import Foundation

/// The enemy's decision-making. It has no randomness of its own: the same state always gives the same plan.
///
/// Each unit looks at every tile it can reach and every action it could take from there, scores
/// each by its expected value (what success is worth times the chance of it, minus the expected
/// cost of the reply), and takes the best. The weights are data, in `rules.json` under `ai`.
///
/// Corpse denial is scored directly: clerics are rewarded for consecrating bodies a raiser could
/// reach, and fire users for burning them. Those units also count what standing on a tile will
/// cost them in the other side's next phase, so they do their work from out of reach when they can.
/// The planning works for either side, which the tests use to drive a player.
public struct EnemyAI: Sendable {
    public let engine: Engine

    public init(engine: Engine) {
        self.engine = engine
    }

    /// One unit's plan: an optional move, then an action.
    public struct Plan: Equatable, Sendable {
        public var moveTo: Position?
        public var action: Action
        public var score: Int
    }

    private var weights: AIWeights { engine.data.rules.ai }

    /// How much the other side would gain by raising this corpse.
    func value(of corpse: Corpse) -> Int {
        guard let id = engine.raisedDefinitionID(for: corpse), let def = engine.data.units[id] else { return 0 }
        return def.maxHP + def.might * 2
    }

    /// True if one of `side`'s raisers could get within raising range of the tile on its next phase.
    func canRaiseSoon(_ side: Side, at tile: Position, in state: GameState) -> Bool {
        state.units(of: side).contains { u in
            let def = engine.definition(of: u)
            guard def.has(.raise), let range = def.raiseRange else { return false }
            return u.position.distance(to: tile) <= def.move + range
        }
    }

    /// What a body is worth to deny: full value if a raiser can reach it next phase, a fraction otherwise.
    private func denialValue(of corpse: Corpse, against side: Side, in state: GameState) -> Int {
        let worth = value(of: corpse) * weights.consecrateValue
        return canRaiseSoon(side, at: corpse.position, in: state)
            ? worth + weights.consecrateReach
            : worth / max(1, weights.outOfReachDivisor)
    }

    private func deniesCorpses(_ def: UnitDefinition) -> Bool {
        def.has(.consecrate) || engine.burnRange(def) != nil
    }

    // MARK: The group attack on the overlord

    /// The chance, in percent, that the units of `side` still to act bring the opposing overlord to zero
    /// this phase. Each attacker is given a tile of its own, so units that cannot all fit are not all
    /// counted. It is an estimate: critical hits are left out, and the tiles are shared out by a simple
    /// rule (the unit with the fewest choices picks first), not by trying every arrangement.
    func overlordKillChance(_ side: Side, in state: GameState) -> Int {
        guard let overlord = state.units(of: side.opponent).first(where: { engine.definition(of: $0).overlord }) else {
            return 0
        }
        struct Option { var tile: Position; var damage: Int; var hit: Int }
        var choices: [(id: Int, options: [Option])] = []
        for unit in state.units(of: side) where !unit.hasActed {
            let def = engine.definition(of: unit)
            let tiles = unit.hasMoved ? [unit.position] : engine.reachable(for: unit, in: state).keys.sorted()
            var options: [Option] = []
            for tile in tiles where engine.inRange(def, from: tile, to: overlord.position) {
                let o = engine.odds(attacker: unit, at: tile, defender: overlord, at: overlord.position, in: state)
                if o.hitChance > 0 { options.append(Option(tile: tile, damage: o.damage, hit: o.hitChance)) }
            }
            if !options.isEmpty { choices.append((unit.id, options)) }
        }
        choices.sort { ($0.options.count, $0.id) < ($1.options.count, $1.id) }

        var taken: Set<Position> = []
        var strikes: [(damage: Int, hit: Int)] = []
        for choice in choices {
            let free = choice.options.filter { !taken.contains($0.tile) }
            guard let pick = free.max(by: { ($0.damage * $0.hit, $1.tile) < ($1.damage * $1.hit, $0.tile) }) else { continue }
            taken.insert(pick.tile)
            strikes.append((pick.damage, pick.hit))
        }

        // The spread of total damage, in parts per million, capped at the overlord's health.
        let need = overlord.hp
        var spread = [Int](repeating: 0, count: need + 1)
        spread[0] = 1_000_000
        for strike in strikes {
            var next = [Int](repeating: 0, count: need + 1)
            for (total, share) in spread.enumerated() where share > 0 {
                let landed = share * strike.hit / 100
                next[min(need, total + strike.damage)] += landed
                next[total] += share - landed
            }
            spread = next
        }
        return spread[need] / 10_000
    }

    /// True when the group attack on the overlord is worth calling: the chance that it falls this phase
    /// is at least `overlordAssaultMinChance`.
    func canKillOverlordThisPhase(_ side: Side, in state: GameState) -> Bool {
        let chance = overlordKillChance(side, in: state)
        return chance > 0 && chance >= weights.overlordAssaultMinChance
    }

    // MARK: Planning one unit

    public func plan(for unit: BattleUnit, in state: GameState) -> Plan {
        let def = engine.definition(of: unit)
        let rules = engine.data.rules
        let w = weights
        let foeSide = unit.side.opponent
        let foes = state.units(of: foeSide)
        let reach = unit.hasMoved ? [unit.position: 0] : engine.reachable(for: unit, in: state)
        let tiles = reach.keys.sorted()
        let corpseTiles = Set(state.corpses.map(\.position)).sorted()
        let anyOpenPile = corpseTiles.contains { !state.isConsecrated($0) }
        let assault = canKillOverlordThisPhase(unit.side, in: state)

        // A unit whose job is to deny bodies keeps out of reach while it has fighters to stand behind.
        let allies = state.units(of: unit.side).filter { $0.id != unit.id }
        let hasFighters = allies.contains { !deniesCorpses(engine.definition(of: $0)) }
        let cautious = deniesCorpses(def) && hasFighters

        // What ending the turn on a tile is likely to cost in the other side's next phase.
        var strikeTiles: [(foe: BattleUnit, tiles: Set<Position>)] = []
        if cautious {
            for foe in foes {
                let foeDef = engine.definition(of: foe)
                var covered: Set<Position> = []
                for from in engine.reachable(for: foe, in: state).keys {
                    for tile in tiles where engine.inRange(foeDef, from: from, to: tile) { covered.insert(tile) }
                }
                strikeTiles.append((foe, covered))
            }
        }
        var exposureCache: [Position: Int] = [:]
        func exposure(_ tile: Position) -> Int {
            guard cautious else { return 0 }
            if let known = exposureCache[tile] { return known }
            var expected = 0
            for (foe, covered) in strikeTiles where covered.contains(tile) {
                let o = engine.odds(attacker: foe, at: foe.position, defender: unit, at: tile, in: state)
                expected += o.damage * o.hitChance
            }
            expected /= 100
            let cost = expected * w.exposureDamage + (expected >= unit.hp ? w.exposureDeath : 0)
            exposureCache[tile] = cost
            return cost
        }

        var best: Plan?
        var bestSteps = Int.max
        /// The best attack from each tile and overall, kept even when it scores nothing, for a unit with no better choice.
        var attackAt: [Position: Plan] = [:]
        var bestAttack: Plan?
        var bestAttackSteps = Int.max

        func consider(_ tile: Position, _ action: Action, _ raw: Int) {
            let score = raw - exposure(tile)
            let steps = reach[tile] ?? 0
            // Ties go to the tile that takes the fewest steps (the unit's own first), then to the earlier candidate.
            if best == nil || score > best!.score || (score == best!.score && steps < bestSteps) {
                best = Plan(moveTo: tile == unit.position ? nil : tile, action: action, score: score)
                bestSteps = steps
            }
        }

        // Blessings this caster would give up by casting once more, for working out what a new one would cost.
        let lapsing = engine.areasThatWouldLapse(for: unit.id, in: state)

        for tile in tiles {
            // Attacks.
            for foe in foes where engine.inRange(def, from: tile, to: foe.position) {
                let f = engine.forecast(attacker: unit, defender: foe, from: tile, in: state)
                guard f.strike.hitChance > 0 else { continue }
                let foeDef = engine.definition(of: foe)
                var onHit = f.strike.damage * w.damage
                if f.strike.kills {
                    onHit += w.kill
                    if foeDef.overlord { onHit += w.overlordKill }
                    if def.type == .holy { onHit += w.holyKill }
                } else if foeDef.overlord {
                    onHit += w.overlordPressure
                }
                if foeDef.has(.raise) { onHit += w.raiserTarget }
                var score = onHit * f.strike.hitChance / 100

                var risk = 0
                var replyLikelyKills = false
                if let back = f.counter {
                    // The reply only comes if the target survives.
                    let survives = f.strike.kills ? 100 - f.strike.hitChance : 100
                    risk = (back.damage * w.counterDamage + (back.kills ? w.counterDeath : 0)) * back.hitChance / 100 * survives / 100
                    replyLikelyKills = back.kills && back.hitChance * survives / 100 >= 50
                }
                let action = Action.attack(unit: unit.id, target: foe.id)
                if assault && foeDef.overlord {
                    // The overlord can fall this phase: everyone who can reach it attacks, whatever it costs them.
                    score += w.overlordAssault
                } else {
                    score -= risk
                    let steps = reach[tile] ?? 0
                    let fallback = Plan(moveTo: tile == unit.position ? nil : tile, action: action, score: score)
                    if attackAt[tile] == nil || score > attackAt[tile]!.score { attackAt[tile] = fallback }
                    if bestAttack == nil || score > bestAttack!.score || (score == bestAttack!.score && steps < bestAttackSteps) {
                        bestAttack = fallback
                        bestAttackSteps = steps
                    }
                    // An attack that can land beats standing still, unless the reply would probably kill the attacker.
                    if score <= 0 && !replyLikelyKills { score = 1 }
                }
                consider(tile, action, score)
            }

            // Destroying corpses.
            if let range = engine.burnRange(def) {
                for pile in corpseTiles where tile.distance(to: pile) <= range {
                    let worth = state.corpses(at: pile).map(value(of:)).reduce(0, +)
                    var score = worth * w.burnValue
                    if canRaiseSoon(foeSide, at: pile, in: state) { score += w.burnReach }
                    if state.isConsecrated(pile) {
                        // Blessed ground is already denied. Fire goes there only when no body lies open anywhere.
                        if anyOpenPile { continue }
                        score /= max(1, w.alreadyDeniedDivisor)
                    }
                    consider(tile, .burn(unit: unit.id, tile: pile), score)
                }
            }

            // Consecrating corpses.
            if def.has(.consecrate) {
                var centres: Set<Position> = []
                for pile in corpseTiles {
                    for c in [pile] + pile.neighbours
                    where state.contains(c) && state.terrain(at: c).isPassable && tile.distance(to: c) <= rules.consecrateRange {
                        centres.insert(c)
                    }
                }
                for centre in centres.sorted() {
                    let covered = Set([centre] + centre.neighbours)
                    var gain = 0
                    for c in state.corpses where covered.contains(c.position) && !state.isConsecrated(c.position) {
                        gain += denialValue(of: c, against: foeSide, in: state)
                    }
                    guard gain > 0 else { continue }
                    // At the limit, a new area costs an old one. Count what that would uncover.
                    var loss = 0
                    if !lapsing.isEmpty {
                        let gone = Set(lapsing.map(\.sequence))
                        let stillCovered = Set(state.consecrations
                            .filter { !($0.casterID == unit.id && gone.contains($0.sequence)) }
                            .flatMap(\.tiles)).union(covered)
                        let uncovered = Set(lapsing.flatMap(\.tiles)).subtracting(stillCovered)
                        for c in state.corpses where uncovered.contains(c.position) {
                            loss += denialValue(of: c, against: foeSide, in: state)
                        }
                    }
                    if gain > loss { consider(tile, .consecrate(unit: unit.id, tile: centre), gain - loss) }
                }
            }

            // Healing a badly hurt ally.
            for ally in engine.healTargets(for: unit, from: tile, in: state) {
                let maxHP = engine.definition(of: ally).maxHP
                guard ally.hp * 2 <= maxHP else { continue }
                let amount = def.has(.heal) ? rules.healAmount : rules.mendHeal
                consider(tile, .heal(unit: unit.id, target: ally.id), min(amount, maxHP - ally.hp) * w.heal)
            }
        }

        if let best, best.score > 0 { return best }

        // Nothing worth doing. A unit never ends its turn idle with a target in range: it falls back to a
        // healer if it is badly hurt and has one, keeps its distance if its job is denying bodies, and
        // otherwise takes the best attack it has, poor as it is.
        let goal = unit.hasMoved ? nil : advanceGoal(for: unit, def: def, allies: allies, in: state)
        if !cautious, goal?.isRetreat != true, let bestAttack { return bestAttack }

        var destination = unit.position
        if let goal {
            let walk = walkingDistances(to: goal, for: unit, def: def, in: state)
            destination = tiles.min { a, b in
                (exposure(a) > 0 ? 1 : 0, walk[a] ?? Int.max, reach[a] ?? 0, a)
                    < (exposure(b) > 0 ? 1 : 0, walk[b] ?? Int.max, reach[b] ?? 0, b)
            } ?? unit.position
        }
        // A unit that cannot get out of reach fights.
        if cautious, exposure(destination) > 0, let bestAttack { return bestAttack }
        if let attack = attackAt[destination] { return attack }
        return Plan(moveTo: destination == unit.position ? nil : destination, action: .wait(unit: unit.id), score: 0)
    }

    /// Where a unit with nothing to do this phase should head, and how near it needs to get.
    private struct Goal {
        var position: Position
        var minRange: Int
        var maxRange: Int
        var isRetreat = false
    }

    /// Walking distance from each tile to the nearest free tile from which the goal is within range,
    /// going round other units. If there is no such tile, the plain distance to the goal.
    private func walkingDistances(to goal: Goal, for unit: BattleUnit, def: UnitDefinition, in state: GameState) -> [Position: Int] {
        var targets: [Position] = []
        let span = goal.maxRange
        for dy in -span...span {
            for dx in -(span - abs(dy))...(span - abs(dy)) {
                let tile = Position(goal.position.x + dx, goal.position.y + dy)
                let d = abs(dx) + abs(dy)
                guard d >= goal.minRange, state.contains(tile), state.terrain(at: tile).isPassable else { continue }
                if let other = state.unit(at: tile), other.id != unit.id { continue }
                targets.append(tile)
            }
        }
        let walk = engine.distances(toAnyOf: targets, for: unit, in: state)
        if walk[unit.position] != nil { return walk }
        return engine.distances(to: goal.position, for: unit, in: state)
    }

    private func advanceGoal(for unit: BattleUnit, def: UnitDefinition, allies: [BattleUnit], in state: GameState) -> Goal? {
        func nearest(_ points: [Position]) -> Position? {
            points.min { a, b in
                (a.distance(to: unit.position), a) < (b.distance(to: unit.position), b)
            }
        }
        let rules = engine.data.rules
        let foeSide = unit.side.opponent

        // A badly hurt unit falls back to a healer.
        if unit.hp * 3 <= def.maxHP,
           let healer = nearest(allies.filter { engine.definition(of: $0).has(.heal) || engine.definition(of: $0).has(.mend) }.map(\.position)) {
            return Goal(position: healer, minRange: 1, maxRange: max(1, min(rules.healRange, rules.mendRange)), isRetreat: true)
        }

        if deniesCorpses(def) {
            // Go for the group of open bodies worth the most to deny, counting bodies within one tile together.
            var bestTile: Position?
            var bestWorth = 0
            for pile in Set(state.corpses.map(\.position)).sorted() where !state.isConsecrated(pile) {
                let group = state.corpses.filter { $0.position.distance(to: pile) <= 1 && !state.isConsecrated($0.position) }
                let worth = group.map { denialValue(of: $0, against: foeSide, in: state) }.reduce(0, +)
                if worth > bestWorth {
                    bestWorth = worth
                    bestTile = pile
                }
            }
            if let bestTile {
                let range = def.has(.consecrate) ? rules.consecrateRange : (engine.burnRange(def) ?? 1)
                return Goal(position: bestTile, minRange: 0, maxRange: range)
            }
            // No bodies to deny: stay with the fighters instead of leading the charge.
            let fighters = allies.filter { !deniesCorpses(engine.definition(of: $0)) }
            if let escort = nearest(fighters.map(\.position)) { return Goal(position: escort, minRange: 1, maxRange: 1) }
        }
        guard let foe = nearest(state.units(of: foeSide).map(\.position)) else { return nil }
        return Goal(position: foe, minRange: def.minRange, maxRange: def.maxRange)
    }

    // MARK: Playing a phase

    /// Plays one enemy unit's turn, or ends the phase when every unit has acted.
    /// The renderer calls this repeatedly and animates the events from each call.
    ///
    /// Fire users act first, then the rest, each group in id order. A burned body is gone for good,
    /// so the clerics that follow spend their blessings on what is left.
    @discardableResult
    public func step(_ state: inout GameState) throws -> [Event] {
        guard state.phase == .enemy, state.outcome == .ongoing else { return [] }
        let waiting = state.units(of: .enemy).filter { !$0.hasActed }
        guard let unit = waiting.first(where: { engine.burnRange(engine.definition(of: $0)) != nil }) ?? waiting.first else {
            return try engine.apply(.endPhase, to: &state)
        }
        let plan = plan(for: unit, in: state)
        var events: [Event] = []
        if let to = plan.moveTo {
            events += try engine.apply(.move(unit: unit.id, to: to), to: &state)
        }
        events += try engine.apply(plan.action, to: &state)
        return events
    }

    /// Plays the whole enemy phase and hands the turn back to the player.
    @discardableResult
    public func runPhase(_ state: inout GameState) throws -> [Event] {
        var events: [Event] = []
        while state.phase == .enemy && state.outcome == .ongoing {
            events += try step(&state)
        }
        return events
    }
}
