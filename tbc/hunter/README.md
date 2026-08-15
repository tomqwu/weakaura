# Hunter TBC — Beast Mastery & Survival (v10)

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

## v10 — Diablo globes

**The rings are gone.** Your health and your mana are now **globes**: round glass vessels
that fill from the bottom up like liquid, with the percentage **inside** the glass.

```
        LIFE                      TARGET                      POWER
     (-300, -150)                (0, -280)                 (+300, -150)

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
| **Life** | left, 116px, deep red | Your health, filling upward. Goes **bright red below 30%**. Half alpha out of combat. |
| **Power** | right, 116px, blue | Your mana — always mana, in every hunter spec, so the glass is mana blue. Goes **red below 20%**, the Aspect of the Viper line, the same number the *Go Viper* prompt fires on. Carries both aspect-swap marks (below). |
| **Target** | centre, 76px, deep red | Your target's health, with its own number inside. Disappears completely when you have no target. |
| **Target power** | beside it, 38px, blue | Mana only, and deliberately **no number** — rogues, warriors and every powerless mob draw nothing at all, so a small blue vessel appearing here means *"this one casts, and here is what it has left"*. |

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

The one thing outside the globes that had to change. The target globe now sits at the screen
centre `(0, -280)` — where the Serpent Sting and Hunter's Mark timers used to be. That row is
re-anchored to `(0, -60)`, the band the player orb occupied until this version, which puts
your two **target** debuff timers directly above the **target** globe. The icons themselves
are untouched: same triggers, same gates, same sizes, same order.

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

**Resources** `(0, -10)` — since v10, three globes instead of two orb clusters, in two
draggable sub-groups. Every globe centre sits at an absolute `y = -280`, and the geometry is
the repo-wide globe canon: main globes 116, target globe 76, each rim its globe + 6, life at
`x = -300`, target at `0`, power at `+300`. Those numbers are identical in every class pack
here. All of it is drawn with two textures WeakAuras already ships — `Circle_Smooth` for the
liquid, `Circle_Smooth_Border` for the glass — so nothing needs a media addon.

*Player Globes* `(0, 0)`: the 116px **life** vessel at `x = -300` (deep red, `%` inside at
18pt) and the 116px **power** vessel at `x = +300` (mana blue, `%` inside at 18pt), each in a
brass rim. Both are always up and fade to 50% alpha out of combat. Life goes bright red below
30%; power goes red below 20% — the same threshold that fires the Go-Viper prompt, so the
vessel and the alert agree — and carries the two aspect-swap waterlines (red at 20%, green at
80%, each spanning the glass at exactly that height).

*Target Globe* `(0, 0)`: the 76px **target health** vessel at the centre (`%` inside at 13pt),
its rim coloured by **your threat on that target** with the threat `%` printed above it, and a
38px **target power** vessel with its own rim just to the right at `x = +69`.
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
  **Coming from v7, v8 or v9, leave it checked** — it is the category that carries width and
  height for child auras, i.e. the thing that turned the old 172x14 bars into rings (v8),
  resized those rings to the shared orb geometry (v9), and replaces them with the globes
  (v10, see above).

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

## Import string (v10)

```
!WA:2!L33c0XX1555lwYiQvpmjejLiLS1kitAavjQ9jEqlARDxSlWcI9bNDXlskHz2DNDNHy2zgoZS4LLTLrvurTDuDGtCQDBCIWXsjnw2Pg1jPvTXTbn1nThNKRrtCg7g7MI0Mi1C650WZjTPjo907Jz2D2flwaccksQWZHdM9o35o379)7)))7EV)ZDaJ3zHF(ql)OBKNRWmf1uuJQiPOnIlxUY4Y7zcP2zbfzdnfjj(IrfeLkQXl)eQhF4QYg8AEEkpzK4waDYqsk551vpwT0ZXPvM3GM(M5v0kYRfX6bOE4isIlUiNwrp5uuKmev1MpDPs68gG8QCOY3q9KwLtUirrLvKKEoTNSv1MvCwoP80ctqBb698Tp0QA8LfvKZTGkptznLQQRsZswXf5p4AIYLu0QWzGYH71OxG2cbaGRn4QAiOOLwfFzD35rT1sILDRXvGKqVm6gCAgUZxsuwuxWDe0FmCVKHMy5Y8A6PoTM1PF(ig4Noxvno)RJpQRYljjwu)KD6nsv0nLxL0pTej9ef1DVPE188ZIARzRwQK48RnD0WzZnD2CHzYv7sz04rxIjBMyJo61QQZhBEu9klTeyzK5QWR7E1I85rLaUXRnCSrZeFSrxb13rRwUxROO(vQkJAnZY7Ntss9iCKZZrVEsLI8VX7XQ7kwXY8Qhj7vRIebEIxvsYZecIg8RtVkTZ(UxHtwK2z2l8OXxNNtNpRbsKv2q4UGNiISIm)gfrTFCoMg3NOPZJ6ulQVeoR4Aj0BKkCIYXHpn6gGEH(G(Hbq)9ynNYk68sLYOikBKpASu5IX0Lyr1oRbWy41vQQvGx)AI4uK5Kgh9Wqp2lTwjnuxdQAXzW56ACYfqs444KWp(8zJYelwQvnukmln)hkZX8xvS4AsZ33OmxD8loF4zy0lWjX7AvKGGHGT0THojKr9cUwf3KePyMiskCfDVg9XqQUWEx(rHGAAqWog5A1Q1dZZjziOEKAjmQyjEpmIv2Owkj5K5C0oZOmh6VOCapi8hdExa4HG9bDlaVha8EH3h8(pi896gEycAgEe3WoDdFaKOXn8yUHh3n8btDA4d95rDRNe(WiSi8rGVp473n8rHEGpgSl4JZc)aUHNcEA4h0nSBypWN4nEpW)oWNe(u3n8myjCZsPG7SCdgc2lsubDb7)sWbCbpl8dbFguNm8CRvTI6vJpBpzhVWvGFexWN1nmSlye3WOUHdI61oBEeixB6fa0)opaExF7oxJR4vQQBWxmj38Du)hIYDG7cq3M6rlYRZzGbD8ytmytaYffwthlX5NhDbEwN5jUcYEbnpm6sCYgGL4LlgwUSe)lDCuDEtvnLYA866zj4RN4rEpDGBsO(Dx4E3J4EjnfdcahWWjPkWHAcN90mfe4lmtC4d5APz50e5YlXVbc9xaPglqK5miBxv57kG3Uuu78z0kiWjxMx)KNgo1iyyYazoG3Z4Zp9ORLq1b0DBSW1kvR2sSADA44ONXbHtSKOCuLk55mGtbqLyxN7CWlIlmkK7sWXO50fCIvQWnpTkaNQt8tVRNXkVaC(Gp7jx(Hu70a1tnTUaxrL5M0Yy8kK0Whup8PAOTCQtPEyh3qD7PBst1wXns4XYLw9bijIS0QGTCuycXIgcrcJ(51ixazIJVijXp5guTOPSQaRtUowGlwAbyVRs63jY0iPsNkg8eAifus9Jw9P3TD1FvsAfS9M5I2CkH8MPE44AIl65cv5kITr4jxovV1ARttDxmDdn4PlYxaz3tAAvn0jyRgGg6YSRXnurStCdsAZHSFmHgN6styDYg1QpeJ3Phl3OjsfZQJTbZjQ9Sd1oc(GyULPKKIIgTJBwuffbdzR)GWEep1gn2nPEQDOWPjMpv1k551YlWlwwW4T3ZwhYxaHSNEbmopOpNMQupmsPpSL6nrBhzMmFn9zlnz1pucSDXsCf4VC4IftlRF5j45Mjm2L7LtYxuK7Yw5u)Yrf1kiXpD2kkkgcNXOmhXm0Qex6e1Dam64RGEQtxqItxNnVbYOVSXXzQufrkXndj1tNxxeN38dpg2heC5Jd)0SrqUXlCC4YUJOJ6rXNaFWN3Yq7JGnUYq8FNNAT3YO7s4NeMlalX0Bn7UoVp4ROE0XqzXtubomjeEnre4VGUTD7pBt3RTn78ve10u0eAUtuuwaEVxZ2GMbTNzjfKNpeDeD3RGGhYfXSayImASudsOUWyBDBtDspxgR7MDvI1Y4IA6gcRzvgfKevfWM4VMvHJr24cu9OrhnCYm5shz0WrpF4bhmrUeJJq31LOw4VRvpfQDem0WBihh7dFS)qlvqPIkUIiG9UedEzso7JyY07a0JUqoCyMdBl5TvpsDtNwqc4lH8bj37q8tMA0exrDonrzmhaEHviTmC1oFIuztmyS1u0ercqs)WsJhJjxIOHhLcDN3c6(EDRrUl(Icl7H4C4Fm8NTjya8vG)d2orxt57NCNeXOhitHADq9sA2HcHn3hK44FfkLanl5a2v1Nh(ZaJCYAUmGp325RypRnREeebZcA8g8txZPyd8pEd1i7rf2PJqiCvtVLWM4G2KlIJPgahZ1Q19RlaZbqY3YXNzXPoF5Z3)mtqOEGyiaFX)I8uFhcinE4lZc)7r0z)7FA4Nc(PPQ0WpdjPFcYXx9Vy5ZchbappIbYVzNWr7aM0MTbmLamnlmJa8caidHWam7w5iGRlJrigy7gEDlRQQy(CWP6YpLiavsmcfIJfi(jhCHelxExi5Qv8lH8YBv0D6Rfo5p7YpeCAaK9ANYz94uNcMNsDSaSiKhwcw(tcfaqruB5kWzqIAjyfauEel0gwHlKlxqfOkuha1aQDVDEpiLVdptWfHgWQWzHZbNhv6Fuw1pq7VvAAWpb8fof8JbuF62N7T6GE5JUHLUqsQXrmLtSwYKhiqWZ0)QywktRs9WAB9QUTpReg3YhQf)(PRGTvsUj7uqJwIZF4rhfEIvTyJGDtDeRtgSo80UiT9KD2DVIbDqzttgpgrH4vZCGb8FM(x3QiRB4SrmeA0cV4DTUvf1QPc)6cB4S1YlqPCG(DeBVbWFMLpk8FEToSmKom4)c0n)Ma4)sw4)k4Vo8Bc)xJGh)BG)gcW1H)BTRrWFZrOMKSmmrQbW)DKhl8Bja)3Jmj9I7D2dWp5wjoaxsa(3fzANyK4hhS70Wj2P)vRB)LHmmlSn4vi4jmIf0G54nWUVRDn29QvCu)5Nd5tg(tb)PPgO)hcGFbw4xua(pI4hL4f5lbG)CVLa8NN4PBilpD(cG7tdqLYyhDWx9THRs8P1FbFlQv5IJuSN(GFzb4RbFD4Va8xe(pPMRk4V0wCs5OXd)Tiv7)dn2GH)hz37UQGFL3AEhELGVX7m(JGF1MC)a)ATW5XWeR6iZZ)Yw(mgyodEz5QZKC8HD4Zadz3TUlACa)xX5eHjGmqy4joImPGJ5nZA(XSMpGJ2C6Kjb4bAovgXkQNO5eRnbbxRPN5DAtyWb26egeDKrKhpGrUHt3BRMWamK(auinUA)TSbPeDvdsNGAbd2vPNIjwJ44J70qnInRNh8fyxPw(7QFVOMmAOC2jmnES4CgkAD9HphIH(HTePzfnQs8wq6zAHkWie8Gp6bIA7wvj8JOgJBrTUZRe8e5XCEr1y8Vrx(pCvYCoKPQKo)s2Z0wN(i3Y1N6Gl7(9FBmiXH2aFOWmXhW3ygtnzDTHVorB4LrAdRH74qJjcptRSKb1GheKavjrZ6cOZpn8(yJOXjwKD70CMLrfnuSfy9RolQKqE1nwOcNmRFKYisMnhY3(cLeNLhnWmY5SqVSWx9RxNAg46Iz2bAKz2jRrDc(8B)eJq4mb52DSKERrieJUkMyeMEKt(olG4)8rzHVWdJ4Ya)4iwnV4x42aVGPAXOv(U7Z(V(DGx(TejUR(cwURMmyyHaL937vhyXT3DvnP8NEFsk)pBByg7g(IjVnru8TAYN83flhOULPsd1JI1304VAvrnEIH)CeYi1CvFdiN(DrYPFlICkPLCkYCv4gCI(tn8IZ0EAfoSbF9HMAhrb33KzbaBYSxPK92FVPJLye1i1n79A7EsaV226oA7KMW)Swj5Uv2N8DWQBo6tU44Dps2KLknXmm17tMA33Nm1YpgUx2s1TL8mO9q)(OEhuhYFalU35vGF)w5sfvtX6406wnJZRFQA(PRnAw1NCldwSUZ8TosXgmRlABwx9XAtHuBWPnmc5(iJqEa64K7NomzTg9dOl2IjCTE52W4LFHhe7Sa51WcgI9(c)JyH)xTC2c30Ynl8pE79Xc)VXc)VZc)tyH)PSW3If(2e3Oyq6kceSfgyHrdySlcjGbfyOWgi(l42HFYik7Nm2dxySXR(AyS55wRNZNuTA4uJDEVzW4te(ApJnJmsDZ0MWP6QpI34pSLDAknQEj0OWZlYxPXmpqJzUUeGwZB6wy4kJiOaNYLZbE0IvGPHBAnQaIScoTMRasPfPF086(5GVFwEnvejgpznqmKCm8a6j6ic)AZ4KBVaVNi8C6gEMq0qquw9HQDPyZRQOZ7bpzbY8661z5F3ew(V6T3S83Sw7is1sL03kLFrPcZ2tYf6E45hPvu(F8vflOitxAUh59GBAuJlBuqrrQOYCYzNte5rCD7FIxvBHT22FDAB)xkIVb6RFgFbcfCa8XqEjh9ro6NCma5yqYXqm(d5Fa0X(86RxnuPNwwcrl1Ylxt9EAdhMjz8XgTrtyxBgEE1W41pWGbZDxW2M2ZE2V7gLLuMlo27oVCHfOq4i40ewh52FijRvAtyfCAzPlrn(0rjR)(XwdFU9IorYtTq5Wf5A2l5dDHZWPqEI5eelqGsUwI8tKXNnYx1WqronDs(jL1OIOSCeYZJoZScl)aedWDDk1DMESmPwSfdIRNivQymthjDUCPtcFH3h1EhAupRGQG0vCFd6FMwXAnbT(zH6R5Ovk2l3L1k1pnpsYdFs7FHhJIl4lEHDNJR7ncgLH0P(RG313UdmQmvGekjlxuvQF846q)lYIkkviwfxYgRXwZ45)B1JANiEs8guuhVGWOrcHTFEbtWJXI1irCQOAtyvKtqhFNL2utPCSTKcwJXb72n5NxvKoyWCIvWgPc40ifl8s4zN8m(odw(HnnmGRLFC4pYPge8VHf()tyBntmseF(cGupcgWFaYXGKJH2g0VjWDJaFtW94eRBcUxka3eCFcMG7h9)3RltWHpMj4iatqNK(ytWdGaRMGJAcog6hh3e8GMGh6iMGtSFa(mbN0jKZe8WMGhb9SFFKYZe8(znbpk8jnbEUoaoizlf2GPpDHarsLDM(I1xXlyHAmbpobZyc(a1rl)FmbNA)gA4EpjKpjtGGb7Z3UYFW7gePZIePKjcIexwZituIPI4pZwe0RwpthA0z3IaFkKaV7fZm6uPfMr6Qt2ob(F5TEb(RxxGhYRptWDZ(3EuKXsD1oXIDzfJTk63SXuXY6DH(ow8xCkUmHkgQe3i93oX))3BIIFVrq0BNRRXYa7477GM55fLK8evPsfo5IQpyTKdNntSO58Kmr2SjsnKd6QjvKlRGPzgr0Gx9HRLECEXYYEgergwWtgnLkQgoILTHu8moI8LMJNloGS8yO4zyU5Mr9rQx8I6ffrJ)c7VARLtsE5IEYWB4ycWz4NvCwEsI1Zx0OEsNYtYyosAWyHh8IPtfZXmQNnXOXsfnMNuPNW58VhMzOy58KizYXsfJWHgRY8BquzO0Mz0v5kWFF3O8MxdXuPAf5S4cJesCHYtP7WWjH6lH9QPBWHdgtaMRlILB9rqOrd2sEwc5(pIRLqswRYbX0hZh)ExV4cYCvelqM0veR)i6kAgqVRuwtKgtv3Zs4tXC66IzqgjXkIg3dEsBhfFMWMiwoOhVSrCUcgkA5zcpyIXYMxJROyv9x6Er89xHtRaLF5lDCBaC9fAiSeVMH(QLQkjrx8EwB28OHOJ4TFxs3adyaPwqH1NBTisPtwwiXmto0il)bG)iq7TV9nrcPxMAwNmobY87J4uwGeWCskLxTE6ib4JQn9GHtgEOyRtIfinrdre3Aw4pSZqWxzvAu25zuLYWhJHjCQHIrxrSx2embl2yZKMGPWLIj4IMGlzDBMGltqe72SYKDcKcin7lFegdnKEteCiZPEeCLQmVmVMyHSckZLwMDJg(5A6K)WWZvCbYcysmDLIRc)HEP)hWtWq(PvWfDIOwSs9yhvpE6MeqX9qThIaKkA84y7bbA4z3anQxPS2f36onISrnVM4lrM2gmUNoXwKGQI0gyvFa8584ix2z2X6h5luv3aP63j9VwXKmQJwSGAVLirTSIC3g94rJ3OQMSNUnUKVNZJIMhJl536VbEUE8GQmOZc(CEqwn2bxuwUGUFK)GJZKrCEEPgCurwJg)0jna7Xc5rJL6nd706wQ7ktWz2EIjMGNglQD6rYeKdh734Oopbshx9jQhSb4FRF5W5fLenwyAQQ80yrRLKLsDvR3zQEr1QZlnrI24kZe0726ld10G)HWaA4a)oDvdYIxTMUecxLxbn4YkWFOFuPr02BHxULp8kKGWMmAuDewch2HKX8I7XQKNCXfirzaevLmOjmpnHFyN(GJbiOqsYSDUqX7UZ5bRqw7mCrUKDrIFWBGoxwxchBPOlPEe7RLZozuTAdlinnbwsztkn2g9)UZwNCW(6lY4lGVEdHhiLV(jhhGmOk6WS8ro6NmNd9INZHGbrS182xWnqofkiWRt1)3GQ)JCPIJuX9c19NO1AiMa1TOE4le942QFSBa0VSnGMcLjW6vj2Ej2Az3c4oqLMb3MGRQE6MX0elvtNchWn8tZWnlVCCfTku8C4YZwa9Zb10U6wXZc1XZ9Tt4zewJaLnbvH)qtWSBpa2emNjyEcC1e4aQAcw0jm1e8rTXNMGxWe8XWfLj4JBc(eOcZe8IOUGp51nk7RrjQG85G9VHj4fBqh(Bmbp)sf51nOUajo(QGaqKvtI8l7lYUKD6mdMEqBNF2LSj4Z2G)otWpj89zcwbvL)CO))tzc(PT9PzcM2eGsJd9)8MGcyGQjOOXZHlkEQ)jtqjtqzuge2ObcOMGR0KhgtWmOSjrDKq6GLvpZo5ZW2xrGRxFfnPj4mcNUdZpbQ7UfAs7K3HSZjwYiRHM4m8uTjVZNPVqEZfEEXHAR3H(FxI20Z3WY597X6y9Qm7AaC4Ia)EKGdPHvUQD4(dDSd1sG)AogH1oa7VHnMhmu756SBaDVEdlcLtKhDTQAe)Dg0))jiM0rn)wae7E7aImkLRYpnPVH01qHH5KgtErP4xi6eJ2wy4aVlcg(NyddvpwdbaRDmk15ZaxRl)ETJQpYBeqdHklBBd0p75fYe8PmbFAtWN5MhHcA4mIo0NR9D6eyy2wOr8JFYwH5E6DW4hDXAukziWtMDdk0lzPf9fEI8sg(t0w(eN9DJqptWpl2A3A4iLZcNzc(sS7yeKAbSU5cP2jpZ7RqQwYm1e8kuqs(URoA0RuP78Ll3wqYh6ocqYJd)rh8gWnzF7j3KV8xTLUjx35miEZ2p5onNa3m9tIA)nbWOqRYEN8Q8tLF8EhBS2cTEM7uGw3v7HwYnaTMSRGEPbyMFvs08AhuvFww6eM1WRWiR6XB8vA0HVYAqqhfENwLTj4l3qrBcEn0)F9o)W7cG7l1A6Dlzp323eXS7xgb3nJN4LouRHNrto2fIoEMjZWmrBHNN7DLw(2jeeED53ziuXZ1si0Q1xlKB2g(2xMTNDdmc1uBjmAGRkxEqjXZRPUqBHrF47uGr7MLMDwcoYIFKTO9vupCunL5k6jATTJfmYAxTYS3WI5BbtMrjSFXAb642S(RNMbVDXWrcWXMqozcOVWq85R4TNbBlY5JCBnY5lwpeeT2gEiBHktfjBUXs1qem2OGeEPRvpCFCSXrGkitWxdo1g47F6KXIoC4ujI22cYe8pTX7ns8yHz2s0t2hnarB1nSb(gA9dBhUtTOPtfFSSX2Y9e0kkpXRsAlRJmPtNBl3L9GnB1tYAvI3AxH1BuzlByzchnr8P2l3Q6HZgD40PhD6e4DvaMXYKBhU9RRbQ54D7Bng8(mINO4DNeCeEWOH)DN9JSVqwddYpThW2MKFv)1DYPBkszswfebfDdYiKzD8cb2yC(VsT8OrpJ)2SLGywNMx2Yi7CAIXe8gnAFbpNb9SttyQbE1yZkOyqTgvOCVYQXIhlqIUBR1ON9Dr0HC8MGejkNUX29YGqzovJOZgHPrfYyKqMeZLbX5zZSiiKCbr5YEWDQTI3dMBeA4IV5(JlrBDVB2EepXU3J4ltHS74kbJ6cAnWLcfRUWqdFLjImxkEL2cfd)Ujkvwt(0NYFVb9hXNx)EXh8hjuObgGbDwF9ZemuWa9ZeWNF)bnbp12elC72aG8DVeU2gqvVdoE3X77IXxWxY2cQIChbOYRji0QdNMjXftNkx4rHD8M1EZmIoioO24rU04K8mbYlPqT3mdYLq(feRiwKei21cdoYvWXNdoe61B8gMyHz51KTETqoEd3aNQyrpXf14Bm9K4DNONcBgSwG8rspSwbozEI9XgFeoNQSgVfhR1uJTW4A88lIT2MtJtTXslBbod8pio3SJBUN8aocCotq07(gnQ5mbd6Y6f(YeehFyOTgFCMGHTdnotqI6bfNjye49FqtW5Hij5O3JjizxmdAcsHolnY(zgtac9XqcVntq26X1MJDDp74Ks3emwZX0gyFjK2gyYitgZ)vsoN)jXS62jRypVZG023aH6liD2f2M(XToVcBsdte7gM98Ro6STE93BaJVdZZGFo5f2FxksHRBoDH3LXjvtbUTj47JJ8eR9HuwQ1Ss8sAJ4lx1WvxSTlR4VlYAMaXAw49T449jQT9ySQsDHvJVUASWlb)LRnEIiybRJC8e0Cyc(GOteWzT(yh2n(k3Y8r9dQHvwO1ZfVtJE3Otj1EmkY3)Whl0m(We8hzHl8EfVNxQNG5t47ITfxaVjGlCVFjeFUFLwkexPM)P70LGOg42kb7oPU3XdkL8cxLPTsWVZTZsWZ)MTwn0jvI70fIN)n3EHO)HvyuhP8id0B22ke34wRq0Ph7ib8gmu7490obEUV52Soa1iiUJXh3)LB0vaTXHdVNCpV7F95AqApz8GtoFiJk50AVr3)t3uDgBc2SToHnb)X7tUGF(Tcfwf7HpS0CClOBbjc(ATgsuFSbTfsCDVHETVT25VtIC6PuIaAxjXWExOyBro)E3eqoN1bYyNqoB202GMnYPvBtAprJB(JyWfkV3qOltW)tlu1GT2qZAogz5TEy1)Rd(9UfGLY19Wb4K9X1ZSHAlw63)VfHLAplLTjWDmbRENo3KTesooWjf51tk5BKYdpB7Ji1V7TZem3Mqt2e8fVnw0ThvSdxEGQHNjpZaCt2wb2FWTXcSVX28ou0WS4DBSOBxUYgFJNR1ZbTtYIZjRC((1lpMC7N5gZBNv)g9PB947CoZR35lnXnZDsCwCW5JMx3yXCtoFBfNFVBIIt8IbWWKyOHZb74KoETYVqvXcZqKf61MgCF3SMf8iJglEU35Mi86Bstz0uk0Q5a)hSVmh4dfSqMiNFqVPgo4UEFRGmyOOskY86S2JUUxFH8EdUNLCN2ccFD6X7VMQqfsGFmMzUA(jUGqBvOQVdv0ScfzP6RqxOoSefVcBVa8hqxnoYcX5dJhx06VFuwS4h)M(gISoBTq9ZzjIZy)OYSZfaDo)F(11c2fzW0tKQPTEznr5z4n8GVIAx1sEc8RXUsjpgc8EIROPZndVmnp13EiIjZxzb7cW5gXmYtQNWAv4l6yhzJ8AHqN3npPR6m70IbVzo3YTycKnI7BFZgH)CPZ8oNjI1RBIy2mTWarX9Nn(HIXh0)WvM4Q9k7F3yH4JJduPLen4Rq2)d(CVn9TvHJf(kQpul27dsGYzp0i01YhmQBM8(VAxgiBm43a1kocekZoU3d95ER6LSzh3xZfHzh3pEdFOJ3Bt3wIV0E72(fVUUTwpJFSVtraypfjbD4MAHYOO)PsmBg(QDpy7Sq1HRBIU8F8BugCV)NTLm4upARm9C9tLJ92nQCO2B7KPEJN889oqLEKk3Ez6bU1ltXXE9ROz9vA8Kmb97Fa)WplDpp3kvwKxkF4xWs1Js2Wb8GdUnpzRwOap(BUeEz5FJB5KW3v6GhNiVAsy1BPb8fCqLX4hEQ2kSo4TjclZoEGZgXxWbi7Cg(i7Cg(8HFvl64yijvx96fNLhK4j9oHTXSDl)Ve3OdBUM82OQ6alE((cSq42kV)XQrjmXTk5nsi93WAVBugWBa8oqP)(WcE)97LSPS2)AiMy4TTc8xXML4kvIVGbFr6UBhQ9VjEdgruMpdntS3bVD3T)Jt(Y)6BVrHbhy2Wxz2Kx9IdnBBbj31nrqI3v1v50MHSRMDmcGP2ol(gKRu7J3K6rA43KVOriqWJj0Y9LDS56)S28UlBJfiB8Wo(EsAfEAlLNtR(3Fj)HQ)LYAGq4ns91j1f6oV7uiE5JCC4jwd)D2dDFtJ(VfGi)PWFpFp1EguSkDN0fppbWx4yuWbsYs(8v8nUEl1FfNFSUwJwY0PabnEUFv8NKlYt4xdqcESh2El6L(HMYpQr1ga5j2taYnj9I1)av9Fg)rwaJpPGI6B0XyRi4p8bAwDXiiOtjWKGviIrDXI8MG)Y9(yuCyCAns5pm5dJ55GVbtujEozKsa95A)5(YXwBbMWaASIr40U8yjEQ6)6PYsGTKBREqZ2bA47poG8Hz4pNOrGgvuLHwCQjQyuU7lG0VSE(IflYlZKk24XyG)cMGFNg(4xS2w(IZ18Rysh9G1Z(5WImYRjtNv6SyNfx(934h2iyFW)kY7aX33e8xJnpyT7JJ35X)2h628pWq39w3TXVWfV4uXIQo)I6bAXUnEN6mbotOZ4TZzpWh7))d
```
