# Game Design Document

Working title: Necromancer Tactics. Draft 3, 2026-11-26. GATE 2 decisions are in
section 13. Draft 3 adds the design principles from the updated brief (section
2.1) and the changes they call for (section 14), which await Adam's review.

Status of what is in here:

- **Agreed** items come from the project brief and are not open for change
  without Adam.
- **Proposed** items are Claude's first-pass design. All numbers are starting
  values to be tuned by playtest, and all of them live in data files, not code.
- Section 13 records what Adam decided at GATE 2. A heading marked "decided"
  reflects those decisions; "proposed" marks design that has not been reviewed.

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
4. **Everything is readable.** The forecast shows the exact damage and the true
   chance to hit. The player can always see what an action can do and what the
   enemy can reach.
5. **Playable in two minutes or twenty.** Folded for a quick turn, open for the
   full view, with nothing lost between them.

### 2.1 Design principles (from the brief, non-negotiable)

Added by Adam on 2026-11-26, drawn from player complaints about necromancer
classes in other games (RESEARCH.md 7.5). Section 14 checks the design against
each one.

1. **The army is the main source of power.** Most damage and board control come
   from raised units, not from the overlord's spells.
2. **It has to feel like an army.** The command cap starts modest and grows
   large. The Lich King path reaches swarm size.
3. **Minions scale.** Raised units improve as the overlord progresses. They must
   not fall off late in the game.
4. **Raise from real corpses.** Units come only from bodies on the map.
5. **The overlord must matter to the undead.** Raised units are stronger near
   the overlord, or need the overlord to raise and empower them.
6. **No bad minion AI.** The player commands each unit directly. Any
   auto-control option must be good enough to rely on.
7. **The world reacts.** Factions, villages and heroes respond to how feared
   the player is.

## 3. Battle rules

### 3.1 Turn structure (agreed: player phase, then enemy phase)

- A battle is played on a square grid. One unit per tile.
- **Player phase:** each of your units may move and then take one action, in any
  order you choose. Then you end the phase.
- **Enemy phase:** each enemy unit does the same, in a fixed order.
- A unit's turn: **move** up to its Move value (4-direction steps, blocked by
  enemies and impassable terrain), then **one action**: Attack, Raise, a skill,
  or Wait. Acting ends the unit's turn.
- **Undo:** the latest move can be taken back until the unit acts or another
  order is given. Attacks, raises and skills ask for confirmation and cannot be
  undone.

### 3.2 Combat (decided 2026-11-25: hit chances, in the Fire Emblem tradition)

- Each unit has: HP, Might, Guard, Ward, Move, Range, a damage kind (physical or
  magic), a type (section 4), and three accuracy numbers: Hit, Avoid and Crit.
- **Damage on a hit** = (attacker's Might − defender's Guard for physical, or
  Ward for magic) × type multiplier, rounded down, minimum 1.
- **Chance to hit** = attacker's Hit − defender's Avoid, +15 with type
  advantage, −15 with disadvantage, −10 if the defender stands on rough ground.
  Kept between 0 and 100.
- **Critical hits:** a hit has the attacker's Crit chance of dealing double
  damage.
- **Counterattack:** if the defender is still standing and the attacker is
  within the defender's Range, the defender strikes back once, with its own
  chance to hit and to crit.
- No double attacks.

Fairness rules:

- **The number shown is the real chance.** One roll decides a hit; nothing is
  adjusted behind the scenes.
- **Rolls come from a seeded sequence that is saved with the battle.** The same
  battle with the same actions always plays out the same way, which keeps the
  rules testable. A consequence for players: reloading a save and repeating the
  same action gives the same result. Doing something else first changes later
  rolls.
- The forecast shows damage, chance to hit, chance to crit, whether a hit would
  kill, and the same for the enemy's reply.

Critical hits were added along with hit chances because both were offered
together in the question Adam answered. If only misses were wanted, setting
every unit's Crit to 0 in `units.json` removes them.

### 3.3 Corpses (agreed core, proposed details)

- **Any unit that dies leaves a corpse on its tile** (agreed), with one
  exception: a unit killed by a Holy-type attack leaves nothing (agreed; see
  3.6).
- A corpse records exactly what the unit was: its unit kind and, for your own
  undead, its skills and level. Raising it gives back that unit.
- **Corpse piles (decided):** a tile can hold any number of corpses. Units can
  stand on and move through corpse tiles.
- Corpses last until the battle ends unless destroyed.
- A body keeps the identity of the unit it was. Raised again, it is the same
  unit to the game and to the interface.
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
- **Dismiss (decided):** as a free action, once per phase, you may release one
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
| **Consecration** | A cleric's Consecrate action blesses a target tile of open ground within range 2 and the four tiles next to it (walls and water are skipped). Corpses there cannot be raised. The blessing lasts **until that cleric dies**. Each cleric keeps at most two blessed areas; a third replaces the oldest | Kill the cleric. Later: units with Defile remove a blessing |
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
| Forest / rubble | Costs 2 Move to enter. +1 Guard to the unit on it, and attacks against it are 10 points less likely to hit |
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
- **Sovereign**: the overlord, and necromancer units such as the Gravespeaker.
  Neutral against everything, so the unit whose
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

## 5. Unit roster (first-pass numbers)

Columns: HP, Mgt (Might), Grd (Guard), Wrd (Ward), Mov (Move), Rng (Range; "2"
means exactly 2, "1–2" means either), Dmg (P physical, M magic). Ranges given for
abilities and for Raise Range, such as "range 2", mean up to that distance.

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
| Hollow Priest | Spirit | 16 | 8 | 2 | 6 | 4 | 1–2 | M | Mend: action, restores 6 HP to an ally within 2, the overlord included |
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

### 5.3 Accuracy

Hit, Avoid and Crit are percentages.

| Unit | Hit | Avoid | Crit | | Unit | Hit | Avoid | Crit |
|---|---|---|---|---|---|---|---|---|
| Overlord | 90 | 10 | 0 | | Militia | 80 | 5 | 0 |
| Gravespeaker | 85 | 10 | 0 | | Archer | 85 | 5 | 0 |
| Skeleton | 85 | 5 | 0 | | Knight | 80 | 0 | 5 |
| Bone Archer | 90 | 5 | 5 | | Reaver | 80 | 10 | 10 |
| Dread Knight | 80 | 0 | 5 | | Warhound | 85 | 20 | 0 |
| Ghoul | 80 | 10 | 5 | | Scout | 85 | 25 | 5 |
| Carrion Hound | 85 | 20 | 0 | | Pyromancer | 85 | 10 | 0 |
| Oathbreaker | 85 | 5 | 5 | | Cleric | 90 | 10 | 0 |
| Shade | 90 | 25 | 5 | | Paladin | 85 | 5 | 5 |
| Ash Wraith | 85 | 10 | 0 | | | | | |
| Hollow Priest | 90 | 10 | 0 | | | | | |

An even matchup is typically 75 to 85 percent. Type advantage adds 15 points
and disadvantage takes 15 away, so disadvantaged attacks land between 40 and 75
percent of the time depending on the pairing. Fast, light units (Shade, Scout, hounds)
are the hard ones to hit.

### 5.4 Checking the numbers

Damage below is on a hit.

| Attack | Calculation | Result |
|---|---|---|
| Skeleton → Militia | (10 − 3) × 0.75 | 5 of 16 HP. Four hits. 65% to hit |
| Militia → Skeleton | (9 − 4) × 1.5 | 7 of 18 HP. Three hits |
| Ghoul → Cleric | (11 − 1) × 1.5 | 15 of 14 HP. One hit. 85% to hit |
| Shade → Knight | (9 − 2) × 1.5 | 10 of 24 HP. Three hits |
| Knight → Shade | (11 − 5) × 0.75 | 4 of 12 HP. Three hits |
| Pyromancer → Ghoul | (11 − 2) × 1.5 | 13 of 22 HP. Two hits |
| Cleric → Shade | (8 − 3) × 1.5 | 7 of 12 HP. Two hits, and no corpse |
| Paladin → Skeleton | (11 − 4) × 1 | 7 of 18 HP. Three hits, and no corpse |

Most even fights last two to four exchanges, and the right matchup removes a
priority target in one or two.

## 6. The overlord

- The player names the overlord. A default name will be workshopped with the title (13.4).
- Before choosing a path (Rise): Sovereign type, HP 24, Mgt 14, Grd 3, Wrd 4,
  Mov 4, Rng 1–2, magic damage, Raise Range 2.
- The overlord gains levels from battles won and objectives met, level 1 to 10.
  Level raises the command cap (3.5) and the overlord's stats.
- The path is chosen at level 3, at the end of the Rise act.

## 7. Overlord paths (agreed table, proposed mechanics)

| | Death Knight | Lich King |
|---|---|---|
| Overlord's role (agreed) | Front line | Back line |
| Overlord stats at level 3 | HP 34, Mgt 15, Grd 7, Wrd 3, Mov 4, Rng 1, physical | HP 22, Mgt 14, Grd 2, Wrd 6, Mov 4, Rng 1–3, magic |
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

Adam confirmed at GATE 2 that these are the overlord's own ranks (13.6).

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

## 10. Enemy AI (built for the slice)

The AI has no randomness of its own. Each enemy unit looks at every tile it can
reach and every action it could take from there, and scores each by expected
value: what success is worth times its chance, minus the expected cost of the
enemy's reply. The weights are data (`rules.json`, under `ai`), so behaviour is
tuned without code changes. What the weights are set to produce:

1. **Kill the overlord if the phase can.** When the enemies still to act could
   bring the overlord to zero between them, every one that can reach it attacks,
   whatever the reply costs them.
2. **Clerics** consecrate the bodies a raiser could reach next phase, choosing
   the spot that covers the most value. Bodies no raiser can reach count for a
   quarter. A cleric at its two-area limit counts what a new blessing would
   uncover, so it does not cycle. It heals a badly hurt ally when no reachable
   body is worth more.
3. **Pyromancers and paladins** burn the most valuable pile in reach, more
   readily if a raiser could get to it and less if it is already on consecrated
   ground.
4. Everyone else attacks where the expected trade is best. Type advantage,
   kills and raisers score higher. A unit that can land a hit attacks rather
   than waits, unless the reply would probably kill it.
5. Holy units prefer kills, since those leave no corpse.
6. A badly hurt unit with nothing useful to do falls back toward a healer.
   Units with nothing in reach walk toward their goal by the shortest route
   round walls. Clerics and fire users with no bodies to deny stay with the
   fighters.

Not built: avoiding a death that would leave a corpse within the overlord's
Raise Range.

Measured on the slice map over 200 seeded battles against a competent scripted
player (the overlord walks to bodies and raises them; other units use the same
planning as the enemy): 171 player wins, 20 losses, 9 unfinished after 80
turns; 1,374 raises, 190 consecrations and 124 corpse burnings. Against a
player that never seeks out bodies: 2 wins, 197 losses, 1 unfinished. Raising decides the
battle, which is the intent. These are scripted players, not people; balance
still needs a human.

The player can see what the AI is going for: a toggle shows enemy threat range,
and corpse piles an enemy can burn or consecrate next phase are marked. The
rules module provides both as queries.

## 11. Campaign (agreed arc; hybrid structure decided)

1. **Rise:** three to four small skirmishes that teach raising, the cap,
   consecration and burning, one at a time. Ends with the path choice.
2. **Conquest:** take territory on a region map. Build the keep between battles.
3. **Reckoning:** named heroes hunt the overlord, including assaults on the
   keep.

Structure options considered:

| Option | What it is | For | Against |
|---|---|---|---|
| Linear story | Fixed sequence of hand-made maps | Best pacing and tutorials; simplest to build | Low replay value; needs the most hand-made content |
| Roguelite | Each run generates a region, enemies and heroes; overlord death ends the run | High replay value; suits "overlord is the only fail state" | Needs map generation and much more balance work; weaker story |
| Hybrid | Fixed three-act spine with hand-made key battles; between them, generated raids for Dread and bodies | Story plus replay; generated battles reuse the same rules | More systems than linear |

Decided at GATE 2: **hybrid**, built as linear first. The vertical slice and the
Rise act are hand-made either way, so the decision does not affect work before
GATE 3.

## 12. Screens and controls

### 12.1 Facts and assumptions

- The inner display is wider than tall in the natural open pose (2670 × 1878
  pixels), and the outer display is taller than wide when closed (1398 × 2034
  pixels). Source: RESEARCH.md section 1.
- The open phone can also be turned to portrait, and Apple's statements on
  locking orientation conflict (RESEARCH.md 3.1). **An open, flat, portrait
  layout is not designed yet.** Until it is, the game lays out whatever size it
  is given, and that pose gets the folded layout scaled up.
- The slice map is **16 columns by 12 rows**, landscape, matching the inner
  display.
- Point sizes are not yet known (RESEARCH.md 6.1). The layouts below assume
  3 pixels per point and that the app draws at the panel's pixel size: about
  890 × 626 pt inner and 466 × 678 pt outer. Inference: if the app instead draws
  at App Store Connect's inner screenshot size (2853 × 2007 pixels), the inner
  display would be about 951 × 669 pt, which leaves more room, not less. Both
  must be measured on the Mac (MAC_SETUP.md section 7).
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
|  .  .  #  #  .  .  .  .  .  .  .  .  .  .  .  .          |  15 ^  85%   |
|  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .          |  Kills if hit|
|  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .          |  Reply 4 65% |
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
| > Cleric 15 ^ 85%  reply 4   |
+------------------------------+
| +------+  [Raise]  [Skill]   |
| | mini |  [Wait]   [Undo]    |
| | map  |  [Threat] [End]     |
| +------+  [< Unit] [Unit >]  |
+------------------------------+
```

- About 9 columns by 9 rows of 48 pt tiles are visible. Drag to scroll; pinch
  out, or tap an Overview button, for a whole-map overview in which tiles are
  too small to command but can
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
|  .  .  .  S  .  .  .  .  .  M  .  +  .  P  |   whole field, 34 to 37 pt tiles,
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

## 13. GATE 2 outcomes

Decided on 2026-11-25, except where a row says otherwise. Details and Adam's
words are in `DECISIONS.md`.

| # | Item | Outcome |
|---|---|---|
| 1 | Campaign structure | Hybrid, built linear first |
| 2 | Personal or App Store | Eventual App Store release |
| 3 | Art | Sprites from Google's image generation (setup as used for Gravewright). Pixel art vs high-resolution still to be chosen after display measurements |
| 4 | Title, overlord name | To be workshopped |
| 5 | Randomness | **Changed:** hit chances, as in section 3.2. Critical hits were added with them and await Adam's confirmation |
| 6 | Promotion lines | The overlord's own ranks |
| 7 | Holy damage | A unit killed by Holy damage leaves no corpse |
| 8 | Corpse piles | Yes |
| 9 | Dismiss | Yes |
| 10 | Consecration lasts until the cleric dies | Yes |
| 11 | Outer display scrolls | Yes |
| 12 | Slice line-up | Overlord (cap 5), 2 Skeletons, 1 Bone Archer, 1 Ghoul against 3 Militia, 1 Archer, 1 Knight, 1 Cleric, 1 Pyromancer, on a 16 × 12 map with two starting corpses |

## 14. The design against the principles (proposed, for Adam's review)

What draft 2 already did, what it lacked, and what is proposed. Nothing in this
section is in the code yet. The vertical slice needs none of it except where
noted.

| # | Principle | Draft 2 | Verdict |
|---|---|---|---|
| 1 | Army is the main source of power | The overlord had the attack of a Skeleton and no damage spells | Changed by Adam: the overlord now hits hardest. See below for how the army stays the main source of power |
| 2 | Feels like an army | Caps of 4 to 7 (Death Knight) and 6 to 12 (Lich King) | **Too small.** Twelve units is not a swarm |
| 3 | Minions scale | Only the Death Knight's raised units gain levels. Lich King units never improve | **Missing** |
| 4 | Real corpses only | Every unit comes from a body on the map, including the keep's Charnel Pit, which places bodies | Holds |
| 5 | Overlord matters to the undead | Only the overlord (and Gravespeakers) can raise. Only the Death Knight strengthens nearby units | Passes on the "or", but weakly. After raising, the overlord has little reason to be near the army |
| 6 | No bad minion AI | Direct command of every unit. No auto-control designed | **Needed** once armies are large |
| 7 | The world reacts | A currency called Dread, and heroes who arrive in the last act | **Thin.** No system makes the world respond |

### 14.1 Overlord power (principle 1; decided by Adam 2026-11-26)

Adam's decision: **the overlord hits harder than any of his minions.** Might is
now 14 before a path is chosen (the strongest undead, the Oathbreaker, has 13),
15 for the Death Knight and 14 for the Lich King at level 3. A test fails if
any undead ever matches the overlord's Might.

How this sits with principle 1, that most damage and board control come from
the army:

- The overlord is the strongest single piece, but acts once a turn like every
  unit, and an army of five to twenty-four acts five to twenty-four times. The
  army's total damage stays several times the overlord's.
- **The overlord's action is contested.** Attacking and raising both use it, so
  every hard hit is a body left on the ground.
- **Using that strength is a risk.** The overlord is the only fail state, and to
  strike he has to be within reach of the enemy.
- The overlord still has no area damage and no way to act twice by attacking.
  His multipliers go to the army (raise, empower, command).

Rules for future balance:

1. At every level the overlord's Might is at least 1 above the highest Might of
   any undead he can field at that level, including after the scaling in 14.3.
2. Measured in whole battles, the army deals most of the damage. If testing
   shows the overlord dealing more than about a third of it, the fix is to the
   army's strength or the overlord's risk, not to the rule above.

Not yet measured: the scripted test player never attacks with the overlord, so
the test battles show only the effect on his counterattacks. A person playing
will use him more.

### 14.2 A larger command cap (principle 2)

Proposed table, replacing the one in 3.5. The slice keeps its cap of 5.

| Overlord level | No path | Death Knight | Lich King |
|---|---|---|---|
| 1 | 4 | | |
| 2 | 5 | | |
| 3 (path chosen) | | 6 | 8 |
| 4 | | 6 | 10 |
| 5 | | 7 | 12 |
| 6 | | 8 | 14 |
| 7 | | 9 | 16 |
| 8 | | 10 | 18 |
| 9 | | 11 | 20 |
| 10 | | 12 | 24 |

What this costs:

- **Bigger maps.** Twenty-four undead and their enemies do not fit a 16 × 12
  field. Late maps need to be around 24 × 18, which means the open display
  scrolls too. The whole-map view in 12.2 then holds only for early battles.
- **More enemies**, so that battles produce enough bodies to raise.
- **Faster turns**, which is 14.5.
- The Death Knight path stays the smaller, elite army, as agreed, but ends at
  twelve units instead of seven.

### 14.3 Minions that scale (principle 3)

Proposed, in three layers:

1. **The overlord's level lifts every undead.** For each two overlord levels
   above the first, every undead the player controls has +2 HP and +1 Might.
   This applies the moment a unit is raised, so the Lich King's disposable
   units scale too, and a Skeleton raised at level 9 is not the Skeleton of
   level 1.
2. **What it was in life.** A stronger enemy rises as a stronger undead. This is
   already true by kind (a Knight becomes a Dread Knight); it would extend to
   level, so late-game enemies leave better bodies. Raised named heroes stay
   the strongest units, as agreed.
3. **The keep.** Rooms such as the Black Forge (section 8) give permanent
   bonuses by type, and each basic undead gets one promotion bought at the
   keep, for example Skeleton to a veteran form.

The Death Knight path keeps its extra: its raised units also keep skills and
earn levels of their own.

### 14.4 Dominion: the overlord's presence (principle 5)

Proposed for all paths: undead within 3 tiles of the overlord have +10 to hit
and +1 Might. The Death Knight's existing bonus to adjacent units becomes a
stronger version of this. Gravespeakers can raise only while inside the
overlord's Dominion, so no raising happens without the overlord.

Why: the overlord is the only fail state, so today the safe play is to raise
and then hide. Dominion pulls the overlord toward the fight and makes that a
real choice. It is cheap to add to the rules (two numbers in `rules.json`) and
could go into the slice if Adam wants to feel it there.

### 14.5 Commanding a large army (principle 6)

- Direct command of every unit stays the default.
- Proposed: **group orders**. Select several undead, or all that have not
  acted, and give one order: advance on a target, hold, or attack at will. Each
  unit then acts using the same planner the enemy uses.
- The bar for "good enough to rely on": that planner already drives the
  player's army in the test battles, where it wins 171 of 200 with a simple
  overlord script. Before group orders ship, the same test must hold on a
  swarm-sized battle, and units under a group order must never take an action
  the forecast shows as a likely death without the player choosing it.
- The interface must also cope: the unit list, the "next unit" buttons and the
  command-cap display in section 12 were drawn for five units.

### 14.6 A world that reacts (principle 7)

Proposed: a **Notoriety** score for the campaign, rising with territory taken,
battles won and heroes raised.

- **Villages** respond by level: at low Notoriety they resist with militia; in
  the middle they pay tribute or flee, which changes what bodies a region
  offers; at high Notoriety some surrender and others call for help.
- **The enemy adapts.** Higher Notoriety brings more clerics, pyromancers and
  paladins in ordinary parties, then holy orders, then the named heroes of the
  Reckoning act. Conquest draws stronger heroes.
- **Factions** remember: sparing or raising a faction's dead changes how its
  remaining forces fight the player.

This is campaign design for later phases. The slice does not need it.

### 14.7 Questions for Adam

1. Are the larger caps in 14.2 right, knowing they bring bigger maps that
   scroll on the open display as well?
2. Is the scaling rule in 14.3 the kind you want, with the overlord's level
   lifting every undead?
3. Dominion (14.4): add it, and should it be in the vertical slice?
4. Group orders (14.5): is that what you mean by an auto-control option?
5. Notoriety (14.6): is this the direction, for when the campaign is designed?

