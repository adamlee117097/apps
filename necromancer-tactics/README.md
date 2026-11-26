# Necromancer Tactics (working title)

A 2D sprite, grid-based, turn-based tactics game for iPhone Duo. You play a
necromancer who raises an undead army; every battle is a fight over control of
the bodies on the field. Original world, characters and lore.

## Where things are

| Path | Contents |
|---|---|
| `docs/STATUS.md` | Current phase, what is done, what is next, open questions. Read this first. |
| `docs/DECISIONS.md` | Log of gate decisions with dates and reasons. |
| `docs/RESEARCH.md` | Phase 0 research with sources. |
| `docs/GDD.md` | Game design document. |
| `docs/MAC_SETUP.md` | Checklist and sourced plan for the first session on the Mac. |
| `docs/ART_PIPELINE.md` | What Google's and Apple's terms say about generated sprites, cost, and the proposed pipeline. |
| `docs/research-notes/` | Raw notes from research agents. Leads, not reviewed text. |
| `tools/citations/` | Scripts that check the quotations in the docs against the pages they cite. |
| `NecroRules/` | Swift package with the game rules and their tests. |

## Running the tests

The game rules are a Swift package with no Apple-only dependencies, so the tests
run on Linux and macOS alike. The package declares Swift tools version 6.0. It has only been built and tested
with Swift 6.4.3 (Xcode 27 includes Swift 6.4; on Linux, install from
<https://www.swift.org/install/linux/>).

```sh
cd necromancer-tactics/NecroRules
swift test
```

GitHub Actions runs the same command on every push that touches
`necromancer-tactics/` (workflow: `.github/workflows/necromancer-tactics.yml`).

## Layout

| Path | Contents |
|---|---|
| `NecroRules/Sources/NecroRules/` | The rules: model, data loading, engine, enemy AI. No rendering or UI code. |
| `NecroRules/Sources/NecroRules/Data/` | Data files: `units.json`, `rules.json`, `maps/`. Balance changes go here, not in code. |
| `NecroRules/Tests/NecroRulesTests/` | Unit tests. |

The Xcode project for the app will be added beside `NecroRules/` and will
depend on it as a local package, so nothing here needs to move.

## Checking the documents

The research documents quote their sources. To re-check every quotation against
the page it cites (needs network access to the cited sites):

```sh
cd necromancer-tactics
python3 tools/citations/check_doc.py docs/RESEARCH.md docs/MAC_SETUP.md
```

## Repository note

This project currently lives in the `necromancer-tactics/` subdirectory of a
repository whose root is an unrelated project (Pixlet apps). Everything for the
game is kept inside this directory so it can be moved to its own repository
without changes. Adam chose to keep it here at GATE 1 (`docs/DECISIONS.md`).
