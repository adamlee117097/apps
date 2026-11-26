import Foundation

/// Something a player or the enemy AI can ask the rules to do.
public enum Action: Equatable, Sendable {
    case move(unit: Int, to: Position)
    /// Takes back the most recent move, as long as nothing else has happened since.
    case undoMove(unit: Int)
    case attack(unit: Int, target: Int)
    case raise(unit: Int, corpse: Int)
    case burn(unit: Int, tile: Position)
    case consecrate(unit: Int, tile: Position)
    case heal(unit: Int, target: Int)
    case defile(unit: Int)
    case wait(unit: Int)
    case dismiss(unit: Int)
    case endPhase
}

/// What happened as a result of an action, in order. The renderer animates these.
public enum Event: Equatable, Sendable {
    /// `path` runs from the tile the unit left to the tile it reached, one step at a time.
    case moved(unit: Int, path: [Position])
    case attacked(attacker: Int, defender: Int, damage: Int, isCritical: Bool, isCounter: Bool)
    case missed(attacker: Int, defender: Int, isCounter: Bool)
    case died(unit: Int, definitionID: String, at: Position, leftCorpse: Bool)
    case healed(unit: Int, amount: Int)
    /// `unit` is the id the body had in life; `corpse` is the body that was used.
    case raised(unit: Int, definitionID: String, at: Position, by: Int, corpse: Int)
    case corpsesDestroyed(at: Position, count: Int, by: Int)
    case consecrated(tiles: [Position], by: Int)
    /// Tiles that were consecrated before this event and are not any more.
    case consecrationEnded(tiles: [Position])
    case dismissed(unit: Int, at: Position)
    case phaseBegan(side: Side, turn: Int)
    case battleEnded(Outcome)
}

public enum RuleError: Error, Equatable {
    case battleOver
    case noSuchUnit
    case noSuchCorpse
    case notYourPhase
    case alreadyMoved
    case alreadyActed
    case nothingToUndo
    case unreachable
    case tileOccupied
    case outOfRange
    case invalidTarget
    case missingSkill
    case consecratedGround
    case commandCapReached
    case noCorpsesThere
    case dismissAlreadyUsed
    case cannotDismissOverlord
    case playerOnly
    case noFreeTile
}

/// One side's half of an exchange: what a strike does if it lands, and how likely it is to land.
public struct StrikeOdds: Equatable, Sendable {
    /// Damage on an ordinary hit.
    public var damage: Int
    /// Damage on a critical hit.
    public var criticalDamage: Int
    /// Chance to hit, 0 to 100. This is the true chance: one roll, no hidden adjustment.
    public var hitChance: Int
    /// Chance that a hit is critical, 0 to 100.
    public var criticalChance: Int
    public var matchup: Matchup
    /// True if an ordinary hit would kill.
    public var kills: Bool
    /// True if only a critical hit would kill.
    public var killsOnCritical: Bool
}

/// What the player is shown before confirming an attack.
public struct Forecast: Equatable, Sendable {
    public var strike: StrikeOdds
    /// Whether the target would leave a body if this attack killed it. False for a Holy attacker or an overlord target.
    public var leavesCorpse: Bool
    /// The defender's reply if it survives. Nil when it cannot reach the attacker.
    public var counter: StrikeOdds?
    /// Whether the attacker would leave a body if the reply killed it. False against a Holy defender: that unit would be gone for good.
    public var counterLeavesCorpse: Bool
}

/// Corpse tiles one side could deny on its next phase.
public struct CorpseRisk: Equatable, Sendable {
    /// Tiles with bodies that a unit could burn or purge.
    public var burnable: [Position]
    /// Tiles with bodies that a unit could cover with consecrated ground.
    public var consecratable: [Position]
}

/// The rules. Holds no state of its own; every function takes the state it works on.
public struct Engine: Sendable {
    public let data: GameData

    public init(data: GameData) {
        self.data = data
    }

    public func definition(of unit: BattleUnit) -> UnitDefinition {
        // A GameState only comes from a map or a validated save, both of which check every
        // definition id, and code outside the package cannot edit a state. So this cannot fail.
        data.units[unit.definitionID]!
    }

    // MARK: Movement queries

    private struct Search {
        var cost: [Position: Int]
        var previous: [Position: Position]
    }

    private func stepCost(onto tile: Position, drift: Bool, in state: GameState) -> Int? {
        let t = state.terrain(at: tile)
        guard state.contains(tile), t.isPassable else { return nil }
        return (t == .rough && !drift) ? data.rules.roughMoveCost : 1
    }

    private func search(for unit: BattleUnit, in state: GameState) -> Search {
        let def = definition(of: unit)
        let drift = def.has(.drift)
        var result = Search(cost: [unit.position: 0], previous: [:])
        var frontier: [Position] = [unit.position]
        while !frontier.isEmpty {
            frontier.sort { (result.cost[$0]!, $0) < (result.cost[$1]!, $1) }
            let current = frontier.removeFirst()
            let cost = result.cost[current]!
            for next in current.neighbours {
                guard let step = stepCost(onto: next, drift: drift, in: state) else { continue }
                if let other = state.unit(at: next), other.side != unit.side { continue }
                let total = cost + step
                guard total <= def.move, total < (result.cost[next] ?? Int.max) else { continue }
                result.cost[next] = total
                result.previous[next] = current
                if !frontier.contains(next) { frontier.append(next) }
            }
        }
        return result
    }

    /// Tiles the unit can reach this phase, with the movement cost of each. Includes its own tile at cost 0.
    public func reachable(for unit: BattleUnit, in state: GameState) -> [Position: Int] {
        // A unit may pass through allies but not stop on them.
        search(for: unit, in: state).cost.filter { $0.key == unit.position || state.unit(at: $0.key) == nil }
    }

    /// The tiles a unit walks through to reach `destination`, starting with its own tile. Nil if it cannot get there.
    public func route(for unit: BattleUnit, to destination: Position, in state: GameState) -> [Position]? {
        let s = search(for: unit, in: state)
        guard s.cost[destination] != nil,
              destination == unit.position || state.unit(at: destination) == nil else { return nil }
        var path = [destination]
        while let last = path.last, last != unit.position {
            guard let before = s.previous[last] else { return nil }
            path.append(before)
        }
        return path.reversed()
    }

    /// Walking distance from every tile to `goal` for this unit, ignoring other units. Used by the AI to find its way round walls.
    public func distances(to goal: Position, for unit: BattleUnit, in state: GameState) -> [Position: Int] {
        let drift = definition(of: unit).has(.drift)
        guard state.contains(goal) else { return [:] }
        var best: [Position: Int] = [goal: 0]
        var frontier: [Position] = [goal]
        while !frontier.isEmpty {
            frontier.sort { (best[$0]!, $0) < (best[$1]!, $1) }
            let current = frontier.removeFirst()
            // Walking from a neighbour onto `current` costs what `current` costs to enter.
            let enter = stepCost(onto: current, drift: drift, in: state) ?? 1
            for next in current.neighbours {
                guard stepCost(onto: next, drift: drift, in: state) != nil else { continue }
                let total = best[current]! + enter
                guard total < (best[next] ?? Int.max) else { continue }
                best[next] = total
                if !frontier.contains(next) { frontier.append(next) }
            }
        }
        return best
    }

    public func inRange(_ def: UnitDefinition, from: Position, to: Position) -> Bool {
        let d = from.distance(to: to)
        return d >= def.minRange && d <= def.maxRange
    }

    // MARK: Combat queries

    /// Guard including terrain and an adjacent ally's Bulwark.
    public func effectiveGuard(of unit: BattleUnit, at position: Position, in state: GameState) -> Int {
        var g = definition(of: unit).guard
        if state.terrain(at: position) == .rough { g += data.rules.roughGuardBonus }
        let hasBulwarkNeighbour = state.units.contains {
            $0.id != unit.id && $0.side == unit.side
                && $0.position.distance(to: position) == 1
                && definition(of: $0).has(.bulwark)
        }
        if hasBulwarkNeighbour { g += data.rules.bulwarkGuardBonus }
        return g
    }

    /// The odds of `attacker`, standing at `attackerAt`, striking `defender` at `defenderAt`.
    public func odds(attacker: BattleUnit, at attackerAt: Position, defender: BattleUnit, at defenderAt: Position,
                     in state: GameState) -> StrikeOdds {
        let rules = data.rules
        let a = definition(of: attacker)
        let d = definition(of: defender)
        let defence = a.damage == .physical ? effectiveGuard(of: defender, at: defenderAt, in: state) : d.ward
        let matchup = rules.matchup(attacker: a.type, defender: d.type)
        let base = max(0, a.might - defence)
        var hit = a.hit - d.avoid
        if state.terrain(at: defenderAt) == .rough { hit -= rules.roughAvoidBonus }
        let scaled: Int
        switch matchup {
        case .advantage:
            scaled = base * rules.advantage.numerator / rules.advantage.denominator
            hit += rules.matchupHitBonus
        case .disadvantage:
            scaled = base * rules.disadvantage.numerator / rules.disadvantage.denominator
            hit -= rules.matchupHitBonus
        case .neutral:
            scaled = base
        }
        let damage = max(1, scaled)
        let critical = max(damage, damage * rules.critical.numerator / rules.critical.denominator)
        return StrikeOdds(damage: damage, criticalDamage: critical,
                          hitChance: min(100, max(0, hit)), criticalChance: min(100, max(0, a.crit)),
                          matchup: matchup, kills: damage >= defender.hp,
                          killsOnCritical: damage < defender.hp && critical >= defender.hp)
    }

    /// What the player is shown before `attacker`, standing at `from` (its current tile by default), attacks `defender`.
    public func forecast(attacker: BattleUnit, defender: BattleUnit, from: Position? = nil, in state: GameState) -> Forecast {
        let origin = from ?? attacker.position
        let a = definition(of: attacker)
        let d = definition(of: defender)
        let strike = odds(attacker: attacker, at: origin, defender: defender, at: defender.position, in: state)
        let canCounter = inRange(d, from: defender.position, to: origin)
        return Forecast(
            strike: strike,
            leavesCorpse: a.type != .holy && !d.overlord,
            counter: canCounter ? odds(attacker: defender, at: defender.position, defender: attacker, at: origin, in: state) : nil,
            counterLeavesCorpse: d.type != .holy && !a.overlord)
    }

    /// Enemies this unit could attack from `from` (its current tile by default).
    public func attackTargets(for unit: BattleUnit, from: Position? = nil, in state: GameState) -> [BattleUnit] {
        let def = definition(of: unit)
        return state.units.filter { $0.side != unit.side && inRange(def, from: from ?? unit.position, to: $0.position) }
    }

    /// Hurt allies this unit could heal or mend from `from` (its current tile by default).
    public func healTargets(for unit: BattleUnit, from: Position? = nil, in state: GameState) -> [BattleUnit] {
        guard let (_, range) = healing(definition(of: unit)) else { return [] }
        return state.units.filter {
            $0.side == unit.side && $0.id != unit.id && $0.hp < definition(of: $0).maxHP
                && $0.position.distance(to: from ?? unit.position) <= range
        }
    }

    private func healing(_ def: UnitDefinition) -> (amount: Int, range: Int)? {
        if def.has(.heal) { return (data.rules.healAmount, data.rules.healRange) }
        if def.has(.mend) { return (data.rules.mendHeal, data.rules.mendRange) }
        return nil
    }

    /// How far this unit can reach to destroy corpses, or nil if it cannot.
    public func burnRange(_ def: UnitDefinition) -> Int? {
        if def.has(.burnCorpses) { return data.rules.burnRange }
        if def.has(.purgeCorpses) { return data.rules.purgeRange }
        return nil
    }

    /// Every tile where a unit could be attacked by `side` on that side's next phase, as things stand now.
    /// This is the "danger area" the interface shows.
    public func threatenedTiles(by side: Side, in state: GameState) -> Set<Position> {
        var tiles: Set<Position> = []
        for unit in state.units(of: side) {
            let def = definition(of: unit)
            for from in reachable(for: unit, in: state).keys {
                for dy in -def.maxRange...def.maxRange {
                    let span = def.maxRange - abs(dy)
                    for dx in -span...span {
                        let target = Position(from.x + dx, from.y + dy)
                        if state.contains(target), inRange(def, from: from, to: target) { tiles.insert(target) }
                    }
                }
            }
        }
        return tiles
    }

    /// Corpse tiles that `side` could burn or consecrate on its next phase, as things stand now.
    public func corpsesAtRisk(from side: Side, in state: GameState) -> CorpseRisk {
        let piles = Set(state.corpses.map(\.position))
        var burnable: Set<Position> = []
        var consecratable: Set<Position> = []
        for unit in state.units(of: side) {
            let def = definition(of: unit)
            let burn = burnRange(def)
            let canConsecrate = def.has(.consecrate)
            guard burn != nil || canConsecrate else { continue }
            let from = reachable(for: unit, in: state).keys
            for pile in piles {
                if let burn, from.contains(where: { $0.distance(to: pile) <= burn }) { burnable.insert(pile) }
                // A blessing covers its centre and the four tiles beside it, so it reaches one tile further.
                if canConsecrate, !state.isConsecrated(pile),
                   from.contains(where: { $0.distance(to: pile) <= data.rules.consecrateRange + 1 }) {
                    consecratable.insert(pile)
                }
            }
        }
        return CorpseRisk(burnable: burnable.sorted(), consecratable: consecratable.sorted())
    }

    // MARK: Raising queries

    /// The number of undead under the player's command. The overlord does not count.
    public func commandCount(in state: GameState) -> Int {
        state.units.filter { $0.side == .player && !definition(of: $0).overlord }.count
    }

    public func isAtCommandCap(in state: GameState) -> Bool {
        commandCount(in: state) >= state.commandCap
    }

    /// The unit a corpse would become if raised. Nil if it cannot be raised at all.
    public func raisedDefinitionID(for corpse: Corpse) -> String? {
        guard let def = data.units[corpse.definitionID], !def.overlord else { return nil }
        let id = def.isLiving ? def.raisesAs : def.id
        guard let id, let raised = data.units[id], !raised.overlord else { return nil }
        return id
    }

    /// Corpses within this unit's raise range that are not on consecrated ground.
    /// This does not look at the command cap; check `isAtCommandCap` as well before offering a raise.
    public func raisableCorpses(for unit: BattleUnit, in state: GameState) -> [Corpse] {
        guard let range = definition(of: unit).raiseRange, definition(of: unit).has(.raise) else { return [] }
        return state.corpses.filter {
            $0.position.distance(to: unit.position) <= range
                && !state.isConsecrated($0.position)
                && raisedDefinitionID(for: $0) != nil
        }
    }

    /// Units of a side that can still do something this phase.
    public func unitsAbleToAct(_ side: Side, in state: GameState) -> [BattleUnit] {
        state.phase == side ? state.units(of: side).filter { !$0.hasActed } : []
    }

    // MARK: Applying actions

    /// Applies an action. On error the state is left exactly as it was.
    @discardableResult
    public func apply(_ action: Action, to state: inout GameState) throws -> [Event] {
        guard state.outcome == .ongoing else { throw RuleError.battleOver }
        var next = state
        var events: [Event] = []
        try perform(action, &next, &events)
        state = next
        return events
    }

    private func actor(_ id: Int, _ state: GameState, mayHaveActed: Bool = false) throws -> (Int, BattleUnit) {
        guard let index = state.units.firstIndex(where: { $0.id == id }) else { throw RuleError.noSuchUnit }
        let unit = state.units[index]
        guard unit.side == state.phase else { throw RuleError.notYourPhase }
        if !mayHaveActed && unit.hasActed { throw RuleError.alreadyActed }
        return (index, unit)
    }

    private func finish(_ index: Int, _ state: inout GameState) {
        state.units[index].hasActed = true
        state.units[index].hasMoved = true
        state.units[index].movedFrom = nil
    }

    /// Any new order makes earlier moves final: only the latest move can be taken back.
    private func commitMoves(except id: Int?, _ state: inout GameState) {
        for i in state.units.indices where state.units[i].id != id {
            state.units[i].movedFrom = nil
        }
    }

    private func consecratedTiles(_ state: GameState) -> Set<Position> {
        Set(state.consecrations.flatMap(\.tiles))
    }

    /// Runs a change to the consecrations and reports the tiles that stopped being consecrated because of it.
    private func changeConsecrations(_ state: inout GameState, _ events: inout [Event],
                                     _ change: (inout [Consecration]) -> Void) {
        let before = consecratedTiles(state)
        change(&state.consecrations)
        state.consecrations.removeAll { $0.tiles.isEmpty }
        let ended = before.subtracting(consecratedTiles(state))
        if !ended.isEmpty { events.append(.consecrationEnded(tiles: ended.sorted())) }
    }

    private func perform(_ action: Action, _ state: inout GameState, _ events: inout [Event]) throws {
        switch action {
        case let .move(id, to):
            let (index, unit) = try actor(id, state)
            guard !unit.hasMoved else { throw RuleError.alreadyMoved }
            guard to != unit.position, let path = route(for: unit, to: to, in: state) else { throw RuleError.unreachable }
            commitMoves(except: nil, &state)
            state.units[index].movedFrom = unit.position
            state.units[index].position = to
            state.units[index].hasMoved = true
            events.append(.moved(unit: id, path: path))

        case let .undoMove(id):
            let (index, unit) = try actor(id, state)
            guard let origin = unit.movedFrom else { throw RuleError.nothingToUndo }
            guard state.unit(at: origin) == nil else { throw RuleError.tileOccupied }
            state.units[index].position = origin
            state.units[index].movedFrom = nil
            state.units[index].hasMoved = false
            events.append(.moved(unit: id, path: [unit.position, origin]))

        case let .attack(id, targetID):
            let (index, unit) = try actor(id, state)
            guard let target = state.unit(id: targetID), target.side != unit.side else { throw RuleError.invalidTarget }
            guard inRange(definition(of: unit), from: unit.position, to: target.position) else { throw RuleError.outOfRange }
            commitMoves(except: id, &state)
            finish(index, &state)
            strike(attackerID: id, defenderID: targetID, isCounter: false, &state, &events)
            // The defender replies if it is still standing and can reach the attacker.
            if state.outcome == .ongoing, let survivor = state.unit(id: targetID), let attackerNow = state.unit(id: id),
               inRange(definition(of: survivor), from: survivor.position, to: attackerNow.position) {
                strike(attackerID: targetID, defenderID: id, isCounter: true, &state, &events)
            }

        case let .raise(id, corpseID):
            let (index, unit) = try actor(id, state)
            let def = definition(of: unit)
            guard def.has(.raise), let range = def.raiseRange else { throw RuleError.missingSkill }
            guard let corpseIndex = state.corpses.firstIndex(where: { $0.id == corpseID }) else { throw RuleError.noSuchCorpse }
            let corpse = state.corpses[corpseIndex]
            guard corpse.position.distance(to: unit.position) <= range else { throw RuleError.outOfRange }
            guard !state.isConsecrated(corpse.position) else { throw RuleError.consecratedGround }
            guard let newID = raisedDefinitionID(for: corpse), let newDef = data.units[newID],
                  state.unit(id: corpse.unitID) == nil else { throw RuleError.invalidTarget }
            if unit.side == .player {
                guard !isAtCommandCap(in: state) else { throw RuleError.commandCapReached }
            }
            guard let tile = nearestFreeTile(to: corpse.position, in: state) else { throw RuleError.noFreeTile }
            commitMoves(except: id, &state)
            state.corpses.remove(at: corpseIndex)
            finish(index, &state)
            // Baseline raise: full health, but the unit cannot act until its side's next phase.
            let raised = BattleUnit(id: corpse.unitID, definitionID: newID, side: unit.side, position: tile,
                                    hp: newDef.maxHP, hasMoved: true, hasActed: true)
            state.units.append(raised)
            state.units.sort { $0.id < $1.id }
            events.append(.raised(unit: raised.id, definitionID: newID, at: tile, by: id, corpse: corpse.id))

        case let .burn(id, tile):
            let (index, unit) = try actor(id, state)
            guard let range = burnRange(definition(of: unit)) else { throw RuleError.missingSkill }
            guard unit.position.distance(to: tile) <= range else { throw RuleError.outOfRange }
            let count = state.corpses(at: tile).count
            guard count > 0 else { throw RuleError.noCorpsesThere }
            commitMoves(except: id, &state)
            state.corpses.removeAll { $0.position == tile }
            finish(index, &state)
            events.append(.corpsesDestroyed(at: tile, count: count, by: id))

        case let .consecrate(id, tile):
            let (index, unit) = try actor(id, state)
            guard definition(of: unit).has(.consecrate) else { throw RuleError.missingSkill }
            guard state.contains(tile), state.terrain(at: tile).isPassable else { throw RuleError.invalidTarget }
            guard unit.position.distance(to: tile) <= data.rules.consecrateRange else { throw RuleError.outOfRange }
            commitMoves(except: id, &state)
            let tiles = ([tile] + tile.neighbours).filter { state.contains($0) && state.terrain(at: $0).isPassable }
            let sequence = state.nextSequence
            state.nextSequence += 1
            let limit = data.rules.maxConsecrationsPerCaster
            changeConsecrations(&state, &events) { all in
                all.append(Consecration(casterID: id, sequence: sequence, tiles: tiles))
                // Each caster keeps only its newest areas; older ones lapse.
                let mine = all.filter { $0.casterID == id }.map(\.sequence).sorted()
                let lapsed = Set(mine.dropLast(limit))
                all.removeAll { $0.casterID == id && lapsed.contains($0.sequence) }
            }
            finish(index, &state)
            events.append(.consecrated(tiles: tiles, by: id))

        case let .heal(id, targetID):
            let (index, unit) = try actor(id, state)
            guard let (amount, range) = healing(definition(of: unit)) else { throw RuleError.missingSkill }
            guard let targetIndex = state.units.firstIndex(where: { $0.id == targetID }) else { throw RuleError.noSuchUnit }
            let target = state.units[targetIndex]
            let maxHP = definition(of: target).maxHP
            guard target.side == unit.side, target.id != id, target.hp < maxHP else { throw RuleError.invalidTarget }
            guard unit.position.distance(to: target.position) <= range else { throw RuleError.outOfRange }
            commitMoves(except: id, &state)
            let healed = min(amount, maxHP - target.hp)
            state.units[targetIndex].hp += healed
            finish(index, &state)
            events.append(.healed(unit: targetID, amount: healed))

        case let .defile(id):
            let (index, unit) = try actor(id, state)
            guard definition(of: unit).has(.defile) else { throw RuleError.missingSkill }
            let cleared = Set([unit.position] + unit.position.neighbours)
            guard !cleared.isDisjoint(with: consecratedTiles(state)) else { throw RuleError.invalidTarget }
            commitMoves(except: id, &state)
            changeConsecrations(&state, &events) { all in
                for i in all.indices { all[i].tiles.removeAll { cleared.contains($0) } }
            }
            finish(index, &state)

        case let .wait(id):
            let (index, _) = try actor(id, state)
            commitMoves(except: id, &state)
            finish(index, &state)

        case let .dismiss(id):
            let (index, unit) = try actor(id, state, mayHaveActed: true)
            guard unit.side == .player else { throw RuleError.playerOnly }
            guard !state.dismissUsedThisPhase else { throw RuleError.dismissAlreadyUsed }
            guard !definition(of: unit).overlord else { throw RuleError.cannotDismissOverlord }
            commitMoves(except: nil, &state)
            state.dismissUsedThisPhase = true
            removeUnit(at: index, leavingCorpse: true, &state)
            events.append(.dismissed(unit: id, at: unit.position))
            changeConsecrations(&state, &events) { $0.removeAll { $0.casterID == id } }

        case .endPhase:
            state.phase = state.phase.opponent
            if state.phase == .player { state.turn += 1 }
            state.dismissUsedThisPhase = false
            for i in state.units.indices {
                state.units[i].hasMoved = false
                state.units[i].hasActed = false
                state.units[i].movedFrom = nil
            }
            events.append(.phaseBegan(side: state.phase, turn: state.turn))
        }
    }

    /// Takes a unit off the board, leaving its body if asked. Every way a unit leaves goes through here.
    @discardableResult
    private func removeUnit(at index: Int, leavingCorpse: Bool, _ state: inout GameState) -> BattleUnit {
        let unit = state.units.remove(at: index)
        if leavingCorpse {
            state.corpses.append(Corpse(id: state.nextCorpseID, unitID: unit.id, definitionID: unit.definitionID,
                                        side: unit.side, position: unit.position))
            state.nextCorpseID += 1
        }
        return unit
    }

    /// Rolls and resolves one strike. Two rolls at most: one to hit, and if it hits, one for a critical.
    private func strike(attackerID: Int, defenderID: Int, isCounter: Bool,
                        _ state: inout GameState, _ events: inout [Event]) {
        guard let attacker = state.unit(id: attackerID),
              let defenderIndex = state.units.firstIndex(where: { $0.id == defenderID }) else { return }
        let defender = state.units[defenderIndex]
        let o = odds(attacker: attacker, at: attacker.position, defender: defender, at: defender.position, in: state)
        guard state.rollPercent() < o.hitChance else {
            events.append(.missed(attacker: attackerID, defender: defenderID, isCounter: isCounter))
            return
        }
        let isCritical = state.rollPercent() < o.criticalChance
        let damage = isCritical ? o.criticalDamage : o.damage
        state.units[defenderIndex].hp -= damage
        events.append(.attacked(attacker: attackerID, defender: defenderID, damage: damage, isCritical: isCritical, isCounter: isCounter))
        guard state.units[defenderIndex].hp <= 0 else { return }

        let attackerDef = definition(of: attacker)
        let deadDef = definition(of: defender)
        let leavesCorpse = attackerDef.type != .holy && !deadDef.overlord
        let dead = removeUnit(at: defenderIndex, leavingCorpse: leavesCorpse, &state)
        events.append(.died(unit: dead.id, definitionID: dead.definitionID, at: dead.position, leftCorpse: leavesCorpse))
        // A caster's consecrated ground ends with the caster.
        changeConsecrations(&state, &events) { $0.removeAll { $0.casterID == dead.id } }

        if attackerDef.has(.feed), let i = state.units.firstIndex(where: { $0.id == attackerID }) {
            let healed = min(data.rules.feedHeal, attackerDef.maxHP - state.units[i].hp)
            if healed > 0 {
                state.units[i].hp += healed
                events.append(.healed(unit: attackerID, amount: healed))
            }
        }

        if deadDef.overlord && dead.side == .player {
            state.outcome = .defeat
        } else if state.units(of: .enemy).isEmpty {
            state.outcome = .victory
        }
        if state.outcome != .ongoing {
            events.append(.battleEnded(state.outcome))
        }
    }

    /// The closest passable, unoccupied tile to `origin`, searching outward in a fixed order.
    func nearestFreeTile(to origin: Position, in state: GameState) -> Position? {
        var seen: Set<Position> = [origin]
        var ring: [Position] = [origin]
        while !ring.isEmpty {
            if let free = ring.sorted().first(where: { state.unit(at: $0) == nil }) { return free }
            var nextRing: [Position] = []
            for p in ring {
                for n in p.neighbours where state.contains(n) && state.terrain(at: n).isPassable && !seen.contains(n) {
                    seen.insert(n)
                    nextRing.append(n)
                }
            }
            ring = nextRing
        }
        return nil
    }
}
