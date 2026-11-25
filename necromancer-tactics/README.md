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

## Running the tests

There is no code yet. Game code starts only after GATE 2 (design review) is
resolved. It will be a Swift package tested with `swift test`. This section will be filled in when the rules module exists.

## Repository note

This project currently lives in the `necromancer-tactics/` subdirectory of a
repository whose root is an unrelated project (Pixlet apps). Everything for the
game is kept inside this directory so it can be moved to its own repository
without changes. See the open question in `docs/STATUS.md`.
