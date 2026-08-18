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
| Rogue — All Specs | Combat · Assassination · Subtlety | v62 | 67 | [string](tbc/rogue/README.md#import-string-v62) · [raw](tbc/rogue/all-specs.txt) |
| Paladin — All Specs | Holy · Protection · Retribution | v23 | 45 | [string](tbc/paladin/README.md#import-string-v23) · [raw](tbc/paladin/all-specs.txt) |
| Druid — Bear, Resto & Balance | Feral tank · Restoration · Balance | v18 | 45 | [string](tbc/druid/README.md#import-string-v18) · [raw](tbc/druid/all-specs.txt) |
| Warlock — All Specs | Affliction · Demonology · Destruction | v17 | 40 | [string](tbc/warlock/README.md#import-string-v17) · [raw](tbc/warlock/all-specs.txt) |
| Hunter — BM & Survival | Beast Mastery · Survival | v18 | 49 | [string](tbc/hunter/README.md#import-string-v18) · [raw](tbc/hunter/all-specs.txt) |
| Priest — All Specs | Shadow · Holy · Discipline | v17 | 41 | [string](tbc/priest/README.md#import-string-v17) · [raw](tbc/priest/all-specs.txt) |
| Mage — Arcane & Frost | Arcane · Frost | v17 | 44 | [string](tbc/mage/README.md#import-string-v17) · [raw](tbc/mage/all-specs.txt) |

Every pack is class-gated and auto-adapts across the **supported builds listed in the table**
through Spell Known gates. The current product scope is primarily level-70 single-target
raid/dungeon play plus the explicitly documented PvP layer; AoE, levelling and omitted specs
are named in each pack README rather than implied by the `all-specs.txt` filename. Druid v7
also adds an active-form state gate so Cat never receives the Bear rotation.

### The Sill — the vitals geometry every pack now shares

The health/power/threat display has been through five shapes: a centre bar stack, unit orbs,
one shared orb size, Diablo-style globes, and concentric rings around a live 3D portrait. All
seven packs now ship **the Sill** — a **164×36 instrument strip** (164×45 where the class has a
fourth, resource lane) sitting directly under your character:

| lane | size | reading rule |
|---|---|---|
| alarm rim | plate +4px per side | pulses red at ≥80% threat; drawn **first**, so only the rim shows |
| plate | 164×36 | a near-black ground, so 13px rails survive snow, lava and Shattrath at noon |
| threat | 160×5 | green → orange at 70 → red on aggro; **absent** when you are on no threat table |
| health | 160×13 | fill, exact % inside the rail, colour flips inside your defensive window |
| power | 160×13 | fill, exact % or raw value, with ability costs drawn as waterlines |
| resource | 5×(16×8) | rogue combo pips — since v58 on the **target’s nameplate**, falling back to the strip when no plate exists; mage arcane stacks; omitted where a class has none |

**A rail is 160px at 1.6 pixels per percent.** Every value these packs mark is a multiple of five
and 1.6 × 5 = 8, so every breakpoint lands on a whole pixel — arithmetic instead of the
trigonometry a ring needs —
the rogue's 35-energy mark moves from `(23.575, −17.128)` to `x = −24`. The strip also deletes
the 3D portrait — 1,936 px² carrying no decision — and puts every number on a dark bed instead of
on a moving model.

Rails fill **left to right** — `orientation = "HORIZONTAL"`. WeakAuras' own dropdown labels
`HORIZONTAL_INVERSE` as "Left to Right", and that label is wrong: in
`BaseRegions/LinearProgressTexture.lua`, `HORIZONTAL` maps the fill to texture-x `0 → progress`
(anchored left) while `HORIZONTAL_INVERSE` maps it to `1-progress → 1` (anchored right). Every
pack shipped inverted until this was checked in game.

Three facts the build pins by assertion, because all three are invisible in a screenshot when wrong:
`Square_White_Border.tga` is a **filled** square (64,516 of 65,536 pixels fully opaque), so the
threat alarm must be *larger than the plate and drawn underneath it* or it washes red over every
readout at exactly the moment you need to read them; and draw order is `controlledChildren`
order at +4 frame levels per child, so the flat transmit list must stay depth-first to match; and
the fill orientation, because an inverted rail still looks like a working bar.

**Long and thin is the point.** Earlier versions scaled the strip uniformly, which kept the
original 2.8:1 plate and simply made the same stubby block bigger — it read as a UI panel and was
rejected at both 300px and 200px rails. The fill’s *travel* is the signal; its thickness carries
nothing. 160×13 is 60% longer than the first 100px rails at less than half the area of the fat
version, and paladin’s clearance to its buff row went from 2px to 17px because the height came
out of the axis that was actually tight.

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

- **tbc/rogue/all-specs.txt** — full HUD, v62 of a 62-iteration build: since **v54 the Sill**
  (see the shared geometry above), at **164×45** because the rogue is one of the two packs whose
  strip carries a fourth lane. The **five combo pips** are 16×8 and since **v58 they ride the
  target’s nameplate** — combo points are a property of the target — falling back to their strip
  lane whenever no nameplate exists. Energy stays a **raw number, not a percent** — 35 and 40 are
  absolute costs — and its two breakpoints are waterlines the fill crosses at `x −24` and `x −16`,
  dim where the breakpoint is and lit the moment you can afford Eviscerate or Sinister Strike. The
  alarm rim is 172×53. Combo pips keep their green→orange gradient and the brief
  scale/brightness pop on gain, plus a
  spec-adaptive cooldown row
  (16 spells, talent-gated, tooltips + keybind labels), a **one-slot rotation lane** at the top of the left column showing only the top unmet
  priority (SnD about to expire → Rupture → Cold Blood → Eviscerate → your builder, each
  spec-gated on ability, the bottom rank always filling the slot so the lane is a next-button
  readout rather than an alert), animated alert flow (Riposte window, Feint-at-70%-threat,
  Evasion-below-50%-HP), weapon enchant proc tracker
  with clones, out-of-combat fade, plus the arena/BG-only PvP layer (CC-on-me with the
  break decision, Kick prompt and lockout bar, target immunity, trinket availability,
  enemy trinket countdowns, own Blind/Sap/Gouge per opponent, Wound Poison uptime).
  Locale-independent (pure spell-ID matching, built on a
  zhCN client). Combat / Mutilate / Subtlety auto-adapt via spell-known gates.
- **tbc/paladin/all-specs.txt** — seal uptime + missing alarm, own Judgement debuff, Holy
  Shield uptime, and since **v16 the Sill** (see the shared geometry above) at 102×31. This is
  the pack where the mana rail earns its pixels most: a Holy paladin has **no low-mana alert
  anywhere in the pack** — verified by decode, there is no `percentpower` trigger — so the rail
  and its **20% waterline** are the only mana signal there is. **v16 also gives the seal-twisting
  runway a mark you can see coming**: the twist window is an absolute 0.4s but the runway's
  length is your weapon speed, so the mark is placed by `subtick` at
  `tick_placement_mode = "AtValue"` — re-read against the live `maxValue` every update, correct
  at any weapon speed and under any haste — with the exact time left printed at one decimal
  beside it. The bar still turns gold inside the window as the fallback cue. **v17 then closes
  the other half of the cycle**: `Twist NOW` only ever fired while Seal of Command was *up*, so
  the moment you obeyed it the prompt vanished and nothing told you to re-apply SoC before the
  next swing — `Seal MISSING` stayed quiet because a seal *was* up. `RE-SEAL` is its mirror
  (swinging, SoC missing, a twist seal present), and it resolves its icon from the client rather
  than a hard-coded path, so it is correct on both factions. **v18 takes two ideas from
  [SwedgeTimer](https://github.com/hypernormalisation/SwedgeTimer)** (no code copied — rebuilt
  from WA primitives): the runway gains a **press** mark ahead of the **land** mark, because 0.4s
  is when the seal must land and the moment you press is 0.4s *plus your latency* — set it to
  your own ping in `/wa` — and a **GCD floor** at 1.5s past which no filler fits before the
  swing. Both twist prompts also gained WA's native Global Cooldown trigger and **grey out while
  the GCD is locked**, held out of the visibility test by a one-line trigger combinator, so a
  prompt you cannot obey reads as *wait* rather than *press*. **v19 then removes the swing
  runway entirely**, on the player's report that it did not read well in combat: a bar you
  cannot trust is worse than no bar when you are timing a 0.4s press against it, and SwedgeTimer
  does that one job with a swing-timer library and a live latency monitor no WA string can
  reproduce. `Twist NOW` and `RE-SEAL` stay — their seal-state half is independent of swing
  timing — but they do still read WA's Swing Timer trigger, so they inherit its accuracy. 45
  auras. Plus a 14-icon cooldown
  row that shows only what is
  unavailable (rotational buttons stay visible and glow when ready); Holy / Protection /
  Retribution adapt via Holy Shock, Holy Shield and Crusader Strike gates, and the row is
  spec-selective — a healing Holy paladin is not shown Consecration or Avenging Wrath. PvP
  layer: CC-on-me, HAMMER NOW, target immunity, trinket and Forbearance clocks, Cleanse.
- **tbc/druid/all-specs.txt** — since **v15 the Sill** (see the shared geometry above) at
  102×31. The power rail is **form-adaptive**: a single region whose Power trigger deliberately
  omits `use_powertype`, so it follows mana, rage or energy as you shapeshift and recolours for
  whichever it is actually reading, with the bear's **20 and 70 rage breakpoints as waterlines**
  at `x −30` and `x +20` instead of pips at 72° and 252° on a circumference. Threat keeps both
  spec gates (bear rail tank-inverted, caster rail green → orange at 70% → red on the flip) and
  the `threatvalue <= 0 → alpha 0` guard — this pack gates threat by spec rather than by
  party/raid, and it has no alarm rim, because it never had a threat flash to carry across.
  45 auras in, 45 out, every UID stable. Lacerate stacks and Mangle debuff,
  Demoralizing Roar, Lifebloom/Rejuvenation/Regrowth
  timers, Moonfire and Insect Swarm, Omen of Clarity proc, and an 8-icon cooldown row showing
  only what is down (Mangle keeps its ready glow); Bear / Restoration / Balance gate on
  Mangle, Swiftmend and Moonkin Form, with every Bear element additionally requiring active
  Bear/Dire Bear form so Cat sees no tank HUD. PvP layer: CC-on-me, Barkskin-while-stunned,
  target immunity, trinket clocks, own Cyclone/Roots per opponent.
- **tbc/warlock/all-specs.txt** — the five own-DoT timers (Corruption, Curse of Agony,
  Immolate, Unstable Affliction, Siphon Life), Demonic Sacrifice and Fel Armor upkeep,
  Nightfall and Backlash proc alerts, Life Tap and Soulshatter prompts, and — since **v14 —
  the Sill** (see the shared geometry above) at 102×31, which puts the two halves of the Life
  Tap decision on one object and one horizontal scale: health green with amber at 60%, mana
  blue with violet at 30%, one directly above the other so the trade is a single glance rather
  than a comparison between two arcs of different radius. 40 auras in, 40 out, every UID
  stable. Plus a 7-icon cooldown row showing only what is down. PvP
  layer: CC-on-me, target immunity, trinket clocks, per-opponent enemy mana for the drain
  decision.
- **tbc/hunter/all-specs.txt** — Serpent Sting and Hunter's Mark timers, Bestial Wrath and
  Rapid Fire windows, aspect-missing and back-to-Hawk alarms, Kill Command reactive prompt,
  pet health prompts, Misdirection/Feign Death threat pairing, proc tracker, and — since **v15 —
  the Sill** (see the shared geometry above) at 102×31. Both **aspect-swap breakpoints are now
  waterlines** at `x −30` and `x +30` — the 20% Go-Viper and 80% back-to-Hawk thresholds — placed
  by `x = value − 50` rather than by trigonometry from a ring radius, and as standalone textures
  rather than sub-regions they can finally carry their own load gates, which a sub-region cannot.
  49 auras in, 49 out, every UID stable. Plus an
  11-icon cooldown row showing only what is down (Multi-Shot and Arcane Shot keep their ready
  glow); BM and Survival only. PvP layer: CC-on-me, SILENCE NOW, trinket clocks, enemy mana.
- **tbc/priest/all-specs.txt** — Shadow Word: Pain and Vampiric Touch timers, Vampiric Embrace
  and Inner Fire uptime, Shadowform-missing alarm, Weakened Soul shield-timing on the heal target,
  Fade and Shadowfiend prompts, and — since **v14 — the Sill** (see the shared geometry above)
  at 102×31. The **40% health and 50% mana breakpoints become full-height waterlines** rather
  than pips at whatever angle the threshold implied on a circumference. This pack also gains a
  proper cluster group in the process: its vitals used to carry their screen offset smeared
  across four leaf regions, so the display could not be dragged or disabled as one object.
  41 auras in, 41 out, every UID stable, and it has no alarm rim because it never had a threat
  flash to carry across. Plus the arena/BG-only
  PvP layer
  (CC-on-me colour-coded by CC category, Fear Ward and Mass
  Dispel prompts, trinket clocks, UA-on-ally warning, and a per-opponent enemy mana bar for
  the Mana Burn decision). The threat ring and Fade prompt do not load in an arena.
- **tbc/mage/all-specs.txt** — Arcane Blast stacks (the Arcane rotation driver), Arcane Power
  and Icy Veins burn-window timers, Ice Barrier uptime and missing alarm, Clearcasting proc,
  mana thresholds with Evocation/mana-gem prompts, Ice Lance shatter window, and a 10-icon
  cooldown row showing only what is down; Arcane and Frost only. Since **v14 — the Sill** (see
  the shared geometry above) at **164×45**, the four-lane variant, because the mage is the second
  pack with a fourth lane: the **Arcane Blast stack counter moves off the buff row and into the
  strip** as a 160×8 lane fed by the debuff itself, so the lane's *length* is how long you have
  before the stack falls off while its three pips show how many you are holding — two facts in
  600 px² where the icon spent 1,600. The 30% conserve breakpoint becomes a waterline at
  `x −20` instead of a bead at the angle its threshold implied. 44 auras in, 44 out, every UID
  stable. PvP layer: CC-on-me
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
