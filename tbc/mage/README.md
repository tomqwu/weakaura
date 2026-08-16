# Mage — Arcane & Frost HUD (v11)

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
Spell IDs only — aura triggers carry every rank ID as
strings and cooldown triggers carry the numeric rank-1 ID, so the pack is safe on zhCN and
any other localized client. There is no custom code anywhere, so the import dialog shows no
code-review panel. Import `all-specs.txt` (or the fenced block at the bottom of this file)
whole: copy all → `/wa` → Import → paste. Heads-up: the `/wa` editor preview force-shows
every aura at once with placeholder data (load gates ignored, identical fake "55.1"
timers, both specs' icons visible together) — judge the pack in combat, not in the preview.

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

**Ring clusters** (v11 — two matched clusters replacing v9/v10's three globes and restoring the
v7/v8 layout. The sizes and positions are the canonical set shared by all seven class packs, so
any two of them can be diffed and match: outer ring 84px, inner ring 62px, portrait 44px, the
player cluster at `(-270, 40)` and the target cluster at `(270, 110)`). Each ring is a
`progresstexture` in `orientation = "CLOCKWISE"` on WeakAuras' bundled `Ring_20px` annulus, so
the value is **arc length travelling round the hoop**, with the unfilled arc drawn as a
black 55%-alpha track on the same art so a partial ring reads as a ring rather than as a shape
appearing out of nothing. In the middle of each cluster is a **live 3D unit portrait** — a real
model, not a class icon, which is what makes the target side work without ever knowing what it
is looking at: it renders players, NPCs and mobs alike.
The **player cluster** is on the left: the outer arc is health, green, with the percentage 13pt
white just under the ring, running orange below 50% and hot red below 30%, where the Ice Block
prompt fires. The inner arc is mana, blue, its percentage 10pt below the health one — mana is
the mage's real clock, since Arcane plans its pool to hit zero as the boss dies — and it carries
the conserve breakpoint as a bead on its circumference at the 30% mark, dim by default with a
brighter, larger bead popping in the moment you cross it. Both rings, the portrait and the
conserve bead fade to 50% alpha out of combat so the HUD breathes with the fight, and the lit
bead is combat-only. Since v3 the conserve bead and its lit marker load for Arcane only: they
mark a rotation switch that Frost does not have.
The **target cluster** mirrors it on the right and vanishes entirely when you have no target,
because the Health trigger produces no state for a unit that does not exist — no arcs, no face,
no numbers, no empty frame. Its inner arc is the target's health with its own 13pt percentage,
and its **outer arc is the threat read-out**: green normally, orange from 70%, red the moment
you pull aggro, with a red flare pulsing round it above 80% and the threat percentage 10pt above
the cluster — mage burst has no passive threat dump, so this ring is the warning system. It is
party/raid only and never loads in an arena (v5), so solo and in arena the outer arc is just its
empty **track** — a static ring in the same unfilled black, drawn under the threat arc so the
two clusters keep the same shape wherever threat means nothing; and it hides itself at zero
threat rather than reporting a relationship that does not exist. The rings likewise hide rather than showing a misleadingly
full circle when their maximum is zero (health not streamed in yet after a target change).
There is deliberately **no target power ring**: two rings and a face per side is what makes the
pair read as one instrument, and enemy mana lives in the arena PvP column (v5), where it decides
something. The percentages sit outside the rings rather than inside them because the portrait
owns the middle — a `model` region cannot carry a text sub-region at all.

**Buffs** (static timer row under the character). Arcane and Frost are mutually exclusive at 70,
so both 40x40 centre icons share the one slot. Arcane Blast stacks (self-aura 36032, 8 s
window) shows the stack count large in the center and the remaining window at the bottom, and
glows purple at 3 stacks — the cap is the decision point: keep spamming Arcane Blast only
while Arcane Power / Presence of Mind / Icy Veins are burning, otherwise fall back to filler
until the stack aura drops and rebuild. Ice Barrier (all six ranks) shows its remaining uptime
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
| Arcane Blast Stacks icon, Arcane Power CD, Arcane Power window | Spell Known 12042 (Arcane Power) |
| Mana conserve bead + lit crossing bead | Spell Known 12042 — **Arcane only** (v3) |
| Presence of Mind CD | Spell Known 12043 |
| Icy Veins CD + Icy Veins window | Spell Known 12472 (loads for deep Arcane *and* Frost) |
| Summon Water Elemental CD | Spell Known 31687 |
| Cold Snap CD | Spell Known 11958 (both raid builds take it) |
| Ice Block CD + Ice Block prompt | Spell Known 45438 |
| Ice Barrier timer + Barrier MISSING alert | Spell Known 11426 (rank 1) |
| Ice Lance SHATTER prompt | Spell Known 30455 (learned at 66) **and NOT** 12042 — hidden from Arcane (v3) |
| Evocation CD **and Evocation prompt** (v3), Counterspell CD, Blink CD, Invisibility CD | Spell Known 12051 / 2139 / 1953 / 66 |
| Invisibility prompt | Spell Known 66 **and** party/raid only (`ingroup`) |
| Target threat ring (the threat read-out), Threat Flash flare | party/raid (`ingroup`) **and** every instance type **except arena** (`size`, v5) |
| All six PvE alert prompts | in combat only |
| CC ON ME, TARGET IMMUNE, Trinket DOWN, CS LOCKOUT (v4) | arena **or** battleground (`size`) |
| COUNTERSPELL NOW, CS LOCKOUT (v4) | arena/battleground **and** Spell Known 2139 |
| Will of the Forsaken DOWN (v4) | arena/battleground **and** Spell Known 7744 (Undead) |
| Enemy Trinket, Polymorph OUT (v4), Enemy Mana (v5) | **arena only** — they read `arena1..arena5` |
| Everything | class MAGE |

Ten elements carry no *spec* gate after v11 — the player's health and mana rings and portrait,
the target's health ring, portrait and outer track, the target's threat ring and its flare, and
Clearcasting and the mana gem prompt — and every one of them is a decision both Arcane and Frost
make (the threat ring and its flare do carry a group gate, and since v5 an instance-size gate as
well; neither is a spec gate).
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
(sha256 `556603f5b216469609e22d6605072f692dadfe2e90e2ea0d98f183ea1b71f47d`, 10350 chars,
48 auras). It round-trip verifies the encoded string and checks UID continuity against the
committed `all-specs.txt` **before** overwriting it; `changed` must stay 0 so in-game
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
anyway, since it leaves nothing orphaned in the player's collection. Future versions must keep
the seed, never reorder existing `W.uid()` calls, and append new auras at the end of the
creation order. One import-time note for users: the Update dialog's *Arrangement* category
is checked by default and will reset any positions dragged in game back to the string's
defaults — uncheck it, or report the coordinates so they can be baked into the script.

## Import string (v11)

```
!WA:2!L33duUXX59P5aPffiL0DNiPePLSGOfziLLOWbC4(dJySaWbChiXbaUa3D8otRdlawGD5bS7YDxC)tr2XNLCyTRQBV04MM64YEPvTk2PT(EYUQXoo2x1ZTnXUz61ALT5L2MWy3O(E556htFV(VK08nZSlWcC4apE8oNtk89iUfZoZS7oF)((99nFFZoanE35VXZE9hF9C85NPGMIAyLYkAxWLlxPC59Sbu7oVISHMs5YcfclkvUGMG8tPEKr5lj45z8KQm)ccAEcxUQUHGwTIZWRvsWWU4BMtrRGGwiR(xTZqLLwCrETcEYOOu2qsvB(KflQlyGYPYdDVH6XO9tMqHH(kOwEEzbpNYtunfDJCS(suBbwtg6GROjussroZcQcCL0uQQUcRkPLwuy)RkjxurRcVbud3RYob75dHqUwNVQHOIwsvYP1DNdEslkvYTgFEAb9XPBWRz4oxrjzjDr3HG)y4EjdnPsLe00tCknRd)CHmixD(QA8(wJ8PUQq5Ysf0pE3EdvfAuov640s0YJvq39n1RMtyw4rnD1IfLMF1PdhmDMPtNjixMANkLMaCkU0PIep(TQQlezE4(knRhYYjZxrq39kfeYb9a5HxBKiXtfDS4lxv262Y9QfK0VAvz4PzwbF8LlR2fp94mSZpQsbHV09ynCfPqjb1UsFTQGeWt0QLl7zcrjdH1yNLnyFFlZllXgm7dF4ORjWRlK2aKyLmeVx8XcjRilSEb45NuJPjJjA6cWGAb9LivLCxI9gQcVKCu8Zcna7f3d2h2p83J0CjlRluUykfjzJCHJKiteUtivynl4fNKCj9BbNsqtMV84WvbUEFKvlQbJjW9dVbVRBXlNheTrjfrUU5shMlsKeRyOKFww9pqQJ4RQuHvpDPaxBrJlRMj0GC655ll4AfqcWrbv62yMyYWJVRviplsmWsOYk8fCVk7YqVpX9D9hhJQP4G7yklCCn1Kre4lBisV9vF4gp1O8Y8Sty3gAjHHlLG2ScEIljlO(iBYPmupAJ9wkfaAYlzG3p(9HV3)4oXha3p2Ti(Gi8HW3p(b2p(bDJ7KQdG7YnUB34hceOUXhXn(OUXpCItHFKphimoo(9diy8JIFm8hWn(XXEWpb(e4pyw8t6gFs8PW)eUXNgFg8t9LUh8hc)04N5(WNLGlAw227TxAJdG7deWyx4b(i4bDHph(Ne)CGecF(vl41BVHNvo6uloo(d7c)8UXbDHd5gh2nEiyi)C5avdTPxaX(78i89IwLVWvjmpfgLF(oQ)fj5oiJaqRupCbbDEdcsvGqlr4nKliUQobTimpCcHSoRtufGKHvho9Y8YgOLeKleuUuzHx(OWT8nv1ukPjORNwPQwEHN6rVNoiprWWUlYGBxUxstXGQvG44lRkYdpbx4uC5ffYptu8JS)LMLxtIpxzHLKKdRujhVb3S8LRkGoHI6jo)51YlYlxsq)4NcpffBTeC9aLlJfWJFk8eqp4cF51HcYd0gIuqgEQteWl06UFo8hH0SlqbL9r(Ohx4RCRI1EIO0H16f8hfAP)gAjPndMAFqd9X(eAp(fQ1ILRWpV91SBsdpXZDEwlrq9gh)8h)6hvTBdyuDADr(ckZDzlY(LPLr(qTZt2Wn)jpPANoAqDc7BYk1MziuWXYKu9HOfcu5keQP8tivWqmuq4R3IEcGdvOaTWpX6mT1jz3aLDTgTce0HuXfW9TcvirbaHsKmre8X0aMasDwHwX82ggDXU1lcggv7mQM0IEUuv(ceEhpzYO6T2Z10mBpt3Wd30feYdKOLNwvdoGWeHAy4X6UdToTS5a6Nj04vxAcRdwV2LMs6NCSmXJLiI14vdSrQN52CJqf)uAAUILvu0ydhZc3tasmB9leXs673ASZw4PEYBtNZkmxIQvYjOLtuqQKOXRVT5hYLha8tVab)1BpojRu7eu7dAPHtv4fv7kxnvAlLz1(JrmwuKpVWvcwOqsz9RmHa)mbjMQVYOcfK4VIvn1VcHeEAFEvN)SgL4PKqRqDdGQTJWHhFz4koD(Y866zZza2lKnokxLQGFmU5OLEQC6sK6gA0Gdhb)ZEu8NoBiWWF(JI)zDhshgljhGF4xWIK9rjeRCul(5ygiSiCxICDiEpKLs7wJZ1z7WVQ6HhdQINWI8e3we0KaWCEDBo7pBtT1MVoxfjnnfnXMh(KKfXh6w2SzgSXKLuatMGHfD3ldad5ce)g4cfpsIHOo7WztTDt9kkkgIPSAD2vOuLrL00nex1QpYxwsvKqVFlRoNGPjDO6Hdhp4OPYKmu8GHVyWHgkwMyJd466YslK3TQxsnIbcUiqGLYRurLCLfjMsIGFHlq5Rcq(Cak3LVbCbwx4MJWg86QDvNe0s6J)KGbhHsZNlEY(cgxFunjzI3ccIltFui3N5ILiDSHISQIMeiXOp4lhoEYWxCIyPJWGPZBbtFq3A0Mjuq86NdFreooX4eE0oWjSneHtkItLfFjrmhcNMAlbNzJMpWJHWJd2mEkgR7(bE6jb(vM1bgzlZNJR4WGWsaXSQYCcAaVCpTMxgNfH5VLn5lTYN8K48mhdkGfWfXLWIFcSu59HVkCdndUmG8QGLVaBeN8z)bC5cRGvXAi1tVzKc0U2bHdEbSo2axfplEoOFxmR6t2(MYkd)XWV4rW)0i1NT91EJuS4p(lT9Do5NzJ8o4pHiEjaUqDs5Lj0c4xjl(trvTV(PW)1WFAMMp(Zql6VEDD(VDDDxUuuXdrx9ZMDz6TozWbr0CzQTQhMqcOjCTQsAc0Aty9ZUoP0A1pBljgW)nVDKa4)wI4Lb9D8ph(VTB8pp(ZH)7GW)czX)DfX)IuDu8Fp8Nh)lHWFH3Pc(VpvPkkrPcqAuTPEPY)bdq0PW34LW)dOQpXcnL3ZCMb7)c9Nh)llI)hI)hHFn8)y8)KAkf4xx86EOyBs3tht(QoUT)NrVT)NJA8oF1T9d5dc0Ymd3m0ATB)abiAwWyWb)83d(qAw8refoYqrOJVf0122qk1UGPMLxtWaeU20NnaV(kQNBRBYInRTPPtyRMvllpPTCSEy89MA)(6)S93dqKSsDpBfjulNF1j8wCKuxmWG9n6yubpHA6JF)5yoejIdplGUVjb0rNb7mYkZjBJ2)mBaZVs9kDGN1g7FJ73PqNmdJ)B2Ir1J0GYlXZwEdfnGVAnNNaCl1gEqnB1GkF2nhX4ajGFJgqbUCcaWFfQO3hy6Hm9cIKTi(y5iguemW(1iZGnzvdIG8BLtxemnmZs2Z1ne0zbOY2wi7HEb)TOhsAAOI8feWVLpOf0Q8vBsUJ)x0cP3ioLE430sOn7Ojg9Ydvn(qZgUUqRl8VgiV(ue2OVMn7dvqTc1Tf6KlY2if1x3HuQRR7F1kGzUYX0hJ66bmdsF8QsIelxmBwA0ZtMPvN1NSBdZF8fAsj9VXMPKENQmVMQ1eBNsrPswymAn29srPYcXkGFSvyFvLhCI6XyphtRd2jwabJyo(oCVdZJ8Jp5wJ2U(C6xshyIfKZl4YHTzyE1FOqjuKfWhIJEjWpWtu)Avv)saWR(31wePXxywWBAqVABBrcGgbFylbXIi8ZCqkOHavIzv6coEE1M)73j(gtsbjNF1qdoSrKXv1M1OibFP2jTEdjPtcsvm5IkI35(AGNULt(ZXq(IoVFwaTHqL8ing6qIx4EYaU0otTaIyDMmIGQOrJXkX6uoJVYdzFkw1JcEMlwlmjw1VXWK89RhMKxDpEys23gdtsEUidF1j9Mkv)93QWKq4E3xDU3M0oH5XqgqUn2rXVb4hGfJjQgHjXwP7T)t0g4)(KTG)7)kH9XbZNQVK550spQS4fQZ896uMVTIc9nE9TR)47Rr)Xpx9OGyqXzQ5nWtDI(PAc)uwAcVtOgIxchFjyoh4PC5uJ6DgUH6SkR3OXaAZJQc1791ozTRCnx3vF6n4ECTk1kFJD6PFfBh9vFI20j1Ch3A2aGwC)wwwTNmGth8Br0cQ3xnmRaQ79W8biIZDv)1jwixLyseiliznilD62KPNlYGpAwNao(u47pBiGOOq2ndtnlNkp4lEwFQZc9e8iASqfE5S(meKZUIXCGxkluuAwHS5yhNf7nltrSMNVRWgqigDX)aq9J6Tv9YYAPB(OWjFv1oTy1slzuL6acvN9U27(FFRPm7J6E0aKp8ZCU)1TCUpCLqtm4LgAXKXIU5o3VZOBD8BNXL66a4CTCoRUACoRVtskY8AOMaN45bChG4EX3pb69saOEpXCfBbnni73zNo3Fa(fEh5gM92mLJn8I5mM8YZfP9ZEBFTWrE4wB96Wwq3ol()nfmJ))Kf)hDIb8c3(QDxxZVMN(avjfyJ))2kGSLF7KqxZ(GepNaTWs03CZTe1Ot4RqdcFQQL1bxX7UhA12MMMUztMM4VyXurIQmrXjQu300xUUt5)WS4)hwmm4F0pcvOLiGFe6Q4B8LVUF8Vj1bC8VLd3VXFNn3X77CmZ3L4fn(FhuRFB4)yIFY4)9BtVJXR7YHAmXTy8)bq48Fe8hg)9iEbJFBe(35U1RxSzd(7(hI)pHW)Uo9VDSG5JKQ6udU4PLOml)Em)zDJ)pJW)xA2XZlOEClFcTYZCiWrrGy1a88uxTBRZflpCcEnnjbTMRpnOmEMqsUGYC1sQxS8l4zCbjzDRtWCWebJo3h1)YdThppC2jAnu1If13OVMbIxjWfKchDMaCTYxZp4ks5vKzPc7rVhYdgd5UEEfLYWOHC65KufYUM9xjPEwCZFY583Nx)(2sp9d8rU1mccQbjHB3GJyzuKcbaLZN)cV96LkRmxun2u4wGzOJLJhYjwdyUgUSv2MYUePi6AkiL08cLxH8140eDFKvjhBNLMLlz3eQLZ(cWmA6Iwj7KLeI8frAvttZWm9ojJOu(zKf01DrpdjdV6DrVqHyRXHR)quRBN4K6TY8gQPiYsYlvlC9c)IpbZJQA9M62U3wlwIer4MouYmzsok(fFywhduRldJHSeLVo7ptRWEYTw(awPoJMcpRsStZKvc2Nwaab4N2(Be)WCH)4xIf5jsKm2SGn5m6fhkeb4HpGjIQTD(vJNk11eZhi1ibuiMqG)fArfLkuz0s2WVS2CjMOoupSDPKGRbZjMKuwWTpGa5gxYeDISeD0FzBkmIsZXyMuS0VAQKJSHsiAroCTjNoLOb8VXVZPdKfFfYIq4S9CwcCGqsmORR)bnrhWP6Kj6(YAICV5AoxLRNE61xFC943R)EOF6J(PFoF93J)E587VxVb2I6vMOdvxv6CVTj6(T1FmrpGj6bH7KonrDzI6(iMOhczIomDsb9YSv7YLj6iqHhv0e9WWXpc8)Jbv(4I7aOst07h)IhRgw0e9OMOhdUyFaA)zIEC4EZd(PnrpXwgr90RyJOazUd8uIyPlD5HQmYLkjAHNmrpjfnzIoPdCeu8P29an3uyEvjwGhZivHmbXaoDogapMOtVDbnhNRhFE713UhSWvnCXGb2ZalIChs0uhwCixKugUOWzMBc5c6d6VT4I9vdxezxaxyI8UZJf6T)7wSat((GwYyhabxmAblScr43565QAyOiNKLS492ObVV5grd8ayyHOJm4cr69mYYJ2wWW(3fadUTe1EdvstzUtmwkCh)k1cfA4Yc8GtR6gox)zrMvjpLkXtknLkQ1xkzw(76z0yPthlXWo8TL4KSs(zSBGTdXXKP20LklzSqZDgDfRnSqf7YFehDwCsSW9KEKGzYeH7w23RH9KmHNrJu7Ygo5yKvbiD1q6jrYjupSDSCdYnCKmEIn6OJLic1rBca)BrNQeZ1AoDv(8c3)DRV1RcoXuTICAsNrxNAbYX8eIJVSujzCFAGXCY6QKo9PWoNzKgBDtkKLodGpSRLaHJv)qNM0tJp0AfwqMVIuEAmNGzgesxrZa7D5sAsSvV0bxICiXL0tWnexzPksghKeZQ4KJeVj44dC5LnIYNhMrDoUGdfBS0504livv)LpemNGLbzpZd2x(O2GW1TNltzbnd9vkwTC5WsA5b3YS94hMoi4B)9w(UykfaUMHlp)Q(oZLoD4RE1z7zStV9yJc4VVDtltuNvyPg0YYu29aoSuS(SW)3MDZNiUnnehZxLONPuSEhxyYb5MTT0q9VP(QyhZK1OXmzv9YsfeYPa8ZvO5V0VDcpBMA66DUmDH0sWQRRtYWsjrd6eFWhlx(Q6qhKJwHfOUcqUcSVpp77KiYmoIUmROfNT7fkCFDppAzAuBi96s29k5AVoCSSEzYk3doLAx2NlJDXWnglSu2fKL230ElBJ8Mpjakr3om5l0qmV(17(5WFdh5Mg)BKTTREHR3fNbjVwHiRyr1Ui3jLeKf0KYNwuzUKYzxVHVUQo9pCc8fwG09lttUEc(kch4zFi8X4OF1APGDSWwtEXJ9AWYZPPly8ZO2nnu3LKv0eiRelGjri76Ac8LtB3DlxZsW61s0pPCAKNj39SNLLTgjZptw1hICSazzP7S6BUA4tTLN3GFwgf2uTWTIAtlYb(g0F(6KbXMuFiRAEAQqbkv1tuFvyq(U(vOJxtNGS8jeMovvnywRu1TlnzjPtNCsHXtjSr1nX6QBdSfv3mrtGFlt0L3CLmt0KMOPideWO8vQPkzI(OovJmrVGT(JjAAtuwspzI4nr5G(YeLhg1kSD1cEnRjAAIoJj6PmrFitem()mMOZUoyUlVOGodeVodepQKozPr2ogCQcIjsWev0evcUSGBJsKgyIUkzAzWt7mm0UjQSjQcud5vDeEotKAtawt01GkPTZGlBE(S7IaZnmhuotKUQNwJhHrGPJdAFYgm0yWeJCXj8Ty0EceTTOXbFVeAS(kR7JY4JzR7eaBzTE6(Szz8TnSsLZQE0gx5Y2zLa413cyYV8hRLyYLR5M8UjIKTuMytL(hdqs4zTfqYNO1qs6RRf7tgMCGqlWfDMuZeT6GTftEU3BIj)ZAmzy9tsgg(pNK6Rgt7v7qBVslXAR5CMx7IWnxwl6t67qYDdA71yz(QfjwIHc)H2arac(1FLwH5otZyUGSN(PjtOzANJhmS3OH7xrHFq)fxO98H)KVxb7j3cFu7Fl7J6xfFSqsgcvinMacbFlFKw4BzmOkNHXVAbtH(AnQNMWzOEdUK9rhy8hTE))2KXLpj7fPqPQSrwgKEfsh6jmPeYkGGEkNjjM5flZHZAxb4IZrRjmGcxEt0RadhFQ6xU7Ekw)wuSSfn8DfY)oDQCeS(jBgRhlX4tdUsLF6HfQmDAdfzHP92ddN7DQ51fhy8HwCk)TfN)CVxIJ1k(al6RhF(8nqFbc1xpK8D41NFVC(637adqcJ5GK8D4FWa2zeVjNp1gji3Orhl(TZC)S)V2CZ90azTT4Fp3wglgGs)oOR9sXN412uM8BkRymDdRgCMkCJf7KTNma3cDGtDB9XGM3EMsWqtjRWRn8PLcmuBJ8X5FxGsWwpkzNISUWcRPmxbYRgS1BSp1cWosCXyVgv9eyxh49yBrG3KwSP1wnnBcB6PW)jz5iBRa8zBoeztf2)4vQEv(kJ6TTSL)u1aktUNdO8lwFrJATrnqFn7Nku6mJLWzoLBsmIVYTQNH5gFhGnrFb8uRtA)0Jgj8ibtelCB7it0nASTHIgjixdnHgohRLgrlAW6Kg06l2TPLAHtMi6yPJSH2yLHrA43B59ixYKz2qRSJ7uRUsPJfpsIWr24qHDiJB1dwQGHJfDYTttv7mD4rsMm(0Xi59GBSuzUnn)o19WOeN)i8dVAOWeUtIHrQ1pQQ3mmlBAzPg0E11ds3tm8mgDfrawcFJxPwLXpknIHIalm1L7Slx7qn2rcKlf7974h8EZW0pP1COb2iNZH(R18COFJxPgPKj6ZNTrRCpz7SYbEyKwuj)mmQRf969sZo1uQxlsP2AJ7dVhM6Q(By3ASngfzoY2CqtVSjzXxb)M3rwdD6tixVb61)a(6RxFHahc9Y5h8rSxoF(heoUNbd0p4vyV92FpBIxH2ZxHcYnrFr4I9Lmr)Q74O53vBCTrCmdEwkrpdm4elioCLl2w45ZVhgEwlx6MO(wzKKCXMkzImbJtYOolT2HhQPLbQvQWPLNI8EdssSTsrpJkjxWkl80ZvB5HQ6PEHPRwPcqWobpqb4jszbsWC5l7SzGv6cEslZR2yFzfNrNfwlvooVtPZRwqJQQDR6fhQSK8moRxdrpXoF6p9(CKqDtuW77UnB6MOqSKOt0IPQYr2yEZnrrTtzUjA46jl3enc(b2Vjkggeox4GMOlEcUHmrXHJgfMTwctustukAAVnrxQE(Uv70E1eyfmdDtu6MZ1nAhjv3JoW1gAUXnuvv5OMK3A0wnnXZvi5njy554xq3EcOpR7whdqN4W2oh074xG6TFScBYiT4DCetcU9wwwVf5DD1AVflR1k3R)YtgFwTag(NRTes)AaHeD9IFJG7ylkNNQMJDROiBJ8A6faJALdQxF4h5PVh8L9fmXq5OBpq6pvFw(e(Bcgg7R2lKPRwSaVEYT8KfBcNDtw(5QDVzJ1oylXAQD2m52DBqNVtwIyMOE3PXphSz8Jj6FJfUrPuCvHHMn8a9VyBXnFTDbCJ77iX6l0Q4w9TTfLEFZnlUvwMI(RyCgByX75qMlV44dK5mvg8stfOTY8V(UkxbvHVDCeMOFlt03zhNEO94Ox8FDRPeoARDF5VIHQGrNnfv1t8iL9VqKXhltpTfv9R)EsuLCBrvN9R2A2PAE8E7WrBOR)U3gIpteE73NBIsGjA9BJHqF8YlC3UauAi8)7wazqGSPazJbcCzTzZipwFjAlq(BSxaiFUncKdrC2bAl8T7LCMFNDyNPCau2KfhIj6LE3ThtByHG4aEeXF1HkOl6V8GHBl8434V09yQ9YoYQRSLYoL3L7T7dT5YUusg5tKFIQ(f0ARS7BU3w29gBY6KXzeqExTq8nELnxgE5EUqPlmrprwWO9Z09BT3wgE4fBPmKJgUQ3vl8GNSnv4L5YbptaTz8LX7zARWBT92cVxztOo)zExTGRnkD58nQqI(hiTCMyTvU9VAxuUrItDOHsorcChxT(2FfzFQtWWdPCROn)mEMqQCzsOBmef8evrtNFgbzwnSFPQIiluzb7gR2LDutt7HStNMCSm1QykLYlurrtv0dP0UAO5Kx6Rw(czzIcE)7yXp2xMKP(XxeKxX(5E2uTi0Xf2zEnPUKpFsJ1ZC9hEMX3IP86JXw0EMOpz9LSNj6LDS28(UoxCC)CVtdR1VTCZ(VVTAwSV42RzRutKBI(EBGyi7pUig2Ejc7pIrmm)axoDXl3B646d3wIHF)DrIHp4oG3WFGNV1X95WTIl5oNL)hBcZTus6jpTTtOgCqFYtukIsL4(ARq9pypHqDwOpEvnRF6rooxV(8nOp8NLT5NzvAw8B5RhFEj7M40LCGNW0nbNQ5Zlq2wWj5((Z)x6gO3s6HhTvYRCXMAY(7txm6Lk0w51n3nToVIUkV2m0xL3JWKD12sNwNEQA7J6QD1W3j764yqR8eI1StUmBFCTSsjt0F8Xd5Rh)dIF8vQVsHWVv3dGF1vy)us4jUsjgV6p0Ap8LUZ8q3v5wP(XGj36sy6o4JJFWdSYu7s54T(5ZPHxgkaeSg9wMTF3mjyg(ChfFSvj7o8qlMg()oWcyyv2UpdxSHhjtTfMZSuGJ9Uod73OaFW1RnqPJT9wQo3K(egYEdWh)njBRBemgtWgU(yfOts2h20SE8byKZrNlJwMo4QlvqGJ9WST9zWHU(Q0lXi0FNfop(RWrEz)LbSm7sB)7GWPRVcJcZ2iacXRDLXI9m1)2ZKMc(OnZXAG8peuzq0TkU36awB0wxBo4bXBIHNnpzVIZ6gqQqbbzUergpch(1mr)lT0a(c0TPFYIR7oG56TP5)oCzfzb9SwVQH(6PhY65EaF9s)ma9Z(4Gp6Vh6N(wvvqJaOjsPL4lwuiVHqbnL5KtkxEHSuUSBs0FKKfsXQz2w4SPj6NFhzbBpG1sqCpZwDsS7gM0YxtrF8HIu1iA7T899RTUEITRTrN4Ft3Otax6VvZCSMO)eye5)PtI0VDJ768eBCF5TW(iUj6)Ntort0FQJnnZABj(VjiO)ZaIWlCuIa5p3skZDsYVBxBBb9kmkW4rIMP2oLQ9EG5x8oTx)so)ryWe9)NShy(Rs(fwGIK(NIyuRMDCpMDGApD6whpz2rh1jon7WvdeMMDq27an7y)iZoEFMDCV7i8IMDCaGo0SJ7dqJMDaF9GMDCih8A)GnYRjQF58xS3ru7FY4aQ1SJhWSJh0IlRE(hWFd7FOKQHb34AY9pTXQ3tJvVfVBr0g1iFz3v6Uq3fU(hOX9lBC)MO3hDzJ(weLtR9xqYEl435a7X38QVVnUHcoF5bUQS(fRi1)fAXgky36C(pBGZ6T7z33l9x8
```
