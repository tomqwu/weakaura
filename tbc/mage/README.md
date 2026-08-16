# Mage — Arcane & Frost HUD (v14)

Programmatically generated WeakAuras pack for TBC Anniversary (WeakAuras internalVersion
45, tocversion 20501). One import covers raid Arcane (40/0/21) and raid Frost (10/0/51):
spec-specific pieces load themselves through Spell Known checks, so the HUD auto-adapts on
respec with zero user action. Since v4 the same import also carries a PvP layer that only
exists inside arenas and battlegrounds — in PvE nothing about the pack changed, and v5 keeps
that promise (the one element it takes away, it takes away *only* inside an arena). v6 adds
and removes nothing anywhere: it changes *when* six cooldown icons draw, so the row shows
what you cannot press instead of everything you own (see below). **v7 gives the middle of
the screen back**: the three stacked Resources bars are gone, and health, mana and threat are
now rings around a live portrait of you and of your target, out at the sides (see below).
**v8 makes the orbs one shared size across every pack in this repo** — pure geometry, not one
trigger, gate or colour moved (see below). **v9 turns the rings into Diablo-style globes**:
three liquid vessels — life, mana and target — with the percentages inside the glass, the
portraits gone and threat carried by the target globe's rim (see below).
**v10 moves those globes up beside the character and lights the glass**: life and mana now
flank you at `y = 40` instead of sitting on a band under the HUD, the target globe rides above
and between them, and every vessel catches a specular highlight so it reads as liquid behind
curved glass rather than as a flat coloured sticker (see below).
**v11 brings the rings and the live portraits back**: the three vessels become two matched
clusters — health and mana arcs around your own face on the left, threat and target health
around your target's face on the right — with the percentages back just outside the rings,
because a portrait in the middle is what pushes them there (see below).
**v12 deletes the target cluster and brings threat home**: your target's health was already on
the target frame and the nameplate, so that half of the HUD duplicated the default UI for the
whole game and is gone — while threat, the one thing it showed that nothing else does, becomes
the **outermost ring of your own cluster** at 100px. Four auras are removed, which is a first for
this pack, so **there is one leftover group to delete by hand after updating** (see below).
**v13 makes the percentages readable**: your health percentage moves into the middle of the
cluster, drawn *on your portrait* at 16pt instead of floating 54px underneath it on bare screen,
and mana takes the slot it vacates. Nothing is added or removed — it is two numbers, two font
sizes and one change of draw order (see below).
**v14 replaces the ring cluster with THE SILL**: a 102×37 instrument strip under your feet at
`(0, -110)`, four stacked 100px rails — threat, health, mana, Arcane Blast stacks — where **one
pixel is one percent**, every number is printed inside its own rail and every breakpoint is a
full-height waterline. It is 2.65× denser than the cluster it replaces and it sits on the
crosshair instead of 270px off to the left. **The 3D portrait is gone** (its UID becomes the
plate the whole instrument is read against), the threat *number* is switched off, and the Arcane
Blast stack icon leaves the buff row to become the fourth rail (see below). The 80% threat alarm
is a **red rim**: a 108×43 quad, 3px proud of the plate on every side, drawn at the *bottom* of
the stack so only the protruding band shows and nothing is ever painted over a readout.
Spell IDs only — aura triggers carry every rank ID as
strings and cooldown triggers carry the numeric rank-1 ID, so the pack is safe on zhCN and
any other localized client. There is no custom code anywhere, so the import dialog shows no
code-review panel. Import `all-specs.txt` (or the fenced block at the bottom of this file)
whole: copy all → `/wa` → Import → paste. Heads-up: the `/wa` editor preview force-shows
every aura at once with placeholder data (load gates ignored, identical fake "55.1"
timers, both specs' icons visible together) — judge the pack in combat, not in the preview.

## v14 — The Sill: the cluster becomes a four-rail instrument under your feet

The ring cluster is gone. In its place, centred under your character at `(0, -110)`, is a
**102 × 37 px strip** made of four 100px rails:

```
   x -54                                                    x +54    <- alarm rim (only >=80% threat)
    rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr        y  -88.5
    rrr .--------------------------------------------------. rrr    y  -91.5   x -51 .. +51
    rrr |================================   :              | rrr    threat  100x4   @ +15.5
    rrr |========================================82%       | rrr    health  100x11  @ +7
    rrr |===============|================        64%       | rrr    mana    100x11  @ -5
    rrr |              ###       ###       ###             | rrr    arcane  100x6   @ -14.5
    rrr '--------------------------------------------------' rrr    y -128.5
    rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr        y -131.5
      0              30        50        70          100
                     ^ the 30% conserve waterline (mana)
                                          ^ the 70 notch (threat)
```

*(One character is 2px above; the percent scale and the pixel scale are the same ruler, which is
the point. The health number is drawn at x = +32 and the fill edge at 82% is at +32 too — that
overlap is real, and the dark plate behind it is the reason it is still readable. The `r` band is
the 80% threat alarm: a 108 × 43 quad that lives **behind** the 102 × 37 plate, so only the 3px
that sticks out on each side ever draws — see below.)*

**One pixel is one percent.** That is the whole design, and every other number follows from it.
A 0–100 quantity has exactly 100 distinguishable states, so a 100px rail is the exact length at
which the gauge is lossless: shorter throws a state away, longer redraws states the eye cannot
separate. It also makes every breakpoint arithmetic instead of trigonometry —

> **x(v) = (v / max − 0.5) × 100**, i.e. **x = v − 50** for a 100-max resource.

— where the ring needed `r = size/2 × 0.94; x = r·sin(2πf); y = r·cos(2πf)` and put the 30%
conserve mark at `(27.71, −9.0)`.

| | v13 cluster | v14 Sill |
| --- | --- | --- |
| bounding area | 10,000 px² (+1,600 for the stack icon in the buff row) | **3,774 px²** |
| height, the scarce axis under a character | 100 | **37** |
| px² carrying no decision | 1,936 (the 3D portrait) | **0** |
| distance from the crosshair | 270px left | **0** |
| breakpoint geometry | trigonometry on a stroke radius | `x = v − 50` |

### The four lanes, and how to read each one

| Lane | Region | Size @ local y | Reading rule |
| --- | --- | --- | --- |
| **Threat** | `Mage - Threat Rail` | 100×4 @ +15.5 | Green fill = your share of the pull threshold. **When the fill reaches the white notch you are at 70 — Invisibility or stop.** Orange past 70, red on aggro, and at 80 a red rim pulses *around* the whole instrument — outside the plate, never over the lanes. Absent entirely when you are solo, in an arena, or on nobody's threat table. |
| **Health** | `Mage - Health Rail` | 100×11 @ +7 | Fill = health, the number at the right end is exact. **Colour is the threshold**: orange below 50, hot red below 30 where the Ice Block prompt fires. Three hairlines mark the quarters. |
| **Mana** | `Mage - Mana Rail` | 100×11 @ −5 | Fill = what you can spend. The amber waterline at x = −20 is the **30% Arcane conserve switch** (Arcane only); a brighter, wider line appears over it the moment you cross. |
| **Arcane** | `Mage - Arcane Lane` | 100×6 @ −14.5 | Three pips = three Arcane Blast stacks; **at three the lane turns red — your next Arcane Blast is at max cost**. And **the length of the lane is how long you have before the stack falls off**, because it is fed by the debuff's own remaining time. |

The instrument fades to 50% alpha out of combat, exactly as the cluster did, but there is no
parent that can do it for the group: **the plate is a *sibling* of the rails, not their parent**,
so its alpha does not propagate and every region that can be on screen out of combat carries the
`inCombat == 0 → alpha 0.5` condition itself. Five do — the plate, the health rail, the mana
rail, the conserve waterline and the arcane lane. The other three cannot be on screen out of
combat at all, and the build proves that rather than assuming it: the threat rail hides at
`threatvalue <= 0`, the lit conserve marker is `load.use_combat`, and the alarm frame's trigger
only fires above 80% threat. Add a lane carrying neither and the build fails — which is exactly
what caught the arcane lane, the one lane that arrived in the strip with no fade and drew at full
brightness over a faded plate whenever a stack window outlived the pull.

### The 80% threat alarm is a *rim*, and here is why that took measuring

`Mage - Alarm Frame` is a **108 × 43** additive red quad — the plate plus **3px on every side** —
and it is **the first child of the group**, i.e. the *bottom* of the stack. Only the 3px band that
protrudes past the 102 × 37 plate can be seen. The rest of it sits behind a 45%-black plate and
behind every rail, number, waterline and pip, so **nothing is ever composited over a readout**.

The first cut of v14 shipped it the other way round — the plate's own 102 × 37, `blendMode = ADD`,
**last** in the draw order — on the belief that `Square_White_Border.tga` is an outline with a
transparent middle, so a same-size quad would trace the instrument's edge. That belief was
inferred from two poc builds and never checked. It is **wrong**, and the file was decoded to
settle it:

> `Interface/AddOns/WeakAuras/Media/Textures/Square_White_Border.tga` — 256×256, 32bpp, RLE.
> **64516 of 65536 pixels (98.44%) are fully opaque, alpha 255**; the 1020 that are not are
> exactly the 1px outer ring. Every pixel **inset 8px or more** from the edge: n = 57600,
> **minimum alpha 255, minimum RGB channel 167**. The centre scanline's red over x = 0…13 reads
> `0, 156, 100, 56, 40, 57, 102, 158, 206, 236, 250, 254, 255, 255`. The centre pixel is
> `rgba(255, 255, 255, 255)`.

So it is a **filled square with a dark bevel baked into its edge** — not an outline, and its
interior is not transparent. Neither bundled square is hollow, which means **no single region can
trace an edge**, which means the original construction was a full-area red wash over all four
lanes at exactly the moment threat ≥ 80% makes them worth reading.

Being bigger and being underneath are **one mechanism, and both halves are asserted** against the
decoded string on every build: `alarm.width == plate.width + 6`, `alarm.height == plate.height +
6`, `cc[1]` is the alarm and `cc[2]` is the plate. A +6 quad drawn last is the wash again; a
same-size quad drawn first is invisible. This construction is correct whether the art is filled or
hollow, which is the point of it — it does not rest on a claim about a `.tga`.

*(The same scanline decides the art. The rim is the outer 3 screen pixels of a 108px-wide quad, so
its columns sample texel centres 1.19 / 3.56 / 5.93 — red ≈ 156 / 48 / 102, a banded left-and-right
rim at roughly 40% strength, while the vertical rim resamples onto 2.98 / 8.93 / 14.9 ≈ 56 / 236 /
255 and draws nearly full. On `Square_White` every rim pixel is 255 on all four sides, so this pack
draws the rim on the fill art for a uniform edge. The rogue pack uses the border art with the
identical construction and is equally correct — correctness comes from the size and the order.)*

### What each old aura became — no new UIDs, none discarded

| v13 aura | v14 | Kept |
| --- | --- | --- |
| `Mage - Player Portrait` (**model** 44×44) | **`Mage - Sill Plate`** — texture 102×37 on `Square_White` (a flat, uniform quad: no border, no rounding), black at 45%, **second** in the draw order | UID, both triggers, both conditions |
| `Mage - Threat Ring` (100×100) | `Mage - Threat Rail` 100×4 | UID, trigger, all three conditions, both load gates |
| `Mage - Player Health Ring` (84×84) | `Mage - Health Rail` 100×11 | UID, both triggers, all four conditions |
| `Mage - Player Mana Ring` (62×62) | `Mage - Mana Rail` 100×11 | UID, both triggers, both conditions |
| `Mage - Mana Conserve Line/Lit` (6/8px beads) | 3×11 and 5×11 **waterlines** at x = −20 | UIDs, triggers, colours, Arcane gate, pop animation |
| `Mage - Threat Flash` (100px halo) | `Mage - Alarm Frame` **108×43** — the plate + 3px per side, **first** in the draw order, so only the 3px rim shows | UID, trigger, ADD blend, alphaPulse, both load gates, and its explicit red |
| `Mage - Arcane Blast Stacks` (**icon** 40×40, buff row) | **`Mage - Arcane Lane`** — progresstexture 100×6 in the strip, plus a second *Unit Characteristics* trigger that feeds the out-of-combat fade | UID, the aura2 trigger (36032), the Arcane-only gate |
| `Mage - Player Cluster` | `Mage - Player Sill`, moved to `(0, −110)` | UID |
| `Mage - Rings` | `Mage - Sill Layer` | UID |

Continuity against v13 is `stable=35 changed=0 retained=43 missing=0 parentSame=true`: **all 43
child UIDs survive**, and `stable` reads 35 only because eight auras were renamed (an aura counts
as *stable* only if its id is unchanged; a `missing` UID is the hard failure, and it is 0). 44
auras before, 44 after. Nothing to delete by hand.

### What this costs you — the honest list

- **The live 3D portrait is gone.** It was 1,936 px² — 19.4% of the cluster — and it decided
  nothing, but it was also the one part of this HUD that read as *you* rather than as an
  instrument panel. v11 brought it back on purpose ("two concentric arcs around a live portrait
  read as a unit"); v14 reverses that on density grounds. Its UID is now the plate, so nothing is
  orphaned, but a 3D face is not coming back without another version.
- **The threat percentage is no longer printed.** The subtext still exists at index 1 with its
  token, colour and font intact — it ships `text_visible = false`. `/wa` → `Mage - Threat Rail`
  → the text sub-region → tick *Show Text* and it returns just above the plate — at absolute
  y −84, which is 7.5px clear of the plate's top edge at −91.5, not on top of the lanes. (That
  offset is `anchorYOffset = 10.5` on the threat rail, because a subtext anchors to its own
  *region's* centre, so it stacks on the rail's +15.5 and not on the group. The build re-derives
  the number from the decoded string and asserts both facts, so this sentence cannot go stale.)
  It went because
  `threatpct` is scaled so 100 = pulling aggro: it is an early-warning ratio, not a quantity you
  spend, and a notch at the 70 line answers it faster than reading "68" against "72".
- **The Arcane Blast stack count and its countdown are no longer text.** Three pips replace the
  16pt number and the draining rail replaces the 11pt window timer, and the 40×40 spell icon art
  goes with them.
- **The numbers straddle the fill.** At ~82% health the fill edge sits under the digits. Outline
  + black shadow + the dark plate is the mitigation, and it is why the plate is load-bearing
  rather than decoration — judge it in combat, not in the editor.
- **Four bars is a dashboard; the cluster was a character.** That is the aesthetic cost of a
  2.65× density gain, and it is the most likely thing to dislike.

### Where it sits, proved rather than asserted

Offsets add down the chain, and the strip hangs two groups deep under a top group with its own y:

```
top (0, -140) + layer (0, +180) + sill (0, -150) = (0, -110)
```

The build **decodes the string it is about to ship**, walks that chain itself, and fails if the
answer is not `(0, -110)` — along with 60-odd other checks that hard-code the rail canon the way
v12/v13 hard-coded the ring canon (`orientation == "HORIZONTAL_INVERSE"`, every rail exactly
`RAIL_LEN` long, the lane offsets, the subregion layout, **the alarm rim first and the plate
second**, and the rim exactly 6px larger than the plate in both axes). Then it boxes every other
element in the pack and scans them against **the alarm envelope, not the plate** — the rim is the
widest thing the strip ever draws, and scanning the plate would have declared 3px of it clear
without ever testing it — projecting each dynamic group **at least six children deep**:
`max(childCount, 6)`, so the alert stack and the cooldown row, which own ten children each, are
projected ten deep, because an alert stack that clears at depth 1 is not a clearance:

```
ALARM ENVELOPE (scanned)         x  -54..54    y -131.5..-88.5
plate (inside it)                x  -51..51    y -128.5..-91.5
  Mage - Ice Barrier             x  -20..20    y -176..-136   clear by  4.5px
  Mage - Arcane Power Window     x  -65..-31   y -173..-139   clear by  7.5px
  Mage - Icy Veins Window        x   31..65    y -173..-139   clear by  7.5px
  Mage - Alerts     (stack x10)  x -172..-128  y  -66..450    clear by 74.0px
  Mage - Cooldowns  (row x10)    x -178..178   y -222..-190   clear by 58.5px
  Mage - PvP        (stack x6)   x   80..220   y -290..-26    clear by 26.0px
                          6 boxes scanned, 0 overlaps, tightest 4.5px
```

The binding margin is **4.5px**, from the rim's bottom edge at −131.5 to the 40px Ice Barrier
timer starting at −136. (The plate alone would clear it by 7.5px — that is the number this section
used to print, and the reason the scan now boxes the envelope.) The rim only exists above 80%
threat, so 4.5px is the worst case rather than the resting state, and the next tightest is 7.5px
to the two burn-window timers. The strip is the same shape and the same `(0, -110)` in all seven
packs, so the margin is deliberate and shared. **No existing row moved.**

### After updating

**Leave the update dialog's categories at their defaults — in particular, leave *Arrangement*
checked.** This version re-parents nine auras, re-orders the group's children and moves the group
itself, and every one of those travels in the *Arrangement* category. Unchecking it leaves the
rails at their old ring sizes and positions, which is not a HUD.

If you have dragged the pack around in game, expect to re-drag it afterwards. That is the cost of
a version that changes region type, size, parent, offset and draw order at once, and it is the
same trade v12 asked for.

There is **nothing to delete by hand** this time: no aura is removed, every UID carries, and the
eight renamed auras update in place under their new names. You should see **44 auras**, same as
v13. The buff row is one icon shorter — the Arcane Blast stack tracker is now the bottom rail of
the strip — and the row closes the gap by itself.

### Honest limitations

- **`HORIZONTAL_INVERSE` has never been rendered by this repo.** It is transcribed from
  WeakAuras' `Private.orientation_with_circle_types` as "Left to Right" (`HORIZONTAL` is "Right
  to Left" — note this is the *opposite* convention to an aurabar), and it shares the linear code
  path with `VERTICAL`, which *is* live in a shipped poc string. **30-second check on a live
  client**: at full mana the rail is solid; drop to ~50% and confirm the empty half is on the
  **right**. If it is reversed, the fix is one token in `generate.lua` and nothing else changes.
- **A non-square progresstexture is new here.** Every other one in this repo is a square (rings
  and globes). `crop_x/crop_y = 0.41` is a texcoord scale on the linear path and the art is a
  uniform white square, so it cannot alter what is drawn — but the aspect stretch itself is
  untested for this region type in this repo.
- **An aura2-fed progresstexture is new here too.** The arcane lane taking its fill from a
  debuff's remaining time is standard WeakAuras, but every other progresstexture in this repo is
  fed by a unit trigger.
- **6px pips are small.** If the three Arcane Blast stacks do not read at a glance in combat, the
  lane can grow — but the plate grows with it and so does the rim, and the rim already sits 4.5px
  off the Ice Barrier timer, so it is a real trade rather than free space.
- **The rim has not been rendered on a live client either.** The construction is arithmetic (a
  108×43 quad behind a 102×37 one leaves a 3px band) and both halves are asserted off the decoded
  string, but *how bright* a 3px additive band at `{1, 0.1, 0.1, 0.85}` reads against a night sky
  versus a lava floor is a judgement no build check can make. If it is too subtle, `RIM` at the
  top of `generate.lua` is the one number to change — the asserts derive from it.
- **The geometry still has not been rendered on a 2.5.x client.** Every dimension is a named
  constant at the top of `generate.lua`: retune and re-run rather than dragging pieces in game,
  or the next update resets them.

## v13 — the health number moves into the middle, onto your face

**The complaint this fixes, in one line: "percentage in middle can't be seen."** It was accurate,
and the middle was the problem — because there was nothing in it.

Since v11 the percentages sat *outside* the rings: health 54px below the cluster at 13pt, mana
70px below at 10pt. Two small numbers with **no backdrop at all** — just whatever the game world
happened to be behind them. Over a snowfield in Winterspring, a lava floor in the Black Temple, or
any bright ground texture, a thin outlined number on open sky is unreadable no matter how big the
outline is. Meanwhile the one part of the cluster that *is* dark, opaque and always on screen —
your portrait — sat in the middle carrying nothing.

v13 puts the number where the backdrop is.

| Read-out | v12 | v13 | Why |
| --- | --- | --- | --- |
| Health % | y = -54, 13pt | **y = 0, 16pt** | dead centre, drawn on your portrait. The glance read while taking damage, so it gets the biggest font in the cluster and the only opaque backdrop it has |
| Mana % | y = -70, 10pt | **y = -54, 12pt** | inherits the slot health vacates — just under the health ring, closer in and two points larger than where it used to be |
| Threat % | y = 58, 10pt | *unchanged* | already above the outer ring, already legible, never part of the complaint |

Text, colours, outline and shadow are untouched: still `%percenthealth%%`, still the same escalating
green → amber → red conditions under 50% and 30%.

### Why this needed the draw order changed, not just the offset

This is the part worth reading, because moving the number alone would have shipped **a change that
looks like nothing happened**.

Auras inside a group draw in `controlledChildren` order — WeakAuras' `FixGroupChildrenOrder` adds
+4 frame levels per entry, so **later children draw on top**. Through v11 and v12 the cluster ended
with the portrait:

```
v12:  Threat Ring → Health Ring → Mana Ring → Conserve beads → Threat Flash → PORTRAIT
```

The portrait was last on purpose, under the old rule "nothing draws over the face" — which cost
nothing while every number lived outside the rings, because nothing else reached the middle. The
moment health moves to the centre that rule inverts: the portrait is drawn *after* the health ring,
so it covers the health ring's own text. The number would be there, correct, and completely hidden.

So v13 puts the face at the **back**:

```
v13:  PORTRAIT → Threat Ring → Health Ring → Mana Ring → Conserve beads → Threat Flash
```

**And this hides no part of your portrait**, because every other child of the cluster is an annulus
or a small bead with no art at its centre. Measured off the decoded string — `Ring_20px`'s stroke is
20/256 of the drawn size, so a ring of diameter *d* covers radius *d*/2 − 20*d*/256 … *d*/2:

| Element | Diameter | Radius it actually paints |
| --- | --- | --- |
| Threat ring | 100px | 42.19 … 50.00 |
| Threat flash | 100px | 42.19 … 50.00 (same art, ADD blend) |
| Health ring | 84px | 35.44 … 42.00 |
| Mana ring | 62px | 26.16 … 31.00 |
| Conserve beads | 6/8px | ~29 from centre, on the mana stroke |
| **Portrait** | **44px** | **0.00 … 22.00** |

The innermost thing any ring paints starts at **26.16**; your face ends at **22.00**. There is a
4.16px gap, so drawing all six over the portrait removes nothing from it — the only thing of theirs
that lands on the face is the health **text**, which is the entire point of the version.

The flash is the one worth checking twice, since it is the single child drawn over the health
number: it is also a 100px annulus, so at 80%+ threat it pulses around the *outside* of the cluster
and never touches a number at the centre.

**Nothing else moved.** No aura added, removed or renamed; no trigger, load gate, condition, colour,
size or position changed anywhere in the pack. Reordering children edits the group's child list
only — the portrait is still created in its original position in the UID stream — so continuity
against v12 is `stable=43 changed=0 retained=43 missing=0 parentSame=true`, and re-importing offers
**Update** with no leftovers to clean up. 44 auras, same as v12.

## v12 — the target cluster is deleted, and threat becomes your own outer ring

v12 is the first version of this pack that **removes** auras: 48 → **44**. Four go, one moves,
and nothing else in the pack changes — `stable=42 changed=0 retained=43 missing=4
parentSame=true` against v11, where the four missing UIDs are exactly the four deletions below
and `stable` reads 42 rather than 43 only because the threat ring was **renamed** (it keeps its
UID). Every other aura — the buffs row, the alert flow, the cooldown row, the conserve beads, the
whole PvP layer — decodes byte-identical to v11.

**What went, and why.**

| Removed | Why |
| --- | --- |
| `Mage - Target Cluster` | the group that held the other three |
| `Mage - Target Health Ring` | your target's health is already on the target frame **and** the nameplate — this was a third copy of it, all game |
| `Mage - Target Portrait` | a live 3D model of the thing whose portrait is already in the target frame you clicked to select it |
| `Mage - Target Ring Track` | an empty black hoop that existed only to keep a UID alive (v11 says so outright) and to make the two clusters look symmetrical |

A HUD element earns its place by changing the next button press. The target's health percentage
never did — it is the number the default UI is loudest about — and once it goes, the face and the
symmetry track have nothing to be symmetrical *with*.

**What moved instead of dying: threat.** It is the one thing the target cluster carried that
nothing in the game shows on its own, and a dps who pulls aggro dies, so deleting it would have
been a real regression rather than a simplification. It is now the **outermost ring of your own
cluster**, and that is the more honest place for it: it is *your* threat. The trigger still reads
the target — threat is a relationship, and the unit names the table it is measured from — but the
arc is on you, because the number is about you.

```
                 47%     <- threat %, 10pt, +58 (above the new outer ring)
        .-----------------.
       /   .-----------.   \
      |   /   .-----.   \   |
      |  |   |  ( )  |   |  |     100px  YOUR THREAT      (green / 70% orange / aggro red)
      |  |   |   o   |   |  |      84px  your health      (unchanged)
      |   \   '-----'   /   |      62px  your mana        (unchanged)
       \   '-----------'   /       44px  live portrait    (unchanged)
        '-----------------'
                84%     <- health %, 13pt, -54
                71%     <- mana %,   10pt, -70
```

Health, mana and the portrait do not move by one pixel; only the threat percentage does, from
`+54` to `+58`, so it clears the new outer ring (radius 50). The 80% flare resizes 88 → **100**,
so it pulses *on* the threat arc instead of orbiting a radius nothing occupies any more.

**Threat kept everything.** The Threat Situation trigger, both escalations on `foregroundColor`
(`barColor` is aurabar-only and is dropped *silently* on a progresstexture — no error, no editor
warning), the party/raid gate, the never-in-arena gate, and the mandatory `threatvalue <= 0 →
alpha 0` guard without which a ProgressTexture with a zero total draws **full** and reports a
complete circle of aggro at the exact moment you have none. One trigger field is deliberately
*not* modernised: the prototype's unit argument is `threatUnit` on internalVersion 45 data and was
renamed to `unit` at 51, and WeakAuras' Modernize pass migrates anything below 51 forward — so
this string emits the old name and lets the client rename it. v11 emitted both; v12 emits only
`threatUnit`, because two names for one binding is one too many.

Because those two load gates travel with it, **the common case is still two arcs and a face**:
solo and in arenas the threat ring does not load at all, and nothing is drawn in its place. That
was the excuse for the target ring track in v11, and it is why the track is gone rather than
reused.

**Positions are absolute, and the surviving cluster did not move.** Every ring hangs two groups
deep under a top group carrying its own `y = -140`, and offsets add down the chain:

```
top (0, -140) + layer (0, 180) + cluster (-270, 0) + ring (0, 0) = (-270, 40)
```

That chain was walked in the **decoded shipped string** for all five surviving cluster regions —
threat 100, health 84, mana 62, portrait 44 and the flare 100 — and every one lands on `(-270,
40)`, i.e. they are genuinely concentric. The Alerts column is the one neighbour that matters: it
sits at `x = -150` and grows *upward* as a dynamic group, so its widest child (44px) spans
`-172..-128` **at any stack depth**, while the 100px threat ring spans `-320..-220`. Projected six
prompts deep the stack reaches `y = 250` and does overlap the cluster's rows — and still clears it
by **48px horizontally**, which is the margin that matters. The PvP column is at `+150`, on the
other side of the character entirely.

### After updating

**There is one group to delete by hand: `Mage - Target Cluster`.**

WeakAuras never deletes an aura that an import does not mention — an import can only add and
update — so the four removed auras stay in your collection after the update, sitting in that
group. Delete it and its children (`Mage - Target Health Ring`, `Mage - Target Portrait`,
`Mage - Target Ring Track`) once, and the pack is exactly what this README describes: right-click
`Mage - Target Cluster` in `/wa` → Delete, and accept deleting the children with it.

**Check the group is empty of anything you want to keep before you delete it.** The import moves
the threat ring into `Mage - Player Cluster`, so in the normal case the leftover group holds only
the three dead regions — but re-parenting is part of the update dialog's *Arrangement* category,
so for this one update leave the dialog's categories at their defaults rather than unchecking
Arrangement. If you have dragged the pack around, expect to re-drag it afterwards; that is the
cost of a version that changes one region's size, parent and offset at once.

Nothing was invented to absorb the four freed UID slots, and that is the deliberate part: a HUD
that may never delete a region can only grow, and v11's target ring track is what "keep the slot
alive" looks like after a few versions. The slots are drawn from the UID stream in their original
positions and thrown away, so no surviving aura's UID shifted by one call, and anything a future
version appends starts *after* them and can never collide with a region you may still have
installed.

You should see **44 auras** afterwards (plus whatever is left of the old target group until you
delete it). The threat ring arrives renamed, `Mage - Target Threat Ring` → `Mage - Threat Ring`;
it keeps its UID, so it updates in place rather than arriving as a new aura, and nothing else in
the pack is touched at all.

### Honest limitations

- **The two outer arcs are flush, not spaced.** `Ring_20px`'s stroke is 20/256 of the drawn size,
  so on the decoded string the threat band occupies radius 42.19–50 and the health band 35.44–42:
  they touch, with 0.19px between them. That is intended to read as one double band around the
  portrait, but it is the first thing to check on a live client — if the pair reads as a single
  fat ring, `THREAT_RING` is the constant to raise, in all seven packs at once.
- **The geometry still has not been rendered on a 2.5.x client.** Diameters, stroke weights, the
  portrait framing and the three number offsets are computed, not measured. All of them are named
  constants at the top of `generate.lua` — retune and re-run rather than dragging pieces in game,
  or the next update resets them.
- **Target health is now the default UI's job.** That is the point of the change, but it is a real
  trade: if you play with the target frame hidden, this pack no longer shows the target's health
  anywhere. Nothing in it ever *decided* anything from that number, which is why it went.
- **Threat is still invisible where it is meaningless.** Solo and in arena the ring does not load,
  by design (v2 and v5), and the cluster is simply two arcs and a face there.

## v11 — the rings come back, and so do the portraits

v11 is an in-place update of v10 that **adds no aura, removes none and moves no UID**
(`stable=38 changed=0 retained=47 missing=0 parentSame=true` — every one of v10's 47 child
UIDs is still here; `stable` reads 38 rather than 47 only because nine auras were **renamed**,
each keeping its own UID). Nothing outside the unit HUD is touched: the buffs row, the alert
flow, the cooldown row, the procs and the whole PvP layer decode byte-identical to v10.

**What changed and why.** Side by side with the v7/v8 ring clusters, the globes lost. A vessel
is a good picture of a *pool* but a poor instrument: a waterline in a circle is not linear in
area, so the middle of the range races and both ends crawl, and three separate vessels never
read as one system. The rings are back, at the proportions that survived the comparison, and
with them the thing that made the old layout legible — **a live 3D portrait in the middle of
each cluster**:

```
          player cluster                              target cluster
            (-270, 40)                                  (270, 110)
                                                            47%      <- threat %, 10pt, +54
         .---------------.                          .---------------.
        /   .---------.   \                        /   .---------.   \
       |   /   .---.   \   |                      |   /   .---.   \   |
       |  |   |  o  |   |  |                      |  |   |  o  |   |  |
       |   \   '---'   /   |                      |   \   '---'   /   |
        \   '---------'   /                        \   '---------'   /
         '---------------'                          '---------------'
                84%       <- health %, 13pt, -54            62%       <- target health %
                71%       <- mana %, 10pt, -70

   outer 84px: your HEALTH          | outer 84px: your THREAT on that target
   inner 62px: your MANA            | inner 62px: the target's HEALTH
   centre 44px: live player portrait| centre 44px: live target portrait
```

Both clusters are the **same three sizes** — 84 outer, 62 inner, 44 portrait (44/84 = the 0.52
ratio the live review approved) — which is the whole reason the pair reads as one instrument
rather than two widgets. The target deliberately does **not** get a third, power ring: an extra
arc on one side only is exactly what made v7/v8 look busy and uneven, and enemy mana already
has a home in the arena PvP column (v5), which is the only place it decides anything. Under the
target's threat arc sits a static **track** in the rings' own unfilled black, so that when threat
does not load — solo, or in an arena — the outer circle is still there and the pair still
matches.

**The percentages move back out.** A `model` region cannot carry a text sub-region at all
(WeakAuras' `SubText.supports()` lists texture / progresstexture / icon / aurabar / empty —
`model` is absent). Dropping the portrait is what let v9 put each number inside its glass;
bringing it back is what puts them outside again: health 13pt at `-54`, mana 10pt at `-70`,
threat 10pt at `+54`. All three anchor `CENTER`, so the offsets are measured from the *cluster*
centre rather than from whichever ring carries the text — which is why one set of numbers
serves both sides even though health is the outer arc on the left and the inner arc on the
right. The specular highlight v10 added is gone with the vessels: it was glass over liquid, and
an arc has no glass.

**One field separates a ring from a globe**, and it is the same field that took v8's rings to
v9's globes, read backwards. Both are `progresstexture`. A globe is `orientation = "VERTICAL"`
on a solid disc and encodes the value as a *waterline*; a ring is `"CLOCKWISE"` on annulus art
(`Ring_20px.tga`, bundled with WeakAuras) and encodes it as *arc length*. Flipping it also
flips which neighbouring fields are live: `startAngle`/`endAngle` matter again and
`compress`/`slanted`/`slantMode` go inert, while `crop_x`/`crop_y` stay at **0.41**, the
identity value on the circular path — it cancels the √2 expansion the circular branch applies,
so setting it to 0 would blow every ring up by 41% and clip it.

**Every danger signal came across again, on the property that exists for the region it now
lives on.** This is the trap this migration repeats at every hop: an aurabar escalates with
`barColor`, a plain texture (v9/v10's rim) with `color`, and a progresstexture with
`foregroundColor` — and `Conditions.lua` drops a change whose property is missing from the
region's table *silently*, with no error and no editor warning. Health's 50% orange and 30% red
were already on `foregroundColor`; threat's 70% orange and aggro red moved from the rim's
`color` back to `foregroundColor` as the rim became a ring. The zero-total guards
(`maxhealth <= 0`, `maxpower <= 1`, `threatvalue <= 0`) are all still in place and are still
mandatory, because a `progresstexture` with a maximum of zero draws **full**, not empty — a
threat ring reporting a complete circle of aggro before your first cast lands would be a lie
told at the worst possible moment.

**The conserve mark follows its ring.** The Arcane 30% breakpoint was a bead on the mana ring
in v7/v8, a waterline across the mana globe in v9/v10, and is a bead again now — placed by
`r = INNER/2 × 0.94` at `2π × fraction` measured clockwise from the top, which is where a
`CLOCKWISE` fill starts. That puts it at `(27.71, −9.0)`: radius 29.13 on a stroke that runs
from 26.2 to 31, at 107.99° — 29.998% of the way round, i.e. the 30% mark, verified on the
decoded string rather than in the generator. It is still two separate auras (dim + lit) purely
so it can keep its **Arcane-only** load gate, which a `subtexture` tick welded to the shared
mana ring could not.

**Positions are absolute, and ±270 is not negotiable.** Both clusters hang two groups deep
under a top group that carries its own `y = -140`, and offsets add down the chain:

```
player: top (0, -140) + layer (0, 180) + cluster (-270,  0) + ring (0, 0) = (-270,  40)
target: top (0, -140) + layer (0, 180) + cluster ( 270, 70) + ring (0, 0) = ( 270, 110)
```

Both chains were walked in the **decoded shipped string**, not in the generator. The x value is
a clearance result, not a taste call: this pack's Alerts column sits at `x = -150` and its PvP
column at `x = +150`, both *dynamic* groups that grow vertically, so a cluster at ±190 is walked
into by the alert stack from the second simultaneous prompt onward. ±270 is the tightest
symmetric pair that stays clear at any stack depth.

### After updating

**Nothing to delete.** All 47 child UIDs from v10 are still here, and nine of them changed hands
to build the new layout —

| v10 aura | is now |
| --- | --- |
| `Mage - Globes` | `Mage - Rings` (the layer) |
| `Mage - Life Cluster` | `Mage - Player Cluster` |
| `Mage - Life Globe` | `Mage - Player Health Ring` (outer, left) |
| `Mage - Mana Globe` | `Mage - Player Mana Ring` (inner, left) |
| `Mage - Life Globe Rim` | `Mage - Player Portrait` |
| `Mage - Mana Globe Rim` | `Mage - Target Portrait` |
| `Mage - Target Globe` | `Mage - Target Health Ring` (inner, right) |
| `Mage - Target Globe Rim` | `Mage - Target Threat Ring` (outer, right) |
| `Mage - Power Cluster` | `Mage - Target Ring Track` (the outer circle under the threat arc) |

`Mage - Target Cluster` and `Mage - Threat Flash` keep both their names and their UIDs. You
should see 48 auras afterwards and no leftovers. **Uncheck *Arrangement* in the update dialog
if you have dragged the pack around** — v11 moves every position in the cluster.

The eleventh slot is worth explaining, because it is the one judgement call here: the globe HUD
had three cluster groups (life, power, target) and the ring HUD needs two, since the player's
health and mana are now concentric arcs around **one** portrait. The freed group could not
simply be deleted — `W.assertUidContinuity` fails on any UID that disappears — so it becomes the
target cluster's **outer track**: the same `Ring_20px` annulus at the same 84px, in the black
55% the rings already use for their unfilled arc, drawn under the threat ring and carrying the
target's Health trigger so it exists exactly when the cluster does. It earns its place rather
than merely holding a UID: the threat ring is party/raid only and never loads in an arena, so
without a track the target side would sit there solo as a lone 62px arc facing an 84px one. This
is the same slot the other packs in this repo put on the same region, for the same reason.

Several auras change region type in place (globe → ring, texture rim → ring, texture rim → model
portrait, group → texture). That is a normal data update for WeakAuras, but it is the most
unusual thing this pack asks of the import dialog: if anything looks structurally wrong
afterwards, delete the `Mage - Rings` group and re-import, which rebuilds it cleanly.

### Honest limitations

- **The geometry has not been rendered on a 2.5.x client.** Ring diameters, the stroke weight
  of `Ring_20px` at 84 and 62 px, the portrait framing and the placement of the three numbers
  are computed, not measured. Every one is a named constant at the top of `generate.lua` —
  retune and re-run rather than dragging pieces in game, or the next update resets them.
- **The portraits are the one thing only a live client can settle.** Current WeakAuras reads a
  model region's unit from `model_fileId`; WA 3.5.0 read `model_path`, and the migration
  bridging them is guarded by `IsClassicEra()`, which is *not* `IsTBC()` — so on a 2.5.x client
  that migration does not run, and a string emitting only `model_path` would show two empty
  squares with no error. Both fields are emitted, which is believed correct but is exactly the
  kind of claim a screenshot settles and source reading does not.
- **Solo, and in arena, the target's outer arc is an empty track.** The threat ring keeps the
  party/raid gate (v2) and the never-in-arena gate (v5), and the outer ring *is* the threat
  element — so where threat means nothing it does not load at all, and what is left is the
  unfilled track behind it, which keeps the two clusters the same shape without inventing a
  number.
- **No target power ring, by design.** Two rings and a face per side is the layout that was
  approved; enemy mana lives in the arena PvP column, where it decides something.

## v10 — the globes come up beside you, and the glass catches light

v10 is an in-place update of v9 and the smallest kind of change this pack can ship: **no aura
added, removed or renamed, no UID moved** (`stable=47 changed=0 retained=47 missing=0
parentSame=true` — the strictest result the continuity check can report), and no trigger, load
gate, condition, colour, spell ID or region type touched anywhere. Decode v9 and v10 side by
side and **41 of the 48 auras are byte-identical**; the seven that differ are the globe layer's
own y, three cluster offsets and one appended sub-region on each of the three vessels.

**Where they went.** v9 put all three vessels on a band at `y = -262`, below the cooldown row.
That band read as a *separate bar bolted under the HUD* — a fourth strip of UI to look at,
level with nothing. The globes now flank the character, the way a Diablo life and mana globe
flanks the belt:

```
                                 target
                                (0, 110)
                                  .---.
                             62% | ### |          <- 44px, hides with no target
                                  '---'

        life                                              mana
     (-270, 40)                                        (190, 40)
    .-----------.                                    .-----------.
   /  *          \                                  /  *          \    <- specular highlight
  |     84%       |                                |      71%      |      (upper left, ADD)
  |               |                                |- - - - - - - -|    <- 30% conserve mark
  |###############|                                |###############|       (Arcane only)
   \#############/                                  \#############/
    '-----------'                                    '-----------'
        72px                                            72px

  the character stands between them; the alert column (x = -150) and the PvP column
  (x = +150) sit below and outside, and both stay clear — see the margins below
```

| element | v9 | v10 |
| --- | --- | --- |
| life globe | `(-150, -262)` | **`(-270, 40)`** |
| mana globe | `(+150, -262)` | **`(+270, 40)`** |
| target globe | `(0, -262)` | **`(0, 110)`** |

Those three positions are **fixed across all seven class packs** and were scanned against every
element in all of them, so any two packs can be diffed and match. They are the tightest
arrangement that collides with nothing, and the near misses are worth writing down so nobody
"tidies" them later: `x = ±170` walks into the Alerts column at `-150` and the PvP column at
`+150`, both of which this pack carries, and `x = ±210` walks into the PvP-layer elements
around `(200, -44)`. In this pack's own numbers the margins are: the life globe's rim ends at
`x = -152` and the widest alert icon starts at `x = -172`, so **20px of air** separates them
even when the alert stack (which grows *upward* from `y = -44`) is three deep; on the right the
widest PvP element is a 140px bar that reaches `x = 220`, but that column grows *downward* from
`y = -44` while the mana globe's lowest point is `y = 2`, so they clear each other by **46px**
vertically. Sizes did not change: 72px mains, 44px target, rims +4.

**Why it is not one number.** `y` here is an **absolute screen coordinate**, but every globe
hangs two groups deep under a top group that carries its own `y = -140`, and offsets add down
the chain. The globe layer therefore cancels the top group (`GLOBE_LAYER_Y = 180`) and the
target cluster carries the 70 that lifts it above the pair, which is why the target globe is
the one cluster with a `y` of its own:

```
life:   top (0, -140) + layer (0, 180) + cluster (-190,  0) + globe (0, 0) = (-190,  40)
power:  top (0, -140) + layer (0, 180) + cluster ( 190,  0) + globe (0, 0) = ( 190,  40)
target: top (0, -140) + layer (0, 180) + cluster (   0, 70) + globe (0, 0) = (   0, 110)
```

Every one of those chains was walked in the *decoded shipped string*, not in the generator —
that is the check this kind of migration is graded on, and it is the one an earlier globe
migration failed in six packs out of seven.

**The glass now catches light.** A flat fill colour is what made v9 read as a sticker rather
than as liquid in a vessel: real glass has a bright spot where it faces the light source. Every
globe gains one — a soft, off-centre highlight in the **upper left**, sized to that globe
(46% × 34% of its width, offset by −17% / +21%), in white at 28% alpha. It is not a decoration
bolted on top; it is the single cue that makes a circle read as a sphere.

The one field that makes it work is the **blend mode, which is `ADD` and not `BLEND`**. The
percentage lives *inside* the glass, sub-regions draw in the order they are listed, and this
one is appended — so it draws over the number. A 28% white `BLEND` overlay would wash 28% of
the digits away; `ADD` can only brighten, so the number keeps its contrast and merely picks up
the same sheen the liquid does. That is also why the recipe is a highlight rather than the more
obvious dark edge vignette: a dark overlay sitting on the health number is least readable in
exactly the moment — low health — the number matters most.

**Appended, never inserted.** WeakAuras conditions address sub-regions *positionally*, as
`sub.N.property`, with no name to fall back on, so inserting anything ahead of a referenced
index silently retargets that condition onto a different sub-region — no error, no editor
warning. The highlight is therefore the **last** sub-region on each globe, and every
pre-existing index is exactly where v9 left it. (This pack's only `sub.N` conditions are the
CC ON ME glow and the Arcane Blast stack glow, both on *icons*, so nothing here was at risk —
but the rule is what makes that verifiable instead of lucky.)

### After updating

Nothing to delete and nothing new to arrange — this is the same 48 auras with the same UIDs.
**Uncheck *Arrangement* in the update dialog only if you want to keep positions you dragged in
game**; leaving it checked is what applies the new layout, which is the entire point of v10.

## v9 — Diablo globes: three vessels, and the numbers move inside the glass

v9 is an in-place update of v8 (same UIDs — the import dialog offers **Update**, not a
duplicate group). It **adds no aura and removes none**: the same 48 auras ship, and all 34
auras outside the orb cluster — buffs, alerts, the cooldown row, the procs, the whole PvP
layer — decode byte-for-byte identical to v8 (the top group's only change is the new name of
the child group it lists). What changed is what the orb cluster *is*.

The two ring clusters are gone. In their place stand **three vessels** that fill bottom-to-top
like liquid, the way a Diablo life or mana globe does:

```
            life                      target                       mana
          x = -150                    x = 0                       x = +150

                                       47%   <- threat %
        .-----------.                 .-----.                  .-----------.
       /             \               /       \                /             \
      |               |             |   62%   |              |      71%      |
      |      84%      |              \       /               |- - - - - - - -| <- 30% conserve
      |###############|               '#####'                |###############|    mark (Arcane)
       \#############/                                        \#############/
        '-----------'                                          '-----------'

  72px, D2 red        |   44px, hides with no target   |   72px, D2 blue
  the fill is a WATERLINE that rises; the empty part is a near-black vessel, not nothing
  a rim is drawn over every globe at a higher frame strata, so the liquid sits inside glass
```

- **Life on the left, mana on the right**, both 72px, each with its percentage **inside the
  glass** at 18pt. Health still brightens to orange below 50% and to a hot red below 30%,
  where the Ice Block prompt fires. Both vessels fade to 50% alpha out of combat, exactly as
  the rings and the bars before them did.
- **The target globe sits between them** at 44px, so it reads as secondary, and it is
  **completely invisible until you have a target** — no globe, no rim, no number, nothing left
  behind. Its percentage is 13pt, also inside the glass.
- **The mana conserve breakpoint is a line again.** On a ring it had become a bead on the
  circumference; on a vessel a threshold is simply a horizontal line at a fixed height, which
  is what it was on the v6 bar. It crosses the mana globe at the 30% waterline — dim by
  default, with a brighter, thicker line popping in the moment you cross it. Still Arcane
  only, still combat-only for the lit line, exactly as v3 left it.

**The portrait is gone, and that is what buys the numbers their place.** A WeakAuras `model`
region cannot carry a text sub-region at all, so with a live portrait in the middle of each
orb there was nowhere for a percentage to go except outside the rings, where it competed with
the world behind it. Dropping the portrait frees the centre of every vessel for the one thing
you actually read. The trade is real and it is the price of this layout: **no live face** for
you or your target. Nothing was orphaned to do it — the two portrait auras were *rebuilt* into
the life and mana rims, keeping their UIDs, so WeakAuras rewrites them where they stand
instead of leaving two dead models in your collection.

**Threat became the target globe's rim.** Threat has no natural vessel — it is a relationship,
not a resource — so instead of taking a fourth globe or a ring of its own it colours the glass
that had to be drawn anyway: green normally, **orange from 70%**, **red the moment you pull
aggro**, with a red flare pulsing over it above 80%. The percentage sits just above the globe.
Same party/raid gate and same never-in-arena gate as v5, which has one visible consequence
worth stating: **solo, and inside an arena, the target globe is drawn without a rim**, because
the rim *is* the threat element. Same for the instant before your first cast lands — at zero
threat the rim hides itself rather than reporting a threat relationship that does not exist.

### Every danger signal came across, on the property that actually exists

Health orange at 50% and red at 30%, threat green → orange → red plus the 80% pulse: all
still here. Each generation of this HUD changes the *name* of the property those escalations
set, and getting it wrong is invisible — WeakAuras drops a condition whose property does not
exist on the region **without an error and without any sign in the editor**. A bar escalates
with `barColor`, a ring or a globe with `foregroundColor`, and a plain texture — which is what
a rim is — with `color`. The threat escalations moved from the second to the third of those in
v9, and the property list was checked against the WeakAuras source before this build.

The zero-total guards the rings gained in v7 are all still in place too (`maxhealth <= 0`,
`maxpower <= 1`, `threatvalue <= 0`), because a progresstexture with a maximum of zero draws
**full**, not empty — a globe brimming with liquid the instant before your first cast lands
would be a lie told at the worst possible moment.

### After updating

**Nothing to delete.** This is a genuine in-place update: all 47 child UIDs from v8 are still
here, and ten of them changed hands to build the new layout —

| v8 aura | is now |
| --- | --- |
| `Mage - Orbs` | `Mage - Globes` (the layer) |
| `Mage - Player Orb` | `Mage - Life Cluster` |
| `Mage - Target Orb` | `Mage - Target Cluster` |
| `Mage - Target Mana` | `Mage - Power Cluster` |
| `Mage - Player Health` | `Mage - Life Globe` |
| `Mage - Player Mana` | `Mage - Mana Globe` |
| `Mage - Target Health` | `Mage - Target Globe` |
| `Mage - Target Threat` | `Mage - Target Globe Rim` (threat colour + threat %) |
| `Mage - Player Portrait` | `Mage - Life Globe Rim` |
| `Mage - Target Portrait` | `Mage - Mana Globe Rim` |

You should see 48 auras afterwards and no leftovers. **Uncheck *Arrangement* in the update
dialog if you have dragged the pack around** — v9 moves every position in the cluster.

Several auras change region type in place (ring → globe, ring → texture rim, model → texture
rim, ring → group). That is a normal data update for WeakAuras, but it is the most unusual
thing this pack asks of the import dialog: if anything looks structurally wrong afterwards,
delete the `Mage - Globes` group and re-import, which rebuilds it cleanly.

### Honest limitations

- **The geometry has not been rendered on a 2.5.x client.** Globe diameters, rim thickness,
  the placement of the numbers inside the glass and of the threat percentage above it are all
  computed, not measured. Every number is a named constant at the top of `generate.lua` —
  retune and re-run rather than dragging pieces in game, or the next update resets them.
- **The rims are drawn *behind* the globes, deliberately, and that is the one thing a live
  client most needs to confirm.** WeakAuras' `frameStrata = 2` is `BACKGROUND` — below the
  inherited strata the globes use, not above it — and `Circle_Smooth_Border` is a disc *with*
  a border rather than a hollow ring, so painting it on top would cover the liquid and the
  number. Behind, and 4px wider (`RIM_PAD`), the only part of it that shows is the 2px ring
  standing past the vessel's edge, which is exactly the glass. The 80% threat flare is the exception: it
  stays at the inherited strata and is drawn last, because an alarm behind the thing it warns
  about would be worse than none.
- **The globes are big and they sit apart.** That is deliberate — a vessel you read at a glance
  has to be a vessel, not a token. v9 placed them at `±150` on a band under the HUD; **v10
  moved them to `±270` beside the character** (see the v10 section for why `±170` and `±210`
  both collide). Each is 76px across including its rim, so the pair is 380px apart centre to
  centre with 304px of clear space between the two rims — a real eye movement rather than one
  glance, which is the honest cost of vessels big enough to read peripherally.
- **The target's mana is gone.** The layout has exactly three vessels and a target power
  read-out has nowhere to live. In arena, where enemy mana actually decides something, the
  per-opponent Enemy Mana bars in the PvP column still carry it (v5).
- **A globe is a coarser read than a bar.** A waterline in a circle is not linear in area:
  the middle of the range moves fastest and the top and bottom crawl. The percentage inside
  the glass is the precise read; the liquid is the glanceable one.

## v8 — one orb size, shared by all seven packs

v8 is **pure geometry**. It adds and removes no aura, moves no UID, and changes no trigger,
load gate, condition, colour, spell ID or region type — decode v7 and v8 side by side and the
only fields that differ are widths, heights, offsets, two font sizes and one texture path.

The complaint it answers was not about any single number, it was about **disagreement**. v7
shipped a 120 px target cluster next to a 100 px player cluster, and each of the seven class
packs had picked its own ring sizes (96, 84, 88 and 100 px outer rings across the repo). Side
by side that reads as sloppiness. Every pack now emits the same canonical set, declared as
named constants at the top of its build script so nothing can drift apart again:

| | v7 (mage) | v8 (every pack) |
| --- | --- | --- |
| Outer ring, **both** clusters | 100 player / 120 target | **104** |
| Middle ring | 72 | **78** |
| Inner ring (target only) | — | **54** |
| Portrait, both clusters | 40 | **46** |
| Threat halo | 124 | 108 |
| Cluster centres | ±260, −100 | **±260, −60** |

Both clusters therefore present the *same* outer diameter and the *same* portrait; the target
simply nests one more ring inside, because it is the side that carries threat. Player rings
are health 104 / mana 78; target rings are threat 104 / health 78 / mana 54.

The thin ring art is gone too. `Ring_10px`'s stroke is 10/256 of the drawn size — 4.7 px on a
120 px ring — so the threat arc read as a wire rather than a band. Every ring in the pack is
now `Ring_20px`, and the concentric arcs read as one system.

The read-outs collapsed to one set of offsets for both sides: health 14 pt at −60, power 11 pt
at −76, threat 11 pt at +60. They can be shared because every ring in a cluster is concentric
and each percentage is a `CENTER`-anchored subtext, so the offset is measured from the cluster
centre rather than from whichever ring happens to carry the text. v7 needed four different
numbers only because its two clusters had different outer diameters.

One mage-specific trap was handled on the way: the Arcane conserve bead is placed by
trigonometry on the mana ring's circumference, so resizing that ring without re-deriving the
bead would have left a mark floating in empty space. It is computed from the ring size
(`ringPoint`), and moved from `(31.56, −10.26)` to `(34.19, −11.11)` on its own — still on the
stroke centre (radius 35.95), still at 108°, still exactly the 30% mark.

## v7 — unit orbs: the bar stack leaves the middle of the screen

v7 is an in-place update of v6 (same UIDs — the import dialog offers **Update**, not a
duplicate group). It **adds six auras and rebuilds the seven** that made up the Resources
group; every one of the 42 auras v6 shipped is still here, and nothing outside that group was
touched — buffs, alerts, the cooldown row, the procs and the whole PvP layer are byte-for-byte
v6.

The three 172x14 bars stacked under your feet are gone. Unit state now lives **at the unit**:

```
        player orb, x = -260              target orb, x = +260

                                              47%   <- threat %
                                       .-----------------.
    .-----------.                      |  .-----------.  |
    |  .-----.  |                      |  |  .-----.  |  |
    |  |  O  |  |                      |  |  |  O  |  |  |
    |  '-----'  |                      |  |  '-----'  |  |
    '-----------'                      |  '-----------'  |
                                       '-----------------'
         84%
         71%                                  62%
                                              93%

  outer ring   health, green   |   inner ring   mana, blue   |   centre   3D portrait
  target only  the outermost thin ring is threat: green -> orange at 70% -> red on aggro
  numbers      health % 16pt white below the orb, mana % 11pt blue under that,
               threat % 12pt above the target orb
```

- **The player orb** sits left of your character: an outer green health ring, an inner blue
  mana ring, your own portrait in the middle, and the two percentages underneath. Both rings
  fade to 50% alpha out of combat exactly as the bars did.
- **The target orb** sits on the right and is **completely invisible until you have a
  target** — no target, no rings, no portrait, no numbers, and no empty frames left behind.
  It adds two readouts the pack never had: your target's health and (for casters) its mana.
  The portrait is a real 3D model of whatever you are targeting, so it works on NPCs and mobs
  without the pack ever knowing their class.
- **Threat became the outermost ring of the target orb**, which is where it belongs: threat
  is your threat *on that target*, not a property of you. It still runs green, turns **orange
  at 70%** and **red the moment you pull aggro**, and above 80% a fat red halo pulses over
  it. Same party/raid gate, same "never in an arena" gate as v5.
- **The mana conserve breakpoint is still there**, now as an amber bead sitting on the mana
  ring at the 30% mark, with the brighter bead popping in the instant you cross it. Still
  Arcane-only, still combat-only, exactly as v3 left it.

**Every danger signal the bars carried came across.** Health still turns orange below 50% and
red below 30% (where the Ice Block prompt fires); threat still escalates green → orange → red
plus the 80% pulse. Those recolours are a different mechanism on a ring than on a bar, and
getting it wrong would have been invisible: a ring has no `barColor`, and WeakAuras drops a
condition whose property does not exist on the region **without an error and without any sign
in the editor**. The rings use the property that actually exists, and it was verified against
the WeakAuras source before this build.

**Three rings gained a guard the bars never needed.** A bar with a maximum of zero draws
empty; a ring with a maximum of zero draws **full**. That is a real difference at the exact
worst moments — the instant before your first cast lands (threat total is zero), or the first
frames after a target change (max health has not arrived yet). Left alone, the threat ring
would have shown a complete circle, meaning "you are at the pull threshold", while its colour
stayed green. Each ring now hides itself in that state instead. The visible consequence: at
exactly zero threat there is no threat ring at all, where v6 showed an empty bar.

### After updating

**Nothing to delete.** This is a genuine in-place update: the health, mana and threat bars,
the threat flash and the two conserve-line textures were *rebuilt* into the orbs rather than
replaced, so they keep their UIDs and WeakAuras rewrites them where they stand. The old
`Mage - Resources` group is renamed `Mage - Orbs` and gains two sub-groups, `Mage - Player
Orb` and `Mage - Target Orb`. You should see 48 auras afterwards and no leftovers. (If you
ever *do* end up with a stale duplicate group from some earlier hand-edited import,
WeakAuras never deletes auras on import — right-click it in `/wa` and delete it yourself.)

**Uncheck *Arrangement* in the update dialog if you have dragged the pack around**, as
always: it resets positions to the string's defaults, and v7 changes a lot of positions.

Four elements changed region type in place (bar → ring, rectangle → halo). That is a normal
data update for WeakAuras, but it is the most unusual thing this pack has ever asked of the
import dialog: if anything looks structurally wrong afterwards, deleting the `Mage - Orbs`
group and re-importing rebuilds it cleanly.

### Honest limitations

- **The geometry has not been rendered on a 2.5.x client.** Ring stroke weights, the gap
  between the two rings, portrait framing and the placement of the numbers are all computed,
  not measured. Everything is in the `G` table at the top of `generate.lua` — retune and
  re-run rather than dragging pieces in game, or the next update resets them.
- **The conserve mark is a bead on an arc, not a line on a bar.** A position on a circle is
  slightly harder to read precisely than a tick on a straight bar. The rotation-based tick
  WeakAuras offers for rings was deliberately not used: sub-elements cannot carry a load
  gate, so a tick welded to the shared mana ring would have reappeared for Frost and undone
  the v3 audit that removed it. The bead keeps the gate *and* keeps its pop animation.
- **Two 3D model frames are heavier than two textures.** They are small, they only render one
  portrait each, and the target's does not exist without a target, but a live model is not
  free the way a coloured rectangle is.
- **The target ring is mana, not "whatever that unit uses".** A warrior or rogue target shows
  a health ring and no inner ring, rather than a blue ring reporting rage. The rings sit at
  `±260` from centre, clear of the Alerts column at `-150` and the PvP column at `+150`.

## v6 — the cooldown row shows what you CANNOT press

v6 is an in-place update of v5 (same UIDs — the import dialog offers **Update**, not a
duplicate group). It **adds nothing, removes nothing and moves no UID**: six icons in the
cooldown row change how they display, and that is the whole version.

Six of the ten cooldown icons now appear **only while their cooldown is running**, carrying
the swipe and the countdown, and vanish the moment the ability is back: **Presence of Mind,
Ice Block, Evocation, Counterspell, Blink and Invisibility**. The row is a dynamic group, so
the gap closes behind them — **absence is the readout**. An empty stretch of row means
everything there is available; two icons means exactly two things are down, and both are
counting back. Before this, all ten sat on screen permanently and merely dimmed, so the row
was at its busiest exactly when you had the fewest options — and you already know your own
spellbook. What you cannot know at a glance is what is *unavailable*, and for how long.

The desaturation went with them. Under the new rule every visible icon is on cooldown by
definition, so greying the whole row would have told you nothing and only made the icons
harder to tell apart; they now show in full colour with the countdown on top.

**Four icons deliberately stay visible at all times, because their glow is an instruction
and a hidden icon cannot glow:**

| Icon | Why it stays | What the glow means |
|---|---|---|
| Arcane Power | 3 min damage cooldown, pressed as the burn window opens | gold: it is up, and you are in combat |
| Icy Veins | both raid builds press it on cooldown — Frost's rotation is *Icy Veins and Water Elemental when possible, Frostbolt in between* | gold: it is up, and you are in combat |
| Summon Water Elemental | 3 min DPS cooldown, pressed on sight for the same reason | gold: it is up, and you are in combat |
| Cold Snap | its moment is a *sequence*, not availability | blue: Icy Veins **and** Water Elemental are both spent, so the reset is finally worth its 8 minutes |

Presence of Mind is the one judgement call worth spelling out: it is a damage cooldown, but
it is spent *inside* the burn window that Arcane Power's glow already announces, and it
shares Arcane Power's 3 minute cooldown, so a second glow would have been a duplicate cue for
the same moment. It is now a countdown that answers "when is the next window", which is the
question it actually gets asked. Everything else that converted is situational by nature —
an emergency button, a mana cooldown, an interrupt, a blink — and every one of them already
has a prompt in the alert flow that fires at the moment it should be pressed (Ice Block below
30% health, Evocation below 30% mana, Invisibility at 70% threat, Counterspell on an enemy
cast in arenas and battlegrounds). The alert says *press this now*; the row icon only has to
say *when does it come back*.

Nothing else moved: same load gates (including every Spell Known gate, so the row still only
shows spells you have actually taken), same positions, same alerts, same PvP layer.

## v5 — no threat bar in arena, and their mana on screen

v5 is an in-place update of v4 (same UIDs — the import dialog offers **Update**, not a
duplicate group). It **adds one aura and changes the load gate on two**; nothing else in the
pack moved. All three changes come from closing questions v4 had shipped as open.

- **The threat bar and the threat flash no longer load inside an arena.** An arena team has
  no threat table, so both were painting a meaningless number in the one place where you have
  the least attention to spare — and the flash *pulses*, which is worse than useless there.
  The party/raid gate they already had could not express this by itself, because an arena team
  **is** a party. They now also carry an instance-size gate that lists every instance type
  except arena: open world, 5-man dungeon, 10/20/25/40-man raid, and battleground.
  **Nothing changes anywhere else — including the open world.** That was exactly the doubt
  that kept this out of v4: WeakAuras only assigns the instance-size value inside a check for
  "am I in an instance", so it looked as though the value might be nothing at all while you
  are questing and the gate might match nothing and silently unload the bars everywhere
  outdoors. It does not — that check is a guard, and the function's last line returns the
  literal `none` for the not-in-an-instance case, which is one of the types the gate lists.
  Battlegrounds deliberately **keep** both: Alterac Valley has real NPCs with a real threat
  table, and the bar is honest furniture there.
- **Enemy Mana — one bar per opponent, arena only.** A mage does not drain mana, but a mage
  plays the mana clock harder than almost anyone: Counterspell exists to stop a healer
  spending it, Polymorph exists to stop them drinking it back, and "keep applying pressure or
  commit the burst now" is a read on how much the enemy healer has left. The new bar sits at
  the bottom of the PvP column, one row per opponent, with their name on the left and the
  percentage on the right. It turns **amber below 30%** (they are running low — deny the
  drink, keep them casting) and **green below 10%** (they are out; this is the kill window),
  matching the escalation language the health bar already uses.
  Two honest limits. Rows only appear for opponents whose *primary* resource is mana, which
  is what keeps warriors and rogues (who have no mana pool at all on 2.4.3, and would
  therefore show a permanently empty bar that reads as "go") off the list — the cost is that a
  druid in bear or cat form drops off the list until they shift back. And while the WeakAuras
  side of this is proven (the Power trigger accepts `arena`, registers per-opponent events and
  clones one row per opponent on TBC), whether the 2.5.x server pushes *continuous* power
  updates for arena opponents rather than refreshing on opponent changes is a client question
  no addon source can settle. Take it into one skirmish before a kill call depends on the
  exact number; the readout refreshes on opponent-frame updates at minimum.
- **CC ON ME's colour-coding is now confirmed rather than assumed.** No change to the pack —
  it works, and it was worth proving, because the mechanism has a silent failure mode one step
  away. Recolouring a glow from a condition only reaches the screen if the glow was built with
  a custom colour in the first place; without that flag the recolour is stored and quietly
  discarded, and the prompt would have glowed one single colour for every kind of crowd
  control while looking completely correct in the editor. This pack builds that glow with an
  explicit colour, so all nine categories are live.

## v4 — PvP layer

v4 is an in-place update of v3 (same UIDs — the import dialog offers **Update**, not a
duplicate group). It **adds nine auras and changes none of the 31 that were already there**.

**Nothing changes in PvE.** Every one of the nine new elements carries its own Instance Size
Type load gate — arena + battleground for most of them, arena alone for the ones that read
`arena1..arena5` (three as of v6, counting the v5 Enemy Mana row), since those unit ids do
not exist in a battleground. In a raid, a dungeon,
or the open world not one of them loads, and no existing element was touched: the raid HUD
is byte-for-byte the v3 HUD. The gate is per aura, not on the group, which is also what lets
the dynamic groups collapse the gaps.

Walk into an arena or a battleground and a second HUD appears:

**Three new prompts join the Alerts flow** (same language as the rest of the pack: they slide
in from below, glow, and fly away when they resolve).

- **COUNTERSPELL NOW** — appears only when your target is casting **and** Counterspell is
  actually castable **and** the target is hostile. It is the highest-value press a mage owns:
  8 seconds of school lockout on a 24 second cooldown, and a healer locked out of Holy for 8
  seconds is a kill window with no CC spent at all. Because the prompt cannot exist while
  Counterspell is down, it never trains you to ignore it — if it is on screen, press it. The
  icon desaturates while the target is outside the 30 yard range, which is your cue to close
  distance instead. There is deliberately **no spell filter**: TBC has no notion of
  "interruptible" that WeakAuras can read (WeakAuras disables that filter on TBC clients
  outright), so judging fake casts stays a player skill. Loads once Counterspell is trained.
- **CC ON ME** — one prompt for every loss-of-control effect, colour-coded by *category* with
  the remaining time under it, because the decision is never "am I CC'd", it is *which break
  works*: red stun (trinket, nothing else), purple fear (trinket), blue root (**Blink** — Blink
  breaks roots and never breaks stuns, so this colour is the difference between escaping and
  wasting your medallion), green polymorph (ride it out, any damage breaks it), amber
  silence / school lockout (your Frost school is locked, so Ice Block, Frost Nova and Ice
  Barrier are all gone — trinket earlier than you otherwise would). Not combat-gated: the
  opener lands before combat starts. This is also the only way to see a school lockout at
  all, since a lockout is not a debuff and no aura trigger can ever find one.
- **TARGET IMMUNE** — fires when your target gains an effect that makes your whole spellbook
  do nothing: Ice Block, Divine Shield, Cloak of Shadows (90% spell resist), Spell Reflection
  (your next cast comes back at you), Bestial Wrath / The Beast Within (uncontrollable, so
  Polymorph and Nova are wasted as well). Stop casting, re-pool, or swap. Two immunities from
  the generic list are **left out on purpose**: Blessing of Protection is physical-only
  (Frostbolt lands straight through it) and Deterrence is dodge/parry, so neither changes a
  single mage decision, and a prompt that fires when nothing is decidable is noise.

**A new "Mage - PvP" column** of state read-outs appears opposite the Alerts flow (it grows
downward on the right of the character, mirroring the alerts on the left).

- **Trinket DOWN** — visible *only while your medallion is on cooldown*, desaturated with the
  swipe running. Absence means ready, so in the normal case the column is empty and the
  question "do I still have my get-out-of-jail" is answered without reading anything. Tracked
  by exact item id (Medallion of the Alliance/Horde, plus the Mage Insignias) rather than by
  equipment slot, because a slot tracker would report "medallion down" whenever any *other*
  on-use trinket was fired — a false negative that gets you killed in the one decision this
  element exists for.
- **Will of the Forsaken DOWN** — same idea, and it only loads if you actually know the racial.
  On 2.4.3 WotF does **not** share a cooldown with the medallion (that arrived in 3.3), so an
  Undead mage really does carry two charges, and whether the second one is up is what decides
  whether the first gets spent early.
- **Enemy Trinket** — a 2 minute countdown per opponent, started when that opponent's trinket
  cast is seen (one row per arena opponent, arena only). Their trinket being down is what
  makes the next full Polymorph chain uncontested; a one-shot "they trinketed!" flash without
  the countdown would change nothing. **This is an inference, not a read** — no 2.5.x API
  exposes another player's cooldowns, so if an opponent trinkets out of sight nothing starts,
  and the timer assumes the 2 minute honor medallion.
- **CS LOCKOUT** — an 8 second bar that starts when *your* Counterspell lands (your interrupt
  only; a partner's does not light it). That bar is the go: burn Icy Veins, Water Elemental
  and Arcane Power now, and do not spend Polymorph on a healer who cannot cast anyway.
- **Polymorph OUT** — your own sheep on each arena opponent, with the remaining time, one row
  per target. It says two things at once: *do not touch that unit* (any damage breaks it and
  the sheep regenerates roughly 6% health per second, so hitting it hands the healer free
  health) and *this is exactly how long the rest of the team has to work*. It glows in the
  last 3 seconds — re-poly now, or the healer is free. `ownOnly`, so another mage's sheep
  never appears here.

### This is NOT diminishing-returns tracking

The Polymorph row is a plain remaining-duration timer on your own sheep and nothing more. It
does **not** know that Polymorph shares the Incapacitate category with Sap, Gouge, Freezing
Trap, Wyvern Sting and Repentance, it does not know whether the next one lands at 100%, 50%
or 25%, and it does not know about anyone else's CC. Real DR tracking needs a custom trigger
maintaining its own category→timer table (which is what Gladius and Diminish exist for);
WeakAuras ships no DR prototype and no DR library, and this pack contains no custom code at
all. Faking it with an 18 second timer would model the *reset window* rather than the
category state — wrong the moment two spells share a category, and worse than having nothing,
because an incomplete DR tracker gets trusted.

Three more things were considered and deliberately left out for the same reason:

- **Enemy cooldowns** cannot be read on 2.5.x at all. The enemy-trinket countdown above is the
  only honest form: a timer you start because you saw the cast.
- **Enemy spec detection** does not exist on TBC either (enemy *class* is readable, spec is
  not), so nothing here branches on what the other team is playing.
- **The threat bar and threat flash still load in arena** — *fixed in v5*, once the open-world
  behaviour of the instance-size gate was confirmed from the source rather than guessed at.
  See the v5 section above.

**One thing to smoke-test before you rely on it.** The CC ON ME prompt is driven by
WeakAuras' *Crowd Controlled* trigger, which reads the client's loss-of-control API. That
trigger was unavailable on Classic/BCC in WeakAuras 3.5.0–5.1.x and was re-enabled in 5.2.0,
but nothing in the WeakAuras source proves the 2.5.x client actually populates the API. Get
sapped and get kicked in a duel and confirm the prompt fires. If it does not, the failure is
silent and harmless — the prompt simply never appears, nothing else is affected. No aura-based
fallback is shipped alongside it, because two prompts for one event is worse than one that
might be quiet, and an aura-based fallback could never see school lockouts anyway.

Every new game id was verified on wowhead.com/tbc for this build: Counterspell 2139 (8 s
lockout, 24 s cooldown), Will of the Forsaken 7744 (2 min), the "PvP Trinket" cast 42292
(120 s, cast by both medallions), items 37864 / 37865 (Medallion of the Alliance / Horde,
2 min) and 18859 / 18850 (Insignia of the Alliance / Horde, **Mage**, 5 min), Polymorph
118 / 12824 / 12825 / 12826 plus Turtle 28271 and Pig 28272, and the immunity list 45438,
642, 1020, 31224, 23920, 19574, 34471. Aura triggers carry every rank as strings; the
cooldown, Spell Known and Action Usable triggers carry the numeric rank-1 id; item triggers
carry the numeric item id, never a name.

## v3 — per-spec audit: each spec sees only what it presses

v3 is an in-place update of v2 (same UIDs — the import dialog offers **Update**, not a
duplicate group) and adds, removes and moves **nothing**: it only changes which spec loads
what. The test was tightened from "can this spec *cast* it" to "does this spec *press* it as
part of playing well", which is the question the HUD actually answers. Three elements failed
it somewhere:

- **Frost no longer sees the mana conserve breakpoint** (the amber line and its lit crossing
  marker are now gated on Arcane Power, 12042). The line marks where Arcane stops spamming
  Arcane Blast and starts the 3x Arcane Blast / 3x Frostbolt conserve cycle — it is a switch
  between two rotations. Frost has no second rotation to switch into; it is Frostbolt spam all
  the way down, with Ice Lance while moving. Its actual low-mana actions are Evocation and the
  mana gem, and both already have their own prompts carrying their own thresholds, so for
  Frost the line marked a mana level nothing was done about — and the lit marker put motion on
  the HUD for a non-decision.
- **Arcane no longer sees the Ice Lance / SHATTER prompt** (inverse gate: `not_spellknown` =
  Arcane Power 12042, the 31-point Arcane capstone and therefore a true spec discriminator —
  no deep-Frost build can reach it). Ice Lance is *trained* at 66 by every mage, so gating on
  Ice Lance's own id hid the prompt while levelling but not from the wrong spec: 40/0/21
  Arcane loaded a reactive prompt it never acts on. Arcane's rotation is Arcane Blast with
  Frostbolt as the mana filler, and the Arcane guides state outright that the spec uses
  neither Ice Lance nor Frost Nova/shatter combos; it also has neither Frostbite nor the Water
  Elemental, so two of the three ways the freeze window opens do not exist for it. Frost keeps
  the prompt — Ice Lance into a frozen target is its one reactive button outside a raid.
- **The Evocation prompt is Spell Known gated** (12051), like its cooldown icon already was.
  A cooldown trigger on a spell you have not trained reports "ready", so below level 20 the
  prompt fired for a button that does not exist. Neither spec at 70 is affected.

**Requires WeakAuras 5.4.0+ for the inverse gate.** The `not_spellknown` load argument does
not exist before that release; on an older client the unknown field is ignored and the SHATTER
prompt simply loads for everyone, exactly as it did in v2, so the pack degrades gracefully
instead of erroring.

Everything else survived the audit unchanged, and deliberately so:

- **Both specs press Icy Veins and Cold Snap.** The Arcane raid build is 40/0/21 — "Arcane
  IV" — and spends its 21 Frost points precisely on Icy Veins plus Cold Snap, so it can use
  Icy Veins twice per burn. Cold Snap's *glow* is still the Frost sequencing cue (both Icy
  Veins and Summon Water Elemental spent); for Arcane the icon is availability only, since
  the mage never has a Water Elemental to bank. That is a condition, not a gate, so it is
  left for a future version rather than smuggled into a gating pass.
- **Clearcasting stays ungated**: the standard Frost raid build is an Arcane Concentration
  build, exactly like Arcane's, so the free-cast proc is a real decision for both.
- **Ice Block, Counterspell, Blink and Invisibility stay** for whoever has them. They are
  emergency and utility buttons both specs press under pressure, and each is gated on its
  own id, so a build that lacks the talent never sees it — no spec gate needed.
- **The mana gem prompt stays ungated**: both specs gem in their regen phase, and the Item
  Count trigger already hides it from anyone without a gem in their bags.

## v2 — rotation fixes

v2 is an in-place update of v1 (same UIDs, so the import dialog offers **Update**, not a
duplicate group). A rotation review found the pack rendered state faithfully but left
several real decisions unrendered, and let three elements fire when nothing was decidable.
What changed:

- **Mana now shows the burn/conserve breakpoint.** v1's mana bar was a bare percentage with
  no threshold — the single most important Arcane decision ("keep spamming Arcane Blast, or
  drop to the 3x Arcane Blast / 3x Frostbolt conserve cycle?") had no element at all. A thin
  amber line now sits at 30% of max mana with a brighter line that pops in the moment you
  cross it (in combat only — drinking afterwards is not a decision). 30% is a percentage
  proxy for Icy Veins' "1500-3000 mana is usually a good time to start this rotation": raw
  mana moves with gear, the fraction of your pool does not.
- **The burn windows have a clock.** A cooldown trigger reports Arcane Power's and Icy
  Veins' 3-minute recharge, never the 15 s / 20 s window they actually buy you, so v1 could
  not tell you whether you were still inside one. Two new 34x34 buff timers flank the shared
  buff slot: Arcane Power (12042) on the left, Icy Veins (12472) on the right. Arcane Power
  glows in its last 5 seconds — that is the Presence of Mind + Arcane Blast finisher cue.
- **Mana gem prompt.** Mana Emerald (item 22044, ~2400 mana, 2 min) was tracked nowhere. It
  now prompts in the alert flow below 70% mana — low enough that the restore is never
  wasted — and only when a gem is actually in your bags, so a mage who forgot to conjure is
  not nagged about a button they do not have.
- **Ice Lance / Shatter window.** Ice Lance (30455) does triple damage into a frozen target
  and v1 had no frozen-target detection at all, which left deep Frost with no reactive
  decision outside a raid. A new prompt fires when your target is held by Frost Nova (all
  five ranks), Frostbite (12494) or the Water Elemental's Freeze (33395) **and** Ice Lance
  is castable. Deliberately not `ownOnly`: your pet's Freeze and a partner's Nova open the
  same window. Bosses are root-immune, so the prompt stays silent in raid.
- **Cold Snap is a sequencing prompt, not a use-on-cooldown icon.** Cold Snap resets the
  Frost cooldowns, so pressing it while Icy Veins or Water Elemental are still up throws the
  reset away. The icon still shows its own 8-minute cooldown, but it only glows once both
  Icy Veins **and** Summon Water Elemental are on cooldown and Cold Snap itself is up.
- **Three cooldowns glow when they are up, in combat.** Arcane Power, Icy Veins and Summon
  Water Elemental are press-on-cooldown, so they now glow gold the moment they come back —
  gated to combat so the row is still while you are riding to the next pull. The reactive
  cooldowns (Ice Block, Counterspell, Invisibility, Evocation, Presence of Mind) do not
  glow; their prompts live in the alert flow instead.
- **Threat bar is party/raid only.** v1 gated the flash overlay and the Invisibility prompt
  on `ingroup` but not the bar itself, so solo — where you are always the aggro target — it
  sat pinned red for every quest mob and trained you to ignore it.
- **Clearcasting is combat-gated**, like the four other alerts. An Arcane Concentration proc
  from a pre-pull cast is not a decision.
- **Ice Barrier warns before it drops.** The timer glows in its last 5 seconds. The MISSING
  alert can only fire once the shield is already gone, which conceded an unshielded gap on
  every fight; a 60 s shield on a 30 s recast should be refreshed pre-emptively.
- **Health bar has colour tiers** (orange under 50%, red under 30%), completing the danger
  pattern whose action half — the Ice Block prompt at 30% — was already there.
- **Every cooldown icon is now Spell Known gated.** v1 left Evocation, Counterspell and
  Blink permanently lit for mages below level 20/24/32.

## Layout

**The Sill** (v14 — ONE 102×37 instrument strip, centred under the character at `(0, -110)`,
replacing the ring cluster that sat at `(-270, 40)` from v11 to v13. The geometry is the canonical
set shared by all seven class packs, so any two of them can be diffed and match: 100px rails,
4 / 11 / 11 / 6 tall, at local y +15.5 / +7 / −5 / −14.5 on a 102×37 plate). Each rail is a
`progresstexture` in `orientation = "HORIZONTAL_INVERSE"` — "Left to Right" — on WeakAuras'
bundled `Square_White` art, so the value is **length along a 100px scale where one pixel is one
percent**, with the unfilled part drawn as a black 55%-alpha track on the same art so a partial
rail reads as a gauge rather than as a shape appearing out of nothing. Behind all four is the
**sill plate**: a 102×37 black slab at 45% on the flat, uniform `Square_White` art — no border and
no rounding, because that texture has neither — the SECOND child of the group, which is what makes
an 11px rail and an 11pt number survive a snowfield or a lava floor. It carries the UID the live 3D
portrait used to. Behind *that*, as the FIRST child and therefore the furthest back of all, is the
**alarm rim**: 108×43, the plate plus 3px per side, additive red at `{1, 0.1, 0.1, 0.85}`, so only
the protruding band is visible and the rest hides behind the plate. Both WeakAuras squares are
*filled* — `Square_White_Border.tga` decodes to 98.44% fully-opaque pixels with a minimum RGB of
167 across its entire 240×240 inset core, i.e. a filled square with a dark bevel at its edge, **not
an outline** — so no single region can trace an edge, and the alarm reads as an edge purely because
it is oversized and underneath. Both halves are asserted on every build.
Top to bottom: the **threat rail** (100×4) is green, orange from 70%, red the moment you pull
aggro, with a white notch at the 70 mark and the alarm rim pulsing red *around* the instrument
above 80%
— mage burst has no passive threat dump, so this rail is the warning system, and it is the one
thing here the default UI never shows. It is party/raid only and never loads in an arena (v5),
and it hides itself at zero threat rather than reporting a relationship that does not exist, so
most of the time the strip is three lanes: **the threat lane appears only when threat is real**.
Its percentage subtext still exists at index 1 but ships switched off — the notch is the read.
The **health rail** (100×11) is next, green, with the percentage **11pt at the right-hand end,
inside the rail**, running orange below 50% and hot red below 30%, where the Ice Block prompt
fires, and three faint hairlines marking the quarters. The **mana rail** (100×11) follows, blue,
its percentage in the same place — mana is the mage's real clock, since Arcane plans its pool to
hit zero as the boss dies — and it carries the conserve breakpoint as a **full-height waterline
at x = −20** (the 30% mark: `x = 30 − 50`), dim by default with a brighter, wider line popping in
the moment you cross it. The **arcane lane** (100×6) is the bottom rail: three pips for Arcane
Blast stacks, and the rail itself drains with the debuff's remaining window, turning red at three
stacks. The plate, both unit rails, the conserve waterline **and the arcane lane** each carry the
`inCombat == 0 → alpha 0.5` condition — the plate is a sibling of the rails, so nothing propagates
it and every visible region has to hold it itself — so the HUD breathes with the fight; the threat
rail, the lit waterline and the alarm frame carry no fade because none of them can be on screen
out of combat in the first place. Since v3 the conserve
waterline and its lit marker load for Arcane only: they mark a rotation switch that Frost does
not have. Every rail hides rather than showing a misleadingly full bar when its maximum is zero,
because a `progresstexture` with a zero total draws **full**, not empty.
There is deliberately **no target-side anything** since v12: the target's health is on the target
frame and the nameplate already, and enemy mana lives in the arena PvP column (v5), where it
decides something. Every percentage is a sub-region **of its own rail**, anchored to that rail's
centre and offset to its right-hand end, so each number appears and disappears with the gauge it
belongs to.

**Buffs** (static timer row under the character). Arcane and Frost are mutually exclusive at 70,
so both 40x40 centre icons share the one slot — although since v14 only Frost's fills it, because
the Arcane Blast stack tracker left this row to become the strip's bottom rail (the row is a
static group, so nothing else shifted). Ice Barrier (all six ranks) shows its remaining uptime
for Frost and glows in its last 5 seconds so the reshield lands before the shield lapses;
pushback protection is completed Frostbolt casts, so the timer is a rotation element, not
decoration. The two 34x34 burn-window timers flank that slot: Arcane Power left, Icy Veins
right, each appearing only while the buff is actually running.

**Alerts** (glowing 40x40 prompts in an upward flow left of the character). Each slides in
from below and flies away upward when it resolves, and the stack collapses gaps
automatically. Clearcasting (12536) fires on the Arcane Concentration proc in combat — the
next spell is free, weave it immediately. The Evocation prompt fires when mana drops below
30% **and** Evocation is off cooldown, once you have trained it. Barrier MISSING fires when Ice Barrier is absent
**and** its 30 s recast is ready, so it stays quiet during the cooldown instead of nagging.
The Ice Block prompt fires below 30% health **and** only when Ice Block is ready. The
Invisibility prompt fires at 70%+ threat **and** only when Invisibility is ready, in a party
or raid. The mana gem prompt fires below 70% mana **and** only with a Mana Emerald off
cooldown in your bags. The SHATTER prompt fires when your target is frozen **and** Ice Lance
is castable, with the freeze window running as the icon's swipe and bottom timer — for every
build except deep Arcane, which does not use Ice Lance. Every
prompt requires all of its conditions at once (`disjunctive = "all"`), so an alert appearing
always means the button is pressable right now, and all six of these are combat-gated. Three
more prompts share the flow in arenas and battlegrounds only — COUNTERSPELL NOW, CC ON ME and
TARGET IMMUNE (v4) — and none of them ever loads in PvE.

**Cooldowns** (auto-collapsing horizontal row of 32x32 icons below the character). Cooldown
text on, mouseover tooltips on. Every icon is Spell Known gated so only spells you have taken
(and trained) take a slot and the row stays tight: Arcane Power (12042) and Presence of Mind
(12043) for Arcane; Icy Veins (12472), which both the 40/0/21 Arcane build and Frost talent
into; Summon Water Elemental (31687), Cold Snap (11958) and Ice Block (45438) for Frost;
Evocation (12051), Counterspell (2139), Blink (1953) and Invisibility (66) once trained.
Since v6 the row is split by how the ability is used. Four icons are always on screen because
their glow is the instruction: Arcane Power, Icy Veins and Water Elemental glow gold the
moment they are up in combat (all three are pressed on cooldown), and Cold Snap glows blue
only when both of the cooldowns it resets have been spent, which is the one moment the reset
is worth spending. The other six — Presence of Mind, Ice Block, Evocation, Counterspell,
Blink and Invisibility — are situational, so they appear **only while their cooldown is
running**, in full colour with the countdown, and disappear when the ability is back. The
group collapses the gap, so absence means available: an empty row is everything up.

**PvP column** (v4, arena and battleground only — invisible everywhere else). A dynamic group
at +150, mirroring the Alerts column on the other side of the character and growing downward:
Trinket DOWN and Will of the Forsaken DOWN (32x32, desaturated, present only while the charge
is spent), the Enemy Trinket countdowns (32x32, one clone per opponent, arena only), the
140x12 CS LOCKOUT bar, the Polymorph OUT rows (36x36, one clone per opponent, arena only), and
since v5 the 140x12 Enemy Mana bars (one row per mana-using opponent, arena only, name on the
left and percentage on the right, amber below 30% and green below 10%).
It is a dynamic group because three of its children are clone sources; clones inside a static
group would stack on one spot. In the quiet case — trinket up, nobody sheeped, nothing
interrupted — the column holds only the opponents' mana.

## Spec gating summary

| Element | Gate |
|---|---|
| Arcane Lane (the stack rail, v14), Arcane Power CD, Arcane Power window | Spell Known 12042 (Arcane Power) |
| Mana conserve waterline + lit crossing line | Spell Known 12042 — **Arcane only** (v3) |
| Presence of Mind CD | Spell Known 12043 |
| Icy Veins CD + Icy Veins window | Spell Known 12472 (loads for deep Arcane *and* Frost) |
| Summon Water Elemental CD | Spell Known 31687 |
| Cold Snap CD | Spell Known 11958 (both raid builds take it) |
| Ice Block CD + Ice Block prompt | Spell Known 45438 |
| Ice Barrier timer + Barrier MISSING alert | Spell Known 11426 (rank 1) |
| Ice Lance SHATTER prompt | Spell Known 30455 (learned at 66) **and NOT** 12042 — hidden from Arcane (v3) |
| Evocation CD **and Evocation prompt** (v3), Counterspell CD, Blink CD, Invisibility CD | Spell Known 12051 / 2139 / 1953 / 66 |
| Invisibility prompt | Spell Known 66 **and** party/raid only (`ingroup`) |
| Threat rail (the top lane, v14), Alarm Frame | party/raid (`ingroup`) **and** every instance type **except arena** (`size`, v5) |
| All six PvE alert prompts | in combat only |
| CC ON ME, TARGET IMMUNE, Trinket DOWN, CS LOCKOUT (v4) | arena **or** battleground (`size`) |
| COUNTERSPELL NOW, CS LOCKOUT (v4) | arena/battleground **and** Spell Known 2139 |
| Will of the Forsaken DOWN (v4) | arena/battleground **and** Spell Known 7744 (Undead) |
| Enemy Trinket, Polymorph OUT (v4), Enemy Mana (v5) | **arena only** — they read `arena1..arena5` |
| Everything | class MAGE |

Seven elements carry no *spec* gate after v14 — the health rail, the mana rail, the sill plate,
the threat rail and its alarm frame, Clearcasting and the mana gem prompt — and every one of them
is a decision both Arcane and Frost make (the threat rail and its frame do carry a group gate, and
since v5 an instance-size gate as well; neither is a spec gate). The other three that used to be
on this list were the target cluster's health ring, portrait and outer track, which v12 deletes.
`tools/spec-preview.lua` models Spell Known gates only, so from v4 it lists the
PvP elements under "ungated" or under their spell gate; read that list together with the
table above, because every one of them also carries the instance-size gate and none of them
loads in PvE. The inverse gate (`use_not_spellknown` / `not_spellknown`, WA 5.4.0+) is used
once, on the SHATTER prompt; `use_exact_not_spellknown` is deliberately left unset so the
rank-1 id resolves through the spell name to whatever rank the player has. Audit any future
change with `lua5.1 tools/spec-preview.lua mage`, which decodes the shipped string and prints
each spec's loaded set.

Two IDs are worth calling out because TBC reshuffled them relative to the classic era:
**Cold Snap = 11958** (8 min CD) and **Ice Block = 45438** (5 min CD, Frost talent). Every
spell ID in the pack — the twenty-six of the PvE layer (17 distinct spells: Ice Barrier
contributes six ranks and Frost Nova five) and the seventeen added by the v4 PvP layer — plus
all five item IDs (**Mana Emerald 22044**, medallions **37864**/**37865**, mage insignias
**18859**/**18850**) were verified on wowhead.com/tbc before this build. **Neither v5 nor v6
adds a single new game ID** — v5's one new element reads a resource rather than a spell, and
v6 adds no element at all, only changing when six existing icons draw. The item triggers
(item cooldown + item count) and the PvP layer's Cast, Action Usable, Crowd Controlled, Spell
Cast Succeeded and Unit Characteristics triggers are the only ones in the pack not built by
the shared factory; their field names come straight from the matching WeakAuras prototypes,
and the item ones take the numeric item ID, never a name.

## Regenerate

`lua5.1 tbc/mage/generate.lua` from the repository root (run
`tools/tbc-weakaura-creator/scripts/setup.sh` once beforehand to fetch LibDeflate and
LibSerialize). The script is fully deterministic — fixed UID seed 20260816, no time or
environment inputs — so rebuilding produces a byte-identical `all-specs.txt`
(sha256 `4cc485a8f3ffb85b61c8f4d9af3c9bdfd1adfba155c2fa2ab4583dcf49ed9ac5`, 10025 chars,
44 auras). It round-trip verifies the encoded string, **re-decodes it and re-proves the
geometry** (v14: the sill's absolute position walked from the real parent chain, the rail canon
on every lane, the subregion layout, the draw order, the alarm rim's +3px-per-side size *and* its
`cc[1]` position, and a rectangle scan of the **108×43 alarm envelope** against every other
element with dynamic groups projected six children deep), and checks UID continuity
against the committed `all-specs.txt` **before** overwriting it; `changed` must stay 0 so in-game
re-imports offer *Update* instead of duplicating the group. v2 added six auras and changed
none of the 25 v1 UIDs (`stable=25 changed=0`); v3 added none and changed none of the 31
(`stable=31 changed=0 parentSame=true`) — it edits load conditions only; v4 added nine and
changed none of the 31 (`stable=31 changed=0 parentSame=true`); v5 added one and changed none
of the 40 (`stable=40 changed=0 parentSame=true`) — its other two edits are load gates, which
move no UID; v6 added none and changed none of the 41 (`stable=41 changed=0
parentSame=true`) — it edits `genericShowOn` and one condition on six cooldown icons, and
every other aura decodes byte-identical to v5; v7 added six and changed none of the 42
(`stable=37 changed=0 parentSame=true`, and all 41 previous child UIDs retained). `stable`
reads 37 rather than 41 because four of the rebuilt auras were also **renamed** — the
continuity check counts an aura as *stable* only when its id is unchanged, and counts a
`missing` UID as a hard failure, which is the number that matters: it is 0. The four renames
are `Mage - Resources` → `Mage - Orbs`, `Mage - Health` → `Mage - Player Health`,
`Mage - Mana` → `Mage - Player Mana` and `Mage - Threat` → `Mage - Target Threat`; each keeps
its own UID, so each updates in place rather than arriving as a new aura. v8 added none,
removed none and renamed none — `stable=47 changed=0 parentSame=true` with `missing=0` and
the same 47 child UIDs on both sides, which is the strictest result this check can report.
v9 also adds none and removes none: `stable=37 changed=0 retained=47 missing=0
parentSame=true`, i.e. all 47 v8 child UIDs are still here, and `stable` reads 37 because ten
of them were renamed as the rings became globes (the mapping is tabled in the v9 section
above). Two of those ten are the portraits: `Mage - Player Portrait` and
`Mage - Target Portrait` are *rebuilt* as the life and mana rims rather than deleted, which is
what keeps the update free of orphans even though the HUD no longer draws a portrait.
v10 adds none, removes none and renames none — `stable=47 changed=0 retained=47 missing=0
parentSame=true`, the same strictest-possible result v8 reported, because the two things it
changes are position offsets and one **appended** sub-region per globe. Appending is what keeps
that true for sub-regions as well as auras: conditions resolve `sub.N` by index, so a new
sub-region may only ever go on the end.
v11 adds none and removes none either: `stable=38 changed=0 retained=47 missing=0
parentSame=true`, i.e. all 47 v10 child UIDs are still here, and `stable` reads 38 because nine
of them were renamed as the globes became rings (the mapping is tabled in the v11 section
above). Two of those nine are the globe rims: `Mage - Life Globe Rim` and
`Mage - Mana Globe Rim` become the two live portraits, which is the exact reverse of the v9 hop
that turned the portraits into rims — the same UIDs have now been a portrait, a rim and a
portrait again, and no import has ever orphaned one. A third, `Mage - Power Cluster`, becomes
`Mage - Target Ring Track`: the ring layout needs two cluster groups where the globe layout
needed three, and a UID that disappears is a hard failure, so the freed slot takes the target's
outer track rather than being dropped.
That constraint is also *why* v7 is a rebuild rather than a delete-and-recreate:
`W.assertUidContinuity` fails on any UID that disappears, so the bars could not simply be
dropped and replaced with new orb auras, and in v9 the rings and portraits could not be
dropped and replaced with globes either — and the in-place transform is the better outcome
anyway, since it leaves nothing orphaned in the player's collection.

**v12 is the first version to spend that constraint rather than obey it**: it removes four auras
(48 → 44), reporting `stable=42 changed=0 retained=43 missing=4 parentSame=true`. A non-zero
`missing` is normally a hard failure, so the four ids are **declared** — in `generate.lua` as a
`REMOVED_IN_V12` list passed to `W.assertUidContinuity`, and as `WA-REMOVED (v12):` comment lines
that `tools/verify-packs.lua` reads when it repeats the check against the last *committed* string.
Only ids tagged with the version the pack currently ships are honoured, so the licence expires by
itself at v13; anything else that disappears still fails, and `changed` is never forgivable. The
four freed UID slots are **not** reused — the `W.uid()` calls still happen in their original
positions and their results are discarded — because deleting a call would shift every UID after it
and turn the in-game Update into forty-odd duplicates, and because inventing a region to absorb a
freed slot is exactly how v11's target ring track came to exist. Future versions must keep
the seed, never reorder existing `W.uid()` calls, and append new auras at the end of the
creation order — after the retired slots. One import-time note for users: the Update dialog's
*Arrangement* category is checked by default and will reset any positions dragged in game back to
the string's defaults — uncheck it, or report the coordinates so they can be baked into the
script. And unlike every previous version, v12 leaves something behind on purpose: WeakAuras
cannot delete what an import does not mention, so `Mage - Target Cluster` and its three children
must be deleted by hand once (see *After updating*, above).

**v14 hands `W.assertUidContinuity` no allowance list at all**, which is the strict default
restored: v12's licence expired at v13, the four deleted ids are absent from both sides of the
comparison, and this version adds and removes nothing — `stable=35 changed=0 retained=43
missing=0 parentSame=true`. It re-types five regions (a model into a texture, an icon into a
progresstexture, three rings into rails), resizes nine, re-parents nine and re-orders one group's
children, and **not one of those touches the UID stream**: every region is still created by the
same `W.uid()` call in the same position, and the four retired slots are still drawn and thrown
away. `stable` reads 35 rather than 43 because eight auras were renamed, listed in the v14 table
above; each keeps its UID and updates in place. The one import-time note that *reverses* for this
version: **leave the Update dialog's *Arrangement* category checked**, because the re-parenting,
the re-ordering and the move to `(0, -110)` all travel in it, and unchecking it leaves the rails
at their old ring geometry.

## Import string (v14)

```
!WA:2!T3xd0TXX9D6rWFidzNir9HLL)cw2svu2wIaGGFOiBhaqqjibcaTaKuswNawaSa7kcS7QDxqsqFo5eDCJAVExszUxExYLRnp0w37ADZhmooPxVMKY26KMM8U5yB8TTVxV0Q(rutV3LEk3D9AsAA)pZSl(IaqKuIoYoNFpdU7SZm7mZ)F))9))mZ)DeAIEY(XFIl)ilNHp7u50uudQuur7eoC4iUJ(oKp1EYQiBOPuSOqUGIsfZPjiVh1EgJVGGRNYv8I8ve0CLqQyXRKrrlNGwaRArDRbkkn3C8A5CLurPOHKQ2SXYNxxWaLrLhQed17NwjjdeeQi)Az5LfCTFxJQPOBKHvxIAvyfzKTuvtOGKICYkQcCf0ukRwLLLesZjChlkjNxrReVbKdNlYEaRxGqihlZx2qurlMk5X6oZa9N8sfCQXNLMWaC6g8AgoZKxswsx0za4pgoN3qtQqbbn9O7xZ6YpCadYBNVSgVNLi)QRkuSOuo990tFbkdfkJkD0yEA6HZP78k6LZimn0vtuoFEPzxmvq)jsMkrs)CjR9O4AcWJ4sepuKixRSUqOzH2vcwnKMtMVKGUZQ5eYa1aPZRD8qrIp64rwOSSvZY5I5K0VqzzO3mTGh(Ifv3gp96KSNpMsoHx52SgUcLRGG62sCXYGeW1OLlw01KIsgclXEkBW(UxGxwInyoaE7JUKaVUqcdqIvWq8UW7oGSISWY5G(pjhPiJjA6cWGAo95jzL0kXhoqjEj5rXhcka(W4(WUXEG)UJwtzbDHI5JRijBKjyOOjdXTxPCQBZcCrqvUIqgsVgKbbnz(ItaVl4T(ClMxdgzGwfVbVJRXlNfeWJssI82ZKiixOqrRAOKDAw(3C8D6PSuUfpqbFxCoJtRMmWWC6z5lk4Okih4OqlDBKtyzyqWrvspsIbzcuuHpNZfzVgARf77YpcgvtjbVPF6AQe(lYRvYfTX0Cpb0vmeQLTKIAc8gU44LkwlTJlWx0qKL2wTsBmEzEwk3FJPeeAxcAtl4kIKSG6U7WJmQ3Qy6xrGFW3o(oW3jcFx4bW3Ti2zX7gVf89GV37a)oCIFNuvg8wDI3MtCpG83jEhoX70jExr3p(((WGS7(X7ba84ha)G4hYj(HXpc2f(rX7nn(XCIFC8(W73j(NaFaCVVYTHpi(jWp5DJFkcmQvOG3Rp4a3p2hGhWoWd(C4HCGhgFe87ceL4JUyU(6R)Gtlp6zNBc8Z4a)SoXVBhy)oXbCIdcYgxqNZX1meM1OSMWKA8QeLa1DemI)XINmwGi(dEs)Jms4KHNieRJ96W79biDMLbvWuguzJAwJ0vzxoor7gyjkiyaDZRuppKhKEHA5FVd1hmOO2tTesPaAh8gkA79zEAoQ(U6wTK8jKmktvHOJFTmY9oCYLLrdtWxUz)C79DOH8bIMmLK00u0arhcVfnREjiVwitrb5CKUQhO3rgoA)iFE8UZOQjaOC69WJpxv(IQI8XlxuxyEBv7ECtlYkelQBdiCYQjyiKstXGMvutqLZOEKWe9188zfoN)C5IjRFUjf4NYpHZ8CJjKtI)CjzTA9ZX4IsrPHoKrbEMeMjWTK)JaOvoAd0bWeQZBqAGcIZx)TF0f5pz(4HgvzY8twIItauqgrbPcIgtMHMpbrCGFYfisUSf511tVi5sjzQTK0ZtUrhmLicszyq0yxCLkd2SCQzLJDHNA)47jDanEjGvMwd7pJo8WIcbgZ)XcHNAxy10baM)SqwDgGuxWftZbM6mQK2J60WlbSrzuPeVCApgcYa0Ag4fvjpWuNod7604dNMBgPCgI)rmimEmCu8UoVLMhfGIhpdJMWsdK20jwFstXr1ucBUmQ7GGuDfuKNy2tqts3qkRUTs8Z3szBagINKqiqGE9tGE4tZqD4Zq4holxGiHIciTdUFUSIczNAu89DhZpnVMepafNxsoOsPm8gCtZxSSaAVkQ79PFATSI8Yfe03Z(XxIYDoVQgrjXOcMF)43dudoWV3fkXpRiRxEPE6JuWJ(045jfbHFrm)6NrjvlivC62G3cryh5DGZiIZsWwbg(ygHMqvBAJ82ylSWjX5be1e4cPXxGiYXY7hRGvzab8fPjPr)TYx)YhjdiL0svbX(7Si4nSiFUluw3qi3y8ZUP63ijVjSZ43UBFGvf4fPUJ6iEIRve0OCoXf1j26y6qPBmpJQaokXYdNErEzd08aNGFcq99TlOBEfy0UaO3PNqPSwwHd(G32MiDBkydKOGeolTV7)i1eg4e4lT3bPsHNXskWOLgGsl5a)IxlFT3k1TRAfLJVaKm(soyYERctk2WeiLBpSFHQa)bRvOfzSNuqt7f)p7bV8UaswO7NsxKpNYmN2YZYfOPr(zP9vJdEF7tDRnK36ogQ(K1YEkM)J1z(tLtil4euXuarzwjIpeORWQeBhwc4F8KXu3onrWdtfIhtzNKO8gWpC71yvR0Sc5OjEPLzUpCgwtfKWa2FjAMisEP8vW(QYyQiY1arJfnK6J2LgilHmrlxkJGgE3AGJmKmwLMBMXdYa9GoiJXd6ZXcwvdXe0OAsZ56uL5Zr8FYvYKnnyA1crlttBgWNiIf05N06ILRvpu)rJnEYiHHMkBiUjxKu3xxA(u0c17rU8fvu0QxTex63P1OLTGLnqnniiaIfXlV9LTS6nMLLqWhakZuvI4jLk79B7aaNTDIRyLWeS6jTLhDPkbMm5yfA3vTghHSPUnRlgPUrh7QWs3d4pQChlzLw9joXSuFN9IfU7LSEhwTjG1y5gBwcISro4(a2wVXVauU1nhxMSaFAQkukB3nY2PUvG8XVfpdL2ruDBzQXPuVhryeRsNueL3abgoj0CIPXsIwKDfVAK2s4DvU6okYm9ehFkIHfU0ednJJNODE7CAXwBBsYI4TCnBUkRbO5va35HPyPdwEWVaDky1fT6LuumeJBvI0vPKFJkPPBiUOv5YwusvKYGdMvv3A9UUfi7A1tPgjbzy0NV5ZQuI4XKUiX(WO4p4jiP7XhrbBiYpEDqSFu53tDB1PcRpGE0fdwkWKdFQrMlwyq1tMmRebXfOnrIapt4OjcpsOfv0Ka3aODi1EoEmUWNnw0K(JKkC0jcXLietYoRLK9D4uJwbc5eV8rW)Ki87NyvbF5nH)PaliVtQvQFAr8)Y04Fgr8)ke(FnL)h)b6mL)jyuW3bq5)VaOABKZMnlNxSbt0ld6(zHwRTz696Jqu3Zrz5)QV)MO0XVbKbVnLHFMMZW7Rdm9N4Y7c)Hq4)nQBDFn9c33(WFy2uv(3I)i4pk(Fh(JDj8)Ee(Nd6y)84poa)(fW)IeDrh4Fj8lR23kyIAQ2AdBp(xgH)pG)pI)vW)Q4xb4Y696ud15ZWFc8Non(tEF4pL)2Wa2CPyjIRE5TJxSolg(Za9IxfH)SPXVg(Zb9Lpp(xxe)FIq24a)ByZW4Ei8D(XqyH7d)FMYRG)nfXFb8lSwQQR(vjqMB0AW7kQbscRBF0(IRK6c)LeX)w2(QTeA153vR(nJNRt(72s((NFD9lggy(Tbck8Vd(3LYfHFDe(lNg)veX)E1iyWFve(3)Q)A4VgLZ4ywCgU9rnoqD8XZqwSg4VoLKqOWSzIeBa)r0hd)FreJX)xXlJ)dW)H1u4XFJ2PQFUBBDORFW1IU(8G74QkZaUzCPEC3fL0RzRJsZ8QtfLrWA5Jcvzf08upqN0BO1CZkBnOLckEQpE3lQTgNLc6H7EUxjVWAv54)Vg61rd91RR5XfNcYiAFpF6fOsaImgr0fzkIQ7GmDxnHlwwstGMBItOPPRAtT8N(np16JtuRb9fpSzit(DyFnRvhoWz7R3EhEWtmy2oRv3YS9FTgA2)z0M9vqn3Y)lw3Ds6C6TMuqTMUVAtUhytSNDpma4FpRcEIn4PJhgFNrAA(4t2x(Jh)K(gEGXgV(8XVp68XNgqD0LNJUg8tjRmJSnk8IRalwTEM28HRnB97QrHbXx2)k7Hx1D2e3qTL27Op9sn(aWrhBXg1T2Myus3zjzNLqoANW55SxGV8q77CypAKfFpwzd665Lrxe8ZCk85dqCtLoE3g5HvjTwdWa55H5ECEpqjOzzvjCorRcNPhl6yNEKYrgz6GTkCOZI4BztbqLkvPlihDvIs3mpXvBqKSL2y1703U7(zlrYA0Y3zxlw(Yatdk7u6229Sx)J04xuDhWefpK7d18ukR7q73fkJN2wgpDTmEBBz8E9lJDNG5zn(zpshmsiUcJeVtlFkjlldvCkCVRkZnTTM(BrVa1I1nAv07kQcscBOMSM2cF2j(IgXK1CUKSDiCEhOpVE62wI8MGPOtA5H5a(ytiTzRqrIh)IIz9f)4(u6SvOM3sRJuBZJcNvWvaEny2PAQ7P5nuIAd21KsY5uMr9(QL)kUMqqsw36b13XPnt3XP7bDR9ooTKv)iq5851x5Mp5lsjFNqk4Ot5JRDB(0JvvkRImB9vFWBJ0Xaap8GLZQOuegnKtmJe4KYs23s2twXo2ZVaNB397zao3E7ZRB6VEO)6LZZGU92pNxV93NVv1yZGp31Msqq1pztkm4iRYGiLHeyUF2J8glxOOYmJs8SsqoBf2YBWwvrYdwc4PpwrRfpn98KKOBfFCPzfkwLCBe6(dVZfjxBVcIluWUiuNK6NTUyoCqZK9s7fGCJinRjOBjlTLKuuk7uYc66oOpHSlN6BJ(IcWcnaGqHmLJ9Up11Ycb00S6xkC0OH4sfiwYKXgd)jVF8NcbtGamkUa0Rz7f8YS)KsXAziTUnBT1q2kQhSxAY0w7HCkbqOIFc77iBhKdSWPwvCmpzvloMTeGaKaTMFar55OlgnCIcNEKsh)ufejoia)xG5uukrv3N3gnX4Ziec)9Q7WorYsrnIKozxzYLMyfSYPmrpuAIghqgW0wiQa7M5kGL2slPSJvKcrNW2drWw0veMvvIT3HjLkrw7EFnozrWywvMntIyKO6pKJl)y4FyJ6i4)X0MOBRZAd7HZTN(63ZQeVBIURgH4MOnBJRnr3TjYj8U2Ij6Emr37onrVdKj6DY2yJ(T8J3eTviXTjAI6bUE7W)VJTzI25ndSNjAxnI4mr3NjA3Wl7(P1NjApqB7bWpHj6bbCtO1MTjOp9qmuZ94GSScZj07mtkNtFyVwWgt0JqbnMix1HlFpt0JYWgH2aWgMO92g8Gj6Xw)4G(h8gfhWKToTKVnacOJrBfzHtic(TSCMYggkYXylL8T2iH((8RajWdaHkJE8HReQ)ELLhRBaHV)gaqWPLyUVaf0uMzVJhhVPFf1TBzMnyrbEWBcDdj5c18Hi00kzPujUIRPus1qDx2gLzoI4ASWjseo6XAWPdWjLIkzNYUa2EQewMsolvuYOsRvgnGzoMqj703DdvweEz43eh3FYKH4UMDBnORyrDnwOAV2GXgNe3s043Yv0ytQUd7a8Xp3XcL0v4XgB8OHOEarq3)wu0nZNhoDv(SGtT3Go9SiynQCj5eKkJgQm9NHzsJJVOubzSpnysmKibdrCvbCsPUtEASi9sin11SNXX8GWXQEa)0iotTLLYvrMVKuwAyqaUSfqxrZaF4fkOjX2yZTmp5sI3a7LBeUIsLKm2cjOeIqUs8kGfm41lBmkFwyUYz48ps4XtKrJpNuz9339aoRTai7zopatDZcdUCTyPsqZqVA(YflgusllyF12vmyYCGtx3zXBaF9aCndxE0f907PoqWlCHPDp(bwpmr(8oWgPfjQxtSfcWYIu6FuBrc8KjF9f47AP78A8XOGmrHy(WmAVfc3)ecNzyUP7chKj6G1iHA1tf7fT4)bDrlwuVOuoHmka3Cj6Ax41EXoALy6YBDbAi)rqQlRBOXtcoiQhN4DNjBzDOcYqZqfQlaK3a7(zz3F(ECJ5r0iiIMC6EQK7U7zw0c0itIuRZBxRK39YW1Y6Kq(J8i1Tz)SK2jdnmwWMzNqAADtRT0nZA(44Fi66GipFJluf(VUNJI)2nSou4)M0DDfeV824GMr2PcqcKb1TrAhfeKf0KYMquzMyYPxUPBxuN(hob(Cviv)c0fslkFjHnF4TJ3nh9wRap6(dA5dQl79M11bOH3AVQ9qdbRcYkAcKDOfyresVSMaFXe2v3c1ScSCTf1JKoDZKjTEwFzbRXXStLwD7KRfibrBJzVZkHhCvPesrOSWPOJ6GRgLM2SeyRq75QKbXwuEiX4lj6Idd0PQ7TE01rUx)C0XRurjXOGqQ4L1GPEqv2o1zkiDGyNryI4cRuztSUY2tSkv2mrNaFEt0j7SkMjkIjAmYarutuSAksMO4nQezIoLT2JjIZeLGutMOKMOXH6YenbmQn56th4LTM1SjcQ6nzsKb3Uj6omr35YGHUSIc6mi8Ymi8ys6KO476S0nxgKVN2eDgt0zHxlGFohPaMO)zK5Qb91ZZW6MOuMO0qo4xSHvmXeLTf4QjkhKPBsOYAtQEJhwwFIP2WstuEvxThncJaPIa6EYgmSO)Oh)Kt6zUrD7B0UIfFY3(GfRVZwVbJlMTb0aYYA)SE(0mU2MIjG0Q7Q5yeWEFgao9vbI8t)EAlICHAUhVrIhzBzbBYZVjaiH(ABaKpA7bK0pSe2Vme5qbQWn6uXNA0Yd3ve5t92rezS0nezwj27GK4whNKSXdnhJwDdR9sTfPTuJZ3AdeS5WAlxPXG6ncw7LPrZwB2QAgeu0gfc4VR(sTdW1BRao)SoFkYSys14Wbd4nwWbvu4h2B(kDNk8qV9a4j3gxthCv7A6RH3DajdHsKctqGGlL7UnUuggYsVmQvlmkuxlrDWeEc1jW5TVAZt8G1R)3GmQmn7ddqPSSrAgEUkPcDfKKc5l(G(Og)yoyoVY8ZS2BaE5C0CcdNWR3enlmCuP(R7gND1Rf7kBp7VHG9R15Vrq67RvKE4OtKc8HkBQJjukvcdfzHu95MHY77SZQlo0eJm3z92vu(HF7d9Q1scmNh3E84zOb8fya3K9SPppE7JZZG9n0qKvTCyYE24DyYE2CQ24ZP2X9Zn2OJh56zNF6)UoBNNUYvRlQ3JSQrI(OmVd74wPLK4L7il(vKvms1u4EWuGBo5gz6jdWTrdy)xxNlcuK32dJroRScV2XoGKVr66ID03BbubwTll2(bc6TgutzMCKperRpCyk7)nLfcJf)KU9THd7EOvjS7mwmP1cn(oWKUFSrAoY39mF6wxtSZg07eLkFb(sJ1xxzkDxdMCMB5GjF06F(owFV40Vd4lfirYXJ20x)tZIr8lET67jyZF8qMOFw8LwMu(uJfk4X9hnCWUwrMOpuZLnWOH8ZTIV8ObTdpIvwGLjfO9VSRtj1cgl6OJNi0kkJ1wjsxT922g5Ifl5kkL9sn1U3uIWrcfnyOvouyVgXTRJf3FWWJEM1trv3AIGhpwmYhHqYqCCJhp51P4RnhdhL42hHDy8abj8MeJIulFufVZZSQjKMAmB8L9t)K9DnoDNSbRGV6lvlZ4hGUeHIadm1v70lu7sn2vcKxfl2Bo1Bpxv(ZynXzGlQXjo)TADIZV6lvJsYe9bs3SfUhVBw4aVlsiQKDkgX1C913PM(SNv9IHk0v7BEUfM4QEaUUe7CBqMJ89P2sKbMg)I4mRblHn6nix)(637qEgOFpbaxb7JZl4Dy)CE8omCT7H9ni4py)9pO7o4pO98uOqCt0ph8Y(5nrF8B6y53sByTzumdCwiQ7HgEYkIhR0j7k407TWGZABBUjQ3Q1)GWiBEoBhSdoslHIN1UEttpo5B8NSh2k5DnMKCoRnCN(SAHONQR6jMOCPsa96K8abGRqffiRElFXglgyHoNReY8QnxxwlTyJjwBNBASLsNpTGgvr7A1toqrj5PAmFnTMj2BD(tE7nS35MO(V7B0no3e5JTF5yFMObj)m0k3ICt0W27oUj6i13xCt07cFV3Hj6OyycSpnC7ZSxUrmrplC17w0e53efWefKUd3MOrQV121oypSxedDt0OTUT2OBk7Q9ydDXrMzcdvvvoI54vfPvlt4SkzBs8xCg(k62t88WoB)Y(1ikSRZ9CnhlSR)LhSfd0IR51jX)6jYRmrFosCTBDShL2k49gS4zImTMpdVZ0v6OFnGosKsh5)Mw03CWAU0vvr2g31YxLp1chKVbW33tEB43Rh)rhjd9mDq)Gdy5n4VjyuCGAroVJ2efxp(QCsITGYUcBZ4Q1YSrABPTin1T2kX2n6QmVwIdmt0pXnB0ZwAf9yI(nSqnkfIOkmY0bhAW56kQ5tSbGACUgeQNVDRv1VUTGSVpFNwRklJq)ygFrlXNxtsC55MyOK9wA4tDwFDvI)j3q5jOk7DJFWe9fmrFXBYudDhf98F52thSR272YpMHPGrNoIPChjurVvcnX4jD3vm1N6THyk5UIPo0R1EMPA(5E9qrROQ)sxhspt0V96Vo7GkGj6396yc0dVCLB04mPPL7FJcgdcKocJngY3P1MoP84deTRW4p9TcW4JSsyCaIBoqzH7UlYt(Q3uDIQbyshIbetK6BT9uAfX7rdGJqElpsoDrVfhoyxbhl(JypL6UKJe(KTvYL5T4(4U9ol5IlzKnA2jl7vqRRsUpZTYsUxTdbdtJR4XBPfHV6l1zj4PDFIcNys3HQy0952(Q3klb3XCTvcYrxCQ3sl6GEwhfDjpT)E9PnLNK91BxfDF2BLfDVuhin1FlTyRlkCz8mMq0bhkHCYWDvQ9ABGsnYAshyKytgfVPlu7t5kj5uNqWWfjDRvw(PCnj50pwjVldrbxJQOPZpLGmlh2FRuHKfkvXUW1o1KdMWvKybpzSXtwlJXvkwPKIMQOlsQBRPIt(wUA73zLjQ)79M2Af7jzS4V5TAXvT73thVnltCUBoF9tNYJhPXDpZGbNAIv1MB9EyHLNjA66bLNjAMgI(UVuJH)2h6QnfnFR6I9xVUkw4F11xXQwtGBI(kRGwi9Bw0cRVT86pMrlm7qNor(t3FIi6hRR0c)bBG0cp2nSpWp87U9RZZoAhpYANH)nnr5QAR4j92Ujs9pSh5jlesPuepDvK(hElGiDAOggxZ6F9d2dx)E8mSh8ZZoPTTsnn(8EC7PpYbsnnScCrc6dxjkNnRa5C)KSd3FGFKBAEvPdUR2jTYe(SNzWb0fh9u56Q06BSrAxUQUkV2u0Vn3DsLCqtZ6eiH(KANzQQBRP7Ph9SFeO9iwZa5cSJMPIkfmrFZ9eWJBVdJF4Q1dfi857zi84vzhZ3UIOuGrP(NzDgCrpcuOhr(vRFnyRTUaMEuPyDCAqdza22XoFgET2CUHayGLOnz2rhYza7Vhzx4DVi5KGfkrk4)VjeLclYowq4cFSJNSwS3mnf3yFCGWotF9aVVUGKU)1x04CfApS(Hb8ZroNIiqmMCny9XkqJKCgbPz19buuJJoNgTaDWvxkNahRZSUDwObv9fPVIJtpA9FA8z4iF8(YauM9QToZBvpq9Giki7d7paV25gp8tv)UNkbf8rlwdb5iOH)ii6rx0VZMPa7JU4fNb6i9f9ytNneOMy1aKYLtqMlAOjcXHx2e9kwka)(0dTxs0ZTQPTEd6MChSOISGEARpFqpUDtcw7H80p9xF0FhGd(zq30F9SOQGgbotKrZZNpVqwdHCAkZihtUyL0uISRq0EKKfIZYz624JPj6Y3uIg7HSIWWBzoYscFJqJw8Ik6tmsOYgJ2DJE)3Qf6oH3WoYs82XJSeycq)LTqWAI(RGbKVvJSOVEZhLJe7B)5RIdbqt0)ZgjenrFNgoYPRDotMbKZ)Tal4j2frE8)YsiZTpY)SbTULZvz8Frcnkq)TtM826aEf)NSwR1)7nEaTAIUg5Or(Bso9vPaP)u00waPVRj6)D35sx9Wjt0)N6SMMO)VnXwAI(7aCIj6)h8Q(7nrFVBkKIMOVpWfAI(bay0e9pyI(HMO)Xgi1mxjPMO(PZEY(pU6GNjcaAn3eYCtBYIiR(EnG)22NB21GGRmIB)onND3nN928vdrluZKL9uQNC9K7YpCthaCNfpa(hqJk0phr106qCJCaU9128T4)tg0Mx5P22Sfh6cY6NSK0GNOnNAB9OZ59q(ouF9m9T)c)tp
```
