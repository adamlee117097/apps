import Foundation

/// Something a player or the enemy AI can ask the rules to do.
public enum Action: Equatable, Sendable {
    case move(unit: Int, to: Position)
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
    case moved(unit: Int, from: Position, to: Position)
    case attacked(attacker: Int, defender: Int, damage: Int, isCounter: Bool)
    case died(unit: Int, definitionID: String, at: Position, leftCorpse: Bool)
    case healed(unit: Int, amount: Int)
    case raised(unit: Int, definitionID: String, at: Position, by: Int)
    case corpsesDestroyed(at: Position, count: Int, by: Int)
    case consecrated(tiles: [Position], by: Int)
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
    case outOfRange
    case invalidTarget
    case missingSkill
    case consecratedGround
    case commandCapReached
    case noCorpsesThere
    case dismissAlreadyUsed
    case cannotDismissOverlord
    case noFreeTile
}

/// The exact result an attack would have. There is no randomness, so this is not an estimate.
public struct Forecast: Equatable, Sendable {
    public var damage: Int
    public var matchup: Matchup
    public var kills: Bool
    /// False when the kill is by a Holy attacker, or the target is the overlord.
    public var leavesCorpse: Bool
    /// Nil when the defender cannot strike back.
    public var counterDamage: Int?
    public var counterMatchup: Matchup
    public var counterKills: Bool
}

/// The rules. Holds no state of its own; every function takes the state it works on.
public struct Engine: Sendable {
    public let data: GameData

    public init(data: GameData) {
        self.data = data
    }

    public func definition(of unit: BattleUnit) -> UnitDefinition {
        // Units are only created from known definitions, so this lookup cannot fail.
        data.units[unit.definitionID]!
    }

    // MARK: Queries

    /// Tiles the unit can reach this phase, with the movement cost of each. Includes its own tile at cost 0.
    public func reachable(for unit: BattleUnit, in state: GameState) -> [Position: Int] {
        let def = definition(of: unit)
        let drift = def.has(.drift)
        var best: [Position: Int] = [unit.position: 0]
        var frontier: [Position] = [unit.position]
        while !frontier.isEmpty {
            frontier.sort { (best[$0]!, $0) < (best[$1]!, $1) }
            let current = frontier.removeFirst()
            let cost = best[current]!
            for next in current.neighbours {
                let t = state.terrain(at: next)
                guard state.contains(next), t.isPassable else { continue }
                if let other = state.unit(at: next), other.side != unit.side { continue }
                let step = (t == .rough && !drift) ? data.rules.roughMoveCost : 1
                let total = cost + step
                guard total <= def.move, total < (best[next] ?? Int.max) else { continue }
                best[next] = total
                if !frontier.contains(next) { frontier.append(next) }
            }
        }
        // A unit may pass through allies but not stop on them.
        return best.filter { $0.key == unit.position || state.unit(at: $0.key) == nil }
    }

    public func inRange(_ def: UnitDefinition, from: Position, to: Position) -> Bool {
        let d = from.distance(to: to)
        return d >= def.minRange && d <= def.maxRange
    }

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

    private func damage(from attacker: BattleUnit, to defender: BattleUnit, defenderAt: Position, in state: GameState) -> (Int, Matchup) {
        let a = definition(of: attacker)
        let d = definition(of: defender)
        let defence = a.damage == .physical ? effectiveGuard(of: defender, at: defenderAt, in: state) : d.ward
        let matchup = data.rules.matchup(attacker: a.type, defender: d.type)
        let base = max(0, a.might - defence)
        let scaled: Int
        switch matchup {
        case .advantage: scaled = base * data.rules.advantage.numerator / data.rules.advantage.denominator
        case .disadvantage: scaled = base * data.rules.disadvantage.numerator / data.rules.disadvantage.denominator
        case .neutral: scaled = base
        }
        return (max(1, scaled), matchup)
    }

    /// What would happen if `attacker`, standing at `from` (its current tile by default), attacked `defender`.
    public func forecast(attacker: BattleUnit, defender: BattleUnit, from: Position? = nil, in state: GameState) -> Forecast {
        let origin = from ?? attacker.position
        let a = definition(of: attacker)
        let d = definition(of: defender)
        let (dmg, matchup) = damage(from: attacker, to: defender, defenderAt: defender.position, in: state)
        let kills = dmg >= defender.hp
        var result = Forecast(damage: dmg, matchup: matchup, kills: kills,
                              leavesCorpse: kills && a.type != .holy && !d.overlord,
                              counterDamage: nil, counterMatchup: .neutral, counterKills: false)
        if !kills && inRange(d, from: defender.position, to: origin) {
            let (back, backMatchup) = damage(from: defender, to: attacker, defenderAt: origin, in: state)
            result.counterDamage = back
            result.counterMatchup = backMatchup
            result.counterKills = back >= attacker.hp
        }
        return result
    }

    /// The number of undead under the player's command. The overlord does not count.
    public func commandCount(in state: GameState) -> Int {
        state.units.filter { $0.side == .player && !definition(of: $0).overlord }.count
    }

    /// The unit a corpse would become if raised.
    public func raisedDefinitionID(for corpse: Corpse) -> String? {
        guard let def = data.units[corpse.definitionID] else { return nil }
        return def.isLiving ? def.raisesAs : def.id
    }

    /// Corpses this unit could raise right now from where it stands.
    public func raisableCorpses(for unit: BattleUnit, in state: GameState) -> [Corpse] {
        guard let range = definition(of: unit).raiseRange, definition(of: unit).has(.raise) else { return [] }
        return state.corpses.filter {
            $0.position.distance(to: unit.position) <= range
                && !state.isConsecrated($0.position)
                && raisedDefinitionID(for: $0) != nil
        }
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

    private func perform(_ action: Action, _ state: inout GameState, _ events: inout [Event]) throws {
        switch action {
        case let .move(id, to):
            let (index, unit) = try actor(id, state)
            guard !unit.hasMoved else { throw RuleError.alreadyMoved }
            guard to != unit.position, reachable(for: unit, in: state)[to] != nil else { throw RuleError.unreachable }
            state.units[index].movedFrom = unit.position
            state.units[index].position = to
            state.units[index].hasMoved = true
            events.append(.moved(unit: id, from: unit.position, to: to))

        case let .undoMove(id):
            let (index, unit) = try actor(id, state)
            guard let origin = unit.movedFrom else { throw RuleError.nothingToUndo }
            state.units[index].position = origin
            state.units[index].movedFrom = nil
            state.units[index].hasMoved = false
            events.append(.moved(unit: id, from: unit.position, to: origin))

        case let .attack(id, targetID):
            let (index, unit) = try actor(id, state)
            guard let target = state.unit(id: targetID), target.side != unit.side else { throw RuleError.invalidTarget }
            guard inRange(definition(of: unit), from: unit.position, to: target.position) else { throw RuleError.outOfRange }
            let f = forecast(attacker: unit, defender: target, in: state)
            finish(index, &state)
            strike(attackerID: id, defenderID: targetID, damage: f.damage, isCounter: false, &state, &events)
            if let back = f.counterDamage, state.outcome == .ongoing {
                strike(attackerID: targetID, defenderID: id, damage: back, isCounter: true, &state, &events)
            }

        case let .raise(id, corpseID):
            let (index, unit) = try actor(id, state)
            let def = definition(of: unit)
            guard def.has(.raise), let range = def.raiseRange else { throw RuleError.missingSkill }
            guard let corpseIndex = state.corpses.firstIndex(where: { $0.id == corpseID }) else { throw RuleError.noSuchCorpse }
            let corpse = state.corpses[corpseIndex]
            guard corpse.position.distance(to: unit.position) <= range else { throw RuleError.outOfRange }
            guard !state.isConsecrated(corpse.position) else { throw RuleError.consecratedGround }
            guard let newID = raisedDefinitionID(for: corpse), let newDef = data.units[newID] else { throw RuleError.invalidTarget }
            if unit.side == .player {
                guard commandCount(in: state) < state.commandCap else { throw RuleError.commandCapReached }
            }
            guard let tile = nearestFreeTile(to: corpse.position, in: state) else { throw RuleError.noFreeTile }
            state.corpses.remove(at: corpseIndex)
            // Baseline raise: full health, but the unit cannot act until its side's next phase.
            let raised = BattleUnit(id: state.nextUnitID, definitionID: newID, side: unit.side, position: tile,
                              hp: newDef.maxHP, hasMoved: true, hasActed: true)
            state.nextUnitID += 1
            state.units.append(raised)
            finish(index, &state)
            events.append(.raised(unit: raised.id, definitionID: newID, at: tile, by: id))

        case let .burn(id, tile):
            let (index, unit) = try actor(id, state)
            let def = definition(of: unit)
            let range: Int
            if def.has(.burnCorpses) { range = data.rules.burnRange }
            else if def.has(.purgeCorpses) { range = data.rules.purgeRange }
            else { throw RuleError.missingSkill }
            guard unit.position.distance(to: tile) <= range else { throw RuleError.outOfRange }
            let count = state.corpses(at: tile).count
            guard count > 0 else { throw RuleError.noCorpsesThere }
            state.corpses.removeAll { $0.position == tile }
            finish(index, &state)
            events.append(.corpsesDestroyed(at: tile, count: count, by: id))

        case let .consecrate(id, tile):
            let (index, unit) = try actor(id, state)
            guard definition(of: unit).has(.consecrate) else { throw RuleError.missingSkill }
            guard state.contains(tile), unit.position.distance(to: tile) <= data.rules.consecrateRange else { throw RuleError.outOfRange }
            let tiles = ([tile] + tile.neighbours).filter { state.contains($0) }
            var mine = state.consecrations.filter { $0.casterID == id }.sorted { $0.sequence < $1.sequence }
            while mine.count >= data.rules.maxConsecrationsPerCaster {
                let oldest = mine.removeFirst()
                state.consecrations.removeAll { $0.casterID == id && $0.sequence == oldest.sequence }
                events.append(.consecrationEnded(tiles: oldest.tiles))
            }
            state.consecrations.append(Consecration(casterID: id, sequence: state.nextSequence, tiles: tiles))
            state.nextSequence += 1
            finish(index, &state)
            events.append(.consecrated(tiles: tiles, by: id))

        case let .heal(id, targetID):
            let (index, unit) = try actor(id, state)
            let def = definition(of: unit)
            let amount: Int, range: Int
            if def.has(.heal) { amount = data.rules.healAmount; range = data.rules.healRange }
            else if def.has(.mend) { amount = data.rules.mendHeal; range = data.rules.mendRange }
            else { throw RuleError.missingSkill }
            guard let targetIndex = state.units.firstIndex(where: { $0.id == targetID }) else { throw RuleError.noSuchUnit }
            let target = state.units[targetIndex]
            let maxHP = definition(of: target).maxHP
            guard target.side == unit.side, target.id != id, target.hp < maxHP else { throw RuleError.invalidTarget }
            guard unit.position.distance(to: target.position) <= range else { throw RuleError.outOfRange }
            let healed = min(amount, maxHP - target.hp)
            state.units[targetIndex].hp += healed
            finish(index, &state)
            events.append(.healed(unit: targetID, amount: healed))

        case let .defile(id):
            let (index, unit) = try actor(id, state)
            guard definition(of: unit).has(.defile) else { throw RuleError.missingSkill }
            let cleared = Set([unit.position] + unit.position.neighbours)
            var removed: [Position] = []
            for i in state.consecrations.indices {
                removed += state.consecrations[i].tiles.filter { cleared.contains($0) }
                state.consecrations[i].tiles.removeAll { cleared.contains($0) }
            }
            guard !removed.isEmpty else { throw RuleError.invalidTarget }
            state.consecrations.removeAll { $0.tiles.isEmpty }
            finish(index, &state)
            events.append(.consecrationEnded(tiles: removed.sorted()))

        case let .wait(id):
            let (index, _) = try actor(id, state)
            finish(index, &state)

        case let .dismiss(id):
            let (index, unit) = try actor(id, state, mayHaveActed: true)
            guard !state.dismissUsedThisPhase else { throw RuleError.dismissAlreadyUsed }
            guard !definition(of: unit).overlord else { throw RuleError.cannotDismissOverlord }
            state.units.remove(at: index)
            state.corpses.append(Corpse(id: state.nextCorpseID, definitionID: unit.definitionID, position: unit.position))
            state.nextCorpseID += 1
            state.dismissUsedThisPhase = true
            events.append(.dismissed(unit: id, at: unit.position))

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

    private func strike(attackerID: Int, defenderID: Int, damage: Int, isCounter: Bool,
                        _ state: inout GameState, _ events: inout [Event]) {
        guard let attacker = state.unit(id: attackerID),
              let defenderIndex = state.units.firstIndex(where: { $0.id == defenderID }) else { return }
        state.units[defenderIndex].hp -= damage
        events.append(.attacked(attacker: attackerID, defender: defenderID, damage: damage, isCounter: isCounter))
        guard state.units[defenderIndex].hp <= 0 else { return }

        let dead = state.units.remove(at: defenderIndex)
        let deadDef = definition(of: dead)
        let attackerDef = definition(of: attacker)
        let leavesCorpse = attackerDef.type != .holy && !deadDef.overlord
        if leavesCorpse {
            state.corpses.append(Corpse(id: state.nextCorpseID, definitionID: dead.definitionID, position: dead.position))
            state.nextCorpseID += 1
        }
        events.append(.died(unit: dead.id, definitionID: dead.definitionID, at: dead.position, leftCorpse: leavesCorpse))

        // A caster's consecrated ground ends with the caster.
        let ended = state.consecrations.filter { $0.casterID == dead.id }
        if !ended.isEmpty {
            state.consecrations.removeAll { $0.casterID == dead.id }
            events.append(.consecrationEnded(tiles: ended.flatMap(\.tiles).sorted()))
        }

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

// MARK: Save and load

extension GameState {
    /// Encodes the battle as JSON. Keys are sorted so the same state always gives the same bytes.
    public func saved() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }

    public static func load(_ data: Data) throws -> GameState {
        try JSONDecoder().decode(GameState.self, from: data)
    }

    /// A text picture of the map for tests and debugging. Not used for display in the game.
    public func ascii(_ data: GameData) -> String {
        var lines: [String] = []
        for y in 0..<height {
            var line = ""
            for x in 0..<width {
                let p = Position(x, y)
                if let u = unit(at: p) {
                    let letter = data.units[u.definitionID]?.name.first ?? "?"
                    line += u.side == .player ? String(letter).uppercased() : String(letter).lowercased()
                } else if !corpses(at: p).isEmpty {
                    line += isConsecrated(p) ? "X" : "x"
                } else if isConsecrated(p) {
                    line += "+"
                } else {
                    switch terrain(at: p) {
                    case .open: line += "."
                    case .rough: line += "f"
                    case .wall: line += "#"
                    case .water: line += "~"
                    }
                }
            }
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }
}
