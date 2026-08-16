# Paladin — TBC WeakAuras (All Specs v15)

One import string covering all three specs. Elements load through Spell Known gates, so
the HUD adapts to your talents with no action from you.
Toolkit setup, once: `cd ../../tools/tbc-weakaura-creator/scripts && ./setup.sh`.

## All Specs — v15 (`all-specs.txt`, seed 20260811)

The full Holy / Protection / Retribution HUD: 45 auras in one import, arranged as a top-level
group at (0, -140) with five draggable sub-groups — the fifth being the PvP column added in v5,
which only ever loads inside an arena or a battleground. Every trigger matches by spell ID
(never by name), so it works unchanged on a zhCN client. `internalVersion` stays 45 /
`tocversion` 20501; modern WeakAuras migrates that forward on import.

## v15 — your health number moves into the middle of the cluster

**What changed:** the **health percentage now prints in the centre of the cluster, on your
portrait**, at 16pt instead of 13pt. Through v14 it hung 54px *below* the rings and the mana
number 70px below that — two small glyphs floating on open screen with nothing behind them but
whatever the game world happened to be showing. Against a snow field, a lit floor or a
Netherstorm skybox they were unreadable, which is the complaint this version exists to fix.
Mana takes the slot health has vacated, just under the health ring, and grows to 12pt now that
it is the only number down there. Threat does not move.

```
              64%    <- threat %, above the outermost ring (unchanged)
        ,-----------.
      /   ,-------.  \   <- THREAT  (outermost, 100px)  — party/raid only
     |   /  ,---.  \  |  <- health  (84px)
     |  |  | 74% |  | |  <- your face (44px) with your HEALTH % on it, 16pt
     |   \  `---'  /  |  <- mana    (62px)
      \   `-------'  /
        `-----------'          your character
              41%    <- mana %, 12pt, in the slot health used to occupy
        you, (-270, 40)
```

| Number | v14 | v15 |
|---|---|---|
| **Health** `%percenthealth%` | 13pt, `y −54` (below the rings) | **16pt, `y 0` — dead centre, over your portrait** |
| **Mana** `%percentpower%` | 10pt, `y −70` | **12pt, `y −54`** — the slot health vacated |
| **Threat** `%threatpct%` | 10pt, `y +58` | unchanged |

### Why this needed the draw order changed too

Moving the offset on its own would have done **nothing visible**. Children of a WeakAuras group
draw in `controlledChildren` order and later children draw on top; through v14 the portrait was
adopted **last**, on purpose — "so nothing draws over it". That also meant the 44px portrait
covered anything a ring's text put in the middle. The number would have been in the string and
invisible on screen.

So the portrait becomes the **first** child of the cluster, and the rings draw over it:

```
v14   Threat  ->  Health  ->  Mana  ->  Threat Flash  ->  Player Portrait
v15   Player Portrait  ->  Threat  ->  Health  ->  Mana  ->  Threat Flash
```

**Your face is not covered by this**, and that is a fact about the texture rather than a matter
of taste. `Ring_20px.tga` is a **true annulus** — its art occupies only its own band — and the
stroke is 20/256 of the drawn size, so at this pack's diameters the bands sit at **42.19…50.00**
(threat and the flare), **35.44…42.00** (health) and **26.16…31.00** (mana) from the centre,
while the portrait is **0…22**. Nothing overlaps. The only ring-owned pixels that now reach the
middle of the cluster are the sub-texts, which is the entire point.

This also settles a v13 note that was half right (*"the portrait is back, so the numbers are
outside the rings again"*). A `model` region genuinely cannot carry text — that limit is real
and unchanged. But it is a limit on which region *owns* the text, not on where the text may
*land*: the health percentage is a sub-text of the **health ring**, a `progresstexture`, which
always could carry one. Anchored at its own ring's centre, it lands on the face.

### What did not change

**Nothing else at all.** No aura was added or removed — still 45 — and every UID is
byte-identical to v14 (`changed = 0`, `missing = 0`), so this re-imports as a clean **Update**
with no leftovers to delete. Not one trigger, load gate, condition, colour, spell ID, ring
diameter or position changed anywhere in the pack; the exhaustive field diff against v14 is
**nine fields**: two offsets, two font sizes and the five-entry child order. The text tokens,
their colours, the `OUTLINE` font and the shadows are untouched — mana keeps its blue tint,
which is now what identifies it, since it no longer sits beneath a white sibling. The Swing
Timer clearance is unaffected: the mana number rising from `y −30` to `y −14` moves it *away*
from the runway at `y −71.5`.

## v14 — one cluster, and threat is your own outermost ring

*Historical. The percentage positions this version describes were changed in v15 — the health
number is in the middle of the cluster now; see above. Everything else below still ships.*

**What changed:** the **target cluster is deleted**. Its health ring, its live portrait and the
group that held them are gone — three auras removed, 48 down to 45. **Threat did not go with
it**: it moved onto *your* cluster as a new **100px outermost arc** around the health and mana
rings you already had.

Everything else is untouched. Not one trigger, load gate, condition, colour, spell ID, size or
position outside the cluster changed — buffs, alerts, cooldown row, procs and the whole PvP
layer are byte-identical to v13, and all 44 surviving auras keep their exact UIDs.

```
              64%    <- threat %, above the outermost ring
        ,-----------.
      /   ,-------.  \   <- THREAT  (outermost, 100px)  — party/raid only
     |   /  ,---.  \  |  <- health  (84px)
     |  |  |  @  |  | |  <- your face (44px)
     |   \  `---'  /  |  <- mana    (62px)
      \   `-------'  /
        `-----------'          your character
              74%    <- health %
              41%    <- mana %
        you, (-270, 40)
```

| Ring | Size | Reads | Escalates to |
|---|---|---|---|
| **Threat** (outermost) | 100px | your % of the pull threshold on your target | orange at **70%**, red once you **hold aggro** |
| **Health** | 84px | your health | hot red under **30%** |
| **Mana** | 62px | your mana — the paladin resource in all three specs | red under **20%** |
| **Portrait** | 44px | your live 3D model | — |

### Why the target cluster went

Your target's health is already on the target frame *and* on its nameplate. For the entire
game, a third copy of it parked at (+270, 110) changed nothing about the next button you press
— it duplicated the very frame you were looking at when you selected the target. A HUD element
earns its place by changing a decision; that one never did, so it is removed rather than shrunk
or moved.

### Why threat moved instead of dying

Threat is the one thing that cluster showed which **nothing else in the game shows**, and a dps
who pulls aggro dies — losing it would have been a real regression. So it comes home as the
outermost ring of your own cluster, which is also the more honest reading: it is *your* threat,
and the target only names the table it is measured against.

It keeps everything it had: the Threat Situation trigger, the party-or-raid gate, the
never-in-an-arena gate (v6), the green → orange at 70% → red on aggro escalation, and the
zero-threat guard without which a ring with a zero total draws as a **full** circle — i.e. as
total aggro at the exact moment you have none. The Retribution-only **Threat Flash** resized
84 → 100 with it, so the 80%+ pulse happens *on* the threat ring instead of orbiting a radius
nothing occupies any more; it is still Ret-only, so a tank sitting at 100% is never alarmed.

Because of those two load gates, **solo and in the open world the cluster is still just two
rings and a face**. The third arc only appears when threat is a real relationship.

Health (84), mana (62) and the portrait (44) do not move by one pixel, and the cluster stays at
its absolute **(-270, 40)**. The threat percentage moved out with its ring, from `+54` to `+58`,
so it clears the larger radius. The wider cluster now spans `x −320…−220`, still **50px clear**
of the Alerts column at `x −170…−130` — and because that column is a dynamic group that only
grows *upward*, the gap holds at any stack depth, not just while one alert is showing.

### After updating: one group to delete by hand

**WeakAuras never deletes an aura that an import does not mention.** Everything this pack has
ever done before was a transform in place, so previous versions could promise there was nothing
to clean up. v14 genuinely removes regions, so after you import it there will be **one leftover
group** sitting in your WeakAuras:

> **`Paladin - Target Rings`** — right-click it in `/wa` and choose **Delete**. Deleting the
> group deletes the two auras still inside it, `Paladin - Target Health` and
> `Paladin - Target Portrait`.

Nothing else is left behind, and nothing breaks if you leave it — it simply keeps drawing the
old target cluster at (+270, 110) forever. Leave **Display** and **Arrangement** handling as
usual in the Update dialog (untick Arrangement if you have dragged the pack somewhere you like).

## v13 — the rings are back, and so are the faces

*Historical. The target cluster this version describes was deleted in v14, and threat moved
onto the player cluster — see above.*

**What changed:** the Diablo globes are gone. Your health and mana are **two rings around a
live portrait of you** again, and your target's health and your threat on it are two rings
around a live portrait of *them*. Two arcs and a face, twice — that is what makes the two
clusters read as a matched pair instead of as three unrelated jars of coloured liquid.

Nothing outside the two clusters changed: not one trigger, load gate, condition, spell ID,
size or position anywhere else in the pack. No aura was added or removed — 48 before, 48
after — and every UID is identical, so this imports as a plain in-place **Update**.

```
                                                    64%      <- threat %, above its ring
                                                 ,-------.
                                               /  ,---.   \  <- THREAT  (outer, 84px)
                                              |  |  @  |   | <- their face (44px)
                                               \  `---'   /  <- health  (inner, 62px)
                                                 `-------'
                                                    88%      <- target health %
                                            the target, (+270, 110)

       ,-------.
     /  ,---.   \  <- health (outer, 84px)
    |  |  @  |   | <- your face (44px)
     \  `---'   /  <- mana   (inner, 62px)
       `-------'                  your character
          74%    <- health %
          41%    <- mana %
     you, (-270, 40)
```

| Cluster | Where | Outer ring | Inner ring | Centre |
|---|---|---|---|---|
| **You** | `x = -270, y = 40` | **health**, 84px, green — hot red under **30%** | **mana**, 62px, blue — red under **20%** | your live 3D portrait, 44px |
| **Target** | `x = +270, y = 110` | **threat**, 84px — green, orange from 70%, red once you hold aggro | **health**, 62px, green — orange-red under **20%** | the target's live 3D portrait, 44px |

Those sizes and positions are **identical in all seven class packs**: outer 84, inner 62,
portrait 44, clusters at `x = ±270`. Roll another class and the two clusters are in the same
place, at the same size, meaning the same things.

`x = ±270` is clearance, not taste. The Alerts column occupies `x −170…−130` and the PvP
column `x +132…+168`, and both are *dynamic* groups that grow vertically — at `±190` the
alert stack climbs into the cluster from the second simultaneous prompt onward. `±270` is the
tightest symmetric pair of positions that stays clear at any stack depth. The 140×9 **swing
runway** did not move either: it stays at `(−150, −76)`, 8px clear of the cluster horizontally
and 31px clear of the lowest percentage vertically.

### The portrait is back, so the numbers are outside the rings again

A WeakAuras `model` region cannot carry text — that is a hard limit of the region type, not a
choice — so with a face in the middle of each cluster the percentages hang below the arcs
again: health at 13pt just under the outer ring, mana at 10pt stacked under that, threat at
10pt above the ring it belongs to. The mana number is tinted to echo its own ring, which is
what tells two stacked percentages apart without spending a label on either.

The **specular highlight** v12 added is gone with the globes. It was a glass effect for a
filled vessel; on an annulus there is no glass to catch light.

### Threat is the target's outer ring

Threat is your standing on that unit's table, so it belongs at that unit — and it costs the
target side no extra element, because the cluster is two rings and a face and threat simply
*is* the outer one. Green normally, orange from 70%, red once you actually hold aggro, with
`%threatpct%` above it. Party or raid only and, since v6, never inside an arena, so solo or in
the open world the target cluster is just a health ring and a face. The Retribution-only
**Threat Flash** pulses red on that same outer ring at 80%+.

All three threat escalations moved with it, from the `color` property a plain texture uses back
to the `foregroundColor` a progresstexture uses. WeakAuras silently *skips* a condition whose
property the region does not have — no error and no editor warning — so getting that wrong
ships a threat ring that never changes colour and looks fine in the editor. The zero-threat
guard came along too: without it a ring whose total is 0 draws as a **full** circle, i.e. as
full aggro on a target you have not touched.

There is deliberately **no target mana ring**. Two rings and a face on both sides is the
design; a third arc is what made the v9 target orb look busy and uneven next to yours. It is
also the right call on the merits — see *Still not built: an enemy mana bar* below.

### If you are updating from v11 or v12

Leave **Display** ticked in the Update dialog. That is the category carrying the region type,
and it is what turns the globes back into rings and the two glass rims back into the portraits
they were built as in v9. Untick **Arrangement** if you have dragged the pack somewhere you
like. Nothing needs deleting: the rims *are* the portraits — same auras, same UIDs, handed
back.

## v12 — the globes flank you, and the glass catches light

**What changed:** two things, and nothing else. The vessels **moved off the bottom of the screen
to either side of your character**, and each one now has a **highlight** on it, so it reads as
curved glass with liquid in it rather than a flat coloured sticker.

Not one trigger, load gate, condition, colour, spell ID or region type changed. No aura was
added or removed, every UID is identical to v11, and nothing outside the globes moved — the
buffs, the alerts, the cooldown row and the PvP layer are all exactly where v11 left them. This
imports as a plain in-place **Update**.

### They flank the character now

v11 parked all three vessels on one band at `y = -262`, below the cooldown row — which read as a
separate bar bolted underneath the HUD rather than as your own state. They now sit beside you at
eye height, with the target above the gap between them:

```
                             ,---.
                            | 88% |   target, (0, 110)
                             `---'
     ,-----.                                        ,-----.
    /  .-.  \                                      /  .-.  \
   |  ( ) 74% |          your character           |  ( ) 62% |
    \       /                                      \       /
     `-----'                                        `-----'
  life, (-270, 40)                               mana, (+270, 40)
```

| Vessel | Where | Size | What it says |
|---|---|---|---|
| **Life** | `x = -270, y = 40` | 72px | your health, in D2 red, `%percenthealth%` inside at 18pt. Goes hot red under **30%**. |
| **Mana** | `x = +270, y = 40` | 72px | your mana, in D2 blue, `%percentpower%` inside at 18pt. Goes red under **20%** — the paladin threshold that ends a tank's threat, a healer's raid and a ret's uptime. |
| **Target** | `x = 0, y = 110` | 44px | the target's health, half size so it reads as secondary. Red under **20%** — the Hammer of Wrath execute window on an enemy, the Lay on Hands emergency on an ally. Vanishes completely with no target. |

Those three positions are **identical in all seven class packs**, and so are the sizes and the
colours. They are also the tightest arrangement that collides with nothing: `x = ±170` would run
into the Alerts column at `x = -150` and the PvP column at `x = +150`, and `x = ±210` would run
into the PvP-layer icons at `(200, -44)`. Roll another class and the vessels are in the same
place, at the same size, meaning the same things.

The **swing runway did not follow the life globe** — it stays at `(-150, -76)`, exactly where
v11 shipped it. Its x offset used to be written as *the globe's* x, so this pass had to cut that
link on purpose rather than drag a non-globe element sideways as a side effect.

### The glass catches light

Each vessel carries one more sub-region: a soft, off-centre bright spot in its **upper left**,
46% of the globe wide and 34% tall, at 28% white. That is the whole trick — a highlight offset
from centre is what the eye reads as a *curved* surface with a light source somewhere above and
to the left, and it turns the flat disc into a jar.

It is drawn in **ADD** blend, not normal blend, and that is not a style choice. The percentage
lives *inside* the glass and sub-regions draw in order, so an overlay appended on top of the
number in normal blend would grey it out. ADD can only brighten, so the number stays readable —
which is exactly why the highlight is a bright spot rather than the more obvious dark rim
vignette, which would have had to sit under the text to be safe.

The highlight is **appended** as the last sub-region on each globe, never inserted. WeakAuras
conditions address sub-regions by position (`sub.1`, `sub.2`, …), so slipping a new one in ahead
of a referenced index silently re-points that condition at the wrong thing.

## v11 — Diablo globes

**What changed:** the rings are gone. Your life and your mana are now **globes** — vessels that
fill from the bottom like liquid, with the number **inside the glass** — and your target is a
third, smaller globe between them.

```
     ,-----.                                        ,-----.
    /       \              threat 41%              /       \
   |   74%   |               ,---.                |   62%   |
    \       /               | 88% |                \       /
     `-----'                 `---'                  `-----'
   life, x = -150         target, x = 0          mana, x = +150
```

| Vessel | Where (v11 — v12 moved all three) | Size | What it says |
|---|---|---|---|
| **Life** | `x = -150, y = -262` | 72px | your health, in D2 red, `%percenthealth%` inside at 18pt. Goes hot red under **30%**. |
| **Mana** | `x = +150, y = -262` | 72px | your mana, in D2 blue, `%percentpower%` inside at 18pt. Goes red under **20%** — the paladin threshold that ends a tank's threat, a healer's raid and a ret's uptime. |
| **Target** | `x = 0, y = -262` | 44px | the target's health, half size so it reads as secondary. Red under **20%** — the Hammer of Wrath execute window on an enemy, the Lay on Hands emergency on an ally. Vanishes completely with no target. |

Those three positions were **identical in all seven class packs**, and so are the sizes and the
colours. Roll another class and the vessels are in the same place, at the same size, meaning the
same things. (v12 moved the three of them together, in every pack at once, for the same reason.)

The empty part of each globe is a near-black disc rather than nothing at all: that is what makes
it read as a *container* — coloured liquid rising into a jar, not a shape appearing out of the
void — and a brass rim rings each one. The fills still fade to 50% out of combat; **the rims do
not**, so the vessels are still findable while you ride around. That is the job the portraits
used to do.

### The portrait is gone, and that is what buys the number its place

Diablo has no portrait. Dropping it is not a subtraction here, it is the whole trade: a
WeakAuras `model` region **cannot carry a text sub-region at all**, which is exactly why v9 and
v10 had to park the percentages *outside* the rings, at 11–14pt, where they competed with the
world behind them. With the face gone, each number sits in the middle of its own vessel at 18pt
— where your eye already is.

**Nothing was orphaned, and you do not have to delete anything.** Neither portrait aura was
removed: both were *recycled*, UID and all, into the two glass rims. `Paladin - Player Portrait`
is now `Paladin - Life Globe Rim` and `Paladin - Target Portrait` is now `Paladin - Mana Globe
Rim`. 48 auras before, 48 auras after, every UID stable, so this imports as a plain in-place
**Update** with no leftovers.

### Threat became the target globe's rim

Threat is the one readout with no natural vessel — it is not a resource anybody holds, it is
your standing on someone else's table. So `Paladin - Threat` kept its id, its UID, its trigger,
its thresholds and both of its load gates, and became **the glass around the target globe**:

| Rim colour | Meaning |
|---|---|
| **Green** | you are below 70% of the pull threshold |
| **Orange** | 70%+ — you are closing on the tank |
| **Red** | you hold aggro (for Protection, that red is the goal state, not an alarm) |

The percentage prints just above the globe, and the red **Threat Flash** still pulses on that
same rim at 80%+ for Retribution only. This costs no extra element and no extra screen space —
which is the entire argument for putting it there. Threat still loads in a party or raid only,
and still never inside an arena, so **out in the open world or solo the target globe simply has
no rim**: that is not a missing piece, it is the absence of a threat table.

### Two things moved out of the way — and only moved

Nothing about either one changed except where it sits: same triggers, same gates, same
conditions, same sizes.

- **The buff row** (Seal Active / Judgement Debuff / Holy Shield or Light's Grace) went from
  `y = -156` to `y = -60`. The target globe now occupies exactly where it used to be. It sits
  above the threat percentage instead.
- **The swing runway** went from `(-260, -170)` to `(-300, -76)` — it used to sit under the
  player's ring cluster, and a 122px life globe now fills that space. It rides just above the
  life globe, on the same x, still 140x9, still gold in the last 0.4 seconds.

### One colour changed, to keep a signal from going silent

The low-health escalation was `{0.90, 0.12, 0.12}` — a red chosen back when the ring underneath
it was **green**. On a D2-red vessel that is the vessel's own colour: the condition would fire
every time and show you nothing. Both health escalations therefore use the prototype's
escalation reds on a red vessel — a hot `{1, 0.15, 0.15}` for your own life and an orange-red
`{1, 0.35, 0.10}` for the target. Same triggers, same 30% / 20% thresholds, same property, same
order. **Mana's red is untouched**: red on a blue vessel needs no help.

### What did not change at all

Every trigger, load gate and condition outside the globes; the spec gating; the alert flow; the
cooldown row; the PvP layer; the seal-twisting pair; and the `threatvalue <= 0` guard that stops
the threat rim painting a full-aggro colour on a target you have no threat on yet.

**One thing to watch in the Update dialog:** leave the **Display** category ticked — that is the
category carrying the region types, and unticking it would keep the old ring shapes while
accepting the new positions, which is the one combination that looks broken. If you have dragged
the HUD around in game, untick **Arrangement** as usual.

## v10 — the orbs are one shared size now, in every pack

**What changed:** nothing but geometry. Not one trigger, load gate, condition, colour, spell
ID or region type moved, no aura was added or removed, and every UID is identical to v9 — so
this imports as a plain in-place Update.

v9 shipped the unit orbs seven times over, once per class pack, and every pack had picked its
own ring diameters. Worse, the **two clusters inside this pack disagreed with each other**: the
player orb was 88px across and the target orb 118px, so the same two faces read as different
sizes side by side. That is what "the sizes look uneven" was. All seven packs now build from
one shared set of numbers:

| | v9 (paladin) | v10 (every pack) |
|---|---|---|
| Player health ring (outer) | 88 | **104** |
| Player mana ring | 60 | **78** |
| Target threat ring (outer) | 118 | **104** |
| Target health ring | 88 | **78** |
| Threat halo (Ret) | 132 | **104** — pulses *on* the threat ring |
| Portrait | 28 | **46** |
| Cluster offset | (±252, −78) | **(±260, −60)** |

Both clusters now present the **same outer diameter and the same portrait**; the target simply
nests one more ring inside. The percentages moved onto the shared baselines with them (health
14pt at −60, mana 11pt at −76, threat 11pt at +60 above the ring).

The ring art changed with the size: **Ring_20px replaces Ring_10px**. These annuli scale their
stroke with the drawn size, so the old 10px art at these diameters was a 4px wire — thin and
cheap-looking, the first thing anyone noticed about v9. The 20px art draws an 8px band on the
outer ring and 6px on the inner one.

The **swing runway did not move on screen**. The orbs rose 18px onto the shared cluster line and
the runway's offset absorbed the re-anchoring, so it sits exactly where it did — now with 22px
of clearance under the mana percentage instead of 5px, because the orb above it got shorter.

## v9 — the middle of your screen is yours again

**What changed:** the three 172px bars that sat under your character since v1 — health, mana,
threat — are gone. In their place are **two unit orbs**, flanking the middle instead of filling
it: **you on the left, your target on the right**, each a live 3D portrait ringed by its own
progress arcs with the percentages underneath.

```
        ( 88%  )                                          ( 62% )
       ( ( 🧑 ) )        ← character stands here →       ( ( 👹 ) )
        ( 74%  )                                          threat 41%
        ▁▁▁▁▁▁▁ swing
```

**The player orb (left, at x = −252).** Outer ring = health, inner ring = mana, live portrait
in the middle, the two percentages stacked below it. The main-hand **swing runway** for seal
twisting rides underneath as a short bar — see *Why the swing timer is still a bar* below. Both
rings still fade to 50% out of combat, exactly as the bars did.

**The target orb (right, at x = +252).** Outermost ring = **your threat on that target**, then
health, then the target's portrait. Threat's percentage sits *above* its ring, health's below,
so the two numbers never queue up under one orb. The whole cluster **vanishes completely when
you have no target** — that is not a load gate or a condition, it is the health trigger
producing no state at all for a unit that does not exist, so there is nothing to switch off.

**Every warning the bars carried is still here, in the same colours:**

| Signal | v8 (bar) | v9 (orb) |
|---|---|---|
| Mana under 20% | bar turns red | mana ring turns the same red |
| Threat at 70%+ | bar turns orange | threat ring turns the same orange |
| You hold aggro | bar turns red | threat ring turns the same red |
| Threat at 80%+ (Ret only) | red rectangle pulsing over the bar | red halo pulsing around the target orb |
| Out of combat | health and mana bars at 50% alpha | health and mana rings at 50% alpha |

Two signals are **new**, both free because a ring says less with length than a bar does and has
to say more with colour: your own health ring turns red **under 30%**, and the target's health
ring turns red **under 20%** — which on an enemy is the Hammer of Wrath execute window the alert
column is already prompting for, and on a friendly target is the Lay on Hands emergency.

### Nothing is orphaned — you do not have to delete anything

This is worth stating plainly, because migrations like this normally leave litter. The three
bars were **transformed, not replaced**: `Paladin - Health`, `Paladin - Mana` and
`Paladin - Threat` keep their aura ids *and* their UIDs and simply became ring displays, and
`Paladin - Threat Flash` kept its id and UID and became the halo. WeakAuras matches auras across
imports by UID, so all four update in place. Only five auras are genuinely new (the two cluster
groups, the target's health ring, and the two portraits), and they append after everything else.
43 auras → 48, zero removals, `changed=0` on the UID continuity check.

**One thing to watch in the Update dialog:** leave the **Display** category ticked. That is the
category that carries the region type, and unticking it would keep the old bar shapes while
accepting the new positions — the one combination that looks broken. If you have dragged the
HUD around in game, untick **Arrangement** as usual; the Resources group keeps its own UID, so
your dragged position for it survives.

### Why the swing timer is still a bar

`Paladin - Swing Timer` was the one thing in the old stack that is **not a unit resource**, and
it did not become a ring:

1. It is a property of your weapon swing, not of the player or the target, so there is no unit
   whose orb it would ring.
2. A sub-second window is judged as *distance to an edge*. On a linear bar the 0.4s twist window
   is a visible run-up to a fixed right-hand edge; wrapped onto an arc it becomes a rotating tick
   with no edge to aim at. That judgement is the entire skill the element exists to support.

So it stays a bar — 140x9 instead of 172x10 — and sits **with the player's own readout** rather
than back in the vacated centre (under the player orb in v9/v10, above the life globe in v11, and
since v12 at a fixed (−150, −76) of its own while the globes moved up beside you). It still turns
gold in the last 0.4s, still only exists while you are actually swinging, and is still gated on
Seal of Command.

It is a *sibling* of the two clusters inside Resources rather than a child of either, so it
can be dragged somewhere personal — many twisters want a sub-second window right under the
crosshair — without dragging your health and mana readouts along with it, and so it survives if
you turn the player globes off in favour of your unit frames.

### Nothing was lost on the way across

- **No resource breakpoint marks were lost, because this pack never had any.** The tick marks
  that mark thresholds on a bar (rogue's 35/40 energy lines, druid's bear-rage marks) are an
  aurabar-only sub-region and genuinely cannot be ported to a ring. The paladin pack does not
  use them: its one resource threshold is "mana under 20%", which was a colour change on the bar
  and is the same colour change on the ring.
- **No numbers were lost.** Health %, mana % and threat % all still print, on the ring they
  belong to.
- **Threat keeps both of its load gates** — party/raid only, and never inside an arena.

### Two failure modes that were designed out

Worth knowing about, because both are invisible until they bite:

- **A ring at "no data" fills, where a bar empties.** WeakAuras draws a bar with a zero total as
  *empty* and a ring with a zero total as *full*. Threat hits a zero total whenever your threat
  value is zero — the moment before your first hit lands, and right after a Divine Shield drops
  you off the table — so a naive port would slam the threat ring to a complete circle, meaning
  "you are at the pull threshold", while the colour stayed green. Every ring here carries an
  explicit hide-when-there-is-no-data condition, so it disappears instead of lying.
- **`barColor` does not exist on a ring.** The property is `foregroundColor`, and WeakAuras
  silently *skips* a condition whose property the region does not have — no error, no warning in
  the editor, the escalation simply never fires. Every colour condition that moved onto a ring
  was renamed; the swing bar, still a bar, correctly kept `barColor`.

## v8 — the execute prompt is hostile-only for real

`Paladin - Hammer of Wrath` fired for a **wounded ally** under 20% health, not just an
enemy. v4 claimed to have fixed exactly this, but did it by setting a hostility filter on
the health trigger — and hostility is not an argument the health trigger reads, so
WeakAuras silently ignored it. The prompt now carries a third trigger that checks target
hostility properly, so a glowing damage button no longer appears over a dying party member.
Nothing else changed; all 42 UIDs are stable, so this imports as an Update.

## v7 — the cooldown row now shows what you *cannot* press

**Absence means available.** The row used to show all fourteen icons all the time and grey out
whichever were down, which meant it was busiest exactly when you had the fewest options — and you
already know your own spellbook. What you cannot know is what is *unavailable, and for how long*.

So the situational half of the row now appears **only while it is on cooldown**, carrying its swipe
and its countdown, and vanishes the moment the ability is back. The row is a dynamic group, so the
gap closes behind it: **an empty row means everything is up**, and two icons mean exactly two things
are down and both are counting back. No aura was added, removed, renamed or moved — re-importing is
still an **Update**, and every position you dragged survives.

Those icons also **lost their grey-while-down tint**, because it stopped meaning anything: if the
only icons on screen are the ones on cooldown, greying all of them just makes them harder to tell
apart. Full colour plus the number reads faster.

### What still sits there permanently — and glows

The four buttons the rotation says to press *the moment they are up* stay on screen in both states,
still greyed while down, still flashing gold the instant they come back. A hidden icon cannot
announce a moment, and these are the moments:

| Always on screen, glows gold when ready | Why it is not hidden |
|---|---|
| **Judgement** | 10s, off the global cooldown — Protection and Retribution press it on sight |
| **Crusader Strike** | 6s, the Retribution rotation's metronome |
| **Avenger's Shield** | on the pull, then on cooldown, for Protection |
| **Consecration** *(new in v7)* | Protection's largest threat source and an explicit press-on-cooldown line in the tank rotation |

**Consecration is the one classification this version changes.** It never had the glow, because the
same icon also loads for Retribution, where Consecration is a mana-permitting filler rather than a
rotation button — a glow overstates it there. Under v7 that trade stopped being symmetric: the only
alternative to glowing it was *hiding a tank's biggest threat button whenever it is available*,
which is the wrong direction for the button they press most. Retribution still reads the row
correctly, because Judgement and Crusader Strike wear the same glow and sit ahead of Consecration in
the priority — a lit Consecration there means "your filler is up", spend it if the mana is there.

### What now hides while it is ready

Everything pressed because a *circumstance* called for it, rather than because it came off cooldown:

- **Divine Shield**, **Lay on Hands** — panic buttons. Lay on Hands already has its own alert that
  fires at under 25% health, so the row only needs to answer "when do I get it back".
- **Avenging Wrath** — a 3-minute burst you spend on a window, and it locks out your bubble.
- **Hammer of Justice** — a stun and your only interrupt, pressed at a cast, not on sight. In an
  arena or battleground the **HAMMER NOW** prompt already owns the moment.
- **Holy Shock** — deliberately *not* promoted to a glowing button. TBC Holy is Holy Light and Flash
  of Light; Holy Shock is the expensive instant you keep for moving and for emergencies, so pressing
  it every 15 seconds is a mana bug, not a rotation.
- **Divine Favor** (2 min, saved for a Holy Light on someone actually taking damage) and **Divine
  Illumination** (3 min mana cooldown) — spent at a window you choose.
- **Blessing of Freedom**, **Blessing of Protection**, **Hammer of Justice (PvP)** — the arena/BG
  additions, all three held for a moment rather than pressed on cooldown.

A Holy paladin riding out of combat now sees an empty cooldown row instead of five greyed icons; a
Protection paladin mid-pull sees Judgement and Consecration lit, plus however many situational
icons are genuinely down.

## v6 — the CC icon tells you which button, and the threat bar leaves the arena

Two things v5 shipped with an open question. Both answers are now confirmed against WeakAuras'
own source, and both land on auras that already exist — **no aura was added, removed, renamed or
moved**, so re-importing is still an **Update** and every position you dragged survives.

### CC ON ME is now colour-coded by what has you

Under a stun nobody reads text. v5 gave you the effect's own icon and a countdown in a red glow;
the red never changed, so the icon told you *that* you were controlled and left *which button
breaks it* to memory — and for a paladin those are four genuinely different answers. The glow now
carries the category:

| Glow | What has you | What you press |
|---|---|---|
| **Red** | Stun | The trinket. It is the only answer — you cannot bubble while stunned. |
| **Purple** | Fear | Trinket, then bubble. |
| **Blue** | Root or snare | **Blessing of Freedom — not the trinket.** Spending the medallion on a Frost Nova is how the next Hammer of Justice kills you. |
| **Green** | Polymorph / confuse | Nothing. Ride it: any damage breaks it, so let a partner clip it rather than burning a cooldown. |
| **Amber** | Silence or school lockout | Your Holy school is gone, so nothing you cast will land. Trinket **earlier** than the timer makes you feel you should. |

Anything outside those five categories keeps the red default, which reads as "trinket food" — the
right assumption when the HUD does not know better. These are the same five colours the other packs
in this repo use, deliberately: roll a second class and you already know the language.

The countdown and the effect's own icon are unchanged, and this is still **not** diminishing-returns
tracking — see the v5 note below, which has not moved an inch.

### The threat bar and threat flash no longer load in an arena

An arena has no threat table, so both were dead PvE furniture sitting in the middle of the screen at
the exact moment space matters most. They now carry an instance-size gate listing every instance type
**except** arena: open world, 5-man, 10/20/25/40-man raid and battleground. Battlegrounds keep them on
purpose — Alterac Valley is full of elite NPCs with real threat tables.

v5 deliberately did *not* ship this, because the gate has to be spelled as "everywhere except arena"
(WeakAuras has no "not arena" key) and it was unclear whether the open world even has a size value to
list — if it did not, the gate would have silently unloaded your threat bar everywhere outside an
instance, which is a far worse bug than two dead bars in an arena. It does: WeakAuras returns the
literal size `"none"` outside instances, `none` is listed, and **nothing changes for a PvE player.**
No other aura's loading was touched.

### Still not built: an enemy mana bar

A per-opponent mana readout is now a proven WeakAuras primitive on 2.5.x (the Power trigger accepts
arena units and clones one row per opponent), and other packs in this repo will get one. A paladin
does not: there is no paladin mana drain, burn or punish — Judgement of Wisdom *gives* the attacker
mana. Watching a healer's bar tick down would not change one paladin button press, and an element
that does not change your next press does not belong in this pack.

## v5 — PvP layer

Ten new elements plus the dynamic group that holds them, and **every element carries its own
instance-type load gate — `arena` + `pvp`, or `arena` alone**. (The container group itself has no
gate, exactly like the four groups already in the pack: it draws nothing, and gating each child
individually is what lets the column close its own gaps.) In PvE — raid, dungeon, heroic, open
world — nothing appears, nothing moves, and nothing about the v4 HUD changes: no existing aura had
a trigger, gate, size or position touched. Re-importing is still an **Update** (no existing
`W.uid()` call was added, removed or reordered), so your dragged positions survive.

**This is not diminishing-returns tracking, and must not be read as one.** WeakAuras on TBC has no
DR prototype, no DR type table and no bundled DR library, and faking DR with an 18-second timer
models the *reset* window rather than the category — it is wrong the moment two spells share a
category, and a DR tracker that is wrong is worse than none because it gets trusted. Every CC
readout below shows the effect that is running **right now**, with its own remaining time. Whether
the next stun lands at full, half or quarter duration is still your own count.

### New: the PvP column (dynamic group at (150, 96), mirrors the Alerts column)

State readouts, growing downward, on the opposite side of the character from the alert flow so the
PvE layout never shifts.

- **Trinket DOWN** — visible *only while your PvP trinket is on cooldown*; absence means it is
  ready, so the column is empty in the normal case. Desaturated with a swipe countdown. Decides the
  single biggest PvP question a paladin has: ride the stun, or spend the medallion now. Tracked by
  exact item id (Medallion of the Alliance/Horde, and the level-60 paladin Insignias), never by
  equipment slot — a slot tracker would report "trinket down" whenever any *other* on-use trinket
  was ticking, and that false alarm costs a life.
- **Enemy Trinket** *(arena only)* — a 2-minute countdown per opponent, started when you see them
  trinket. While it runs, their get-out is gone: that is the window your real CC chain and your
  kill attempt go into. This is an **inference, not a read** — no API on 2.5.x can query another
  player's cooldowns — so an opponent who trinkets out of your sight starts no countdown, and an
  opponent still using the old 5-minute Insignia will be shown as ready long before they are.
- **Forbearance** *(arena only)* — one icon per team member carrying Forbearance, with the time
  left. It answers the paladin-only question the default UI buries in a debuff row: who can still
  be given Divine Shield, Blessing of Protection or Lay on Hands. BoP-ing a partner locks *your*
  bubble out of them for a minute, so this is where "which of us survives" is actually decided.
- **CLEANSE** *(arena only)* — one glowing icon per team member holding an effect worth a global,
  showing **which** effect and how long is left, because with the strongest dispel in the game the
  decision is ordering, not speed: Polymorph, Fear, Psychic Scream, Howl of Terror, Entangling
  Roots, Wound Poison, Crippling Poison, Viper Sting (all ranks). Filtered by exact spell id, never
  by dispel type — a "magic" filter would fire on every trivial magic debuff and still miss
  physical CC, which has no dispel type at all on non-retail.

Both clone rows read *group* units, so they are arena-only on purpose: in a 40-man battleground
every stray fear and every other paladin's bubble would push another icon into the column, and a
wall of icons is the same as no HUD at all.

### New prompts in the alert flow

Same language as the rest of the pack — glowing icon, slides in from below, flies off on exit. None
of them takes the usual in-combat gate: the opening Sap, poly or Hammer all happen before the
combat flag, and the arena/BG gate already keeps them out of the rest of the game.

- **CC ON ME** — appears the moment anything takes control of you, shows *that effect's own icon*
  and counts it down. Which break works is what the icon tells you: a stun means the trinket (you
  cannot bubble while stunned), a fear means trinket-then-bubble, a root or snare means **Blessing
  of Freedom, not the trinket**, and a school lockout means your Holy spells are gone for the
  duration so the answer is the trinket or distance — never another cast. This is also the only way
  to see a Kick/Counterspell lockout at all: a lockout is not a debuff, so no aura trigger can find
  it. *(v6 puts that decision in the glow colour instead of leaving it to memory — see above.)*
- **HAMMER NOW** — a paladin has no interrupt, so the stun *is* the interrupt. The prompt exists
  only when both halves are true: your target is in the **last 1.5 seconds of a cast** *and* Hammer
  of Justice is genuinely castable (cooldown and mana both checked). If the target is outside
  Hammer's 10 yards the icon desaturates, which reads as "close the gap first" rather than "press
  it". There is no filter for "casts I can interrupt" — WeakAuras disables that argument on TBC
  entirely — so fake-casting still beats you; that is a player skill, not a HUD feature.
- **TARGET IMMUNE** — stop. Judging, Crusader Striking or dumping Avenging Wrath into Divine
  Shield, Blessing of Protection, Ice Block, Cloak of Shadows or Divine Intervention spends the
  whole set for zero; The Beast Within means your stun is wasted too. Hostility is checked
  separately, so your partner's own bubble never fires it.

### Cooldown row, PvP additions

Three more 32x32 icons, same swipe/desaturate/out-of-combat-fade language as the rest of the row,
and deliberately **no** gold ready-glow — these are held for a moment, not pressed on cooldown.
*(v7 makes that classification literal: all three now show only while they are on cooldown, and the
grey-while-down tint went with the always-on display — see above.)*

- **Blessing of Freedom** — the answer to every root and snare, i.e. the reason not to spend the
  trinket. Whether it is up decides which of the two goes.
- **Blessing of Protection** — the peel, read next to the Forbearance row it will burn.
- **Hammer of Justice (Holy, PvP only)** — v4 hid the shared Hammer icon from deep Holy, which is
  right in a raid (bosses are stun-immune) and wrong in an arena, where the stun is a healer's main
  peel. This copy carries the exact inverse gate — Holy Shock *known* — plus the PvP gate, so it can
  never double up with the icon Protection and Retribution already have.

### Not built, and why

- **Diminishing returns** — see above. Not expressible without custom code.
- **Enemy cooldowns and enemy spec** — no API on 2.5.x reads either. The enemy trinket countdown is
  the one sanctioned approximation, and it is labelled as one.
- **A Will of the Forsaken readout** — TBC has no Undead paladins (Human, Dwarf, Draenei, Blood
  Elf), so the second trinket charge that element exists for cannot happen here.
- **Hiding the threat bar inside arena** — the inverse instance-size gate needed a field check first
  (WeakAuras only assigns the size value inside instances, and if it were nil in the open world that
  gate would silently unload the bars everywhere outside one). **Resolved and shipped in v6**: the
  open-world value is the literal string `none`, so the complement can be listed safely.
- **Enemy health frames and an enemy cooldown wall** — Gladius already owns the first, and the
  second is unreadable inside a stun.

### Field check before you lean on CC ON ME

The Crowd Controlled trigger is the one piece here that WeakAuras' own source cannot prove works on
a 2.5.x client: the prototype was deleted for Classic flavours in WA 3.5.0–5.1.x and ungated again
in 5.2.0, and it reads the loss-of-control API rather than the aura table. Get sapped and kicked in
a duel once and confirm the icon appears. If your client does not populate that API the icon simply
never shows — nothing else in the pack depends on it.

## v4 — each spec sees only what it presses

A Holy paladin reported the pack showing them buttons they never press. They were right: the
gates asked "can this spec *cast* it", when the only question that matters is "does this spec
*press* it as part of playing well". Three more elements now carry the inverse load gate
(`not_spellknown` = Holy Shock 20473, "not deep Holy"). Gating only — no element was added,
removed or moved, so re-importing is still an **Update** that keeps your dragged positions.

**Holy no longer sees:**

- **Judgement** (cooldown icon). Protection and Retribution press Judgement the moment its 10s
  cooldown is up — a numbered line in both rotations, and what the gold ready-glow means. Holy
  judges on a different clock entirely: Seal of Wisdom → Judgement of Wisdom, refreshed when the
  **20-second debuff** expires. Because the cooldown is half the debuff, it was off cooldown
  every time the decision came up, so the glow sat lit for most of every fight — a permanent
  "press me" that was wrong more often than right. The decision Holy actually makes is already
  rendered by **Paladin - Judgement Debuff** (own-only, 20s, on the boss), which stays. So this
  removes the false prompt, not the information — Holy paladins in a raid without a Retribution
  paladin should still keep Judgement of Wisdom up, and now watch the debuff timer to do it.
- **Hammer of Justice**. A 6s stun. Protection uses it to interrupt casters and to pin a runner
  while gathering a pack, Retribution carries it as its only interrupt; for a healer it is a PvP
  button that never enters a healing decision, and raid bosses are stun-immune.
- **Hammer of Wrath** (the execute prompt). It keeps its own `spellknown` gate on 24275 and adds
  the inverse gate on top — WeakAuras ANDs load conditions, so it now reads "knows Hammer of
  Wrath *and* is not deep Holy". A glowing damage button on a boss at 19% is not a healing cue.

**Deliberately kept for Holy** (a false cut costs more than a marginal keep):

- **Divine Shield** and **Lay on Hands** — genuine panic buttons, and bubble doubles as a debuff
  wipe. With Avenging Wrath gone from the Holy row since v3, these are the only Forbearance-
  burning presses left in it, which is exactly the pairing a healer needs to see together.
- **Threat** — a healer who pulls the boss off the tank wipes the raid, and the bar self-hides
  while you are targeting a friendly, so it costs a healer nothing when it is not relevant.
- **Seal Active** and **Judgement Debuff** — Seal of Wisdom → Judgement of Wisdom upkeep is the
  Holy paladin's one non-healing job when the raid has no Retribution paladin.

Protection and Retribution lost nothing: Judgement, Hammer of Justice and Hammer of Wrath are
all in their published rotations. **Seal twisting stays gated on Seal of Command (20375) rather
than on Retribution's capstone on purpose** — a Sanctity-Aura Protection paladin who takes Seal
of Command does so precisely to twist with a two-hander on fights they are not tanking.

*Requires WeakAuras 5.4.0 or newer for the inverse gate*, same as v3: on an older client the
unknown field is ignored and those elements simply load for everyone, exactly as before.

## v3 — seal twisting + spec-selective cooldown row

**Retribution seal twisting ("swing dancing").** Two new elements, both gated on Seal of
Command's own rank-1 id (20375), so they appear for anyone who can actually twist and stay
hidden otherwise:

- **Paladin - Swing Timer** — a slim main-hand swing bar under the resource stack (v9: under
  the *player orb*, and 140x9 rather than 172x10). It drains
  toward impact and turns gold in the last 0.4s: that gold band *is* the twist window. Note
  the bar does not exist until you start swinging (the WA Swing Timer trigger produces no
  state while the timer is not running), so it appears on your first white hit and vanishes
  when you stop.
- **Paladin - Twist NOW** — an alert-flow icon that is present only while Seal of Command is
  up *and* you are swinging (both triggers required), and glows gold inside the same 0.4s
  window. That glow is the moment to re-seal with Seal of Blood (Horde) or Seal of the Martyr
  (Alliance); both are already in the seal list, so the seal readout follows either.

Twisting is an advanced, high-APM play. If you do not want it, untick these two auras in
`/wa` — nothing else depends on them.

**The cooldown row is now spec-selective.** A healing Holy paladin was being shown
Consecration (a threat/mana dump) and Avenging Wrath (a damage cooldown) — buttons that never
enter a healing rotation, sitting in the row where their real cooldowns live. Both now carry
an inverse load gate (`not_spellknown` = Holy Shock 20473, a 30-point Holy talent), so they
load for Protection, Retribution and shallow hybrids but not for deep Holy. This needed the
inverse gate rather than one copy per spec: no single spell is known by Prot and Ret but not
Holy, and duplicating the icon would double-show it to a 21-Prot/40-Ret hybrid who knows both
capstones.

*Requires WeakAuras 5.4.0 or newer for the inverse gate.* On an older client the field is
ignored and those two icons simply load for everyone, exactly as in v2 — it degrades, it does
not break.

Audit any spec's actual element list with `lua5.1 tools/spec-preview.lua paladin`.

## v2 — rotation fixes

A rotation review judged v1 against one standard: every element must change which button you
press next. Four things failed that test. v2 fixes them without adding or moving a single
`W.uid()` call, so re-importing offers **Update** and keeps your dragged positions.

- **Seal of the Martyr (348700) and Seal of Corruption (348704) added to the seal list.**
  These are the 2.5.1 Alliance/Horde damage seals and were missing from all 36 ids v1 knew, so
  an Alliance Retribution paladin — running the spec's *default* seal — had a permanently blank
  Seal Active icon **and** a red SEAL MISSING alert glowing in the alert flow for the entire
  fight. That is the worst failure mode a pack can have: the alert that fires when nothing is
  wrong is the alert you learn to ignore. Same fix covers Horde Protection on Seal of Corruption.
- **Hammer of Wrath is no longer Retribution-only, and only fires on hostile targets.** It was
  gated on Crusader Strike (35395, a 41-point Ret talent) even though HoW is baseline at level 44
  and is an explicit numbered Protection priority line — a Protection paladin never saw the
  execute prompt at all. It now gates on its own rank-1 id (24275), so it appears for every spec
  that has learned the spell and stays hidden while levelling toward it. Trigger 1 also gained a
  `hostility = hostile` filter: targeting a wounded *ally* under 20% no longer fires a glowing
  prompt for a spell that cannot be cast on them.
- **The press-on-cooldown buttons now say "press this NOW".** Judgement (10s, off the GCD),
  Crusader Strike (6s) and Avenger's Shield were passive icons that only desaturated while down —
  the pack never once told you to press the buttons Ret and Prot press all fight. Each now
  carries a gold pixel glow wired to `onCooldown == 0`. Consecration and Holy Shock deliberately
  stay passive: Consecration is a mana-permitting filler for Ret and Holy Shock is a Holy
  emergency instant, so a "press now" glow would push the wrong button.
- **The cooldown row breathes with the fight.** All eleven icons gained the same
  `inCombat == 0 → alpha 0.5` fade the health and mana bars already had, and the ready glow is
  forced off out of combat, so the HUD is still while you ride around.

### Not changed in v2 (deliberate)

**Seal twisting** (Seal of Command R1 → Seal of Blood/Martyr in the last ~0.4s of the swing) is
the Retribution skill-expression line and is genuinely missing — it needs a Swing Timer trigger
and a design decision about how loud a sub-second window should be, so it is left for a future
version rather than guessed at. Also unchanged: **Threat** still paints held aggro red for
Protection (a tank's goal state), and **Consecration / Avenging Wrath** still load for Holy —
both would need either negated load gates or duplicated per-spec elements, which is a redesign,
not a fix. Exorcism, Blessing of Light, Divine Protection and a Holy seal-missing alert remain
uncovered; they are new elements, not corrections.

### Resources (the ring cluster, group offset (0, 140))

Since v9 this group holds a draggable cluster group instead of a bar stack; since v14 there is
exactly **one**, **Player Rings** at `(−270, 40)`. The cluster group carries its **whole**
screen position and every ring, flare and portrait inside it sits at `(0, 0)`, so the cluster
is one rigid object and the arcs are concentric *by construction* rather than by four offsets
that agree today. The parent chain sums to exactly `(0, −140) + (0, +140) + (−270, +40)`, which
is also why the Resources group anchors at the screen origin rather than under the character:
give it a drop of its own and the cluster offset stops being the canonical number. The cluster
stays clear of the Alerts column (x = −150, band −170…−130), the PvP column (x = +150 and its
icons at (200, −44)), the buff row and the cooldown row underneath.

**Player Rings.** Three concentric arcs drawn on `Ring_20px.tga` (a true annulus that ships
inside WeakAuras — the disc texture the globes used would fill as a pie wedge) around a 44px
**live 3D portrait** of you:

- **Threat**, 100px, outermost — added in v14, see above. Green, orange from 70%, red once you
  hold aggro, with `%threatpct%` at 10pt just above it. Loads in a party or raid only and,
  since v6, never inside an arena, and it hides itself at zero threat, so most of the time
  there are only two arcs on screen.
- **Health**, 84px, green — hot red below 30%. Since v15 `%percenthealth%` prints at 16pt in the
  **centre of the cluster**, on your portrait, which is the only surface in the middle with
  enough contrast to read a white outlined number against.
- **Mana**, 62px, blue — red below 20%, because mana is the paladin resource in all three specs:
  it is what ends a tank's threat, a healer's raid and a ret's uptime. `%percentpower%` at 12pt
  just under the health ring (the slot health left in v15), tinted to its own ring so it is
  identifiable without spending a label on it.

The cluster's children are ordered **portrait first**, then threat, health, mana and the flare,
because WeakAuras draws later children on top: the face has to be at the *back* for the health
ring's centred number to land on it. Nothing of the face is lost, because every region in front
of it is a true annulus whose band (26–50px from centre) never reaches the portrait's 22px
radius.

Health and mana fade to 50% alpha out of combat; the portrait does not, so your eye can still
find the cluster while you ride around. A red **Threat Flash** pulses on the threat arc's own
radius at 80%+ threat, gated to Retribution only so a tank at 100% is never nagged, and
carrying the same not-in-an-arena gate. The 140x9 **Swing Timer** runway sits at (−150, −76) —
a sibling of the cluster rather than a child of it, so it drags on its own — gated to Seal of
Command; the widened cluster reaches down only to y = −10, leaving the bar 61.5px of vertical
clearance.

There is deliberately **no target cluster** since v14 and **no mana ring for anyone but you**.
Your target's health was already on the target frame and the nameplate; an opponent's mana was
never actionable for this class in the first place — a paladin has no mana drain, burn or
punish (Judgement of Wisdom *gives* the attacker mana), so it would not change one paladin
button press. See *Still not built: an enemy mana bar* above.

Each ring is fed by exactly one progress trigger, because WeakAuras rewrites a v45
progresstexture's progress source to *Automatic* on import and Automatic reads the first active
trigger — health and mana can never share one region. That is why they are concentric arcs and
not one.

Every percentage belongs to a **ring**, never to the portrait: a `model` region cannot carry a
text sub-region at all (WeakAuras' SubText supports texture / progresstexture / icon / aurabar /
empty — not model). That constrains which region *owns* the text, not where the text lands — so
since v15 the health number is anchored at its own ring's centre and prints on the face, while
mana and threat sit outside the arcs.

### Buffs (icon row, group offset (0, 80))

Four 40x40 timers, left to right. **Seal Active** matches every rank of every seal
(Righteousness, Crusader, Command, Blood, Vengeance, Wisdom, Light, Justice, plus the 2.5.1
Martyr / Corruption pair) and glows in the last 5 seconds so you re-seal before the 30s window
closes. **Judgement Debuff** shows your own judgement on the target (own-only, all ranks of
Light / Wisdom / Crusader / Justice) so you know when to re-judge. The third slot is spec-shared: Protection sees **Holy Shield Up** with its
remaining charges in the centre and time at the bottom; Holy sees **Light's Grace** instead,
glowing under 5 seconds as the cue to land another Holy Light before the 0.5s discount lapses.

### Alerts (dynamic group, offset (-150, 96), grows upward)

Seven glowing prompt icons that slide in from below and fly off on exit; the stack re-collapses
itself as prompts come and go. All of them are combat-gated, so nothing fires while you are
riding around. **Seal MISSING** appears when no seal is up — one copy for Retribution, one for
Protection, because a single load gate cannot OR two talents. Holy has no copy yet; that is a
gap, not a principle (see *Not changed in v2*), and it costs a third element to close.
**RF MISSING** is the classic Protection failure alarm: Righteous Fury off while tanking.
**Holy Shield NOW** requires both conditions at once — buff down *and* the ability off cooldown.
**Hammer of Wrath** appears when a *hostile* target drops under 20% health *and* HoW is ready,
and re-pops every time the 6s cooldown comes back, which is the "press it again" pulse; it is
baseline, so it loads for every spec that has learned it rather than for Retribution only —
minus deep Holy, for whom an execute nuke is not a healing decision (v4).
**Lay on Hands Prompt** is the panic button for every spec: your health under 25% and LoH ready.

### Cooldowns (dynamic group, offset (0, -66), grows horizontally)

Eleven 32x32 icons (plus the three PvP additions) with WeakAuras swipe text, mouseover
tooltips and a 50% fade out of combat. Since v7 the row is split by how the ability is
pressed, not by what it does:

- **Press-on-cooldown rotational — always on screen.** **Judgement**, **Consecration**,
  **Crusader Strike** and **Avenger's Shield** are greyed while down and add a gold pixel
  glow the instant they are ready in combat. The glow is the instruction, so these can
  never be hidden.
- **Situational — on screen only while on cooldown.** Everything else shows up when you
  spend it, counts back down, and disappears when it returns; no grey tint, because under
  that display every visible icon is on cooldown by definition. Absence is the readout.

Only two are baseline for everyone — **Divine Shield** and **Lay on Hands**, the panic buttons
every spec presses under pressure.
Four more are baseline but hidden from deep Holy by the inverse gate, because a healer never
presses them: Judgement, Consecration, Hammer of Justice, Avenging Wrath. Five are
talent-gated and sit at the end of the row
so the shared part never shifts: Holy Shock, Divine Favor and Divine Illumination for Holy,
Avenger's Shield for Protection, Crusader Strike for Retribution. The dynamic group closes the
gaps left by whatever is not talented — and, since v7, the gaps left by whatever is available.

### Spec gating

No spec picker and no respec chore: every spec-specific piece carries a `Spell Known` load gate
on a signature talent, and the pack reshapes itself the moment the spell enters or leaves your
spellbook. Holy is gated on **Holy Shock (20473)**, Protection on **Holy Shield (20925)**,
Retribution on **Crusader Strike (35395)**; the talent cooldown icons additionally gate on their
own rank-1 ids (20216, 31842, 31935). Baseline-but-late abilities gate on their own id instead of
on a spec — the Hammer of Wrath prompt gates on **24275**, so it exists from level 44 in every
spec and nowhere before it. Threat pieces add an `in group / raid` gate, and every alert adds an
`in combat` gate.

Five elements go the other way with an **inverse** gate (`not_spellknown` = Holy Shock 20473):
Judgement, Consecration, Hammer of Justice, Avenging Wrath and the Hammer of Wrath prompt load
for everyone *except* a deep Holy paladin. There is no negated form of `spellknown`
(`use_spellknown = false` means *ignore*, not *must not know*), and no positive gate expresses
"Protection and Retribution but not Holy" — no spell is shared by those two and absent from
Holy. One aura with one inverse gate also cannot double-show on a hybrid the way one copy per
spec would. Audit any spec's real element list with `lua5.1 tools/spec-preview.lua paladin`.

v5 adds a second axis on top of that: every PvP aura also carries an **instance-size** gate
(`arena` + `pvp`, or `arena` alone for the pieces that read arena units or would flood a
battleground). The two gates are ANDed by WeakAuras, so "Hammer of Justice (PvP)" means *Holy, in
an arena or battleground*, and the Cleanse row means *knows Cleanse, in an arena*. `spec-preview`
does not model instance types, so the PvP auras show up there as ordinary extra entries — the PvE
per-spec sets are unchanged from v4.

v6 uses that same axis in reverse for the two threat elements: `none` + `party` + `ten` + `twenty` +
`twentyfive` + `fortyman` + `pvp`, i.e. every instance type **except** `arena`. WeakAuras has no
"not arena" key — the `size` load argument supports no negation — so the complement has to be listed
out, and `none` (the open world) is the entry that makes it safe.

### Regenerating

```bash
(cd ../../tools/tbc-weakaura-creator/scripts && ./setup.sh)   # once
lua5.1 generate.lua                                 # from tbc/paladin/
```

The script is deterministic: the fixed seed `20260811` reproduces the exact same UIDs, so the
output file is byte-identical run to run and re-imports in game as an **Update** rather than a
duplicate. It also runs `uidContinuity` against the existing `all-specs.txt` before overwriting
it, so future versions report `changed=0` for free, and since v14 it asserts the cluster's
**absolute** geometry against the decoded string it is about to ship — position, concentricity,
ring diameters and the Alerts-column gap with the alert stack projected six children deep —
so a drifted layout fails the build instead of shipping. v15 extends that proof to the two
things this version changes: each percentage's offset, size and outline, and the cluster's
**draw order**, checked in both `controlledChildren` *and* the flat child list so a half-done
reorder fails the build rather than shipping a number hidden behind the portrait. When you extend the pack, append new
`W.uid()`-consuming constructors at the END of the script — never reorder or delete existing
ones. v14 deletes three regions and keeps this rule by *drawing and discarding* their three
UID slots in place (`W.uid()` with no assignment, marked "retired uid slot"): removing the
calls would have shifted the player portrait's UID and orphaned it for everyone. Contains zero
custom Lua code, so the import dialog shows no code-review panel.

Importing: copy the whole string below → `/wa` in game → Import → paste. Note that the `/wa`
editor preview force-shows every aura with fake data and ignores load conditions — judge the
layout there, judge the behaviour in combat. If you re-import over a pack you have dragged into
place, uncheck **Arrangement** in the Update dialog to keep your positions — but **leave Display
ticked whatever version you are coming from**. Display is the category that carries the region
type, and from v11 or v12 that is what turns the globes back into rings and the two glass rims
back into portraits; unticking it keeps the old shapes while accepting the new positions, which
is the one combination that looks broken.

**One thing does need deleting, once, if you are coming from v13 or earlier.** Every version up
to v13 transformed its regions in place, so there were never any leftovers — bars became rings
in v9, rings became globes and the portraits became rims in v11, v12 moved and re-lit those
globes, v13 handed every one of those UIDs back to a ring or a portrait. v14 is the only
version that genuinely **removes** auras, and WeakAuras never deletes an aura that an import
does not mention. After updating, right-click **`Paladin - Target Rings`** in `/wa` and choose
**Delete**; that takes `Paladin - Target Health` and `Paladin - Target Portrait` with it. Those
three are the only leftovers, and nothing breaks if you keep them — the old target cluster
simply carries on drawing at (+270, 110). **Coming from v14 there is nothing to delete**: v15
adds and removes no aura at all.

## Import string (v15)

```
!WA:2!L33E0nY159PlPu9Uus27Yv7kZ16b0kTRjL1UcyaajOYkjdacUeuKGyhasURSIigamaZSCWmZoZasc6v21msom(vRPD9R04iZKOuBlNiXK6428qrSXQr1o9CpmNt78F9uwF8rT1hx5nPPXTPP97EVdagacsWD1UkIR(J9Yb3xZ9XVVFFF3V79olAQUZ98p0Y37gzfYnBEdn9OAkAgJ2zNDMStVNkOE350uTm0uueZhvswjVHO6dQFKKckc5Lv9CspjveQiA4HxwTOP(HRhFQ5Hy8KwUKOXMz1mYlAeX5fOFGikYlUOGrEpP10uSK1ZQlavRL(DwT4PJefQIWkkEsPlMZCnz1cAgLeSK1u7klR2KmQmrHcMIw)z7BvdXIqkPROlYx0qRS(QSSKsErXBzdHYwsAgtOtkSzxRXsI1jriuNzH(xb5IDXBMtqrStdHC0m2pVPLGHvxzliRkBk1ve4pwDTKLHCXIIgMjoHHZJFPiwK3RqzdbU1jHM6IkkY5npA3EJugkuwD6i0s04JN3SRnnlNvCoO)MQCHcYlS2mrdNk9mPshMpDTKsAicjXNkzSXg7YLnfJTa0UsXQHm8QcLen7A18IzHAG0Tngj2yjhEYXwPSQtZQR1YlBEHYQqVzorobff9dkqFonl9X1Yl(I30kcQYSH1(X3XWRlkykMYcMkkAj9EW9ervtvCJ8qFIKJzi9tdtry8kV5sKSsEZ4tgPKGS6W4hcka(K4tHFySx4VhU5ywNnWZMZ2)LLvTenufuMcQsOY)iRykQuiPgeD2OXsKog)XKZRFO6WjErtTYg5enx1sl3CScTVKhETcgWyb0MfSe68YcQ5GP6HjrrABztfLpwSeRXIMw54GCLLZVg)4jFYIbh889lgYbqexfAwDUkm(ZtbtWWllHy5lkQFWuxSmar9mCzasoTKSL4QKHbzgMkIIMq(UmwG13qlFVyun5hChpPEpBrAjPgaFeKT0pq9Kslzik0qmJikOyjTz9igxqvWTShRiEgwrWucFl4)r43dUF8(7c3Le(wpl(2W3o(9El43xx4dqr64d2fU7oXhcMQ7cF4UWhPl8DM4e43)xcMMok(da4v8DHVB890f(EXEW3h(y47pd(b6cFC8jWFWUW9I7d)GV4nH)qeOsZt3(ApaaZTFS)pcoaoim1I7epam9Hd1jEq8JG)fWbXNETcI5JfnWW8toDe8J1j(X7c)HXHXr6chTl8q)KdSS)1kbOwL4MtcIvziDyobDzj8qi8TIi1Hbn9zwab94AtaTS)ExK(ipvullBy2PVVeiSntzA9tgb2s3FDDNPUNutRugOdTo7DwqwrmEE8DVk7N6cqnE3S27mMwGSdAjdnlQGeYv0qt9X7kRKOCrjRZJJo1kKxFoy(0mtwlGps16i8LkdCKDXtJ9eznbAvfrJKHhl8qXtGFYJG)fZeb4wYDe8t2vetGYJ8Gle4sMIxSSOAoXob4bfe8(OiKpCKeG4n(24PTg879(Q3SkBEwagv)3glImeYphihjkD1p)dZ1p2D6mfTicZDRuiabmeZj2kUgAmw4hDa(5LZBjDEke50Rf6It7BQOJoS)CLiOi9dqZ7qYMec24GgcjEbfDjHobiJRH4fDxPvql)izHXyd4DX(lmdmeAnH8xOSPLy(XfwOJ6)qwTdhKL(DKx0uWIqfks0JruZOMxAntcvJ4cqcIzCNNH1aDsS8WBQiOAHwsunFyYu3ZEea1SPUHwrdrtZuuwTh8UUPoi9jxZqtIWkqp5robFojXCZom(935sZjyilKvrCflgxrol(5euklESb8Emn9J9ypQrojb1IIMh9e4lnkD6VFsGVoxcEFa7TvLlxOwlJQd8e4kKQgViVqriA8L6Kutp6JIFgADqk9GjVzOk4yHDI)y4pETcTgRHqBe4l1nTvCANYIGCQGF8JU8r072cgIMXusiV28NZHLCfACKG1pETUZXpU(bCL36AP1FOAzFgMPaZuRqZKxmhOfde6mGhikgqBYQKQQuIeEY0tOFiAKG5aAevE5MMGTIeg(5LzvR8cI5Pr(j2GPX48SMA51PPtWeYfQGdUkvqMoThjXejIPFF7qBJfr2eLlLv0a3JbOGHKXvP5ohT)rgyhGo8oyq6Zb6CfNkdSj6adBiVONZwwiprhNN0PBy00PjI2Gg38GgRPne0xAANh2Ow9qTsyIjtpwCObZgJBqTO(X3HobfUq1)ZxqrtZOE1smX6WodxvNzzdxZbZeaundE6x)QMYiBoa1otfYGsaFUjY1pai7g2rmLk1kPFWS1KlDKi1hioXkJcc5eFQW5ZpHQ5tnTOWSHjgP9uJlMxw4PCYP5trSFDgoV6lCkRIcuIPvPgasfzr4OFs85YSgHCgYhXeZmuffe6wj85jmUgojapFc8TNjcOJiFg8h5e4Nc)lYyPXpnLzEgiCoEWIxRkz40NdQjy82Qsjb1mCwIQzw1AEG2VsbWwnqha95m4tMPjDxRYMDiAcbffgffTaDvBsAt1tidrxEc9d4yMqkzRYufqunBnQwlBjzddndPMhyLvLW32LRswzXgTwsdmad4Cn7AfygwnpXws(iJflXqudG5RQNBtZsAAwsjDkDMvPmHdlByAjTMtDKtrwxIqWFzNkNaBjvO(DeDSWJNm9erglC0Ni8qdfpD8PaOB9zzh42LRhtn(ccIjyWLYPvsN8MLikzgg)XPIACbjKAHib(7KOus(11pyDwrheb(3e04S4ufTshq7C(SgbMEjwDkkTcTtqAHzJNiv8HITMMHmmjr7YReDSjI(ethpvmg0DbhO7(7YGwmX8sl)iynewNO1bFXoWgv1WGbt4GzSYs45q45PkjWlSt6fOCW3cEXLKvJQvkRGfq56M7Mz9dWbxJTEdGcih0uLyg8CPJ5Nqy39PD467KYWhKf2ip)kLajmNsTDS84Lq4Fj9dC8gEjh)44NJz85VmEz8Vc(tH)0Fc8NbH)SqF6ZH)NaO5vWFbIPkDI)I4)z6E3cjud1wly6XFje(lJ)k4Vk(RH)vbAS(AtnuNkd)RHF(m4V(9H)1rTG8RXsXIe)5Xt)nV6T)5BSvEm8Qs4FdaQrTf(3cOzMcOzy8jBh1bye7t7MiaNaprv72t2KrRnMp97Gqk4jQKazrUIgYG(SCMBxzRzV)VVe(FjqcG)U4)GUWFp8)k8)Ae(pmd(psc)htfCX)j4xb)NIWV6B8C41PsANXrsJHLcrvTXfIjR9nX)BOIwItpvY8k96pB(EXFFj8RH)3I)ZXVo(Fxnbg8p4AVOc(h2wzK1DM411Mh0xFPJX1GicT)eC7LtwcKtCkz3(2bXKlFC3VMwlKan9gLsyKAulecYKxaWVEVBh0Lw1nI3DjOayF9hyNlAnq)xVhImYdVZ5UfIMt)mVdry57wxiGpjD6ba9RqB3Krgud4)nikrRLwMwkkH)lVoi2mcrSbaKu5LabzgeYKAEghPMHkosYf0V4IthQVTxQXdveGu9utgETQn7nQBDayuxg8lHFzs7ETm4p6Xc5f6mGLL1m5JSAbblndyrfq393RfMmaVnEMbS0fA4JfqfqicFq)hKwVndh16erYVhhOgNSE(wJkkG7jlrDnykd53qY)OvPlOlzzftXLQ6hQU9rlYwGm6hmVSzodrlXzQTs7gGpBwf7a0fWGQJJiItyxu6C16RDtIqCC61gl0yt3F0Z1Be9c18rX0VEwMX)s4OVa(FHJTE4Vzvyid5bOYxOrt)OgMrDa4SQAZRMb)BlTA9FUVpvuMvH4Vvg83od(fZG)ozW)ozW)Uud)KF9L9c5wWyw6Qto8QY50uzRB8UUj8qk7hFR)WBM082GMPAMFPFWg(nXKf8YrifwQjJjXjwZL7AjGchhHaRMmpfGhH8e2xtqaAlXzvmuD4m)7SuwbhhSwNYIf2pS(X3qADA7Iz(25r4h)bpcUN1iwocLBg4FZH7zfyDsm)VTb7poRwHdsUAmAol3W5N5QTyrh)nxBjioU4BgX8ffXHR(lIT7DIN(q4OZrMX(V34Cydek)K9nXxMXNSjTPhPQvV4)lesP3dUF28t06JeGear83WPBbWF396ZHwHo0zkdwoZh)mJK(QNP0feFn6RyeQ3KEu8M8rvefubWn7vxDvr9wFvrrfaBaulgrW4PMm(jR)RtMIICOftQMBAU5ilQPvcrzK(Z2NJxzwC2I91R)yPdhPcqj50cKZNxuLprSPIXJ)ZxDKj4J)KtKiD4XWroAnDLBkUGUmtKMa7WxId4WCRZKzqky(a1dgGc0)gcb3RsTVhIAGM8Z6OnS7dGDBEctD4T(rRh9OLbiqjqNLNHO(ox)97YBRAkv8KsswujVNj1D7M1XiJNMEody2KOJBw3xv3S(nEhTBwVC9oreO7A2cNUgk4qLMLBWI(MNBRoDfT89J)PesMh6MDS9AJCAAk5bslGWa0oUE1FsCtUe(NLPH(6ZFcEoV(cgGNZN3qqOxUqdqddrdhKeoOxAOpAihn0pp3a(cgKwksm(6Ne63BqAy)0WbOHHO5KuB(hGK6G(yHHOHK6FqoVK8mGxE)(cb1pe61hToP1tqw4aK8qJXx)03saA9hGwZbgKMQxAQbO1tWSqAd41l7pb2vtO()ixEwrr9WeF1AXtW9su7vFdj8J)i)h2OOI28dBWCvBf26uJqItADGi(mkoodtAfsCPOBv1QKhhJUznhEnYZvDgenp15IOPv15mmxqrIH(gtljNBwvyjYDUe9NGfpBKTSLLM6eS1NtRRXKHSCq67lcBZ3w(qu7yp2X1VswFxdlwB94jseJFMitKo9eJJ)63nyJjyukyea(NJ)7q4)VSQ9Vpd()hoSn6MaQ6ZU7m572W)mI0iaTp7O(cohFjUlEb87XgDN4)Z0wIn62Ol(FPQy3mvz4Srhs)oQglHUCiztI)wbDGeoVZ6iusK06HzHIJqztXC4TedWja2R5MtGib6In0gDqyndbDZ)Lb)Xi7h1P8DkYapHWrPZQYJkv3YdBupzSrhTUO3l4i61nbUgIbMdqdzp3pfmtfRcXa)0ujIBdqG3C(8fYpnvk43RxAOpAitmKjEoinpmXH(nGXRjuvQKbKeE5wijymsy(XhEYXAuEWgf2TiGnkcd3BJIkzJgc(xmyYA4dBJodYgnIZKxCadBJg1g9eWpgZgnUnkXbTrtCTatAJsEDbjgrqmW5ZzLtspuRqI2iExyW7WgL66fGRRgHrNC7qroe4JszqPCQCdqdPmUdm4UKXRHz4rV2ndBEvpdd5G6Yhyc(AfE5o3v4LDHrMN9pUzCZteTy4fvV405vJ0ECZHFNdU5OeAb)bUAqj714b2nlE4N388AICLdn5zoFVj16R9ZRh5648A7uazJs7mZ7nsrGL)ytMe3X3s)UAYs7XJNkv8eNXtV8Iw9PF3BxQjHfp3N(D46uDmC1eDFijCBjEIjMUHKekbRq1JwbptdlDqY9RAmHkE0uHCOM30d8MkPB5(aKKEEztlA11D9iJg1Zej8mEm3TPrcp(4X4P58oDv8W8NjwApXhF8jteJUia6cVFvQv0md)jlxkN4T)w1Y)1GfYwUKAksLXwrDwMns8ckYfvXbnmTeihHhYrhGyLE9fbzWoopIzwcMQCQGU7CLIgYSn28wP77pyE)TTE(kQcLKZr3Yky5lrm1mSWNCjswjgbEm(H4vKljBDRe)amg5jPSgWyrzZN922ew6k0guTgwiNLMrw(WdfFYuRiyKJzn6ZEeyriRwOSIsuzJCK9a0bl7(WTewr0WYK4QfNLJqwufSaKR619acwaiNXuD61sx8CtVOx)jNoAXLFa8pfv)qISTwmDcB0hWgDx2O72gDp2O71g5XgDF2OJzJUFB0dyJoUncYZh0g1RnQpB0dAJ(q2OhYgDsB0PSrpSnYRnYNnIZgbsWbSrWRQFB0a2Oq2ObTrpIn6xWgDAB0JAJEmB0JBJ(WBaZw5KentjPn)eQBys)Z4YMKd5Xvd55dwN80HCCiOVogFs5fevAGcTbFytitbY2mmIwcFkJjTnuFFshQpgPhLaCv65xHUDuzAMg0XlxuAqYPtJESnaOK(jQ7qcYVnFkQRXMrcObMXeiq0kKvrtlpJ6KZ)WIYxuAo(PQqOo)CBL6uQo1PrtuNKo0pc71GC61MOSf1hJRzQiNxmRgSONs4Fmhuhuivlivx(aRqpKG0vjzsofqfLSORfd3t2CLnHkilndvinLayao8LzrSalIFC3(Wki6z8HgDMURKF)DVaAfQBojv7svRwYlFd4zvtfYznass)GvtlD1OHwgZPUvJidTUP1wM2Pk)DUsf2O)P2Op)1q8VnAfxG)3SJEU2b4TrFHm7KDC2OVO(93m(wiRSISvLzSKkRcRMoRMIfdC3hFXHJjEH0I(92EWTzRb3aOJIRTrFf8p2g9v3E0Sn6RzJ(vjdu)ZTr)A1XS2OVUB8Qn6xVkq1g982OVbPQSrRAJ(nGkZg9BcdJ)wxJGBhLNl4aH8EJgc44TLHRqzJkmmGVjup7z8ho0Gg7cmG1nkyGNUogaMZUGnAwBeOXQu7rcqbx(G8afyUzJqoCx6hKWbwuuv0qohtXAMnA4NRX0ZYlkKVcDNaPZgjekjsM46HN(tN9mVNOoUdYt1JXINEPNd7(07MECGkQQzisomlGLtIz2auTOKQA1TMllz3O2warsHE0CiTF2MhUIdlEUzZOFiYZIKZ7T7S)weX3OV0F7f8)W7a4pRIi1yhTc6WAdePN9EMyWqZfk9qgvkD2fc0EXGY3OigO6EdBX)fhJZRZ574Lz7khfVKmddJ3WzujJ(rA8mRuDhC7(0UfuSrFBB0lAJ(oW783Xg97sW)2OxAFp9FjPZ)YmuVnAnB0VhKJF)l30cUSrF3MGU2O)aiJFVmSxaDN2PqDjntlQwUmU2YCIVbxPwkgSNe3(nr)QJC)5UkX3VqR8NhfYVPQMLR9Vfwrpt6VXODKmOYe)eYi6vKva5ue0zq)P9VGVSIbdgyQrAp0FUBK0a0a0pyTJ2KBOVn6pe(3F0Ucv)f)GTeuVUBxfSJi63ACU0zl6wv25vlLBHAEzERmTn5P52zNbSAlnvY24BYqzfxmBVpzVdu48vc3Eu283iHYCFqEUSd46VIrb9xx7mou3VnxyRlN56MLPTupT01h90vptdvbpFOTJGsN50MTUw8E9BoWf8D(bhplF7Hql82NBmTrDVT(X8byEWEBxiYCuWHZCBvsHe6hiQH2859eT2LHKmHVR8I914LHCn2721zz(TL25TZ6e4VDgEY90uitveZ244gvYbPICg6uQusZqxIbwsN23yLgvirOEhU9GLk7j4B(A1Vimo3sw6vI8srsLEYenCpAA(SvF56BSBJxdhB0)E8L2Gu(zgpw0rcNiEu3v0B2zucyg3y(JmCSW8B5E7ma7iU3zlkWgKcSnVGXAr(nIorIHNmvST8oc4CTviEFUvVOi8tmr6TuQQkfB1Bkv8XILiASTo6fI(w4Az3jz4OXh(8TOOVzNZ0I8RFGurhzIjgBM4KBAk)Kjt3QYCfAYIE3gIKRcl5IK4Y27erihRkITVRulDoFNkiqXqTtUwKzA1X3(1CzaZgHPlpYZK0ZKaXcfWwg9dw3c9rj3qPCITYIgIDpVu6GV1zSEU)HJXQhxmwvvXvJ0QvB8g0FRsCzJ(bTJ1YLZykr9alZDZ9zCM(pB2rp)cNR9SwlUNG16O1op8RZUt6Q8KlnythnEqPj(n2f6mF66gk9146paxeFE58sc4Iem4GdYdpnqi(abd4peVFFCCb49hiWa(49n4ab52MJlsv0pD1K2O)KMxcPn6vSr)P76Ln(oFLX9C1Om2nM(K7aMoV8CYQI0lCp5(oxZdlfUyFcfuImRXWLBp0(JUNAbaqfFrB0bWD8FR(54m6qUpaO13uzA8GDDMI5yNgv97PHK2c)Q(hOH0dddQfjhEA2osF0gsCi6yVJlaB6D6EvO13Qz27K53qTCZ2uzCQVHfMdmSYtRskUIs5sYQSEYDV1wQOXh0SA75UACmWOSPqEORMYYqEwXMQ(ioEQJmqmSHOyETs63)2MJK18MN(dSZJME6n5Cj7JTJ6abZdDZU2rDB0L2)B1Tt3g9mvpx62Opoj4F8w34CB0NawK1sKDl3g9lvFBYTrpl(9El2ONddl)7tEm(HSr)Y3QnAziZ)kplK6NYg9PTrFg6gEBJ(S13OBxh8GQoq(63EDpzHacdv4S(6nCQ2sv3KVswL4k8WkZluXSQNaN4HBPttwPMOt78b4v29K5TMl(UIwACy2P1XgTEnFQ8QKdNZo5vfYgA78vQjdJ2CUlMo8fsyfqoSjH28VBhp7o)uG2uIsBg(A(IEFKAg1UQMAvuwtxGFQw86g)2rhBvlpS04wFb5EWgVGCxsA3Um6NUv(K7VVk(Q4FrRDkNBk43vbXS74MCGwZwPOSLs)Pgp55Ap06)XBlqlkK5DKqQnz7IxnGpdELoylrx2O)tVDHPUkp1Ix)qvXsQpAzXrMAA)91Eu1BEDevD0DXfX9QKEPJBPk9YL(mTeaSzJMP9UxWGPCHXYQ1NvLfApy4NThhm8a92sSWgnyv(EBOWU8AiuhaS4i8pr0fMTWfsov7baxEpoayB2aqB03)DzZ6vuZhDQZRo(5sfS9Z6)v711baSHTAAF16lREVp))vWDoOomO)ZhBaHy6lYnr)Thg8xVxhgK4VT1R0WTtuUHhiadcTaimI68bRenxUsH1Bpq4)5EEBcZ2sGG(HAHpZUHhqadgTaqCr)9MtCmVthBQrBpG4VzVjGOUpiU0R0AaXbA2fP71Der7WcVsRWcdE2rJ0FiZ4(9oD7Xc)VExUBiCHQ(urB9zOSjhRFdoMY918PoMsl9f4NsX)SHLY2Em1F772Xu1uDnu4TrZvl2oM92AU2v7OpmCSLD)Sgel3Sx4mxyXk(e091Ei2pFpUnn)OhV1aJJ06DH7Dbydyez7XggtnDOPTMus8j3fU96)9ECSXnQ(aFxbdQUY3wJde9oKUEIrMCGr3f(b5)Z7mWbKdZqKHMy6eKVXvU)6)BiRoROLhssUVQ6XuflvPAQU)OynSMrwrbdYNXD9d6AdQhlw4ePCUu75B6sTBJU0TFnBl45sprYDCt4ZCTCt43W1)TlmxYRB7((uPI0)tm2CPsmj3YhF7pRGFmY5zAjzlXs0lA2x4nidzerxCc93FlUKzXHC2h7WP7iCddVRtVYzo1rgCprip768sz3X9VVVW)161SDhpqZvHDhhhkODhNOPIf)LUQkM5x5kQy4E5euRSf2JmVnWECLFUQawdYzRQVMpBvXtm1mJkoVOIrLzCeZsovYz86JXXOhmzb(e8PnJSiWX0X9TtCmDCxxh5y2Lx9wYjynHHZ)90Cu(aCCdYrLN)XC(i3)m97GEHg9qohREsvoxorYNgCYbZ7hSwTl1y88zEhLUID1S9rCFe621tZCoNN95616SNT)fpZesTFA(UFByA((BZnB41Oh2NOkAQIMzCDDRhW3A6IgKVn0KpPLljuOayZizcgF7Bs(uoiRkMKLEMwW0BJK2t818PN2)18j(vkSX5abPzfuBaFLclwO9aH7P25Om()WbeS7WNda45VpY37nEFCH4cqddsd7NhcgWhnKlsWbcXfPFoF(jbbJeYhhhjakG3qHcrch0BKGbcbrmWGqr87FWi(82puqFdgKe0FKbdfKJe4NNR)bdniVp)CKxRFoooAOFAyaYhxSqdgXFaVdciZqEHh96hQ2aCdmijme5J5OxFHS7WVDhKpVu3UDhbFlHk3jNK8FC7oqWV9Ij3DM9EOpARWMIx4C8(I17fdKA82JnV3R)yZUl1D(UZV8904)dzH73gDN2OphyqoPn6CwqjFEv)H7R63x19x77RkZ8R3QFFvjMwYT)REJaD(8rVpNVM0Koj9JR6PxRGu08JwYyYXZEgYhcwWm3hRtNpOQG0y3M8(pvWt5T75U5N5))
```
