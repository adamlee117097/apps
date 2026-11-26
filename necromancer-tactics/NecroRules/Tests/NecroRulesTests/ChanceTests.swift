import Foundation
import Testing
@testable import NecroRules

@Suite struct ChanceTests {
    func duel(_ attacker: String, _ defender: String, rows: [String]? = nil, seed: UInt64 = 1) throws -> Fixture {
        try Fixture(rows: rows, certainHits: false, seed: seed, units: [
            P(unit: attacker, side: .player, x: 1, y: 1), P(unit: defender, side: .enemy, x: 2, y: 1),
            P(unit: "militia", side: .enemy, x: 7, y: 4),
            P(unit: "overlord", side: .player, x: 0, y: 4),
        ])
    }

    @Test func hitChanceIsAccuracyMinusAvoidPlusMatchup() throws {
        // Ghoul: hit 80. Cleric: avoid 10. Flesh has advantage over Holy: +15.
        var f = try duel("ghoul", "cleric")
        #expect(f.engine.forecast(attacker: f.unit("ghoul"), defender: f.unit("cleric", .enemy), in: f.state).strike.hitChance == 85)
        // Skeleton: hit 85. Knight: avoid 0. Bone is at a disadvantage against Steel: -15.
        f = try duel("skeleton", "knight")
        #expect(f.engine.forecast(attacker: f.unit("skeleton"), defender: f.unit("knight", .enemy), in: f.state).strike.hitChance == 70)
        f = try duel("gravespeaker", "militia")
        // Gravespeaker: hit 85. Militia: avoid 5. Neutral.
        #expect(f.engine.forecast(attacker: f.unit("gravespeaker"), defender: f.unit("militia", .enemy), in: f.state).strike.hitChance == 80)
    }

    @Test func roughGroundMakesTheDefenderHarderToHit() throws {
        let f = try duel("gravespeaker", "militia", rows: ["........", "..f.....", "........", "........", "........"])
        #expect(f.engine.forecast(attacker: f.unit("gravespeaker"), defender: f.unit("militia", .enemy), in: f.state).strike.hitChance == 70)
    }

    @Test func chancesStayBetweenZeroAndOneHundred() throws {
        var f = try duel("ghoul", "cleric")
        f.data.units["ghoul"]!.hit = 300
        var engine = Engine(data: f.data)
        #expect(engine.forecast(attacker: f.unit("ghoul"), defender: f.unit("cleric", .enemy), in: f.state).strike.hitChance == 100)
        f.data.units["ghoul"]!.hit = -50
        engine = Engine(data: f.data)
        #expect(engine.forecast(attacker: f.unit("ghoul"), defender: f.unit("cleric", .enemy), in: f.state).strike.hitChance == 0)
    }

    @Test func criticalDoublesDamageAndCanTurnAHitIntoAKill() throws {
        // Reaver: might 11, crit 10. Skeleton: guard 4, 18 HP. Steel against Bone: (11 - 4) x 1.5 = 10, critical 20.
        let f = try Fixture(certainHits: false, units: [P(unit: "skeleton", side: .player, x: 1, y: 1), P(unit: "reaver", side: .enemy, x: 2, y: 1)])
        let odds = f.engine.forecast(attacker: f.unit("reaver", .enemy), defender: f.unit("skeleton"), in: f.state).strike
        #expect(odds.damage == 10)
        #expect(odds.criticalDamage == 20)
        #expect(odds.criticalChance == 10)
        #expect(!odds.kills)
        #expect(odds.killsOnCritical)
    }

    @Test func aMissDoesNoDamageButStillUsesTheAction() throws {
        var f = try duel("ghoul", "cleric")
        f.data.units["ghoul"]!.hit = 0
        let engine = Engine(data: f.data)
        let events = try engine.apply(.attack(unit: f.id("ghoul"), target: f.id("cleric", .enemy)), to: &f.state)
        #expect(events.first == .missed(attacker: f.id("ghoul"), defender: f.id("cleric", .enemy), isCounter: false))
        #expect(f.unit("cleric", .enemy).hp == 14)
        #expect(f.unit("ghoul").hasActed)
        // The cleric is adjacent and has range 1-2, so it still gets its reply.
        #expect(events.contains { if case .attacked(_, _, _, _, true) = $0 { true } else if case .missed(_, _, true) = $0 { true } else { false } })
    }

    @Test func aGuaranteedCriticalDealsCriticalDamage() throws {
        var f = try duel("ghoul", "knight")
        f.data.units["ghoul"]!.hit = 1000
        f.data.units["ghoul"]!.crit = 100
        let engine = Engine(data: f.data)
        let odds = engine.forecast(attacker: f.unit("ghoul"), defender: f.unit("knight", .enemy), in: f.state).strike
        let events = try engine.apply(.attack(unit: f.id("ghoul"), target: f.id("knight", .enemy)), to: &f.state)
        #expect(events.first == .attacked(attacker: f.id("ghoul"), defender: f.id("knight", .enemy),
                                          damage: odds.criticalDamage, isCritical: true, isCounter: false))
        #expect(f.unit("knight", .enemy).hp == 24 - odds.criticalDamage)
    }

    @Test func rollsMatchTheStatedChance() throws {
        // 20,000 rolls against an 85% chance should land close to 85%.
        var f = try duel("ghoul", "cleric")
        var hits = 0
        let trials = 20_000
        for _ in 0..<trials where f.state.rollPercent() < 85 { hits += 1 }
        let rate = Double(hits) / Double(trials)
        #expect(abs(rate - 0.85) < 0.01)
    }

    @Test func rollsCoverTheWholeRangeEvenly() throws {
        var f = try duel("ghoul", "cleric")
        var counts = [Int](repeating: 0, count: 100)
        for _ in 0..<100_000 { counts[f.state.rollPercent()] += 1 }
        #expect(counts.min()! > 850)
        #expect(counts.max()! < 1150)
    }

    @Test func theSameSeedGivesTheSameRolls() throws {
        var a = try duel("ghoul", "knight", seed: 42)
        var b = try duel("ghoul", "knight", seed: 42)
        let ea = try a.apply(.attack(unit: a.id("ghoul"), target: a.id("knight", .enemy)))
        let eb = try b.apply(.attack(unit: b.id("ghoul"), target: b.id("knight", .enemy)))
        #expect(ea == eb)
        #expect(a.state == b.state)
    }

    @Test func differentSeedsGiveDifferentBattles() throws {
        let outcomes = try Set((1...8).map { try playSlice(turns: 6, seed: UInt64($0)).saved() })
        #expect(outcomes.count > 1)
    }

    @Test func reloadingASaveDoesNotChangeTheNextRoll() throws {
        var original = try duel("ghoul", "knight", seed: 7)
        var reloaded = original
        reloaded.state = try GameState.load(original.state.saved(), data: original.data)
        let a = try original.apply(.attack(unit: original.id("ghoul"), target: original.id("knight", .enemy)))
        let b = try reloaded.apply(.attack(unit: reloaded.id("ghoul"), target: reloaded.id("knight", .enemy)))
        #expect(a == b)
    }
}
