import Foundation

public enum SaveError: Error, Equatable {
    /// The file was written by a newer or older version of the game that this one cannot read.
    case unsupportedVersion(Int)
    /// The file could be read but describes a battle that breaks the rules' assumptions.
    case corrupt(String)
}

/// What is written to disk: the battle plus the version of the format it was written in.
struct SavedBattle: Codable {
    var formatVersion: Int
    var state: GameState
}

extension GameState {
    /// Raise this when the saved shape changes, and teach `load` to read the older shape.
    public static let saveFormatVersion = 1

    /// Encodes the battle as JSON. Keys are sorted so the same state always gives the same bytes.
    public func saved() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(SavedBattle(formatVersion: Self.saveFormatVersion, state: self))
    }

    /// Reads a save and checks it against the game data before trusting it.
    public static func load(_ bytes: Data, data: GameData) throws -> GameState {
        struct Header: Codable { var formatVersion: Int }
        let decoder = JSONDecoder()
        let header: Header
        do {
            header = try decoder.decode(Header.self, from: bytes)
        } catch {
            throw SaveError.corrupt("not a saved battle")
        }
        guard header.formatVersion == saveFormatVersion else {
            throw SaveError.unsupportedVersion(header.formatVersion)
        }
        let state: GameState
        do {
            state = try decoder.decode(SavedBattle.self, from: bytes).state
        } catch {
            throw SaveError.corrupt("the saved battle could not be decoded")
        }
        try state.validate(against: data)
        return state
    }

    /// Checks everything the rules rely on, so a damaged or hand-edited save is refused instead of crashing later.
    func validate(against data: GameData) throws {
        func fail(_ reason: String) -> SaveError { .corrupt(reason) }
        guard width > 0, height > 0, terrain.count == width * height else { throw fail("map size and terrain disagree") }
        guard turn >= 1, commandCap >= 0 else { throw fail("turn or command cap out of range") }

        var ids: Set<Int> = []
        var tiles: Set<Position> = []
        for unit in units {
            guard let def = data.units[unit.definitionID] else { throw fail("unknown unit kind \(unit.definitionID)") }
            guard ids.insert(unit.id).inserted else { throw fail("two units share id \(unit.id)") }
            guard contains(unit.position), terrain(at: unit.position).isPassable else { throw fail("unit \(unit.id) is off the map") }
            guard tiles.insert(unit.position).inserted else { throw fail("two units share a tile") }
            guard unit.hp >= 1, unit.hp <= def.maxHP else { throw fail("unit \(unit.id) has impossible health") }
            if let origin = unit.movedFrom {
                guard contains(origin), terrain(at: origin).isPassable else { throw fail("unit \(unit.id) moved from off the map") }
            }
        }
        guard units.map(\.id) == units.map(\.id).sorted() else { throw fail("units are out of order") }

        var corpseIDs: Set<Int> = []
        for corpse in corpses {
            guard let def = data.units[corpse.definitionID], !def.overlord else { throw fail("unknown corpse kind \(corpse.definitionID)") }
            guard corpseIDs.insert(corpse.id).inserted else { throw fail("two corpses share id \(corpse.id)") }
            guard ids.insert(corpse.unitID).inserted else { throw fail("a corpse shares a unit id") }
            guard contains(corpse.position), terrain(at: corpse.position).isPassable else { throw fail("corpse \(corpse.id) is off the map") }
        }
        for area in consecrations {
            guard !area.tiles.isEmpty, area.tiles.allSatisfy({ contains($0) }) else { throw fail("consecrated ground is off the map") }
            guard units.contains(where: { $0.id == area.casterID }) else { throw fail("consecrated ground has no living caster") }
            guard area.sequence < nextSequence else { throw fail("consecration counter is behind") }
        }
        guard (ids.max() ?? 0) < nextUnitID, (corpseIDs.max() ?? 0) < nextCorpseID else { throw fail("id counters are behind") }

        if outcome == .ongoing {
            let overlords = units.filter { $0.side == .player && (data.units[$0.definitionID]?.overlord ?? false) }
            guard overlords.count == 1 else { throw fail("an unfinished battle needs exactly one overlord") }
            guard units.contains(where: { $0.side == .enemy }) else { throw fail("an unfinished battle needs an enemy") }
        }
    }

    /// A text picture of the map for tests and debugging. Not used for display in the game.
    public func ascii(_ data: GameData) -> String {
        var lines: [String] = []
        for y in 0..<height {
            var line = ""
            for x in 0..<width {
                let p = Position(x, y)
                if let u = unit(at: p) {
                    let letter = data.units[u.definitionID]?.name.first ?? "?"
                    line += u.side == .player ? String(letter).uppercased() : String(letter).lowercased()
                } else if !corpses(at: p).isEmpty {
                    line += isConsecrated(p) ? "X" : "x"
                } else if isConsecrated(p) {
                    line += "+"
                } else {
                    switch terrain(at: p) {
                    case .open: line += "."
                    case .rough: line += "f"
                    case .wall: line += "#"
                    case .water: line += "~"
                    }
                }
            }
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }
}
