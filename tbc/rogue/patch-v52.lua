-- rogue v51 -> v52: the TARGET CLUSTER is deleted, and threat comes home as YOUR outer ring.
--
-- WHY THE TARGET CLUSTER GOES. Its health arc, its live face and the black track behind them
-- were a third copy of a number the default UI already draws twice — the target frame you
-- clicked to select the target, and its nameplate — for the entire game. A HUD element earns
-- its place by changing the next button press, and a target health percentage 270px to the
-- right of your character never did. Removed, not shrunk, not moved: four auras go.
--
-- WHY THREAT DOES NOT GO WITH IT. Threat is the ONE thing that cluster carried that nothing
-- else in the game shows, and a dps who pulls aggro dies — dropping it would be a regression,
-- not a simplification. It becomes the OUTERMOST ring of the PLAYER cluster, which is also the
-- more honest home: it is YOUR threat. The target still names the table it is measured
-- against (the trigger is unchanged), but the arc is drawn on you, because the number is
-- about you.
--
--     THREAT_RING = 100        -- outermost, same Ring_20px art
--     OUTER       =  84        -- health, unchanged
--     INNER       =  62        -- energy, unchanged
--     PORTRAIT    =  44        -- unchanged
--     CLUSTER     = (-270, 40) -- the player cluster does not move by one pixel
--     PCT_THREAT  = font 10, CENTER, anchorYOffset 58   (was 54; the new outer radius is 50)
--
-- The >= 80% alphaPulse halo resizes 84 -> 100 with it, so it pulses ON the threat arc instead
-- of orbiting a radius nothing occupies any more.
--
-- THREAT KEEPS EVERYTHING IT HAS. Its Threat Situation trigger is copied across untouched,
-- `threatUnit` included: that argument was renamed to `unit` at internalVersion 51 and
-- WeakAuras' Modernize pass migrates data BELOW 51 forward, so this IV-45 string must emit the
-- old name and let the client rename it. Its escalations stay on `foregroundColor` (barColor
-- is aurabar-only and `color` is texture-only; Conditions.lua skips an unknown property
-- SILENTLY, so getting it wrong is a no-op rather than an error), its party/raid + not-arena
-- load gate is untouched, and so is the mandatory `threatvalue <= 0 -> alpha 0` guard, without
-- which a ProgressTexture with a zero total draws FULL and reports a complete circle of aggro
-- at the exact moment you have none. Because that gate travels with it, the common solo case
-- is still two rings and a face; the third arc appears only when threat is a real relationship.
--
-- ORPHANS ARE EXPECTED HERE, AND THAT IS THE POINT. Four uids now have no home:
--     Rogue - Target Cluster       HucL3GUXR4L   the group that held the other three
--     Rogue - Target Health Ring   XaXe7Ja77RQ   the duplicated health arc
--     Rogue - Target Portrait      RgOrbTgtFac   the duplicated face
--     Rogue - Target Ring Track    MafcyRCWM9e   v51's filler: an empty hoop that existed to
--                                                keep a spare uid alive and to make the two
--                                                clusters look symmetrical
-- Nothing is invented to absorb them. v51's ring track is exactly what "keep the slot alive"
-- looks like after a few versions, and it is the first thing this patch deletes. The removals
-- are declared to the verifier as WA-REMOVED lines in generate.lua, and because WeakAuras
-- never deletes an aura an import does not mention, the pack README tells the player to delete
-- the leftover `Rogue - Target Cluster` group by hand once.
--
-- NO uid() IS CALLED. This is a lineage replay step that only removes and re-homes, so it
-- consumes nothing from the random stream: math.randomseed and the uid() call ORDER are
-- untouched and every surviving aura keeps the uid it had in v41.
--
-- POSITIONS ARE ABSOLUTE. Nothing anchors to the screen directly: the cluster hangs off
-- `Rogue - Resources` which hangs off the pack's top group, and each carries an offset. The
-- chain is walked in the DECODED finished string at the bottom to prove the cluster still
-- lands on (-270, 40) and that all five surviving regions are concentric with it, and the
-- Alerts column clearance is projected six prompts deep rather than assumed from one.
--
-- WHAT THIS PATCH MAY NOT TOUCH: every trigger, gate, condition, colour and spell id outside
-- the two clusters — buffs, alerts, combo pips, cooldown row, procs, the PvP layer — is
-- asserted field by field against v51 at the bottom.
--
-- Run: lua5.1 tbc/rogue/patch-v52.lua   (rewrites all-specs.txt in place)

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local SCRIPTS = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local PACK = dir .. "/all-specs.txt"
local savedArg = arg
arg = { [0] = SCRIPTS .. "/wa_lib.lua" }
local W = dofile(SCRIPTS .. "/wa_lib.lua")
arg = savedArg

-- ===== the canonical geometry, shared verbatim by every pack ===========================
local MEDIA       = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\"
local RING_TEX    = MEDIA .. "Ring_20px.tga"
local THREAT_RING = 100  -- NEW outermost ring
local OUTER       = 84   -- health, unchanged
local INNER       = 62   -- energy, unchanged
local PORTRAIT    = 44   -- unchanged
local CLUSTER_X   = -270 -- ABSOLUTE screen position of the player cluster
local CLUSTER_Y   = 40

local PCT_THREAT_SIZE, PCT_THREAT_Y_BEFORE, PCT_THREAT_Y = 10, 54, 58
local COL_THREAT = { 0.25, 0.80, 0.30, 1 }
local COL_TRACK  = { 0, 0, 0, 0.55 }

local BEFORE_OUTER = 84  -- the diameter threat and its halo carried in v51

local PLAYER_GROUP = "Rogue - Player Cluster"
local TARGET_GROUP = "Rogue - Target Cluster"
local RES_GROUP    = "Rogue - Resources"
local THREAT       = "Rogue - Threat Ring"
local FLASH        = "Rogue - Threat Flash"
local HEALTH       = "Rogue - Health Ring"
local ENERGY       = "Rogue - Energy Ring"
local FACE         = "Rogue - Player Portrait"

-- The four auras v52 deletes. Duplicated as WA-REMOVED lines in generate.lua, which is where
-- tools/verify-packs.lua reads the licence for a disappearing uid.
local REMOVED = {
  TARGET_GROUP,
  "Rogue - Target Health Ring",
  "Rogue - Target Portrait",
  "Rogue - Target Ring Track",
}

-- The Alerts column is the one neighbour on this side of the screen. It is a dynamic group
-- that grows UP, so its footprint depends on how many prompts are showing; the clearance is
-- asserted with the stack PROJECTED, not with one child.
local ALERT_DEPTH = 6

-- ===== helpers =========================================================================
local function iseq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not iseq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

local function contains(list, value)
  for _, v in ipairs(list) do if v == value then return true end end
  return false
end

-- ===== read the v51 build ==============================================================
local f = assert(io.open(PACK, "r")); local src = f:read("*a"); f:close()
local T = W.decode(src)
local OLD = W.decode(src)

local byId = { [T.d.id] = T.d }
local oldById = { [OLD.d.id] = OLD.d }
for _, aura in ipairs(T.c) do byId[aura.id] = aura end
for _, aura in ipairs(OLD.c) do oldById[aura.id] = aura end

-- ===== the exact v51 state this patch expects ==========================================
local V51 = {
  [HEALTH]       = { parent = PLAYER_GROUP, kind = "progresstexture", size = OUTER },
  [ENERGY]       = { parent = PLAYER_GROUP, kind = "progresstexture", size = INNER },
  [FACE]         = { parent = PLAYER_GROUP, kind = "model",           size = PORTRAIT },
  [THREAT]       = { parent = TARGET_GROUP, kind = "progresstexture", size = BEFORE_OUTER },
  [FLASH]        = { parent = TARGET_GROUP, kind = "texture",         size = BEFORE_OUTER },
  ["Rogue - Target Health Ring"] = { parent = TARGET_GROUP, kind = "progresstexture", size = INNER },
  ["Rogue - Target Portrait"]    = { parent = TARGET_GROUP, kind = "model",   size = PORTRAIT },
  ["Rogue - Target Ring Track"]  = { parent = TARGET_GROUP, kind = "texture", size = BEFORE_OUTER },
}
for id, want in pairs(V51) do
  local aura = assert(byId[id], "v51 state missing: " .. id)
  assert(aura.parent == want.parent,
    ("%s hangs off %s, expected %s"):format(id, tostring(aura.parent), want.parent))
  assert(aura.regionType == want.kind, id .. " is not a " .. want.kind)
  assert(aura.width == want.size and aura.height == want.size,
    ("%s is %sx%s, expected %d"):format(id, tostring(aura.width), tostring(aura.height), want.size))
end
local playerGroup = assert(byId[PLAYER_GROUP], "the player cluster is missing")
local targetGroup = assert(byId[TARGET_GROUP], "the target cluster is missing")
local RES = assert(byId[RES_GROUP], "the resources group is missing")
assert(iseq(playerGroup.controlledChildren, { HEALTH, ENERGY, FACE }),
  "the v51 player cluster is not health + energy + face")
assert(iseq(targetGroup.controlledChildren,
  { "Rogue - Target Ring Track", THREAT, "Rogue - Target Health Ring", FLASH, "Rogue - Target Portrait" }),
  "the v51 target cluster is not the five regions this patch expects")
local threat, flash = byId[THREAT], byId[FLASH]
assert(#threat.subRegions == 1 and threat.subRegions[1].type == "subtext"
  and threat.subRegions[1].anchorYOffset == PCT_THREAT_Y_BEFORE
  and threat.subRegions[1].text_fontSize == PCT_THREAT_SIZE,
  "the v51 threat percentage is not the 10pt label at +54 this patch moves")
assert(flash.animation.main.preset == "alphaPulse",
  "the threat halo is not the alphaPulse overlay")

-- ===== delete the target cluster =======================================================
local doomed = {}
for _, id in ipairs(REMOVED) do
  assert(byId[id], "cannot remove a region that is not there: " .. id)
  doomed[id] = true
end
-- The two survivors move FIRST, so nothing is ever parented to a group that no longer exists.
threat.parent, flash.parent = PLAYER_GROUP, PLAYER_GROUP
threat.width, threat.height = THREAT_RING, THREAT_RING
flash.width,  flash.height  = THREAT_RING, THREAT_RING
threat.subRegions[1].anchorYOffset = PCT_THREAT_Y

-- Sibling order is layering: FixGroupChildrenOrder adds +4 frame levels per child, so EARLIER
-- = further behind. Threat leads (it is the outermost band and must never draw over an inner
-- arc), the face goes last so nothing draws over it — the same order paladin and mage ship.
playerGroup.controlledChildren = { THREAT, HEALTH, ENERGY, FLASH, FACE }

local kept = {}
for _, aura in ipairs(T.c) do
  if not doomed[aura.id] then kept[#kept + 1] = aura end
end
T.c = kept

local resKids = {}
for _, id in ipairs(RES.controlledChildren) do
  if not doomed[id] then resKids[#resKids + 1] = id end
end
RES.controlledChildren = resKids

-- ===== verify ==========================================================================
local encoded = W.encode(T)
W.verify(T, encoded)
local cont = W.uidContinuityStrings(encoded, src)
W.assertUidContinuity(cont, "rogue v52", REMOVED)
assert(cont.changed == 0, "rogue v52: an existing id changed uid")
assert(cont.parentSame, "rogue v52: the top-level uid changed")
assert(cont.missing == #REMOVED,
  ("rogue v52: %d uids went missing, this patch removes exactly %d")
    :format(cont.missing, #REMOVED))
assert(cont.oldCount - cont.newCount == #REMOVED, "rogue v52: the aura count moved by the wrong amount")
for _, id in ipairs(cont.missingIds) do
  assert(contains(REMOVED, id), "rogue v52: an undeclared aura disappeared: " .. id)
end
assert(cont.stable == cont.newCount, "rogue v52: a surviving aura did not keep both its id and uid")

local NEW = W.decode(encoded)
local newById = { [NEW.d.id] = NEW.d }
for _, aura in ipairs(NEW.c) do newById[aura.id] = aura end

-- AUDIT 1: the four removals are gone from the string COMPLETELY — not just from the child
-- list, but from every parent pointer, every controlledChildren entry and every other string
-- field (a stale anchor or condition reference would decode fine and break in game).
for _, id in ipairs(REMOVED) do
  assert(newById[id] == nil, id .. " is still in the shipped string")
end
local function scan(node, path, seen)
  for k, v in pairs(node) do
    if type(v) == "table" then
      if not seen[v] then seen[v] = true; scan(v, path .. "." .. tostring(k), seen) end
    elseif type(v) == "string" then
      for _, id in ipairs(REMOVED) do
        assert(v ~= id, ("%s%s still names the removed %q"):format(path, "." .. tostring(k), id))
      end
    end
  end
end
scan(NEW, "root", {})
for _, uid in ipairs({ "HucL3GUXR4L", "XaXe7Ja77RQ", "RgOrbTgtFac", "MafcyRCWM9e" }) do
  for _, aura in ipairs(NEW.c) do
    assert(aura.uid ~= uid, aura.id .. " recycled a deleted region's uid: " .. uid)
  end
end
-- and no surviving region reads the target's health any more. Only `type = "unit"` triggers
-- count: an aura2 (buff/debuff) trigger carries `event = "Health"` as an inert stub field and
-- watching your own DoT on the target is not a health readout.
for _, aura in ipairs(NEW.c) do
  for _, wrapped in ipairs(aura.triggers or {}) do
    local tr = wrapped.trigger or {}
    assert(not (tr.type == "unit" and tr.event == "Health" and tr.unit == "target"),
      aura.id .. ": a target health readout survived the cull")
  end
end

-- AUDIT 2: absolute screen position, walked up the parent chain exactly as WeakAuras anchors
-- it, recovered from the ENCODED string so it cannot pass by reading back the variable that
-- wrote it.
local function absolute(id)
  local x, y = 0, 0
  local node = assert(newById[id], "missing region " .. id)
  while node do
    assert(node.anchorFrameType == "SCREEN" and node.selfPoint == "CENTER"
      and node.anchorPoint == "CENTER", id .. ": " .. node.id .. " is not centre-anchored")
    x, y = x + (node.xOffset or 0), y + (node.yOffset or 0)
    node = node.parent and assert(newById[node.parent], "unresolved parent " .. node.parent)
  end
  return x, y
end

for _, id in ipairs({ PLAYER_GROUP, THREAT, HEALTH, ENERGY, FLASH, FACE }) do
  local x, y = absolute(id)
  assert(x == CLUSTER_X and y == CLUSTER_Y,
    ("%s lands at (%d,%d); the cluster is at (%d,%d)"):format(id, x, y, CLUSTER_X, CLUSTER_Y))
  if id ~= PLAYER_GROUP then
    local aura = newById[id]
    assert(aura.parent == PLAYER_GROUP, id .. " is not in the player cluster")
    assert(aura.xOffset == 0 and aura.yOffset == 0, id .. " is not concentric in the cluster")
  end
end

-- AUDIT 3: the Alerts column, with the stack PROJECTED six prompts deep. It grows UP from a
-- BOTTOM self-point, so its rows climb into the cluster's y range; the clearance that matters
-- is horizontal and it must hold at every depth.
do
  local alerts = assert(newById["Rogue - Alerts"], "the Alerts column is missing")
  assert(alerts.regionType == "dynamicgroup" and alerts.grow == "UP" and alerts.selfPoint == "BOTTOM",
    "the Alerts column is no longer an upward dynamic group; re-derive this clearance")
  local ax, ay = alerts.xOffset, alerts.yOffset
  local node = alerts.parent and newById[alerts.parent]
  while node do
    ax, ay = ax + (node.xOffset or 0), ay + (node.yOffset or 0)
    node = node.parent and newById[node.parent]
  end
  local widest = 0
  for _, id in ipairs(alerts.controlledChildren) do
    widest = math.max(widest, newById[id].width or 0)
  end
  local tall = 0
  for _, id in ipairs(alerts.controlledChildren) do
    tall = math.max(tall, newById[id].height or 0)
  end
  local cx, cy = absolute(THREAT)
  local ringLeft, ringRight = cx - THREAT_RING / 2, cx + THREAT_RING / 2
  local ringBottom, ringTop = cy - THREAT_RING / 2, cy + THREAT_RING / 2
  local gap, overlapped = math.huge, false
  for i = 1, ALERT_DEPTH do
    local bottom = ay + (i - 1) * (tall + alerts.space)
    local top = bottom + tall
    local left, right = ax - widest / 2, ax + widest / 2
    local rowsOverlap = not (top < ringBottom or bottom > ringTop)
    if rowsOverlap then overlapped = true end
    assert(right < ringLeft or left > ringRight,
      ("alert %d spans x %.0f..%.0f and hits the %dpx threat ring at %.0f..%.0f")
        :format(i, left, right, THREAT_RING, ringLeft, ringRight))
    gap = math.min(gap, left - ringRight)
  end
  assert(overlapped, "the projected alert stack never reaches the cluster's rows; re-check the projection")
  print(("alerts: %d deep, x %.0f..%.0f vs threat ring %.0f..%.0f — clears by %.0fpx at every depth")
    :format(ALERT_DEPTH, ax - widest / 2, ax + widest / 2, ringLeft, ringRight, gap))
end

-- AUDIT 4: the threat ring itself — canonical ring art at the new diameter, everything else
-- carried over from v51 field for field.
do
  local r = newById[THREAT]
  local was = oldById[THREAT]
  assert(r.regionType == "progresstexture", "threat is not a progresstexture")
  assert(r.width == THREAT_RING and r.height == THREAT_RING,
    ("the threat ring is %sx%s, not %d"):format(tostring(r.width), tostring(r.height), THREAT_RING))
  assert(r.orientation == "CLOCKWISE", "the threat ring is not radial")
  assert(r.startAngle == 0 and r.endAngle == 360, "the threat ring is not a full circle")
  assert(r.crop_x == 0.41 and r.crop_y == 0.41, "threat crop is not the circular identity value")
  assert(r.auraRotation == 0 and r.backgroundOffset == 0, "threat rotation/offset drifted")
  assert(r.foregroundTexture == RING_TEX and r.backgroundTexture == RING_TEX and r.sameTexture,
    "the threat ring is not drawn on the canonical ring art")
  assert(iseq(r.foregroundColor, COL_THREAT), "the threat base colour changed")
  assert(iseq(r.backgroundColor, COL_TRACK), "the threat track colour changed")
  -- it is genuinely OUTSIDE health: Ring_20px's stroke is 20/256 of the drawn size
  local threatInner = THREAT_RING / 2 - THREAT_RING * 20 / 256
  assert(threatInner >= OUTER / 2,
    ("the threat band reaches r=%.2f and overlaps the %dpx health ring"):format(threatInner, OUTER))
  -- the percentage clears the new outer radius
  local st = r.subRegions[1]
  assert(#r.subRegions == 1 and st.type == "subtext", "the threat label was disturbed")
  assert(st.text_fontSize == PCT_THREAT_SIZE and st.text_anchorPoint == "CENTER"
    and st.anchorXOffset == 0 and st.anchorYOffset == PCT_THREAT_Y,
    "the threat percentage is not the 10pt CENTER label at +58")
  assert(PCT_THREAT_Y > THREAT_RING / 2, "the threat percentage sits inside the new outer ring")
  for key in pairs(was) do
    if key ~= "parent" and key ~= "width" and key ~= "height" and key ~= "subRegions" then
      assert(iseq(was[key], r[key]), "threat lost or changed " .. key .. ", which v52 may not touch")
    end
  end
  for key in pairs(r) do assert(was[key] ~= nil, "threat gained field " .. key) end
  for key, v in pairs(was.subRegions[1]) do
    if key ~= "anchorYOffset" then
      assert(iseq(v, st[key]), "the threat label changed " .. key)
    end
  end
  -- the trigger, spelled the way IV-45 data has to spell it
  local tr = r.triggers[1].trigger
  assert(tr.event == "Threat Situation" and tr.type == "unit", "the threat trigger changed event")
  assert(tr.threatUnit == "target" and tr.use_threatUnit == true,
    "the threat trigger lost threatUnit; on internalVersion 45 data that argument is not `unit`")
  assert(iseq(r.triggers, was.triggers), "the threat trigger changed")
  assert(iseq(r.load, was.load), "the threat load gate changed")
  assert(r.load.use_ingroup and r.load.ingroup.multi.group and r.load.ingroup.multi.raid,
    "the party/raid gate is gone")
  assert(r.load.size.multi.arena == nil, "the never-in-arena gate is gone")
  -- the escalations, on the only property a progresstexture actually reads
  assert(#r.conditions == 3, "a threat condition was lost")
  for _, cond in ipairs(r.conditions) do
    for _, change in ipairs(cond.changes) do
      assert(change.property ~= "color" and change.property ~= "barColor",
        "a threat condition drives a property that is a SILENT no-op on a progresstexture")
    end
  end
  assert(r.conditions[1].check.variable == "threatpct" and r.conditions[1].check.value == "70"
    and r.conditions[1].changes[1].property == "foregroundColor", "the 70% escalation changed")
  assert(r.conditions[2].check.variable == "aggro"
    and r.conditions[2].changes[1].property == "foregroundColor", "the aggro escalation changed")
  assert(r.conditions[3].check.variable == "threatvalue" and r.conditions[3].check.op == "<="
    and r.conditions[3].changes[1].property == "alpha" and r.conditions[3].changes[1].value == 0,
    "the mandatory zero-threat alpha guard is gone")
end

-- AUDIT 5: the halo pulses ON the new ring, and is otherwise the v51 region.
do
  local h, was = newById[FLASH], oldById[FLASH]
  assert(h.width == THREAT_RING and h.height == THREAT_RING and h.texture == RING_TEX,
    "the threat halo did not follow the ring out to 100")
  assert(h.animation.main.preset == "alphaPulse" and h.animation.main.type == "preset",
    "the halo stopped pulsing")
  assert(h.triggers[1].trigger.threatpct == "80" and h.triggers[1].trigger.threatpct_operator == ">=",
    "the halo is no longer the >= 80% warning")
  for key in pairs(was) do
    if key ~= "parent" and key ~= "width" and key ~= "height" then
      assert(iseq(was[key], h[key]), "the halo changed " .. key .. ", which v52 may not touch")
    end
  end
  for key in pairs(h) do assert(was[key] ~= nil, "the halo gained field " .. key) end
end

-- AUDIT 6: the three surviving rings are untouched, to the byte.
for _, id in ipairs({ HEALTH, ENERGY, FACE }) do
  local a, b = oldById[id], newById[id]
  assert(iseq(a, b), id .. " changed, and v52 only removes the target cluster and re-homes threat")
end
assert(newById[HEALTH].width == OUTER and newById[ENERGY].width == INNER
  and newById[FACE].width == PORTRAIT, "the surviving cluster is not 84 / 62 / 44")

-- AUDIT 7: nothing outside the cluster changed, at all. Every surviving aura is compared field
-- by field against v51; the player cluster may differ only in controlledChildren, and the
-- resources group only by losing the target cluster from its child list.
local TOUCHED = { [THREAT] = true, [FLASH] = true, [PLAYER_GROUP] = true, [RES_GROUP] = true }
assert(iseq(OLD.d, NEW.d), "the top-level group changed")
local expectedIndex = 0
for _, old in ipairs(OLD.c) do
  if not doomed[old.id] then
    expectedIndex = expectedIndex + 1
    assert(NEW.c[expectedIndex].id == old.id,
      ("aura order changed at %d: %s"):format(expectedIndex, NEW.c[expectedIndex].id))
    local new = newById[old.id]
    if not TOUCHED[old.id] then
      for key in pairs(old) do
        assert(iseq(old[key], new[key]),
          ("%s: %s changed, and v52 may only cull the target cluster"):format(old.id, key))
      end
      for key in pairs(new) do assert(old[key] ~= nil, old.id .. ": gained field " .. key) end
    end
  end
end
assert(expectedIndex == #NEW.c, "an aura appeared out of nowhere")
do
  local a, b = oldById[PLAYER_GROUP], newById[PLAYER_GROUP]
  for key in pairs(a) do
    if key ~= "controlledChildren" then
      assert(iseq(a[key], b[key]), PLAYER_GROUP .. ": " .. key .. " changed")
    end
  end
  assert(iseq(b.controlledChildren, { THREAT, HEALTH, ENERGY, FLASH, FACE }),
    "the player cluster is not threat / health / energy / halo / face")
  for _, id in ipairs(a.controlledChildren) do
    assert(contains(b.controlledChildren, id), PLAYER_GROUP .. " dropped " .. id)
  end
end
do
  local a, b = oldById[RES_GROUP], newById[RES_GROUP]
  for key in pairs(a) do
    if key ~= "controlledChildren" then
      assert(iseq(a[key], b[key]), RES_GROUP .. ": " .. key .. " changed")
    end
  end
  assert(#a.controlledChildren - #b.controlledChildren == 1,
    RES_GROUP .. ": exactly one child (the target cluster) should have gone")
  local j = 0
  for _, id in ipairs(a.controlledChildren) do
    if id ~= TARGET_GROUP then
      j = j + 1
      assert(b.controlledChildren[j] == id, RES_GROUP .. ": child order changed at " .. j)
    end
  end
end

local out = assert(io.open(PACK, "w")); out:write(encoded); out:close()
local px, py = absolute(THREAT)
print(("audit ok: player cluster (%d,%d) — absolute, chain-walked; threat %d concentric with %d/%d/%d")
  :format(px, py, THREAT_RING, OUTER, INNER, PORTRAIT))
print(("removed %d auras: %s"):format(#REMOVED, table.concat(REMOVED, ", ")))
print(("uid continuity: stable=%d changed=%d retained=%d missing=%d (%s) parentSame=%s")
  :format(cont.stable, cont.changed, cont.retained, cont.missing,
    table.concat(cont.missingIds, ", "), tostring(cont.parentSame)))
print(("wrote %s (%d auras, %d chars)"):format(PACK, #T.c + 1, #encoded))
