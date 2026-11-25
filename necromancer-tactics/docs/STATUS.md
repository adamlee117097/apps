# Status

Last updated: 2026-11-25

## Current phase

Phase 1: Design document. `docs/GDD.md` draft 1 is written. **Waiting at GATE 2**
for Adam's review. No game code is to be written until GATE 2 is resolved.

## Working environment

- Running on Linux (cloud container), not the Mac mini. The Mac mini checks in
  brief section 2.1 are skipped until Adam says he is on the Mac.
- Repository: `adamlee117097/apps`, branch `claude/new-session-jfevon`,
  directory `necromancer-tactics/`. Draft PR #1.

## Done

- Phase 0 research (`docs/RESEARCH.md`). GATE 1 approved 2026-11-25: native
  Swift, SwiftUI + SpriteKit. See `docs/DECISIONS.md`.
- GDD draft 1.

## Next

1. GATE 2: Adam reviews the GDD and answers its section 13.
2. After GATE 2, on Linux: Swift package for the rules module, JSON data files
   for units and the slice map, unit tests, and a GitHub Actions workflow that
   runs `swift test`. No rendering, UI or Xcode project until on the Mac.
3. First tasks on the Mac: the checks in brief 2.1; sign in to Xcode with a
   free Apple Account; a fold/unfold prototype in the iPhone Duo simulator;
   read the display scale factors (RESEARCH.md 8.4).

## Open questions for Adam (GATE 2)

The twelve items in `docs/GDD.md` section 13. Still unanswered from GATE 1, and
not blocking: Mac mini model and macOS version; whether Adam owns an Apple
Pencil (USB-C) and has iOS 27.2 or later.

## Things a future session should know

- Research was done from a Claude Code cloud environment named
  `necromancer-tactics`, which allows Apple's, Godot's and Unity's sites. Other
  sites (Nintendo, App Store, game press) are blocked there.
- Apple's documentation pages can be read as JSON at
  `https://developer.apple.com/tutorials/data/<path>.json`.
