-- rogue v43 -> v44: the PvP layer — TEN new auras, not one existing aura touched.
--
-- The rogue was the last pack with no PvP layer, because its historical generate.lua
-- (the v1->v41 iteration script) needs the original workspace and cannot be re-run. So
-- this follows the v42/v43 lineage pattern instead: decode the shipped string, append,
-- re-encode, and audit that every pre-existing aura round-trips byte-identical.
--
-- Run: lua5.1 tbc/rogue/patch-v44.lua   (rewrites all-specs.txt in place)
--
-- ---------------------------------------------------------------------------
-- WHAT A PvE ROGUE SEES: nothing. Every one of the ten carries its own Instance
-- Size Type load gate:
--   PVP   = { arena, pvp }   arena OR battleground
--   ARENA = { arena }        arena only — anything that reads arena1..arena5, because
--                            those unit ids do not exist in a battleground and the
--                            element would be a permanently blank slot there
-- `use_size = false` is NOT "off": multiselect load args are inert only at nil; false
-- selects MULTI mode, which ORs the listed instance types (WeakAuras.lua L847). The gate
-- is per aura on purpose — a group's load is not a child gate, and per-child gates are
-- what let the dynamic groups collapse their gaps.
--
-- ZERO custom code: every composite is a multi-trigger AND, an OR (disjunctive "any"),
-- or a condition. Same as v1..v43.
--
-- ---------------------------------------------------------------------------
-- WHAT EARNED A SLOT (rotation-design.md: every element must change the next button
-- press; the HUD must be quiet when nothing needs doing):
--
--   Rogue - CC ON ME        which break works right now — the single most expensive
--                           decision a stunned rogue makes
--   Rogue - KICK NOW        target is casting AND Kick is genuinely usable
--   Rogue - TARGET IMMUNE   do not open / do not dump into a bubble
--   Rogue - Trinket DOWN    spend or hold the medallion (absence = ready)
--   Rogue - Will of the Forsaken DOWN   the Undead rogue's second trinket
--   Rogue - Enemy Trinket   their 2 min countdown = when the real CC chain goes in
--   Rogue - KICK LOCKOUT    the 5 s go window my own Kick just bought
--   Rogue - My CC OUT       my Blind/Sap/Gouge per opponent: do NOT break it, and how
--                           long the rest of the team has
--   Rogue - Wound Poison    healing reduction on the kill target — refresh or the
--                           healer heals at full rate
--
-- WHAT WAS DELIBERATELY NOT BUILT:
--   * Cloak of Shadows and Vanish availability. Already legible: v43's cooldown row
--     ships `Rogue CD - Cloak of Shadows` and `Rogue CD - Vanish` as showAlways icons
--     that desaturate with a swipe while down. A PvP duplicate would be the same
--     information in two places, which is how a HUD teaches the player to stop reading.
--   * Diminishing returns. WeakAuras on TBC has no DR prototype and no bundled DR
--     library (references/pvp.md §4). A hand-rolled 18 s timer models the RESET window,
--     not the category state, and is wrong the moment two spells share a category — and
--     an incomplete DR tracker is worse than none, because it gets trusted. `My CC OUT`
--     is a plain remaining-duration readout of MY OWN CC and nothing more.
--   * "Only show casts I can interrupt." WeakAuras disables the Cast prototype's
--     interruptible arg on TBC clients outright (enable = not IsTBC()), so emitting it
--     does nothing. KICK NOW is "is casting" AND "Kick usable"; fake-casts stay a player
--     skill, not a HUD feature.
--   * Enemy cooldown reads and enemy spec. No 2.5.x API exposes either. `Enemy Trinket`
--     is an inference started by SEEING the cast, not a read.
--   * Enemy Evasion / Deterrence in the immunity list. Verified TBC values: Evasion is
--     +50% dodge (5277/26669), Deterrence is +25% dodge and parry (19263). Both are
--     damage reductions, not walls — TARGET IMMUNE means "your damage is exactly zero",
--     and diluting it with maybes is what turns a prompt into noise.
--   * Hiding the threat bar/flash inside arena. The only spelling is the inverse size
--     gate, and WeakAuras only assigns `size` at all inside `if inInstance or
--     instanceType ~= "none"`; the open-world value is unproven, so that gate can
--     silently unload the bars everywhere outside instances. A PvE regression is a worse
--     trade than one dead bar in arena.
--
-- ---------------------------------------------------------------------------
-- GAME DATA — every id below re-verified on wowhead.com/tbc (2026-08-13), ids only,
-- never names (zhCN-safe). Aura triggers carry ALL ranks as strings; cooldown and
-- Action Usable triggers carry the numeric rank-1 id.
--   Kick             1766 r1 · 1767 · 1768 · 1769 · 38768 r5 — "prevents any spell in
--                    that school from being cast for 5 sec" on every rank, 10 s cooldown
--   Blind            2094 (single rank, 10 s, "any damage caused will remove the effect")
--   Sap              6770 r1 25 s · 2070 r2 35 s · 11297 r3 45 s
--   Gouge            1776 · 1777 · 8629 · 11285 · 11286 · 38764 (TBC r6) — all 4 s
--   Wound Poison     13218 r1 L32 · 13222 r2 L40 · 13223 r3 L48 · 13224 r4 L56 ·
--                    27189 r5 L64 — "all healing effects reduced by 10%", 15 s, 5 stacks
--   Immunities       642/1020 Divine Shield · 498/5573 Divine Protection ·
--                    1022/5599/10278 Blessing of Protection (all PHYSICAL attacks — a
--                    rogue does literally nothing through it) · 45438 Ice Block ·
--                    19574 Bestial Wrath / 34471 The Beast Within (cannot be stopped
--                    unless killed, i.e. Blind/Kidney/Cheap Shot are wasted energy)
--   Will of the Forsaken 7744 (2 min; on 2.4.3 it does NOT share the medallion cooldown)
--   PvP trinkets     37864 Medallion of the Alliance · 37865 Medallion of the Horde
--                    (2 min, any race) · 18857 Insignia of the Alliance (Rogue) ·
--                    18849 Insignia of the Horde (Rogue) (5 min, class-restricted)
--   PvP Trinket cast 42292 (the spell both families cast — the enemy-trinket signal)
--
-- ---------------------------------------------------------------------------
-- UIDS: the original seeded stream cannot be replayed (generate.lua is not runnable), so
-- every new uid is a hand-picked LITERAL, exactly like v42's "St3aLthCd42". Nothing here
-- consumes math.random for a shipped value, so this script is deterministic without a
-- seed; the rogue pack keeps its registered seed 20260809 and no new seed is claimed.
-- tools/verify-packs.lua's global uid check proves they collide with no other pack.
local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local SCRIPTS = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local PACK = dir .. "/all-specs.txt"
local savedArg = arg
arg = { [0] = SCRIPTS .. "/wa_factory.lua" }
local F = dofile(SCRIPTS .. "/wa_factory.lua")
arg = savedArg
local W = F.W

local CLASS = "ROGUE"
local TOP = "Rogue TBC - All Specs"
local ALERTS = "Rogue - Alerts"
local GPVP = "Rogue - PvP"

local f = assert(io.open(PACK, "r")); local src = f:read("*a"); f:close()
local T = W.decode(src)
local OLD = W.decode(src)   -- pristine copy for the audit

assert(T.d.id == TOP, "unexpected top-level id: " .. tostring(T.d.id))

-- ===== shared helpers (same shapes the other packs' PvP layers use) =========
local function pvpLoad(arenaOnly)
  local l = F.load(CLASS, { use_size = false })
  l.size = arenaOnly and { multi = { arena = true } }
                      or { multi = { arena = true, pvp = true } }
  return l
end

local function alertAnims(aura)   -- slide in from below, fly out upward
  aura.animation.start  = F.animPreset("slidebottom", "0.3", "easeOut")
  aura.animation.finish = F.animCustom("1", { y = 150, alpha = 0, scale = 0.4 }, "easeOut")
end

local function polishIcon(icon)   -- crop + 1px outline, the pack's icon language
  icon.zoom = 0.3
  table.insert(icon.subRegions, F.subborder())
end

-- The factory has no item builder. "Cooldown Progress (Item)" takes a NUMERIC itemName
-- (the item id — a name string reaches GetItemCooldown("...") -> nil and never fires)
-- plus genericShowOn exactly like the spell version (nil = the aura never shows).
local function itemTrigger(itemId, showOn)
  return {
    type = "item", event = "Cooldown Progress (Item)",
    use_itemName = true, itemName = itemId,
    use_genericShowOn = true, genericShowOn = showOn,
    names = {}, spellIds = {}, debuffType = "HELPFUL",
    subeventPrefix = "SPELL", subeventSuffix = "_CAST_START",
  }
end

local function hostileTarget()
  -- aura2/unit triggers do NO hostility filtering of their own on target units, so
  -- "is an enemy" is a separate Unit Characteristics trigger ANDed in.
  return {
    type = "unit", event = "Unit Characteristics", unit = "target", use_unit = true,
    use_hostility = true, hostility = "hostile",
    names = {}, spellIds = {}, debuffType = "HELPFUL",
    subeventPrefix = "SPELL", subeventSuffix = "_CAST_START",
  }
end

-- ===== the ten new auras ====================================================
local UIDS = {}   -- id -> literal uid, asserted applied and collision-free below
local function newAura(a, uid)
  a.uid = uid
  UIDS[a.id] = uid
  return a
end

-- --- 1. CC ON ME (Alerts flow) ---------------------------------------------
-- The decision is not "am I CC'd", it is WHICH BREAK WORKS, and for a rogue the answer
-- splits on school, not on duration:
--   stun / charm      -> physical or mechanic: Cloak does nothing. Trinket, or eat it.
--   fear / poly / root of magic origin -> Cloak of Shadows (31224) "instantly removes all
--                        existing harmful spell effects" on 2.4.3, so it is a free break
--                        on a 1 min cooldown; save the medallion.
--   silence / lockout -> Cloak clears a silence debuff but NOT a Kick-style school
--                        lockout (a lockout is not an aura), so this is the one colour
--                        that means "you are on white damage until it expires".
--   disarm            -> a disarmed rogue has no rotation at all: Vanish/reset, not DPS.
-- Colour carries the category and %p the countdown, because a player inside a 3 s stun
-- parses colour and never text. No controlType filter, so it also catches school
-- lockouts, which no aura trigger can ever see. No combat gate: the opener Sap lands
-- out of combat.
local ccme = newAura(F.icon("Rogue - CC ON ME", CLASS, 40, 40, 0, 0, nil), "RgPvPccOnMe")
ccme.triggers = F.triggers({ { type = "unit", event = "Crowd Controlled" } })
ccme.cooldown = false            -- %p subtext carries the timer, no swipe
ccme.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })   -- red default = trinket food
ccme.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
ccme.conditions = {
  F.condition(1, "controlType", "==", "STUN", "sub.1.glowColor", { 1, 0.15, 0.15, 1 }),
  F.condition(1, "controlType", "==", "STUN_MECHANIC", "sub.1.glowColor", { 1, 0.15, 0.15, 1 }),
  F.condition(1, "controlType", "==", "CHARM", "sub.1.glowColor", { 1, 0.15, 0.15, 1 }),
  F.condition(1, "controlType", "==", "POSSESS", "sub.1.glowColor", { 1, 0.15, 0.15, 1 }),
  F.condition(1, "controlType", "==", "FEAR", "sub.1.glowColor", { 0.7, 0.3, 1, 1 }),
  F.condition(1, "controlType", "==", "FEAR_MECHANIC", "sub.1.glowColor", { 0.7, 0.3, 1, 1 }),
  F.condition(1, "controlType", "==", "CONFUSE", "sub.1.glowColor", { 0.4, 0.95, 0.5, 1 }),
  F.condition(1, "controlType", "==", "ROOT", "sub.1.glowColor", { 0.3, 0.7, 1, 1 }),
  F.condition(1, "controlType", "==", "SILENCE", "sub.1.glowColor", { 1, 0.85, 0.2, 1 }),
  F.condition(1, "controlType", "==", "PACIFY", "sub.1.glowColor", { 1, 0.85, 0.2, 1 }),
  F.condition(1, "controlType", "==", "PACIFYSILENCE", "sub.1.glowColor", { 1, 0.85, 0.2, 1 }),
  F.condition(1, "controlType", "==", "SCHOOL_INTERRUPT", "sub.1.glowColor", { 1, 0.85, 0.2, 1 }),
  F.condition(1, "controlType", "==", "DISARM", "sub.1.glowColor", { 1, 0.45, 0.05, 1 }),
}
ccme.load = pvpLoad(false)
alertAnims(ccme)

-- --- 2. KICK NOW (Alerts flow) ----------------------------------------------
-- Three triggers ANDed: the target is casting, Kick is genuinely castable (Action Usable
-- folds cooldown + energy + range into ONE boolean, so the prompt is never a lie — "no
-- energy to kick the heal" is exactly the case a bare cooldown icon gets wrong), and the
-- target is hostile. No spell whitelist: interruptibility does not exist on TBC and an id
-- list of every enemy heal is unmaintainable, so junk casts stay the player's read. The
-- prompt simply does not EXIST while Kick is down, which is what stops it training the
-- player to ignore it. Fixed Kick icon rather than the enemy's spell icon: the prompt
-- must look identical every time so it is recognised, not read.
local kick = newAura(F.icon("Rogue - KICK NOW", CLASS, 40, 40, 0, 0, nil), "RgPvPkickNw")
kick.triggers = F.triggers({
  { type = "unit", event = "Cast", unit = "target", use_unit = true },
  { type = "spell", event = "Action Usable", use_spellName = true, spellName = 1766,
    use_exact_spellName = true, use_ignoreoverride = true,
    names = {}, spellIds = {}, debuffType = "HELPFUL",
    subeventPrefix = "SPELL", subeventSuffix = "_CAST_START" },
  hostileTarget(),
})
kick.iconSource = 0
kick.displayIcon = "Interface\\Icons\\Ability_Kick"
kick.cooldown = false
kick.subRegions[1] = F.subglow(true, { 1, 0.85, 0.2, 1 })
kick.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")   -- remaining CAST time
-- out of melee range: the prompt stays up (close the gap) but reads as not-yet-pressable
kick.conditions = { F.condition(2, "spellInRange", "==", 0, "desaturate", true) }
kick.load = pvpLoad(false)
kick.load.use_spellknown = true
kick.load.spellknown = 1766
alertAnims(kick)

-- --- 3. TARGET IMMUNE (Alerts flow) -----------------------------------------
-- A rogue's entire kit is physical, so Blessing of Protection alone takes him to zero
-- output — this is a harder stop for a rogue than for any caster. Openers are the worst
-- case: Cheap Shot into a bubble spends the stealth, the cooldown and the opener for
-- nothing. Bestial Wrath / The Beast Within are in the list because they make the target
-- uncontrollable, so Blind, Kidney Shot, Gouge and Cheap Shot are wasted energy too.
-- Deliberately NOT here: Cloak of Shadows (90% SPELL resist — a rogue's white damage and
-- finishers land straight through it) and Spell Reflection (a rogue has no spell to
-- reflect). Both would fire on a target you should keep hitting.
local IMMUNE = {
  642, 1020,            -- Divine Shield r1/r2 (all damage and spells)
  498, 5573,            -- Divine Protection r1/r2 (all physical attacks and spells)
  1022, 5599, 10278,    -- Blessing of Protection r1/r2/r3 (all PHYSICAL attacks)
  45438,                -- Ice Block (TBC id)
  19574, 34471,         -- Bestial Wrath (pet) / The Beast Within (hunter): CC-immune
}
local immune = newAura(F.icon("Rogue - TARGET IMMUNE", CLASS, 40, 40, 0, 0, nil), "RgPvPimmune")
immune.triggers = F.triggers({
  F.auraTrigger("target", true, IMMUNE),   -- any caster: it is the TARGET's state that matters
  hostileTarget(),
})
immune.cooldown = false
immune.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
immune.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
immune.load = pvpLoad(false)
alertAnims(immune)

-- --- the PvP column ----------------------------------------------------------
-- State read-outs, mirroring the Alerts column on the other side of the character
-- (Alerts sits at -150 and grows UP; this sits at +200 and grows DOWN, clear of the
-- Procs row that starts at x=110). It MUST be a dynamic group: two of its children are
-- clone sources, one row per arena opponent, and clones inside a static group all stack
-- on a single spot.
local gPvP = newAura(F.dynGroup(GPVP, 200, 96, TOP, "DOWN", "TOP", 6), "RgPvPgroup4")

-- --- 4. Trinket DOWN ---------------------------------------------------------
-- The medallion asks exactly one question — "is my get-out-of-jail available" — so the
-- icon exists ONLY while it is on cooldown. Absence means ready and the column stays
-- empty in the normal case. Exact item ids OR'd, never the equipment-slot trigger: that
-- one tracks whatever sits in slot 13/14, so a PvE on-use trinket in the other slot
-- would report "medallion down" while the medallion is actually up, and in this exact
-- decision that false negative is a death. Class-gated to ROGUE, so the class-restricted
-- Insignias reduce to two ids; the Medallions are race-gated only, hence all four.
local PVP_TRINKETS = { 37864, 37865, 18857, 18849 }
local trinketTrigs = {}
for i, id in ipairs(PVP_TRINKETS) do trinketTrigs[i] = itemTrigger(id, "showOnCooldown") end
local trink = newAura(F.icon("Rogue - Trinket DOWN", CLASS, 32, 32, 0, 0, nil), "RgPvPtrink1")
trink.triggers = F.triggers(trinketTrigs, { disjunctive = "any" })   -- whichever one you wear
trink.cooldownTextDisabled = false   -- swipe numbers; no %p subtext (OmniCC would double it)
trink.desaturate = true
trink.load = pvpLoad(false)

-- --- 5. Will of the Forsaken DOWN --------------------------------------------
-- On 2.4.3 WotF does NOT share a cooldown with the medallion (that arrived in 3.3), so an
-- Undead rogue genuinely carries two charges and whether the second is up changes whether
-- the first gets spent on a fear. Gated on the ability, not the race.
local wotf = newAura(F.icon("Rogue - Will of the Forsaken DOWN", CLASS, 32, 32, 0, 0, nil),
                     "RgPvPwotf44")
wotf.triggers = F.triggers({ F.cdTrigger(7744, "Will of the Forsaken", "showOnCooldown") })
wotf.cooldownTextDisabled = false
wotf.desaturate = true
wotf.load = pvpLoad(false)
wotf.load.use_spellknown = true
wotf.load.spellknown = 7744

-- --- 6. Enemy Trinket ---------------------------------------------------------
-- Their trinket down for two minutes is when the real Blind -> Sap -> kill chain goes in;
-- a one-shot "they trinketed!" flash with no countdown changes nothing. One clone per
-- opponent (unit = "arena" => clones, hence the dynamic-group parent). This is an
-- INFERENCE, not a read: no 2.5.x API exposes another player's cooldowns, so the timer
-- starts when the cast is SEEN. 120 s is the level-70 Medallion; an opponent still on the
-- 5 min Insignia comes back later than the bar says, which errs toward holding CC.
-- Arena-only: arena1..5 do not exist in a battleground.
local etrink = newAura(F.icon("Rogue - Enemy Trinket", CLASS, 32, 32, 0, 0, nil), "RgPvPetrink")
etrink.triggers = F.triggers({
  { type = "event", event = "Spell Cast Succeeded", unit = "arena", use_unit = true,
    use_spellId = true, spellId = { "42292" },   -- "PvP Trinket", cast by both families
    duration = "120" },                          -- REQUIRED on timed events; medallion CD
})
etrink.cooldownTextDisabled = false
etrink.load = pvpLoad(true)

-- --- 7. KICK LOCKOUT ----------------------------------------------------------
-- The five seconds the interrupt bought, which is the go: Cold Blood / Adrenaline Rush /
-- Blade Flurry now, and do NOT spend Blind on a healer who cannot cast anyway. A school
-- lockout is not an aura, so the only way to see it is the combat-log event plus a
-- duration supplied here — 5 s on every Kick rank, verified. sourceUnit = player, so a
-- partner's interrupt never lights my bar.
local lockout = newAura(F.aurabar("Rogue - KICK LOCKOUT", CLASS, 140, 12, 0, 0, nil,
  { 1, 0.85, 0.2, 1 }), "RgPvPlockot")
lockout.triggers = F.triggers({
  F.clogTrigger("SPELL", "_INTERRUPT", "5", {
    use_sourceUnit = true, sourceUnit = "player",
    use_spellId = true, spellId = { "1766", "1767", "1768", "1769", "38768" },
  }),
})
lockout.subRegions[2] = F.subtext("%p", 12, "INNER_RIGHT")
lockout.subRegions[3] = F.subborder("bar")
lockout.load = pvpLoad(false)
lockout.load.use_spellknown = true
lockout.load.spellknown = 1766

-- --- 8. My CC OUT, per opponent ------------------------------------------------
-- Blind, Sap and Gouge share ONE decision, so they share one element: that unit is out,
-- any damage revives it, and the countdown is exactly the window the rest of the team has
-- to work in. Cleave into your own Blind and you have handed the enemy healer a free
-- global; a rogue who cannot see the timer guesses. ownOnly, so another rogue's Sap never
-- shows here. The icon comes from the trigger, so the clone tells you WHICH of the three
-- is running. Glows in the last 2 s: it is about to break, commit or re-CC. Arena-only
-- clones (one row per opponent).
-- NOT a DR tracker — see the header. This is remaining duration and nothing else.
local MY_CC = {
  2094,                                        -- Blind
  6770, 2070, 11297,                           -- Sap r1-r3
  1776, 1777, 8629, 11285, 11286, 38764,       -- Gouge r1-r6
}
local mycc = newAura(F.icon("Rogue - My CC OUT", CLASS, 36, 36, 0, 0, nil), "RgPvPmyCCot")
mycc.triggers = F.triggers({
  F.auraTrigger("arena", false, MY_CC,
    { ownOnly = true, showClones = true, combinePerUnit = true, perUnitMode = "affected" }),
})
mycc.subRegions[1] = F.subglow(false, { 0.85, 0.5, 1, 1 })
mycc.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
mycc.conditions = { F.condition(1, "expirationTime", "<=", "2", "sub.1.glow", true) }
mycc.load = pvpLoad(true)

-- --- 9. Wound Poison on the kill target ----------------------------------------
-- The rogue's Mortal Strike. Five stacks is -50% healing, and against a healer team that
-- number decides the game — but it is applied by procs, so it silently decays while you
-- are on the wrong target or between swaps. This is the readout that turns it back into a
-- press: stacks in the middle, remaining underneath, glow in the last 3 s = Shiv it back
-- up (Shiv applies the off-hand poison instantly) or get back on the target. ownOnly, so
-- a second rogue's stacks never inflate the reading. Shown on the current target, so it
-- works in battlegrounds as well as arena.
local WOUND_POISON = { 13218, 13222, 13223, 13224, 27189 }   -- r1-r5, 15 s, 5 stacks
local wound = newAura(F.icon("Rogue - Wound Poison", CLASS, 36, 36, 0, 0, nil), "RgPvPwound1")
-- One trigger only: no hostility check is needed here (unlike TARGET IMMUNE, where the
-- listed buffs are commonly on a FRIENDLY target). Your own Wound Poison can only ever
-- sit on an enemy, so a hostility trigger would be dead weight.
wound.triggers = F.triggers({
  F.auraTrigger("target", false, WOUND_POISON, { ownOnly = true }),
})
wound.subRegions[1] = F.subglow(false, { 1, 0.35, 0.35, 1 })
wound.subRegions[2] = F.subtext("%s", 16, "CENTER")          -- stacks
wound.subRegions[3] = F.subtext("%p", 11, "INNER_BOTTOM")    -- remaining
wound.conditions = { F.condition(1, "expirationTime", "<=", "3", "sub.1.glow", true) }
wound.load = pvpLoad(false)

-- ===== splice into the decoded pack =========================================
local alertNew = { ccme, kick, immune }
local pvpChildren = { trink, wotf, etrink, lockout, mycc, wound }
local everything = { ccme, kick, immune, gPvP, trink, wotf, etrink, lockout, mycc, wound }

for _, a in ipairs(everything) do
  if a.regionType == "icon" then polishIcon(a) end
end

-- no shipped value may come from the factory's random uid stream
for _, a in ipairs(everything) do
  assert(UIDS[a.id] == a.uid, "aura " .. a.id .. " does not carry its hand-picked uid")
  assert(#a.uid == 11 and a.uid:match("^[%w()]+$"), "bad uid literal on " .. a.id)
end

local existingIds, existingUids = { [T.d.id] = true }, { [T.d.uid] = true }
for _, a in ipairs(T.c) do existingIds[a.id], existingUids[a.uid] = true, true end
for _, a in ipairs(everything) do
  assert(not existingIds[a.id], "id already present in the pack: " .. a.id)
  assert(not existingUids[a.uid], "uid collision inside the pack: " .. a.uid)
end

-- Alerts: append the three prompts, and insert them in `c` directly after the last
-- existing Alerts child so `c` stays depth-first consistent with controlledChildren.
local alerts
for _, a in ipairs(T.c) do if a.id == ALERTS then alerts = a end end
assert(alerts and alerts.regionType == "dynamicgroup", "alerts dynamic group not found")
local lastAlertIdx
for i, a in ipairs(T.c) do if a.parent == ALERTS then lastAlertIdx = i end end
assert(lastAlertIdx, "alerts group has no children")
for k, icon in ipairs(alertNew) do
  icon.parent = ALERTS
  table.insert(alerts.controlledChildren, icon.id)
  table.insert(T.c, lastAlertIdx + k, icon)
end

-- PvP column: a new top-level group appended after the existing five, with its own
-- children immediately behind it (depth-first again).
table.insert(T.d.controlledChildren, GPVP)
T.c[#T.c + 1] = gPvP
for _, a in ipairs(pvpChildren) do
  a.parent = GPVP
  gPvP.controlledChildren[#gPvP.controlledChildren + 1] = a.id
  T.c[#T.c + 1] = a
end

-- depth-first invariant: walking d's controlledChildren must reproduce c exactly
local function depthFirst(root, byId)
  local out, seen = {}, {}
  local function walk(node)
    for _, cid in ipairs(node.controlledChildren or {}) do
      local ch = assert(byId[cid], "missing child table: " .. cid)
      assert(not seen[cid], "child listed twice: " .. cid)
      seen[cid] = true
      out[#out + 1] = cid
      walk(ch)
    end
  end
  walk(root)
  return out
end
do
  local byId = {}
  for _, a in ipairs(T.c) do byId[a.id] = a end
  local want = depthFirst(T.d, byId)
  assert(#want == #T.c, ("depth-first walk covers %d of %d children"):format(#want, #T.c))
  for i = 1, #T.c do
    assert(want[i] == T.c[i].id,
      ("c is not depth-first at %d: %s vs %s"):format(i, T.c[i].id, want[i]))
  end
end

-- ===== encode + verify ======================================================
local encoded = W.encode(T)
W.verify(T, encoded)
local cont = W.uidContinuity(encoded, PACK)
assert(cont.parentSame, "top-level uid changed")
assert(cont.changed == 0, "uid continuity broken: changed=" .. cont.changed)
assert(cont.stable == #OLD.c, ("uid continuity: %d stable, expected %d"):format(cont.stable, #OLD.c))

-- ===== audit: nothing but the additions may differ ==========================
local back = W.decode(encoded)
local function iseq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not iseq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end
local function deepcopy(t)
  if type(t) ~= "table" then return t end
  local r = {}; for k, v in pairs(t) do r[k] = deepcopy(v) end; return r
end
local function ccAppendedOnly(old, new, added)
  assert(#new.controlledChildren == #old.controlledChildren + #added,
         old.id .. ": controlledChildren changed by the wrong amount")
  for i = 1, #old.controlledChildren do
    assert(new.controlledChildren[i] == old.controlledChildren[i],
           old.id .. ": existing controlledChildren reordered")
  end
  for i, id in ipairs(added) do
    assert(new.controlledChildren[#old.controlledChildren + i] == id,
           old.id .. ": expected " .. id .. " appended")
  end
  local a, b = deepcopy(old), deepcopy(new)
  a.controlledChildren, b.controlledChildren = nil, nil
  assert(iseq(a, b), old.id .. ": changed beyond controlledChildren")
end

assert(#back.c == #OLD.c + #everything,
       ("child count: %d, expected %d"):format(#back.c, #OLD.c + #everything))
ccAppendedOnly(OLD.d, back.d, { GPVP })
local newById = {}
for _, a in ipairs(back.c) do newById[a.id] = a end
for _, old in ipairs(OLD.c) do
  local new = assert(newById[old.id], "child vanished: " .. old.id)
  if old.id == ALERTS then
    ccAppendedOnly(old, new, { "Rogue - CC ON ME", "Rogue - KICK NOW", "Rogue - TARGET IMMUNE" })
  else
    assert(iseq(old, new), "unexpected change in " .. old.id)
  end
end

-- every new aura must actually carry a PvP size gate
for _, a in ipairs(everything) do
  local new = assert(newById[a.id], "new aura missing from the encoded pack: " .. a.id)
  if a.id ~= GPVP then
    assert(new.load.use_size == false and new.load.size and new.load.size.multi
             and new.load.size.multi.arena, a.id .. ": missing arena load gate")
  end
end

print(("audit ok: +%d auras, all %d existing auras byte-identical")
  :format(#everything, #OLD.c + 1))
print(("uid continuity: stable=%d changed=%d parentSame=%s")
  :format(cont.stable, cont.changed, tostring(cont.parentSame)))

local out = assert(io.open(PACK, "w")); out:write(encoded); out:close()
print(("wrote %s (%d chars, %d auras)"):format(PACK, #encoded, #back.c + 1))
