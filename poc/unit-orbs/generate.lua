-- generate.lua — Unit Orbs, a LAYOUT PROOF OF CONCEPT (not a class pack).
-- Run: lua5.1 poc/unit-orbs/generate.lua   (works from any cwd; paths resolve from this file)
-- Produces unit-orbs.txt: a "!WA:2!" string importable in game (/wa -> Import -> paste).
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
math.randomseed(20260890)

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
-- Radial progress ring. Field notes on the ones that are traps:
--   orientation CLOCKWISE  -> the only radial values are CLOCKWISE / ANTICLOCKWISE;
--     every other value in orientation_with_circle_types is linear, and the key names
--     lie about direction the same way aurabar's VERTICAL does (gotchas.md).
--   startAngle 0 / endAngle 360 -> full circle. WA normalises 0/360 -> 0/0 and then
--     corrects endAngle back up by 360, so a full ring is handled, not a degenerate case.
--   crop_x / crop_y = 0.41 -> the IDENTITY value, NOT "no crop". The circular path
--     expands the texture by sqrt(2) so rotated quadrants never run off it, and
--     crop = 1 + 0.41 exactly cancels that. Setting 0 blows the ring up 1.41x and clips it.
--   auraRotation = 0 -> absent from the 3.5.0 default table but read unconditionally by
--     current code as data.auraRotation / 180 * math.pi, so it must be emitted.
--   backgroundOffset = 0 -> the default 2 fattens the track relative to the fill, which
--     reads as a halo instead of a concentric track.
--   sameTexture = true -> backgroundTexture becomes dead code; both are set anyway.
--   adjustedMin/Max are STRINGS ("" ), because SetAdjustedMin does adjustedMin:find(...).
--   progressSource is rewritten to {-1, ""} by Modernize < 71 no matter what is emitted;
--     it is here for readability only. {-1,""} = Automatic, which is what routes the
--     Health/Power prototype's value/total into the fill with no further wiring.
--   compress / slanted / slant / slantFirst / slantMode are LINEAR-only and silently
--     inert on a circular ring; they are emitted because they are in the default table.
-- ONE TRIGGER PER RING: automatic progress reads a single trigger's state, so health and
-- mana cannot share a region. That constraint is what makes the concentric look possible.
local function ring(id, size, color, trigger)
  return stub{
    regionType = "progresstexture", id = id, uid = W.uid(), parent = nil,
    -- geometry
    width = size, height = size,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = 0, yOffset = 0, frameStrata = 1, alpha = 1,
    -- radial fill
    orientation = "CLOCKWISE", startAngle = 0, endAngle = 360,
    inverse = false, mirror = false,
    compress = false, slanted = false, slant = 0, slantFirst = false, slantMode = "INSIDE",
    -- textures
    foregroundTexture = RING, backgroundTexture = RING, sameTexture = true,
    desaturateForeground = false, desaturateBackground = false,
    foregroundColor = color, backgroundColor = COL.track,
    backgroundOffset = 0,
    blendMode = "BLEND", textureWrapMode = "CLAMPTOBLACKADDITIVE",
    crop_x = 0.41, crop_y = 0.41, rotation = 0, auraRotation = 0,
    user_x = 0, user_y = 0,
    -- progress plumbing
    progressSource = { -1, "" },
    useAdjustededMin = false, useAdjustededMax = false,
    adjustedMin = "", adjustedMax = "",
    smoothProgress = true, overlayclip = false, overlays = {},
    subRegions = {},
    triggers = F.triggers({ trigger }),
    load = anyClass(),
  }
end

-- Live unit portrait. This is a real 3D portrait of whoever is targeted, not a static
-- image and not a class icon, which is what makes the target side work without ever
-- knowing the target's class — it renders NPCs and mobs too.
--   modelIsUnit = true + model_fileId = "<unit>" -> PlayerModel:SetUnit(unit)
--   portraitZoom = true                          -> SetPortraitZoom(1), Blizzard head framing
-- CRITICAL: current code reads the unit from `model_fileId`. WA 3.5.0 read `model_path`,
-- and the migration that bridges the two (Modernize < 72) is guarded by
-- WeakAuras.IsClassicEra(), which is a DISTINCT predicate from IsTBC() — so on a 2.5.x
-- client that migration DOES NOT RUN and emitting only model_path is a silent no-op.
-- Both are emitted; model_fileId is the one that does the work.
-- The portrait carries the same Health trigger as its ring, so it self-hides with it.
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

-- The percentage numbers sit BELOW the cluster, not inside it: the middle is occupied by
-- the portrait, and a `model` region cannot carry a text subregion at all (SubText's
-- supports() gate lists texture / progresstexture / icon / aurabar / empty — not model).
-- So each number rides on its own ring, which also means it appears and disappears with
-- that ring: no target, no numbers; no mana pool, no mana number.
local function pct(sym, size, yOffset, color)
  local st = F.subtext("%" .. sym .. "%%", size, "CENTER", sym)
  st.anchorYOffset = yOffset
  st.text_color = color
  return st
end

-- ===== assembly =====================================================================
local top = F.group(TOP, 0, G.clusterY, nil)
top.uid = W.uid()

-- Sibling stacking is exact, not "roughly creation order": FixGroupChildrenOrder walks
-- controlledChildren and adds +4 frame levels per child, so EARLIER = further behind.
-- Outer ring first, inner ring second, portrait LAST so nothing draws over the face.
-- sharedFrameLevel is deliberately left off the cluster groups — it would set the
-- offset to 0 and make the overlap order ambiguous.
local function cluster(name, unit, x)
  local g = reg(F.group(name, x, 0, nil))
  adopt(top, g)

  local hp = reg(ring(name .. " Health", G.hpRing, COL.health, healthTrigger(unit)))
  hp.subRegions[1] = pct("percenthealth", G.hpTextSize, G.hpTextY, COL.hpText)
  adopt(g, hp)

  local mp = reg(ring(name .. " Mana", G.mpRing, COL.mana, manaTrigger(unit)))
  mp.subRegions[1] = pct("percentpower", G.mpTextSize, G.mpTextY, COL.mpText)
  -- Last honest gap in requirePowerType: most NPCs report mana as their primary bar with
  -- a 0/0 pool, and the prototype's total = math.max(1, UnitPowerMax(...)) floor turns
  -- that into a valid 0% state — an empty ring on a powerless mob. A real caster has
  -- maxpower in the thousands; a powerless unit has exactly 1, because of that floor.
  -- alpha is a region-prototype property, so it is valid on every region type.
  mp.conditions = { F.condition(1, "maxpower", "<=", "1", "alpha", 0) }
  adopt(g, mp)

  local pt = reg(portrait(name .. " Portrait", unit, G.portrait))
  adopt(g, pt)

  return g
end

cluster("Unit Orbs - Player", "player", -G.clusterX)
cluster("Unit Orbs - Target", "target",  G.clusterX)

-- ===== assemble (v2000 nested), encode, verify, write ===============================
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

-- uid continuity against the previous on-disk build, measured BEFORE the file is
-- overwritten, so a re-run is always checked against the string that was published.
local txtPath = dir .. "/unit-orbs.txt"
local cont = W.uidContinuity(encoded, txtPath)
W.assertUidContinuity(cont, "unit-orbs")

local out = assert(io.open(txtPath, "w"))
out:write(encoded)  -- single line, no trailing newline
out:close()

print(("OK: %d auras (top group + %d children), %d chars -> unit-orbs.txt")
  :format(#transmit.c + 1, #transmit.c, #encoded))
if cont then
  print(("uid continuity vs previous: stable=%d changed=%d parentSame=%s")
    :format(cont.stable, cont.changed, tostring(cont.parentSame)))
end
