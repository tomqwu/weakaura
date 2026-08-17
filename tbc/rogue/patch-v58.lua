-- rogue v57 -> v58: THE NAMEPLATE PIPS ACTUALLY WORK, AND THE RAILS GET THREE PIXELS PER
-- PERCENT.
--
-- Replayed by generate.lua after patch-v57. Mutates the decoded tables in place and consumes
-- NO W.uid(): no region is added, removed, renamed or re-parented.
--
-- ============================================================================================
-- PART 1 — WHY v57's NAMEPLATE PIPS RENDERED IN THE STRIP, AND WHAT ACTUALLY FIXES IT
--
-- v57 set anchorFrameType = "NAMEPLATE" on the ten combo regions and added a third trigger,
-- Unit Characteristics on "target", with activeTriggerMode = 3 so that state.unit would be
-- "target". Every one of those moves is right except the unit token, and the unit token is the
-- whole bug. From the installed WeakAuras 5.21.10:
--
--     -- AuraEnvironment.lua:160
--     WeakAuras.GetUnitNameplate = function(unit)
--       if Private.multiUnitUnits.nameplate[unit] then
--         return LGF.GetUnitNameplate(unit)
--       end
--     end
--
--     -- Types.lua:4316 and 4351-4355
--     Private.multiUnitUnits = { ["nameplate"] = {}, ... }
--     for i = 1, 40 do
--       Private.multiUnitUnits.nameplate["nameplate"..i] = true
--
-- Private.multiUnitUnits.nameplate["target"] is nil. GetUnitNameplate returns nil for EVERY
-- unit token except nameplate1..nameplate40 — "target", "player" and "focus" included. So
-- GetAnchorFrame's NAMEPLATE branch (WeakAuras.lua:6105) could never resolve, and its last
-- line, `return parent` (6171), handed the pips back to their own group. They drew in the
-- Sill, 100% of the time, silently. Exactly what the player reported.
--
-- IT IS NOT A MISSING MONITOR. A static NAMEPLATE-anchored aura re-anchors continuously:
-- RegionPrototype.lua:1118-1125 calls Private.AnchorFrame from region:Expand() for
-- SELECTFRAME / CUSTOM / UNITFRAME / NAMEPLATE, BEFORE the `if region.toShow then return end`
-- early-out, and WeakAuras.lua:4901 calls region:Expand() from ApplyStateToRegion on every
-- state application. The delayed-anchor loop and the UNITFRAME monitor are not the only ways
-- in. That is why this fix needs no dynamic group: see the note at the bottom of Part 1.
--
-- THE FIX: MAKE TRIGGER 3 A NAMEPLATE TRIGGER THAT IS FILTERED DOWN TO YOUR TARGET.
--
--     trigger 3 = Unit Characteristics, unit = "nameplate",
--                 use_unitisunit = true, unitisunit = "target"
--
--   * Prototypes.lua:2398 statesParameter = "unit", and the `unit` arg is init = "arg",
--     store = true -> GenericTrigger.lua:454-458 emits `state.unit = unit`.
--   * GenericTrigger.lua:703-715: because Private.multiUnitUnits["nameplate"] exists, the
--     trigger clones per matching unit and cloneId == arg1 == "nameplate7". So state.unit is
--     a REAL nameplate token, which is the only kind GetUnitNameplate will answer.
--   * Prototypes.lua:2412-2426: unitisunit is init = "UnitIsUnit(unit, extraUnit)",
--     test = "unitisunit", extraUnit baked from trigger.unitisunit -> the 40 plates are
--     filtered down to exactly the one that is your current target.
--   * Prototypes.lua:2372-2382: internal_events include UNIT_CHANGED_nameplateN AND
--     UNIT_IS_UNIT_CHANGED_nameplateN_target for all 40, and loadFunc calls
--     WeakAuras.WatchUnitChange on all 40 plus "target". GenericTrigger.lua:3748-3767 emits
--     exactly those pairs whenever a watched unit's GUID or existence changes, fed by
--     PLAYER_TARGET_CHANGED, NAME_PLATE_UNIT_ADDED/REMOVED and PLAYER_ENTERING_WORLD.
--
-- THE FALLBACK, WHICH IS THE PART THAT MAKES THIS SAFE. disjunctive becomes "custom" with
-- customTriggerLogic "function(t) return t[1] and t[2] end" — the v54 show rule, points AND
-- the player state feeder, with trigger 3 deliberately NOT in it. So:
--
--     target has a plate      trigger 3 has one state, cloneId "nameplate7",
--                             state.unit = "nameplate7"  -> the clone anchors to that plate
--     no target / no plate    trigger 3 has no state; WeakAuras.lua:5093 builds
--                             CreateFallbackState, which never writes state.unit
--                             (GenericTrigger.lua:5118-5185) -> the NAMEPLATE branch falls
--                             through to `return parent` -> the Sill lane, pixel-for-pixel
--
-- v57 left disjunctive = "all", which ALSO required a target to exist before the sockets would
-- draw at all. That was sold as a feature; it is not one, because it removed the always-visible
-- socket row that v41 shipped and that the strip fallback depends on. "custom" restores it.
--
-- WHY NOT A DYNAMIC GROUP. DynamicGroup.lua's useAnchorPerUnit / anchorPerUnit = "NAMEPLATE"
-- path (anchorers.NAMEPLATE, line 380-402) is a real mechanism, and it is the RIGHT one when
-- you need one region per nameplate. Here it is strictly worse:
--   * it lays children out in a ROW, so the five sockets and the five lit pips drawn on top of
--     them stop being five overlapping pairs and become ten boxes in a line;
--   * an unhandled child is `controlPoint:SetShown(false)` (line 1520-1524) with NO
--     HiddenFrames placeholder and no PRD fallback outside the options window — so with
--     nameplates off the combo readout would disappear entirely, and the pack would need a
--     second set of ten regions plus mutual-exclusion logic to get the strip back;
--   * RegionPrototype.lua:1095 and 1166-1172 install no-op Expand/Collapse stubs for anything
--     with controlledChildren, so a nested static `group` inside a dynamic group never shows —
--     that escape hatch does not exist;
--   * it costs six appended W.uid() calls and doubles the region count for a strictly smaller
--     feature set.
-- The plain anchor costs nothing and keeps the pop and the green->orange ramp verbatim.
--
-- THE ONE PRICE, STATED PLAINLY. Those ten regions have ONE pair of offsets, and they now draw
-- on two surfaces. So the pip pitch on the nameplate IS the pip pitch in the strip. That is why
-- Part 2 lengthens the rails 3x but leaves PIP_W and PIP_X exactly where v54 put them: the pip
-- lane is a 0..5 counter, not a percentage gauge, and a 96px row is right on a nameplate. Only
-- PIP_H moves, from 6 to 12, because the lane stack around it doubled.
--
-- ============================================================================================
-- PART 2 — THE RAILS WERE TOO SHORT
--
-- v54's rail is 100px, one pixel per percent, which is lossless but tiny: a 4px threat rail and
-- an 11px energy rail carrying an 11pt number. Paladin v22 already answered this — RAIL_LEN
-- 300, THREE pixels per percent, a 304x62 plate with a 6px alarm rim, 22px bars, 20pt numbers.
-- This patch brings rogue to the same law, with a fourth lane for the combo pips.
--
--     lane            local y     height    span            gap to the lane below
--     threat            +31          8      +27 .. +35              2
--     health            +14         22       +3 .. +25              2
--     energy            -10         22      -21 ..  +1              2
--     combo pips        -29         12      -35 .. -23              -
--
--   content spans +-35, the plate adds a 2px margin -> 304 x 74, centred at local (0,0).
--   Rogue's plate stays at local y 0 because its four-lane stack is symmetric; paladin needs
--   its +6 only because its three-lane stack is not.
--
-- THE GEOMETRY IS MEASURED, NOT CHOSEN. Every element in the pack was projected with dynamic
-- groups six children deep, using the box model the canon in generate.lua already uses, and the
-- frontier was searched. What it says:
--
--   * With NOTHING moved, the strip cannot grow. At the shipped SILL_Y -110 the tracked-buff
--     row (y -176..-136, directly BELOW the strip — this is the rogue/paladin difference:
--     paladin's buff row is above its strip) caps ALARM_H at 52, and at any ALARM_H >= 76 it
--     caps the half-width at 2px. Max ALARM_W anywhere in that band is 188, i.e. RAIL_LEN 172.
--     300 does not fit. Measured, not asserted.
--   * Moving the buff row to y -60 — paladin's own slot, above the strip — opens a 110px
--     corridor between the buff row's bottom (-80) and the cooldown row's top (-190). An
--     86px alarm fits with 24px to spare, and SILL_Y -125 spends 2px of it above and 22px
--     below, which is paladin's exact split and puts rogue's strip top on paladin's strip top.
--   * Horizontally the binder is not the proc icons, it is the 140px-wide KICK LOCKOUT aurabar
--     that sets the PvP column's box to x +-70 around its anchor. Measured minima for a 316px
--     rim: Rogue - Procs x >= 174, Rogue - PvP x >= 228, both at zero clearance. This patch
--     takes 180 and 250, for 6px and 22px.
--   * Rogue - Alerts does NOT need to move, unlike paladin's. Its box (x -170..-130) only
--     exists above y -44, which clears the new strip top (-82) by 38px in true geometry and by
--     18px under the canon's deliberately conservative box for dynamic-group children. Left at
--     -150 on purpose; do not "fix" it.
--   * Rogue - Cooldowns does not move either: 22px.
--
-- Run: lua5.1 tbc/rogue/patch-v58.lua   (rewrites all-specs.txt in place)

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local SCRIPTS = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local PACK = dir .. "/all-specs.txt"
local savedArg = arg
arg = { [0] = SCRIPTS .. "/wa_lib.lua" }
local W = dofile(SCRIPTS .. "/wa_lib.lua")
arg = savedArg

-- ===== art ==============================================================================
local MEDIA      = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\"
local SQUARE     = MEDIA .. "Square_White.tga"
local SQUARE_BRD = MEDIA .. "Square_White_Border.tga"

-- ===== geometry =========================================================================
local SILL_X, SILL_Y   = 0, -125      -- paladin parity: the strip top lands on paladin's
local RAIL_LEN         = 160          -- 1.6 PIXELS PER PERCENT. Every value this pack marks is
                                      -- a multiple of five, and 1.6 x 5 = 8, so every mark still
                                      -- lands on a whole pixel. The invariant was never the
                                      -- number 100; it is that markX() is the only place a
                                      -- coordinate is derived, so the length is one constant.
local MAXPOWER         = 100          -- energy cap without Vigor
-- HEIGHT IS THE THING THAT WAS WRONG, NOT LENGTH. v58 scaled the whole strip uniformly, which
-- kept the original 2.8:1 plate and simply made the same stubby block twice as big — and it
-- read as a panel. A vitals readout wants to be LONG AND THIN: the fill's travel is the signal,
-- its thickness is not. So the rails keep 1.6x the original length and go back to near the
-- original thickness, taking the plate from 204x74 (15,096 px^2) to 164x45 (7,380) — less than
-- half the area, while every bar stays 60% longer than the 100px version that read as too short.
local THREAT_H         = 5            -- an early-warning ratio: thinnest lane, no number
local BAR_H            = 13
local LANE_THREAT_Y    = 18.5         -- stack, top down, 1px gaps: 5 | 13 | 13 | 8 = 42 content
local LANE_HEALTH_Y    = 8.5
local LANE_POWER_Y     = -5.5
local PLATE_W, PLATE_H = 164, 45      -- 42 of content + 1.5px of margin top and bottom
local RIM              = 4            -- a thinner strip wants a thinner alarm rim
local ALARM_W, ALARM_H = PLATE_W + 2 * RIM, PLATE_H + 2 * RIM

-- The combo lane. WIDTH IS FROZEN ON PURPOSE — see the "ONE PRICE" note in Part 1. These ten
-- regions also draw on the target's nameplate, where a 96px row is right and a 264px row is
-- absurd. Only the height follows the lane stack.
local PIP_W, PIP_H, PIP_Y = 16, 8, -17
local PIP_X = { -40, -20, 0, 20, 40 }

-- The one formula. Rounded to 3dp because (0.35 - 0.5) * 300 is -45.00000000000001 in IEEE754
-- and a 17-digit float has no business in an import string for a whole-pixel coordinate.
local function markX(value, maxValue)
  local x = (value / (maxValue or MAXPOWER) - 0.5) * RAIL_LEN
  return math.floor(x * 1000 + 0.5) / 1000
end

local NOTCH_THREAT = 70
local EVISCERATE   = 35
local SINISTER     = 40
local RULER        = { 25, 50, 75 }

-- Mark widths, scaled 2x with the rail exactly as paladin v22 scaled its own (RULE_W 1->2,
-- MARK_W 2/4 -> 4/8, the threat notch stays 2 because it is already a hairline against an 8px
-- rail). A ruler hairline is a hint; a breakpoint waterline is a decision boundary.
local RULE_W       = 2
local MARK_DIM_W   = 4
local MARK_LIT_W   = 8
local NOTCH_W      = 2

local LABEL_X, LABEL_SIZE = 51, 12    -- 82% along the rail, inside it
local THREAT_LABEL_SIZE   = 14        -- still text_visible = false; sized for parity

-- Column moves, as ABSOLUTE targets. Local offsets are derived from the real parent chain
-- below, so a future change to any ancestor cannot silently drag a column.
local COLUMNS = {
  { id = "Rogue - Buffs",   x = 0,   y = -60,  why = "the tracked-buff row moves ABOVE the strip" },
  -- v58.1: 180 cleared the sill rim but sat INSIDE the PvP column's own box. Rogue - KICK
  -- LOCKOUT is a 140px aurabar, so the PvP column occupies x 180..320 at any depth its stack
  -- reaches; a proc icon at 180..212 was therefore entirely behind it whenever the kick timer
  -- was down at that depth. At 330 the first proc icon (330..362) clears the bar's right edge
  -- by 10px. Two weapon procs is the real maximum, so the row ends at 398.
  { id = "Rogue - Procs",   x = 330, y = -116, why = "clears the rim AND the 140px KICK LOCKOUT bar" },
  { id = "Rogue - PvP",     x = 250, y = -44,  why = "the 140px KICK LOCKOUT sets this column's box" },
}

-- ===== ids ==============================================================================
local TOP    = "Rogue TBC - All Specs"
local GROUP  = "Rogue - Player Sill"
local PLATE  = "Rogue - Sill Plate"
local THREAT = "Rogue - Threat Rail"
local HEALTH = "Rogue - Health Rail"
local POWER  = "Rogue - Energy Rail"
local ALARM  = "Rogue - Alarm Frame"

local function socket(i) return ("Rogue - Combo Socket %d"):format(i) end
local function pip(i)    return ("Rogue - Combo Point %d"):format(i) end

local COMBO = {}
for i = 1, 5 do
  COMBO[#COMBO + 1] = socket(i)
  COMBO[#COMBO + 1] = pip(i)
end

-- ===== helpers ==========================================================================
local function iseq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not iseq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

-- ===== read the v57 build ===============================================================
local f = assert(io.open(PACK, "r")); local src = f:read("*a"); f:close()
local T = W.decode(src)
local byId = { [T.d.id] = T.d }
for _, aura in ipairs(T.c) do byId[aura.id] = aura end

local function absoluteIn(map, id)
  local x, y = 0, 0
  local node = assert(map[id], "missing region " .. id)
  while node do
    x, y = x + (node.xOffset or 0), y + (node.yOffset or 0)
    node = node.parent and assert(map[node.parent], "unresolved parent " .. node.parent)
  end
  return x, y
end

-- ===== the exact v57 state this patch expects ===========================================
do
  local V57 = {
    [THREAT] = { w = 100, h = 4,  subs = 2 },
    [HEALTH] = { w = 100, h = 11, subs = 4 },
    [POWER]  = { w = 100, h = 11, subs = 8 },
  }
  for id, want in pairs(V57) do
    local a = assert(byId[id], "v58: " .. id .. " is missing")
    assert(a.regionType == "progresstexture" and a.orientation == "HORIZONTAL",
      "v58: " .. id .. " is not the v56 left-to-right rail")
    assert(a.width == want.w and a.height == want.h,
      ("v58: %s is %sx%s, expected the v54 %dx%d"):format(id, tostring(a.width),
        tostring(a.height), want.w, want.h))
    assert(#a.subRegions == want.subs,
      ("v58: %s has %d subregions, expected %d"):format(id, #a.subRegions, want.subs))
    assert(a.parent == GROUP, "v58: " .. id .. " is not in the sill")
  end
  assert(byId[PLATE].width == 102 and byId[PLATE].height == 37, "v58: the plate is not the v54 plate")
  assert(byId[ALARM].width == 108 and byId[ALARM].height == 43, "v58: the alarm is not the v54 rim")
  local gx, gy = absoluteIn(byId, GROUP)
  assert(gx == 0 and gy == -110, "v58: the sill is not at the v54 (0,-110)")
  -- and the v57 nameplate state, which this patch corrects rather than replaces
  for _, id in ipairs(COMBO) do
    local a = assert(byId[id], "v58: " .. id .. " is missing")
    assert(a.anchorFrameType == "NAMEPLATE", "v58: " .. id .. " lost v57's nameplate anchor")
    assert(#a.triggers == 3 and a.triggers.activeTriggerMode == 3,
      "v58: " .. id .. " is not the v57 three-trigger shape")
    assert(a.triggers[3].trigger.event == "Unit Characteristics"
      and a.triggers[3].trigger.unit == "target",
      "v58: " .. id .. " trigger 3 is not v57's unresolvable target feeder")
    assert(a.triggers.disjunctive == "all", "v58: " .. id .. " is not v57's disjunctive")
    assert(a.width == 16 and a.height == 6, "v58: " .. id .. " is not the v54 16x6 pip")
  end
end

-- ========================================================================================
-- PART 1: the nameplate token
-- ========================================================================================
local SHOW_RULE = "function(t) return t[1] and t[2] end"
for _, id in ipairs(COMBO) do
  local a = byId[id]
  local t3 = a.triggers[3].trigger
  t3.unit           = "nameplate"     -- the ONLY token family GetUnitNameplate answers
  t3.use_unitisunit = true
  t3.unitisunit     = "target"        -- ...filtered to the one plate that is your target
  -- activeTriggerMode stays 3: state.unit must come from trigger 3, and 3 <= #triggers, or
  -- WeakAuras.lua:3280 silently reverts it to first_active.
  a.triggers.disjunctive        = "custom"
  a.triggers.customTriggerLogic = SHOW_RULE
  -- anchorFrameType / selfPoint / anchorPoint / xOffset / yOffset: deliberately untouched.
  -- They are what make the no-plate fallback land back in the Sill lane for free.
end

-- ========================================================================================
-- PART 2: three pixels per percent
-- ========================================================================================

-- ----- the sill, and the columns that make room for it ----------------------------------
do
  local sill = byId[GROUP]
  local x, y, node = 0, 0, byId[sill.parent]
  while node do
    x, y = x + (node.xOffset or 0), y + (node.yOffset or 0)
    node = node.parent and byId[node.parent] or nil
  end
  sill.xOffset, sill.yOffset = SILL_X - x, SILL_Y - y
end
for _, col in ipairs(COLUMNS) do
  local a = assert(byId[col.id], "v58: missing column " .. col.id)
  local x, y, node = 0, 0, byId[a.parent]
  while node do
    x, y = x + (node.xOffset or 0), y + (node.yOffset or 0)
    node = node.parent and byId[node.parent] or nil
  end
  a.xOffset, a.yOffset = col.x - x, col.y - y
end

-- ----- the plate and the alarm rim ------------------------------------------------------
byId[PLATE].width, byId[PLATE].height = PLATE_W, PLATE_H
byId[ALARM].width, byId[ALARM].height = ALARM_W, ALARM_H

-- ----- the rails ------------------------------------------------------------------------
local function resize(id, h, y)
  local a = byId[id]
  a.width, a.height = RAIL_LEN, h
  a.xOffset, a.yOffset = 0, y
  return a
end
local threat = resize(THREAT, THREAT_H, LANE_THREAT_Y)
local health = resize(HEALTH, BAR_H,    LANE_HEALTH_Y)
local power  = resize(POWER,  BAR_H,    LANE_POWER_Y)

-- Threat: the number stays switched off (threatpct is an early-warning ratio, not a quantity),
-- but its dead ring-era offset of +58 is zeroed so that ticking it on in /wa prints it on the
-- rail instead of 58px above open screen. sub.2 is the 70 notch.
threat.subRegions[1].text_fontSize = THREAT_LABEL_SIZE
threat.subRegions[1].anchorXOffset, threat.subRegions[1].anchorYOffset = 0, 0
threat.subRegions[1].text_anchorXOffset, threat.subRegions[1].text_anchorYOffset = 0, 0
threat.subRegions[2].xOffset = markX(NOTCH_THREAT)
threat.subRegions[2].width, threat.subRegions[2].height = NOTCH_W, THREAT_H

-- Health: the number, then the three ruler hairlines at 25 / 50 / 75.
health.subRegions[1].text_fontSize = LABEL_SIZE
health.subRegions[1].anchorXOffset, health.subRegions[1].anchorYOffset = LABEL_X, 0
health.subRegions[1].text_anchorXOffset, health.subRegions[1].text_anchorYOffset = LABEL_X, 0
for i, value in ipairs(RULER) do
  local sub = health.subRegions[1 + i]
  sub.xOffset = markX(value)
  sub.width, sub.height = RULE_W, BAR_H
end

-- Energy: the number, the dim/lit 35 and 40 pairs (sub.4 and sub.5 KEEP their indexes — two
-- shipped conditions address them as sub.4.textureVisible / sub.5.textureVisible), then the
-- ruler at 6..8.
power.subRegions[1].text_fontSize = LABEL_SIZE
power.subRegions[1].anchorXOffset, power.subRegions[1].anchorYOffset = LABEL_X, 0
power.subRegions[1].text_anchorXOffset, power.subRegions[1].text_anchorYOffset = LABEL_X, 0
local MARKS = {
  [2] = { v = EVISCERATE, w = MARK_DIM_W },
  [3] = { v = SINISTER,   w = MARK_DIM_W },
  [4] = { v = EVISCERATE, w = MARK_LIT_W },
  [5] = { v = SINISTER,   w = MARK_LIT_W },
}
for index, mark in pairs(MARKS) do
  local sub = power.subRegions[index]
  sub.xOffset = markX(mark.v)
  sub.width, sub.height = mark.w, BAR_H
end
for i, value in ipairs(RULER) do
  local sub = power.subRegions[5 + i]
  sub.xOffset = markX(value)
  sub.width, sub.height = RULE_W, BAR_H
end

-- ----- the combo lane -------------------------------------------------------------------
for i = 1, 5 do
  for _, id in ipairs({ socket(i), pip(i) }) do
    local a = byId[id]
    a.width, a.height = PIP_W, PIP_H
    a.xOffset, a.yOffset = PIP_X[i], PIP_Y
  end
end

-- ===== encode and verify ================================================================
local encoded = W.encode(T)
W.verify(T, encoded)
local cont = W.uidContinuityStrings(encoded, src)
-- No allowance list. v58 adds and removes nothing.
W.assertUidContinuity(cont, "rogue v58")
assert(cont.changed == 0, "rogue v58: an existing id changed uid")
assert(cont.missing == 0, "rogue v58: a uid disappeared, and v58 removes nothing")
assert(cont.parentSame, "rogue v58: the top-level uid changed")
assert(cont.oldCount == cont.newCount, "rogue v58: the aura count moved")
assert(cont.retained == cont.oldCount, "rogue v58: not every previous uid survived")

local NEW = W.decode(encoded)
local nodes = { [NEW.d.id] = NEW.d }
for _, aura in ipairs(NEW.c) do nodes[aura.id] = aura end
local function absolute(id) return absoluteIn(nodes, id) end

-- ===== PROOF 1: the nameplate mechanism, read back off the encoded string ================
do
  for _, id in ipairs(COMBO) do
    local a = nodes[id]
    assert(a.anchorFrameType == "NAMEPLATE", "v58 proof: " .. id .. " is not nameplate-anchored")
    assert(a.parent == GROUP,
      "v58 proof: " .. id .. " left the Sill, so it has no no-plate fallback")
    assert(a.selfPoint == "CENTER" and a.anchorPoint == "CENTER",
      "v58 proof: " .. id .. " changed anchor points; the fallback would not reproduce the lane")
    assert(#a.triggers == 3, "v58 proof: " .. id .. " does not have three triggers")
    local t3 = a.triggers[3].trigger
    assert(t3.event == "Unit Characteristics", "v58 proof: " .. id .. " trigger 3 changed type")
    assert(t3.unit == "nameplate",
      ("v58 proof: %s trigger 3 is on %q. WeakAuras.GetUnitNameplate is gated on "
        .. "Private.multiUnitUnits.nameplate, which holds nameplate1..nameplate40 and NOTHING "
        .. "else, so any other token resolves to nil and the pips fall back to the strip")
        :format(id, tostring(t3.unit)))
    assert(t3.use_unitisunit == true and t3.unitisunit == "target",
      "v58 proof: " .. id .. " trigger 3 is not filtered to the target's plate, so it would "
      .. "clone onto every nameplate on screen")
    assert(a.triggers.activeTriggerMode == 3,
      ("v58 proof: %s activeTriggerMode is %s; region.state must come from the nameplate "
        .. "trigger"):format(id, tostring(a.triggers.activeTriggerMode)))
    assert(a.triggers.activeTriggerMode <= #a.triggers,
      "v58 proof: " .. id .. " activeTriggerMode is out of range; WeakAuras.lua:3280 would "
      .. "silently reset it to first_active")
    assert(a.triggers.disjunctive == "custom" and a.triggers.customTriggerLogic == SHOW_RULE,
      ("v58 proof: %s show rule is %s/%s, expected custom/%s — trigger 3 must NOT gate "
        .. "visibility, or there is no readout without a nameplate")
        :format(id, tostring(a.triggers.disjunctive),
          tostring(a.triggers.customTriggerLogic), SHOW_RULE))
    assert(a.triggers[1].trigger.event == "Power" and a.triggers[1].trigger.unit == "player",
      "v58 proof: " .. id .. " trigger 1 is not the player combo-point trigger")
    assert(a.triggers[2].trigger.event == "Unit Characteristics"
      and a.triggers[2].trigger.unit == "player",
      "v58 proof: " .. id .. " trigger 2 is not the player state feeder the show rule names")
    for _, c in ipairs(a.conditions or {}) do
      assert(c.check.trigger ~= 3,
        "v58 proof: " .. id .. " has a condition pointing at the nameplate trigger")
    end
  end
  -- the pop and the ramp survived, because nothing about them was touched
  local colours = {}
  for i = 1, 5 do
    local lit = nodes[pip(i)]
    assert(lit.animation.start.type == "custom" and lit.animation.start.scalex == 1.85
      and lit.animation.start.scaley == 1.85 and lit.animation.start.duration == "0.3",
      "v58 proof: " .. pip(i) .. " lost its 1.85x pop")
    assert(lit.blendMode == "ADD", "v58 proof: " .. pip(i) .. " stopped being additive")
    colours[i] = lit.color
  end
  assert(colours[1][2] > colours[5][2] and colours[5][1] >= colours[1][1],
    "v58 proof: the green->orange left-to-right pip ramp is gone")
  print(("  nameplate: 10 regions, trigger 3 = Unit Characteristics/nameplate filtered by "
    .. "unitisunit=target, activeTriggerMode 3, show rule %s; no-plate fallback = the Sill lane")
    :format(SHOW_RULE))
end

-- ===== PROOF 2: the strip lands where the measurement says ==============================
do
  local gx, gy = absolute(GROUP)
  assert(gx == SILL_X and gy == SILL_Y,
    ("v58 proof: the sill resolves to (%s,%s), not (%d,%d)")
      :format(tostring(gx), tostring(gy), SILL_X, SILL_Y))
  for _, col in ipairs(COLUMNS) do
    local cx, cy = absolute(col.id)
    assert(cx == col.x and cy == col.y,
      ("v58 proof: %s resolves to (%s,%s), not (%d,%d) — %s")
        :format(col.id, tostring(cx), tostring(cy), col.x, col.y, col.why))
  end
  -- CROSS-COLUMN ALL-PAIRS. The scan in generate.lua tests everything against the SILL, which
  -- structurally cannot see two flanking columns overlapping EACH OTHER — and v58 moves two of
  -- them. This is the check that would have caught the proc icon sitting behind the kick bar.
  do
    local function columnBox(id)
      local g = assert(nodes[id], "column " .. id .. " missing")
      local cx, cy = absolute(id)
      local widest, tallest, n = 0, 0, 0
      for _, cid in ipairs(g.controlledChildren or {}) do
        widest  = math.max(widest,  tonumber(nodes[cid].width)  or 0)
        tallest = math.max(tallest, tonumber(nodes[cid].height) or 0)
        n = n + 1
      end
      local depth = math.min(n, 6)
      local space = tonumber(g.space) or 4
      -- selfPoint names the corner of the child that sits ON the anchor, so it decides which
      -- way the row hangs. Anything that is not LEFT/RIGHT is horizontally centred — TOP and
      -- BOTTOM included, which is what a DOWN- or UP-growing column uses.
      local x0, x1
      if g.selfPoint == "LEFT" then x0, x1 = cx, cx + widest
      elseif g.selfPoint == "RIGHT" then x0, x1 = cx - widest, cx
      else x0, x1 = cx - widest / 2, cx + widest / 2 end
      local y0, y1 = cy - tallest / 2, cy + tallest / 2
      if g.selfPoint == "TOP" then y0, y1 = cy - tallest, cy
      elseif g.selfPoint == "BOTTOM" then y0, y1 = cy, cy + tallest end
      if g.grow == "DOWN" then y0 = y0 - (depth - 1) * (tallest + space)
      elseif g.grow == "UP" then y1 = y1 + (depth - 1) * (tallest + space)
      elseif g.grow == "RIGHT" then x1 = x1 + (depth - 1) * (widest + space)
      elseif g.grow == "LEFT" then x0 = x0 - (depth - 1) * (widest + space) end
      return { id = id, x0 = x0, x1 = x1, y0 = y0, y1 = y1 }
    end
    local cols = {}
    for _, id in ipairs({ "Rogue - Alerts", "Rogue - Procs", "Rogue - PvP", "Rogue - Cooldowns" }) do
      if nodes[id] then cols[#cols + 1] = columnBox(id) end
    end
    for i = 1, #cols do
      for j = i + 1, #cols do
        local a, b = cols[i], cols[j]
        local overlaps = a.x0 < b.x1 and a.x1 > b.x0 and a.y0 < b.y1 and a.y1 > b.y0
        assert(not overlaps,
          ("v58 proof: columns %s (x %.0f..%.0f y %.0f..%.0f) and %s (x %.0f..%.0f y %.0f..%.0f) "
            .. "overlap; one will render behind the other")
            :format(a.id, a.x0, a.x1, a.y0, a.y1, b.id, b.x0, b.x1, b.y0, b.y1))
      end
    end
    print(("  columns: %d flanking stacks, all-pairs at 6 deep, 0 overlaps"):format(#cols))
  end

  local ax, ay = absolute("Rogue - Alerts")
  assert(ax == -150 and ay == -44,
    "v58 proof: Rogue - Alerts moved. It is at -150 ON PURPOSE: its box only exists above "
    .. "y -44 and therefore never enters the strip band at any rail length.")
  local dx, dy = absolute("Rogue - Cooldowns")
  assert(dx == 0 and dy == -206, "v58 proof: Rogue - Cooldowns moved")
end

-- ===== PROOF 3: the rails, the lane stack and the plate =================================
do
  local RAILS = {
    { id = THREAT, h = THREAT_H, y = LANE_THREAT_Y, subs = 2 },
    { id = HEALTH, h = BAR_H,    y = LANE_HEALTH_Y, subs = 4 },
    { id = POWER,  h = BAR_H,    y = LANE_POWER_Y,  subs = 8 },
  }
  for _, want in ipairs(RAILS) do
    local a = nodes[want.id]
    assert(a.regionType == "progresstexture", "v58 proof: " .. want.id .. " changed type")
    assert(a.orientation == "HORIZONTAL",
      "v58 proof: " .. want.id .. " does not fill left to right")
    assert(a.width == RAIL_LEN,
      ("v58 proof: %s is %s wide; three pixels is one percent only at %d")
        :format(want.id, tostring(a.width), RAIL_LEN))
    assert(a.height == want.h and a.xOffset == 0 and a.yOffset == want.y,
      ("v58 proof: %s is %s tall at (%s,%s), expected %d at (0,%d)")
        :format(want.id, tostring(a.height), tostring(a.xOffset), tostring(a.yOffset),
          want.h, want.y))
    assert(a.width ~= a.height, "v58 proof: " .. want.id .. " is square, so it is a ring again")
    assert(a.foregroundTexture == SQUARE and a.backgroundTexture == SQUARE,
      "v58 proof: " .. want.id .. " is not drawn on Square_White")
    assert(#a.subRegions == want.subs,
      ("v58 proof: %s has %d subregions, expected %d — indexes are positional and conditions "
        .. "address them as sub.N"):format(want.id, #a.subRegions, want.subs))
  end
  -- no two lanes overlap, and every lane is inside the plate with a margin
  local stack = {
    { "threat", THREAT_H, LANE_THREAT_Y }, { "health", BAR_H, LANE_HEALTH_Y },
    { "energy", BAR_H, LANE_POWER_Y },     { "combo",  PIP_H, PIP_Y },
  }
  for i = 1, #stack - 1 do
    local a, b = stack[i], stack[i + 1]
    local gap = (a[3] - a[2] / 2) - (b[3] + b[2] / 2)
    assert(gap >= 1, ("v58 proof: %s and %s are %gpx apart"):format(a[1], b[1], gap))
  end
  local top    = LANE_THREAT_Y + THREAT_H / 2
  local bottom = PIP_Y - PIP_H / 2
  assert(top <= PLATE_H / 2 - 1 and bottom >= -PLATE_H / 2 + 1,
    ("v58 proof: the lane stack (%+.1f .. %+.1f) does not fit inside a %dpx plate with a "
      .. "1px margin"):format(top, bottom, PLATE_H))
  local plate, alarm = nodes[PLATE], nodes[ALARM]
  assert(plate.width == PLATE_W and plate.height == PLATE_H,
    ("v58 proof: the plate is %sx%s, expected %dx%d")
      :format(tostring(plate.width), tostring(plate.height), PLATE_W, PLATE_H))
  assert(alarm.width == plate.width + 2 * RIM and alarm.height == plate.height + 2 * RIM,
    ("v58 proof: the alarm is %sx%s; a %dpx rim on a %dx%d plate is %dx%d")
      :format(tostring(alarm.width), tostring(alarm.height), RIM, PLATE_W, PLATE_H,
        ALARM_W, ALARM_H))
  assert(plate.xOffset == 0 and plate.yOffset == 0 and alarm.xOffset == 0 and alarm.yOffset == 0,
    "v58 proof: the plate and the rim are no longer concentric with the strip")
  assert(alarm.blendMode == "ADD" and plate.blendMode == "BLEND",
    "v58 proof: the plate and the alarm swapped blend modes")
  assert(nodes[GROUP].controlledChildren[1] == ALARM,
    "v58 proof: the alarm rim is not drawn first, so it is a wash and not a rim")
  assert(#nodes[GROUP].controlledChildren == 15,
    "v58 proof: the sill no longer holds 15 children")
  print(("  lanes: threat %+d/%d, health %+d/%d, energy %+d/%d, combo %+d/%d -> content "
    .. "%+.1f..%+.1f inside a %dx%d plate under a %dx%d rim")
    :format(LANE_THREAT_Y, THREAT_H, LANE_HEALTH_Y, BAR_H, LANE_POWER_Y, BAR_H, PIP_Y, PIP_H,
      top, bottom, PLATE_W, PLATE_H, ALARM_W, ALARM_H))
end

-- ===== PROOF 4: every mark recomputed from the formula ==================================
do
  local EXPECT = {
    { THREAT, 2, NOTCH_THREAT, NOTCH_W,    THREAT_H, "the 70 threat notch" },
    { HEALTH, 2, 25,           RULE_W,     BAR_H,    "the health 25 rule" },
    { HEALTH, 3, 50,           RULE_W,     BAR_H,    "the health 50 rule" },
    { HEALTH, 4, 75,           RULE_W,     BAR_H,    "the health 75 rule" },
    { POWER,  2, EVISCERATE,   MARK_DIM_W, BAR_H,    "the dim 35 mark" },
    { POWER,  3, SINISTER,     MARK_DIM_W, BAR_H,    "the dim 40 mark" },
    { POWER,  4, EVISCERATE,   MARK_LIT_W, BAR_H,    "the lit 35 mark" },
    { POWER,  5, SINISTER,     MARK_LIT_W, BAR_H,    "the lit 40 mark" },
    { POWER,  6, 25,           RULE_W,     BAR_H,    "the energy 25 rule" },
    { POWER,  7, 50,           RULE_W,     BAR_H,    "the energy 50 rule" },
    { POWER,  8, 75,           RULE_W,     BAR_H,    "the energy 75 rule" },
  }
  for _, want in ipairs(EXPECT) do
    local id, index, value, w, h, label = want[1], want[2], want[3], want[4], want[5], want[6]
    local sub = assert(nodes[id].subRegions[index],
      ("v58 proof: %s has no sub.%d (%s)"):format(id, index, label))
    assert(sub.type == "subtexture", "v58 proof: " .. label .. " is not a subtexture")
    assert(sub.textureTexture == SQUARE, "v58 proof: " .. label .. " is not a white square")
    assert(sub.xOffset == markX(value),
      ("v58 proof: %s is at x %s, the formula says %s")
        :format(label, tostring(sub.xOffset), tostring(markX(value))))
    assert(sub.yOffset == 0, "v58 proof: " .. label .. " is off its rail's centre line")
    assert(sub.width == w and sub.height == h,
      ("v58 proof: %s is %sx%s, expected %dx%d")
        :format(label, tostring(sub.width), tostring(sub.height), w, h))
    assert(sub.height == nodes[id].height,
      "v58 proof: " .. label .. " is not full rail height; a waterline must span the rail")
  end
  -- the two conditions still address sub.4 and sub.5 and nothing moved into them
  local drives = {}
  for _, cond in ipairs(nodes[POWER].conditions or {}) do
    for _, change in ipairs(cond.changes) do
      if tostring(change.property):match("^sub%.%d+%.") then
        drives[change.property] = cond.check
      end
    end
  end
  local d35 = assert(drives["sub.4.textureVisible"], "v58 proof: nothing drives sub.4 any more")
  local d40 = assert(drives["sub.5.textureVisible"], "v58 proof: nothing drives sub.5 any more")
  assert(d35.variable == "power" and d35.value == tostring(EVISCERATE),
    "v58 proof: sub.4 is no longer the 35-energy mark")
  assert(d40.variable == "power" and d40.value == tostring(SINISTER),
    "v58 proof: sub.5 is no longer the 40-energy mark")
  assert(nodes[POWER].subRegions[4].textureVisible == false
    and nodes[POWER].subRegions[5].textureVisible == false,
    "v58 proof: the lit marks start visible, so they say nothing")
  print(("  marks: 35 -> x%+g, 40 -> x%+g, threat 70 -> x%+g, ruler %g/%g/%g  (x = (v/100 - "
    .. "0.5) * %d)"):format(markX(EVISCERATE), markX(SINISTER), markX(NOTCH_THREAT),
      markX(25), markX(50), markX(75), RAIL_LEN))
end

-- ===== PROOF 5: the numbers still fit inside the rails they print in =====================
do
  for _, want in ipairs({ { HEALTH, LABEL_SIZE, true, "%percenthealth%%" },
                          { POWER,  LABEL_SIZE, true, "%p" },
                          { THREAT, THREAT_LABEL_SIZE, false, "%threatpct%%" } }) do
    local id, size, visible, text = want[1], want[2], want[3], want[4]
    local label = nodes[id].subRegions[1]
    assert(label.type == "subtext", "v58 proof: " .. id .. " lost its number")
    assert(label.text_fontSize == size,
      ("v58 proof: %s number is %spt, expected %dpt"):format(id, tostring(label.text_fontSize), size))
    assert(label.text_visible == visible,
      ("v58 proof: %s number visibility changed"):format(id))
    assert(label.text_text == text, ("v58 proof: %s number token changed"):format(id))
    assert(label.text_anchorPoint == "CENTER" and label.text_fontType == "OUTLINE",
      "v58 proof: " .. id .. " number lost its centre anchor or its outline")
    -- BOTH SPELLINGS. WeakAuras anchors on text_anchor*Offset (SubText.lua); the bare
    -- anchor*Offset is written by its own default() and read by nothing. v55 shipped that fix;
    -- this patch must not undo it.
    local x = (id == THREAT) and 0 or LABEL_X
    assert(label.anchorXOffset == x and label.anchorYOffset == 0
      and label.text_anchorXOffset == x and label.text_anchorYOffset == 0,
      ("v58 proof: %s number is not at x %+d on both spellings"):format(id, x))
  end
  -- widest string, generous advance: "100%" at 20pt is at most 4 * 0.60 * 20 = 48px wide,
  -- centred on x = +96, so it spans +72 .. +120 and stays inside the rail's +150 edge.
  local ADVANCE, WIDEST = 0.60, 4
  local half = WIDEST * ADVANCE * LABEL_SIZE / 2
  assert(LABEL_X + half < RAIL_LEN / 2,
    ("v58 proof: a %dpt %d-glyph number reaches x=%.1f and leaves the %dpx rail")
      :format(LABEL_SIZE, WIDEST, LABEL_X + half, RAIL_LEN))
  assert(LABEL_SIZE <= BAR_H, "v58 proof: the number is taller than the rail it prints in")
  print(("  numbers: %dpt at x=+%d, widest %.1fpx -> x %+.1f..%+.1f inside a %dpx rail; "
    .. "threat %dpt, hidden"):format(LABEL_SIZE, LABEL_X, half * 2, LABEL_X - half,
      LABEL_X + half, RAIL_LEN, THREAT_LABEL_SIZE))
end

-- ===== PROOF 6: the rectangle scan, dynamic groups projected six children deep ===========
-- The scanned box is the ENVELOPE — the widest of the plate, the alarm rim and the peak of the
-- 1.85x pip pop — so it covers everything the strip ever draws. The box model is the canon's:
-- (x,y) is a CENTRE for a plain region, and the edge a dynamic group grows away from for a
-- dynamic group. Dynamic-group CHILDREN are boxed at the group anchor, which is deliberately
-- conservative (they are already covered by the group's own six-deep projection) and is what
-- makes Rogue - Weapon Procs the binding element on the right.
local GROW_SELF = { UP = "BOTTOM", DOWN = "TOP", RIGHT = "LEFT", LEFT = "RIGHT",
                    HORIZONTAL = "CENTER", VERTICAL = "CENTER", CIRCLE = "CENTER" }
do
  local DEPTH = 6
  local sx = nodes[pip(1)].animation.start.scalex
  local sy = nodes[pip(1)].animation.start.scaley
  for i = 2, 5 do
    assert(nodes[pip(i)].animation.start.scalex == sx
      and nodes[pip(i)].animation.start.scaley == sy, "v58 proof: the pips no longer pop alike")
  end
  local popX = math.max(math.abs(PIP_X[1]), math.abs(PIP_X[5])) + PIP_W * sx / 2
  local popY = math.abs(PIP_Y) + PIP_H * sy / 2
  assert(popX <= ALARM_W / 2 and popY <= ALARM_H / 2,
    ("v58 proof: the pip pop reaches (%.2f,%.2f) and leaves the %dx%d rim; the envelope is "
      .. "supposed to BE the rim"):format(popX, popY, ALARM_W, ALARM_H))
  local sx1 = math.min(SILL_X - ALARM_W / 2, SILL_X - popX)
  local sx2 = math.max(SILL_X + ALARM_W / 2, SILL_X + popX)
  local sy1 = math.min(SILL_Y - ALARM_H / 2, SILL_Y - popY)
  local sy2 = math.max(SILL_Y + ALARM_H / 2, SILL_Y + popY)

  local inSill = { [GROUP] = true }
  for _, id in ipairs(nodes[GROUP].controlledChildren) do inSill[id] = true end
  local scanned, hits, closest, closestId = 0, {}, math.huge, nil
  for _, a in ipairs(NEW.c) do
    if not inSill[a.id] then
      local x1, x2, y1, y2
      assert(a.anchorFrameType == nil or a.anchorFrameType == "SCREEN",
        a.id .. " is not screen-anchored, so its absolute position is not this arithmetic")
      assert(a.anchorPoint == nil or a.anchorPoint == "CENTER",
        a.id .. " does not anchor to the screen centre")
      if a.regionType == "dynamicgroup" then
        assert(a.selfPoint == GROW_SELF[a.grow],
          ("%s grows %s from %s; the scan projects it from %s")
            :format(a.id, tostring(a.grow), tostring(a.selfPoint), tostring(GROW_SELF[a.grow])))
        local x, y = absolute(a.id)
        local widest, tallest = 0, 0
        for _, cid in ipairs(a.controlledChildren or {}) do
          widest  = math.max(widest,  nodes[cid].width  or 0)
          tallest = math.max(tallest, nodes[cid].height or 0)
        end
        local space = a.space or 0
        local runX = DEPTH * widest  + (DEPTH - 1) * space
        local runY = DEPTH * tallest + (DEPTH - 1) * space
        if a.grow == "UP" then
          x1, x2, y1, y2 = x - widest / 2, x + widest / 2, y, y + runY
        elseif a.grow == "DOWN" then
          x1, x2, y1, y2 = x - widest / 2, x + widest / 2, y - runY, y
        elseif a.grow == "RIGHT" then
          x1, x2, y1, y2 = x, x + runX, y - tallest / 2, y + tallest / 2
        elseif a.grow == "LEFT" then
          x1, x2, y1, y2 = x - runX, x, y - tallest / 2, y + tallest / 2
        else
          x1, x2 = x - runX / 2, x + runX / 2
          y1, y2 = y - tallest / 2, y + tallest / 2
        end
      elseif a.regionType ~= "group" then
        assert(a.selfPoint == nil or a.selfPoint == "CENTER",
          a.id .. " is not centre-anchored, so a centred box is the wrong box for it")
        local x, y = absolute(a.id)
        local w, h = a.width or 0, a.height or 0
        x1, x2, y1, y2 = x - w / 2, x + w / 2, y - h / 2, y + h / 2
      end
      if x1 then
        scanned = scanned + 1
        if sx1 < x2 and x1 < sx2 and sy1 < y2 and y1 < sy2 then
          hits[#hits + 1] = ("%s (x %g..%g, y %g..%g)"):format(a.id, x1, x2, y1, y2)
        else
          local gap = math.max(sx1 - x2, x1 - sx2, sy1 - y2, y1 - sy2)
          if gap < closest then closest, closestId = gap, a.id end
        end
      end
    end
  end
  assert(scanned > 0, "v58 proof: the rectangle scan examined nothing")
  assert(#hits == 0, ("v58 proof: the envelope at (%d,%d) overlaps %d element(s): %s")
    :format(SILL_X, SILL_Y, #hits, table.concat(hits, "; ")))
  print(("  scan: envelope x %g..%g y %g..%g (plate %dx%d, rim %dx%d, pop x+-%.2f y+-%.2f), "
    .. "%d elements, 0 overlaps, closest %.2fpx (%s)")
    :format(sx1, sx2, sy1, sy2, PLATE_W, PLATE_H, ALARM_W, ALARM_H, popX, popY,
      scanned, closest, tostring(closestId)))
end

-- ===== PROOF 7: nothing outside this patch's licence moved ==============================
do
  local OLD = W.decode(src)
  local oldById = { [OLD.d.id] = OLD.d }
  for _, aura in ipairs(OLD.c) do oldById[aura.id] = aura end

  local ALLOWED = {
    [GROUP]  = { yOffset = true },
    [PLATE]  = { width = true, height = true },
    [ALARM]  = { width = true, height = true },
    [THREAT] = { width = true, height = true, yOffset = true, subRegions = true },
    [HEALTH] = { width = true, height = true, yOffset = true, subRegions = true },
    [POWER]  = { width = true, height = true, yOffset = true, subRegions = true },
  }
  for _, col in ipairs(COLUMNS) do ALLOWED[col.id] = { xOffset = true, yOffset = true } end
  for _, id in ipairs(COMBO) do
    ALLOWED[id] = { width = true, height = true, xOffset = true, yOffset = true, triggers = true }
  end

  assert(iseq(OLD.d, NEW.d), "v58: the top-level group changed")
  assert(#OLD.c == #NEW.c, "v58: the aura count changed")
  for _, new in ipairs(NEW.c) do
    local old = assert(oldById[new.id], new.id .. " has no v57 counterpart")
    assert(old.uid == new.uid, new.id .. ": the uid moved")
    local licence = ALLOWED[new.id] or {}
    for key, value in pairs(old) do
      if not licence[key] then
        assert(iseq(value, new[key]),
          ("v58: %s.%s changed, and v58 does not licence that field"):format(new.id, key))
      end
    end
    for key in pairs(new) do
      assert(old[key] ~= nil or licence[key], new.id .. ": gained unlicensed field " .. key)
    end
  end

  -- The combo regions may only differ in the three trigger-3 fields plus the show rule.
  for _, id in ipairs(COMBO) do
    local was, now = oldById[id].triggers, nodes[id].triggers
    assert(#was == #now and was.activeTriggerMode == now.activeTriggerMode,
      "v58: " .. id .. " changed trigger count or active mode")
    assert(iseq(was[1], now[1]) and iseq(was[2], now[2]),
      "v58: " .. id .. " triggers 1 or 2 changed")
    for key, value in pairs(was[3].trigger) do
      if key ~= "unit" then
        assert(iseq(value, now[3].trigger[key]),
          ("v58: %s trigger 3 field %s changed"):format(id, key))
      end
    end
    for key in pairs(now[3].trigger) do
      assert(was[3].trigger[key] ~= nil or key == "use_unitisunit" or key == "unitisunit",
        ("v58: %s trigger 3 gained unlicensed field %s"):format(id, key))
    end
  end

  -- Everything a design change must not touch, named explicitly.
  local UNCHANGED = { { THREAT, "triggers" }, { THREAT, "conditions" }, { THREAT, "load" },
                      { HEALTH, "triggers" }, { HEALTH, "conditions" }, { HEALTH, "load" },
                      { POWER,  "triggers" }, { POWER,  "conditions" }, { POWER,  "load" },
                      { ALARM,  "triggers" }, { ALARM,  "animation" },  { ALARM,  "color" },
                      { PLATE,  "triggers" }, { PLATE,  "color" } }
  for _, id in ipairs(COMBO) do
    UNCHANGED[#UNCHANGED + 1] = { id, "conditions" }
    UNCHANGED[#UNCHANGED + 1] = { id, "color" }
    UNCHANGED[#UNCHANGED + 1] = { id, "animation" }
    UNCHANGED[#UNCHANGED + 1] = { id, "load" }
  end
  for _, entry in ipairs(UNCHANGED) do
    assert(iseq(oldById[entry[1]][entry[2]], nodes[entry[1]][entry[2]]),
      ("v58: %s.%s is not byte-identical to v57"):format(entry[1], entry[2]))
  end

  -- Subregion-level: only the keys this patch moves may differ, and no subregion may appear
  -- or disappear (indexes are positional; conditions address them as sub.N).
  local SUB_LICENCE = {
    text_fontSize = true, anchorXOffset = true, anchorYOffset = true,
    text_anchorXOffset = true, text_anchorYOffset = true,
    xOffset = true, width = true, height = true,
  }
  for _, id in ipairs({ THREAT, HEALTH, POWER }) do
    local was, now = oldById[id].subRegions, nodes[id].subRegions
    assert(#was == #now, "v58: " .. id .. " changed subregion count")
    for index = 1, #was do
      for key, value in pairs(was[index]) do
        if not SUB_LICENCE[key] then
          assert(iseq(value, now[index][key]),
            ("v58: %s sub.%d field %s changed"):format(id, index, key))
        end
      end
      for key in pairs(now[index]) do
        assert(was[index][key] ~= nil, ("v58: %s sub.%d gained %s"):format(id, index, key))
      end
    end
  end
  print("  diff: every unlicensed field, on all 58 auras, is byte-identical to v57")
end

local out = assert(io.open(PACK, "w")); out:write(encoded); out:close()
print(("v58: nameplate pips fixed (unit token target -> nameplate/unitisunit) and the rails "
  .. "go to %d (%dpx/percent); sill (%d,%d), plate %dx%d, rim %dx%d; buffs -> (0,-60), "
  .. "procs -> (330,-116), pvp -> (250,-44); uid stable=%d changed=%d missing=%d")
  :format(RAIL_LEN, RAIL_LEN / MAXPOWER, SILL_X, SILL_Y, PLATE_W, PLATE_H, ALARM_W, ALARM_H,
    cont.stable, cont.changed, cont.missing))
