# Rotation-first design (start every pack here)

**The job: learn the spec's rotation — its best practices and key abilities — then render it
so the player's next button press is obvious at a glance. A pack is decision support, not a
tracker collection.** Everything below serves that. If a pack is beautiful, complete, and
still leaves the player reading tooltips mid-pull, it failed.

A WeakAuras pack is not a list of trackers — it is the spec's rotation rendered as UI.
Before building anything, declare the supported scope, then write out the priority rotation
for each supported SPEC and SCENARIO (leveling/dungeon single-target, raid single-target,
AoE, PvP). Any omitted spec or scenario belongs in the pack README and root pack table; an
`all-specs.txt` filename is the one-string-per-class packaging rule, not permission to imply
coverage that was never designed. Pull the
rotation from a current-phase class guide and confirm it with the user; talents change
rotations (e.g. Improved Sinister Strike changes the energy breakpoint from 45 to 40).

Then translate: every line of the rotation becomes exactly one HUD element, and any element
that doesn't change which button gets pressed next gets cut.

## Step 1: learn the rotation (not the spellbook)

Pull the spec's current-phase priority list from a real guide (wowhead TBC guides,
icy-veins.com/tbc-classic, the class discord's rotation post) — never from memory, and never
from retail or 1.12 Classic knowledge; TBC rotations differ from both (Shadow gained Vampiric
Touch, Arcane became Arcane Blast stack management, bears got Mangle/Lacerate).

Then extract only the part worth rendering. Most of a spellbook is not a decision:

- **Decisions that vary fight to fight** → these earn HUD elements. "Is my DoT about to fall
  off?", "am I at the energy/mana breakpoint?", "did the proc fire?", "is the big cooldown
  back?", "am I about to pull threat?"
- **Constants** → these do not. Buffs applied once before the pull, passive talents, abilities
  with no meaningful timing choice. A player does not need a HUD to remember to have Inner
  Fire up before the boss.
- **Things the default UI already answers well** → skip them unless the rotation needs them
  *combined* with something else (health is on the unit frame; health *below 50% while a
  defensive is ready* is a prompt worth building).

A good pack for a spec is usually 5–10 elements the player actually reads, plus a cooldown
row they glance at. If a spec's list is running past that, the extra items are almost always
constants or default-UI duplicates that should be cut.

## The usability test (apply before shipping)

Every pack must pass all four, judged in combat, never from the /wa preview:

1. **Does each element change a button press?** For every element, name the rotation rule it
   serves and the decision it changes. No answer ⇒ cut it.
2. **Can the player run the rotation from the HUD alone**, without watching buff bars,
   recount, or the spellbook?
3. **Is the most frequent decision the most prominent?** Every-GCD state belongs closest to
   the crosshair and largest; once-a-minute cooldowns belong at the edge. Reactive prompts
   should announce themselves by *appearing* (animation + glow), so they cost no attention
   until they matter.
4. **Is it quiet when nothing needs doing?** Out of combat and during a clean rotation the HUD
   should be nearly still. Constant motion trains the player to ignore it, which costs the
   alert that actually mattered.

## The alert flow is where "press this now" lives

The alert column (a `grow="UP"` dynamic group beside the character) is the pack's primary
surface for telling the player what to press. It is worth understanding why it does not
compete with the "cut anything that doesn't change the next press" rule:

**A cooldown-row icon and an alert answer different questions.** The row icon answers *does
this ability exist, and is it up* — a passive readout the player consults. The alert answers
*press this now* — it interrupts the player. Desaturating an icon when it comes off cooldown
says the button is available; it never says the moment has arrived.

**Alerts are conditional, so they cost nothing while silent.** Nothing is drawn until the
condition fires, and the dynamic group closes the gap afterwards. So the budget for alerts is
not screen space — it is the quality of each condition. Adding a tenth alert whose condition
is right costs the player nothing; adding one whose condition is loose costs them every alert,
because a column that cries wolf gets ignored wholesale.

Rules for what earns an alert:

- **Ability-ready AND the state that makes pressing it correct.** Never ability-ready alone —
  that is the cooldown row's job, and an alert built that way sits lit for most of the fight.
  The canonical shapes are *reactive* (a proc or event window fired, and the answer is off
  cooldown) and *conditional* (a danger or opportunity threshold crossed, and the answer is
  off cooldown).
- **If it would be lit most of the fight, the condition is wrong.** A paladin's Judgement
  cooldown is 10s against a 20s debuff, so "Judgement is ready" is true almost always; the
  real cue is the debuff expiring. Fix the condition or leave the ability in the row.
- **Prefer promoting an existing decision over adding a new icon.** The high-value abilities
  usually already sit in the cooldown row as passive icons. Giving one an alert at its true
  moment is nearly always worth more than adding another passive icon.
- **Emergencies always earn one.** Survival cooldowns paired with the health threshold that
  calls for them, and CC-breaks paired with being CC'd, are the highest-value alerts in the
  pack — they fire rarely and matter enormously each time.

A useful smell test: compare the pack's alert count with its passive cooldown-icon count. A
pack with many passive icons and few alerts is making the player scan a row to discover
moments the HUD could have announced.

## Show what the player CANNOT press

The default cooldown row is inverted: it shows every ability all the time and dims the ones
on cooldown, so the row is at its busiest when the player has the fewest options. The player
already knows their own spellbook — what they cannot know is what is unavailable and for how
long.

So for **situational and utility cooldowns**, use `genericShowOn = "showOnCooldown"`: the icon
exists only while the cooldown runs, carrying its countdown, and disappears when the ability
is back. Inside a dynamic group the gap closes, so **absence is the readout** — an empty row
means everything is available. A row of two icons means exactly two things are down, and both
are counting back.

The exception is **press-on-cooldown rotational buttons** (a paladin's Judgement and Crusader
Strike, a bear's Mangle, a shadow priest's Mind Blast). Those must stay `showAlways`, because
their whole point is the ready-glow that fires the instant they come up — an icon that is
hidden while ready cannot announce itself. Hiding them would trade a "press this now" signal
for a "you cannot press this" one, which is the wrong direction for the button you press most.

The split, then:

| Ability kind | Display | Why |
|---|---|---|
| Press-on-cooldown rotational | `showAlways` + ready glow | the glow IS the instruction |
| Situational / utility / long CD | `showOnCooldown` + countdown | absence = available; presence = when it returns |
| Emergency answer (defensive, CC break) | alert flow, paired with its trigger state | it must interrupt, not be looked up |

## Rotation rule → element mapping

| Rotation rule | Element |
|---|---|
| "Keep buff X up" | Active timer in the buff row + a glowing MISSING alert (combat-gated) |
| "Keep debuff Y on the target" | Own-only debuff timer (`ownOnly = true`, all rank IDs) |
| "Spend at N resource" / pooling | Threshold line on the resource bar with a lit layer that pops at crossing |
| "Finisher at N points/stacks" | Pip color flip at cap (condition on the power value) |
| "Use Z on cooldown" | CD icon, desaturate while down; `showOnReady` glow if it must be pressed ASAP |
| "React to proc / event window" | Prompt in the alert flow: event trigger (combatlog/aura) AND ability-ready, glow + enter/exit animation |
| "Manage a danger state" | Bar with escalating color tiers + a paired-ability prompt at the action threshold (threat→Feint, low HP→Evasion) |
| "Only in raids / only this spec / only talented" | Load gates: `ingroup`, `use_combat`, `spellknown` of the signature talent |

## Layout by decision frequency

Distance from the crosshair should equal how often the rotation consults it:
every-GCD state (resource bar, points, thresholds) closest; per-cycle timers (buffs/DoTs)
next; occasional cooldowns further out; reactive prompts as an animated flow beside the
character so appearance itself is the signal. Out-of-combat, fade the always-on layer
(inCombat condition → alpha) so the HUD breathes with the fight.

## Multi-spec in one pack

Write each spec's rotation separately, find the shared core (usually the resource system and
one or two universal buffs), then gate every spec-specific element with `spellknown` of that
spec's signature talent. Mutually-exclusive spec elements may share a screen slot. The
result auto-adapts on respec with zero user action — verified across Combat/Mutilate/Subtlety.

**The pack is not a superset — each spec must get a HUD that looks purpose-built for it.**
The test is per spec, never on the pack as a whole: load the pack as one spec and ask the
four usability questions again. A pack that is perfect in aggregate and cluttered for Holy
has failed for Holy.

Two rules make that concrete:

- **An ungated element loads for every spec, so it must be justified for every spec.**
  Ungating is the default failure mode, because it is invisible while you build: nobody
  notices that the healer's cooldown row inherited the tank's threat dump. If one spec never
  presses it, gate it — an element only that spec sees is worth more than an element everyone
  sees and two specs ignore.
- **Gate on ability, not only on spec.** `spellknown` on an ability's own rank-1 id is usually
  better than on the spec's capstone: it hides the element while levelling (before the ability
  exists) and shows it to every build that actually has it, including hybrids. Reserve
  capstone gates for elements that only make sense inside that spec's rotation.

Current WeakAuras exposes a separate inverse load argument:
`use_not_spellknown = true, not_spellknown = <id>` (WeakAuras 5.4.0+). It is not expressed as
`use_spellknown = false`; that disables the positive gate. Prefer an ability's own positive
gate when possible, use the inverse only for genuine complements such as "not deep Holy",
and check the hybrid case before duplicating elements.

Audit the result rather than trusting the build script:

```bash
lua5.1 tools/spec-preview.lua <pack>
```

It decodes the shipped string and evaluates the combined load/form eligibility of explicit
level-70 exemplar profiles. Pass `pve`, `arena` or `prepull` as the second argument. The result
is the offline-eligible set; live aura/cooldown state still decides what is currently drawn.

## Scenario variants

If two scenarios disagree (raid rotation vs PvP), prefer load-gating over duplicate packs:
`ingroup` for raid-only pieces, combat gates for reactive ones. Only fork a separate pack
when the layouts themselves must differ.
