# Game Design Document

Working title: Necromancer Tactics. Draft 1, 2026-11-25. For review at GATE 2.

Status of what is in here:

- **Agreed** items come from the project brief and are not open for change
  without Adam.
- **Proposed** items are Claude's first-pass design. All numbers are starting
  values to be tuned by playtest, and all of them live in data files, not code.
- **Open** items are questions for GATE 2, collected in section 13.

All names of units, places and abilities are original to this project. Names
marked (placeholder) are expected to change.

## 1. Pitch (agreed)

A 2D sprite, grid-based, turn-based tactics game for iPhone Duo. You play a
necromancer who rises from nothing, raises an undead army, conquers land, builds
a dark dominion, and is eventually hunted by heroes. In every battle, the fight
is over control of the bodies.

## 2. Design pillars

1. **Bodies are the resource.** Every death, on either side, changes what both
   sides can do next.
2. **Death is not a setback.** Losing a unit costs tempo, never the unit, unless
   the enemy gets to the corpse first. No penalty for being raised again
   (agreed; not to be reintroduced).
3. **The enemy fights the necromancy, not just the army.** Consecration, burning
   and holy damage are the threats.
4. **Everything is readable.** No hidden rolls. The player can always see what
   an action will do and what the enemy can reach.
5. **Playable in two minutes or twenty.** Folded for a quick turn, open for the
   full view, with nothing lost between them.

## 3. Battle rules

### 3.1 Turn structure (agreed: player phase, then enemy phase)

- A battle is played on a square grid. One unit per tile.
- **Player phase:** each of your units may move and then take one action, in any
  order you choose. Then you end the phase.
- **Enemy phase:** each enemy unit does the same, in a fixed order.
- A unit's turn: **move** up to its Move value (4-direction steps, blocked by
  enemies and impassable terrain), then **one action**: Attack, Raise, a skill,
  or Wait. Acting ends the unit's turn.
- **Undo (proposed):** a move can be undone freely until the unit acts. Attacks,
  raises and skills ask for confirmation and cannot be undone.

### 3.2 Combat (proposed)

Combat has **no randomness**. The forecast shown before an attack is exactly
what happens.

- Each unit has: HP, Might, Guard, Ward, Move, Range, a damage kind (physical or
  magic) and a type (section 4).
- Damage = (attacker's Might − defender's Guard for physical, or Ward for magic)
  × type multiplier, rounded down, minimum 1.
- **Counterattack:** if the defender survives and the attacker is within the
  defender's Range, the defender strikes back once, using the same formula.
- No double attacks, critical hits or misses.

Why no randomness: the rules module must be deterministic (brief), mis-taps on a
touchscreen are punishing enough without bad rolls, and a game about planning
around corpses is clearer when outcomes are certain. This is open for
discussion (13.5).

### 3.3 Corpses (agreed core, proposed details)

- **Any unit that dies leaves a corpse on its tile** (agreed), with one
  exception: a unit killed by a Holy-type attack leaves nothing (agreed; see
  3.6).
- A corpse records exactly what the unit was: its unit kind and, for your own
  undead, its skills and level. Raising it gives back that unit.
- **Corpse piles (proposed):** a tile can hold any number of corpses. Units can
  stand on and move through corpse tiles.
- Corpses last until the battle ends unless destroyed.
- The overlord leaves no corpse. If the overlord falls, the battle is lost
  (agreed).

### 3.4 Raising (agreed core, proposed details)

- **Raise** is an action available to the overlord and to necromancer units.
- Target: one corpse on a tile within the raiser's Raise Range. The tile must
  not be consecrated. If the tile is occupied, the raised unit appears on the
  nearest free tile.
- **What it becomes** (agreed principle): a dead enemy rises as the undead unit
  listed for its kind in section 5. One of your own fallen undead rises as
  itself, unchanged.
- **Raising costs nothing but the action** and counts against the command cap.
- Baseline (before a path is chosen): the raised unit arrives at full HP and
  cannot act until your next phase. Paths change this (section 7).

### 3.5 Command cap (agreed core, proposed numbers)

- The cap limits how many undead you control at once, not counting the overlord.
- At the cap, you cannot raise.
- **Dismiss (proposed):** as a free action, once per phase, you may release one
  of your undead. It collapses into a corpse on its tile. This is how you swap
  a weak unit for a better body lying nearby, and it carries the same risk as
  any corpse: the enemy can burn it.
- Cap by overlord level and path:

| Overlord level | No path | Death Knight | Lich King |
|---|---|---|---|
| 1 | 4 | | |
| 2 | 5 | | |
| 3 (path chosen) | | 4 | 6 |
| 4 | | 4 | 7 |
| 5 | | 5 | 8 |
| 6 | | 5 | 9 |
| 7 | | 6 | 10 |
| 8 | | 6 | 11 |
| 9 | | 7 | 12 |
| 10 | | 7 | 12 |

### 3.6 How the heroes fight the necromancy (agreed)

| Threat | Rule (proposed details) | Player counterplay |
|---|---|---|
| **Consecration** | A cleric's Consecrate action blesses a target tile within range 2 and the four tiles next to it. Corpses there cannot be raised. The blessing lasts **until that cleric dies**. Each cleric keeps at most two blessed areas; a third replaces the oldest | Kill the cleric. Later: units with Defile remove a blessing |
| **Corpse burning** | Pyromancers (range 2) and paladins (adjacent) can spend their action to destroy every corpse on one tile. Those units are gone for good | Guard piles, raise quickly, kill or body-block the burner, avoid stacking deaths on one tile |
| **Holy damage** | A unit killed by a Holy-type attack leaves no corpse | Keep valued units out of Holy reach when low; use type advantage against Holy units |
| **Overlord is the fail state** | Overlord at 0 HP ends the battle in defeat | Positioning. The overlord must still get close enough to raise |
| **Command cap** | Section 3.5 | Choose what to raise and what to leave |

A unit is lost for good only if its corpse is destroyed before you raise it, or
it is killed by Holy damage (agreed).

### 3.7 Winning and after the battle (proposed)

- Victory conditions are per map: rout the enemy, kill the leader, hold a point
  for N turns, or survive.
- After a victory, **every undead of yours that is standing, or lying as an
  intact corpse, returns to your roster** at full HP. Units whose corpses were
  destroyed or who died to Holy damage are removed.
- Enemy units you raised during the battle can be kept, up to your roster limit
  (set by the keep, section 8). The Lich King path changes this (section 7).

### 3.8 Terrain (proposed, minimal for the slice)

| Terrain | Effect |
|---|---|
| Open ground | None |
| Forest / rubble | Costs 2 Move to enter. +1 Guard to the unit on it |
| Wall / deep water | Impassable |
| Graveyard | Battle starts with one corpse of a listed kind on the tile |
| Consecrated ground | State laid over any tile (3.6) |

## 4. Types and the counter table

Agreed: Bone beats Flesh, Flesh beats Spirit, Spirit beats Bone. Proposed: three
living types, each of which threatens one undead type and is threatened by
another.

- Undead types: **Bone** (skeletons), **Flesh** (ghouls), **Spirit** (wraiths).
- Living types: **Steel** (soldiers and knights), **Flame** (fire users),
  **Holy** (clerics and paladins).
- **Sovereign**: the overlord. Neutral against everything, so the unit whose
  death ends the battle is never subject to a surprise multiplier.

Attacker is the row, defender is the column. **+** is ×1.5 damage, **−** is
×0.75, blank is ×1.

| Attacker \ Defender | Bone | Flesh | Spirit | Steel | Flame | Holy |
|---|---|---|---|---|---|---|
| **Bone** | | + | − | − | + | |
| **Flesh** | − | | + | | − | + |
| **Spirit** | + | − | | + | | − |
| **Steel** | + | | − | | | |
| **Flame** | − | + | | | | |
| **Holy** | | − | + | | | |

How to remember it:

- Steel shatters Bone; a blade passes through Spirit.
- Flame burns Flesh; there is little on Bone to burn.
- Holy banishes Spirit; Flesh is too mindless to be turned.
- Each undead type has two targets it is strong against, two it is weak
  against, and one neutral.

On screen the matchup is always shown as an up or down arrow next to the
forecast number, never by colour alone.

## 5. Unit roster (proposed)

Columns: HP, Mgt (Might), Grd (Guard), Wrd (Ward), Mov (Move), Rng (Range; "2"
means exactly 2, "1–2" means either), Dmg (P physical, M magic).

### 5.1 Undead

| Unit | Type | HP | Mgt | Grd | Wrd | Mov | Rng | Dmg | Skill |
|---|---|---|---|---|---|---|---|---|---|
| Skeleton | Bone | 18 | 10 | 4 | 1 | 4 | 1 | P | None |
| Bone Archer | Bone | 14 | 9 | 2 | 1 | 4 | 2 | P | None |
| Dread Knight | Bone | 26 | 12 | 7 | 2 | 3 | 1 | P | Bulwark: adjacent allies get +1 Guard |
| Ghoul | Flesh | 22 | 11 | 2 | 2 | 5 | 1 | P | Feed: heals 5 HP when it kills |
| Carrion Hound | Flesh | 14 | 9 | 1 | 1 | 6 | 1 | P | None |
| Oathbreaker | Flesh | 28 | 13 | 6 | 5 | 4 | 1 | P | Defile: action, removes consecration from its tile and adjacent tiles |
| Shade | Spirit | 12 | 9 | 5 | 3 | 5 | 1 | M | Drift: ignores terrain movement costs |
| Ash Wraith | Spirit | 14 | 11 | 2 | 5 | 4 | 1–2 | M | None |
| Hollow Priest | Spirit | 16 | 8 | 2 | 6 | 4 | 1–2 | M | Mend: action, restores 6 HP to an undead within 2 |
| Gravespeaker | Sovereign | 14 | 7 | 2 | 4 | 4 | 1–2 | M | Raise (range 1). A necromancer unit. Lich King path only (section 7) |

### 5.2 The living, and what they become

| Unit | Type | HP | Mgt | Grd | Wrd | Mov | Rng | Dmg | Ability | Raises as |
|---|---|---|---|---|---|---|---|---|---|---|
| Militia | Steel | 16 | 9 | 3 | 1 | 4 | 1 | P | None | Skeleton |
| Archer | Steel | 13 | 9 | 2 | 1 | 4 | 2 | P | None | Bone Archer |
| Knight | Steel | 24 | 11 | 7 | 2 | 3 | 1 | P | None | Dread Knight |
| Reaver | Steel | 20 | 11 | 2 | 1 | 5 | 1 | P | None | Ghoul |
| Warhound | Steel | 12 | 8 | 1 | 1 | 6 | 1 | P | None | Carrion Hound |
| Scout | Steel | 12 | 8 | 2 | 2 | 5 | 1 | P | None | Shade |
| Pyromancer | Flame | 13 | 11 | 1 | 4 | 4 | 1–2 | M | Burn Corpses (range 2) | Ash Wraith |
| Cleric | Holy | 14 | 8 | 1 | 6 | 4 | 1–2 | M | Consecrate (range 2); Heal 6 (range 2) | Hollow Priest |
| Paladin | Holy | 24 | 11 | 6 | 5 | 4 | 1 | P | Purge Corpses (adjacent) | Oathbreaker |

Notes:

- The brief's example "a knight raises as a death knight" is kept in spirit.
  The unit is called Dread Knight so it does not share a name with the Death
  Knight overlord path.
- Raising the enemy's anti-necromancy units gives you the answers to them: a
  raised Cleric can mend your undead, and a raised Paladin can Defile
  consecrated ground. Killing them without Holy or fire getting to the body
  first is the reward.

### 5.3 Checking the numbers

| Attack | Calculation | Result |
|---|---|---|
| Skeleton → Militia | (10 − 3) × 0.75 | 5 of 16 HP. Four hits |
| Militia → Skeleton | (9 − 4) × 1.5 | 7 of 18 HP. Three hits |
| Ghoul → Cleric | (11 − 1) × 1.5 | 15 of 14 HP. One hit |
| Shade → Knight | (9 − 2) × 1.5 | 10 of 24 HP. Three hits |
| Knight → Shade | (11 − 5) × 0.75 | 4 of 12 HP. Three hits |
| Pyromancer → Ghoul | (11 − 2) × 1.5 | 13 of 22 HP. Two hits |
| Cleric → Shade | (8 − 3) × 1.5 | 7 of 12 HP. Two hits, and no corpse |
| Paladin → Skeleton | (11 − 4) × 1 | 7 of 18 HP. Three hits, and no corpse |

Most even fights last two to four exchanges, and the right matchup removes a
priority target in one or two.

## 6. The overlord

- The player names the overlord. A default name is an open item (13.4).
- Before choosing a path (Rise): Sovereign type, HP 24, Mgt 10, Grd 3, Wrd 4,
  Mov 4, Rng 1–2, magic damage, Raise Range 2.
- The overlord gains levels from battles won and objectives met, level 1 to 10.
  Level raises the command cap (3.5) and the overlord's stats.
- The path is chosen at level 3, at the end of the Rise act.

## 7. Overlord paths (agreed table, proposed mechanics)

| | Death Knight | Lich King |
|---|---|---|
| Overlord's role (agreed) | Front line | Back line |
| Overlord stats at level 3 | HP 34, Mgt 13, Grd 7, Wrd 3, Mov 4, Rng 1, physical | HP 22, Mgt 12, Grd 2, Wrd 6, Mov 4, Rng 1–3, magic |
| Army (agreed) | Few, elite | Many, weak |
| Command cap | 4 rising to 7 | 6 rising to 12 |
| Raise Range | 1 (must stand next to the body) | 3 |
| Raising (agreed: slow / fast) | Raised unit arrives at full HP and cannot act until the next phase | Raised unit arrives at half HP and can act at once |
| Raised enemies (agreed: keep skills / disposable) | Keep their skills, gain levels, and can be kept in the roster after the battle | Have no skills and crumble when the battle ends. Only your core roster carries over |
| Extra | Units next to the overlord get +1 Might | From level 6, the overlord may Raise twice in one action. Gains Gravespeakers, who can also raise |
| Keep (agreed) | Fortress: walls and chokepoints | Spire: wards and traps |
| Heroes who come (agreed) | Champions who duel | Holy orders and exorcists |
| Promotion line (agreed) | Revenant → Blackguard | Acolyte → Archlich |

Promotion line, as interpreted here: these are the overlord's own ranks. The
first name is the rank at level 3 and the second is a promotion at level 7 that
adds a signature ability:

- **Blackguard:** Death's Challenge. Once per battle, mark an enemy; that enemy
  and the overlord deal +50% damage to each other until one falls.
- **Archlich:** Phylactery. Once per battle, when the overlord would fall, the
  overlord instead returns at 1 HP on the starting tile.

Whether the promotion lines were meant for the overlord or for units is an open
item (13.6).

Stretch goal (agreed as stretch): a hidden hybrid path. Not designed yet.

## 8. The keep (proposed, later phase)

Between battles the player spends **Dread**, earned from victories and held
territory, on the keep.

| Room | Effect | Path |
|---|---|---|
| Ossuary | Roster limit: how many undead you can keep between battles | Both |
| Charnel Pit | Start each battle with extra corpses near your deployment zone | Both |
| War Table | Deploy one more unit at battle start | Both |
| Walls and Gatehouse | In keep-defence battles: wall tiles and a single gate chokepoint | Death Knight |
| Black Forge | +1 Guard for Bone units, then further tiers | Death Knight |
| Wards | In keep-defence battles: tiles that cannot be consecrated | Lich King |
| Trap Halls | In keep-defence battles: tiles that damage the first enemy to enter | Lich King |
| Sanctum | +1 Raise Range for Gravespeakers, then further tiers | Lich King |

Keep upgrades change the map of keep-defence battles in the Reckoning act, so
what the player builds is what the player later defends.

## 9. Enemy heroes (proposed)

Ordinary enemy parties are built from section 5.2. **Named heroes** are unique
units with more HP and one signature ability aimed at the necromancy. A
defeated named hero whose corpse survives can be raised as one of the
strongest units in the game (agreed).

| Archetype | Type | Signature ability | Comes for | Raised form |
|---|---|---|---|---|
| Champion | Steel | Duel: the overlord and the Champion can only attack each other while adjacent | Death Knight | Elite Bone unit that keeps Duel |
| Banner Captain | Steel | Rally: living allies within 2 get +2 Guard | Death Knight | Elite Bone unit with an undead Rally |
| Exorcist | Holy | Banish: range 3 Holy attack. Kills leave no corpse | Lich King | Elite Spirit unit with a range 3 attack |
| High Cleric | Holy | Sanctify: consecrates every tile within 2 of themself, moving with them | Lich King | Elite Spirit unit with a moving Defile aura |
| Inquisitor | Flame | Pyre: burns all corpses within 2 of a target tile | Both | Elite Spirit unit with an area attack |
| Witch Hunter | Steel | Silence: a hit on a raiser stops it raising next phase | Both | Elite Flesh unit that silences enemy abilities |

## 10. Enemy AI (proposed, for the slice)

The AI is deterministic and scores each possible action. Priorities, highest
first:

1. Kill the overlord if it can be done this phase.
2. **Clerics** move toward the largest group of unconsecrated corpses within
   reach of the overlord or a raiser, and consecrate it. They heal when an ally
   is badly hurt and no corpse target is worth more.
3. **Pyromancers and paladins** burn or purge the most valuable corpse pile they
   can reach. Value is the summed strength of the units in the pile, raised for
   piles the player could raise next phase.
4. Everyone else attacks the target with the best damage-for-damage trade,
   preferring type advantage, kills, and raisers.
5. Holy units prefer finishing blows, since their kills leave no corpse.
6. Units avoid ending their move on a tile where they would die and leave a
   corpse within the overlord's Raise Range, when a safer tile gives the same
   attack.

The player can see what the AI is going for: a toggle shows enemy threat range,
and corpse piles an enemy can burn or consecrate next phase are marked.

## 11. Campaign (agreed arc, structure open)

1. **Rise:** three to four small skirmishes that teach raising, the cap,
   consecration and burning, one at a time. Ends with the path choice.
2. **Conquest:** take territory on a region map. Build the keep between battles.
3. **Reckoning:** named heroes hunt the overlord, including assaults on the
   keep.

Structure options for GATE 2:

| Option | What it is | For | Against |
|---|---|---|---|
| Linear story | Fixed sequence of hand-made maps | Best pacing and tutorials; simplest to build | Low replay value; needs the most hand-made content |
| Roguelite | Each run generates a region, enemies and heroes; overlord death ends the run | High replay value; suits "overlord is the only fail state" | Needs map generation and much more balance work; weaker story |
| Hybrid | Fixed three-act spine with hand-made key battles; between them, generated raids for Dread and bodies | Story plus replay; generated battles reuse the same rules | More systems than linear |

Recommendation: **hybrid**, built as linear first. The vertical slice and the
Rise act are hand-made either way, so the decision does not affect work before
GATE 3.

## 12. Screens and controls

### 12.1 Facts and assumptions

- The inner display is landscape when open (2670 × 1878 pixels). The outer
  display is portrait when closed (1398 × 2034 pixels). Source: RESEARCH.md
  section 1.
- The slice map is **16 columns by 12 rows**, landscape, matching the inner
  display.
- Point sizes are not yet known (RESEARCH.md 6.1). The layouts below assume
  3 pixels per point: about 890 × 626 pt inner and 466 × 678 pt outer. They must
  be re-checked on the Mac.
- Apple's minimum for a frequently used touch target is 44 × 44 pt. A tile the
  player taps should be at least that.

### 12.2 Open: inner display, whole battlefield

16 tiles × 44 pt = 704 pt wide, 12 × 44 = 528 pt tall. That leaves about 186 pt
for a side panel and 98 pt for a top bar.

```
+----------------------------------------------------------+--------------+
| Turn 4  Player phase     Cap 4/5      [Threat] [Menu]    |  GHOUL       |
+----------------------------------------------------------+  Flesh       |
|  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .          |  HP 17/22    |
|  .  .  #  #  .  .  .  .  .  .  .  +  +  .  .  .          |  Mgt 11      |
|  .  .  #  .  .  S  .  .  .  .  +  C  +  .  .  .          |  Grd 2 Wrd 2 |
|  .  O  .  .  G  .  .  x  .  .  .  +  .  P  .  .          |  Mov 5 Rng 1 |
|  .  .  .  S  .  .  .  .  .  M  .  .  .  .  .  .          |  Feed        |
|  .  .  .  .  .  A  .  .  x2 .  .  K  .  .  .  .          +--------------+
|  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .          |  FORECAST    |
|  .  .  #  .  .  .  .  .  .  .  .  .  Y  .  .  .          |  Ghoul > Clr |
|  .  .  #  #  .  .  .  .  .  .  .  .  .  .  .  .          |  15 dmg  ^   |
|  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .          |  Kills       |
|  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .          |  Counter: -  |
|  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .          +--------------+
+----------------------------------------------------------+ [Raise]      |
                                                           | [Skill]      |
 O overlord  S skeleton  G ghoul  A bone archer            | [Wait]       |
 M militia  K knight  C cleric  P paladin  Y pyromancer    | [Undo]       |
 x corpse  x2 pile of two  + consecrated  # wall           | [End phase]  |
                                                           +--------------+
```

- The whole map is visible. No scrolling.
- The side panel shows the selected unit, the combat forecast, and the action
  buttons. The forecast is never under the finger.
- The panel sits on the trailing side, within thumb reach of the right hand. A
  setting mirrors it for left-handed play.

### 12.3 Folded: outer display, quick play

At 466 pt wide, 16 columns would be 29 pt each: too small to tap. The outer
display therefore shows **part of the map** at full tile size and scrolls.

```
+------------------------------+
| T4 Player   Cap 4/5   [Menu] |
+------------------------------+
|  .  .  G  .  .  x  .  .  .   |
|  .  S  .  .  .  .  .  M  .   |
|  .  .  .  A  .  .  x2 .  .   |
|  .  .  .  .  .  .  .  .  .   |
|  #  .  .  .  .  .  .  .  .   |
|  #  #  .  .  .  .  .  .  .   |
|  .  .  .  .  .  .  .  .  .   |
|  .  .  .  .  .  .  .  .  .   |
|  .  .  .  .  .  .  .  .  .   |
+------------------------------+
| GHOUL Flesh  HP 17/22   [i]  |
| > Cleric: 15 dmg ^  Kills    |
+------------------------------+
| +------+  [Raise]  [Skill]   |
| | mini |  [Wait]   [Undo]    |
| | map  |  [Threat] [End]     |
| +------+  [< Unit] [Unit >]  |
+------------------------------+
```

- About 9 columns by 9 rows of 48 pt tiles are visible. Drag to scroll; pinch
  out for a whole-map overview in which tiles are too small to command but can
  be tapped to jump the camera.
- The mini-map shows the whole field and the current view. Tapping it moves the
  camera.
- "Unit" arrows cycle through units that have not acted, moving the camera to
  each, so a full turn can be played with one thumb.
- Fast turns: enemy phase animations play at double speed on the outer display,
  with a setting to change this.

### 12.4 Moving between the displays

- **Unfolding:** the camera's centre tile, the selected unit, any half-made
  move, and the open menu are all kept. The view widens to the whole map.
- **Folding:** the same state is kept. The camera centres on the selected unit,
  or on the tile that was at the centre if nothing is selected.
- Nothing reloads. The rules state is not touched by a display change; only the
  layout is recalculated.
- A fold in the middle of an enemy phase does not pause or skip it.

### 12.5 Half-folded like a laptop: tabletop

The fold runs across the middle. The top half is the screen; the bottom half
lies flat and is the controller. Each half is about 626 × 445 pt under the same
assumption.

```
+--------------------------------------------+
|  T4 Player phase              Cap 4/5      |
|  .  .  #  #  .  .  .  .  .  .  .  +  +  .  |
|  .  O  .  .  G  .  .  x  .  .  +  C  +  .  |   top half: map only,
|  .  .  .  S  .  .  .  .  .  M  .  +  .  P  |   whole field, 39 pt tiles,
|  .  .  .  .  .  A  .  .  x2 .  .  K  .  .  |   not touched
|  .  .  #  .  .  .  .  .  .  .  .  .  Y  .  |
+============================================+   fold
|  GHOUL  Flesh  HP 17/22     > Cleric 15 ^  |
|                                            |
|  +--------------+     [Raise]   [Skill]    |   bottom half: controls
|  |  touch pad   |     [Wait]    [Undo]     |
|  |  moves the   |     [Threat]  [End]      |
|  |  map cursor  |     [< Unit]  [Unit >]   |
|  +--------------+     [Confirm]            |
+--------------------------------------------+
```

- The top half shows the whole map. Tiles can be smaller than 44 pt here because
  the player does not tap them.
- The bottom half has a touch pad that moves a cursor on the map, plus the
  action buttons. A game controller uses the same cursor.
- Half-folded like a book (fold running top to bottom): map on the left half,
  scrolling as on the outer display; panel and buttons on the right half.
- Nothing is placed across the fold, following Apple's guidance.

### 12.6 Touch, Pencil and controller

| Input | Select and move | Attack or raise |
|---|---|---|
| Finger, tap | Tap unit, tap destination | Tap target, read forecast, tap Confirm |
| Finger, drag | Drag unit along its path | Drag onto target and hold to see the forecast, release, tap Confirm |
| Apple Pencil | Same as finger; drawing a line from a unit sets its exact path, tile by tile | Draw from the overlord to a corpse to order a raise; from a unit to an enemy to order an attack |
| Controller or touch pad | D-pad or stick moves the cursor; A selects, B cancels | A on target, A to confirm |

- Pencil gives position and tilt only on iPhone Duo. Nothing depends on
  pressure or hover.
- Every Pencil action has a finger equivalent.
- Long-press any unit or tile for details.

### 12.7 Always-visible information

- Corpses, pile counts, and consecrated tiles are drawn on the map at all
  times, with shape as well as colour.
- The command cap is always in the top bar.
- The Threat toggle shows every tile enemies can attack next phase, and marks
  corpse piles they can burn or consecrate.

### 12.8 Frame rate and haptics

- 120 frames per second during movement, attacks and scrolling. 30 on menus and
  while the screen is still. 60 during the enemy phase.
- Three distinct haptic patterns to design on the device: a slow rising pulse
  for a raise, a single sharp crack for holy damage, a fading rumble for a
  burned pile.

## 13. Open items for GATE 2

Update 2026-11-25: items 1 to 4 are decided (hybrid; App Store release;
sprites from Google's image generation; title to be workshopped). Items 5 to
12 are in use as provisional defaults and await Adam's confirmation. See
`DECISIONS.md`.

From the brief:

1. **Campaign structure:** linear, roguelite, or hybrid. Recommendation:
   hybrid, built linear first (section 11).
2. **Personal project or App Store release.** The engine choice (native Swift)
   works for both. A release needs the paid developer program, original or
   properly licensed art, and App Store screenshots.
3. **Art direction** and who makes it. RESEARCH.md 6.2 explains why strict
   pixel art is harder on this device. Recommendation: decide after the display
   scale is measured on the Mac; the slice uses placeholder shapes.
4. **Final title, and a default overlord name.**

From this draft:

5. **No randomness in combat** (3.2). Agree, or prefer hit chances and
   criticals in the Fire Emblem style?
6. **Promotion lines** (section 7). Are Revenant → Blackguard and Acolyte →
   Archlich the overlord's own ranks, as written here, or unit promotion lines?
7. **Holy damage.** Written here as "a unit killed by Holy damage leaves no
   corpse". Is that what "destroys a unit outright" meant?
8. **Corpse piles** (3.3). Several corpses can share a tile and one burn
   destroys them all. Agree?
9. **Dismiss** (3.5). A free action that turns one of your undead into a corpse
   so you can raise something else. Agree?
10. **Consecration lasts until the cleric dies** (3.6). Agree?
11. **Outer display shows part of the map and scrolls** (12.3), instead of
    shrinking the map to fit. Agree, or prefer a smaller map?
12. **Vertical slice contents.** Proposed: overlord (no path, cap 5) with 2
    Skeletons, 1 Bone Archer and 1 Ghoul, against 3 Militia, 1 Archer, 1 Knight,
    1 Cleric and 1 Pyromancer, on a 16 × 12 map with two graveyard tiles. Win by
    routing the enemy.
