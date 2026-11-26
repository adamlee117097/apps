# Status

Last updated: 2026-11-26

## Current phase

All the work that can be done on Linux is done and reviewed. **The next step
needs the Mac**: Phase 2, the vertical slice's rendering and interface. The plan
for the first session there is `MAC_SETUP.md`.

## Working environment

- So far everything has run on Linux (a cloud container), not on the Mac mini.
  The Mac checks in the brief's section 2.1 have not been run.
- Repository: `adamlee117097/apps`, branch `claude/new-session-jfevon`,
  directory `necromancer-tactics/`. Draft PR #1.
- Swift 6.4.3 on Linux was used to build and test.
- Adam's Mac: Mac mini (2024), M4, 16 GB, probably a 256 GB drive. It can run
  the required macOS and Xcode (`MAC_SETUP.md` section 1).
- Adam has no paid developer account. A free Apple Account will be used.

## Done

- **Phase 0 research** (`RESEARCH.md`). GATE 1 approved: native Swift, SwiftUI
  around a SpriteKit map.
- **Design document** (`GDD.md`, draft 3; section 14 awaits review). GATE 2 decided: hybrid campaign,
  eventual App Store release, sprites from Google's image generation, title to
  be workshopped, hit chances in combat.
- **Rules package** (`NecroRules`): grid and movement with routes, combat with
  hit and critical chances from a seeded and saved random sequence, the type
  chart, corpses and piles, raise, command cap, dismiss, consecration, corpse
  burning, holy kills, overlord defeat, rout victory, undo of the latest move,
  versioned and validated saves, and queries the interface will need (threat
  tiles, corpses at risk, attack and heal targets, forecast).
- **Enemy AI** that consecrates and burns bodies a raiser could reach, attacks
  the overlord together when it can fall, heals, retreats, and paths round
  walls. It can be stepped one unit at a time for animation.
- **Data files**: 20 units, rule constants, type chart, AI weights, and the
  16 × 12 slice map.
- **112 tests**, passing locally. GitHub Actions runs them on every push.
- **Mac plan** (`MAC_SETUP.md`): what to install, what Adam must do in person
  and in what order, how Claude Code drives Xcode, what a free account allows,
  what the simulator cannot show, and the first task (a fold prototype).
- **Look-and-feel mock-ups** (`docs/mockups/`): a style sheet and the battle
  screen in three poses, drawn in code by `tools/mockups/render.js`. They are
  placeholders, not final art.
- **Art research** (`ART_PIPELINE.md`): Google's current image models, cost,
  terms, watermarking, Apple's rules, and a proposed pipeline. Nothing has been
  generated.
- **Citation checker** (`tools/citations`): every quotation in `RESEARCH.md`
  (126), `MAC_SETUP.md` (91) and `ART_PIPELINE.md` (56) is checked against its
  source page by script.

## Review of 2026-11-26: what ran and what did not

Adam asked for the most thorough mode. Independent agents were started for an
audit, a code review and new research. The account's usage limit stopped them
part-way.

| Check | Outcome |
|---|---|
| Citation audit of `RESEARCH.md`, five auditors | Completed. 69 problems found, all addressed |
| Code review: design conformance | Completed. Findings fixed |
| Code review: engine edge cases and saves | Completed. Findings fixed |
| Code review: enemy AI | Agent did not run. The other two reviewers covered much of it; Claude fixed what they found and measured 200 seeded battles |
| Code review: public API | Agent did not run. Claude compiled and ran a client that uses only the public API |
| Code review: mutation testing | Agent did not run. Claude scripted it: of 53 deliberate code changes the tests caught 38 and missed 15. Tests were added; a rerun caught 14 of the 15. The last was a redundant check, now removed |
| Second-agent verification of the code findings | Did not run. Claude reproduced each bug with a test before fixing it |
| Mac research, four researchers | Completed. Quotations machine-checked (110 of 110 found) |
| Second-reader review of `MAC_SETUP.md` | Ran after the limit was reset: two reviewers, 25 problems (step order, omissions, overstatements). All corrected |
| Research on Google image generation for sprites | Claude read Google's and Apple's pages and wrote `ART_PIPELINE.md`. One reviewer then found 15 problems and omissions. All corrected |

## Not done yet in the rules package

- Overlord paths, levels and promotions; named heroes; keep; campaign.
- Victory conditions other than routing the enemy.
- Returning units to a roster after a battle (GDD 3.7).
- The AI does not avoid deaths that would leave a body within the overlord's
  reach (GDD section 10).
- An open, flat, portrait layout is not designed (GDD 12.1).
- Balance. The numbers are first-pass. Against a competent scripted player the
  slice gives 162 wins and 34 losses in 200 battles, which may be too easy;
  only a person playing can say.

## Next

1. On the Mac: the checks in `MAC_SETUP.md` section 2; Adam's in-person steps
   in section 3; then the fold prototype in section 7.
2. Then Phase 2: the app target with SwiftUI and SpriteKit on top of
   `NecroRules`, ending at GATE 3 with Adam playing the slice on his phone.
3. Before any art is made: the one-unit trial in `ART_PIPELINE.md` section 5,
   which needs the API key and Adam's answers to that file's questions.

## Open questions for Adam

0. **New on 2026-11-26:** the updated brief added seven design principles. The
   design falls short on three (army size, minion scaling, auto-control) and is
   thin on two more. The proposed changes and five questions are in `GDD.md`
   section 14. None is in the code yet.

1. Critical hits were added along with hit chances. Keep them, or misses only?
2. Rule decisions made while fixing review findings, listed in `DECISIONS.md`
   under 2026-11-26: undo covers only the latest move; Mend and Heal may target
   the overlord; Dismiss is player-only; ability ranges mean "up to". Confirm
   or change.
3. Which Google image generation product and model did the Gravewright project
   use, and is that account on paid billing? That project's memory is on Adam's
   own computer and is not readable from a cloud session. The API key must
   never be committed or pasted into chat. Two more questions about the art are
   in `ART_PIPELINE.md` section 6.
4. How much free disk space does the Mac have, and which macOS version? (Claude
   Code will check both when it runs there.)
5. Do you own an Apple Pencil (USB-C), and is the phone on iOS 27.2 or later?

## Things a future session should know

- The project brief is in `docs/BRIEF.md`. Adam updated it on 2026-11-26 with
  more reference games (2.5), player feedback (2.6) and design principles
  (3.5).

- Research was done from a Claude Code cloud environment named
  `necromancer-tactics`. It allows Apple's, Godot's and Unity's sites,
  `download.swift.org`, and Google's developer documentation
  (`aistudio.google.com`, where `ai.google.dev` now redirects). Other sites
  (Nintendo, App Store listings, game press, `github.com` pages) are blocked
  there.
- Apple's documentation pages can be read as JSON at
  `https://developer.apple.com/tutorials/data/<path>.json`. `tools/citations/fetch.py`
  does this.
- Google's documentation returns readable Markdown only to a non-browser
  client. `fetch.py` handles that too.
- `docs/research-notes/` holds the raw notes behind `MAC_SETUP.md`, including
  every Apple code sample found for the fold APIs.
