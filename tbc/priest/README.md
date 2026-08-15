# Priest — All Specs HUD (v7)

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

**Resources** (`0, 56` — since v7, two unit orbs instead of a bar stack). The
**player orb** at `x = -250` is a 28px live portrait inside a 96px health ring
and a 64px mana ring, with the percentages below (16px and 11px) and pips marking
40% health and 50% mana. Both rings are always on and fade to 50% alpha out of
combat (a second Unit Characteristics trigger feeds the `inCombat` condition),
and the health ring turns red below 40%, where the Desperate Prayer prompt fires.

The **target orb** at `x = +250` is the same portrait, health ring and mana ring
— the mana ring only appears when mana is that unit's primary resource — wrapped
in a third, outermost 128px **threat ring**, because your threat is threat *on
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
(sha256 `95e0a8e66b9eb2b8d2b7438d1b8f99e9a6391abe86ec4b551c241a9de7ab1b46`,
10134 characters, 44 auras). When editing, never remove or reorder existing
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
delete after the import.) The script
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

## Import string (v7)

```
!WA:2!T3xF4XXX595HqFqbjzdasrjrlrDcwKMurK(Ud3bCGsY13xa4OaU7WEhajOOmU9UDVBxI92D5U7bGdYYQewwbrrwnfUrQs2X25IJBTRBAd6tuCsD(qOjUP(XppzEqB9Z2NgxNW66k)rCJz(WpU5FY7mZEFbC4iiaiLOv(dSyVzNz2zM3FVVVZ8((oZIMSNCFUFULEG1YYNBgbdn9WAkAgNQJo6izhUpHF9EYPPAzOPOikewswrWquDHlN0qw00Y1XDnIiVIL0A1(9y8Q81FAAjdrEl9dupbEJcIwoLsF)RpDsP1VNAPMuHVSOHRKAgwg8Ywn8eN8x9jxkRMHGOriNEGExHuKxybEdbxP10uSK1nMpr(8MIwOS68qhOEtkDOWq1furXvkDXCMzzvKKrzw(VqfdXcYAQPlRlYvWqRKEfwosjVG4nVISAEnJI8wqo6Cf2dyJEieQJ14lzjPzKqN8yZoZcJJ5Ll0PbFoAc9ZzAXBy1z28YQYMsDgc(NvNlAzixOGOHz8Jy4C7lhYI825lzW7DvYvtDrffzbZd2J7qLGcLvNooTin9ycMDEjZszfNf6MPkLpV88RmD4GPspDQ0b5sx7rjneHhXLkz0rh9YLmfJop0UsXQHmCQ8ffn7SIGywOgiDEJrIoAYHMy0LlP60S6CfbzZZxsf6nZk6LxrrVBE69PzpFmnbXV87Yz4kQqbr9UtDHsWOVRHkbd3Nws2sCv2tzJ132Y8QYSbZ(X37qRkYBkMYcOwfSKUv8HcPQPkUMa0)j5yAYyIHPimOkyUijRKwj2FOI8YQdH9bfa7h3pEaCa4)hC9PSSPOs(KAYQwzdhnE6OC9klO3tn4fNOPwjJCIMxgYHOHkVYKWldETp5k5nGHgOzXBX3XL5vZbu4HijrE9ztfMlA04vS0Ynll)7n5D5TKSWk(0oVGVaEKo6C(4mZXRi2rfGqWrXwMvHoXuHrHoQq6sYmmtifnEHoxH9AOnx8JU0jZcKlJPlJy)FEe(o(YVNv4foFjtlrHX4NFp1)HS6EWDDhiCm8JQVFbrtElY4NiHrHGMvfKwXK04fNhEGyMgZZqAa0NLhotfEvl0IIQcbvlOi(Cha)4p5L0n0kyiAAMIou9W337Ap4tIFu8DIFm8itUm02MoNcVPzMSwq)v16aCflbSIDYrt9iznLjvv2KCXIMknEYdGNktiabN7a4j7mKjWErUbF3DUOHMfLKJWhOtoEfDj(oWrF4LUh9ESGM90Ms8cAZDgh(7LPPrUO31Hbeso4nlrL2C4dR3vdfOoF6LyPwfqek4ePtOVpAIahSgbrM70YcwsHcc)8Y0haSoIc0eV4AmQZuSgW3OJvPzGm(lNVm(rRqB(0r4qXtepk(qgaLN2azTFwXR2(RqtlxvrWDW6p5brW6DnKH8cUgVeVab85kDAD316StZKdnDt94PfeZbmuktRBa3qGJOMgZCAYOMAi16hRrtCoazEAdE9fpTZnRvRbrflKyI0JglEuNH2MaQ6h7k08OGlkJmxEfnnd2i3SqlnRIyM6ViIS2hCTMhN0p8vOYzjMnEPIzfnwA)0AdG4JjByOziHJ0r2Io321zUL(8DIbceOcbdmToR1FzNcWvf9DjNeM0P95WvoDrqohhTqvtbKXX7n4OJIpufhsnum9UDUjsnomPQvPd7N(jJrK2KNpN45ckiKq18CNwKFMGer(NBmrbz(Z5KtZZXeLonvk6jSkWZnhbm29Qo1yt6WdGVJK3Ix)NW7a(ZkjkxqYQ7vDAQoD2SmqQ0An2PfLyuv43HagybIaDUqJgnEe8l9g4Hp5r4YjjMBMHW3)nV4S8gY8WOYIYQH1kML3IBwELsIOE1079XFCJCs8Qfenp4rWVcDsflcYoaYLvz8tDe8)cOg6a)lVwt0p8R0Rp3qP75XW)ljf7uKYnyYBY9j84LDTd8RE581Krr7W1QRLlYpF16Phs107J94S6bHFv8tLnh86NUmPE85b3hrBZ61ym4vwhIExGmUGosAPcEL07oBnjRvjQdS1jQCGiXP94wFEcffFpq7Qt8b7e)E7ScDQcuzViCqqPc(((WhbF)Vm0CEq8dHpmhvLEw20QGK6f)(6CrIeyY0dYGpc(9JpwN4hg)ZHFKoBSC4k67FcilUclXtMxIOHmi2kNPtvG)8RRS4JJpb(d8LFx4)PsRV3lRkH7(Yv1j4GBwud0dctoXSZLZwfcH)K0jXuNVYSOMMLusNsMPcvzZqYgMwsR4u(CkY6s4)j4puvUsIKisLPV)WJgCSKPteA0GHFIGrIelDSjbPr1jdoYlUC9uQj5Nq)97FXCAf1jVzjyoa4oWFQtrXx(jxhia5Qx)DG)GDGFX3qV76aohIg(ZHdTscLXtvwiREH5cyiRsu9lkTmTBqAJzJfpvSirxrdMDHkRtVC4rte(joDSurzqX5DGI7VtdAXefKw6K4tHWpbv5oE09GhRMICCCjCIm4Ks4XryoQUyCQ1P(fNodEcQc0tFe8zWtX0VIplnPN0rZk(CevQ4NIPof)Hr4PVCvDM6AZjAC4dJ5PQiXzX5WcyrC(lIl8dVjSe8IKXNhGrZGvq4INInushY83rhyvSg2aY3fq6hDZKttFdnOdaxgBITWLWZINdQ(fYO)qTVOS0WFu8tF34pcs)d0(CVrDHlTF8ZsueaGzCxFve(IWBDre(JLb)C4po(5X)8q3Bj8VGe(fW)I4xSB8N4npbgOaVu34)zqo)LKW)ZLWlJ)K4x6I4Hpit0ZnJ)LXVmiKHj2JjXHkWJi1b)RSdf4G)ms4pla4AqWa(xTr5bVED(AUKKEnHpEzA)NmcJAILEnI8HApltlLoG)13cscWFbGZh)Vc)VUt8xego(si8)Mm4VSe(FlLJf)BG)3H)3JW)MV544vOSy3KdlMx)0HgYTd6LXHDr8)bkdvG4(YlpGC0cztJ)TKWVo(3g)vW)o4F3ASj4)JnWG85V6zqYdmiubKKjAk1EwLz5G1mAvoJx9z1ZSiGTSkxKxnJxlr1mvSMdqyLZdl7bMNl9(my)zAM56GomxREyl26HZzvJZs)r2aSTwMAbMTjgXVyv(q9hSnvsn2KMywhGnUtjbbymSxa1edOXxSfZXQE12eJ7t)EboqGLf)s30EjZmOME4A5h0Npavr8h0HT4u0PM0p5Ihqvo(tvRqC8farS4xPJg5IEZanLNvyvmDsgTuf)1wMT4nYMuH1wi6rHL6qSlbWMCjc4Q(dYq4HQO3fZGiUsjBvIQiGYuTJ5OU5M4OcqU0hJHcihmoQliowr)PvUWONn01goQRAvov5kWzALsMrV5nOK5nFekmvhrqQgqgAeTopGcb83t)GeG4ZaODYuupyn8c(t)wnkbeM(Rb39FDxwy6TG)uVjhB2jouAUfcm185gm8cdVWB3O0F1wrPvULnsPfyZGaEeqQ)92WmdW)(v16J)dqnQ)fO0lct9NQvdi4EElGG)1AGG)hsi467NikWq8cLKnePALtt13(gnRogVAMDoA4wb0WZ2KMuDHjf1c7pQGyGnhn03kKfXQeZKjQQt8T7LxxwIo1thCHbnheJnDx1mnCtdcnVGeh0ElN6Wv7umwv3XkVNvtRygaqUkRTKxwrmMaU3kSFQZdl9PxwpzAtqvvzeGbB43qBpAN4xAWTgcgvRBUOjq7evZj2bf)dqBax)EKWUdfxtve3nh9vG33dw)DvYCCyOT(VnwazWlmlSOByYgBBOhqxh6UDielGWEVDkSJq33RtQLBO)Am)3Pl8loifOeALrhp)rpQXuINkAecNSEx08fr2Ky74yQ51KiSQBP5X2Wq6cn((kJwQp8)tk8b)NjrfTuvOY3AZHnx9cj)FrWa4VnKR)C4V)ccvgFPTjTf))E9ev83b44()aut83LqdX)Fr43CNsZWFVMOw3g(7JW)GgPodFbpNs1iWeJRCgQC2)sg1Ot8pcH))Hw6bASfVNZRFV1muDkQH8CrmoNRK8YQ63DThnjFrDzd5CUsRvkNudLP2dIwmlSOFXgCpdXYeIQIcUsPvsrFF1spMQQOHlyn5IxQbBKRkohLyde57e)UjJEe6D34EW77MjdD3fty)bOQdAjr)bWUoypURkaGaaiK8JMPfuD3ypyV322NqadRWyF9MFOs5ZBsasafIqeOsWb5Ld72kMqqFhB(HjlneavdrjeJ0jbiV07RIConvMfVVV3fPR1ffHVwonnfGsOMAozq4(Qv)jXVhsBuo5xG13)sE9hyqV(h0N3bhWT3bh0BiVd0)aCECdPsV2h9QpoV(7dsNCnGbuRjuvGLz4WNSUrnJrcYn2qtm62zTCp(tE5zef1dsmdVfhzcQsKXTk1DkGeo6j)MRvqrBUHmysflZM4zisAsRcQ6gwXX46sltslfZBhKBhL6kN7AfY9vT9mnp1Swzh0Nv1gVmtLtsH(gtljNBgvrtZowK(tql6AzlzzPPMGzLiADnQmKLUPVVqmF5T0(OZ(O3dR3QPFGAA2hfPTInSCOvJfpEuUPdLiD6eJHF67NTAN84dTm0azoVzn2)MwJ12D8SLJL8PUzWjLQ232XPptlcqeSNQ)ISE0oWV044rMfeKrxfb1TEZOc09Qc2o7geVvPEM27JDbhXCDhIawbEZFc(oEKBca3(cNW9ti1)yEMzCU6Uyi0cGEv6AgwSkSntnzv)y99xnrIfVafgeZ8kKHiF6fh3g9G016(BvvcjHBJW1bmFomMRlLdUHuimFd)W1M)2LeNhKorxCuA5IIRFwCzWVkXO6NWZjiu4TIvxabrFWow69H)PnYVI))Nb)3V5mMNKRpFd6Xh9A)0RdyJULnJLZgDRBpUnB0EPmy2OBJYyzJ6KXnzJUDjB0Da)DNDyJE33Ln69GSrDrjx2OUbodBup2O9b)y)2i4XhOBB0DVBG0Tr3tJ4BB09AJoi8UFV06ZgDFzSr3p2Jn6q1rP2OhyZrM2ix7DPSvrKaGHHhHP5hALqZ)eNpM7jN7chZRn69507Eiku0gD46GWlBJoY1oeNn69dOS(whkZgD0RvORdY5XV3a9)pIO2(iQh913aI64aGs0CbPugsctDSHAlG6V(NrauvNdvO(hiqG)rSulXs69quIQQzTrfPxQ5ujAo301muhOrvLg8SIXMy859p7uxOTiT)MRdinpx)qAlaZynqOb84nG3(D7nKh3U7hMI6G(9qV6fMIQV(80U5ZVJXHNA3dhAUTXHqoywACHm7wO67ERJQ3klXToC9JdO1(h4StYnZXgpRyG2Iw)BVgGwp41k1OFDVE6BWq97EaFKl(jx6NCzaYLaeaP3bOxz3piz9tE8dx961d9Q32ObE3bSEdScy3oqmBKNTOCr6u6MBIHJDQjgEYIt4VTiT)URdYf9UtKl6oubyP29ors8EEb9376m4cXByUglwQuXIp8gFOSOQGRKgAf1TAiexhIxqSAQUQLAerq)dzL1qsSGDLLJURLJWHDLiURXIQFW6vv0GCUoDqUi1Ad1Jm2XcMkLRiXiX1PR4joDdnGuXgnA8WrjPsnBdHp7nO8zmd1WzQZNt8o3PwQzfyLLLkQMIuzDqmWYjZYw3mhVICbv8JAyAXtcquQj7gPrRXzWcauXmu7jfPJfbkGt9qnnNhC3RkuwLVOCoAS4I33nhYuZWc7F5cgYS4X72xKClX4a9YfHtrUOS1Tt807OK7KUeSGy41RAneFolnJSCbJeBIuzn4fKlz(C3b27TTmVroMHkEUdufTwpGMdQiAyzwjFjfLWYg5GLXx1(rNdrSu0DOSdmrfWdmCNe4hm9cLKPmth1u1xHLEi8pf1EHIXBETf(gOV1GHXCsIMPK0MlH6AM0)nMSjjOl3sMBB9sYE46sYCKuDhGqI9ZLuEErLMKNvp6z84NkzdK8LHj1JiCJjwBRih65RUqaM4gQ0Ok0WkLgHzz2WIcQB4dQmjBuwsiktnWnq21F)1delYVnphDMFoXcPZ)im2e7zgAfZGUh8mty(ehvD4wiitQk0WgfBtLKbDYSKils0chWGeIYjkzb0CBuXvmvKfeZQzzPvCXQH0SxOQPyHwiWBPUwMg2WuJEzs8gsbjlQP1G3rUsMq9KLMHYKwOpmOMxLLW80eSr694b)uiAy5stptpLfUTEMhTmnIAj17IvRxYBFn4EvtfsKRcpsV7QplD1KHMgncsQLVm06MwBzyYJ70ru6vgat0Q)DRQPv)UAkWD0OYh1m65XwTX071VBhpS1lnu0AkAFAJ31G30sDZbT6CZeIeEV6DtkCbrvrd5Cm2LmR10pxHX9WjYluMgqnuCtC(II795Vi(qC0F6enD3ByhJL5QA8S56O0GQ)ySLHaca1mejr1giKsmZAaSqjv1QBLg0FSwnl)rEcn8biTFwVzzNb(CZKrFFK7fjbVFJz)QNt2gj1iBC9a6Qp)DSRZgBJK3i7lmyUo2xB051p6wHRLmIXyBNkGsGaEgKFQ5l2E22t1o2wGfLYcX4wTrAa)Jn6cBo3PnYWgzskOLnQuDEqB0SnX)zJMRkJNnAEBuzsDzJwWg90031hbgjEMTf7tn)oVw9iprphiLCny(TadW)Tm4)0EhWnaK07PEu8uL5IewovW)3BiCuO8j2OlAJw0g9XGM1ZzJ(4e4Vn65)8pePN(ZZW82OLSr)cqgEHqKP4yJEX1HwTrFc4PV0UaOKQBXNFwmdTtWKVm(pQLb9vJivcgfGLqFLgey4)4m4Vwg8)5m4)Km4)lzWFDACE1eu94TgQwKVGCUPvazbIKOdLy(FzfRYm8AyHHoFSZmFqFj90E86t8ZQ4v8R1Rp31IxaaPcGhcW5ZNHjAUPWcpJ(bAom)RRDylGB3B)PBjWvVR1pn8RLOyw4zrNW71hbRqVUfcwpsRrRsAkLNguCbJPSiuJcttnw8G(lUqHukcThMo6nmW0TGXgiZREwkoTHPltGev07kmS2ebxHRT3iji3TMLaUsc4UItEE3YMap4w0MatXIx2nrMzDJbCeqajhz7vY3GGrg(rlxWrCNCUebtpF7XpJvd)m1BtXpVw9Gq1zNXs35HVsOuPNiEJwuyDut8RE56oUS5TRIn6ZGFL1iLF6XIgEKGXJfUTvKn6Z1CzdrSiqtfH09gGjPPvfynsbA9l7kusJWjIp0ePIUHY4REaf362ixIeP3qP6J(6A9BYXGfBCOia9T4TLDSKbdhBOP2ofvVRuHhjrIrNogzdHYnrY0xHIFvPV7luZvn95RFBuEBuHRGDY3C1y3ZxVLQXwEirEdxNM3q4AT6lFSWgF7R(AkM6lqKYv0vFqNTQWfB0NEDt56HAJsmX5ZPzKt20zb9dO3FYjt6nASZE(2lck(B7fbD1ntRAUUPFFep241nNp)(6laN3b63ZGKe8gYV)bhKdUBGaxbZHV5yYp6CTetUYy8WAGjXziXmrBhu5vHMZQCNxRvCE)BDfNBvuom8T5O8nXYv8g54vfH1xyAkqhGza9(8eYDPPUWyJenz7b6j(zqGUJVAcfM30QkwMTAIMWXFTgaRRfKEGm4AcAOnrGJaU1iLScjMFRIzRoZpcMLaSF(9(yp7oh1U1SYYBJHTWGWMdBF42A6g5I66s8MIMsY5TCerZhD05lWlgDaR2JCtEddY1TnAKkJKGl2ztepDWrX751QfUTHJqCxJSQGRqkaAv)(Bm9gdS3iI8ws1IS3gEm1UxnxohViPL31yWZKvl0C5CcKxTCLmR5pjw5iMnfEC(sK9zM(910Z4LvDLQKoDxYsE6D14thLyw45acBZjxBUi1810JCtn4SjB0432o1tt2ioMdMimDPjxMyJ(uYgnPKJ7KSrNUUJKSrNbVVB2gnfgYYzVDB0t2lxeB05G7Eka3)HTrtBJYqDjKnIVUVGA4ucPQTEnTr5wVFGq7kUbYNm)e55hosXbhHidCR4C81PHUcX41bvMJVSzvn1pWNULAQRuhk2wf17yNIVdmaT0v9endUfdOSn47OVgXvtoNEqzyIN4kiejA0zLSYnr78TTn63deprJG)xm4UMZTpvTfRurtTkYBDBssQpUVTgwvZ3yDo5El7e8npls0QOUE5ReMuTvZA8pP2SgF6wBqUEAq(3jzcaVAaL7A79OTh49V6Mc8waG1g91DaQdejUK3jCNBQ0Z0EG6V)1aG6zBg)TZaOVg(v61FJNdisnKHB9kJGV1DbeClKQEjMlbRXg6GMjUdSfOzB0V41njQBZWmAxdwUbN41aSCQqxyQaPpMFTX5BpS8p4AaS8Qim02EyIgKQDrFTwQw3By2zVDqtBRw682sU1lVzUuZDgwuK1OZ1CrgL2uOIPu0thzuXHSowG2dv(dVMQQDxqc21bvSTem(Nwfmo4NT1gMPHLc8ogPtWyXMR0SWujhWtOe8AcThY9g3ykDQgG49pAlbexQ5La(ogmbmCSPyIlWZF0J5xDC)dnv7XeREdoM4IV(M4y81V2)3XalU4RV5WI511h0AcdZXvxO9WI)t3ydlIC8w7NPAM85DkObyGytbdr8oRL5GwdN9uJ0EWWF0n4Yi2eVoAJ(sVJrOGJViBjoiBSr6Fsf3AhTyK2Jd(JFRfhqSinhxSHhjnEphSHZ4Hr0uktIA1CM1SyRNRvgSn0OrhkDBTzBMDtB2w)uFG2)AH5A)w7kMRv98NjqiH4jIio0wn8I(cud0gwrtv0mdBW8H56Rpp(9W1NVb87BBfS(Vn0LP37w03tb3E7)iB032XgdLN60CwtP7(SNP9CHFRAUqA9CHuFdAXCHeHitC8Z8vOb2EYskMIm3fr9uKhcwDwN)pxgQxG09srWptMwX92qDZYzaO67PmQN5)XxvUuIUVKoFnpUCCxPnKvNr0YvKeNoUEV1pqxKvuiMBWssewQNHj54DHLN6h6lrvflwUAf0GaHjc6stLC04xUbFEmwz6gsQuJzKvbKZU)wUVIajh35UMKdBuQRFYnwTUCJzt2cPgc7oB2NbhVuwZadnFyZj3kIn(k3YEiN1NlkBjwKUleI9Bqg7ikSXv0VNwSdeIb58y1dTwMA9vP7hbN6ae9eICFDZK)62O)Q9g7xREnBJ(XRVkSrxodbq)xVUIn7Ny7vSxyBvSp5BU9k237QQy4J7LxT8gf3M561eu2YHGztoI)hXelwEuHCHg5j0hpKy7fl(MxdMCYvze3U5Za9qFOwVk193kXCBJOn66gTCRgEfqhUDu1c6L9n8rx4OjM9yTNQ(9ERNQsI3)kgoFIsoiNpVEh0lJbu3RhVUjNe50ncLlsK74kvPC5ejNR44he64RuBZqftitRION3Ix7WwI18aTKc2)CfhiiN3jec1Ek43)TbuqB0FrMANpsU94oaC1NBF0R(xrx0GC8rsoXZxKpFEXCweQhUNlr2UMYQIjzppZMEeLCdvSZVvNpBSDc64m57ZA8chTWmIZ1(4H6huBYSXERcD8nRJoEHqb841l5IpY5xxGa0tXo3KDMCGb82VB)KZJbp0JmepET3dYEp7HDsmaJb27PJDgc5gKZzHDeU4ud6n2CEMjL7leV94IF41qCH7kM68gZq3093ffJaTnNtdr6tQ9fEqV7M(n9JaroO9i1YtmxOdJ)FSfoECPNeJn8LYXjsWwmlVZ3GRnEgZtalRsBlStyWPGLqCYdGp0kKpifq5Mg(BPd0MZQ42HdA6ykEf2bgiZmlvpWIVx2bw8SuSr1Zlq2hIfVWBUnOL7)QbTCjApS2NSfVbJeHCQftGpmsw9JBrcBn5ig2Wzaaaino(Cg0Y0bztzY(68pB7VyNgKwScT(hH(zO5XnQ(9MjSIiVkauzV9QF6uAyV)sMvGSAHq8gNBIyhV(VoEkk0IwSga()La)aIEqi)JDoIvvIeBu5YLk6oVbWd40kKfeev5IhDYOC4VIn6RIh(fQFKHFA8RWfHBIyr242aXh9lrJBFK9bYE6PPIKDKjOFpXAAJUazU)bOMBPp2wyTffm0ybho6gkMppSJ0DcaUvVoJKbhnyKyX3qbhS)g(MC0xlkjEQM7xD0rR6nPgj4ybBU2PF3u8r3UpbgOvnPthKJ85nzdnj)0UHFp0M0GRRK2ONf)k969k(n)bkdra0Vj9d4czVd1tXEe6ryPd18zKl(XW)eAyidZA5BteC6Cq1soKA)g79T3hsT439gpxAlL2Rra5HfeMBMwCU02JjxFNW)jC3ZS30Z8p8
```
