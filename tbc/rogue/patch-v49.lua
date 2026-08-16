-- rogue v48 -> v49: the two ring orbs become three Diablo-style globes.
--
-- WHY. v47/v48 drew each unit as a live portrait ringed by concentric progresstexture arcs.
-- An arc encodes a value as *sweep*, which reads badly at speed: a 3% change is a couple of
-- degrees, and the portrait in the middle meant the numbers had to be parked outside the
-- rings where they compete with the world. A Diablo globe is the opposite idea — the shape
-- is a VESSEL and the *waterline* encodes the value — and because a progresstexture accepts
-- a subtext (SubText.lua's supports() lists "texture" and "progresstexture"; a `model`
-- region is not in that list) the number can finally sit inside the glass. That is what
-- dropping the portrait buys, and it is the whole reason the portrait goes.
--
-- THE ONE FIELD THAT MAKES A GLOBE A GLOBE:
--     orientation = "VERTICAL"     -- Private.orientation_with_circle_types: "Bottom to Top"
-- VERTICAL fills UP; VERTICAL_INVERSE fills DOWN and would drain the globe from the top as
-- you take damage, which looks deliberate and is wrong. Switching off the circular path also
-- swaps which fields are live: compress / slanted / slantMode now matter (slant stays 0 — a
-- straight waterline is what reads as liquid), and startAngle / endAngle stop mattering.
-- crop_x / crop_y stay at the 0.41 default: TextureCoords.TransformPoint scales the coords
-- by 1.4142 and then divides by (1 + crop), so 0.41 is a ~1:1 draw and the disc's radius is
-- half the region box — which is what the breakpoint chord arithmetic below assumes.
--
-- THE CANONICAL GEOMETRY IS SHARED WITH ALL SEVEN PACKS and is declared as named constants
-- at the top of this file so it cannot drift the way the v47 per-pack diameters did.
--
-- GLOBE_Y IS AN ABSOLUTE SCREEN OFFSET, NOT A LOCAL ONE. This cluster hangs under
-- `Rogue - Resources`, which hangs under the pack's top group, and both carry offsets of
-- their own. The two globe groups are therefore positioned by SUBTRACTING the inherited
-- chain rather than by writing -150 into a child, and the finished string is decoded at the
-- bottom and the chain walked to prove the three globes land at exactly
-- (-300, -150), (0, -150) and (+300, -150).
--
-- RESOURCE BREAKPOINTS GET EASIER, NOT HARDER. On a ring the 35/40 energy marks needed
-- trigonometry (v48's TICK_RADIUS and atan2 recovery). On a vessel a threshold is a
-- horizontal line at a fixed height:
--     yOffset = (threshold/max - 0.5) * GLOBE_MAIN
-- and the only other number a line needs is how far it reaches, which is the globe's chord
-- at that height: width = 2 * sqrt(r^2 - yOffset^2), r = GLOBE_MAIN/2. Both are recomputed
-- here and both are recovered back out of the committed string at the bottom, so the proof
-- does not lean on the same arithmetic that produced them. The dim + lit pair and their
-- colours (red = Eviscerate at 35, purple = Sinister Strike at 40) are carried across
-- untouched, and the pair keeps its subRegions INDEX so the `sub.4` / `sub.5` condition
-- references keep pointing at the lit marks.
--
-- THREAT HAS NO VESSEL, so it becomes the TARGET GLOBE'S RIM COLOUR: green base, orange at
-- threatpct >= 70, red on aggro, most severe last, with the percentage above the glass. It
-- costs no extra element and no extra screen space. Two details are load-bearing:
--   * the rim is a `texture` region, so its colour property is `color` (Texture.lua's
--     properties table). `foregroundColor` is a progresstexture property and would be a
--     SILENT no-op here — Conditions.lua skips unknown properties without warning, the same
--     trap as barColor on a progresstexture.
--   * the `threatvalue <= 0 -> alpha 0` guard is kept. Without it the rim reads as full
--     aggro at zero threat.
-- The group/raid load gate is carried across unchanged, and so is the >= 80% pulsing halo.
--
-- UID DISCIPLINE. Eight regions are replaced by eight regions and every uid is recycled onto
-- the thing that took its place, so the import is a clean Update with no orphans left in the
-- user's WeakAuras. No `uid()` is called: this patch consumes nothing from the random stream
-- and appends no new aura.
--     Rogue - Health          -> Rogue - Life Globe          (progresstexture, unchanged type)
--     Rogue - Energy          -> Rogue - Energy Globe        (progresstexture, unchanged type)
--     Rogue - Player Portrait -> Rogue - Life Globe Rim      (model    -> texture)
--     Rogue - Target Power    -> Rogue - Energy Globe Rim    (progresstexture -> texture)
--     Rogue - Target Health   -> Rogue - Target Life Globe   (progresstexture, unchanged type)
--     Rogue - Target Portrait -> Rogue - Target Globe Rim    (model    -> texture)
--     Rogue - Threat          -> Rogue - Threat Rim          (progresstexture -> texture)
--     Rogue - Threat Flash    -> Rogue - Threat Flash        (texture, resized onto the rim)
-- The two cluster groups keep their uids too and are renamed to what they now hold.
--
-- WHAT THIS PATCH MAY NOT TOUCH: anything outside the orb cluster. The combo pips, buffs,
-- alerts, cooldown row, procs and the whole PvP layer are asserted byte-identical to v48 at
-- the bottom, field by field, and so is `Rogue - Resources` apart from the two renamed
-- entries in its controlledChildren.
--
-- Run: lua5.1 tbc/rogue/patch-v49.lua   (rewrites all-specs.txt in place)

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local SCRIPTS = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local PACK = dir .. "/all-specs.txt"
local savedArg = arg
arg = { [0] = SCRIPTS .. "/wa_lib.lua" }
local W = dofile(SCRIPTS .. "/wa_lib.lua")
arg = savedArg

-- ===== canonical globe geometry, shared verbatim by every pack =========================
local MEDIA      = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\"
local FILL_TEX   = MEDIA .. "Circle_Smooth.tga"          -- the liquid: a filled disc
local RIM_TEX    = MEDIA .. "Circle_Smooth_Border.tga"   -- the glass rim drawn on the band
local GLOBE_MAIN = 72     -- life and power globes
local GLOBE_TGT  = 44      -- target globe
local RIM_PAD    = 4       -- a rim is its globe's size + 6 ...
local RIM_STRATA = 2       -- ... drawn at frameStrata 2
local GLOBE_X    = 150     -- life at -300, power at +300, target at 0
local GLOBE_Y      = -262    -- ABSOLUTE screen y for all three
local ORIENT     = "VERTICAL"                        -- "Bottom to Top"
local COL_EMPTY  = { 0.05, 0.05, 0.07, 0.85 }        -- the empty vessel, near-black
local COL_LIFE   = { 0.72, 0.09, 0.09, 1 }
local COL_ENERGY = { 0.85, 0.75, 0.15, 1 }           -- a rogue's power IS energy: yellow
local COL_RIM    = { 0.62, 0.55, 0.40, 1 }
local PCT_MAIN   = { size = 18, y = 0 }   -- inside the glass
local PCT_TGT    = { size = 13, y = 0 }   -- inside the glass
local PCT_THREAT = { size = 11, y = 52 }  -- above the target globe

-- The 35/40 energy breakpoints. `sub` is the dim mark's subRegions index and `lit` the
-- bright one's; both indexes are FIXED by the conditions that reference sub.4 / sub.5.
local MARK_DIM_H, MARK_LIT_H = 3, 5
local BREAKPOINTS = {
  { threshold = 35, f = 0.35, dim = 2, lit = 4 },
  { threshold = 40, f = 0.40, dim = 3, lit = 5 },
}

-- ===== helpers =========================================================================
local function iseq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not iseq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

local function round(v) return math.floor(v * 1000 + 0.5) / 1000 end

-- A threshold is a horizontal line at a fixed height, and it reaches as far as the globe
-- does at that height. Nothing here is a tuned constant.
local function markY(f) return round((f - 0.5) * GLOBE_MAIN) end
local function markW(f)
  local r = GLOBE_MAIN / 2
  local dy = (f - 0.5) * GLOBE_MAIN
  return round(2 * math.sqrt(r * r - dy * dy))
end

local function noAnimation()
  return {
    start  = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
    main   = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
    finish = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
  }
end

-- ===== read the v48 build ==============================================================
local f = assert(io.open(PACK, "r")); local src = f:read("*a"); f:close()
local T = W.decode(src)
local OLD = W.decode(src)

local byId, oldById = {}, {}
for _, aura in ipairs(T.c) do byId[aura.id] = aura end
for _, aura in ipairs(OLD.c) do oldById[aura.id] = aura end

-- ===== the exact v48 state this patch expects ==========================================
local RING_20 = MEDIA .. "Ring_20px.tga"
local BEFORE = {
  ["Rogue - Player Orb"]      = { kind = "group",           x = -260, y = -60 },
  ["Rogue - Target Orb"]      = { kind = "group",           x =  260, y = -60 },
  ["Rogue - Health"]          = { kind = "progresstexture", size = 104, tex = RING_20 },
  ["Rogue - Energy"]          = { kind = "progresstexture", size =  78, tex = RING_20 },
  ["Rogue - Player Portrait"] = { kind = "model",           size =  46 },
  ["Rogue - Threat Flash"]    = { kind = "texture",         size = 104, tex = RING_20 },
  ["Rogue - Threat"]          = { kind = "progresstexture", size = 104, tex = RING_20 },
  ["Rogue - Target Health"]   = { kind = "progresstexture", size =  78, tex = RING_20 },
  ["Rogue - Target Power"]    = { kind = "progresstexture", size =  54, tex = RING_20 },
  ["Rogue - Target Portrait"] = { kind = "model",           size =  46 },
}

for id, want in pairs(BEFORE) do
  local aura = assert(byId[id], "v48 orb region missing: " .. id)
  assert(aura.regionType == want.kind,
    ("%s: expected a v48 %s, found %s"):format(id, want.kind, tostring(aura.regionType)))
  if want.size then
    assert(aura.width == want.size and aura.height == want.size,
      ("%s: expected v48 size %d, found %sx%s"):format(id, want.size,
        tostring(aura.width), tostring(aura.height)))
  end
  if want.tex then
    local tex = aura.foregroundTexture or aura.texture
    assert(tex == want.tex, id .. ": unexpected v48 texture " .. tostring(tex))
  end
  if want.x then
    assert(aura.xOffset == want.x and aura.yOffset == want.y,
      ("%s: expected v48 offset (%d,%d), found (%s,%s)"):format(id, want.x, want.y,
        tostring(aura.xOffset), tostring(aura.yOffset)))
  end
  if want.kind == "progresstexture" then
    assert(aura.orientation == "CLOCKWISE", id .. ": v48 ring is not CLOCKWISE")
  end
end

do  -- the energy ring really carries the percentage plus the four 35/40 marks, in order
  local en = byId["Rogue - Energy"]
  assert(#en.subRegions == 5, "v48 energy ring does not carry 5 subregions")
  assert(en.subRegions[1].type == "subtext", "v48 energy subRegions[1] is not the percentage")
  for i = 2, 5 do
    assert(en.subRegions[i].type == "subtexture", "v48 energy subRegions " .. i .. " is not a mark")
  end
  local marks = 0
  for _, cond in ipairs(en.conditions) do
    for _, change in ipairs(cond.changes) do
      if change.property == "sub.4.textureVisible" or change.property == "sub.5.textureVisible" then
        marks = marks + 1
      end
    end
  end
  assert(marks == 2, "v48 energy conditions do not light subRegions 4 and 5")
end

do  -- the threat conditions this patch has to re-home onto a texture region
  local th = byId["Rogue - Threat"]
  assert(#th.conditions == 3, "v48 threat does not carry 3 conditions")
  assert(th.conditions[1].check.variable == "threatpct" and th.conditions[1].check.value == "70",
    "v48 threat condition 1 is not the 70% escalation")
  assert(th.conditions[2].check.variable == "aggro", "v48 threat condition 2 is not aggro")
  assert(th.conditions[3].check.variable == "threatvalue" and th.conditions[3].check.op == "<=",
    "v48 threat condition 3 is not the zero-threat guard")
  assert(th.load.use_ingroup and th.load.ingroup.multi.group and th.load.ingroup.multi.raid,
    "v48 threat has lost its group/raid load gate")
end

-- A complete, WA-valid `texture` region straight out of the shipped pack, used as the
-- schema template for the four rims. Captured BEFORE anything is edited.
local TEXTURE_PROTO = W.deepcopy(byId["Rogue - Threat Flash"])

-- ===== position the two globe groups ===================================================
-- GLOBE_Y is absolute, so the inherited chain is subtracted rather than assumed. Both groups
-- sit on the screen centreline at the globe band; each globe states its own +-300 itself.
local RES = assert(byId["Rogue - Resources"], "the Resources group is missing")
local GROUP_X = 0 - (T.d.xOffset + RES.xOffset)
local GROUP_Y = GLOBE_Y - (T.d.yOffset + RES.yOffset)

local PLAYER_GROUP = "Rogue - Player Globes"
local TARGET_GROUP = "Rogue - Target Globe"

-- ===== rebuild the regions =============================================================
-- Each new region KEEPS the uid of the region it replaces, and keeps its trigger set, load
-- gate and conditions unless this file says otherwise.
local function rename(oldId, newId)
  local aura = assert(byId[oldId], "missing " .. oldId)
  byId[oldId] = nil
  aura.id = newId
  byId[newId] = aura
  return aura
end

-- Turn a surviving progresstexture ring into a globe.
local function makeGlobe(aura, opts)
  aura.width, aura.height = opts.size, opts.size
  aura.foregroundTexture, aura.backgroundTexture, aura.sameTexture = FILL_TEX, FILL_TEX, true
  aura.foregroundColor = W.deepcopy(opts.color)
  aura.backgroundColor = W.deepcopy(COL_EMPTY)
  aura.backgroundOffset = 0
  aura.orientation = ORIENT
  aura.compress, aura.slanted, aura.slant = false, false, 0
  aura.slantFirst, aura.slantMode = false, "INSIDE"
  aura.crop_x, aura.crop_y = 0.41, 0.41
  aura.auraRotation, aura.rotation = 0, 0
  aura.inverse, aura.mirror = false, false
  aura.blendMode, aura.textureWrapMode = "BLEND", "CLAMPTOBLACKADDITIVE"
  aura.desaturateForeground, aura.desaturateBackground = false, false
  aura.startAngle, aura.endAngle = 0, 360   -- inert on the linear path, kept for the schema
  aura.smoothProgress, aura.overlayclip = true, false
  aura.parent = opts.parent
  aura.xOffset, aura.yOffset = opts.x, 0
  aura.frameStrata, aura.alpha = 1, 1
  -- the number moves INSIDE the glass; everything else about the text is untouched
  local text = aura.subRegions[1]
  assert(text and text.type == "subtext", aura.id .. ": subRegions[1] is not the percentage")
  text.text_fontSize = opts.pct.size
  text.text_anchorPoint = "CENTER"
  text.anchorXOffset, text.anchorYOffset = 0, opts.pct.y
  return aura
end

-- Build a rim from the shipped texture schema, recycling `donor`'s uid.
local function makeRim(donor, opts)
  local rim = W.deepcopy(TEXTURE_PROTO)
  rim.id, rim.uid = opts.id, donor.uid
  rim.parent = opts.parent
  rim.width, rim.height = opts.size, opts.size
  rim.texture = RIM_TEX
  rim.color = W.deepcopy(opts.color)
  rim.blendMode = opts.blendMode or "BLEND"
  rim.textureWrapMode = "CLAMPTOBLACKADDITIVE"
  rim.desaturate, rim.mirror, rim.rotate = false, false, false
  rim.rotation, rim.discrete_rotation = 0, 0
  rim.selfPoint, rim.anchorPoint, rim.anchorFrameType = "CENTER", "CENTER", "SCREEN"
  rim.xOffset, rim.yOffset = opts.x, 0
  rim.frameStrata, rim.alpha = RIM_STRATA, 1
  rim.animation = opts.animation or noAnimation()
  rim.triggers = W.deepcopy(opts.triggers)
  rim.load = W.deepcopy(opts.load)
  rim.conditions = W.deepcopy(opts.conditions or {})
  rim.subRegions = opts.subRegions or {}
  rim.actions = { init = {}, start = {}, finish = {} }
  rim.config, rim.authorOptions, rim.information = {}, {}, {}
  return rim
end

-- ---- LIFE, left -----------------------------------------------------------------------
local lifeDonorRim = byId["Rogue - Player Portrait"]   -- the portrait's uid becomes the rim
local life = makeGlobe(rename("Rogue - Health", "Rogue - Life Globe"), {
  size = GLOBE_MAIN, color = COL_LIFE, parent = PLAYER_GROUP, x = -GLOBE_X, pct = PCT_MAIN,
})
local lifeRim = makeRim(lifeDonorRim, {
  id = "Rogue - Life Globe Rim", parent = PLAYER_GROUP, size = GLOBE_MAIN + RIM_PAD,
  color = COL_RIM, x = -GLOBE_X,
  triggers = life.triggers,                       -- appears and fades with its globe
  load = lifeDonorRim.load,
  conditions = lifeDonorRim.conditions,           -- the portrait's out-of-combat fade
})

-- ---- ENERGY, right --------------------------------------------------------------------
local energyDonorRim = byId["Rogue - Target Power"]   -- the target power ring's uid
local energy = makeGlobe(rename("Rogue - Energy", "Rogue - Energy Globe"), {
  size = GLOBE_MAIN, color = COL_ENERGY, parent = PLAYER_GROUP, x = GLOBE_X, pct = PCT_MAIN,
})
-- The breakpoints become two horizontal waterline marks. Same dim + lit pair, same colours,
-- same subRegions indexes; only the geometry is re-derived.
for _, bp in ipairs(BREAKPOINTS) do
  for _, entry in ipairs({ { i = bp.dim, h = MARK_DIM_H }, { i = bp.lit, h = MARK_LIT_H } }) do
    local mark = energy.subRegions[entry.i]
    mark.width, mark.height = markW(bp.f), entry.h
    mark.xOffset, mark.yOffset = 0, markY(bp.f)
    mark.anchor_mode, mark.anchor_point, mark.self_point = "point", "CENTER", "CENTER"
    mark.textureRotate, mark.textureRotation, mark.textureMirror = false, 0, false
  end
end
local energyRim = makeRim(energyDonorRim, {
  id = "Rogue - Energy Globe Rim", parent = PLAYER_GROUP, size = GLOBE_MAIN + RIM_PAD,
  color = COL_RIM, x = GLOBE_X,
  triggers = energy.triggers,                     -- appears and fades with its globe
  load = energyDonorRim.load,
  conditions = { W.deepcopy(energy.conditions[1]) },  -- the same out-of-combat fade
})

-- ---- TARGET, centre -------------------------------------------------------------------
local targetRimDonor = byId["Rogue - Target Portrait"]
local target = makeGlobe(rename("Rogue - Target Health", "Rogue - Target Life Globe"), {
  size = GLOBE_TGT, color = COL_LIFE, parent = TARGET_GROUP, x = 0, pct = PCT_TGT,
})
-- The plain glass. It carries the target Health trigger it already had as a portrait, so it
-- is the rim you see whenever threat has nothing to say — solo, in an arena, or on a unit
-- you are not on the threat table of. The threat rim below draws over it, same size and
-- same art, so the player only ever sees one rim.
local targetRim = makeRim(targetRimDonor, {
  id = "Rogue - Target Globe Rim", parent = TARGET_GROUP, size = GLOBE_TGT + RIM_PAD,
  color = COL_RIM, x = 0,
  triggers = targetRimDonor.triggers,
  load = targetRimDonor.load,
  conditions = targetRimDonor.conditions,
})

-- ---- THREAT: the target globe's rim colour --------------------------------------------
local threatOld = byId["Rogue - Threat"]
local threatText = W.deepcopy(threatOld.subRegions[1])
threatText.text_anchorPoint = "CENTER"
threatText.anchorXOffset, threatText.anchorYOffset = 0, PCT_THREAT.y
threatText.text_fontSize = PCT_THREAT.size

local threatConditions = W.deepcopy(threatOld.conditions)
for _, cond in ipairs(threatConditions) do
  for _, change in ipairs(cond.changes) do
    -- `foregroundColor` belongs to progresstexture. On a texture region the colour property
    -- is `color`; anything else is skipped without a warning.
    if change.property == "foregroundColor" then change.property = "color" end
  end
end

local threat = makeRim(threatOld, {
  id = "Rogue - Threat Rim", parent = TARGET_GROUP, size = GLOBE_TGT + RIM_PAD,
  color = threatOld.foregroundColor,              -- the same green base it always had
  x = 0,
  triggers = threatOld.triggers,
  load = threatOld.load,
  conditions = threatConditions,
  subRegions = { threatText },
})

-- The >= 80% halo keeps its trigger, gate, colour, ADD blend and alphaPulse; it just pulses
-- on the rim now instead of around a ring.
local flash = byId["Rogue - Threat Flash"]
flash.width, flash.height = GLOBE_TGT + RIM_PAD, GLOBE_TGT + RIM_PAD
flash.texture = RIM_TEX
flash.parent = TARGET_GROUP
flash.xOffset, flash.yOffset = 0, 0
flash.frameStrata = RIM_STRATA

-- ===== rewire the tree =================================================================
byId["Rogue - Player Portrait"], byId["Rogue - Target Portrait"] = nil, nil
byId["Rogue - Target Power"], byId["Rogue - Threat"] = nil, nil
byId[lifeRim.id], byId[energyRim.id] = lifeRim, energyRim
byId[targetRim.id], byId[threat.id] = targetRim, threat

local playerGroup = rename("Rogue - Player Orb", PLAYER_GROUP)
playerGroup.xOffset, playerGroup.yOffset = GROUP_X, GROUP_Y
playerGroup.controlledChildren = { life.id, lifeRim.id, energy.id, energyRim.id }

local targetGroup = rename("Rogue - Target Orb", TARGET_GROUP)
targetGroup.xOffset, targetGroup.yOffset = GROUP_X, GROUP_Y
-- Order is layering: siblings get increasing frame levels in controlledChildren order
-- (FixGroupChildrenOrderImpl), so the threat rim draws over the plain rim and the halo
-- over both.
targetGroup.controlledChildren = { target.id, targetRim.id, threat.id, flash.id }

for index, childId in ipairs(RES.controlledChildren) do
  if childId == "Rogue - Player Orb" then RES.controlledChildren[index] = PLAYER_GROUP
  elseif childId == "Rogue - Target Orb" then RES.controlledChildren[index] = TARGET_GROUP end
end

-- Rebuild the flat child list depth-first from the tree: `Rogue - Target Power` changed
-- parents, so the v48 ordering no longer matches the group structure.
local rebuilt = {}
local function push(node)
  for _, childId in ipairs(node.controlledChildren or {}) do
    local child = assert(byId[childId], "missing child table: " .. childId)
    rebuilt[#rebuilt + 1] = child
    if child.controlledChildren then push(child) end
  end
end
push(T.d)
T.c = rebuilt

-- ===== verify ==========================================================================
local encoded = W.encode(T)
W.verify(T, encoded)
local cont = W.uidContinuityStrings(encoded, src)
W.assertUidContinuity(cont, "rogue v49")
assert(cont.missing == 0 and cont.changed == 0, "rogue v49: a uid was lost or re-homed")
assert(cont.oldCount == cont.newCount,
  "rogue v49: the globes replace the orbs one for one; no aura may be added or removed")

local NEW = W.decode(encoded)
local newById = { [NEW.d.id] = NEW.d }
for _, aura in ipairs(NEW.c) do newById[aura.id] = aura end

-- AUDIT 1: absolute screen position, walked up the parent chain exactly as WeakAuras
-- anchors it (a grouped child with anchorFrameType SCREEN anchors to its group's frame).
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

local PLACED = {
  ["Rogue - Life Globe"]        = { -GLOBE_X, GLOBE_Y },
  ["Rogue - Life Globe Rim"]    = { -GLOBE_X, GLOBE_Y },
  ["Rogue - Energy Globe"]      = {  GLOBE_X, GLOBE_Y },
  ["Rogue - Energy Globe Rim"]  = {  GLOBE_X, GLOBE_Y },
  ["Rogue - Target Life Globe"] = {        0, GLOBE_Y },
  ["Rogue - Target Globe Rim"]  = {        0, GLOBE_Y },
  ["Rogue - Threat Rim"]        = {        0, GLOBE_Y },
  ["Rogue - Threat Flash"]      = {        0, GLOBE_Y },
}
for id, want in pairs(PLACED) do
  local x, y = absolute(id)
  assert(x == want[1] and y == want[2],
    ("%s lands at (%d,%d), the shared geometry puts it at (%d,%d)")
      :format(id, x, y, want[1], want[2]))
end

-- AUDIT 2: every globe is a vessel, not an arc, and every rim is its globe + 6.
local GLOBES = {
  ["Rogue - Life Globe"]        = { size = GLOBE_MAIN, color = COL_LIFE,   pct = PCT_MAIN },
  ["Rogue - Energy Globe"]      = { size = GLOBE_MAIN, color = COL_ENERGY, pct = PCT_MAIN },
  ["Rogue - Target Life Globe"] = { size = GLOBE_TGT,  color = COL_LIFE,   pct = PCT_TGT },
}
for id, want in pairs(GLOBES) do
  local g = newById[id]
  assert(g.regionType == "progresstexture", id .. " is not a progresstexture")
  assert(g.orientation == ORIENT, id .. " does not fill bottom to top")
  assert(g.width == want.size and g.height == want.size, id .. " is not " .. want.size .. "px")
  assert(g.foregroundTexture == FILL_TEX and g.backgroundTexture == FILL_TEX,
    id .. " is not drawn on the globe disc")
  assert(iseq(g.foregroundColor, want.color), id .. " is not its canonical colour")
  assert(iseq(g.backgroundColor, COL_EMPTY), id .. " has no near-black empty vessel")
  assert(g.backgroundOffset == 0 and g.crop_x == 0.41 and g.crop_y == 0.41
    and g.auraRotation == 0 and g.slant == 0 and g.slanted == false,
    id .. " deviates from the canonical fill fields")
  local text = g.subRegions[1]
  assert(text.type == "subtext" and text.text_fontSize == want.pct.size
    and text.text_anchorPoint == "CENTER" and text.anchorYOffset == want.pct.y,
    id .. ": the number is not inside the glass at the canonical size")
end

local RIMS = {
  ["Rogue - Life Globe Rim"]   = GLOBE_MAIN + RIM_PAD,
  ["Rogue - Energy Globe Rim"] = GLOBE_MAIN + RIM_PAD,
  ["Rogue - Target Globe Rim"] = GLOBE_TGT + RIM_PAD,
  ["Rogue - Threat Rim"]       = GLOBE_TGT + RIM_PAD,
  ["Rogue - Threat Flash"]     = GLOBE_TGT + RIM_PAD,
}
for id, size in pairs(RIMS) do
  local rim = newById[id]
  assert(rim.regionType == "texture", id .. " is not a texture region")
  assert(rim.width == size and rim.height == size, id .. " is not " .. size .. "px")
  assert(rim.texture == RIM_TEX, id .. " is not drawn on the rim art")
  assert(rim.frameStrata == RIM_STRATA, id .. " is not at the canonical rim strata")
end

-- The portrait is gone from the pack entirely, and no ring art survives anywhere.
for _, aura in ipairs(NEW.c) do
  assert(aura.regionType ~= "model", "a portrait survived: " .. aura.id)
  local tex = aura.foregroundTexture or aura.backgroundTexture or aura.texture
  assert(tex ~= RING_20, aura.id .. " is still drawn on ring art")
end

-- AUDIT 3: the breakpoint marks, recovered FROM the committed string rather than recomputed
-- the same way they were written. yOffset gives back the fraction, width gives back the
-- chord, and the pair still sits at the subRegions indexes the conditions point at.
local en = newById["Rogue - Energy Globe"]
assert(#en.subRegions == 5, "the energy globe lost a subregion")
for _, bp in ipairs(BREAKPOINTS) do
  for _, entry in ipairs({ { i = bp.dim, h = MARK_DIM_H }, { i = bp.lit, h = MARK_LIT_H } }) do
    local mark = en.subRegions[entry.i]
    assert(mark.type == "subtexture", "energy subRegions " .. entry.i .. " is not a mark")
    local fraction = mark.yOffset / GLOBE_MAIN + 0.5
    assert(math.abs(fraction - bp.f) < 0.0001,
      ("energy mark %d sits at %.4f of the globe, expected %.2f"):format(entry.i, fraction, bp.f))
    assert(mark.xOffset == 0, "energy mark " .. entry.i .. " is not centred")
    local half = mark.width / 2
    local reach = math.sqrt((GLOBE_MAIN / 2) ^ 2 - mark.yOffset ^ 2)
    assert(math.abs(half - reach) < 0.002,
      ("energy mark %d reaches %.3f, the globe reaches %.3f there"):format(entry.i, half, reach))
    assert(mark.height == entry.h, "energy mark " .. entry.i .. " lost its dim/lit weight")
  end
end
do  -- the dim/lit colours are exactly what v48 shipped
  local before = oldById["Rogue - Energy"]
  for i = 2, 5 do
    assert(iseq(before.subRegions[i].textureColor, en.subRegions[i].textureColor),
      "energy mark " .. i .. " changed colour")
    assert(before.subRegions[i].textureVisible == en.subRegions[i].textureVisible,
      "energy mark " .. i .. " changed its default visibility")
    assert(before.subRegions[i].textureTexture == en.subRegions[i].textureTexture,
      "energy mark " .. i .. " changed art")
  end
end

-- AUDIT 4: threat. Same trigger, same gate, same escalation order and the same zero guard —
-- re-homed onto the property a texture region actually reads.
do
  local before, after = oldById["Rogue - Threat"], newById["Rogue - Threat Rim"]
  assert(iseq(before.triggers, after.triggers), "the threat trigger changed")
  assert(iseq(before.load, after.load), "the threat load gate changed")
  assert(iseq(before.foregroundColor, after.color), "the threat green base changed")
  assert(#after.conditions == 3, "the threat escalation lost a step")
  assert(after.conditions[1].check.variable == "threatpct"
    and after.conditions[1].check.value == "70"
    and after.conditions[1].changes[1].property == "color"
    and iseq(after.conditions[1].changes[1].value, before.conditions[1].changes[1].value),
    "the 70% orange step is not on the rim colour")
  assert(after.conditions[2].check.variable == "aggro"
    and after.conditions[2].changes[1].property == "color"
    and iseq(after.conditions[2].changes[1].value, before.conditions[2].changes[1].value),
    "the aggro red step is not on the rim colour, or is no longer last")
  assert(after.conditions[3].check.variable == "threatvalue"
    and after.conditions[3].check.op == "<=" and after.conditions[3].check.value == "0"
    and after.conditions[3].changes[1].property == "alpha"
    and after.conditions[3].changes[1].value == 0,
    "the zero-threat guard is gone: the rim would read as full aggro at no threat")
  local text = after.subRegions[1]
  assert(text and text.type == "subtext" and text.text_text == "%threatpct%%"
    and text.text_fontSize == PCT_THREAT.size and text.anchorYOffset == PCT_THREAT.y,
    "the threat percentage is not above the target globe")
  assert(iseq(oldById["Rogue - Threat Flash"].triggers, newById["Rogue - Threat Flash"].triggers)
    and iseq(oldById["Rogue - Threat Flash"].load, newById["Rogue - Threat Flash"].load)
    and iseq(oldById["Rogue - Threat Flash"].color, newById["Rogue - Threat Flash"].color)
    and newById["Rogue - Threat Flash"].blendMode == "ADD"
    and iseq(oldById["Rogue - Threat Flash"].animation, newById["Rogue - Threat Flash"].animation),
    "the 80% threat halo changed behaviour")
end

-- AUDIT 5: the danger escalations on the two health globes survive, on the progresstexture
-- property that is actually read.
do
  local pairsToCheck = {
    { old = "Rogue - Health",        new = "Rogue - Life Globe" },
    { old = "Rogue - Target Health", new = "Rogue - Target Life Globe" },
    { old = "Rogue - Energy",        new = "Rogue - Energy Globe" },
  }
  for _, p in ipairs(pairsToCheck) do
    local before, after = oldById[p.old], newById[p.new]
    assert(iseq(before.triggers, after.triggers), p.new .. ": the trigger changed")
    assert(iseq(before.load, after.load), p.new .. ": the load gate changed")
    assert(iseq(before.conditions, after.conditions), p.new .. ": a condition changed")
    for _, cond in ipairs(after.conditions) do
      for _, change in ipairs(cond.changes) do
        assert(change.property ~= "barColor",
          p.new .. ": barColor is aurabar-only and would be a silent no-op here")
      end
    end
  end
end

-- AUDIT 6: nothing outside the orb cluster moved at all.
local CLUSTER = {
  ["Rogue - Player Globes"] = true, ["Rogue - Target Globe"] = true,
  ["Rogue - Life Globe"] = true, ["Rogue - Life Globe Rim"] = true,
  ["Rogue - Energy Globe"] = true, ["Rogue - Energy Globe Rim"] = true,
  ["Rogue - Target Life Globe"] = true, ["Rogue - Target Globe Rim"] = true,
  ["Rogue - Threat Rim"] = true, ["Rogue - Threat Flash"] = true,
}
local RECYCLED = {
  ["Rogue - Player Orb"] = true, ["Rogue - Target Orb"] = true,
  ["Rogue - Health"] = true, ["Rogue - Player Portrait"] = true,
  ["Rogue - Energy"] = true, ["Rogue - Target Power"] = true,
  ["Rogue - Target Health"] = true, ["Rogue - Target Portrait"] = true,
  ["Rogue - Threat"] = true, ["Rogue - Threat Flash"] = true,
}
assert(iseq(OLD.d, NEW.d), "the top-level group changed")
assert(#OLD.c == #NEW.c, "the aura count changed")
for _, old in ipairs(OLD.c) do
  if not RECYCLED[old.id] then
    local new = assert(newById[old.id], "aura disappeared: " .. old.id)
    if old.id == "Rogue - Resources" then
      -- the only permitted change: the two renamed group entries
      for key in pairs(old) do
        if key ~= "controlledChildren" then
          assert(iseq(old[key], new[key]), "Rogue - Resources changed in " .. key)
        end
      end
      assert(#old.controlledChildren == #new.controlledChildren,
        "the Resources group gained or lost a child")
      for i, childId in ipairs(old.controlledChildren) do
        local expected = childId
        if childId == "Rogue - Player Orb" then expected = PLAYER_GROUP
        elseif childId == "Rogue - Target Orb" then expected = TARGET_GROUP end
        assert(new.controlledChildren[i] == expected,
          "the Resources group's children were reordered")
      end
    else
      assert(iseq(old, new), old.id .. ": changed outside the orb cluster")
    end
  end
end
-- and every recycled uid really did land on a cluster region
local uidHome = {}
for _, aura in ipairs(NEW.c) do uidHome[aura.uid] = aura.id end
for _, old in ipairs(OLD.c) do
  if RECYCLED[old.id] then
    local home = assert(uidHome[old.uid], old.id .. "'s uid was orphaned")
    assert(CLUSTER[home], old.id .. "'s uid landed outside the globe cluster: " .. home)
  end
end

local out = assert(io.open(PACK, "w")); out:write(encoded); out:close()
print(("audit ok: globes %d/%d/%d at (-%d,%d) (0,%d) (+%d,%d), rims +%d at strata %d")
  :format(GLOBE_MAIN, GLOBE_TGT, GLOBE_MAIN, GLOBE_X, GLOBE_Y, GLOBE_Y, GLOBE_X, GLOBE_Y,
    RIM_PAD, RIM_STRATA))
print(("breakpoints: 35 -> y=%.3f w=%.3f, 40 -> y=%.3f w=%.3f")
  :format(markY(0.35), markW(0.35), markY(0.40), markW(0.40)))
print(("uid continuity: stable=%d changed=%d retained=%d missing=%d parentSame=%s")
  :format(cont.stable, cont.changed, cont.retained, cont.missing, tostring(cont.parentSame)))
print(("wrote %s (%d auras, %d chars)"):format(PACK, #T.c + 1, #encoded))
