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
| Rogue — All Specs | Combat · Assassination · Subtlety | v48 | 62 | [string](tbc/rogue/README.md#import-string-v48) · [raw](tbc/rogue/all-specs.txt) |
| Paladin — All Specs | Holy · Protection · Retribution | v10 | 48 | [string](tbc/paladin/README.md#import-string-v10) · [raw](tbc/paladin/all-specs.txt) |
| Druid — Bear, Resto & Balance | Feral tank · Restoration · Balance | v9 | 48 | [string](tbc/druid/README.md#import-string-v9) · [raw](tbc/druid/all-specs.txt) |
| Warlock — All Specs | Affliction · Demonology · Destruction | v8 | 44 | [string](tbc/warlock/README.md#import-string-v8) · [raw](tbc/warlock/all-specs.txt) |
| Hunter — BM & Survival | Beast Mastery · Survival | v9 | 52 | [string](tbc/hunter/README.md#import-string-v9) · [raw](tbc/hunter/all-specs.txt) |
| Priest — All Specs | Shadow · Holy · Discipline | v8 | 44 | [string](tbc/priest/README.md#import-string-v8) · [raw](tbc/priest/all-specs.txt) |
| Mage — Arcane & Frost | Arcane · Frost | v8 | 48 | [string](tbc/mage/README.md#import-string-v8) · [raw](tbc/mage/all-specs.txt) |

Every pack is class-gated and auto-adapts across the **supported builds listed in the table**
through Spell Known gates. The current product scope is primarily level-70 single-target
raid/dungeon play plus the explicitly documented PvP layer; AoE, levelling and omitted specs
are named in each pack README rather than implied by the `all-specs.txt` filename. Druid v7
also adds an active-form state gate so Cat never receives the Bear rotation, and **Druid v8
replaces the centre bar stack with unit orbs** — player and target portraits, ringed by health,
power and threat — freeing the middle of the screen. **Druid v9 is geometry only**: the orbs
adopt the canonical size shared by every pack (104px outer ring and a 46px portrait on *both*
clusters, at `x = ±260, y = -60`, drawn with the thicker `Ring_20px` arc), so the player and
target sides — and all seven classes — finally match.

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

- **tbc/rogue/all-specs.txt** — full HUD, v48 of a 48-iteration build: v48 **one shared orb
  geometry** (104 / 78 / 54 rings and a 46px portrait on both clusters and in every pack,
  on the fatter Ring_20px art — the player and target sides used to be different sizes, and
  so did every class pack), v47 **unit orbs**
  (player left, target right: live portraits ringed by health and energy — the 35/40
  threshold marks moved onto the energy ring — and, on the target, its own power bar plus
  your threat, replacing the centre bar stack so the middle of the screen is empty),
  combo pips (always-visible sockets, green→orange
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
  Shield uptime, v9 **unit orbs** (player left, target right: live portraits ringed by health,
  mana and — on the target — your threat, replacing the centre bar stack so the middle of the
  screen is empty) resized in v10 onto the **shared cross-pack orb geometry** (104/78 rings,
  46px portrait, ±260 clusters, Ring_20px art — identical in all seven packs, and identical on
  both clusters), the seal-twisting swing runway, and a 14-icon cooldown row that shows only
  what is
  unavailable (rotational buttons stay visible and glow when ready); Holy / Protection /
  Retribution adapt via Holy Shock, Holy Shield and Crusader Strike gates, and the row is
  spec-selective — a healing Holy paladin is not shown Consecration or Avenging Wrath. PvP
  layer: CC-on-me, HAMMER NOW, target immunity, trinket and Forbearance clocks, Cleanse.
- **tbc/druid/all-specs.txt** — **unit orbs** at `x = ±260` instead of a centre bar stack, at the
  shared v9 geometry (104px outer ring on both sides, 46px portraits, `Ring_20px` arcs): live
  player and target portraits ringed by health, primary power and (target side) threat, with the
  player's power ring form-adaptive — one ring reads mana, rage or energy as you shapeshift and
  recolours itself to match — plus the bear's 20/70 rage breakpoints as pips on that ring; the
  target cluster hides completely with no target. Lacerate stacks and Mangle debuff,
  Demoralizing Roar, Lifebloom/Rejuvenation/Regrowth
  timers, Moonfire and Insect Swarm, Omen of Clarity proc, and an 8-icon cooldown row showing
  only what is down (Mangle keeps its ready glow); Bear / Restoration / Balance gate on
  Mangle, Swiftmend and Moonkin Form, with every Bear element additionally requiring active
  Bear/Dire Bear form so Cat sees no tank HUD. PvP layer: CC-on-me, Barkskin-while-stunned,
  target immunity, trinket clocks, own Cyclone/Roots per opponent.
- **tbc/warlock/all-specs.txt** — the five own-DoT timers (Corruption, Curse of Agony,
  Immolate, Unstable Affliction, Siphon Life), Demonic Sacrifice and Fel Armor upkeep,
  Nightfall and Backlash proc alerts, Life Tap and Soulshatter prompts, player and target
  unit orbs (health and mana rings around a live portrait, plus a threat ring on the target) —
  v8 puts both clusters on the **one shared orb geometry** used by every pack (104 / 78 / 54
  rings and a 46px portrait on the fatter Ring_20px art) —
  and a 7-icon cooldown row showing only what is down. PvP layer: CC-on-me, target immunity,
  trinket clocks, per-opponent enemy mana for the drain decision.
- **tbc/hunter/all-specs.txt** — Serpent Sting and Hunter's Mark timers, Bestial Wrath and
  Rapid Fire windows, aspect-missing and back-to-Hawk alarms, Kill Command reactive prompt,
  pet health prompts, Misdirection/Feign Death threat pairing, proc tracker, player and
  target unit orbs (health and mana rings around a live portrait, the mana ring ticked at
  the two aspect-swap thresholds, plus a threat ring on the target; **v9 puts both clusters
  on the orb geometry shared by all seven packs** — 104/78/54 rings, 46px portraits, `±260`
  clusters, `Ring_20px` art — so the two sides match each other and every other class, and
  the aspect-swap ticks were re-derived onto the resized ring), and an 11-icon
  cooldown row showing only what is down (Multi-Shot and Arcane Shot keep their ready glow);
  BM and Survival only. PvP layer: CC-on-me, SILENCE NOW, trinket clocks, enemy mana.
- **tbc/priest/all-specs.txt** — Shadow Word: Pain and Vampiric Touch timers, Vampiric Embrace
  and Inner Fire uptime, Shadowform-missing alarm, Weakened Soul shield-timing on the heal target,
  Fade and Shadowfiend prompts, player and target
  unit orbs (health and mana rings around a live portrait, plus a threat ring on the target;
  **v8 puts both clusters on the orb geometry shared by all seven packs** — 104/78/54 rings,
  46px portraits, `Ring_20px` art — so the two sides match each other and every other class),
  plus the arena/BG-only PvP layer (CC-on-me colour-coded by CC category, Fear Ward and Mass
  Dispel prompts, trinket clocks, UA-on-ally warning, and a per-opponent enemy mana bar for
  the Mana Burn decision). The threat ring and Fade prompt do not load in an arena.
- **tbc/mage/all-specs.txt** — Arcane Blast stacks (the Arcane rotation driver), Arcane Power
  and Icy Veins burn-window timers, Ice Barrier uptime and missing alarm, Clearcasting proc,
  mana thresholds with Evocation/mana-gem prompts, Ice Lance shatter window, and a 10-icon
  cooldown row showing only what is down; Arcane and Frost only. **v7 replaces the centre
  health/mana/threat bar stack with two unit orbs** — a live portrait of you and of your
  target, each ringed by health and mana arcs, with threat as the outermost ring of the target
  orb and the target orb hiding itself entirely when you have no target, so the middle of the
  screen is free — and **v8 is geometry only**, putting both clusters on the **one shared orb
  size used by every pack** (104 / 78 / 54 rings, a 46px portrait, centres at `±260, -60`, all
  on the fatter `Ring_20px` art), with the Arcane conserve bead re-derived onto the resized
  mana ring. PvP layer: CC-on-me
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
