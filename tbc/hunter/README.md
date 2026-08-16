# Hunter TBC — Beast Mastery & Survival (v13)

A single WeakAuras pack for TBC Anniversary (2.4.3) hunters that covers both raid specs:
Beast Mastery (41/20/0) and Survival (0/20/41). It is built from the rotation, not from a
list of trackers — every element maps to one line of the priority list, and anything that
does not change which button you press next was left out. Everything matches by **spell ID**
(never by name), so it works identically on a zhCN or any other localized client.

49 auras: one draggable top-level group `Hunter TBC - BM & Survival` anchored at screen
centre `(0, -140)`, holding six sub-groups you can drag independently (the *Resources* group
holds the ring cluster, draggable on its own). Built for WeakAuras `internalVersion 45` /
`tocversion 20501`; modern WA migrates it forward on import.

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

**Resources** `(0, +180)` — one **ring cluster** in one draggable sub-group, beside your
character at an absolute `(-270, +40)`. Since v13 there is no second cluster: the target side
is gone (see *v13* above). The geometry is the repo-wide ring canon — health 84, power 62,
portrait 44, cluster at `-270` — and those numbers are identical in every class pack here, with
this pack's threat ring wrapping them at 100. It is drawn with one texture WeakAuras already
ships (`Ring_20px`, a true annulus), so nothing needs a media addon. Every region inside the
cluster sits at `(0, 0)` in the cluster's frame and the *group* carries the position, which is
what makes the arcs concentric by construction instead of by five hand-typed offsets that drift
apart a version later.

*Player Cluster* `(-270, 0)`, from the outside in:

- **Threat — 100**, the outermost arc: your threat on your current target, green → orange at
  70% (press *Misdirection*) → red at 90% (press *Feign Death*) → deep red the moment you are
  pulling aggro, with the `%` at 10pt printed **above** the rings at `+58`. It loads only in a
  party or raid, never in an arena (v5 — there is no threat table there), and hides itself at
  zero threat, so solo you simply see two rings and a face. A red `ADD`-blend halo at the same
  100px diameter pulses on that arc at 80%+ threat, same gates.
- **Health — 84**: green, bright red below 30%, `%` at 13pt just under the arcs.
- **Mana — 62**: blue, red below 20% — the same threshold that fires the Go-Viper prompt, so
  the arc and the alert agree — `%` at 10pt under the health number. It carries the two
  aspect-swap breakpoints as marks on its own circumference: red at 20% (72° clockwise from the
  top) and green at 80% (288°), so the swap band is visible before either alert fires. A dark
  track ring sits behind it, so that position never reads as a hole when the arc hides.
- **Your live portrait — 44** in the middle.

The health and mana arcs (and the mana track) fade to 50% alpha out of combat. The threat ring
gets no track ring on purpose: it is already conditional in three ways, and a permanent dark
100px hoop would draw a third ring for every solo player purely to say nothing.

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

**PvP** `(150, 96)` — a downward dynamic stack of state readouts that exists only in an arena
or a battleground: trinket down, Will of the Forsaken down (Undead), enemy trinket countdowns,
trap armed, Viper Sting out, and (v5, arena only) one **Enemy Mana** bar per opponent who runs
on mana. Empty in PvE, and empty in PvP whenever nothing needs saying. Full description in
*v4 — PvP layer* and *v5* above.

**Procs** `(110, 24)` — a cloned 32x32 icon right of the bars for **Quick Shots**, the 12s
+15% ranged-haste proc from Improved Aspect of the Hawk. It pops in with a scale-and-pulse
and flies right on expiry. It is the smaller of the two haste windows the pack sees; the
bigger one (Rapid Fire) lives on its own icon in the cooldown row.

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
| Misdirection CD / prompt | `spellknown 34477` (+ combat, party/raid on the prompt) | level 70 |
| Go Viper prompt | `spellknown 34074` + in combat | level 64+ |
| Back to Hawk prompt | `spellknown 13165` + in combat | any hunter with Hawk |
| Aspect-missing alert | `spellknown 13165` + in combat | any hunter with Hawk |
| Mongoose Bite alert | `spellknown 1495` | any hunter |
| Feign Death prompt / CD | `spellknown 5384` + combat + party/raid / none | level 30+ |
| Mend Pet prompt | `spellknown 136` | any hunter with a pet |
| Revive Pet prompt | `spellknown 982` | any hunter with a pet |
| Threat ring / threat halo | party/raid **and** not in an arena (v5) | grouped PvE, and battlegrounds |
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
  an empty threat "%", and every ring pegged at some arbitrary fake fill. Judge the
  layout there, judge behaviour in combat.
- On a future re-import the Update dialog's **Arrangement** checkbox (checked by default)
  resets any positions you dragged in game back to the string's defaults. Uncheck it to keep
  your own placement, or tell me your coordinates and they get baked into the script.
  **Coming from v7, v8, v9, v10, v11 or v12, leave it checked** — it is the category that
  carries width, height and offsets for child auras, i.e. the thing that turned the old 172x14
  bars into rings (v8), resized those rings to the shared orb geometry (v9), replaced them with
  the globes (v10), moved those globes up beside your character (v11), turned them back into
  arcs around a live portrait (v12), and grew the threat ring to 100px around your own face
  (v13, see above).
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

## Import string (v13)

```
!WA:2!L33E0XX159PlaPmfOLnjejffLS0AktgazjYDxGfpyPK8(eyjWUy5SlEWxcZS7myNHy2zgoZSayXPYngMwHjN(eoXn1oonbnwn212TfrX1vNeNg0wx7EYFCp406mXjopqZdx3(hn8C6)2MV79o7UZcSybiiOePcphoyM7CV3zU3VFFpVFZDrt0zHFf)35fwpVqHzfn1nIQRQBEP2BV9mT7)CHm6SGUMTPUQQKyuzfvrtjTtz80dxwZwY03R4lJQqf4KOQLTGc2iVUPOKze3UY4iruvwCrbtrF501vTvmmxySzMXsYgL3qa6jBJt52t5Ief6TiP8DwFzlBoNYCcQ5zDMSzfwBID4vmLkQORLRIHexrt9YgRWQswLfLo4QkAZOBwsWgQrhRYUbBSGqO2xxOSTSU5ygKBB1rEyunJsXomfkqlOpolBbt7oYpJIMILChrG)y3Xs2MkflkzAL(SMUN(fIytE6cLnfcUg5OLHKQQIO1P60FKYqJYBqNrwIwEsrRo2WQCEP5GXA2YZmJYcRoD0WzZnD2CH5Yv7wzmLGBXLnt8rh9ULTKIVa8ELL1d8CAcLKS6yfrP8qpqg8MdhF0mjgF0LH5o2RvhRkQyDZYAWOzoPGcQQghvGEEo29tPlk91Fm3PR4IfLmoA2Bvgib(suwv13KYk2sRXUlBY(jwwqtHnz2h(PsSMKGLuwBGKv0w(dHpzenDnP1fHXpPgttMtmTKGjvrRLivL8wIpFKsckAjWNdAa(8y)4a4GWFp2Mlzzlj1zYOROzNpA805IZDAfrJoRbX4KS0lBwqY6UkKs0euNaEyWJ9ARoJjm1aVwc2cTFxbTcafobPiYJpF2OCXJNEfB9cZXQ)HYC8GLvexvDH(hL7wtC1fcplNvbbvP2xbieCuSLvvOtsnywO9vidjfgMjIQUGyhRYEm0xxCO78cyunEfCB304zQZzOpp8xofTI(YbWSzVBT7Kt2usW244BQaFjufSKRxTHLeuTLxV21Pe0emo5M58YOdqtbfB8bWhe)4)Vpc(dH7d)eY4oq4dJ)W4N8G4psh4pkLhaFKoWhTdCNabTd8X6aF8oWNi9zXp9xaigpd(uacg)S4Nd)X6a)84xa7d)XXNMh)IDG)e4ZGpBh4FkCx4U)6pg(LWFs8l)e4xHGl2mTTNDMAJ7fhciW42X9Fn8aTJheFb8FhG0GV4QLlzCReZ1D2jkCt8R1o(17a)PAhhUdCKoWrH5AFWyR97AlTGDztPjnfmiOAJJfD0WPYKBSiJgo6iHJflzUKtehFI3agyFl45(SKbdhLlJJssiJXLniNrqTiy4UeWXnnH3LNoOFXowNuqTQW7ob4otr7qCkJJno0cFrLfiYqKmvSSvkyvDcmt1UAZtEFKo4kuvOuMdaGMqavjFjfttDtgrZ0DacKQLZRkPjsgLCrgnE6y4WN6SCfKLkmBc8tFWLMtWuraQYskAr1lLxWMdKAwwcDADJt)QVQzbzbTIswN6S4RrHNlzaIKjdjobvdzH9mb04OGSMcMs2stBQBtfaGAaunUr)jjG0zekiD9WIIJPzD9jLeMnmrC51tjjQiC9CSbP11jmith0VXcNZUOadiWWfUWKy4hhHFJ2bPFwc2e5nsYlv)XEXvhCEBjnTYZMAIHPqjaOKxwsPOS9BMNwpjzCKjwMqrla8xw85TboEn7tWvQmOrcihKspBEl49qvk)WJteaHLpbEw(iGm8cNadAdSafmKt4Mxr0w(nVZfYd9N50vqS)UacEjxvq8MeLGIPewOT6xOO1gHScVwghR(yGOHKObttuEvlIal20bV36Kqhu3XQdNLQGMnAjaneM8AE7tatsBa0ZIWuOvwQ4Xx65ES2itAeMecBoWSNNmZHdFPZINcamTJVYY2mrpfSXx7097NauETxfFDce5suzy9roeOD8nU7m1E6uLO16cCfOPd2ytja5bdrogmu1oaVyTMWjue6j81ANbmR2iOIdsAtGGSJn2OvzVQuen(ADsFGx0TTiOMVb(1p1DoPrNeULPTKfe1NFkxBlwMwg5WANP2a(mNX4iEQBDldmE5AvFAMbetxRrtlkva0cQoTHjCcrhcAdwNuvJvKWJNBmJNIwiyIHorLzHjjOKiHHlVlRBvwqsKw4NzDM6JRWEvlVg9(eOIYmvWHwHHyjOHiPhlDCJpElE3yfKpD5s5bPAN0e0HrQO7uc75uDkzfAzmjpKz7(dvNM1)aTVS7tami7ijmvw03Lllis0Q6lxUgMIDFVrRtlBEqtjro8st6EY616hQzkJnEUrtcJIJ45nYvXzdVLvNnmotlgUuSi1sdUzu11nR)SiM)D81BCaZMyNdOzGasES43FplUlFbqS50viZu9gWRCoJJam)HD5ZPS9YghnFngBxwAmpvO2ku7lPmViCK3cpd)QersGqhIDS8uvqePmY4IebnMU3ao)S4pmFeqdVipw5S4BINLjCcRsQhUeCCooWyA7k8bnMd6jyIZUsjbn(GGGr(vSNhe2vzgWuqqYh9CE855RR4NQoBf20mrJgiE0SOKnO6AdY7u9BWt0RLY4iUgRKvXUmvimvr3M0YLtEZtokAY4dF3QsSCvXTKoyzgygJvh4jWtsnNMRQO9nSkPRBlNXTf8RqfbMqX0YwEv32vqvXqMk1Fe8OghP(CVli4U1lHYV)JJSub9sgK(tMOBjoEXlvxQ1aKd90or3J2334O1fawNsEXv7EKugLdNE8r8NbOredlLKxM(QrutNpz6SjJfFvDtfyMMoqwo6OJfDKjtMnodiTGlq6J0HjTzsIYmdBiJbgz57wLSSEDkaWbWJ)64VbXKIVjpUYPhWpqpaUOA8heD7c26MeXYPW)RBgzbSemltoFa2b4vzaIbiabJzW44enhteemJIy3vZzzMbFY8K5qaKqUgU93DfQffzkRAjTuvNc6maTjB1(VP3K1cUCinQ2pbtTpwqMOf7IRkfkmxIbdmU9vMQQAEctnr5oHzcVcp(FHlVd(xZLRb)v2Ewg8BZJ)xYJ)15XFvE8xJh)VIYvO99VZfW6iSbrHo(wTHnRQ8gBjJbkqzz8Ci88u9V4f2EvUxOMES1bYsbamitTMh0D2drvwNxCxOf8GG22RcA78Q2K5ObO(RUo9sGGh3oF7utIFte(tBCKZ0W7Yzod(NM5xWs4pl(24ph(T(m4Fg12X3bgr)S4FoGO9pa)peH)hrCWPD8)y8)ed)Br(Cd9ytuxIxgH)fH(8ZJ)5X)c4Va(Fki6V7DOxQlPh)fXFzE8x6zX)sOMOBOXwXke)3hl(v37(M8lVvX84)5Y4FLQy0Fvq49ee8gdPTnORoyUF4XBH8mN52o3dASYyUD0ncGF9Fdiqf)VfVkv2j(3aHFhE8VPm(BvtGi(Fhc)T)XrW)7PY6gYvwxaQo)bOOTGdWK29vXVlv4MwFdjnv6rtEtJ5X)wY4FB83b)7G)pG)DRjYcVM8(odYAUKrQ)wa)rWg5pOIOiO(G0d3ZShlbShUDDNbAc3XfC5oU7z8(ESn8ghyR8gmN4y2uX4sa8(bayVrxBhGL(eAeL7H9aq8gFIw30Aq9V0XjCgNV11ERmL35yR7QboLRJNG32evap1kedBbxFP2Ov1v766KDlycxZQCJfY0LiEOsBu1seaTsbdp6O4tUIRzPqZmoQ7jXQ7lx1U0vhRXf29EoYcG100yxrDEu7jxZT3IwZq3gXopEMdgS)Z1FaS4tUM7BQ7yf0KSU3HRKmZQv46ivDchp5Dog2P(Kf(paA3peH)d5X)r4Fe(pg)NaWI)u8FMmEd8)d4Tb)NtfV3B7SJ4hFQApD8Fb9rI)lLX)va3R4B(qIiRVLhPqPPsHgd1OGOlZ)ENmRHjYSOKpYq01LfMiR30vK1afcSOzPREjXU7F7fz1ZQeeQAslMDShaFWGcgkYerymHxM07t8J)JwpAEneNSnjphJ3VeLVMHBa8UQUEjEqQ5AS3LzuuLskIFUvyxAiaApEo24yAlGBVcceL65A4D)17alELDhXUEqlxYs6wLL0ki1UhH0pHm(LIKwxtcFyo6Ja)KF86pRYwxgMyRFT5IitbX5agkarVNXXav9t90UeIfr4x(Wu4lbgK0T0kEgVMl8NFeS2vO4MlUAXeZU4vgP4idm7Ke1nghHwVykwKGXNuBgDzQsNtTluC4zkDrVpVkOnfR3lzCIAXInRKPbiV1xwBWVnpb2LDILVucMZ6j0W5KL8frsWY23Kk2YkAEIQBCqzLLKpIqpnWnfwuDraP5q0G6(R(WDqD3O24iszWfSTgHxf1cZ1DQkDn8cxQzr49fxrPGUglEwp3JrgAm(Z1lORRkQpVw25vmK4xR6LKvYqERJ93Mn2)Arcmy)dWfONq9oi5yi)0JbOhdsp2d9yV0JH4cgk4GWX(9hOptO3httfCw(zbNU26SN5WH5sLy8r9oh2)1U7SssgHjHn0MJOYuMA8d4dZRFHFW6fv1NpHjJBRcZTZiKYKxdCZBiv3ysjVmPSSSLLGC6O01C54RsoVA4xO1P2c11o9EvJ8blsqKsOpXCYkfOqP2xIEjyVX65lBBRRngZjAAFnQcuLJsFEryR62DEkQzrN(mgnZsiudgcv3dbI5(1SLzTKPthNB6iJLl3yPWFPpgyRcyCd4(4YWliBvwwN9NP1DJAJ7L1crE7UROyTi54U6mtlbuE8NS6vKiN0ow8Y7oHFhocbLH)qoO2Wp(VxBeyz6EsQNQOOH6aepKH)fzrqCmnGalvfSXxtG0)pJJvTqI1iGCgsy4f5jcz0USdQBEcl5VvvHHeEKtY8u2LDAtLCSTucHLPQ4kWi2nKwWqH5wDoLsK4H2Jxtz5X3GyM15cCocbKiByG2VZl6GoGxEih0b5DqpU82kQ4srceOhGfP3Ec2d9yV0JH2goahuNnc(DqpLx8Ud6ymqUd64YoOta))PB3bDYJ7GEgKd6u0Pzh0Zcawh0Z5G(yWfpVd6fCq(oQd6JVFaaDqN2lSZbbZjFc4zFgA)5GolmH8tH)KoOUUhapa51f6qIlXL7js6SZ2F8(H2N1Di9jP4gh0lxhX8)3b9k73WJo2Re6tX1tV9cMHUB0l8bbY6CazLgmt6AYpRgLxMrMv3cXEL6v6qJo3wj6xbi6DTyMrVYyYZQERPAbr3b9ypuq1F76u9q(d4Gok)F7HJMq6n6Kq710T3k9FJglLqW3nm(emG4veYesm0mcxAGwIbqpaXa(JueSt50JNb32p0JvNJOOQ6lQEPscAIEsvNWzZepAoFPsMnBY0d5X61u6Af1jwDgb8K24zRvEcjLIA(IjbUE4lJPEjdBJJw7MdP7BcWwmtppxYIA6Zw33WcZpRXZvV7vSevmLOjAZw7NuGZ1(YizB8uEs4J5uMtIwy96fnQVXs7lvCpfflE4yxLSkzhRUH4jhnE6OX9LESj9maZfMBO458LmvQXthNAsnHT53Lg2kMv0CwgcfKEY7xZOxfmCPCjTSKoJMFd9MNz9dNGkmxcoAAzlqYhhQZAr86hMjlFBK4P26)ATVeqzD7hI3yG55hEnXkAcLukqxziWjGiwGRJ4ZVCrtf2QlE4LiNsmX70CX4uvkPyFyYklnk5m5naJEGhVMDcHc26M55chl54zZdUUPu262FyW8)LfmlWm382NOkcUE(OewvY02ALzkRQgvXSazz1CnUppIyg)JREF4)aWwWG1xC1iQJLQOCYzNAOlDhqM0bq7KqUVdqNElMaEQNdmV8p5YfOjfHQEXvQxoqdFEZPJfov4HIVgnPamvSvaRT5XFVodHtTcltk8nQErSpoUWPhkoZP(3YbnnprId8ciq6fhuEhub3M5GePGIDBv5YojWdYQ(DokNnjbHIqw)yJJsEPkkPjzQuiRS(8JPXVEdxUQf9pCscIvO5Ycv(vAHssh62)e8j5Ox6MJkptuxZu9vDD081fnTY6MjueWK6MsKvtdWns8RBkjOMTA3TMx5iRxt)j5w01cKa9zH0GMDf0XaVXtroxIK)AERoHfjFHYw2a3FNS)6MzAWeTsbJ(MHM7A6ADz3Tptj7YMA(6Y(AbUHpDtF2xlO7F75gD7dEzGZ69g(abh7GEkx9qNaOdppxgLfKuBqBLBGWPjSarTfOwJNPsJO569vDwoO(2EtuCq9ti1nQw66KmaKgUdGn34LQhgvY1wxpCEfvf7ktZ4MNMqADPSm7yn7B2Yx1O8cQtMSLQZETTvDgm0WFxCqts6)nwzB66cUQLkGRYRdUBwc)9cc9gLHVjk6UZrwMMkEu)tTibeROSn1lyYmw580BwHgivCqh0FxwblWk471za8BGOOqAX8Dwr8j6Cb0Y0LLK0LlvTljp41HZ1SujjAbClJJw9E5Qwm8wTUlKMvapTVP9gFJQG3vcO8yf2xKlqpb6leXZQadqpoi1llMFxbOhdsderFKar0BVGvB(7V31bvdfKLSyIawNjcauSsYAP9ID8VuZzsCqlSfoe2cgfi02YISBW0Vvvmndntr2Rqf)sf3YVf8DpL2m(2bvX4SBgwtfwnDAYQjinnNWCsAj0nlXG0Hloxb4YyMM3ARqA56q6xFNG0aCJIMDqVj(75G(0Bpg2b93Zb9ttrSoOptD0QdAjVivh0NTke1bDBh0NJ0voiqVXpd0zoO7atb)S7fG23KzXcO5HOLJyPx8yE064GMzjrjlBMIqQ6VsagIWfWtVQ6n5xQA5CXglwvvGv7zh0VydA9Cq)ZWac6lcVqFj4))soOVCvnBoOIoiWpbfO8B6GMLGvDqQ23G0vLyAPCqAoiDOcgR3GLOoiZnPNXbzbvZMPoHohpNX52jnhv1y0Z9QgJnXm4DPCEetBbmD3eMPDshr25vMXoRTPYSsmgk)lKP)q(ZfEbLHAPoIp1hCyOEdVPJd()yJPGZGKuWb)FARjCtRG(h64hQPy)v94T1oG8VVfP3BOwB0ZUb392nKMnEbFSSXPriyFW))fOc2HHFtWIDTDyro9ILLMMo3qNAyiXCQJRTOAIlhDYrBjsm8hSqI)LvrIghVHv4VAQF15fXRF6G(RU2T0CWRHCbGVLlNB1af5Gw2b95Dq)8p4SSGsRih6V99D7kiiTTypXN7und2D(DqeiBPC0NXwwIgSdg6l1mlgi8K5vTdMSLgwe5dOOph0xHiZBDsoi6c1CqVn)oMQaUyRhSOQDsf9(kQQPwP6G(cmCs(UkpA0BwQR8fl2sCs0hjWjKaoFW7l9L9VN0x(wFJMQVCnVHv8bTcZDkkbpivycJ)nHXyORI(N6wsxj)e9n(4TeDf7rg01hANqxAnGU(VE6E9ZYeNGg0ewNGaiu)m8SOO1q(HYBCIgZxupknRHc905D623oOVEdDTd6Ba))B25RTlWU3U5M6Tu1yE)ae2UFjkC34EXTpuZrOrtn(LJorMPYWnzlrOX)GQ8VDcerwa)Dgfj(QnffTs9Lj5bT4V9LqaTBqsWqTPiPbVLwXyQkJyAuPLiPepYGK2DlD7CuOKRTsvPUPmosut95f9fT2xMpbCTRw527Bk97dr4ygIcYAFChBZ6ZEwoY(jGa9J6ytGNm9yvziP8L83DSwcEg6HAWZxS(xgP7oYa9BS)ArYMB80n8Hv2iHeFJ7wp1GA8t50b9TWxBDs7Nov8OdhoDYOTSJCqF7gBBKeXdZTLpQZ(zFhvnRbRtAqZFy7qlnJow6eJNn(wAtVUFiJK1qTPVJCJnwUT0QQ(E2SNK7AiV1Pc3CjVPdSmHJMmXv2ln14izJo8yJn60jjF5XCJNj3o087v)28Kt3RYr(KW9fL8jKtsceotY1DoaiIHUch0lR6)2g0RQ)DL5vzfTpPRrISULn1NzEpz883ObhbxUwDmzNj9q2QtmNxjmBXrpVszCqVtJIyirrO7DkqQ2K1QnRSUntGuHI9Pzepr8Es2vlfin8hSSlYtAXhjQGL9wWjnyhEnlEwpmlZrgNMKLeJAaJF2ilGI0kq2CniZRnZaiIrsG3JV7(JIXQCGpO1l(m7E9IVfd1UJlvmmf0CSldnwUYqdFZjJmFAj9wIgt(bmBRCJi1pxW(6nyKa(d6NCiyKqHgCqo4S(hGR3q92ZaC9eiyWEDqBxAWUBtxYp4A512GR6l2eDLO)RMOsGuTexDPhjWv(DqV6kdpgxYRow6CHhf327w775iAmsUVjbk2eu9njORuU23Zb9wG2bLskI0S3Uw2YrVdjhEijEVvJnyYkZjzQ5(XKCIgAGGHIOVekMsnwEkYwzYRqKewlF)OLh2SGGMevezJpcVbpRXM4zzOACeMWusAr3DZiJg7TSfeSjxqvXvn96E5d4j)6CqJ8e3VjxNdAuwo1r4Qttom2wtJohuMQzqNd6Y1ZDoheh(jpOdkl(8oOCWLJFAUyoOjGZMeeHoLdcSg7Q0SGZbDT6P)MN9HQQ5sLLd6gBo13q7lz(2GtfzQ4bVzQ5dof18UDwq2B4nRUdmyO(7LfSHTzQCRHzydwQKuDSvnORJoxZxG(gG57qyhckOvz)DHkLVNnUl8UmDQ2sMEVbj7uC3064zc0Mrs18sbYvoC5fB5Io(7dc0OFVzAH33Y43xQ2xU2k61jwnUJ6WJVbwOMVfriewp14Ly1WbDE4ezsv94hXUtJ5wIq1Frn4sLMhJEVI(UFds1EmPZ3)Giv2meXb9JDHg(VP)ru7U38jdC1wcnCEaan6yFKoEJFZMshxUMIQh1jIWaCBjIDLYY)e9QM6Y3IRLeX)GhYjIJ8UnNz0RzfpQthh5D3E6yWH15mUuXlnyFzBjD8h((oD0R27i94V3qTYmOwrZZ9D2MLiOM9I7yY09xD)UePn6G8Esv99Y3FNhc(uj6DQfczxkNzRL((h(avXSd6N0sfYoO)x7FQJFJTIgwHOWpS68cvSCrf9(vAoQOU3cTevCpVbpSVT(6VxcE6EMK9yEZKd7VIylbp)rpaapxWd4yNap)KnTHfuf80Sn0GxQXDchc(cQ79laZb9)1fyfR5IBw1J7MV)JS()CWyVpaNY11W9iOfqO75c1s40p6VDbNATflBtk(4G(ApQBNYwsEhpqfrjRuQbUuXHNR1jX6F8d52BUnj0SdALhIPE7r27WfhSC4zZZnOqR)YV)tE4MM9oBZ3FrdX47HyQ3UCPpENB08iu712X510hzaRIJR16G68N(qot4ONV5o95n0Sp6tqjdZDIIkgBHO5TSxm3ul0sk6F2dqkkz1c44so0W5WTDkpFE6xUSsHzP0cRAXjpWdQWKhz04jY9ExKYRV3pLXuVqZcs(pAFji5d1BHmrgjM)0d379YMGb19OOQ6Asw8vD5UVaH8FFUlO8O26gFVP6RT2z8uHKLgNB2BLFYll3kEQ2QVzxSzEk6k6xMTyEeIkzv4Un()cBf7OlwxacKCj3)(z5jiaYxmCi6AX1eoqV9iPIda9zNvqDUWF990I6fj2ytMM8l3HNFoomv0MvY2h5ogNUwXts(C41NXNTSKVe6MwcZkPXQt9DAI4AsLQuTd8SLwq0N6lSzjjrp71B0pPew848nwzVvN1nKFWpA6UvbiM4j33etem3yzEVtkXA1LsmxMMiJqC)zpKqmrSGdxAYB1NwWDPqIpnjRMwsXwQeDRu4Z))K9LUOWJtzCYMSnkKeQz3SK61vtmmtt)iAR2hGygYNXAjpznLtBh7qF(FC9E2PTJV5UWPTtq27iA7P3uZs(lV3A2V(9uZAEKa5FVYmG9uch0wNmHu2IbVsY5YivURyTui1HFaQ4)f3hmL75)un1uoJJ1mbq3720X)WMnDW4TvKv)jsnsFdwQB1ITMS(HFOGSsYy7uMU)4FDkUEdgCWG4mSFShClLhuxfG8vAACm62xGpsYW5lB5cfKi)ujqwa)359DdY3vCINGsY2e9QVzgmqVX0hxA4R0s61t(Wd9YPTN9crc07G0TIJa0TIJabiFMgT9XaI1P7ZpPkVavR6Jc7pA7wBbtE)6iDnsUDzJbxCK(7Ps4wsY)i1mpm57JK8FGtBhKV6wEzp(7HSnxgSFcTp4a(P7(RdSkyygzFWGSRFVKWmZivWwsKTZ5btbBq20su0KYWQe)JWBLE7)qLFTF7Tx0qSbNl8nNl1TU6qZ1sCYh9bioX)kwgcMZs3V0oodZuBBaFD6TQTD3BC0gUMUfW)zHxi5n9Z0c7JGggWghJMe9s3QSIPe9hBo6wRY2)HrxfGq32JD31BPelwAUTuEbZ6BL9bdv)3AaY2GUG8A03p2((7vaB3V0jWNCvYVIoq7Mg(Vlkj)zi)csEM9mszf2(4ljCcSFXbaeZDobTRX)3Ux71)7E)1oyvwpZIuYxMh)dQ(BAa(3hrZaTxS6gemB36pimOAbk9z2tO0nOZI13L))pt2(8jGwgsP(2Smr4czhS30DkgWLEPatHwMsgTueLCA7X27(X4rI1Q0(Fy6VNDVkECUOQscAaNb75w9hnbp7EgeBja)jJiyE9Xt(k1V6vYsHY0Mvp5BB7iadiIUH6)x7UvQlwAOfVYKLSl21LbMo3NVIOOKgx64teNd)74G(bE3BIXRVLF0o283SsBbjmFFB6V5HKV7Mol1PyNI355B83otCFoO2OFsfB40w7eHgUB(5Kn(8FVd9q(pNLhARB25x(Qx9kXJASWIw90Kn78oT465CHoN)oN7aV5FZd
```
