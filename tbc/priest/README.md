# Priest — All Specs HUD (v17)

One pack for Discipline, Holy and Shadow on TBC Anniversary (2.4.3 client,
WeakAuras internalVersion 45). Copy the whole string at the bottom of this file
(or the contents of `all-specs.txt`) → `/wa` → Import → paste. 41 auras: a
top-level group holding six draggable sub-groups. Since **v14** your health,
mana and threat live in **The Sill** — an instrument strip directly under your
character, **164 × 36** since v17, where 1.6 pixels are exactly one percent and
every mark this pack draws still lands on a whole pixel. Spec-specific pieces load
through `spellknown` / `not_spellknown` gates, so the HUD reshapes itself on
respec with no user action, and mutually exclusive pieces share screen slots.
Since v4 there is also a **PvP layer** that only exists inside an arena or a
battleground — see below. Every trigger matches by exact spell ID — all ranks,
never by name — so it works identically on zhCN and every other client. There is
no custom Lua anywhere in the pack.

**The `/wa` editor preview lies.** Selecting a group force-shows every aura with
placeholder data: load gates ignored, identical fake durations, empty `%` on
threat, simulated clone slots, mutually exclusive auras (Shadow Word: Pain and
Weakened Soul share a slot, Vampiric Touch and Renew share another) visible at
once, and no real animation or condition behaviour. Judge this HUD in combat,
not in the preview.

## v17 — long and thin, not big

**The rail was too short, and the fix is not to scale the strip.** v14's 100px rail is
lossless and tiny. Rogue tried the obvious answer twice — 300px and then 200px rails on a
uniformly scaled plate — and the player rejected both, because a uniform scale preserves
the original 2.8:1 plate and simply makes the same stubby block bigger: it reads as a **UI
panel**, not as a readout.

**A vitals bar wants to be long and thin.** The fill's *travel* is the signal; its
thickness carries nothing. So v17 keeps the rails long and leaves the height near where it
was:

| | v14–v16 | **v17** |
|---|---|---|
| rails | 100 × 11 | **160 × 13** |
| threat | 100 × 4 | **160 × 5** |
| plate | 102 × 31 | **164 × 36** |
| reserved alarm rim | — | **±4** |
| number | 11pt at `x +32` | **12pt at `x +51`** |
| threat number (hidden) | 10pt | **9pt** |
| area | 3,162 px² | **5,904 px²** |

60% more gauge travel per rail for 5px of extra height. Rogue's uniformly scaled version
cost 15,096 px² to get there.

**1.6 pixels per percent, and every mark still lands whole.** Every value this pack marks
is a multiple of five and 1.6 × 5 = 8, so the 40% Desperate Prayer line sits at `x −16`,
the 50% Shadowfiend window at `0`, the 70 threat notch at `+32` and the 25/50/75 ruler at
`−40 / 0 / +40` — nine marks, all integers, each one recovered from the shipped string and
asserted in the build. `railX()` gained 3-decimal rounding to make that exact rather than
nearly-exact: `(40/100 − 0.5) × 160` is `−15.999999999999996` in IEEE754, and v16 really
did ship `x = 19.999999999999996` for its threat notch. The invariant was never the number
100 — it is that `railX()` is the only place a coordinate is derived, which is what keeps
the length a single constant.

**The lane stack is derived, not typed.** `threat 5 | 1 | health 13 | 1 | mana 13` = 33 of
content, centred inside the 36px plate for an even 1.5px margin top and bottom — computed
from *priest's own* plate convention (`PLATE_Y = +3`, unchanged since v14) rather than
copied from another pack's offsets, and the sum, the gaps and the margins are all asserted
against the decoded string.

**Nothing moved, and that is a measurement.** The new profile is 5px taller than v14's 31,
2.5 of them downward, so:

| against | clearance to the rim envelope |
|---|---|
| tracked-buff row (`y −156`) | **7.0px** (11px to the plate itself) |
| Procs column (`x 110, y −116`) | **24.0px** |
| PvP column (`x 150, y −44`) | **41.0px** |
| Alerts column (`x −150, y −44`) | **42.0px** |
| Cooldown row (`y −206`) | **61.0px** |

Two things changed in *how* that is proved. The scan now guards the **rim envelope** —
the plate grown by the 4px the canonical profile reserves for an alarm frame — rather than
the plate. Priest still ships **no alarm region**: building one costs a new uid, and this
pack's three spare uid slots are burned v12 removals that must never be handed to a new
region (v14 explains why). Reserving the space now means the version that can finally
afford the uid will not discover the layout never had room for it.

And there is a second pass: **all-pairs, column against column**. The sill-versus-
everything scan structurally cannot see two flanking stacks overlapping *each other* — the
sill is not a party to that collision — and that blind spot hid a real defect in the rogue
pack, where a 140px aurabar in one column sat on top of a proc icon in another while both
cleared the strip perfectly. Priest's PvP column carries the same shape of hazard: a 120px
Enemy Mana aurabar makes that column 120 wide at every depth its stack reaches. All ten
pairs (four columns plus the buff row as one merged box, dynamic groups projected six deep)
are clear; the tightest is 14px, between the cooldown row and the buff row.

No aura is added, removed, renamed or re-parented, and no `uid()` call is added, removed or
reordered: all 40 child uids are byte-identical, so this imports as an **Update**.

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

## v14 — The Sill

**The ring cluster is gone. Your health, mana and threat are now three 100px rails on a
102 × 31 plate, sitting directly under your character at absolute screen `(0, -110)`,
where one pixel is exactly one percent.** The numbers print *inside* their own rails.
Every breakpoint is a full-height waterline instead of a mark on an arc. Nothing else in
the pack moves, no aura is added or removed, and every uid is untouched.

```
                      v13                                    v14

        (      THREAT   100      )
         (    health   84    )                 +-------------------------------+
          (   mana   62   )                    | ============================  |  threat
           [   you 87%   ]                     | ####|####|###|######    87%   |  health
                 62%                           | ##########|##|#####     62%   |  mana
                                               +-------------------------------+
      10,000 px2, at x = -270                     3,162 px2, dead centre, y = -110
```

| lane | region | size | local y | absolute y span |
|---|---|---|---|---|
| plate | `Priest - Sill Plate` (texture) | 102 × 31 | +3 | −91.5 … −122.5 |
| 1 | `Priest - Threat` (progresstexture) | 100 × 4 | +15.5 | −92.5 … −96.5 |
| 2 | `Priest - Health` (progresstexture) | 100 × 11 | +7 | −97.5 … −108.5 |
| 3 | `Priest - Mana` (progresstexture) | 100 × 11 | −5 | −109.5 … −120.5 |

The group `Priest - Player Sill` (renamed from `Priest - Resources`) carries the
absolute position at its own offset `(0, +30)` under the unchanged top group `(0, -140)`;
every rail carries only its lane offset. So the whole instrument drags as **one object**,
which four leaves each carrying `(-270, 124)` never allowed.

### Why 100 pixels

A 0–100 quantity has exactly 100 distinguishable states. 100px is therefore the exact
length at which the gauge is lossless: every pixel past it re-draws a state your eye
cannot separate, every pixel short of it throws a state away. The v13 rings spent
10,000 px² to carry 712px of arc — 243px of health arc for 100 readable states — plus
1,936 px² of 3D portrait that decided nothing.

It also turns every breakpoint from trigonometry into arithmetic:

> **x(v) = (v / max − 0.5) × 100**, which for a 0–100 resource is simply **x = v − 50**

against the ring era's `r = size/2 × 0.94; x = r·sin(2πf); y = r·cos(2πf)`, which put the
40% health mark on `(23.206, −31.94)`. Priest is mana in every spec and every form, so
`max` is always 100 here and both marks are one subtraction.

### What each rail says

**Threat (top, 4px).** Green fill = your share of the pull threshold, on your current
target. **When the fill reaches the notch you are at 70** — the exact line where the rail
turns orange and where the Fade prompt fires. Red = you have aggro. The rail does not
exist at all when you are on nobody's threat table, which for a healer is most of the
time, and it does not load in an arena.

**Health (middle, 11px).** Fill = health, number at the right end = the exact percent.
The waterline at `x = −10` is 40%: the Desperate Prayer line, where the rail itself turns
red and where the prompt fires. The three faint hairlines at 25 / 50 / 75 turn the rail
from "estimate a fraction" into "count quarters" for 33px of ink.

**Mana (bottom, 11px).** Same recipe in blue. The waterline at `x = 0` is 50%, where the
Shadowfiend prompt fires. (On this rail the 50% waterline and the ruler's own 50% tick
land on the same pixel column — the ruler is deliberately identical on both rails so the
sub-region indexes match, and the brighter mark simply wins.)

Both numbers sit at `text_anchorXOffset = +32` inside their own rail at 11pt. Two digits
at 11pt is ~14px wide (x +25 … +39); three digits ~21px (x +21.5 … +42.5), still well
inside the rail's right edge. Out of combat the whole instrument fades to 50% alpha,
exactly as the rings did.

### What was lost

Two things, and neither is an accident.

**The live 3D portrait is gone.** `Priest - Player Portrait` keeps its uid and its
triggers but is re-typed `model → texture`, renamed `Priest - Sill Plate` and resized
44 × 44 → 102 × 31: it is now the dark bordered ground the whole instrument is drawn on.
That plate is load-bearing rather than decorative — an 11px rail and an 11pt number
survive snow, lava and Shattrath at noon only because something known-dark is behind
them, and four lanes read as *one instrument* only because a single bordered plate
encloses them. But v11 brought the portrait back on purpose ("two concentric arcs around
a live 3D portrait read as *a unit* — you"), and this version reverses that judgement on
density grounds. It is a taste call, and it is the most likely thing to dislike here.

**The threat percentage is switched off.** `Priest - Threat` sub.1 keeps its index, its
size and its colour and simply takes `text_visible = false`, so it is one checkbox away
in `/wa`. The justification: `threatpct` is scaled so 100 = pulling aggro, i.e. an
early-warning *ratio* rather than a quantity you act on, and reading "68" versus "72" is
slower than watching a fill cross a notch. A 4px rail also has nowhere to print it. It is
still information deliberately removed.

Its **offset** did move, and that is a fix rather than a tidy-up. The ring era anchored
that number at `y = +58` — the 100px threat ring's radius plus 8px of clearance, a label
sitting just above the arc it named. Carried unchanged onto a 4px rail whose centre is
absolute `-94.5`, the same `+58` resolves to absolute `(0, -36.5)`: **55px above the
plate's top edge**, on bare terrain. Switched off it is invisible either way, so nothing
in the drawn picture was wrong — but "one checkbox away" is a promise about what happens
when you tick it, and at `+58` ticking it would have handed you the precise failure this
version exists to end. It now sits at `y = 0`, on its own rail and therefore on the
plate. It stays in the **centre** column rather than joining the other two at `x = +32`:
the strip is packed solid, so a re-enabled 10pt number unavoidably overlaps the health
rail below it, and the centre is the one place it cannot land on top of the health or
mana *number*. The build asserts every label's anchor resolves inside the plate — hidden
ones included — so an invisible region can never quietly keep a dead offset again.

### What was *not* built, and why

The design has a sixth region: an **alarm frame** that pulses the strip's outline red at
`threatpct >= 80`. Every other pack in this repo re-purposes its `<Pack> - Threat Flash`
region for it. **This pack has never had one** — decoding v13 for `alphaPulse` returns
only `Priest - Holy Procs` — so building it would have cost a brand-new uid, and the only
spare uid slots this pack has are the three *burned* v12 removals, which must never be
handed to a new region: WeakAuras matches by uid, so any copy where the player never
hand-deleted the v12 orphans would have seen a deleted target ring "Updated" into the
alarm frame. So the priest Sill has three lanes and no alarm frame. The threat rail still
escalates green → orange at 70 → red on aggro, the 70 notch is now visible before the
escalation fires, and the Fade prompt is unchanged.

### One field to check in game

`orientation = "HORIZONTAL"` is the single value in this version that no
committed string in this repo has ever rendered. On an **aurabar** `HORIZONTAL` is
left-anchored and grows right; on a **progresstexture** that same key is WeakAuras'
*"Right to Left"* and the left-to-right value is the `_INVERSE` one. The value is
transcribed from `Private.orientation_with_circle_types`, and `VERTICAL` off that same
table is live in a shipped string here, so the linear fill path itself is proven — but
the direction is not. **30-second check: drop to about half health and confirm the empty
half of the rail is on the RIGHT.** If it is reversed, the fix is a one-token swap to
`"HORIZONTAL"` and nothing else in the design changes.

### After updating

**Leave the Arrangement category CHECKED** on the update dialog (it is checked by
default). This version moves the group, re-orders its children and changes every child's
offsets, and all of that travels in the Arrangement category — an import that preserves
your existing arrangement will leave the rails scattered where the rings used to be. If
you had dragged the pack, you will have to drag it again once.

Nothing to delete. This is a clean Update over v13: `changed=0`, `retained=40`,
`missing=0`, `parentSame=true`, same seed `20260815`, same 41 auras, **zero new `uid()`
calls**. Two auras are *renamed* (`Priest - Resources` → `Priest - Player Sill`,
`Priest - Player Portrait` → `Priest - Sill Plate`); WeakAuras matches by uid, so both are
renamed in place rather than duplicated. (The three v12 target-cluster orphans named
under **v12** are still yours to delete by hand if you never did.)

### What changed in behaviour, honestly

- **Everything you read mid-fight is now in one 102 × 31 box under your feet**, instead
  of a 100px disc parked out at `x = -270`. One fixation instead of a glance across the
  screen.
- **Both numbers are always legible**, because they are printed on the pack's own dark
  plate rather than on the terrain. That was the original complaint and this is the last
  version that has to be about it.
- **The 40% and 50% marks now cut the whole rail**, so "am I past the line" is a
  yes/no read instead of an angle estimate, and the 40% mark sits exactly where the rail
  changes colour.
- **You lost your face and your threat number** (see above). The threat number is one
  checkbox away and comes back *on the plate*, centred on its own rail — overlapping the
  health rail beneath it, because the strip is packed solid — rather than on the terrain;
  the portrait is not coming back in this version.
- **Nothing else changed at all**: every trigger, every load gate, every condition and
  every fill colour on all four regions is byte-identical to v13, and so is the entire
  rest of the pack — buffs, alerts, the cooldown row, procs and the PvP layer. Proven by
  decoding both strings and comparing field by field, not by reading the diff.
- **No other row moved.** The build scans the 102 × 31 footprint against every region in
  the pack with all four dynamic groups projected six children deep and requires zero
  overlaps: the nearest neighbour is the buff row 13.5px below, and nothing at all sits
  above the strip inside its x span.

## v13 — the health number moves into the middle

**Your health percentage is now dead centre in the cluster, drawn over your own
portrait, at 16px.** Mana takes the slot health just vacated. No aura is added, removed
or renamed and every uid is untouched — but the number only *arrives* there because the
portrait was moved to the back of the cluster's draw order, which is the real content of
this version.

| Number | v12 | v13 |
|---|---|---|
| health | 13px at `y = -54`, below everything | **16px at `y = 0` — the middle, on your face** |
| mana | 10px at `y = -70`, below that | **12px at `y = -54`** — the slot health vacated |
| threat | 10px at `y = +58` | unchanged |

```
         v12                              v13

  (   THREAT   100  )             (   THREAT   100  )
   (  health  84 )                 (  health  84 )
    (  mana  62 )                   (  mana  62 )
     [  you  44 ]                    [  you 87% ]   <- 16px, over your portrait
          87%  <- 13px                    62%       <- 12px, under the outer ring
          62%  <- 10px
```

### Why it was unreadable

Decode v12 and the complaint explains itself: two small numbers hanging 54px and 70px
*below* the rings, on nothing. A HUD element is legible because of what is behind it,
and behind those digits was whatever the game happened to be drawing — snow, sand, a
lit floor, a health bar. Meanwhile the one part of the cluster that is *always* backed
by the pack's own art, the middle, showed a face and no information at all.

So the number that gets read at a glance moves onto that art, and grows: 13 → 16px.
Mana slides up into the vacated slot and grows too (10 → 12px), so it is now
immediately under the outer ring instead of adrift under the health number. Threat does
not move — it is the outermost ring's own label, it appears only when threat is real,
and it was never the number anyone struggled to find. Every label keeps its `OUTLINE`
font and its colours: white health, pale blue mana, pale green threat, so they still
need no captions to be told apart.

### Moving the number was half the fix — the other half is draw order

**Changing the offset alone would have looked like nothing happened.** A text
sub-region is drawn by the region that owns it, and the health number is owned by the
health *ring*. WeakAuras assigns frame levels inside a group by walking
`controlledChildren` and adding +4 per child, so the last child draws on top. Through
v12 the cluster's order was:

```
1. Priest - Health     2. Priest - Mana     3. Priest - Player Portrait     4. Priest - Threat
```

— the portrait sitting **above** both rings that would have to put a number in the
middle. The digits would have been emitted, positioned perfectly, and then painted over
by your own face. v13 reorders the group so the portrait is **first**, and the three
rings follow it:

```
1. Priest - Player Portrait     2. Priest - Health     3. Priest - Mana     4. Priest - Threat
```

In this pack the four cluster regions parent **directly to `Priest - Resources`** —
there is no separate cluster group — so that group's own child list is what was
reordered, together with the matching order in the import string's child array. The
build asserts both, and that they agree with each other, before it will write the
string; `wa_lib.verify` rejects a `controlledChildren` list that disagrees with the
children it can see, so a half-applied reorder fails the build instead of shipping.

### Drawing a ring over your face does not hide your face

That reorder is only safe because `Ring_20px.tga` is an **annulus**. A ring's art
occupies its own stroke and nothing else, so the four regions never overlap — measured
in pixels of radius from the shared centre, straight out of the shipped string:

| Region | Radius band |
|---|---|
| `Priest - Player Portrait` | 0.00 … 22.00 (a solid disc — your face) |
| `Priest - Mana` | 26.16 … 31.00 |
| `Priest - Health` | 35.44 … 42.00 |
| `Priest - Threat` | 42.19 … 50.00 |

There is a clear 4px gap between the face and the innermost stroke, and the rings never
touch each other. The only thing a ring can now paint onto the portrait is its
**subtext** — which is the entire point of the change. The build recomputes these bands
from the shipped widths and refuses to write a string in which any two of them overlap.

### After updating

**Nothing to delete, nothing to do.** This is a clean Update over v12: `changed=0`,
`stable=40`, `retained=40`, `missing=0`, `parentSame=true`, same seed, same 41 auras.
Decoding v12 and v13 and comparing field by field gives exactly **nine** differences —
the two health label fields plus its size, the two mana label fields plus its size, and
the three `controlledChildren` positions the portrait's move shifts. Nothing else in
the pack differs by a single byte.

If after importing your portrait still covers the number, re-import with WeakAuras'
**Arrangement** checkbox ticked (it is ticked by default): the fix is carried partly by
the group's child order, so an import that preserves your existing arrangement also
preserves the old stacking.

### What changed in behaviour, honestly

- **You can read your health.** It is bigger, it is where your eye already goes, and it
  has your own portrait behind it instead of the terrain.
- **Mana moved up 16px and grew 2pt.** It is still outside the rings, still blue, still
  the second number you read.
- **Your face is now behind the rings.** Because they are annuli it looks identical,
  except that the health number is on it.
- **Nothing else changed at all**: same triggers, same load gates, same 40% Desperate
  Prayer danger tier and its pip, same 50% Shadowfiend pip, same threat escalation and
  its zero-value guard, same out-of-combat fade, same buffs, alerts, cooldown row,
  procs and PvP layer, same position and size for every region on screen.

## v12 — the target cluster is gone, and threat comes home

**Your target's ring cluster is deleted. Threat — the one thing it showed that nothing
else does — becomes the outermost ring of *your* cluster.** Three auras removed, one
aura resized and moved, nothing else touched. 44 → 41.

```
        v11                                   v12
  ( health  84 )   (  THREAT  84 )      (   THREAT   100  )
   ( mana  62 )     ( health 62 )        (  health  84 )
    [ you  44 ]      [ them 44 ]          (  mana  62 )
                                           [  you  44 ]

  (-270, 40)        (+270, 110)              (-270, 40)
```

### Why the target cluster had to go

Your target's health is already on the Blizzard **target frame** and on its
**nameplate**, both within a glance of where this pack drew it a third time. For the
entire game the cluster was a prettier duplicate of the default UI, and a HUD earns
its space by showing what nothing else shows. Deleted, with nothing put in its place:

| Removed | What it was |
|---|---|
| `Priest - Target Health` | the target's 62px inner health ring |
| `Priest - Target Track` | the dark 84px annulus the threat arc swept over |
| `Priest - Target Portrait` | the 44px live portrait of your target |

There was never a target *power* ring in this pack to remove — the arena Mana Burn
scoreboard (`Priest - Enemy Mana`, v5) covers that case where it decides a press.

### Threat is now your own outermost ring

Threat is the exception, and it is the whole reason this is a move rather than a pure
deletion: **no default UI element shows it**, and a dps who cannot see aggro coming
dies. So it moves to the outermost ring of your own cluster at **100px**, concentric
with health (84), mana (62) and your face (44), all four on the one centre at absolute
`(-270, 40)`. That is also the more honest reading — it is *your* threat. The v7
argument that it "belongs at the target" only ever held while there was a target
cluster to hang it on.

**Its size and position are the only fields that changed.** Decoding v11 and v12 and
comparing `Priest - Threat` field by field gives exactly five differences: `width`
84 → 100, `height` 84 → 100, `xOffset` +270 → −270, `yOffset` 194 → 124, and the
threat percentage's own offset 54 → 58 (the old offset would have sat *inside* the
bigger ring's stroke, which runs from radius 42.2 to 50). Everything else is
byte-identical:

- the **Threat Situation** trigger with `threatUnit = "target"` — the arg was renamed
  to plain `unit` only at internalVersion 51, and Modernize migrates `< 51` data by
  copying `threatUnit → unit`, so IV-45 data must keep emitting the old name;
- the escalation conditions on **`foregroundColor`** — green, orange at 70%, red on
  aggro (`barColor` is aurabar-only and a *silent* no-op on a `progresstexture`);
- the **not-arena load gate** (there is no threat table in an arena), which still
  loads in the open world, in dungeons, in every raid size and in battlegrounds;
- the mandatory **`threatvalue <= 0 → alpha 0`** guard, without which the ring reads as
  full aggro at zero threat — a `progresstexture` draws a *full* region at `total == 0`.

Because the ring is gated out of arena and self-hides whenever you are not on a hostile
threat table, **the common solo case is still two rings and a face**; the third arc
appears only when threat is real. There is no threat flash halo in this pack to
resize — the only `alphaPulse` animation priest ships is on `Priest - Holy Procs`,
which is not a cluster region.

### It still clears the Alerts column, six prompts deep

The cluster's widest ring grew from 84 to 100, so it now spans `x = -320…-220` instead
of `-312…-228`. The Alerts column is a **dynamic group** at `x = -150` carrying 40–44px
icons, spanning `-172…-128`, and it grows **upward**: depth changes its height, never
its width. Projected six children deep it occupies `y = -44…250` — vertically right
through the cluster's band, which is exactly why the horizontal gap is the thing that
matters. **48px of clearance**, and the build asserts it (with the stack projected six
deep, not at rest) before it will write the string.

### After updating

**You must delete three auras by hand.** WeakAuras never deletes an aura that an import
does not mention, so importing v12 over v11 updates the 41 auras it carries and leaves
the three removed ones sitting on your screen at `(+270, 110)`. In this pack the
cluster regions parent **directly to `Priest - Resources`** — there is no target group
to delete in one click — so remove these three individually in `/wa`:

- **`Priest - Target Health`**
- **`Priest - Target Track`**
- **`Priest - Target Portrait`**

Everything else is a clean Update. Continuity against v11: `changed=0`, `stable=40`,
`retained=40`, `parentSame=true`, and `missing=3` — exactly the three ids above, no
others. Every surviving aura keeps a **byte-identical uid**, including the top-level
group, and their relative order in the seeded stream is unchanged. The three freed
`uid()` slots are **burned in place** in `generate.lua` (`W.uid()` called and the
result discarded, at the exact positions those regions held since v7) rather than
filled: filler regions are how a HUD accumulates junk, and burning the slots also means
no future version can ever hand a deleted region's uid to a new aura and "Update" a
face over a ring. `Priest - Player Portrait` sits *between* two of those slots, which
is why they had to be burned rather than simply dropped.

### What changed in behaviour, honestly

- **You lose a second copy of your target's health.** The target frame and the
  nameplate still have it, and they always did.
- **You lose your target's portrait**, which was decoration — it never changed a press.
- **Threat is bigger and it is on you.** Same colours, same thresholds, same guard, and
  now it is the ring your eye already lands on when you check your own health.
- **The right-hand side of the screen at `(+270, 110)` is now empty.** The PvP column
  at `x = +150` is unaffected.
- **Everything else reads exactly as it did in v11**: same 40% Desperate Prayer danger
  tier and its pip, same 50% Shadowfiend pip, same zero-total guards, same
  out-of-combat fade to 50% alpha, same buffs, alerts, cooldown row, procs and PvP
  layer.

## v11 — rings and a live face, again

**The globes are gone. Your health and your mana are two concentric rings drawn
around a live 3D portrait of you, and your target has the matching pair on the other
side of the screen.** Same 44 auras, same UIDs, same triggers and gates — a different
shape, and the shape is the one that was approved before the globes: two rings and a
face, per unit.

```
      ( health  84 )                          (  THREAT  84 )
       ( mana  62 )                            ( health 62 )
        [ you  44 ]                             [ them 44 ]
          78%                                      41%
          64%                                    (threat % above)

     x = -270, y = 40                        x = +270, y = 110
```

### Two rings and a face, on both sides

| Slot | Diameter | Player cluster | Target cluster |
|---|---|---|---|
| outer | **84** | health | **threat** |
| inner | **62** | mana | health |
| centre | **44** | your face | their face |

Both clusters present the *same* outer diameter, the *same* inner diameter and the
*same* face, which is what makes them read as a matched pair rather than two
unrelated gauges. **There is deliberately no target power ring.** A third ring is
exactly what made the v7/v8 version look busy and uneven, and the case it covered —
"how much mana does that healer have left" — is already served in the place it
decides a press, the arena Mana Burn scoreboard (`Priest - Enemy Mana`, v5).

The clusters sit at absolute screen `(-270, 40)` and `(+270, 110)`, identical in all
seven class packs. `±270` is not a taste call: the Alerts column is a dynamic group at
`x = -150` carrying 40–44px icons (spanning `-172…-128`) and the PvP column mirrors it
on the right, and **both grow vertically**, so at `±190` the prompt stack climbs into
the cluster from the second simultaneous prompt onward. `±270` is the tightest
symmetric position that is clear at any stack depth. The build script derives both
local offsets from the absolute numbers and then **refuses to write the string**
unless the decoded parent chain sums back to them.

### The face is back, so the numbers moved back out

A `model` region cannot carry a text sub-region at all — WeakAuras' `SubText`
`supports()` gate lists texture, progresstexture, icon, aurabar and text, and not
model. That is why the globes could put their percentages *inside* the glass and the
rings cannot: with a portrait in the middle, every number rides on its own ring and
sits just outside the cluster. Health is 13px at `y = -54`, just under the outer
ring; power is 10px at `-70`, under it; threat is 10px at `+54`, above the ring. Each
number appears and disappears with the ring that carries it — no target, no target
number; no threat state, no threat percentage. (**v13 corrects the second half of that
reasoning**: the ownership constraint is real, but "owned by a ring" never meant
"drawn outside the cluster" — a subtext is offset from its owner's centre and can land
anywhere. Health is now 16px in the middle, over the face. See v13 above.)

The portrait is a **live unit model**, not an image and not a class icon, which is
what lets the target side render any mob, NPC or player without ever knowing what it
is. Both `model_fileId` *and* `model_path` carry the unit string on purpose: current
WeakAuras reads `model_fileId`, WA 3.5.0 read `model_path`, and the migration that
bridges them is gated on `IsClassicEra()` — which is **not** `IsTBC()`, so on this
pack's 2.5.x client that migration never runs and emitting only `model_path` would be
a silent no-op: a blank square where your face should be.

### One field turns a vessel back into a ring

A globe and a ring are the same region type. `orientation` decides which one you get —
`"VERTICAL"` fills a shape bottom-to-top by waterline, `"CLOCKWISE"` sweeps an arc —
and it also decides which of the neighbouring fields are live. Under the globes
`startAngle`/`endAngle` were dead and `compress`/`slanted`/`slantMode` mattered; on
the ring it is exactly the other way round. `crop_x`/`crop_y` stay at **0.41**, which
is not "a bit of crop" but the *identity* value on the circular path: it cancels the
√2 expansion the radial fill applies so rotated quadrants never run off the texture.
Setting it to 0 would blow every ring up by 1.41× and clip it.

Threat becomes a ring again instead of a rim colour, so its region type goes back to
`progresstexture` — and with it, its two danger escalations go back to the
`foregroundColor` property (they were `color` on the v9/v10 texture rim, and
`barColor` back in the bar era). `Conditions.lua` **skips a change whose property the
region does not have, with no error and no warning**, so the wrong name there would
look perfectly correct in the editor and do nothing in the game.

The `threatvalue <= 0 → alpha 0` guard matters *more* on a ring than it did on a rim:
`threattotal = threatvalue × 100 / threatpct`, so total is 0 for the whole moment
after a Fade — and a `progresstexture` draws **full** at total 0. Without the guard,
zero threat would read as full aggro. It is last in the list, so it wins over both
colour rules.

Behind the threat ring sits `Priest - Target Track`, a dark annulus in the same
circle, carrying the target's Health trigger. The threat ring only exists while you
are on a hostile threat table — for a healer, most of the time you are not — and
without the track the target cluster would drop to one ring and a face while yours
still showed two. It is the outer ring's track, not a third element.

### The breakpoint marks go back to being points on a circle

On a vessel a threshold was a horizontal waterline; on a ring it is a point on a
circumference again, so the trigonometry comes back — derived from **its own ring's
radius**, never a shared one, or a mark ends up orbiting a circle its ring no longer
draws:

```
r = size/2 × 0.94    x = r × sin(2π·f)    y = r × cos(2π·f)
```

Angle 0 is 12 o'clock and increases clockwise, matching the fill direction, so a mark
sits exactly where the arc ends at that fraction. The 40% health mark (the Desperate
Prayer line) lands at `(23.206, −31.940)` on the 84px ring — radius 39.48, **144.000°**
— and the 50% mana mark (the Shadowfiend window) at `(0, −29.140)` on the 62px ring —
radius 29.14, **180.000°**. Decoding the shipped string and recovering radius and
angle back out of those offsets reproduces both to under 0.0003px and 0.0003°. Each
pip is a square of its own ring's band width (`size × 20/256`), so it fills the stroke
instead of poking out of it.

### After updating

**Nothing to delete, and nothing to re-check.** All 43 child UIDs and the group UID
are exactly v10's, in exactly the same order: no aura added, removed or reordered, and
no `uid()` call moved. Three auras change *name* and keep their uid, which is what
recycling means here — the two portraits return to the two slots they held in v7/v8,
and the v9/v10 brass target rim becomes the target track:

| uid slot (since v7) | v9 / v10 | v11 |
|---|---|---|
| `Priest - Player Portrait` | `Priest - Life Rim` | **`Priest - Player Portrait`** |
| `Priest - Target Portrait` | `Priest - Power Rim` | **`Priest - Target Portrait`** |
| `Priest - Target Mana` | `Priest - Target Rim` | **`Priest - Target Track`** |

Continuity against v10: `changed=0`, `missing=0`, `retained=43`, `stable=40` (the
three renamed auras match by uid rather than by id), `parentSame=true`. Decoding v10
and v11 and comparing every aura field by field gives **zero differences across the 36
auras outside the cluster**, and the only field that differs on the *Resources* group
is the three renamed entries in its child list — same length, same order, same slots.

### What changed in behaviour, honestly

- **Your face and your target's face are back on screen**, which is the whole reason
  the percentages are outside the rings again rather than 18px inside the glass.
- **The specular highlight is gone.** It was a glass effect for a filled vessel and
  does nothing on an arc. It was the *last* sub-region on every globe, so removing it
  retargets no `sub.N` condition anywhere in the pack.
- **The target cluster moved to the right and up**, from `(0, 110)` to `(+270, 110)`.
  That retires the last centre-screen occupant: the middle of the HUD now carries
  nothing but the buff row, the cooldown strip and the prompts.
- **A ring is still not a bar for exact numbers.** It is a shape you read at a glance
  — that is the trade the whole cluster makes — and the percentage under each ring is
  there for when you need the number.
- **Everything else reads exactly as it did in v10**: same 40% Desperate Prayer danger
  tier, same threat escalation at 70% and on aggro, same zero-total guards, same
  out-of-combat fade to 50% alpha (rings *and* portrait), same buffs, alerts, cooldown
  row, procs and PvP layer.

## v10 — the globes flank you, and the glass catches light

**Two changes, both about where your eye goes: the vessels move up beside your
character instead of sitting in a band under the HUD, and every one of them gains a
specular highlight so it reads as curved glass rather than a flat coloured disc.**

```
        ( target )
          44px
        x=0, y=110

 ( LIFE )                    ( POWER )
  72px red                   72px blue
 x=-190, y=40               x=+190, y=40
```

### They moved beside you

v9 parked all three globes on one band at screen `y = -262`, directly below the
cooldown row. That reads as a second bar bolted under the HUD — a separate widget you
have to look *down* at, away from your character and away from the prompts. They now
**flank the character**: life on your left at `(-270, 40)`, power on your right at
`(+270, 40)`, and your target's globe above and between them at `(0, 110)`.

These are absolute screen coordinates and they are **identical in all seven class
packs**, scanned against every element in every pack rather than eyeballed here. The
`x` is not a taste call: `±170` runs into the Alerts column (`x = -150`) and the PvP
column (`x = +150`), `±210` runs into the PvP-layer elements at `(200, -44)`, so
`±270` is the tightest arrangement that clears both. Sizes did not change (72px life
and power, 44px target, each rim its globe + 4).

Because the target globe rises to its own height, the build script now derives **two**
local offsets from two absolute numbers instead of one — the vessels no longer share
a band, so they can no longer share a `y`.

**This retires the v9 buff-row overlap.** The target globe used to sit at screen
centre `y = -262` and cross the Vampiric Touch / Renew and Vampiric Embrace icons at
`y = -156`. At `y = 110` it is clear of the buff row entirely.

### The glass catches light

Every vessel gains exactly one new sub-region: a soft white disc at 28% opacity,
0.46 × 0.34 of the globe, offset up and to the left (`-0.17`, `+0.21` of the globe).

That off-centre bright spot is the whole difference between a filled shape and liquid
in a container. A flat disc of colour reads as a sticker no matter how good the fill
is; a curved surface catching a light source is what your eye has been trained on
since the first Diablo health orb.

**It is drawn in `ADD` blend mode, and that is mechanical rather than decorative.**
Sub-regions draw in the order they are listed and the percentage has lived *inside*
the glass since v9, so this overlay is painted over the number. A `BLEND` overlay at
28% white would wash grey across the text; `ADD` can only brighten, so the number
stays readable. That constraint is also why this is a highlight and not the more
obvious dark edge vignette — a vignette has to darken, so it has to be `BLEND`, so it
would have had to be *inserted before* the text instead of appended after it.

The highlight is **appended last** on every globe (life `[3]`, power `[3]`, target
`[2]`), never inserted. Conditions address sub-regions positionally as `sub.N`, so
inserting ahead of a referenced index silently retargets it. Decoding the shipped
string and re-checking all 21 `sub.N` references in the pack confirms every one still
points at the same kind of sub-region it did in v9.

### After updating

**Nothing to delete, and nothing to re-check.** All 43 child UIDs and the group UID
are exactly v9's, in exactly the same order: no aura added, removed, renamed or
reordered, and no `uid()` call moved. Decoding v9 and v10 and comparing every aura
field by field gives **seven changed auras and 36 byte-identical ones** — the seven
are the three globes and the four rims, and the only fields that differ on them are
`xOffset`, `yOffset` and (on the three globes) one appended sub-region. Every
trigger, load gate, condition, colour, spell id and region type in the pack is
untouched.

### What changed in behaviour, honestly

- **Two prompt columns can now reach the globes.** The Alerts column is bottom-
  anchored at `(-150, -44)` and grows upward in 40–44px icons, so its icons span
  `x = -172…-128`; the life globe's rim spans `x = -228…-152`. They overlap by about
  20px horizontally, and vertically from the *second* stacked prompt upward (the
  first sits below `y = 0`). The same is true of the PvP column against the power
  globe on the right. In practice that is a lower corner of the glass behind an icon
  during a multi-prompt moment, and the icons draw over it — but it is a real
  overlap, and the fix belongs in a layout pass across all seven packs rather than a
  priest-only nudge.
- **The highlight is on top of the number.** `ADD` guarantees it can only make the
  text brighter, never dimmer, but at full health the top-left of the percentage sits
  under the brightest part of the glass.
- **Everything else reads exactly as it did in v9** — same waterlines, same
  breakpoint marks, same threat rim, same out-of-combat fade.

## v9 — Diablo globes

**The rings are gone. Your health and your mana are two glass globes that fill with
liquid, and the numbers are inside them.**

```
   ( LIFE )                    ( target )                    ( POWER )
   72px red                    44px red                    72px blue
   x = -150                      x = 0                       x = +150
                     all three at screen y = -262
```

A ring encodes a value by how far an arc has swept round. A globe encodes it by
**where the waterline sits** — the shape never changes, the level rises and falls.
It is the same WeakAuras region as the v7/v8 rings with one field different
(`orientation` goes from `CLOCKWISE` to `VERTICAL`, which WeakAuras spells
"Bottom to Top"), and it is a fundamentally easier read at a glance: you are
judging a height, not an angle.

### What you see

| Vessel | Where | Reads |
|---|---|---|
| **Life** | left, 72px | Your health, D2 red, **brighter red below 40%** — the Desperate Prayer line, unchanged since v2. A thin white line across the glass marks that 40% so you can see it coming. |
| **Power** | right, 72px | Your mana, D2 blue, with a white line across the middle at **50%** — where the Shadowfiend prompt fires. Every priest spec and every form runs on mana, so this globe is always blue. |
| **Target** | centre, 44px | Your target's health, same red, half the size so it reads as secondary. It vanishes completely when you have no target — the Health trigger simply produces no state. |

The empty part of each globe is a near-black disc rather than nothing, which is what
sells the container read: coloured liquid rising into a vessel, not a shape appearing
out of the void. A brass rim is drawn over every globe at a higher frame strata, so
the fill looks like it is *inside* the glass.

**The percentages moved inside the glass** — 18px in the two main globes, 13px in the
target — which is the whole dividend of the next change.

### The portraits are gone

Diablo has no portrait, and dropping yours and your target's is what freed the centre
of each globe for its number. This is not a style preference: a `model` region
**cannot carry a text sub-region at all**, which is why v7 and v8 had to park every
percentage outside its ring, down where it competed with the world. No portrait, no
constraint, and the number lands where your eye already is.

The trade is real: **no live face** for you or your target any more.

Nothing was deleted, though. Both portrait auras were **recycled** — their UIDs now
carry the life and power rims — so the update leaves no orphan aura behind in your
WeakAuras. Same for the target's mana ring, which became the target globe's brass rim.

### Where threat went

**Threat is now the target globe's rim colour.** Green while you are safe, **orange at
70%** of the tank's threat, **red the instant you have aggro**, with your threat
percentage in small text just above the globe. Same thresholds, same colours, same
arena gate (there is no threat table in an arena) and the same zero-threat guard as
v7 — it hides rather than showing a calm green ring when your threat is genuinely
zero, the state you are in for a moment after every Fade.

This costs **no extra element and no extra screen space**: a fourth vessel would have
cost both, and threat has no natural vessel of its own. When you are on nobody's
threat table — which for a healer is most of the time — a brass rim shows through
underneath instead, so the target globe is never rimless.

### Breakpoint marks got simpler

On a ring, "40% health" was a point on a circumference and needed trigonometry. In a
vessel it is a horizontal line at a fixed height:

```lua
yOffset = (threshold/max - 0.5) * 116
```

So the 40% health mark sits at `y = -11.6` and the 50% mana mark at `y = 0`, dead
centre. Both were re-derived from that formula, not carried across, and the line's
width is the chord of the globe at that height (113.656 and 116) so it never pokes
out of the glass. Decoding the shipped string returns exactly those numbers.

### After updating

**Nothing to delete.** All 43 child UIDs and the group UID are exactly v8's — no aura
was added, removed or reordered, and no `uid()` call moved. Three auras are renamed
in place (`Priest - Target Mana` → `Priest - Target Rim`, `Priest - Player Portrait` →
`Priest - Life Rim`, `Priest - Target Portrait` → `Priest - Power Rim`) and WeakAuras
matches them by UID, so they update rather than duplicating.

### What changed in behaviour, honestly

- **The target's mana ring is gone.** Three vessels is the whole canonical set and a
  target power globe is not one of them. In arena the Mana Burn scoreboard —
  `Priest - Enemy Mana`, one class-coloured bar per opponent — is untouched and still
  covers the case that actually decides a press.
- **The target globe overlaps the two middle icons of the buff row.** It sits at
  screen centre by the shared spec (`x = 0, y = -262`); the Vampiric Touch / Renew
  slot at `x = -22` and the Vampiric Embrace slot at `x = +22` sit at `y = -156` and
  are 40px wide, so they cross it. The icons draw *over* the glass (both are frame
  strata 1, and the buff group is ordered after the resources group) and the brass rim
  draws over the icons. Nothing outside the globes was allowed to move in this pass,
  so this is a layout decision to make across all seven packs at once, not one to
  patch here.
- **No live faces** — see above.
- **The player's globes still fade to 50% alpha out of combat**, exactly as the rings
  and the bars before them did, and so do their rims.
- **A globe is still not a bar for exact numbers**, which is why the percentages are
  now 18px and *inside* the glass rather than 14px underneath it.
- **Nothing else in the pack changed at all.** Decoding v8 and v9 and comparing every
  other aura field by field gives **zero differences** across the 35 auras outside the
  globe cluster: no buff timer, no prompt, no cooldown icon, no proc row, no PvP
  element, no trigger and no load gate.

## v8 — one orb size, in every pack

**The orbs are now a single shared geometry across all seven class packs.** v7
gave each pack its own diameters, and inside a pack the two clusters did not even
agree with each other: the priest's player orb was a 96px health ring, while the
target orb next to it topped out at a 128px threat ring, with a 28px face in each.
Seven packs × two clusters read as fourteen differently-scaled gauges. There is
now one canonical set, identical here and in rogue, paladin, druid, warlock,
hunter and mage:

| Slot | Diameter | Player cluster | Target cluster |
|---|---|---|---|
| outer | **104** | health | threat |
| mid | **78** | mana | health |
| inner | **54** | *(unused)* | mana |
| portrait | **46** | your face | their face |

Both sides therefore present the **same outer diameter and the same face size**;
the target simply nests one more ring inside. Clusters sit at `x = ±260`.

**The rings are drawn with `Ring_20px.tga` instead of `Ring_10px.tga.`** The number
is the stroke weight in the source art's own 256×256 space, so the old texture
painted a ~3.8px arc at a 96px ring and thinner still on the inner ones — at these
diameters it read as a wire rather than as a gauge. The new art gives ~8.1px of
band on the outer ring.

The percentages are one shared set too: health at 14px just under the outer ring,
power at 11px below it, threat at 11px above. The target column now uses the same
offsets as the player column instead of the deeper ones it had, so the two stacks
of numbers line up.

**Both breakpoint pips were re-derived, not just left in place.** A pip's position
comes from its ring's radius, so resizing a ring without recomputing them would
leave the marks floating in empty space. The radius now resolves to the *stroke
centre* of the actual art — `size × (1 − 20/256) ÷ 2` — replacing v7's flat
`size/2 − 5` inset, which was tuned for the thin texture. The 40% health mark moved
from `(25.275, −34.788)` to `(28.177, −38.782)` and the 50% mana mark from
`(0, −27)` to `(0, −35.953)`; decoding the shipped string puts both exactly on
their own ring's circumference (radius 47.9375 and 35.953, error < 0.001) at
exactly 144° and 180°, i.e. still at 40% and 50% of the sweep.

**Nothing else changed at all.** No aura was added, removed or reordered, and no
trigger, load gate, condition, colour, spell ID or region type was touched — the
danger escalations and the threat zero-guard are exactly as v7 shipped them. All
44 UIDs are byte-identical, so this imports as a clean **Update** with nothing to
delete. The only fields that differ in the string are widths, heights, x/y
offsets, the two texture paths, the font sizes and the two pip coordinates.

## v7 — the middle of the screen, given back

The three bars that sat stacked under your character — health, mana, threat, 172
pixels wide each — are gone as bars. The same three auras are now **rings around
two small live portraits**, one per unit:

```
        ( player )                                    ( target )
   health ring, mana ring,                    threat ring, health ring,
     your face in the middle                  mana ring, their face
        x = -250                                      x = +250
                        <-- the middle is now empty -->
```

Unit state belongs *at* the unit, and the centre of the screen is the most
expensive real estate on a HUD. What is left in the middle is only what you look
at to decide the next press: the buff row, the cooldown strip, the prompt
columns. Nothing outside the Resources group moved by a pixel.

**Reading the orbs.** Each ring fills clockwise from twelve o'clock.

| Ring | Where | Colour |
|---|---|---|
| **health** (outer) | both orbs | green, **red below 40%** — the Desperate Prayer line, unchanged from v2 |
| **mana** (inner) | both orbs | blue. On the target orb it only exists if mana is that unit's *primary* bar, so a warrior or a rogue target shows a portrait and a health ring and nothing else |
| **threat** (outermost) | target orb only | green → **orange at 70%** → **red on aggro**, unchanged from v1, and still absent in an arena |

The percentages are still there, underneath each orb (health large, mana small);
your threat percentage sits above the target orb. The portraits are real 3D unit
models with Blizzard portrait framing, so the target side works for any mob, NPC
or player without the pack knowing anything about it — and it re-renders the
instant you switch targets.

**The target orb disappears completely when you have no target.** That is not a
condition or a load gate: the Health trigger produces no state for a unit that
does not exist, so all three target auras simply stop existing.

**New: breakpoint pips.** The bars never had tick marks. The player orb's rings
do — one small mark on the health ring at 40% (where it turns red and the
Desperate Prayer prompt fires) and one on the mana ring at 50% (where the
Shadowfiend prompt fires). Now you can see how far you are from each line before
you cross it, instead of only being told once you have. The target orb has no
pips: nothing in the priest kit keys off a target's percentage on TBC (Shadow
Word: Death is not an execute).

### After updating

**Nothing to delete.** All 40 v6 UIDs are preserved and the three bar auras
change region type *in place*, so this imports as a clean **Update** with no
orphans: WeakAuras leaves auras from a previous version alone if it cannot match
them, and here it matches every one of them. If your import dialog offers
"Import as new" instead of "Update" — which happens if you renamed the group or
you are coming from the pre-v2 draft string — take the new import and then delete
the old **Priest TBC - All Specs** group, bars included, by hand.

The four new auras (target health, target mana, and the two portraits) are built
at the very bottom of the build script and re-parented afterwards, which is what
keeps every existing UID in its place in the seeded stream.

### What changed in behaviour, honestly

- **The threat ring hides at zero threat instead of sitting empty.** It has to.
  The two region types disagree about an empty total in opposite directions: an
  aurabar with a total of 0 draws *empty*, a ring draws *full*. Threat's total is
  `threatvalue × 100 / threatpct`, which is exactly 0 right after a Fade and
  before your first cast lands — so an unguarded ring would slam to a complete
  circle, meaning "you are at the pull threshold", at the precise moment you have
  no threat at all. The ring is hidden in that state instead. The health rings
  carry the same guard for a target whose max health has not streamed in yet.
- **Both orbs sit 250px out from the centre line**, well outside the 86px the
  bars reached. That is eye travel you did not have before, and it is the price
  of the empty middle. The distance is not arbitrary either: it is what clears the
  Alerts column on the left and the Procs row on the right without moving either
  of them.
- **The player orb still fades to 50% alpha out of combat**, exactly as the
  health and mana bars did, and so does the player portrait.
- **A ring is not a bar for exact numbers.** Reading 63% versus 58% off an arc is
  harder than off a bar. The percentages under each orb are the answer to that,
  and they are bigger now than the 12px they were on the bars.
- **Two 3D models are two 3D models.** Portraits cost a little more than a
  texture. On a 2.5.x client the cost of two portrait-zoomed unit models is not
  measurable next to the raid frames you already run, but it is not zero.
- **Nothing else in the pack changed at all** — no buff timer, no prompt, no
  cooldown icon, no proc row, no PvP element, and no load gate.

## v6 — the cooldown row now shows what you *cannot* press

The row used to be inverted: nine icons on screen at all times, greyed out when
they were down. That is busiest exactly when you have the fewest options — and
you already know your own spellbook. What you cannot know is what is
**unavailable, and for how long**.

So the six situational cooldowns now appear **only while they are on cooldown**,
carrying the sweep and the countdown, and vanish the moment they are back. The
row closes the gap, so:

> **An empty row means everything is up. Two icons means exactly two things are
> down, and both are counting back.**

The greyed-out look went with it. Under the new behaviour every icon you can see
is on cooldown by definition, so desaturating all of them would just make them
harder to tell apart; they now show in full colour with the timer.

**Three buttons deliberately did *not* change** — the ones you press the instant
they come up. Hiding those would trade a "press this now" signal for a "you
cannot press this" one, which is the wrong direction for the buttons you press
most, so they stay on screen, greyed while down, and light up the moment they
are ready:

| Always on screen | Glow | Why it is not hidden |
|---|---|---|
| **Mind Blast** | violet | the Shadow rotation cancels a Mind Flay channel for it; it is up every 5.5–8s |
| **Shadow Word: Death** | violet | same — pressed on cooldown, with the glow still switching **off** below 50% health, because the backlash is what kills you |
| **Prayer of Mending** (new in v6) | gold | 10-second cooldown, cast on cooldown on the tank: the most mana-efficient heal a priest owns and the healer's most frequent *scheduled* press. It had no glow before; hiding it while it was available would have been the worst possible call |

The six that are now hidden while ready: **Shadowfiend** (a mana cooldown fired
at a mana window — and the Alerts column already shouts when mana drops below
50% with the fiend up), **Inner Focus** and **Power Infusion** (3-minute windows
you spend on a specific cast, not on sight), **Pain Suppression** (an emergency),
**Lightwell** (placed before a damage phase), and **Fear Ward** (pre-warded, and
in arena the Alerts column already tells you when it is missing *and* ready).

One more piece of quiet: **the ready glows are now switched off out of combat.**
Standing in Shattrath every cooldown is up, so the glow was permanent decoration
— and after this change the out-of-combat row contains nothing *but* those three
icons. They still fade to 50% alpha out of combat, as the whole always-on layer
does; they simply stop pulsing until the fight starts.

Nothing else moved: no aura was added, removed or re-ordered, every load gate is
untouched, and all 39 UIDs are unchanged, so this imports as a clean **Update**.

## v5 — the three things v4 left on the table

v4 shipped with three deliberate gaps, each one because the WeakAuras behaviour
behind it was unproven and a HUD element that silently does nothing is worse than
no element. All three were then verified against the WeakAuras source, and this is
what came back. One new aura (39 → 40); no existing aura was removed or reordered,
so this imports as an **Update**.

### CC ON ME now tells you *which* break works

The prompt used to glow red for everything. Red is the right colour for a stun and
the wrong colour for a root, because under CC you read colour, not text — and the
categories want completely different answers:

| Colour | What has you | What you do |
|---|---|---|
| **red** | stun (and stun-mechanic effects like Hammer of Justice, Cheap Shot, Intercept) | the trinket is the only answer. Nothing else in the priest kit touches a stun |
| **purple** | fear, and fear-mechanic effects (Howl of Terror, Intimidating Shout, Blind's DR partner) | trinket now, or eat this one and put Fear Ward up before the next — a warlock's second fear is the one that kills you |
| **blue** | root (Frost Nova, Entangling Roots, Improved Hamstring) | **not** the trinket. A priest has no root break, so this is "you are not helpless": line-of-sight the caster, keep casting, and save the break for a stun |
| **green** | confuse / polymorph / Sap | ride it out and *hold your damage* — a Shadow Word: Pain tick or a Prayer of Mending bounce breaks it early and hands them a re-cast |
| **amber** | silence, pacify-silence, or a school lockout from a Kick / Counterspell / Shield Bash | your defensive school is gone. Every priest panic button is Holy or Shadow, so this is the one case where you trinket **earlier** than the timer says |

Anything the client reports without a category (charm, disarm, possess) keeps the
red default — "assume trinket food" is the safe fallback.

These are the same five colours the mage pack uses, on purpose: if you play both,
you learn the language once.

### The threat bar and the Fade prompt no longer load in an arena

There is no threat table in an arena, so both were dead furniture on your screen
for the whole match. They now carry an instance-type gate that lists every place
threat *does* exist — open world, 5-mans, all raid sizes, and battlegrounds (which
have real NPCs) — and simply omits arena.

This is the change v4 refused to make, because the gate has to be written as "load
in these six places" rather than "not in an arena", and nobody had proved what
WeakAuras reports out in the open world. It reports the literal string `"none"`
(there is an explicit fallthrough for it), so listing `none` keeps both elements
loaded everywhere they were before. **Nothing changes in PvE** — same bar, same
prompt, same behaviour, in every dungeon, raid, battleground and quest zone.

### New: Enemy Mana — the Mana Burn scoreboard (arena)

One bar per opponent whose *primary* resource is mana, in the PvP column, class
coloured, with the percentage on the right. It turns **red under 20%**, which is
roughly two heals left — the point where mana, not damage, is the fastest way to
win the game.

Mana Burn is the priest's second win condition and it was the only one this HUD
could not show you. Now the burn has a scoreboard: you can see the healer's pool
actually moving, decide whether burning beats casting Mind Blast, and see the exact
moment the rest of your team should stop peeling and go.

Rogues and warriors never take up a row — the read-out only shows opponents whose
main bar is mana, so what is on screen is exactly the people worth burning. Arena
only: `arena1..arena5` do not exist in a battleground, and a BG copy would be
permanently blank rows.

## v4 — PvP layer

v4 adds nine elements that exist **only inside an arena or a battleground**, plus
one container group to hold them (ten new auras, 29 → 39). Every one of the nine
carries its *own* instance-type load gate — `use_size = false` with
`size.multi = { arena, pvp }`, or `{ arena }` alone for the three that read
`arena1..arena5` unit ids, which do not exist in a battleground — because a
group's load is not a child gate, and per-child gates are what let the dynamic
groups collapse their gaps. No v3 aura was edited, added to or re-ordered.

**Nothing changes in PvE.** In a raid, a dungeon, or out in the world this is
byte-for-byte the v3 HUD: same 29 auras, same positions, same gates. The threat
bar, the Fade prompt and the rest of the PvE layer were deliberately left alone —
they kept loading in arena too, because the "hide PvE furniture in a PvP
instance" gate would have had to touch PvE auras, and its behaviour outside
instances was unproven at the time. *(v5 settled it and closed that gap: the
threat bar and the Fade prompt no longer load in an arena, and still load
everywhere else, PvE included.)*

**This is NOT diminishing-returns tracking.** Nothing in this pack knows that
your second fear lands at half duration, because WeakAuras has no DR primitive
at all — no prototype, no type table, no bundled library, on any client. The
countdowns below are real remaining durations of effects that are actually on a
unit right now. An approximate DR tracker (say, an 18-second timer per spell)
would be worse than none, because it models the reset window rather than the
category state and is wrong the moment two spells share a category — and it
would get trusted anyway.

### What appears in arena and battlegrounds

Four new prompts join the **Alerts** column (same language as the PvE prompts:
they slide in from below, glow, and fly up shrinking when handled).

| Prompt | Appears when | What you do differently |
|---|---|---|
| **CC ON ME** (colour-coded since v5) | any loss-of-control effect is on you — stun, fear, polymorph, root, sap, or a school lockout | the icon *is* the effect, the glow colour is the *category* (see v5 above), and the number is the time left: this is the "ride it or trinket it" call, next to the trinket read-out that says whether you even can. It is the only element that can show a Kick/Counterspell school lockout, because a lockout is not an aura and no aura trigger can see one. Not combat-gated — the opener lands before you are in combat |
| **FEAR WARD MISSING** (blue) | Fear Ward is not on you **and** off cooldown | re-ward now. Fear Ward is eaten by the first fear, so this is a live state in every game, not a pre-pull constant; while it is showing, the next fear costs you the trinket |
| **MASS DISPEL NOW** (gold) | your target gains Divine Shield, Ice Block or Blessing of Protection **and** Mass Dispel is up | the priest is the only class that can answer an immunity, so this is a press, not a stop sign. The number counts the bubble down: dispel it, or your team burns the kill window into nothing |
| **SILENCE NOW** (violet, Shadow) | your target is casting **and** Silence is genuinely castable | press Silence. The second condition is the point: "Spell Usable" folds cooldown, mana and range into one boolean, so the prompt never nags while Silence is down. There is deliberately no spell filter — WeakAuras disables the "interruptible" option on TBC clients entirely, so no HUD on this client can tell you whether a cast can be kicked |

Five state read-outs live in the new **Priest - PvP** column (`150, 96`), which
mirrors the Alerts column on the other side of the character (v5 adds a sixth,
the enemy mana bars). State read-outs do not glow — in this pack a glow means
"press something".

| Read-out | Shows | What you do differently |
|---|---|---|
| **Trinket DOWN** | your PvP trinket while it is on cooldown, greyed, with the swipe timer | absence means ready, so the normal case is an empty column. This is the number the CC prompt is read against: no trinket means eat the stun and save the next one. Tracked by exact item id — Insignia (5 min) and Medallion (2 min) of both factions plus the 2.4 epic Medallion — never by equipment slot, because a PvE on-use trinket in the other slot would report "trinket down" while your medallion is ready |
| **Will of the Forsaken DOWN** | the racial while it is on cooldown (Forsaken only) | on 2.4.3 it does not share a cooldown with the medallion, so undead carry two breaks: this is what tells you the first one is affordable |
| **Enemy Trinket** (arena) | a 2-minute clock per opponent, started when you *see* them trinket | their break is gone — this is when the real CC chain goes in. It is an inference, not a read: no API on 2.5.x can query another player's cooldowns, so nothing starts if an opponent trinkets while you cannot see the cast, and the clock assumes the 2-minute medallion everyone wears at 70 |
| **UA on Ally** (arena) | Unstable Affliction on a team-mate, one icon per person, red, with the timer | **do not press Dispel Magic on that person.** Dispel Magic is the highest-frequency button a TBC priest owns and this is the one state that must break the habit: dispelling UA is ~1050 damage and a 5-second silence on you, which is the warlock's entire plan. Arena-only on purpose — in a 40-man battleground it would be a permanent wall of icons for people you will never dispel |
| **My CC Out** (arena) | your own Psychic Scream, Mind Control and Silence on each opponent, with the remaining time | fear and Mind Control mean **hold damage** — one tick breaks them, and the number tells you how long the peel lasts. Silence on their healer means **go**, and counts exactly how much kill window is left |

### Per spec, in arena

Discipline and Holy get the four all-spec prompts (CC ON ME, Fear Ward, Mass
Dispel from level 70) and all five read-outs. Shadow gets the same set plus
SILENCE NOW, gated on Silence's own talent id, so it appears for exactly the
builds that took it. Undead see one extra icon; everyone else never loads it.

### Deliberately not built

Each of these was planned and cut, because a HUD element that fakes a mechanic
is worse than an empty screen slot.

- **Diminishing returns** — see above. No WeakAuras primitive exists.
- **Enemy cooldowns** (their Blink, their bubble, their Preparation) — 2.5.x has
  no API for another player's cooldowns. The enemy trinket clock is the one
  sanctioned exception, and only because it is started by an event you saw.
- **Enemy spec detection** — readable on retail only; every Classic-flavour
  prototype for it is deleted. Enemy *class* is readable, enemy *spec* is not.
- **"Only show casts I can interrupt"** — disabled by WeakAuras itself on TBC.
- ~~**Enemy healer mana** (the Mana Burn scoreboard)~~ — **built in v5.** The
  Power trigger's arena-unit support was the unverified part; it is verified now
  (the unit value is deleted on Classic Era only, not on TBC).
- ~~**Hiding the threat bar in arena**~~ — **done in v5**, once the open-world
  behaviour of the instance-size gate was proven rather than assumed.

### Two things to smoke-test

The **CC ON ME** prompt is built on WeakAuras' Crowd Controlled trigger, which
reads the client's loss-of-control API. That trigger did not exist on Classic
clients until WeakAuras 5.2.0 and is registered on TBC by current builds, but
whether the 2.5.x client actually populates that API cannot be proven from
addon source. Duel a friend, get sapped and kicked, and confirm the prompt
fires. If it never appears, that is why — and the fallback (a hand-listed set of
CC spell ids) would lose school lockouts entirely, so it is not shipped
alongside; two prompts for one event is worse than one that needs a check.

The **Enemy Mana** bars (v5) are the other one, for a smaller reason. WeakAuras
provably registers the power events for `arena1..arena5` on a TBC client and
re-reads each opponent on `ARENA_OPPONENT_UPDATE`, so the bars will appear and
they will be right — what addon source cannot prove is how *continuously* a 2.5.x
server pushes power updates for an opponent you are not targeting. Run one
skirmish and watch a healer's bar move while you burn them before you let the
exact number decide a kill. Unlike the CC prompt, this one cannot fail silently:
either the bars are there or they are not.

## v3 — per-spec load audit

v3 re-judged every one of the 23 elements against a stricter question than "can
this spec cast it?": **does this spec press it as part of playing well?** The
audit was run per spec with `lua5.1 tools/spec-preview.lua priest`, which decodes
the shipped string and prints each spec's real loaded set.

**What changed: the Holy proc row is no longer ungated.** Surge of Light sits at
tier 6 of the Holy tree (25 points in) and Holy Concentration at tier 7 (30 points
in), so no Shadowform build — the raid standard is 23/0/38 — can ever proc either
one. The icon now carries `not_spellknown = 15473` (Shadowform), the same inverse
gate Weakened Soul, Renew and Prayer of Mending already use, so Shadow no longer
loads a healer-only proc watcher. That leaves exactly **four** ungated elements:
the health bar, the mana bar, the threat bar and Inner Fire. *(v7 rebuilt those
three bars as the seven auras of the two unit orbs, so today the ungated set is
eight elements covering the same three things — see **Spec gating** below.)*

*The inverse gates need WeakAuras 5.4.0 or newer.* On an older client the
`not_spellknown` field is ignored and those four elements simply load for
everyone, exactly as before — it degrades, it does not break.

**What each spec no longer sees**

| Spec | No longer loads | Why |
|---|---|---|
| Shadow | Holy Procs | Surge of Light (25 Holy points) and Clearcasting from Holy Concentration (30) are unreachable from a 31-point Shadowform build; the icon could never fire |
| Shadow | *(already gone in v2)* Weakened Soul, Renew, Prayer of Mending | healing presses, and all three are Holy-school spells a priest cannot even cast while in Shadowform |
| Holy / Discipline | *(nothing new)* | the audit found no Shadow-only element reaching a healer — Shadow Word: Pain, Vampiric Touch, Vampiric Embrace, the Shadowform alarm, Mind Blast and Shadow Word: Death are all gated on Shadowform or on their own talent id |

**Deliberately kept, with reasons.** Each of these failed a first-pass reading and
survived a second one; a false cut is worse than a marginal keep.

- **Threat bar + Fade prompt for Holy and Discipline.** Both need a hostile target,
  which reads at first like "DPS only". It is not: a healer using mouseover or
  click-casting keeps the boss targeted, healing puts you on its threat table, and
  Fade is the only threat dump a priest owns. Kept for every spec, and there is no
  single spell id that means "healer" for an inverse gate anyway (Circle of Healing
  identifies Holy, Pain Suppression identifies Discipline, and `not_spellknown`
  takes one id).
- **Fear Ward for Shadow.** Fear Ward is a Holy-school spell, so a priest in
  Shadowform has to drop form to cast it — which is why this was the closest call in
  the pack. Kept because the press still happens: it goes on the tank **before** the
  pull, out of combat, where leaving form costs nothing, and Icy Veins lists it in
  the Shadow priest spell summary. The icon answers the only question that press
  needs — "is it back yet?" — and a Shadow priest is the raid's Fear Ward provider
  whenever no priest is healing.
- **Desperate Prayer for Shadow.** Also Holy-school and also a form drop, but it is
  a genuine emergency button under pressure (instant, and cancelling Shadowform is
  itself instant), especially in arena. Emergency survival stays.
- **Shadowfiend (prompt + cooldown) for all three specs.** Verified rather than
  assumed: it is a mana cooldown, not a damage one, and Holy, Discipline and Shadow
  guides all list it. Correctly ungated beyond its own level-66 spell id.
- **Inner Focus for Shadow.** The gate is Inner Focus' own talent id, so it loads
  only for builds that took it — and the standard 23/0/38 Shadow build does, using
  it on Mind Blast.
- **Health bar, mana bar and Inner Fire.** Every spec plans around mana, every spec
  keeps Inner Fire up (Shadow applies it before entering form), and the health bar
  is half of the Desperate Prayer danger state.

## v2 — rotation fixes

An adversarial rotation review judged v1 against one standard: every element must
change which button gets pressed next. These are the changes it forced.

- **Weakened Soul now watches the heal target, not you.** v1 tracked `6788` on
  `unit = "player"` and gated it behind `33206` (Pain Suppression, the 41-point
  Discipline talent). Power Word: Shield is the #1 Disc/Holy press and the only
  thing that stops it is Weakened Soul *on the person you are about to shield*, so
  v1 answered a question the rotation never asks and hid the answer from Holy
  entirely. It is now `unit = "target"`, still not own-only (any priest's shield
  blocks yours), and loads for every priest **without** Shadowform — the exact
  complement of Shadow Word: Pain's gate, so the shared `x = -66` slot is still
  provably occupied by exactly one aura.
- **New: Renew on your target.** All 12 TBC ranks (139 → 25222), own-only, in the
  slot Vampiric Touch uses for Shadow. Icy Veins ranks Renew third in the Holy
  priority list ("keep this HoT up on the tank and anyone taking consistent
  damage"); v1 had no friendly-target buff tracking of any kind.
- **Mind Blast and Shadow Word: Death glow when they come up.** These are the two
  presses the Shadow rotation cancels a Mind Flay channel for, and in v1 they were
  indistinguishable from Lightwell in the same 32px strip. Both now light a violet
  pixel glow the moment the cooldown ends. Shadow Word: Death's glow additionally
  switches **off** below 50% health: the backlash is the one thing in this pack
  that can kill you, so the HUD stops asking for it when it is dangerous.
- **Shadow Word: Pain's re-cast glow moved from 3s to 1s.** SW:P is instant and
  ticks every 3s, so a glow at 3s remaining was instructing a clipped tick — a DPS
  loss. Vampiric Touch (1.5s cast) and Vampiric Embrace (60s, no tick to clip)
  keep the 3s lead; Renew gets 2s.
- **Vampiric Embrace got the expiry glow its row-mates already had** (v1 shipped it
  with an empty conditions table — the only buff timer that expired silently).
- **Shadowfiend prompt moved from 30% to 50% mana.** The fiend returns roughly a
  quarter of your maximum mana over 15s; firing it at 30% wastes part of the return
  and five minutes of cooldown.
- **Prayer of Mending no longer loads for Shadow** (`not_spellknown = 15473`), and
  the **Fade prompt is combat-gated** like the other three alerts.
- **The health bar turns red below 40%**, the same number the Desperate Prayer
  prompt fires at, so bar and prompt read as one danger state.
- **The always-on icon layer fades to 50% alpha out of combat**, matching the
  health and mana bars — the buff row and the whole cooldown strip stayed at full
  opacity in v1.

Not changed, deliberately: the health bar, mana bar, Fear Ward and Lightwell all
stay (each one answers a real question), and no element was deleted, so this
string imports as an **Update** over v1 with every UID intact.

**Known limit — threat while healing.** The threat ring (a bar until v7) and the
Fade prompt measure your threat on *your current target*. Holy and Discipline target friendly units, so
both stay hidden while you heal. WeakAuras' "At Least One Enemy" threat option
cannot fix this: the prototype's final hidden test is
`WeakAuras.UnitExistsFixed(unit, false)` and `UnitExists("none")` is false by
definition, so a `none` threat trigger never activates. A healer-facing aggro
warning needs a different mechanism (a boss-unit or nameplate scan) and is left for
a future version rather than shipped dead. Also note that WeakAuras deletes the
whole Threat Situation trigger on Classic-family clients that do not expose
`UnitDetailedThreatSituation` — if the threat ring never appears on your client,
that is why.

## Groups

**Player Sill** (`0, +30` — since v14, ONE **instrument strip**, on the geometry shared
by all seven packs; called `Priest - Resources` up to v13). The group's own offset plus
the top group's `(0, -140)` is why every child offset is now a small local number: the
strip lands at absolute screen `(0, -110)`, which the build script derives from the
absolute number rather than hard-codes — and then asserts against the decoded parent
chain before it will write the string. All four regions carry `x = 0` and `CENTER`
anchors, which is what makes them one stacked instrument rather than four nearby bars,
and the build asserts that too, along with the fact that no lane overlaps another and
every lane sits inside the plate:

| Lane | Size | Local y | Shows |
|---|---|---|---|
| plate | **164 × 36** | +3 | the dark bordered ground everything is read against |
| 1 | **160 × 5** | +17 | **your threat** on your target, with a notch at 70 |
| 2 | **160 × 13** | +7 | your health, with a waterline at 40% and a 25/50/75 ruler |
| 3 | **160 × 13** | −7 | your mana, with a waterline at 50% and the same ruler |

The lane offsets are **derived** from the plate convention and the lane heights rather than
typed in: `5 | 1 | 13 | 1 | 13` = 33 of content, centred in the 36px plate, 1.5px of margin
above and below. Since v17 **1.6 pixels are one percent**, so a breakpoint is
`x = (v/100 − 0.5) × 160` — every value this pack marks is a multiple of five and
1.6 × 5 = 8, so all nine of them land on a whole pixel — and the number printed at the
right end of a rail and the length of its fill are the same scale. The plate is the
**first** child of the group and therefore the furthest back, with the three rails drawn
over it; the build asserts that order in both `controlledChildren` and the transmit's own
child array, because the two are read independently in game.

**Health** is green, with the percentage **12pt inside the rail at `x = +51`** and a
4 × 13 white waterline at 40% — the Desperate Prayer line, where the rail itself turns
red. **Mana** is blue, with its percentage in the same place and a waterline at 50% where
the Shadowfiend prompt fires. Rails and plate fade to 50% alpha out of combat (a second
Unit Characteristics trigger feeds the `inCombat` condition). Priest is mana in every
spec and every form, so the power rail never needs the recolouring condition a druid's
does.

The **threat rail** is the read-out you act on: green, orange at 70% of the tank's
threat, red on aggro, with a 2 × 5 notch drawn permanently at the 70 line (`x = +32`) so
you can see the escalation coming. It is the thinnest lane on purpose — an early-warning
ratio is something you see, not something you read — and the extra 60px of travel v17
gave it is exactly what makes "near the notch" and "on the notch" different pictures. It carries a bare threat trigger, so it exists only while you are
on a hostile threat table and vanishes by itself the moment you are not — which means the
everyday solo picture is a plate and two rails, and the top rail appears only when threat
is real. It hides rather than sitting calmly green when your threat is genuinely zero
(see **v7** for why that guard exists, and **v11** for why a `progresstexture` makes it
mandatory). Since v5 it does not load inside an **arena** at all (there is no threat
table there); it still loads in the open world, in dungeons, in every raid size and in
battlegrounds. Its own `%threatpct%%` label is still present at sub.1 but is **switched
off** since v14 — re-tick "Display Text" on it in `/wa` and the number comes back at 9pt
(v17; it was 10pt) centred on the threat rail, on the plate, overlapping the health rail
below it because the strip is packed solid. (v14 also re-aimed it: it carried the ring's
`y = +58` offset, which on a 4px rail pointed 55px off the top of the instrument onto
open terrain. The build asserts that its anchor still resolves inside the plate, visible
or not, so a hidden label can never quietly keep a dead offset again.)

**Buffs** (`0, -16` — static row of 40×40 icon timers with time remaining
underneath). Shadow Word: Pain (all 10 ranks) and Vampiric Touch (all 3 ranks)
show only your own DoT on the current target; SW:P glows at 1 second or less
(instant cast, ticks every 3s — refreshing earlier throws a tick away) and
Vampiric Touch at 3 seconds, which is its cast time plus a moment to react.
Vampiric Embrace shows your own debuff on the boss for the raid-healing/mana loop
and glows at 3 seconds. For every priest without Shadowform the same row becomes a
healer row: Weakened Soul on your *target* takes the SW:P slot (icon up = you
cannot shield this person; it glows in the last second, meaning "shield again
now"), and your own Renew on your target takes the Vampiric Touch slot, glowing at
2 seconds so the refresh is already in flight when it drops. Inner Fire sits on the
right for every spec, with its remaining charge count large in the centre and the
time left below. An empty slot in this row is the refresh prompt.

**Alerts** (`-150, 96` — dynamic group growing upward, 40×40 glowing prompts).
Each prompt slides in from below and flies up, shrinking and fading, when it is
handled; the stack re-flows automatically. Four prompts, all combat-gated and each
requiring both a state *and* the ability being off cooldown, so none of them ever
nags uselessly: Shadowform MISSING (red, Shadow only — you dropped form),
Shadowfiend (violet, mana below 50% and the fiend ready), Fade (orange, threat on
your target at 70%+ and Fade ready — the only threat dump a priest has; since v5
it does not load in an arena, where there is nothing to fade), and Desperate
Prayer (green, health below 40% and the racial ready). Inside an arena or
battleground the same column also carries the four 44×44 PvP prompts (CC ON ME —
colour-coded by CC category since v5 — Fear Ward missing, Mass Dispel, Silence)
described under **v4** and **v5** above; they do not exist anywhere else.

**PvP** (`150, 96` — dynamic group growing upward, mirroring Alerts on the other
side; 32–36px icon timers plus one 120×14 bar row, arena/battleground only). Six
state read-outs, none of them glowing, each one collapsing out of the stack when
its state ends: your trinket while it is down, Will of the Forsaken while it is
down (Forsaken only), one 2-minute clock per opponent who trinketed, one red icon
per team-mate carrying Unstable Affliction, one icon per opponent sitting in your
own Psychic Scream / Mind Control / Silence, and (v5) one class-coloured mana bar
per opponent who runs on mana, red under 20%. The last four are clone rows, which
is why this group is a dynamic group: clones inside a static group would all stack
on one spot. When nothing is happening the column is empty.

**Cooldowns** (`0, -66` — dynamic group growing horizontally, 32×32 icons).
Blizzard cooldown swipe and numbers are on (no WA `%p` text, so OmniCC users do
not get two numbers), the strip dims to 50% alpha out of combat, mouseover shows
the real tooltip, and the row auto-collapses gaps — both the ones left by icons
your spec never loads and, since v6, the ones left by abilities that are simply
available. Nine cooldowns in fixed order, in two kinds (see **v6** above):

- **Always on screen, greyed while down, glowing when up** — Mind Blast and
  Shadow Word: Death (Shadow gated, violet; SW:D's glow is suppressed below 50%
  health because of the backlash) and Prayer of Mending (Holy/Disc, gold). These
  are pressed the moment they come up, so the glow is the instruction.
- **On screen only while on cooldown, in full colour with the countdown** —
  Shadowfiend, Inner Focus, Power Infusion, Pain Suppression, Lightwell and Fear
  Ward. Each is pressed when a circumstance calls for it, so absence means
  available.

Mind Flay, Smite, Circle of Healing and the rest of the filler are deliberately
absent — they have no cooldown to watch, so an icon for them would not change
which button you press next.

**Procs** (`110, 24` — dynamic group growing right, 32×32 cloned icons). One
gold-glowing icon per *active* Holy proc, so two procs show as two icons side by
side: Surge of Light (your next Smite is instant and free) and Clearcasting from
Holy Concentration (your next Flash Heal / Binding Heal / Greater Heal is free).
Each pops in with an alpha pulse and slides off to the right when it is spent.
Since v3 the icon also carries an inverse load gate (`not_spellknown = 15473`), so
it does not even load in Shadowform: both procs come from talents 25 and 30 points
deep in Holy, which a 31-point Shadow build cannot reach. A 41/20 Discipline build
cannot proc them either (20 Holy points stop at tier 5), but it keeps the icon
loaded — no single spell id separates deep Holy from deep Discipline without
risking a false cut on a Holy build that skipped one of the two talents, and the
trigger keeps it silent regardless.

## Spec gating

Everything is class-gated to PRIEST. On top of that:

| Element | Load gate | In practice |
|---|---|---|
| Shadow Word: Pain timer | knows 15473 Shadowform | Shadow |
| Vampiric Touch timer | knows 34914 Vampiric Touch | Shadow |
| Vampiric Embrace timer | knows 15286 Vampiric Embrace | Shadow |
| Shadowform MISSING alert | knows 15473 Shadowform | Shadow |
| Mind Blast cooldown | knows 15473 Shadowform | Shadow (baseline spell, gated on purpose) |
| Shadow Word: Death cooldown | knows 15473 Shadowform | Shadow (baseline spell, gated on purpose) |
| Weakened Soul (target) timer | does **not** know 15473 Shadowform | Discipline, Holy, and any non-Shadowform build |
| Renew (target) timer | does **not** know 15473 Shadowform | Discipline, Holy, and any non-Shadowform build |
| Holy proc clones | does **not** know 15473 Shadowform | Holy in practice (both procs are 25+ points into the Holy tree) |
| Prayer of Mending cooldown | knows 33076 **and** not 15473 | any healing priest ≥ 68 |
| Pain Suppression cooldown | knows 33206 Pain Suppression | Discipline 41-pt |
| Power Infusion cooldown | knows 10060 Power Infusion | Discipline 31-pt |
| Inner Focus cooldown | knows 14751 Inner Focus | Discipline and Holy builds |
| Lightwell cooldown | knows 724 Lightwell | Holy 40-pt (optional) |
| Shadowfiend cooldown + prompt | knows 34433 Shadowfiend | any priest ≥ 66 |
| Fade prompt | knows 586 Fade, in combat | any priest ≥ 8 |
| Fear Ward cooldown | knows 6346 Fear Ward | any priest ≥ 20 (all-priest spell since patch 2.3.0 — no longer a dwarf racial) |
| Desperate Prayer prompt | knows 13908 Desperate Prayer, in combat | only races that learn it |

The PvP layer is gated on the instance type instead, and on an ability where one
exists:

| Element | Load gate | In practice |
|---|---|---|
| CC ON ME prompt | arena **or** battleground | every priest, no combat gate (the opener lands out of combat) |
| Enemy Mana bars | **arena only** | every priest; reads `arena1..arena5`, one row per mana-primary opponent |
| Fear Ward MISSING prompt | arena/BG **and** knows 6346 Fear Ward | any priest ≥ 20 |
| MASS DISPEL NOW prompt | arena/BG **and** knows 32375 Mass Dispel | any priest at 70 |
| SILENCE NOW prompt | arena/BG **and** knows 15487 Silence | Shadow builds that took Silence |
| Trinket DOWN | arena **or** battleground | every priest |
| Will of the Forsaken DOWN | arena/BG **and** knows 7744 | Forsaken only |
| Enemy Trinket clock | **arena only** | reads `arena1..arena5`, which do not exist in a battleground |
| UA on Ally clones | **arena only** | party-sized by definition; a 40-man BG would be a wall of icons |
| My CC Out clones | **arena only** | reads `arena1..arena5` |

Two PvE elements now carry an instance gate of their own, in the other direction:

| Element | Load gate | In practice |
|---|---|---|
| Threat rail | everywhere **except arena** (open world, party, all raid sizes, battleground) | arena has no threat table, so the rail could only ever be clutter there |
| Fade prompt | same, **and** in combat, **and** knows 586 Fade | its trigger is the threat rail's, so it was already unreachable in an arena — now it does not even load |

`lua5.1 tools/spec-preview.lua priest` lists the un-`spellknown`-gated PvP
elements in its UNGATED section: that tool models spec gates only and does not
know about instance-type gates, so read those as "every spec, but only in arena or
a battleground". The PvE ungated-by-spec set is eight elements since v7 (the seven
cluster auras plus Inner Fire) covering the same three subjects the three bars did —
and one of them, the threat rail, is gated by instance type instead.

Shadowform (15473) costs 31 Shadow points and Vampiric Touch (34914) costs 41, so
neither can coexist with a "not Shadowform" gate: the two shared slots at `x=-66`
and `x=-22` are single-occupancy for every possible 61-point build.

The four `not_spellknown` gates require **WeakAuras 5.4.0 or newer**. Older builds
ignore the field, so those elements load for everyone — the pre-v2 behaviour.

Ungated by spec (loaded for every priest, and the whole of the levelling HUD): the
Sill — the threat, health and mana rails plus the plate they sit on — and Inner Fire.
Each is justified for all three specs — mana is the resource every priest plans around,
Inner Fire is maintained by all three (Shadow applies it before entering form), the
health rail is half of the Desperate Prayer danger state, and the threat rail exists only
while you are on a hostile threat table, which includes a healer who keeps the boss
targeted for mouseover healing. Since v5 the threat rail carries one instance-type
exclusion — it does not load in an arena, where no threat table exists. (v12 removed
the three target-cluster regions that used to share this paragraph; they were the only
ungated elements that showed something the default UI already showed.)

## Regenerating

```bash
cd tools/tbc-weakaura-creator/scripts && ./setup.sh   # once per machine
lua5.1 tbc/priest/generate.lua                        # rewrites all-specs.txt
```

The build is fully deterministic: fixed seed `20260815`, no clock or randomness
beyond it, so re-running produces a byte-identical `all-specs.txt`
(sha256 `f4397bcc6e0f563f55ab12b465eb1e707705e14337b34f43566bb7cc584f9dd0`,
9617 characters, 41 auras). When editing, never remove or reorder existing
`W.uid()` call sites — append new auras after all existing ones — so re-imports
offer "Update" instead of duplicating the pack. (v2 does exactly that: Renew is
built at the end of the script and re-parented into the Buffs row, so all 27
v1 auras keep their UIDs. v3 adds no auras at all — it only sets load fields — so
all 29 UIDs are untouched and it imports as a clean Update over v2. v4 builds its
ten PvP auras at the very bottom of the script and re-parents them into the
Alerts column and the new PvP column afterwards, so all 29 v3 UIDs are again
untouched: `changed=0`, `stable=28`, `parentSame=true`. v5 adds exactly one aura,
Enemy Mana, below all of them, and otherwise only edits conditions and load
fields: `changed=0`, `stable=38`, `parentSame=true`. v6 adds no aura at all — it
only changes the cooldown row's triggers and conditions, so every one of the 39
children keeps its uid and its parent: `changed=0`, `stable=39`,
`parentSame=true`. v7 converts the three Resources bars into rings **in place** —
same ids, same `W.uid()` call sites, new region type — and builds the four new orb
auras below every existing one: `changed=0`, `stable=39`, `missing=0`,
`parentSame=true`, so no previous uid disappears and there is nothing left over to
delete after the import. v8 is pure geometry — ring diameters, portrait size,
cluster offsets, the ring texture, the percentage sizes and the two re-derived pip
coordinates — and touches no aura list at all: `changed=0`, `stable=43`,
`missing=0`, `retained=43`, `parentSame=true`. v9 turns the rings into globes and
**recycles** the three auras it no longer needs as rings — the two portraits and the
target mana ring become the three rims — instead of deleting them and appending
replacements, which would have left four orphans in every installed copy:
`changed=0`, `stable=40` (three auras are renamed, so they match by uid rather than
by id), `missing=0`, `retained=43`, `parentSame=true`. v10 moves the globe cluster
and appends one sub-region to each of the three vessels, and touches no aura list at
all: `changed=0`, `stable=43`, `missing=0`, `retained=43`, `parentSame=true`, with
the 43 uids in the same order they have been in since v8. v11 turns the globes back
into two ring clusters and **recycles** the same four slots a third time — the two
portraits return to the uid slots they held in v7/v8 and the brass target rim becomes
the target track — instead of deleting regions and appending replacements, which
would have left three orphans in every installed copy: `changed=0`, `stable=40`
(three auras are renamed, so they match by uid rather than by id), `missing=0`,
`retained=43`, `parentSame=true`. **v12 is the first version that genuinely deletes
regions**, so it is also the first with `missing ≠ 0`: the three target-cluster auras
go and nothing replaces them — `changed=0`, `stable=40`, `retained=40`, `missing=3`,
`parentSame=true`. Their `uid()` slots are *burned* (called and discarded) at the exact
positions they held since v7, because `Priest - Player Portrait` is created between two
of them and would otherwise inherit a deleted region's uid; the three ids are declared
in `generate.lua` on `WA-REMOVED (v12)` lines, which is what licenses the removal in
`tools/verify-packs.lua` — anything else that disappears is still a hard failure. Since
v11 the script also **refuses to write the string** unless the decoded parent chain puts
every cluster region on its canonical absolute screen position at its canonical
diameter, and unless each breakpoint mark's radius and angle — recovered from the
committed offsets, not from the arithmetic that produced them — match its own ring and
its own threshold; since v12 it additionally proves the four rings are **concentric**,
that no removed id survives anywhere in the data, and that the cluster **clears the
Alerts column with the prompt stack projected six children deep**. **v13 reorders the
cluster's children and changes two label offsets and two font sizes — nothing else** —
so it is once again `changed=0`, `stable=40`, `retained=40`, `missing=0`,
`parentSame=true`: re-parenting order is not uid order, a reorder consumes no `W.uid()`
call, and v12's removal licence has expired, which puts the strict "not one uid may
disappear" contract back in force. The v13 build additionally proves, from the decoded
string, that the health label is at `y = 0` in 16px and the mana label at `y = -54` in
12px in **both** the live `text_anchorYOffset` spelling and the dead `anchorYOffset`
one, that every label kept its `OUTLINE`, that the portrait is the **first** child of
`Priest - Resources` with all three rings after it, that the transmit's own child array
agrees with that list, and that no two of the four regions' radius bands overlap.
**v14 replaces the ring cluster with The Sill and consumes no `uid()` call at all**:
`changed=0`, `stable=38`, `retained=40`, `missing=0`, `parentSame=true` — `stable` drops
to 38 only because two auras are *renamed* (`Priest - Resources` → `Priest - Player Sill`
and `Priest - Player Portrait` → `Priest - Sill Plate`), and a rename matches by uid, not
by id. The ring canon the build has asserted since v11 was **rewritten, not deleted**: it
now proves `orientation == "HORIZONTAL"` and `foregroundTexture == Square_White`
on every rail, `width == 100` on every rail (one pixel is one percent), the exact
sub-region count per lane, the plate's explicit dark colour and bordered texture, that
`Priest - Player Sill` resolves through the real parent chain to absolute `(0, -110)`,
that the lanes share one x centre-line and neither overlap each other nor hang off the
plate, that the plate is child 1 in both `controlledChildren` and the transmit's `c`
array, and that every waterline's threshold — recovered back out of its committed
`xOffset` through the inverse of `x = (v/max − 0.5) × 100` — is the threshold it claims
to mark and is full rail height. It also replaces v12's single Alerts-column clearance
check with a **whole-pack rectangle scan**: the 102 × 31 footprint against every region
in the pack, with all four dynamic groups projected six children deep, requiring zero
overlaps.

**v17 keeps that canon and rewrites it to the long-and-thin profile** — `width == 160` on
every rail with an aspect ratio never within 8:1 of square, `164 × 36` plate, the derived
lane stack proved as a sum (`5 | 1 | 13 | 1 | 13` = 33 of content, 1.5px of even margin
inside a 36px plate), every one of the nine marks recovered from its committed `xOffset`
*and* asserted to be a whole pixel, each mark carrying the width its role gets (4px
breakpoint waterline, 2px ruler hairline, 2px threat notch), both numbers 12pt at `x +51`
in both offset spellings and proved to fit their own rail in width and height. The
rectangle scan now guards the **rim envelope** (the plate plus the 4px an alarm frame
would need — priest builds no such region, see v14) instead of the bare plate, names the
tightest clearance it found, asserts every dynamic group's `selfPoint` matches the edge
its growth direction anchors to, and is joined by an **all-pairs column scan** that tests
the four columns and the buff row against *each other* — the collision the
sill-versus-everything scan structurally cannot see. It consumes no `uid()` call:
`changed=0`, `stable=40`, `retained=40`, `missing=0`, `parentSame=true`, no allowance
list.) The
script prints a UID continuity report against the previous `all-specs.txt` before
overwriting it; expect `changed=0`, and on the v11 → v12 step the three deliberate
removals named above. On an update,
WeakAuras' Arrangement checkbox (ticked by default) resets any positions you
dragged in game back to the values in the string — untick it, or report your
coordinates so they can be baked into the build script.

Note for anyone who imported the earlier priest draft string: v1 was a different
pack (it added the Weakened Soul timer, the Shadowfiend and Desperate Prayer
prompts, the Prayer of Mending / Lightwell / Fear Ward cooldowns and the Holy
proc group, and dropped the Shield prompt, Silence, Psychic Scream and the Fade
cooldown icon), and its UIDs do not match that draft. It therefore imports as a
new group — delete the old "Priest TBC - All Specs" group first. v2 is a true
update of v1 and imports over it.

## Import string (v17)

```
!WA:2!T33E4TT15Dhyg3yZCPwk2oj25cJtSRTxSdjfPeLtst5njrBkskqkzlh3iasasalqayaqjr3UlwlntpzTRDQBzFlRBTtTn9(2Qwxw3(2Lw90L11NT13QUMITUU(uTNNUS)zR1DBFDFD3oNdajiLOOLKLCI96FyiWdW5GZLFV)EFpVN3ZXuJ0zHpWHN5bwmpBHX50uuJQiPODsxUCLXL3JhuTZckYgAkss8CrfeL404LpP6DMrtKx3WZX8KvusYtgjwd(lxpTCcA8Sgo)EaEwjdHfR)7bzLzxkVIghVwe7pQ6UIijEXlYQX5jNIIKHOQ2uPlwuN3GkVkl6BAOUx78Nlsuuzeg9zZQYxqpVvbjOv169FI504ljQiNRQkpDjnLkQZz9gzfVi)2NxuUOIwzwd0B4EERhy1GPOOCTiBfdbfT0Q4hR7opQPxuSKBn2cKe6Mw3GvZWD(IIYI6cUJG(JH7Pn0elvIxtp1H0SV95JyG)6Sv0y9Va(QUkVKKiN((60BKkOmLxvITkV20K0tWP7Ej9k55Na1mZwPyrXPMFSOHZMBSS5ctNR(JYOXJEeD2mXtM8Yv05JpfQEL1QeyOLzlZR7Eoo(8Osa341giEYm9nCYzRiBxTCppNO(5RiJAntW7NvssTdwY95SE(GkC8FYBYU7koxjE1oYEHkOEFp9vb1DFAbrd(fSEQvF9oNLvw0QZSByV9TapRoFwd0OvjdHBb2Fezfz(f5qTF8BmgUprtNh1PYPpn(vX1sWFKYSIY9b(qza8dDbbGGO)ExlpLz15LkMrru2iF04PYfN(aICQ7UoMkdPdLahVm6D41KzLgb95qF4NA(IAOohufJ1G11LzLlGgJ7dNeUcKpBu64XtnNHsHjSE)DKzp(RiYnFaLZZfiKpHdpzaA9cSs8UMdnuqtqx61apjKr9dUMd3OeTqnrKuy5CpV1NHuHHqZ8GWoPGB)wG(GqWEq9vUH7YnC3UH75PpeSVNh1oVF4bHdqtgNZBjVGs6bapUNgnspggZWape8WWHCdVj4WWrC3y(G(v39WOxXtubwmyLxtu3qSGUDrajwwEHJc)yWJ8jVj4epf0decbA0znWdt8ctRPyqgUOGiUZlWlwsWirEsI8cq8rMfxDkiXQRZK3a1NiBSx6YvqcSUPjPEO86IYLK4ZNHor8S5GH2lKJjccNxyVWqUJOJecX3Czd(PqFr(tRXQIHDQ7oAYWdMjx6ijdh9uHJflrUeJepFzrnnfnb4o0SF)zZJ(KC4Cqhjz8uXGZQgobE4UiBb(ZfMJlTS(5onp74HXsDNBqEor2ZLZkV6NZcnpgbipweY43XnkXcUHEHD7gEZOrEeQcCb3PBAwjvbwx0tkYzied14QrsK5M9E8abHNC(Kdv8WhwBu(tgpMAhibRcA8Os1P77XCbEXsflhz39vgRdXo6HOliWxy8(G9T9PNGvtKf1WNwuoQs58Sg0tWkvHN6akQh4jEcTccSYL4133HGIek7PvreQ8Agvbe4QaQeCbCZwMDkblyvXo9IZ4J)eqjCwOab4PHoCdpo8eZCI8OHxTXQsz93POqW25z5oFfDdEUbzNABo)quEBWT)qyaT6UDWpy(CmPRmNW86yjmRUEMgFN(uqm0wVdTUeRSb10OX0WyuZZSxeKCju9VeA4spRsfTc8h9EVPTHrPKrP4fH0mercmssaYGbta9HGSGnwdgMK0iORtqJuDyuLXV6eQmtJ49nQwMvMXVbVmZCgtIWUvlIy)qazY9mGFgmmijfA8hEAxqKJoZDR2jg5nMUalNYKNXwL0SK0Wxw4GgeLDQfmo4bv3vdVRJwf1hP(RpMLYNXQNPX44lGyqLgtvdDdM9HAjRcPgBxKWdNlT6DssePEsbt3w40yuzKWOFEzRIvCkEosIxArlINrTRQlqEoEmtSyvKOULKmEyjsQ0PIR(GTPUzLq(uvkNNxd2VgI9d)I2DjwFNADjZrsZskblI0tq81EdIrKHCnR9haPgFx9PjErpdvHLdth7jxUMkUAv7fjPnjsefZqm9PTVzX6Ldrdx6HZLmbQrSRgkbBgx1d2Mggb8r0hrxusrrRPb5MRc4Vf2YH7CXMBVw9RtGgYqcMcZS7fTjOg0MXkSlyub42PMdpqoMQvLQgRhDnsILStyeRYHXwRXyLXeCKmvlfeVfR)Wjtc7Fo7Hbu2u7W(Myoe41ksBjp1tSXOhj8IJT9fSlnhJcrJQHcc7mmm4TUGDDZU1bPewSXgiVG1ad63rQXAdNdLpi2jCiMQpQafpqpeMP3SnZ0jjwG2n(IpxGWLlwN3GuBQxe0SLqjdfDzXhANzC26fxB9536kQiGpv9mnV13LqK2skX8fqSOJvLq37BdZKRUlexvyBotcfQGAh5RtsA31dFKgnkyoIvMe(qkIoj4Es1O2(5SQ6yf(ivWAL4nqA2xcZj68agSA)(v3LLP4iZImQqqCe7awMraJkS8APOmsL7LRrdBpgoTcY(iKvw6UHNcohXSwhCSEzffdHm25GzocVEFIA6gcZBNVcsIQcyTmWPHZOUlNobBjQl7Ks0gv2gm40fukRIlxbS25Bg(uegg)wCl4lD5cRTDSB2TAhoGeN(2NC(lWpy5G5KUqYZgrtugBNhVWSK6iguMprQSjIfFEfKXKYwTO5ginDIZMovUWjTactzde6WTgjF8CcZCc48uW4yDKG02GYi9HVrIbEOEpfga1yVafOruPb6nRfBeKwS2R7YDZAIo7m3n82OG3U6UoiI3RaQAAPn)Ghe(jikzGFk4sW0Wpn8mxcEhuWZI(s)mWmiiZpl8olbVlSORl4NdE3QExbVytfyluibVhk1JCfYLdJk8lb)8WSW7f(fGFruL4xHb()qb)Y3d8cLAbLCZfIvIWZnZUH3Nddk8RIkMFnk49ZaFa4xhMd(GOw1hc(WcWlIgBhBNWhT2Kvdb782OGb3p8XiKrWhxa(eW5wxL22TlnmJbQ4ENB7QU4E13ngFSzukdTIsbNqnU0TdCaIjJQrsqI5GyYS60El2upoIYnaM5RZh369FvUM4ibXwBS4V1vjPi8PfG5BMZd(TRr190npXgyGvBsml79o5vCYoOU6plIxd(9GFFcfg8)Lc(dyG)qb4pQoVe8htbFUxDk4ZtOA2UnvJpIXmHiks8hQgzdSaHBjT0qzRYLxT0KHGVGa8NaVm8NcFr4pRoHb8LAfvXB)M2Q5kUCnQcvLj51wZmfwCUw2WzZzC4vtWLuYnl8)EOWY8nqbO(WTp31K6D4jE02NHvYqTEjmE131MLm51dee7BnqqS1lt)soYQ0zWJJy51zjJOyKdvtIUlITMP(ZyU2jX)gWs8Oof)wtZ3AomltGpuQaff7rmEP85wDb(haOQ7dvyBNx9EC8ykzwgEWtPXtgwrz17Q(JgHTSQOMybp5uQuqOH8u)bXlNxdzkFDNHEmpyR55L558GMTSudoMnHSmVMhKjy8lvpnA0lojClWoWio3WTc3gcCHuzEhWBe212X18oTOiUtcLstoQQMjO3lCF7RtV166XJe4((dY0IU)JbhhE0DUXHuikq0yIt1psfKLIygs0WbE0JaUEY5v73RrcUWboYu9JfyI4gI6cI5gI7gZWoZdnNybfzlFjCV3eUPHKNqpyXckksOrc5StkIWylu7NyhFkSsN09IwT9pU)GH61FWEd4V3E86V3E9hXFpD3dTpVOujx7ICnaT)GDHshFnKgQutllvLb1R970IEnTbctpyFdNCJaXpXtD5X55vdJ9WMbn22vbIQJtjaroXRSyjjLj7tJ)cv4Llu1YQ5i40ewajH1VKTBkeMfNwwlFCIVnjXfU7zE891Mpm5DQppqxKNvB2WwohaNc5lMtqSW4Yid2Dnn5Niz4fZxXWqroT1CbiLvsr0R0b57z5loHz2drX1boO6Aqxfvdw1I16uxLZcjsLko9yrsNlx6bjAvUp4fWALkc7Fwu10YXTlA9NXuSNpV9pR7Npx2RqrT54Zy7W3X4r4d441(f2nuUGbhcIpbspnzwyeN6pUmAqVME7HxH275CEPD84xWwl(DebJurcMFlyNpYnJq2bIM27Pe6EqFJpeWqASrUOIszYuEMUgELPUFl)Rv3DTeXt(jMOo2RHCmyRcgBitQDqCVfIYYsIelMHf3qsD2sKllL7AfPGL6ID06giUe)uiAjYeMYjwgppAFnATidiGDwXX9DC8y8ArleIb6XCnZdbF7gfuHLyG)(vxI8e0DfOxFbix7MCTh4FA1e1G)5nMqg8DBuSc(EwIsWLfGVVa8V4c(x3d8Vrb))SaK)aK8a8Vd))Db)q4)a(p7a(V2Kq2W)9YGZMu3KjQ0mP2gPqnPCXysDZWXnP2UdO0K6nS6artQBzhZKVgaeHrSGFsui4xKPo15t4DKjVWr8Bd)mPCtaFMu3QdS7VXK6226WyMu3ocx11YWvMu3XwfEAF0(c6pu3)im06cd9yV0kWqhdbH41VOqwnbUrpsFTdc9nUbbcvZaPiD3tOq)i4tD4JANyfJYkgRu54snNkwB4QonxhSfr9y4ZYNy4HMk4eJEH2bU(BVgaU8DTdCDrKfOHI0Jp)H83Tx)r851B3ito7nOpYv)itod0LV2zF(vj27Kxnyp9RkSxic27bTWEBQ457ATJNxl(JXbO(oq40U75SJqp(rgkpFO2Ht)MBb409TvPL8l53xx9gPBV9eaFji(s34l9GVecdf93d5Q199INjKVGOR(97JC1FBuWE4)3Oc29AJQmPUR1ijiXiTjhU)eNC4(hP8WbBh46V7AajO)RgsqVrkHMN8bgodSTNtD)lZBjy3a6zWezZMiv)R8HI8YCEYOPuw1OHicQpwo(AP6PEQX4r6AWlukkjsedz)gDu)nIg1t6uEgmU6(CkQ4HP9C6W0XQxhUBNGzlC2SEILahvwEsL(0nubYMiz8urJJtL4ZfSO1NNiAz5LfADv2c83(vRBwMhnL1kLLZIlmxKi6jV1uFPzLeljdH00nyXH3foIEWofXXXuAwHVfpdXzqHDnnAeWUCUnbI7BUJf4QkZwwSajs6GDT9i6kAgG)zlPjAfWb3604BXtX)a0XOLellACR4a0ij(oHLqtOf95Ln6JTGHIwE6WXsmC28ASCIv0FMBdE0DolRwbl3n8m7TgA1j0bdlXRzOpxXkssrf1kGMgEnN)KKc7MNDkDv4FjKmqm3y4hYucPmz1ZfxxoqPzEy4Bt1EEWunpBHa901IOUXcc86zfuMmT8I6K)mOOooyOwt(kRz2RJ6WEHjP((mWpKoJ4u8soCyoRlHVGe2SlZG54q8zeUS1cVZZwZWEl6fc7ZCK47IeLrmRWiFhpvq4GmPgahrH4yzmbACw9n5eQb4FRFoIzD2HvH9FWsYyVp(KZRh2BVNzy9tDy5(xjXLqnOGj1JUQmxO2yE86cZBab1Wbuy6kgOXytQSZRljYXNxXWqP801car)OIMm23ccUz21SKq8J4QkDdnwCCVrCig6BuOIoQCYtEHQ4Aic(ysLZkHPijysnsN(GNMIeECK0z6Sk3o7CkQzjbsgUCNUw5I)6lIUxwhh3S4hP2rTNLRwYOQgXl41Fpgsztkngl(x32uNxzalwX93PM2u1900YPOq4dv068XxOX0pqqVi1UFnm4LeEanTgmmWR0Sd7HVEdoPFMoOr16cJhbhVsQDGZCjEzEnXcwIhml20pN3sAHMNLRkzrbiWMuSL53XZEjy)0KFAhMJ3tuBhC5PwSg45WKqG9iwtXar4POXJJ4aePepZIiyHu2Af38nOVyX6EQd)es4sGR)wTMzT74lmoJ6DIVNhhQTn(6RhjxtQu1fBDwCTUc6AtuS1Kk9kfxr9EltC1KkJ6HxlsP4UilX0rdjfkKVEzhDQYTvm1B7etrIKerglPttQHrYlMuNE1LgnPoJj1O4mEwtQNYrMZK6CnjVzs9wRjOzs90MuJHlltkuZNL8TYJURWgsC5LRjUSOtK1Owark(zq2SIa8Ved8jpqpErah1oDISSAct4GyQF43THWTHixysvYKczxKiQADEtQXXWDtkPp0dJBPLTW4MuYMukOxqnc2egtkTLHonP0rp1yJdcDzV4wwbw1gcd(8Grld(YgrMymjcgIACKGXeQWatWatYatXavzGlsI3YMGMhR1qZYSLelmMesyNhh9oy)Xlkzu1cFgLRVZN4mtfoqgFTfF67gv8j8LpqaV1duceYebwWaLemwuVnfXhmQ7T5yUXH9FnGt3r35AjqvDxl3S6TauRvGErSBDRM4e1mBbX5HAn6uqrQ6yinrOorRqSJalZoyQWblFXszL4AlS0)1nWY1G)bW2fpbbx2G5Uyiq)Q7kkAUfCEIwFZeHrQRLzVVQeyTX43n1jY)GRXjYpQvWPVkeJoZG)qiwqA8wAITb2plqJsHWd4nZKPdNBQ2cA6QoOz0xNcAEbNaT1E)Jr2SpfJKn3WPAkoDx2yPWLDwXWMdZxtQNbkUio)Jny8OdeovIOTTGmPE2MZBe804xrmc3JfVsRYWI4m06p2viNArtNQVHZgFf5jGtuX366iD605wrU6I85A9xY2ldRSRie5R4VLnSmHJMOVr3izvDxzJoq60jhlbEpyrpCMCxHSVUuQ9I1x)KUc0TjvstQbVcEYE11vD3FPwQRA2(4z18CAwnUTiDubS2YdBeDuJAPJcrHCfxVnuRRgzIj10lZoQhUnAQ4NQGIwbrD7zH3JA3zgjJ)4jo75BlLtGx3t5S(mFQ(IP0Da8AO43lDGGb6keT)E62xV4e8hjyWE7LgDxpHUc(PE1XG)et2sm48dYIM4Amr8WYgbfUwupwxiCRv749T21oUwH2OoTvhAVk(yIvRaRmpAMc66CKUvl0Dx(I4TYOxyWbINPTO7G3aIUTx5Kirz1nQbGTMxqtG3xUbe6IHjB0zpdtcCimgebw1YkkXlxO(erRzthgOIrZs74X)j3Wq1RK)qE9owf10xDS6rBRNwelRQkWQZRliw0WMmMnEYPkXYhVhJ2cx7(6g4QxtQJdFryBVq9iwnAm8IMikZ5jIeczQEFnMEJXgBmEwdH6bhBdpM4CQMZN9A5Ou0ZGONjkxQ58zhlSkfQOxFvDSYh2zMOhxScooYvV3MEgROSNSvuj78i8t3tJpnj2zTtIgoBo56gxuFfFEKBUHL8XKQNDE1UEpMuHCzVXTnPob(YJTYv2XK6XfSxuhtQNWz5CmPEZWU2Uj1tcOjE(wUvtQWhGoMjve0DrrOD0TXnP6JSWmMu97SImQD6S(y2EGv3KkXYxngQnLfJjGi7Wfz7pw5EhaZ3Twwv6LPcEoSlLdlnjBv9AQIFG3xlvfpNduSTAIVkxo61VBHfwxwogEngMwRyfC(e4f8X(i3GXIfIUexS4XNqWOWWTzfLnPMdXcjqyHcVPTKYNS(SnMtrUgsBzBTtgqaovdZk5tVSvwEnVYZR(RiqkchvUxjiOCRSc8tv3kW3wR9AwNnq3Dcl(U1dgCZBNrTEWQFxxFJRP4ttQFtBCzpXsj4FyVfgn34Tfx(b3cWLNTz82vfE8ldfpqWg32Dcn8c3YvgWElBca2wWzUK1YWvxOZg8IxcUwaEnPUW1i(Y1C47SPbcxX6M1aiC0ixy0q5osqLHyBli8dTfacxhbZ1gdc0aN1Lc0AoRowHPwVgQ2CLt0DDZk98R2QyTxgRaXQX1Z6wWDlRk0qxi(PJLKVpJJeQTqJp8wQEZRE(PRb6lBj27Zud7177V1EnPbZ4VHL7b12xDfGLgntp(IKMvHRTaSx86tUN6J)VPKTC8FPMNT2nSqauZFvHaxGL9WhjO8qb7B02cb(ixNdbU0lTkl08YNv(nSOGl9sRokykv1EngwtFi5l2wuWh96BuqSJ16vWPUVxUrDWh1Wx1X(y(NWqVxJ(ZFYbA7y)h76CgGvz57mPEp3WkYBVMETCypFIb6EejVkhUCS2oS)XFTDyh7VxA6e9pqoyB7RHtJGbuKQIdzZc61DmQVTk)Igjz8(Y1wxJYSz6AuNZNas7RfEf9BUP4vu5ZFMqr4sLogFFR1yX5fj(bnQKImVoJvN5rP7QlFb9r3vGEcgydez6VoAPhVN14Y5eEJTdBmP(c2t5V6ONM2yuvVN9mTv0BH6RkZYf9iRX2zTwvg8ilETuE65iHYDMks68wRadzXx8HbONZ(VVvgYcRmIFcSTatRezBOSTEZqOIVZQuDo13BDTknKDEZ5RVAghZtonr5X5n8el9PtPEaNZBe8b(mA2)gc8OPIPPJp9rSEhNZKK4Y8LRwRaAGfy4WEuKXhDZvBy9egSkzl3uPXx0QaWNt0TCNZGOlU9nn6ctQEV2rwSGdzXezAbvb3MZ2zP3HQKxpuFtfvFK1cxXN9nSn8j0Z0Ig8LjXDFIFdCFhwPm0V6D3IyUpb6npItWMAP6Ebse4Bxgi(Mi47D8j9lzs912rIpOtjBs9klVimP(6myaT5YY2eVRnw2EUnu2EVV6glB)JRRSbh1pRC1LZXYS1zeYAo8eBAPS)QwSGvtYviYaNsDOi8TLf8VylWaK1ziOU6gvE)VLwpTYD3kwT1DK5Sfo0TwJhbudSDdILuRgO)dFXdNEIJ02bX)Yx7heXX3E)A2hq(7JoGF)963s8Ae)(87fFKNt2ypEWX3INSvkuGhF2Lc3pQDpF9n3tcoMwf3lxJT(Fnj4T3woG19KL7jmT)H5I02bSV8RdgWmPEzM6hjpE95ne6AaVbixdoVkVg(GPfFERonBXI8fmWdwWBCj8MnuuMpJ1ZzwTtmJRdIu81QbPjUAqeNPyxgdv6WLgNFY2gJqqDRrt8AfI4vCqepxKq(87hFja(8rluiYPKMx8MNnup(72Bq8PeGpYryHpKfvFhtQ)bY5daQhWK6vVkafV(EZ)FvHeozV(tmPVXZ69cPAls4RSfIe8oNUkR24KDc(EiOc8)pxyD(6rEs9JiA1oA63Kdd8lHQpco091CAZxJmURUBmlo(SRtuJN46)CKZcYvDNNwdmqoV)Spi3idswbl105zT)V6fNtpARd4r0mvpLWcKQN15z3OOjcCI9c7FE8HCnkBJH(N9HQk8vwVWJfx5HI68wNqDw(j5R6C0Nsb)vutqWm1oD6SoH19J((TbfDFRhu0sK2z9dKD)HJfdF2DIHvwJLohXFyjC85NPMD3ac50yV0zOML0tRlI3LIF(n(exAG4yEs5pa5)2rEc4S0rL4zLryxRVBTZ0(g2cRyT)IYLIWQDUHtCmNFDSSe0gjBnilSiseH8FnhJ99ia5NCEPyjskwTszVf1qIf2FFrooEz6uXhjon5S9m2Z5COitdfPJrpCIyRCJpeGCGZ7nazNp8dAkl5hyyY)P100w7a9YD3dXJjDzTLmBrgJmy4(JVISfWN1HFog(2QpNwMWjdhlrQvKXE7UHZ33UAroHLTHoC5QvTMSdeEWWnx6w)pJczdUeQNwvLoDy6KPJEQvuLcsAgb9rQs9USCAsXdfpG)gdxMwE0(JYdMs6Zro14X7wMol3jxNCZC)nFoSc9cFls05(jmP(cyMu7ddv8bH6F(oE99bHkCRR8SpTso)AHe7NJBYXBXzFAN60DD8Gh3BNtCZ)4)pd
```
