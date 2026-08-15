# Warlock — All Specs HUD (v7)

Import `all-specs.txt` whole (copy all → `/wa` → Import → paste). One pack for
Affliction, Demonology, and Destruction: every spec-specific piece loads through
a `spellknown` gate, so the HUD auto-adapts on respec with no user action. All
triggers match by exact spell ID — aura triggers carry every rank, cooldown
triggers use the numeric rank-1 ID — never by name, so the pack is safe on zhCN
and every other client. There is zero custom code, so the import dialog shows no
code-review panel. Since v7 the layout is a **ring, not a stack**: two unit orbs
flank the character and the DoT row and cooldown row sit below it, plus the
alert column on the left and — in arena or a battleground only — the PvP column
on the right. Drag whole groups in `/wa` to taste. Note: the `/wa` editor preview
force-shows everything with fake data (all load gates ignored, so the PvP column
and both curse states and all three specs' icons appear at once, placeholder
durations, no animations) — judge the HUD in combat, not in the preview.

Upgrading from any earlier version: paste the new string and the import dialog
offers **Update** (the UIDs are unchanged), which upgrades the group in place
instead of duplicating it. That is true of v7 as well, including the five auras
that used to be the bar stack — see "nothing to delete" below.

## v7 — the middle of your screen is yours again

**The health / mana / threat bar stack is gone from under the crosshair.** In its
place, two **unit orbs** flank the character: a live 3D portrait with its
readouts drawn as concentric rings around it, the numbers underneath.

```
        ( mana )                                        ( mana )
      ( health  )            [DoT row]                ( health  )
    ( · portrait )         [cooldowns]            ( threat  ·   )
         83%                                           41%
         62%                                           100%
     PLAYER ORB                                     TARGET ORB
      (x = -260)                                     (x = +260)
```

Everything the bars told you is still there, in the same colours, so nothing has
to be relearned:

| Ring | Where | Colour language |
|---|---|---|
| **Health** | outer ring, both orbs | green → **amber at or below 60%** on your own orb — the health half of the Life Tap decision |
| **Mana** | inner ring, both orbs | blue → **violet below 30%** on your own orb — the mana half of the same decision |
| **Threat** | outermost ring, **target orb only** | green → **orange at 70%** → **red the moment you pull**, with the percentage above the orb and a pulsing red halo at 80%+ |

Every ring still dims to 50% out of combat, exactly as the bars did, and the
threat ring still loads **only in a party or raid and never inside an arena**.

**What you gain, because the layout made it free:** the *target's* health and
mana are now on screen too. A warlock reads both — target health is the Drain
Soul / Shadowburn window, and whether a target has a mana bar at all is what
decides if Curse of Tongues or a felhunter is worth spending. And each orb
carries a real portrait of the unit, so an accidental target swap is visible
without reading a name.

**The target orb disappears entirely when you have no target** — rings, portrait
and numbers — so the right-hand side of your screen is empty out of combat rather
than showing four zeroes. It is not a load gate or a condition; the health
trigger simply produces no state for a unit that does not exist. A target with no
mana pool (a warrior, a rogue, most trash mobs) shows no mana ring, rather than a
permanently empty blue circle.

### Nothing to delete after updating

The five auras that were the bar stack are **converted in place**, not replaced:
`Warlock - Health` and `Warlock - Mana` became the player orb's two rings,
`Warlock - Threat` became the target orb's threat ring, `Warlock - Threat Flash`
became the pulsing halo, and the `Warlock - Resources` group now holds the two
orb clusters instead of the three bars. They keep their UIDs, so the import
dialog offers **Update** and rewrites them where they stand — there are **no
orphaned bars left behind and nothing to clean up.** Six genuinely new auras
(the two cluster groups, the two portraits, and the target's health and mana
rings) are added below them, so all 38 of v6's UIDs are byte-for-byte stable.

Two things to know when you paste it:

- The Update dialog's **Arrangement** checkbox is ticked by default and will
  reset any group you dragged in game back to the string's coordinates. Untick
  it if you have moved things — but note that the Resources group's *children*
  are what moved this time, so the orbs will land in their new positions either
  way.
- If you import as a *copy* rather than an Update (a different account, or you
  clicked past the dialog), you will have both the old group and the new one.
  Delete the older `Warlock - Resources` group in that case.

### Honest notes, including what is worse

- **The numbers moved out of the bars.** The percentages used to sit on the right
  edge of each bar; they now sit under each orb on one shared baseline (health
  large, mana small beneath it, threat above the target orb in its own line so it
  never crowds them). Same numbers, one glance further from the crosshair — that
  is the trade the whole change is making.
- **The thin black bar borders are gone.** A ring has no border sub-region; the
  dark unfilled track behind each arc does that job instead.
- **The portraits do not dim out of combat.** The rings do. Whether a `model`
  region exposes alpha as a conditionable property could not be proved from the
  sources this repo verifies against, and this pack does not ship conditions that
  might silently do nothing — so the fade was applied to the rings, which carry
  every number and every colour, and the faces stay lit.
- **No resource breakpoint marks were lost, because there were none.** The v6
  warlock bars carried no tick marks at any threshold. If you ever want them:
  WeakAuras' bar-tick sub-region is *aurabar-only*, so a ring cannot use it, and
  the equivalent on a ring is a small static texture placed by hand at the right
  angle. That is a build-script change, not a setting.
- **The threat ring is guarded against a trap the bars did not have.** A bar with
  a zero total draws *empty*; a ring with a zero total draws **full**. Threat is
  exactly zero in the moment before your first cast lands and right after a
  Soulshatter, so an unguarded ring would slam to a complete circle — reading
  "you are at the pull threshold" — while its colour stayed green. The threat
  ring, and every other ring in the pack, hides itself at zero total instead.

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

Five of them need arena specifically (they read `arena1`–`arena5`, unit
ids that do not exist in a battleground — a battleground-loaded arena element is
a permanently blank slot); the rest load in battlegrounds too.

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

**Resources** (two orbs, flanking the character) — since v7 this group holds the
**player orb** at x=−260 and the **target orb** at x=+260 instead of a bar stack
in the centre. Each orb is a live unit portrait (28px) with concentric progress
rings around it and its percentages below: health outside (96px, green, amber at
or below 60% on your own orb), mana inside (64px, blue, violet below 30% on your
own orb). Together those two colours are the visual pair of the Life Tap prompt,
so the "tap now" decision is readable in one glance at one object. The target orb
adds a third, outermost **threat ring** (128px) with the percentage above it: it
loads only in a party or raid **and never inside an arena** (there is no threat
table there), appears once you are on a hostile threat table, turns orange at 70%
and red the moment you pull aggro, and a pulsing red halo rings the orb at 80%+.
Warlock threat is dangerous in all three specs, which is why it rides on the orb
you are already looking at rather than off to one side. Every ring dims to 50%
opacity out of combat. The whole target orb hides itself when you have no target,
and its mana ring hides on a target with no mana pool. Both cluster groups are
independently draggable in `/wa` (`Warlock - Player Orb`, `Warlock - Target Orb`)
if ±260 does not suit your resolution.

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
The threat ring, its flash halo and the Soulshatter prompt additionally require
a party or raid — solo, pulling aggro is the plan — and since v5 the ring and its
flash also refuse to load in an arena. Life Tap and all three "MISSING" prompts
are combat-gated, so nothing nags you between pulls.

The PvP auras are gated on instance type instead of (or as well as) a talent, and
each one carries its own gate — a group's load is not a child gate:

| Element | Loads in |
|---|---|
| CC ON ME, TARGET IMMUNE, Trinket DOWN, Howl of Terror | arena **or** battleground |
| Will of the Forsaken DOWN | arena or battleground, if you know 7744 |
| Fear Out, Spell Lock ON, Fear Ward UP, Enemy Trinket, Enemy Mana | arena only |
| Threat ring, Threat Flash | everywhere **except** arena (and still party/raid only) |

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
condition on seven existing cooldown icons — so every UID is untouched. v7 is the
first version to *repurpose* auras rather than only add them: the five bar-stack
auras keep their `W.uid()` call sites, and therefore their UIDs, while their
region type, geometry and parent all change, and v7's six new auras are built at
the very bottom below every earlier call — which is what makes the bar-to-orb
move an Update with no orphans instead of a delete-and-re-add. Removing a
`W.uid()` call site is not an option: it reshuffles every UID after it, and
`W.assertUidContinuity` fails the build if any previously shipped UID
disappears.) The
script checks UID
continuity against the previous `all-specs.txt` automatically before overwriting
it (expect `changed=0`). One more re-import caveat: the Update dialog's
**Arrangement** checkbox is checked by default and will reset any positions you
dragged in game back to the string's defaults — uncheck it, or report your
coordinates so they can be baked into the script.

## Import string (v7)

```
!WA:2!DZ1EuUXv59mw2joBCsS3y7eBsafhSRxtIrsRETM4qK0kzR17kjps7d7yy1iPrAMDhnZ4zgT7kdgiBdbhcV6gifsHaDlnLsPuQGsPVj(ecVsHp2wctoCoTWYJM2sphQ7lo0Y507JrsJ2vEL9AhN15p2zhDN79o379733R733CzgP78FIx3zEnlKJl)Kf0uuJOiPOnGdhos5W1(9P2DEfzdnfjj(creeLkOXlVp1TokNMKs(jDEpotjXvLxZzsTC2lndNwjEdCPlMtrRaVwyRExDZHLep1P40k4mJIIKHOQ2mjlwuN3GjNkhQZnuV16DtMWrqDvijjNPv5ZRNJ2tcAvPn4KZRXxsurotvvE2sAkvuNNwJ0INIFd1eLlQOvMZavJUQrFaDQXWW4ybUkgckAjvXpwVRCOjzrXsDPXLNuGFwDdonJUYvuuwuxORWO)z01SgAILkXRPNypAw3(4HnWVDUkACEol(QUkVKKyb9D2TRWvqnkNkz9zws5XlO31I6vYXpfAEMUsXIIZuB8iHsNz80zcXMPXJsPXJEeB6urhCWZvrNp6mOXvAApKLvMRmVExZxGphQhWtETdhDWuXgEW5QiBnS6Qwbr9jQiJMntX7HtssDlCK7ZqF(qkf4)mxJ1Yv0cL4v3s6twbT87mwf0Y9OcIg8NL(u6A91phNSiDX0pS1yNLNtNpTbICvYq46GDewwrMFHcO5pUgJJxt005rlQf0Nfxv8OeCfUmNOCm41JAa4cCdEGEr)FBlTK505LkMsru2ixKOjYeLDxIfuVLMylwEDLkA551phQk8AYCsJGEBO37duROgATbnU4m4CCoo58isCmCr43FU0ryJgnX8gk5NIw)nMABEQiwO2H8FsJCAXyhz4JWQNNtI3X8ikblbCPxh7exgTm4yE8CsKcAclPWvORA0xdz8c(pZRbyAW7aR7anbZn4uompNKHG62w2dgItMtDhlR4ukiWgNObSb4AHRBWndBecaDja3adSj4gHBAdWn3fSzcQg2sxq3Db3cIe1fSTUGT3fCRj2dCBpoA5DNWRcHjHBhUd4v3f8AaNWDc7cURSWRTly3WEGFTUG9c9a77ZCnWRdUB4EUEy)yk9sPwE7m9d8b(rKmWbe8bG(CahaEdW9IwRHdwlsYKLftv0yuTeWB0bC)DbHCaH7cI0f0pAX7a5qGDTXRYq))mmW1XuJRWev0n4lme3mRR5peLxhEfa1k1TwGxNZaJ94XszWscKliutht35Nb9a(S2RtmfKydADy1L4KnyMLxUqi5ss8p02rd5fv1ukPXRRNMGY23TFnRdpJql7oWlUBPRz1umi4Cgwojvbo0m4a7HnVaF(jJb3MJzNIttKlNe)ciMG8iUzbcbNDkoPk87YVRDPOUR79GA5f4KlXRVZ9aJnqQ17A)95JGzW362NJzrdcuZnQEUIngUePx7bgg9s2amYSIYrukNJZagJb3Lh8GWXWDgf5DCidTMoGrMRm3m0Xamw3wVEADzW1dU)DEMTR2TbAPACDbUcktpMLa55iLHVOU5D3YKz37wDZ2Aqt5QlslTodC4qdNjP6TqkejXvblbj)OIfmechc9ZZrEasuhFbsHp4cuMPJrhap36plPcysUyXQG)5jR8eQA4ejtef2HgIrfxN5jvmFDvxoOd9IivxQBoMM4PCE0kCfWIfCMjJQRgZRXPQigVLj34f4ZJK1jnUQg6gSGcMwwESgDmlqkBAK0Hr14uNDuRBwOXRMiBo5WzgmEIOwRxTiSqTNomqiKDI0u2IskkA0LJPqJje8kBZxewH3DAT2vN4PU7o050cZLOs5C8A5e4fljy80RAM(C5ra2XRIHVEDBxcK6Mr8YHSyBjCXcQBjxd(ulou1aXXYYlYLN)eHkuiPS(jgLNBYqynQNyi(cICNWQM6NGvuU04UDPoZ(nkXrKSmprBnHfMbImYCO3445L401ZMZajox2y7SLRGS1OlwsP7jNUiUUAJgIDWKroc8o3oCMSHrQOZVD4D2vyD0Yj(g4wFZwcpVDSatwIU5Cu53wcsNf)QW65ZseN2qwQ92bpQ6whgvfNre4WgyWRjIWZ51Rll(9UK2wxoCUYIAAkAclDfuuwa205QlLYGUSmRcsPgsHHExZHWgYfWA4zdpy0e9tmlHTUiRf1lROyiKYQ1zNNicmMOMUHqnR(iVKOQawS95S6CmSg3HQBnYGHgkvMKHhmuKJeQ)(JNj(iiODtYPf47CnlPHSbm0WNVzZRuwf)MfWQiIcpWaujE4RbcIV6XNdKwd2PXceEA1T0u(NfaaEqKIKy9KPuSJmzSX6pIMOmwFoVWCKPcECMlEI0X7pAnfnrefJmXNlcMspA80rPi1zSqQ3CxAKMXxq4mhaIZadGv6ahzDWG1vWadjajYcjfGumWrj6ia2LRwasZazi6cQl49SwmCQktZRbJTREXcF7(EPYEjZ7a(OZyQcahiXXpqdb8Wj6OK9zrs2T68UD3Eb7WBMbg)C72(iz37g4OMlKdYdfaEO4dcL(zBaeqthryceUDsqAak9IokD4akdYGkJ6EpFsviDTnjwW0WjbnqhmGkO(DMSQV2vUP0YG3ku9wHtXO(6x5AVCz0WPFWvVjlVTLl4cE7cW7ab2iMUmlwUc8RNfEiIGHhEpW7codvUb8iKIE3nLy8fBY5ZMIqEqC6Zrg34vgMwy6xalbPXZY2w5hW7RtYkG3Va8bqIfGFdyUUGhd(GWhIbE8SWVPa8HjSYWhbEc43Ib(OVOa8Xi8EXS49OOpVnWGil2EYhe(4e2mxtmtKjKKCNMDe43waMh(DGpj87cpvdMh43t4m9wRmINtkU(We5GiZu9WPkkGzJOmqAKNJnNBZnTnUTgPwF((E6089SQwwfFCfLYzrCKNL(okkkXhVaChZt)Pkhss9DqhFJRJGtvzqSP2(nAmHmc909DHrDBAA)S68NScVCEEh2eaGmk)1fobYtiytSKxbCt3zZ3vf9JIwWA(BTtXOXvykKwBEHvpWfrTcDRwlWNIbUNBGGxX03dzvAvBZxTz(XBgEY(iaIdwRYrJLyOJCsKhQEXIYu3mPE9lQJ9znoY9zbIanBJzJtzVZQYSe3DoU62TTfacA8CgoJH04IuHT0YT7yK1MfSChJSEWsDmYQ4wDmQ)RECmA9l3XOJ4EsHHf1g4uzKANJrorZT1tyHjd7NVoRcr4HbDbnVr25P3I5drg(GxKqtIfBwhcd6CnQ)Uc6cnLr22wVGXX(CWzOOTR77GOxW3gz5YMTiJPfnQquKswDwY6YnJmSIA6ngi4MEbjIiOp8c)7Nss0SmMatiEmpiJhWZV2Vuwe2roSrcOXp(3Oh)9MN4QvQks68ZwFFg62nPjlBDwDlfe1ZRXBWpEdx1AH2)DRlwNshSilFvSeRmoMVPRIcyD6hSwMboQ(WtwqAOENIqZW2eC6NzJ5OEJiarEyKSJA4LzKzL49HklXSqSzKcurkAwpaD)EGBmByeSTq2ZNCMPyvrwZwnRh1Pq9es5Nr1YCYz9yWlJOWtJubwTO4u8iBBj3NfCLfEYNzJRwZxwFRMVmqdRlGVdYMLaehgVpl7kOey)ecSnRvqvMLReAgcJ5WUfldGRyFed88qVErBItnk4K488539vIvoND3naYnmXr9UxMzenr7TXgc7we9rQBqK6DUcDsdZwOwnrwGcsTDQUrt2neQnUL1SVAX6jIzqi7MGtV(n(sRHny4l8pKf(hTqRWpWcNc)WZpifwml8JYc)4SWpjl8tZc)teCiX(NNQHM8VfsgcsmkKflALiqb(7Sja5kGvoFTMw5qimOl9sTXbTQsnYPV9oMs)r6tIlI053iNlpmx77Ib6dVPoa4rlRTXq(NB9TAi)loabgQWSeKimfcKHGxvVtmo7TGqWN(PxJya9snf8B3oqXvaWZxhEGxuKawEAlSsoFvoApjcPPosW1wyLF)o4ci8PVqC67fFh1fz9hSm)3GptDFZG)W1qoB9S2WaFwcwbba(Ji(yrHbQBfRmwdzVUOgpXDSmehT(Cxb916BGaspzlEwn80X1h6yrtC0crwbpRGAe)PGpVnVPGVWfNFuF7vCU8NGDEc(IOA9NI(7lHDpc(ZwLofb)5oSbJXEdb)fOLP)sKBqWFf25h4VMb(BUuD2b(YT4MZ3eEAg4S2DRX9KtU3izMzcFvlq4SEgl3yGVcd8Sl3LfBrTmIIMwfsibpNTcROPZR2DZcIxUSIeYWp17OzzdlRBG3ZFNHkwusKeer7oYKwuvqr25GIf5PERWGwOUEIZkBAnU3kl2Cw0Vsg9L76sFvIkgRI7jlCmX256YDnVyEfzASuU9RbUU3ZgSWXlKxrrQGY0YPNweXpE26)ehosHW4gLLoTFk60(D7XDapH97Xd5sVHd43Bqw3U9hWn5Qhwp(61TBwpb842VgQFsklHSn2c)VKfkTdhIDOydpO9LRGpW5MKNxneEBGnyXEniqGpFFb4(33zUfIu0DTB12jgLzjBDgocelZ2VZgprIOSJhozMmjhcQEhuR7qU6mNEfRqBVa9FJRq3fvRiWAfwds4vSkPEiaSIn548O1m4UR)lSJhoGtF0lm(3nb)kmG7G1CLBiTEgtpsFCCi05Va(7jZJWNsrPmXSPzRtHY2G57)qDR1leV7S9lQJzcqU2Gf1DulOhgpTdQBCwqVLuY2wwji0psOODgamGdbQq8izCCM7c(LyO0Z1qZ6)Bw4)ta(vTcy(e3QN(c6kSBxU9IqmUdGGjbC7MC1d5AVeWsqp(D1lBVU6ZnQUE7Zf(rEivZJhCf8Gqzbc6h1Ka91Basj95jGlViaOVG4l9r6m6t8hgDRxsb9zYCTNp8NjZ11k0ZKzJxErBMmxVDmMjtxMm3aJjZMi9NjZnM1K5MG72K5MxfiLe6dFSP9vvrD642qkMmBHGtmz6Ujc5)0K5wUcbhywr0Wt4PxVbr0TaiarFEd7PpVe5g(9rUgGCniwgIR(iWcFRAY3bE(fkjPmDmn6wewL6(bnwL4hCwK9ihsYkQPzNfxejfwsjodV084FoijVk2wn891J24CLQ3eKpM0nSL4foPs1d6xy8peivnnjrgiJKmcI5NuMxx3b5jdkIUFlKxuyAg1SwhVLjw(CtjxuCk)t0j82)1lH4TD2WC7f5NrvKUjuzelZdJ5X9(9z367SWXX5qY(DVF8YCR40JTI40dGef52vq0vVU8sUEPGenz8vh(zY43KjaIme0KbjB6aBZK5nGiq3lztAcqDmgTMEquz3NGjZBeD)9J(l0wmzc)YbczkecHS3LKuNAszIIhkI5rwgUz(MvAJv(Olf)eS8ezIoiB0b1hRt4N)7Ri4htM(HXmzIUeiJjtSwHk)XRiuzcwSYlKaSGbd0h(AqxKReJG87LOtZ9vvAHW0CtMbo)0ztMJSXdDSLsFn4fL7F6iU8nzLorF)FUcOpYv4sidq31WPG19e2JZrAs6J4mJgoMp29OaN2sKWKyRmSVcoZWP2IBekvK0f4mm41uFvTwmQ(Yt6CO4PthpXHS)Wy8sodPvwrRXdVlBw0ZxwrwmVZ0C51elkMNVrLSnsIeXzYeohkAlHSje7HIMXz8HgA4erjU0Gie3WttWQuNyy1v5YZFJxQEXudz8BLYYPXDgjHY8LJAbnlNKyjzWVgYXlCkns8znID3r1OPSiYvFSVwVrhZIikw9dX307g20zluvMRSyEYMZJ8blSUIMb4AUsAI0ms6gMfFlw98Uy7NvsSSOXnG3C)bX3jSiYjf0Rx2igxEdfTCSH6p(WPZPXvqSI(dTjK3xZXPLNQnhHOTWG2dgwijEnd95lwrskIOwEKj919Uc5hoYpQRt6sWboemLIjXsap6eAhlA5GHQ2bZLQtEWM7619fKJMRgTo)81fXsxt21i6A6OCNyF2Lk3POONJE8PozjHbKGnAYOSccEmzgEjsEqJl47b9QHZp2Kvmir5QMUKyb(CkggkLHxWdQpieZ2it6mBEosQQIHMlOJJdAjbdInFWoYLVIoQdYrQqv8qXlGgmg0cMHwWl0TBiddjvPifNT7QfU(UNHzosG2WD7S17w8lFb09Y64T9a)i1Tu)zzQxmAKrJgz9cYs6BsVL9sZc(gqYE92xV(FjdssTR2x9uW8Qn45zMEPWt1XsnKC)hQ6XICKodphP9WteSHGmnzQaVGjZuNF8OjZ0MmZGNnvnzovtuNjZBXoIZK5TwhQzYCAtM3gURmzE7MmVduNzY8GOjZSDeW8AHFjtBXl4Te(NwFhqv3wl5mu9OB399cFQD1RlRnm(oi5xxlzxu9nqU5UMAFZIBUJZJUl)UAKTkOAzTNZV3SQBXwxsZ3YSQBV18VSXO5(6a4DFxWwX3RvChpVy3leWwXgEMnpjpkjjzC2v0ln8xBajNrq6dv3xZm5e)B9tq(WfgNA8Z4HROjlkxknY9jrdkmnYGEu5ZlflSwIZdmvOjmD0x5atBIJ(BZAlsPFND1hoTmGfWrDFzXl9mBHfjHn)KHXPtnfMvIxMxtmFAbLPtkNDHw(znDY)y55kuLKfAe)KsWvMFJgZd7GL8tRKuDhrS2kpN1ZouN7Lq76rTBsYnuswrJhNJOitI4ZUasZLu66DxnB2MUqdV2WpHe7x84NYknNLsI8tMv9wW3ZJ)4wSx9lvobIy8ET2EKlfoHhVLaH3MnRGe2CIGzcdbwkmAvTbBHjZ7wD3TNBiKwEozER)5YnLrqpy4eLp8iJMPN4DMrySxzWiyZD2DY6XNhpbxazZEEbEDkaEbkaEirDCoBVA09FraAC3jD)xiOMhUUYAQqYhIImEKSltH9azAfQSYcopehsXHg9h6u8Y0doYXljI8ylVqNXlh7vC4L9X6jO7a(XxdIOLpPjZh)vu4d5n3k(ypRi(a5Np2n)kAwYsgmFAXQtpK7Pk1zSXXFLJsvlSXXzDhmqq8MIfahrh0v3KREy71xaxU7mAXMyjtMp2vpORNQ96PWaUfLvmSTzQi5pu96TwCdDzpcbegVWfJqQu6vZlGS9ipY2GYuGypYt5L3ZXkPi1tNbIpWvvaXv2R1PiM3zbxQB)ZJQU5iAktxWzKgFv1ym0LfpxDVwZZ1Jz5mrJ8k884dXEGFuww83(nx2MoVgiYevo(Otk6zYP7SZRNObU5yRHXnprZSA16JQN8Drpw40zgorl5nBR0t44NRzSKS9vGscKqnySfWTF8HIg5WHsepYk2rMmFHwBB4yrdXUSC2TE4GAtdwa3G2)Y6ql1IKmrSHthDzTXRTV)12ogztMmZYAvVKxx7FtPJpy0erIU8LIGK3IN2oXsfks8yhB10u1nNoYHtMCWXJJ)C1zhovMo08lMT9Acp(96jSBxEC5XBFbd7ZxGEz96ZBVbz71ThpEppX25YWo064ZFvLGKFUJVCtPhsfcL3ZHpzUdp6X6S0J30vfspAeDjtMmZF4KSXpEYezcniSUtPUZ6buis)4ykuwvsSyvRex7v1YZWrdQFLYIYKyxREBT8qKoPIsCLWF5dnJ1d5ju175QOj32huSIw1L8G(5r(RG6rrPLmcoSY0sovk6mdp(JBTrOJU71Bl2rMmV5R)snWrMmJtJxeGG3C4l5wEiImzWUorIoKjtHMXfYKHhUPnyYueqR2LUbtgHDX2VjJi6UjemzM0KrYKPmjcpMmY2cTZTypzcP7MIUjJ6sJQdZLLG6extAW(pk3W66SyJIxbrjNbX2(EnzEFMmVFeg7dSi1P66Jq8YPjZCB8qQyi8Jr3oitMpOjZhcv7hFHwauMmF4LSJoMmFeu1EIlWnUHMDbbSYWaBMW4GUTLwcKWcBcUqUkggkYjPFwYxWMbh6cnqYQnTTfVxNwhinzTs6e)9QE0KbtnPUkweYZTIIq(kiriceriHEjlSYxuKytMVvDYA8T2wY6ITkl4kjD1KbUStmrZsBoQ8DSiI(lnv(0EhzKE046mr8zxdteJTV2seRztM9v7uq0uSnuqPEJ6XRSOKxpL6mf8RUgMcg972wk48n1TE1obendBdbCKsJwTqObMov)93zc4xBnmbCQJSseqSnqxTtarZW2qa75qt0RQVEpK)8v7mb8RVgMaUZ3z7jGnTv9QDciAg2gcyvVNCWCH73BC5E6mb8BSgMaUnP2BjtR(uSgMi2yV)B4jB7PJOjA9ngZK5ZLTvYzzJbQ6vpaFYuj6m58BEfGCI9inC)jhnb2xu7NaeAIYtYB4e)i7zD4OIseYLHaVZykA6CtYltRKTmmmQmF5Q17c7PJymEonNjR0YjibztODoi(hjtyFiqQ8O4tBYHtz)l9I274dwI2M8IihqVXlBoG6jtYuROlOzVC6c6c2oabNkvB89SWLNmkm2O5cO4V)W(gn35pImFPRDD4ZdNzfn4lts6GPEx41mmNn8OQ3wBs4G4OA2dnxAS49rRVNLK(bw9rwyhHX33mqnFrtM)Lno17PzpBY8VU0UWK5NLfZG(VTKM9y)ZRUM9IRQMf)tU6A2N(IQzWE9WjxDzs5Yc3)oVqesDbVvB44b1ZsJhu8eJm(a8tZlPvDClU3uJKA8654qCwU(Ni80(6xNST(V4kk86hCfq41DTk1f9QV)2QlcjKPns3U4vjDHsSEylIvlbtEGLhmz0WT1DiDOetmZy6YbtDkUoti(Hxzmk48hYFCUs9OAwhIU7K1l(BWJS0)cEC7Xf(e2JQcicNUHZ0vYNNhFu5b3os7zTgzJu8czxXVf6LysWLjMf01T3uj(fbhJhkHQqypdM2BP(ztnrNjul(YohZZppEZfJiPiZRNLQW8th2xGG4VAx39IV4lSpVb9IZVCpbd7NeLE0T(ix9t(kkrvRxFbRPYRHpXIWNOFZYvSiFEd(c0pNf065I4etuuMpfTszFP5JJATvAQFbizEdpvtwC2s6crkp4WduEQoJC(rVS)HAIOh)YSnsfmVE81N562G56U2gKCZ1DDVerMBneDx9sXZmGqpJYNCs(0d1zk(p(LDk(ZAJIJy596NsWxjI9LEY2ScX1SJuK4x0uKaA6UMz0y58jj0zkYpPbfj(lDoRnVUkN2KKVUPTrOoKHL1zYa5znoSyv3sl)gligb4)vcn1jB7KxbrZw6rVc8ZTDmRuNOropiSDunBfKUzZXzD(83UdLYVVWzjdf6358XqUrnW2HDudF02IA34O)Syoz3n(4XFvZFop9qAyWOXYav3gLpDfpbDwPETLZqNA0EMn(HoCMgNMoBJEA6mfb3v)0FGEoo7bnNwbK4oUarIlsw2cx)ibgEE4TlqrarAsbON3i4Z0gnRvu7R2JT6Jw5CeATUybEw6e3gSeXcWuJ8Aom5SN(GW3LnIepNmcLsF91pBO3BtlMW23jkxkmN2jgo(908x3tAcqL0mB5t2pfl6bZp9VBD2WmAYQU0gW3ENW1jrCjwVEXcf4LzteDKOSWN0K5zS)L6cFQLDW9U005yDBbZA9rjNXX4usP7YDxO7cN5v365mdea(fMmkMmphMDZ6qGbFaW8CBCn(Xv51V8Z8fJGfs7pzpUgo9HBZz(s36S9UFF73v3tT(t)))d
```
