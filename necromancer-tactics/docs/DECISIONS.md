# Decisions

Each entry: date, decision, reason. Newest at the bottom.

## 2026-11-25: Project lives in `necromancer-tactics/` for now

- **Decision:** Keep all project files inside the `necromancer-tactics/`
  subdirectory of `adamlee117097/apps`, on branch `claude/new-session-jfevon`.
- **Reason:** The session was started against `adamlee117097/apps`, whose root
  is an existing Pixlet apps repository with its own `README.md`, `.gitignore`
  and CI. Writing the game's files at the root would overwrite those. A
  subdirectory touches nothing that exists and can be moved to a dedicated
  repository later.
- **Status:** Confirmed. Adam kept this location at GATE 1 (see below).

## 2026-11-25: Separate cloud environment for research

- **Decision:** Created a personal Claude Code cloud environment
  `necromancer-tactics` that allows `www.apple.com`, `support.apple.com`,
  `docs.godotengine.org`, `godotengine.org`, `docs.unity3d.com`, `unity.com`.
- **Reason:** The default environment blocked these hosts, and the brief
  requires primary sources. Adam approved it on the approval prompt.

## 2026-11-25: GATE 1 approved

Adam's words: "I'll go with your recommendations and I don't have a developer
account."

- **Engine:** native Swift. SwiftUI for menus, HUD and fold layouts; SpriteKit
  for the map; game rules in a pure Swift package tested on Linux.
  Reason: the iPhone Duo fold APIs are first-party only, iOS 27 support is
  certain, and Linux work carries over unchanged. Full reasoning in
  RESEARCH.md section 8.
- **Build pipeline:** Xcode 27.2 on macOS Tahoe 26.6 or later; iPhone Duo on
  iOS 27.2 or later.
- **Apple account:** Adam has no developer account. Plan: sign in to Xcode with
  a free Apple Account (Personal Team) when on the Mac. Installs expire after 7
  days. The paid program is deferred until TestFlight or release is wanted.
- **Repository:** stays in `necromancer-tactics/` inside `adamlee117097/apps`
  (the provisional choice, which Adam did not change).
- **Reference-game research:** left at its current level. Adam did not ask for
  more; it can be revisited.

## 2026-11-25: GATE 2, items from brief section 3.5

Adam's words: "I would say it's a hybrid structure. I would like to eventually
App Store release it. And let's use the Google image generation to make
sprites. And we'll workshop the final title."

- **Campaign structure:** hybrid. A fixed three-act spine with hand-made key
  battles, and generated raids between them. Built linear first.
- **Release:** eventual App Store release. Consequences: the paid Apple
  Developer Program ($99 per year) will be needed before TestFlight or
  submission; all art and audio must be cleared for commercial use; App Store
  screenshots for both iPhone Duo displays will be needed.
- **Art:** sprites made with Google's image generation. Not yet researched, and
  to be done from primary sources before any art is produced: which Google
  product and model, its terms for commercial use of generated images, any
  watermarking or disclosure requirements, App Store rules on generated
  content, and how to keep a consistent style and get transparent sprite
  sheets out of it. The choice between pixel art and high-resolution 2D is
  still open and should follow the display measurements on the Mac
  (RESEARCH.md 6.1, 6.2).
  Adam, later the same day: "The api and accounts are in memory of grave wrate",
  meaning the setup used for his Gravewright project. Not reachable from the
  cloud session; to be read on his computer.
- **Title:** to be workshopped. "Necromancer Tactics" stays as the working
  title.

## 2026-11-25: GDD section 13 items 5 to 12, decided

Adam's words: "I definitely think there should be a miss or a hit chances,
like Fire Emblem. Yes to holy damage. Yes to corpse piles. Yes to number 5. I
would say yes to everything."

- **Combat has hit chances.** This reverses the draft's no-randomness proposal.
  Implemented as: chance to hit = Hit − Avoid, ±15 for type matchup, −10 for a
  defender on rough ground; one honest roll, the displayed number is the real
  chance.
- **Critical hits are included** (double damage, 0 to 10 percent by unit).
  Adam named misses and hit chances; criticals were part of the same question
  and of the Fire Emblem model he pointed to, so Claude included them. They can
  be removed by setting Crit to 0 in `units.json`. To confirm with Adam.
- **Rolls are seeded and saved.** The random state is part of `GameState`, so
  the rules stay deterministic and testable, and a reloaded save repeats the
  same roll for the same action.
- Promotion lines are the overlord's own ranks.
- A unit killed by Holy damage leaves no corpse.
- Corpse piles: yes. Dismiss: yes. Consecration lasts until its cleric dies:
  yes. Outer display scrolls: yes. Slice line-up: as proposed.

## 2026-11-25: Rules module structure

- The rules live in a Swift package, `NecroRules`, importing only Foundation.
- The unit type is named `BattleUnit`, because Foundation already defines a
  type called `Unit` and the clash breaks any file that imports both.
- Battle state is one `Codable` value (`GameState`); encoding it is the save
  file. Saves work mid-phase, including a half-finished move.
- Units, the type chart, rule constants and maps are JSON resources inside the
  package.
- Tests use Swift Testing, which ships with the toolchain on Linux and macOS.
- The cloud environment also allows `download.swift.org`, to install Swift.

## 2026-11-25: The Mac

Adam's words: "The Mac Mini I have has the 4th generation of Apple Silicon, and
it has 16 gigabytes of RAM." He also showed an Apple order record: a Mac mini
picked up on 1 July 2025 for $599.

- Read as the Mac mini (2024) with an M4 and 16 GB. Inference from the price:
  the base model with a 256 GB drive.
- Apple lists it as compatible with macOS Tahoe 26 and macOS 27, and Xcode 27.2
  runs on either. Sources: `MAC_SETUP.md` section 1.
- Still unknown until checked on the Mac: installed macOS version, drive size,
  free space.

## 2026-11-26: Independent review, and what it changed

Adam switched the session to its most thorough mode. Claude ran an independent
review of the work so far with separate agents: a citation audit of
`RESEARCH.md`, a code review of `NecroRules`, and new research on the Mac. The
account's usage limit stopped the agents part-way, so some of the planned
checks were done by Claude with scripts instead. What ran and what did not is
in `STATUS.md`.

Facts that changed:

- **Game Center needs the paid program.** Apple's capability table gives it to
  program members only. It is deferred; saves stay on the device.
- **Unity does recognise iPhone Duo** as a device (release notes of 3 November
  2026). It still has no hinge or fold-layout support, so the engine decision
  stands.
- **The open phone can be turned to portrait**, and Apple's statements on
  locking orientation conflict. A layout for that pose is not designed yet.
- **The simulator cannot send two-finger gestures or Pencil input** in Xcode
  27.2. The folded view's whole-map overview therefore also gets a button.

Rule decisions Claude made while fixing review findings. Each is small and
reversible, and **each needs Adam's confirmation**:

- **Undo covers only the latest move**, and only until another order is given.
  Before, a moved unit could be put back after other units had acted on the
  strength of its position (and two units could end up on one tile).
- **Mend and Heal may target the overlord.** The design text said "an undead";
  the code allowed any ally. Kept as any ally, since the overlord is the fail
  state and has no other healing.
- **Dismiss is for the player only.**
- **Ability ranges mean "up to"** (burn within 2, consecrate within 2).
- **Consecration cannot target a wall** and skips walls and water.
- **A raised unit keeps the identity it had before it fell.**

Engineering decisions:

- Saves carry a format version and are validated on load.
- The resource folder is `Data`, not `Resources`. A reviewer measured on Linux
  that Foundation treats a folder named `Resources` as a bundle layout marker,
  and found reports (not opened first-hand) that Xcode fails to sign such a
  bundle. Unconfirmed on a Mac; the rename costs nothing.
- Enemy AI weights live in `rules.json`.
- Maps are checked for exactly one overlord, at least one enemy, and starting
  undead within the cap.
- The cloud environment also allows `ai.google.dev`, `policies.google.com` and
  `aistudio.google.com`, for research on Google's image generation that has not
  been done yet.

## 2026-11-26: Second review round

Adam reset the usage limits, and three independent reviewers read
`MAC_SETUP.md` and `ART_PIPELINE.md` against their sources. What changed:

- **Fold prototype layout.** The map goes in an overlay arrangement as the
  secondary view, with the controls as primary. The earlier plan (map as the
  primary of a split arrangement) would have halved the map on the flat
  display.
- **Order of the in-person steps.** Claude Code is installed first; the phone is
  updated before it is paired; connecting Claude Code to Xcode and setting up
  signing are now explicit steps.
- **Art.** Google states that its image models cannot produce transparent
  backgrounds, and documents style references only for its dearest model. The
  trial therefore runs on two models. Apple's rules on disturbing content and
  on store imagery are wider than first reported: the art direction is
  stylised, not realistic, with corpse markers that read as game pieces. The
  expected age rating is 13+ (inference).
- **Pinch in the simulator** is possible with a trackpad, not with a mouse. The
  folded view keeps both the pinch and an Overview button.

## 2026-11-26: Updated brief

Adam sent a new version of the brief. It adds three necromancy reference games,
a summary of player feedback, and seven design principles marked
non-negotiable. The brief is now kept in the repository as `docs/BRIEF.md`.

- The project was not restarted. The additions were applied to the existing
  work: RESEARCH.md 7.4 and 7.5, and GDD.md 2.1 and 14.
- The design was checked against each principle (GDD.md 14). It holds on two,
  passes weakly on one, and falls short on four: command caps too small for an
  army, no scaling for most raised units, no auto-control for large armies, and
  no system by which the world reacts.
- Changes are proposed, not made: larger caps, overlord-level scaling for all
  undead, a Dominion aura around the overlord, group orders, and a Notoriety
  score. **They await Adam's review.** No code was changed.

## Gates

| Gate | Status | Date | Outcome |
|---|---|---|---|
| GATE 1: engine, build pipeline, feature feasibility | Approved | 2026-11-25 | Native Swift: SwiftUI + SpriteKit, rules in a pure Swift package |
| GATE 2: GDD review, items in brief 3.5 | Resolved | 2026-11-25 | Hybrid campaign, App Store release, AI-generated sprites, title to be workshopped, hit chances in combat |
| GATE 3: vertical slice played on device | Not reached | | |
