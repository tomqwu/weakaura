# Paladin — TBC WeakAuras (All Specs v8)

One import string covering all three specs. Elements load through Spell Known gates, so
the HUD adapts to your talents with no action from you.
Toolkit setup, once: `cd ../../tools/tbc-weakaura-creator/scripts && ./setup.sh`.

## All Specs — v7 (`all-specs.txt`, seed 20260811)

The full Holy / Protection / Retribution HUD: 43 auras in one import, arranged as a top-level
group at (0, -140) with five draggable sub-groups — the fifth being the PvP column added in v5,
which only ever loads inside an arena or a battleground. Every trigger matches by spell ID
(never by name), so it works unchanged on a zhCN client. `internalVersion` stays 45 /
`tocversion` 20501; modern WeakAuras migrates that forward on import.

## v8 — the execute prompt is hostile-only for real

`Paladin - Hammer of Wrath` fired for a **wounded ally** under 20% health, not just an
enemy. v4 claimed to have fixed exactly this, but did it by setting a hostility filter on
the health trigger — and hostility is not an argument the health trigger reads, so
WeakAuras silently ignored it. The prompt now carries a third trigger that checks target
hostility properly, so a glowing damage button no longer appears over a dying party member.
Nothing else changed; all 42 UIDs are stable, so this imports as an Update.

## v7 — the cooldown row now shows what you *cannot* press

**Absence means available.** The row used to show all fourteen icons all the time and grey out
whichever were down, which meant it was busiest exactly when you had the fewest options — and you
already know your own spellbook. What you cannot know is what is *unavailable, and for how long*.

So the situational half of the row now appears **only while it is on cooldown**, carrying its swipe
and its countdown, and vanishes the moment the ability is back. The row is a dynamic group, so the
gap closes behind it: **an empty row means everything is up**, and two icons mean exactly two things
are down and both are counting back. No aura was added, removed, renamed or moved — re-importing is
still an **Update**, and every position you dragged survives.

Those icons also **lost their grey-while-down tint**, because it stopped meaning anything: if the
only icons on screen are the ones on cooldown, greying all of them just makes them harder to tell
apart. Full colour plus the number reads faster.

### What still sits there permanently — and glows

The four buttons the rotation says to press *the moment they are up* stay on screen in both states,
still greyed while down, still flashing gold the instant they come back. A hidden icon cannot
announce a moment, and these are the moments:

| Always on screen, glows gold when ready | Why it is not hidden |
|---|---|
| **Judgement** | 10s, off the global cooldown — Protection and Retribution press it on sight |
| **Crusader Strike** | 6s, the Retribution rotation's metronome |
| **Avenger's Shield** | on the pull, then on cooldown, for Protection |
| **Consecration** *(new in v7)* | Protection's largest threat source and an explicit press-on-cooldown line in the tank rotation |

**Consecration is the one classification this version changes.** It never had the glow, because the
same icon also loads for Retribution, where Consecration is a mana-permitting filler rather than a
rotation button — a glow overstates it there. Under v7 that trade stopped being symmetric: the only
alternative to glowing it was *hiding a tank's biggest threat button whenever it is available*,
which is the wrong direction for the button they press most. Retribution still reads the row
correctly, because Judgement and Crusader Strike wear the same glow and sit ahead of Consecration in
the priority — a lit Consecration there means "your filler is up", spend it if the mana is there.

### What now hides while it is ready

Everything pressed because a *circumstance* called for it, rather than because it came off cooldown:

- **Divine Shield**, **Lay on Hands** — panic buttons. Lay on Hands already has its own alert that
  fires at under 25% health, so the row only needs to answer "when do I get it back".
- **Avenging Wrath** — a 3-minute burst you spend on a window, and it locks out your bubble.
- **Hammer of Justice** — a stun and your only interrupt, pressed at a cast, not on sight. In an
  arena or battleground the **HAMMER NOW** prompt already owns the moment.
- **Holy Shock** — deliberately *not* promoted to a glowing button. TBC Holy is Holy Light and Flash
  of Light; Holy Shock is the expensive instant you keep for moving and for emergencies, so pressing
  it every 15 seconds is a mana bug, not a rotation.
- **Divine Favor** (2 min, saved for a Holy Light on someone actually taking damage) and **Divine
  Illumination** (3 min mana cooldown) — spent at a window you choose.
- **Blessing of Freedom**, **Blessing of Protection**, **Hammer of Justice (PvP)** — the arena/BG
  additions, all three held for a moment rather than pressed on cooldown.

A Holy paladin riding out of combat now sees an empty cooldown row instead of five greyed icons; a
Protection paladin mid-pull sees Judgement and Consecration lit, plus however many situational
icons are genuinely down.

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
*(v7 makes that classification literal: all three now show only while they are on cooldown, and the
grey-while-down tint went with the always-on display — see above.)*

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

Eleven 32x32 icons (plus the three PvP additions) with WeakAuras swipe text, mouseover
tooltips and a 50% fade out of combat. Since v7 the row is split by how the ability is
pressed, not by what it does:

- **Press-on-cooldown rotational — always on screen.** **Judgement**, **Consecration**,
  **Crusader Strike** and **Avenger's Shield** are greyed while down and add a gold pixel
  glow the instant they are ready in combat. The glow is the instruction, so these can
  never be hidden.
- **Situational — on screen only while on cooldown.** Everything else shows up when you
  spend it, counts back down, and disappears when it returns; no grey tint, because under
  that display every visible icon is on cooldown by definition. Absence is the readout.

Only two are baseline for everyone — **Divine Shield** and **Lay on Hands**, the panic buttons
every spec presses under pressure.
Four more are baseline but hidden from deep Holy by the inverse gate, because a healer never
presses them: Judgement, Consecration, Hammer of Justice, Avenging Wrath. Five are
talent-gated and sit at the end of the row
so the shared part never shifts: Holy Shock, Divine Favor and Divine Illumination for Holy,
Avenger's Shield for Protection, Crusader Strike for Retribution. The dynamic group closes the
gaps left by whatever is not talented — and, since v7, the gaps left by whatever is available.

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
lua5.1 generate.lua                                 # from tbc/paladin/
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

## Import string (v8)

```
!WA:2!L33E0TXX1D710krc(Le1dBjlhdlBPq6yldSaGeWXoUaGGKGMeeAbiPKSQ5UayaWkUy3v7UGKGX1jMXjrXjnnLrnVAAQ)ytZPNEY58LY)O5LtCcBA(oj1n9Eyst32K2C(uZ7M06Q(kjnjTZm7cGfGGeuusoMY)HgUyETZoZV7V5EVZDxXmENzFM75S3XkzeYovonf1OkskAd1rhDKSdphnGANzvKn0uKKq5IwuukNgs(KQ7mPGKqorz33N7brcsgfpF9mgrqwWzfsxudjyOUVMZXD)sc6fv3B98tnJOCb3PflH0oFgfTCiTi2Jj1DgrsCU5e0Y5oTIIKHOAgvb8iXq9wQ280rII7IWssUtPIYQVKOCEfTscgIkYUYy1Bf1QmA(86iJZSOgQaUG0vurCf0ukRUOvnsjohABRiu2OOI2OQK2Q7AjRISMwyyy6idEgjVybxC6zfKqDOjKLwXE40ne0mCLjVOSOErxrW)XW18gAIfkG00tCen7lFprmi3xHYAcSlts1vrssI50pqNEIug3OmQscvqAZtZpEoDxNxVCg004h3uLZNxC2LMmA4uPNmv6WCPRvusneUiUujJn8WxOSok2S4XvkREGNtwOes31I5qzW9a5XwBWydNS)XgEHYY2dlxlLtu)0LLXpntJyfKKu3La960wLpIso0h9Awqqw0AwTh4w6FzKGokLbELOGrXxjCWiYkYOvYHFMi1ysYZPMocpFLtFEsvj3zWtKscIY9d3pUbGhWlWc(W)9wBoNLTM4TwY2XfeLnqAYcsJJ7sCN)OlOJKYNubNDMOXsKog3HeZPU76OjoKUszTSi9fnuYoTvJ2EY9UuEn8CbEmlyi0XfeKZIxQ7NKfzSLjvuUyXsSKv20ohcYwwm3sCJK8Kfce6e9GcAdiIlJhwDSiE(NJcMWtVwfelxbK6UsDMYyeQ7(lJrKtuu0aTizAq0ctfrsriNlTzTE2yoRNf1X45PMqmNrX9UOiUMPOJ9dEnGlieCtFZRbEDqWvOvItXGo7YOURg(nz9js4XspAes7lch4XocCBVh8e6DahcUlokijJL0kol3WD6AEmmzscGJhUB4WWR2f0f0nCpUC2oiH6Egdxf3rlkqq6inrDdXS62DbKSP2cVg4EH77JEn0hIjZwLlPdONhf6fcoFgbBjPKxNNJ6najT3GKu2aDGHN6cgeWdQ4Y0NnR5NtWarEG9bhCjIWcUdMe)VZUp1onqZAmPErHCkZCC7zYfO5rsu35HXGVS4h6I0N5dFy1D6Ob1fNpVvUvbtWWQ7MMdMfqHG0ZsxvIeg)ZlqlalMHYrZ8jxXcOCc77(Y0YpDz8mu(kqWf1ilnO04mJKy0eXGdQHrlK6SiTI1NDSg25XmTQ7SFnX5CFSYc5iiu3PtR6P2Z0KwuAt2Wd2K5qzXIKstQQHVqNImCo1uDWTcnVzWq0j0euNFc7lwP2TMslm6yPhoEIy2ZvoKdwkEIeX4MKl(adMwT72mKWuQY5OI)C5Luu0SMyMgp6YiH4RFlj8T73EsS6sO6HBtNBLzMeLlLbPnnCWfWtQwsERy9h7HnlgMunhf7fi7FMT(QVDovhB2c3tIWcXqFv)LoEC2rMIiXcfnUDO)XxGi5KfV)LoFgd8MaYg7JRuz8(sU4O5EKm64TYKqAjdpC4(INaEY9bpfFemHE29bpPRiK(JCX5PO8i4oihr8LnCF9PUtCFhohbeHYHYnIWSfTihIwxwQtxWEC1CffXY83SMTiItXNJZahLqw3mHR)2tbVavkwxmhIJUWd7d3rUGB1fSFxrMtrPeZs0B0G0zMhsJSOvwdXfvcjiZjiPwuOdRHsARsu7koHgpVqw0PIkGLtKlerq7uJf)(Q)R7lfLwJ2SIWdG5SXm7qhWamWRTdUzicEFbxWdcpe8WlHMy8K5K6YxMCDPjkty5rfThsI5YHK5seB8yClPOjIxJO0Klo4OCXp5OjshEyi2bocx2IOSt1pCBBB(Pf0efWyG5fLJQukJGb30csLrmhsr9qp0dPLTOGCbK(bocSivZO5vXkMG0mQaNdUbxxGO(ubkUVg1cPA9EwpWG7fIxLj)zzim5WqmWJaddJytt)NwNULlPYminc96cQKRicrmnW0Ucb8vRm(wsAdhRDe0aNtEzi1qKrRxctSFkRCOaDaPlcJzZ9cJF29btWah)cvPvPJGdFy4Ku5i4rXpoNc(1Hh7jHjzaECxkazWTllKZ6gHG8qrg1UwlPBA)5G5aubr40WuGeucKHZWRE3RFtTYdkdA7h0zuV)1V2RM1etLatdZaZcvyG5SEQE98WJd9b)gDapbrUhEd8WBKi4cZFe4nbpLLCn8MPz9wOPVv4SWBRi80oKuH3owYeEhWV5MxqeENWVLtHp4DXa)2peSa8UHZ1b87aVh49wxu56SevG3xnXK(kmyYzvpZCteSB4due(DHpi87bFii29Ce43hJ97aEMLDo5alEiwpyyFNpi8hqW70nRdgO(w2EXGJpmKYQ1BdEg4)dSOTCIvlOsi4QqenG)W1sy4dETnlmKWjmErdQHce1pWSSAfqgyy85jO)6fWtW4ju3PTnfPenktfZPG(2H4PQDqgybjj(AnGF5dBD3uZAudTREVRcCvRsTaz1AHd17CD6KAG5vjb5uQOf7vwVlAquIktGfIApi)TGb5lrMKXSXetJ4PQjs2XQOf2xZUa81hb2jFenbXC8RLaX0CyYyJk8SQtJ7j8y0OsjbzEwdKm)IgZGrCvYJTXaVnk9AEWd)lfeH22QeHMB8cgP9RCCVgdUgIqluBQhl)0lr(5qVoBXHHOgt3dLI1HKdUrCcfWtMWID4u6HYfhIkOXALsButYsUTex(IvfxwPUKbEmWd)FHpgH2)pHhw(qb9GLtWQfwdCq26sWqrJmetal1cXLlyVzorjrIYjQ7j6WHhjj2(IHdh9rWAQepD8XJrgt4viI48ECLPKOMMIwrQK9nJNAJ5AHmvvUbVO26LU8WbZGLvWAQq)nU4V8IuvhswwshnFvRj70lTjREDLSMrwRCU2UG6duxrJW5YnQS(PMajmvyI52NAeuorHtzRsI(PSmvBsQvAh1OGaNTI5w7iwDBXGbimhyybM8GarEfuGX5iKgZRv1Mmmqz4GdprprpExruZty3u3f2S6SAid0K1R1tC4mw2gue6)JaFsBjj4tvD3fl5h8MnF8gfSOKFu3cmLSYmY8WNGOCy1FU9NoQLmh8P5HNLh(m8WNLhEoE4ZrfREFx313e)7J3X6Y)cjwYHlziyjBBgXAcLJQwreYvG)ncrBGa1t7HTgv79qPABdR0EH(NMmB8vBC(PbkNV22h99(sNTGFLRM)yQcD3LVyPdhPsd8hhOgvW5rZQkAH1jt4WISyDXi0cpyDwecoKTonstmc3bWuZXDW1oud(wdB7K7Wu)5OEG6zpuzSDoLWmVU7J6Ai1B1HN9uKQ4ovrrKuo3JP60bEdt02x39aAyPly7WoWOPRNmuUrSK)nWGNO3jSRTrM43T1sjE(FVnkFwdOD7WR6aD6PQYQeqhHj6i8TqH1n9cxGDydfXRmxO(tre8ZREn2dYQery4HxkyG(knfBOcENHfc3beXfefJdJ5c63fEv9S3fv(zG796GBIQl)kzvuKW2zlJLvWQJVC1FsCdurye(gEwFMJWX6XBa)CSE9eeN6HnyV00G00qK0qEOPEPPS0uFCS96nqaARi54ThsQppbOP9qt7LMgKwtsV5RxsPH8ALgKMs6)qSEi1PxpC(8ge3)4upEP9jTFcyL2lPo0C82d9U4N2)(P9S)q0s9ql1pTFcKbxwVE8y9h)BOf0EE0lmfcPgMywSbhb4xKsyGPgI8aF9vkiPmt)AOZugjNTILUAri5vCzmh0as2(WP4cK8srDf7IKlhM6mY9Ue56Q((GwN6gqtlRQ)gS8kdjh6DmDrXStjJ017yE6pXQpTsMYggkYJInVusOcTVgwexLDrVFrS8T8z3nvBXdDy1lslIQRp3YwUyjYOPtp6iG2TBPXwEk3yl5fp2gZKKBggHimIr2hBiVbMMRe7zonwK9BbFfRXX7IQ978vbU81yX(gQ7PAMKnl7tuNyFmM6NWSDmBbsIu2bT232wGSPCU1vLdMpatb6KpGi95Gke(BHf7mGtUpE4dtC16r9EuYCoHS5CDuvuuIXwue()ZdNVUm3hXwMRtconOfk2pn166EOOyQ8uqlupTuICwVeCnRxVb9rlLI694HM6LMAj)zjxgIwhl5GE0WtwJklH1K9oW6FTAraTbdZns)JnCJccMm7Wj23KXLfG3K56lAYCd4)DJDyYCt71K5Mzmz2jDDZKzxyWRjtNMm7g)J9yYGlEF7YK5wUCagnzU1ReqWici)NiRr2IQbxne0K5a1bFFttMB7kfsZvJaO7R14hBo7HOKMuAu2EPPus2EdTbj5AyTDOlFRT6B61wCn0UtRL2lxiLBzJGu2akXDSptZiMhjAHWZjFMjYjhPniM)(xQGyoaHkWN)nd(ylMS)grT8FAZROjYwo4ydCIUsQ0DBwr)hUcUI2MDBmzoO9sUNiyl0N5qJLeU2)y1d2Kk1JepvQ4jgWDxCiJUvV91Q0KyZ96wDpooDY(RwO6(BTk3jgDIgksOe2im3k5DJni3OOZB1WcvCRiJRHCoD347ujvdNheA6ze1nODxN1ZmAu3JMW9iXCoMgm8iJeJJwZBXrZdZnqS0UJpYiJLigvB)bK2bCtFEk83sbFIV6ZIUXlvn8xcB3D5sYPiDML1JzS0fItqsSGmeut3qGCu0meLYXAJx3AhnRJLgXJnfFg7oyVDSqbnrRtQ76j2MquJ)MxoxfzHsIzPUWcBMseDfndWZ8KQsu27qC9Xjjws046jM6om5QIz0WZfL1FQB48zvKXJbzJ(fYAOOLHlCFXhl1ccAzT068P2h2yJfZxwskQOwwjunKSZaIiSesZqh(RyQA2bX6jSHgBA7BSSW1II6HxkDHJpXCE8LCIOfo7DdXziwIUUQhDe4Fe(2W3b(UW3d((Wpa(HW)e8JGFm8pd)lWla)RWfG)n4Fh(pG)t4)c(jWpf(zW)n8ZHFb8lH)htMRXKbtkDTMmywORZKzBMmVctMxPjZ2xbVCKTispvrLzgvEfD6FgruNCWyBgIX7PoXOnX3nWJj(4skolsQb6XgCtnHOetKYBrIs4kTyjxFAT3InTMfHgLCBr6r(rpxi(MP4S97cLIJeffK43iogQOEK6oHI8B9trDwZKfXI5tQJjiuYNrsrjNfTiRV(rINP40CJxbCzYm(Q4fR5EbtMhOjIrYJZxg8PrcYIrlBqDI2s6sI5qzuW2UucEEwCFqrmTGY8S7CbASSqn2r3qtGyFp1Kk4GzYwwh3bzOvOczO4hWdMjTYywRmE(o9cNJHEQO0S57SsUD05Smlq9JhPBNVA3sU5RGVwwxIC244Iu3v1YsxnB8iZYBMvZGN230EJVDBr)RqqVjZXnzoXLr4TjZjDGTFbMVXLn8SjZJYVEkFzYCk17Qz4RqgrjrJktAuSSm2O3mksgwy3U5k0Fm0PtJ85PTy3xBRXUymff2AYWdpVjJWAdwnzYyYKLmnH7nuDiPjtENWrtMcvXHMmyTOejDLjZPnzMc3zMms4jXsxwqthGJnqVb9Cv2Q)HBl5v(YAvSw)9oQ8XgWx4GH0A)6)dE1X6)JvF9FitgChJhc(nzc0EuaUHNDxCyUTStfHeLrQ7IqUvajJ0eZATFj)kn8ZLS2(KdjKRcn0aOlfjekHiRAhKJ(t7W1A)rTDzdrvWcAiDD3DrJdWUv7KESEfKv0qktJ0WA8G4xbVNHuQQD3so0aDLAh2aPe6bTsg)wrtWc20ZzNIxD3KRrK4n0z1Ver7n6S7xub(3)6a8ZiHOQWOKxfRspIg6NwIa9nDW09PvP0XM1FBfbEORoebKB44hBikToeRhibmk1jy0doIIBsYBH1BOQ8Q7RXa8Q6zt25d6uGXKr3KXWKPmEmpTjZme5atMz3(J9vjtdvSq)MmZzY86X14XVqtgmzY8enbHnzEd4k(g5TUb0qWHc5lQOBq3MJ3rS0qCL3c1krZ6k0AhDnBkc(RDGnho)J0k3VrH(NxwXWXbgIng3IeOXSTLqOYgFnYe6fLwazLeuTebMW3SEZGceW)4d2wrGx3vp7cuteWK5nDi8cSfU3Dd4EtMNc)V38gcsFUxDlr0l70o)1foFPr8sxSOhOyhBsE3818i8QPBBYRWTtrdSLukYKtzw3cIvyUmDDYU6n)jQeUTqSh(QhiMZq77V2gy91T4E(BQD(71D4YPBW2LRukK2YTOlEfzl6ANTVnK51SwCsQwUzz1wx3Lp9EpT3teAKmCTf48R9IMBhH)U10TJ3TLNMxdlpMMciSxvRscKqDNr1uMjN7O1ENDil1BiVnF51UJlZoHUoRYNO46FuthbEwEoYRgKaFvSYA4egzYRAajqALQusrtTOfmjDAVdxAiHeb7Q)2ctcVLGF5dudWTK9RYf9TWzXiPspwIgI6SoAkapVq9dCLE2516itM3lS4kK2p5iXIoy4eXJ6SJEHo2gbi)(BS(r6pwyUvfLB9Af5LD0IgScPbRXn4MAr91IoAI(hlvSvDp8BfpZuhf3QBueUrhn9QAv1TaB1Dkv8HJLiASvp7fKExyB5JtYWrJ3)jArtFHoUZwuF1DMk6GJo6WtgN8YnXnwY0TQnxu6NO2PgI8UxHTFXPs2jIqc(EIsUluRCwVhnaMEHQqCTm5xL(Uw9EnLvwjm1Gi3JrduaI2iy9wu3vDvXhI8UXKf1kTxi64mB6axYSvBcLOVCXwTFhSvv3yRgHvRoCm8JBvsltMZ1oglhEEPe1vQwUnUBTb65yzg6eZE82YyfzlbJ1bQfx5lB9kqkZrE1lAkeZXBwcPB7ELpwDLI(aS94NnIxpSEijSrceiuio8v9gKZFa)(cY5ZllRFoF(93RxoVH6na7Aechvr(utgnzERnBNOjZznzEBByBdFj)MW7FZSjSt889To45CItlkJOVCNK3qXAUtj)z6wiVuKP06VCBH1r3sPOVhtMqWhcU2Fy9qQmAFoJfZ6h7lnFSYC6OSwbgQ6RQHIwfXQ6T1q5HXtPfirWR1zgFGgkSp6mVTZ(A6E60uZ6hgS190YdHkzNQP2y3F9lmnwDk3TQO4ssLljkB9KC7REKI0E16vhphSX5aTY6c5WpQPm0eNc1u3hX2PCKjI(1qOCkLuVR1SgjR54o17E9NnD3vYPt2T1zEJ5wU3RZXzEBY03oUupWBtMyvJsAtMbijdU6J22KjogQne58SnzEK6hKTjZWWU2MjZiagqL4qC9zYm61BYKex5J9u3GjdNjtktM00JK2KzS6hfTJqdOQRIVYDA0JL3VqF5pM3UcNQnS0n5oKfjU8oS0mcv0R6PVrV)w6xKfQj40oF8DX9cYDP5cVlg7GdBfinMmV9AUn5PjXnZ654eY5rB)TqG3IXC6ZKo8Pty4xmSoHX8pFTJRgtMpoMXSiLXm8LDlCFGA6XUOICvewtVHl0nVDOV7FXQ3ChBjCRF)YUhNVFz4RlUXSA(XALl3()vfBv4VS1(CZj57lNGxMmFjBy1uvkiAi1tQrsE82cR(eVOaROWLxccNoV1P0vdYBbTshOLiltM)OxSWtBYaj8kgIkws1HkJgC8j81DBruFYRGiQdSbF)vV4Pv(kvPvE83rlx8pFJkM9YwGGUy(HZO0TrLzBlq4tTLgiC3D1sCWknOd(wAyWg8TaO(I)CdY9irNDQ8No54TDX)tVLEXFnopptM35lVwXRiNl64NqEKJNkqBxXF2T28(ykWwTKVyDJN3YZ5Fre2)1Ha9CIy9ketDo2r7PTqGpZwBiqIFsRTOWPBsUAheGNdAbiyq5zcujA2SLcR2wqWNDlU(FzAjiqD3TWJyxTdgWZfTamCgFDLfnSNjIn(qTfm8CBjbd18XWJ)CTgmSZMD(5wChn0oCWZ1kCqOJnuKEcQh3NNjAlo4Z9YA3m4ar90rBDSp2K7YV6gp58TVPoEsj9P5gxY3uHlMPT4Pp)lZXtv3UQVWRXUvT4aw2sVB1g6W5XZgR(WmRcVYo1Ph40ZvXRGQ32cVwElTomF7hU1GI916Zu7QFCbEczTXfAJprWjmgRi6KT3Lw)zBPXfxL6x7neeOQ1TTgdG80NQAIbhR3HAVFo(cV0adqIjHi9n6ejiF2OC(PAxtuEkKHBsroFPWJjJkvPAPo)ot1VIwgKGMGCwK6UCCqZdhlCIu2V(45A61h3KPVB8Y2rPZME0KR7HPZF58W0xP(JyYPtEf7u0hpvKEEKHNovIXyp7HxRq97jiHK08IgOs0xmS39336vsOmpKq9wBXlfwCCn72kwYTfSXtUltFfXS7dE4Grix7iKNmz(rB)D)dQ3ZMm)4M7ctM)zEIO3)stnl(hBt1m933fvZGxdRGCLvXCWFLN5yteAuFjEs4r1DZHhv8eJp5qOzqsAvM0wgl54jN0Jxl(f1ajZZLGlTEK5i8l)W1JF57CfKFzd9kYsc(0eA2)xzWb48ZYgILkj)8SEjVJyQ7H(Yh6MecQUtvoBwe5RznjU6o3s1EbeJNJ)Ls7rSHwP3NZiGBdVeZAhg6t3LXXowpZnWOfB7s839fHL47ADFze(I0G1jQKImsN3XReDVExsfPr(m9s(aGoVq(8yDejlUWopp5tPGOmkPv58TGF3KXZwIpuo7VTFOCIFXczSdOhfJak96Tuyu(2cc(E1cbY4)QceyY8ZSx8FM7K8PtJZlBqw)00a00E4Wj96LMYgjqVbzJ0dRxFKKarc6LLLKGBGNGbdssd5jsa)bXz0BiCt85lueVE6b3qVHcqs6jsOGbyjj(4y7juWqCE9XsUT(yzzPP(OP(jFTUcgkIp)EcHrLb9GV0JpC36NT3qK0GKpiIE8I1y4NBY8liOttMF5LeIC9CeY7FTIJ3xuXJBm1C39RVv4s0PpoN3yDDg)PgPT4YV)vECzNL6mxN5o7RQHp(PNecbFltMXXQFtgH2HWj5du6ZV9QFGsVHAFGsT026s9dukrtYa7yZRZN9hw4RNOhRTAK0VoPp8s5lgn3qL0gBKmdq(sQI1QfRBP1xKuSGyN6C(oAGJ6PZPVUFJ)3p
```
