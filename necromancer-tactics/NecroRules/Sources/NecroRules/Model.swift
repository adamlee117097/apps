import Foundation

/// A tile coordinate. `x` is the column, `y` is the row, both starting at 0 in the top-left.
public struct Position: Hashable, Codable, Sendable, Comparable, CustomStringConvertible {
    public var x: Int
    public var y: Int

    public init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }

    /// Manhattan distance, the distance used for all ranges.
    public func distance(to other: Position) -> Int {
        abs(x - other.x) + abs(y - other.y)
    }

    /// The four orthogonal neighbours in a fixed order (up, left, right, down).
    public var neighbours: [Position] {
        [Position(x, y - 1), Position(x - 1, y), Position(x + 1, y), Position(x, y + 1)]
    }

    /// Row-major ordering, used wherever the rules need a deterministic tie-break.
    public static func < (a: Position, b: Position) -> Bool {
        (a.y, a.x) < (b.y, b.x)
    }

    public var description: String { "(\(x),\(y))" }
}

public enum Side: String, Codable, Sendable {
    case player, enemy

    public var opponent: Side { self == .player ? .enemy : .player }
}

public enum UnitType: String, Codable, Sendable, CaseIterable {
    case bone, flesh, spirit, steel, flame, holy, sovereign
}

public enum DamageKind: String, Codable, Sendable {
    case physical, magic
}

public enum Skill: String, Codable, Sendable {
    case raise, bulwark, feed, defile, drift, mend
    case burnCorpses, purgeCorpses, consecrate, heal
}

public enum Terrain: String, Codable, Sendable {
    case open, rough, wall, water

    public var isPassable: Bool { self == .open || self == .rough }
}

public enum Matchup: String, Codable, Sendable {
    case advantage = "+"
    case disadvantage = "-"
    case neutral = "="
}

public enum Outcome: String, Codable, Sendable {
    case ongoing, victory, defeat
}

/// A unit standing on the map.
public struct BattleUnit: Codable, Equatable, Sendable, Identifiable {
    public let id: Int
    public var definitionID: String
    public var side: Side
    public var position: Position
    public var hp: Int
    public var hasMoved = false
    public var hasActed = false
    /// Where the unit stood before its move this phase, kept so the move can be undone.
    public var movedFrom: Position?
}

/// A body on a tile. `definitionID` is what the unit was when it died.
public struct Corpse: Codable, Equatable, Sendable, Identifiable {
    public let id: Int
    /// The id the unit had while it stood. A unit raised from this body gets the same id back.
    public var unitID: Int
    public var definitionID: String
    /// The side the unit fought for when it fell.
    public var side: Side
    public var position: Position
}

/// Ground blessed by one caster. It lasts until that caster dies.
public struct Consecration: Codable, Equatable, Sendable {
    public var casterID: Int
    public var sequence: Int
    public var tiles: [Position]
}

/// The complete state of a battle. Encoding this value is a save game.
/// Code outside the package can read everything but can only change a battle through `Engine.apply`.
public struct GameState: Codable, Equatable, Sendable {
    public internal(set) var mapID: String
    public internal(set) var width: Int
    public internal(set) var height: Int
    /// Row-major, `width * height` entries.
    public internal(set) var terrain: [Terrain]
    /// Living units only, in ascending id order.
    public internal(set) var units: [BattleUnit]
    public internal(set) var corpses: [Corpse]
    public internal(set) var consecrations: [Consecration]
    public internal(set) var phase: Side
    public internal(set) var turn: Int
    public internal(set) var commandCap: Int
    public internal(set) var outcome: Outcome
    public internal(set) var dismissUsedThisPhase: Bool
    public internal(set) var nextUnitID: Int
    public internal(set) var nextCorpseID: Int
    public internal(set) var nextSequence: Int
    /// State of the battle's random number generator. Saved with everything else, so a
    /// reloaded battle rolls exactly what the original would have.
    public internal(set) var rngState: UInt64

    /// A number from 0 to 99, advancing the generator (SplitMix64).
    mutating func rollPercent() -> Int {
        rngState &+= 0x9E37_79B9_7F4A_7C15
        var z = rngState
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Int(z % 100)
    }

    public func contains(_ p: Position) -> Bool {
        p.x >= 0 && p.y >= 0 && p.x < width && p.y < height
    }

    public func terrain(at p: Position) -> Terrain {
        contains(p) ? terrain[p.y * width + p.x] : .wall
    }

    public func unit(id: Int) -> BattleUnit? {
        units.first { $0.id == id }
    }

    public func unit(at p: Position) -> BattleUnit? {
        units.first { $0.position == p }
    }

    public func corpses(at p: Position) -> [Corpse] {
        corpses.filter { $0.position == p }
    }

    public func isConsecrated(_ p: Position) -> Bool {
        consecrations.contains { $0.tiles.contains(p) }
    }

    public func units(of side: Side) -> [BattleUnit] {
        units.filter { $0.side == side }
    }
}
