# Priest — All Specs HUD (v8)

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

**Resources** (`0, 56` — since v7, two unit orbs instead of a bar stack; since v8
they use the geometry shared by all seven packs). The **player orb** at
`x = -260` is a 46px live portrait inside a 104px health ring (the outer slot) and
a 78px mana ring (the mid slot), with the percentages below (14px and 11px) and
pips marking 40% health and 50% mana. Both rings are always on and fade to 50%
alpha out of combat (a second Unit Characteristics trigger feeds the `inCombat`
condition), and the health ring turns red below 40%, where the Desperate Prayer
prompt fires.

The **target orb** at `x = +260` carries the same 46px portrait and one more ring
than the player side, so its outermost diameter still matches: health drops to the
78px mid slot and mana to the 54px inner slot — the mana ring only appears when
mana is that unit's primary resource — wrapped in a third, outermost 104px
**threat ring**, because your threat is threat *on
that target*. It runs green, turns orange at 70% of the tank's threat, and red
the instant you have aggro, with the percentage above the orb. It carries a bare
threat trigger, so it exists only while you are on a hostile threat table and
vanishes by itself the moment you are not — and it hides rather than filling when
your threat is genuinely zero (see **v7** above for why that guard exists). Since
v5 it does not load inside an **arena** at all (there is no threat table there);
it still loads in the open world, in dungeons, in every raid size and in
battlegrounds. The whole target orb disappears when you have no target.

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
(sha256 `6a0689cc64d31f9ef8e3e223a552b23101332127e5a53f57892e4a3ae5b1926f`,
10117 characters, 44 auras). When editing, never remove or reorder existing
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
`missing=0`, `retained=43`, `parentSame=true`.) The script
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

## Import string (v8)

```
!WA:2!T3xF4nYX5955G(4oQtoK8oDs6S0jiADNVtr3faqacWtsUbFrsCIeaCbi5XtNmXcSlWUhxS7E7UGKGkoUIrwHrwwPLUwkw2oXfXrT1XnTH5jkUT5lZM4K4h98KXmj(z7tJRBUMKEoPjn6sBZtA)N(oZUaybjioEK8oPZk)bxUy2zMD(437V3zEN3zw0K9w4l9dU8JSEE2cZYPPOgvrsr7CUC5kTlpNjGAVfuKn0uKK45IkikXPXlV41sRjYRB4(0UhHNvYqy9g)Emwz2MpnRGgpRH6rAgaRwjEd7uPE4ngoj1QpqJqtlXwLxZDAfndnwrdhpXo(1FYvYROXXRfXUgO2DejXfxKvJZDwffjdrvTfsvSOoVbkVklubAwKYgjkKDHLKCNrLVGEERmsqRQv8VCnn(sIkYzRQYZustPIAnRyKrCr(7Cvr5IkALznGy01QwpWQ1dHqUwNTIHGIwkvYJ17kp0owuSuxASfObmaJUbRMrx5lkklQl0ve4FgDTKHMyPs8A6jpHM9TVwedYBNTIgRV1ix1v5LKe50pAVEIubsuEvA70s0WtWP31v0RKNFoOAMPsXIIlS6mrdNj7mzYgMjBJhLwJhEetM0XhD0RvrNp(cq5kJvoKJrMTmVEx144Zd5aPYRns8rtp0eJUsfz7IvxRYjQFPkYqTzoEFSssQ9WsVpR1ZhtHJ)R(bSBUIZvIxTNmxUc067EOkqZ9ucIg8Rz9uR26dScRSOvJ5a4hCO14z15Zya9wLmeUB8XIiRiZVohu)jXygsBIMop0OYPVejQKsjoqKYSIYdH9djahapaoioe8)JUXqwrNxQyAfrzJ8rJNmBCM(e5u7Tb8IHxxPIwbE9RbXGxtMvAs4LbV2ND1IAqtduSynyDDnw5cqp8qKGiV(8zIYepEYAgkfMZk(7p995RIi3Q(vUeN)qEfo58(z0lWkX7Qg0rWqXw61HojKHwbx1ivjrlmtejfwUUw161qlU4NC5ZMh6U0MPkY6)lGWhC0UxLL7sv0n45gJDH918hIY7d39B7cNa)KQhMJxN1G0(XteuiOzzoHv1jfE(fGhWNZzCgsbG(wXHrxIv2aTeVmxy5ss8V4rWp9ZEfvnLsA866zOnvp(d9b2h(S4NeFV4NcpYKRaLTzkiXQRNlVbuFLnoct5kGOyxm0qprEDrswLpntI4zYIN8i4PZfbqWfocEYUIOdIxKBW3FxlPPyq7Yr4J0fdRKQaRlC8hF5hqTxdOypJUalNY8N3w(EfAyKlQDFCaHuaEZcu2MJFC1UDKGMYPxXk06aIiHNiBk1drdeKGviiYctjYziejm8ZRrFai6WZrd8fw3Q3zARcWB7AnAeiT)IfRIFYA0IpTfosYujJJpMg0ZtlGwLFRKxV8xJgwH6uWUSQpfbky1UhstCr3JxHLJa(CNnRQNgv2zS4HMPLA8mC8fabkPzu1GBiWrulTz2fzulfKg1J1PbopGmNsJvDPPSVz9gfikTqQjYoAIKXTBABbOQEQRtXJcUOcYmfLuu0SA5MdkP5L4Z18fr4AF41BTDs94xNm3kW8jRuopV2YhMMBaeFmrnnfnbCmx5lBFB3N)U6p0zcgYxncgygvRs)1StatD03vSdys7YNTu5mLbEogAIQhcWXX6l8OJIpwn7UAizQ9yFtSgsyc1ZsBXp1ZMGW2uKTa)fdZXLsw)ItXZoBycL)fhJNtK9I2Xu)IwuPZqzrpJrjwM5jGXEwZohBrhEi8btFx(cDgVbdMxGxSKGrpRzxuTRS5TaPcR7SsZly1Rc)ociaZri0zImA8KXWV63cp8zpbtbb(cZoe(HVZLMJvtKfAvwsuoQs58SgmZXkvHh1NIAFp9tRvqGvUeV(rpb(1PdQyjG7a6UmQIFUtG)Nb5Gl8ND9w6)WVEF(9aPU3Nc)trs25iPBW03HNZ41N1vx4p31k2GJIwHBKxRuMDH65tVKSPVN6PTYhe(ZHFU8fGx)mvj5JFV4(jAB2OgJbV(6qu7g44cBZ0sjEfu7jFdM16DQb3(DQmaL4m(8OUaPhf)aq5Ql8r7c)H6QgDOcuUxeomOub)qFStGF4xdkopk(XWhNHQspV1WQGG6d)H7Ajcdmz4b5WNa)rWNQl8JJ)bXprxothUM6HNaII7OcSKXLWRjc0wf0TZc8xEdPfFA8zW)qF1pa(FSWgR9IYc4EUwDDc24MLua9GWGt07AL81Hq4pdDqmnLR0lROyiK2oL5Qrv2mKOMUHWQ2PVGKOQa(Fe(hUUujHjIKzQho6OHhlD2urgnC0NjCSyjYMysGnQz3GnFX1AgsdMFs)FGalvqPSk5nlaJba7c)5phfFfGCnyiYvFbCH)OUWVY3sTNMao7on8xchz1usJNPkxE1sZhstuMO6NxyfA1GugZNizMeXIVQcm6czRk9krhnv0NzQezIBbfxWgkE4U0OjJNty5ZIphc)muL74r3hESgkYXjfWPYHtlGhhHzO6IXz2G6xC2C4jOkqN6e4ZJN2s)k(c0GEwBnR4lsuPIFol1P4pgcpZ1QRZuvzEETJFCmlvfjopUaMdZJl(c4sV9DGfGxKi(samAwSecx(CwnL0MSaUCHLXkyniExgPEYTINM(gCOdaxfRJnWvWZHNhY(fZP(yDoPwHH)rXp)9J)rqQ)qDo2Bwx4Yhg)jikcaWmvhqGZmyG(XVa8UxcH)XYHFr8Ne)s4FCOsUm(Nqa)Y4pf(v6b)PV6zWheHF1EW)Kqm)NiG)NkGxb)zWV6xep8rTiGUt8Nf)AavJf5NfVdL2JW9G)I7sAh8pTa(NbGDoOhW)ZDYk8wnLUzstQ7eP5vOTcK2zulc2RtyjA8SCTLJa)ZTn4dWVji)J)xG)x2f(Ff0C8vq4F(C4VQa(FnvUf)lG)3G)3IW)IxDC8QubT7WwqZxaAtd52b9zjN9fX)suXQqj9xumOy8s5ZI)LfWVf(xb)1W)7W)7BiSG)p4qmj2nUysrqmHstsgUPqNfyMJbM5Or1C(uNtn3sacZOAzw5C(m4LZvZyEaNvTim5hy0U07ZHdKRvrSJAlIT2XnSMvCbJgYxQpXMaVnIuBqUTiowTU0O6J2HmPHWslISbTA3PDbHSeBVmQfXqTQTzKwnZ2weFPYHGGR9WdAOmUr0bL6bPAJ)O2sfNJo(Kbix8c6ZXF(gjIHTeWZIFDxofIUAOwIZQwzmDKgTvp)nxzTKoLsQzvwiktH57qmobiLCfc2Q5dYreHQP2TLvrCNr0OcvBavMAxlqDNTiqfICPFB9w2YtxMFSYbYkD5rVqKBoYt3WQDQltGZ1wfnU2KIMR(euqQkIGt1Gi4eRUaGbb03Z)Wey4hhW6o4Kb4c(l8UnibOs)zH7(d2JPsVl8N)QmTWCYSyOPxOWGrxC4fFVwp9V62CifxLZXOiW)ABA0b4F96A(X)gG64Yo7Pxcg(pvNg0H79DHo8VHJo8FtshU6HjmbA8xUIOgpvNCwQ22VERkJXRLB3JgUBan8jOOHY2ObvUj5vIgiohFOTgn0)QKjYkLq3IPQl894JvvuGo8tBCHgngedoDFnmpClncToPeB0EBh4Wn6amwt12sVxqrPCoaqUMvzPOOeFcoCF1S(Pklm9N(SQjZOdkQQIamOJFdL94DHF1NB7HGrnQMlPd9D8Yf4DrX)a0gW1)acyprsQiZJ7HH(kWh6rB(UQOpo00283AlI0y5MdM4nmuJDm0d6xh6(T7iweH9DpuyhPFF)2Hw1r9vBH)0UXVYZrbkrwD0XlEYtQnn)5IhJijR2nnEXe1j2poHCrfbIO62AuSoAsx057RkA5(X)NPWh8FSaLAPoPY3zRHn34KK)xiya83fI1)v4V)esVm(k7W(w8)Tn2PI)tbjU)mO3e)Nt6dX)3r4RUB7ZWFVw6Toa(VaH)lD27m8L9EozTqtmU05P8S)vw9gDH)Rr4)NOLFeNL49Dj1hSHXQZqnMNBIb6CNMvuw9(B8OjzlRkQjwWDwLkfeCKMgpiE58We)5DSeneRtWlZZ5oJsfj1d1i8eYY8AUH5LZFfh2jxMFEANnmLO7f)bjTEDd32dUx8HUtst39zr2FeQ6G22P)iy3hTxp1jaiaasx(jZ1MEDpyVyFhyN3ranRqBFZIFKkflQtasqpePtGYGd8Ld7Xibxy)NAHHjtpeavdr7igPlcqE5pCnXckYww9(H(aKQw3iYdwVGIIe0tiNzErGCFT6)KS2hcBMN8nTQ7FfFbcnOVad633Gb94BWb9fXxWbcY41dek9A)0R(z8fOFiCY1qAqUMswcMKHTCYgA10gjmZydnXO7KzY90p71MLNxnmXu8gmKXNkqA3Q1CHbeWXp73E9sskZpKMfRyvRXDgHeMWAGQUHLSnWUWkKWYyTIhKBhLUCo33QK7RB)zACAyXsx0Nv3oVwMlNec9nMvqSWSY866UwI(tql665RyyOiNYYsr08Aurik9qFFrSwpVLpeD0h9DC12n8dulJ(OmTuSPjdTwIKjJZmtKuzZMAm7bzUyUI4JTcuaTwaN1T(3mkwLD7v3Y2A(0LAWoK6242EHFMHhGiyV1)fz2OUWV644rMdiYOtIGU0EZkd971j2UWMO3Q1ms7)PUSnnxpriGvq28VdFWN4oaWT)OP88mcdmM3zhNP5YmezrqVkDkdlvh2MRbx17OE46bsS6fOWGyQxUCe(PxzCt0JsNP7VCDgsI0grQde(Sfm3qihDtHqe(g(XBm(TRWVaWorNBuwXY8BCuC5WFoIH1pJ3Zq6H3o2CbiI(OUw(dJ)7DkVI))Md))BRfmplt)(h0RF61bOxdAIURTsKZeD37mPnt0(PcyMOdqfSmrDzjnzIUhbt0bH)UxxMOp49zI(bqMOUPDxMOEajdtuVMOdb)4WMi4XhPht09VxG0nrpGt8Tj6bnrhfE3FiA(zIEOCMOhg71eDSMOut0JS1ittK79VC(6isaWyHhHH5hz1il8mxkHNjN)YNYNj6dBx7Emku0eD8MGWRzIoXnpeNj6JaOS(3akZeDYBwORJY4nGVqd8pGO25iQN8T2eI60aGIxFrHmAcCtFQH6iG6V97tau1hdvKbcgk0)awQTyj1EjkrLvm2SI0R0AOenNB5CgAc0OQsdFb(etm(cbMB6l3rK2)RBbinV36qAlcJynuKGE9fY3aE8fXRhpdadrDWaEPx9bdr1F)E7045314WZT3Hd13X4qigp)JAbd3Rq13)2hvVDMIBt46NeqRde8ctYm7PgppFOoIw)FFtaTE0BwQr)M(82)GrgWtq)KlbixgGCji5sicG0xq6vR7hKm)jVbGR(85LE1xh0aV3awVnwbShBiMjY72KxKoKU5Ny4eNBIHNS8eb6is7)ZTaErF7gErprkbt1UVjsJ33lR(H2GbxiRfM7XsKjtIKdV5hkYlZ5oTMszvdhU56qSC81d1DJqJXd6FiZSgcYYHxTIrpnIr0OUtL09yXvpAZSkEyg3tfMjwJYqtVJDSWzY4owcIVD6ozQPCuaYKy04jJgNek1Sne5SVovoZYqnm6QSf4V3DRLAwfMzzLYYzizMlIbwoBER5nZWkjwsg)KA6gSeNeLAYUrCAnonlNaLph1EsXCTe0dyNputZ5f3ZACvLzllwG6pU4dDNr0v0mWbwPKMOLp5DplrULyCG(yIXijww04EiRZ7OK7eUcmHy41lBmeBbdfT8mHJLyIm51y5eRO)Ihe77aRWQvWYqfV4rQJwB6uZHL41m0RvSIKuurTcW04RB)OlIiwk6Gs7ctubYad3fb(bdVqkDg9SX1L9xA5hd)3J6mPyYwNBH)G9Vo0mwqGxpJGY8PKxxN(VXe1joE52YCBBKj7XBYKzZuDqGK4WmPfxGxQf(SMEqJ3auMnG5lNfRhHCZIwB7Wd9s1NiGfDdLnQg11sPEzwUnnPGMg(GYjzIYtCtzQbUHUD1pstNXI8B9lsh5NT)qA)pIGnXEMrwvpSNbp)e6pZjLhUnezc1HgMOeBjtgujZt8UiEdCinIBkNQIb0NBIkVQUKihFEfddLYlv3TM9bznfl0gcVL7EfQRdtn6Loz1qkjyqnTg8okurhYN80iuLuc9Jb18YwbSanatKAVEXphI6AU0WZ1BvUd07cOvOEvljFxQE(sE7Rd3lRlr8Ev4rQ9u)zzRhmu0O(psJ4LJM30ClNfFCx2uPxFamrR(FEDnTQ3xloVJcLFurR3NAnNH3xap2RWwFu3rRfp(PdRUg8MwUhgOuxy2iex8vThsIlXlZRjwWsCj36T8ZvTKEy4z5QsDNgkUjjBz(9)sVa(ym0FA7rDpyuBJL5UUpT5(KuhR)uwtdbiav04jE2gqsXNBDawiLPE2TQd9hR3WYFKNq9Eas53Q2SIDdFHzZPEiY98eh43z0VXLKnrcofJB6ux9hW1EUySjsCZIVqJ5geFnrxs9KBhPwslMLy70HKcfY7GStVq5ol2EUoj2cIOurilPvtKci)yIU8wlDAI0mr6KeAyIQ0ug0enxlYFMO5Rl4zIwWevLKxMOfnrpp9D9JaTeF8DK4tJ1DE9MoEIAbGLCDy8TGaWFyo8VFFb9aaj1EB6dp1fUiELtn8FKdVrHkNyIEbt0sMOFmOy9IMOpjb(BIEPV8JrQP)4wyEt0YMOFcicVCeYqCmrVYgqRMOpn80xDpaus1T4pGLldTBWKVg(3QTU8LtKkbJcWsOUsDbm8VDo83ih(3jh(3nh(3lh(Bs9YRwGQNU9q1YSLelmJeWfWt8quI5)fLmQAHxJYn0LsC(fc7pT3oJxFMVFfVIFJ(87PH)caiva8qaoF5CwuZT4A45upsRU6FtTdBdC7(hiBBbUQDVXHHFZefB5Dw0b8ERHyfQ1THy9eThTkOivDgqXf0MA5GAuyAMXsgoq5flLrIRZW0rVTbMUnm2azC1ZrXPogUmbsutT7OWCt4ChTX(JKGC3Ewc46rWDDh88ELnbE0TPnbM2YBz3coZMgd4eabjdzlwY6Gy0c)Oui8iEspFQWzxOZ4NXAGFM(9O4N3OPpOAV7yP7(WxpsMStK0Pff2qVj(ZDTMlCzRBzft0pn(1xNK(zglE0rcNmr0oMrMOVuRPncXIaTKes1lOftt7sW6Ke0(x21jLArtLCOjYeFtPXFt3jU9LrMuPYUPu1p911(3KTbl2Ctri6BXxBRyPdhnXqtVtsQA3zIosQuJotcYMcLzI0zVoj)gsF3B2yPA63)aMOIMOsxh7KV1QXEGVzBvJTYq8SAUNIvJ7MT6l)won(ox910wQVakLR7s9bv26KlMOVWggY1J1bLy8luqrRGOU9e6dQoq6jt7lEIlCPotbL898uq3yJ0QXs3mGFYk24ZdJ)a(7peJVGd4Dqsa(IeiWGdYa3fm01XC4BnM8hD(2IjxDmwyoWe)mKyMODcQ8gqZzDPZB2koF4TVIZTlkhA(2Au(wy5kwTcSY8W8l015OnWwa9(9gXtLPV8yJepDNb6P((qGU9A1ejkRUrDSS1SjAbh)nCawxpm9qzW9euxBIahbCRwgrjIp)whZwFKFemlby)s7)P(e7Eu72ZklVhg2cncBnS9X7OPBelRQkWQZRliw0WMIMn(OluILpEqJoJCtFBdY1JjAKAJKIjXfsLmB4rX77nA4UTrJrwUgrzo3rKa0Q6d7mCNo2BmEwdHgE2RJhtT7vRPZEvKuk6Em4zIYLAnD2oYRsHk6nwpjR0rmBk84Ivi7Ym1hQLNXkk7otfv6oLL807Z5thLyw45Ho2wdUXyrASwtpXD4yXMmrJFGD7knzIySwGjIqxwYLj28AkzIMuWE5Kmrt1CHKmrNhFO70enngIYfUht0Z2htmt0fH7Eoa3)XmrZyIYrxsiteBZ1cYXjfsDB9QBIkSX1bcTNSmq(fzNOi7WXkp4ieoWTZIJVbn01igVoS08Sv1RRP(r(cTvtDTMqXoQOExVO47cdqlCdpqZWBthkBtRD03GSut2NGq5SONykXflE85emkmrNwBBt0Vgqpr9G)xj8E2IBFUgtwPMICDK3g2JK014(aoMvZBVHf5EBVi4BDueOzrt9YxpmPC7g14VBJrn(8T3GC96G)7SweG3iGY9S9E0od8(3ChHExaWAI(M2a1GXsk4BcpfMo7SDgO(RFtaOEHwXF7oa6BGF9(c48SarWreU7Rpc(U3dqWTHv9kwljydXqB0mz5aBdA2e9PULXOUdDZO9my5MwephWYPJC5PdL9ubugNTZWYFJBcWYBa3qBNHjCWQ9c(BpRwpBA0zVxqtB7M68oI3612QLuZtolViZ5IR5M0kTLqfDH4tfBu(HmovOodv(nVPQQDpGb7wGk22cg)9Rdgh8NP9gMXXubEFd7e0wS1knlnD6GEJKIvHRZqUV(TNStnaeFKrBlG4kTofW33GjGMJTetCzw2tEQaYJhyOP7mMyTBZXeVWBTflm(gN7)7BGfVWBT1WIfuvh0ycn9XLxSZWI)J3EdlID62Votnm5Z7xqdqdXwcgI5Bod9bngo)5gPZGHFRBZ5i2IvD0e9vEFdPG9Ar2wCq(eJmWKsEuoz5yDgh8B)UloGyrAgMedpsw8(oQJZ4HruKQs8A1c6nSyR3BwgSnYOXhkBhTzBU9sB228uFGw)AJ5A)o7jMRv(sNpueUKPIXp0219IEtQbAJkPiZRNZQX8Xz6VFVb8Y0V)Gb8VJCw)3dUKPp42CTNcVZ2)rMOVRTngQo9umgtR65cNVZsHFNglH0gLcPRnOH1sir6Kjl8Zc1Oo2E6ks68wlxeDLI8sWQZz))5ZrxfivFue8hpx7KEDK3wXmeK99wf17cVZn0skr3xsxQXkUCA3z1eLNL3WDSutLuTVMhOlIsseZnyiWdt1ttNC8UyfNMh6lXL5lxTEg4GqyIWUvKjhp(vDSMhJvLUHKQ4mIwza587VT7RiG54E3ZyomrzU1XBSwtEJ5s3gwdU9Mn7ZGJxjVEOHwiQ(KBhAJV2DTpYj95sIg8LP7cHe)cK2oIcBCn1hOn7aHeqmpvtxR1sT(A09JGDEaupri330m5VLj6Vz)j(zBMZMO3zJzHj6A5ia6)2nKS5(07SK9Y7OK9zU6olzFVBOKHpTpw5QBMUn3TQbOSTDbZwwi()AlAXQJYviYipJ64r47mT4vVjm4KBqpUDRhb6X(HB)SupC7O52bEB0TS(YTR7vav4o1RwsTQ)Hp5INm1CNQZ9QFV397vj(7Fnn7ptjhLXVpFd6Zsau1NxFEiNg50ncLBIN74otLcf4jNT44hfQ4R2yZqLGlx78ON3LN7W2s08iTThCG5lhmmJVj4I05EW)I3d0dAI(tY148rYJxpHGR(94NEnWQQ8AKJpsYPE(sSflYxWG07H79kKTRPOmFARNNBlpIsUTY353UJNnXUbDC(I9BmEPtwAw(57S)q9x2yWSjE3cD8TBIoE5iH86Zh5IFY5xxOq0tXopKDMCOG(gWtaY5XGx6rgIxFM7dzUV9zDsmaTbM7Z1UdHCBY5SWUcxCUb9LyEVZMXZLt2zCX)JBI4cp10vz1MLUP7VpkgbkB2NgI0N04R8GApT8B6hcIcq5rOTNyUqfg)FABC84spjgD81YX2tWwkpR93HRnFcZtalRrllwNWGtdtH4ShbFSvjFukG0nd83YhPdNvXDch0YXu8QwhyGwMzP(bw8dADGfphfBu)8c06JXIp4n3b0YdFJGwUcTg24Z2IVWXIro1IjWhRUSMh3IeXAYrmSMDdaaqC2(CE0k0gzDrY(68pENpzhhSfRsZ)rOFkAEAT6FZzIkXZkdavR3E9pFko27VKrfikxkcR2fNiXPB(RtNHcTOjZbW)VcKhq0dc53X(iwvkwIrfRwPSNIAGmGDPqKJJxMjz8jJZG)AMOFv8WVCZJm8PWVotmMjseBZBde)0VgnE8t2hi7R3wss(rMG(nfRLn6ce5bcsn3s)wBH12KWiJfE44Bkz(9ADIUtaWT71PLo8OHJLi5Ms4Gd447Yr)TjL4PBTE5Yv7Qnzgj8yHBn3PF7u8t3UpHc2UI0uHziFIt2urkaTAeWlTin4gsPj6tGF9(8DD)U)aPHqa9ls)iUq27q9wUxUE5w(yTEg5IFk8Fh1nKHrT8DjeN2huTKdP23E)V3(qQf)b385sBLS(0cjomh38Z2MZL2E1z6)mboJNEN7o(4))p
```
