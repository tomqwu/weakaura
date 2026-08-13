# Hunter TBC — Beast Mastery & Survival (v5)

A single WeakAuras pack for TBC Anniversary (2.4.3) hunters that covers both raid specs:
Beast Mastery (41/20/0) and Survival (0/20/41). It is built from the rotation, not from a
list of trackers — every element maps to one line of the priority list, and anything that
does not change which button you press next was left out. Everything matches by **spell ID**
(never by name), so it works identically on a zhCN or any other localized client.

46 auras: one draggable top-level group `Hunter TBC - BM & Survival` anchored at screen
centre `(0, -140)`, holding six sub-groups you can drag independently. Built for WeakAuras
`internalVersion 45` / `tocversion 20501`; modern WA migrates it forward on import.

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
holds the same nine prompts. Four of the new elements read `arena1..arena5` and are therefore
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

**Resources** `(0, 56)` — three 172x14 bars stacked flush: health (green, `%` at the inner
right), mana (blue, `%` at the inner right) and threat. Health and mana are always up and
fade to 50% alpha out of combat. The mana bar turns red below 20% — the same threshold that
fires the Go-Viper prompt, so the bar and the alert agree.
The threat bar loads only in a party or raid, never in an arena (v5 — there is no threat table
there), and only exists while you have a threat state on your target: green normally, orange
from 70% (press Misdirection), red from 90% (press Feign Death), deep red the moment you are
actually pulling aggro. On top of it sits a red `ADD`-blend flash that pulses at 80%+ threat,
same gates, because solo threat is your pet's problem, not yours.

**Buffs** `(0, -16)` — a static row of four 40x40 icon timers with the remaining duration
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
text, tooltips on hover and desaturation while the ability is down: Bestial Wrath,
Intimidation, Readiness, Wyvern Sting, Rapid Fire, Multi-Shot, Arcane Shot, Misdirection,
Feign Death. Talent and late-trained abilities load-gate on their own spell, so the row shows
exactly the buttons your current build owns and the gaps close by themselves. In an arena or
a battleground it grows two more: **Freezing Trap** and **Scatter Shot** (v4). Two of them do
double duty: **Rapid Fire** and **Bestial Wrath** show their *active* window first (15s of
+40% ranged haste; 18s of +50% pet damage) — full colour plus a glow while it runs, the
cooldown swipe afterwards. Kill Command deliberately has no icon here — a 5-second cooldown
says nothing useful; its reactive alert owns it.

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
| Threat bar / threat flash | party/raid **and** not in an arena (v5) | grouped PvE, and battlegrounds |
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
- **A pet health bar / pet unit frame.** The pet decisions the *rotation* needs are covered by
  the two prompts above; a second set of unit frames is not this pack's job.
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
  an empty threat "%". Judge the layout there, judge behaviour in combat.
- On a future re-import the Update dialog's **Arrangement** checkbox (checked by default)
  resets any positions you dragged in game back to the string's defaults. Uncheck it to keep
  your own placement, or tell me your coordinates and they get baked into the script.

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
call: `stable=44 changed=0` against v4.

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
| Medallion of the Horde | 30346 | 2 min |
| Medallion of the Alliance | 37864 | 2 min |
| Insignia of the Horde (Hunter) | 18846 | 5 min |
| Insignia of the Alliance (Hunter) | 18856 | 5 min |

## Import string (v5)

```
!WA:2!L3vE0TXX5DVM2ns0hrIwsosYhW0wkKo2YaGe8qXhbaeKeuehAbOOKSK5Ua7qGvCXUl3DbjbBtQdJJRAABAktRZRP5Y0XoNojLnjT1nj9f9ADFVu)A)ESjUBABAA1R5SNwT9186F15ybWccqqkjklr3)qlxm7mZUZ8977A((MrChRTSFIh8S39kzeZoLKHMEynfnJrAPLws2I3dfqVTSAQwgAkkiPW5LvKmqQJCHHlQAHm88GEggjQyLFLk)oMOQy1NMoVbs0sF3RQapdQiAM)8z0mKqgHCET67iKI88ZlAi5jTMMILSUXCjMCstKfxgDr8B1sFFo9t6qHX9vOyEoONufnMrEgrLmSolVrjwBMEjduozn10L0r85m0kQVeRgPKNhDJllRoPMrbrlCnADz2dydBooUwwrSOvEnJe6KhB2Ag8eWKY5A1qmlTGE4nTenSAnZKYQYM5Bne(pwTUGLHCUCidZ4h0W52NjKf5Tlw0q0)5ixn1rkkYsM7RnVHkIBugDfXsiJfOLhvYS1ZBwmdAg8qnvXjNuEULNiCWuPNiv6G8PR8OKgi8J4tLmYOJEHIMOiZH)UsX6bbEvXciZwxscLb3dKbVXWrgn5GJn6I4Po2NvRlljBEMIQ4rZmi)Ikk67uKEFA2ZJPjH(8xNZ0vePCi9DMA6IykGNblQO4z88YwOZXEkBUE7lkQkZMm7b2ZGNdjAIszHPy5SY)MG9hsvtfTIeE8tQXeK5edteEsvYCbsvjFLG)qfeLvhe8HBa4h6c6gcG)7TV6sw0ePmzsnzvRmHJepDe(2LL0BRc(IhzQv0ilY8cYKsufvog(LHFTp(YtAGNAWFwIwITCbr1Syk8GKIiV(mPcZhjs8LS0YodR(Bl5U9xuwAzL56Du(Pp2jNl4u8MzfvqTSeMqWtXwMLHorvXZcTSezijZWmHu0eLADz2RH(5c9DwVlzIbYtnUSKv(DVKmU6POFS3X1bBNdUL)URdge6BfAD41SOZwC67SMFtOnHcow6eHinppS3N4GW(Eg8e0Db3d0opfGKHXtIl6UbpTUagImbbSja3lCFWbBfERqhqNT6UDqm9DngUkEcNxKGYrgYMwYznD6ciXQAlC)WBdEamgH8rmr2YYlAbo8Jd9c9TqgrhUPK3G3d5la5AV9rU6pqlyOPPOfbmGYFo6yJbIobhe6W7b2)YegfChmb(FNDp6TzHMZAcZ8IsAZEChXblslJCrFhhadMYIh05PJ5dCa9D4QbvzPppR0Yyh4i63gTemNUgb5MLsucfe)ZlqFaMfdjrl8DVcJkEcN3(5Op)mfXZqtwc6BjdcPbLgxyO4jIhb2VbgGqQZs0kwD2H9zpjwAQ(og0qEEphTOOebo6jDADVvgttWKmnrndSjKqzXSyktOBGVXKImCp1u(JBfAzZIrLJBiQVW4o3SsLxnvKqIXspA04rCMRCbsxoA84r4NGp6qdNwVZ15tcluvvIYoZpPIMMbBIzg8xxgfKq1xjrI7EDMeltc1pW605ScZeVyHmiJzG9ViEsLXSTc7poF2(XWKYLO5qGC(z2QuFNsk)T5W2obclCdou5FzI)oBjtEKCU8w3je5yls4CYI1uzkKXcZ5RATh(cfXkMALNw6bZykRMtbLz4XicIGNCpW7riewwE29apzRHiDh5MZtb5HWTxIW96p4adOVdCxhuIGHqsiPyIZLhAf6NjEiCv2PBR1vxtzmp)TA4WIa7Qv3CqhNBrk)OPSeINscbVe5XRwMApRVuwy34g2kC7TcVLwxM(kgMoT8igekwrdeFyfKOkVOIEEXwyFePzprVJOejVtkMfDQWIyMe1CHeno1yrFWQ)6btrLPrBwE4rXYAXsXHwcnVMwbo4T3c)SegV)KwHhgEe4XwwTNHqhp(OrpJ(SgYQeb0O8oFvYssiv(4rowe(L1mKX0iQyYLgobF0tMiE6GJcdSVdYNnpk7udc77gxygrdzrmgybz1WAfYiAXJnEOiIRDn92FKhXiBEr1CiZ9Dq4zPw)SGo2YeKHvjyryNTEbIjs5O4(kIwivR3Z6fgA3WWocY)ACeb5quoye4iWOosP)QvL2YNuBwKbr66I6K7i8qC1iODfc2RYZeAOmBi56jFgoQBXYa)imzWKRbOx7pqlqQ8qAhzVWyNDpWX4GXVqzXQ0pHdCa4eu(i4K4XZJdNco97gEcoycCFkaI42LbYYEtsacYXP3XAXDt7pxsoanipidNbMcuGcGUG(918MYkdSGP3lyWP)qnV21l1elkbkcZaZcZXbLyJQ5fGFE4qWVqlW7KW3dVlb4xKW5cV7dclaVhgJn8u0IEV0Rpn8lbNLYZc)YLzvH3hM1e(vWmLWVkh8RbV)nfUp4x)rGpa8Bal2c8bHFt43Qk7YnapdHxb(qv4t6lRV5nkCYrK6Sx43op8HHFh4JaFuyG7)GWhdd(Bb(4NZ9Sd8ST73lg332ddlra8u0rFbiaA)0lTaphWZA7ncFC4tapRdBcR(ugeCviCgWNCn4f(ix)Q5fI7gfVKf1HaIXhyzSg5qwyu85jG)QpqGaXJPVdhFhsjBvKYKtX8Bmap(7QpYLUAmC)ChG920ZAvbRR)a1bTQuPgGRAmRH(90KoPcuUo(h38enqtz1UOggjkhbMfA9H4pngIVmzsgloM4AKa1irIcR8mKVHZdW3Fq4nleYquwsyTyhMHhlk2QKGF9zW9e(B0Qubrvb)wivHLSMfd3knj27cSsu69cGFHRjyGUX6yG68iX0lgm(yhXBYAyGoCfgOfRm3J5E6LW90(J6Womc1F5Eix85IZb3i4BIRC)1wzM03QWZv1eEXCyca8ST4MHBesf7NAtTF2vAJwf7NhYS6fC0ttm(Jy1H(UcpAWyjX(nmAWWhbBcs00rpwegZ4lxMzCLQ8D4bOa8fGVirNYxsa(MT3Nxmxi2KZkqpIArrlndYqkg872iMXDInuIzmdDeYUqLXGP2zkiByOzKNkI4wXKOD16IzkBKegDmqRRb5Fsy)zW8DydEO)g)4V1su7qswuXeTqz)mBZhTj1Hn03j273Sgil0egLDYQg8Yhq)WvTGjOKucvZtnosCQGeh4pvmKKS4PCS1X8umhJNG6t8HSYjsbxeXpyCfwcebM9ZrKdUirWZcvFHp2YOab5hSFFJzDIJtrFePKVZdKH5nrEgpk8vfGFFhws4pWHze(dxBor4LeG)ib4RjaFDb4Bia)XuMTp0nCtN9UbUklPdC9JOVNkUmNczOJ5l9KIyCMRLQHDJPNyy7S03RRvWb5je2TDlpJlBLxwv)Tu5rrMtxZe5HmzPImnH3eSnYyVv4MGBgtNVzomD(nd74gja22yYLWC9y2D3t)v0pChWDUV28w2ehIfpei2beAGzopiw02dT9lDXfmk15RmqcveBqTdvKqBOe1hBzzLSZ0zSsDm8CJabBbc1keUfconsReQ3zVxQsp8i6wO2)TswnnfSRzQPMvgBc35k)tYkQKV(H8lWgYF2q(6V3(491vGU7NCnGx6vF0R(Px7IETB61a8(d4VF81E96RhdCVNqvblH9UWCU1pPzmCq(ydo2OUN6o8JFHPqi9Ge3wS4jOZ8uvNy1KHo8RUsofTzh0anDrKA2smPvHiLL)CyzfdP44ID(fjLLIT8iKBhLU2p7EzY9LDnLwNQo3qFwz3bzontkH(gtNxolfc1Yc0FI1VTsMIwwAQjWw)RiwI2xJkJRYoPVVqSf)7S3gvDE7hq)I0G1QkCphZd4qjsNormy67KPsDsQk1gQo9OBmlgVvyumJWRcB)vUEcskExr1ILtsxPp4pJ9H8mu7twOmkrOIAQv03v5cjIDgq2K4)cwDmwMYh6OWOceoiS2kg6NaP3ptSOd6FvLC71vcbHJDsQSQNZJMtxMjdnTCbe8ST1frj0d7OesaEoYkGDiFhImXtyLF7TSAOpylaF38RjB9iH85RlmUU7U83f9A30Rbwdyl8dQfWc)q3qu4hXGLWpop8tYd)0wG)5Dd)lCW)kBA9FdJTG)D4)Of41Gla)N7e(V2mqjW)9vcObrTWr7ku8ut1BKELoATid4)PkK4Vc(zBYK)wVKiK7JVRU7UxFBiz0BTOBZGPBu3qOln)uQuosgD8PQJAUu1kTTrNz1u1tGPQDmFYrprI8tPm9XxBQ63(Qnv9fQsvd41h8pj8gqgscHvVncLvvZQEQ75RTuc5C95BjuyPtiMmGuGjfhPV1Mc)DUIrH9gc7UWSTpws46)BCzd3rKvu8ewRa2Fmj9BVsXbtLms40EIfnvQOXhYLTGX0uZPrSHle2Ew99xP8brY5u9ma20)8EsAOvq3sFNvE4qAEog2chdxVxsm98yP5zyXzNs)oQ29YMsYyxMj6wQVFIHn(3tsKL(T5kCoZG9CKwy16foSNeX9elIRIgisWbozI4r03vvZAJoAK4HJ4jEIXDnathKFOiP9enwSXIhHAGkHR4Bs5kyMKswvYSOB5Y1M0LXE(uSGAksNXwpImmBk4fvWZLqFgMwIKOTXrSJeBbzvZZnyrtdjqTCoyly3gM1PFWMrtS19wpNujvXcYzPoPJTOoKj2RBW)I5mKzbT4MwGClXWP25hGxrUGS1nrCYFuYD5pFwnv8Rx1AqXSyx4YWhCGOJLkJHOKCrZN6MX2sVOOrwMrCyeVd8TAyDdQGmSmxAYIkkHLnYQG)uDSu(VKJyt82vUmmghZwWG1p2YHuselx(OtD8Hg5S3hmmxZfH9nWePNMj0Mgwn2AhT)fZsxNxfTClvTCmb8EmMyGGXcouKZrxNFdzlzSbScWR0wai2sSfh2ZOA5G7LNpy8HIWw)1N2M7(XDQn3BZM7bi9In3dAZDiNMzZ9queXgTQ8PghZaYQ(z3jVLbMVjejMu67K8rLdPImKZMkV2SjufwPMFUSj9p8irPs0vsMk1kUyb02EQFkSFE6pDcU3Ed7yajHPlh2VvtpDqJyCNmrHyaPMbsdBBng0Gewb7JVsQYD35ClezLk6ejpIUYCeCpB1NPbmHoge0VnY9isOPDxDc)rMSfnTWS(TX(RtqNXt0Yz17zsAyP1u7WQtpyF0lAO6PdRh33P9Oz4X6X9783UoDNEWFm476(0EWsnAUEiI6MFIa8A8jLNdPuvBeDPi87S4ly1s)ybIYkSIPRkkLS54wBlmS5UEcv1LEhBU3kjm(KeiikMBw)(RUMfKFBEQGzKvKTknbJPDccr0HgYm00ONPkEs9IZPmE01uHLn32xdnwKXZ3ccyqIFFIIw0vHzztfm6jJg2pTcWR4N0veE6gOl7S7yrAS0Po2zIrmKylrDFKWU8oYqFyjYxdwKGn3qScMJvWR0MpyrokwJwSqBLK2EBZXTiDrGiD5cL7sYlEf89QMkKq0IFK(ol)S0Llg)vTIdWLvGaTVP9MqTAzxFzqUmJ6dJDq3xpbiU24Rp61(PU5WC8Xh9QFQ779qCFV7UXMD5T3Uxbl6pBEKjJlFfgxowXjjwJxcgAF)1ZhyZfUwMawe69fObCbnh3(0LXTmelf9UevAkv6PqDy4UkSkmSn3a6hC1qxQONjItYsa0e8IZGuhuZOad2gm3mzX)CadJPxnSnFvyBRnh2IHuueRn3WWRyZfDTXP2CJyZDekQ0MB0QisBUyUrJ2CXlddT5syZLK0v2Ch1MJh3z2CPWJ(0x0GPVaZQdSceIYkI1ArgWLYdBoFliHmTy6ZOAXkGXjeyUa9xLFOWcLlNFGeduwtw5E2MlBnkVS5KG72MdH)KNe)VC2C5lRGYMZVnxx2CDJlhpl0dbpAZ1R1PjDvFmLn2C9BZDyCfE7RuJ1K2CpYQuxyZ9O4Q9ymTc0j4G6hA9uauwWFxxec(Dd4PuTwyxV2xOpEMTE(L1tuFQzLN0kLLH8uigpJ35s2BaVPdoN8qnru)n9gcEMNWDanG)0AdIr)KGyaVC9HSOzO7TT7T1q49YUCkADa3xYsM7oWAzEsZXwVqnrlWnaJfuHAHzC4)jqLpJhQ1J36yTWB8A5kIMGonqNfyOT0kJPoVYGhn84J2e02n)gg02pSmAtF31K7bLdqwBpm8IT73lgX98eefnJEQjlfeGxO2K)a(uUs4JYlkJn3PT5EcBUj28ncGsDObpSLnftaiOP6u9)E3xdGwp06ikJfwcTjTYJOlXadHfBY59fC8mkw(J2eBaUL34HWS5Orq(fjrJ1bozZnDZXpptv8ZvgKZARnDtc50iJgT5ezyHmDuC0WNPqhzYLRjyHBDlaw4EHHVXldDB9EjPB7PFXgQB7CUxPURuk3wBFVVYOCdpwRfhXqq58E8PrNiZX6zSXAcc6nV1ab9MAocsTM09OMmUT9UjYuId3LFDAsyrO4eQDcb2ArvtLf03tTPRRlLDvqDVCvXwZ2MtNBZnxn9Tnxj8)MVThDdawFQgBh2cLx34Ra40lh5BBe77FQT1qiz4yJD0Whl5XtYpEtGK74nEc1wFKcjo0Rpur6rAiuzPQXt4kLqTl51szJaxWdRgbx6FA1CdOiFed9snbUSZTgWLnsGkNHIxCSKPmfmM(ocBOnRKNWv2VAea0gjsLxkuZxpxQGjjA2QKiyRrajpipztYjstaSAXhj7YS0qOmf825anbF021W4JpCLStzzNDJiDtJ9SHsLES41KIKRIS9CxOAUQqZ9OkDKn3cWZUcP9tels4HdgpA4M2r2CpvTTn0GrcYxx6z2llnJBudwH0Gg)YwNwAeor8bhlvK6At3oPrkjSHn8BKprI011Qk(61G3KtytRFQWjXWB4alzWWrh8exknvFhPcpCIeJoruYwOHFSKPxNMFr54KRTCXY8Kn2HNWKnccjTg4ni)UT(WsrOl3p9NLDG680FvnfxDRZH2N0agKxZ0I6TQGR9JXxSgpXwSsDmy3HUkUA9Z4wksDEA5wsIn3twJyeIR6DUER6OfjsKPYRzXe6KnxpQ6rgmsxr7OjcDUT3WydJRnMtiYoDQoSqnggxX4KvcYYgIXOz1hX(dSDkNpfgPOMvwnNhYeAJSvHypd29Tx6Yt)wfwRRuQ327gr92tZaMRBeqXJ2gcpzaUILgA4ZmEOzJJ0AcGBxVXXkiNv2595VNU9hYNx)Ejx8hkqG(7NhFxV9X3DGU7Qp(U853p(vEDRv2C1X)pYgPgdD6zGJ1XG9EYbl5lwtGo7Ela0XRn32GpkC9VuLm2p8aK8XcHv(iQ4zCS(S8vYyF6JWI1LlilrZ33kzWf9jKulHKI1M12GXlndYq1z7cSNAAGOUSKNbLnq1wEmYMM9bjsYQKdA0YdAKvufrfXv7RW9QpvBtCfZLAhHdAGqZteyM2quV2ElvwrlYpO6MkNYxpWn4kNVS52Z2VCt4lBUBV8(oZMBVKl7R(u7YMB)LZQlBU7OA(CzZDNWoUrBU7cWUZE33KnNN25hWM7EW31owU49AZDF2ChGMzw2ChSAkz56KpOCk(yAZ1XQthlUnLSXQ)Jh64r8FMyZ6)4e7VwprupH78e2x)b6TBMt9RX8y9UZVej3hcQmRyjZYlx5OZ04inxd(EDCT3VOAPnJWXLFdA5vWny(9uBMdBZ9IKmPW5KqrGjNAsKIXi(sxmyX5BsO1wc(z5PYPcUzLLP3FLnb6sAQLbARAZPjaphKQIX9Hi0ox14(DQX)l(V5j1SQD8BevD1TqpFPkiIsnEbSDlw7YCTE2W5X8MbiO0Qab2C)EoeFVNX7ru6S7mr9DYMq8FUnDI)(C5X2xPre9nls5P)knKuUyf9qBHOJ4XYArh7iMP3J1TsSJonFtOJFYTU0XJ8snML0THdBHiLh5LwtsP)H141hj3i93tQMqkF(RLjLU1shQlVDhOz260mYE6VXASK7vmkCDZaSLVudKOBVyViulVH3Cw1q0p(GDF85cyviTrZKd)cxbvcVgeDxGIV6RdQE7(5BmbVQ1(xBWKFPrL7CYODzCMOd7TKutOYFQTSsPhOXSRl7YNSTYKV0DmCxIQ(e7CManH89P36QKDnsCdBUIBHuTU6mYWfbuczgtX3i5gEMMLfHFMTUeW1iRsT5kSvMVlyU(lgCQm89lE8Mq2(SBzjBF51iv3Rz5NU2GaUbxv9V8PB4kJ62GNzv1osFM5gtTzR6WNBRlR4OpuJDyX9chULIMsgrRdrvAG5cNX0A(0hFUMqu)8x1iQ0fY(9dx)(CTLEpAr5StrPgMvwhxFxPwg3qJgzW0V(TsUvp8zsAOLTrlI73BtzrChQ7SjdDKb8gF4U3Whla0fInSIMkYuOSRI94lG3lVZ9HRLdk5fN(VxHXsfipAm(PMoZ4hnFtyP(wLJI0QyPObf(DWcJeHUrI)tc4pNfRiAyI8rqDXC(BCbcrMSlldqJcudyaD3JKk2hUpBRexBZ9AxuHtk0ajgpoC9NX9P4THS6uilpKNO3ELIhNSrH1M0JvEKNb1mmfNcPYQt1nGFevuHsL7ax70FIEtpbnkGKCDGsrZ5F2cg5jrr3vN1nKdB8gUj(XscULnnjb(tNi5RFccoxvbbZKSbIbK2C2A9sdoG)Hlm(09O6FJih4DrY8LfKTqfO7W8zEFSS1SBbiM(BPb7U8O4A2jl)nX6AppBxSwjYb4PC6guSC)HLQq2IGfCLLn2CFVT9b)XvFl2C)9v6oBUVpBJk(pq3E9)JRQzr)yxAn7tFr1SgUGvcxju6Fjfz7)wMmjlj)Ni6mjrf7yGMit6BVPRM)ImvgQZ2SVFzBZUR3rdTntFxnsyZfTrAcxnnsdp0AcLZ7GXosp9xOtLCnJY9DUAt5iPIBmdN)dmyF8D73F)(HeStxuNsfWAF8r2aC67IUZU9qspkpPkMnlICMwtIk8t(6Pr0Bi(P9qPk1ss6zY(919aAJHg(enHK8QxtqsS5(bhoKVU7NEMd4JEMd4Zhnn6)ry6r794LuLFcvp41INLtRVjArVC9WTmr1QOE)ZFKE7QuWMqu)RlB1w0Rse1x1M7VqO8XNxxE7ICK55Vxc11FFEPh)J9Tm2yjY29NCaQUG4KtIYAH5UiNIx4r(5jhjdYQOKS6iS15y9AZek8j)6RjZ9a9ptWZmtSPp5qZ0eCG9vmCqnNA2Cn6qZ(LDD0V)8uIQ(UOPUmA6IYgi6zkp9WFyT3pOxkhm8JWoPSzeZmhG8FWmh4sMGUe741K4Bnm9UzuwNdHB4tFX2RFM6o94Hpl5KHN2VFU17OEFVxAOMYNC1eGZvRJUABUVB5ZU6xZ5ORwQWqZFIXlyLRJJwZrxD11BbEX6oW3xv61V6Js62k0MuBsN9UQ5Od(mq)WRsZj8xe75lzwW5y(LCe)(kB7A7J4xSBA1DQ(E0tEYtejS(CZB2vdovFBZKVRdf4qEBBMB4D()n
```
