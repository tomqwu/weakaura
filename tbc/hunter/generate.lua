-- generate.lua — Hunter TBC HUD, Beast Mastery & Survival (v5).
-- Run: lua5.1 tbc/hunter/generate.lua   (toolkit libs must be fetched once:
--      tools/tbc-weakaura-creator/scripts/setup.sh)
-- Produces all-specs.txt: a "!WA:2!" string importable in game.
--
-- Rotation-first: every element below maps to one line of the BM (41/20/0) or
-- SV (0/20/41) raid priority; anything that does not change the next button
-- pressed was cut.
--
-- v2 rotation fixes (see README "v2 — rotation fixes"):
--   * Arcane Shot joins the cooldown row (the OR-partner of Multi-Shot).
--   * Back to Hawk closes the aspect-swap loop (Viper up AND mana recovered).
--   * Misdirection prompt is the paired ability for the 70% threat tier;
--     Feign Death moved to 90% and is now combat + group gated.
--   * Mend Pet / Revive Pet prompts: the pet is ~35-40% of BM damage and the
--     prerequisite for Kill Command (unit = "pet" is a first-class WA unit).
--   * Rapid Fire and Bestial Wrath icons now own their ACTIVE window as well
--     as their cooldown (first-active trigger mode: buff first, cooldown second).
--   * Viper threshold 15% -> 20%; Kill Command also opens on a melee crit.
--
-- v3 spec audit (see README "v3 — spec-selective loading"): gating only, no new
-- elements, no removals, no uid changes. BM and SV run the same shots (Steady Shot
-- weave, Multi-Shot on cd, Kill Command on crit, Serpent/Arcane on the move, one
-- pet, Viper for mana), so the shared core is legitimately large and stays shared.
-- The single leak was Expose Weakness: a Survival-talent debuff sitting in the
-- ungated set, i.e. loading for Beast Mastery, which cannot apply it. It is now
-- inverse-gated off Bestial Wrath.
--
-- v4 PvP layer (see README "v4 — PvP layer"): twelve new auras, every one of them
-- load-gated to arena/battleground, so nothing about the PvE HUD changes. Elements
-- that read arena1..arena5 are arena-ONLY (those unit ids do not exist in a BG).
-- Zero custom code was added: every new composite is a plain AND or OR of triggers.
--
-- v5 (see README "v5 — the CC glow speaks, and the arena stops lying"): one new aura
-- and two changed elements, all three from a source verification of things v4 deferred.
--   * CC ON ME is now colour-coded by controlType: the glow says which BREAK works
--     before you have read a single word. sub.1.glowColor is a real, settable
--     condition property (Glow.lua properties table, Conditions.lua sub.N parser) —
--     it is only a no-op when useGlowColor is false, and F.subglow sets that flag
--     whenever a colour is passed, which this element does.
--   * Threat bar and threat flash no longer load in an ARENA. The size load arg has
--     no inverse, so the complement is enumerated; open world is the literal string
--     "none" (GetInstanceTypeAndSize's explicit fallthrough return), so listing it
--     is what keeps both elements loading while questing.
--   * ENEMY MANA: one bar per opponent who actually runs on mana. The Power
--     prototype is NOT pruned on TBC and its unit arg accepts "arena" (the deletion
--     of arena units is gated on IsClassicEra, not IsTBC), so this is a plain
--     multi-unit clone row with zero custom code.
--
-- Every spell id was verified on wowhead.com/tbc. Aura triggers carry EVERY
-- rank as strings; cooldown triggers carry the numeric rank-1 id; spellknown
-- gates use ids that really sit in the spellbook when trained/talented.
--
-- Custom code budget: two one-line customTriggerLogic strings (Kill Command,
-- Mongoose Bite) — the sanctioned OR-of-two-events AND a-state pattern.
--
-- UID ORDER IS SACRED: the seed below and the ORDER of the region constructors
-- (each consumes one W.uid()) must never change. v2 elements are created at the
-- BOTTOM of this file and re-parented into their groups afterwards.

math.randomseed(20260814)  -- FIXED pack seed; append-only uid order across versions

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
-- wa_factory.lua resolves wa_lib.lua and assets/icon_proto.lua relative to
-- arg[0], so point arg[0] at the factory for the dofile, then restore it.
local toolDir = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local savedArg0 = arg and arg[0] or nil
if arg then arg[0] = toolDir .. "/wa_factory.lua" end
local F = dofile(toolDir .. "/wa_factory.lua")
if arg then arg[0] = savedArg0 end
local W = F.W

local CLASS = "HUNTER"
local TOP = "Hunter TBC - BM & Survival"

local byId = {}
local function reg(t) byId[t.id] = t; return t end
local function adopt(parent, child)
  child.parent = parent.id
  table.insert(parent.controlledChildren, child.id)
end

-- ===== verified spell ids =====
local SERPENT = { 1978, 13549, 13550, 13551, 13552, 13553, 13554, 13555, 25295, 27016 } -- r1-r10
local MARK    = { 1130, 14323, 14324, 14325 }                                           -- r1-r4
local HAWK    = { 13165, 14318, 14319, 14320, 14321, 14322, 25296, 27044 }              -- r1-r8
local VIPER   = 34074            -- Aspect of the Viper (single rank, lvl 64)
local TBW     = 34471            -- The Beast Within, the 18s self-buff (talent is 34692)
local EXPOSE  = 34501            -- Expose Weakness, the 7s target debuff (talents 34500/2/3)
local QSHOTS  = 6150             -- Quick Shots (Improved Aspect of the Hawk proc, 12s)
local KILLCMD = 34026            -- Kill Command (lvl 66, after a crit)
local MBITE   = 1495             -- Mongoose Bite (after you dodge)
local FEIGN   = 5384             -- Feign Death (30s cd)
local BWRATH  = 19574            -- Bestial Wrath — also THE Beast Mastery gate
local INTIMID = 19577            -- Intimidation (BM)
local READY   = 23989            -- Readiness (SV 41-pointer)
local WYVERN  = 19386            -- Wyvern Sting (SV 31-pointer, skipped by raid builds)
local RAPID   = 3045             -- Rapid Fire (cd id AND the 15s +40% haste buff)
local MULTI   = 2643             -- Multi-Shot
local MISDIR  = 34477            -- Misdirection (lvl 70)
local ARCANE  = 3044             -- Arcane Shot r1 (6s cd; Multi-Shot's OR-partner)
local MENDPET = 136              -- Mend Pet r1 (no cooldown, 15s channel)
local REVIVE  = 982              -- Revive Pet r1 (the dead-pet answer)

-- ===== v4: verified PvP spell / item ids (wowhead.com/tbc) =====
local SILENCE  = 34490                              -- Silencing Shot (MM 41-pt, 20s cd, 3s silence)
local SCATTER  = 19503                              -- Scatter Shot (SV 20-pt, 30s cd, 4s disorient)
local FRZTRAP  = { 1499, 14310, 14311 }             -- Freezing Trap r1-r3; the TRAP lasts 1 min
local VIPERST  = { 3034, 14279, 14280, 27018 }      -- Viper Sting r1-r4 (8s mana drain)
local WOTF     = 7744                               -- Will of the Forsaken (Undead racial, 2 min)
local PVPTRINK = 42292                              -- "PvP Trinket" — the spell EVERY medallion
                                                    -- and insignia casts (verified on item 37864)
-- The four trinkets a hunter can actually be wearing. Item ids, never names, and never
-- the equipment-slot trigger: that one tracks whatever sits in slot 13/14, so a PvE
-- on-use trinket would report "medallion down" while the medallion is ready — a false
-- negative in the one decision this element exists for.
local TRINKETS = {
  30346,  -- Medallion of the Horde    (lvl 70, 2 min)
  37864,  -- Medallion of the Alliance (lvl 70, 2 min)
  18846,  -- Insignia of the Horde    (Hunter, lvl 60, 5 min)
  18856,  -- Insignia of the Alliance (Hunter, lvl 60, 5 min)
}
-- Hard stops only: while one of these is up, shots and traps do nothing. Mitigation
-- cooldowns are deliberately absent, and so is Deterrence — on 2.4.3 it is +25% parry
-- and dodge, not an immunity, so it does not change which button you press.
local IMMUNE = {
  642, 1020,          -- Divine Shield r1-r2
  1022, 5599, 10278,  -- Blessing of Protection r1-r3 (physical immunity = every shot)
  45438,              -- Ice Block
  31224,              -- Cloak of Shadows
  34471,              -- The Beast Within (their trap/scatter immunity window)
}

-- icons that live in the alert flow all get the same entrance/exit motion
local function alertAnim(a)
  a.animation.start  = F.animPreset("slidebottom", "0.3", "easeOut")
  a.animation.finish = F.animCustom("1", { y = 150, alpha = 0, scale = 0.4 }, "easeOut")
end

-- Threat unit stays the factory's `threatUnit`. That IS the correct key for the
-- internalVersion 45 (WA 3.5.0) data this pack emits: the arg was renamed to plain
-- `unit` only in internalVersion 51, and Modernize.lua migrates < 51 data by copying
-- threatUnit -> unit on import. Writing `unit` here instead is actively wrong — that
-- migration assigns unconditionally, so it would overwrite our value with nil.
local function threatTrigger(minPct)
  return F.threatTrigger(minPct)
end

-- Pet health. unit = "pet" is a first-class WA unit (Types.lua actual_unit_types),
-- and the Health prototype nil-guards percenthealth, so no pet = no state.
local function petHealth(op, pct)
  local tr = F.healthTrigger(nil)
  tr.unit = "pet"
  tr.use_percenthealth = true
  tr.percenthealth = tostring(pct)
  tr.percenthealth_operator = op
  return tr
end

-- ===== 1. top-level group, anchored below the character =====
local top = F.group(TOP, 0, -140, nil)
top.uid = W.uid()

-- ===== 2. Resources: health / mana / threat stacked flush =====
local gRes = reg(F.group("Hunter - Resources", 0, 56, nil))
adopt(top, gRes)

-- 3. health — don't die
local hp = reg(F.aurabar("Hunter - Health", CLASS, 172, 14, 0, -13, nil, { 0.15, 0.78, 0.25, 1 }))
hp.triggers = F.triggers({ F.healthTrigger(nil), F.unitCharTrigger() })
hp.subRegions[2] = F.subtext("%percenthealth%%", 12, "INNER_RIGHT", "percenthealth")
hp.subRegions[3] = F.subborder("bar")
hp.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }
adopt(gRes, hp)

-- 4. mana — the hunter resource; turns red at the Viper threshold (20%: Viper's
--    regen scales off MISSING mana, so swapping at 15% is already late)
local mana = reg(F.aurabar("Hunter - Mana", CLASS, 172, 14, 0, -27, nil, { 0.25, 0.55, 0.95, 1 }))
mana.triggers = F.triggers({ F.powerTrigger(0), F.unitCharTrigger() })
mana.subRegions[2] = F.subtext("%percentpower%%", 12, "INNER_RIGHT", "percentpower")
mana.subRegions[3] = F.subborder("bar")
mana.conditions = {
  F.condition(1, "percentpower", "<", "20", "barColor", { 0.85, 0.2, 0.2, 1 }),
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
}
adopt(gRes, mana)

-- v5: "everywhere except an arena", spelled out. The `size` load arg declares no
-- `inverse` and no `test`, so there is genuinely no "not arena" key — the complement has
-- to be enumerated, and the emitted load test is a plain OR of string compares. `none` is
-- the load-bearing entry: in the open world GetInstanceTypeAndSize returns the literal
-- STRING "none" (its explicit fallthrough return, not nil), so leaving it out would delete
-- the threat bar while questing. `pvp` (battleground) stays in: AV has NPCs and a real
-- threat table. `arena` is the only key left out — an arena has no threat table at all, so
-- there the bar is a dead green rectangle in the slot closest to the crosshair.
local function noArenaSize()
  return { multi = {
    none = true, party = true, ten = true, twenty = true,
    twentyfive = true, fortyman = true, pvp = true,
  } }
end

-- 5. threat — escalating tiers, each one paired with the ability that answers it:
--    orange at 70 (Misdirection prompt), red at 90 (Feign Death prompt), deep red
--    on aggro. Most severe condition last. Group-gated: solo you ARE the threat
--    list, so the bar would sit pegged at 100% in the closest slot to the crosshair.
local threat = reg(F.aurabar("Hunter - Threat", CLASS, 172, 14, 0, -41, nil, { 0.25, 0.8, 0.3, 1 }))
threat.triggers = F.triggers({ threatTrigger(nil) })
threat.subRegions[2] = F.subtext("%threatpct%%", 12, "INNER_RIGHT", "threatpct")
threat.subRegions[3] = F.subborder("bar")
threat.conditions = {
  F.condition(1, "threatpct", ">=", "70", "barColor", { 1, 0.6, 0.1, 1 }),
  F.condition(1, "threatpct", ">=", "90", "barColor", { 0.95, 0.25, 0.1, 1 }),
  F.condition(1, "aggro", "==", 1, "barColor", { 0.9, 0.12, 0.12, 1 }),
}
threat.load.use_ingroup = true
threat.load.ingroup = { multi = { group = true, raid = true } }
threat.load.use_size = false   -- false = MULTI mode (nil would disable the gate)
threat.load.size = noArenaSize()
adopt(gRes, threat)

-- 6. threat >= 80% in a party/raid: pulsing red overlay on the threat bar
local flash = reg(F.texture("Hunter - Threat Flash", CLASS, 176, 18, 0, -41, nil,
  F.TEX_SQUARE, { 1, 0.1, 0.1, 0.85 }))
flash.blendMode = "ADD"
flash.triggers = F.triggers({ threatTrigger(80) })
flash.load.use_ingroup = true
flash.load.ingroup = { multi = { group = true, raid = true } }
flash.load.use_size = false
flash.load.size = noArenaSize()
flash.animation.main = F.animPreset("alphaPulse", "1")
adopt(gRes, flash)

-- ===== 7. Buffs: static row of aura timers =====
local gBuffs = reg(F.group("Hunter - Buffs", 0, -16, nil))
adopt(top, gBuffs)

-- 8. Serpent Sting — own DoT on the target, glows in the refresh window
local serpent = reg(F.icon("Hunter - Serpent Sting", CLASS, 40, 40, -44, 0, nil))
serpent.triggers = F.triggers({ F.auraTrigger("target", false, SERPENT, { ownOnly = true }) })
serpent.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
serpent.conditions = { F.condition(1, "expirationTime", "<=", "3", "sub.1.glow", true) }
serpent.zoom = 0.3
table.insert(serpent.subRegions, F.subborder())
adopt(gBuffs, serpent)

-- 9. Hunter's Mark — any hunter's mark counts, so no ownOnly
local mark = reg(F.icon("Hunter - Hunters Mark", CLASS, 40, 40, 0, 0, nil))
mark.triggers = F.triggers({ F.auraTrigger("target", false, MARK) })
mark.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
mark.zoom = 0.3
table.insert(mark.subRegions, F.subborder())
adopt(gBuffs, mark)

-- 10. The Beast Within — BM burst window (18s). Shares the x=44 slot with SV's
--     Expose Weakness; the two specs are mutually exclusive.
local tbw = reg(F.icon("Hunter - The Beast Within", CLASS, 40, 40, 44, 0, nil))
tbw.triggers = F.triggers({ F.auraTrigger("player", true, { TBW }) })
tbw.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
tbw.zoom = 0.3
table.insert(tbw.subRegions, F.subborder())
tbw.load.use_spellknown = true
tbw.load.spellknown = BWRATH
adopt(gBuffs, tbw)

-- 11. Expose Weakness — the SV raid mandate: keep this 7s debuff at ~100%.
--     The talent is passive, so there is no positive id to gate on. v3 gates it the
--     other way instead: use_not_spellknown = Bestial Wrath hides it from Beast
--     Mastery, the one spec that can never apply it (the proc is a Survival talent,
--     and the trigger is ownOnly). That also makes the shared x=44 slot single-
--     occupancy by LOAD rather than by talent arithmetic — BM sees The Beast Within
--     there, everyone else sees Expose Weakness. Needs WA 5.4.0+; older clients
--     ignore the field and load it for everyone, i.e. exactly the v2 behaviour.
local expose = reg(F.icon("Hunter - Expose Weakness", CLASS, 40, 40, 44, 0, nil))
expose.triggers = F.triggers({ F.auraTrigger("target", false, { EXPOSE }, { ownOnly = true }) })
expose.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
expose.zoom = 0.3
table.insert(expose.subRegions, F.subborder())
expose.load.use_not_spellknown = true
expose.load.not_spellknown = BWRATH
adopt(gBuffs, expose)

-- ===== 12. Alerts: glowing prompts flowing upward beside the character =====
local gAlerts = reg(F.dynGroup("Hunter - Alerts", -150, 96, nil, "UP", "BOTTOM", 6))
adopt(top, gAlerts)

-- 13. no aspect at all (neither Hawk nor Viper), in combat
local aspectIds = {}
for _, id in ipairs(HAWK) do aspectIds[#aspectIds + 1] = id end
aspectIds[#aspectIds + 1] = VIPER
local aspect = reg(F.icon("Hunter - ASPECT MISSING", CLASS, 40, 40, 0, 0, nil))
aspect.triggers = F.triggers({
  F.auraTrigger("player", true, aspectIds, { matchesShowOn = "showOnMissing" }),
})
aspect.iconSource = 0
aspect.displayIcon = "Interface\\Icons\\Spell_Nature_RavenForm"
aspect.cooldown = false
aspect.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
aspect.zoom = 0.3
table.insert(aspect.subRegions, F.subborder())
aspect.load.use_combat = true
aspect.load.use_spellknown = true
aspect.load.spellknown = HAWK[1]
alertAnim(aspect)
adopt(gAlerts, aspect)

-- 14. Kill Command: (ranged crit OR spell crit OR melee crit by me) AND KC ready.
--     Sanctioned one-liner #1 (Riposte pattern). TBC Kill Command is enabled by
--     ANY crit of yours, so the melee swing counts while the pet tanks in a dungeon.
local kc = reg(F.icon("Hunter - Kill Command", CLASS, 40, 40, 0, 0, nil))
local kc1 = F.clogTrigger("RANGE", "_DAMAGE", "5",
  { use_sourceUnit = true, sourceUnit = "player", use_critical = true })
local kc2 = F.clogTrigger("SPELL", "_DAMAGE", "5",
  { use_sourceUnit = true, sourceUnit = "player", use_critical = true })
local kc3 = F.clogTrigger("SWING", "_DAMAGE", "5",
  { use_sourceUnit = true, sourceUnit = "player", use_critical = true })
local kc4 = F.cdTrigger(KILLCMD, "Kill Command", "showOnReady")
kc.triggers = F.triggers({ kc1, kc2, kc3, kc4 }, {
  disjunctive = "custom",
  customTriggerLogic = "function(t) return (t[1] or t[2] or t[3]) and t[4] end",
})
kc.iconSource = 0
kc.displayIcon = "Interface\\Icons\\Ability_Hunter_KillCommand"
kc.subRegions[1] = F.subglow(true, { 1, 0.82, 0.1, 1 })
kc.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
kc.zoom = 0.3
table.insert(kc.subRegions, F.subborder())
kc.load.use_spellknown = true
kc.load.spellknown = KILLCMD
alertAnim(kc)
adopt(gAlerts, kc)

-- 15. Mongoose Bite: (swing OR spell dodged BY me) AND MB ready.
--     Sanctioned one-liner #2 — dest=player, missType DODGE.
local mb = reg(F.icon("Hunter - Mongoose Bite", CLASS, 40, 40, 0, 0, nil))
local mb1 = F.clogTrigger("SWING", "_MISSED", "5",
  { use_missType = true, missType = "DODGE", use_destUnit = true, destUnit = "player" })
local mb2 = F.clogTrigger("SPELL", "_MISSED", "5",
  { use_missType = true, missType = "DODGE", use_destUnit = true, destUnit = "player" })
local mb3 = F.cdTrigger(MBITE, "Mongoose Bite", "showOnReady")
mb.triggers = F.triggers({ mb1, mb2, mb3 }, {
  disjunctive = "custom",
  customTriggerLogic = "function(t) return (t[1] or t[2]) and t[3] end",
})
mb.iconSource = 0
mb.displayIcon = "Interface\\Icons\\Ability_Hunter_SwiftStrike"
mb.subRegions[1] = F.subglow(true, { 0.4, 1, 0.4, 1 })
mb.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
mb.zoom = 0.3
table.insert(mb.subRegions, F.subborder())
mb.load.use_spellknown = true
mb.load.spellknown = MBITE
alertAnim(mb)
adopt(gAlerts, mb)

-- 16. threat >= 90% AND Feign Death ready -> drop it before you tank.
--     90, not 70: 70 is Misdirection's band (see "Misdirection Prompt" below), and
--     FD is a full threat wipe that costs shots and burns your MD setup. Combat +
--     party/raid gated: solo you are the entire threat list, so threatpct reads 100
--     forever and a permanently glowing prompt is exactly the noise this pack cuts.
local fd = reg(F.icon("Hunter - Feign Death Prompt", CLASS, 40, 40, 0, 0, nil))
fd.triggers = F.triggers({ threatTrigger(90), F.cdTrigger(FEIGN, "Feign Death", "showOnReady") })
fd.iconSource = 0
fd.displayIcon = "Interface\\Icons\\Ability_Rogue_FeignDeath"
fd.subRegions[1] = F.subglow(true, { 1, 0.45, 0.1, 1 })
fd.zoom = 0.3
table.insert(fd.subRegions, F.subborder())
fd.load.use_combat = true
fd.load.use_ingroup = true
fd.load.ingroup = { multi = { group = true, raid = true } }
fd.load.use_spellknown = true
fd.load.spellknown = FEIGN
alertAnim(fd)
adopt(gAlerts, fd)

-- 17. mana < 20% AND not already in Viper -> swap aspect
local viper = reg(F.icon("Hunter - Go Viper", CLASS, 40, 40, 0, 0, nil))
local vp = F.powerTrigger(0)
vp.use_percentpower = true
vp.percentpower = "20"
vp.percentpower_operator = "<"
local viperMissing = F.auraTrigger("player", true, { VIPER }, { matchesShowOn = "showOnMissing" })
viper.triggers = F.triggers({ vp, viperMissing })
viper.iconSource = 0
viper.displayIcon = "Interface\\Icons\\Ability_Hunter_AspectoftheViper"
viper.cooldown = false
viper.subRegions[1] = F.subglow(true, { 0.3, 0.7, 1, 1 })
viper.zoom = 0.3
table.insert(viper.subRegions, F.subborder())
viper.load.use_combat = true
viper.load.use_spellknown = true
viper.load.spellknown = VIPER
alertAnim(viper)
adopt(gAlerts, viper)

-- ===== 18. Cooldowns: horizontal row; talent icons appear only when known =====
local gCDs = reg(F.dynGroup("Hunter - Cooldowns", 0, -66, nil, "HORIZONTAL", "CENTER", 4))
adopt(top, gCDs)

-- 19-26. one recipe: desaturate while down, WA cooldown text on, tooltip on hover
local function addCD(name, spellId, gate)
  local ic = reg(F.icon("Hunter CD - " .. name, CLASS, 32, 32, 0, 0, nil))
  ic.triggers = F.triggers({ F.cdTrigger(spellId, name, "showAlways") })
  ic.cooldownTextDisabled = false
  ic.useTooltip = true
  ic.conditions = { F.condition(1, "onCooldown", "==", 1, "desaturate", true) }
  ic.zoom = 0.3
  table.insert(ic.subRegions, F.subborder())
  if gate then
    ic.load.use_spellknown = true
    ic.load.spellknown = gate
  end
  adopt(gCDs, ic)
  return ic
end

-- A burst cooldown owns its ACTIVE window too: trigger 1 is the buff (so
-- first-active mode drives the swipe off the window's own timer) and trigger 2 the
-- cooldown, joined with disjunctive "any" so the icon never leaves the row. While
-- the window is live the icon is lit and full colour; afterwards it desaturates
-- for the rest of the cooldown. This is what tells you the haste/damage window is
-- still running, which is the part of the button that changes the next 15-18s.
local function withActiveWindow(ic, unit, auraIds, glowColor)
  local cd = ic.triggers[1].trigger
  ic.triggers = F.triggers({ F.auraTrigger(unit, true, auraIds), cd }, { disjunctive = "any" })
  ic.subRegions[1] = F.subglow(false, glowColor)
  local lit = F.condition(1, "show", "==", 1, "sub.1.glow", true)
  lit.changes[2] = { property = "desaturate", value = false }
  ic.conditions = { F.condition(2, "onCooldown", "==", 1, "desaturate", true), lit }
  return ic
end

local cdBWrath = addCD("Bestial Wrath", BWRATH,  BWRATH)   -- BM 31-pt
addCD("Intimidation",  INTIMID, INTIMID)  -- BM
addCD("Readiness",     READY,   READY)    -- SV 41-pt
addCD("Wyvern Sting",  WYVERN,  WYVERN)   -- SV 31-pt, skipped by raid builds
local cdRapid = addCD("Rapid Fire",    RAPID,   nil)      -- baseline, lvl 26
local cdMulti = addCD("Multi-Shot",    MULTI,   nil)      -- baseline, lvl 18
addCD("Misdirection",  MISDIR,  MISDIR)   -- trained at 70
addCD("Feign Death",   FEIGN,   nil)      -- baseline, lvl 30

-- Rapid Fire's 15s +40% ranged haste is the bigger of the two haste windows the
-- pack sees (Quick Shots is the 12s +15% one), so the icon shows the window, not
-- just the button. Bestial Wrath's 18s buff lands on the PET (spell 19574 is the
-- pet aura; 34471 The Beast Within is the 41-pt hunter half, tracked in the buff
-- row), so a 31-pt BM finally gets a burst-window timer too.
withActiveWindow(cdRapid,  "player", { RAPID },  { 1, 0.85, 0.2, 1 })
withActiveWindow(cdBWrath, "pet",    { BWRATH }, { 1, 0.45, 0.1, 1 })

-- ===== 27. Procs: cloned tracker right of the bars =====
local gProcs = reg(F.dynGroup("Hunter - Procs", 110, 24, nil, "RIGHT", "LEFT", 4))
adopt(top, gProcs)

-- 28. Quick Shots — the smaller of the two ranged-haste windows (12s, +15%);
--     the bigger one is Rapid Fire, which now shows its window on its own icon
local quick = reg(F.icon("Hunter - Quick Shots", CLASS, 32, 32, 0, 0, nil))
quick.triggers = F.triggers({ F.auraTrigger("player", true, { QSHOTS }, { showClones = true }) })
quick.subRegions[1] = F.subglow(true, { 1, 0.85, 0.2, 1 })
quick.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
quick.zoom = 0.3
table.insert(quick.subRegions, F.subborder())
quick.animation.start  = F.animCustom("0.5", { alpha = 0, alphaType = "alphaPulse", scale = 1.5 }, "easeOut")
quick.animation.finish = F.animCustom("0.8", { x = 120, alpha = 0 }, "easeOut")
adopt(gProcs, quick)

-- ===== v2 additions =====
-- Everything below is NEW in v2 and must stay at the end: each region constructor
-- consumes one W.uid(), and the v1 auras keep their uids only if no uid() call is
-- inserted before theirs. Placement in the HUD is done by re-parenting afterwards
-- (adopt / reorder), which costs no uid.

-- 29. Arcane Shot — the other half of the "Multi-Shot or Arcane Shot" slot in the
--     1:1.5 weave, and the instant you press while moving. Same row recipe.
local arcane = addCD("Arcane Shot", ARCANE, nil)  -- baseline, 6s cd (r1 = 3044)

-- 30. Back to Hawk — the return half of the aspect swap. Viper is a flat damage
--     loss (Hawk r8 = +155 ranged AP), so the moment mana is back you swap out.
--     Aspect MISSING cannot cover this: Viper counts as an aspect, so it is silent.
local hawkBack = reg(F.icon("Hunter - Back to Hawk", CLASS, 40, 40, 0, 0, nil))
local manaBack = F.powerTrigger(0)
manaBack.use_percentpower = true
manaBack.percentpower = "80"
manaBack.percentpower_operator = ">="
hawkBack.triggers = F.triggers({ manaBack, F.auraTrigger("player", true, { VIPER }) })
hawkBack.iconSource = 0
hawkBack.displayIcon = "Interface\\Icons\\Spell_Nature_RavenForm"
hawkBack.cooldown = false
hawkBack.subRegions[1] = F.subglow(true, { 0.4, 1, 0.4, 1 })
hawkBack.zoom = 0.3
table.insert(hawkBack.subRegions, F.subborder())
hawkBack.load.use_combat = true
hawkBack.load.use_spellknown = true
hawkBack.load.spellknown = HAWK[1]
alertAnim(hawkBack)
adopt(gAlerts, hawkBack)

-- 31. Misdirection prompt — the ability paired with the threat bar's 70% tier.
--     MD is the TBC hunter's actual answer to climbing threat; Feign Death (90%)
--     is the emergency behind it. Icon comes from trigger 2 (iconSource = 2), so
--     it is the real spell icon on every locale. Party/raid + combat gated: MD
--     needs a friendly target to hand the threat to.
local mdPrompt = reg(F.icon("Hunter - Misdirection Prompt", CLASS, 40, 40, 0, 0, nil))
mdPrompt.triggers = F.triggers({
  threatTrigger(70), F.cdTrigger(MISDIR, "Misdirection", "showOnReady"),
})
mdPrompt.iconSource = 2
mdPrompt.cooldown = false
mdPrompt.subRegions[1] = F.subglow(true, { 1, 0.82, 0.1, 1 })
mdPrompt.zoom = 0.3
table.insert(mdPrompt.subRegions, F.subborder())
mdPrompt.load.use_combat = true
mdPrompt.load.use_ingroup = true
mdPrompt.load.ingroup = { multi = { group = true, raid = true } }
mdPrompt.load.use_spellknown = true
mdPrompt.load.spellknown = MISDIR
alertAnim(mdPrompt)
adopt(gAlerts, mdPrompt)

-- 32. Mend Pet — the pet is ~35-40% of BM damage and the prerequisite for Kill
--     Command. Two health triggers ("< 40" AND "> 0") mean the prompt covers the
--     hurt pet only; a dead pet is a different button and gets its own alert.
local mendPet = reg(F.icon("Hunter - Mend Pet", CLASS, 40, 40, 0, 0, nil))
mendPet.triggers = F.triggers({
  petHealth("<", 40), petHealth(">", 0), F.cdTrigger(MENDPET, "Mend Pet", "showOnReady"),
})
mendPet.iconSource = 3
mendPet.cooldown = false
mendPet.subRegions[1] = F.subglow(true, { 0.4, 1, 0.4, 1 })
mendPet.zoom = 0.3
table.insert(mendPet.subRegions, F.subborder())
mendPet.load.use_spellknown = true
mendPet.load.spellknown = MENDPET
alertAnim(mendPet)
adopt(gAlerts, mendPet)

-- 33. Revive Pet — a dead pet still knows Kill Command, so without this the pack's
--     best element glows for a button that does nothing. Pet exists and is at 0%.
local revivePet = reg(F.icon("Hunter - Revive Pet", CLASS, 40, 40, 0, 0, nil))
revivePet.triggers = F.triggers({
  petHealth("<=", 0), F.cdTrigger(REVIVE, "Revive Pet", "showOnReady"),
})
revivePet.iconSource = 2
revivePet.cooldown = false
revivePet.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
revivePet.zoom = 0.3
table.insert(revivePet.subRegions, F.subborder())
revivePet.load.use_spellknown = true
revivePet.load.spellknown = REVIVE
alertAnim(revivePet)
adopt(gAlerts, revivePet)

-- ===== v4 additions: the PvP layer =====
-- Same rule as the v2 block: everything new is constructed at the BOTTOM of the file
-- so no W.uid() call is inserted before an existing one, then re-parented into place
-- (re-parenting and renaming are free; uid CALL ORDER is what must never move).
--
-- Every element below carries its own arena/battleground load gate. A group's load is
-- not a child gate, so the gate is repeated per aura — which is also what makes the
-- dynamic groups collapse cleanly in PvE, where none of this loads at all.

-- use_size = false is NOT "off": multiselect load args are active for both true and
-- false and only inert at nil. false selects MULTI mode, which ORs the entries.
local PVP_SIZE   = { arena = true, pvp = true }   -- arena OR battleground
local ARENA_SIZE = { arena = true }               -- anything reading arena1..arena5:
                                                  -- those units do not exist in a BG
local function pvpLoad(sizes, extra)
  local l = F.load(CLASS)
  l.use_size = false
  local m = {}
  for k, v in pairs(sizes) do m[k] = v end        -- fresh table per aura
  l.size = { multi = m }
  for k, v in pairs(extra or {}) do l[k] = v end
  return l
end

-- The factory's private trigger stub, replicated for the prototypes it does not wrap.
local function trig(t)
  t.names = {}; t.spellIds = {}
  t.subeventPrefix = "SPELL"; t.subeventSuffix = "_CAST_START"
  t.debuffType = t.debuffType or "HELPFUL"
  return t
end

-- Item cooldown by NUMERIC item id. genericShowOn is mandatory — nil means the aura
-- never shows, the same trap as the spell version.
local function itemCD(itemId, showOn)
  return trig{ type = "item", event = "Cooldown Progress (Item)",
               use_itemName = true, itemName = itemId,
               use_genericShowOn = true, genericShowOn = showOn }
end

-- Spell Cast Succeeded: the only sanctioned enemy-cooldown *inference* on 2.5.x, and
-- the only way to know a trap is on the ground. duration is REQUIRED (string seconds);
-- without it the state lasts 1 second and nobody sees it.
local function castSucceeded(unit, ids, duration)
  local s = {}
  for i, id in ipairs(ids) do s[i] = tostring(id) end
  return { type = "event", event = "Spell Cast Succeeded",
           unit = unit, use_unit = true,
           use_spellId = true, spellId = s, duration = duration }
end

local gPvP = reg(F.dynGroup("Hunter - PvP", 150, 96, nil, "DOWN", "TOP", 6))
adopt(top, gPvP)

-- 34. CC ON ME — which break works, and whether to spend it now. No controlType filter,
--     so it matches ANY loss-of-control effect, including a Kick/Counterspell school
--     lockout, which is not an aura and which no aura trigger can ever see. The icon
--     comes from the trigger (iconSource -1) because the icon IS the identity of the
--     effect, and %p is the answer to "ride it or trinket it". No combat gate: the
--     opener lands before you are in combat.
local ccMe = reg(F.icon("Hunter - CC ON ME", CLASS, 40, 40, 0, 0, nil))
ccMe.triggers = F.triggers({ trig{ type = "unit", event = "Crowd Controlled" } })
ccMe.cooldown = false
ccMe.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })   -- red default = "trinket food"
ccMe.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
-- v5: the glow COLOUR carries the category, because under a stun a player parses colour and
-- never text. sub.1.glowColor is the real property name: "sub." .. <1-based subRegions index>
-- .. "." .. <key from the subregion's properties table>, and the subglow above is index 1.
-- Two preconditions, both satisfied here: useGlowColor must be true (otherwise SetGlowColor
-- stores the value and LibCustomGlow keeps using its own default — a silent no-op), which
-- F.subglow sets whenever a colour is passed; and the glow must be on, which it is. Values
-- are 4-element ARRAYS — an {r=,g=,b=,a=} hash would serialise to four nils.
-- Same five colours as the mage pack on purpose: one language across two characters.
-- Anything not listed (CHARM, DISARM, PACIFY, POSSESS) keeps the red base = "spend the break".
ccMe.conditions = {
  -- RED — stun. Nothing a hunter owns breaks a stun: it is the medallion or nothing,
  -- and the Trinket DOWN readout in the PvP stack is the other half of that sentence.
  F.condition(1, "controlType", "==", "STUN", "sub.1.glowColor", { 1, 0.15, 0.15, 1 }),
  F.condition(1, "controlType", "==", "STUN_MECHANIC", "sub.1.glowColor", { 1, 0.15, 0.15, 1 }),
  -- PURPLE — fear. Trinket, or Will of the Forsaken if you are Undead (the pack tracks
  -- that racial's cooldown separately, which is exactly the "which break do I spend" call).
  F.condition(1, "controlType", "==", "FEAR", "sub.1.glowColor", { 0.7, 0.3, 1, 1 }),
  F.condition(1, "controlType", "==", "FEAR_MECHANIC", "sub.1.glowColor", { 0.7, 0.3, 1, 1 }),
  -- GREEN — confuse / polymorph. Ride it: any damage breaks it, and your pet is already
  -- hitting something. Trinketing here throws the break away for an effect about to end.
  F.condition(1, "controlType", "==", "CONFUSE", "sub.1.glowColor", { 0.4, 0.95, 0.5, 1 }),
  -- BLUE — root. NOT a trinket: a hunter shoots at full effect while rooted, so keep firing
  -- and save the break for the stun that follows. A root only kills you if a melee is
  -- closing, and that case already has its own prompt (DEADZONE -> Scatter / trap / Wing Clip).
  F.condition(1, "controlType", "==", "ROOT", "sub.1.glowColor", { 0.3, 0.7, 1, 1 }),
  -- AMBER — silence or school lockout. Your shots and your traps are gone for the duration,
  -- so there is no "play through it" line: trinket EARLIER than you otherwise would.
  F.condition(1, "controlType", "==", "SILENCE", "sub.1.glowColor", { 1, 0.85, 0.2, 1 }),
  F.condition(1, "controlType", "==", "PACIFYSILENCE", "sub.1.glowColor", { 1, 0.85, 0.2, 1 }),
  F.condition(1, "controlType", "==", "SCHOOL_INTERRUPT", "sub.1.glowColor", { 1, 0.85, 0.2, 1 }),
}
ccMe.zoom = 0.3
table.insert(ccMe.subRegions, F.subborder())
ccMe.load = pvpLoad(PVP_SIZE)
alertAnim(ccMe)
adopt(gAlerts, ccMe)

-- 35. DEADZONE — a hostile target inside ~8 yards means Auto Shot, Steady Shot and
--     every other shot are dead, so the next press is Wing Clip / Scatter / trap /
--     melee, not a shot. "<=" tests max <= 8, i.e. "definitely inside the deadzone".
--     Trigger 2 keeps it off friendly targets. This is the pack's ONLY Range Check —
--     it polls on FRAME_UPDATE, which is exactly why it sits behind a PvP gate and a
--     combat gate. LibRangeCheck is an estimate, so nothing hard depends on it.
local deadzone = reg(F.icon("Hunter - DEADZONE", CLASS, 40, 40, 0, 0, nil))
deadzone.triggers = F.triggers({
  trig{ type = "unit", event = "Range Check", unit = "target",
        use_range = true, range = "8", range_operator = "<=" },
  trig{ type = "unit", event = "Unit Characteristics", unit = "target", use_unit = true,
        use_hostility = true, hostility = "hostile" },
})
deadzone.iconSource = 0
deadzone.displayIcon = "Interface\\Icons\\Ability_Hunter_SteadyShot"
deadzone.cooldown = false
deadzone.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
deadzone.zoom = 0.3
table.insert(deadzone.subRegions, F.subborder())
deadzone.load = pvpLoad(PVP_SIZE, { use_combat = true })
alertAnim(deadzone)
adopt(gAlerts, deadzone)

-- 36. SILENCE NOW — target is casting AND Silencing Shot is genuinely castable.
--     "Action Usable" folds cooldown + mana + range into one boolean, so the prompt
--     never appears for a button that would fail. No spell whitelist: TBC has no
--     interruptibility flag at all (WA disables the arg for IsTBC), so filtering by
--     id would only shrink coverage while pretending to add precision. Trigger 1 is
--     first, so %p counts down the cast; the icon comes from trigger 2 = the button.
local silence = reg(F.icon("Hunter - SILENCE NOW", CLASS, 40, 40, 0, 0, nil))
silence.triggers = F.triggers({
  trig{ type = "unit", event = "Cast", unit = "target", use_unit = true },
  trig{ type = "spell", event = "Action Usable",
        use_spellName = true, spellName = SILENCE, realSpellName = "Silencing Shot",
        use_exact_spellName = true, use_ignoreoverride = true },
})
silence.iconSource = 2
silence.cooldown = false
silence.subRegions[1] = F.subglow(true, { 1, 0.85, 0.2, 1 })
silence.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
silence.zoom = 0.3
table.insert(silence.subRegions, F.subborder())
silence.load = pvpLoad(PVP_SIZE, { use_spellknown = true, spellknown = SILENCE })
alertAnim(silence)
adopt(gAlerts, silence)

-- 37. TARGET IMMUNE — stop. Shooting into Divine Shield / Blessing of Protection /
--     Ice Block / Cloak of Shadows burns the whole burst for zero damage, and The
--     Beast Within means the trap and Scatter will not land either. iconSource -1
--     shows WHICH immunity, which is what decides swap vs wait-out.
local immune = reg(F.icon("Hunter - TARGET IMMUNE", CLASS, 40, 40, 0, 0, nil))
immune.triggers = F.triggers({ F.auraTrigger("target", true, IMMUNE) })
immune.cooldown = false
immune.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
immune.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
immune.zoom = 0.3
table.insert(immune.subRegions, F.subborder())
immune.load = pvpLoad(PVP_SIZE)
alertAnim(immune)
adopt(gAlerts, immune)

-- 38. Trinket DOWN — "is my get-out-of-jail available". showOnCooldown only, so the
--     column is EMPTY in the normal case and absence means ready. Four triggers ORed
--     because itemName has no multiEntry; only one of them can ever be equipped, and
--     iconSource -1 means the icon is the trinket you actually own.
local trinket = reg(F.icon("Hunter - Trinket DOWN", CLASS, 32, 32, 0, 0, nil))
local trinketTrigs = {}
for i, id in ipairs(TRINKETS) do trinketTrigs[i] = itemCD(id, "showOnCooldown") end
trinket.triggers = F.triggers(trinketTrigs, { disjunctive = "any" })
trinket.cooldownTextDisabled = false
trinket.desaturate = true
trinket.zoom = 0.3
table.insert(trinket.subRegions, F.subborder())
trinket.load = pvpLoad(PVP_SIZE)
adopt(gPvP, trinket)

-- 39. Will of the Forsaken DOWN — Undead carry a second, independent 2-minute break,
--     and whether it is up is what decides if the medallion can be spent early.
--     Gated on the ability, not the race: no racial, no icon, no gap.
local wotf = reg(F.icon("Hunter - Will of the Forsaken DOWN", CLASS, 32, 32, 0, 0, nil))
wotf.triggers = F.triggers({ F.cdTrigger(WOTF, "Will of the Forsaken", "showOnCooldown") })
wotf.cooldownTextDisabled = false
wotf.desaturate = true
wotf.zoom = 0.3
table.insert(wotf.subRegions, F.subborder())
wotf.load = pvpLoad(PVP_SIZE, { use_spellknown = true, spellknown = WOTF })
adopt(gPvP, wotf)

-- 40. Enemy trinket — one clone per opponent, counting down 120s from the cast we
--     SAW. This is an inference, not a read: no API on 2.5.x exposes another player's
--     cooldowns. The countdown is the whole value — "they trinketed" as a one-shot
--     flash changes nothing, "their break is gone for 90 more seconds" is the go.
--     Arena-only, because unit = "arena" is meaningless in a battleground.
local enemyTrinket = reg(F.icon("Hunter - Enemy Trinket", CLASS, 32, 32, 0, 0, nil))
enemyTrinket.triggers = F.triggers({
  castSucceeded("arena", { PVPTRINK }, "120"),
})
enemyTrinket.cooldownTextDisabled = false
enemyTrinket.zoom = 0.3
table.insert(enemyTrinket.subRegions, F.subborder())
enemyTrinket.load = pvpLoad(ARENA_SIZE)
adopt(gPvP, enemyTrinket)

-- 41. Trap Armed — a trap is on the ground: pull the target across it, recall the pet
--     (your own pet is the most common trap-breaker) and do not waste the second one.
--     Inference again, with the trap's own 1-minute lifetime supplied: it cannot see
--     the trap being sprung or broken, so it is a maximum, not a fact.
local trapArmed = reg(F.icon("Hunter - Trap Armed", CLASS, 36, 36, 0, 0, nil))
trapArmed.triggers = F.triggers({ castSucceeded("player", FRZTRAP, "60") })
trapArmed.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
trapArmed.zoom = 0.3
table.insert(trapArmed.subRegions, F.subborder())
trapArmed.load = pvpLoad(PVP_SIZE, { use_spellknown = true, spellknown = FRZTRAP[1] })
adopt(gPvP, trapArmed)

-- 42. Viper Sting out — one clone per opponent carrying YOUR Viper Sting. Mana denial
--     is the hunter's win condition in a long game and the sting gets dispelled, so
--     the row emptying is the re-apply prompt. Tracked on the opponents rather than on
--     the kill target, because the drain belongs on whoever heals.
local viperOut = reg(F.icon("Hunter - Viper Sting Out", CLASS, 36, 36, 0, 0, nil))
viperOut.triggers = F.triggers({
  F.auraTrigger("arena", false, VIPERST, {
    ownOnly = true, showClones = true, combinePerUnit = true, perUnitMode = "affected",
  }),
})
viperOut.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
viperOut.zoom = 0.3
table.insert(viperOut.subRegions, F.subborder())
viperOut.load = pvpLoad(ARENA_SIZE, { use_spellknown = true, spellknown = VIPERST[1] })
adopt(gPvP, viperOut)

-- 43-44. Scatter -> Trap is the hunter's entire opening game plan, and neither button
--        is in the PvE cooldown row. Both join it under the PvP gate, so the row is
--        byte-for-byte the same row in a raid and grows two icons in arena.
local cdTrap = addCD("Freezing Trap", FRZTRAP[1], nil)
cdTrap.load = pvpLoad(PVP_SIZE, { use_spellknown = true, spellknown = FRZTRAP[1] })
local cdScatter = addCD("Scatter Shot", SCATTER, nil)
cdScatter.load = pvpLoad(PVP_SIZE, { use_spellknown = true, spellknown = SCATTER })

-- ===== v5 addition: the one new aura, constructed last =====
-- Same append-only rule as v2 and v4: one new W.uid() call, at the very END of the file.

-- 45. ENEMY MANA — one bar per opponent who actually runs on mana, so the row IS the
--     healer list. Mana denial is the hunter's win condition in a long game, and Viper
--     Sting is a choice of target, not a rotation slot: this says which arena unit is worth
--     the sting and when the drain has done its job. Below 20% a healer cannot chain-heal
--     through a swap, so the bar goes amber — this pack's "press now" colour, the same one
--     SILENCE NOW and Kill Command wear.
--
--     The Power prototype is not pruned on TBC and its unit arg accepts "arena" (WA deletes
--     arena units only under IsClassicEra, not IsTBC), and statesParameter = "unit" makes it
--     clone one state per arena1..arena5 — hence the dynamicgroup parent. Both flags matter:
--     use_powertype = true AND powertype = 0 pin it to MANA, because without them the
--     trigger silently reads whatever bar that opponent primarily uses (a rogue's energy).
--     use_requirePowerType then hides every opponent whose PRIMARY bar is not mana, so the
--     rogue and warrior rows never appear and the row that remains is the one you care about.
--     Arena-gated only: arena1..arena5 do not exist in a battleground, so a BG-loaded copy
--     would be permanently blank rows.
local enemyMana = reg(F.aurabar("Hunter - Enemy Mana", CLASS, 120, 12, 0, 0, nil,
  { 0.25, 0.55, 0.95, 1 }))
local emPower = F.powerTrigger(0)          -- 0 = Mana, and use_powertype is already true
emPower.unit = "arena"                     -- multi-unit: one clone per opponent
emPower.use_requirePowerType = true        -- mana must be their PRIMARY bar
enemyMana.triggers = F.triggers({ emPower })
enemyMana.subRegions[2] = F.subtext("%name%", 10, "INNER_LEFT")
enemyMana.subRegions[3] = F.subtext("%percentpower%%", 10, "INNER_RIGHT", "percentpower")
enemyMana.subRegions[4] = F.subborder("bar")
enemyMana.conditions = {
  F.condition(1, "percentpower", "<", "20", "barColor", { 1, 0.85, 0.2, 1 }),
}
enemyMana.load = pvpLoad(ARENA_SIZE, { use_spellknown = true, spellknown = VIPERST[1] })
adopt(gPvP, enemyMana)

-- ===== layout order (no uid cost: controlledChildren order is pure layout) =====
local function placeFirst(group, id)
  for i, cid in ipairs(group.controlledChildren) do
    if cid == id then
      table.remove(group.controlledChildren, i)
      table.insert(group.controlledChildren, 1, id)
      return
    end
  end
  error("placeFirst: " .. id .. " is not a child of " .. group.id)
end

local function placeAfter(group, id, afterId)
  local pos
  for i, cid in ipairs(group.controlledChildren) do
    if cid == id then table.remove(group.controlledChildren, i) break end
  end
  for i, cid in ipairs(group.controlledChildren) do
    if cid == afterId then pos = i + 1 break end
  end
  table.insert(group.controlledChildren, assert(pos, "placeAfter: no " .. afterId), id)
end

-- The two on-cooldown shots sit together in the row.
placeAfter(gCDs, arcane.id, cdMulti.id)
-- Kill Command is the pack's one reflex prompt, so it gets a fixed home: first in
-- a grow-UP flow means it is anchored at the bottom and never reflows when another
-- alert appears above it.
placeFirst(gAlerts, kc.id)

-- ===== assemble (v2000 nested), encode, verify, write =====
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

local txtPath = dir .. "/all-specs.txt"
-- uid continuity vs the PREVIOUS version's string, read before it is overwritten
local cont = W.uidContinuity(encoded, txtPath)

local out = io.open(txtPath, "w")
out:write(encoded)
out:close()

print(("OK: %d auras (top + %d children), %d chars -> all-specs.txt")
  :format(#transmit.c + 1, #transmit.c, #encoded))
if cont then
  print(("uid continuity vs previous: stable=%d changed=%d parentSame=%s")
    :format(cont.stable, cont.changed, tostring(cont.parentSame)))
end
