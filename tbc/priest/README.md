# Priest — All Specs HUD (v10)

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

## v10 — the globes flank you, and the glass catches light

**Two changes, both about where your eye goes: the vessels move up beside your
character instead of sitting in a band under the HUD, and every one of them gains a
specular highlight so it reads as curved glass rather than a flat coloured disc.**

```
        ( target )
          44px
        x=0, y=110

 ( LIFE )                    ( POWER )
  72px red                   72px blue
 x=-190, y=40               x=+190, y=40
```

### They moved beside you

v9 parked all three globes on one band at screen `y = -262`, directly below the
cooldown row. That reads as a second bar bolted under the HUD — a separate widget you
have to look *down* at, away from your character and away from the prompts. They now
**flank the character**: life on your left at `(-270, 40)`, power on your right at
`(+270, 40)`, and your target's globe above and between them at `(0, 110)`.

These are absolute screen coordinates and they are **identical in all seven class
packs**, scanned against every element in every pack rather than eyeballed here. The
`x` is not a taste call: `±170` runs into the Alerts column (`x = -150`) and the PvP
column (`x = +150`), `±210` runs into the PvP-layer elements at `(200, -44)`, so
`±270` is the tightest arrangement that clears both. Sizes did not change (72px life
and power, 44px target, each rim its globe + 4).

Because the target globe rises to its own height, the build script now derives **two**
local offsets from two absolute numbers instead of one — the vessels no longer share
a band, so they can no longer share a `y`.

**This retires the v9 buff-row overlap.** The target globe used to sit at screen
centre `y = -262` and cross the Vampiric Touch / Renew and Vampiric Embrace icons at
`y = -156`. At `y = 110` it is clear of the buff row entirely.

### The glass catches light

Every vessel gains exactly one new sub-region: a soft white disc at 28% opacity,
0.46 × 0.34 of the globe, offset up and to the left (`-0.17`, `+0.21` of the globe).

That off-centre bright spot is the whole difference between a filled shape and liquid
in a container. A flat disc of colour reads as a sticker no matter how good the fill
is; a curved surface catching a light source is what your eye has been trained on
since the first Diablo health orb.

**It is drawn in `ADD` blend mode, and that is mechanical rather than decorative.**
Sub-regions draw in the order they are listed and the percentage has lived *inside*
the glass since v9, so this overlay is painted over the number. A `BLEND` overlay at
28% white would wash grey across the text; `ADD` can only brighten, so the number
stays readable. That constraint is also why this is a highlight and not the more
obvious dark edge vignette — a vignette has to darken, so it has to be `BLEND`, so it
would have had to be *inserted before* the text instead of appended after it.

The highlight is **appended last** on every globe (life `[3]`, power `[3]`, target
`[2]`), never inserted. Conditions address sub-regions positionally as `sub.N`, so
inserting ahead of a referenced index silently retargets it. Decoding the shipped
string and re-checking all 21 `sub.N` references in the pack confirms every one still
points at the same kind of sub-region it did in v9.

### After updating

**Nothing to delete, and nothing to re-check.** All 43 child UIDs and the group UID
are exactly v9's, in exactly the same order: no aura added, removed, renamed or
reordered, and no `uid()` call moved. Decoding v9 and v10 and comparing every aura
field by field gives **seven changed auras and 36 byte-identical ones** — the seven
are the three globes and the four rims, and the only fields that differ on them are
`xOffset`, `yOffset` and (on the three globes) one appended sub-region. Every
trigger, load gate, condition, colour, spell id and region type in the pack is
untouched.

### What changed in behaviour, honestly

- **Two prompt columns can now reach the globes.** The Alerts column is bottom-
  anchored at `(-150, -44)` and grows upward in 40–44px icons, so its icons span
  `x = -172…-128`; the life globe's rim spans `x = -228…-152`. They overlap by about
  20px horizontally, and vertically from the *second* stacked prompt upward (the
  first sits below `y = 0`). The same is true of the PvP column against the power
  globe on the right. In practice that is a lower corner of the glass behind an icon
  during a multi-prompt moment, and the icons draw over it — but it is a real
  overlap, and the fix belongs in a layout pass across all seven packs rather than a
  priest-only nudge.
- **The highlight is on top of the number.** `ADD` guarantees it can only make the
  text brighter, never dimmer, but at full health the top-left of the percentage sits
  under the brightest part of the glass.
- **Everything else reads exactly as it did in v9** — same waterlines, same
  breakpoint marks, same threat rim, same out-of-combat fade.

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
seven packs; since v10 they flank the character). The group's own offset plus the top
group's is why the child offsets read `124` and `194`: the globes land at absolute
screen `(-270, 40)`, `(+270, 40)` and `(0, 110)`, which the build script derives from
the absolute numbers rather than hard-codes. Each globe carries a **specular
highlight** as its last sub-region — a 28% white disc in `ADD` blend, 0.46 × 0.34 of
the globe, offset up and left — which is what makes the fill read as liquid behind
curved glass instead of a flat coloured shape.

The **life globe** at `x = -270` is a 72px vessel of D2 red that fills bottom to
top, with your health percentage 18px inside the glass, a white line across it at
40%, and a brass rim over the top. It turns a brighter red below 40% — the Desperate
Prayer line — and fades to 50% alpha out of combat, rim included (a second Unit
Characteristics trigger feeds the `inCombat` condition). The **power globe** at
`x = +270` is its blue twin: mana specifically, marked at 50% where the Shadowfiend
prompt fires. Priest is mana in every spec and every form, so it never needs the
recolouring condition a druid's does.

The **target globe** sits above and between them at `(0, 110)`, 44px so it reads as
secondary, showing your target's health in the same red with the percentage 13px
inside it. It disappears entirely when you have no target — no condition and no load
gate, just a Health trigger that produces no state for a unit that does not exist.

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
by id), `missing=0`, `retained=43`, `parentSame=true`. v10 moves the globe cluster
and appends one sub-region to each of the three vessels, and touches no aura list at
all: `changed=0`, `stable=43`, `missing=0`, `retained=43`, `parentSame=true`, with
the 43 uids in the same order they have been in since v8.) The script
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

## Import string (v10)

```
!WA:2!T33E0TT199hyAN4W40ij)ijUjomQXU2PXUKuKIu2oPHVKeTPiPaPKTCCIiibibSabGba1R0hlAPDEzPPTkRP1nTRDYT53wB6l1EYA7w3w1VZA7YAp970FKI(yDBEDTPB9CwRpN9OT719Eb4ljkAkjR8WRNJneWf4EX9XNVF(EVF)(fxsnCh5(iVHZDhlMLj3ySQYkHKfLvpMnB2sAZ5H8Q0rozjDvzrro2q8cISQCstFPKQcCA6ooOJ(5ye15xSY1dWiXOSRkxMMrTaNU1tPS9LMoTqrL2RKymH8CKK6OssjLNGtfNw13yAEvog9lMvwLLtnOvDwPTGIctpnJkRJ0YYI6ckQtMiFEnoDQSkmOQSELkv6GHqLsarrhPu4YPL1SG4vNY85p7CQCfeKLspLchDbv5skZz(ePeMMBlZliLxwTiJo6jSpV5nm7VOOOSTitjDEz1ek4BRzplQNlVqb7Qm5ij0nTMoJQU9S5fKe04The9hD7ZORkuOaNQw89PAD6tfuh)2zkPY4Eb8rnforrbwTD3HZGLqzkRIiZuCQZqspkRM9lQvkl34OMzQs5Zlm58JgkqQ0JMkDa60vUvsvo0TOtLmsSyxQKgxKjr1RuMLqgAjMICA2NJLllQeWnE1(JelzVdfB2sswvl7ZZkODMssOwZ4CUzefvANHCEAZ7pGml3ZEnwDxrylWP0EQZwc177O3sOU7tWlOZTG5Dn7RV(zzKem7m7gU1ExGJrJlLoA0QGo)1b7jOKSe3ISO2p(jgf3NOQXH6uz1Mb)O4Aj4nyrgbPEbpOmaEHUbFGF0F39stzwnoX8jLfK0Zgks80rO7uGTgGgnNMCj1CCAxc9eCQsmIdJEzOx7dmFEvuxdQAXOZy7sms5qJW9Itc)6ZMkeDKiXNtxo34Mp)wtUt3LeyN3J8zy943f)(NWdTwogroBZHgiOjylTYqNOsOEbBZHBscMyMGIYmS2N381qQUWro3HZIgUuhDkkZ)ojfSTFABZZWEMsA6CSdWm5MQEHG0MG2(fqu4ik7GLtJrh39XHLtWGzjw(51W1DUjr3GltTptVYiKV5ZqRjYiPtndNeBaPcICp6UG79bUOIQCbvonTuKEQ7(2UMnbhgocCJWrH(hEwuvB0CImAAzYQJAUs67IUyjKKODAsQ7lRMaUOYMKoAKuPHH3fmsMGiaCUDbdBpOgs6cFcCZ2NrvwNmItb7YonJOcpJniYHp3TO0HoQApQgpdR8eN0s8EwsA4dkTTxeajh6nZtOB27EvARMmuvm9IMPwgpemWqPtOSDsIibyzmGm3jey15dgaD5Li3aj5WXss8rw0CWzeRkWcK7J79fYpfCK5i1EshCW4jIhb2JkACNu)mR(M5UC1FosA5kt5AZS5Khr5Q0wVQct7yWsmSyONJ0PvCwPToQjl0O11GhLLlhsCsCufv0jyWivDDzLRX1vrkN4IK0MablpHkJYmNW6KfRuFiCcjgkDSOXJy1Xwhkv5axMAhbArKIPZlklRA2XnoQIMvKlt1xeMODVlwF3KYEVmfUzIzJxQywo1ZTdsPHa4diOQkRYdHTLTO1PTDsB(oK75Wd)JQyw1VK1ttxg4DrReg2QYzjpoAredhnjtLtbXUX4oqSyWEMZAygLnL2TojCfHl(YfPLKNYHJI5zYZKJ70byztiPD6tWXmwamz)PhGJvG50wpP2PnjrhLWFEi9cm0tGXHjVwFi1ZE8UGvbxNAB)W2OYYZjuGxFllyvvTASznbO8lwBJMJ3CifDDqKSllMkNoySiXdFUTdVnEyBNClUCFi3EGFduhyYT4Y7HC5gEeKW)muWVzg4rH3oIR9CWVnp8ykhP1BzHeuZjYnAQIYY684Mg849F)3)7607)FDH3n8ojnMn78qU9Jg)G3f6T9ej3IBphYJF4DZdVhEyw3bchgEI3d03H3hDoEUCJ1lC7BzMXzufyqdBZiifsUywgD6XzelXr1PSsN379QMJNrQaN2U3hCEYmCMbXRHat6tbp4(GNcvc2G33I1HUGZ3PhNOC3XrHpaoBhdNVEWvnxUnpAdE6lLVc)jzOOsznBrMjlxoDGlMop69AwouWtdpy2COx)OtHlhpUGUWkcxQYSEU8Q3uAdX)gWsjarNaVs7zRW6B1Jd)UWTGEb2HDBhET2NJmDecbpfeaP4cUThAFWT)uOY9oH7c2lnzAdznN8gkPoHxN9zW084PGKb2h86HdyhUB4na3J9AZhCbLDme6rCeINbp3hovbe5yonRIa(yljVWbHdbVXN9AqGRL2meK4H2Vuzfpwi0zKr6ArtasZ(SzldwHNKmrPQsWAemvsRCMzoIgTEfu105N3k)5efu4H3eC)LL)XeE4ctzhHIfyGKPtemwGqhhHXIMo6WisVQ9Nw0sxQAkMIF4rrNER5Op8r)ENjNCrfCfHhnTdWg8HipPpc6XzpMhTb3Nn4XFpkTxfivDyl48jehm1uSzvkmHFvbj8Sn44NL0QWv5SrJNkA4iZlJMqJKzFWmdhHoD0qbIzIWM0cHTd7QKCXXYFUddhJcooA6e)W2GyBcgO8uhG48qImqsEyqkGMO9hsTef(q6mWqev2NyFWjHrm1OdNIK0dyPlhonwjo8GMkWHhIcg9sL1sRGNB)E3lWqukdzHCalWb5FeOafWJEpcWzqqQXarkOiP)YlPp1NxB2ajqguPGZsPS)vsZaP8RrRdmfOb6qjyCycuPpDgL7Q5z1mn4Tcp8EH3mLYBS5p9Yv(EUDGPoruxystQLqx(oGFRkuMWVdAChENV4HqS2WtSfcvNfdh8KRAcyeAz1XIcVxch6UnzS2c8(G3pIBYKT0KOIWtIjRGp86KNc(i8WVF90qWC1Y(8CvzrOjR(dZAmlPlgpisvhbYIy2Ok3ltd5IGNPf4DG)FiEg4pa(dTdFC4jHpbf8SzGpjp8Pi8dWNg(mWNLcM)ftbFoIe8MTKGD1fURPltHClby4ZtKx9h3tEbFcrkKnn8C8WFe8fGVi8LG)4kIHWFsncGuLL)URTTrjaE3wcGqMwtK7fVhIuMcwkdlRvRWZKiHPPZap8RfjyaVf4TwgKUzFyCfbJU5EWW1Mbr9CVkx4BB)(wbiQlphQNURfIosfiksPk871qLPBS4Z4lbz9rH7eTwhSLmUcdV2c8HEX0e00iwOj6P9pYK56j009n9kJMUtmoQmcQ2wqJQ5WFrtR0iahcQnx1LhYJHsrSdpbdEqPLGF42fQX3UQL(vsJ)RReCnobXrdsw0mzEIyrG7BlKXfCh21sNRI(3UDBPRajz6Xgg6)4myzGGZRWomNCiVry58JenuANvqlNkNo3OvxX5Ag30cyt0GeA0gpk9tBRSI26gLEOgmk1qMRvndN5Oj81QmiE(v9Gi81nh(G)YL25FDWZ)IFfs)85n7NJny(9VF1r4owKWykOVX6PB9UBbTsRIE(F4k3ZxJMh4Rq6rxOETnW))mVIS)FRlT)VVZ66ysQ(hAqXtUU7)BPzfuT)Tv4FMtNycx8seqKqhW(fXAXRMwgCp5fuAZ0qVosjOxIiCs6ABA)6UT0WTWEnlnLC6vMFPY9SSPVv5HAWC3Qt3OqzDJk3ztkKktxSU5S6JmN1EiSr(nN36zRxxQQqdSUr1ITUjW(W3mwHlsZRflCEeaISKmS9Z4BouACAf0Y9MkJBLXvYmd69OpvrgPmU15KYmN(eOjYovEHX5YK188mG3mTa476HNN0oDB2cjthQos3ZYnqrVPfpBStfCDdgpC1fvxPdcT4CFer(7ZcwEmIfq6gFWfAD5WZxjt0mfqRRcoVTArXV4HR7zM3SGjwmOPKj3bqvXjjWMoJYTwXwYPiwBZb2eAosYiiPCZvU1WmfveufY5iTCPC81KNk3isXSO1mZvJpuWkh5K4yDKsUKyn(qjQKeNQd0sA5UynMXwIBcWoCdyjXBeEnWnHMkg602HoGTVfCvFNMt9BxKjh2qz07aCS7oCwMsdZWHf82FMgqR5eCbUV(1(aks2fHHQw9dwcTUASqnAQp4jgrM2fsVDFo1JYgWZbMSp8eer8N9Ad6Zo0VDmtZ5EDZjKtwY0Q0321GBAOvBHUXI5KLfrJesPMqaT6GfkFj21e8lN))zmB7FC3E93JBV94XDp(C6UNECh0TVU9r7YjkvYXUih9q72BxO0Xh9RIk1esIizgRPvTKEn1(dqpqVdfBTP64sJXXPeaBQCDAmtiFzoVih(fwSGO8e9QYD2sCs5MYuqmion(fq0c9jAz3B(zXPLY0pe4tJrCYYoNhFEztatEMkMr0g5ELnaRPzSXPqEJP5fYnMeNMMTzixIyNwmBjDDzPeM2wHuwXeqps7K3N5u34rRtatq35EvU8RbPiPwSmgZfIgpEe6rdMiD6edap8TBsiMh2ZSOkOPBvw08pJkBzHERlZv1dawPu24ZwUJzuoeYaCv(kmNQn4jge6FCenlrlfXHBJjHgUlR3(ulJYDUQp0wp6zT0I3Eqmgfjs(JHTDpBgHP9ekHZJZ39aUgBqedkULgCAz5Ie(ZzkJuZuHM9VxzhLtep54WcAylCYMHW0oObvBzWYZOvgyklIfWWcAi5nlzXLKYUxwky5TYZ2cXdErUjresefVPfkIPcDvlvyg4PXg8(qUoeE0TfNJW9z7CVo4NuRik8pLb(NxzzXdt3LNEC5HCSBYrFW)2kjKb)7RXzM9FuRaf8lmfIGFjp8R4H)tBW)1oH)Bk4)HmgzqDnirbdkkdQnHUa9VnBqTL2nOU2ReqBdQRRwaTb1wnOUE0RYoP8mOUHmguBdCzqDJvHLguVMvgkAqDtB9CzldbrOetaiAYjbNp4Kh)mrDo8eN9aUTaGguDqGFguBVkW7Igu7yJdLzqTteYQRLGSmO21gfIA30U862F3)Au0QefDKNBzOOdIarCAtZNsLNDKd0BZar)dxLaIkp9OGD7ZV)FnaQgaKshy1JsY6lxf5fRpvSoXvCXUvrxeLKbofx0HgCsVJpYzBg86h(sa8Y1lDWRPrZa1FqFUC73D3oDh0LtNDJMYzpEDro6gnLtpD5QzZpFDI(o2va0N2Ag9HEIh(onbFxPWY3CRJLBflYufK(2ry0U9DQHPh7adMLZFZWO)JBay0DVrPL85D7QREc2TtFEWh8Ip0n(Gp8b)yyOBFKJMN3dEvqU8Io62TlYr3nrb7B4)BQGDpw4kdQ7OfPajttBIH6l6XgQVHloK3MbV(rVeqb6E9qb6myb0QK7COKWMEmLx7sSvc2OxogiAQurJ33YVPaNeRJKQYfv0v2rLB2ldlx5uDuj1WCinny3vGschIKLFIQrzAOqose3Xaru2D1IksaAhNiaD4k1HBPAaTgivkhHJIJAshXtCIAQaPIgls8qrWPsS4cw46RqeUmTXcTMctoUBC9AKL5rlBTurPu4cZgXGNznx7lnJOqbj4iQA6m4WVKyy5(TxJzPundVsUmetbf22mOraRY5M4jgVP9fyNsIPOqosKUcBFlb1Kv1bVZwqvWmC3UHzWNIxGFN0HPffkkOFdylogdFg)frlQf96L07LjNUSAw6aHJouQSQmScL0E0TbUV(zzuZzASHhDxLrRvdM3aICQ6AZLVKOOPREYu20pNMcBKNTjUoSUesgOp7y4hAIeIjtPLoIMKNcN7UGFcvZzcJx)6f84RRfrDJ5450sXlprcPf1i)zabnCmn2swkRE(R7Uk)fMLc(vi(bB0jfMKtSkpgX)YEnpAYO9lZGi6mP0mjZAf2N3r5P3BsYq4GMJeSMKyJkZYMQFvBwqyImOsIJ7xCehhfnAR86R69o81ANMm1oRqm06py5zSfidoVwaN9CYH0o((L6B50x8Lbegu(wr(luBmlo0z40b)Q4W(nrjD0iTb1dmVMOalxwzDD5IZuomHDJkAccOb0CNRTzjHIlXCvA6Qm44JJyum07ixjnu5KL8atr8Di43G60MjmjjbdQhQdxWdsrI1vs6z6yk2RVJjPMLeMQ4YDMYLl(TVi6CjnrC8GIULs7LVx6YjJQAKyyOYZLHu2KslJjlSDlc0lpSfRa)hvwRQYoRl6uKjSIYQDC0fQn9o96SS3UiHEvDH0sMM6aSZ1onQwNBSG4yMvPDCMlWjXPkKZuijZI1D58MYm0CmStrcPdcSjotrUT(oEeyp0KlTIESBnKLPUCuo(TCSFsGQFaZLzGO9Kv5WrXfIAIlZIiyHyQYf381O1yXk2SdFhIJLW1FZwZSwD85glJY2XNZHdi(AF8vN8Rb1WveERgTsD512vyHxdQtSCHwuF4seAnOoPY(BfzvChLPW6i(f973vpmJmzXMkS6VzcRibtIGJPmQb1dIKAmOgDLLjnOqTagCgZAqLRQKNbfBDsDguve3mOYBqvaxwgu8gucK31zqfZyRjHMVAzHMfR6jsLCiQXVfX)KaKb(bD6Zjc(O0rvhZvwKc74Pla)114EsI0HbLSbLIb1zrvlvdks0pAqP)rVlClTKjs3GACdQjqpWKbXtNXGA6LGrnOEy0DFZRhOirpIhVMUdBTJeFk4fAO)fRfFIrMiWiQjs83i8TZagzGVtg47Mb(EzGVpXLI1bqpyJbOfzkiKBurKGphowhXwPxquFktuAi2Ept0tozapjD1uuApxTIsHpyNECwj8qq4teKbdx(yzmPHRl2LZOSR6Ju(QAcAb06w7oDdHRkTT0jAVHGDn9MmzUSVuqIIASnGeDFngJYllo1OiDtOUsZWtGaotnq8aEloDHuISnfCE4x1aoBblhGNV84e0zntdgdeUGsBHqR5G1rOkFdHy8ARSU(MqMDzMu8vQv4FNT4k8hXmmmwb(XQlTFFiYqA83IitnKGMOg5Cb63zYjsei9Knf1CKkOMrEfkQ5dunqkS(UrjFLENpyQ0dfVw7dSKHs4PVuv3jw)3pHb1JdNFrC(hDGiH6pq8OHAAbzq9e1N3G413xxwWnpFMKlnkdlIZqJFzxMCQgkr8EhkvKLLhpvJcOgxhPtKi9YYfj6I9143KL5hwExHFYBXDdByjdekAVJSwYQsBPc1FIeXgnk(JNKEOKPVmzFvPB7zQ4yLU80TbvAdQHUmg4ELvzDlpFdvznBVCmQoobJk7gMQkpMb51Avv1iMQQqejxw3XHAJLPumOESLmPQ7QjkS4MmNSAobnRLN7tP7KdN0DKON6mnL45OVIN4z1nxQkEAPBpyhS42jThVE6YpTBFD7QhCcUd61Bp9qJoZN)lJHSxzK4BDIgIeNFag0kAdlGhwwlyXwtlzzHXnwLK3ERRKSvX2OETvgBVcwFIrnhJehADdAASK(vt4DxUc6S0iNDG(JKSPW779Qq4TLVvcgIrtVmc2Cvc1HE)Q1arxmazJkWXqKGlcdcrOv1ucICs5QS40YZTdJuXWz9TE0326aR2kwk5vWGvuBFLbR3Dtn)IqrffEgnonEH86w0XmrInzbgUi(0BkE9(EvdE1Pbv3Z1Fc6ONkr80bIbB6dujYwdfg7EfbjwhbfryuLBV20RngAdZXOZxjiAR52etxvF(S86JCEhdGUNGuH6ZNvmZkNRKwf))yMpYgnsuP8LWH)TYTv39yeKCKQKc5d4eF3Dw7DJHnO7eOX16tUYSnQ4BO7zZ14CidQ301VE9mKb19BZkc4nOcIpeA5(aYGkmVL7FmOIu1Xpgu9cBFlgu9bOhP)BWGkAN0HnOog6SJJgrJzqnGbvCIlCmOsu13n1SNzu2kTAgudUu)2qDfXTnEeygkptFHl2t)yMVwXd2lrB8CyZohqCcMPQOv(o(GnuR8CvHInvP86011RjthZVANkzGwmSUwMVE(8yxdzTf6KXKuIUaB4irgNxp3qnXd0guFcePepHukWvmxqFSklczozPY4TLea)zGNg(A1SyLV0s8eDl7P6v(r4jfrvvWxoGOuJMw4ZvzAHpCJTPwh1q6DytwVvds8k6xl2QaX(Z2CWxYrPguFbl0PVWX5DpKZCJKESMIoF2na05PQh1TUqLFq48D6T2nzc(AEGR7YdBVURaW2gWFErt32vr0ZccJDzxdGWgut9se35QnSFUIHfxMJ2QblosWZoI)0hWR8Gmnfl(j3aWIRIybBTHeQHa7r80ycS2x2SVEzvtAdwg8AHI6Pwj3ETNmMXYvToa7MWDoRiarJpYjchJRx9d4VPaKp1gQQ01pz1lbQqBic8lxgb2ZhUXwwPM53F1oreQlyLvkwyKK(CfmbJmBtXzF6xDsevbg86J1qyWfRF1CxTJeq9cRis4Smm7)aELg0BVJ0uKWN5v5iHh55wb)uV0fVF1oy4rEUvgmmPIsp6dPQnO00nfm8zF1nyi8bBSdGQyPMRYXaO2)kcbc7ECDTE07l7X6VPqG5FvoFWk4eqdQ3)v7eawUgSHJ(zJ2F3dl6uE)fd30r)p3lVJ(yJgtthTV(tdBA31SJh0VS4u4qcnNwfJQ6AJYMQbJfP30n1SQzUsAw1Q7bcK2xdSO6FZvelQkDMt6piB8eH56TvJSNNHyd1qIYsCAzm7mVB6U6YLxx0D5XNxpRH4F)vsEW8wBrNcfyT9H8yq9nTmoWuJCcA9ruCEQt2uzV)Qk(2zPYEex1L103o4HwShzYphjwXtwsuJZ0poex44cJqzT(lxgI7zEi3eC7yzAKmBnLT5t6hv8Dmfvht(Zxv(6H8b(CMkUc5GosRkingNUJWjorCLoRUPMiikITtGophA5AQA4T4eZNP6gFsejUItvUaQHgyOaoKLW7G7tvJZigykYx2tPAFqZcaVL03WpqheFXnEfJVWGkWlDSfluLTy8KnGRG9kZxntpdwkRM)ENmK2WTczXx4A3eEB0AgbDUIKa7p6Nc33Hvodxq5wAqq9hf9KhOAeSAQcFbsi(BvgicNG4ZRAk7NZG6hS1OxOAjBq93U0IWG6Vldgq)3VKSn(7CTLThBnLTN8fxBz7NSQYgCq3mstTus2mB4tgPLJ5X68l(33KmCQyS5c2)XvgmixtjdFHnGjISkdS1vEoM75(B8Ao3rJi3w1b6Zg)iyRgJdO2zZgllOmLN(2)07pX4hOPJLF7x(hlXHq)fuT(vZy30EC7Uh3McBpKBxUDI34QjFhroWbnJJuLYLJdVnud3jQDpFLVLOOSzAuW08YZAcAjXWD1WXTUNOOVa0UhInyth3mEfW4Mb13ktLTeiNUC6hD0JtpKJENxHtfVXbI3hSNHjFEUC64XmOJlI)ehfK4sAE)mR0U1XRgIg9wDAQrxpqItMVl9blS)cJXnrtJ)OVtL5Og9LliXlufs8yb97YTB8bp4TMn)(jBqBoXF5U(95UBNEXBsbUi7EgUCBq9Vyq9ZiBpbOEadQF(6av8k99EG1fw4y94o6eUglLZZgVPyHV7giwW5CAkmQJr(q03jbxG3Grn3C)i3PY(9Vs71Dn5NeGCO6dFvI)A2BxrTxLDG5ZXBCEcQCe)fKMSfIVIFYRLHdKnBWA(fBXkcSMjlJA1Fdam3nmn36pDBdHBwGu9m3m9gbTaHdVlypZJ)flaLTrr))C7YCV5(lVArg)P1UT2pV5EJNPPtqZ34pdV51tyo(ZPgNGwkV14z(BcIB0BUj4NBF1GFUiPfw5xpe49I3kTXWjZXWQ7RGyzB8(HTQvZhHyQT35KuZs6H1eWFqKp)AFHm1qzmpP87N87HY9cFD6qICmsimR57T8pjl181YI1)liviiJ6Phk6bRE1btrqzKSvJmW3djAqr2VU)5eaCW5fdhnMWuLk6mVksCW69lWYYjrhpYWrOHVOb1hh67XQU1fFc480HPhkA4L)Dv4X8xicp4pSInrvxwY2)qKFmRQ7lhbVjyB(dprxMF8NniJbhiqFrww284YCxCfJBB0RtnzGybchn(YYypDxZpqdD1GCcJuF7YMTg1As1FGbcuFPtrQxKVFg)(Auv6ebOJLi0XxwvYlPz41fPk1ZsYPbvr48D6(Y(R6ckpyUO5XIhKpgNok2bBhSNBp1V7Vchf(XKG(9ZBq9nXuOwBbR4TF1VXwFL92Vk8Aw(oUAP0Uv9l0hl7eJ1GDC1o0O76qEpKZogFZVL)3)
```
