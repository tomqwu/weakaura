-- patch-v61.lua — THE LANE. One slot, eight ranked prompts, the engine picks the winner.
--
-- Run: lua5.1 tbc/rogue/patch-v61.lua   (rewrites all-specs.txt in place)
-- Replayed by generate.lua after patch-v58. Hand-picked uid literals only; the pack keeps
-- its registered seed 20260809 and claims no new one.
--
-- ============================================================================================
-- THE REPORT THIS ANSWERS (zhCN, verbatim): "类似影袭和刺骨战斗贼的rotation你并没有在左边
-- highlight when it's useable" — for a COMBAT rogue, the rotational buttons are never
-- highlighted on the left when they become usable.
--
-- 刺骨 = Eviscerate. 影袭 is settled ON THIS DISK, not from the web:
--   * Cell/Utils.lua:2225   ["ROGUE"] = 1752, -- 影袭      (zhCN comment, class harm spell)
--   * Questie zhCN quest 14010 ("刺骨"): "记住，刺骨需要连击点数，所以你需要先对训练假人
--     使用影袭" — Eviscerate needs combo points, so use 影袭 first. That is the level-1
--     builder, i.e. Sinister Strike 1752, NOT 出血/Hemorrhage 16511 and not Backstab.
-- One reading exists, so only one was built.
--
-- THE STRUCTURAL GAP. "Rogue - Alerts" held seven children and every one of them was reactive
-- or defensive (SnD MISSING, Riposte, Feint, Evasion Prompt, CC ON ME, KICK NOW, TARGET
-- IMMUNE). "Rogue - Cooldowns" is sixteen icons that are ALL genericShowOn = "showOnCooldown",
-- so an ability DISAPPEARS the moment it becomes usable — correct for cooldowns
-- (references/rotation-design.md:97, "show what the player CANNOT press") and exactly why
-- "usable now" had no home. The only affordability signal was the energy rail's 35/40
-- waterlines, which say you CAN pay, never that the points are worth spending.
--
-- ============================================================================================
-- WHY A ONE-SLOT LANE AND NOT A SECOND ALERT COLUMN
--
-- A new dynamic group with sort = "none", useLimit = true, limit = 1 draws the FIRST child in
-- controlledChildren order that is both loaded and triggered, and hides every other. Verified
-- in the installed WeakAuras 5.21.10, not assumed:
--   * sorters.none composes SortAscending({"dataIndex"})              DynamicGroup.lua:281-286
--   * dataIndex IS the index in controlledChildren                    DynamicGroup.lua:1180,1214
--   * sortedChildren only ever receives children whose region toShow  DynamicGroup.lua:1220-1246
--   * local limit = data.useLimit and data.limit or math.huge
--     ... local numVisible = min(limit, #regionDatas) ... if i <= numVisible then
--                                                        DynamicGroup.lua:611-640 (DOWN branch)
--   * everything the grow function did not place is hidden outright:
--         child.controlPoint:SetShown(false)                          DynamicGroup.lua:1520-1522
-- So this is a priority list evaluated by the engine, with zero custom Lua beyond the
-- one-line customTriggerLogic strings the pack already ships, and no new import review gate.
--
-- THE CONSEQUENCE THAT PAYS FOR IT: ORDERING REPLACES CLAUSES. A stacking column would have
-- needed an "SnD remaining > 3" aura2 trigger on four separate prompts to stop them shouting
-- over the Slice and Dice prompt. In the lane, SnD is rank 1, so that clause is deleted from
-- every child below it — four triggers gone, and the mutual exclusion is structural instead
-- of hoped-for.
--
-- WHAT DID NOT EARN A SLOT (the lane membership rule: a prompt may enter a ranked one-slot
-- surface only if OBEYING IT MAKES IT FALSE WITHIN ONE GCD):
--   * A standing Sinister Strike / Mutilate / Hemorrhage "usable" prompt. It would be lit for
--     ~90% of a fight, which teaches the player to ignore the whole column. The honest 影袭
--     answer is ranks 7/8: the builder icon, shown only while energy is about to overflow.
--   * "Build for SnD at 0 CP". At zero points the correct press is the builder whether or not
--     SnD is dying, so the prompt never changes the button. Ranks 7/8 already cover the case
--     it was invented for, at zero extra cost.
--   * A second SnD prompt at rem < 6. Rank 1 fires at 3s = three GCDs of warning and the buff
--     row already glows SnD at <= 5s.
--   * A Backstab positional. There is no API: grep -rniE 'behind|GetPlayerFacing|UnitPosition'
--     over 5.21.10 finds only Model:SetFacing, UI_ERROR_MESSAGE is absent from
--     Private.chat_message_types, and IsUsableSpell does not encode facing.
--   * Adrenaline Rush / Blade Flurry / Preparation / Vanish "ready". They fail the membership
--     rule by minutes and stay in the showOnCooldown row.
--
-- GREY HAS EXACTLY ONE MEANING IN THIS PACK: YOU CANNOT PAY FOR THIS YET. No GCD desaturation
-- (a rogue's wait state is energy, not the global; strobing the one slot for 1s of every GCD
-- is what usability test 4 forbids) and no spellInRange desaturation (a rogue holding combo
-- points is in melee range).
--
-- NO ANIMATIONS, AND animate = false ON THE GROUP. The alert column's language is slidebottom
-- in / fly-out — right for a prompt whose APPEARANCE is the signal, wrong for a slot that is
-- occupied most of a fight and swaps contents several times a cycle. A finish animation would
-- also visibly delay the Cold Blood -> Eviscerate handoff.
--
-- SUPPRESSED LANE CHILDREN STILL RUN THEIR ACTIONS. RegionPrototype.lua:1154 calls
-- Private.PerformActions(data, "start", region) inside Expand(), and the group hides the
-- over-limit child AFTERWARDS. A sound or TTS on rank 6 would fire while rank 1 is on screen.
-- So: no lane child may carry a sound, TTS or chat action — asserted below, not remembered.
--
-- ============================================================================================
-- FIELD FACTS, EACH GREPPED FOR WHERE IT IS *READ* (three silent no-ops have shipped in this
-- repo from trusting a plausible name: anchorXOffset, HORIZONTAL_INVERSE, and the "target"
-- nameplate token)
--
--   POWER THRESHOLDS MUST BE TABLES. The Power prototype's `power` arg carries
--   multiEntry = { operator = "and", limit = 2 } (Prototypes.lua:3979-3991), and ConstructTest
--   only builds a test when `type(trigger[name]) == "table" and #trigger[name] > 0`
--   (GenericTrigger.lua:296-298); a scalar leaves `test` nil and it is discarded at :337-339,
--   degrading the trigger to "the unit exists". The shipped combo pips survive scalars only
--   because internalVersion 45 < 70 makes Modernize migrate them (Modernize.lua:1958-1993,
--   migrateToTable). migrateToTable is a no-op on a value that is already a table, so the
--   table form is correct WITH the migration and correct without it. F.powerTrigger's own
--   minValue argument emits scalars (wa_factory.lua:88-97) and is therefore never used here.
--
--   COMBO POINTS ARE TARGET-RELATIVE ON THIS BRANCH.
--   `local power = GetComboPoints(unit, unit .. '-target')` (Prototypes.lua:3854-3860) is the
--   only GetComboPoints call site; the retail-only `trigger.unit == 'player'` branch at :3823
--   does not apply. So CP >= 4 already implies a target you have been hitting.
--
--   useRem TURNS A TRIGGER ON BY ITSELF. trigger.useRem/remOperator/rem are read at
--   BuffTrigger2.lua:3113-3114 and scheduled through remainingCheck (:3229) by
--   calculateNextCheck, so the trigger fires as the buff crosses the line. A condition could
--   never do this — a condition cannot make an aura appear.
--
--   useRem IS DROPPED SILENTLY UNDER showOnMissing. CanHaveMatchCheck returns false for
--   showOnMissing (BuffTrigger2.lua:212-224) and gates useRem at :3113. That is why rank 1 is
--   two SnD triggers ORed in customTriggerLogic and not one clever one.
--
--   ownOnly IS THE ONE OPTION THAT SURVIVES showOnMissing. createScanFunc gates useStacks,
--   use_stealable, use_debuffClass and friends behind canHaveMatchCheck, but the ownOnly
--   branch at BuffTrigger2.lua:2889-2894 is tested bare and emits
--   `if matchData.unitCaster ~= 'player'/'pet'/'vehicle' then return false end`.
--
--   NO TARGET ⇒ NO PROMPT. `showIfInvalidUnit = trigger.unitExists or false` for any
--   non-player unit (BuffTrigger2.lua:3127-3130), consumed at :1541-1542. The field is the
--   bare `unitExists`; `use_unitExists` is read nowhere.
--
--   iconSource > 0 READS A TRIGGER'S STATE ICON. Icon.lua:511-513
--   `iconPath = self.states[triggernumber].icon`, and region.states[n] is filled for EVERY
--   trigger index regardless of activeTriggerMode (WeakAuras.lua:4961-4990). The Cooldown
--   Progress (Spell) prototype stores it: `local name, _, icon = GetSpellInfo(effectiveSpellId)`
--   (Prototypes.lua:5377) with `{ name = "icon", hidden = true, init = "icon", store = true }`.
--   genericShowOn = "showAlways" compiles to `startTime ~= nil` (Prototypes.lua:5357-5358),
--   true for any known spell, so it is a stable, locale-proof icon oracle. A showOnMissing
--   aura2 state carries no icon, which is why iconSource cannot be 1 on the Rupture prompt.
--
--   THE "show" CONDITION VARIABLE IS NUMERIC. Private.GetTriggerConditions injects a per-
--   trigger Active bool for every trigger system (WeakAuras.lua:4169-4180) whose test is
--   `... == (needle == 1)`, so the value must be 1, never Lua true.
--
--   spellknown WALKS RANKS. IsSpellKnownForLoad dances through the spell NAME to the currently
--   known rank when the exact flag is unset (Prototypes.lua:1127-1143), so a rank-1 gate covers
--   every rank and correctly hides the element while levelling.
--
-- GAME IDS. 1943 Rupture r1, 14177 Cold Blood, 16511 Hemorrhage r1 — references/spell-data.md.
-- 1329 Mutilate r1 and 2098 Eviscerate are confirmed on disk: Details/functions/spells.lua:183
-- `[1329] = 259, -- Mutilate (rank 1)` and :2701 `[2098] = "ROGUE", --eviscerate`.
-- 1752 Sinister Strike as above.
--
-- THE STRONGEST ARGUMENT AGAINST THIS SET, stated rather than hidden: a one-slot lane MAKES a
-- choice, and a child that stays true while the player rationally declines to obey it censors
-- everything beneath it. The concrete case is Rogue Now - RUPTURE: on a target that dies in
-- five seconds the correct play is Eviscerate, not a 16-second bleed, and the lane will sit on
-- RUPTURE while the player holds the points. There is no buildable guard — health percent is
-- not time-to-live — so it is a mitigation (the membership rule; every other child is consumed
-- by pressing it within one GCD) and not an answer. If the lane is cut back after a night of
-- raiding, RUPTURE is the first child to go.
-- ============================================================================================

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local SCRIPTS = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local PACK = dir .. "/all-specs.txt"
local savedArg = arg
arg = { [0] = SCRIPTS .. "/wa_factory.lua" }
local F = dofile(SCRIPTS .. "/wa_factory.lua")
arg = savedArg
local W = F.W

local CLASS    = "ROGUE"
local TOP      = "Rogue TBC - All Specs"
local ALERTS   = "Rogue - Alerts"
local LANE     = "Rogue - Rotation"
local SND_OLD  = "Rogue - SnD MISSING"
local SND_NEW  = "Rogue Now - SLICE AND DICE"
local HEM      = "Rogue - Hemorrhage"
local MUTILATE = 1329           -- the spec split: Mutilate changes the CP ladder, nothing else

local file = assert(io.open(PACK, "r"))
local previous = file:read("*a"); file:close()
local T = W.decode(previous)
local OLD = W.decode(previous)          -- pristine copy for the audit
assert(T.d.id == TOP, "unexpected top-level id: " .. tostring(T.d.id))
local byId = { [T.d.id] = T.d }
for _, a in ipairs(T.c) do byId[a.id] = a end

local function deepcopy(t)
  if type(t) ~= "table" then return t end
  local r = {}; for k, v in pairs(t) do r[k] = deepcopy(v) end; return r
end

-- ===== shared trigger helpers ===============================================================

-- TABLE FORM, DELIBERATELY — see the multiEntry note in the header.
local function powerAtLeast(ptype, n)
  local tr = F.powerTrigger(ptype)
  tr.use_power, tr.power, tr.power_operator = true, { tostring(n) }, { ">=" }
  return tr
end
local function comboAtLeast(n) return powerAtLeast(4, n) end
local function energyAtLeast(n) return powerAtLeast(3, n) end

-- Always-active energy state feeder: no threshold, so it never gates visibility and exists
-- only to publish `power` to the desaturate condition. Identical in shape to
-- Rogue - Energy Rail trigger 1, which is the shipped proof this works.
local function energyFeeder() return F.powerTrigger(3) end

-- Slice and Dice, both TBC ranks, with a remaining-time gate.
local function sndRem(op, sec)
  return F.auraTrigger("player", true, { 5171, 6774 },
    { useRem = true, remOperator = op, rem = tostring(sec) })
end
local function sndMissing()
  return F.auraTrigger("player", true, { 5171, 6774 }, { matchesShowOn = "showOnMissing" })
end

-- MY Rupture missing on the target (all TBC ranks).
local function ruptureMissing()
  return F.auraTrigger("target", false, { 1943, 8639, 8640, 11273, 11274, 11275, 26867 },
    { ownOnly = true, matchesShowOn = "showOnMissing" })
end

-- patch-v44's helper, verbatim: aura2/unit triggers do NO hostility filtering of their own.
local function hostileTarget()
  return {
    type = "unit", event = "Unit Characteristics", unit = "target", use_unit = true,
    use_hostility = true, hostility = "hostile",
    names = {}, spellIds = {}, debuffType = "HELPFUL",
    subeventPrefix = "SPELL", subeventSuffix = "_CAST_START",
  }
end

local function noneAnim()
  local none = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 }
  return { start = deepcopy(none), main = deepcopy(none), finish = deepcopy(none) }
end

-- ===== hand-picked uids (patch-v44's idiom: no shipped value comes from math.random) ========
local UIDS = {}
local function newAura(a, uid)
  a.uid = uid
  UIDS[a.id] = uid
  return a
end

-- Lane children are 48x48 — the alert column is 40x40, and this is the every-GCD surface, so
-- it must outrank the alert column visually (usability test 3).
local function laneIcon(id, uid, glow)
  local a = newAura(F.icon(id, CLASS, 48, 48, 0, 0, LANE), uid)
  a.zoom, a.cooldown, a.iconSource = 0.3, false, 0
  a.subRegions[1] = F.subglow(true, glow)        -- the icon prototype ships a subglow at [1]
  table.insert(a.subRegions, F.subborder())
  a.animation = noneAnim()
  a.actions = { init = {}, start = {}, finish = {} }   -- MUST stay empty: Expand() runs these
  a.load = F.load(CLASS, { use_combat = true })
  return a
end

local HEMORRHAGE = 16511   -- Hemorrhage rank 1; the Subtlety builder
local COLD_BLOOD = 14177   -- Assassination tier 5; not itself a spec gate, see below

local function mutilateOnly(a)
  a.load.use_spellknown, a.load.spellknown = true, MUTILATE
  return a
end
local function notMutilate(a)
  a.load.use_not_spellknown, a.load.not_spellknown = true, MUTILATE
  return a
end
-- v61.1 CORRECTION. `spellknown` and `not_spellknown` are INDEPENDENT load args
-- (Prototypes.lua:1806-1821), so "knows X but not Y" IS expressible in one gate — five sibling
-- packs already ship it (paladin Hammer of Wrath 24275/not 20473, druid Barkskin 22812/not
-- 33878, mage Ice Lance 30455/not 12042, priest Prayer of Mending 33076/not 15473, warlock
-- Demonic Sacrifice 18788/not 19028). The first draft of this patch claimed otherwise and left
-- the non-Mutilate Cold Blood prompt loading for EVERY Combat and Subtlety rogue, relying on a
-- runtime nil return to hide it — exactly the "ungated element must be justified for every
-- spec" rule this repo holds itself to.
local function knowsButNot(a, positive, negative)
  a.load.use_spellknown, a.load.spellknown = true, positive
  a.load.use_not_spellknown, a.load.not_spellknown = true, negative
  return a
end
local function hemoOnly(a)
  a.load.use_spellknown, a.load.spellknown = true, HEMORRHAGE
  return a
end

-- ===== the group ============================================================================
-- (-150, 44) under a top group at (0, -140) => absolute (-150, -96): directly below the alert
-- column, 52px clear of it, 40px clear of the alarm rim, 46px above the cooldown row.
local lane = newAura(F.dynGroup(LANE, -150, 44, TOP, "DOWN", "TOP", 6), "RgLaneGrp61")
lane.useLimit, lane.limit = true, 1
lane.animate = false
lane.sort, lane.align, lane.stagger = "none", "CENTER", 0

-- ===== rank 1: SLICE AND DICE (the existing SnD MISSING aura, moved and re-aimed) ===========
-- The uid is untouched, so WeakAuras' in-game Update matches it and the player's existing
-- aura is upgraded in place rather than duplicated. Its defect was that it spoke only AFTER
-- the uptime was already lost.
--
-- Why this is the highest-value change in the version: a 5-CP Slice and Dice is 30.45s with
-- Improved SnD and a Combat rogue reaches 5 CP roughly every 15s, so SnD eats about every
-- second finisher. The highest-DPS timing decision Combat owns is dumping SnD EARLY, at 1-2
-- CP — which inverts the "build to 5" rule and is the one thing nothing else in this HUD says.
local snd = assert(byId[SND_OLD], "v61: " .. SND_OLD .. " is missing")
assert(snd.uid == "cd9y8ATlQep", "v61: " .. SND_OLD .. " does not carry its shipped uid")
assert(snd.parent == ALERTS, "v61: " .. SND_OLD .. " is not in the alert column")
assert(#snd.triggers == 1 and snd.triggers[1].trigger.type == "aura2"
  and snd.triggers[1].trigger.matchesShowOn == "showOnMissing",
  "v61: " .. SND_OLD .. " is not the single showOnMissing trigger this step rewrites")
assert(#snd.subRegions == 2 and snd.subRegions[1].type == "subglow"
  and snd.subRegions[2].type == "subborder", "v61: " .. SND_OLD .. " subregions moved")
assert(#snd.conditions == 0, "v61: " .. SND_OLD .. " grew conditions; sub.N indexes would move")
assert(snd.iconSource == 0 and snd.displayIcon == "Interface\\Icons\\ability_rogue_slicedice",
  "v61: " .. SND_OLD .. " no longer draws its own displayIcon")

snd.id, snd.parent = SND_NEW, LANE
snd.width, snd.height, snd.xOffset, snd.yOffset = 48, 48, 0, 0
snd.cooldown = false
snd.triggers = F.triggers({
  sndRem("<", 3),   -- 1: under three seconds left — three GCDs of warning
  sndMissing(),     -- 2: gone entirely (the shipped v41 behaviour, kept verbatim)
  comboAtLeast(1),  -- 3: at least one point to spend on it
  hostileTarget(),  -- 4
  energyFeeder(),   -- 5: state only, held out of the show test
}, { disjunctive = "custom",
     customTriggerLogic = "function(t) return (t[1] or t[2]) and t[3] and t[4] end" })
-- activeTriggerMode stays -10 (first_active): triggers 1 and 2 are mutually exclusive by
-- construction, so %p is SnD's remaining seconds while expiring and blank while missing.
snd.subRegions[1] = F.subglow(true, { 1, 0.55, 0.1, 1 })      -- amber: still preventable
table.insert(snd.subRegions, 2, F.subtext("%p", 14, "INNER_BOTTOM"))   -- border moves 2 -> 3
snd.conditions = {
  -- already lost it: back to the exact red the player already knows this icon by
  F.condition(2, "show", "==", 1, "sub.1.glowColor", { 1, 0.15, 0.15, 1 }),
  F.condition(5, "power", "<", "25", "desaturate", true),      -- Slice and Dice costs 25
}
snd.animation = noneAnim()   -- the alert column's slide-in/fly-out is wrong for this surface

-- ===== rank 2: RUPTURE — Mutilate only ======================================================
-- Threshold 4, not 5: every Mutilate build has 41 points in Assassination and therefore Seal
-- Fate, so Mutilate grants +2/+3 and four is the point at which one more builder overflows.
local rup = laneIcon("Rogue Now - RUPTURE", "RgNowRuptur", { 0.85, 0.25, 0.35, 1 })
rup.triggers = F.triggers({
  ruptureMissing(),                              -- 1
  comboAtLeast(4),                               -- 2
  hostileTarget(),                               -- 3
  energyFeeder(),                                -- 4
  F.cdTrigger(1943, "Rupture", "showAlways"),    -- 5: ICON SOURCE ONLY
}, { disjunctive = "custom",
     customTriggerLogic = "function(t) return t[1] and t[2] and t[3] end" })
rup.iconSource = 5
rup.conditions = { F.condition(4, "power", "<", "25", "desaturate", true) }
mutilateOnly(rup)

-- ===== ranks 3 & 4: COLD BLOOD ==============================================================
-- WHY TWO. load.spellknown holds exactly one id, so "Cold Blood AND Mutilate" is not
-- expressible as a load gate. So the 1329 split IS the load gate and the Cold Blood trigger is
-- the runtime gate: showOnReady compiles to `startTime and startTime == 0 or gcdCooldown`
-- (Prototypes.lua:5353-5354) and WeakAuras.GetSpellCooldown returns nil early for an unknown
-- spell (GenericTrigger.lua:2797), so a rogue without the talent loads the aura and it never
-- activates. An inactive child in a limit = 1 lane costs literally nothing — sortedChildren
-- never contains it. (tools/spec-preview.lua will therefore report both as "eligible" for
-- specs that cannot actually see them. That is the tool being offline, not a gate being wrong.)
--
-- WHY THE CP SPLIT IS NOT OPTIONAL. Cold Blood's buff is consumed by the NEXT qualifying
-- ability, including Sinister Strike. A non-Mutilate holder prompted at 4 CP would press CB,
-- then press Sinister Strike to reach 5, and leak the guaranteed crit onto a builder.
--
-- WHY CB SITS BELOW RUPTURE AND ABOVE EVISCERATE. Cold Blood is not consumed by Rupture (a
-- DoT), so at 4 CP with your Rupture down the correct press is Rupture and CB must stay quiet
-- — expressed as rank order, not as a fourth trigger. And CB is OFF THE GCD: you press it, its
-- showOnReady trigger goes false in the same instant, and the lane falls through to the
-- Eviscerate prompt. A two-button sequence rendered as one slot that advances as you press it.
-- The 35-energy grey means "not this GCD — do not spend it yet", which is the anti-leak
-- instruction; there is no state in which CB is visible and unpressable, so nothing else greys.
--
-- GATE ON MUTILATE'S OWN ID, NEVER ON COLD BLOOD: Cold Blood is Assassination tier 5 (20 pts)
-- and Mutilate is tier 9 (41 pts), so a 21/40/0 build holds one without the other.
local function coldBlood(id, uid, cp)
  local cb = laneIcon(id, uid, { 0.5, 0.9, 1, 1 })
  cb.triggers = F.triggers({
    F.cdTrigger(COLD_BLOOD, "Cold Blood", "showOnReady"),  -- 1: visibility AND icon source
    comboAtLeast(cp),                                 -- 2
    hostileTarget(),                                  -- 3
    energyFeeder(),                                   -- 4
  }, { disjunctive = "custom",
       customTriggerLogic = "function(t) return t[1] and t[2] and t[3] end" })
  cb.iconSource = 1
  cb.conditions = { F.condition(4, "power", "<", "35", "desaturate", true) }
  return cb
end
local cbM = mutilateOnly(coldBlood("Rogue Now - COLD BLOOD (Mutilate)", "RgNowCBmuti", 4))
local cbN = knowsButNot(coldBlood("Rogue Now - COLD BLOOD", "RgNowCldBld", 5), COLD_BLOOD, MUTILATE)

-- ===== ranks 5 & 6: EVISCERATE — the player's 刺骨 request ==================================
-- The glow is byte-identical to Rogue - Combo Point 5's colour (the pip ramp ends
-- {1,0.45,0.05}), so the lane and the pip lane say the same thing in the same colour.
--
-- No "SnD remaining > 3" clause, and none is needed: rank 1 owns the slot in exactly that
-- case. This is the lane earning its keep.
--
-- The Eviscerate id is held OUT of customTriggerLogic, so even a wrong id could only fall back
-- to displayIcon (Icon.lua:517) rather than suppress the prompt. That asymmetry is what makes
-- an icon-source trigger safe.
local function eviscerate(id, uid, cp)
  local ev = laneIcon(id, uid, { 1, 0.45, 0.05, 1 })
  ev.triggers = F.triggers({
    comboAtLeast(cp),                                 -- 1
    hostileTarget(),                                  -- 2
    energyFeeder(),                                   -- 3
    F.cdTrigger(2098, "Eviscerate", "showAlways"),    -- 4: ICON SOURCE ONLY
  }, { disjunctive = "custom",
       customTriggerLogic = "function(t) return t[1] and t[2] end" })
  ev.iconSource = 4
  ev.conditions = { F.condition(3, "power", "<", "35", "desaturate", true) }
  return ev
end
local evM = mutilateOnly(eviscerate("Rogue Now - EVISCERATE (Mutilate)", "RgNowEvisMu", 4))
local evN = notMutilate(eviscerate("Rogue Now - EVISCERATE", "RgNowEviscr", 5))

-- ===== ranks 7-9: THE BUILDER — the lane always answers "what do I press" ==================
-- v62. The player asked twice to see 影袭 (Sinister Strike, 1752 -> 26861 at rank 9) highlighted
-- when it is usable. v61 refused, on the grounds that a builder prompt is lit most of a fight
-- and an always-on alert teaches you to ignore the column it lives in.
--
-- THAT OBJECTION WAS RIGHT ABOUT AN ALERT AND WRONG ABOUT THIS LANE. The lane runs limit = 1:
-- it draws exactly ONE icon, ever. A bottom rank does not add a competing light — it fills the
-- slot in the moments nothing more urgent is true, which turns the lane from "an alert that
-- sometimes fires" into "the next button", always. The old rank-9 ENERGY CAP already proved the
-- point: it existed only to catch that same idle case, but it required energy >= 85, so a
-- Combat rogue spending normally essentially never saw it. That is exactly the report.
--
-- SO THE ENERGY THRESHOLD IS GONE AND "USABLE" IS ASKED OF THE GAME. Action Usable evaluates
-- (Prototypes.lua, ["Action Usable"] init):
--     local ready = (startTime == 0 and not paused) or charges > 0
--     local active = Private.ExecEnv.IsUsableSpell(spellName or "") and ready
-- IsUsableSpell accounts for the REAL cost, so Improved Sinister Strike's 45 -> 40 needs no
-- constant here and cannot drift when the player respecs. It drives the LOOK, not the
-- visibility: the icon is always in the slot while you have a hostile target, and it is
-- desaturated until the game says you can press it. Grey means wait, colour means press — the
-- same idiom paladin uses for a locked GCD and Hammer of Wrath uses for range.
--
-- The energy-cap meaning is preserved as a GLOW rather than a rank: at 85+ you are one tick
-- from wasting regen, and the icon lights up instead of a separate prompt appearing.
--
-- RANK-1 IDS, DELIBERATELY, EVEN THOUGH THE PLAYER GAVE 26861 / 26865. Cooldowns are shared
-- across ranks and every rank shares its art, but a max-rank id is not in a levelling rogue's
-- spellbook — references/gotchas.md: a name lookup that fails silently tracks spell 0. 1752 and
-- 2098 resolve for everyone, including at 70.
local function usableTrigger(spellId)
  return {
    type = "spell", event = "Action Usable", use_spellName = true, spellName = spellId,
    use_ignoreoverride = true, ignoreoverride = true,
    names = {}, spellIds = {}, debuffType = "HELPFUL",
    subeventPrefix = "SPELL", subeventSuffix = "_CAST_START",
  }
end

local function builder(id, uid, spellId, spellName)
  local b = laneIcon(id, uid, { 1, 0.9, 0.45, 1 })
  b.triggers = F.triggers({
    hostileTarget(),                                  -- 1: the only visibility test
    usableTrigger(spellId),                           -- 2: drives desaturate
    F.cdTrigger(spellId, spellName, "showAlways"),    -- 3: ICON SOURCE ONLY
    energyAtLeast(85),                                -- 4: drives the wasting-regen glow
  }, { disjunctive = "custom",
       customTriggerLogic = "function(t) return t[1] end" })
  b.iconSource = 3
  b.conditions = {
    F.condition(2, "show", "==", 0, "desaturate", true),
    F.condition(4, "show", "==", 1, "sub.1.glow", true),
  }
  return b
end
local enM = mutilateOnly(builder("Rogue Now - BUILDER (Mutilate)", "RgNowEnCpMu",
  MUTILATE, "Mutilate"))
local enH = hemoOnly(builder("Rogue Now - BUILDER (Hemo)", "RgNowEnCpHm",
  HEMORRHAGE, "Hemorrhage"))
local enN = notMutilate(builder("Rogue Now - BUILDER", "RgNowEnergy",
  1752, "Sinister Strike"))

-- THE ARRAY IS THE ROTATION. WeakAuras' options UI lets a user drag group children around,
-- silently re-ranking this priority list with no other visible change. generate.lua's LANE
-- CANON asserts this exact order back off the finished string.
local RANKS = { snd, rup, cbM, cbN, evM, evN, enM, enH, enN }
local ADDED = { lane, rup, cbM, cbN, evM, evN, enM, enH, enN }   -- snd already exists


-- ===== bundled fix: the weapon-proc column comes home ======================================
-- The player asked why the enchant proc icon sits at the far right of the screen. It was at
-- x 330 because of a chain that no longer applies: v58 widened the strip to a 316px rim, which
-- pushed Procs off 110; at 180 it landed ENTIRELY inside Rogue - KICK LOCKOUT, a 140px aurabar
-- in the PvP column that claims x 180..320 at whatever depth its stack reaches; so it went to
-- 330, just past that bar. v60 shrank the strip to a 172px rim, but Procs stayed put because
-- the blocker was never the strip.
--
-- IT WAS ALSO SHOVED BY A MODELLING ARTEFACT. The group carries showClones with NO limit, so
-- every collision scan projects it six deep — a 212px row — and clears everything on that
-- basis. A rogue has TWO WEAPONS and can never have more than two enchant procs. Saying so in
-- the data (useLimit/limit, read at DynamicGroup.lua:521) makes the honest footprint 68px, and
-- the scan then measures what can actually happen instead of what the default projection
-- assumed. That is a constraint being declared, not a check being relaxed.
--
-- x 110 is exactly where it lived before v58, so this is a full return rather than a new guess.
-- Measured on the boxes the scan actually uses (a child is boxed CENTRED on the group anchor,
-- which is why 100 was 2px short — its box is 84..116 against a rim edge at 86):
--   one deep  94..126  -> clears the 172px rim (right edge 86) by 8px
--   two deep  94..162  -> clears KICK LOCKOUT (180..320) by 18px
do
  local procs = assert(byId["Rogue - Procs"], "v61: Rogue - Procs is missing")
  assert(procs.regionType == "dynamicgroup", "v61: Rogue - Procs is not a dynamic group")
  assert(procs.useLimit == nil or procs.useLimit == false,
    "v61: Rogue - Procs already carries a limit")
  procs.useLimit, procs.limit = true, 2
  procs.xOffset = procs.xOffset - 220        -- 330 -> 110, derived not retyped
  assert(procs.limit == 2 and procs.useLimit == true,
    "v61 proof: the proc column lost its two-weapon limit")
end

-- ===== bundled correctness fix: Rogue - Hemorrhage ==========================================
-- Its aura2 trigger carried no ownOnly (compare Rogue - Rupture / Deadly Poison / Wound
-- Poison, all of which set it) and its load carried only use_class. A Combat rogue raiding
-- beside a Subtlety rogue got a Hemorrhage timer for a debuff they did not apply and cannot
-- refresh — an ungated element that fails rotation-design.md's "an ungated element loads for
-- every spec, so it must be justified for every spec".
do
  local hem = assert(byId[HEM], "v61: " .. HEM .. " is missing")
  assert(hem.triggers[1].trigger.ownOnly == nil, "v61: " .. HEM .. " already sets ownOnly")
  assert(hem.load.use_spellknown == nil, "v61: " .. HEM .. " already carries a spell gate")
  hem.triggers[1].trigger.ownOnly = true
  hem.load.use_spellknown, hem.load.spellknown = true, 16511   -- Hemorrhage rank 1
end

-- ===== splice into the decoded pack =========================================================
for _, a in ipairs(ADDED) do
  assert(UIDS[a.id] == a.uid, "v61: " .. a.id .. " does not carry its hand-picked uid")
  assert(#a.uid == 11 and a.uid:match("^[%w()]+$"), "v61: bad uid literal on " .. a.id)
end
-- Checked against the PRISTINE copy: T's rank-1 table has already been renamed in place, so
-- asking T whether SND_NEW is free would always answer "no".
do
  local ids, uids = { [OLD.d.id] = true }, { [OLD.d.uid] = true }
  for _, a in ipairs(OLD.c) do ids[a.id], uids[a.uid] = true, true end
  for _, a in ipairs(ADDED) do
    assert(not ids[a.id], "v61: id already present in the pack: " .. a.id)
    assert(not uids[a.uid], "v61: uid collision inside the pack: " .. a.uid)
  end
  assert(not ids[SND_NEW], "v61: rank 1's new id is already taken: " .. SND_NEW)
end

-- 1) the alert column loses its one offensive child and finally has one coherent job
local alerts = assert(byId[ALERTS], "v61: alert group not found")
assert(alerts.controlledChildren[1] == SND_OLD,
  "v61: " .. SND_OLD .. " is not the alert column's first child")
table.remove(alerts.controlledChildren, 1)
assert(#alerts.controlledChildren == 6, "v61: the alert column should be left with six children")

-- 2) rank 1's table moves out of the Alerts block in `c`
local sndIndex
for i, a in ipairs(T.c) do if a.id == SND_NEW then sndIndex = i end end
assert(sndIndex, "v61: rank 1 vanished from c")
table.remove(T.c, sndIndex)

-- 3) the lane is appended last, with its children immediately behind it (depth-first)
table.insert(T.d.controlledChildren, LANE)
T.c[#T.c + 1] = lane
for _, a in ipairs(RANKS) do
  a.parent = LANE
  lane.controlledChildren[#lane.controlledChildren + 1] = a.id
  T.c[#T.c + 1] = a
end

-- 4) depth-first invariant: walking d's controlledChildren must reproduce c exactly.
--    generate.lua's canon §5 asserts the same thing on the finished string.
do
  local ids = {}
  for _, a in ipairs(T.c) do ids[a.id] = a end
  local out, seen = {}, {}
  local function walk(node)
    for _, cid in ipairs(node.controlledChildren or {}) do
      local ch = assert(ids[cid], "v61: missing child table: " .. cid)
      assert(not seen[cid], "v61: child listed twice: " .. cid)
      seen[cid] = true
      out[#out + 1] = cid
      walk(ch)
    end
  end
  walk(T.d)
  assert(#out == #T.c, ("v61: depth-first walk covers %d of %d children"):format(#out, #T.c))
  for i = 1, #T.c do
    assert(out[i] == T.c[i].id,
      ("v61: c is not depth-first at %d: %s vs %s"):format(i, T.c[i].id, out[i]))
  end
end

-- ===== encode + verify ======================================================================
-- ===== v63: THE LANE'S ICONS WERE QUESTION MARKS ==========================================
-- Reported in game: the lane renders, but its icon is Interface\Icons\INV_Misc_QuestionMark.
--
-- Icon.lua UpdateIcon() resolves in three ways:
--     iconSource == -1  -> self.state.icon          (the ACTIVE trigger's state)
--     iconSource ==  0  -> self.displayIcon         (a literal path)
--     iconSource ==  N  -> self.states[N].icon      (trigger N's state)
--   ... then: iconPath = iconPath or self.displayIcon or "…\INV_Misc_QuestionMark"
--
-- Every lane rank except SLICE AND DICE used the third form, pointing at a spell trigger that
-- is deliberately EXCLUDED from customTriggerLogic so it cannot gate visibility. An excluded
-- trigger does not reliably populate states[N], so iconPath came back nil, displayIcon was nil
-- too, and the fallback is the question mark. It failed silently and looked like a missing
-- feature rather than a broken icon.
--
-- THE FIX USES THE FORM THIS PACK ALREADY PROVES. `Rogue CD - Kick` has shipped correct spell
-- art since v3 with iconSource = -1 and no displayIcon at all: -1 reads state.icon, and state
-- is whichever trigger activeTriggerMode names. So each rank now NAMES its spell trigger as the
-- state provider and switches to -1. Nothing about visibility changes — customTriggerLogic is
-- untouched — and no icon path is hard-coded, so the art comes from the client and is correct
-- on every locale and at every rank.
--
-- Why not displayIcon: a literal path is a guess unless it can be verified, and this repo has
-- already shipped one unverifiable texture string (paladin's Horde-only twist icon). The
-- client knows the art; ask it.
do
  -- Index the FINISHED table: this step runs after the lane and its ranks were created, and
  -- `byId` above was built from the string as it arrived, before any of them existed.
  local nowById = { [T.d.id] = T.d }
  for _, a in ipairs(T.c) do nowById[a.id] = a end
  local byId = nowById
  local lane = assert(byId[LANE], "v63: the lane is missing")
  local fixed = 0
  for _, id in ipairs(lane.controlledChildren) do
    local a = assert(byId[id], "v63: lane child " .. id .. " is missing")
    local src = a.iconSource
    if src and src > 0 then
      local t = assert(a.triggers[src], "v63: " .. id .. " iconSource points at no trigger")
      assert(t.trigger.type == "spell",
        "v63: " .. id .. " iconSource trigger is not a spell trigger, so it carries no art")
      a.triggers.activeTriggerMode = src
      a.iconSource = -1
      fixed = fixed + 1
    end
  end
  assert(fixed == 8, "v63: expected 8 ranks on the trigger-sourced icon, fixed " .. fixed)

  -- proof: nothing may be left on the form that produced the question mark
  for _, id in ipairs(lane.controlledChildren) do
    local a = byId[id]
    assert(a.iconSource == -1 or (a.iconSource == 0 and a.displayIcon),
      ("v63 proof: %s resolves its icon by neither state (-1) nor a literal path (0 + "
        .. "displayIcon), so it falls through to INV_Misc_QuestionMark"):format(id))
    if a.iconSource == -1 then
      local mode = a.triggers.activeTriggerMode
      assert(type(mode) == "number" and mode >= 1 and mode <= #a.triggers,
        ("v63 proof: %s uses state-sourced art but activeTriggerMode is %s")
          :format(id, tostring(mode)))
      assert(a.triggers[mode].trigger.type == "spell",
        ("v63 proof: %s names trigger %d as its state provider, but that trigger carries no "
          .. "spell art"):format(id, mode))
    end
  end
end

local encoded = W.encode(T)
W.verify(T, encoded)
local cont = W.uidContinuityStrings(encoded, previous)
W.assertUidContinuity(cont, "rogue v61")
-- `stable` counts only ids present in BOTH strings (wa_lib.lua:179-183), and rank 1's ID
-- changed while its uid did not — which is exactly the rename-is-safe contract: not `changed`,
-- not `missing`. So this asserts #OLD.c - 1, where patch-v44 asserted #OLD.c.
assert(cont.changed == 0 and cont.missing == 0 and cont.parentSame,
  ("v61: uid churn — changed=%d missing=%d parentSame=%s")
    :format(cont.changed, cont.missing, tostring(cont.parentSame)))
assert(cont.stable == #OLD.c - 1,
  ("v61: %d stable uids, expected %d (rank 1 is renamed)"):format(cont.stable, #OLD.c - 1))
assert(cont.oldCount == #OLD.c and cont.newCount == #OLD.c + #ADDED,
  ("v61: child count went %d -> %d, expected %d")
    :format(cont.oldCount, cont.newCount, #OLD.c + #ADDED))

-- ===== proof, read back off the ENCODED string ==============================================
local back = W.decode(encoded)
local newById = {}
for _, a in ipairs(back.c) do newById[a.id] = a end

local function iseq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not iseq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

do
  local g = assert(newById[LANE], "v61: the lane is not in the shipped string")
  assert(g.regionType == "dynamicgroup" and g.sort == "none"
    and g.useLimit == true and g.limit == 1 and g.grow == "DOWN" and g.selfPoint == "TOP"
    and g.animate == false and g.parent == TOP,
    "v61: the lane is not a one-slot, unsorted, unanimated DOWN group")
  assert(#g.controlledChildren == #RANKS, "v61: the lane holds the wrong number of ranks")
  for i, a in ipairs(RANKS) do
    assert(g.controlledChildren[i] == a.id,
      ("v61: rank %d is %s, expected %s"):format(i, g.controlledChildren[i], a.id))
  end
end

for rank, want in ipairs(RANKS) do
  local a = assert(newById[want.id], "v61: rank " .. rank .. " missing from the string")
  assert(a.parent == LANE and a.width == 48 and a.height == 48
    and a.xOffset == 0 and a.yOffset == 0,
    "v61: " .. a.id .. " is not a 48px lane child at the group's own point")
  assert(a.load.use_combat == true, "v61: " .. a.id .. " is not combat-gated")
  for slot, anim in pairs(a.animation) do
    assert(anim.type == "none", ("v61: %s has a %s animation on %s"):format(a.id, anim.type, slot))
  end
  assert(next(a.actions.start) == nil and next(a.actions.finish) == nil,
    "v61: " .. a.id .. " carries an action; Expand() runs it even while the lane hides it")
  -- power thresholds ship as tables, or the test is silently dropped
  for i, wrapped in ipairs(a.triggers) do
    local tr = wrapped.trigger
    if tr.event == "Power" and tr.use_power then
      assert(type(tr.power) == "table" and #tr.power > 0
        and type(tr.power_operator) == "table" and #tr.power_operator > 0,
        ("v61: %s trigger %d ships a scalar power threshold; ConstructTest would drop it")
          :format(a.id, i))
    end
    assert(not (tr.matchesShowOn == "showOnMissing" and tr.useRem),
      ("v61: %s trigger %d pairs showOnMissing with useRem; CanHaveMatchCheck drops useRem")
        :format(a.id, i))
  end
  if (a.iconSource or 0) > 0 then
    local src = a.triggers[a.iconSource]
    assert(src and src.trigger.type == "spell",
      ("v61: %s iconSource points at trigger %d, which is not a spell trigger")
        :format(a.id, tostring(a.iconSource)))
  end
  -- SPEC GATING. v61.1 widened this: the first draft asserted every positive gate was Mutilate,
  -- which is what forced Cold Blood and the Subtlety energy prompt to be under-gated in the
  -- first place. spellknown and not_spellknown are INDEPENDENT args, so the legal shapes are:
  --   spellknown = MUTILATE                      (Assassination only)
  --   not_spellknown = MUTILATE                  (everyone else)
  --   spellknown = X and not_spellknown = MUTILATE  (knows X, is not Mutilate)
  --   spellknown = HEMORRHAGE                    (Subtlety builder)
  -- What is still forbidden is gating positively AND negatively on the SAME id, which can
  -- never load, and any positive gate on an id this lane does not know about.
  local KNOWN_POS = { [MUTILATE] = true, [COLD_BLOOD] = true, [HEMORRHAGE] = true }
  local pos = a.load.use_spellknown and a.load.spellknown or nil
  local neg = a.load.use_not_spellknown and a.load.not_spellknown or nil
  assert(not (pos and neg and pos == neg),
    "v61: " .. a.id .. " gates positively and negatively on the same id; it can never load")
  assert(not pos or KNOWN_POS[pos],
    "v61: " .. a.id .. " has an unrecognised positive spell gate " .. tostring(pos))
  assert(not neg or neg == MUTILATE,
    "v61: " .. a.id .. " has an unrecognised negative spell gate " .. tostring(neg))
end

-- rank 1 specifically: the uid survived the rename, and the icon still draws itself
do
  local a = newById[SND_NEW]
  assert(a.uid == "cd9y8ATlQep", "v61: rank 1 lost the uid the in-game Update depends on")
  assert(a.iconSource == 0 and a.displayIcon == "Interface\\Icons\\ability_rogue_slicedice",
    "v61: rank 1 no longer draws Slice and Dice")
  assert(#a.subRegions == 3 and a.subRegions[1].type == "subglow"
    and a.subRegions[2].type == "subtext" and a.subRegions[3].type == "subborder",
    "v61: rank 1's subregion order changed under its conditions")
  assert(a.conditions[1].check.trigger == 2 and a.conditions[1].check.value == 1,
    "v61: rank 1's 'already lost it' condition must test the Active bool against numeric 1")
end

-- the alert column: same six survivors, in the same order, otherwise untouched
local oldById = {}
for _, a in ipairs(OLD.c) do oldById[a.id] = a end
do
  local a, o = newById[ALERTS], oldById[ALERTS]
  assert(#a.controlledChildren == 6, "v61: the alert column is not six children")
  assert(#o.controlledChildren == 7 and o.controlledChildren[1] == SND_OLD,
    "v61: the alert column did not start as seven children led by " .. SND_OLD)
  for i = 1, 6 do
    assert(a.controlledChildren[i] == o.controlledChildren[i + 1],
      "v61: the alert column reordered its survivors")
  end
  local x, y = deepcopy(o), deepcopy(a)
  x.controlledChildren, y.controlledChildren = nil, nil
  assert(iseq(x, y), "v61: the alert column changed beyond losing one child")
end

-- ===== audit: nothing but the declared changes may differ ===================================
assert(#back.c == #OLD.c + #ADDED,
  ("v61: child count %d, expected %d"):format(#back.c, #OLD.c + #ADDED))
do  -- the top-level group gains exactly one child, appended
  local o, n = deepcopy(OLD.d), deepcopy(back.d)
  assert(#n.controlledChildren == #o.controlledChildren + 1
    and n.controlledChildren[#n.controlledChildren] == LANE,
    "v61: the lane is not the last top-level child")
  for i = 1, #o.controlledChildren do
    assert(n.controlledChildren[i] == o.controlledChildren[i], "v61: top-level children moved")
  end
  o.controlledChildren, n.controlledChildren = nil, nil
  assert(iseq(o, n), "v61: the top-level group changed beyond controlledChildren")
end

local EXCEPTIONS = { [SND_OLD] = "renamed, re-parented and re-triggered as " .. SND_NEW,
                     [ALERTS] = "one child removed", [HEM] = "ownOnly + spellknown gate",
                     ["Rogue - Procs"] = "two-weapon limit + x 330 -> 110" }
local touched = 0
for _, old in ipairs(OLD.c) do
  if EXCEPTIONS[old.id] then
    touched = touched + 1
  else
    local new = assert(newById[old.id], "v61: child vanished: " .. old.id)
    assert(iseq(old, new), "v61: unexpected change in " .. old.id)
  end
end
assert(touched == 4, "v61: expected exactly four declared exceptions, saw " .. touched)
assert(newById[SND_OLD] == nil, "v61: the old SnD id is still in the string")

do  -- the Hemorrhage fix, and nothing else on that aura
  local o, new = deepcopy(oldById[HEM]), newById[HEM]
  assert(new.triggers[1].trigger.ownOnly == true, "v61: Hemorrhage is still not own-only")
  assert(new.load.use_spellknown == true and new.load.spellknown == 16511,
    "v61: Hemorrhage is still ungated")
  o.triggers[1].trigger.ownOnly = true
  o.load.use_spellknown, o.load.spellknown = true, 16511
  assert(iseq(o, new), "v61: Hemorrhage changed beyond ownOnly and its spell gate")
end

local out = assert(io.open(PACK, "w")); out:write(encoded); out:close()
print(("v61: the lane — %d ranks in one 48px slot at (-150,-96), limit=1 sort=none; "
  .. "+%d auras (%d -> %d), Hemorrhage own-only and gated; "
  .. "uid stable=%d changed=%d missing=%d (rank 1 renamed, uid kept)")
  :format(#RANKS, #ADDED, #OLD.c + 1, #back.c + 1, cont.stable, cont.changed, cont.missing))
