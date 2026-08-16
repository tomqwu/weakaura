# Paladin — TBC WeakAuras (All Specs v16)

One import string covering all three specs. Elements load through Spell Known gates, so
the HUD adapts to your talents with no action from you.
Toolkit setup, once: `cd ../../tools/tbc-weakaura-creator/scripts && ./setup.sh`.

## All Specs — v16 (`all-specs.txt`, seed 20260811)

The full Holy / Protection / Retribution HUD: 45 auras in one import, arranged as a top-level
group at (0, -140) with five draggable sub-groups — the fifth being the PvP column added in v5,
which only ever loads inside an arena or a battleground. Every trigger matches by spell ID
(never by name), so it works unchanged on a zhCN client. `internalVersion` stays 45 /
`tocversion` 20501; modern WeakAuras migrates that forward on import.

## v16 — The Sill: the ring cluster becomes a 102×31 instrument under your feet

**What changed:** the three concentric rings and the 3D portrait that sat 270px to your left
are gone. In their place is **The Sill** — a 102 × 31 px strip directly under your character at
absolute **(0, −110)**, built from three 100px rails stacked on a dark plate, **where one pixel
is exactly one percent**.

```
                       your character
     +--------------------------------------------------+
     |===============================...o...............|  threat 100x4   o = the 70 notch
     |############:###########:############:# 78        |  health 100x11  : = 25/50/75 ruler
     |#########!##:#######....:............:. 41        |  mana   100x11  ! = the 20% floor
     +--------------------------------------------------+
      0%                       50%                   100%
     x -51 . . . . . . . . . . . . . . . . . . . . . +51    y -91.5 .. -122.5
```

One character above is two pixels: threat at 62% (short of the 70 notch), health at 78%, mana
at 41% and still well above the floor. At 80%+ threat a 3px red rim lights up around the outside
of that box — a 108 × 37 quad drawn *behind* the 102 × 31 plate, so only the part that sticks out
is visible and no number is ever painted over.

No aura is added and none is removed — all 45 keep their UIDs (`changed = 0`, `missing = 0`),
so this is an **Update**, not a second copy.

| | v15 | v16 |
|---|---|---|
| shape | three arcs + a face, 100 / 84 / 62 / 44 px | three rails, 100 × 4 / 11 / 11 on a 102 × 31 plate |
| position | (−270, +40) — open screen, left of centre | **(0, −110)** — the centre line, under you |
| footprint | 10,000 px² | **3,162 px²** (3.16× denser) |
| health % | 16pt, centre of the cluster, on your face | 11pt, **inside the health rail** at x +32 |
| mana % | 12pt, below the rings | 11pt, **inside the mana rail** at x +32 |
| threat % | 10pt, above the outer arc | **off** — replaced by a notch at the 70 line |
| breakpoints | one arc-mark, placed with `sin`/`cos` | full-height waterlines at `x = v − 50` |
| pixels spent on decoration | 1,936 (the portrait) | 0 |

### Why a strip instead of a ring

A 0–100 quantity has exactly **100 distinguishable states**. A 100px rail carries all 100 and
not one pixel more — that is the exact length at which the gauge is lossless. The rings bought
712.5px of arc inside a 10,000 px² box to show the same 300 states, and 19.4% of that box was a
3D model that decides nothing: no paladin button press follows from looking at your own face.

It also makes every breakpoint arithmetic instead of trigonometric. The old 20% mana mark was
`r = 62/2 × 0.94; x = r·sin(2π·0.2); y = r·cos(2π·0.2)` → `(27.71, 9)`. The new one is:

> **x(v) = (v / maxpower − 0.5) × 100**, i.e. **x = v − 50** for a 100-max resource. 20% mana
> is at **x = −30**. That is the whole placement system.

And the numbers finally have something behind them. v13/v14 hung them on open screen; v15 moved
the health number onto a 44px face to give it *some* contrast. v16 gives **every** number a dark
bordered plate of its own to print on, which is what makes 11pt survive a snow field, a lit
floor and a Netherstorm skybox.

### The three rails, top to bottom

- **Threat** — 100 × 4, the thinnest lane, because `threatpct` is an early-warning *ratio*, not
  a quantity you spend. Green, **orange from 70%**, **red once you hold aggro**. A white
  **2 × 4 notch at x +20** marks the 70 line: when the fill touches it, stop or dump. Party or
  raid only, never in an arena, and it hides itself at zero threat — so solo, this lane is
  simply empty.
- **Health** — 100 × 11, green, **hot red below 30%**. `%percenthealth%` prints inside it at
  11pt, x +32. Three faint hairlines at 25 / 50 / 75 turn "estimate a fraction" into "count
  quarters". Fades to 50% out of combat.
- **Mana** — 100 × 11, blue, **red below 20%**, with the same number and the same ruler, plus
  the one genuinely new signal in this version.

### The mana floor is now drawn, not only coloured

A decode of the shipped string says something worth saying out loud: **`percentpower < 20 → red`
on the mana ring is the only power threshold in the entire pack.** Nothing in the Alerts column
fires on mana; no other aura in the string even carries a Power trigger. For a Holy paladin,
whose whole game is mana, this rail *is* the mana instrument — and a threshold you can only see
*after* you cross it is half a signal.

So the mana rail carries a permanent **3 × 11 waterline at x = −30 (20% mana)**, in a bright
red-orange chosen to stay visible *on top of* the red the rail turns underneath it. You can now
watch the floor coming from 60% instead of finding out about it when the colour changes. Prot
and Ret will mostly ignore it; it costs 33 px² and never moves.

The mana number also gets lighter — `(0.55, 0.75, 1)` → `(0.82, 0.90, 1)`. The old tint was
picked when the two percentages were stacked outside the cluster on open screen and the colour
was the only thing telling them apart. Printed *inside* a blue rail it was the lowest-contrast
choice available; the rail itself now says which number this is.

### What you lose, stated plainly

- **The live 3D portrait is gone.** Its UID is now the Sill Plate — the dark panel the rails are
  drawn on. That panel is load-bearing rather than decorative (it is what makes an 11px bar and
  an 11pt number readable against a bright world), but it is not a face, and this is the change
  most likely to annoy you. v15's own notes argued the opposite case; that argument was about a
  ring cluster, which no longer exists here.
- **The threat percentage is switched off**, not deleted. It keeps its sub-region index, so it
  is one checkbox away in `/wa` (select `Paladin - Threat` → Display → the text sub-region →
  tick it back on). It is off because `threatpct` is scaled so 100 = pulling aggro: "is the fill
  past the notch" is read faster than "is 68 nearly 70", and it was the last element of the old
  cluster printing onto bare screen.
- **The numbers straddle the fill edge.** With a left-to-right fill and the number at x +32, the
  edge passes under the digits at about 82%. `OUTLINE` + a black shadow + the plate are the
  mitigation. Judge it in combat, not in the editor.
- **A ring is prettier than a bar.** Three stacked rails are a car dashboard; the old cluster
  was a character. That is the honest aesthetic cost of a 3.16× density gain.

### The ≥80% threat alarm is a rim around the strip, not a wash over it

`Paladin - Threat Flash` keeps its UID, its `threatpct ≥ 80` trigger, its Retribution gate, its
not-in-an-arena gate and its explicit red `(1, 0.10, 0.10, 0.85)` on `ADD` blend. It is now
**108 × 37** — the 102 × 31 plate plus **3px on every side** — drawn **first**, at the very
bottom of the strip's stack. Only the 3px band that sticks out past the plate reaches your eye:
a pulsing red rim around the whole instrument. Everything inside it sits behind a 45%-black
plate and behind every rail, number and waterline, so **nothing is ever composited over a
readout**.

That construction is forced by the art, and the art was measured rather than guessed.
`Square_White_Border.tga` as WeakAuras ships it is a 256 × 256 32-bit TGA in which **64,516 of
65,536 pixels (98.44%) are fully opaque**. Every pixel inset 8px or more from the edge —
57,600 of them — has alpha 255 and a minimum RGB channel of 167. The centre scanline's red
channel over x = 0…13 reads `0, 156, 100, 56, 40, 57, 102, 158, 206, 236, 250, 254, 255, 255`,
and the centre pixel is `rgba(255, 255, 255, 255)`. In plain terms: it is a **filled white
square with a dark bevel baked into its edge**. It is *not* an outline, it is *not* hollow, and
its interior is *not* transparent.

So a single region on that texture cannot trace a frame. Drawn at the plate's own size, on
`ADD`, on top of the strip — which is what the first cut of v16 did — it is a full-area red
quad over every rail and every number for as long as threat stays ≥ 80%, washing out the
readouts at exactly the moment you most need to read them. Making it 3px bigger per side and
putting it **underneath** is the fix, and it is the right one whether the art turns out to be
filled or hollow. The build asserts **both halves** — `alarm.width == plate.width + 6`,
`alarm.height == plate.height + 6`, `controlledChildren[1]` is the alarm and `[2]` is the plate
— because dropping either one silently turns the rim back into the wash.

### Where it sits, and why it fits

Absolute **(0, −110)**. The plate is **x −51…+51, y −91.5…−122.5**; the alarm rim, which is the
widest thing the instrument ever draws, is **x −54…+54, y −88.5…−125.5**. The collision scan is
run on the **rim**, not the plate — verified by decoding the shipped string and projecting every
region in the pack, with all three dynamic groups grown six children deep because they grow
without bound:

```
scanned envelope    108x37 (the alarm rim), x -54..+54, y -88.5..-125.5
173 projected rectangles, 0 overlaps
tightest clearance   8.5px  (the buff row at y -80..-40; plate alone: 11.5px)
cooldown row        64.5px  below (y -190..-222; plate alone: 67.5px)
alert column        76.0px  to the left (x -170..-130, grows UP without bound)
PvP column          78.0px  to the right (x +132..+168, grows DOWN without bound)
swing timer         26.0px  clear: it runs x -220..-80 at y -71.5..-80.5
```

Nothing else in the pack moves by a pixel. That scan is not a one-off — it is re-run inside
`generate.lua` against the string it is about to write, so a future version cannot slide a row
into the strip without failing the build.

### After updating

**Leave the `Arrangement` category CHECKED in the update dialog.** This version re-parents,
re-orders and moves the group — all of which travel in that category, and none of which arrive
without it. If you had dragged the cluster somewhere you liked, you will have to drag the strip
there instead; if you leave Arrangement unchecked you will get a 102 × 31 strip still sitting at
(−270, +40) with rails in the wrong draw order.

There is **nothing to delete**: v16 adds and removes no aura. Two are renamed in place —
`Paladin - Player Rings` → `Paladin - Player Sill` and `Paladin - Player Portrait` →
`Paladin - Sill Plate` — and WeakAuras matches by UID, so the rename applies on Update.

### What did not change

Every trigger, every load gate, every condition and every escalation colour on the three rails
is **byte-identical** to v15 — diffed field by field against the shipped v15 string, not
eyeballed: the Threat Situation trigger and its `threatUnit` argument, the party/raid and
not-in-an-arena gates, the 70%/aggro/`threatvalue ≤ 0` conditions, the health 30% red, the mana
20% red, both `maxhealth ≤ 0` / `maxpower ≤ 1` guards, the out-of-combat fades, the alarm's
80% threshold and Ret gate, and the three canonical colours. The other 38 auras in the pack —
buff row, alert column, cooldown row, PvP layer, Swing Timer — are byte-identical tables.

The two deliberate exceptions, both listed above: the plate gains the Unit Characteristics
state feeder and the `inCombat == 0 → alpha 0.5` condition the rails already had, so the whole
instrument dims as one object out of combat; and the mana number's tint is lightened.

The Swing Timer's table is byte-identical **except** for the two sub-regions v16 appends to it,
which is the next section.

### The twist window is now a mark you can see coming

The Retribution swing runway told you about the twist window only by turning gold at ≤ 0.4s,
with the `Paladin - Twist NOW` icon glowing in the same instant. Both of those fire **inside**
the window — the moment you needed to have already pressed. So the runway gains two things:

- **A gold tick at the 0.4s line**, so you watch the fill travel toward a fixed mark instead of
  waiting for a colour to arrive.
- **The exact time remaining, at one decimal**, right-aligned inside the bar. A 0.4s window is
  not learnable from a bar edge alone, and at zero decimals every value inside the window
  displays as `0`.

**Why the mark could not simply be drawn at a fixed offset.** The twist window is an absolute
0.4 seconds, but the runway's length is your weapon speed. A hard-coded pixel position would be
right for one weapon and wrong for every other — and wrong again the moment Wrath of Air or
Swift Retribution changes your haste. It is the kind of defect no screenshot reveals: the bar
looks correct, the twist just misses.

WeakAuras' `subtick` sub-region solves it natively. With `tick_placement_mode = "AtValue"` and
`tick_placements = {"0.4"}`, `UpdateTickPlacementOne` re-reads `GetMinMaxProgress()` on every
update, so on a timed progress — where the value is seconds *remaining* — the mark lands exactly
where 0.4s are left, at any weapon speed, under any haste, with nothing to recompute on a respec
or a weapon swap. The build asserts the mark's placement against the same `TWIST_WINDOW`
constant that drives the gold recolour, so the tick and the colour can never disagree about
where the window is.

`subtick` is **aurabar-only** — `Tick.lua`'s `supports()` returns `regionType == "aurabar"` and
nothing else. This runway is the pack's one aurabar, which is exactly why the mark can live here
and could never have gone onto one of the Sill's progresstexture rails.

### Honest limitation: this raises the client floor

`subtick` did not exist in WeakAuras 3.5.0, the data version these strings declare. It renders
on any current client (verified against the installed **5.21.10**) and is simply absent on a
genuinely old one. Nothing else depends on it — the gold recolour at ≤ 0.4s and the glowing
Twist NOW icon both still fire — so an old client loses the early warning but keeps the cue it
already had.

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

### Resources (The Sill, group offset (0, 140))

Since v9 this group has held a draggable cluster group instead of a bar stack; since v16 that
group is **Player Sill**, at absolute `(0, −110)`. It carries its **whole** screen position and
every region inside it carries only its lane offset, so the strip is one rigid object and the
rails cannot drift off their own plate. The parent chain sums to exactly
`(0, −140) + (0, +140) + (0, −110)`, which is why the Resources group anchors at the screen
origin rather than under the character: give it a drop of its own and the Sill's offset stops
being the number it says it is. `generate.lua` walks that chain in the decoded string on every
build and fails if it does not land on `(0, −110)`.

**Player Sill.** A 102 × 31 plate (`Square_White_Border.tga`, black at 45%) carrying three
`progresstexture` rails drawn on `Square_White.tga`, filling **left to right**
(`orientation = "HORIZONTAL_INVERSE"` — on a progresstexture, plain `HORIZONTAL` drains from
the right; this is the exact opposite of the aurabar convention the Swing Timer uses). Every
rail is **100px long, so one pixel is one percent**, and every mark on it is placed by
`x = v − 50`:

| lane | region | size | local y | reading |
|---|---|---|---|---|
| 1 | **Threat** | 100 × 4 | +15.5 | green → **orange at 70** → **red on aggro**; white notch at x +20 = the 70 line |
| 2 | **Health** | 100 × 11 | +7 | green, **hot red below 30%**; `%percenthealth%` at 11pt, x +32; ruler at −25 / 0 / +25 |
| 3 | **Mana** | 100 × 11 | −5 | blue, **red below 20%**; `%percentpower%` at 11pt, x +32; **20% waterline at x −30**; same ruler |

Threat loads in a party or raid only and, since v6, never inside an arena, and it hides itself
at zero threat, so solo the top lane is simply empty. Mana is red below 20% because mana is the
paladin resource in all three specs — it is what ends a tank's threat, a healer's raid and a
ret's uptime — and that one condition is the *only* power threshold anywhere in this pack,
which is why v16 draws it as a permanent line rather than leaving it as a colour change you
notice too late.

The Sill's children are ordered **alarm rim first**, then the plate, then threat, health, mana,
because WeakAuras draws later children on top (`FixGroupChildrenOrder` adds +4 frame levels per
child). The rim is `Square_White_Border.tga` and that art is **filled** — 98.44% of its pixels
are fully opaque — so it cannot trace an edge by itself; it reads as an edge only because it is
108 × 37 against the plate's 102 × 31 and is drawn *underneath*, leaving a 3px band proud on
every side. Put it last instead and the same region is an `ADD` red quad over every rail and
number. The plate is second because it is the surface everything prints on *and* the thing that
hides the rim's interior; the three rails come last, so no readout is ever drawn under
anything. The flat `c` list in the import string is depth-first in the same order, and the build
asserts all of it.

Health, mana and the plate fade to 50% alpha out of combat, so the instrument dims as one
object. The red **Threat Flash** rim pulses around the strip at 80%+ threat, gated to
Retribution only so a tank at 100% is never nagged, and carrying the same not-in-an-arena gate.
The 140 × 9 **Swing Timer** runway sits at (−150, −76), spanning x −220…−80 — a sibling of the
Sill rather than a child of it, so it drags on its own — gated to Seal of Command; it clears the
strip on both axes and the build proves it by name.

The strip clears every other row in the pack with all three dynamic groups projected six
children deep. The scan runs on the **108 × 37 alarm rim**, the widest thing the instrument ever
draws: 8.5px to the buff row above, 64.5px to the cooldown row below, 76px to the Alerts column
and 78px to the PvP column, with 26px to the Swing Timer. On the 102 × 31 plate alone the same
four numbers are 11.5 / 67.5 / 79 / 81px.

There is deliberately **no target cluster** since v14 and **no mana rail for anyone but you**.
Your target's health was already on the target frame and the nameplate; an opponent's mana was
never actionable for this class in the first place — a paladin has no mana drain, burn or
punish (Judgement of Wisdom *gives* the attacker mana), so it would not change one paladin
button press. See *Still not built: an enemy mana bar* above.

Each rail is fed by exactly one progress trigger, because WeakAuras rewrites a v45
progresstexture's progress source to *Automatic* on import and Automatic reads the first active
trigger — health and mana can never share one region. That is why they are three stacked rails
and not one.

Every percentage belongs to the **rail it measures**, as a `subtext` sub-region, so it appears
and disappears with its own bar: no threat table, no threat lane, and nothing left floating on
screen. The breakpoint marks are `subtexture` sub-regions on the same rails — `subtick`, the
tick sub-region, is aurabar-only, while `subtexture`'s `supports()` does list progresstexture.

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
**absolute** geometry against the decoded string it is about to ship, so a drifted layout fails
the build instead of shipping. v16 rewrites that proof from the ring canon to the **rail
canon** — it does not drop it — and widens it:

- the Sill group is walked through the real parent chain in the decoded string and must land on
  **(0, −110)**, and the Resources band must still resolve to the screen origin;
- every rail must be a **linear** `progresstexture`, exactly **100px long** (one pixel, one
  percent), non-square, drawn from `Square_White` on both layers, with `backgroundOffset = 0`,
  `compress`/`slanted` off, Automatic progress, and an exact sub-region count — because
  sub-region indexes are positional and conditions address them as `sub.N`;
- the plate must be **102 × 31** and the alarm **108 × 37**, concentric at local y +3, both on
  `Square_White_Border`, and the alarm must carry an explicit **red** four-component colour (a
  texture shipping `color = {}` draws in WeakAuras' default);
- **the alarm canon**, which is the pair of facts that makes the ≥80% warning a rim instead of a
  wash: `alarm.width == plate.width + 6` and `alarm.height == plate.height + 6` (3px proud on
  every side), *and* the alarm is `controlledChildren[1]` with the plate at `[2]`. The texture is
  filled art, so either fact on its own is worthless — drop the size and the rim vanishes behind
  the plate, drop the draw index and it becomes an `ADD` red quad over every readout. The build
  also re-checks the alarm's `ADD` blend, its `threatpct ≥ 80` trigger, its `alphaPulse` and its
  Retribution gate, so the fix cannot be undone by a "harmless" edit;
- every number must sit inside its own rail at x +32 with `OUTLINE`, and a three-digit number
  must still fit;
- every waterline must be at exactly `x = v − 50`, full rail height, in its declared colour;
- the draw order must be **alarm, plate, threat, health, mana** in both `controlledChildren`
  *and* the flat child list, with every rail proven to draw above *both* the rim and the plate,
  so a half-done reorder fails the build;
- and the whole pack is re-scanned as rectangles — every region, every dynamic group projected
  six children deep — with **zero overlaps** required against the **alarm rim's** 108 × 37
  envelope, not the plate's, plus named checks for the Swing Timer and the Alerts column.

When you extend the pack, append new `W.uid()`-consuming constructors at the END of the script
— never reorder or delete existing ones. v14 deletes three regions and keeps this rule by
*drawing and discarding* their three UID slots in place (`W.uid()` with no assignment, marked
"retired uid slot"): removing the calls would have shifted the plate's UID and orphaned it for
everyone. Contains zero custom Lua code, so the import dialog shows no code-review panel.

Importing: copy the whole string below → `/wa` in game → Import → paste. Note that the `/wa`
editor preview force-shows every aura with fake data and ignores load conditions — judge the
layout there, judge the behaviour in combat.

**Coming from v15, leave every category CHECKED — Arrangement most of all.** The usual advice
for this pack is the opposite (uncheck Arrangement to keep positions you dragged), and it is
wrong for this one version: v16 moves the group 270px right and 150px down, re-parents nothing
but re-orders the group's children, and every one of those changes travels in the Arrangement
category. Unchecking it leaves you with a 102 × 31 strip still parked at (−270, +40) with its
plate drawn over its own rails and the alarm rim drawn over everything instead of under it.
**Leave Display ticked too, whatever version you are coming
from** — Display is the category that carries the region type, and it is what turns three rings
into three rails and the 3D portrait into the plate. From v11 or v12 it is also what turns the
globes back into progress regions and the glass rims back into textures.

**One thing does need deleting, once, if you are coming from v13 or earlier.** Every version up
to v13 transformed its regions in place, so there were never any leftovers — bars became rings
in v9, rings became globes and the portraits became rims in v11, v12 moved and re-lit those
globes, v13 handed every one of those UIDs back to a ring or a portrait. v14 is the only
version that genuinely **removes** auras, and WeakAuras never deletes an aura that an import
does not mention. After updating, right-click **`Paladin - Target Rings`** in `/wa` and choose
**Delete**; that takes `Paladin - Target Health` and `Paladin - Target Portrait` with it. Those
three are the only leftovers, and nothing breaks if you keep them — the old target cluster
simply carries on drawing at (+270, 110). **Coming from v14 or v15 there is nothing to
delete**: neither v15 nor v16 adds or removes a single aura.

## Import string (v16)

```
!WA:2!T33F0TXX9D6HqkwI2orKwsos1obr2sH0XsgybajORCCbabfjnja0cqsjffJDbWcSRiWUR2DbjbJD6jw3uw30K3X0MKM2M4W267AA(jBB69R00WM620lU3uMCT79h996tV(h5YR9Uu(E371C39h33zMf)KGeu0soMY3FOrlMDMz3zMpF)89hZmlrt3B2x(jw(DVrgXSZMZqtpIwrnJXD5YvcxEoxa9EZQPAzOvSOuUiYkfZziP(46hlHyrXCkQUpR7effRiz4oPsXInMDY5vul4oLsjjJBMrZiNKryN2x)iHlQS4IIg5CNstROLIEgDrOvT0FOQvpv4iqteQyr3j1LYAUMIAEnJsIwkAQDNH1AYgvINpVPK13(qRAivaUtQk6s8fm0kRVkRijvwu6GBiw2swZiUoPYMDVg7wS(icHCLb6E5vk0nVzwXIsUmeZsl4a8MwIgwDNjVIQIPC3HH)ZQ7LSmukuqYWm2zmCU8tg2I8CflBiYToj1uxQyrLCMNSxpHldvkJoDaAjA(JLZS7BAwoJ0Cq)nz585vwyT0rcLmv6KPcXNQ2Tsyib3IpzIOtmXMLnLIUa8ELK1cc8QILKm7E1CszGwG0Tngn6ejgzQjwPSQZRv3RLtX8ALvHEZCsCIWCtpI0RtXU)KA5K(I3ZkIQkSH1bWhDK1LenLsAbtffSKVx8jcRQPkTroOprkrAs)0WucgVYzUePOKNm(SHljQOoc(jGkGpl(C4Ne7b()J1AoRZg4zZzhEtfvljdvXItdnj04FGvmLkMpHgKDMirJLkk)PuYP)G1Ht8sMALnYkzUQLw25yv6qjo2A5nGXc4Dw0s01MIQzHP6rizrE3YKmcF0OXwJLnTXXb4kRKBn(jtCLcbg6Ydif0bqmMk8A5Avy8NNcMGHx2nIMRGKEpjVEzaI6EKYaKCgzflPvjddkmmv4IAI562ybwFdT87gJQj(G76k6hVE3iLSHKOL7rkkAkRF0gKwaPhIKKLK(rAT0nMZOsIfTKVz9mMuuveFq8BdFV4bWhUBC3Y477F8THVF8dGF7he)o6gFekkh3t34EDHFqyAUB8X6gF8UXpuSZGFNFsyk6K4FkaRIFy8JGFxDJF3y343d(u4hva)yDJpn(m43B34(W9JF8V49GFFeysRt1E78KpM7WyFFaSFCayAf7cpim1Hd6cpe(PW)04a4ZVwEPCrJ4Fe(PMjm(97c)mDJ)zWHWH7ghPB8WOLDd9pxBAjTGvzdPzme1j4x9JgzIqtMiv8WtekYZgA4Hhl1ythL1XEv4X)WKoZgG0tAl2azwlHvzxofrWeeWlizbDZBwVmKBiSsTYFQGEGbf9ERLrAnqiq0sZ4uV)NMNkQQFeNj1KkwLPsk0XVwg5oC38zz8QeyHxwYb8CUGbGjPmLumm0mGPU7fF)go9sykBLmfLuZr6QCqVJmA0(jG84tKr3qcaF0Fd3(kRkwuxwmr5IMslvvcUxV0QSLzh9EaUISgswsPn0SOff1euzg9qJrKxZlMv6QHYLlUQ5vNrsC2qe6URoPuofXRMI9wBEvMOsAQus6WuzOZzvqKnNdGayA3bhefMz5PVNUaUmtrlY7PK8s1Fjo)AteCIzgiYL6lSE(QOLmYskfKTE2m0YjjJJ8kgGUgcX)X5lvguOCg8die2qujNamhddHwhhNV7WabCwYfRqMTZcsGMcRrU0PUc808otgtiJIsgjcnrOHhlgo)XXQcuecLbFwvT5vfwI(Bq)I8Q1Z9qVuKWK8GhYC8GknRkcC6ZPlSeO8YQsjrvboljvacop8kvjpqgdVF0RfWNvGFELCwY)3yqD8ZINa)qpNJekfiJtMHj97iPsFfikyeO4TAcRnxh9Jsq0UJils0SjzOyAPK1SQW(hQL62aCfpfH4Gar9tGO4PzOt8meQKlXhEIOXae5jpdFwzPSZoc(DEWLMt0qreGSlPOgrRugrl(5elwwcDkn9t90pTrwzr1csMN8m4BqPgxs3GimzvbNEVtS8bBbPIFU2a0gbaA40UWcYyrcOk41NX70rgFeFzlvJck7ZGZbqPPXxtaltGj4INbxcRYM)Xk0SmOPvETLFQmWOVr6ki2)VacEcRjM7ALnTKYnP4cDv)hkQDHVVehWBaqza8G0pADOoXIic2tnN8AMeLwmziHglZiAG1nSYWBwuu1cTeWjeIarFXJdDZBcJIfa5oZKu9Jp(dFpDr62uqemtbZCI0(E4N6m4pmmn5c)ZIVi(gNAqpKPL3)tJxImHWOLgGsl5c)ZTz(ApvQLs1QkVybiB8nCXMtDQmPAdrGkE5yPqtG)41Q0Am2tkyaFJEPp4Z7uxeuY04N5Xx(4ajl09tBklMtB(l5OlDfAEKK1pDno4tFA9J0qzRBlN(tuR4PzgmwN5pDoPSGToftdeLzviMpGUjRrQA4r4qtLkU(dsZemAuJyyu2zicLHdb)CtwZQSGuoAM3ydMDfx25vDD69jt6k5RGdSkJDImLgow8yr1Fp7W7glJmXkxkJKb(egGziKcUkT0m9gKb2bPdVdfGETFxR40yeDqJyOSO7lwwmhXsi3Ps10Oz1xXnO5npWjtuHU0moxSrT2HAlz8PsnXyWlmBmUjJN0p9o0jOWfQvI85lQPzuVzjgI3JZWLZmBi2W1CWmbWyiV8r3WrT3KoQcbRviuoOvjZpP1zp)QwaWxvdXnDYyAw7i4yRx6sGotEALQMdOtsKl0etGpXQoJUq107X5IHRR(PAt6imQ)u7nvFuDEvo46oTwDNQyk9hUFC2dVUZ7MtVdiG2OXoOKmBoa(D4QgcGFbOE7z6Ymzbk30vOS6EBK4u)iapwihklkdMSEpzQrp50dX)NOKRRsDnIsbHWr(iegZzfW6Yo8Me9FenW4ccBhh6CytbmO4QSaEob88c4fiAaRBskt5vmCCIQPecevvjXPANDvtl36RUIQm((3SkROZ43sAGpdGFyMGUl8lq9tRogYSKMMLCcNAiSkLMDefdtl51CQx2Ikq)JORaumRFK6JmoswBwpNA0rKr5abwkRwjITzMYenrxa)XPsYCbiCMbjj(Cr0uv57O3tDs36J3NFTfNUGvk)AxYR1OGzoexFKKxH(ksWdzglwYXgo6AAgkGHe0oKEVJgNFSRepwQqtKESythLpzu2e)cot8hUBdAdiLtE5Nc)ZJWFeI(l8Vqx4LbDvVdQ(WFrz8ljG)LKXFue(xMQPb)X6OYLdckx(xbK6nQDG5geWYxtFWgajtw4TvMzoZnoLpIkHEpFnvreDibyPnRjzLsaW0PwTvpY4lFC8ki8Nq)iNUPhYPpn(xL5i0Nc)PX)A4pd(x)g4Fde(3e6mFw8NdGCRI)TiINUW)24FhDpBHMRPwRn6sWVcc)Vb)Vf)7I)c4FpGOS)o0c1jlXFj8xva)LFi8xjuBOxBUwSmXF(Lpk(RvNIeVg0l(9r4)ab8Fi(RJ)JW)7G(Z)E8)bz8)rabvXf(BuL4XBq8WqVo7dH)JP0n4VPm(pb)c3Qn3p4pNaxUD0k(2sRqYypBn43ARmB41LX)Poex4VnA3zHxRwEJxC7SyULY98D0YAyW5pdiOWVk(pNYfH)lq4VJa(Vug)FUgbd(7IWV2p4lH)ROCgJ6WzWejcsTbGlOdRb()cLKqAMPtKRyF(YKRp8FTmEd83d)9X)xX)n1e4X)TTtu)Q3ZDAz91DaW6AZdw2CJtX1KOotz42lVVeiV7uZE92gX9R4iUV5PB8XS7e2DgmjMUYK6bry9(2obqAd3SuBdI7GeS(JTZvTQORJK(tUZLERem3ssx3lrKN0b9fWrBd1Ur8W)J3EeB))ZHSl5q(615g4tqbYa)Wk05yckc1evbnuv1UNWBCmmJryyabboM7(mWsZemdxy0elOF9fNjy)BpbJNvn1fnML6E0XwvjRMkZP0h(EWdx8W4777EacDZg0cvZ8l9EA63uJC)0HjvwUvdctUwdRQaPN7efezr1C0rJWKRWEBzeH(M44gfvfpluKlLr0zDaywQvpDaosScwN(EXmW7YiW2IJJpXAelhH6Lg(3C4tSc4kblmXBW(ph3L4GBxnhnh3dD(z2AER6SSiv9bsWjs0PLYvqchQ6VibuY1Y9Sb4l6S1dp360FwnIZBs)vdHqJgxlhtFLbxAj3wVi4ctjGHH6CKriRPj(JZAOQUd1xDFDIicoYQwiSOXvNASZw)xNnjzuznA1ksxPGNEZMdbH5jF8Na0DW8Ifk2Mn)4npjhaz0psnxSDAgHBYEvKHuvOXo4Q0FxnQP1yR96I9oxDyJ9lNfdcXEXCINk7jtdIkTtJVSJ(ItDA9Dufr7iZ3kNSRwmBSjBaxBSyXIYNMFSlmAkI6Ht0MwSUoHJH)ki9hPnfPjnozFqCK5iupAvzFu2kh01pu8pfJc6MuaCDxhVmHh7EXdWKsJuxEa0TtymmCa3G6(gX(xcTcvaYub8PM1F2ZKRnqQUg9rmknwUpnEg(ifLevbdmypAhpGSrhGN(Bzk5lHS6aHxutReIYo9TpeLqdCsA2c93NVOPcfUcqp500k5YjPYhlk4be(7VADNIiHTSQfg3uAbDfw4XjSk4ByJoCJgA0mYdS6ytcx3Rr9VdYAWwwSNXBAjqbJ2DhIUQB6NSE2JxgeWjscUhMUaE6VZgwFhTIvCNuwrQyo3tP34khnbzCY09fmaXiNf85qvxWNp)BQxVNnR3jcdDxZ2S6pbdmCPz5gQG355A3Q)8O4FirfYtCaInbeniz10kMtBEvqDaOOC9Q)KSwDY4)jHM6RV8z4584nGFEoVEccPE4coinninDis6qEOPEPPC0uF8Cd6nqaATi54DasQppbOPdqthKMgKwssR5BqYDhYllninL0(dX5HuMb9W7ZBqO9HupEPTjTDcWshKugAoEhG(u8tBF)0w2)q076HEx)02jqg4Ed6Xd7)8VRMq99b2Cwjj9qK1cXINa7LPg5liJFMN6VzJcf1MFedPRxwsnBfMLJHj5jVoOq5cfDI1Q8kK8ssxV8vjxobLa)yRrUUASgPLPohd9EvJQlt3ajh6tmvvkFxlr)jq2TrMYwwAQXzrFH2wtOafPh6ZJTQsYl)G7kY8DILEDglD44PsfFs8x(raAyGSopuL)x4)fe(hZA2)3c4)paE8)RlC2lU7m(7(X)teHrazFXX9gyo(sCx)A471g1pEk6lIn6DtJ9ZsvHUcv53SrNw)OvZLWcoSIjzrvadCimEx0rMKiODc2A95it2sohBl5aucGLBnsjqeaBGl0g9yGFwbAK(ta)Zrcx658EoY4oHVjTRQIJfroIJ2O3NGn6jQl59kosE9sqRbzyz)0u21dqXYuPQGmSp9UePTbjOBoVEd6JExk23JhAQxAktkKjDoeTmmPHbmGXR4QfRiaccXBJGGXOH4NCKPMOzXbBuYgLaSrPyWEB0uY2OPH)ndmzDPJzJUmYgDfNjVpaaHTrx1g9bHF8C2O02iHESrI3oGK2Om3jaIHfL8F5SwzL1d2oGOnkxdqWZyJKUtH36Uzu0z3oqKd994u(tkJk3G0ukF7GdTl57AAcE8BFtWM75jyOeF53dB(92fC5H2nWLDHLJx8B0kS5zJui0IQxFMCQH7mS59(MhyZjjKc(8Vxaj7Zyb2noe8JBDAnw2YbN6cxUVeA935P1(UdoT2jTp2O8ot8EcxaO4p1ujWD9f0F4wSYEYXsMCSyxWDF8sw9R)iB3Dtaoq3FJ77k(rQEt9t0ERWJfFMMULyPssgU1Y7EgWRb5gFutiwXTMkuc1CMUHNujDRg3bBPMxX0I2C9wpZirChpM7jJ2470OHMCYO80s(qnu9q8xiAk3Jn5Ktflk1baAiv(wulOzg9t8ukR0d861Q)1axUlxsnjPXyXkjdZ(iEXIkfuXbmmTej7HqeXqDWc96oazW2pHsclbtvonqVUwPGHcBnZVpI7ket7V)1ZvrvSKsw6wVbCDjSPMHf(SlrkkXaWtXpmFrLskw3hjcptqUsoJbmwu28fV)BcUJcVdQwJiM1sZidFOHhBQKRiAKLzj6lECWbKvZxUyXikgzlkvdl34wPlurjdltsqTDCfH4qf48XE2NhqWca5mIQZVwQcxAMf94lXmrkS8JH)H0OU3bZLaTUN1gDoB0tAJ8yJ8AJ4SrGSOFBeuPbSrdAJcAJgYg9u2OFAB05TrpTn69BJEgB0pJnkKnkSnkInAyBuuB0i2OlyJg1gnMnACB0ZAJMWgnPnkMnkUnkHn6I2i(nGzRSYsMjL1MpU6gM0)BsftYEGAVWD(415oD4gNg6RphFcLfKk2edAtb9NWLcCTcmEwcDkJiDNz((iomFmopk)3Q092fDZhj0kl4lfPoliz3Xs2xUJbij9ZupQxKFBEv6w6kTmWcK2e4p0YNPOMwogZjNVrKuUU8C8txHWC(YBL5uUoZ5l2cZjP)CfShdYUNnEzl6o1BnZIk5KYOb(7ucFvoOnOiQ2WPU8rwHUjLPoizAziscja1nm8jYKTSj0azOfOc5vXpgWq)USmwGLXv71lonIU)3Ozl0BLChU3fqRq3eEKMDPQnl5HVbCTQjztPsULEpvVxQQzdVzSTxz1meOTnT1e6KI838kuyJw1g9BDBe(BJ(TBa7)J6Y3Tn8Un63ryNmIZg9k6pARWBXmkfvSQK2sUSk4hDgTIwmSD)8fgjQ01sj5ZtNX2)8ThBdyokS2g9fWq))3B7bZ2OVOn6lrgN(Y2OVsDiRn6R2iC1g91QItTrRzJ(9jnLn6pWg9hcnMn6RdJI)r3MqBNKNlWGb9Cxga40DKFlFzJkmiG34Qx8c(cfCiJDbe4JC3ce45QdbawHN3g9c2OpSn6NTZabOIl3dpqaMD2WKv0qVhcdybjvjdLSmTQcB00pxJPKLxsmxf6QbsNnIjwsImXDcE6pD28UNiItGGCxD3j5Up6PaPF9EPBD5cQAgsK9Oey2KKWgGILIjR2CR1GzSBuB)ltUdDdvrE)zlG4koC4zNvq)bjxlroTjnw8xNa(MdI(BOy)NChW(zkkrn0rlVo4xGe9G)WKcgEUGPg2OsPlUG)olf8lC3IuGAJNBcS9P484SZxIZwRvkC5djWG4nTXKe0pEZBuPQNsIEpFJYj2OVHn6p2g9nHN5FIn6BrG)2O1p0Z99iD()ugO3g9TTr)zqjE1nBXzlB0FrlixB03bk4FPa7bqxSDksxwZ0IQJtOHvnNeuWvQDhd2vsB)6OV3O2)C7n49R0Ua5rr83uvZQHJEa4mpt2V5SDemOIexNmGElzcq2II6mK)m(wWBgPab8p9ODg5V8Dt8)nH8duBpF1iY3g9AW)(R2vG6FL3BBX0R3yuc2ra9Rpgx6SfDfkDThjCZxl6YBLNTLim3jJmahT0ujBndtgiRWIz67k9ny(lxjuNbz)I3nbYACN88)WbB9)Kra9JQTVvQhXMRTvpzUJzvABvslFhrjD1nOqvSZ7B7ON0zrRzREH3NpZbVM3lp0Kz47mc6LEJl(LTS7bAkaMpglY1BRpiZrXgotTvPesQFKigAZNZDKANcBY89Uk613E9a52CqTRZXu7GdSnumNbBjWtoG4IcvbmBteBuj7)jYwORyLsAgq7sXkPs5DIsJlglyFJ0zSYV0(c2Mpt9ZwLZPZNEwSVr4KPMkwthnRw3m9BwF1CB(KDzJ(7X3yds9tpz0iJgk2yrASH(rU(GeS8nBU8HhjAi(TCuWgKDSgC1MkSbPcBZdiFBkVrK4XgzQKr3YZWVZjHIe1529GcZhpEQTuRQAeB3tk5ytenwKOBD0li9PW12UtIqrgBKl3MQ(JCvPnLx)ijJmA84KJLrQO88tLiv7QZTO9k69Airod(GNmnA3DYWKnThXU3vQDFoVNlaWWqTrUwMcTBtT)Qny9YgHOUg5Ek6grGyEcyiJEp1ToFCYHElRu7mNHy0Z6Pc86NW6Z9tmcRt0aHvvfC14SA36TbD3Q8w2O)UorA1qyykrJ8klmZ9BCHbUyMXV8cxQZKwF09fKwNS25gyD23cdvEYbcULJqaOYelSl0y(C1Ts6ZWnGFUWE9W5HKWfoqGHgIhUAWG8(d43xqEFE548Z7ZV)b9Y7DObdWTnBrKQGFQJK2iCREpAJ(RTrBSR9y8n9QIpXErvCJq6ZUdq6CkZPOkr)oFq(mjul2k5VE)I5lgEwJrk3zK9V8(kJ)Hgg4VFuCx)W67CZid34w(S(sjtZhmQZuklB7NQ)UA6wBHDv)NQP7hcgulq2m8S1H(KnDZHPJ9oX(RLNzJoGwFbMzptwad1YoBl1XP9grCoWSk3T7wJvSy5skQSEYJS13ujJ3Rz13NhU5XaJYMI5iFbHSmuMvQLMpStm6ideJyijLtRK(JUTLirT44P)y78OP7(smxI(zRJoWV8ehOH1r3g9Xo8R3fr3g9XREodSr)RjjRS1Ll3g9jahS(viRrUn6xT(IJBJ(K43(bTrFk8zTrF6tXpSn6x7(SrFgOW)6ViC3FdB0VPn6ZsxMBB0NR(YB3W2nOAKJVZTc3tL3V4W5VO3(cLSJm1TeMKvjXapuX5fRywngGXFY2gVKvQj60PO)DRDizE9fCVBf3IdX2Io2OVFTWP89i7iNDkGkKLX25BJLaJ1CURNk01Iz5xjKjWA21BFN2WoDbOpjzkRzOB7o8w)ZiXQAQvbzT8bHGQdVULVDD0TQJhClU9hJWhV5Jr4nK3TUq3gyMDxhPk8QWR1(WX1id8BLqy2D1RdYA2kfuSkoqYjtCPoJSqVHGSOiM3uIOUjBX7QH7zORubAl4Yg9p)gfKApUrfVJbQIMqF8YsJo9m(6VZGQUUdcQo5U4WkVxjxEOQKlp)hTTZ)3SzB0EllwWuj)ez063QYcDgl4AFow4X6RTqHnAYI891iHD5PoO(8)IJY)Srwy28xlX0DE()a7ZN)3ML9Zg93(wRj9kQ5Im9LvN8sjd05j9dUFxbaWf2Uz9vR7q9(EY)BHJyqDuWaxo6GIr1xKl(aDgf822VJcI9V0EFmAm6j3TJdGXG2GdgvD(avIKnBPq6DghCV77nhmtBXb6pyBIv2D74bySOn4HR7RVSst4zMOtpENXdhAFkEOwShE(Vz7XdhP1iJUppaeDck8nBhuyOloE4bcAoMppZ0zOWHFlE4hAau9srA)EMSLWPF3nKQXJ0tDiLwQRXpDrFZgsotNHuD)wEivv9wdhABuB1M1GzFTARD1I4dJgBzfpRHWYo71UW1wSIxrDVDgHDF7ZTN5F4zApU44TFL3U7hAadiBp0Wy6zcoJ1uYsxzxeTR7FFo04U0aFVRqbvD5T9WajpdRRhB0PgC8Dr8pEG3CadiBFHWdhFMyKVJvn(hTedf1zLSCtUvJhj9OQsLQu9Un(HVAenJmsIgIQzL07PHLKEIOHIL05WRNRLdVUn6J9a32w0DUuXtSJl7UWTZLDFJg(JH0CjUJTE7tNm8ap7eZLm2uClF6TFVb(HjBGPLuSKkrptzFIFaziJi5ItQ)oBZ5jBmOK9Z2k6oY2WW760txMtBiGpryY1nSbPS7kWH(e)3R3Y2DnqRnHDxdcv0URGTuTX(Q7PQz(PVLQgUpor1kBH8q4op5XT(gPciniBMQ(BDZunwSPtpU08sfnQK2rklX0js7XlJIrpqI88X4tzgErcfJVDKI5C3bPy2LNXwYgwnPHZFgSojVFoUH4OIZxLZl5OMPFu6rx0nzBR6oz5SzLiFp3jBeV)U1QD8fhlNWBM0uSRMSpEJBzUD9SmNZUxFU(SU4fhyXlexUZZYp5BaZYpAhogdVkDZ9ePOMQKPqdhR6b9UMUKb5VgnKpgLljMppyViz(f)a3K8fBqrvkb7(cTHN3gT4(IpzpNOJFYEg7wf14SbG0ScOnO3sHKY3zCGNABBYX(jhoWURioZ)V87H8fDJ3lxqo)00a00b4HKb9st5chyWGCHhGZRpssGWb9YXrsGk4jyWGK0H8eoG)GqgdoeufF(gkSxpdav07qbijdeEOGb4ij(45gyOGdX71hh5X6JJJJM6JM6N89dl4qH953ZqaWmOh4sp(GM1p3Gdrsds(An6XBq7UIA31ieaQDxx41fOCNIoY)82T9FFdfsU7m59b)qTdAkDTlX7nAFx3FYj7m007DEOzVL6nxV5w(D18Fg(WdyJ63g9YGX4K3rND(j5ZN639qv)(PE4AF)uzME9697NkXSsU9(FUwQ(3VQd58NZksNK(Xt98RLxosUXlzm1KzUa5d9kyIlyOj7dMkim2RjVVZf4CE6DUd8c))(
```
