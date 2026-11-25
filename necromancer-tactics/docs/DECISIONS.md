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
- **Status:** Provisional. Made by Claude to avoid blocking; Adam to confirm or
  name a dedicated repository.

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
- **Title:** to be workshopped. "Necromancer Tactics" stays as the working
  title.

## 2026-11-25: GDD section 13 items 5 to 12, provisional

Adam answered the four brief items and did not comment on items 5 to 12.
Claude proceeded with the GDD's proposals as provisional defaults so the rules
module could be built. Each is a data or small code change to reverse:

- No randomness in combat.
- Promotion lines read as the overlord's own ranks (not yet in code).
- A unit killed by Holy damage leaves no corpse.
- Several corpses can share a tile; one burn destroys the pile.
- Dismiss: a free action, once per phase.
- Consecration lasts until the cleric who cast it dies; two areas per cleric.
- The outer display scrolls rather than shrinking the map (not yet in code).
- Slice line-up as in GDD 13.12.

**Status:** awaiting Adam's confirmation or changes.

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

## Gates

| Gate | Status | Date | Outcome |
|---|---|---|---|
| GATE 1: engine, build pipeline, feature feasibility | Approved | 2026-11-25 | Native Swift: SwiftUI + SpriteKit, rules in a pure Swift package |
| GATE 2: GDD review, items in brief 3.5 | Brief items resolved; design defaults provisional | 2026-11-25 | Hybrid campaign, App Store release, AI-generated sprites, title to be workshopped |
| GATE 3: vertical slice played on device | Not reached | | |
