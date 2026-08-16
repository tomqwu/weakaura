# Warlock — All Specs HUD (v10)

Import `all-specs.txt` whole (copy all → `/wa` → Import → paste). One pack for
Affliction, Demonology, and Destruction: every spec-specific piece loads through
a `spellknown` gate, so the HUD auto-adapts on respec with no user action. All
triggers match by exact spell ID — aura triggers carry every rank, cooldown
triggers use the numeric rank-1 ID — never by name, so the pack is safe on zhCN
and every other client. There is zero custom code, so the import dialog shows no
code-review panel. Since v9 the layout is **three glass globes**, and since v10
they **flank your character** instead of sitting in a band underneath it: your
life to the left at `x = -270`, your mana to the right at `x = +270`, your
target's health above and between them at `(0, 110)`, with the DoT row and
cooldown row below, the alert column on the left and — in arena or a battleground
only — the PvP column on the right. Drag whole groups in `/wa` to taste. Note:
the `/wa` editor preview force-shows everything with fake data (all load gates
ignored, so the PvP column and both curse states and all three specs' icons
appear at once, placeholder durations, no animations) — judge the HUD in combat,
not in the preview.

Upgrading from any earlier version: paste the new string and the import dialog
offers **Update** (the UIDs are unchanged), which upgrades the group in place
instead of duplicating it. That is true of v10 and v9 as well, including the
auras that used to be the ring orbs and the two portraits — see "nothing to
delete" below.

## v10 — the globes stand beside you, and the glass catches light

Two changes, no new auras, nothing removed.

**1. They moved out from under the HUD and up beside your character.** v9 parked
all three vessels on one band at `y = -262`, which read as a *separate bar bolted
under the HUD* rather than as part of you. They now flank the character:

```
                        ,---.
                       ( 41% )        target      (0, 110)
                        `---'
       ,-----.                            ,-----.
      ( 83%   )                          ( 62%   )
       `-----'                            `-----'
      LIFE  (-270, 40)                MANA  (+270, 40)
```

Your life and mana keep a shared line, because "can I Life Tap?" is still one
glance at two objects. The target's vessel sits above and between them, where
your eye already goes for a nameplate. **Sizes did not change** — 72 px for
yours, 44 px for the target's, each rim 4 px wider.

Those x coordinates are a repo-wide contract rather than a taste call: `∓170`
collides with the Alerts column at `x = -150` and the PvP column at `x = +150`,
and `±210` collides with the PvP layer's elements at `(200, -44)`. `±270` is the
one width that clears both in every class pack. It also ends v9's honest note
about the target globe landing on top of the DoT row — the DoT icons are at
`y = -156` and the target vessel is now at `y = +110`, so they no longer share
screen space.

**2. Each vessel now catches the light.** A flat disc of colour reads as a
sticker; real glass has a bright spot where it faces the light. Every globe gets
a soft, off-centre highlight in its upper left — sized as a fraction of that
globe, so the small target vessel gets the same look and not the same pixels —
and the liquid inside starts reading as liquid *in something*.

The highlight is drawn in **ADD** blend, which is the deliberate part: the
percentage lives inside the glass, overlays draw on top of it, and a normal
overlay would dim the number. ADD only ever brightens, so the number stays as
readable as it was. That is also why this is a highlight and not the more obvious
dark rim shadow — a dark overlay in that position would have cost you the text.

**Nothing else changed.** No aura was added, removed, renamed or reordered; every
trigger, load gate, condition, colour and spell ID is untouched; the alerts, the
DoT row, the cooldown row, the procs and the whole PvP layer are exactly as they
were. All 44 UIDs are byte-for-byte identical to v9, so the import dialog offers
**Update** and leaves nothing orphaned. Let the Update dialog's **Arrangement**
checkbox through, or the globes will keep their v9 coordinates and you will not
see the move at all.

## v9 — Diablo globes

**The rings are gone. Your health and your mana are now two glass vessels that
fill from the bottom like liquid**, one on each side of the character, with your
target's health as a smaller vessel between them.

```
      ,-----.                                       ,-----.
     ( 83%   )              ( 41% )                ( 62%   )
      `-----'                `---'                  `-----'
      LIFE                   TARGET                  MANA
    x = -150                  x = 0                 x = +150
```

(v10 moved all three — see above. The rest of this section describes what v9
changed, and every word of it still holds.)

A ring told you a value by how far an arc had swept round a hoop. A globe tells
you the same thing the way a glass of water does: the liquid has a **level**, and
you read it without decoding anything. That is the whole reason for the change —
under pressure you glance at a level, you do not measure an arc.

| Globe | Where | What it does |
|---|---|---|
| **Life** | left, 72 px | your health, deep red, **amber at or below 60%** — the health half of the Life Tap decision |
| **Mana** | right, 72 px | your mana, blue, **violet below 30%** — the mana half of the same decision |
| **Target** | centre, 44 px | your target's health, smaller so it reads as secondary; **disappears entirely when you have no target** |

Both of your globes carry a real decision, and neither is decoration: **Life Tap
trades the left globe for the right one.** "Can I tap?" is now literally "is the
red one high and the blue one low" — two objects, one glance, no numbers needed
(though the numbers are there).

The unfilled part of each globe is a near-black disc rather than nothing, which
is what makes it read as a *container* being filled instead of a shape appearing
out of the void, and a brass rim is drawn over each one so the liquid looks like
it is inside the glass.

### The percentages moved inside the glass

They used to sit *under* the orbs, on a shared baseline, where they competed with
the world behind them. They are now **in the middle of each globe**, where your
eye already is: 13 pt on your two, 10 pt on the target's.

That is possible only because **the portraits are gone**. A WeakAuras `model`
region — which is what a live 3D portrait is — cannot carry a text sub-region at
all, so as long as a face occupied the middle of each orb the numbers had nowhere
to go but outside. Diablo has no portrait either. **The trade is real and it is
the one thing this version takes away: no live face for you or your target**, so
an accidental target swap now shows up as a changing health level and name rather
than a changing face.

### Threat became the target globe's rim

Threat is not a pool, so it has no natural vessel — and inventing a fourth globe
for it would have cost real screen space for something you only look at when it
is going wrong. Instead **it colours the glass around the target globe**:

| Rim colour | Meaning |
|---|---|
| **Green** | you are on the threat table and fine |
| **Orange** | 70%+ — the tank is in sight |
| **Red** | you have aggro |

with the threat percentage sitting just above the globe, and the pulsing red halo
at 80%+ exactly where it always was. Nothing about threat's behaviour changed:
still party/raid only, still **never inside an arena**, still hidden entirely at
zero threat (a rim that read "full aggro" the instant before your first cast
landed would be worse than no rim at all), still dimmed out of combat. When
threat does not load — solo, or in an arena — the target globe wears a plain
brass rim like the other two, so it never looks broken.

### Nothing to delete after updating

Every aura the orbs were made of is **recycled in place**, not replaced: the two
player rings became the life and mana globes, the threat ring became the threat
rim, the flash stayed a flash, and the two portraits and the target's two rings
became the three rims and the target globe. They keep their UIDs, so the import
dialog offers **Update**, rewrites them where they stand, and leaves **no
orphaned portraits or rings behind**. All 44 UIDs are byte-for-byte identical to
v8 and no aura was added or removed.

As always, the Update dialog's **Arrangement** checkbox carries the new sizes and
positions. If you have dragged groups in game and untick it, you will keep the v8
coordinates and get globe *shapes* at ring *positions*, which is the one case
where this update looks wrong — let Arrangement through and re-drag afterwards.

### Honest notes, including what is worse

- **No portraits.** Named above, because it is the real cost of putting the
  numbers where they belong.
- **The target's mana is gone.** v7 and v8 drew a third ring for it. The globe
  layout ships one target vessel and it reads health, so the "is this target
  worth Curse of Tongues / a felhunter" read is no longer on the PvE HUD. In
  arena it is still there and better — the per-opponent **Enemy Mana** bars in
  the PvP column give you a number per enemy instead of one ring for your current
  target.
- **The globes sit at fixed screen coordinates** — `x = ∓150` and `x = 0`, all
  three on the line `y = -262` — which is the same geometry every class pack in
  this repo used at v9, so a warlock and a mage sitting next to each other have
  their globes in exactly the same places. **(v10 moved them to `∓190` at
  `y = 40`, with the target at `(0, 110)` — same cross-pack contract, new
  numbers.)**
- **The target globe lands on the DoT row.** It is centred at `y = -262` and the
  DoT icons at `y = -156`, so the 44 px vessel sits on top of your Immolate /
  Corruption timers. That is a consequence of the shared cross-pack geometry, not
  of anything warlock-specific — every pack in the repo puts its centre row in
  the same place — so it will be fixed the same way everywhere. **(Fixed in v10:
  the target vessel is at `y = +110` and the DoT row is untouched at `y = -156`,
  so they no longer overlap.)**
- **A globe fills upward.** WeakAuras' orientation names lie about direction, and
  the opposite setting produces a globe that *drains from the top* as you take
  damage — which looks deliberate and is wrong. This one rises, like liquid.

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

**Resources** (three globes) — since v9 this group holds your **life globe**,
your **mana globe** and the **target globe**, all three filling bottom-to-top
like liquid in a vessel; since v10 they flank your character rather than sitting
in a band below it, with life at `(-270, 40)`, mana at `(+270, 40)` and the
target above and between them at `(0, 110)`. The two player globes are 72 px, the
target's is 44 px so it reads as secondary, and each wears a brass rim and a soft
specular highlight in its upper left that makes the disc read as curved glass;
the percentage sits inside the glass (13 pt on yours, 10 pt on the target's) and
stays readable under the highlight because the highlight is drawn in ADD blend,
which only brightens. These are the numbers every
class pack in this repo uses, so the globes land in the same places on every
character you play. Your life globe is deep red and flips **amber at or below
60%**; your mana globe is blue and flips **violet below 30%**. Those two colours
are the two halves of the Life Tap decision, which is why they are two objects
and not one — Life Tap literally trades the left globe for the right one. The
target globe's **rim carries your threat**: green, orange at 70%, red the moment
you pull, with the percentage just above it and a pulsing red halo at 80%+. The
threat rim loads only in a party or raid **and never inside an arena** (there is
no threat table there) and hides at zero threat, and the plain brass rim
underneath is what the target globe wears the rest of the time. Everything dims
to 50% opacity out of combat. The whole target globe hides itself when you have
no target. Both cluster groups are independently draggable in `/wa`
(`Warlock - Player Globes`, `Warlock - Target Globe`) if those coordinates do not
suit your resolution.

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
The threat rim, its flash halo and the Soulshatter prompt additionally require
a party or raid — solo, pulling aggro is the plan — and since v5 the rim and its
flash also refuse to load in an arena. Life Tap and all three "MISSING" prompts
are combat-gated, so nothing nags you between pulls.

The PvP auras are gated on instance type instead of (or as well as) a talent, and
each one carries its own gate — a group's load is not a child gate:

| Element | Loads in |
|---|---|
| CC ON ME, TARGET IMMUNE, Trinket DOWN, Howl of Terror | arena **or** battleground |
| Will of the Forsaken DOWN | arena or battleground, if you know 7744 |
| Fear Out, Spell Lock ON, Fear Ward UP, Enemy Trinket, Enemy Mana | arena only |
| Threat rim, Threat Flash | everywhere **except** arena (and still party/raid only) |

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
so all 44 v7 UIDs are byte-for-byte identical. v9 touches no call site either,
and it is the strongest form of the v7 trick: **every one of the eleven orb auras
is recycled**, including the two portraits, whose UIDs now carry the life and
mana globe rims — a portrait that was simply deleted would be left stranded in
your WeakAuras with nothing to update it, so the region type changes underneath a
UID that never moves. v10 is the mildest of all of them: it moves two group
offsets and appends one sub-region to each of the three globes, so not one aura
and not one `W.uid()` call site is touched and all 44 v9 UIDs are identical.
(That sub-region is *appended*, never inserted, which is the rule this pack lives
by: conditions address sub-regions positionally as `sub.N`, so inserting one
ahead of a referenced index silently retargets that condition at the wrong
sub-region.) Removing a
`W.uid()` call site is not an option: it reshuffles every UID after it, and
`W.assertUidContinuity` fails the build if any previously shipped UID
disappears.) The
script checks UID
continuity against the previous `all-specs.txt` automatically before overwriting
it (expect `changed=0`). One more re-import caveat: the Update dialog's
**Arrangement** checkbox is checked by default and will reset any positions you
dragged in game back to the string's defaults — uncheck it, or report your
coordinates so they can be baked into the script.

## Import string (v10)

```
!WA:2!DZ3EuUXv99NXYM4i7a2RFKyNaiCID9AsmsZQxBioejTsE16DLKhPDxVoMSZiPrAMDhnZ4zgT7ktP9hlHGd1ajlTbiqk0f(LwE2dBPuAlp3qGduo98TBpnD4DXqPP5qBbtHZP)tP37DgjnAxTRw)io2XNJND0DU37CV3VF((6(97CPgPRcF4x7zF1lLNRWKf1uuJPiPOnGlxUY4Y7HdO2vbfzdnfjj(IXeeLkQXlFi1BzuonjLct65U9KrIRgVMNJkPKNxxD3nFqooTY8gwp485v0kYRf1(vOUTOsIN5mCAf9KtrrYquvBM0LkPZBqLxLd9gmA(gYfngQZIij5jRkFb98w9KGwnRgC6514llQiNRMkptznLQQZBvJSINHFtlikxsrRcNbQgUxW6bwZpkkkxlXv1qqrlTk(X6UZJMPLel7wJRaPGGm6gCAgUZxsuwuxWDu0FmCpRHMy5Y8A6PoGM9TpEud8BNRQgh9I4R6Q8ssIf13BxEJwf1O8QKfPzjLNSOU7ZRxnp)uO5z2QLkjoZcJhls2CJNnxeMCnEugnE0JyYMj(GdEHQ68XNbnUYA1dSmYCv41DpFr(8OEap516p(Gzsm8GZvv2Ey5EHII6tuvgnBMINMtssD7CK7Zz98HukY)jVb7LR4flZRU9SNUkA53tIQOL7rfen4x06PwR130CCYIwlMbHDMyrEoD(SgiYvzdHBe2tuzfz(LkIM)4AmoEnrtNhTOwuFwCvXJsWB0kCIYjGxhQbGxWhqd9G(7UwEjZPZlvkJIOSr(yXtLloZ(elQUJMOlgEDLQAf41VaQk8AYCsJGEBO37dSqjn0AdACXzW56cCYfqK4e4IWV)8zJXepEQ5nukmLv93CMDrxvS4chn4PnYRLGzKHpgJEbojExZJOemeWLEDStsz0YGR5XZjrlqtujfUIUxW61qgVqWZ(QbQgmqWggOnSl9ZZjziOURv8GH4K5uV1MfpOyjElEipmIvu3JJgOmDD(o8JGnbVm4gPGndHa3cWw(FGTc3m8Y3e8kCdBJa3HT7g6YnSdeTZnSl3WUDd3sQda36JJw33lCBiWkC7WReEvUHxn4bEnW(G7GfUt3W(Hda)oUHdcDdh6tEdWRfUl4UVj4WyiWYjJ(7mHfcabr0sWfe(bGEDb3d86H7freGJSqS0PRiMPKXOAPG3Gl4(DdrCbrDdXCd9HwvVN8iUaTXRrz93zOGB8NVTf4korvDd(IdXnZgA(dr5naBHc3m1DwKxNZaJk5XYFWYiKlkSGogrWpd6b8SoRtcfKafR6WOlXjBqnlVCXiYLL4FODJgZNxvtPSgVUEwc(7q3(nSb8ucTU7cV6UD3ZQPyq4aOy4Kuf4qtH75amfe4lmzc4wDn7uCAIC5L4xcXEuaXNlqGcmtXjvLFFb9Upf19DVhrRGaNCzE99EaySbYSrVhU3ae0e(wFbCnlAqGAUrTluQXWLix7aWiOxYMGrNvuoMsL8CgWyu4U8ihbojUZSWKpamSvnDbJoxfUzSgdWyDz)6TQlfUEW9FOZUB1UmqlvJRlWvuz6tylQEosz4lQBB)Tmz2)(v3MJg0uI75TkToRD0idNlT6oifIKfRGLTuyuXIgcrJG(5fipajeKViPW3YswSzJzpawK8CmfxSuni48KfEcrnAQ0PId7rdXbJRZ8KkwOUInxwJ8sifBQBlHM4z8C8QCfXYl8KlNQ3gtRXT0DmElZTXlYxajeuACvn0nyjiuTS6uFWTePSPrIngvJtD2rTVzPgVAIq70dNBWKPIBVC1Iue1U7WaHq1jIzzkjPOOzTCmfAmHqxSnFrynH3M9sxDAN6(7qNBvy(uvRKNx7S7G0BiwLHe10u0eGB8eBYh9HP9NVIDbBjZM8f4W(ONhtChx1AkCb7wXuNJ482fmI9G0wU54vqQIySA0EM3MOHQM62TVPVgSNc17cBEx1xFsS8)sCf4pvKIftlRFQr55Mmcwl8PgIVOi3PSRP(PIjQvqIF8SvuumeoSrzoMPXWQ(V)7)DFQd(Rx8rx0URBAbeIBJomsw0I2Jt75vEbEXYcgz2eT)d7pCElCNWsoNT8cw0u0VJkHeGGv2shPV(GZ9yxYIoZxaX1pEn8OYVpNYXv3gsIyeBzFerHcQBpFdHD2laWzjcANNyvdrGgfeBK5qnD8csC66S5nqQ9Kn2ntLQiBYCZqk9a51fX1vB0imdMo2XG37UHNGnkYuMc7gEVUJQJqx4BGB5bT1LC7y9hmeByYBPNZwVYS4xf2EiwI2LgQwC2o4jv35WOQ4jMah2qmEnre7Db96QM(qlRTnul97lS8vbrzbyRxOU4ABIXSki9(ivT6UNlFD6ct0bJNQpILBnrQ6eusg7wZoprxqcrnDdHfS7JcsIQcyfy1X5ygCChQUZydgzOm5shDWiXogIQNmxYrqm5njj2SHxOzjwGomT1BahxdHVgoWSfuQOIhicyDNXHtrQziAsD616QlS60h5Xu3EtDcnP8hzHeDNRCIJnzIt0xmnrzS1p8cZrMv4HC(KPYMSV4lOOjIOBK1GzhjotUKXImOfUBgBC3RWTgPv8ffo79adqbhdPi(NUnyWnadvxPlKsasZczeGJtbme9Mq2vQQeYrbdt0pwxz0I2sHuXg3aJTVEWkK66ET0hznNjRl0bSuk6cPI6unu6bVXoQTBwK2o7oVlFTxzhmofWEH97CKS)9d5TSHQaue4Hsq53ciqbIOzZeWKiWReu55gaKbf40uQhC1eUs6mhcUHzanqhmGQWuOUQgR6DU2n1Qm4ndN52G3eL6RBTR9kvvD2Da)EnLEJyAAi4g()HgaVfkyww4TcpeAg92GhwaE7iOZJ0qaj8oArQi8hGAY5SLccVtb4DjaVB4rVCeXbp2kLUbZjaVhBHxWFiwMf8hXcporOZ77aW7hEclzsWhGu0hSP0OpxtPkmeZLXsrMJS2Gx9PArGYsyPtnEgBBLnbF41HCi4pbj3bMh(iUHpk8)hEkk4pLf(ZeGpgrwb8XHpb8jPGp1Znb8PjCZjS5M91dgU2JfdVnZm8Nt4D9oXmXMqsYxwMrGpJaSa8xaFw4Ve(CnyjH)kHZ(AW2dxNbSfR8FWLnl(JxTzXf9SfXxJ4ONVP5ZcyEAKL7N79JbeRlsfEbbTQTvnBPOKvTNwn6LOI9XJsCvdRFNiPP3nrqo4v6JYuOHu2GezNbiMv73fwm0J8(XIKoYcvpEIudDStJ8z3psmL62rErxqJ3GF8gg2FPdVJEOlgHvWd2EtYr0BesctW)PRob3b4h(sec5xUvap8vyV8i7WIxguB4PTOZWxB5uP(HN55(Ioji(MCYdgl3mteOwrSEJVXvV1))62RLWE9FnCZ3EZVSDZFNR4byF53MJsf045mAz3ZiL4jbYemHL7A)DU1RX9TFJR03(J5BsHHf1g4m5KARV91nKG6IYoIn2QDexryUAycaWT(v6RsH073IU8Pr62RXcNzxi90WVl8MRR5DJHWkljkE3yVyDWRLEx)hr9J8p7((wf9U(8F4Ed6uV7yxJO3Dz6Aq(vGb9xru4CXRE9BcN65MKOnDmBTP5du94DNkIM6iHxtTPuRBLP)9xbvM6qQk3LNu1n6uQ63QHuvolPQdpDs9HglEQJxm2vzPQDuR2QVW)u1xqN3GiGe7QiA1)oDFES1BnlJfVqJPlpP62SfLMv0Okr9nz1)kcjAV2skwC)wVz1cgn8uq9UwHT5nQuBmmVfzmI1LXO(AwJoPHVaebrdq0df2YOgx2EI4uIuB2YNM9vlUKCMBblZcj8Yga(Wia4c41xrzsewyjoYJD8xWcxQz)a09haUz2OACIfzxnW6umQCitSzPvNc1tOrIrTkCYS0g8YSZBmnY5LALeNINnV19SGx21b8(VdEMbSDmKSmGTK2Lt4EVh8ek9fRxjUysx2W9bAU5PnwcroRgIaQVpBqTfbji(IpSBQptJgXWvgTCbJ5YjFYa4ks8K3hT1vhnA9XyTG1GHStYRjlMhYQhErLyKWZwNfyPMmrOzel8pqyTGLyHFY(c7fXyO2vtidEdO5mu0WtycNg8p6GZQbhd6v(mwlf(SUqCVbttW6aPi00UWIYFuS5aTNMuc2tE8UFG0HG)n6Xp38K9wptvjD(zRhYPU8rAYkjyiITtjjy4drPMLvk2gT8TXYDqaglE7JSqUboU(WtwuAOEMIOyblp6C1AWqaMSW3Xg)dFxBKp89wDyp89zHFal8dzHFel8VWc)ycY(rQTmZipPtRfJPOPvLeEYl4OWQA68QD1SGKvQOiH89s9v2SSHL1nWrzWtKsLKejb00z0MYkQkOitIUutRlVjI1LBL6ABRlpFZzrFk50xPPM9wnUyIQ(MS4yITZuZ7yEXckYwrV52Vb4gp3MS12SubffPIktlNDArvE2fR)tCOrfIIBeR10(PSM2VdAFHOJgKMMCPNOHc6pmJpFbd5JCLMHoqp(8XqhI2xqnu)KwwcjnZ2yHLTqP1FeMHsm8GTQR5ctYZRgbVvRgmyeUqDLpiBu3brZZ(2V66WivsqpwHkHftMkvCMXJMoxU0dbN5vAj0hXRnNEv7WSVK1FgxXoGl2)SqZa6yxs9OoyhN0X5rRzWDv)xyvfUGZD81NTmBf(nwIS9MFiTUpHESE5WEY)lXYrq)l6zuuQqKVpBDkeBd1a)C1DwVq8Ud0NOoMjaPmcB)3XTHEy80ESKJyd9wwj7AfLGq)ilfDYaGbCiqfIhzyxN9oGFfgk9TB43Y)nl8RfGFtRaMp8Tq3ByVr951NFeIXxiemjKpFKR0KR9qalHPd6ThME82RpuD93Rx8JOjvJMgxbAeklu4GOMeQ3EcrkPx6qE9JaGbcJV0lPZSEsWOOB9tkOx43UAWptQBOvKNjf1vwWMj1gCcXmPCzsTrktQnr6ptQxgRj1nc3Lj1MVeakP0hESPdutrD6KoakMuUjWetQT0eG8FysT1RsObQ1em8e094pmISfcHh61Fu6E9teBema5AiY1WyriE7LGkcCPs9UNNDPYsktNqJ)0v5LluZYkjRGJIFWIiL(hvYokTSZIlIKmnzeNHxAE8phKKHh7Ab891dV5CLR3KbioM6pGLHoKkvpkJrX)qGu1SKuQGmsYjiwyszEDDxKNmOi6(TtErw7CNW16WTCjkKFkzKrQbNOtWT)ZxaHB7THHFNNFgvrlBGYjwbz7hTVdhWP1FSWdGdR6H9Dy8YCRW0Xwty69Gee5ZBy0v)E9tUEzaenPoCD0Nj1RZKYlIk4ZKI2KQNDzs5hrFcqmdoKL57OL0GOYcjysfgDFVO)FpB3K61)IbazkeaH4JjjhUMuMO1XcW8bwbSz(MvAZv)Glh(eUYe5Ipit8b1prNGp)xxvGpMuhbgZK6(wgIXK6n0ks5ZSMiLjyWAUqIVchouV4RH9sUsSakOFIcnFxpPcctYnPIT6KztQ(28rhB5KxdEr5(MoM3atwTtK3FXvbLrEJI81C69nCgydpHZDOoljBv8KtJtUqlEtGtsk8Uo7SmswOLJtTfxiuqoFjWzyWRPEBTwmQ(Yt6zOKzZMm1rD(We8sEIOvrrRXdVdhwZZxrrwSGNSCf0eljwGVrLCmsIfZt6uEgkElB2EeMJgpNNKdn0WPItCNbri2YxLavTCGHrxLRa)nF56bZcidFRwrolUZi5VwG8wwpZWjjwwgcQHC6cNALKTVd5Vrth70SsDsEwIFwVbxZIik29dYPlSNrBDXI1K5QiwGSvki)VIQROzaENRSMOv(pTLzX3IvoVpM(yKeRiASf8wXmi(oHZJCqb96LnsWva5wEEMi9LC4S514kkwv)H2kYZR540kyPl)H2DDmOZOqerIxZqF(svLKSIOgBDpRqoeJ8H6gLUmCEdbtTWKybGhFcTXIxjCKADWwP6KhSPU(9TUCY8srPZVydJzRQH9AevnDuUtIp9YL7usK(4NCQtxwyajyZMOLGvxWJjvQLj5bnUGNd6rdNNUPRAq2ILf0LelYNxXWqPc880O(GqmBJmPZUT5iPmlgAUKUHgho7Oiw8b7jFHQ6OoipPc1irBfqdg7cMXQGNVlFWWuKurIumBx1kEtDnd1CKD5b3TZwVBXV8Lq3lRJ3Yd8Ju3E9NLREXOrM1EzvVawsFt6n2lpZ3Baj7XFV9e8fmiPLv1bQNWNxVbpp70lhEQEImdj33rRnwSJ1z4z62dprWgcY0KsgEEtkLvhpAsPAsDA8SrZKsVjQZKYWjIZKQADOMjfALyACxzsnJjvnuNzsDg0K5n1raZDc)kQ2IxWrS4NvFZvv3vl5Mt9TpTR7f(87RhV1dspjj2AjlEyxZ42)1Be(ItSVGEBKBhOAHAcU(Fiw1T7OlTsVtw1D3A6E2y0CFDa8EO1Tr89yhkIvf7UEaBLA4x28K8uKKsZSRPpA4V6b83BrsK(q1d1mjsW)w)uKpGIXTm(z8Ov1KfLlNf58KOHfmn2G0Q8fKsevl1QatfActZ8shyAtC0pR199Vx8((d)B4D5V1D4h1OZUDgKe2ctgfN82wWSY8Y8AIfYkOmDAz2LA5NlOt(ddpxXAKmXI4MukUk8B2yEypmKFANeO7jM9245PEky65GeAx3QDrcfvzzfnECIyImjINDjKMlPS17UfCyB6snCAd)esCbXJFlwP5Svsuysw1DGVNh)r24S6xUCceX49yV5ixoCcpElbzOnBvbjKeebZegcSuy0QAd2ctQ3Q6(Bp3qeTcCY82)XRplgb9WrtvP)rgnx3j7mJWXFPbJGdVz3ldDaA6WlHSzVGaVUfaEjla8qI64CI(sr3)fbOXxN09VEqnpCDL1wcjFClKXSSRqH9a5AfQS2copkhsXHM1p0TWltp4iNSSiYJTccDgVW8so8YHyOd7luq81W9As9EnPEFVKcFiVTwXhhynXhi)8XU5xvZwwYGfYkwB6H8nv5oJnY(shLQ2yJtY4lCOW49eleoAoOR(ixPz6jqiV(6mAXHyjtQh)6h01t1E9uya35LvmCSxQi5pw61BT4g6YMLactw8Irivg9Afeq2EuazBqflGy3Yt5NNESYksD3zGyURRaIRTxRtrmVZgUu3(NNuDBX0uMUONyn(eVXyORiEU67AnpxhZ2zIg5SXQ4dXbGFald(BqNJTPZRHInr1to6KI0toDNDED4g4MXUgg38entBi7VWFY3N9yrZMB4uTKysTspHh4cnJKKJV5usCe(eWylHB)4dfpw)rsLm2A2rMuFQwBB0eXJWSIKIQE0GAtdwc3G2)Y6ql1ILovIHZgFfTXVJV222ogzsNo3kAf5t3iu7Ftztoy8uXIVYLIWK3cDBNyzIelzIXUuAQ62YgR)0PhC8K4pBEMHZKRdn)IzBVMGoOF6O(8s7L2FVHJgiqOEy8hWFpHz6XhnT)vj2oxb2HwxFZRReK8lC9SnLEivmsb6(pD((hDSol9yKRlKE0i6sMudnF)PzsEY0PYfzqydNrDV1dOqS(WXuOIQKyPA2jT2T1YZWrdQpLkIYKix38upG8qKoPssCLXFtrnJ1d5jwQ3ZxvtUTpOuvTAl7b9XJ8xb1JIslBe0VY0sEuk5jhp(RyUrOJURn6i2rMuJEtxUboYK6eUSZDytQtIV8aRmerMuNsWo6qMuVXMXfYK6bHx(MmPghqR2SBXKIBFm9zsLhDxbbtkeMH3KQejcpMuLDeAND4mrcT2nfDtkXLhvhQRib1jPM0G9DCUH11zWgfVgIsolIT9HnPE7MuNfHXEKZB5uD9riE50K6pyZhvfdHpN12bzs9onPExOA)UxQfaLj1JTSD0XKAou1EpRZnUXk5c8ANGbomHXL12wAlqclSX3s5RAyOiN26B)DDBgCK1BGKvBABlEVoTpyCyTt5KG9OE80HZmPUkweYZSMIq(siricerirEblSYxuKytQVrDYAYD2wY65BvwWvt6Qj138koXenlD4OY3YMigS8ufY6FKr6wJRZeXV81WeXehQTeXfCiZ(6DkiAk2gkOupXP9llk5NUCNPGFLRHPGX)NAlfC(M6wVENaIMHTHaos5rRvmYatNPV(6mb8REnmbCQJTweqSnqxVtarZW2qa7(Ot0JAGEoAWc16mbCXRHjG79T1EcytBvVENaIMHTHawZ)PhmF0(8NuU7otaF6RHjG7sQ9wY0QpfxdteBS3)n8KT90r0eT(gJzs9XyBLCwXyGA(1dXNotQoto)AxfiNypsJ2x6rtH9f15huVMO8K8gEWpYzwhoQOeHCziW7jHIMo3K8YwvYrgggxMVsT6DHZ0rmbpNMN0vnAjZkXBcTNbX)iDkNdbsLhfFQxoCgNFLxw9o(K)RTjViYb0B(kMdO05sNznDbL9kPlOl544kCQmTX3ZIxzYOWeJMpKsW(Igy08REez(8VSnGpwmMv0GVcjPdM6TJxZWC2WtQERTjHdsIQz3w5sJnVpA9Drs6hy3hSWEIIVVzGA(CMu)Knp15A2ZMu)0L3fMu)RSyg0F2YA275F)sRzp3LuZs(rV0A2h)IQzWbP5KRTcPCSW9V31JqQ19wTHJhu3lpEqjtnY4dWpnVKwTXT5EZmsMXRNJdjz46BIOthOpDY26)JxtHxFNRccVUJlrDrVQ7VT6IqczAJ0TlEvsRxI1dBtSAjyYXwzWKrd3w3H0HsnXmNqxoCMZW1zcX39QJrbREi)X5k1tQzFy(Uxg)4V)oYs)Zt7J2l(eSZsfqmoDdpzRwOap(8OdUDK2ZfAKnsjlY2HtAGwmj4keZc66UBQe)IGJH2Iqvmk9Gz9xUpMmt0zc137fDoMNDE8MlgtsrMxN1sH5hpAGqHXFXU(6bFjq0a(d7hNF50HJgKeLE0Tbixds(ckrvRNaHxqLxdFWsGpR8MLRuj(cgisk(RzbTCEECEjkkZNXQoSVW8PrDTvwQVoemVPVqtoCMY6cXQm4WduzQodC((VO)rAIOh)k2gzcMF6a9As9)As9BRtXn3Wn8cevU1a0D9lbp3acDpkF6j5ZouNj4)Gx0j4FDheCedV)G2071GyF5NQnRrun7ifj5fnfjKMU3zgnr(ascDMI8dBqrs(cNRAZRRYPnj5BBAxeQdzyzFAmqEwJZJv1T3YVXIHra(FJqtnYooR7q0mSIvR8M3s9Q6oXAEXFd0IA8KZcYCKt5Xg5sFDcj50HWXzfTDy7MnpNwZJOvRJFu)noesxuyrYWZ67EEmKJvdSByplGprzrTBC0)Tzyz2p(G7)sMNDERJSHbJNiN9jlwn26Nwz)nxS96FRZtF0fS6zMKhT)C4J(NVa(mgL8g(IutrWI1pliSokKPrZP1aDUN1j688KLTgNqYWJcZjyHkI1KcyD6JGp2V0SxrDUAFIl94xohHwRlwKNXAI7aQIylOwG8A6NCypFe4PzIjXZjJqUwV(6Na1hSPnuyl(eLlhLt7udN8UB(R7olb8sAMJmm7hHfhH5X(LegJJSWOPR5vBGahCcVNgX5y)6flwKxMjv8rIZaFwtQVOZpDx4ZVIdj3LNGhByly2TpfMkrssLUQ0vXUkE2xvRN6mqi4xAsH8L)zWSG2hjm4JdMV9MVg)Wg8Mw5jaJr4IzdMUBVdNT)2CcW0LotphoWH921uB8n))n
```
