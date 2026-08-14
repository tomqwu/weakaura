# Paladin — TBC WeakAuras (All Specs v7)

One import string covering all three specs. Elements load through Spell Known gates, so
the HUD adapts to your talents with no action from you.
Toolkit setup, once: `cd ../../tools/tbc-weakaura-creator/scripts && ./setup.sh`.

## All Specs — v7 (`all-specs.txt`, seed 20260811)

The full Holy / Protection / Retribution HUD: 43 auras in one import, arranged as a top-level
group at (0, -140) with five draggable sub-groups — the fifth being the PvP column added in v5,
which only ever loads inside an arena or a battleground. Every trigger matches by spell ID
(never by name), so it works unchanged on a zhCN client. `internalVersion` stays 45 /
`tocversion` 20501; modern WeakAuras migrates that forward on import.

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

## Import string (v7)

```
!WA:2!L31E0nYv59mrjWUkV869rYUzdrzt2f7qYgPrs2sHesLKLTLJTK2rY27UzB8ms6kPz9OzMDMr2wMqGycHTbkLA2cukLM6s50tpCoL6)O8Obc4sPhOP0VJHsNwOLt3Y7YJ0TVakq79ENrpTSL3xH4n)XE9O79o35o37VVF3VVV73DwMj6o7ZC3N(2xnJq2PZPPOgrrsrBehoCK0H7d7xT7SkYgAkssOCrkkkLtdjFC1UskijKtu2196AyKGKrXZwpJXeKfAScPlQHemu3tR54Aqjb9IQ7UE(PMvuUGR0ILqANnJIwoKwy7(KAxHLeNFEbTCUsROiziQMrva3tmuV5Q3E6WrWnrijjxPurz1xwuoVIwjbdrfzNzSATIAvsKpVoY4ulPHkGliDfvexbnLYQlzvJuIZJU2vfkBuurlHk5E1DUSvrwdlmmmoYGhrYlwWjNEwbjKdnHS0k2hNUHGMHZm5fLf1l6mm(pgoxWqtSqbKME8dPzF57oSb55kuwtGDfsQUksssmN((62D4Y4BkJQKqfK2c08JLt35z1lNbnd(1nv585fNB5PIekv6PsLoex6AfLudHlIlvYOJo65kRJIohUFLYQf45KfkH0DUuougClqET1go6OjhC8rxSSSD3Y5Y5e1pzzz8BZmiwbjj1DiqVoTv5JPKd9HVQffKfTgv7dU5bxbjOJszGNjkyu8vc7pSSImA1C43jsnMI8EQPJWJx50xGuvYtgChUKGO8GW9HVbWn4bybV4)ElTMZkwd8wtzB)CIYginzbPjWnjUXFKf1rs5tQGZotKOXthL7aI5u3zD0ehsxPSwwK(sgkzNX6M2wYDVCEn8ybUplyi44CcYzXt1dsYI03YKkcx0OXx2kBAJdbyllMBzUXsE8c(dES(qbSbeXKXDlhlHh)5OGj8WRvbrZvaPUJuNQmgH6AWYye5KffnqlrggeTWuHLueY5uBoR3nMt7EjDmEE6jfZzuC3ljIRzkAFF)xf4ecc34x7QGxheyvAL4umOJUmQ7OPFtMFchA80jctU)IW(E0db367gpGE7WbG7KJcsYyjTIZYfChoxadtMIa44H7coi8QDc9a9c3TZgVpiU6Ughxfxrkkqq6inrDdXS62nbKSL7fEnW9a37h(QOVetLTkxIdOVhb6hcSqgbBjPKxJ7d7XpjT)aKuw)oWWtDbdc4bvCf67M14ZXyGW3)EG9Vmryb3atH)3P3JA3gO5mMsVOqoLzpQ9i5I08ijQDDqm4ll(LUi9D(GhuTRgUH6IZN1k3QGjyu1DsZbZcOqq6zPZkHdH)55OfGfZq5Oz(eRAbuoM9tFfA5NSmEekFfiWsAKPguACMHJNiEuy)Ay0cPolrRy9rhRUDEmtRAxdQjoVRJuwihbH6kDAv31ENMYIsBQMEXMkhklwKuAkvn8f6uKrJdnv7CRsZBwmeDsnb1fM0(IvR9OP0cjgp9OXIh1ESQb5GLJfpEuUP4In0WPv7TdDjmLQCoQ4pxEjffnRbMzW9Umsi(6pscF7ETheRofQEWo04wzMjE5szqAZa7Fr8GQLK3Qw)XUBZIHjvZrXEcY(NzRp7BNt1(MTW9uiSqmmq1FPJ7NoYuejwOOXTbdoXIejNS41V05ZyGxeq2ypCLkJxxYjhn3dLrhVuMeslzOrdnqS4WtSh4j5dJj0ZUh4jCgM0EKlolfLhg3a5iIVSHgya1UWTDOCeqekhk3ycZv0ICisDzPUDc7YzRvuelZFtA2Iink(Cug4WeY6wjC91zk4fPsX6I5qC0jEyp4gYjCloH96m88kkLywM(GgMoY8GAKjTYAiUisibzobj1IcoS6kPTkrTNyeA88czrNiIaworUqybTtmES7T(VU3uuAn6TveUFmNnMzhCadXaVwhCZse8(SoHhaEq4Hwgn5ejZj1J3m56rtuMWYJkA3LeZLdjZfp6er5wwrtephrPjxA4eCXoEI4PdnkeDFhIlBru2PheU1RDHze0efWyGfeLJOukJGb3mcsLrmhqr9ap4dQLTOGCbK((oeSevZOfuXkMG0mQaNbUENNJO(ubkUVg1cPA9FA3WW7gIvLj)zzim5WimWddJcJztt)NvNULlPYSinc96IQKRicrmnX0Ukb8vRm(2sAdhPte0axJ8YqQri9wpeMyFuw5G(DaPlcJBZ9ctC69atYah9CvPvP9GdEq44u5i4rWVoNa(vHh9jGPyaECtkazW3xwiN1dcb5HImQ9SEs302RbMdqfeHtctdsqjqgofV6DTX3QvEqzqBVGoJ69TX1ETSMyQeygywyoOcdmV1B1RNhEmya4n4aECICp8g5H3erWfw4qWBgEsl5A4TqZ6POPVv40WVwr4PBqsfEByjt4Td)6x4cIW7a(nAu4dENmWV5dclcVl4moGFl4DdVN6IkxJLOc8ERjMmqHHtoN6PMFYa9cVVIWVd8(HFx4darV7db)EySVd4zwPXbhyPdW6gd77(bG)acENUyDa)1xY2dgC8bHuw391cpd87dlzlNyDhujeCviIgWF46jm8(V6wfgI3imEjdQHce1pWSSAfqgyy8zjO)6fWtW4Xv7Y2MIuIgLPI5uqFNq8u1oiDSaKeVThWVYbTEAQznQH2vVN1aUQvP2GSAVWH6DSbnsnW8AKGAuQOnRvwVjAsuIktGfI6mi)PWG8LjdYy2yIPr8u1ejRyv0c7Rzxa(6dbDXhwtqmh)6jqmdhMm2OcpR6m4wc3hnQusqMN1ajZVKXSyexL8yBmWlJsVMhCZ)sbrORDnIqZprbJ0(uoQhJHxhrOfRn0JLF6Ni)CGxNT4WiuJP7JsX2GKd(M4ekGhmHLC0O0dLloivqJ1kLEtTil5YsC5ZvvCz16sg4(ap8NaFecT)FkpSYbc4glNGvlSg4GS0LGHIgPlghwUnIlNZEXCIsIeLtu3vKrdnwsS9fJgkYdJ1ujw6yteL0NWZqeX5D5mtjrnnfTIuj7Bcp0g15IzQQCdEsT9tD5H9NblRG1uH(BCXFHLOQoKSSKoAHQwt2Th6TS25vYCgzUQX52fvV)6kAekxUeY6NysKW0HiMBFIXq5efoHTkj6NWYuTPOwPDyJccC2kMBTIy1Lfd4NWCGHfyYdce5vqbgNHqASGwvBYWaLrdm6K9f5O9ewnpHDtDhyZQZQHmqtvVwp(bZyzBqryWpe8XTLKGpr1vxSKFWl28rBwWIs(rDlW0YkZkZdFmIYHv)52E6iwYCWFop8S8WNKh(u8WZXdFAQy179AUUw4FFmhBi)leF5gCjdblzBZiwtOCu1kctUc8TziA97VEAFS1OAVBkvBhyL2nm4mKrJVuZJpnr58L3wI3ZlDwc(vUw(JPl0BpEJMou4knXFSVAubNfnNQOfwNmGdlXI1fJql8a1zri4q260iTWiC7atnh3bx9in5BnSTtUcr9NJ6(QN9iLX25ucZ86AaQRHuVLg8SNIufxPkkIKY5AC1gDG3OeT91DnKgw6c2gSDmA66iDLBal5F9m4b6UGDCTKb(DAnvIh)3DZYN1aA3g8Q2x3URQSkb0ryIoeFBuy9cEIZ)2THI4zMZv)Tim(9vVg7bzwIim8qlhW)aLMMnybpZYcHCaHDcrW4WOoHbDINvp9DsLFg6EUg4gP6YVAwffjSD2YyzfS64Ru9Ne3avegJVP31N5qCSU943hhRh3bWPUzd0pnnannijnOBAQhAkln1lhB)E87NExKC80hj1RB)00(OP9ttdqRjP182pP0GESsdqtjTFqw3K60VBoVEcGBFCQBp02K2o(Ts7NuhAoE6J(u8rBFF0w2xqAPUPL6J2o(ZGlRF3UT(JVn1eAFpY5MgHudrml2GJa8lsjmWudHV)VYQfKuMDqn0PkJKZwXsxTWK8kUcMdAijBF4uCrsEPOUIDjYLJsDg5UxMCDvFFqRtDdOPLv1FdwELHKd9jMUOy2PLr66owG(tS6tRMPSHHICcS5LscvOT1OI4QSd6ZlSLVLp9oPAlEGdQEEAruD95wXYflHtKoDIXaTBZsJT8uUX2YlEKnNjj3emgryeJSpYiE8pdxj2tDsSi7xh(Iw9J3jv73fQcC5RXI9vv3v1mjlwoGOoX(ym1pHz7i2cKePS9BTUTTazl5ClRjhmFaMcSr(aI0xduHW)aSu3(BK7Jh(GexTEyphMmMtiBoJJQIIsm2IIW)cpC26YCFiBzUUj40awOyF0uRR7JIIPYtbSq90sjYz9tW1SE8eWlTukQ3TBAQhAQL8NLCzqADSKd6tdpyLqwcRj7TJ1)ATIaAdhIBSbhF0Mfemz2EJyFtgNwaEtMRROjZ1J)3n4WK5g3TjZnXyY0fDEZKzhyWRjt3Mm7e)JDzYGlEp7WK5MVuagnzULlhqWWciFhlRr2IQbwle0KzF1bFFntMB9YfsZzZaO7T94hBo7rOKMuAu2(PPus2(dUjj5AAUDKlDZT6xWZT4AODhwtTxQqk38MbPSjuI7iFYwrmpCKcHMx(utMtoChqm)tVubXSpcvGxFxi4JTyY(Bg1Y)jToJgpB5aJp0X6jPsVDyg9F(Y4mAhwTXKz)2t5UdJTqF2dmEs4Q)Jv3FlQupwSuPIfFix9WHm6v92wVstIn3Rx1D1WUtoy1cv3B7v5oEIjBQiHsyJWCPK3f2GCJIn(OgvOIlfzCnKZP7c)KkPA04gHMEwrDdAZ1D9mJeXvI4UglAJ9PHdn2yr5O18MB42dXnu00UIn2yJhpkvB)HK2oCJFgk83sbFIV6ZIUHlwn8xgB3D5sYPinML1JzS0fItqsSGmeqt3qGSv0meLYXAJx3AhnRTLgXJnfFw7gy3owSGMO1o1DDeBtiQXFtRKRISqjXSuxyHntjSUIMb4Ebsvjk7DaUb4KeljACDetDhLCvXmA4XIY6p51F2SkY4(GSXGcznu0YWfAGyJNArbTSwAD(K7bBSXs5lljfrulReQgsUXaIiKesZqh(BzQA2bX6jSHgxW23yzHRff1dTC6chDY5D7n5KrkC67cIXqSeDdvp6qW)k8nGVj8TGVn8DGVl89G)n47d)a4hc)i4fG)D4CW)b8Fc)xW)n8)a)y4Na)u4)f(zWph(fW)NjZvzYGjLUAtgml01yYCTMmVctMxPjZ2wfpDKTispvrLztiVQo9pJjQt2ySleIX7UoXOnX31ZJj(4skohsQj6XMCtnHOetKYBrIs4kTyj3yATNYMwZIqJsUTeDl)O7leFRuC2(DHsXrIIcs8BeddvupuDNqr(T(jOoRzQIyX8P0Xeek5ZiPOKZIwK17GiXtvCgUjQaonzMyn8I1CVGjZ93cXi515laE1ibzrIYguNOTSUKyougfSTlLGNNf3guetBOmpDxlsJLfQXo6gAce77PMub7pt2Y64gidTcviDfFaUZmLvgZzLXZ3Th4mm0DfLMnF3vYT9UNJzrQF8in7cvBwYdFv81Y6sK9ghxK6oQww6QzJ7zwEZSAg802M2A8DAj6Fjc6nzoQjZXUecVnzoEdy7xG5REjdpBY8i8BKYxMmNq9oBf(kKrus0OYugfllJn6nJIKHf2TxUcdgfDY0iVU7i2912ESlgtrHTMm8WZBYiS(GvtMmMmzjdt4wdvhsAYKVr4OjtHQ4qtgSwuIKMYK5KMmtJBmtgj8GyPljOP9XX6V)aUVcB2)GDK8kFzTkwZ)EsiFKH8gkqqTop))axzm))O1N)hXKb3W4UGptg)DgfGVXtVdom3w2PdtIYi1Dqi3kGKrAIzTwVKF1M(5YwlFYHeYvHgAa0PI4cLqKzT9Zr)PD4AT3i2USHOkybnKUUREOXbyVQDt3wVcYkAiLzqAynEq8RIxZqkv1MB5g0aD1AB2aPe6gTs6)wrtWI20ZzNMxDNKRrK4nSXQFrI2B2z3VOc8VVna4NrcrvHrjVkwLEen0pTebgyMaPhqRsPJmNVokc8Gx5ic8Ti7wefQuur3GU8apD3iBkOToaRBioKG4tSfRvpnRRqw7SefyLK3syOPBMxDpnhbyv38YUFGgLOmz0nzmmzkJFPMXKzwIGIjZCB7r)sKXPkwIhMmZBY86X14XoxlwuzY84TGXnzEJ4k(MUOHYVWvp0fg(9d1o3QrH0NvwXOHnceBKTLWDZzBJ8Py(VmzC48A19SscQwq7j9oNNmi)(9nXWDeA)6UYbAxBN1nzEYdGNGTaWUAcUAY8wX)70BkK4zE1TfiUsJ2VF5dfsdQaV0nk0XfiFA(AE6DT0OT4T3oPab2cjfzYUhRBbXkmFMEoEp9N)yvc1ri2dDLdeRXq27VZgy9vSIyV)(A7REDhPCYMSj5YLIMTDP3Ixww6T2E2BdzEnRhNKQL7twRvZ94vV)t65ybhldxhbo)kVO5or4FCDDN4Dz5b51XIIzOac7z1QKaXv7kIMYS5CfP2zXHmvVP8I8Lw7jUe7C56SkFSIB8wiDi4z55ih5hb(QyL1X5kYKJqajazLQusrtTOfmjDApJwAeH4b6zWoctcTLGF59vdWTS9r0IE6AwkCQ0JhVPOjZrlbU55QVrQ09eVwdzY8EGLwLC)tnw0idhkESin2qVGJRIaK)TBU(HhmAiU1e9A9BfrLoAZnSk5gwNhW2Bt91IKi(GJNk6AEg(SItzQdGB3dkmxIePxZDvDjW29KsfB0OXJeDTJEbOpf22(6KmuKydES2CRVGJ93M6R2vQidNiXOtfJCOL4gpz62DpNx6NO2TgICMQW2L0OUXXdtcQEQo31kN1ZH9JPxOkSxlt(1eL4wTEnLvwne1qhxJtdaaI2iy9wu3rDnOhHCMxYIAN2leDCMlT)lA2QlaLOVuXwT3gyRQUWwncR2TPx4x3QKwMmNPtmwn4rLsuxKA5o4E1gQVJKzKJn3r7iJv4Temw7Rw8IVI1rBuMJCKkAj0XXlwcP74ALpADLIEFS95JnSh3SUjjSH97pyqo8v9hGZNFFEdW51dlRpoV(81Vhopb73p76eAgvr(0tJHjZBMVHZsbP(MmVftMNA9prfB1weEVxilc3iE(E3a8CoXzeLr0dTj5KhwZnj5pvVc5LcpT2GL7iSoYwkf9DBYee(aWv)9QhQKrgOXySS(25sZhRmNokRvaFQ(QAQO1qSQERnvEi8qAbsK5ATxW7RPchGoYB7eVwEMnAQz9n516zA55pLSt3Y9y3EdkmdwDkxTROyssLljkB9MCBRTNI0E16v7p7V5XaTY6c5WVQPm0eNg1sZh22zBKbIb1qOCkLuVZ1TgjR5qo17AJhnD1tYzs2R1EzJ5wUNRPH9Y2KzGTFXUr2MmrRg9ZMmdrsgETBzTjtmmuBeY(uBY8W13GAtMrHDCTMmJbyav8dWnGjtIRZKjjUYh5jVEtgotMuMmPPB1SjZ413I5g2Y)QUa(Y3UmpEEFcdK)iE6juQoWs3I7qwI4k7qsZkurVQd6sCFT1VilwtWzdDkY59bF7IZfENp2bhYkazmzEB1CBYttIhMnYXjK9z2(BCaVfJ5mNkDOtg3WNyiDcJ5F56hVmMmFumJzrkJzOl5w4E)10JDjf5QiSwo5k0fVBqF3)61U4o2s42FUXU7gp3y4RlU5SA(rBNl3(RQITk830EFU1i57lNGxMmFEBy10vkiAi1xQXsE0ocR(yVOaROWLxccNoR1UVvdYBbTs7VTiltM)OxSWtxGbi4Lnev0KQJugn8et6T3oIO(4xgru7BtEUup)Pv(IvPvES3EBN8pBZkM9YwGGUy(rZO0RrL56iq4tSLgiCx90wCWQnPd(wAyWMm6(Rp5p)WCpCK5Mo)jtorhN8)Z3sp5Vo7NNjZ74LxZ4vKZfzIJjp2rt5VJZ4p7wBEFmfy7MYxQUXZB558ppcN)6qG(ow0(fIQopBI(6ie4tU1gce)h3ElkA0njxPdcWJbTbemS8S(RejB2sHu7ii4tTfx)VmTfeOUZ24rSR0bd4XI2agoL3EYIg19KrNyKocgEUTKGHA(y4XEU2dg6QvNFUf3rdDch8CTdhe8iJeUVa6X86EYoId(0VS2ndnGOE6iTpKfBXD5xzJNA8u1uhpPK(KCti5D6qfZ0r80N5L54PQlxnqO1z1Q2SblBPxTAtT584rJ1UzMvHxzN(KdDY5R4rq1thHxRSLwhMVXd1EqXEA)EQDLpUapGS(4cTjMmWKgJxeD8o7sR)IT04IRq9R9Mccu1622JbqUhqvn(WJ3)iD2phF2xAGbiXKq4bsmzCYNdQg)eSRjkpnYWfPOgpS3rLrLQuT0g)(rnOIwgKGMGCwK6oAyJMhnAO4PSpw45A5yHBYmWnCjBR0ztNi5gUz68xk3m9vR)kMCMKx22f9jsfUVhE0zsfFC2tFW1lu)ECsijTGObQe9aF9U(owhjHY8qC1BPnh2Ry4A2RvSKBlyJhCxHE0VSBdEy)Hjx3qipzY8932767wVLnz(bT2eMm)qEIO3pQLBl2h5c620FVNx3g8AyfKRSgMd(l)mhxaHg1NNNeEu92A4rfl(etncAwKKwLPSLXsorYPC7XIFr1FY8CX5sRhEEc)Y3BJ4x(Mxg5x2uh9vsWNgxZ()Ic2hNpw2GSuj5NN1d5WEPUl6Hk0fjeuDLQC2SiYxPAsC1DMLRDWcJLJ)LsRrSPMP3tJra3MEkM1om0NPhJJCK(MFOef74u836fHP47CdpmcFoAW6ersrgPZ3WrDUFplRI0iF(DjFypxqiFESoIKjxORZs(ejikJsAvoFB43nzCVL4dGZE74haNyNVqg7a6rXWVs)EkfcLVJGGVDTqGm2VSabMm)u7j)N5oiFs048WgG1hn1pnTpoCs)EOPSH93Fa2W9X6XljXF4aEyzjj4BWDGabiPbDh2VVa4m6pi(w86nyypU7dFJEc6NK0x4Gb8Zss8YX2xWab584LL8y9YYYst9st9r(kCfiyyV(CheJkd4gFPBV4M1hB)bjPbiFOdD7bRXWpZK5NtqNMm)Ilke5g5iKZSEXX7lQ4XnNAU7813oCj6KhLZt0EoLVuJ1rC535YpUS7sDNR7CN(v10h10JdbHVUjZey1Vj9q7q4K8Hh953w1p8OxFTp8OwABDX(HhLOjP)TFHRZN9hm4RJOhRTAK0V6Op0Y5lgj3iL0gFSmdr(cPI1QfRBP1xAuSGy36CEpS)d7U7zUM3W)p
```
