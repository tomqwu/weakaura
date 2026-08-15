# weakaura

Hand-built, programmatically generated WeakAuras for WoW Classic (TBC Anniversary).
Every import string here is produced by Lua build scripts through the exact WeakAuras
serialization pipeline, verified by round-trip decode before commit — no hand-edited
exports, no custom code beyond the reviewed one-line trigger-combinator pattern.

## Structure

```
tbc/<class>/           one folder per class
  ├── *.txt            importable "!WA:2!" strings — copy the whole file, /wa → Import
  └── generate.lua     the build script that produced the string
tools/tbc-weakaura-creator/
                       the generator toolkit + verified schema references + gotchas;
                       also packaged as a Claude skill (see its SKILL.md)
```

## Import strings (quick copy)

Latest version of every pack. Each link jumps to the pack README's fenced code block —
use GitHub's copy button on the block to grab the whole string in one click.

| Pack | Specs | Version | Auras | Copy |
|---|---|---|---|---|
| Rogue — All Specs | Combat · Assassination · Subtlety | v49 | 62 | [string](tbc/rogue/README.md#import-string-v49) · [raw](tbc/rogue/all-specs.txt) |
| Paladin — All Specs | Holy · Protection · Retribution | v11 | 48 | [string](tbc/paladin/README.md#import-string-v11) · [raw](tbc/paladin/all-specs.txt) |
| Druid — Bear, Resto & Balance | Feral tank · Restoration · Balance | v10 | 48 | [string](tbc/druid/README.md#import-string-v10) · [raw](tbc/druid/all-specs.txt) |
| Warlock — All Specs | Affliction · Demonology · Destruction | v9 | 44 | [string](tbc/warlock/README.md#import-string-v9) · [raw](tbc/warlock/all-specs.txt) |
| Hunter — BM & Survival | Beast Mastery · Survival | v10 | 54 | [string](tbc/hunter/README.md#import-string-v10) · [raw](tbc/hunter/all-specs.txt) |
| Priest — All Specs | Shadow · Holy · Discipline | v9 | 44 | [string](tbc/priest/README.md#import-string-v9) · [raw](tbc/priest/all-specs.txt) |
| Mage — Arcane & Frost | Arcane · Frost | v9 | 48 | [string](tbc/mage/README.md#import-string-v9) · [raw](tbc/mage/all-specs.txt) |

Every pack is class-gated and auto-adapts across the **supported builds listed in the table**
through Spell Known gates. The current product scope is primarily level-70 single-target
raid/dungeon play plus the explicitly documented PvP layer; AoE, levelling and omitted specs
are named in each pack README rather than implied by the `all-specs.txt` filename. Druid v7
also adds an active-form state gate so Cat never receives the Bear rotation, v8 replaced the
centre bar stack with unit orbs and v9 put those orbs on one shared size — and **Druid v10
turns them into Diablo-style globes**: life at `x = -300` and power at `x = +300` in 116px
vessels that fill bottom-to-top, a 76px target globe between them at `(0, -280)`, the
percentage *inside* each glass, threat as the target globe's rim colour, and no portrait —
dropping it is exactly what frees the centre of a vessel for its number.

Every pack also carries a **PvP layer**: elements that exist only inside an
arena or battleground (CC-on-you with the break decision, trinket availability, enemy trinket
countdowns, interrupt and immunity prompts, your own CC timers on each opponent). They are
load-gated per aura, so a PvE player sees no change at all. What is *not* built — and why —
is in `tools/tbc-weakaura-creator/references/pvp.md`; most importantly there is **no
diminishing-returns tracking**, because TBC WeakAuras cannot express it without custom code
and a partial DR tracker is worse than none. The source-verified Crowd Controlled primitive
is still marked **live-smoke-required** on a 2.5.x client; every pack README carries that
acceptance note instead of presenting static serialization as an in-game test.

## Packs

- **tbc/rogue/all-specs.txt** — full HUD, v49 of a 49-iteration build: v49 **Diablo globes**
  (life 116px at `x = -300`, energy 116px at `+300` and the target's health 76px at `0`, all
  three on the `y = -280` band shared by every pack — vessels that fill bottom-to-top with the
  percentage inside the glass, the 35/40 energy breakpoints as waterlines across the energy
  globe, threat as the target globe's rim colour, and no portrait: a `model` region cannot
  carry text, which is what kept the old numbers outside their rings), replacing the v47/v48
  **unit orbs** (live portraits ringed by health and energy, which in turn replaced the centre
  bar stack), combo pips (always-visible sockets, green→orange
  gradient, and a brief scale/brightness pop whenever a point is gained),
  spec-adaptive cooldown row
  (16 spells, talent-gated, tooltips + keybind labels), animated alert flow (SnD missing,
  Riposte window, Feint-at-70%-threat, Evasion-below-50%-HP), weapon enchant proc tracker
  with clones, out-of-combat fade, plus the arena/BG-only PvP layer (CC-on-me with the
  break decision, Kick prompt and lockout bar, target immunity, trinket availability,
  enemy trinket countdowns, own Blind/Sap/Gouge per opponent, Wound Poison uptime).
  Locale-independent (pure spell-ID matching, built on a
  zhCN client). Combat / Mutilate / Subtlety auto-adapt via spell-known gates.
- **tbc/paladin/all-specs.txt** — seal uptime + missing alarm, own Judgement debuff, Holy
  Shield uptime, and **v11 Diablo globes** in place of the v9/v10 ring orbs: a 116px life
  vessel at `x = -300`, a 116px mana vessel at `x = +300` and a 76px target vessel at `x = 0`,
  all at `y = -280`, each filling bottom-to-top with its percentage **inside the glass** — the
  portraits are gone (a `model` region cannot carry text, which is what kept the ring-era
  numbers outside) and both were recycled into the two brass rims, so 48 auras stay 48 with
  every UID stable. Threat became the **target globe's rim** — green, orange at 70%, red on
  aggro, percentage above the globe — costing no extra element. Plus the seal-twisting swing
  runway and a 14-icon cooldown row that shows only what is
  unavailable (rotational buttons stay visible and glow when ready); Holy / Protection /
  Retribution adapt via Holy Shock, Holy Shield and Crusader Strike gates, and the row is
  spec-selective — a healing Holy paladin is not shown Consecration or Avenging Wrath. PvP
  layer: CC-on-me, HAMMER NOW, target immunity, trinket and Forbearance clocks, Cleanse.
- **tbc/druid/all-specs.txt** — **v10 Diablo globes** at the geometry shared by every pack: a
  116px life vessel at `x = -300`, a 116px power vessel at `x = +300` and a 76px target vessel
  at `x = 0`, all at `y = -280`, filling bottom-to-top with the percentage inside the glass and
  a brass rim over each. The power globe is form-adaptive — one vessel reads mana, rage or
  energy as you shapeshift and is always coloured for what it is actually reading — with the
  bear's 20/70 rage breakpoints as horizontal marks across it; threat is the target globe's rim
  colour (green → orange at 70% → red on the aggro flip, `%threatpct` above the glass); there is
  no portrait, which is what frees each vessel's centre for its number; and the target globe
  hides completely with no target. Lacerate stacks and Mangle debuff,
  Demoralizing Roar, Lifebloom/Rejuvenation/Regrowth
  timers, Moonfire and Insect Swarm, Omen of Clarity proc, and an 8-icon cooldown row showing
  only what is down (Mangle keeps its ready glow); Bear / Restoration / Balance gate on
  Mangle, Swiftmend and Moonkin Form, with every Bear element additionally requiring active
  Bear/Dire Bear form so Cat sees no tank HUD. PvP layer: CC-on-me, Barkskin-while-stunned,
  target immunity, trinket clocks, own Cyclone/Roots per opponent.
- **tbc/warlock/all-specs.txt** — the five own-DoT timers (Corruption, Curse of Agony,
  Immolate, Unstable Affliction, Siphon Life), Demonic Sacrifice and Fel Armor upkeep,
  Nightfall and Backlash proc alerts, Life Tap and Soulshatter prompts, and **v9 Diablo
  globes** in place of the ring orbs: life (116px, red, amber at 60%) at `x = -300`, mana
  (116px, blue, violet at 30%) at `x = +300` and the target's health (76px) at `x = 0`, all
  three on the absolute line `y = -280`, filling bottom-to-top like liquid with the
  percentage inside the glass. The portraits are gone — a model region cannot carry text,
  which is what kept the numbers outside the rings — and **threat became the target globe's
  rim colour** (green → orange at 70% → red on aggro, percentage above, pulsing halo at 80%,
  same party/raid and not-in-arena gates). Plus a 7-icon cooldown row showing only what is
  down. PvP layer: CC-on-me, target immunity, trinket clocks, per-opponent enemy mana for
  the drain decision.
- **tbc/hunter/all-specs.txt** — Serpent Sting and Hunter's Mark timers, Bestial Wrath and
  Rapid Fire windows, aspect-missing and back-to-Hawk alarms, Kill Command reactive prompt,
  pet health prompts, Misdirection/Feign Death threat pairing, proc tracker, and **v10
  Diablo-style life and mana globes** — round glass vessels that fill bottom-to-top with the
  percentage inside the glass, life at `x = -300`, mana at `+300` and the target's own globe
  between them at `0`, all at `y = -280`; the mana globe carries the two aspect-swap
  thresholds as waterlines, and **threat is the colour of the target globe's rim** (green →
  orange at 70% → red on aggro) with its percentage above it. The live portraits are gone —
  a model region cannot hold a text sub-region, so dropping the face is what frees the centre
  of each globe for its number — and both portrait auras were recycled into the glass rims
  rather than deleted. Plus an 11-icon
  cooldown row showing only what is down (Multi-Shot and Arcane Shot keep their ready glow);
  BM and Survival only. PvP layer: CC-on-me, SILENCE NOW, trinket clocks, enemy mana.
- **tbc/priest/all-specs.txt** — Shadow Word: Pain and Vampiric Touch timers, Vampiric Embrace
  and Inner Fire uptime, Shadowform-missing alarm, Weakened Soul shield-timing on the heal target,
  Fade and Shadowfiend prompts, and — since **v9** — **Diablo-style life and mana globes**
  that fill bottom-to-top with the percentages inside the glass (116px at `x = ±300`, a 76px
  target globe between them, all at `y = -280`), replacing v7's portrait-and-ring orbs: the
  portraits are gone because a model region cannot carry text, which is what freed the centre
  of each globe for its number, and **threat is now the target globe's rim colour** — green,
  orange at 70%, red on aggro — so it costs no extra element. The 40% health and 50% mana
  breakpoint marks are horizontal lines across the glass. Plus the arena/BG-only PvP layer
  (CC-on-me colour-coded by CC category, Fear Ward and Mass
  Dispel prompts, trinket clocks, UA-on-ally warning, and a per-opponent enemy mana bar for
  the Mana Burn decision). The threat rim and Fade prompt do not load in an arena.
- **tbc/mage/all-specs.txt** — Arcane Blast stacks (the Arcane rotation driver), Arcane Power
  and Icy Veins burn-window timers, Ice Barrier uptime and missing alarm, Clearcasting proc,
  mana thresholds with Evocation/mana-gem prompts, Ice Lance shatter window, and a 10-icon
  cooldown row showing only what is down; Arcane and Frost only. v7 replaced the centre
  health/mana/threat bar stack with two unit orbs and v8 put them on the shared ring geometry;
  **v9 replaces the rings with Diablo-style globes** — a 116px red life vessel at `x = -300`,
  a 116px blue mana vessel at `x = +300` and a 76px target vessel between them, all at
  `y = -280`, each filling bottom-to-top like liquid with its percentage **inside the glass**.
  The live portraits are gone (a model region cannot carry text, so keeping them meant keeping
  every number outside its orb); **threat is now the target globe's rim** — green, orange at
  70%, red on aggro, with a flare above 80% and the percentage above the globe — and the
  Arcane conserve breakpoint is a horizontal line across the mana globe at its 30% waterline.
  PvP layer: CC-on-me
  colour-coded by category, COUNTERSPELL NOW plus its lockout bar, target immunity, trinket
  clocks, own Polymorph per opponent, enemy mana.

## Verifying

```bash
lua5.1 tools/verify-packs.lua && tools/verify-rebuild.sh
```

`verify-packs.lua` discovers every shipped string, round-trip-verifies it, checks bidirectional
parent wiring and historical UID continuity, validates root/pack/generator versions, aura
counts and seed registration, checks each README copy block byte-for-byte, and enforces global
id/uid uniqueness. `verify-rebuild.sh` independently discovers the same deliverables, re-runs
every build script—including Rogue's v41→v46 lineage replay—in a sandbox, and proves byte-for-
byte reproduction.

Uid uniqueness matters because WeakAuras matches auras across imports by uid: two packs built
from the same `math.randomseed` produce identical uids, and importing both would make one
silently "Update" over the other. Seeds in use, one per pack — never reuse one:

| Seed | Pack |
|---|---|
| 20260809 | rogue |
| 20260810 | *retired* (paladin tank-starter, removed) — do not reuse |
| 20260811 | paladin |
| 20260812 | druid |
| 20260813 | warlock |
| 20260814 | hunter |
| 20260815 | priest |
| 20260816 | mage |

## Updating a pack

Re-importing a regenerated string offers an in-place **Update** (UIDs are deterministic and
stable across versions). Uncheck the *Arrangement* category in the update dialog if you've
dragged groups in game. Details: `tools/tbc-weakaura-creator/references/encoding.md`.

After regenerating a pack, use
`lua5.1 tools/sync-readme-strings.lua <pack>` to replace its README copy block from the
canonical `all-specs.txt`; the verifier rejects missing, duplicate, or stale blocks.

## Building new packs

`tools/tbc-weakaura-creator/SKILL.md` — workflow starts from the spec's rotation
(`references/rotation-design.md`), maps each rotation rule to one HUD element, builds through
`scripts/wa_factory.lua`, and verifies with `scripts/wa_lib.lua`. Run `scripts/setup.sh`
once to fetch LibDeflate/LibSerialize (not committed; MIT/zlib-licensed upstream).
