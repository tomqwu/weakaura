-- Historical iteration script (v40 of 40). Requires the original workspace:
-- dump.lua + decoded schema template + prior version strings + LibDeflate/LibSerialize.
-- For new packs, use ../../tools/tbc-weakaura-creator/ instead.
math.randomseed(20260809)
local H = dofile("dump.lua")
local LibDeflate, LibSerialize = H.LibDeflate, H.LibSerialize

local f = io.open("F6TgwAljB.txt","r"); local src = f:read("*a"); f:close()
local T = H.decode(src)

local function deepcopy(t)
  if type(t) ~= "table" then return t end
  local r = {}
  for k,v in pairs(t) do r[k] = deepcopy(v) end
  return r
end

local B64 = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789()"
local function uid()
  local s = {}
  for i=1,11 do local n = math.random(1,64); s[i] = B64:sub(n,n) end
  return table.concat(s)
end

local function stripWago(t) t.wagoID, t.url, t.semver, t.version = nil,nil,nil,nil end

local TOPID = "Rogue TBC - All Specs"
local CDID  = "Rogue - Cooldowns"

-- ===== top-level static group (v2000: keeps parent/controlledChildren) =====
local parent = deepcopy(T.d)
stripWago(parent)
parent.id = TOPID
parent.uid = uid()
parent.xOffset = 0
parent.yOffset = -140
parent.controlledChildren = {}

-- ===== icon prototype from the validated template child =====
local proto = deepcopy(T.c[1])
stripWago(proto)
proto.actions = { init = {}, start = {}, finish = {} }
proto.conditions = {}
proto.subRegions[1].glow = false
proto.load = {
  use_class = true,
  class = { single = "ROGUE", multi = { ROGUE = true } },
  size = { multi = {} }, spec = { multi = {} }, talent = { multi = {} },
}
proto.cooldown = true
proto.cooldownSwipe = true
proto.cooldownEdge = false
proto.cooldownTextDisabled = true

local function newChild(id, w, h, x, y, parentId)
  local c = deepcopy(proto)
  c.id, c.uid = id, uid()
  c.width, c.height = w, h
  c.xOffset, c.yOffset = x, y
  c.parent = parentId
  return c
end

local function subtext(fmt, size, point)
  return {
    type = "subtext", text_text = fmt, text_color = {1,1,1,1},
    text_font = "Friz Quadrata TT", text_fontSize = size, text_fontType = "OUTLINE",
    text_visible = true, text_justify = "CENTER",
    text_selfPoint = "AUTO", text_anchorPoint = point,
    anchorXOffset = 0, anchorYOffset = 0,
    text_shadowColor = {0,0,0,1}, text_shadowXOffset = 0, text_shadowYOffset = 0,
    rotateText = "NONE", text_automaticWidth = "Auto", text_fixedWidth = 64,
    text_wordWrap = "WordWrap",
  }
end

local function auraTrigger(unit, helpful, ids, opts)
  local spellids = {}
  for i, id in ipairs(ids) do spellids[i] = tostring(id) end
  local tr = {
    type = "aura2", unit = unit,
    debuffType = helpful and "HELPFUL" or "HARMFUL",
    useExactSpellId = true, auraspellids = spellids,
    names = {}, spellIds = {},
    event = "Health", subeventPrefix = "SPELL", subeventSuffix = "_CAST_START",
  }
  for k,v in pairs(opts or {}) do tr[k] = v end
  return { [1] = { trigger = tr, untrigger = {} }, activeTriggerMode = -10, disjunctive = "all" }
end

local function cdTrigger(spell, spellId)
  return {
    [1] = {
      trigger = {
        type = "spell", event = "Cooldown Progress (Spell)",
        use_spellName = true, spellName = spellId, realSpellName = spell,
        use_exact_spellName = true, use_ignoreoverride = true,
        use_genericShowOn = true, genericShowOn = "showAlways",
        use_track = true, track = "auto",
        subeventPrefix = "SPELL", subeventSuffix = "_CAST_START",
        names = {}, spellIds = {}, debuffType = "HELPFUL", unit = "player",
      },
      untrigger = {},
    },
    activeTriggerMode = -10, disjunctive = "all",
  }
end

local c = {}  -- flat transmit list, depth-first
local function addTop(child)
  table.insert(parent.controlledChildren, child.id)
  c[#c+1] = child
end

-- ===== row 1: buff/debuff trackers (shared across specs) =====
local snd = newChild("Rogue - Slice and Dice", 40, 40, -66, 0, TOPID)
snd.triggers = auraTrigger("player", true, { 5171, 6774 })
snd.subRegions[2] = subtext("%p", 14, "INNER_BOTTOM")
snd.conditions = { [1] = {
  check = { trigger = 1, variable = "expirationTime", op = "<=", value = "5" },
  changes = { [1] = { property = "sub.1.glow", value = true } },
} }
addTop(snd)

local rup = newChild("Rogue - Rupture", 40, 40, -22, 0, TOPID)
rup.triggers = auraTrigger("target", false, { 1943, 8639, 8640, 11273, 11274, 11275, 26867 }, { ownOnly = true })
rup.subRegions[2] = subtext("%p", 14, "INNER_BOTTOM")
addTop(rup)

local dp = newChild("Rogue - Deadly Poison", 40, 40, 22, 0, TOPID)
dp.triggers = auraTrigger("target", false, {
  2818, 2819, 11353, 11354, 25349, 26968, 27187,
}, { ownOnly = true })
dp.subRegions[2] = subtext("%s", 16, "CENTER")
dp.subRegions[3] = subtext("%p", 11, "INNER_BOTTOM")
addTop(dp)

-- Assassination signature: Find Weakness uptime after finishers
local fw = newChild("Rogue - Find Weakness", 40, 40, 66, 0, TOPID)
fw.triggers = auraTrigger("player", true, { 31234, 31235, 31236, 31237, 31238 })
fw.subRegions[2] = subtext("%p", 14, "INNER_BOTTOM")
addTop(fw)

-- Subtlety signature: Hemorrhage charges on target (same slot; specs are mutually exclusive)
local hemo = newChild("Rogue - Hemorrhage", 40, 40, 66, 0, TOPID)
hemo.triggers = auraTrigger("target", false, { 16511, 17347, 17348, 26864 })
hemo.subRegions[2] = subtext("%s", 16, "CENTER")
hemo.subRegions[3] = subtext("%p", 11, "INNER_BOTTOM")
addTop(hemo)

-- SnD missing warning (all specs)
local miss = newChild("Rogue - SnD MISSING", 40, 40, 0, 84, TOPID)
miss.triggers = auraTrigger("player", true, { 5171, 6774 }, { matchesShowOn = "showOnMissing" })
miss.iconSource = 0
miss.displayIcon = "Interface\\Icons\\ability_rogue_slicedice"
miss.cooldown = false
miss.subRegions[1].glow = true
miss.subRegions[1].glowType = "Pixel"
miss.subRegions[1].useGlowColor = true
miss.subRegions[1].glowColor = {1, 0.15, 0.15, 1}
miss.load.use_combat = true
addTop(miss)

-- ===== cooldown row: dynamic group, auto-collapses hidden icons =====
local dyn = {
  regionType = "dynamicgroup",
  id = CDID, uid = uid(), parent = TOPID,
  internalVersion = 45, tocversion = 20501,
  controlledChildren = {},
  grow = "HORIZONTAL", align = "CENTER", space = 4, stagger = 0,
  sort = "none", animate = false,
  selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
  xOffset = 0, yOffset = -66,
  radius = 200, rotation = 0, fullCircle = true, arcLength = 360,
  constantFactor = "RADIUS", frameStrata = 1, scale = 1,
  useLimit = false, limit = 5, gridType = "RD", gridWidth = 5,
  rowSpace = 1, columnSpace = 1,
  border = false, borderColor = {0,0,0,1}, backdropColor = {1,1,1,0.5},
  borderEdge = "Square Full White", borderOffset = 4, borderInset = 1,
  borderSize = 2, borderBackdrop = "Blizzard Tooltip",
  triggers = deepcopy(T.d.triggers),
  load = deepcopy(T.d.load),
  actions = { init = {}, start = {}, finish = {} },
  animation = deepcopy(T.d.animation),
  conditions = {}, config = {}, authorOptions = {}, information = {},
}
addTop(dyn)

local function addCD(spell, spellId, gated)
  local icon = newChild("Rogue CD - " .. spell, 32, 32, 0, 0, CDID)
  icon.triggers = cdTrigger(spell, spellId)
  icon.cooldownTextDisabled = false
  icon.conditions = { [1] = {
    check = { trigger = 1, variable = "onCooldown", op = "==", value = 1 },
    changes = { [1] = { property = "desaturate", value = true } },
  } }
  if gated then
    icon.load.use_spellknown = true
    icon.load.spellknown = spellId
  end
  table.insert(dyn.controlledChildren, icon.id)
  c[#c+1] = icon
  return icon
end

-- talent CDs, gated by Spell Known -> only your spec's icons appear
addCD("Adrenaline Rush", 13750, true)   -- Combat 41
addCD("Blade Flurry",    13877, true)   -- Combat 21
addCD("Cold Blood",      14177, true)   -- Assassination 21
addCD("Shadowstep",      36554, true)   -- Subtlety 41
addCD("Preparation",     14185, true)   -- Subtlety
addCD("Premeditation",   14183, true)   -- Subtlety
-- baseline CDs, always shown
addCD("Evasion", 5277, false)
addCD("Vanish", 1856, false)
addCD("Cloak of Shadows", 31224, false)
addCD("Kick", 1766, false)


-- ===== Riposte proc (Combat): parry window + ready-state gate =====
local rip = newChild("Rogue - Riposte", 40, 40, -66, 84, TOPID)
rip.iconSource = 0
rip.displayIcon = "Interface\\Icons\\ability_warrior_challange"
local function parryTrigger(prefix)
  return {
    trigger = {
      type = "combatlog", event = "Combat Log",
      subeventPrefix = prefix, subeventSuffix = "_MISSED",
      use_missType = true, missType = "PARRY",
      use_destUnit = true, destUnit = "player",
      duration = "5",
    },
    untrigger = {},
  }
end
local ripCD = cdTrigger("Riposte", 14251)[1]
ripCD.trigger.genericShowOn = "showOnReady"
rip.triggers = {
  [1] = parryTrigger("SWING"),
  [2] = parryTrigger("SPELL"),
  [3] = ripCD,
  disjunctive = "custom",
  customTriggerLogic = "function(t) return (t[1] or t[2]) and t[3] end",
  activeTriggerMode = -10,
}
rip.subRegions[1].glow = true
rip.subRegions[1].glowType = "Pixel"
rip.subRegions[1].useGlowColor = true
rip.subRegions[1].glowColor = {1, 0.82, 0.1, 1}
rip.subRegions[2] = subtext("%p", 14, "INNER_BOTTOM")
rip.load.use_spellknown = true
rip.load.spellknown = 14251
table.insert(parent.controlledChildren, 7, rip.id)  -- after SnD MISSING, before CD row
table.insert(c, 7, rip)


-- ===== Combo points: 5 red dots above the buff row =====
local cpX = { -70, -35, 0, 35, 70 }
for i = 1, 5 do
  local dot = {
    regionType = "texture",
    id = "Rogue - Combo Point " .. i,
    uid = uid(),
    parent = TOPID,
    internalVersion = 45, tocversion = 20501,
    texture = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White_Border.tga",
    desaturate = false,
    width = 32, height = 8,
    color = {0.2, 1, 0.25, 1},
    blendMode = "BLEND",
    textureWrapMode = "CLAMPTOBLACKADDITIVE",
    rotation = 0, discrete_rotation = 0,
    mirror = false, rotate = false,
    alpha = 1,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = cpX[i], yOffset = 30,
    frameStrata = 1,
    triggers = {
      [1] = {
        trigger = {
          type = "unit", event = "Power", unit = "player", use_unit = true,
          use_powertype = true, powertype = 4,
          use_power = true, power = tostring(i), power_operator = ">=",
          names = {}, spellIds = {}, debuffType = "HELPFUL",
          subeventPrefix = "SPELL", subeventSuffix = "_CAST_START",
        },
        untrigger = {},
      },
      activeTriggerMode = -10, disjunctive = "all",
    },
    load = {
      use_class = true,
      class = { single = "ROGUE", multi = { ROGUE = true } },
      size = { multi = {} }, spec = { multi = {} }, talent = { multi = {} },
    },
    actions = { init = {}, start = {}, finish = {} },
    animation = deepcopy(T.d.animation),
    conditions = {
      [1] = {
        check = { trigger = 1, variable = "power", op = ">=", value = "5" },
        changes = { [1] = { property = "color", value = { 1, 0.65, 0.1, 1 } } },
      },
    },
    config = {}, authorOptions = {}, information = {},
  }
  table.insert(parent.controlledChildren, 7 + i, dot.id)
  table.insert(c, 7 + i, dot)
end


-- ===== restructure: four draggable sub-groups =====
local function makeSubGroup(id, x, y)
  local g = deepcopy(T.d)
  stripWago(g)
  g.id = id
  g.uid = uid()
  g.parent = TOPID
  g.xOffset = x
  g.yOffset = y
  g.controlledChildren = {}
  return g
end
parent.frameStrata = 1
local gBuffs  = makeSubGroup("Rogue - Buffs", 0, -16)
local gAlerts = makeSubGroup("Rogue - Alerts", -150, 96)
local gCP     = makeSubGroup("Rogue - Resources", 0, 56)

gBuffs.frameStrata, gAlerts.frameStrata, gCP.frameStrata = 1, 1, 1

-- alerts: vertical flow (dynamic group growing upward, smooth re-stacking)
gAlerts.regionType = "dynamicgroup"
gAlerts.grow = "UP"
gAlerts.selfPoint = "BOTTOM"
gAlerts.align = "CENTER"
gAlerts.space = 6
gAlerts.stagger = 0
gAlerts.sort = "none"
gAlerts.animate = true
gAlerts.rotation = 0
gAlerts.fullCircle = true
gAlerts.arcLength = 360
gAlerts.radius = 200
gAlerts.constantFactor = "RADIUS"
gAlerts.useLimit = false
gAlerts.limit = 5
gAlerts.gridType = "RD"
gAlerts.gridWidth = 5
gAlerts.rowSpace = 1
gAlerts.columnSpace = 1


-- ===== energy bar under the combo point dots =====
local energybar = {
  regionType = "aurabar",
  id = "Rogue - Energy",
  uid = uid(),
  internalVersion = 45, tocversion = 20501,
  icon = false, desaturate = false, iconSource = -1,
  texture = "Clean",
  width = 172, height = 14,
  orientation = "HORIZONTAL", inverse = false,
  barColor = {1, 0.82, 0, 1},
  backgroundColor = {0, 0, 0, 0.7},
  spark = false, sparkWidth = 10, sparkHeight = 30,
  sparkColor = {1, 1, 1, 1},
  sparkTexture = "Interface\\CastingBar\\UI-CastingBar-Spark",
  sparkBlendMode = "ADD", sparkOffsetX = 0, sparkOffsetY = 0,
  sparkRotationMode = "AUTO", sparkRotation = 0, sparkHidden = "NEVER",
  selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
  xOffset = 0, yOffset = -27,
  icon_side = "RIGHT", icon_color = {1, 1, 1, 1},
  frameStrata = 1, zoom = 0, alpha = 1,
  useAdjustededMax = false, useAdjustededMin = false,
  subRegions = {
    [1] = { type = "aurabar_bar" },
    [2] = subtext("%p", 12, "INNER_RIGHT"),
    [3] = {
      type = "subborder",
      border_visible = true,
      border_color = {0, 0, 0, 1},
      border_edge = "Square Full White",
      border_size = 1,
      border_offset = 0,
      border_anchor = "bar",
    },
  },
  triggers = {
    [1] = {
      trigger = {
        type = "unit", event = "Power", unit = "player", use_unit = true,
        use_powertype = true, powertype = 3,
        names = {}, spellIds = {}, debuffType = "HELPFUL",
        subeventPrefix = "SPELL", subeventSuffix = "_CAST_START",
      },
      untrigger = {},
    },
    activeTriggerMode = -10, disjunctive = "all",
  },
  load = {
    use_class = true,
    class = { single = "ROGUE", multi = { ROGUE = true } },
    size = { multi = {} }, spec = { multi = {} }, talent = { multi = {} },
  },
  actions = { init = {}, start = {}, finish = {} },
  animation = deepcopy(T.d.animation),
  conditions = {}, config = {}, authorOptions = {}, information = {},
}


-- ===== vertical threat bar, left of center =====
local threatbar = {
  regionType = "aurabar",
  id = "Rogue - Threat",
  uid = uid(),
  parent = gCP.id,
  internalVersion = 45, tocversion = 20501,
  icon = false, desaturate = false, iconSource = -1,
  texture = "Clean",
  width = 172, height = 14,
  orientation = "HORIZONTAL", inverse = false,
  barColor = {0.25, 0.8, 0.3, 1},
  backgroundColor = {0, 0, 0, 0.7},
  spark = false, sparkWidth = 10, sparkHeight = 30,
  sparkColor = {1, 1, 1, 1},
  sparkTexture = "Interface\\CastingBar\\UI-CastingBar-Spark",
  sparkBlendMode = "ADD", sparkOffsetX = 0, sparkOffsetY = 0,
  sparkRotationMode = "AUTO", sparkRotation = 0, sparkHidden = "NEVER",
  selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
  xOffset = 0, yOffset = -41,
  icon_side = "RIGHT", icon_color = {1, 1, 1, 1},
  frameStrata = 1, zoom = 0, alpha = 1,
  useAdjustededMax = false, useAdjustededMin = false,
  subRegions = {
    [1] = { type = "aurabar_bar" },
    [2] = (function()
      local st = subtext("%threatpct%%", 12, "INNER_RIGHT")
      st.text_text_format_threatpct_format = "Number"
      st.text_text_format_threatpct_decimal_precision = 0
      st.text_text_format_threatpct_round_type = "floor"
      return st
    end)(),
    [3] = {
      type = "subborder",
      border_visible = true,
      border_color = {0, 0, 0, 1},
      border_edge = "Square Full White",
      border_size = 1,
      border_offset = 0,
      border_anchor = "bar",
    },
  },
  triggers = {
    [1] = {
      trigger = {
        type = "unit", event = "Threat Situation",
        use_threatUnit = true, threatUnit = "target",
        names = {}, spellIds = {}, debuffType = "HELPFUL",
        subeventPrefix = "SPELL", subeventSuffix = "_CAST_START",
      },
      untrigger = {},
    },
    activeTriggerMode = -10, disjunctive = "all",
  },
  conditions = {
    [1] = {
      check = { trigger = 1, variable = "threatpct", op = ">=", value = "70" },
      changes = { [1] = { property = "barColor", value = { 1, 0.6, 0.1, 1 } } },
    },
    [2] = {
      check = { trigger = 1, variable = "aggro", op = "==", value = 1 },
      changes = { [1] = { property = "barColor", value = { 0.9, 0.12, 0.12, 1 } } },
    },
  },
  load = {
    use_class = true,
    class = { single = "ROGUE", multi = { ROGUE = true } },
    size = { multi = {} }, spec = { multi = {} }, talent = { multi = {} },
  },
  actions = { init = {}, start = {}, finish = {} },
  animation = deepcopy(T.d.animation),
  config = {}, authorOptions = {}, information = {},
}


-- ===== Feint prompt: threat >= 70% AND Feint ready =====
local feint = newChild("Rogue - Feint", 40, 40, 66, 0, gAlerts.id)
feint.iconSource = 0
feint.displayIcon = "Interface\\Icons\\ability_rogue_feint"
local feintCD = cdTrigger("Feint", 1966)[1]
feintCD.trigger.genericShowOn = "showOnReady"
feint.triggers = {
  [1] = {
    trigger = {
      type = "unit", event = "Threat Situation",
      use_threatUnit = true, threatUnit = "target",
      use_threatpct = true, threatpct = "70", threatpct_operator = ">=",
      names = {}, spellIds = {}, debuffType = "HELPFUL",
      subeventPrefix = "SPELL", subeventSuffix = "_CAST_START",
    },
    untrigger = {},
  },
  [2] = feintCD,
  disjunctive = "all",
  activeTriggerMode = -10,
}
feint.subRegions[1].glow = true
feint.subRegions[1].glowType = "Pixel"
feint.subRegions[1].useGlowColor = true
feint.subRegions[1].glowColor = {1, 0.45, 0.1, 1}
feint.load.use_spellknown = true
feint.load.spellknown = 1966

local byId = {}
for _, ch in ipairs(c) do byId[ch.id] = ch end

local function adopt(group, ids, zeroY)
  for _, cid in ipairs(ids) do
    local ch = byId[cid]
    ch.parent = group.id
    if zeroY then ch.yOffset = 0 end
    table.insert(group.controlledChildren, cid)
  end
end
adopt(gBuffs,  { "Rogue - Slice and Dice", "Rogue - Rupture", "Rogue - Deadly Poison",
                 "Rogue - Find Weakness", "Rogue - Hemorrhage" }, false)
adopt(gAlerts, { "Rogue - SnD MISSING", "Rogue - Riposte" }, true)
byId[feint.id] = feint
table.insert(gAlerts.controlledChildren, feint.id)
for _, a in ipairs({ miss, rip, feint }) do
  a.xOffset = 0
  a.animation.start = {
    type = "preset", preset = "slidebottom",
    duration_type = "seconds", duration = "0.3",
    easeType = "easeOut", easeStrength = 3,
  }
  a.animation.finish = {
    type = "custom",
    duration_type = "seconds", duration = "1",
    use_translate = true, x = 0, y = 150, translateType = "straightTranslate",
    use_alpha = true, alpha = 0, alphaType = "straight",
    use_scale = true, scalex = 0.4, scaley = 0.4, scaleType = "straightScale",
    easeType = "easeOut", easeStrength = 3,
  }
end
adopt(gCP,     { "Rogue - Combo Point 1", "Rogue - Combo Point 2", "Rogue - Combo Point 3",
                 "Rogue - Combo Point 4", "Rogue - Combo Point 5" }, true)
for i = 1, 5 do byId["Rogue - Combo Point " .. i].yOffset = 4 end
local gBars = makeSubGroup("Rogue - Bars", 0, 0)
gBars.parent = gCP.id
gBars.border = false
gBars.borderEdge = "Square Full White"
gBars.borderSize = 2
gBars.borderColor = {0.5, 0.5, 0.5, 0.8}
gBars.borderBackdrop = "Blizzard Tooltip"
gBars.backdropColor = {0, 0, 0, 0.4}
gBars.borderOffset = 5
gBars.borderInset = 1
byId[gBars.id] = gBars
table.insert(gCP.controlledChildren, gBars.id)
byId[energybar.id] = energybar
energybar.parent = gBars.id
table.insert(gBars.controlledChildren, energybar.id)
byId[threatbar.id] = threatbar
threatbar.parent = gBars.id
table.insert(gBars.controlledChildren, threatbar.id)

-- ===== health bar on top of the stack =====
local healthbar = {
  regionType = "aurabar",
  id = "Rogue - Health",
  uid = uid(),
  parent = gBars.id,
  internalVersion = 45, tocversion = 20501,
  icon = false, desaturate = false, iconSource = -1,
  texture = "Clean",
  width = 172, height = 14,
  orientation = "HORIZONTAL", inverse = false,
  barColor = {0.15, 0.78, 0.25, 1},
  backgroundColor = {0, 0, 0, 0.7},
  spark = false, sparkWidth = 10, sparkHeight = 30,
  sparkColor = {1, 1, 1, 1},
  sparkTexture = "Interface\\CastingBar\\UI-CastingBar-Spark",
  sparkBlendMode = "ADD", sparkOffsetX = 0, sparkOffsetY = 0,
  sparkRotationMode = "AUTO", sparkRotation = 0, sparkHidden = "NEVER",
  selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
  xOffset = 0, yOffset = -13,
  icon_side = "RIGHT", icon_color = {1, 1, 1, 1},
  frameStrata = 1, zoom = 0, alpha = 1,
  useAdjustededMax = false, useAdjustededMin = false,
  subRegions = {
    [1] = { type = "aurabar_bar" },
    [2] = (function()
      local st = subtext("%percenthealth%%", 12, "INNER_RIGHT")
      st.text_text_format_percenthealth_format = "Number"
      st.text_text_format_percenthealth_decimal_precision = 0
      st.text_text_format_percenthealth_round_type = "floor"
      return st
    end)(),
    [3] = {
      type = "subborder",
      border_visible = true,
      border_color = {0, 0, 0, 1},
      border_edge = "Square Full White",
      border_size = 1,
      border_offset = 0,
      border_anchor = "bar",
    },
  },
  triggers = {
    [1] = {
      trigger = {
        type = "unit", event = "Health", unit = "player", use_unit = true,
        names = {}, spellIds = {}, debuffType = "HELPFUL",
        subeventPrefix = "SPELL", subeventSuffix = "_CAST_START",
      },
      untrigger = {},
    },
    activeTriggerMode = -10, disjunctive = "all",
  },
  load = {
    use_class = true,
    class = { single = "ROGUE", multi = { ROGUE = true } },
    size = { multi = {} }, spec = { multi = {} }, talent = { multi = {} },
  },
  actions = { init = {}, start = {}, finish = {} },
  animation = deepcopy(T.d.animation),
  conditions = {}, config = {}, authorOptions = {}, information = {},
}
byId[healthbar.id] = healthbar
table.insert(gBars.controlledChildren, 1, healthbar.id)

-- ===== 80%+ threat: red flash overlay, only in party/raid =====
local flash = {
  regionType = "texture",
  id = "Rogue - Threat Flash",
  uid = uid(),
  parent = gBars.id,
  internalVersion = 45, tocversion = 20501,
  texture = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White.tga",
  desaturate = false,
  width = 176, height = 18,
  color = {1, 0.1, 0.1, 0.85},
  blendMode = "ADD",
  textureWrapMode = "CLAMPTOBLACKADDITIVE",
  rotation = 0, discrete_rotation = 0, mirror = false, rotate = false,
  alpha = 1,
  selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
  xOffset = 0, yOffset = -41,
  frameStrata = 1,
  triggers = {
    [1] = {
      trigger = {
        type = "unit", event = "Threat Situation",
        use_threatUnit = true, threatUnit = "target",
        use_threatpct = true, threatpct = "80", threatpct_operator = ">=",
        names = {}, spellIds = {}, debuffType = "HELPFUL",
        subeventPrefix = "SPELL", subeventSuffix = "_CAST_START",
      },
      untrigger = {},
    },
    activeTriggerMode = -10, disjunctive = "all",
  },
  load = {
    use_class = true,
    class = { single = "ROGUE", multi = { ROGUE = true } },
    use_ingroup = true,
    ingroup = { multi = { group = true, raid = true } },
    size = { multi = {} }, spec = { multi = {} }, talent = { multi = {} },
  },
  animation = {
    start = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
    main = { type = "preset", preset = "alphaPulse", duration_type = "seconds", easeType = "none", easeStrength = 3 },
    finish = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
  },
  actions = { init = {}, start = {}, finish = {} },
  conditions = {}, config = {}, authorOptions = {}, information = {},
}
byId[flash.id] = flash
table.insert(gBars.controlledChildren, flash.id)






-- ===== weapon enchant procs: cloned tracker right of the bars =====
local gProcs = makeSubGroup("Rogue - Procs", 110, 24)
gProcs.regionType = "dynamicgroup"
gProcs.grow = "RIGHT"
gProcs.selfPoint = "LEFT"
gProcs.align = "CENTER"
gProcs.space = 4
gProcs.stagger = 0
gProcs.sort = "none"
gProcs.animate = true
gProcs.rotation = 0
gProcs.fullCircle = true
gProcs.arcLength = 360
gProcs.radius = 200
gProcs.constantFactor = "RADIUS"
gProcs.useLimit = false
gProcs.limit = 5
gProcs.gridType = "RD"
gProcs.gridWidth = 5
gProcs.rowSpace = 1
gProcs.columnSpace = 1

local procs = newChild("Rogue - Weapon Procs", 32, 32, 0, 0, gProcs.id)
procs.triggers = auraTrigger("player", true, { 20007, 28093, 42976 }, { showClones = true })
procs.subRegions[2] = subtext("%p", 12, "INNER_BOTTOM")
procs.subRegions[1].glow = true
procs.subRegions[1].glowType = "Pixel"
procs.subRegions[1].useGlowColor = true
procs.subRegions[1].glowColor = {1, 0.85, 0.2, 1}
procs.animation.start = {
  type = "custom",
  duration_type = "seconds", duration = "0.5",
  use_alpha = true, alpha = 0, alphaType = "alphaPulse",
  use_scale = true, scalex = 1.5, scaley = 1.5, scaleType = "straightScale",
  easeType = "easeOut", easeStrength = 3,
}
procs.animation.finish = {
  type = "custom",
  duration_type = "seconds", duration = "0.8",
  use_translate = true, x = 120, y = 0, translateType = "straightTranslate",
  use_alpha = true, alpha = 0, alphaType = "straight",
  easeType = "easeOut", easeStrength = 3,
}
byId[gProcs.id] = gProcs
byId[procs.id] = procs
table.insert(gProcs.controlledChildren, procs.id)


-- ===== low-health Evasion prompt: HP < 50% AND Evasion ready =====
local evade = newChild("Rogue - Evasion Prompt", 40, 40, 0, 0, gAlerts.id)
evade.iconSource = 0
evade.displayIcon = "Interface\\Icons\\spell_shadow_shadowward"
evade.cooldown = false
local evadeCD = cdTrigger("Evasion", 5277)[1]
evadeCD.trigger.genericShowOn = "showOnReady"
evade.triggers = {
  [1] = {
    trigger = {
      type = "unit", event = "Health", unit = "player", use_unit = true,
      use_percenthealth = true, percenthealth = "50", percenthealth_operator = "<",
      names = {}, spellIds = {}, debuffType = "HELPFUL",
      subeventPrefix = "SPELL", subeventSuffix = "_CAST_START",
    },
    untrigger = {},
  },
  [2] = evadeCD,
  disjunctive = "all",
  activeTriggerMode = -10,
}
evade.subRegions[1].glow = true
evade.subRegions[1].glowType = "Pixel"
evade.subRegions[1].useGlowColor = true
evade.subRegions[1].glowColor = {0.3, 0.7, 1, 1}
evade.load.use_combat = true
evade.load.use_spellknown = true
evade.load.spellknown = 5277
evade.animation.start = {
  type = "preset", preset = "slidebottom",
  duration_type = "seconds", duration = "0.3",
  easeType = "easeOut", easeStrength = 3,
}
evade.animation.finish = {
  type = "custom",
  duration_type = "seconds", duration = "1",
  use_translate = true, x = 0, y = 150, translateType = "straightTranslate",
  use_alpha = true, alpha = 0, alphaType = "straight",
  use_scale = true, scalex = 0.4, scaley = 0.4, scaleType = "straightScale",
  easeType = "easeOut", easeStrength = 3,
}
byId[evade.id] = evade
table.insert(gAlerts.controlledChildren, evade.id)


-- ===== energy threshold lines: Eviscerate 35 (red) / Sinister Strike 40 (purple) =====
local function energyTrigger(minPower)
  local tr = {
    type = "unit", event = "Power", unit = "player", use_unit = true,
    use_powertype = true, powertype = 3,
    names = {}, spellIds = {}, debuffType = "HELPFUL",
    subeventPrefix = "SPELL", subeventSuffix = "_CAST_START",
  }
  if minPower then
    tr.use_power = true
    tr.power = tostring(minPower)
    tr.power_operator = ">="
  end
  return { [1] = { trigger = tr, untrigger = {} }, activeTriggerMode = -10, disjunctive = "all" }
end

local function thresholdLine(id, x, w, h, color, minPower, anim)
  local line = {
    regionType = "texture",
    id = id,
    uid = uid(),
    parent = gBars.id,
    internalVersion = 45, tocversion = 20501,
    texture = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White.tga",
    desaturate = false,
    width = w, height = h,
    color = color,
    blendMode = "BLEND",
    textureWrapMode = "CLAMPTOBLACKADDITIVE",
    rotation = 0, discrete_rotation = 0, mirror = false, rotate = false,
    alpha = 1,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = x, yOffset = -27,
    frameStrata = 1,
    triggers = energyTrigger(minPower),
    load = {
      use_class = true,
      class = { single = "ROGUE", multi = { ROGUE = true } },
      size = { multi = {} }, spec = { multi = {} }, talent = { multi = {} },
    },
    actions = { init = {}, start = {}, finish = {} },
    animation = deepcopy(T.d.animation),
    conditions = {}, config = {}, authorOptions = {}, information = {},
  }
  if anim then
    line.animation.start = {
      type = "preset", preset = "shrink",  -- WA key "shrink" = UI label "Grow" (pop-in)
      duration_type = "seconds", duration = "0.25",
      easeType = "easeOut", easeStrength = 3,
    }
    line.animation.finish = {
      type = "preset", preset = "fade",
      duration_type = "seconds", duration = "0.2",
      easeType = "none", easeStrength = 3,
    }
  end
  byId[line.id] = line
  table.insert(gBars.controlledChildren, line.id)
end

thresholdLine("Rogue - Evis Line",     -26, 2, 16, {1, 0.15, 0.15, 0.55}, nil, false)
thresholdLine("Rogue - SS Line",       -17, 2, 16, {0.65, 0.3, 1, 0.55},  nil, false)
thresholdLine("Rogue - Evis Line Lit", -26, 4, 18, {1, 0.15, 0.15, 1},    35,  true)
thresholdLine("Rogue - SS Line Lit",   -17, 4, 18, {0.65, 0.3, 1, 1},     40,  true)


-- ===== extra baseline cooldowns (uid calls appended, never inserted) =====
for _, e in ipairs({
  { "Sprint",   2983 },
  { "Gouge",    1776 },
  { "Blind",    2094 },
  { "Feint",    1966 },
  { "Distract", 1725 },
}) do
  local icon = addCD(e[1], e[2], false)
  byId[icon.id] = icon
end

parent.controlledChildren = { gBuffs.id, gAlerts.id, gCP.id, gProcs.id, CDID }
local newC = {}
local function push(group)
  newC[#newC+1] = group
  for _, cid in ipairs(group.controlledChildren) do
    local ch = byId[cid]
    if ch.controlledChildren then push(ch) else newC[#newC+1] = ch end
  end
end
push(gBuffs)
push(gAlerts)
push(gCP)
push(gProcs)
push(byId[CDID])
c = newC



-- ===== bars panel: 50% alpha out of combat, full in combat =====
local fadeSet = {
  ["Rogue - Health"] = true, ["Rogue - Energy"] = true,
  ["Rogue - Evis Line"] = true, ["Rogue - SS Line"] = true,
  ["Rogue - Evis Line Lit"] = true, ["Rogue - SS Line Lit"] = true,
  ["Rogue - Combo Point 1"] = true, ["Rogue - Combo Point 2"] = true,
  ["Rogue - Combo Point 3"] = true, ["Rogue - Combo Point 4"] = true,
  ["Rogue - Combo Point 5"] = true,
}
for _, ch in ipairs(c) do
  if fadeSet[ch.id] then
    local n = #ch.triggers + 1
    ch.triggers[n] = {
      trigger = {
        type = "unit", event = "Unit Characteristics", unit = "player", use_unit = true,
        names = {}, spellIds = {}, debuffType = "HELPFUL",
        subeventPrefix = "SPELL", subeventSuffix = "_CAST_START",
      },
      untrigger = {},
    }
    table.insert(ch.conditions, {
      check = { trigger = n, variable = "inCombat", op = "==", value = 0 },
      changes = { [1] = { property = "alpha", value = 0.5 } },
    })
  end
end



-- ===== keybind labels (top-left; bottom-right belongs to OmniCC) =====
local keybinds = {
  ["Rogue CD - Sprint"]   = "G",
  ["Rogue CD - Distract"] = "B5",
  ["Rogue CD - Gouge"]    = "E",
  ["Rogue CD - Vanish"]   = "Z",
}
for _, ch in ipairs(c) do
  local key = keybinds[ch.id]
  if key then
    table.insert(ch.subRegions, subtext(key, 10, "INNER_TOPLEFT"))
  end
end

-- ===== mouseover tooltips on the cooldown row =====
for _, ch in ipairs(c) do
  if ch.id:sub(1, 11) == "Rogue CD - " then ch.useTooltip = true end
end

-- ===== icon polish: crop + 1px outline =====
for _, ch in ipairs(c) do
  if ch.regionType == "icon" then
    ch.zoom = 0.3
    table.insert(ch.subRegions, {
      type = "subborder",
      border_visible = true,
      border_color = {0, 0, 0, 1},
      border_edge = "Square Full White",
      border_size = 1,
      border_offset = 0,
    })
  end
end

-- ===== encode (nested groups => version 2000) =====
local transmit = { m = "d", d = parent, c = c, v = 2000, s = "3.5.0" }
local serialized = LibSerialize:SerializeEx({ errorOnUnserializableType = false }, transmit)
local compressed = LibDeflate:CompressDeflate(serialized, { level = 9 })
local encoded = "!WA:2!" .. LibDeflate:EncodeForPrint(compressed)
local out = io.open("import_string_v40.txt", "w"); out:write(encoded); out:close()

-- ===== verification =====
local back = H.decode(encoded)
local function deepeq(a, b, path)
  if type(a) ~= type(b) then return false, path end
  if type(a) ~= "table" then if a ~= b then return false, path end return true end
  for k,v in pairs(a) do
    local ok, p = deepeq(v, b[k], path.."."..tostring(k)); if not ok then return false, p end
  end
  for k in pairs(b) do if a[k] == nil then return false, path.."."..tostring(k) end end
  return true
end
print("round-trip identical:", deepeq(transmit, back, "root"))
print("string length:", #encoded, " children:", #back.c)

-- structural integrity: parent refs + controlledChildren wiring + uid uniqueness
local ids, uids, errs = { [back.d.id] = true }, { [back.d.uid] = true }, 0
for _, ch in ipairs(back.c) do
  if ids[ch.id] then print("DUP ID:", ch.id); errs = errs + 1 end
  if uids[ch.uid] then print("DUP UID:", ch.uid); errs = errs + 1 end
  ids[ch.id], uids[ch.uid] = true, true
end
for _, ch in ipairs(back.c) do
  if not ids[ch.parent] then print("BAD PARENT:", ch.id, "->", tostring(ch.parent)); errs = errs + 1 end
end
local listed = {}
local function walkCC(t)
  for _, cid in ipairs(t.controlledChildren or {}) do
    if not ids[cid] then print("CC MISSING:", cid); errs = errs + 1 end
    if listed[cid] then print("CC DUP:", cid); errs = errs + 1 end
    listed[cid] = true
  end
end
walkCC(back.d)
for _, ch in ipairs(back.c) do walkCC(ch) end
local nListed = 0; for _ in pairs(listed) do nListed = nListed + 1 end
print("controlledChildren entries:", nListed, " transmitted children:", #back.c, " errors:", errs)
for i, ch in ipairs(back.c) do
  local gate = ch.load and ch.load.use_spellknown and (" [known:" .. ch.load.spellknown .. "]") or ""
  print(string.format("  %2d %-28s -> %-22s %s%s", i, ch.id, ch.parent, ch.regionType, gate))
end

-- uid continuity vs v2 (same seed => same uids => WA offers "Update")
local f2 = io.open("import_string_v39.txt","r")
if f2 then
  local old = H.decode(f2:read("*a")); f2:close()
  local oldByI = {}
  for _, ch in ipairs(old.c) do oldByI[ch.id] = ch.uid end
  local stable, moved = 0, 0
  for _, ch in ipairs(back.c) do
    if oldByI[ch.id] then
      if oldByI[ch.id] == ch.uid then stable = stable + 1 else moved = moved + 1 end
    end
  end
  print("uid continuity: stable="..stable.." changed="..moved.." parentSame="..tostring(old.d.uid == back.d.uid))
end
