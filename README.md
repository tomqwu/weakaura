# weakaura

Hand-built, programmatically generated WeakAuras for WoW Classic (TBC Anniversary).
Every import string here is produced by Lua build scripts through the exact WeakAuras
serialization pipeline, verified by round-trip decode before commit — no hand-edited
exports, no custom code beyond a single one-line trigger combinator.

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
| Rogue — All Specs | Combat · Assassination · Subtlety | v41 | 45 | [string](tbc/rogue/README.md#import-string-v41) · [raw](tbc/rogue/all-specs.txt) |
| Paladin — All Specs | Holy · Protection · Retribution | v2 | 30 | [string](tbc/paladin/README.md#import-string-v2) · [raw](tbc/paladin/all-specs.txt) |
| Paladin — Tank Starter | Protection (minimal) | v1 | 6 | [string](tbc/paladin/README.md#tank-starter-import-string) · [raw](tbc/paladin/tank-starter.txt) |
| Druid — All Specs | Feral tank · Restoration · Balance | v2 | 39 | [string](tbc/druid/README.md#import-string-v2) · [raw](tbc/druid/all-specs.txt) |
| Warlock — All Specs | Affliction · Demonology · Destruction | v2 | 27 | [string](tbc/warlock/README.md#import-string-v2) · [raw](tbc/warlock/all-specs.txt) |
| Hunter — BM & Survival | Beast Mastery · Survival | v2 | 33 | [string](tbc/hunter/README.md#import-string-v2) · [raw](tbc/hunter/all-specs.txt) |
| Priest — All Specs | Shadow · Holy · Discipline | v2 | 29 | [string](tbc/priest/README.md#import-string-v2) · [raw](tbc/priest/all-specs.txt) |
| Mage — Arcane & Frost | Arcane · Frost | v2 | 32 | [string](tbc/mage/README.md#import-string-v2) · [raw](tbc/mage/all-specs.txt) |

Every pack is class-gated and auto-adapts to your spec through `spellknown` talent gates —
import the one pack for your class and it shows the right elements after a respec, with no
further action.

## Packs

- **tbc/rogue/all-specs.txt** — full HUD, v41 of a 41-iteration build: health/energy/threat
  bars with 35/40 energy threshold lines, combo pips (green→orange gradient, left to right),
  spec-adaptive cooldown row
  (15 spells, talent-gated, tooltips + keybind labels), animated alert flow (SnD missing,
  Riposte window, Feint-at-70%-threat, Evasion-below-50%-HP), weapon enchant proc tracker
  with clones, out-of-combat fade. Locale-independent (pure spell-ID matching, built on a
  zhCN client). Combat / Mutilate / Subtlety auto-adapt via spell-known gates.
- **tbc/paladin/all-specs.txt** — seal uptime + missing alarm, own Judgement debuff, Holy
  Shield uptime, mana/health/threat bars, and a talent-gated cooldown row; Holy / Protection /
  Retribution adapt via Holy Shock, Holy Shield and Crusader Strike gates.
- **tbc/paladin/tank-starter.txt** — Protection starter: Righteous Fury missing alarm +
  cooldown row. Also serves as the canonical toolkit example.
- **tbc/druid/all-specs.txt** — rage/mana/health/threat bars, Lacerate stacks and Mangle
  debuff, Lifebloom/Rejuvenation/Regrowth timers, Moonfire and Insect Swarm, Omen of Clarity
  proc; bear / Restoration / Balance gate on Mangle, Swiftmend and Moonkin Form.
- **tbc/warlock/all-specs.txt** — the five own-DoT timers (Corruption, Curse of Agony,
  Immolate, Unstable Affliction, Siphon Life), Nightfall and Backlash proc alerts, Life Tap
  and Soulshatter prompts, health/mana/threat bars.
- **tbc/hunter/all-specs.txt** — Serpent Sting and Hunter's Mark timers, Bestial Wrath window,
  aspect-missing alarm, Kill Command reactive prompt, proc tracker; BM and Survival only.
- **tbc/priest/all-specs.txt** — Shadow Word: Pain and Vampiric Touch timers, Vampiric Embrace
  and Inner Fire uptime, Shadowform-missing alarm, shield and Fade prompts, mana/health bars.
- **tbc/mage/all-specs.txt** — Arcane Blast stacks (the Arcane rotation driver), Ice Barrier
  uptime and missing alarm, Clearcasting proc, Evocation and Ice Block prompts, mana bar;
  Arcane and Frost only.

## Verifying

```bash
lua5.1 tools/verify-packs.lua && tools/verify-rebuild.sh
```

`verify-packs.lua` round-trip-verifies every shipped string, checks each pack README's
embedded copy block is byte-identical to its `.txt`, and enforces that aura ids **and** uids
are globally unique across all packs. `verify-rebuild.sh` re-runs every build script in a
sandbox and proves the shipped strings reproduce byte-for-byte.

Uid uniqueness matters because WeakAuras matches auras across imports by uid: two packs built
from the same `math.randomseed` produce identical uids, and importing both would make one
silently "Update" over the other. Seeds in use, one per pack — never reuse one:

| Seed | Pack |
|---|---|
| 20260809 | rogue |
| 20260810 | paladin tank-starter |
| 20260811 | paladin all-specs |
| 20260812 | druid |
| 20260813 | warlock |
| 20260814 | hunter |
| 20260815 | priest |
| 20260816 | mage |

## Updating a pack

Re-importing a regenerated string offers an in-place **Update** (UIDs are deterministic and
stable across versions). Uncheck the *Arrangement* category in the update dialog if you've
dragged groups in game. Details: `tools/tbc-weakaura-creator/references/encoding.md`.

## Building new packs

`tools/tbc-weakaura-creator/SKILL.md` — workflow starts from the spec's rotation
(`references/rotation-design.md`), maps each rotation rule to one HUD element, builds through
`scripts/wa_factory.lua`, and verifies with `scripts/wa_lib.lua`. Run `scripts/setup.sh`
once to fetch LibDeflate/LibSerialize (not committed; MIT/zlib-licensed upstream).
