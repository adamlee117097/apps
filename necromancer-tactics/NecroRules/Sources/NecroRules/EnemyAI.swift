import Foundation

/// The enemy's decision-making. Deterministic: the same state always gives the same plan.
///
/// Each unit looks at every tile it can reach and every action it could take from there,
/// scores them, and takes the best. Corpse denial is scored directly: clerics are rewarded
/// for consecrating corpses the player could raise, and fire users for burning them.
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

    /// How much the player would gain by raising this corpse.
    func value(of corpse: Corpse) -> Int {
        guard let id = engine.raisedDefinitionID(for: corpse), let def = engine.data.units[id] else { return 0 }
        return def.maxHP + def.might * 2
    }

    /// True if one of the player's raisers could reach raising range of the tile next phase.
    func playerCanRaiseSoon(at tile: Position, in state: GameState) -> Bool {
        state.units(of: .player).contains { u in
            let def = engine.definition(of: u)
            guard def.has(.raise), let range = def.raiseRange else { return false }
            return u.position.distance(to: tile) <= def.move + range
        }
    }

    public func plan(for unit: BattleUnit, in state: GameState) -> Plan {
        let def = engine.definition(of: unit)
        let rules = engine.data.rules
        let foes = state.units(of: unit.side.opponent)
        let tiles = engine.reachable(for: unit, in: state).keys.sorted()
        let corpseTiles = Set(state.corpses.map(\.position)).sorted()
        var best: Plan?

        func consider(_ tile: Position, _ action: Action, _ score: Int) {
            // Ties go to the earlier candidate; candidates are generated in a fixed order.
            if best == nil || score > best!.score {
                best = Plan(moveTo: tile == unit.position ? nil : tile, action: action, score: score)
            }
        }

        for tile in tiles {
            // Attacks.
            for foe in foes where engine.inRange(def, from: tile, to: foe.position) {
                let f = engine.forecast(attacker: unit, defender: foe, from: tile, in: state)
                let foeDef = engine.definition(of: foe)
                var score = f.damage * 10
                if f.matchup == .advantage { score += 10 }
                if f.kills {
                    score += 60
                    if foeDef.overlord { score += 100_000 }
                    // A Holy kill leaves nothing to raise.
                    if def.type == .holy { score += 40 }
                } else if foeDef.overlord {
                    score += 30
                }
                if foeDef.has(.raise) { score += 20 }
                if let back = f.counterDamage {
                    score -= back * 6
                    if f.counterKills { score -= 80 }
                }
                consider(tile, .attack(unit: unit.id, target: foe.id), score)
            }

            // Destroying corpses.
            if def.has(.burnCorpses) || def.has(.purgeCorpses) {
                let range = def.has(.burnCorpses) ? rules.burnRange : rules.purgeRange
                for pile in corpseTiles where tile.distance(to: pile) <= range {
                    let worth = state.corpses(at: pile).map(value(of:)).reduce(0, +)
                    var score = worth * 2
                    if playerCanRaiseSoon(at: pile, in: state) { score += 50 }
                    // Ground that is already blessed is already denied.
                    if state.isConsecrated(pile) { score /= 4 }
                    consider(tile, .burn(unit: unit.id, tile: pile), score)
                }
            }

            // Consecrating corpses.
            if def.has(.consecrate) {
                var centres: Set<Position> = []
                for pile in corpseTiles {
                    for c in [pile] + pile.neighbours where state.contains(c) && tile.distance(to: c) <= rules.consecrateRange {
                        centres.insert(c)
                    }
                }
                for centre in centres.sorted() {
                    let covered = [centre] + centre.neighbours
                    var score = 0
                    for c in state.corpses where covered.contains(c.position) && !state.isConsecrated(c.position) {
                        score += value(of: c) * 2
                        if playerCanRaiseSoon(at: c.position, in: state) { score += 40 }
                    }
                    if score > 0 { consider(tile, .consecrate(unit: unit.id, tile: centre), score) }
                }
            }

            // Healing a badly hurt ally.
            if def.has(.heal) {
                for ally in state.units(of: unit.side) where ally.id != unit.id && tile.distance(to: ally.position) <= rules.healRange {
                    let maxHP = engine.definition(of: ally).maxHP
                    guard ally.hp * 2 <= maxHP else { continue }
                    consider(tile, .heal(unit: unit.id, target: ally.id), min(rules.healAmount, maxHP - ally.hp) * 8)
                }
            }
        }

        if let best, best.score > 0 { return best }

        // Nothing worth doing from here: advance on a goal.
        let goal = advanceGoal(for: unit, def: def, in: state)
        let destination = tiles.min { a, b in
            (a.distance(to: goal), a) < (b.distance(to: goal), b)
        } ?? unit.position
        return Plan(moveTo: destination == unit.position ? nil : destination, action: .wait(unit: unit.id), score: 0)
    }

    private func advanceGoal(for unit: BattleUnit, def: UnitDefinition, in state: GameState) -> Position {
        func nearest(_ points: [Position]) -> Position? {
            points.min { a, b in
                (a.distance(to: unit.position), a) < (b.distance(to: unit.position), b)
            }
        }
        let foes = state.units(of: unit.side.opponent).map(\.position)
        if def.has(.consecrate) || def.has(.burnCorpses) || def.has(.purgeCorpses) {
            let open = state.corpses.map(\.position).filter { !state.isConsecrated($0) }
            if let target = nearest(open) { return target }
        }
        return nearest(foes) ?? unit.position
    }

    /// Plays the whole enemy phase and hands the turn back to the player.
    @discardableResult
    public func runPhase(_ state: inout GameState) throws -> [Event] {
        var events: [Event] = []
        guard state.phase == .enemy, state.outcome == .ongoing else { return events }
        for id in state.units(of: .enemy).map(\.id) {
            guard state.outcome == .ongoing, let unit = state.unit(id: id) else { continue }
            let plan = plan(for: unit, in: state)
            if let to = plan.moveTo {
                events += try engine.apply(.move(unit: id, to: to), to: &state)
            }
            events += try engine.apply(plan.action, to: &state)
        }
        if state.outcome == .ongoing {
            events += try engine.apply(.endPhase, to: &state)
        }
        return events
    }
}
