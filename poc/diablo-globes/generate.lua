-- generate.lua — DIABLO-STYLE GLOBES, a layout proof of concept (not a class pack).
-- Run: lua5.1 poc/diablo-globes/generate.lua  (works from any cwd; paths resolve from this file)
-- Produces diablo-globes.txt: a "!WA:2!" string importable in game (/wa -> Import -> paste).
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
math.randomseed(20260892)

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
-- THE DIABLO GLOBE, and why it is a different animal from the ring HUD.
--
-- A D2 globe is not a radial sweep. It is a VESSEL that fills bottom-to-top like liquid:
-- the shape stays constant and the fill LINE rises. WeakAuras expresses that exactly, with
-- the same progresstexture region the rings use but a different orientation:
--
--   Private.orientation_with_circle_types = {
--     HORIZONTAL_INVERSE = "Left to Right",   HORIZONTAL = "Right to Left",
--     VERTICAL           = "Bottom to Top",   VERTICAL_INVERSE = "Top to Bottom",
--     CLOCKWISE = ..., ANTICLOCKWISE = ...,
--   }
--
-- so `orientation = "VERTICAL"` on a CIRCULAR texture is a round vessel that fills upward.
-- Note the name lies about the direction in the usual WA way (gotchas.md): VERTICAL fills
-- UP, VERTICAL_INVERSE fills DOWN. Getting this backwards gives a globe that drains from
-- the top as you take damage, which looks deliberate and is wrong.
--
-- The linear path also means the fields the circular path ignored now matter, and the ones
-- it needed no longer do:
--   * crop_x / crop_y stay 0.41 (the default). The sqrt(2) expansion that 0.41 cancels is
--     applied in the circular branch; on the linear path it is simply the texcoord scale.
--   * compress / slanted / slant / slantMode were inert on a ring. They are LIVE here.
--     slant is deliberately left off: a slanted fill line is a stylistic choice and a
--     straight waterline is what reads as liquid.
--   * startAngle / endAngle are ignored on the linear path.
local MEDIA = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\"
local GLOBE  = MEDIA .. "Circle_Smooth.tga"        -- the liquid itself: a filled disc
local FRAME  = MEDIA .. "Circle_Smooth_Border.tga" -- the glass rim drawn over it

local COLG = {
  life     = { 0.72, 0.09, 0.09, 1 },   -- D2 life red
  mana     = { 0.13, 0.30, 0.85, 1 },   -- D2 mana blue
  energy   = { 0.85, 0.75, 0.15, 1 },
  rage     = { 0.70, 0.12, 0.12, 1 },
  empty    = { 0.05, 0.05, 0.07, 0.85 },-- the unfilled vessel, nearly black
  rim      = { 0.62, 0.55, 0.40, 1 },   -- brassy rim
  text     = { 1, 1, 1, 1 },
}

-- The vessel. backgroundColor is the EMPTY portion, which is what sells the container
-- read: a nearly-black disc that a coloured liquid rises into. backgroundOffset 0 keeps
-- the empty part exactly the same disc as the full part rather than a halo around it.
local function globe(id, size, color, trigger)
  return stub{
    regionType = "progresstexture", id = id, uid = W.uid(), parent = nil,
    width = size, height = size,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = 0, yOffset = 0, frameStrata = 1, alpha = 1,
    orientation = "VERTICAL",            -- "Bottom to Top": the waterline rises
    startAngle = 0, endAngle = 360,      -- ignored on the linear path, emitted for the schema
    inverse = false, mirror = false,
    compress = false, slanted = false, slant = 0, slantFirst = false, slantMode = "INSIDE",
    foregroundTexture = GLOBE, backgroundTexture = GLOBE, sameTexture = true,
    desaturateForeground = false, desaturateBackground = false,
    foregroundColor = color, backgroundColor = COLG.empty,
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

-- The glass rim, drawn as a plain texture ON TOP of the vessel so the liquid appears to be
-- inside it. It carries the same trigger as its globe purely so the two appear and vanish
-- together; it has no progress of its own.
local function rim(id, size, trigger)
  local t = F.texture(id, "ROGUE", size, size, 0, 0, nil, FRAME, COLG.rim)
  t.load = anyClass()
  t.triggers = F.triggers({ trigger })
  t.frameStrata = 2                       -- above the fill
  return stub(t)
end

-- The number goes INSIDE the vessel, which is the whole advantage of dropping the portrait:
-- a progresstexture accepts a subtext (SubText's supports() lists progresstexture), a model
-- region never did — that is why the ring build had to park its numbers outside.
local function centreText(sym, size)
  local st = F.subtext("%" .. sym .. "%%", size, "CENTER", sym)
  st.anchorYOffset = 0
  st.text_color = COLG.text
  return st
end

local top = F.group("Diablo Globes PoC", 0, -150, nil)
top.uid = W.uid()
top.load = anyClass()

local function place(child, x, y)
  child.xOffset, child.yOffset = x, y
  adopt(top, child)
end

local SIZE = 116
local X    = 300

-- ---- LIFE, left ---------------------------------------------------------------------
local life = reg(globe("Globe Life", SIZE, COLG.life, healthTrigger("player")))
life.subRegions = { centreText("percenthealth", 18) }
-- The one escalation worth keeping from the bar era: the vessel itself goes brighter red
-- low. foregroundColor is the progresstexture property; barColor is aurabar-only and is a
-- silent no-op here (Conditions.lua skips unknown properties without warning).
life.conditions = {
  F.condition(1, "percenthealth", "<", "35", "foregroundColor", { 1, 0.15, 0.15, 1 }),
}
place(life, -X, 0)
place(reg(rim("Globe Life Rim", SIZE + 6, healthTrigger("player"))), -X, 0)

-- ---- MANA, right --------------------------------------------------------------------
-- Mana specifically, with use_requirePowerType, so on a rogue or warrior the globe does not
-- sit permanently empty — it vanishes, and the energy globe below is what they would use.
local mana = reg(globe("Globe Mana", SIZE, COLG.mana, manaTrigger("player")))
mana.subRegions = { centreText("percentpower", 18) }
place(mana, X, 0)
place(reg(rim("Globe Mana Rim", SIZE + 6, manaTrigger("player"))), X, 0)

-- ---- TARGET LIFE, a smaller vessel between them --------------------------------------
-- Diablo has no target globe; WoW needs one. Half size so it reads as secondary, and it
-- self-hides with no target because the Health trigger produces no state.
local tgt = reg(globe("Globe Target", 72, COLG.life, healthTrigger("target")))
tgt.subRegions = { centreText("percenthealth", 13) }
tgt.conditions = {
  F.condition(1, "percenthealth", "<", "20", "foregroundColor", { 1, 0.35, 0.1, 1 }),
}
place(tgt, 0, 34)
place(reg(rim("Globe Target Rim", 78, healthTrigger("target"))), 0, 34)

-- ===== assemble =====================================================================
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

local OUT = dir .. "/diablo-globes.txt"
local cont = W.uidContinuity(encoded, OUT)
local out = io.open(OUT, "w"); out:write(encoded); out:close()
print(("OK: %d auras, %d chars -> diablo-globes.txt"):format(#transmit.c + 1, #encoded))
if cont then print(("uid continuity: stable=%d changed=%d"):format(cont.stable, cont.changed)) end
