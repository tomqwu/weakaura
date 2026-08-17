-- rogue v53 -> v54: THE SILL. The 100x100 concentric ring cluster becomes a 102x37 instrument
-- strip of four stacked 100px rails, parked under your character at absolute (0, -110).
--
-- THE THESIS. A ring buys gauge length with area squared: Ring_20px's stroke is 20/256 of the
-- drawn size, so a 100px threat ring spends 10,000 px2 to draw a 289.6px arc of a quantity that
-- has exactly 100 distinguishable states. A 100px RAIL carries the same 100 states in 100px, and
-- it makes every breakpoint arithmetic instead of trigonometric:
--
--     x(v) = (v / maxpower - 0.5) * 100   which for a 100-max resource is simply  x = v - 50
--
-- The 35-energy Eviscerate mark stops being (23.575, -17.128) on a circumference and becomes
-- x = -15 on a straight line. One pixel is one percent, and the number printed at the right-hand
-- end of each rail finally agrees with the scale it sits on.
--
-- WHAT THE STRIP IS (all offsets local to `Rogue - Player Sill`, which resolves to (0,-110)),
-- listed in DRAW ORDER, which is `controlledChildren` order:
--
--     lane            region                 w x h     local (x,y)     absolute y span
--     Alarm rim       texture                108 x 43  (0,    0)       -131.5 .. -88.5
--     Sill Plate      texture   (was model)  102 x 37  (0,    0)       -128.5 .. -91.5
--     Threat rail     progresstexture        100 x  4  (0, +15.5)       -96.5 .. -92.5
--     Health rail     progresstexture        100 x 11  (0,   +7)       -108.5 .. -97.5
--     Power rail      progresstexture        100 x 11  (0,   -5)       -120.5 .. -109.5
--     Combo lane      10 textures            16 x  6   (xp, -14.5)     -127.5 .. -121.5
--
--   4 + 1 + 11 + 1 + 11 + 1 + 6 = 35 content rows spanning local +17.5 .. -17.5, and the plate
--   adds a 1px margin all round -> 102 x 37. Pip pitch is 20px at x -40,-20,0,+20,+40.
--
-- THE ALARM IS A FILLED QUAD, SO IT IS A RIM AND NOT AN OUTLINE. Square_White_Border.tga is a
-- FILLED square -- it is the art this pack's dark combo SOCKETS are drawn from, and the lit pip
-- of the same size and position covers the socket completely. A single region on that texture
-- therefore CANNOT trace a hollow edge. So the >=80% threat flare is not stacked on top of the
-- instrument, where an ADD red at 0.85 would wash the health green and the energy yellow into
-- one colour at the exact moment the rogue must read energy and combo points. Instead it is
-- 3px LARGER than the plate on every side and is drawn FIRST, underneath everything:
--
--     * the 3px band that sticks out past the plate is the only place it draws at full
--       strength -- a pulsing red rim around the whole instrument;
--     * inside the plate it sits behind a 45%-black quad and behind every rail, number and
--       pip, so NOTHING is composited over a readout and every colour code survives;
--     * its footprint is only spent while it is up: the plate is 102x37 = 3,774 px2, the
--       alarm envelope is 108x43 = 4,644 px2 and exists only at >=80% threat.
--
-- WHY (0,-110) AND NOT THE WAIST. A rectangle scan of this pack, dynamic groups projected six
-- children deep, returns ZERO overlaps at (0,-110) for the full envelope -- the 108x43 alarm
-- box widened to the 54.8px the combo pips reach at the peak of their 1.85x pop -- with 4.5px
-- of clearance to the buff row (y -176..-136) and 39.2px of horizontal clearance to the proc
-- column. The plate alone clears by 7.5px. The strip sits UNDER the character, which is where
-- it was asked to go. The scan is re-run from the finished string at the bottom of this file,
-- not asserted from this comment.
--
-- WHERE THE PIPS WENT. The five combo pips had their own 172x14 row at y -87..-73 while the
-- energy ring was at (-270,+40) -- 233px centre-to-centre, 153px of clear screen edge-to-edge,
-- so "do I have the points" and "can I afford the finisher" were two fixations at opposite
-- ends of the HUD. The ten textures are re-parented into the sill and resized 32x14 -> 16x6,
-- 1px below the power rail (9.5px centre-to-centre). That frees the whole combo row and folds
-- 12,408 px2 of HUD into 3,774.
--
-- NO uid() IS CALLED. Every region in the strip is an existing aura that changed job:
--
--     Rogue - Player Cluster   -> Rogue - Player Sill      (group, moved)
--     Rogue - Player Portrait  -> Rogue - Sill Plate       (model -> texture, 44 -> 102x37)
--     Rogue - Threat Ring      -> Rogue - Threat Rail      (100x100 -> 100x4)
--     Rogue - Health Ring      -> Rogue - Health Rail      (84x84  -> 100x11)
--     Rogue - Energy Ring      -> Rogue - Energy Rail      (62x62  -> 100x11)
--     Rogue - Threat Flash     -> Rogue - Alarm Frame      (100px ring halo -> 108x43 rim)
--     Rogue - Combo Socket/Point 1..5                      (re-parented, resized)
--
-- Re-parenting, renaming, re-typing and resizing consume nothing from the random stream, so
-- math.randomseed and the uid() call order are untouched: 58 auras in, 58 out, changed = 0,
-- missing = 0. The pack seed stays 20260809.
--
-- WHAT THIS PATCH MAY NOT TOUCH: every trigger, every load gate, every condition and every
-- colour. The threat escalations (70 -> orange, aggro -> red, threatvalue <= 0 -> alpha 0), the
-- 30% health red, the maxhealth/maxpower guards, the out-of-combat 50% fade, the party/raid and
-- never-in-arena gates, the 80% alarm trigger and its alphaPulse, the pip pop animation, the
-- green->orange pip ramp, the `%p` raw-energy token, and the sub.4/sub.5 condition indexes on
-- the power rail. All of it is diffed field by field against v53 at the bottom; only the keys
-- listed in ALLOWED below may differ, and only on the regions listed there.
--
-- Run: lua5.1 tbc/rogue/patch-v54.lua   (rewrites all-specs.txt in place)

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local SCRIPTS = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local PACK = dir .. "/all-specs.txt"
local savedArg = arg
arg = { [0] = SCRIPTS .. "/wa_lib.lua" }
local W = dofile(SCRIPTS .. "/wa_lib.lua")
arg = savedArg

-- ===== art ==============================================================================
local MEDIA      = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\"
local RING_TEX   = MEDIA .. "Ring_20px.tga"
local SQUARE     = MEDIA .. "Square_White.tga"
local SQUARE_BRD = MEDIA .. "Square_White_Border.tga"
local WRAP       = "CLAMPTOBLACKADDITIVE"

-- ===== geometry =========================================================================
local SILL_X, SILL_Y = 0, -110      -- absolute screen position of the whole instrument
local RAIL_LEN       = 100          -- one pixel is one percent; this is the lossless length
local MAXPOWER       = 100          -- energy cap without Vigor; see the note in the README
local PLATE_W, PLATE_H = 102, 37
local RIM              = 3          -- how far the alarm sticks out past the plate, per side
local ALARM_W, ALARM_H = PLATE_W + 2 * RIM, PLATE_H + 2 * RIM

local LANE = {
  plate  = { w = PLATE_W, h = PLATE_H, x = 0, y = 0 },
  threat = { w = RAIL_LEN, h = 4,  x = 0, y = 15.5 },
  health = { w = RAIL_LEN, h = 11, x = 0, y = 7 },
  power  = { w = RAIL_LEN, h = 11, x = 0, y = -5 },
  alarm  = { w = ALARM_W, h = ALARM_H, x = 0, y = 0 },
}
local PIP_W, PIP_H, PIP_Y = 16, 6, -14.5
local PIP_X = { -40, -20, 0, 20, 40 }

-- The one formula that replaces r*sin/r*cos. v is an absolute resource value.
local function markX(v) return (v / MAXPOWER - 0.5) * RAIL_LEN end

local NOTCH_THREAT = 70    -- "stop or dump" — the threat rail's only printed breakpoint
local EVISCERATE   = 35
local SINISTER     = 40
local RULER        = { -25, 0, 25 }   -- quarter ticks, x = v - 50 at 25 / 50 / 75

local LABEL_X, LABEL_SIZE = 32, 11    -- numbers print INSIDE their own rail, right-hand end

-- ===== ids ==============================================================================
local RES_GROUP = "Rogue - Resources"
local GROUP     = "Rogue - Player Sill"
local PLATE     = "Rogue - Sill Plate"
local THREAT    = "Rogue - Threat Rail"
local HEALTH    = "Rogue - Health Rail"
local POWER     = "Rogue - Energy Rail"
local ALARM     = "Rogue - Alarm Frame"

local RENAME = {
  ["Rogue - Player Cluster"]  = GROUP,
  ["Rogue - Player Portrait"] = PLATE,
  ["Rogue - Threat Ring"]     = THREAT,
  ["Rogue - Health Ring"]     = HEALTH,
  ["Rogue - Energy Ring"]     = POWER,
  ["Rogue - Threat Flash"]    = ALARM,
}
local RENAME_ORDER = { "Rogue - Player Cluster", "Rogue - Player Portrait", "Rogue - Threat Ring",
                       "Rogue - Health Ring", "Rogue - Energy Ring", "Rogue - Threat Flash" }

local function socket(i) return ("Rogue - Combo Socket %d"):format(i) end
local function pip(i)    return ("Rogue - Combo Point %d"):format(i) end

-- Draw order IS controlledChildren order: FixGroupChildrenOrder gives each child +4 frame
-- levels in list order, so later = on top. The alarm is FIRST and the plate second, because
-- the alarm is a filled quad: put it last and it covers the whole instrument in ADD red.
-- First, and 3px oversized, it shows only as a rim around the plate, and every readout --
-- rails, numbers, sockets, lit pips -- draws over it.
local SILL_ORDER = { ALARM, PLATE, THREAT, HEALTH, POWER }
for i = 1, 5 do
  SILL_ORDER[#SILL_ORDER + 1] = socket(i)
  SILL_ORDER[#SILL_ORDER + 1] = pip(i)
end

-- ===== helpers ==========================================================================
local function iseq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not iseq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

local function indexOf(list, value)
  for i, v in ipairs(list) do if v == value then return i end end
  return nil
end

local function keyset(t)
  local ks = {}
  for k in pairs(t) do ks[#ks + 1] = k end
  table.sort(ks)
  return ks
end

-- ===== read the v53 build ===============================================================
local f = assert(io.open(PACK, "r")); local src = f:read("*a"); f:close()
local T = W.decode(src)
local OLD = W.decode(src)

local byId = { [T.d.id] = T.d }
for _, aura in ipairs(T.c) do byId[aura.id] = aura end
local oldById = { [OLD.d.id] = OLD.d }
for _, aura in ipairs(OLD.c) do oldById[aura.id] = aura end

-- ===== the exact v53 state this patch expects ===========================================
local V53 = {
  ["Rogue - Threat Ring"]     = { kind = "progresstexture", size = 100, subs = 1 },
  ["Rogue - Health Ring"]     = { kind = "progresstexture", size = 84,  subs = 1 },
  ["Rogue - Energy Ring"]     = { kind = "progresstexture", size = 62,  subs = 5 },
  ["Rogue - Threat Flash"]    = { kind = "texture",         size = 100 },
  ["Rogue - Player Portrait"] = { kind = "model",           size = 44,  subs = 0 },
}
for id, want in pairs(V53) do
  local aura = assert(byId[id], "v53 state missing: " .. id)
  assert(aura.parent == "Rogue - Player Cluster", id .. " does not hang off the player cluster")
  assert(aura.regionType == want.kind, id .. " is not a " .. want.kind)
  assert(aura.width == want.size and aura.height == want.size,
    ("%s is %sx%s, expected the %dpx ring"):format(id, tostring(aura.width),
      tostring(aura.height), want.size))
  if want.subs then
    assert(#(aura.subRegions or {}) == want.subs,
      ("%s has %d subregions, expected %d"):format(id, #(aura.subRegions or {}), want.subs))
  end
  if want.kind == "progresstexture" then
    assert(aura.orientation == "CLOCKWISE", id .. " is not a clockwise ring")
    assert(aura.foregroundTexture == RING_TEX and aura.backgroundTexture == RING_TEX,
      id .. " is not drawn on Ring_20px")
  end
end
do
  local cluster = assert(byId["Rogue - Player Cluster"], "the player cluster is missing")
  assert(iseq(cluster.controlledChildren,
    { "Rogue - Player Portrait", "Rogue - Threat Ring", "Rogue - Health Ring",
      "Rogue - Energy Ring", "Rogue - Threat Flash" }),
    "the v53 cluster is not face / threat / health / energy / halo — re-derive this patch")
  assert(cluster.xOffset == -270 and cluster.yOffset == 124,
    "the v53 cluster is not at (-270,124) under Rogue - Resources")
end
for i = 1, 5 do
  for _, id in ipairs({ socket(i), pip(i) }) do
    local a = assert(byId[id], "missing " .. id)
    assert(a.parent == RES_GROUP, id .. " is not in the combo row")
    assert(a.regionType == "texture" and a.width == 32 and a.height == 14,
      id .. " is not the 32x14 v53 pip")
    assert(a.texture == SQUARE_BRD, id .. " is not on Square_White_Border")
  end
end
-- The alarm frame's colour is the one field the design brief flagged as possibly empty. It is
-- not: v53 ships an explicit red. Asserted so the claim in the README is checked, not repeated.
do
  local flash = byId["Rogue - Threat Flash"]
  assert(type(flash.color) == "table" and #flash.color == 4,
    "Rogue - Threat Flash ships no explicit colour; the alarm frame would draw in WA's default")
  assert(iseq(flash.color, { 1, 0.1, 0.1, 0.85 }),
    "Rogue - Threat Flash is not (1, 0.1, 0.1, 0.85); re-derive the alarm colour")
end

-- ===== rename ===========================================================================
local function rename(oldId, newId)
  local aura = assert(byId[oldId], "missing " .. oldId)
  assert(byId[newId] == nil, "id collision: " .. newId)
  aura.id = newId
  byId[oldId], byId[newId] = nil, aura
  for _, node in pairs(byId) do
    if node.parent == oldId then node.parent = newId end
    local cc = node.controlledChildren
    if cc then for i, cid in ipairs(cc) do if cid == oldId then cc[i] = newId end end end
  end
  return aura
end
for _, oldId in ipairs(RENAME_ORDER) do rename(oldId, RENAME[oldId]) end

-- ===== the group: absolute (0,-110) by arithmetic on the real parent chain ==============
local sill = byId[GROUP]
do
  local x, y, node = 0, 0, byId[sill.parent]
  while node do
    x, y = x + (node.xOffset or 0), y + (node.yOffset or 0)
    node = node.parent and byId[node.parent] or nil
  end
  -- x/y is now the absolute position of `Rogue - Resources`; the sill's own offset is
  -- whatever takes that to (0,-110). Nothing else in the pack moves.
  sill.xOffset, sill.yOffset = SILL_X - x, SILL_Y - y
end
sill.controlledChildren = { unpack(SILL_ORDER) }

-- ===== lane 0: the Sill Plate (model -> texture) ========================================
-- The portrait's UID moves onto the plate. That is the v47/v51 precedent: a UID belongs to a
-- slot in the pack, not to a region type. A model region carries no text and no fill; a dark
-- bordered plate is what makes an 11px rail and an 11pt number survive a bright floor, which
-- was the original complaint the ring cluster never solved.
local MODEL_ONLY = { "advance", "api", "backdropColor", "border", "borderBackdrop", "borderColor",
  "borderEdge", "borderInset", "borderOffset", "borderSize", "modelDisplayInfo", "modelIsUnit",
  "model_fileId", "model_path", "model_st_rx", "model_st_ry", "model_st_rz", "model_st_tx",
  "model_st_ty", "model_st_tz", "model_st_us", "model_x", "model_y", "model_z", "portraitZoom",
  "sequence", "subRegions" }
local PLATE_COLOR = { 0, 0, 0, 0.45 }
do
  local plate = byId[PLATE]
  for _, key in ipairs(MODEL_ONLY) do plate[key] = nil end
  plate.regionType        = "texture"
  plate.texture           = SQUARE_BRD
  plate.textureWrapMode   = WRAP
  plate.color             = { unpack(PLATE_COLOR) }
  plate.blendMode         = "BLEND"
  plate.desaturate        = false
  plate.discrete_rotation = 0
  plate.mirror            = false
  plate.rotate            = false
  plate.width, plate.height   = LANE.plate.w, LANE.plate.h
  plate.xOffset, plate.yOffset = LANE.plate.x, LANE.plate.y
end

-- ===== lanes 1-3: the rails =============================================================
-- HORIZONTAL is progresstexture's "Left to Right". (HORIZONTAL on a progresstexture is
-- Right to Left — it means the opposite of what it means on an aurabar. See the README.)
local function toRail(id, lane)
  local a = byId[id]
  a.orientation        = "HORIZONTAL"
  a.foregroundTexture  = SQUARE
  a.backgroundTexture  = SQUARE
  a.width, a.height    = lane.w, lane.h
  a.xOffset, a.yOffset = lane.x, lane.y
  return a
end
local threat = toRail(THREAT, LANE.threat)
local health = toRail(HEALTH, LANE.health)
local power  = toRail(POWER,  LANE.power)

-- The subtexture schema is copied off the shipped 35-energy pip, so a new waterline cannot
-- invent or drop a key relative to what this pack already ships.
local SUB_TEMPLATE = oldById["Rogue - Energy Ring"].subRegions[2]
local function waterline(x, w, h, color, visible)
  return {
    anchor_mode = "point", anchor_point = "CENTER", self_point = "CENTER",
    width = w, height = h, xOffset = x, yOffset = 0,
    mirror = false, rotate = false, scale = 1,
    textureBlendMode = "BLEND",
    textureColor = { unpack(color) },
    textureDesaturate = false, textureMirror = false, textureRotate = false,
    textureRotation = 0,
    textureTexture = SQUARE,
    textureVisible = visible,
    type = "subtexture",
  }
end
do
  local sample = waterline(0, 1, 1, { 1, 1, 1, 1 }, true)
  assert(iseq(keyset(sample), keyset(SUB_TEMPLATE)),
    "the waterline schema does not match the subtexture this pack already ships")
end

-- Threat rail. sub.1 is switched OFF, not deleted: the index is preserved so nothing shifts,
-- and the checkbox is one click away in /wa. `threatpct` is scaled so 100 = pulling aggro, so
-- it is an early-warning ratio, not a quantity — a notch at the 70 line answers it faster.
threat.subRegions[1].text_visible = false
threat.subRegions[2] = waterline(markX(NOTCH_THREAT), 2, LANE.threat.h, { 1, 1, 1, 0.85 }, true)

-- Health rail: the number moves INSIDE the rail at its right-hand end, and three quarter ticks
-- turn "estimate a fraction" into "count quarters" for 33px of ink and zero footprint.
do
  local label = health.subRegions[1]
  -- BOTH SPELLINGS. WeakAuras anchors on text_anchor*Offset (SubText.lua); the bare
  -- anchor*Offset is what its default() writes and nothing reads, with no Modernize bridge.
  label.anchorXOffset, label.anchorYOffset = LABEL_X, 0
  label.text_anchorXOffset, label.text_anchorYOffset = LABEL_X, 0
  label.text_fontSize = LABEL_SIZE
  for i, x in ipairs(RULER) do
    health.subRegions[1 + i] = waterline(x, 1, LANE.health.h, { 1, 1, 1, 0.18 }, true)
  end
end

-- Power rail: the same label move, and the four 35/40 marks stop being trigonometry. sub.4 and
-- sub.5 KEEP THEIR INDEXES — two shipped conditions address them by index, which is exactly why
-- these rails are progresstexture and not aurabar (an aurabar_bar subregion would occupy sub.1
-- and push every mark down one slot).
do
  local label = power.subRegions[1]
  -- BOTH SPELLINGS. WeakAuras anchors on text_anchor*Offset (SubText.lua); the bare
  -- anchor*Offset is what its default() writes and nothing reads, with no Modernize bridge.
  label.anchorXOffset, label.anchorYOffset = LABEL_X, 0
  label.text_anchorXOffset, label.text_anchorYOffset = LABEL_X, 0
  label.text_fontSize = LABEL_SIZE
  local MARKS = {
    [2] = { v = EVISCERATE, w = 2 },   -- dim: where the line is
    [3] = { v = SINISTER,   w = 2 },
    [4] = { v = EVISCERATE, w = 4 },   -- lit: you can afford it right now
    [5] = { v = SINISTER,   w = 4 },
  }
  for index, mark in pairs(MARKS) do
    local sub = power.subRegions[index]
    sub.xOffset, sub.yOffset = markX(mark.v), 0
    sub.width, sub.height = mark.w, LANE.power.h
  end
  for i, x in ipairs(RULER) do
    power.subRegions[5 + i] = waterline(x, 1, LANE.power.h, { 1, 1, 1, 0.18 }, true)
  end
end

-- ===== lane 4: the combo pips move in ===================================================
for i = 1, 5 do
  for _, id in ipairs({ socket(i), pip(i) }) do
    local a = byId[id]
    a.parent = GROUP
    a.width, a.height = PIP_W, PIP_H
    a.xOffset, a.yOffset = PIP_X[i], PIP_Y
  end
end

-- ===== the alarm rim ====================================================================
-- 3px larger than the plate on every side, and FIRST in the draw order. Square_White_Border is
-- filled, so this region cannot trace an edge; what it can do is be bigger than the thing on
-- top of it. The 3px band is the alarm; the rest of the quad hides behind the plate.
do
  local alarm = byId[ALARM]
  alarm.texture = SQUARE_BRD
  alarm.width, alarm.height = LANE.alarm.w, LANE.alarm.h
  alarm.xOffset, alarm.yOffset = LANE.alarm.x, LANE.alarm.y
  -- The colour is already (1, 0.1, 0.1, 0.85) and is re-stated rather than assumed, because a
  -- progresstexture->texture repurpose that inherits an empty colour draws in WA's default.
  alarm.color = { 1, 0.1, 0.1, 0.85 }
end

-- ===== the combo row is gone, so Resources holds the sill and nothing else ==============
byId[RES_GROUP].controlledChildren = { GROUP }

-- ===== `c` is the wire order and must be depth-first in controlledChildren order ========
do
  local ordered = {}
  local seen = {}
  local function walk(node)
    for _, id in ipairs(node.controlledChildren or {}) do
      assert(not seen[id], "controlledChildren lists " .. id .. " twice")
      seen[id] = true
      local child = assert(byId[id], "unresolved child " .. id)
      ordered[#ordered + 1] = child
      walk(child)
    end
  end
  walk(T.d)
  assert(#ordered == #T.c,
    ("depth-first walk covers %d of %d children"):format(#ordered, #T.c))
  T.c = ordered
end

-- ===== encode and verify ================================================================
local encoded = W.encode(T)
W.verify(T, encoded)
local cont = W.uidContinuityStrings(encoded, src)
-- No allowance list. v54 removes nothing: every region in the strip is a v53 aura doing a new
-- job, so the strict default applies and every previous uid must still be here.
W.assertUidContinuity(cont, "rogue v54")
assert(cont.changed == 0, "rogue v54: an existing id changed uid")
assert(cont.missing == 0, "rogue v54: a uid disappeared, and v54 removes nothing")
assert(cont.parentSame, "rogue v54: the top-level uid changed")
assert(cont.oldCount == cont.newCount, "rogue v54: the aura count moved")
assert(cont.retained == cont.oldCount, "rogue v54: not every previous uid survived")

local NEW = W.decode(encoded)
local newById = { [NEW.d.id] = NEW.d }
for _, aura in ipairs(NEW.c) do newById[aura.id] = aura end

local function absolute(id)
  local x, y = 0, 0
  local node = assert(newById[id], "missing region " .. id)
  while node do
    x, y = x + (node.xOffset or 0), y + (node.yOffset or 0)
    node = node.parent and assert(newById[node.parent], "unresolved parent " .. node.parent)
  end
  return x, y
end

-- ===== AUDIT 1: the sill lands on (0,-110), walked through the real parent chain ========
do
  local gx, gy = absolute(GROUP)
  assert(gx == SILL_X and gy == SILL_Y,
    ("the sill resolves to (%s,%s), not (%d,%d)"):format(tostring(gx), tostring(gy), SILL_X, SILL_Y))
  local chain, node = {}, newById[GROUP]
  while node do
    -- The offsets only add up to a screen position if every node on the chain is anchored to
    -- the screen centre by its own centre. Asserted, not assumed.
    assert(node.anchorFrameType == "SCREEN", node.id .. " is not screen-anchored")
    assert(node.selfPoint == "CENTER" and node.anchorPoint == "CENTER",
      ("%s anchors %s to %s, so adding offsets does not give a centre")
        :format(node.id, tostring(node.selfPoint), tostring(node.anchorPoint)))
    chain[#chain + 1] = ("%s(%s,%s)"):format(node.id, tostring(node.xOffset), tostring(node.yOffset))
    node = node.parent and newById[node.parent] or nil
  end
  print("  chain: " .. table.concat(chain, " <- ") .. (" = (%d,%d)"):format(gx, gy))
end

-- ===== AUDIT 2: the rail canon, read back out of the ENCODED string =====================
local RAIL_CANON = {
  { id = THREAT, lane = LANE.threat, subs = 2 },
  { id = HEALTH, lane = LANE.health, subs = 4 },
  { id = POWER,  lane = LANE.power,  subs = 8 },
}
do
  for _, want in ipairs(RAIL_CANON) do
    local a = newById[want.id]
    assert(a.regionType == "progresstexture", want.id .. " is not a progresstexture")
    assert(a.orientation == "HORIZONTAL",
      want.id .. " does not fill left to right (orientation is " .. tostring(a.orientation) .. ")")
    assert(a.width == RAIL_LEN,
      ("%s is %s wide; one pixel is one percent only at %d"):format(want.id, tostring(a.width), RAIL_LEN))
    assert(a.height == want.lane.h, want.id .. " is not " .. want.lane.h .. " tall")
    assert(a.width ~= a.height, want.id .. " is square, so it is still a ring")
    assert(a.foregroundTexture == SQUARE and a.backgroundTexture == SQUARE,
      want.id .. " is not drawn on Square_White")
    assert(a.foregroundTexture ~= RING_TEX, want.id .. " is still on the ring art")
    assert(a.sameTexture == true and a.backgroundOffset == 0, want.id .. " lost its track")
    assert(a.xOffset == want.lane.x and a.yOffset == want.lane.y,
      ("%s sits at (%s,%s), not its lane (%s,%s)"):format(want.id, tostring(a.xOffset),
        tostring(a.yOffset), tostring(want.lane.x), tostring(want.lane.y)))
    assert(#a.subRegions == want.subs,
      ("%s has %d subregions, the rail canon says %d"):format(want.id, #a.subRegions, want.subs))
    assert(a.parent == GROUP, want.id .. " is not in the sill")
  end
  -- the lane stack: no two lanes overlap, and every lane is inside the plate
  local stack = {
    { id = THREAT, lane = LANE.threat }, { id = HEALTH, lane = LANE.health },
    { id = POWER, lane = LANE.power },
    { id = "combo lane", lane = { h = PIP_H, y = PIP_Y } },
  }
  for i = 1, #stack - 1 do
    local a, b = stack[i].lane, stack[i + 1].lane
    local gap = (a.y - a.h / 2) - (b.y + b.h / 2)
    assert(gap >= 1, ("%s and %s are %gpx apart"):format(stack[i].id, stack[i + 1].id, gap))
  end
  local top = LANE.threat.y + LANE.threat.h / 2
  local bottom = PIP_Y - PIP_H / 2
  assert(top <= LANE.plate.h / 2 - 1 and bottom >= -LANE.plate.h / 2 + 1,
    "the lane stack does not fit inside the plate with a 1px margin")
  print(("  lanes: content %+.1f .. %+.1f inside a %dx%d plate"):format(top, bottom, PLATE_W, PLATE_H))
end

-- ===== AUDIT 3: the breakpoints, recomputed from the formula ============================
do
  local p = newById[POWER]
  local EXPECT = {
    [2] = { x = markX(EVISCERATE), w = 2, alpha = 0.55 },
    [3] = { x = markX(SINISTER),   w = 2, alpha = 0.55 },
    [4] = { x = markX(EVISCERATE), w = 4, alpha = 1 },
    [5] = { x = markX(SINISTER),   w = 4, alpha = 1 },
  }
  for index, want in pairs(EXPECT) do
    local sub = p.subRegions[index]
    assert(sub.type == "subtexture", ("power sub.%d is not a subtexture"):format(index))
    assert(sub.xOffset == want.x and sub.yOffset == 0,
      ("power sub.%d is at (%s,%s), the formula says (%g,0)")
        :format(index, tostring(sub.xOffset), tostring(sub.yOffset), want.x))
    assert(sub.width == want.w and sub.height == LANE.power.h,
      ("power sub.%d is %sx%s, expected %dx%d")
        :format(index, tostring(sub.width), tostring(sub.height), want.w, LANE.power.h))
    assert(sub.textureColor[4] == want.alpha,
      ("power sub.%d changed alpha; the dim/lit pairing is part of the reading rule"):format(index))
  end
  -- the two shipped conditions still address sub.4 and sub.5, and nothing else moved into them
  local drives = {}
  for ci, cond in ipairs(p.conditions or {}) do
    for gi, change in ipairs(cond.changes) do
      local n = tostring(change.property):match("^sub%.(%d+)%.")
      if n then drives[change.property] = { value = cond.check.value, var = cond.check.variable,
                                            ci = ci, gi = gi } end
    end
  end
  local d35 = assert(drives["sub.4.textureVisible"], "nothing drives sub.4 any more")
  local d40 = assert(drives["sub.5.textureVisible"], "nothing drives sub.5 any more")
  assert(d35.var == "power" and d35.value == tostring(EVISCERATE),
    "sub.4 is no longer the 35-energy mark")
  assert(d40.var == "power" and d40.value == tostring(SINISTER),
    "sub.5 is no longer the 40-energy mark")
  assert(p.subRegions[4].textureVisible == false and p.subRegions[5].textureVisible == false,
    "the lit marks start visible, so they say nothing")
  print(("  breakpoints: %d -> x%+g, %d -> x%+g  (x = v - %d)")
    :format(EVISCERATE, markX(EVISCERATE), SINISTER, markX(SINISTER), MAXPOWER / 2))
  -- the threat notch
  local notch = newById[THREAT].subRegions[2]
  assert(notch.xOffset == markX(NOTCH_THREAT) and notch.height == LANE.threat.h,
    "the 70 notch is not a full-height waterline at x = 20")
  assert(newById[THREAT].subRegions[1].text_visible == false,
    "the threat percentage is still printed on open screen")
  -- the rulers
  for _, pair in ipairs({ { HEALTH, 1 }, { POWER, 5 } }) do
    for i, x in ipairs(RULER) do
      local sub = newById[pair[1]].subRegions[pair[2] + i]
      assert(sub.width == 1 and sub.xOffset == x and sub.textureColor[4] == 0.18,
        ("%s ruler tick %d is wrong"):format(pair[1], i))
    end
  end
end

-- ===== AUDIT 4: numbers print inside their own rail =====================================
do
  for _, id in ipairs({ HEALTH, POWER }) do
    local label = newById[id].subRegions[1]
    assert(label.type == "subtext", id .. " lost its number")
    assert(label.text_anchorXOffset == LABEL_X and label.text_anchorYOffset == 0
      and label.anchorXOffset == LABEL_X and label.anchorYOffset == 0,
      id .. ": the number is not at the rail's right-hand end")
    assert(label.text_fontSize == LABEL_SIZE, id .. ": the number is not " .. LABEL_SIZE .. "pt")
    assert(label.text_anchorPoint == "CENTER", id .. ": the number is not centre-anchored")
    assert(label.text_fontType == "OUTLINE", id .. ": the number lost its outline")
  end
  assert(newById[POWER].subRegions[1].text_text == "%p",
    "the energy number stopped being raw; 35 and 40 are absolute costs")
  assert(newById[HEALTH].subRegions[1].text_text == "%percenthealth%%", "the health token changed")
  -- widest string, generous advance: "100%" at 11pt is at most 4 * 0.60 * 11 = 26.4px wide,
  -- centred on x = +32, so it spans +18.8 .. +45.2 and stays inside the rail's +50 edge.
  local ADVANCE, WIDEST = 0.60, 4
  local half = WIDEST * ADVANCE * LABEL_SIZE / 2
  assert(LABEL_X + half < RAIL_LEN / 2,
    ("a %dpt %d-glyph number reaches x=%.1f and leaves the %dpx rail")
      :format(LABEL_SIZE, WIDEST, LABEL_X + half, RAIL_LEN))
  assert(LABEL_SIZE <= LANE.health.h, "the number is taller than the rail it prints in")
  print(("  numbers: %dpt at x=+%d, widest %.1fpx -> x %+.1f .. %+.1f inside a %dpx rail")
    :format(LABEL_SIZE, LABEL_X, half * 2, LABEL_X - half, LABEL_X + half, RAIL_LEN))
end

-- ===== AUDIT 5: draw order, and `c` depth-first across the WHOLE pack ===================
do
  local cc = newById[GROUP].controlledChildren
  assert(iseq(cc, SILL_ORDER), "the sill's child order is not alarm / plate / rails / pips")
  assert(cc[1] == ALARM,
    "the alarm rim is not first; a filled ADD quad anywhere else washes what is under it")
  assert(cc[2] == PLATE, "the plate is not second, so it draws over the rails")
  assert(cc[#cc] == pip(5), "the top of the stack is not a readout")
  for _, id in ipairs({ THREAT, HEALTH, POWER }) do
    assert(indexOf(cc, id) > indexOf(cc, PLATE), id .. " draws under the plate")
    assert(indexOf(cc, id) > indexOf(cc, ALARM), id .. " draws under the alarm rim")
  end
  -- the load-bearing claim: NOTHING in the sill is composited over a readout
  for i = 2, #cc do
    assert(cc[i] ~= ALARM, "the alarm rim appears twice in the draw order")
  end
  for i = 1, 5 do
    assert(indexOf(cc, socket(i)) < indexOf(cc, pip(i)), ("pip %d draws under its socket"):format(i))
    assert(indexOf(cc, socket(i)) > indexOf(cc, POWER), ("pip %d draws under the power rail"):format(i))
  end
  assert(#cc == 15, ("the sill holds %d children, expected 15"):format(#cc))

  local expected, seen = {}, {}
  local function walk(node)
    for _, id in ipairs(node.controlledChildren or {}) do
      assert(not seen[id], "controlledChildren lists " .. id .. " twice")
      seen[id] = true
      expected[#expected + 1] = id
      walk(assert(newById[id], "unresolved child " .. id))
    end
  end
  walk(NEW.d)
  assert(#expected == #NEW.c,
    ("depth-first walk covers %d of %d children"):format(#expected, #NEW.c))
  for i, id in ipairs(expected) do
    assert(NEW.c[i].id == id,
      ("c is not depth-first at %d: %s, expected %s"):format(i, NEW.c[i].id, id))
  end
  assert(iseq(newById[RES_GROUP].controlledChildren, { GROUP }),
    "Rogue - Resources still lists the old combo row")
end

-- ===== AUDIT 6: the plate and the alarm rim =============================================
do
  local plate, alarm = newById[PLATE], newById[ALARM]
  for _, a in ipairs({ plate, alarm }) do
    assert(a.regionType == "texture", a.id .. " is not a texture")
    assert(a.texture == SQUARE_BRD, a.id .. " is not on Square_White_Border")
    assert(a.texture ~= RING_TEX, a.id .. " is still ring art")
    assert(a.xOffset == 0 and a.yOffset == 0, a.id .. " is not concentric with the strip")
  end
  assert(plate.width == PLATE_W and plate.height == PLATE_H,
    ("%s is %sx%s, not %dx%d"):format(PLATE, tostring(plate.width), tostring(plate.height),
      PLATE_W, PLATE_H))
  -- The alarm is the same FILLED art as the plate, so the only way it can read as an edge is by
  -- being bigger than the plate and drawn under it. Both halves of that are asserted here.
  assert(alarm.width == plate.width + 2 * RIM and alarm.height == plate.height + 2 * RIM,
    ("the alarm is %sx%s; a %dpx rim around a %dx%d plate is %dx%d")
      :format(tostring(alarm.width), tostring(alarm.height), RIM, PLATE_W, PLATE_H,
        ALARM_W, ALARM_H))
  assert(indexOf(newById[GROUP].controlledChildren, ALARM) == 1,
    "the alarm is not the bottom of the stack, so it washes the readouts instead of ringing them")
  -- the plate must have exactly the field set this pack's other textures have
  assert(iseq(keyset(plate), keyset(alarm)),
    "the plate's field set does not match a shipped texture region:\n    plate = "
      .. table.concat(keyset(plate), ",") .. "\n    alarm = " .. table.concat(keyset(alarm), ","))
  assert(plate.model_path == nil and plate.portraitZoom == nil, "the plate kept model fields")
  assert(iseq(plate.color, PLATE_COLOR), "the plate is not a dark ground")
  assert(plate.blendMode == "BLEND", "the plate is additive and would glow")
  assert(type(alarm.color) == "table" and #alarm.color == 4 and alarm.color[1] == 1
    and alarm.color[2] == 0.1 and alarm.color[3] == 0.1 and alarm.color[4] == 0.85,
    "the alarm frame has no explicit red and would draw in WeakAuras' default")
  assert(alarm.blendMode == "ADD", "the alarm frame stopped being additive")
  assert(alarm.animation.main.preset == "alphaPulse" and alarm.animation.main.duration == "1",
    "the alarm frame lost its pulse")
  assert(alarm.triggers[1].trigger.threatpct == "80"
    and alarm.triggers[1].trigger.threatpct_operator == ">=",
    "the alarm frame is no longer the 80% warning")
end

-- ===== AUDIT 7: the pips, and how far the pop reaches ====================================
-- The pop scale is read out of the string rather than assumed, because the envelope the next
-- audit scans has to contain the widest thing the strip ever draws, not the resting geometry.
local POP = {}
do
  for i = 1, 5 do
    for _, id in ipairs({ socket(i), pip(i) }) do
      local a = newById[id]
      assert(a.parent == GROUP, id .. " is not in the sill")
      assert(a.width == PIP_W and a.height == PIP_H,
        ("%s is %sx%s, not %dx%d"):format(id, tostring(a.width), tostring(a.height), PIP_W, PIP_H))
      assert(a.xOffset == PIP_X[i] and a.yOffset == PIP_Y,
        ("%s is at (%s,%s), not (%d,%g)"):format(id, tostring(a.xOffset), tostring(a.yOffset),
          PIP_X[i], PIP_Y))
      assert(a.texture == SQUARE_BRD, id .. " changed art")
    end
    local lit = newById[pip(i)]
    assert(lit.blendMode == "ADD", pip(i) .. " stopped being additive")
    assert(lit.animation.start.type == "custom" and lit.animation.start.duration == "0.3"
      and lit.animation.start.scalex == 1.85, pip(i) .. " lost its pop")
    assert(lit.triggers[1].trigger.powertype == 4
      and lit.triggers[1].trigger.power == tostring(i), pip(i) .. " no longer watches " .. i)
  end
  -- the row fits inside the rail's own 100px content width
  local left  = PIP_X[1] - PIP_W / 2
  local right = PIP_X[5] + PIP_W / 2
  assert(left >= -RAIL_LEN / 2 and right <= RAIL_LEN / 2,
    ("the pip row spans %g..%g and leaves the %dpx content width"):format(left, right, RAIL_LEN))
  -- At the peak of the 0.3s pop a pip is scalex/scaley times its resting size about its own
  -- centre, so it transiently leaves the plate. That is not a collision, but the claim "1px
  -- margin all round" is only true at rest, and the scan below has to cover the excursion.
  local sx = newById[pip(1)].animation.start.scalex
  local sy = newById[pip(1)].animation.start.scaley
  for i = 2, 5 do
    assert(newById[pip(i)].animation.start.scalex == sx
      and newById[pip(i)].animation.start.scaley == sy, "the pips no longer pop identically")
  end
  POP.x = math.max(math.abs(PIP_X[1]), math.abs(PIP_X[5])) + PIP_W * sx / 2
  POP.y1 = SILL_Y + PIP_Y - PIP_H * sy / 2
  POP.y2 = SILL_Y + PIP_Y + PIP_H * sy / 2
  print(("  pips: 5 sockets + 5 lit, %dx%d at x %g..%g, %gpx of clear air under the power rail; "
    .. "the %.2fx pop reaches x +-%.2f, y %.2f..%.2f (%.2fpx past the plate edge)")
    :format(PIP_W, PIP_H, PIP_X[1], PIP_X[5],
      (LANE.power.y - LANE.power.h / 2) - (PIP_Y + PIP_H / 2), sx, POP.x, POP.y1, POP.y2,
      (SILL_Y - PLATE_H / 2) - POP.y1))
end

-- ===== AUDIT 8: the rectangle scan, dynamic groups projected six deep ====================
-- The scanned box is the ENVELOPE, not the plate: the widest of the plate, the 3px alarm rim
-- and the pip pop, so nothing the strip ever draws is outside what was proved clear.
--
-- The box arithmetic below reads (x,y) as a region's CENTRE, which is only true for
-- selfPoint == anchorPoint == "CENTER"; for a dynamic group it reads the anchor as the edge the
-- group grows away from. Both assumptions are now asserted per region instead of assumed, so a
-- future aura anchored by an edge cannot be silently mis-boxed by this scan.
local GROW_SELF = { UP = "BOTTOM", DOWN = "TOP", RIGHT = "LEFT", LEFT = "RIGHT",
                    HORIZONTAL = "CENTER", VERTICAL = "CENTER", CIRCLE = "CENTER" }
do
  local DEPTH = 6
  local sx1 = math.min(SILL_X - ALARM_W / 2, -POP.x)
  local sx2 = math.max(SILL_X + ALARM_W / 2,  POP.x)
  local sy1 = math.min(SILL_Y - ALARM_H / 2, POP.y1)
  local sy2 = math.max(SILL_Y + ALARM_H / 2, POP.y2)
  local inSill = { [GROUP] = true }
  for _, id in ipairs(SILL_ORDER) do inSill[id] = true end

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
          widest  = math.max(widest,  newById[cid].width  or 0)
          tallest = math.max(tallest, newById[cid].height or 0)
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
  assert(scanned > 0, "the rectangle scan examined nothing")
  assert(#hits == 0, ("the envelope at (%d,%d) overlaps %d element(s): %s")
    :format(SILL_X, SILL_Y, #hits, table.concat(hits, "; ")))
  print(("  scan: envelope x %g..%g y %g..%g (plate %dx%d, alarm %dx%d, pop x+-%.2f), "
    .. "%d elements, 0 overlaps, closest %.2fpx (%s)")
    :format(sx1, sx2, sy1, sy2, PLATE_W, PLATE_H, ALARM_W, ALARM_H, POP.x,
      scanned, closest, tostring(closestId)))
end

-- ===== AUDIT 9: everything the design calls unchanged IS unchanged =======================
-- Diffed field by field against v53, by uid, with an explicit per-region licence. Anything not
-- named here must be byte-identical, including every trigger, load gate, condition and colour.
do
  local ALLOWED = {
    [GROUP]  = { id = true, xOffset = true, yOffset = true, controlledChildren = true },
    [PLATE]  = { id = true, parent = true, regionType = true, width = true, height = true,
                 xOffset = true, yOffset = true,
                 texture = true, textureWrapMode = true, color = true, blendMode = true,
                 desaturate = true, discrete_rotation = true, mirror = true, rotate = true,
                 advance = true, api = true, backdropColor = true, border = true,
                 borderBackdrop = true, borderColor = true, borderEdge = true, borderInset = true,
                 borderOffset = true, borderSize = true, modelDisplayInfo = true,
                 modelIsUnit = true, model_fileId = true, model_path = true, model_st_rx = true,
                 model_st_ry = true, model_st_rz = true, model_st_tx = true, model_st_ty = true,
                 model_st_tz = true, model_st_us = true, model_x = true, model_y = true,
                 model_z = true, portraitZoom = true, sequence = true, subRegions = true },
    [THREAT] = { id = true, parent = true, orientation = true, foregroundTexture = true,
                 backgroundTexture = true, width = true, height = true, xOffset = true,
                 yOffset = true, subRegions = true },
    [ALARM]  = { id = true, parent = true, texture = true, width = true, height = true },
    [RES_GROUP] = { controlledChildren = true },
  }
  ALLOWED[HEALTH] = ALLOWED[THREAT]
  ALLOWED[POWER]  = ALLOWED[THREAT]
  for i = 1, 5 do
    local moved = { parent = true, width = true, height = true, xOffset = true, yOffset = true }
    ALLOWED[socket(i)], ALLOWED[pip(i)] = moved, moved
  end

  local backwards = {}
  for oldId, newId in pairs(RENAME) do backwards[newId] = oldId end

  assert(iseq(OLD.d, NEW.d), "the top-level group changed")
  assert(#OLD.c == #NEW.c, "the aura count changed")
  for _, new in ipairs(NEW.c) do
    local old = oldById[backwards[new.id] or new.id]
    assert(old, new.id .. " has no v53 counterpart")
    assert(old.uid == new.uid, new.id .. ": the uid moved")
    local licence = ALLOWED[new.id] or {}
    for key, value in pairs(old) do
      if not licence[key] then
        assert(iseq(value, new[key]),
          ("%s: %s changed, and v54 does not licence that field"):format(new.id, key))
      end
    end
    for key in pairs(new) do
      assert(old[key] ~= nil or licence[key], new.id .. ": gained unlicensed field " .. key)
    end
  end

  -- Named explicitly, because these are the things the design promised not to touch.
  local UNCHANGED = {
    { THREAT, "triggers" }, { THREAT, "load" }, { THREAT, "conditions" },
    { THREAT, "foregroundColor" }, { THREAT, "backgroundColor" },
    { HEALTH, "triggers" }, { HEALTH, "load" }, { HEALTH, "conditions" },
    { HEALTH, "foregroundColor" }, { HEALTH, "backgroundColor" },
    { POWER,  "triggers" }, { POWER,  "load" }, { POWER,  "conditions" },
    { POWER,  "foregroundColor" }, { POWER,  "backgroundColor" },
    { ALARM,  "triggers" }, { ALARM,  "load" }, { ALARM,  "animation" }, { ALARM, "color" },
    { ALARM,  "blendMode" },
    { PLATE,  "triggers" }, { PLATE,  "load" }, { PLATE,  "conditions" },
  }
  for i = 1, 5 do
    for _, id in ipairs({ socket(i), pip(i) }) do
      UNCHANGED[#UNCHANGED + 1] = { id, "triggers" }
      UNCHANGED[#UNCHANGED + 1] = { id, "conditions" }
      UNCHANGED[#UNCHANGED + 1] = { id, "color" }
      UNCHANGED[#UNCHANGED + 1] = { id, "animation" }
      UNCHANGED[#UNCHANGED + 1] = { id, "load" }
    end
  end
  for _, entry in ipairs(UNCHANGED) do
    local old = oldById[backwards[entry[1]] or entry[1]]
    assert(iseq(old[entry[2]], newById[entry[1]][entry[2]]),
      ("%s.%s is not byte-identical to v53"):format(entry[1], entry[2]))
  end

  -- Subregion-level: every key of every surviving subregion except the ones this patch moves.
  local SUB_LICENCE = {
    [THREAT] = { [1] = { text_visible = true } },
    -- v54.1: text_anchor*Offset joins the licence. It is the key WeakAuras actually anchors
    -- on (SubText.lua); the bare anchor*Offset this patch already moved is written by WA's
    -- own default() and read by nothing, with no Modernize step bridging them — so the
    -- number had been rendering dead on its anchor point the whole time.
    [HEALTH] = { [1] = { anchorXOffset = true, anchorYOffset = true, text_fontSize = true,
                         text_anchorXOffset = true, text_anchorYOffset = true } },
    [POWER]  = { [1] = { anchorXOffset = true, anchorYOffset = true, text_fontSize = true,
                         text_anchorXOffset = true, text_anchorYOffset = true },
                 [2] = { xOffset = true, yOffset = true, width = true, height = true },
                 [3] = { xOffset = true, yOffset = true, width = true, height = true },
                 [4] = { xOffset = true, yOffset = true, width = true, height = true },
                 [5] = { xOffset = true, yOffset = true, width = true, height = true } },
  }
  for id, perIndex in pairs(SUB_LICENCE) do
    local was = oldById[backwards[id]].subRegions
    local now = newById[id].subRegions
    for index, licence in pairs(perIndex) do
      for key, value in pairs(was[index]) do
        if not licence[key] then
          assert(iseq(value, now[index][key]),
            ("%s sub.%d: %s changed"):format(id, index, key))
        end
      end
      for key in pairs(now[index]) do
        assert(was[index][key] ~= nil, ("%s sub.%d: gained %s"):format(id, index, key))
      end
    end
  end
  print("  diff: every unlicensed field, on all 58 auras, is byte-identical to v53")
end

local out = assert(io.open(PACK, "w")); out:write(encoded); out:close()
print(("sill order: %s"):format(table.concat(newById[GROUP].controlledChildren, " -> ")))
print(("uid continuity: stable=%d changed=%d retained=%d missing=%d parentSame=%s")
  :format(cont.stable, cont.changed, cont.retained, cont.missing, tostring(cont.parentSame)))
print(("wrote %s (%d auras, %d chars)"):format(PACK, #T.c + 1, #encoded))
