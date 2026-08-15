# Paladin — TBC WeakAuras (All Specs v10)

One import string covering all three specs. Elements load through Spell Known gates, so
the HUD adapts to your talents with no action from you.
Toolkit setup, once: `cd ../../tools/tbc-weakaura-creator/scripts && ./setup.sh`.

## All Specs — v10 (`all-specs.txt`, seed 20260811)

The full Holy / Protection / Retribution HUD: 48 auras in one import, arranged as a top-level
group at (0, -140) with five draggable sub-groups — the fifth being the PvP column added in v5,
which only ever loads inside an arena or a battleground. Every trigger matches by spell ID
(never by name), so it works unchanged on a zhCN client. `internalVersion` stays 45 /
`tocversion` 20501; modern WeakAuras migrates that forward on import.

## v10 — the orbs are one shared size now, in every pack

**What changed:** nothing but geometry. Not one trigger, load gate, condition, colour, spell
ID or region type moved, no aura was added or removed, and every UID is identical to v9 — so
this imports as a plain in-place Update.

v9 shipped the unit orbs seven times over, once per class pack, and every pack had picked its
own ring diameters. Worse, the **two clusters inside this pack disagreed with each other**: the
player orb was 88px across and the target orb 118px, so the same two faces read as different
sizes side by side. That is what "the sizes look uneven" was. All seven packs now build from
one shared set of numbers:

| | v9 (paladin) | v10 (every pack) |
|---|---|---|
| Player health ring (outer) | 88 | **104** |
| Player mana ring | 60 | **78** |
| Target threat ring (outer) | 118 | **104** |
| Target health ring | 88 | **78** |
| Threat halo (Ret) | 132 | **104** — pulses *on* the threat ring |
| Portrait | 28 | **46** |
| Cluster offset | (±252, −78) | **(±260, −60)** |

Both clusters now present the **same outer diameter and the same portrait**; the target simply
nests one more ring inside. The percentages moved onto the shared baselines with them (health
14pt at −60, mana 11pt at −76, threat 11pt at +60 above the ring).

The ring art changed with the size: **Ring_20px replaces Ring_10px**. These annuli scale their
stroke with the drawn size, so the old 10px art at these diameters was a 4px wire — thin and
cheap-looking, the first thing anyone noticed about v9. The 20px art draws an 8px band on the
outer ring and 6px on the inner one.

The **swing runway did not move on screen**. The orbs rose 18px onto the shared cluster line and
the runway's offset absorbed the re-anchoring, so it sits exactly where it did — now with 22px
of clearance under the mana percentage instead of 5px, because the orb above it got shorter.

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

### Resources (two unit orbs, group offset (0, 140))

Since v9 this group holds two draggable cluster groups instead of a bar stack, one per unit. In
v10 each cluster carries the shared cross-pack offset — **(−260, −60)** for the player, **(+260,
−60)** for the target, the same pair every class pack uses, which is why the Resources group
anchors at the screen origin rather than under the character: the clusters' own offsets then
*are* their screen position. That keeps them clear of the Alerts column (x = −150), the PvP
column (x = +150) and the cooldown row underneath, so the middle of the screen carries nothing.

**Player Orb (left).** A 104px **Health** ring (green) outside a 78px **Mana** ring (blue),
around a 46px live portrait, with `%percenthealth%` and `%percentpower%` stacked below. Both
rings fade to 50% alpha out of combat. Mana turns red below 20%, because mana is the paladin
resource in all three specs — it is what ends a tank's threat, a healer's raid, and a ret's
uptime; health turns red below 30% (new in v9). The 140x9 **Swing Timer** runway sits below the
orb — a sibling of both clusters rather than a child of either, so it drags on its own — gated to
Seal of Command. The portraits do not fade out of combat: they are the anchor you find the
cluster by.

**Target Orb (right).** A 104px **Threat** ring outermost — the same outer diameter as the
player's health ring, which is the point of v10 — a 78px **Health** ring inside it, a 46px
portrait, `%threatpct%` printed above the outer ring and `%percenthealth%` below the inner one.
Threat only loads in a party or raid — and, since v6, never inside an arena, which has no
threat table — and only fills while you have a target: green normally, orange from 70%, red once
you actually hold aggro (for Protection that red is the goal state, not an alarm). A red
**Threat Flash** halo pulses at 80%+ threat, drawn at the same 104px as the threat ring since
v10 so it flares *on* that ring rather than hovering outside it, gated to Retribution only so a
tank at 100% is never nagged, and carrying the same not-in-an-arena gate. Target health
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
old bar shapes instead of becoming rings. Coming from v9, **Display** is also what carries the
new orb sizes and the new ring art across; leaving it unticked keeps the old uneven ones.
Nothing needs deleting afterwards: v9 transformed the bars in place rather than replacing them,
and v10 only resized what v9 built, so there are no leftover auras from any old layout.

## Import string (v10)

```
!WA:2!L33E0TX15D6lHCQmSDcfLTSnJTdSSLmPFidmaGauXQ2aGGIGMeaAaiPOSSjgamaZioyMrZmGKGXXTM11vj1nTLXBsA21jEzsC72n9C2LTn9X200WnnT7M0Z5A22St3xDxDAZ61NCoRp6KDtsFSTF37mayaiOa1lxtR)qxo4(AM79(7733J7DgHMUVcV2JDUp0M55kmFrnf1ykskAJ7YLR0U8EKGQ9vqr2qtrsIVymbrPIA8Yhv92sZjXvuu2ZJ6jTexnEnpP0Y7m3SCAL5nO5E7nZnZIIYL9KvScV25ZROvKxlQ9nvT3OsIlVmNwrpzvuKmevZRYb3kd17OEZZgng0frKK8KrLVG(6IYLu0QWziQi7oVvVjOvlvPs68gFJ9UMgFzOKS1u5zlRPuvDnRQKrCz(BCtUQgckAPujnw396wfznWriKR8WyUKyz3S6f4K4DPXvGwXHy1n40mCNVKOSOUG7OWFmCVIHMy5Y8A6jpSM9LFQOgK7lxvnoMniP6Q8ssIf17VpVrRcnkVkDwBfA(jkQ7(86vZZVamEZuTujXLwFUyrYKDUmzJWMTrrP14HIyZKo(etCHQ68XxcEUYy1d5yL5QWR7ETI85HEGmS1gl(ePhDQjwTQS9JL71lkQFMQYWOzbEgojj19XrVoRv5tQuK)lFdRYjlAnToe(2hDdEoD(mgWsrzdHFmC)rLvK53SimMi1yoY4utNhMVkQVcPQK7m(irRWjkpk(rHgGpc(XWEX(G)EG2ZzdRjER1SB6cIYg8AYCstdDj05p9Q68sLsRazNpw8KzJZEqXIQ7VjCILxxPQwbE91mukSGvJ2B6BF9sAWCb8mZzW56cCYfGL6rjzrE2YNjgB84jx3kBANJhIPQyX1zNm9PkhC4zhIpSnGiHm8y5Any(NLcMGPxRcIxSmV6(YC2Qae1ZOvbi5mcIg8RrMgeTWurLu4k6wBjRXg6CFimQHmfUNJQ2BZHXy8CsgcNVzgtYjZPExBrelTcGV4enWVp8pgEV4qy3UX3Sa(w(2UW3k(9J)a3iUx349rbW4(CJ3Vl8TbRGUXhWn(oCJVZKhgFxFky2)dIVBagIVh89I)qUXEW3h(G47h)a5WhYn(W4hepGB8G4hc)WF5Ba)ieeq7RImDFDf7)MWbEACq8qWkg2fomSQGh2f(O4pm(XXdHp26L4lgpwGrzNAMO4NWf(jDJJGJIJ5gpIBC8j69ChnpaW1MRgY6VlHWXrRZv8mv1n4loj3s908hIY9GVfePFvVTI86CgeSjpHyHi3lxuyDDYAp)sqb85CwNrvascR6WQlXjBGwHxUye5Ys8V4bGbW5v1ukRXRRNHcZEO7(g6HmMG5E6eCVUxrtXGkhGy5Kuf4CHJD0dZwqGVW8JIVRBCLf40e5YlXVIOCmLk55myxGtQkp6GkQh8yhtRGaNCzE9(pmEwkUyf4(bItg1WtDy80qp4cpZMqgfaHFbkibp7b97fADFpo(uKMnoPDdNEpEpIpgRux4N(cLAmUOuAn6RvRWTu9(Pps3CWh)yw9dc)04PWpz)N7aQ9zaZuZPlWvuzXtAJExLMhjrT3d1Yd0HoKAVoAqtk0ZBLBDb4OrMkBk19tZeiFviemfMrSOHq0iWpVaTaGDJVinZxytl5ZzTEa(2U2GwbYkUyPA4HwJoXtxuJMmvY44(1aPusDwJwXc11H5Y6rVeOdtT3r1ex2ZjQYvKWm4jBwvVngxZzPlzUwgCZvKVaqfknNQgCbHDb1Y0J9thAtAElcudZOXPUYm2xSzJBnLoo1uzNirY42ZxTW)OoyxEqOlMuYw2sskkAwthlapta6kxZBer729yp3vFXt9qDPZTYmFYQvYZRLxGxSSGXBCzl7NVaaINRgbngWNtgi1Ebr5i2sTuHyb19LVHyQTaQAOeeTaL4kWF6iflMsw)0ZWZnFeIs0tpjFrrUtBxt9tZcwtmhJx1LoIrzokjZAuf0ujyeEKPxfUJZvqItxpxEdqtUSXbyRufSUWnln3dNxxKuxT0rMiYijsIFPdG)y5IcALlCa8l5oQomDsUaFNpRn559qimzPQJZBXBBtKUc5wruTNJsN2Gl1z7WVS6TnfufpXe4i2uWRjc45c615I)eT1268W5RiQPPOj0(mOOSa(wVqDskdRPLvuanHGcdD3Rcyd5IeL6SrNiEYrOwIWwNX686vuumesB36CRrzahvut3qyD7(OGKOQaH1(c2Dobwt6q1Bl2erMmD2urNisSNkYiJKiBIPbODZLtBW3fAMtdUbc0iyWvkOurLCNfi6igf)mJtjWcssdfMKYe0fO0GDrcHWBOUVMSA2aa8kGIe(zMoDrPb8NV4aAIYeJa4fwLouipN5tKmtIrIVUIMiSIrh4RgBIuXEQzsKjUfsDjBKQB3A0MXxu4Chfpoc)ueDo4j6bpzD9l4Kc4u5WPfWNaHzPQiWz2QwbCweEkQQakX7nINbFsGI1I03IV1YmGN2bp)g2YKQklYRb08mTsZdpJHd2CcYhm1804NPrRxby2TBzF(6mXoEoeo3foKZBZHoeoVL5cfWfX84s4YVaw4BVhSimCodEEa3kHRmU16fDDjOlxyzSc(Si1b2owfAx7GXcVewdRJnWvXla9BTCQpWfVPw5H)O4LVd8hbP(yx8AVvoA8Z)Qx(wU8tSvIl8pPa(faWg1kMFkcVc(fZH)PPed)mhgFo8hZI3a)XPz9Z2KX4R0uYNnnD5bK0xL(CtMzqTi0VjHbPrz56i)b(NVBCf4Fbb8ViqlGxf)jDJFf8)m8NcH)05WFgb8Vevug)zX)ZX)lq4x9nfWFoQS3XjYEaG0hDOtxOhMk6H)8Vk(1OszJuES0lPE2LNj8G41eWFb8xe)LWVo(xUHSd(xr4C(xVciYjLqFkkniyLkdNQOarkYs(rJwoXyU910w4oAJA9H7px3gUBOABu8PuuQKdei3W6EusuIprr89UM1pv5aI67165BoDanvdbsPo(n8mb2G(8pZoBXTPP8ROZF2Q8Yf4D5q(hmkps0KGFs4BLLElWFG7R59QQ(jGjSM)wBzKgxXfaL28cx(4wy16jUd7j4Lry)3mfUswEhZo3AogVAl9x1l(Z)mu8WXwp8zNX30XgFu)fQqyYu7LwVre1jEPMaCZwGYN54z2yzNDwT2DVzCNU3KvqJNZq9aTNJNrbvWcn9VVrqdS0R60bi7c2T6a0E6GdqXZinBed)kNiuHT6a0i9E5QcApDufeX2FdRLHcgGYLquJ))XT1rmoDzBikfqRQvy5kdACXZ6YPURo6ZHJgTU1DI6PZ27NbvD0ghQXtvdDrQpYw47BuPor27u1vT6AUuVVlsN0q)st1BHySy9OxhOUooN6T6Gv0n7Xwu2r1AbQ5Wp)BCTvn0lbmvRtuAa2WsIWvoQnOeBwfSiW0SlaU(W43FUOGStXCBhR2cSQGPZ1YXOUa0tWq0Owfo5Cmg8Y5wZyrqFBTsIlWdgstVoh(i5SePE9681RznHqy)bRTjsSGe15jptnlihrK7EW)LGPW9AtdKr0Ok1YmQy4vS2S)yBljzcsWPHjj(TuM9g2kZwE6YgzdOCsFgJT9kZ8qfMi9oDq(DQpi3S54bw5ZH)VdJfG34)ro8FYbd7fgDGhInWfeV55mu0iIA0bn()zNgKUb3rSCy1snCDDXHdseLHPaq2)w1SnbNiG)kmGj3eYIoJVkH7ppX0AybG8BO43CnA8jsxvsNFL6bVRpF0MSfWN6(kkQxqJ3GFUgX3OfG43TokeiFGjwBwU)deUQPCTwZ4RiqOHo26teEIzgk2jhiQAPgeGp)BK3YfEb8iVo(7yJqX)NQR61cxcAI)ZAfWsHt0OMoVSYIY5W)5cR18N79JhZclJnZH)lYH)pNd)Fjh()Ao8)nkC9Z)gxLOvFOgKD4t3UT6Vz0wydXpBx4aXCD0iCxTAe(BooLtsf1gTeErGXbegx(EiKophqQ9UcJF7KDC)LxLnB9)i(zEtXwSsvusBMmdMrn4jRErSsf)RtTnf)B4WYu8V5LMnPx8XYxHyik(3cQ1Vn8VFhIPM4F3ltdmX)7C5a)rSSe)7bttFvWKs8VpXqs8xdH)dUsnCe)1BXKXVfEde(FVttel6BYfZ4nFsM5pfvK4p02Kq83eH)JqNZlieYPnpn2D3(AIfuKTcz6DFdKO5IVLVSBYS8M0k1iceQ7RLFt8xhxmkPXcBzwFDhBDezg3oGlcCYfPRcrjxHzABLG(K4iyG22KTsEo7n7PPRTwPdb2Y89e2G(CzfbdqC9jFOdG7FDsWtG2nh8VfW9VQEv79CAtR)yhqpgO465Oyfce7n5W(XGgBu7CQh)o7TByo(IL5XrR)lIICx4NF)4rwGGy()0k1ylqN3EVP(0wiNZtF0JwpWp4)xe5xWuzR1NynNjaWerEtZEyb4lNJ6tIwLo1PlwKNLnXXhl7LpaZHW060BXy0imEm83LnMepNmaKSU11Ja4anJaymoDdyDpkN2PNkXJ28xpAgkYH2mHgW2Bm6YGxGikNW3yV2i3LNV8Gd4pE2irRbKc2pbIflYlZMm(0XzXFP1glfBItLkz2itGJ1FdM7ZZVKQOLMscSdpldWI4KihuxtusZ0WW5)oI44RsdXfKvOT4uKZDcf8XXte6MVP2FZShVkabQa2x5ze6(4PENo2MifPAEYiiYlv0ZuQo9NAcY8PUNJRbtz2(gDt19nIy6W7I9n6cnhfrHXREh8ukCWrQmpZWL9TiZw9ucDU7h)9jSmpYESPY3SGIIurWyaGXqLp3g1)jzp7eW)GCTmwFTdZY41xWaSm(8ggs9YeoennmnDys6WEPP(OPm0u)SmH8fmiTvKC8nej1V3G00HOPHOPHP1K0B(drkDyFwPHPPK(FygVK6eYlRFFHH(hs96J2N0(jOvAisDO54Bi6DjaT)dq75adtl1lT0a0(jyEOSqE9A9Na7Of0ap9fMNNxncj83gSeGVaLR)7jGFYJ(D2SSKYIJQzfUJAwwyhLKNWgat8XLS38hHvj5LHUV5RrUCc6ohF7RtUU(gMqRttYiAz13UcRTYHKd9oMvqSW8Y866UwH(tWhRnZx1WqroLvmQP91eIqv2h9(f16KaCU9tTU6GhsTtMxHAleNukX2D6BJejtgNDUOPYMn1K2wyvlhyCn(FWe1dYe5I2XMO9KZeDJ4OMO3hWxFIDMg(Bf)disKa8(eJ7l4cSvyo7zW71eDp4)A6tJjQpQRlRuh)MRonNj6UuVT65s4mhruNSjJGIqcX3jSfmjsB9Bz9VTGzB5CGTKdWlaMn5KxGif6Gs0eDhG1SbDscMd)0Kni)i(oczYNW6mLR6YKs1nVYe9HGPipnf)EDBXV(iq2Wwa6a0uRRhIcOPIwHTeaOLse5crG4m(8f2pTuQaGxV0uF0ulrrlr0HP1XsKyiny(kLSeyTSTbCTjnOnwe2jhDQjAvMWeDCNIbMOXSW(MOecMOXH)9uWI1e3UjAsasK0EXlfGJnrPnrNa(bRjkJjk7(mrtD1axAIM(AgAmkhFGzlyuqqnCNqJMOt6ahcJWzVwb6C3ku6r3oKKnr(4uMuk3ktiAkL5n0W7qMVwwLh)Q3QS(L9QmuJLVpRf5RwyM7yhJz2bwCEIVA7yNNkw5illF2zkkhT7yNp47EWo9tOh8h4YbPSBKpyN4nXpQ912KfQgEQJp7aPvgS7RT391W12UPmYeDk7vFVrldm(hCQ04E(vvV72m9EYezYKi5X9malVXGQ3Z2vAAnfOyhNRr2rRxOZ9NWPP5jtntlfXvbCz1JsjpZa(si48wnbxnpkYqnKlQ7bUtvunCE62YUOOUbT76RzMXI5jvsptg35Z0yrMCY4S0A6CZuIWE84z9KyYjNkzCQxbXLUj8T81PwvB5iaX)Pc836vQNaRdE2wTICgsNz5IDElBMy5KellJhst3GJC(cPHazeNr3qZ6SgYNBfyPYUd2VRvlRjADoGUzRiEefFRBuSMmxfXc0aAdUZevxrZaFKvivLyu4bzhHvsSIOXntcmWeKReYRbZfv1FXB58GVSWZGSXOCfmu0YZgzKetLzvoTcwwN(IhaCkzTsvLKIjQva8iVow25(yfrIxZqNelhB3tiEzboKCz7heiybGCl2QJTE2YNCML96p9mXkFUha)9rndo12A90Hnr3Nj6GMO73e9aMOdzIGCEqt0aMObnrpKj6HnrpIj6rnrhXe9yMiVMiFMigteiVgWebuwqFhYef2enSj6OMOpSj6XnrhZe9JBIEct0tAIIyIaMJyMOrmrXnrJUjSAvqGxpJGYIPK3uN(Njf1jNJMlhc0hQjbQnb54WyLLnT4s8sTqJ2YHFGqOceU5SiBjCQwSP7a6VxYM(ZI4JscUg9ycrpGE5ANk0oIYuQqYXNLULOaCs9WnJsb536NMgg65eaQG50bseLs5LuukArFY4FuEXZkSa701i0NVYwPpfAsFUuB0NKb1BI9ProETPQAqJN)66sIf5ZRaocvb)wmqFqHvDGy9C9Uk9umt9CsNS)PLfmO(NH7pFHQ6qhKNwHAKhLayaH8QwzSKvgVvF(WtHOhLkA256RwXBQVLqRs3sbs3Us9ULCZ3eUwwxIC68GIu3x9YYwpB4jZAtuQNroAFt7TCDtL(7ELmmrFkt0N(QOmGj6Z4qa4T7z5RUGEt0VuUlMnDMOpR693ogNlVOKOrT5meQkdEzNxrYWcGpiB5rJZFMS8(92DaETodWbGhfBBI(C43Ye953EeTj61mr)ljtwRzI(cnXTMOVOtmRj6lvhSAIEDt0VmPRmr)kMO)vqNzI(vHzP)1xLGC9ZYemuyVVxefCOUY0vQQwnlCGVuYN44(JeEyTDaoy53RGdE2M4GXnrQMOZAI0mr6Dhnan8C7JfOclmFuY5IwDFeUWY8Y8AIfSuYMBZw(56w6Cz55kwJECYORgj5QWtw46NL(t7tB6DfZomrEQFmp9ma9fgzq1(OhCGYYkA8Kd7jyffFUnbvmszQ3DR7WQ2nBSTRKsOBIp553A7Vw1MnVW85u3p5AEYlMIZQFfI6Bnq7VZla8yxebG8s8uJFukPc(kWtFrHSefgzHWzhrRwLtSuGUlk8rEVIOGmGO)Mn23UtFqgVn2Yu622rXmFICw48woh65upqRNl96NEI(ECNclMO)TMO1nr)6W983We9BsKbmrFL9(S)PKb)VLfY3e9BBI(DGA87EH2CaZe971g81e9vHk(7NZ6gqpYMu4UGIUbvBxohN9ssCdxTrjAwxXV9Bf8Lhj)39kaJ)6DkwFuy)5LvmCC2jaV8TybAnBBPdQCXBtMvVKSiOGeNQf8Fg)l5lpFWGbMESUd)FU3lPjOf4FWgNIvNWFt0xh(3g7iK9R8GDeyVHZWhCrr1xzCV0vl6(z66kH6TuJOqVvg32IeD3S5a8atrMSF)6wiTYlNFGtnqOsZwls3rAF03lH0CESu(H2aSFKfv0FtJddrZ45CMT6IZ1mlv7OoBHRD6SRFaiQdGE4TJOs1kGoB1h9b8Rh6m(MD4jZZ2Dy0Z)oxionr352gJZhWkc3BRZjlqbi2RV1jhEz1EJPPSyrpXA8MDtw03rr5(AGRjxLJaEt2M)CHl(2EDy8FrowYlzoxU6OMTjOoYKd0i5LZqQwffnvblat2S(MOY4CjdpWODhW8tSRG35Z28uCB)A)tFFUNnAMStLSLdbUR2EzKUqZnbU1x6ut0FgE2njTFUjJhBSijteZzh92U(Iea93P16hD04ry3YHopK1H51vhAWMKgSn3GFTouFTyPso6uzIVL7ra7dcoj60D6gfLnvQSBPv1vq2P7uMetepzS4BD2lm9UW0XHt6iXsm6SDOPVTR)GouF1EZeBSuPMyUeKxtE2PsNTtT5s08f1(04jVh)K3Ysh2I)YrjNdlITWR2OCgFhjiqZqTBUrM52IzXw9EdJz2mc1Djptrp)ceRva7Au3xtl2hN8((wGVtw3qSb6RKn4voR139FAzTUlhSw1v11G4QtBohmMRtEzIEJUXC5iinvOrO1kC0dQD8Hor(XNDPt2DMRFYDfmx934LTCdRpQgYSKxU(2EVlbLN4V3oq35Z20OPplZqbyI6ZlJxsct0GbhEyw4QqHzdemG)WS(9XWeG1FGaH8X6B4qbz2MJxsDjaQhMMOVr7UvAI(dnrFZDSRK7oukFxxokLDIRF0lcUUO4cIY80VAiKxi7grEP0zhKRKu051gTA3H3VWUkhcGwSOj6a4EERMha0yJ48KJ2CZNP5d24PZxW6ySQEVTu0w4zv)GTuEeysTm5uxBTZ193sHJqN7TdpyB3tNEM2ClPTUNwXuuPW8T1g7(BuUfadS80PIsijvTIOS1i5E26tkV2dQx)55UBDoqRQoxryOMXqtCE(26(O2rWJmrmQgpFrLkQ3)2wJ0nIYN6dCXNn9mq6fspO1oVdKmpYECSZ7MOvUPR0TD3e9tv)aTBI(PjjV0w3GDt0pd4015i7QUj6J1C70nrFC8h4gnr)S4JyIE5dYoIj6N7MnrFcOY)8V4TyI(fmr)IMOvPBmUj6t2CdXDCafQhC5RD7j(uLcWnsPt4BGiz6kDDBXpznsyYJiTixn96rim1J1XaPSAdrNUfBWlTxe7RSq)Dj7QCeRt2Jj6pUrCw(JihKNlwKwiB8T9NBRCwuNlC2SrotsJaIr0bQZE65IEoF((a1PaL6mYvDNGB(MRUMICDKwBVjQuT5nneUN9UvT9GRYD(RWWd16xHbyCSdDRUdynZE2tDmw5)KohSoN0Wx3bZm759zdVMVwzrdPHYmz6t2D41)33rGxuyZ7kHvN3AN(Aa(TGyzd2reMj6V(DkC1L5jD8AlYkEA1XRYp20Z4FWUJS()Dnez1)o4R(YLlnZnxNM55E5occoFRMSD9nGqxS0e5vg0O2sDhq8d2LdiEGb6iEyZwSsF3pCyh(Qm0eeS8ySpvSLMV0zspD3bb)WD5GGTzJcnrFRRdx5Rjxm20Zkp5jZeS7R8)OD76dawXoT0Vwt3TFVHUGlH3BHMqHHMnEiU4QlZKAOUdf(B2Tdfs(d7ShiodWY1fGbyIOdGHXKxmyTyfkujIA3bd)T76TtmFhbdQ7VdXu76cqbmH0bqXz9pqb(j8ot8PhV7GI)UDPGIgXO45(ADgu0B7Hr99cbQOB4HVwNWddFIXJouy9e(9ot3Xd)9xNhMchiRpESoFgmBla8xhGRC(Ad1exPK9mStl5F(ic57oU6))194Q6QXgjY2OfRdBDZUFTy7OtbamLSLDlTbmRW8N54Nz5A(4u91Dy2)WUCBC(REIodooqN31URtWhWSY2Jp0MEMWZymLa)P6EOX65g2LJpEVC8Y3rqH6Ef3zSaV3ruvto2uHgV7XjH8O8UbSa5qqeDKuZKK8r1Y53vynr555n8qkY5RcFCz(k1QxQZVcxJQOLNNtJ8PxwDFo2y7jIhjzg7xA(IT9sZBIw5wVQT19mztL(IU595UAU59B64)szwi91SDTF6mrh6PMyHmjNI5ChA7pRHpp5SqTIObFf6lV2N8njtzeXx8lREND4fxlbuZbToK72c4W07g0xJn7(ihU)OKRDCwRm7zW9(j)F3SNn75HAVlm75HHgA2ZJ0wZs8V5YQz6FMlPMHhKHtU2wyqY9oedYL(zYcyoiNlRbB)CzLi50Zno)I8sA1MZwul90PNZRplEg1GPlXMKnRE0Lj8mp4fLN5Gxd5z2HVwVKtb7lRz))px9ZgGHzygQm9BX4J8oTPEB0xuspKZcRNmvluGN8FjhKd23BSEJxwYefZ9UoDg7Ov8d48i4TJxQzSpx8lmGXjoXqlF8ucDFP((FhyP((7YBjX3KEyHIjPiZRNZXRZDiFRRYRr(Svt(wAUcxPsGnKKfz87)8KpxeIY8PTkpxhy8nrY7k(YbDx7SVCqjUuHo2hOifJGkH8vjcFPUdgEGgNfZe)thyWSNq2GGx7(iFN5y9XeMjanninDiwijKpAkt0GHcZeDigF(jjbJg2hddjbAG3WHdtsh2B0GbcdzeAyOj(9pCuFEhcAOVHdssgk6WHdYqs8ZYm0WHhM1NFgYT1pdddn1pnna5dAw4HJ6pG3Hb0zyVWLE9dDBaMqdtsdt(qs61xyZEg2SNJsqPM98HVIqMxKaO4k82DWIFNhxUZmdE)FKoHp5pZjz9fFGZgiZKDhFEOR94Z(Q0xX(kEU7TLpDSNchYebQwEfWaDYZO9zkL()9f7T(33v3n((UAzo2v633vIPM(VPlFJcT)SWFt2FL4jds6h31JTEjHyfhVI2utM)4KpeTGzVpHl7pORGezF6S(psWJ4TVf2Zh9Fm
```
