# Rotation-first design (start every pack here)

A WeakAuras pack is not a list of trackers — it is the spec's rotation rendered as UI.
Before building anything, write out the priority rotation for each SPEC and each SCENARIO
the user plays (leveling/dungeon single-target, raid single-target, AoE, PvP). Pull the
rotation from a current-phase class guide and confirm it with the user; talents change
rotations (e.g. Improved Sinister Strike changes the energy breakpoint from 45 to 40).

Then translate: every line of the rotation becomes exactly one HUD element, and any element
that doesn't change which button gets pressed next gets cut.

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

## Scenario variants

If two scenarios disagree (raid rotation vs PvP), prefer load-gating over duplicate packs:
`ingroup` for raid-only pieces, combat gates for reactive ones. Only fork a separate pack
when the layouts themselves must differ.
