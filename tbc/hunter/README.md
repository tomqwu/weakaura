# Hunter TBC — Beast Mastery & Survival (v7)

A single WeakAuras pack for TBC Anniversary (2.4.3) hunters that covers both raid specs:
Beast Mastery (41/20/0) and Survival (0/20/41). It is built from the rotation, not from a
list of trackers — every element maps to one line of the priority list, and anything that
does not change which button you press next was left out. Everything matches by **spell ID**
(never by name), so it works identically on a zhCN or any other localized client.

46 auras: one draggable top-level group `Hunter TBC - BM & Survival` anchored at screen
centre `(0, -140)`, holding six sub-groups you can drag independently. Built for WeakAuras
`internalVersion 45` / `tocversion 20501`; modern WA migrates it forward on import.

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
call: `stable=44 changed=0` against v4. v6 adds **no** constructors — it rewrites the
cooldown row's display in place (one trigger field per icon, the conditions that go with it,
and a glow subregion *replaced* at index 1 on the two rotational shots, never inserted, so no
`sub.N` condition anywhere in the pack is silently retargeted): `stable=45 changed=0`
against v5, with every load gate, position and parent untouched.

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

## Import string (v7)

```
!WA:2!L33E0TXX59610Urc(rKOLKJK8dyAlfkfBzaqc(qXpcaiijOiEOfGIsYsM7cSdbwXf7UC3fKeSnPomoUQPTPPmToNMBEz6yNNojLnj9w3K0gDADpNe3t(oSjUBYj3(qNMhoT3EJ1T90CYF15XcGfKGGusKwso)bxS7SZm7mZ3VVxZ8nd5owR5(epWzV7LYkMBcjdn9iAkAgd1slTKQfFhkOER50uTm0uuqsrkiRizGuh6cdws1cz49b8oisuXQWsvFoUOQyT3MPGbs0sFNllbV9RiAw48z1mKqgHD(S6BlSI8SZkAi5nJMMILSUXmjhFCtKfxwDr8x1sFpo1tMWrW1v44E3V30LmMsEkrLSSkRGrzwzMCbduEzn1mL1r85n0kPValhPLNfDJlkRoUMrrrlCo8Si7fSUnhhxlljwYQGMrsDYRn9KfpamUCEpgI5Oj0fVPLOHLNSJlRkBwWty8pwEMZYqoFEKHzI9B4C7th2I81flzig4CKRM6iffzjZ90QVWLWfkRUIyzKXC00Jjz658MLYIMc3vtxA8XLNzXXIekDMXsNjeFMQVkLbc)k(0PIo8WxOKjk6m42vAwniWRkwez6zbjuwCnq68gdgD4u9pYWZJh6ynlplkjBEMsQ4EZuOaIkk6BxKEFg27JRjH(8xNZWvuP8i9TNEYsykG3(lPO4D0cYwOZXElBSERZlQkZgm7c2v)NdjAIsBHPy5Tk8MG9gwvtfTKeU)tYXyKXedteEqvYCoswjTsiq4IIYQ9d(XfacaDaDcbX)E7lpL5nrkJNstw1kBKOjYeLVnzj9wRIV4rMALmYHmVGmjfvrLJH)y4p7JT44g4HgCZs0sSLliQMdtH7NKe5ZNnDe(OrtSGLwUPy5FlP2zGsYslQmt3dZp5Xo5mHMG3mNOcQLfWecEk2YSc0jMkEuOLfiDjzgMjSIMOKNfzFgAZf65S(wWedKNyuzjRc7CbzC2ttBS3X1bBLdULF41b9d9Senp8Aw0rlo9Tx3ZeAt4qJKjzysXla7(X3pSNNgpaDxW9aTXtbizz8K4KUBWRN5WqKXiGnb4EH7d2Vh4TcTdhWJ7YbX13Xi4S4nsbrckhziBAjNZ0PkGKlRSWbH3gC)ymcPrmwUkYlAbo8JbDd9mxwrhUPu3GVd5pi5A39qUgiylyOPPOfbmGkCoAFJbIobhe(W7c27IegfCfmg(VZUl9wTqZynMzbrjTPpUJ4G5PPrUOVT9Hbt5WD6c0(8(2N(2CvGAS0NNLAfSdCe9BJMcMtxJGCZrjkHdHF8c0xGzXqs0eF3lXOINW5RFo67ptj8i04LHEwWGqAqzWjgorYerH9AGbiK8SanJ1gDyn7XXst13w)gYZ69OLeLiWrVzYO7RAFAmMKPXQRJnMekhMftzmDd8nMuKH7HMknULOPnngvoQHO(CJ6CZsv)0urcjhjZWXse1zSYfiDXyjseLFm(ydmyg9dSgnjSqvvjk7m)4kAAgSbMPWTUSkiHAFsIe3D7miwHeQVV1OYzjMnrPIzrgtb7DE8GkJzBj2pon7ayysLu0CiqopMRg13jLkTnh22XqyHBWHQ8KjUD2s2ci58fSUti6XMNW5KdRPYuiRfMZx1Ax8flHvm5HNM6(ZAkRMxbLDWricIGNyxW7rimwwEUDbpHNWKQJCZ5PG8W4Ylr4EdeQV(03gUQdjrWqijKuCXzkaEGEzIhIuJD628S8CkJ55VvdhweyhECZbDCU5P8JMYsiEkje8rKhVCzQDT2szHDIlOh429aVfpls)edshwEydcfRKbIpIcsuLxurVGylSgrg2B0BpgrY74I5qNkIiMjrnFyrJtnsShO2tpqAQmnAXkapcwwlwko0s4z10kYbV9w4NMW49x7bEi4HHhDr1UgaD8edh7m6tBiRseqJk40QKLKqQ8jIESO8lQziJPruXKlmys(yNmzImHgg6Bp7NpxbuUj6h2Zno3uIgYIymWCYQr0kMv0IhB8qjexBA6T9WpSrUcIQ5rM7z)WZqT(zoDSLjidRYW8W29CbIjs5P4(QIwizR7Z6dgyNWGocY)ACeb5qmoyi4iWWosP)Q1K2YNsBAKbr6686K7i8qC1jODjc2R67eAOmBi1AjFgoQBXYa)qmzWKRbPx7nylq6cqghzVWiNDxWX4GrVqfXQ0MW(2hCckFeCsC)5XGtbN(DdpohmgUofarC5Yc5yFjjab550BF14UP1NljhGguaKHZatakqrqxq)(AErzPbwWK7gm40FWMN7vk1elkbkbtbtdZWbLz9QzfGFD4qWVrlW7KW3dVlb43KW5cV79dZbVhgJn8K0KEV0Rpf8BbNLYZc)2vyvH3hM1e(DWmLWVlh87bV)neUp43)HHpa8haZ3c8bH)q4pQg7YnapnHxb(qv5t6jN)znkEYHKoq3WFCb4dd)VGpc8rH(o4(Hpgg83c8XpN7rh4zAlGpmUV1hcwGa4POJEcsa0bOxAbEwGNv2Be(4WNaEgh2ew(Pmi4Sq4mGp5QWl8rU(LZlKWnkEblQdbeJpWYynYJSWO4Zta)1EHabIhxFBo(oKw2QeLjNI5xFaEC7QhYLoAmC)C7J910ZzvfRRF)RaAvntnax1ywd97PjvsvO8k4FCZt0anL1QI6yKOCeywO1gI)uyi(IKbzS4yIRrcuJejkSkWq(goVaF)(H3SqydrzjHvJDykESOyRYcb0Ncxt42Ov5IIQcbSqQclynngUvECS3fyLO07fGacxvWaDJRGb6ahjUEPqjg5i(svhd0HRYanF1XEm3t3eUN2Eeh2HHO(l3f5IFxCo4cbFtCM7T(mZK(wdEUSIWlMhtaGNPf3mCdrYyVuBQdWUsl0Yy)8sgvVGJEAIXFeRo03rKHdfpf2VHHdf5iytqILj2XIYygFPkmJlvJVd3bfGVa8fj6u(scW3STE8H5cXMCwf6rulkAPzq6sXH)KgXmUDSHsmJzO9q2fQmgm1oBrzddnJcure3kMeTdpZNTIrsy0rFEwfY)4WEZI57Wg8qFg)6V1cu7qsvsXenxf)mB1pTiRaBOVDS3V5mqwOXmQ4KvD4LpG(HRzbtijPKQMNAuK4eHioWFQ4ijzXt5yRJ5Pyogpg1N4dzLxKcUiIFW4kSeicm7xJihCEIGN5Q9bF0frbdX3FV(hX6ehNI(isjFN7llZBIcmEu4Rka)zoSKW)BhMr4pF15eHxua(leGVMa81fGVHa8xsz2(q3WnD27g4QoLoW1pK(UQ6YCAKHoMV0BAIXzUMQg2nMEJJTZsF3UMbhK3Wy32T8oQSvbzv93s1xfDgDntKxYGLkY0eEtWwi9DpWnb3mMoFZCy68Bg22nsaSTYKlH56XS7Uh(RQF4oG7CpT6RIjoelEiqS9j0aZCEaSOThCRx6IlyuQZxTJeUe2GAhQiH2qjQp6IYk5M6aXl3(GZmeeQfiShisleCAupeQ3zVxQspCp6wO2)TuonnfSRzQPNwgBc35Q8izgvkSYU8ZZ6YF2W(7T7E493rWo7LCnOp6v)0RbOx7GETt61G8bcgOx81U95VldCTNuvblH9UWCURCqZyWq8X7FKHDp0D4h7ctGq6HiUTyXtqNfOQoXQjdF4xzP8kAt3VbAYsi1CLzsRctsRW5WYkgqXXf7cZtslnB6ri3omDUF25IK7R4Aknp1CUH(UkUdYCAMKc9lMPGCokeQL5OpI1VTu2swwAQjXw)RiwMwxdlJZY2PFVWSj)7S3gvDEB7t)I0G1AkCphZd4WjZKjzCyY7KPsDCQk1gQo9ORplgVvyymJWRaB9LVEcskrhX0INxsxPh4VL1qEAQ9jZvbLiuvn1s67OsIeXo9jBs8FbRoglt5dDuyybchewBfd9tG07Ljw0b9VSuU9vKcbHJDsQIQNZJMrxMjdnJCre8mT2brj0d5OesaEwYmGDi)hImWtyLF7TSCOpylaF)cRkB9qH97VdmUUZoc0b9AN0Rbxfyl8JQhWc)y3qu4NWGLWpTa8QfGFwlW)2oH)Do4)lBy9)aJTG)FWpVf41Gla))3o8FUrGsG)RndObrTWr7iCI0t0D0ULoA9id4)UgK4Vh(fBWKFpxseY9W3rND2T)1Lm6RTOBtHPBu3qOtn)eQuosgD8jxb1CHAzAldp1YPQNatvBF2udFIKfMqzYJV6u1V7vAQ6ZxJQg0NF4Fv4nGmKecRERekRQM1kPUNV(ujKZ1MVLqHLoHyQGsbhxCOEwDk83BtJc7lm2DHPBBKuW1)dCzd3rKvu8grRi2Fmj9BVAYHsNkAKmEJhlD6yjgWLTGX1uZRrSHlm2Ew99wn9(rY5v92h20)cEtzOvu3sF7vF5aAEpg2chdxFxYA651sZ7GItpH(DuR6LnLKXUmt0TSY6jo24FVPqw63MRLZzkSNJ0eRLVir8MmH34rDLuFrd13jtMiQ(oQzwBSHJMisuVjsoQRoyMq8denJ3yXJpsIOudujCfFtkxbZKuYSsMdDlxU2KUi2ZNsfvttQm28rKLztbVOcESe6XW0sKSABCe7iXwqwZ8Cd2QPHeOwohQfSBdt7upyZOj26ERNtQSQyr5CuN0Xwuh2e71ney(8gYSfT4MMJClXWP247JxrUOS1nrCYFyYDfoFonv8Nx1QFXCyx4YYhQVyJKoRHOKCjZN8MX2spVOroMrCyeVd8T2Y6gsbzyzUW4LuuIiBKtb3uDSu(7WrSjERkxggJJzlyW6hDXWkjJNVqSjo(adD27dgKR5IW(gyI0tXeAtxwn2ChT35ZrNNxfT8lulDmb8EmgRVqXdnq0ZrNNFdzlzSbScWl3Aqi(cSjh27WA5H7LNpuIbIYM)1NYM7G4k1M7TzZD)KAXM7bS5oKtXS5EqkIy9Mv(0JIzazz)SBN3YaZ3eMSMu6BN0OYJurgY5sxqB6KQclv3JlAs)HhjkvMotYuPwjelI2Yt(ZG9YtF0zX92DehdijmD5X(TA6TD6kgFaMOqmGuZaPHTTgdAqclH9XxjDLQ7CUfISuvDIKxrNzocUNn7Z0fmH2he0VnY9iYst7o7e(JS5kzAHz9BL9RZIoJhOLZP3140LLwtTDRd4f7JEjdvVTB9y(pTxndVwpwaNF740hWlUXGVRZt7fl1O56HiQBEvb414tjpdsPM2i6ureWzYxWQL(PceLvyftxrukzZXT6wyyZD9eQQl9o2CVvYY4tcGGyyUz9dwBolipBEQqzLvKTkpgJPDmcr0HgYm00ORjkDs9sZOmASvvHLn3wxfnwK(Z3ccAqw)(KLSOZcZIMky0twnSFAfHxoaPQi80nqx2z32801sN6yNjgXqwBjQ7Je2L3rw6lltAnyrc2CdWsygwcVCR(H55OynAYcTwwARTod380jbIuLZvPkjF4LW3RAQqwIw8R03EL3LPsY4w1soaxwcc06MwBc1RLDTLb5YmQpm2bD)DfK4AJ)EOx7L6MdZXh)0RbOUV3fX99o7eB2LVU7CjSO)CfqMmU8LyC5yfNK1A8sWq7dUs(aBUi1ZeWwHE)bBaxqZXTpvfCldXsrVlqLMsLEkScmChfxgg2MRp99VCOlv0ZyjirjaAmEXPqQ9RzuKbBdLFQC4h7ZWyYLdBlud26P5WwmKIIyT5geEzBUyRoo1MBiBUJqrL2CdxdrAZf3nA0MlrfyOnxsBUuKQYM7O2C84kZMlnU3N5Igm9fywDGvGquwrSwlAFUuEyZ5FojKPftFgvlwrmoHaZfOpv5LcZvjD((s2xfnzvQzBUC1P8YMtcUBBoeUjpo(V82CfQOGYMlGnxh2CDIthpk0fbpAZ1T1PjvvpmLn2C9AZDyCgE7lvN1K2Cp8YuxyZ9i4S9OmTc0b4q6hATuaurWFhxec(Dd4PuTwyxV6xOpEKDL8lRLO(0tlpUvAld5jqmEgFZKQ7G(YeAg5bAIO(B6ne8mpU7f0a(BQFrm6LSigWlTYLSOzO7TSZT0q49IUCkAna3xYsM7m4QzEsZXwpFDRwGBagBrfQhMXH)tGkFg3vxjER9vdVXRLVeAm6WaDuGH2YOmI6Sk9F0iJoCtqB38ByqB)4kOn9DwxShuzbYA9HGxOTa(WiUNJGOOr0tDrPGa881h8hWNYvaFuzszS5oTn3JBZn2gVrauQdDXdBzdXeacAAfQ(FV7PbqRhCneLXwwcTXTkGOtXadHfF8z9hA0SkwbI1eBaUL34HWS5ORG8lqwnwh4Kn3Knh)801WpBoiNvxB6geYPrgnAZjYWczBV0WrotX2ZMpFtWc361ayH7fg8gVm0T19LKUTN6fAOUTZ5EM62SuUT6(EV5OCd3xRhhXqq59D8jrNi7X6AKrAcc6nFTbc6n1CeKADH7rDrCBBDsKPKaURa60GWIqXju7KcS5IQUmlOVR6dxxxk7QI6EPAITMUvNk3MBM6QBBUY4)MT1hzDawFYgBh2CvM34nbC6LJ8T1J99p5wAiKms8roAKJL64P4hTjqYT9gpHARnsHSo0Rnur6HBiuzHARNWMLqTl55sz9axWDRgbx6Ds189PiFed9YnbUS9RnGlRNfQCkkEXXsMkuW46BlIH20sEJuD)QraqRNvQ8sHA(65ufmorZw1abBvwqY9Zt2KCI0aaRE8rQomlpakBrFhOVMGpA9Qy8XhUA0PSOZUrKUPXEMWPZmsI6crYLr2E2lulwvOXEu1kYMBo4zwIu(XIhnYGHselstRiBUNS(YgU)OH4xr4z2nlmJBubwIuGg)XwJsAejzI(hjD0vuMoDcJuYYg2W2iFYKzwrPQ6Rxd(solB6khkCcm8g2XsfksS(pXLsr13w6idMm5WJfJSfA4hjvM1O4xuoo5AlxSipzJD4nczJGqcRbEdYZT2dwkcD6(PpwXbQZtFQwiU6wNdToPlyqbntlQ3QcU2pgFX68eB(Q5XGDh6k4S1pLBPiRWtl3ssS5EI6eJqCv)aR1SoArwjY0f0SycDYLVlv9O9hTJyT3eHo32BySHX1gZjmzNoTcSqDggx14KLcXIgIrOr1hX(dSDkNpngPOMtwnVxYaAJSvHypd29Tx8Yt)wvwRnl1B7E9OE7PyaZ1CfqX92gcpzaUsLhyWZmA4PtG0AcGBhVXXkiNz259fORode2VVa(ixceoyWE7LhFx39W3zWo7Oh(o8hia(tEDRw0C1(VczJuJHoD13XAV)Upz)L9hVjqNDEna0XNn3wGpkC9Vy1i2psFK4XcHv(iQ4DuS(ScvJyF6RWI1LlklrJ33QrWf9nKqlHeI1M1xGrlpfYq1z7cSR6kGOUSK3(Lnq1NECYMM9bisYQgdA00dzKtufrfXv)NW9SpvFrCTMl13d73aHMLiWmJHOE91w6CIwKhO6MQeYx3)n4kMVS521wVCd4lBUBVY(oZMB3Kl7zLH2Ln3ERevx2C3rT45YM7oHTDJ2C3fGDN9UVjBoVTX3Nn39GVRnSCX71M7(S52hnYSS52FTqYY1jFqLq8X0MR9LhowCBirJvVhp8XJg4mXNoWXj2FTwIOEC3XjS)Ed2DNmN6xLXXv6o)5zX(qLowLPSC4PA8QnxhgFnCVpGOA5nILKRW606RqRZy8P(Oh2M7firtHZPHIatw14ifJH8NPuOsZ2KLxBb4xuGkRk0gvKMEWQBe0f0QrtQFdQjaplKUQb(Hj0px54Go54xI)TajN1SLF9OUBft2ZxQkIOCJNeB3I2UmNVN1DSmVrackVmqGn3FQdX33z8DeLd0z2y(pzti(p7goX3ZgfP60FLgsQMVQUMRHOt4(YQrNApUPVJ1Ps8JojFtOtFYREPth5fBmlLBL)xdrQoYlUQKQadQXRpu(H6TR0nHu9CxjjvU1KgUdFDgSz2J0mYAMVXQmT4vnCBnJsRfVuxSp3EAErO2CDVbQQJOE8(784Ze0QygJMjN853evsAZ9vAQYrBUV6gJQXhFLe8fikEdPmTyzthcFNpxJj81SmVPe(l6ZDKlZfdEthFCGXJ1HXzInOVYsnbF8P2WXhh2f9FTWhFLLDCB4GpA0PXXbDFAC4aH(LxwqiBU)khOtFnwMXIUCE7kh25NFdF3xFamzAFWoev9lEGPc2eaZN(xramn32HvjMsS5kDnKfdlpyrCHfKqMXv8pu(bNQzb44N5QxJ7wLaA1MR4vheOlnw0q57TuOjYY3R4XBcz5ZEvlz5lVkrrFDZS1vheO15e2)LpDdN0v32PnTQ2r6Xm)iQnBYm(Cx9Ykn8d2y)KCpNJxtrZi9O1GOj13mrYAAnBMJpttiAF(nnIgDoUF)W1Vhx723Jwso3e0rBZQtXR)nRz4n8Wr7pZRFtYBTZLMugA5A087()zdz(DhOZCPcFK(8LyWox3NyauxnIOOPImfQ4HAx(d67Y7iH4Q51R8It)0FhJLjyb0i8tmz2rpAHMWY8TRSatlJLHUEXVd2kmrOBKLgkj8TzlJeDfK8tqDXD(nHaHit2aMbPlqudyWCxJKm2dUoBTmxRZ8AxuR0u4(soAc46pJ7d4Bdz1jqwEjVrVTQjpkzpeRnUxRciV9RzykobsLLNA7n)OQOILRubUoeai698gYOisY1znfD7aWMhkVjl5o7SQHCoK3W93pwsWTSHjjiqMKPE9tqW5QjiyQunqmG0gZUUxQ)(cmyXrNSl1aRh5aVlsqXmNSfQiDZN)bFvwGC2Paex)T0GnEEmCopal0oD0LIhMP7xXk1bwsczhdw0vq3yZ9pULp4pTwnBZ9pT8QWM7FMUB7)xwwXI9XU0k2N(IQynCUXe2muKFjTq3)qMCilPaNi2uPqLAVVMih67TPP6(EVCT36UEhn0El9D0ibmx0gEjCL0WlCxRjuoF9h)iD1BXdOKVzuUx5knLJezUXnC()zWE47mqGEdajzh2OoPkG144NSF403bDJE7LeTuEtxkxoe5iUMSiXpXRNggVU4N2fLQupjPRX71FN9PncAWt0esY)WvfKeBUF0Hd7VZEPhbb(Phbb(9tJQ(FcME0wx(iz5vP6(UA8ODATnll2LRxPviQwL07D2J0DhLd1eIQDfl1IDfIO(k2CFhHkNMED4RdYjOxGUju3a94JEAq2ZIydKi7(FY5P6CIJpokNfM7ICOEH75NNCcniRIsXYJW1oNYxBKqHp5xFvzU7R3PcDMPIp5jhyQMGd((BA4G6oeT5A0zO9l5Aw1FokrvFh0izgnzjzde9iMNEwqS6Bp0lLZj(HyhC2mIz29r()nZ(UKjOlWoTnj(tdtUtgL15m5g(0xS16NzfhM8WNLCqXtR3p3ADYVV7lnutLdYAcW5k1jzTn3pOYrz9R5CswlvCGzpXOfTY3(rR7KSU2X8j8cR48FFzrB)YpzPBTyRsTkD27QUts4Za9cVcneXFbS3UKrbNt9xYj(7lVLRUpXFXUMTId53JEYtEIOr0NzwZoAWH8BRM8DCOGhYxRtDdVZ)Nd
```
