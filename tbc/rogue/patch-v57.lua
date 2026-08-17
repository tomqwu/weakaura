-- patch-v57.lua — the combo pips move onto the TARGET'S NAMEPLATE.
--
-- !! CORRECTED BY patch-v58.lua. THIS STEP SHIPPED BROKEN. !!
-- Everything below is right except one field: `unit = "target"` on trigger 3. WeakAuras'
-- GetUnitNameplate (AuraEnvironment.lua:160) is gated on Private.multiUnitUnits.nameplate,
-- which Types.lua:4351-4355 fills with nameplate1..nameplate40 and NOTHING else — so "target"
-- resolves to nil, GetAnchorFrame falls through to `return parent`, and the pips rendered in
-- the Sill for the whole of v57. v58 changes trigger 3 to unit = "nameplate" with
-- use_unitisunit / unitisunit = "target", and swaps disjunctive "all" for a custom rule that
-- keeps the sockets visible with no target. This step is kept in the replay because the anchor
-- field, the third-trigger slot and activeTriggerMode = 3 are all still what v58 builds on;
-- only two field values are wrong, and layering the correction keeps the lineage honest.
--
-- Replayed by generate.lua after patch-v56. Mutates `byId` in place; consumes no W.uid().
--
-- ============================================================================================
-- WHY THIS IS POSSIBLE AT ALL, AND WHY IT TAKES THREE TRIGGERS
--
-- WeakAuras can anchor a region to a nameplate: anchorFrameType = "NAMEPLATE". Verified in the
-- installed WeakAuras 5.21.10:
--   * Types.lua Private.anchor_frame_types lists NAMEPLATE = L["Nameplates"].
--   * WeakAuras.lua GetAnchorFrame():
--         if (anchorFrameType == "NAMEPLATE") then
--           local unit = region.state and region.state.unit
--           if unit then
--             local frame = unit and WeakAuras.GetUnitNameplate(unit)
--             if frame then return frame end
--           end
--   * AuraEnvironment.lua WeakAuras.GetUnitNameplate = LGF.GetUnitNameplate, and
--     Libs/LibGetFrame-1.0 is bundled in this install, so the lookup exists on 2.5.x.
--
-- THE CATCH. It anchors to the nameplate of the AURA'S OWN unit, and the combo-point trigger is
-- hard-gated to the player. Prototypes.lua, inside the Power prototype's init:
--         elseif powerType == 4 and trigger.unit == 'player' then
-- so a combo trigger can only ever report unit = "player". Anchoring the pips as they stood
-- would have hung them off YOUR nameplate, not your target's — and silently, because the code
-- path is identical and the pips would simply appear in the wrong place.
--
-- THE WAY ROUND IT. A third trigger, Unit Characteristics on "target", supplies the unit; then
-- activeTriggerMode names it as the state provider. WeakAuras.lua:3280 accepts any index up to
-- #triggers (anything larger silently reverts to first_active = -10), so this must stay in
-- range or the pips quietly go back to hanging off the player.
--
-- WHAT THE THIRD TRIGGER ALSO BUYS. disjunctive stays "all", so the pips now require a target
-- as well as the points. That is not a side effect to apologise for: combo points are a
-- property of the target, and a socket row floating under a rogue with nothing selected was
-- always decoration. It does mean the empty sockets are no longer permanently on screen, which
-- IS a change from the "always-visible sockets" v41 shipped.
--
-- THE FALLBACK IS FREE, AND THAT IS WHY THE ANCHOR POINTS DO NOT CHANGE. GetAnchorFrame's last
-- line is `return parent` — with no nameplate it hands back the region's own group. The pips
-- stay children of the Sill with CENTER/CENTER anchoring and their existing offsets, so a
-- player with nameplates switched off gets pixel-for-pixel the v56 strip layout, and a player
-- with nameplates on gets the pips on the target. One string, both behaviours, no second set of
-- regions and no new uid.
-- ============================================================================================

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local SCRIPTS = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local PACK = dir .. "/all-specs.txt"
local savedArg = arg
arg = { [0] = SCRIPTS .. "/wa_lib.lua" }
local W = dofile(SCRIPTS .. "/wa_lib.lua")
arg = savedArg

local f = assert(io.open(PACK, "r"))
local previous = f:read("*a"); f:close()
local T = W.decode(previous)
local byId = { [T.d.id] = T.d }
for _, a in ipairs(T.c) do byId[a.id] = a end

local ids = {}
for i = 1, 5 do
  ids[#ids + 1] = ("Rogue - Combo Socket %d"):format(i)
  ids[#ids + 1] = ("Rogue - Combo Point %d"):format(i)
end

-- The state-supplying trigger. Unit Characteristics is the right primitive: it is always active
-- while the unit exists, carries no threshold of its own, and is already used elsewhere in this
-- pack purely as a state feeder. Its ONLY job here is to put unit = "target" into state.
local function targetTrigger()
  return {
    type = "unit", event = "Unit Characteristics",
    unit = "target", use_unit = true,
    names = {}, spellIds = {}, subeventPrefix = "SPELL", subeventSuffix = "_CAST_START",
    debuffType = "HELPFUL",
  }
end

for _, id in ipairs(ids) do
  local a = assert(byId[id], "v57: " .. id .. " is missing")

  assert(#a.triggers == 2, "v57: " .. id .. " no longer has exactly the two v54 triggers")
  assert(a.triggers[1].trigger.event == "Power", "v57: " .. id .. " trigger 1 is not the Power trigger")
  assert(a.triggers[1].trigger.unit == "player",
    "v57: " .. id .. " trigger 1 is not on the player; powerType 4 only reads combo points there")
  assert(a.triggers[2].trigger.event == "Unit Characteristics",
    "v57: " .. id .. " trigger 2 is not the state feeder the inCombat condition reads")

  -- APPEND. The inCombat condition addresses trigger 2 by index, so the new trigger goes at the
  -- end for exactly the reason subregions do.
  a.triggers[3] = { trigger = targetTrigger(), untrigger = {} }
  a.triggers.activeTriggerMode = 3
  a.triggers.disjunctive = "all"

  a.anchorFrameType = "NAMEPLATE"
  -- selfPoint / anchorPoint / xOffset / yOffset deliberately untouched: see the fallback note.
end

-- ===== proof, read back off the mutated tables ==========================================
for _, id in ipairs(ids) do
  local a = byId[id]
  assert(a.anchorFrameType == "NAMEPLATE", "v57 proof: " .. id .. " is not nameplate-anchored")
  assert(#a.triggers == 3, "v57 proof: " .. id .. " does not have three triggers")
  assert(a.triggers[3].trigger.unit == "target",
    "v57 proof: " .. id .. " trigger 3 is not on the target, so the nameplate would be yours")
  assert(a.triggers.activeTriggerMode == 3,
    ("v57 proof: %s activeTriggerMode is %s; it must name the target trigger, or state.unit "
      .. "falls back to the player and the pips hang off your own nameplate")
      :format(id, tostring(a.triggers.activeTriggerMode)))
  assert(a.triggers.activeTriggerMode <= #a.triggers,
    "v57 proof: " .. id .. " activeTriggerMode is out of range; WeakAuras.lua:3280 would "
    .. "silently reset it to first_active")
  assert(a.triggers.disjunctive == "all",
    "v57 proof: " .. id .. " no longer requires ALL of points + player state + target")
  -- the fallback: unchanged geometry inside the Sill
  assert(a.parent == "Rogue - Player Sill",
    "v57 proof: " .. id .. " left the Sill, so it has no fallback when no nameplate exists")
  assert(a.selfPoint == "CENTER" and a.anchorPoint == "CENTER",
    "v57 proof: " .. id .. " changed anchor points; the no-nameplate fallback would no longer "
    .. "reproduce the v56 strip layout")
  -- the condition still addresses the trigger it was written against
  for _, c in ipairs(a.conditions or {}) do
    assert(c.check.trigger ~= 3,
      "v57 proof: " .. id .. " has a condition pointing at the new trigger 3")
  end
end

local encoded = W.encode(T)
W.verify(T, encoded)
local cont = W.uidContinuityStrings(encoded, previous)
-- Nothing is added, removed, renamed or re-parented here: only three trigger fields and one
-- anchor field change on ten existing regions. So this must be perfectly stable, with no
-- allowance list at all.
W.assertUidContinuity(cont, "rogue v57")
assert(cont.changed == 0 and cont.missing == 0 and cont.stable == cont.oldCount,
  ("v57: uid churn — stable=%d changed=%d missing=%d of %d")
    :format(cont.stable, cont.changed, cont.missing, cont.oldCount))

local out = assert(io.open(PACK, "w")); out:write(encoded); out:close()
print(("v57: 10 combo regions anchored to the target's nameplate "
  .. "(trigger 3 = Unit Characteristics/target, activeTriggerMode = 3); "
  .. "no-nameplate fallback stays the Sill lane; uid stable=%d changed=%d missing=%d")
  :format(cont.stable, cont.changed, cont.missing))
