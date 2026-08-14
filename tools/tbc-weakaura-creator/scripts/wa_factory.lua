-- wa_factory.lua — verified builders for TBC-Anniversary WeakAuras packs.
-- Every field name here was checked against the WeakAuras 3.5.0 source
-- (the TBC-era release, internalVersion 45). Modern WA migrates 45 -> current
-- on import via Modernize, which is the battle-tested path every old wago
-- string takes. Do not bump internalVersion.

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local W = dofile(dir .. "/wa_lib.lua")

local F = { W = W }

local IV, TOC = 45, 20501
local ICON_PROTO = dofile(dir .. "/../assets/icon_proto.lua")

-- Standard per-class load gate. class token: "ROGUE","PALADIN","WARRIOR", etc.
function F.load(class, extra)
  local l = {
    use_class = true,
    class = { single = class, multi = { [class] = true } },
    size = { multi = {} }, spec = { multi = {} }, talent = { multi = {} },
  }
  for k, v in pairs(extra or {}) do l[k] = v end
  -- useful extras: use_combat=true | use_spellknown=true, spellknown=<id>
  --                use_ingroup=true, ingroup={multi={group=true,raid=true}}
  return l
end

local function stub(t)
  t.internalVersion, t.tocversion = IV, TOC
  t.actions = t.actions or { init = {}, start = {}, finish = {} }
  t.animation = t.animation or {
    start  = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
    main   = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
    finish = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
  }
  t.conditions = t.conditions or {}
  t.config = t.config or {}; t.authorOptions = t.authorOptions or {}; t.information = t.information or {}
  return t
end

-- ================= TRIGGERS =================
local function trigStub(tr)
  tr.names = {}; tr.spellIds = {}
  tr.subeventPrefix = "SPELL"; tr.subeventSuffix = "_CAST_START"
  tr.debuffType = tr.debuffType or "HELPFUL"
  return tr
end

function F.triggers(list, opts)
  local t = { activeTriggerMode = -10, disjunctive = "all" }
  for i, tr in ipairs(list) do t[i] = { trigger = tr, untrigger = {} } end
  for k, v in pairs(opts or {}) do t[k] = v end
  -- opts: disjunctive="any"|"custom", customTriggerLogic="function(t) ... end"
  return t
end

-- Buff/debuff by EXACT spell IDs (locale-proof: never match by name).
-- Pass ALL rank ids (classic aura ids differ per rank; some names embed rank).
-- opts: ownOnly=true | matchesShowOn="showOnMissing" | showClones=true
function F.auraTrigger(unit, helpful, ids, opts)
  local spellids = {}
  for i, id in ipairs(ids) do spellids[i] = tostring(id) end  -- MUST be strings
  local tr = trigStub{
    type = "aura2", unit = unit,
    debuffType = helpful and "HELPFUL" or "HARMFUL",
    useExactSpellId = true, auraspellids = spellids,
  }
  for k, v in pairs(opts or {}) do tr[k] = v end
  return tr
end

-- Cooldown by NUMERIC rank-1 spell id, exact match, override-following off.
-- Rank-1 ids are always in a classic spellbook and cooldowns are shared
-- across ranks. NEVER pass a name string: modern WA resolves names via
-- GetSpellInfo(name) at load time and silently tracks spell 0 on failure.
function F.cdTrigger(spellId, name, showOn)
  return trigStub{
    type = "spell", event = "Cooldown Progress (Spell)",
    use_spellName = true, spellName = spellId, realSpellName = name,
    use_exact_spellName = true, use_ignoreoverride = true,
    use_genericShowOn = true, genericShowOn = showOn or "showAlways", -- |"showOnReady"|"showOnCooldown"
    use_track = true, track = "auto", unit = "player",
  }
end

-- Power. powertype: 0 mana, 1 rage, 3 energy, 4 combo points (classic WA
-- special-cases 4 via GetComboPoints). minValue: show only at >= N.
function F.powerTrigger(powertype, minValue)
  local tr = trigStub{
    type = "unit", event = "Power", unit = "player", use_unit = true,
    use_powertype = true, powertype = powertype,
  }
  if minValue then
    tr.use_power = true; tr.power = tostring(minValue); tr.power_operator = ">="
  end
  return tr
end

function F.healthTrigger(maxPercent)  -- show when HP below N%
  local tr = trigStub{ type = "unit", event = "Health", unit = "player", use_unit = true }
  if maxPercent then
    tr.use_percenthealth = true; tr.percenthealth = tostring(maxPercent); tr.percenthealth_operator = "<"
  end
  return tr
end

-- Threat vs target. NOTE the arg is threatUnit, not unit.
-- threatpct: 100 = pulling aggro. Stored vars for conditions: threatpct, aggro, status.
function F.threatTrigger(minPct)
  local tr = trigStub{ type = "unit", event = "Threat Situation", use_threatUnit = true, threatUnit = "target" }
  if minPct then
    tr.use_threatpct = true; tr.threatpct = tostring(minPct); tr.threatpct_operator = ">="
  end
  return tr
end

-- Combat log. Prototype is timedrequired: duration (string, seconds) is the
-- window the state stays active after the event fires.
-- ex: F.clogTrigger("SWING","_MISSED","5",{use_missType=true,missType="PARRY",use_destUnit=true,destUnit="player"})
function F.clogTrigger(prefix, suffix, duration, opts)
  local tr = {
    type = "combatlog", event = "Combat Log",
    subeventPrefix = prefix, subeventSuffix = suffix,
    duration = duration,
  }
  for k, v in pairs(opts or {}) do tr[k] = v end
  return tr
end

-- Always-active state feeder; stored bool inCombat drives combat conditions.
function F.unitCharTrigger()
  return trigStub{ type = "unit", event = "Unit Characteristics", unit = "player", use_unit = true }
end

-- Current shapeshift form by spellbook position. On a fully trained TBC druid,
-- Bear/Dire Bear is form 1 and Cat is form 3. This is a state gate, not a load
-- gate: append it to an aura's trigger list with disjunctive="all" so a Feral
-- talent gate cannot make Bear-only elements appear while the player is in Cat.
function F.formTrigger(formIndex)
  return trigStub{
    type = "unit", event = "Stance/Form/Aura",
    use_form = true, form = { single = formIndex, multi = {} },
  }
end

-- ================= REGIONS =================
-- Icon (from the embedded, field-complete prototype).
function F.icon(id, class, w, h, x, y, parent)
  local c = W.deepcopy(ICON_PROTO)
  c.id, c.uid, c.parent = id, W.uid(), parent
  c.width, c.height, c.xOffset, c.yOffset = w, h, x, y
  c.load = F.load(class)
  c.cooldown, c.cooldownSwipe, c.cooldownEdge, c.cooldownTextDisabled = true, true, false, true
  return stub(c)
end

function F.aurabar(id, class, w, h, x, y, parent, color)
  return stub{
    regionType = "aurabar", id = id, uid = W.uid(), parent = parent,
    icon = false, desaturate = false, iconSource = -1,
    texture = "Clean", width = w, height = h,
    orientation = "HORIZONTAL",  -- fills left->right. Bottom-up = "VERTICAL_INVERSE" (yes, inverse — see gotchas.md)
    inverse = false,
    barColor = color, backgroundColor = { 0, 0, 0, 0.7 },
    spark = false, sparkWidth = 10, sparkHeight = 30, sparkColor = { 1, 1, 1, 1 },
    sparkTexture = "Interface\\CastingBar\\UI-CastingBar-Spark",
    sparkBlendMode = "ADD", sparkOffsetX = 0, sparkOffsetY = 0,
    sparkRotationMode = "AUTO", sparkRotation = 0, sparkHidden = "NEVER",
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = x, yOffset = y,
    icon_side = "RIGHT", icon_color = { 1, 1, 1, 1 },
    frameStrata = 1, zoom = 0, alpha = 1,
    useAdjustededMax = false, useAdjustededMin = false,
    subRegions = { [1] = { type = "aurabar_bar" } },
    load = F.load(class),
  }
end

function F.texture(id, class, w, h, x, y, parent, path, color)
  return stub{
    regionType = "texture", id = id, uid = W.uid(), parent = parent,
    texture = path, desaturate = false, width = w, height = h,
    color = color, blendMode = "BLEND", textureWrapMode = "CLAMPTOBLACKADDITIVE",
    rotation = 0, discrete_rotation = 0, mirror = false, rotate = false, alpha = 1,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = x, yOffset = y, frameStrata = 1,
    load = F.load(class),
  }
end
-- Bundled textures that exist for everyone:
F.TEX_CIRCLE = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Smooth2.tga"
F.TEX_SQUARE = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White.tga"
F.TEX_SQUARE_BORDER = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White_Border.tga"

function F.group(id, x, y, parent)
  return stub{
    regionType = "group", id = id, uid = W.uid(), parent = parent,
    controlledChildren = {},
    xOffset = x, yOffset = y,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    frameStrata = 1, scale = 1, subRegions = {},
    border = false, borderColor = { 0, 0, 0, 1 }, backdropColor = { 1, 1, 1, 0.5 },
    borderEdge = "Square Full White", borderOffset = 4, borderInset = 1,
    borderSize = 2, borderBackdrop = "Blizzard Tooltip",
    triggers = F.triggers({ F.auraTrigger("player", true, { 0 }) }),
    load = {},
  }
end

-- grow: "UP","DOWN","LEFT","RIGHT","HORIZONTAL"(centered),"VERTICAL"(centered)
-- ALWAYS pair selfPoint with grow: UP->BOTTOM, DOWN->TOP, RIGHT->LEFT, LEFT->RIGHT,
-- HORIZONTAL/VERTICAL->CENTER. Child x/y offsets are ignored inside dynamic groups.
function F.dynGroup(id, x, y, parent, grow, selfPoint, space)
  local g = F.group(id, x, y, parent)
  g.regionType = "dynamicgroup"
  g.grow, g.selfPoint = grow, selfPoint
  g.align = "CENTER"; g.space = space or 4; g.stagger = 0
  g.sort = "none"; g.animate = true
  g.rotation = 0; g.fullCircle = true; g.arcLength = 360
  g.radius = 200; g.constantFactor = "RADIUS"
  g.useLimit = false; g.limit = 5
  g.gridType = "RD"; g.gridWidth = 5; g.rowSpace = 1; g.columnSpace = 1
  return g
end

-- ================= SUBREGIONS =================
-- Formats: to print a stored number rounded, add
--   text_text_format_<sym>_format = "Number",
--   text_text_format_<sym>_decimal_precision = 0,
--   text_text_format_<sym>_round_type = "floor"
-- ex: F.subtext("%threatpct%%", 12, "INNER_RIGHT", "threatpct")
function F.subtext(fmt, size, point, numberSym)
  local st = {
    type = "subtext", text_text = fmt, text_color = { 1, 1, 1, 1 },
    text_font = "Friz Quadrata TT", text_fontSize = size, text_fontType = "OUTLINE",
    text_visible = true, text_justify = "CENTER",
    text_selfPoint = "AUTO", text_anchorPoint = point,
    anchorXOffset = 0, anchorYOffset = 0,
    text_shadowColor = { 0, 0, 0, 1 }, text_shadowXOffset = 0, text_shadowYOffset = 0,
    rotateText = "NONE", text_automaticWidth = "Auto", text_fixedWidth = 64,
    text_wordWrap = "WordWrap",
  }
  if numberSym then
    st["text_text_format_" .. numberSym .. "_format"] = "Number"
    st["text_text_format_" .. numberSym .. "_decimal_precision"] = 0
    st["text_text_format_" .. numberSym .. "_round_type"] = "floor"
  end
  return st
end

function F.subglow(on, color)
  return {
    type = "subglow", glow = on or false, glowType = "Pixel",
    useGlowColor = color and true or false, glowColor = color or { 1, 1, 1, 1 },
    glowLines = 8, glowFrequency = 0.25, glowLength = 10, glowThickness = 1,
    glowScale = 1, glowBorder = false, glowXOffset = 0, glowYOffset = 0,
  }
end

function F.subborder(anchor)
  return {
    type = "subborder", border_visible = true, border_color = { 0, 0, 0, 1 },
    border_edge = "Square Full White", border_size = 1, border_offset = 0,
    border_anchor = anchor,  -- "bar" for aurabars; omit for icons
  }
end

-- ================= CONDITIONS / ANIMATIONS =================
-- Conditions apply in order; a later matching condition overwrites the same
-- property. sub.N property refs use the subRegions index: append new
-- subregions, never insert before an index a condition points at.
function F.condition(trigger, variable, op, value, property, changeValue)
  return {
    check = { trigger = trigger, variable = variable, op = op, value = value },
    changes = { [1] = { property = property, value = changeValue } },
  }
end

-- ALWAYS pass a duration (string seconds) — missing duration = 0s = invisible.
function F.animPreset(preset, duration, ease)
  return {
    type = "preset", preset = preset,
    duration_type = "seconds", duration = duration,
    easeType = ease or "none", easeStrength = 3,
  }
end

-- channels: {x=,y=} translate | {alpha=, alphaType=} | {scale=} — combined in one pass
function F.animCustom(duration, ch, ease)
  local a = {
    type = "custom", duration_type = "seconds", duration = duration,
    easeType = ease or "none", easeStrength = 3,
  }
  if ch.x or ch.y then
    a.use_translate = true; a.x = ch.x or 0; a.y = ch.y or 0; a.translateType = "straightTranslate"
  end
  if ch.alpha ~= nil then
    a.use_alpha = true; a.alpha = ch.alpha; a.alphaType = ch.alphaType or "straight"
  end
  if ch.scale then
    a.use_scale = true; a.scalex = ch.scale; a.scaley = ch.scale; a.scaleType = "straightScale"
  end
  return a
end

-- ================= PACK ASSEMBLY (v2000 nested) =================
-- top = F.group(...); wire children via parent + controlledChildren, then:
function F.assemble(top, byId)
  local c = {}
  local function push(node)
    for _, cid in ipairs(node.controlledChildren or {}) do
      local ch = assert(byId[cid], "missing child table: " .. cid)
      c[#c + 1] = ch
      if ch.controlledChildren then push(ch) end
    end
  end
  push(top)
  return { m = "d", d = top, c = c, v = 2000, s = "3.5.0" }
end

return F
