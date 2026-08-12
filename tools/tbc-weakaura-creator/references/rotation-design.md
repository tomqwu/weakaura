# Rotation-first design (start every pack here)

**The job: learn the spec's rotation — its best practices and key abilities — then render it
so the player's next button press is obvious at a glance. A pack is decision support, not a
tracker collection.** Everything below serves that. If a pack is beautiful, complete, and
still leaves the player reading tooltips mid-pull, it failed.

A WeakAuras pack is not a list of trackers — it is the spec's rotation rendered as UI.
Before building anything, write out the priority rotation for each SPEC and each SCENARIO
the user plays (leveling/dungeon single-target, raid single-target, AoE, PvP). Pull the
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

There is no negated `spellknown`, so "show for Prot and Ret but not Holy" cannot be written as
one gate. Either gate each shared element on its own ability id (preferred), or ship one copy
per spec with positive gates — but check the hybrid case first: a 21-Prot/40-Ret paladin knows
both capstones and would see a duplicated element twice.

Audit the result rather than trusting the build script:

```bash
lua5.1 tools/spec-preview.lua <pack>
```

It decodes the shipped string and prints, for every spec gate, exactly which elements that
spec adds — plus the ungated list (read it critically) and the levelling case, which is what
a player sees before any capstone talent exists.

## Scenario variants

If two scenarios disagree (raid rotation vs PvP), prefer load-gating over duplicate packs:
`ingroup` for raid-only pieces, combat gates for reactive ones. Only fork a separate pack
when the layouts themselves must differ.
