-- generate.lua — Priest TBC All-Specs HUD (v6).
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
--
-- v3 (per-spec load audit — "does this spec PRESS it", not "can it CAST it"):
--   * Holy Procs is no longer ungated: not_spellknown = 15473 (Shadowform). Surge of
--     Light and Holy Concentration are 25- and 30-point Holy talents, so the icon was
--     dead weight in the only spec that could still load it. That leaves exactly four
--     ungated elements (health, mana, threat, Inner Fire), each verified below.
--   * Everything else was audited element-by-element per spec and deliberately kept —
--     see the "Spec gating" section of README.md for the reasoning on the close calls
--     (threat bar + Fade prompt for healers, Fear Ward + Desperate Prayer for Shadow).
--   No element was added, removed or re-ordered, so every uid is unchanged.
--
-- v4 (PvP layer — nine gated elements plus their container group):
--   * Every v4 element carries load.use_size = false with size.multi = { arena, pvp }
--     (or { arena } alone where it reads arena1..arena5). Nothing new loads in a
--     raid, a dungeon or the open world, and no v3 aura was touched, so a PvE
--     player sees exactly the v3 HUD.
--   * Alerts gains four prompts: CC ON ME (any loss of control, with the
--     countdown), FEAR WARD MISSING, MASS DISPEL NOW (target immunity + Mass
--     Dispel ready) and SILENCE NOW (target casting + Silence usable, Shadow).
--   * New "Priest - PvP" column mirrors Alerts on the right with five state
--     read-outs: my trinket down, Will of the Forsaken down, an enemy trinket
--     clock per opponent, Unstable Affliction on a team-mate, and my own CC on
--     each opponent.
--   * NOT built, deliberately: diminishing-returns tracking (no prototype and no
--     library exists — an incomplete DR tracker gets trusted and gets you killed),
--     enemy cooldowns beyond the trinket inference, enemy spec, an interruptible
--     filter (WA disables the arg on TBC), enemy mana (the Power prototype's arena
--     unit support is unverified), and the inverse "hide the threat bar in arena"
--     gate (its open-world behaviour is unproven and it would change a PvE aura).
--
-- v5 (three v4 deferrals resolved against the WeakAuras source; one new aura):
--   * CC ON ME is now colour-coded by controlType, because "which break works" is
--     the decision, not "am I controlled". Same colour language as the mage pack:
--     red stun, purple fear, blue root, green confuse/poly, amber silence/lockout.
--     Verified: subglow is subRegions[1], glow = true and useGlowColor = true, so
--     "sub.1.glowColor" really repaints the glow (with useGlowColor = false the
--     setter runs and nothing changes on screen — the trap this was deferred on).
--     Values are 4-element ARRAYS; a {r=,g=,b=} hash serialises to four nils.
--   * The threat bar and the Fade prompt no longer load in an ARENA. Arena has no
--     threat table, so both were pure clutter there. The open-world worry that
--     blocked this in v4 is settled: GetInstanceTypeAndSize returns the literal
--     string "none" outdoors (WeakAuras.lua:1626 explicit fallthrough), so listing
--     `none` in the multi table keeps them loaded everywhere in PvE.
--   * NEW Priest - Enemy Mana: one bar per arena opponent whose PRIMARY resource
--     is mana, class-coloured, red under 20%. The Mana Burn scoreboard. The Power
--     prototype is present on TBC, its unit arg accepts "arena" (only ClassicEra
--     deletes that value), arena1..5 are registered, and statesParameter = "unit"
--     clones one row per opponent — hence the dynamicgroup parent.
--
-- v6 (the cooldown row now shows what you CANNOT press; no new auras, no new uids):
--   * Six of the nine cooldown icons become genericShowOn = "showOnCooldown" —
--     Shadowfiend, Inner Focus, Power Infusion, Pain Suppression, Lightwell and Fear
--     Ward. Each is situational: a mana cooldown, a burst window, an emergency, a
--     pre-placed well, a pre-fear ward. The icon now exists only while its cooldown
--     runs, carrying the swipe and the countdown, and vanishes when the ability is
--     back. The row is a dynamic group, so the gap closes: ABSENCE IS THE READOUT.
--     Their onCooldown == 1 -> desaturate condition goes with the change — under
--     showOnCooldown every visible icon is on cooldown by definition, so desaturating
--     them all would grey the whole row and make the icons harder to tell apart.
--   * The three press-on-cooldown rotational buttons stay showAlways WITH a ready
--     glow, because a hidden icon cannot announce the moment it comes up: Mind Blast
--     and Shadow Word: Death (violet, the two presses that cancel a Mind Flay), and
--     NEW — Prayer of Mending, which gains the gold Holy glow it never had. PoM is a
--     10s-cooldown cast-on-cooldown staple of the Holy/Disc loop, the most mana-
--     efficient heal in the game, kept rolling on the tank; hiding the healer's most
--     frequent scheduled press would have been exactly the wrong direction.
--     Those three keep their desaturate-while-down condition — they are on screen in
--     both states, so it is still what separates "up" from "down".
--   * Every ready glow is now switched OFF out of combat (inCombat == 0 ->
--     sub.1.glow = false, appended last so it wins). Out of combat every cooldown is
--     up, so the glow was permanent decoration on an idle HUD — and after this pass
--     the out-of-combat row contains nothing BUT those three icons.
--   * No aura added, removed or reordered: only triggers and conditions changed, so
--     all 39 uids are untouched and this imports as an Update.

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

-- v5: keep a PvE element out of the arena, where its mechanic does not exist.
-- There is no "not arena" key — the `size` load arg is a plain multiselect with no
-- `inverse` and no `test`, so the exclusion is spelled out as every OTHER legal
-- instance type. `use_size = false` is MULTI mode (only nil disables the gate).
-- `none` is the value this was deferred on and it is now proven: GetInstanceTypeAndSize
-- guards the "assign size = Type" block with `if inInstance or instanceType ~= "none"`
-- and then falls through to `return "none", "none", nil, nil, 0`, so the open world
-- reports the literal string "none" and the element stays loaded out there.
-- `pvp` (battleground) is kept on purpose: BGs have NPCs and a real threat table.
local function hideInArena(a)
  a.load.use_size = false
  a.load.size = { multi = {
    none = true,        -- open world / city / no instance
    party = true,       -- 5-man normal or heroic
    ten = true,         -- Karazhan, ZA
    twenty = true,      -- legal key, unreachable on TBC; free to list
    twentyfive = true,  -- SSC / TK / Hyjal / BT / Sunwell
    fortyman = true,    -- the vanilla raids
    pvp = true,         -- battleground
  } }
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
hideInArena(threat)  -- v5: no threat table exists in an arena; everywhere else unchanged
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
-- v5: same arena exclusion as the bar that drives it. Trigger 1 is the threat
-- trigger, so this prompt was already unreachable in an arena — the gate makes it
-- unreachable at LOAD time, which is one fewer aura evaluating every frame there.
hideInArena(fade)
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
-- Cooldowns (0,-66): horizontal row. Since v6 the row is INVERTED — it shows
-- what you cannot press. Situational cooldowns appear only while they are
-- down; the three press-on-cooldown rotational buttons stay on screen and
-- glow the instant they are up.
-- =====================================================================
local gCDs = reg(F.dynGroup("Priest - Cooldowns", 0, -66, nil, "HORIZONTAL", "CENTER", 4))
gCDs.animate = false
adopt(top, gCDs)

-- The classification lives in one flag: an icon with a readyGlow is a press-on-cooldown
-- rotational button, everything else is situational.
--
-- opts.readyGlow = colour  -> ROTATIONAL. genericShowOn = "showAlways", so it is on
--                             screen in both states: desaturated while down, and lit by
--                             a pixel glow the moment it is up. The glow IS the
--                             instruction, and a hidden icon could never fire one.
--                             Suppressed out of combat, where everything is always up.
-- opts.healthGuard = N     -> that glow is switched back off below N% health
-- opts.notGate = spellId   -> also require that spell to be UNknown (spec exclusion)
-- (no readyGlow)           -> SITUATIONAL. genericShowOn = "showOnCooldown": the icon
--                             exists only while the cooldown runs, carrying the swipe
--                             and its countdown, and disappears when the ability is
--                             back. The row is a dynamic group, so the gap closes —
--                             absence is the readout. No desaturate condition either:
--                             every visible icon is on cooldown by definition, so
--                             greying them all would only make them harder to tell apart.
local function addCD(id, name, spellId, gate, opts)
  opts = opts or {}
  local rotational = opts.readyGlow ~= nil
  local icon = reg(F.icon("Priest CD - " .. id, CLASS, 32, 32, 0, 0, nil))
  local trigs = { F.cdTrigger(spellId, name, rotational and "showAlways" or "showOnCooldown") }
  if opts.healthGuard then trigs[#trigs + 1] = F.healthTrigger(nil) end
  icon.triggers = F.triggers(trigs)
  icon.cooldownTextDisabled = false  -- swipe numbers on; no %p subtext (OmniCC double-number trap)
  icon.useTooltip = true
  icon.conditions = {}
  if rotational then
    -- desaturate still carries information here: this icon is visible in BOTH states
    icon.conditions[1] = F.condition(1, "onCooldown", "==", 1, "desaturate", true)
    -- the factory's icon prototype already puts a (disabled) subglow at subRegions[1],
    -- so this REPLACES index 1 rather than inserting — every "sub.1.glow" reference in
    -- this pack keeps pointing at a subglow, and the subborder stays at index 2
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
  if rotational then
    -- v6: out of combat every cooldown is up, so the ready-glow would sit lit forever on
    -- an idle HUD. Appended AFTER the fade condition (and so after the glow-on rule) —
    -- later match wins — and it reads the Unit Characteristics trigger fadeOutOfCombat
    -- just added, which is now the last trigger.
    icon.conditions[#icon.conditions + 1] =
      F.condition(#icon.triggers, "inCombat", "==", 0, "sub.1.glow", false)
  end
  adopt(gCDs, icon)
  return icon
end

local SHADOW_READY = { 0.55, 0.35, 1, 1 }  -- same violet as the Shadowfiend prompt
local HOLY_READY   = { 1, 0.85, 0.2, 1 }   -- same gold as the Holy proc row

-- ROTATIONAL (showAlways + ready glow) --------------------------------------------
-- Mind Blast (8s, 5.5s with 5/5 Improved) and SW:Death (12s) are the two presses the
-- Shadow rotation cancels a Mind Flay channel for, so both glow the instant they are up.
addCD("Mind Blast",        "Mind Blast",          8092, 15473, { readyGlow = SHADOW_READY })
addCD("Shadow Word Death", "Shadow Word: Death", 32379, 15473, { readyGlow = SHADOW_READY, healthGuard = 50 })
-- SITUATIONAL (showOnCooldown) ----------------------------------------------------
-- Shadowfiend is a mana cooldown fired at a mana window, and the Alerts column already
-- owns that moment (mana < 50% AND the fiend ready), so the row icon only has to answer
-- "when is it back".
addCD("Shadowfiend",       "Shadowfiend",        34433, 34433)  -- all specs, 5 min
-- ROTATIONAL: the healer's most frequent scheduled press. 10s cooldown, cast on cooldown
-- on the tank — the cheapest heal per point of healing a TBC priest owns — so it takes the
-- gold Holy glow rather than being hidden while it is available.
addCD("Prayer of Mending", "Prayer of Mending",  33076, 33076, { notGate = 15473, readyGlow = HOLY_READY })  -- Holy/Disc staple, 10s CD
-- SITUATIONAL, continued ----------------------------------------------------------
addCD("Inner Focus",       "Inner Focus",        14751, 14751)  -- Disc tier-2 talent, 3 min; paired with a specific big cast
addCD("Power Infusion",    "Power Infusion",     10060, 10060)  -- Disc 31-pt talent, 3 min; a burn-phase window
addCD("Pain Suppression",  "Pain Suppression",   33206, 33206)  -- Disc 41-pt signature, 2 min; an emergency
addCD("Lightwell",         "Lightwell",            724,   724)  -- Holy 40-pt optional talent; placed before a damage phase
addCD("Fear Ward",         "Fear Ward",           6346,  6346)  -- baseline for every priest since 2.3.0 (lvl 20, 3 min CD)

-- =====================================================================
-- Procs (110,24): cloned proc icons, one per active Holy proc
-- =====================================================================
local gProcs = reg(F.dynGroup("Priest - Procs", 110, 24, nil, "RIGHT", "LEFT", 4))
adopt(top, gProcs)

local procs = reg(F.icon("Priest - Holy Procs", CLASS, 32, 32, 0, 0, nil))
procs.triggers = F.triggers({
  -- 33151 Surge of Light (free instant Smite), 34754 Clearcasting (Holy Concentration).
  F.auraTrigger("player", true, { 33151, 34754 }, { showClones = true }),
})
-- v3: inverse-gated off Shadow. Surge of Light sits at tier 6 of the Holy tree (25 points
-- in) and Holy Concentration at tier 7 (30 points in), so a Shadowform build — 31 points
-- into Shadow, 23 into Discipline in the standard 23/0/38 — can never own either proc.
-- The trigger already made this icon impossible for Shadow; the gate makes it impossible
-- to LOAD, which is what "an ungated element must be justified for every spec" asks for.
-- Discipline keeps it loaded on purpose: a 41/20 Disc build stops at tier 5 of Holy and
-- also never procs it, but no single spell id separates "deep Holy" from "deep Disc"
-- without risking a false cut on a Holy build that skipped one of the two talents.
procs.load.use_not_spellknown = true
procs.load.not_spellknown = 15473  -- everyone except Shadowform
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

-- =====================================================================
-- v4 additions — the PvP layer. Every aura below carries an instance-type
-- load gate, so NOTHING here loads in a raid, a dungeon or the open world:
-- a PvE player sees exactly the v3 HUD. Created after every earlier W.uid()
-- call and re-parented into the rows they belong to, so all 29 v3 uids keep
-- their positions in the seeded stream.
-- =====================================================================

-- Load gates (references/pvp.md §1.1). `use_size = false` is NOT "off": a
-- multiselect load arg is active for both true and false and only inert at nil,
-- and false selects MULTI mode, which ORs the listed instance types.
--   pvpLoad(false) -> arena OR battleground
--   pvpLoad(true)  -> arena only. Mandatory for anything that reads arena1..5:
--                     those unit ids do not exist in a battleground, so a
--                     BG-loaded arena element is a permanently blank slot.
local function pvpLoad(arenaOnly, extra)
  local l = F.load(CLASS, {
    use_size = false,
    size = { multi = arenaOnly and { arena = true } or { arena = true, pvp = true } },
  })
  for k, v in pairs(extra or {}) do l[k] = v end
  return l
end

-- GenericTrigger stub: the inert companion fields every non-aura2 trigger table
-- carries in WeakAuras' own exports (they only do anything behind their use_*
-- flag). The factory applies these inside its builders; these triggers are
-- hand-written from the prototypes, so they get the same treatment.
local function gTrigger(t)
  t.names = {}; t.spellIds = {}
  t.debuffType = t.debuffType or "HELPFUL"
  t.subeventPrefix = "SPELL"; t.subeventSuffix = "_CAST_START"
  return t
end

-- ===== the PvP column: state read-outs, mirroring Alerts on the right =====
-- A dynamicgroup, because three of its children are clone sources (clones
-- inside a STATIC group all stack on one spot). It grows upward from the same
-- y as the Alerts column so the two read as a matched pair, and it collapses
-- to nothing whenever no PvP state is live.
local gPvP = reg(F.dynGroup("Priest - PvP", 150, 96, nil, "UP", "BOTTOM", 6))
adopt(top, gPvP)

-- ---- prompt: something is controlling me --------------------------------
-- The Crowd Controlled trigger is the only non-custom-code way to see CC
-- generically WITH its real duration, and the only way to see a Kick /
-- Counterspell school lockout at all (a lockout is not an aura, so no aura
-- trigger can ever find one). No controlType filter: it matches every loss of
-- control effect. iconSource stays -1, so the icon IS the identity of the
-- effect — stun, poly, fear or a locked school — and %p is the countdown that
-- answers "ride it or spend the trinket". NOT combat-gated: the opening Sap
-- and the pre-gate fear land before you are in combat.
--
-- v5 — the glow is colour-coded by controlType, because under CC a player parses
-- COLOUR, never text, and the category is the whole decision:
--   red    stun          the trinket is the only answer
--   purple fear          trinket, or Fear Ward the next one before it lands
--   blue   root          NOT the trinket — a priest has no root break, so this is
--                        "reposition, LoS, and keep casting; you are not helpless"
--   green  confuse/poly  ride it, and hold your DoT/damage: any tick breaks it
--   amber  silence/lockout  your school is gone (every priest defensive is Holy or
--                        Shadow), so trinket EARLIER than you otherwise would
-- Same five colours as the mage pack, on purpose: one language across two classes.
--
-- Mechanically this needs three things and has all three: the subglow really is
-- subRegions[1] (so "sub.1.glowColor" resolves), it was built with a colour so
-- useGlowColor = true (with it false the setter is a silent no-op), and glow = true
-- so SetGlowColor's restart guard passes. Values must be 4-element ARRAYS.
-- The five loss-of-control types with no condition (NONE, CHARM, DISARM, PACIFY,
-- POSSESS) fall back to the base colour below, i.e. red "trinket food" — correct.
local ccOnMe = reg(F.icon("Priest - CC ON ME", CLASS, 44, 44, 0, 0, nil))
ccOnMe.triggers = F.triggers({
  gTrigger{ type = "unit", event = "Crowd Controlled" },
})
ccOnMe.cooldown = false
ccOnMe.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
ccOnMe.subRegions[2] = F.subtext("%p", 16, "INNER_BOTTOM")
ccOnMe.conditions = {
  F.condition(1, "controlType", "==", "STUN",             "sub.1.glowColor", { 1, 0.15, 0.15, 1 }),
  F.condition(1, "controlType", "==", "STUN_MECHANIC",    "sub.1.glowColor", { 1, 0.15, 0.15, 1 }),
  F.condition(1, "controlType", "==", "FEAR",             "sub.1.glowColor", { 0.7, 0.3, 1, 1 }),
  F.condition(1, "controlType", "==", "FEAR_MECHANIC",    "sub.1.glowColor", { 0.7, 0.3, 1, 1 }),
  F.condition(1, "controlType", "==", "CONFUSE",          "sub.1.glowColor", { 0.4, 0.95, 0.5, 1 }),
  F.condition(1, "controlType", "==", "ROOT",             "sub.1.glowColor", { 0.3, 0.7, 1, 1 }),
  F.condition(1, "controlType", "==", "SILENCE",          "sub.1.glowColor", { 1, 0.85, 0.2, 1 }),
  F.condition(1, "controlType", "==", "PACIFYSILENCE",    "sub.1.glowColor", { 1, 0.85, 0.2, 1 }),
  F.condition(1, "controlType", "==", "SCHOOL_INTERRUPT", "sub.1.glowColor", { 1, 0.85, 0.2, 1 }),
}
ccOnMe.load = pvpLoad(false)
alertAnimations(ccOnMe)
adopt(gAlerts, ccOnMe)

-- ---- prompt: Fear Ward is off you AND off cooldown ----------------------
-- Fear Ward is consumed by the first fear, so "missing" is a live state in
-- every arena, not a pre-pull constant. Both triggers must hold, so the prompt
-- is exactly the moment the press exists: re-ward before the next go, and know
-- that until it is back up the first fear costs the trinket.
local fward = reg(F.icon("Priest - FEAR WARD MISSING", CLASS, 44, 44, 0, 0, nil))
fward.triggers = F.triggers({
  F.auraTrigger("player", true, { 6346 }, { matchesShowOn = "showOnMissing" }),
  F.cdTrigger(6346, "Fear Ward", "showOnReady"),
})
fward.iconSource = 0
fward.displayIcon = "Interface\\Icons\\spell_holy_excorcism"
fward.cooldown = false
fward.subRegions[1] = F.subglow(true, { 0.4, 0.8, 1, 1 })
fward.load = pvpLoad(false, { use_spellknown = true, spellknown = 6346 })
alertAnimations(fward)
adopt(gAlerts, fward)

-- ---- prompt: the target went immune AND Mass Dispel is up ---------------
-- Every other class treats Divine Shield / Ice Block / Blessing of Protection
-- as a stop sign; the priest is the one class that can answer it, so this is a
-- press, not a warning. Trigger 1 is first and therefore owns the dynamic
-- info: %p counts down the bubble, which is the whole decision (dispel it now
-- or you burn the kill window waiting it out). Divine Shield 642/1020,
-- Ice Block 45438 (27619 is the older id, kept for safety), Blessing of
-- Protection 1022/5599/10278 — all ranks, all verified on wowhead.com/tbc.
local mdispel = reg(F.icon("Priest - MASS DISPEL NOW", CLASS, 44, 44, 0, 0, nil))
mdispel.triggers = F.triggers({
  F.auraTrigger("target", true, { 642, 1020, 45438, 27619, 1022, 5599, 10278 }),
  F.cdTrigger(32375, "Mass Dispel", "showOnReady"),
})
mdispel.iconSource = 0
mdispel.displayIcon = "Interface\\Icons\\spell_arcane_massdispel"
mdispel.cooldown = false
mdispel.subRegions[1] = F.subglow(true, { 1, 0.85, 0.2, 1 })
mdispel.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
mdispel.load = pvpLoad(false, { use_spellknown = true, spellknown = 32375 })
alertAnimations(mdispel)
adopt(gAlerts, mdispel)

-- ---- prompt: the target is casting AND Silence is castable (Shadow) -----
-- No spell-id filter, on purpose: WeakAuras disables the "interruptible" arg
-- on TBC clients outright (enable = not IsTBC()), so there is no way to ask
-- "can I interrupt this", and a whitelist of every enemy heal is unmaintainable.
-- The second trigger is Action Usable, which folds cooldown, mana AND range
-- into one boolean — that is what stops the prompt from screaming while
-- Silence is down. %p is the remaining cast time.
local silence = reg(F.icon("Priest - SILENCE NOW", CLASS, 44, 44, 0, 0, nil))
silence.triggers = F.triggers({
  gTrigger{ type = "unit", event = "Cast", unit = "target", use_unit = true },
  gTrigger{ type = "spell", event = "Action Usable",
            use_spellName = true, spellName = 15487, realSpellName = "Silence",
            use_exact_spellName = true, use_ignoreoverride = true },
})
silence.iconSource = 0
silence.displayIcon = "Interface\\Icons\\spell_shadow_impphaseshift"
silence.cooldown = false
silence.subRegions[1] = F.subglow(true, { 0.55, 0.35, 1, 1 })
silence.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
silence.load = pvpLoad(false, { use_spellknown = true, spellknown = 15487 })
alertAnimations(silence)
adopt(gAlerts, silence)

-- ---- state: my own PvP trinket is DOWN ----------------------------------
-- Visible ONLY while on cooldown, so an empty column means "your break is
-- ready" — the normal case stays silent. One trigger per item id, OR-combined:
-- the equipment-slot trigger would read whatever sits in slot 13/14, so a PvE
-- on-use trinket would report "trinket down" while the medallion is ready, and
-- that false negative is a death in the one decision this element exists for.
-- Priest-usable ids, both factions (wowhead.com/tbc): 18862/18851 Insignia
-- (5 min), 30349/30346 Medallion (2 min), 37864/37865 the 2.4 epic Medallion.
local trinket = reg(F.icon("Priest - Trinket DOWN", CLASS, 32, 32, 0, 0, nil))
local trinketTrigs = {}
for i, itemId in ipairs({ 18862, 18851, 30349, 30346, 37864, 37865 }) do
  trinketTrigs[i] = gTrigger{
    type = "item", event = "Cooldown Progress (Item)",
    use_itemName = true, itemName = itemId,          -- NUMERIC id; a name never resolves
    use_genericShowOn = true, genericShowOn = "showOnCooldown",
  }
end
trinket.triggers = F.triggers(trinketTrigs, { disjunctive = "any" })
trinket.cooldownTextDisabled = false  -- swipe numbers; no %p subtext (OmniCC double-number trap)
trinket.desaturate = true             -- greyed = unavailable, readable without reading
trinket.load = pvpLoad(false)
adopt(gPvP, trinket)

-- ---- state: Will of the Forsaken is DOWN (Forsaken only) ----------------
-- On 2.4.3 WotF does not share a cooldown with the medallion (that arrived in
-- 3.3), so an undead priest genuinely carries two breaks — and whether the
-- second one is up is what decides if the first gets spent on a Sap. Gated on
-- the racial's own id, so it simply never loads for anyone else.
local wotf = reg(F.icon("Priest - Will of the Forsaken DOWN", CLASS, 32, 32, 0, 0, nil))
wotf.triggers = F.triggers({ F.cdTrigger(7744, "Will of the Forsaken", "showOnCooldown") })
wotf.cooldownTextDisabled = false
wotf.desaturate = true
wotf.load = pvpLoad(false, { use_spellknown = true, spellknown = 7744 })
adopt(gPvP, wotf)

-- ---- state: an opponent's trinket is on cooldown (arena) ----------------
-- There is no API that reads another player's cooldowns on 2.5.x. This is the
-- sanctioned inference: see the cast, start your own 2-minute clock. One clone
-- per opponent (unit = "arena" clones, hence the dynamicgroup parent). Spell
-- 42292 "PvP Trinket" is what every medallion and insignia casts (verified on
-- the item pages); the 120s duration is the medallion, which is what everyone
-- wears at 70 — an opponent still on the 5-minute vanilla insignia will show a
-- clock that ends early.
local etrinket = reg(F.icon("Priest - Enemy Trinket", CLASS, 32, 32, 0, 0, nil))
etrinket.triggers = F.triggers({
  gTrigger{ type = "event", event = "Spell Cast Succeeded",
            unit = "arena", use_unit = true,
            use_spellId = true, spellId = { "42292" },
            duration = "120" },  -- REQUIRED on a timedrequired trigger; missing = 1s flash
})
etrinket.cooldownTextDisabled = false
etrinket.load = pvpLoad(true)
adopt(gPvP, etrinket)

-- ---- state: Unstable Affliction on a team-mate (arena) ------------------
-- Dispel Magic is the highest-frequency button a TBC priest owns, and this is
-- the one state that must interrupt the habit: dispelling UA costs ~1050
-- damage and a 5s silence, which is the warlock's whole game plan. One clone
-- per affected ally, all three ranks (30108/30404/30405), not own-only.
-- Arena-gated on purpose: in a 40-man battleground this would be a permanent
-- wall of icons for people you will never dispel.
local uaAlly = reg(F.icon("Priest - UA on Ally", CLASS, 36, 36, 0, 0, nil))
uaAlly.triggers = F.triggers({
  F.auraTrigger("group", false, { 30108, 30404, 30405 },
    { showClones = true, combinePerUnit = true, perUnitMode = "affected" }),
})
uaAlly.cooldown = false
uaAlly.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
uaAlly.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
uaAlly.load = pvpLoad(true)
adopt(gPvP, uaAlly)

-- ---- state: my control effects on the enemy team (arena) ---------------
-- One clone per controlled opponent, own-only, with the remaining duration:
-- Psychic Scream (8122/8124/10888/10890) and Mind Control (605/10911/10912)
-- say HOLD DAMAGE — a tick breaks them; Silence (15487) on their healer says
-- GO, and counts down exactly how long the kill window lasts. No glow: this is
-- a state read-out, and in this pack glow means "press something".
local myCC = reg(F.icon("Priest - My CC Out", CLASS, 36, 36, 0, 0, nil))
myCC.triggers = F.triggers({
  F.auraTrigger("arena", false, { 8122, 8124, 10888, 10890, 15487, 605, 10911, 10912 },
    { ownOnly = true, showClones = true, combinePerUnit = true, perUnitMode = "affected" }),
})
myCC.cooldown = false
myCC.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
myCC.load = pvpLoad(true)
adopt(gPvP, myCC)

-- =====================================================================
-- v5 addition — the Mana Burn scoreboard. Created after every earlier
-- W.uid() call, so all 39 v4 uids keep their positions in the seeded stream.
-- =====================================================================

-- ---- state: enemy mana, one bar per opponent (arena) --------------------
-- Mana Burn is the priest's second win condition and it is the only one you
-- cannot see: burning 700-750 mana a cast into a 9k healer is a decision you
-- have to be able to score. This is that scoreboard.
--
-- unit = "arena" makes the Power prototype clone one state per opponent
-- (statesParameter = "unit"), hence the dynamicgroup parent — the same
-- mechanism the enemy trinket clock and the CC rows already use.
--
-- Both use_powertype AND powertype = 0 are required: without the flag the
-- trigger silently reads whatever bar the opponent primarily uses, so a rogue
-- row would show ENERGY as if it were mana. use_requirePowerType then hides
-- every opponent whose primary resource is not mana, so rogues and warriors
-- never take up a row and the column is exactly the people worth burning.
--
-- Colour is identity: standard class colours, which every player already reads
-- without thinking (warrior red and rogue yellow can never appear — those two
-- are filtered out by requirePowerType, which is also why red is free to mean
-- something else here). Under 20% the bar goes red: that is roughly two heals
-- left, the point where mana, not damage, is the fastest way to win.
--
-- Arena-only, never battleground: arena1..arena5 do not exist in a BG, so a
-- BG-loaded copy would be permanently blank rows.
local emana = reg(F.aurabar("Priest - Enemy Mana", CLASS, 120, 14, 0, 0, nil,
  { 0.25, 0.5, 0.92, 1 }))
local emanaTrigger = F.powerTrigger(0)   -- 0 = Mana, with use_powertype set
emanaTrigger.unit = "arena"              -- clones: arena1..arena5
emanaTrigger.use_requirePowerType = true -- mana must be their PRIMARY bar
emana.triggers = F.triggers({ emanaTrigger })
emana.subRegions[2] = F.subtext("%percentpower%%", 12, "INNER_RIGHT", "percentpower")
emana.subRegions[3] = F.subborder("bar")
emana.conditions = {
  F.condition(1, "class", "==", "DRUID",   "barColor", { 1, 0.49, 0.04, 1 }),
  F.condition(1, "class", "==", "HUNTER",  "barColor", { 0.67, 0.83, 0.45, 1 }),
  F.condition(1, "class", "==", "MAGE",    "barColor", { 0.41, 0.8, 0.94, 1 }),
  F.condition(1, "class", "==", "PALADIN", "barColor", { 0.96, 0.55, 0.73, 1 }),
  F.condition(1, "class", "==", "PRIEST",  "barColor", { 1, 1, 1, 1 }),
  F.condition(1, "class", "==", "SHAMAN",  "barColor", { 0, 0.44, 0.87, 1 }),
  F.condition(1, "class", "==", "WARLOCK", "barColor", { 0.58, 0.51, 0.79, 1 }),
  -- last, so it wins over the class colour: nearly dry, go now
  F.condition(1, "percentpower", "<", "20", "barColor", { 0.9, 0.12, 0.12, 1 }),
}
emana.load = pvpLoad(true)
adopt(gPvP, emana)

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
