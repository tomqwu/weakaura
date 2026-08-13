# Paladin — TBC WeakAuras (All Specs v6)

One import string covering all three specs. Elements load through Spell Known gates, so
the HUD adapts to your talents with no action from you.
Toolkit setup, once: `cd ../../tools/tbc-weakaura-creator/scripts && ./setup.sh`.

## All Specs — v6 (`all-specs.txt`, seed 20260811)

The full Holy / Protection / Retribution HUD: 43 auras in one import, arranged as a top-level
group at (0, -140) with five draggable sub-groups — the fifth being the PvP column added in v5,
which only ever loads inside an arena or a battleground. Every trigger matches by spell ID
(never by name), so it works unchanged on a zhCN client. `internalVersion` stays 45 /
`tocversion` 20501; modern WeakAuras migrates that forward on import.

## v6 — the CC icon tells you which button, and the threat bar leaves the arena

Two things v5 shipped with an open question. Both answers are now confirmed against WeakAuras'
own source, and both land on auras that already exist — **no aura was added, removed, renamed or
moved**, so re-importing is still an **Update** and every position you dragged survives.

### CC ON ME is now colour-coded by what has you

Under a stun nobody reads text. v5 gave you the effect's own icon and a countdown in a red glow;
the red never changed, so the icon told you *that* you were controlled and left *which button
breaks it* to memory — and for a paladin those are four genuinely different answers. The glow now
carries the category:

| Glow | What has you | What you press |
|---|---|---|
| **Red** | Stun | The trinket. It is the only answer — you cannot bubble while stunned. |
| **Purple** | Fear | Trinket, then bubble. |
| **Blue** | Root or snare | **Blessing of Freedom — not the trinket.** Spending the medallion on a Frost Nova is how the next Hammer of Justice kills you. |
| **Green** | Polymorph / confuse | Nothing. Ride it: any damage breaks it, so let a partner clip it rather than burning a cooldown. |
| **Amber** | Silence or school lockout | Your Holy school is gone, so nothing you cast will land. Trinket **earlier** than the timer makes you feel you should. |

Anything outside those five categories keeps the red default, which reads as "trinket food" — the
right assumption when the HUD does not know better. These are the same five colours the other packs
in this repo use, deliberately: roll a second class and you already know the language.

The countdown and the effect's own icon are unchanged, and this is still **not** diminishing-returns
tracking — see the v5 note below, which has not moved an inch.

### The threat bar and threat flash no longer load in an arena

An arena has no threat table, so both were dead PvE furniture sitting in the middle of the screen at
the exact moment space matters most. They now carry an instance-size gate listing every instance type
**except** arena: open world, 5-man, 10/20/25/40-man raid and battleground. Battlegrounds keep them on
purpose — Alterac Valley is full of elite NPCs with real threat tables.

v5 deliberately did *not* ship this, because the gate has to be spelled as "everywhere except arena"
(WeakAuras has no "not arena" key) and it was unclear whether the open world even has a size value to
list — if it did not, the gate would have silently unloaded your threat bar everywhere outside an
instance, which is a far worse bug than two dead bars in an arena. It does: WeakAuras returns the
literal size `"none"` outside instances, `none` is listed, and **nothing changes for a PvE player.**
No other aura's loading was touched.

### Still not built: an enemy mana bar

A per-opponent mana readout is now a proven WeakAuras primitive on 2.5.x (the Power trigger accepts
arena units and clones one row per opponent), and other packs in this repo will get one. A paladin
does not: there is no paladin mana drain, burn or punish — Judgement of Wisdom *gives* the attacker
mana. Watching a healer's bar tick down would not change one paladin button press, and an element
that does not change your next press does not belong in this pack.

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
  it. *(v6 puts that decision in the glow colour instead of leaving it to memory — see above.)*
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
- **Hiding the threat bar inside arena** — the inverse instance-size gate needed a field check first
  (WeakAuras only assigns the size value inside instances, and if it were nil in the open world that
  gate would silently unload the bars everywhere outside one). **Resolved and shipped in v6**: the
  open-world value is the literal string `none`, so the complement can be listed safely.
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
loads in a party or raid — and, since v6, never inside an arena, which has no threat table — and
only fills while you have a hostile target: green normally, orange
from 70%, red once you actually hold aggro (for Protection that red is the goal state, not an
alarm). A red **Threat Flash** pulses over the bar at 80%+ threat, gated to Retribution only so a
tank at 100% is never nagged, and carrying the same not-in-an-arena gate.

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

v6 uses that same axis in reverse for the two threat elements: `none` + `party` + `ten` + `twenty` +
`twentyfive` + `fortyman` + `pvp`, i.e. every instance type **except** `arena`. WeakAuras has no
"not arena" key — the `size` load argument supports no negation — so the complement has to be listed
out, and `none` (the open world) is the entry that makes it safe.

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

## Import string (v6)

```
!WA:2!T33A0TXX1971Worc(Le1dBjlhdlBPq6yldSaGeWXoUaGGKGMeaAbiPKSQ5UayaWkUy3v7UGKGXXjMXXr1jnnLrnjnnn1LnnN)NEY50u(HMxoXjSPPNK62EpmPPB)N0MtvZ7NUQVssts7mZU4jbjOOKCSyYh0WfZm7SZoZV7V5EVZDwXmExzFM7(m3(kzeYovonf1ikskAd7WHJKoCFe)QDLvr2qtrscLlsrrPCAi5tOUJKcsc5eLDDVUgcjizu8C1ZyubzHgRq6IAibd192AoUgqsqVO6EQNFQzeLl4kTyjK25YOOLdPf2UpPUJWsIZnNGwoxPvuKmevZOkG7jgQ3C1BpD4i4MiKKKRuQOS6ljkNxrRKGHOISZmwTwrTkjYNxhzC6f1qfWfKUIkIRGMsz1fTQrkX5qx7kcLnkQOLqLCV6oxYQiRHfggghzWJi5fl4KtpRGeYHMqwAf7Lt3qqZWzM8IYI6fDgg)hdNZBOjwOastp(H1SV8Dg2G8CfkRjWUmjvxfjjjMtF)D5oCz8nLrvsOcsBEA(XYP78C6LZGMg)6MQC(8IZU0KrcLk9KPshIlDTIsQHWfXLkz0rg58L1rrNf3Vsz1c8CYcLq6oxmhkdUfiV2AdfDKKdm2iluw2UB5CPCI6NQSm(TzAeRGKK6ofOxN2Q8rvYH(Gx1ccYIwJQ9c38alJe0rPmWZefmk(YHdewwrgTso87ePgtsEp10r4XRC6ZtQk5jdUdxsquEa4(W3a4g8aSGx8FVLwZzzRbERPSTFErzdKMSG044Me34pYc6iP8jvWzNjs04PJYDqXCQ7QoAIdPRuwllsFrdLStBDtBl5EwkVgESa3NfmeCCEb5S4P6bizr6BzsfHlA04lzLnTXHaSLfZTe3Ojprb)bpEVOa2aIyY4ULJfXJ)CuWeE41QGO5kGu3zQtxgJqDnqzmICIIIgOfjddIwyQWskc5CQnR17gZzCVOogpp1eI5mkUNffX1mfTVFGRcCcbHB8RCvWRbcScTsCkg0rxg1D20VjZpHdnw6eHj3Fry)p6HHB9DIhqVD4GWDYrbjzSKwXz5cUdNZJHjtsaC8WDbhcELoHUHEG72zJ3hexD3JHRIRiffiiDKMOUHywD7Mas2Y9cVk4EG79dEv0xIjZwLlXb07Ja9bbMpJGTKuYRX9r84NK2xaskRFhy4PUGbb8GkUm9DZA854mq47FVWbwIiSGBGjX)7m7vTld0SgtQxuiNYmhZEKCbAEKe1DCim4ll(LUi9D(qhsDhnCd1fNpNvUvbtWiQ7IMdMfqHG0ZsNvchc)ZZtlalMHYrZ8jwXcOCC7N(Y0Ypvz8iu(kqGf1itnO04mdhpr8OWb0WOfsDwKwX6JowD78yMw1DmGM4CUoAzHCeeQR0PvDx7DAslkTjB6fBYCOSyrsPjv1WxOtrgno0uTZTcnVzWq0j0euNFc7lwP2JMslKyS0JelEu7XQgKdwkw84r5MKl2GdLwTNo0LWuQY5OI)C5Luu0SgyMg37YiH4R)ij8T7ZEqS6uO6H6qJBLzM4LlLbPnnCGfWdQwsERy9h7UnlgMunhf7ji7FMT(SVDov7B2c3tIWcXq)v)LoUF6itrKyHIg3gmW4lqKCYIx)sNpJbErazJ9YvQmEDjNC0CpCgD8szsiTKHgju)XIdpXEHNKpmMqp7EHNWzys7rU4CuuEyCdKJi(YgQ)(v3bUTdLJaIq5q5gvy2IwKdrQll1Lty3oBTIIyz(BsZwePrXNJXahHqw3kHRVotbVavkwxmhIJoXd7f3qoHBXjSpNHNtrPeZs0h0q0rMhuJmPvwdXfrcjiZjiPwuWHvxjTvjQDhJqJNxil6KreWYjYfclODYXIDV1)19MIsRrVTIW9J5SXm7Gdyqg4v7GBgIG3NXj8aWdcp0sOjgpzoPU9Mjx3AIYewEur7UKyUCizU4rhpk3skAI45ikn5IdLGl2jsepDOrGO7)WCzlIYo1aWTETZpTGMOagdmVOCeLszem4MwqQmI5GkQh8bFqTSffKlG03)HHfPAgnVkwXeKMrf4SW1788e1NkqX91OwivRVZ4ggApqSQm5pldHjhgMbEyyeyuBA6)860TCjvMbPrOxxqLCfriIPjM2viGVALX3wsB4ODIGg4AKxgsnmP36HWe7JYkh0VdiDrymBUxy8ZSxycg4yNVkTkThCOdbNGkhbpc(15KWVo8OpbmjdWJBsbid((Yc5SEqiipuKrT71s6M2EnWCaQGiCkykqckbYWP5vVR1)wTYdkdA7d0zuVV1V2RM1etLatdZaZcvyG5SERET8WJb9dVohWJtK7Hxpp8gicUW8hgEJWtAjxdVjAwpfn9ndNb(nkcpDdsQWBblzcVv43CZlicVn43QrHp4TZa)2piSa8oGZ6a(DG3j8UQlQCnwIkW7UMys)fgk5SQNEUjc0d8Ekc)EW7f(9H3he9Upm8hGX(oGNz5ghCGfpiRBmSVRha(Ji4D6I1b8xFjBpyWX7hszD3xl8mWFiSOTCI1DqLqWvHiAa)XRLWW79QBvyiEJW4fnOgkqu)aZYQvazGHXNJG(RxapbJhxDh22uKs0OmvmNc67eINQ2bPJfGK4T9a(LpK1ttnRrn0U69SkWvTk1gKv7fouVJ1PrQbMxLeuJsfTzTY6nrtIsuzcSquNb5pfgKVezqgZgtmnINQMizfRIwyFn7cWxFyyh8H1eeZXVwcetZHjJnQWZQonULW9rJkLeK5znqY8lAmdgXvjp2gd8YO0R5b38Vuqe6AxLi0CJxWiTpLJ5XyO1qeAHAd9y5N(iYph81ylomm1y6EPuSni5GVjoHc4btyrhnk9q5Idsf0yTsP3ulYsUSex(SvfxwPUKbUpWd)PWhIq7)NXdlFWaUXYjy1cRboilDjyOOr6IXHLAJ4Y5TxmNOKir5e1DhzKqJMeBFXiHI8WynvILo24rj9j8merCE3oZusuttrRivY(MWdTrDUqMQk3GNuB)uxE4azWYkynvO)gx8NFrQQdjllPJMVQ1KD5HElREELmNrMRACUDb17VUIgHYLlHS(jNajmviI52NCuuorHtARsI(jTmvBsQvAhXOGaNTI5wRiwDzXa(jmhyybM8GarEzuGXzjKgZRv1MmmqzKaJmrVrow3HvZty3u3j2S6SAid0K1R1JFOmw2gueg4daFuBjj4JvD1fl5h8InF4MfSOKFu3cmLSYmY8WhHOCy1FUTNoILmh8X5HNLh(e8WNKhEoE4trfRE3xZ11c)7J5yD5FH4l1GlziyjBBgXAcLJQwryYvGVncrRF)1t7LTgv7DtPA7aR0EGbMMmA8fAE8PjkNV42s8UEPZsWV8vZFmvHE62B00HcxPj(J9xJk4COzvfTW6KbCyrwSUyeAHhOolcbhYwNgPfgHBhyQ54o4QhUjFRHTDYviQ)Cu3F9ShUm2oNsyMxx9tDnK6T0GN9uKQ4kvrrKuoxJP2Od8gHOTVURb1WsxW2GTJrtxhPRCdyj)RNbpqVdyNxlzGFxwtL4X)90S8znG2TbVI93L7QkRsaDeMOdZ3gfw30tC(3UnuepZC(6VfHXVV61ypiZseHHhAPa(7V0uSbl4zgwiKdiSticghg1jmGt8S6zUtQ8ZG3Z1a3ivx(vYQOiHTZwglRGvhF5Q)K4gOIWO8n9U(mhMJ1Th)(4y94oao1nBG(OPbOPbjPbDtt9qtzPPE5y7ZJF)07IKJNEjPED7NM2lnTpAAaAnjTM3(iLg0JvAaAkP9dY6MuN(CZ51taC7JtD7H2M02XVvAFK6qZXtV0NIpA77J2Y(csl1nTuF02XFgCz952T1F8THMq79ro)uiKAiIzXgCeGFrkHbMAi89)LwPGKYmdOHoDzKC2kw6QfMKxXLXCqdkz7dNIlqYlf1vSlsUCeQZi3ZsKRR67dADQBanTSQ(BWYRmKCOpX0ffZoLmsx3X80FIvFALmLnmuKtGnVusOcTTgrexLDsFEHT8T8z2fvBXdEi1lqlIQRp3YwUyjCI0PtmkODBwASLNYn2wEXJUXmj5MGrjcJyK9rh2J)P5kXE6tHfz)QWFRv)4Tt1(D(Qax(ASyFz1DxntYIL9lQtSpgt9ty2oQTajrk7awRBBlq2so3YQYbZhGPaBKpGi91avi8pcl2L)g5(4H3pXvRhXZriJ5eYMZ6OQOOeJTOi8VWdNRUm3hWwMRlconGfk2hn166EPOyQ8ualupTuICwFeCnRhpb8slLI6D7MM6HMAj)zjxgKwhl5GE1WdwjKLWAYE7y9VwTiG2qH4gDGXgPzbbtMT3i23KXPfG3K56kAYC94)DdomzUX9yYCtmMm7GoVzYStm41KPltMDH)XUnzWfV3DAYCZxkaJMm3YLdiyybKVJN1iBr1aRgcAYS)6GVVIjZTE5cP5Sza092E8JnN9WustknkBF0ukjBFb3GKCnn3o8LU5w9n9ClUgA3H1u7LkKYnVrqkBaL4o6NOveZdhPqO5Kp9e5Kd3beZ)0lvqm7Nqf413MbFCfMS)grT8FCRZOXZwoWydE8UtQ0thMr)NVmoJ2HvBmzoG9uU7Wyl0N5GJLeU6)e1d0Ik1JglvQyXh0v3CiJEuVT1Q0KyZ96rD3nS7KduTq191EvUJNyIMksOe2imxk5DHni3OyJpQreQ4srgxd5C6UWpPsQgnUrOPNru3G2CDvpZirCLiURrJ2yFAOqJoAuoAnV5gU9qCdgnTRyJo6yXJs12FqPTd34NMc)TuWN4R(SOB4Ivd)LW2DxUKCksJzz9yglDH4eKelidb00neiBfndrPCS241T2rZABPr8ytXNXUb2JJfkOjATtDxhX2eIA830Y5Qilusml1fwyZucRROzaUNNuvIYEhKRFojXsIgxhXu3rixvmJgESOS(tE9NlRImUpiBmGqwdfTmCH6p2yPwqqlRLwNp5EXgBSy(Yssre1YkHQHKBmGicjH0m0H)oMQMDqSEcBOXM2(gllCTOOEOLsx4ytmNBVjNisHZCxqmgILORR6rhg(xHVg81HVb8nHVf8THVd8DHVh89HFa8dHxa(3GZd)7W)b8Fc)xW)n8JGFm8tG)h4Nc)m4Nd)VMmxLjdMu6QnzWSqxJjZ1AY8YmzE5MmBBf80r2Ii9ufvMjH8k60)mQOozJX2meJ3DDIrBIVRNht8XLuCwKut0Jn5MAcrjMiL3IeLWvAXsU(0ApLnTMfHgLCBr6w(r3xi(wP4S97cLIJeffK43iggQOE46oHI8B9tsDwZKfXI5tQJjiuYNrsrjNfTiR3bqINU40CJxbCAYm(Q4fR5EbtM7VfIrYRZNh8QrcYIeLnOorBjDjXCOmkyBxkbpplUnOiM2qzEMDSanwwOg7OBOjqSVNAsfCGmzlRJBGm0kuH0v8b4oZKwzmRvgpFxEGZYq3vuA28Dvj327AwMfO(XJ0SZxTzjp8vWxlRlr2BCCrQ7SAzPRMnUNz5nZQzWtBBARX3PLO)fiO3K5yMmh)si82K5enGTFbMV8Lm8SjZJWVEkFzYCs17Sv4RqgrjrJktAuSSm2O3mksgwy3E4kmqu0PsJ86UJy3xD7XUymff2AYWdpVjJWAdwnzYyYKLmmHBnuDiPjt(gHJMmfQIdnzWArjsAktMtzYmfUXmzKWdILUKGM2phR)(c4El2S)H6i5v(YAvSM)9Kq(Od6nuGGADE()b2Am))O1N)h2Kb3W4UGptg)DgfGVXZStom3w2PctIYi1Dsi3kGKrAIzTwVKFLM(5swlFYHeYvHgAa0PI4cLqKzTdWr)PD4ATVi2USHOkybnKUURUPXbypQDr3wVcYkAiLPrAynEq8RGxZqkv1MBPg0aDLAB2aPe6gTs6)wrtWc20ZzNIxDxKRrK4nSXQFrI2B2z3VOc8VV1b4NrcrvHrjVkwLEen0pTeb6F6aP7xRsPJoRVokc8GBDeb(gKDlIcvkQOBqxEGNUBKnf0whK1nehsq8j2c1QNM1viRDwIcSsYBjm00nZRU3MJaSQBEzxpqJsuMm6MmgMmLXVutBYmdrqXKz2T9OFbY4uflXdtM5mzET4A8yNVflQmzE8wW4MmVECfFdx0q5x4QhCZHF)aTZTAui95KvmAyJaXgzBjC3C22iFkM)lsghUGwDpRKGQf0EcVZ6jdYVFFJpuhH2VMToq7A7SUjZtEq8eSfa2vtWvtM3m(FNzdHep7RSTaXLB0(9lFOqAqf4LUrHo2K8P5R5P3vtJ2I3E7KceylKuKj7ESUfeRWCz6(eD3x(JxjuhHyp0whiwJHS3FVnW6lzfXE)d12x96os5unztYLlfnB7sVfVSS0BT9S3gY8Qwlojvl3NSARM72REFNYZXdoAgUocC(1ErZDIW))10DI3LLhKxdlkMMciSNvRscexDhr0uMjNRi1oloKP6nKxKV0ApXLyNlxNv5JuC93cPddplph5i)iWxfRSgoxrMCecibiRuLskAQfTGjPt7zKsdlepq3d0rysORi4xEp1aClzFeTONUMfdNk9yXBkAYC0sGBE(6BKkDpXR1qMmVlyXvi3)KJgnYqHIhlsJn0l44Qia5F3MRF4bIgIBvrVwFwruPJ2CdRqUH14bS92uFTijIpWyPIUQNHpR4uM6a429GcZLir6vDxvxcSDpPuXgjA8irx9Oxa6tHTTVojdfj2ahVn36l44aTP(Q7ivKHsKyKjJro0sCJLmD7UNli9tu7sdrotvy7sAu344HjbvpvN7ALZ65i(X0luf2RLj)QIsCRwVMYkReIAOJRXObaarBeSElQ7SUg0dtoZlzrTt7fIooZM2)fnB1Mqj6lvSv7Rb2QQlSvJWQDB6f(1TkPLjZz7eJvdEuPe1fPwUdUhTb79Ozg(4ZESoYyf(kcgR9xlEXx26OnkZrosfTe644flH0DCTYhTUsrVh2E9Xg2JBw3Ke2W(9hmih(Q(cW5ZVpVb486HL1hNxF(6ZdNNG95NDncnJQiF6PXWK5nY3WzPGuFtM3KjZtT2NOIR0weEFBMfHBepFVRdEoN40IYi6H2KCYdR5MK8NUhH8sHNsBGYDewh5kkf9DBYeeEFWv)DQhQKr6VXySS(25sZhRmNokRvaFQ(kAQOvrSQERnvEi8qAbsK5ATxW7VPc7NoYB7eVwEMnAQz9n516zA55pLSt1Y9y3EdimnwDkxTROyssLljkB9MCBRUNI0EL6v7phO5XaTY6c5WVQPm0eNc1sZh22zBKbIb0qOCkLuVZ1SgjR5qo17A9hnD1DYPt2J1EzJ5wUNRPH9Y2KP)TFXUr2MmrRg9ZMmdssgA1BzTjtmmuByY(uBY8W13GAtMrGDETMmJcyav8dY1VjtIRZKjjUYh9jVEtgotMuMmPPB1SjZy13I5g2Y)QUa(Y3UmpwEFc9N)OE6ouQoWs3I7qwK4k7qsZiurVQd6sCFT1VilutWzDDkYf8bF7IZfExi2bhYkazmzEl1CBYttIhM1ZXjK9z2(BCaVfJ50NoDOtf3WNyiDcJ5F5AhVmMmFymJzrkJzOl5w4E)10JDrf5QiSwo5k0fVBqF3)6vV4o2s42FUXU7gp3y4RlUXSA(rBNl3(RQITk830EFU1i57lwWRnzaDDjgGzY85SbwtvPGOHuVPgn5X6iW6JCzeyD3ndywlavhpNHBEysA)TfLyY8)7xwXgrtQoCz0qJpH3E6i24JULgBSTh7T2wWX5AwjSFPfOOlMFKmk9yuz2ocu(yBPbk3v3TfNSst6JFfnmzdgP)1bhZne3dhz2PYFQKJ3rWXhFln4yn27ptM32VCHiQiNlY4hxE0JLYFhrep7w71vWuSTdsSyDdXVIFnLlGJgqDisVhpAFcrvNJnrVDeI8j2AdrI)JAV1ln6sMT6Ge8yqBajdjpJ)krYMTui1ocs(KBX1pntBbjQ7QnENBRoybpw0gWYP92Dw0iUNi64d3rWYZTfhS8CThSSJwDu7v4(CRt4KNRD4KGhD4W9gqpMx3t0rCYN6ffpTTU4KxA4HTNos7dVYwCT)wB8uJNaO64jL0NIBCjVtfQyMoIN(0)k8efp1FO1y1S2SzqxrVA2gkqcWJgREJxRcVYo1Pg8uZvXJGQNocVwEl9YAFThQ9GM92(9hCRpUbpGS24gTXNiWegJveDIo7YU)IFLF)3IcrQA9D7Xii39RQgFOX6B4o7NMpZvgyes8zeU)eteN8PXQXph9AIYtHmCrkQXd(EuzuPkvlTXVLwdOOLbjOjiNfPUZg209rIgkEk7JiFUwoI8Mm9FdxYcRa20jsUUbwa)LYalyL6VIjNo5LTiky8uH79Hhz6uXhJ9mhATc7XhNeEwZlAGkrp8BVJVL1XZOmpex9wAZbFlgUM9yfx9yb)ZzDm6QT314b6LPhjo72JhoqyY1nekyMmF3T9o(21FkMmFVAnNjZ3N0eMm)aEIy6pSLBl2hAtDB6V7lOBdEvScYvwfld)LFwMnriJ954jHnwpTg2yXIp(KdJMbjPvzsB5TKJNCs3ES4Iu9NmpxCU06HNJWf9TxpUOV2LrUOn0rcMeuUX1S)VUH9Z5JLnilvQ(5z9qoeCQ7MEylDrcnxxPkNnlI817MeVHNDPAh4Yy54FP06jBOz692yKbUHNIzTdp)P724OhT35gmrXoof)1Fryk(ox3dPXNLgetrKuKr68nCeW7ZZsQinYNLyYh805fYNhRVjzYf2X5iF6ieLrjTkNVnC9MmUVI4dd0(64hgOyxOqg7aDsXWVsFEkfcLVJGGVrTqdn2VOabMm)e7j)N5oiFQ448WgG1hn1pnTxoCsFEOPSH93xa2W9Y6XljXF4aEyzjj4BWDGabiPbDh2VVa4m6li(w86nyypU7fFJEc6NK0B4Gb8Zss8YX2BWab584LL8y9YYYst9st9r(6KfiyyV(CheJkd4gFPBV4M1hBFbjPbiFaiD7bR9Wp1K5NrqNMm)8lke5650LZUwX38lQ4XnMkX7612oCj6uhJZt0UpTVuJ2rC538YpUSRsDLRRCN5v00h71tabHVQjZ4yv1j9q7qBL8bz953w1piRxFTpiRwAEDX(bzLOvP)TV51)Z(dP81r0P1wLs6xJ1hAP8fJKB4sAJnAMbjF5yXA4I1Z06lWkwqSlDoVhX)rC310xZR7)7
```
