-- tbc/mage/generate.lua — Mage "Arcane & Frost" HUD v1.
-- Run: lua5.1 tbc/mage/generate.lua   (toolkit libs live in tools/tbc-weakaura-creator/scripts/)
-- Produces all-specs.txt: a "!WA:2!" string importable in game (internalVersion 45).
--
-- Every spell id below was verified on wowhead.com/tbc (re-checked 2026-08-11), ids
-- only, never names (zhCN-safe): aura triggers carry ALL ranks as strings, cooldown
-- triggers carry the numeric rank-1 id. NB the classic->TBC id swap:
--   TBC Cold Snap = 11958 (8 min CD), TBC Ice Block = 45438 (5 min CD).

math.randomseed(20260816)  -- FIXED pack seed; uid() call order is append-only forever
local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
-- wa_factory/wa_lib resolve their own dependencies (wa_lib.lua, assets/icon_proto.lua)
-- from arg[0], so a bare relative dofile fails for scripts outside scripts/.
-- Point arg[0] at wa_factory.lua for the duration of the load, then restore it.
local SCRIPTS = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local realArg0 = arg and arg[0]
if arg then arg[0] = SCRIPTS .. "/wa_factory.lua" end
local F = dofile(SCRIPTS .. "/wa_factory.lua")
if arg then arg[0] = realArg0 end
local W = F.W

local CLASS = "MAGE"
local TOP = "Mage TBC - Arcane & Frost"
local OUT = dir .. "/all-specs.txt"

local byId, order = {}, {}
local function reg(t) byId[t.id] = t; order[#order + 1] = t; return t end
local function adopt(parent, child)
  child.parent = parent.id
  table.insert(parent.controlledChildren, child.id)
end

-- shared bits ---------------------------------------------------------------
local IN_GROUP = { multi = { group = true, raid = true } }  -- party or raid only

local ICE_BARRIER = { 11426, 13031, 13032, 13033, 27134, 33405 }  -- ranks 1-6

local function alertAnims(aura)   -- slide in from below, fly out upward
  aura.animation.start  = F.animPreset("slidebottom", "0.3", "easeOut")
  aura.animation.finish = F.animCustom("1", { y = 150, alpha = 0, scale = 0.4 }, "easeOut")
end

local function polishIcon(icon)   -- crop + 1px outline on every icon
  icon.zoom = 0.3
  table.insert(icon.subRegions, F.subborder())
end

-- ===== top-level group, anchored below the character ========================
-- NOTE: the top group takes the factory's own uid() call (no extra W.uid() here);
-- that choice is permanent — changing it would reshuffle every uid downstream.
local top = F.group(TOP, 0, -140, nil)

-- ===== Resources: health / mana / threat bars, stacked flush ================
local gRes = reg(F.group("Mage - Resources", 0, 56, nil))
adopt(top, gRes)

-- Health: always on; the Unit Characteristics trigger only feeds inCombat.
local hp = reg(F.aurabar("Mage - Health", CLASS, 172, 14, 0, -13, nil, { 0.15, 0.78, 0.25, 1 }))
hp.triggers = F.triggers({ F.healthTrigger(), F.unitCharTrigger() })
hp.subRegions[2] = F.subtext("%percenthealth%%", 12, "INNER_RIGHT", "percenthealth")
hp.subRegions[3] = F.subborder("bar")
hp.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }
adopt(gRes, hp)

-- Mana: the mage's real resource clock — Evocation pacing reads off this bar.
local mana = reg(F.aurabar("Mage - Mana", CLASS, 172, 14, 0, -27, nil, { 0.25, 0.50, 0.95, 1 }))
mana.triggers = F.triggers({ F.powerTrigger(0), F.unitCharTrigger() })
mana.subRegions[2] = F.subtext("%percentpower%%", 12, "INNER_RIGHT", "percentpower")
mana.subRegions[3] = F.subborder("bar")
mana.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }
adopt(gRes, mana)

-- Threat: green -> orange at 70% -> red on aggro. Mage burst has no threat dump.
local threat = reg(F.aurabar("Mage - Threat", CLASS, 172, 14, 0, -41, nil, { 0.25, 0.8, 0.3, 1 }))
threat.triggers = F.triggers({ F.threatTrigger() })
threat.subRegions[2] = F.subtext("%threatpct%%", 12, "INNER_RIGHT", "threatpct")
threat.subRegions[3] = F.subborder("bar")
threat.conditions = {
  F.condition(1, "threatpct", ">=", "70", "barColor", { 1, 0.6, 0.1, 1 }),
  F.condition(1, "aggro", "==", 1, "barColor", { 0.9, 0.12, 0.12, 1 }),  -- severe last
}
adopt(gRes, threat)

-- 80%+ threat: pulsing red overlay on the threat bar, party/raid only.
-- Created after the bars so it layers above them.
local flash = reg(F.texture("Mage - Threat Flash", CLASS, 176, 18, 0, -41, nil,
  F.TEX_SQUARE, { 1, 0.1, 0.1, 0.85 }))
flash.blendMode = "ADD"
flash.triggers = F.triggers({ F.threatTrigger(80) })
flash.animation.main = F.animPreset("alphaPulse", "1")  -- duration required or it is invisible
flash.load.use_ingroup = true
flash.load.ingroup = IN_GROUP
adopt(gRes, flash)

-- ===== Buffs: static timer row (mutually-exclusive specs share the slot) ====
local gBuffs = reg(F.group("Mage - Buffs", 0, -16, nil))
adopt(top, gBuffs)

-- Arcane driver: Arcane Blast stacks (8 s window, each stack +75% mana cost).
-- Glows at 3 = cap reached: keep spamming AB only while burning, else filler.
local ab = reg(F.icon("Mage - Arcane Blast Stacks", CLASS, 40, 40, 0, 0, nil))
ab.triggers = F.triggers({ F.auraTrigger("player", true, { 36032 }) })
ab.subRegions[1] = F.subglow(false, { 0.65, 0.3, 1, 1 })  -- preset color, lit by condition
ab.subRegions[2] = F.subtext("%s", 16, "CENTER")
ab.subRegions[3] = F.subtext("%p", 11, "INNER_BOTTOM")
ab.conditions = { F.condition(1, "stacks", "==", "3", "sub.1.glow", true) }
ab.load.use_spellknown = true
ab.load.spellknown = 12042      -- Arcane Power known == deep-arcane spec gate
adopt(gBuffs, ab)

-- Frost: Ice Barrier uptime (all 6 ranks) — pushback protection = more Frostbolts.
local ib = reg(F.icon("Mage - Ice Barrier", CLASS, 40, 40, 0, 0, nil))
ib.triggers = F.triggers({ F.auraTrigger("player", true, ICE_BARRIER) })
ib.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
ib.load.use_spellknown = true
ib.load.spellknown = 11426
adopt(gBuffs, ib)

-- ===== Alerts: glowing prompt flow beside the character =====================
local gAlerts = reg(F.dynGroup("Mage - Alerts", -150, 96, nil, "UP", "BOTTOM", 6))
adopt(top, gAlerts)

-- Clearcasting: next spell is free — weave it immediately. Icon comes from the aura.
local cc = reg(F.icon("Mage - Clearcasting", CLASS, 40, 40, 0, 0, nil))
cc.triggers = F.triggers({ F.auraTrigger("player", true, { 12536 }) })
cc.subRegions[1] = F.subglow(true, { 1, 0.85, 0.2, 1 })
cc.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
alertAnims(cc)
adopt(gAlerts, cc)

-- Mana < 30% AND Evocation ready, in combat: channel now, not at 0.
local evoTrig = F.powerTrigger(0)
evoTrig.use_percentpower = true
evoTrig.percentpower = "30"
evoTrig.percentpower_operator = "<"
local evo = reg(F.icon("Mage - Evocation Prompt", CLASS, 40, 40, 0, 0, nil))
evo.triggers = F.triggers({ evoTrig, F.cdTrigger(12051, "Evocation", "showOnReady") })
evo.iconSource = 0
evo.displayIcon = "Interface\\Icons\\Spell_Nature_Purge"
evo.cooldown = false
evo.subRegions[1] = F.subglow(true, { 0.3, 0.7, 1, 1 })
evo.load.use_combat = true
alertAnims(evo)
adopt(gAlerts, evo)

-- Barrier fell off AND the 30 s recast is ready, in combat (Frost).
local bmiss = reg(F.icon("Mage - Barrier MISSING", CLASS, 40, 40, 0, 0, nil))
bmiss.triggers = F.triggers({
  F.auraTrigger("player", true, ICE_BARRIER, { matchesShowOn = "showOnMissing" }),
  F.cdTrigger(11426, "Ice Barrier", "showOnReady"),
})
bmiss.iconSource = 0
bmiss.displayIcon = "Interface\\Icons\\Spell_Ice_Lament"
bmiss.cooldown = false
bmiss.subRegions[1] = F.subglow(true, { 0.4, 0.85, 1, 1 })
bmiss.load.use_combat = true
bmiss.load.use_spellknown = true
bmiss.load.spellknown = 11426
alertAnims(bmiss)
adopt(gAlerts, bmiss)

-- HP < 30% AND Ice Block ready, in combat: the panic button (Frost talent in TBC).
local block = reg(F.icon("Mage - Ice Block Prompt", CLASS, 40, 40, 0, 0, nil))
block.triggers = F.triggers({
  F.healthTrigger(30),
  F.cdTrigger(45438, "Ice Block", "showOnReady"),
})
block.iconSource = 0
block.displayIcon = "Interface\\Icons\\Spell_Frost_Frost"
block.cooldown = false
block.subRegions[1] = F.subglow(true, { 0.75, 0.95, 1, 1 })
block.load.use_combat = true
block.load.use_spellknown = true
block.load.spellknown = 45438
alertAnims(block)
adopt(gAlerts, block)

-- Threat >= 70% AND Invisibility ready, in combat, grouped: drop threat or die.
local invis = reg(F.icon("Mage - Invisibility Prompt", CLASS, 40, 40, 0, 0, nil))
invis.triggers = F.triggers({
  F.threatTrigger(70),
  F.cdTrigger(66, "Invisibility", "showOnReady"),
})
invis.iconSource = 0
invis.displayIcon = "Interface\\Icons\\Ability_Mage_Invisibility"
invis.cooldown = false
invis.subRegions[1] = F.subglow(true, { 1, 0.45, 0.1, 1 })
invis.load.use_combat = true
invis.load.use_spellknown = true
invis.load.spellknown = 66
invis.load.use_ingroup = true
invis.load.ingroup = IN_GROUP
alertAnims(invis)
adopt(gAlerts, invis)

-- ===== Cooldowns: one row; talent CDs appear via Spell Known, gaps collapse ==
local gCDs = reg(F.dynGroup("Mage - Cooldowns", 0, -66, nil, "HORIZONTAL", "CENTER", 4))
adopt(top, gCDs)

local cdList = {
  { "Arcane Power",           12042, true  },  -- Arcane 31: 3 min burst
  { "Presence of Mind",       12043, true  },  -- Arcane 21: instant cast, pairs with AP
  { "Icy Veins",              12472, true  },  -- both 40/0/21 arcane and frost talent it
  { "Summon Water Elemental", 31687, true  },  -- Frost 41: 3 min pet
  { "Cold Snap",              11958, true  },  -- Frost 21: 8 min, resets IV + WE
  { "Ice Block",              45438, true  },  -- Frost 31: 5 min immunity
  { "Evocation",              12051, false },  -- 8 min mana refill
  { "Counterspell",           2139,  false },  -- 24 s interrupt
  { "Blink",                  1953,  false },  -- 15 s reposition
  { "Invisibility",           66,    true  },  -- 5 min threat drop (trained at 68)
}
for _, e in ipairs(cdList) do
  local icon = reg(F.icon("Mage CD - " .. e[1], CLASS, 32, 32, 0, 0, nil))
  icon.triggers = F.triggers({ F.cdTrigger(e[2], e[1], "showAlways") })
  icon.cooldownTextDisabled = false   -- swipe numbers here; no %p subtext (OmniCC doubles)
  icon.useTooltip = true
  icon.conditions = { F.condition(1, "onCooldown", "==", 1, "desaturate", true) }
  if e[3] then
    icon.load.use_spellknown = true
    icon.load.spellknown = e[2]
  end
  adopt(gCDs, icon)
end

-- ===== icon polish everywhere ===============================================
for _, aura in ipairs(order) do
  if aura.regionType == "icon" then polishIcon(aura) end
end

-- ===== assemble (v2000 nested), encode, verify, write =======================
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

-- uid continuity vs the previously shipped string, checked BEFORE overwriting,
-- so every future version gets the "same id keeps its uid" check for free.
local cont = W.uidContinuity(encoded, OUT)

local out = io.open(OUT, "w")
out:write(encoded)
out:close()

print(("OK: %d auras (1 top + %d children), %d chars -> all-specs.txt")
  :format(#transmit.c + 1, #transmit.c, #encoded))
if cont then
  print(("uid continuity vs previous: stable=%d changed=%d parentSame=%s")
    :format(cont.stable, cont.changed, tostring(cont.parentSame)))
else
  print("uid continuity: no previous all-specs.txt (first build)")
end
