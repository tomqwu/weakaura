# Paladin — TBC WeakAuras (All Specs v5)

One import string covering all three specs. Elements load through Spell Known gates, so
the HUD adapts to your talents with no action from you.
Toolkit setup, once: `cd ../../tools/tbc-weakaura-creator/scripts && ./setup.sh`.

## All Specs — v5 (`all-specs.txt`, seed 20260811)

The full Holy / Protection / Retribution HUD: 43 auras in one import, arranged as a top-level
group at (0, -140) with five draggable sub-groups — the fifth being the PvP column added in v5,
which only ever loads inside an arena or a battleground. Every trigger matches by spell ID
(never by name), so it works unchanged on a zhCN client. `internalVersion` stays 45 /
`tocversion` 20501; modern WeakAuras migrates that forward on import.

## v5 — PvP layer

Ten new elements plus the dynamic group that holds them, and **every element carries its own
instance-type load gate — `arena` + `pvp`, or `arena` alone**. (The container group itself has no
gate, exactly like the four groups already in the pack: it draws nothing, and gating each child
individually is what lets the column close its own gaps.) In PvE — raid, dungeon, heroic, open
world — nothing appears, nothing moves, and nothing about the v4 HUD changes: no existing aura had
a trigger, gate, size or position touched. Re-importing is still an **Update** (no existing
`W.uid()` call was added, removed or reordered), so your dragged positions survive.

**This is not diminishing-returns tracking, and must not be read as one.** WeakAuras on TBC has no
DR prototype, no DR type table and no bundled DR library, and faking DR with an 18-second timer
models the *reset* window rather than the category — it is wrong the moment two spells share a
category, and a DR tracker that is wrong is worse than none because it gets trusted. Every CC
readout below shows the effect that is running **right now**, with its own remaining time. Whether
the next stun lands at full, half or quarter duration is still your own count.

### New: the PvP column (dynamic group at (150, 96), mirrors the Alerts column)

State readouts, growing downward, on the opposite side of the character from the alert flow so the
PvE layout never shifts.

- **Trinket DOWN** — visible *only while your PvP trinket is on cooldown*; absence means it is
  ready, so the column is empty in the normal case. Desaturated with a swipe countdown. Decides the
  single biggest PvP question a paladin has: ride the stun, or spend the medallion now. Tracked by
  exact item id (Medallion of the Alliance/Horde, and the level-60 paladin Insignias), never by
  equipment slot — a slot tracker would report "trinket down" whenever any *other* on-use trinket
  was ticking, and that false alarm costs a life.
- **Enemy Trinket** *(arena only)* — a 2-minute countdown per opponent, started when you see them
  trinket. While it runs, their get-out is gone: that is the window your real CC chain and your
  kill attempt go into. This is an **inference, not a read** — no API on 2.5.x can query another
  player's cooldowns — so an opponent who trinkets out of your sight starts no countdown, and an
  opponent still using the old 5-minute Insignia will be shown as ready long before they are.
- **Forbearance** *(arena only)* — one icon per team member carrying Forbearance, with the time
  left. It answers the paladin-only question the default UI buries in a debuff row: who can still
  be given Divine Shield, Blessing of Protection or Lay on Hands. BoP-ing a partner locks *your*
  bubble out of them for a minute, so this is where "which of us survives" is actually decided.
- **CLEANSE** *(arena only)* — one glowing icon per team member holding an effect worth a global,
  showing **which** effect and how long is left, because with the strongest dispel in the game the
  decision is ordering, not speed: Polymorph, Fear, Psychic Scream, Howl of Terror, Entangling
  Roots, Wound Poison, Crippling Poison, Viper Sting (all ranks). Filtered by exact spell id, never
  by dispel type — a "magic" filter would fire on every trivial magic debuff and still miss
  physical CC, which has no dispel type at all on non-retail.

Both clone rows read *group* units, so they are arena-only on purpose: in a 40-man battleground
every stray fear and every other paladin's bubble would push another icon into the column, and a
wall of icons is the same as no HUD at all.

### New prompts in the alert flow

Same language as the rest of the pack — glowing icon, slides in from below, flies off on exit. None
of them takes the usual in-combat gate: the opening Sap, poly or Hammer all happen before the
combat flag, and the arena/BG gate already keeps them out of the rest of the game.

- **CC ON ME** — appears the moment anything takes control of you, shows *that effect's own icon*
  and counts it down. Which break works is what the icon tells you: a stun means the trinket (you
  cannot bubble while stunned), a fear means trinket-then-bubble, a root or snare means **Blessing
  of Freedom, not the trinket**, and a school lockout means your Holy spells are gone for the
  duration so the answer is the trinket or distance — never another cast. This is also the only way
  to see a Kick/Counterspell lockout at all: a lockout is not a debuff, so no aura trigger can find
  it.
- **HAMMER NOW** — a paladin has no interrupt, so the stun *is* the interrupt. The prompt exists
  only when both halves are true: your target is in the **last 1.5 seconds of a cast** *and* Hammer
  of Justice is genuinely castable (cooldown and mana both checked). If the target is outside
  Hammer's 10 yards the icon desaturates, which reads as "close the gap first" rather than "press
  it". There is no filter for "casts I can interrupt" — WeakAuras disables that argument on TBC
  entirely — so fake-casting still beats you; that is a player skill, not a HUD feature.
- **TARGET IMMUNE** — stop. Judging, Crusader Striking or dumping Avenging Wrath into Divine
  Shield, Blessing of Protection, Ice Block, Cloak of Shadows or Divine Intervention spends the
  whole set for zero; The Beast Within means your stun is wasted too. Hostility is checked
  separately, so your partner's own bubble never fires it.

### Cooldown row, PvP additions

Three more 32x32 icons, same swipe/desaturate/out-of-combat-fade language as the rest of the row,
and deliberately **no** gold ready-glow — these are held for a moment, not pressed on cooldown.

- **Blessing of Freedom** — the answer to every root and snare, i.e. the reason not to spend the
  trinket. Whether it is up decides which of the two goes.
- **Blessing of Protection** — the peel, read next to the Forbearance row it will burn.
- **Hammer of Justice (Holy, PvP only)** — v4 hid the shared Hammer icon from deep Holy, which is
  right in a raid (bosses are stun-immune) and wrong in an arena, where the stun is a healer's main
  peel. This copy carries the exact inverse gate — Holy Shock *known* — plus the PvP gate, so it can
  never double up with the icon Protection and Retribution already have.

### Not built, and why

- **Diminishing returns** — see above. Not expressible without custom code.
- **Enemy cooldowns and enemy spec** — no API on 2.5.x reads either. The enemy trinket countdown is
  the one sanctioned approximation, and it is labelled as one.
- **A Will of the Forsaken readout** — TBC has no Undead paladins (Human, Dwarf, Draenei, Blood
  Elf), so the second trinket charge that element exists for cannot happen here.
- **Hiding the threat bar inside arena** — the inverse instance-size gate needs a field check first
  (WeakAuras only assigns the size value inside instances, and if it is nil in the open world that
  gate would silently unload the bars everywhere outside one). Until that is confirmed in game, the
  threat bar keeps loading in an arena party, exactly as in v4 — a harmless extra, where the
  alternative risked breaking a PvE element.
- **Enemy health frames and an enemy cooldown wall** — Gladius already owns the first, and the
  second is unreadable inside a stun.

### Field check before you lean on CC ON ME

The Crowd Controlled trigger is the one piece here that WeakAuras' own source cannot prove works on
a 2.5.x client: the prototype was deleted for Classic flavours in WA 3.5.0–5.1.x and ungated again
in 5.2.0, and it reads the loss-of-control API rather than the aura table. Get sapped and kicked in
a duel once and confirm the icon appears. If your client does not populate that API the icon simply
never shows — nothing else in the pack depends on it.

## v4 — each spec sees only what it presses

A Holy paladin reported the pack showing them buttons they never press. They were right: the
gates asked "can this spec *cast* it", when the only question that matters is "does this spec
*press* it as part of playing well". Three more elements now carry the inverse load gate
(`not_spellknown` = Holy Shock 20473, "not deep Holy"). Gating only — no element was added,
removed or moved, so re-importing is still an **Update** that keeps your dragged positions.

**Holy no longer sees:**

- **Judgement** (cooldown icon). Protection and Retribution press Judgement the moment its 10s
  cooldown is up — a numbered line in both rotations, and what the gold ready-glow means. Holy
  judges on a different clock entirely: Seal of Wisdom → Judgement of Wisdom, refreshed when the
  **20-second debuff** expires. Because the cooldown is half the debuff, it was off cooldown
  every time the decision came up, so the glow sat lit for most of every fight — a permanent
  "press me" that was wrong more often than right. The decision Holy actually makes is already
  rendered by **Paladin - Judgement Debuff** (own-only, 20s, on the boss), which stays. So this
  removes the false prompt, not the information — Holy paladins in a raid without a Retribution
  paladin should still keep Judgement of Wisdom up, and now watch the debuff timer to do it.
- **Hammer of Justice**. A 6s stun. Protection uses it to interrupt casters and to pin a runner
  while gathering a pack, Retribution carries it as its only interrupt; for a healer it is a PvP
  button that never enters a healing decision, and raid bosses are stun-immune.
- **Hammer of Wrath** (the execute prompt). It keeps its own `spellknown` gate on 24275 and adds
  the inverse gate on top — WeakAuras ANDs load conditions, so it now reads "knows Hammer of
  Wrath *and* is not deep Holy". A glowing damage button on a boss at 19% is not a healing cue.

**Deliberately kept for Holy** (a false cut costs more than a marginal keep):

- **Divine Shield** and **Lay on Hands** — genuine panic buttons, and bubble doubles as a debuff
  wipe. With Avenging Wrath gone from the Holy row since v3, these are the only Forbearance-
  burning presses left in it, which is exactly the pairing a healer needs to see together.
- **Threat** — a healer who pulls the boss off the tank wipes the raid, and the bar self-hides
  while you are targeting a friendly, so it costs a healer nothing when it is not relevant.
- **Seal Active** and **Judgement Debuff** — Seal of Wisdom → Judgement of Wisdom upkeep is the
  Holy paladin's one non-healing job when the raid has no Retribution paladin.

Protection and Retribution lost nothing: Judgement, Hammer of Justice and Hammer of Wrath are
all in their published rotations. **Seal twisting stays gated on Seal of Command (20375) rather
than on Retribution's capstone on purpose** — a Sanctity-Aura Protection paladin who takes Seal
of Command does so precisely to twist with a two-hander on fights they are not tanking.

*Requires WeakAuras 5.4.0 or newer for the inverse gate*, same as v3: on an older client the
unknown field is ignored and those elements simply load for everyone, exactly as before.

## v3 — seal twisting + spec-selective cooldown row

**Retribution seal twisting ("swing dancing").** Two new elements, both gated on Seal of
Command's own rank-1 id (20375), so they appear for anyone who can actually twist and stay
hidden otherwise:

- **Paladin - Swing Timer** — a slim main-hand swing bar under the resource stack. It drains
  toward impact and turns gold in the last 0.4s: that gold band *is* the twist window. Note
  the bar does not exist until you start swinging (the WA Swing Timer trigger produces no
  state while the timer is not running), so it appears on your first white hit and vanishes
  when you stop.
- **Paladin - Twist NOW** — an alert-flow icon that is present only while Seal of Command is
  up *and* you are swinging (both triggers required), and glows gold inside the same 0.4s
  window. That glow is the moment to re-seal with Seal of Blood (Horde) or Seal of the Martyr
  (Alliance); both are already in the seal list, so the seal readout follows either.

Twisting is an advanced, high-APM play. If you do not want it, untick these two auras in
`/wa` — nothing else depends on them.

**The cooldown row is now spec-selective.** A healing Holy paladin was being shown
Consecration (a threat/mana dump) and Avenging Wrath (a damage cooldown) — buttons that never
enter a healing rotation, sitting in the row where their real cooldowns live. Both now carry
an inverse load gate (`not_spellknown` = Holy Shock 20473, a 30-point Holy talent), so they
load for Protection, Retribution and shallow hybrids but not for deep Holy. This needed the
inverse gate rather than one copy per spec: no single spell is known by Prot and Ret but not
Holy, and duplicating the icon would double-show it to a 21-Prot/40-Ret hybrid who knows both
capstones.

*Requires WeakAuras 5.4.0 or newer for the inverse gate.* On an older client the field is
ignored and those two icons simply load for everyone, exactly as in v2 — it degrades, it does
not break.

Audit any spec's actual element list with `lua5.1 tools/spec-preview.lua paladin`.

## v2 — rotation fixes

A rotation review judged v1 against one standard: every element must change which button you
press next. Four things failed that test. v2 fixes them without adding or moving a single
`W.uid()` call, so re-importing offers **Update** and keeps your dragged positions.

- **Seal of the Martyr (348700) and Seal of Corruption (348704) added to the seal list.**
  These are the 2.5.1 Alliance/Horde damage seals and were missing from all 36 ids v1 knew, so
  an Alliance Retribution paladin — running the spec's *default* seal — had a permanently blank
  Seal Active icon **and** a red SEAL MISSING alert glowing in the alert flow for the entire
  fight. That is the worst failure mode a pack can have: the alert that fires when nothing is
  wrong is the alert you learn to ignore. Same fix covers Horde Protection on Seal of Corruption.
- **Hammer of Wrath is no longer Retribution-only, and only fires on hostile targets.** It was
  gated on Crusader Strike (35395, a 41-point Ret talent) even though HoW is baseline at level 44
  and is an explicit numbered Protection priority line — a Protection paladin never saw the
  execute prompt at all. It now gates on its own rank-1 id (24275), so it appears for every spec
  that has learned the spell and stays hidden while levelling toward it. Trigger 1 also gained a
  `hostility = hostile` filter: targeting a wounded *ally* under 20% no longer fires a glowing
  prompt for a spell that cannot be cast on them.
- **The press-on-cooldown buttons now say "press this NOW".** Judgement (10s, off the GCD),
  Crusader Strike (6s) and Avenger's Shield were passive icons that only desaturated while down —
  the pack never once told you to press the buttons Ret and Prot press all fight. Each now
  carries a gold pixel glow wired to `onCooldown == 0`. Consecration and Holy Shock deliberately
  stay passive: Consecration is a mana-permitting filler for Ret and Holy Shock is a Holy
  emergency instant, so a "press now" glow would push the wrong button.
- **The cooldown row breathes with the fight.** All eleven icons gained the same
  `inCombat == 0 → alpha 0.5` fade the health and mana bars already had, and the ready glow is
  forced off out of combat, so the HUD is still while you ride around.

### Not changed in v2 (deliberate)

**Seal twisting** (Seal of Command R1 → Seal of Blood/Martyr in the last ~0.4s of the swing) is
the Retribution skill-expression line and is genuinely missing — it needs a Swing Timer trigger
and a design decision about how loud a sub-second window should be, so it is left for a future
version rather than guessed at. Also unchanged: **Threat** still paints held aggro red for
Protection (a tank's goal state), and **Consecration / Avenging Wrath** still load for Holy —
both would need either negated load gates or duplicated per-spec elements, which is a redesign,
not a fix. Exorcism, Blessing of Light, Divine Protection and a Holy seal-missing alert remain
uncovered; they are new elements, not corrections.

### Resources (bar stack, group offset (0, 56))

Three flush 172x14 bars. **Health** (green) and **Mana** (blue) are always on and fade to 50%
alpha out of combat; mana turns red below 20%, because mana is the paladin resource in all three
specs — it is what ends a tank's threat, a healer's raid, and a ret's uptime. **Threat** only
loads in a party or raid and only fills while you have a hostile target: green normally, orange
from 70%, red once you actually hold aggro (for Protection that red is the goal state, not an
alarm). A red **Threat Flash** pulses over the bar at 80%+ threat, gated to Retribution only so a
tank at 100% is never nagged.

### Buffs (icon row, group offset (0, -16))

Four 40x40 timers, left to right. **Seal Active** matches every rank of every seal
(Righteousness, Crusader, Command, Blood, Vengeance, Wisdom, Light, Justice, plus the 2.5.1
Martyr / Corruption pair) and glows in the last 5 seconds so you re-seal before the 30s window
closes. **Judgement Debuff** shows your own judgement on the target (own-only, all ranks of
Light / Wisdom / Crusader / Justice) so you know when to re-judge. The third slot is spec-shared: Protection sees **Holy Shield Up** with its
remaining charges in the centre and time at the bottom; Holy sees **Light's Grace** instead,
glowing under 5 seconds as the cue to land another Holy Light before the 0.5s discount lapses.

### Alerts (dynamic group, offset (-150, 96), grows upward)

Seven glowing prompt icons that slide in from below and fly off on exit; the stack re-collapses
itself as prompts come and go. All of them are combat-gated, so nothing fires while you are
riding around. **Seal MISSING** appears when no seal is up — one copy for Retribution, one for
Protection, because a single load gate cannot OR two talents. Holy has no copy yet; that is a
gap, not a principle (see *Not changed in v2*), and it costs a third element to close.
**RF MISSING** is the classic Protection failure alarm: Righteous Fury off while tanking.
**Holy Shield NOW** requires both conditions at once — buff down *and* the ability off cooldown.
**Hammer of Wrath** appears when a *hostile* target drops under 20% health *and* HoW is ready,
and re-pops every time the 6s cooldown comes back, which is the "press it again" pulse; it is
baseline, so it loads for every spec that has learned it rather than for Retribution only —
minus deep Holy, for whom an execute nuke is not a healing decision (v4).
**Lay on Hands Prompt** is the panic button for every spec: your health under 25% and LoH ready.

### Cooldowns (dynamic group, offset (0, -66), grows horizontally)

Eleven 32x32 icons with WeakAuras swipe text, mouseover tooltips, desaturation while the spell
is down, and a 50% fade out of combat. **Judgement**, **Crusader Strike** and **Avenger's
Shield** — the buttons you press the moment they are up — add a gold pixel glow while they are
ready in combat; the rest stay passive readouts. Only two are baseline for everyone —
**Divine Shield** and **Lay on Hands**, the panic buttons every spec presses under pressure.
Four more are baseline but hidden from deep Holy by the inverse gate, because a healer never
presses them: Judgement, Consecration, Hammer of Justice, Avenging Wrath. Five are
talent-gated and sit at the end of the row
so the shared part never shifts: Holy Shock, Divine Favor and Divine Illumination for Holy,
Avenger's Shield for Protection, Crusader Strike for Retribution. The dynamic group closes the
gaps left by whatever is not talented.

### Spec gating

No spec picker and no respec chore: every spec-specific piece carries a `Spell Known` load gate
on a signature talent, and the pack reshapes itself the moment the spell enters or leaves your
spellbook. Holy is gated on **Holy Shock (20473)**, Protection on **Holy Shield (20925)**,
Retribution on **Crusader Strike (35395)**; the talent cooldown icons additionally gate on their
own rank-1 ids (20216, 31842, 31935). Baseline-but-late abilities gate on their own id instead of
on a spec — the Hammer of Wrath prompt gates on **24275**, so it exists from level 44 in every
spec and nowhere before it. Threat pieces add an `in group / raid` gate, and every alert adds an
`in combat` gate.

Five elements go the other way with an **inverse** gate (`not_spellknown` = Holy Shock 20473):
Judgement, Consecration, Hammer of Justice, Avenging Wrath and the Hammer of Wrath prompt load
for everyone *except* a deep Holy paladin. There is no negated form of `spellknown`
(`use_spellknown = false` means *ignore*, not *must not know*), and no positive gate expresses
"Protection and Retribution but not Holy" — no spell is shared by those two and absent from
Holy. One aura with one inverse gate also cannot double-show on a hybrid the way one copy per
spec would. Audit any spec's real element list with `lua5.1 tools/spec-preview.lua paladin`.

v5 adds a second axis on top of that: every PvP aura also carries an **instance-size** gate
(`arena` + `pvp`, or `arena` alone for the pieces that read arena units or would flood a
battleground). The two gates are ANDed by WeakAuras, so "Hammer of Justice (PvP)" means *Holy, in
an arena or battleground*, and the Cleanse row means *knows Cleanse, in an arena*. `spec-preview`
does not model instance types, so the PvP auras show up there as ordinary extra entries — the PvE
per-spec sets are unchanged from v4.

### Regenerating

```bash
(cd ../../tools/tbc-weakaura-creator/scripts && ./setup.sh)   # once
lua5.1 generate-all-specs.lua                                 # from tbc/paladin/
```

The script is deterministic: the fixed seed `20260811` reproduces the exact same UIDs, so the
output file is byte-identical run to run and re-imports in game as an **Update** rather than a
duplicate. It also runs `uidContinuity` against the existing `all-specs.txt` before overwriting
it, so future versions report `changed=0` for free. When you extend the pack, append new
`W.uid()`-consuming constructors at the END of the script — never reorder or delete existing
ones. Contains zero custom Lua code, so the import dialog shows no code-review panel.

Importing: copy the whole string below → `/wa` in game → Import → paste. Note that the `/wa`
editor preview force-shows every aura with fake data and ignores load conditions — judge the
layout there, judge the behaviour in combat. If you re-import over a pack you have dragged into
place, uncheck **Arrangement** in the Update dialog to keep your positions.

## Import string (v5)

```
!WA:2!TZ3E4nYv5DNtCwyxLB769sYUSbu2KDXox2insYskKqQKS8TylRDKS9UBwI1iPJKM1JMz2zgzBzGaXKcBPCRM008qP0uxkTFuAj4EHpEO9HNU0q7FaF99XCBA5w7wkfOaLUT9RqVFoNzK0izzlN9siRd)HpE052CMZ537VZ7775Dg0KDN7zURZ(QwnRqUzYRPOgtrsrBKU6QRKD55Obu7oNISHMIKeoFSsIs51WYNuDNjfKeYlk7(EDpewqYO05BKXycYcoRq6sAybd191AoUhqsqVK6EBKFQ5eLl6oTyzS25ZQOLhRf1EmPUZOsIlSGGwE3PvuKmevZQkqgjgQ3sTMNoAmsxersYDkvCo9veLlOOvwWqur2vwRERKw1XluqhBCML1WfjfKUQkMVOMsf1LTQrkXfWBBvHkgLu0gxL2wDxRyvK10ccH6klzgPGyrx865eKWDPjKJvX(41ne0mCLTGOSOEjxrj)ZW1IgAIflI10tCen7lFQOg07RqfnbUZrt1vXssI51pq3EIwH0OSQscvXAlYYF486UoVELS4zjpUPQuOG48RmDSiPspDQ0r4txVOKAysr8PsgF0rVqfDC85jJRuw9qgEzHYyDxlNhNL0d0hBTHIpAYbMy0LQiBpSCTsEr9txrM80mlMtqssDxcSRtBv(yk5XFKRzjbzrRz1(GBzGZHf0XPmiRefnk9YHdgvwrgVAEYZeTgttFo10XK5R86lsRk9odEIwwquEa4(ina8aEboWh5)3AR5CoRjERLSDCbrzdSMSG0KKUK05pYs6yPcjvizNnw8ePJZFiX8Q7UbAIhRRurlhwFzdLCZA1OTNCVRuqJmxqgZcgcDDbb5CKL6bOzrhBztfJpE8eRyLnRZHqCveZVc)yjpzXaHprF4q2aIHLjdRUwMm)ZZatKPxRcINViwDxPotfcc19aviiYPkjAGxMoniAHPIkPiK3L28wpBOZ6zzDcEEMPeZBuAVllsQzk2y)Gxd4ccd30x9AGxleAvwL4vmyZUi1D10VPRprJmr6XJsBFj4ap6rGxXtrMqFvWHG7GNbsYAjTsYYnC7UwKatMMc4Ya3jCy4v7c6b6fUlxoBhKqDptqQI7yLeOiDSMOUHyoD7Uas2sBH7gUh4E)ixd7Hy6C14s6c67rGGqOfZkyljL868CuVbOPbdrt5c0fbEQlyqbp4sNJ9Szn)Ccee9(3hCWvOclKoyAYFNDFQDBGN3yA9sc5vM742ZKlXYJMOUZdtaF5ip0LypZh(WQ70rdAioFERCRbMGrv3nlhclGcfPNJTQenc5NxGvarmdNNL5JVQfq5e239ZXk)0viZqfQcHwwJU0GttYmAIXtehoOgbTqRZYSk2y2XAyxGW0QUZb0exW9XQiKNIqDNoTQN6pttBrPnDtpytNhNJisknTQg5cDgYW5utTb3QS8MJarNstqDXPSVy163AgTW4tKE0Hte3EUYHCWkdNirC(P5hEWHsR2Bhgsekv58mXF(cskkAwtmZsgDzLWzAClP8T73EsS2sO6H7qNBLz2evkNfRnlCWLitQwsERA9p7HnhbMulhf7fi7FMRXQVDo1gB2c3tJjcXq)1(LozC2v2syXILmUnyGjxIk5KJS)LEMSgKnbKn2hF5kK9LCXZY9iz1jBLjH1sgz0i9pCc4X3h8ezIsi0ZTp4XDfL2F0lopdLhL0b5PIVCr6VF1Ds67i5PGiCEC(XeMVKf5qSgYsD7c2JRwROirM)M1SfrCk(CCeCukzDReU(7mf8smPyDX8yE2cpSpsh5cUvxW(DfDbfLYOvy3OHyZmpOgDrRIgMpMewqMxqsTKqxwdL0wLO2ZWuA8cc5WNkMarorUyubTtnXW3BJFDVPy0ASMvcUFcNnHzh6cgebVMU4NJk49N6cEa4bHhAf8utMmVup(YMVhnrzklpUK9qsmFESmFI4tgNFffnrYAeJMC5HgNF4toEI0rgfIFGJWNReo3mdaVITT4ScAIcemWIIYXukNvWGFwbPky0Huup0d(GA5kjixeRFGJalZ0mArvIIjynJQWtc3GRlqvFQid3xNAHwTGN1dm0EHHRXK)hHOm5Wii4HHrHXSPP)dBq3YNuzoSgLEDjv6vuHiutmTRsbF1lltBjTHJ1jcAG3jVmKAe6O1lLj2pJvoCGUG0LGjS5EHjp7(GPqWXVqnAv2i4WhgojtocEeYJZPGxh8OpomncYq6sbilPD5G8w3imuakHu7z9KUz9NdMdqfeHtdZasqzqgotg17CJBQvEqfqB)Gos9(24AVwwtcvcmlmhmpufbly9u96ZaVbOF4n2f8yu5E4nLbEZubxyXJaVf4jSKRHFwwwVvw6Bdol8ZvcE7oKuHFEIKj8oG35fVGi8UG3TtHp49GGFHhewcEVWt2f8lcpf8l1qu56SevGNUUys)fhk58QNzHPc1l8(kb)YW7h(vGpae)Uoc8RsW(DbpZ5Co5alFiopeyF3pa8RtX7SnRdfOXw2EjGJpiKYQ1BdEg4xdw2woXQfmjesvOIgWVX6jm8(V2wfgs4egVSbZqbQ6hewwTIydcm(8u0FJcYqX4ju3PTnfPenQWeZzG(oH4zQDqhyHOj(ApG)Ch26UPMZOoAx9Ewd4QELAdYQ9chQ3(g0j1bZRrcYPurB2RSrx0KOetMGie1zq(Seq(k0jzcBm10iBeVM9pjxFeyNzIQjiMpZlQfd22AedwyYIgP9RCCVgdToIblvF6JideKkdCOxRnKEeMbX9XOjDG(jnIxOizQbwUlNsam(0WmHfoRuwJArEWTfK)ZudYVAd0nzmKb(OWZsPU)yzGp5Hc5HG1jQ2vFbMU9JGHIgDiMawPnq(lyVHmvrpQcgQ7j2OrgljXgHrJe7HjABmC6HNmoDmrwHOIK7Xv2YIAAkALysN3mzQnURLYwtbfYIA7x6kahmlbVt02G9BsXF6LzB)NSIKoEXAwe2Txwtw76kDnJUw5CTDj17VHYcrYNFCz9tnfwyMiutMp1y48IcNYwTc9tzzU10mlToQrrbEBLRT2vR2wBHcqL(jWccbafI8YyaJNKk4VOwn7QiaLrdn6u9f749evTaLHsDxetJZPHnWt3Owp2HZAPFFjyGNc()AlxaFIA7qyjn8MYWiSyMYpJSYCYTiZ8XZSCJY2(BpMT4ZtFDxFlCLVHU2qUsiXkoCFcfZyBFhrRL8mvaIsVc8VzifdeOrAFC1PfVlgTyhyq2Rfdc8zBEEOPh6p32h)x6fp8eV81YtmtXE7Xx80rIwTjEIduxK)845vfTW00jCyzoIEtuX)hObBbfVX1GUOfj)xfGQ7Kn4AhPj)GrSZXDeMVxupqJShPcXMKYK9OD3pZnoQ3QdVWPiv1DQsIyP8UNq1PZ2gLQzUU7bjgVJHTd7GGMUE6q5gjs43aImrVtyxBJoXVBRLsY8)EBwoSoq72Gx5b62tnflPGokJZrY0gLlVOx4cSdBOizL5cnEkIsEE1RZsqxLOcdp0kHc0F5z4cx07CCqKUGOUGyeCyCxWaUiRQN9oyYpdEpxhCtm9UxnNIIeXMyzIScr15Zv7Nux2ucglttpRpZr4584nGFEoVEcrs9WfkilnelnmnnShwQxwkhl1hpxqVbcWAfnhV9rt95jalTpwAqwAiwnP9MVG0sd71knelL2)H58qRtqp8(8gI0)KupEz9jRFcyLgKwhwoE7JDx8Z6F)SE2FywPEyL6N1pbYsklOhpw)Z)MAbTVh5cZGXQrOMWAWtb(LyegeQHO3)xA1IskZnGg(mvWY5QAPxvuAELohHdAqjB)TuAjAEPyUnDz6LJYCC4ExHEDn)uWQtdJDzLvZ3awEqHMd7oMUKyUzKX66DTi7NevDwnBfddf5XjMckjuL1xJksQYUy3VOw(b(S7MPz3HoS6ZtRxAO715SChs0XtNE8XaTBZs7QcmUX2YlESnN5d3mmgvyKGSp2iEdmlFzUZCAIiRj8NznoEpmnvxSgWntDwSVG6EQLjDtX(f1P2YsO(PmBhZwGKkLDqR9NTfiBjNBDn5q4diuGo5dOsFoOcHvHL7oGtUVmWhK6w0J69O05CkzZt2vnrrjKTOi8xLb(knK5(q2YCDtXPHSqX(zPwx3hdfZKNczH6zLsLZcsX1CE9gYhRugQ3JhwQxwQL8NLCzywDSKd6tJmznUSu1merGNTnIaAdfHFSbMy0MfemrxRtSVjQllaVj66kzI2g5VxwxMOx(EnrBhzI2bBDZe5IaEnrxVj6gi)4gnr3Kj6M3LjANxoaJMODDLacgva7)e5mYvsn0AHGMOD3a89fnr75kfsZvZaO7T94hBo7ryKMmAuUGSugjBWWBssUMwBh5Y3AR(f9AlPgA3U1s7LlKYTSzqkBcL4o2FCRiMhowXiliFMPYlhTdiMV0lwqmhGsf4Z)fd(4Qmz)nJA5)4wxrtKRsOjg8e9KuP3oSI(LVcUI2HDBmr71Ej3tuIL4ZDOjscx7hw9GTOs9ydNk1Wjg0Dp8yJEvVT1R0KeZ66vDpoojXbQvO6(BVk3jgFQMksOmXim3kfCtm82OKZB1OcvDRitQHCED3K7uzvdNhAz65e1nyDx3nYmwm3JNW9yXDoMgkYyJfNNvZBXrZJWpy80UhESXMirCM2(dkTd4M(tyWFlf8P(vph(gVu1WFfI91vklNI2zwwpM1sxiEbjXIYqinDdb6XgJOkLt0gVH1oAwhHmodXK75S7G921sf1eTovTRNABcvn(B(C5RkluwmhZXteZuIQROzaEwKwvQYEhIVFEjXYIgxp1u3rPxvkRgzUOI(tCdNpNImzmiBmGqodfTS8r6F4jsTKGwolToFI9rm2y5cvKKIjQLtcxhj7m4fIiH1m0H)CunZoOwprm04I2(gllCTOOEOvsx84tTGhFjNkwXZENWWiQLOBO6rhb(QWxd(6W3a(RH)g48WFl8nH)o4Bb)9W3g(oW3f(hGVh89HFa8pc)q4FcUa8pd)lW)k8)h(3GFe8JH)D4)a(pH)l4)g(FmrxJjcTkzDixjSEQskZnU8Q6S)nMOo90RUyyeVRgmI2mEBldHXJpP48yPM4fBYxYugscdAgl2tkjPf94gZN9wT5ZSyYySAlZoxo2H3KPvUT6(wHWTrd1bAqwmmbJOEKgEzI(B9tXCiZ0LiY3tRtygukKvsrjVfFiNVbWINP0S8twfCzIgFneI19RGjYxlmI0hNpn4tJgjeJxXG5LSv0LeZJZQqmAPm8CCK(GbvAdx5z35sSaoHzLJUHMa1WEMTuWbZMRIoPdYYQqv6qXpqU7h3kJ5TY4562l8Ki2rxYYot3vZVJUNhTeZrD0UDXADl9MVk5AzDj6bytksDx1klDTSjJml3vwlJmS(M1Bz60EZ)KaTBIoMjI)YiU2eLYbO(hI(kx2aYMO0z2i1TmrtOEhTIBfYkkjAuDAJsvKjM5MvrYWc02lFXbIJpDASppDe06V9GwcyIHxnrNaEot0jxFuQjIm3Dk600RZe9OnWIMOPDIdnrzQbanrcMOS0UYeLZeLN0zMimzsSWLfy0b45cemKNTyR(hUJSwfQOv1A9374YhBqFrcfwRZR)b2AS()Onw)hXeD3MO7XeDVMOJ2zuaPHNDx8esTCZeLgdqQ7IYQvelJ1eZzTrzMvB6NRyTVjpwiFv2b3Zwksiugtx1oip7N2bt1(Jz7KgQYFf1W66U7HfLE9Q2n7q3kkROHvMfRr0XbNzvYMfsPQ1DR4qNZvRFSc0syhdkD8BDw)lzZlNBMmQ7MEnMgnGoR(LiAVz3B)ckW)(2aGFwjmt3fLcQeL4XSaZ0seO)zdLUFTQLp28(7OiqFBDeb(w0ZhIbvkPOBW2Eid7CgBkKQoeNhibmo1lylvVEAwxHToljgWkzglHHMACg191C8zv7yj7(bCkrzIikasSwvM8qPyIuPckMOZS9h9ZtNN0Sepmr6MidsnQCHwSHYenxlyCt08Kkw9sgk)dV2bV4WVFO25ingK(8YkgooYpIz1wc3nNTnYNH5)C05HNx7UNtsq1cApLV59MfhiG)jhQJq7GBDG21pZCt0B8qKfylaS7MGRMO3m5VhFtHeFYxDBbINZPf7x5qHSWfWh7Ob76IKpTqDF7UwA0w8VBNuGGyAKIm98I1TGyfxiBpNSNGfor1iDeIfARdeZza19)Zgy9xyfpDq9tsVHRtoDtgJCLsrZ2U1BPRiB9w)u6THm396XjPA5WK1AUCp(0dEAVNi8yz57iWj8lyoqe(8RRdeVtlFgVowumldqyVQwJeiH6oJPPmxE3XQ)MYqxQ3u(n(YR9exMDNCDwfwGKqJz5sB8zhDeo1zvZWtFZCeYud0SoUxrMgP)04yvQAzfn1sw4L0P9oA5reseQNb6iE5(3cUxMA3Ay6BhdrhwN6rLikn8Oz6NvVCoVhnabkYuUREMzwt8(A1713yB1imLIDpb74HP7Cr2JtDxn02Ae6BVqoC72PJUF4zsh4sgzFrOW1LlK9(DGSTjbnrVZsBWzIqEEzqBt07Iu13DNG1oS)UmZtAwEnSxTb77yzh5eZF8ocRFnxvaRpq9y)9CwVMAY80WJVLWaMqTcP7iZ6J2yl03hxF(5I61dNhAcx0abchMNCvWq8(d43xiEFE548Z7ZV)GE59goyaU15O7RH9zrwVj6nKXrCXtRVj6XmrVP1p64VAJYE)Tqz7avVEK1TIOV3narNxCwrzm7vWJ(EKv3S6cNPxHcsrNrBGkDey)axvXx7XeXbFa4A)UncMUy97mk8ACGFS8jB(RJZzfsGQVYMkAnKRQVIMkpczkTin2nToTWd0uH9ZM5TD6tl3tNMM04yaTUNwEksj3mT0g7(BaHzj766UDfnSKuLYIYwpj32AhPyTxTETXZbBEoqRIUaX2u3Pm0eNb3s3h125m0jIb0W48kLvVJ1TgjR7ah17CJNnD3tYzt2R1PDsyxUNRZXPDAIEWDCPEuNMOxBT4J1e9ZqtIS2d10efLOdEm6jzAI6VXryAIId7ABMObacGAWdX3VjAic7XWKkpYtCdMOh2enQjAm2HrAIs04qiDCOW1Cz4vUZHCIc(f6VWX82tKuDGNUfZNxM66ZisZjuvVMdDg)(ARD0lvxWzdnI(59RX0LMlFE(y3ueRqOWe9e1nZ(TqJyInYqB6bsA)gRNXIXC2ZKoYPty4xmIoLX8py9JOct0VjHXSeJXmYLDlIU)6weTSICnewlVddSTVRxpt0NCTBVtSCQ9Vfq3LZ3ciY1L2Cwz9OTZfnF8AyRIFU27JgNKVVqbVUid5NlZamt0NWgynt1IIgs9LASKhVJaRFRRGaR7QzaZ6bO64Bn2fpmjDG2Ismrp9lvXgXtQosf8qtoLVE7i24)ZwASX2FdVJ2cooFZkH9swGIUyHrZQ0Rr157iq5dVLgOCN90wCYQnPp(v1WKnzSG3aCSWq8pCS5NPWPtozhbh)2BPbhRZzfzIEBV0cruvoFSjpH8yhpvGoIi(iBT3xHqX2oiXYnme)Q(9uEEe84nGi9DI4bfIRUa3491riYVZwBisIFu7TEXPlz2QdsiZbTbKmK8CbQglxUYru7ii53DlU(PzBlirD3TX7CB1blK5I2awoJVEYHh1ZuXNCKocw(OBXblFQ2dw2zRoQ9QCFU1jCYNQD4KWhBKO9fsFyFEMQJ4KN9fepTTH4KxC4HT3ES2hoET4A)T24jNVQinWtkPpn)Ks(MjsPSDep9X(P4jgEQ)iRZUzT5WGUQE3SnxWeqMoAZrVwdGLBMtp4PxOQxbvVDeGTYw6n2(Mpu7Hn7R9Nq4lbqoKzKna5On5uHMYyIs4t2z32979t99)wvqsntWxhuc2t)QQjgAIGJ0zV187F1bkHgLgr7F8Psq)ek58tmUMO8myd30IC(cshxgxUATsD(nxAafTSybnb5Cy1D54O3hnEKePSFvQZ3YRsTj6bVXlBbxax6XtUHHxqMlNHxWQnEetoBYRyXvWKPI23dp6SPsmb3zp86faKpgnmTwu0axM9kt9E)2wb1VCgiH6T2MxxQHj1SxROXMi6FERx(Q6NGnzI(CSxKk7(ldCWO0RDesyMOVY2FVFNg3ft0xTE3zI(A0UWe91Zqfu)gT0SHF2lQMP)0pVAgC3CcYvxdptMR88mxuHo2Nidn8X6T1WhB4eto9i45WsAvN2wIl5KjN2Jxl2i1ajlWNGpTE0fOSr)LBeB0x4kiB0M6vjLgGUj0S)G8FaE)CCH5yY1phNx6lpL6EyVKEUPHPR7uvYLdt)MmtJ8W39k1Fr9goFMxmTNYMBTEFodrWn9AmND4CpBpgh7y9TWGJxQJRXFXxawJVJnm6()mSOzkMKImwpJJ3D4GExrfRr)AZs)gyUOqHce1oPRUWopp9JnGOmoPv5zAdDVj6QJVHm7VJFdzg(5nMXoKNumcOe0B5i4cDef047c0W)KcfyI(U2R(pZTt)SIX7LleNFwAawAF8KKGEzPCrdemex0(486JMeiAiVCC0esd8ekuiAAyprd4pejJGHjnXNVWr96Ppsd9goanPVOHdfGJM4JNRVWHcZ71hh926JJJJL6JL6N(LSku4O(87jmbwgYd5sp(iDRFUGHPPHOFSa94LObX3Ze99PWtt0p4scsUrUF5jxVyD(fua5MuX4D)6BhWeF6JZ7nEpNXFQX6iW8lFLhy2D5UZ3D(Z(kB6ld6jHWGPjACI(60rODuUs)6D(z3ETVEN3q9VENwQFDP(17KQAzGDCXReO9xx3RNQyRTELSpDNp0kfkfl)iL1MySSds)mJsuZLOSP1NRtIKy368(oAGJ6P7zVU34)7p
```
