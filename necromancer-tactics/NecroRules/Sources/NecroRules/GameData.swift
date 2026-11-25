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
        public init(unit: String, x: Int, y: Int) {
            self.unit = unit; self.x = x; self.y = y
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
        guard let url = Bundle.module.url(forResource: "Resources/\(name)", withExtension: "json") else {
            throw DataError.missingResource(name)
        }
        return try Data(contentsOf: url)
    }
}

extension GameState {
    /// Builds the opening state of a battle from a map.
    /// `seed` starts the battle's random sequence. The same seed and the same actions always give the same battle.
    public init(map: MapDefinition, data: GameData, seed: UInt64 = 1) throws {
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
            corpses.append(Corpse(id: nextCorpseID, definitionID: def.id, position: pos))
            nextCorpseID += 1
        }
    }
}
