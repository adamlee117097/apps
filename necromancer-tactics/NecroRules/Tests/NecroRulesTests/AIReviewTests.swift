import Foundation
import Testing
@testable import NecroRules

/// Cases found by an independent review of the enemy AI. Each was reproduced as a failing test before it was fixed.
@Suite struct EnemyAISecondReviewTests {
    private func isStrike(_ event: Event, by attacker: Int) -> Bool {
        if case .attacked(attacker, _, _, _, false) = event { return true }
        if case .missed(attacker, _, false) = event { return true }
        return false
    }

    @Test func aWoundedUnitBesideItsTargetDoesNotStandAndWait() throws {
        // Both enemies would probably die to the overlord's reply. They must still attack or get out of its reach.
        var f = try Fixture(certainHits: false, units: [
            P(unit: "overlord", side: .player, x: 7, y: 0), P(unit: "knight", side: .enemy, x: 6, y: 0), P(unit: "pyromancer", side: .enemy, x: 5, y: 0),
        ])
        f.state.units[0].hp = 17
        f.state.units[1].hp = 6
        f.state.units[2].hp = 1
        try f.apply(.endPhase)
        let events = try f.ai.runPhase(&f.state)
        let attacks = events.filter { isStrike($0, by: 2) || isStrike($0, by: 3) }.count
        let reach = f.engine.threatenedTiles(by: .player, in: f.state)
        let stillInReach = f.state.units(of: .enemy).contains { reach.contains($0.position) }
        #expect(attacks > 0 || !stillInReach)
    }

    @Test func aWoundedUnitDoesNotWalkUpToAFoeAndWait() throws {
        var f = try Fixture(certainHits: false, units: [
            P(unit: "overlord", side: .player, x: 0, y: 4), P(unit: "skeleton", side: .player, x: 2, y: 2), P(unit: "militia", side: .enemy, x: 6, y: 2),
        ])
        f.state.units[2].hp = 5
        try f.apply(.endPhase)
        let militia = f.id("militia", .enemy)
        let events = try f.ai.runPhase(&f.state)
        let attacked = events.contains { isStrike($0, by: militia) }
        let beside = f.state.unit(id: militia).map { $0.position.distance(to: Position(2, 2)) == 1 } ?? false
        #expect(attacked || !beside)
    }

    @Test func aUnitBehindItsAlliesWalksRoundToAFreeTile() throws {
        // Three sides of the overlord are held by militia. The knight has to go round to the fourth.
        var f = try Fixture(width: 7, height: 7, units: [
            P(unit: "overlord", side: .player, x: 3, y: 3),
            P(unit: "militia", side: .enemy, x: 3, y: 2), P(unit: "militia", side: .enemy, x: 2, y: 3), P(unit: "militia", side: .enemy, x: 4, y: 3),
            P(unit: "knight", side: .enemy, x: 3, y: 1),
        ])
        f.state.units[0].hp = 10_000
        // The militia must not die and open a tile: this is about walking round, so they are made sturdy.
        for i in 1...3 { f.state.units[i].hp = 10_000 }
        let knight = f.id("knight", .enemy)
        var knightAttacks = 0
        for _ in 0..<3 {
            try f.apply(.endPhase)
            knightAttacks += try f.ai.runPhase(&f.state).filter { isStrike($0, by: knight) }.count
        }
        #expect(knightAttacks > 0)
    }

    @Test func aFireUserBurnsFromWhereItCannotBeStruck() throws {
        // The body can be burned from (10,2), out of the skeleton's reach, as well as from tiles inside it.
        var f = try Fixture(width: 14, height: 5, certainHits: false, units: [
            P(unit: "overlord", side: .player, x: 0, y: 4), P(unit: "skeleton", side: .player, x: 5, y: 1), P(unit: "pyromancer", side: .enemy, x: 12, y: 2),
        ], corpses: [C(unit: "reaver", x: 8, y: 2)])
        try f.apply(.endPhase)
        let events = try f.ai.runPhase(&f.state)
        #expect(events.contains { if case .corpsesDestroyed = $0 { true } else { false } })
        let reach = f.engine.threatenedTiles(by: .player, in: f.state)
        #expect(!reach.contains(f.unit("pyromancer", .enemy).position))
    }

    @Test func theClericAndTheFireUserDenyDifferentPiles() throws {
        // The fire user can reach only the knight's body; the cleric can reach both. Between them nothing should be left to raise.
        var f = try Fixture(width: 9, height: 9, units: [
            P(unit: "overlord", side: .player, x: 0, y: 4), P(unit: "cleric", side: .enemy, x: 6, y: 4), P(unit: "pyromancer", side: .enemy, x: 8, y: 0),
        ], corpses: [C(unit: "knight", x: 4, y: 2), C(unit: "militia", x: 4, y: 6)])
        try f.apply(.endPhase)
        try f.ai.runPhase(&f.state)
        let open = f.state.corpses.filter { !f.state.isConsecrated($0.position) && f.ai.canRaiseSoon(.player, at: $0.position, in: f.state) }
        #expect(open.isEmpty)
    }

    @Test func anAreaWithNoBodyLapsesBeforeAnOlderOneThatHoldsBodies() throws {
        // The cleric's older area covers two knights' bodies. Its newer one covers nothing. A militia's body lies open.
        var f = try Fixture(width: 12, height: 5, units: [P(unit: "overlord", side: .player, x: 0, y: 2), P(unit: "cleric", side: .enemy, x: 6, y: 2)],
                            corpses: [C(unit: "knight", x: 4, y: 0), C(unit: "knight", x: 4, y: 0), C(unit: "militia", x: 3, y: 3)])
        let cleric = f.id("cleric", .enemy)
        f.state.consecrations = [
            Consecration(casterID: cleric, sequence: 1, tiles: [Position(4, 0), Position(3, 0), Position(5, 0), Position(4, 1)]),
            Consecration(casterID: cleric, sequence: 2, tiles: [Position(9, 3), Position(8, 3), Position(10, 3), Position(9, 2), Position(9, 4)]),
        ]
        f.state.nextSequence = 3
        try f.apply(.endPhase)
        try f.ai.runPhase(&f.state)
        #expect(f.state.isConsecrated(Position(4, 0)))
        #expect(f.state.isConsecrated(Position(3, 3)))
        #expect(!f.state.isConsecrated(Position(9, 3)))
    }

    @Test func theOldestAreaStillLapsesWhenEveryAreaHoldsABody() throws {
        var f = try Fixture(width: 14, height: 5, units: [P(unit: "overlord", side: .player, x: 0, y: 4), P(unit: "cleric", side: .enemy, x: 8, y: 2)],
                            corpses: [C(unit: "knight", x: 2, y: 0), C(unit: "knight", x: 12, y: 0), C(unit: "knight", x: 8, y: 4)])
        let cleric = f.id("cleric", .enemy)
        f.state.consecrations = [
            Consecration(casterID: cleric, sequence: 1, tiles: [Position(2, 0)]),
            Consecration(casterID: cleric, sequence: 2, tiles: [Position(12, 0)]),
        ]
        f.state.nextSequence = 3
        try f.apply(.endPhase)
        try f.apply(.consecrate(unit: cleric, tile: Position(8, 4)))
        #expect(!f.state.isConsecrated(Position(2, 0)))
        #expect(f.state.isConsecrated(Position(12, 0)))
        #expect(f.state.isConsecrated(Position(8, 4)))
    }

    @Test func noGroupAttackWhenTheAttackersCannotAllFit() throws {
        // On paper four militia deal 24 to an overlord on 24. Only one tile beside the overlord is free.
        var f = try Fixture(certainHits: true, units: [
            P(unit: "overlord", side: .player, x: 0, y: 0), P(unit: "skeleton", side: .player, x: 1, y: 0),
            P(unit: "militia", side: .enemy, x: 2, y: 2), P(unit: "militia", side: .enemy, x: 3, y: 2),
            P(unit: "militia", side: .enemy, x: 2, y: 3), P(unit: "militia", side: .enemy, x: 3, y: 3),
        ])
        try f.apply(.endPhase)
        #expect(!f.ai.canKillOverlordThisPhase(.enemy, in: f.state))
    }

    @Test func noGroupAttackWhenEveryHitWouldHaveToLand() throws {
        // Four militia at 70% each must all hit: about one chance in four.
        var f = try Fixture(certainHits: false, units: [
            P(unit: "overlord", side: .player, x: 3, y: 2),
            P(unit: "militia", side: .enemy, x: 3, y: 1), P(unit: "militia", side: .enemy, x: 2, y: 2),
            P(unit: "militia", side: .enemy, x: 4, y: 2), P(unit: "militia", side: .enemy, x: 3, y: 3),
        ])
        try f.apply(.endPhase)
        #expect(!f.ai.canKillOverlordThisPhase(.enemy, in: f.state))
        // With the overlord on 12, any two of the four will do, and the attack is on.
        f.state.units[0].hp = 12
        #expect(f.ai.canKillOverlordThisPhase(.enemy, in: f.state))
    }

    @Test func aUnitAlreadyInPositionActsWithoutMoving() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 3, y: 2), P(unit: "militia", side: .enemy, x: 4, y: 2)])
        try f.apply(.endPhase)
        let plan = f.ai.plan(for: f.unit("militia", .enemy), in: f.state)
        #expect(plan.moveTo == nil)
        #expect(plan.action == .attack(unit: f.id("militia", .enemy), target: f.id("overlord")))
    }
}

/// What happened in one battle of the slice, for the checks and the sweep below.
struct BattleReport {
    var outcome: Outcome
    var turns: Int
    var raises = 0, consecrations = 0, burns = 0, heals = 0
    var deathTurn: [String: Int] = [:]
    /// Enemy unit-turns that ended in a wait although an attack was possible from where the unit stood.
    var idleBesideAFoe = 0
    var playerUnitsLeft = 0
}

func playSliceForReport(seed: UInt64, turns: Int = 80) throws -> BattleReport {
    let data = try GameData.bundled()
    let engine = Engine(data: data)
    let ai = EnemyAI(engine: engine)
    var state = try GameState(map: GameData.bundledMap("slice01"), data: data, seed: seed)
    var report = BattleReport(outcome: .ongoing, turns: 0)
    func noteDeaths() {
        for kind in ["pyromancer", "cleric"] where report.deathTurn[kind] == nil {
            if !state.units(of: .enemy).contains(where: { $0.definitionID == kind }) { report.deathTurn[kind] = state.turn }
        }
    }
    for _ in 0..<turns where state.outcome == .ongoing {
        report.raises += try playBotPlayerPhase(engine, ai, &state)
        noteDeaths()
        while state.phase == .enemy && state.outcome == .ongoing {
            let waiting = Set(state.units(of: .enemy).filter { !$0.hasActed }.map(\.id))
            let events = try ai.step(&state)
            for event in events {
                if case .consecrated = event { report.consecrations += 1 }
                if case .corpsesDestroyed = event { report.burns += 1 }
                if case .healed = event { report.heals += 1 }
            }
            noteDeaths()
            // The unit that has just taken its turn, if it is still standing.
            if state.phase == .enemy, let actor = state.units(of: .enemy).first(where: { waiting.contains($0.id) && $0.hasActed }) {
                let acted = events.contains { if case .moved = $0 { false } else { true } }
                if !acted, !engine.attackTargets(for: actor, in: state).isEmpty { report.idleBesideAFoe += 1 }
            }
        }
    }
    report.outcome = state.outcome
    report.playerUnitsLeft = state.units(of: .player).count
    report.turns = state.turn
    return report
}

@Suite struct BattlesEndTests {
    @Test func everyBattleEndsAndTheDenialUnitsGetToAct() throws {
        var unfinished: [Int] = []
        var idle = 0, burnBattles = 0, blessBattles = 0
        let seeds = 200..<260
        for seed in seeds {
            let r = try playSliceForReport(seed: UInt64(seed), turns: 120)
            // The test player's overlord, once alone, walks away from the enemy for ever. That is the
            // test player's doing and is not counted; any other battle that fails to end is.
            if r.outcome == .ongoing && r.playerUnitsLeft > 1 { unfinished.append(seed) }
            idle += r.idleBesideAFoe
            if r.burns > 0 { burnBattles += 1 }
            if r.consecrations > 0 { blessBattles += 1 }
        }
        #expect(unfinished.isEmpty, "battles that never ended, by seed: \(unfinished)")
        #expect(idle == 0, "enemy units waited \(idle) times with a target in range")
        // The pyromancer and the cleric must live long enough to do their job in most battles.
        #expect(burnBattles * 2 >= seeds.count, "the pyromancer burned a body in only \(burnBattles) of \(seeds.count) battles")
        #expect(blessBattles * 2 >= seeds.count, "the cleric consecrated in only \(blessBattles) of \(seeds.count) battles")
    }

    /// A measuring tool, not a check. Run with NECRO_SWEEP=1000 to print figures for that many battles.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["NECRO_SWEEP"] != nil))
    func sweep() throws {
        let count = Int(ProcessInfo.processInfo.environment["NECRO_SWEEP"] ?? "") ?? 200
        var wins = 0, losses = 0, unfinished: [Int] = [], raises = 0, bless = 0, burns = 0, heals = 0, idle = 0
        var burnBattles = 0, blessBattles = 0, turns: [Int] = []
        var pyro: [Int] = [], cleric: [Int] = [], unfinishedWithAnArmy: [Int] = []
        for seed in 1...count {
            let r = try playSliceForReport(seed: UInt64(seed))
            switch r.outcome {
            case .victory: wins += 1
            case .defeat: losses += 1
            case .ongoing:
                unfinished.append(seed)
                if r.playerUnitsLeft > 1 { unfinishedWithAnArmy.append(seed) }
            }
            raises += r.raises; bless += r.consecrations; burns += r.burns; heals += r.heals; idle += r.idleBesideAFoe
            if r.burns > 0 { burnBattles += 1 }
            if r.consecrations > 0 { blessBattles += 1 }
            turns.append(r.turns)
            if let t = r.deathTurn["pyromancer"] { pyro.append(t) }
            if let t = r.deathTurn["cleric"] { cleric.append(t) }
        }
        func median(_ xs: [Int]) -> Int { xs.isEmpty ? 0 : xs.sorted()[xs.count / 2] }
        print("SWEEP battles \(count): wins \(wins) losses \(losses) unfinished \(unfinished.count) \(unfinished.prefix(20))")
        print("SWEEP unfinished with more than the overlord left: \(unfinishedWithAnArmy)")
        print("SWEEP median turns \(median(turns)); raises \(raises) consecrations \(bless) burns \(burns) heals \(heals)")
        print("SWEEP battles with a burn \(burnBattles), with a consecration \(blessBattles); idle beside a foe \(idle)")
        print("SWEEP pyromancer died in \(pyro.count), median turn \(median(pyro)); cleric died in \(cleric.count), median turn \(median(cleric))")
    }
}
