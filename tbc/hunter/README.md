# Hunter TBC — Beast Mastery & Survival (v4)

A single WeakAuras pack for TBC Anniversary (2.4.3) hunters that covers both raid specs:
Beast Mastery (41/20/0) and Survival (0/20/41). It is built from the rotation, not from a
list of trackers — every element maps to one line of the priority list, and anything that
does not change which button you press next was left out. Everything matches by **spell ID**
(never by name), so it works identically on a zhCN or any other localized client.

45 auras: one draggable top-level group `Hunter TBC - BM & Survival` anchored at screen
centre `(0, -140)`, holding six sub-groups you can drag independently. Built for WeakAuras
`internalVersion 45` / `tocversion 20501`; modern WA migrates it forward on import.

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
  the opening Sap or trap lands before you are in combat.
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
  is readable on TBC, enemy *spec* is not.
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
The threat bar loads only in a party or raid and only exists while you have a threat state on
your target: green normally, orange from 70% (press Misdirection), red from 90% (press Feign
Death), deep red the moment you are actually pulling aggro. On top of it sits a red
`ADD`-blend flash that pulses at 80%+ threat, also party/raid only, because solo threat is
your pet's problem, not yours.

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
trap armed, Viper Sting out. Empty in PvE, and empty in PvP whenever nothing needs saying.
Full description in *v4 — PvP layer* above.

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
| Threat bar / threat flash | party/raid only | grouped play |
| CC ON ME / Trinket DOWN / TARGET IMMUNE | arena + battleground | everyone, PvP only |
| DEADZONE prompt | arena + battleground + in combat | everyone, PvP only |
| SILENCE NOW prompt | `spellknown 34490` + arena/BG | Marksmanship (Silencing Shot) |
| Will of the Forsaken DOWN | `spellknown 7744` + arena/BG | Undead |
| Trap Armed / Freezing Trap CD | `spellknown 1499` + arena/BG | level 20+, PvP only |
| Scatter Shot CD | `spellknown 19503` + arena/BG | Survival 20-pointer, PvP only |
| Enemy Trinket | **arena only** (reads `arena1..arena5`) | arena |
| Viper Sting Out | `spellknown 3034` + **arena only** | level 36+, arena |

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
- **A per-opponent range column, enemy health frames, an enemy-cooldown wall, or "the enemy
  healer's mana".** The first is impossible (WeakAuras' range check has no arena unit and
  every extra unit costs its own frame-update trigger), the middle two are Gladius' job and
  fail the "changes my next press" bar, and enemy power on arena units is not a verified
  primitive in this client.

## Importing

Copy the whole string from the fenced block at the bottom (GitHub's copy button on that block
grabs it exactly) or from `all-specs.txt`, then in game: `/wa` → **Import** → paste.

Four things to expect, all normal:

- The twelve v4 **PvP auras show as greyed-out / not loaded** in the `/wa` list whenever you
  are not in an arena or a battleground. That is the load gate working, not a fault — step
  into a BG and they light up.
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
parent unchanged as well.

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
| Viper Sting | v4 arena clone row (r1-r4) | 3034, 14279, 14280, 27018 |
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

## Import string (v4)

```
!WA:2!DZ3EWTX159MvWkwc(rKOLKTL8dyAlfshBzaqc(qXoo4fjbjbj0cqrkzjtSa7HaR4IDxU7cqcMM0eghx1020uMe7M3X0jUD60KClN00oEsD7LjontRtYx50jZoDUPTHT3CttFmnQ)1n9F65XcGfKGGusu2IAgYf7E2ZE2Z589771577SCNPLSFPh7sp4QzeYoTOUQwyvzv9bD5YvcxEpzaTwYQQyQRklJedNxswuhPm4LhOOIjs3ZJ7zaKGSz(vREDCbfHA3nvEDKGP2HxxbE6twWi)Azu1fr6HSFTAhiKS08ZlOl6jLQQSPKM(CJo1ugitUmAc43QP2rTBNuHcJBRqX9CcpjlQxsQKGCgwJLxVm7zMzjDuojvLuL1q850vlQTeRgjLMhT3LLuMsvVGGjUgUxMDd2WMJJZ1QcfnZRQpQg52gUZGNaMskNBDHS0c6I3Wuq30DMPKuKmY7oe(ht3lyQlLlhs3yKtOBF6leYK82fkQl4FfYrdnKSSKOXrBXBOI4hkJMSqzK(c0YJjA4EnJIzqLWd1KfNAkP5wEYWbtMAYKPcYNQ6TsOJW3IpzIOdp8LlAGIohUFLK1cP5vekGmCVKikdUfidE9bIoCI(gB4fXtDSUL7LfLmUyrf8OPeYVGSS2bfONNID)4QIO)W3M90vuXCiTdMCMIykGN(kkl7z88sMOvy3LnxV)ffuKytMDbhPVvqcgOKMykwoZ83kCSqkQkOvfXJFsnMKmNOBGWtQIglqQkPxc(dvqqsPpWh(ba)qhqNqa8V396lzrdK8ujuLumZeo6iPIY3QKOwlvXx8id1I6zrgxwIuIIG8zWVm8R9zwEkD8udUBjyk46YckzXu4(ifrE9zsgMpA0rwYunBjw93xId7VOK4YYZ19W8ZCMZnxWP5nYkiJCTeMqWtXwgvGoXuWZcUwImKKyyMqYQcIUxM9AODxONl5DjdmqE6XLenZF4LKWvpjTZEFVny)CWD8)5Tb9b9SkTo8QM0zloTdw31eAtOGJLA0qKhppCVp7jGJ(c4jOhaEiOvEkajdJNex0dcECVagImjbSLgEy4rGt4gENqBq7UD(CqCTdngUkEcNxGGYr6sgMsznSBcy019SWJcVl4XWyesNyYSvKx4co1ZaDd9SqgbBUPe3I3t6la5y39qo6pGlm00qWKagq5xHo2yGOZYbHo1rGJTmHrb3atI))shrRft0CMtAKxquD2jSfhSiTmYbTdCCmyklEqNNoMp(X1oGJhOgl9ASsRGDGH0UlAjyoDvcYnlLOeki(YltVbMfdjsl8dTkJkEw73(k07FXI4zOPkd9SKoH0GsHlm0iJosu4y6yacPolrRyTzhw3EkS0uTd0NU08EoDrbrcC0tQuAERoMMKjzAY6gytkIYIzXKNuthFIbfz4CQPsNBvAzZIrLJRlOTW42NSA1xnvKWOJLA4yJe1EUYbiD5yJmsu(j5J1)aP0AFl6syHQkIu2z(PKvv1ztmLW9UmYO01ELejU3R9KyfsO2X3IgNvyMrkwidsVeCSfXtQmMTvz)y3T9JHjvkr1MazFz2AuF7sQ03SzBNeHfUbNSYvg4(PRm5rs5YBE)q0ZSiHZjlwtLr6mMyoFfZJWxOiwXKBEAPNiJHKsozuMbgJiic(Ghb(WPdHLLN9iWh0DisZroznkipe(5fjCV(dgjI2bWnDqrcgcjIeJlmxEWn0lt8q4ASt3L71xtjmp)DQBZIahYTtoOj4wKYpAijI4PKqWlrE86LP21wlLfom(bDd3TB4ECVm9vmaDA5P0juSI6i(WYibfEbzT8cUyDIuS7O1wmIK3PeYIoFybmtIsUqc6NFSypETRE8KuzA0hlp8EWYAXsXbxHMxvTah8UDXplHX774gEs4PGNEzLU6hnXidh7IAZQlPqeqJYB3RKefrk8Je9mr5xwvxctJOIjxAGr5JDUrhjvWHHih9e8zZJYoDFWr37cLe0LeWyGfKucRwiJGjp24HIiUwv1A9PEk9S5fuYHmo6jGxIA9ZcAyltq6MLHfHd6(YetKYrX9vfTqQw3xYl0)HHbSfK)T4icYHyCWGWqWW2sP)M1K2YNqDwKor66IAKZi8qC1jODvc2R69s3qz2qITs(mCANILb(bzYGjhdqp2BaxqY8qkBzVWyx6iWz4GXVCfXQ0UWXpoCwkFeCo845zGZdx4dbplhmjUntdc4NldKL9MebeKJtRTnJ7M2EoKCaQqEqcUimnidfaT0ApsZFuwzGjmZ9c6CAprZR9gLAIfLafHsWSWCCqz2OA(0W7doj8R4cE)e(E4dKg(vjCUWh6eWcWhMXydphTOpc94Zd)AWLO8SWVEfwv4JIznHFdmtj8BYb)wWhBhH7d(TFk4Jd)oWIUGpb8jHpvn2LBbEbcVc8Iv5t6jRV51lCUbfBVB4tNh(mWNf(CWNhI8ONa(cyWVl4lUIZzh4LA1VxmUVLNewIa4POJEcqa0(PhCbVmWZE29cFr4lbVKnBcR(ugeCviCgWxEt4f(C7z98cJ4efVKj1HaIXhyzS65qMyu8AeWFTBKMaXJRDaBFhskzwKYKtX8BpapUF1d5qhngUVYXzVnTSMvX6Ap2gGwvRudWvnM1q7HAsJufkVb(hN8enqtzTMOogjkhbMfARH4LWq8LjtYyXXexJSX762xIp)eW7iDiDbjX03yZeS3nWe0(qX1kgCKXgYBI6ycovvMGfRo)H5a6MWb067Xgspi1N3Uih85a9JFi4vXvU36RmtcAni26EeEHC4Pt4LC5KPzqsf7LAxSF2r6dTowipKz1lBRRLyahXYbTdfE4GXtGT9F4GHhcBgrSuXotugd13Tcd1Q14DWdW0Wxd(6e9c)VsdVAR94fZjHnBSk8HOAtWuvNmKId)rnIH6GyJDygKqhHSdu5eyQDMcs66Q65PS53jMeDi3lMPIHoy0re3Bc5Fk4yzW8oyJwOxJV93EjQTejkkBGwOIVIT4J(iBaBODqShSz1rMOj1R4OuD4LpU2PQzfsqrXrvmo)4iHPdsCc)8XrIscN32EfJZZCUDsQFTN0mNafCreHGXvyPiey2BNilBrIWJfQ9cF6LrbcY3xV(gZ8StqrFejDV)JNH5rqEgFg8nROn5pXMVc(tBct1lEl32LEqGR6YVa7zqTJu192KiDnS4Bpjjgs5yzvyNy4jo2MiT71XQTG8ec7ITPNXLmZlPODpvVv050unqEitkkidd4wH9rgJUHBdUDm9825W0Z3bCG9saMTWKHG5UXS1oNMRkl)(G7)OT4TI5ieRtiqPJNUbMK84yXqpX(V6flWOiRvDGeQi24xBQfHgqjEp9YsYzl1E8YTnWCdcbDbHCdHDrWJrDtOsx6HPkOWJO7GAR2QzvvLXUrPKCwjS5wRu5sYQFKFJd5xHnK)dc5R3U7H3xhb6SxYXaEPh9rp6NESd6XoPhdW7pG)EXh72RVU0XT(OkYLtJN0(6nystFGG8X7BSHDo1DQN5YtJqAbjUyyYtqH5PQ5WQ0cDQF0Q5KvNTpD0mfrkzlZKkfIuw(vWYe6x22D48lskljBPmiNomDDAo8YKZR4gjTo1CeHEVkUUXCWLuc9nMkVuwkeY1c0lX6IwntrttvLrXwQlluM2wdlHRYbPVVqSfQ7s3fv1BRhx7k04YAkhxH5TAOrtLA04Wm3pt93uu1Fnu13P3Ew3DNWWygHFiS)3ypeK0iDetnEorn5EG)cwh5fO2sSqfus6QQJ(R1ouLcjIxIizq81aRefl74fpnmCAchewRed9tG0hJj(Zg9VUsU7nucbHJDOPIkM1qZPjXKvMsQacEPw6GOS5jTv2KgEzYQvDsFNKmXtyLF3Uwp0h(BsdRMFtzRhmKpFDGX1D2H)oOh7KEmWMaBH)(6bSW)Gtik8pYGLWpjpSwE4FYf8pFy4)lh8tztR))Wyl4Nb)lUGFo8Vc)Bhe(33jqjW)X1dObr8)P7i0ijNU7ODlE66rgW)zniXBa)IDyYV7Rkc5r57OZo7232sg9Ul6grll1Lb6YOpTcLJKrhFUnqnxQwL23WLwpv9SyQABZNy4ZoA(PLNzInNQ(9FRMQ(k1OQb86d(XPVjKHKqy1AHqzvun3i1DT6lLqo3A(wcfw8ScjcigykHb7zZPW)GRBuyVHWUfmBRJLa2ZFNdB4gssw2ty1cfeue1U7QfhmzIOHt5jESKjJns)oSfmUQsovInCHW2TQDSQL3hskNINiyt8Z7jHUAbntTdw9M9R65mylC0D8EjXFZJPQNbeMDAT7RwZlzikHDVLOBzJTtCSr(EsGm1UlhHEPKujeTWA1lCypJoIN4rDuuKObJCUrhjQ2HQzwBSHJos4OEgz0XDmatfKV)OP8elE8Xgjk1avcxX)BkxbZKuYkiMfDhxR2KUm2dNIfussAm2AhKHztbVGmEUe6r3WuGezmoIDKyliRzEUolYxO0ulNd6c7EWS2Td2mAITU35kILvekiLL6An2I6qgQ6MG)fZPlXcWWTTa5uIHtTYhHxwQGK5TrIAZWKZYVwwvf8RxXSpHSyx1YWhmsSXsMrxquQOXZD7yBPxuqplZiomI3g(wleSbLr6Mglnvrz5Ws6zLXDvBlL)ECeBI3V81GX4y2cgS(PxoK8OXZLp20t0)Gx6rGb4AUiSxdtKEEMqBAiWyRZZXwmlDnzLvZTuTYXeWhsFYibJhS)ORqxtEDjtjSbSPHxVLaq8LylKRNHvZbpmpFWr6pkBTsFElUhg3OwCpIf3XjTIf3jS4EN2pMfxBueX2TQ8jhhZaYQ(LoiVPoMVjej(rAhK0PYHuq6sztMxD2rvsVADxUSb9hEKGyz6Q(sLAnIqb0(EUFoCmE6L2bI7EdBBajHPlh2)udpTrJUB7mrHyaPQosfBBng0GsVk2xE5KvAUvCkez1Q6ej3IUkAeCpBLIPb3GogsRDxKZrKWi7S6e(JmzlAyIz9BH9RDaIXt0sz16AkAiKvvAZSDpyFXlQR4PnZNX3f8OQ7X8z8B)BhxODp4od(SoVGhSuJMRhIOUzT0WpNpH0Ci5AAJOl5GF7fzbRw6NKMOScRy6TeLsWVCZnWa(Vj0uhADS48qc4oju)XW8YApATvMGCTX5dMrswYS8Kmw2jjKqBkiZmt9UMU450koN84X2u1vwC7zt0xrgnFBiGojs7Jw0KUwllBiJXozuXEPvaED)KMIWr3anzx6alsJ6n1TodmEHefiQZJeMLEZqVzzsVblqWI79YkyowbVEl(Gf5OinAXPBPS4(BzoUfPl1dPjxOstsEXRIpxXqMemv8T0oyL7LQsX4E1Q2WwwbPPTnT1sxVo2TwcKdJO(my3Z91vaIJn(6HESxQtom3E8rp6N68ExeN37StSrxE7UZvXc(ZMhzW4XxLXJJvBsIk4vHz2p6g5cS4EY6zbyXs3xGgWd0Cu7ZBJAz4vk2DjQOuQOZ0Rhb3rH1HGT4EkTtSEGlvSZKJqIMpAsEHsiL(u1lWaTbZvkl(Yi66ZSEqB(AGwxnh0Ibuu8Qfxq41T4cT5OulUWwCrOyslUO1WJwC95elAX1FfqOf3awCXinLf3GwCdHBmlUHtBXf)kgk91ywCGvEquurSulAehkoS4E0fergMmDzunyfWOecipn9Qk3m9cvkNpYOrQOfRslBXD(6uCzXDb4bT4EwCxEs8)4)eQOCYI7DzX9ywCpoUWtAX9ee0OfNxZlqAkFmfnwC(T46axHoxToljT46ADQkS46gxTEyAeOtWNs7KBLW)kc974kqOVt4oLQ5ID8gDb(451nYTSvI5toR0uMjn1LMgX4y8oxIUd4nvW5K6VjI5VLBk4yEwNHSaET6dtrVKWua)5BmOendBVVdVVgcUx2H7qBb0(QwQCNb2mdtAoY6vQlKaoXxSWguhk7xI7ONLiBgpq3iARTndTXRMRiAs6KaDoGH1sjpMY8Y9D6WJpCtWA79MgS2pTcwt7W1LFavcawlpj8vB1VxmE7RqWt0SUPUmjin8k1NGgWVNJKYOYIXyXDglUXT4MyNx9pL6qdoORDcL)uS06u6)roAdawpXwigJfmc1PmZJOlSadFfFQ59fC8mYM(J1eT)V9B(WxwCse5wFvsSwTbtwCxS5ONxOg656dUzZ1JUJGBAKXIwCNJHeY0wXHdFXcTLjxUMGeU1DbiHhggyVxdA16(QsR2Z)vBOwTvCU6CxVuRT5(BF9qTgEKwpkIHFY5DIzqNnZz6ASXAc(zF7oWp3AZXpk1Lih1LpST2jrEYiWd4xJMIue6nHwpAA2QpvxLtRDK6tMwhQ5QI5(U1ezP1IDJBXntDTTfNo(FJwEpBdO6Z1y7VwOYkfFDaLETiBBRTQ)52xdbKHJp2PdFMetKGF8Mai3)nFc02ACcjUZBnqr8PAiqzPAXp46LaTR6vpzRbl4bvJal9oJsUiYsdPRvUjGf37oalBNWswIIwSTGPc9lU2bcRRoRONWv3jze4Z2jUKxn0Y3mxCGPWid6oSHKT)5BE2dCcEYUytiTFTsAPxhqjrhgL7hLPG32J0eGYTDtJbZosg(L5jPCVNWKu0NeeBEDY1T0dgfrxEx6LvmCEn6v1sCrNsCOTjDbIZRAys9sjTJmL)RxNf4lwTo6SZqVfU6Se5lwCLZVz2y7adzXnpUQVV015Kw7B1AnzsI8uY8QMm0w2CDPOfTVODeRTMG2U9BA0H5ytteISlu2aAOoZIQQCA1GSOFpgnlUi6FW6PwljgROKvsjNhYeAJ0vr0NHnD)vV2KWzNj(x)eWDVBhbCpFfOzZd5fEW2y4jdWvSC)dCXXdn7ii1Ma4UJBE0dA7t)h1FxD6pKpV(9so4puGa92lp(SU7HVZaD2rp8D4ZV)oH))BwY702nnkjRjEB7lAJHD6kYzARVUpxFL9fVjyN7Cxa2XRfhh85H98Qvtr7WrijGdcR)rq2Z4yvA5RMI20BHLRlvqsKMGNvtzh6Di5sajNAnQ)bgVCjKUID(HFK6Eabnjrp9jPJQV84KD04JteLvnPJOLhupRGcIkJR(xHZLEO(hXXsTx)iSpDeAEIeZu6cA13AjZkysUGQCQso(8y3IJK8XI7DS)R1m8XI7av2uqwCTqoCxBmxES4ouL04XI7W1sGhlUJahyVwC3nG9v5EUnlU7Tv(iwChfF2XYBXDFwC3Vf3dqtfhlUhSwo44yBPxjNomS4EO1N)nC7iPFtVteAIO(Vy8z9pbXeSTsg1Z6mXq91BGU7K5v3MmpUr)5wIeU7GYZku2OYAvnCPghEX6W3BHVD(fukVtefM8BtJVcUTsOJ6tuulUppj252FKksZKsnfswFqFPkgS48njIklc)I8uPub3PsQWhT6(ZBjvLkWS1TNJsdVmKSAoJhIq5CuJh1Ug)x4FZtQznd53oA62GF(FPQ4HYnETlDku7A0v)TDARETdbkVoiGf3lBt69ErVdj3ENzI57CnH0)j2Xj912gawCFLgrY3PiKx4pUHeYfRQdAxdveps2mQyBXn8EMoLJF6z4Bcv8tU7Lko0R2y2rNMmSRHqo0RUPes)dOYRnyUb7TRKnHq(PUrMq6u7COo82zGMzJtZi6PETnzTwRAm4wMUplD1g9iNUVEfOoEBVlCQJOprFDoXCbmlKsVzYGFHRJQF3eIUdqXR8MGs3o)knMGxZk)BmyXV6OYTpvSo0VySb8wwSju5xCxRm6inMDDzh(ITBM8LQTb6qqXNq7Lc0eY3V7UxvSBs06T429yN76ddVdYNiYiUSVbZnqPML0yF6DVKVnjfcT4MA3mxxWC9wm40z47vyIMq2(m7AjBFJnjRMRBrNUXGaU9wm9VXfA86H60CNzvuhQhJCJP0SvB4ZU7LvC4NOXoR4C5c3nrtjdOTIOkgzUWzmmNp1eZ1eI6N7TmIkD5R)yWEoQJDU5PlkLDAk1WO6Q36761I3gA4O9L6nV1VT23yKe6QzB0s3(J3rw62(7mBIqdfX7id052E3Ftx(1WYQkiJ0vCuSlFb8ETT9(VrowKxz6)(wmwQa5rJXp9mzg)05Bcl1Rwj2rRJLIgl4EzbpIq3ir9za47WIqen4q(iOU(S)T)0eImz70fGg7NgWa6SfjvShCB2szUwM7xCffePqrgD8rG9CoNFyL1LuMgz6HChTwRw84K9dQ6uEmZJ80NQUHW0ifwDQTpRJQGkuUsd4ydDt0B6jOEbKOJVBq0K8MTyrEiBNWgTTSXm93XogtV)uJM4npE(vQXZxkrd44f3z2S0I9fX)afgFMUu8VDy5)aKSBzbjtub6EgU0hLLpEpEAiU290G9lCmCnBNLHEy1QRX2zIvdoaEkNUTZQ0EybiKn(vbhzsJf3BSVpXpR2BXI77xT5S4(bSTF2pKUHPH19yX(cxDp2V)v0J1WvMk91d97xLbV(VIjaYu0)zJvkbQyBrAIaOVZoUo9RW0vydgI9dQyi2d8EBOHyAhQrswUITil9BHwKHhznJY5TV4d1vVfAxoxZOCV(B1uoscxgx3(di)r570V)E9dJY(6oAxAASQgFKn3K2HO7yxpKuGYtYIzZIiFtHjb(D(3mTyE7XrDecDzD0KUMQxFDgrDm0aNTj0KV7ne0elU)2tfYxN9s3k5(OBLCF(O5k9pctqATlVKQyrvfEJ4hONT2GSyxR(ZwHOAwuR35hQ7okhSje1)Yk2Of7TiI6pYI71sx5BIwhE7G8DqZF3eQR)E8s)M(1ZYytJi7JBYx)YfeMAkuwtm7f5tZeEOVgzR2lPGsWQt6DpFRM2bHcF5)SnL3osVLcEXsXN5C9xQjWGV31lyqlfArSfXl9a19P38IqVWpKMJTy30)wKUQ9NjtYNiZ3yF3y)jYeBu8g(QyE6ZDUZgnS2CZB0rd(Qy2IbFhNmWj92sPB59))a
```
