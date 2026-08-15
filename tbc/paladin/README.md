# Paladin — TBC WeakAuras (All Specs v9)

One import string covering all three specs. Elements load through Spell Known gates, so
the HUD adapts to your talents with no action from you.
Toolkit setup, once: `cd ../../tools/tbc-weakaura-creator/scripts && ./setup.sh`.

## All Specs — v9 (`all-specs.txt`, seed 20260811)

The full Holy / Protection / Retribution HUD: 48 auras in one import, arranged as a top-level
group at (0, -140) with five draggable sub-groups — the fifth being the PvP column added in v5,
which only ever loads inside an arena or a battleground. Every trigger matches by spell ID
(never by name), so it works unchanged on a zhCN client. `internalVersion` stays 45 /
`tocversion` 20501; modern WeakAuras migrates that forward on import.

## v9 — the middle of your screen is yours again

**What changed:** the three 172px bars that sat under your character since v1 — health, mana,
threat — are gone. In their place are **two unit orbs**, flanking the middle instead of filling
it: **you on the left, your target on the right**, each a live 3D portrait ringed by its own
progress arcs with the percentages underneath.

```
        ( 88%  )                                          ( 62% )
       ( ( 🧑 ) )        ← character stands here →       ( ( 👹 ) )
        ( 74%  )                                          threat 41%
        ▁▁▁▁▁▁▁ swing
```

**The player orb (left, at x = −252).** Outer ring = health, inner ring = mana, live portrait
in the middle, the two percentages stacked below it. The main-hand **swing runway** for seal
twisting rides underneath as a short bar — see *Why the swing timer is still a bar* below. Both
rings still fade to 50% out of combat, exactly as the bars did.

**The target orb (right, at x = +252).** Outermost ring = **your threat on that target**, then
health, then the target's portrait. Threat's percentage sits *above* its ring, health's below,
so the two numbers never queue up under one orb. The whole cluster **vanishes completely when
you have no target** — that is not a load gate or a condition, it is the health trigger
producing no state at all for a unit that does not exist, so there is nothing to switch off.

**Every warning the bars carried is still here, in the same colours:**

| Signal | v8 (bar) | v9 (orb) |
|---|---|---|
| Mana under 20% | bar turns red | mana ring turns the same red |
| Threat at 70%+ | bar turns orange | threat ring turns the same orange |
| You hold aggro | bar turns red | threat ring turns the same red |
| Threat at 80%+ (Ret only) | red rectangle pulsing over the bar | red halo pulsing around the target orb |
| Out of combat | health and mana bars at 50% alpha | health and mana rings at 50% alpha |

Two signals are **new**, both free because a ring says less with length than a bar does and has
to say more with colour: your own health ring turns red **under 30%**, and the target's health
ring turns red **under 20%** — which on an enemy is the Hammer of Wrath execute window the alert
column is already prompting for, and on a friendly target is the Lay on Hands emergency.

### Nothing is orphaned — you do not have to delete anything

This is worth stating plainly, because migrations like this normally leave litter. The three
bars were **transformed, not replaced**: `Paladin - Health`, `Paladin - Mana` and
`Paladin - Threat` keep their aura ids *and* their UIDs and simply became ring displays, and
`Paladin - Threat Flash` kept its id and UID and became the halo. WeakAuras matches auras across
imports by UID, so all four update in place. Only five auras are genuinely new (the two cluster
groups, the target's health ring, and the two portraits), and they append after everything else.
43 auras → 48, zero removals, `changed=0` on the UID continuity check.

**One thing to watch in the Update dialog:** leave the **Display** category ticked. That is the
category that carries the region type, and unticking it would keep the old bar shapes while
accepting the new positions — the one combination that looks broken. If you have dragged the
HUD around in game, untick **Arrangement** as usual; the Resources group keeps its own UID, so
your dragged position for it survives.

### Why the swing timer is still a bar

`Paladin - Swing Timer` was the one thing in the old stack that is **not a unit resource**, and
it did not become a ring:

1. It is a property of your weapon swing, not of the player or the target, so there is no unit
   whose orb it would ring.
2. A sub-second window is judged as *distance to an edge*. On a linear bar the 0.4s twist window
   is a visible run-up to a fixed right-hand edge; wrapped onto an arc it becomes a rotating tick
   with no edge to aim at. That judgement is the entire skill the element exists to support.

So it stays a bar — 140x9 instead of 172x10 — and sits **under the player orb** rather than back
in the vacated centre. It still turns gold in the last 0.4s, still only exists while you are
actually swinging, and is still gated on Seal of Command.

It is a *sibling* of the two orbs inside Resources rather than a child of the player orb, so it
can be dragged somewhere personal — many twisters want a sub-second window right under the
crosshair — without dragging your health and mana rings along with it, and so it survives if you
turn the player orb off in favour of your unit frames.

### Nothing was lost on the way across

- **No resource breakpoint marks were lost, because this pack never had any.** The tick marks
  that mark thresholds on a bar (rogue's 35/40 energy lines, druid's bear-rage marks) are an
  aurabar-only sub-region and genuinely cannot be ported to a ring. The paladin pack does not
  use them: its one resource threshold is "mana under 20%", which was a colour change on the bar
  and is the same colour change on the ring.
- **No numbers were lost.** Health %, mana % and threat % all still print, on the ring they
  belong to.
- **Threat keeps both of its load gates** — party/raid only, and never inside an arena.

### Two failure modes that were designed out

Worth knowing about, because both are invisible until they bite:

- **A ring at "no data" fills, where a bar empties.** WeakAuras draws a bar with a zero total as
  *empty* and a ring with a zero total as *full*. Threat hits a zero total whenever your threat
  value is zero — the moment before your first hit lands, and right after a Divine Shield drops
  you off the table — so a naive port would slam the threat ring to a complete circle, meaning
  "you are at the pull threshold", while the colour stayed green. Every ring here carries an
  explicit hide-when-there-is-no-data condition, so it disappears instead of lying.
- **`barColor` does not exist on a ring.** The property is `foregroundColor`, and WeakAuras
  silently *skips* a condition whose property the region does not have — no error, no warning in
  the editor, the escalation simply never fires. Every colour condition that moved onto a ring
  was renamed; the swing bar, still a bar, correctly kept `barColor`.

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

- **Paladin - Swing Timer** — a slim main-hand swing bar under the resource stack (v9: under
  the *player orb*, and 140x9 rather than 172x10). It drains
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

### Resources (two unit orbs, group offset (0, 62))

Since v9 this group holds two draggable cluster groups instead of a bar stack, one per unit, at
x = −252 and x = +252 — clear of the Alerts column (x = −150), the PvP column (x = +150) and the
cooldown row underneath, so the middle of the screen carries nothing.

**Player Orb (left).** An 88px **Health** ring (green) outside a 60px **Mana** ring (blue),
around a 28px live portrait, with `%percenthealth%` and `%percentpower%` stacked below. Both
rings fade to 50% alpha out of combat. Mana turns red below 20%, because mana is the paladin
resource in all three specs — it is what ends a tank's threat, a healer's raid, and a ret's
uptime; health turns red below 30% (new in v9). The 140x9 **Swing Timer** runway sits below the
orb — a sibling of both clusters rather than a child of either, so it drags on its own — gated to
Seal of Command. The portraits do not fade out of combat: they are the anchor you find the
cluster by.

**Target Orb (right).** A 118px **Threat** ring outermost, an 88px **Health** ring inside it, a
28px portrait, `%threatpct%` printed above the outer ring and `%percenthealth%` below the inner
one. Threat only loads in a party or raid — and, since v6, never inside an arena, which has no
threat table — and only fills while you have a target: green normally, orange from 70%, red once
you actually hold aggro (for Protection that red is the goal state, not an alarm). A red
**Threat Flash** halo pulses just outside the threat ring at 80%+ threat, gated to Retribution
only so a tank at 100% is never nagged, and carrying the same not-in-an-arena gate. Target health
turns red below 20% — the execute window on an enemy, the emergency on an ally. The whole cluster
is absent whenever you have no target, which is why it carries no out-of-combat fade: it is
already invisible unless you have deliberately targeted something.

There is deliberately **no target mana ring**: most TBC bosses report mana as their primary bar
and sit near full all fight, and v6 already settled the PvP half of the question for this pack —
a paladin has no mana drain, burn or punish (Judgement of Wisdom *gives* the attacker mana), so
an opponent's mana would not change one paladin button press. See *Still not built: an enemy mana
bar* above.

Each ring is fed by exactly one progress trigger, because WeakAuras rewrites a v45 ring's
progress source to *Automatic* on import and Automatic reads the first active trigger — health
and mana can never share one region. That constraint is what makes the concentric layout the
right shape rather than a decorative one.

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
place, uncheck **Arrangement** in the Update dialog to keep your positions — but leave
**Display** ticked when coming from v8 or earlier, or the three resource bars will keep their
old bar shapes instead of becoming rings. Nothing needs deleting afterwards: v9 transformed the
bars in place rather than replacing them, so there are no leftover auras from the old layout.

## Import string (v9)

```
!WA:2!L33E0nY159PlXkNvqsw7YvALeTEaTs7kszPv4jb4ATrcaeCjOibWoaKC5Q1IyaMbyMLdMz2zgqsqlPeXOOSYzJJdTQTJBCSkJTsAA65uXK48OXVyDSDBSpNBytCN0020UNexvDCovN94wBNM20V7DgamaeCb3xkIA)J9Yb3xZCV3FF)(ECVZSOP6T4R94N9(3OaBX540uuJRiPOnMlxUY4Y7HdP2BrfzdnfjjEU4cIsCA8Yhr92ZWkXYjk75X8KrITgVMN0AfCMBowTY8g0CVJM5MDbr5YEYjwHx78fu0441IzFtv3tmjXLwIvJZtoffjdr1cQSWTYq9oR38CXIdDrujjpzv5lQVMOCjfTkSgIkYUly1BcA1sxQKoVXZVQgFzOGC1u5zkRPuvDvRAKvCj(BCd2QgckAPvjTv39AwfznUriKRcWqUKyz3m6fzL4DPXwKwXbz0ny1mCxOKOSOUG7yWFmCVSHMy5Y8A6PoKM9LFYygK7lBvnw)Rts1v5LKe507RxVXQcnQGkDsBzA(j50DFE9Qf4NhgUzRwQK4IRnB8OzZnB2CrzY1OOmA8qrmzZKy8XVqvD(elcpxzT6H8mYSv41DVkhFbOhidBTrtmEMrMC8vQkB)y5Enor9txvggnZZ7NvssDVS0RZzv(ekC8)w3WkSYIwZQdIVJrwNNvNpRbSsu2q4Na3xmzfz(n4GXePgZsgNA68W8fN(YKQsUZ4dhRcRO8i4hdAa(W4hh7f7d(7(BpN1TM4TwYUPlikBWRjZknf0LqN)mROZlvkJcKDH4jsLlbZbe5u3xt0edVUsvTI86RAOuCERgT7m3XAL0G5c4zM1G11fyLlcl1JqYI8SviBCMejsTMv20ohpO)QICRXmrMtwo0qZmiFeBarsz4XY1QW8pdfmbtVwfKGRmV6EZEMQac1Zivbe50cIg8RsMgeTWuXKuy5CRTO1ydD27hJAisH75iQ7P5WyuEwjdHZ3mJjyLzvV7njHLrbWxSIg43h(NaVBCySB34BwaFli8TIF)4B7gX7XnEVu8lUx3495cF7WcOB8(DJVt347k1HW39NeM8)a47bqH47fFF473n2d(bWha)G4hkp(GUXhc)W4(DJha)i4p4V1nGFucaO9fr)DFzfh4MWbFgCi8GWcg2focSOGhYf(i4pe(jWdIp6AL45sep4imtoDm8t6c)uUXrXXWXDJh2noX3(2o7rka4BTzRHS(7IiCc0ASCNUQUbp3eSl2tZFik3dzka6x1BNJxN1Gan5j0keXEzoH10jl98lcfWN3zDgrb4iSQdJUeRSbAzEzUOYLL4FP9ddGZRQPuwJxxplfL9i3Zn0dzmbt90j494EznfdQyaIHvsvG1fo(roetrb(IZnc(UVXLNNvtKTGe)YIYXvQuG1GzEwPQ8OdOOEGJEuTIcSYL5177q4zOWILH7hinzudp5HWtb9Gl80BazueK9fOye8mhiGxO19(e4tsA2yK2nuMD59W(8BL6c)mxOuJXfLrRrFTsf2fR3p9s6Md8eh1QFq4Nbpj(P67S7xTxdyMAwDbwoLfoHn4DfAEKe19CWwEGo4bv3JJg0Kb98w5wx(nw0jZLwDF0mbUxfc)sXPf5meIff(5fOfaKB8C0mFXnSepNX6b4CUwNwbYkUyPA4bxLoXtxuJLkDQe4(0aHusDwLwXI11G5Y6rVeObtDpJOjUKNJxLLJqm4jxovVngxZAPjz2wgCZYXxeycLMvvdUGqUGAz6X(PdTbnVfaMHP1yvxEA7l2OXTMYgNEYCJNmvc75RwOFuhOlpi0ftkxltjjffnRPJ5HNjaDLV5nIOC7(TN7QV4PEWU05wzwiv1kf41kiWlwwW4nUSL9lueaXZwJGgd6ZjdK6Ear5O2sTuHyb19wOHyQTaQA4KeLaLylYFQOCCPL1p108SZfLOd9utWZjYEk7AQFkgWwIz95vDXdBuMLsYSkv)mvcgHhEQvG74SfLy11ZxWauKlBSFMkvbBlCZqZ9qf0fj1vlt0XJoCYu4xE)4xjFmqPCX9JFz3X0HPtYf476zTjpVxcHjdvBCblABBI0Lj3kIM98u60gCPoBh(CQ3(Kqv8exGLysbVMiGNlQxNl(J1wBRZdxOIOMMIMq7ZGIYc4B9c1jPmSMwwwbuec6l0DVcGnK5i60zInEIudtneHPoJ151ROOyiKXU15xLYaoIOMUHWA29rrjrvbcR9fS7CcSM0HQ3E8XJorMCPJnE04pD0HhozUKtbq7MlN2GVl0mNgCdeOrOqlxuPIk5olq0rmc(dpgLalejnCesQ)qUaLgmlqieEd192KvZgaGxguKWp9uz4K6pqbU(1eLj2aWlScDOqEolKmv2KdNynfnryfJoWxj(4PJ)0tNmBclK6I2iv3U1OnJNt4Shbpgc)0eDo4X7bprD9l4uc405XzeWhhHzOQiWz3SwbCoeEsQQakX7nINgFcGI1I03IV1YkGNXbp)62YKQklWRb08(BLMhEgJeQ5eKpyQ5zWF4gTEzGz3UL96RZe74zr48x4GoVnh8G4cwMlueZH5XLWLFrSWVYUWIWW5045aCReUYywRx01LqUCHLXk4ZGu7FRyvODTdgl8IynSo2axfpp0V1YR(qx8MALh(5XlDh4pcs9XV41EZC04xO2LVLl)uBM4c)tlGFraSrTI5NHWRGFP84FwkXWp3HWNf)kw8g4pknRF(MmgFXMs(mzOlpGK(k0NBYmdQfH(niminklFh5pW)IDJRa)XfW)saTaEf8NWn(vX)tWFse(tLh)PfW)Yurz8Nb)pf)RGWF23ua)RsL9ogr2daK(OdD6c9qurp8NRg(1OszdxE0mlQEMLMoYa4vfW)A4pp(lGFD8VEdzh8VHWzdSwfqKtkP(KuAqWiv)SQIcePil5hnA5eJ52BttH7OnQ1hU)cDB4UUQTnXNurPsEqGCDR7rjrj(KC47BvRFQYce13N1Z3S6aAQgcKsD8B4zcSb9fgA7T420s(L15ptvE5I8UCi)d2KhnwkWnj8TYqVf4B7bAEVQQFCycR5V1wcPXYnpO0Mx4Yh3cRwp5DApbVech4MPWvYY7O25wZX4vBX)69G)CdrXdhDTiNzAFtfFSrcuScHjtDp06nSOoXj1KGt2cu(mhpZgl5SZQ1U3nJ507MCcA8SgQ7V9C8mcOcwOP39nczGLEvN()yxWou)F2vh8)jrwPzIAeq54HlUz)F(632LRgOD1rnqet)nSwfkAa6wctT9)N0wfXy0vTbPmaTQvHHTmOWfpJlNQU6OlhoA0Aw3jQJoBTBguTrRFWgpvnufP(OBIUVrL6exVtnxVsDfxQpWfPtAOEPP2TW(Ti9OxhSUkoNQT6Gr0n7Xw01T0DckTaTC4x4V9ARwOxgiQwJOZamHLeFR8utqjMSkyXFPzxaC9HWV)8XarhU8BfP28mQGLZ1Y7xDEONGHOrTkSY59BWlNFvJfa1T1kjoppyhn9684dN3sK61RtxVQ1ecH8hm2MiWcsuNN8m1SG8erU7f)xbwcVhBwGSIgvPgMrfdVIvM9TSnK0FiconcjjGLUS)wBDzlnvzJCbvoHpJr3ADzEOctKENoi)U1hKB0C8aR85X)xGXcWB8Fnp(7CGiEHrh4GydCbXzEwdfnIOgDqJ)V1PbPBWBel)vT0cxxvCKqer5pUfbNMTf4eb8x1pyXnHSOZ4Rs4(kqSSgwai)gk(nxLgEImvL05xUEO761hTjBc8PUxor9IA8g8Z2i8gTae)E1rHa5dmXAZY9VLWvnPRvBgEfbcn0rxB8iJp9GXpr)Xul1Ga8fgE3fSCHxap8RJ)U2qu8)H6QETaMGM4)SwrSu8enOPZjRSGCE8FUWQn)5U)OXTaZyZ84)I84)J5X)L5X)NYJ)ptXRFUH39vjI1hPbDh(uTBS(BgRf(q8Z2fwqmBNSc)CUA1k83CmkRKkQnIj8caNdioU09tODEoGw7fEJ3fy9BNmK7V6QSDR)7WF43uKkA)g2I2IsAtNDGSQHor1lIzQ4FBQXP4FhhMMI)DV0mk9Ipw(IelrX)EqT(9H)9hqS1e)hEzAHj(FTlh4pIPL4)iyA6lb2uI)YeljXFfe(RELA5i(R1InJ)j41r4)noTrKZ3elK1BHu(N7KurI)yBBcXFde(BIoRxqkKvBoAW7UJvflQiBfZ075giHZfFlF7BKmlVbTsncbH6EB53eh2XCXinwytZ6R5yNJiZ42rCrGvMJUkeJCf2FBRe0Nehrd02QSLlWAVzpn9T1kDqWAMVVW60NlRqyaIRp1JSFCFRrIEc0UzH)npUVv0RAVLtBy9h7i65hkUEokwXaXEtoSFmObh1oN6bWZE7gMLNRmpow9FruL7c)c7dp88eeZ)Zw5gBb6827o9NYc5CE6JES6r(b)FNi)c2kBT(eV5mbaMiYBA2dlaF5CuFc0k0PoDroEgMKhB0Cx(amhctRrVfJsdX4rXFpM4s8SYaqY6wxpeG93meGXz1nG19ySANAYKpwZF9yzPihAZeAaBVXylbUbIOCcF9DBJCxAUYd0FGe5IgRgqky)eiYXXlZKkXujyWFHvhnntYtMovUOJJJ3xdM7ZZVOQOLUscSdpJFGfXjroOWMOM2FdtN)7jIJFwAmUGScVjVICUrOGtoEIs38n1(AM9yvbiqfWclpdt3hp17YX2ePivZtwbrEjoptQ60HQXjZN6EoMgmLz7C0nv35O3L7D0fAokIbJx9o4RuKqdxzo)dv23c(3SVsOZ(G4FaHL5r3Lnv(gfvuK4aRbagdv(8Rx)NK9Sta)dZ3Yy91oeJFV(cfKXVpVrGuV(JeMMgHMoejDiV0uF0u)00am(d7luiARi54BqsAaVHOPdstdttJqRjP3ceMu6q(SsJqtj9)q(9sQtyVmb8fb6Fi1RpAFs7NqwPHj1HMJVbP3LG0(piTNdoeTuV0sds7NqfGYc71R1FcUTwqd(mxyoEE1OK4FBWqa(cuU(VVa(PoY3DJYsklmIMv8oQzzJDmsEcRdmXhtYE3FewHKxw6(MVk5YXP7C8DSg5667ycTonjJOLvF)kS2lhso07yobXIZjZRR7Az6pbVS2Oqvddf50wbPM2xJlcvzV07xmRdcWz3h16QdCq1ozEfQTyCsPeB3TV1tMkvcMzJLoxU0tGx6ETCSdmVg)pyI6bzICr7yt0UYBIUrCmt07d4Rp(2td)TI)HejsaEF8X8fAEMk(pZPX72eDV4)g6tJjQxQZllxh)MVonNj6UvV965s4mhwuNSlJGIqcX3XTfmjsB9zz)VTGzB5S)nLdWlaMn5KxGif6Gs0eDNG1SHCscMh)mKni)W(omzYNW6mPR6YKs1nVYeD)WuKNMIFVUT4xVeiBelaDqAQ11dsb0urRiwca0sjICHjqC)(8fjaTuQaGxV0uF0ulrrlr0HO1XsKyqny(kTSeyTSTbCTjnOnAuMjgzYXBvMWeDmNIbMOrTW(MOKcMOXG)90WI143HjAcasKYEXlnGJnrzmrhh(bJjkRjk3EnrtE1axAIM6AgAmglFWzkAuuqnsNqJMOt4ahcJWzUwb6C3ku6X2kKKnr(yuMuk3Q)W0ukZB4H2MmFTSkp2vVvz9l7vzOgl9awlYxTWm352gZSnS484FP2XopD8Yrxs(mtZjhR7yNpW7EWo9rOhce8YbPStKpy74nXpU912ufRgzYJnt)zugO7RT3Z1W12UPmYeDs7vFVXkdm(hyYm4E(nvVN2m9EIKzZMm1X80pdVXaQ37wvAgnfOyhhRrMrQxOZnOWPP5PspDlfXwbCz1Jsjptd(si48wnoBnpkYqnK509a3PkQgopDB5wqu3G2D92mZ4X9KoLNjs48zA0OtmrcgAnDUBkrzowICEsoXetMkb1RGes3e(w(AuRQTCeG4)ur(B9k1tG1apBRwrolPZSCXUGLntmSsILLXdQPBWsoFH0qGmSZOBOzDwd5ZVmSuz3b7Z1kL1eToiq3SvepIHV115QjZwrSinK2G7mX0v0mWhEzsvjgfEaMHzKeRiACZKadmo5kHcAWCrv9x6wop4ll8miBmcBrdfTcmrho5KzxHvROL1PV0(bNswTuvjP4IAfbpYRJLDUrwrL41m0jXYX29eIxwGdjx2(bbcwai3IT6ORLR8jMEjVbYmD8YN9HW)auZGtTLwpDit0dyIoGj6bnrpKj6GMiiNh2e1VjAat0JyI(GMOh1e9yMOdBIECtKxtKptKFteiVg0ebuwqFh2efXenKj6iMOpKj6jmrh1e9tAIEst0tzIIAIaMJ4MOHnrjmrJSbSAvuGxpRGYcPL3qN(Nje1jhKMlhc0hPjbQnb5yWyLHjJ4I8sTqJ2YPFGqOceU5TiBjCQwSPBd6Vx2M(ZI4JscUk9CcrpHE5BNk0oKYuQqYXNLUNOaCs9qnJsb536NIgh6zfaQGz1bseLsfKuu4SOp9hyeEXZimpZu1i0NV6MPpfAsFUyB0NKb1BI9ProETPRAqJO)A6sIC8fuahHQGFl)qFqHvDGy9S7zf6PyM65Kozdullyq9pd3xHIv1HoOaTc1ipkbXac5ZALXIwz8w96dpjIEwQOzNV3AC3uVlIwHUPcKUD56Dl5MVbCTSUe545bfPU36LLRE2WtM12OupJ80(M2B57Mk939kzyI(KMOp1vrzat0N2HaWB3ZsxDb9MOF58xmB6mrFg1hSDmoBbrjrJAZAiuvg8YUGIKHfaFaMYJKG)054d4T7a8ADgGdapk22e9RIFlt0NBRr0MOxZe9pJmzTQj6xRjU1e95DIznrFH6Gvt0RBI(1jDLj63We9ph6mt0Vjml9V4QeKRpg)HchX77frbhSRmDLQQvZch4lT8XpwGOrgsBBGdw69k4GNTjoymtKQj6mMintKE3rdqdp7EzaQWIZfJCWOv3lHlSmVmVMyrlLS53OLFUMLoxgEwUA0ZtgD1ifBfEYcxFm0FAFCtV742HjYt9Z5PN(PVWidO2l9OduwwrJNCApbRO4ZVbOIrkB9UBnhw1UrJ9DLucDB8jp)wB)1k2S5fNlV6(ixZtEXuCw9RquFRbA)DEbGh)IiauqINA8JsjvWxbE6lkKLOWWZhj3WA1QC8fd2DrHpY7vefKbe93OX(2DQd43BJTmLUTDumZhlVfoVLdIEE1936btV(5NO3NWPWIj6nmrRzI(TH75VJj63LidyI(I7(z)3tg8)EwiFt0VVj6paQXF4fAZbmt0FuBWxt0xcQ4xoV1nGEMnPWDbfDdQ2U8oo8LK4gUsJs0SUIFR3k4lps(V3vag)17uS(OW(ZlRy44WtaE5BXc0A22shu5I3MmREjzrqrjwvl4)0bw0xb(qHco1ODh()CVxstqlW)qnogRoH)MOVg8V13wi7x9H7iWEDNHp4IIQVY4EPRw09Z01vc1BPgrHEZmUTfj6UzZb4bMImz)(1TqALxQq)NS)WLMPw0UJ0E(3lH0CESu(r2aSFSfv0FxJddrZ45C6n7IZ1mlv7OoBHRD6SRFaiQdG(GBfrLQvaD2Sp69hqp8P9nZqtuGP7WOx4DUqCAIURTmgNpKveU3sNtMNcqSxFRtoCo19extzbopXB8IDtw03wr5(AGRjxLJaEt2M)CHl(2EDi8FrEgY7yoB(6OMTiOoYKJ0i5TZqQwffnvblatUC(gVYySPI0)iDhW8tTJG35Z08CCB)w)tFFUNjw2CtMQLJbUR2EBKUqZnbU136ut0FgEMniTF2jseF0OPsg3zh92U(8ea93T16hBKerz20XopS1X51vhAWgKgSf3G)LDO(AXtNAKjZMyt3JG2hfCs0P70nkgt6052uRQRGSt3PSjhprQ4j28Sxe6DXFhhozIgp5iZ0HM(2U(QDO(Q7jB8rtNE8ztsEn5zMmtUo1MlrZxu7vJN8E8tEnlDyl(5IrohweBHxPr5(9D4qand1U5gzMFtMfB17nmMzJOu3L8mj98lqSwbSRrDVnTyFmYl8Br(ozDdXgOVyUqx5SwFV)XL16UDWAvxvxdIRoT5CWyUo5Lj6pTBmxocstfAeATch9aAhBWJxySzw8eDN56NEhbZvFnEBlx36JQHmd5TRVTx8sq5j(7Vn0D(SnnA6Z4FWG(J5ZRFVKe)XcfAOHyGRchHjyOGbIWeWNF)bzcemyyFm(gkCi)BXXlPUea1dtt0xVD3knr)XMOVX22vYDgkLV7lhLYoX1p2fbxZjoVOmp9Rgc5nYUrKxkDMbyljfBoTrQ2D49lUJYHaOflyI2pUN3Q5ban(Wop5On38zA(GnE68fTogRQ3xlfTjEw1pqlLhfMulto11w7CDFTu4W05E7Wd2290PNPn3sAR7PvmfvkoxBTXU)gHDEWalpDQOKssvRikBnsU3n)KYR9W61FEUNwNd0QQZYbd1SgAIZX3w3hZocEKjIr0455uQO(GBznY0ikFQp0fF20t)zMpZaw78oqY8O7YXoVBIw(MUs32Dt0pt9d0Uj6NLK8YBEd2nr)CGtxNLSR6MOxP52PBI(O4B7gnr)84dBIo3byg2e9lCZMOpgu5FXx6wmrFCt0VKjAf6gJBI(en3qChhqH6bx(A3EIpzPGSdx64(6pA2Usx3w8twLeM8OslWwtVEect)4DmqkR0q0PBXg8s7nX(kl0FxYUkh16K9yI(wnIZY3KCqEUyrAHSX32FTTYBrDo)zYf90PmckgvhOo7PNl6585hauNcuQZOx1DcU57U6QkY1rAT9UOs1M30q4E29M12dUk35pddpsRFggGXX20T6oG1m7zx1XyL)oDoyDoPHVUdMz2Z7ZgEnxTYIgsdMDImNO7WR)xVJaVOWM3vcRoV1o91a8BbXYfQJimt0FZ7u4QlZt641wKvImQJvLF0PMoWaDhz9)(AiYQVTXN9LlxAMBUonZZDUoccoFRMSD9nGqxS04fugWO2IDhq8d3HdiEO(7iEyJwSsFNpCyB(Qm0eeS0OmpD8fNR0PZmv3bb)OD4GGTyJcnr)jxhUYxtMl(uZipXjYgQ7R8)4D66dawXoT0VAt3TFVHUGlH3BHMqHbNjry2eQl5p9GDhk83TthkK6h1zpqCgGLRladWerhadJkVqOAXlwSsu1Udg()SJ3oXcDemOUVoetTRlafWeshafNjq)f5h370jMASUdk(73HckAeJIN7R0zqXEApmQVxiqfDdp8v6eEyOJpwSbJONmG3P7oE4)715HPWbY6JgVZNbZ2ca)1b4kNV2qnXvk5onZusbMlQqHUJR()DDpUQUASHJUfAX6Ww3SZxl226uaatjBA3sBaZko3Pp2PxQMpwvFDhM9pSd3gN)6NSZGJ935DT76e8bmRS14dTPMoY0gtkWFYUhASEUHD44J3lhV8TfuOUxXDglW7Dyv1uJoz4X6ECsipkVBalqoeeXgo90PiFuTC(HfwtuEoEdpKIC(QWNqMVsT6L68RW1ikAf4z1iF7Lv3RJn2E8ertL1(LMNRTxAEt0Y36vTTU3FU0zUOBEF(RMBE)go(VuM5ZCnBx7NkBSbF6XNpBQj9F2dU1N1WxGCwOww0GVc9Lx7t8MKPmI4l(CQ3vhEX1sc1CaRd5UTaom9Uo91yZUpYJ7lg5AhN1kZEgy3FI)hn7zZEEK27cZE(Gqdn75rBRzj)xDz1m9p9LuZWd4NvU2MyqY)oedYL(zYcyoiNlRbA)CzLm1uZog)c8sA1M1wulZuzM1RplEg1qzkXKIjNESLi8mp8fLN5axd5z2MVwVKtb750S))NR(yc63)q(PY0VLFFK3Pn1BN(Is6HCwy9KTAXI8K)p5GCW((txRXllzsU8VRtNX2AfF)opcEB7LA)2Nl(57344hFWLowAHUVu)GVdSu)GD5TK4BqpSqXLuK51Z7415oSV1u51iF4QjFlnxMTujWgsYIm(9FEYNlcrz(mwLNVdm(Mi5DeF5GU7T3xoOKxQqh7duKIriLW(QeLVu3bdpuJZIzY)Xdmy2tyBqWR9aKVZCm(8hXFqAAiA6GmqsyF0u)XcfoI)yd63xassOyr853pjbAG3irIqshYBSqbJazeEiOjbcmumFEheAOVHcrsgm2qrc5NKeGX)GdfzigFb8tUTb873pnnanni5dAwKHIfiO3Ha0zeVWLEdaDBq)HhIKgH8HK0RViM9mKzphHGsn75dDfHmVibqXvKT6Gf)opUC7zg8((iDcFYF6tW4lr)Njy2j6o(8Gx7XN9wPxUE5o791YNo2tIdBIavlVkyGo5z0(mLs((U(T3D9VVRUB89D1YCSR0VVRetndCtx(gfA)HH)MS)oXtgK0pURhDTscX5gRI2Ktu4yKpeTGzVpPl7pORGezV6mboCOd7T3531Z)))
```
