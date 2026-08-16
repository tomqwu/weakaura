# Hunter TBC — Beast Mastery & Survival (v11)

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

## v11 — the globes come up beside you, and the glass catches light

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

**Resources** `(0, +180)` — since v10, three globes instead of two orb clusters, in two
draggable sub-groups. Since v11 they **flank the character** rather than sitting in a band
below the HUD: the life and power vessels at an absolute `y = +40`, the target vessel above
and between them at `y = +110`. The geometry is the repo-wide globe canon: main globes 72,
target globe 44, each rim its globe + 4, life at `x = -270`, target at `0`, power at `+270`.
Those numbers are identical in every class pack here. All of it is drawn with two textures
WeakAuras already ships — `Circle_Smooth` for the liquid, `Circle_Smooth_Border` for the
glass — so nothing needs a media addon. Every vessel also carries a soft `ADD`-blend
**specular highlight** in its upper left (v11), which is what makes a filled disc read as
curved glass; it is appended last on every globe so no `sub.N` condition is retargeted.

*Player Globes* `(0, 0)`: the 72px **life** vessel at `x = -270` (deep red, `%` inside at
18pt) and the 72px **power** vessel at `x = +270` (mana blue, `%` inside at 18pt), each in a
brass rim. Both are always up and fade to 50% alpha out of combat. Life goes bright red below
30%; power goes red below 20% — the same threshold that fires the Go-Viper prompt, so the
vessel and the alert agree — and carries the two aspect-swap waterlines (red at 20%, green at
80%, each spanning the glass at exactly that height).

*Target Globe* `(0, +70)` — the one cluster that sits higher than the pair, and the only
place in the pack that knows it: the 44px **target health** vessel on the centre line (`%`
inside at 13pt), its rim coloured by **your threat on that target** with the threat `%`
printed above it, and a 22px **target power** vessel with its own rim just to the right at
`x = +41`.
The whole cluster disappears when you have no target. The threat rim loads only in a party or
raid, never in an arena (v5 — there is no threat table there), and only colours the glass
while you actually have a threat state: green normally, orange from 70% (press Misdirection),
red from 90% (press Feign Death), deep red the moment you are actually pulling aggro,
otherwise plain brass. Just outside it sits a red `ADD`-blend halo that pulses at 80%+ threat,
same gates, because solo threat is your pet's problem, not yours. The target's power vessel
shows no number and only exists for units whose primary resource *is* mana, so a warrior or a
rogue never draws one.

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
  an empty threat "%", and every globe pegged at some arbitrary fake fill. Judge the
  layout there, judge behaviour in combat.
- On a future re-import the Update dialog's **Arrangement** checkbox (checked by default)
  resets any positions you dragged in game back to the string's defaults. Uncheck it to keep
  your own placement, or tell me your coordinates and they get baked into the script.
  **Coming from v7, v8, v9 or v10, leave it checked** — it is the category that carries width,
  height and offsets for child auras, i.e. the thing that turned the old 172x14 bars into
  rings (v8), resized those rings to the shared orb geometry (v9), replaced them with the
  globes (v10), and moves those globes up beside your character (v11, see above).

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

## Import string (v11)

```
!WA:2!L33d0TrY595HukNoC)tINKUt6o7dhVtkKQ3PdaeG)r(05daeKeueGqla)NKUJybWcSR4IDxT7c(pF2oh7LRQ(IVytN4w7g7lMX(sA6fNuwh32Zn(5W26(p)sMW0yV2n2nHjn9st771O3RTPjo91VzMfalabbPOOojDrVNwUy2zNDM573333VzMVDw04TL9NpWvFS1ZWNDMC6QAHvLv1hU1wBnrREoDaT2YQQyQRkllKlSOKCoDbLtPD0HkPykO7(PDNqMFb4KbLvZiyODKkPNIxVGGjl9nYOQNtqpK9dq7GHKLwCrE9CUtPQkBkPPp)O5ZBiyIYOXdLVP2XTlNuHcdLvOyUpP7KL0NvAwE5mSctuFb290)9SIUqbjvLulOjWvqxTK2kSSKuArH9VQKsEv9I8MqoCTk7cSwicHADD(sMIQ6JQrUSHRmqBnVubx68zPj0nNHjVUPRm5LuKmeDfc(JPRLm1Lkuqq3i(j1Tp9ZeYK805lPZ7BnYrdnbzzPCghVnpHkb3ugnA)0s00JMZW1ggLYiml0wtwkFEP5xD6WbtMA6KPcYLQYLsOlaxIlzIiJmY1kziezEOELKvcP5u4lky4ALCczGsG041hkYijgySrwg67yvlxRMtY4YLuGwZSc(4LL1oep98uSRhtnNWB9(S7UIKRGG2HsELsGiW9aLKLDpHOKPWASRY6SV7L5vKyDMDJp8aRjWBiK0eezfmfVl8XcPOQiSEoO9tYX0K(eDdbOtnNXsKSsQLypHkYlPma(zGBa7b7f7d3f83JuFklBiiNpHQKIzMWrINkcx7s50ARcaJtWqTKEwbJRjrsrHxEC4Hbp2lUAEDORbQw8M8TEnELSGeEassKhFMKH5Iej(kMQzNLL)dK4i(kjLBv557zeURm(fMp4mCgz5LfADfqqWrXwgLHorvGEHwxH0KKyyMqYQ85CTk7XqRU4UV6JHrv0GWTm81QuRhsGx2uu7qvsyeP8cU5KkUELuIXRW7ODMqDo4VqoW7h)JHVle(a4EWUeX3dcFV47dF)7h)aUWhKIMXhYfUnx4heenUWhXf(OUWpu8tIF4pd0TEC8Jayr8JIF)4pGl8JHDJFCC74Nin(jDHpb(K4FCx4oWDIp1B9(W)TWpf(PVB8Pjs46Ls(3E5goaUBquHBf37fX91k(m4pi(zHoz8zxTurTRmWSDMC8Sxg)HAf)8UWbBfhYfoSlC)qV2zYaGC9PxaX(78i8D9F)GRYN7YLmmfYfJF(wQ(djLwiDbWTPD4Ccg8MeqNaXedXeGsoXvnisCH5HliK2zEgqfSxWYdNHmVIjAjbLCbvkil8khfQZBOPRwqxWWijfFDQh991cPjb97Ts6DpKRL0vnPaCehVSMip0eoZj5YkkKDMbWpCRlnlVUeFgzH1b0FwqnwKkZ5aBxLeAVlpTRQ12ZQNvKxPGGXXpjEQHjWK(sSppN2Rp2XwxcQdWDBUW1YxP2sTADs84WZy)4jwssjSAXm8M4Pqqj2(zpl(cKcJb5UiEmwoBfpXYf5NNvfWt1g5P3(ZANxejF4N)ux9H1AZe6PM2qKpN6CtABmEzAAKdAh8e10woXj0oOJBOQ90nyPwwXnuWXsnQ2dsteS0QsSCKDcPCMIHcc)8A0laM4eYrt8LxNPfnLDfyn61jcCP8lG7EfA)ovMgk(OXJGpMoOGsRFSQp7Ulx9xHMw2YEZAL1CYdEZ0o4a6sl6(8L4ZrSr4ovknpvARtZCxmDnn4PZjKfS7jpTMoCcXQbQMUSY14AQiLtCDAAZb2pMqNxBPjSpz9k1hQX7rhl1irJhXUJTgZjADUn1ok(GAULlVSQQoRJBwOIcWW0vFqepINy9A7M0oX2u4SeZeVuXmc6x9bPLgOtftsxxvxeFxtUFV(oTp)zkANW9Ky)EdaG4viWGP1ynHRzFxCLvD2WoHXTRK2gqNUi4sIJDthBfBXlKnTdzFs)v0Jflxe2k5AFWOetM55ZkCPG5YnQIXLMqGFMGeVXxkMqoj(lzNtJlfwspRSW0jlQQAkEAZc8CZraGd98p)p9L64)1AFY1Sl6QCHa9sF9cgTwZUEA3UYikivq0mX(95)0(7nddHkUUZwRGitMc)oKmyPH401xW(7h)6FQDTn2mzb7dtVaPw53Rtd(AhemDg02ij1Mj4SjtfRI2Da4po1I8ku2nulFiC4XxgU1PZkZByKoJj4)tX8OCflb8ZCXrt9KzmKi5nZqJrChJ)Shf)ZLoeWOj7rXFwxHmaWf5e8d9I2(CEuIFgokvMmmhF2(FwI8Ki0Ist9cvXfKZ7d)gAhEmilUdlYt4JjOlb2bYAu2f2xSU7TI7RxwS(objfr89ETYM1TLflPc()bszgUwotzXcxOrIeVFkbUQavdkijH9DNEfQpJbK0nmfx1UmYklPjsC0vgMt0VjfO2HdpsWyjsnAOrcg(CGqpAQOJd64vLi2AHxRAkmmhr06jGJJ9qo2BGLYQwuJurej(yJGVenN9qDC4Pp2XwjUDFTpL2HQ68OQG)SRQ09GctgFKOxwBoDjfclibXLPTksvot04jJ2FKvv1La5gTpyPXJWLkA4GJWGDZBd7Eax607siN4vDtDp(w4FL6K(43a)ZVvsS6Y3kBRK9baGyLoNUPn5abio88tP(8Ymsr62YaIZ63e)lIdD8konXVWw5TCxRjQDiGIDwDbtHPRqlOggyFDTq7s7sthIs5KyEIrGIWNA)LPxnaHCeESwxPkZgrCkeiFlmWmlo15kCUENzck5lGJe(1)S4FArqhh)3ln(Vpvl9ZDs8)a8phtjg)5Pj9fOhFTp7vpdEye(Ca9R)4dIhPfCSYuTWXfXJMgNqeFEeMJYwcNCZeKivJXOSIkZbznBxkAeYS4PA3hJfetimmdztKf(OhAfKixAhi0Qu8lbuCSl6282agodF1hgpncN(ANWz94eNaNHXBolohwaNhx4LXIiSe0wUmEgqklJlIWkdBd0i6zbATvSkwdBGW6iTo2kxN0Y3HBz8IytCj8S45WZdL(hoT2t28BLLg(JHFPtG)iiTNP55EZStU6HX)eIeo2eLIj3NpVa(Ej4j)3gHFL04Fs8Rw2FlmypEFbhzeO1(3bFvr8FxTZSZHRSblonDCIuy6RLyFb6bEu)unqMcdD51Vl8NaQeas8tkI)u4FXAQLjAqTe)TW)BQuZW)BDw(u1EBL)gv0piPOltoH9ay8sQ7juP0)44xRI)F4b40PpTOFDBN8vEglFJ4bh)P3SZB8pJi(N123m(ZG2zQRu7TFTQ2r5OdyKylDzk4Ga)q1ywDDI33kxl9U1Am0L(la(vXFj8xMzO9xcH)hMg)llI)hr9fs9g8vq4F135Y4FnQ3QbT9w5TlICRlgeX2zf(Fm13uVz9UOEXlmCUo7b)pre)vX)64Vg(Fk(Fwfxo4)5BYzJJgp(FhTA)VV2gm()q6DVlh8B)ol6W7c(R)UJFf8)I6CJG)nAGtGHOMObBTFdBB)9nNPGIsPzIn(q7sB)1o1fx25u6jc2kmDpaWfu0XmaAptF2ZSXHRpD60z8G1NkNurTJvFIvMQJRv3ZS(P(4tCB(uFSVnp1hHhEyLX7Ym1qJ2DJM6dcKEFminPA)TkdsP6QM0obTSMPxHDkHxmqrN0PbnInQMhYfsVCL83EVEGMmmO0Yjmnzwf4nv1B)5olqW(G2I0KsMLOuxO9mnqfyykEWl7avTTbQeltApnURlp(yziSwH6l53WL)9xHo3jjkjBiSu5zmSnV0B56tzO1Y96)weiIdDbHab5gOpVJzo1Kv1fKO6cVkOlSkPBdgqdzgJtthrczemImveD7laNFs89LoKoVuU0BLEZSCAW4OwiTpTzHscCqBUqrEL0(avrqInh4MEH8sZkaJQIEEASN04xtQkll01fjR9vljRJxHfe(f36j4Hs)bZVZi88odt54CfchhcthNuxwaOY8HtJFPhbOLG)O4pwz)S7RhIRrMF8(iECBMxw)Nv7x476652cVSE9F6(62Px2PUnWlB8gmQMV7ES)XFB8LENzOUdNY2D4K(dk2vbFDFL(wCRDhwbhLCpch9BUf0OpEfHDxNUhBov7ZpmsSMkSFYMjSzWghY6N(2ez93QosfFxIGMXRGjU1omXKHUWvkjPlq9CLIYMQcxJBaGagacFBkq4PTbcHMRiF)t0B8HwCMMZlYHtKRp4AZy646MmnMFN6SCNpw3929OrIoSwOQwU535Sy43s)PBL0e)N1ij3TY(K1j6Zo6tUW4DmCYy5ZpXmCv7tcSZ7tcC1hN0lBBBOHeLy9qFhO3b6qSst6DEd8)PgXjaQPeJiS6gyxG5FzTtuHOrLXwR9uBAORvzJS5XTwJNjPYEM0E8MuivgQCnJxVh6417JnQ9EzdAxVwxzgsnyUVRwU1m69x6Hi(7ahF2Wqcbc8FqA8FOnFb8g2mfW)rBnnb8FCA8)L04)K04)RPXVtA8FkLjabK(YIuSfbyrqdeSlGeiGccu43fiGrnCshpDV0bp1kbB8A8eS5zxTZZftRuW4JDopji4taFTRXMHgUQFGVhEQ27HsO45SDeW4b2nLhizwAE7AZCF1M5QsawnVUBHJVaWXcpvRoh5udwmSAUPvzci6IP1y6oGslOFu)sW6yaljf01aEyUtAcK8Cm(g2jgWiw0NX5GtefChsG3W09esMIskApCLlfzEnvdb3K5hrrWWO6WuUB6Wu(I3EpmLnQ0ocvkFEJnpMfj5SZ2zSf6yO5hUrJz5jwrkRQcBvsF03hPPXmUSEwvv5CQZPKCojWJ4AL)jjade3CB)nzT9F5qE7RNE582va)9rogWd9Ox6rF0JDrp6NEmaNVa(6do2JhVDRdL(OkYaZABVC117PpuqUydm2i1Ac7AZiiOfKS(fMCKHFiw2M2ZFMVZ6fKvNBaI3DbLSlWGWHiPjUg42Fqz7f9uCzsAjzrla50rOHcXrwLCE51)JMNkRKuR0RvE13yRHjjf6tmLOuwkuQ1LO)em(SEMsMMQkJYwPbAznIeKLdrFESPiweiMrma3(j02Eg(k0AXMmiUw04XJWnDOrtLA0y4x69ZS3bdCBzOcYc(H1z)zAv7LN1(NzRU8V2PuELhTdAIPfajp(Pk)lYWSAf)6NFN546EdrqzGo1Fj(U(2TqqLX7kQASc50K7LmWu4FHwuvTi1Q4sLXAPRy88)T2HlNizEl7xYGS28WG5i2ppVf6Xtt0ibovmTjIkYXydr1wBQUuoYMsHOX4G(8gcZRjXgpBkPIeJuD50ivA8fjRR5P9EAI8JyAOVwV6tG)ro1GW)1PX))e3sZedhYR3Ua1d)D5Rl6r)0Jb2c0VfYvTaFl094eRBHUxga3cDFIwO7h()d0Qf6GhXcDiKfQnAFSf6bbWQf6WwOJa)4OwOhYc9WhYcDS9cWNf64oHCwOhXc9OWZ(9tlpl0hiTf6XWpLfY91bWbKTmydH(057ku8KZ0tKEYDEBuJf6jOygl0twfT8)XcDI9AOHRDLq(4CD53FpE3r(dEVGiDwqKsNjlAiYnJcvjMjI)8BsqVs1mDGrMDtc8PabEhlMyKPgvCg5RmzZe4)f36f4VzvbEapETq3D6)MJImrQR1grSROAUzr)g1MkrwVd03jI)CtXNiqUa55hU3Mj())Etu87jeqVDU2hlbULVVdAMNtsw2Dy1If5vYP9qvsoyYercNYDSOjtgn(GoORgtvPGkHMzijtbThPs6diivqXD)azyr3j0vlQz6iSchu194a5lDhpxsSX52u19q8ZnJ2JwT4LmYjbJ)I4VAZLtmbLCUtiy6yg85eMvAwbAIvZx4WUhnU7yrCKu)rc2)fgnEehljqYOJejE4iUJp6eoxaHGCdgjL7OXInw8iuo0evMFtQkdJ2mNHgFwH77gL38QatLsfvsskmA0jgidJUdhVm0xI7w3WKNexSicxxGLB1rqOZI7vH0uY9FOwxcKS2LdW0NWh)Exl3ck8fLYsN3yG1FidvDtSNLlOlXcVT7zjYPeoDTZ1pNSurjZ7HmVZJqotCdGLd84vmhGpRPQEgUG9hDSKz05ZjvY4vUxGV)Y86zz8lFLJwgaxDLscklOBASs(sYYSOiiDz28Wq0bE73L8nWaga1cgS(SRgsE0yfeJoZKdo8vFs8pc1C7BFdqi9QmZ60XjqxGcGtzwASlkRwyLQPdcWhtF6(dgl4GrwJgls6sMsa3604FyBbWVXkSaE09iQfWpohxW4dgHTKEVQfAI0eJntAHMIukwOlyHUO9TzHUefrStZkxYjafqw2V6H4m1b9MqKOxu7qKkvbbfbDPSjfvNBuL0RxZpx1G(hob(ClqxbwQPR48ffoWR8FdFmo6pTdUPJf2MvQ7YHwK7oOX2DNm7HaGuvxGeGraOri96WOELtwU4wZPrK1R41KCj602qW9Sj2Igux02qAThKCUajiYDMDI(rMSLmmbv)2y)1o8WHoAPSADNNga5QkDy2PBDbZs6kU7W8IEFb3Q6UnVOp7)21l0PBOYaN5)fCdwn2gxu2UGUFWFWr5sinVGCnoQOlYKp2Kgq8ybE0sZ8MrCADl1DLf60BnXel0Zqe1o9izHsrcdFYlaquqhx7uvJVcYVnUuWmsYsMlmntvEAIO1wYYOUQ39mLUGwP5LNiAtCLzH6El9Lbnn8VpUlDsm4pAjt66VTQHmGRYOcdUSi(h6dknQ2Ed8YD1dUmnE4PJg1aWsKiEKoMxspwXm0lUanumWqvYKLW8Se(HT5fpgIIcPjNUTfYD3TnpAz6Y)rkYLkxKKh86W5kgYKW8fUK2HkFTuLtgQvRBdPzjKMw20slDT(F3ERtoyF95482L3UdqgiL3EPh7JoOk2WS8sp6JoNdDtMZb)(b2AE6X)6GtHSIcgm9)1z6)GlvsKsUBOUFQgRHyH02K6H3aSJBP(Xobq)QLb0mOmfwVc12l1wB6nbU7Qy9GBl0v0oz9yAQLQPJtcmnHP54Nvqzav9Im8CWcZMf(z)66xzZ4zXQ45E2o8mG1Oqzluj8p0cn7wdGTqZzHMNcxTqoGQwOfDctTqF4Y4tl0lzH(iKIYc9rTqFmOWSq)eqxWlFDJY(kmIkGphI)ncbVi97WFJf6fxkNGHjZfi1Xxraarxnj6VkFX0lvoDU(hT)Yo)kxYwOpzn(7SqFk873cTmuL)0W))zSq)SL9PzHM2cbPXd)pJfklbOAHYz(cKIsG5FYcL3cvaYG461qa1cD568WyHMbYMmZrcTdwr70BNpJY(k6661xrDAcoddS7W8taD3nqtA78oKCoP8Mjn1LMrGPn5z(e9eWtQGZlnyt9o077r0MEXAwoVFV0owVQVx79rI3f83NgDl1SYvnd3FGJCGgc8x1XiS2gy)nSXC)bAoxNDcO7nRzrOCI8yRvvT4Vtd))tqnPdn)gae7yRaICQfkjmnTVH21WGHPKhtzr5boF4jgPPWW(Epem8pPmmu7i1eoULdYQ2Ew83SDFEkhwI0xlHAcC30nnsflpVqwOpUf61Sq)u38iuWIht4qpTUNtNGaZ2enIFYJ3im3ZSng)ylwJAEtrb6SBWGEXYVO3GtKr20x0MYN4mVxe6zH(8eRDFtsO(zJZSqFH0BBiWAdSU5cP2opZ7PqQgYm1c96mqsMokns4lxSJmfk0uqYh8ocqYtG)r7)gWnzp7k3KV6VsdDtUMZzq8MTFYTBobUz6NeA)1bWyqRcEM8kctLz8UhBSMcTE27uGw3vZHwk1aTMSD)EybyMpnA4ixoOQ(IPztywnVnPP1oATVDPo8vwbc6OWBZUSTqFPAkAl0xg()B22ZTdaUVsJP3Tu552(MiMDVYi4oz8eVYbAm8mCSXoF4XtmzcUjAk88SVN0Y32HGiRl)2dHYD2gcHwP6AHCZ2W3EYS9StGrqtTHWO(UIsH(LLoNU2cnfg9C3PaJ2jln7SuCKn)OYI23q7GH1vNlN7Wv2zCiiRD0kZEdlMVfmzg5j(fReOJBX6VEsoYo3dpnahRd5KOlJfguitrpD2FtroFOBRroFUQHGO9oIeD3SzQqjtnw8AIGXAfK4lETQH7JJ9WdOGSqFf8uRtU)PJfj8qbJhnCtlil0VwT3BObIeKBtrpzpSaeTr3W6KBOXpST5o1dpA8bglzKnDp(TJYtYQK2W6i3OJMAt3v5bB2ONK9QeV5Uc73N0g2WsemC0bMA3CRAhmz4HgD0rMokzxnGBSeP2MB)6AGAoE5exLJSLV4omzJIHeHhC6KF3wVG9f6Ayq)z5bSTb9xvFFTC6MIwM0vbru1WKoc50oEJgRno)xUsE0zNjCB2sqmRtZlBAKDonXyHERATVqMZGo3Ujm1KSASjfvnzwJYwOBfTidePROD0uRrp)7HOd54nbjuyEdZT6LbHXCQcrN1dYIkKXOHmjHldW5zJKaesjRKsb3Ko1gX7HWncgU4BV34sSSU3nBpIhBN7r8vzq2TDLGHUGgdCzqXslm4qxEIqZfxqTPqXGVxIsL9Kp9X91TFFH86XNhYbFHceOV(4GZ6Pxo)b83vVCD51Np)wONElIfUDAaq(ExcxBbOQ7(hVJb65cdSG3ynfuf6ocqLhluGvgAuUOxy04PcocUL3UYBMr4(jb1Ma4sJx29eGxsXkVzg0lb(fKkkLJgi2vcdo6viXNdje6nQ9gMyHzf0vSFTqoAn3aVMuo3diPluB6Xi7ospnXmyLa5JMEq9S8kcu7J1(iCovz1ElowRPABHdOliSiXABkDETAlTKz5nj)G6CRCCZ9u7ZrGZzHcF33OrnNfQ)wTFHVSqdqom4MJpol0qLdnolu0QbfNfAy89VFl05WGKCK7XcfRDU(TqXHZgfSFMWcbOpoA4TzHswnU2CSbiwooPmSqJvFmTH2tcPT(Mm0Kr8D5yZ5BscRUTZk2l6miT92xGE8ZMDHTOFCZZRWgSWePCdR88RoYSnE93RbJVnZZGpELf2BxksXRBoDb3HXjvDbUTf67tI8e7Te20mRz5fK1h2BQsblTytxwXFBWAMi1AwW9S449uv2FpwrTQWQ2xxT04lI)gvgpriIG1rooflhwOFC4erswRo2HDIVYnnFu)GkyLfA8CX70O3n6usTlJI89o8Xc1JpSq)b24cpx2Z5K70FMOEVqtXf4Bc4cx7vcXx4xVHcXLR4F6oDji0a3sjyhXm8mUF5yN)kCnvc(7C7Se8CVDJvdDsL4oDH45E7Twi6BivoTHlmCFDNSPcX1V1keD6XouxE8hOz8EAMap13ylwhGkee324J7)8n6kGw7WH3vUN35V(C1iTNCa)toFaZIP0BUr3F3BQoJTqB0uNWwO)O9ixWV4MHcRq8WhuEo(fmSHe()YngsuDSbnfsCDVJKTNT25VBIC6mF0U0VC0H8SqUMIC(pEta5CghiJTd5SrD7JBLronAFE7u1UvusaxqEVHqxwO)h2OQ(BSHMvDmYYB9WQ)N7)p8wawkvhd1fVIx(oNnqtXs)E)niSuZzPSfbUJfAL705MSPqYXbojNGrmzVdxyOzBEeP(DUDMG5weAYwOp3TXIUDPIDWc9vk4mz46JFYMkW(U3glW(QBX7qrnZI3TXIUD4kB8vFHgph0ojloNI6561OWyknFMBSUDw9BKNPXJVZ5mVENV0K0m3oXzU(NpCgdZftn58nvC(9Ujkojlgahx0bhkfULJ741k)8LKYodvwyuzAW9EZAwWdnsKbs9U3eHxDtAkHUA2gnh4)G9K5aFq)zte6C97j(q(3X7Bf0bdfwwvrWiD5rx3T3aEUb3ZsUtBbHVo949xXuOcikmg3mxjZeNxSPkuv3HkQxHIUu9fzluhrIswHTxc)dyRghDH48sWJlA)3pCAI4N8M(gGUoBnq9ZzjsYyVqz22cO2M)p)6Ab7c1)OteVU9oADjLzemDtUIw7vsEcYRXUAE3MIcUhqv3GFgbfwEQU9qerrO4cLlaN7K0GNu3b1lkKZXoYg91cHnVBUhTKZSZkgYUrDd3IjaBe33EMncFPgnX7EMiwRQjIzt0ade52B24hYnq)(gQ4exPBfF7eleFusGkTKKPqr6(FWN(pL92QWNg)gApCd27dIc5Stwe6A7dg6MPV)RLldWgd5nqTOJaHYQL79aF63PAjB1Y9vFry1Y9t2WhA5bQ72I(f2D32V011T14z8l97wea2vrsqlUywOmZ5BQOZMqOuh93mluT06nrx(pXnkdUpWZ3qgCAhUrMEU(PYL(2nQCq7TzYupde7CD3xXoLl0Cz6(U1ltjXE9BOB)bZ84C(95RpF4ViBBB3o10GxkVKxWsTdt3WbCtcUn3jlLnRa5d)ezz5FRB5KW3r6GhLkVQty1D((86VF1XegAQMkS2)TjclRwEWZeYR)(O7CgEP7CgE9sEvlA5iGKQ9U9qYYdr9KENW2y2oL)x0B0HnxrEBwsRVfpxpDTqWMkV)XQqjm6Tk5niK(RtxE3OSlpDr2bk91drW7Rxp0nL1ExfyIr22kiFuXwIpFEHSMc5y7UDq7FdYgmIKIqcwMsFh82D3Epo5l9BS1gf6VVzdE5zJDLlm4SnfKCx3ebjEwXqJxFg6UA2rOaMk7S4RtVsLVEEAhQMFtWcyae84InCFzNyU(pRjV7YLXc0nEyhFApTdpTLYWRx9RNNVav)UD1xaYgP(A06cBN3DkGx(WhfFSvjFS)G7BA4)2aImNG8Pv(e7AqXkSDsxY8eGFPJWahx9OSVahRD9wQ)lD(PdBvwjZMcey8C)RiFGWOpH)1iAWJ9iL3IEzFDV8bnQMaip2UcqUbTxSYNYs8YKpYce8jduuDJoMyfH8Hpq3UlgGGoLatIwMkgnKYjyH(l29JrXHXPvPL)q0VjNNf)15cllWRakbSNB5puOo2AliegGXkgIx)sJf9PR(RNojf2sVTQbnBlWW3Fce9dZWFovJagvuXbxCQjkAwOJZd6x2pFPC5eu4Ihz8iC4VMf63QMVUgFZn99VR(xXKw6KON9Rsez0xtM2k2wU2YD1pqTFzMW9G)lPVdeFFl0FfX8G9UpozNh)BFGBZ)cjD3BE3g)8x4ctfjS28lA0vd2TXBZGRRth40EAB299r())
```
