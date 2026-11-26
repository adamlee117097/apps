import Foundation

/// The fixed description of a kind of unit, loaded from `units.json`.
public struct UnitDefinition: Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var type: UnitType
    public var maxHP: Int
    public var might: Int
    public var `guard`: Int
    public var ward: Int
    public var move: Int
    /// Base accuracy, avoidance and critical chance, in percent.
    public var hit: Int
    public var avoid: Int
    public var crit: Int
    public var minRange: Int
    public var maxRange: Int
    public var damage: DamageKind
    public var skills: [Skill]
    /// For the living: the undead unit this becomes when raised.
    public var raisesAs: String?
    public var raiseRange: Int?
    public var isOverlord: Bool?

    public var overlord: Bool { isOverlord ?? false }
    public func has(_ skill: Skill) -> Bool { skills.contains(skill) }
    /// The living can be raised into something else; everything else rises as itself.
    public var isLiving: Bool { type == .steel || type == .flame || type == .holy }
}

public struct Fraction: Codable, Equatable, Sendable {
    public var numerator: Int
    public var denominator: Int
}

/// The weights the enemy AI uses to compare actions, loaded from `rules.json` so they can be tuned without code changes.
public struct AIWeights: Codable, Equatable, Sendable {
    /// Per point of damage an attack would deal.
    public var damage: Int
    public var kill: Int
    public var overlordKill: Int
    /// Added to an attack on the overlord when the units still to act could kill it this phase between them.
    public var overlordAssault: Int
    /// The least chance, in percent, of the overlord falling this phase for the group attack to be called.
    public var overlordAssaultMinChance: Int
    /// A Holy kill leaves nothing to raise.
    public var holyKill: Int
    public var overlordPressure: Int
    public var raiserTarget: Int
    /// Per point of damage the reply would deal.
    public var counterDamage: Int
    public var counterDeath: Int
    /// Per point of corpse value destroyed.
    public var burnValue: Int
    public var burnReach: Int
    public var consecrateValue: Int
    public var consecrateReach: Int
    /// Corpses no raiser can reach next phase are worth this fraction to a cleric.
    public var outOfReachDivisor: Int
    /// Burning a pile that is already on consecrated ground is worth this fraction.
    public var alreadyDeniedDivisor: Int
    /// Per point of health restored to a badly hurt ally.
    public var heal: Int
    /// For units that deny bodies: per point of damage they can expect to take next phase on the tile they end on.
    public var exposureDamage: Int
    /// For the same units: ending where that damage would probably kill them.
    public var exposureDeath: Int
}

/// Tunable rule constants and the type chart, loaded from `rules.json`.
public struct Ruleset: Codable, Equatable, Sendable {
    public var advantage: Fraction
    public var disadvantage: Fraction
    public var typeChart: [String: [String: Matchup]]
    /// Damage multiplier for a critical hit.
    public var critical: Fraction
    /// Added to hit chance with type advantage, subtracted with disadvantage.
    public var matchupHitBonus: Int
    public var roughAvoidBonus: Int
    public var roughMoveCost: Int
    public var roughGuardBonus: Int
    public var bulwarkGuardBonus: Int
    public var feedHeal: Int
    public var mendHeal: Int
    public var mendRange: Int
    public var healAmount: Int
    public var healRange: Int
    public var burnRange: Int
    public var purgeRange: Int
    public var consecrateRange: Int
    public var maxConsecrationsPerCaster: Int
    public var ai: AIWeights

    public func matchup(attacker: UnitType, defender: UnitType) -> Matchup {
        typeChart[attacker.rawValue]?[defender.rawValue] ?? .neutral
    }
}

/// A battle map, loaded from a file in `maps/`.
public struct MapDefinition: Codable, Equatable, Sendable {
    public struct Placement: Codable, Equatable, Sendable {
        public var unit: String
        public var side: Side
        public var x: Int
        public var y: Int
        public init(unit: String, side: Side, x: Int, y: Int) {
            self.unit = unit; self.side = side; self.x = x; self.y = y
        }
    }
    public struct CorpsePlacement: Codable, Equatable, Sendable {
        public var unit: String
        public var x: Int
        public var y: Int
        /// Whose unit this body was. Defaults to the enemy for the living and the player for undead.
        public var side: Side?
        public init(unit: String, x: Int, y: Int, side: Side? = nil) {
            self.unit = unit; self.x = x; self.y = y; self.side = side
        }
    }

    public var id: String
    public var name: String
    public var commandCap: Int
    public var legend: [String: Terrain]
    public var rows: [String]
    public var units: [Placement]
    public var corpses: [CorpsePlacement]

    public init(id: String, name: String, commandCap: Int, legend: [String: Terrain]? = nil,
                rows: [String], units: [Placement], corpses: [CorpsePlacement] = []) {
        self.id = id
        self.name = name
        self.commandCap = commandCap
        self.legend = legend ?? [".": .open, "f": .rough, "#": .wall, "~": .water]
        self.rows = rows
        self.units = units
        self.corpses = corpses
    }
}

public enum DataError: Error, Equatable {
    case missingResource(String)
    case unknownUnit(String)
    case badMap(String)
}

/// Everything the rules need that is not battle state.
public struct GameData: Sendable {
    public var units: [String: UnitDefinition]
    public var rules: Ruleset

    public init(units: [UnitDefinition], rules: Ruleset) {
        self.units = Dictionary(uniqueKeysWithValues: units.map { ($0.id, $0) })
        self.rules = rules
    }

    public init(unitsJSON: Data, rulesJSON: Data) throws {
        struct UnitsFile: Codable { var units: [UnitDefinition] }
        let decoder = JSONDecoder()
        self.init(units: try decoder.decode(UnitsFile.self, from: unitsJSON).units,
                  rules: try decoder.decode(Ruleset.self, from: rulesJSON))
    }

    public func definition(_ id: String) throws -> UnitDefinition {
        guard let d = units[id] else { throw DataError.unknownUnit(id) }
        return d
    }

    /// The data files shipped inside the package.
    public static func bundled() throws -> GameData {
        try GameData(unitsJSON: resource("units"), rulesJSON: resource("rules"))
    }

    public static func bundledMap(_ id: String) throws -> MapDefinition {
        try JSONDecoder().decode(MapDefinition.self, from: resource("maps/\(id)"))
    }

    private static func resource(_ name: String) throws -> Data {
        let parts = name.split(separator: "/").map(String.init)
        let directory = (["Data"] + parts.dropLast()).joined(separator: "/")
        guard let file = parts.last,
              let url = Bundle.module.url(forResource: file, withExtension: "json", subdirectory: directory) else {
            throw DataError.missingResource(name)
        }
        return try Data(contentsOf: url)
    }
}

extension GameState {
    /// Builds the opening state of a battle from a map.
    /// `seed` starts the battle's random sequence. The same seed and the same actions always give the same battle.
    public init(map: MapDefinition, data: GameData, seed: UInt64 = 1) throws {
        try self.init(map: map, data: data, seed: seed, requirePlayable: true)
    }

    /// `requirePlayable: false` skips the checks that a battle can be won and lost. Tests use it for small set-ups.
    init(map: MapDefinition, data: GameData, seed: UInt64, requirePlayable: Bool) throws {
        guard let width = map.rows.first?.count, width > 0,
              map.rows.allSatisfy({ $0.count == width }) else {
            throw DataError.badMap("rows must be non-empty and the same length")
        }
        var cells: [Terrain] = []
        for row in map.rows {
            for ch in row {
                guard let t = map.legend[String(ch)] else {
                    throw DataError.badMap("no legend entry for '\(ch)'")
                }
                cells.append(t)
            }
        }
        self.init(mapID: map.id, width: width, height: map.rows.count, terrain: cells,
                  units: [], corpses: [], consecrations: [], phase: .player, turn: 1,
                  commandCap: map.commandCap, outcome: .ongoing, dismissUsedThisPhase: false,
                  nextUnitID: 1, nextCorpseID: 1, nextSequence: 1, rngState: seed)
        for p in map.units {
            let def = try data.definition(p.unit)
            let pos = Position(p.x, p.y)
            guard contains(pos), terrain(at: pos).isPassable, unit(at: pos) == nil else {
                throw DataError.badMap("cannot place \(p.unit) at \(pos)")
            }
            units.append(BattleUnit(id: nextUnitID, definitionID: def.id, side: p.side, position: pos, hp: def.maxHP))
            nextUnitID += 1
        }
        for c in map.corpses {
            let def = try data.definition(c.unit)
            let pos = Position(c.x, c.y)
            guard contains(pos), terrain(at: pos).isPassable else {
                throw DataError.badMap("cannot place a corpse at \(pos)")
            }
            guard !def.overlord else { throw DataError.badMap("an overlord leaves no corpse") }
            if def.isLiving {
                guard let raised = def.raisesAs, data.units[raised] != nil else {
                    throw DataError.badMap("\(def.id) has no undead form to rise as")
                }
            }
            // A body keeps the unit id it had in life, so a raised unit is the same unit to the interface.
            corpses.append(Corpse(id: nextCorpseID, unitID: nextUnitID, definitionID: def.id,
                                  side: c.side ?? (def.isLiving ? .enemy : .player), position: pos))
            nextCorpseID += 1
            nextUnitID += 1
        }
        guard requirePlayable else { return }
        let overlords = units.filter { $0.side == .player && (data.units[$0.definitionID]?.overlord ?? false) }
        guard overlords.count == 1 else { throw DataError.badMap("a map needs exactly one player overlord") }
        guard units.contains(where: { $0.side == .enemy }) else { throw DataError.badMap("a map needs at least one enemy") }
        guard !units.contains(where: { $0.side == .enemy && (data.units[$0.definitionID]?.overlord ?? false) }) else {
            throw DataError.badMap("the enemy cannot field an overlord")
        }
        let commanded = units.filter { $0.side == .player }.count - 1
        guard commanded <= commandCap else { throw DataError.badMap("starting undead exceed the command cap") }
    }
}
