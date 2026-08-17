# Rogue — All Specs HUD (v55)

Import `all-specs.txt` whole. Layout groups (drag each in /wa): Buffs, Alerts, Resources,
Procs, Cooldowns, PvP. Everything that used to be the ring cluster *and* the combo row is now
one sub-group — `Rogue - Player Sill` — so the whole instrument can be dragged, or disabled,
on its own.

**v54 replaces the ring cluster with The Sill: a 102 × 37 px instrument strip under your
character, where one pixel is one percent.** Four stacked 100px rails — threat, health, energy,
combo — with the numbers printed *inside* the rails and every breakpoint drawn as a full-height
waterline instead of a mark on a circumference. The five combo pips move in from their own row,
so the two things a rogue actually decides between — *do I have the points* and *can I afford
the finisher* — are **1px apart instead of 233**. It costs **3,774 px²** against the old
cluster's **12,408**, and it loses two things on purpose: the 3D portrait and the printed threat
percentage. Both are argued for below. No aura is added or removed; all 58 UIDs carry across.

## v55 — the number offsets were never actually applied

**A silent no-op that had shipped for a long time.** WeakAuras anchors a subtext with
`text_anchorXOffset` / `text_anchorYOffset` — `SubRegionTypes/SubText.lua` reads exactly those
keys, and the options panel writes them. But `SubText.lua`'s own `default()` still emits the
bare `anchorXOffset` / `anchorYOffset`, **and no `Modernize` step bridges the two**. This repo
emitted only the bare pair, so every offset was dropped and every number rendered dead on its
anchor point.

Across the seven packs that was **21 non-zero offsets doing nothing** — most visibly the rail
percentages, which sat centred in their rails instead of right-aligned at `x +32`.

This is not the `text_anchorPoint` case, and the distinction is the whole trap: *that* key **is**
renamed (`Modernize.lua`, `internalVersion < 80`, `subtext.text_anchorPoint → anchor_point`), so
emitting the old name is correct there. There is no such migration for the offsets. Both
spellings are now written and kept equal, `F.subtextOffset` is the only sanctioned way to move a
number, and `verify-packs.lua` now fails any subtext that sets one spelling without the other or
sets them to different values.

Nothing else in this version changed: no aura added, removed, renamed or re-parented, and every
uid is byte-identical.

## v54 — The Sill

### What it is

A `102 × 37` strip at absolute **(0, −110)**, directly under your character. Six lanes,
fifteen auras, every one of them an aura that already existed, listed here in **draw order** —
which is `controlledChildren` order, bottom first:

| draw | lane | region | w × h | local (x, y) | absolute y span |
|---|---|---|---|---|---|
| 1 | **Alarm rim** | texture | 108 × 43 | (0, 0) | −131.5 … −88.5 |
| 2 | **Sill Plate** | texture | 102 × 37 | (0, 0) | −128.5 … −91.5 |
| 3 | **Threat rail** | progresstexture | 100 × 4 | (0, +15.5) | −96.5 … −92.5 |
| 4 | **Health rail** | progresstexture | 100 × 11 | (0, +7) | −108.5 … −97.5 |
| 5 | **Energy rail** | progresstexture | 100 × 11 | (0, −5) | −120.5 … −109.5 |
| 6–15 | **Combo lane** | 10 textures, 16 × 6 | 96 wide | (±40/±20/0, −14.5) | −127.5 … −121.5 |

`4 + 1 + 11 + 1 + 11 + 1 + 6 = 35` rows of content spanning local `+17.5 … −17.5`, plus a 1px
margin all round — which is where 102 × 37 comes from. The alarm rim is 3px larger on every
side, is drawn *underneath* everything, and only exists at ≥ 80 % threat; the section
["The threat alarm is a rim, not an outline"](#the-threat-alarm-is-a-rim-not-an-outline)
explains why it has to be built that way.

Each rail below is drawn to scale — one character is two percent, `|` and `:` and `X` are the
real breakpoints at their computed positions:

```
  one pixel is one percent ->        0          25          50           75          100
                                     |           |           |            |           |
  threat  100 x  4   at 46%         |#######################...........|...............|
  health  100 x 11   at 84%         |############:###########:############:####........|
  energy  100 x 11   at 71          |############:####X#X####:###########.:............|
  combo   5 x 16 x 6 at 3           |[######]  [######]  [######]  [      ]  [      ]  |

     |  the 70 threat notch      :  the 25/50/75 ruler      X  the 35 / 40 energy marks, lit
```

### Why a strip and not a smaller ring

`Ring_20px.tga` has a stroke of 20/256 = **7.8 % of the drawn size**, so a ring's stroke is a
fixed *fraction* of its diameter: you cannot draw a small ring with a thick stroke. At the sizes
v53 shipped, the three arcs bought 712.5px of gauge inside a 10,000 px² box:

| ring | band it painted | arc length |
|---|---|---|
| threat, 100px | `r 42.19 … 50.00` | 289.6 px |
| health, 84px | `r 35.44 … 42.00` | 243.3 px |
| energy, 62px | `r 26.16 … 31.00` | 179.6 px |

A 0–100 quantity has exactly **100 distinguishable states**. A 243px arc spends 143px redrawing
states the eye cannot separate on a curve anyway, and 1,936 px² of that box — 19.4 % — was a 3D
model carrying no decisions at all. **100px is the length at which a 0–100 gauge is lossless**:
every pixel beyond it is redundant, every pixel below it throws a state away.

It also makes every breakpoint arithmetic instead of trigonometry:

> **x(v) = (v / maxpower − 0.5) × 100**, which for a 100-max resource is just **x = v − 50**.

The 35-energy Eviscerate mark was at `(23.575, −17.128)` on a circumference. It is now at
`x = −15`. The 40-energy Sinister Strike mark is at `x = −10`. The 70 threat notch is at
`x = +20`. Same three constants the pack always used, no `sin`/`cos` anywhere.

### How to read it

- **Threat rail** (top, 4px). Absent means you are solo, in an arena, or not on anyone's threat
  table — its party/raid gate is unchanged. Green fill = your share of the pull threshold.
  **When the fill touches the white notch you are at 70 — stop or dump.** Orange past 70, red
  when you have aggro, and at 80 a red rim pulses around the whole instrument — *around* it,
  not over it: nothing is drawn on top of a readout.
- **Health rail.** Fill = health; the number at the right-hand end is the exact percent; three
  faint hairlines at 25/50/75 turn "estimate a fraction" into "count quarters". The rail turns
  red at 30 % — colour *is* the threshold.
- **Energy rail.** Same shape, raw `%p` at the right-hand end because 35 and 40 are absolute
  costs, not percentages — and now the rail's own scale is absolute too, so the number and the
  bar finally agree. Two permanent hairlines mark 35 (red) and 40 (purple); **when a fat bright
  line appears next to one, you can afford that ability right now.**
- **Combo lane.** Count lit blocks left to right; five lit = finisher. Green→orange ramp,
  unchanged, and the pop animation is unchanged.
- Out of combat the plate, the health and energy rails and all ten pips — 13 regions — sit at
  50 % alpha, exactly as before. The **threat rail is not one of them**: it carries no
  `inCombat` condition and never did; it hides itself instead, through
  `threatvalue <= 0 → alpha 0`.

### What was lost

**The 3D portrait is gone.** `Rogue - Player Portrait` keeps its UID but is now a texture: the
dark bordered plate the whole instrument is drawn on. v49 argued that "nothing in a rogue's
rotation is decided by looking at a model"; v51 reversed that on the grounds that "two
concentric arcs around a live 3D portrait read as *a unit* — you". **v54 reverses it back, on
density grounds**, and that is a taste call you are entitled to overrule. What the plate buys
in exchange is the thing the portrait never did: a dark, bordered ground is what keeps an 11px
rail and an 11pt number legible over snow, lava and Shattrath at noon — which was the original
complaint that v53 only half-answered.

**The threat percentage is no longer printed.** It is not deleted — `sub.1` on the threat rail
is intact and one checkbox away in `/wa` — it is switched off. `threatpct` is scaled so 100 =
pulling aggro, so it is an early-warning *ratio*, not a quantity you spend; reading "68" vs "72"
is slower than watching a fill cross a notch, and it was the one element of the cluster printing
onto open screen at 10pt. Honest caveat: it is switched off *where it was*, so if you re-enable
it in `/wa` it reappears 58px **above** the strip, on open screen. Drag it into the plate or
leave it off.

**The combo pips shrink 5.7× in area** (32 × 14 → 16 × 6). For a rogue this is the primary
rotation driver and the riskiest single reduction here. The mitigation is that a saturated lit
block on a near-black socket at 20px pitch is still unambiguous at five states, and that the
pips now sit **1px under the energy rail**. In v53 they were nowhere near it: the pip row was at
`(±70, −80)` and the energy ring at `(−270, +40)` — **233px centre-to-centre**, 153px of clear
screen edge-to-edge, at opposite ends of the HUD. "Do I have the points, and can I afford the
finisher" was two fixations; it is now one. If it reads badly in combat the lane can grow — but
only by taking pixels from a plate that has 7.5px of clearance to the buff row, so it is a real
trade rather than free.

**The row the pips vacated is now empty.** `y −87 … −73` carries nothing; nothing else moved to
fill it, because nothing else wanted to be there.

### The threat alarm is a rim, not an outline

`Rogue - Alarm Frame` (the old `Rogue - Threat Flash`) keeps its UID, its `threatpct >= 80`
trigger, its party/raid and never-in-arena gates, its `ADD` blend, its explicit
`(1, 0.10, 0.10, 0.85)` red and its 1-second `alphaPulse`. What changed is its size and its
place in the draw order, and the reason is worth stating plainly because it is the one thing
about this build that is easy to get wrong:

> **`Square_White_Border.tga` is a *filled* square.** It is the art this pack's dark combo
> *sockets* are drawn from, and a lit pip of identical size at identical coordinates hides one
> completely. A single region on that texture **cannot draw a hollow outline.**

That is measured, not inferred. The file WeakAuras ships is 256 × 256, 32-bit, and **98.44 % of
its pixels are fully opaque**: alpha is 255 everywhere except a 1px transparent margin, and
every pixel inset 8px or more is `rgba(255, 255, 255, 255)`. The "border" is a dark bevel baked
into the fill — along a centre scanline the red channel runs `156, 100, 56, 40, 57, 102, 158,
206, 236, 250, 254` over the first eleven pixels and is solid `255` from x = 12 to the far edge.
The interior is not transparent; there is nothing to see through.

So the obvious build — one 102 × 37 quad on that texture, `ADD` red, drawn last — is not an
outline at all. It is a **full-area wash**: at ≥ 80 % threat it would composite red over the
entire instrument at 85 % strength, once a second, and the colour coding this HUD leans on
would collapse. The health green `(0.15, 0.82, 0.28)` would read as `(1.0, 0.90, 0.37)` and the
energy yellow `(0.90, 0.80, 0.20)` as `(1.0, 0.89, 0.29)` — the same colour — across both
printed numbers and all five pips, at exactly the moment you have to read energy and combo
points to decide between Feint and one more Sinister Strike.

What v54 ships instead uses the one property a filled quad *does* have — it can be bigger than
the thing in front of it:

- the alarm is **108 × 43**, 3px larger than the plate on every side;
- it is the **first** child of `Rogue - Player Sill`, so it is at the **bottom** of the stack.

The 3px band that sticks out past the plate is the alarm: a pulsing red rim around the whole
instrument, at full strength, unmissable in peripheral vision. Everywhere else it is behind the
45 %-black plate and behind every rail, number, socket and lit pip, so **nothing is composited
over a readout** — the greens stay green, the yellows stay yellow, and the digits keep their
own contrast. Where a rail is not filled you also get a dim red glow through the translucent
plate, which is a bonus rather than the mechanism.

The build asserts both halves — `alarm.width == plate.width + 6`, `alarm.height ==
plate.height + 6`, and `controlledChildren[1] == the alarm` — because dropping either one
silently turns the rim back into the wash.

### Where it sits, and what it clears

The strip is at **(0, −110)** — under the character, not at the waist. The build re-runs the
rectangle scan on the finished string, with dynamic groups projected six children deep, and
asserts zero overlaps. The box it scans is the **envelope**, not the plate: the widest of the
plate, the alarm rim and the peak of the combo pips' 1.85× pop, so the proof covers everything
the strip can ever draw rather than its resting state:

```
sill plate 102x37, alarm rim 108x43, pop x+-54.80 at (0,-110)
  -> envelope x -54.8..54.8  y -131.5..-88.5
39 elements scanned (dynamic groups 6 deep), 0 overlaps, closest 4.50px (Rogue - Slice and Dice)
```

At rest the plate alone clears the buff row (`y −176 … −136`) by **7.5px**; the alarm rim, which
exists only at ≥ 80 % threat, narrows that to **4.5px**. Sideways there is 39.2px to the
weapon-proc column and 75.2px to the alert column at any stack depth. The group offset is not a
hard-coded number either: it is computed as *whatever takes the real parent chain to (0, −110)*,
and the chain is printed and asserted at build time, with every node checked to be
`SCREEN`-anchored `CENTER`-to-`CENTER` (otherwise adding offsets would not give a centre) —
`Rogue - Player Sill(0,−26) ← Rogue - Resources(0,56) ← Rogue TBC - All Specs(0,−140) = (0,−110)`.

### What did not change

Every trigger, every load gate, every condition and every colour. The build diffs all 58 auras
field by field against v53 and fails on anything not explicitly licensed:

- the threat escalations (`threatpct >= 70` → orange, `aggro == 1` → red) and the mandatory
  `threatvalue <= 0` → alpha 0 guard, without which a progresstexture with a zero total draws
  **full** and reports a complete bar of aggro at the exact moment you have none;
- the party/raid and never-in-arena gates on both threat regions;
- health's `percenthealth < 30` red and its `maxhealth <= 0` guard; energy's `maxpower <= 1`
  guard; the `inCombat == 0` → 50 % fade on the plate, the health and energy rails and all ten
  pips (13 regions — the threat rail has no such condition, in v53 or v54);
- the alarm's `threatpct >= 80` trigger, its `ADD` blend and its 1-second `alphaPulse`;
- the pips' `powertype = 4, power >= N` triggers, the green→orange ramp, and the pop
  (`custom`, `0.3s`, `easeOut`, `scale 1.85`, `alphaPulse`);
- the `%p` and `%percenthealth%%` tokens, `OUTLINE`, and both shadow settings.

Of the 42 auras outside the strip — the top-level container included — **41 decode
byte-identical** to v53, and the one that differs, `Rogue - Resources`, differs in exactly one
field: its child list, which is now just the sill. Counting the strip, 41 of all 58 auras are
byte-identical and 17 changed.

**The `sub.4` / `sub.5` indexes on the energy rail did not move**, and neither did the two
conditions that drive them. That is the reason the rails are `progresstexture` and not
`aurabar`: an aurabar requires `subRegions[1] = {type = "aurabar_bar"}`, which would push every
mark down one slot and silently break `sub.4.textureVisible` / `sub.5.textureVisible`. The build
asserts the conditions still resolve to the 35 and 40 marks by value, not just by index.

### After updating

**Leave the *Arrangement* category checked** on the update dialog. It is checked by default, and
it is the category this whole change travels in: the strip **re-parents** ten combo pips out of
`Rogue - Resources` and into `Rogue - Player Sill`, **re-orders** the sill's child list (draw
order is `controlledChildren` order — WeakAuras gives each child +4 frame levels in list order,
so *alarm rim first, plate second, readouts on top* is load-bearing), and **moves** the group
from (−270, +40) to (0, −110). Uncheck it and you get v53's positions with v54's artwork, which
is a mess.

The flip side: if you have dragged this pack around in game, you will have to re-drag it once.

**Nothing to delete.** 58 auras in, 58 out — `stable=51 changed=0 retained=57 missing=0
parentSame=true` against v53, so the re-import is a clean **Update**. `stable` is 51 rather than
57 because six auras were **renamed** to what they now are; all six kept their UID, which is
what WeakAuras matches on:

| v53 | v54 |
|---|---|
| `Rogue - Player Cluster` | `Rogue - Player Sill` (group, moved to (0, −110)) |
| `Rogue - Player Portrait` | `Rogue - Sill Plate` (model → texture, 44 → 102 × 37) |
| `Rogue - Threat Ring` | `Rogue - Threat Rail` (100 × 100 → 100 × 4) |
| `Rogue - Health Ring` | `Rogue - Health Rail` (84 × 84 → 100 × 11) |
| `Rogue - Energy Ring` | `Rogue - Energy Rail` (62 × 62 → 100 × 11) |
| `Rogue - Threat Flash` | `Rogue - Alarm Frame` (100px ring halo → 108 × 43 rim, drawn first) |

**Coming from v51 or earlier?** The v52 note further down still applies: you have a leftover
`Rogue - Target Cluster` group to delete by hand, once.

### Honest limitations

- **`orientation = "HORIZONTAL_INVERSE"` has never been rendered by this repo.** On a
  progresstexture it is the "Left to Right" value — `HORIZONTAL` is *Right to Left*, the exact
  opposite of what the same word means on an aurabar. It is transcribed from WeakAuras'
  `Private.orientation_with_circle_types` and shares the linear code path with `VERTICAL`, which
  *is* live in a shipped `poc/diablo-globes` string, but no committed string here uses it.
  **30-second check:** drop to about half energy and confirm the empty half is on the **right**.
  If it is reversed, the fix is a one-token swap to `HORIZONTAL` and nothing else changes.
- **A non-square progresstexture is new here.** Every other one in this repo is square (rings and
  globes). `crop_x`/`crop_y` stay at the shipped `0.41`; on the linear path they are a texcoord
  scale, and `Square_White.tga` is uniform, so they cannot alter the art — but the 100 × 11
  aspect stretch itself is untested for this region type in this repo.
- **The numbers straddle the fill.** With a left-to-right rail and the number at `x = +32`,
  health at ~82 % puts the fill edge under the digits. `OUTLINE` + black shadow + the dark plate
  is the mitigation. Judge it in combat, not in the editor.
- **Vigor moves the energy marks.** The build bakes `maxpower = 100`; with the talent the cap is
  110 and the general form puts 35 at `x = −18.2` and 40 at `x = −13.6`. Same limitation the ring
  had, restated because the formula makes it obvious.
- **The alarm costs 3px of clearance while it is up.** The rim takes the buff-row gap from 7.5px
  to 4.5px at ≥ 80 % threat. Both numbers are asserted by the build, and 4.5px is still clear —
  but if you drag the buff row upward, that is the margin you are spending.
- **The alarm is a rim because it cannot be an outline.** `Square_White_Border.tga` is filled;
  see the section above. If you prefer the flare to be brighter you can enlarge the alarm region
  in `/wa` — but every pixel you add is spent on the buff-row gap, and once it is *smaller* than
  102 × 37 it disappears behind the plate entirely.
- **The pips leave the plate at the peak of the pop.** A 1.85× scale on a 16 × 6 pip is
  29.6 × 11.1 for 0.3s, so it reaches `x ±54.8` and `y −130.05`, i.e. 3.8px past the plate's side
  and 1.55px past its bottom. The "1px margin all round" is a *resting* figure. Nothing collides
  — the build scans that excursion as part of the envelope — but the outer pips visibly overhang
  the plate for the length of the animation. It is better than v53, where the same 1.85× pop on a
  32 × 14 pip swelled to 59.2px on a 35px pitch.
- **Four stacked bars is a car dashboard.** The old cluster was a character. That is the honest
  aesthetic cost of a 2.65× density gain, and it is the other half of the taste call.

## v53 — the health number moves into the middle, and your face moves behind the rings

v52 left the biggest empty space in the HUD — the inside of a 100px ring cluster — holding
nothing but a portrait, while all three percentages floated *outside* the arcs on whatever the
world happened to be rendering. Small, detached, unreadable against a bright background. v53
puts the number that matters most where your eye already is.

| Label | v52 | v53 | Token |
|---|---|---|---|
| **health** | 13pt, `y = -54` | **16pt, `y = 0`** — dead centre, over the portrait | `%percenthealth%%`, unchanged |
| **energy** | 10pt, `y = -70` | **12pt, `y = -54`** — the slot health just vacated | `%p`, unchanged |
| **threat** | 10pt, `y = +58` | unchanged | `%threatpct%%`, unchanged |

```
                47%     <- threat %, 10pt, +58 (unchanged)
        .-----------------.
       /   .-----------.   \
      |   /   .-----.   \   |
      |  |   |       |   |  |     100px  threat ring    (party/raid only, unchanged)
      |  |   |  84%  |   |  |      84px  your health    — 16pt, dead centre, over your face
      |   \   '-----'   /   |      62px  your energy    (35/40 marks intact)
       \   '-----------'   /       44px  live portrait  — now the FIRST child, drawn behind
        '-----------------'
                71      <- energy, raw, 12pt, -54 (health's old slot)
```

**The energy number stays raw.** It is `%p`, not a percentage, and it has to be: 35 and 40 are
*absolute* thresholds (Eviscerate, Sinister Strike) and the ring's own breakpoint pips mark
those absolute values on the circumference. "62%" next to two marks that mean 35 and 40 would be
unactionable. Only its position and size changed.

**The non-obvious half: draw order.** Moving the offset alone would have looked like nothing
happened. WeakAuras' `FixGroupChildrenOrder` gives each child **+4 frame levels** in
`controlledChildren` order, so **later = drawn on top**, and v52's cluster ended with the
portrait:

```
v52:  { Threat Ring, Health Ring, Energy Ring, Threat Flash, Player Portrait }
v53:  { Player Portrait, Threat Ring, Health Ring, Energy Ring, Threat Flash }
```

The face was on top of everything, so any text a ring put in the middle went *under* it. The
portrait is now first — furthest back — and the rings, with their subtexts, draw over it.

**That does not bury your face, because a ring is an annulus.** `Ring_20px`'s stroke is 20/256
of the drawn size, so each ring's art occupies only its own band and its middle is empty pixels.
Measured out of the shipped string:

| Region | Band it actually paints |
|---|---|
| threat, 100px | `r 42.19 .. 50.00` |
| health, 84px | `r 35.44 .. 42.00` |
| energy, 62px | `r 26.16 .. 31.00` |
| **portrait, 44px** | `r 0.00 .. 22.00` |

Nothing reaches `r ≤ 22`, so promoting three rings above the model hides no part of it. The only
thing that lands on the face is the FontString — which is the entire point. The 16pt number is
at most 38.4 × 16px, so it also clears the innermost hole (`r = 26.16`) rather than being cut by
the energy stroke.

**Reordering is not free bookkeeping.** The import envelope's flat child list must stay
depth-first in each parent's `controlledChildren` order, so the child list was reordered *with*
the group. v52 left those two disagreeing inside the cluster; v53 makes the whole transmit
depth-first consistent, and the build now asserts it for **every** group in the pack rather than
just this one.

**Nothing else changed.** 58 auras in, 58 out — `stable=57 changed=0 retained=57 missing=0
parentSame=true` against v52, with exactly **three** objects differing in the decoded string:
`Rogue - Health Ring` (one subtext offset + font size), `Rogue - Energy Ring` (the same two
fields; its four 35/40 pip subregions and the `sub.4`/`sub.5` conditions that drive them are
byte-identical) and `Rogue - Player Cluster` (child order). Text tokens, colours, `OUTLINE`,
shadows, every trigger, load gate, condition, size and position are untouched, and the cluster
still lands on `(-270, 40)` with all five regions concentric.

### After updating

**Nothing to delete.** No aura is added, removed or retyped, so all 58 UIDs carry straight
across and the re-import is a clean **Update**. Because the change includes a re-ordering, leave
the update dialog's *Arrangement* category at its default rather than unchecking it — that is
the category the new draw order travels in, and without it the portrait stays on top and the
health number stays invisible.

**Coming from v51 or earlier?** The v52 note below still applies: you have a leftover
`Rogue - Target Cluster` group to delete by hand, once.

### Honest limitations

- **The 3D portrait is the one thing source cannot settle.** Frame levels are what put the
  rings above the model, and a `model` region renders a real 3D scene rather than a texture, so
  this is the bullet to check first on a live 2.5.x client: the number should sit crisply on
  your face. If a client draws the model over everything regardless of level, the fix is not a
  bigger font — it is moving the number back out, and that is a version, not a setting.
- **The two outer arcs are flush, not spaced.** In the decoded string the threat band occupies
  radius 42.19–50 and the health band 35.44–42: they touch, with 0.19px between them. That is
  meant to read as one double band around the portrait.
- **The threat ring does not dim out of combat.** Health, energy and the portrait each carry a
  second Unit Characteristics trigger that fades them to 50% alpha out of combat; threat has
  only its Threat Situation trigger. In practice it is invisible out of combat anyway — the
  `threatvalue <= 0` guard takes it to alpha 0 — so the fade would have nothing to fade.
- **`threatpct` is scaled so 100 = pulling aggro**, not "100% of the tank's threat". The 70%
  orange is therefore an early warning, not a near-miss.

**v52 — the target cluster is deleted, and threat becomes your own outer ring.**

v52 is the first version of this pack that **removes** auras: 62 → **58**. Four go, one moves
out to a bigger radius, and nothing else changes — `stable=57 changed=0 retained=57 missing=4
parentSame=true` against v51, where `stable` equals the entire new child count (every surviving
aura kept both its name and its UID) and the four missing UIDs are exactly the four deletions
below. Every other aura — the buffs row, the alert flow, the combo pips, the cooldown row, the
procs, the whole PvP layer — decodes byte-identical to v51.

**What went, and why.**

| Removed | Why |
| --- | --- |
| `Rogue - Target Cluster` | the group that held the other three |
| `Rogue - Target Health Ring` | your target's health is already on the target frame **and** the nameplate — this was a third copy of it, all game |
| `Rogue - Target Portrait` | a live 3D model of the thing whose portrait is already in the target frame you clicked to select it |
| `Rogue - Target Ring Track` | an empty black hoop that v51 invented to keep a spare UID alive and to make the two clusters look symmetrical |

A HUD element earns its place by changing the next button press. A target health percentage
270px to the right of your character never did, and once it goes, the face and the symmetry
hoop have nothing left to be symmetrical *with*. The ring track is the clearest case: v51's own
notes say outright that it exists because a dropped UID would be orphaned — that is a
bookkeeping reason, not a reason a rogue needs it mid-fight.

**What moved instead of dying: threat.** It is the one thing the target cluster carried that
nothing in the game shows on its own, and a dps who pulls aggro dies, so deleting it would have
been a regression rather than a simplification. It is now the **outermost ring of your own
cluster**, which is also the more honest place for it: it is *your* threat. The trigger still
reads the target — threat is a relationship, and the unit names the table it is measured
against — but the arc is drawn on you, because the number is about you.

```
                47%     <- threat %, 10pt, +58 (above the new outer ring)
        .-----------------.
       /   .-----------.   \
      |   /   .-----.   \   |
      |  |   |  ( )  |   |  |     100px  YOUR THREAT      (green / 70% orange / aggro red)
      |  |   |   o   |   |  |      84px  your health      (unchanged)
      |   \   '-----'   /   |      62px  your energy      (unchanged, 35/40 marks intact)
       \   '-----------'   /       44px  live portrait    (unchanged)
        '-----------------'
                84%     <- health %, 13pt, -54
                71%     <- energy %, 10pt, -70
```

Health, energy and the portrait do not move by one pixel, and neither do the 35/40 energy pips
on the inner stroke. Only the threat percentage moves, from `+54` to `+58`, so it clears the new
outer radius of 50. The 80% flare resizes 84 → **100** with the ring, so it pulses *on* the
threat arc instead of orbiting a radius nothing occupies any more.

**Threat kept everything.** The Threat Situation trigger, both escalations on `foregroundColor`
(`barColor` is aurabar-only and `color` is texture-only; Conditions.lua drops an unknown
property *silently* — no error, no editor warning), the party/raid gate, the never-in-arena
gate, and the mandatory `threatvalue <= 0 → alpha 0` guard without which a ProgressTexture with
a zero total draws **full** and reports a complete circle of aggro at the exact moment you have
none. One trigger field is deliberately *not* modernised: the prototype's unit argument is
`threatUnit` on internalVersion 45 data and was renamed to `unit` at 51, and WeakAuras' Modernize
pass migrates anything below 51 forward — so this string emits the old name and lets the client
rename it.

Because those load gates travel with it, **the common case is still two arcs and a face**: solo
and in arenas the threat ring does not load at all, and nothing is drawn in its place. That was
the excuse for the target ring track in v51, and it is why the track is gone rather than reused.

**Positions are absolute, and the surviving cluster did not move.** Nothing anchors to the
screen directly — every ring hangs two groups deep under a top group carrying its own `y =
-140`, and the offsets add down the chain:

```
top (0, -140) + Resources (0, 56) + cluster (-270, 124) + ring (0, 0) = (-270, 40)
```

That chain was walked in the **decoded shipped string** for all five surviving cluster regions —
threat 100, health 84, energy 62, portrait 44 and the flare 100 — and every one lands on
`(-270, 40)` with a `(0, 0)` offset inside the group, i.e. they are genuinely concentric. The
Alerts column is the one neighbour on that side: it sits at `x = -150` with 40px icons, so it
spans `-170..-130` **at any stack depth**, while the 100px threat ring spans `-320..-220`.
Projected six prompts deep the stack climbs to `y = 226` and its lower rows do share the
cluster's rows — and it still clears the ring by **50px horizontally**, which is the margin that
matters for a column that only ever grows upward. The PvP column is at `+200`, on the other side
of the character entirely.

**After updating to v52 there is one group to delete by hand: `Rogue - Target Cluster`.**

WeakAuras never deletes an aura that an import does not mention — an import can only add and
update — so the four removed auras stay in your collection after the update, sitting in that
group. Delete it and its children (`Rogue - Target Health Ring`, `Rogue - Target Portrait`,
`Rogue - Target Ring Track`) once, and the pack is exactly what this README describes:
right-click `Rogue - Target Cluster` in `/wa` → Delete, and accept deleting the children with it.

**Check the group holds nothing you want to keep before you delete it.** The import moves the
threat ring and its flare into `Rogue - Player Cluster`, so in the normal case the leftover group
holds only the three dead regions — but re-parenting is part of the update dialog's *Arrangement*
category, so for this one update leave the dialog's categories at their defaults rather than
unchecking Arrangement. If you have dragged the pack around, expect to re-drag it afterwards;
that is the cost of a version that changes one region's size, parent and offset at once.

Nothing was invented to absorb the four freed UID slots, and that is the deliberate part: a HUD
that may never delete a region can only grow, and v51's target ring track is what "keep the slot
alive" looks like after a few versions. This step calls no `uid()` at all — it only removes and
re-homes — so the pack seed and the UID call order are untouched and no surviving aura's UID
shifted by one call.

You should see **58 auras** afterwards (plus whatever is left of the old target group until you
delete it). `Rogue - Threat Ring` and `Rogue - Threat Flash` keep both their names and their
UIDs, so they update in place rather than arriving as new auras.

**v51 — the globes go back to being rings, and your face is back in the middle.** Held up
against the older ring-and-portrait build, the rings won: two concentric arcs around a live
3D portrait read as *a unit* — you, and your target — where two filled discs read as two
gauges bolted to the screen. So both units are drawn as rings again, at the geometry every
pack in this repo now shares.

| | player cluster, `(-270, 40)` | target cluster, `(+270, 110)` |
|---|---|---|
| **outer ring, 84px** | your health, green → red under 30% | **threat**, green → orange at 70% → red on aggro |
| **inner ring, 62px** | your energy, yellow, with the 35/40 marks | the target's health, green → red under 20% |
| **portrait, 44px** | you | your target — a live 3D model, so it renders mobs and NPCs too |

**Two rings and a face, not three.** v48's target cluster nested threat *plus* health *plus*
power, and that third arc is what made the two sides look busy and uneven. The target power
ring is not rebuilt; its UID had somewhere better to go (below).

**The percentages moved back outside the rings.** That is the direct price of a face in the
middle, and it is worth naming: a `model` region cannot carry text at all — WeakAuras' SubText
`supports()` gate lists texture / progresstexture / icon / aurabar / empty, and `model` is not
on it. So each number rides its own ring and sits just outside the cluster: health 54px below
at 13pt, energy 70px below at 10pt, threat 54px above at 10pt. The same three slots on both
sides, so the two clusters line up rather than each finding its own spot.

**The 35/40 energy marks went back onto the circumference.** On a vessel a threshold was a
horizontal waterline; on a ring it is a point on the arc, so they are re-derived from the
inner ring's radius — `r = 62/2 × 0.94`, `x = r·sin(2πf)`, `y = r·cos(2πf)` — which puts the
35 mark at `(23.6, -17.1)` and the 40 mark at `(17.1, -23.6)`, both on the stroke, 11.5px
apart along the arc. Same dim + lit pair, same colours (red = Eviscerate at 35, purple =
Sinister Strike at 40), same conditions, same `sub.4` / `sub.5` indexes. They are square pips
again rather than lines, because a chord width on a ring would reach straight across the
middle and through the portrait.

**Threat kept everything it gained as a rim, on the property that exists.** It is a
progresstexture again, so its escalations move back from `color` to `foregroundColor` —
`color` belongs to `texture` regions and Conditions.lua skips unknown properties *without a
warning*, so getting this backwards is a silent no-op, not an error. The
`threatvalue <= 0 → alpha 0` guard is still there (without it the ring reads as full aggro at
zero threat), the party/raid gate is unchanged, and the 80% pulsing halo now pulses on the
84px ring.

**The specular highlight is gone.** It was a curved-glass effect for a filled vessel; on a
20px stroke it is a white blob in the middle of a hole.

**One region changed job, and it is where the spare UID went.** This is the only pack of the
seven that ever built a target power ring, so after the rebuild it had one UID more than a
two-rings-and-a-face cluster needs — and a dropped UID is not free: WeakAuras never removes an
aura an import does not mention, so it would sit orphaned on your screen forever. It became
`Rogue - Target Ring Track`: the outer ring's unfilled track, drawn unconditionally under the
threat ring. It earns the space, because the threat ring only loads in a party or raid, and
without it the target cluster solo would be one lonely inner ring next to your two.

**Nothing to delete after updating.** All ten UIDs in the two clusters — the two group UIDs
and the eight regions — carry straight across, so the re-import is a clean **Update** with no
leftovers and no new auras. Six of them move to a region with a different job:

| v50 | v51 |
|---|---|
| `Rogue - Life Globe` | `Rogue - Health Ring` |
| `Rogue - Life Globe Rim` | `Rogue - Player Portrait` (it *was* the portrait before v49) |
| `Rogue - Energy Globe` | `Rogue - Energy Ring` |
| `Rogue - Energy Globe Rim` | `Rogue - Target Ring Track` (it was the target power ring before v49) |
| `Rogue - Target Life Globe` | `Rogue - Target Health Ring` |
| `Rogue - Target Globe Rim` | `Rogue - Target Portrait` (it *was* the portrait before v49) |
| `Rogue - Threat Rim` | `Rogue - Threat Ring` |
| `Rogue - Threat Flash` | unchanged, re-arted and resized onto the 84px ring |

so a hand edit to one of those is what gets replaced. Every trigger, load gate, condition,
colour and spell id outside the two clusters is byte-identical to v50, and the player cluster
still fades to 50% out of combat, portrait included.

**v50 — the globes flank your character, and the glass catches light.** Two changes, both
shared verbatim by every class pack in this repo.

**They moved off the band.** v49 parked all three globes in a row at `y = -262`, and a
horizontal strip of widgets under the HUD reads as *another action bar* — your eye files it
with the screen furniture and stops going there. Diablo's globes were never a strip: they
**flank the character**, and that is what makes them feel like part of you rather than part
of the interface. So life and energy move up and out to either side of you, and your target's
globe moves onto the centreline above you.

| | Where it sits now | Size |
|---|---|---|
| **Life** | `x = -270`, `y = 40` — left of your character | 72px (rim 76) |
| **Energy** | `x = +270`, `y = 40` — right of your character | 72px (rim 76) |
| **Target** | `x = 0`, `y = 110` — above your character | 44px (rim 48) |

Those exact numbers are the tightest arrangement that collides with nothing else in the HUD.
`x = ±170` runs a 76px rim through the Alerts column at `x = -150` and the PvP column at
`x = +150`; `x = ±210` pushes the right-hand globe into the PvP layer at `(200, -44)`, whose
kick-lockout bar is 140 wide and so reaches `x = 270`. `190` is the band left in between.
Nothing else moved and nothing resized: same 72px vessels, same 44px target, same rims.

**The fill stopped being flat.** Each globe now carries a **specular highlight** — one soft
white ellipse, 46% × 34% of the globe, offset up and to the left by 17%/21% — which is what
the eye reads as *a curved glass surface catching the light*. Before it, the fill was a single
flat colour and the globe read as a sticker: a coloured disc printed on the screen rather than
liquid sitting in a vessel. The highlight is scaled from each globe's own width, so the 44px
target globe gets the same shine, not a shrunken copy of someone else's.

The highlight blends with **ADD**, and that is load-bearing rather than a taste call. Your
percentage sits *inside* the glass, and overlays draw over it: a 28% white sheet on the normal
blend mode would wash the number toward grey and cost exactly the readability that putting it
inside the vessel bought. ADD only ever brightens, so the text stays white and crisp. It is
also why this is a highlight and not the more obvious dark vignette around the rim — a
vignette has to darken, and it would dim the number.

**Nothing to delete after updating.** No aura is added, removed or retyped: the highlight is a
*subregion* of an existing globe, appended after everything already on it, so all 62 UIDs are
untouched and the re-import is a clean **Update**. Every trigger, load gate, condition, colour
and spell id in the pack is byte-identical to v49, and so is everything outside the globes.

**v49 — the orbs become Diablo globes.** The rings are gone. Your health and your energy
became two 72px **vessels that fill bottom-to-top like liquid**, with your target's health as
a smaller 44px globe — at the time all three sat on one band at `y = -262`, which is the part
v50 replaced.

| | Globe | What it shows |
|---|---|---|
| **Life** | left, 72px, D2 red | Your health. Brightens to a hot red under 30% — the tier below the Evasion prompt. |
| **Energy** | right, 72px, yellow | Your energy, with the **35 and 40 marks** still on it (below). The number is your actual energy, not a percentage, because 35 and 40 are absolute. |
| **Target** | above you, 44px, D2 red | Your target's health, red under 20%: stop building, spend what you have. It vanishes completely with no target. |

The unfilled part of each globe is a near-black disc rather than nothing, which is what sells
the container read — coloured liquid rising into a vessel, not a shape appearing out of the
void — and a brass rim is drawn on each globe's edge.

**The number is now inside the glass**, and that is the whole point. It is also why the
portrait had to go: a `model` region cannot carry a text sub-element at all, so the ring build
was forced to park every percentage *outside* its ring, where it competed with the world. A
globe is a `progresstexture`, which can carry text, so the health number sits dead centre at
13pt (10pt on the target) where your eye already is. **The trade is real: no portrait** — no
live face for you or your target any more. Diablo never had one, and nothing in a rogue's
rotation is decided by looking at a model.

**Threat moved onto the target globe's rim.** It has no vessel of its own, so it became the
colour of that glass: **green** while you are safe, **orange from 70%**, **red the moment you
have aggro**, with the percentage above the globe and the same pulsing red halo at 80% the
ring had. That costs no extra element and no extra screen space. Threat still only loads in a
party or raid and never in an arena, so solo the rim simply stays brass instead of vanishing.

**The 35/40 energy marks got simpler, not harder.** On a ring they needed trigonometry; on a
vessel a threshold is a horizontal line at a fixed height — `(35/100 − 0.5) × 72` puts the 35
mark 10.8px below centre — reaching exactly as far as the globe does there. Same dim + lit
pair as before (red = Eviscerate at 35, purple = Sinister Strike at 40): a permanent hairline
marking where the breakpoint is, plus a thicker bright line that appears the moment you can
afford the ability. They are now full waterlines across the energy globe rather than 5px squares on a ring, which is the most legible they have ever been.

**Nothing to delete after updating.** All ten UIDs in the two orb clusters — the two group
UIDs and the eight regions, both portraits included — are carried onto globe regions, so the
re-import is a clean **Update** with no orphans and no new auras: 62 auras before, 62 after.
Three of them move to a region with a different job — the two portraits become the life and
target rims, and the old target power ring becomes the energy globe's rim — so a hand edit to
one of those is what gets replaced. Everything outside the globes is byte-identical to v48,
combo pips included.

**v48 — the orbs are one shared size across every pack.** Purely geometry: every class pack
in this repo now draws its orbs at the same diameters, and the two clusters inside a pack
are finally the same size as each other. The outer ring is **104px on both sides** and the
portrait is **46px on both sides**; the target simply nests one more ring inside it. Before
this, the player orb ran 96 / 72 with a 28px face while the target ran 118 / 90 / 62 with the
same 28px face and a 132px halo — the left and right of one HUD were visibly different sizes,
and no two class packs agreed either.

| | player orb | target orb |
|---|---|---|
| outer ring 104 | health | threat |
| middle ring 78 | energy | health |
| inner ring 54 | — | power |
| portrait 46 | you | your target |

The ring art changes with it: **Ring_20px** replaces Ring_10px everywhere, because at these
diameters the 10px stroke read as a wire. The 80% threat halo is now the same 104px as the
threat ring, so it pulses *on* that ring instead of orbiting outside it. The percentages are
standardised too — health 14pt just under the outer ring, energy/power 11pt below that,
threat 11pt above — and the clusters sit at `x = ±260`. The 35/40 energy marks were
re-derived from the new ring radius, not left where the smaller ring had put them.

Nothing else moved: no trigger, load gate, condition, colour or spell id changed, no aura was
added or removed, and every UID is untouched, so this re-imports as a plain **Update**.

**v47 — the centre bar stack becomes two unit orbs.** The 172×14 health / energy / threat
bars that sat in the middle of the screen since v1 are gone. Your state is now a compact
cluster on the **left** of your character and the target's is the mirror of it on the
**right**, each a live 3D portrait with its readouts drawn as rings around it. The middle
of the screen is empty apart from the combo pip row, which is unchanged.

| Ring | Where | What it is |
|---|---|---|
| Health | player orb, outer | Your health, green. Turns red under 30% — the tier below the Evasion prompt. `%` below the orb. |
| Energy | player orb, middle | Your energy, yellow, with the **35 and 40 marks** still on it (below). Its number sits under the health number, in the shared power slot every pack uses (v47 shipped it as the larger of the two). |
| Health | target orb, middle | The target's health, green, red under 20%: stop building, spend what you have. |
| Power | target orb, inner | Whatever bar that unit really shows — blue mana, red rage, yellow energy, orange focus. It disappears entirely on a unit with no power pool, so trash mobs do not get a permanent empty circle. |
| Threat | target orb, outermost | Your threat on *that* target, 0–100% of the pull threshold. Green → orange at 70% → red when you have aggro, with the same pulsing red halo at 80% that used to flash over the bar. `%` above the orb. |

Both orbs **self-hide when there is nothing to show**: no target means the whole right-hand
cluster vanishes, with no condition and no load gate — the unit triggers simply produce no
state. The player orb still fades to 50% out of combat, portrait included.

**The 35/40 energy marks survived.** They could not come across as-is: WeakAuras' bar-tick
sub-region is aurabar-only, by an explicit `supports()` gate in its source. They are rebuilt
as marks *on* the energy ring — a permanent dim mark showing where the breakpoint is
(red = Eviscerate at 35, purple = Sinister Strike at 40, the same two colours as before),
plus a larger bright mark that appears the moment you can actually afford the ability. That
is the same dark-line / lit-line pair the bar had, and they now sit 11.5px apart along the
arc (10.6px as v47 shipped them, before v48 widened the ring to 78px), *more* room than the
8.6px they had on the 172px bar. What changed is their
shape: square marks rather than vertical lines, because rotating art inside a ring
sub-region needs directional source art that WeakAuras does not bundle.

**Nothing to delete after updating.** This is deliberate and it is the one thing that makes
this migration safe: WeakAuras matches auras across imports by UID and never removes an
aura an import does not mention, so a rebuild that simply dropped the nine old bar-stack
auras would leave nine orphans sitting in the middle of your screen forever. Instead every
one of those nine UIDs is carried forward onto an orb region, so the re-import is a clean
**Update** with no leftovers and only one genuinely new aura (`Rogue - Target Portrait`).
Four of the carried UIDs move to a region with a different job — the old `Rogue - Bars`
group becomes `Rogue - Player Orb`, `Rogue - SS Line` becomes `Rogue - Target Orb`, and the
two lit threshold lines become the target health and target power rings — so if you had
renamed or recoloured one of those by hand, that edit is what gets replaced.

**Two honest changes in behaviour, not just in shape:**

- **The threat ring no longer loads solo, or in an arena.** Every other pack has gated its
  threat display to party/raid-and-not-arena for several versions; the rogue pack's missing
  gate has been flagged in this README since v3 as "a one-line addition whenever the pack
  next moves". This is that move. Solo you are always the aggro target, so the old bar sat
  pinned red on every quest mob, and an arena team has no threat table at all.
- **The target power ring is new.** It is the only element here that did not exist as a bar.
  A rogue's kit is built on denying casts and resources — Kick's 5-second lockout already
  has its own bar in the PvP column — and an arena healer's mana is the match clock. In PvE
  it will show a near-full blue ring on any boss that uses mana; that is the cost of it, and
  it is why it carries no number.

Ring arcs read differently from bars: a 172px bar showed a 3% change as 5px of length, and a
ring shows it as a few degrees. The numbers under each orb are what you read for precision;
the rings are what you read for *state*. The one number in the build script that may want an
in-game tuning pass is the radius the 35/40 marks sit at (`TICK_RADIUS` in `patch-v48.lua`,
0.94 of the ring's outer radius), since it depends on the stroke weight of WeakAuras' bundled
`Ring_20px.tga`.

**v46 — earned combo points pop into place.** The five dark sockets stay visible exactly
as before, but each earned pip is now a separate lit overlay that appears at 1.85× scale,
flashes brighter, and settles over 0.3 seconds when that point is gained. Two-point gains
pop both new pips together. Spending points removes only the lit overlays, immediately
revealing the same dark sockets underneath. The five existing combo-point UIDs stay with
the lit overlays; five new, append-only UIDs provide the backgrounds, so Update continuity
is preserved.

**v45 — the cooldown row shows what you CANNOT press.** All 16 cooldown icons now appear
*only while their cooldown is running*, carrying the swipe and countdown, and vanish the
moment the ability is back — the pattern v42 introduced for Stealth, applied to the whole
row. Because the row is a dynamic group the gap closes, so **absence is the readout**: an
empty row means everything is up, and two icons means exactly two things are down and both
are counting back. Previously all 16 sat on screen permanently and merely dimmed, so the row
was busiest precisely when you had the fewest options. The desaturate went with the change —
under the new rule every visible icon is on cooldown by definition, so greying them all would
just make the abilities harder to tell apart.

This is safe for the rogue specifically because no rogue cooldown is a press-on-cooldown
rotational button: all 16 are situational, and none carries a ready-glow (a hidden icon could
never fire one). Packs that DO have such buttons — paladin Judgement and Crusader Strike,
druid Mangle, priest Mind Blast — keep those on always-visible so their glow still announces
the moment.

**v44 — the PvP layer (ten new auras, nothing else touched).** A second HUD that exists
only inside an arena or a battleground. **Nothing changes in PvE:** every one of the ten
carries its own Instance Size Type load gate, so in a raid, a dungeon or the open world
the pack is byte-for-byte the v43 HUD — same elements, same positions, same behaviour.
The 46 existing auras keep their UIDs, so re-importing offers **Update**.

Three prompts join the existing alert flow (left of the character):

| Element | The decision it changes |
|---|---|
| `Rogue - CC ON ME` | Which break works *right now*. Colour is the category, `%p` is the countdown: red = stun/charm (physical — Cloak does nothing, trinket or eat it), purple = fear, blue = root, green = disorient, yellow = silence or school lockout, orange = disarm (no rotation exists — reset instead). Catches school lockouts too, which no aura trigger can ever see. |
| `Rogue - KICK NOW` | Target is casting **and** Kick is genuinely usable — cooldown, energy and range folded into one boolean, so it never asks for a Kick you cannot press. It does not exist while Kick is down. Desaturates out of melee range. |
| `Rogue - TARGET IMMUNE` | Do not open, do not dump. Divine Shield, Divine Protection, Blessing of Protection (physical immunity — a rogue does *literally nothing* through it), Ice Block, Bestial Wrath / The Beast Within (uncontrollable, so Blind and Kidney Shot are wasted energy too). |

A new `Rogue - PvP` column (right of the character) holds the state read-outs:

| Element | The decision it changes |
|---|---|
| `Rogue - Trinket DOWN` | Spend or hold. Visible **only while on cooldown** — absence means ready. Tracked by exact item id (both Medallions, both rogue Insignias), never by equipment slot, so a PvE on-use trinket in the other slot can never fake "medallion down". |
| `Rogue - Will of the Forsaken DOWN` | Undead only. On 2.4.3 it does *not* share the medallion cooldown, so it is a real second charge and changes whether the first gets spent. |
| `Rogue - Enemy Trinket` | Their 2-minute countdown, one row per arena opponent — the window the real Blind → Sap → kill chain goes into. Arena only. |
| `Rogue - KICK LOCKOUT` | The 5 seconds your Kick just bought: Cold Blood / Adrenaline Rush now, and stop spending Blind on a healer who cannot cast anyway. |
| `Rogue - My CC OUT` | Your own Blind, Sap or Gouge on each arena opponent, with the remaining time. Do not break it — and this is exactly how long the team has. Arena only. |
| `Rogue - Wound Poison` | Stacks and remaining on your current target. Five stacks is −50% healing and it decays silently between swaps; glows in the last 3 seconds — Shiv it back up or get back on the target. |

**`Rogue - My CC OUT` is not diminishing-returns tracking.** It is the remaining duration of
your own CC and nothing else. TBC WeakAuras has no DR prototype and no bundled DR library,
so DR cannot be expressed without custom code — and a hand-rolled timer models the *reset*
window rather than the category state, which is wrong the moment two spells share a
category. A partial DR tracker is worse than none, because it gets trusted.

Also deliberately absent: Cloak of Shadows and Vanish availability, because the v43
cooldown row already shows both as always-on icons that desaturate with a swipe while
down — the same information twice is how a HUD teaches you to stop reading it. Enemy
cooldowns, enemy spec, and "only show casts I can interrupt" are impossible on 2.5.x;
the reasons are in `../../tools/tbc-weakaura-creator/references/pvp.md`.

**Live acceptance note:** `CC ON ME` uses WeakAuras' source-verified Crowd Controlled
prototype, but addon source cannot prove that the 2.5.x client populates the underlying
loss-of-control API. Get sapped and school-locked in a duel once before relying on it; the
repo suite verifies its schema and gates, not live client events.

**v43 — readable combo pips.** All five pips are now always on screen: unearned ones sit
as dark empty sockets and light up green→orange left to right as you build points, so the
row reads like a filled bar instead of floating dots you have to count. They are also
taller (8px → 14px) to match the resource bars. Previously an unlit pip had no state at
all, so nothing was drawn in its place.

**v42 — re-stealth timer.** `Rogue CD - Stealth` answers one question: *I just broke
stealth, when can I re-stealth?* It is deliberately not a permanent icon — Stealth cannot
be cast in combat and out of combat it is nearly always ready, so a persistent icon would
be a passive readout almost all of the time. It loads only **out of combat** and only
**while the 10s cooldown is running** (`showOnCooldown`), then disappears; the dynamic
group closes the gap, so it costs no space the rest of the time. Absence of the icon means
stealth is available.

`generate.lua` is now a reproducible lineage build: it starts from the committed v41 snapshot
embedded in the script, then replays `patch-v42.lua` through `patch-v54.lua` in order. Every
step decodes, edits and re-encodes through the shared toolkit, and the final build asserts
historical UID continuity before writing. It also carries a **post-build canon**: a block of
assertions that decode the finished string and hard-code what the pack's central instrument
*is*. Through v53 that was the ring canon (`orientation == "CLOCKWISE"`, `width == height`,
`Ring_20px` art, the annulus radii); v54 **rewrites** it to the rail canon — linear orientation,
100px length, `Square_White` art, per-lane heights and offsets, exact subregion counts, the
alarm rim first and 3px oversized with the plate second, `c` depth-first, the anchor mode of
every region the scan boxes, and the six-deep rectangle scan of the full envelope — rather than
deleting it. Those assertions are the reason a geometry change in this pack has never silently
shipped wrong. v52's `WA-REMOVED (v52)` licence for the four deleted target-cluster ids
**expired with the bump to v53**, which is how that allowance is designed to work — it is scoped
to the one version that spends it. v53 and v54 remove nothing, so the strict default is back in
force: no UID may disappear, and none did. Re-importing therefore offers **Update**.

**Closed in v47 — the threat display used to load in an arena.** Every other pack gates its
threat readout to "in a party or raid, and everywhere except an arena", because an arena has
no threat table. The rogue pair carried no such gate through v46; it was largely self-hiding
(the trigger produces no state without a hostile target you are on the threat table of), so
in practice it stayed blank rather than lying. The threat ring and its 80% halo now carry
the same gate as every other pack.

Keybind labels currently baked: Sprint=G, Vanish=Z, Gouge=E, Distract=B5.

## Import string (v55)

```
!WA:2!T3xF0XX119PbGmICLOfjejLfT(yjPfdPkf8(jwaklxV7Ifeli(y5SlajHOmMz3DwmdWU7mCMzXhmXoXisk0IwUkWmkoTj9eJ)ONgxF65u8hQTPPP2SPoXFKQxqtKh5y72Y44gFC7PnSPPXP119EFVz2D2VabbbyKou6imC238EVzEV7V7V39DF35nCt0vUFJ(UYtUwwXCZMxxvlUArv9H6SZot1PVUdR1vo1YM6QflkLpUSsX86sLNu7G8QtxrY7Z4nDrLCsEflN3B)Wj30jz(kAMv0L0oGtc9ljMV4IEtPQyOwUwYdOaL8CsIZwwYWqRlNKhuQKQUUS40s3iRQEEj9y2pBA7nwrLlFzr98EZOQw0urtFHXkuWqYKBnXkMYQ6JPzQOw2WtwwbL1xKD9hKBvXY5GmapcLnZgpXOzsWVcltPvUS0oJvuvm)aznflkv28G8LQa1UNygAs5oi5H9WNROOHbEwmdi34jRYkmR7IJJRt7Alr(PL02x6lvruxY7avkw075KvmL4nYbvDN6I5OpG9WBykQB6jMszftpzla)JHSNLm1vMEAjDJdDmD7tF5yvGCKvRO4Iq)G5IAs8Iv0fdSe8OvSyY8gEUHrLSsZbp1PRuOGYcRov8OPZmv6mr5Zu9sP0LGlXNovIHhEL8szHCMbQk9btmCQbgFyEAMYoOKyrtz(YILKm8SCLY2pcEwwSSsjr85UhYJna5OXkRww66sIgsPnb8W0MY3)A5HhkmhtHpI6gsaSjVXsyEWBeXFSsIkLHYs8tcC)KGKqKWWPprJPCtq6iPxwS4eqLav3ZVIPAU5yNVRuhyzdPIfOIqYdDeL8R5GyIbniJavuYVQMK259N)S57pyWvlOdTe4ru0uSZBYe)dGjHprzthNprIrZQbIPYMoqYmXId1wuqOLgK8g2Y4KLbeuNzHMubLP9Sc0PYlnnfMDDwgyySDVc2OvyaWvvkxqvN1R5zfDA(X7l)06Qv0UYrxrbYCA1k65KES7J8aEi7HJ8(ip0A5aCDE15lNEEfnjHR78tevjhdlJa5jh9yeV)JGoUp41rOafiOK34PJf2Fe)X6jsKqKtsEgYHjhH8uEihNCIBwXqkXcaYlndZiq62d5yKFAYtt(7q(qEwnVIXmvkdaZ5KciwSO2(ePNNHj(hrnV0x8(irE(BoRKKwuuLWKhBxYK(ipeGMmenrHVKmP)t9wRnDr15hqx6svKkNBXu7Wx3bctoQo0NHx46WtYPH)LQ1iVeMe2PSw2kMMQLhde0aoFfm5HP4QdSkE(fS1XxEANII8tDsV25DFT0uDm6JqgzLCuALoJH)uME9HvGu2hT(JX4hUYdR1LP0cMtzilM3vTrtdpCKNcyDCLJA673GLQdGmw0XZmM2dtte4IurrFUZPK3uowu4N3KEbqjukpnXp5AmaPtB760RptfdtLclcDR6QMqxAgiXyJo2OjyDHyEwHMXCv7fypQfawAT9oGUYL9E2kI5riV3mzQRT5CNwJM28q7)C6IAlDo7twRA9qzggB8mdNC0e2TDxCNxp5OJMGFQyJLjZyJuRqij6JB3MoFDTP5umuYwusOGT20uidANKJUm0GyPyRfz3OO9T2P4uwNIkbQbKhDn7FPYUnzLLuMw28SK9nXYa(AkkxTaPlKLMSF6XdCSSgkLNUOep)yNE8eKh(GKRiqoi9AdsgrB)o6zyhE)kgIWnnVWsoPkWlwutwStINtUJyxwvTeo2yq(AcbsVa5eqir6K4JYrcmAiXMdpxpnLYt0ukpxNKpc5Vl5JsofjUhDLYiRhOt9SRo)K58xmzKlxi288ZJyNZsg4qhJpNSuUzhG4TZLMtuxbFIVH0cAkmA4mkLK4NtSyfPUcFevTJ8HFo9CYILNwcgAHCnHL0GrtL0nxejZ62F3Ogb50EiFa4H3d5X9qEcpx5OKHCZmroJazyzYi28pVbY)qoRGo09mw5IlkW4CGbq1NwYejEqcgG8b5Ag9YX83xOGX6TNG9bhc5J3V)arcspgIEmmFGE6TNiKNwFWO8Jadjb8seEsAsgk1dzCkzdzckhd5Co8kKZtUGmzsYZtU4biVah5JXKgtXre6KaYRSYKC7JKhuZjsCKcGYmzAkaJituiZqMLu8tskXrkd1TkrdQWlrSLOgetsfoYCK5jlqwKCzYpd5N9XjFCoYNqOa5NdWVKFEYNKvxljq(fipk5f5iVeccjVCJGpYVi5knI5iFkbYRiqUkaQkYr(0uef5vRhnTJTi0e5ZG4OzfVaVcyNLXmdsEnad5zZjXjFoBzn5xTzXCGE93lEOpqQgmCq6Xq8bchmuFGeUVE6Lpqe)9cYzYNV9s4HUtKWgBEj8dr(zpmtcVfHxEKTh8YZ0g4Yo3sHlJLptOrMlu)vuV0MbUqnqHm6K8b9hiyi6XW0J9qpgHES3gSubHx1zBY9mCaVuBKP)uBPY0fYhVNt4xemWn2DGmDiE)9e2VFE)rcgkc9yVu67qU5fAuA(E67B5yJ7FlfBC8aN5sktoKXCfNV1ydFllQNJzx(lEqshxw7HR6gGY97DKKPtNC0txZhakAQgMsvNI2asGXJ18CqI5eX505nLUAjnW0vN0Jh37yJ6DKe1s5mjJFgVJo25Q52ayQTNorgVjhzKXblJ3fz3WqO7MSNV8stRRKhTE9i89VsbyQ3Xv0ZbwpYBOjMtApUBmKNeSdY7ltPEqmTRbYqIhehdixyUrGnEvkvonwbDIW2(YYS8fSiuzAawOdZJhNLehPFpK9nq9cw6rMeLRQlv0zZMwsyjWy1HvkPyktouNlbgszFxEqzY7hGldE98lctfxjhDgJK9UZygQ6MGS7rOOk(IyrFaulngKJ5pY4PUbm9q4XPS5aWe4u1ZYhT)KJNgeT6NyMHKdnJH2Ibjj29s05waD(CoiPB40ZgTiyuOXYy)iDwkpqnGsusSorSYd4jRUyELkgV4dAJryGWgMzFp3656FLpizioOMjRV9gRbDwGTUgPLvNFSYRzq)Nradzad6Dp8HBdrEAYyKuR)qipDdKocKj5tbtpRynIh8Y(dZo6McsGrbT(Q5fQQMVcDsjQLYkAkS(Q8UbOVImoVC0VpjbXQ2pDs0XifaaYfXFBCrXSkfvmxCkDu0nLb6iU8WFuPLNQguIYMcKJMvtxcMQejSo6rMXQysE7vHIKxkRkmX7sOezjhp4ealhiLAbnYv2BwQBSweR8qRzcqzJI40ubDoT9za)gNiwgNKxMMz6e8DUgDg6qL9TGNPCWKDz3BYv5yv8c0kURfZV7UwGJozoAYcltN)fwtl5utKVDxiyAnmtvFqeOLHMzHQ0K)ZbnGC57BXEJMP4zL0qkvGFZMlLX(bd4baDgC(tjSoaZ)PaW81H5UYeNfvNMCm9PqQVe9dpqHjNCL40R4Dy4shNp95akXLYlzyoEzftYrq)Fmvja7Infb6VCUOWsoPZNkkp)faKl7Er(Ha0()kR2j)3Oq8)7aI))Ha5VqGCtY)twgVY(4HEHCZgd99G2(WAEAPYs6k5y6ncRv3pxLPgXljMFrqJzzQtKgvSK0UI8pHCuE6pPAuNu7rJBplyKREAahz494uhjDcThgVnsONLMQAfiSgGXkM25N6oJdqfMvZeQWIQNyRb0Fx2wkMBwbTUWZbUvvDjvyoWaveKDQA8FQwxmmJTNPG(yLCADxG67k1Yh38eE1LmROx27XnFE)VGxvDVMpFGx4euhuB(8bFbVsLZVbSMeOci)X1td0Baez6VfSa3nnRCoGt5gv7iNTm6Ac7rCQJrHsYSsTmHc12WYiq(MANODClZlcD)Q6tLtwSyr07bTMDH82un63M8NqvM)2KVtB5piFxQgo5)i5)e5)m5gmMaYFQnja575w)N8Njq((K)l2k6K)CbYpOMs9)cqPUu0ro9qJFC)do6c3rk1Fmq)5Rapghgr8mcfzaeBQLdiSpP2EZq)L30kMvOmKGcZnQLlQY7YvlXrI4da3ADvnHPqpTicJhFKpYZH49vQvmWsz2yuufyYFj5)f5VsG8)M8xJdI9J(ExgEM(ByAHK)pK)VcKFmp1kkYpPr9hlU7tWIJt42A4UgX4Hc3om(TgvAXTJ2JeT42j0wwha4rx)b3kqB0VJb69VeGENrE8fImu5J3VXKBHqpaOKtQSPmDDyosyFvnVbfZpLh0GXPWLdcNwfJJVUsiODW6(DvKxxF41dNTR9)R3eqt32(8TEOgv8HhI05Tns7LDqAmROAbE7TGRVtSb1oJQa0wtMsrjkT9sU9)amF5FNdI73cqCZ4RGsrJiNVxXf3aio284Hh(6qCSUING2BqTX(yi9wCy2d59gV668sHJnjDRV5Jnb4XeB9ypb08XuSTV3P5JTfSDZAOvB(29kxfBZoTESPJ1a2vvT5VbhBUot0bGedrXgC(aB4bNTxRK6xbdxJyx31DwlL6gdhgsV2W4aIfqY1JIrCTZudO6Y4kHi3wAtkg(yb0MttGhxLsWKwepd0gamgGa2Y)pLacbCGk)RCGRphfJGKop7Q8tNAUu5YbtBscXkiUgWld8Tog5xcxabYYRAVk)01Q9AXsNz8rXvn45EoYVmUEbn2p)63S2YgqxqSQvKf3tsU2Ay5NAKeXhm6OjJVUvKf3HRVS8XXfa42Rm6PgdmapD6BVsfBGer5RRiuwjAVxNTQaRHfO1nRBrj1Jp2OdmE6envMq4JxF0XDB9Zi)yJLPPsvL(Sf3P0jhoXOXt0CxrV07sGwvOSPIgp5ax42QmRXkZM52PT30XhCSXgEQKyqyWpEQm3EpT9NmDlHiHOcBF2DKirimIuBg7ToMWYat4awCDjqz(ozS4IgMu3yshW8nQn44ArPt0W740fiehOS(Hh72dDKXFu(Y1k6HPgukdZbIAsJG9SQ2pA)N34YIyeHaZldUCodx(oL(4atmRAb1zNj1AVA8ox25QsY7eYzlUh1nxSf3HAM69r3iuVowqyX9bKBRtybtiajiL91I7XGF(4UzE)MApwJgqe12C1ZOKBwxmZ2mXODro0Z)2oSXZczD05DCVgmqD1HXFn6Y7sH87KS81zX5tzE60VUgNByVa51jtSXhW)Jz7pHpiz0VqGEcfiMFFb8fiuF9glC4ibXFfaoRV(4HZI0lFOWHc2lV)(chjeFWqHI4Vbp7J44U9uZWsky3IZNnc3IZFZWzlUawCbF3geERXaJncgEdB(Gl8B7mCOfq32z0W)62A0GsPsvkxNrdECiwFsx(0M0XHQTAaPOXQgmD5IfzoNNdl4dkt2ZLOqZ9UZ1Zr5mVBt9a(H6CZ4Y(nT)OrCi2JGToOxrBFvxkdjdAGAza9kHNOp9SxWN)a5d3SVX73djXUT7IgKKK2fbTggCSJ)MADrrlkQxYlny0Qf2Jyhg25zkvlJ2UEGxuPyTezXPxdjMOSK(0lYsS6QSGoJu1BA1CZkz61FTvqHLonEEGKBD2d06ShOnzpyRZEW2K9qTo7HAt2d36ShMcWaCc0B7SUj2qStJqjk4S(d9I4Xepq9uJmKfaFAdWcXCFiM(cIsI7ztVYBaWYIlgIxCqpwCXbCv54gzZNIV3tmWI0bm63JT2gOQCWMuvykp75lYDfVKb1XjMurx6M2)lgnxyq7PT)4dhDKuzgl2WrJFMO93FYmjNiHZyGFa5vPoATmD5LAVZB0TZbsPqsketxujpBnlMJxtuhSObjAwQGkCAjXYcbmLklSI58sLnxSGYCsczzNlq8lKLfvB0H5aIiQ7MyhOgkKTKIUUQUSZyy0PO(woEhXIBxWTApWqk44iEGZFGJ0l6RnlUheDTgoydkZGrE2DdJWSmyTw58yFsaOBG2)(SRoFgXE65elu(cdNI8MCUzAS4gxlATX4JMp)yWG8yCkhfJ3YloIuEfXlMH1BBCrwS(ofnmFNIfxHDBoTi51EBeRC1oBdHKZyD(RowhmA2BVcDXlsvPOHuZmuuWtceaZapA7lVIroDj4(wBn9S51Xb3EPZztgbGSyaub)hNo36ywDmn4W2obYzr1Sh2UQUq11K4WUhKV1509W7BAkzOr8MCwCtZrEPZyXjiVXw(8xLY6sNsGf3ewCNdaCwCIYKbbrRfxw(yWSw6hWaND8ZoxS4lmC0fJqVIKJwP9iJwCdqD2YFa2RcD7UmmBjLYSL6X2ISRXXmkJnE4RtUQZ4KNklONPp1ICS)fSfbfdRkMhd2tP8JiUqh1(Hs5oi7j1o8hU7W3euPKqvVY5zbDkZkfkhgBQMA7VwW3IHiplZYRAGX4mdDk4opduTcLRfph26w10Rq(V1rxAjqtkkgkLV4bbj7n0SxtiwOm)0p291b2O1nkkc6p5L30s(S50v1MAbQq0pGb4P1id62)tFL3p1SRR)uv9Y(t9u2gGPDYQXU7uSiWUM38NkVuoLsIfNsthoXGQU42ETko2RPD41PsyjKD0kLYkP7YYo8znsa7z0JNhYXqVk1f0jFczQTEhaS1t7PwN7dvsrJNE(cfvv1VYdVMnd)i28KEg8Jg8Nq)pk6EpCRGHJ8uASaK3z8aEhQHByNWeorvlZzwtvcig5zf6ORyhMX4RVX(SpP)AH4TtvydV0o1MJMKXpUtw0fdxnMd)Sfhgmex3o5AVlk0XhUU9ZRD7d5dwZDBegy5L2n()GMA1r5S4oVW6mtVlypUMf3K2JQzX98cmBNVi83la)9XG)Mch)cymMmw)PhEIE7Be)P12lOqh1wZLQilRTVSv1dTB4wC)IU5A12xn1Ax541(QaZdkeBSsvkdSw30rlZU1EdJsQQMYoRhl84Lf64wMQIG9IztoA6K9NyPCQLWf(3qEf6Lgqr3WuEvvwy2NROIM8nR98wnY2Xo7WHPuMi35s253WtnwXttFZdQcSqosG1KPZUOTolDcTRqFnxO8fCRQQRawcqlIwxdogFYjhB0mrr)anrc(0jidCkxE65bix7ir8HKRFKAE5bO96XErQEDlo1QzNxCAOrqUwNn5RS(OtDla7ydLAvMUgnmPjxRlFSaLMvyoBkCT9wRhY2PVx5uwCZcdkvKXKBXvQdloK3(Hq2jlonaZDjqMakOBRdSAXzq5GT4mD4DT4QixVLmZvLbDttfdDzdvBAW9s7ld0BNK(hYMgwBVpvDR7uvU41DYWrTNmS2jAIdS(vXQgpOf3hxZ3Ti3ntXtNPnUM71rclqjHFeYhpAliHRVkzjAX9ZCLh2IdyV98RXzZ3AX9ZHD6)8WjFsqIVKf3Va5OwCVOf3lbGGxMQzdQ1xHrRzX9PCiZ83Rf3RWOWS4UkWB9io192yvhCRVQX)hFK)hydZE2vJxQVIkroFFJopiUEviFFgS(2iMTzX9RXvJi0I71O2R9lzXTSnbNf3N1I7AwC)YWzVo83Vc83NRfmwwC)QU4QG64VVddLf382EAZI7Vh8CzX9RBX9pSkXZorINzANbDUiN2hKNU(WadvqFBqUMLlbdpWwxxgldW3uptJf3NV9ulx8(An3YBuJYGpL68G9iy00OHNHkm3VdbcZ70uxrx9IcV7G5H2X6y0l0T2)RC750nkptvXtOWTY7Bu(akzaWkyRUCOoVnux2jtDHQR42LHmKjvRbuvQQ44zWVu33h(F3P3mS(7jmB6aT)EDuMrIR39sUn3RD3MgwNBY20g4(4Un15TU58ESXRdBCbFtmZato68Nn08VZGno5gGnEOBl2yEkHMTHIaJC4QloI2(XLPou31pThx04FXQLkKVgkv42vQLaI8Q3rkpU)wWJ7LXjs99WgR3wqM8QmZSc66ypSz(q88P7Gbxo)o8hc6aqhzqMqMjj28VgaOx(JRH(y1Np)u3SuVBWqpI8Ah22nwvLHdrNfUTNsEtQiSXbJS4(hZcwOFZD7SKrDthqXI7lCRg3XvUB0vsuhy9s7XTFywhic6bMhWJTFVSfgqs1x4gwtTAf(vhInGdZTlD2AracYbrqo7(kONOQReDTQBFFNM5nOih3re4YvhswWvV2xSl)B6UoNHTBORdLvGC85CjhpdvoI(36Wuzpy82WMdF5idK4eXRqbvFf66PHRR23n1o8JaXRIDhGo233IRafg99SVaUoC)zcoRz3pqyJ6EVxApn5xV2SIwm3PTLRznm32TMvGnSM1W3ROzrhIOMRYW1wTLcIBt9llU)zGoLf3Q1Rmf4UGY0inPmLF0rJAQm4erYmZ9mktB76sb3W6sJEp0Ou9vlsB83zlLcBnksbVlOinwtksdQM(sLsEEFHlF57zuKoX2TIuOnSIuQ7ruK60EINyqe2BNTueS1Off6UGw0zBslQ0KtkBOlpXiZo)9mArND7wlk8gwlI)EjTOAHIBRebBnArHVlOfLUjTi1HtTW0lA4lPV8VtvlYh5nW3p)dPTFNqM6CsIAS31(CgSqY77q2JFYVZr47N8VrG8L29Mko7(YSxi(ydNyGmK)Tq)0V7g)LGN8VtG8vq)zr(9Q9cVt(9Xa36Rw9vCN81OVE7KVopFYtpygY3G8hasaPrYmUXzZC(CZCCmA7EZQVf7v3QbyTZ)Ww(YRtw7o)9w)wSp5Sc(U1gVOAzjdbw42Ek(a(85lcFGE91xq(qb6lspBrB8j3IaUEB5vv9rVLVQQr3m7YfTztqYI73Ubfn7xFkQ(fOp9Dt1P)Ud7ehW4POgwaeKX0XAKqVXAQRf56AH)cAKbtFdScGbjy1yeUwy69LQUvzio30rKLgQ)zcxK8ArBXwLXhIPc(BSxTdXaLX7hJ6tC3ZuSOszjV8vmK1EexxlwrX8sEhOyfD9fDI1r6fIRwmpCvv181LCA6RPMHPKMtetstoLUKMi794x79xF6LKYR4S47UUI9l6Nt0UstBcrC7Ou7d4(XOOQ4SEvl4CJVPRRHH9EDLpTMoUzFSxxjDA1ktlvxkXGoI81LcBlc5HDLs)k4R7FoZ6EItBsxhnNylEpNChuTq3ez1fwNBqISnDmQzt9Tb59WaAd59a2V659aYoKBYM6ZMZcP8ItJQ4FVQAe1cmzN3mF3KDus9NDv5tO27jsPmR00zjF9vQfSfiTfYWwloU)Gu2maFB1A(mxVWO3GTRb4CBzV9OHFJME7rVzdi9n0BrkUnzyVRUkSEVoPBKDhO1NBAJ8clJnRASua8ayP20wmw)lsQ7XARsY97J74wlmB8EIF(ct6BgQnhrxNxXt5Bh5Mf3Fctw1t4MKvx3nZZgsqzX9DENGacAl3nfqFvqaDUstpByD)h)09232KakIytcOvQncW7Mepql5UP45RbINjc33I5KJpJsHtVnjE(mFTMfp1gj(DtIhOLC3u881bXJzYytyo4qk8Mv2U0EuAs8SQllIExL6JYDv5Z3aKpNpHAoZYdPv0y7A4Nit3K8zT6Sm9DvsOPVRkHWP(QWx8skZDzv)Pp32KeQfBfiwCh4DiILn6Ck3(fg)7bHXLIlD(tukUXGQBtcJDy2KSilBMzBk5XDWEMAxtUPDyWASTl8mJLI6Mi6B9WwMZd2(f0VjA1NUuF(QmJC)6xyBsRBX)6MK0A7TXzC)EkHniBWxs5ujJC8iZm5yHLK2EKn5l3KOjg918)9Kg1ln(dbPrFbYpR588dkhFBstX83QzkrMZMURtjE6nnLOf3p8DD8GRH6Ad17S6zcmJ5OZUnnGNAZB4Du)gExx4M4EkH7)bmqH5NES05oZcPNDXThH73BPMfUuxa)EmPnio(JW5Iv6C9NAW8JoCMTjDTwS5sAX9(EpzrdYI)yqwKmuSln(WNzUZLk72JS4pA2MKfl5SYh3TP(osSW3tX99wGaoGEMqbkCgX(NV0gwa34oTuBeV4Ap9JEXMhxt3zrSAEde72C71eeKnjCbbUavY6SnfvGkkGo)6LgGicLgfAuA8wYTD5ALVtw5CSFe6nRtEWwQUQYJVj2PF1QR5QfiEsBguCyt545dfafh2Yg26U(kci2)k(iF9y9p25gL0Xm1I6HmGDH4EhdEbTdxnwiWDzhywvMYsEhqv3qCwPYSSCaxBLoLw0P41Qp6hIGHhl(zgB8m1wdUrwK(nlasQw4wGVWQ2FSdPRsjgQaF5AHBXEAEJ40EF56qD5RHGcOUDzRQic2kw(vKDh2fngEf9faM09gmclWvRgxQXyDwFivSA1qQyUuneqf2Bqu09gMq0ThJx8bBk4kU91z3iBKzFcwytftXuQeTd6Vc3MMF)TyFkpjKd6xeawhkDdxhlfBpih1qxY5N76Z(Nx3EzMvh)uvRBRoU)AvIvh7IvuRo29U(S)GnrHs(BUzk0NVkiiGy5fByJtRPThTwSHP1uktiuhBcWxWioACGcKMbysqAgB2K2U9KfDZV9Kj4E7jt212tMf3p29(twuGxOJD4G)mrTu)TCdkBdUh42aJnQ39J21t8rDtztjK)XA7VvChUyW72JZ4ZihFl3G7EhKCAJUviI9f32sS)FTxInVQzHqHUtKyZbTHtQB)bq9q8HceOVaym9TA1TgF8BC53oG)a(WDAt63IaV4M6P30vYLtc3xnWDQWhFRuej)3EQshCJku(jTxOir1JAPqX3kgAI6Zs)EWCaBJBHcA)9kLETQBeiA7RUFJ7fjefNxluCtRT2OD)qRoEFtgZFKE6bpebp0lEOp(G9cNso2k12FyD)XVWQJ9A)nqGUJdr399xP25SnQnNqkb)GP66BLjnEfjp0szfT)U9wFaZnH81Pp(S95JladREQdso6Q4wDcuIPG)2Q2UhxL5vCwyn6AZlDoao481TKTz3eaURTbG8OB(TZ0BqBNU21DYHVDWBEdThbbAS3ryD7Ulee5HBzQeWqbVh)oKpnNdEROAUzvnxL(ymi9Z35ZzXnoF8IsILrSAh3htu4SpdD8A7ZqOISs5PJjQFXXt(m1(1ZKMc9OftMc6TREL85LkZpAIjsWtETF3D5yeZv7KbSR9bLfG)UbaNNJ(cj)TQl((O0qBuIQ3YI7lBhcOFHyb81xi8RZRp4Si0VaM9HO(ii(psKy92ta8JMyGEdtp2dvni0QAs6iSgLsljwOGuotG86Zjq5VUb(vOrPSukwEeChHBN1ocN)8BXKCRFaOwtDkmJVlR8FRUJ)MClGd19oLQvhCU5qtwhhAPfJhx10nh6HQ(wJt(SKR1va3BWq4M37VYT5aFSV)EOigra12nEhDsE)bd4Vx8yGa0JbPhdr)CB232gAyOBD4ihmm746bhmUdHdpefo48T8BRfK9iBDGSBHfu1d06O9aT5X5x6FDaAbBhqRRsDLVR8x5jQBR7DgYPielU4wCFjyc349XEoR4w273yxoBOQ4eiTN146eQRE42uVlbhIoXt0fhBwFlG7JXrXEqB69ND1GgZ1tXlLCSte4e4eBPBkMWeLbyF1DO3Um4d2D4U911C74J)))d
```
