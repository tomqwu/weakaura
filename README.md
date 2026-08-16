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
| Rogue — All Specs | Combat · Assassination · Subtlety | v53 | 58 | [string](tbc/rogue/README.md#import-string-v53) · [raw](tbc/rogue/all-specs.txt) |
| Paladin — All Specs | Holy · Protection · Retribution | v15 | 45 | [string](tbc/paladin/README.md#import-string-v15) · [raw](tbc/paladin/all-specs.txt) |
| Druid — Bear, Resto & Balance | Feral tank · Restoration · Balance | v14 | 45 | [string](tbc/druid/README.md#import-string-v14) · [raw](tbc/druid/all-specs.txt) |
| Warlock — All Specs | Affliction · Demonology · Destruction | v13 | 40 | [string](tbc/warlock/README.md#import-string-v13) · [raw](tbc/warlock/all-specs.txt) |
| Hunter — BM & Survival | Beast Mastery · Survival | v14 | 49 | [string](tbc/hunter/README.md#import-string-v14) · [raw](tbc/hunter/all-specs.txt) |
| Priest — All Specs | Shadow · Holy · Discipline | v13 | 41 | [string](tbc/priest/README.md#import-string-v13) · [raw](tbc/priest/all-specs.txt) |
| Mage — Arcane & Frost | Arcane · Frost | v13 | 44 | [string](tbc/mage/README.md#import-string-v13) · [raw](tbc/mage/all-specs.txt) |

Every pack is class-gated and auto-adapts across the **supported builds listed in the table**
through Spell Known gates. The current product scope is primarily level-70 single-target
raid/dungeon play plus the explicitly documented PvP layer; AoE, levelling and omitted specs
are named in each pack README rather than implied by the `all-specs.txt` filename. Druid v7
also adds an active-form state gate so Cat never receives the Bear rotation, v8 replaced the
centre bar stack with unit orbs, v9 put those orbs on one shared size, v10/v11 turned them
into Diablo-style globes and v12 brought the rings and the portraits back — and **Druid v13
deletes the target cluster and brings threat home**, at the geometry every pack now shares: one
cluster at `(-270, 40)` of a 100px **threat** ring, an 84px health ring and a 62px form-adaptive
power ring around a 44px **live 3D portrait**, with the percentages just outside the arcs because
a `model` region cannot carry text.

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

- **tbc/rogue/all-specs.txt** — full HUD, v53 of a 53-iteration build: since **v52 a single
  ring cluster**: the target cluster is deleted (its health duplicated the target frame and the
  nameplate for the whole game, and its ring track existed only to keep a spare UID alive) and
  **threat comes home as your own outermost arc**. Three concentric rings around a **live 3D
  portrait** of you at `(-270, 40)` — a 100px **threat** ring, an 84px health ring, a 62px
  energy ring and a 44px portrait — where `-270` is the tightest position the vertically-growing
  Alerts column cannot climb into at any stack depth (the cluster spans `x -320..-220` against
  the column's `-170..-130`). The energy ring keeps its **35/40 breakpoint marks on the
  circumference** (dim where the breakpoint is, lit the moment you can afford Eviscerate or
  Sinister Strike); threat is green, orange at 70%, red on aggro, with the percentage above the
  ring and the 80% halo resized onto it, party/raid-gated and never in an arena, so the common
  solo case is still two rings and a face. **v53 puts the health percentage in the middle of the
  cluster at 16pt, over your own face** — which needed the portrait moved to the *front* of the
  child list so the rings, and their text, draw above it; a ring paints only its own band
  (`r 42.19..50`, `35.44..42`, `26.16..31` against a portrait at `r 0..22`), so nothing of the
  face is covered. Raw energy takes health's old slot at 12pt, threat stays above the outer ring.
  62 auras become 58 at v52 with all 57 survivors keeping their UIDs, and 58 stay 58 through v53;
  the leftover `Rogue - Target Cluster` group must be deleted by hand once after updating. On
  the v47/v48 **unit orbs** the
  design returns to (they in turn replaced the centre bar stack), combo pips (always-visible sockets, green→orange
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
  Shield uptime, and since **v14 a single ring cluster**: the target cluster is deleted (its
  health duplicated the target frame and the nameplate for the whole game) and **threat comes
  home as your own outermost arc**. Three concentric rings around a **live 3D portrait** of you
  at `(-270, 40)` — a 100px **threat** ring, an 84px health ring, a 62px mana ring and a 44px
  portrait — where `-270` is the tightest position that the vertically-growing Alerts column
  cannot climb into at any stack depth (the cluster spans `x -320..-220` against the column's
  `-170..-130`). Threat is green, orange at 70%, red on aggro, with the percentage above the
  ring, party/raid-gated and never in an arena, so the common solo case is still two rings and
  a face. Since **v15 the health percentage prints in the middle of the cluster**, 16pt on your
  own portrait, which needed the portrait moved to the *front* of the child list so the rings —
  and their text — draw over it; a ring is an annulus, so the face stays visible and only the
  number lands on it. Mana moves up into the slot health left, at 12pt.
  48 auras become 45 with all 44 survivors keeping their UIDs; the leftover
  `Paladin - Target Rings` group must be deleted by hand once after updating from v13 or
  earlier (v15 removes nothing). Plus the seal-twisting swing
  runway and a 14-icon cooldown row that shows only what is
  unavailable (rotational buttons stay visible and glow when ready); Holy / Protection /
  Retribution adapt via Holy Shock, Holy Shield and Crusader Strike gates, and the row is
  spec-selective — a healing Holy paladin is not shown Consecration or Avenging Wrath. PvP
  layer: CC-on-me, HAMMER NOW, target immunity, trinket and Forbearance clocks, Cleanse.
- **tbc/druid/all-specs.txt** — since **v14 your health percentage sits in the middle of the
  cluster**, 16pt across your own portrait, which is the only opaque backdrop the HUD owns; that
  needed the portrait moved to the *front* of its group's `controlledChildren` (first = furthest
  behind) so the rings' text draws over the face instead of under it, and it hides nothing because
  an annulus's band starts at radius 26.16 while the face ends at 22. Power moves up into the slot
  health left, at 12pt; threat stays above its arc. Since **v13 a single ring cluster**: the target cluster is deleted
  (its health duplicated the target frame and the nameplate for the whole game, and its ring track
  existed only to keep the pair looking matched) and **threat comes home as your own outermost
  arc**. Three concentric rings around a **live 3D portrait** of you at `(-270, 40)` — a 100px
  **threat** ring, an 84px health ring, a 62px power ring and a 44px portrait — where `-270` is
  the tightest position the vertically-growing Alerts column cannot climb into at any stack depth
  (the cluster spans `x -320..-220` against the column's `-170..-130`). The power ring is
  **form-adaptive**: one arc follows mana, rage or energy as you shapeshift and is always coloured
  for what it is actually reading, with the bear's 20/70 rage breakpoints as pips on its
  circumference at 72° and 252°. Threat keeps both spec gates (bear ring tank-inverted, caster
  ring green → orange at 70% → red on the flip), the not-in-arena gate and the
  `threatvalue <= 0 → alpha 0` guard, with `%threatpct` above the ring — this pack gates threat by
  spec rather than by party/raid, and the guard plus the target-less trigger is what keeps the
  common case to two rings and a face. The percentages are sub-regions of the *rings*, since a
  `model` region cannot carry text — but v14 puts the health one over the portrait anyway, because
  the number only has to land on the face's pixels, not live on its region. 48 auras become 45
  with all 44 survivors keeping their UIDs; the leftover `Druid - Target Health Ring`,
  `Druid - Target Ring Track` and `Druid - Target Portrait` must be deleted by hand once after
  updating from v12 or earlier (v14 removes nothing). Lacerate stacks and Mangle debuff,
  Demoralizing Roar, Lifebloom/Rejuvenation/Regrowth
  timers, Moonfire and Insect Swarm, Omen of Clarity proc, and an 8-icon cooldown row showing
  only what is down (Mangle keeps its ready glow); Bear / Restoration / Balance gate on
  Mangle, Swiftmend and Moonkin Form, with every Bear element additionally requiring active
  Bear/Dire Bear form so Cat sees no tank HUD. PvP layer: CC-on-me, Barkskin-while-stunned,
  target immunity, trinket clocks, own Cyclone/Roots per opponent.
- **tbc/warlock/all-specs.txt** — the five own-DoT timers (Corruption, Curse of Agony,
  Immolate, Unstable Affliction, Siphon Life), Demonic Sacrifice and Fel Armor upkeep,
  Nightfall and Backlash proc alerts, Life Tap and Soulshatter prompts, and — **v12 —
  ONE ring cluster**, at absolute `(-270, 40)`: three concentric arcs around a 44px **live
  3D portrait** — **your threat** on a 100px outermost ring (green → orange at 70% → red on
  aggro, percentage above the cluster, pulsing halo at 80% on the same radius, party/raid
  only and never in an arena), health on the 84px ring (green, amber at 60%) and mana on the
  62px one (blue, violet at 30%) — the two halves of the Life Tap decision on one object.
  **v12 deletes the v11 target cluster** (its health duplicated the target frame and the
  nameplate) and moves threat onto your own rings rather than losing it; 44 auras → 40, every
  surviving UID byte-identical, and the README names the one leftover group to delete by hand
  after updating from v11 or earlier (v13 removes nothing). Since **v13 the health percentage
  prints in the middle of the cluster**, 16pt on your own portrait, which needed the portrait
  moved to the *front* of the child list so the rings — and their text — draw over it; a ring
  is an annulus, so the face stays visible and only the number lands on it. Mana moves up into
  the slot health left, at 12pt. Plus a 7-icon cooldown row showing only what is down. PvP
  layer: CC-on-me, target immunity, trinket clocks, per-opponent enemy mana for the drain
  decision.
- **tbc/hunter/all-specs.txt** — Serpent Sting and Hunter's Mark timers, Bestial Wrath and
  Rapid Fire windows, aspect-missing and back-to-Hawk alarms, Kill Command reactive prompt,
  pet health prompts, Misdirection/Feign Death threat pairing, proc tracker, and — **v13 —
  ONE ring cluster**, at absolute `(-270, 40)`: three concentric arcs around a 44px **live 3D
  portrait** — **your threat** on a 100px outermost ring (green → orange at 70% → red at 90% →
  deep red on aggro, percentage above the cluster, pulsing halo at 80% on the same radius,
  party/raid only and never in an arena), health on the 84px ring (green, red below 30%) and
  mana on the 62px one (blue, red at the 20% Go-Viper threshold, with both aspect-swap
  breakpoints marked on the arc's own circumference by trigonometry from the ring radius).
  **v13 deletes the v12 target cluster** (its health duplicated the target frame and the
  nameplate, and it still carried the old target-mana satellite as a track ring) and moves
  threat onto your own rings rather than losing it; 54 auras → 49, every surviving UID
  byte-identical, and the README names the one leftover group to delete by hand after updating.
  The percentages sit just outside the arcs, because a model region cannot carry text. Plus an
  11-icon cooldown row showing only what is down (Multi-Shot and Arcane Shot keep their ready
  glow); BM and Survival only. PvP layer: CC-on-me, SILENCE NOW, trinket clocks, enemy mana.
- **tbc/priest/all-specs.txt** — Shadow Word: Pain and Vampiric Touch timers, Vampiric Embrace
  and Inner Fire uptime, Shadowform-missing alarm, Weakened Soul shield-timing on the heal target,
  Fade and Shadowfiend prompts, and — since **v12** — **one ring cluster around a live
  portrait of you** at `(-270, 40)`: **threat on a 100px outermost ring** (green, orange at
  70%, red on aggro, hidden at zero threat and out of arena), health on the 84px ring, mana on
  the 62px one and your face at 44px, all four concentric. The v11 target cluster at
  `(+270, 110)` is **deleted** — target health was already on the target frame and the
  nameplate, so it duplicated the default UI — and threat moved to your own body because it is
  the one thing that cluster showed that nothing else does. Updating leaves three orphan auras
  to delete by hand (`Priest - Target Health`, `Priest - Target Track`,
  `Priest - Target Portrait`). Since **v13** the **health percentage sits dead centre on your
  portrait at 16px** with mana at 12px just under the outer ring: a model region cannot carry
  text, so every number is still owned by a *ring*, but the portrait was moved to the back of
  the cluster's draw order so a ring's text can land on the face (an annulus hides nothing —
  the bands are 26.2–31, 35.4–42 and 42.2–50 around a 22px face). The 40% health and 50% mana
  breakpoint marks are pips on their own ring at the angle the threshold implies. Plus the arena/BG-only
  PvP layer
  (CC-on-me colour-coded by CC category, Fear Ward and Mass
  Dispel prompts, trinket clocks, UA-on-ally warning, and a per-opponent enemy mana bar for
  the Mana Burn decision). The threat ring and Fade prompt do not load in an arena.
- **tbc/mage/all-specs.txt** — Arcane Blast stacks (the Arcane rotation driver), Arcane Power
  and Icy Veins burn-window timers, Ice Barrier uptime and missing alarm, Clearcasting proc,
  mana thresholds with Evocation/mana-gem prompts, Ice Lance shatter window, and a 10-icon
  cooldown row showing only what is down; Arcane and Frost only. v7 replaced the centre
  health/mana/threat bar stack with two unit orbs, v8 put them on the shared ring geometry,
  v9/v10 turned them into Diablo-style globes and v11 brought the rings and live portraits back
  — and **v12 deletes the target cluster**, leaving **one ring cluster around a live portrait of
  you** at `(-270, 40)`: **threat on a 100px outermost ring** (green, orange at 70%, red on
  aggro, a flare pulsing on it above 80%, the percentage 10pt above the cluster, hidden at zero
  threat and never loaded in an arena), health on the 84px ring, mana on the 62px one and your
  face at 44px, all five regions concentric. The v11 target cluster at `(+270, 110)` is gone —
  its health duplicated the target frame and the nameplate all game, and its outer track existed
  only to hold a UID — while threat moved onto your own body because it is the one thing that
  cluster showed that nothing else does. 48 auras → 44, every surviving UID unchanged, and
  updating leaves one group to delete by hand (`Mage - Target Cluster`, with its three
  children). **v13 makes the percentages readable**: health moves to the dead centre of the
  cluster at 16pt, drawn **on your portrait** instead of floating 54px below it on bare screen,
  and mana takes the vacated slot at 12pt (threat is unchanged at 10pt above the cluster). That
  required reordering the cluster so the **portrait draws first (furthest back)** rather than
  last — otherwise the face covers the health ring's own text and the move is invisible — which
  hides nothing, because no ring paints inside radius 26.16 and the face ends at 22.00. No aura
  added or removed and every UID stable. The Arcane conserve breakpoint is a bead on the mana
  ring's circumference at the angle its 30% threshold implies.
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
