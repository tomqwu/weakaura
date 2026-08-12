-- generate.lua — Priest TBC All-Specs HUD (v2).
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
--
-- v2 (rotation review fixes; UIDs are append-only, so this imports as an Update):
--   * Weakened Soul now reads the HEAL TARGET (unit = "target"), not the player, and
--     loads for every non-Shadowform priest — it is the gate on the #1 healer press.
--   * NEW Priest - Renew: your own Renew on the current friendly target (all 12 ranks).
--   * Mind Blast and Shadow Word: Death get a violet ready-glow (the two presses the
--     Shadow rotation clips Mind Flay for); SW:D's glow is suppressed below 50% HP
--     because its backlash is the one thing in this pack that can kill you.
--   * SW:Pain's re-cast glow moved to <= 1s (glowing at 3s told you to clip a tick).
--   * Vampiric Embrace got the same expiry glow as its row-mates; Shadowfiend prompt
--     moved to 50% mana; Fade prompt is combat-gated; Prayer of Mending no longer
--     loads for Shadow; the health bar turns red at the Desperate Prayer threshold;
--     the always-on icon layer fades to 50% alpha out of combat.

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

-- Threat unit stays the factory's `threatUnit`. That IS the correct key for the
-- internalVersion 45 (WA 3.5.0) data this pack emits: the arg was renamed to plain
-- `unit` only in internalVersion 51, and Modernize.lua migrates < 51 data by copying
-- threatUnit -> unit on import. Writing `unit` here instead is actively wrong — that
-- migration assigns unconditionally, so it would overwrite our value with nil.
-- "none" ("At Least One Enemy") is NOT usable here regardless: the prototype's last
-- hidden test is WeakAuras.UnitExistsFixed(unit, false) and UnitExists("none") is false,
-- so a "none" threat trigger never activates. Threat stays target-relative.
local function threatTrigger(_unit, minPct)
  return F.threatTrigger(minPct)
end

-- Always-on elements breathe with the fight: append an always-active Unit
-- Characteristics trigger and dim to 50% alpha while out of combat.
local function fadeOutOfCombat(a)
  local n = #a.triggers + 1
  a.triggers[n] = { trigger = F.unitCharTrigger(), untrigger = {} }
  a.conditions[#a.conditions + 1] = F.condition(n, "inCombat", "==", 0, "alpha", 0.5)
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
-- red below 40%: the same number the Desperate Prayer prompt fires at, so the bar
-- and the prompt read as one danger state
health.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "percenthealth", "<", "40", "barColor", { 0.9, 0.12, 0.12, 1 }),
}
adopt(gRes, health)

-- mana: the resource all three specs plan around
local mana = reg(F.aurabar("Priest - Mana", CLASS, 172, 14, 0, -27, nil,
  { 0.25, 0.5, 0.92, 1 }))
mana.triggers = F.triggers({ F.powerTrigger(0), F.unitCharTrigger() })
mana.subRegions[2] = F.subtext("%percentpower%%", 12, "INNER_RIGHT", "percentpower")
mana.subRegions[3] = F.subborder("bar")
mana.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }
adopt(gRes, mana)

-- threat: your threat on the unit you have targeted. The trigger only produces a
-- state for a hostile unit you are on the threat table of, so the bar self-hides
-- out of combat and while you have a friendly targeted (no fade condition needed).
-- Green -> orange at 70% -> red on aggro; conditions run in order, most severe last.
local threat = reg(F.aurabar("Priest - Threat", CLASS, 172, 14, 0, -41, nil,
  { 0.25, 0.8, 0.3, 1 }))
threat.triggers = F.triggers({ threatTrigger("target", nil) })
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

-- Shadow Word: Pain — own DoT on the target, all 10 ranks. The glow sits at <=1s,
-- not <=3s: SW:P is instant and ticks every 3s, so re-casting early throws away a
-- tick. Re-apply as it drops, never before.
local swp = reg(F.icon("Priest - Shadow Word Pain", CLASS, 40, 40, -66, 0, nil))
swp.triggers = F.triggers({
  F.auraTrigger("target", false, {
    589, 594, 970, 992, 2767, 10892, 10893, 10894, 25367, 25368,
  }, { ownOnly = true }),
})
swp.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
swp.conditions = { F.condition(1, "expirationTime", "<=", "1", "sub.1.glow", true) }
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

-- Vampiric Embrace — own debuff on the boss (raid heal / mana loop), single rank.
-- 60s duration and no tick to clip, so it takes the same <=3s re-apply glow as VT.
local ve = reg(F.icon("Priest - Vampiric Embrace", CLASS, 40, 40, 22, 0, nil))
ve.triggers = F.triggers({
  F.auraTrigger("target", false, { 15286 }, { ownOnly = true }),
})
ve.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
ve.conditions = { F.condition(1, "expirationTime", "<=", "3", "sub.1.glow", true) }
ve.load.use_spellknown = true
ve.load.spellknown = 15286
adopt(gBuffs, ve)

-- Weakened Soul on the HEAL TARGET — the gate on the #1 Disc/Holy press. Power Word:
-- Shield is unusable while this is on them, so the icon answers "can I shield this
-- person?"; the glow at <=1s is "you can shield again now". NOT ownOnly: any priest's
-- shield blocks yours. Loads for every priest WITHOUT Shadowform, which is the exact
-- complement of SW:P's gate, so the shared x=-66 slot is still provably single-occupancy.
local wsoul = reg(F.icon("Priest - Weakened Soul", CLASS, 40, 40, -66, 0, nil))
wsoul.triggers = F.triggers({
  F.auraTrigger("target", false, { 6788 }),
})
wsoul.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
wsoul.conditions = { F.condition(1, "expirationTime", "<=", "1", "sub.1.glow", true) }
wsoul.load.use_not_spellknown = true
wsoul.load.not_spellknown = 15473  -- everyone except Shadowform (which owns this slot)
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

-- mana < 50% AND Shadowfiend ready -> send the fiend (percent-based, so it works at
-- any mana pool size); both triggers must hold (disjunctive "all"). 50%, not 30%: the
-- fiend returns ~25% of your maximum mana over its 15s, so firing it while nearly dry
-- wastes both the return and five minutes of cooldown.
local sfiend = reg(F.icon("Priest - Shadowfiend Prompt", CLASS, 40, 40, 0, 0, nil))
local sfiendPower = F.powerTrigger(0)
sfiendPower.use_percentpower = true
sfiendPower.percentpower = "50"
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

-- threat >= 70% on your target AND Fade ready -> dump threat now. Combat-gated like
-- the other three prompts (the threat trigger already needs a hostile target, but the
-- gate keeps the whole alert flow uniformly silent outside a fight).
local fade = reg(F.icon("Priest - Fade Prompt", CLASS, 40, 40, 0, 0, nil))
fade.triggers = F.triggers({
  threatTrigger("target", 70),
  F.cdTrigger(586, "Fade", "showOnReady"),
})
fade.iconSource = 0
fade.displayIcon = "Interface\\Icons\\spell_magic_lesserinvisibilty"  -- that misspelling is the real filename
fade.cooldown = false
fade.subRegions[1] = F.subglow(true, { 1, 0.45, 0.1, 1 })
fade.load.use_combat = true
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

-- opts.readyGlow = colour  -> "press this NOW": violet pixel glow the moment it is up
-- opts.healthGuard = N     -> that glow is switched back off below N% health
-- opts.notGate = spellId   -> also require that spell to be UNknown (spec exclusion)
local function addCD(id, name, spellId, gate, opts)
  opts = opts or {}
  local icon = reg(F.icon("Priest CD - " .. id, CLASS, 32, 32, 0, 0, nil))
  local trigs = { F.cdTrigger(spellId, name, "showAlways") }
  if opts.healthGuard then trigs[#trigs + 1] = F.healthTrigger(nil) end
  icon.triggers = F.triggers(trigs)
  icon.cooldownTextDisabled = false  -- swipe numbers on; no %p subtext (OmniCC double-number trap)
  icon.useTooltip = true
  icon.conditions = { F.condition(1, "onCooldown", "==", 1, "desaturate", true) }
  if opts.readyGlow then
    icon.subRegions[1] = F.subglow(false, opts.readyGlow)
    icon.conditions[#icon.conditions + 1] =
      F.condition(1, "onCooldown", "==", 0, "sub.1.glow", true)
    if opts.healthGuard then
      -- conditions apply in order and the later match wins, so this one un-glows the
      -- icon when pressing it would be dangerous
      icon.conditions[#icon.conditions + 1] =
        F.condition(2, "percenthealth", "<", tostring(opts.healthGuard), "sub.1.glow", false)
    end
  end
  if gate then
    icon.load.use_spellknown = true
    icon.load.spellknown = gate
  end
  if opts.notGate then
    icon.load.use_not_spellknown = true
    icon.load.not_spellknown = opts.notGate
  end
  fadeOutOfCombat(icon)
  adopt(gCDs, icon)
  return icon
end

local SHADOW_READY = { 0.55, 0.35, 1, 1 }  -- same violet as the Shadowfiend prompt

-- Mind Blast (8s, 5.5s with 5/5 Improved) and SW:Death (12s) are the two presses the
-- Shadow rotation cancels a Mind Flay channel for, so both glow the instant they are up.
addCD("Mind Blast",        "Mind Blast",          8092, 15473, { readyGlow = SHADOW_READY })
addCD("Shadow Word Death", "Shadow Word: Death", 32379, 15473, { readyGlow = SHADOW_READY, healthGuard = 50 })
addCD("Shadowfiend",       "Shadowfiend",        34433, 34433)  -- all specs, 5 min
addCD("Prayer of Mending", "Prayer of Mending",  33076, 33076, { notGate = 15473 })  -- Holy/Disc staple, 10s CD
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

-- =====================================================================
-- v2 additions. Every new aura is created AFTER all pre-existing W.uid()
-- calls so the shipped uids keep their positions in the seeded stream;
-- re-parenting it into the row where it belongs costs nothing.
-- =====================================================================

-- Renew on the current friendly target — Icy Veins ranks it #3 for Holy ("keep this HoT
-- up on the tank and anyone taking consistent damage"), and it is the one heal a priest
-- schedules rather than reacts to. All 12 TBC ranks (139 -> 25222), own-only because
-- Renews from different priests are separate auras, glowing at <=2s so the refresh is
-- already in flight when it drops. It takes the Vampiric Touch slot: VT costs 41 Shadow
-- points, so a priest without Shadowform can never own both.
local renew = reg(F.icon("Priest - Renew", CLASS, 40, 40, -22, 0, nil))
renew.triggers = F.triggers({
  F.auraTrigger("target", true, {
    139, 6074, 6075, 6076, 6077, 6078, 10927, 10928, 10929, 25315, 25221, 25222,
  }, { ownOnly = true }),
})
renew.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
renew.conditions = { F.condition(1, "expirationTime", "<=", "2", "sub.1.glow", true) }
renew.load.use_not_spellknown = true
renew.load.not_spellknown = 15473  -- healer row: everyone except Shadowform
adopt(gBuffs, renew)

-- the buff row is the other always-on layer, so it fades out of combat as well
for _, a in ipairs({ swp, vt, ve, wsoul, innerfire, renew }) do fadeOutOfCombat(a) end

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
