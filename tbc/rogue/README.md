# Rogue — All Specs HUD (v66)

Import `all-specs.txt` whole. Layout groups (drag each in /wa): Buffs, Alerts, **Rotation**,
Resources, Procs, Cooldowns, PvP. Everything that used to be the ring cluster *and* the combo
row is now one sub-group — `Rogue - Player Sill` — so the whole instrument can be dragged, or
disabled, on its own.

**How to read the new Rotation lane (v61): it shows ONE icon — the highest-priority thing you
are not doing. Grey means you cannot pay for it yet; colour means press it. An empty lane means
no rotational decision is pending, so press your builder.**

**v54 replaced the ring cluster with The Sill: an instrument strip under your character where
the rail length divides evenly into 100, so a breakpoint is arithmetic instead of trigonometry.
v58 takes it to three pixels per percent — a 304 × 74 px plate under a 316 × 86 px alarm rim at
(0, −125), with 22px bars and 20pt numbers.** Four stacked 300px rails — threat, health, energy,
combo — with the numbers printed *inside* the rails and every breakpoint drawn as a full-height
waterline instead of a mark on a circumference. **v58 also makes the nameplate combo pips
actually work**; v57 shipped them broken, and the reason is worth reading.

No aura is added or removed in either version; all 58 UIDs carry across.

## v66 — the whole left side behaves like 还击 (Riposte)

The player named the reference directly: *"还击 works the best, all left side should work like it
in terms of position, effect, size etc."*

They were right, and the two left-hand stacks had drifted apart. The alert column has shipped
one treatment since v3 — **40×40**, a **`slidebottom` entry**, and a leave that **slides up 150px
while shrinking to 0.4 and fading over a full second**. The rotation lane arrived at v61 with
none of it: 48px, no animation, appearing and vanishing between frames.

The lane now takes all of it. **The values are copied from `Rogue - Riposte` at build time, not
retyped**, and both the patch and the build canon assert the lane field-by-field *against the
reference aura* rather than against literals — so the two stacks cannot drift apart again, and
if Riposte ever changes the lane follows.

**A mistake this replaced, recorded because it nearly shipped.** An earlier draft of this step
invented its own leave animation and applied it to *both* stacks — which silently overwrote the
exact effect the player had just singled out as the best thing in the HUD. Deriving from the
reference makes that impossible; the alert column is now provably untouched, byte-identical to
v65.

### Two prompts that stayed on when they should have cleared

`BUILDER` and `EVISCERATE` were visible whenever you merely *qualified*, so they stayed lit
through their own cast. Both now put **Action Usable** into the visibility test:

```lua
IsUsableSpell(spellName) and ((startTime == 0 and not paused) or charges > 0)
```

`GetSpellCooldown` reports the **global** cooldown for an instant, so the moment you press the
button the trigger goes false and the slot empties — then it returns on its own when the GCD
ends and the energy is back. A prompt that stays lit through its own cast is not telling you
anything.

The `desaturate` conditions went with it: there is no longer an "earned but unaffordable" state
to grey out, because that state now correctly shows the **builder** instead. If you cannot
afford the finisher, the next press *is* a builder.

### The lane is 40px, matching the column above it

It shipped at 48 to outrank the alerts by size. But the two stacks share the left edge, and a
20% difference reads as a mistake rather than as emphasis — rank is already carried by position,
since the lane sits at the top. The slot box and both clearances are now derived from the size
rather than pinned to it, so the next change updates them together.

## v65 — no aura can render as a question mark any more

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

## v64 — 26861 and 26865, as asked

The build now uses **Sinister Strike 26861** and **Eviscerate 26865** — the high ranks a level-70
rogue actually has on their bars — for the builder and finisher prompts.

Earlier versions used the rank-1 ids `1752` / `2098`, reasoning that ranks share a cooldown and
share their art, so rank 1 resolves for a levelling rogue too. **That reasoning is still true and
it is no longer the deciding argument.** The scope of this pack is level-70 play, the player is
at 70, and the prompts were not showing what they expected. Where a rank-1 id is genuinely
load-bearing it is **kept**: the `spellknown` gates still use rank 1, because
`IsSpellKnownForLoad` name-dances through ranks and a gate must resolve for a rogue who has not
learned the high rank yet.

**What this costs, plainly:** a rogue below the level for those ranks has no such spell, so those
two triggers will not resolve and the lane falls through to the next rank that does. That is a
real regression for levelling and a deliberate trade for correct art at 70.

### If the icons are still question marks after this

Then the remaining cause is the **`/wa` options preview**, not the string. With the options
window open, WeakAuras substitutes fake states for every aura — that is what puts `56.4` and
`3.4` on icons that have no real timer — and a fake state does not carry the spell art that
`iconSource = -1` reads. The lane will show a question mark there and the correct icon in combat
with the window closed.

Judge this one in combat, not in the editor. `references/gotchas.md` has a section titled
"The /wa editor preview lies" for exactly this reason.

## v63 — the lane's icons were question marks

Reported in game: the lane renders, but the icon is `INV_Misc_QuestionMark`. So the prompt was
firing correctly the whole time and simply had no art — which looks exactly like a missing
feature.

`Icon.lua`'s `UpdateIcon()` resolves three ways, then falls through:

```lua
if     self.iconSource == -1 then iconPath = self.state.icon              -- the ACTIVE trigger
elseif self.iconSource ==  0 then iconPath = self.displayIcon             -- a literal path
else                              iconPath = self.states[N] and .icon     -- trigger N
end
iconPath = iconPath or self.displayIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
```

Every rank except `SLICE AND DICE` used the third form, pointing at a spell trigger that is
**deliberately excluded from `customTriggerLogic`** so it cannot gate visibility. An excluded
trigger does not reliably populate `states[N]`, `displayIcon` was nil too, and the fallback is
the question mark.

**The fix uses the form this pack already proves.** `Rogue CD - Kick` has shipped correct spell
art since v3 with `iconSource = -1` and no `displayIcon` at all — `-1` reads `state.icon`, and
the state is whichever trigger `activeTriggerMode` names. Each rank now names its own spell
trigger as the state provider and switches to `-1`. Visibility is untouched; only the art
changes.

**Why not a literal `displayIcon`:** a hard-coded texture path is a guess unless it can be
verified, and this repo has already shipped one unverifiable texture string — paladin's twist
prompt still carries Horde-only Seal of Blood art. The client knows the icon; ask it. This also
keeps the art correct on any locale and at any rank.

## v62 — the lane always answers "what do I press"

**影袭 is now visible, and v61's refusal to show it was half right.**

The objection was that a Sinister Strike prompt is lit most of a fight, so it teaches you to
ignore the column it lives in. That is true of an **alert**. It is not true of **this lane**,
which runs `limit = 1` and draws exactly one icon, ever. A bottom rank does not add a competing
light — it fills the slot in the moments nothing more urgent is true, which turns the lane from
*an alert that sometimes fires* into **the next button, always**.

v61's own rank 9 already proved the point and missed it: `ENERGY CAP` existed to catch exactly
that idle case, but required energy ≥ 85, so a Combat rogue spending normally essentially never
saw it. Which is precisely what was reported.

### "Usable" is now asked of the game, not guessed from a number

The energy threshold is gone. `Action Usable` evaluates:

```lua
local ready = (startTime == 0 and not paused) or charges > 0
local active = Private.ExecEnv.IsUsableSpell(spellName or "") and ready
```

`IsUsableSpell` accounts for the **real** cost, so Improved Sinister Strike's 45 → 40 needs no
constant in the build and cannot drift when you respec.

It drives the **look**, not the visibility: the icon sits in the slot whenever you have a hostile
target, **desaturated until the game says you can press it**. Grey means wait, colour means
press — the same idiom paladin uses for a locked GCD. The old energy-cap meaning survives as a
**glow** rather than a rank: at 85+ you are one tick from wasting regen and the icon lights up.

| spec | builder shown |
|---|---|
| Combat / any non-Mutilate, non-Hemo | Sinister Strike |
| Assassination (Mutilate known) | Mutilate |
| Subtlety (Hemorrhage known) | Hemorrhage |

### Why the build still uses 1752 and 2098, not 26861 and 26865

Max-rank ids are correct for a level-70 rogue and wrong for everyone else: **a max-rank id is not
in a levelling rogue's spellbook**, and `references/gotchas.md` records what happens then — a
failed name lookup silently tracks spell 0 and the trigger watches nothing, without erroring.
Cooldowns are shared across ranks and every rank shares its art, so the rank-1 id resolves
correctly for you at 70 *and* for a rogue at 20.

## v61 — the rotation lane

A player reported, in Chinese: *"类似影袭和刺骨战斗贼的rotation你并没有在左边 highlight when
it's useable"* — for a Combat rogue, the rotational buttons are never highlighted on the left
when they become usable. **They were right, and the gap was structural.**

`Rogue - Alerts` held seven children and every one was reactive or defensive (SnD missing,
Riposte, Feint, Evasion, CC on me, Kick now, Target immune). `Rogue - Cooldowns` is sixteen
icons that are *all* `showOnCooldown`, so an ability **disappears** the moment it becomes
usable — which is this pack's stated principle and correct for cooldowns, and exactly why
"usable now" had nowhere to live. The only affordability signal was the energy rail's 35 and 40
waterlines lighting, and that says you *can* pay, never that the points are worth spending.

**刺骨 is Eviscerate. 影袭 is Sinister Strike** — settled from the installed addon set rather
than the web: `Cell/Utils.lua` ships `["ROGUE"] = 1752, -- 影袭`, and Questie's zhCN text for
the level-quest *刺骨* reads "记住，刺骨需要连击点数，所以你需要先对训练假人使用影袭" —
Eviscerate needs combo points, so use 影袭 first. That is the level-1 builder, not Hemorrhage
(出血, 16511) and not Backstab.

**But the Hemorrhage reading still had to be built**, for a different player: a Subtlety rogue's
builder *is* Hemorrhage, so a prompt that hands them a Sinister Strike icon is a wrong-spec
prompt no matter what 影袭 means. The lane therefore carries both, gated on ability and ranked so
the Hemorrhage variant wins where it loads.

### Before you import v61: leave *Arrangement* CHECKED

**This release is the first whose payload is structural, and that changes the update advice this
repo has been giving you.** v61 adds a new group (`Rogue - Rotation`) and re-parents the old
`Rogue - SnD MISSING` out of the alert column into it. WeakAuras files both of those under the
update dialog's **Arrangement** category:

- an unmatched **group** sets `activeCategories.arrangement` (`WeakAurasOptions/OptionsFrames/Update.lua:1128-1132`) — note it is *not* filed under `newchildren`, which is what a plain added aura sets;
- a changed parent sets it too (`Update.lua:1055-1063`);
- and the parent is only ever written inside the arrangement branch (`Update.lua:1741-1780`), while unchecking it triggers `RemoveUnmatchedNew(..., removeGroups = true)` at `:1728-1732`.

`references/gotchas.md` tells users the opposite — uncheck Arrangement to keep positions you have
dragged. **That advice was safe for every previous rogue version, because they were all
property-only changes. It is not safe for this one.** Unchecked, rank 1 stays in the alert column
carrying its new 48px size and lane triggers, and the lane's membership gets decided by
`InsertUnmatchedFrom` rather than by the shipped child list.

So: **leave Arrangement checked for v61**, and re-drag the pack afterwards if you had moved it.
The exact end state of an unchecked update needs a live client to confirm; which branch runs does
not.

### One slot, nine ranks, no custom Lua

The new `Rogue - Rotation` group sits at (−150, −96), directly under the alert column, and
carries `sort = none`, `useLimit = true`, `limit = 1`. WeakAuras draws the **first** child in
`controlledChildren` order that is both loaded and currently triggered, and hides every other
one. That is a priority list evaluated by the engine: `sorters.none` composes
`SortAscending({"dataIndex"})`, `dataIndex` *is* the index in `controlledChildren`, and every
child the grow function did not place gets `controlPoint:SetShown(false)`.

**Ordering replaces clauses.** Slice and Dice is rank 1, so no prompt below it needs an
"SnD remaining > 3" trigger to stop it shouting over the buff — four triggers deleted, and the
mutual exclusion is structural instead of hoped-for.

| rank | prompt | fires when | icon |
|---|---|---|---|
| 1 | **SLICE AND DICE** | SnD under 3s **or** missing, and you hold ≥ 1 combo point | amber, red once it is actually gone |
| 2 | **RUPTURE** *(Mutilate only)* | your own Rupture is off the target at 4+ CP | red |
| 3/4 | **COLD BLOOD** | Cold Blood is ready at 4 CP (Mutilate) / 5 CP (everyone else) | ice blue |
| 5/6 | **EVISCERATE** | 4 CP (Mutilate) / 5 CP (everyone else) | the pip lane's own 5-point orange |
| 7/8 | **ENERGY CAP** | energy ≥ 95 with Mutilate, ≥ 85 without | the builder's own icon |

The lane is 48 × 48 against the alert column's 40 × 40, because it is the every-GCD surface and
has to outrank the reactive one visually.

**Grey has exactly one meaning in this pack: you cannot pay for this yet.** No GCD
desaturation (a rogue's wait state is energy, not the global — desaturating for 1s of every GCD
would strobe the one slot permanently) and no range desaturation (a rogue holding combo points
is in melee range). Cold Blood's 35-energy grey is the anti-leak instruction: *not this GCD, do
not spend the points yet.*

**Cold Blood → Eviscerate is one slot that advances as you press it.** Cold Blood is off the
GCD, so the instant you press it its `showOnReady` trigger goes false and the lane falls
straight through to the Eviscerate prompt underneath. That is also why the lane carries no
animations and `animate = false`: a finish animation would visibly delay the handoff, and the
alert column's slide-in language is wrong for a slot that is occupied most of a fight.

### What was refused

* **A standing Sinister Strike / Mutilate / Hemorrhage "usable" prompt.** It would be lit for
  ~90% of a fight, which teaches you to ignore the whole column. The honest 影袭 answer is
  ranks 7/8: the builder icon, shown only while your energy is about to overflow.
* **"Build for Slice and Dice" at 0 combo points.** At zero points the correct press is the
  builder whether or not SnD is dying, so the prompt never changes the button — and ranks 7/8
  already cover the case it was invented for, at zero extra cost.
* **A second SnD prompt at 6s.** Rank 1 gives three GCDs of warning and the buff row already
  glows SnD at ≤ 5s.
* **A Backstab positional.** There is no API on 2.5.x — no facing query exists anywhere in
  WeakAuras 5.21.10, and `IsUsableSpell` does not encode it.
* **Adrenaline Rush / Blade Flurry / Preparation / Vanish "ready".** They fail the lane's
  membership rule — *a prompt may enter a ranked one-slot surface only if obeying it makes it
  false within one GCD* — by minutes, and stay in the `showOnCooldown` row.

### Per spec

| | Combat | Assassination (Mutilate) | Subtlety |
|---|---|---|---|
| SLICE AND DICE | ✓ | ✓ | ✓ |
| RUPTURE | — | ✓ at 4 CP | — |
| COLD BLOOD | ✓ if talented, 5 CP | ✓ if talented, 4 CP | ✓ if talented, 5 CP |
| EVISCERATE | ✓ at 5 CP | ✓ at 4 CP | ✓ at 5 CP |
| ENERGY CAP | ✓ at 85, Sinister Strike icon | ✓ at 95, Mutilate icon | ✓ at 85, **Hemorrhage** icon |
| Hemorrhage timer | **removed** (it was wrongly shown) | — | ✓ own-only |

Every gate is on an **ability**, never a spec capstone: `spellknown 1329` / `not_spellknown
1329` splits the combo-point ladder exactly where Mutilate changes it, so a levelling
Assassination rogue who has not learned Mutilate yet correctly gets the 5-point set.

**Cold Blood is gated the same way, and an earlier draft of this file claimed it could not be.**
That claim was wrong: `spellknown` and `not_spellknown` are two **independent** load args, so
"knows Cold Blood but is not a Mutilate rogue" is one gate — `spellknown 14177` +
`not_spellknown 1329`. Five sibling packs in this repo already ship that shape (paladin's Hammer
of Wrath, druid's Barkskin, mage's Ice Lance, priest's Prayer of Mending, warlock's Demonic
Sacrifice). As first written, the non-Mutilate Cold Blood prompt loaded for **every** Combat and
Subtlety rogue and relied on a runtime nil return to stay hidden — which is exactly the
"an ungated element loads for every spec, so it must be justified for every spec" rule this repo
holds itself to.

### Also in v61: the Hemorrhage timer was ungated

`Rogue - Hemorrhage` tracked `16511/17347/17348/26864` with **no `ownOnly`** (unlike Rupture,
Deadly Poison and Wound Poison, which all set it) and loaded for **every rogue spec**. A Combat
rogue raiding beside a Subtlety rogue got a countdown for a debuff they did not apply and
cannot refresh. It is now own-only and gated on `spellknown 16511`.

### The strongest argument against the lane, stated rather than hidden

A one-slot lane **makes a choice**, and a child that stays true while you rationally decline to
obey it censors everything beneath it. The concrete case is **RUPTURE**: on a target that dies
in five seconds the correct play is Eviscerate, not a 16-second bleed, and the lane will sit on
RUPTURE for as long as you hold the points. There is no buildable guard — health percent is not
time-to-live (a boss at 5% outlives a 16s Rupture; a trash mob at 90% does not) — so this is a
mitigation, not an answer: every other child is consumed by pressing it within one GCD, and
RUPTURE is the first child to cut if a night of raiding says the lane is too opinionated.

### Continuity

`Rogue - SnD MISSING` **is** rank 1: it keeps its UID and was renamed, moved into the lane,
resized and re-triggered, so re-importing offers **Update** and upgrades it in place. Eight
auras are added (58 → 66); nothing is deleted; all 57 existing UIDs carry across unchanged.
The alert column drops to six children and is purely reactive again.

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

## Import string (v66)

```
!WA:2!T33E4XX1195blLf5kPisWhYI6bxrzjtslXGDXUybuLQe2fliwsaSlNDbFkkSZU7amdXU7mCMzXdw74Ayzfghf)aQvXrr2YgXvToj1)bARA)s)Q)QzDDCBttUbXrESCu(CrDDsCR6xet)QttF4Eo37D2z2h4jHOin1FGbZC37DECp)o)UN75EU3RWjA3uSZdh5WD0E52l2EXlD)lMxQWefn00JRvsZ4O(85lTVooCe92lOvXYqRuj5IXvulv0qUYfxuuB8QYbE0aXQo2yMl5CvVLKnSm13HZ1IYMAvnkiBwl)Pn0k4jdX10kvuBQkMluldtMwF71kVMLKLQwLLYRzuu2ig)fuF7XkPEXlkzumqw4gyPQBmDk49q2siplNkgZWs43BRZBipoClYoJUS44gAv1NNLLmQxu(wwqQsbfnJ0AQvSYhpXWztiUa7Nzvcccc(wqTYyAgLPVi(xuQQfuGu64vM(nKkqpPlrtljdl)5htTIQPI)yW)S8pRLH64JlByU3h2GF6ZjwrQSSP)yw47JuvdPqZAQlxQuYIM(xYSAE5jLRyLbQvvNEHrJ3BMSJMjBVIzR9tPnKHFsmt6edo48fLZd5e)0mgiXGP7FKbfPzk)aYsLSuIvfElYRxsAgzJ5QwH)k4)YSVqwf02Uc8PlBurQ0jGxu4B5SZjvrL912f5U7)YYsMYzSaH(4wk3kzFXQOvrEXIWloMJrXpddtzaIu0CwmR4ldjySYsQv6N0buasqsisNKWW)3BJPmNPCPXOv(KDTF1I67Mj4ZglofmvkqgD5cMZBPvys2l3wtV7fgZaQbH3ijljFxHj)6htcFY5ZexmrIH5YWKvGpqFHQQwCHonNSRsxizQdg6G5Hx2Xuh3)8qvQifBy6x0SGujzFZJFhQmrBSsAsf7pMjat2Jy5QakZFmqsvypKe(flusY0eplVfuUkw4PCCvIIJlRVJmxOQKHCG(RcFeNur1sU9cFPyxAFK2QPxr8Dg994a0ZusTGCaPkfd0hCYvQH)RQBv1q2PE5rd0NSuXsZeaQYm1Q4MC)QqjpPS0evKnn1B3j5bKlRzyOinUm52i3oPxFKDs2f5NtHCNFzY2j7G0(Tq2JFYUPOCssYrjh(SKpai09t2RFY94NCV79Hj33ZrUF)Gmla5b8t2p5bjFqYdrEyYhICaYbjhI8HjpIFsxWD9r3g5X9r(5ritJI9iRoqae(KTqEs)KE8rEmYFR86qLhakIsEIf0L1pvWIhVyFD2jPBq(tEk)K7qGeZpjE)K(WkEs)0JhHECa6X7Y)LEW5vbPzgk)Z9((i3XJSfYDkGvalwGt6KzkvD5Cx25suWPu)3)WW3)RIF8xg1uP6PQfnpuSibJgmwxrJgUwTau5avmxPQPCIPboHmmv6CyDhwPHvypI)fkQAE(QvakJjLdjvQK(oKONNLPyoKwr5F73hieUYeYY69IGnlruntbRHbLDtjluVdElFQh71xC8sAt1VH8fQkxPWmP3shhoueY(maqn(dlGhofNuCw8cu9yX8vTS0QKc0MasH5XKhKQyVBA(pnp)ZHxuRvaFxg(QoItkk0FmdvDjgEQc9fjRIAbk6Zh93hufoFh0hqmgH8L2PE7wYtBnQPIur3xT5OPHh2)db86EYHlb8sSuDOkI17iztPVtAIaBSgYvv4KQfb(UEHlVc9haos5I0e)4lY4iC(4Um93pFvtl1XMbQwnW2yKZcjgB4udNGvfI5zEAgluRAG9Qog0yO(273q9IboEvPIiluGSzR7BZ5jTinTPGV)tAiPp7j5NSyT7dL4o1izhm5Wj4F7EAp6YjhE4eIJglv2SPgYTqy7w3h)B6u19nnPQPA(sY5gJt)nkYD5JSV5GpiwkCMF(hfTULNItzDkQmOmqo6I8R04nUQiRoUI1XjXpXCaMyuklyoUk3rE48MQvgVKSOyQJmscsI9q(m54QMm10Thd1ijF2CiRdtrp2f10kJ0HDIk)O6nYeCmopcsqa8eE4rAiL92ykIsL0vK8jofk5poqdaeitDMcblLm6fhl2ugQvWgsafO0KTi6kAjX27dlwqrUWe9tUpFZoPKHQeuBSK806QSg6YQwwE)A67)XFcXjLkvvU9igfuKQmUm02o5LYnRoywcy7ZmyJkho4HrG)Soel503LZPimRpvt8Mxm3LEqIiYmvsGZmrYKJKTfuqVgL)f4rmGBrQkLMjhJ3bA8XyCzlK85u5iJCXyb7jCNX6URo7boeUdXGbdfTt6XW0Jred1v3DffjLOS4gd0R4qGrdih(PjNHCwk7d5PP8nKZrPzipJd1czusobIejpPWUjffiYSQUXuiJ7JOOqu9ro)oitaA6e4lQmOptQWAArJOtUaXGy(XjwcKQW9EsYuWnCAYmS7Xfj)DiFebYhL8lq(yK)UKpozwYN4(ipRa5tMBmYZbqyYVi5sS71VuoYNcAP6xwG88ioK8R4I)iFAYNPvWoYNTomh5Z1eGBWnmGJmNpYlWbAtiDArvO9xZZpa5VpfIrEro8Yp5lMJ8k1K4p6AvGt(sCrn5l7kLd1DWUXd9ac1oJ0j9yyXqr6mCpGaUNU6wmu0GD7kMjF1LxaF0RgbS5gxaVlYN4byc4nj4YDDneUm0McCjvXSHhAYW9vv7cRcC5tUkWfQjkKroJyNbd1zy6Xi0JDrpgLES7gSvbbt1zDYn3uadVPitNUy8UoyqjORlXUkLPmkGroQyWUIemOyWODgok9y3us8WnWm0Oa99u55WJjb4XsOXkuR3NOc2EmhU0FtGM5DZ0wFQp2Ah8KAtb8CGqh7cQN5OMtwAQLd80XCsgfyMS)S7H478U9uuvxZ0sUMFw6xgSG0T)LjMuc7(m6(LY6wUoyjE8aPgoWqjCt5yjJFSadN6KUDUmBVIhjr2ajhAOraZJXoscVT353y2XnulIwWUFX(49HCwW(Km6sfaJo3aDJCbWESQLRWVbaMTR8mBFbJ6uhVczxgMwsy)KeWUaUcD(ZTp2gmxziNBwabmOAzvlfOxW5nKkQw18zVDSRWy3E3(LlotfPYQfO(hc6wCmtndlsW5hd6(ECvJcGHXIM471DawRHD0DjWqw4TPIv)qp40mYl2BFjhjdcjG(bNg63QdY4waqZCynfTVi3gIFM1G7vlbqMBCWZFuLWN3uFMoJbp9P2)iPrwbXs4l7THcEa3Tr7v9L(GerbhmuD0naE(E)AGu5fHEhuqRCEjRsAJt2VXOdLmtMe9nRJ)DApc5aZhNMHadc54dkM5Kjh(iZc9f1AKkQwKpm25WrldM9GqHC0RC(XCZ6KUy6EffpniJzpsY3hGa)jK3eV7K)uku4haqG)t5ilLJ8FM8dzz8s7q0YqQWeXWo5PVd8opUCfzd1czu0MkvLClw3Llys)NOSuXzaS2Cuv5HLklV1O)wK9jsVKI8oG(D742ruFyCdOxRboaTh7huFN4Jrg7c)O1Ub5w0qwQugNlnC01QXQqZeaS1BhtcWQAgYAqhnaXoKo(5biCApMOFq5Q1GB(cq3qbnY2z)N7haOIwTG(HhJ6PaTkhW6GbmKHE(xjWbSoBWZfqZiG1zdDUds9xK1z78CbKRuCT1YTyAOFXLCj7XFU7qOUsqG1phL1p37knJJ80K)vlp1m5RJYrxgzVemGkcOOamPPb9no7mQZmgzF51bXl0fPWgOZjtv1I8twWSeixYRzb14unL3mewaq1Pf81xA745lcYTkMLq)eaOz9DycxJ9eoRtYq5(RGc8xph1pIuxT4KhQRsYttFg8vlmzoba6hS9zkUT2NwyoApwXsmRtjOifAbYXk30SY1XTUihdXEO5OzKw(C1iC(gCVO50Os5Eh6ihDKdeCGHNgBu5oeqki0ruOBHtc0y6hmj6a4Xa2TNgV28PLYRws1AMrNscqWAgJcD0TujSVU8gHwrwLNb0C)wq1XHqDn27Rcu3BPxWcmyrF7zPxfiJQvvkddOQUKBUO0gZvRe7pAhu1QAjmk2lBjGXD))TFcuXAE3Ib2bXuROuhK)lKFe5plh5pN8xGn88J)HxeEN(VY0)j)3iVvoY)DrABKK)suZL8210tjxj3kBq8HAH9t)pRxLkCKLtL6Qvja(ow36aKFccnHJ)VyWDYFZkc2j)Vj)FCWZK)VK)FKFAlGT2cVpBb4yB5Sf85apTf2cC5T4cgVCdGXJPmY0rpALd0N5zCbJ2c3Q(dUCyqd0iKrhJkPw3OpaRuqUILcDWq2FKoQzSbkQFa)OrbJIdrcA3mRbM6kro99u311aFT)4ReuBR76l0ewZGBa2MnAJkNXdr9TUbBphhS1VhtNQZyyQl(OT9JSVWx1nqiV)nnG8oFhJPwYm6P6wAM6rEFOgrE0w05EYL)pGiSi5lQWrFyV3APh7UhAncT3Bpms1fhSNRyG41g9ukUSjbD9vvyTauXG1uyTgVQINQtvfuzGvt1((BU6cQi5vxyzDRY8wvTCDUVbUSGryhP4lg4ACh7d29A2(aUdYR3T1EmAOUF3Xb61zgXNmh3sIpIWyiegG21dRrGoIRhdW1uvB093kRSRbEyrCGMKYfsFs9CE6PxS34Hj)QOVGjF(f4d)nTRoA67)jEcYlflt2rgM8RJU(TXkPx(kUEaMoeg1Ur2cbCk)Iy5hDOeXhO3HtgFzUr2c7VvLvmo6121xzmsNcmRptM1xPI1FIEf5fHYXq1T9T8fyrSan(zTMkPr8ud3)izs4PmHXxVEOnKUsVJIPsL1tPQrgUSpPmjhmXWXt4TQOB6tj0YxO8P7nEY(p96QmlYkZg5XPV9mXhivQbhnjgqcIJKo767TTVKzAaIeMkS7Gxrs9IHh2ASTghIZVzdeNIJNEY0fkKQYqYiXjVH358HCNpCR5oRGdtj0wQwPzkRzOR4sDkSYmNvaMZ(PE0czkpqS4sMw2c7mhRL2xZTv1f7L2ZOaJqhjfSfww7Q)4IvW2wR547pKBjpe1wufOJBudlYX7k4UqthdexrcJKdOZKWpxW0Jt1MRwjmyNjd3D67ulB1(6DY8AyNRgUCBH7Xl1TTW92mt9DVwyQrlqSfUpfxtEBbn9xhKPuQABH7hY9(QJMEVm8)Tq(8xMffnveXoQ4OjiW0bYrEzY5wjq))2wb6NqTWedpvtG(7TrqFVCtvpgK)1Uvcpd3viSH5XJxCbW7i)MH6kCOyb7iuhHc3t3XIejAN4vHGZ6Phr4SODlgos4o7wmyprIgwSZWHJge9)B9qEBHo54CBHWEEg2crSf66gAG8MJvjRfK8A2MdksELT2Ovqy)ReW8B1kGPA5YvR0mB8J2A2yfGgE0IQtQwrMgPxy8HH9eHHuRpIK2R(oRfhE0Ogd6NEPsng8qx46WGh697g8qu)V(ele5e9yK)0DemuXiRR4gcRrGVjgO13FJBnsVLKmkhGgQzUHyfw)G1vwYUzK7Idrj1sUjYIiVgsmrfzJXNHL4ECJjYY51cKrRWeYwbc66hEw60qdbsU1zpuRZEOLj7D26S35YK9WTo7HxMShP1zpIdEcq0ChWJilapbcMbAsWWev7MADxK6p0nficc16ywz4oeDTmapas(i(34JydGZP4PUOXSOTq)ayRsCZ8ftl29b7Fgxu47hb1aSeaEpQJR8VZxUTlfGKgkfnoLa7KWqccJ8l9DfFWEhkD2uXgS34hR3(6lz2KNibNIaQQaDDQtLyhOTLNVSQHHMHItZmWJDoWEOkfX7xi4wqvUEs)67OOQzbdzl5rDh7bp6Qg8xf9EDPq6TyXuahcguH9IX(2tpKCrvPNollNMpnlahhLgBJJYIXRdBnUeYFdvq9SCAZoTPuR1dSvJFY8uNyMUAjt5wQEBlmakMXXk7B6N8DXbozQSsD11bNUYPhmntCq739R747hBHTbmT)CqtEyRC3gC(TV)UrNjAlChOVdXgdHwf9AOyTwaF(jYZckmfMjklq9QFf6Gd5HL3GNesSt2rUygsQfZ1kN2Hi4jf1LmqZodMlV1uaf8m5czjxj38SlgtDs5CZoMgKLYsv4Tryl8mawb)NTWPSfoDdw8mRAf2iZa25Wn4HATdJl)LjZrHzaUbzZO9bWw4m1WkyDMTWzfJbDpPpkG9jH6MZjuphUJvkhI7nlNaiGA4a3ALA2C4jJm7nADoRvp)c95hXkZDvX8BlKKwbnkI5aWhfCC8ro(KXIp9G9otuQkaGDE(ZAlKxzTfUaqRapwEqOBm6mcS)pn2ZLfKkIHnOCXHKMUn3luR0g5otVLGDF4ixbKGYiOOsrw4lYSIHYvX6cS(UCdJtmC2zzwzbtmaMz6w58MN(RDdvenljvXsywq)Uxmo7E29a1ElPZhblwGUEO7991g(fRV981U5ootXRGn2J5PJJ3oIEaDIxcD3UtNgH32U4oXg6YORxmeLghUTogy7ZtxV7HArwi2Xgk1cm)0tdDowy0rEP25pmbkwfKBBuuG(oCR251H6p2gJjJsH9uh6sFaQjKx(HQnWdp0dXnMu)rQfXQJYMwaUdWXOfLlOwwQ0O6gWjMuA2wA7P(dSc3ewc5hUA58YgESsfRyJgI7ve88WTYO1DP)qRW9MwhrdAFXXkPPzGJvhF85uU0oxK3oWq8MvUJE5mgZJbFl0HEAG670WLZKZqyjEcNWjgszEXB0YqRqIScTV55bvlkB2b)K(CdOzNBbxOyl8rjVWTWcjw4YyoTPzlu6Y80CNKk0Mcjp)TDz(JL)AIQ7l69vvgh7FiFuAX8fm00hLg20HdInrUDqpVxUknvdxrFhU6qEEVQfXv82zCBJbT1yfAxzE6ueHQ6s9(m1S9ZO04twTIcz7xXrTM)bqJ)8Av4aVnutmpLpOFvdtlfkD(C0eW6P8jhotY(sSGglqVlusvxzw(fM(5TMCx(VI7hyTOTgRrIez2cALXro1uHsXE0LmlRPzP4mC55O9jzl(D6cFbpnlAluK3IOTGCULJKDsBHXWgdTfgh(tb(tf(78Sw(EIfotS(Ym4j6UNHcMb7Nd0G1cAgQqlL0kG5hiLyYZKA4S9oitoonxoUh)g06a5Ikx6XSfWAknK52wqVnBHlG80(aAA8(zlyQylybpWQW)NeYYuucvBHPDirTfMr4D4MaD4HVfKhEILRHCpC1TdS0D2bKR2F81i17CLbSmTZhiLlN8TEIxpTmyl83tG8uhLtaQV9hQUraRgl4k2L6X96x)oAInQ(XuRzktKqt)GRsXCjYSf(e1fKzqF2rsT7M8SJ3cQW6VlSeTf(4xAN2cplq498TXz8Sf(Kia45Gt(fbmYLSf(Li7Zw4tzl8ldWLNNrqzl8Ra6H2cFAhEOGDtE(7Xw4ZWyFSf(SiLJZ9w4DUB9X38V1qsm7hxtwmH2oohu0xaEe2cFoM6OTWhbFIUuD2cGUmyp7lAl8RYjXSf(8kCBr)1SfEjBHFDixVSlfLTWxWLvYw4lY4JoMTWRuJdAJA2aqZeVCpLuJEQEgEk0DkGwZrD9Tu3u1PqDdV5FzBH5Tf(nQrYyl8vwo(Lt5lYgGF51CPnetRnf0SpgWq64zie)wRNeH6j7A)yURc2NJUUyFePptKakc3IrhVRQVlCqVcF46neWdT1xdkv4oAzPISCLAwG4I)eBp4AJ36tT(89hLOQg)z4iT0EQASj0axLttSE0L3gtHJPtvNAgvh0R3mzWCNNYTV59uWBCxryDbP(hsl)uuwMhYow7Fk(wXVIn2dW7xHV3JY(gkk7b3KOShRJtC((pZWtD8Wt5qztvGD6IDOLJVM51Tw6jLvG8J8ISMe60ZXU4D5Og0dimqV0q)2z1quhs8K(BGKIfZTVMxw6FlKL2w43EBUd)dsyBl8pE141zdKZoZvN9NV2soX0KQjlYMCl1C4mpxNhTIhcUdZ7MpOxlUpC3Mj(Ri)p0)GTiouPHHkl6tdXJ(0BL8yZnCVdLi9G9Mnb3fG8rXWwyiQlNq339auFmHdKrCD0nXD0rWnUNypNc553XA3ToqtUakG2Wlfe4TqlJB78tV7V4rzilM3C81SGh)Sab)tZ8ejyxXGwdEXO9N4GXR6XNAC)tJyGFKJeDjAlCEdRX5Q16EopaKVw7b9Gs4Y91ikPEXkIsSf(N4fzyl8pLdjSf(NT8qbBHxdLZmp8Y9A33IoeFoJr4CynuNrOJSxoYpn9wcI6j4Wgshyq(i95JLoD4(wRo5BykccDTUTW)CuTcPVOAz3LFae0G2CdJ)RR2mO3JSaVtqgmOW1DKbxvIzAfDd6XPwb94q3qOhtBuY1hA4ai3KKRrT5IdpCVwQdCIOzp)QOnBl87aAW2c)lRx1n0n1QUPVUx19Man3JVcAUDEJslW94gctb91KyRr12b0YCHYjpvhrQCXnMABN3uR2kEDVA7b)zF12mRGAB4BeuB9X7Zog9PD7RjzwJ6SLpZzumnuoXqtm1gtNn8n16SzVUxN94)SVo7iRGoBKBy0zDJy8gLznQZQny6PhFgZos2rXnMoBKBQ1zpXMRoBhK)14kdWE13LtS3DszjD2u)VGzTPVFqYVR782N8T3qtyFY)o200p2Gj6pl5)a8v87T2NA(K)J5i)(5qVw(h4zI4tiyCa(hcvrlMJ8hTnYD8Mym09Di)XTyQ1FRyL2RtNs9SO(rEOSJyE8SNQW5pa57jkM8idW4dFJB5QDE0)GRq8C7Dn7yECoOhVKwfzZCS1VJhtmuhD0ruXqD3rpDkgoupr7AtCDyzfIU)3rMj339QotU7DZAbzXw4BwVAivjBobUgOZ82osTqopiCoi2(P0ZC0aBKv9BrNIH1uQ5tMW2N(TXBt7ZiqVND7nE0rE8EzbFT0KJhvr(O9D(iLyRph3AtRph)8KVNTW8eFFPTRVxM(x8(Wqhgx0uLkPwroGyvtf97YZVfRKur5a9xQQHXmobml9hIRvQi8RAAfRl5m0PKOPLSUty3stoTHSUeBrBq)duF6LLlQYcCcN4wM(l8PKQZIXknTtiHlFP63J3xJsAsteqBmNh8v88B4uEOUYNr3ax3r2UNKoIw1XLRlLyqfrX6sHTALStpP0NkoB4lyv3BCglwCmGKyOY4JSfQ2iJQOfXa8AHadzF(9vCyVwJuxkB8rWai86Ifh9nq4bA7VXTrj4qcCKY7jwq5GADFW0QtipEEK9Jsz7q)Tvp0FFBACg)40qQMtPZy8(Uc85IYYnHPhU(PW8sSfrdN1hd28zoYR108z(knGOxdZRzC6eZxTEZTAtW5vB5iALjGwdlLeWNKlreN7zp(VQwfFsdsKxP(gfQrL9h4mno4mjPMEI4Df)uJDMooV7SrMZIC4ZU(ez2c)aMyQRinjMUSxYL1GmYwyP39LnW3X1szdPbzZjlp(ermcEGJ0DpBEYMOsnjBM3LF)gfjd8vCTuY8h2GK5er6zMckXpV6yhzZtY8P)33SKXTj2BuKmWxX1sjZInizSsg7ewdCuvrRQBI6mQnjzwWJvo3WO0OEnv08h1GO5uj0kyv5O6Lm3eBQj64njAwSodnVHr4m(1uHZ3PbHJQyPlOo5f1cM5KBEcNwS8ZylSNRlKiR1Ug(oVK4pUbjXfIlFQdwoU5aABEsITy1KGipRdwBaHXvXYWA7Nzd3P)fzRb5ztLM6JNpXU3mDaW78s5xVrB7mK7PJQNxPpJtV5PVnZFDtIz9T3yVMFp1V6emF3gemPtg9arp)zsfrwEttWuSstYLy01OH3tu4vuy3GOONqfNWAkXbuIV5PJy970mtiZvrxJzcpYgMj0w4V8go6VVxJAzhT7jmYg68wdpXMxJCAnVWksD531yjBIBQKSVrds2XehpvMchB6mtmZMMK9hoBZswQRBFpc06KfF)g7Xv5t2x6bko8Gz380YAXYxQTWD(EcI6ee)jniisgo2fgzWJn5jtNFttq8DMOjbXSoJvX1wgV9hlYnvuEVzds3qgzdhASJj13uLxEPlEdxlIwuy9JF2MBkZWziNQt0caH1RIgifBsYcsBqYQsfUCfnuoa181lka5dkkgRHa4Ww4UuArqCqfhh(Sy1WgEqQWAsOcLlu9oYA1eh)PGiiJvNsdAPeVy4q8XjLRnbskqKCxu5fBGOEfLl1b57fRVuNCyIVZ7gCczbJaX1ki8h0FGAHSaUQkbDEYsroq)AgMstixHLLD7zPtQ8mof39(r3(cgmv8JLAKSUBZKdndDNoasYnQiWjqmFJ0JnGIFL7KCNFJwhweEwzx9UMT9H9UMTT327WDfyR2y4Zcrc3byedpIgddIUcb9VELJeI7WZY)fDrNj8YeueBR(GI4X9rhnrAuqu)UjW6xbDTSQ29lWIwRyQwYLPvs)z4I(9hOfR3(jHCqxkMyvHZILGUA9)c)5uvs6ojGtI1VW2z3M)A3B72Un3BIDB3(wFH)cAXTB7owhfk5xDJuOVCJfIC6qsvMPHvrVMwR8AXQNxtPCUC1XGaeemYIgBzaPwqEf3MQx2vPUE3uwL62wlwL6SBRTg4MP4ulu3mytltDnTCZNC4tm6rLNsUKXmJY1NtFI0J2rqAmvOWd(g8rVYR5YnqPJ6L)4TE)pvDC6Vn6CMD1k6fod)BrdgNvDH5(DeXZAB5We)KAwmTHrA7XrW9kuc7AIuFoc65850CaxUoLM1yHdJY1N0F9baZNDnV(ypj8ACad(gF7EfdhkupHWO17(xO2MQbU7z(MHcgQdCvALU5BeaxpydKPAHcY4kLcFLHTflCLBmvoL39u52dklx7QBBPvQBYu9TnU6wiU6whZBQlzmbD)Qz3xMEoBfK6uc0ihKThQstV2csJ(oQ7ACjObmjTLTD(9TBBNNjwWOD1fEikEOB8qpID2nCkz)Z7zvp2ZoeJDB7MVporxOROBueZ7EolEECc1eCFM0Zo3jnkfj7A28s8T156JwUZP49Z80qJ0p2Ei7BbCj3bkXOWFBwlPOlWCNol0e9Sm5ojGHC2RnzRIrHGN6YGQU7n6cN7s0VsplMspnodWj4CR)l4SKxgfbDSj9TbVcabBGs9C0kvtvSG)USkmNfBRd4IXqvu1kJhtY4Phj5J6E1JMblGdwTKwHj0SwGEtgGUNI(e2cpJy8sYsvqG9NtqK(BS5zopFQflkxrC4eNiHiFcQtEHV5wPke3cdZ6UL1Y6raBMGF1A2ZAT9Nx3w4BZJ6ZFZyH6ONW4oeChWzrP7eN9Gy9OiQpA0yD3viC3Bmu3rOh7Ic(dVeUBlOwroTSbfFJ7XBusrDwcOuBwPXgtUGLCrS1Q7NULqIT0TQ76BRC4J6QpeHTrsW6V57Alo0jx)mNxTTaMK8k5QRfW3)Y2cy5zIhxZQHwa3BTfUeYVwTL4UqUla1FbElKRv40R6DpaT(1hACBa9mIb7muWUXJHcrp2j9yy6M)zpR)TaWgIL4oJWoUsObZRs0aDXAITPa(re2KXy31MhgBZ1sRMWz36kyPf0h1GRfCwNnJZGUBB3MaX3l5ejYdRnfgdTdMmEIa9oCFb6doXjMBz)g2M7iIjC6holX4PgSVaXgmvQ(cCGHQAPIlGeh0j0JBml1x0eNizM4je7nBILTOUzr)(9MESrsoyFje9wU92YFh3J7py9Fg8FJ1R(sGE2PP6z8o1d9LUPa3N1PEAx459Q3jGHpvUwSUjXN3d2TT1LVB9kO3d6L2x8M7sp1jdVHpCcqG95h7kp2nDOV8l6Uf2qNluEwsRVkwHSr82t6N3qicUguQI8rm07Av2Ia)xCl(4BOsqTZHiNGCsC5qvuUmYi9HdzixgqESntjSgBbiHuU7rsNQ(zA1R652SyzjRckYMSTUVfzrD8qQM4oi(kjcAy2eT3wmDI2BTvkdpR8v1pFIwLfhF(mqIUg5xFzACoODRl7tHV4PeDDSj(Xoj8AC38dyLBIZoIZuJgi0vYXDU4MDd4URyORYo6NR)kTfURLDHrU17NuhQ2CEkgIniVKpVt1WLFdS52CwSXcfXZAKiB)FG6Fz)TEhQcuxWn2aC(CHQmTEhQIVrgGZGeNPggUzv5mtsyB7b12LQW9NkCYLqxHRBEhQYUTHAyT9VqXEMP7EZw64Y6RYwuv9BoAMLulixe(JVK(36jRKR6mFNf(IK5j)gKVc5Fa5vj)dj)JSB7m2TDwQEWxkxRu)(QRv1VWxhO(vV7GOtlRElnL0mMmp9BnttEfYqSQo2zgUFGWBJRR(FRCUQ0p6QUEiv)2Y5TTYBOBnOhZneNTSrZnaRjT5vyCcA9(6gvbS(qFCxz8O(X9Ia08jRwGQOWBuGRV8fvCrUdt4lLxh)Dp1i2qm4L3Go8pCRJ22kWdShCZQBf0s(6nTR(rXmngd)VnDmy)rlpE5ggLf(CGTT8KZ6B9bwD2ig6X31wuA8yLbZcxfuAQBCqPDEDoknYnRO0xTv9mKcCz71Zv0S8UXYVu9xdO3(RbSBy6Z4bmxQySsfxfWC6FMgmZmm5grtlSBlhxXt5TBsXB(etQAwa7pK8kQa6z(vAleclkl38zS6snUJItd7y45TUTjjc3MKTTUuGAy9G4Ajrpwbou1vr344x)QB4Ftd6h5glOVDBkxnqE72uBgMB325V2dDTBtg(BmaFUmq3gJeQ6bVfwnBPfVrg8(1VkWDRfPpuRVSOo43Ae0nRJZcV6m3z)4k4YQBjcBnJz9Hg9UwJFnLhTsC9vLhnZne2y025AWBqmNE)UnuDRp1hBfyiHFSjJdqpxByOin(nXWvSIz5WRduEvWRzFp86vbEv5TwPw0FRMWRxjJAfvtlCpb1YqDIFMf0E10GpD78CvqTJCdpQT9j3Yh9))
```
