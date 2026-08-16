# Priest — All Specs HUD (v9)

One pack for Discipline, Holy and Shadow on TBC Anniversary (2.4.3 client,
WeakAuras internalVersion 45). Copy the whole string at the bottom of this file
(or the contents of `all-specs.txt`) → `/wa` → Import → paste. 44 auras: a
top-level group holding six draggable sub-groups. Spec-specific pieces load
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

**Resources** (`0, 56` — since v9, three **globes** on the geometry shared by all
seven packs). The group's own offset plus the top group's is why the child offsets
read `±300`: the globes land at absolute screen `(-150, -262)`, `(0, -262)` and
`(+150, -262)`, which the build script derives rather than hard-codes.

The **life globe** at `x = -150` is a 72px vessel of D2 red that fills bottom to
top, with your health percentage 18px inside the glass, a white line across it at
40%, and a brass rim over the top. It turns a brighter red below 40% — the Desperate
Prayer line — and fades to 50% alpha out of combat, rim included (a second Unit
Characteristics trigger feeds the `inCombat` condition). The **power globe** at
`x = +150` is its blue twin: mana specifically, marked at 50% where the Shadowfiend
prompt fires. Priest is mana in every spec and every form, so it never needs the
recolouring condition a druid's does.

The **target globe** sits between them at `x = 0`, 44px so it reads as secondary,
showing your target's health in the same red with the percentage 13px inside it. It
disappears entirely when you have no target — no condition and no load gate, just a
Health trigger that produces no state for a unit that does not exist.

Its **rim is the threat read-out**: green, orange at 70% of the tank's threat, red on
aggro, with your threat percentage in 11px text just above the globe. That rim
carries a bare threat trigger, so it exists only while you are on a hostile threat
table and vanishes by itself the moment you are not — and it hides rather than
sitting calmly green when your threat is genuinely zero (see **v7** for why that
guard exists). Since v5 it does not load inside an **arena** at all (there is no
threat table there); it still loads in the open world, in dungeons, in every raid
size and in battlegrounds. A second, brass rim underneath it carries the target's
Health trigger, so the target globe still has glass around it when no threat state
exists.

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
| Threat ring | everywhere **except arena** (open world, party, all raid sizes, battleground) | arena has no threat table, so the ring could only ever be clutter there |
| Fade prompt | same, **and** in combat, **and** knows 586 Fade | its trigger is the threat ring's, so it was already unreachable in an arena — now it does not even load |

`lua5.1 tools/spec-preview.lua priest` lists the un-`spellknown`-gated PvP
elements in its UNGATED section: that tool models spec gates only and does not
know about instance-type gates, so read those as "every spec, but only in arena or
a battleground". The PvE ungated-by-spec set is eight elements since v7 (the seven
orb auras plus Inner Fire) covering the same three subjects the three bars did —
and one of them, the threat ring, is gated by instance type instead.

Shadowform (15473) costs 31 Shadow points and Vampiric Touch (34914) costs 41, so
neither can coexist with a "not Shadowform" gate: the two shared slots at `x=-66`
and `x=-22` are single-occupancy for every possible 61-point build.

The four `not_spellknown` gates require **WeakAuras 5.4.0 or newer**. Older builds
ignore the field, so those elements load for everyone — the pre-v2 behaviour.

Ungated by spec (loaded for every priest, and the whole of the levelling HUD): the
two unit orbs — player health, player mana, threat, target health, target mana and
the two portraits — and Inner Fire. Each is justified for all three specs — mana is
the resource every priest plans around, Inner Fire is maintained by all three
(Shadow applies it before entering form), the health ring is half of the Desperate
Prayer danger state, the target orb is the unit every spec is pointed at, and the
threat ring exists only while you are on a hostile threat table, which includes a
healer who keeps the boss targeted for mouseover healing. Since v5 the threat ring
carries one instance-type exclusion — it does not load in an arena, where no threat
table exists.

## Regenerating

```bash
cd tools/tbc-weakaura-creator/scripts && ./setup.sh   # once per machine
lua5.1 tbc/priest/generate.lua                        # rewrites all-specs.txt
```

The build is fully deterministic: fixed seed `20260815`, no clock or randomness
beyond it, so re-running produces a byte-identical `all-specs.txt`
(sha256 `68bc4f499f38662367dc43919867dbaebcf826c5449a9b3ec55667c1fd4924a0`,
9874 characters, 44 auras). When editing, never remove or reorder existing
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
by id), `missing=0`, `retained=43`, `parentSame=true`.) The script
prints a UID continuity report against the
previous `all-specs.txt` before overwriting it; expect `changed=0`. On an update,
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

## Import string (v9)

```
!WA:2!T33E0TXX1D7vWYwI2orK6HTvIuGzSuKCSuaabiaLKDdErsibcqUaKsuw2elWoe7kUy3L7UGVCFzwNugNe)1W0yv7(8Jj1TjX5fZPojnPpcp94uNMt69WZjoBsoPnvTnhL(hTj6C6J02V2oZSlErccbskklRV(hCjWSZm784393DM79UdygQTC)oVZ5EBlNLl3y8AkQHvKu0oTdho63HRJ7tTTCkYgAkssi(WcIs8Ai5zUA)AIiDdNhZzViojdHLl)9(4K5u3x5VMMtlpYWoxQ7ELPZkwqT1YjgxCuenP2kNu)ktI0iPv5jMwqdXzC5SkA8iTq2Tz1DfssCMz404DMwrrYquvBQKJoQoYGjRkhUjBuUrLouyCTeusYzkvuo9SwvKG20w5F8f0q5fvKtpTkInVMsr1fSYrkXzqBFrr5rv0kWzGZrllADdRXlggghlZv0qqrlPk526TKfpYnQy(w04YrtOtwDdonJwYoQOSOUqlHW)ZOLzn0eZNhPPN4WA2F85czqE6Cf148Se5QUksssKxF)T5kurCHYQkXnnsBwA6X41B5Y6fZIMa3ntvC0rfNAXrchmv6rsLoiB6Y3QFne(wSP6pA84xTOok6u42vkRAidRmxbKEllWJYIRbsNxR3OX7V7bJpFrz7MvllYlQFXIY4EZeipCssQTYr)CAR73Ncp6LUn7HRO85rQTMA8I4rFNDxepCFwbrd0sw31ASENZZjlAny2jC)DVeIthLYapBL3q4oHdgswrgTmpU)tYXiKXenDeEqLxFwswjTsWxOcCIYDdEXfa8bDc(Ha4)V)vMY86iPr7xru2iB4OjshLTDr(QaASiDLIA5q6xfNdKMmN0q4hg(X(yloQgEOb3S4m4CCvo5C4z4UjjrE8ztfMnA0elyOKBcR8VJ(3RNII8l6v5I8Ed4w4it6LvphNeYXc4jcwk2sVe0jMmEuWXcKUKOfMjKKchFllA9yOnx4KZDIS4PlTrMMX6)tXa3T0oxKJ)If1nq89Xn12Q8fr5Tb76HVligCs19WJ05miJFiIGcbnlZlSOoPXJMcFduMQZt3kyOVvEy1L4KnyMfjZhuoVe6P3h8ip2Lv1uYRH01trhQEO36TTn4eWjH7bof07qZJBBJKtItxptwdC)v2yFSfkIffBHLM6HZQlsQQS9ZglAQ0Wq7dgotimco3(GHAjKow8I8b4EBzwnfd6uodSVwy5Kuf4CarFO5Up12mWn7r0f44vM8C2Y3ZttJCrDxhcJqYHFYcu(MdDi1DvvbQiNEzRulbicfCW0jv3nnrSeScbrM7SI8gcHcI)6vP3al6G4Pj(ulBn7mSDdyj69jd)IJonCYfOTE6aCOejtefoOgEIN2(SA(wLUuZFbAA5kX56WQ7mkMZvDxDRjoJZbkYXtWEotNw1v5(6iw0qJuthEeEuoS8K0iQA4pqqJm1mKvQfxtdPuIlttBsmU8SACQZEw7pSC52dLui5GPJhlru7b2AGPQh9A06OqlQym7OskkAwdCtGBOzLqzQ8GimThA5AhMup01OYTsmBIIfYI0MBp0AddW7tuttrtaI4iBb7pURZ5W)X9Saz6FevRM(vTZnBjG3LTtyi7gNTa5ifWuCS0cvkfm9gNNGXJdhCb7PzCXuB1(drklCjuQkTL8uprmcrZOC5qxiipFsz9lCwe3ybjS9xOpeVi3fSZP(fSyrhHsGECJ8CStsWH9Fh(X6N96Bj7kUg92bG7MjRasmVGX2xYUPA3zZAbqfwU6onsWAkf)9qyzxEcxoBO4rtebE2pe0ZjomBobuUX6goW2NDconro8OYSIYHvkKLZGDcoPIiM2vuB)rEeTCcCY5r67)WWLORGywmTbEUYyA4Xpm8RIRbhWhz5AM8Gl1Uxx4s32PGFnsXonPCD1)T764U9yD1b88xD0Y0t0EA56A(cCtvQEAJunTFQhXQEyGNhE8S5Wp(rMMupEDdDqu0SsLfDDTvFOUlm9wqBswkNRGARzltQwAs9Kn)KAyrTCsOrsvqrXqGmRc3hUT1cS)wG3sllqxPaL6LbcI1PaV1N4WWbEoCt6bGheoelvJEwR1vHtQD4T3YSecyYQdYahgEhWrBbEi4DcpClvxoyb19miolodlWrwwcstetBLt3UkGp2kklCm44W76LUn4xuyLJaIYcqRxTKkbBSZSky1G41MO3Y8zlbJGpmDnmvKT0PD5(TlzMfO6A6wut3qyr7YNtsuva(zG3DjjtcvePYu3t44b7R)0jdfpy4ZemsKyPJneMoQYuHnHXvRKILGbba4Yxvx9tUgW3S5ukOsAic4veaoGFDAo9tbEU6Y6Qd4rDaFGpKARvWG2ZJWVdeAXKsdKAA(SQ5NmGMOmzHaiH5P9kstoBSePIfj6Ik41AiBngm7qrzthlCW4wGZPSbN7PfnAPq8cZDc40mWzWA653jeFBqFL1QdjeGKzG(fGbyawQIzi1k0fdPZads1ME2ddNdg2szlCEAspMTAw4ce9RWJBPBfEcgyKRwsbQkzD3h6qahvFjKfYb8acg9PG8mGa(5icxeJPgdKyGc0bmF0bv)(C4aKbfqJbgNr9iRfPnT(RsHamnOdgqrycysCTptg1hSXf1kn4NhEYdb)SmQVRgN7vRxCU9a)ceTcyGnSlg4PWp0zzGFPmWtdVh49c)Y4o3CW7taEg49JN4Hp4vooMqfE2Td)FW58xra(qcW8WhMYnUFlMOTdFe45WCowSGwequ(pcje8BUj5FGFlb43gd2QIJa()wn1WlxreNLURjIi980UpzaMPgP7LjufLVxM6sua)UnbPa8Iysa43d(9Bb(44HJpbd8jZaVKa8POcVWNg(mWNLb(CxzayrQ41TBlE5UdYqthwsG2sxWNNkmfiH3rf9lgnF20WFGa8YWxa(IWxc(dllJaF5QKoy26fo2VTWbKP5ehUYdtLaujsae5GQb2tHb6ZKbEY3cg0c)Cy47ZoCzaewvg8BuxvyBTONeRyE)JcpaEb8K9NFDEYF7WV(vyPZ1dBpxZotGHNkxxHNPNzw756hGmlxA(T6Eq9A5WFwdB0y4agiSqL98iqMOJ2c8SCeP6McCq6x4oFRA2QMOD(VMAOnOQ)rcr3kiDfaea6JUD68cza7oyZvw1vNESzzXYnEDqaMFaoccn0IQ8dHuc7lkpkag4Q2kEt650qgOrQSnQnmUPjWM4jj8SnzwsAN1FA6jQZ0uDjww3eqwtNWRuEw85x3ZIWxZA(d(Zx5O)DcV6v(Y0b6N3AGo(aJEKJOnm60rJqyi(l2mJRputO0yDm0Z3GH(Q0ma)P0H0VATAdGLYCt5eWow5eqpJ7(0YAbgCaPZTPNaAkT2vgGBggOfmOMMKS(Amn0rB5YeTSvsldzKCb1DzzatNPenksfpPdTnCCTKgOLoKvTPMZO8AZuF4vT0NYzQoR7PgDxIL0DP(anOskVuRAwVNF6696IYhfWAnFJxRUonX6SP9kvBnl(7jVxIcrSMrBE4rXai6(ziMfsOXqPjyvX7vA6mEuNqnZS4NJX0f4KZ4XajNzbJjXlcC6rfNaLjR1NZa(Y0eGVDcVkTF6XQhsxUsn0UJJ6RGV0sJh)8H20GXtuzZSLhGWBk2pvM)rTHLNMUX(ojxCJ3pm8QLlelxE8MsGl5OAu8vcutEw0QIP7uVHSjVnGPSX)HTDr17VSnstrnIKtILHC2pNOS69w(wdXvqvutmNZ0kfZjuvzkFJOfYI3WjQkFdqupIKr8otPuuQkFdetwgP5eVFq0LRY8SYOjHwG7IijEpWBcEZ4LTJ)yRqBWU3oPPVxRLMTp6I3QRm6BdCU)2CvIsJWWre8osM6qR5cCdE25gFcfl7IXqvA(HkI3ukrOgV4hYsJOl8cR5UhxgX4d69Ot1dzRiy(ZUDa90c0BleMM5E7liMtr2YyRV1BJ01W7ubFJLZPOiHNjKtnPiE17lv6RetUlSA()x0QV)j84lqxE81LxpD53LNU6Ytip(70pRBx4uPx7GE1lRhFDGtNCnGgUwtklHLzSxy1kg106niBFDpy8nMQJRogcPgKybydwctOqjoVON41woVKYKDRHgViso30wcIHiPjSeMwOhjBZ5kmpjTuw2xN8X4uNhS3fjFUKLnP5PS1XCqVxj7kAzDwsk0NyAbXCJjJ01Dml9Ry2PLZw0WqroPLHjO1vCrCwAL(8Sw8MWC7Msq3(HuV27rOaTvSkgZLILiru2rcLmD6K9bp5bSiehfo484gOL7cw26FJOyB4z7VMRIHTTtPKnvTDZWiimYaCx6BeovhWZoa07eyAwQwkQJKgtgpDxsV95xfL7cvY0oo142AXBnebJIfj)HWD)W3ogt7nCsxNrOZ(Cp2ayguspn0mkkfO8NZwcPMPmn7pqDpLsKS84iI6ellYNHY0oGjZBodrEgV3alzrIagrqdlVzllUIu2)QsHiVvA5wyEWlJMctirv8MwSaHk0D1uHzGNNyh3J7(4Kz3MCncpQJ5E7WvQwef(rzG)H1ww8eSD4Tl3EPx7KE1p8pVwczW)YgCLz)Rvlqb)BwcrWpva(3fG)dhW)5EH)FmW)LfA8)gljyYCBMyqKjZ2mjxV9wnz2(1dKTjZDunE2K5onz2bJjZoP1NjtlzmzUlWTjZDxbvAYCpRns0K5nTJ5YwcbIbjw4p8AtcTyOPoZfJ5AOjh)OESXFMmTsrFMmTvb393yYS7ToqMjZEWaRowbWYKzVBvaQ9Z62NNaD()cIwFGOt(YRceDmmgcPpJqknb(HpA3ncdD5BrWqLwCuOo9hiW)l(Pc(rTnIUrzfJvRF8Y1MkrH4AUt3kGlQgYGNhfBWbMY3edpEJqx)T3aqxUVXHUMbV8ZaH872tapD6Yti3UC1jE9MD5Zn9Qh86n92H7gT48nj470BEWN(gg8HZXt(awyVRxq57T5HYnJ1yQGrFpyiAN(p)qSJD0bYIc0ii6F3waeD)BvQi)6EC3rxH60LFVKl(ix6KCXp5sack0JF6vRp3fzhqU9HV6XJB6vpnq7678)Vu76bSHvMmhSjjaPlrBYb7j2PhSNHkmOVgHU(7Vbqa6zZqa6kuE8gKBFW(HT9mQVLvyMeI9UC2xSuPILONvFtrKmVZ(1ukOAOUNY3SBoEuPuDwo1iiSEgIVkWjrI6Vs5OsGtgoSZKjC2xu19xPQIgK15zdYgPCB4(QeJMbtLYzKyKab0zIKNTQgqQyXJMiCusQuJTqKT(QuzllZRWQRYLdDpBw7RSiEhRfliNIuzoO26mR12Ez5KeZldNut3GJerHuBk3BlvzrknRigeLHAfOioMfpdyxpVzbQDBADj(PL5kiMJg8MWU3EiDfndW3851eTcGR7AwYhj7TVD2iSsIfenUlIXgJt(KWLX7Nf)4Ln6MlNHIww2GrInyQSAC8If1F67g8SZ550YzzNHNEFLqRvIp1Gsind9fgTOKKLFEYuYQpxGHyFhIBs2Wgwcld0tle4hEzes9NspDuDzV5N7bHRW0yIWe1UxbV(7yz8WyobKEkbLjtkVSo9F9jQtIsVMYiz1sF9qvOViSuW)oMFyBS9lofsQcng11V(SUsj0(PzW0CwmAwCznd5Z7T0s7T4yOuqlqJ(qA0iLzvlZVI1kOerMmjjrYkjgAJHNSvFhv8Ch576xGUUo7yMZ(FeXzIThdTOEqxDDUb1pZrK7z1SxcLWdMmDUM0x4(ywseNGmGaAKaznzrd8eTjZ5xuxsKhLvXWqPWSLc8vp4QMcaQdl3C7AEAWLsnuLUHghjGVOMdd)mYvuhxpzPzyAQFdHaMmpMvctrtWK5XBZn84m0G3KMEM2MMFNTnfZ804UKuVZwQEjp9LXFwwxIeGJ4BP2AP7LUuY4Mgn6ckNVm06MwBzSiHBXM)8AJAjQV)HL0PQU3AIPdfkPOIwBNAPQtVDFUk5NlAelvtGGKPHU(AUwzXT6CJfIeeOQTskCEKmstmNLmsMLR5RlAjYWI44NMgSfuytcUcOD8EFk4GS0VAh0v3FyBJC5Suyp58i0qV(Ow7XaZ6POHib)eMzcLzzmSqkvPQBXQuASCzR1rUd1LsK2VvVzE7b(CJLrD3KpJiH4D1zF9j(AYmyzz3kX4th(CC9v21KzOvlZIhcxHmRjZzvpsZiQsgNSKvhoGuGaU7IB4Pk0qzv)nswflxsLBSernzUawOXK5jwBrstMrmzYqkiNjt2kcEMm5QrOZKHVK0MjdYKzusDzYK3KrG(SeXdexCdjZ8kLKzwUIlivZHzg)Muhtc)LzGVF7(DHrpQTvXJCLKOiECAbaQYVKuHdtgztgftgvCZACtgAagzYO)XEqsp1WcOBYu0KzcCgMmezXmMmtVciQjZm47(KBgKivlIxF2(bBJceFo4Bvx)kwn8KamXyrCpK6Nr41YaF7mGzg47Kb(UzGVh1vI1Gppw9XNf4YlMBejSypIeGGeRZlkzmTfinmF3xm25MkO3(D3qqAGBvbPWl0UxxLJlem8eJyiOLpwgls4AIv4mQ7R2a)UIEGMaSUJotxx0Q6Uw5QS3sGUwErMUq2BauO4(ADOqpC9HOckstpcwXeEK0kQeOyZu9LiOVcZKpLeFdXMD9ggSzty0aYALNGcoRAjWeCWcQ7kmE)g8odx(vIJaxBMT03aQSgVG4RxBU)bAYn3pSvWxSgSJv2v)HXuHSK3SoUQOaTank5c2RR(NmzW0t1qqZjkdAg(MuqZluj8jSFliPVZzxkuQ0dMOAtdSYzYN)QvCIyTVTcMmVF4sltk)i9fnCVbtelCdRitMpyTLnezR91ues3ZVf1s9kWYKcu)h21OKAHtMO7btfDvLXBLy)P(Tr2KjtVQsrJ5x)1)jzB5HvpueG(u8u3ow)bdhR7H3ifvDxPc3BYKXhjg5vbKDW(tFnk(6sZ2lw2HkD4fVnWuMmPVgw2ETvyDFF96QWA(UrCAoplNg)wMIkVwH21gur1WwkQW8ixtVWH7ILyumzEFRyfvpyduxHMkNIworD7DM7xTZ(hQFprJD(l2qENtEtpVZ6BHuL9WsNEjowXJlwV(82rawp(70DxKe8eYNVU6If)j)bUgwWETbI)8twxG4I9XH3mBerY0Ygbk2C6illlUvQI8anVkYMfAJh0wBO9Ay3joTCCYi8Eg015PdRwO7oChYvXHhVVEJ2Fdr3N6wq0TTpvcfMt3Oea2Ahc1aEFLQqOlhK(s37CqAafrWGyWQwkrjKCUY7lT0c7iavcAwFhN6xytavBcBKCtmwf31xBS6d1qdViwqvvGthPlioQHnzmx04tLNdf1VrdHRpYByGRUmz8TqVjzJD(KjshmoSTxOCWSgocXTkIY8odjHHOQhO60RoSzJG4mekh3SvDBQrRQTC2E7rzuN9HVNOC(AlNDyYQKROEz)(yvo6zMrm5rlsI4B13An3Jtu2zQIQ0x4rYD3B13noXsUtINxRn5Yl1OSpHE4BVkNczY8O7CZ6ritMFgh2b9UjtqYLqR23pMmHfSD7JjtKko8XKjkS7TBY0nGZsp3LjtVTZgXKjg(tNgd7pJjtCtM(OUUXKjrfF2u1X)qjZZQBY0)k9xdZ1f314vKBWr56jsHU6Lq81moUEf6IxGyV5GstYnTEjDYVTFJ6QtEHkqXgQsEt6X6nInJfwVRJmytgkxRYhpFEIlHSpmyYyXjXMNps0OtiyKBWg44ztMpbMtsGYjf86MNNpD5nGSGICj42kcz)mWZdVsvBu5lTchq30oOETZIaTkQOa(AHdLR3Ac)dkVMWNS(wtRTQ48oHfP36biED9feBDay)X3(PUrdsnz(c2Gt)rsi4zqx5go9yneC(j3caNNVwq3Mcu(cWLA3x1NMdcvLH78AJAVZRdO26WEEzlV1vwYZgbt8uxDqWMmtDdI5CDgRpx3GIRY)Avbfho04dhi9r9PmaxdHIV0wauCDe)xBmGqv0xpL36tF16Qw61RRQrx9oG3ieup3A5TRdKXk(TQ2VxVjYyZAIp0fIE2iXrDBC0aneF8P2s1JU5PQUbO)SUaWVsjayx)213MkvT2(BXPHWJaRTgX8d3VF3HsYPW3qy2N(nM0qLrbVJ41ffC5A3i3T4ab8GWAcegNJ7ih1N8a(6E4gce(mVbhi8uV8A4C6vUT9BXXcp1lV2yHPuv7Yyqn9bKNPHyHp7BSXcrow9D7tzt0CRnea39xteqeptyO3LrpzpDVneb85EdoBWA45ptMlDlU4VT)aR7KF2y925qsUuosHinCYFXxFN8j2kMLnwp9Mg22(R6SnOxfPPjHaAo9Y2s19wLPudfpA3PBO1uZC90AQvoTdO9V6yi1V)1fdPkFXZfieFIKrqD3SbZZlsnDAyjfzKEgRbZhITJoC7ZnBhE97Z7giC3VjYTL3Ft6kOGBSxBhtMVHTvbME4ZYAmSQRZFUgk691l7rNvk6r9phNLhDiZSe)WGwGgA49xushz59gQJBCtaO5S)pFgQtzECpuy7fZupr2QQBRCgax9TnntBt9twxE4H(68CXYoa5yotRjkpgYWzKKNnHA7vo9seLKigiWqaH3OMMo5SmXkpvoHtIkJkmDPkOkwGbd6urMCeKpDvUGOVPPVhpfRoJwva5mvVUVooy6I756gDHjZ7(ghzXsvilMO)6qvWF95DKPRbkMvpq3tfwFOMHR4lEhBJCEznRObQano(J9PjJDevZWcQ3xDIH)y4CE0kHSQLc8LOr0VDDG5Bcr(Cfly)YMmF)De7JwPMnz(RwzvyY8xt9I5pyffBIp4gRypZgQyF4RSXk2pADvm4yE4KNELCSz2QxksthLJ14m8VNfx40X5ZfQ3ZOoqiud5c)wBbldzDgjRR9cmp47U(B3Cp1JBBDhBpB5tGnBCnG7MnAQmV60E75iZCKKtC0gov(AV(pvsIy(f0S)rFy)SE94PlpwIApUh3ECroCNPV0qojXjJZufZLdroQMHha3VxS8loum(m1l(zEDz)anLq4(Q70wNtwWFqwpdYhQHtBF7BcM2mz(MzkFW)4YTRa4RED5LE13IQinYXdi5OIEwUrhfLZGmLbTDzYRZOOmQFR7NzTovoEdqWN3Slrn2MbrCUr7WyG8hj)yOjByehzwE9PXE9cr8AvqeptOaU94HCXl58xlqa6PWMlY7OBa)E60LpYPrGB6PKHBpMm)JMm)t0ZHa8iGjZpEtakUj)qgytbfoDxEInP7Xs5A8enek8D2cHcUwqxLtBm6BC(EPWcYHiQ1b4h9oLpq8vBTMVtpZ8ZHBpcvy9R68Bf3Fv3dHmNC44jQHOEjin9y8EnF5wlHgOhOGv9JnIDixnBwoTkhs(wN4LwhVN4TU(kclrBEwhyEdJ3BWj2hCWfjhP)4Inc(V52N15J9xz9Im(JQ(yFFrRZ)olJMmtg4pMC4Utjo(tyMGIwkD83z9ZzHh8tUb4NdSEWpxM2dl)dFHNGrIqoYSjakRzXkNEGeHBY5ETM9aagZu94Z5yMNogRlsE7hF1n(UyQIZyrA93l9hZJhb(ASHLqCYyuR1ZT0p9ev9QXsu)lkNpeN2fgm2XQ8TJLIIZOfRkPGVlw4GHEUC)tOq4qlkfjwCXPlwW1OAybc7NVippsMnr0HIYcFrtMpo0ZZu5ek(SWLyJWoySiR(9OWR1pIcEjVifB72QPiz7Dq6pft18MIqoSRT(TzOdR30Z6uWq9fSNORQyEDBDwTsqU17XP1FW4bJelXQkyxDw1pHbDuNscdxB)YHJ61Bs1BW(cwBTZqBx03xMa(Rxt6SbzJNm8zwvtYhTB4ZnTj11kkPjJeCP29Cn)ntbxgcB0NJiGqF5BARqB8TXp3bR9mEfof8dPX57N3K5BqirTpOvjhYQFJDCZ9HSk8Mw95QAX0E0ci2dp)KJvNZv120z744(oUR2M42)5(F(
```
