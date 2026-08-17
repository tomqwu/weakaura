# Rogue — All Specs HUD (v60)

Import `all-specs.txt` whole. Layout groups (drag each in /wa): Buffs, Alerts, Resources,
Procs, Cooldowns, PvP. Everything that used to be the ring cluster *and* the combo row is now
one sub-group — `Rogue - Player Sill` — so the whole instrument can be dragged, or disabled,
on its own.

**v54 replaced the ring cluster with The Sill: an instrument strip under your character where
the rail length divides evenly into 100, so a breakpoint is arithmetic instead of trigonometry.
v58 takes it to three pixels per percent — a 304 × 74 px plate under a 316 × 86 px alarm rim at
(0, −125), with 22px bars and 20pt numbers.** Four stacked 300px rails — threat, health, energy,
combo — with the numbers printed *inside* the rails and every breakpoint drawn as a full-height
waterline instead of a mark on a circumference. **v58 also makes the nameplate combo pips
actually work**; v57 shipped them broken, and the reason is worth reading.

No aura is added or removed in either version; all 58 UIDs carry across.

## v60 — long and thin, not big

Third size pass, and the first two were fixing the wrong axis. v58 scaled the whole strip
uniformly, which preserved the original 2.8:1 plate and simply made the same stubby block twice
as large — so it read as a **panel** rather than a readout, at both 300px and 200px rails.

**A vitals bar wants to be long and thin.** The fill's *travel* is the signal; its thickness
carries nothing. So v60 keeps the rails long and takes the height back to near the original:

| | v58/v59 | **v60** | original v54 |
|---|---|---|---|
| rails | 200 × 22 | **160 × 13** | 100 × 11 |
| threat | 200 × 8 | **160 × 5** | 100 × 4 |
| pips | 16 × 12 | **16 × 8** | 16 × 6 |
| plate | 204 × 74 | **164 × 45** | 102 × 37 |
| rim | ±6 | **±4** | ±3 |
| number | 20pt | **12pt** | 11pt |
| area | 15,096 px² | **7,380 px²** | 3,774 px² |

Less than half the area, while every bar stays **60% longer** than the 100px version that read as
too short.

**1.6 pixels per percent, and every mark still lands whole.** Every value this pack marks is a
multiple of five and 1.6 × 5 = 8, so the 35 and 40 energy breakpoints sit at x −24 and −16 and
the 25/50/75 ruler at ∓40 and 0 — all exact. The invariant was never the number 100; it is that
`markX()` is the only place a coordinate is derived, which is what keeps the length a single
constant.

A side benefit worth recording: the strip's clearance to the buff row above went from **2.0px to
18.5px**, because the height came out of the axis that was tight.

## v59 — 300px was too long; back to two pixels per percent

Shipped and reverted in play. At `RAIL_LEN 300` the alarm rim was 316px and spanned most of the
screen — it read as a UI panel rather than a readout. Rogue is now **200px rails, plate 204×74,
rim 216×86**: two pixels per percent.

**The invariant is a whole number of pixels per percent, not any particular number**, which is
why this is a one-constant change. `markX()` carries every mark with it — the 35 and 40 energy
breakpoints land at x −30 and −20, the 25/50/75 ruler at ∓50 and 0, all on exact pixels because
every value the pack marks is a multiple of five.

Nothing else moved. The buff row stays at y −60, the Procs column at x 330, the nameplate combo
pips and their strip fallback are untouched, and the all-pairs column check still reports 0
overlaps at 6-deep projection.

**Paladin is deliberately left at 300** for now, so the two can be compared side by side in play
rather than by argument.

## v58 — the nameplate pips work now, and the rails get three pixels per percent

### 1. v57's nameplate pips never left the strip. Here is the one line that broke them

v57 anchored the ten combo regions to the target's nameplate and added a third trigger to supply
the unit. Everything about that was right **except the unit token**, and the unit token is the
whole bug:

```lua
-- AuraEnvironment.lua:160
WeakAuras.GetUnitNameplate = function(unit)
  if Private.multiUnitUnits.nameplate[unit] then
    return LGF.GetUnitNameplate(unit)
  end
end

-- Types.lua:4316, 4351-4355
Private.multiUnitUnits = { ["nameplate"] = {}, ... }
for i = 1, 40 do
  Private.multiUnitUnits.nameplate["nameplate"..i] = true
```

`Private.multiUnitUnits.nameplate["target"]` is `nil`. **`GetUnitNameplate` returns `nil` for
every unit token in the game except `nameplate1`…`nameplate40`** — `"target"`, `"player"` and
`"focus"` included. v57 fed it `"target"`. So `GetAnchorFrame`'s nameplate branch never
resolved, its last line `return parent` (WeakAuras.lua:6171) handed the pips back to their own
group, and they drew in the Sill 100% of the time. Silently, because the code path is identical
either way.

It was **not** a missing re-anchor. A static NAMEPLATE-anchored aura re-anchors constantly:
`RegionPrototype.lua:1118-1125` calls `Private.AnchorFrame` from `region:Expand()` for
`SELECTFRAME` / `CUSTOM` / `UNITFRAME` / `NAMEPLATE`, *before* the `if region.toShow then
return end` early-out, and `WeakAuras.lua:4901` calls `region:Expand()` from
`ApplyStateToRegion` on every state application.

### The fix: a nameplate trigger, filtered down to your target

```lua
trigger 3 = Unit Characteristics, unit = "nameplate",
            use_unitisunit = true, unitisunit = "target"
```

- `Prototypes.lua:2398` — `statesParameter = "unit"`, and the `unit` arg is `init = "arg"`,
  `store = true`, so `GenericTrigger.lua:454-458` writes `state.unit = unit`.
- `GenericTrigger.lua:703-715` — because `Private.multiUnitUnits["nameplate"]` exists, the
  trigger clones per matching unit and `cloneId == "nameplate7"`. **That** is a token
  `GetUnitNameplate` will answer.
- `Prototypes.lua:2412-2426` — `unitisunit` compiles to `UnitIsUnit(unit, extraUnit)` with
  `extraUnit` baked from the trigger, filtering the 40 plates down to the one that is your
  current target. Exactly one clone, on exactly the right plate.
- `Prototypes.lua:2372-2382` — the trigger registers `UNIT_CHANGED_nameplateN` **and**
  `UNIT_IS_UNIT_CHANGED_nameplateN_target` for all 40 plates and watches `"target"` too, fed by
  `PLAYER_TARGET_CHANGED`, `NAME_PLATE_UNIT_ADDED` / `_REMOVED` and `PLAYER_ENTERING_WORLD`.

### The no-plate fallback is back, and v57 had broken that too

v57 left `disjunctive = "all"`, which meant the pips required a *target* before they would draw
at all — so with nameplates switched off you got no socket row, which is not a trade anyone
asked for. v58 uses `disjunctive = "custom"` with the one-line rule

```lua
function(t) return t[1] and t[2] end
```

— points **and** the player state feeder, with the nameplate trigger deliberately left out of
the visibility test. So:

| situation | trigger 3 | region shown | anchored to |
|---|---|---|---|
| target has a nameplate | one state, `cloneId "nameplate7"`, `state.unit = "nameplate7"` | that clone | the plate |
| no target, no plate, nameplates off | no state → `CreateFallbackState`, which never writes `state.unit` | the base region | `return parent` → the Sill lane, pixel-for-pixel |

**You are never left without a combo readout.** That is the property a dynamic group could not
have given for free.

### Why not a dynamic group

`DynamicGroup.lua`'s `useAnchorPerUnit` / `anchorPerUnit = "NAMEPLATE"` path is real, and it is
the right tool when you need *one region per nameplate*. Here it is strictly worse on four
counts, all read out of the installed 5.21.10:

- it lays children out in a **row**, so the five sockets and the five lit pips drawn on top of
  them stop being five overlapping pairs and become ten boxes in a line;
- an unhandled child is `controlPoint:SetShown(false)` (line 1520-1524) with **no**
  `HiddenFrames` placeholder and no fallback outside the options window — nameplates off would
  mean no combo readout at all, and getting the strip back would need a second set of ten
  regions plus mutual-exclusion logic;
- `RegionPrototype.lua:1095` and `1166-1172` install no-op `Expand`/`Collapse` stubs for
  anything with `controlledChildren`, so **a nested static group inside a dynamic group can
  never show** — that escape hatch does not exist;
- it costs six new UIDs and doubles the region count for a smaller feature set.

The plain anchor costs nothing, adds no region, consumes no UID, and keeps the 1.85× pop and the
green→orange ramp byte-identical.

### The one price, stated plainly

Those ten regions carry **one** pair of offsets and now draw on **two** surfaces, so the pip
pitch on the nameplate *is* the pip pitch in the strip. That is why part 2 lengthens the rails
3× but leaves the pips 16px wide at ±40: a 96px row is right on a nameplate and a 264px row is
absurd. The pip lane is a 0–5 counter, not a percentage gauge, so it has no business scaling
with the rail.

**Two things about the row did move, and the coupling cuts both ways.** Its height went 6 → 12,
and its vertical offset went **−14.5 → −29**, because the lane stack around it doubled. In the
strip that is simply where lane 4 now sits. On the *nameplate* it means the pips hang twice as
far below the anchor as they did — 29px rather than 14.5px under the frame `LibGetFrame`
returns. That is the same one-pair-of-offsets-two-surfaces problem as the width, and unlike the
width it was **not** frozen. Whether 29px reads as "under the nameplate" or "adrift below it" is
a live-client judgement; if it hangs too low, `PIP_Y` is one constant.

### 2. The rails were too short

Paladin v22 already answered this. Rogue now follows the same law, with a fourth lane:

| lane | local y | height | span | gap below |
|---|---|---|---|---|
| threat | +31 | 8 | +27 … +35 | 2 |
| health | +14 | 22 | +3 … +25 | 2 |
| energy | −10 | 22 | −21 … +1 | 2 |
| combo pips | −29 | 12 | −35 … −23 | — |

Content spans ±35; the plate adds a 2px margin → **304 × 74** at local (0, 0), under a **6px**
alarm rim → **316 × 86**. The plate stays centred at local y 0 because rogue's four-lane stack
is symmetric — paladin needs its +6 only because its three-lane stack is not.

`RAIL_LEN 300` means `x(v) = (v/100 − 0.5) × 300`. The 35-energy Eviscerate mark lands at −45,
the 40-energy Sinister at −30, the 70 threat notch at +60, the ruler at −75 / 0 / +75. Numbers
go to **20pt at x +96** (a four-glyph number spans +72 … +120, inside the rail's +150 edge);
ruler hairlines 1 → 2px and breakpoint waterlines 2/4 → 4/8px, the same 2× paladin used.

### The geometry is measured, not chosen

Every element in the pack was projected with dynamic groups **six children deep** and the
frontier searched. What the scan says:

- **With nothing moved, 300 does not fit.** At the shipped (0, −110) the tracked-buff row
  (y −176…−136, directly *below* the strip — that is the rogue/paladin difference; paladin's
  buff row is above its strip) caps the alarm height at **52**, and at any alarm height ≥ 76 it
  caps the half-width at **2px**. The widest rim that fits anywhere in that band is **188**,
  i.e. `RAIL_LEN 172`.
- **Moving the buff row to y −60** — paladin's own slot, above the strip — opens a **110px**
  corridor between the buff row's bottom (−80) and the cooldown row's top (−190). An 86px rim
  fits with 24px to spare; (0, −125) spends 2px above and 22px below, paladin's exact split, and
  puts rogue's strip top on paladin's strip top (−82).
- Horizontally the binder is not the proc icons, it is the **140px-wide `Rogue - KICK LOCKOUT`
  aurabar**, which sets the PvP column's box to ±70 around its anchor. Measured minima for a
  316px rim: `Rogue - Procs` x ≥ **174**, `Rogue - PvP` x ≥ **228**, both at zero clearance.
  v58 takes 180 and 250 → 6px and 22px.
- **`Rogue - Alerts` does not move**, unlike paladin's. Its box (x −170…−130) only exists above
  y −44, which clears the new strip top by 38px in true geometry and 18px under the canon's
  deliberately conservative box for dynamic-group children. Left at −150 on purpose.
- `Rogue - Cooldowns` does not move either: 22px.

Final scan, 39 elements, dynamic groups six deep: envelope **x −158…158, y −168…−82**, **0
overlaps**, closest **2.00px** (the buff row, which is paladin's own figure).

| moved | from | to |
|---|---|---|
| `Rogue - Player Sill` | (0, −110) | (0, **−125**) |
| `Rogue - Buffs` | (0, −156) | (0, **−60**) — now *above* the strip |
| `Rogue - Procs` | (110, −116) | (**180**, −116) |
| `Rogue - PvP` | (200, −44) | (**250**, −44) |
| `Rogue - Alerts`, `Rogue - Cooldowns` | — | unchanged |

### What this does not change

Every trigger, load gate, condition and colour outside the ten combo regions' third trigger is
byte-identical to v57, diffed field by field in the build. Sub-region indexes are untouched, so
the two conditions that address `sub.4.textureVisible` / `sub.5.textureVisible` on the energy
rail still point at the 35 and 40 marks.

## v57 — combo points move onto the target's nameplate

> **Superseded by v58, and it did not work.** The mechanism described below is right in outline
> and wrong in one field: `unit = "target"` can never resolve to a nameplate, because
> `WeakAuras.GetUnitNameplate` only answers `nameplate1`…`nameplate40`. The pips rendered in the
> strip for the whole of v57. Kept here because the reasoning about *why* it takes a third
> trigger is still correct and is what v58 builds on.

The five pips now hang off the **enemy's nameplate** instead of sitting in the strip, because
combo points are a property of the target, not of you.

### It needed a third trigger, and the reason is a hard gate in WeakAuras

`anchorFrameType = "NAMEPLATE"` anchors to the nameplate of **the aura's own unit**:

```lua
-- WeakAuras.lua, GetAnchorFrame()
if (anchorFrameType == "NAMEPLATE") then
  local unit = region.state and region.state.unit
  if unit then
    local frame = unit and WeakAuras.GetUnitNameplate(unit)
```

and the combo-point trigger can only ever report `unit = "player"`, because `Prototypes.lua`
gates the whole combo-point branch on it:

```lua
elseif powerType == 4 and trigger.unit == 'player' then
```

Anchoring the pips as they stood would therefore have hung them off **your** nameplate — and
silently, since the code path is identical and they'd simply have appeared in the wrong place.

The fix is a third trigger, `Unit Characteristics` on `target`, whose only job is to put
`unit = "target"` into the state, with `activeTriggerMode = 3` naming it as the state provider.
`disjunctive` stays `all`, so the pips require the points **and** a target.

### The no-nameplate fallback is free

`GetAnchorFrame`'s last line is `return parent` — with no nameplate it hands back the region's
own group. So the pips stay children of the Sill with their existing `CENTER`/`CENTER` anchoring
and offsets untouched, and:

- **nameplates on** → pips ride the target's nameplate;
- **nameplates off, or the plate hidden** → pips fall back to the strip lane, pixel-for-pixel as
  v56 shipped.

One string, both behaviours, no second set of regions, no new UID.

### What you give up

**The empty sockets are no longer permanently on screen.** They now require a target, which is a
change from the always-visible socket row v41 introduced. With no target you cannot spend combo
points anyway, but it is a real difference.

**Combo points and energy stop being one fixation.** v54's whole argument for pulling the pips
into the strip was collapsing "do I have the points" and "can I afford the finisher" from 233px
apart to 1px. On the nameplate they are two reads again — and the distance now moves as your
target does. That is a deliberate trade, not an oversight: it buys you reading combo points
without leaving the enemy you are watching.

If it reads worse in practice, reverting is one field per region.

## v56 — the rails were filling the wrong way

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
39 elements scanned (dynamic groups 6 deep), 0 overlaps, closest 2.00px (Rogue - Slice and Dice)

**Read that figure for what it is: sill-versus-everything.** It tests each element against the
strip envelope, so it structurally cannot see two flanking columns overlapping *each other* —
and this version moves two of them. That gap hid a real defect: at x 180 the Procs column sat
inside the PvP column's own box, because `Rogue - KICK LOCKOUT` is a 140px aurabar and therefore
claims x 180..320 at whatever depth the stack reaches. A weapon-proc icon at 180..212 was
entirely behind the kick timer. Procs now sits at **x 330**, clearing the bar's right edge by
10px, and the build carries a second, **all-pairs check across the four flanking columns** at
6-deep projection so that class of overlap cannot hide again.
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

- **`orientation = "HORIZONTAL"` has never been rendered by this repo.** On a
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

## Import string (v60)

```
!WA:2!T3xF0Tr219TdHuxjO1zL4kP1R2VGKSuK2URcaiabWgTobaeueu8dObG6ZDnXaGbygsamJMza)qo2jMwEnT3DDtOv2y3M0twEYPNMuFY5u22nTPT21QoUTPP2pZMSESJDtnTBs6jPN0O2MgN2CAV33B(aGaKIIIu7UNv)bho4nV38X7(7(7DF33DUd357U4VCS5F6LliuCYsAkQjvQQOnOhpEY4X)PcR2DrL6gAkvRkwkPKC1sAI1VS6b5vQ0q03Z5lBv5II(eQxYxFWo3YUy(gQgn0evpGDb9jkuQ6S(YOiRRu3T4(LHwEbrHjRlQRR2TDXdiwtrttsOI4kfu0kjQLW6EtDVjQkFTRjOvYxofLQgYQAZmA5Y6IgCAZY25nkWAI0IS)NQufr19L9Qne0e91FJQv9DbjzdXf1eRiRup3SQI8v0uAOAv9SYxtCNjQQiuQ)cgcvfRBCq(AnGRK3e6QIfpiz)E5lwvqxh3lHouBCNLynM11XXX5HxVi0ypll0WqsrBuvd4AP7vtOiDNE51ne0m8MqUUSH3cLH)Pl5Dodn5kve10p0X1S29Lt0aQrb1QcZcDcg4nRqdnHGZb3lvRMUKU3v0BuqCk42mBJYLLNzPXtgpBUXZMloFoNdLrteoeF2mPgAOfljwaQj(CRnqQHY0)ydXtRuHbefQAiXxxOMOU3fAu36wW7cc1LRjG339sEI(jhnrDL6I3uuqxmRbagQyi9GlxcUPWAmoElQPlcyMs6ZH1bVqKajQjixhAljaj4ds6HeIeg29PwDj3K1nYeK7EbDXQLbedCVLm1i5sXVOHsXPGtpCH2vMdCe5slBdysaps6bBixAjvr1lgO05k1xp9Suzn4zbUjfme8ClH6fbjr)yr49uHSj5tLAKcQaSOUHnImxIKWzloasYccB9cWZrz5k2I301HBlplcDR8uWJU3Bb3CIA1fQEE2T1vweFYLzs7LKRxwrJ115Dj21N(4qIn)rxugQzwLgAffFIhGCiVK9WrstITCrawxsz66zNwwvm)nT)jIILipoib8sEsVKNYl5Ph54eF)9GoWpa54KFuYZsEoYHjhHCmVKtqo5nrucfJixs)zseoqKaj6nsKqKt59wn0ftndaeZYGq5jpd5Vj5hZ7sLK1NOrDaGoLyqHQvv3NaD)CmyWWkLe)cpaP)RCRjffvJJ6cg84JMejkjgGQ0fmqqaCxM65FRLRuvz6(1eVAdX6fNnZo8FQGHjhvd65WdCt4w4mW)PQlsZHfHIKLl0WWqP(OGigW7lIfpefFDGLW9VKLI(cvSBkss5HESl28XYYu9ONwj5IuUfpjWFkrp(qYqj7JE(tWOkM)ru72qCgJX1Lek10zJwgU5ihdOEAQgUk6RWk1gPMi(y5gv9rOfc6(kO0V4fKlziLio8ZBrpaOmkwIw4hBzgSW(z7M0JprdDd5YZcDRAkgqxAoOWeJm6iPyDHyDwKwXIo9cSB1YavT6E7xt(A(oxdHsiW3xUCT8SzFLwMw20WZ)f0euN7cw7SSZ5HYqm6y5gk9iPSE2BccFZ0Jmsk(XtmAUCJoSBJq2ZN06z6IT8mnLSUCHQI5lVmtxACf2rTuTghzs9yP)B9Cr7ETkXU52vxe0hi)iKJUa0FWkQGKOCfjJZr6(8la4RXPK05jpcsptoaD7bpEbD56vQkYZp6zglfz)hK8jZtEu6XE4eOczIRPOudh3RN5S18YZluvvsWdjo5hxD)2LIIK(K1fG7jqdY7ZUdYZZOKiEi(P8KaRgsUzZ11BBL8uTvYh0d)0iQ4C8UcwYPxA6lxmq10rUw5etRjxhjabLSKEj)eKFsYzo0X5lkjwCY(j(8m3ucAY4T0kIZOkZyKZjxtKFkHQne7o8ruupYPFbTIsc1RicJYqUr(5uHrvf1mMfz1ovGtHkfKb8sMp)8hLmyZmtKZMNmuhOGEtkfuM8AqVYO1RoBEgvem4PwfrdKpcPNaojG7Hm81seiwOEseT3EIbBc5NpqGGr6HUneDBy(G9gT3iKNrBG48ddJobutKZr4jzPSpKCu(gYyuAgY5TPwixGCrjYLixMCLdqEroYlX68(qCKX9qY7HiirkSpsrqtNuIJic6ZKYuagPcrIitMGm5hJuLJudo31jkWjuLCv25qJOtm4initrMMmdzwY1iF4NK8tXr(i5lt(OCKFApKFg2P6JLNmhckjFCY1rCi5tSA8h5LjFYwHDK5jFkkGJ8PZtEfkkJ8QaIcUxSru74UbrrETZr(m2iPjfUeVmyOL(edq(zDXqE3CsCYNZswt(8TlMdgnquCtmqQ2t4EOBdXhmCpHIbs4y9gLpyKarb5m5nwBj8G3nsy9nVeog5dFyMeElcV8OB74LNZbUSZTm4YOLYfA4Pc1xdLRExaxwlBuidFz(EceSNq0THPB7LUncDBuejLX28K3lYb8jCKP)n2YKPZukzVNmGayIBITqz6N3rMoiFGEdhiaFGi9ekcDBukJEihP59133AXgp4wg24ebp7vLV8G6tvD6oHn8NaMO80hzSmKUUM6J44bG695B40zZMEKZ4o9FzvfDdrNPN1ViyYORtdsnLaozjFz0uQPcgSAxEYK(gDeFdNYTKZMo5z9nYOxW1JbWeBptQC(sp8WJb2dVlYUPG1VmcwxSmm7(KYAfb7eNdUtZQkuu0tRGxWOhFVmLecbWnnQfYYGyzaLcZfcS)QrT6StqbnHsYn0V(dz1pVQjX27TFATGfKYvQtIPbZ6hNlfhjLxs393QSNULj05C8(IgBU3I5jrlWS1M8yEqLMhsI8(aO0dFZsZctyxUi1fgK9Tt(QY1Kn2d59trCj0v0mibMRIMCj0E(JW33ccAfzZQ66hCfWIx4wQUr)Wu9u0kWhVV0JLfacANCIbLcnHU6S9qIS75OZcbeyoMKSIT0iEvW2r9fWZpD(m7bHuiOjojbIF6ZdyjZU51XoY3hdjnhyC(q4nP08FaYGCTX1mF(wTYyz45hSWvpRKY0JwFzD6)ggSIbSKV5ruA28JNHmcz01FGJNzvun5jxIpdmVSQU0n4HdeMTTzIN8mIN1x5USJY9I0zJOuRGGr(1xrhXxLjhTGQMim1isyn0bkJ2WGIJc(GZz7LLGiDW3CjDyY9IfuG5mxRtA7ZV3cuNqnlIKcTSbGL0RIZMeacQ7th(noFPC2fVaTY05HBFm6ePHtMjCpveMtkCDWZ(RWXoXZqpXDpBPD39mC05Crlo)c0jmHNP5SptKVv3OcXYyLCUrYtBdTY5jFAj0beOJUsdOs1F00OJvkdWMxe)T(lkuqUQSXSJRHiVX1r3owc(Rj(llAsGC0Mz83aGYflfB2OXZv9CIQ2ytVCi0ei4It(6iLkJGRjAI1gy(RdaZxhM1jtCwvPc54AJJSFP6dEedtE2ftspIVHGdDc(SxayfNRKOUXy1LnihbD8X41aSl25KN(l7dMFo7Y5ZeNN)saYLDTi)ja0(pLD2j)3Oq8)maX)Fpp5ppp5wK)hSko)(4H(1ItMaD6G6(WZCfX6IAYfz6n5xULFUetnIxuO0SOc0cuFfnIqnXDf5Fa5O80FYgFx9XsAnNxKVUcan19DcQVJoP6JGxhr0zsJ7CcYVmaBRM1(NA2JfqXhovc1yr9ZtrnByblCrXjZR2nUpqxQOjQaZ1fywGAtvJ)EQDZqHwUKc6JLlQEQYuNwPu)egN0NMOrdT6(oHXvc8s(u08zCLGV0jPUN24k98s(eRxAdydjqfq(9ALgiAqeCfOdSa3lnMCkGtzfN(XjRJENWAqKwyuOKml6wjuM2gld5Bs1SzulKVf5Bdf873zEeY3HQPt(UK)tK)aY)zgJa57zrgqwPzEaY3pp5hq(VyPWt(dZt(JYJMU8hREY1sLEAbqkROnErjHQvrxtSUk1)tbL6AXh(mdo2jcmWiZSfOu)Ha9NVk8aDyeWZOOKamSHArGW(zv3Bo6V8Lv2ObL(faTR4wlQY7coT4ir8dyB1UDkyC0)kcWWRh5d(ciwFr3MbMnZgJIQat(Fs(Fr(lYt(Ft(lPJP9d)bxdUP(RSSY()d5)BEYFnp1skY)VvP)yY9a5n54YFhnC3QX4HcVwy8BpQ0KBhRns0KBNWJYB)aWJU(JPuM21UEqV)za07SsJntKbRFI(0V8wo0dakffRBirxiMJe2VJ5niP)XOwonoUEq5bXoJJVLwKx9GT8BhKx3NEDXz7A))sTb00SSrFlhQr7uXnr8ChJ0EzBK2BT2ZBcaB4ZZBVOnjaT1Mfmu(ylVWB9pG5R06I4(nbe3e(llxvpYfJkm7ghXXMhpuVoAB9XrATKWuKk5lPZQ7sHHByhT0bcKwSvgKOmrlBuYdSHhL0A1kADneAAOZwoU9Qz0YGPWpDhpfXoaMQvafGWSTrNQuHl(G0AYFrbthpO6uQ55XvleE0qGfR7(PO94GeNo38Vok8o9s8vYmvMIfH5Pi6ik)NBlETKHwYCMCe4gayWz(2hN8ZHoYNSWswR6oD5tVrIS5gBe079VWlq(5r)2V6o8x)wUUVNU2uoNitUNMCJLX2p(WPsoq8rsNCDprMChU12YNeDe)DwB0YmkysC2S3zTkr)PIZ3stO8e0EnpDQblJnOZpw3MwQLC0r6FSSPARnHWBVy0rc789i)OJMRTw5qO1HRu20dLAKKPAVRik9QeStnQqM4jt3)LUJAZYS2SzUCQ7nBYbgD0HgpnUk78JLj3D2DBFPZ2risiQW2Vvhjsr1kzmqyIKWizmYTcKX4)S8DYQiJrIyKK1MmMXcJ8XF)82CXirmEgqIBBY4op2BZ6UpDDGrSFtUUZtzaF2ejf0nO(0KoG5B6o24YXPt0W3y019dhN0D0rMRhOJm(dlv3TPhMAqPemfiQTg5TMu1(r7)8LusadjeyEzWHlQ3KJuP3oNY7conuJTNyN9QX9((1n8mNSXn3nJjyY9ynpeGj3HANX)X2im(2wqyY94sRNjeGeKs6BY9eWpFsgHpouiDO9Ny1dTh3YqYZkxCsKFhg3T9XY)xypWWKqTgzACad3H(Dho3AvDPAy7KSWnzr6tDE6eJUbxZAz5jVozSwCCFNgW)dz5hHpaz4FTG9gkyIa(d6pyOyrteoCKEWFfe2lwmEyVir5dfoupr5delCKq89ekuKan7EFe8MbbMUgusb5MC(Tq2MCbAhgBYf0KRN7SvYzBZaJncyAdB(qtaP1YWHwWq3oJgKRvRrDxJg(xUbmAW7BteRpDt(PM01HCxrGm0OvdMVC1Quh0JGYR64XAYEj7BNRN3VzUUg9Z9H8UzCE)M2n9Ki7MIgT68v3NZYziQtdulDqkf(8X0kCj)bcwkC7(6oLxeuZKiGsiTlcEyy9OD9x52ffVQGwnF0GrZnQhXomSZZq0TIw(EGxqUQBHSi1BvfMQUOwLzzf6SslO3iv8LvP4KIg(c4UkkSYPrYduCNREWox9GRr17PZvVN1O6H6C1dTgvpCNREykadGkiLhGW2ZVyx2iSbqKefC26MOuyiiMAXgag0cWpRbYcbDa0cHhr2dkQ3SR5gaSm5O4fB0JjxsaxvpPEHsz4JEY(NLcarSeO4Cg6cf9OTPQWuEoK359rEynCcrn0eVL1)X44cdxp19NCO4dNj3OjgkEYZgVV(sNl95tzpi4JlTe1tR1PlD0ApHAnRAGuzK9MpHMGCj2IwmfVQGgysdsWnxzfy3Ac1Zh0qSE(fnMwSUXSLLNsmFb2(5jbYxGfpBsipg1ztSnuZeGhMc1K10u0KSgdZKBm14Ud1gVuPrHXAXOfoogDJV4WILKfEXCShA9xKfIVJtJU3Xzb23PmQiSayQw9sy)rqOlynihSPoPL(nxKUMezAuvxKsnIvRD2ItV005e6T3tot9lnugYxJR9vj)TS9SJj3UGEP3hmSiowOxy)9CKOOFcn5Ei0TG4aMiAdg9C3REuYx7RqjvGrkS4Lm5sHida(mMK6(kjRxuteEIDxKUKmCkcUU(KwSraklbGv(ACMCN3K7cBOfF2KlpkPqcmQX8Wv1KtWw6qpLMCf5tat4OpKR(0lDUXo3ujsoZqXNnYMNfULUrBJxo8QcGeldlC0rDwTKd3SziDUMoDTGzhqpl0rcDx0owywaJzYvGAAwFqlRWzVi4uvYRFLMTmBo56Sf7XYKSBWXSkJnG4RtEfSF)HHZ48pFbqttB8z5y)hgqf77wsOegONILgwyMUC)HC9Ui7jZocefojq3S6(DdTwmk4rDX6LKwshJJzg0pFZDz86vfQBWnhG5JJH641pi8mUIQ1k3Wc44N5jEGUWNznADflj18fPFfnrRlsHIAkQJpdv6haWoSFpl733QStfzrdlZ4nkflBI3KupZ8VFQzz38yoUd)yhZYan1N1j6AhNfM0UUDF8sIfLRjuDCvnyhDkQUJ2ZPE415KWkOWinQvquRjl)WB0ibTMOpUFOoziymYhrYXwq1JToxhAFanY35lxvrrB(hzzlM4HT4ZEmpwkolIbk84QSGa3MVM3wZDfRcoVDWUYCY141aYlEwJo6Iwbam(2vSpRD6Zn4RTpfwqd1NFZXFIeNKxBNS4(foAcBoutojI34306gZ6bHC99GCfl38ZJO0nT(P77tcJN)67bPVCgfYK7IR3shCjRXDm5US1OoMCxjpZM6xe(7LG)(qWFJJJVauqxorFzh68rJnCGSQ7fu3IBPxrvZa(Yco6qwp4MCZVP5QwK(ACq1Z4iV2oWX0rb9QVWY1Lip8TS1bT6wwrVMIIHK9AQcpcfHo3fOQKypDH0JKnDFPMROsnmEa0LwKEO(L10nKwsHfK8fRkRkDl3NjN4sh7RdJJPY47NZQ(6EDhf5m0xsahWhs6HmDoX3L1ixUJAH2fTEJurNvI6(C5fC7HxsrtgmcGELwCGr5tF5rhjx8HiN55BYvs7HCJJeXpYM(bDDJeWK0R16s96MCZ4uDEHkWfHCdpT5mUy0jjgKTDvTAjMwlnEOj3OB)SiIM1yoloB1962FA5E55FEtUjHb)QYznQxTUm5O80EaAA4cmO70tJsVYbJcibfaCRcc2gsBVdKzYPrP5n50TP2n5mK20WAtUPC48n5UkB4(udArMRU3J1YYm5WOVUt5UI1uUvpzBmPTUOvUSPMCFuv)3MA3(afuACCj2BHkpVTpIQ0bQ8wpLScn5(PM)rm5(PBI82K7Nb7y)yWoZbs1pUj31jh1K7tyY9YGG(tIejV2on5(uuoYxfqiFAKA8XrQrtUxb(7vTzbde9U6CZT9DQp36EQHYPC3BKix80lLSwSQYrUySrMgeLFg4m93cVwnzRIj3Vi9Q7qCAY9ZjHMmbKbFwlcrtUByY9ZBY96WE)cWFFo4VpFhy4m5(B3e32aMC)DSz0m5M2cntjOm5(zHEIFjtU)UoSp7ezFMyTmJRjgQ9b1P7td0u94Fds4Sqnyuh265YOAasNwPBm5EJ1MF5IEcBXVqVo22wfSdKlVPlNbFgLPblEW46rf3dvMEqBgeMJQPEL25G5Fho1ZN(oZ9EuUghjtOWRH5D5zecaZGLkJ3xL7oqNz3uvJM9ljdsYuLwTEeOpAFvEO74RcEI7nmZQ6n4fPJpksRXfzFT9O4zZ9uSUxGMFkUTN)7Z6UjzDl7)8t0)Lhz6ZfA671SUP3ySUdEhX6YtzPSSkeyEd7S2hQ7hx07qNQ1zn1eD9xWPvH8VQwfETA1CaHTZvKYxhOd81(yeD3PUsHkp7PPT9AnNikWfXnpbh1LbKx7WmbbZXd4IdKufDfQF)bOULOfNK8R3k9Vj3FFK32K7xD32RBZPOu4MC)A3oM(MQ9QwINMQ5c47iUk6O6vSdjjzDwGjDmVl6(tYNVJdC89m56s9d0HW2Kg1MSG1mOvWA(GwoP5vUl946G0bsqxUUWiXhovMHINlf6ZUKETC5ZH8sU((A29oRd2SjhQzRiGf1AJx1A1524pZGSHWz(lXt7YElhRzYvIjA)dT7(xHcmBoGcxWzy88nj3)cDhytl8TLyRPW3K7FOj3s5Pwf8pADKWMC)JrXhO974AuQV2T6V)jm5(Ny59nuW(vPR9eUguFNm7iaQs8ky)dOT)dm5ePIYvSoaUGvF)82rX1Fu(nIzfumWzPyGxb9BkvhcSqDiJHUwK(tDYKnykAV2HbuavzTzT61yL9OUzDRNkyiUnkvqW3(PcUdrdBnkZd5OmJGO320IPdf66grCDPBt4TM6YMCVjO)AY9B0QIBW7R42UI7WTP4wAKrIBipW5JKBI35O4UH1B759O6TJ8od9w7jgg1oG39ExQ02Z9vABxPD02uAhqj7vRL(I(dx)AVZrP9KBuL2qVhvPnZ7iuA9y58amEsJ6PnX2DQgBO7RX2Ug75AtJT2LVSKUM05hEYPFNJg752OASHFpQgl)7C0yDJa8vl2Ut1ydFFn221yZ2MgRYqzMPYS6(t7V0MwJ1p5n55tFMbYHr15(Td7UlikOYYzdf1DY7cbO3aFX8KV0Mkplq(x5H8LVlsScKBcx9)1B80Pa5RKNenXqP6p3QsJcKVkgYG)BSZBcK)TW5(F3r47J8BF9ds(3t(DGEwXHZnM(5YDXItCcmqr)AojdbNSCbRRH0PCGWVY(jFJDBfkwllTHt0slIVM2jRQuxup)AMfDEE(G(97pcFWO(J1dFOGXI07MjZ5CBID)TL365h72(wphFZMMum5(TO5jfox3tFZvPxA9(8rvhb1VVtgpboftzCf2UOczqe2Wujxn57QptDplx3Z8NtdsA6ReyqmytDEFjWCTsC3CTIWuvIijoyFteUANY1k)yK3e9vEx)Y7v9qm8vY(W4ggt)QcvLRl6JVHUK6J20XsuvOKOV(R2qtBw7OLLEGKkvlbhvrPulfNL(kiQBiQAhZT0IZOjQkWYZeQV)wlVMyjzwmCyh0Y0Jy9QIAhV00YoVaMstvF8MVnQQimPpLY2x4B10XWxCIwAFwvnmLXS3Mk6mknQi2sjjGoIsTuclrZ8invsFYyoOOOrl3XznOljRdn2ZUdQAOLYpOP2HydEJWLbAyO6fYkb8dBqkjjKbdOJwwAv0rijeYo(fZB9cFIeraBcW(8L80EuQBNMgAMcIYHD6LKoPs0tMrEsXkfOmAiZeq25(QdSziFX3SQoWIz)oM20lA8kSSnH9nO1BDC43ST364BTk89wWBF8gjfsT(8pBK3VD8HXHjct4lwzNy6BE(Mo9m5Yx8QTo6GdL2)bmlTnZKj7n5flFz)t0(7hSj3319feMXqUXLBMC)bwYQEd3MS6MnZ38Uhbf8K4iOm5(EB3cOVgiGUqTktgwlWjot0yBBcOicTjGw0L3)DpIh454EP45RdINZho2SfLsoHC5ZSTjE(m)2TlECh)9DpIh454EP4HaIhJ0joVXadkZB0y7t7rUnXZsnzh07IuFKVNkF(gG85IPukAuFq1Q6BFd)ePsBYNLBXE03fjHQCpvcTmiHK5REv5PUMsGSxyBtc1HuiJj3bEhHyzdo)X7bcJ)JGW4QjfV4jRLuFaLTnHXomAtwuGnFSnH84Uib729L30ohyzw6Lp3OzOoR5dFGTqhfCpqq)7Iw9PjgZFJjK6t7sBBADZ(x2MKwDVREE23xjSfzZVhiBYKoYjImXLhnSO42LSPu92enjOPhI7lnAwA8wG0iwWstAmn)asj320um(nBNsK5IP7XuINzttjAY9N9UoEWVjQRny0j1YfCcJrMCBBapL2tuIuVfEpw4M69ucxtmyZ5RmA2INDMSto72LW9hmx7cxQJFVptAlIJVfoxSAxOVmduAKHYTTPR1HKsQj3pY9LfTil(2GSiDOexDSHo7uxitHTlzXV7KTjlMZE9oU3s9DKeHFpf33VpiGdQLluWYNvOVPRDNiGToZBeHmi4(HxV9X20Sx(kxrSvsITdYyANXAR2bc02eYGGFCQe2o5AvgfjOqOvXciQqPs5vlvElPBZs0ExSOtwRT731vYWwKohjZ3Xk16aYqAkjjRrpcdziLSuOGOGbKqwRZkaq6)kZ7NUEyDnHBCoKdSkeZ4q9n6fgr9Wor)aMBMG5uzij6RFfnDHjfRZQYbAkbmvBw7M7E(OFclgA0KND0XY5UyDdpl9RDbuKBawGV4ZwFHmz5nRFLh26lBrlryH1QsoIBAD7qD7V5icy1jPnh19wI2InHErtrBXQJQILL2OruXBMa72AATmDJKILCIKIPY0ECuyLH0OjJOqOW9By9fLGenyUrZSozaVpklOFsiBiwJ278xG5173FhYR9PHAq)esy9zuKMHKGYy5SEuPCo7FURp7FClHuKzxEDo3MDTh3tIzxpeRPMD9(21N9)6MOrP)v3mn6nCe)bfQp7Q57Z3cvaOSZ06xnBpYra0aihHfvWAMr8IVfKr8SIDJUEqu)2sGBGAubC0W76bUD5eV4TSW2RkZ31HCH3Ql52K8K7ONyEQFYMPPPCW)1Q7VtSgDiNH(a5rE9opU82ICAJMgmXhRnHeBAfJYHc5kX4EBwInfu1NvZ6tM7H4dfmySGyu(TKZ3sb8ZG63kyGG(XuZk9BxHpmlW6lBJIffXC4cgLGp5gYy27PQshCJlueP6rUcLU22fk(xuxvqBs6hgOdCt6(S8PYf5Cfvltl3jl0OUVw(nMiCioV7Xysw2DGV)eZU6(YjceP3EXnrWnrXnX47jkSl54l6MpJB(ZNIzx736RObnzyr)(nSO7(Se9NLyM(v6TPpZQOyFZo85CfeS(ar3AW1nMuZ9nxcgF95pi5OlHjNhOfJd)TvLCtxI5vDwSD2uoZf1p(42FxwzP2PGWLTZyZhBZNfDxH(C2uUKQe(gQtvIAc(YqnUFGFzVE6Aw9hi0er2lqLm6Y4P5lt(uOH3lrB4a0pdSVGj3y8jRkku3Qu5sLeRZpsQZNIN1DBNHSoHBgYcv5LRxjHG2low6NZ9xpxwkMK2mjxniWiZVYUStBsFqp2kAvvkoPIbQfbCs2VZ7S46t62qu9wMCF18wPQ3eb9hle(rB2pSxe6hk1yiipcc3Jejr0EdIFBndgnmDBVuuFOLuf1qum2)oNq5YIfnaYRpxEk)1k4NTi56Izy1jFZXYMTbJVXMnIrDX0Hz8DcsVTMTNtV1XH6KDERnBYKGO1bbSJBhhAAN4L3dzbYNLCJUd2CkNctGZ)cBJd8X(mno8L5d0tWarXTbds32dDBi63G1yu4rNZXZ3bFRg7q8d3ty221doOFxchIrHd2F9g3Abzp6whiBJzbvExlOG5c2KnV78ohO1ZwkqR7ADxQ7sZ)uTKZNNG8Jt(6MCjn5(TGPKJpbwzJ3wZ1Z753zx2ZcCDcjwVCBQ3GGd51oQB3SUuaZZ2jGo(E0NQ3Qxn9ONm4jT7MzrVVD64nYUDtTZDRZ3ZPcFk)Dp1o(i)))
```
