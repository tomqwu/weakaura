# Mage — Arcane & Frost HUD (v12)

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
Spell IDs only — aura triggers carry every rank ID as
strings and cooldown triggers carry the numeric rank-1 ID, so the pack is safe on zhCN and
any other localized client. There is no custom code anywhere, so the import dialog shows no
code-review panel. Import `all-specs.txt` (or the fenced block at the bottom of this file)
whole: copy all → `/wa` → Import → paste. Heads-up: the `/wa` editor preview force-shows
every aura at once with placeholder data (load gates ignored, identical fake "55.1"
timers, both specs' icons visible together) — judge the pack in combat, not in the preview.

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

**Ring cluster** (v12 — ONE cluster, at `(-270, 40)`, after the target cluster was deleted for
duplicating the default UI. The sizes are the canonical set shared by all seven class packs, so
any two of them can be diffed and match: threat ring 100px, health 84px, mana 62px, portrait
44px). Each ring is a `progresstexture` in `orientation = "CLOCKWISE"` on WeakAuras' bundled
`Ring_20px` annulus, so the value is **arc length travelling round the hoop**, with the unfilled
arc drawn as a black 55%-alpha track on the same art so a partial ring reads as a ring rather than
as a shape appearing out of nothing. In the middle is a **live 3D portrait** of you — a real
model, not a class icon.
Outside in: the **threat ring** is the outermost arc at 100px, green normally, orange from 70%,
red the moment you pull aggro, with a red flare pulsing on it above 80% and the threat percentage
10pt above the cluster — mage burst has no passive threat dump, so this ring is the warning
system, and it is the one number here the default UI never shows. It is party/raid only and never
loads in an arena (v5), and it hides itself at zero threat rather than reporting a relationship
that does not exist, so most of the time the cluster is simply two arcs and a face: **the third
arc appears only when threat is real**. Nothing is drawn in its place when it does not load.
The **health arc** is next at 84px, green, with the percentage 13pt white just under it, running
orange below 50% and hot red below 30%, where the Ice Block prompt fires. The **mana arc** is
innermost at 62px, blue, its percentage 10pt below the health one — mana is the mage's real clock,
since Arcane plans its pool to hit zero as the boss dies — and it carries the conserve breakpoint
as a bead on its circumference at the 30% mark, dim by default with a brighter, larger bead
popping in the moment you cross it. Both unit rings, the portrait and the conserve bead fade to
50% alpha out of combat so the HUD breathes with the fight, and the lit bead is combat-only. Since
v3 the conserve bead and its lit marker load for Arcane only: they mark a rotation switch that
Frost does not have. Every ring hides rather than showing a misleadingly full circle when its
maximum is zero, because a `progresstexture` with a zero total draws **full**, not empty.
There is deliberately **no target-side anything** since v12: the target's health is on the target
frame and the nameplate already, and enemy mana lives in the arena PvP column (v5), where it
decides something. The percentages sit outside the rings rather than inside them because the
portrait owns the middle — a `model` region cannot carry a text sub-region at all.

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
| Threat ring (the outermost arc, v12), Threat Flash flare | party/raid (`ingroup`) **and** every instance type **except arena** (`size`, v5) |
| All six PvE alert prompts | in combat only |
| CC ON ME, TARGET IMMUNE, Trinket DOWN, CS LOCKOUT (v4) | arena **or** battleground (`size`) |
| COUNTERSPELL NOW, CS LOCKOUT (v4) | arena/battleground **and** Spell Known 2139 |
| Will of the Forsaken DOWN (v4) | arena/battleground **and** Spell Known 7744 (Undead) |
| Enemy Trinket, Polymorph OUT (v4), Enemy Mana (v5) | **arena only** — they read `arena1..arena5` |
| Everything | class MAGE |

Seven elements carry no *spec* gate after v12 — the health ring, the mana ring, the portrait, the
threat ring and its flare, Clearcasting and the mana gem prompt — and every one of them is a
decision both Arcane and Frost make (the threat ring and its flare do carry a group gate, and
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
(sha256 `92508e8db3151660e2520b9489b64a9aea91f337cd07d9479f04e6b5a70087a3`, 9914 chars,
44 auras). It round-trip verifies the encoded string and checks UID continuity against the
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

## Import string (v12)

```
!WA:2!L33E0TX15DQRGKTmKLdj1dll74aRyPvYXwcpi4dTYpaabeHeji0aqsrjztmayaMreyMrZmGKGPY1H1ovB3t32Y2ton1DB7I24Tjv7PByDCC3M6TL5rR3nDZDzADMUU9ST60toUp(l1UTD7J0(DV3zWlccrrr6s7Mtm484EVZDUF)((99D)UFZvOX6kZp3N46FSLtZNzQSAkQHukOODwhoCe3H7t4xTRmkYgAkfkiKnKOuHSAcYhsD)dZNxW1t5kEb(YcAUcvOKUHG2ntROLvqlOvdP2rWcsZnhVwwxjvukyiPQn7i5YPlyGsRYdTJH6drBNKbdbTvaTm8YcUoQRiAk6gPzTLOwzwvgy3v0eYlPiNSSQaxEnLsQvyfjH0Cc7Crj5CkAf5nGs4Cr2nyViieYXY8Lmev0grLCBDNPHxPCs5DQXNHEHE40n41mCMoNKSKUOZGWFmCoVHMu(8cA6XoQM1HFMGgKNoFjnEVlr(vxvOqbPS6hQl3blbvkTkDazE61JMv35n1lLwyA4vnrPC5KMDXjdfirYjtKmaxYQ3kUMaClUeXdp0q3QKUq4zH(vcwlKItMVOGUZkzfsdTa5LxBWWdfpYOdTqjzRULZfZkPFLsYWBZ0cE5luqTtE6Xjz3FyLSc3yBwdxHZMxqTZexTeibCfPuHcUgxuYqyj2Dzd233c8YsSbZEW7nYsc86cjmajwEdX7fFWGYkYclNfE)jLysYyIMUamOMvFEsrj9s8jdwKxsoc(eqfWNe7g7b7f(7(A(klOluixCfjzJ0HchlzyUdlLDjl4fNKCE9Bb3sqtMVWyWtbEExAXCAWyc0F4n4DClE5mGOnc5sKNB6eH4chowfdLmtZk)UIVFVLKYU4XY7)QZzCb1Kb7NtpdFbbhvajahfuPBJzIkdV(oQqExKyGLGfu4Z6Cr2JH2pX(V(hdJQQHG3(CQDz1HtkQjWBq73wy7Q6idkWxWqKDRhSXBnmVmFJ1HELqWJxqBAbxdjjlOEWv5wgQ7TXhEKc86IQhOXhrCfadZlzG3bEN475VOd89I7bFFIyNi8UX3pEp7e)aoXFeQYcUdN4oDI7cK8oX7ZjE)oXhi2rXp4NbKApe(qauh)W4hb)rDIFu8hd7c)y4dNc)XDIFC8rWh1j(Fd(y4JFJTHFc8Na)K3h(PiaOMbb(U9WcC3y)asa7a37LW95a3p(u4)TGOeF6fZ62D3HMwoYfNBm8Z4a)SoXpNdCaN4GoXHazZPsd6qAtwgX(7Si89GwKp7viuuzhMF2Tx7ej5TtgbGAPUVSc68geiTaH)IqWiNvCrDcSsyw4gcPQVmrua2iwz40lWlBGMxqoBa58feE5daD5BQQPKxtqxpHsjTmcpXJSTTtEJGHDhKb3oCoVMIbv9bXXxqvKhEdo1r5YikKzQi4h0X8tZRjXNUGWcguPQAgdUP5lus4W96(WkQh(zEATmI8Y5f0p0rXx6SuKypKF84yE4rdkKgLVvUQDskv4rXxG004j44ZdxgFjhKw6PFA8LPTbP29hFhqt4L9Rd8ZJFHQvArwhH2jWxQlAV40w1fbLCC8ZEORFa1UmGrRj1f5ZQmZfSy7xGEnYplDKQVoh5iQDuxzRrwR(Kvl(Kmo9jRwPjZkKbiMkmPQgCar7gDtwJytIemWOjhrDV0lcS(kewSmJlL1qmya40BXAwPzfYsV4NAzMI9eSUAPLO3NapKYvg7VcvkrrabJnsSWQpwB6BSlKowPIPf0WhudyxifScT0zOVFKX4EDqgE71VJfSAgWoyhr0KMZ15lXNLqQ5kzYgghT6COLPxBgGOACnE15h36GLR2ouZdJmAYHIcDv2OBd8wQhPnDFkqHsMZLRGIIwTMLyHD)wdu2Yu2a10GmaaPPslkiLx04Tx3Q7PZaG2jltgz62t9CpQDaAXbSuyP6VIQDMUQgQLUPAVrjgjYXNr4YbYMDez9lpUa)ubiMOV8WczL4VSvj1VmHODsVUvN9eg55PCkvOM)PkViCWp9cWtCYmalQEQfjhcLN4UrQ5jNOdJfIPnaZhYghGRyjWTgNAwL4a4FOJIV)ubbIwWWnTfoAADjs7gC4aNjm(h6a4FKubbNdYaf1zqsBbhmnh4nKr5uEvNgEiGCXOCrE5uEneKtvXyg4bvohympvA2XPWNmvng5hMWcxHjfhL4bc8QKxWaiKVjP7w7gPagBoQ)gQDyzPiHKrjkheLfVr(70fL00u0eBE8xsweV7BzZUzWguNxbS1cgA0DUaGgKZsC4Gl4qHJna1ljoBQUBQxurXqmUvTtvHsDgrst3qCrR2itbjvrcD)TSACceN0GQ7l0qbgoEYrcouGqNlWadenz0XayEnWGf08w1UsvwfcWYV)5ZOuuL8KfjMwga)cNLCDV(jQL9r(XNdWwd3meMH3wTZA8NwGh8ldMFcvm449F(bMBKOGsRmXjdbXfOViKEz6OXseDGWlQOjbd10x7fcn0iHo34rteMHYN1cL)ao1OvtiR41pfEieEyIPkCSTJhX2SeoUi(8PWCI4eiCsQLf8OR0ycEmeECWcYzzS17epX8sYHukMM3aiNRNLN5XcWwxLxFzGYid0vfP(NGV0H9tO2760SY)EptdgbWFzOa(AOaHAOalueuqTAPvZgbMhHtR2XrA4bFKJGZYC)ihopwelHVYNcpvbh4cWlArSma1VkMoTehyDSHQ7vWK1qZ1cdf4si804zWZIlJNd4cp(TPfQXhI)(WF)PWx7HXViQfmOnwl2fXQ4x6ZV(995tTsEq88I4Faa)r9b6vaAQXWF6u4)DeEe8p8rX)hW)im2f8pk9s)y0FpWluplb(vtZCc1Y)nkFwjk1ar)VQlCnwh19rypCfsKNmDjbnjW0ygDBxaFRMQBv3)(pkI)zaMc8pl(NZj()eUc(NhH)fsH)CI4xJQDJ)pJ)fXFEe(l8E5W)su1XWwQJE8t(TpQtiE7JOqIVXNh)FHQ7jKF20dnspbgsFy8VSi()k(lIxe)RGF9QAu4V0gLU0tuvxc)g3wLO5byVQYmGz)l1LN2G6VLnONw4vbZVJMW8mUllNgOOFakRESvdisB6grV1b7bKS6J3(QwfcFT9tq8NS9LUfkAV012Ia9)g1GXCXPIhcS9TsTaTRtgCqeqmdbRUpI(GMWvljPjqlnXDQultUA1YNQL6i4)7Bc6dri6dasJQi0nv(3VFM6W1SuhIg8IUp(X7V3Z2BMvxDWffBtAE6yYBux3(Bq72)wOg75V96(L8bCYX8Z1Yf3QDF)(jAwWyGZF6TH3TMLLDIchzOiWHwd6ARBiLANzL0ZOjyacxBhrAaE9nvp1A37rwGtMKgZKQoqAnhvRPSEg89eFNE79e96bisQuBoJIeQLtV44UZny8Z5V)EgEuQGNqn9s7jnBMgI4GtdOBQVB0GinLSYmY2O9F0vG5RuRq76K2y)BSN6f6epf)U2Ir193GYlzII8gkAaF1s1FdWgVn8G6aydQ8PwDetDib8)ZgqboQhaG)MurVxWjoYe3js2C4dMM4Ag46QxnsqKgPKbrqAMwxeCZAQ5Td3uqIdBuzBlK9qRGnPhsQAWC8zfWVRxOg0I870KCh))QfsVbRx6H)wwcTPho2WxyGsdnW0HQj06e))gKxFAcB0Y2Spubvf6miO(FLQrkQVDDsPoBwkvLUA5AUUdZmlf(Ne)zjdZ)uPWx8W95gg7HPhwDEBvLHpZtdYSF6w4lVT0GeEa2pedSvvjrvfi4VJT4yLkAno0wHg0I4LkOddWD5HwSvsMVIb8xUfd4rjgQRBOM)C5IhoIY45gVyTH63U2q9pyk81fTui(3)EJ3staV3ZJVXBFDFlwe8iVquD28F2bENE5vLejppMlbA07tcr0hPw48AiWxn5af(xF14aVt5kxs1kICxurPykyezjwFjNubHOzXpsf2PQ8G7Apc79ysDWmCzemkv35qF)zDIFPjwBwfRf1Y51bdDcYzeCuNRp3Ni(jcgtrwaVBo6JaVNhR2ZQK(5bKuTZ1MdPXNDAEOrex)g8bGWZ9GwcI5q4NC3uicbyCwRRwUU3xTz)t6aFJjOaJtVyW(pJr4Xu1M2ihbnP2bTCdiPtcdFu5CkI35UYHFZwoZL6gYNR((tzutbd(SQhYk0RwlOrWc86WCTnGjLQxnqXrZa3GxdMKOwZLN66HRXLKZQmt1ifhntzxJjijRBDdwCCrGSBx0W4E)BXJJRDe9dwcMJ(kdPR)Hk6)SsHImLFUwfs3pEfPmkYSqP(iBJ8IX0FxoJIsby0qoXmsGVzlzFkznoex93CoF942N310BFVx6wtjiOgGeZgdoIbir60faYQN9SVZY5lOmtenMMuzwSeyb(JCJLaw8ZuWk0MPMNCj6IxfxAwHcviNoeDfv2)IKJTdY3c5TRc1X)E8ZIlHdAHSJ(wqYjI0IMGUug0EssrPmtjlOR7GEhYYgO3j9bfKTyAxFV0zHC4JO3QjEGwL5A30eNXx7XGPfaZJOARPUUBTLIglwyUjdosYKJmm(ApiRHbtnlaJHSvKzz2FMuXkUJwNMPA8ITw1XQXI0ALCMuaab4pH9zKyT5a)sNN5FfXE9Q5sv92O3DqcWd0Y(EeLTtV4qXJFvXm(JpOFfIfv4)fCoG)MkIM3g9LQkd2FN6(SViXbsGyIes)SPiSs348MOdLIOH(lBZEsuzoiZaRL2vtxzFR4keDiB3NbYR06uAgGbZx9SCPWppzTUoHNtqadekI(CC9pUjAB1RmzIqPmrBF11BUcNhpD7Thop(C7Zd9xV0F9X5Txp(6MZNVUD7FnQvzI2rnfPt9oMODAR9yIUht09c9KDzIUptKZ9BI2nYeD)05c1nZZfhomr7bU4diAI(iWXDa)xNDAI6sCdatAI2l(ApuvKOjAFMO9dpSdqBpt0dc9TdI)eMOhAnJNEYk24jqMxdnflAI8xyGIdE(8IwOjt0JqXsMOpAnu0FVj6r38Gm3uywvjMR1jLkswAh)1B8dGoMixRxiZH4841D3E38afoQIkG5gVvbue(oKKPkO4(DqIX1CchFMXLZQ3VV2Hk(hQIkcVjGkmrhBJhj0DV3TibM09ETKW1bdCWOeSqker)UwoDjddf5rylRWwBSG73CfybEakuoYG9xoC3hxwE42bf(h3eGcoTe0UdMxtzMdpAC82)cvZ0Gqfe4bNv1nQpzgcpTsgknIR4AkfvnQMccw(56A4Ojsen2zQZNwIZXkzMYUc2ochvMAlxQGKr5MBmA6pCgHI2x)G11ydrMkIRedgizYWC3YUVgY1iXCnC4Qp2qJmkjntOPBJRyJmU6(SZFIaCNjCsxrhE4rJfM6GnbE)BsNakZLAoDv(mc75U1N6fbNxkvuobPXO53q3PzEaXXxqkVmmVuWmojXDOZTly9tBtJLyocPOE()moMheowTdzYBGV67EPSLL5lkLHUKKWmccQdZ0eFYfYRjXwZ7Dpp5qIROhMBaUcsfLm2nzTagICK4nbhEGhVSre(mgkAP5cmq0rtKgMPNuj9x((H5cSai7zEU(YhWgdUS9CykiOzOxjxPcfcjPLbChZ2tFyU9Gp93tH7IPsa4AgU80l694N)yHUYvM2ZOhB9Xf53xpBMwLOUPWc8LLvPuBbCvjxTqe8hLA1JsaJeYeDwMBkroE(ODpMWe9ZnDByHmrNCv9tXo2r)(0yhTOEbPScPva25I0OZ5ZoCEntnD9owGMPweS6Y6KWLKx0GoHh8btNPKo0aPPfOm1naYtGD(SSZjrMACeD98PxovxLZEFDnlAbA0RiT682Tk5zVmCSSEbscFa3sTt77L0(YqhJfAo7lKI220wlvJ8Mpoakr3om5luFOzX)UDDA8VxDrEf)oPABS5VENCqhjZubj55IANKEsEbzbnPmjevMze5ul3WPlQt)dNaF2YKMFbAOJJXxuyxNCV4dYrp1An)EOqwtBXL9A176y0ms84QDrtjI8YkAcKvShysesTSMaFHe2n3cvTeSC1WytUojdeO9E27YcwJKzMkL6EjhlqY7X6l(QRg(eR5zm4JLYnRQw4ArTPfr4Df6pFBYGytQpK0YKgjkGsv9W1wJbY56xMoEnzmYIdimz8sAWSvPQBNFI8shBKjeglUWkv3eRPU5EnQUzIgb)UMO4RUsMjcAboYarctuYQQsMOrRxnYenMT(JjACt0fiTKjcCv8IqBzIUemQD51RwWRznftt0JzIoSjc40H6Eet0rxgm3LruqNbIxMbIhwsNKxnTJbNQGyIaFwFbt0KWJf()8KkyIstMqg82MHH2nrWOPaC7Clwxy5mrInbynrsqHUYgdUS5zYUjcmBA2NaW0enLQRwJhHrGjhc0(KnyOXaXg8CJ7DUiE8hPTOrpFycnwBDJ)Ym(ywy)bSL1Qf)wPy8TnK7hPupqJ5cI9kZa86Rbm5x8fBjMCHQUjVzIizluhBA0VpajH31wajFSwdjPFpaSFzyY(cwMlYuXNksP(BlM07hoXK)XnUGG9swqq8nx5Y)1o02R0sS2s1pZRnr4MdRuAGMVY3nOTxJUcGTyrVyGWFqBCiGa)2VsRGChVzixa2l)KK5Zmz9dhmO3WH6vrHVFF5k3E6qFFyb6j3cxu7Dn7I6BGpyqjdHIKktWGGRLhSfUwgfkYXz0RwOuOTwI6OjChQZGZBF0Ug7rQ1(VdzC5tYsyxLsYgPyi6kKg0viYvijcl9w1Vo5mNyz(Bw9jqYpwAjHbu4XBIUg0tEXApU7EgwFwmSSmI5Uc4FNotocw)inJ1JgBSjbpPYm5zekozcdfzHjD7HHZDFXz1f7BSbM7I(AloV7pmrXAfEG586XRxV91J)G94HSqhU96ZnN3ED3xFKyy2pzHo81pzHo(STW3tTbdWnCKrh62zTF6)Mv3ApnowRl63tTMXI(PSV97yRu4jETvLj)MYkgt2qQoXuHB8Y1Z2tgGBHoWrVTUyqxUEMsWaxuwHx7mhtY)aTnWh()aGsWApizhfiP7iKMYmzjFMzwF6NulaBiHfJLEVE8VPd8(ORrG3ewSPvtQOvHn9O4F8uCKpBv(unhHSlgY3yflDf(Id7UTSL9ufOmXwoGYpvTV0lRV4x6NX5LcMi5OXA4dfRrXi(5VvTLwUXVZmt0NbFPLj1FYHdhAWaXIgQTnKj6NSX6gms4aCR4JuRxRmIOfvyzsfA9d72utTqJelYOjcVI6yT4I0OV3Y(i3iJKCf1YoStT6jLi6qHJfk8khkSJyCREXIhiu0itSEQQAhjcn4iJm0Krjl7b3OXtEBQ(DQ7Hrio)r4hE1GHiCNedJuRFuvVmmlBxjf1G2RUCa63CTRrPPcbyj81FLQfg)W0agkcSWuxUtTq1d1yhjqEuSSR7Z(HZO0pH1uOb2O6Nc9Ynpf6x)vQskzI(js1OvUhVDw5apmsiQKzkg11CUDF(PV4fvVA48T1gxVBHPUQL(4lX(W7L5iFASnLQFPWpp(BDhznSEFc562F3(6ZBpD7ni4qOBoFGpIDZ51x)WXE63FVGxHD3DVEwfVcTNVcfKBI(5Hh2VGj6ZTHJM)aTX1gXXm4z(yE6R)XllEMINRTWZ(2cdpRUu6MOtuzWr4IEXrILmWqKfuNTQ2HgOPS)0ALWPxpojP4jRRTsoxdljN1Ar4P3RAwHQ6Q2ftuQyrGGDCEGcWv4ccKy5YxO(QbwPZ6kHmVAJTLvygR)IvxjN67P05vlOrv1UvTlhSGK8u1xUgIEI9YP)K7OU1t3e1)9D3Uy6MOtXwdDIw8Pj)80RCzZnrpJ9kMBIE2ARvUj65W7zNMOa4tAIccNg6WCdyIgaokSOjkIj6mMObPR6TjkATL7wTd7KjWkyg6MOZ18sDJ2qwP7H77QdmZygQQQCutYRnARMM4zfYYMeOWm8L1TNa6jD26qawpoSTZb9o(RdA9hQWMmslEhhXKaRNmYYe9viFihw7DnPSYzVElmXqtR53W3mTLqArGqIM953iWgwo58evDSRIISnYRPTXbQvoOC9GFWNCB4j8gi2aPP7Qe6prpw(eUeyySNQPdVJwKDxp(AEYInHZUjB55Q23SXA7ULyn1oAMC7UnMZ3j5hMj6j3OXp7Uz8Jj63Wc3OKFivHbMouF9oxBXn)kBc4gN3rI1xOvXT6TSfLUFZvlUvwMI(xzCgnL5EniZLNBS(sE8I9F(l6VTY8xFtLRGQW3ooct0x1e912WPhApo6t(B1AkHd0A3x(xzOky0zvrvEgkCbFLdp2Oj90wu1x6dLOk52IQoXB0A2PQE8E7WrROP)63gIpt0V96VnxfLat0)JBJHqV8YLVBZ)Kgc))MfqgeiRkq2Op)xqB6KYJ2tS2cKFJTca5tTsGCqIZoqDHZUxYD(wBWotvhqzvYnetuPpy7X0kYdK6GhH9vAGS6I(k0FO2cp(Y)lUhtTx2rsUYwk7Y)bCVD37Ql7IlzKjwMXl5tqRTYU3CRTS71xL0KP(iG8bAH4R)kRUm8cEoB(ZoUNWLnA)mD)v3Ald33CTugYrdx1hOfEWB2Qk8sEHah3V2uEt6(4Tv49FBRTW7vwfQZz)aTGRnkDP9oSqSE7lHCYOTvU9RTjk3iXPo4aJmEm82VsTnxwYMWIGHlY1TI28t5ACPcfiHUXquWvefnD(PeKzLW(BQkSSqXY2vwTt7OMMWfzlXBKrtwTGXvkuUOIMQOlYv7SHQt(MVA53JLjQ)9SHf)yVjhj(7FrqUI9790XBrOJZUX8vsDEVELg1Zm9gAQXwJl51lYsApt0NSwk7zI((Ql38(61NCC)4Vxd563AUA)PRRQf9xA9vTkvf5MOFNvqmK69lIH13cH9)LrmmBFxirUl0DIH0ptBjgm3ejg(4BaEd)OpxRJ7Z(AfxYDol)7BcZ10I0tEBBNqnq)ELhpFyLId5TTc1F)Tec1PH24v1S2A7pex3E92Vx8BX2JCTUAk8761Jx3KDnsAkh4keDVVPuMmcKDpwYAF)t8V4gOxt6HhOvYR0rV4e92JUyKZNTTYR)pBMwNRORYRnf9l5D)mzx19ZQLP3Q62TRANnCoz7Pfdt68qIvTtUaBtkRGcC5)Kdf0RhF9JF0k1Yui872vF4xTcBRK11qk5z8QFxRnOo6gYdDZ1QsTJbtU1KW0nUhRnRfA2eWwP25tZB9ppdn8TqbGGLODz22CZeGz4tDa8bxKSjcd1ys4)2asGHfzB6mCrpZGjRMyottbo2B2mS96AVWZRnqPhA9LQo3K(gg0EFsg)Di7VLemgtWgQ2yfOts2Zi1SE9byu9JoxaTaDWvxkRah7LzD7ZqD66lsFeds3pVFA83KJ8T(ldyz2J2E)2(y1YWOqS9bGG8AxE0OpvTZEQeuWhTA1LdKVlOYGO7ILFTDzTnED1zGxe3XoZ0zcd6jwDaPSzfK5IfESWC4fnrFrlnGVaD3CMKCD3bmxVdD9VdvqrwqpL1xAOxpEi5ZDFE7M(RF6V9Wb)0Rh6VExuvqJaOjsP55ZLtiJHqwnLzKhrUq5uuUSBs0FKKfIZkzQw4SPj6hEdjHT7Zkfe3YSlNe9UHjTWvv0hBGWLmI0ElF)bvZRNOBA7Yj(w1D5eyMq)znZXAI(ZHrK)I6js)gnULQsSX9BVg2Kmnr)L1ZjAI(RQB7iV6(963ce0))aIWZEaIa5V2skZDeY)UWSUf0vyuGdfoss2U8lz78ITffJx6oTv)Q1VddBI(BiBw2FnY2hmfj91rtBHK(Bnr))BpD6AhpzI(7QrCAI(7BGW0e9paaft0)i8O(EMO)PneErZTVnGo0C7K9QsZTVDZTd)UJ641(dxjVMO(fYCUUhuT3jgcqTMB)Em3(9AXLvB9hW)E2BP6vXGRmNC)RAS4EAS4T4BlIwPg5l7Qyxz7k71F0g2TcViUh83JM1OFfIUP1Ukizhf8BURT4)ldZUw52i4Sf67kY6NROuVNTfBJGDPZ57e(pH7UMEhx7F(
```
