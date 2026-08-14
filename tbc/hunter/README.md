# Hunter TBC — Beast Mastery & Survival (v6)

A single WeakAuras pack for TBC Anniversary (2.4.3) hunters that covers both raid specs:
Beast Mastery (41/20/0) and Survival (0/20/41). It is built from the rotation, not from a
list of trackers — every element maps to one line of the priority list, and anything that
does not change which button you press next was left out. Everything matches by **spell ID**
(never by name), so it works identically on a zhCN or any other localized client.

46 auras: one draggable top-level group `Hunter TBC - BM & Survival` anchored at screen
centre `(0, -140)`, holding six sub-groups you can drag independently. Built for WeakAuras
`internalVersion 45` / `tocversion 20501`; modern WA migrates it forward on import.

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

## Import string (v6)

```
!WA:2!L3xE0TXX997v0Urc(is0sYrs(aM2sHsXwgaKGhk(iaGGKGI4qlafLKLm3fyhcSIl2D5UlijyBsDyCCvtBttzADEn)YLPJDoDskBsARBsAJETUVxI7RFFSnUBYl)6HEnTjPxXQTVMx(RohlawqccsjrAj58hCXUZoZSZmF)89AMVZqUJ3AUpXdEU7zPSI5MqYqtpIMIMXqT0slPAX3HdQ3AonvldnffKuKcYksgi1HU4GLuTqgEFqVdIevSkSu1NJlQkw7TzkyGeT031YsWB)kIMfUqwndjKryNpR(2dRip7SIgsEZOPPyjRBmtYXh3ezXLvxe)vT03Rt9KjCeCDfoU3d4nDjJPKNsujlRYkyuMvMjxWaLxwtntzDeFEdTs6lWYrA5zr30IYQJRzuu0cNdplYEbRBZXX1YsILSkOzKuN8AtpzXdaJlN3JHyoAcDXBAjAy5j74YQYMf8eg)JLN5SmKZNhzyM4ago3(mHTiFDXsgIbop5QPosrrwYCVT6lCjCHYQRiwgzmhn9ysMEUGzPSOPWD10LgFC5zwCSiHsNzS0zcXNP6RszGWVIpDQOdp8flzIIodUDLMvdc8QIfrMEwqcLfxdKoVXGrhov)Jm884HowZYZIsYMNTKkU3mfkGOII(oeP3NH9(4AsOp)n4mCfvkpsFhPNSeMc4T)skkEhTGSf68S3YgR328IQYSbZUGD3)5rIMO0wykwERcVjyFHv1urljH7)KCmgzmXWeHhuLmNJKvsReceUOOSA)GFCbGaqhqNqq8V3XYtzEtKY4P0KvTYgjAImr5BtwsV1Q4lEKPwjJCiZlktsrvu544pg(Z(4loUbEOb3SeTeB5IIQ5Wu4(jjr(8zthHpA0elyPLBkw(3AQDfOKS0IkZ09W8tE8tntOj4nZjQGAzbmHGNITmRaDIPIhfAzbsxsMHzcROjk5zr2NH2CHEoNVfmXa5jgvwYQWUwqgN900g7DEdW24GB97Fdq)qplrZdVMfD0ItFh19mH2eo0izsgMu8cWEEIda79zWdq3nCVqB8uaswgpjoP7b86zomezmcytaUp4(Hd4bERq7Wb94UCqC9DocolEJuqKGYrgYMwY5mDQci5YklCi4TbpagJqAeJLRI8IwGJ84q3qpZLv0HBk1n67W(dsU2DpKRbc2cgAAkAradOcNN23yGOtYbHpYUH9TiHrbxbJH)7C7wVvl0mwJzwqusB6t4ioyEAAKl6BF)yWuoCNUaTpV)9RVDxfOgl9fyPwb7ahv)2PPG501ii3CuIs4q4hVi9fywmKenX39smQ4jD(6NN((ZwcpcnEzONfmiKgugCIHtKmruyFgyacjplqZyTrhwZECS0u9T3VH8SEpwjrjcC0BMm6(Q2NgJjzAS66yJjHYHzXugt3aFJjfz4EOPsJBjAAtJrLJAiQp3Oo3Su1pnvKqYrYmCSerDgRCbsxmwIer5hJp2adMr)GRrtcluvvIYoZpUIMMbBGzkCRlRcsO2NKiXDpodIviH67FnQCwIztuQywKXuW(MhpOYy2wI9JtZoagMujfnhcKZJ5Qr9DsPsBZHTDmew4gC4kpzIBNTKTasoFbR7cIE85jCo5WAQmfYAH58vT2nFXsyftE4PPEGSMYQ5vqzhCeIGi4j3n8EecJLLNB3Wt6jmP6i3CbkipmU8seU3aH6Rp9TJR6qsemescjfxCMcGhOxM4Hi1yNUDplpNYyE(BZWHfb2Ph3CqNGBEk)OPSeINscbFe5XlxMAxRTuwyx4c6bUdpWBXZI0pXG0HLhXGqXkzG4JOGev5fv0li2cRrKH9g92JrK8oUyo0PJiIzsuZhw040Je7bR90dMMktJwScWJIL1ILIdTeEwnTICWBVf(PjmE)zEGhgEe4XwuTRbqNiXWXoR(0gYQeb0OcoTkzjjKkFIOhpk)IAgYyAevm5cdMKp2PsMitOHH(27b4ZvaLBI(H9EtZnLOHSigdmNSAeTIzfT4XgpucX1MMEBpYJyKRGOAEK5Epa8SuRFMthBzcYWQmmpSdpxKyIuEkUVQOfs26(C(Gb2fmOJG8VghrqoeJdgcokmSJu6VAnPT8P0MgzqKUoVo5ocpexDcAxIG9Q(oHgkZgsTwYNHJ5wSmWpetgm5Aq61Ed2cKUaKXr2lmY52nCCoy0lwrSkTjS)9dNKYhbNc3FEC40WzE3WtWbJHRtbqexUSqo2xscqqEo92xnUBA95sYbObfaz4SWeGcue0f0V)MxuwAGfm5Eado9hQ55ELsnXIsGsWuW0WmCqzwVAwb4xeom8l1c8oj89W7sa(LjCUW7(aWCW7HXydpfnP3l96td)kW5O8SWVAfwv49HznHFnmtj8RZb)gW7FdH7d(nFe4da)wW8TaFq43g(DQXUCJWZq4vGpuv(KEY5FwJINAiPd2n87wa(WW)p4JaFuOVdDa4JHb)TaF8Z7E0bE22c4dJ7B9HHfiaEk6ONGeaDa6LwGNd4zL9MGpo8jGN1HnHLFkdcoleod4tUk8cFKTSCEHeUrXlyrDiGy8bwgRrEKfgfFbc4V2leiq846B3X3H0YwLOm5um)6dWJBx9qU0rJH7NF)SVMEoRQyD9hyfqRQzQb4QgZAOFVnPsQcLxb)JBEIgOPSwvuhJeLJaZcT2q8NgdXxKmiJfhtCnsGAKirHvbgY3W5f47pa8MfcBikljSASdtXJffBvwiG(u4Ac3gTkxuuviGfsvybRPXWTYJJ9UaReLEVaeq4AcgOBAfmqh8OX1lfkXih1xQ6yGosvgO5Ro2J5E6MW902J6Wome1F5Uix87IZbxi4BIZCV1NzM03AWZLveEX8yca8ST4MHBisg7LAtDa2vAHwg7NxYO6fD0ttm(Jy1H(oJmCO4PW(nmCOihfBcsSmXoEugZ4lxHzCPA8D4oOa8fGVirNYxsa(MT1Jpmxi2KZQqpIArrlndsxko871iMXDGnuIzmdThYUqLXGP2zlkByOzuGkI42WKOD6z(SvmscJo6ZZQq(hh2xwmFh2Gh6Z4x)TwGAhsQskMO5Q4NzR(Pfzfyd9DG9(nNbYcnMrfNSQdV8b0psnlycjjLu180JIeNieXb(thhjjlEAhBDmpnZX4XO(eFyR8IuWfr8dgxHLarGz)ce5GZte8mxTp4JTikyi((71)iwN8eu0hrk57C)zzEtuGXJcFvb4pWHLe(dDygH)OvNteEjb4pwa(AcWxxa(gcWFcLz7dDJ385UhGR6u6aBzi9Dx1L50idDmFP30eJZCnvnSBm9ghBNL(ECndoiVHXUTB5DuzRcYQ6VLQVk6m6AMiVKblvKPj8MGTs67EGBgUfmD(w4W053mS9BIayBLjxcZ1Jz3Dp8xv)WDc31EB1xftCiw8qGy7xObM58GyrBp02U8fxWOuxOAhjCjSb1ourcTHsuFSfLvYn1bJxU9bNziiulqypqKwi40OEiuVZDFuLE4E0TsT)BPCAAkyxZutpTm2eUZx5rYmQuyLD5xG1L)SH93B39W7VJGD2l5AqF0R(PxdqV2b9AN0Rb5demqV4RD7ZFxg4ApPQcwc7DJ5Cx5GMXGH4J3)id7EO7ip(fNaH0drCBXINGolqvDIvtg(iV6s5v0MUFd0KLqQ5kZKwfMKwHZJLvmGIJl2fMNKwA20JqUDy6C)SRfj3xX1uAEQ5Cd9DvChK50mjf6xmtb5CuiulZrFeRFBPSLSS0utIT(xrSmTUgwgNLDq)EHzt(35UDQ6822V(LObR1u4EEMhWHtMjtY4WK3ftL64uvQnuD6XwFwmEBWWygHxf22RSfcskrhX0INxsxPh4VG1qEgQ9jZvbLiuvn1s67SsIeXo9jBs8FbRoglt5dDmyybchewBfd9tG07Jjw0b9VSuUJvKcbHJDsQIQNlGMrxMjdnJCre8ST2brj0d7OesaEoYmGDy)hMmWtyLF7TSCOpylaF3cRkB9qH97VdmUUZoc0b9AN0Rbxfyl8dQhWc)ZUHOW)cdwc)WcWpQa8JBb(x3f8VXb)7SH1)dm2c(pHFslWRbxe(V2b8FVrGsG)NndObrTWX6iCI0t0D0ULow9id4)TgK4Vg(PBWKFpxweY9Y3rND2T)1Lm6RVOBtHPBu3qOtn)eQuosgD8Pwb1CHAzARdp1YPQNetvBF2udFYKfMqzYtS6u1)MR2u1xOgvnOp)W)KWBazijew9wjuwvnRvsDVq9PsiNRnFlHclDsXubLcoU4q9S6u4VZMgf2xyS7ct32iPGT89Czd3rLvu8grRi2Fmj97OAYHsNkAKmEJhlD6yjgWLTGX1uZRrSHlm2Ew99vn9(rY5v92h20)cEtzOvu3sFhvF5aAEpo2chdxFxYA651sZ7GItpH(DwR6LnLKXUmt0TSY6jo24FVPqw63URLZzkSNJ0eRLVir8MmH34rDLuFrd13PsMiQ(oRzwBSHJMisuVjsoQRoyMq8denJ3yXJpsIOudujCfFtkxbZKuYSsMdDRxP2KUi2ZNsfvttQm28rKLztbVOcESe6XW0sKSABCe7iXwqwZ8Cd2QPHeOwohQfSBdt7upyZOj26EBNxQSQyr5CuN0Xwuh2e71ney(8gYSfT4MNJClXWP247JxrUOS1ntCYFyYDfUqonv8Nx1QFXCyx4YYhQVyJKoRHOKCjZN6wW2spVOroMrCyeVd8T2Y6gsbzyzUW4LuuIiBKtb3uDSu(VIJyt82uUcmghZwWG1p2IHvsgpFHytCIbg6C3pmixZfH9nWePNMj0MUSAS5oAFZNJopVkA5xOw6yc49AmwFHIhAGONNop)gYwYydyfGxP1Gq8fytoS3H1Yd3hpFOedeLn)RpTn3HWvQn3BZM7bi1In3dAZDyNIzZ9queX6nR8PhfZaYY(52bVLbMVjmznP03bPrLhPImKZLUG20jvfwQUhx0K(dpsuQmDMKPsTsiweT1N6hd7JN(OZI7TNiogqsy6YJ9B10B70vm(GmrHyaPMbsdBBng0Gewc7JVs6kv35DlezPQ6ejVIoZCeCpB2NPlycTpiOF7K7rKLM2D2j8hzZvY0cZ63k7xNfDgpqlNtVRXPllTMA7wh0l2h9sgQEB36X9FgVAgETE8ao)2XzoOxCJbFxNNXlwQrZ1dru38JeGxJpL8miLAAJOtfraNjFbRw6hkquwHvmDvrPKnh3QBHHn3wiuvx6DS5ERKLXNeabXWCZ6hQ2CwqE280HYkRiBvEmgt7yeIOdnKzOPrxtu6u6LMrz0yRQclBUTTkASi9NVfe0GS(9jlzrNfMfnvWONSAy)0kcVsasvr4PBGUSZT95PRLo1XotmIHS2su3hjSlVJS0xwM0AWIeS5gGLWmSeELw9dZZrXA0KfATS02ADgU5PtcePkNRsvs(WlHVx1uHSeT4xPVJkVltLKXTQLCaUSeeO1nT2eQxl7AldYLzuFySd6(7kiX1g)9qV2l1nhMJp(PxdqDFVlI77D2j2SlFD35syr)5kGmzC5lX4YXkojR14LHH2hAL8b2CrQNjGTc9(d2aUGMJBF6k4wgILIExGknLk9uyfy4okUmmSnxF6hy5qxQONXsqIsa0y8ItHu7xZOid2gk)u5Wp2NHXKlh2wOgS1tZHTyiffXAZni8k2CXwDCQn3q2ChLIkT5gUgI0MlUB0OnxIkWqBUK2CPivLn3XS54XvMnxACVpZLmy6lWS6aRaHOSIyTw0(CP8WMZ)CsitlM(mQwSIyCcbMlqFQYlfMRs689LSVkAYQuZ2C5Qt5LnNeCp2CiCtEC8F5T5kurbLnxaBUoS56eNoEuOlcE0MRBRZqQQEykBS561M7i4m82xQoRjT5EKLPUWM7rXz7XyAfOdWH0p8APaOIG)oUee87gWtPATWUETVqF8i7k5xwlr9PNwECR0wgYtGy8m(Mjv3b9Lj0mYd0er938Bi4zEc3lOb8Nx)Iy0lzrmGxELlzrZq3BDxBTHW7fD5u0AaUVSLm3zWvZ8KMJTEH6wTa3am2IkupmJd)Nav(mURUs8w7RgEJxlFj0y0Hb6OadTLrze1zv6)yrgD4MG2UL3WG2(NRG203vDXEqLfiR1hgEX2c4dJ4EEcIIgrp1fLccWluFWFaFkxb8rLjLXM7m2CpHn3yB8gbqPo0fpSLnetaiOPvO6)9U3gaTEO1qugBzj0g3QaIofdmew8XN1FOrZQyfiwtSb4wFJhcZMJUcYViz1yDGt2Ct2C8ZZud)S5GCwDTPBqiNgz0OnNidlKT9sdh5SfBpB(8nblCBxhGfUpyWB6kq3w3xw62E6xSH62oV7zQBZs52Q779MJYnCFTECedbL33jMeDYShVRrgPjiO381hiO3uZrqQ1fUh1fXTT1jrMsc4UdOtdclcfNqTtkWMlQ6YSG(URpCDDPSRkQ7LRj2A6wDQCBUzQRUT5kJ)B2wF01by9PASDyZvzEJ3eWPxjY3wp23)uBTHqYiXh5yroEQtKIF0Maj3(B8eQT2ifY6qV2qfPhPHqLfQTEcBwc1USNlL1dCb3TAeCP3jvZ3NI8rn0l3e4YoU(aUSEwOYPO4fhlzQqbJRV9igAtl5ns19RgbaTEwPYlhQ5RNtvW4enBvdeSvzbjpapztYjsdaS6XhP6WS8aOSf9DW(Ac(O1RHXhF4QrNYIo7gr6Mg7zdNoZijQlejxgz75UyTyvHg7rvRiBU5GNDjs5hlE0idgkrSinTIS5EQ6lB4(JgIFfHNz3SWmUrfyjsbA8hBnkPrKKj6FK0rxrz60jmsjlBydBJ8jtMzfLQQVEn4l5SSPRCOWjWWByhlvOiX6)KxofvF7PJmyYKdpwmYwOHFKuzwJIFj54KRTCXI8Kn2H3iKnccjSg4nip3ApyPi0P7N(yfhOUa9PAH4QBDo06KUGbf0mTOERk4A)y8fRZtS5RMhd2DORIZw)uULIScpTCljXM7jRtmcXv9dUwZ6OfzLitxqZIj0jx(Uu1J2F0oI1Ete6C7VHXggxBmNWKD60kWc1zyCvJtwkelAigHgvFe7pW2PCH0yKIAoz18EjdOnYwfI9my33EPRm9BvzT2SuVTN1J6TNMbmxZvaf3BBi8Kb4kvEGbp7OHNobsRjaUD(ghRGCMzN3xGU6mqy)(c4JCjq4Gb7TxE8DD3dFNb7SJE47WFGa4p5nSArZv7)CKnsng60vFhV9(7(u9x2F8MaD211bqhF2CBf(OWwEPQrSFK(iXJfcR8ruX7Oy9zfQgX(0xHfRlxuwIgVVvJGl6BiHwcjeRnRVaJwEkKHQZ2fy31varDzjV9lBGQp94Knn7dsKKvng0OPhYiNOkIkIR(pH7zFQ(I4AnxQVh2VbcnlrGzgdr96RT05eTipq1nvjKVEGB0vmFzZT7TDLgWx2C3rL9DMn3Eix27kdTlBU9vjQUS5UZAXZLn3DbB)MS5UBa7o79CZ2CEBJVpBU7fFxBy5I3Nn39BZTFAKzzZDGAHKLRt(GkH4JPnx7lpCS42qIgREpr4tenWzJpDGtqS)ATer9eUJty)9gS7ozo1VkJJR0D(lWI9HkDSktz5Wt14vBUom(A4EFar1YBeljxH1P1xHwNX4t9rpSn3lsIMcNtdfbMSQXrkgd5ptPqLMTjlV2cWpTavwvOnQin9qv3iOlOvJMu)gutaEoiDvd8dtOFUYXHCYXpd)BbsoRzl)6rD3kMSNVuver5gpj2UfTDfoFpR7yzEJaeuEzGaBUFFhIVVZ67OkhSZSX8FQMq8FUnCIVNnks1z(knKunFvDnxhrNW9LvJo1ECtFhVtL4hBs(MqN(Kx7sNo6l1ywk3k)VoIuD0xAvjvbguJxFO8d1BxPBcP65VAsQCRjnCh(6myZShPzK1mFJvzAXRA42AgLwlE5UyFU908sqT56Eduvhr9e935jMjOvXmgnto5lSjQK0M7R0uLJ2CF1ngvJpXkj4lqu8gszAXYMoe(oF(gt4RzzEtj8xYN7ixHlg8Mo(4GJhRdJZgBqFLLAc(4tTHJpoIl6)AHp(kl742WbF0OtJJd5(04Wbc9ZUIGq2C)PoqN(ASmJfD582vpSZp5g)BE9bWKP9b7qu1V4bNkytamF6FobW0CBhwLykXMR01rwmS8GfXfwqczgxX)q5hCQMfGJFMRDnUBvcOvBUIxBqGU8yrdLV3sHMilFVINOjKLp71SKLV8Qef91nZwxBqGwNty)x(mnCsxDBN20QAhThZ8JO2SjZ4ZDTlR0WpuJ9tY9CoEDfnJ0JwdIMuFZejRP1SzoXmnHO9530iA054(9dBzVU2TVhRKCUjOJ2MvNIx)BwZWB4HJ2FMx)MK3ANlnPm0Y1O539))gY87oqN5sf(O95lXGDUUpXaOUAerrtfzkuXd1U8h03v2rcX1YRx5LM(P)sgltWcOr4NyYSJEScnHL5BxzbMwgldD9IFhSvyIq3ilnus4BZwgj6ki5NG6I78BcbcrMSbmdsxGOgWG5UgjzShCD2AzUwN51UKwPPW9LC0eWwoR7d4Bdz1jqwEjVrVTQjpkzpeRnUxRciV9RzykobsLLNA7n)OQOILRubUoeai698gYOisY1znfD7aWMhkVjl5o7SQHCoK3W93pwsWTUHjjiqMKPE9tqW5RjiyQunqmG0gZUUxQ)(cmyXrNSl1aRh5aVlsqXmNSfQiDZNp17JfiNDkaX1FlnyJNhdNZdYcTthDP4Hz6(vSsDGLKq2XGfDf0n2C)DB9d(dRvZ2C)9lVkS5(hO72()XLvSyFSlVI9PVKkwdNBmHndf5xwl093NjhYskWjJnvkuP27RjYH(oBAQUVVRu7TU73rdT3sFNnsaZLSHxcxnn8c31AcLZx)XpAx9w8Gk5BgL7vVAt5irMBCdN)FgSx(odeO3aqs2HnQtQcyno(j7ho9Ds3O3EjrlL30LYLdroIRjls8t(6PHXRl(PDtPk1ts6A8E93zFAJGg8KnHK83EnbjXM7hCKW(7Sx6rqGF6rqGF)0OQ)FbtpARlFKS8JO6(Uw8ODATnll2vQxPviQwL07D2J2DhLd1eIQDfl1IDvIO(Q2C)vcvon96WxhKtqVaDtOUb6Xh90GSNfXgir29)KZt15ehFCuolm3f5q9c3ZVa5eAqwfLILhHRFoLV2iHcFYV(QYC3xVtf6StfFYtnWunbh8D30Wb1DiAZ1OZq7x21SQ)8uIQ(oPrYmAYsYgi6rmp9SGy13EOxoNt8dXo4SzeZS7N8)BM9FztqxGDABs8NgMCxmkRZzYn8PVuR1pZkom5Hpl5GINwVFU16KFFpxEOMkhK1eGZvRtYABUVxLJY6xZ5KSwQ4aZEYrlALV9Jv3jzDTJ5t4fxX5)(YI2(LFYs3AXwLAv6C3DDNKWNf6fEvAiI)IyVDjJcoN6VKt83xzRxBFI)IDnBfhYVh7uN6KrJOpZSMD0Gd53wn574WbpSVwN6gFN)Fp
```
