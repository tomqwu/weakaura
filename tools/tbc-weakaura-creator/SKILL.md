---
name: tbc-weakaura-creator
description: Generate importable WeakAuras strings ("!WA:2!...") for World of Warcraft Classic / TBC Anniversary — any class, any spec. Use this skill whenever the user asks to create, modify, or debug WeakAuras (WA), wants an import string, mentions tracking buffs/debuffs/cooldowns/procs/resources/threat in Classic WoW, or wants a HUD for a WoW class. Also use it when iterating on a previously generated pack (adding auras, moving things, changing colors/animations) — the update-continuity rules here are what keep re-imports clean. Do NOT hand-write WA export strings or guess field names; always build through this skill's scripts.
---

# TBC WeakAura Creator

**Purpose: learn a spec's rotation — its best practices and key abilities — and render it as
a HUD that makes the player's next button press obvious. The pack is decision support; an
element that doesn't change what gets pressed next doesn't get built.** The machinery below
exists to serve that, not the other way around.

Builds real, importable WeakAuras strings programmatically: Lua factories construct the aura
data tables, then the exact WeakAuras serialization pipeline (LibSerialize → LibDeflate →
`!WA:2!` Base64) encodes them. Every generated string is round-trip decoded and structurally
verified before delivery. Proven across a long-running rogue HUD (bars, combo points, threat, alerts, animations)
and six more class packs — seven in total, each with a PvP layer — on a Chinese-language
client. Current versions are in the root README table rather than repeated here, so this
provenance line cannot go stale.

## Setup (once per session)

```bash
cd scripts && ./setup.sh    # fetches LibDeflate + LibSerialize, ensures lua5.1
```

## Core principles (non-negotiable)

1. **Spell IDs only, never names.** Aura triggers: `useExactSpellId` + all rank IDs as
   strings. Cooldowns: numeric rank-1 ID + `use_exact_spellName`. Names break on non-English
   clients and modern WA's name→ID resolution fails silently. See `references/spell-data.md`.
2. **UID continuity = clean updates.** Fixed `math.randomseed` per pack; never reorder or
   remove `W.uid()` calls between versions; new auras append new calls at the END. Same UIDs
   make the in-game import show "Update" instead of duplicating. Verify with
   `W.uidContinuity(encoded, prevFile)` plus `W.assertUidContinuity(...)` every version after
   the first. The repo suite also compares against the previous Git revision.
3. **Verify before delivering.** `W.verify(transmit, encoded)` (round-trip + structure) must
   pass. Deliver the string as a `.txt` file the user copies whole.
4. **internalVersion stays 45** (`tocversion 20501`). Modern WA migrates it forward on
   import — the same battle-tested path every old wago string takes. Don't modernize by hand.
5. **Check `references/gotchas.md` before using any enum, animation, or layout feature.**
   Several WA enums are inverted from their labels; guessing has burned us before.

## Workflow

1. **Start from the rotation, not from trackers.** Read `references/rotation-design.md`
   first — it is the core of this skill, not background reading. Learn the spec's priority
   rotation from a current-phase guide (never from memory, never from retail or 1.12
   knowledge), confirm it with the user, then map each rotation rule to exactly one HUD
   element using the table in that doc. An element that doesn't change which button gets
   pressed next doesn't get built. Before shipping, run the four-point usability test in that
   doc; a pack that fails it is not done, however cleanly it imports.
2. **Get spell IDs**: known IDs are in `references/spell-data.md`; anything else, verify on
   wowhead.com/tbc (all ranks for auras, rank 1 for cooldowns). Never trust memory for IDs.
3. **Write a build script** modeled on `scripts/example_paladin.lua`:
   - `F.group` top-level, sub-groups per concern (Buffs / Alerts / Resources / Cooldowns) —
     users drag whole groups, so grouping by concern matters.
   - `F.dynGroup` for anything that appears/disappears (cooldown rows gated by
     `spellknown`, alert stacks, cloned procs) so gaps auto-collapse.
   - Talent-specific cooldowns: gate with `load.use_spellknown` + the talent spell's ID —
     one pack then auto-adapts across specs. Prefer the ability's own rank-1 id over the
     spec capstone: it also hides the element while levelling. Every UNGATED element loads
     for every spec and must be justified for all of them — audit with
     `lua5.1 tools/spec-preview.lua <pack> pve`, which evaluates combined load and form gates
     for explicit level-70 exemplar profiles (live trigger state is intentionally out of scope).
   - Icon polish: `zoom = 0.3` + `F.subborder()` on every icon.
4. **Encode + verify + deliver**: `F.assemble` → `W.encode` → `W.verify` → write `.txt` →
   present the file. Tell the user: copy all → `/wa` → Import → paste.
5. **Iterate**: copy the previous build script, patch it, keep the seed, re-run, check
   `uidContinuity` (expected: all previous stable, only additions new). Remind the user that
   the Update dialog's *Arrangement* checkbox resets positions they dragged in game — either
   they uncheck it, or they report coordinates and you bake them into the script as defaults.

## Design language that works (from field testing)

Alerts (glowing prompt icons) in a vertical `grow="UP"` dyngroup beside the character, with
entrance/exit animations (`F.animPreset("slidebottom","0.3","easeOut")` in,
`F.animCustom("1", {y=150, alpha=0, scale=0.4}, "easeOut")` out). Condition-driven prompts
combine two triggers with `disjunctive="all"`: e.g. *threat ≥ 70% AND Feint ready*, *HP < 50%
AND Evasion ready*. Bars stacked flush (centers = height apart) with `F.subborder("bar")`.
Resource thresholds as thin `F.texture` lines over the bar with a lit layer that pops in
(`animPreset("shrink", ...)` — that key renders as "Grow"). Out-of-combat fade: extra
`F.unitCharTrigger()` + condition `inCombat == 0 → alpha 0.5`. Keep custom code at zero;
the only justified exception so far is a one-line `customTriggerLogic` for OR-of-events AND
a-state (Riposte pattern).

## Files

- `scripts/wa_lib.lua` — encode/decode/uid/verify (read its comments for envelope rules)
- `scripts/wa_factory.lua` — all region/trigger/subregion/condition/animation builders,
  every field verified against WA 3.5.0 source; skim it before building
- `scripts/example_paladin.lua` — canonical build-script shape; copy it as the starting point
- `references/rotation-design.md` — the mandatory step 1: rotation → element mapping
- `references/gotchas.md` — inverted enums, silent failures, preview illusions. Read fully
  the first time; consult before touching orientation, animations, strata, or clones.
- `references/encoding.md` — envelope/v1421-vs-v2000/UID mechanics in depth
- `references/spell-data.md` — verified TBC spell IDs + how to find more
