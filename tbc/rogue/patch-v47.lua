-- rogue v46 -> v47: the centre bar stack becomes two unit orbs.
--
-- WHAT CHANGES. The 172x14 health / energy / threat aurabar stack that has sat in the
-- middle of the screen since v1 is replaced by two compact clusters flanking the character:
-- the PLAYER's own state on the LEFT, the TARGET's on the RIGHT, each a live 3D portrait
-- with its readouts drawn as concentric RINGS around it. The centre of the screen — the
-- most expensive real estate on a HUD — is left empty except for the combo pip row, which
-- is untouched. Nothing outside `Rogue - Resources` is touched at all.
--
-- UID DISCIPLINE, and why nothing is deleted. tools/verify-packs.lua runs
-- W.assertUidContinuity against the previously committed string, and that assert requires
-- `missing == 0`: EVERY uid that has ever shipped must still be present. Deleting the nine
-- auras of the old `Rogue - Bars` subtree would break it — and would also leave nine
-- orphans in the user's collection, because WeakAuras never removes an aura an import does
-- not mention. So all nine uids are RE-USED in place: five regions keep their id outright
-- (Health, Energy, Threat, Threat Flash), and four whose concept no longer exists as a
-- standalone aura (the Bars group and the three surviving threshold-line textures) hand
-- their uid to a new orb region. The re-import is therefore a clean Update with zero
-- orphans, and only ONE genuinely new uid is minted:
--
--   Rogue - Bars          nCsbdPR8)Fy -> Rogue - Player Orb      (group)
--   Rogue - Health        Cm9li7X9Nwe -> Rogue - Health          (ring, was aurabar)
--   Rogue - Energy        f0VjFZNwQ4w -> Rogue - Energy          (ring, was aurabar)
--   Rogue - Evis Line     QUQvBCxLAy7 -> Rogue - Player Portrait (model)
--   Rogue - SS Line       HucL3GUXR4L -> Rogue - Target Orb      (group)
--   Rogue - Threat        ZBDSLV89M1S -> Rogue - Threat          (ring, was aurabar)
--   Rogue - Threat Flash  wTa66)xnYLP -> Rogue - Threat Flash    (ring-shaped halo)
--   Rogue - Evis Line Lit XaXe7Ja77RQ -> Rogue - Target Health   (ring)
--   Rogue - SS Line Lit   MafcyRCWM9e -> Rogue - Target Power    (ring)
--   (new)                 RgOrbTgtFac -> Rogue - Target Portrait (model)
--
-- The new uid is a LITERAL, exactly as v46's five combo sockets are. This script is a
-- patch in a replay chain, so it must never draw from the W.uid() stream: a run through
-- generate.lua and a standalone run would then disagree about how much of the stream had
-- already been consumed. Every uid below is either carried over or spelled out.
--
-- THE FIVE TRAPS THIS MIGRATION HAD TO CLEAR, all source-verified:
--   1. `barColor` DOES NOT EXIST on progresstexture; the property is `foregroundColor`
--      (ProgressTexture.lua properties table). Conditions.lua:554 skips a condition whose
--      property is missing from the region's properties table — no error, no editor
--      warning — so a mechanically ported `barColor` is a dead escalation. Every colour
--      condition below uses foregroundColor.
--   2. total == 0 INVERTS between the two region types. AuraBar.lua:897 starts at
--      `progress = 0`, ProgressTexture.lua:615 starts at `progress = 1`. An aurabar with
--      total 0 draws EMPTY; a ring draws FULL. Threat hits total 0 whenever threatvalue is
--      0 (threattotal is derived from it) — i.e. right after a Vanish and in the instant
--      before the first hit lands. Every ring therefore carries an explicit zero-total
--      guard as its LAST condition (a later condition overwrites the same property).
--   3. Progress source is NOT selectable at internalVersion 45. Modernize IV<71 rewrites
--      `progressSource` to {-1, ""} (Automatic) on every progresstexture no matter what is
--      emitted, and Automatic reads the FIRST ACTIVE trigger. So each ring has exactly one
--      progress-supplying trigger and it is trigger 1; trigger 2, where present, exists
--      only to feed the out-of-combat fade condition.
--   4. The aurabar `subtick` sub-region CANNOT come along: Tick.lua:562 `supports()`
--      returns true only for "aurabar". The 35/40 energy threshold lines are rebuilt as
--      `subtexture` marks on the energy ring (Texture.lua:151 supports progresstexture),
--      positioned by trigonometry. Angle 0 is 12 o'clock and increases CLOCKWISE — proven
--      from TextureCoords.lua `exactAngles`, whose index 1 (0 deg) is {0.5, 0} = top
--      centre and index 3 (90 deg) is {1, 0.5} = right middle — which matches the ring's
--      orientation = "CLOCKWISE", startAngle = 0. Hence x = r*sin(t), y = r*cos(t).
--      `subcirculartexture` would give a prettier true arc wedge, but it first shipped in
--      December 2024 and is absent from every WeakAuras before 5.x, so a pack using it
--      silently loses its breakpoints on an older client. subtexture has existed for years.
--   5. The Threat Situation prototype's unit argument is named `unit`, NOT `threatUnit`.
--      wa_factory's F.threatTrigger emits `threatUnit`/`use_threatUnit`, which is dead
--      data that works only because the prototype's init() runs `trigger.unit =
--      trigger.unit or "target"` and mutates the trigger table before events() reads it.
--      Both threat regions here set `unit = "target"` explicitly.
--
-- Run: lua5.1 tbc/rogue/patch-v47.lua   (rewrites all-specs.txt in place)

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local SCRIPTS = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local PACK = dir .. "/all-specs.txt"
local savedArg = arg
arg = { [0] = SCRIPTS .. "/wa_factory.lua" }
local F = dofile(SCRIPTS .. "/wa_factory.lua")
arg = savedArg
local W = F.W

local CLASS = "ROGUE"
local IV, TOC = 45, 20501

-- Bundled WeakAuras media. Ring_10px.tga is a true annulus (10 = the stroke weight of the
-- source art); Circle_Smooth2.tga — F.TEX_CIRCLE, what the rest of this repo uses — is a
-- SOLID DISC and would fill as a pie wedge, not a ring. It ships inside WeakAuras itself,
-- registered in Private.texture_types under "Shapes", so no media addon is required.
local RING = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Ring_10px.tga"

-- ===== geometry ======================================================================
-- Offsets are relative to `Rogue - Resources`, which sits at (0, 56); orbY = -10 puts the
-- orb centres at absolute y = 46, the vertical middle of the band the bar stack vacated.
local G = {
  clusterX  = 300,   -- player at -X, target at +X.
                     -- The right flank is the binding constraint: the PvP column sits at
                     -- x = 200 with 36px icons (x 182..218) and the proc tracker grows
                     -- right from x = 110 (x 110..142). The widest thing on the target orb
                     -- is the 132px threat halo, half-width 66, so the cluster centre has
                     -- to clear 218 + 66 = 284. 300 leaves 16px of air and mirrors cleanly
                     -- on the left, where the Alerts column ends at x = -130.
  orbY      = -10,

  hpRing    = 96,    -- player: OUTER ring, health
  enRing    = 72,    -- player: INNER ring, energy. Wider than the paladin pack's mana ring
                     -- because it has to carry the two threshold marks legibly: at radius
                     -- 33.84 the 35% and 40% marks are 10.6px apart, which is more room
                     -- than the 172px bar gave them (8.6px).
  portrait  = 28,

  thRing    = 118,   -- target: OUTERMOST ring, your threat toward the pull threshold
  flashRing = 132,   -- target: the >=80% threat halo, just outside the threat ring
  tHpRing   = 90,    -- target: health
  tPwRing   = 62,    -- target: whatever bar that unit actually shows

  enTextY   = -62, enTextSize = 16,   -- the rogue's primary number, closest to the orb
  hpTextY   = -84, hpTextSize = 12,
  tHpTextY  = -74, tHpTextSize = 14,
  thTextY   = 70,  thTextSize = 11,   -- ABOVE the threat ring (radius 59); three numbers
                                      -- stacked under one orb is a queue, not a readout

  -- Distance from the ring centre to the stroke. Ring_10px draws its annulus at the outer
  -- edge of the region box (crop 0.41 is the identity crop, so the art exactly fills it),
  -- and 0.94 lands inside the stroke for every plausible source resolution of the tga.
  -- This is the one number in the file that may want an in-game tuning pass.
  tickRadius = 0.94,
  tickDim   = 5,     -- the v46 "2px dark line" equivalent
  tickLit   = 8,     -- the v46 "4px bright line" equivalent
}

-- Every colour is carried across byte-for-byte from the v46 bars, so the HUD still speaks
-- exactly the same language; only the shape changed.
local COL = {
  health  = { 0.15, 0.78, 0.25, 1 },   -- v46 health bar green
  energy  = { 1, 0.82, 0, 1 },         -- v46 energy bar yellow
  threat  = { 0.25, 0.80, 0.30, 1 },   -- v46 threat bar green
  flash   = { 1, 0.10, 0.10, 0.85 },   -- v46 threat flash red
  track   = { 0, 0, 0, 0.55 },         -- the unfilled arc behind every ring
  lowHp   = { 0.90, 0.12, 0.12, 1 },
  thHigh  = { 1, 0.60, 0.10, 1 },      -- v46 ">= 70% threat" orange, unchanged
  thAggro = { 0.90, 0.12, 0.12, 1 },   -- v46 "you hold aggro" red, unchanged
  evisDim = { 1, 0.15, 0.15, 0.55 },   -- v46 Evis Line
  evisLit = { 1, 0.15, 0.15, 1 },      -- v46 Evis Line Lit
  ssDim   = { 0.65, 0.30, 1, 0.55 },   -- v46 SS Line
  ssLit   = { 0.65, 0.30, 1, 1 },      -- v46 SS Line Lit
  mana    = { 0.25, 0.50, 0.95, 1 },   -- target power ring, by resolved power type
  rage    = { 0.90, 0.25, 0.20, 1 },
  focus   = { 1, 0.50, 0.25, 1 },
  hpText  = { 1, 1, 1, 1 },
  enText  = { 1, 0.90, 0.45, 1 },      -- each number echoes its own ring, so the two
  thText  = { 0.72, 0.95, 0.74, 1 },   -- under an orb never need labels
}

-- party/raid only, and never inside an arena. See the threat ring for the reasoning.
local IN_GROUP = { multi = { group = true, raid = true } }
local NOT_ARENA = { multi = {
  none = true, party = true, ten = true, twenty = true,
  twentyfive = true, fortyman = true, pvp = true,
} }

-- ===== helpers =======================================================================
local function iseq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not iseq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

local function round(v) return math.floor(v * 1000 + 0.5) / 1000 end

-- wa_factory's stub() is local to the factory, so the two hand-written region types below
-- get the identical scaffolding here.
local function orbStub(t)
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

-- Radial progress ring. Field notes on the ones that are traps:
--   orientation CLOCKWISE  -> the only radial values are CLOCKWISE / ANTICLOCKWISE; every
--     other entry in orientation_with_circle_types is linear and would draw a bar.
--   startAngle 0 / endAngle 360 -> a full circle. WA normalises 0/360 -> 0/0 and then
--     corrects endAngle back up by 360, so this is handled, not a degenerate case.
--   crop_x / crop_y = 0.41 -> the IDENTITY value, NOT "no crop". The circular path expands
--     the texture by sqrt(2) so rotated quadrants never run off it, and 1 + 0.41 exactly
--     cancels that. Setting 0 blows the ring up 1.41x and clips it.
--   auraRotation = 0 -> absent from the 3.5.0 default table but read unconditionally by
--     current code as data.auraRotation / 180 * math.pi, so it must be emitted.
--   backgroundOffset = 0 -> the default 2 fattens the track relative to the fill, which
--     reads as a halo instead of a concentric track.
--   adjustedMin/Max are STRINGS (""), because SetAdjustedMin does adjustedMin:find(...).
--   compress / slanted / slant / slantFirst / slantMode are LINEAR-only and inert on a
--     circular ring; they are emitted because they are in the region's default table.
local function ring(id, uid, size, color, trigs)
  return orbStub{
    regionType = "progresstexture", id = id, uid = uid, parent = nil,
    width = size, height = size,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = 0, yOffset = 0, frameStrata = 1, alpha = 1,
    orientation = "CLOCKWISE", startAngle = 0, endAngle = 360,
    inverse = false, mirror = false,
    compress = false, slanted = false, slant = 0, slantFirst = false, slantMode = "INSIDE",
    foregroundTexture = RING, backgroundTexture = RING, sameTexture = true,
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
    triggers = F.triggers(trigs),
    load = F.load(CLASS),
  }
end

-- Live unit portrait — a real 3D portrait of whoever is targeted, not a static image and
-- not a class icon, which is what lets the target orb work without ever knowing the
-- target's class: it renders NPCs and mobs too.
--   modelIsUnit = true + model_fileId = "<unit>" -> PlayerModel:SetUnit(unit)
--   portraitZoom = true                          -> SetPortraitZoom(1), Blizzard framing
-- CRITICAL: current code reads the unit from `model_fileId`. WA 3.5.0 read `model_path`,
-- and the migration bridging the two (Modernize < 72) is guarded by IsClassicEra(), which
-- is a DISTINCT predicate from IsTBC() — so on a 2.5.x client that migration DOES NOT RUN
-- and emitting only model_path is a silent no-op. Both are emitted; model_fileId works.
-- The portrait carries the same Health trigger as its own orb, so it self-hides with it.
local function portrait(id, uid, unit, size, trigs)
  return orbStub{
    regionType = "model", id = id, uid = uid, parent = nil,
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
    triggers = F.triggers(trigs),
    load = F.load(CLASS),
  }
end

-- The percentages sit OUTSIDE the rings: the middle is occupied by the portrait, and a
-- `model` region cannot carry a text sub-region at all (SubText's supports() gate lists
-- texture / progresstexture / icon / aurabar / empty — not model). So each number rides on
-- its own ring, which also means it appears and disappears with that ring: no target, no
-- numbers; no threat table, no threat number.
local function pct(fmt, sym, size, yOffset, color)
  local st = F.subtext(fmt, size, "CENTER", sym)
  st.anchorYOffset = yOffset
  st.text_color = color
  return st
end

-- A static breakpoint mark on a ring. `pct` is the fraction of the ring, 0..1.
--   textureRotate is the GATE for textureRotation (SubTexture.modify passes it through as
--   canRotate, and DoTexCoord only rotates when canRotate is set) — irrelevant here only
--   because Square_White is a solid square with no orientation, so both are left off.
--   Swap in directional art and textureRotate = true becomes mandatory.
--   xOffset / yOffset are NOT in the subtexture default() table but ARE read by
--   modify -> AnchorSubRegion in "point" mode; omit them and every mark stacks at centre.
local function mark(fraction, radius, size, color, visible)
  local angle = fraction * 2 * math.pi
  return {
    type = "subtexture",
    textureVisible = visible,
    textureTexture = F.TEX_SQUARE,
    textureDesaturate = false,
    textureColor = color,
    textureBlendMode = "BLEND",
    textureMirror = false,
    textureRotate = false,
    textureRotation = 0,
    anchor_mode = "point", anchor_point = "CENTER", self_point = "CENTER",
    width = size, height = size, scale = 1, mirror = false, rotate = false,
    xOffset = round(math.sin(angle) * radius),
    yOffset = round(math.cos(angle) * radius),
  }
end

local function addSub(region, sub)
  region.subRegions[#region.subRegions + 1] = sub
  return #region.subRegions
end

-- The Threat Situation prototype's argument is `unit` (Prototypes.lua:9396, required,
-- default "target"). F.threatTrigger emits threatUnit/use_threatUnit, which the prototype
-- never reads; it is inert, so it is left alone rather than churned, and the real name is
-- set alongside it.
local function threatTrigger(minPct)
  local tr = F.threatTrigger(minPct)
  tr.unit = "target"
  return tr
end

local function unitHealthTrigger(unit)
  local tr = F.healthTrigger()
  tr.unit = unit
  return tr
end

-- ADAPTIVE power: no use_powertype at all, so the prototype compiles
-- `local powerType = nil; local powerTypeToCheck = powerType or UnitPowerType(unit)` and
-- the ring reads whatever bar that unit actually displays — mana on a healer, rage on a
-- warrior, energy on another rogue. `requirePowerType` is gated on use_powertype and is
-- therefore inert here, so a powerless mob (total floored to 1) is caught by the
-- maxpower <= 1 guard instead.
local function adaptivePowerTrigger(unit)
  local tr = F.powerTrigger(0)
  tr.unit = unit
  tr.use_powertype, tr.powertype = nil, nil
  return tr
end

local function inGroupNotArena(aura)
  aura.load.use_ingroup = true
  aura.load.ingroup = W.deepcopy(IN_GROUP)
  aura.load.use_size = false   -- false selects MULTI mode; only nil disables the gate
  aura.load.size = W.deepcopy(NOT_ARENA)
end

-- ===== read the v46 build ============================================================
local f = assert(io.open(PACK, "r")); local src = f:read("*a"); f:close()
local T = W.decode(src)
local OLD = W.decode(src)

local byId = {}
for _, aura in ipairs(T.c) do byId[aura.id] = aura end

local resources = assert(byId["Rogue - Resources"], "Rogue - Resources missing")
local barsGroup = assert(byId["Rogue - Bars"], "Rogue - Bars missing")

-- The nine auras the v46 bar stack was made of, and the uid each one hands forward.
local RETIRED = {
  "Rogue - Bars", "Rogue - Health", "Rogue - Energy", "Rogue - Threat",
  "Rogue - Threat Flash", "Rogue - Evis Line", "Rogue - SS Line",
  "Rogue - Evis Line Lit", "Rogue - SS Line Lit",
}
local uidOf = {}
for _, id in ipairs(RETIRED) do
  local aura = assert(byId[id], "expected v46 aura missing: " .. id)
  assert(aura.parent == (id == "Rogue - Bars" and "Rogue - Resources" or "Rogue - Bars"),
    id .. ": unexpected parent " .. tostring(aura.parent))
  uidOf[id] = aura.uid
  byId[id] = nil
end

-- Sanity-check the two things this migration claims to carry across, against the actual
-- v46 data rather than against the README.
do
  local function find(id)
    for _, aura in ipairs(OLD.c) do if aura.id == id then return aura end end
  end
  local energy = find("Rogue - Energy")
  assert(energy.triggers[1].trigger.powertype == 3, "v46 energy bar is not powertype 3")
  assert(iseq(energy.barColor, COL.energy), "v46 energy bar colour drifted")
  local threat = find("Rogue - Threat")
  assert(#threat.conditions == 2
     and threat.conditions[1].check.variable == "threatpct"
     and threat.conditions[2].check.variable == "aggro",
    "v46 threat bar no longer carries the 70%/aggro escalation")
  assert(find("Rogue - Evis Line Lit").triggers[1].trigger.power == "35"
     and find("Rogue - SS Line Lit").triggers[1].trigger.power == "40",
    "v46 threshold lines are not at 35/40")
end

-- ===== build the two clusters ========================================================
-- Separate groups so each orb can be dragged on its own, and so a player who wants only
-- one of them can disable a single group. Cloned from the retired Bars group so they keep
-- the pack's own group idiom (trigger shape, load table, borders) exactly.
local function clusterGroup(id, uid, x)
  local g = W.deepcopy(barsGroup)
  g.id, g.uid, g.parent = id, uid, "Rogue - Resources"
  g.xOffset, g.yOffset = x, G.orbY
  g.controlledChildren = {}
  return g
end

local gPlayer = clusterGroup("Rogue - Player Orb", uidOf["Rogue - Bars"], -G.clusterX)
local gTarget = clusterGroup("Rogue - Target Orb", uidOf["Rogue - SS Line"], G.clusterX)

-- --- player orb ----------------------------------------------------------------------
-- PLAYER HEALTH — the outer ring. Was the 172x14 health aurabar; same id, same uid, so it
-- updates in place. Trigger 2 is the existing Unit Characteristics state feeder and drives
-- the out-of-combat fade ONLY; the fill comes from trigger 1, because Automatic progress
-- reads the first active trigger.
-- v47 adds the low-health tier the bar never had: at ring scale colour does far more work
-- than arc length, and "I am about to die" is the one state a 48px radius must shout. The
-- Evasion prompt already fires at 50%; 30% is the tier below it.
local hp = ring("Rogue - Health", uidOf["Rogue - Health"], G.hpRing, COL.health,
  { unitHealthTrigger("player"), F.unitCharTrigger() })
addSub(hp, pct("%percenthealth%%", "percenthealth", G.hpTextSize, G.hpTextY, COL.hpText))
hp.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "percenthealth", "<", "30", "foregroundColor", COL.lowHp),
  -- LAST: the Health prototype's total is UnitHealthMax(unit) with NO floor, so a unit
  -- whose max health has not streamed yet gives total == 0 — and a ring draws total == 0
  -- as FULL, the exact inverse of what the aurabar did. Hide rather than lie. It must come
  -- after the fade, because a later condition overwrites the same property.
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

-- PLAYER ENERGY — the inner ring, and the rogue's rotation clock. The two threshold marks
-- are the v46 Evis/SS lines rebuilt as subtexture marks: a permanent dim mark that says
-- where the breakpoint is, plus a larger bright mark that only becomes visible once the
-- energy is actually there. That is the same dark-line/lit-line pair v41 shipped, with the
-- lit layer switched by a condition on `textureVisible` instead of by its own aura.
local en = ring("Rogue - Energy", uidOf["Rogue - Energy"], G.enRing, COL.energy,
  { F.powerTrigger(3), F.unitCharTrigger() })
addSub(en, pct("%p", nil, G.enTextSize, G.enTextY, COL.enText))
local tickR = G.enRing / 2 * G.tickRadius
addSub(en, mark(0.35, tickR, G.tickDim, COL.evisDim, true))   -- Eviscerate, 35 energy
addSub(en, mark(0.40, tickR, G.tickDim, COL.ssDim,   true))   -- Sinister Strike, 40 energy
local evisLit = addSub(en, mark(0.35, tickR, G.tickLit, COL.evisLit, false))
local ssLit   = addSub(en, mark(0.40, tickR, G.tickLit, COL.ssLit,   false))
en.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "power", ">=", "35", "sub." .. evisLit .. ".textureVisible", true),
  F.condition(1, "power", ">=", "40", "sub." .. ssLit   .. ".textureVisible", true),
  -- Energy is floored at 100 on every rogue, so this can never fire; it is here because
  -- every ring gets the zero-total guard for its own trigger. The Power prototype floors
  -- total at math.max(1, UnitPowerMax(...)), which is why it reads <= 1 and not <= 0.
  F.condition(1, "maxpower", "<=", "1", "alpha", 0),
}

-- The face. It carries the same fade as the rings it sits inside, so the whole cluster
-- dims together out of combat instead of leaving a lit portrait in a dimmed orb.
local pFace = portrait("Rogue - Player Portrait", uidOf["Rogue - Evis Line"], "player",
  G.portrait, { unitHealthTrigger("player"), F.unitCharTrigger() })
pFace.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }

-- --- target orb ----------------------------------------------------------------------
-- THREAT — now the OUTERMOST ring of the TARGET orb, because your threat is threat on that
-- target. The Threat Situation prototype is progressType "static" with hidden value/total
-- args and threattotal = threatvalue * 100 / threatpct, so value/total is exactly
-- threatpct/100 and the ring fills 0..100% of the pull threshold.
-- v47 finally adds the party/raid + not-arena gate the pack README has flagged as missing
-- since v3: solo you are always the aggro target, so ungated this sat pinned red on every
-- quest mob, and an arena team has no threat table at all.
local th = ring("Rogue - Threat", uidOf["Rogue - Threat"], G.thRing, COL.threat,
  { threatTrigger() })
addSub(th, pct("%threatpct%%", "threatpct", G.thTextSize, G.thTextY, COL.thText))
th.conditions = {   -- severe last: a later match overwrites the same property
  F.condition(1, "threatpct", ">=", "70", "foregroundColor", COL.thHigh),
  F.condition(1, "aggro", "==", 1, "foregroundColor", COL.thAggro),
  -- THE MIGRATION'S WORST TRAP, guarded. threattotal is threatvalue-derived, so it is 0
  -- whenever threatvalue is 0 — the instant before the first hit lands, and every second
  -- after a Vanish. The v46 aurabar drew that as EMPTY; a ring draws it as FULL, i.e. "you
  -- are at the pull threshold", while these colour conditions stay green because threatpct
  -- is 0. Shape and colour would contradict each other at the worst possible moment.
  -- `threatvalue` is a stored number arg; the hidden `total` is not.
  F.condition(1, "threatvalue", "<=", "0", "alpha", 0),
}
inGroupNotArena(th)

-- >=80% threat HALO. Was a 176x18 red rectangle pulsing over the threat bar; it is now the
-- same Ring_10px art at 132px pulsing just outside the threat ring, so the alarm still
-- lands exactly on top of the thing it is about. Same trigger, same threshold, same
-- pulse, same uid — only the shape and the arena gate changed.
local flash = F.texture("Rogue - Threat Flash", CLASS, G.flashRing, G.flashRing, 0, 0,
  nil, RING, COL.flash)
flash.uid = uidOf["Rogue - Threat Flash"]
flash.blendMode = "ADD"
flash.triggers = F.triggers({ threatTrigger(80) })
flash.animation.main = F.animPreset("alphaPulse", "1")   -- duration required or invisible
inGroupNotArena(flash)

-- TARGET HEALTH. The self-hide needs no condition and no load gate: the Health prototype
-- ANDs in `WeakAuras.UnitExistsFixed(unit, smart)`, so unit = "target" with no target
-- produces NO STATE and the whole cluster vanishes. Red under 20% is the "stop building,
-- spend what you have" line — a rogue has no execute, so the decision it changes is
-- finisher timing, not a new button.
local tHp = ring("Rogue - Target Health", uidOf["Rogue - Evis Line Lit"], G.tHpRing,
  COL.health, { unitHealthTrigger("target") })
addSub(tHp, pct("%percenthealth%%", "percenthealth", G.tHpTextSize, G.tHpTextY, COL.hpText))
tHp.conditions = {
  F.condition(1, "percenthealth", "<", "20", "foregroundColor", COL.lowHp),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),   -- see the player ring's note
}

-- TARGET POWER. Adaptive, so it reads whatever bar the unit actually shows, and colours
-- itself from the RESOLVED type (`powertype` is a stored, conditionable select arg whose
-- init is powerTypeToCheck, so it reports what was really read, not what was asked for).
-- This is the readout a rogue can act on: an arena healer's mana is the match clock, and
-- an enemy rogue's or warrior's bar tells you whether a stun is coming. It carries no
-- number on purpose — three numbers stacked under one orb is a queue, not a readout.
local tPw = ring("Rogue - Target Power", uidOf["Rogue - SS Line Lit"], G.tPwRing,
  COL.mana, { adaptivePowerTrigger("target") })
tPw.conditions = {
  F.condition(1, "powertype", "==", 1, "foregroundColor", COL.rage),
  F.condition(1, "powertype", "==", 2, "foregroundColor", COL.focus),
  F.condition(1, "powertype", "==", 3, "foregroundColor", COL.energy),
  -- LAST, and the one that keeps this ring honest in PvE: most powerless NPCs report mana
  -- as their primary bar with a 0/0 pool, and the prototype's math.max(1, UnitPowerMax())
  -- floor turns that into a valid 0% state. maxpower is exactly 1 for those units and in
  -- the thousands for a real caster, so this hides the ring instead of parking a permanent
  -- empty circle on every trash mob.
  F.condition(1, "maxpower", "<=", "1", "alpha", 0),
}

local tFace = portrait("Rogue - Target Portrait", "RgOrbTgtFac", "target", G.portrait,
  { unitHealthTrigger("target") })

-- ===== splice ========================================================================
-- Sibling stacking inside a group is exact, not "roughly creation order":
-- FixGroupChildrenOrder walks controlledChildren and adds +4 frame levels per child, so
-- EARLIER = FURTHER BEHIND. Halo first, then outer to inner, portrait LAST so nothing ever
-- draws over the face.
local function adopt(parent, child)
  child.parent = parent.id
  parent.controlledChildren[#parent.controlledChildren + 1] = child.id
  byId[child.id] = child
end

adopt(gPlayer, hp)
adopt(gPlayer, en)
adopt(gPlayer, pFace)

adopt(gTarget, flash)
adopt(gTarget, th)
adopt(gTarget, tHp)
adopt(gTarget, tPw)
adopt(gTarget, tFace)

byId[gPlayer.id], byId[gTarget.id] = gPlayer, gTarget

-- Replace the single "Rogue - Bars" entry with the two clusters, leaving the ten combo
-- sockets/pips ahead of it exactly where they are.
local children = {}
for _, cid in ipairs(resources.controlledChildren) do
  if cid == "Rogue - Bars" then
    children[#children + 1] = gPlayer.id
    children[#children + 1] = gTarget.id
  else
    children[#children + 1] = cid
  end
end
resources.controlledChildren = children

-- v2000 transmit order is depth-first through controlledChildren; rebuild it from the tree
-- rather than patching the flat list, so the two new subtrees can never land out of order.
local flat = {}
local function walk(node)
  for _, cid in ipairs(node.controlledChildren or {}) do
    local child = assert(byId[cid], "controlledChildren references missing id: " .. cid)
    flat[#flat + 1] = child
    if child.controlledChildren then walk(child) end
  end
end
walk(T.d)
assert(#flat == #T.c + 1, ("child count %d, expected %d"):format(#flat, #T.c + 1))
T.c = flat

-- ===== verify ========================================================================
local encoded = W.encode(T)
W.verify(T, encoded)
local cont = W.uidContinuityStrings(encoded, src)
W.assertUidContinuity(cont, "rogue v47")

-- Audit: nothing outside the retired bar subtree may differ, and the Resources group may
-- differ only in controlledChildren.
local retired = {}
for _, id in ipairs(RETIRED) do retired[id] = true end
local newById = {}
for _, aura in ipairs(W.decode(encoded).c) do newById[aura.id] = aura end

for _, old in ipairs(OLD.c) do
  if old.id == "Rogue - Resources" then
    local new = assert(newById[old.id])
    for key in pairs(old) do
      if key ~= "controlledChildren" then
        assert(iseq(old[key], new[key]), old.id .. ": unexpected change in " .. key)
      end
    end
    assert(#new.controlledChildren == #old.controlledChildren + 1,
      "Resources group did not swap one bar group for two orb groups")
  elseif not retired[old.id] then
    assert(iseq(old, newById[old.id]), "unexpected v47 change outside the orbs: " .. old.id)
  end
end

-- Every retired uid landed on exactly the region this script says it did, and the one new
-- uid is the literal, not a draw from the seeded stream.
local EXPECT = {
  ["Rogue - Player Orb"]      = uidOf["Rogue - Bars"],
  ["Rogue - Health"]          = uidOf["Rogue - Health"],
  ["Rogue - Energy"]          = uidOf["Rogue - Energy"],
  ["Rogue - Player Portrait"] = uidOf["Rogue - Evis Line"],
  ["Rogue - Target Orb"]      = uidOf["Rogue - SS Line"],
  ["Rogue - Threat"]          = uidOf["Rogue - Threat"],
  ["Rogue - Threat Flash"]    = uidOf["Rogue - Threat Flash"],
  ["Rogue - Target Health"]   = uidOf["Rogue - Evis Line Lit"],
  ["Rogue - Target Power"]    = uidOf["Rogue - SS Line Lit"],
  ["Rogue - Target Portrait"] = "RgOrbTgtFac",
}
for id, uid in pairs(EXPECT) do
  local aura = assert(newById[id], "orb region missing: " .. id)
  assert(aura.uid == uid, id .. ": uid is " .. tostring(aura.uid) .. ", expected " .. uid)
end
for _, id in ipairs({ "Rogue - Evis Line", "Rogue - SS Line",
                      "Rogue - Evis Line Lit", "Rogue - SS Line Lit", "Rogue - Bars" }) do
  assert(newById[id] == nil, id .. " should no longer exist as an aura")
end

-- No `barColor` may survive on a ring: it is not a progresstexture property and would be a
-- silently dead condition.
for _, id in ipairs({ "Rogue - Health", "Rogue - Energy", "Rogue - Threat",
                      "Rogue - Target Health", "Rogue - Target Power" }) do
  local aura = newById[id]
  assert(aura.regionType == "progresstexture", id .. " is not a ring")
  assert(aura.barColor == nil, id .. " still carries barColor")
  for _, condition in ipairs(aura.conditions) do
    assert(condition.changes[1].property ~= "barColor", id .. ": dead barColor condition")
  end
  local last = aura.conditions[#aura.conditions]
  assert(last.changes[1].property == "alpha" and last.changes[1].value == 0,
    id .. ": zero-total guard is not the last condition")
end

local out = assert(io.open(PACK, "w")); out:write(encoded); out:close()
print("audit ok: bar stack -> two unit orbs, 9 uids carried, 1 new literal uid")
print(("uid continuity: stable=%d changed=%d retained=%d missing=%d parentSame=%s")
  :format(cont.stable, cont.changed, cont.retained, cont.missing, tostring(cont.parentSame)))
print(("wrote %s (%d auras, %d chars)"):format(PACK, #T.c + 1, #encoded))
