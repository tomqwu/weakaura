# Warlock — All Specs HUD (v18)

Import `all-specs.txt` whole (copy all → `/wa` → Import → paste). One pack for
Affliction, Demonology, and Destruction: every spec-specific piece loads through
a `spellknown` gate, so the HUD auto-adapts on respec with no user action. All
triggers match by exact spell ID — aura triggers carry every rank, cooldown
triggers use the numeric rank-1 ID — never by name, so the pack is safe on zhCN
and every other client. There is zero custom code, so the import dialog shows no
code-review panel. Since v14 the layout is **The Sill: an instrument strip directly
under your character** at `(0, -110)`, and since v17 it is **164 × 36 px** — three
stacked **160 × 13 px rails** (threat 5 px) where **1.6 pixels is one percent**, each
number printed inside its own rail, all of it on a dark plate — with the DoT row and
cooldown row below it, the alert column on the left and — in arena or a battleground
only — the PvP column on the right at `x +190`. Drag whole groups in `/wa` to taste.
Note: the `/wa`
editor preview force-shows everything with fake data (all load gates ignored, so
the PvP column and both curse states and all three specs' icons appear at once,
placeholder durations, no animations) — judge the HUD in combat, not in the
preview.

Upgrading from any earlier version: paste the new string and the import dialog
offers **Update** (every surviving aura keeps its UID), which upgrades the group
in place instead of duplicating it. **Updating from v16 is completely clean** —
v17 adds and removes nothing, it only re-shapes the five strip regions and moves
one group — and the same was true of v14 from v13. In both cases you must **leave
the `Arrangement` category checked** on the update dialog, or the import does
nothing visible: every size and offset in this version travels in `Arrangement`,
and so does the PvP column's new x. See [After updating](#after-updating). Coming
from **v11 or earlier**, one thing is left behind: v12 deleted the target cluster,
and WeakAuras never deletes an aura an import does not mention, so you must delete
the leftover group **`Warlock - Target Orb`** by hand (right-click it in `/wa` →
Delete; that removes its four children with it). Everything else is an in-place
update, as it was in v13, v11, v10 and v9.

## v18 — no aura can render as a question mark any more

The player kept seeing a red `INV_Misc_QuestionMark` in the alert column. It was
`CC ON ME` — and it was, strictly speaking, working.

`Icon.lua` falls through to that texture when nothing supplies art:

```lua
iconPath = iconPath or self.displayIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
```

These auras use `iconSource = -1`, which reads the **live** state's icon — for `CC ON ME` that is
whichever crowd-control effect is actually on you, which is the right design. But in the `/wa`
editor there is no real CC, so WeakAuras builds a fallback state, and `CreateFallbackState` can
only supply an icon when the prototype has a static `GetNameAndIcon`/`iconFunc`. `Crowd
Controlled` derives its icon from the live `data.spellID`, so it has none — and the aura renders
as a question mark that looks exactly like a broken import.

**The fix keeps the live icon and adds a floor.** `displayIcon` is set as a *fallback* while
`iconSource` stays `-1`, so the real icon still wins whenever there is one. Paladin has shipped
this exact pattern since v5; every path used here is one the repo already proves, rather than a
texture string guessed and hoped for — the mistake that left paladin's twist prompt carrying
Horde-only art.

Audited across all seven packs: every `icon` region now either resolves art from a spell-bearing
trigger or carries a fallback. **Zero can reach the question mark.**

## v17 — long and thin, not big

**The Sill goes to the canonical profile.** Two earlier attempts at "the bars are
too small" (in the paladin and rogue packs) scaled the whole strip *uniformly* —
which preserves the plate's original 2.8:1 shape and simply makes the same stubby
block bigger. Both were rejected in play, at 300 px rails and again at 200 px: they
read as a **UI panel**, not a readout.

**A vitals bar wants to be long and thin.** The fill's *travel* is the signal; its
thickness carries nothing. So the rails get 60% longer and stay near their original
height:

| | v14–v16 | **v17** |
|---|---|---|
| rails | 100 × 11 | **160 × 13** |
| threat rail | 100 × 4 | **160 × 5** |
| plate | 102 × 31 | **164 × 36** |
| alarm rim | ±3 (108 × 37) | **±4 (172 × 44)** |
| numbers | 11 pt at x +32 | **12 pt at x +51** |
| ruler hairlines | 1 px | **2 px** |
| plate area | 3,162 px² | **5,904 px²** |

**+87% area for +60% travel** — and the comparison that matters is against the
alternative: scaling the whole strip by 1.6× would give a 163 × 50 plate, 8,150 px²
(**+158%**), for exactly the same extra travel. Area grows with the square; the
reading grows with the length. Height is the axis to spend nothing on, which is why
the bars go 11 → 13 and not 11 → 18.

**1.6 pixels per percent, and every mark still lands whole.** 160 is not a round
number and does not need to be: every value this pack marks is a multiple of five
and 1.6 × 5 = 8, so the 70% threat notch sits at **x +32** and the quarter ruler at
**∓40 and 0** — exact pixels, all of them, and the build now proves it value by
value. The invariant was never the number 100; it is that `markX()` is the only
place a coordinate is derived, which is what makes the rail length a single
constant.

**The lane stack is derived, not copied.** Threat 5 | health 13 | power 13 with 1 px
gaps is 33 px of content on a 36 px plate. This pack centres its plate at local
`y +3` (rogue centres on 0, paladin on +6), so the lanes are *computed* from that:
content top +19.5, threat **+17**, health **+7**, power **−7**, with even 1.5 px
margins above and below where v14 had a 1/2 split.

**The strip does not move, and that is a measurement.** The new 172 × 44 alarm
envelope spans `y −129..−85` at the unchanged `(0, -110)` — still inside the
repo-wide free band (`−136..−80`), 7 px clear of this pack's own DoT row and 5 px of
the band's top edge. Packs that were *enlarged* had to move their buff rows first;
this one never was.

### The PvP column moves to x +190, and it is not about the strip

Every scan this pack shipped before v17 measured things **against the strip**, which
structurally cannot see two *flanking* stacks overlapping **each other**. The new
all-pairs scan does, and it found that the PvP column at `x +150` had been sitting
on top of two of its neighbours the whole time:

| pair | clearance at x +150 | at **x +190** |
|---|---|---|
| PvP vs DoT row | **−18 px (overlap)** | +22 px |
| PvP vs cooldown row | **−16 px (overlap)** | +24 px |
| PvP vs the strip's alarm rim | +36 px | +44 px |

The cause is that the column's box is not icon-width: `Warlock - Enemy Mana` is a
120 px aurabar, and a down-growing group centres its children on the anchor, so the
column occupies `x ±60` at any depth its stack reaches. Neither stack being six deep
is hypothetical — a Destruction lock in an arena can have five cooldowns down at
once, and the mana bars clone once per opponent. The measured minimum anchor is
**+168** (the DoT row's right edge at 108, plus half the bar); +190 is shipped. The
column is therefore no longer the mirror image of Alerts at −150, and it cannot be.

Every pairwise clearance is now printed by the build, not just the failures.

**Nothing else changed.** No aura added, removed, renamed or re-parented; not one
trigger, load gate, condition, colour or spell ID touched. Exactly six auras differ
from v16 — the five strip regions and the PvP group's `xOffset` — and all 39 UIDs
are byte-identical, so importing offers **Update** with no allowance list.

## v16 — the rails were filling the wrong way

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

## v15 — the number offsets were never actually applied

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

## v14 — The Sill: the ring cluster becomes an instrument strip under your feet

**The rings are gone.** Three concentric arcs around a live 3D portrait at
`(-270, 40)` are replaced by **three stacked rails on a dark plate at absolute
`(0, -110)`**, directly under your character, in a 102 × 31 px box. Every rail is
**100 px long, and one pixel is one percent.**

```
      x -54                                                    x +54
     ..........................................................    y  -88.5   <- 80% alarm rim
     .  x -51                     x 0                    x +51 .              (108 x 37, ADD red,
     . +------------------------------------------------------+.   y  -91.5   drawn FIRST/underneath)
 threat |  ####################:####                           |   100 x  4
 health |  ####################|##############|####      73    |   100 x 11
 power  |  #########|#########                           41    |   100 x 11
     . +------------------------------------------------------+.   y -122.5
     ..........................................................    y -125.5
                            YOU  —  (0, -110)

     :  the 70% threat notch, permanently at x +20   (x = v - 50)
     |  the quarter ruler, three hairlines at 25 / 50 / 75%
    73  the percentage, 11 pt, printed INSIDE its own rail at x +32
     .  the 3 px band of the alarm that sticks out past the 102 x 31 plate —
        the ONLY part of it you ever see, because everything inside the plate's
        footprint is drawn behind the plate and behind every rail and number
```

**Why a bar beats a ring here, in numbers taken from the v13 string.** A ring buys
gauge length with area *squared*: at 100 / 84 / 62 px the three arcs delivered
289.6 / 243.3 / 179.6 px of ink — 712 px — inside a 10,000 px² box, and 1,936 px²
of that box (19.4%) was a 3D model carrying no decision. But a 0–100 quantity has
exactly **100 distinguishable states**, so a 243 px arc spends 143 px re-drawing
states the eye cannot separate, on a curve, at a radius that is different from the
next ring's — which means two arcs were never directly comparable by eye. Three
100 px rails sharing one origin and one scale carry the same 300 states in
3,162 px², are stacked so the comparison is vertical, and are **31 px tall instead
of 100** on the axis that is actually scarce.

| | v13 cluster | v14 Sill | ratio |
|---|---|---|---|
| bounding area | 10,000 px² | 3,162 px² | **3.16×** |
| height (the scarce axis) | 100 px | 31 px | **3.2×** |
| readable states carried | 300 | 300 + 1 notch + 6 ruler ticks | — |
| px² spent on decoration | 1,936 (19.4%) | 0 | — |

It also makes every breakpoint arithmetic instead of trigonometric. The general
form is `x = (v / maxpower − 0.5) × 100`, which on a 100-max gauge is simply
**`x = v − 50`**: the 70% threat notch is at `x = +20`, and that is the whole
calculation. The ring era needed `r = size/2 × 0.94; x = r·sin(2πf); y = r·cos(2πf)`
to land a mark on a circumference.

### What each rail says

| lane | size | reads | escalation |
|---|---|---|---|
| **Threat** (top, 4 px) | 100 × 4 | your share of the pull threshold | green → **orange at 70%** → red on aggro; **a 2 px notch marks the 70 line** |
| **Health** (11 px) | 100 × 11 | `%percenthealth%%` printed inside, at the right-hand end | green → **amber at or below 60%** (the Life Tap health input) |
| **Power** (11 px) | 100 × 11 | `%percentpower%%` printed inside, at the right-hand end | blue → **violet below 30%** (the Life Tap mana input) |

**Reading rules.** Threat: absent means you are solo, in an arena, or not on
anyone's threat table. When the green fill **touches the notch you are at 70** —
stop or dump. Orange is past it, red means you pulled, and **a 3 px red band
pulsing around the outside of the whole strip is 80%** — a rim *around* the
instrument, drawn underneath it, so every rail and both numbers stay fully
readable while it flashes; the section "The ≥80% threat alarm is a rim around the
strip" below says exactly how that is built and why it has to be. Health and power:
the fill is the state, the number is
the precision, and **the colour is the threshold** — the moment a rail changes hue
you are inside the window that decision belongs to. Life Tap is now literally one
comparison: is the green rail long and the blue one short. Out of combat the whole
strip sits at 50% alpha, exactly as the cluster did.

**Each 11 px rail carries a quarter ruler** — three 1 px hairlines at 25 / 50 / 75%
at 18% white. Thirty-three pixels of ink, zero footprint, and it turns "estimate a
fraction" into "count quarters".

### The plate is the point

The dark bordered rectangle behind the rails is not decoration, it is the actual
fix for the complaint v13 tried to solve by moving a number. **"The percentage
can't be seen" was a contrast problem, not a coordinate problem**: v13 put the
health number dead centre on your portrait because the portrait was the darkest
thing the cluster had. The Sill gives *every* element that backdrop, permanently,
and it is what lets an 11 px rail and an 11 pt number survive a snowfield, a fire
and Shattrath at noon. It is also what makes four separate regions read as **one
instrument** rather than four floating things.

### Where it sits, and why there

`(0, -110)` is under the character, in the band this repo keeps clear in all seven
class packs. It is bounded by two rows: the paladin and hunter packs' buff rows at
`y -80..-40`, and the other five packs' buff rows at `y -176..-136` — which in
*this* pack is the DoT row at `y -156`. The build asserts a full rectangle scan of
the strip against every other element in the pack, **with the alert column, the PvP
column and the cooldown row each projected six children deep**, because a check
made with one prompt showing proves nothing about a real pull:

The scanned box is the **alarm envelope**, not the plate: at ≥80% threat the strip
draws a 108 × 37 rim around its 102 × 31 plate, and that is the largest thing it
ever puts on screen — during a real pull, which is precisely when the clearance
has to hold.

```
envelope x -54..54  y -125.5..-88.5   vs 8 elements   ->  0 overlaps
  (plate alone: x -51..51  y -122.5..-91.5)
  DoT row (5 icons)          y -176..-136      10.5 px below the envelope  <- tightest
  Alerts,   projected 6 deep x -172..-128      74.0 px, no horizontal overlap
  Cooldowns,projected 6 deep y -222..-190      64.5 px below
  PvP,      projected 6 deep x  90..210        36.0 px, no horizontal overlap

  tightest clearance anywhere: 10.50 px, to Warlock - Curse in the DoT row
```

**No other row moved.** The DoT row, the cooldown row, the alert column and the
PvP column are all exactly where v13 left them.

### What was lost — read this before deciding you like it

* **The live 3D portrait is gone.** v11 brought it back deliberately, arguing that
  "two concentric arcs around a live 3D portrait read as *a unit* — you". v14
  reverses that judgement on density grounds: 1,936 px², 19.4% of the old cluster,
  carrying zero decisions in a rotation-first pack. **This is a taste call and it is
  the single most likely thing to dislike.** Its UID is not wasted — it is what the
  Sill Plate is built on, so nothing is orphaned.
* **The threat number is gone from the screen.** It is *switched off*, not deleted:
  the sub-region is still there at index 1 and re-enabling it is one checkbox in
  `/wa` (select `Warlock - Threat` → Display → the text sub-region → tick Visible).
  Its position is untouched from v13, so it reappears **58 px above the threat
  rail**, floating over open screen rather than inside the strip — a 4 px rail has
  nowhere to put a 10 pt number, which is part of why it went.
  It is off because `threatpct` is scaled so 100 = pulling aggro — an early-warning
  *ratio*, not a quantity you spend — so "has the fill reached the notch" is a
  faster read than "is 68 close enough to 70". Still, it is information deliberately
  removed, and it printed at 10 pt over open screen, which is the other half of why
  it went.
* **Numbers straddle the waterline.** With a left-to-right fill and the number at
  `x = +32`, health at ~82% puts the fill edge under the digits. `OUTLINE` + a black
  shadow + the dark plate is the mitigation, and it is the thing to judge in combat
  rather than in the editor.
* **A ring's arc is prettier than a bar.** Four stacked rails are a car dashboard;
  the v13 cluster was a character. That is the honest aesthetic cost of the density
  gain, and it is not a small one.
* **The 80% threat alarm changed shape.** The v13 halo orbited the rings; the v14
  alarm is a 3 px red band around the outside of the strip. It is smaller and
  quieter than the halo was, which is deliberate — it is drawn *underneath* the
  instrument so it can never cover a readout. Full detail below.
* **One field has never been rendered by this repo.** `orientation =
  "HORIZONTAL_INVERSE"` is WeakAuras' "Left to Right" on a progresstexture (its
  `HORIZONTAL` is *Right to Left* — the enum lies about direction in the usual WA
  way, and note the aurabar's `HORIZONTAL` means the opposite thing). It shares the
  linear code path with `VERTICAL`, which this repo has shipped, but no committed
  string here uses it. **30-second field check: drop to about half health and
  confirm the empty half of the rail is on the RIGHT.** If it is reversed, the fix
  is a one-token swap to `HORIZONTAL` and nothing else changes.

### The ≥80% threat alarm is a rim around the strip

`Warlock - Threat Flash` keeps its UID, its `threatpct ≥ 80` trigger, its party/raid
gate, its not-in-an-arena gate, its `alphaPulse` and the explicit red
`(1, 0.10, 0.10, 0.85)` it has carried since v7. What changed is its **size and its
place in the draw order**: it is a **108 × 37** box on `ADD` blend, concentric with
the 102 × 31 plate — 3 px larger on every side — and it is the **first** child of
the sill group, i.e. the bottom of the stack. Only the 3 px band sticking out past
the plate is ever visible. Everything inside that footprint is hidden behind a
45%-black plate and behind every rail, number and mark, so **nothing is ever
composited over a readout**.

**Why it is built inside-out, and it is not a style choice.** The texture is
`Interface\AddOns\WeakAuras\Media\Textures\Square_White_Border.tga`. Decoded out of
a real game install rather than guessed at, it is a 256 × 256, 32 bpp, RLE TGA in
which **64,516 of 65,536 pixels — 98.44% — are fully opaque (alpha 255)**. Take
every pixel inset 8 px or more from the edge: **n = 57,600, minimum alpha 255,
minimum RGB channel 167**. The centre scanline's red channel across `x = 0..13`
reads `0, 156, 100, 56, 40, 57, 102, 158, 206, 236, 250, 254, 255, 255`, and the
centre pixel is `rgba(255, 255, 255, 255)`.

So the file is a **filled white square with a dark bevel baked into its edge**. It
is *not* an outline and its interior is *not* transparent — the dark part is a ~6 px
ramp at the rim and nothing else. A single region drawn from it therefore cannot
trace a hollow frame at any size.

That is the trap this construction exists to avoid. Ship the alarm at the plate's
size on top of the stack and ≥80% threat paints a **full-area red `ADD` quad over
both rails, both percentages, the 70 notch and the quarter ruler** — washing out the
readouts at exactly the moment you most need to read them. Ship it 3 px oversized
and underneath, and the same filled art reads as a clean pulsing edge. **The size
and the draw index are two halves of one mechanism**; the build asserts both
(`alarm.width == plate.width + 6`, `alarm.height == plate.height + 6`,
`controlledChildren[1]` is the alarm and `[2]` is the plate), because dropping
either one turns the rim silently back into a wash. The sibling rogue pack ships the
identical 3 px construction.

It also costs almost nothing: the plate is 102 × 31 = 3,162 px², the alarm envelope
is 108 × 37 = 3,996 px², and the difference — 834 px² of rim — exists only while
threat is at or above 80%.

### Nothing else changed

Every trigger, load gate, condition and colour outside the strip is byte-identical
to v13 — the DoT row, the alerts, the cooldown row, the procs and the whole PvP
layer are untouched — and so are the three rails' own: the Threat Situation
trigger with its era-correct `threatUnit` arg, the party/raid gate, the
not-in-an-arena gate, the `threatvalue <= 0 → alpha 0` guard (mandatory: a
progresstexture with a zero total draws **full**, i.e. reports complete aggro at
the moment you have none), the health `maxhealth <= 0` guard, the mana
`maxpower <= 1` guard, the 60% amber, the 30% violet, the 70% orange, the aggro
red, the out-of-combat fade and the 80% alarm's `alphaPulse`. Verified by decoding
both strings and diffing them keyed on UID: **zero** fields changed anywhere under
`triggers`, `conditions`, `load`, `animation` or `actions`, in the strip or outside
it.

The full field scope, measured by a whole-record diff keyed on UID (every leaf
field, not a chosen subset) rather than described from memory. Seven auras differ
from v13 — the six strip auras plus `Warlock - Resources`, whose
`controlledChildren` entry follows the group's rename — and the changed top-level
keys are exactly:

| aura | changed keys |
|---|---|
| `Warlock - Player Sill` (group) | `id`, `xOffset`, `yOffset`, `controlledChildren` |
| `Warlock - Resources` | `controlledChildren` (the rename, echoed) |
| `Warlock - Threat` | `height`, `yOffset`, `parent`, `orientation`, `foregroundTexture`, `backgroundTexture`, `subRegions` (`width` was already 100) |
| `Warlock - Player Health` / `- Player Mana` | the same, plus `width` |
| `Warlock - Threat Flash` | `width`, `height`, `yOffset`, `parent`, `texture` |
| `Warlock - Sill Plate` | geometry, `id`, `parent`, `subRegions`, plus the whole `model` → `texture` re-type: `regionType`, `texture`, `blendMode`, `textureWrapMode`, `color`, `mirror`, `rotate`, `desaturate`, `discrete_rotation`, the `border*` / `backdropColor` block a texture region carries, the `model_*` / `portraitZoom` / `modelDisplayInfo` / `modelIsUnit` / `sequence` / `advance` / `api` block a model region no longer carries — and `frameStrata` |

So outside geometry, the ring→rail art swap, the sub-region rebuild, the renames
and the re-type itself, exactly **two** fields changed, both on the plate, and both
are listed here rather than left to be found in a diff:

* **`color` gained** `(0, 0, 0, 0.45)` — a `texture` region needs an explicit colour
  and a `model` region had none. Without it the plate would draw in WeakAuras'
  default.
* **`frameStrata` 2 → 1**, i.e. BACKGROUND → Inherited. v13 set the portrait to
  BACKGROUND deliberately (the *lowest* strata — that was v13's fix for the face
  covering the numbers); `F.texture` emits Inherited, the same strata the three
  rails use, and v14 keeps it. **Nothing moves visually**: the alarm rim is child 1
  of the group and the plate is child 2, and WeakAuras gives each child +4 frame
  levels in `controlledChildren` order, so frame level — not strata — decides
  layering inside the group and rim and plate are still the two rearmost things in
  the strip. The build now asserts the plate and the alarm both sit on the rails'
  strata, so this cannot drift unnoticed again — a lifted plate would bury every
  rail, and a lifted alarm would go straight back to being a red wash over the
  readouts no matter where it sits in `controlledChildren`.

Six auras were re-shaped and **not one `W.uid()` call was added, removed or
reordered**, so all 39 v13 child UIDs are byte-for-byte stable
(`changed=0 missing=0`) and the build runs `W.assertUidContinuity` with **no
allowance list**:

| v13 | v14 | UID |
|---|---|---|
| `Warlock - Player Orb` (group) | **`Warlock - Player Sill`** | carried |
| `Warlock - Player Portrait` (model 44×44) | **`Warlock - Sill Plate`** (texture 102×31) | carried |
| `Warlock - Threat` (progresstexture 100×100 ring) | threat rail 100×4 | carried |
| `Warlock - Player Health` (84×84 ring) | health rail 100×11 | carried |
| `Warlock - Player Mana` (62×62 ring) | power rail 100×11 | carried |
| `Warlock - Threat Flash` (ring halo) | 80% alarm rim 108×37, drawn first | carried |

Renaming, re-parenting, re-typing and resizing are all free — WeakAuras matches
auras across imports by UID and then applies the new ID. Only the `uid()` **call
order** is sacred, and no constructor call moved.

### After updating

**Leave the `Arrangement` category CHECKED on the update dialog.** It is checked by
default, and this is the one version where unchecking it breaks the update rather
than protecting it: v14 moves the group from `(-270, 40)` to `(0, -110)` and changes
every region's size and offset. Both travel in `Arrangement`. Uncheck it and you
keep the v13 ring geometry with v14's textures, which looks like the import did
nothing.

(v14 **does** re-order `controlledChildren`, and that also travels in
`Arrangement`. v13 listed `{ Portrait, Threat, Health, Mana, Threat Flash }` — the
backdrop first, the flash last — which is right when the flash is a ring *halo*, an
annulus with a hole in it. v14's alarm is a filled quad, so it moves to the front of
the list and grows 3 px per side instead: `{ Threat Flash, Sill Plate, Threat,
Health, Mana }`. Re-ordering costs nothing in UID terms — `adopt` order is not
`uid()` order.)

The cost of that is the usual one: **if you had dragged this pack around in game,
those positions are reset** and you will have to drag it again. If you want your
own coordinates baked in permanently instead, report them and they go into
`generate.lua`.

There is nothing to delete afterwards. v14 removes no aura, so an update from v13
leaves nothing orphaned.

## v13 — the health number moves into the middle, onto your face

**The complaint was "the percentage in the middle can't be seen". It could not be
seen because it was never in the middle.** Since v11 both numbers hung *outside*
the rings — health at 13 pt, 54 px below the cluster, mana at 10 pt, 70 px below —
two small figures floating over whatever the game world happened to be showing
behind them. Over a bright floor, a snowfield or a fire effect they simply vanish.
The middle of the cluster, meanwhile, held nothing but your portrait.

```
        ,-------------.
       /   ,-------.   \        THREAT 55%   <- 10 pt, 58 px above centre
      |   /  ,---.  \   |
      |  |  | 83% |  |  |       <- 16 pt, DEAD CENTRE, on your portrait
      |   \  `---'  /   |
       \   `-------'   /        threat  100 px   health 84 px
        `-------------'         mana     62 px   your face 44 px
              62%               <- 12 pt, just under the rings
         YOU  (-270, 40)
```

| Number | v12 | v13 |
|---|---|---|
| Health `%percenthealth%%` | 13 pt, 54 px below centre | **16 pt, dead centre, on your portrait** |
| Mana `%percentpower%%` | 10 pt, 70 px below centre | **12 pt, 54 px below** — the slot health vacated |
| Threat `%threatpct%%` | 10 pt, 58 px above centre | unchanged |

**Why the middle is the right place.** Your portrait is the darkest, most stable
backdrop the cluster has — it is a rendered 3D model, not the game world — and it
is where your eye already goes. A number sitting on it is legible over anything
you happen to be standing in front of. Health gets it because health is the
number you read under pressure; it grows to 16 pt because it is now the cluster's
headline rather than a caption beneath it. Mana slides up into the slot health
left behind, so there is **one** number under the cluster instead of two stacked,
and it gains 2 pt now that nothing bigger sits directly above it. Every label
keeps its outline font, its shadow, its colour and its text token — only the
offsets and two sizes moved.

**The half of this that is not a coordinate: draw order.** Moving the health
number to the centre and nothing else would have looked like *nothing happened*.
WeakAuras lays sibling regions out by their order in the group — `FixGroupChildrenOrder`
adds +4 frame levels per child, so **later = drawn further forward** — and the
portrait was the **last** child of the cluster. It was painted over everything the
rings put in the middle, including their text. So the portrait becomes the
**first** child instead:

```
v12   { Threat, Health, Mana, Portrait, Threat Flash }     face on top
v13   { Portrait, Threat, Health, Mana, Threat Flash }     face at the back
```

**Putting the face behind the rings hides none of it, because a ring is an
annulus.** `Ring_20px` paints a band from `0.84375r` to `r`, so the three arcs
occupy radii `42.19..50`, `35.44..42` and `26.16..31`, while the face is a disc of
`0..22` — the innermost band still clears it by 4.16 px. No ring art overlaps the
portrait at any radius; the only thing that lands on your face is the text, which
is the entire point. The build asserts that clearance from the decoded diameters,
so a future ring that *would* cover the face fails the build instead of shipping.

**A comment in the build script was wrong, and is now right.** Two places claimed
`frameStrata 2` put the face *above* its rings "no matter how the children are
ordered". That is backwards: WeakAuras' `frame_strata_types[2]` is `BACKGROUND` —
the **lowest** strata, below the inherited strata `1` the rings use. (The mage pack
documents the same fact for its rims, which are deliberately drawn behind at
`frameStrata 2`.) The portrait keeps `frameStrata 2` **in v13** (v14's Sill Plate
moves to `1`, the rails' strata — see [Nothing else changed](#nothing-else-changed)
above) and was therefore *already*
behind its rings; strata outranks frame level, so the reorder does not change which
one wins — it makes the frame-level ordering agree with the strata instead of
contradicting it. The wrong comment mattered anyway: the next person to read it
would have "fixed" the strata to put the face genuinely on top and buried the
number all over again.

**Nothing else changed at all.** No aura added, removed or renamed — still 40 — and
**every UID is byte-for-byte stable** (39 of 39 children plus the top-level group;
`changed = 0`, `missing = 0`), because UIDs are assigned where a region is
*constructed* and not one constructor moved; only the wiring calls that order the
cluster changed, and the build derives both `controlledChildren` and the flat
transmit list from those, so the two cannot drift apart. Not one trigger, load
gate, condition, colour, diameter or position moved. The cluster is still at
`(-270, 40)`, still 100/84/62 around a 44 px face, and the DoT row, cooldown row,
alerts, procs and PvP layer are untouched. Updating is an ordinary in-place
**Update** with nothing to delete afterwards.

*(Housekeeping: v12's removal licence expires here, as designed — the four
`-- WA-REMOVED (v12):` tags stay as lineage but are no longer honoured, and v13 is
back on the default contract that no UID may disappear at all.)*

## v12 — one cluster, and threat is yours

**The target cluster is gone. Threat moved onto your own rings as the outermost
arc.** Four auras removed, 44 → 40, and nothing else in the pack changed.

```
        ,-------------.
       /   ,-------.   \        THREAT 55%   <- 10 pt, 58 px above centre
      |   /  ,---.  \   |
      |  |  |  ()  |  |  |      threat  100 px  (outermost, party/raid only)
      |   \  `---'  /   |       health   84 px
       \   `-------'   /        mana     62 px
        `-------------'         your face 44 px
              83%
              62%
         YOU  (-270, 40)        — no second cluster on the right
```

**Why the target cluster went.** Its big readout was the target's health, which
is already on your target frame and on the target's nameplate; for the whole game
it was a second copy of the default UI parked at `(+270, 110)`. The ring track
under it existed only to keep the two sides looking like a matched pair, and the
target portrait told you what you were already looking at. Rotation-first means a
readout has to change the next button press, and none of those three did.

**Why threat did not go with it.** Threat is the one thing that cluster carried
that nothing else on screen shows, and a DPS who pulls aggro dies. So it moved
instead of dying — and it moved onto **your** cluster, at 100 px, one ring
outside your health, because it was always **your** threat rather than a property
of the target. Same green → orange at 70% → red on aggro, same pulsing red halo
at 80%+ (now resized to sit exactly *on* the threat ring instead of orbiting the
old radius), same percentage above the cluster at 10 pt, and the same
party/raid-only and never-in-an-arena load gates plus the zero-threat guard. That
last part matters for how it looks: because threat only loads in a party or raid
and hides itself at zero threat, **solo you still see just two rings and a face**
— the third arc appears only when threat is a real thing you can lose a raid slot
to.

| Ring | Size | Shows | Escalation |
|---|---|---|---|
| Outermost | 100 px | **your threat** on your target | green → orange at 70% → red on aggro; red halo pulses at 80%+ |
| Outer | 84 px | your health | **amber at or below 60%** (the Life Tap health input) |
| Inner | 62 px | your mana | **violet below 30%** (the Life Tap mana input) |
| Centre | 44 px | your live 3D portrait | fades and vanishes with the rings |

**Positions did not move.** The cluster is still at absolute `(-270, 40)` — the
group offsets are derived, not typed, and the build walks the decoded parent
chain (`top (0, -140)` → `Resources (0, +56)` → `cluster (-270, +124)`) to prove
it. All three rings, the face and the halo sit at a local `(0, 0)`, which is what
makes them concentric by construction rather than by eye. The widened ring
reaches `x -320..-220`; the alert column is `x -172..-128` and grows upward, and
the build asserts the 48 px gap with the alert stack projected **six prompts
deep**, because "it looked fine with one alert showing" is how you ship an
overlap.

**⚠ Delete one group by hand after updating.** WeakAuras never deletes an aura
that an import does not mention, so the four removed auras stay in your
collection as a leftover group. In `/wa`, right-click **`Warlock - Target Orb`**
and delete it — that takes `Warlock - Target Health`, `Warlock - Target Ring
Track` and `Warlock - Target Portrait` with it. Nothing else needs touching, and
nothing invisible is left behind: the pack deliberately does **not** invent filler
regions to keep those four UIDs alive, because that is exactly how a HUD fills up
with elements nobody can justify a year later.

**Every surviving UID is byte-for-byte identical** (39 of 39 children, plus the
top-level group), because the four removed regions were the *last four* `W.uid()`
calls in the build — removing the tail shifts nothing. The removals are declared
to the repo verifier one ID at a time (`-- WA-REMOVED (v12): …`), so a deletion is
a reviewable line in a diff instead of a silent count, and any *undeclared* UID
disappearance still fails the build. Let the Update dialog's **Arrangement**
checkbox through, or your cluster keeps its v11 coordinates and the new ring will
not appear where the numbers expect it.

**One correctness fix rode along**, in the threat trigger only. The pack ships
`internalVersion 45` data, and the Threat Situation prototype's unit argument was
renamed from `threatUnit` to `unit` at internalVersion 51 — WeakAuras' `Modernize`
migrates older data forward, so IV-45 data must emit the **old** name and let the
migration rename it. v11 emitted `threatUnit` *and* an extra `unit` field, which
is an IV-51+ field written onto IV-45 data. The stray field is gone; behaviour is
unchanged (it still reads your target).

**Nothing outside the cluster was touched:** not one trigger, load gate, condition
or spell ID in the DoT row, the alert flow, the cooldown row, the procs or the
PvP layer.

## v11 — the rings are back, and so is your face

**The globes are gone. Health, mana, threat and your target's health are arcs
again — two concentric rings around a live 3D portrait, one cluster per unit.**

```
         ,--------.                        ,--------.
        /  ,----.  \                      /  ,----.  \
       |  |  ()  |  |                    |  |  ()  |  |
        \  `----'  /                      \  `----'  /
         `--------'                        `--------'
             83%                               41%
             62%                          THREAT above: 55%
      YOU  (-270, 40)                  TARGET  (+270, 110)
```

| Cluster | Outer ring (84 px) | Inner ring (62 px) | Centre (44 px) |
|---|---|---|---|
| **You**, left | your health, green, **amber at or below 60%** | your mana, blue, **violet below 30%** | your live portrait |
| **Target**, right | **your threat** on it, green → orange at 70% → red on aggro | its health, green | its live portrait |

Both sides use the same three diameters, which is the whole reason they read as a
matched pair rather than as two unrelated widgets. **There is deliberately no
target mana ring**: a third arc on one side and two on the other is exactly what
made the old v8 cluster look busy and uneven.

Your two rings still carry the Life Tap decision, and it is still one glance —
"is the outer arc long and the inner one short" — only now both halves of it live
on one object instead of two vessels a screen apart.

**Why the numbers moved back outside the rings.** A `model` region cannot carry
text at all, so the moment a live portrait occupies the middle of a cluster the
percentages have to sit somewhere else: health 13 pt just under the outer ring,
mana 10 pt below that, threat 10 pt above the ring where it can never collide
with them. That is the trade the globes made in reverse — v9 dropped the face to
buy the middle, v11 spends the middle to get the face back.

**What did not change.** Every trigger, every load gate and every escalation:
health amber at 60% and mana violet at 30%, threat's green → orange → red, its
party/raid-only and never-in-an-arena gates, the pulsing red halo at 80%+ threat,
the out-of-combat fade to 50%, and the guards that keep a ring from reading full
when its total is zero (a `progresstexture` with `total == 0` draws **full**, not
empty — that is why threat carries an explicit `threatvalue <= 0` guard). The
whole target cluster still vanishes when you have no target. Nothing outside the
two clusters was touched.

**Nothing to delete after updating.** All 44 UIDs are byte-for-byte identical to
v10 and the aura count is unchanged: every globe and rim was *recycled* into a
ring, a portrait or the target's outer track rather than deleted and re-added, so
a v10 import offers **Update** and leaves no orphans. The two "globe rims" that
carry the portraits' UIDs are in fact the same UIDs the v7/v8 portraits had, so
this restores those auras to what they were. Let the Update dialog's
**Arrangement** checkbox through, or the auras will keep their v10 coordinates
and you will not see the change.

The one aura whose job is not obvious: **Target Ring Track**, an unfilled outer
ring in the same track colour a progress ring draws behind its arc. The threat
ring only loads in a party or raid outside an arena, and hides itself at zero
threat — so solo, in an arena, or before your first cast lands, the target would
show one lonely inner ring next to your two. The track keeps the pair matched;
when threat is live it is covered exactly and you never see it.

One correction to v7's honest notes: **the portraits now fade out of combat with
their rings.** `alpha` is a common region property — the region prototype adds it
to every region type, `model` included — so each face carries the same
out-of-combat fade and the same zero-total guard as the arcs around it, and a
cluster dims and vanishes as one object instead of leaving a lit face behind.
Also still true, and still verified against the build: **this pack ships no
resource breakpoint marks**, because it never had any. Health and mana escalate
by colour (amber at 60%, violet at 30%), not by threshold ticks, so there is no
mark to place on a circumference.

## v10 — the globes stand beside you, and the glass catches light

Two changes, no new auras, nothing removed.

**1. They moved out from under the HUD and up beside your character.** v9 parked
all three vessels on one band at `y = -262`, which read as a *separate bar bolted
under the HUD* rather than as part of you. They now flank the character:

```
                        ,---.
                       ( 41% )        target      (0, 110)
                        `---'
       ,-----.                            ,-----.
      ( 83%   )                          ( 62%   )
       `-----'                            `-----'
      LIFE  (-270, 40)                MANA  (+270, 40)
```

Your life and mana keep a shared line, because "can I Life Tap?" is still one
glance at two objects. The target's vessel sits above and between them, where
your eye already goes for a nameplate. **Sizes did not change** — 72 px for
yours, 44 px for the target's, each rim 4 px wider.

Those x coordinates are a repo-wide contract rather than a taste call: `∓170`
collides with the Alerts column at `x = -150` and the PvP column at `x = +150`,
and `±210` collides with the PvP layer's elements at `(200, -44)`. `±270` is the
one width that clears both in every class pack. It also ends v9's honest note
about the target globe landing on top of the DoT row — the DoT icons are at
`y = -156` and the target vessel is now at `y = +110`, so they no longer share
screen space.

**2. Each vessel now catches the light.** A flat disc of colour reads as a
sticker; real glass has a bright spot where it faces the light. Every globe gets
a soft, off-centre highlight in its upper left — sized as a fraction of that
globe, so the small target vessel gets the same look and not the same pixels —
and the liquid inside starts reading as liquid *in something*.

The highlight is drawn in **ADD** blend, which is the deliberate part: the
percentage lives inside the glass, overlays draw on top of it, and a normal
overlay would dim the number. ADD only ever brightens, so the number stays as
readable as it was. That is also why this is a highlight and not the more obvious
dark rim shadow — a dark overlay in that position would have cost you the text.

**Nothing else changed.** No aura was added, removed, renamed or reordered; every
trigger, load gate, condition, colour and spell ID is untouched; the alerts, the
DoT row, the cooldown row, the procs and the whole PvP layer are exactly as they
were. All 44 UIDs are byte-for-byte identical to v9, so the import dialog offers
**Update** and leaves nothing orphaned. Let the Update dialog's **Arrangement**
checkbox through, or the globes will keep their v9 coordinates and you will not
see the move at all.

## v9 — Diablo globes

**The rings are gone. Your health and your mana are now two glass vessels that
fill from the bottom like liquid**, one on each side of the character, with your
target's health as a smaller vessel between them.

```
      ,-----.                                       ,-----.
     ( 83%   )              ( 41% )                ( 62%   )
      `-----'                `---'                  `-----'
      LIFE                   TARGET                  MANA
    x = -150                  x = 0                 x = +150
```

(v10 moved all three — see above. The rest of this section describes what v9
changed, and every word of it still holds.)

A ring told you a value by how far an arc had swept round a hoop. A globe tells
you the same thing the way a glass of water does: the liquid has a **level**, and
you read it without decoding anything. That is the whole reason for the change —
under pressure you glance at a level, you do not measure an arc.

| Globe | Where | What it does |
|---|---|---|
| **Life** | left, 72 px | your health, deep red, **amber at or below 60%** — the health half of the Life Tap decision |
| **Mana** | right, 72 px | your mana, blue, **violet below 30%** — the mana half of the same decision |
| **Target** | centre, 44 px | your target's health, smaller so it reads as secondary; **disappears entirely when you have no target** |

Both of your globes carry a real decision, and neither is decoration: **Life Tap
trades the left globe for the right one.** "Can I tap?" is now literally "is the
red one high and the blue one low" — two objects, one glance, no numbers needed
(though the numbers are there).

The unfilled part of each globe is a near-black disc rather than nothing, which
is what makes it read as a *container* being filled instead of a shape appearing
out of the void, and a brass rim is drawn over each one so the liquid looks like
it is inside the glass.

### The percentages moved inside the glass

They used to sit *under* the orbs, on a shared baseline, where they competed with
the world behind them. They are now **in the middle of each globe**, where your
eye already is: 13 pt on your two, 10 pt on the target's.

That is possible only because **the portraits are gone**. A WeakAuras `model`
region — which is what a live 3D portrait is — cannot carry a text sub-region at
all, so as long as a face occupied the middle of each orb the numbers had nowhere
to go but outside. Diablo has no portrait either. **The trade is real and it is
the one thing this version takes away: no live face for you or your target**, so
an accidental target swap now shows up as a changing health level and name rather
than a changing face.

### Threat became the target globe's rim

Threat is not a pool, so it has no natural vessel — and inventing a fourth globe
for it would have cost real screen space for something you only look at when it
is going wrong. Instead **it colours the glass around the target globe**:

| Rim colour | Meaning |
|---|---|
| **Green** | you are on the threat table and fine |
| **Orange** | 70%+ — the tank is in sight |
| **Red** | you have aggro |

with the threat percentage sitting just above the globe, and the pulsing red halo
at 80%+ exactly where it always was. Nothing about threat's behaviour changed:
still party/raid only, still **never inside an arena**, still hidden entirely at
zero threat (a rim that read "full aggro" the instant before your first cast
landed would be worse than no rim at all), still dimmed out of combat. When
threat does not load — solo, or in an arena — the target globe wears a plain
brass rim like the other two, so it never looks broken.

### Nothing to delete after updating

Every aura the orbs were made of is **recycled in place**, not replaced: the two
player rings became the life and mana globes, the threat ring became the threat
rim, the flash stayed a flash, and the two portraits and the target's two rings
became the three rims and the target globe. They keep their UIDs, so the import
dialog offers **Update**, rewrites them where they stand, and leaves **no
orphaned portraits or rings behind**. All 44 UIDs are byte-for-byte identical to
v8 and no aura was added or removed.

As always, the Update dialog's **Arrangement** checkbox carries the new sizes and
positions. If you have dragged groups in game and untick it, you will keep the v8
coordinates and get globe *shapes* at ring *positions*, which is the one case
where this update looks wrong — let Arrangement through and re-drag afterwards.

### Honest notes, including what is worse

- **No portraits.** Named above, because it is the real cost of putting the
  numbers where they belong.
- **The target's mana is gone.** v7 and v8 drew a third ring for it. The globe
  layout ships one target vessel and it reads health, so the "is this target
  worth Curse of Tongues / a felhunter" read is no longer on the PvE HUD. In
  arena it is still there and better — the per-opponent **Enemy Mana** bars in
  the PvP column give you a number per enemy instead of one ring for your current
  target.
- **The globes sit at fixed screen coordinates** — `x = ∓150` and `x = 0`, all
  three on the line `y = -262` — which is the same geometry every class pack in
  this repo used at v9, so a warlock and a mage sitting next to each other have
  their globes in exactly the same places. **(v10 moved them to `∓190` at
  `y = 40`, with the target at `(0, 110)` — same cross-pack contract, new
  numbers.)**
- **The target globe lands on the DoT row.** It is centred at `y = -262` and the
  DoT icons at `y = -156`, so the 44 px vessel sits on top of your Immolate /
  Corruption timers. That is a consequence of the shared cross-pack geometry, not
  of anything warlock-specific — every pack in the repo puts its centre row in
  the same place — so it will be fixed the same way everywhere. **(Fixed in v10:
  the target vessel is at `y = +110` and the DoT row is untouched at `y = -156`,
  so they no longer overlap.)**
- **A globe fills upward.** WeakAuras' orientation names lie about direction, and
  the opposite setting produces a globe that *drains from the top* as you take
  damage — which looks deliberate and is wrong. This one rises, like liquid.

## v8 — one orb size, shared by every class pack

**The orbs are now exactly the same size in all seven packs, and both orbs are
the same size as each other.** In v7 each class pack picked its own dimensions,
and inside this pack the player orb (96 px outer ring) was visibly smaller than
the target orb (128 px) — which is what read on screen as uneven. There is now
one canonical set of numbers, used verbatim by warlock, druid, hunter, mage,
paladin, priest and rogue alike:

| Ring | Diameter | Player orb | Target orb |
|---|---|---|---|
| Outer | **104** | health | threat |
| Mid | **78** | mana | health |
| Inner | **54** | — | mana |
| Portrait | **46** | face | face |

Both orbs therefore present the **same outer circle and the same face**; the
target simply nests one more ring inside it. The clusters sit at x = ∓260,
y = -60, and the readouts share one baseline on both sides — health 14 pt just
under the outer ring, mana 11 pt below it, threat 11 pt above the orb.

**The rings are drawn with WeakAuras' 20 px ring art instead of the 10 px one.**
At these diameters the 10 px annulus rendered as a hairline wire; the 20 px art
gives roughly an 8 px band, so a half-full arc is legible at a glance instead of
being something you have to look for. The 80%-threat halo follows the outer ring
down with it (140 → 116) and keeps the same 12 px stand-off it always had.

Nothing else changed: not one trigger, load gate, condition, colour, spell ID or
region type, and **no aura was added, removed or renamed**. All 44 UIDs are
byte-for-byte identical to v7, so the import dialog offers **Update** and the
pack upgrades in place. One thing to watch in the Update dialog: the new sizes
and offsets ride in the **Arrangement** category, so unticking that box (the way
you would to protect groups you dragged in game) keeps the v7 sizes and applies
only the new ring art — which is the one case where this update does nothing
useful. If you have dragged things, let Arrangement through and re-drag the top
group afterwards; every element inside the orbs is positioned relative to it.

## v7 — the middle of your screen is yours again

**The health / mana / threat bar stack is gone from under the crosshair.** In its
place, two **unit orbs** flank the character: a live 3D portrait with its
readouts drawn as concentric rings around it, the numbers underneath.

```
        ( mana )                                        ( mana )
      ( health  )            [DoT row]                ( health  )
    ( · portrait )         [cooldowns]            ( threat  ·   )
         83%                                           41%
         62%                                           100%
     PLAYER ORB                                     TARGET ORB
      (x = -260)                                     (x = +260)
```

Everything the bars told you is still there, in the same colours, so nothing has
to be relearned:

| Ring | Where | Colour language |
|---|---|---|
| **Health** | outer ring, both orbs | green → **amber at or below 60%** on your own orb — the health half of the Life Tap decision |
| **Mana** | inner ring, both orbs | blue → **violet below 30%** on your own orb — the mana half of the same decision |
| **Threat** | outermost ring, **target orb only** | green → **orange at 70%** → **red the moment you pull**, with the percentage above the orb and a pulsing red halo at 80%+ |

Every ring still dims to 50% out of combat, exactly as the bars did, and the
threat ring still loads **only in a party or raid and never inside an arena**.

**What you gain, because the layout made it free:** the *target's* health and
mana are now on screen too. A warlock reads both — target health is the Drain
Soul / Shadowburn window, and whether a target has a mana bar at all is what
decides if Curse of Tongues or a felhunter is worth spending. And each orb
carries a real portrait of the unit, so an accidental target swap is visible
without reading a name.

**The target orb disappears entirely when you have no target** — rings, portrait
and numbers — so the right-hand side of your screen is empty out of combat rather
than showing four zeroes. It is not a load gate or a condition; the health
trigger simply produces no state for a unit that does not exist. A target with no
mana pool (a warrior, a rogue, most trash mobs) shows no mana ring, rather than a
permanently empty blue circle.

### Nothing to delete after updating

The five auras that were the bar stack are **converted in place**, not replaced:
`Warlock - Health` and `Warlock - Mana` became the player orb's two rings,
`Warlock - Threat` became the target orb's threat ring, `Warlock - Threat Flash`
became the pulsing halo, and the `Warlock - Resources` group now holds the two
orb clusters instead of the three bars. They keep their UIDs, so the import
dialog offers **Update** and rewrites them where they stand — there are **no
orphaned bars left behind and nothing to clean up.** Six genuinely new auras
(the two cluster groups, the two portraits, and the target's health and mana
rings) are added below them, so all 38 of v6's UIDs are byte-for-byte stable.

Two things to know when you paste it:

- The Update dialog's **Arrangement** checkbox is ticked by default and will
  reset any group you dragged in game back to the string's coordinates. Untick
  it if you have moved things — but note that the Resources group's *children*
  are what moved this time, so the orbs will land in their new positions either
  way.
- If you import as a *copy* rather than an Update (a different account, or you
  clicked past the dialog), you will have both the old group and the new one.
  Delete the older `Warlock - Resources` group in that case.

### Honest notes, including what is worse

- **The numbers moved out of the bars.** The percentages used to sit on the right
  edge of each bar; they now sit under each orb on one shared baseline (health
  large, mana small beneath it, threat above the target orb in its own line so it
  never crowds them). Same numbers, one glance further from the crosshair — that
  is the trade the whole change is making.
- **The thin black bar borders are gone.** A ring has no border sub-region; the
  dark unfilled track behind each arc does that job instead.
- **The portraits do not dim out of combat.** The rings do. Whether a `model`
  region exposes alpha as a conditionable property could not be proved from the
  sources this repo verifies against, and this pack does not ship conditions that
  might silently do nothing — so the fade was applied to the rings, which carry
  every number and every colour, and the faces stay lit.
- **No resource breakpoint marks were lost, because there were none.** The v6
  warlock bars carried no tick marks at any threshold. If you ever want them:
  WeakAuras' bar-tick sub-region is *aurabar-only*, so a ring cannot use it, and
  the equivalent on a ring is a small static texture placed by hand at the right
  angle. That is a build-script change, not a setting.
- **The threat ring is guarded against a trap the bars did not have.** A bar with
  a zero total draws *empty*; a ring with a zero total draws **full**. Threat is
  exactly zero in the moment before your first cast lands and right after a
  Soulshatter, so an unguarded ring would slam to a complete circle — reading
  "you are at the pull threshold" — while its colour stayed green. The threat
  ring, and every other ring in the pack, hides itself at zero total instead.

## v6 — the cooldown row now shows what you *cannot* press

**An empty cooldown row means everything is available.** That is the whole
change, and it is the only thing you need to remember.

Until now the row worked the way the default action bar does: all seven icons on
screen at all times, greyed out while their spell was down. That is backwards.
You already know your own spellbook — what you cannot know is what is *missing*
right now and for how long, and the old row buried that answer in a strip that
was at its most crowded exactly when you had the fewest options.

So each icon now **exists only while its cooldown is running**, carrying its
sweep and its countdown, and **disappears the instant the spell is back**. The
row is a dynamic group, so the gap closes behind it:

- **Nothing in the row** → every cooldown you own is up. Nothing to check.
- **Two icons** → exactly two things are down, and both are counting themselves
  back for you.

The grey-while-down desaturation is gone with it. Under the new rule every icon
you can see is on cooldown by definition, so greying them all would just make
them harder to tell apart at a glance; they now show in full colour, which is
what makes a two-icon row readable in peripheral vision.

**No warlock cooldown got a "press it now" glow, and that is deliberate.** Other
packs in this repo keep a couple of icons permanently visible with a gold
ready-glow — a paladin's Judgement, a bear's Mangle — because those are pressed
the moment they come up, and a hidden icon cannot announce itself. The warlock
has none of those *in this row*. Your press-on-cooldown buttons are Shadow Bolt,
Incinerate and your DoTs, none of which has a cooldown at all, and all of which
are already rendered by the DoT row and the Alerts flow. Every spell in the row
is something you press when a *circumstance* calls for it:

| Icon | Why it is a "when you need it" button, not a "press on cooldown" one |
|---|---|
| **Conflagrate** | it **eats your Immolate**. TBC guides are explicit — do not fire it on cooldown or at the end of an Immolate; it is the answer to "I have to move and I do not need to Life Tap". A glow every 10 s would be an instruction to delete your own DoT. |
| **Shadowburn** | costs a Soul Shard *and* consumes your Improved Shadow Bolt charges, so on-cooldown use is a DPS loss. It is a movement filler, an execute, and a PvP burst button. |
| **Amplify Curse** | 3 minutes, and it only pays off on Curse of Agony or Doom — which in a raid you are usually not the one assigned to. |
| **Fel Domination** | 15 minutes. It is the pet emergency (and the resummon half of the re-sacrifice loop). |
| **Shadowfury** · **Howl of Terror** | crowd control, pressed at a moment you choose. |
| **Death Coil** | CC plus a self-heal — an emergency answer, not a rotation slot. |

Nothing else in the pack moved: same bars, same DoT timers, same alerts, same
PvP layer, same load gates (including the arena/battleground gate on Howl of
Terror). No aura was added, removed or renamed, so all 38 UIDs are unchanged and
a v5 import offers **Update**.

## v5 — CC in colour, no threat bar in the arena, enemy mana

Three things that had been left as "not verified, so not built" were verified at
the source and are now shipped. One new aura, one prompt taught to say more, and
one piece of raid furniture told to stay out of the arena. Nothing else moved:
every one of v4's 37 UIDs is unchanged, so this is an Update, not a re-import.

- **CC ON ME is now colour-coded by what is holding you.** The prompt used to be
  red for everything, which told you *that* you were controlled and left the
  *which break works* question to your memory — inside a 3-second stun, that is
  the wrong place to keep it. The glow now carries the category, because under CC
  a player parses colour and never text:

  | Colour | What has you | What you do |
  |---|---|---|
  | **Red** | stun | the trinket is the only answer — nothing else breaks a stun |
  | **Purple** | fear | trinket, or Death Coil, or Will of the Forsaken if you are undead |
  | **Blue** | root | a movement answer, **not** the trinket — never spend a 2-minute break on a snare you can walk out of, or Fear the melee off you instead |
  | **Green** | polymorph / confuse | ride it. Any damage breaks it, so your DoTs or a partner's cleave will pop it before the trinket would |
  | **Amber** | silence or school lockout | your Shadow school is gone, which means your **Fear** went with your damage — trinket *earlier* than you otherwise would, because waiting it out leaves you with no escape either |

  The countdown under the icon is unchanged and still answers "ride it or spend
  it". These are exactly the mage pack's colours, deliberately: if you play both,
  you learn the language once. Anything the client reports outside those five
  categories (charm, possess, disarm) stays the default red — "trinket food".

- **The threat bar and its red flash no longer load in an arena.** An arena has
  no threat table, so a threat bar there was a permanently meaningless strip
  sitting in the middle of your HUD. It now loads everywhere else exactly as
  before — open world, 5-mans, Karazhan, the 25s, and battlegrounds (Alterac
  Valley has real NPC bosses with a real threat table, so a BG threat bar still
  earns its place). **No PvE behaviour changed at all.** WeakAuras has no "not
  arena" load option, so the list is spelled out the long way; the value that
  mattered was the open world, where the client reports the instance size as the
  literal string `none` rather than nothing at all, so the bar keeps loading in
  Hellfire.

- **New: Enemy Mana** (arena only, one bar per opponent). v4 listed enemy healer
  mana under "deliberately not built" because the arena-unit power read was
  unverified. **It is now verified and built.** Each mana-using opponent gets a
  120×12 bar in the PvP column with their name on the left and their mana
  percentage on the right; the bar turns **gold below 30%**, which is the moment
  your drain plan has won and you should stop switching and finish it. Rogues and
  warriors do not appear at all — the row only exists while mana is that
  opponent's primary bar, so the column never fills with energy bars you cannot
  drain. This is the readout Drain Mana, Curse of Tongues and a felhunter parked
  on the healer were always missing: without it you drain on faith and swap on a
  guess. One honest caveat: how often the 2.5.x server pushes power updates for
  arena units is a client question no addon can settle, so treat the number as a
  live trend rather than a to-the-point kill calculation — WeakAuras re-reads
  each opponent whenever the arena frames change, so the worst case is a coarser
  refresh, never a wrong number.

## v4 — PvP layer

Nine new auras that load **only inside an arena or a battleground**. Every one of
them carries its own "Instance Size Type" load gate, so **nothing about the PvE
HUD changes**: in a raid, a dungeon, a group or the open world the pack is
byte-for-byte the v3 experience — same bars, same DoT row, same alerts, same
cooldown row, no new icons, no new triggers running. Nothing was removed,
renamed or moved either, so a v3 import offers Update and all 26 old UIDs are
stable.

Five of them need arena specifically (they read `arena1`–`arena5`, unit
ids that do not exist in a battleground — a battleground-loaded arena element is
a permanently blank slot); the rest load in battlegrounds too.

**This is not diminishing-returns tracking, and the pack never pretends it is.**
DR does not exist anywhere in WeakAuras — no prototype, no bundled library — and
the tempting fake (an 18-second "DR" timer on the target) models the *reset*
window rather than the category state, so it is wrong the moment two of your
spells share a category. What you get instead is the honest half: the CC that is
actually running right now, on which opponent, with its real remaining time. You
still count your own fears.

**New group: `Warlock - PvP`** (right of the character, growing down) — the
state column, mirroring the Alerts flow on the other side. It holds six of the
new auras and is empty whenever nothing needs doing.

- **Fear Out** (purple, one row per opponent, arena) — your own Fear, Howl of
  Terror, Seduction or Death Coil on that unit, with the seconds left. This is
  the layer's most-pressed element: your own DoTs break your own Fear, so for
  the first three it is a live *do not press that button, and do not re-apply
  Corruption on that unit* timer. Death Coil shares the row for the other half
  of the same decision — its Horror does **not** break on damage and it is a
  separate DR category, so Fear → Death Coil is the standard extension and the
  icon tells you which of the two you are in. All ranks; `ownOnly`, so your
  succubus' Seduction counts and another warlock's fear does not.
- **Spell Lock ON** (gold, one row per opponent, arena) — the felhunter's
  silence is running on that unit: this is the go. Read from the silence debuff
  itself (both Spell Lock ranks trigger the same aura, 24259), so the countdown
  is the game's own number rather than a guessed lockout length. It is the
  silence portion only — the school-lockout half of an interrupt is not an aura
  and cannot be read on TBC.
- **Fear Ward UP** (red, one row per opponent, arena) — that opponent is immune
  to your next fear. Open with Death Coil or Howl, or bait the ward first. Every
  priest has carried Fear Ward since 2.3, and this is the difference between a
  working go and a wasted one.
- **Enemy Trinket** (arena) — a 2-minute countdown that starts when an opponent
  uses their PvP trinket, one per opponent. While it runs, your fear chain
  actually sticks. Honest caveat: no API on 2.5.x reads another player's
  cooldowns, so this is an **inference from the cast you saw** — if someone
  trinkets while their unit is not tracked, nothing starts, and the row is
  silent rather than wrong.
- **Trinket DOWN** — your own medallion/insignia, shown *only while it is on
  cooldown* and desaturated, so an empty slot means "you still have your break".
  Six item IDs are watched (warlock Medallion of the Horde/Alliance, the
  race-wide Medallions, and the old warlock Insignias); the equipment-slot
  trigger was deliberately not used, because it reports whatever sits in the
  slot and would call your medallion down while a PvE on-use trinket ticks.
- **Will of the Forsaken DOWN** — same readout for the undead racial, and it
  loads only if you know it. On 2.4.3 WotF does not share a cooldown with the
  medallion, so an undead warlock has two breaks and this decides whether to
  spend the first one.

**Two new prompts in the Alerts flow** (44×44, they slide in like every other
prompt):

- **CC ON ME** (red, with a countdown; v5 colour-codes it by category — see the
  v5 section above) — you are stunned, feared, rooted,
  silenced or school-locked, and the icon *is* the identity of the effect: stun
  means the trinket is the only answer, fear means trinket / Death Coil / Will
  of the Forsaken, a root means do **not** burn the trinket, and a Shadow-school
  lockout means your Fear is gone too, not just your damage. The countdown is
  the "ride it or spend it" half. Not combat-gated: the opener lands on you out
  of combat. Caveat: this reads the client's loss-of-control API; if your client
  does not populate it the prompt simply never fires (it cannot show anything
  wrong).
- **TARGET IMMUNE** (red, with a countdown) — your kill target just became
  immune: Divine Shield, Divine Protection, Ice Block or Cloak of Shadows. Stop
  casting, stop re-applying DoTs into a 90% resist, swap or wait it out.
  Blessing of Protection is deliberately *not* in that list — it is physical-only
  and your shadow damage goes straight through it, so prompting on it would stop
  a burst that was working.

**Howl of Terror joins the cooldown row** in arena and battlegrounds only — a
40-second AoE fear is a PvP button, and it would be noise in a raid.

Deliberately **not** built, and why: an interrupt prompt (Spell Lock is a pet
cast, and "can the pet cast it right now" is not a verified readout), enemy
health frames and an enemy-cooldown wall (Gladius owns the first, nobody reads
twenty icons inside a stun), enemy healer mana (the arena-unit power read was
unverified at the time — it has since been verified, and **v5 ships it**), enemy
spec detection (impossible on TBC — every element here says
"each opponent" or "my target", never "the healer"), and diminishing returns
(see above). Soul Link uptime and the Unstable Affliction timer already exist in
the PvE HUD and are exactly right for arena, so they are not duplicated here.

**Live acceptance note:** `CC ON ME` uses WeakAuras' source-verified Crowd Controlled
prototype, but addon source cannot prove that the 2.5.x client populates the underlying
loss-of-control API. Get sapped and school-locked in a duel once before relying on it; the
repo suite verifies its schema and gates, not live client events. The Enemy Mana row's source
shape is likewise verified, while its 2.5.x arena-unit refresh cadence still merits one match.

## v3 — per-spec load audit

v3 asked one question of every element, for every spec that loads it: *does this
change which button that spec presses next?* — the test being "does this spec
**press** it", not "can this spec **cast** it". One element failed, for one spec.

- **Demonic Sacrifice MISSING no longer loads for Felguard Demonology.** In every
  Felguard build, Demonic Sacrifice is a 1-point prerequisite tax on the way down
  to Soul Link: the talent is known, and the button must never be pressed —
  burning the demon deletes Soul Link, Demonic Knowledge, Demonic Tactics and
  Master Demonologist in one keystroke. v2 knew this and used a live "Soul Link
  buff absent" trigger to suppress the prompt, but that discriminator inverts at
  exactly the wrong moment: **when the Felguard dies, the Soul Link buff drops
  too**, so the prompt fired and told a Demonology warlock to sacrifice the pet
  their entire spec is built on, in the middle of the emergency. It is now an
  inverse load gate — `not_spellknown = 19028` (Soul Link) — so a Soul Link build
  never loads the aura at all, in any state. A 0/21/40 SM-Ruin lock reaches
  Demonic Sacrifice but not Soul Link, so nothing changes for them.
  The v2 trigger is deliberately left in place as the fallback for older clients
  (see the WeakAuras 5.4.0 note below).
- **Nothing else changed.** No aura was added, removed, renamed or reordered, and
  all 26 UIDs are byte-for-byte stable, so re-importing offers Update.

### Requires WeakAuras 5.4.0+ (degrades gracefully below it)

The `not_spellknown` load argument does not exist before WeakAuras 5.4.0. On an
older client the unknown field is simply ignored, the Demonic Sacrifice prompt
loads for every warlock with the talent again, and the v2 "Soul Link buff absent"
trigger goes back to being the discriminator — i.e. exactly v2's behaviour, with
no error and no missing aura.

### Audited and deliberately kept

The three ungated DoT timers were the main suspects going in — Corruption, your
curse and Immolate load for all three specs — and all three survived the audit
against the current guides:

- **Corruption is in every spec's priority list.** Affliction and Demonology
  maintain it all fight; Icy Veins' Destruction list (both the Fire and the
  Shadow variant) carries "Corruption on pull". A destro lock still needs to see
  whether it is up.
- **Immolate is in every spec's priority list too, conditionally.** It is core to
  both Destruction builds; Demonology casts it "if you are not wearing a lot of
  Shadow damage gear or if you have a Fire Mage"; Affliction casts it "if you
  have Improved Scorch from a Fire Mage" — a common TBC raid setup. Gating it off
  Affliction would leave an Affliction lock in a raid with a Fire Mage running a
  DoT with no timer, which is a worse failure than one extra icon, so it stays.
- **Death Coil stays in all three cooldown rows.** It is not a rotation button in
  any spec, but it is the warlock's emergency button — a 30% self-heal plus a 3s
  horror to peel something off you — and all three specs press it under pressure.
- **Curse, Life Tap, the health/mana bars and the threat bar and its flash stay
  ungated.** Every spec maintains a curse, every spec Life Taps (the health and
  mana bars are the two halves of that decision), and warlock threat is dangerous
  in all three specs.

Everything else was already gated on the ability or talent that produces it, and
the deep gates hold up: a 0/21/40 destro build has only 40 Destruction points, so
it never loads Shadowfury (a 41-point talent), and Fel Domination loads for both
Demonology (instant Felguard resummon) and destro-sac (the resummon half of the
re-sacrifice loop) because both genuinely press it.

## v2 — rotation fixes

An adversarial rotation review judged the pack against one standard: every
element must change which button you press next, and anything that does not gets
cut. What changed:

- **Demonic Sacrifice MISSING (new).** The 0/21/40 SM-Ruin Destruction loop
  begins "Fel Armor → Demonic Sacrifice your Succubus (Imp if fire)", and the
  buff dies with you and with any resummon. v1 tracked none of it, which also
  left the Fel Domination cooldown icon pointing at nothing: the resummon +
  re-sacrifice cycle is the only reason a Destruction lock presses it. The
  prompt watches all five sacrifice buffs (18789 Burning Wish / 18790 Fel
  Stamina / 18791 Touch of Shadow / 18792 Fel Energy / 35701 the Felguard
  variant) and fires when none is up in combat.
- **Fel Armor MISSING (new).** Priority line 1 of every spec's guide, lost on
  death, tracked nowhere in v1. Both ranks (28176/28189), combat-gated. It asks
  for Fel Armor specifically, as every PvE guide does — if you deliberately run
  Demon Armor instead, disable this one aura in `/wa`.
- **Soulshatter moved from 70% threat to 90%.** `threatpct` is scaled so 100 =
  pulling aggro, and a competent TBC caster rides well above 70 for most of a
  fight — so the old prompt was lit, glowing and sliding for a large fraction of
  every encounter. A 5-minute, one-shard, 8%-of-base-health button belongs at
  the "about to pull" tier, not the "doing your job" tier.
- **Threat bar is party/raid-only and fades out of combat.** Solo you are always
  the tank on your own target, so v1's bar sat permanently full and red while
  levelling. Its own flash overlay already had the `ingroup` gate; the bar now
  matches it, and it dims to 50% out of combat like the health and mana bars.
- **Health bar flips amber at 60%.** Life Tap needs two inputs — mana under 30%
  *and* health over 60% — and v1 only drew the mana half of that line.
- **Refresh glow is 1.5s, not 2s, and the dead glow layers are gone.** Immolate
  is a 1.5s cast with Bane 5/5 — which every Destruction build, i.e. every build
  that actually maintains it, takes — and Unstable Affliction is 1.5s base, so a
  2s cue trained a half-second clip in an expansion with no pandemic window. Corruption, your curse and Siphon Life are
  instant recasts whose only correct cue is the icon vanishing — in v1 they each
  carried a glow layer no condition could ever switch on, so that dead config
  was removed rather than wired up.
- **Curse slot also feeds on Curse of Recklessness and Curse of Tongues** (all
  ranks). v1 covered only Agony/Doom/Elements/Shadow, so a dungeon or PvP
  assignment produced no timer at all.
- **`spellknown` gates added to Death Coil, Shadow Trance and Backlash.** Death
  Coil is trained at 42 and its icon used to render, permanently ready, for
  warlocks who could not cast it; the two proc prompts loaded for every warlock
  and simply never fired.

Deliberately **not** built in v2, because they are design decisions rather than
defects — say the word if you want any of them: an AoE suite (Seed of Corruption
timer plus Rain of Fire / Hellfire awareness), a pet health bar for the Health
Funnel / Drain Life call, a soul shard counter, item-cooldown icons for Flame
Cap and Soulstone (the 30-minute Soulstone cooldown lives on the *item*, not on
a player spell, so a spell-cooldown trigger would track nothing), and a
Conflagrate interlock that visually separates it from the use-on-cooldown icons
it shares a row with.

## Groups

**Resources** (The Sill) — since v14 this group holds a single instrument strip,
yours, directly under the character at `(0, -110)`; since v17 it is **164 × 36 px**:
three stacked **160 px rails** — threat 5 px tall, health 13 px, power 13 px — on a
dark bordered plate, with a 4 px red rim pulsing around the outside at 80% threat.
**1.6 pixels is one percent**, and 160 is not a round number for a reason: every
value this pack marks is a multiple of five and 1.6 × 5 = 8, so every breakpoint
still lands on a whole pixel (`x = (v/100 − 0.5) × 160`). The lane offsets are
shared byte-for-byte by every class pack in this repo, so the strip reads
identically on every character you play, and `(0, -110)` is a contract rather than
a taste call: it is the widest-margin position in the band all seven packs keep
clear between the paladin/hunter buff rows at `y -80..-40` and everyone else's at
`y -176..-136`. The build asserts a full rectangle scan of the strip against every
other element in the pack with each dynamic group projected six children deep — and
it scans the **172 × 44 alarm envelope**, not the plate, because that is the largest
thing the strip ever draws: 0 overlaps, tightest clearance **7 px**, to this pack's
own DoT row. Since v17 it also runs an **all-pairs scan across all five layout
stacks**, which is what caught the PvP column sitting on top of the cooldown row.
Health is green, **amber at or below 60%**; power is blue,
**violet below 30%** — those two colours are the two halves of the Life Tap
decision, and on two parallel rails sharing one origin and one scale that decision
is a single comparison. **Threat is the top rail** (green, orange at 70%, red the
moment you pull, with a permanent **2 px notch at the 70% line** — x +32 on the
160 px rail — so you can see the threshold coming, plus a 4 px red band pulsing
around the outside of the strip at 80%+ — a rim *around* the instrument, drawn
underneath it, so no readout is ever covered). It loads only
in a party or raid **and never inside an arena** (there is no threat table there)
and hides itself at zero threat, so solo the strip is a plate and two rails. **Each
percentage is printed inside its own rail**, 12 pt at x +51, on the
plate — which is the actual answer to "the percentage can't be seen": the numbers
were never too small, they were painted on the game world. Each 13 px rail also
carries a **quarter ruler**, three 2 px hairlines at 25 / 50 / 75%, which land on
x ∓40 and 0. Everything dims
to 50% opacity out of combat. The strip is draggable in `/wa` as
`Warlock - Player Sill` if those coordinates do not suit your resolution — but see
[After updating](#after-updating) first, because the update dialog's `Arrangement`
category will reset a drag. The **live 3D portrait and the on-screen threat number
are gone** (v14); the threat number is switched off rather than deleted and is one
checkbox away. There is deliberately **no target cluster**: the target's health is
already on your target frame and its nameplate (see v12 above), and if you are
updating from v11 the leftover `Warlock - Target Orb` group has to be deleted by
hand.

**DoTs** (center row, five 40×40 icon timers) — your own debuffs on the current
target only, with the time left under each icon: Corruption (x=-88) and your
curse (x=-44) for every spec, Immolate (x=0) for the Demonology/Destruction fire
rotations, Unstable Affliction (x=44) and Siphon Life (x=88) for Affliction. The
curse slot is one icon fed by twenty-three rank IDs across six chains — Curse of
Agony, Doom, the Elements, Shadow, Recklessness and Tongues — because a target
can only carry one of your curses, so whichever one you are assigned lights the
same slot. An icon exists only while the DoT is actually up, so a gap in the row
is the "recast it" signal. Corruption, the curse and Siphon Life are instant, so
the gap is their *whole* signal and they carry no glow; Immolate and Unstable
Affliction glow at 1.5 seconds remaining, one cast time out, so the refresh
lands exactly as the old tick falls off. Never clip, never let one drop.

**Alerts** (left of the character, growing upward) — glowing 40×40 prompts that
slide in from the bottom and fly off when handled; appearance itself is the
signal. Seven prompts: Shadow Trance (purple, the Nightfall proc — cast the free
instant Shadow Bolt, with the 10s window counting down), Backlash (orange, the
Destruction proc — free instant Shadow Bolt/Incinerate, 8s window), Life Tap
(blue: mana below 30% **and** health above 60%, in combat only — the exact window
where tapping is free value), Soulshatter (orange: threat at 90%+ **and**
Soulshatter off cooldown, party/raid only), and three red "you lost a buff"
prompts, all combat-gated: Soul Link MISSING (Soul Link dropped, which almost
always means your pet died, so resummon and recast it), Fel Armor MISSING, and
Demonic Sacrifice MISSING. The two threshold prompts require the ability to
actually be ready, so they never nag uselessly. Inside an arena or battleground
the same flow gains two slightly larger 44×44 prompts, CC ON ME and TARGET
IMMUNE (see the v4 section); in PvE it is the same seven prompts as v3.

The Demonic Sacrifice prompt is the one aura in the pack with two load gates: it
needs Demonic Sacrifice known (18788) **and** Soul Link *not* known (19028). Every
Felguard build spends a point on Demonic Sacrifice purely to reach Soul Link
further down the tree and then never presses it, so "knows Soul Link" is an exact
"keeps its demon" test — a Demonology warlock never loads this prompt. A 0/21/40
Destruction lock has the points for Demonic Sacrifice but not for Soul Link, so
they always see it. The aura still carries its v2 second trigger, "Soul Link buff
absent", which is now only the fallback on clients older than WeakAuras 5.4.0.

**Cooldowns** (center, below the DoT row) — a horizontal row of 32×32 icons with
cooldown text and mouseover tooltips, showing **only the spells that are
currently down** (v6). An icon appears when you press the spell, counts itself
back in full colour, and vanishes the moment the spell is ready again; the row
collapses the gap, so **an empty row means everything is available** and two
icons mean exactly two things are not. It also collapses the gaps left by icons
your spec does not load. Amplify Curse (Affliction), Fel Domination
(Demonology), and Conflagrate, Shadowburn and Shadowfury (Destruction) appear
only when the talent is known; Death Coil is baseline for all three specs but is
gated on its own rank-1 ID so it stays hidden until it is trained at level 42.
There is deliberately no timer text on these icons — the swipe (plus OmniCC, if
you run it) already provides the number. Nothing here glows: not one of these
seven is a press-on-cooldown button (Conflagrate and Shadowburn least of all —
Conflagrate consumes your Immolate and Shadowburn burns a shard and your
Improved Shadow Bolt charges, so both are movement/burst answers rather than
rotation slots), and the v6 section above has the per-icon reasoning. Howl of
Terror joins this row inside an arena or battleground only.

**PvP** (right of the character at `x = +190` since v17, growing down,
arena/battleground only) — the
v4 state column described above: Trinket DOWN and Will of the Forsaken DOWN
(your own breaks, shown only while unavailable), and three per-opponent clone
rows — Fear Out, Spell Lock ON and Fear Ward UP — plus the Enemy Trinket
countdown, and below them the v5 **Enemy Mana** bars, one per mana-using
opponent, gold below 30%. It is a dynamic group because those rows spawn one copy
per arena opponent. Everything in it except the mana bars collapses to nothing the
moment nothing is running; the mana bars are a standing readout for as long as
there is a caster across from you, which is exactly as long as the drain decision
is live.

## Spec gating

| Element | Loads when known |
|---|---|
| Unstable Affliction timer | 30108 (Affliction 41-point signature) |
| Siphon Life timer | 18265 (Affliction talent) |
| Shadow Trance alert | 18094 (Nightfall, Affliction talent) |
| Backlash alert | 34935 (Backlash, Destruction talent) |
| Soul Link MISSING alert | 19028 (Demonology talent) |
| Demonic Sacrifice MISSING alert | 18788 (Demonology talent) **and NOT** 19028 (Soul Link) |
| Fel Armor MISSING alert | 28176 (trained at 62) |
| Amplify Curse cooldown | 18288 (Affliction talent) |
| Fel Domination cooldown | 18708 (Demonology talent) |
| Conflagrate cooldown | 17962 (Destruction talent) |
| Shadowburn cooldown | 17877 (Destruction talent) |
| Shadowfury cooldown | 30283 (Destruction 41-point) |
| Death Coil cooldown | 6789 (trained at 42) |
| Soulshatter alert | 29858 (trained TBC spell; party/raid only) |
| Howl of Terror cooldown | 5484 (trained at 40) **and** arena/battleground |
| Will of the Forsaken DOWN | 7744 (undead racial) **and** arena/battleground |

Everything else is baseline warlock and always loads (class-gated to WARLOCK).
The threat rail, its 80% alarm and the Soulshatter prompt additionally require
a party or raid — solo, pulling aggro is the plan — and since v5 the rail and its
frame also refuse to load in an arena. Life Tap and all three "MISSING" prompts
are combat-gated, so nothing nags you between pulls.

The PvP auras are gated on instance type instead of (or as well as) a talent, and
each one carries its own gate — a group's load is not a child gate:

| Element | Loads in |
|---|---|
| CC ON ME, TARGET IMMUNE, Trinket DOWN, Howl of Terror | arena **or** battleground |
| Will of the Forsaken DOWN | arena or battleground, if you know 7744 |
| Fear Out, Spell Lock ON, Fear Ward UP, Enemy Trinket, Enemy Mana | arena only |
| Threat rail, Threat Flash (the 80% alarm) | everywhere **except** arena (and still party/raid only) |

The arena-only five read `arena1`–`arena5`; those unit ids do not exist in a
battleground, so loading them there would only ever produce blank slots. The
threat pair is the mirror image — WeakAuras has no "not arena" load key, so their
gate lists every other instance type explicitly, including the open world (which
the client reports as the literal size `none`).

## Regenerating

```bash
cd tools/tbc-weakaura-creator/scripts && ./setup.sh   # once per machine
lua5.1 tbc/warlock/generate.lua                       # rewrites all-specs.txt
```

The build is fully deterministic (fixed seed `20260813`): re-running produces a
byte-identical string. When editing, never remove or reorder existing `W.uid()`
call sites — append new auras after all existing ones — so re-imports show
"Update" instead of duplicating. (That is exactly how v2's two new prompts were
added: they are built at the bottom of the script and re-parented into the
Alerts group, so all 24 v1 auras kept their UIDs — and how v4's nine PvP auras
and their group were added below those, leaving all 26 v3 UIDs stable, and how
v5's single Enemy Mana bar was added below all of them, leaving all 37 v4 UIDs
stable. v6 added no aura at all — it changed one trigger field and dropped one
condition on seven existing cooldown icons — so every UID is untouched. v7 is the
first version to *repurpose* auras rather than only add them: the five bar-stack
auras keep their `W.uid()` call sites, and therefore their UIDs, while their
region type, geometry and parent all change, and v7's six new auras are built at
the very bottom below every earlier call — which is what makes the bar-to-orb
move an Update with no orphans instead of a delete-and-re-add. v8 touches no
call site at all: it is a pure geometry and texture pass over the orb regions,
so all 44 v7 UIDs are byte-for-byte identical. v9 touches no call site either,
and it is the strongest form of the v7 trick: **every one of the eleven orb auras
is recycled**, including the two portraits, whose UIDs now carry the life and
mana globe rims — a portrait that was simply deleted would be left stranded in
your WeakAuras with nothing to update it, so the region type changes underneath a
UID that never moves. v10 is the mildest of all of them: it moves two group
offsets and appends one sub-region to each of the three globes, so not one aura
and not one `W.uid()` call site is touched and all 44 v9 UIDs are identical.
(That sub-region is *appended*, never inserted, which is the rule this pack lives
by: conditions address sub-regions positionally as `sub.N`, so inserting one
ahead of a referenced index silently retargets that condition at the wrong
sub-region.) v11 is the v9 trick run in reverse and it touches no call site
either: all ten cluster auras are recycled again — the two player globes become
the player's two rings, the threat rim becomes the threat *ring*, the two globe
rims become the two portraits (which is the very identity their UIDs carried in
v7/v8), the target globe becomes the target's inner ring, and the brass target
rim becomes the target's outer track — so all 44 v10 UIDs are byte-for-byte
identical and the v10 specular highlights are dropped rather than left behind.
v12 is the first version that **removes** auras rather than recycling them, and
it is allowed to only because of *where* they sat: the four target-cluster
regions were the last four `W.uid()` calls in the script, so deleting the tail
reshuffles nothing and all 39 surviving child UIDs are byte-for-byte v11's.
Removing a call site from the **middle** is still not an option — it would
reshuffle every UID after it — and every removal has to be declared to the
verifier one ID at a time with a `-- WA-REMOVED (v12): <id>` line, which is the
licence for that UID to disappear and which expires automatically at the next
version bump. An undeclared disappearance, or any existing ID that changes UID,
still fails the build. v13 touches no call site either — it moves two text offsets
and re-orders the cluster's `controlledChildren`, and `adopt` order is not `uid()`
order. v14 is the v9/v11 re-type trick run one final time and it likewise touches
no call site: all six cluster auras are recycled where they stand — the three rings
become the three rails, the **portrait becomes the Sill Plate** (`model` →
`texture`), the flash halo becomes the 108 × 37 alarm rim and the group is renamed
— so all 39 v13 UIDs are byte-for-byte stable and `W.assertUidContinuity` runs with
no allowance list. Renaming, re-typing and **re-ordering `controlledChildren`** are
all free — `adopt` order is not `uid()` order, which is what lets the alarm move
from last child to first without touching a single UID; only the call **order** is
sacred.) The script checks UID
continuity against the previous `all-specs.txt` automatically before overwriting
it (expect `changed=0 missing=0`; for v12 alone, `missing=4` naming exactly those
four). One more re-import caveat, and v14 inverts it: the Update dialog's
**Arrangement** checkbox is checked by default and normally resets any positions
you dragged in game back to the string's defaults — but **for v14 you must leave
it checked**, because the whole change travels in that category (see
[After updating](#after-updating)). Report your coordinates if you want them baked
into the script instead.

The post-build assertions in `generate.lua` are the **rail canon** (they were the
ring canon in v11–v13, and they were rewritten rather than deleted): the walked
parent chain resolving to absolute `(0, -110)`, the lane stack fitting inside the
plate, `orientation == "HORIZONTAL"` with `width == 100` and
`width ~= height` on every rail, no surviving `CLOCKWISE` region or `Ring_20px`
texture anywhere in the pack, exact sub-region counts and types, explicit colours
on both texture regions, the **alarm rim pinned as a size *and* a draw index
together** (`alarm.width == plate.width + 6`, `alarm.height == plate.height + 6`,
same centre, `controlledChildren[1]` the alarm and `[2]` the plate, with the flat
`c` list agreeing depth-first), and the full rectangle scan — of the alarm
envelope, not the plate — with dynamic groups projected six deep. They exist
because a geometry change that ships wrong still imports, still round-trips and
still verifies: a same-size alarm on top of the stack is a perfectly valid string
that floods every readout in red.

**They now pin values, not only wiring.** The first cut of the rail canon contained
assertions that could not fail, because each was phrased in the same symbol that
produced the value it checked — `assert(PLAYER_GY == SILL_Y - TOP_Y - RES_Y)` where
`PLAYER_GY` *is* that expression, and `assertAt(id, SILL_X, SILL_Y + lane)` where
`SILL_Y` proves `SILL_Y`. Those forms pin the *wiring* (the group offset is derived,
each lane offset is typed once) and are kept for it, but they pin no number: with
them alone, editing `SILL_Y` to `-21`, `PLATE_H` to `37`, `LANE_THREAT` to `14`
(which makes the threat and health rails **overlap** by half a pixel) or `RULER_W`
to `3` each rebuilt clean and shipped the wrong instrument inside a perfectly valid
string. Every number the design fixes is therefore written a second time as a bare
literal in a **contract** block, and the build constants *and* the decoded string
are both checked against it — plus four checks that come from the geometry itself
and catch even a two-place edit: the strip must land inside the free band
`y -136 .. -80` (a pack-local overlap scan cannot see this — `-21` collides with
nothing in the warlock pack and is still wrong), the three lanes must not overlap
each other and must sit exactly 1 px apart, the plate's margins must be exactly
1 px above and 2 px below, and the ruler must stay under 3% of the rail in ink.
Two more holes closed with them: the silent-no-op guard covered only the **threat**
rail, so health and power could have shipped their escalation on `barColor` or
`color` — dead, with no error anywhere — and there was no check that the three
lanes did not overlap one another, only that they fitted on the plate. The
no-op guard is now a census of **every condition on every aura in the pack**
against its own region type's colour setter, and health and power now carry the
same "escalation on `foregroundColor`, zero guard **last**" proof the threat rail
had. None of this changes the shipped string: v14's `all-specs.txt` is
byte-identical before and after (`sha256 59703af5…6721600`, 9,164 chars).

## Import string (v18)

```
!WA:2!TZ3E0nYv99NzD2KnAtGD9(iB2WdHd7s8MKnsJLSLtZdKKLwlV2sAhjBVo7s0msAKMXE0mZoZiBRTHTjMqWaHZbmNMFTP0tPgiLYjfkUTuE3GlqFa90V1aPt7HdpC5qdLd009)akT)Upg9Yw2AxVB2SBo9p84r3xZ9E)(57R7979YmwN5(WVL5FJRKvi3u5n00dRPOzmuhD0rYo8Cu)6DMtt1YqtrrmFyjzL8gIQhuFFJlyOOLBk33J7KkcvenCNswrz1SAg5fnc50q67kKI8zpRGrE3P10uSK1nMnrHcMIwmz1fqTJL(TwTDshkmQTcQO4oLUyoZS0wsYOcTcNzrdXIYAQPROlYv0qRS(I0sKs(SIBFjz1cAgLeSqLW1s0mOJcggMowrOSLKMrcDC2MUYIgpfKl6YqihjHE5mTemSCLTGSQSPKRqO)z5Aold5IffnmJFydNxF6qw4VUqzdb2LXpn1fvuKZBEWo9eQmQsz1jtfZrspwEtxRAwoR40OXzQYfkip7szchmv6mPshKlDTSsAiIYIlvYidp85lBkgzwu)kfTf45ufkjA6AX8IzrTaEWBmyKHtgD0HxOSQt3Y1s5LnNSSkA0mTiRGII(UfiVNMM)iA5fFURZz6ks(II67o1zkJM(DhTmA6ECjzlXLP5sNRVPfeuLPtM9c7j6YIcMIPSqKRIws3iCGqQAQIRKhn(XLidEoXWuenPM3CoCrX9s4EdvsqwnkCuufG7f8aEbw0)37AtzbtrLcj1KvTYgos80r46soV(EQdU4en1kBKt088OIiAOkOmg6RH(UNAPcgO5gu)sWsOJZlOMdrIJItc)9ZMkmxKiXx0sl300YVJK7JTSC(LowVNXkRruUXg94CM5eue7yreLGJaUmRIDIPIMg6yr8ysMcAcPOjK31s0pdP)c(N)ncm1ytGT9W67VE)oTKHOGL7OkcMs67TE6yUemhJLO(UwBPRZmuJPAqrbflPwWTnIGQaC9W2HBGbUrOx4MKaxphdSt4MHBz7WRXf8AjqFyxUGD7c6erhDb71fSpxW(JFy4wFAen42GdIaUWTdVo417cEdWBeCdVjOlE4oCbVz4qWHDbVf4oHUFURdocCxWDFtW9GHdRLK2t7jYGpWpIUcDa9Dkiqhq)W9b)giccC)lforIsYjlynUrC4b7aEixWBTdiOliKlimAg2nAW1X5TeN1QSH44gc6yWS(EdpCWrsMorOHdg(4bhyGyPJnwe6a7RJ(U3oEWScIvkJfDEnNf)I0xhfZLI42lkAHgMRwVm4m4xOw57kGh0KIEN1siJgcLlyPz01d(aCe(w9D5qJtjBvMWkqM)wZm3RXfxoQ4umkXl9X175Ob8JinzljByOzGiD3iStdNrjIETqwfr184HklA0HNoA9mFb4az1neryvYVrzpXIck6scjlRykoxvw0o9sQY6il67gj4iNHOLygdnlsrzAcQmMEWyyUUcc5epDW85tOAE6XffMkiw23PhrmVSWPtt71MNMktjdrCsMqe2OJAvuGsOP0DhyWaiqlhPF2bsWMPGfUFkknx9oX9Vu6HoH5OtLxzKEMMaxqGHSsIYfLSMilPCIsqONCbmbmhIhZKFj8RYQevd8ZH)HjsZGeIyJMlT2pxPYi9pUmCkX(bPdd3mFidbzKqwslC4SMOmvengpi3WjcFCqA)qj(qiz55qL2viCZHEzAoKMlRk8S6tJ(oiTowvkjOYZAjQIazZG(wvkGK9YNL(opCV8CZiN3s6R6IIMHHGJd7)rCycjyvGllLr3HzK09Xku4jqQA8Jnxh99IbTUdljG1KjAiBAjNZSk)8SRPUnGiH0yzdyuOpmkegLcaHXWIkgNl0WrIJaDh5WC5KeZnvu4w3(CtlyilGqLZjRgwRuwblUPfuklY0LMExpWdyKtsqTOO5bpmCoIWW50nW8lwva0483e1cDap6cLeMvIokpxNEWv8(Fa43cxfg4XGhzRlC50Rb0cVTwG5IGfu(iDazKaEm(Q8jIgFKJFgKcBFvXxq2yqoeQAmippuetZHPomOaLOibqLKKg550d4A(7llImzKPcd9)ZYG(eljKFYYMwI5hry2Tv)hYQBdCDh4pI(ERJ4XMjHrJQ5LwYeR4IYkX3yzIQHS7HwgotfbvlM5qIgcIbQpX(rdXvrZ0frSFMPiQjpYR762gEitaAiQjI6Ytg3bhQgHascNRR(iuGh0HcqLo1lr6uhWJD(c1(QeROQvvoHIOKHZ1bLU7uzC16hdN8YsFIAc49rR02rFV3oIe3yfO6lFSgWglrLZsWuTgD8qhz(dGehJMHYykjKxBMt6yi5cK0Wpw(q1KwFOdPVRgkBDtb1V7Afpd1IX66iYKxmhYShLmirQ5KX2mWSkTrQAIsOGJMoH(EijISPudBJuUXXm3HcI(55PnR8SI5jj(4RqnxycAxT8YK8Xqc5cva)lsLJHP6HINiEe930M03OjKnE5szfnGdyGSzbxqNPe63P6uYIK0AqTtamzXV)owWPTXkVIAiFw3NOSqES9tUtNUPwQApEfsAZGeMJ19o34oVSsT2HyrAIrtpCmu)Fxn0coMiPFOnzmraye7h5kOOPz0e91PlWu)BHT0FpR08qLoLonIAHeojn)EwXrj6iokwrMuGLUXSiMgMrN2PQApbxv9nR6KWy02H3XmVmLqAG5Ov6al6mJJkM(UDEzG6kVQ2eo8W633wtXjrJ50BFzNwRUNyutgUHGq2DUStVZz0GKzTsJdirjkHa97qvnJaolQEBzjSzZHKMNPcrHH3gL1QVlKKVGoc5iY8K03D2As1CgHWNNipErIxwejxmiv3yHSI8qbjhrTYoQKHj53iXUtd68Wz4bdEWKhqkhlJ1UUwDPJaXXA9sWJ1cYbPAWQSM1FcvARUYrLw7quwvc255Rk01zEEonKtgi7YnrQpHZsCnSo2YSKMMLusNAWVirkEuzdtlPLCQxofzDjIAiKTb67Q(mOdk)81tPMOmkl9C50kHTa0ucRKlk8(gcNoRFkxp6rpDGvco917sF31fQxNWC)l1)DEsTbc3VIqyfKXryNLeLwG0hXaNSXINk2arwsZqgzndzeT4Gj4I9WjINo4WuGXSoaJxJlds9eZln)9bVdg4jWAeH352GNeP971suX(UKG55H3Te8EyG3lrbg8uBSoR7RMcIvqIzYH6bvnGOREBshbzu3pzu7NOcY)fTki4X3afpdn)bG3pd8b031HAQtCOdbFqQpw)2Wtd))GFh439XHNHb(9qJKpe87JWzFy4pSiSiM9Td4JaFuDpRtwytnyl0)aFmg9UBtTQlffEo4zH)i4Jd)XWNa1j(t5H)eg4tEBWNQyled3CJqte(dMFpWNUUutyjuZ8NXa)58WFb8zqJO)s4ZkbFoeUz6TdFHQYL8gaUHNABq2Bh(IePrWxsc(YWzVyAQx8BJrkxQTWjwxlGtylBx5F16f4bpVe8vCKNblZCHzR4AT1hMzJK7SfKpb)1i5rWxf(AerpWxNb(B4H)wj4VRM8e4VNb(gV4Nh(MerehZreHxcFsaIbBSbQkKa(hiYeI2D6Irp(urp5aHH)rjaG)jyf4BbF7Am6W3PvS4p61DjXJVSdKuxBgKjoNRREWCJDE)nWH3NFhPBeU9lAw85qEG404D6Dt40p)HASNCHYN)IRqyYVZnItJ0ynZT(XyWmPnWZQ)M38AxLnToJ99U5vy9IuUyzQ()4SBdN9NPohlxsc6cX1Uaz6htMzAIbMSQu1YJ)khF)Gy(Eehbl1T)QCqnX27zYzdpPII3uCJTXS9RDnpByTndRzyuMSi7NVHelJSOqVZ6jeRujnY6F(6RN2OQiJdrwE7oyHckYKLLVX18mfY8inv3dlxqS(AEUdYAEEZxLVMNRwFumGwAZ1VaO9xoIC0YENk)eYTAbqVJfLZPPsDU)1DDi2XTJzyq5SsonnfKFsQPMrgHKwU6pXlWVuiCL4Pd7NLoSFpSE7JnuVSSKh9eQVE9fGZR3E7Zl5jlhR)E86LJTpwV9AGANeQkv4rtuXBXeLXGb5gj6Od340vFN68tjkQheVEzwCylfLic8ZiH9DFFebRDDi9lazPmnyZewezn5JlhlE8iCzcLiD6eJqeb(6HpfweAb4alGCpJU29Rq)xgnhpeD(zUARbGZMuv1RrEN18pJiAMdURQ)cVCFDazpXfMKGDcVeg2H4HYoIr3N0mC)ccim6pfstgkHoRMwjI54ZvLoXtaaywZFS(ERMi2W8bKnXScOVjM58eoaqmQ6a0141baUMu276sbXdG4IBKnad7qqleNYJ0X83b8ZWaQV52CauWpNh(pLGxQzyZh(wz7pGNqE941hc34TpeyPpVEjpzjp7HazcW2RNE46Xt)ErL1x)EWzXskgllUaSiSwFb6fvL(6VN(iP0pBFE8HGH(dGF0pPXO50Bi0R(ij0p8l2iqi8lBg(b)Ql7ao4)EnOm4xd)pmW)lPfTzUoEBgg4USz22waOe3C0jMXFfn9zI1aqXM56jWeBMTxhG8VBZCdxHqdmBky4zy7XxaezRpeEOFFHy73hr4rV(jp7J8mawqIN(jOc)BnQ399cRuurBMOgINPSOAUkuJ(Ol6foJLrkrpMIZY6XphojY2cNuEwrLfX)CyYEvUVLWVxDHKwOy1Qmuhokbjl3jPqvxpPq4FirkAkYMds6jPLKZnLkYl7oi5mSm69Dt(q095q6QF4w6O5YoTAb5P7DY2b3EXxgHBhSMX4RkoRUmD)PslxseohR3J6VrJY5HhdVMBh17rXt0ndtNytHP3hsqKxpbqp95Xh55wgiAZCNvrF2mDBZCeenarbUBBM7zF2mhLXM5EjMv1hDTwqtOEqP5vYMHf9EpO)8TBBg)VYaqMgbqiBXjjEeMsLO1HcyuxhSzX6fAhL)qRf(eO0KPJmmxKHnpz7Gp)KRiWhBM(GZzZeynigBM(BgP8P3uKYKCynxiXxbc0x)4Nb8qEsSdQxFefAEVwsfeMKBZ8aBmz2M5b3XXMyTKxlrz1bMjSh)tvUDK3)JRakJ8eQiYe0UgnjSTNPXGIifzNbCN2qqnxt(uG3jnsKw0qAyVfCNwqVjhj0kRykjyzjAOF7nNmQ8Qt5EKyPsfl(XAmZOIkUdAusZOwM3rd20lwstvoN7uc5mKliNtSwHAONeoS7eXDpsKghkPdYDSiPDhBKrgnEeItnicHRVcbQsDJHZuxiN4TCP6hZsidFlxsnfUXiXFHVSudO5euKlQc(nqUEHdtigSVhiVoQ7ENbnmGqUPI926b7yoerXPDqUEH9pANlNVIQqj5CKnvh5fwitndl4ExOOHmDpW25C4xXQN7IBaof5sYw7eV92dJFtAvKBkOpVQvuHCwAgz5coqSrtL1qiVCzZN4Mr(FTGGroQ28Ny)vXGng5mbvqUsBUyHYkkHLnYHmNVQ)v8mypPUbLlbx4qWukMela8etAmrKsbcwPn2kvL8Gn1f518fIRMBbToVeZYo6A4VQrxtBf8e9tUwbpfKzpXdp9zkknKcCJ2mz3ejp2mdUgrp4o1eaRboOZsu2Ie)llzQiNxmRMLLwj4uSO2GqnBHqP531cK4)cJnxX0YqahCjeJ(GdKnxztudKLuGk4UIpG1MPinHzPjCQo9cpcdjeuijZ3zL83uNZYSaj0wWn7CvBw8hFf07QM4v(aNL(URMx6QjJ6z0GwQAc8K2M0A8xA2Vxdt2JV(7P3xUWKu7Q9xDhyU2dFo)mRfFQFYKJOoWXQmr4J3E8zSwJpr4gc00MrcoLnJ8gdiTzM0Mzk8eSIntP6WoBg1gHC2mAvXA2m62mNb3u2mg2mMOgZMXcnyk3weZBg(zmTeWGxuZFC1LJuFFnTEYvJcUoVF472vpEaoyvmAISlPnTYZ8W)wZR8j8JAy1oRfLEWl0vVEQTLiOsHQcU8ZYRV7gAs6UuXRV)M31QA9MhCZrVh5c2o(ECIuIne82wGwHAELTij40irlf)M6Hgo(DXroCmK2q9JupWbW)280Kqbod10NmHkBOkRwmfY1jzlken8WS6I5uIgYi(garLQdrh6vpq06yOH5Byt)t2v)4q3eobo4Mw32)p)U5qIxZnviC47qHyffvfnKZLssBMeQ8R00pxYK8porH8KfLFbItsXfkjUdRfHdWr(Pt04DBHDwep3v3RF33jH21TENKytSOQMHiEh)rgejYVcsTLsQQn3snyz6k1CzdNdjmgW9FkB0coAiYnfV(EWVlIdx8gl(LixargEpoRnYwMl4PBkEoAXIuqI(dIazcZaw6lAgTglHnZBx)qTMtiOrobvrN)5XlLjWmqO4LgCSXt3DS2ZeC8xDWe0GFShKJ1plBGvqwRNts0KcExHcEhr2ehyRBbL(xeagVTtPFBrmpzvf0uHJfPOIhLFDkPhkDZWKnxG5XeqklmO)WKIvMz4XE4IYi)0Yj1ESYWVQdRCeo2aE7Rx8Za9BZ8bSzw4vnyd1D1m24WBk2a5zp2X(YgoYqgoxk5kZmI3Pl2ECXiV6rrQdU4H58gOVa4vbRp8(3GE6L8KLRh)95XB7rknioYM59FTbY6zBTUjmyBvvnRgw5uKChQE8MtUM(RhLaaJL)Ir4usZk5Kq2AKdzlqjkiSB1P9jYorrnLUBpim(1AGWnXf1PjMZ5avQAVdN(UcBOntE3HRDeeX4NlhUP69Qp3uNWX7HAXe7g40WHHZWZHp(Kc8BOGoccnJko8KXbCIsLsAg6sumwFHNS8dp(uYStnt7DQnrnm2exfJXEM6hLaNtRk5uiEUqPspA8MoScnt8Hh7813JPMpRd2mplCUvW1pZircpyW4XcVPnKnZhV56gkAKGCR7GsuDNIArfwbxHw)XAtnncNiE0rtfzD1XxdbgBl7JCjsKED1QhYNR1FPuXgos8Wrw)uraYxHTLdSKbdhl6eBLQQVRuHhmrIHZedF4q5gnz62u9liHnoRh2KS96JnKxpSEy91FGq(93xpC(87RNaC94LL13gTRpxYRDBhSxJj05L64HQkP5EATKgjKiMm5LNwwvKCqDXNqs8rIKiWrjFWCSdEMSdo(eTxGtYRje4uBRQSzog8TGTDw9dwDtjcpaEFjkPRixOIt4VD7nLhEhLgqRKSkz3V1pqtzI00vqrOi(qLuF)Ii5qnAiBzd1wMrHYgvwtgdiI8(b1IYkRPhmO2mkU1k4oTi(yYuB7NU7RVH9FYM5e30L6MpzZWr3ZjWVntA8Jrx)2mzZmMKZomzZmE99wYM5KWTSDBMjG71M5Hr)8uDXnGnZPrV92KSzEeBMm2m8KDjYMrOHThApngsI01KX0Mj3A3ziMllBmumdLHh4ecJAAY1gHoZJ4WrsOECBM5qqR3XQu3ZR2dXtN2mVZDCmDmY9jPlQKnZ7YMzEuPF3R0eGYM59UM1fYM5Pqf79DHT8p0iu4iorPqdgg1bDHpDeDHflDxRKTSLLMAc6jv5cZW6GxOBeTEDRLXRwQZLebVtiR0Bp6NirGKtzQJLA88BQuJphsQHerQrWx22w6lkYRnZYvjPX2BljPR2SCGRG0uBMV6LxcjAe2GBpFnhcyVfNoxkFJnw3gcTNa(5VkMag9iTKaUudYQVwM6HgETG6P0tewFQYk(yl2EQ3x4QyQxKVtlPElwxF61Yep0ORfeVXkoEL8bhAMKdmq7jEFXRIjEtF8nJ4HT55AzIhA01cIx3hBYE093ZX6nxL2t8(sxft8o47S1eV62LETmXdn6AbXRIVZmC2qd4lMA3TN49LVkM4TpLwB1sZ(oCvkbS2oguZT2wtdrdYQROMnZhHVzszjRHQ4ZSpXejJ3Es5F1vasj2zZqdKy84y)nB8YMYqwDkrl34SAm6ehhFztHivwsIUJQzykmLOkTqnejIruflvPAt0yylgvuWWDIYnDTurw(A3dJ)rI4n2fifEC8n92OjB8mHrB9A3wvRnihrozElx2CYKnDIKBQBM8xoDZCLgUtUMozl8V8hTZlloygD8S9P17aH8pE2nEFC(S3W2WhfX5KTelrcpHPFx45mmxnWPFGweAcXqLSBAe34W3JMFxMeOcoTbpCGq43RV9oFgBMV3oM(PQ3Y2mF)12e2m)aEmx7pCnv7d(t2Av7f3svl2hDRvTpXfv1G3cRGAL1kHJhEOd2wbuxuR5w3RDn3IfFSmdjoJOIrLmoCUjhlzMQrdrmoHbMm0m(hWKSa)F3nvW13(kGGR7ylQd6n8wBPoiKaMwiz7Iwv0feH6jDiunT1ZpW636zuxTkjJsegj(KZEst1ajpRq7jcFNRmgcSXbhaoAQ4mCU4kpiNp85ZJmTFkwVSEWx2yur)HfmTCNQCUCI4Rdf42rAnxQw8kflp)MESLB2mGlhmjON7VUI7lcofwkrkFi2Ht5R4aCjNS9ePx4vCoLxyr8Iggwrtv0KNQK8teYFFbWNPxV9GF4pKFFb8HJ9C2aH6LSF(Ox9tE2l50vIkwp(dSKUOb(6JdFjVmNqHcI5SqKt8jDbnDUkoQfLvftsld)lhhBQR2cG9labYB)q15U5kAkfU0WJouPPBpW5F(v8dWjII8Z5RfRy(y93VnZVWM5xwLIBZ8REzHk38g0DTmbp9qsDpUyIPetns7j42VItW)6nqWrm8(61HEVze7l1GYzt2xZnNAe7IMA0NHPNzhpAw)ksTNA8VuJAe7LpxZw0uxWykYzEAFekdPB5CxnqYR2vcM(UB63KlOTNgEjP1Cd2sdUEe9cRqLgn9u1Q67fRXfF6OLnejx5iPjxMi1IW(QerYDhr1lcqmldDR4MlRGZTJD9RtN6xjizKwM09ONi6jqosn0(HdSe(sndvVmO)Cyx5oe(YP(sHJDr6f6WWrIMMW6UpkRRZ1Wd89UyB7V)6VtDwI(j4IDSbtd)aNBohY35hYGd5OFD1Rlc6LQhlA4THW0B7ceMUkz(R(LV3jHNxIcpcxNuqVKsW3IlgotTnoTFYT(MtUaHOBkNxKJoQBaZI4pywI8zgKCx6(aWyCHvefurqy6NV69x4Dw3qkSjFYQfdjyC6rJDp1)19KIGIjvRHGs7FfltcZS9Fr4qU)Lgprfpgd5)oN0ZzqSqoFE585fv5IhzSiCKlzMgoAVW3DDx(tRnmp22nGz7(gK7bpCOQ0zPoZ3z(5FdnF30a9c)uBMS2mppMv05IJbFPX8n3Xv5xu27y93tmwbYNQ3eD7z0ud2I7jMon565O(pQNoN(6F7))d
```
