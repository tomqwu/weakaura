# Priest — All Specs HUD (v4)

One pack for Discipline, Holy and Shadow on TBC Anniversary (2.4.3 client,
WeakAuras internalVersion 45). Copy the whole string at the bottom of this file
(or the contents of `all-specs.txt`) → `/wa` → Import → paste. 39 auras: a
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
they keep loading in arena too, because the "hide PvE furniture in a PvP
instance" gate would have had to touch PvE auras, and its behaviour outside
instances is unproven (WeakAuras only assigns the instance-size value inside an
instance, so that gate can silently unload a bar everywhere in the open world).

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
| **CC ON ME** (red) | any loss-of-control effect is on you — stun, fear, polymorph, root, sap, or a school lockout | the icon *is* the effect and the number is the time left: this is the "ride it or trinket it" call, next to the trinket read-out that says whether you even can. It is the only element that can show a Kick/Counterspell school lockout, because a lockout is not an aura and no aura trigger can see one. Not combat-gated — the opener lands before you are in combat |
| **FEAR WARD MISSING** (blue) | Fear Ward is not on you **and** off cooldown | re-ward now. Fear Ward is eaten by the first fear, so this is a live state in every game, not a pre-pull constant; while it is showing, the next fear costs you the trinket |
| **MASS DISPEL NOW** (gold) | your target gains Divine Shield, Ice Block or Blessing of Protection **and** Mass Dispel is up | the priest is the only class that can answer an immunity, so this is a press, not a stop sign. The number counts the bubble down: dispel it, or your team burns the kill window into nothing |
| **SILENCE NOW** (violet, Shadow) | your target is casting **and** Silence is genuinely castable | press Silence. The second condition is the point: "Spell Usable" folds cooldown, mana and range into one boolean, so the prompt never nags while Silence is down. There is deliberately no spell filter — WeakAuras disables the "interruptible" option on TBC clients entirely, so no HUD on this client can tell you whether a cast can be kicked |

Five state read-outs live in the new **Priest - PvP** column (`150, 96`), which
mirrors the Alerts column on the other side of the character. State read-outs do
not glow — in this pack a glow means "press something".

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
- **Enemy healer mana** (the Mana Burn scoreboard) — the Power trigger's support
  for arena unit ids is unverified, and a mana bar that silently reads nothing is
  worse than no mana bar.
- **Hiding the threat bar in arena** — it would mean editing a PvE aura's load
  gate on unproven behaviour. It stays as it is.

### One thing to smoke-test

The **CC ON ME** prompt is built on WeakAuras' Crowd Controlled trigger, which
reads the client's loss-of-control API. That trigger did not exist on Classic
clients until WeakAuras 5.2.0 and is registered on TBC by current builds, but
whether the 2.5.x client actually populates that API cannot be proven from
addon source. Duel a friend, get sapped and kicked, and confirm the prompt
fires. If it never appears, that is why — and the fallback (a hand-listed set of
CC spell ids) would lose school lockouts entirely, so it is not shipped
alongside; two prompts for one event is worse than one that needs a check.

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
tank's threat, and red the instant you actually have aggro.

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
your target at 70%+ and Fade ready — the only threat dump a priest has), and
Desperate Prayer (green, health below 40% and the racial ready). Inside an arena
or battleground the same column also carries the four 44×44 PvP prompts (CC ON
ME, Fear Ward missing, Mass Dispel, Silence) described under **v4** above; they
do not exist anywhere else.

**PvP** (`150, 96` — dynamic group growing upward, mirroring Alerts on the other
side; 32–36px icon timers, arena/battleground only). Five state read-outs, none
of them glowing, each one collapsing out of the stack when its state ends: your
trinket while it is down, Will of the Forsaken while it is down (Forsaken only),
one 2-minute clock per opponent who trinketed, one red icon per team-mate
carrying Unstable Affliction, and one icon per opponent sitting in your own
Psychic Scream / Mind Control / Silence. The last three are clone rows, which is
why this group is a dynamic group: clones inside a static group would all stack
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
| Fear Ward MISSING prompt | arena/BG **and** knows 6346 Fear Ward | any priest ≥ 20 |
| MASS DISPEL NOW prompt | arena/BG **and** knows 32375 Mass Dispel | any priest at 70 |
| SILENCE NOW prompt | arena/BG **and** knows 15487 Silence | Shadow builds that took Silence |
| Trinket DOWN | arena **or** battleground | every priest |
| Will of the Forsaken DOWN | arena/BG **and** knows 7744 | Forsaken only |
| Enemy Trinket clock | **arena only** | reads `arena1..arena5`, which do not exist in a battleground |
| UA on Ally clones | **arena only** | party-sized by definition; a 40-man BG would be a wall of icons |
| My CC Out clones | **arena only** | reads `arena1..arena5` |

`lua5.1 tools/spec-preview.lua priest` lists the four un-`spellknown`-gated PvP
elements in its UNGATED section: that tool models spec gates only and does not
know about instance-type gates, so read those four as "every spec, but only in
arena or a battleground". The PvE ungated count is still four.

Shadowform (15473) costs 31 Shadow points and Vampiric Touch (34914) costs 41, so
neither can coexist with a "not Shadowform" gate: the two shared slots at `x=-66`
and `x=-22` are single-occupancy for every possible 61-point build.

The four `not_spellknown` gates require **WeakAuras 5.4.0 or newer**. Older builds
ignore the field, so those elements load for everyone — the pre-v2 behaviour.

Ungated (always loaded for every priest, and the whole of the levelling HUD): the
health, mana and threat bars, and Inner Fire. Each is justified for all three
specs — mana is the resource every priest plans around, Inner Fire is maintained by
all three (Shadow applies it before entering form), the health bar is half of the
Desperate Prayer danger state, and the threat bar exists only while you are on a
hostile threat table, which includes a healer who keeps the boss targeted for
mouseover healing.

## Regenerating

```bash
cd tools/tbc-weakaura-creator/scripts && ./setup.sh   # once per machine
lua5.1 tbc/priest/generate.lua                        # rewrites all-specs.txt
```

The build is fully deterministic: fixed seed `20260815`, no clock or randomness
beyond it, so re-running produces a byte-identical `all-specs.txt`
(sha256 `c3a82b3a6735bea925e50541a76103048bbba6328b2891655950a49f10056cda`,
7918 characters, 39 auras). When editing, never remove or reorder existing
`W.uid()` call sites — append new auras after all existing ones — so re-imports
offer "Update" instead of duplicating the pack. (v2 does exactly that: Renew is
built at the end of the script and re-parented into the Buffs row, so all 27
v1 auras keep their UIDs. v3 adds no auras at all — it only sets load fields — so
all 29 UIDs are untouched and it imports as a clean Update over v2. v4 builds its
ten PvP auras at the very bottom of the script and re-parents them into the
Alerts column and the new PvP column afterwards, so all 29 v3 UIDs are again
untouched: `changed=0`, `stable=28`, `parentSame=true`.) The script
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

## Import string (v4)

```
!WA:2!TZ16ZTX119SgwXsW2Xs0w0wmw2WmwYsowkalbiaKTtnErsircsUausu2nel29cSR4IDxU7cscLNM5rvDBAQzA80M4KOqN4otN20oSTEsBtZ0OPt(qM02tyBt30M0mLPTt7hANw9xqV37U4fjaeffPJnt)axU4(AVp(D(Dp3Z5SlZ57r4Ah)Qp6Af4fMv0qtpHMIMXz94XZeE8F6q69iOPAzOPOGetijRiAGupZnMWqgzA57u(gbXRyjTw9FpgVkFJCZjzG4TwVGMHiYiUB7RFW4kYx5k8gI(YPPPyjRBS44flAISykOZJBEl9EDBHCXtGBLykk(YQJeml40qsgvDk)CRyGkjRPMRQoIRKHwf9vCkrw5RG23QYQf1mkZBHlH3vDYWzSXWW4zn(kwsAgJRtY20Bb8OSOCjVg8c0egKZ0I3WYBHIYQYMsEJJ)NL3LSmKlvczyM54gU3(kXTipD(kg8SxNC1uhPOilA2xp(JxbxPc6k8vrglrtpTOP31nRuanpEyMTsXIYlU6mjILn3mzZfJlx9SMWaHZIl7ePgD0BuXeLArC)kRtlKNtLVmY07kIOc4wGm4ngj1Otm0uJUCfv3UL3vfLnVCfv8OzEelVII(H4P3NZj)X0er)UVd3PRuILq6hk7CvWZ((gQcE6(csYwOR7KRZC9bwMxv2zYCq4WdDDeVjkRfE1QKL0Db9fxvtfTMiE8tkXmK5edteEsv0Cjsrj9siq8Y8YQdb(XvacaSWaqq8)7DJPSSjsP4eAYQwfsKktUuC9llQ3tDufhYuRIHaY8g4sGmu5vop(HHFSp)QfnWtn4UfVfVNBWRkGxHhIKe5XxiBcUuPYSILMW8oLF)tCy2kYIRgu7YIbJeq6eleKZuGxb5zf8cbhfBzwd6Kwfpl4zfYqs2bZexrJx07QopgA3fcFv)RyIbXZEbzrlPdVImU4zPD2h(Da7NbUNF07asbHxJwgonl6SfJ(HA53K1M4XMk34XjvxcEOpWXHJ8k4jOJc(GhJJcqk4i4Ht6rGh17syiYmeWwEOF49ahZlCC4jGt4T56bJQ)atHlIVes8euoYq20swW0TjGmBOUWjHNeEVymcPtmJqnsbpq0NhgecVubExPPjUt)NoqiY1Wrixzd5bdnn5TiGbK01PJnhq00mqSZ0l03QebfCdmd(VR2REpwOfTMXuIxuBHl6sfSmnnYf9dEmmysapOLOJ5JDm9d2ufAisVUtQ1WoWz1VFAkyjDncYvGUOepg(N3GMbwedjst8fxZzvCA3N(1P5F5k4zOIvHWRyqwAq5WjgpZ4zsb9zGbiKYScTGnMDC62fXuM6hCid5R4BYk8Ie4OVC509xFmnJdZ0mTmWMrejGfXuMr3aFJjfz08utTo3A00waJkVGbV(sxW9M1Q)OPucJpvUrtNjL7CvtG0vtNjtkUz4sp8i50p5nPlHjvvfPIZCfv00mCMyMh37kOGY34rsyCpI7KyTLq9JDtACNelKPs5ciJ5H(wgpP6iSTMZ)C72SyysTu0CxGC)PqJvF3uQ13CfBNbHj3Gtv7xM4(PNcsi5sswhfsE(Ljsock8MM5lyHL8vT6LRCf8MsE5OPE8cMYQLuqfMGlDQS5GpAVWs5JJ5Yf6f(OEJtAoYnRtb5XX1xKi9Yglzs9dIB6yIemesejog)IsWbGio0djAio1J3nwszSm)9A4kIa3V3MLGUiZYu5rtzrehDjeEFe(4nYPg6MZYcpaUIEHE9cpO3vPpIrOtlpRbzfRIbIlHcIxLJxrxI3JtNiNto6NinH5TiVa6fsWJfsulfN34fMk9PA8RtLLYPrRMe8SyUwmlo4j(v00kZaNXd3cebV)sVWtdpd8(xDCLjZwvSGEPfIyiRsiOrsU9kzrrKkxMuNpf3QA4nbuDOjxzKX5sFPXZKl2OqIN84CcsiHzhcoY(wAEEdzEmgyjz1eALlWBXnpVsfet)A69)SpRHGeVAjKzFhhUgvfNL0XALGmSQcV8XHViUf8aFP1AbPcxR)G(X1UNNb(kKQDws9Isj(yDU6bwbMeoO3Bq0IQevQPoXePW4ngGHommS72aFtgY2aWimqA4SW5C54FJgC1CtOTaYGWnVSo5oIeitl00RrqU1ZlFBz8HXVzS7WentQdtEwhgC68c52O4rgNeK1L4gYD1EHPyGZFJACY0EWXogCrQqimnE4Cj45Hx4fHFrg4dGBYzG846XdfCEqcGiuKr)eDIAG2Enr7aQqjqcKHldZckGwE9hV7v1jnWe0pcmhJ(7R7LEZuUyEiWcQaZdlWal6mQQMhUcCk4d6b(qesd4dNh(ieXE4JDC4fHLCyfGponPpb96Ne(uWVevGhUAn5C4xglxdVewIg(vyGFv4tVJi6c)Apl8zGFD4L9aldFw43OHS2DcFoIGg8k1fYIKjyr5WYPkvih8Bkb)wWNh(cWRcj6Zb3Vp4lbFz4AUYjoqDksadUFzm4g(QDao)Q3XgHZzAgiUIf9CaeTpWKSgLqwyG46e8BJmYtqPJQFqNJm4lRSvfQuof2ULXSrixgO9q2RFmNNMUGvD8Q(tTj4r9c1gSr7H36pwxAK6WXnjd0mUUnBv2OjAryGIQXIb7DGP7BtW05qJvouoL5g9sXBbM(K1PNxU(SdMAomHAU)3VlG9S0ZToi5sakRC9kXXxcZmdxZtZ47otL3mA)rbM6NigUJlRFK6hgjlv1mFeLW8nb(0n6py9SopFzDzdzb8XCRii1uDQNrQYfWQIJQFE3t57ci(zrQirF4tnOOF)1tpTQkYW3qYgO1B6CqQOfG3jCxezWdaEH7wcUN7HbV49UG7BFKrWHCWf41u8IzZlg1LpF3WdJpOATDjiBAqK3E88TzNINcdTo9b2(GbSSkE5Ur3po(WRMeHy8ApzDNGhWl(6d73kTySGNCXHHNZdeZle3dKWlK0lHJ5QVhkPdEeDp0TqxtqttbVaOMDbz8UGxV2pjhPvQ1Hmzh2x3zi)7Wgksu2qrdYgnSF2OrzJZgEWWCb8JtLEDa61GCSHgaNo5AedCRoUQcwg7OWxVntwgJeJBm8zW3oBch95VXSiKEmIELwCeEpjk1gMgl2z(bRvsrBHHmqZvbPku1HSlojnPRJ5qhwX9mqsltslRZ5xj3ok9W5hEvY91o7aTmn0(KMxn91Dovdjf6tmNKSWSQittplr)jM)zTcvSS0uhhREMcFvABnQmUihI(8I7yDMRE)u62(pM(TOsbnieVUZruIpEUCJpgOFuhkVIukV2s3njKCEmDhDpfQHwMvfVCvJ(7JVjsWvAuO9)mZ5sgEVW5WIrFly)p1DIXHbtmU)Zjn4ybMDsUMo97NJUdZs1Wz5RtJ9n0FGAjs0soPSjrfuX8egVxzs4C5jYGy2mh5hIqbr4alJ4k)SHu6DtPqKrAIcCD0Iyse6EK5KlJGR1tacV2Z4YRLhwHyeJth40KLMT4(7NXZgLVG)I8W3UZcsNHBGGrdeKEDq61WW3RtsiWF12t2a(RBwAa(BCKaamy57lbR5b(Bpm83Xa)9oRp)ammg(haBpWpe(hH)Pdb)ODcaj8JVfqHW)CNbEWpz)xTWgXBkmy8w8fp3Lt7)8lm3jzH)LMXAW6naz)jWpDxdqb)Rym0aBadb)B7wqN(4ceInYG))WLBcC5PFJncxofgTGmVIuwdjXPp5qDgT8NUhaTutjL4dgosKFohPO3dz)nvnRnVh36TMkztToQ0FR7Zf7sO0tn5IHMF656ms6pB3gjf4nnK0vW6(fjE4aSryh0pB8a(9piwzVOHcqVYIv2l4ab6McX3MaTZE7a0m3(aTWG(J5a02HGTp4wb2UvoeAD84Nedhhm8Lop3SNCYcOiDgo(n3XHJ9TBTn33LnWarJpO)WbjxcrUmi5syYLiemhBy6vN7JsoSrGq4RSSbOxz7YoKpXpNSd5)vnm0)9wJyJQq1ctnC6Zo1WNV8uH6ms6pF3MyJ92GyZF8s4tD2)uta3XlP)U3GjhiMjY3yPZMnDMH3CMYivrFtyOvw3s)bQN5q8IOAP6REQjr4noi(QdNeXv11kXHQxIej8nEgFJLsVVgnvQyC(UqmUK17dpuJGaiw2S(sMM49AFzg)cn1bYME0uzsKIKk1WfePOVnvkYXufe3fiGU3BxBvSk(aBvkRML0yo2jSGZzj54vKlPcHnmT4jUbNHyFHKEBY6ogoU5gLNArLNZZs4va325ULO2a5EVUyvv(YYc0ioaUV9f3uZWccSCjdzhVjE3lrULCG5(5sYPixw26UjUODuYDsRlOPIF8QwdXlyPzuGlwY0tLTGbVOCfZpX9aN(alZBi4C4DmU2fP2iOkIPGmSmxPyffLeYgck4UQJfuwYOMdLjMmz)k3g2QbliKWlbfI1pqzISM5szQgS0vFCyyMUZ8LPvf8dgEG1WZMcsiZSsAlmU6AM0)nMSjXVABj7o1kF1t2GVIql99Zd)qUjKxeP0G1QHdPdeIYFHPIWSAygmk7v35B(uUAK7WRqzDwH6JqQJKYVrTZB14b2mpkjUlir8rA8QS(t0WnzKFB(cun0CDNR7)iYXed49(x1mM)OxCkZZDc1H3iHvDRLAZ8o7aJfEyvq3azISGGgKqUy8kw4LvBM37QMkYIOcAwwALxQwiAWsAxYYDBi2U6bxMggeut(yAzWtCli1Ws4NHqftC7uGwGQKUxqiOnZt5KWI0eSzoDpbGxMH6CvA657PQ4b6zrMLPotK0UlvRDjp91W3RAQqCXool9dvlVC1sg31O(7QE5YtBBARL3H31RlP5nhJs2D(FV2wM6hUf)bPrzc1m65zUEZP3Fi)49w)Ae8k1BTT4eP8WR3QR5GF7MCh3vpehUxlmBCsyiOFisLlHurgYcose5xRLFUQJachIxSk19Fuitg(YO9)PErOpo6pDJNJJKW1Gteg7s41EtFNGgKqN05KcyQondK28idmDek)AyyHs2An3QnTtXA1TBgjhQRyi9FNrZYUt8cZMx)(j3JibJuZf)wry1M541LujzfIkOoqip7esQ2mpXMKqXZATkHAZCIM9FDNfmjZmosMthrjsKar5NEXYDrY8U6SKjwkKkL4iqAZCkSiInZ7RZcG2m(TzcqQiRnZaneZSzc2IiMntOAYw2mdAZeM0w2mrSzIsFwNjVnZtVTKq(o1KqwRHJ60fWmG)EyDrXy8F)8WB0Fy)ySIEpn8vvn5hI7ygf(dAY7DurbBMFbBMNZMjgUBf3MjbbHBZK8R(4KrAkhyTnZq2mdJlWiXj6RyZC2naiTzoho3r3(4o6oebd56IODfyhEeTzu3PApQRmFjzHzuWIVisOpqIFfzfRQoqVeIdD50xCXybNiqxGE7FVj0dET(dsiEhJQOag0HXbemqM8oePTeKg517T1WlQbx(wacU)bZ1wmO(b3O6X7cashVwt1)C3Igep82mG84ThqkPPuDg82j45ohFWtrIzhltSqLVsPSkIDbjEG3MGe3cNINOl78uOytQOsw1hv)GjWhlq0xI6HgnbCUvoJDhPJ6IcR7qh3(XUPh3EAizrmAIgnPKiBtQ7wU54S6ZRNNJeY2yLWQHRCalAcXgX)elmESCl2fWI3AGLP3lqB961nv9abXn8JBZCSBIDe7mB0d9DBlB0YdH4n8DbEdXDjwi6CvKBrLXM2HfYM5ss3eNzGhwuKJnZZJl(lKVf2OhVlSrOff0meKnDpQuy9bN48tWMk9LUCxGx39Ek4vD7xpyqIzRz9ZfmuWbIWXgEWarjjWgpuOOr5W3foYnXIHDg49rwOTaVvhJhF6IKYKLKTd0BRqbgHQrg7Uhd4r3kmGBrKmEEQZi5oCUFEdbEvewFpttr6mPdyEGaX9xz65gBKut0fW89SNdm7AY64KygUgE1r7UwWQFNMaKRfJ(654BkAWvqGCySPrwzfKQq9tkuBBAcUKaEtU)N5JUTrM3SZO(wqOjE02zO5t21t(kxwxxI3ezkjx0YLQLp1OlwIhLkSvxqN37BtqN4wEFWRc3XNVEm3LijXI1YQI(IRGbI6hT50Bo6(sIpIRu9W7RPSPgkO165AiDTI(gdNNSAPwRNB08PjuXSUj1DQhXEs4SlwHeVP6pCl5XlR6lBfDIr(O5E4MZDuI9YwaVu2AY11xOU52FQ7Sj7TBZ8UoWTRX2TzUVAXIRnZHix6zZMv3M5(LCTOUnZd0Ww62mhgUV9zZ0leWM5bVBBMhQFUK2mhbFxFs2mVBBMh2M5OuRIBZ8inmhEtVoy1mcMPnJVAMc3M5XCmcoZoInWdkZpvr(Htwo6ie(TTI7)2WoSRqmRxmLf4RAwBN2h9vB7oTR0al21nAVn973TUP5K2IAdgBlfwlB0W5xHyLD33h08ompCLetMk18swct1rh4zZmh8tLOmpX2P8G3zQ7bVv0uRHU2qydt8Khx9YzZ8X2GR8Uf903wauP2o12(q1vB7d2ERx0ttmyNXHc7wbvnwNqv7QOV)hpFW3mqC2mFexKw4KzKyNYVW05MTlinJDCK2zBfbD7GWEn4A9hQ53rjPg5Fx7miWpqxrGeVt0geOnt63KOX2YHVWTnsAJUuOjK00XNB6i5oziTj57csYChhj9KBnK0(EZaj8IbBpx0H2KwrV9cz8kTZCyorNcnUuQBe2FczkOtietPuxi5OOHSozKUGqS2tJqI(LBVrgAsV49CKg4XCh3(P00teoq8X51e7cKOYEAiXtmABHeR36jI2ZHkWd7oHkMJN)eNmK6KHgA6UGkMFV9wjVrhCk3gpm8EoGXl(gDeySOUEuRPmmNu9kDbySWEzGrYt1E3Ju3ki71Wd4bCNGdjzN3YmQ1Wfo7iDboS4EAEIo4UmBMz2Zrm46cT2HekKEKbpVIFTtuozxqcvFRmsGAF2pnCh9107(8iAkvjr4MGzDJygy3YgMXhn1q56QzmZVtAgZgVn00Xx7SG5pEhXcMQx(IrIlMz8KOH2QH(WRtTzzcfnvKzENzZNKBGbceka3abdhk42i4DFlHxapYn1vlX2gV2b2mVSRfaQo9f4SMw3)LUyxec)m18xYgecPo7I1XFjKLrIxogCfACUorfftKJVrOUfjabog09)HYtD5XPzPG0NoF7eEBQTDkzeCZ3tvMEw8)9wY)j0xiHlv3pdNYxodz1zrw(so(fYO3FJVLbYkkKd7BjHWNPZWK8LnWPmn(EhKsfvUATgOjz(PI5ttL8L)RAtw6FSQ03eHkwT9DhaZdCV7y8a2mh8npwGR3Gfy(jAhhG4otO8hDYkfmJm0Ijmp)wHe4B8oVdYhLOLKTqLPbGC6VozYJS7lmQ(d1MGponUKNSrC6H3JEDNWzUwzVonSKDBpSKACY9nmP8ByZ8v2F6xRXtXMzLwAoBMxZM5RMNaK)ABOAZ)P3Ev7L2wv7Z(FS9Q2)5Tu1GtYYRwDJeP53n08OynFl39q(AJ(u(l7q6vDurH4JCo9jJJ6cP3NFhxZJBXO5Btkq(A1uG8rEU2FqZhODKy3YbaZUYk2wmAaWJSUTYvsVAWHpXvoX4ZFYUSY9f(z9khjKGh1W9BOAFCbzzJY6ikDA2aS(jFClPVzd(ibtIVSveeqKVLEWrXd5vR)2nKwmF7cYK30uVFRjK1B7wMgCHYHJXXoLy8USm9Q)mFzYM5ZMV(Nge)b8hbFnO)G0RHwvhzq(wFr(ejUeFXIiblYse8UwN82vjRIMWj)8D6D8)T0Xx7nxVY03oiGlwCaRjlDIsZIwOlXHZxSMELP)zec4h0ab8sXJeGLLCji5ZPuKi0pQs(jVwGrcZoO)qK345a037(aS2m)H2m)r031z8G3M5p(2ae8wVxK5BRv(ZgLn9cbMnR)5Y0Lv(V0U1kFpL7rShXR(iT(jqdIaFlAiLDf8jFiDv3VdzKVbzFV9)w7Vbzyn330NDSk5ynIipSO4cZ2Mp7y9yYnWPdDA)9m)D(H))(
```
