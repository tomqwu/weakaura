-- generate.lua — Druid TBC "All Specs" HUD (v1).
-- Run: lua5.1 generate.lua   (toolkit libs live in ../../tools/tbc-weakaura-creator/scripts/,
-- fetch them once with that directory's setup.sh)
-- Produces all-specs.txt: a "!WA:2!" string importable in game (copy whole -> /wa -> Import).
--
-- Covers Feral tank (bear), Restoration and Balance in ONE pack: every spec-specific element
-- is load-gated with use_spellknown on that spec's signature ability, and mutually exclusive
-- elements share screen slots. Zero custom code anywhere.
--
-- Every spell id below was verified on wowhead.com/tbc (2.4.3 data): aura triggers carry
-- EVERY rank id as strings; cooldown triggers carry the numeric rank-1 id; spellknown gates
-- use a castable spell that is in the spellbook whenever the talent is taken.

math.randomseed(20260812)  -- FIXED pack seed; append-only uid order across versions
local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
-- wa_factory resolves wa_lib.lua and ../assets/icon_proto.lua from arg[0]'s directory,
-- so point arg[0] at the toolkit for the dofile, then restore the original.
local toolDir = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local arg0 = arg[0]
arg[0] = toolDir .. "/wa_factory.lua"
local F = dofile(toolDir .. "/wa_factory.lua")
arg[0] = arg0
local W = F.W

local CLASS = "DRUID"
local TOP = "Druid TBC - All Specs"

local byId = {}
local function reg(t) byId[t.id] = t; return t end
local function adopt(parent, child)
  child.parent = parent.id
  table.insert(parent.controlledChildren, child.id)
end

-- ===== spec gates (castable signature abilities, verified on wowhead.com/tbc) =====
local GATE_F = { use_spellknown = true, spellknown = 33878 }  -- Mangle (Bear)  — Feral 41
local GATE_R = { use_spellknown = true, spellknown = 18562 }  -- Swiftmend      — Resto 21
local GATE_B = { use_spellknown = true, spellknown = 24858 }  -- Moonkin Form   — Balance 31

-- ===== verified spell ids =====
local IDS_LACERATE  = { 33745 }                                -- 15s bleed, single TBC rank
local IDS_MANGLE    = { 33878, 33986, 33987 }                  -- Mangle (Bear) r1-r3
local IDS_FAERIE    = { 770, 778, 9749, 9907, 26993,           -- Faerie Fire r1-r5
                        16857, 17390, 17391, 17392, 27011 }    -- Faerie Fire (Feral) r1-r5
local IDS_LIFEBLOOM = { 33763 }                                -- 7s HoT, stacks to 3
local IDS_REJUV     = { 774, 1058, 1430, 2090, 2091, 3627, 8910,
                        9839, 9840, 9841, 25299, 26981, 26982 }  -- Rejuvenation r1-r13
local IDS_REGROWTH  = { 8936, 8938, 8939, 8940, 8941,
                        9750, 9856, 9857, 9858, 26980 }        -- Regrowth r1-r10
local IDS_INSECT    = { 5570, 24974, 24975, 24976, 24977, 27013 }  -- Insect Swarm r1-r6
local IDS_MOONFIRE  = { 8921, 8924, 8925, 8926, 8927, 8928, 8929,
                        9833, 9834, 9835, 26987, 26988 }       -- Moonfire r1-r12
local IDS_CLEARCAST = { 16870 }                                -- Clearcasting proc, 15s
local IDS_OOC       = { 16864 }                                -- Omen of Clarity, 30min

local CD_MANGLE    = 33878  -- rank-1 cooldown ids (cooldown is shared across ranks)
local CD_ENRAGE    = 5229
local CD_FRENZIED  = 22842
local CD_SWIFTMEND = 18562
local CD_NSWIFT    = 17116
local CD_TREANTS   = 33831
local CD_BARKSKIN  = 22812
local CD_INNERVATE = 29166

-- ===== groups (uid order is sacred: top, 4 sub-groups, then R / B / A / C) =====
local top     = F.group(TOP, 0, -140, nil)
local gRes    = reg(F.group("Druid - Resources", 0, 56, nil))
local gBuffs  = reg(F.group("Druid - Buffs", 0, -16, nil))
local gAlerts = reg(F.dynGroup("Druid - Alerts", -150, 96, nil, "UP", "BOTTOM", 6))
local gCDs    = reg(F.dynGroup("Druid - Cooldowns", 0, -66, nil, "HORIZONTAL", "CENTER", 4))
adopt(top, gRes)
adopt(top, gBuffs)
adopt(top, gAlerts)
adopt(top, gCDs)

-- ================= Resources (0,56): 172x14 bars stacked flush =================
local function resBar(id, y, color, gate)
  local b = reg(F.aurabar(id, CLASS, 172, 14, 0, y, nil, color))
  b.load = F.load(CLASS, gate)
  adopt(gRes, b)
  return b
end

-- R1 Health — all specs, always on, fades out of combat
local hp = resBar("Druid - Health", -13, { 0.15, 0.78, 0.25, 1 }, nil)
hp.triggers = F.triggers({ F.healthTrigger(), F.unitCharTrigger() })
hp.subRegions[2] = F.subtext("%percenthealth%%", 12, "INNER_RIGHT", "percenthealth")
hp.subRegions[3] = F.subborder("bar")
hp.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }

-- R2 Rage (bear) — shares the primary power slot with the two mana bars
local rage = resBar("Druid - Rage", -27, { 0.85, 0.15, 0.15, 1 }, GATE_F)
rage.triggers = F.triggers({ F.powerTrigger(1), F.unitCharTrigger() })
rage.subRegions[2] = F.subtext("%p", 12, "INNER_RIGHT")
rage.subRegions[3] = F.subborder("bar")
rage.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }

-- R3 Mana (Resto)
local manaR = resBar("Druid - Mana (Resto)", -27, { 0.25, 0.5, 0.9, 1 }, GATE_R)
manaR.triggers = F.triggers({ F.powerTrigger(0), F.unitCharTrigger() })
manaR.subRegions[2] = F.subtext("%percentpower%%", 12, "INNER_RIGHT", "percentpower")
manaR.subRegions[3] = F.subborder("bar")
manaR.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }

-- R4 Mana (Balance) — identical to R3 but Balance-gated; a resto/balance hybrid sees
-- both, pixel-identical on the same slot (harmless by design)
local manaB = resBar("Druid - Mana (Balance)", -27, { 0.25, 0.5, 0.9, 1 }, GATE_B)
manaB.triggers = F.triggers({ F.powerTrigger(0), F.unitCharTrigger() })
manaB.subRegions[2] = F.subtext("%percentpower%%", 12, "INNER_RIGHT", "percentpower")
manaB.subRegions[3] = F.subborder("bar")
manaB.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }

-- R5 Threat (Bear) — tank-inverted semantics: green while tanking, RED when aggro is lost
local threatF = resBar("Druid - Threat (Bear)", -41, { 0.25, 0.8, 0.3, 1 }, GATE_F)
threatF.triggers = F.triggers({ F.threatTrigger() })
threatF.subRegions[2] = F.subtext("%threatpct%%", 12, "INNER_RIGHT", "threatpct")
threatF.subRegions[3] = F.subborder("bar")
threatF.conditions = { F.condition(1, "aggro", "==", 0, "barColor", { 0.9, 0.12, 0.12, 1 }) }

-- R6 Threat (Caster) — orange at 70%, red on aggro (severe condition last)
local threatB = resBar("Druid - Threat (Caster)", -41, { 0.25, 0.8, 0.3, 1 }, GATE_B)
threatB.triggers = F.triggers({ F.threatTrigger() })
threatB.subRegions[2] = F.subtext("%threatpct%%", 12, "INNER_RIGHT", "threatpct")
threatB.subRegions[3] = F.subborder("bar")
threatB.conditions = {
  F.condition(1, "threatpct", ">=", "70", "barColor", { 1, 0.6, 0.1, 1 }),
  F.condition(1, "aggro", "==", 1, "barColor", { 0.9, 0.12, 0.12, 1 }),
}

-- ================= Buffs (0,-16): three 40x40 timers per spec, slots shared =================
local function buffIcon(id, x, gate)
  local ic = reg(F.icon(id, CLASS, 40, 40, x, 0, nil))
  ic.zoom = 0.3
  ic.load = F.load(CLASS, gate)
  adopt(gBuffs, ic)
  return ic
end

-- B1 Lacerate — stacks to 5 (%s) + timer, glow inside the refresh window
local lacerate = buffIcon("Druid - Lacerate", -44, GATE_F)
lacerate.triggers = F.triggers({ F.auraTrigger("target", false, IDS_LACERATE, { ownOnly = true }) })
lacerate.subRegions[2] = F.subtext("%s", 16, "CENTER")
lacerate.subRegions[3] = F.subtext("%p", 11, "INNER_BOTTOM")
lacerate.subRegions[4] = F.subborder()
lacerate.conditions = { F.condition(1, "expirationTime", "<=", "5", "sub.1.glow", true) }

-- B2 Mangle debuff — uptime awareness only; C1 is what you actually press
local mangle = buffIcon("Druid - Mangle Debuff", 0, GATE_F)
mangle.triggers = F.triggers({ F.auraTrigger("target", false, IDS_MANGLE, { ownOnly = true }) })
mangle.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
mangle.subRegions[3] = F.subborder()

-- B3 Faerie Fire (Bear) — ANY caster's FF or FFF satisfies the armor debuff rule
local ffF = buffIcon("Druid - Faerie Fire (Bear)", 44, GATE_F)
ffF.triggers = F.triggers({ F.auraTrigger("target", false, IDS_FAERIE) })
ffF.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
ffF.subRegions[3] = F.subborder()
ffF.conditions = { F.condition(1, "expirationTime", "<=", "5", "sub.1.glow", true) }

-- B4 Lifebloom — stacks (%s) + timer on your friendly target; glow = roll it NOW
local lifebloom = buffIcon("Druid - Lifebloom", -44, GATE_R)
lifebloom.triggers = F.triggers({ F.auraTrigger("target", true, IDS_LIFEBLOOM, { ownOnly = true }) })
lifebloom.subRegions[2] = F.subtext("%s", 16, "CENTER")
lifebloom.subRegions[3] = F.subtext("%p", 11, "INNER_BOTTOM")
lifebloom.subRegions[4] = F.subborder()
lifebloom.conditions = { F.condition(1, "expirationTime", "<=", "2", "sub.1.glow", true) }

-- B5 Rejuvenation — own HoT on target, all 13 ranks (downranking-safe); Swiftmend fuel
local rejuv = buffIcon("Druid - Rejuvenation", 0, GATE_R)
rejuv.triggers = F.triggers({ F.auraTrigger("target", true, IDS_REJUV, { ownOnly = true }) })
rejuv.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
rejuv.subRegions[3] = F.subborder()

-- B6 Regrowth — own HoT on target, all 10 ranks; the other Swiftmend fuel
local regrowth = buffIcon("Druid - Regrowth", 44, GATE_R)
regrowth.triggers = F.triggers({ F.auraTrigger("target", true, IDS_REGROWTH, { ownOnly = true }) })
regrowth.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
regrowth.subRegions[3] = F.subborder()

-- B7 Insect Swarm — refresh early (glow at 3s), especially while moving
local swarm = buffIcon("Druid - Insect Swarm", -44, GATE_B)
swarm.triggers = F.triggers({ F.auraTrigger("target", false, IDS_INSECT, { ownOnly = true }) })
swarm.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
swarm.subRegions[3] = F.subborder()
swarm.conditions = { F.condition(1, "expirationTime", "<=", "3", "sub.1.glow", true) }

-- B8 Moonfire — NO expiry glow on purpose: let it fully expire, then recast
local moonfire = buffIcon("Druid - Moonfire", 0, GATE_B)
moonfire.triggers = F.triggers({ F.auraTrigger("target", false, IDS_MOONFIRE, { ownOnly = true }) })
moonfire.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
moonfire.subRegions[3] = F.subborder()

-- B9 Faerie Fire (Balance) — same combined FF+FFF set as B3 (Improved FF hit debuff)
local ffB = buffIcon("Druid - Faerie Fire (Balance)", 44, GATE_B)
ffB.triggers = F.triggers({ F.auraTrigger("target", false, IDS_FAERIE) })
ffB.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
ffB.subRegions[3] = F.subborder()
ffB.conditions = { F.condition(1, "expirationTime", "<=", "5", "sub.1.glow", true) }

-- ================= Alerts (-150,96): glowing prompts, grow UP =================
local function alertIcon(id, gate)
  local a = reg(F.icon(id, CLASS, 40, 40, 0, 0, nil))
  a.zoom = 0.3
  a.load = F.load(CLASS, gate)
  a.animation.start = F.animPreset("slidebottom", "0.3", "easeOut")
  a.animation.finish = F.animCustom("1", { y = 150, alpha = 0, scale = 0.4 }, "easeOut")
  adopt(gAlerts, a)
  return a
end

-- A1 HP < 40% AND Frenzied Regeneration ready (bear panic button)
local frenzyPrompt = alertIcon("Druid - Frenzied Regen Prompt",
  { use_spellknown = true, spellknown = 33878, use_combat = true })
frenzyPrompt.triggers = F.triggers({
  F.healthTrigger(40),
  F.cdTrigger(CD_FRENZIED, "Frenzied Regeneration", "showOnReady"),
})
frenzyPrompt.iconSource = 0
frenzyPrompt.displayIcon = "Interface\\Icons\\ability_bullrush"
frenzyPrompt.cooldown = false
frenzyPrompt.subRegions[1] = F.subglow(true, { 0.3, 1, 0.4, 1 })
frenzyPrompt.subRegions[2] = F.subborder()

-- A2 Clearcasting proc — free cast, 15s window (swipe shows it)
local clearcast = alertIcon("Druid - Clearcasting",
  { use_spellknown = true, spellknown = 16864, use_combat = true })
clearcast.triggers = F.triggers({ F.auraTrigger("player", true, IDS_CLEARCAST) })
clearcast.subRegions[1] = F.subglow(true, { 1, 0.85, 0.2, 1 })
clearcast.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
clearcast.subRegions[3] = F.subborder()

-- A3 Omen of Clarity missing in combat — "you forgot to buff it"
local oocMissing = alertIcon("Druid - OoC Missing",
  { use_spellknown = true, spellknown = 16864, use_combat = true })
oocMissing.triggers = F.triggers({
  F.auraTrigger("player", true, IDS_OOC, { matchesShowOn = "showOnMissing" }),
})
oocMissing.iconSource = 0
oocMissing.displayIcon = "Interface\\Icons\\spell_nature_crystalball"
oocMissing.cooldown = false
oocMissing.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
oocMissing.subRegions[2] = F.subborder()

-- A4 mana < 20% AND Innervate ready (no spec gate: any druid should press it)
local innervatePrompt = alertIcon("Druid - Innervate Prompt", { use_combat = true })
local lowMana = F.powerTrigger(0)
lowMana.use_percentpower = true
lowMana.percentpower = "20"
lowMana.percentpower_operator = "<"
innervatePrompt.triggers = F.triggers({
  lowMana,
  F.cdTrigger(CD_INNERVATE, "Innervate", "showOnReady"),
})
innervatePrompt.iconSource = 0
innervatePrompt.displayIcon = "Interface\\Icons\\spell_nature_lightning"
innervatePrompt.cooldown = false
innervatePrompt.subRegions[1] = F.subglow(true, { 0.4, 0.7, 1, 1 })
innervatePrompt.subRegions[2] = F.subborder()

-- ================= Cooldowns (0,-66): 32x32 row, desaturate while down =================
local function addCD(label, realName, spellId, gate)
  local ic = reg(F.icon("Druid CD - " .. label, CLASS, 32, 32, 0, 0, nil))
  ic.zoom = 0.3
  ic.triggers = F.triggers({ F.cdTrigger(spellId, realName, "showAlways") })
  ic.cooldownTextDisabled = false   -- WA prints the CD number; no %p subtext (OmniCC)
  ic.useTooltip = true
  ic.conditions = { F.condition(1, "onCooldown", "==", 1, "desaturate", true) }
  ic.load = F.load(CLASS, gate)
  ic.subRegions[2] = F.subborder()
  adopt(gCDs, ic)
  return ic
end

addCD("Mangle",             "Mangle (Bear)",         CD_MANGLE,    GATE_F)  -- C1
addCD("Enrage",             "Enrage",                CD_ENRAGE,    GATE_F)  -- C2
addCD("Frenzied Regen",     "Frenzied Regeneration", CD_FRENZIED,  GATE_F)  -- C3
addCD("Swiftmend",          "Swiftmend",             CD_SWIFTMEND, GATE_R)  -- C4
addCD("Nature's Swiftness", "Nature's Swiftness",    CD_NSWIFT,
  { use_spellknown = true, spellknown = 17116 })                            -- C5
addCD("Force of Nature",    "Force of Nature",       CD_TREANTS,
  { use_spellknown = true, spellknown = 33831 })                            -- C6
addCD("Barkskin",           "Barkskin",              CD_BARKSKIN,  nil)     -- C7
addCD("Innervate",          "Innervate",             CD_INNERVATE, nil)     -- C8

-- ================= assemble (v2000 nested), encode, verify, write =================
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

local txtPath = dir .. "/all-specs.txt"
-- continuity vs the PREVIOUS shipped string (read before overwriting it)
local cont = W.uidContinuity(encoded, txtPath)

local out = io.open(txtPath, "w")
out:write(encoded)  -- single line, no trailing newline
out:close()

print(("OK: %d auras (%d children + top), %d chars -> all-specs.txt")
  :format(#transmit.c + 1, #transmit.c, #encoded))
if cont then
  print(("uid continuity vs previous: stable=%d changed=%d parentSame=%s")
    :format(cont.stable, cont.changed, tostring(cont.parentSame)))
end
