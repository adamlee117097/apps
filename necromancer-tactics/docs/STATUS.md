# Status

Last updated: 2026-11-25

## Current phase

Linux work between GATE 2 and the Mac. The rules module, data files and unit
tests exist and pass. GATE 2 is fully resolved. **The next step needs the Mac** (Phase 2 rendering and
UI).

## Working environment

- Running on Linux (cloud container), not the Mac mini. The Mac mini checks in
  brief section 2.1 are skipped until Adam says he is on the Mac.
- Repository: `adamlee117097/apps`, branch `claude/new-session-jfevon`,
  directory `necromancer-tactics/`. Draft PR #1.
- Swift 6.4.3 on Linux was used to build and test.

## Done

- Phase 0 research (`docs/RESEARCH.md`). GATE 1 approved: native Swift,
  SwiftUI + SpriteKit.
- GDD draft 1 (`docs/GDD.md`). GATE 2: the four brief items are decided
  (hybrid campaign, App Store release, Google image generation for sprites,
  title to be workshopped). See `docs/DECISIONS.md`.
- `NecroRules` Swift package: grid and movement, combat with hit and critical
  chances from a seeded, saved random sequence, the type chart,
  corpses and piles, raise, command cap, dismiss, consecration, corpse burning,
  holy kills, overlord fail state, rout victory, undo of moves, save and load,
  and an enemy AI that consecrates and burns corpses. 60 tests pass locally and in GitHub Actions.
- Data files: 20 units, the rules constants and type chart, and the slice map
  (16 × 12).
- GitHub Actions workflow for `swift test` on Linux.

## Not done yet in the rules module

- Overlord paths, levels and promotions; named heroes; keep; campaign.
- Victory conditions other than routing the enemy.
- AI priority 6 from GDD section 10 (avoiding deaths near the overlord). The AI
  also steers by straight-line distance, so it can get stuck behind long walls.
- Balance. The numbers are first-pass and have only been exercised by a
  scripted test player.

## Next

1. Research Google image generation from primary sources before making art
   (see DECISIONS.md).
2. On the Mac: the checks in brief 2.1; sign in to Xcode with a free Apple
   Account; a fold/unfold prototype in the iPhone Duo simulator; read the
   display scale factors (RESEARCH.md 8.4). Then Phase 2: the app target with
   SwiftUI and SpriteKit on top of `NecroRules`.

## Open questions for Adam

1. Critical hits were added along with hit chances. Keep them, or misses
   only?
2. Answered 2026-11-25: the Google image API and accounts are the ones used
   for Adam's earlier Gravewright project, recorded in that project's Claude
   memory on Adam's own computer. That memory is not readable from a cloud
   session and no computer folder was shared, so the product, model and
   account are still unknown here. A session on that computer can read them.
   The API key must never be committed or pasted into chat.
3. Not blocking: Mac mini model and macOS version; whether you own an Apple
   Pencil (USB-C) and have iOS 27.2 or later.

## Things a future session should know

- Research was done from a Claude Code cloud environment named
  `necromancer-tactics`, which allows Apple's, Godot's and Unity's sites. Other
  sites (Nintendo, App Store, game press) are blocked there.
- Apple's documentation pages can be read as JSON at
  `https://developer.apple.com/tutorials/data/<path>.json`.
