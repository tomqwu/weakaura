-- generate.lua — Druid TBC "All Specs" HUD (v2).
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
--
-- v2 (rotation review fixes) — see README "## v2 — rotation fixes". New elements are
-- constructed in the block at the BOTTOM of this file so every pre-existing uid() draw keeps
-- its position in the seeded stream; they are re-parented into the right group there.
--
-- v3 (spec-selective loading) — see README "## v3 — each spec loads only what it presses".
-- Pure gating: no element added, removed or reordered, so every uid is unchanged. Barkskin,
-- Innervate and the Innervate prompt now carry an INVERSE gate (not_spellknown = Mangle (Bear))
-- and no longer load for a feral druid, who cannot cast either spell without dropping form.
--
-- v4 (PvP layer) — see README "## v4 — PvP layer". Six new elements plus one new dynamic
-- group, EVERY one of them gated on the instance type (`load.size` multiselect: arena+bg, or
-- arena alone for anything that reads arena1..arena5). Nothing existing changed, so a PvE
-- druid sees a byte-for-byte identical HUD. Built in the v4 block at the BOTTOM of this file
-- so the seeded uid stream stays append-only.
--
-- v5 (source-verified PvP fixes) — see README "## v5 — the CC prompt answers itself". Two
-- changes, NO new auras, so every uid is byte-identical to v4 and the import dialog still
-- offers Update:
--   * CC on Me now colour-codes the glow by loss-of-control category, so the colour names the
--     answer (red = trinket, purple = trinket, blue = shift out, green = ride it, amber = your
--     school is locked out) before the icon is read. Nine `sub.1.glowColor` conditions.
--   * the two threat bars carry an inverse instance-size gate and no longer load in an arena,
--     where there is no threat table for them to read. v4 declined to ship this because the
--     open-world value of `size` was unverified; it is the literal string "none", so the
--     complement enumeration is safe. See notInArena() below.

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
local GATE_R = { use_spellknown = true, spellknown = 18562 }  -- Swiftmend      — Resto 31
local GATE_B = { use_spellknown = true, spellknown = 24858 }  -- Moonkin Form   — Balance 31
-- Enrage is a PRE-PULL rage generator (it also strips armour), so it loads out of combat only.
-- WA load booleans are tri-state: use_combat = false means "must NOT be in combat".
local GATE_F_PREPULL = { use_spellknown = true, spellknown = 33878, use_combat = false }

-- ===== v3 inverse gate: "load only for druids who do NOT know this spell" =====
-- There is no negated form of use_spellknown (use_spellknown = false means IGNORE, not "must
-- not know"), so WA exposes a separate `not_spellknown` arg — verified in Prototypes.lua's load
-- prototype: test = "not WeakAuras.IsSpellKnownForLoad(%s, %s)". Requirements:
--   * WeakAuras 5.4.0+ (the arg does not exist before that). On an older client the unknown
--     field is ignored and the element simply loads for everyone — the v2 behaviour — so this
--     degrades gracefully rather than erroring.
--   * do NOT set use_exact_not_spellknown: with `exact` falsy, IsSpellKnownForLoad resolves the
--     rank-1 id through the spell NAME to whatever rank the player has, so one id covers r1-r3.
-- 33878 is Mangle (Bear), the 41-point Feral talent every other feral element gates on, so
-- NOT_FERAL is the exact complement of the bear HUD: what a bear loads, this hides, and vice
-- versa. Mangle (Cat) is a different spell NAME (33876), so the name resolution is unambiguous.
local NOT_FERAL        = { use_not_spellknown = true, not_spellknown = 33878 }
local NOT_FERAL_COMBAT = { use_not_spellknown = true, not_spellknown = 33878, use_combat = true }

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
local IDS_DEMOROAR  = { 99, 1735, 9490, 9747, 9898, 26998 }     -- Demoralizing Roar r1-r6, 30s
local IDS_TOL       = { 33891 }                                -- Tree of Life Form (self shapeshift aura)

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

-- R4 Mana (Balance) — identical to R3 but Balance-gated. Swiftmend (31 pts Resto) and Moonkin
-- Form (31 pts Balance) cannot both be taken at TBC's 61-point cap, so the two mana bars are
-- mutually exclusive, not merely overlapping.
local manaB = resBar("Druid - Mana (Balance)", -27, { 0.25, 0.5, 0.9, 1 }, GATE_B)
manaB.triggers = F.triggers({ F.powerTrigger(0), F.unitCharTrigger() })
manaB.subRegions[2] = F.subtext("%percentpower%%", 12, "INNER_RIGHT", "percentpower")
manaB.subRegions[3] = F.subborder("bar")
manaB.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }

-- ===== v5 inverse size gate: "load everywhere EXCEPT an arena" =====
-- An arena has no threat table, so both threat bars sit pinned and meaningless in there —
-- pure clutter in the one place screen space is scarcest. WA's `size` load arg (Prototypes.lua
-- "Instance Size Type") declares no `inverse` and no `test`, so there is genuinely no "not
-- arena" key: multi mode ORs raw string equality over the listed keys, and the only spelling
-- of "not arena" is to enumerate the complement.
-- The value that made v4 refuse to ship this is `none`. GetInstanceTypeAndSize's
-- `if inInstance or instanceType ~= "none"` block is a GUARD, not the whole function — under
-- it sits an explicit `return "none", "none", nil, nil, 0`, so in the open world `size` is the
-- literal string "none" (never nil), ScanForLoads passes it through unmodified, and listing
-- `none` keeps the bars loaded while questing. That was the whole PvE risk, and it is gone.
-- TBC's full instance_types set is none/party/ten/twenty/twentyfive/fortyman/pvp/arena
-- (Types.lua deletes flexible, scenario, ratedpvp and ratedarena for Classic flavours, and
-- deletes `arena` only for Classic Era), so listing seven keys omits exactly one: arena.
-- `pvp` stays listed on purpose — a battleground has NPCs and a threat table, and the bars are
-- as useful there as they are outdoors. `twenty` is a legal key that no TBC difficulty index
-- maps to; listing it is free.
local PVE_NOT_ARENA = { "none", "party", "ten", "twenty", "twentyfive", "fortyman", "pvp" }
local function notInArena(gate)
  local g = {}
  for k, v in pairs(gate or {}) do g[k] = v end
  local multi = {}                                     -- fresh table per call: two loads must
  for _, key in ipairs(PVE_NOT_ARENA) do multi[key] = true end  -- never share one subtable
  g.use_size = false                                   -- false = MULTI mode (nil = gate off)
  g.size = { multi = multi }
  return g
end

-- R5 Threat (Bear) — tank-inverted semantics: green while tanking, RED when aggro is lost
local threatF = resBar("Druid - Threat (Bear)", -41, { 0.25, 0.8, 0.3, 1 }, notInArena(GATE_F))
threatF.triggers = F.triggers({ F.threatTrigger() })
threatF.subRegions[2] = F.subtext("%threatpct%%", 12, "INNER_RIGHT", "threatpct")
threatF.subRegions[3] = F.subborder("bar")
threatF.conditions = { F.condition(1, "aggro", "==", 0, "barColor", { 0.9, 0.12, 0.12, 1 }) }

-- R6 Threat (Caster) — orange at 70%, red on aggro (severe condition last)
local threatB = resBar("Druid - Threat (Caster)", -41, { 0.25, 0.8, 0.3, 1 }, notInArena(GATE_B))
threatB.triggers = F.triggers({ F.threatTrigger() })
threatB.subRegions[2] = F.subtext("%threatpct%%", 12, "INNER_RIGHT", "threatpct")
threatB.subRegions[3] = F.subborder("bar")
threatB.conditions = {
  F.condition(1, "threatpct", ">=", "70", "barColor", { 1, 0.6, 0.1, 1 }),
  F.condition(1, "aggro", "==", 1, "barColor", { 0.9, 0.12, 0.12, 1 }),
}

-- ================= Buffs (0,-16): 40x40 timers per spec, slots shared =================
-- Bear runs FOUR slots (-66/-22/+22/+66), the caster specs three (-44/0/+44); both rows stay
-- centred on the group and only one spec's row can ever load.
local function buffIcon(id, x, gate)
  local ic = reg(F.icon(id, CLASS, 40, 40, x, 0, nil))
  ic.zoom = 0.3
  ic.load = F.load(CLASS, gate)
  adopt(gBuffs, ic)
  return ic
end

-- B1 Lacerate — stacks to 5 (%s) + timer, glow inside the refresh window.
-- Desaturated below 5 stacks: colour returning IS "the stack is capped, stop feeding it".
local lacerate = buffIcon("Druid - Lacerate", -66, GATE_F)
lacerate.triggers = F.triggers({ F.auraTrigger("target", false, IDS_LACERATE, { ownOnly = true }) })
lacerate.subRegions[2] = F.subtext("%s", 16, "CENTER")
lacerate.subRegions[3] = F.subtext("%p", 11, "INNER_BOTTOM")
lacerate.subRegions[4] = F.subborder()
lacerate.conditions = {
  F.condition(1, "stacks", "<", "5", "desaturate", true),
  F.condition(1, "expirationTime", "<=", "5", "sub.1.glow", true),
}

-- B2 Mangle debuff — uptime awareness only; C1 is what you actually press
local mangle = buffIcon("Druid - Mangle Debuff", -22, GATE_F)
mangle.triggers = F.triggers({ F.auraTrigger("target", false, IDS_MANGLE, { ownOnly = true }) })
mangle.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
mangle.subRegions[3] = F.subborder()

-- B3 Faerie Fire (Bear) — ANY caster's FF or FFF satisfies the armor debuff rule
local ffF = buffIcon("Druid - Faerie Fire (Bear)", 22, GATE_F)
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
lifebloom.conditions = {
  F.condition(1, "stacks", "<", "3", "desaturate", true),
  F.condition(1, "expirationTime", "<=", "2", "sub.1.glow", true),
}

-- B5 Rejuvenation — own HoT on target, all 13 ranks (downranking-safe); Swiftmend fuel
local rejuv = buffIcon("Druid - Rejuvenation", 0, GATE_R)
rejuv.triggers = F.triggers({ F.auraTrigger("target", true, IDS_REJUV, { ownOnly = true }) })
rejuv.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
rejuv.subRegions[3] = F.subborder()
rejuv.conditions = { F.condition(1, "expirationTime", "<=", "3", "sub.1.glow", true) }

-- B6 Regrowth — own HoT on target, all 10 ranks; the other Swiftmend fuel
local regrowth = buffIcon("Druid - Regrowth", 44, GATE_R)
regrowth.triggers = F.triggers({ F.auraTrigger("target", true, IDS_REGROWTH, { ownOnly = true }) })
regrowth.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
regrowth.subRegions[3] = F.subborder()
regrowth.conditions = { F.condition(1, "expirationTime", "<=", "3", "sub.1.glow", true) }

-- B7 Insect Swarm — plain uptime timer, NO refresh glow: TBC Balance refreshes it only while
-- moving, and WA cannot see movement without custom code, so a glow here would be wrong most
-- of the time. The icon vanishing is the only claim it makes.
local swarm = buffIcon("Druid - Insect Swarm", -44, GATE_B)
swarm.triggers = F.triggers({ F.auraTrigger("target", false, IDS_INSECT, { ownOnly = true }) })
swarm.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
swarm.subRegions[3] = F.subborder()

-- B8 Moonfire — NO expiry glow on purpose: let it fully expire, then recast
local moonfire = buffIcon("Druid - Moonfire", 0, GATE_B)
moonfire.triggers = F.triggers({ F.auraTrigger("target", false, IDS_MOONFIRE, { ownOnly = true }) })
moonfire.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
moonfire.subRegions[3] = F.subborder()

-- B9 Faerie Fire (Balance) — same combined FF+FFF set as B3, but OWN-ONLY: a feral's Faerie
-- Fire (Feral) satisfies the armour debuff yet strips the raid's Improved Faerie Fire hit,
-- so the moonkin must see "mine is not up" even when someone else's is.
local ffB = buffIcon("Druid - Faerie Fire (Balance)", 44, GATE_B)
ffB.triggers = F.triggers({ F.auraTrigger("target", false, IDS_FAERIE, { ownOnly = true }) })
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

-- A3 Omen of Clarity missing — "you forgot to buff it". NOT combat-gated: Omen of Clarity is
-- a 30-minute out-of-combat self buff that cannot be cast while shapeshifted, so a combat
-- gate would only ever fire at the one moment you cannot act on it.
local oocMissing = alertIcon("Druid - OoC Missing",
  { use_spellknown = true, spellknown = 16864 })
oocMissing.triggers = F.triggers({
  F.auraTrigger("player", true, IDS_OOC, { matchesShowOn = "showOnMissing" }),
})
oocMissing.iconSource = 0
oocMissing.displayIcon = "Interface\\Icons\\spell_nature_crystalball"
oocMissing.cooldown = false
oocMissing.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
oocMissing.subRegions[2] = F.subborder()

-- A4 mana < 20% AND Innervate ready. v3: hidden from feral. Innervate cannot be cast while
-- shapeshifted in 2.4.3 ("Cannot be used while shapeshifted" on 29166), and a bear's mana neither
-- pays for nor gates anything it presses — so in bear form this prompt sits lit for whole fights
-- asking for a button that would first cost the tank its form. For Resto and Balance it is the
-- mana decision of the fight, and Tree of Life explicitly whitelists Innervate.
local innervatePrompt = alertIcon("Druid - Innervate Prompt", NOT_FERAL_COMBAT)
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

local mangleCD =                                                            -- C1
addCD("Mangle",             "Mangle (Bear)",         CD_MANGLE,    GATE_F)
addCD("Enrage",             "Enrage",                CD_ENRAGE,    GATE_F_PREPULL)  -- C2
addCD("Frenzied Regen",     "Frenzied Regeneration", CD_FRENZIED,  GATE_F)  -- C3
addCD("Swiftmend",          "Swiftmend",             CD_SWIFTMEND, GATE_R)  -- C4
addCD("Nature's Swiftness", "Nature's Swiftness",    CD_NSWIFT,
  { use_spellknown = true, spellknown = 17116 })                            -- C5
addCD("Force of Nature",    "Force of Nature",       CD_TREANTS,
  { use_spellknown = true, spellknown = 33831 })                            -- C6
-- C7/C8 v3: both carry the "Cannot be used while shapeshifted" flag in 2.4.3, so they are
-- caster-spec buttons only. Barkskin "takes you out of form when used, making it only usable
-- while you are not actively tanking" (Icy Veins feral tank guide) — i.e. pressing it mid-pull
-- is the mistake, not the save. Tree of Life whitelists both, and a moonkin can drop form for
-- them, so they stay for Resto and Balance.
addCD("Barkskin",           "Barkskin",              CD_BARKSKIN,  NOT_FERAL)  -- C7
addCD("Innervate",          "Innervate",             CD_INNERVATE, NOT_FERAL)  -- C8

-- Mangle (Bear) is the bear's every-6-seconds press, so it gets the "press it NOW" treatment
-- the rest of the strip does not: an orange pixel glow the instant the cooldown clears, on top
-- of the shared desaturate-while-down readout.
mangleCD.subRegions[1] = F.subglow(false, { 1, 0.55, 0.15, 1 })
mangleCD.conditions[2] = F.condition(1, "onCooldown", "==", 0, "sub.1.glow", true)

-- ================= v2 additions =================
-- APPEND-ONLY: every constructor below draws a uid AFTER all v1 ones, which is what keeps the
-- in-game import dialog on "Update". Each element is re-parented into its v1 group by the
-- helper it is built with (adopt() appends to that group's controlledChildren).

-- R7-R10 Rage thresholds — the bear's two spend decisions drawn on the rage bar itself.
-- Rage caps at 100 and the bar is 172 wide anchored at x=0, so x(v) = -86 + 1.72*v.
-- Dim line = where the threshold is; the wider lit line pops in the moment you cross it.
local function rageLine(id, rageValue, w, h, color, minRage)
  local x = math.floor(-86 + 1.72 * rageValue + 0.5)
  local line = reg(F.texture(id, CLASS, w, h, x, -27, nil, F.TEX_SQUARE, color))
  line.triggers = F.triggers({ F.powerTrigger(1, minRage) })  -- rage only exists in bear form
  line.load = F.load(CLASS, GATE_F)
  if minRage then
    line.animation.start  = F.animPreset("shrink", "0.25", "easeOut")  -- WA "shrink" = pop-in
    line.animation.finish = F.animPreset("fade", "0.2")
  end
  adopt(gRes, line)
  return line
end

rageLine("Druid - Rage Line Mangle",     20, 2, 16, { 0.25, 0.95, 0.45, 0.55 }, nil)
rageLine("Druid - Rage Line Maul",       70, 2, 16, { 1, 0.75, 0.2, 0.55 },     nil)
rageLine("Druid - Rage Line Mangle Lit", 20, 4, 18, { 0.25, 0.95, 0.45, 1 },    20)
rageLine("Druid - Rage Line Maul Lit",   70, 4, 18, { 1, 0.75, 0.2, 1 },        70)

-- B10 Demoralizing Roar — bear priority #1 alongside Faerie Fire. Not own-only: any druid's
-- roar satisfies the -240 AP debuff. Takes the fourth bear buff slot at x=+66.
local demoRoar = buffIcon("Druid - Demoralizing Roar", 66, GATE_F)
demoRoar.triggers = F.triggers({ F.auraTrigger("target", false, IDS_DEMOROAR) })
demoRoar.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
demoRoar.subRegions[3] = F.subborder()
demoRoar.conditions = { F.condition(1, "expirationTime", "<=", "5", "sub.1.glow", true) }

-- A5 Maul prompt — Maul is off the GCD and has no cooldown, so the decision is purely
-- "am I about to waste rage": above 70 you have room for Maul (15) and the next Mangle (20)
-- and still cap. Appearing is the instruction; it leaves when the rage is spent.
local maulPrompt = alertIcon("Druid - Maul Prompt",
  { use_spellknown = true, spellknown = 33878, use_combat = true })
maulPrompt.triggers = F.triggers({ F.powerTrigger(1, 70) })
maulPrompt.iconSource = 0
maulPrompt.displayIcon = "Interface\\Icons\\ability_druid_maul"
maulPrompt.cooldown = false
maulPrompt.subRegions[1] = F.subglow(true, { 1, 0.65, 0.15, 1 })
maulPrompt.subRegions[2] = F.subborder()

-- A6 Tree of Life missing — resto priority #1 is "be in Tree of Life whenever possible".
-- The form is a self aura, so its absence in combat is the prompt to shift back after the
-- Healing-Touch/Tranquility window that forced you out. Gated on the 41-point talent itself.
local tolMissing = alertIcon("Druid - Tree of Life Missing",
  { use_spellknown = true, spellknown = 33891, use_combat = true })
tolMissing.triggers = F.triggers({
  F.auraTrigger("player", true, IDS_TOL, { matchesShowOn = "showOnMissing" }),
})
tolMissing.iconSource = 0
tolMissing.displayIcon = "Interface\\Icons\\ability_druid_treeoflife"
tolMissing.cooldown = false
tolMissing.subRegions[1] = F.subglow(true, { 0.35, 0.95, 0.45, 1 })
tolMissing.subRegions[2] = F.subborder()

-- ================= v4 additions — the PvP layer =================
-- APPEND-ONLY again: every constructor below draws a uid AFTER all v1-v3 ones.
--
-- HARD RULE: every element here is gated on the instance type, so a druid who never queues
-- for arena or a battleground sees exactly the v3 HUD. The load arg is `size` (UI label
-- "Instance Size Type"), a multiselect over WA's instance_types; on TBC the only PvP keys
-- that can ever match are `arena` and `pvp` (Types.lua deletes ratedarena/ratedpvp for
-- Classic flavours, and WeakAuras.InstanceType() can never return them). `use_size = false`
-- is NOT "off": multiselect load args are live for both true and false and only inert at nil
-- — false selects MULTI mode, which ORs the listed keys. Group-level load is not a child
-- gate in WA, so the gate goes on every child individually, which is also what lets the
-- dynamic groups collapse their gaps in PvE.
local function pvpGate(extra)     -- arena OR battleground
  local g = { use_size = false, size = { multi = { arena = true, pvp = true } } }
  for k, v in pairs(extra or {}) do g[k] = v end
  return g
end
local function arenaGate(extra)   -- arena ONLY — arena1..arena5 do not exist in a BG, so a
  local g = { use_size = false, size = { multi = { arena = true } } }  -- BG-loaded arena
  for k, v in pairs(extra or {}) do g[k] = v end                       -- element is a
  return g                                                             -- permanently blank slot
end

-- Raw (non-factory) triggers still need the fields WA's own editor always writes.
local function rawTrigger(t)
  t.names = {}; t.spellIds = {}
  t.subeventPrefix = "SPELL"; t.subeventSuffix = "_CAST_START"
  t.debuffType = t.debuffType or "HELPFUL"
  return t
end

-- ===== verified PvP ids (wowhead.com/tbc, 2.4.3 data) =====
-- Damage-pointless CC: Cyclone makes the target immune to ALL damage and healing for its
-- whole duration, and Entangling Roots breaks the moment it takes damage. Both mean "stop
-- hitting that unit". Deliberately NOT in this list: Bash and Maim — stuns are exactly when
-- you SHOULD be pouring damage in, so mixing them into the same row would invert the message.
local IDS_CYCLONE = { 33786 }                                   -- single TBC rank
local IDS_ROOTS   = { 339, 1062, 5195, 5196, 9852, 9853, 26989, -- Entangling Roots r1-r7
                      19970, 19971, 19972, 19973, 19974, 19975, 27010 }  -- Nature's Grasp roots
local IDS_CC_HOLD = {}
for _, id in ipairs(IDS_CYCLONE) do IDS_CC_HOLD[#IDS_CC_HOLD + 1] = id end
for _, id in ipairs(IDS_ROOTS)   do IDS_CC_HOLD[#IDS_CC_HOLD + 1] = id end

-- Hard stops only: buffs that make the press you were about to make land for nothing.
-- Mitigation cooldowns (Barkskin, Shield Wall, Pain Suppression) are NOT here — they change
-- how much damage lands, not whether pressing the button is worth a GCD.
-- Deterrence is not here either: on 2.4.3 it is +25% parry / +25% dodge, not an immunity.
local IDS_IMMUNE = { 642, 1020,            -- Divine Shield r1-r2 (immune to everything)
                     1022, 5599, 10278,    -- Blessing of Protection r1-r3 (physical immunity)
                     45438,                -- Ice Block
                     31224,                -- Cloak of Shadows (90% spell miss + strips DoTs)
                     19574, 34471 }        -- Bestial Wrath / The Beast Within (CC immunity)

-- Every TBC PvP trinket a DRUID can equip. All six cast spell 42292 ("PvP Trinket") since
-- 2.1.2, which is what makes the enemy-side countdown below possible.
local PVP_TRINKETS = { 28235,   -- Medallion of the Alliance (Druid),  2 min
                       28241,   -- Medallion of the Horde (Druid),     2 min
                       37864,   -- Medallion of the Alliance (all classes, 2.4), 2 min
                       37865,   -- Medallion of the Horde (all classes, 2.4),    2 min
                       18863,   -- Insignia of the Alliance (Druid),   5 min
                       18853 }  -- Insignia of the Horde (Druid),      5 min

-- P0 the PvP column — mirrors the Alerts flow on the other side of the character so the PvE
-- layout is untouched. MUST be a dynamicgroup: two of its children are clone sources.
local gPvP = reg(F.dynGroup("Druid - PvP", 150, 96, nil, "DOWN", "TOP", 6))
adopt(top, gPvP)

local function pvpIcon(id, size, gate)
  local ic = reg(F.icon(id, CLASS, size, size, 0, 0, nil))
  ic.zoom = 0.3
  ic.load = F.load(CLASS, gate)
  ic.cooldownTextDisabled = false   -- WA prints the countdown on the swipe; no %p (OmniCC)
  ic.subRegions[2] = F.subborder()
  adopt(gPvP, ic)
  return ic
end

-- P1 CC on me — the single prompt that answers "ride it or spend the trinket". The icon comes
-- from the trigger, so the effect identifies itself (sap / poly / fear / stun / kick lockout),
-- and %p is the countdown you decide against. Still NO controlType filter on the trigger: it
-- catches every loss-of-control effect including school lockouts, which are not auras and
-- which aura2 can therefore never see. No combat gate either — the opener Sap lands out of
-- combat.
--
-- v5: the category now drives the GLOW COLOUR, because under a stun a player parses colour and
-- never text, and "am I CC'd" was never the decision — WHICH break works is:
--   red    STUN / STUN_MECHANIC   the trinket is the only answer a druid has
--   purple FEAR / FEAR_MECHANIC   likewise the trinket: 2.4.3 gives a druid no fear break
--   blue   ROOT                   a MOVEMENT answer, NOT the trinket — shift form (any shift
--                                 clears roots and snares), Travel/Cat out, or Nature's Grasp
--   green  CONFUSE                polymorph/disorient: ride it, any damage breaks it, and
--                                 trinketing here throws the cooldown away for nothing
--   amber  SILENCE / PACIFYSILENCE / SCHOOL_INTERRUPT
--                                 your school is gone (a Nature lockout takes Cyclone, roots,
--                                 Healing Touch and Innervate at once) — trinket EARLIER than
--                                 you otherwise would, because waiting costs the whole kit
-- Deliberately identical to the mage pack's five colours: a player who rolls two of these
-- classes learns one language, not two.
--
-- Mechanics this depends on, all source-verified: the condition property is
-- "sub.1.glowColor", where 1 is the 1-based index into subRegions (Conditions.lua builds
-- `"sub." .. index .. "." .. key` from ipairs(data.subRegions)), so the subglow MUST stay at
-- index 1 — inserting a subregion ahead of it silently repoints all nine conditions. The value
-- must be a 4-element ARRAY, not {r=,g=,b=,a=}, or it serialises to four nils. And the glow
-- must be BOTH visible and colour-enabled: SetGlowColor only stores the value, while SetVisible
-- does `if self.useGlowColor then color = self.glowColor end` and otherwise hands LibCustomGlow
-- nil — so with useGlowColor false every one of these conditions would be a silent no-op.
-- F.subglow(true, colour) sets glow = true AND useGlowColor = true, which is exactly what the
-- call below does.
local ccOnMe = alertIcon("Druid - CC on Me", pvpGate())
ccOnMe.triggers = F.triggers({ rawTrigger{ type = "unit", event = "Crowd Controlled" } })
ccOnMe.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })  -- red base = "trinket food":
ccOnMe.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")    -- the fallback the five
ccOnMe.subRegions[3] = F.subborder()                          -- uncovered locTypes restore
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

-- P2 Barkskin while stunned — the druid-only press nothing else in the game can prompt.
-- 22812's 2.4.3 tooltip reads "Can be used while stunned"/"Usable while feared", so a stunned
-- druid still has exactly one button, and this is it. Trigger 1 is the Barkskin readiness
-- check on purpose: activeTriggerMode = -10 means the FIRST active trigger supplies the icon,
-- so the prompt wears Barkskin's own icon rather than the stun's. Inverse-gated like every
-- other Barkskin element in this pack (v3): the spell carries "Cannot be used while
-- shapeshifted" on 2.4.3 and you cannot shift out while stunned, so for a feral it would be a
-- prompt for a button that does not exist.
local barkStun = alertIcon("Druid - Barkskin (Stunned)", pvpGate({
  use_spellknown = true, spellknown = CD_BARKSKIN,
  use_not_spellknown = true, not_spellknown = 33878,
}))
barkStun.triggers = F.triggers({
  F.cdTrigger(CD_BARKSKIN, "Barkskin", "showOnReady"),
  rawTrigger{ type = "unit", event = "Crowd Controlled", use_controlType = true, controlType = "STUN" },
})
barkStun.cooldown = false
barkStun.subRegions[1] = F.subglow(true, { 0.5, 0.9, 0.4, 1 })
barkStun.subRegions[2] = F.subborder()

-- P3 target immune — stop the burst. Continuing into a bubble, an Ice Block or a Blessing of
-- Protection spends the whole cooldown set for zero, and Bestial Wrath means the Cyclone you
-- were about to cast fails outright. The matched buff supplies the icon, so which immunity it
-- is (and therefore whether to swap, re-pool or answer it) is readable without text.
local targetImmune = alertIcon("Druid - Target Immune", pvpGate())
targetImmune.triggers = F.triggers({ F.auraTrigger("target", true, IDS_IMMUNE) })
targetImmune.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
targetImmune.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
targetImmune.subRegions[3] = F.subborder()

-- P4 my trinket down — visible ONLY while on cooldown, so an empty slot means "ready" and the
-- column stays quiet in the normal case. One trigger per item id OR'd together: the
-- equipment-slot trigger would report whatever sits in slot 13/14, so a PvE on-use trinket
-- would claim your medallion is down when it is ready — a false negative that gets you killed
-- in the one decision this element exists for.
local function trinketCD(itemId)
  return rawTrigger{ type = "item", event = "Cooldown Progress (Item)",
                     use_itemName = true, itemName = itemId,
                     use_genericShowOn = true, genericShowOn = "showOnCooldown" }
end
local myTrinket = pvpIcon("Druid - PvP Trinket Down", 32, pvpGate())
local trinketTriggers = {}
for i, itemId in ipairs(PVP_TRINKETS) do trinketTriggers[i] = trinketCD(itemId) end
myTrinket.triggers = F.triggers(trinketTriggers, { disjunctive = "any" })
myTrinket.desaturate = true   -- reads as "unavailable" without needing the number

-- P5 enemy trinket — one clone per opponent who has used theirs, counting down 120s. The flash
-- is worthless; the countdown is the whole value, because it is the window in which a real CC
-- chain sticks. This is an INFERENCE, not a read: no 2.5.x API exposes another player's
-- cooldowns, so the timer starts when the cast is seen. 120s is the Medallion cooldown every
-- level-70 arena player carries; a low-level BG opponent on a 5-minute Insignia would show
-- "ready" early. Arena-gated because unit = "arena" makes no sense in a battleground.
local enemyTrinket = pvpIcon("Druid - Enemy Trinket", 36, arenaGate())
enemyTrinket.triggers = F.triggers({
  rawTrigger{ type = "event", event = "Spell Cast Succeeded",
              unit = "arena", use_unit = true,
              use_spellId = true, spellId = { "42292" },
              duration = "120" },
})

-- P6 my CC out — one clone per opponent carrying my Cyclone or my roots, with the remaining
-- time. Both effects mean the same thing: every point of damage sent at that unit is wasted
-- (Cyclone absorbs it all) or actively harmful (damage breaks roots), and the timer is the
-- window you bought on the OTHER target. Own-only, because someone else's roots are not your
-- clock. The matched aura supplies the icon, so cyclone and roots are never confused.
local ccOut = pvpIcon("Druid - CC Out", 36, arenaGate())
ccOut.triggers = F.triggers({
  F.auraTrigger("arena", false, IDS_CC_HOLD,
    { ownOnly = true, showClones = true, combinePerUnit = true, perUnitMode = "affected" }),
})
ccOut.cooldownTextDisabled = true
ccOut.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
ccOut.subRegions[3] = F.subborder()

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
