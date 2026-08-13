# Warlock — All Specs HUD (v4)

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

Upgrading from v1, v2 or v3: paste the new string and the import dialog offers
**Update** (the UIDs are unchanged), which upgrades the group in place instead of
duplicating it.

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

- **CC ON ME** (red, with a countdown) — you are stunned, feared, rooted,
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
twenty icons inside a stun), enemy healer mana (the arena-unit power read is
unverified), enemy spec detection (impossible on TBC — every element here says
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
threat bar loads only in a party or raid, appears once you are on a hostile
threat table, turns orange at 70% and red the moment you pull aggro, and a
pulsing red overlay flashes across it at 80%+. Warlock threat is dangerous in all
three specs, which is why the bar sits with the every-GCD information instead of
off to one side.

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
countdown. It is a dynamic group because those rows spawn one copy per arena
opponent, and it collapses to nothing the moment nothing is running.

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
a party or raid — solo, pulling aggro is the plan. Life Tap and all three
"MISSING" prompts are combat-gated, so nothing nags you between pulls.

The v4 auras are gated on instance type instead of (or as well as) a talent, and
each one carries its own gate — a group's load is not a child gate:

| Element | Loads in |
|---|---|
| CC ON ME, TARGET IMMUNE, Trinket DOWN, Howl of Terror | arena **or** battleground |
| Will of the Forsaken DOWN | arena or battleground, if you know 7744 |
| Fear Out, Spell Lock ON, Fear Ward UP, Enemy Trinket | arena only |

The arena-only four read `arena1`–`arena5`; those unit ids do not exist in a
battleground, so loading them there would only ever produce blank slots.

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
and their group were added below those, leaving all 26 v3 UIDs stable.) The
script checks UID
continuity against the previous `all-specs.txt` automatically before overwriting
it (expect `changed=0`). One more re-import caveat: the Update dialog's
**Arrangement** checkbox is checked by default and will reset any positions you
dragged in game back to the string's defaults — uncheck it, or report your
coordinates so they can be baked into the script.

## Import string (v4)

```
!WA:2!DZ1(3Trw9DMOnSjAFGJ3KSSoSlcZMW6WUbPrpDyZcsYs2YrYszKSDC2awJgDL0ypAMjZmsokTuynVCHLxEPlhOqH1lfOuouWThk90hNdHUu(Hf6xCB5m)qFDcNdN2FJt6)a9EVZOx2ks55UX7p4RN5EVZDU373pFFFhXm3WcFJhFT3(wf4fwUOMIAufjfTPD4WrghUpHF1HfuKn0uKKqfJwruQOgsEA1HMNxtsryzxpLRPq8sgvUs7ksXlZ3zhYvrdXBOE4TxJR4s86vUsbfTIiTi2VC1HIijEPlXRv0voffjdrvTlMUujDKbtbvE872q9HBoq5IefpyHLKCLvfjOxWAKQO1W6bUWgAOYIkY5AOI4kRPutDdREKv8sO9UPOCjfTQ8g4E4CtRgSw5mmmo2IVMrffT0QKM1DwaVhusSStnEbAfb40n41mCwOKOSOEfNrW)ZW5QgAILlJ00N5yA2x(IrmiVD(AA8SxMuQRIKKelQpYWUJud)qfuL4BG0wLwFII6oVIETcO641z2ALkjEXnxmA4S5wmBUWC5A1ugneUjUSzILm5vRPJIDr88kR1iKNtMVks35gfrfWJazXRnvSKzIpBY1RjBpTCUzrr9LQjJxn1rS8ssQhGNEDoR2tPue99Et2BxXkwgPEGSxOgE73v8A4T75RiAGUSvRw717FDEzrRnZaWHJFzeVokRbMCv2OY9chjISImARI41pPhls2t00r4n1I6Rs6kzwcSrQYlkhh8GFaGf8c(a)4))WBVM11rsLYOikBuiASzYfJBuXIQpuB0fhsxPMMas)Q4UG0K5LMd)2WV3NDZsA49g88I3G3Xv5LfWK44KQiV)czJYfl2mByOiu3Q)7lZHyRjwCZjdCbJcAX5MB2tZPlWlHCSbMsWrbx6nXojKXBdo2GSMeTanrKu4l6CtRxdD(cHwZ9g6yy8YZlw0OYH2qe39S0j7B7nboHXHh4F)nbXHqBr7eNIbD)Ir9aDDpH6ej8S5shH88vGh5dEmyKxeVf9yW7agLJcrkyXwIR6TdUCUkgKSibULhENWJdhZj8UGNagZzNphKs9GZI7IROv4j4CKMOUHOGU9qaP32ZchhE3WtIrjKjXIcnfA4ao5ZcbHqRwG3MFkZ94(eE8tkdgIuY63bgCQZBqGdOkxMU2SGrlWaro5HHJSjHvbpalI)BTdRoSb6IglQxHVOYkN1wAW606ifQdDumCsaVORqxZh9OQd1Xd0MP(kw12e9aNw9HO1G51viyxbkvjsy8TxL2aMjdvKw5ZTLfzCb73(LPTVun8ouPgqOn0iKguoCLrMj9mXGJOHriK(SbTJT3DSM2LWIuvhkUM4LCDMA8fj4rx5YP6U1AArlztl21cBXIibmtM0IQA4l0PiJo3AAo52Iw3kyy58A8QRoV9fB16vtfkKE2Cjtmtm79QoqPBMyMzIXTixIjNkN6ydykHfRkxKYqZvssrrZAJPoE2vqcLV9RKiZ9rS3eBscvp6agCRklmtTQfqA1HJSoEt1IBBlR)zpTzXWKM1OytGSVvOn13UMMZnB(2fryXBWjAENoEE6OqfKy5kgpkeBU1jCocyfv65lyGz9Lnomx1Ay9so5O1ESc6IYLLqAZhMlz6ONg(ihg(O5JGfNlCy4J4mcz8ixCfkkpcEaksyFzdpXeQdHh7WfjGiuruXu8xSILWHOT5LEiNWbDU9okI55FqnBwKozFold4Mi(D7IqdCDiuLYfRlweXrj8WHWdKt4HDcVvNrUKIsvMnPVOPO7mNsJq0QPH4IkH4L54LuRW7WAQKZQf1Nibr6BjEb05JYJ5tKlhHx78ZM4PAF3tLLkwJ(yvGNblVflkhCa7NbEVo4wHW49p6eEA4uW7BZ4JLRC8tVC8ZorunrzIeAuf7PKyXIizUzInxmUnv0eX0iQyYnMknxIZLEMCHtctC8JXjubjSCCyehRwNxtKhJb2Ql4gxDEPAOrd4Euf1rF6tPjuHxUmsFKJbVevg24(PgezjoZXQQyRvqAgnaUJb)j4HDVWxFvr5OkvlWBaVedzqo1PGnipo95GxgEb4aoVkXmRYu2MwsMiThCn3WKhcMQPIG)ogIIaibdmnCAiPTu(FuBP1CzuwbPrKoVUk5kcpitxcQ3IGDB1w(EkZhYmi57Wz6uSoWnTLmCsPp)w7loGSvGC2YUHzx7WWCmW8xTPyz6u4OhfwGYhcNdVEEw48Wh45GpidSiEmZd84NRaiy9MkciOmJ6tCTKoqhVoK8akqfqewcwgKGQGAE1hV)pQvDGbCHhb0yuFp9V37uQlwueudQdRaxKbAyTQUuE43dob877a(qe5gWFqE4dty8HN7yWQWh1sUa8XOv9XPLFc4tcRvb(d7Gth(uyoB4tdp)npJm8zGpBNmVWNJb(8Nc(cW6Wl4a(IWFe8ITz1Uhlwn4l1InZ9sxm6sssEYYnh8LRaFf4pg(QWxJW)qb5oGV(L7CZbEPr9s4xg(PTq6uWrq)THieWXl3blc8n7dVb8NET4g(Q7PxCdTWXByq9OGy(cwkTwzKbghFfc8VDd5jG8uQdz78rwrJAuXeuu)Txwd8ciePWBVzmU8rTMvQcgT4kuFYDacB1PEGa7ntK67Opdslq)o406K7Ph6KBpeDXYr5DWmBdMzOoMzytcXal1N4gMnNHM9T4Rpg8wYhrJxSy(7Qzx27oyxg)joRYerhxIpQuxSlNSf7Y6T2(W8kbP6wEgBO)0upSdqk80bxc(H44lJ3AGxYrNCktt644u1pSwL3KSwUGhzgmu)N1eQVvBgf80mp8xa)acw)hMh(BhnKBmda2kZwyaIspEdfnYQifSzhCpn5kUQTTbeBoj26OEWOjdNkd2DLKHJEASHpjYLyUyK5eMis4UpOZcvf10u0Qqz0Fq8U)eoxVqtBLW09EtDlbhPaMLaB4d9ECZ)0nOwIKPMKoA1MUBoSh6JStspHSsiNDs()cQNSTDlHlwmTS(5NhXVCyIV7NpfQOi)5TTWr)8w(eVi1D4tyuMNZ2oFkf1QatNc5NiGaJCWYiiOO3mf78cezdRQ10fpmwk30NrF2LlkLYBDIWo1dG9rxqdzGwSDV(qhTGLRgvSyRG)6MQz(X2SrWFtF4H(s3Z9T2BhyAfChypNt9GT9CoQIMwnAipUAhvwdBQL6WTRir1Qks4PG6J2UUzL1niwu5kCPssI0GKOEO2nNvuTIISRKILqW9c7JSz4eUp4(Xe87NbtWFlWq7Laig2s8HfZDNKfkGLiB(Tbp6id7UPGzICAca8O57HW5Nclb69S)BEjdwKRocS1ek50jKsmKHqbPWhSiGAXeJxZZYfxqec7aI4eI6aJFHyojuX1ENuLy7)53l8aul62sqrrc7SMC2veXgLD5M3sIYsfizERL63YAP(Py9eKnsawwAH3ibd4leNhpbc6HwYYX63RhpCSbz9eqdpiPLLAKhV58d6XMJ2uH5sfF2KDUfDYN9QlJqQHjURyWrWyvOAYWATIC81EiQ2QrpQ6nOLBT1NCzlxjJKoxU0PGl8OwAmkr1y0tTfN56Z0PhessajyZvkKsBSZQhDCEEmI6xb)twZJphv77Qn3BZ3sc(RQEWMvs4INquNGAXQDis1pJnwHaaoILafBSY2Q5H3rny4kw8FNiwccbJcWG6xWrtqWRUhBqa8VKh(x3b1(B8WSJhYDepU94dtU9eetJd6XdTKLw6LsPdXgWTxoVUh3dUV(g3nPjwA3yzjDGfdrcgka(rcoU3G0AgNnOBFy0J)qKIXPdMvlbIGV0hTIXH)JRf2b(p7g1a)x3EXjW)9DcWXm6ZUWk(BOOUsIDcoGR0gv8lGFZRriaM(ca(kSE9fctQcIXaJ7lc74(O85b8tldsldr45Dpofj4)MJIDYF9wLLuwjUg6c1qYcnSSA1kMvKgUm2EGjLSJCw(vjvrJHEgXlIK2GCBsAGDp0MKRBg1P1l38rWkaTCoKAydTtnd5teYnvODnlnsQ0zsUkIcllJ01DqBjPi(6dqFrrScP)DTqSCXfkuxUKy9al1Fi2V8oheBKwMnEf0fvfTm6jNyve8sSEoHFROzyzryE4LjHU(eEobzZTBO5c9fAEsSahpUdHl952hT8Mg8zYS3MiotM3SjZ9M3KzFMm73KX5HmzUpgtM7NAQBqlxOCyY8a46EWkMmVf81dH)7ahWKz4xtbfeBTO(tsZtZYYuLkwGKp2oGkB0Ut7R2xD7qMqvxkxSKCXsQF2(dz(NFTaYyYCq4Lmzo02qjMmhUB0XpSVOJL4iALWIPcfk44KYqUPLuttc4JQSYZUa1leYSjZixBsRjZr23KlSDsQbsuEIvI62)Y16pjfUZROXDeSNJRm6SzG98vANQuSj40ue4kNgVSqxMZtY8kjrSDwhXqDx54v7YgEfSxvv4nWohPEKURg3F5LDLkr2SjMzYoBmosYvyTQkATA8D2H50OQkYIcUYYlOjwsua1QtDmtIg1v6zCLkwNlLCH5MmwoxjsLA2zIr9NatfEGFcfEA5bbjKYcOh4w1fInX(ZvRQCwYGzfLNcwMYYXljwwgcPH96HKVugIz)yd(B7zLMv(qr5Po6e2b2tVvShhSxpextEWlxSHmFvrbAqqWoafrxrZayxVSMOvsNUVvjxsu9ok3eCsIvfnUpsM8ssUQYveuioDjBeNxa7pEbUWtKy2Sf04lkwt)JD)yxFwNxtWstngiBdb7mX8HLqAg6BuQMKuurnbju(MU28ZzioXSFPBbVNWWulmjrI3zwsBHyvdfUXaSdQj5Hy6QppxxE5DtOD53Xu3wNs(xV1PmqHnX)(Bxytjr2ZCU6xOCLPLaNMmVVRP0gtMJ2T4gY05Nc(1izCpDndAat2uxsSiQGIHHsv4vyjJaHc2dbrRn060KFtWJBPBOXtsee1io4ifeQPJhGc0o0GmrWGatMjSQ4Iwv8kd7bEbgAc1OvNF4gf3)WxKzDAmBid7QnhwYlFl81Y6KanqAs9anBlxZQXZmRix1SI80XMoA5V1ShVfo0RVX9g4ofo0Yoz)nZO0Ugm5ARSDmP6zZKsEIjBSq0tpim5X6jMeJvOWrtMyWRyYe)AdcnzM0KzkYMActMPBd1mzoDNWmtMKnXxMmPmzMHmuMmPnzYGhmtMZGxjCdeL84Wum9eKqY(WVTz8tvpux5lQzesh(PHV)OEDdPGVfbbrZIBxzwkp8T7oHDW3PJK01k8SW3y0aKrzgkoe3l8Jq6F68QhOJH0kjM5vpC35qV1S5z6pI94x32L71c164Acy7peRul)R2GMBDActZ3xFTiNwjY5KkbwLN6XBhFwY96NNEWNw0Y(MfJuttwuUCwSFqIgwGZOjzvrcsXJOntpbNvAdoFxVHbC2g9833Da9hNeqF4FyNHVh)qRDaoSWuHLJqormwGRYizKMOq2kkRKwo)wDD7M60)XH4l2GMhAQFpZWxfTpJnGJWrV1(Of9irTd7MRmAkL1W(676jOeUXuhMMAOYYkAiL6inSjpO8BHvsjLT5WTzh2EUvlVWiTqtQhz(BXaTUT(aHLZR(qKRrKtgxND)we)tLy71oYg3C4)xSRq13JanqJQpvimLnGiXfVD2IzWK5CQhT38aH1e4Lr2)ZThl4VEOiZuDQ5Mp3yjge8)jEdb8Vd)shHJ1plBOTWwIlubPBbB3Yc2MsuNC0DUjuUFdav8miL79hR8jAQo2sG4h2cpSq(DOsE6CDdq6VqYj5XAh0SUr3cLSsY5oxzrSdycvgekzS3OHsoohBipbdqkdnUjJSjJYBmqfYd1nQ4y9fvGDwN4REnnB5gjfYk2yLuEQxEqiIJ)gg1M2iIZX5juWqKizfKKFfCPhAjlNx)bD7zWyKoebzYuDxaM6B1Bnrey2vKvm6iUNyznwQS7U6wARwGc9su8grGug9gcvWMviGv7x1c(nMCDFi2fkRin2GGFV7DtWV(74zDQzB2GKM21KsDOOAkRu0v0wFjgeKZTdNp9CxJZNly5za9KQto0Sv6FoyogRAD18CKVieSZ(TCeny0LQDU5xwKD5vgKJOpztuZc76rn2HRyj2a(yJ4XnRBwFJhkIF)b9Y5ZVpVH486HL131k473YHtBp)27wqpMmFK(HB(D75)RnurQyyb2PUqHPMFHbbvEQDtqf3Mmpo81G9Cj1rAgQ3OtqI2BvvjXsnSppphPR2iXPFcLQIY0ChQ(w7QrSuNss8LjFSgTJcpTflP3fWUC3ZgkvtRX2Ayce20t8ikkTTzWukRi5sPKRCiYbbRvq9FY7PJO6BYCI9FRgsFtM3tZZRPjJhsb7odEVjJ3k2XT3KXx7i2BY4hgAVMmbawtMG3NjtOr5WeXXXxDYkMmVxtMN2K5u0yVBY8mDe09hQZZyLLFW6MmV)ThVDMBlHBpHMuYjod)S66CeJD6JCJ1WmPFatMpOjZIyOv(niogfwAf(g0p6htMc7BsvcQvWYjEtgmVac3ZsB1fyYKPY28d3Kre3TLU(C32k3U3RD(D7qbLdRqmzl5HivzFBvOMHHIC66inj(gxhM2e(6nPEQTTxHexk7p(W82P5pGx1ZKouML1vjYkwVpYk(0WVPcvwr47GzTDdf5M4OTDirZdVmKTTLUx)eFtMVytIEId2tI(v6wkXRHuDtMx82iPgV86W00VKnjoq56cz9n3CJPXpis8Z)Abj2K5lFhG0g)49K0UzhY431sxXRTEqxL8gJ1NSOKp2YdIU(z29sxJ9V1t66gT1qVRLSIxA9GSox55Bum80RKzIjgez9ZU7LSw)09JSsSVAxlzfV06bzDSjxYRQFVtgqOXGiRFUDVK1r(49MS2264DTKv8sRhK1g(UqYcrMWxc5Xgez9ZV7LSEiPEB3u3(2C3iPTzeL7W)5EtEXlrA0xmzEo89RMVBYCvJPB4tpikDMzgez(l86pzM4OCKjsp)mWEwQRFDs0eLxgz4I0uNNxT5fLOKrJkixXv005xgjB1PooBAXKrvB0Ci68GSfhXR5kDnJUotEKyG6kj5M0Z05uG255j)iOmBMEEa3WUc)a32CfMnx6m91z483oDgER2lZm1Z0dVGlE75uNfF(cbvcmre)Zx4AhZ)F8BEpKVQ6vfnqvPjUU(NKSNr4THuQV1EK06e4EoM1PWaZ9FfRCj2Yzm8E9LPPZ2E8Ydhjc562Pf4hzY8d2x9NV9BXK5h2A4mzOzK3K5VmpHp(VABp2l8)EZ9y)p3upwIV5n3J9DVHEm44S8Yn2UmV8qKr6ViRR)W9rs)WyBp9djMzUfNgTcssRXI2CRzMlZIntAEco(jwkYk(NqNgh5VFFKK9TVZjj76l6V7qH0Mnvi9yV)EQqs9G9su2nSEPbtJ(enPrDLOYr2zIkXt0UdoBQzw6INvxouMlXpO9)VZD(9)(MezYjTjLM9VFtJW5J81wr3XFfwpSUj)Q6yjMN8ZEHRS1eeqKFepGhdR(CZwNLLefZ33p08Unh4wN1axE426VVb4pyTOpfJWMmRVYtWLzPbrF(ZE9M)4xtJRzujfzKEElnKF3i(dgI8nv6XlPWFe)(c5JCOJzdfjanXV4l9tldq)m5WDZR)qBQI0i)ucq(QKxLVujKGbMss(SgW7LxHCs2eLrzS6t(7eFxm3LCYLVEK9Ep)82CZCL1ReTAYzNUA9bHw(UVE)P4Hjd)K8To9q(y9pUjZRAY8lAsMnz(L3riTw5Jne9OLX6y3ivo30vgBEu6LrztniQ8F(R3u5FwhuzmRTVa2e5(rHVvpNg9jpP9HqK4gNqeut39fNpEb)svgeH471KqK4ofHy4QdxC4IR9yD)Roamo8RmzEFyFejZp7Fsai)Ca8Q77U7FoaW(bTJFbamcvmBG0J5E2St1JFbagwNZ7j8Fc3dx)E(q)))
```
