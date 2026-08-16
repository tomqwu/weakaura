-- rogue v50 -> v51: the globes go back to being RINGS around a live portrait.
--
-- WHY. v49/v50 replaced the ring clusters with Diablo-style filled globes, and side by side
-- with the older ring-and-portrait build the rings won: two concentric arcs around a live 3D
-- face read as *a unit* — you and your target — where two filled discs read as two gauges
-- bolted to the screen. So the vessels become rings again, the portraits come back, and the
-- percentages move back OUT from under the glass to just outside the rings (a `model` region
-- cannot carry text at all — SubText's supports() gate lists texture / progresstexture /
-- icon / aurabar / empty, not model — so with a face in the middle the numbers have nowhere
-- else to go, which is exactly the trade v49 made in the other direction).
--
-- THE CANONICAL RING CLUSTER, shared verbatim by all seven packs and declared as named
-- constants below so it cannot drift the way the v47 per-pack diameters did:
--     OUTER 84, INNER 62, PORTRAIT 44 on BOTH clusters (44/84 is the approved 0.52 ratio),
--     player cluster at (-270, 40), target cluster at (+270, 110), Ring_20px art.
-- The same numbers are already shipped by tbc/paladin v13; this pack is checked against them.
--
-- TWO RINGS AND A FACE, NOT THREE RINGS. v48's target cluster nested threat + health + power
-- and that third arc is what made it look busy and uneven next to the player's two. So:
--     PLAYER: outer = health, inner = energy, centre = live player portrait
--     TARGET: outer = threat, inner = target health, centre = live target portrait
-- No target power ring is built. Its uid does not disappear (see UID DISCIPLINE) — it is
-- recycled onto the target's outer TRACK, below.
--
-- ORIENTATION IS THE FIELD THAT MAKES A RING A RING. Back to
--     orientation = "CLOCKWISE"    -- Private.orientation_with_circle_types, the radial path
-- which swaps which fields are live again: startAngle / endAngle matter (0 / 360 = a full
-- circle; WA normalises 0/360 -> 0/0 and then corrects endAngle back up by 360, so a full
-- ring is a handled case and not a degenerate one), and compress / slanted / slantMode go
-- inert. crop_x / crop_y stay 0.41: that is the IDENTITY value on the circular path, not
-- "no crop" — TextureCoords.TransformPoint expands by sqrt(2) so rotated quadrants never run
-- off the texture, and 1 + 0.41 exactly cancels it. Setting 0 blows the ring up 1.41x.
-- backgroundOffset stays 0 so the track sits under the fill instead of haloing around it.
--
-- THE PORTRAITS NEED BOTH MODEL FIELDS. modelIsUnit = true plus the unit string, and the
-- unit string has to be written to model_fileId AND model_path: current WeakAuras reads
-- model_fileId, WA 3.5.0 read model_path, and the migration that bridges them (Modernize
-- < 72) is guarded by IsClassicEra(), which is a DISTINCT predicate from IsTBC() — so on a
-- 2.5.x client that migration never runs and emitting only model_path is a silent no-op.
-- portraitZoom = true gives Blizzard's head framing.
--
-- THE BREAKPOINT MARKS GO BACK ON THE CIRCUMFERENCE. On a vessel the 35/40 energy marks were
-- horizontal waterlines whose width was the globe's chord at that height. A ring has no
-- chord, so they return to the v47/v48 polar form, re-derived from the INNER radius:
--     r = INNER/2 * 0.94 ;  x = r*sin(2*pi*f) ;  y = r*cos(2*pi*f)     (f = threshold/max)
-- (angle 0 is 12 o'clock and increases clockwise, matching the ring's fill direction), and
-- the width follows the height so each mark is a square pip on the stroke — a chord width
-- would now reach right across the middle of the cluster and through the portrait. The dim +
-- lit pair, their heights (3 / 5), their colours (red = Eviscerate at 35, purple = Sinister
-- Strike at 40) and their conditions are carried across untouched, and the pair keeps its
-- subRegions INDEX so the `sub.4` / `sub.5` condition references keep pointing at the lit
-- marks. Radius and angle are recovered back OUT of the committed string at the bottom, so
-- the proof does not lean on the arithmetic that produced them.
--
-- THE SPECULAR HIGHLIGHT IS DROPPED. It was a curved-glass effect for a filled vessel; on a
-- 20px stroke it is a white blob in the middle of a hole. Three subregions go, all of them
-- the LAST on their region, so no `sub.N` reference moves.
--
-- THREAT KEEPS EVERYTHING IT GAINED, on the property that actually exists. It goes back to
-- being a progresstexture, so its escalation conditions go back to `foregroundColor`;
-- `color` is a texture-region property and would be a SILENT no-op here (Conditions.lua
-- skips unknown properties without warning — the same trap as barColor on a progresstexture,
-- in the other direction). The `threatvalue <= 0 -> alpha 0` guard stays: without it the ring
-- reads as full aggro at zero threat. The group/raid load gate and the >= 80% pulsing halo
-- are unchanged.
--
-- ONE HONEST ADDITION, AND IT IS WHERE THE SPARE UID GOES. This pack is the only one of the
-- seven that built a target POWER ring (v47 added it; v49 parked its uid on the energy globe's
-- rim), so after the retype it has one uid more than the canonical seven-region cluster needs.
-- Dropping it is not an option — WeakAuras never removes an aura an import does not mention,
-- so a dropped uid is an orphan sitting on the user's screen forever. It goes to
-- `Rogue - Target Ring Track`: a plain Ring_20px annulus at OUTER in the rings' own track
-- colour {0,0,0,0.55}, carrying the target Health trigger, listed FIRST in its group so the
-- threat ring draws over it in the same annulus. It is not a third ring — it is the outer
-- ring's unfilled track — and it earns its place: the threat ring only loads in a party or
-- raid, so without it the target cluster solo is one lonely inner ring while the player
-- cluster shows two, and the matched pair is the whole point of the design.
--
-- UID DISCIPLINE. Eight regions become eight regions and every uid is recycled onto the thing
-- that took its place, so the import is a clean Update with no orphans. No `uid()` is called:
-- this patch consumes nothing from the random stream and adds no aura.
--     Rogue - Life Globe        -> Rogue - Health Ring        (progresstexture, same type)
--     Rogue - Life Globe Rim    -> Rogue - Player Portrait    (texture -> model; it WAS the
--                                                              player portrait before v49)
--     Rogue - Energy Globe      -> Rogue - Energy Ring        (progresstexture, same type)
--     Rogue - Energy Globe Rim  -> Rogue - Target Ring Track  (texture, re-homed; it was the
--                                                              target power ring before v49)
--     Rogue - Target Life Globe -> Rogue - Target Health Ring (progresstexture, same type)
--     Rogue - Target Globe Rim  -> Rogue - Target Portrait    (texture -> model; it WAS the
--                                                              target portrait before v49)
--     Rogue - Threat Rim        -> Rogue - Threat Ring        (texture -> progresstexture)
--     Rogue - Threat Flash      -> Rogue - Threat Flash       (texture, re-arted and resized)
-- The two cluster groups keep their uids and are renamed to what they now hold.
--
-- POSITIONS ARE ABSOLUTE. Nothing here anchors to the screen directly: each cluster hangs off
-- a group that hangs off `Rogue - Resources` that hangs off the pack's top group, and every
-- one of those carries an offset. The two group offsets are therefore computed by SUBTRACTING
-- the inherited chain, and the finished string is decoded at the bottom and the chain walked
-- to prove each cluster lands exactly on its number. x = +-270 is not a look: the Alerts
-- column sits at x = -150 with 40px icons (so -170..-130) and the PvP column at x = 200 with
-- 36px icons (182..218), and BOTH are dynamic groups that grow vertically — so at +-190 an
-- 84px ring (-232..-148 / 148..232) is inside those columns from the second simultaneous
-- prompt onward. 270 is the tightest symmetric position clear at any stack depth, and both
-- clearances are asserted numerically at the bottom rather than argued here.
--
-- WHAT THIS PATCH MAY NOT TOUCH: every trigger, load gate, condition, colour and spell id
-- outside the cluster, and every aura outside it — buffs, alerts, combo pips, cooldown row,
-- procs, the PvP layer — is asserted field by field against v50 at the bottom.
--
-- Run: lua5.1 tbc/rogue/patch-v51.lua   (rewrites all-specs.txt in place)

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local SCRIPTS = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local PACK = dir .. "/all-specs.txt"
local savedArg = arg
arg = { [0] = SCRIPTS .. "/wa_lib.lua" }
local W = dofile(SCRIPTS .. "/wa_lib.lua")
arg = savedArg

-- ===== canonical ring geometry, shared verbatim by every pack ==========================
local MEDIA     = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\"
local RING_TEX  = MEDIA .. "Ring_20px.tga"
local OUTER     = 84     -- outer ring diameter, BOTH clusters
local INNER     = 62     -- inner ring diameter, BOTH clusters
local PORTRAIT  = 44     -- live unit portrait, BOTH clusters (44/84 = 0.52)
local CLUSTER_X = 270    -- player cluster at x = -270, target cluster at x = +270
local CLUSTER_Y = 40     -- ABSOLUTE screen y for the player cluster
local TARGET_Y  = 110    -- ABSOLUTE screen y for the target cluster

-- The percentages ride on their own ring and are sized by ROLE, not by cluster, so the two
-- sides line up: health just under the outer ring, power under it, threat above.
local PCT_HP     = { size = 13, y = -54 }
local PCT_POWER  = { size = 10, y = -70 }
local PCT_THREAT = { size = 10, y =  54 }

local COL_HEALTH = { 0.15, 0.82, 0.28, 1 }   -- green
local COL_ENERGY = { 0.90, 0.80, 0.20, 1 }   -- a rogue's power IS energy: yellow
local COL_THREAT = { 0.25, 0.80, 0.30, 1 }   -- threat base, before the escalations
local COL_TRACK  = { 0, 0, 0, 0.55 }         -- the unfilled arc behind every ring

-- Distance from a ring's centre to its stroke, as a fraction of the outer radius. Ring_20px's
-- band runs from 1 - 20/128 = 0.844 of the outer radius to 1.0, so 0.94 lands inside the
-- stroke. Asserted numerically below rather than argued.
local TICK_RADIUS = 0.94

-- The 35/40 energy breakpoints. `dim` and `lit` are subRegions indexes and are FIXED by the
-- conditions that reference sub.4 / sub.5. Energy is capped at 100 on every rogue, so 35
-- energy is 0.35 of the ring.
local MARK_DIM, MARK_LIT = 3, 5              -- the pip sizes v50 carried as mark heights
local BREAKPOINTS = {
  { threshold = 35, f = 0.35, dim = 2, lit = 4 },
  { threshold = 40, f = 0.40, dim = 3, lit = 5 },
}

-- the v50 state this patch replays onto
local FILL_TEX   = MEDIA .. "Circle_Smooth.tga"
local RIM_TEX    = MEDIA .. "Circle_Smooth_Border.tga"
local GLOBE_MAIN, GLOBE_TGT, RIM_PAD = 72, 44, 4
local BEFORE_X, BEFORE_Y, BEFORE_Y_TGT = 270, 40, 110

local PLAYER_GROUP, TARGET_GROUP = "Rogue - Player Cluster", "Rogue - Target Cluster"
local RES_GROUP = "Rogue - Resources"

-- ===== helpers =========================================================================
local function iseq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not iseq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

-- Byte-identical to the rounding v47/v48 used, so a mark that lands where it used to keeps
-- its exact literal.
local function round(v) return math.floor(v * 1000 + 0.5) / 1000 end

local function noAnimation()
  return {
    start  = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
    main   = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
    finish = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
  }
end

-- ===== read the v50 build ==============================================================
local f = assert(io.open(PACK, "r")); local src = f:read("*a"); f:close()
local T = W.decode(src)
local OLD = W.decode(src)

local byId, oldById = { [T.d.id] = T.d }, { [OLD.d.id] = OLD.d }
local indexOf = {}
for i, aura in ipairs(T.c) do byId[aura.id] = aura; indexOf[aura.id] = i end
for _, aura in ipairs(OLD.c) do oldById[aura.id] = aura end

-- ===== the exact v50 state this patch expects ==========================================
local V50 = {
  { id = "Rogue - Life Globe",        group = "Rogue - Player Globes", x = -BEFORE_X,
    kind = "progresstexture", size = GLOBE_MAIN, subs = 2 },
  { id = "Rogue - Life Globe Rim",    group = "Rogue - Player Globes", x = -BEFORE_X,
    kind = "texture", size = GLOBE_MAIN + RIM_PAD, subs = 0 },
  { id = "Rogue - Energy Globe",      group = "Rogue - Player Globes", x = BEFORE_X,
    kind = "progresstexture", size = GLOBE_MAIN, subs = 6 },
  { id = "Rogue - Energy Globe Rim",  group = "Rogue - Player Globes", x = BEFORE_X,
    kind = "texture", size = GLOBE_MAIN + RIM_PAD, subs = 0 },
  { id = "Rogue - Target Life Globe", group = "Rogue - Target Globe",  x = 0,
    kind = "progresstexture", size = GLOBE_TGT, subs = 2 },
  { id = "Rogue - Target Globe Rim",  group = "Rogue - Target Globe",  x = 0,
    kind = "texture", size = GLOBE_TGT + RIM_PAD, subs = 0 },
  { id = "Rogue - Threat Rim",        group = "Rogue - Target Globe",  x = 0,
    kind = "texture", size = GLOBE_TGT + RIM_PAD, subs = 1 },
  { id = "Rogue - Threat Flash",      group = "Rogue - Target Globe",  x = 0,
    kind = "texture", size = GLOBE_TGT + RIM_PAD, subs = 0 },
}

local RES = assert(byId[RES_GROUP], "the Resources group is missing")
local oldPlayerGroup = assert(byId["Rogue - Player Globes"], "the v50 player group is missing")
local oldTargetGroup = assert(byId["Rogue - Target Globe"], "the v50 target group is missing")

do
  local inheritX, inheritY = T.d.xOffset + RES.xOffset, T.d.yOffset + RES.yOffset
  for _, node in ipairs({ oldPlayerGroup, oldTargetGroup }) do
    assert(node.regionType == "group", node.id .. ": v50 cluster holder is not a group")
    assert(node.parent == RES_GROUP, node.id .. ": v50 cluster does not hang off Resources")
    assert(node.xOffset + inheritX == 0, node.id .. ": v50 cluster is not on the centreline")
  end
  assert(oldPlayerGroup.yOffset + inheritY == BEFORE_Y, "the v50 player globes are not at y=40")
  assert(oldTargetGroup.yOffset + inheritY == BEFORE_Y_TGT, "the v50 target globe is not at y=110")

  for _, want in ipairs(V50) do
    local aura = assert(byId[want.id], "v50 globe region missing: " .. want.id)
    assert(aura.regionType == want.kind,
      ("%s: expected a v50 %s, found %s"):format(want.id, want.kind, tostring(aura.regionType)))
    assert(aura.parent == want.group, want.id .. ": v50 parent is " .. tostring(aura.parent))
    assert(aura.width == want.size and aura.height == want.size,
      ("%s: expected v50 size %d, found %sx%s"):format(want.id, want.size,
        tostring(aura.width), tostring(aura.height)))
    assert(aura.xOffset == want.x and aura.yOffset == 0,
      ("%s: expected v50 offset (%d,0), found (%s,%s)"):format(want.id, want.x,
        tostring(aura.xOffset), tostring(aura.yOffset)))
    assert(#(aura.subRegions or {}) == want.subs,
      ("%s: expected %d v50 subregions, found %d"):format(want.id, want.subs,
        #(aura.subRegions or {})))
    if want.kind == "progresstexture" then
      assert(aura.orientation == "VERTICAL", want.id .. ": v50 globe does not fill bottom to top")
      assert(aura.foregroundTexture == FILL_TEX, want.id .. ": v50 globe is not the filled disc")
      -- the specular highlight this patch drops is always the LAST subregion
      local hl = aura.subRegions[#aura.subRegions]
      assert(hl.type == "subtexture" and hl.textureBlendMode == "ADD"
        and hl.textureTexture == FILL_TEX, want.id .. ": the last subregion is not the v50 highlight")
      assert(aura.subRegions[1].type == "subtext", want.id .. ": subRegions[1] is not the percentage")
    else
      assert(aura.texture == RIM_TEX, want.id .. ": v50 rim art is not what v51 replays onto")
    end
  end
end

local energyOld = byId["Rogue - Energy Globe"]
do  -- the four marks really are the v50 waterlines, dim pair then lit pair
  local r = GLOBE_MAIN / 2
  for _, bp in ipairs(BREAKPOINTS) do
    local dy = (bp.f - 0.5) * GLOBE_MAIN
    for _, entry in ipairs({ { i = bp.dim, h = MARK_DIM }, { i = bp.lit, h = MARK_LIT } }) do
      local sub = assert(energyOld.subRegions[entry.i], "energy mark missing at " .. entry.i)
      assert(sub.type == "subtexture", "energy subRegions " .. entry.i .. " is not a mark")
      assert(sub.height == entry.h,
        ("energy mark %d: expected v50 height %d, found %s"):format(entry.i, entry.h,
          tostring(sub.height)))
      assert(math.abs(sub.yOffset - round(dy)) < 0.002 and sub.xOffset == 0,
        ("energy mark %d is not the v50 waterline for %d energy"):format(entry.i, bp.threshold))
      assert(math.abs(sub.width - round(2 * math.sqrt(r * r - dy * dy))) < 0.002,
        ("energy mark %d is not the v50 chord width"):format(entry.i))
    end
  end
  local marks = 0
  for _, cond in ipairs(energyOld.conditions) do
    for _, change in ipairs(cond.changes) do
      if change.property == "sub.4.textureVisible" or change.property == "sub.5.textureVisible" then
        marks = marks + 1
      end
    end
  end
  assert(marks == 2, "the v50 energy conditions do not light subRegions 4 and 5")
end

do  -- the threat conditions this patch has to re-home back onto a progresstexture
  local th = byId["Rogue - Threat Rim"]
  assert(#th.conditions == 3, "v50 threat does not carry 3 conditions")
  assert(th.conditions[1].check.variable == "threatpct" and th.conditions[1].check.value == "70",
    "v50 threat condition 1 is not the 70% escalation")
  assert(th.conditions[2].check.variable == "aggro", "v50 threat condition 2 is not aggro")
  assert(th.conditions[3].check.variable == "threatvalue" and th.conditions[3].check.op == "<=",
    "v50 threat condition 3 is not the zero-threat guard")
  assert(th.load.use_ingroup and th.load.ingroup.multi.group and th.load.ingroup.multi.raid,
    "v50 threat has lost its group/raid load gate")
  assert(iseq(th.color, COL_THREAT), "v50 threat base colour is not the canonical green")
end

-- A complete, WA-valid progresstexture straight out of the shipped pack, used as the schema
-- template for the threat ring. Captured BEFORE anything is edited.
local RING_PROTO = W.deepcopy(byId["Rogue - Target Life Globe"])

-- Where every `sub.N` condition reference in the pack points BEFORE this patch, recorded so
-- the audit can prove none of them silently re-homed.
local function subReferences(root)
  local refs, all = {}, { root.d }
  for _, aura in ipairs(root.c) do all[#all + 1] = aura end
  for _, aura in ipairs(all) do
    for ci, cond in ipairs(aura.conditions or {}) do
      for gi, change in ipairs(cond.changes or {}) do
        local index = tostring(change.property or ""):match("^sub%.(%d+)%.")
        if index then
          refs[#refs + 1] = { id = aura.id, cond = ci, change = gi, index = tonumber(index),
                              property = change.property }
        end
      end
    end
  end
  return refs
end
local SUB_REFS_BEFORE = subReferences(OLD)
assert(#SUB_REFS_BEFORE > 0, "no sub.N condition references found: the audit would prove nothing")

-- ===== builders ========================================================================
local function rename(oldId, newId)
  local aura = assert(byId[oldId], "missing " .. oldId)
  byId[oldId] = nil
  aura.id = newId
  byId[newId] = aura
  indexOf[newId], indexOf[oldId] = indexOf[oldId], nil
  return aura
end

local function replace(oldId, aura)
  local i = assert(indexOf[oldId], "missing " .. oldId)
  T.c[i] = aura
  byId[oldId] = nil
  byId[aura.id] = aura
  indexOf[aura.id], indexOf[oldId] = i, nil
  return aura
end

-- Turn a surviving progresstexture globe back into a radial ring.
local function makeRing(aura, opts)
  aura.width, aura.height = opts.size, opts.size
  aura.foregroundTexture, aura.backgroundTexture, aura.sameTexture = RING_TEX, RING_TEX, true
  aura.foregroundColor = W.deepcopy(opts.color)
  aura.backgroundColor = W.deepcopy(COL_TRACK)
  aura.backgroundOffset = 0
  aura.orientation = "CLOCKWISE"
  aura.startAngle, aura.endAngle = 0, 360        -- a full circle; live again on this path
  aura.compress, aura.slanted, aura.slant = false, false, 0
  aura.slantFirst, aura.slantMode = false, "INSIDE"
  aura.crop_x, aura.crop_y = 0.41, 0.41          -- the identity value on the circular path
  aura.auraRotation, aura.rotation = 0, 0
  aura.inverse, aura.mirror = false, false
  aura.blendMode, aura.textureWrapMode = "BLEND", "CLAMPTOBLACKADDITIVE"
  aura.desaturateForeground, aura.desaturateBackground = false, false
  aura.smoothProgress, aura.overlayclip = true, false
  aura.parent = opts.parent
  aura.xOffset, aura.yOffset = 0, 0              -- concentric: the GROUP carries the position
  aura.frameStrata, aura.alpha = 1, 1
  -- the specular highlight is the last subregion and it goes
  if opts.dropHighlight then aura.subRegions[#aura.subRegions] = nil end
  -- the number moves back outside the ring
  local text = aura.subRegions[1]
  assert(text and text.type == "subtext", aura.id .. ": subRegions[1] is not the percentage")
  text.text_fontSize = opts.pct.size
  text.text_anchorPoint = "CENTER"
  text.anchorXOffset, text.anchorYOffset = 0, opts.pct.y
  return aura
end

-- A live 3D portrait of whoever the unit is — not a class icon, not a static image, so it
-- renders NPCs and mobs on the target side without ever knowing their class. The field list
-- is the repo's proven one (poc/unit-orbs/generate.lua).
local function makePortrait(donor, opts)
  return {
    regionType = "model", id = opts.id, uid = donor.uid, parent = opts.parent,
    internalVersion = donor.internalVersion, tocversion = donor.tocversion,
    model_fileId = opts.unit, model_path = opts.unit,   -- BOTH: see the header
    modelIsUnit = true, modelDisplayInfo = false, portraitZoom = true, api = false,
    model_x = 0, model_y = 0, model_z = 0,
    model_st_tx = 0, model_st_ty = 0, model_st_tz = 0,
    model_st_rx = 270, model_st_ry = 0, model_st_rz = 0, model_st_us = 40,
    sequence = 1, advance = false, rotation = 0,
    width = PORTRAIT, height = PORTRAIT, alpha = 1,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = 0, yOffset = 0, frameStrata = 1,
    border = false, borderColor = { 1, 1, 1, 0.5 }, backdropColor = { 1, 1, 1, 0.5 },
    borderEdge = "None", borderOffset = 5, borderInset = 11,
    borderSize = 16, borderBackdrop = "Blizzard Tooltip",
    subRegions = {},
    triggers = W.deepcopy(opts.triggers),
    load = W.deepcopy(opts.load),
    conditions = W.deepcopy(opts.conditions or {}),
    actions = { init = {}, start = {}, finish = {} },
    animation = noAnimation(),
    config = {}, authorOptions = {}, information = {},
  }
end

-- ===== PLAYER CLUSTER: health outside, energy inside, your face in the middle ==========
local health = makeRing(rename("Rogue - Life Globe", "Rogue - Health Ring"), {
  size = OUTER, color = COL_HEALTH, parent = PLAYER_GROUP, pct = PCT_HP, dropHighlight = true,
})

local energy = makeRing(rename("Rogue - Energy Globe", "Rogue - Energy Ring"), {
  size = INNER, color = COL_ENERGY, parent = PLAYER_GROUP, pct = PCT_POWER, dropHighlight = true,
})

-- The marks go back on the circumference. Same formula as v47/v48, the new inner radius.
local tickR = INNER / 2 * TICK_RADIUS
for _, bp in ipairs(BREAKPOINTS) do
  local angle = bp.f * 2 * math.pi
  for _, entry in ipairs({ { i = bp.dim, s = MARK_DIM }, { i = bp.lit, s = MARK_LIT } }) do
    local mark = energy.subRegions[entry.i]
    mark.xOffset = round(math.sin(angle) * tickR)
    mark.yOffset = round(math.cos(angle) * tickR)
    mark.width, mark.height = entry.s, entry.s   -- a square pip: a ring has no chord
    mark.anchor_mode, mark.anchor_point, mark.self_point = "point", "CENTER", "CENTER"
    mark.textureRotate, mark.textureRotation, mark.textureMirror = false, 0, false
  end
end

-- The rim that used to be the portrait becomes the portrait again, keeping the health
-- triggers it carried (so it fades with the cluster) and the out-of-combat fade condition.
local playerRimDonor = byId["Rogue - Life Globe Rim"]
local playerFace = replace("Rogue - Life Globe Rim", makePortrait(playerRimDonor, {
  id = "Rogue - Player Portrait", parent = PLAYER_GROUP, unit = "player",
  triggers = playerRimDonor.triggers, load = playerRimDonor.load,
  conditions = playerRimDonor.conditions,
}))

-- ===== TARGET CLUSTER: threat outside, target health inside, their face in the middle ==
local targetHealth = makeRing(rename("Rogue - Target Life Globe", "Rogue - Target Health Ring"), {
  size = INNER, color = COL_HEALTH, parent = TARGET_GROUP, pct = PCT_HP, dropHighlight = true,
})

local targetRimDonor = byId["Rogue - Target Globe Rim"]
local targetFace = replace("Rogue - Target Globe Rim", makePortrait(targetRimDonor, {
  id = "Rogue - Target Portrait", parent = TARGET_GROUP, unit = "target",
  triggers = targetRimDonor.triggers, load = targetRimDonor.load,
  conditions = targetRimDonor.conditions,
}))

-- Threat goes back to being an arc. Its escalations move off `color`, which only exists on a
-- texture region, and back onto `foregroundColor`.
local threatOld = byId["Rogue - Threat Rim"]
local threatConditions = W.deepcopy(threatOld.conditions)
for _, cond in ipairs(threatConditions) do
  for _, change in ipairs(cond.changes) do
    if change.property == "color" then change.property = "foregroundColor" end
  end
end
local threatText = W.deepcopy(threatOld.subRegions[1])
threatText.text_fontSize = PCT_THREAT.size
threatText.text_anchorPoint = "CENTER"
threatText.anchorXOffset, threatText.anchorYOffset = 0, PCT_THREAT.y

local threat = W.deepcopy(RING_PROTO)
threat.id, threat.uid = "Rogue - Threat Ring", threatOld.uid
threat.triggers = W.deepcopy(threatOld.triggers)
threat.load = W.deepcopy(threatOld.load)
threat.conditions = threatConditions
threat.subRegions = { threatText }
threat.animation = noAnimation()
threat.actions = { init = {}, start = {}, finish = {} }
threat.config, threat.authorOptions, threat.information = {}, {}, {}
makeRing(threat, { size = OUTER, color = COL_THREAT, parent = TARGET_GROUP,
                   pct = PCT_THREAT, dropHighlight = false })
replace("Rogue - Threat Rim", threat)

-- The target's outer TRACK. The old target power ring's uid, re-homed: the outer annulus is
-- unconditional so the two clusters still read as a pair when threat is not loaded.
local track = rename("Rogue - Energy Globe Rim", "Rogue - Target Ring Track")
track.parent = TARGET_GROUP
track.width, track.height = OUTER, OUTER
track.texture = RING_TEX
track.color = W.deepcopy(COL_TRACK)
track.blendMode, track.textureWrapMode = "BLEND", "CLAMPTOBLACKADDITIVE"
track.desaturate, track.mirror, track.rotate = false, false, false
track.rotation, track.discrete_rotation = 0, 0
track.xOffset, track.yOffset = 0, 0
track.frameStrata, track.alpha = 1, 1          -- listed first, so the threat ring draws over it
track.triggers = W.deepcopy(targetFace.triggers)   -- appears and vanishes with the target
track.conditions = {}                              -- its v50 conditions read a player trigger
track.subRegions = {}

-- The >= 80% halo keeps its trigger, gate, colour, ADD blend and alphaPulse; it just pulses
-- on the outer ring again. frameStrata 1 (with the ring) and LAST in the group, so it is not
-- buried under the arc it is warning about.
local flash = byId["Rogue - Threat Flash"]
flash.parent = TARGET_GROUP
flash.width, flash.height = OUTER, OUTER
flash.texture = RING_TEX
flash.xOffset, flash.yOffset = 0, 0
flash.frameStrata = 1

-- ===== rewire the tree =================================================================
-- Absolute positions, so the inherited chain is subtracted rather than assumed.
local inheritX, inheritY = T.d.xOffset + RES.xOffset, T.d.yOffset + RES.yOffset

local playerGroup = rename("Rogue - Player Globes", PLAYER_GROUP)
playerGroup.xOffset = -CLUSTER_X - inheritX
playerGroup.yOffset = CLUSTER_Y - inheritY
-- Sibling order is layering: FixGroupChildrenOrder adds +4 frame levels per child, so
-- EARLIER = further behind. The face goes last so nothing draws over it.
playerGroup.controlledChildren = { health.id, energy.id, playerFace.id }

local targetGroup = rename("Rogue - Target Globe", TARGET_GROUP)
targetGroup.xOffset = CLUSTER_X - inheritX
targetGroup.yOffset = TARGET_Y - inheritY
targetGroup.controlledChildren = { track.id, threat.id, targetHealth.id, flash.id, targetFace.id }

for i, id in ipairs(RES.controlledChildren) do
  if id == "Rogue - Player Globes" then RES.controlledChildren[i] = PLAYER_GROUP end
  if id == "Rogue - Target Globe" then RES.controlledChildren[i] = TARGET_GROUP end
end

-- ===== verify ==========================================================================
local encoded = W.encode(T)
W.verify(T, encoded)
local cont = W.uidContinuityStrings(encoded, src)
W.assertUidContinuity(cont, "rogue v51")
assert(cont.changed == 0 and cont.missing == 0, "rogue v51: a uid changed or was lost")
assert(cont.oldCount == cont.newCount,
  "rogue v51: this patch retypes and re-homes; no aura may be added or removed")
assert(cont.retained == cont.oldCount, "rogue v51: not every v50 uid survived")

local NEW = W.decode(encoded)
local newById = { [NEW.d.id] = NEW.d }
for _, aura in ipairs(NEW.c) do newById[aura.id] = aura end

-- AUDIT 1: absolute screen position, walked up the parent chain exactly as WeakAuras anchors
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

local PLACED = {
  [PLAYER_GROUP]              = { -CLUSTER_X, CLUSTER_Y },
  ["Rogue - Health Ring"]     = { -CLUSTER_X, CLUSTER_Y },
  ["Rogue - Energy Ring"]     = { -CLUSTER_X, CLUSTER_Y },
  ["Rogue - Player Portrait"] = { -CLUSTER_X, CLUSTER_Y },
  [TARGET_GROUP]                 = { CLUSTER_X, TARGET_Y },
  ["Rogue - Threat Ring"]        = { CLUSTER_X, TARGET_Y },
  ["Rogue - Target Health Ring"] = { CLUSTER_X, TARGET_Y },
  ["Rogue - Target Portrait"]    = { CLUSTER_X, TARGET_Y },
  ["Rogue - Target Ring Track"]  = { CLUSTER_X, TARGET_Y },
  ["Rogue - Threat Flash"]       = { CLUSTER_X, TARGET_Y },
}
for id, want in pairs(PLACED) do
  local x, y = absolute(id)
  assert(x == want[1] and y == want[2],
    ("%s lands at (%d,%d); the canonical cluster puts it at (%d,%d)")
      :format(id, x, y, want[1], want[2]))
end
-- and every cluster region really is concentric with its group
for id in pairs(PLACED) do
  local aura = newById[id]
  if aura.parent == PLAYER_GROUP or aura.parent == TARGET_GROUP then
    assert(aura.xOffset == 0 and aura.yOffset == 0, id .. " is not concentric in its cluster")
  end
end
-- 270 and not 190: both 84px outer rings clear the two vertically-growing columns.
do
  local px = select(1, absolute("Rogue - Health Ring"))
  assert(px + OUTER / 2 < -170,
    ("the player cluster reaches x=%.0f and overlaps the Alerts column"):format(px + OUTER / 2))
  local tx = select(1, absolute("Rogue - Threat Ring"))
  local pvpX, node = 0, assert(newById["Rogue - PvP"], "the PvP column is missing")
  while node do
    pvpX = pvpX + (node.xOffset or 0)
    node = node.parent and newById[node.parent]
  end
  local pvpEdge = pvpX + 36 / 2                           -- widest PvP icon is 36px
  assert(tx - OUTER / 2 > pvpEdge,
    ("the target cluster reaches x=%.0f and overlaps the PvP column at %.0f")
      :format(tx - OUTER / 2, pvpEdge))
end

-- AUDIT 2: the canonical geometry, read back out of the committed string.
local RINGS = {
  ["Rogue - Health Ring"]        = { size = OUTER, color = COL_HEALTH, pct = PCT_HP,    subs = 1 },
  ["Rogue - Energy Ring"]        = { size = INNER, color = COL_ENERGY, pct = PCT_POWER, subs = 5 },
  ["Rogue - Threat Ring"]        = { size = OUTER, color = COL_THREAT, pct = PCT_THREAT, subs = 1 },
  ["Rogue - Target Health Ring"] = { size = INNER, color = COL_HEALTH, pct = PCT_HP,    subs = 1 },
}
for id, want in pairs(RINGS) do
  local r = assert(newById[id], "ring missing: " .. id)
  assert(r.regionType == "progresstexture", id .. " is not a progresstexture")
  assert(r.width == want.size and r.height == want.size,
    ("%s is %sx%s, not the canonical %d"):format(id, tostring(r.width), tostring(r.height), want.size))
  assert(r.orientation == "CLOCKWISE", id .. " is not a radial ring")
  assert(r.startAngle == 0 and r.endAngle == 360, id .. " is not a full circle")
  assert(r.crop_x == 0.41 and r.crop_y == 0.41, id .. ": crop is not the circular identity value")
  assert(r.auraRotation == 0 and r.backgroundOffset == 0, id .. ": rotation/offset drifted")
  assert(r.foregroundTexture == RING_TEX and r.backgroundTexture == RING_TEX and r.sameTexture,
    id .. " is not drawn on the canonical ring art")
  assert(iseq(r.foregroundColor, want.color), id .. ": base colour is not the canonical one")
  assert(iseq(r.backgroundColor, COL_TRACK), id .. ": the track is not the canonical one")
  assert(#r.subRegions == want.subs,
    ("%s carries %d subregions, expected %d"):format(id, #r.subRegions, want.subs))
  local st = r.subRegions[1]
  assert(st.type == "subtext" and st.text_fontSize == want.pct.size
    and st.text_anchorPoint == "CENTER" and st.anchorXOffset == 0
    and st.anchorYOffset == want.pct.y, id .. ": the percentage is not where the spec puts it")
end
-- both clusters present the same outer diameter and the same face: the point of the pair
assert(newById["Rogue - Health Ring"].width == newById["Rogue - Threat Ring"].width
  and newById["Rogue - Health Ring"].width == newById["Rogue - Target Ring Track"].width,
  "the two clusters do not share an outer diameter")
assert(newById["Rogue - Energy Ring"].width == newById["Rogue - Target Health Ring"].width,
  "the two clusters do not share an inner diameter")
assert(newById["Rogue - Player Portrait"].width == PORTRAIT
  and newById["Rogue - Target Portrait"].width == PORTRAIT,
  "the two portraits are not the canonical size")
assert(newById["Rogue - Threat Flash"].width == OUTER
  and newById["Rogue - Threat Flash"].texture == RING_TEX,
  "the threat halo escapes the cluster's outer bound")
-- no target power ring was rebuilt
for _, aura in ipairs(NEW.c) do
  if aura.parent == TARGET_GROUP and aura.regionType == "progresstexture" then
    for _, wrapped in ipairs(aura.triggers or {}) do
      assert((wrapped.trigger or {}).event ~= "Power",
        aura.id .. ": a target power ring was rebuilt; the approved design is two rings and a face")
    end
  end
end

-- AUDIT 3: the portraits. Both model fields carry the unit, or the face is blank on 2.5.x.
for id, unit in pairs({ ["Rogue - Player Portrait"] = "player",
                        ["Rogue - Target Portrait"] = "target" }) do
  local p = assert(newById[id], "portrait missing: " .. id)
  assert(p.regionType == "model", id .. " is not a model region")
  assert(p.modelIsUnit == true, id .. ": modelIsUnit is not set, so it is not a live unit")
  assert(p.model_fileId == unit, id .. ": model_fileId is not the unit string")
  assert(p.model_path == unit, id .. ": model_path is not the unit string (3.5.0 fallback)")
  assert(p.portraitZoom == true, id .. ": portraitZoom is off, so it is not head-framed")
  assert(#p.subRegions == 0, id .. ": a model region cannot carry subregions")
  local old = oldById[id == "Rogue - Player Portrait" and "Rogue - Life Globe Rim"
    or "Rogue - Target Globe Rim"]
  assert(iseq(p.triggers, old.triggers), id .. ": the donor's triggers did not carry across")
  assert(iseq(p.load, old.load), id .. ": the donor's load gate did not carry across")
  assert(iseq(p.conditions, old.conditions), id .. ": the donor's conditions did not carry across")
  assert(p.uid == old.uid, id .. ": the donor's uid was not recycled")
end

-- AUDIT 4: every breakpoint mark lands ON the inner ring's stroke, at the angle its threshold
-- demands. Radius and angle are recovered FROM the committed offsets.
do
  local band = INNER * 20 / 256                 -- Ring_20px stroke at this diameter
  local outerR, innerR = INNER / 2, INNER / 2 - band
  assert(tickR <= outerR and tickR >= innerR,
    ("tick radius %.3f is outside the ring band %.3f..%.3f"):format(tickR, innerR, outerR))
  local en = newById["Rogue - Energy Ring"]
  for _, bp in ipairs(BREAKPOINTS) do
    for _, entry in ipairs({ { i = bp.dim, s = MARK_DIM }, { i = bp.lit, s = MARK_LIT } }) do
      local sub = en.subRegions[entry.i]
      local r = math.sqrt(sub.xOffset ^ 2 + sub.yOffset ^ 2)
      local fraction = math.atan2(sub.xOffset, sub.yOffset) / (2 * math.pi)
      if fraction < 0 then fraction = fraction + 1 end
      assert(math.abs(r - tickR) < 0.002,
        ("energy mark %d sits at radius %.3f, ring radius is %.3f"):format(entry.i, r, tickR))
      assert(math.abs(fraction - bp.f) < 0.0001,
        ("energy mark %d sits at %.4f of the ring, %d energy is %.2f")
          :format(entry.i, fraction, bp.threshold, bp.f))
      assert(sub.width == entry.s and sub.height == entry.s,
        ("energy mark %d is not a %dpx pip"):format(entry.i, entry.s))
      -- colours and visibility survive from v50, untouched
      local was = oldById["Rogue - Energy Globe"].subRegions[entry.i]
      assert(iseq(sub.textureColor, was.textureColor),
        ("energy mark %d changed colour"):format(entry.i))
      assert(sub.textureVisible == was.textureVisible and sub.textureTexture == was.textureTexture
        and sub.textureBlendMode == was.textureBlendMode,
        ("energy mark %d changed art or default visibility"):format(entry.i))
    end
  end
end

-- AUDIT 5: the specular highlight is gone from the whole pack, and no `sub.N` reference moved.
for _, aura in ipairs(NEW.c) do
  for i, sub in ipairs(aura.subRegions or {}) do
    assert(not (sub.type == "subtexture" and sub.textureTexture == FILL_TEX
      and sub.textureBlendMode == "ADD"),
      ("%s: subregion %d is a leftover v50 highlight"):format(aura.id, i))
  end
end
local SUB_REFS_AFTER = subReferences(NEW)
assert(#SUB_REFS_AFTER == #SUB_REFS_BEFORE, "a sub.N condition reference appeared or disappeared")
local RENAMED = {
  ["Rogue - Life Globe"] = "Rogue - Health Ring",
  ["Rogue - Energy Globe"] = "Rogue - Energy Ring",
  ["Rogue - Target Life Globe"] = "Rogue - Target Health Ring",
  ["Rogue - Life Globe Rim"] = "Rogue - Player Portrait",
  ["Rogue - Energy Globe Rim"] = "Rogue - Target Ring Track",
  ["Rogue - Target Globe Rim"] = "Rogue - Target Portrait",
  ["Rogue - Threat Rim"] = "Rogue - Threat Ring",
  ["Rogue - Player Globes"] = PLAYER_GROUP,
  ["Rogue - Target Globe"] = TARGET_GROUP,
}
for i, before in ipairs(SUB_REFS_BEFORE) do
  local after = SUB_REFS_AFTER[i]
  assert(after.id == (RENAMED[before.id] or before.id) and after.cond == before.cond
    and after.change == before.change and after.property == before.property
    and after.index == before.index,
    ("%s condition %d: the sub reference moved to %s"):format(before.id, before.cond,
      tostring(after and after.property)))
  local target = (newById[after.id].subRegions or {})[after.index]
  assert(target ~= nil, ("%s condition %d: %s now points at nothing")
    :format(after.id, after.cond, after.property))
  local was = (oldById[before.id].subRegions or {})[before.index]
  assert(target.type == was.type,
    ("%s condition %d: %s now drives a %s, not a %s")
      :format(after.id, after.cond, after.property, tostring(target.type), tostring(was.type)))
end

-- AUDIT 6: nothing outside the cluster changed, at all. Every aura is compared field by field
-- against v50; the Resources group may differ only in the two renamed controlledChildren.
local CLUSTER = {}
for old, new in pairs(RENAMED) do CLUSTER[old], CLUSTER[new] = true, true end
CLUSTER["Rogue - Threat Flash"] = true

assert(#OLD.c == #NEW.c, "the aura count changed")
assert(iseq(OLD.d, NEW.d), "the top-level group changed")
for index, old in ipairs(OLD.c) do
  local newId = RENAMED[old.id] or old.id
  local new = assert(newById[newId], "aura disappeared: " .. old.id)
  assert(NEW.c[index].id == newId, "aura order changed at " .. index)
  if not CLUSTER[old.id] then
    if old.id == RES_GROUP then
      for key in pairs(old) do
        if key ~= "controlledChildren" then
          assert(iseq(old[key], new[key]), RES_GROUP .. ": " .. key .. " changed")
        end
      end
      assert(#old.controlledChildren == #new.controlledChildren,
        RES_GROUP .. ": a child appeared or disappeared")
      for i, id in ipairs(old.controlledChildren) do
        assert(new.controlledChildren[i] == (RENAMED[id] or id),
          RES_GROUP .. ": controlledChildren order changed at " .. i)
      end
    else
      for key in pairs(old) do
        assert(iseq(old[key], new[key]),
          ("%s: %s changed, and v51 may only rebuild the unit cluster"):format(old.id, key))
      end
      for key in pairs(new) do assert(old[key] ~= nil, old.id .. ": gained field " .. key) end
    end
  end
end
-- and inside the cluster, the things a look pass may never touch
for old, new in pairs(RENAMED) do
  local a, b = oldById[old], newById[new]
  assert(iseq(a.triggers, b.triggers) or old == "Rogue - Energy Globe Rim",
    old .. ": triggers changed")
  assert(iseq(a.load, b.load), old .. ": load gate changed")
  assert(a.uid == b.uid, old .. ": uid changed")
end
do  -- the threat conditions survived the move back onto foregroundColor
  local a, b = oldById["Rogue - Threat Rim"], newById["Rogue - Threat Ring"]
  assert(#a.conditions == #b.conditions, "a threat condition was lost")
  for i, cond in ipairs(a.conditions) do
    assert(iseq(cond.check, b.conditions[i].check), "threat condition " .. i .. " check changed")
    for j, change in ipairs(cond.changes) do
      local after = b.conditions[i].changes[j]
      assert(iseq(change.value, after.value), "threat condition " .. i .. " value changed")
      assert(after.property == (change.property == "color" and "foregroundColor" or change.property),
        "threat condition " .. i .. " property did not move onto the progresstexture property")
    end
  end
  assert(b.conditions[3].check.variable == "threatvalue" and b.conditions[3].check.op == "<="
    and b.conditions[3].changes[1].property == "alpha" and b.conditions[3].changes[1].value == 0,
    "the mandatory zero-threat alpha guard is gone")
  for _, prop in ipairs({ "color" }) do
    for _, cond in ipairs(b.conditions) do
      for _, change in ipairs(cond.changes) do
        assert(change.property ~= prop,
          "a threat condition still drives `color`, which is a silent no-op on a progresstexture")
      end
    end
  end
end

local out = assert(io.open(PACK, "w")); out:write(encoded); out:close()
print(("audit ok: player cluster (%d,%d), target cluster (+%d,%d) — absolute, chain-walked")
  :format(-CLUSTER_X, CLUSTER_Y, CLUSTER_X, TARGET_Y))
print(("rings %d/%d, portrait %d; percentages %d/%d/%d at y %d/%d/+%d")
  :format(OUTER, INNER, PORTRAIT, PCT_HP.size, PCT_POWER.size, PCT_THREAT.size,
    PCT_HP.y, PCT_POWER.y, PCT_THREAT.y))
print(("breakpoints: %d marks back on the circumference at r=%.3f (%d -> %.3f,%.3f; %d -> %.3f,%.3f)")
  :format(#BREAKPOINTS * 2, tickR,
    BREAKPOINTS[1].threshold, newById["Rogue - Energy Ring"].subRegions[BREAKPOINTS[1].lit].xOffset,
    newById["Rogue - Energy Ring"].subRegions[BREAKPOINTS[1].lit].yOffset,
    BREAKPOINTS[2].threshold, newById["Rogue - Energy Ring"].subRegions[BREAKPOINTS[2].lit].xOffset,
    newById["Rogue - Energy Ring"].subRegions[BREAKPOINTS[2].lit].yOffset))
print(("uid continuity: stable=%d changed=%d retained=%d missing=%d parentSame=%s")
  :format(cont.stable, cont.changed, cont.retained, cont.missing, tostring(cont.parentSame)))
print(("wrote %s (%d auras, %d chars)"):format(PACK, #T.c + 1, #encoded))
