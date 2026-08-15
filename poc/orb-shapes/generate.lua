-- generate.lua — Orb SHAPE COMPARISON, a layout proof of concept (not a class pack).
-- Run: lua5.1 poc/orb-shapes/generate.lua  (works from any cwd; paths resolve from this file)
-- Produces orb-shapes.txt: a "!WA:2!" string importable in game (/wa -> Import -> paste).
--
-- WHAT THIS PROVES
-- Two compact clusters, one per unit, flanking the character: a small live portrait
-- with the health and mana readouts drawn as concentric RINGS AROUND it, plus the
-- percentage numbers underneath. The point is that unit state belongs AT the unit, so
-- the centre of the screen — the most expensive real estate on a HUD — is freed of the
-- health/mana/threat bar stack every pack in tbc/ currently parks there.
--
-- Player cluster on the LEFT, target cluster on the RIGHT, mirroring where the eye
-- already looks. The target cluster self-hides completely when there is no target.
--
-- WHY IT LIVES IN poc/ AND NOT tbc/
-- tools/verify-packs.lua and tools/verify-rebuild.sh discover packs from
-- tbc/*/all-specs.txt, so nothing here is picked up as a shipped pack. That is
-- deliberate: this is class-agnostic (no class load gate at all), it is one layout
-- experiment rather than a spec's rotation, and shipping it inside a class folder
-- would violate the one-string-per-class rule. Its seed is still registered against
-- the repo's seed discipline check (see the seed note below).
--
-- REGION TYPE
-- The rings are `progresstexture` regions in CLOCKWISE orientation. wa_factory.lua has
-- no progresstexture builder, so the ring and portrait tables below are written out in
-- full; every other piece (groups, trigger envelope, subtext, conditions, assembly)
-- goes through the factory. internalVersion stays 45, and no Modernize block at
-- IV >= 45 renames any progresstexture fill field, so what is emitted is what runs.
--
-- ZERO custom code. Zero name matching. Nothing here needs a media addon: Ring_10px.tga
-- ships inside WeakAuras itself, registered in Private.texture_types under "Shapes".

-- FIXED seed, and deliberately NOT one of the eight registered in the root README
-- (20260809-20260816). Two builds sharing a seed produce identical uids, and WeakAuras
-- matches auras across imports BY uid — a PoC that reused a pack's seed would import as
-- an "Update" over that pack and silently eat it. 20260890 is unallocated.
math.randomseed(20260891)

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
-- wa_factory.lua resolves wa_lib.lua and assets/icon_proto.lua from arg[0]'s directory,
-- so a bare relative dofile fails when the build script lives outside scripts/. Point
-- arg[0] at the factory for the duration of the load, then restore it.
local factoryPath = dir .. "/../../tools/tbc-weakaura-creator/scripts/wa_factory.lua"
local realArg0 = arg[0]
arg[0] = factoryPath
local F = dofile(factoryPath)
arg[0] = realArg0
local W = F.W

local IV, TOC = 45, 20501
local TOP = "Unit Orbs PoC"

-- Bundled WeakAuras media. Ring_10px/20px/30px/40px are true annuli (the number is the
-- stroke weight of the source art); Circle_Smooth2.tga — the texture the rest of this
-- repo uses — is a SOLID DISC and would fill as a pie wedge, not a ring.
local RING = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Ring_10px.tga"

-- ===== geometry =====================================================================
-- One place to retune after the first in-game look (see README "needs a tuning pass").
local G = {
  clusterY   = -100,  -- top group: the band the pack bar stack currently occupies
  clusterX   = 180,   -- player at -X, target at +X: clear of a 172px-wide centre stack
  hpRing     = 96,    -- OUTER ring, health. Bigger arc = the more-read number.
  mpRing     = 64,    -- INNER ring, mana.
  portrait   = 28,    -- the "small icon" in the middle
  hpTextY    = -60,   -- below the outer ring (radius 48), clear of it
  hpTextSize = 16,    -- large enough to read mid-fight
  mpTextY    = -80,
  mpTextSize = 11,
}

local COL = {
  health   = { 0.15, 0.82, 0.28, 1 },   -- green
  mana     = { 0.25, 0.50, 0.95, 1 },   -- blue
  track    = { 0, 0, 0, 0.55 },         -- the unfilled arc behind both
  hpText   = { 1, 1, 1, 1 },
  mpText   = { 0.55, 0.75, 1, 1 },      -- echoes the mana ring so the two numbers
}                                       -- never need labels to tell them apart

-- ===== scaffolding ==================================================================
local byId, order = {}, {}
local function reg(t)
  byId[t.id] = t
  order[#order + 1] = t.id
  return t
end
local function adopt(parent, child)
  child.parent = parent.id
  table.insert(parent.controlledChildren, child.id)
end

-- wa_factory's stub() is local to the factory, so the hand-written region tables below
-- get the identical scaffolding here.
local function stub(t)
  t.internalVersion, t.tocversion = IV, TOC
  t.actions = { init = {}, start = {}, finish = {} }
  t.animation = {
    start  = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
    main   = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
    finish = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
  }
  t.conditions = t.conditions or {}
  t.config, t.authorOptions, t.information = {}, {}, {}
  return t
end

-- Class-agnostic: an explicit "no gate" load table. F.load() always gates on a class,
-- which is exactly what this PoC must not do — it has to load for whoever imports it.
local function anyClass()
  return {
    use_class = false,
    class = { multi = {} }, size = { multi = {} },
    spec = { multi = {} }, talent = { multi = {} },
  }
end

-- ===== triggers =====================================================================
-- wa_factory's trigStub is local and its healthTrigger/powerTrigger are hardwired to
-- unit = "player"; these clusters need "target" too, so the two unit triggers are spelt
-- out with the same stub fields the factory applies.
local function unitTrigger(t)
  t.names, t.spellIds = {}, {}
  t.subeventPrefix, t.subeventSuffix = "SPELL", "_CAST_START"
  t.debuffType = "HELPFUL"
  return t
end

-- Health. The prototype ends in a hidden always-on test,
--   WeakAuras.UnitExistsFixed(unit, smart) and specificUnitCheck
-- ANDed into the trigger function, so unit = "target" with no target produces NO STATE
-- and the region hides. That is the whole self-hide mechanism for the target cluster —
-- no condition, no load gate, no custom code.
local function healthTrigger(unit)
  return unitTrigger{ type = "unit", event = "Health", unit = unit, use_unit = true }
end

-- Mana, and only mana. All three flags are load-bearing, and this is the same shape the
-- shipped warlock/mage/priest enemy-mana bars use:
--   use_powertype + powertype = 0  -> read MANA specifically. Drop either and powerType
--     is nil, and the trigger silently falls back to the unit's CURRENT bar — a rogue's
--     energy rendered in a ring coloured for mana.
--   use_requirePowerType          -> the ring only exists while mana is that unit's
--     PRIMARY bar, so a warrior or rogue target produces no state and the ring vanishes
--     instead of parking a permanently empty blue circle. Without it the non-retail init
--     does total = math.max(1, UnitPowerMax(unit, 0)), so a rageless unit yields a valid
--     0% state rather than no state. It is enabled by use_powertype, so both are needed.
local function manaTrigger(unit)
  return unitTrigger{
    type = "unit", event = "Power", unit = unit, use_unit = true,
    use_powertype = true, powertype = 0,
    use_requirePowerType = true,
  }
end

-- ===== regions ======================================================================
-- FOUR SHAPES, side by side, all reading the PLAYER so every one shows live data at
-- once and the comparison is honest. Pick one; the winner gets rolled into the packs.
--
-- The complaint that produced this file was that the shipped orb "looks like a wire".
-- That is a RATIO problem more than a shape problem: the shipped build puts a 28px
-- portrait inside an 88px Ring_10px ring, so ~70% of the circle is empty space and the
-- arc itself is a tenth as thick as the gap it encloses. Variants A and B fix the ratio
-- without changing the idea; C and D change the shape to the square the user asked about.
local MEDIA = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\"

local function ring(id, size, color, trigger, tex)
  return stub{
    regionType = "progresstexture", id = id, uid = W.uid(), parent = nil,
    width = size, height = size,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = 0, yOffset = 0, frameStrata = 1, alpha = 1,
    orientation = "CLOCKWISE", startAngle = 0, endAngle = 360,
    inverse = false, mirror = false,
    compress = false, slanted = false, slant = 0, slantFirst = false, slantMode = "INSIDE",
    foregroundTexture = tex, backgroundTexture = tex, sameTexture = true,
    desaturateForeground = false, desaturateBackground = false,
    foregroundColor = color, backgroundColor = COL.track,
    backgroundOffset = 0,
    blendMode = "BLEND", textureWrapMode = "CLAMPTOBLACKADDITIVE",
    crop_x = 0.41, crop_y = 0.41, rotation = 0, auraRotation = 0,
    user_x = 0, user_y = 0,
    progressSource = { -1, "" },
    useAdjustededMin = false, useAdjustededMax = false,
    adjustedMin = "", adjustedMax = "",
    smoothProgress = true, overlayclip = false, overlays = {},
    subRegions = {},
    triggers = F.triggers({ trigger }),
    load = anyClass(),
  }
end

local function portrait(id, unit, size)
  return stub{
    regionType = "model", id = id, uid = W.uid(), parent = nil,
    model_fileId = unit, model_path = unit, modelIsUnit = true, modelDisplayInfo = false,
    portraitZoom = true, api = false,
    model_x = 0, model_y = 0, model_z = 0,
    model_st_tx = 0, model_st_ty = 0, model_st_tz = 0,
    model_st_rx = 270, model_st_ry = 0, model_st_rz = 0, model_st_us = 40,
    sequence = 1, advance = false, rotation = 0,
    width = size, height = size, alpha = 1,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = 0, yOffset = 0, frameStrata = 1,
    border = false, borderColor = { 1, 1, 1, 0.5 }, backdropColor = { 1, 1, 1, 0.5 },
    borderEdge = "None", borderOffset = 5, borderInset = 11,
    borderSize = 16, borderBackdrop = "Blizzard Tooltip",
    subRegions = {},
    triggers = F.triggers({ healthTrigger(unit) }),
    load = anyClass(),
  }
end

-- A caption under each variant so the screenshot is self-describing.
local function caption(id, text, x)
  local t = F.texture(id, "ROGUE", 1, 1, x, -120, nil, MEDIA .. "Square_White.tga", { 0, 0, 0, 0 })
  t.load = anyClass()
  t.triggers = F.triggers({ healthTrigger("player") })
  local st = F.subtext(text, 12, "CENTER")
  st.anchorYOffset = 0
  t.subRegions = { st }
  return stub(t)
end

local top = F.group("Orb Shapes PoC", 0, -40, nil)
top.uid = W.uid()
top.load = anyClass()

local function place(child, x, y)
  child.xOffset, child.yOffset = x, y
  adopt(top, child)
end

-- ---- A: thick ring, portrait sized to fill it -------------------------------------
-- Ring_30px at 84px with a 52px portrait: the arc is ~3x thicker and the empty gap is
-- ~4x smaller than the shipped build. Same idea, corrected proportions.
local xA = -300
place(reg(ring("Shape A HP", 84, COL.hp, healthTrigger("player"), MEDIA .. "Ring_30px.tga")), xA, 0)
place(reg(ring("Shape A MP", 58, COL.mp, manaTrigger("player"), MEDIA .. "Ring_30px.tga")), xA, 0)
place(reg(portrait("Shape A Portrait", "player", 52)), xA, 0)
place(reg(caption("Shape A Caption", "A  thick ring", xA)), xA, 0)

-- ---- B: heaviest ring, no inner ring ----------------------------------------------
-- Ring_40px, health only, portrait 60px. Tests whether ONE bold arc reads better than
-- two thin concentric ones — mana moves to the number alone.
local xB = -100
place(reg(ring("Shape B HP", 88, COL.hp, healthTrigger("player"), MEDIA .. "Ring_40px.tga")), xB, 0)
place(reg(portrait("Shape B Portrait", "player", 60)), xB, 0)
place(reg(caption("Shape B Caption", "B  one bold arc", xB)), xB, 0)

-- ---- C: SQUARE radial sweep --------------------------------------------------------
-- The square the user asked about, still radial: a square texture in CLOCKWISE
-- orientation wipes like a Blizzard cooldown swipe. Reads as a normal WoW icon frame.
local xC = 100
place(reg(ring("Shape C HP", 74, COL.hp, healthTrigger("player"), MEDIA .. "Square_White_Border.tga")), xC, 0)
place(reg(ring("Shape C MP", 52, COL.mp, manaTrigger("player"), MEDIA .. "Square_White_Border.tga")), xC, 0)
place(reg(portrait("Shape C Portrait", "player", 44)), xC, 0)
place(reg(caption("Shape C Caption", "C  square sweep", xC)), xC, 0)

-- ---- D: SQUARE portrait with edge bars ---------------------------------------------
-- The most WoW-native option and the only one that is not radial at all: a square
-- portrait flanked by two slim vertical bars. Uses aurabar, which is field-proven in
-- every pack, with orientation VERTICAL_INVERSE — bottom-to-top, per gotchas.md, where
-- plain VERTICAL fills downward from the top.
local xD = 300
local function edgeBar(id, x, color, trigger)
  local b = F.aurabar(id, "ROGUE", 8, 56, x, 0, nil, color)
  b.orientation = "VERTICAL_INVERSE"
  b.load = anyClass()
  b.triggers = F.triggers({ trigger })
  b.subRegions = { { type = "aurabar_bar" }, F.subborder("bar") }
  return b
end
place(reg(edgeBar("Shape D HP", 0, COL.hp, healthTrigger("player"))), xD - 34, 0)
place(reg(portrait("Shape D Portrait", "player", 52)), xD, 0)
place(reg(edgeBar("Shape D MP", 0, COL.mp, manaTrigger("player"))), xD + 34, 0)
place(reg(caption("Shape D Caption", "D  square + edge bars", xD)), xD, 0)

-- ===== assemble =====================================================================
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

local OUT = dir .. "/orb-shapes.txt"
local cont = W.uidContinuity(encoded, OUT)
local out = io.open(OUT, "w"); out:write(encoded); out:close()
print(("OK: %d auras, %d chars -> orb-shapes.txt"):format(#transmit.c + 1, #encoded))
if cont then
  print(("uid continuity: stable=%d changed=%d"):format(cont.stable, cont.changed))
end
