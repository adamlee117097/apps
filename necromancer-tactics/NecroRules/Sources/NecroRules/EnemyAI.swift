import Foundation

/// The enemy's decision-making. It has no randomness of its own: the same state always gives the same plan.
///
/// Each unit looks at every tile it can reach and every action it could take from there, scores
/// each by its expected value (what success is worth times the chance of it, minus the expected
/// cost of the reply), and takes the best. The weights are data, in `rules.json` under `ai`.
///
/// Corpse denial is scored directly: clerics are rewarded for consecrating bodies a raiser could
/// reach, and fire users for burning them. The planning works for either side, which the tests use
/// to drive a player.
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

    /// True when the units of `side` still to act could bring the opposing overlord to zero this phase
    /// if their attacks land. Each unit is counted from its best tile, without checking that they fit together.
    func canKillOverlordThisPhase(_ side: Side, in state: GameState) -> Bool {
        guard let overlord = state.units(of: side.opponent).first(where: { engine.definition(of: $0).overlord }) else {
            return false
        }
        var total = 0
        for unit in state.units(of: side) where !unit.hasActed {
            let def = engine.definition(of: unit)
            let tiles = unit.hasMoved ? [unit.position] : Array(engine.reachable(for: unit, in: state).keys)
            var best = 0
            for tile in tiles where engine.inRange(def, from: tile, to: overlord.position) {
                let o = engine.odds(attacker: unit, at: tile, defender: overlord, at: overlord.position, in: state)
                if o.hitChance > 0 { best = max(best, o.damage) }
            }
            total += best
        }
        return total >= overlord.hp
    }

    public func plan(for unit: BattleUnit, in state: GameState) -> Plan {
        let def = engine.definition(of: unit)
        let rules = engine.data.rules
        let w = weights
        let foeSide = unit.side.opponent
        let foes = state.units(of: foeSide)
        let tiles = unit.hasMoved ? [unit.position] : engine.reachable(for: unit, in: state).keys.sorted()
        let corpseTiles = Set(state.corpses.map(\.position)).sorted()
        let assault = canKillOverlordThisPhase(unit.side, in: state)
        var best: Plan?

        func consider(_ tile: Position, _ action: Action, _ score: Int) {
            // Ties go to the earlier candidate; candidates are generated in a fixed order.
            if best == nil || score > best!.score {
                best = Plan(moveTo: tile == unit.position ? nil : tile, action: action, score: score)
            }
        }

        // Blessings this caster already holds, oldest first, for working out what a new one would cost.
        let ownAreas = state.consecrations.filter { $0.casterID == unit.id }.sorted { $0.sequence < $1.sequence }

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
                if assault && foeDef.overlord {
                    // The overlord can fall this phase: everyone who can reach it attacks, whatever it costs them.
                    score += w.overlordAssault
                } else {
                    score -= risk
                    // An attack that can land beats standing still, unless the reply would probably kill the attacker.
                    if score <= 0 && !replyLikelyKills { score = 1 }
                }
                consider(tile, .attack(unit: unit.id, target: foe.id), score)
            }

            // Destroying corpses.
            if let range = engine.burnRange(def) {
                for pile in corpseTiles where tile.distance(to: pile) <= range {
                    let worth = state.corpses(at: pile).map(value(of:)).reduce(0, +)
                    var score = worth * w.burnValue
                    if canRaiseSoon(foeSide, at: pile, in: state) { score += w.burnReach }
                    // Ground that is already blessed is already denied.
                    if state.isConsecrated(pile) { score /= max(1, w.alreadyDeniedDivisor) }
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
                    // At the limit, a new area lapses this caster's oldest. Count what that would uncover.
                    var loss = 0
                    if ownAreas.count >= rules.maxConsecrationsPerCaster, let oldest = ownAreas.first {
                        let stillCovered = Set(state.consecrations
                            .filter { !($0.casterID == oldest.casterID && $0.sequence == oldest.sequence) }
                            .flatMap(\.tiles)).union(covered)
                        for c in state.corpses where oldest.tiles.contains(c.position) && !stillCovered.contains(c.position) {
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

        // Nothing worth doing from here: head for a goal by the shortest walk, round walls if need be.
        guard !unit.hasMoved, let goal = advanceGoal(for: unit, def: def, in: state) else {
            return Plan(moveTo: nil, action: .wait(unit: unit.id), score: 0)
        }
        let walk = engine.distances(to: goal, for: unit, in: state)
        let destination = tiles.min { a, b in
            (walk[a] ?? Int.max, a) < (walk[b] ?? Int.max, b)
        } ?? unit.position
        return Plan(moveTo: destination == unit.position ? nil : destination, action: .wait(unit: unit.id), score: 0)
    }

    private func advanceGoal(for unit: BattleUnit, def: UnitDefinition, in state: GameState) -> Position? {
        func nearest(_ points: [Position]) -> Position? {
            points.min { a, b in
                (a.distance(to: unit.position), a) < (b.distance(to: unit.position), b)
            }
        }
        let allies = state.units(of: unit.side).filter { $0.id != unit.id }
        let foeSide = unit.side.opponent

        // A badly hurt unit falls back to a healer.
        if unit.hp * 3 <= def.maxHP,
           let healer = nearest(allies.filter { engine.definition(of: $0).has(.heal) || engine.definition(of: $0).has(.mend) }.map(\.position)) {
            return healer
        }

        let deniesCorpses = def.has(.consecrate) || engine.burnRange(def) != nil
        if deniesCorpses {
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
            if let bestTile { return bestTile }
            // No bodies to deny: stay with the fighters instead of leading the charge.
            let fighters = allies.filter {
                let d = engine.definition(of: $0)
                return !d.has(.consecrate) && engine.burnRange(d) == nil
            }
            if let escort = nearest(fighters.map(\.position)) { return escort }
        }
        return nearest(state.units(of: foeSide).map(\.position))
    }

    /// Plays one enemy unit's turn, or ends the phase when every unit has acted.
    /// The renderer calls this repeatedly and animates the events from each call.
    @discardableResult
    public func step(_ state: inout GameState) throws -> [Event] {
        guard state.phase == .enemy, state.outcome == .ongoing else { return [] }
        guard let unit = state.units(of: .enemy).first(where: { !$0.hasActed }) else {
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
