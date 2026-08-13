# Warlock — All Specs HUD (v5)

Import `all-specs.txt` whole (copy all → `/wa` → Import → paste). One pack for
Affliction, Demonology, and Destruction: every spec-specific piece loads through
a `spellknown` gate, so the HUD auto-adapts on respec with no user action. All
triggers match by exact spell ID — aura triggers carry every rank, cooldown
triggers use the numeric rank-1 ID — never by name, so the pack is safe on zhCN
and every other client. There is zero custom code, so the import dialog shows no
code-review panel. Four draggable groups sit under the character, plus a fifth
that exists only inside an arena or a battleground; drag whole groups in `/wa`
to taste. Note: the `/wa` editor preview force-shows everything with fake data
(all load gates ignored, so the PvP column and both curse states and all three
specs' icons appear at once, placeholder durations, no animations) — judge the
HUD in combat, not in the preview.

Upgrading from any earlier version: paste the new string and the import dialog
offers **Update** (the UIDs are unchanged), which upgrades the group in place
instead of duplicating it.

## v5 — CC in colour, no threat bar in the arena, enemy mana

Three things that had been left as "not verified, so not built" were verified at
the source and are now shipped. One new aura, one prompt taught to say more, and
one piece of raid furniture told to stay out of the arena. Nothing else moved:
every one of v4's 37 UIDs is unchanged, so this is an Update, not a re-import.

- **CC ON ME is now colour-coded by what is holding you.** The prompt used to be
  red for everything, which told you *that* you were controlled and left the
  *which break works* question to your memory — inside a 3-second stun, that is
  the wrong place to keep it. The glow now carries the category, because under CC
  a player parses colour and never text:

  | Colour | What has you | What you do |
  |---|---|---|
  | **Red** | stun | the trinket is the only answer — nothing else breaks a stun |
  | **Purple** | fear | trinket, or Death Coil, or Will of the Forsaken if you are undead |
  | **Blue** | root | a movement answer, **not** the trinket — never spend a 2-minute break on a snare you can walk out of, or Fear the melee off you instead |
  | **Green** | polymorph / confuse | ride it. Any damage breaks it, so your DoTs or a partner's cleave will pop it before the trinket would |
  | **Amber** | silence or school lockout | your Shadow school is gone, which means your **Fear** went with your damage — trinket *earlier* than you otherwise would, because waiting it out leaves you with no escape either |

  The countdown under the icon is unchanged and still answers "ride it or spend
  it". These are exactly the mage pack's colours, deliberately: if you play both,
  you learn the language once. Anything the client reports outside those five
  categories (charm, possess, disarm) stays the default red — "trinket food".

- **The threat bar and its red flash no longer load in an arena.** An arena has
  no threat table, so a threat bar there was a permanently meaningless strip
  sitting in the middle of your HUD. It now loads everywhere else exactly as
  before — open world, 5-mans, Karazhan, the 25s, and battlegrounds (Alterac
  Valley has real NPC bosses with a real threat table, so a BG threat bar still
  earns its place). **No PvE behaviour changed at all.** WeakAuras has no "not
  arena" load option, so the list is spelled out the long way; the value that
  mattered was the open world, where the client reports the instance size as the
  literal string `none` rather than nothing at all, so the bar keeps loading in
  Hellfire.

- **New: Enemy Mana** (arena only, one bar per opponent). v4 listed enemy healer
  mana under "deliberately not built" because the arena-unit power read was
  unverified. **It is now verified and built.** Each mana-using opponent gets a
  120×12 bar in the PvP column with their name on the left and their mana
  percentage on the right; the bar turns **gold below 30%**, which is the moment
  your drain plan has won and you should stop switching and finish it. Rogues and
  warriors do not appear at all — the row only exists while mana is that
  opponent's primary bar, so the column never fills with energy bars you cannot
  drain. This is the readout Drain Mana, Curse of Tongues and a felhunter parked
  on the healer were always missing: without it you drain on faith and swap on a
  guess. One honest caveat: how often the 2.5.x server pushes power updates for
  arena units is a client question no addon can settle, so treat the number as a
  live trend rather than a to-the-point kill calculation — WeakAuras re-reads
  each opponent whenever the arena frames change, so the worst case is a coarser
  refresh, never a wrong number.

## v4 — PvP layer

Nine new auras that load **only inside an arena or a battleground**. Every one of
them carries its own "Instance Size Type" load gate, so **nothing about the PvE
HUD changes**: in a raid, a dungeon, a group or the open world the pack is
byte-for-byte the v3 experience — same bars, same DoT row, same alerts, same
cooldown row, no new icons, no new triggers running. Nothing was removed,
renamed or moved either, so a v3 import offers Update and all 26 old UIDs are
stable.

Six of the nine also need arena specifically (they read `arena1`–`arena5`, unit
ids that do not exist in a battleground — a battleground-loaded arena element is
a permanently blank slot).

**This is not diminishing-returns tracking, and the pack never pretends it is.**
DR does not exist anywhere in WeakAuras — no prototype, no bundled library — and
the tempting fake (an 18-second "DR" timer on the target) models the *reset*
window rather than the category state, so it is wrong the moment two of your
spells share a category. What you get instead is the honest half: the CC that is
actually running right now, on which opponent, with its real remaining time. You
still count your own fears.

**New group: `Warlock - PvP`** (right of the character, growing down) — the
state column, mirroring the Alerts flow on the other side. It holds six of the
new auras and is empty whenever nothing needs doing.

- **Fear Out** (purple, one row per opponent, arena) — your own Fear, Howl of
  Terror, Seduction or Death Coil on that unit, with the seconds left. This is
  the layer's most-pressed element: your own DoTs break your own Fear, so for
  the first three it is a live *do not press that button, and do not re-apply
  Corruption on that unit* timer. Death Coil shares the row for the other half
  of the same decision — its Horror does **not** break on damage and it is a
  separate DR category, so Fear → Death Coil is the standard extension and the
  icon tells you which of the two you are in. All ranks; `ownOnly`, so your
  succubus' Seduction counts and another warlock's fear does not.
- **Spell Lock ON** (gold, one row per opponent, arena) — the felhunter's
  silence is running on that unit: this is the go. Read from the silence debuff
  itself (both Spell Lock ranks trigger the same aura, 24259), so the countdown
  is the game's own number rather than a guessed lockout length. It is the
  silence portion only — the school-lockout half of an interrupt is not an aura
  and cannot be read on TBC.
- **Fear Ward UP** (red, one row per opponent, arena) — that opponent is immune
  to your next fear. Open with Death Coil or Howl, or bait the ward first. Every
  priest has carried Fear Ward since 2.3, and this is the difference between a
  working go and a wasted one.
- **Enemy Trinket** (arena) — a 2-minute countdown that starts when an opponent
  uses their PvP trinket, one per opponent. While it runs, your fear chain
  actually sticks. Honest caveat: no API on 2.5.x reads another player's
  cooldowns, so this is an **inference from the cast you saw** — if someone
  trinkets while their unit is not tracked, nothing starts, and the row is
  silent rather than wrong.
- **Trinket DOWN** — your own medallion/insignia, shown *only while it is on
  cooldown* and desaturated, so an empty slot means "you still have your break".
  Six item IDs are watched (warlock Medallion of the Horde/Alliance, the
  race-wide Medallions, and the old warlock Insignias); the equipment-slot
  trigger was deliberately not used, because it reports whatever sits in the
  slot and would call your medallion down while a PvE on-use trinket ticks.
- **Will of the Forsaken DOWN** — same readout for the undead racial, and it
  loads only if you know it. On 2.4.3 WotF does not share a cooldown with the
  medallion, so an undead warlock has two breaks and this decides whether to
  spend the first one.

**Two new prompts in the Alerts flow** (44×44, they slide in like every other
prompt):

- **CC ON ME** (red, with a countdown; v5 colour-codes it by category — see the
  v5 section above) — you are stunned, feared, rooted,
  silenced or school-locked, and the icon *is* the identity of the effect: stun
  means the trinket is the only answer, fear means trinket / Death Coil / Will
  of the Forsaken, a root means do **not** burn the trinket, and a Shadow-school
  lockout means your Fear is gone too, not just your damage. The countdown is
  the "ride it or spend it" half. Not combat-gated: the opener lands on you out
  of combat. Caveat: this reads the client's loss-of-control API; if your client
  does not populate it the prompt simply never fires (it cannot show anything
  wrong).
- **TARGET IMMUNE** (red, with a countdown) — your kill target just became
  immune: Divine Shield, Divine Protection, Ice Block or Cloak of Shadows. Stop
  casting, stop re-applying DoTs into a 90% resist, swap or wait it out.
  Blessing of Protection is deliberately *not* in that list — it is physical-only
  and your shadow damage goes straight through it, so prompting on it would stop
  a burst that was working.

**Howl of Terror joins the cooldown row** in arena and battlegrounds only — a
40-second AoE fear is a PvP button, and it would be noise in a raid.

Deliberately **not** built, and why: an interrupt prompt (Spell Lock is a pet
cast, and "can the pet cast it right now" is not a verified readout), enemy
health frames and an enemy-cooldown wall (Gladius owns the first, nobody reads
twenty icons inside a stun), enemy healer mana (the arena-unit power read was
unverified at the time — it has since been verified, and **v5 ships it**), enemy
spec detection (impossible on TBC — every element here says
"each opponent" or "my target", never "the healer"), and diminishing returns
(see above). Soul Link uptime and the Unstable Affliction timer already exist in
the PvE HUD and are exactly right for arena, so they are not duplicated here.

## v3 — per-spec load audit

v3 asked one question of every element, for every spec that loads it: *does this
change which button that spec presses next?* — the test being "does this spec
**press** it", not "can this spec **cast** it". One element failed, for one spec.

- **Demonic Sacrifice MISSING no longer loads for Felguard Demonology.** In every
  Felguard build, Demonic Sacrifice is a 1-point prerequisite tax on the way down
  to Soul Link: the talent is known, and the button must never be pressed —
  burning the demon deletes Soul Link, Demonic Knowledge, Demonic Tactics and
  Master Demonologist in one keystroke. v2 knew this and used a live "Soul Link
  buff absent" trigger to suppress the prompt, but that discriminator inverts at
  exactly the wrong moment: **when the Felguard dies, the Soul Link buff drops
  too**, so the prompt fired and told a Demonology warlock to sacrifice the pet
  their entire spec is built on, in the middle of the emergency. It is now an
  inverse load gate — `not_spellknown = 19028` (Soul Link) — so a Soul Link build
  never loads the aura at all, in any state. A 0/21/40 SM-Ruin lock reaches
  Demonic Sacrifice but not Soul Link, so nothing changes for them.
  The v2 trigger is deliberately left in place as the fallback for older clients
  (see the WeakAuras 5.4.0 note below).
- **Nothing else changed.** No aura was added, removed, renamed or reordered, and
  all 26 UIDs are byte-for-byte stable, so re-importing offers Update.

### Requires WeakAuras 5.4.0+ (degrades gracefully below it)

The `not_spellknown` load argument does not exist before WeakAuras 5.4.0. On an
older client the unknown field is simply ignored, the Demonic Sacrifice prompt
loads for every warlock with the talent again, and the v2 "Soul Link buff absent"
trigger goes back to being the discriminator — i.e. exactly v2's behaviour, with
no error and no missing aura.

### Audited and deliberately kept

The three ungated DoT timers were the main suspects going in — Corruption, your
curse and Immolate load for all three specs — and all three survived the audit
against the current guides:

- **Corruption is in every spec's priority list.** Affliction and Demonology
  maintain it all fight; Icy Veins' Destruction list (both the Fire and the
  Shadow variant) carries "Corruption on pull". A destro lock still needs to see
  whether it is up.
- **Immolate is in every spec's priority list too, conditionally.** It is core to
  both Destruction builds; Demonology casts it "if you are not wearing a lot of
  Shadow damage gear or if you have a Fire Mage"; Affliction casts it "if you
  have Improved Scorch from a Fire Mage" — a common TBC raid setup. Gating it off
  Affliction would leave an Affliction lock in a raid with a Fire Mage running a
  DoT with no timer, which is a worse failure than one extra icon, so it stays.
- **Death Coil stays in all three cooldown rows.** It is not a rotation button in
  any spec, but it is the warlock's emergency button — a 30% self-heal plus a 3s
  horror to peel something off you — and all three specs press it under pressure.
- **Curse, Life Tap, the health/mana bars and the threat bar and its flash stay
  ungated.** Every spec maintains a curse, every spec Life Taps (the health and
  mana bars are the two halves of that decision), and warlock threat is dangerous
  in all three specs.

Everything else was already gated on the ability or talent that produces it, and
the deep gates hold up: a 0/21/40 destro build has only 40 Destruction points, so
it never loads Shadowfury (a 41-point talent), and Fel Domination loads for both
Demonology (instant Felguard resummon) and destro-sac (the resummon half of the
re-sacrifice loop) because both genuinely press it.

## v2 — rotation fixes

An adversarial rotation review judged the pack against one standard: every
element must change which button you press next, and anything that does not gets
cut. What changed:

- **Demonic Sacrifice MISSING (new).** The 0/21/40 SM-Ruin Destruction loop
  begins "Fel Armor → Demonic Sacrifice your Succubus (Imp if fire)", and the
  buff dies with you and with any resummon. v1 tracked none of it, which also
  left the Fel Domination cooldown icon pointing at nothing: the resummon +
  re-sacrifice cycle is the only reason a Destruction lock presses it. The
  prompt watches all five sacrifice buffs (18789 Burning Wish / 18790 Fel
  Stamina / 18791 Touch of Shadow / 18792 Fel Energy / 35701 the Felguard
  variant) and fires when none is up in combat.
- **Fel Armor MISSING (new).** Priority line 1 of every spec's guide, lost on
  death, tracked nowhere in v1. Both ranks (28176/28189), combat-gated. It asks
  for Fel Armor specifically, as every PvE guide does — if you deliberately run
  Demon Armor instead, disable this one aura in `/wa`.
- **Soulshatter moved from 70% threat to 90%.** `threatpct` is scaled so 100 =
  pulling aggro, and a competent TBC caster rides well above 70 for most of a
  fight — so the old prompt was lit, glowing and sliding for a large fraction of
  every encounter. A 5-minute, one-shard, 8%-of-base-health button belongs at
  the "about to pull" tier, not the "doing your job" tier.
- **Threat bar is party/raid-only and fades out of combat.** Solo you are always
  the tank on your own target, so v1's bar sat permanently full and red while
  levelling. Its own flash overlay already had the `ingroup` gate; the bar now
  matches it, and it dims to 50% out of combat like the health and mana bars.
- **Health bar flips amber at 60%.** Life Tap needs two inputs — mana under 30%
  *and* health over 60% — and v1 only drew the mana half of that line.
- **Refresh glow is 1.5s, not 2s, and the dead glow layers are gone.** Immolate
  is a 1.5s cast with Bane 5/5 — which every Destruction build, i.e. every build
  that actually maintains it, takes — and Unstable Affliction is 1.5s base, so a
  2s cue trained a half-second clip in an expansion with no pandemic window. Corruption, your curse and Siphon Life are
  instant recasts whose only correct cue is the icon vanishing — in v1 they each
  carried a glow layer no condition could ever switch on, so that dead config
  was removed rather than wired up.
- **Curse slot also feeds on Curse of Recklessness and Curse of Tongues** (all
  ranks). v1 covered only Agony/Doom/Elements/Shadow, so a dungeon or PvP
  assignment produced no timer at all.
- **`spellknown` gates added to Death Coil, Shadow Trance and Backlash.** Death
  Coil is trained at 42 and its icon used to render, permanently ready, for
  warlocks who could not cast it; the two proc prompts loaded for every warlock
  and simply never fired.

Deliberately **not** built in v2, because they are design decisions rather than
defects — say the word if you want any of them: an AoE suite (Seed of Corruption
timer plus Rain of Fire / Hellfire awareness), a pet health bar for the Health
Funnel / Drain Life call, a soul shard counter, item-cooldown icons for Flame
Cap and Soulstone (the 30-minute Soulstone cooldown lives on the *item*, not on
a player spell, so a spell-cooldown trigger would track nothing), and a
Conflagrate interlock that visually separates it from the use-on-cooldown icons
it shares a row with.

## Groups

**Resources** (center, above the DoT row) — three 172×14 bars stacked flush:
health (green, y=-13), mana (blue, y=-27), and threat vs target (y=-41), each
with a percent readout on the right edge and each dimming to 50% opacity out of
combat. The mana bar tints violet below 30% and the health bar turns amber at or
below 60% — together they are the visual pair of the Life Tap prompt, so the
"tap now" decision is readable without looking away from the crosshair. The
threat bar loads only in a party or raid **and never inside an arena** (there is
no threat table there, so it would be a meaningless strip in the middle of the
HUD), appears once you are on a hostile threat table, turns orange at 70% and red
the moment you pull aggro, and a pulsing red overlay flashes across it at 80%+.
Warlock threat is dangerous in all three specs, which is why the bar sits with the
every-GCD information instead of off to one side.

**DoTs** (center row, five 40×40 icon timers) — your own debuffs on the current
target only, with the time left under each icon: Corruption (x=-88) and your
curse (x=-44) for every spec, Immolate (x=0) for the Demonology/Destruction fire
rotations, Unstable Affliction (x=44) and Siphon Life (x=88) for Affliction. The
curse slot is one icon fed by twenty-three rank IDs across six chains — Curse of
Agony, Doom, the Elements, Shadow, Recklessness and Tongues — because a target
can only carry one of your curses, so whichever one you are assigned lights the
same slot. An icon exists only while the DoT is actually up, so a gap in the row
is the "recast it" signal. Corruption, the curse and Siphon Life are instant, so
the gap is their *whole* signal and they carry no glow; Immolate and Unstable
Affliction glow at 1.5 seconds remaining, one cast time out, so the refresh
lands exactly as the old tick falls off. Never clip, never let one drop.

**Alerts** (left of the character, growing upward) — glowing 40×40 prompts that
slide in from the bottom and fly off when handled; appearance itself is the
signal. Seven prompts: Shadow Trance (purple, the Nightfall proc — cast the free
instant Shadow Bolt, with the 10s window counting down), Backlash (orange, the
Destruction proc — free instant Shadow Bolt/Incinerate, 8s window), Life Tap
(blue: mana below 30% **and** health above 60%, in combat only — the exact window
where tapping is free value), Soulshatter (orange: threat at 90%+ **and**
Soulshatter off cooldown, party/raid only), and three red "you lost a buff"
prompts, all combat-gated: Soul Link MISSING (Soul Link dropped, which almost
always means your pet died, so resummon and recast it), Fel Armor MISSING, and
Demonic Sacrifice MISSING. The two threshold prompts require the ability to
actually be ready, so they never nag uselessly. Inside an arena or battleground
the same flow gains two slightly larger 44×44 prompts, CC ON ME and TARGET
IMMUNE (see the v4 section); in PvE it is the same seven prompts as v3.

The Demonic Sacrifice prompt is the one aura in the pack with two load gates: it
needs Demonic Sacrifice known (18788) **and** Soul Link *not* known (19028). Every
Felguard build spends a point on Demonic Sacrifice purely to reach Soul Link
further down the tree and then never presses it, so "knows Soul Link" is an exact
"keeps its demon" test — a Demonology warlock never loads this prompt. A 0/21/40
Destruction lock has the points for Demonic Sacrifice but not for Soul Link, so
they always see it. The aura still carries its v2 second trigger, "Soul Link buff
absent", which is now only the fallback on clients older than WeakAuras 5.4.0.

**Cooldowns** (center, below the DoT row) — a horizontal row of 32×32 icons with
cooldown text and mouseover tooltips; icons desaturate while the spell is down
and the row auto-collapses the gaps left by icons your spec does not load. Amplify
Curse (Affliction), Fel Domination (Demonology), and Conflagrate, Shadowburn and
Shadowfury (Destruction) appear only when the talent is known; Death Coil is
baseline for all three specs but is gated on its own rank-1 ID so it stays hidden
until it is trained at level 42. There is deliberately no timer text on these
icons — the swipe (plus OmniCC, if you run it) already provides the number.
Conflagrate is a plain availability readout on purpose: it never glows, because
TBC guides are explicit that you should *not* fire it on cooldown or at the end
of your Immolates — it is there for the "I have to move and cannot Life Tap"
case. Howl of Terror joins this row inside an arena or battleground only.

**PvP** (right of the character, growing down, arena/battleground only) — the
v4 state column described above: Trinket DOWN and Will of the Forsaken DOWN
(your own breaks, shown only while unavailable), and three per-opponent clone
rows — Fear Out, Spell Lock ON and Fear Ward UP — plus the Enemy Trinket
countdown, and below them the v5 **Enemy Mana** bars, one per mana-using
opponent, gold below 30%. It is a dynamic group because those rows spawn one copy
per arena opponent. Everything in it except the mana bars collapses to nothing the
moment nothing is running; the mana bars are a standing readout for as long as
there is a caster across from you, which is exactly as long as the drain decision
is live.

## Spec gating

| Element | Loads when known |
|---|---|
| Unstable Affliction timer | 30108 (Affliction 41-point signature) |
| Siphon Life timer | 18265 (Affliction talent) |
| Shadow Trance alert | 18094 (Nightfall, Affliction talent) |
| Backlash alert | 34935 (Backlash, Destruction talent) |
| Soul Link MISSING alert | 19028 (Demonology talent) |
| Demonic Sacrifice MISSING alert | 18788 (Demonology talent) **and NOT** 19028 (Soul Link) |
| Fel Armor MISSING alert | 28176 (trained at 62) |
| Amplify Curse cooldown | 18288 (Affliction talent) |
| Fel Domination cooldown | 18708 (Demonology talent) |
| Conflagrate cooldown | 17962 (Destruction talent) |
| Shadowburn cooldown | 17877 (Destruction talent) |
| Shadowfury cooldown | 30283 (Destruction 41-point) |
| Death Coil cooldown | 6789 (trained at 42) |
| Soulshatter alert | 29858 (trained TBC spell; party/raid only) |
| Howl of Terror cooldown | 5484 (trained at 40) **and** arena/battleground |
| Will of the Forsaken DOWN | 7744 (undead racial) **and** arena/battleground |

Everything else is baseline warlock and always loads (class-gated to WARLOCK).
The threat bar, its flash overlay and the Soulshatter prompt additionally require
a party or raid — solo, pulling aggro is the plan — and since v5 the bar and its
flash also refuse to load in an arena. Life Tap and all three "MISSING" prompts
are combat-gated, so nothing nags you between pulls.

The PvP auras are gated on instance type instead of (or as well as) a talent, and
each one carries its own gate — a group's load is not a child gate:

| Element | Loads in |
|---|---|
| CC ON ME, TARGET IMMUNE, Trinket DOWN, Howl of Terror | arena **or** battleground |
| Will of the Forsaken DOWN | arena or battleground, if you know 7744 |
| Fear Out, Spell Lock ON, Fear Ward UP, Enemy Trinket, Enemy Mana | arena only |
| Threat bar, Threat Flash | everywhere **except** arena (and still party/raid only) |

The arena-only five read `arena1`–`arena5`; those unit ids do not exist in a
battleground, so loading them there would only ever produce blank slots. The
threat pair is the mirror image — WeakAuras has no "not arena" load key, so their
gate lists every other instance type explicitly, including the open world (which
the client reports as the literal size `none`).

## Regenerating

```bash
cd tools/tbc-weakaura-creator/scripts && ./setup.sh   # once per machine
lua5.1 tbc/warlock/generate.lua                       # rewrites all-specs.txt
```

The build is fully deterministic (fixed seed `20260813`): re-running produces a
byte-identical string. When editing, never remove or reorder existing `W.uid()`
call sites — append new auras after all existing ones — so re-imports show
"Update" instead of duplicating. (That is exactly how v2's two new prompts were
added: they are built at the bottom of the script and re-parented into the
Alerts group, so all 24 v1 auras kept their UIDs — and how v4's nine PvP auras
and their group were added below those, leaving all 26 v3 UIDs stable, and how
v5's single Enemy Mana bar was added below all of them, leaving all 37 v4 UIDs
stable.) The script checks UID
continuity against the previous `all-specs.txt` automatically before overwriting
it (expect `changed=0`). One more re-import caveat: the Update dialog's
**Arrangement** checkbox is checked by default and will reset any positions you
dragged in game back to the string's defaults — uncheck it, or report your
coordinates so they can be baked into the script.

## Import string (v5)

```
!WA:2!DZ3A0TXX5zNvWorc(MeTKSTuSdSsK(mvSvawCLkwobaeqeuGaqlajfL1x4UyXaGLCXUR2DbPGAttctIdZL20q36CQJtIfDQttAoPFH)ijnXPPH5YpYXN23dBt6E61ZrN281KFLQE6)7mZU4gjeGUAB6FWHlMB7mZ7Z7T5D2HzQHeFXdV87yJIcIZxsxvlUQSQ(4UC5kNlVhlO2qIQkM6QYYOsXRkjxshPmU2UNwqxwvCEppHNXqcYMvVC7mMqqrOZkuOQosWuB)BohpjLfmQE5IQ6Lq6XCE5A7oMS0fVOGEjpfuvLnL00Vq2YLnqMmf1eWVBtThOzhviwCCNfvw2tEnKOrr7EQQEd7gC(v1rvKuvk0qdXvrxTU2Q21iV0fr35AskLv1RjyIRH71SlWEMZWW4AdH6Mvv1ZQrk2WDr8AqzPkU1fePzeIZWuq30DXYsksgvDhd)pt3lzQlvPcs3iZr0DE85IzsE7c11fyxNKAOHKLLkzCGH8gRoUrf1KfAG0xIMFQsgUVSr9IOfWZZ81lxw6cRnB8O5lmB(cr5k0QOC6iCrC5ZLiD6Ru3aL4c4XvE7EGNtrOgYW9QLqfX9azYRpwI05soz6vQR4mSCVwjjJ5QRGNnlGyfKL12Ja95c2LpHAj034T4SCLOufK2EYF(64LFpjRJxUNUQKjAD7sTxR31kcks2lMHG9NCDKGbkVjMCvXS6Bdoymfvf0gLWZFsnMLSMOBGWlQLmwIuvYOeyJvtqsjj4d3aGf8dbGG4))aBoNvmqYLZPkPywmEImfsWDiPsA3FB0fhYqTUUiY4k4QG0veKNc)2WV3NETY641g84sWuW1veueXK4KKSiV)I5JZLirMvnvfxWU(7m3(yRlvATtg68Mf1tYn1KNIZquqg5AvmLGJcUmAIDsPGxgCTkzojzdAIjRkuY9A2Vg64fISS3vnWW45NwQKz19TQeU65Pd23(BbCdJa3Z)8Bbscr2Gwjovt66fJ2E663eQtSOtwiBms7Rcp0h4iWbEo8s0JapkCiokePOnBjoR3b4X9syqYSe4gp8oH3fCe3W)h4XGHD3z7Gj027K4Q4jEvbcohPlzykjA40fq2n1w4OW7gECmkHmiMvSPqdxWXFAimezPIco8t5UdVhZxqsA4iKu2GUWGtdbtcCavDD6CZggndde747ho4AewfChml(VL3V2qMOlyoRrvHsQlEghPbRqZJKOT7dJHtI4jDv6C(WhwB3D0G2m1x2o3MOh4uA3pnhmVUkb7ksPkXII)5vOfGzYqLOz(r2WMmoJZBFDA5ZvhVcvUbezvDcPbvaNzSmzZKaoOogHqQZQ0k2E1XEyxglsvB3j1LUONtxxOebp6PqbnVTMtZAlBA2UMyZwcjIzYKNvth)Gbfz05stZb3g08wedlNwxqBPPDEyJwVAQqHStwiDQmjCwR6aLUwQmzsWnlxQtowbTHhWqclwvPeLHMRSSQQU9cZc4rxrzeF7xjrM7d5Si2KeQD4b052zwmt9Afr6lahCf8IQn32g2)ZzyZIHjnZr1Ha58tX2uFNCAo2C4BNfHfVbhR5VmWJtxfRIKQu18HHetTcHZreROYGVOjM1xXC)C1QJ1l5MJM7rkAiPurgPpDuU0zJFk4dVF4JYhdloxC)Wh2Dms)rE4YuuEmChuIW(YgD0r12nUVJwIaIqLqLMq4cvTfoeVnV097g2R7nxrjmp)9Q7WI0j7ZzyaVeXVBweAORbHQuUydPsiokHh2hUJCdpGB4bDh7IQQ1ywJ(IgJUYCcDcrRUoIlUmsqHtqwRQGl7Hsb7s0ESuePVLferNlUaMprPsmb9ZnzQNO9VEI8uXA0MvfEkS8wSOCWfSlg496IBrcJ3pXn8KWjG33AjhUqLKNA(KNz046skej0OQodjPsLqkCzsmvcU1u1LW0iQyYvhllxQZMntHOPHrp6r4eRIeNpjCaxlTGGUKagdSrxWnUfeKRJouiVhsv7qp5j0fRkOubzCGJaxIkdBKGudISfN5AjnS1kiDZga3rGVeUBVt4lVKKsC1AffmHlXq6KtCcyvsZPTdEj4zH94(keZSQqzBAjzIuE4L9cNCFWynve8kmefbqkgyC4uqAhP8F72sR5YPUisNiDEfnYteEqMUeuVbb72Qm(EkZhYni57WP7uSoWnUTmCsAGG2RlUG8vHcoYUHjxE)WumW0xPPyz6q4WhgMHYhcNfpFEA4CW)3pc8byGzX9jpiGBxrq0(nvcqqfgTh7QjDG2FDi5buHQGemhmpid1anET3v)BQDEGjC(hc0z0Ep9V2BvQlwueuhwaweUad0WEwDrE43bog876c(Ge5gWVhp8Him(Wh5iWsWh1wUa8XOz9XPPpd8jGLRcFYo40HpfMZg(0WN5gNrg(9H)GozEHpld8hEc4ZbRapRl4pc(JHNRnR2DyZQbF(wSzEN7cXNtw2xEUPG)KQWZdFb4fGViH)HcYDbF517CXbU0H8t4xg6jTr6uWr4GTHieWXl1blc8v6dVb8NE14gEHD0lUHw44vnPEuqmFblLwVcYeJJVmb(3UaEciFcTD748rEjZ6uXeuu)Twwd8eicjXFVzmw)W2JknrZwCfAp(waHTQupqG9Mjs7r7tN0c0VfoTo5E6Ho52DrxSCuEhmZ2GzgEgmZWAeIbwQpXnmEQ5OenJvT5r0Dka)8rG7JpMUGuj(RgJZcCyH(Mn4z1wa3t4XOzJAck8SMif(vnxeJmBug7jdwDn9zEGL)ncSA35wy1g5XoJ6OXhrwiUCxSAhVfR2kTw6X8zHP6LEkh2MXPENhIK4RdomCJ4eQGxmHl5QtUSXjvCeQQlw70Bq2spWdLbZM8ZAYMSrBMm8WKh(lG)Fe(KVfpS(HI4fZ8GTqTf(HOWuWuvNmlMawRdoVMCuxXXUcI9Qe7K02B80rNih2vN0rJFkSrtPkKAQeKXeMisKmSx3fRjPRRQxLkK4EXR(J6ELInTZct37n1TmCWIy2jSrt0FJl(NVk1kMC1Lnql10v1H8rBYwj9eYkHC2j5)ZPD8228eTuPSkgNBAKW8rj(9FUjqLKeoNJ1rgNZ2F6zPUsFmZkcCo(iqPO2jy6uKGeHlyKdw(cbf9wPyNNLixzj9MUhIXsfg)0gtoFj5j8VarqP2EW(3lQJmrZ2UwFWdx02nLQ2SKW3Hh(UoCGWFPdVh89U6mEW3NhEfE4hWd)v8WpKh(RP8wF(74Uw(DamT2WiyhNvBVT9gpUQUED62OCLoYSo28nTHANrQA1uLXdnThUDEtQyysSsZt0YLLLOB8I2(AxCEjTQQkEslvgbVnyNKfj3WDb3ngiC3myGW9b7(ojaLHSfjzZ03j5IcKjY7F7WdFGH82uypr2pbyEy(EiW)jWs1Ep76gxIHnzSJnlBu1cgesmgkrOSuyfw0q9esjR7B(sZibrDbXCdXDHX1qc3eQ7YVtQIXD9zUt4EOwjUHOQQm2bqL8lkHn0B9M)KSZnvH082t1x2EQ(Py9fMnwiwwAI)yHdficNpFHc7JMYYXg0VpFCSHz9fsh3jzvKXcrFemF9wxC0hlk3ejNmDNlrh)PVY8iKwuIlqMCeSxvQ2rSMWyhD57NQb8qhw760AW26Ow3290yzlui7eW5FyBTqLPAH6PgOtFTzo29cPjGeSjqfNqF4ZyeFebbmIYc(BShhFwQg9LAU2Y3sY(FN2EBMjH7EujdcQfRaJiT)0oyfca4G2cACWkBkNhyl5GHRy1cDIyjiemkadQFwxnbbV6oCabW)ip8pTfQ9l(aSJeXBmFE9fatU9fgtJd7ZhnLLM6NsPJWgYRFo)EhXhUUbgXlPiwA1yzjvGfdrchjeUjHhXFyAoJWg2Bam6jyesYi0oZUKqXWpgGMXiW)(vd7a)hDJAGF1TwCc8))2b4iJXKZSyWgQAlMARGd4x3gv83d)MxJqam9fa88S(debtQcJXaJeig7ibO85HcstdttJq459ocfje8gJID8F5gvKvxmPo681rkInSTe2EFWifSo2oHtk7SBC8lrYIUV85KUasEvYptt3S49Tg55M7K1kvA2eSIrBhoPg8qRuZTrkg5hvPvnpD3zPJKcvLeNxbzy4IwsAj8Z7H(IIzhMG3WcXkKuS4ckyBydnx)Hy)IBFqSd0YCYlJUGMKTXqfKQHGlX67ybT3HeBlf5HxISD4hZ3XilUDdnNPVqZJJf44ZBeCAaVbOP3WGplM7UjIZI5ESyUxElM7ZIz3wm7zFwmdXyXC)utGdB7wMllM9IZBFvTy2p(5ha)3dUhlMh61uqXcyqb1hvASFMxHQuXgK8X2cuz12vAN1FHndzIuBUcjsZLiTXz6pK5x(AbKXI5GWLSyE7BcLyX8WDJo(w9fDmhhrRewmvKiHhHKgXlnLAAsOauLv(2gOEHqMTyE0RoP1I5q78KZSzsQjssz0fJ7n4817pj9F42VIgVXWEuU4HMmhSJNVD4xXMGtd7GNc6ckIDzopjAUKG72zEed19uqqRlB4vXEBvvWe70K2b7oBC9vM3ZePYNpvMt2zHjrYEIQxtvVvHVZomNgvtvrs0tEbrDPYsIOwvQJrs84EYMXZej6CQuik3jtuWtQjMyYmjO(tGPc3ZpIcpT9GGSn1IO75M1fI1W(5vVMsEsNzVZrfTnLLtqwQIcerh71djgSmeZ(Xg832ZkD7ySI4Po6e1f2dWfD6hSxpextU31l1qrOMKiD7uWoafZqv3eyxPIUKDGSURLipsu9EiUr5KLQjzExKTJjn5PQxwuL40LIzsbrSF6f5IoAQjZxuxOKuDJp2DJD9zfbDrBn1yGSdeSZG9hvgPBASA56YYXL0fLr8nDT5VLH4eZUKVj8EcdtTXKejENEo9zsuls0gdWoOMKhIPRb8Dn5L3nG2LFlZco6u4F9wNYaf2K8BUzHnLLyp9zx48vQoUm42Ij5vvAJfZJ3T4gYW5Ndb1jrXpBDt6gPSMHSujurvtt1AWRYs6bcfShcIwE3RqdOobpUHHPUaj4suJ4GdwuSUbUdksRqdYabdcSyoLDgxWoJxDiFWZYqdshnB(HAuAxdDbMvO7LdPBxQz3sE5BGFwXGSrdKI02tZYk0mB8iZEhTAMbpTVP9g)nN94TWH(dmI)q3UWH22jhSzuQ22GjxEXnJj1otUjug9KnMj(PgeM8j6jMeJvOWrlM0WRAXmXvheAXKXIjlzrnNfZPBd1Sy46eMzXKVj(YIPGfZKKUYIzklMPXDMfZzWZKzgik5DbJX0tqcjIg)QM7RQ2(6kgun350HEs4BEi)EHjGxMGGOrgUROvXdF1Udci8N1rG)ATTTWlEOqKEjdfhIRfUjK6NLxBpD0L2bgLxB)Dhx(wJMNQ)i2JEnBxUFBuRRRkGT)qSYT8VAvA86PbHLVV(ArobuKZEvkSkpTJ2EFBj)24C0dt1S223mBS66kskvYJ9dsY0gCgpnRgsuozm9m9eCwTn48yVPbC2g98t6EJ(hHSr)WpDRBRpUrlVhoSWuX5JroLn2GRkifKUKy(QQlMvHFJU(5Ag0)XHek1GgBBQFpzeQH2P5QWb5O)054k9qXD22np50vROJ913ZJrjCdRnenCtvuu1rQlG0XM8G43aRKsoFZUBToS9CJwEHrkHgOqY43MbAfh9bIZZRD)KNrKtBxNv)Me)tLy73zNnUXW)pxx7FFp2Ob6U9tfctzdisCXlNTygSye0oCV5bIQlkOGC(NxF2WFJiXYuBSPMUWWPge8)98Mc4Fh(LEao2GSSr2aBjUyvKHnSDdBy7esgKJd0nGY9RdOIVbPCV)yLNPP6yBbIFiB8ap)wujpEHUbi9xi5jfWAh0T)HHnkzX0tD2ksyhWeRoiuI33SHsokhBeFHdrsJmIftDlMfEZbQqz3DJkosFrfyN1j(Qxx3rUrAX8snwCcFluzqicFVPrTPdI4SC(IeoczNSctIVco1hnLLZFWWE9nymshIGSym3gGPE5ERjIaZUSIQzh77jwwJTk7UZUL2kEk0lvPRhbs5mAiwfBwHiwTFnB43WkleaXotfv5Hhe8JD7e8R)oEUa1Snhqst7AMqB3X1vxSKN4T(6oiiNBfoF67nmoFoJJNbToLdxfhcoc8k8CKpUeSp(T8)mC85QF2PNxID(fhK)N(BcwM5nWGLNV1(ZVMZx0d9RU4sXYxyYmDDwH6MkcV0vAhEhAS46yJ()KWL2G0(zNir8XIMjv8(2rwmF6UBBSKjIYTLZPuZG00JgSbPb9(LnGwQhpBMKtMpXwAtGooBV9CmYLnBHT0k)0xxVFt5tLorM4j26sre6BHTNtSCrJNk5m3invB35Jpw2SPNnf5JHHBYCfgqZVE2UQ5ydfGnMpVSEzdmsKybdg2pxGGb8hHZVpw2axTGVCtVDQ74xT9q6XVDh)3TfzixkQi7yNV4ytpZGezey7GiJwX)XI5DdFryhxu7an3P)4Js2S)AAYsLB4CCUoyxLrctZOQ1KuOHow7b7QqSsNYYcviF)pTdcdTeBL3fRRR0ZckxxVXMkyue2ZdCpkjVPrWyQlk7rTSNciY5dSvmDE87OJG6yXeCx3Sr0XIjuZJaSftesYiBn2nwmhVQtyBSyEVTdyJfZtc7(oTyobWAX8u3LfZ77qCJAX8(XpfTQftmlM4wmJsd9IftIoI5Y935rSZEBqmSyo5Md3cZTKOTKsxo9ONwysddoITU9rSXYyEum8gzXugdTQSkXV4OYlk0G(DKzXiTZtQrqTZzVhowmZBXiJRzTn6cmzXOUPTHXIrdxTZFTTBl2H2)EDcVFh2N4YEhgDe8qeQCFBuSUPPQs2fq6YcnUgSSn61AmD1ABUkzBjD(Ew5DoLhH8RD6SrYnVHgrwXQ9rwXxa(nvPYkIEBmO9RQQ0ehTPZomp8sq(2o6CTt8Ty(knj6P2Bpj6xUBPeVgs1TyE5BHKA80Rdpt(QoK4qvwqmFGPMAyDHbrIFHxliXwmFTBdK2KhTNK216qg)2w6kEU1d6QS)eSbuKKdWwzq01V42x6AIFrpPRR2wd92wYkEQ1dY6uvMUrPOJVyUrhDqK1V02xY6cNQFKvI9vBBjR4PwpiRdFY58Rf0)jdj2yqK1V82xY6b(49MS2264TTKv8uRhK1gboF6IXgnqkLHhez9f3(sw3NCVTBQBFBEJiPTvafA5(CVPU4zyZTGZI5tW3nrUM54ncyegLnxMbrKV0R)ezIBYXgn70ziEk351DJUKY8itpKI68WkoTKmLiAwf5jPQUHW8if7k1XbtmHcQwJMDrNNIXKibDpzRB21bYKSb4Est(r2mDoeOvEAYTQZK568RZYU3j3yp98mpIDp(EUL5EmBHS56RdY83kDqEJ2tYClKRhEgx6wZbrm50fdRgA0ybNU4vpmqF336oiF8(ljzIQrpldl8jiRze(DycThShNJHu4AoS9bZblr4Y2HxULdA4161PNWbN(JhoymYZTJu032I5hTZf(mTFlwmR3Q7Sy(XKUWI5NWt4T)PBQzp7V(gRz)N3qnl1x5gRzF9RRMbhLvqPXMLdYdXoq)fJDnVdGKasn8MdivQmtn74OfrY6nM1Hfo3u5MT5XOifNWOZfBXGJAqdXWpSpI3(o3(eVDTffPTOJ6h3uh1J8(7PokSyMEiF76wv1GjrpJdjQRix)OBnY14Xz3Bx7ezM7cNXqjsUlkmOL)V7T)L)(EQcih9Qj0DUKWoaxaYNFhDb)vz9X6LC1nzl6NC3Q4jFDrre5MIbEeSk11AD4MsvIVV3MbDBGWnnJboD)TvPFDWDWAtEkfJnD(avgLl3CdI88x(6n3XVKUrNXLvvqg82Qh)6Xcgoc5BS1NFssWybdeja5qOZgjwi6bba)yqAAi6NnjUA(dgznnKo56QG81RVKq5YirtmHK8zUGxlVm5KnkPGYzxh(BhFNuVb5KSFni49o(FAZlZvXOA8APNC8AlmiWY3717Vmtmvyd(whMSaSbhXI5FXI5FTjv2I5F72cLT7qbUnKixy8Qdpnk78O8tmiI83)1BI8pRdImMXoqihAC)iW3SNAN(e10(qhsDDthcRB49ctNSyq5QdIo8knPdPU991P16McImuUNTCVz119vI9jNhtdiQbTpQ82kd12lrpj5ZxwshrVATkqV0SAD85VrUpSg3(A)XMJI7WKBMZByMQvTV3dsNizb487ZM7Y5cfc(AxV96xFl3zwWFo5(WI2VFJbDbx9qxRiMx)V3DSy(bnV4D(VCU3DMoBdV6Jh8XMZ7576E3PTB(W3Cl3RvB6uuaCDFV4muTHknuPLFKUVhuGrallMKwmRsqMoxsjKlOKxDNVX(ckb7g(wUtsmJukFOSd7DY8J1J7KKHm48FSGhZ7qlChFW)3d
```
