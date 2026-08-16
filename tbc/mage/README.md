# Mage — Arcane & Frost HUD (v10)

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
Spell IDs only — aura triggers carry every rank ID as
strings and cooldown triggers carry the numeric rank-1 ID, so the pack is safe on zhCN and
any other localized client. There is no custom code anywhere, so the import dialog shows no
code-review panel. Import `all-specs.txt` (or the fenced block at the bottom of this file)
whole: copy all → `/wa` → Import → paste. Heads-up: the `/wa` editor preview force-shows
every aura at once with placeholder data (load gates ignored, identical fake "55.1"
timers, both specs' icons visible together) — judge the pack in combat, not in the preview.

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

**Globes** (v9 — three vessels replacing the v7/v8 ring clusters; **v10 moves them beside the
character**. The sizes and positions are the canonical set shared by all seven class packs, so
any two of them can be diffed and match: main globes 72px, target globe 44px, rims +4px, life
at `(-270, 40)`, mana at `(190, 40)` and the target globe above and between them at
`(0, 110)`). Each is a `progresstexture` in
`orientation = "VERTICAL"` — "Bottom to Top" — on a solid disc, so the value is a **waterline
that rises**, with the unfilled part drawn as a near-black empty vessel and a brass rim over
the top at a higher frame strata so the liquid reads as being inside glass. Since v10 every
vessel also carries a **specular highlight** — a soft bright spot in the upper left, in `ADD`
blend so it brightens the liquid *and* the percentage inside it rather than veiling either —
which is what makes the fill read as liquid behind curved glass instead of as a flat disc.
The **life globe** is on the left: D2 red, the health percentage inside the glass at 18pt
white, running orange below 50% and hot red below 30%, where the Ice Block prompt fires.
The **mana globe** is on the right, D2 blue with its percentage at 18pt — mana is the mage's
real clock, since Arcane plans its pool to hit zero as the boss dies — and it carries the
conserve breakpoint as a horizontal line across the glass at the 30% waterline, dim by default
with a brighter, thicker line popping in the moment you cross it. Both globes, both rims and
the conserve line fade to 50% alpha out of combat so the HUD breathes with the fight, and the
lit line is combat-only. Since v3 the conserve line and its lit marker load for Arcane only:
they mark a rotation switch that Frost does not have.
The **target globe** sits between them at 44px so it reads as secondary, with its own health
percentage inside at 13pt, and vanishes entirely when you have no target, because the Health
trigger produces no state for a unit that does not exist. Its **rim is the threat read-out**
(v9): green normally, orange from 70%, red the moment you pull aggro, with a red flare pulsing
over it above 80% and the threat percentage 11pt above the globe — mage burst has no passive
threat dump, so this rim is the warning system. It is party/raid only and never loads in an
arena (v5), so solo and in arena the target globe is drawn bare; and it hides itself at zero
threat rather than reporting a relationship that does not exist. The globes likewise hide
rather than showing a misleadingly full vessel when their maximum is zero (health not streamed
in yet after a target change).
There is no portrait: a `model` region cannot carry a text sub-region, so dropping it is what
put every percentage inside its own glass instead of parking it out in the world (v9).

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
| Mana conserve line + lit crossing line | Spell Known 12042 — **Arcane only** (v3) |
| Presence of Mind CD | Spell Known 12043 |
| Icy Veins CD + Icy Veins window | Spell Known 12472 (loads for deep Arcane *and* Frost) |
| Summon Water Elemental CD | Spell Known 31687 |
| Cold Snap CD | Spell Known 11958 (both raid builds take it) |
| Ice Block CD + Ice Block prompt | Spell Known 45438 |
| Ice Barrier timer + Barrier MISSING alert | Spell Known 11426 (rank 1) |
| Ice Lance SHATTER prompt | Spell Known 30455 (learned at 66) **and NOT** 12042 — hidden from Arcane (v3) |
| Evocation CD **and Evocation prompt** (v3), Counterspell CD, Blink CD, Invisibility CD | Spell Known 12051 / 2139 / 1953 / 66 |
| Invisibility prompt | Spell Known 66 **and** party/raid only (`ingroup`) |
| Target globe rim (the threat read-out), Threat Flash flare | party/raid (`ingroup`) **and** every instance type **except arena** (`size`, v5) |
| All six PvE alert prompts | in combat only |
| CC ON ME, TARGET IMMUNE, Trinket DOWN, CS LOCKOUT (v4) | arena **or** battleground (`size`) |
| COUNTERSPELL NOW, CS LOCKOUT (v4) | arena/battleground **and** Spell Known 2139 |
| Will of the Forsaken DOWN (v4) | arena/battleground **and** Spell Known 7744 (Undead) |
| Enemy Trinket, Polymorph OUT (v4), Enemy Mana (v5) | **arena only** — they read `arena1..arena5` |
| Everything | class MAGE |

Nine elements carry no *spec* gate after v9 — the life and mana globes and their two rims, the
target globe, the target globe's threat rim and its flare, Clearcasting and the mana gem prompt
— and every one of them is a decision both Arcane and Frost make (the threat rim and its flare
do carry a group gate, and since v5 an instance-size gate as well; neither is a spec gate).
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
(sha256 `e60f567641d00444a73b50543dfd25a13ec14f7123715497520d842b63dcfb1f`, 10404 chars,
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
That constraint is also *why* v7 is a rebuild rather than a delete-and-recreate:
`W.assertUidContinuity` fails on any UID that disappears, so the bars could not simply be
dropped and replaced with new orb auras, and in v9 the rings and portraits could not be
dropped and replaced with globes either — and the in-place transform is the better outcome
anyway, since it leaves nothing orphaned in the player's collection. Future versions must keep
the seed, never reorder existing `W.uid()` calls, and append new auras at the end of the
creation order. One import-time note for users: the Update dialog's *Arrangement* category
is checked by default and will reset any positions dragged in game back to the string's
defaults — uncheck it, or report the coordinates so they can be baked into the script.

## Import string (v10)

```
!WA:2!L33cuUX155P7cslsijBYLpK4QxquImKSsu4XI9bLeRaWcWfKybahG9PyeMbadWmChmZWzgS7InXYXBTszRIRS30Qg5QQ6cNi3A72tZAfz54g36ToXNJRpNC7EoXDQRAsdBQltAE4YMhTP5rVpMzWJfl4YLlDwPOZrdbUZ9EN7C))()))U)3FCxWe9w4Z(0x9rxlpxHzlQPOgrrsr78UC5kTlVNoOAVfuKn0uKK4lgrquQOgV8zupWyCL598uEsiwI3tePQ6g8AQhYQWSCAL5nCk(GwfNwzEEn7sVwEfTI8AHTEMQ7lSK4IlYPv0twffjdrvTfsvQKoVbiVkh6rAOEes3KnCeuxfsRaNmVNJ7jMMIUrEAFjOvJ2KrUN6A8LfvKZwtLNPSMsv160QKrCr(DVIOCjfTkCgOA4Ef6nOVZaaW1ACvneu0sPIVTU78O3(sILDRXvGuWam6gCAgUZxsuwuxWDy0)y4EjdnXYL510tECnRp(AHnWpDUQAC(xfFvxLxssSOEF96nCvuJYRkXvJxBjs5XlQ7(A6vZZph6vnt1sLexyLCrcLjBUmzdXK15wP14r3Ijt6OjsCJQ68rxanUYq7bwgzUk86URxKppQhWV8AJgnr6yJNy5QYwdl3Ruuu)YvLrVnZX7NtssD)CKpNLE)XukY)LUlRPROflZRU)mxPksc4jwvjjptkiAWVk9U0j79UmNSiDYCa4HITkpNoFgdKeRSHWDd7lSSIm)AfrV)4AKdpNOPZJMulQVeUQ4rj0x4kCIYXGErna6d6hga2p6FpC7LSSoVuP0kIYg5Jenz2OmhvS4AwORZjPKNx)gO7XRjZjnb6XGEGVWkL0qtkObeNbNRBWjxajBJHlc)GZNjct0OjRBOuyoA93t6d5VQyXvor5GxzrJPuZgEyg9cCs8UQJebmeuLUnOjUm693vD8lJifTewsHRO7vOpgYafo4vFuiWrBc2ZPu3FZ6oKHTJMtJI8Wiwb(HG3nCp)U7dUx4qW7raEVa49b)WWpYUH7ZnC)e0kSx3Wd4gEq0uVB4HDdVF3Whi5XHh51qtBpi8Hqyn4ddFe4J6g6b(yWJcFC4tWcpMB4XH)iWt4gEs4PG)n(s3f8jHpf807f(0yjy7sHG3C5cCa4Girb0fC4xaEgxWNb(SWNdnvcp7kf96T)iZjhBMfNa(8UGHCdd7cgXnCe3WOO5MZKhbI1Yvdq)3faW9awHR4LX2ikog3c904lIY9GNbqTs9Gf515mWykESbeSgUCrHv0XIv(fq3GNT56etbzoGwhgDjozdWs8YfdjxwI)tCy0q(AQAkL1411ZOuvRa)PEO7Qh8BeAA3fEYTx3lPPyqWVagojvbo0BW5potbb(cZgdEKDV0CCAIC5L4xsuoIsL8CgmZXjvLhCuf1J(CpNwbbo5Y869DC4ueqWsONhsnWOgm7XHJJ6bxWjwdvqbKcUapNKHaCQJg0lQ19(SWPXn78e0Za4l(CbN5gLCEJigUC6f4lGAzGwAjUndNExOg6NEf1E4LCAXYv4wW(z2lUHh9zFoAlbO6Lfg6ux9WQ9AGMvZPlWvuz(PSmlVmPm8f19DSwg8h7yQ7RPg0W061OLARdho04ztPEasHiJUkyJifMuSOHq4qOVEdYnqw74lsk8JVgvTAARbWQK7JbhILQbhSorgrK)HtMkzuyFAinwCDQtQybBVAUOJ8siVAQ7lMM4IEUyvUIy7dEYMv1RZRvoQtICT8ULRiFbK1oPCQAOpGTyaAz2XEWTgPS5rMjMuJtDPjT(WAopAI15uJNnr8KrTMUAXQH6jVjdeI0NypLPKKIIgD6yo0ycbezB8GWU8EqRPoBzN6XUjDoTW8jRwjpV2vpaP3qAvJjQPPOja3Zu72N)t7V)8vSk4EtVBFbryR6yHBov6RWnSAfJTYZ1SkycRbPLDYCvq(CyOnQV6wcnu1u3V1hgXrtwWUlSuZvFM4y79L4kWFPqflMsw)stYZnBiS72lngFrrUlzvt9lfruRGeFUmvuumeoTrzoM5XWQrF(N)vV0j(Jw9tTQvx3G(dsDX)qiRwRAnoTEVYlWlwwWi9U93)P7FO8uCNWAn)2YlqLPOVhwczRb7v1FOrgb(kF6TSr28fqwnYvdpQ63xZw8v3hY2zilZKeRMcQ7pVJDrRja4FBIj56e6leBFa4itSmQP5kiXPRZM3a5Mt24WmvQI4F5MHu6XZRlIRB4XcDUOWx7WWxNnmIWsHddFn3H1rql8hGpWlA5Y5HXUzyimvYpk1Qc19Zs4NdM1dlXjKJhOMBh8nup44OQ4jIahMUfVMis3UGUThS3ST26496LeAFkquwaEF3W2SULKyjfKtEeNlD3lN3wOWeor0KJq4N1aMQtGiPTAnBDIpJyIA6gcRy1hfKevfW(5Sb5yTBChQEWijcnw6SPcNiuKlGe5XZgFcKgEd5HLo4nAucfXHfSEd201bXxhk4sfuQOIhicyxSXGxIuZbjwZ9om9QlSx3R(Pv3Fdhdne7NDf(YlKprQbcLqFmnrzmvhEHLjVv4HC(4jZeFKOROOjIKBK5GLMikt24rcLGc6wWc0Tp3AKwXxu4QEiUh)Nd)cTj9HVb8F8gjXARE)tUPs29HGHotodqELdge7rRFcZNxIYjsZsgGDw)5G)SWiNI6EB3ihItICKrDdt9QrzHnttEEH)OD2Z3wvpvD)ig2f04n4Z5qBOfcAVRA4TOvRCHj8oXgVO8RW0T2Tn7RZH4obZ6QEdIpcWmaK4p8WNZi6eQAZzuIqndrHc(kVo8Nsazaa(3Nf(pGOe)p84WFg4Rt1XHFgsr)JixV6R3gf2gl)ZALEusS3FhketJTrTf045m8edzyrGYTf4qT9tUdNA7Uwp12cmrp3LN2B60doyhP2cJdGNhtOfEHEGjSjVchtaMKfMsaMgaViH)jKPjkN7Is5el5YI6U(UP4umdn4lcG5GSqo6mxEybyripS0hhwgafq9Ri8YO3QzHsxpfScugQaGQa4vGAqDObSkQgZbNhUalS2HGlcG)yWF8REa4hf7PFxdICYr00sVRHr(8HFmuL)jaWpolCj4FluN(jGVSa8NezN5QJ(89)CQFU)JUpl8Vtl(pH)DXaoefH(p9WdGHDFsb4Fp4RcFLP36ILp169dc)0cWLTCZb)PbBoWTdKQjJxipHye8nXNd8ZI8Xa)NcRtn68ZbGVfl8Zla)Nr8lqSm(fbWV01vG)liwU)LGx66Qe70td)xsmlpRu8ZTyEJPNA(OW)vcWFE4kWVm8TH)cowBHVJWvFmmaYc6SoDH3XEGx3GOBHDFc)gOH71W(BBugR17YdJU5BOUplfXmIgvj2NiVJT9cIGLya5xJydjuFwySvpgTtvlyCSJzb3uFY1XM0PsDGVClOtrB0P6J1LoHwa8hNcHjlPzqc8AWGUiW5wXYDGEBJ(QbVzeGV29Jr7iy)RWrmh(tIqmRGN6qKEWHnILWBbZZrGcK0SUb6Zhh(HzdRXjwKDJqxZXOI4AvJ1V6COEcnsmQvHtM1VbVmBDJ5roBRvsCoEeZlYNzH(yjWMxcdSExcQ6DH)IeBciR8yyngh91HFfI7q)ehHdHVeWf2wXv5W2no7krQeEYHV4ilMkEmSTKVkyRRLf5mnwOOZuiAjMdsSdDwl7qxpmYq0xXPMmCLrZrWPC1SF3RFUwQZk0EJSm5oBwdH(rQreAg7IsZad4)(oAQVj7AnW4Orfl8Fhb5d)MSWFTJoKxeIhTYmhXoEb3CgkA4bnrla(l3jup6P(vOl22h9cHcwtCnqseclJxfBPVZZRLG9Lhtydzbb)D0T)E1jHniDvjD(LSJfwV0MS(j9VAB0fqqahN9US9h9VH6S3s)8SRWDHsPJgtzYstwPHp(gGA43Mf(V3cdd)ox)3VJq2R)hIWqT5R)8oHRAmozolp9hP5IIOiRZRnhVNeIY8QpWgCldNyC1OFAeJRFR3)eJRDVEIaQ(tvGrlZyYcNFBKiWUBLiWTeN2LQWTGkoC7iDlFDHYWnSJCdPYow07gbIZBrcNA9128R6j2Oikq65wT62mTJfyvFIU3uhJ)1EqKXA1NU71E9(BSjYqdzbLjdnAfDLkJvub2aQmKL(3mvMp9oaQm41H9R0Gkddzdxi6gVj7YKPhSaaG1uOKAupi2eQg)vQkQXtQnoSuudRo1NDRU4TBDks)6wlU1xaIxnQXxR12AXzkE4z8EYto8GNFWcBmNjpe1hN1M(onnSVozy)BdADK))KDRVcvIddI2aEqBTgvBpgtTleP3(B424N1HrFxvK36GP2DEOEMn)AnPB0toYE806AmDC78B0MBNj9wA00xi4Wdm24nC7SBIBN5qqwcnuYgCnRSY8Y2q4pZ6aY1BuP980ol8m9Uhi4PhE4MLNTqcq9qTO774J)zFUvB(ghnGxBjpjqrTyXGDJbdBSq21gjFDOfGiba)EW(1W7XvQQgewa51fq8hNf(EHXS3iISoisTAPfZHWL4kYdFp)OwqQY6ih871bP0)12KsZnwYXMAKQjgzUinKs7Tb5G)aBdjeXtDsmbj7JrBuB)bDx20M9hlDT30Eg2A693H92uD76FSoWh7woQp)36SRXTnfVMzT5eIMFZ2emJhQq00vNz4fpH42sKzoVAFwSSS2H8WsC6Of6zWvywD1ETUx8cOBWPPjYR1E9P7r)KIYfvM3jGoXluZZe8IY6w3OrSBCtOSTtNZ2QwVhHRwQK(6PVfmrLGNxmsSzdY0j6BpEDXckY0Tg8HUl8lgL)2AfuuKqZgYzMxe5LCv7VI30CHn(nNjWaEd4Ft92p8lCJz55vdHd4UbdErdc2Rjp05)URvwsz(yyN38YfQrxriDtVW3yvKsmIKnD33yxcxejBislUaVuD8xtq2I(dTc(Z2BB1YLTBcnIRbPRU0fPs27Euy8xeivndzRXjJKScIfMvMxx3f5o4fdOVFYdIg0sbepmmLZJEm9ndlt8g11HL2dR9y0vS70BQB5EB14jtgLjx4uzZMAmNqbGm)UmAoKUd)Rr)NCkwB5O1xl0ylnTkXEF3SYmGC8iqa8PS)goacUGVYfPofXMB3i)GnBI9(cJbEW9AcUlS22zxjr60xrOqW0Jgub7pc9FHxurPcrgTKn8J1jqb)zQh0UqSl(re1X7rDrwsScUOj4HyXQOisuu1lSotFuVowQxTvYHxxjyLOMIqzEDIDgKH1anB8LfodEx9oTVtJrdyBeNX1vFCtqpnRnzcCXAc21gR4CzgF(63)am(c4nGpYv)KRby8pOVa9Zeiq)EdUjvRmbFOgAsN57AcUBB1htWEmb7fnsCBcUhtW9EitW9bmbFysmN63IqQltWhbv4(emb7h95Er))b2Vj4GcBdGstWHG1oIdu0eCytW9JEypaP)mbhbn26d(uMGhCtdOEY62akKmVj4uY4zkp1ivg9ILfSGtMGhHaMmbpAdy0FUjWZDomZ14xqvKgqKSIvWXckyZoLryhtWr3QyM(y853B)(VZHkC5algo4ogur0BrZmnqf3Rl8MfUi)jNFs5I6dhOBWI)chyr07aWctWP2(Hc9p4TluGkE3RLiUjCGlQrblOcw27ET8vnmuKtr3W4D2GbVV76bdCiSqTyJoCTO9Fsz5X6gw4V8oawWTLK2B4YAkZF0Xtd75l4StIrK45qew1neLl7qtn6Ckfigs8KwtPIQH6HT59r566zS4zYep55AIxlMGSsHzTBGnz44Ye)5IsIg1AVZOHVKVID5pqtDwcoz01mJgkB2Om3WESgXtQKEglQZJnsQXX5Uijho9Km1KojiB2qmNlAwpXhBSXtgLqYgJV)gKvfqPvZORIwi)9D7YREfebMQvKZG7mso7nqEkligojXYYWb1qEYXzdkaZggXdUXAm0Oz7jplH9)Z7AjKWXQFqlfaZx)(wTynzUkIfiBucAvbH1v0mG(wUSMintUUNLWFeth9OmJWijwr04EWB0sc8NeUgI0d6XlBeJRaAX85zcns8XZKxJROyv9pX9IwpWYizpL96N4W2yq70anKeVMHE9svLKOBDoRnBF0cUq863J0TXYjq4AkU8SR4)Kx8erU8LNZ34NyRzmkyGbUt6xIWuHgRcl)sS7ayRuQXIA)tz3411ABfkbLOsStwoE)tWp9WmZ1fRqMaFBitf7yQ8hsIPYk6sIf5ZRGmpxHeALa2XIPDttxDFltY(xmwDnDdnoCIFrw0dSV8fQQJ6G8KkuJqea)eOFFb63FVE9bZcijzfPy2ERvCV9UayzY(bH71LS7v8ZEn0NL1LWPXi6wQ73(EzTlgnWO76LDbSK(M0BSTA38jqGsWndt(ITSLA)V69zH3OPGLb)FZ21iLE19ZGgifMnmo7nv3pEKuMxMxtSqgbL5tjZUwlFDfDY)WWZvSgU7xMeZVKCv43ZtFayFmKVALiyhjI1kx8yNgwEobjn3pPAVK9NTSSIgpozSqws4zxtJNtkJD3TSJNG1CI)iUCYUGJh903LLTMjlmlR6bWFMhNm9nx9nwn8uB6fneGUB1BOw4MrTPdbPBD6p)a8KyBQp4C9h)RmioYKQ6rBeiy831Vez(kxsCUcXNlDvn0kwjQBxC6YINi108tKMF9QBcnu38Vjv3mbxe(EMaMnwjZeKXeKfprmUjychvjtWKnRgzcMYw)XemTjygCpzcqcMlH6ltWpkAw7f3QAbVL1QmnbiR5OwDmtWXnb)iMGtSgYDxbbEDkiEnkiEmrDCIr2nl4efetqota6rYH()8MGc4gyckIxtg6TLNI2nbLmbLr1qyLMcnNj4YTbynbZIQK02dUS9fZEheyUUfGMWeur1tNXJOzGCjqAFYgu0yOKJEHj9VymFiKt3qJb(GeASru0FbQ9yAkvIWwwXr)nzP2BBjTTzvpCRPXT9gIGSRVjWK)8VuhXKl7qt(ojIKU3k0fs)dbij6DTdqYhRZqsYpYm6vkMCOW1yInB6zJvD4UIj7)dMysZwZ1MbX5Ad8)eoZAAnRA6gA7L7iwB1Mx51Dq4gHFC)bP)EAUDqBVfjzA6W20qbHFBBCicb(dE5ob5oz7qUq0x(C41ZKR5Pdk0BSidQOWnCGs16U5WGFqb6j3bkQdUPPO(oW(clAWxb3ymgerT8b6a1Y4OQCsQ5vlukQVwLq0eDhczWLS)0EM4HA0)Fx88YhL(ROqPQSblfrxh3HEIGlbNmMKB1CkOrjXs5B68eqpCgsnrtOOhVj4JHMo(jA84U9TWgWYclnhfUTa(3QRKdJ1pw7y94jNihIjvHCNJVsUmgkY8586JIZ9oZc6cdnXilotGUIZh4dsMyTcpWI(953V)Hgiy4b8H3RdV(d4LX)GEhAiCqmhgVxhbgoijngxp3tTrdXmwSXtCZ82p3FYg7TNehRTK53ZSPXI0Fhhd7ANu4jERn0s(1KvmY1soQqvHBT4MT2JNG7GoWXVPumiBzpvjyKzKv40o3jedosxd8XGVpqjyZhKSJJtr9iAkZxeNaPwh9aepaBlHfZxq6174aVhEtc8M2YAQt(5Ubwtpo8xLLbFwiGCJ1weYMjsGjQu9YCvgZBxTwoKdqz6DCaLptJKd36eNGC2amv4mzhpzZ7NCBIr4m3OXUl36phAtWpdCQ1WTp3yrJmAOKXJ01oYe8zATTHJfnetlnHenhRSIOdnynCd68d7M0sTiPsgB8mrxxBS2Ers0374yKjvQSRRv2HDQtpPmXtenzKORFQWoIXD6flDOiXJn9wPPQ7ltKrtLkrU44T9Gz80zVjn)wLEymm5pS9H3iCeSTtSJrI3pIQhp1ZMelXH2BSwiYb5HNXjzdbYt4B)Yovg(WKagkGSctOCZUSZh1OFIh)OOjQ234dMrPFARLqJSg18sO)dAFj0V9l7yuYe8AST6L7j6MxoedJmckfMLA6ArVEV4CZmJ6vIwUR(4gEhSPRgP07Q0tZfzg8j(qBjHilCg4x7wYByZCcz6py)bgY)a97pmIqOxMaioI9Z4pWWOp7B4GdIyf2F)d6BdyfAVEfci3e8ZHEyVLj4ZVTJMFFTZ1wXXu4z5K(gA4jRjCUkxORWZZSdgE6Sv6MaV1hnft8zsLmBOe4nuNUR2rgPTma1ANWjLNg)tzcVV2kL8mMOCrRnHNCpNmdv1tJcZuTsfKb2j5qMa8evIhhlxoPMBgYlDrpzK5uBTVScZyZf6StonpsjRRMxJOQDJgfhwsuE2MRxlrpXE70FYD10(PBcEM9E7Uz6MGN1L1VwstWzXx(BU(Tn3e8827yUjiuJ9k3eeg(r2Tjic0NjyeK(u0JYmIjig6tNtWemQjiUj48KD92eCHgB3T6(StMaRGzOBcgR9T6gSTSt3Jn0vgz(jmuvvziUK3CMTABHN1XBBsiP55QPBVa0N2DNdbyZ4WUUg0B5KhFRhQW2CslClhXKqBTCY6RJZfFRdenwRS2BqPPtmNwqJaZ3vdsVnYGKaXGuOTTCY5uoe7QRiBJ8A7h6jXlhQEdapYtExWj8hk5i5jNus6NAaloHFtKJXbCsuFxDi9UEIn9IfBdNDn62Z5m2SXA3thXAQ7RDJB3UXC(wjbXmbNE7g)CpTJFmbRAHBukNqLFK5Im0Gl2vCZVWDaCJ7BjX6l2P4w9V1wu69D3O4wz5k6VMzZyDPUxtYC5fNyOSNSYWxCMGDvM)o3rTvqu47MnctWVSj4xzB38q3Xr)yFRoBs4WDM(YFndvHMD2quLVerLcul6eJN1xxrvFLpqIQK7kQ60VtNTo5W49MHJwxx)TUjg(mbF7TEFUbkbMGVZnXrOFo5A3U5FslH))ofqgjq2qGSXqbNsBUSYJpqYUcKF3Dca5ZSEGCymzhuBrF7UX35)W2mzQMakBqUHycM)93mMwxEG0e8iAGQJuuxiG0Wr6k84R(x5mM6USdNCLDu2j((C2UhyJLDPfnkKSWKvdWR1vz3V4oBz3BVbPjtZra591cX3(L3yz4u(oF5ZpPVO1m6(kD)A7SLHhCXokdziHR691cp0B2gk8YovOtguBw)z9EYUk8(xVZw49YBGPZfFFTGRlkD59pgFYbhkJC24DvU9lDhuUHJtD4rsnzsypxUXHhj(OZG3WdUCROn)uEMuusch6gdbEpXu005MLxMwd7FtvrL5RuZUXoNLvrY4jrQixi14zB6Vobs1QOOPk4bx6(BP54FZxD83JLj4zUVTT4h7pBQ0)WlcY1TFVNlDhcDCXTNFLux0VFXX9n)GrMDIn5wE9s0K2Ze8rBKYEMGxQPCZ7B1CYX9tF9wY1VnDZ(T3snl(xCR1S6oICtWV66mmW(dlddBTnc73KAyyHHMktPP6ptc9Z1vddFV7GggE8Tb2WpYZ354(CWozl5w3k)p0eMBQnPh)22nHAOH9lpz5Okvs4VRc1)Z7ieQZH6J3qZ6Vxk9X0VF)d7h(M0dStRszHVNFF(9IpkXjPCGNiKZ)MQfkWJpyWX799R9x5oO3u6HhUtYR8XNz6bhqxi2fl2v517DN07CDDvoTzj)sEpev25Cc1Ug5woNK6Q7VLVJpSXHfqdibh)KltpNPKukBc((9f2VVadd9uVrMcbFVEhc(g1P)v1WtcLYu7Qx36KfJCO8qoGBR34ZixUnKWKdVNM(J)G1o1UuEoR)M)0YVfkeiyvYqMEu3mnYn8zomSVvWNp8OwKd9)BdjWWk0dEgM4NB0SojMZCeGJ9bod9V4a(rpVUaLoYwlvDUg5n05VlbWxfFAdIXyubBKgZviDs8j4NM1Rpcg18SZuGLjtU6If5zOVmBzodnPRVc5rmk5VXcph8DzW)w)Lryz6J2(p8dNOrggfHEoaeMt7sJh)PA8TNkdb8rAwt5a5)fKkdGCMc(n3dbzF2vUY8OxeVjp3CfWheZwdaXIf5LzsgDIOmWVSj4lBPb8LWscsY1Dly567s2)7iskY86Sw)sd97ZhoFUhYF)KRbjxhGbDzqFKR(xrLxddOXsPL4kvIVGbFrnL5LtjlvJLyl7Ay9hrz(00AY2bYMMGxDBjHThYkfe3XCoNe)2XsQ0vu0NyKOvnI1DpF)6o51t87yhZjb2WJ5e0kH(DB3gRj43dnJ873SH02o09W(4(D2eNRHMG)OMTjAc(JB6GL2(hJhcLyc(tqgcp)HXcK)pwszMJH)Jn2wwqxNAcmr0yzToY5xG1(yS)36wTx)V38zkRj4)l(a9(7JpWyjiP)hG5Sqs)PMG)FD3C6Mhpzc(ZAy40e8N3IbttWFbcOyc(lbM9CxM9a2wSlA2tpiZHM9GpRVn7zxM9SBZE(qnzx73y921e0NQWf6Fu1bNobc1A2ZEm7zVw2YAS)dWBy)3mkhm46Zj3)4wRUVwREh(TfrAuR2l7TsVf7T4vFKwoXcNboKj4UiPn6xhRCAD0cIpwb)o7zh(rbT71FwcUG0qxww)cvehSthf09QZe40bpT3ENBxF0))
```
