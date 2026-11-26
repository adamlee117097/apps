import Foundation
import Testing
@testable import NecroRules

/// A simple scripted player used to drive whole battles in tests: every unit attacks the
/// first enemy it can reach, otherwise walks toward the nearest enemy.
func playScriptedPlayerPhase(_ engine: Engine, _ state: inout GameState) throws {
    for id in state.units(of: .player).map(\.id) {
        guard state.outcome == .ongoing, let unit = state.unit(id: id), !unit.hasActed else { continue }
        let def = engine.definition(of: unit)
        if def.overlord {
            if let corpse = engine.raisableCorpses(for: unit, in: state).first,
               engine.commandCount(in: state) < state.commandCap {
                try engine.apply(.raise(unit: id, corpse: corpse.id), to: &state)
            } else {
                try engine.apply(.wait(unit: id), to: &state)
            }
            continue
        }
        let enemies = state.units(of: .enemy)
        let tiles = engine.reachable(for: unit, in: state).keys.sorted()
        var done = false
        for tile in tiles {
            if let target = enemies.first(where: { engine.inRange(def, from: tile, to: $0.position) }) {
                if tile != unit.position { try engine.apply(.move(unit: id, to: tile), to: &state) }
                try engine.apply(.attack(unit: id, target: target.id), to: &state)
                done = true
                break
            }
        }
        if done { continue }
        if let goal = enemies.map(\.position).min(by: { ($0.distance(to: unit.position), $0) < ($1.distance(to: unit.position), $1) }),
           let dest = tiles.min(by: { ($0.distance(to: goal), $0) < ($1.distance(to: goal), $1) }), dest != unit.position {
            try engine.apply(.move(unit: id, to: dest), to: &state)
        }
        try engine.apply(.wait(unit: id), to: &state)
    }
    if state.outcome == .ongoing { try engine.apply(.endPhase, to: &state) }
}

func playSlice(turns: Int, seed: UInt64 = 1) throws -> GameState {
    let data = try GameData.bundled()
    let engine = Engine(data: data)
    let ai = EnemyAI(engine: engine)
    var state = try GameState(map: GameData.bundledMap("slice01"), data: data, seed: seed)
    for _ in 0..<turns where state.outcome == .ongoing {
        try playScriptedPlayerPhase(engine, &state)
        try ai.runPhase(&state)
    }
    return state
}

@Suite struct SaveTests {
    @Test func midBattleSaveRoundTrips() throws {
        let state = try playSlice(turns: 3)
        // The state after three turns has moved units, damage, and usually corpses.
        #expect(state.turn == 4 || state.outcome != .ongoing)
        let bytes = try state.saved()
        let loaded = try GameState.load(bytes, data: GameData.bundled())
        #expect(loaded == state)
        #expect(try loaded.saved() == bytes)
    }

    @Test func aLoadedBattleContinuesIdentically() throws {
        let data = try GameData.bundled()
        let engine = Engine(data: data)
        let ai = EnemyAI(engine: engine)
        var original = try playSlice(turns: 2)
        var loaded = try GameState.load(original.saved(), data: data)
        for _ in 0..<3 where original.outcome == .ongoing {
            try playScriptedPlayerPhase(engine, &original)
            try ai.runPhase(&original)
            try playScriptedPlayerPhase(engine, &loaded)
            try ai.runPhase(&loaded)
        }
        #expect(loaded == original)
    }

    @Test func saveCanHappenMidPhase() throws {
        var f = try Fixture(units: [P(unit: "skeleton", side: .player, x: 0, y: 0), P(unit: "militia", side: .enemy, x: 7, y: 4),
                                    P(unit: "overlord", side: .player, x: 0, y: 4)])
        try f.apply(.move(unit: f.id("skeleton"), to: Position(2, 0)))
        var loaded = try GameState.load(f.state.saved(), data: f.data)
        // The half-finished move, including the ability to undo it, survives the save.
        try f.engine.apply(.undoMove(unit: f.id("skeleton")), to: &loaded)
        #expect(loaded.unit(id: f.id("skeleton"))?.position == Position(0, 0))
    }
}

@Suite struct DeterminismTests {
    @Test func theSameBattlePlaysOutTheSameWay() throws {
        let a = try playSlice(turns: 12)
        let b = try playSlice(turns: 12)
        #expect(a == b)
        #expect(try a.saved() == b.saved())
    }

    @Test func aFullBattleRunsToAnOutcomeWithoutRuleErrors() throws {
        let state = try playSlice(turns: 60)
        #expect(state.outcome != .ongoing)
    }
}

@Suite struct EnemyAITests {
    @Test func clericConsecratesCorpsesThePlayerCouldRaise() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 0, y: 2), P(unit: "cleric", side: .enemy, x: 6, y: 2)],
                            corpses: [C(unit: "knight", x: 3, y: 2)])
        try f.apply(.endPhase)
        try f.ai.runPhase(&f.state)
        #expect(f.state.isConsecrated(Position(3, 2)))
        #expect(f.engine.raisableCorpses(for: f.unit("overlord"), in: f.state).isEmpty)
    }

    @Test func clericCoversAsManyCorpsesAsItCan() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 0, y: 2), P(unit: "cleric", side: .enemy, x: 6, y: 2)],
                            corpses: [C(unit: "knight", x: 3, y: 1), C(unit: "militia", x: 3, y: 3)])
        try f.apply(.endPhase)
        try f.ai.runPhase(&f.state)
        // One blessing centred between the two bodies covers both.
        #expect(f.state.isConsecrated(Position(3, 1)))
        #expect(f.state.isConsecrated(Position(3, 3)))
    }

    @Test func pyromancerBurnsTheMostValuablePile() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 0, y: 2), P(unit: "pyromancer", side: .enemy, x: 5, y: 2)],
                            corpses: [C(unit: "warhound", x: 3, y: 0), C(unit: "knight", x: 3, y: 4), C(unit: "reaver", x: 3, y: 4)])
        try f.apply(.endPhase)
        try f.ai.runPhase(&f.state)
        #expect(f.state.corpses.map(\.definitionID) == ["warhound"])
    }

    @Test func burnersWalkTowardCorpsesTheyCannotReachYet() throws {
        var f = try Fixture(width: 12, height: 3, units: [P(unit: "overlord", side: .player, x: 0, y: 0), P(unit: "pyromancer", side: .enemy, x: 11, y: 2)],
                            corpses: [C(unit: "knight", x: 2, y: 2)])
        try f.apply(.endPhase)
        try f.ai.runPhase(&f.state)
        #expect(f.unit("pyromancer", .enemy).position == Position(7, 2))
        #expect(f.state.corpses.count == 1)
    }

    @Test func enemyTakesAKillOnTheOverlordAboveAllElse() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 2, y: 2), P(unit: "pyromancer", side: .enemy, x: 5, y: 2)],
                            corpses: [C(unit: "knight", x: 5, y: 0), C(unit: "knight", x: 5, y: 0)])
        f.state.units[0].hp = 4
        try f.apply(.endPhase)
        try f.ai.runPhase(&f.state)
        #expect(f.state.outcome == .defeat)
    }

    @Test func clericHealsABadlyHurtAllyWhenThereAreNoCorpses() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 0, y: 0), P(unit: "cleric", side: .enemy, x: 6, y: 2),
                                    P(unit: "knight", side: .enemy, x: 7, y: 2)])
        f.state.units[2].hp = 6
        try f.apply(.endPhase)
        try f.ai.runPhase(&f.state)
        #expect(f.unit("knight", .enemy).hp == 12)
    }

    @Test func enemyPhaseHandsTheTurnBack() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 0, y: 0), P(unit: "militia", side: .enemy, x: 7, y: 4)])
        try f.apply(.endPhase)
        let events = try f.ai.runPhase(&f.state)
        #expect(f.state.phase == .player)
        #expect(f.state.turn == 2)
        #expect(events.last == .phaseBegan(side: .player, turn: 2))
    }
}
