# Priest — All Specs HUD (v6)

One pack for Discipline, Holy and Shadow on TBC Anniversary (2.4.3 client,
WeakAuras internalVersion 45). Copy the whole string at the bottom of this file
(or the contents of `all-specs.txt`) → `/wa` → Import → paste. 40 auras: a
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
the health bar, the mana bar, the threat bar and Inner Fire.

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

**Known limit — threat while healing.** The threat bar and the Fade prompt measure
your threat on *your current target*. Holy and Discipline target friendly units, so
both stay hidden while you heal. WeakAuras' "At Least One Enemy" threat option
cannot fix this: the prototype's final hidden test is
`WeakAuras.UnitExistsFixed(unit, false)` and `UnitExists("none")` is false by
definition, so a `none` threat trigger never activates. A healer-facing aggro
warning needs a different mechanism (a boss-unit or nameplate scan) and is left for
a future version rather than shipped dead. Also note that WeakAuras deletes the
whole Threat Situation trigger on Classic-family clients that do not expose
`UnitDetailedThreatSituation` — if the threat bar never appears on your client,
that is why.

## Groups

**Resources** (`0, 56` — three 172×14 bars stacked flush). Health (green,
`y=-13`), mana (blue, `y=-27`) and threat versus your target (`y=-41`), each
with a floored percentage on the right edge and a 1px border. Health and mana
are always on and fade to 50% alpha out of combat (a second Unit Characteristics
trigger feeds the `inCombat` condition); the health bar turns red below 40%,
where the Desperate Prayer prompt fires. The threat bar carries a bare threat
trigger, so it exists only while you are on a hostile threat table and vanishes
by itself the moment you are not: it runs green, turns orange at 70% of the
tank's threat, and red the instant you actually have aggro. Since v5 it does not
load inside an **arena** at all (there is no threat table there); it still loads
in the open world, in dungeons, in every raid size and in battlegrounds.

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
| Threat bar | everywhere **except arena** (open world, party, all raid sizes, battleground) | arena has no threat table, so the bar could only ever be clutter there |
| Fade prompt | same, **and** in combat, **and** knows 586 Fade | its trigger is the threat bar's, so it was already unreachable in an arena — now it does not even load |

`lua5.1 tools/spec-preview.lua priest` lists the un-`spellknown`-gated PvP
elements in its UNGATED section: that tool models spec gates only and does not
know about instance-type gates, so read those as "every spec, but only in arena or
a battleground". The PvE ungated-by-spec count is still four — but one of the
four, the threat bar, is now gated by instance type instead.

Shadowform (15473) costs 31 Shadow points and Vampiric Touch (34914) costs 41, so
neither can coexist with a "not Shadowform" gate: the two shared slots at `x=-66`
and `x=-22` are single-occupancy for every possible 61-point build.

The four `not_spellknown` gates require **WeakAuras 5.4.0 or newer**. Older builds
ignore the field, so those elements load for everyone — the pre-v2 behaviour.

Ungated by spec (loaded for every priest, and the whole of the levelling HUD): the
health, mana and threat bars, and Inner Fire. Each is justified for all three
specs — mana is the resource every priest plans around, Inner Fire is maintained by
all three (Shadow applies it before entering form), the health bar is half of the
Desperate Prayer danger state, and the threat bar exists only while you are on a
hostile threat table, which includes a healer who keeps the boss targeted for
mouseover healing. Since v5 the threat bar carries one instance-type exclusion —
it does not load in an arena, where no threat table exists.

## Regenerating

```bash
cd tools/tbc-weakaura-creator/scripts && ./setup.sh   # once per machine
lua5.1 tbc/priest/generate.lua                        # rewrites all-specs.txt
```

The build is fully deterministic: fixed seed `20260815`, no clock or randomness
beyond it, so re-running produces a byte-identical `all-specs.txt`
(sha256 `babac6429ac14f1e2f53bf8814312b78c9e716f08227b9ca7f07e84fc4955c4d`,
8570 characters, 40 auras). When editing, never remove or reorder existing
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
`parentSame=true`.) The script
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

## Import string (v6)

```
!WA:2!TZ1A0TXX15SgwXsW2Xs0sYwkw2WmwYsowkaGaeaYsUgVijKabaxakjk7gIfyhIDfxS7QDxqsO08qmjokUjPXmn(0M6MOYK4MM3LTXn91PnQjU9Kt)X9W2MSTnPnvT1NK0(JgDs)FNz2fVibaFBlR0FWLlMDMzNzUF3V7mZ9UdZz6P4vF0R8qlwGR4K8AkQrvKu0oLdhoY4W9X8R2trfzdnfjjeFubrjEnK8XVrgnrKUHRJ6AieNKHWI1)9WCYCnEAobneNX1lOOXJ0Iyx)Q7mIK4LUeNgVRCkksgIQAZKEIj0rgmfu5WvVH6ETRHCrIIRLWssUYQIkQxWQIe0QAL)loVgQKOICUQQi2sAkvuN3khzfVeABlikpHIwzodCoCUG1dS6BmmmowKRIHGIwAvYJ1Dwa3lNqSKtnUI0e6Nv3GtZWzHjeLf1fCgb)pdNZAOjwQestp1H0SV9fIyqE7Cv048EnYvDvKKKiV((7XDKk4cvqvIRksBwA6j41DED9kfqtH7MzRmXeIZSW4rdNn34zZfMnx9hLrdHFeB2mXtM8gv0rXNb3UYAvd5zL5kJ0DoppQaUgiDETHINmZaJMCUkY2nlNlWlQFHkY4EZuiVCssQ7IJEFoRNpScp6l)MShUIZxcPURSxScE031avWd3Nvq0aDnRNAnwVJ54KfTgm7h2ZaxdXPJYAGLwLmeUdy)rKvKrlYJ7)KCmozmrthHhu51NLKvsRe8ePmNO8aGBCbapGxOpWh()7DPPmNosAImkIYgfIgpvU4S9kYR2tDuflsxPIwrK(nW5aPjZjDg8ld)AF6fMqdp0GBwCgCoUbNCrSeEassKxFHSrzJhp18gkfNYk)BpZE8wrKFbFkxG3xqpchEAFS6f5KqoMhliyPyl9AqNeY4rbhZt6sIwyMiskC8oxW61qBUqGR4EEDmiEYZkYBiSN5fXzplTX(aVjy7mWD9dEtqCiWI08WQyqhTyu3vl)MiBIeE0CPJqkUaC)VZdb77fWdqhaCbpmlfGuWsXdN0dcpKZzXqKXjGT8qVWBdoOt4qWJch2zZLdsQU7rXzXvubockhPjQBiwu3UkGulPSWrGhdE7ymcPrmEXAKcoGqpn0pey2cC2AtzUD3hZJFY1abjx963bgAQZzqadiHRr7BwGOXyGWhFVW(xGOOGRGXX)DL9Q2JbAgJX1f44vM(C2ubZrtJCrDNhedMkI70c0(8bpO6oBQanuPVUvQ1WoWPuVxAkynDfcYTivOejm(N3G(aSkgINM4Lx0skoM9B)A0NFHk4rOjQcbMxJiAq5Wjgjv6uXH9RHbiK8mpnJngDSA2tGPmv35aAIxY1iv44jWrx5YP6UEFAClMPXBPJnopQiwftACvn8n6uKrZdn1AClstBAmQ8SACQZEw7BwS(RMsjKE0CjtKkU9yvtG0fsKkvC2Xztm4q5upYk0KWKQY8u1z2jKuu0SgyMc36kiHY34vsyC3N9GynrO6bxHk3kXcPQuUasBky)ZHhuTu2w06F2nBVyysTuuSfq2)SydPVDk1AB2QTJJWKBWrR9lDC70rbbKyjbJdaXoZCenNIsC665lyG18Ln2lB5kyJsozPPEOc6IYLKqfYWMiE2CW7DVWS5JG5YlUx496mcP6i3CDkipcU88eTxVHJftDN4QompbdH4r8dZnJaSdiOf9q0gQt94CP5ueRZF3A2QiW96SznOZXmhvFuxKhXsfHW7GWhVuov)RmllSBCbDc71jCFoxG(kgIoSCsnIeRIgInQeItMLtsvGZHvJiN1tupCccZ7eCfrptuoSsICPiCApZOjoAJFD0SuonAXeGtI5AXS4GJixsrPmdCChSttu8(2oHNaob8KlKwAKSv5lOwA6GAIYecAKGDRsKNhjZMk(zIZUGc2iGSfn58dLMnX5tNkx4Kq0h7qSffqfNCayFBB2P40e5WyGzfLJQuUaNb7uCsvqm9QO27jpPwrbo5si99Fi4Q0P4mRkEwjinJQWZFi43gxdoGp9ITGuHR2Rp34s3ZjGFhsXofPCHOeFETU6aMhgb2PZBqMfvjQwtDIjsMXggGb2dmOTzG)mgIzayigibCk402C8VCdUA2mktJ0iCZZPsUJObY0cn9IeKB9NLVTm(q6vIDhY0mPomYPSyWPJlKBdH7zScqwBIBi3v2lmkdCMBuJtM2co4bHZrvcHXWDNZdpn8mxg(LzG3jUkhhYJlhhuW6fve4HjyupCNOgO1xt0oGmucear4cWKGeOKx9r6ErTsd0b19bxKr9D09CVCkxmpeyavGPGPzGzS6vvZdxcok8UCa)kesd4DNhEpe1E49Di4YWSwScW7NM0hGE9dcpl8HOk8WvQPNdFySEn8CynA4xLb(iWhDtr1f(yNe(1Gpo88oG5Gpb8R3qx72HpjrrdEH6kzbt5BcXaIXlvih8Bia)MWNc(TGxeIUFlC)2Gpn8zGRARNyb1Pibm4(5XGB4Z1b48lEBlfoNQzG48g01bqM9bMKvReYadeVob)24b5jO0KQ70AjdUYkAuHQLtHTRAmBqYL(ApK9Ah06TPw0OoEv9Xxg8OEMAd2O9WB1hUlvsD44Y0bAgx3gtLnQIwugOOASAWkdtNadtPtmKyKsO7a2PyXmTgvZ7vDk18ZIBbgvlZjN3Rbso)8gtJvxQobEXdyBK07ZdEYFtbeFBldIFr0WL9Nt6IjpFKwG4pwDQ95QpYIP1dqO179jTb7NIUM3(jx8qz0RxiwUsywD4QoAw3OZMbAwt5HaM6RMgUTlOUV6lKjlDADUitGZvg8kJuVV6p6mCLvf1elIxICLIcnvM6piE5c4PXJQVw5J66SiUjrYiEx4vCiPEV1tpHSmsZ1aIAOR30AOKrtdVz4oi6V7aCc3PaCx3fdw49wG7zBKEWUSWuyzkwy2SWOUU9BfEa8ICRzHHyWHOR(i5BJvMhhdlp2ow)GbSEowC3O5hbVWxDcbaw2tK7e8aw4RoOBJe8H9DKzgeEkhqyNqehquNqmNe(PR82Oew4E0Drn)UyrffjSaqo70IylOxR2pjlhwO1UmX68lz1L)IE9hmKx)H85nua3EdfYBeVb6paRh34uPx7JE1hRx)9HtNCnOgUwtllH1Boa8vBZGL2qHzhgV(91Jb8qp9nMeHudtMtQblHZuGslIPadF8V3ILKuMEan0fRGKlw1IOmcjnHRHPgguYE9tcZrslR1AFj3MKUW(9Sa5(AR7GMNgZCL(SAZ13AfrKuOVXCcIfNugPR7yw6pXCxlwOIHHICA8u7K4QsRRKI4SSl67lI1o7CL7Lsv37bvxJtOObz61SwEtK05YLEyq9aw0LtqPlBlv5iqSPWuLu7r0nPzszS4QMf(3)YOnNVrM2(jUOT9(7gonwn67aB)XVDmo0x00UpTq)d7zYryBALZFsQ1PzRHZYxNg7VqD31sKmd7yI6KPVYNNW49cJaNoprheZMzP)qukikhyDeB9NLKYExwkeDKMOaVoAgmjc1(AoXYi4Q94HWRDcBET8W8Kna5yEogr0SkNBWXDSu9l4Vop830zfPJZ2NVqE8rV2p9Aa4VRtAiWF)6t3a(hAwBa(EwAaW3xamfG)rhW)0EG)zg4hyjF(Hyym8Va)RoGFe8VbxFxW)(MbGe(pwdOq4)SZap4v3(vkSu8MedgVfzMtFHeUpZ0x8iEHFCZyn4N0aK9xc)0Tmaf8FHXq9Teme8FVvbD2pRh)Ed2))pCzfGlpXlVu4YrXOfK(LeYQjWp2rgOZOLV1TaOLAtsjs)bcg8xWrkQ9qSVjRySCBCxV1ujg1646AB1ox4ZJsm6iZ4FQXUyNrsxBRgj551mK0LWZ9lyKaE8g0B)U9gXJB39JNSxi)EOx9INSNV(80TjeVbbANAJa00x)aTaG6dBb02KGT33Qb2UA2NL64Xpigo2FGZFg2jpYifqb7mC8VAthoU)TkZCFxVE6luK(DhWh5IFYL(jxcqUeKG58gGE16(qKfB4Xp(QxVEOx92flKp6VGyH8Nxdd9)U6i2OtOA6rhmXPgDWZuEu)Dgj9T3Qj28Ubi2ChPeEvN9oAg42Eo136s2YbYwm5A4ezZMi1Gl)HIizExz0ukRAOU76pCaoEuTuDvp1yiSHdIF(WjrCZDTCSR65iAuxPt5A44Q7VrvfpmRRZgMnw92W93iaccNnRRyjiE(2vQ0NTPgq2ejJNkACsQ0nUGOf9TOArwBvbXvdfr39gDVkwaVGTkLLZsQmR9ySG1Ajz5Keljdb00n4iUqNHS)cXC20U7Oz5ICuE6oQ8uoMflbSRN7uGUhi3914RkZvwSinAfG7zBr0v0mapZvst0YtK35SKBjlyUx2ySsILfnUtYU4LKCNW1lQiJF9YgdWv0qrRaB4yjgnBbnoEXk6FG7co2oMJtRO1I3X4ABKAJaYiSesZqF(jQijfvuROeUPATdkZQvZz0KTmz7sBG9QbRie1jbfINFGuMS65IRl7R0vEeyqMUZ8LQ1j47lqFlIhnlkG0ZkOmDA5f1P)ByrDIp5wv77uR8vpwd(kcTKzE4hXMrCgKudwRgoZ2JFk)13ppHvdZGrzV6oFZZApJClEfkRZ8u)lsDcv(Lo78w38atMdrIzds0IKalLvF0gUyJ8B9NHodnBxbB)pIEmzd8EYf0d7o05gv)0hwEWLsyvF3snzU7oWyH7wfu1q6idWNgjCnsxXalwnz8UGUKipQGIHHs5zRfEhEj1lrC3gITRSZ5OHqbDlF0n04iUuKUXs43rXk646PandvjnpFGptM(SsygAcMm(7Xd88muhZstpFpv53rpZWmh1rKK6D2A1l5TVi(EzDjI75XpsDx1EwUAjJBAuFLvpF5P1nT2YBX760M0CLXOeRZVAntMQ7PfFjPqzcv065exR5071VBST1ppbVs90BloGkp8sT6wp43Tjx5DLDXIB1fNmcjegu3fPWLqYinXIwAe5xSLFUGLcclIJVk11HuitkUYOT)Sxg2pl9N2XcY(IAVHteg7syzVURdtdWOJyTsbmvNIgszkKgMocLFrmSqkBTQBHMSuSy99nJ8eQBCiTFREZC2d8fNmV69sUhrcKPMZ(Arz1K5O11ujpYpvrTp)o2m0unzo2Y0qXJATQHAY8oA233DwXKmYyPzowqPGb9eIBSzk3fnZ3sN1mXAHuTelfstgIkIjt)Dwb0KjGjtqsbdzYC8gQzMmprlQyMmNOMULjZjnzEssDzY8lzY8u03v48MmrwxAiVsnnKfB4Kp1IygWVcEUOym(xlp8N3Ba3ySIApn8Zvn9hI7yscF9M88hvvWKzatMbnzgc3SsyYCkcc3K50FUhH0ttAbRnzg2KjfodPJqMVIjZilbqAYWIFA21pUJAHWNFBxeTgHDVa8nARJ4AcmsHHVkUtrDlh8Y5H)O8W3mp8hNh(tYd)PupV1mA8OThnwMRKyXXLWQ1is4uqIjgrjJQwqYO8dCHeNBMW(Y4PlqY75wtij8z71hHqEy6eiWGrm(GGnsL3IGTLa)iV6EBnKLAWXVkGMBV)CTfBQUZLoT5TaGQLNWPZlDRIEe39wo94HApGuqrQ64yZm4Xol)6trIzhovy)LVuPSs8DbjUZ3GGexfRUNmh3POqXMM6krQNuDNrXlxG3v06HBnbCUAw7DhPP6Yez3Kwg(dVIldFmRarOdeFnwb(HW8CSKO)MRb)MfgrPy4HCNz60HZntxWi7QggzSBoXiFQ6lTFb7aQNgs0xns2CJMQLGkyjIU5VrdxXrD(A9kYKPiC1fjLF8HJhDOWPseTRvKjdQ1YgHSq8LfqdbSyoAxbwKuG2)YwHsQfnDQbgnB8LvgF0OmZVnpvBAJSPtNBzLQp6RR9Vj79jy5dfbPVfVTTJLjC0edm26POQ7mB0HsNo54jirQo7OzYTcfFnz26LQ7cJ(81VjZB3K5XxH9xUZwJU)VBBTgn3aionxNLtJFlYkKpAKzTgNK(y2wHW8gD3hx4Evn(dtgUwNC0J0fBrOzkQOvuu3Eb0bu7pZzY4nEIZFHUWY0Zn5SmRT5ev3Rg97J4mdVUz953xFbz9gOFpHij4nIF)HcXIVlqWvyFK7mS79mDBHDlmmhEnNXejIK1dWB1yaSUE3wL9VdSAS)T6WX4HPoIJ7WEbXPvKtgHNRVUopDC0ck3NNiURm2fhEO4z6cu(EVLdkB7gJiKyqVgA1AM9TGuFLMGJlgM(5E5AuAa3qaCyKPwwrjKCX6RES2u0iOsc090B)eV31nUCL23IB(aM4oBhbMpwx3leXYQQcC6iDbXjmSPz5INCMsCO4bm6c2C3VbbB62K5UGxeUTpv9OWmAmIpmeL5DfrcddvpqZP3C8EgdXziupGpB6X0ToQ1Yz7AfLjCnm(zIYLATC2X3PsXk61DYIv5i7Wi(XtuHe9YQpqlpJtu2v2kQKT9L(0908tts2b1PXIYwtU(mfQ7aMh)2BYdmMm7zhBu3VyYS3Ar2TjZ9tUSVL7OftM9ly7JftM3AdVRyY8aW9SntMdaEmzEW70K5H6LnMjJl8DpSGjtVMmVntMhH6NetMd2Wbjn9XfwBBr1nzE0AohXK5WwUfHztXRi(e5gDcUbJvo0qe2TvJdHxI115jB0ByPP5QQxZk7d9IT1k78nWID1i7g0tWR9nRvyvopWWRQaDAPUs55i(DX(RloVfZdBj(yXJpLGrXr7OlDnzUm8tfOmpH3S8P7PQVCH5vKRHUwsGKt8TlBtlR4JVeN7UA99BNZIaPgAyrDLWCYTBgDFK6ZO7D1(T1QNMi4oUfd3Ab0nCNaDBPGZ)hhFHxlaKMmFmBGyGyPe8oQ7IJLBYUaeNDthiE(wbyBea4NfUAV(B(dItOXZVJvgGEhBCaABifVUL3VQRIzdwjE(QnGvtMmVgriUQdnMnmOBPURQjq3yrU4ybZDe)kJW1fq37Fth0TgInQ1NuVjAPl7R90s7AzZF61rtHlFDPRbINxOdop6NN3k6MQVL9VkzWOtybDH4Nnws0aghjyxWcFGTqlHBycOTElGTfQ9jQb1c9zA)EA00uXVLJDb3N7OjTsJLjGNiP5u47cI6d(gr2L6I8hnzBf5xV1fzDlNuh3T7Ku)ICCh(i(LhX)aJ1fP(Z(gAP(LF5o4b3LU(5B5e8x(L7OGFgv1qgJQPpI8L6IG)d9gzbFSJ2EFLuFJrUvtEJ7WDsChZ7ug6HmgSWPgQlI7R8gA98o4BmtgLB5uSTDyw7K0fsmu)NrYTYHlhRls6p8RNsA6wU(rHBB)n9bUpKIuvsymwuV((s6zRABjJKm(a566otMFZCNjB8jVt7FTBtj)HBkBkP8foxWi8PshdnWQnowEj62qgvsrgPN3A08Xy7Rpp(9W2NVa(9ToIq7BkCQ3(wrFNeED8TLyYmV9sXRo2zzngt195pxxuYUAnxGSeLmQ3Rcz5ceIyK44ItopnyMZurshz5UdQNo8qGJpH9)prEQxm87LcsJKVDkNnv3w5miU67PktpZ8ZwtUeH(vNCH6Uo4OUYPjkpjYWvS0NnLAVnoWkeLKiRk3qaHxZKMo54RWkpnoulIlJkxTwf0Ko)OHDPitoAiR20M3pCv6NBsLMZOvfqoxkB7xncMC4U30ihmzUVx7OgUwdQHPY0oIb(nNpIJqJuPGEWbMjQ(zwnmdFZ38TrokRMv0avMg65j(QKbpIjxiP693MWopboNhPrKyAzy(A0Gq3UoWQSri33y)GFztM)GTN4Z2OMnz(dxAvyY8nYtq0V8sk2uF01xXEU1vX(e)41xX(jRPIbhXlNC1LYOMFRykgR6W5RzVf)7BX9vnjFXidDA1rIG6c33xAtFcgRXi0SZZt8bFQ2VEWD3oUS1CyTSLiVwDE5h3X6ICRKAvFdE4lD40tDKUi3(YVEl3ib5Dsn7tA39Z6ZR3qETuJ871Jx3KJav63WIlsiIGx9EXIiYjUiCaCxEH6Fhlj4Z3Uqh51S5WVQuW2B7Ks9pD5aHz9okFKUiL(kVUlLmz(C5RFgW42J7G4R(C7JE1)cQinYbch5C0CwUjMav0GiHG3Y1jFgDIYOmwppFNomhUPoGPx55wMydaao3e9zmsPdxAs00Dj6A(Q1MAzIxNaaFVgaGNlsqpE9sU4JCSzfmi9WZYn5Z)myaV972p5lB3d98vWJxtMVTjZ3H(nTJ78MmVYgadCZ3hS(grWFQqEtmTNjZ6(IP6IG)RTLj4B50GKPDhgKVstBtYNNk)u3nHXLC0KjQHO7IEo6bzAh)Gi3ONzPWxyTkb)9w2Ppk8fRDYIcFjMv3zW4QuGw74uKitF968u0K5Rx7av8NzFEkkflrsXQvk7EcTwopfFUghvbVp4QSXyhnrSLh47(ONoIU916HPiPefgAu6j7Elr2poV9hGUg)(S(m7wE5ImC4bJVSs5ZJ1P)jr63MxMwMWjdhlrQLvUq93i0Kc03YlimBR9jIuzz9KSdfE4WTw3m0gf9BBiyG20EoBy2KPJE6L1E8t7c(9qBpHATGMmXGR2R3v35qCthaL9uUh(E4VYd26Xqjee(o0G485mzMNG5SplijNdK)TB)M7Zbs8AOx2r)yLCE1ckoip)0t2MJ(XE0z77y(pM7EM62F3)F)
```
