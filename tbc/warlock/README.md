# Warlock — All Specs HUD (v6)

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

## v6 — the cooldown row now shows what you *cannot* press

**An empty cooldown row means everything is available.** That is the whole
change, and it is the only thing you need to remember.

Until now the row worked the way the default action bar does: all seven icons on
screen at all times, greyed out while their spell was down. That is backwards.
You already know your own spellbook — what you cannot know is what is *missing*
right now and for how long, and the old row buried that answer in a strip that
was at its most crowded exactly when you had the fewest options.

So each icon now **exists only while its cooldown is running**, carrying its
sweep and its countdown, and **disappears the instant the spell is back**. The
row is a dynamic group, so the gap closes behind it:

- **Nothing in the row** → every cooldown you own is up. Nothing to check.
- **Two icons** → exactly two things are down, and both are counting themselves
  back for you.

The grey-while-down desaturation is gone with it. Under the new rule every icon
you can see is on cooldown by definition, so greying them all would just make
them harder to tell apart at a glance; they now show in full colour, which is
what makes a two-icon row readable in peripheral vision.

**No warlock cooldown got a "press it now" glow, and that is deliberate.** Other
packs in this repo keep a couple of icons permanently visible with a gold
ready-glow — a paladin's Judgement, a bear's Mangle — because those are pressed
the moment they come up, and a hidden icon cannot announce itself. The warlock
has none of those *in this row*. Your press-on-cooldown buttons are Shadow Bolt,
Incinerate and your DoTs, none of which has a cooldown at all, and all of which
are already rendered by the DoT row and the Alerts flow. Every spell in the row
is something you press when a *circumstance* calls for it:

| Icon | Why it is a "when you need it" button, not a "press on cooldown" one |
|---|---|
| **Conflagrate** | it **eats your Immolate**. TBC guides are explicit — do not fire it on cooldown or at the end of an Immolate; it is the answer to "I have to move and I do not need to Life Tap". A glow every 10 s would be an instruction to delete your own DoT. |
| **Shadowburn** | costs a Soul Shard *and* consumes your Improved Shadow Bolt charges, so on-cooldown use is a DPS loss. It is a movement filler, an execute, and a PvP burst button. |
| **Amplify Curse** | 3 minutes, and it only pays off on Curse of Agony or Doom — which in a raid you are usually not the one assigned to. |
| **Fel Domination** | 15 minutes. It is the pet emergency (and the resummon half of the re-sacrifice loop). |
| **Shadowfury** · **Howl of Terror** | crowd control, pressed at a moment you choose. |
| **Death Coil** | CC plus a self-heal — an emergency answer, not a rotation slot. |

Nothing else in the pack moved: same bars, same DoT timers, same alerts, same
PvP layer, same load gates (including the arena/battleground gate on Howl of
Terror). No aura was added, removed or renamed, so all 38 UIDs are unchanged and
a v5 import offers **Update**.

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

**Live acceptance note:** `CC ON ME` uses WeakAuras' source-verified Crowd Controlled
prototype, but addon source cannot prove that the 2.5.x client populates the underlying
loss-of-control API. Get sapped and school-locked in a duel once before relying on it; the
repo suite verifies its schema and gates, not live client events. The Enemy Mana row's source
shape is likewise verified, while its 2.5.x arena-unit refresh cadence still merits one match.

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
cooldown text and mouseover tooltips, showing **only the spells that are
currently down** (v6). An icon appears when you press the spell, counts itself
back in full colour, and vanishes the moment the spell is ready again; the row
collapses the gap, so **an empty row means everything is available** and two
icons mean exactly two things are not. It also collapses the gaps left by icons
your spec does not load. Amplify Curse (Affliction), Fel Domination
(Demonology), and Conflagrate, Shadowburn and Shadowfury (Destruction) appear
only when the talent is known; Death Coil is baseline for all three specs but is
gated on its own rank-1 ID so it stays hidden until it is trained at level 42.
There is deliberately no timer text on these icons — the swipe (plus OmniCC, if
you run it) already provides the number. Nothing here glows: not one of these
seven is a press-on-cooldown button (Conflagrate and Shadowburn least of all —
Conflagrate consumes your Immolate and Shadowburn burns a shard and your
Improved Shadow Bolt charges, so both are movement/burst answers rather than
rotation slots), and the v6 section above has the per-icon reasoning. Howl of
Terror joins this row inside an arena or battleground only.

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
stable. v6 added no aura at all — it changed one trigger field and dropped one
condition on seven existing cooldown icons — so every UID is untouched.) The
script checks UID
continuity against the previous `all-specs.txt` automatically before overwriting
it (expect `changed=0`). One more re-import caveat: the Update dialog's
**Arrangement** checkbox is checked by default and will reset any positions you
dragged in game back to the string's defaults — uncheck it, or report your
coordinates so they can be baked into the script.

## Import string (v6)

```
!WA:2!DZ123TXX59Sc2jsW3OOLKTLIDGPJunvSvawCLkwobaeqeuGaqlajfLvd3fadawYf7UA3fGcQnnjmjokxAtdDRZPoojw0PoTP5K2WhYv30e208qo(0(DyBs32K(IoTUn5Pu1)b6mZU4gjeGeLKTKFGdxm32zMVFF3MVzhMzgUWlDWl8U2iVqHflQPOgvrsrBshoCKXH7J4xD4ckYgAkssOIrRikvudjpP6qZkOjPuyrxpPRjqcsgvUu7mMsqwOZkKRIgsWqDFBohxXLe0RCP8kAfrArSF5Qdfrs88NxqRORCkksgIQANlDPs6idM8Qc43TH6d0SJYfjkUZclj5kRkQGEEREQIwdRgC2v1qLfvKZ1qfXvwtPM6Qw1iR45r35AIYLu0QkyGRHZ1SkWAMZWW4ydHAgvu0sRskw3zE8AqjXYo1ekqZiaNUHGMHZ8LeLf1R4mc(Fgox2qtSCzKMEQdPz)4ZhXG82fQPjWUojvxfjjjwuF)d7osnCJYRkj0aPTmn)ef1DEj9A5r1XZZS1kvs8CRnF0WzZnF2CH5Y1QOmAiCrCzZelzYlxthf7C4XvwREGNtwOks35Qfr5X9azYRnrSKzIpDYvQjBpSCUwrr9fQjJNn1rScssQ7wG(CoRYNsPi6B82SxUIvSmsD3zpBn8YVR41Wl3Zwr0aTUvPwR17AfbzrRfZaW(IVosqhL1atUkBu5DahiISImAJI45pPgZtwt00r4f1I6ltQkzucSrQkikhh8GBaWcEbFGF8)FGnNZk6iPszueLnYhnwQCX4grSO693gDXH0vQPvaPFzCvqAYcsZGFB437ZSwjn8AdECjyi44YcYfWK44KSiV)8zJYflwQvnuku3Q(7mZEzRjwCTJh4Sg51IZnZ0NGtVGGeYXQykbhfCP3e7KqgVm4yvYCs0c0ersrOOZ1SEn0Xle6cUxvhdJxCwXIgv27QI4QNLoyFNVnWjmgCp)Q3gehcTbTsCkg01lg1D31VjuNiHNox6iK2xbEOp4HG9)84LOhbEuyeokejVfBjoR3f4Y5YyqY8e4gp8yW7goKt43bECyuND2oyk19mnUkUIwrGGZrAI6gIf0T7ci9MAlCy49apbgLqgeZxOPqdhWrFgiieA58c28tzUd3hXJFsAWqKuw)oWGtDbdcCavzD6CZcgnhde5O7doWAewfChmp(VlSp1HnqNZyE9kcfvw6u2sdwHMhjrDOdIHtfWt6k058bpO6qD0G2m1xYk3MOh4eQ3pnhmVUcb7wGsvIeg)ZltlaZKHksZ8JUHfzCo73(60YxOgEfQudi0QAesdkhoZiPsNkgCanmcHuNvPvS9QJ1WUewKQ6qX1epVRtwtOibp6kxov3TMtZBjBA(UMyZxevaZKjnVQg(bDkYOZLMMdUnO5TegwoRMG6YZA)WgTE1uHcPNoxYePIzVw1bkDTePsfJBEUehFICQJoGHewSQCrkdnxjjffnRfM64rxEjeF7xjrM7dzVi2KeQEWb05wzMpvTQ5rA1HdScEr1IBBdR)zpSzXWKM5OytGS)zH2uF7CAo2S5BNhHfVbhP5V0XJth5RGelxX4HHyZScHZPawrLoFEdmRVSX(4QwdRxYjhn3dLxxuUSesB2WCjth9eWhzFWhJpcwCEH9bFeNri9h5Hlrr5rWDqrc7lB4XhxDiCFhUibeHkIkoLW5QyjCiABEP73jShNBUIIyE(7vZMfPt2NtXaUjIF3Si0axfcvPCX6IfrCucpSxCh5eEaNWd6mY5vuQYSg9fnbDL5yAeIwnnexujKGmNGKAfbhwdLCwLO(4jisFljuaDMOcy(e5Yre0oZ0jEY2)6jZsfRrBwf4PXYBXIYbhWUyG3NdULimE)eNWtbhdE)RfF0CLJFIfJFQXJQjktKqJQypKelwejZLk2mX4wtrtetJOIjxDI0CjoD6u5cNeg)WhIRqfuHfJd73XY1f0efWyGn6cUXvxqQgAKaUhrrDKN6yAfQiixgPV)dbxKkdBm)udISeN5yzvS1kinJga3HGVmUBVt4RSSOCuLQ5fmGlYq6KJDmyvsZPTdEz45GD78YeZSktzBAjzIuEWl4go(EHjAQi4vzikcGemWKWjGK2s5)2TLwZLrzjKgr68kQKNi8GmDjOEdc2Tvz89uMpKzqY3Ht2PyDGBslz4KuF(TwxCazRa5SLDdtFH9bZWaZE5MILPdHdEqyokFiCA885zGZa)UFu4dYaZJ7tEqa3U8qbR3urabLzuF8RK0bA)1HKhqbQaIWcWIGeufu5vF39VPw5bgWzFiqJr992)AVvPUyrrqnOoSeCogOH1S688WVhCe433b8HiYnG)aE4dty8Hp6HGLHpMLCb4JtZ6tqtFw4tcxOc8P6Gth(0yoB4ZaF2TpJm8hc)rDY8cFog4p(yWNhwbEohWFc8NcpFBwT7WIvd(cTyZCVW5IUGKKNSCZa)zvGxa(IWlcFjc)dfK7a(kR35IdCXr8s4xg(PSq6uWrq)THieWXl3blc8v7dVb8NFL4gEXD0lUHw44vnOEuqmFblLwRmYaJJVeb(3UaEciFk1HSD(iROrnQyckQ)glRbEceIK4T3mgRFqRrLAbJwCfQpXwaHTQupqG9Mjs9r7tN0c0VfoTo5E6Ho52DrxSCuEhmZ2GzgEwmZWAeIbwQpXnmEQ5OenJvS4r0Sla)8HG7JpIMGyr(ReJtDoSqFJg8SQ1X9eEmA0OQGmpRbsMFvJLWiZgLWEYGvxtFMhy5VvGv7o3cR2yp(Pugp6yscrL6Iv7OTy1wP1spMplivV0tBZ2mj178aKepDWHHBeNqz8IjCrhDYLnjPIJrvDXALUnzlDbpukmBYpTjBYgTzYWdtE4Vg(Bi8jFlEy9rc5gZ8GTqTf(HOWuWqrJmlMcwRdoVMCux22UcI9Qe7Ku3t0KHNkd2vNKHJEcSrtjYLyMyKXeMisKmShN5RkQPPOvHkK4EXR(J7CL8nTZct37n1TeCG8y2jSrt0FJl(NTk1kMm1K0rl30v1H9qBYwj9eYkHC2j5)ZRE0228eUyX0Y6NzwKWIHj(9FMPqfffoJT1r6NXYF65PUsFeJYcC2(iqPOwjy6ui)eHlyKdw(cbf92PyNNJixzzTMUhIXs5M8K6tVyrPP8wNiOuD3y)7lOHmqZ3UwFOdM3YnLkwSKW3Hh(U2CGW3ZM3d((xzgp4hWdVkp83Yd)qE4VJh(ruERVWDCxx4DbmT2WiyhNwDpT9gpQIMwn62OC5oYSg28n1HBNrIQvvKWdn1hUDEtlRBqSsZv4sLKePB8I6EBxCwr1kkYUskwcbVdyNKfjNWDb3ngiC3myGW9bdDNeGYWwIKSy67KCrbYe59Vt4H3)WUBkSNi7NampiFpe4)KyPAV3DT9Lyyrg7yZYgxjNoHeJHseklfwHfnulMy8AEwS4CIqyhqeNquhyCneZjH6EHhJQyCxF27eUhQvIBuqrrc7aOC2LeXg6TEZFs25MkqsERP6Rynv)0SEcYgjallnXBKGb8fIZJNab9qtz5y971Jho2GSEcOH7K0YsyHOpcMVERloAteMBQ4tNSZLOJ(mxEresnmXfidoc2Rcv7iwtyKdFH7NQbCKdQEnAnyBDuRB5EAK05YLEk4SpSLwOsuTq9ud0jV6mh7EHKeqc2eO8tPn6P0JoMGagrzc)JwJJphvJ(YnxB5Bjz)FwDpnZKWDpUOob1IvGrK2FsBScbaCalbn2yLnLZdSLCWWvSAHorSeecgfGb1pNJMGGxBh2Ga4FNh(LBHA)spa7yHChXJBp(WKBpbX04GE8qtzPPEPu6qSbC7LZR7X8GRRVXCtkILwnwwsfyXqKGHcGBsWX8gKMZySbD7dJE8hIKmgTZSkjqe8J(Ozmg8FELWoW)v3Og41VXItG)7BgGJu6tp3s(BOOUuITcoGFDBuX)c8BEdcbW0xaWlW61ximPkigdmMViSJ5JYNhWpnninneHN39yuKG)Thf7O)InklPSuCn0zRHKl0WYsyR9bJuW6y7eoUK9UXXVmjl6(YNr8CiPvj)mjDZI37AKNBUtwRuUztWkgTC4KAWdTsn3gPiKFuHw1S0DNLosYvrSWIYiDDh0sskIFE30xueRWeCllelx8c5RlJTHnWc9hI9ZV5bX2FlZjVe6CQIwgdLtSkcUiRNJ43AhsSSuKhEzY2HFephHS42n0CU(cnpkwGJh3HWP(C7JMUTbFMm3DteNjZ9yYCV8Mm3NjZqMm7EVMmdZyYC)utGdA5wMdtM9GZBVvmz2h(5ha)3dUBtMh6nuqrDmOG6Jkn2plktvQybs(4BbQSA7kTZAV4MHmHQUqUyj5ILu)u9hY8lEJaYyYCa4IMmVZnHsmzE4UrhFR(IowGJOvclMkuOGJrsd5MMsnnjGpQYkp3gOEHqMnzE0RmP1KzKDE852mj1ajkp(srD7FXA9NK(VEZxrJ7iypkxAKPZa74fAh(vSj40Wo4kNMGCHUmNNenxsWD7mpIH6UYjO2Ln8kyVTQiyGDAs9aDNnU(Yl6AQezZMi1X7SW4ijxH1QQO1QWhRdZPrvvKfl4kRqbnXsIfqTQuhJKOrDLoLRPI15ujxyUJhlNRetn10PIr9NatfUNFmfEA5bbzBQlGUNRxxiwd7NxTQYzjDM1ohL3YuwobjXYYqinSxpKyWYqm7hBWFBpR0SIXkIN6OtyhypaxYUFWE9qCn5ExVydzHQIfOBNc2bOi6kAga7kL1eTcK1DTm5rIQ3r4gNtsSQOXDr2oMKKNQCPckeNUKnIlua7NEEUWJNy6S51ekkwt)JF3yxFwrqRGLMAmq2gc2zW(dlH0m0xTunjPOIAfKq8nDT5FIH4eZUKUo8EcdtTWKejENCbT5Ivnu4gdWoOMKhIPR(8Cv5L32q7YVLPUTof(3S1PmqHnX)MBwytjr2tE66NTCLjLaNMmXVIsBmzEIUf3qgo)mWVgjk(PRzq3iL10LelIYRyyOufEnwspqOG9qq0fgAfAa1j4Xn0n0eibxIAehCG8fQPJ7G80k0GmqWGatMtyLX5SY41g2d8Cm0G0rZMF4gf31WNJzf6E5q62LB2TKx(g4NL1jB0aPi1D3SSCnZgpYS2rRMzWt7BAVXF9zpElCOxFJ5nWnlCOLDY(BgLQBBWKxyPnJjvpvMPKh)4nMl6jgeM8j7jMeJvOWrtMKWRzYm1vgeAYKYKjnzrnJjZjBd1mz46eMzYKTj(YKjNjZ0KUYKzgtMzXDMjZPWZK5gik5DdtW0tqcjIgVEZ9vvDVDfdQM7C6Wpf8nhXRByk4viiiAKH7kAv8WxR7Gac)fDe4VwBBl8sJeG0lPO4qCTWnHu)08Q7UJU0kWO8Q7R74Y3A0809hXE4RA7Y9AHADCfbS9hIvQL)vRsJxpniS891xlYjGIC2RsGv5PE427Bl536NHEyQM3Y(M5JuttwuUCwSFqIgwGZOjzvrfKIhrlvpbNvAdopYBzaNTrp)KU3O)XiB0p8pS1T1h3OlSBoSW0clgHCkBSaxLrYinXczROSuAz(n66NRPt)hhsOydASTP(9KsOkANgRchGJ(t7JR0df1EB3CLrtPSg2xFxpoLWnQ6W0WnvwwrdPuhPHn5bXVbwjLu2MD3ADy75gT8cJucnqHKXVfd0k26dkSiV69tEgroTDDw9Rt8pvITx7D2y7H)F(U2)(ESrd0D7NkeMYgqK4IxoBXmyYiOEWEZdewRGGmY(FU9yb)1dfjv1jMz2CJMyqW)37BjG)D4x6(5y9ZYgAdSL4fQG0TGTBybBNsuNCCG2gk3VgGkEgKY9(JvE2MQJTei(HTWd88BrL8K56gG0FHKhxaRDqZ6h6wOKLsoZPllIDaRqLbHsC)wnuYH5yd5jyasAOXmzQzYu)TgOc5H6gvCO(IkWoRt8vVMMTCJKfYk2yPP8uV8GqeEElJAtBeXP58ekyiYozfKeFfCQhAklNx)bD7zWyKoebzYyCBaM6v6TMicm7sYkgDSVNyznwQS7o7wAR4PqVefVweiLrVrHkyZkkGv7x1c(nQCDFi25kRin6GGFS3ob)6VJN1PMTzdsAAxZuQdfvtzPIUI26R7GGCUr48PNBzC(CoBpdADkhUcoeCi4v55iFCjyF8B5)zWOlu70ZUOi7Ilni)p92eSm3TWGLxO1(ZVM9x0d9RU4IrYMB6uDDwH6MkcV8LBhEhAS46yJ()uWf3G0(5Nkw0jcNkr0(2rMmFMUBBK4XcZTLZPuZG00JgSbPb9(LnGwQfnDQ4tNn2wAJVooBV9CmYLoDUT0kV0xxVFtztKmwQOX26sri6BHTNtSmHJMi(CBNMQou2OtKoDY5tq(yy4MotUb08RLTRAb2a(yJ4XnRBwFJfkIF)b9Y5ZVpVH486HL13vk4lx3BN6oE9BpKE8B3X)xBrgsfdxGDIZMFIzNBqIm8D7GiJwX)XK59aFjyhNxD)n3P)OJt2S)QQsILAyFCUoqxLrctZ4kvfLPHow9b7QqSsNsscLjF)pTdcdTelL35RPj3ZckvtRXMkyCe2ZdCpkkTPrWeklj5sPKRCiY5dSvmDEI7OJG6yY4FxxVr0XKjqZJaSjtisYyBn2nMmhTIDyBmzEFTdyJjZtbdDNMmhdynzE67YK59pc34MmFa8tHRyYeXKjQjZ40qVyYeRJyUC)DEe7S2geDtMJV5WTWCdjAlj0Kso(jfMwxNJyRBFeBCbmpkgEJmzkHHwLVKLFXnhHKLttgXDECvcYDbR9XXKzrtgjCTRUrxaktgLnTvmMmQ4QD2RUDCXk8(3RDi(7Wgfhw7YOTWhIGL7BJ81mmuKtxhPjj04QW62WxTX1vTTjRKTM0(BAL3(KEeWR6jthkZI6Qe5fR2h5fFr43uHkVi8nTO8Enrynz(QnjMj2tpjMxQBjaVbsnnzELBGKq80RdVo(A2KUaLRxiRVzMzunHbr6EXBDjDXpCpjDR1H85BBPB45wpOBsEJX6twuYhB5br3(s36s3I9Z7jDB12ApVTLSHNA9GSnt5zBum8KlLz8Xhez7lFRlzR(j6hzJyBZTTKn8uRhKTrp(cEv9794bk0yqKTVYTUKT9)j6nzRTLN32s2WtTEq2A47SjZhzCFjKhDqKTx6wxY2EL6TDjD7xWTIKUwBgFlxp7n1dpdBU9vMmFs(UjIvnMSHp9GO0zsniI4fV5tejUqgz80ZMI4fzNxfmAIYlImCrkQZdY3SIsuIKrfKR4kA6clIKTQuhhAVyYOQnA2fDEc)IJe0CLUMrxhwrYMd7kj5hPt15qGw5zj34mtNPZVCjRENCB20ZZdi21X75gMRJS5sNPVopYFJ05XnApjZuptp8AS4nMdPx8zZhujW4r8pB(RCis(UV9Dq(W2xw0avLgN)6FsYAgHFgMs9b7rm(tGR5OwhAfBoE86760i(B3h8WbIqEUDKt(2Mm)ODw)Z2UNnz(XBUlmzwNNWV(3VPM9C)6TxZ(F2wnlXxD71SV(1uZGdZki3yZY24Hi7V)IMUQ3rmsaAgDZbOjrQzMFs0sijTgZBZ2MzMmZ38yfKGty8fISK)X1PB5(pSpIS(238fz9yBt9opYhON6DWIw6HmTRz1pdMe9S2KOUIK7JU1i5IhNDV9LtLAHZDkD5qzoVWGw()oVHO2)khLDYrrAkn7lnR9Z5J85OrxWFnwpSUjxLrwI7j31iUYwRqbe5MtbEeSAY1ADyFsuKVVFD)DR0)6MXaNUV2QPVg4oyTipfJWMmRVYJZLzHbrE(UVzZD8lwLSXFrLuKr68wQe)6r8hme5Bo1JxsI)i(9fYh5qzZgksaAGXXp6NMgG(zeIRMx)HwtfPrU(giFn3lluQeQGbMqs(SpWRLxICs)eLrzSQd)nJVBOBroz3xfcEVJ)T28YCL1ReTAYPNSA9bbw(EVz)LkIPcaFRdxLpw)JzY8lnz(vnPYMm)h3uOSDhASBdjY5MSYOZIsVik7udIi)9FZMi)t7GiJzS9fWMg3pc817PyPprrSp0HexZ0HGA6Up3SXZ7xQYGOd)GM0He38C1Q1nNdzOCpB5EKQR7VdRtsoMgqudAD0XTugQUhIEsYNZROgIEvtLJEjs164KVDUFOM06AWXIJI7GKBQYTnt1Qw3dajJfphC29AXDzFb7a)LxR96xFl3HuWFf5(HI2VFJbDHp9qxTiM38VhAmzE1Mxen)V23dnZMUHBTj9)4l4(SDDp00(d6e(MB5EEAtNQaGR77jMHRoCXHlEHhP77feymW0KjUjZQeKP9L2b5c74125T2xyhyxV3YD0HrOIzdKEu3tNDIEChDmSoN3J4)iUhU(D8H())
```
