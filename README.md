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
| Rogue — All Specs | Combat · Assassination · Subtlety | v46 | 61 | [string](tbc/rogue/README.md#import-string-v46) · [raw](tbc/rogue/all-specs.txt) |
| Paladin — All Specs | Holy · Protection · Retribution | v8 | 43 | [string](tbc/paladin/README.md#import-string-v8) · [raw](tbc/paladin/all-specs.txt) |
| Druid — Bear, Resto & Balance | Feral tank · Restoration · Balance | v7 | 46 | [string](tbc/druid/README.md#import-string-v7) · [raw](tbc/druid/all-specs.txt) |
| Warlock — All Specs | Affliction · Demonology · Destruction | v6 | 38 | [string](tbc/warlock/README.md#import-string-v6) · [raw](tbc/warlock/all-specs.txt) |
| Hunter — BM & Survival | Beast Mastery · Survival | v7 | 46 | [string](tbc/hunter/README.md#import-string-v7) · [raw](tbc/hunter/all-specs.txt) |
| Priest — All Specs | Shadow · Holy · Discipline | v6 | 40 | [string](tbc/priest/README.md#import-string-v6) · [raw](tbc/priest/all-specs.txt) |
| Mage — Arcane & Frost | Arcane · Frost | v6 | 42 | [string](tbc/mage/README.md#import-string-v6) · [raw](tbc/mage/all-specs.txt) |

Every pack is class-gated and auto-adapts across the **supported builds listed in the table**
through Spell Known gates. The current product scope is primarily level-70 single-target
raid/dungeon play plus the explicitly documented PvP layer; AoE, levelling and omitted specs
are named in each pack README rather than implied by the `all-specs.txt` filename. Druid v7
also adds an active-form state gate so Cat never receives the Bear rotation.

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

- **tbc/rogue/all-specs.txt** — full HUD, v46 of a 46-iteration build: health/energy/threat
  bars with 35/40 energy threshold lines, combo pips (always-visible sockets, green→orange
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
  Shield uptime, mana/health/threat bars, and a 14-icon cooldown row that shows only what is
  unavailable (rotational buttons stay visible and glow when ready); Holy / Protection /
  Retribution adapt via Holy Shock, Holy Shield and Crusader Strike gates, and the row is
  spec-selective — a healing Holy paladin is not shown Consecration or Avenging Wrath. PvP
  layer: CC-on-me, HAMMER NOW, target immunity, trinket and Forbearance clocks, Cleanse.
- **tbc/druid/all-specs.txt** — rage/mana/health/threat bars with bear rage thresholds,
  Lacerate stacks and Mangle debuff, Demoralizing Roar, Lifebloom/Rejuvenation/Regrowth
  timers, Moonfire and Insect Swarm, Omen of Clarity proc, and an 8-icon cooldown row showing
  only what is down (Mangle keeps its ready glow); Bear / Restoration / Balance gate on
  Mangle, Swiftmend and Moonkin Form, with every Bear element additionally requiring active
  Bear/Dire Bear form so Cat sees no tank HUD. PvP layer: CC-on-me, Barkskin-while-stunned,
  target immunity, trinket clocks, own Cyclone/Roots per opponent.
- **tbc/warlock/all-specs.txt** — the five own-DoT timers (Corruption, Curse of Agony,
  Immolate, Unstable Affliction, Siphon Life), Demonic Sacrifice and Fel Armor upkeep,
  Nightfall and Backlash proc alerts, Life Tap and Soulshatter prompts, health/mana/threat
  bars, and a 7-icon cooldown row showing only what is down (Conflagrate and Shadowburn keep
  their ready glow). PvP layer: CC-on-me, target immunity, trinket clocks, per-opponent enemy
  mana for the drain decision.
- **tbc/hunter/all-specs.txt** — Serpent Sting and Hunter's Mark timers, Bestial Wrath and
  Rapid Fire windows, aspect-missing and back-to-Hawk alarms, Kill Command reactive prompt,
  pet health prompts, Misdirection/Feign Death threat pairing, proc tracker, and an 11-icon
  cooldown row showing only what is down (Multi-Shot and Arcane Shot keep their ready glow);
  BM and Survival only. PvP layer: CC-on-me, SILENCE NOW, trinket clocks, enemy mana.
- **tbc/priest/all-specs.txt** — Shadow Word: Pain and Vampiric Touch timers, Vampiric Embrace
  and Inner Fire uptime, Shadowform-missing alarm, Weakened Soul shield-timing on the heal target,
  Fade and Shadowfiend prompts, mana/health bars,
  plus the arena/BG-only PvP layer (CC-on-me colour-coded by CC category, Fear Ward and Mass
  Dispel prompts, trinket clocks, UA-on-ally warning, and a per-opponent enemy mana bar for
  the Mana Burn decision). The threat bar and Fade prompt do not load in an arena.
- **tbc/mage/all-specs.txt** — Arcane Blast stacks (the Arcane rotation driver), Arcane Power
  and Icy Veins burn-window timers, Ice Barrier uptime and missing alarm, Clearcasting proc,
  mana thresholds with Evocation/mana-gem prompts, Ice Lance shatter window, and a 10-icon
  cooldown row showing only what is down; Arcane and Frost only. PvP layer: CC-on-me
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
