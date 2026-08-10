# WeakAuras gotchas (each one cost a debugging round — read before building)

## Inverted / misleading enums

- **Aurabar orientation**: `VERTICAL` anchors the fill at the TOP and grows DOWNWARD.
  Bottom-to-top (thermometer style) is `VERTICAL_INVERSE`. Horizontal is sane:
  `HORIZONTAL` = anchored left, grows right. Verified in AuraBar.lua's anchorAlignment table.
- **Start-animation presets**: the KEY describes the starting state, the UI label the motion.
  `preset = "shrink"` renders as the UI's **"Grow"** (pops in from small);
  `preset = "grow"` renders as **"Shrink"**. Same trap class as VERTICAL.
- **Dynamic group grow vs selfPoint**: setting `grow` alone is not enough — pair it or the
  stack anchors from its center and overlaps neighbors: UP→`selfPoint="BOTTOM"`,
  DOWN→TOP, RIGHT→LEFT, LEFT→RIGHT, HORIZONTAL/VERTICAL→CENTER.

## Silent failures

- **Animations without `duration` play in 0 seconds** — technically executed, visually
  nothing. Every start/main/finish animation needs `duration = "0.3"`-style string seconds.
- **Name-based cooldown triggers silently track spell 0.** Modern WA converts a string
  `spellName` via `GetSpellInfo(name)` at load; if that lookup fails (non-English client,
  spell not in book yet), the trigger watches nothing and never errors. Numeric rank-1 ID +
  `use_exact_spellName = true` + `use_ignoreoverride = true` is the only robust form.
- **Aura name matching dies on localized clients.** A zhCN client never matches
  "Slice and Dice". `useExactSpellId` + `auraspellids` (STRING array, all ranks) always works.
- **Classic rank names**: some effects embed the rank in the NAME itself (poisons:
  "Deadly Poison VII"), so even on English clients name matching per-rank is a trap.
  IDs sidestep it entirely.
- **Missing `parent` on a v2000 child** = orphaned aura on import. `F.assemble`'s byId walk
  catches it (asserts), but only if the child was registered — always `reg()` every table.

## The /wa editor preview lies

Selecting a group force-shows EVERY aura with placeholder data: all load conditions ignored,
identical fake durations (e.g. "55.1" on everything), threat shows an empty "%", clone slots
render simulated copies, mutually-exclusive auras all visible at once, and none of the
start/finish animations or condition logic runs realistically. **Never debug from preview** —
judge assembly there, judge behavior in combat. Warn the user preemptively or they will
report the preview as a bug (it happened three times).

## Layout & rendering

- **Frame strata**: raising groups to HIGH (5) draws them over unit frames — and also over
  bags, vendors, and quest panels, which users hate. Prefer repositioning; keep strata
  inherited (1). If something must be raised, raise only that one group.
- WA regions never eat mouse clicks; overlap is visual only.
- Sibling regions inside a group layer roughly by creation order — overlays (flash layers,
  threshold lines) created after the bars render above them. `blendMode = "ADD"` overlays
  survive ordering surprises.
- Child `xOffset/yOffset` are ignored inside dynamic groups; position via the group.
- Energy-threshold line positions are computed from MAX power (100). Talents that raise the
  cap (Vigor → 110) shift the geometry — recompute if the user respecs.

## Update / import mechanics

- Same UID ⇒ the import dialog offers **Update** (in-place upgrade); new UIDs ⇒ a duplicate
  group. Renaming an aura is safe if the UID is stable (WA matches by UID, applies the new id).
- The Update dialog's **Arrangement** category (checked by default) resets any positions the
  user dragged in game back to the string's defaults. Either they uncheck it, or you bake
  their reported coordinates into the build script.
- `internalVersion` above the user's installed WA triggers a "made with a newer version"
  warning; staying at 45 avoids it forever.
- Any `customTriggerLogic` / custom code shows a code-review panel on import (line count,
  complexity score). One clean line is fine; warn the user so the panel doesn't alarm them.

## Trigger logic patterns

- `disjunctive = "all"` needs EVERY trigger active — an always-active state feeder
  (`Unit Characteristics`) coexists fine; a sometimes-active one (bare threat trigger) gates
  visibility, which is often exactly the point (prompt = state A AND ability ready).
- OR-of-two-events AND a-state needs `disjunctive = "custom"` +
  `customTriggerLogic = "function(t) return (t[1] or t[2]) and t[3] end"` (Riposte pattern).
- Conditions evaluate in order; later matches overwrite the same property — put the most
  severe state last (70% orange, then aggro red). Condition `sub.N` refs point at subRegions
  indexes: APPEND new subregions, never insert before a referenced index.
- Threat trigger's unit argument is **`threatUnit`**, not `unit`. `threatpct` is scaled so
  100 = pulling aggro; stored vars: `threatpct` (number), `aggro` (bool), `status`.
- `showClones = true` on an aura trigger + a dynamic group parent shows every match
  separately (dual-wield weapon procs). Clones inside a STATIC group stack on one spot.
- OmniCC-style addons add their own numbers to any cooldown swipe — don't also add a `%p`
  subtext on cooldown icons or users get double numbers. Bars/buff icons: WA `%p` subtext,
  `cooldownTextDisabled = true`.
