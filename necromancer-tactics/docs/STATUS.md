# Status

Last updated: 2026-11-25

## Current phase

Phase 0: Research. Complete. **Waiting at GATE 1** for Adam's approval. No game
code is to be written until then.

## Working environment

- Running on Linux (cloud container), not the Mac mini. The Mac mini checks in
  brief section 2.1 are skipped until Adam says he is on the Mac.
- Repository: `adamlee117097/apps`, branch `claude/new-session-jfevon`,
  directory `necromancer-tactics/`.

## Done

- Read the project brief.
- Created README, STATUS, DECISIONS, .gitignore.
- Re-verified the iPhone Duo hardware facts against Apple's spec page.

- `docs/RESEARCH.md` complete, with a recommendation in section 8: native
  Swift, SwiftUI around a SpriteKit map, rules in a pure Swift package.

## Next

1. GATE 1: Adam answers the questions below.
2. After approval: Phase 1 GDD, then GATE 2.
3. After GATE 2: rules module, data files, unit tests and GitHub Actions on
   Linux. No rendering, UI or Xcode project until on the Mac.
4. First task on the Mac: the checks in brief 2.1, then a fold/unfold prototype
   in the iPhone Duo simulator, and read the display scale factors
   (RESEARCH.md 8.4).

## Open questions for Adam (GATE 1)

1. Approve native Swift (SwiftUI + SpriteKit) as the engine?
2. Which Apple Developer account do you have: none, free, or paid?
3. Keep the game in `necromancer-tactics/` in `adamlee117097/apps`, or move to a
   dedicated repository?
4. Mac mini model and macOS version, if known.
5. Do you own an Apple Pencil (USB-C), and is the phone on iOS 27.2 or later?
6. Firm up the reference-game research (needs more sites allowed), or is it
   enough for the GDD?

## Things a future session should know

- Research was done from a Claude Code cloud environment named
  `necromancer-tactics`, which allows Apple's, Godot's and Unity's sites. Other
  sites (Nintendo, App Store, game press) are blocked there.
- Apple's documentation pages can be read as JSON at
  `https://developer.apple.com/tutorials/data/<path>.json`.
