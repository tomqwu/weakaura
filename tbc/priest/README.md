# Priest — All Specs HUD (v5)

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
not get two numbers), icons desaturate while the spell is down, the strip dims to
50% alpha out of combat, mouseover shows the real tooltip, and the row
auto-collapses gaps left by icons your spec never loads. Nine cooldowns in fixed
order: Mind Blast and Shadow Word: Death (Shadow gated, both with a violet ready
glow; SW:D's glow is suppressed below 50% health because of the backlash),
Shadowfiend, Prayer of Mending, Inner Focus, Power Infusion, Pain Suppression,
Lightwell and Fear Ward. Mind Flay, Smite, Circle of Healing and the rest of the
filler are deliberately absent — they have no cooldown to watch, so an icon for
them would not change which button you press next.

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
(sha256 `1e1e6f0cad26e4a7e3bc8d7c09f20625aaa31f9debc923937be68a371f629333`,
8537 characters, 40 auras). When editing, never remove or reorder existing
`W.uid()` call sites — append new auras after all existing ones — so re-imports
offer "Update" instead of duplicating the pack. (v2 does exactly that: Renew is
built at the end of the script and re-parented into the Buffs row, so all 27
v1 auras keep their UIDs. v3 adds no auras at all — it only sets load fields — so
all 29 UIDs are untouched and it imports as a clean Update over v2. v4 builds its
ten PvP auras at the very bottom of the script and re-parents them into the
Alerts column and the new PvP column afterwards, so all 29 v3 UIDs are again
untouched: `changed=0`, `stable=28`, `parentSame=true`. v5 adds exactly one aura,
Enemy Mana, below all of them, and otherwise only edits conditions and load
fields: `changed=0`, `stable=38`, `parentSame=true`.) The script
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

## Import string (v5)

```
!WA:2!TZ3A0TXX19N1Wkrg2owIws2IXYgMXswsXsbaeGaqwY14fjHeia4cqjrz3qSa7qSR4IDxT7cscLMhIjXrrnjnMPXN283nrHoXnnVAoSjUPT)7PnQjU9Kt)W9W2MSTnPnvT1N00(HgDs)ENz2fVibaFisBfL(boCX8ANh)U)MzU37omNUNIx9XV8JSubUItXRPOgvrsr7KoC4iJd3h1VApfvKn0uKKq8rfeL41qYh7gz0er6gUoIRHrCsgclv)3JWjZ1i1CcAioJRxqrJhPfXU(v3rejXlEronEx5uuKmev1Mn9KtQJmykOYHREd19yxd5IefxlHLKCLvfvuVGvfjOv1k)xybnujrf5CvvrSL0uQOUGvoYkEr02wuuEsfTYCg4C4CrReS6BmmmowIRIHGIwAvsY6olG7LtkwYPgxrAedWQBWPz4SWKIYI6coJG)NHZ5m0elvcPPN6aA2p(crmiVDUkACEVgjuxfjjjYR3BpUJubxOcQsCvrAZrJpbVUZRRxPaAAC3mBLjNuC2fNiA4S5MiBUWS5QNugneoj2SzINm5nQOJIplUDL1QgYZkZvgP7CbEubCnq68AdhpzMbhl58vKTBwoxKxu)8vKX9MPrE5KKu3jh95CwPpIcp6R8MShUIZxcPUZSxOcE031GvWd3Nrq0aDnRuTgRVR55KfTgmha29GxdXPJYAGNTkzi8wGEJiRiJwIh3)j5ycYyIMocpOYRphjRKwj4jszor5bb34caEaVq)Gp8)3ZYJzEDK0KzueLnkenEQCXz7tKxTN6OkwKUsfTIi9BGZbstMt604xg(1(mloPgEOb3S4m4CCdo5I4z4bjrrE9fYgLnE8ulyOuCAR8V9m72Bfr(f9PCEEFb9iCWz8XQxKtc5yb8eblfBPxd6Kqgpk4ybsxs0cZersHJ35IwVgAZfcCz3lOJbXtDgrEdHDVGio7zPn2h6nbBNbUNF4BcIdbwIMhwfd6OfJ6oB53K5MiHhlx6iKIlap476aWEFb8a0(axWJYsbifSe8Wr9WWJ4Comezccylp0h82H97eoa84WbD2C5GKQ7AmCwCfvGJGYrAI6gIf1TRci1YklCi4WW7aJrinIjkwJuWbe6zGbGaZvGZwAkZD6(OE8tcdeKe61Vdm0uNZGagqcxJ23SarJZaHp2EGExKiOGRGjW)D59O2JbAwJj0f44vM5S2ubZtJJeOUJ9JbtfXDAbAFE)7xDhnvGgI0x3k2Ayh4KQ3pngSKUcb5wKoPejm(N3GMawedXtJ8slznloU9B)A00pFf8i0KvHalOrMAq5Wrgjv6uXHE1WaesEwGMXgJown7jXuMQ7yqnXl6A0kC8e4ORC5uDxVpnHfZ0eT0XMGhvelIjnHQg(bDkYO5HMAnULOXndgvEgno15oJ9dlv)vtPespwUKjsf3ESQjq6IjsLko7eSjgA4CQhAvAsysvzEQ4m7KskkAwdmtJBDfKq5B8kjmU71EqS2uO6(xLk3kYcPQuUasBAO35XdQwcBlz9p7MTxmmPwmk2tq2)SyJzF7yQ12SfBNaHj3GJu7x642PJcciXscg7dID65jsofL401ZxWal5lBSh2YvWlk5KLg7bkOlkxscvidBI4zZbVV9aZLpcMlV4EG3NZiKQJ8W1PG8i4YZtKE9gowm1DGR6W8emeIhXpc3ScWDbbTOhI2qCQhNlpNIyz(7vZwebUFNnlbDwM5PYJ6I8iw6ui8oj8XlNt1)QZYc7cxqNWECcpGZfPVIHPdlNqJmJvrdXgvcXjZYjPkW5WQrKZkf1dMGW8ojxr0ZgLdlKixkcN2ZowIJ04xhjlLtJwmb4eyUwmlo4iYfvukZahZb7mebVVJt4jHJdp1IPLgnBv(cQLMjOMOmHGgjy3Qe55rYSPIF64SlQGxeq2IMCHHtZM4CPtLlCsi6HpaBrbuXPge272MBAonromgyor5OkLlWzWonNufetFkQ9DItOvuGtUesV3daxLUfN5uX7kbPzufE(da)o4AWb8zwQfKkC1(85gx6Eoo85if7KKYfIs851k0bSamkSdN3GSlQsuPM6etKmJxyagC3Wq2ld8)NHSmammdKaojCkBo(xPbxnBgLzqAeU55vjprKazAHMEjcYTEA5BlJpKE1y3HmntQdJEslgC64c5Xq4EgRaK1M4gYD59aJXaN(g14KPTG9VF4SuHqyCC35CWZap7LGFvg4DHRYjG84YXbfSErfbEysg1d2jQbA91eTdidLabqeopmfibk5vFSUxuR4aDqDVWfyuFNDp3RKYfZdbgqfyAyggywREv18WfHJaVBhWVgH0aEp5H3lrShE)haUemNfRa8bOr9bPHFi45GpmvGhUCn5C4JGLRHRGLOHFDg4JcFSnfrx4JFc43a(eWZ7aMh(KWVzdzT7e(uebn4fQlKfmLVjfdigVuHCWVLa8BdFA4)h8Iq0ETW9Bd(mWNfUQTCIfuNIeWG7NhdUHpFhGZV4DSC4CQMbIlyqphaz3hyswTsidmq86e8BJeYtqPjv3H1rgCLv0OcvkNcBxZy2GKG(BpK9A736TPw0OoEv9jwb8OEMAd2O9WB1hTlvsD44kKbAgx3MLkBufTimqr1yXGvhMojgMs3yizrkHUdyNMfZ0AunVx1PvZphUfyuTmNCEVgi58lymdwCP6K4dpGxJK(CEWt(BjG4BBfq8lGgPS)Csxi55I0ce)W1P2NV(ilMwpaHwVVNYgSFs6zEhGe4HYOxVqSCLWS6WvD0SSrNxgOzjLhbyQFAA4ooV6ERFqMS0T15ISboxzWNms9bQN0P5kRkQjweFe5kffAQm1tiE5c4TXJQFw5J46miUPqYiEx4tCiPE)1JpHSmsZ1GIAOR30zOKrZaVz4TqKFVlWjC3cW9Cpm4jV3kCFBJ0d2PfMcpNINmBEYOUS9BdEi8HCRTcdzbhIS6JLVnRY8eyy5rVRnoyalNJNUB08JGp4RoHaap3tM3j4b8KV6qUnsWh23HMDi4PDaHDcrCarDcXCs4NU8BNsyH7r3dD53LkQOiHNaKZoJiEf0Rv7NKJdl0AxMS68lB1L)sE9hmKx)H85nua3EdfYBeVbgiaRh34yPH9td9X61F)44jHb1W1AAzjSCZ(GVwBgS0gom7i4ZVVrwap0ZCJPqi1WK9KAWs4mfO0IykWWh77VujjLzgudDHki5IvTikJqIt4AyQHHKSp)KW8K4YAD2xYJjPhSF3lsEU25oO5PXoxPPvBV(wNiIed9nMtqS4uYiDDhZr)jM7APcvmmuKtJ3ANexvADLueNLDsFFrS0SZLVFkvDF7xDDUHIgKPxZ64nrsNlx6ra19zrxojLUSTuLJcXMgtvsxpIQKMPKXtx1wH)dScAZfAKPTF8lyVE)9cNclg9DHT)e3jgh6lAA3NsyGr8m1OSnDY5pfD1P5QHZYxNg7ptDx1IKSd7yI6KTVYNNW49cJcNkprgeZMzj)qekichyzeB5NLfZEwrmezKMOaVoAwmjcD91CILrWv7XdHx7428A5Hfika5OEokzQznU3GJ5y5YxWFzE4VQZcshJTFFH84Jgoanma830jje4VDJjBa)DnlnaFFlja4hiaMcWFVd4Fy3W)id8dTMF(ryym8pb)ZoGFm8VaxFNW)6MbGe(3whOq4FVZap412(LlSC8MedgVfz2tD(eUp9mx4qEHFsZyn4)Obi7ph(PBzak4)eJH6Fzyi4)ARc60lRh)EdoW)hCzvGlp5RSC4YrWOfK(ffYQjWp(HgSZOLV9TbOLABsjYabcg8xYrkQ9qwFtwXyLRXD9wJLSOwhpxBRRZf(COeJn6S(NE8l0zK012QrsEEDdjDr8E)cgjGhVb9oGBVr8429a4n7fYVhAOx8M981VNUTH4BsG2jVzaA6BCGwaq9rTaABsW2hyTaBxl6zPoE8dHHJde4CNMDQdnAbuWodh)l20HJ9UvTm33ZRN(dfza3b8rc8tcgGeeGeeKG58gGgA9CiYHn84hh61RhAO3USc5J)ljRq(ZRHH(FwBeB0nunZydL4KJn0PlpM)oJK(oB1eBEVji2ChPe(uN9nwg4oUI6BBzQCGOIjxJKiB2ePgALjkIK5DLrtPSQH6UQN4GC8OAX6QESXq4foi25dhfXm31YXoRNJOrDLoLRrIR2BJQkEywxNjmBS6THhSHdeeoBwxXsqS8TRuPpttnGSjsgpv04KyPkUGif9TPsrwQQGyQHIO79MvxflIpWwLYYzjvMLoglyDwswojXsYqanDdoIj0zi6xiMZM0UJMLjYr5PAu5PDmhEgWUEUBbQoqU3RXxvMRSyrQ3ka332IOROzaEMVKMOLLiV75ipsoWCFSXyLellAC3eT4LK8KW1lQiJF9YgdYv0qrRaB4yjglBbnoEXk6FW7bo6DnpNwrRdVJX12i1goKryjKMH(ctwrskQOwrjCt1sdkZPvZy0evMSDPBcD1GfeI6KGcX7pqktw9CX1L9v6Ypgmet3z(s16g89fO)LWJMffq6zfuMjT8s60)nIOoXMCRj9o1kF1HBWxrOLmZd)y2mIZIKAWA1Wy2E8t5V(b5jSAygmk7v35BEo7DKBXRqzDwGAFrQrOYV8DN3QYdmzoaXNniElsc8SS6J3WeBKFR)S0DOzBky7)rKJjkW7PwupS7qNDm9tDq5HwoHvDTLAYCVDGXc3TkOQH0rgGpnI7AKUIbEA1KX7I6sI8OckggkLNRM7D4LuVKP72qSD5Dmp1fkOQ8r3qJJysrQILWVJIv0X1tbAgQsAE(aFMm9BfXS0imz83Jh45zOgMLgF(EQYFx9mlZ8udrsQ35QvVK3(s4NL1LiMNhNK6oRLwUArJBAuBLvpF5P1nT2YBX760M0C1XOKvNFTAlzQU7wSLKcLjurRNJFTMJVp)UXRT(fi4vQLEBXau5HxUvZ6b)UnzkVlVtwCRU4uriUWG6ojfUesgPjw0sIi)sT8ZfTeqyrC8vPMoKczsXvgT9N7sqVS0FA7li7nQTcNim2LWZ96Uoi1bJoK1jfWuDkAiLPrAy6iu(LWWcPS1QUfBALILQR3mskuZ4qA)w9M5Th4lovE17N8mI4itnN91JWQjZrQlPssYpvqTF)o2mKunzo6kKqXJATkHAY8oB223DwWKmYyjzoEqPGb9eIB8zl3fjZ3ANLmXsHuPelbstgIiIjZaDwa0KjGjtqsbdzYCSgIzMmpzlIyMmhVMSLjZjmzEksDzY8RyY8003v48Mmr2qsiVAnjKLAyKp1IygWVkEVOym(VFE4pTVaUXyf1EAyNRAYpeZXKe(6nz5pQOGjZGMmdzYmmUzLWK5KeeUjZP(8pgPNM0cwBYmIjtkCgshHSFftMrxgG0KHfNA2noUJUcHp)2MiADc7Eb4B2wdX1eyKcdFnCNIAwo4vYd)H5HVvE4pkp8hNh(tOwERz04rApASmxjXItiHfRre3PG4tmIsgvTGKr5h88jo7SH9LXtxGK33TNqs4L6ZhHqEe6giWGrm(GGnsL3IGTfh)iV6EA1LLAWXVgGMBFGCTfBQUJLVT5TaGQLLWP7lDRIEe39wj94bApGuqrQ6e4LzWJDw21NIeZosQW(lFXszL47csCh)ccsCnC6EYECNMcfBARRKz9KQ7ik(4c8UIw3DRjGZ1YzV7invx2i7M0XWF0v9y4JB5icDG4RXjWpaMNJL493Cn43SWikfdpS7mZKoCUz7cgzN1WiJFRjg5tx)O9lA7q9uxI(QrYMBSuT4ublBQBHB0WuCuJVwVImzkcxDjs5NyK4rhoCQer7AfzYGATSriheFfo0qalMJ2vGLifO9VSvPKArtNAWXYgFfLXh1lZ8BZt1M2iB605wrP6N(6A)BYwpbRCOii9T4TTDSmHJMyWX3ifvDhzJoC60jNibXt1zhltUvP4RRLTE56MWOFFdyY8omzEIvr)YDE1Oh8712vJMFqeNMRZWPXVfTkKpQNzTo3K(42RcH5n6UnUW9QA8hMmCTU5OhRlRfHMTOIwrrD7dqhqDGmNoJ34jo357cltp3IZYS(2tuDRAmGpIXm86M1NFF9hK1BGb8eIeH3i(9hkel(Pabxf9i3zy37DM2c7wCeo8zoJjsMs2iaV1YcG1L72Qw)BFRL1)wB4y8WuhXXDqxqCAf5Kr496RRZthhTGY97jI7kJFHrgoEMUaLV)B7GY2MXicXh0RHwT2zFli1xTj44sHPFUxUgJ6WneahgzQLvucjxS(PhRTfncQKaDp12p(7BdJlxn9wCRhWe3z7iW8WDvxiILvvf40r6cItAytZYfp5SL4qXdy0fS5U(feSPBtM7bEr4o(019cZOXi2WquM3vejmmuDFnhFZ(7zmeNHqDh(SPKPQoQ1YzBAfLjDnconr5sTwoB)7uPyf96gzXQCenmItEYkeVxw9HAjnorzxzROsu7ln1D3CQjjAqDg8uzRrxFNc1naZtCNnzbgtMDFx3SMFXKzp18SBtMhKeS3vAOftMEfSTXIjZBRH1vmzEi4(2MjZ(apMmp8DBY8i9XgZKXf(PhvWKPptM3UjZJrTtIjZ(ByGKM(4cRPwuDtMhVMXrmzoOLzry2uSkIprUXMKBOyLdnmHDBTyq4LT66cef9gwAgUQ61wL9rEX2Uk7cnWIDDr2BslbV(vwRWACFGHxto60YnLYvi2DX(RloVfZdBj(yXJpTGrXX6OjDnzUe8tfOmpH3SSP7XQFCHfuKRHUwMJKtSTlBthR4tSmJ7UoT97Aauj3UTS9rRVLT3D71BvpnXGDmlkS1dQAKoHQ2srF)3o(IVEG4mz(42iTaXsj4Dm3fhp3uDbPn3Mos7KTIGUzqyVeC1(838x8MqJ0FlBoiW3vxrGe7v1geOjtMxNOXwZo0YnnsA5gzQjK04rUW4bZDi)kJY1fK0hythjD41gsABVEGeUKV2ZfTZvSROFXcz8cDWqq)88wEQuD1V)AKHGoHq0fIFMyjrdACOGDbH8bVTgHe6Z2Efm00(IVTJ0a3N74YpLgptaprsZPW3fiXh62AiXJNSTqIR36jIUTdvG72DcvCboUdEi)YJ6FWX7cQ45U9EPKxPdMJD5hg(2oGXLELocmMvvnKXyA6JkFXUam(W3odmIDK2ByK6Ab52n8aUd3j4qmVtBOhYyOcNC4UahU8T18eDWqzMmk32rmyB9S2HekKy4boTKBLdwowxqcFKBLrcu9Z(XG7O3M(A4hwrQkXNhlQxxjME2Q0HzKKXhmxxvJz(nt1y247JN2)ANgm)rBkAWu(8Nnye(uPJHgCT60lVmvNLrLuKr65TgnpmB)97XVh2(9fWVVnG7CFlHfa37QAOLWBGpeftMpNTgaQo(zyngx195oBxec)S1SxYYecPM6kKL9sitJeRCCIfOE(CMks6ilBJqnlIhcC8jT))XZtn5HFVuqAK8Tt4TP62kNbXvFpvz6z2F26Y(j0prLZx3odhXvonr5PqgUIL(mPu7RXTBHOKe5W(gci8z600j31fw5PXnGrCzu5Q1QGMK5hlSlfzY9iz1M00)ivPFBkvAoJwva5sSSTFIjyYH7DtJCWK5bE9JA4AnOgMot7ig43C(IpcnALc6bhC2O6NETWm8TEZ3b5EVAorduzQFQN4Rrg8iljdjvFW24J6jW58qnCBt8c3x3YR3RL3Rr9ED76dl(gH8Cd9m)kMmlU9eVuJ3IjZFqlvNjZ3WK5BMNGUFLLvSP)yBSIDLnuX(K)KnwX(pwxfdoKxo5QlNDn)wX2rwZ(byZMz(RBXdwnjFXidFk1rJG6cp4xAtFZiRtx7Cf7P8BuBpLp8t3(ZEUR2XRTU9hMTK5R1M7bG7yDzERKAvFdDWlEW0tFOUmV9LFJEEJ4D4j1SVIE7L1NxVH8Ajg53RhVUj3DQ0p(fxeFlXv2kflIixvJW(WD5fR)bWKGpF785Kx32V)AsaBpTBwAGzkhimR3X4J0LzPVYB4ZsMmVu(6xEmU94oio0NBF0q)lQI0i3KCKlGZ54MCsurdYme8wVo57VtugLXk98D6wG4wApTE13NzIBcaWzNSFJrlDWstHMPlULZxT22mt8gea473aaCLib941ljWh5(2kyq6TULBY3nAWaEhWTFYNeVh6fZGhVMmFhtMVl9JHh35nzE1BcmWTEFP73mt8NmK3eZ4zQSUVqQUmX)12YM4B5AKKPD3IKVAtQu5lqN)u3fHXLCNMjQHOA0ph9gqTJFjL3Sx2PWxC9od(7TIRTu4lv7kjf(YmRTlVX14eAT7HrYC6BuxeJMm)(1Ujg)z2xeJsXsKuSALYUNuRLlIXR04oo49dxLng7yjITspM3h9Av0TVwVfgjLOWWJrVs4B5tcaN3bcqpVF)wFFERSCrgj8qXxrP85X6AdLm73MxMwMWjdhlrQvuUqd0WNMc0)klimxR9jYSYk6jzho8iHBTUzOnk6hfrWaTP9CMWSjth9uRO94N2f87H2Ec1AbnzIbxTpVRTlW4MU5k7PCp89WF5hU17Vsii8DPE)5vmz(CemN9Lij5cK8VE73AFbsIpp9kUZiRKZRwqXH45NzQ2CNr2JoB)h1)rD3Z03575)9p
```
