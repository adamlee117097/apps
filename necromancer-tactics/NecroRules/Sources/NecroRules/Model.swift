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
    public var definitionID: String
    public var position: Position
}

/// Ground blessed by one caster. It lasts until that caster dies.
public struct Consecration: Codable, Equatable, Sendable {
    public var casterID: Int
    public var sequence: Int
    public var tiles: [Position]
}

/// The complete state of a battle. Encoding this value is a save game.
public struct GameState: Codable, Equatable, Sendable {
    public var mapID: String
    public var width: Int
    public var height: Int
    /// Row-major, `width * height` entries.
    public var terrain: [Terrain]
    /// Living units only, in ascending id order.
    public var units: [BattleUnit]
    public var corpses: [Corpse]
    public var consecrations: [Consecration]
    public var phase: Side
    public var turn: Int
    public var commandCap: Int
    public var outcome: Outcome
    public var dismissUsedThisPhase: Bool
    public var nextUnitID: Int
    public var nextCorpseID: Int
    public var nextSequence: Int

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
