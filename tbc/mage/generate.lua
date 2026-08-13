-- tbc/mage/generate.lua — Mage "Arcane & Frost" HUD v3.
-- Run: lua5.1 tbc/mage/generate.lua   (toolkit libs live in tools/tbc-weakaura-creator/scripts/)
-- Produces all-specs.txt: a "!WA:2!" string importable in game (internalVersion 45).
--
-- Every spell id below was verified on wowhead.com/tbc (re-checked 2026-08-11), ids
-- only, never names (zhCN-safe): aura triggers carry ALL ranks as strings, cooldown
-- triggers carry the numeric rank-1 id. NB the classic->TBC id swap:
--   TBC Cold Snap = 11958 (8 min CD), TBC Ice Block = 45438 (5 min CD).
--
-- v2 (rotation review fixes): mana conserve breakpoint on the mana bar, Arcane Power /
-- Icy Veins burn-window timers, a mana gem prompt, an Ice Lance shatter prompt, Cold Snap
-- turned into a sequencing prompt instead of a use-on-cooldown icon, threat bar gated to
-- party/raid, Clearcasting gated to combat, spell-known gates on every cooldown icon.
-- UID stream is append-only: no existing W.uid() call moved, so re-import offers Update.
--
-- v3 (per-spec audit — gating only, no element added or removed, no uid moved): the
-- question changed from "can this spec CAST it" to "does this spec PRESS it as part of
-- playing well". Three elements failed that test somewhere:
--   * the mana conserve breakpoint (line + lit marker) encodes Arcane's burn/conserve
--     switch — Frost has no second rotation to switch into, so it is now Arcane-only;
--   * the Ice Lance SHATTER prompt is hidden from deep Arcane (inverse gate), whose
--     guides state outright that the spec does not use Ice Lance or shatter combos;
--   * the Evocation prompt gained its own spell-known gate so it stops firing for
--     mages below level 20, who do not have the button it asks for.
-- Everything else survived the audit unchanged: both specs press Icy Veins, Cold Snap
-- (Arcane IV spends 21 Frost points precisely for Icy Veins + Cold Snap), Evocation,
-- mana gems, Clearcasting (both raid builds take Arcane Concentration), Counterspell,
-- Blink, Invisibility and Ice Block, and every spec-specific piece was already gated on
-- the ability that defines it.
--
-- v4 (PvP layer — nine NEW auras, no existing aura touched): a second HUD that exists only
-- inside arenas and battlegrounds. Every one of the nine carries its own Instance Size Type
-- load gate (arena + battleground, or arena alone where it reads arena1..arena5), so a raid
-- or dungeon mage sees byte-for-byte the v3 HUD. One new dynamic group, "Mage - PvP", holds
-- the state read-outs opposite the Alerts column; three new prompts join the Alerts flow.
-- No custom code: every composite is a multi-trigger AND, an OR (disjunctive "any"), or a
-- condition. What is NOT in it — diminishing returns, enemy cooldown reads, enemy spec,
-- "only interruptible casts" — is listed with its reason at the top of the v4 section.

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

-- Multi-check condition (WA stores an ANDed group as trigger = -2, variable = "AND", with
-- the sub-checks in `checks`; bool sub-checks compare `value` 1/0 and ignore `op`).
-- F.condition only expresses a single check, so combined states are built here.
local function allOf(checks, property, value)
  return {
    check = { trigger = -2, variable = "AND", checks = checks },
    changes = { [1] = { property = property, value = value } },
  }
end

-- Item triggers. The factory has no item builder (no earlier pack needed one), so these
-- come straight from the WeakAuras prototypes: "Cooldown Progress (Item)" takes a NUMERIC
-- itemName (the item id) plus genericShowOn exactly like the spell version, and "Item
-- Count" takes the same id with use_exact_itemName so the count is read off the id instead
-- of a localized GetItemInfo name lookup (which is nil until the item is cached).
local function itemTrigger(event, itemId, extra)
  local tr = {
    type = "item", event = event,
    use_itemName = true, itemName = itemId,
    names = {}, spellIds = {}, debuffType = "HELPFUL",
    subeventPrefix = "SPELL", subeventSuffix = "_CAST_START",
  }
  for k, v in pairs(extra or {}) do tr[k] = v end
  return tr
end

-- Power trigger filtered on percent of max mana (raw mana varies too much with gear).
local function manaPctTrigger(op, pct)
  local tr = F.powerTrigger(0)
  tr.use_percentpower = true
  tr.percentpower = tostring(pct)
  tr.percentpower_operator = op
  return tr
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
-- v2: escalating colour tiers, so the bar itself is the danger read-out that the Ice Block
-- prompt (which fires at 30%) answers. Severe tier last — later conditions overwrite.
hp.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "percenthealth", "<", "50", "barColor", { 1, 0.6, 0.1, 1 }),
  F.condition(1, "percenthealth", "<", "30", "barColor", { 0.9, 0.12, 0.12, 1 }),
}
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
-- v2: party/raid only, like the flash overlay and the Invisibility prompt. Solo you are
-- always the aggro target, so ungated the bar sat pinned red for every quest mob.
threat.load.use_ingroup = true
threat.load.ingroup = IN_GROUP
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
ib.subRegions[1] = F.subglow(false, { 0.4, 0.85, 1, 1 })  -- preset color, lit by condition
ib.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
-- v2: 60 s shield on a 30 s recast, so refresh BEFORE it drops — the MISSING alert can
-- only fire once the shield is already gone, which concedes an unshielded gap every time.
ib.conditions = { F.condition(1, "expirationTime", "<=", "5", "sub.1.glow", true) }
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
cc.load.use_combat = true   -- v2: a proc out of combat is not a decision
alertAnims(cc)
adopt(gAlerts, cc)

-- Mana < 30% AND Evocation ready, in combat: channel now, not at 0.
local evo = reg(F.icon("Mage - Evocation Prompt", CLASS, 40, 40, 0, 0, nil))
evo.triggers = F.triggers({ manaPctTrigger("<", 30), F.cdTrigger(12051, "Evocation", "showOnReady") })
evo.iconSource = 0
evo.displayIcon = "Interface\\Icons\\Spell_Nature_Purge"
evo.cooldown = false
evo.subRegions[1] = F.subglow(true, { 0.3, 0.7, 1, 1 })
evo.load.use_combat = true
-- v3: both specs evocate, but a cooldown trigger on a spell you have not trained reports
-- "ready", so below level 20 this prompted a button that does not exist. Its own rank-1 id
-- is the right gate — it scopes the levelling case without touching either spec.
evo.load.use_spellknown = true
evo.load.spellknown = 12051
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

-- v2: every icon is Spell Known gated (v1 left Evocation/Counterspell/Blink permanently lit
-- for mages below level 20/24/32), and the three use-on-cooldown burst CDs glow the moment
-- they come up IN COMBAT — out of combat the row stays still.
local cdList = {
  { "Arcane Power",           12042, true  },  -- Arcane 31: 3 min burst, press on CD
  { "Presence of Mind",       12043, false },  -- Arcane 21: instant cast, saved for a window
  { "Icy Veins",              12472, true  },  -- both 40/0/21 arcane and frost talent it
  { "Summon Water Elemental", 31687, true  },  -- Frost 41: 3 min pet, press on CD
  { "Cold Snap",              11958, false },  -- Frost 21: 8 min, sequencing rebuilt below
  { "Ice Block",              45438, false },  -- Frost 31: 5 min immunity, reactive
  { "Evocation",              12051, false },  -- 8 min mana refill, prompted by mana
  { "Counterspell",           2139,  false },  -- 24 s interrupt, reactive
  { "Blink",                  1953,  false },  -- 15 s reposition
  { "Invisibility",           66,    false },  -- 5 min threat drop, prompted by threat
}
for _, e in ipairs(cdList) do
  local icon = reg(F.icon("Mage CD - " .. e[1], CLASS, 32, 32, 0, 0, nil))
  icon.cooldownTextDisabled = false   -- swipe numbers here; no %p subtext (OmniCC doubles)
  icon.useTooltip = true
  icon.conditions = { F.condition(1, "onCooldown", "==", 1, "desaturate", true) }
  if e[3] then
    -- Unit Characteristics is always active, so trigger 1 still drives icon and swipe.
    icon.triggers = F.triggers({ F.cdTrigger(e[2], e[1], "showAlways"), F.unitCharTrigger() })
    icon.subRegions[1] = F.subglow(false, { 1, 0.85, 0.2, 1 })
    icon.conditions[2] = allOf({
      { trigger = 1, variable = "onCooldown", value = 0 },
      { trigger = 2, variable = "inCombat", value = 1 },
    }, "sub.1.glow", true)
  else
    icon.triggers = F.triggers({ F.cdTrigger(e[2], e[1], "showAlways") })
  end
  icon.load.use_spellknown = true
  icon.load.spellknown = e[2]
  adopt(gCDs, icon)
end

-- Cold Snap is not a press-on-cooldown button: it resets the Frost cooldowns, so it is
-- only worth pressing once Icy Veins AND Water Elemental have been spent. The icon keeps
-- showing its own 8 min cooldown (trigger 1, showAlways, disjunctive "any"), and glows only
-- when both resets are banked and Cold Snap itself is up. A mage who never learned Water
-- Elemental simply never gets the glow — the icon still behaves as before.
local coldsnap = byId["Mage CD - Cold Snap"]
coldsnap.triggers = F.triggers({
  F.cdTrigger(11958, "Cold Snap", "showAlways"),
  F.cdTrigger(12472, "Icy Veins", "showOnCooldown"),
  F.cdTrigger(31687, "Summon Water Elemental", "showOnCooldown"),
}, { disjunctive = "any" })
coldsnap.subRegions[1] = F.subglow(false, { 0.4, 0.9, 1, 1 })
coldsnap.conditions[2] = allOf({
  { trigger = 1, variable = "onCooldown", value = 0 },
  { trigger = 2, variable = "show", value = 1 },
  { trigger = 3, variable = "show", value = 1 },
}, "sub.1.glow", true)

-- ===== v2 additions ==========================================================
-- NEW auras only from here down: every W.uid() call below is appended AFTER the whole v1
-- stream, so all 25 v1 auras keep their uid and the in-game import still offers "Update".
-- They are re-parented into the v1 groups (re-parenting is free; uid ORDER is what matters).

-- Mana conserve breakpoint. Arcane's whole game is spending the mana budget to zero by the
-- time the boss dies: above the line keep burning Arcane Blast, below it drop to the
-- 3x Arcane Blast / 3x Frostbolt conserve cycle (Icy Veins puts the switch at ~1500-3000
-- mana, i.e. roughly 30% of a raid pool — a percentage keeps it honest across gear).
-- The dim line is always there; the lit line pops in the moment mana crosses it.
local MANA_CONSERVE_PCT = 30
local MANA_LINE_X = -86 + math.floor(1.72 * MANA_CONSERVE_PCT)   -- 172-wide bar centred on 0
local manaLine = reg(F.texture("Mage - Mana Conserve Line", CLASS, 2, 16, MANA_LINE_X, -27, nil,
  F.TEX_SQUARE, { 1, 0.75, 0.2, 0.55 }))
manaLine.triggers = F.triggers({ F.powerTrigger(0), F.unitCharTrigger() })
manaLine.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }
-- v3: Arcane only. The line marks the point where Arcane STOPS spamming Arcane Blast and
-- starts the 3x Arcane Blast / 3x Frostbolt conserve cycle — it is the switch between two
-- rotations. Frost has no second rotation: it is Frostbolt spam all the way down, and its
-- low-mana actions (Evocation, mana gem) already have their own prompts, both of which
-- carry their own thresholds. So for Frost the line marked nothing pressable.
manaLine.load.use_spellknown = true
manaLine.load.spellknown = 12042      -- Arcane Power == deep-Arcane spec gate
adopt(gRes, manaLine)

local manaLit = reg(F.texture("Mage - Mana Conserve Lit", CLASS, 4, 18, MANA_LINE_X, -27, nil,
  F.TEX_SQUARE, { 1, 0.75, 0.2, 1 }))
manaLit.blendMode = "ADD"
manaLit.triggers = F.triggers({ manaPctTrigger("<=", MANA_CONSERVE_PCT) })
manaLit.load.use_combat = true   -- drinking after a pull is not a rotation decision
manaLit.load.use_spellknown = true   -- v3: Arcane only, with the line it lights
manaLit.load.spellknown = 12042
manaLit.animation.start  = F.animPreset("shrink", "0.25", "easeOut")  -- WA "shrink" = UI "Grow"
manaLit.animation.finish = F.animPreset("fade", "0.2")
adopt(gRes, manaLit)

-- Burn windows. A cooldown trigger reports the 3 min recharge, never the 15/20 s window, so
-- v1 had no clock on the burst itself. Buff auras give the real one: Arcane Power 12042
-- (15 s) left of the shared slot, Icy Veins 12472 (20 s) right of it. Arcane Power glows in
-- its last 5 s — that is the Presence of Mind + Arcane Blast finisher cue.
local apw = reg(F.icon("Mage - Arcane Power Window", CLASS, 34, 34, -48, 0, nil))
apw.triggers = F.triggers({ F.auraTrigger("player", true, { 12042 }) })
apw.subRegions[1] = F.subglow(false, { 1, 0.4, 0.95, 1 })
apw.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
apw.conditions = { F.condition(1, "expirationTime", "<=", "5", "sub.1.glow", true) }
apw.load.use_spellknown = true
apw.load.spellknown = 12042
adopt(gBuffs, apw)

local ivw = reg(F.icon("Mage - Icy Veins Window", CLASS, 34, 34, 48, 0, nil))
ivw.triggers = F.triggers({ F.auraTrigger("player", true, { 12472 }) })
ivw.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
ivw.load.use_spellknown = true
ivw.load.spellknown = 12472
adopt(gBuffs, ivw)

-- Mana gem. Mana Emerald (item 22044, ~2400 mana, 2 min) is free damage the moment it is
-- not overheal: prompt at <70% mana so the restore is never wasted, and only when a gem is
-- actually in the bags (Item Count) — no gem, no nag.
local MANA_EMERALD = 22044
local gem = reg(F.icon("Mage - Mana Gem Prompt", CLASS, 40, 40, 0, 0, nil))
gem.triggers = F.triggers({
  manaPctTrigger("<", 70),
  itemTrigger("Cooldown Progress (Item)", MANA_EMERALD,
    { use_genericShowOn = true, genericShowOn = "showOnReady" }),
  itemTrigger("Item Count", MANA_EMERALD,
    { use_exact_itemName = true, use_count = true, count = "1", count_operator = ">=" }),
})
gem.iconSource = 0
gem.displayIcon = "Interface\\Icons\\INV_Misc_Gem_Stone_01"
gem.cooldown = false
gem.subRegions[1] = F.subglow(true, { 0.35, 0.95, 0.55, 1 })
gem.load.use_combat = true
alertAnims(gem)
adopt(gAlerts, gem)

-- Shatter window. Ice Lance (30455) does triple damage into a frozen target, so the freeze
-- is the only reactive decision Frost has outside a raid: Frost Nova (all 5 ranks), the
-- Frostbite root and the Water Elemental's Freeze all open it. NOT ownOnly on purpose — the
-- pet's Freeze and a partner's Nova freeze your target just as well. The swipe and %p run
-- off the debuff, so the icon is also the window clock.
local FROZEN = { 122, 865, 6131, 10230, 27088, 12494, 33395 }
local shatter = reg(F.icon("Mage - Ice Lance SHATTER", CLASS, 40, 40, 0, 0, nil))
shatter.triggers = F.triggers({
  F.auraTrigger("target", false, FROZEN),
  F.cdTrigger(30455, "Ice Lance", "showOnReady"),
})
shatter.iconSource = 0
shatter.displayIcon = "Interface\\Icons\\Spell_Frost_FrostBlast"
shatter.subRegions[1] = F.subglow(true, { 0.55, 0.9, 1, 1 })
shatter.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
shatter.load.use_combat = true
shatter.load.use_spellknown = true
shatter.load.spellknown = 30455
-- v3: hidden from deep Arcane. Ice Lance is trained at 66 by EVERY mage, so the positive
-- gate above scopes the levelling case but not the spec: 40/0/21 Arcane loaded a prompt it
-- never acts on. Its rotation is Arcane Blast with Frostbolt as the mana filler, and the
-- guides say outright that Arcane uses neither Ice Lance nor Frost Nova/shatter combos —
-- it also has neither Frostbite nor the Water Elemental, so two of the three ways the
-- window opens do not exist for it. Frost keeps the prompt: Ice Lance into a frozen target
-- is its one reactive button outside a raid.
-- Inverse gate: there is no negated form of `spellknown` (use_spellknown = false means
-- IGNORE, not "must not know"), so WA exposes a separate `not_spellknown` arg — verified
-- in Prototypes.lua's load prototype: test = "not WeakAuras.IsSpellKnownForLoad(%s, %s)".
--   * needs WeakAuras 5.4.0+; on an older client the unknown field is ignored and the
--     prompt simply loads for everyone (the v2 behaviour), so it degrades gracefully.
--   * do NOT set use_exact_not_spellknown: with `exact` falsy, IsSpellKnownForLoad
--     resolves a rank-1 id through the spell name to whatever rank the player has.
--   * 12042 (Arcane Power) is a true discriminator, not a shallow dip: it is the 31-point
--     Arcane capstone, so no Frost build can reach it while keeping deep Frost.
shatter.load.use_not_spellknown = true
shatter.load.not_spellknown = 12042
alertAnims(shatter)
adopt(gAlerts, shatter)

-- ===== v4 additions: the PvP layer ==========================================
-- NEW auras only from here down, appended after the whole v2/v3 uid stream: the 32
-- existing auras keep their uid, so a re-import still offers "Update".
--
-- EVERYTHING below is gated on Instance Size Type, so a PvE player sees no change at all:
--   PVP   = arena OR battleground
--   ARENA = arena only, for anything that reads arena1..arena5 — those unit ids do not
--           exist in a battleground, where such an element would be a permanently blank slot
-- `use_size = false` is not "off": multiselect load args are inert only at nil; false
-- selects MULTI mode, which ORs the listed instance types. Load is per aura on purpose —
-- a group's load is not a child gate, and per-child gates are what let the dynamic groups
-- collapse their gaps.
--
-- Deliberately NOT built (each would be a lie, not a feature):
--   * diminishing returns. WeakAuras has no DR prototype and no bundled DR library, so any
--     DR read-out here would be a hand-rolled 18 s timer that models the reset window rather
--     than the category state — wrong the moment two spells share a category, and worse than
--     nothing because it gets trusted. The Polymorph row below is a plain remaining-duration
--     timer on MY OWN poly and nothing more.
--   * "only show casts I can interrupt". WeakAuras disables the Cast prototype's
--     interruptible arg on TBC clients outright (enable = not IsTBC()), so emitting it does
--     nothing; the prompt is built from "target is casting" AND "Counterspell is usable".
--   * enemy cooldown reads and enemy spec detection. No 2.5.x API exposes either. The enemy
--     trinket row is an inference started by SEEING the cast, not a read.
--   * hiding the threat bar/flash inside arena. The only spelling is the inverse size gate
--     (every non-PvP instance type listed), and WeakAuras only assigns `size` at all inside
--     `if inInstance or instanceType ~= "none"` — in the open world the value is not proven
--     to be "none", so that gate can silently unload the bars everywhere outside instances.
--     A PvE regression is a worse trade than two dead bars in arena; left alone until the
--     open-world value is confirmed in game.
local function pvpLoad(arenaOnly)
  local l = F.load(CLASS, { use_size = false })
  l.size = arenaOnly and { multi = { arena = true } }
                      or { multi = { arena = true, pvp = true } }
  return l
end

-- The PvP column: state read-outs, mirroring the Alerts column on the other side of the
-- character (Alerts sits at -150 and grows up; this sits at +150 and grows down). It must
-- be a dynamic group — two of its children are clone sources, one row per arena opponent,
-- and clones inside a static group stack on a single spot.
local gPvP = reg(F.dynGroup("Mage - PvP", 150, 96, nil, "DOWN", "TOP", 6))
adopt(top, gPvP)

-- CC ON ME. Which break works is the decision, not "am I CC'd": root -> Blink (Blink breaks
-- roots, never stuns), stun -> trinket, fear -> trinket, polymorph -> ride it out (any damage
-- breaks it), school lockout -> Ice Block / Nova / Barrier are all Frost and all gone, so
-- trinket EARLIER than you would otherwise. The Crowd Controlled trigger is the only
-- non-custom-code way to see this generically with a real duration, and the only way to see
-- a Counterspell/Kick school lockout at all (a lockout is not an aura, so no aura trigger can
-- ever find it). Colour carries the category and %p the countdown — under a stun a player
-- parses colour, never text. No combat gate: the opener Sap lands out of combat.
local ccme = reg(F.icon("Mage - CC ON ME", CLASS, 44, 44, 0, 0, nil))
ccme.triggers = F.triggers({ { type = "unit", event = "Crowd Controlled" } })
ccme.cooldown = false
ccme.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })   -- red default = "trinket food"
ccme.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
ccme.conditions = {
  F.condition(1, "controlType", "==", "STUN", "sub.1.glowColor", { 1, 0.15, 0.15, 1 }),
  F.condition(1, "controlType", "==", "STUN_MECHANIC", "sub.1.glowColor", { 1, 0.15, 0.15, 1 }),
  F.condition(1, "controlType", "==", "FEAR", "sub.1.glowColor", { 0.7, 0.3, 1, 1 }),
  F.condition(1, "controlType", "==", "FEAR_MECHANIC", "sub.1.glowColor", { 0.7, 0.3, 1, 1 }),
  F.condition(1, "controlType", "==", "CONFUSE", "sub.1.glowColor", { 0.4, 0.95, 0.5, 1 }),
  F.condition(1, "controlType", "==", "ROOT", "sub.1.glowColor", { 0.3, 0.7, 1, 1 }),
  F.condition(1, "controlType", "==", "SILENCE", "sub.1.glowColor", { 1, 0.85, 0.2, 1 }),
  F.condition(1, "controlType", "==", "PACIFYSILENCE", "sub.1.glowColor", { 1, 0.85, 0.2, 1 }),
  F.condition(1, "controlType", "==", "SCHOOL_INTERRUPT", "sub.1.glowColor", { 1, 0.85, 0.2, 1 }),
}
ccme.load = pvpLoad(false)
alertAnims(ccme)
adopt(gAlerts, ccme)

-- COUNTERSPELL NOW. The highest-value press a mage owns: 8 s school lockout on a 24 s
-- cooldown, and a healer locked out of Holy for 8 s is a kill window with zero CC spent.
-- Three triggers ANDed: target is casting, Counterspell is genuinely castable (Action Usable
-- folds cooldown + mana into one boolean, so the prompt is never a lie), and the target is
-- hostile (aura/unit triggers do no hostility filtering of their own — that is a separate
-- Unit Characteristics trigger). No spell whitelist: interruptibility does not exist on TBC
-- and an id list of every enemy heal is unmaintainable, so junk casts are the player's read.
-- The prompt simply does not exist while Counterspell is down, which is what stops it
-- training the player to ignore it. Desaturates when the target is out of the 30 yd range.
local csnow = reg(F.icon("Mage - COUNTERSPELL NOW", CLASS, 44, 44, 0, 0, nil))
csnow.triggers = F.triggers({
  { type = "unit", event = "Cast", unit = "target", use_unit = true },
  { type = "spell", event = "Action Usable", use_spellName = true, spellName = 2139,
    use_exact_spellName = true, use_ignoreoverride = true },
  { type = "unit", event = "Unit Characteristics", unit = "target", use_unit = true,
    use_hostility = true, hostility = "hostile" },
})
csnow.iconSource = 0
csnow.displayIcon = "Interface\\Icons\\Spell_Frost_IceShock"
csnow.subRegions[1] = F.subglow(true, { 1, 0.85, 0.2, 1 })
csnow.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")   -- remaining cast time
csnow.conditions = { F.condition(2, "spellInRange", "==", 0, "desaturate", true) }
csnow.load = pvpLoad(false)
csnow.load.use_spellknown = true
csnow.load.spellknown = 2139
alertAnims(csnow)
adopt(gAlerts, csnow)

-- TARGET IMMUNE. Everything a mage does is a spell, so casting into one of these burns the
-- whole burst for zero: Ice Block (45438), Divine Shield (642/1020), Cloak of Shadows
-- (31224, 90% spell resist), Spell Reflection (23920, your next spell comes back at you),
-- Bestial Wrath (19574) and The Beast Within (34471), which make the target uncontrollable
-- so Polymorph and Nova are wasted too. Stop, re-pool, swap, or wait it out.
-- Trimmed from the shared list on purpose: Blessing of Protection (physical immunity only —
-- Frostbolt lands through it) and Deterrence (dodge/parry, does nothing to spells) change
-- no mage decision, and a prompt that fires when nothing is decidable is noise.
local IMMUNE = { 45438, 642, 1020, 31224, 23920, 19574, 34471 }
local immune = reg(F.icon("Mage - TARGET IMMUNE", CLASS, 44, 44, 0, 0, nil))
immune.triggers = F.triggers({
  F.auraTrigger("target", true, IMMUNE),   -- any caster: it is the target's state that matters
  { type = "unit", event = "Unit Characteristics", unit = "target", use_unit = true,
    use_hostility = true, hostility = "hostile" },
})
immune.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
immune.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
immune.load = pvpLoad(false)
alertAnims(immune)
adopt(gAlerts, immune)

-- TRINKET DOWN. The one question the medallion asks is "is my get-out-of-jail available",
-- so this is visible ONLY while it is on cooldown — absence means ready, and the column
-- stays empty in the normal case. Desaturated with the swipe running, i.e. it reads as
-- unavailable at a glance. Exact item ids, never the equipment slot: the slot trigger tracks
-- whatever sits in slot 13/14, so a PvE on-use trinket would report "medallion down" while
-- it is actually ready, and that false negative is a death in this exact decision. The pack
-- is class-gated to MAGE, so the class-specific Insignias reduce to two ids.
local PVP_TRINKETS = {
  37864,   -- Medallion of the Alliance (TBC honor, 2 min)
  37865,   -- Medallion of the Horde     (TBC honor, 2 min)
  18859,   -- Insignia of the Alliance (Mage, 5 min)
  18850,   -- Insignia of the Horde    (Mage, 5 min)
}
local trinketTrigs = {}
for i, id in ipairs(PVP_TRINKETS) do
  trinketTrigs[i] = itemTrigger("Cooldown Progress (Item)", id,
    { use_genericShowOn = true, genericShowOn = "showOnCooldown" })
end
local trink = reg(F.icon("Mage - Trinket DOWN", CLASS, 32, 32, 0, 0, nil))
trink.triggers = F.triggers(trinketTrigs, { disjunctive = "any" })   -- whichever one you wear
trink.cooldownTextDisabled = false   -- swipe numbers; no %p subtext (OmniCC would double it)
trink.desaturate = true
trink.load = pvpLoad(false)
adopt(gPvP, trink)

-- WILL OF THE FORSAKEN DOWN. On 2.4.3 WotF does NOT share a cooldown with the medallion
-- (that arrived in 3.3), so an Undead mage genuinely carries two charges and whether the
-- second is up changes whether the first gets spent. Gated on the ability, not the race.
local wotf = reg(F.icon("Mage - Will of the Forsaken DOWN", CLASS, 32, 32, 0, 0, nil))
wotf.triggers = F.triggers({ F.cdTrigger(7744, "Will of the Forsaken", "showOnCooldown") })
wotf.cooldownTextDisabled = false
wotf.desaturate = true
wotf.load = pvpLoad(false)
wotf.load.use_spellknown = true
wotf.load.spellknown = 7744
adopt(gPvP, wotf)

-- ENEMY TRINKET. Their trinket down for two minutes is when the real Polymorph chain goes
-- in; a one-shot "they trinketed!" flash without the countdown changes nothing. One clone
-- per opponent (unit = "arena" => clones, hence the dynamic-group parent). This is an
-- INFERENCE, not a read: no 2.5.x API exposes another player's cooldowns, so the timer
-- starts when the trinket cast is SEEN. Arena-only — arena1..5 do not exist in a BG.
local etrink = reg(F.icon("Mage - Enemy Trinket", CLASS, 32, 32, 0, 0, nil))
etrink.triggers = F.triggers({
  { type = "event", event = "Spell Cast Succeeded", unit = "arena", use_unit = true,
    use_spellId = true, spellId = { "42292" },   -- "PvP Trinket", cast by both medallions
    duration = "120" },                          -- REQUIRED on timed events; medallion CD
})
etrink.cooldownTextDisabled = false
etrink.load = pvpLoad(true)
adopt(gPvP, etrink)

-- COUNTERSPELL LOCKOUT. The eight seconds bought by the interrupt, which is the go: burn
-- Icy Veins / Water Elemental / Arcane Power now and do NOT spend Polymorph on a healer who
-- cannot cast anyway. A lockout is not an aura, so the only way to see it is the combat log
-- event plus a duration supplied here (Counterspell 8 s, verified). sourceUnit = player, so
-- a partner's interrupt does not light my bar.
local lockout = reg(F.aurabar("Mage - CS LOCKOUT", CLASS, 140, 12, 0, 0, nil,
  { 0.4, 0.85, 1, 1 }))
lockout.triggers = F.triggers({
  F.clogTrigger("SPELL", "_INTERRUPT", "8", {
    use_sourceUnit = true, sourceUnit = "player",
    use_spellId = true, spellId = { "2139" },
  }),
})
lockout.subRegions[2] = F.subtext("%p", 12, "INNER_RIGHT")
lockout.subRegions[3] = F.subborder("bar")
lockout.load = pvpLoad(false)
lockout.load.use_spellknown = true
lockout.load.spellknown = 2139
adopt(gPvP, lockout)

-- MY POLYMORPH, per opponent. Two decisions at once: do not touch that unit (any damage
-- breaks it and the sheep regenerates ~6% HP/sec, so hitting it hands the healer free
-- health), and the countdown is exactly the window the rest of the team has to work in.
-- ownOnly, so another mage's sheep never shows here. All four ranks plus the Turtle and Pig
-- variants. Glows in the last 3 s: re-poly now or the healer is free. Arena-only clones.
local POLYMORPH = { 118, 12824, 12825, 12826, 28271, 28272 }
local poly = reg(F.icon("Mage - Polymorph OUT", CLASS, 36, 36, 0, 0, nil))
poly.triggers = F.triggers({
  F.auraTrigger("arena", false, POLYMORPH,
    { ownOnly = true, showClones = true, combinePerUnit = true, perUnitMode = "affected" }),
})
poly.subRegions[1] = F.subglow(false, { 0.85, 0.5, 1, 1 })
poly.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
poly.conditions = { F.condition(1, "expirationTime", "<=", "3", "sub.1.glow", true) }
poly.load = pvpLoad(true)
adopt(gPvP, poly)

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
