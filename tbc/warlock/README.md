# Warlock — All Specs HUD (v8)

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

## v8 — one orb size, shared by every class pack

**The orbs are now exactly the same size in all seven packs, and both orbs are
the same size as each other.** In v7 each class pack picked its own dimensions,
and inside this pack the player orb (96 px outer ring) was visibly smaller than
the target orb (128 px) — which is what read on screen as uneven. There is now
one canonical set of numbers, used verbatim by warlock, druid, hunter, mage,
paladin, priest and rogue alike:

| Ring | Diameter | Player orb | Target orb |
|---|---|---|---|
| Outer | **104** | health | threat |
| Mid | **78** | mana | health |
| Inner | **54** | — | mana |
| Portrait | **46** | face | face |

Both orbs therefore present the **same outer circle and the same face**; the
target simply nests one more ring inside it. The clusters sit at x = ∓260,
y = -60, and the readouts share one baseline on both sides — health 14 pt just
under the outer ring, mana 11 pt below it, threat 11 pt above the orb.

**The rings are drawn with WeakAuras' 20 px ring art instead of the 10 px one.**
At these diameters the 10 px annulus rendered as a hairline wire; the 20 px art
gives roughly an 8 px band, so a half-full arc is legible at a glance instead of
being something you have to look for. The 80%-threat halo follows the outer ring
down with it (140 → 116) and keeps the same 12 px stand-off it always had.

Nothing else changed: not one trigger, load gate, condition, colour, spell ID or
region type, and **no aura was added, removed or renamed**. All 44 UIDs are
byte-for-byte identical to v7, so the import dialog offers **Update** and the
pack upgrades in place. One thing to watch in the Update dialog: the new sizes
and offsets ride in the **Arrangement** category, so unticking that box (the way
you would to protect groups you dragged in game) keeps the v7 sizes and applies
only the new ring art — which is the one case where this update does nothing
useful. If you have dragged things, let Arrangement through and re-drag the top
group afterwards; every element inside the orbs is positioned relative to it.

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
in the centre. Each orb is a live unit portrait (46px) with concentric progress
rings around it and its percentages below. Since v8 both orbs share one outer
circle of **104px** and one face size, the same numbers every class pack in this
repo uses. On the player orb that outer ring is health (green, amber at or below
60%) and the 78px ring inside it is mana (blue, violet below 30%). Together those
two colours are the visual pair of the Life Tap prompt, so the "tap now" decision
is readable in one glance at one object. The target orb nests one ring more —
health moves to 78px and mana to 54px — because it carries an outermost
**threat ring** (104px) with the percentage above it: it
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
move an Update with no orphans instead of a delete-and-re-add. v8 touches no
call site at all: it is a pure geometry and texture pass over the orb regions,
so all 44 v7 UIDs are byte-for-byte identical. Removing a
`W.uid()` call site is not an option: it reshuffles every UID after it, and
`W.assertUidContinuity` fails the build if any previously shipped UID
disappears.) The
script checks UID
continuity against the previous `all-specs.txt` automatically before overwriting
it (expect `changed=0`). One more re-import caveat: the Update dialog's
**Arrangement** checkbox is checked by default and will reset any positions you
dragged in game back to the string's defaults — uncheck it, or report your
coordinates so they can be baked into the script.

## Import string (v8)

```
!WA:2!DZ3E0TX15D6rWYwMs2wIws2sXobrosvuXwfaeVOQvIbabKafja0aWhswoedagGzihmZOzgqsOw3eZ64ihNK2LoXBI3eNu2SEtttZ2LjnB2Tp2eDsDsADB(m7g3jNCoDtuEuN2DpNu1hBoz3Co97ENbadiHi0llt5)GdhCN79o379733R733CzgR3IFQ3(zFllxGR40L0uuJPiPOnKlxUY4YZbdO2Brfzdnfjj(sXeeLkPXlFa1TpoNMKsXPD)GUZiXvNxZDATcolnhNwfEdsPNVGIwjETO29U6wJkjEMZWPvYDoffjdrvT5sxUSoVbtbvoSZnuV7gDtUOXWUkIKK7SQ8f1ly1tcA1TAWPxuJVIOICU6Q8Sv0uQPUOvnYkEg(nUKOCzfTQCgyn6zjRhyn1yyyCTmxndbfT0QKhR3tbCswwSspACfPfeKv3GtZONcLfLf1f6jk(pJEM3qtSsfEn9u7tZ(2NnQb5TZvtJZ35ix1v5LKelPV7E9eTg2OcQ01N5PLNSKEpNxVwb(zW5z2ALllo3stgls2CtMnxe2CnFugnE8rSzZeF4HVqnD(4ZHJRSw9qEwzUQ869Syj(cypqM8Ahn(Wzsm6Wlut2Ey1ZsLe1NQMmoBMH3hNKK624O3NZ65JOuI)ZDt2lxXlvHxDBzpDnC53DIA4Y94cIg8NZ6PwR132cCYIwlMbHTN4C8C68znqYvfdHBf2vuzfz(LlHZFsnMKSMOPZJlQL0NNuvYOe8eTkNOCc4xgBa4b8c(G(X)VJvwYc68sLZOikBuiw8u5IZUhXsQ3vlSflVUsnTI86xaRcVMmN0y4BdFVpYsL1W1gCCXzW56cCYfrsCcsrK3FHSXyJhp1IgkfNXQ(BkZo8vtS0shj4PnkOLGDSrpgRErojExlIucwk4sVb2jPmUm4ArYCs0c0evsHRuplz9AOJxi4zFlattEhydhQfyUjNYr55Kmeu3XQEWiCYCQ7AvfNrbbBCIgWgHBbU1H3kSjie0JaS5xYfSf42H7yJWD2dSvkSg2wpqV9a3fsJ6b2rpWo7bU7u7dUNNfxF3n8MqqjCVW9bV5EG3c4gERWEG7pp826b2lSp4xQhy)qFWb(C3e82HhaEWBdoiHuVsYL)UtaHaqqKMbUGWpcmGl4qWVc8q4InC4LILoDvXmLngxlf8oDbpCpqexq0EGy9adIREhQaI21MSoJ1)NJbUvML4knvnDd(sJWn3gA9dr5naBMH0k1TxIxNZGa(4jIziIcKljSKoHWZph(a(8oRtcfuUHvDy1L4KnyMNxUue5ks8pXoXH85v1uQOXRRNLcZoW9EtBGmJW1DxKf3T1Z8AkguGodlNKQahodo0(ylkWxC6eW94A(z40e5kiXVmYfuezNfOuC2z4KQXVNGE2JI6EEOdRvuGtUcV(U3hmXqzUzphCGauqd5wVbCnpoiWMBu)cLBoCPIV2hmk(s2im28IYXuQwGZaMGH0Lh(WWjiDMf07KqoRA6cgBHQCZzngGj61(1Bvxgs9GhE3NDNQ9AGlvtQlWvsz2jSLiVaTmYf1TU32Mm7DVQB1rdAjy98wL2GdoAKrZLw9UOfIICviIqkoUyjdHOrWFEb6dqzD8LOf(4lBXnDcRbWl56C0kqi5ILRdbxKUYtPQrtLovCyxAiNkPolsRyXg6UCzn0lJ6Uu3AcnXZ4(414krKl4oxovpnNxtAPJyY2MCtwIVikStAsvn8gIKcM2wEShDmltlBwu8W4ACQZpU9nl38vtfoNE0CdNmvC71R2KwO2xxgiuYovCkBzjffnRLJzWXecVY36fr04DF2RDniEQ7TlDUvHfsvRAbETcc8IvemE5RyM(cfra7K1jWx)EDkbsDRiVCeB2wkxSG62k0Kp1MdvnusIW8YCf5pvKsLslRFQX55MocrL6PgHVKi3PSRP(PyfLRmPppQZDqJkCujllsvxtzHzGyJTa(gNSOeNUE(cgO8CzJDYwTgASrpS0s3xbDrsD1gpc7WPJDm49Ut4S5JI6OlUt492tuDC5KCdC3VlBHN3lrGjlv5Cblb42csNN8Qik6ZtfN2uwQZ2bpT62hfRI7ycCelm41er8Cr9gYI)GROTnKdxOQOMMIMWkxbfLfGTCHgsPmSwwMxb1QHAm07zbeBixIOINn6WXtni1Ue2gISoVEvffdHm2To)IurGje10newYUpkkjQkqeBFb7oNaRjDO62JnCKrYKlD0HJe7yrgCWK5sogcTBroTbFxOvjnLnqGgbcmFrLQQK3SarfrC4rgYsIh5AOWKR(c4c1AWolrGWlRUTwY)SbaWJJkss0xUkjo20jMyWyAIYef68clqNkKXzHKPYMCW4lPOjIum6eFHyek94jZg3cPoNns9o7rJ2m(scN9qqsgyiIsh4yBagUHcgyebivEiTaKHboovhbWUA1cqwgihvxqdbVNZMHtvzwEnyI90pr4BVpKLSx68ouaRzSLcaxO44hPPaE4uDvY(8OKD7oVxVDwWo8UyGjVWEDos27EbolZfkafHsapu(XHkV0ndc40reMcXTtdsdzrVSgLUCbvbzqLrD)xmPk0U2Helyw40GgOdgqnSFNlV6BBTBQvzWVgu)UHZWO(lV21E1YOHh7tCLBYYV(QfCbVBb49GGnQPlZtKRa)g5HNGky4j3h8(GZAj3aEkArV)wsm(sT48zZqjpiN(c0XnzLHPnM(LjsqA(S8Du(b8H6MSc43ua(TqXcW)oyHEGNb(WWhHbE28W)Eb4JszLHpg8CW)bg4J)QcWNGY7LWM3Zc95VjgeTy75)eWNKYM5zQ5InLKK3SSJb)2cWIWVd8PH)JWl0K5b(pjC2(xQkYZjLuFuQCq0ovFCQIce2ilgin6ZjMZT1wgh3rJuBmF)aDB(EovBZIpPIs18ih55SEhLfL4twcUVfT(PkhkP((SgFtQJWP6miBQJFJJj0i0h7rV0OUTSTFED(txJxUiVlhcaqRYF7rtHUcbBHL(kG74T26Dvt)44cwRFRDggnUsZGAT5fUYbUi1kYDBVaFgg4b3mfVsOVhXU06oMVAZ9d3k88pkfqC4LQD8ePg5yNgDr1pruM6wP1BqrDItRjr)NfOc0CmMnoJZoRoZk835KQ70XEaiOXZz4obQXfvHTYYD6zK9UfSApJSFWk9mYU429mAWBG8m6MxTNrhZ70cJkQn0zYj1jpJCJtUBMYdth2VsdEfQ0ddRv0Ig5x06wcJiA5dzvcNeNVvDOCOl0S(7jShCkJg32OGjjoDWzOOTN3XHXxW3cnDzR20XSIg1OAsPRoRyD5orlRSS9MGe8ADbLreoazHhLnHcc2IMT1eecXZ4dTEGm)68szzyxfiwjGJFYVXh)3Si1xRm1K05NVXon0RxAtw16S62kjQxuJ3GFYM(Q1gT)B3qUUfDWMS81jISY5AXw(kkquQF4LYn0X1hD6ssJ0)muAgXOGh7NuWYBebi2tIYowISkJMvs2iQ8uZcjMrkyjsrZ(b497dU98rryBP8xm5mZWQIwZwpVp1zWEcv(zuVkNCEFg8YibEwufy9YIZWJ22sVpp4jp88)KRuRxU52TEzOMgxaVmAYsiQ)IVdBZkSiVbPKxhgRGvMLRcobHjC50GLHivCaQ9D(SUEzBHZswqtQVZxCVxPg5CU92eg30ch1hyvwr0cR3btiCAqu9g2dP(wxJoPPvlwgnrxGcBz6udBMCAhuh8kRvF1MXtuRGqZMGh7LFT1Sgc4f(BZd)VSXQW3ZgLcF)loefoFE4hKh(H5HFuE4hNh(7OOqQ1pVqt94)vOaeugkKNixLknb(RDi946GnoFJw24qPl4L(TSW5LTTWzG9pHYGXgqIlM0f3cNRnSwh4Yb4dpAxG74QANSI3v7wX)QdrbHkmRahcZGqmeCv)(iOSFve)UUX65vAh43QtyIRdyNVj8iVQyBwdxiqTJ3xQiAQJfE9fw53Tl()bF2lfp(E13tdbw)ERY5n4Z1WXm43h90Q66eSYl6ad85Pyfea8FM6GLfmqD7enXAOX6IA8uFXYr9Y6p46OJw)5iq65PaPQ2aPrNnP(iNiEQJxk2A4wfSe1zk4l4Wvk4lE55e13AnNl)HepNGVewR)R4FFzIVrW)TRqpIG)7UCaJjUcb)r4Y0Fm6de8Nq88b(tzG)hxTE6aFL28X5Va(QmW5C6tJ3PNE)XYn3ubQxIYz91S9Hb(ZyGxC1(R4iMLXu00Qrdi4fCuynnDE1EBvqYQvvKqR(uVVwLnQSUbzd)DhPCzjrAieD6ftwrvbfz3dlwM3YvfgCH62OEQSfM13EQC(wZIbvYPVA3wgOwCXe18oDPti2j3wU)fflQiBfiL79MGB9dSrBC8YfvuKkPmRC2zfr(XZ14NKGrkeL0O8wt7xWAA)(95nKVOb95JEP)OHc6pmRxVbd5LE1hRVa971lRVq(8gud7N0YsOHX24)vSqPD0iSJKy0HDUCf(rUW088Qri7bSblXJbbk857kap8bo7DrLIUN9Q2jXOmRyFZiHFyvw(DUKPsfNDYOPZLl9i2ADNlp6MZc61SdS9Yw)BsfRTq1o(R2X0GgBf7sAS))2rMCsECndEGg)I41Hl4Xo(Lg)7wGFbbWD4L8uyeT(Mqp2aCCi68Nb)pPZJONrrPk1QP5BqHY3K57FsD7nkKS1SdkQtycq)AiI6oUn0JGN2LLlC2qVvuYowvji6hfk6KbGa4qqfYJKZ1zVF4NtGsVutnR))Yd))fGFr7aMp1D7BGWEI61Jx)iIXBieMeYRx6vF0R9tblH9f0t)S97zaVyD9pGhYJ8rRMpFKk4drzHcheBsOb6peTKb8fYJFeagim5Ya0oZ6jbJI36NwWaMm3Yfd)zYCRTd9mz201w0MjZT5eJzY0JjZMzmz2cT)mzU98Mm3b8aMm35vasjL(ONy2a1vuNnPdKIjZ2O4etMEBHq(NnzURRtWbM1en8C(63FyKUfcbed4pQVb8tLBema9Ai61WeziEgGclcCft(o0RSCfjLztOzT)G1T8(WkqLKhCo0EKJizhY08ZtkIMalzeNJxArYphMMvf7yjY9nc14cvA0e0dtRDRL6doTsnI4xuYpeOvnlnngOJKCcIfNwMxx3f9jdlI3Vn6lkQv(0SEhVLlrXcZixwCMGt1n82)YRH4TD30C7ZZpNQO1gqLtSkpmHpVhmGtRVZdNKKbjh07bjlZTJtpXAItpekkYRNW4v)E8tVE1Genzc0a(zYe0KjesgcBYGYMo0omz(vqc0dr3IMqw(fJRPhgl7DiyY8oX7Fy8ViBZKj6RhiKzqecDFlPjo10YufpwiMNAv4MfBvPnv7JVs8t4QtLl(WSXhwFIUHF(xVUGFmzgeMWKj(kGmMmjAhQ8FznHktXsuEHcWcho0aKRH9qVsnckOFQonV3qPfIqZnzg6ItNnzo2MoYjwj91GxuEWzJ5jW016g99)71b9rEIwbnaDpJMb2WZ5mihzP5oI7CAKa(40JcsolrJrIJYi(k4ohNABUrOutsxGZWGxt9n1EXy9LN29ijZMnzQJ48Hj4LChrRQIwZhE)oSONVQISyr3z5kQjwwSiFZk5yKelM70PCps82Ixte2JepN7KJmYOPItDPbjeB(RsXQwoXWQRYvK)2VA9Izj043AvLZs6mA2KfOGLf0SCsIvKHGAOJxKeAK6ZAmNUJQzLWIOR(eFTENUMhjk29d130ha2Y5kvxMRQyr6oZJ(GfvxrZa8SqfnrR0rAZZtULOEEpSdYkjwv0yZKD2FyYDcNhDsbF9Ygj4kAOOvGnYGjhnBbnUsI10FITGEFTaNwrlT5iI2gd6msyrK41m0xSCnjPyIAfrt6B4Df6ho6h1TkDv4ahctTWKejGhFkTteVA4i17I5snipeZD979sYrZReTo)0neZwxt(1j6A6QCNeF(vk3PSOVJFYzoDfHHKGnzYOSgcEmzgDfsEWXf83a9RrYo201mOr4AjDjXs8fummuQcFhFyFqjMDqM0z36c0evLanxwNee0kcguB(GDvOynDSdkqRqDYqXpGdgdRcMZQGVtVEHCm08KIwC(ERx626DoMfObzJ0TZ3OBjV8LX7L1jB7b5rQBRXZY1OyCKzfjYgfKN230El)vNf8nHK97FG(d(AgK0YU6anY)YB0GNND2vcpvNiZiYdEK6Ni2X6o8CSodprydfzAYud(oMmZCXXJMmZAYmhz2u3K5mTqDMm)QorCMm)AnGAMmpMjZVoPRmzE3MmVhSZmzECCYmFxbmVn4NZ0r8czlH)Xn2bu1D0wcd1iY29(qWNzp97XEdJVpAY11wQf1ydKBTRPo3S4w74847jONMPQcwl79C(dMxDBo6sRKTmV6oBp5lBoAEhDb8EGlzR473oQJxuS7LcyRCtpZwKMeL0mmo)A6Lg5BnGMWiO(q1d0knoj)w)u0pBHjTm(zYO10KfLRKfDFs0WcMgByFQ8fLsevl1fbMk0cMo(BCGPTWr)L5DeO0xEpdqsjdyzsm3xv4sp72yrjSfNokjxQTGzv4L51elMvqz20Y5xUTFUKo9FS8CLQttbnQFsP4QYVjJfHDXs)PDgQURy2BLN7gPgQ79tPD9P2lnZgQiROXtsqu0Ki(8lJAUKY2O7wYHTPl30RnYtOH(Lm(TyLwWwjrXPZRExK75jFAloR(vlNavmE)2BpYvdNWZ2wCW7WMvqJAovWmLHGifgxvBYwyY8(v3BN5gIOvKtM3(FE8AXiOhoAQQhDSXZ1xYUZimXBmyeC4o7Uz9fWNVWlJ2SxuGx3caVSfaEerDscBFLO7)Ya04TB6(VuqnpzdL1wcjFclKXtLFvkShkx7qL1wW5r4qfhAw)q3cVm7WJDYkIOhBff6oE5eVHdVCawFH9gki5AyKw(8MmFY3qHpK3A74J9TM4d0pFIB(10SLLmCXSI1NDeVZuP7yJt(ghLQ2yJtY6nCOWKnflejIo4vV0R(y7pqipE7oAXHyjtMpXnoORxOZ6PiaUZlRy4yZur5pw61BV4M6YEkkimzPlhHuz0RxuaT9OiABqvlGyFYZ4N33jQOi1x3bIpYnuaX12R1zOM3zdxAy)ZtRU1yAkZwYDSMFt1em01epx9UEZZ1ty7mrZ0k8I4dX(GFqEwYx(nx(woVgk2u1o54tl6B6z7UZRNQjU5eRJXnpxRCA1(tQN(vrpr0S5gnvBznB70t4KxOvSKC8jGsdKWsWeltA)KJep2rJKkzS1SJmz(IT32OjIhHDvzSBJWb1HgSmPbD(L1LwQflDQeJMn(QAJFhF8RDCmYMoDUv1Q(PVUo)MYMC44PIfF1lfHPVfFDCILjsSKjoXvstv3A2yhnD6HNmj5JvND0m56sZVC22RP8f0VVOE94ZJp)deoAGaH6N1Fa)9hMTFV(85)IeBNRb7qRRVWnucs(PU(kTKEivksrFh90fo64NO7spE0BiKE0m6sMm5w8OPztEY0PYfzyydNrD3ncOqSbjXuOQQKy562jU2BQTNrIg0GkvfLPXUw9EA7HOoPYsCviF1dTI1d9jwQ3luttUJpOCnT6R4bdYJ(RG9OO0kgbhvzwj3kLDNJN8LT2m0rpWn7i2rMmVRB7QnWrMmtAfViaH3CKlfwDiImziUorJoKjtPwXfYKHhUJnAYugWv7kB2KrypSdAYiI3nLGjZ0MmsMmvPr4XKr2rODUlNjtO1UPOBYOUYO6WCnjOoj1KgEWJZnQUolXO41quYzr22pOjZhYK53eXy)wN3YP6gJqYYPjZcB6iQei8ZyTDqMmFytMpcw7ND52auMmF0vSJoMmFmSAp3L4g3yLDbHSZWahMW4YABlTfire2eE5c1mmuKtB9njFjBgCKl1ajR2Y2wYEDAFC0K3oPtc2V6XthoZ06QeriV0Akc5pdfHiqfHe51SWkFzrInz(RAqwtU9oswpF7YcUEsxnzGR5etCw6WrLx2MigSYmfZ6FSX6tJR7eXxCDmrmXb6irCjhYSVrNcItXoqbL6pUp)YIs(9vP7uWV(6yky8VDhPGl2s36n6eqCg2bc4yvgVEPidnBMbhS7eWVX6yc4mhBTiGeBGUrNaIZWoqa77it1VAG(psWI17ob8BUoMaU73BNjGTSv9gDciod7abSU)tpCHOd6pPCFDNa(NVoMaUdPoBjt7(uSoMi2CV)B6jBNPJ4eTXgJzY8hKVDYzvJHQ7xpeF6mP6o58V46a5K4rA0btpEkIVOop(h0eLNM3Wn5roZ6WXfLOKldbE3ju005MMx2QsoYWW4Y8vR3OlCMoIj450CNUwBhFe0nH29WKFKoLZHaTYJtoRjhnJZV0lRENCQs0XKxeDa92VM5aQVCPZSMUGM)APlOl744dCMmDW3ZsxBYOWeJxiKsWbJgy8cx8iY8LVLnqomCMx0GVknPdM59rwZiC2WtREpDiHdsI1SpRCPXM3hxFphn9dS7J8WUIsUVvGA(sMm)9BAMpqRE2K5FyLDHjZ)78eg0)pROzpZp5kRzV6vuZs(PVYA2N9YQzW(9XjxFvs5Ydp8UVuesDjVvBK4b13kJhuYuJn5q8ZYlPvFsBU3mJLzYg54qswUbNk6SbguNUT(V6Ak867DDq419FfQl6n)WDuxekKPds3U8vjDPsSEsBIvBbtEOvhmzC42(oKosQPMBcD5Wzodx3jeF)RpgfCXd5pjxPEAn7Jq3DZ6N8n4rx6)o(86Zd541ZsfqmoDd3zRvSip5CYdUxu75snZgPKLYVMFl0RWKGRrml41D2sj(LbhJplcvPO(goR)kdYMzQUtOo)R7CmVYIKnxmMKImVEElfMF2ObcfM8v76TFYLard4pSFs(L7lC0G0O0J3gGEni9ROeRw)bcVKkVg50kICC(npx5Y8fn4lz95SGRNNNKyIIY8zSQu(xB(4OwFLM6xcsM34l0IfNTIUqSQdp6qvNP7iNFWR7FOMi94NNVzQG53xGbm3Wgn3WT0KKBUHB91iYC7HO7gxkEUHe6BC(0tZNDKUtX)HVUtXFrhuCKL3Fqlc(ArSV6t2M1iUMDLIK8YMIest3ZCJNOqajHUtr(rnPijFTZzTf1v50MM(1nTdk1HoSSptgOpR5jfR62A73ebXiG)xi0sNSJtEfKMTYJEf4N64ywPbrJEEq44CA2oiDZxGZ(05VtNiLFxHZrhkwFNZNaDJAODc7AjY5Al2UjX)Szoz3l5WX)kM)CrRdPHHJNihuFhw8PR5jOZA1RTDg6SKvpZM8ihnxZttNDyDA6mdf3140FW6qC2hoNwdK4UUerINNUSfTX5bm8kW7wWcbeRffW68gHCM2OzVI6C1EIR8OvUaLwRlwIN1AI7awISamlrFnhLEWtFy4BZgtINtgrPwV(ghm07VLfte77eLReLt7uJM8bB9RhmlfOsBMJ8j7hte9q4N(hTpBygpDDpAdfy)t550ixI9RxSujEz2uXhlol8Pnz(Ao)sDHpZQo1Exz6CSHTryT(40d4yskP0B1El1BPZ(MB)CMbcb)mtgftMxIWUzFiWqpQk3068JQYBB1N5lgHlLny6(8mA2J2HZ8LE1z7)GboONEN5MFS)T
```
