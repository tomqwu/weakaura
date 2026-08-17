# Druid TBC — Bear, Restoration & Balance (v18)

One pack covering **Feral tank (bear)**, **Restoration** and **Balance** for TBC Anniversary
(2.4.3 / WeakAuras `internalVersion` 45, `tocversion` 20501). Built with
`tools/tbc-weakaura-creator`, 45 tables (5 sub-groups + 39 elements under one top-level
group), **zero custom code**, and locale-proof by construction: every trigger matches by
exact spell ID — never by name — so it works identically on a zhCN client. Every
spec-specific element is gated on that build's signature ability, so the HUD reshapes
itself on respec with no user action; mutually exclusive elements share screen slots.
Six of the 39 elements are the **PvP layer** and load only inside an arena or a
battleground — in PvE the pack is exactly what v3 was, minus nothing.

The whole thing hangs off one draggable top-level group anchored at screen centre `(0,-140)`;
the five sub-groups below can be dragged independently. **From v15 your state is drawn as
The Sill**: an instrument strip directly under your character at `(0, -110)`, stacked from three
rails — threat, health, primary power — with both numbers printed *inside* their own rail and
every rage breakpoint drawn as a full-height waterline. **v18 makes it long and thin**: 160 × 13
rails on a 164 × 36 plate, **1.6 pixels per percent**, where every value the pack marks is a
multiple of five so every mark still lands on a whole pixel. It replaces the v12–v14 ring cluster
(three concentric arcs around a live 3D portrait at `(-270, 40)`), which cost 10,000 px² to carry
the same three gauges and spent 19% of that on a face that never changed a button press.

## v18 — long and thin, not big

**The rails read as too short, and the fix is not "make the strip bigger".** The sibling packs
tried that twice — 300px rails, then 200px — and the player rejected both, because scaling the
whole strip uniformly preserves the original 2.8:1 plate and simply makes the same stubby block
larger. It reads as a **UI panel** rather than as a readout.

**A vitals bar wants to be long and thin.** The fill's *travel* is the signal; its thickness
carries nothing. So v18 keeps the rails long and puts the height back near the original:

| | v15–v17 | **v18** | |
|---|---|---|---|
| health / power rails | 100 × 11 | **160 × 13** | 60% longer |
| threat rail | 100 × 4 | **160 × 5** | thinnest lane, no number |
| plate | 102 × 31 | **164 × 36** | 5 px taller |
| numbers | 11 pt at `x +32` | **12 pt at `x +51`** | still inside the rail |
| ruler hairlines | 1 px | **2 px** | |
| rage waterlines | 3 / 5 px | **4 / 8 px** | dim / lit |
| threat number | 10 pt, hidden | **9 pt, hidden** | unmoved, still at `x −32` |

**1.6 pixels per percent, and every mark still lands whole.** Every value this pack marks is a
multiple of five and 1.6 × 5 = 8, so nothing lands between pixels:

| mark | value | x |
|---|---|---|
| Mangle reserve | 20 rage | **−48** |
| ruler | 25% | **−40** |
| ruler | 50% | **0** |
| Maul window / threat notch | 70 | **+32** |
| ruler | 75% | **+40** |

The invariant was never the number 100 — it is that `waterX()` is the **only** place a coordinate
is derived, which is what makes the length a single constant. The build asserts each mark against
a literal *and* asserts that it is a whole pixel.

### The lane stack is derived from this pack's own plate, not copied

A druid has no discrete class resource — rage, energy and mana are all continuous pools already
carried by the power rail — so this is a **three-lane** strip where the rogue and mage packs have
four, and its plate has sat at local `y +3` since v15. The offsets fall out of that convention:

```
content = 5 + 1 + 13 + 1 + 13 = 33, centred on the plate centre (+3) -> -13.5 .. +19.5
  threat  +19.5 - 5/2                        = +17
  health  +19.5 - 5 - 1 - 13/2               =  +7   (unchanged from v17)
  power   +19.5 - 5 - 1 - 13 - 1 - 13/2      =  -7
36px plate around 33 of content -> 1.5px of margin above AND below
```

| lane | region | size | local (x, y) | absolute y span |
|---|---|---|---|---|
| **Sill Plate** | `texture` | 164 × 36 | `(0, +3)` | −89 … −125 |
| **threat rail** | `progresstexture` | 160 × 5 | `(0, +17)` | −90.5 … −95.5 |
| **health rail** | `progresstexture` | 160 × 13 | `(0, +7)` | −96.5 … −109.5 |
| **power rail** | `progresstexture` | 160 × 13 | `(0, −7)` | −110.5 … −123.5 |
| rage waterlines | 4 × `texture` | 4/8 × 13 | `(−48 / +32, −7)` | on the power rail |

The build asserts the stack arithmetic, the 1 px gutters, that the whole stack fits inside the
plate, and that the two leftover margins are **equal**.

### Nothing moved on screen, and that is a measurement

The plate grew by 5 px of height, so the frontier was re-scanned *before* anything changed rather
than copied from another pack:

```
sill:            x -82..82   y -125..-89   (164x36 = 5904 px2)
envelope scan:   30 regions, dynamic groups projected 6 clones deep, 0 overlaps
                 tightest gap on any axis: 11.0px to the buff row (v17 had 13.5px)
                 nothing above the strip at all
column all-pairs: 4 flanking stacks, 6 pairs, 0 overlaps, tightest 14.0px
                 Druid - Buffs      x  -86..86    y -176..-136
                 Druid - Alerts     x -170..-130  y  -64..206
                 Druid - Cooldowns  x -106..106   y -222..-190
                 Druid - PvP        x  132..168   y -272..-26
```

**No column moves**, and no column needed to: the strip clears everything up to a ±8 px pad and
only collides with the buff row at ±12. It would still clear by 7.0 px if this pack ever grew the
±4 px alarm rim the profile allows — **and it does not grow one**. This pack has never had a
threat flash (decoding v12 for `alphaPulse` returns zero hits), and inventing one would consume a
new uid for a region that has never existed here. The 70 notch and the aggro-red rail remain the
escalation this pack ships.

The **all-pairs column check is new in v18**. The sill-versus-everything scan structurally cannot
see two flanking columns overlapping *each other* — a blind spot that hid a real defect in the
sibling rogue pack for several versions, where a 140 px kick-lockout bar sat over a weapon-proc
icon. Nothing in this pack is wrong today; the check is added now so it is already here the day
something is.

### What does not change

Not one trigger, load gate, condition, colour, spell id or region type. Diffed field by field
against the shipped v17 string, the only differences anywhere in the pack are `width`, `height`,
`xOffset`, `yOffset` and `subRegions` on the nine sill regions — the form-adaptive power trigger
(no `use_powertype`, so it follows every shapeshift), both spec-gated threat rails, the
not-in-arena size gate, the Bear-form gates, the buffs, alerts, cooldown row and PvP layer are
untouched.

**Nothing to delete afterwards.** 45 tables before, 45 after, all 44 child uids byte-identical
(`changed = 0`, `missing = 0`, `parentSame = true`, verified with **no** removal allowance). Zero
new `uid()` calls consumed. **Leave the `Arrangement` category ticked in the update dialog** —
sizes and offsets travel in it, and unticking it keeps the v17 geometry.

## v17 — the rails were filling the wrong way

**Every rail filled right-to-left.** They should fill left-to-right, and now do.

The Sill shipped `orientation = "HORIZONTAL"` because WeakAuras' own dropdown labels it
that way — `Private.orientation_with_circle_types` maps `HORIZONTAL_INVERSE = L["Left to Right"]`.
That label is wrong, or at least describes something other than where the fill sits. The
implementation is the authority, `BaseRegions/LinearProgressTexture.lua`, where a bar calls
`SetValue(0, progress)`:

| orientation | texture x-range | fill sits | grows |
|---|---|---|---|
| `HORIZONTAL` | `0 → progress` | left | rightward |
| `HORIZONTAL_INVERSE` | `1-progress → 1` | right | leftward |

So every rail is now `HORIZONTAL`. This also finally aligns the breakpoint waterlines with the
fill: they were always placed by `x = value − 50` assuming a left-anchored bar, so on an
inverted rail the fill crossed them from the wrong side.

The design flagged this field as its one unverified value and asked for a 30-second live check.
That check has now happened, and the answer was the opposite of the transcription.

## v16 — the number offsets were never actually applied

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

## v15 — The Sill

**The ring cluster is gone. In its place, under your feet, is an instrument.**

```
                    ┌──────────────────────────────────────────────────┐
   threat  100×4    │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░│░░░░░░░░░░░░░░░░░░░░░░│   ← notch at 70
   health  100×11   │████████████│████████████│███████│░░░░░░░░░  87    │   ← ruler at 25/50/75
   power   100×11   │██████████████│███░│█████│░░░░│░░░░░░░░░░░░  62    │   ← waterlines at 20/70
                    └──────────────────────────────────────────────────┘
                              102 × 31 px, absolute (0, −110)
```

### The argument, in three numbers

**A ring buys gauge length with area squared.** `Ring_20px.tga` has a 20/256 stroke, so the
band is a fixed *fraction* of the diameter — you cannot draw a small ring with a thick stroke.
At the shipped sizes the three arcs delivered 712 px of gauge inside a 10,000 px² box.

**But that length was not readable.** A 0–100 quantity has exactly **100 distinguishable
states**. The 84px health ring's arc was 243 px long: 143 of those pixels were re-drawing
states the eye cannot separate on a curve. **100 px is the exact length at which a 0–100 gauge
is lossless** — every pixel beyond it is redundant, every pixel below it discards a state.
That is why the rails are 100 px and not 120 or 80, and it is what makes **one pixel one
percent**.

**And 19.4% of the cluster was decoration.** The 44 × 44 model was 1,936 px² carrying zero
decisions; the hole inside the power ring was another 2,150 px² carrying one number.

| | v14 cluster | v15 Sill | |
|---|---|---|---|
| bounding area | 10,000 px² | **3,162 px²** | **3.16× denser** |
| height (the scarce axis) | 100 px | **31 px** | 3.2× |
| px² spent on decoration | 1,936 (19.4%) | **0** | |
| readable states carried | 300 | 300 + 3 breakpoints + 6 ruler ticks | |

Every breakpoint also stops being trigonometry. v14 placed the 20-rage mark with
`r = 62/2 × 0.94; x = r·sin(2πf); y = r·cos(2πf)` → `(28, 9)`. v15 places it with

> **x(v) = (v / maxpower − 0.5) × 100**, which for rage's flat 0–100 pool is simply **x = v − 50**

→ 20 rage at `x = −30`, 70 rage at `x = +20`. The build asserts both against that formula.

### Geometry, exact

`Druid - Rings` is renamed **`Druid - Player Sill`**. It does not move: it was already at
`(0, 30)` inside a top group at `(0, −140)`, which sums to absolute **`(0, −110)`** — precisely
where the Sill wants to be. What changed is that its nine children stopped carrying a local
`(−270, +150)` and started carrying a lane table:

| lane | region | size | local (x, y) | absolute y span |
|---|---|---|---|---|
| **Sill Plate** | `texture` | 102 × 31 | `(0, +3)` | −91.5 … −122.5 |
| **threat rail** | `progresstexture` | 100 × 4 | `(0, +15.5)` | −92.5 … −96.5 |
| **health rail** | `progresstexture` | 100 × 11 | `(0, +7)` | −97.5 … −108.5 |
| **power rail** | `progresstexture` | 100 × 11 | `(0, −5)` | −109.5 … −120.5 |
| rage waterlines | 4 × `texture` | 3/5 × 11 | `(−30 / +20, −5)` | on the power rail |

Lane stack: `4 + 1 + 11 + 1 + 11 = 28` of content, plus a 1 px margin top and bottom and the
1 px border art → **102 × 31**. A druid has no discrete class resource — rage, energy and mana
are all continuous pools already carried by the power rail — so there is no fourth lane and the
strip is 31 tall instead of the 37 the rogue and mage packs use. Every rail keeps the same
local offset as in those packs, so the three gauges land in identical places in all seven.

**Why `(0, −110)` and not the waist.** A 102 × 37 rectangle scan across all seven packs
(dynamic groups projected six clones deep) is clean at `y = −21`, `−100` and `−110` and dirty
everywhere between; `−110` has the best margins by a wide margin — 11.5 px to paladin's and
hunter's buff rows above, 7.5 px to the other five packs' buff rows below. This pack's strip is
only 31 tall, so its own clearance to `Druid - Buffs` (`y −176…−136`) is **13.5 px**, and
nothing in the pack sits above it at all. The build re-runs that scan against the assembled
tables and fails on a single overlapping pixel:

```
strip rect: x -51..51   y -122.5..-91.5   (102x31 = 3162 px2)
30 regions scanned, dynamic groups projected 6 clones deep, 0 overlaps
  Druid - Buffs      bbox x  -86..86    y -176..-136     (13.5px clear below)
  Druid - Alerts     bbox x -170..-130  y  -64..206      (x-separated)
  Druid - Cooldowns  bbox x -106..106   y -222..-190
  Druid - PvP        bbox x  132..168   y -272..-26      (x-separated)
```

### What each lane says

**Threat rail** — 100 × 4, the thinnest lane because it is a warning and not a quantity. Both
threat auras (Bear-gated and Balance-gated, mutually exclusive as they have been since v7)
share it. Every trigger, every escalation, the not-in-an-arena size gate and the mandatory
`threatvalue <= 0 → alpha 0` guard are **byte-identical to v14**. The new part is `sub.2`, a
2 × 4 white notch at **`x = +20`, i.e. the 70 line** — the same `x = v − 50` the rage
waterlines use. For the caster it is the ceiling to stay under (and the orange condition fires
on the same value); for the bear, whose semantics are inverted, it is the floor to stay above.

**Health rail** — 100 × 11. Trigger pair, amber under 50%, red under 25%, the `maxhealth <= 0`
guard, the out-of-combat fade: all unchanged. `%percenthealth` is printed **inside the rail at
`x = +32`, 11 pt, `OUTLINE`** — two digits span `+25…+39`, three digits `+21.5…+42.5`, still
7.5 px inside the rail's right edge. `sub.2–4` append a **ruler**: three 1 px hairlines at 18%
white at `x −25 / 0 / +25`. Thirty-three pixels of ink, zero footprint, and it turns "estimate
a fraction" into "count quarters".

**Power rail** — 100 × 11, and it is still one gauge for all three druid resources. The trigger
still omits `use_powertype`, so WeakAuras resolves the type from `UnitPowerType(unit)` at
runtime and the rail follows every shapeshift; the `powertype == 1 → red` / `powertype == 3 →
yellow` conditions are kept **verbatim**. `%percentpower` at `x = +32`, 11 pt — and because
rage and energy both cap at 100, on a 100 px rail the percentage *is* the absolute value, so
the number and the scale finally agree. Same ruler at `sub.2–4`.

**Rage waterlines** — the four v2 marks, same uids, same colours, same triggers, same Feral +
Bear-form gates, same 0.25 s pop-in and 0.2 s fade. They stop being 5 px and 7 px dots on a
circumference and become **full-height lines across the rail** (3 px dim, 5 px lit,
`Square_White`) at `x = −30` (20 rage, the Mangle reserve) and `x = +20` (70 rage, where Maul
plus the next Mangle still leaves you capping). The dim line is the permanent "this is where
20 rage is"; the fat lit twin pops in the instant you cross it. They were round before because
a rotated quad rotates the *art inside* the quad, so a straight line could never be laid along
an arc — across a horizontal rail no rotation is needed at all.

**The Sill Plate** — a 102 × 31 `Square_White_Border` quad in black at 45%, drawn **first** so
it is behind everything. It is what makes an 11 px rail and an 11 pt number survive snow, lava
and Shattrath at noon, and it is what makes three bars read as *one instrument* instead of
three floating things.

### What you lose, said plainly

- **The live 3D portrait is gone.** Its uid becomes the plate (`model` → `texture`, which is
  free — WeakAuras matches by uid and the region type is just data). This reverses v12's
  judgement that "two concentric arcs around a live 3D portrait read as *a unit* — you". It is
  a taste call and it is the single most likely complaint. The defence: what v14 actually
  needed from the face was not a face, it was an **opaque backdrop for a number**, and the
  plate is that at 1/62nd of the ink. The model was 1,936 px² carrying zero decisions.
- **The threat percentage is switched off** — `text_visible = false`, *not* deleted. It keeps
  `sub.1`, so it is one tick-box away in `/wa` → the aura → Display → Text. It is parked at the
  **left** end of the rail (`x = −32`) so that re-enabling it does not drop a second number on
  top of the health percentage at `+32`. Why it went: `threatpct` is scaled so 100 = pulling
  aggro, which makes it an early-warning *ratio*, not a quantity you spend — and reading 68
  against 72 is slower than watching a fill cross a notch. It is still information deliberately
  removed, and you are entitled to disagree.
- **`Druid - Rings` is renamed** to `Druid - Player Sill`, and three more auras are renamed
  (`Player Health Ring` → `Health Rail`, `Player Power Ring` → `Power Rail`, `Player Portrait`
  → `Sill Plate`). Renames are invisible to an Update — WeakAuras matches by uid — but if you
  have macros or notes referring to the old names, they are the old names.

### What does *not* change

Not one trigger, load gate, condition or colour. That is checked by diffing the shipped v15
string against the shipped v14 string field by field, not by eye: **132 trigger/condition/load
field pairs across all 44 auras, 0 differences**, and every rail and waterline colour identical.
The buffs, alerts, cooldown row and PvP layer are untouched.

### After updating

**Leave the `Arrangement` category ticked in the update dialog.** This is the version where it
matters most: v15 re-parents nothing but it **renames the group, moves every one of its nine
children, changes four region sizes, re-types the portrait and re-orders `controlledChildren`**
— and all of that travels in Arrangement. Untick it and you keep the v14 ring geometry wearing
v15's region types, which is not a layout anyone wants. Tick it once, then drag
`Druid - Player Sill` wherever you like it.

**Nothing to delete afterwards.** No aura is added or removed: 45 tables before, 45 after, and
every one of the 44 child uids is byte-identical (`changed = 0`, `missing = 0`,
`parentSame = true`, verified with **no** removal allowance). Zero new `uid()` calls were
consumed — the plate, the rails and the waterlines are all recycled in place.

**One thing to look at in combat, once.** `orientation = "HORIZONTAL"` is WeakAuras'
"Left to Right" on a progresstexture (the key lies about direction in the usual way, and it
lies *differently* from an aurabar, where `HORIZONTAL` is the left-to-right one). It is
transcribed from `Private.orientation_with_circle_types` and shares its code path with
`VERTICAL`, which is live in a shipped string in this repo — but no committed string here has
rendered `HORIZONTAL_INVERSE` itself. **30-second check: at full health the rail is solid; take
some damage and the empty part must be on the *right*.** If it is reversed, it is a one-token
fix and nothing else changes.

## v14 — the health number is in the middle again

**The complaint was exact: "percentage in middle can't be seen."** It could not, because there
was no percentage in the middle. v12–v13 parked both of your numbers *outside* the arcs — health
54px below the cluster at 13pt, power 70px below at 10pt — and left the middle holding nothing
but the portrait. Two small detached numbers hanging in open space have nothing behind them, and
against a bright zone or a white-ish mob they are simply gone.

**Where the numbers are now:**

| number | before (v13) | now (v14) | why |
|---|---|---|---|
| **health** | 13pt, `y −54` | **16pt, `y 0`** | dead centre, **on your portrait** — the only opaque backdrop the HUD owns |
| **power** | 10pt, `y −70` | **12pt, `y −54`** | takes the slot health just vacated, right under the 84px health band |
| threat | 10pt, `y +58` | **unchanged** | still the one number *above* its arc, clear of the 100px annulus |

Nothing else about them changed: same `%percenthealth` / `%percentpower` / `%threatpct` tokens,
same white, same `OUTLINE` font — and the outline is what does the work now, because a white
16pt number with a black outline on a lit 3D model is the most readable thing in the pack.

**The half that is not obvious: the draw order had to change too.** Moving the offset alone
would have looked like *nothing happened*. A group's `controlledChildren` list is its sibling
stacking order — WeakAuras' `FixGroupChildrenOrder` walks it and adds **+4 frame levels per
child**, so **first = furthest behind** — and the portrait was adopted **last**, i.e. on top of
everything. The health number would have been drawn under the face and stayed invisible for a
second, more annoying reason. So the portrait is now the **first** child of `Druid - Rings`:

```
v13:  Health Ring, Power Ring, Threat (Bear), Threat (Caster), Rage Mark ×4, Player Portrait
v14:  Player Portrait, Health Ring, Power Ring, Threat (Bear), Threat (Caster), Rage Mark ×4
```

**This does not hide your face, and that is not luck — it is what an annulus is.** `Ring_20px`
paints `diameter × 20/256` at the *outer* edge, so the three arcs occupy radius **42.19–50**
(threat), **35.44–42** (health) and **26.16–31** (power), while the portrait occupies **0–22**.
No ring's *art* comes anywhere near the face. The only thing any of them puts over it is text,
which is the entire point of the change. The build asserts exactly this — every band's inner
radius against the portrait's — so a future size change cannot quietly paint over your head.

**It also ends a contradiction that has sat in the source since v12.** The portrait is written at
`frameStrata 2`, which is WeakAuras' **`BACKGROUND`** — the *lowest* strata, below the inherited
one the rings use. The comments next to it claimed the opposite ("nothing ever draws over your
face") and the child order was arranged to match the claim rather than the data. Strata and frame
level now agree, and both say the same thing: the face is the cluster's backdrop.

**Reordering children costs no UIDs.** Construction order is the seeded UID stream and is
untouched; only the portrait's `adopt()` call moves, from the end of the group to the front. The
result is `stable=44 changed=0 retained=44 missing=0 parentSame=true` — every one of the 45
tables keeps its identity, so this is a clean **Update**, and there is nothing to delete
afterwards. **Tick Arrangement when you update**: the offsets and font sizes *are* the
arrangement, and with it unticked you keep v13's placement and see none of this.

Beyond those two labels and that one list, **nothing in the pack changed** — no aura added or
removed, no trigger, load gate, condition, colour, size or position anywhere. A field-level diff
of the shipped string against v13 is exactly 13 lines: four label fields and the nine-entry
`controlledChildren` rotation.

## v13 — one cluster, and threat is yours

**The target cluster is deleted.** Its 62px health ring, the 84px track ring that groove ran in,
and its live 3D portrait are gone — three auras removed, 48 tables → 45. It was the prettiest
thing in the pack and it never once changed a button press: your target's health is already on
your **target frame** and on its **nameplate**, and its portrait is on the target frame too, so
for the whole game that cluster was a second copy of the default UI parked at `(+270, 110)`.

**Threat moves, it does not die.** Threat was the one thing that cluster carried which nothing
else on screen shows, and a druid who pulls aggro dies. Both threat rings — the bear one and the
caster one, which are mutually exclusive spec gates and have shared a slot since v7 — become the
**outermost ring of your own cluster**:

| ring | diameter | shows |
|---|---|---|
| **outermost** | **100px** | **your threat** (spec-gated, and absent unless threat is real) |
| outer | 84px | your health |
| inner | 62px | your primary power — mana, rage or energy |
| centre | 44px | your live portrait |

all of it concentric on `(-270, 40)`, which has not moved. `%threatpct` sits at 10pt, anchored
`CENTER` with a `+58` offset — just clear of the 100px annulus, and still the one number in the
layer that is above its arc rather than below it, so it can never collide with the health number.
Ring_20px paints `diameter × 20/256` at the outer edge, so the health band runs from radius 35.4
to 42 and the threat band from 42.2 to 50: adjacent, never overlapping. There is no threat flash
halo in this pack to resize — decoding v12 for `alphaPulse` returns zero hits.

**Threat keeps everything else it had**: the same Threat Situation trigger, the same escalations
on `foregroundColor` (bear: green while you are securely tanking, **red the moment aggro is
lost**; caster: green → **orange at 70%** of the pull threshold → **red when you pull**), the v5
not-in-an-arena instance gate, the v7 Bear-form trigger, its spec gate, and the mandatory
`threatvalue <= 0 → alpha 0` guard without which a progresstexture at total 0 draws **full** and
reads as complete aggro at exactly zero threat. **No gate was added either.** This pack has never
carried a party/raid `ingroup` gate on threat — its gates are per-spec — and inventing one here
would be a behaviour change rather than a preserved one. What keeps the common case to two rings
and a face is the guard plus the trigger itself: with no hostile target there is no threat state,
so the third arc simply is not drawn.

**One correction rides along.** v12 wrapped the factory's threat trigger to add `unit = "target"`,
on the belief that `threatUnit` was dead data. It is the other way round: the Threat Situation
prototype renamed that argument to `unit` at **internalVersion 51**, and Modernize migrates `< 51`
data forward — so IV-45 data must emit the **old** `threatUnit` name and let the migration rename
it on load. The stray `unit` field is dropped and the factory trigger is used unchanged.

**Orphans are expected here, and that is the point.** Every version up to v12 recycled every UID,
so an update left nothing behind. v13 genuinely *removes* regions, and inventing filler regions to
absorb their freed slots is how a HUD accumulates junk nobody can explain a year later. Two of the
three sat **mid-stream** in the seeded UID sequence (slots 8 and 9), so their `W.uid()` calls are
still drawn and thrown away where they always were — a *retired slot*, which builds nothing and
ships nothing — and every later UID keeps its value. The third was the very last draw in the file
and is retired the same way, so no future version can hand a removed aura's UID to a new one.
The result is `stable=44 changed=0 retained=44 missing=3 parentSame=true` against v12: **every one
of the 44 surviving auras keeps its UID**, and the only three missing are the ones named below.

### What to delete by hand after updating

WeakAuras **never deletes an aura that an import does not mention**, so after you Update, these
three still sit in your collection doing nothing. The group that held them, `Druid - Rings`, is
*not* one of them — it is still your cluster's layer and the rage pips' — so delete the three
auras individually rather than the group:

- **`Druid - Target Health Ring`**
- **`Druid - Target Ring Track`**
- **`Druid - Target Portrait`**

`/wa` → right-click each one → **Delete**. Until you do, you will still see a ring cluster
floating at `(+270, 110)` with no threat arc on it.

Tick the **Arrangement** category when you update: the threat ring's new size and position *are*
the arrangement.

## v12 — the globes become rings again, around a live portrait

**Two rings and a face, per unit.** v10 traded the ring clusters for Diablo globes and paid for
the number-inside-the-glass by deleting the portraits. Side by side, the rings win: an arc around
a face reads as *that unit's* state, where a vessel is a meter that happens to be near you, and a
live 3D portrait tells you what you are actually fighting — including every NPC and mob no icon
or gate in this pack could ever name.

| | outer ring (84px) | inner ring (62px) | centre (44px) |
|---|---|---|---|
| **Your cluster** at `(-270, 40)` | health | primary power — mana, rage or energy | your live portrait |
| **Target cluster** at `(+270, 110)` | **threat** | target health | its live portrait |

Both clusters are the same three sizes, which is what makes them read as a matched pair rather
than as two unrelated widgets. **There is deliberately no target power ring.** v8–v9 gave the
target a third arc for its mana, and that extra ring is exactly what made the old cluster look
busy and uneven — and a target's mana pool never changes a druid's next button press. Its aura is
not deleted (that would strand a UID): it becomes the target's **outer track**, the empty groove
the threat arc runs in, so a resto druid — who loads neither threat aura — still sees two rings
where you have two.

**The percentages hang just outside the arcs again, and the portrait is why.** A WeakAuras `model`
region cannot carry a text sub-region at all — `SubText`'s `supports()` lists texture,
progresstexture, icon, aurabar and empty, and pointedly not model — so the centre of a cluster is
a face and can never be a number. Both clusters label themselves identically: health 13pt just
under the outer ring, power 10pt below that, threat 10pt *above* the ring where it can never
collide with a health number.

**`|x| = 270` is not an eyeballed number.** The Alerts column occupies `x` `-170..-130` and the
PvP column `182..218`, and both are *dynamic groups that grow vertically*: an 84px outer ring
spans 42px either side of its centre, so at `|x| = 190` it reaches 148 and the alert stack climbs
straight into it from the second simultaneous prompt onward. At `|x| = 270` the inner edge is at
228 — the tightest symmetric position that is clear of both columns at any stack depth. The build
proves this rather than asserting it: after assembling the string it re-walks the parent chain and
asserts both cluster centres and all four rage pips.

**The rage breakpoints go back to trigonometry.** On a vessel, 20 and 70 rage were horizontal
waterlines. On a ring a threshold is a point on the circumference, placed from the inner ring's
radius as `r = 62/2 × 0.94`, `x = r·sin(2πf)`, `y = r·cos(2πf)` — which puts `f = 0` at 12 o'clock
and advances *clockwise*, the same direction the ring fills, so each pip sits exactly where the
arc will reach it: **20 rage at 72°** (upper right), **70 rage at 252°** (lower left). They are
round pips rather than lines because rotating a thin quad on a texture region rotates the *art
inside* the quad, so a straight line can never be laid along an arc. The dim + lit pair, their
colours, the pop-in when you cross, and both gates are unchanged.

**What did not change:** every trigger, every load gate, every escalation (amber under 50% health,
red under 25%, the power-type recolour, threat green → orange at 70% → red on the flip), both
threat gates and the `threatvalue <= 0 → alpha 0` guard; the buff row, alert flow, cooldown row and
PvP layer are byte-identical. **No aura was added or removed** — 48 tables before, 48 after,
`stable=40 changed=0 retained=47 missing=0 parentSame=true` against v11, so the import dialog still
offers **Update**. The two globe rims were the v8–v9 portraits and are handed straight back to
them. **What is dropped:** the v11 specular highlight, which was a glass effect for a filled
vessel and means nothing on an annulus.

Tick the **Arrangement** category when you update: the position and geometry *are* the arrangement.

## v11 — the globes move up beside you and the glass catches light

Two changes, both cosmetic, and between them they are the difference between "three meters
parked under the UI" and "the character is holding these".

**The globes flank the character now.** v10 put all three vessels on one horizontal band at
absolute `y = -262`, below everything else in the pack. That reads as a *second* status bar
bolted under the HUD: your eye leaves the character to check it and comes back. They now sit
either side of the model at eye level, with the target above and between them:

| | v10 | v11 |
|---|---|---|
| life globe | `(-150, -262)` | **`(-270, 40)`** |
| power globe | `(+150, -262)` | **`(+270, 40)`** |
| target globe | `(0, -262)` | **`(0, 110)`** |

Sizes are untouched — 72px for life and power, 44px for the target, each rim its globe + 4px.

**`|x| = 190` is not an eyeballed number, and it is the tightest arrangement that fits.** The
Alerts column sits at `x = -150` and the PvP column at `x = +150`, with icons up to 40px wide,
so those columns occupy `|x| ≤ 170`; the PvP layer also holds elements at `(200, -44)`. A 72px
vessel spans 36px either side of its centre and its rim 38px, so at `|x| = 190` the inner edge
lands at 152 and the outer at 228 — inside the gap, and clear of the PvP row in `y` as well,
since the globes now sit 84px above it. `|x| = 170` would sit *on* the icon columns and
`|x| = 210` *on* the PvP element. The build proves this rather than asserting it: after
assembling the string it re-walks the parent chain and asserts the three absolute positions,
and the same numbers are used by all seven class packs.

**The glass catches light.** A flat colour inside a circle reads as a sticker, not as liquid in
a vessel. Every globe gains one **specular highlight**: a soft, off-centre bright spot in the
upper left, 46% × 34% of the globe's diameter, offset `(-17%, +21%)` of it, white at 28% alpha —
which is the cue your eye already reads as *a curved surface catching a light source*. It is a
`subtexture` sub-region on the same `Circle_Smooth.tga` disc the globe is drawn from, so it
scales with the vessel and the small target globe gets the same read as the big pair.

Two rules that recipe obeys, both of them silent-breakage class if broken:

- **It is appended, never inserted.** Conditions address sub-regions *positionally* — `sub.N` is
  the 1-based index into `subRegions` — so inserting a sub-region ahead of a referenced index
  silently retargets that condition at the new occupant, with no error anywhere. The highlight
  goes on the end: the percentage stays `sub.1`, the highlight is `sub.2`, and the build asserts
  exactly that before it will write a string.
- **Its blend mode is `ADD`, not `BLEND`.** The percentage sits *inside* the glass and
  sub-regions draw in index order, so an appended overlay draws over the number. `ADD` can only
  brighten what is beneath it, so the number stays readable; a `BLEND` overlay at the same alpha
  would grey it out. That single constraint is the reason this is a *highlight* rather than the
  more obvious dark edge vignette, which would have to be `BLEND` and would have to be inserted
  ahead of the text.

**What did not change:** every trigger, load gate, condition, colour, spell id and region type;
the buff row, alert flow, cooldown row and PvP layer; every size in the globe layer. **No aura
was added or removed** — 48 tables before, 48 after, `stable=47 changed=0 retained=47 missing=0
parentSame=true` against v10, so the import dialog still offers **Update**. The four bear rage
marks moved with the power globe, because their coordinates were already derived from the
canonical constants rather than written down.

Tick the **Arrangement** category when you update: the position change *is* the arrangement.

## v10 — the rings become globes

**Life and power are now vessels, not arcs.** A ring encodes a value in *arc length*: you read
it by judging how far around a hoop the colour has travelled. A globe encodes it in a
**waterline**, which is the same read your eye already does on a glass of water, and it is
what Diablo has used for thirty years. Same WeakAuras region type as the rings
(`progresstexture`), one different field:

```lua
orientation = "VERTICAL"   -- WeakAuras for "Bottom to Top": the fill line rises
```

| | where | size | what it shows |
|---|---|---|---|
| **Life globe** | `x = -150` | **72px** | your health, in D2 red, `%percenthealth` **inside the glass** at 18pt |
| **Target globe** | `x = 0` | **44px** | your target's health, `%percenthealth` inside at 13pt — smaller because it is secondary, and it vanishes entirely with no target |
| **Power globe** | `x = +150` | **72px** | mana, rage or energy — whichever you are actually using — with `%percentpower` inside at 18pt |

All three sat at screen `y = -262` in v10 (v11 moves them beside the character), and each is
wrapped in a brass **rim** texture at its own size + 4px, drawn one frame strata above the fill
so the liquid reads as being *inside* glass.
The unfilled part of a globe is a near-black disc rather than nothing, which is what sells the
container: colour rising into a vessel, not a shape appearing out of the void.

**The portrait is gone, and that is what buys the numbers their place.** A WeakAuras `model`
region cannot carry a text sub-region at all — `SubText`'s `supports()` lists texture,
progresstexture, icon, aurabar and empty, and pointedly not model — which is why every ring
version had to park its percentages *outside* the arcs, where they competed with the world for
your attention. Drop the portrait and the centre of each vessel is free for the one number that
belongs there. Diablo never had a portrait either. The trade is real and worth naming: **no
live face** for you or your target.

**Threat became the target globe's rim.** It is the one readout with no natural vessel of its
own — it is not a resource, it is a relationship — so instead of inventing a fourth globe for
it, it colours the ring of glass around the target: **green** while your threat is healthy,
**orange at 70%** of the pull threshold on the caster rim, **red** on the aggro flip, with
`%threatpct` sitting just above the globe. This costs no extra element and no extra screen
space. Both rims keep their v5 not-in-arena gate, their v7 Bear-form gate and the
`threatvalue <= 0 → alpha 0` guard, and the bear rim keeps its tank-inverted meaning: green
while you are securely tanking, red the moment aggro is *lost*.

**The bear's rage breakpoints got simpler, not harder.** On a ring, 20 and 70 rage needed
trigonometry against the arc's stroke. On a vessel a threshold is a horizontal line at a fixed
height — `y = (threshold/max - 0.5) × 72` — so 20 rage is a line 22px below the centre of the
glass and 70 rage is one 14px above it, each as wide as the globe's chord at that height (58px
and 66px). The dim + lit pair, their colours, the pop-in when you cross, and both gates are
unchanged.

**What else did not change:** every trigger, every load gate, every escalation (amber under
50% health, red under 25%, the power-type recolour), the whole cooldown row, buff row, alert
flow and PvP layer. **No aura was added or removed** — 48 tables before, 48 after, every UID
stable (`changed=0, missing=0`). All thirteen tables in the layer were *recycled in place* —
eleven renamed, five given a new region type — so nothing is orphaned in your WeakAuras,
including both portraits, which became the life and power rims, and the target's mana ring,
which became the target globe's brass rim. **The one readout that ends is the target's mana** —
a fourth vessel for a number that never changes a druid's next button press.

Tick the **Arrangement** category when you update: the change *is* the arrangement.

## v9 — the orbs are one shared size

**The orbs are now one shared size across every pack.** v8 shipped the unit-orb layout to all
seven class packs, and each of them landed on its own diameters — and inside a single pack the
player cluster and the target cluster did not match each other either. Side by side that read as
uneven rather than as one HUD. v9 replaces every hand-written diameter with **one canonical set
of numbers, identical in all seven packs**, declared once at the top of `generate.lua` as named
constants (`ORB_OUTER`, `ORB_MID`, `ORB_INNER`, `PORTRAIT`, `CLUSTER_X`, `CLUSTER_Y`, `RING_TEX`)
and referenced everywhere below, so they cannot drift apart again.

| | player cluster, `x = -260` | target cluster, `x = +260` |
|---|---|---|
| outer ring, **104px** | **health** | **threat** |
| middle ring, **78px** | **primary power** | **health** |
| inner ring, **54px** | — | **mana** |
| centre, **46px** | your portrait | the target's live portrait |

Both sides therefore present the **same outer diameter** and the **same portrait**; the target
simply nests one more ring inside the same footprint. The numbers match too — health at 14pt,
`y = -60`; power at 11pt, `y = -76`; threat at 11pt, `y = +60` above the ring — so the two
clusters label themselves identically instead of at four different sizes and six different
offsets. Druid is the one pack with **two** threat rings (Bear and Caster, mutually exclusive
load gates); both are `ORB_OUTER`.

**The arcs are drawn with `Ring_20px.tga` instead of `Ring_10px.tga`.** A bundled ring texture is
256×256 and the number in its name is the stroke weight *in that space*, so the band scales with
the drawn size: the 10px art on a 104px ring is a 4px hairline that read as a wire, where the
20px art gives 8px of arc at the same diameter.

**What did not change:** every trigger, load gate, condition, colour, spell ID and region type is
byte-identical to v8, and **no aura was added, removed or reordered** — 48 tables before, 48
after, all 47 child UIDs and the top-level UID stable (`changed=0, missing=0`). The import dialog
offers a clean **Update**; as in v8, **tick the Arrangement category** for this one version, since
the change *is* the arrangement.

**The bear rage pips moved with their ring**, which is the one thing this pass could have broken
silently. The four pips at 20 and 70 rage are stand-alone `texture` regions anchored to the
screen and positioned by trigonometry on the power ring's stroke, so nothing drags them along
when that ring changes — and in v9 it both grew (64 → 78) and moved (`y` 0 → -60). Their radius
is no longer the literal `30`: it is derived as `ORB_MID / 2 × (1 - 20/256)`, the middle of the
Ring_20px band at that diameter, and their `y` now includes the cluster's own offset. Decoding
the shipped string puts all four at radius 35.74 inside a stroke spanning 32.91–39.00, at 72.07°
and 252.07° against the 72° and 252° their thresholds demand.

## v8 — the centre of the screen is now empty

Every version up to v7 parked a 172px-wide stack of health / power / threat bars directly under
your character, in the most expensive real estate on the screen — the place you are actually
trying to *watch the fight* through. v8 moves that state to where it belongs: **at the unit**.

Two compact clusters flank your character. Each is a **live 3D portrait** with the readouts
drawn as concentric **rings** around it:

| | player cluster, `x = -250` | target cluster, `x = +250` |
|---|---|---|
| outermost ring (120px) | — | **threat**, `%threatpct` above the orb |
| outer ring (96px) | **health**, `%percenthealth` under the orb | **health**, `%percenthealth` |
| inner ring (64px) | **primary power**, `%percentpower` | **mana**, `%percentpower` |
| centre (28px) | your portrait | the target's live portrait |

The target cluster **hides completely when you have no target** — portrait, rings and numbers.
That is not a condition or a load gate: the Health and Power triggers end in WeakAuras' own
hidden `UnitExistsFixed(unit)` test, so an absent target produces no state at all and every
region carrying that trigger simply is not drawn. Deselect and the right-hand side of your
screen goes quiet.

`±250` is not an eyeballed number. The Alerts column sits at `x = -150` and the PvP column at
`x = +150` with icons up to 40px wide, so they reach `|x| ≤ 170`; the widest orb reaches
`|x| ≥ 190`. Nothing overlaps, and everything between the two orbs is now free.

**One ring now does what three bars used to.** The player's power ring is *form-adaptive*: its
Power trigger deliberately omits `use_powertype`, so WeakAuras reads `UnitPowerType(unit)` and
follows you through caster → bear → cat with no gate, no respec dependency and no second aura.
The ring recolours itself from the resolved type — **blue mana**, **red rage**, **amber energy**
— so the colour names the resource without a label. v7 needed three mutually exclusive bars for
this and still showed a feral **nothing at all** outside Bear form; a cat had no resource
display in the entire pack. The trade is that the number reads `%percentpower`, i.e. a
percentage: for mana that is what you want, and for rage and energy the percentage *is* the raw
value, because both cap at 100.

**Nothing was quietly dropped.** Point by point:

- **The bear rage breakpoints survive**, as two pips sitting *on* the power ring rather than two
  lines sitting on a bar. The ring starts at 12 o'clock and fills clockwise, so 20 rage lands
  near 2 o'clock and 70 rage near 8 o'clock, each with the same dim marker plus the wider
  fully-lit twin that **pops in over 0.25s the instant you cross it**. They are still four
  separate auras, on purpose: the aurabar tick sub-region cannot be attached to a ring at all
  (its `supports()` accepts only `aurabar`), and the two sub-region types that *can* ride a ring
  would have cost the pop — a sub-region can change colour by condition but cannot carry its own
  animation, and the pop is the signal.
- **Threat keeps both role semantics and moves to the target orb**, which is where it belongs:
  it is *your* threat *on that unit*. The bear ring is green while you are securely tanking and
  turns **red the moment aggro is lost**; the caster ring is green, **orange at 70%** of the
  pull threshold and **red when you pull**. Both keep the v5 arena exclusion.
- **The out-of-combat fade survives** on the player rings (50% alpha), and now applies to the
  target rings too.

Two things are genuinely **new** rather than ported: a low-health escalation on the player
health ring (**amber under 50%, red under 25%** — the flat green bar never had one), and target
health and mana, which v7 did not draw anywhere.

Under the hood this is a **progresstexture** ring in `CLOCKWISE` orientation on WeakAuras'
bundled `Ring_10px.tga`, and a `model` region bound to the unit. Three field names in that
migration are silent no-ops if you get them wrong, and all three were checked against current
WeakAuras source rather than assumed:

- an aurabar's fill colour property is `barColor`; a progresstexture's is **`foregroundColor`**.
  A condition naming a property the region does not have is *skipped without any error*, so a
  mechanical port of the threat escalation would have produced a dead condition that still looks
  correct in the editor.
- an aurabar with `total == 0` draws **empty**; a progresstexture draws **full**. Threat reaches
  a zero total whenever your threat value is zero — post-Vanish, post-Feign, the instant before
  your first hit lands — so a naive port would slam the threat ring to a *complete circle*
  meaning "at the pull threshold" while the colour stayed green. Every threat ring therefore
  carries `threatvalue <= 0 → alpha 0`, and every health ring `maxhealth <= 0 → alpha 0`.
- current WeakAuras reads a model region's unit from **`model_fileId`**; WA 3.5.0 read
  `model_path`, and the migration bridging them is gated on `IsClassicEra()`, which is a
  *different* predicate from `IsTBC()` and therefore never runs on a 2.5.x client. Both fields
  are emitted.

**Updating from v7 — read this.** The eleven v7 Resources tables were **repurposed in place**,
not deleted: each kept its UID, so WeakAuras matches them and the import dialog offers a clean
**Update** in which each old bar simply *becomes* its replacement ring. All 45 v7 children and
the top-level UID survive (`missing=0, changed=0`), and only the two portraits are new. **Tick
the Arrangement category in the import dialog for this one version** — the entire layout has
moved, and unticking it keeps the v7 bar positions and stacks all six rings on top of each
other in the middle of the screen.

Because nothing was deleted, an Update leaves **no orphaned auras** and there is nothing to
clean up. The one case that does leave debris is importing as **new** instead of Update (or
having previously renamed/detached the group): then your old `Druid - Resources` group and its
ten bars stay behind alongside the new `Druid - Unit Orbs` group, and you should delete
`Druid - Resources` by hand — `/wa` → right-click the group → **Delete** → confirm *including
children*. If you see both a bar stack and a pair of orbs after updating, that is the case you
are in.

## v7 — Cat no longer receives the Bear HUD

The Mangle talent teaches both **Mangle (Bear)** and **Mangle (Cat)**. A Spell Known gate can
therefore identify a Feral build, but it cannot identify the form currently being played. Up
through v6 that distinction was missing: a Cat player loaded the rage bar, Lacerate, Maul and
the complete Bear cooldown row.

Every Bear-only element now ANDs its existing trigger with WeakAuras' built-in
**Stance/Form/Aura** state for form 1, the Bear/Dire Bear position on a fully trained TBC
druid. Cat form gets only the genuinely shared elements and the instance-gated PvP layer;
shifting into Bear makes the tank HUD appear immediately. No aura was added, removed or
reordered, all 45 child UIDs and the top-level UID are unchanged, and the top-level group has
been renamed to state the supported scope honestly.

## v6 — the cooldown row shows what you cannot press

**No new auras, no removed auras, no moved auras.** Every UID is identical to v5, so the import
dialog offers a clean **Update** and nothing on your screen moves.

The old cooldown row was inverted. It drew all eight icons all the time and dimmed the ones that
were down, so it was at its busiest exactly when you had the *fewest* options — and you already
know your own spellbook. What you cannot know at a glance is what is **unavailable, and for how
long**.

So the seven situational cooldowns now appear **only while they are on cooldown**, wearing the
swipe and the countdown, and disappear the instant the ability is back. The row is a dynamic
group, so the gap closes behind them:

> **Absence is the readout.** An empty row means everything is available. Two icons means
> exactly two things are down, and both are counting back to you.

The dim-while-down shading went with it. Under the new rule every icon you can see is on
cooldown *by definition*, so desaturating all of them would grey the whole row and make the
abilities harder to tell apart. Full colour plus the number reads better.

**Mangle (Bear) is the exception and keeps its always-on icon and its orange ready-glow**, for
the same reason the glow exists at all: it is the bear's every-six-seconds press, and the glow
is not a status light, it is the instruction *press this now*. An icon that hides itself while
the ability is ready can never fire that instruction — hiding the button you press most often
would trade a "press this now" signal for a "you cannot press this" one, which is the wrong
direction. It keeps its dim-while-down shading too, because it is the one icon that is still on
screen while it is down.

One small fix rides along with it: **the ready-glow now goes quiet out of combat.** Previously a
bear standing in Shattrath sat looking at a permanently lit Mangle icon, which is the fastest way
to teach yourself to ignore a glow. It is driven by a second, always-active trigger that only
reports whether you are in combat; the icon, the swipe and the tooltip are unchanged.

| Cooldown | v6 behaviour | Why |
|---|---|---|
| **Mangle (Bear)** | **always on**, dims while down, **orange glow the instant it is ready** (in combat) | 6s cooldown, "use Mangle whenever available" — the press the whole bear rotation is built around |
| Enrage | on cooldown only | a *pre-pull* rage generator that strips your armour; it was already out-of-combat gated, and absence now answers "can I open with it again" |
| Frenzied Regeneration | on cooldown only | emergency healing, and the alert flow already owns its moment (HP < 40% *and* ready). The row only needs to answer "when does it come back" |
| Swiftmend | on cooldown only | it **consumes** a Rejuvenation or Regrowth, so pressing it on sight throws away a HoT that was already healing. It is a burst/emergency button, not a rotation button |
| Nature's Swiftness | on cooldown only | a 3-minute emergency instant-cast enabler — never a loop press |
| Force of Nature | on cooldown only | a 3-minute summon you deliberately **hold**: the treants want a target that lives 30s and no AoE that kills them, so "it is up" is not "cast it" |
| Barkskin | on cooldown only | a defensive, pressed at a moment; it also breaks shapeshift in 2.4.3 (already hidden from feral) |
| Innervate | on cooldown only | a mana cooldown that already has its own prompt at < 20% mana; likewise breaks shapeshift, likewise hidden from feral |

Per spec that means a **bear** in combat sees Mangle (glowing when ready) plus a Frenzied Regen
icon only while it is down; a **resto** druid sees an empty row until they spend something, then
Swiftmend / Nature's Swiftness / Barkskin / Innervate counting back; a **moonkin** likewise for
Force of Nature / Barkskin / Innervate. Nothing else in the pack changed — the load gates,
including the PvP and shapeshift ones, are untouched.

## v5 — the CC prompt answers itself

**No new auras, no removed auras, no moved auras.** v5 is two behaviour changes on two
existing elements, both of them things v4 wrote down as *unverified and therefore not shipped*.
Both have since been settled against the WeakAuras source, so they ship now. Every UID is
identical to v4 and the import dialog offers a clean **Update**.

### CC on Me now tells you *which* break works, in colour

v4's prompt answered "something has control of you" and left the rest to you. Under a 6-second
fear you do not read an icon, and you certainly do not read text — you see a colour. So the
glow is now colour-coded by the loss-of-control **category**, and each colour is a different
instruction:

| Colour | Category | What to press |
|---|---|---|
| **Red** | Stun (`STUN`, `STUN_MECHANIC`) | **Trinket.** It is the only answer a druid owns — you cannot shift out of a stun. |
| **Purple** | Fear (`FEAR`, `FEAR_MECHANIC`) | **Trinket.** 2.4.3 gives a druid no fear break of its own; there is nothing else. |
| **Blue** | Root (`ROOT`) | **A movement answer, *not* the trinket.** Any shapeshift clears roots and snares — Travel Form, Cat, back to Bear. Spending a 2-minute trinket on a root you can shift out of for free is the single most common druid arena mistake. |
| **Green** | Confuse / Polymorph (`CONFUSE`) | **Ride it.** Any damage breaks it, your team is already breaking it, and trinketing here throws the cooldown away for nothing. |
| **Amber** | Silence / lockout (`SILENCE`, `PACIFYSILENCE`, `SCHOOL_INTERRUPT`) | **Trinket *earlier* than you otherwise would.** A Nature lockout takes Cyclone, Entangling Roots, Healing Touch, Regrowth and Innervate all at once — your whole kit is one school. Waiting out a lockout costs more than waiting out a stun. |

Anything not in that list (charm, possess, disarm, pacify) keeps the red default, which reads
correctly as "trinket food".

These are **the same five colours the mage pack uses**, deliberately. If you play both, you
learn one language, not two.

The trigger itself is unchanged and still carries **no category filter**, so it keeps catching
the one thing no aura tracker can ever see: a Kick / Counterspell **school lockout**, which is
not a debuff. The colour comes from nine conditions on the trigger's stored `controlType`, and
the prototype stores that variable whether or not the trigger filters on it.

### Threat bars no longer load in an arena

There is no threat table in an arena, so both threat bars sat there pinned and meaningless,
taking the bottom bar slot in the one place screen space matters most. They are now gated to
load **everywhere except an arena**: open world, dungeon, every raid size, and battlegrounds
(a BG has NPCs and a real threat table, so the bar keeps working there).

v4 refused to ship this and said so in writing, because WeakAuras has no "not arena" key — the
`size` load argument declares no inverse flag, so the only spelling is to list every *other*
instance type, and it was not proven what `size` is in the **open world**. If that value were
`nil` rather than a listed string, the gate would have silently unloaded the threat bars for
every questing druid: a PvE regression traded for PvP tidiness.

It has now been read out of the source. `GetInstanceTypeAndSize` ends with an explicit
`return "none", "none", nil, nil, 0` that sits *below* the `if inInstance or instanceType ~=
"none"` guard, so outdoors `size` is the literal string `"none"`, never nil. Listing `none`
keeps the bars loaded everywhere in PvE, and the gate is safe. Nothing else in the pack moved.

## v4 — PvP layer

Six new elements and one new sub-group. **Every one of them is gated on the instance type**,
so they exist only inside an arena or a battleground.

**Nothing changes in PvE.** Not one v1–v3 element was added to, removed, reordered or
re-gated: in a raid, a dungeon, the open world or a 5-man the pack loads exactly the v3 set,
pixel for pixel. The gate is WeakAuras' `size` load argument in multi mode
(`use_size = false, size = { multi = { arena = true, pvp = true } }`), the only PvP instance
keys that can ever match on TBC. Two of the six read `arena1..arena5` and are therefore
**arena-only** (`size = { multi = { arena = true } }` — those unit ids do not exist in a
battleground, where the element would be a permanently blank slot). Each child carries its own gate — a group's load condition is not a
child gate in WeakAuras — which is also what lets the dynamic groups collapse their gaps.

### New prompts, in the existing Alerts flow at `(-150, 96)`

- **CC on Me** — appears the instant anything takes control of your character, wearing that
  effect's own icon with the remaining time under it. The decision it changes is *ride it or
  spend the trinket*: a 2s Bash you sit through, a 6s Kidney Shot with your healer already
  dead you break. It uses WeakAuras' **Crowd Controlled** trigger with no category filter, so
  it also catches the one thing no aura-based tracker can ever see — a **Kick / Counterspell
  school lockout**, which is not a debuff. No combat gate: the opening Sap lands before combat.
  **v5 colour-codes the glow by category** so the colour names the answer before you read the
  icon — see [v5](#v5--the-cc-prompt-answers-itself).
- **Barkskin (Stunned)** — appears only when you are **stunned** *and* Barkskin is off
  cooldown. Barkskin's 2.4.3 tooltip reads "Can be used while stunned", which makes it the one
  button a stunned druid still has, and it is exactly the button nobody remembers at the
  bottom of a stun chain. Inverse-gated like every other Barkskin element here (v3): the spell
  cannot be cast while shapeshifted and you cannot shift out while stunned, so a feral would
  be looking at a prompt for a button that does not exist.
- **Target Immune** — appears when your current target gains a hard defensive: Divine Shield,
  Blessing of Protection, Ice Block, Cloak of Shadows, Bestial Wrath / The Beast Within. The
  matched buff supplies the icon, so you read *which* one and act: stop the burst and re-pool,
  swap, or (Bestial Wrath) do not throw the Cyclone that is about to fail. Mitigation
  cooldowns are deliberately absent — Barkskin, Shield Wall and Pain Suppression change how
  much your damage is worth, not whether pressing the button is worth a GCD. TBC's Deterrence
  is +25% parry / +25% dodge, not an immunity, so it is not here either.

### New state column — `Druid - PvP` at `(150, 96)`, growing down

A dynamic group mirroring the Alerts flow on the other side of the character. It is empty
when there is nothing to say.

- **PvP Trinket Down** — visible *only while your trinket is on cooldown*, desaturated, with
  the countdown on the swipe. Absence means ready, which is the state you want to be able to
  check without reading anything. It matches the six trinkets a druid can actually equip by
  **item id** (both Medallions, the two 2.4 all-class Medallions, and both druid Insignias),
  not by equipment slot — a slot tracker would report "trinket down" while a PvE on-use
  trinket in the other slot ticked, and that false negative is a death in the one decision
  this element exists for.
- **Enemy Trinket** *(arena only)* — one icon per opponent, counting **120 seconds** from the
  moment you see them use their trinket. The flash is worthless; the countdown is the whole
  point, because it tells you when a real Cyclone → re-Cyclone → kill chain will actually
  stick. Note what this is: an **inference**, not a read (see the caveats below).
- **CC Out** *(arena only)* — one icon per opponent carrying **your** Cyclone or **your**
  Entangling Roots (including the Nature's Grasp ones), with the time left. Both effects mean
  the same thing and it is the single most expensive druid mistake in arena: a cycloned target
  is immune to **all** damage and healing, so every point you send at it is thrown away, and
  roots break the moment they take damage. The timer is the window you just bought on the
  *other* target. Own-only — somebody else's roots are not your clock. Bash and Maim are
  deliberately **not** in this row: a stun is exactly when you should be pouring damage in, so
  putting stuns in a "stop hitting that" row would invert its meaning.

### What this is not

- **This is not diminishing-returns tracking.** There is no DR in this pack, and none is
  faked. WeakAuras ships no DR primitive on TBC — no prototype, no library — and the usual
  fake (an 18-second timer after a CC) models the reset window rather than the category, so it
  is simply wrong the moment two spells share a category. An incomplete DR tracker is worse
  than none because it gets trusted. Count your own Cyclones.
- **Enemy cooldowns cannot be read on 2.5.x**, so the Enemy Trinket countdown starts only when
  the cast is *seen*: if an opponent trinkets while you are dead, cycloned or looking
  elsewhere, nothing starts. 120s is the Medallion cooldown every level-70 arena player
  carries; a low-level battleground opponent on a 5-minute Insignia would show ready early.
- **Enemy spec is unreadable** on TBC (enemy *class* is, enemy spec is not), so nothing here
  branches on "is that a resto druid".
- **Druids get no interrupt prompt.** The pack's sibling packs get one built on "target is
  casting AND my interrupt is usable"; a druid has no castable interrupt to hang it on, and
  "can I interrupt this cast" does not exist as a filter on TBC at all — WeakAuras disables it
  on this client.
- **The Crowd Controlled trigger wants one live smoke test.** WeakAuras deleted that prototype
  on BCC in 3.5.0–5.1.x and un-deleted it in 5.2.0; a current client registers it, but the
  WeakAuras source cannot prove the 2.5.x client populates the `C_LossOfControl` API behind it.
  Get sapped and kicked in a duel once. If it turns out dead on your client, the two elements
  that use it (CC on Me, Barkskin (Stunned)) simply never appear — nothing else is affected.
- ~~**PvE furniture is not suppressed inside arena.**~~ **Fixed in v5.** The threat bars now
  carry an inverse `size` gate and do not load in an arena. v4 held this back because the
  open-world value of `size` was unverified and a wrong guess would have unloaded the bars for
  every questing druid; it is the literal string `"none"`, so enumerating the complement is
  safe. See [v5](#v5--the-cc-prompt-answers-itself).

## v3 — each spec loads only what it presses

v2 gated on *"can this spec cast it"*. The correct test is *"does this spec **press** it as
part of playing well"*, and by that test the bear inherited three elements it can never act
on. v3 fixes exactly that; **no element was added, removed or reordered**, so every UID is
identical to v2 and the import dialog still offers **Update**.

**Feral (bear) no longer sees Barkskin, Innervate or the Innervate prompt.** Both spells carry
the `Cannot be used while shapeshifted` flag in 2.4.3, and there is no auto-unshift — pressing
either as a bear means dropping bear form first, i.e. giving up the armour multiplier and the
Dire Bear health bonus mid-pull. Icy Veins' TBC feral tank guide puts it plainly: Barkskin
"takes you out of form when used, making it only usable while you are **not actively tanking**".
The Innervate prompt was the worst of the three: it fires at under 20% *mana*, and a bear's mana
neither pays for nor gates a single thing it presses, so on any long fight it sat lit in the
alert flow demanding a button that costs the tank its form. A bear's cooldown row is now Mangle,
Enrage (out of combat) and Frenzied Regeneration — three buttons, all pressable in form.

Restoration and Balance keep all three: Tree of Life form explicitly whitelists Innervate,
Nature's Swiftness, Rebirth, Swiftmend, Barkskin and the HoTs, and Innervate is the mana
decision of a caster druid's fight. Balance keeps Barkskin as a deliberate marginal call —
Moonkin Form blocks it too, so it costs a form drop, but it is the spec's only damage-reduction
cooldown and the shift-out-and-heal flow it belongs to is real, especially in PvP.

**Deliberately kept everywhere.** The **health bar** stays ungated: it is the bear's paired
state for the Frenzied Regen prompt at 40%, and for the caster specs it is the number both
Barkskin and "stop casting and heal yourself" key off. **Clearcasting** and the **OoC Missing**
nag stay gated on Omen of Clarity's own spell id (16864) rather than on a spec: the talent is
melee-proc'd and so mostly a feral pick, but TBC Balance builds do spend into it (41/0/20), and
the rule for a shared gate is the ability, not the tree — if you spent the point, the pack
shows you the buff you forgot to cast and the free cast when it lands.

**Requires WeakAuras 5.4.0+ for the inverse gate.** `not_spellknown` does not exist in older
builds; there the field is ignored and those three elements simply load for everyone again —
v2's behaviour — so nothing breaks, the bear just gets its three dead icons back.

## v2 — rotation fixes

v1 was a solid tracker collection that left three rotation lines unrendered and mis-signalled
four more. v2 fixes what an adversarial rotation review confirmed, judged against one
standard: *does this element change which button gets pressed next?*

**Bear**

- **Rage thresholds on the rage bar.** Two thin lines sit over the bar where the two spend
  decisions live — `20` (a Mangle is affordable; below it, do not spend on anything else) and
  `70` (you have room for Maul *and* the next Mangle and will still cap — dump it). Each has a
  wider, fully-lit twin that pops in the instant you cross it. v1 printed the rage number and
  nothing else.
- **Maul prompt.** Maul is off the GCD, has no cooldown and is *pure* rage-dump, so the only
  question is "am I about to waste rage". The prompt appears in the alert flow above 70 rage
  and leaves when you have spent it. (No swing timer is involved — the trigger is the rage
  value, nothing else.)
- **Demoralizing Roar** is now tracked, on the fourth bear buff slot. It is the bear's joint
  priority #1 with Faerie Fire and v1 tracked neither the debuff nor any of its six ranks. It
  is deliberately **not** own-only: any druid's roar satisfies the −240 AP debuff.
- **Mangle now glows when it is ready.** It is the every-6-seconds press, so it gets the
  orange pixel glow the moment the cooldown clears, on top of the desaturate-while-down
  readout every other cooldown icon has. v1 shipped an inert glow no condition ever lit.
- **Lacerate is desaturated below 5 stacks.** Colour coming back *is* "the stack is capped,
  stop feeding it"; v1 printed the stack count as text and never changed state at cap.
- **Enrage loads out of combat only.** It is a pre-pull rage generator that also strips your
  armour, so mid-fight it is a button the tank must not press. v1 showed it always.

**Restoration**

- **Tree of Life Missing** is a new alert. "Be in Tree of Life whenever possible" is the
  spec's priority #1, and the form blocks Healing Touch and Tranquility — so the prompt after
  an emergency shift-out is exactly the moment you need reminding to shift back. Gated on the
  41-point talent (33891) and combat-gated, so it is silent for anyone who did not take it.
- **Rejuvenation and Regrowth glow under 3s.** v1 gave both an inert glow sub-region no
  condition ever lit, so the two refreshable HoTs signalled only present/absent — no refresh
  window, and no warning that your Swiftmend fuel was about to vanish.
- **Lifebloom is desaturated below 3 stacks**, so "roll it to a triple stack" is a state, not
  a number to read.

**Balance**

- **Faerie Fire (Balance) is now own-only.** A feral druid's Faerie Fire (Feral) satisfies the
  armour debuff but supplies no Improved Faerie Fire, so v1's shared tracker went green while
  the raid was quietly missing the +3% hit that is the moonkin's priority #1.
- **Insect Swarm lost its refresh glow.** TBC Balance refreshes Insect Swarm *only while
  moving*, and WeakAuras cannot see movement without custom code, so an unconditional
  "refresh now" glow was wrong most of the time. The timer stays; the instruction is gone.

**All specs**

- **Omen of Clarity Missing is no longer combat-gated.** Omen of Clarity is a 30-minute
  out-of-combat buff that cannot even be cast while shapeshifted, so a combat gate meant the
  nag could only ever fire at the one moment you could not act on it.

Known gaps, deliberately left for a future version rather than guessed at: AoE lines (bear
Swipe, Balance Hurricane), raid-wide HoT tracking (this pack is single-target: it follows your
current friendly target), a purpose-built Cat rotation, and pre-70 levelling coverage. See
[Not covered](#not-covered).

## The Sill — `Druid - Player Sill` at `(0, 30)`

Since **v15** this group holds **one strip** — The Sill — instead of v12–v14's ring cluster (the
v10–v11 globes before that, the v8–v9 clusters before them, and the v7 bar stack before those).
It is the same group table with the same uid, renamed for the fifth time; **it did not move.**
`(0, 30)` inside the top-level group at `(0, -140)` sums to absolute **`(0, -110)`**, which is
directly under your character and is exactly where the strip belongs, so v15 only had to stop
the nine children carrying a local `(-270, +150)` each.

| | absolute anchor | lane 1 | lane 2 | lane 3 | backdrop |
|---|---|---|---|---|---|
| the Sill | `(0, -110)` | **160 × 5** threat | **160 × 13** health | **160 × 13** power | **164 × 36** plate |

Those are **absolute** coordinates for the group; every region below carries a *local* offset
inside it, listed in the [v18 section](#v18--long-and-thin-not-big). `generate.lua` converts
absolute → local in exactly one place and then re-walks the assembled string and asserts the
group's anchor, each lane's offset, each rail's size, the 1 px gutters between lanes, the even
1.5 px margins above and below the stack, and every mark's position — before it will write a
file. Nine auras in all: four rails (two of them the mutually exclusive threat pair), one plate,
four rage waterlines.

**The rail is 160 px long, i.e. 1.6 pixels per percent** (v18). It is long because the fill's
*travel* is the signal, and thin (13 px) because the fill's thickness carries nothing — a
uniformly scaled strip reads as a UI panel rather than as a readout, which is what the sibling
packs proved twice. 160 rather than a rounder number because every value this pack marks is a
multiple of five and 1.6 × 5 = 8, so every breakpoint still lands on a **whole pixel**:
`x(v) = (v / maxpower − 0.5) × 160`, giving 20 rage at `−48`, 70 at `+32` and the ruler at
`−40 / 0 / +40`.

**`x = 0` is not an eyeballed number either.** The Alerts column occupies `x −170…−130` and the
PvP column `x +132…+168`; both are *vertically growing* dynamic groups, and both are separated
from the strip's `x −82…+82` by 48 px at any stack depth (a dynamic group with
`align = CENTER` and `stagger = 0` cannot move a clone sideways). Vertically the strip spans
`y −89…−125`, with nothing at all above it and **11.0 px** of clearance to the buff row at
`y −176…−136`. The build projects every dynamic group six clones deep, asserts zero overlaps
against all 30 other drawn regions in the pack, and separately runs an **all-pairs check across
the four flanking stacks** — the one thing a sill-versus-everything scan cannot see.

Every rail is a `progresstexture` in **`HORIZONTAL`** orientation — the left-anchored fill that
grows rightward — on the bundled `Square_White.tga`. The trap lives in that one token: the
dropdown label lies, captioning `HORIZONTAL_INVERSE` as "Left to Right" when it is the
*right*-anchored one. `LinearProgressTexture.lua` is the authority, and v17 fixed the
transcription after a live check. `startAngle` / `endAngle` are ignored on this linear path (they were the
full circle on the ring path) and are emitted only for the schema; `crop_x / crop_y = 0.41` is
the texcoord scale here rather than the circular identity it was, and with a uniform white quad
it cannot alter the art at all. `backgroundOffset 0` keeps the unfilled part of the rail exactly
the same quad as the fill instead of a halo around it. The unfilled part is black at 55% alpha
on every rail, which is what makes a half-empty rail read as *half* rather than as a bar that
shrank.

The rails are **not** aurabars, and that is a decision rather than an accident. An `aurabar`
requires `subRegions[1] = { type = "aurabar_bar" }`, which would push every existing sub-region
index up by one and silently retarget any condition that addresses one. `subtexture` is proven
on a `progresstexture` in this repo and unproven on an aurabar. And the conditionable tint on a
progresstexture is `foregroundColor`, where an aurabar wants `barColor` — and `Conditions.lua`
skips a change whose property the region does not have, silently and with no editor warning, so
a mechanically ported escalation would simply never fire.

The **Sill Plate** is a plain `texture` region: `Square_White_Border.tga` at 164 × 36, tinted
black at 45% alpha, at `frameStrata 2` — WeakAuras' `BACKGROUND`, the *lowest* strata — and
**first** in `controlledChildren`, i.e. the bottom of the frame-level stack. Both of those say
the same thing: the plate is the backdrop and everything else is drawn on it. It carries the
uid, the trigger pair and both alpha conditions of the v8–v14 3D portrait, so the whole
instrument appears, fades and vanishes as one object. Its colour is written out explicitly,
because on a `texture` region the tint field is `color` and leaving it empty draws in
WeakAuras' default rather than the intended shade.

**Always loaded**, for every spec and every level:

- **Health**, the 160 × 13 lane-2 rail in green, with `%percenthealth` printed **inside it at
  `x = +51`, 12 pt** — the widest string it ever prints, `100%`, spans `+35…+67`, still 13 px
  inside the rail's right edge, and 12 pt fits inside the 13 px lane it prints in. White with an
  `OUTLINE` and a black shadow, over the plate. It
  keeps the low-health escalation added in v8: **amber under 50%, red under 25%** (severe
  condition last, so it wins), plus a `maxhealth <= 0 → alpha 0` guard, because a
  progresstexture with a zero total draws a *full* bar rather than an empty one. `sub.2–4` are
  the **ruler**: three 2 px hairlines at 18% white, at 25% / 50% / 75% — `x −40 / 0 / +40`.
- **Power**, the 160 × 13 lane-3 rail, with `%percentpower` at **12 pt, `x = +51`**. Its Power
  trigger omits `use_powertype` entirely, so WeakAuras resolves the type from
  `UnitPowerType(unit)` at runtime and the rail follows every shapeshift — the trigger registers
  `UNIT_DISPLAYPOWER` unconditionally, so the switch is immediate. The resolved type is a stored
  conditionable value, which is what drives the colour, and the rail is always coloured for the
  resource it is actually reading: **blue mana** as the base (caster, tree, moonkin), **red**
  when the type resolves to rage (bear), **yellow** when it resolves to energy (cat). Because
  rage and energy both cap at 100, on a 0–100 scale the percentage *is* the absolute value, so
  for a bear the number and the scale finally agree. Same ruler at `sub.2–4`.
- **The plate**, 164 × 36, behind all of it.

Both rails and the plate carry the extra Unit Characteristics trigger that has fed the
out-of-combat fade since v1 and drop to **50% alpha out of combat**.

**Threat is the 160 × 5 top lane, and it is *yours*** (v13 — before that it was the target
cluster's outer ring). Two mutually exclusive auras share that one lane, as they have since v7,
and at most one of them ever loads:

- the **bear** rail (Feral-gated, Bear-form-gated) is tank-inverted: green while you are
  securely tanking, **red the moment aggro is lost**;
- the **caster** rail (Balance-gated) is green, **orange at 70%** of the pull threshold and
  **red when you pull**.

`sub.2` on both is a 2 × 5 white **notch at `x = +32`** — the 70 line, from the same `waterX()`
the rage waterlines use. It stays a 2 px hairline because against a 5 px rail it already is one,
and widening it would turn the top lane into a two-tone bar. For the caster that is the ceiling
to stay under, and the
orange condition fires on exactly that value; for the bear, whose semantics are inverted, it is
the floor to stay above. The `%threatpct` number is still `sub.1` but ships **switched off**
(`text_visible = false`) and parked at the left end (`x = −32`) so re-enabling it in `/wa` does
not land a second number on the health percentage. `threatpct` is scaled so 100 = pulling aggro,
which makes it a ratio rather than a quantity, and a notch answers "am I close" faster than
reading 68 against 72.

Every one of those recolours is on **`foregroundColor`**, the progresstexture spelling. It is
`barColor` on an aurabar and `color` on a plain texture, and `Conditions.lua` skips a change
whose property the region does not have, silently and with no editor warning, so a mechanically
ported escalation would simply never fire.

Both threat rails carry, since **v5**, an **instance-size gate that excludes arena**
(`use_size = false, size = { multi = { none, party, ten, twenty, twentyfive, fortyman, pvp } }`
— every TBC instance type *except* `arena`). An arena has no threat table, so the rail would be
pure clutter in the one place screen space is scarcest; everywhere else, including the open
world (`size` is the string `"none"` there) and battlegrounds, it behaves as it did in v4. Both
also carry a `threatvalue <= 0 → alpha 0` guard: `threattotal` is derived from `threatvalue`, so
it is zero exactly when your threat is zero — post-Vanish, post-Feign, before your first hit —
and without the guard the rail would read as **full aggro** at exactly that moment. Their trigger
reads the **target**'s threat table via the era-correct `threatUnit` argument (v13 dropped the
`unit` field v12 also emitted: that spelling only exists from `internalVersion` 51 on, and
Modernize renames the old one forward on load), so with no hostile target there is no state and
the rail is not drawn at all.

**There is no alarm frame in this pack.** The Sill design gives the 80%-threat pulse to a
`<Pack> - Threat Flash` aura; this pack has never had one — decoding v12 for `alphaPulse`
returns zero hits — and inventing one would have meant consuming a new uid for a region that has
never existed here. The 70 notch and the aggro-red rail are the escalation this pack ships,
exactly as they were.

Four bear-only **rage waterlines** sit on the power rail. On a rail a threshold is one
subtraction — `x(v) = (v / maxpower − 0.5) × 160` — so **20 rage** (the cost of a Mangle, the
reserve you never spend below) is a line at `x = −48` and **70 rage** (where Maul plus the next
Mangle still leaves you capping) is a line at `x = +32`, both spanning the rail's full 13 px
height and both on whole pixels. Each is a 4 px dim
line with an 8 px opaque twin that **pops in over 0.25 s when you cross its value** and fades when
you drop back under, so the crossing itself is the signal. They stay four separate auras rather
than sub-regions because the aurabar tick sub-region does not support a progresstexture at all
and the two sub-region types that do cannot carry their own animation — and the pop *is* the
point. They were round dots on the v12–v14 ring only because a rotated quad rotates the *art
inside* the quad, so a straight line could never be laid along an arc; across a horizontal rail
no rotation is needed. Both coordinates are derived from the canonical constants, so the lines
follow the rail if those numbers ever move. They only exist while you have rage, i.e. in bear
form.

## Buffs — icon row at `(0, -16)`

40x40 timers on shared slots, each with the WA cooldown swipe plus a `%p` seconds text. The
caster specs use three slots at `x = -44 / 0 / 44`; the bear uses four at `x = -66 / -22 / 22 /
66`, both rows centred on the group, and only one spec's row ever loads.

Bears get **Lacerate** (own bleed, big centred `%s` stack count, desaturated until it hits 5
and glowing when under 5s left), the **Mangle (Bear)** debuff timer (all three ranks, uptime
awareness — the actual press lives on the cooldown row), **Faerie Fire** — matched against both
the regular and Feral rank sets and *not* own-only, because anyone's armour debuff satisfies
the bear's rule — and **Demoralizing Roar** (all six ranks, likewise not own-only), which
glows under 5s like Faerie Fire does.

Restoration gets **Lifebloom** on your friendly target (stack count plus timer, desaturated
below a triple stack and glowing in the last 2s — that glow *is* the rolling-refresh window),
plus own-only **Rejuvenation** (all 13 ranks) and **Regrowth** (all 10 ranks) HoT timers,
which glow under 3s and double as your Swiftmend fuel check.

Balance gets **Insect Swarm** (a plain uptime timer — no refresh glow, because the TBC rule is
"refresh only while moving" and no zero-custom-code trigger can see movement), **Moonfire**
(deliberately **no** expiry glow either: TBC guides want it to fully expire before you recast,
so the icon simply vanishing is the signal), and an **own-only Faerie Fire** tracker, which
glows under 5s. Own-only matters here and only here: a feral's Faerie Fire (Feral) blocks your
cast without supplying Improved Faerie Fire, and you need to see that.

## Alerts — animated prompts at `(-150, 96)`

A dynamic group that grows upward; each prompt slides in from below over 0.3s and, on expiry,
flies up 150px while fading and shrinking to 40%. The **Frenzied Regen Prompt** (bear) needs
HP < 40% *and* Frenzied Regeneration off cooldown before it appears — appearance itself is the
instruction. The **Maul Prompt** (bear) appears above 70 rage: Maul is off the GCD and has no
cooldown, so excess rage is the entire decision. **Clearcasting** lights up with a gold glow
and a 15s swipe whenever Omen of Clarity procs a free cast. **Innervate Prompt** appears at
under 20% mana with Innervate ready, for every druid *except* a feral one (v3: a bear cannot
cast Innervate in form, and its mana pays for nothing it presses). **Tree of Life Missing** nags a talented
resto druid who is in combat out of form. Those five are combat-gated; **OoC Missing** is not,
because Omen of Clarity is a 30-minute buff you can only apply *outside* combat and while not
shapeshifted — it nags in red whenever the buff is absent, and the fix is one cast.

Three more prompts share this flow **only inside an arena or battleground** — **CC on Me**
(whose glow colour names the break: red/purple = trinket, blue = shapeshift out, green = ride
it, amber = your school is locked out), **Barkskin (Stunned)** and **Target Immune**. See
[v5](#v5--the-cc-prompt-answers-itself) and [v4 — PvP layer](#v4--pvp-layer); in PvE they do
not exist.

## Cooldowns — icon row at `(0, -66)`

A horizontally-centred dynamic group of 32x32 icons; the WA cooldown text is enabled, mouseover
shows the real spell tooltip, and hidden icons collapse their gaps automatically. Since **v6**
the row shows what you **cannot** press: the seven situational cooldowns are visible *only while
they are on cooldown* and vanish when the ability returns, so an empty row means everything is
available (see [v6](#v6--the-cooldown-row-shows-what-you-cannot-press)). **Mangle** is the
exception to that rule as well as to the "quiet readout" one — it is the bear's every-6-seconds
press, so it stays on screen at all times, desaturates while down, and carries an orange pixel
glow that fires the instant it comes off cooldown (and stays dark out of combat). **Enrage** is
bear-gated *and* out-of-combat-gated: it is a
pre-pull rage generator whose armour penalty makes it a mistake mid-fight, so it simply is not
on screen once the fight starts. Restoration sees **Swiftmend**; **Nature's Swiftness** and
**Force of Nature** gate themselves on their own talent (so a talented hybrid correctly gets
them alongside another spec's row); **Barkskin** and **Innervate** show for every druid *except*
a feral one. Both carry the `Cannot be used while shapeshifted` flag in 2.4.3, so a bear must
drop form — and its armour multiplier and Dire Bear health — to press either; v3 gives them an
inverse load gate (`not_spellknown` = Mangle (Bear), 33878) so they no longer take up two slots
in a tank's cooldown row. Tree of Life whitelists both, and a moonkin can drop form for them.
Per spec the row *contains* Feral → Mangle, Enrage (out of combat), Frenzied Regen ·
Resto → Swiftmend, Nature's Swiftness, Barkskin, Innervate · Balance → Force of
Nature, Barkskin, Innervate — but from v6 on, all of those except Mangle are only *drawn* while
they are counting back down.

## Spec gating

| Gate | Spell ID | Gates |
|---|---|---|
| Feral tank — Mangle (Bear), 41 pts + Bear form 1 | 33878 | The four rage waterlines, bear threat rail, Lacerate, Mangle debuff, bear Faerie Fire, Demoralizing Roar, Frenzied Regen prompt, Maul prompt, Mangle / Enrage / Frenzied Regen cooldowns |
| Restoration — Swiftmend, 31 pts | 18562 | Lifebloom, Rejuvenation, Regrowth, Swiftmend cooldown |
| Restoration — Tree of Life, 41 pts | 33891 | Tree of Life Missing alert |
| Balance — Moonkin Form, 31 pts | 24858 | Caster threat rail, Insect Swarm, Moonfire, balance Faerie Fire |
| Omen of Clarity, 11 pts | 16864 | Clearcasting proc, OoC Missing alert |
| Nature's Swiftness | 17116 | Nature's Swiftness cooldown |
| Force of Nature | 33831 | Force of Nature cooldown |
| **Inverse** — *not* Mangle (Bear) | not 33878 | Barkskin cooldown, Innervate cooldown, Innervate prompt (v3: hidden from feral) |
| Barkskin | 22812 + not 33878 | Barkskin (Stunned) PvP prompt |

The last row is an inverse gate: `use_not_spellknown = true, not_spellknown = 33878`, which WA
compiles to `not WeakAuras.IsSpellKnownForLoad(33878, false)`. `use_exact_not_spellknown` is
deliberately left unset so the rank-1 id resolves through the spell *name* and matches every
rank of Mangle (Bear) — and only Mangle (Bear), since Mangle (Cat) is a different name. It
needs **WeakAuras 5.4.0+**; older builds ignore the unknown field, which just restores v2's
"loads for everyone" behaviour rather than erroring.

Combat gates on top of those: the Frenzied Regen, Maul, Clearcasting, Innervate and Tree of
Life prompts load **in** combat only, and the Enrage cooldown icon loads **out** of combat
only (WeakAuras load booleans are tri-state — `use_combat = false` means "must not be in
combat"). OoC Missing carries no combat gate at all.

Ungated by spec: the whole sill layer except the two threat rails — your health rail, your power
rail and the plate load for every druid at every level, which from
**v8** is the first time a Feral in Cat form has any resource display at all. Plus the five v4 PvP elements
that carry no talent gate — those are instead gated on the **instance type**, so in PvE they load
for nobody. `tools/spec-preview.lua` evaluates the combined level-70 exemplar profile,
combat/instance load gates, inverse gates and the Bear/Cat form state; its output is the
offline-eligible set, before live aura and cooldown state decides what is currently drawn.

Instance-type gates are a second, independent axis and run in both directions. The six PvP
elements list only the PvP instance types (`arena`, or `arena` + `pvp`), so they exist *only*
there. The two threat rails do the opposite from **v5** on: they list every TBC instance type
*except* `arena`, which is the only way to spell "not arena" — WeakAuras' `size` load argument
declares no inverse flag and no custom test, so multi mode is a plain OR over raw string
equality and the complement has to be enumerated by hand. Both threat rails keep their spec gate
on top of it (Mangle (Bear) for the bear rail, Moonkin Form for the caster rail).
All 39 element children additionally carry the `DRUID` class load gate; the five sub-groups
and the top group carry no load conditions of their own (they inherit visibility from what
they contain — the same arrangement as the field-proven rogue pack).

## Not covered

Named here so nobody assumes they were forgotten:

- **AoE.** No bear Swipe and no Balance Hurricane. Both specs have a documented AoE line; both
  need a target-count decision this pack has no way to render, and Swipe has no cooldown to
  hang a `showOnReady` glow on. It needs a design pass, not a copy of an existing element.
- **Raid-wide HoT tracking.** Lifebloom, Rejuvenation and Regrowth follow your current
  friendly target. Tracking them across every raid member needs cloned auras in a dynamic
  group, which is a different layout, not a flag.
- **Cat-form rotation.** v7 prevents the Bear HUD from leaking into Cat by form-gating all
  Bear elements (15 in v7, 14 from v8 on — the rage bar became the spec-neutral form-adaptive
  power readout and correctly lost its Bear gate). A cat gets a live yellow energy arc where
  v7 gave it nothing, but the pack still does not invent a Cat rotation: powershifting, combo
  points and the Mangle/Shred/Rip decision loop need their own reviewed design before they ship.
  **Combo points are not drawn anywhere** — the Sill has a fourth lane reserved for exactly that
  (16 × 6 pips at 20px pitch) and the rogue pack's row is the design that should be adapted, not
  a colour change here.
- **Energy breakpoints for Cat.** The two rage waterlines are Bear-gated and rage-specific. Cat's
  Shred/Mangle costs would be two more waterlines on the same rail with their own form gate — the
  placement formula takes any fraction — but they are not here because the Cat rotation they
  would serve is not here either.
- **Levelling.** A druid without a 31/41-point talent loads the health rail plus the three
  inverse-gated pieces (Barkskin, Innervate, Innervate prompt — a levelling druid does not know
  Mangle (Bear), so the "not feral" gate passes). Pre-70 coverage is a separate gating pass.
- **Balance keeps Barkskin knowing Moonkin Form blocks it.** Pressing it costs a moonkin its
  form, so in a raid rotation it is close to dead weight; it is kept as the spec's only
  damage-reduction cooldown and because the PvP shift-out-and-heal flow it belongs to is real.
  A genuinely 50/50 call, kept rather than cut.
- **Clearcasting / OoC Missing are gated on the talent, not on a spec.** Omen of Clarity procs
  from melee attacks, so it is overwhelmingly a feral pick, but TBC Balance builds do spend into
  it (41/0/20) and a shared element gates on the ability, not on the tree. If you took the
  point you see the proc and the "you forgot to buff it" nag; if you did not, you see neither.
- **Diminishing returns (v4).** Not tracked, not approximated — see
  [v4 — PvP layer](#v4--pvp-layer). Nor is any enemy cooldown other than the trinket
  countdown, which is an inference from a cast you saw rather than a read of their cooldowns.
- **A PvP mana prompt.** The Innervate prompt still fires at under 20% mana, where arena play
  would rather see ~30%. The blocker v4 named is gone — v5 proves the inverse `size` gate is
  safe, so the PvE prompt *could* now be hidden inside arena and a 30% twin added beside it —
  but that is a rotation-design call about the right threshold, not a mechanics question, and
  it is not being smuggled in on the back of a verification fix. Two prompts for one button
  would still be worse than a threshold that is 10% late.
- **Enemy mana is not read.** WeakAuras' Power trigger does work on `arena1..arena5` on 2.5.x
  (one clone per opponent, `powertype = 0` for mana), so a per-opponent enemy mana row is
  buildable — it is simply not a *druid* element. A druid has no mana drain, no Mana Burn and
  no way to punish an empty healer beyond what the health bars already tell it; that row
  belongs to the warlock, priest, hunter and mage packs, which own the buttons it would feed.
- **Bash / Maim windows (v4).** Your stuns are not shown anywhere. They are the opposite
  instruction to the CC Out row (stun = burst now), so they need their own element and their
  own colour, not a seat in a row that means "stop hitting that".

## Importing

Copy the whole string from the code block below (GitHub's copy button on that block is the
easiest path), then in game: `/wa` → **Import** → paste. If you are updating from an earlier
version, WeakAuras matches by UID and offers **Update**; untick the **Arrangement** category
in that dialog if you have dragged the groups somewhere you like, otherwise your positions
snap back to the defaults above. Note that v2 moves the four bear buff icons onto a four-slot
row, so a bear who unticks Arrangement will keep v1's three-slot spacing and see Demoralizing
Roar land on top of Faerie Fire — tick it once for that upgrade, then drag the group back.
v3 changes load conditions only, so it is a clean Update over v2 with no layout consequences —
but a bear on **WeakAuras older than 5.4.0** will still see Barkskin and Innervate, because the
inverse gate that hides them is a field those builds do not know about. v4 adds one new
sub-group (`Druid - PvP`) and six new auras and touches nothing that already existed, so it is
a clean Update over v3 too: every pre-v4 UID is unchanged, and the new group arrives at
`(150, 96)` where you can drag it wherever your arena UI has room. **v5 adds and removes
nothing at all** — it changes conditions on one aura and load settings on two — so it is the
cleanest Update in the pack's history: no layout consequences, and Arrangement can stay
unticked. **v6 likewise adds and removes nothing**: it changes how eight cooldown icons decide
whether to be on screen, so it is another clean Update with Arrangement left unticked — the row
simply starts out shorter, and fills up as you spend things. **v7 is another gating-only Update**:
all existing UIDs remain stable, and Bear elements now disappear when the player shifts to Cat.

**v8 through v15 are the versions where you should tick Arrangement.** v8 is still a clean
Update — every v7 UID survives, because the eleven Resources tables were repurposed in place
rather than deleted and re-created — but the entire resource layout moved from a centre bar
stack to two orbs at `x = ±250`, and with Arrangement unticked WeakAuras keeps the old
coordinates and stacks all six rings on top of each other in the middle of the screen. **v9 adds
and removes nothing at all** — it is purely the orb geometry and the ring texture — but for
exactly that reason Arrangement is the *only* category that carries it: untick it and you keep
the v8 sizes and positions and see none of the change. **v10 is the same story, larger**: the
rings become globes, the clusters move to `x = ±150` and every size changes, so unticking
Arrangement leaves you with v9's ring geometry wearing v10's colours. **v11 adds and removes
nothing at all** — it moves the three globes to `(±190, 40)` and `(0, 110)` and appends one
highlight sub-region to each — so, exactly like v9, Arrangement is the *only* category that
carries the position change: untick it and the globes stay on v10's band under the HUD (you
still get the highlight, which travels with the display data). **v12 is the largest of them
and also adds and removes nothing**: the globes become ring clusters, both cluster positions and
every size change, and the two rims become portraits again — untick Arrangement and you keep
v11's globe geometry wearing v12's region types, which is not a layout anyone wants. **v13 is the
first version that removes auras rather than recycling them**: the target cluster is deleted and
threat becomes a new 100px ring on your own cluster, so untick Arrangement and the threat rings
stay 84px over at `(+270, 110)`, orbiting a cluster that no longer exists. **v14 adds and removes
nothing at all** — it moves two percentage labels and reorders one group's children — but for
exactly that reason Arrangement is the *only* category that carries it: untick it and the health
number stays 54px below the cluster at 13pt, which is the whole thing v14 fixes. **v15 is the
one where it matters most**: the ring cluster becomes The Sill, which renames the group, moves
all nine of its children from `(-270, 40)` to `(0, -110)`, changes four region sizes, re-types
the portrait into a plate and re-orders `controlledChildren` — every bit of that travels in
Arrangement, so unticking it leaves you with v14's ring geometry wearing v15's region types.
Tick it once, then drag `Druid - Player Sill` wherever you want it.

**Nothing to delete after updating to v15**, and nothing was added — the renames, the re-type
and the reorder are all properties of existing tables, and every one of the 45 UIDs is
unchanged (`changed = 0`, `missing = 0`, checked with no removal allowance).

**What to delete after updating, from v13: three auras.** WeakAuras **never deletes an aura that
an import does not mention**, and v13 stops mentioning the target cluster's three regions — so an
Update leaves them behind, still drawing a lone ring cluster at `(+270, 110)`. Delete them by
hand: `/wa` → right-click each of **`Druid - Target Health Ring`**, **`Druid - Target Ring
Track`** and **`Druid - Target Portrait`** → **Delete**. Do **not** delete the group they sit in
(called `Druid - Rings` up to v14 and **`Druid - Player Sill`** from v15) — that is still your
own layer and the rage waterlines'.

Before v13, nothing needed deleting after an update, because no aura had ever been removed: each
constructor drew the same UID and an Update replaced each old region with its replacement in
place. The one exception was and still is importing as **new** rather than Update — or having
renamed or dragged the old group out of the pack — in which case the whole older group survives
alongside the new one and you see *both* layouts at once. Delete the stale group by hand:
`/wa` → right-click it (**`Druid - Resources`** from v7, **`Druid - Unit Orbs`** from v8–v9,
**`Druid - Globes`** from v10–v11, **`Druid - Rings`** from v12–v14, **`Druid - Player Sill`**
from v15) → **Delete**, confirming that it deletes the children too.

One warning about the editor: selecting a group in `/wa` force-shows **every** aura with
fake data — both threat rails, all three specs' buff rows and every rage waterline at once, all
with identical placeholder timers, and the rails sitting at a fake 100%. That is the documented
WeakAuras preview illusion, not a bug. Judge this pack in combat, not in the preview.

## Regenerating

```bash
cd tools/tbc-weakaura-creator/scripts && ./setup.sh   # once: fetches LibDeflate + LibSerialize
cd ../../../tbc/druid && lua5.1 generate.lua          # rewrites all-specs.txt in place
```

`generate.lua` is the single source of truth — never hand-edit `all-specs.txt`. The script
seeds `math.randomseed(20260812)` and draws UIDs in a fixed construction order (top group,
the four sub-groups, then the sill layer → Buffs → Alerts → Cooldowns, then the v2 block, the
v4 block and the v8/v10/v12/v15 block at the bottom of the file), which is what makes a re-import offer
*Update* instead of duplicating the pack. Keep that seed and never reorder or remove an existing
element's construction — **and note what "never remove" means from v13 on**: where a region is
genuinely deleted, its `W.uid()` call stays where it was and the value is thrown away (a *retired
slot*, marked as such in the source). The stream is positional, so dropping the call outright
would renumber every UID drawn after it and turn the next import into a duplicate rather than an
Update. New auras append their constructor calls at the end and are
re-parented into the right group there — which is why the v2, v4 and v8 additions are built last
and not next to their siblings. v3 added no constructors at all — it only set load fields on
three existing elements — so the uid stream is untouched, and **v5 likewise adds no
constructors** (nine conditions on one aura, a load gate on two), neither does **v6** (a
trigger flag and the conditions on the eight cooldown icons, plus one extra trigger on Mangle),
and **v7** only appends a form-state trigger to the 15 existing Bear elements. **v14 adds no
constructors either** — two subtext offsets, two font sizes, and one `adopt()` call swapped for
`adoptFirst()`. That last one is worth stating plainly, because it is the only kind of edit in
this file that *looks* like reordering and is not: `controlledChildren` order is DISPLAY order
and is written by the `adopt` helpers, while UID order is CONSTRUCTION order and is written by
where a `W.uid()` call sits. Moving a child between the front and the back of its group touches
the first and cannot touch the second.

**v8 is the first version that changes what an existing constructor builds**, and the rule it
follows is worth stating because the rest of the repo will need it. `W.assertUidContinuity`
fails the build if *any* previously shipped UID disappears, and rightly so: a deleted aura's UID
is gone forever and the in-game Update flow cannot reconcile it. So the eleven v7 Resources
tables were not deleted and re-created — each constructor still draws **the same UID at the same
position in the seeded stream**, and only the region type, id, geometry and triggers changed:

| uid slot | v7 | v8 |
|---|---|---|
| 2 | `Druid - Resources` (group) | `Druid - Unit Orbs` (group) |
| 6 | `Druid - Health` (aurabar) | `Druid - Player Health` (progresstexture) |
| 7 | `Druid - Rage` (aurabar) | `Druid - Player Power` (progresstexture) |
| 8 | `Druid - Mana (Resto)` (aurabar) | `Druid - Target Health` (progresstexture) |
| 9 | `Druid - Mana (Balance)` (aurabar) | `Druid - Target Mana` (progresstexture) |
| 10 | `Druid - Threat (Bear)` (aurabar) | `Druid - Threat (Bear)` (progresstexture) |
| 11 | `Druid - Threat (Caster)` (aurabar) | `Druid - Threat (Caster)` (progresstexture) |
| 33–36 | `Druid - Rage Line …` ×4 | `Druid - Rage Tick …` ×4 |
| new ×2 | — | `Druid - Player/Target Portrait` (model) |

**v10 recycles nine tables the same way**, and adds and removes nothing:

| uid slot | v9 | v10 |
|---|---|---|
| 2 | `Druid - Unit Orbs` (group) | `Druid - Globes` (group) |
| 6 | `Druid - Player Health` (ring) | `Druid - Life Globe` (vessel) |
| 7 | `Druid - Player Power` (ring) | `Druid - Power Globe` (vessel) |
| 8 | `Druid - Target Health` (ring) | `Druid - Target Globe` (vessel) |
| 9 | `Druid - Target Mana` (ring) | `Druid - Target Globe Rim` (texture) |
| 10 | `Druid - Threat (Bear)` (ring) | `Druid - Threat (Bear)` (rim texture) |
| 11 | `Druid - Threat (Caster)` (ring) | `Druid - Threat (Caster)` (rim texture) |
| 33–36 | `Druid - Rage Tick …` ×4 (pips) | `Druid - Rage Mark …` ×4 (lines) |
| last 2 | `Druid - Player/Target Portrait` (model) | `Druid - Life/Power Globe Rim` (texture) |

**v12 recycles seven tables the same way**, and again adds and removes nothing — including both
portraits, which are handed back the two uids they held in v8–v9:

| uid slot | v11 | v12 |
|---|---|---|
| 2 | `Druid - Globes` (group) | `Druid - Rings` (group) |
| 6 | `Druid - Life Globe` (vessel) | `Druid - Player Health Ring` (84px arc) |
| 7 | `Druid - Power Globe` (vessel) | `Druid - Player Power Ring` (62px arc) |
| 8 | `Druid - Target Globe` (vessel) | `Druid - Target Health Ring` (62px arc) |
| 9 | `Druid - Target Globe Rim` (texture) | `Druid - Target Ring Track` (84px texture) |
| 10 | `Druid - Threat (Bear)` (rim texture) | `Druid - Threat (Bear)` (84px arc) |
| 11 | `Druid - Threat (Caster)` (rim texture) | `Druid - Threat (Caster)` (84px arc) |
| 33–36 | `Druid - Rage Mark …` ×4 (lines) | `Druid - Rage Mark …` ×4 (round pips) |
| last 2 | `Druid - Life/Power Globe Rim` (texture) | `Druid - Player/Target Portrait` (model) |

**v13 is the first version that deletes.** Three regions are removed rather than recycled, and
because two of them sat mid-stream their draws remain as *retired slots* — `W.uid()` is still
called in place and the value discarded, so nothing after them shifts:

| uid slot | v12 | v13 |
|---|---|---|
| 6 | `Druid - Player Health Ring` (84px) | unchanged |
| 7 | `Druid - Player Power Ring` (62px) | unchanged |
| 8 | `Druid - Target Health Ring` (62px) | **removed** — retired slot |
| 9 | `Druid - Target Ring Track` (84px) | **removed** — retired slot |
| 10 | `Druid - Threat (Bear)` (84px, target cluster) | `Druid - Threat (Bear)` (**100px**, your cluster) |
| 11 | `Druid - Threat (Caster)` (84px, target cluster) | `Druid - Threat (Caster)` (**100px**, your cluster) |
| last−1 | `Druid - Player Portrait` (model) | unchanged |
| last | `Druid - Target Portrait` (model) | **removed** — retired slot |

A retired slot is not a filler region: it builds nothing and ships nothing, and it also means the
three freed UIDs can never be handed to a future aura and silently "Update" over the leftovers in
somebody's collection.

**v15 recycles nine tables and consumes not one new UID.** Renaming, re-typing, resizing and
re-parenting are all free — WeakAuras matches by UID, and the region type, the id and the size
are all just data:

| uid slot | v14 | v15 |
|---|---|---|
| 2 | `Druid - Rings` (group at `(0,30)`) | `Druid - Player Sill` (**same group, same offset**) |
| 6 | `Druid - Player Health Ring` (84 × 84 arc) | `Druid - Health Rail` (**100 × 11 bar**) |
| 7 | `Druid - Player Power Ring` (62 × 62 arc) | `Druid - Power Rail` (**100 × 11 bar**) |
| 10 | `Druid - Threat (Bear)` (100 × 100 arc) | `Druid - Threat (Bear)` (**100 × 4 bar**) |
| 11 | `Druid - Threat (Caster)` (100 × 100 arc) | `Druid - Threat (Caster)` (**100 × 4 bar**) |
| 33–36 | `Druid - Rage Mark …` ×4 (round pips on an arc) | `Druid - Rage Mark …` ×4 (**waterlines across a rail**) |
| last−1 | `Druid - Player Portrait` (**`model`**, 44 × 44) | `Druid - Sill Plate` (**`texture`**, 102 × 31) |

The `model` → `texture` re-type is the same move v10 made turning portraits into globe rims and
v12 made turning them back, so it is precedent rather than invention. It is also the one place
v15 *removes* a feature rather than reshaping one: there is no 3D face anywhere in the pack any
more.

Construction order is UID order and is fixed; **display** order (which controls frame level, +4
per child in `controlledChildren` order, so **first = furthest behind**) is set separately by the
`adopt()` calls and is completely independent of the UID stream. **v14 inverts the ends of that
list**: the portrait is adopted **first** (`adoptFirst()`, at the point in the file where it is
still *constructed* last), so the rings and their percentage text stack above it and the health
number lands on the face; then the four arcs, then the rage pips after the power ring they mark.
That also finally agrees with the portrait's `frameStrata 2` = `BACKGROUND`, which had said the
face was the backdrop since v12 while the child order said the reverse. (The three arcs are
concentric at three different diameters and their annuli do not overlap at all, so their relative
order is cosmetic; it is kept in UID order. Nor do they overlap the *face*: their bands start at
radius 26.16 and the portrait ends at 22, which is why drawing them on top hides nothing.)

The script round-trip verifies with `W.verify` before writing and reports `W.uidContinuity`
against the previously shipped `all-specs.txt` (v4 reported `stable=38 changed=0
parentSame=true` against v3; v5–v7 report `stable=45 changed=0 parentSame=true`; **v8 reports
`stable=36 changed=0 parentSame=true` with `missing=0` and `retained=45`** — the 36 is lower
only because eleven surviving auras were *renamed*, and `stable` counts ids that appear in both
strings. `changed=0` and `missing=0` are the numbers that matter: no id changed UID and no UID
was lost. **v9 renames nothing, so it reports the full `stable=47 changed=0 retained=47
missing=0 parentSame=true`**; **v10 renames eleven, so it reports `stable=36 changed=0
retained=47 missing=0 parentSame=true`** — same shape as v8, same conclusion; **v11 renames
nothing either, so it is back to the full `stable=47 changed=0 retained=47 missing=0
parentSame=true`**; **v12 renames seven, so it reports `stable=40 changed=0 retained=47
missing=0 parentSame=true`**; **v13 is the first with a non-zero `missing`, and it is declared:
`stable=44 changed=0 retained=44 missing=3 parentSame=true`, the three being exactly
`Druid - Target Health Ring`, `Druid - Target Ring Track` and `Druid - Target Portrait`**;
**v14 renames, adds and removes nothing, so it is back to a full clean sheet:
`stable=44 changed=0 retained=44 missing=0 parentSame=true`** — reordering a group's children
consumes no UID and moves none; **v15 renames four, so it reports `stable=40 changed=0
retained=44 missing=0 parentSame=true`** — same shape as v8, v10 and v12, same conclusion: the
four are `Druid - Rings` → `Druid - Player Sill`, `Player Health Ring` → `Health Rail`,
`Player Power Ring` → `Power Rail` and `Player Portrait` → `Sill Plate`, and every one of those
UIDs is carried across untouched). A re-run with no source change reproduces the file byte for
byte.

A removal is only allowed when it is **declared, one id at a time**. v13 listed its three ids in
`WA-REMOVED (v13):` comment lines and handed the same list to `W.assertUidContinuity`;
`tools/verify-packs.lua` reads those comment lines independently and honours them **only while
the pack still ships v13** — so **that licence has now expired by itself at v14**, exactly as
designed. v14 deletes nothing, the three ids are already absent from the v13 string every
continuity check compares against, and `W.assertUidContinuity` is called with **no allowance at
all**: the strict default, where any disappearing UID is a hard build failure. The list survives
in the source as the removal proof's input (nothing may quietly come back) and as the record of
what a v12 player still has to delete by hand. `changed` — an id that keeps its name and swaps
UID — is never forgivable under any setting.

Since **v10** the script also proves the layout, not just the encoding: after assembling, it
re-walks the parent chain summing every `xOffset`/`yOffset` exactly as WeakAuras does, and from
**v15** asserts that the sill group itself resolves to `(0, -110)` and that every one of its nine
children lands on its canonical lane offset — with `0 / -110 / 160 / 5 / 13 / 164 / 36` spelled
out as literals once (v18's numbers), so a sign flip in the constants block cannot pass a proof
written in terms of those same constants. A group offset edited later, or a coordinate written
locally instead of converted, fails the build instead of quietly sliding the HUD. **v18 ships ten
proofs**, the rail-canon replacements for v13/v14's ring canon — rewritten at every geometry
change rather than deleted, because they are the reason a geometry change in this repo has never
silently shipped wrong:

- **the 1.6-pixels-per-percent proof** measures each rage waterline back from the *centre of
  the power rail* and asserts the offset equals `(v/max − 0.5) × 160` — written in that readable
  algebra deliberately, not in the integer-safe rearrangement the builder uses, so it is a check
  of the formula rather than a restatement of it — then asserts the mark is a whole pixel, spans
  the rail's full height and does not hang off either end. A companion assertion proves the
  *property* the length rests on: every value the pack marks is a multiple of five, and at 1.6 px
  per percent every one of them lands whole;
- **the rail canon** asserts every rail's region type, **`HORIZONTAL`** orientation, 160px
  length, canonical lane height, `Square_White` texture, visible track with `backgroundOffset 0`,
  `0.41` crop, `compress`/`slanted` both off (they are LIVE on the linear path and would bend the
  scale), its exact lane offset, and the **exact number and type of every sub-region** — a stray
  `CLOCKWISE` here would silently draw a pie wedge instead of a bar;
- **the lane-stack proof** derives each lane's y span from the assembled tables and asserts the
  stack arithmetic (`5 + 1 + 13 + 1 + 13 = 33` of content), the 1px gutters, that every rail sits
  inside the plate, and that the two leftover margins are **equal** at 1.5px — an instrument with
  1px of sky and 2px of floor reads as slipped;
- **the collision scan** (v15, replacing v13's single alert-column clearance) projects **every**
  drawn region in the pack to an absolute rectangle — dynamic groups **six clones deep**, in each
  group's own grow direction with its own spacing — and fails on one overlapping pixel. It prints
  the tightest gap on either axis as a number in the build log (**11.0px**, to the buff row's
  `Druid - Lacerate`) rather than leaving it as a claim in a comment, and asserts that the strip
  would still clear everything if this pack ever grew the profile's ±4px alarm rim (7.0px);
- **the column all-pairs proof** (v18) boxes each of the four flanking stacks as the union of its
  children projected six deep and tests all six pairs against each other. The scan above tests
  everything against the *sill*, which structurally cannot see two columns overlapping each
  other — the blind spot that hid a real defect in the sibling rogue pack. Tightest pair here is
  14.0px (`Druid - Buffs` / `Druid - Cooldowns`);
- **the removal proof** (v13) asserts that no region whose id names the target survives in the
  assembled child list, so a stray `adopt()` cannot ship a cluster the release notes say is gone;
- **the plate proof** (v15, replacing the portrait proof) asserts the region type, the
  `Square_White_Border` art, the canonical 164 × 36, `frameStrata 2` — and, the one that matters,
  an **explicit four-component colour**, because on a `texture` region the tint field is `color`
  and leaving it empty draws in WeakAuras' default rather than the intended shade. It also
  asserts that **no `model` region survives** anywhere in the pack, so "the portrait is gone" is
  a fact about the shipped string rather than about the constructors;
- **the readability proof** (v15) asserts each percentage as it is actually shipped — token,
  point size, **both** offset spellings (`anchorXOffset`/`anchorYOffset` *and* the
  `text_anchor*Offset` pair WeakAuras actually reads, kept equal since v16), `CENTER` anchor,
  `OUTLINE` and `text_visible` — with `12 pt at (+51, 0)` and the threat number's 9 pt
  switched-off state written as literals once; then asserts that the widest string, `100%`, ends
  inside the rail and that the point size fits inside the 13px lane. A companion assertion checks
  the ruler hairlines at `−40 / 0 / +40` and the 70 notch at `+32`, on the same scale, each of
  them a whole pixel;
- **the draw-order proof** (v15) asserts the sill's `controlledChildren` against a written-out
  list — plate first, threat, health, power, then the four waterlines — *and* that the flat child
  list the string actually ships is depth-first in that same order and starts immediately after
  the group. Draw order is what keeps the numbers on top of the plate and the waterlines on top
  of the rail they mark, and `controlledChildren` order is the only thing that sets it (+4 frame
  levels per child, so first = furthest behind).

## Import string (v18)

```
!WA:2!T31c4XXr99m(Ij2xEzj)ijMeYfLyhztIZ9uNo3yG7LSK8jDN27K8JKIU9UDUBxR92D9U7jPt8mIaveElGanHNciqtdLwXJslfk42sBbA7G63x(2stB5tF8bbAdTFUqlLhF0zMD37LoDwwso2jK8fpEVzNz2DM))()7))z(pZAWyDM)JCxZDRlLJn)eCQYkrLfLvh0HdhPC4(qbu6mVSKUQSOiKlkVGiNku6ru6mMAzbox3TR0cIIUsjYQdv2TDEz4vHS6U6ocKv9ak3qZzhLvthIVXoTVr)qwrDExmScI1A4uYtbvnZ7gTZJHTi01qSQtGtKkkcv2tRUtzrLBE1QHRec6k7T11ICVLZjRYbvJynuOSJiIcZmdRkNRmYYI6ckQtNSqbnOoiNclEKqx5onBSmrIIBqsp(UCXa10Lvz1fKLCTFxryfzLYdZz2Y8QvmBGJSGkSiUezQOazkQkxwzbZsKwyg4wxuqQGSAjAB4CrZBykxaaGJLylRZlRMuHCBnN5WsOccfDQYMNMrpmA6SQ6oZvqqsqJ3ze8FP7CwDvHIfHQAdVFvRlF4i6KNoBzvwVNLKQPafff402BNUJugxPCkISvGQZsZFaonNlRvohCsC)oD5cfeMEXXJgoDMXtNjmtMQ3kLkeFlM0PINiX5kRbJpn(9kTzlKLrITeuZ5cCWC4wG05v7pEIu9nAI5llz9A5CrobTtxwc3BMe6LvuuPdw61zmV)qYCWN4kSgUIZveQ0r6ZugloC1xzmA848c6WZAExZX6TppRKG5GzpOxCFNfYQbtRJfFf15VkKRisYsWL4kBkYgNmMOQbXdQCAZskk5TefmsjwbP(q9GRakiQxui0HX)9n3CoZRbflKswqspx04dNjotxcC1G6POJNuTMZHlcuvIvCm8td)CVVflOIhBWVxS6SoohgZGfX9rYI88ZLokt84dVGUC(jnl)2sTBV4gDXjpAMtDSeYXtC6JZOLNve6ybSKGHcU0SXodiHhgCSaPpjycAIikZY5CrZhd99fDK5Un01bqDEvOJHocAV4HkNOB2j6wCIEjVY9JU1hg3nVD0(r3jdvmNZuTfN1DG2NZzXc6XjqMSOUrha9sDIUl0DJoKZ6RhkHYUgfxexr5zjyvOQGMUqEnRManCt1fDpi3ippXvGE53h6ErhbJz0y1jsji)SQY6uPfaDuN54Hcf51hihntipAWXMN86KxKvtlBoD8yIK(EykvgRa7KHM7(ZPjq4dyIXm6aXqJTh0jZgbJYZVh0yoJOHvbjxCoD404hi84QSkeqNYUIMi8qPYKmsIWrpw4yXgiZaJfpxjbvvzvE0ovTk)85WprosnyIKi(WXqJReEaI0UaBE49hMJlPK29FCi7eHj6C3)qqob27pJzD1UFtS84uy84rOIVdPxKfD9Oxg6MCIIIf8ymfYb6gDYWkQWZ6GzkboD(yorVITIITy8c(5glT)eWIfzYBZzK6kDFi)bu6aRzLxfIB4AdGbi6enJR)To)iD0ahC)m55H5NOp0TU1zNKvvGf3XNvqkQCPCS6mtYkwgc6swPRJCe188ycyO2E3pAcQDLzvW8Rqv9kO87hXJBbhiH5lXonVjQAIoDtQ49EeKiPkaujuE0ECIcJIm3HZHLUQJxby(3tdWO2fz5oDzSDfUHyNEl1(HG0wqDE7e8SYUQbFi07ekxjo(f1ikyMd9zRVm9jJ5NnldJgMbxhmlwMgMaAEW9GrKlJF)lIfxAPLlRMhEWB(k2cbKAlLUrNOraO8oids2DpS5gClI7mMdjM9SbjJgHiIhpEntDGkDUcvF6uw)QnXI6uJO0r2wpgD0do3nQ0jbioUgplN8uNWYG1808ijNDFMTIsE99TpLDuxzRzIr5UQw8XnTenE1knohmpMovCCfv8feUiWYMnIn1xKWJMjPYoPzITvjt4EZFCcinsy8ppNzZkmnKJM5dSKjn0jTEvpl9(erOqHkyfFt9AIukYWjhoUYT1M3nZmYnC5s5GQixQyUqsbTgsmFowdjxZwwGMzEBhECmVvBITRVJ(ufMX1iLz5i8XUYKPHwW(nDjAEtHvsjCeZECRlwQA7qTWLC0mjga)EVJ6AblkxL91M(cfaqThXuquwwTb5AJVcKNfXZHDUutDrZXYjXIjSUj)C7AjloQHSiTUUWOxjpQtWceH34kMVv2eFm2KelBLXyMTtwl7gJxIWXrRKDoyQlwVHtKa5AbRHEC1u6W6Iy1OWTBslLpLdV(yiPuJCB1CSfF3i2uViwuFooRvU18PfRI1BGZA9YA1DrP5xQ(Em2ecZvt()1l1yU8yYTXRqjD9uVLuLDGPScBXorjR4v6ixv6iREi6trz5xG6ghLYbGg8nHYKLALLyDIhDkIbk0OK0LP5sCWAcj5PKYIo((rNaDstRAlu7gB7bhdDF4kmjd23v9kz9QmPs2zXOo9kLyLY6vhkLDb9PWglRua7Tf2Yj96SOGzBYdGfmXOeJ5yZRQfH6yR20xJA3ilXKEcLDy52FAb9YuSe1g)kDoicb9JFVDq6w4QLwN4189GPHlDpeqaXTal3miLmBDntv)eEL8np(kiHnlFoBQAlz8SYyxOWoIP5eLfXsD8TgqxRKSSoFkRAGh(iC)9jOQPZVOv9YlkOWtSeHUF0VTYoQj(S0ipxTCIwV93abMnVCjfs7YtSGFLOzgKKV3aeBa9ss85a9kCG4UsNkDuZeqnurSfpASPsLskIAWkbvfKiUcc5NN(osW85gy40del(IYQcyjhThTq)jzg4ujhot4eMOYPTqL7XPkTEqo(5omsgGui2rrNzlivBBMinEewowMhnjanf1ShA6v3s3HRziVkhgAIUcsTs9YST3rNwzpKepylDOzQwjuf0eoQ304tNQX7)QwDlEOxna9AqVw0RJA8c96bOhanl6nGEq0B8bqVja63b)(oh6nJEi0Bbd4ERO321Sf0B)Ppb6DGENO3fanp6DJEpO3l6HXf79HE)OFxa6r2j6rXf6dGPmrFWA0KOpeUiFya6JKf9rrlG(yOpoU9(eOhJh9jXYhUTI(9O8oOh)Ppf63NYSGEInkBc6tVsIe0Fap6ZyXtG(dTOhq)rnWlGwSrQa0NDBS71Kba95YI(8zrFHSO)4SOVyw0FIPs(Wn4U(Fk6lr06(Zm1KrF5wRYH(Ayvm0zr)fuTj0Fja9xLf915r)1vvrq)na0F7tpd6Bqr9BfnZt)QSq5OVjfuNjN0Of7jXXsoOo6VJh93J(hqi03gTuvKk6FSvy0RFDGrh0eoTvmC60n5jg1TucIQkIBjST78yfjBFs7kab(159wfjJF)6jqRGYpjUWEduxHBgllTky5bTWYk7yFn8W33(SX2Tgytb1fTX0kUxHxfn0ATWdoSAGYbop1QM)iyDK61z(azPQm3e6rl2chAASrmZe9wS0RERB5cuXY2kUNERxb7fB1CGlu10VERALr2yTc5)VOQSpgrz3uhVbfCtL)7JM2OfBS(7qR28SBQCjpVZh)cxP)fzzQZtaQdy0z64TxhnsdmtEE1H17HV)tXEHqd8QVIl28aZRqwmskUVrlu0(uWa16zEc0erWtHM4QAX09ST37TXIplEcW0NfMDWtByhoNn5aTWxGCdDVAkO0gRrLCSTrSUDDQ6k3r7RTT2Dn(G7P9vyLmrRxIHwRk)cecRgHadDj2VeskCvesbIsG5ItrsdfOjob5I5IEQtl69ejZS6CcUO63K2N2h)c19EVm99(PC0WR(sKzruvNoBR6XFLQtfb9NBo1d0xTLZ5a)guW2lEAhOwNjqacHdb4GPO2jACcdezGzaNRFWqrqd4GXTbby2o84gMQJmWUn01Dnoi0CP4j8DXw0B3XkNmKMpptWsffe(smKedphCscYzrBWZPwje6ZApTrNiUTFbpuJ(EBcdVoSOzTXkxYgy3ozEa1nUwOBL0Ijgn1WvIT5oU(9ThPw2KLKSuPS6YQ4PrnFvWBw7bDg6p7YR7lkJ(ReC7OTd)fqUYrMKluhDyvs8tswwNmA)JYPXJNZ6eZAhPLiK2LkaAHac3kOFe9ssvJuGLdIEgV4AqlYAsA5Sz1apfNAk((927qzcUHexDSQIl0pGmr3NUQKb9dXt)9IUoX5vEqhj)3PJKO)d0ZG(XRTrD0)jUS)xR9b8RUj1dU8hJTCuV9fny8n449TIavJinAlpUYoSdOwc28enJ6I(SvGEJrdWyTy92hluva6QpbvODKP7OAJiuaMtuwUKYUQgAy4PlpjuIItR90yiRiZu681khjWA51DLEkw1s1k3qYKiYQcvULw)4ndj8buUj7BhdwswLvuygbPIUyKzvrxd6AjoVC9ODG6alzVgawYUl0U3kr6FdME7Hf6yjDdXPZEc83gQR92PBBB2e0fbhDWSTWUTxKpK)TV(jonL9lz3tIGh11SGfezofLeBXtMS7KQ(oMyQJkrCq6Oor97Gaqh0jbvm3TVGqEzjZqPCZxbPNHD2cFJLYlllYjpLu6PeWwQpR9pjr9LFLHO8XS66m(8f0FaSOskPKyLS4XHVulghu7pmZq9nAI1TI4l)(o3eqOsysGd1ziyfE6SnW4)Jo4tUurr5P6tfEMYqP8vmzrJqYJ)Syk8JkAfUf(5j5L2mYTKltqJl9UxKCT9I8tlt1fX2b9E2b2XmihKCOpXm8c5NqcQP5yw6pXE4SuUY66Ysjnx(sABLqaxKoOppZqmYp3UPtTOR9PTgMnba92PViTAb0iE(FBOhLmZHQTPYgPnp7adpCCMXJKmtMKdrB(BWS5XSvZJ76MH4EjZ)ACzRyiz9ZQra1H1E7WowizTcn(4qmwc5Z(xKvx3bIzKlmkQDgHGFXAR)k01DxxjgV3TNqrsgUNr6ompHSg)FrMbtWqxJ3zTrXzRgm3)BLDzNjz1EJjOrcLkxwcBk3igGxCwIQo2byt1uIUNltsAl10MY5MxroeDX6IfzonD28tOHNNz9Rsvw80mtvTmldNwrW0uDgHsqRYwDoP4ctcXZH8CickIWl9kCm3TJ(11R)AaUISgaWQRQEySQAVb7fNgQ3EOPbnaownnwdWvUbuwnaBTM(5HFsdWlYuP0aCv8gGTH)Z2DyaCUBdWvdmaxdvQzaUwScMb46maxp(h7Wa0HbOt8F2j)Md42aSlkK(wQcPna43G9GFdmP5na3iEi8Mq(ma7DDamXyhtyPiXI8KCNyW45J7R7sbSGLgGBHcknaVKAWXFIb4w3SXEoVqriw2XECVbd6g)NEJekO)qrcfYDqgV9ekKpgp90BGGmEc6lKBAQhAQxgVbD7XZlGG20rq3ngavQNdu8OhBmo)z83oa0p9IaaAVvjMma3wliJmaDDHaXgUj)f6XxBiEAlqyWnpGWLD2ETbx3WMk4Q)zxb46BTfY6uC6(v5evIPFSJ2o01)Zfb01bRdD5cJU8TQMfnrFE30qFFhm5M)iEChO3iE87ZDeVUdrt8eXxpEdgP3qEChjuV(WuF96NCLFpmEd4nuiclyVEOPExVq3NFZH1cygXiiK)a8d5TWjpUwM2HY(FFwGdZ3Mgk6XXafF9qs6LKecNGrl4epy7Mbi4Ma9qscss6LIAC)cOM1iQ5KyuZXRivMxTKNj46UDOMF2ZPqnNosGabDZ41p23kAAaAAp00GupP8DE9h)3mHjwBLIvydJPCoFdgxuO7ZCM2Ht()Uu7IDDOGVbMNWRhsIFssascHkHA9XlHpXlX6JpFKe)KKauceQJ4927laqwRaeI1NUN2R7yPsC8PNuOD4JF(Lr4Jh3aCNgGUnahWaCqdWl1aGfS3Tb4qgG7Xa4(fK)Rv5pXoYXsDgVElWgGlTu7K))Il)NbvDts)0Dfkue8SVdejKFS3RyRje)mcr9ZiuVVWCX30Nl(BeJKsNmL6uA(h94J6PDiPF5LuKK7iKqM01OPqB5rQlCiQqPzeGCKiQaLCLsvUKIETOQeveYQMNvtxqQyTdpvs5OUgsqJCYDQDMahqscQojRo0Ur2zTabvw0oZQhiWmQqOl5c0q(uTXQg3MOrDjl5AiyTWgfHvDcTjeKC1DA9Y4hf3bQ7Cos35ZUgOuPYsqAaBikmFnAyUmL2mAkS5Hx7gngnlMxwSCjP0KgZb90qLZCXWzyffkkHoIQMol5KXronuKqQulyzQMN8nywAKK6ZXSyHHv70bpn2p78SCvKyljKNEier7ERr0Kv1rbNVOQG5XZ4QNLCjjqcDXeJruOKG(vt2i2jixXVCEzj8JxsVp286YQ5ychBGrtNtLLtOS2dEni)BFESS0mOgp4ESrLlBpigweQQRTqHYIIrfuZlIFtTIC0iasmIUoXnqSPWqDtJEXw0V)065KZWpgxY5Ud0VgC(i3KWsPVEvEPNSl)URUf6m5LicRHZQ0bnC81VdhZQSNg3XJ2bVVZ7TwyFNRdgDv28teHC8ymBeSIauviFAE5PskLDPg(5IA0)IbYYvH8ompDx9pmBj42o5HrUyO)06m2DtrTIKGl7DXog8sU)bu6K8CWigzvizVSJLQWSlPIFltB3Ck7UrvtO56)Vu1JyaPq0nemPRygpB6osG2BYQStY1qYj(S(IVjXYFWAS8wS4Bdl52btkHPHI1Z1BUv6jP(PC(yBcznThqO9nj8xlCZVjtU5fONMq6HABTZttoeRKJp7ay9dfx1oClKFRD)S5eef0RmEomUxTSgp66naVbthelCStm4y9ma7ehD6vsRZBRazaewvE9gJ4)IAIy5CozDD5s0TqHp7O)3mx)C7yE6jiLgZqnSeLCSkPrMe5kx(YA4gihTavOdTKNG5VN283ptNEq5bu4an7SDwHB7DonyE6XuK0QZA3QKN9s4RL0iNDCYTu6W(EzSZg)ITKf2YmJS02M2AzxNU0AZ8sIEqW1weYxDFnQhfAaE4gC3W8KgzU)mwnm4LmNoSa2gG3xBb0H)Un44rviAUj9mspdLtz0HAxyKmaNEncrnapk6zmaFGvhyAa(GgGpePN9HnaFKQWpdWhTEONbybBmNb4Jza(4KwYa8jmapgUTmaFsCp(t1eYzTymOHyfGbo94FjSr188qnt65LmPNT8Ny9aQo4AhuvDNgVry2wdED2GW3a8(v6Uzsmkd)4sKt0hMFuTc2naXCSydr1qkhi6yfIM60c(KZ0wYSjEEcsPHDdMYUByRoxZpGZwF(K9TN12fJE81Ay)rNf9uGvFZJnhwEpNb4nBaEi87YBXa8wjTIb4TTTZ8JjJaVDtxcmaVddW7exI318vDx2a8UBYmUb49GlY7n7ggLshNjjbDSHT(A6YIKSE9hWXLB83e7UuCmLoBv3)Z2W493wySiXcKerlUgio5jIoy5OzC7E0t3wqS4ZhbXpRSLgx)SH9SzWgUgnh2G)DeOuxRMBDCKz3mEj8mqRdgXddLmypkP8OX0wyuPNpA10NVEd5Xa8egGp9fp7JKc4RXTQ8ZgWI8NpdLncl0vHq5cIcfG1boMr)aEpDFAfcDG2BOu65aGJ1SZ4tszkSGc2wIsOSJOQYtX5kA1p8ue8XMId5NxFNUK5rEbRZVBBpep7h95ZYq(UtHN(ttUKNiS)(s1)K9wAuL26sU8LX4NhP235eRp6y0p9stejDMrhUHtrNJMoYDNR2grSXpykgGVkAILi1F8HIhT)Wdpq022qgGZ2yDJ0x8WmR4e8f0CfgAvfwIuHw)Wop1unAYH7B00XxrD8BXOrwqVw(oYKmzMvulFwUG1QNu6bseF4OXx5qH9mwBvhlv4Od03jxpvvzhPJ2FYKjgFaYxelMrtL58u9l0WqS6ocFYBULocpR9c72w)GR3zgChXa81iTXx20vMZzUQqvXPBEo2qf0vpOOBSLW6XQrQyYJKbxGpxJUjBa(8eFBwKymdpEzZ0ya(kRGMP0XMHXx8KEfL5BRzkLNpzMYAnJEeV943BepU96MK4nsGaHcXGVkyVm(d43xVm(841RFgpHce0pJp)(d6zdU5A(naRzTcJPiCM8NuyKbHkD3wtzN55aym3gya13gTLhY(0gfnw1ZOudzfxsLTi0(ebrZQXvI3o6y0BLEkHc6LGsC2HuJM7W0PWENAM3MCgqSdKLz7jRMNg8lZYzhPm69SPdB4PuDXcQgCR76kRl6wga1TVrdTLbqZH133pdqzsYKRmiwgGPSJFLby6ArUYaubT7TAaMbf0a8QUAdWRUlMygGxd(QxlVb41zaE9gGhGgdkdWS1c(uTt(LDOs0mapyZbEcSPe3POElLhYmSCKWEjtA68t4iTsZzlqwEXWItXwrZ2SgMUUvM1wY60VzEc3wZ22A3b8(z7j0hOjsn(lyREHxpbv3a8DjH5X6Z8AwtMOrMbEMWLpaRC3XAltKbMjINYefEtle71(AkTGSKnoTPV)enVXK)(n9PSWms8R(N6c(6Ju)DSoD2AzZf)U6ROfcDxLAjcnNjr3AhAUja5wNBjK1cqR2seWFHb2maFplqw3WadlLpEKX4LAli7F6IaiZ5gu2Ba(bvD0(WTuEBaM)5lY61fPsn5CPr6pvLPIv8O8hTTY5VZLA58WTvo3)SToYcvDjzJgzHlTsWM293nibpwLEcmDq(PQuiCBLG)ZxElbJ8uTucQ05k9F852YsChDvLLAPtoPiSGUMA7NKXtD5TS8bVZwklpxt(6)CB5iUtUQYXt1Zutuj2ihnKS)2kh)xU8woUkltLb4BEzUOJUyswrFLUksTn(Rnj88lCMtPmuPjZfpFBfE)RxEl8wLGTBa(SpFw4nIBPrd0p7e95g2wH3)2frHhz5vIel5XhgTLdxBpbNAYuUYq(udb1DfdpLKABz34sWsvSV3Y1TTFjFJIA1o41aOETBARXH3mjt9S3QCSyDdhTy5n42C2xTdDgUaN(KJ4l5j6DTTGQFXx0wiF4WMvqhwIUbwLoM5YR)qzrjuUXwS5vhaxYdyoDal9o8i9zPBLvR2ilYveY11wYIVGb4NVnPrQ1YgGFrZnHb4xMLOO8RAQAV7NE9vTF46QAd8zwFv7tCbvn094LvQYkyBY(SfBZ6BbH)zMmn9owYyWJL6uU9uPTmn)KlImnR5Gfq204juT(xmN9Y43R3qEP0dpJxpKD6LYUOB2AxK)zqYv6Y5ZdjFPYr3oUJVy1Dz9aCzpp)lIYZ2wmgynkd3tReGs9RK(0f9xrsO)2ka)PvfGdCPta(K0LBnQOmEcqznj6)5Kpqe92JxF(cfXJ7E8gjGNqbij0JuTxsIp6zHmeJNqHc6MM6HM6LM6JM6NMgGESADVOcuL8DYN8DBFw2cfG51HCMhLo8q4YKTBUGemLzHY(C(Zw3nTgdE0gcNfFc9HC7BeONHD3wCwTpGeB64Sol1jxNCZ9sA4dw3PqVm0VYa8gO(p9ZS)2Ur(UU9T22L3Fx3WUJSIVLB9Mxz64Hf6pCX(BX3YTo1y8DOahYDNtELVM))
```
