# Project Brief: Necromancer Tactics (working title)

You are starting a new game project with me (Adam). Read this whole brief before doing anything. Work in phases. Do not write game code until Phase 0 (Research) is finished and I have approved the technical decisions it produces.

---

## Current status: start on Linux, move to the Mac later

I'm not at my Mac mini yet. Until I tell you I'm on the Mac:
1. Skip the Mac mini checks in 2.1.
2. Do Phase 0 research and stop at GATE 1 as written.
3. After I approve, write the GDD (Phase 1, GATE 2). Then build the rules module, data files and unit tests in plain code that doesn't depend on any Apple framework. Write them in the language the chosen engine uses (for example, Swift without UIKit/SpriteKit imports if we go native), so the code moves to the Mac unchanged.
4. No rendering or UI code, Xcode project, or device builds until we're on the Mac.

When I say I'm on the Mac, run the checks in 2.1 and continue to Phase 2.

### GitHub is the source of truth
- This session runs against a GitHub repo. Everything must live in the repo: research, design docs, code, tests, assets, decisions. Nothing important should exist only in this chat.
- Commit in small, logical steps with clear messages, and push regularly so no work is lost if the session ends.
- Keep a `docs/DECISIONS.md` log: each gate decision, the date, and the reason. Keep a `docs/STATUS.md` with the current phase, what's done, what's next, and open questions. A future session, including one on my Mac, should be able to read those two files and pick up where you left off.
- Add a `README.md` with the project summary and how to run the tests.
- Add a `.gitignore` suited to the chosen engine and to Xcode (DerivedData, xcuserdata, build output). Never commit secrets, signing certificates, provisioning profiles or Apple ID details.
- Set up GitHub Actions to run the rules-module unit tests on every push, on Linux runners for now.
- Later, on the Mac, I'll clone this repo and run Claude Code locally so it can use Xcode. Structure the repo so the Xcode project can be added later without moving existing code.

---

## 0. Ground rules

- Research before building. Use primary sources: developer.apple.com (documentation, Human Interface Guidelines, WWDC session videos and transcripts), Apple's own sample code, official engine docs (Godot, Unity, etc.), and official GitHub repos. Third-party blogs and forums are acceptable only to find leads. Confirm anything that matters against a primary source.
- Cite every technical claim in research documents with a link. Before citing a link, open it and confirm it's live.
- Never present a guess as fact. If you can't verify something, write "unverified" or "I don't know" and say what it would take to find out.
- Don't call something impossible until you have tried it or found a primary source that says so.
- Hardware is new. The target device came out in October 2026 and runs iOS 27, which may be newer than your training data. Assume that anything you know about iOS APIs could be out of date, and look up the current docs.
- Keep me in the loop at decision gates (marked **GATE**). At each one, stop, summarize the options with a recommendation, and wait for my answer.
- Write plainly. No filler, no marketing tone.

---

## 1. Target hardware: iPhone Duo

Facts from Apple's spec page (https://www.apple.com/iphone-duo/specs/). Re-verify them yourself:

- Apple's first foldable iPhone. Released October 23, 2026. Runs iOS 27.
- **Inner display:** 7.6" foldable OLED, 1878×2670, 430 ppi, roughly 4:3 aspect ratio. The phone is wider than it is tall when open.
- **Outer display:** 5.4" OLED, 1398×2034, 460 ppi.
- **ProMotion:** adaptive refresh up to 120Hz on both displays.
- **Chip:** A20 Pro. 6-core CPU (2 performance + 4 efficiency), 7-core GPU with Neural Accelerators, dual 16-core Neural Engine. Hardware-accelerated ray tracing. RAM is not listed by Apple.
- **Apple Pencil (USB-C)** works on the inner display. Hover is not supported.
- **Posable design:** the phone can stand partly folded, like a tent or a laptop. Apple's spec page lists no hinge or angle sensor. Find out whether iOS 27 exposes fold state or posture to apps, and how.
- **Battery:** dual battery, vapor-cooled chip.

### Hardware features I want the game to take advantage of (research feasibility for each)
1. **Two screens, two modes.** Folded, the outer screen is for quick play on the go: compact map view, fast turns. Open, the inner screen shows the full 4:3 tactical map with unit panels beside it. Moving between the two must not interrupt play: no reload, game state kept, camera position kept.
2. **Apple Pencil** on the inner display: tap units with precision, draw movement paths, sketch a raise or attack order.
3. **Tabletop / half-folded pose:** if iOS exposes posture, use a layout with the map on the top half and controls on the bottom half.
4. **120Hz ProMotion:** smooth sprite animation and scrolling, with a lower frame rate on menus and while waiting for enemy turns, to save battery.
5. **Haptics** (Core Haptics): a distinct feel for raising the dead, holy damage, and corpses being burned.
6. **Game controller support** (Game Controller framework), as an option.
7. **Game Center / Apple's Games app** integration, if it's simple to add.
8. **Neural Accelerators / Core ML:** only if research shows a real use, such as smarter enemy AI. Don't force it.

---

## 2. Phase 0: Research (do this first, thoroughly)

Produce `docs/RESEARCH.md`. Cover each topic below with sources, then end with a recommendation section.

### 2.1 Build pipeline and environment
- What exactly is required to build and install an app on my own iPhone? macOS + Xcode version requirements, Apple Developer Program (paid vs free account), free-provisioning limits such as app expiry, TestFlight, and Xcode Cloud. Verify each against Apple's current docs.
- **I have a Mac mini.** The intended setup is to run Claude Code directly on the Mac mini, so you can run Xcode builds, the iOS Simulator, and installs to my iPhone Duo yourself.
- First check the machine: run `sw_vers`, `system_profiler SPHardwareDataType`, and `xcodebuild -version` (if Xcode is installed). Report the Mac mini model, chip, RAM, macOS version, and Xcode version.
- Using Apple's own docs, confirm which Xcode version is needed to build for iOS 27 and which macOS version that Xcode requires. If my Mac mini can't run it, stop and tell me.
- If you find yourself running on Linux rather than the Mac, tell me immediately. Limit Linux work to design, pure game logic, tests and assets until we move to the Mac.
- Walk me through any one-time steps that need me physically present: signing into Xcode with my Apple ID, enabling Developer Mode on the iPhone, trusting the Mac, and connecting the phone by USB-C or Wi-Fi.

### 2.2 Engine / framework options
Compare at least these, judged against this specific game (2D sprites, grid-based tactics, iPhone Duo first, solo developer working with AI help):
- **SpriteKit** (Apple native 2D). Check its current status and whether Apple is still actively developing it, from Apple's own docs and WWDC.
- **Metal** directly, possibly with a thin custom 2D renderer.
- **SwiftUI + SpriteKit/Metal** hybrid (SwiftUI for menus and HUD).
- **Godot 4.x** (iOS export requirements, Apple-hardware feature access, how well it handles foldables).
- **Unity** (licensing terms, iOS export, 2D tooling).
- Any newer Apple game technology announced at WWDC 2025/2026 that applies.

For each option: how it handles the foldable (display changes, layout, state preservation), Apple Pencil access, ProMotion control, haptics, controller support, how much code can be developed and tested off-Mac, learning curve, and risk.

### 2.3 Foldable-specific development
- Apple's guidance for iPhone Duo / iOS 27: display transitions, size classes, scene handling, safe areas, and the inner-display crease area (if any).
- Whether fold state or posture is exposed, and which API does it.
- Recommended asset resolutions and scaling for both displays.

### 2.4 2D sprite pipeline
- Pixel art vs high-resolution 2D: how each scales across 430 and 460 ppi displays.
- Sprite sheet and texture atlas tooling for the chosen engine.
- Placeholder art strategy, so development isn't blocked on final art.

### 2.5 Reference games (design research, not copying)
Study how these handle grid tactics UI on touchscreens: Fire Emblem (mobile entries and Switch handheld mode), Into the Breach (iOS version), Advance Wars, Final Fantasy Tactics (mobile port), and Legend of Keepers / Iratus for villain-side design. Note what works for touch input. This game is an original IP: use no names, characters, art or text from any of them.

Necromancy-specific references:
- **The Necromancer's Tale** (Psychic Software, July 2025, https://store.steampowered.com/app/1315320/The_Necromancers_Tale/): story-heavy CRPG with turn-based tactical battles that include undead minions. Its Trust system can turn townsfolk against you, up to a trial or a mob. Study how it handles undead in turn-based combat and how the world reacts to the player.
- **Tactics Ogre:** a grid tactics game with skills that stop the undead from rising. It's a precedent for our consecration mechanic. Study how enemy necromancers and anti-undead skills work there.
- **Grim Dawn:** its necromancer is often cited as the best "army" feel because of a high summon limit and minions that stay strong.

---

### 2.6 Design lessons from player feedback (see 3.5)
I found a Reddit thread (r/rpg_gamers, "Games that do necromancy the best for gameplay?"). This is one player's opinion, not data, but the complaints match what's commonly said about necromancer classes. Summary:
- **Works:** Grim Dawn (large summon limit, minions strong enough to fight bosses), Last Epoch (skill tree that strengthens minions, though they weaken late game), and Skyrim's detail of reviving real corpses rather than summoning from nothing.
- **Fails:**
  - Path of Exile: weak minions with bad AI, so you end up playing a dark spellcaster.
  - Divinity: Original Sin 2: one summon, then you play normally.
  - Guild Wars 2: limited slots, so it plays like a summoner with a dark coat of paint.
  - Pathfinder: Wrath of the Righteous: great story, but skeletons scale poorly.
  - Tactics Ogre: undead units are strong without a necromancer, so the necromancer feels like a tool.
- **The poster's overall complaint:** necromancer classes don't scale, and developers hand the player damage spells instead of making the army the main source of power.

### **GATE 1**
Present: recommended engine/framework, build pipeline, which hardware features are feasible, a list of open risks, and questions for me. Wait for approval.

---

## 3. Game design (the concept, as agreed)

### 3.1 Pitch
A 2D sprite, grid-based, turn-based tactics game like Fire Emblem. You play an original necromancer who rises from nothing, raises an undead army, conquers land, builds a dark dominion, and is eventually hunted by heroes who come to destroy you. Original world, characters and lore.

### 3.2 Core battle mechanics
- **Grid-based, turn-based.** Player phase, then enemy phase.
- **Corpse economy (the central mechanic).** Any unit that dies, on either side, leaves a corpse on its tile. The overlord or a necromancer unit can spend an action to raise a corpse as an undead unit that joins your side in that battle. What a unit was in life decides what it becomes: a knight raises as a death knight, a mage as a lich-type unit, and so on.
- **Death is not a setback.** Your fallen undead can be raised again. There is **no** penalty or degradation for being raised again. That idea was considered and rejected; don't reintroduce it.
- **Where the tension comes from instead** (the heroes fight the necromancy itself):
  - **Consecration:** enemy clerics bless tiles. Corpses on consecrated ground can't be raised. Clerics are priority targets.
  - **Corpse burning:** fire users and paladins destroy corpses. A unit is only lost for good if its corpse is destroyed before you raise it.
  - **Holy damage:** destroys a unit outright with no corpse left.
  - **The overlord is the only fail state.** If the overlord falls, the battle is lost (like the Lord in Fire Emblem).
  - **Command cap:** you can only control a limited number of raised units at once, and the cap grows as you level. You choose what to raise and what to leave on the field.
- **Undead counter triangle:** Bone beats Flesh, Flesh beats Spirit, Spirit beats Bone (skeletons, ghouls, wraiths). Hero types (e.g., Holy, Steel) interact with this triangle. Propose the full matchup table in the design doc.
- In every battle, the fight is over control of the bodies.

### 3.3 Overlord paths (player choice, early in the campaign)
| | **Death Knight** | **Lich King** |
|---|---|---|
| Overlord's role | Fights on the front line | Casts from the back line |
| Army | Fewer units, each one elite | Large swarms of weak units |
| Raising | Slow; raised units keep their skills | Fast; raised units are disposable |
| Keep | Fortress with walls and chokepoints | Spire with wards and traps |
| Heroes who come | Champions who challenge you to a duel | Holy orders and exorcists |
| Promotion line | Revenant → Blackguard | Acolyte → Archlich |

Optional: mixing both paths unlocks a hidden hybrid (e.g., a Dracolich). Treat this as a stretch goal.

### 3.4 Campaign arc
1. **Rise:** small skirmishes; the player chooses a path.
2. **Conquest:** take territory; build and upgrade the keep between battles.
3. **Reckoning:** named heroes hunt the overlord. A hero you defeat can be raised as one of your strongest units.

### 3.5 Design principles (from 2.6, non-negotiable)
1. **The army is the main source of power.** Most damage and board control should come from raised units, not from the overlord's spells. Even the Death Knight overlord fights alongside the army, not in place of it.
2. **It has to feel like an army.** The command cap starts modest and grows large. The Lich King path should reach swarm size. If late battles don't put a large undead force on the board, the design has failed.
3. **Minions scale.** Raised units improve as the overlord progresses (upgrades, promotions, keep buildings, what they were in life). They must not fall off late game.
4. **Raise from real corpses.** Units only come from bodies on the map. No summoning from nothing.
5. **The overlord must matter to the undead.** Raised units are stronger near the overlord, or need the overlord to raise and empower them. The necromancer must never feel like an optional tool.
6. **No bad minion AI.** Turn-based play means the player commands each unit directly. Any auto-control option (e.g., "swarm advance" for large hordes) must be good enough to rely on.
7. **The world reacts.** Factions, villages and heroes respond to how feared you are. This ties to the notoriety idea: conquest draws stronger heroes.

### 3.6 Undecided (ask me at GATE 2)
- Linear story campaign vs roguelite runs vs a hybrid.
- Personal project vs eventual App Store release (affects the engine, licensing and art pipeline).
- Art direction (pixel art vs high-res 2D) and whether art will be AI-generated, hand-made, or bought as asset packs.
- Final title.

---

## 4. Phase 1: Design document

Produce `docs/GDD.md`: unit roster with stats, the counter-triangle table, raise rules, command cap numbers, enemy hero archetypes and their anti-necromancy abilities, overlord path progression, keep-building between battles, campaign structure options, and UI layouts for the folded and unfolded screens (ASCII wireframes are fine).

### **GATE 2**
Review the GDD with me. Resolve the items in 3.6.

---

## 5. Phase 2: Vertical slice

Build one complete, playable battle on the iPhone Duo:
- One map, about a 12×16 grid. Size it for the 4:3 inner display and confirm it reads well on the outer display.
- Overlord plus 3–4 starting undead vs a hero party that includes at least one cleric (consecration) and one fire user (burning).
- Working corpse/raise system, command cap, counter triangle, overlord-death fail state.
- Basic enemy AI that understands corpse denial: clerics move to consecrate, fire users target corpses.
- Fold/unfold transition with state kept.
- Placeholder sprites.

### Architecture requirements
- Keep **game rules separate from rendering**: a pure, deterministic rules module (grid, units, combat, raise, turn order) with unit tests that run off-Mac. The renderer and UI sit on top of it.
- Save/load from the start, including mid-battle saves (mobile play gets interrupted).
- Data-driven units and maps (JSON or similar) so balance changes don't need code changes.
- Keep following the GitHub workflow in "Current status": small commits, push often, STATUS.md and DECISIONS.md kept current.

### **GATE 3**
I play the slice on my device. Then we decide what comes next.

---

## 6. Later phases (plan only, don't build yet)
Campaign map, keep building, both overlord paths, promotions, named hero system, raising defeated heroes, story and dialogue, audio, haptics polish, Pencil controls, art pass, performance and battery tuning.

---

## 7. First actions
1. Confirm you've read this brief.
2. Tell me whether you're running on Linux or macOS, and confirm which GitHub repo and branch you're working in. Ask me which Apple Developer account I have, if any.
3. Create README.md, docs/STATUS.md, docs/DECISIONS.md and .gitignore, then commit and push.
4. Start Phase 0 research. Commit docs/RESEARCH.md as it grows, and show me progress as you go rather than one dump at the end.
