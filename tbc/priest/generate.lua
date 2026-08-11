-- generate.lua — Priest TBC All-Specs HUD (v1).
-- Run: lua5.1 tbc/priest/generate.lua   (works from any cwd; paths resolve from this file)
-- Produces all-specs.txt: a "!WA:2!" string importable in game (/wa -> Import -> paste).
--
-- Design: the proven rogue/paladin skeleton adapted to priest. Shadow drives the
-- DoT/threat side; Holy and Discipline pieces load through spellknown gates, so a
-- single pack auto-adapts on respec with no user action. Mutually exclusive spec
-- elements share screen slots (SW:P and Weakened Soul both sit at x=-66).
--
-- Every spell id below was verified on wowhead.com/tbc: aura triggers carry EVERY
-- rank id (as strings, via the factory), cooldown triggers carry the numeric rank-1
-- id, spellknown gates use ids that are really in the spellbook when talented.
-- Zero custom code, zero name matching (zhCN-safe), internalVersion stays 45.

math.randomseed(20260815)  -- FIXED pack seed; the uid() call order below is append-only forever

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
-- wa_factory.lua resolves wa_lib.lua and assets/icon_proto.lua from arg[0]'s
-- directory, so a bare relative dofile fails when the build script lives outside
-- scripts/. Point arg[0] at the factory for the duration of the load, then restore.
local factoryPath = dir .. "/../../tools/tbc-weakaura-creator/scripts/wa_factory.lua"
local realArg0 = arg[0]
arg[0] = factoryPath
local F = dofile(factoryPath)
arg[0] = realArg0
local W = F.W

local CLASS = "PRIEST"
local TOP = "Priest TBC - All Specs"

local byId = {}
local icons = {}  -- ordered icon list for the polish pass (deterministic iteration)
local function reg(t)
  byId[t.id] = t
  if t.regionType == "icon" then icons[#icons + 1] = t end
  return t
end
local function adopt(parent, child)
  child.parent = parent.id
  table.insert(parent.controlledChildren, child.id)
end

-- alert flow: slide in from below, fly up and shrink out when handled
local function alertAnimations(a)
  a.animation.start = F.animPreset("slidebottom", "0.3", "easeOut")
  a.animation.finish = F.animCustom("1", { y = 150, alpha = 0, scale = 0.4 }, "easeOut")
end

-- ===== top-level group, anchored below the character =====
local top = F.group(TOP, 0, -140, nil)
top.uid = W.uid()

-- =====================================================================
-- Resources (0,56): health / mana / threat, 172x14 bars stacked flush
-- =====================================================================
local gRes = reg(F.group("Priest - Resources", 0, 56, nil))
adopt(top, gRes)

-- health: always on; trigger 2 (Unit Characteristics) feeds the inCombat fade
local health = reg(F.aurabar("Priest - Health", CLASS, 172, 14, 0, -13, nil,
  { 0.15, 0.78, 0.25, 1 }))
health.triggers = F.triggers({ F.healthTrigger(nil), F.unitCharTrigger() })
health.subRegions[2] = F.subtext("%percenthealth%%", 12, "INNER_RIGHT", "percenthealth")
health.subRegions[3] = F.subborder("bar")
health.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }
adopt(gRes, health)

-- mana: the resource all three specs plan around
local mana = reg(F.aurabar("Priest - Mana", CLASS, 172, 14, 0, -27, nil,
  { 0.25, 0.5, 0.92, 1 }))
mana.triggers = F.triggers({ F.powerTrigger(0), F.unitCharTrigger() })
mana.subRegions[2] = F.subtext("%percentpower%%", 12, "INNER_RIGHT", "percentpower")
mana.subRegions[3] = F.subborder("bar")
mana.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }
adopt(gRes, mana)

-- threat: a bare threat trigger is only active with a hostile target, so the bar
-- self-hides out of combat (no fade condition needed). Green -> orange at 70% ->
-- red on aggro; conditions run in order, so the most severe one is last.
local threat = reg(F.aurabar("Priest - Threat", CLASS, 172, 14, 0, -41, nil,
  { 0.25, 0.8, 0.3, 1 }))
threat.triggers = F.triggers({ F.threatTrigger(nil) })
threat.subRegions[2] = F.subtext("%threatpct%%", 12, "INNER_RIGHT", "threatpct")
threat.subRegions[3] = F.subborder("bar")
threat.conditions = {
  F.condition(1, "threatpct", ">=", "70", "barColor", { 1, 0.6, 0.1, 1 }),
  F.condition(1, "aggro", "==", 1, "barColor", { 0.9, 0.12, 0.12, 1 }),
}
adopt(gRes, threat)

-- =====================================================================
-- Buffs (0,-16): static row of 40x40 aura timers at x = -66/-22/22/66
-- =====================================================================
local gBuffs = reg(F.group("Priest - Buffs", 0, -16, nil))
adopt(top, gBuffs)

-- Shadow Word: Pain — own DoT on the target, all 10 ranks; glows at <=3s left
local swp = reg(F.icon("Priest - Shadow Word Pain", CLASS, 40, 40, -66, 0, nil))
swp.triggers = F.triggers({
  F.auraTrigger("target", false, {
    589, 594, 970, 992, 2767, 10892, 10893, 10894, 25367, 25368,
  }, { ownOnly = true }),
})
swp.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
swp.conditions = { F.condition(1, "expirationTime", "<=", "3", "sub.1.glow", true) }
swp.load.use_spellknown = true
swp.load.spellknown = 15473  -- Shadowform: Shadow-only slot (shares x=-66 with Weakened Soul)
adopt(gBuffs, swp)

-- Vampiric Touch — own DoT, 3 ranks; rank 1 doubles as the talent gate
local vt = reg(F.icon("Priest - Vampiric Touch", CLASS, 40, 40, -22, 0, nil))
vt.triggers = F.triggers({
  F.auraTrigger("target", false, { 34914, 34916, 34917 }, { ownOnly = true }),
})
vt.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
vt.conditions = { F.condition(1, "expirationTime", "<=", "3", "sub.1.glow", true) }
vt.load.use_spellknown = true
vt.load.spellknown = 34914
adopt(gBuffs, vt)

-- Vampiric Embrace — own debuff on the boss (raid heal / mana loop), single rank
local ve = reg(F.icon("Priest - Vampiric Embrace", CLASS, 40, 40, 22, 0, nil))
ve.triggers = F.triggers({
  F.auraTrigger("target", false, { 15286 }, { ownOnly = true }),
})
ve.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
ve.load.use_spellknown = true
ve.load.spellknown = 15286
adopt(gBuffs, ve)

-- Weakened Soul on the player — Discipline self-shield cadence. NOT ownOnly (any
-- priest's shield applies it). Same slot as SW:P; the two gates never coexist.
local wsoul = reg(F.icon("Priest - Weakened Soul", CLASS, 40, 40, -66, 0, nil))
wsoul.triggers = F.triggers({
  F.auraTrigger("player", false, { 6788 }),
})
wsoul.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
wsoul.load.use_spellknown = true
wsoul.load.spellknown = 33206  -- Pain Suppression: the Discipline 41-pt signature
adopt(gBuffs, wsoul)

-- Inner Fire — all 7 ranks: %s = charges left, %p = time left. Every spec keeps it up.
local innerfire = reg(F.icon("Priest - Inner Fire", CLASS, 40, 40, 66, 0, nil))
innerfire.triggers = F.triggers({
  F.auraTrigger("player", true, { 588, 7128, 602, 1006, 10951, 10952, 25431 }),
})
innerfire.subRegions[2] = F.subtext("%s", 16, "CENTER")
innerfire.subRegions[3] = F.subtext("%p", 11, "INNER_BOTTOM")
adopt(gBuffs, innerfire)

-- =====================================================================
-- Alerts (-150,96): vertical prompt flow, glowing icons, animated in/out
-- =====================================================================
local gAlerts = reg(F.dynGroup("Priest - Alerts", -150, 96, nil, "UP", "BOTTOM", 6))
adopt(top, gAlerts)

-- Shadowform dropped while in combat (Shadow only)
local sform = reg(F.icon("Priest - Shadowform MISSING", CLASS, 40, 40, 0, 0, nil))
sform.triggers = F.triggers({
  F.auraTrigger("player", true, { 15473 }, { matchesShowOn = "showOnMissing" }),
})
sform.iconSource = 0
sform.displayIcon = "Interface\\Icons\\spell_shadow_shadowform"
sform.cooldown = false
sform.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
sform.load.use_combat = true
sform.load.use_spellknown = true
sform.load.spellknown = 15473
alertAnimations(sform)
adopt(gAlerts, sform)

-- mana < 30% AND Shadowfiend ready -> send the fiend (percent-based, so it works
-- at any mana pool size); both triggers must hold (disjunctive "all")
local sfiend = reg(F.icon("Priest - Shadowfiend Prompt", CLASS, 40, 40, 0, 0, nil))
local sfiendPower = F.powerTrigger(0)
sfiendPower.use_percentpower = true
sfiendPower.percentpower = "30"
sfiendPower.percentpower_operator = "<"
sfiend.triggers = F.triggers({
  sfiendPower,
  F.cdTrigger(34433, "Shadowfiend", "showOnReady"),
})
sfiend.iconSource = 0
sfiend.displayIcon = "Interface\\Icons\\spell_shadow_shadowfiend"
sfiend.cooldown = false
sfiend.subRegions[1] = F.subglow(true, { 0.55, 0.35, 1, 1 })
sfiend.load.use_combat = true
sfiend.load.use_spellknown = true
sfiend.load.spellknown = 34433  -- level-66 baseline; the gate just hides it for lowbies
alertAnimations(sfiend)
adopt(gAlerts, sfiend)

-- threat >= 70% AND Fade ready -> dump threat now. No combat gate needed: the
-- threat trigger is only active with a hostile target in the first place.
local fade = reg(F.icon("Priest - Fade Prompt", CLASS, 40, 40, 0, 0, nil))
fade.triggers = F.triggers({
  F.threatTrigger(70),
  F.cdTrigger(586, "Fade", "showOnReady"),
})
fade.iconSource = 0
fade.displayIcon = "Interface\\Icons\\spell_magic_lesserinvisibilty"  -- that misspelling is the real filename
fade.cooldown = false
fade.subRegions[1] = F.subglow(true, { 1, 0.45, 0.1, 1 })
fade.load.use_spellknown = true
fade.load.spellknown = 586
alertAnimations(fade)
adopt(gAlerts, fade)

-- HP < 40% AND Desperate Prayer ready -> emergency self-heal. Racial spell: the
-- spellknown gate simply never loads it for races that do not learn it.
local dprayer = reg(F.icon("Priest - Desperate Prayer Prompt", CLASS, 40, 40, 0, 0, nil))
dprayer.triggers = F.triggers({
  F.healthTrigger(40),
  F.cdTrigger(13908, "Desperate Prayer", "showOnReady"),
})
dprayer.iconSource = 0
dprayer.displayIcon = "Interface\\Icons\\spell_holy_restoration"
dprayer.cooldown = false
dprayer.subRegions[1] = F.subglow(true, { 0.3, 1, 0.5, 1 })
dprayer.load.use_combat = true
dprayer.load.use_spellknown = true
dprayer.load.spellknown = 13908
alertAnimations(dprayer)
adopt(gAlerts, dprayer)

-- =====================================================================
-- Cooldowns (0,-66): horizontal row, swipe numbers on, desaturate while down
-- =====================================================================
local gCDs = reg(F.dynGroup("Priest - Cooldowns", 0, -66, nil, "HORIZONTAL", "CENTER", 4))
gCDs.animate = false
adopt(top, gCDs)

local function addCD(id, name, spellId, gate)
  local icon = reg(F.icon("Priest CD - " .. id, CLASS, 32, 32, 0, 0, nil))
  icon.triggers = F.triggers({ F.cdTrigger(spellId, name, "showAlways") })
  icon.cooldownTextDisabled = false  -- swipe numbers on; no %p subtext (OmniCC double-number trap)
  icon.useTooltip = true
  icon.conditions = { F.condition(1, "onCooldown", "==", 1, "desaturate", true) }
  if gate then
    icon.load.use_spellknown = true
    icon.load.spellknown = gate
  end
  adopt(gCDs, icon)
  return icon
end

addCD("Mind Blast",        "Mind Blast",          8092, 15473)  -- Shadow rotational (8s CD)
addCD("Shadow Word Death", "Shadow Word: Death", 32379, 15473)  -- Shadow rotational (lvl 62 baseline, Shadow-gated)
addCD("Shadowfiend",       "Shadowfiend",        34433, 34433)  -- all specs, 5 min
addCD("Prayer of Mending", "Prayer of Mending",  33076, 33076)  -- Holy/Disc staple, 10s CD
addCD("Inner Focus",       "Inner Focus",        14751, 14751)  -- Disc tier-2 talent, taken by Holy too
addCD("Power Infusion",    "Power Infusion",     10060, 10060)  -- Disc 31-pt talent, 3 min
addCD("Pain Suppression",  "Pain Suppression",   33206, 33206)  -- Disc 41-pt signature, 2 min
addCD("Lightwell",         "Lightwell",            724,   724)  -- Holy 40-pt optional talent
addCD("Fear Ward",         "Fear Ward",           6346,  6346)  -- baseline for every priest since 2.3.0 (lvl 20, 3 min CD)

-- =====================================================================
-- Procs (110,24): cloned proc icons, one per active Holy proc
-- =====================================================================
local gProcs = reg(F.dynGroup("Priest - Procs", 110, 24, nil, "RIGHT", "LEFT", 4))
adopt(top, gProcs)

local procs = reg(F.icon("Priest - Holy Procs", CLASS, 32, 32, 0, 0, nil))
procs.triggers = F.triggers({
  -- 33151 Surge of Light (free instant Smite), 34754 Clearcasting (Holy Concentration).
  -- No load gate: the icon exists only while one of those buffs does.
  F.auraTrigger("player", true, { 33151, 34754 }, { showClones = true }),
})
procs.subRegions[1] = F.subglow(true, { 1, 0.85, 0.2, 1 })
procs.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
procs.animation.start = F.animCustom("0.5", { alpha = 0, alphaType = "alphaPulse", scale = 1.5 }, "easeOut")
procs.animation.finish = F.animCustom("0.8", { x = 120, alpha = 0 }, "easeOut")
adopt(gProcs, procs)

-- ===== icon polish: crop + 1px outline on every icon =====
for _, icon in ipairs(icons) do
  icon.zoom = 0.3
  table.insert(icon.subRegions, F.subborder())
end

-- ===== assemble (v2000 nested), encode, verify =====
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

-- uid continuity against the previous on-disk version, measured BEFORE the file is
-- overwritten, so every future re-run is checked against the string that shipped
local txtPath = dir .. "/all-specs.txt"
local cont = W.uidContinuity(encoded, txtPath)

local out = assert(io.open(txtPath, "w"))
out:write(encoded)  -- single line, no trailing newline
out:close()

print(("OK: %d auras (top group + %d children), %d chars -> all-specs.txt")
  :format(#transmit.c + 1, #transmit.c, #encoded))
if cont then
  print(("uid continuity vs previous: stable=%d changed=%d parentSame=%s")
    :format(cont.stable, cont.changed, tostring(cont.parentSame)))
end
