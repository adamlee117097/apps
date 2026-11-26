import Foundation
import Testing
@testable import NecroRules

/// Tests added after the independent review of 2026-11-26. Each one failed before its fix.
@Suite struct UndoTests {
    @Test func onlyTheLatestMoveCanBeUndone() throws {
        var f = try Fixture(units: [P(unit: "skeleton", side: .player, x: 0, y: 0), P(unit: "ghoul", side: .player, x: 0, y: 1),
                                    P(unit: "militia", side: .enemy, x: 7, y: 4)])
        try f.apply(.move(unit: f.id("skeleton"), to: Position(2, 0)))
        // The ghoul takes the tile the skeleton left. That order makes the skeleton's move final.
        try f.apply(.move(unit: f.id("ghoul"), to: Position(0, 0)))
        #expect(throws: RuleError.nothingToUndo) { try f.apply(.undoMove(unit: f.id("skeleton"))) }
        #expect(f.unit("skeleton").position == Position(2, 0))
        // The ghoul's own move is the latest, so it can still be taken back.
        try f.apply(.undoMove(unit: f.id("ghoul")))
        #expect(f.unit("ghoul").position == Position(0, 1))
        #expect(Set(f.state.units.map(\.position)).count == f.state.units.count)
    }

    @Test func aMoveCannotBeUndoneAfterAnotherUnitUsedIt() throws {
        // A Dread Knight steps next to a skeleton to lend it Bulwark for one attack, then tries to step back.
        var f = try Fixture(units: [P(unit: "dread_knight", side: .player, x: 1, y: 1), P(unit: "skeleton", side: .player, x: 3, y: 0),
                                    P(unit: "militia", side: .enemy, x: 4, y: 0)])
        try f.apply(.move(unit: f.id("dread_knight"), to: Position(3, 1)))
        try f.apply(.attack(unit: f.id("skeleton"), target: f.id("militia", .enemy)))
        #expect(throws: RuleError.nothingToUndo) { try f.apply(.undoMove(unit: f.id("dread_knight"))) }
    }

    @Test func undoNeverStacksTwoUnits() throws {
        var f = try Fixture(units: [P(unit: "skeleton", side: .player, x: 0, y: 0), P(unit: "ghoul", side: .player, x: 0, y: 1),
                                    P(unit: "militia", side: .enemy, x: 7, y: 4)])
        try f.apply(.move(unit: f.id("skeleton"), to: Position(2, 0)))
        // Force the situation the engine's own orders can no longer create: another unit on the origin tile.
        f.state.units[1].position = Position(0, 0)
        #expect(throws: RuleError.tileOccupied) { try f.apply(.undoMove(unit: f.id("skeleton"))) }
    }
}

@Suite struct LeavingTheBoardTests {
    @Test func theEnemyCannotDismiss() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 0, y: 0), P(unit: "militia", side: .enemy, x: 7, y: 4)])
        try f.apply(.endPhase)
        #expect(throws: RuleError.playerOnly) { try f.apply(.dismiss(unit: f.id("militia", .enemy))) }
        #expect(f.state.units(of: .enemy).count == 1)
    }

    @Test func dismissingACasterEndsItsConsecration() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 0, y: 0), P(unit: "skeleton", side: .player, x: 2, y: 2),
                                    P(unit: "militia", side: .enemy, x: 7, y: 4)])
        let skeleton = f.id("skeleton")
        f.state.consecrations = [Consecration(casterID: skeleton, sequence: 1, tiles: [Position(4, 2)])]
        f.state.nextSequence = 2
        let events = try f.apply(.dismiss(unit: skeleton))
        #expect(f.state.consecrations.isEmpty)
        #expect(events.contains(.consecrationEnded(tiles: [Position(4, 2)])))
    }

    @Test func consecrationEndedNamesOnlyTilesThatAreNoLongerBlessed() throws {
        // Two clerics bless overlapping ground. When one dies, the shared tiles stay blessed and must not be reported.
        var f = try Fixture(units: [P(unit: "ghoul", side: .player, x: 2, y: 3), P(unit: "cleric", side: .enemy, x: 2, y: 2),
                                    P(unit: "cleric", side: .enemy, x: 6, y: 2), P(unit: "militia", side: .enemy, x: 7, y: 4)])
        let first = f.state.units[1].id, second = f.state.units[2].id
        try f.apply(.endPhase)
        try f.apply(.consecrate(unit: first, tile: Position(3, 2)))
        try f.apply(.consecrate(unit: second, tile: Position(4, 2)))
        try f.apply(.endPhase)
        let events = try f.apply(.attack(unit: f.id("ghoul"), target: first))
        #expect(f.state.unit(id: first) == nil)
        let ended = events.compactMap { event -> [Position]? in
            if case let .consecrationEnded(tiles) = event { return tiles } else { return nil }
        }
        #expect(ended.count == 1)
        // The first area covered (3,2) and its neighbours; (3,2) and (4,2) are still covered by the second.
        #expect(ended.first == [Position(3, 1), Position(2, 2), Position(3, 3)])
        for tile in ended.first ?? [] { #expect(!f.state.isConsecrated(tile)) }
        #expect(f.state.isConsecrated(Position(3, 2)))
    }

    @Test func consecrationSkipsWallsAndCannotTargetOne() throws {
        var f = try Fixture(rows: ["........", "...#....", "........"],
                            units: [P(unit: "overlord", side: .player, x: 0, y: 0), P(unit: "cleric", side: .enemy, x: 4, y: 0)])
        try f.apply(.endPhase)
        #expect(throws: RuleError.invalidTarget) { try f.apply(.consecrate(unit: f.id("cleric", .enemy), tile: Position(3, 1))) }
        try f.apply(.consecrate(unit: f.id("cleric", .enemy), tile: Position(3, 0)))
        #expect(!f.state.isConsecrated(Position(3, 1)))
        #expect(f.state.isConsecrated(Position(3, 0)))
    }

    @Test func aRaisedUnitKeepsItsIdentity() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 1, y: 1), P(unit: "skeleton", side: .player, x: 2, y: 1),
                                    P(unit: "knight", side: .enemy, x: 3, y: 1)])
        let skeleton = f.id("skeleton")
        f.state.units[1].hp = 1
        try f.apply(.endPhase)
        try f.apply(.attack(unit: f.id("knight", .enemy), target: skeleton))
        let corpse = try #require(f.state.corpses.first)
        #expect(corpse.unitID == skeleton)
        #expect(corpse.side == .player)
        try f.apply(.endPhase)
        let events = try f.apply(.raise(unit: f.id("overlord"), corpse: corpse.id))
        #expect(f.state.unit(id: skeleton)?.definitionID == "skeleton")
        #expect(events == [.raised(unit: skeleton, definitionID: "skeleton", at: Position(2, 1), by: f.id("overlord"), corpse: corpse.id)])
        #expect(f.state.units.map(\.id) == f.state.units.map(\.id).sorted())
    }
}

@Suite struct MapValidationTests {
    func map(units: [P], corpses: [C] = [], cap: Int = 5) -> MapDefinition {
        MapDefinition(id: "t", name: "T", commandCap: cap, rows: Array(repeating: "........", count: 4), units: units, corpses: corpses)
    }

    @Test func aMapNeedsExactlyOneOverlord() throws {
        let data = try GameData.bundled()
        #expect(throws: DataError.self) {
            try GameState(map: map(units: [P(unit: "skeleton", side: .player, x: 0, y: 0), P(unit: "knight", side: .enemy, x: 5, y: 0)]), data: data)
        }
        #expect(throws: DataError.self) {
            try GameState(map: map(units: [P(unit: "overlord", side: .player, x: 0, y: 0), P(unit: "overlord", side: .player, x: 1, y: 0),
                                           P(unit: "knight", side: .enemy, x: 5, y: 0)]), data: data)
        }
    }

    @Test func aMapNeedsAnEnemy() throws {
        let data = try GameData.bundled()
        #expect(throws: DataError.self) {
            try GameState(map: map(units: [P(unit: "overlord", side: .player, x: 0, y: 0)]), data: data)
        }
    }

    @Test func anOverlordLeavesNoBodyToPlaceOrRaise() throws {
        let data = try GameData.bundled()
        #expect(throws: DataError.self) {
            try GameState(map: map(units: [P(unit: "overlord", side: .player, x: 0, y: 0), P(unit: "knight", side: .enemy, x: 5, y: 0)],
                                   corpses: [C(unit: "overlord", x: 1, y: 0)]), data: data)
        }
    }

    @Test func startingUndeadMustFitTheCommandCap() throws {
        let data = try GameData.bundled()
        #expect(throws: DataError.self) {
            try GameState(map: map(units: [P(unit: "overlord", side: .player, x: 0, y: 0), P(unit: "skeleton", side: .player, x: 1, y: 0),
                                           P(unit: "ghoul", side: .player, x: 2, y: 0), P(unit: "knight", side: .enemy, x: 5, y: 0)], cap: 1), data: data)
        }
    }
}

@Suite struct SaveSafetyTests {
    func slice() throws -> (GameData, GameState) {
        let data = try GameData.bundled()
        return (data, try GameState(map: GameData.bundledMap("slice01"), data: data, seed: 3))
    }

    func edited(_ state: GameState, _ change: (inout [String: Any]) -> Void) throws -> Data {
        var json = try #require(JSONSerialization.jsonObject(with: state.saved()) as? [String: Any])
        change(&json)
        return try JSONSerialization.data(withJSONObject: json)
    }

    @Test func aSaveCarriesItsFormatVersion() throws {
        let (_, state) = try slice()
        let json = try #require(JSONSerialization.jsonObject(with: state.saved()) as? [String: Any])
        #expect(json["formatVersion"] as? Int == GameState.saveFormatVersion)
    }

    @Test func aSaveFromAnotherVersionIsRefused() throws {
        let (data, state) = try slice()
        let bytes = try edited(state) { $0["formatVersion"] = 99 }
        #expect(throws: SaveError.unsupportedVersion(99)) { try GameState.load(bytes, data: data) }
    }

    @Test func garbageIsRefused() throws {
        let (data, _) = try slice()
        #expect(throws: SaveError.corrupt("not a saved battle")) { try GameState.load(Data("hello".utf8), data: data) }
    }

    @Test func aSaveNamingAnUnknownUnitIsRefusedNotCrashed() throws {
        let (data, state) = try slice()
        let bytes = try edited(state) { json in
            var s = json["state"] as! [String: Any]
            var units = s["units"] as! [[String: Any]]
            units[1]["definitionID"] = "dragon"
            s["units"] = units
            json["state"] = s
        }
        #expect(throws: SaveError.self) { try GameState.load(bytes, data: data) }
    }

    @Test func aSaveWithTooLittleTerrainIsRefusedNotCrashed() throws {
        let (data, state) = try slice()
        let bytes = try edited(state) { json in
            var s = json["state"] as! [String: Any]
            s["terrain"] = Array((s["terrain"] as! [Any]).prefix(10))
            json["state"] = s
        }
        #expect(throws: SaveError.self) { try GameState.load(bytes, data: data) }
    }

    @Test func aSaveWithTwoUnitsOnOneTileIsRefused() throws {
        let (data, state) = try slice()
        let bytes = try edited(state) { json in
            var s = json["state"] as! [String: Any]
            var units = s["units"] as! [[String: Any]]
            units[1]["position"] = units[0]["position"]
            s["units"] = units
            json["state"] = s
        }
        #expect(throws: SaveError.self) { try GameState.load(bytes, data: data) }
    }
}

@Suite struct InterfaceQueryTests {
    @Test func forecastSaysWhenTheReplyWouldDestroyTheBody() throws {
        let f = try Fixture(units: [P(unit: "shade", side: .player, x: 1, y: 1), P(unit: "cleric", side: .enemy, x: 2, y: 1),
                                    P(unit: "militia", side: .enemy, x: 2, y: 3)])
        let holy = f.engine.forecast(attacker: f.unit("shade"), defender: f.unit("cleric", .enemy), in: f.state)
        #expect(holy.counter != nil)
        #expect(!holy.counterLeavesCorpse)
        let g = try Fixture(units: [P(unit: "shade", side: .player, x: 1, y: 1), P(unit: "militia", side: .enemy, x: 2, y: 1)])
        #expect(g.engine.forecast(attacker: g.unit("shade"), defender: g.unit("militia", .enemy), in: g.state).counterLeavesCorpse)
    }

    @Test func aMoveReportsItsRouteRoundObstacles() throws {
        var f = try Fixture(rows: ["....", ".#..", "...."], units: [P(unit: "skeleton", side: .player, x: 0, y: 1), P(unit: "militia", side: .enemy, x: 3, y: 2)])
        let events = try f.apply(.move(unit: f.id("skeleton"), to: Position(2, 0)))
        #expect(events == [.moved(unit: f.id("skeleton"), path: [Position(0, 1), Position(0, 0), Position(1, 0), Position(2, 0)])])
        #expect(f.engine.route(for: f.unit("skeleton"), to: Position(3, 2), in: f.state) == nil)  // occupied
    }

    @Test func threatenedTilesAreWhereTheEnemyCanStrikeNextPhase() throws {
        let f = try Fixture(width: 10, height: 1, units: [P(unit: "overlord", side: .player, x: 0, y: 0), P(unit: "archer", side: .enemy, x: 9, y: 0)])
        let danger = f.engine.threatenedTiles(by: .enemy, in: f.state)
        // The archer moves up to 4 and shoots exactly 2: it can hit columns 3 to 9 except where it cannot stand 2 away.
        #expect(danger.contains(Position(3, 0)))
        #expect(!danger.contains(Position(2, 0)))
        #expect(danger.contains(Position(7, 0)))
    }

    @Test func corpsesAtRiskListsWhatTheEnemyCanDenyNextPhase() throws {
        let f = try Fixture(width: 12, height: 3, units: [P(unit: "overlord", side: .player, x: 0, y: 1), P(unit: "pyromancer", side: .enemy, x: 11, y: 0),
                                                        P(unit: "cleric", side: .enemy, x: 11, y: 2)],
                            corpses: [C(unit: "knight", x: 6, y: 1), C(unit: "militia", x: 1, y: 1)])
        let risk = f.engine.corpsesAtRisk(from: .enemy, in: f.state)
        // Both move 4. The pyromancer burns within 2; a blessing reaches 2 plus the tile beside its centre.
        #expect(risk.burnable == [Position(6, 1)])
        #expect(risk.consecratable == [Position(6, 1)])
    }

    @Test func raisableCorpsesIgnoresTheCapWhichIsAskedSeparately() throws {
        let f = try Fixture(cap: 0, units: [P(unit: "overlord", side: .player, x: 1, y: 1), P(unit: "militia", side: .enemy, x: 7, y: 4)],
                            corpses: [C(unit: "knight", x: 2, y: 1)])
        #expect(f.engine.raisableCorpses(for: f.unit("overlord"), in: f.state).count == 1)
        #expect(f.engine.isAtCommandCap(in: f.state))
    }

    @Test func mendMayTargetTheOverlord() throws {
        // Decision of 2026-11-26: Mend and Heal work on any ally, including the overlord.
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 1, y: 1), P(unit: "hollow_priest", side: .player, x: 2, y: 1),
                                    P(unit: "militia", side: .enemy, x: 7, y: 4)])
        f.state.units[0].hp = 10
        try f.apply(.heal(unit: f.id("hollow_priest"), target: f.id("overlord")))
        #expect(f.unit("overlord").hp == 16)
    }
}

@Suite struct EnemyAIReviewTests {
    @Test func enemiesTogetherKillTheOverlordEvenAtTheirOwnCost() throws {
        // Three badly hurt enemies beside an overlord on 10 HP. Any two hits kill. Each would die to the reply.
        var f = try Fixture(certainHits: false, units: [
            P(unit: "overlord", side: .player, x: 1, y: 1),
            P(unit: "militia", side: .enemy, x: 0, y: 1), P(unit: "militia", side: .enemy, x: 1, y: 0), P(unit: "knight", side: .enemy, x: 2, y: 1),
        ])
        f.state.units[0].hp = 10
        f.state.units[1].hp = 2
        f.state.units[2].hp = 2
        f.state.units[3].hp = 4
        try f.apply(.endPhase)
        let events = try f.ai.runPhase(&f.state)
        let strikes = events.filter {
            if case .attacked(_, 1, _, _, false) = $0 { return true }
            if case .missed(_, 1, false) = $0 { return true }
            return false
        }
        // All three attack the overlord unless it falls first.
        #expect(strikes.count == 3 || f.state.outcome == .defeat)
        #expect(strikes.count >= 2)
    }

    @Test func enemiesFocusTheOverlordWhenTwoHitsWouldKill() throws {
        var f = try Fixture(units: [
            P(unit: "overlord", side: .player, x: 2, y: 2), P(unit: "bone_archer", side: .player, x: 4, y: 0),
            P(unit: "militia", side: .enemy, x: 5, y: 2), P(unit: "militia", side: .enemy, x: 5, y: 3),
        ])
        f.state.units[0].hp = 10
        try f.apply(.endPhase)
        try f.ai.runPhase(&f.state)
        #expect(f.state.outcome == .defeat)
    }

    @Test func aUnitBesideAnEnemyAttacksRatherThanWaitingForever() throws {
        // A militia that gains little and takes a reply still attacks: standing still is worse.
        var f = try Fixture(certainHits: false, units: [P(unit: "overlord", side: .player, x: 0, y: 4), P(unit: "dread_knight", side: .player, x: 2, y: 1),
                                                        P(unit: "militia", side: .enemy, x: 3, y: 1)])
        try f.apply(.endPhase)
        let events = try f.ai.runPhase(&f.state)
        #expect(events.contains { if case .attacked(3, 2, _, _, false) = $0 { true } else if case .missed(3, 2, false) = $0 { true } else { false } })
    }

    @Test func clericHealsRatherThanBlessABodyNoRaiserCanReach() throws {
        var f = try Fixture(width: 16, height: 5, certainHits: false, units: [
            P(unit: "overlord", side: .player, x: 0, y: 2), P(unit: "cleric", side: .enemy, x: 10, y: 2), P(unit: "knight", side: .enemy, x: 11, y: 2),
        ], corpses: [C(unit: "militia", x: 8, y: 0)])
        f.state.units[2].hp = 6
        try f.apply(.endPhase)
        try f.ai.runPhase(&f.state)
        #expect(f.unit("knight", .enemy).hp == 12)
        #expect(f.state.consecrations.isEmpty)
    }

    @Test func clericHeadsForTheBodiesTheOverlordCanReach() throws {
        var f = try Fixture(width: 20, height: 5, units: [
            P(unit: "overlord", side: .player, x: 1, y: 2), P(unit: "cleric", side: .enemy, x: 12, y: 2),
        ], corpses: [C(unit: "knight", x: 3, y: 2), C(unit: "knight", x: 3, y: 2), C(unit: "knight", x: 3, y: 2), C(unit: "warhound", x: 19, y: 3)])
        try f.apply(.endPhase)
        try f.ai.runPhase(&f.state)
        #expect(f.unit("cleric", .enemy).position.x < 12)
    }

    @Test func clericDoesNotCycleItsBlessings() throws {
        // Three separate bodies, two blessings allowed. Once two are blessed, blessing the third would only uncover another.
        var f = try Fixture(width: 14, height: 5, rows: [
            "..............", "..............", "####..........", "....#.........", "....#.........",
        ], units: [P(unit: "overlord", side: .player, x: 0, y: 4), P(unit: "cleric", side: .enemy, x: 8, y: 1)],
           corpses: [C(unit: "knight", x: 6, y: 0), C(unit: "knight", x: 9, y: 0), C(unit: "knight", x: 12, y: 0)])
        var blessings = 0, lapses = 0
        for _ in 0..<9 {
            try f.apply(.endPhase)
            for event in try f.ai.runPhase(&f.state) {
                if case .consecrated = event { blessings += 1 }
                if case .consecrationEnded = event { lapses += 1 }
            }
        }
        #expect(blessings == 2)
        #expect(lapses == 0)
    }

    @Test func unitsWalkRoundAWallToReachTheirTarget() throws {
        // A wall with one gap at the bottom separates the militia from the overlord.
        var f = try Fixture(rows: [
            "....#....", "....#....", "....#....", "....#....", ".........",
        ], units: [P(unit: "overlord", side: .player, x: 0, y: 0), P(unit: "militia", side: .enemy, x: 5, y: 0)])
        var reached = false
        for _ in 0..<6 where f.state.outcome == .ongoing {
            try f.apply(.endPhase)
            try f.ai.runPhase(&f.state)
            if f.state.outcome != .ongoing || f.unit("militia", .enemy).position.x < 4 { reached = true }
        }
        #expect(reached)
    }

    @Test func theEnemyPhaseCanBeSteppedOneUnitAtATime() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 0, y: 0), P(unit: "militia", side: .enemy, x: 7, y: 4),
                                    P(unit: "knight", side: .enemy, x: 7, y: 3)])
        try f.apply(.endPhase)
        let first = try f.ai.step(&f.state)
        #expect(f.state.phase == .enemy)
        #expect(f.state.units(of: .enemy).filter(\.hasActed).count == 1)
        #expect(!first.isEmpty)
        try f.ai.step(&f.state)
        let last = try f.ai.step(&f.state)
        #expect(last == [.phaseBegan(side: .player, turn: 2)])
        #expect(try f.ai.step(&f.state).isEmpty)  // not the enemy's phase any more
    }
}

@Suite struct WholeBattleTests {
    @Test func theSliceCanBeWonAndRaisingIsPartOfIt() throws {
        var victories = 0, defeats = 0, raises = 0, consecrations = 0, burns = 0
        for seed in 1...24 {
            let result = try playSliceWithBot(seed: UInt64(seed))
            if result.state.outcome == .victory { victories += 1 }
            if result.state.outcome == .defeat { defeats += 1 }
            raises += result.raises
            consecrations += result.consecrations
            burns += result.burns
        }
        // The slice has to be winnable, losable, and a fight over the bodies.
        #expect(victories >= 4)
        #expect(defeats >= 1)
        #expect(raises >= 24)
        #expect(consecrations + burns >= 12)
    }

    @Test func manySeedsPlayWithoutARuleErrorAndKeepOneUnitPerTile() throws {
        let data = try GameData.bundled()
        let engine = Engine(data: data)
        let ai = EnemyAI(engine: engine)
        for seed in 100..<140 {
            var state = try GameState(map: GameData.bundledMap("slice01"), data: data, seed: UInt64(seed))
            for _ in 0..<60 where state.outcome == .ongoing {
                try playBotPlayerPhase(engine, ai, &state)
                try ai.runPhase(&state)
                #expect(Set(state.units.map(\.position)).count == state.units.count)
                try state.validate(against: data)
            }
        }
    }
}

@Suite struct DataPinTests {
    /// The stat tables of GDD sections 5.1 to 5.3 and 6, typed in again here so that a slip in
    /// units.json fails a test. Columns: type, HP, Mgt, Grd, Wrd, Mov, min range, max range, Hit, Avoid, Crit.
    static let design: [String: (type: UnitType, numbers: [Int])] = [
        "overlord": (.sovereign, [24, 14, 3, 4, 4, 1, 2, 90, 10, 0]),
        "gravespeaker": (.sovereign, [14, 7, 2, 4, 4, 1, 2, 85, 10, 0]),
        "skeleton": (.bone, [18, 10, 4, 1, 4, 1, 1, 85, 5, 0]),
        "bone_archer": (.bone, [14, 9, 2, 1, 4, 2, 2, 90, 5, 5]),
        "dread_knight": (.bone, [26, 12, 7, 2, 3, 1, 1, 80, 0, 5]),
        "ghoul": (.flesh, [22, 11, 2, 2, 5, 1, 1, 80, 10, 5]),
        "carrion_hound": (.flesh, [14, 9, 1, 1, 6, 1, 1, 85, 20, 0]),
        "oathbreaker": (.flesh, [28, 13, 6, 5, 4, 1, 1, 85, 5, 5]),
        "shade": (.spirit, [12, 9, 5, 3, 5, 1, 1, 90, 25, 5]),
        "ash_wraith": (.spirit, [14, 11, 2, 5, 4, 1, 2, 85, 10, 0]),
        "hollow_priest": (.spirit, [16, 8, 2, 6, 4, 1, 2, 90, 10, 0]),
        "militia": (.steel, [16, 9, 3, 1, 4, 1, 1, 80, 5, 0]),
        "archer": (.steel, [13, 9, 2, 1, 4, 2, 2, 85, 5, 0]),
        "knight": (.steel, [24, 11, 7, 2, 3, 1, 1, 80, 0, 5]),
        "reaver": (.steel, [20, 11, 2, 1, 5, 1, 1, 80, 10, 10]),
        "warhound": (.steel, [12, 8, 1, 1, 6, 1, 1, 85, 20, 0]),
        "scout": (.steel, [12, 8, 2, 2, 5, 1, 1, 85, 25, 5]),
        "pyromancer": (.flame, [13, 11, 1, 4, 4, 1, 2, 85, 10, 0]),
        "cleric": (.holy, [14, 8, 1, 6, 4, 1, 2, 90, 10, 0]),
        "paladin": (.holy, [24, 11, 6, 5, 4, 1, 1, 85, 5, 5]),
    ]

    @Test func unitDataMatchesTheDesignTables() throws {
        let data = try GameData.bundled()
        #expect(Set(data.units.keys) == Set(Self.design.keys))
        for (id, row) in Self.design {
            let d = try #require(data.units[id])
            #expect(d.type == row.type, "\(id) has the wrong type")
            #expect([d.maxHP, d.might, d.guard, d.ward, d.move, d.minRange, d.maxRange, d.hit, d.avoid, d.crit] == row.numbers,
                    "\(id) differs from the design table")
        }
    }

    /// Adam's decision of 2026-11-26: the overlord hits harder than any of his minions.
    @Test func theOverlordHitsHarderThanAnyUndead() throws {
        let data = try GameData.bundled()
        let overlord = try #require(data.units["overlord"])
        for unit in data.units.values where !unit.isLiving && !unit.overlord {
            #expect(overlord.might > unit.might, "\(unit.id) hits as hard as the overlord")
        }
    }

    @Test func raisedFormsMatchTheDesign() throws {
        let data = try GameData.bundled()
        let expected = ["militia": "skeleton", "archer": "bone_archer", "knight": "dread_knight", "reaver": "ghoul",
                        "warhound": "carrion_hound", "scout": "shade", "pyromancer": "ash_wraith",
                        "cleric": "hollow_priest", "paladin": "oathbreaker"]
        for (living, undead) in expected { #expect(data.units[living]?.raisesAs == undead) }
    }

    @Test func ruleConstantsMatchTheDesign() throws {
        let r = try GameData.bundled().rules
        #expect(r.advantage == Fraction(numerator: 3, denominator: 2))
        #expect(r.disadvantage == Fraction(numerator: 3, denominator: 4))
        #expect(r.critical == Fraction(numerator: 2, denominator: 1))
        #expect(r.matchupHitBonus == 15)
        #expect(r.roughAvoidBonus == 10)
        #expect(r.roughMoveCost == 2)
        #expect(r.roughGuardBonus == 1)
        #expect(r.bulwarkGuardBonus == 1)
        #expect(r.feedHeal == 5)
        #expect(r.mendHeal == 6)
        #expect(r.healAmount == 6)
        #expect(r.burnRange == 2)
        #expect(r.purgeRange == 1)
        #expect(r.consecrateRange == 2)
        #expect(r.maxConsecrationsPerCaster == 2)
    }
}

/// Tests written to close gaps found by mutation testing on 2026-11-26: each of these code
/// changes used to pass the whole suite unnoticed.
@Suite struct MutationGapTests {
    @Test func enemiesBlockTheWay() throws {
        let f = try Fixture(rows: ["....."], units: [P(unit: "skeleton", side: .player, x: 0, y: 0), P(unit: "militia", side: .enemy, x: 1, y: 0)])
        let reach = f.engine.reachable(for: f.unit("skeleton"), in: f.state)
        #expect(reach[Position(2, 0)] == nil)
        #expect(reach[Position(3, 0)] == nil)
        #expect(reach.count == 1)
    }

    @Test func anAttackThatCannotPierceStillDealsOne() throws {
        // Warhound might 8 against a Dread Knight on rough ground: guard 7 + 1. Nothing gets through, so damage is the minimum, 1.
        let f = try Fixture(rows: ["...", ".f.", "..."], units: [P(unit: "dread_knight", side: .player, x: 1, y: 1), P(unit: "warhound", side: .enemy, x: 2, y: 1)])
        #expect(f.engine.forecast(attacker: f.unit("warhound", .enemy), defender: f.unit("dread_knight"), in: f.state).strike.damage == 1)
    }

    @Test func damageEqualToHealthIsAKill() throws {
        var f = try Fixture(units: [P(unit: "skeleton", side: .player, x: 1, y: 1), P(unit: "militia", side: .enemy, x: 2, y: 1),
                                    P(unit: "militia", side: .enemy, x: 7, y: 4)])
        f.state.units[1].hp = 5
        let forecast = f.engine.forecast(attacker: f.unit("skeleton"), defender: f.state.units[1], in: f.state)
        #expect(forecast.strike.damage == 5)
        #expect(forecast.strike.kills)
        #expect(!forecast.strike.killsOnCritical)
        try f.apply(.attack(unit: f.id("skeleton"), target: 2))
        #expect(f.state.unit(id: 2) == nil)
    }

    @Test func forecastSaysWhetherAKillWouldLeaveABody() throws {
        let f = try Fixture(units: [P(unit: "overlord", side: .player, x: 1, y: 1), P(unit: "shade", side: .player, x: 1, y: 2),
                                    P(unit: "cleric", side: .enemy, x: 3, y: 2), P(unit: "knight", side: .enemy, x: 2, y: 1)])
        // A Holy attacker leaves no body.
        #expect(!f.engine.forecast(attacker: f.unit("cleric", .enemy), defender: f.unit("shade"), in: f.state).leavesCorpse)
        // The overlord leaves no body whoever kills it.
        #expect(!f.engine.forecast(attacker: f.unit("knight", .enemy), defender: f.unit("overlord"), in: f.state).leavesCorpse)
        // An ordinary kill does.
        #expect(f.engine.forecast(attacker: f.unit("knight", .enemy), defender: f.unit("shade"), in: f.state).leavesCorpse)
    }

    @Test func alliesCannotBeAttacked() throws {
        var f = try Fixture(units: [P(unit: "skeleton", side: .player, x: 1, y: 1), P(unit: "ghoul", side: .player, x: 2, y: 1),
                                    P(unit: "militia", side: .enemy, x: 7, y: 4)])
        #expect(throws: RuleError.invalidTarget) { try f.apply(.attack(unit: f.id("skeleton"), target: f.id("ghoul"))) }
        #expect(f.unit("ghoul").hp == 22)
    }

    @Test func enemiesCannotBeHealed() throws {
        var f = try Fixture(units: [P(unit: "hollow_priest", side: .player, x: 1, y: 1), P(unit: "militia", side: .enemy, x: 3, y: 1)])
        f.state.units[1].hp = 5
        #expect(throws: RuleError.invalidTarget) { try f.apply(.heal(unit: f.id("hollow_priest"), target: f.id("militia", .enemy))) }
        #expect(f.unit("militia", .enemy).hp == 5)
    }

    @Test func healingStopsAtFullHealth() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 1, y: 1), P(unit: "hollow_priest", side: .player, x: 2, y: 1),
                                    P(unit: "militia", side: .enemy, x: 7, y: 4)])
        f.state.units[0].hp = 22
        let events = try f.apply(.heal(unit: f.id("hollow_priest"), target: f.id("overlord")))
        #expect(f.unit("overlord").hp == 24)
        #expect(events == [.healed(unit: f.id("overlord"), amount: 2)])
    }

    @Test func aZeroChanceNeverHits() throws {
        var f = try Fixture(certainHits: false, units: [P(unit: "ghoul", side: .player, x: 1, y: 1), P(unit: "knight", side: .enemy, x: 2, y: 1)])
        for key in f.data.units.keys { f.data.units[key]!.hit = -100 }
        let engine = Engine(data: f.data)
        let ghoul = f.id("ghoul"), knight = f.id("knight", .enemy)
        #expect(engine.forecast(attacker: f.unit("ghoul"), defender: f.unit("knight", .enemy), in: f.state).strike.hitChance == 0)
        for _ in 0..<1500 {
            let events = try engine.apply(.attack(unit: ghoul, target: knight), to: &f.state)
            #expect(events == [.missed(attacker: ghoul, defender: knight, isCounter: false), .missed(attacker: knight, defender: ghoul, isCounter: true)])
            try engine.apply(.endPhase, to: &f.state)
            try engine.apply(.endPhase, to: &f.state)
        }
        #expect(f.unit("knight", .enemy).hp == 24)
        #expect(f.unit("ghoul").hp == 22)
    }

    @Test func anOverlordBodyCanNeverBeRaised() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 1, y: 1), P(unit: "militia", side: .enemy, x: 7, y: 4)])
        // Maps refuse such a body; put one in directly to check the rule itself.
        f.state.corpses.append(Corpse(id: 50, unitID: 60, definitionID: "overlord", side: .player, position: Position(2, 1)))
        #expect(f.engine.raisableCorpses(for: f.unit("overlord"), in: f.state).isEmpty)
        #expect(throws: RuleError.invalidTarget) { try f.apply(.raise(unit: f.id("overlord"), corpse: 50)) }
    }

    @Test func aSaveWithImpossibleHealthIsRefused() throws {
        let data = try GameData.bundled()
        let state = try GameState(map: GameData.bundledMap("slice01"), data: data, seed: 3)
        for bad in [999, 0] {
            var json = try #require(JSONSerialization.jsonObject(with: state.saved()) as? [String: Any])
            var s = json["state"] as! [String: Any]
            var units = s["units"] as! [[String: Any]]
            units[2]["hp"] = bad
            s["units"] = units
            json["state"] = s
            let bytes = try JSONSerialization.data(withJSONObject: json)
            #expect(throws: SaveError.self) { try GameState.load(bytes, data: data) }
        }
    }

    @Test func aPoorTradeIsStillBetterThanWaiting() throws {
        // A warhound beside a Dread Knight deals 1 and takes a likely 8 back. It does not die to the reply, so it attacks.
        var f = try Fixture(width: 16, height: 5, certainHits: false, units: [
            P(unit: "overlord", side: .player, x: 15, y: 0), P(unit: "dread_knight", side: .player, x: 2, y: 1), P(unit: "warhound", side: .enemy, x: 3, y: 1),
        ])
        try f.apply(.endPhase)
        let plan = f.ai.plan(for: f.unit("warhound", .enemy), in: f.state)
        #expect(plan.action == .attack(unit: f.id("warhound", .enemy), target: f.id("dread_knight")))
        #expect(plan.score == 1)
    }

    @Test func fireGoesToTheBodiesARaiserCanReach() throws {
        // Two knight bodies of equal value. Only the one at (5,2) is within the overlord's reach next phase.
        var f = try Fixture(width: 16, height: 5, units: [P(unit: "overlord", side: .player, x: 0, y: 2), P(unit: "pyromancer", side: .enemy, x: 8, y: 2)],
                            corpses: [C(unit: "knight", x: 9, y: 0), C(unit: "knight", x: 5, y: 2)])
        try f.apply(.endPhase)
        let plan = f.ai.plan(for: f.unit("pyromancer", .enemy), in: f.state)
        #expect(plan.action == .burn(unit: f.id("pyromancer", .enemy), tile: Position(5, 2)))
    }

    @Test func fireIsNotWastedOnBodiesAlreadyOnBlessedGround() throws {
        // The knight's body is worth more, but it is already denied by consecration. The militia's is not.
        var f = try Fixture(width: 16, height: 5, units: [P(unit: "overlord", side: .player, x: 0, y: 2), P(unit: "pyromancer", side: .enemy, x: 8, y: 2)],
                            corpses: [C(unit: "knight", x: 5, y: 1), C(unit: "militia", x: 5, y: 3)])
        let pyromancer = f.id("pyromancer", .enemy)
        f.state.consecrations = [Consecration(casterID: pyromancer, sequence: 1, tiles: [Position(5, 1)])]
        f.state.nextSequence = 2
        try f.apply(.endPhase)
        let plan = f.ai.plan(for: f.unit("pyromancer", .enemy), in: f.state)
        #expect(plan.action == .burn(unit: pyromancer, tile: Position(5, 3)))
    }

    @Test func clericDoesNotSpendItsTurnOnAScratch() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 0, y: 0), P(unit: "cleric", side: .enemy, x: 6, y: 2),
                                    P(unit: "knight", side: .enemy, x: 7, y: 2)])
        f.state.units[2].hp = 23
        try f.apply(.endPhase)
        let plan = f.ai.plan(for: f.unit("cleric", .enemy), in: f.state)
        if case .heal = plan.action { Issue.record("the cleric healed a unit that was barely hurt") }
    }

    @Test func aBadlyHurtUnitFallsBackToItsHealer() throws {
        var f = try Fixture(width: 16, height: 3, units: [P(unit: "overlord", side: .player, x: 0, y: 1), P(unit: "militia", side: .enemy, x: 8, y: 1),
                                                        P(unit: "cleric", side: .enemy, x: 14, y: 1)])
        f.state.units[1].hp = 4
        try f.apply(.endPhase)
        let hurt = f.ai.plan(for: f.unit("militia", .enemy), in: f.state)
        #expect((hurt.moveTo?.x ?? 8) > 8)
        // At full health the same unit advances on the overlord instead.
        f.state.units[1].hp = 16
        let healthy = f.ai.plan(for: f.unit("militia", .enemy), in: f.state)
        #expect((healthy.moveTo?.x ?? 8) < 8)
    }
}
