import Foundation
import Testing
@testable import NecroRules

@Suite struct DataTests {
    @Test func bundledDataLoads() throws {
        let data = try GameData.bundled()
        #expect(data.units.count == 20)
        // Every living unit names an undead form that exists and is not itself living.
        for def in data.units.values where def.isLiving {
            let raised = try #require(def.raisesAs)
            let form = try #require(data.units[raised])
            #expect(!form.isLiving)
        }
    }

    @Test func undeadTriangle() throws {
        let rules = try GameData.bundled().rules
        #expect(rules.matchup(attacker: .bone, defender: .flesh) == .advantage)
        #expect(rules.matchup(attacker: .flesh, defender: .spirit) == .advantage)
        #expect(rules.matchup(attacker: .spirit, defender: .bone) == .advantage)
        #expect(rules.matchup(attacker: .flesh, defender: .bone) == .disadvantage)
        #expect(rules.matchup(attacker: .spirit, defender: .flesh) == .disadvantage)
        #expect(rules.matchup(attacker: .bone, defender: .spirit) == .disadvantage)
    }

    @Test func eachUndeadTypeHasTwoStrengthsAndTwoWeaknesses() throws {
        let rules = try GameData.bundled().rules
        for type in [UnitType.bone, .flesh, .spirit] {
            let others = UnitType.allCases.filter { $0 != type && $0 != .sovereign }
            #expect(others.filter { rules.matchup(attacker: type, defender: $0) == .advantage }.count == 2)
            #expect(others.filter { rules.matchup(attacker: type, defender: $0) == .disadvantage }.count == 2)
        }
    }

    @Test func overlordIsNeutralToEverything() throws {
        let rules = try GameData.bundled().rules
        for type in UnitType.allCases {
            #expect(rules.matchup(attacker: .sovereign, defender: type) == .neutral)
            #expect(rules.matchup(attacker: type, defender: .sovereign) == .neutral)
        }
    }

    @Test func sliceMapMatchesTheDesign() throws {
        let data = try GameData.bundled()
        let state = try GameState(map: GameData.bundledMap("slice01"), data: data)
        #expect(state.width == 16)
        #expect(state.height == 12)
        #expect(state.commandCap == 5)
        let player = state.units(of: .player).map(\.definitionID).sorted()
        let enemy = state.units(of: .enemy).map(\.definitionID).sorted()
        #expect(player == ["bone_archer", "ghoul", "overlord", "skeleton", "skeleton"])
        #expect(enemy == ["archer", "cleric", "knight", "militia", "militia", "militia", "pyromancer"])
        #expect(state.corpses.count == 2)
    }
}

@Suite struct CombatTests {
    /// The worked examples in GDD section 5.3.
    @Test(arguments: [
        ("skeleton", "militia", 5),
        ("ghoul", "cleric", 15),
        ("shade", "knight", 10),
    ])
    func playerDamageMatchesTheDesignDocument(attacker: String, defender: String, expected: Int) throws {
        let f = try Fixture(units: [P(unit: attacker, side: .player, x: 1, y: 1), P(unit: defender, side: .enemy, x: 2, y: 1)])
        let forecast = f.engine.forecast(attacker: f.unit(attacker), defender: f.unit(defender, .enemy), in: f.state)
        #expect(forecast.damage == expected)
    }

    @Test(arguments: [
        ("militia", "skeleton", 7),
        ("knight", "shade", 4),
        ("pyromancer", "ghoul", 13),
        ("cleric", "shade", 7),
        ("paladin", "skeleton", 7),
    ])
    func enemyDamageMatchesTheDesignDocument(attacker: String, defender: String, expected: Int) throws {
        let f = try Fixture(units: [P(unit: defender, side: .player, x: 1, y: 1), P(unit: attacker, side: .enemy, x: 2, y: 1)])
        let forecast = f.engine.forecast(attacker: f.unit(attacker, .enemy), defender: f.unit(defender), in: f.state)
        #expect(forecast.damage == expected)
    }

    @Test func attackAppliesForecastAndCounter() throws {
        var f = try Fixture(units: [P(unit: "skeleton", side: .player, x: 1, y: 1), P(unit: "militia", side: .enemy, x: 2, y: 1)])
        let forecast = f.engine.forecast(attacker: f.unit("skeleton"), defender: f.unit("militia", .enemy), in: f.state)
        #expect(forecast.counterDamage == 7)
        try f.apply(.attack(unit: f.id("skeleton"), target: f.id("militia", .enemy)))
        #expect(f.unit("militia", .enemy).hp == 16 - 5)
        #expect(f.unit("skeleton").hp == 18 - 7)
        #expect(f.unit("skeleton").hasActed)
    }

    @Test func rangedAttackerIsNotCounteredByMelee() throws {
        var f = try Fixture(units: [P(unit: "bone_archer", side: .player, x: 1, y: 1), P(unit: "militia", side: .enemy, x: 3, y: 1)])
        try f.apply(.attack(unit: f.id("bone_archer"), target: f.id("militia", .enemy)))
        #expect(f.unit("bone_archer").hp == 14)
    }

    @Test func archerCannotAttackAdjacent() throws {
        var f = try Fixture(units: [P(unit: "bone_archer", side: .player, x: 1, y: 1), P(unit: "militia", side: .enemy, x: 2, y: 1)])
        #expect(throws: RuleError.outOfRange) {
            try f.apply(.attack(unit: f.id("bone_archer"), target: f.id("militia", .enemy)))
        }
    }

    @Test func damageIsAtLeastOne() throws {
        let f = try Fixture(units: [P(unit: "carrion_hound", side: .player, x: 1, y: 1), P(unit: "knight", side: .enemy, x: 2, y: 1)])
        // Might 9 against Guard 7 is 2; any result below 1 is raised to 1.
        #expect(f.engine.forecast(attacker: f.unit("carrion_hound"), defender: f.unit("knight", .enemy), in: f.state).damage == 2)
        let g = try Fixture(units: [P(unit: "warhound", side: .enemy, x: 2, y: 1), P(unit: "dread_knight", side: .player, x: 1, y: 1)])
        // Might 8 against Guard 7 is 1, times 1.5 for Steel against Bone, rounded down, is 1.
        #expect(g.engine.forecast(attacker: g.unit("warhound", .enemy), defender: g.unit("dread_knight"), in: g.state).damage == 1)
    }

    @Test func roughGroundAndBulwarkAddGuard() throws {
        let f = try Fixture(rows: ["....", ".f..", "...."], units: [
            P(unit: "skeleton", side: .player, x: 1, y: 1),
            P(unit: "dread_knight", side: .player, x: 1, y: 0),
            P(unit: "militia", side: .enemy, x: 2, y: 1),
        ])
        #expect(f.engine.effectiveGuard(of: f.unit("skeleton"), at: Position(1, 1), in: f.state) == 4 + 1 + 1)
    }

    @Test func ghoulFeedsOnAKill() throws {
        var f = try Fixture(units: [P(unit: "ghoul", side: .player, x: 1, y: 1), P(unit: "cleric", side: .enemy, x: 2, y: 1),
                                    P(unit: "militia", side: .enemy, x: 7, y: 4)])
        f.state.units[0].hp = 10
        try f.apply(.attack(unit: f.id("ghoul"), target: f.id("cleric", .enemy)))
        #expect(f.unit("ghoul").hp == 15)
    }
}

@Suite struct CorpseTests {
    @Test func deathLeavesACorpse() throws {
        var f = try Fixture(units: [P(unit: "ghoul", side: .player, x: 1, y: 1), P(unit: "cleric", side: .enemy, x: 2, y: 1),
                                    P(unit: "militia", side: .enemy, x: 7, y: 4)])
        let events = try f.apply(.attack(unit: f.id("ghoul"), target: f.id("cleric", .enemy)))
        #expect(f.state.corpses.map(\.definitionID) == ["cleric"])
        #expect(f.state.corpses[0].position == Position(2, 1))
        #expect(events.contains { if case .died(_, "cleric", _, true) = $0 { true } else { false } })
    }

    @Test func holyKillLeavesNoCorpse() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 0, y: 0), P(unit: "shade", side: .player, x: 1, y: 1),
                                    P(unit: "cleric", side: .enemy, x: 3, y: 1)])
        f.state.units[1].hp = 5
        try f.apply(.endPhase)
        try f.apply(.attack(unit: f.id("cleric", .enemy), target: f.id("shade")))
        #expect(f.state.unit(id: 2) == nil)
        #expect(f.state.corpses.isEmpty)
    }

    @Test func raisingAnEnemyGivesItsUndeadForm() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 1, y: 1), P(unit: "militia", side: .enemy, x: 7, y: 4)],
                            corpses: [C(unit: "knight", x: 3, y: 1)])
        try f.apply(.raise(unit: f.id("overlord"), corpse: f.state.corpses[0].id))
        let raised = f.unit("dread_knight")
        #expect(raised.position == Position(3, 1))
        #expect(raised.hp == 26)
        #expect(raised.hasActed)  // cannot act until the next player phase
        #expect(f.state.corpses.isEmpty)
        #expect(f.unit("overlord").hasActed)
    }

    @Test func fallenUndeadRiseAsThemselvesAtFullStrength() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 1, y: 1), P(unit: "militia", side: .enemy, x: 7, y: 4)],
                            corpses: [C(unit: "ghoul", x: 2, y: 1)])
        // Raise, lose and raise the same body repeatedly: nothing degrades.
        for _ in 0..<3 {
            try f.apply(.raise(unit: f.id("overlord"), corpse: f.state.corpses[0].id))
            let ghoul = f.unit("ghoul")
            #expect(ghoul.hp == 22)
            try f.apply(.endPhase)
            try f.apply(.endPhase)
            try f.apply(.dismiss(unit: ghoul.id))
        }
    }

    @Test func raiseIsBlockedOutOfRange() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 1, y: 1), P(unit: "militia", side: .enemy, x: 7, y: 4)],
                            corpses: [C(unit: "knight", x: 4, y: 1)])
        #expect(throws: RuleError.outOfRange) {
            try f.apply(.raise(unit: f.id("overlord"), corpse: f.state.corpses[0].id))
        }
    }

    @Test func raisedUnitAppearsBesideAnOccupiedCorpseTile() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 1, y: 1), P(unit: "skeleton", side: .player, x: 2, y: 1),
                                    P(unit: "militia", side: .enemy, x: 7, y: 4)],
                            corpses: [C(unit: "militia", x: 2, y: 1)])
        try f.apply(.raise(unit: f.id("overlord"), corpse: f.state.corpses[0].id))
        let raised = f.state.units.last!
        #expect(raised.definitionID == "skeleton")
        #expect(raised.position == Position(2, 0))
    }

    @Test func commandCapStopsRaising() throws {
        var f = try Fixture(cap: 1, units: [P(unit: "overlord", side: .player, x: 1, y: 1), P(unit: "skeleton", side: .player, x: 0, y: 0),
                                            P(unit: "militia", side: .enemy, x: 7, y: 4)],
                            corpses: [C(unit: "knight", x: 2, y: 1)])
        #expect(f.engine.commandCount(in: f.state) == 1)
        #expect(throws: RuleError.commandCapReached) {
            try f.apply(.raise(unit: f.id("overlord"), corpse: f.state.corpses[0].id))
        }
    }

    @Test func dismissFreesTheCapAndLeavesABody() throws {
        var f = try Fixture(cap: 1, units: [P(unit: "overlord", side: .player, x: 1, y: 1), P(unit: "skeleton", side: .player, x: 0, y: 0),
                                            P(unit: "militia", side: .enemy, x: 7, y: 4)],
                            corpses: [C(unit: "knight", x: 2, y: 1)])
        try f.apply(.dismiss(unit: f.id("skeleton")))
        #expect(f.state.corpses.contains { $0.definitionID == "skeleton" && $0.position == Position(0, 0) })
        try f.apply(.raise(unit: f.id("overlord"), corpse: f.state.corpses.first { $0.definitionID == "knight" }!.id))
        #expect(f.engine.commandCount(in: f.state) == 1)
    }

    @Test func dismissIsOncePerPhaseAndNeverTheOverlord() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 1, y: 1), P(unit: "skeleton", side: .player, x: 0, y: 0),
                                    P(unit: "ghoul", side: .player, x: 0, y: 1), P(unit: "militia", side: .enemy, x: 7, y: 4)])
        #expect(throws: RuleError.cannotDismissOverlord) { try f.apply(.dismiss(unit: f.id("overlord"))) }
        try f.apply(.dismiss(unit: f.id("skeleton")))
        #expect(throws: RuleError.dismissAlreadyUsed) { try f.apply(.dismiss(unit: f.id("ghoul"))) }
    }

    @Test func burningDestroysTheWholePile() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 0, y: 0), P(unit: "pyromancer", side: .enemy, x: 4, y: 1)],
                            corpses: [C(unit: "knight", x: 3, y: 2), C(unit: "ghoul", x: 3, y: 2), C(unit: "militia", x: 0, y: 4)])
        try f.apply(.endPhase)
        try f.apply(.burn(unit: f.id("pyromancer", .enemy), tile: Position(3, 2)))
        #expect(f.state.corpses.map(\.definitionID) == ["militia"])
    }

    @Test func paladinMustBeAdjacentToPurge() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 0, y: 0), P(unit: "paladin", side: .enemy, x: 4, y: 1)],
                            corpses: [C(unit: "knight", x: 2, y: 1)])
        try f.apply(.endPhase)
        #expect(throws: RuleError.outOfRange) { try f.apply(.burn(unit: f.id("paladin", .enemy), tile: Position(2, 1))) }
        try f.apply(.move(unit: f.id("paladin", .enemy), to: Position(3, 1)))
        try f.apply(.burn(unit: f.id("paladin", .enemy), tile: Position(2, 1)))
        #expect(f.state.corpses.isEmpty)
    }
}

@Suite struct ConsecrationTests {
    func setUp() throws -> Fixture {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 1, y: 2), P(unit: "ghoul", side: .player, x: 0, y: 4),
                                    P(unit: "cleric", side: .enemy, x: 5, y: 2), P(unit: "militia", side: .enemy, x: 7, y: 4)],
                            corpses: [C(unit: "knight", x: 3, y: 2)])
        try f.apply(.endPhase)
        try f.apply(.consecrate(unit: f.id("cleric", .enemy), tile: Position(3, 2)))
        try f.apply(.endPhase)
        return f
    }

    @Test func consecratedCorpsesCannotBeRaised() throws {
        var f = try setUp()
        #expect(f.state.isConsecrated(Position(3, 2)))
        #expect(f.state.isConsecrated(Position(3, 1)))
        #expect(!f.state.isConsecrated(Position(4, 1)))
        #expect(f.engine.raisableCorpses(for: f.unit("overlord"), in: f.state).isEmpty)
        #expect(throws: RuleError.consecratedGround) {
            try f.apply(.raise(unit: f.id("overlord"), corpse: f.state.corpses[0].id))
        }
    }

    @Test func consecrationEndsWhenTheClericDies() throws {
        var f = try setUp()
        try f.apply(.move(unit: f.id("ghoul"), to: Position(4, 3)))
        try f.apply(.endPhase)
        try f.apply(.endPhase)
        try f.apply(.move(unit: f.id("ghoul"), to: Position(5, 3)))
        try f.apply(.attack(unit: f.id("ghoul"), target: f.id("cleric", .enemy)))
        #expect(f.state.consecrations.isEmpty)
        try f.apply(.raise(unit: f.id("overlord"), corpse: f.state.corpses.first { $0.definitionID == "knight" }!.id))
        #expect(f.state.units.contains { $0.definitionID == "dread_knight" })
    }

    @Test func aClericHoldsAtMostTwoAreas() throws {
        var f = try setUp()
        let cleric = f.id("cleric", .enemy)
        try f.apply(.endPhase)
        try f.apply(.consecrate(unit: cleric, tile: Position(5, 0)))
        try f.apply(.endPhase)
        try f.apply(.endPhase)
        try f.apply(.consecrate(unit: cleric, tile: Position(5, 4)))
        #expect(f.state.consecrations.count == 2)
        #expect(!f.state.isConsecrated(Position(3, 2)))  // the oldest area lapsed
        #expect(f.state.isConsecrated(Position(5, 4)))
    }

    @Test func defileClearsBlessedGround() throws {
        var f = try setUp()
        f.state.units.append(BattleUnit(id: 99, definitionID: "oathbreaker", side: .player, position: Position(3, 3), hp: 28))
        try f.apply(.defile(unit: 99))
        #expect(!f.state.isConsecrated(Position(3, 2)))
        try f.apply(.raise(unit: f.id("overlord"), corpse: f.state.corpses[0].id))
    }
}

@Suite struct TurnTests {
    @Test func movementRespectsCostWallsAndEnemies() throws {
        let f = try Fixture(rows: ["......", ".#f...", "......"], units: [
            P(unit: "skeleton", side: .player, x: 0, y: 1), P(unit: "militia", side: .enemy, x: 0, y: 2),
        ])
        let reach = f.engine.reachable(for: f.unit("skeleton"), in: f.state)
        #expect(reach[Position(1, 1)] == nil)       // wall
        #expect(reach[Position(0, 2)] == nil)       // enemy
        #expect(reach[Position(3, 0)] == 4)         // up and along the top row
        #expect(reach[Position(4, 0)] == nil)       // Move is 4
        #expect(reach[Position(2, 1)] == nil)       // 3 steps to reach it, and rough ground costs 2 to enter
    }

    @Test func shadeIgnoresRoughGround() throws {
        let f = try Fixture(rows: [".fff.."], units: [P(unit: "shade", side: .player, x: 0, y: 0), P(unit: "militia", side: .enemy, x: 5, y: 0)])
        #expect(f.engine.reachable(for: f.unit("shade"), in: f.state)[Position(4, 0)] == 4)
    }

    @Test func unitsPassThroughAlliesButCannotStopOnThem() throws {
        let f = try Fixture(rows: ["....."], units: [P(unit: "skeleton", side: .player, x: 0, y: 0), P(unit: "ghoul", side: .player, x: 1, y: 0),
                                                       P(unit: "militia", side: .enemy, x: 4, y: 0)])
        let reach = f.engine.reachable(for: f.unit("skeleton"), in: f.state)
        #expect(reach[Position(1, 0)] == nil)
        #expect(reach[Position(2, 0)] == 2)
        #expect(reach[Position(4, 0)] == nil)
    }

    @Test func moveCanBeUndoneUntilTheUnitActs() throws {
        var f = try Fixture(units: [P(unit: "skeleton", side: .player, x: 0, y: 0), P(unit: "militia", side: .enemy, x: 7, y: 4)])
        let id = f.id("skeleton")
        try f.apply(.move(unit: id, to: Position(2, 0)))
        #expect(throws: RuleError.alreadyMoved) { try f.apply(.move(unit: id, to: Position(3, 0))) }
        try f.apply(.undoMove(unit: id))
        #expect(f.unit("skeleton").position == Position(0, 0))
        try f.apply(.move(unit: id, to: Position(3, 0)))
        try f.apply(.wait(unit: id))
        #expect(throws: RuleError.alreadyActed) { try f.apply(.undoMove(unit: id)) }
    }

    @Test func onlyTheActiveSideMayAct() throws {
        var f = try Fixture(units: [P(unit: "skeleton", side: .player, x: 0, y: 0), P(unit: "militia", side: .enemy, x: 7, y: 4)])
        #expect(throws: RuleError.notYourPhase) { try f.apply(.wait(unit: f.id("militia", .enemy))) }
        try f.apply(.endPhase)
        #expect(f.state.phase == .enemy)
        #expect(f.state.turn == 1)
        try f.apply(.endPhase)
        #expect(f.state.phase == .player)
        #expect(f.state.turn == 2)
    }

    @Test func aFailedActionChangesNothing() throws {
        var f = try Fixture(units: [P(unit: "skeleton", side: .player, x: 0, y: 0), P(unit: "militia", side: .enemy, x: 7, y: 4)])
        let before = f.state
        #expect(throws: RuleError.unreachable) { try f.apply(.move(unit: f.id("skeleton"), to: Position(7, 0))) }
        #expect(f.state == before)
    }

    @Test func overlordDeathIsDefeat() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 1, y: 1), P(unit: "skeleton", side: .player, x: 0, y: 4),
                                    P(unit: "knight", side: .enemy, x: 2, y: 1)])
        f.state.units[0].hp = 3
        try f.apply(.endPhase)
        let events = try f.apply(.attack(unit: f.id("knight", .enemy), target: f.id("overlord")))
        #expect(f.state.outcome == .defeat)
        #expect(f.state.corpses.isEmpty)  // the overlord leaves no body
        #expect(events.last == .battleEnded(.defeat))
        #expect(throws: RuleError.battleOver) { try f.apply(.endPhase) }
    }

    @Test func losingOtherUnitsIsNotDefeat() throws {
        var f = try Fixture(units: [P(unit: "overlord", side: .player, x: 0, y: 0), P(unit: "skeleton", side: .player, x: 1, y: 1),
                                    P(unit: "knight", side: .enemy, x: 2, y: 1)])
        f.state.units[1].hp = 1
        try f.apply(.endPhase)
        try f.apply(.attack(unit: f.id("knight", .enemy), target: f.id("skeleton")))
        #expect(f.state.outcome == .ongoing)
        #expect(f.state.corpses.map(\.definitionID) == ["skeleton"])
    }

    @Test func routingTheEnemyIsVictory() throws {
        var f = try Fixture(units: [P(unit: "ghoul", side: .player, x: 1, y: 1), P(unit: "cleric", side: .enemy, x: 2, y: 1)])
        try f.apply(.attack(unit: f.id("ghoul"), target: f.id("cleric", .enemy)))
        #expect(f.state.outcome == .victory)
    }
}
