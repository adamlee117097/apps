import Foundation
@testable import NecroRules

typealias P = MapDefinition.Placement
typealias C = MapDefinition.CorpsePlacement

struct Fixture {
    var data: GameData
    let engine: Engine
    let ai: EnemyAI
    var state: GameState

    /// An open field of the given size unless `rows` is supplied.
    /// With `certainHits` (the default) every attack lands and none is critical, so tests of
    /// other rules do not depend on rolls. Pass false to use the real chances.
    init(width: Int = 8, height: Int = 5, rows: [String]? = nil, cap: Int = 5, certainHits: Bool = true, seed: UInt64 = 1,
         units: [P], corpses: [C] = []) throws {
        data = try GameData.bundled()
        if certainHits {
            for key in data.units.keys {
                data.units[key]!.hit = 1000
                data.units[key]!.crit = 0
            }
        }
        engine = Engine(data: data)
        ai = EnemyAI(engine: engine)
        let map = MapDefinition(id: "test", name: "Test", commandCap: cap,
                                rows: rows ?? Array(repeating: String(repeating: ".", count: width), count: height),
                                units: units, corpses: corpses)
        // Small set-ups need not be winnable battles, so the playability checks are skipped here.
        state = try GameState(map: map, data: data, seed: seed, requirePlayable: false)
    }

    /// The id of the first unit of this kind on this side.
    func id(_ kind: String, _ side: Side = .player) -> Int {
        state.units.first { $0.definitionID == kind && $0.side == side }!.id
    }

    func unit(_ kind: String, _ side: Side = .player) -> BattleUnit {
        state.unit(id: id(kind, side))!
    }

    @discardableResult
    mutating func apply(_ action: Action) throws -> [Event] {
        try engine.apply(action, to: &state)
    }
}

/// A simple but competent player for whole-battle tests. The overlord walks to bodies and raises
/// them while keeping out of the enemy's reach where it can; every other unit uses the same
/// planning the enemy does.
/// Returns how many bodies the overlord raised.
@discardableResult
func playBotPlayerPhase(_ engine: Engine, _ ai: EnemyAI, _ state: inout GameState) throws -> Int {
    var raises = 0
    for id in state.units(of: .player).map(\.id) {
        guard state.outcome == .ongoing, let unit = state.unit(id: id), !unit.hasActed else { continue }
        guard engine.definition(of: unit).overlord else {
            let plan = ai.plan(for: unit, in: state)
            if let to = plan.moveTo { try engine.apply(.move(unit: id, to: to), to: &state) }
            try engine.apply(plan.action, to: &state)
            continue
        }
        func bestRaise(_ s: GameState) -> Corpse? {
            guard !engine.isAtCommandCap(in: s), let me = s.unit(id: id) else { return nil }
            return engine.raisableCorpses(for: me, in: s).max { (ai.value(of: $0), $1.id) < (ai.value(of: $1), $0.id) }
        }
        if let corpse = bestRaise(state) {
            try engine.apply(.raise(unit: id, corpse: corpse.id), to: &state)
            raises += 1
            continue
        }
        let danger = engine.threatenedTiles(by: .enemy, in: state)
        let open = state.corpses.filter { !state.isConsecrated($0.position) }.map(\.position)
        let tiles = engine.reachable(for: unit, in: state).keys.sorted()
        let safe = tiles.filter { !danger.contains($0) }
        if !engine.isAtCommandCap(in: state),
           let goal = open.min(by: { ($0.distance(to: unit.position), $0) < ($1.distance(to: unit.position), $1) }) {
            let walk = engine.distances(to: goal, for: unit, in: state)
            let pool = safe.isEmpty ? tiles : safe
            if let dest = pool.min(by: { (walk[$0] ?? .max, $0) < (walk[$1] ?? .max, $1) }), dest != unit.position {
                try engine.apply(.move(unit: id, to: dest), to: &state)
            }
        } else if danger.contains(unit.position),
                  let dest = safe.max(by: { a, b in
                      let da = state.units(of: .enemy).map { $0.position.distance(to: a) }.min() ?? 0
                      let db = state.units(of: .enemy).map { $0.position.distance(to: b) }.min() ?? 0
                      return (da, b) < (db, a)
                  }), dest != unit.position {
            try engine.apply(.move(unit: id, to: dest), to: &state)
        }
        if let corpse = bestRaise(state) {
            try engine.apply(.raise(unit: id, corpse: corpse.id), to: &state)
            raises += 1
        } else {
            try engine.apply(.wait(unit: id), to: &state)
        }
    }
    if state.outcome == .ongoing { try engine.apply(.endPhase, to: &state) }
    return raises
}

/// Plays the slice map with the bot player against the enemy AI.
func playSliceWithBot(seed: UInt64, turns: Int = 80) throws -> (state: GameState, raises: Int, consecrations: Int, burns: Int) {
    let data = try GameData.bundled()
    let engine = Engine(data: data)
    let ai = EnemyAI(engine: engine)
    var state = try GameState(map: GameData.bundledMap("slice01"), data: data, seed: seed)
    var raises = 0, consecrations = 0, burns = 0
    for _ in 0..<turns where state.outcome == .ongoing {
        raises += try playBotPlayerPhase(engine, ai, &state)
        while state.phase == .enemy && state.outcome == .ongoing {
            for event in try ai.step(&state) {
                if case .consecrated = event { consecrations += 1 }
                if case .corpsesDestroyed = event { burns += 1 }
            }
        }
    }
    return (state, raises, consecrations, burns)
}
