# PvP on TBC: what WeakAuras can express (verified) — read before planning a PvP layer

Companion to `gotchas.md`. Everything below was read out of WeakAuras source, not docs:
current `main` pinned at **81b4c383697c6a4f2adad3db0f3588bc524a7019** (13 Aug 2026, IV 90),
cross-checked against tag **3.5.0** (IV 45, what our strings declare) and tags 5.0.0/5.1.0/
5.2.0/5.6.0 for version history.

Apply the repo's version principle every time (`CLAUDE.md`): **internalVersion governs data
migration only — the prototype that executes is the installed client's.** So emit the field
name the CURRENT prototype reads *after* Modernize has rewritten IV-45 data. Audited for
this layer: nothing migrates `load.size` at IV>=45 (the arena/ratedarena fix-up lives in the
`< 45` block), nothing migrates aura2's `auraspellids`/`useExactSpellId`, the item triggers'
`itemName`/`itemSlot`, or Crowd Controlled's `controlType`. Cast's spell filter *is* migrated
at `< 67` — and that migration is buggy (see gotchas), so emit the modern names.

Spell ids, item ids and zone ids below are **placeholders**. They are game data, not WA data:
verify every one on wowhead.com/tbc before it goes in a string (`spell-data.md` rules apply —
all ranks as strings for auras, numeric rank-1 for cooldowns, never a name).

---

## 1. Load gates

### 1.1 Arena only / battleground only / both

The load arg is `size` (UI label "Instance Size Type"), a multiselect over
`Private.instance_types`. Arena and BG **are** distinguishable — separate keys `arena` and
`pvp`. On TBC the legal values are exactly `none, party, ten, twenty, twentyfive, fortyman,
pvp, arena` (Types.lua deletes `ratedpvp`, `ratedarena`, `flexible`, `scenario` for Classic
flavors).

```lua
-- add to the pack's existing per-class load table (F.load already sets size = { multi = {} })
load = {
  use_class = true, class = { single = "ROGUE", multi = { ROGUE = true } },
  use_size = false,                                  -- false == MULTI mode. true = single, nil = gate off
  size = { multi = { arena = true, pvp = true } },   -- arena OR battleground
  spec = { multi = {} }, talent = { multi = {} },
}

--   arena only:        use_size = false, size = { multi = { arena = true } }
--   battleground only: use_size = false, size = { multi = { pvp   = true } }
```

`use_size = false` is not "off": multiselect load args are active for BOTH `true` and
`false` and only inert at `nil` (WeakAuras.lua L847). `false` selects multi mode, which ORs
the entries — that is the mode we want everywhere.

Never emit `ratedarena` / `ratedpvp`: `WeakAuras.InstanceType()` can only return them on
retail, so those keys can never match.

**Anything that reads `arena1..arena5` must be `arena`-only, not `arena + pvp`** — arena unit
ids do not exist in a battleground, so a BG-loaded arena element is a permanently blank slot.

### 1.2 Other gates worth knowing

```lua
use_pvpmode = true,          -- tristate: true = only while PvP flagged, false = only while NOT, nil = ignore
use_zoneIds = true, zoneIds = "559, 562, 572",   -- comma-separated ids, '-' prefix negates.
                                                 -- Read the live ids from /wa's "Player Location ID(s)" tooltip.
use_itemequiped = true, itemequiped = { 18854, 18864 },  -- NOTE: one 'p'. multiEntry array, OR-combined
```

`itemequiped` as an **array** is current-main only (3.5.0 took a scalar and no Modernize step
converts it). That is acceptable for this repo — the packs target a current client — but it
is the one load field here with a hard client-version floor.

### 1.3 Hiding PvE furniture inside arena (the inverse gate)

There is no "not arena" key; multi mode ORs, so the exclusion is spelled out as the other six
legal values:

```lua
use_size = false,
size = { multi = { none = true, party = true, ten = true, twenty = true,
                   twentyfive = true, fortyman = true } },
```

**VERIFY BEFORE SHIPPING THIS ONE.** WeakAuras.lua L1598-1626 only assigns `size = Type`
inside `if inInstance or instanceType ~= "none"`; what `size` holds in the open world was not
confirmed. If it is `nil` rather than `"none"` outdoors, this gate silently unloads the
element everywhere outside instances. Test in the field (open world → dungeon → BG) before
using it on anything a player relies on. `use_pvpmode = false` is the cheaper alternative
("hide while flagged"), at the cost of also hiding during world PvP.

---

## 2. Triggers that carry a PvP decision

Scaffolding for all of them: `data.triggers[i] = { trigger = <table>, untrigger = {} }`,
`activeTriggerMode = -10`, `disjunctive = "all"|"any"`. `type` routes the trigger system —
`"aura2"` goes to BuffTrigger2, everything else to GenericTrigger where `type` must equal the
prototype's own type (`unit`/`item`/`spell`/`event`/`combatlog`) and `event` the prototype key.

### 2.1 Cast — "my target is casting" (the interrupt prompt primitive)

```lua
{
  type = "unit", event = "Cast",
  unit = "target",                 -- player|target|focus|pet|party|raid|group|boss|arena|nameplate|member
  use_unit = true,

  -- optional spell filter, exact ids (preferred, locale-proof):
  use_spellIds = true, spellIds = { "12824", "12825", "12826" },
  -- or by name (rank-agnostic, but name matching is banned in this repo):
  -- use_spellNames = true, spellNames = { "Polymorph" },

  -- optional: only fire near the end of the cast
  use_remaining = true, remaining = "1.5", remaining_operator = "<",
}
```

State: `unit, spell, spellId, name, icon, duration, expirationTime, progressType ("timed"),
castType, sourceUnit/sourceName, destUnit/destName, npcId, class, raidMark…`
Conditions: `expirationTime` (display "Remaining Duration", type `timer` — this is the
remaining-cast-time check), `duration`, `paused`, `spellId` (number, only_equal), `spell`,
`castType`, `class`, `npcId`, `destUnit`, `raidMarkIndex`.

```lua
-- "kick window": last second of the cast
conditions = {
  { check = { trigger = 1, variable = "expirationTime", op = "<", value = "1" },
    changes = { { property = "sub.1.glow", value = true } } },
}
```

TBC uses native `UNIT_SPELLCAST_*` events for every unit (the LibClassicCasterino path was
Classic-Era only in 3.5.0 and is gone from main), so target/focus/arena casts are real.

### 2.2 Action Usable ("Spell Usable") — can I actually press the interrupt

This is the trigger an interrupt prompt wants, because it folds cooldown **plus resource
plus range** into one boolean. It is what makes "no energy to Kick the heal" visible.

```lua
{
  type = "spell", event = "Action Usable",
  use_spellName = true, spellName = 1766,        -- NUMERIC rank-1 id, never a name
  use_exact_spellName = true, use_ignoreoverride = true,
  use_targetRequired = true,                     -- optional
}
```
State/conditions: `charges`, `spellCount`, `spellInRange` (bool), `readyTime`, `name`, `icon`.

### 2.3 Crowd Controlled — CC on the player, including school lockouts

The only non-custom-code way to see CC *generically*, with a real duration and without
enumerating spell ids — and the only way to see a Kick/Counterspell school lockout at all
(a lockout is not an aura, so aura2 can never find it).

```lua
{
  type = "unit", event = "Crowd Controlled",
  use_controlType = true,
  controlType = "SCHOOL_INTERRUPT",   -- NONE|CHARM|CONFUSE|DISARM|FEAR|FEAR_MECHANIC|PACIFY|
                                      -- SILENCE|PACIFYSILENCE|POSSESS|ROOT|SCHOOL_INTERRUPT|
                                      -- STUN|STUN_MECHANIC
  -- use_interruptSchool = true, interruptSchool = 2,   -- only with SCHOOL_INTERRUPT
  -- use_inverse = true,                                -- show while NOT controlled
}
-- omit use_controlType entirely to match ANY loss-of-control effect
```

State: `controlType, interruptSchool, lockoutSchool, name (displayText), spellName, spellId,
icon, duration, expirationTime`. Conditions: `controlType` (select), `spellName`, `spellId`,
`lockoutSchool`, `expirationTime` (timer), `duration`.

Select conditions compare the **key** from the values table, not a localized label:

```lua
{ check = { trigger = 1, variable = "controlType", op = "==", value = "STUN" },
  changes = { { property = "sub.1.glowColor", value = { 1, 0.15, 0.15, 1 } } } },
```

**Version-sensitive — the one item in this file that needs a live smoke test.** WA 3.5.0
through 5.1.x deleted this prototype on Classic/BCC; 5.2.0 ungated it, and current main only
prunes `Alternate Power` and `Death Knight Rune` on TBC. So a current client registers it and
calls `C_LossOfControl` — but WA source cannot prove the 2.5.x client populates that API. Get
sapped and kicked in a duel and confirm before a HUD element depends on it.

### 2.4 aura2 — CC by id, arena-unit auras, clone rows

```lua
-- CC on me by exact id (the version-proof fallback to Crowd Controlled)
{ type = "aura2", unit = "player", debuffType = "HARMFUL",
  useExactSpellId = true, auraspellids = { "118", "12824", "6770" },   -- STRINGS
  matchesShowOn = "showOnActive" }

-- one specific opponent
{ type = "aura2", unit = "member", specificUnit = "arena1", debuffType = "HARMFUL",
  useExactSpellId = true, auraspellids = { "12826" },
  matchesShowOn = "showOnActive", unitExists = false }

-- ALL arena opponents at once: one clone per matching unit (needs a dynamicgroup parent)
{ type = "aura2", unit = "arena", debuffType = "HARMFUL",
  useExactSpellId = true, auraspellids = { "12826" },
  showClones = true, combinePerUnit = true, perUnitMode = "affected" }
```

`ownOnly = true` restricts to auras cast by me/my pet (`false` = only *other* people's, `nil`
= any). State/conditions as in the packs already: `expirationTime`, `stacks`, `spellId`,
`unitCaster`, `matchCount`, `debuffClass`, …

arena1..5 are first-class on TBC: `Private.baseUnitId["arena"..i]` and
`Private.multiUnitUnits.arena` are populated for TBCOrWrathOrCataOrMistsOrRetail, and
BuffTrigger2 registers `ARENA_OPPONENT_UPDATE`. The scan is a full `UnitAura(unit, index,
filter)` walk, so anything the API exposes is found.

### 2.5 Trinket cooldown — by item id, or by slot

```lua
-- (a) one specific item id per trigger. N ids => N triggers + triggers.disjunctive = "any"
{ type = "item", event = "Cooldown Progress (Item)",
  itemName = 18854,                      -- NUMERIC item id (required arg)
  use_itemName = true,
  genericShowOn = "showOnCooldown",       -- REQUIRED: showOnCooldown|showOnReady|showAlways
  use_genericShowOn = true }

-- (b) the slot, id-agnostic (faction/season proof)
{ type = "item", event = "Cooldown Progress (Equipment Slot)",
  itemSlot = 13,                          -- 13 = TRINKET0SLOT, 14 = TRINKET1SLOT
  genericShowOn = "showOnCooldown", use_genericShowOn = true }
```

State (both): `itemId, name, icon, duration, expirationTime, enabled, gcdCooldown`.
Conditions: `expirationTime` (timer), `duration`, `onCooldown` (bool), `itemId` (number,
only_equal), `name`.

Trade-off, decide per pack: (a) is exact but needs the full verified id list (both factions,
both PvP trinket families, every season) and one trigger each; (b) is one trigger but tracks
**whatever is in the slot**, so a PvE on-use trinket in the other slot will drive the readout
and tell the player their medallion is down when it is not. In a HUD whose whole purpose is
"is my get-out-of-jail available", that false negative is a death — prefer (a), and fall back
to (b) only with a condition on `itemId` or a `use_itemequiped` load gate.

### 2.6 Spell Cast Succeeded — the enemy-cooldown *inference*

No API on 2.5.x reads another player's cooldowns. The sanctioned approximation is: see the
cast, start your own countdown.

```lua
{ type = "event", event = "Spell Cast Succeeded",
  unit = "arena", use_unit = true,          -- "arena" => one clone per opponent (dynamicgroup!)
  use_spellId = true, spellId = { "42292" },
  duration = "120" }                        -- REQUIRED, string seconds. Missing => 1s flash
```
State: `unit, spellId, icon, name` + the timed `duration`/`expirationTime`.

### 2.7 Combat Log — "my interrupt landed" (the school-lockout window)

`SPELL_INTERRUPT` is the cheapest kill-window signal in the game and no unit-state trigger
can produce it. You supply the lockout length yourself.

```lua
{ type = "combatlog", event = "Combat Log",
  subeventPrefix = "SPELL", subeventSuffix = "_INTERRUPT",
  duration = "8",                              -- REQUIRED. Counterspell 8s, Kick 5s — verify each
  use_sourceUnit = true, sourceUnit = "player",  -- or "pet" for felhunter Spell Lock
  use_spellId = true, spellId = { "2139" } }

-- "a hostile player just applied a debuff to me"
{ type = "combatlog", event = "Combat Log",
  subeventPrefix = "SPELL", subeventSuffix = "_AURA_APPLIED", duration = "5",
  use_destUnit = true, destUnit = "player",
  use_sourceFlags2 = true, sourceFlags2 = "Hostile",   -- Hostile|Neutral|Friendly
  use_sourceFlags3 = true, sourceFlags3 = "Player" }   -- Player|NPC|Pet|Guardian|Object
```

State: `sourceGUID/sourceName/sourceFlags, destGUID/destName/destFlags, spellId, spellName,
spellSchool, extraSpellId/extraSpellName` (the interrupted spell, for `_INTERRUPT`/`_DISPEL`),
`missType, amount, icon, cloneId`.

### 2.8 The rest, in one line each

- **Health** — `{ type = "unit", event = "Health", unit = "arena1", use_specific_unit = true,
  use_unit = true }`; also `unit = "arena"` for clones. Conditions on `percenthealth`,
  `health`, `deficit`. TBC listens on `UNIT_HEALTH_FREQUENT`; every absorb field is retail.
- **Unit Characteristics** — enemy `class` (select), `hostility` (hostile/friendly),
  `character` (player/npc), `level`, `dead`, `attackable`, `inCombat`. Enemy CLASS is
  readable; enemy SPEC is not. Also the repo's always-on `inCombat` feeder.
- **Range Check** — `{ type = "unit", event = "Range Check", unit = "target",
  use_range = true, range = "8", range_operator = "<=" }`. `"<="` tests `max <= N`, anything
  else tests `min >= N`. Runs on **FRAME_UPDATE**: at most one per pack, always behind an
  arena/BG load gate. Estimate only (LibRangeCheck) — never build a hard gate on it. No
  `arena` multi-unit value.
- **Conditions (unit)** — always-on feeder with `use_pvpflagged`, `use_incombat`,
  `use_ismoving`, `use_alive`. Its own `instance_size`/`instance_type` args are deprecated
  and retail-gated: use the LOAD gate `size`, never these.

---

## 3. PvP gotchas (each one is a silent failure)

- **Interruptibility does not exist on TBC.** The Cast prototype's `interruptible` arg is
  `enable = function(trigger) return not (trigger.use_inverse or WeakAuras.IsTBC()) end,
  hidden = WeakAuras.IsTBC()`. ConstructFunction skips `enable = false` args, so on a TBC
  client you get neither the filter nor the state variable nor the condition. Emitting
  `use_interruptible` does nothing at all. Design interrupt prompts around "is casting" +
  "my interrupt is usable", and accept fake-casts as a player skill, not a HUD feature.
- **Cast's IV<67 migration is broken** — it branches on `t.useExactSpellId` while the options
  UI has always stored `use_exact_spellId`, so legacy exact-id data degrades to NAME matching.
  Emit `use_spellIds` / `spellIds` (or `spellNames`) directly; nothing rewrites those.
- **`auraspellids` without `useExactSpellId = true` is discarded**, and the trigger then falls
  into the catch-all branch and fires on ANY harmful aura. Always emit both, ids as STRINGS.
- **aura2 `debuffType` defaults to `"HELPFUL"`** — a CC trigger that forgets it watches buffs.
- **Do not filter CC by `debuffClass`.** It is UnitAura's dispel type, and non-retail maps nil
  to `"none"`; physical CC (Sap, Kidney Shot, Hammer of Justice) has no dispel type and is
  silently missed by a magic filter. Filter by exact ids. (Note the shape differs from generic
  multiselects: `debuffClass = { magic = true }`, not `{ multi = {...} }`.)
- **School lockouts are not auras.** Kick/Counterspell/Silencing Shot produce no debuff, so
  aura2 cannot see them on anyone. Own lockouts: Crowd Controlled `SCHOOL_INTERRUPT`. Lockouts
  you applied: Combat Log `_INTERRUPT` + your own duration.
- **`genericShowOn` is required** on both item cooldown triggers; nil means the aura never
  shows. Same trap as the spell version.
- **Item cooldowns must be the numeric id.** A name string reaches
  `C_Container.GetItemCooldown("Insignia of the Horde")` → nil → never fires.
- **`duration` is mandatory on every timedrequired trigger** (Combat Log, Spell Cast
  Succeeded). Missing = 1 second = a flash nobody sees.
- **Number args need an explicit `_operator`** — `remaining_operator`, `range_operator`,
  `percenthealth_operator`. singleTest falls back to `==`, which is never true.
- **`unit = "arena"` (and group/nameplate) makes clones.** Clones inside a STATIC group stack
  on one spot — always give a clone source a `dynamicgroup` parent.
- **Arena-unit triggers need arena-only load gates**; in a BG they are dead weight.
- **aura2 hostility filtering only applies to group/nameplate units** — `useHostility` on a
  target/arena/member aura trigger is silently ignored. Use a separate Unit Characteristics
  trigger on `hostility`.
- **`use_unit`/`use_specific_unit` shapes**: on generic prototypes a specific unit is encoded
  as the literal unit id in `unit` plus `use_specific_unit = true`; on aura2 it is
  `unit = "member"` plus `specificUnit = "arena1"`.
- **Group-level load is not a child gate.** The repo convention is one load table per aura;
  gate every PvP child individually, which is also what lets dynamic-group gaps collapse.

---

## 4. Not possible without custom code (do not fake these)

- **Diminishing returns.** A full-text search of the WA working tree for `diminish`, `DRList`,
  `LibDR` returns ZERO hits — no prototype, no type table, no bundled library. DR needs a
  custom trigger maintaining its own category→timer table (LibDRList-1.0). And do NOT fake it
  with an 18s aura timer: that models the reset window, not the category state, and it is
  wrong the moment two spells share a category. An incomplete DR tracker is worse than none,
  because it gets trusted.
- **"Only show casts I can interrupt."** Disabled on TBC by WA itself (see gotchas).
- **Enemy spec / talents / PvP talents.** `PvP Talent Selected` and `Class/Spec` are deleted
  for all Classic flavors; Unit Characteristics' `specId` is Cata+; aura2's `useArenaSpec` is
  retail. Enemy *class* is available, enemy *spec* is not.
- **Enemy cooldowns.** No API reads another player's cooldowns on 2.5.x. Only the Spell Cast
  Succeeded inference (see 2.6) — a countdown you start when you SEE the cast.
- **Rated arena / rated BG as load values.** Deleted from `instance_types` on TBC; `size` can
  only ever be `arena` or `pvp`.
- **Instance difficulty to tell arena from BG.** WeakAuras.lua force-zeroes `difficultyIndex`
  in PvP ("WORKAROUND Tol'Viron arena returning a difficulty index of 1"). Use `size`.
- **Range check against arena units / a per-opponent range column.** `unit_types_range_check`
  is pet/member/target/softenemy/softfriend/focus — no `arena` multi-unit. Unit
  Characteristics' `inRange` is retail-gated and dead on TBC.
- **One item-cooldown trigger covering several trinket ids.** `itemName` has no `multiEntry`.
  N triggers with `disjunctive = "any"`, or the equipment-slot variant.
- **Enemy mana as a verified primitive.** The Power prototype's unit arg was NOT verified for
  arena units in this pass. It is the highest-value remaining unknown (Mana Burn / Viper Sting
  / Drain Mana all read it) — verify it before planning around it.

---

## 5. What is worth building (apply `rotation-design.md`, unchanged)

The bar does not move because it is PvP: **every element must change which button gets pressed
next**, each spec must get a HUD that looks purpose-built, and the HUD must be quiet when
nothing needs doing. PvP raises the stakes on rule 4 — a player deciding inside a 3-second
stun window parses colour, size and screen position, never text.

Build (all of it is reachable with §2 and zero custom code):

| Decision | Element | Primitive |
|---|---|---|
| Trinket: spend or hold | trinket-down readout, absence = ready | 2.5 (a), showOnCooldown |
| Which break works right now | CC-on-me prompt, colour-coded by `controlType`, with countdown | 2.3 |
| Their trinket is down = go | 2-minute countdown per opponent | 2.6, `unit = "arena"` clones |
| Interrupt the healer | prompt = target casting AND interrupt *usable* | 2.1 + 2.2 |
| The go is open | school-lockout window bar after my interrupt lands | 2.7 `_INTERRUPT` |
| Stop into immunity | alert when the target gains a listed immunity | 2.4 `unit = "target"` |
| Hold damage / CC is running | my own CC on each opponent, with remaining | 2.4 `unit = "arena"` clones |
| Healing reduction uptime | own-only stack + timer on the kill target | 2.4 `unit = "target"` |

Cut (they fail the bar, whatever the PvP wishlist says): enemy team health bars and frames
(Gladius owns them), a wall of 20+ enemy cooldown icons, "they trinketed!" as a one-shot flash
with no countdown, damage meters, pre-cast constants, **threat in arena**, cast bars for spells
you cannot interrupt right now, DoT timers on non-kill targets, trinket/enchant proc rows,
uptime percentages, and anything that requires reading a word under pressure.

Placement follows the existing pack language: prompts are glowing icons in the `Alerts`
dynamic group (`slidebottom` 0.3s entrance, `y150 / alpha 0 / scale 0.4` 1s exit); state
readouts are bars or icon timers; every icon gets `zoom = 0.3` and a `F.subborder()`; clone
sources get their own dynamic group. Add the arena/BG gate from §1.1 to **every** PvP child,
and nothing to the PvE children — a PvP layer that leaks into raid is the same failure as an
ungated spec element.
