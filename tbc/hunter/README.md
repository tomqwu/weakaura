# Hunter TBC — Beast Mastery & Survival (v18)

A single WeakAuras pack for TBC Anniversary (2.4.3) hunters that covers both raid specs:
Beast Mastery (41/20/0) and Survival (0/20/41). It is built from the rotation, not from a
list of trackers — every element maps to one line of the priority list, and anything that
does not change which button you press next was left out. Everything matches by **spell ID**
(never by name), so it works identically on a zhCN or any other localized client.

49 auras: one draggable top-level group `Hunter TBC - BM & Survival` anchored at screen
centre `(0, -140)`, holding six sub-groups you can drag independently (the *Resources* group
holds **The Sill**, the instrument strip under your character, draggable on its own). Built
for WeakAuras `internalVersion 45` / `tocversion 20501`; modern WA migrates it forward on
import.

## v18 — long and thin, not big

The Sill is re-cut to the profile the repo settled on after three size passes elsewhere: **160px
rails, 1.6 pixels per percent**, on a **164 × 36** plate under a **172 × 44** alarm rim. Same
three lanes, same six regions, same 48 UIDs, and not one trigger, load gate, condition, colour or
spell ID moved. This version is geometry and nothing else.

| | v15–v17 | **v18** |
|---|---|---|
| rails | 100 × 11 | **160 × 13** |
| threat | 100 × 4 | **160 × 5** |
| plate | 102 × 31 | **164 × 36** |
| rim | ±3 | **±4** |
| numbers | 11pt at `x +32` | **12pt at `x +51`** |
| ruler hairline / waterline | 1px / 3px | **2px / 4px** |
| plate area | 3,162 px² | **5,904 px²** |

**A vitals bar wants to be long and thin.** The fill's *travel* is the signal; its thickness
carries nothing. Two other packs in this repo tried the obvious thing first — scale the whole
strip — and it was rejected in play twice, at 300px and at 200px rails, for the same reason both
times: a uniform scale preserves the aspect ratio, so the same stubby block just gets bigger and
reads as a **UI panel** rather than a readout. So the rails get 60% longer and go back to near
their original thickness.

**1.6 pixels per percent, and every mark still lands whole.** Every threshold this pack marks is
a multiple of five and 1.6 × 5 = 8, so each mark sits on an exact multiple of 8 from the centre:

| mark | value | x |
|---|---|---|
| Go Viper waterline | 20% mana | **−48** |
| Back to Hawk waterline | 80% mana | **+48** |
| health defensive waterline | 30% health | **−32** |
| threat notch | 70% threat | **+32** |
| ruler hairlines | 25 / 50 / 75 | **−40 / 0 / +40** |

The invariant was never the number 100 — it is that `railX()` is the only place a coordinate is
derived, which is what keeps the length a single constant. The build now asserts
`x == floor(x)` for every one of those, on the decoded string, and refuses to write a string in
which any of them lands on a half pixel (a half-pixel waterline is drawn across two columns at
half intensity each, which turns a decision boundary into a smear).

The **known cosmetic collision from v15 survives the move, unchanged in kind**: the mana number
sits at `x +51` and the 80% waterline at `x +48`, so a three-glyph reading (roughly `x +40..+62`
at 12pt) still has the green line through its first digit. It was `+32` against `+30` before.
Fixing it means moving a number off the shared profile, so it stays as it is and is written down
instead.

**The lane stack is derived, not typed.** `threat 5 | gap 1 | health 13 | gap 1 | mana 13` = 33 of
content; the plate is 36 and stays at this pack's own local `+3`, so the content sits inside it
with an even **1.5px margin** top and bottom and the lanes fall at `+17 / +7 / −7`. The build
re-derives all three from `PLATE_H`, the lane heights and the gaps, and checks both margins
separately — "it fits" and "it is centred" are different claims.

### Nothing moves for the strip — measured, not assumed

The thin profile is only ~5px taller than the strip it replaces, so this pack does **not** need
the buff-row move that the enlarged packs needed. With the alarm lit:

```
rim envelope: x -86..+86, y -85..-129   (172 x 44, a 4px rim = 1664 px2 of red)
Buffs        5.00 px   (Serpent Sting, y -80..-40)      <- the tight one
PvP         34.00 px   (Enemy Mana, x 120..240)
Alerts      44.00 px   (x -170..-130)
Cooldowns   61.00 px   (y -190..-222)
Procs      164.00 px   (x 250..)
```

The buff row's 8.5px became 5.0px and nothing else came close.

### The all-pairs scan, and the two collisions it found

A scan that tests everything against *the strip* structurally cannot see two flanking columns
overlapping **each other**. v18 adds that pass — all six pairs of *Alerts / Procs / PvP /
Cooldowns*, each column boxed as its **widest child by its deepest projected stack**, six deep —
and it found two overlaps that had been shipping since v5. Both come from one fact:
`Hunter - Enemy Mana` is a **120px-wide aurabar**, and a `DOWN`-growing group is anchored by its
`TOP`, i.e. horizontally **centred** — so the PvP column occupies `anchor ± 60` at *every* depth,
not the narrow strip of icons its anchor suggests.

1. **`Hunter - Quick Shots` was inside the PvP column.** The proc icon sat at `x 110..142,
   y −132..−100`; the PvP column's box was `x 90..210`. In an arena with a couple of prompts up
   and two mana-using opponents, the enemy-mana rows are drawn straight through it.
2. **The PvP column reached the cooldown row.** That row is centred under the character and grows
   horizontally, so at the six simultaneous cooldowns an arena really produces it spans
   `x −106..+106` at `y −190..−222` — and a mixed PvP stack (trinket down, two enemy trinkets,
   trap armed, then the mana bars) puts a 120px mana row at about `y −200..−212`, across the
   rightmost cooldown icon.

**PvP moves `150 → 180`** and **Procs moves `110 → 250`**. Moving PvP right past `+106` fixes (2)
at *any* depth, because depth only grows a column downward; it also takes PvP's clearance to the
new rim from **4px to 34px**, which is the second reason it had to move. Procs then clears the
mana bar's right edge (`240`) by 10px. Tightest column pair afterwards: **10px**. Zero overlaps.

Nothing else in the pack moved: the buff row, the alert column and the cooldown row are
byte-identical to v17, and the hidden threat `%` keeps its `+58` offset (it now resolves to an
absolute `(0, −35)` rather than `(0, −36.5)`, because the top lane rose 1.5px with the taller
stack) at 9pt.

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

## v15 — The Sill: the rings become an instrument strip under your feet

The 100px concentric ring cluster beside your character is gone. Health, mana and threat are
now three stacked horizontal **rails** on a dark 102 × 31 plate directly under your character,
at an absolute `(0, -110)`, and **one pixel is one percent**.

```
                                   ^ your character
  x -54  x -51                                                      x +51  x +54
    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::   y -88.5
    ::  +----------------------------------------------------------------+  ::   y -91.5
    ::  |  ################################.........|....................  |  ::   threat  100x4   -94.5
    ::  |  ############################################......:....... 62% |  ::   health  100x11  -103
    ::  |  #########################:###...|...........:.............  47% |  ::   power   100x11  -115
    ::  +----------------------------------------------------------------+  ::   y -122.5
    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::   y -125.5
         ^                        ^   ^  ^         ^              ^
         |                        |   |  |         |              +-- the % printed INSIDE
         x = -50 is 0%            30% 25 50%       80%                its own rail, 11pt
                                  mark ruler hairlines (25/50/75)

    :::  the 3px ALARM RIM, lit only at >= 80% threat. It is a 108x37 quad drawn FIRST,
         i.e. UNDER the plate — only the band that sticks out past the plate is ever
         visible, so nothing is drawn over a rail or a number.

    x(v) = (v / maxpower - 0.5) * 100      i.e.  x = v - 50  on a 0..100 scale
```

**Why a bar beats a ring at this job.** `Ring_20px.tga` has a 20/256 stroke, so a ring's
thickness is a fixed *fraction* of its diameter — you cannot draw a small ring with a readable
stroke, which is why the cluster needed 10,000 px² to carry three numbers. Of that, the 44px
portrait was 1,936 px² (19.4%) carrying no decision at all. A 0–100 quantity has exactly **100
distinguishable states**, so a 100px rail is the precise length at which the gauge is lossless:
every pixel beyond it redraws a state your eye cannot separate, every pixel below it throws one
away. The strip carries the same three gauges, plus four breakpoints (70 threat, 30 health, 20
and 80 mana) and six ruler ticks, in **3,162 px²** — and it turns every breakpoint from
trigonometry into arithmetic. The 20% aspect
mark used to be computed as `r = 62/2*0.94; x = r·sin(2πf); y = r·cos(2πf)` and land on
`(27.71, 9.0)`. It is now `x = 20 − 50 = −30`.

### Every element, and where it went

| was | is | UID |
| --- | --- | --- |
| `Hunter - Threat` — 100px arc | **threat rail**, 100 × 4, top lane | carried |
| `Hunter - Health` — 84px arc | **health rail**, 100 × 11, middle lane | carried |
| `Hunter - Mana` — 62px arc | **power rail**, 100 × 11, bottom lane | carried |
| `Hunter - Player Portrait` — a live 3D **model**, 44px | **`Hunter - Sill Plate`**, a 102 × 31 bordered texture — the floor everything stands on | carried, re-typed model → texture |
| `Hunter - Power Ring Track` — the mana arc's dark socket | **`Hunter - Health 30% Mark`**, the health rail's 30% waterline at `x = −20` | carried |
| `Hunter - Threat Flash` — a 100px pulsing halo | the strip's **108 × 37 alarm rim**: 3px larger than the plate on every side and drawn *first*, so only the protruding band shows | carried |
| `Hunter - Player Cluster` (group) | **`Hunter - Player Sill`** (group) | carried |

**Not one new UID was drawn.** Six regions and one group is exactly what the strip needs, and
exactly what the cluster had, so every one of them is re-typed, resized, renamed and
re-parented in place. `stable=45 changed=0 missing=0 parentSame=true` — the three that fall out
of `stable` are the three that changed *name*, and each keeps its UID byte-for-byte
(`Hunter - Player Cluster` → `umpqFv)SVcj`, `Hunter - Player Portrait` → `gFkzYKgK8kW`,
`Hunter - Power Ring Track` → `9wtennukMVH`). Nothing is orphaned and nothing has to be deleted
by hand.

### Reading it

- **Threat (top, 4px).** Absent means you are solo, in an arena, or not on anyone's threat
  table. Green fill growing left to right is your share of the pull threshold, and there is a
  **white notch at `x = +20`, i.e. 70%** — when the fill touches the notch, press *Misdirection*
  or stop shooting. Orange past 70, red on aggro, and at **80% a red rim appears around the whole
  strip and pulses** — a 3px band framing the instrument, with nothing drawn over the rails or
  the numbers (see *The 80% alarm is a rim, and why that takes two rules* below). Same trigger,
  same three tiers, same not-in-an-arena gate as v14 — and the party/raid gate **works now**,
  which it never did before v15 (see *The gate that never gated*).
- **Health (middle, 11px).** Green; **bright red under 30%**, and the permanent red waterline at
  `x = −20` shows you where 30% is *before* the colour flips. The exact percent is printed at
  the right end of the rail.
- **Power (bottom, 11px).** Blue; red under 20%. The two aspect-swap breakpoints are now
  full-height waterlines: **red at `x = −30` (20%, Go Viper)** and **green at `x = +30` (80%,
  Back to Hawk)** — the same two thresholds the two alerts fire on, so the rail and the prompts
  agree.
- **The ruler.** Three 1px hairlines at 25 / 50 / 75 on each of the two tall rails, at 18%
  alpha. 33px of ink per rail, no footprint at all, and it turns "estimate a fraction" into
  "count quarters".
- Out of combat the **plate, both tall rails and the 30% waterline** sit at 50% alpha, exactly
  as the cluster did. The threat rail and the alarm carry no fade of their own and never have:
  the rail hides itself at zero threat and the alarm only exists above 80%, so out of combat
  there is nothing of theirs lit to dim.

### What was lost, said plainly

- **Your 3D portrait is gone.** It carried no decision — nothing in a hunter's rotation is
  decided by looking at a model — but v12 put it back deliberately, and its own note said two
  arcs around a live face "read as *a unit* — you". This reverses that on density grounds and it
  is the single most likely thing you will miss. Its *surface* is what survives: the plate is
  the reason an 11px bar and an 11pt number stay readable over Nagrand grass, a snowfield or a
  fire, which was the exact complaint v14 existed to answer.
- **The threat percentage no longer prints.** It is **switched off, not deleted**: `sub.1` keeps
  its index, its `%threatpct%%` token, its font and its offsets, and `text_visible = false` is
  one checkbox in `/wa` away from being back. The justification is that `threatpct` is *scaled*
  so 100 = pulling aggro — an early-warning ratio, not a quantity you spend — so a notch at the
  70 line answers it faster than reading "68" versus "72". It was also the one element of the
  cluster that printed onto open screen with nothing behind it. **If you do tick it back on,
  move it**: its offset is still the `+58` it needed to clear a 100px ring, and that offset is
  measured from **the rail**, not from the group — the rail sits at `y = -94.5`, so the text
  prints at an absolute `(0, -36.5)`, 58px above a 4px lane and about 12px tall, i.e. just above
  your buff row with its bottom edge clipping the top ~2px of the Hunter's Mark icon. (The build
  asserts that number now; an earlier draft of this file said `(0, -52)`, which is what you get
  by walking the offset from the *sill group* instead of from the rail it is anchored to.) The
  offset is deliberately left untouched so that switching the text off is the *only* difference
  from v14 on this region, but there is no sensible resting place for a 10pt number on a 4px
  lane, which is the other half of why it ships off.
- **The two numbers shrink**, health from 16pt to 11pt and mana from 12pt to 11pt, because they
  now live inside an 11px rail instead of on a 44px portrait. The dark plate is what buys that
  back; if it does not read in combat, that is the thing to report.
- **Known cosmetic collision.** The mana number sits at the rail's right end (`x = +32`) and the
  80% waterline is at `x = +30`, so at 11pt the digit block (roughly `x +21..+43`) has a 3px
  green line running through it. Both positions are forced — the number goes at the end that is
  *empty track* when the value is low, and the waterline goes where `x = v − 50` puts it — so
  this ships as-is rather than by moving one of them and making it lie. `OUTLINE` + a black
  shadow on the digits is the mitigation. Judge it in combat, not in the editor.
- **The aspect marks still cannot be aspect-gated.** "Go Viper" only matters in Hawk and "Back
  to Hawk" only in Viper, but both marks are `subtexture`s and **a subregion carries no load
  gate of its own**. Making them gate would mean promoting them to standalone textures, which
  costs two brand-new UIDs; v15 spends none, so they stay always-on exactly as they were on the
  ring.

### The 80% alarm is a rim, and why that takes two rules

`Hunter - Threat Flash` keeps its UID, its `threatpct ≥ 80` trigger, its `ADD` blend, its
`alphaPulse` and its explicit red `(1, 0.10, 0.10, 0.85)`. What changes is its shape: v14 flashed
a 100px `Ring_20px` **annulus**, and v15 makes it a **108 × 37 quad drawn *first*** — at the very
bottom of the strip's stack, 3px larger than the 102 × 31 plate on every side.

**`Square_White_Border.tga` is a filled square with a dark bevel baked into its edge. It is not
an outline and its interior is not transparent.** That is measured off the file shipping in the
live client, not guessed: it is a 256 × 256 32bpp RLE TGA in which **64,516 of 65,536 pixels
(98.44%) are fully opaque** at alpha 255; every pixel **inset 8px or more from the edge**
(n = 57,600) has min alpha 255 and min RGB channel 167; the centre scanline's red channel over
`x = 0..13` climbs `0, 156, 100, 56, 40, 57, 102, 158, 206, 236, 250, 254, 255, 255`, and the
centre pixel is `rgba(255, 255, 255, 255)`. The dark bevel lives in roughly the first 8 columns;
everything inside is solid white.

So **one region on this art cannot trace a hollow frame**, and the shape has to come from
geometry instead. Two rules do it, and *both* are required:

1. **The alarm is bigger than the plate** — `102 + 2×3 = 108` wide, `31 + 2×3 = 37` tall,
   concentric with it.
2. **The alarm is drawn first**, `controlledChildren[1]`, at the bottom of the stack. The plate
   is `[2]` and every readout is above both.

The result is that the only part of the alarm you ever see is the **3px band protruding past the
plate** — 834 px² of pulsing additive red framing the instrument. Its whole interior sits behind
a 45%-black plate and behind all three rails, both 11pt numbers, the ruler and the 30% waterline.
Nothing is painted over at the exact moment you are reading it to choose *Misdirection* or
*Feign Death*.

**Drop either rule and it silently becomes a wash again.** Equal size means the plate covers the
alarm exactly (invisible); drawing it last means the alarm covers the plate exactly (a full-area
additive red sheet over every readout). Both failures look fine in a diff, so the build asserts
each one separately — size, draw index, concentricity, `ADD`, and the literal red — and then
**re-asserts all of them against the decoded shipped string**, not against the tables it just
built.

This construction is correct whether the underlying art is filled or hollow, which is why it is
the one used. It costs no new UIDs: it is the same single region, re-sized and re-ordered.

**One honest caveat: the band is not equally bright on all four sides.** The bevel is a fixed
*fraction* of the 256px source, so it scales with each axis of the quad independently. On a
108 × 37 quad one screen pixel is `256/108 = 2.37` source px across but `256/37 = 6.92` source px
down — so the 3px band samples source `0..7.11` on the left and right (almost entirely the dark
ramp, mean texel 74/255) and source `0..20.76` on the top and bottom (the ramp plus a dozen rows
of solid white, mean texel 185/255). **The top and bottom of the rim read about 2.5× brighter
than its sides.** That is geometry rather than a defect, the plate's own border has the same
2.5× asymmetry, and it is identical in every pack built on this canon — it is written down here
so nothing claims an even band. If the sides read too faint in combat, say so: the fixes are a
wider rim or drawing the alarm on plain `Square_White` instead, and either is one constant.

### The gate that never gated — a real bug this version fixes

Every version of this pack from v5 to v14 gave the threat rail and the 80% alarm a party/raid
load gate written like this:

```lua
load.use_ingroup = true
load.ingroup     = { multi = { group = true, raid = true } }
```

That is the wrong mode, and the failure is silent and total. A WeakAuras multiselect load option
has **three** states: `nil` disables the gate, `false` is **multi** mode (it ORs every key of
`.multi`), and `true` is **single** mode, which reads `.single` and ignores `.multi` completely.
With `use_ingroup = true` and no `.single`, `TestForMultiSelect` in `WeakAuras/GenericTrigger.lua`
emits the literal test `false`, and `ConstructFunction` joins every load test with `and` — so the
compiled load function of both regions was `if (class == "HUNTER") and false and (size ...)`.

**Neither region ever loaded. Not in a party, not in a raid, not anywhere.** The top lane and the
80% alarm have been dead in game since v5 while three versions of this file explained how to read
them. The pack's not-in-an-arena gate one line below was always written `use_size = false`, which
is *why* that one worked — the same shape, in the correct mode.

**Two alerts had it too.** `Hunter - Feign Death Prompt` and `Hunter - Misdirection Prompt` carry
the same party/raid gate written the same way, so both of those have also never appeared. That is
four auras — the whole threat lane plus the two prompts that tell you what to do about threat —
silently absent since v5.

v15 writes `use_ingroup = false` on all four, keeps the same `{ group, raid }` values, and the
build now sweeps **every** aura and refuses to write the string if any multiselect load option is
in single mode without a `.single` (or in multi mode with an empty `.multi`). That is the check
that could have caught this at any point in the last ten versions; the old assert only checked
that the *values* were there, and the values were never the problem. Nothing else about the four
regions changes: same UIDs, same triggers, same tiers, same colours, same arena gates. The
visible effect on your screen is that the threat lane, the alarm and the two prompts **appear**
in a party or raid, having previously appeared nowhere.

### One field a live client has to confirm

`orientation = "HORIZONTAL"` is WeakAuras' own label for **"Left to Right"** on a
`progresstexture`; plain `HORIZONTAL` on that region type is *Right to Left*, which is the exact
**inverse** of the aurabar convention. No string committed in this repo has ever rendered it —
it is transcribed from `Private.orientation_with_circle_types`, and its sibling `VERTICAL` from
the same table is live in a shipped proof-of-concept string. **The check is 30 seconds:** drop
to about half mana and confirm the *empty* half of the rail is on the **right**. If it is
mirrored, the fix is one token and nothing else changes — say so and it ships the same day.

### After updating

**Leave the update dialog's *Arrangement* category CHECKED.** This version re-parents every
region into a renamed group, re-orders `controlledChildren` (the draw order *is* that order —
alarm rim first, then the plate, then the readouts), changes every region's size and region type,
and moves the group from `(-270, +40)` to `(0, -110)`. All of that travels in *Arrangement*, and
the alarm's position in that list is what keeps it a rim instead of a wash. Unchecking it leaves
you with 100px rails still stacked as a ring cluster's leftovers, which is not a HUD.

If you had dragged the pack somewhere of your own, you will have to drag it again — tell me the
coordinates and they get baked into the build script instead.

### What did not move

Not one trigger, condition, colour, spell ID, size or offset outside the strip. The buffs row,
the alerts column, the cooldown row, procs and the whole PvP layer are what v14 shipped —
verified by decoding both strings and comparing all 41 non-strip auras field by field. **Exactly
two of them differ, by exactly one boolean each**: `Hunter - Feign Death Prompt` and
`Hunter - Misdirection Prompt` get the same `use_ingroup: true → false` mode fix as the threat
rail (they carried the identical broken party/raid gate and so also loaded nowhere — see *The
gate that never gated*). The other 39 are byte-for-byte identical, and the *Resources* group's
only diff is the renamed entry in its `controlledChildren` list. The *Resources* group keeps the
`+180` it has carried since v11; the
sill group itself carries the `-150` that lands the strip on the canon, and the build walks the
real parent chain (`top(0,-140) → Resources(0,+180) → Player Sill(0,-150)`) and refuses to write
a string that resolves anywhere but `(0, -110)`.

Every trigger, escalation tier and zero-total guard inside the strip is byte-identical too:
health's `<30%` red and its `maxhealth <= 0 → alpha 0` guard, mana's `<20%` red and its
`maxpower <= 1` guard, threat's 70/90/aggro tiers, its not-arena gate and the mandatory
`threatvalue <= 0 → alpha 0` guard (without which `ProgressTexture` draws a **full** bar at zero
total — a complete green threat bar the instant after a Feign Death), and the alarm's explicit
`{1, 0.1, 0.1, 0.85}` red, its `ADD` blend and its `alphaPulse`. **One load field is deliberately
not byte-identical**: `use_ingroup` on the threat rail and the alarm goes `true → false`, which
is the mode fix described above — the values in `ingroup.multi` are untouched.

### The strip fits, and that is measured rather than claimed

`(0, -110)` puts the strip in a band this pack has never occupied, so "does it fit" stops being
a question about one neighbour. The build projects every dynamic group **six deep** (more
simultaneous elements than this pack can raise) and rectangle-scans **355 boxes from the 35
drawing regions outside the strip**.

**The box it scans is the 108 × 37 alarm envelope, not the 102 × 31 plate** — `x -54..+54,
y -125.5..-88.5`. The rim is the widest thing the strip ever draws and it lights up in the
busiest moment of a pull, so measuring the plate would overstate every clearance in this pack by
3px on every side:

```
355 rectangles, 6 deep, 0 overlaps
envelope scanned: x -54..+54, y -125.5..-88.5   (the alarm rim, not the plate)
nearest neighbour: the buff row (y -80..-40) at 8.5px
                   — four icons tie: Serpent Sting, Hunter's Mark,
                     The Beast Within, Expose Weakness

per-column clearance (printed by the build, projected six deep):
  Buffs         8.50 px   column x  -64..64,   y  -80..-40
  PvP          36.00 px   column x   90..210,  y -290..-44
  Procs        56.00 px   column x  110..322,  y -132..-100
  Cooldowns    64.50 px   column x -106..106,  y -222..-190
  Alerts       76.00 px   column x -170..-130, y  -44..226   (88.07 px corner to corner)
```

The buff row is the tight one and it is **8.5px** clear even with the alarm lit. **The next
tightest is the PvP column at 36px**, and that is worth stating precisely because its anchor is
misleading: the column is anchored at `x = +150`, but `Hunter - Enemy Mana` is a **120-wide**
aurabar, so the column really spans `x +90..+210` and its nearest projected row reaches back to
36px from the rim's right edge — not the ~96px the anchor alone suggests. (An earlier draft of
this file claimed nothing came within 50px of the strip; that was wrong, and the build now prints
the per-column figures above so the claim is measured rather than remembered.) Every column is
clear, 0 of 355 boxes overlap, and nothing else in the pack had to be re-flowed.

## v14 — the health number moves into the middle, over your face

**The complaint this version exists to fix: "percentage in middle can't be seen."** It was
accurate, and it was worse than a taste problem. Through v13 all three readouts sat *outside*
the rings — health 54px below the cluster at 13pt, mana 70px below at 10pt — so the numbers
were small unbacked glyphs floating on whatever the game happened to be drawing. Over Nagrand
grass, a Netherstorm skybox or any snowfield, white text on nothing is nothing. Meanwhile the
one genuinely opaque surface in the whole cluster — your portrait — sat dead centre displaying
a face and no information at all.

v14 spends that centre:

```
                         41%   ← threat, 10pt, +58  (unchanged)

        ,-----------------.
       /  ,-------------.  \      ← threat      100   (unchanged)
      |  /  ,---------.  \  |     ← health       84   (unchanged)
      |  |  |  ,---.  |  |  |     ← mana         62   (unchanged)
      |  |  |  |87%|  |  |  |     ← YOUR FACE    44 — the health % sits HERE
      |  |  |  `---'  |  |  |        now: 16pt, y = 0, dead centre
      |  \  `---------'  /  |
       \  `-------------'  /      same centre, same diameters, same
        `-----------------'       colours — absolute (-270, +40)

                         62%   ← mana, 12pt, -54  (the slot health vacated)
```

| readout | v13 | v14 |
| --- | --- | --- |
| health `%percenthealth%` | 13pt, `y = -54` | **16pt, `y = 0`** — dead centre, on the portrait |
| mana `%percentpower%` | 10pt, `y = -70` | **12pt, `y = -54`** — the slot health left empty |
| threat `%threatpct%` | 10pt, `y = +58` | 10pt, `y = +58` — **unchanged** |

Health goes to the middle because that is where your eye already rests and, now, the only place
in the cluster with something solid behind the glyphs. Mana inherits health's old slot, so the
bottom of the HUD carries **one** number just under the outer ring instead of two stacked ones
trailing off into the terrain. Both keep their `OUTLINE` font and black shadow, their text
tokens and their colours exactly as before.

### Why this needed the draw order changed — the non-obvious half

Moving the offset alone would have looked like **nothing happened**, and that is the part worth
writing down. A `model` region still cannot carry text (WeakAuras' `SubText` supports
`texture`, `progresstexture`, `icon`, `aurabar`, `empty` — not `model`), so the health number is
a sub-region of the **health ring**, not of the portrait it appears to sit on. And through v13
the portrait was the **last** child of the cluster. WeakAuras' `FixGroupChildrenOrder` walks
`controlledChildren` and adds +4 frame levels per child, so later children draw *in front*:
sending the text to the centre would have painted it straight underneath the face.

So the portrait is reordered to be the **first** child, furthest back, and every ring — and
therefore every ring's text — now draws in front of it:

```
v13:  track, threat, halo, health, mana, PORTRAIT      ← face on top, hides the centre
v14:  PORTRAIT, track, threat, halo, health, mana      ← face at the back, text lands on it
```

**This does not bury your face, because a ring is an annulus, not a disc.** `Ring_20px.tga` is a
20px stroke on 256px source art, so a ring of diameter *d* paints only the band from
`0.84375 · d/2` out to `d/2` and is completely empty inside it. Measured on this cluster:

| region | diameter | painted band (radius) |
| --- | --- | --- |
| threat / halo | 100 | 42.19 – 50.00 |
| health | 84 | 35.44 – 42.00 |
| mana / power track | 62 | 26.16 – 31.00 |
| **portrait** | 44 | **0 – 22 (solid)** |

The innermost ink any sibling can put down is at radius **26.16**; the portrait ends at **22**.
That 4.16px gap means no ring's *art* can reach the face at any draw order — only its *text*
can, which is the entire point. The build asserts that clearance, so a future resize of the
mana ring or the portrait fails the build instead of quietly covering your face.

### Updating from v13 — nothing to delete

A plain **Update** in place. All **48** child auras and the top-level group keep their UIDs
byte-for-byte (`stable=48 changed=0 missing=0 parentSame=true`), no aura is added or removed,
and no trigger, load gate, condition, colour, size or position changed anywhere in the pack —
the entire diff is two text offsets, two font sizes and the cluster's child order. Leave
*Group Arrangement* **checked**: reordering `controlledChildren` is exactly what carries the
new draw order, and unchecking it would keep your old stacking and leave the health number
hidden behind the portrait again.

## v13 — the target cluster is gone, and threat comes home

The right-hand cluster is deleted: **target health arc, target portrait, and both of its track
rings** (one of which was the last remnant of the v8/v9 target *mana* arc). Its whole job was
already being done twice by the game — the target frame and the target's nameplate both print
that unit's health, all game, in the two places every player already looks. A HUD element that
restates the default UI costs screen space, draw order and attention and returns nothing for it.

**Threat is not lost — it moves, and it is the reason this version is careful.** Threat was the
one thing that cluster carried that nothing else in the game shows, and dropping it would be a
real regression: a dps who pulls aggro dies. It becomes the **outermost ring of your own
cluster** at 100px, which is also the more honest reading of the number. It is *your* threat, so
it belongs around *your* face.

```
                         41%   ← threat, 10pt, +58 (above the outer ring)

        ,-----------------.
       /  ,-------------.  \      ← THREAT     100   (new outermost ring)
      |  /  ,---------.  \  |     ← health      84   (unchanged)
      |  |  |  ,---.  |  |  |     ← mana        62   (unchanged)
      |  |  |  | @ |  |  |  |     ← your face   44   (unchanged)
      |  |  |  `---'  |  |  |
      |  \  `---------'  /  |     all four concentric on ONE centre,
       \  `-------------'  /      absolute (-270, +40) — exactly where
        `-----------------'       the cluster already was

                         87%   ← health, 13pt, -54
                         62%   ← mana,   10pt, -70
```

Threat keeps **everything** it already had: its Threat Situation trigger on `threatUnit` (that
arg was renamed to plain `unit` at `internalVersion 51` and WeakAuras migrates `< 51` data
forward, so `internalVersion 45` data has to emit the *old* name and let the migration rename
it), its three escalation tiers on `foregroundColor` (`barColor` is aurabar-only and a **silent**
no-op on a ring — Conditions.lua drops a change whose property the region does not declare,
without an error), its party/raid **and** not-in-an-arena load gates, and the mandatory
`threatvalue <= 0 → alpha 0` guard, without which the ring reads as full aggro at zero threat
(`ProgressTexture` draws a **full** circle when its total is 0, which is true the instant after a
Feign Death). The 80% flash halo resizes from 96 to **100** so it pulses *on* the threat ring
instead of orbiting a radius nothing draws any more, and it is drawn **in front of** that arc,
because an `ADD`-blend ring behind an opaque arc only lights the part of the circle threat has
*not* filled — backwards.

Because threat is gated to party/raid and hides itself at zero threat, **the common solo case is
still two rings and a face**. The third arc only appears when threat is a real quantity.

### Updating from v12 — one group has to be deleted by hand

**WeakAuras never deletes an aura that an import does not mention.** v13 genuinely *removes*
five regions rather than recycling them, and no filler region was invented to absorb their UIDs
— that is how a HUD accumulates junk. So after you import v13, the old cluster is still sitting
in your collection, no longer referenced by anything:

> In `/wa`, delete the group named exactly **`Hunter - Target Cluster`** (deleting the group
> offers to take its children with it: `Hunter - Target Health`, `Hunter - Target Ring Track`,
> `Hunter - Target Health Track` and `Hunter - Target Portrait`).

Nothing else needs touching. All **48** surviving child auras keep their UIDs byte-for-byte,
and so does the top-level group (`stable=48 changed=0 parentSame=true`, with the only five
missing IDs being the five named above), so everything else is a plain **Update** in place.
Leave *Group Arrangement* **checked** — it is the category that carries the threat ring's new
100px size, the halo's new size, the `+58` threat readout and the re-parenting into your
cluster.

### What did not move

Not one trigger, gate, condition, colour, spell ID or offset outside the cluster: buffs, alerts,
the cooldown row, procs and the whole PvP layer are byte-for-byte what v12 shipped. Inside the
cluster, health is still 84 at `(-270, +40)`, mana still 62, your portrait still 44, and the two
aspect-swap marks are still on the mana ring at 72° and 288°. The threat ring was added
*outside* them; nothing was resized to make room, and the build asserts every region's parent
chain still sums to exactly `(-270, +40)` and that the diameters strictly nest
(`100 > 84 > 62 > 44`) before it will write the string.

The cluster is now 100px wide, i.e. `x = -320..-220`, and the *Alerts* column is its nearest
neighbour at `x = -170..-130`. That column is a **dynamic** group that grows upward, so a
clearance measured with one prompt showing proves nothing — the build projects the stack **six
deep** (more simultaneous prompts than this pack can raise) and asserts every icon box clears
the cluster box. Three of those six rows share the cluster's vertical band; the horizontal gap
is **50px** at every depth.

## v12 — the rings come back, and your face with them

The Diablo globes are gone. Health, mana, threat and target health are **radial arcs** again —
two per cluster, drawn around a **live 3D portrait** of the unit they belong to, one cluster on
each side of your character. Put beside the ring build of v8/v9, the globes lost: a vessel
answers *"how full"*, which is the sentence a bar already speaks in a rounder frame, while two
concentric arcs around a face answer *"**this unit**, this much"* in one glance — and the
portrait is the part a globe can never have.

Nothing outside the cluster moved: not one trigger, load gate, condition, spell ID or offset in
the buffs, alerts, cooldown row, procs or the whole PvP layer, and the 40 auras outside it are
byte-for-byte what v11 shipped. No aura was added or removed either
(`stable=46 changed=0 missing=0` — the seven auras missing from `stable` are the ones that
changed *name*, and every one of them kept its UID, so nothing is orphaned).

### The cluster

```
                                                                41%  ← threat, above the arcs

        YOU  (-270, +40)                            TARGET  (+270, +110)

         ,-------------.                             ,-------------.
        /  ,---------.  \   ← health 84             /  ,---------.  \   ← THREAT 84
       |  /  ,-----.  \  |  ← mana 62              |  /  ,-----.  \  |  ← target health 62
       |  |  |  @  |  |  |  ← your face 44         |  |  |  #  |  |  |  ← its face 44
       |  \  `-----'  /  |                         |  \  `-----'  /  |
        \  `---------'  /                           \  `---------'  /
         `-------------'                             `-------------'

              87%  ← health                                88%  ← target health,
              62%  ← mana                                       same baseline as yours
```

| | player cluster | target cluster |
|---|---|---|
| **outer arc — 84** | health | **threat** |
| **inner arc — 62** | mana | target health |
| **portrait — 44** | you | your target |

Both sides are **two arcs and a face**, which is what makes them read as a matched pair rather
than as two unrelated widgets. Every number above is canon: outer 84, inner 62, portrait 44,
clusters at an absolute `(-270, +40)` and `(+270, +110)`, health `%` at 13pt under the arcs,
power at 10pt below it, threat at 10pt above them. Those values are byte-identical in all seven
class packs in this repo, and the build **refuses to write the string** unless every region's
parent chain sums to exactly its canonical absolute screen position — the nesting does the
work, not a pile of hand-typed offsets. `x = ±270` is not a taste call: the *Alerts* column at
`x = -150` and the *PvP* column at `x = +150` are dynamic groups that grow vertically, so a
cluster at `±190` is walked into by the alert stack from the second simultaneous prompt onward.

### The portrait is why the numbers sit outside the rings

A `model` region cannot carry a text sub-region at all — WeakAuras' `SubText` supports
`texture`, `progresstexture`, `icon`, `aurabar` and `empty`, and not `model`. That is the one
thing the globes bought by deleting the face: the number could live in the middle. Getting the
face back means the numbers move back out, just under the arcs (and just above them for
threat), which is where v8 and v9 had them.

It is worth the trade on the target side especially: the portrait is a real 3D head, so the
cluster tells you **what you are shooting** — mob, player, class, elite — without a nameplate
and without the pack ever knowing the target's class. Both portraits carry the unit in
`model_fileId` *and* `model_path`, because current WeakAuras reads the first, WA 3.5.0 read the
second, and the migration that copies one to the other is gated on `IsClassicEra()` — which a
2.5.x TBC client is **not**. Emitting only `model_path` is a silent no-op that leaves an empty
square in the middle of the cluster.

### Two arcs, not three — the target's mana readout is gone

v8/v9 gave the target three arcs (threat, health, mana) against the player's two, and that is
exactly what made the old cluster look busy and uneven. The target's power readout is dropped
on purpose, and it is the **one honest loss** in this version: in the open world you no longer
see at a glance whether a mob runs on mana. In an arena the *Enemy Mana* rows (v5) still answer
that question far better, with names attached, which is where the Viper Sting decision actually
gets made.

Its aura is *not* orphaned. Its UID now carries the **track ring** behind the threat arc — a
dark ring at the same radius, drawn behind it. Threat does not load solo or in an arena at all
and hides itself at zero threat, so without that ring the target cluster would collapse to one
arc and a face for every solo player while yours still shows two. Two more track rings sit
behind the player's mana arc and the target's health arc, both of which carry the same kind of
zero-total guard. They are the v10/v11 glass rims, respent: same UIDs, same slots in the build
order, no orphans left behind.

### What carried over untouched

- **Every escalation.** Health goes bright red below 30%, mana below 20% (the Go-Viper
  threshold, so the arc and the alert agree), threat runs green → orange at 70% (press
  *Misdirection*) → red at 90% (press *Feign Death*) → deep red the moment you are pulling
  aggro. On a `progresstexture` the condition property is `foregroundColor` — it was `barColor`
  on v7's bars and `color` on v10/v11's rim texture, and **Conditions.lua drops a change whose
  property the region does not declare, in silence**, so each of those renames is a dead
  escalation if it is missed.
- **Every zero-total guard.** `ProgressTexture` draws a **full** circle at `total == 0` (the
  aurabar drew empty), so each arc hides itself instead: `maxhealth <= 0`, `maxpower <= 1`, and
  — the one that fires in real play — `threatvalue <= 0`, which is true the instant after a
  Feign Death. Without it the threat arc would slam to a complete green circle, i.e. *"you are
  fine"*, at the exact moment the readout exists to speak.
- **Threat's gates**: party or raid only, never in an arena, plus the pulsing red `ADD`-blend
  halo at 80%+ threat, which is now the same ring art one stroke outside the threat arc.
- The out-of-combat fade to 50% alpha on the player's cluster, and the target cluster's
  self-hiding: with no target, the Health and Threat prototypes produce no state at all.

### The breakpoints go back to being angles

On a vessel, a threshold is a horizontal waterline at a fixed height. On a ring it is an
**angle**, so the two aspect-swap marks are computed by trigonometry from the arc's own radius
again:

```
r = INNER/2 * 0.94        x = r·sin(2π·f)        y = r·cos(2π·f)
```

`sin` on `x` and `cos` on `y`, because the fill starts at 12 o'clock and runs clockwise, so
`f = 0` must land at the top. The red *Go Viper* mark at 20% lands at `(27.71, 9.0)` — 72°
clockwise from the top — and the green *Back to Hawk* mark at 80% at `(-27.71, 9.0)`, 288°. The
build re-derives the angle back out of the emitted offsets and refuses to write a string whose
marks are not on their own ring at their own threshold; a mark 9px inside its arc looks exactly
like a mark on it until somebody measures.

The **specular highlight** each globe carried is dropped: it was a glass effect for a filled
vessel, and there is no glass on an arc.

### Updating from v11 — leave "Arrangement" **checked**

Every v11 aura keeps its UID and its build order (`stable=46 changed=0 missing=0`, nothing
added, nothing lost), so WeakAuras offers a plain **Update** in place and no leftover has to be
deleted by hand. *Group Arrangement* is what carries the region sizes, the sub-region changes
and the new cluster offsets, i.e. the entire content of this version — leave it checked, or you
will get v12's rings at v11's globe geometry.

## v11 — the globes come up beside you, and the glass catches light

*(v12 replaced every globe described below with a ring around a live portrait, and dropped the
specular highlight with them. The position discipline is unchanged — one canonical set of
numbers in all seven packs, proved by walking each parent chain — but the geometry is now the
ring canon. See **v12** above for what ships today.)*

Two changes, both to the vessels and to nothing else. Not one trigger, load gate, condition,
colour, spell ID or region type moved; no aura was added or removed
(`stable=53 changed=0 missing=0`); and every element outside the globes — buffs, alerts, the
cooldown row, procs, the whole PvP layer — is byte-for-byte what v10 shipped.

### 1. They flank you now, instead of sitting in a band at the bottom

v10 parked all three globes on one line at the bottom of the HUD, at an absolute
`y = -262`. Three round vessels in a row under everything else read as *a second bar bolted
onto the interface* — a widget you consult, not part of your character. So they moved up and
apart, to stand either side of you:

| Globe | v10 | **v11** |
|---|---|---|
| **Life** | `(-150, -262)` | **`(-190, +40)`** — left of your character |
| **Power** | `(+150, -262)` | **`(+190, +40)`** — right of your character |
| **Target** | `(0, -262)` | **`(0, +110)`** — above and between the two |

```
                              TARGET
                             (0, +110)

                               34%  ← threat
        LIFE                  ,-----.                       POWER
     (-190, +40)             /  47%  \                    (+190, +40)
                            | ####### | (o)
      ,---------.            \#######/  ^                  ,---------.
     /   ,-.     \            `-----'   target            /   ,-.     \
    |   (   )62%  |            rim =    power            |   (   )88%  |
    |             |            threat                    |~~~~~~~~~~~~~| ← 80%: back to Hawk
    |~~~~~~~~~~~~~|                                      |#############|
    |#############|              @  ← you                |#############|
     \###########/                                       |~~~~~~~~~~~~~| ← 20%: go Viper
      `---------'                                         \###########/
                                                           `---------'
```

Those three coordinates are not a taste call, and they are not adjustable by eye: they are
the tightest **collision-free** arrangement in this repo's shared layout, scanned against
every element in all seven class packs. `x = ±170` walks into the *Alerts* column at
`x = -150` and the *PvP* column at `x = +150`; `x = ±210` walks into the PvP layer's
elements at `(200, -44)`. The build **refuses to write the string** unless each globe's
parent chain sums to exactly these absolute screen positions, so no future edit can drift
them by hand.

The nesting does the work, not a pile of hard-coded numbers: the *Resources* group carries
`+180` (which is `GLOBE_Y` minus the top group's own `-140`), and the *Target Globe* cluster
carries a further `+70` — the only place in the pack that knows the target vessel sits higher
than the pair. Every globe, rim, halo and readout inside those groups still has an offset of
`0` or its own `±270`.

### 2. Every globe is glass now, not a flat disc

A vessel filled with one flat colour is a sticker on your screen. What makes a sphere read as
a sphere is **light striking its curve off centre**, so every globe — including the target's
small power vessel — gained a **specular highlight**: the same `Circle_Smooth` disc as the
liquid, squashed to an ellipse 0.46 wide and 0.34 tall of its own globe, pushed up and to the
left, white at 28% alpha.

**The blend mode is the whole recipe, and it is `ADD`.** Sub-regions draw in order, and on
these vessels the percentage lives *inside* the glass — so the highlight is painted over the
number. A normal (`BLEND`) white sheet would wash that number toward grey: the readout the
globe exists to carry would get harder to read in exchange for a prettier globe. `ADD` can
only ever brighten what is beneath it, so the white text stays white and the dark, empty part
of the vessel lifts. It is also why this is a *highlight* and not the more obvious dark
vignette around the rim — a dark overlay has no additive form.

The highlight is **appended** to each globe, never inserted:

| Globe | Sub-regions after v11 |
|---|---|
| **Life** | 1 = `%` readout, **2 = highlight** |
| **Power** | 1 = `%` readout, 2 = 20% waterline, 3 = 80% waterline, **4 = highlight** |
| **Target** | 1 = `%` readout, **2 = highlight** |
| **Target power** | **1 = highlight** (this vessel carries no readout) |

That ordering is load-bearing. Conditions address sub-regions **positionally**, as `sub.N`,
and inserting anything ahead of a referenced index retargets that condition at the wrong
thing with no error and no warning. The build asserts that the pre-v11 prefix of every
vessel is untouched and that the highlight is the last entry, so this cannot go wrong quietly
later.

### Updating from v10 — leave "Arrangement" **checked**

Every v10 aura keeps its UID and its build order (`stable=53 changed=0 missing=0`, nothing
added, nothing lost), so WeakAuras offers a plain **Update** in place. *Group Arrangement* is
what carries the new positions and the new sub-region, i.e. the entire content of this
version — leave it checked or you will get v11's glass at v10's coordinates.

## v10 — Diablo globes

*(v11 moved all three globes and gave every one of them a highlight. The positions in this
section are where v10 put them; see **v11** above for what ships today. Everything else below
— what each vessel reads, the threat rim, the waterlines — is still current.)*

**The rings are gone.** Your health and your mana are now **globes**: round glass vessels
that fill from the bottom up like liquid, with the percentage **inside** the glass.

```
        LIFE                      TARGET                      POWER
     (-150, -262)                (0, -262)                 (+150, -262)

      ,---------.                                          ,---------.
     /           \                 34%  ← threat          /           \
    |     62%     |               ,-----.                 |     88%     |
    |             |              /  47%  \                |~~~~~~~~~~~~~| ← 80%: back to Hawk
    |~~~~~~~~~~~~~|             | ####### | (o)           |#############|
    |#############|              \#######/  ^             |#############|
     \###########/                `-----'   target        |#############|
      `---------'                  rim =    power         |~~~~~~~~~~~~~| ← 20%: go Viper
                                   threat                  \###########/
                                                            `---------'
```

| Vessel | Where | Reads |
|---|---|---|
| **Life** | left, 72px, deep red | Your health, filling upward. Goes **bright red below 30%**. Half alpha out of combat. |
| **Power** | right, 72px, blue | Your mana — always mana, in every hunter spec, so the glass is mana blue. Goes **red below 20%**, the Aspect of the Viper line, the same number the *Go Viper* prompt fires on. Carries both aspect-swap marks (below). |
| **Target** | centre, 44px, deep red | Your target's health, with its own number inside. Disappears completely when you have no target. |
| **Target power** | beside it, 22px, blue | Mana only, and deliberately **no number** — rogues, warriors and every powerless mob draw nothing at all, so a small blue vessel appearing here means *"this one casts, and here is what it has left"*. |

### The percentage is inside the glass now, and the portrait is the price

The live 3D portraits are **gone**. That is not incidental — it is the trade that buys the
number its place. A WeakAuras `model` region cannot carry a text sub-region *at all*, which
is the only reason the ring build had to park its percentages outside the rings, in the band
where the world is. A `progresstexture` can, so the moment the face leaves, the number moves
to the middle of the vessel, where your eye already is. Diablo's globes never had a face
either.

**Nothing was orphaned by this.** Both portrait auras were *recycled* into the glass rims
rather than deleted, keeping their UIDs, so the update leaves no leftovers in your WeakAuras
list to hunt down.

**The honest loss:** no live face for you or your target. If you relied on the portrait to
tell mobs apart, that job goes back to your nameplates and your target frame.

### Threat is the target globe's rim

Threat has no natural vessel — it is not a resource you spend, and giving it its own globe
would have meant a fourth container and a fourth patch of screen. So it became the **colour
of the glass around your target**:

| Rim | Meaning | What to press |
|---|---|---|
| **green** | you are fine | — |
| **orange** | 70%+ of the tank's threat | *Misdirection* (its prompt fires here too) |
| **red-orange** | 90%+ | *Feign Death* (its prompt fires here too) |
| **deep red** | you have aggro | you are the tank now |
| **pulsing red halo** | 80%+ | the same warning v7 flashed on the bar |

The percentage sits just above the globe. Same trigger, same three tiers and the same gates
as every version since v5: **party or raid only, never in an arena** (an arena has no threat
table). When threat does not apply — solo, in an arena, or in the moment right after a Feign
Death when your threat is genuinely zero — the rim falls back to plain **brass**, which says
nothing rather than lying green.

### The aspect-swap marks got simpler

Both marks are still there, and on a vessel they are what they always should have been: two
thin **waterlines** across the mana globe, red at 20% (*go Viper*) and green at 80% (*back to
Hawk*). The liquid crosses the red line exactly when the *Go Viper* prompt fires and the
green one exactly when *Back to Hawk* does. On the old ring these needed trigonometry and
re-derivation every time the ring changed size; on a globe a threshold is just a height.

### The buff row moved up

The one thing outside the globes that had to change. In v10 the target globe sat at
`(0, -262)` — where the Serpent Sting and Hunter's Mark timers used to be. That row was
re-anchored to `(0, -60)` and **has not moved since**: v11 lifted the globes off that band
entirely and left every icon in this row exactly where v10 put it, so the timers are still
untouched — same triggers, same gates, same sizes, same order, same offsets.

### Updating from v9 — leave "Arrangement" **checked**

Every v9 aura keeps its UID (`stable=47 changed=0 missing=0`; the four auras that changed
name kept theirs too), so WeakAuras offers a plain **Update** and the globes replace the
rings in place. Two auras are new (the power globe's rim and the target power globe's rim).
Leave *Group Arrangement* checked — it carries the sizes and offsets that are the whole
content of this version.

## v9 — one orb size, shared by every pack

*(v10 replaced every ring described below with a globe, and deleted the portraits. The
geometry discipline is unchanged — one canonical set of numbers in all seven packs — but the
numbers themselves are now the globe canon. See **v10** above for what ships today.)*

Pure geometry. **No aura was added, removed, retriggered or recoloured** — not a trigger, not
a load gate, not a condition, not a spell id (`stable=51 changed=0` against v8). What changed
is that the orbs now use **one canonical geometry that is byte-identical in all seven class
packs in this repo**, so a hunter alt on a paladin's HUD sees the same rings in the same
places at the same size.

v8 shipped seven packs that each picked their own numbers, and inside *this* pack the two
sides did not even agree with each other: the player orb was 84px across, the target orb 108.
That mismatch is what read as "uneven" on screen. Now both clusters present the **same outer
diameter and the same portrait**, and the target simply nests one more arc inside:

```
        player  (-260, -60)                       target  (+260, -60)

        (( health 104 ))                       ((( threat 104 )))
        (  mana   78  )                        ((  health  78  ))
        (  face   46  )                        (   mana    54   )
             87%                               (   face    46   )
             62%                                       41%   ← threat, above
                                                       88%   ← health, below
```

| | player cluster | target cluster |
|---|---|---|
| **outer — 104** | health | threat |
| **middle — 78** | mana | health |
| **inner — 54** | *(unused)* | mana |
| **portrait — 46** | you | your target |

Everything else about the look follows from that:

- **`Ring_20px` replaces `Ring_10px`.** The number is the stroke weight in WeakAuras' 256px
  source art, so the drawn arc is `diameter × N/256` — on a 104px ring the old texture drew a
  4px hairline that read as a *wire*. It now draws an 8px arc you can see at a glance.
- **The readouts share one baseline.** Health is 14pt at −60 and power 11pt at −76 on *both*
  clusters (threat stays 11pt at +60, above the ring), so the target's health number no longer
  hangs 20px lower than yours.
- **The portrait nearly doubled**, 26px → 46px. At 26px the live 3D head was a smudge; the
  whole point of a portrait orb is that you can tell what you are shooting at.
- **The aspect-swap ticks were re-derived, not left behind.** Both marks on the mana ring are
  positioned by trigonometry from the ring's radius; growing the ring 60 → 78 moved the 20%
  mark from `(26.63, 8.65)` to `(35.19, 11.43)` and the 80% mark to `(−35.19, 11.43)`. They
  still sit on the arc at exactly 20% and 80% of the way round.
- **The clusters moved to `(±260, −60)`**, up from `(±250, −100)`, which is what keeps a 104px
  orb and its two numbers clear of the cooldown row underneath.

**Updating from v8: leave *Group Arrangement* checked** (it is checked by default). That is the
category that carries width and height for child auras — the entire content of this version.
Uncheck it and you keep v8's mismatched sizes.

## v8 — the middle of the screen is empty

*(v9 rebalanced every size and position quoted in this section — the ring assignment below is
still what the pack does, but the numbers are v8's. See **v9** above for what ships today.)*

The three 172x14 bars that sat under your feet — health, mana, threat — are gone as
rectangles. The **same four auras**, with the same ids, the same UIDs, the same triggers
and the same load gates, are now radial rings around two small **unit orbs** that flank
your character:

```
        Alerts                                            PvP stack
          ↑                                                   ↓
   ( health ring )                                  (( threat ring ))
   (  mana ring  )        ← your character →        ( target health  )
   (  portrait   )                                  (  target mana   )
     -250                       0                    (   portrait   )
                                                            +250
```

Each orb is a live 3D portrait of the unit with its health drawn as the outer arc and its
primary power as the inner one, and the numbers that matter printed just outside the rings
(see the table below for exactly which). **Player on the left, target on the right.** With
no target, the entire right-hand cluster disappears — the
Health, Power and Threat triggers all end in a "does this unit exist" test, so there is no
empty circle sitting there.

**Why.** Unit state belongs *at the unit*, not stacked in the most expensive real estate on
the screen. The band directly under your character is where you look for a boss's cast bar,
a void zone, or the thing that is about to kill you; v7 parked 172px of green rectangle
there and made you read past it. That band is now clear.

### What each ring says

| Ring | Where | Reads |
|---|---|---|
| **Health** (green) | both orbs, outer | Your own goes **red below 30%** — the escalation the flat green bar never had. Percentage printed beneath. |
| **Power** (blue) | both orbs, inner | Yours is mana, and it turns **red below 20%**: the Aspect of the Viper line, the same number the *Go Viper* prompt fires on. |
| **Threat** (green → orange → red) | target orb, outermost | Same three tiers as v7 — orange at 70% (press *Misdirection*), red at 90% (press *Feign Death*), deep red the moment you are actually pulling aggro — plus the pulsing red halo at 80%+. Percentage printed *above* the orb. Party/raid only, never in an arena. |

Threat moved onto the **target** orb on purpose: threat is a number about a specific mob,
and now it is drawn around that mob's face. It appears only while you actually have a
threat state on your target and vanishes with the target.

### New: the mana ring shows the aspect-swap band

Two static ticks sit on the mana ring at exactly the thresholds the two aspect alerts fire
on: a **red tick at 20%** (*Go Viper*) and a **green tick at 80%** (*Back to Hawk*). The
arc sweeps anticlockwise past the green mark and down towards the red one, so the swap
window is a thing you can *see coming* rather than a prompt that arrives. Nothing was lost
here — the v7 bars carried no tick marks at all; these are new.

### New: the target orb

Four of the six new auras make the right-hand cluster:

- **Target health** — the kill-window read: execute range, whether the pull is going
  anywhere, whether to swap.
- **Target mana** — deliberately an arc with **no number**. Rogues, warriors and every
  powerless mob produce no state at all, so an arc appearing here means *"this one casts,
  and here is what it has left"* — the Viper Sting / Silencing Shot read out in the open
  world, where the arena-only *Enemy Mana* bars do not load. Three stacked numbers under
  one orb would just be a bar stack again, rounder.
- **Two live portraits** — a real 3D head, so the orb identifies the mob or the player
  without a nameplate and without the pack ever knowing their class.

### Updating from v7 — leave "Arrangement" **checked**

**Nothing is orphaned and nothing needs deleting.** Every one of the 45 v7 auras keeps its
UID (`stable=45 changed=0 missing=0`), so WeakAuras offers a plain **Update** and the four
Resources auras change shape in place. There is no leftover "Hunter - Resources" group to
clean up, because it is the same group.

One thing does matter in the update dialog: **leave *Group Arrangement* checked** (it is
checked by default). That category carries width, height and position *for child auras*, and
the rings are 84x84 and 60x60 where the bars were 172x14. Uncheck it and you get three
squashed ellipses stacked where the bars used to be. Your dragged position of the *whole*
HUD is a separate category (*Size & Position*, on the top-level group only) and is
unchecked by default, so that is still preserved.

### Honest losses

- **A ring is less precise than a bar.** A 172px rectangle lets you read "about 40%" at a
  glance more accurately than a 84px arc does. The percentage numbers are still printed
  under both orbs, and the *decisions* the pack cares about — 20% mana, 30% health, 70/90%
  threat — are all colour flips, which read faster on an arc than a length ever did.
- **The threat number moved above the orb** instead of sitting at the right end of a bar.
- **The three bars' 1px borders are gone.** A `progresstexture` has no bar-border
  sub-region; the dark unfilled track behind each arc does that job instead.
- **No resource breakpoint marks were lost.** The aurabar tick sub-region is aurabar-only
  and could not have been carried over — but v7 used none, so there was nothing to carry.
  v8 adds two.

## v7 — the Horde trinket readout actually works

`Hunter - Trinket DOWN` was watching item **30346**, which is the *Priest-only* Medallion
of the Horde. A hunter can never equip it, so the trigger could never fire: a Horde hunter
who trinketed a fear saw nothing, and would reasonably conclude their medallion was still
up. It now watches **37865**, the all-class Medallion of the Horde, matching every other
pack. Alliance (37864) and both level-60 Insignias were already correct. UIDs unchanged —
imports as an Update.

## v6 — the cooldown row shows what you CANNOT press

v6 changes **only the cooldown row**, and only how its eleven icons decide when to be on
screen. No new auras, nothing removed, no load gate touched, no new custom code
(`stable=45 changed=0` — every v5 aura keeps its UID, so re-importing offers **Update**).

**The old row was inverted.** All eleven icons sat on screen permanently and merely dimmed
when the ability was down, so the row was busiest exactly when you had the fewest options —
and you already know your own spellbook. What you cannot know is what is *unavailable*, and
for how long.

So the situational buttons now appear **only while their cooldown is running**, carrying the
swipe and the countdown, and vanish the moment the ability is back. The row is a dynamic
group, so the gap closes: **absence is the readout.** An empty stretch of row means
everything is up. Two icons means exactly two things are down, and both are counting back.
The grey went with the change — under the new rule every visible icon is on cooldown by
definition, so greying them all would only make them harder to tell apart at a glance.

### The two buttons that stay, and now glow gold

Hiding an icon is the wrong answer for a button you press the moment it is up, because a
hidden icon cannot announce itself. Two shots in this row are exactly that, and neither had
a glow before — v6 gives them one:

| Icon | Why it stays visible |
|---|---|
| **Multi-Shot** | Both raid guides say to press it on cooldown in place of a Steady Shot — it is more damage per use than Steady Shot even on a single target. This is the button you press most. |
| **Arcane Shot** | The other half of the same weave slot when mana allows, and the instant you fire while moving. A 6s shot inside the core damage loop. |

Both are always on screen with two states and no third: **dim** while the cooldown runs,
**full colour with a gold pixel glow** the instant it is back — the same gold *Kill Command*
and the *Misdirection* prompt already wear, so the pack speaks one colour language. Out of
combat the pair fades to half alpha and the glow is forced off, so an idle row is still.

Arcane Shot was the closest call in the row: a mana-permitting filler is not Multi-Shot. It
went the visible-and-glowing way because it is in the core loop, and for anything in the core
loop a "press this now" signal is worth more than a "you cannot press this" one.

### Everything else answers only "when is it back"

**Intimidation, Readiness, Wyvern Sting, Misdirection, Feign Death** — plus the two
arena/battleground icons, **Freezing Trap** and **Scatter Shot** — are all pressed when a
circumstance calls for them, not on sight. They are gone from the row while ready.
Misdirection and Feign Death are the clearest case: their moment is already owned by a
threat-paired prompt in the *Alerts* flow (70% and 90%), which interrupts you; the row icon
only ever had to answer "when does it come back".

**Rapid Fire** and **Bestial Wrath** join them — a burst window is spent at a moment (the
opener, and again after Readiness), not on sight — but they keep both of their existing
states, because those states mean something the other icons do not have:

- **absent** — ready, use it when the window is worth it;
- **full colour + glow, swipe counting the buff** — the window is *live* (15s of +40% ranged
  haste; 18s of +50% pet damage);
- **dim, swipe counting the cooldown** — the window is spent and the button is recharging.

That is why those two alone kept their grey: on them it does not mean "on cooldown", it means
"the window is over", and it is the only thing that distinguishes the two visible states.

### What this looks like in a pull

Out of combat: two half-faded shots, nothing else. Pull, and the row fills only as you spend
things — Bestial Wrath lit while its window runs, then grey, then gone at 2 minutes; Multi-Shot
flashing gold every time it comes up. Glance down mid-fight and the row is a short list of
what you *cannot* do, in the order it comes back.

## v5 — the CC glow speaks, and the arena stops lying

v5 is a small, surgical Update of v4: **one new aura, two changed elements, nothing removed**
(`stable=44 changed=0` — every v4 aura keeps its UID, its triggers and its position). All
three changes come from three questions v4 shipped as "not proven"; each one has now been
settled against the WeakAuras source, and this is what the answers buy you.

### 1. `CC ON ME` is colour-coded — the glow tells you which break works

v4's prompt told you *that* you were controlled and for how long. It now tells you **what to
do about it**, in colour, which is the only thing you can actually read while stunned:

| Glow | Category | What you do |
|---|---|---|
| 🔴 **red** | stun (`STUN`, `STUN_MECHANIC`) | Nothing you own breaks a stun. It is the medallion or you eat it — and *Trinket DOWN* in the PvP stack is the other half of that sentence. |
| 🟣 **purple** | fear (`FEAR`, `FEAR_MECHANIC`) | The medallion, **or** Will of the Forsaken if you are Undead. The pack tracks that racial's own cooldown, so "which break do I spend" is answerable at a glance. |
| 🔵 **blue** | root (`ROOT`) | **Do not trinket.** A hunter shoots at full effect while rooted; a root only kills you if a melee is closing, and that has its own alert (*DEADZONE*). Save the break for the stun that follows. |
| 🟢 **green** | confuse / polymorph (`CONFUSE`) | Ride it out — any damage breaks it and your pet is already hitting something. Trinketing here throws the break away for an effect that is about to end anyway. |
| 🟡 **amber** | silence & school lockout (`SILENCE`, `PACIFYSILENCE`, `SCHOOL_INTERRUPT`) | Your shots *and* your traps are gone for the duration, so there is no "play through it" line. Trinket **earlier** than you otherwise would. |

Anything not in that list (charm, disarm, pacify, possess) keeps the red default, which reads
as "spend the break" — the safe fallback. The colours are **identical to the mage pack's**, on
purpose: if you play both, you learn one language and it transfers.

This works because `sub.1.glowColor` is a real, settable condition property (the glow
subregion exposes all fourteen of its keys to conditions, not just visibility) and because
this element's glow was already built with a custom colour, which is what arms `useGlowColor`
— without that flag the colour is stored and then silently ignored.

### 2. The threat bar and threat flash no longer load in an arena

An arena has **no threat table**. In v4 the bar loaded there anyway (an arena team is a
party), so it sat as a dead green rectangle in the slot closest to your crosshair. Both
elements now carry an instance-size gate that lists everywhere *except* `arena`:
open world, 5-man, 10/20/25/40-man and battleground.

Nothing about PvE changed. The open world is the literal instance-size value `none`, so it is
listed explicitly and the bar behaves exactly as it did while questing, in dungeons and in
raids. Battlegrounds keep it too — Alterac Valley has NPCs and a real threat table. (There is
no "not arena" switch in WeakAuras; the complement has to be spelled out, which is what this
does.)

> **Correction, written in v15.** The instance-size half of this — `use_size = false` with a
> `size.multi` list — was written correctly and has always worked. The party/raid half added in
> the same version was not: it shipped `use_ingroup = true` beside an `ingroup.multi` table and
> no `ingroup.single`, which is WeakAuras' *single-select* mode, and with a nil single the load
> test compiles to the literal `false`. Both the threat bar and the flash therefore loaded
> **nowhere at all** from v5 through v14, in PvE as much as in an arena. v15 fixes the mode; see
> *The gate that never gated* in the v15 notes above.

### 3. New: `Enemy Mana` — one bar per opponent, arena only

A 120x12 bar per arena opponent **whose primary resource is mana**, showing their name and
their remaining mana percent. Rogues and warriors never produce a row, so what is left on
screen is the enemy healer and casters — the list of people you can drain.

Mana denial is how a hunter wins a long game, and Viper Sting is a choice of *target*, not a
rotation slot. This bar is the target-selection half of the *Viper Sting Out* row you already
have: it says who is worth the sting, and when the drain has done its job. Below **20%** the
bar turns amber — this pack's "press now" colour — because a healer under 20% cannot chain
heal through a swap, and that is the moment to stop kiting and kill something.

Arena-only (`arena1..arena5` do not exist in a battleground) and gated on `spellknown 3034`,
so it appears next to the drain it exists to aim. One honest caveat: how often the 2.5.x
server pushes power updates for arena units is a client behaviour, not an addon one — the
readout refreshes at minimum whenever the arena frames update, so treat a number that has not
moved in a while as stale rather than as a measurement.

## v4 — PvP layer

v4 adds twelve auras that load **only inside an arena or a battleground**. Everything else
is untouched: same uids, same triggers, same load rules, same positions
(`stable=32 changed=0` against v3).

**Nothing changes in PvE.** Every new aura carries its own instance-type load gate
(`use_size = false, size = { multi = { arena = true, pvp = true } }`), not just the group it
sits in — a group's load is not a child gate. In a raid, a dungeon, or out in the world the
new group is empty, the cooldown row is the same nine icons it was in v3, and the alert flow
holds the same nine prompts. Three of the current elements read `arena1..arena5` and are therefore
**arena-only**, because those unit ids do not exist in a battleground and a BG-loaded arena
element is a permanently blank slot.

### New group: `Hunter - PvP` `(150, 96)`

A downward dynamic stack on the opposite side of your character from `Alerts`, holding the
state readouts. It is empty when nothing needs saying:

| Element | What it shows | What you do differently |
|---|---|---|
| **Trinket DOWN** | your medallion/insignia **while it is on cooldown**, desaturated, with the swipe | Absence means ready. While the icon is up your only break is Bestial Wrath / The Beast Within, so you eat the next CC instead of pre-trinketing, and you stop pushing into a setup you cannot escape. Four item ids are watched (Medallion of the Horde/Alliance, hunter Insignia of the Horde/Alliance) — never the equipment slot, which would report "trinket down" for a PvE on-use trinket in the other slot. |
| **Will of the Forsaken DOWN** | Undead only: the racial while it is on its own 2-minute cooldown | A second, independent break. Knowing it is up is what lets you spend the medallion on the first stun instead of saving it for the fear. Gated on `spellknown 7744`, so nobody else ever sees it. |
| **Enemy Trinket** | one clone per opponent, counting 120s down from the moment you *saw* them use it | Their break is gone: this is the window where a Scatter → Freezing Trap or a Wyvern Sting actually sticks, so the whole team's CC chain goes in now instead of being wasted. |
| **Trap Armed** | a Freezing Trap you just dropped, counting down its 1-minute lifetime | Pull the target across it, and recall your pet first — your own pet is the most common trap-breaker. It also stops you burning the second trap while the first is still live. |
| **Viper Sting Out** | one clone per opponent carrying **your** Viper Sting, with the remaining 8s | Mana denial is how a hunter wins a long game, and the sting is dispellable. The row emptying *is* the re-apply prompt; tracked on the opponents, not on the kill target, because the drain belongs on whoever heals. Arena-only. |

### New prompts in `Alerts`

Same language as the rest of the flow — they slide in from below, glow, and fly up on exit:

- **CC ON ME** — any loss-of-control effect on you, with its own icon and a countdown.
  It answers "ride it or spend the break": a stun means trinket, a root does not, and a
  school lockout means the spell you were about to use is gone for the duration. This is
  also the only element in the pack that can see a Kick/Counterspell **school lockout**,
  because a lockout is not an aura and no aura trigger can ever find it. No combat gate —
  the opening Sap or trap lands before you are in combat. Since v5 the glow **colour** carries
  that answer, so you do not have to read anything: see *v5* above.
- **DEADZONE** — a hostile target inside roughly 8 yards, in combat. Your shots do not work
  right now, so the next press is Wing Clip, Scatter Shot, a trap or melee, never a shot.
  The deadzone kills more hunters than any cooldown mistake and is one of the very few
  positioning facts a HUD can express. It is a range *estimate* (WeakAuras' range check is
  approximate), so treat it as a warning, not a measurement — and it is the pack's only
  frame-update trigger, which is exactly why it is behind the PvP and combat gates.
- **SILENCE NOW** — your target is casting **and** Silencing Shot is genuinely castable
  (off cooldown, in range, mana available). The prompt uses "Action Usable", so it never
  glows for a button that would fail; the countdown under it is the remaining cast time.
  Marksmanship only, via `spellknown 34490`.
- **TARGET IMMUNE** — the target gained a hard stop: Divine Shield, Blessing of Protection
  (physical immunity, i.e. every shot you own), Ice Block, Cloak of Shadows, or The Beast
  Within. Stop the burst — swap, pool, or wait it out. The icon shows *which* immunity,
  because that decides swap versus wait.

### Two icons join the cooldown row (arena/BG only)

**Freezing Trap** and **Scatter Shot**, both gated on their own spell id *and* the PvP gate.
Scatter → Trap is the hunter's entire opening game plan and neither button has any place in
a raid row, which is why they were not there before and why the row is byte-for-byte
unchanged in PvE.

### What this layer is **not**

- **It is not diminishing-returns tracking.** TBC DR (Freezing Trap shares the Incapacitate
  category with Polymorph, Sap, Gouge, Wyvern Sting and Repentance) cannot be expressed in
  WeakAuras without a custom trigger maintaining its own category table — there is no DR
  concept anywhere in the addon. Nothing here approximates it: `Trap Armed` is the trap's
  own lifetime and `Viper Sting Out` is a debuff timer. Neither says anything about whether
  your next trap will land at full duration. An incomplete DR tracker is worse than none,
  because it gets trusted.
- **It does not read enemy cooldowns.** No API on 2.5.x can. `Enemy Trinket` is an
  *inference* started by seeing the cast: if an opponent trinkets out of your view, nothing
  starts, and the 120s assumes the level-70 medallion (the old level-60 insignias are 5
  minutes).
- **It cannot see a trap being sprung.** `Trap Armed` runs the trap's maximum lifetime; if
  the trap is broken by your pet or a stray tick, the icon keeps counting.
- **It cannot tell which opponent is the healer,** and no element pretends to. Enemy *class*
  is readable on TBC, enemy *spec* is not. (v5's `Enemy Mana` narrows the field to the
  opponents who *run on* mana, which is a strong hint and still not an answer — a shadow
  priest and a holy priest look identical to it.)
- **It cannot filter casts by interruptibility.** WeakAuras disables that argument entirely
  on TBC clients, so `SILENCE NOW` fires on any cast your target starts. Fake-casting stays
  a player skill, not a HUD feature.
- **`CC ON ME` depends on the client's loss-of-control API.** WeakAuras registers the
  trigger for TBC and calls `C_LossOfControl`; that the 2.5.x client populates it is the one
  thing here that source cannot prove. Get sapped and kicked in a duel once and confirm the
  icon appears. Everything else in the layer is built on primitives this repo already ships.

## v3 — spec-selective loading

v3 is a **gating-only** in-place Update of v2: no new elements, nothing removed, every UID
unchanged (`stable=32 changed=0`). The audit question was not "can this spec cast it" but
"does this spec *press* it as part of playing well", asked element by element for Beast
Mastery (41/20/0) and Survival (0/20/41, or the 0/21/40 variant that skips Readiness — the
Readiness icon gates on its own spell id, so the row is right either way).

The answer for this pack is mostly *yes, both*. BM and SV run the same shots in TBC — the
Auto Shot ↔ Steady Shot weave, Multi-Shot on cooldown, Kill Command off the GCD after a crit,
Serpent Sting / Arcane Shot as the instants you press while moving, one pet, Aspect of the
Viper for mana, Misdirection then Feign Death for threat. Both raid guides describe the same
loop, so the shared core is legitimately large and it stays shared. Cutting it per spec would
have been noise, not clarity.

Exactly one element failed the test:

| Element | No longer loads for | Why |
|---|---|---|
| **Expose Weakness** timer | Beast Mastery | The 7s debuff is a **Survival talent proc** and the trigger is `ownOnly`, so a BM hunter could never fill this timer — it was an SV raid mandate sitting in the "loads for everyone" set. Now `use_not_spellknown = 19574` (Bestial Wrath): anyone 31 points deep in Beast Mastery is not the hunter this element speaks to. |

That also upgrades the shared `x=44` buff slot from a talent-arithmetic argument to a load
rule: BM sees **The Beast Within** there and nothing else; every other build sees
**Expose Weakness** there and nothing else. The two can no longer overlap by construction.

**Requires WeakAuras 5.4.0+** for the inverse gate (`not_spellknown`). Older clients ignore
the field, which means Expose Weakness simply loads for everyone — exactly v2's behaviour, so
nothing breaks.

Kept deliberately, and worth naming because they look like cut candidates:

- **Mongoose Bite** stays for both specs. Both raid guides discourage melee weaving, so the
  cut would have to hit *both* specs, not one — and its trigger already gates it perfectly:
  it only appears when something was dodged **by you**, i.e. when you are standing in melee.
  It is silent for a ranged hunter of either spec, and it is the right button for the
  levelling/solo case both specs share.
- **Kill Command, Mend Pet, Revive Pet** stay for both. Survival runs a pet too and uses Kill
  Command on cooldown; a dead pet costs an SV hunter the same button it costs a BM hunter.
- **Serpent Sting and Arcane Shot** stay for both — both specs press them on the move.
- **Intimidation** (BM) and **Wyvern Sting** (SV) are already single-spec via their own spell
  ids and were left exactly as they were.

## v2 — rotation fixes

v2 is an in-place **Update** of v1 (same UIDs — WeakAuras offers *Update*, not a duplicate
group). Five new elements, seven corrections; nothing was removed.

| Fix | Why |
|---|---|
| **Arcane Shot** joins the cooldown row (3044) | The guides' weave slot is "Multi-Shot **or** Arcane Shot", and Arcane Shot is the instant you press while moving. v1 shipped one half of an either/or and called the other half situational. |
| **Back to Hawk** prompt (new alert) | v1 only taught the *entry* to Viper. Viper is a flat damage loss (Hawk r8 = +155 ranged AP), and `ASPECT MISSING` structurally cannot catch it — Viper counts as an aspect, so that alert stays silent forever. The new prompt fires in combat when you are in Viper **and** back above 80% mana. |
| **Misdirection prompt** (new alert) at 70% threat | The threat bar's danger state was paired with the wrong ability. Feign Death is a full threat wipe that costs shots; Misdirection is the actual 70%-band answer and every TBC hunter presses it on cooldown. It now has a prompt instead of only a flat icon in the outer row. |
| **Feign Death prompt** moved 70% → 90%, and gated `combat` + party/raid | Solo you *are* the entire threat list, so `threatpct` reads 100 and v1's prompt glowed permanently while questing. 90% is also the honest threshold now that Misdirection owns 70%. |
| **Mend Pet** and **Revive Pet** prompts (new alerts) | The pet is ~35-40% of Beast Mastery damage and the prerequisite for Kill Command — and with a dead pet, spell 34026 is still *known*, so v1's best element glowed for a button that does nothing. `unit = "pet"` is a first-class WeakAuras unit, so v1's "no reliable pet-state trigger" was simply wrong. |
| **Rapid Fire** and **Bestial Wrath** icons now show their **active window** | v1 showed only the cooldown, so the icon went flat for exactly the 15s / 18s in which the burst decision is live. Trigger 1 is now the buff (Rapid Fire 3045 on you, Bestial Wrath 19574 on the pet — that one is a *pet* aura in TBC), trigger 2 the cooldown; while the window runs the icon stays full colour and glows. |
| **Threat bar**: third colour tier at 90%, party/raid gate | One tier per paired ability — orange at 70 (Misdirection), red at 90 (Feign Death), deep red on aggro. Solo the bar sat pegged at 100% red in the closest slot to the crosshair. |
| **Viper threshold 15% → 20%** (bar and prompt together) | Viper's regen scales off *missing* mana, so 15% is late. The bar's colour flip and the prompt still share one number. |
| **Kill Command** also opens on a **melee** crit | TBC Kill Command is enabled by any critical strike of yours. v1 watched `RANGE_DAMAGE` and `SPELL_DAMAGE` only, so in the one scenario where a hunter melees (pet tanking a dungeon, which is why `Mongoose Bite` ships) the window went unnoticed. |
| **Kill Command anchored** at the bottom of the alert flow | It is the pack's one reflex prompt, so it gets a fixed home instead of being pushed up whenever another alert appears. |

Still **not** in the pack, and deliberately so — see *Deliberately not included* at the
bottom for the reasoning: the Auto Shot ↔ Steady Shot weave (a swing-timer question, and a
design decision you should make before it is built) and the AoE breakpoint suite.

## Groups

**Resources** `(0, +180)` — **The Sill**, one draggable sub-group holding one 164 × 36
instrument strip directly under your character at an absolute `(0, -110)` (172 × 44 while the
80% threat rim is lit, which is the footprint the build's clearance scan uses). Since v13 there is no
second cluster: the target side is gone (see *v13* above). The geometry is the repo-wide sill
canon — a 160px rail, a 164px plate, lane offsets `+17 / +7 / -7` and the strip anchored at
`(0, -110)` — and those numbers are identical in every class pack here; only the plate's height
differs, because a hunter has no discrete class resource and therefore no fourth lane (a rogue's
combo pips and a mage's arcane pips make their plates 45 tall). It is drawn with two textures
WeakAuras already ships (`Square_White`, `Square_White_Border`), so nothing needs a media addon.
Every region inside the strip sits at its own **lane offset** in the group's frame and the
*group* carries the position, which is what makes the rails share one centreline by construction
instead of by six hand-typed absolute offsets that drift apart a version later.

*Player Sill* `(0, -150)` relative to Resources, from the back of the stack to the front:

- **The alarm rim — 172 × 44**, drawn **first**, at the very bottom. It is 4px larger than the
  plate on every side, so once the plate is drawn on top of it the only part left visible is the
  protruding band. Lit only at ≥ 80% threat, in `ADD` red `(1, 0.10, 0.10, 0.85)`, pulsing. It is
  first *because* `Square_White_Border.tga` is filled art rather than an outline (98.44% of its
  pixels are fully opaque) — see *The 80% alarm is a rim* above.
- **The plate — 164 × 36**, a bordered near-black texture at 45% alpha, drawn **second** so
  everything stands on it and so it buries the rim's filled interior. This is the aura that used
  to be your live 3D portrait; its surface is the entire reason a 13px bar and a 12pt number
  survive a bright zone.
- **Threat — 160 × 5**, the top lane: your threat on your current target, green → orange at 70%
  (press *Misdirection*) → red at 90% (press *Feign Death*) → deep red the moment you are
  pulling aggro, with a permanent white **notch at 70** (`x = +32`). It loads only in a party or
  raid, never in an arena (v5 — there is no threat table there; the party/raid half of that gate
  was in the wrong multiselect mode and loaded *nowhere at all* until v15 fixed it), and it hides
  itself at zero threat, so solo the top lane is simply empty. Its `%threatpct%%` readout still
  exists at `sub.1` but ships with `text_visible = false`, at 9pt.
- **Health — 160 × 13**, the middle lane: green, bright red below 30%, with the exact `%` at
  12pt printed **inside** the rail's right end (`x = +51`) and a red 30% waterline at `x = -32`.
- **Power — 160 × 13**, the bottom lane: blue, red below 20% — the same threshold that fires the
  Go-Viper prompt, so the rail and the alert agree — `%` at 12pt at `x = +51`. It carries the two
  aspect-swap breakpoints as full-height waterlines at `x = -48` (20%, red) and `x = +48` (80%,
  green), so the swap band is visible before either alert fires.
- **The 30% mark** is the last child, because it has to draw over the health rail it annotates.
  Nothing is drawn above it — the top of this stack is always a readout, never the plate or the
  alarm.
- Both tall rails carry a **ruler**: 2px hairlines at 25 / 50 / 75 at 18% alpha.

Every rail's unfilled part is its own `backgroundColor` — a rail needs no separate track region
behind it, which is what freed the old mana track's UID for the 30% waterline. Out of combat the
**plate, both tall rails and the 30% waterline** fade to 50% alpha, exactly as the cluster did;
the threat rail and the alarm carry no fade of their own, because neither is lit out of combat.

**Buffs** `(0, 80)` — a static row of four 40x40 icon timers with the remaining duration
under each icon. Serpent Sting (your own DoT only, all ten ranks) sits left and glows in its
last 3 seconds so you refresh instead of clipping; Hunter's Mark (any hunter's, all four
ranks) sits centre. The right slot is spec-shared: Beast Mastery sees **The Beast Within**
(the 18s self-buff from the 41-point talent, spell 34471 — not the passive talent), Survival
sees **Expose Weakness** (your own 7s debuff on the target, spell 34501). Keeping that debuff
as close to 100% uptime as possible *is* the Survival raid job, so it gets the prime slot and
doubles as the alignment cue for Rapid Fire and Readiness. Since v3 the two are exact load
complements on Bestial Wrath, so a Beast Mastery hunter never loads the Survival timer at all.

**Alerts** `(-150, 96)` — a dynamic stack of glowing 40x40 prompts growing upward beside your
character; each one slides in from below and flies up while fading out when it stops applying,
so the appearance itself is the signal. Nine prompts in PvE (four more in arena/battleground,
see *v4 — PvP layer*), with *Kill Command* anchored at the bottom of the flow so the one
reflex prompt never moves:

- *Kill Command* — you landed a ranged, spell **or** melee crit **and** Kill Command is off
  cooldown, i.e. the exact 5-second window in which the button works.
- *no aspect at all* — neither any rank of Hawk nor Viper, in combat only.
- *Mongoose Bite* — something was just dodged by you **and** the bite is ready.
- *Feign Death* — threat at 90%+ **and** FD ready, in combat, party/raid only.
- *Go Viper* — mana under 20% **and** you are not already in Viper, in combat.
- *Back to Hawk* — mana back over 80% **and** you are still in Viper, in combat.
- *Misdirection* — threat at 70%+ **and** MD ready, in combat, party/raid only.
- *Mend Pet* — the pet is alive and under 40% health.
- *Revive Pet* — the pet is dead (this is also why Kill Command stopped working).

**Cooldowns** `(0, -66)` — a horizontal, self-collapsing row of 32x32 icons with WA cooldown
text and tooltips on hover. Since v6 the row shows what you **cannot** press (full reasoning
under *v6* above):

- **Always there:** *Multi-Shot* and *Arcane Shot*, the two shots you press the moment they
  are up — dim while recharging, full colour with a gold glow when ready, both at half alpha
  with the glow off out of combat.
- **There only while on cooldown:** *Intimidation*, *Readiness*, *Wyvern Sting*,
  *Misdirection*, *Feign Death*, and in an arena or battleground *Freezing Trap* and
  *Scatter Shot* (v4). Each carries its own countdown and disappears when it is back, so a
  gap in the row means the button is available.
- **Both, plus a live-window state:** *Rapid Fire* and *Bestial Wrath* show their *active*
  window first (15s of +40% ranged haste; 18s of +50% pet damage) — full colour plus a glow
  while it runs, a dim cooldown swipe afterwards, and absent once it is ready again.

Talent and late-trained abilities load-gate on their own spell, so the row shows exactly the
buttons your current build owns and the gaps close by themselves. Kill Command deliberately
has no icon here — a 5-second cooldown says nothing useful; its reactive alert owns it.

**PvP** `(180, 96)` — a downward dynamic stack of state readouts that exists only in an arena
or a battleground: trinket down, Will of the Forsaken down (Undead), enemy trinket countdowns,
trap armed, Viper Sting out, and (v5, arena only) one **Enemy Mana** bar per opponent who runs
on mana. Empty in PvE, and empty in PvP whenever nothing needs saying. Full description in
*v4 — PvP layer* and *v5* above. It moved 30px right in v18: the 120px-wide *Enemy Mana* bar
makes this column `anchor ± 60` at every depth, which at `150` came within 4px of the new alarm
rim and reached across the cooldown row's outermost icon (see *v18*).

**Procs** `(250, 24)` — a cloned 32x32 icon right of the bars for **Quick Shots**, the 12s
+15% ranged-haste proc from Improved Aspect of the Hawk. It pops in with a scale-and-pulse
and flies right on expiry. It is the smaller of the two haste windows the pack sees; the
bigger one (Rapid Fire) lives on its own icon in the cooldown row. It sat at `110` from v1 to
v17, which put it **inside** the PvP column's enemy-mana bar; v18's all-pairs scan found that and
moved it clear.

## Spec gating

The pack auto-adapts on respec with zero user action — every spec-specific element gates on
`spellknown` of a spell that is only in your book when the talent (or the training level) is
actually there:

| Element | Gate | Shows for |
|---|---|---|
| The Beast Within timer | `spellknown 19574` (Bestial Wrath) | Beast Mastery |
| Expose Weakness timer | `not_spellknown 19574` (v3) — inverse gate | everyone except Beast Mastery |
| Bestial Wrath / Intimidation CD | `spellknown 19574` / `19577` | Beast Mastery |
| Readiness CD | `spellknown 23989` | Survival (41-pointer) |
| Wyvern Sting CD | `spellknown 19386` | only if you took it (raid SV skips it) |
| Kill Command alert | `spellknown 34026` | level 66+ |
| Misdirection CD / prompt | `spellknown 34477` (+ combat, party/raid on the prompt — mode fixed in v15) | level 70 |
| Go Viper prompt | `spellknown 34074` + in combat | level 64+ |
| Back to Hawk prompt | `spellknown 13165` + in combat | any hunter with Hawk |
| Aspect-missing alert | `spellknown 13165` + in combat | any hunter with Hawk |
| Mongoose Bite alert | `spellknown 1495` | any hunter |
| Feign Death prompt / CD | `spellknown 5384` + combat + party/raid (mode fixed in v15) / none | level 30+ |
| Mend Pet prompt | `spellknown 136` | any hunter with a pet |
| Revive Pet prompt | `spellknown 982` | any hunter with a pet |
| Threat rail / alarm rim | party/raid **and** not in an arena (v5, mode fixed in v15) | grouped PvE, and battlegrounds |
| CC ON ME / Trinket DOWN / TARGET IMMUNE | arena + battleground | everyone, PvP only |
| DEADZONE prompt | arena + battleground + in combat | everyone, PvP only |
| SILENCE NOW prompt | `spellknown 34490` + arena/BG | Marksmanship (Silencing Shot) |
| Will of the Forsaken DOWN | `spellknown 7744` + arena/BG | Undead |
| Trap Armed / Freezing Trap CD | `spellknown 1499` + arena/BG | level 20+, PvP only |
| Scatter Shot CD | `spellknown 19503` + arena/BG | Survival 20-pointer, PvP only |
| Enemy Trinket | **arena only** (reads `arena1..arena5`) | arena |
| Viper Sting Out | `spellknown 3034` + **arena only** | level 36+, arena |
| Enemy Mana (v5) | `spellknown 3034` + **arena only** (reads `arena1..arena5`) | level 36+, arena |

Beast Mastery and Survival never both light up at `x=44`. Since v3 that is enforced by the
load rules themselves and not by talent arithmetic: The Beast Within needs `spellknown 19574`,
Expose Weakness needs `not_spellknown 19574`, so the two are exact complements — whatever your
build, exactly one of them is eligible for that slot. (Belt and braces: the tracked auras
already made a double-show implausible, since 34471 only exists for the 41-point talent The
Beast Within.) On a pre-5.4.0 WeakAuras the inverse gate is ignored and the aura falls back to
the v2 situation, where the tracked debuff itself is what a BM hunter can never produce.

## Deliberately not included

- **Auto Shot ↔ Steady Shot weave timing.** This is the spec's central skill, and it is *not*
  unbuildable: WeakAuras in this client does ship a Swing Timer trigger with a `ranged` hand
  (v1's README claimed no sanctioned trigger provides it, which was wrong). It is left out
  because it is a design decision, not an oversight — the trigger's own tooltip warns that
  non-retail swing results are inaccurate in edge cases, and a weave bar that lies costs more
  than no weave bar. Bloodlust/Heroism and the "tighten the weave under haste" reading of
  Quick Shots are parked with it, since they only become actionable next to a swing bar.
- **The AoE breakpoint suite** (Explosive Trap at 7+ targets, Volley at 10+, situational
  Survival traps). A plain on-cooldown trap icon would prompt a ranged hunter to walk into
  melee, so these need a target-count scenario gate and a group of their own.
- **A pet health bar, a pet unit frame, or (since v8) a third pet orb.** The pet is
  ~35-40% of Beast Mastery damage, so this was reconsidered when the orbs went in, and the
  answer is still no. There are exactly two pet decisions in the rotation and both are
  *threshold* decisions, not readings: heal it below 40%, resurrect it at 0. Each already
  has a prompt in *Alerts* that interrupts you at the moment it applies. A permanent third
  orb would show a number you act on twice, and would spend the screen space the v8 layout
  just freed to say something the pack already says louder.
- Master Tactician (a passive crit proc you cannot react to).
- **Deterrence**, deliberately, even in the PvP layer: on 2.4.3 it is +25% parry and dodge,
  not an immunity, so it is not a hard stop on the target-immunity alert and it is not a
  button whose readiness changes your next press the way the trinket's does.
- **A per-opponent range column, enemy health frames, or an enemy-cooldown wall.** The first
  is impossible (WeakAuras' range check has no arena unit and every extra unit costs its own
  frame-update trigger); the other two are Gladius' job and fail the "changes my next press"
  bar. *Enemy mana* used to sit in this list on the grounds that arena-unit power was not a
  verified primitive — it now is (WeakAuras only removes arena units on Classic Era, not on
  TBC), so v5 ships it as a real element.

## Importing

Copy the whole string from the fenced block at the bottom (GitHub's copy button on that block
grabs it exactly) or from `all-specs.txt`, then in game: `/wa` → **Import** → paste.

Four things to expect, all normal:

- The thirteen **PvP auras show as greyed-out / not loaded** in the `/wa` list whenever you
  are not in an arena or a battleground. That is the load gate working, not a fault — step
  into a BG and they light up. Three of them (`Enemy Trinket`, `Viper Sting Out`, `Enemy Mana`)
  stay greyed out in a battleground too: they read `arena1..arena5`, which only an arena has.
- The import dialog shows a **code-review panel**. This pack contains exactly two lines of
  custom code — one on the Kill Command alert and one on Mongoose Bite, both the same
  sanctioned "either of these events fired, and the ability is ready" one-liner.
- The `/wa` **editor preview lies**: selecting a group force-shows every aura with fake data,
  so you will see both spec slots at `x=44` at once, identical fake durations like "55.1", and
  an empty threat "%", and every rail pegged at some arbitrary fake fill. Judge the
  layout there, judge behaviour in combat.
- On a future re-import the Update dialog's **Arrangement** checkbox (checked by default)
  resets any positions you dragged in game back to the string's defaults. Uncheck it to keep
  your own placement, or tell me your coordinates and they get baked into the script.
  **Coming from any earlier version, leave it checked** — it is the category that
  carries width, height, region type and offsets for child auras, i.e. the thing that turned the
  old 172x14 bars into rings (v8), resized those rings to the shared orb geometry (v9), replaced
  them with the globes (v10), moved those globes up beside your character (v11), turned them
  back into arcs around a live portrait (v12), grew the threat ring to 100px around your own
  face (v13), moved the health `%` into the middle of the cluster (v14), flattened the whole
  cluster into a strip under your feet (v15) and re-cut that strip to 164x36 with 160px rails
  (v18, see above). Coming from v14 it also
  carries the strip's **child order** and its move from `(-270, +40)` to `(0, -110)` — uncheck it
  and you get rings-worth of geometry stacked in the old place, which is not a HUD.
- **Coming from v12 only:** one group is left behind and you have to delete it yourself.
  WeakAuras never deletes an aura an import does not mention, and v13 genuinely removes the
  target cluster instead of recycling its UIDs into filler regions. In `/wa`, delete the group
  named exactly **`Hunter - Target Cluster`** — deleting it offers to take its four children
  (`Hunter - Target Health`, `Hunter - Target Ring Track`, `Hunter - Target Health Track`,
  `Hunter - Target Portrait`) with it. Nothing else is orphaned.

## Regenerating

```bash
lua5.1 tbc/hunter/generate.lua
```

Run it from anywhere — the script resolves the toolkit and its own output directory from its
own path. It rebuilds `tbc/hunter/all-specs.txt`, round-trip verifies the string (decode +
deep-compare + structural wiring check) and prints the aura count, string length and the UID
continuity report against the previous version of the file. The build is fully deterministic:
the same source produces a byte-identical string every run.

`math.randomseed(20260814)` at the top of the script is this pack's **fixed seed** and must
never change: it is what makes the UIDs stable, which is what makes WeakAuras offer *Update*
instead of creating a duplicate group. When adding auras in a future version, append new
elements at the end of the build order — never reorder or delete existing ones, and when a
region is genuinely removed (v13), **burn its `W.uid()` draw in place** rather than deleting the
call: a UID is a *position* in a seeded stream, so a deleted draw hands the next surviving aura
someone else's identity. v2's five new
auras are built at the bottom of the script and re-parented into their groups afterwards,
which is why every v1 aura kept its UID (`stable=27 changed=0`). v3 adds no constructors at
all — it only sets two load fields — so it reports `stable=32 changed=0` against v2. v4's
twelve PvP auras follow the same rule — constructed in a block at the very bottom, then
re-parented into `Alerts`, the cooldown row and the new `Hunter - PvP` group — so it reports
`stable=32 changed=0` against v3, with every pre-existing aura's load table, triggers and
parent unchanged as well. v5 adds exactly one constructor (`Enemy Mana`), again at the very
end of the file, and changes three existing auras in place without touching a single `uid()`
call: `stable=44 changed=0` against v4. v6 adds **no** constructors — it rewrites the
cooldown row's display in place (one trigger field per icon, the conditions that go with it,
and a glow subregion *replaced* at index 1 on the two rotational shots, never inserted, so no
`sub.N` condition anywhere in the pack is silently retargeted): `stable=45 changed=0`
against v5, with every load gate, position and parent untouched. v7 changes one item id and
adds no constructors: `stable=45 changed=0` against v6.

v8 is the largest in-place rewrite so far and still obeys the rule exactly. The four
Resources auras keep their original build positions in the script — `Hunter - Health`,
`Hunter - Mana` and `Hunter - Threat` swap `F.aurabar` for a hand-written `progresstexture`
table at the *same* point in the file, so each consumes the same `W.uid()` call it always
did — and the six genuinely new auras (two cluster groups, two portraits, the target's two
rings) are constructed in a block at the very bottom, then everything is re-parented.

v9 adds no constructors at all and changes no trigger, condition or load table: it only
rewrites width, height, offsets and the ring texture, so it reports `stable=51 changed=0`
against v8. The canonical sizes live in one block of named constants at the top of the build
script (`RING_TEX`, `ORB_OUTER`, `ORB_MID`, `ORB_INNER`, `PORTRAIT`, `CLUSTER_X`,
`CLUSTER_Y`); every ring, portrait and cluster reads from them, and the mana ring's two
breakpoint ticks are computed from `G.mpRing` so they can never be left behind when a ring
is resized.

v10 turns the rings into globes and deletes the portraits **as regions, not as auras**. Every
`W.uid()` call keeps its position and its order: the four Resources auras are rebuilt at the
same point in the script (`Hunter - Health` and `Hunter - Mana` become vessels, `Hunter -
Threat` becomes the target's rim, and the flash keeps its shape), and the six v8 cluster
constructors keep their slots while what they build changes — the two portraits are recycled
into the life rim and the target rim. Only the two rims that never had an ancestor (the
power globe's and the target power globe's) are new `uid()` calls, appended after every
existing one. Result: `stable=47 changed=0 missing=0` against v9 — the four auras missing
from `stable` are the ones that changed *name*, and each kept its uid, so **nothing is
orphaned**. The canon again lives in one block of named constants at the top of the script
(`FILL_TEX`, `RIM_TEX`, `GLOBE_MAIN`, `GLOBE_TGT`, `RIM_PAD`, `GLOBE_X`, `GLOBE_Y`,
`PCT_MAIN`, `PCT_TGT`, `PCT_THREAT`), the two breakpoint waterlines are derived from the
globe diameter by one formula, and the build **refuses to write the string** unless every
globe's parent chain sums to its canonical absolute screen position.

v11 adds no constructors either, and changes no trigger, condition, colour or load table: it
edits three constants in that canon block (`GLOBE_X`, `GLOBE_Y` and the new `GLOBE_TGT_Y`)
and appends one sub-region to each of the four vessels, so it reports
`stable=53 changed=0 missing=0` against v10 with the child order and the whole `uid()`
sequence identical. Eight of the 53 auras differ from v10 at all, and every one of them is a
globe: three offsets (the *Resources* group, the *Target Globe* cluster, and the `x` on the
four player-side regions) and four appended highlights. The position proof grew a third
coordinate, and a second guard joined it — the build walks every vessel and asserts that the
pre-v11 sub-region prefix is unchanged and that the highlight is **last**, because
conditions address sub-regions positionally and an insert would retarget one in silence.
Re-parenting, renaming and reordering `controlledChildren` all cost nothing; only the `uid()`
call order matters. Result: `stable=45 changed=0 missing=0` against v7, so **no v7 aura is
left orphaned** and nothing has to be deleted by hand after the update.

v12 turns the globes back into rings and adds no constructors at all: every `W.uid()` call keeps
its position and its order, and the twelve cluster auras are rebuilt at the same points in the
script. Seven of them change *name* rather than identity — `Hunter - Player Globes` becomes
`Hunter - Player Cluster`, the two rims that were the portraits in v8/v9 become portraits
again, and the target's power globe plus the two remaining rims become the three track rings —
so the result is `stable=46 changed=0 missing=0` against v11, with 53 children before and 53
after: **nothing is orphaned**. The canon lives in one block of named constants at the top of
the script (`RING_TEX`, `OUTER`, `INNER`, `PORTRAIT`, `CLUSTER_X`, `CLUSTER_Y`, `TARGET_Y`,
`PCT_HP`, `PCT_POWER`, `PCT_THREAT`), the two breakpoint marks are derived from the ring
diameter by one formula, and the build refuses to write the string unless every cluster
region's parent chain sums to its canonical absolute screen position, every arc is a
full-circle `CLOCKWISE` progresstexture at a canon diameter with the identity crop, every
portrait carries its unit in **both** model fields, and each breakpoint mark re-derives to the
angle its own threshold implies.

v13 is the **first version of this pack that is allowed to lose UIDs**, and the licence is
exactly as wide as the list it declares. Five regions are removed for real — the target cluster
group, the target health arc, both target track rings and the target portrait — each named in
`generate.lua` on a `-- WA-REMOVED (v13): <id>` line, which is what the repo-wide verifier reads
before it will accept a missing UID. Everything else is unchanged: `stable=48 changed=0
missing=5`, the top-level UID matches, no aura was added, and the five missing IDs are exactly
the five declared. The four removed constructors that sat *before* a surviving one
(`Hunter - Power Ring Track` is built after them) **burn their `W.uid()` draw in place** —
`retire()` calls one draw and emits nothing — because deleting the call would shift the seeded
stream and silently hand the mana track the target cluster group's identity. Threat moves to the
player cluster and grows to 100px; the halo follows it at the same diameter. The build gained
three proofs to go with the move: every cluster region must be anchored `CENTER`-to-`CENTER` at
`(0, 0)` inside the cluster and land on one shared absolute centre (that *is* concentricity),
the diameters must strictly nest `100 > 84 > 62 > 44`, and the *Alerts* column is projected six
icons deep with every icon box tested against the cluster box.

v14 adds no constructors and moves two text offsets and the cluster's child order:
`stable=48 changed=0 missing=0`.

v15 adds no constructors **and draws no new UID at all**, which is the constraint the whole
version was built inside: the strip needs six regions and one group, the cluster had six regions
and one group, so every slot in the v8 build order is respent rather than extended. The `ring()`
builder becomes `rail()`, `portrait()` and `trackRing()` become plain `F.texture` calls at the
*same* points in the file, and three auras change **name** (`Hunter - Player Cluster` →
`Hunter - Player Sill`, `Hunter - Player Portrait` → `Hunter - Sill Plate`,
`Hunter - Power Ring Track` → `Hunter - Health 30% Mark`) while keeping their UID byte-for-byte:
`stable=45 changed=0 missing=0 parentSame=true`, and `assertUidContinuity` runs on its **strict
default with no allowance list**. The five `retire()` draws from v13 stay exactly where they are;
removing one would shift every later UID in the stream.

The ring canon block at the top of the script is *rewritten*, not deleted, into the sill canon
(`RAIL_TEX`, `PLATE_TEX`, `RAIL_LEN`, `PLATE_W`, `PLATE_H`, `SILL_X`, `SILL_Y`, `LANE`), and so
are the post-build proofs, which is why a geometry change in this repo has never silently shipped
wrong. They now assert: the sill group's parent chain sums to exactly `(0, -110)`; every rail is
a `progresstexture` at `orientation = "HORIZONTAL"` with the canon art, the canon crop
and an exact subregion type list; the three lanes are all `RAIL_LEN` long, share one centreline,
do not overlap and sit inside the plate with a margin; every breakpoint re-derives from
`x = (v/max − 0.5) × RAIL_LEN` (so a mark can never be left behind by a resize); the plate, the alarm
frame and the waterline carry an explicit four-component colour and no leftover `model` fields;
`controlledChildren` is plate-first / alarm-frame-last with the waterline after the rail it
annotates; and a **rectangle scan** projects every dynamic group six deep and tests all 355
resulting boxes against the strip.

v18 adds no constructors and draws no UID either: `stable=48 changed=0 missing=0
parentSame=true` against the v17 string, on the strict default with **no allowance list**. It
rewrites the canon a second time — `RAIL_LEN 160`, `THREAT_H 5`, `BAR_H 13`, `PLATE_W 164`,
`PLATE_H 36`, `RIM 4`, `NUM_PT 12`, `NUM_X 51` — and adds four proofs, three of which run on the
**decoded string** rather than on the Lua tables the script just built:

- **the lane stack is re-derived** from `PLATE_H`, the two lane heights and the 1px gaps, with
  both plate margins checked separately (1.5 and 1.5), so the three offsets cannot be typed;
- **every mark is asserted onto a whole pixel** — `x == floor(x)` for all ten marks plus the
  standalone 30% waterline;
- **the rim envelope** (172 × 44, not the plate) is scanned against every region outside the
  sill, dynamic groups six deep, with the tightest clearance named;
- **an all-pairs column scan**, which the pack never had: all six pairs of *Alerts / Procs / PvP /
  Cooldowns*, each boxed as its widest child by its deepest projected stack. It found two real
  overlaps on the v17 layout (see *v18* above) and both are fixed.

`railX()` also rounds to 3dp now, because `(0.2 − 0.5) × 160` is a 17-digit float in IEEE754 and
a coordinate that *is* a whole pixel should be written as one.

## Verified spell IDs

All checked on wowhead.com/tbc. Aura triggers carry every rank; cooldown triggers and
`spellknown` gates carry the rank-1 ID.

| Spell | Use | IDs |
|---|---|---|
| Serpent Sting | own DoT timer (r1-r10) | 1978, 13549, 13550, 13551, 13552, 13553, 13554, 13555, 25295, 27016 |
| Hunter's Mark | debuff timer (r1-r4) | 1130, 14323, 14324, 14325 |
| Aspect of the Hawk | missing-check + gate (r1-r8) | 13165, 14318, 14319, 14320, 14321, 14322, 25296, 27044 |
| Aspect of the Viper | missing-check, Back-to-Hawk check + gate | 34074 |
| The Beast Within | BM burst-window buff (18s, 41-pt talent) | 34471 |
| Expose Weakness | SV target debuff (7s) | 34501 |
| Quick Shots | haste proc (12s) | 6150 |
| Kill Command | reactive alert + gate | 34026 |
| Mongoose Bite | reactive alert + gate | 1495 |
| Feign Death | prompt + CD icon | 5384 |
| Bestial Wrath | CD icon + 18s **pet** buff window + BM gate | 19574 |
| Intimidation | CD icon (BM) | 19577 |
| Readiness | CD icon (SV 41-pointer) | 23989 |
| Wyvern Sting | CD icon (SV 31-pointer) | 19386 |
| Rapid Fire | CD icon + 15s +40% haste window | 3045 |
| Multi-Shot | CD icon | 2643 |
| Arcane Shot | CD icon (r1) | 3044 |
| Misdirection | CD icon + threat prompt + gate | 34477 |
| Mend Pet | pet prompt + gate (r1) | 136 |
| Revive Pet | dead-pet prompt + gate (r1) | 982 |
| Silencing Shot | v4 interrupt prompt + gate (MM) | 34490 |
| Scatter Shot | v4 CD icon + gate | 19503 |
| Freezing Trap | v4 CD icon, trap-armed inference + gate (r1-r3) | 1499, 14310, 14311 |
| Viper Sting | v4 arena clone row (r1-r4), v5 `Enemy Mana` gate (r1) | 3034, 14279, 14280, 27018 |
| Will of the Forsaken | v4 second-break readout + gate | 7744 |
| PvP Trinket | v4 enemy-trinket inference (the spell every medallion casts) | 42292 |
| Divine Shield | v4 target-immunity alert (r1-r2) | 642, 1020 |
| Blessing of Protection | v4 target-immunity alert (r1-r3) | 1022, 5599, 10278 |
| Ice Block / Cloak of Shadows | v4 target-immunity alert | 45438, 31224 |
| The Beast Within | v4 target-immunity alert (their trap immunity) | 34471 |

PvP trinket **item** ids watched by *Trinket DOWN* (all four verified on wowhead.com/tbc;
only one can ever be equipped, so they are ORed into one element):

| Item | Id | Cooldown |
|---|---|---|
| Medallion of the Horde | 37865 | 2 min |
| Medallion of the Alliance | 37864 | 2 min |
| Insignia of the Horde (Hunter) | 18846 | 5 min |
| Insignia of the Alliance (Hunter) | 18856 | 5 min |

## Import string (v18)

```
!WA:2!T3xF4XXX59PbqKI8OKfjejffLS8zitwaAlY7oGdFWij77tGJe3HJ7D4dsrPB37Uf3Ue7T7YD3dahCIPfQSctAsFAGFQAI7hXbX2nnpojTOoPTQjQji(J8Hu6uKA3T5FClBBQAsRFK5F00pEstFNz27U9aoCaKeuIu2)XT3UZoZS7mV)E)yEN3zw0KDv4l676FK1Zluy2IgA6r0u0moxND2z6o9D6G6Dvqt1YqtrrSyejzLIgIQhx)WJwr1s0W7Z6nTIqv4KmYkk3iVMrrrJWo1J(bdRiV4Icgf9MvttXsw3yHXNzgtrluEDbOAS0pUt1KnCeOQcN07j9MPIXCYZjOKNvzsgvzLj6bwXqSKSMA2Q6ICLm0QOVcllzKxuCpRkRoJMrzblihEwLDdwdbHqDUUqfljnJX1j320tEOjnJCjpgcfOjmaNPLGHLN8ZiRkBk5jm8NLNLSmKlvs0Wm1jnCo91dBrE6cvmecSg5OPUOIICrZJ3LVWvGcLxN2DSen9efn9CdZk5fNdARzQmZmYlSAUiHYKnxMSH4Yw)wPneHBXLjDSXg7MvmfJTa8ELHvd8CQcLfn9SsrX8qnqA8gJgBS0XNySLH(o2RLNvlkBELkQqRzoXackk6hsGEEw29tQvu8R(aoDxXkwsu)qzUAfGe4nEfffVtjjBjUg7USo79VSGQmRZCa8JfFnrbtXmwajRKL0dHpwyvnvX1lcTFsoYr6tmmfHo1IMlrYk5TeFMWLfKvJJpnua8zW(W(XbG)p8gtzztrLzsRjRALpsSuzJX1TCr9UQJV4en1Qyuq08MYKuufuMeEyWJ9fxDgdORbETeSe68McQfakCCssKhF(mr4Ifl1kwAfMJL)9L(ibQixCvLfgCmURo5Lwi0SCMfeue7CfGqWrXwM1GojuHEHoxH0KKzyMWkAcf9Sk7XqFDXbV(hbJQZOG74k6hP(RDwjdrblVXvemL0FS6jtytiSmwI3CdzTX1JkkOyjTE9RtkOkOFSnCBV957eWDmMf)G49G3lc)q4bW7xc7rz)4dGFy8JSh8hYd(rPOF8b9GpKhCxaP0d(WEWhXd(OPoj(XFDGm8e4Jdyx8tIFk8h2d(PXFeSx8hf3np(z8G)y4tGpPh8FnCp4E)Qpa(u4po(tSF8ZsqeBKQ232tNX9JdcKwCN4bFr8qDIhgFw8pcquWp3QvkRF14Z1BMjlCf8l0j(t6b)P6ehYdoShCeOx2l0468MwIlyvXqCkdbDcEw)WrgluY0zhp8yHIC(qrJMiBIjJXAyFt45(KKgZ6a3uolA)REbl(vyNobHrfy4ljAbnZB0ipKBWVC9839q(Gof9UQNqonaOlyPz09l88Cuwx9d6qOZiBvHYnq7)2qp3hYdxbMqvcsXp7Wd670dfein5llByOzaKUhcFadNwjqVwoVIOArstna06iDhTUNFg8XYRBic4v61WTV0kck6scPROykUunU0U8tlYMil6hcKDuWq0smNHMfnROMGktPhkbb6nJqbXlhQyXXvnV8uIcZgIi(7YjflklC5SS3AZlZeRKJkrjxykR0PTkjWi0m6UdmikaA5OVNDcY2mfSiVNIsl14L45wvmyiU4d7FcRlonfUaGH8sIYLKSUyEA(eLWHFTLjeWcaJMj)QKtLvPAhKwICHjOCqci2qFP1r5kxbud5XWjhhflFs8dZh2qqgKZsRHtM3eUPIy(rNGikclFuSkFyqAEbiZEctQn4K54a9xwv5dOpNo)sGEhRQLfu5dyjQcyS5Hhv1zaPV85zNZJpdp38YfTK(6EyGz85XJHp6l7WdsHQ4m5zC2o8I03EIkfEkIQo7yZLr)WemR3isceDzIgYMwYfmRXoxDdL1fGepbr0abe2pbeINKH)WtrKumnx4XILcWCh)KCfKelmBC8JVNLMtWqwaaLljRgrRCEbloqnDfru3A6D)8pVrbjb1sIMh)K4RrLhUKUbHDXQko3TVmJxAdyr8l3cOumI8VCDI5LWceytP4ZU4fpFPZp0Stvd2GlKaxealtIf5XseAjw5K4YyvgfgRrtsNEC(OEU(zZdD)g5QIy)VacEeRku8kvmTelMuyHoACHSAhyppd5HOF4gazIrqeqMArPvnj6KyCi8UZtCnWIgwE4mveuTqlbC8Hi4Vx9Oqt8gqpyjGRYmdvd4PEQhOdstMcGaQeq1eOT7qN7K4FuGe1j(hdFb816EqFesYl884plHyWe6mavOtN4x5MZu)PsTpQ5IoCZfLGpgoi5yGG1Qa8pD9IWjucQj816KbbQviiJdtkJ)aSJnxOvzItPyh816I(aFoNYIGCMd)jp11pgi1f6XYzkjuuB(PDmBCzAAKdRDI6cLpXj0pOR82WOp9pr9SNJzBydvb5kkwamWrjhi5SGmX8a0nyvsnJrchAISJR)y0ebRh1iwdvykctC4qWL3KvTYliwKM4RSoZYGlYEvRSg9(eiI8mvXbxHjUIGccNA8uX0)OT5DJLq(uvkNx0aFmdW8esgD6sypNADjRqtJPDH0BpyWg0SbhQZLDEcenvXnKx07fQiuKyWK3SzBQ(Q9EVonT5bj3efTlnLZjRxVEOwGo(ezhlb0koORAWXMi9t0Mwgf2rTxKBgfnnJMOYoVcOgplIL9p26n3GzDSZb0mquK01p86oAmt6OffSFGildTcHsMtN9svZ4bUAkxUHtctYQhEh76Yvgu3YrluTua1zcbcn2y4JTIdDakM(HCojAdnx1QshoD9ZE7P1KQUC(9SMtT1yWym7f2BiCHdSMZ7MtRdKSTU7gOOeJWaxhUMne4pnuUBB5W5laYYZvLQUWVBjY6heKpgYruivYOK(HYxx2Ntle)BsLAVcDuwu5BiqVnru8ms4ssocKVIJ(y8S8BLW55WxLhBWJn5XGEXk845i6wBynltRyk84eDEP5j6aZGZ2ktYMuAJV6YQs4dCZAICD6)wsdg9amKotqPi(tthYxdmKzznnlP0oLGFfQm84YgMwsR6uUckY6suLqGgF9d2ONXbnFZgPuxWfPxoyWLkOvMywNPerfxC8p95AigEiYH(6KOcC(h0J(HAisVrh(ZTAVNpPELqPM48(sdw8qgfKO0Y03rcGiFIuzsen2QAgYGnk0w0kJooxIlnEQSHgJrWxWHG)H8yqlNyrPRFw8FDe(vj6dXFUoWVgO77rPky)XLWxNh)tiH)jr4)gu1x4FQTwJ1zRRoyDqCsb4nqIz8Z16UpIgHUEUDGYK9akT(mGsd3AFydfd0Iu)bSCzau6u5TuBZ5U(XW)Tq4Fg9dEIMExoXjWFE24N(BJFD8Fh8pl(N7vWFbe(Vl0G(7H)7dWTVi(xOeEfc3zN4Fr8xs33Me91uf2cLo4VmsV3TPuneAI)Q4Vc(Fi(xc)pc)ldVe)J5X)ki8V6tG)1k1cPUnxjSeX)8x)W4)jnesIxfQM)Pi8xJh)RJ)nW)ZW)ZHw1)c8BiH)xcqO53d(3QMOh)dH37pvh4cpj(nPcCW)RKW)24p9TA19oVfb4SBulxyt1cjHBBdn)D2SSn8As4Fxhrx4VoANz84gnQhVWwzm(gY3IBRr7qNZ3aerH)M4VfvAe(3dH)95X)bs4)W6IyWVfc)2VZQ4)iQuJrCKA4NAoWquoOadvtUb(FnvmH6aJioDQXsCf95X)BKWRJ)JX)BXFB83PoVp(FxR46)rFG7i2(1CGN6AZd24CTUd0mxpvzhHxoa9WTmt)satVtv3L)wWZFfhE(BEc3Vh7yoEMiAM9wo8(9SvmG0AUzM4VmIW76Ivw)J1(sxJ7Tb)(zAFb2SKMBjES9d8y)f49(WDENXQcvdvaE)DYoI3RWUcV)puq0ouq0VrdbmCPPSdGqMLPqecue1K8gQZYQFp(37etnkrmfLxN6oc2ay2GuQHk4FrJYx6Cf7DWTwk1w7BLDrXWeFN8oVznFM8O19zc0sdDQBfzu4)9T2GKDpNL8B2cNLKayR7WT3sgEElrv1kZMCYrB4TKNCN7TK9VbVGFo9J2WD3Ig6GmjVzSKvl5Y74StmPoWw)jC5jCrVHffmT8oLSLKSQlVEhdeNBk6LmekvWO4gE9EFuVE)lCVTtVVr92r4kGH)B2d4YkfMR3Kv7z0foxR8a(ZSICbnvMBGEQhG00aPtWnwVGMMcm0z1mZldSSRv7sYC8iT52(xH12)Ld7F4bhIZFFb7FyYXG(Oh9tpgGESp6X(PhdYfiyGHHJd6Z)agqTpUQcWD8KWOS2CVNXOH4sgFIXC3ho4lEZzff1drCJQfhzOgsuZdae4N8SFN1lPOnFCdXRwruTqv2GCctstAnqG0ikoU0rAzsAzytyd50XOZg1rwLCEnxhqZt9Hm3j9E1CCaZrkKuOpXSsYfOqPoxIEjiYB98vSS0uhNn0nADnMmKLdrFEmVzlD9JqnCO7tOVdSva5A0beT(1v5VwIuPIXLl84zZoEsQw9pm(xJyvWm4JTm8AYMfQ1z)LtZX1hoxwOUlUCMX1AUdH3z2RYjc0F8hV2veVwdAYVWoJH(aHjynGZ67H37B1bbBMQVeAjlvuxzi8e0Mt4f10kthd6s1qC8uKmraZFM(HRLiz0OrLnjonUiprMZ8xWgDeEcFjidNXtryuogBElC4P2qkhEtPq4BcD86YrVH4c6YSj5iRCzIpf7ZTqvE8Rq8CZP9FAcvKiGyOoV(ZGFx38r4Vpp(MsBPWIZf2V)(aMK(7lqF0J9tpgCl4bW))Ag9J)RCJ3TrpadKBJqs2OoGFD2Pn6bpInApiB0EP9W2OhcaS2O9zJ2pCHhB0bSrp8HSrpYUea0g9H2aSZg9O2OdcVbhIwR2OU4Trpg(JBJo8Ta4bOVmOdr1Yf6lCQmZoySblEbhKJn6XP4gB0XAGy(ZTrpXUn8WZTfH(4C91F)d6FhPz4dm015a6kDsqPbTWSQuUzgDwBtu7vAKP9n2CBIQFrGQ3ZIPh7IJlnRYvNUDu9)7V)t1)knO6b95h)xY)dwm0ecVExekVQM1MP(3O5ujK7DaFpbbu8IcPdwm4mcNBO2Ha(FCxeb4lCjWuLUNinUJ)exgEEEs8xerRCzb1I6pE9KdLjDSiz9MmrMmjsnIldytQPwsJy4zyzlr9NSE6XfLlP6nQOGLK30gAL1T0pu9BoIM3jbZXmC9CjthOxlnVJkm)S6pvJQx2SOmmeDIURnxpjfvl6nTOLR4hHtCo55ePj2iFrI4D8uEtgZvsrJfk6LiZZuJa1ktIXILksmVPgFkxnWSH4gjwwVjsMCIuXOwvt4A(DOCnmdP5m1fki(i3PwsVky1sLYQzivgneq6ppZ6hobfOVeh0W0sGeSsiI1VGDVngtHblyKaTpeZ9FHoxcOSo1dy7pXc9dSwXQQcLLlqNxFyCaHn1mSWNz5sgYS5N7alroLyLx3Cr5uKllBDaYuSpg5mPBaw8apEvR4cfS0mYZfkAIjYK3qOOCfZx9HHraSSGrbMfNV6rRbGBeYoHuGbnBUYmvuuIiBuaSeRM99WqSal53RYDWqia2cgS(5wnSY4jljLy2Ph5Cx)JHFxu7fX9Mar61ys2PJCGgElG9LfOZEVIwPvAKoqaFAJCrdLm0iXwJgqfgYwYG1284l3vqCMvyt5V3X0kH9YXfk1iXydE(1SrNNNiSzmBussTyJszJg3Py2O0ueXonRCzMcyazz)6hIZYa4BctM(v9drEPkjQkAixiJK28JRYVEtxUQj9porHIvPU5Gk6kLqzX99Q)z4JXrV0jQjEIiowO6T2S34ThAa31ltEiai1mejZHdaAe5x3quqjtTQBn3crwVUItYTOZ4eb3ZCDanYuOTbE9hJCUijY(CNDc)r(cvmTaw)Uy)7eZEqhTCb9bMHgvFAQ9y1RxdrRkgQE7X6f9)sE1m8A9IbC(VVxQxVWldCw)VKxqQr71t5OhQdqDGhU0YliQ0K2khFftNUFIAlqTgptLgrZ19a6SSrDV1gOyJEgc92TAjB0OKaKKeAMjagD9t1yMzjxBE5q5LvKTQMJXpNJqFDiVm7yngy2kxsVYcktLOn6ZSrNAlvObnn8LWbmirh54vSOrP1QMka4kVgmMZY4lhaQnklFlu1D9dUmnsfPds1eauKqGIouyspMqE6nRs9XkoGnsILWcSeUCx(X5quOinz(UQwC)DTaAzAWxrQYLQvLKh86W5QMKiuKCl9dv7EzRLm8wTUdUMLapTUP1gFZkH3EruUSc7lW5Vp)deKmYk)drpomDuwSXD5NEma1vedqCfr)9dwT5BW(xh0muqs0KjeyDMqaqVkjoUUnSJ)uTMnXgvCt8iSzvXFWTKjzNGNFTA4zgsMIQxHk)LkVLFty7(kVrSTnsu)KBestLwLlfj4eeZXjmNOACnJYm4COsZvaUmQHXv3mCwQbC(JVDWzaQrrY2iz8LTrxzRXV2OzTrku0QnQCdKQns1nk1gPvdEAJ0TrxLuv2idBKjuz2ilOlOYTmi7xLzScO3HOJJyKxSOU05yJ4wQOOPftniv5xza)qG)80RQDt(LQLox0XJwtbyTA2g9QnPZZg95WpLn61Gx5FC431Tr)e10RzJGmL1gnbK(K2OPi4uB00wVePQUithLnc6wFridxE9Mmc1g9YBqlJnkhKnEMYeAhCE9tVD6nQPVOVBr9fBGrW9S7CFPUcOpVfStBNgImZlpJvgld5zfzSu(wi9Gb9Ln0cYJ0wneFIpGWs9YUJYACsExXCZf6EysytJ5iHryZrFt7a)77i7RLO)vDnuRTb7FNkqV)GT3ONDcM7R0uym5g4XI2PMHFDd)EfQyDO13cCypBfoKtRufXC0UgApddfMvzc1fvIFHitnwBrHp7hGqH)P1qH6hPPzaVwO631ZH)UDhWhGe)VqqA0O(QP5kNh)N288GI)V6AUpR5IiB0NXgDnB0N9UMnfu6e5WGDURBrbbLTjlj(ChVvqUZSnI(yZIJ2mwsIuNCWqEjNzr)HMkVIvGeT1KIt)brKNn6NHiR77swVioWmB0YThx96nWv3vruBNY5DvevlTn1gTedJKVNkJf5kL7jFPsTfJCM7lWipd(D3ZDGoYbVT0r(A)kTuh5AU9J4DzLKBNNbUBQKeA(BaFXqwL8n9vfVy(jhyIjAlYY39liRhQ9il1Mqw2D3VpweUeqNUI2iuFcLVkpZRznfjO86hT5id1LIY6iqxvExo1Tn6NTPQ2g9Zb)(cD9c7aC7R2At7wQMdUV7bz3TebUtgkXRUVwJoJKCIlezY0tNMBQ2Io9)bs5EBhaImp9BpcQ4Z3se0knMpK7YI92vC2ZobfbT0wIIg(QQLIQiFEd9QTfff4(fu0ozcANJcJCSnQgLnJ(bJyOnFrVrQVXeqaw7KzO9oMk)(MVmMHOAS(sLzlMh2tYr2wfeOlrMnaFs3Nz1reZx2xVrBl8PV7PHpFHgRIqNDLc6wnW1cNj7ePAAri2m5e)k3Sria18YE0gTc(ARtkFUKXImAOujI02kYg9LAUSHJhle3MwaKdYwIoTQaRtkqRFyBtjnImEQ4tKj2Mkt)ol6pYSL2Y3rUXhp7MkvTrB2QNKZSfV5UcNWYVLnS0HIKi(fVDkQ(bZez0XhFSCjil7AUjsNDBk(T0i1Cfg0RYrwLYEJqwvZKO9GZGCDxdbczOtJb9YAJy7g0RASQ)DRQIwN0jcrsZ0IoezExXq84nn0VLRNhd2zI3BnleZ5w6YMgANBjm2OVyZIxi(mO3TZDPwKjLnJKMftyuHsdOQhlES(s0tBfg1)hGSiYvqMhoIGP1MWinz9DDBDwpel4qMGgfLeZzaZEUrgabPwqwTKxsNARm9HyEemEX3yxrTynoV3B0k(e7CTIVgd3UTtim0p0A0ldpwP6iJELPcpFkrT2Ihd(bjBRC8a1pzGb6pqy)(c4JCiq4GbhEyo4SbhIR)G933qC95pqaGr8JUvXg3j(HwET1iRbIozpXh8sXR6pzBrwdCFbYYNnQx83g3XBuFnBejkj42ebvAckENc0skvFnBqVfOyqUSCrAWzxpC4O3HeNoKGR3S5cmv15enuDwWihTPciOlx0BCzdXMtpjzpD5zjYbRhqF00dzuqqvKkGS5hHBNL1CrCnvtn3cJBikUirCBwdb9MRTmfeSixq1Uvl(5(epORaOZgn4(VtJEoB0qSGMddYGol5WpYMJtoB0Zvle5SrpFJGJZg9c4hzp2Opj(m2OpfCzOU5IAJcdNfbGfWPXSrXPH5MnAKgX3MRDHRAXlLPnkXgJTn0UsOTn80HNowGRKC(attSQB7KG9YUdAB)dhCW(zEyyl6h3SVfUblsrQ1WQ5H1XMR1ZbFty8TXxdbeuRURotKs3Y20fAhgPuBieUTrVnj4tC2U(4zYWMruX4C(ZwjuLfB7SkUgidtIkdl0Uw482yb1TIwdAvZB4m84xbZxF4eHj0vx54uSCyJEs4ejswBm0HDIAYn5skCDOs1w7mE3Y8Ud9k1TzeLV7bpQUr4Hn6p2bw47k(oVsV9NpH)l1wyXV7DbyHNDlA4l9R3sA4Y11oDFobeAFBjbSNKM(MSFLKx4QCTLa(1VxMaE(3O1mHUTJ4(CA45FJTMggyuno9Zv6CdpqM2sd)gV)sdDRToCF(6py7S5PD07SV5wmpa1noCBJpU1VdN)ZMhl8TLQ5D(kPRjI90X7F6fcAvoRr7L4(nVRQi2g9TBRcyB03zxs97lVzKWkeT7HuMxOQPdIO)VCRrengwqBre3Yl))DRjo)9sGtVZKOpJRKyuFvl2wGZ36UaW5SUagBhW5BVH9mHAaNwTNkCQM3tfiyliV3rGlB0)bhqv0wlMzvxJP89Du17UNuVpaLY2ZO9jO6xO35c2wO0V3pabLAVfkBrm7yJE97ZTlztrJJlysrrZKk(pxPrNR9rI6V)9Y2wUfrKSn6V59UuUBt26qLgUsOzZZnSW0TLE9hCpm96RTflFIMCE39UuUD4Cz81EPw7Wz32joVQ25hYS0eQT3Hn)H3lZ8n2zA9a7C7V177jMKw52rnlgDHi5nTwm70l0wQ5BDxKAsC8phxIrgnlUd3F8pUqf5cZsjfM199T)7wU(o8yXIN99oVF3ypBkTHwHw547V0JUR457r6Vq6WNpQVuJ2)oEJRGooOikAQIM81gx9a(d67oBNl5(Z5b(wuRNZEttqjXj4M9Q5N6csTLTQX2uYgzROttVaBQ5iKvYCQPJFr28VrN6n)euPQZ)A8emazD(gKoZATGj0DnsY4qqD2vvuxl89VLMIUWrhFQuB4ZrIHS6SIwEj3rV76jpfzLSRnJxljrVX1mmfMvuLLNg7qeXuflxTwf4AROGOn1BiJYIfDTnTrxsimVU5D8kUZoRAiFltA5UmbiP4r21Kuei74PFVtqXAneumx6wiMi6b2vetumE0aJwEQRoGAGDIyIpdjgLws2sSmDlq4Z)FJTsvMGhNr)yTy7pibKZEzbORJIyOBMU8xRvhGGgYcqTSRyGYg9xTVp)70OMT74b2yvy3bISNp0rhBOyj(hC7vSFPBPI1sh(X)ELva3EHoWFjtaLvXaxmXCPfR0t02kG6)5Dr9(pZDQvCp9NQLwXPF4wj55w2Co(71mNdAUTJK6lEYZpWWL7vPu7jP)fV)tsjrEDgdNpJzhNR)abgoaUk7dSJtQ8Gok)KvwP(HP72aEjH1M3mvkuqKSH6tMp(V4732HVJ4apkLCTbA1aZmS)(JQnH4OxST0Q)x3JqRS7yVNnS)(hMUPz4NUPz43pzzw0X(acv3d4JKfpu1O33SxMTtTamXD8ONRr0TQOp8INFW(QgQTe9)31nkmX7xeDGu9U812Ek7ZxFKTKYadsO(bgYhDVADOvbBXi7BfKp3dljmZmIfSa2sYUCh08Vbzdgrwvmnlp83NVT3T7dv(s)wBTWHOdpxORmxYREPrMRT4K)p3fXj(wXuxWyw6UB2rOyg4vZzBbMEN6FOs0putxt)CW86W7J0g(A5Xw8Yq7v)W0qHx8QvKneP7B40ndLTEbnxdKq3MID2FAPKlwiRTuEbNpgNoFdtQV95t2NV5LwJ((X2NEViyW(5ok(yRs(wRaLlh8ZbQK)eKVfMN4obUScBF3L4jbkS5imyJZxda8)XB16(gBE38Fv2JG5TK)to7z)0NZ)zen4YE0ABRVSVIpbGgyBaSpXTfG9g0E0gF9FUizpKNGFzGMgBrYebnKTRDdNUBaI6MAmnAzkj1uUOOn6p)2FGmUKFTkT(hL(D875XtXfrruqfysyp3AF(KCT1xqSRagqzybJlprINTXvpBgkSMwmxXs7)xGxer394)(uogyOtLhzXlovzRs9CbG)Z55lxSOOkxQytgJJUvY7Ahfg)D30xKInUcu64dtydFB63RhYQOPRYDvSRIx)PB(dckEa83JUgjEBB03Ji9WzBlNSLL)w77E8puN7BZBt5x4sx6IXIOVWIM91ITP8Um5670bpTVUM7b)X())
```
