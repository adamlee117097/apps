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
        state = try GameState(map: map, data: data, seed: seed)
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
