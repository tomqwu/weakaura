# Hunter TBC — Beast Mastery & Survival (v12)

A single WeakAuras pack for TBC Anniversary (2.4.3) hunters that covers both raid specs:
Beast Mastery (41/20/0) and Survival (0/20/41). It is built from the rotation, not from a
list of trackers — every element maps to one line of the priority list, and anything that
does not change which button you press next was left out. Everything matches by **spell ID**
(never by name), so it works identically on a zhCN or any other localized client.

54 auras: one draggable top-level group `Hunter TBC - BM & Survival` anchored at screen
centre `(0, -140)`, holding six sub-groups you can drag independently (since v8 the
*Resources* group holds two further clusters, each draggable on its own). Built for
WeakAuras `internalVersion 45` / `tocversion 20501`; modern WA migrates it forward on
import.

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

**Resources** `(0, +180)` — since v12, two **ring clusters** in two draggable sub-groups,
flanking your character: **you** at an absolute `(-270, +40)` and **your target** at
`(+270, +110)`, one notch higher. The geometry is the repo-wide ring canon — outer arc 84,
inner arc 62, portrait 44, clusters at `±270` — and those numbers are identical in every class
pack here. It is drawn with one texture WeakAuras already ships (`Ring_20px`, a true annulus),
so nothing needs a media addon. Every region inside a cluster sits at `(0, 0)` in its cluster's
frame and the *group* carries the position, which is what makes the arcs concentric by
construction instead of by four hand-typed offsets that drift apart a version later.

*Player Cluster* `(-270, 0)`: **health** on the outer arc (green, bright red below 30%, `%` at
13pt just under the rings) and **mana** on the inner one (blue, red below 20% — the same
threshold that fires the Go-Viper prompt, so the arc and the alert agree — `%` at 10pt under
the health number), with your **live portrait** in the middle. Both arcs fade to 50% alpha out
of combat. The mana arc carries the two aspect-swap breakpoints as marks on its own
circumference: red at 20% (72° clockwise from the top) and green at 80% (288°), so the swap
band is visible before either alert fires. A dark track ring sits behind the mana arc.

*Target Cluster* `(+270, +70)` — the one cluster that sits higher than the other, and the only
place in the pack that knows it: **your threat on that target** on the outer arc with the
threat `%` printed above the rings, **target health** on the inner one (`%` on the same
baseline as yours), and the target's **live portrait** in the middle, so the cluster tells you
what you are shooting without a nameplate and without the pack ever knowing its class. The
whole cluster disappears when you have no target. The threat arc loads only in a party or raid,
never in an arena (v5 — there is no threat table there), and hides itself at zero threat; the
dark **track ring** at the same radius keeps that position occupied, so the cluster still reads
as two rings and a face when threat has nothing to say. Just outside it sits a red `ADD`-blend
halo that pulses at 80%+ threat, same gates, because solo threat is your pet's problem, not
yours.

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
| Threat rim / threat halo | party/raid **and** not in an arena (v5) | grouped PvE, and battlegrounds |
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
  **Coming from v7, v8, v9, v10 or v11, leave it checked** — it is the category that carries
  width, height and offsets for child auras, i.e. the thing that turned the old 172x14 bars
  into rings (v8), resized those rings to the shared orb geometry (v9), replaced them with the
  globes (v10), moved those globes up beside your character (v11), and turns them back into
  two arcs around a live portrait (v12, see above).

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
elements at the end of the build order — never reorder or delete existing ones. v2's five new
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

## Import string (v12)

```
!WA:2!L3xc4XX1995hwXkkijlsiskrQRvqI0a0su7bwCWkAR9celWEXzxCqisHz2DNDNHy2zgoZSayrd9bIIcIJpsGBTDDtCCqSvIsTtCrvDsvBuJrBtB)QB7ROTUts(sBcJtI8rRJyD693x77yMDNf7Ifhe0IubFFy2zEZBEZ8E))9)89FEdyIUY)fdS8tSroU8ZwqtrnSIKI2OUC5kTlpNjGAx5vKn0uKK4lewquQGgV8PvFOrQiBWR5(zDNwIRkANWsv0rf44ez50kXByFIRNtrRaVwiR7H6HcjjU4ICAfCNvrrYquvBHuflQZBaYPYHUfgQNWQLYgkmQ1cLW9PCNPI2CIZXjLJ2ycAvPxtK7Dvn(sIkYzRQYZustPI6Q0QKrCr(dSMOCrfTYCgOA05A0tq7KaaW1gCvmeu0sPIpTEN5qD3IIL6uJlpPG(z0n40m6mxrrzrDHodH(XOZLm0elvIxtp5P0S29ZeYaF35QOX5BD8wDvEjjXc6NOlpHQGUOCQKHQLiLhRGENxxVso(5q91mvkwuCH1MjCWmzNjt2GmzRDQ0A8OtXKjD04XVrfD(OlGEUYqBbwgzUY86DUAb(COwa351gjA80dpE8vqJD0hRoxRGO(vQiJ6nZX7Jtss9WCK9ZspFcLc8FL3J1Wv0cL4vpCMRwbrcCpCfjj3tkiAWVo9S0b77zfozr6Gz)WJm868C68zmqKSsgc3n84HKvK53OaQ)JRXm4XenDE0GAb9LWvf)uc9eQmNO8WWNdDbqpqVqFq)OFp6MlzfDEPIPveLnYfoAYSrz6wSGAx1Gym86kv0YZRFdrCjYCstGUzOB7lUwrn0qd6XIZGZ1n4KZJOWdJlcF7ZLjmt0Ojx1qj)C06FW0h1xfXcRjTWaXzU6etVqWzz0ZZjX7AveHGHGT0THoXKrJcUwf3LePyMqskCf6Cn6TH84c7F5NacQXeb7yu1JxNLrzE0VmIYLCNfbZM9g1oZi8CsgcBu74eCYCQp8M51sRGWCCIgWda)RaV7V)HGheoaStb49cG3h8(HV3daFGoHhIaUHhUtyxDcFqeLQt4r7eESoHpuYtbF4pdAu(eWhbbnHpk8XGpENWNa6g(KWUHpfl8P7eEs4PGVVoH9a7fE6VY7b((Hpd8zVh4zWe8nt06B7jJWaW(ruoOl4GViCixWZc)RcFE0yo8CRvPS6vhEUEZmr(Ra)GUGVqNWGUGH6egUtye0GOBuFZ1nm4xWOIg)KACQy4Q6rchpyI0ztfkEWWJfmsKyzJnru4d9sOo2xhDFFuCNHHW(WqgRX9XvuX7HHJau3DjeR0myMswsN(P7CdCb1QcR1aG1ifPbHXvpY4ORWDyboSWbEnrDdX862dGPSBQnp49aDYK3wAt67cHgcGOk5klQPPOrjAAwDqePALCs8YfW9sMqXJMmcm0joftEb(8Zom8HpWsZXPjYHQYsIYHvkNJZGbjoScpOBf1Up350YlWjxIx)eNconb3TKkswlUlXWjPkWTNjGQhgjejVgVb)mAkgeoBqdGQSQdeddslYLN)sbluiLS(LMKNB2Gy5GxkbFbrUlLL2j1Veg5pJppQlCgJsCuGafxybtIcVBa8YUqI105mWcs4fwQ(T9CRn08g8YYvMnXeJqGsiGsobEXscgxlhPE8cWWtScMIMxItxNnNbIvw24ymLRGu1Gih4spvoD0ZHeFUrghlzbw6yWRWgcjCo)XGL6mKosZbEhM5flyiCTLpBou7Pntva93faOhY14kCfS2Tcj4wOJ6hik3bMSIESups9(aw1hw1KCbH10XsIOdhSoRZWki9y06WOlXjBawcHgcIFmF5JHgKUoIEwcneQNHi370p67Pd8GgMjbZMJy25WJCWqN9uWjragxWP2ar)ZJ68cerlWP72VheyPRNh(IyuYOyyYqyuPxF0TUGx6gfR9yqutsBRdaNcEr40wqn6LtfUDj4LRD7wPm3c23QUW3PUFER6cW1d(cNy5hwTlmEFgDbUckZpLLA)viLH3OEOt2WZ8jpP6HCCb11CFDAP2QicfC8SPuFqsHiD6kyDu5Net9cfeDirkYmiLP8fif(r3GkV(I0hajxRtQaMgkwSkS)vPqjmzkuYujJcpUgsxa5bK(8tVC7N)vjLL322jx0(trKTtQhAynXfDFHkCfWQJCNnRQNAD2zOwMmtd94zkWNhPIvAgvn0oyfuGggZSEKbn8GuRFSbPW5r6QWcmxAsRD2O2deXqHuJNnESKrTgABq1LAVBZJhbAquTZuusrrJoYnh6jfjAIT(ncB91JSrJJtQNCBACAH5swPCoKK78V2EwOvU8iHFZufdR7ZRtPvQhcXch0IBLW8kOE4C1ypTymHZqenTkX8pcliajvbI0nuelxakCkOi8kuXgWzjfjr2s0d5qTroQw9TsprJvgEHTvFsgHn3beLfG33nSLnyPmzjfKXnidg07eooCcIfPm2crVUEzffdH0wxb7QeHndlQPBiSM11LxsuvGiFDu4yQhQ(4JfH8g1lHWs(wHwkVszvC7jGLIpmS6OerkbWBhKiEX3GUWY5l)AQhUUmM6J3NBn5(pp)ujJh7kQZRjkJToJxyfYdhwLyUyjZels01u0er4fsxzLWXtfESjJLjkLCVGf5(b6uJCz8few(SqKAdfSaBOAhWRAlCgI0(QZcruMka4Ce5RW53jIux3cWsmxajr1xJsuX92ayjJ(iBqcuHv3nIqxcjc1QP7YBlKGE2LFy4Fna8h7gN05ZXjpj8drn57dd)iWpkCj4p(hf(Ys3f8Na1zEf4pjcITm8Nca)yJsTbbVDGaUCb)PHFC4NcvVpjqTNTI1KChCW2d)mWFg4plCf4Ng(xh18Fww1NU9xkTm4Fl4N7OW)Ma1NR91UzXFlFKnSG1jSSBczSygK1tp4Qy5)il3isUSTuSoq3QGjSKnzzJ(mLXgyrUi7sqE8W5ly84WJVQLyE0LPEyRDIu3ue7M0c2QE2DUHpuhRMH4tfX2NY3)6wTgvRwZyN7o9b8nWzgWlm)9VU1tQvFfwqydNDxEbQSC0XHSTHeoXYhb(g1hSG)dqx3)qa83If(MW)rWFB43ablwh(pwa(pb(pf90a)Dige0Nl6w4DpvT7o8Fg5wc)Nla)xaNaM)A7DVb(5AwKm8Nxa(fSK4c)f2ncA)6oKDMGi7mjOrXNPz37sAH)IijRWvH)seHOWVea(LzHVQa8xUMKr4Vca(AVvi4VkrO35Xc9iKpCxKWKnuaQmVRb)BteXnyEVlQvE6rl07aWVQa8xd(Rd)AW)oW1Qj4c(3vyz)RHrOsX0hN4JcYrpFCQIcyryuHxAKZJnd9q19YSb382Kwi4xC)sb06Qw(FoTIszwKuZ1PplffL4Jva(yRspuLdjz9XO9Jz0rC7vbirPoog9SJC3l)f3ze76otVKo)vRWlNN3LdH0i3FF)HsQiZdVpgYTa(EFY63Rk6xanWw)yTfbACfMdXqHCvypJJru1GpKfHyra8zVxc8fddgXQ0Qo6VAl8TpeS8fj4MZTwPHNDXlowPXgC2jXQBupePEre1XbjkMCrfbIsNtSduC4yiDrN3VQGnfdIROE06rNtajVZW9WipHeQfQTAbTRESjuF0nFoQ1mwN9yT(S3yt3hhXWWQEngdJVD9yy8jUnpgg3vZXWi8OJkpHFJSJKQ)Tkgg3frub5X(3XMxJeYbd64tEd2vP7Iz4r(RIhKqDIRxVoejbRuR(DpOhuxg5bGDbZG90NZqrR7pW5GXvpKffoJOrfIUqYittHMaYmkbE4LUHO)bpGNXkCszXd9J7lyKi4EuRh8kcpEoSDFONy8XOt)dwLeVH0vK05xYowGD5LCjnpY(sBkwc26bAiOa)H0GcazfWgKDU14deKz4H8oUXfNYoiaW8FdSgQWVcsCYA4boekghlyws0EWo0lqLYOzDc0(NcE)SHqaXcSBLON5yuroauL1N6COwczUIr1YCYS(m4Lr0S5rgTuTO4C8S5O7Zc9Wcl)n2mvFZsI)oBtiJGmiDknrhqQG2sQWoacVJgO)J20aDO5lZfzYbtoYIZwFG(1id07e52LFT7ChkU(MgkMEIEgntIIfNCwM6dfxBNpuCT9QRi3vJUICIA(kaxCRdZcXjb41APBbUAYTG3sL4jWNaGCea5pGRgmW)VbYG)pll8Z9iiJ3HFEKz83wy(3UhmT7nO7pgw9T(Kny)2u9fuWFjF9F1HwCRTFB)HopAD683d5N5aec9hWIqtLB3prUTdFmTR8qnwzQLOeFWd0IlHHResIiCAxoTWOLbh0XfTgv3djc0BdmC9twtpvnhvvFMM8cSUYSMDbSbaCzB8R6t2MgPMxNn477abQpymWGuhGryEN49pv5weMQ6TBdoct8OfZDCteQQDepbwTg8)gl8hAPfd(xyP)c(FFRvEb)FWc)FYc)FXc)FZc))Wc))s0pTjwN3cX2Gyw(USyMN4W)lTYuHDpRZ32kaqua3G4n(Tc)JfRuVJLqTsWKJpMN0TXvi4)sIdqWVPd3FG)R2AhF29If(xJ9Ib(Vbvli6))Ty)uGBSh9ob(VZLdgzSBjW)9OHT)di)rGFlSxiW)JaO5nRxhWF3g834pb(7bG)(o9VOyI(hS)urJnQAiISL)aQ)eDc)pbG)Nbnn5K1TJpdVMkYog3zmqgj5WHb6o6UtWPnRJ5YmRaV7q8C6gUNu0qqu2HL(rxqvrN3noAiY866ul9bObN7HyO)V4T3g6F9A9JqvkwuVzR(fLYpxVjQ2ZilmARS6)PwvmVImDEAE03dURrrUBKxrrQGY8YzMxuLNDD7dXt9UqZ99xL23)vd5DObgKXR)a9neEBapKTEjB9r26NSTpY2am(c4Bi02b84TFnuRNswczzQfFWMg90gjitIHhpUZXWbFXBmlpVAq80HzWGnFxGaJqwc9cN9BTrjjL5hwJ6gEvkpEiCzcRJS0(8swtsJWk4YYqNhD8UXjjjWrxdVV9CyqQtTuoXf5C2ZvaDkxWLqUJzfeZtGsUwICis(7g5QyyOiNIgYAsBfxevLdtUFHOPjYYpirhu3NuTv2cbAWuOpg5POjDcRhlzYOmZekv2SPsa)CpgvKpYXNvqpG00cyd6pZOqF2TYzIzYxF6QSkXEEsSsNGz4ruE4ZyFe2nfxW8xyNj35(cHrzWdAcUp4D)n7adlt6pMsIsfuLge7Bh6VqlQOuMi9DjBWgRTKdtWbvpIDP44ugruhp)Yi3HqIlkFbtGFwmp5x1wGfMj54uN8S4N2ujhTPsW8momz968lOks9imRyzSHd(DA4al8s4aWEgVNbtbXchgY1YpLj496KjYe8aSMGdjSLYkgnKxV(r8i953NFY2(iBdSfSaMGhTr0Vj4XCc4nbpofLBcEcbtGB0)pPltq3h1e8uatWttgNnbNeHynbNYe8(qh0JjOxtWPpSj49VFGanbpJtCNj4znbNbDVFos7zc8Ggq8cFgtGVDb6brETWoy3BUG)qjZm7arhOWfSGoMaIUB)MG(DazUhtWa734Jo3Ru6tW4VV(gW7osZW7gORZHORKOcrsJSzLjCZu68SnrTxTELoy85AMQFrevVNfth)IPeMv6Qt1wQEN3wq1F16u9aE8AcEe2)YdlnM0R2fM2lRy0m9)6nwkMGVt48XyGcxKlDGcbkYn6GTfdCV3cXaEcH8aD(UhpnSJFph2DoMOKK7WkLlZjxWr2Lgmt6OHZ6orSmzIL88oSFnHICjfSDNHen4vFKALpmVyjz3rqEWj4oTMszvd1dx7KNxX9eiRX0CCFXPRJBdf3JWnVZGGNquVGiYNuS6RMBNe8YfCNM3q9bDKJIZjohpPW61lCy3Ps6oruhffjAWitNkzu1Ju3u8yXJMmCu3jtnPZaThK58rZ6owIeJNmkXOAmBZ3G4ve1oAgDvU883)nRH0RHmDPsz5m4gJK5EbYrT)HHtcnwc7xt3GdNcPepLc70jinAkII0aHT2)d6AjeL1QDiEe9mW7B9cvL5klMNeiwKBaH0v0mGEwPKMin)CU3LW7InYRBMimsILfnUxCGCJJ3t46iZEq3EzJH5YBOOLJjyKyJNjNgxbXk6V89HCayfoT8udoF5JzJGRpVebL41m0xTyfjPWIA5rMJzBEpY3pKH83T0nHhei2ckS(CRfskvIscXMDQZp6Ypnskhy7eY9Mi60RqfWt8DGobGhFL8K09tsP0Q1lhrdFcTzIemrWZhDDs6UPjAiIS3Mf(2DfagFvAoc6oUsj4tYWem55JsNVVxXeiYIL4CftWS4wXeizckBDzMa6KfStRktMjr8G0QV8HzmWZmuiCgyPEy8dvjEzEnX8zeuMpLm7gnC4A6KFy45kuLKLMe5xj5kZFWx(7cpod5qRSV84HTSt1TDER4UhsMq3lvOictQOXJZEfeUHNDdnEoPm2n36oLJSrn9N4trI6bg6tdoajVbj9bw1heVppoLRDwDmlsU8v0nqC)Dr)1kzQrd0I5v7VijDRvK7XOx3A8gv0KD3JXl69YUv0CB8I(S(1)L71n6HbTxFx2nsWX2ONYspKBeMPhM0IlWl1G2kRKSHeApSAlKAnwQknSMR3r1zzcEHT2eftqqmPUr1sfXjTozMqrS5QNUEgwGpw)sbZjkjAuDgk38mysRfLLAiRw)ZwzA1klinzS2QoBKTuDgQRb)bq)A4mwpvfdYCATMUecxLtb5Wzz4B7d1Aeg(wOOB5dTcj7XjEOQJNNZscge)GXJyF4CKtwLKJfq0J0RqlybAbVDxEHxgqqHKIz7QAH7PRfaRqMsnCtUKDtIVXBG2xwxcNPIOtPEy7ZL1Uy0t1gwqAAbSK2M0ASnQcEhjGYHvyFEgV(92FaSRvEhKSDiIBwuhV8s26JekI(XHIOV(qwT5zG(2aPAiVaVoveWguraifR48XDVyh)PBntIjyPM4qOjJM3aBjlYobt)k2yAkAMGSxLi(LiULTj8T)YBgFBc(Xvp1MH1eHvZKeNOr8ZWWnhV8WkALPq6GLMlp6WiAAxTziTqDiDSTdsJGBe0Sj4Ne(2MGL3AmSj4NYe8XiiwtWpDD0Qj4J7ePAc(e2qutWN0e8PWnLj4NXe8ZIAmtWkOHGp9EbO9RrTybP5bRLdBPx0io06ycuxQaVUbvrir9xzegcZfWsoY(KSlzxotKurSvbA3YMGvBqRNj4xc(yMGVe6b6lJ()vnb)Y2A2mbx1eOzc0rLBycQGXQMG5mUmUPMNQLYeSGjOkQclUrdwIAc(X2KEgtW1qv7drvNqgJ)iQNz70CyRXW)UvJXMygCMLx3HPTanC3cMPTthrM5flAKXqtCwEkdLNfspqapzdUG45BRoIrF3dd1l5m7tG)zSoM3NVx3dHtNe43NK8inmdqTd6FWJEWwI9xZH3wBdY)MwKEFbAVrp7eC3R2WCP5e8rNYTgHGVa6)FbIGDu3VfyXE2kSiJsPk8ZqgBidnuKywPXLxuA4leEY4Tfjo27UqI)P2ir1J2qY)ANgtD98WxVBFEStRtsoV3qAcZ22m90oqrMGFotWpVj4lCRZYccTcVzax772vGrAnzpXpXjAfS752grG0jZrPOHapjyhu0xIIl6n4K5Km8fRTgwe)DPOptWVowM3RJZNolOMj4RXUTzrSf26wlQA7urVVIQAPvQMGVifNKRNkXdFLY9KRuP2ItsChbobhW5dCtPVCG9K(Yx5R2s9LR7mSI3QvyUDrj4wPctu)Ftymk6QKNPUk)fZnr)JpEBrxjVJbDD3Bh6sUb01cD3NhAUQ4tLK5VyeaM6NILgfTgEj5yvpwJV0CouAwdf6OX7YQTnbF9gAAtWVb6)FZU(a7aS7l3At9wYoM33cHT7xIc3jUx8YhS1i0Wjg)cHNi9uPzMSTi0uVBv(32bIWZG)2JIkCUwIIwT(0KCRw83(siG2jijuxTLiPHUQCPisIJPPwTTiP03XGK2ztD7CeOKLTs2u34QhkSMY8fChU2QmdgCTJM52BAk97ar4OiwbzTm4ClMF2tXGxcC4izU5MapP9Rx9885k7P3iTf8CHBRbpF(65qS1QlezzHz6qzYoEYgsb5gjKWlDJ65gKJ1Maudzc(THtVb(6Njr0WJemzSWTTHmbR341gA4ObzAk9NhGM2QT6c2aFbT(MTnxPw4ujhE8mrB6A6ZkZKXZHAlFgzsLkBtxLTVNT6oznhYnpuy9AM2Yow6GHJn8f3lxQ6HYeEKuPIptm8AQbZ4PZUnx(U1VnhVUNRXGxStChgV4OGtcegn8XDnisedzgoihA7)21jhv)DKYPYksBsMJebfDdIpZSoEziBm3HxPwD0O7XFB2StmNtjmn5ONtPmMG3Srrm4Oi072fivd8C1MrqXGkqkFP(LvJoCu)X6PTcKyE3LDrosW8qH50n2QCmNAcvnlE2iinZrgNKLLyJAqg)C9miuKCE87CjECTvgaHnsc594BS)Oy0Md8wTEXJVZ1l(kuu72ovXOHGwJDPOXkvp)ixzYqZNKxPTOXmVlZ2kRis9X81FF(c51Jpp4n(cfiWqdXG2BGbz6lqF(hKXVxF(6Ze8b3IKMBNMUKV71YRTax1FKj6z4bME4QEt0wCv27iWvEmbNF1rsXeB6ujZgmoSJ3O2B0r4i4CFJhPyJtY9KiDLc1EJoiNcPDqSSybs6BxlB5iNbNdp4uVxVXlyYQZXRjB96KCSgUaovXcUhwuJVXYtGxKUEwSKWA57hP8GA55K5jIiB8w4m4znEjoMgQg7HdRXZVO1l5UAJTwM8Cg4diQ4StVUN5UCKFDMGXVNB2KRZembnN6WC1tH3CXMtJotW02zqNj4fRN7CMGlbFVhWeCziIs(s3RjyMUzIycyr7XHeHMZeK3euGKfCMa(6P)MJLor7CPs3euAZP(gyFjZ3gAQqtf13vsmVVPiM3T9cYEjNz1T3HcmqF0GnSfdLnhMHRttLe7(MDqxJpxRNG(gG5Btyh8XjxD)DIkf21g3fChMovnLP3FFC2PyToRYsfOvKxsBuVzReSYITDsh)Jqc0iV6yLdUVLXVNU2IAXQk1jwn(UNYcVeKTMVfHWewh1400AycgcTJaUQo8JyNPXSPiu9dQbxQ26y07u03nBqQ2JjD((heP6MHiMGBybn8CfpJj1BF5I5D62cnU(TaOrN7J0Xl)3RL0XvQPO6oDIiQdULeXEsO7zI(KsCHRY0wI4F8T5eXXEJwZm60SI70PJJ9gBnD03ikmQJwA0H6ptBPJF73XPJo1EhYVN(c0oZGAhnp7BUftrqn7f32KP7TVzNI0gDqEpPQE38c45GGp1W9n1cbmkNvR9sF)tULQy2e8dBRcztWFX(N64xQz0WQyf(bLMNRQUfQOVVCRrf19wOTOID9A)2(28R)JsWtVfJ5x7kXgXt1cTf88NEla8CwhGJTd88d30AzMn4PvR1zNUXfjtm(cv3BwaMj4)NfWksRf3SMd3nFNhz9NFGF33bGtz7ze)CYE56DUaTfo9N9xUGtT3ILTifFmbV(D62P0uY74aQuGxpHK3rlnYCTpjwFRBZT3ClsOztWx52yQ3EK9oyPHQeC2CmdX1(387VZT30SxFlE)lAigF3gt92Ht9XRF5whHAN2ooVSYydQxAC52huNV7T5mHXFUw70NZqZENpbf3n3okAHileoNUXIzNAH2sr)E3cPO4zlGHj25hjlSJt441t)cveZplHwOxlo5EVvfM8qXJoC2F0fP86R(tP1uY3QGK)hSVeK8Z3x(0HglINKJ03UzrWG4EuyjfzEDwBxU73Bap3KRck3PnVX7ovFDC)uEQac8JZm7vZn5feAhpvh1xSl2mpfzg9)W0jZdtuXZc3Ne(NtNXoYK15fdj)4w)(jyXia8BmCaYCX1coqNTiUIdIAZUQc6AH3ExnPEHIKAYKBAHEwtuEwEd34ZO2DTINe)6WRu0THaV7Hv005MLxMwN6R0erL5lx1UbCSKwG1N6oOwz(cowT3iVsj04X5ovfNvN2m4pLvTC1QajM4(33et4lBQ0)OtkX61Lsmx6wiJOW(ZAirHHJ4BKYtE1(L9Tdfs8HWz10sIg8LjlLcF6Vd9nDbjSiU6d3ILrHyOA2lnPET0eJgPjVeT2Tbsmd(1yTSJSMYSJh)GF63QElB2XtS5MWSd341oIoEYnDzX(c7Tl7xzxDzTosGS)OYmG9uch0XJsfszuW3fJnxA(k9ePTcPo6Tqf)p1(GPCp(l0st5upsReaT7TPJ92nB6q932rw9mCIX6FOY9kvQ9K1JDBbzfNX2X1S(EvEcM(85BiFWu01wDRszrQR8IFlnvpcz5lWnoz4CNPs(884pnr4jW)nFh3G8DeN4XiKSnrV6V4qE7lIY48JCX2sVEOBFOxMDCYZgYBFdrwko8swko86f)AA0X7drS6UFp4Q0lrR6DcRpA7uBbJDZ6iDnsUrf1HwCSb8xnyBj5pCnZdJ9oij)Bz2XdWAVMx63JF86CPVbW0EFd6HS(Vo4AidZWRdg4piqlXvSiFEd(c0vop0qW1XlAjIY8PPvI9o4LsV9FOYx63ARfnezO5cEL5sC1Pp)CTfNC8BH4epRQRYPnlz9s7OumtTLi7niNQ2xcl1d3WXKVouFe0dKWM(QKqFjOrDy1JqsIE(RwruJN8zuLS0QS1Vy02aeYcFSJVeIwP52s540Q)vUYxG6FgYWFHKyfwN88rx5FX2Up6XGhFn8xTo01nd6FlusUtI)OhFY9mszv6k5loCc1w62x(y0VvcF9DBR(B48dH2A0wMgPKpll830(ZDg8VpGKbApR9sem9d5LpuNQnO0JVNqPxNmkw)da2)v8Yipg0srk1xOLXcxWlO7AwdXiCPtkWuGviKrDXc8MDCt8H2WHeR1iT)iKVuRNdMLjSepNmIZGEFT)EQ5y1ZaBlbYFYqCAxA8ypB9JE2meOm5YQN8TDCcediGSaZ)2wRc6fkF(fV4KLnk1ZfqmDw3FXcf4LzsgDIOmWVMj4pSHVNgVEtFp)287SshppM571iFnFXV3nDvURcDvy5hVXp1sWbmb3h5vQ47B2X9JfAyT8NJx6Z)Mh828pYr3tZl35xy6PVy0WQlSOU)wSCN3LoJ)Ze4mE6AU76A))p
```
