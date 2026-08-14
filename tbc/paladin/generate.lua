-- generate.lua — "Paladin TBC - All Specs" (v7)
-- Holy / Protection / Retribution HUD in one import; spec pieces auto-load via
-- Spell Known gates. Built entirely with the wa_factory builders (zero custom code).
--
-- v7 — the cooldown row shows what you CANNOT press. NOT ONE W.uid() call was added,
-- removed or reordered, so the re-import is still an Update and every dragged position
-- survives; only two fields on eleven existing row icons changed.
--
-- The row was inverted: 14 icons on screen at all times, dimmed when down, so it was
-- busiest exactly when the paladin had the fewest options — and a paladin knows their own
-- spellbook. What they cannot know is what is unavailable, and for how long. Every
-- SITUATIONAL icon becomes genericShowOn = "showOnCooldown": it exists only while its
-- cooldown runs, carrying the swipe and its countdown, and disappears the moment the
-- ability is back. The row is a dynamic group, so the gap closes — ABSENCE IS THE READOUT.
-- Their onCooldown == 1 -> desaturate condition goes with it: under showOnCooldown every
-- visible icon is on cooldown by definition, so greying the whole row would only make the
-- abilities harder to tell apart. Full colour + countdown reads better.
--
-- The exception is the PRESS-ON-COOLDOWN ROTATIONAL buttons, whose gold ready-glow is the
-- instruction and cannot fire from a hidden icon. Those keep showAlways + desaturate +
-- glow: Judgement, Crusader Strike, Avenger's Shield (all three already glowed) and —
-- the one classification v7 changes — CONSECRATION, which now glows for the first time.
--   * Consecration is Protection's largest threat source and an explicit press-on-cooldown
--     line in the tank rotation (Holy Shield > Consecration > Judgement). v2 withheld the
--     glow because the same icon also loads for Retribution, where Consecration is a
--     mana-permitting filler, and a glow there overstates it. Under v7 that trade is no
--     longer symmetric: withholding the glow now means HIDING a tank's biggest threat
--     button whenever it is available, which is the wrong direction for the button they
--     press most. Ret still reads it correctly — Judgement and Crusader Strike carry the
--     same glow and sit ahead of it in the priority, so a lit Consecration means "the
--     filler is up", spend it if mana permits.
--   * Holy Shock deliberately still does NOT glow, and now hides while ready: TBC Holy is
--     Holy Light / Flash of Light, and Holy Shock is the expensive instant kept for
--     movement and emergencies — pressing it on sight is a mana bug, not a rotation.
--   * Divine Favor (2 min, paired with a Holy Light on someone actually taking damage),
--     Divine Illumination (3 min mana cooldown), Avenging Wrath (3 min burst, burns
--     Forbearance), Divine Shield and Lay on Hands (panic buttons, and LoH already has its
--     own alert prompt), Hammer of Justice (a stun/interrupt, with a HAMMER NOW alert in
--     the PvP layer) and the three PvP blessings/stun are all "pressed when a circumstance
--     calls for it" — the row only needs to answer when they come back.
--
-- v6 — two deferred questions came back from a source verifier, and both answers land
-- on existing elements. NOT ONE W.uid() call was added, removed or reordered, so the
-- re-import is still an Update and every dragged position survives:
--   * CC ON ME now says WHICH break to use, in colour. The glow was already there and
--     always red; nine conditions on `sub.1.glowColor` now recolour it by control type —
--     red stun, purple fear, blue root, green confuse/poly, amber silence/lockout. Same
--     five colours as the mage pack on purpose: a player who rolls two classes should
--     learn one language, not two.
--   * The Threat bar and the Threat Flash no longer load inside an ARENA. An arena has
--     no threat table, so both were dead PvE furniture parked in the middle of the HUD
--     exactly when screen space matters most. Everywhere else — open world, dungeon,
--     raid, battleground — they behave exactly as in v5.
--   Not built: a per-opponent enemy mana readout. It is now a proven WA primitive (the
--   Power trigger accepts unit = "arena" on 2.5.x and clones per opponent), but a
--   paladin has no mana drain, burn or punish — Judgement of Wisdom GIVES mana to the
--   attacker. An opponent's mana bar would not change one paladin button press, which is
--   the standard every element in this pack has to meet. It belongs in the packs that
--   can act on it (warlock / priest / hunter / mage).
--
-- v5 — the PvP layer (arena + battleground). Ten new elements plus the dynamic group
-- that holds them; every ELEMENT carries its own instance-type load gate (the group
-- does not, like every other group here), and all eleven regions are appended AFTER
-- every existing W.uid() call so the re-import is still an Update:
--   * new dynamic group "Paladin - PvP" mirroring the Alerts column on the other
--     side of the character; holds the PvP state readouts and the two clone rows.
--   * prompts (Alerts column): CC ON ME, HAMMER NOW, TARGET IMMUNE.
--   * state (PvP column): Trinket DOWN, Enemy Trinket (arena), Forbearance (arena),
--     CLEANSE (arena).
--   * cooldown row: Blessing of Freedom, Blessing of Protection, and a Holy-only
--     Hammer of Justice copy (v4 hid the shared one from deep Holy, which is right
--     in a raid and wrong in an arena).
--   A PvE player sees ZERO change: nothing above loads outside arena/battleground.
--
-- v4 — "does this spec PRESS it", not "can this spec CAST it" (gating only; not one
-- W.uid() call added, removed or reordered, so re-import is still an Update):
--   * Judgement, Hammer of Justice and the Hammer of Wrath execute prompt are now
--     hidden from deep Holy via the same not_spellknown = 20473 inverse gate v3 gave
--     Consecration and Avenging Wrath. A Holy paladin's judgement decision is "is my
--     20s Judgement of Wisdom about to expire", which the Judgement Debuff timer
--     already answers; the CD icon answers "is the 10s cooldown up", which for a
--     healer is ~always yes — so its gold ready-glow sat lit for most of every fight,
--     training the eye to ignore the row. A 6s stun and a 20%-execute nuke are not
--     healing decisions at all.
--   * Deliberately KEPT for Holy: Divine Shield and Lay on Hands (real panic buttons —
--     bubble also clears debuffs, and with Avenging Wrath already gone from the Holy
--     row nothing else on it burns Forbearance), the Threat bar (a healer who pulls the
--     boss off the tank wipes the raid), and Seal Active + Judgement Debuff (Seal of
--     Wisdom -> Judgement of Wisdom upkeep is the Holy paladin's one non-healing job
--     when the raid has no Retribution paladin).
--
-- v2 rotation fixes (no uid() call was added, removed or reordered — Update-safe):
--   * SEALS gains Seal of the Martyr (348700) / Seal of Corruption (348704), the 2.5.1
--     Alliance/Horde damage seals. Without them an Alliance Ret had a blank Seal Active
--     icon and a permanent SEAL MISSING alert.
--   * Hammer of Wrath is no longer gated to Retribution (it is baseline at 44 and an
--     explicit Protection priority line); it now gates on its own id and only fires on a
--     HOSTILE target under 20%.
--   * Judgement / Crusader Strike / Avenger's Shield — the press-on-cooldown buttons —
--     get a gold "ready NOW" glow (condition -> sub.1.glow), suppressed out of combat.
--   * The whole cooldown row fades to 50% alpha out of combat like the resource bars.
--
-- Run: lua5.1 tbc/paladin/generate.lua   (after tools/.../scripts/setup.sh)
-- Writes: tbc/paladin/all-specs.txt (single line, no trailing newline)
--
-- This is the ONE paladin string. The former tank-starter.txt pack was retired: every
-- spell it tracked is covered here behind Protection gates, and a class shipping two
-- strings competes with itself for globally-unique aura ids.

math.randomseed(20260811)  -- FIXED pack seed; uid order is append-only across versions

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
-- wa_factory.lua resolves wa_lib.lua and ../assets/icon_proto.lua from arg[0], so a bare
-- relative dofile fails when the build script lives outside scripts/. Point arg[0] at the
-- factory for the duration of the load, then hand it back.
local factoryPath = dir .. "/../../tools/tbc-weakaura-creator/scripts/wa_factory.lua"
local savedArg0 = arg and arg[0]
if arg then arg[0] = factoryPath end
local F = dofile(factoryPath)
if arg then arg[0] = savedArg0 end
local W = F.W

local CLASS = "PALADIN"
local TOP = "Paladin TBC - All Specs"

-- spec gates: rank-1 id of each spec's signature talent (present in the spellbook when talented)
local GATE_HOLY, GATE_PROT, GATE_RET = 20473, 20925, 35395

-- ===== shared spell-id tables (every rank; F.auraTrigger stringifies them) =====
local SEALS = {
  20154, 21084, 20287, 20288, 20289, 20290, 20291, 20292, 20293, 27155, -- Righteousness r1-r9 (+legacy r1 20154)
  21082, 20162, 20305, 20306, 20307, 20308, 27158,                      -- the Crusader r1-r7
  20375, 20915, 20918, 20919, 20920, 27170,                             -- Command r1-r6
  31892,                                                                -- Blood (Horde)
  31801,                                                                -- Vengeance (Alliance)
  20166, 20356, 20357, 27166,                                           -- Wisdom r1-r4
  20165, 20347, 20348, 20349, 27160,                                    -- Light r1-r5
  20164, 31895,                                                         -- Justice r1-r2
  348700,                                                               -- the Martyr (Alliance, 2.5.1 — Ret's default seal at 70)
  348704,                                                               -- Corruption (Horde, 2.5.1 — the SoV-equivalent)
}
local JUDGES = {
  20185, 20344, 20345, 20346, 27162,               -- Judgement of Light r1-r5 (r5 = 27162, the debuff;
                                                   --   27163 is the heal proc and carries no aura)
  20186, 20354, 20355, 27164,                      -- Judgement of Wisdom r1-r4
  21183, 20188, 20300, 20301, 20302, 20303, 27159, -- Judgement of the Crusader r1-r7
  20184, 31896,                                    -- Judgement of Justice r1-r2 (r2 from Seal of Justice r2)
}
local HOLY_SHIELD = { 20925, 20927, 20928, 27179 } -- buff r1-r4 (10s, 4 charges)

-- ===== assembly helpers =====
local byId = {}
local function reg(t) byId[t.id] = t; return t end
local function adopt(parent, child)
  child.parent = parent.id
  table.insert(parent.controlledChildren, child.id)
end
local function gate(t, spellId)
  t.load.use_spellknown = true
  t.load.spellknown = spellId
  return t
end
-- Inverse gate: "load only if the player does NOT know this spell". There is no
-- negated form of `spellknown` (use_spellknown = false means IGNORE, not "must not"),
-- so WA exposes a separate `not_spellknown` arg — verified in Prototypes.lua's load
-- prototype: test = "not WeakAuras.IsSpellKnownForLoad(%s, %s)". Requirements:
--   * WeakAuras 5.4.0+ (the arg does not exist before that). On an older client the
--     unknown field is ignored and the element simply loads for everyone — the v2
--     behaviour — so this degrades gracefully rather than erroring.
--   * do NOT set use_exact_not_spellknown: with `exact` falsy, IsSpellKnownForLoad
--     resolves a rank-1 id through the spell name to the highest rank the player has,
--     so one rank-1 id matches every rank. `exact` would only match rank 1 literally.
-- No Modernize migration touches this field between internalVersion 45 and current.
local function gateNot(t, spellId)
  t.load.use_not_spellknown = true
  t.load.not_spellknown = spellId
  return t
end
local function inGroup(t)
  t.load.use_ingroup = true
  t.load.ingroup = { multi = { group = true, raid = true } }
  return t
end
-- v6 — "everywhere EXCEPT an arena", for PvE furniture that must not follow you in.
-- There is no "not arena" key and no negation flag: the multiselect builder does honour
-- `arg.inverse` (WeakAuras.lua:755-763), but the `size` load arg (Prototypes.lua:2035-2044)
-- declares no `inverse`, no `test` and no `enableTest`, so multi mode is a plain OR over
-- raw string equality and the complement has to be enumerated. This emits the load test
--   (size==[[none]] or size==[[party]] or size==[[ten]] or size==[[twenty]]
--    or size==[[twentyfive]] or size==[[fortyman]] or size==[[pvp]])
-- `none` is the entry that had to be verified before this could ship, and it is why v5
-- deliberately did NOT ship it. The worry was that WeakAuras only assigns `size` inside an
-- instance, which would make this gate silently unload the bars in the open world — the
-- one place a threat bar is least harmful and most often looked at. It does not:
-- GetInstanceTypeAndSize (WeakAuras.lua:1598-1626) guards its in-instance branch with
-- `if inInstance or instanceType ~= "none"` and then falls through to an explicit
--   return "none", "none", nil, nil, 0
-- so standing in Hellfire Peninsula `size` is the STRING "none", not nil, and ScanForLoads
-- hands it to the load function unmodified. Listing `none` is what keeps these loading
-- outside instances.
-- Legal TBC keys are none/party/ten/twenty/twentyfive/fortyman/pvp/arena — Types.lua
-- deletes ratedpvp/ratedarena/flexible/scenario for Classic flavours, and deletes `arena`
-- only under IsClassicEra() — so listing all of them but `arena` IS "not arena". `twenty`
-- is legal on TBC though no TBC difficulty index maps to it; listing it costs nothing.
-- `pvp` is kept on purpose: Alterac Valley is full of elite NPCs with real threat tables,
-- so a battleground is a place a threat bar still earns its space.
local function noArena(t)
  t.load.use_size = false   -- false = MULTI mode; only nil disables a multiselect gate
  t.load.size = { multi = {
    none = true, party = true, ten = true, twenty = true,
    twentyfive = true, fortyman = true, pvp = true,
  } }
  return t
end
local function polish(icon)          -- crop + 1px outline on every icon
  icon.zoom = 0.3
  table.insert(icon.subRegions, F.subborder())
  return icon
end

-- uid order is sacred: one W.uid() per region, consumed by the constructor below,
-- in exactly this creation order. Append new regions at the END in future versions.

-- 1) top-level group, anchored below the character
local top = F.group(TOP, 0, -140, nil)
top.frameStrata = 1

-- ===== 2) Resources: health / mana / threat stacked flush =====
local gRes = reg(F.group("Paladin - Resources", 0, 56, TOP))
adopt(top, gRes)

-- 3) health
local hp = reg(F.aurabar("Paladin - Health", CLASS, 172, 14, 0, -13, gRes.id, { 0.15, 0.78, 0.25, 1 }))
hp.triggers = F.triggers({ F.healthTrigger(), F.unitCharTrigger() })
hp.subRegions[2] = F.subtext("%percenthealth%%", 12, "INNER_RIGHT", "percenthealth")
hp.subRegions[3] = F.subborder("bar")
hp.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }
adopt(gRes, hp)

-- 4) mana — the paladin resource in every spec; red below 20%
local mp = reg(F.aurabar("Paladin - Mana", CLASS, 172, 14, 0, -27, gRes.id, { 0.10, 0.45, 0.95, 1 }))
mp.triggers = F.triggers({ F.powerTrigger(0), F.unitCharTrigger() })
mp.subRegions[2] = F.subtext("%percentpower%%", 12, "INNER_RIGHT", "percentpower")
mp.subRegions[3] = F.subborder("bar")
mp.conditions = {
  F.condition(1, "percentpower", "<", "20", "barColor", { 0.85, 0.15, 0.15, 1 }),
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
}
adopt(gRes, mp)

-- 5) threat vs the current target (party/raid, and never in an arena). For prot, red =
-- "I have aggro" = correct.
local th = reg(F.aurabar("Paladin - Threat", CLASS, 172, 14, 0, -41, gRes.id, { 0.25, 0.80, 0.30, 1 }))
th.triggers = F.triggers({ F.threatTrigger() })
th.subRegions[2] = F.subtext("%threatpct%%", 12, "INNER_RIGHT", "threatpct")
th.subRegions[3] = F.subborder("bar")
th.conditions = {  -- severe last: a later match overwrites the same property
  F.condition(1, "threatpct", ">=", "70", "barColor", { 1, 0.6, 0.1, 1 }),
  F.condition(1, "aggro", "==", 1, "barColor", { 0.9, 0.12, 0.12, 1 }),
}
inGroup(th)
noArena(th)   -- v6: an arena party is still a party, but has no threat table
adopt(gRes, th)

-- 6) >=80% threat flash over the bar — Ret only (a tank AT aggro must not be alarmed)
local flash = reg(F.texture("Paladin - Threat Flash", CLASS, 176, 18, 0, -41, gRes.id,
  F.TEX_SQUARE, { 1, 0.1, 0.1, 0.85 }))
flash.blendMode = "ADD"
flash.triggers = F.triggers({ F.threatTrigger(80) })
flash.animation.main = F.animPreset("alphaPulse", "1")
inGroup(flash)
noArena(flash)   -- v6: a pulsing red alarm that can never fire is the worst kind of clutter
gate(flash, GATE_RET)
adopt(gRes, flash)

-- ===== 7) Buffs: static row of timers =====
local gBuffs = reg(F.group("Paladin - Buffs", 0, -16, TOP))
adopt(top, gBuffs)

-- 8) seal uptime — the rotation's metronome; glows under 5s so you re-seal in time
local seal = reg(F.icon("Paladin - Seal Active", CLASS, 40, 40, -66, 0, gBuffs.id))
seal.triggers = F.triggers({ F.auraTrigger("player", true, SEALS) })
seal.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
seal.conditions = { F.condition(1, "expirationTime", "<=", "5", "sub.1.glow", true) }
polish(seal)
adopt(gBuffs, seal)

-- 9) your own judgement debuff on the target (all three specs judge)
local judge = reg(F.icon("Paladin - Judgement Debuff", CLASS, 40, 40, -22, 0, gBuffs.id))
judge.triggers = F.triggers({ F.auraTrigger("target", false, JUDGES, { ownOnly = true }) })
judge.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
polish(judge)
adopt(gBuffs, judge)

-- 10) Holy Shield uptime + remaining charges (Prot)
local hs = reg(F.icon("Paladin - Holy Shield Up", CLASS, 40, 40, 22, 0, gBuffs.id))
hs.triggers = F.triggers({ F.auraTrigger("player", true, HOLY_SHIELD) })
hs.subRegions[2] = F.subtext("%s", 16, "CENTER")
hs.subRegions[3] = F.subtext("%p", 11, "INNER_BOTTOM")
gate(hs, GATE_PROT)
polish(hs)
adopt(gBuffs, hs)

-- 11) Light's Grace (Holy) — shares the slot with Holy Shield; specs are mutually exclusive
local lg = reg(F.icon("Paladin - Lights Grace", CLASS, 40, 40, 22, 0, gBuffs.id))
lg.triggers = F.triggers({ F.auraTrigger("player", true, { 31834 }) })
lg.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
lg.conditions = { F.condition(1, "expirationTime", "<=", "5", "sub.1.glow", true) }
gate(lg, GATE_HOLY)
polish(lg)
adopt(gBuffs, lg)

-- ===== 12) Alerts: glowing prompts flowing upward beside the character =====
local gAlerts = reg(F.dynGroup("Paladin - Alerts", -150, 96, TOP, "UP", "BOTTOM", 6))
gAlerts.animate = true
adopt(top, gAlerts)

local function alert(id, displayIcon, glowColor, spellKnown)
  local a = reg(F.icon(id, CLASS, 40, 40, 0, 0, gAlerts.id))
  a.iconSource = 0
  a.displayIcon = displayIcon
  a.cooldown = false
  a.subRegions[1] = F.subglow(true, glowColor)
  a.load.use_combat = true
  if spellKnown then gate(a, spellKnown) end
  a.animation.start = F.animPreset("slidebottom", "0.3", "easeOut")
  a.animation.finish = F.animCustom("1", { y = 150, alpha = 0, scale = 0.4 }, "easeOut")
  polish(a)
  adopt(gAlerts, a)
  return a
end

local RED  = { 1, 0.15, 0.15, 1 }
local GOLD = { 1, 0.82, 0.1, 1 }
local BLUE = { 0.3, 0.7, 1, 1 }

-- 13) no seal in combat (Ret)
local sealRet = alert("Paladin - Seal MISSING (Ret)", "Interface\\Icons\\spell_holy_sealofblood", RED, GATE_RET)
sealRet.triggers = F.triggers({ F.auraTrigger("player", true, SEALS, { matchesShowOn = "showOnMissing" }) })

-- 14) no seal in combat (Prot) — a second copy because one load cannot OR two spellknowns
local sealProt = alert("Paladin - Seal MISSING (Prot)", "Interface\\Icons\\ability_thunderbolt", RED, GATE_PROT)
sealProt.triggers = F.triggers({ F.auraTrigger("player", true, SEALS, { matchesShowOn = "showOnMissing" }) })

-- 15) Righteous Fury off while tanking — the classic prot failure
local rf = alert("Paladin - RF MISSING", "Interface\\Icons\\spell_holy_sealoffury", RED, GATE_PROT)
rf.triggers = F.triggers({ F.auraTrigger("player", true, { 25780 }, { matchesShowOn = "showOnMissing" }) })

-- 16) Holy Shield down AND off cooldown (disjunctive "all" = both must be true)
local hsNow = alert("Paladin - Holy Shield NOW", "Interface\\Icons\\spell_holy_blessingofprotection", GOLD, GATE_PROT)
hsNow.triggers = F.triggers({
  F.auraTrigger("player", true, HOLY_SHIELD, { matchesShowOn = "showOnMissing" }),
  F.cdTrigger(20925, "Holy Shield", "showOnReady"),
})

-- 17) execute window: HOSTILE target under 20% HP AND Hammer of Wrath ready.
-- Baseline at 44 and a numbered Protection priority line too, so it gates on its own
-- rank-1 id (known from 44 onward) instead of on a spec capstone. The hostility filter
-- stops a wounded ALLY under 20% from firing a prompt for a spell you cannot cast on them.
local howHealth = F.healthTrigger(20)
howHealth.unit = "target"
howHealth.use_hostility = true
howHealth.hostility = "hostile"
local how = alert("Paladin - Hammer of Wrath", "Interface\\Icons\\ability_thunderclap", GOLD, 24275)
how.triggers = F.triggers({ howHealth, F.cdTrigger(24275, "Hammer of Wrath", "showOnReady") })
-- v4: ...but an execute nuke is not a healing decision. Both load gates apply (WA ANDs
-- them), so this is "knows Hammer of Wrath AND is not deep Holy" — Prot and Ret keep the
-- prompt, a Holy paladin healing the pull never gets a glowing damage button.
gateNot(how, GATE_HOLY)

-- 18) panic button: own HP under 25% AND Lay on Hands ready (all specs)
local loh = alert("Paladin - Lay on Hands Prompt", "Interface\\Icons\\spell_holy_layonhands", BLUE, nil)
loh.triggers = F.triggers({ F.healthTrigger(25), F.cdTrigger(633, "Lay on Hands", "showOnReady") })

-- ===== 19) Cooldowns: horizontal row, gaps auto-collapse when a spec's icons unload =====
local gCds = reg(F.dynGroup("Paladin - Cooldowns", 0, -66, TOP, "HORIZONTAL", "CENTER", 4))
gCds.animate = false
adopt(top, gCds)

-- 20-30) gated icons last so the shared part of the row keeps a stable position.
-- Talent cooldowns gate on their OWN rank-1 id (untalented => icon unloads => row collapses).
-- { label, rank-1 id, spellknown gate or nil, press-on-cooldown?, hide-from gate or nil }
-- The 5th column is the inverse gate. A healing Holy paladin never presses
-- Consecration (a threat/mana dump) or Avenging Wrath (a damage cooldown), but no
-- positive spellknown covers "Prot and Ret but not Holy" — no spell is shared by
-- those two and absent from Holy. `not_spellknown = 20473` (Holy Shock, a 30-point
-- Holy talent) reads as "not deep Holy", which is exactly the set wanted, and being
-- a single aura with a single gate it cannot double-show on a hybrid the way one
-- copy per spec would.
--
-- v4 adds Judgement and Hammer of Justice to that inverse gate:
--   * Judgement — Prot and Ret press it the moment the 10s cooldown is up (an explicit
--     numbered line in both rotations), which is what the gold ready-glow says. Holy
--     does judge, but on a completely different clock: Seal of Wisdom -> Judgement of
--     Wisdom, refreshed when the 20s DEBUFF expires. Judgement's cooldown is half that
--     debuff, so for a healer the icon is off cooldown every time the decision comes
--     up and its glow is lit for most of the fight — a permanent "press me" that is
--     wrong twice out of three times. The decision Holy actually makes is already
--     rendered by "Paladin - Judgement Debuff" (own-only, 20s, on the boss), which
--     stays ungated. Cutting the icon removes the false prompt, not the information.
--   * Hammer of Justice — a 6s stun. Prot uses it to interrupt casters and to pin a
--     runner while gathering a pack (an explicit line in the Prot rotation) and Ret
--     carries it as its only interrupt; for a Holy paladin it is a PvP button that
--     never enters a healing decision, and raid bosses are stun-immune anyway.
-- Divine Shield and Lay on Hands stay ungated on purpose — both are genuine
-- emergency buttons for all three specs (bubble also strips debuffs), and they are the
-- only Forbearance-burning presses left in the Holy row now Avenging Wrath is gone.
-- The 4th column is the v7 classification, and it decides BOTH how the icon shows and
-- whether it glows — the two are the same question asked twice:
--   true  = press-on-cooldown rotational. showAlways + desaturate-while-down + the gold
--           ready glow, because the glow IS the instruction and a hidden icon can never
--           fire one. Judgement (10s, off the GCD), Crusader Strike (6s), Avenger's Shield
--           (on pull, then on cooldown) and — new in v7 — Consecration, Protection's
--           largest threat source and an explicit press-on-cooldown line in the tank
--           rotation. See the v7 note in the header for why Ret's filler use does not
--           outweigh hiding a tank's biggest button.
--   false = situational / utility / emergency / long cooldown. showOnCooldown, no
--           desaturate: the icon exists only while the cooldown runs, and its ABSENCE is
--           the readout that the ability is available. Holy Shock is here on purpose —
--           an expensive instant kept for movement and emergencies, never pressed on
--           sight — as are the two Holy cooldowns (Divine Favor 2 min, Divine
--           Illumination 3 min), Avenging Wrath, and the two panic buttons.
local CDS = {
  { "Judgement",           20271, nil,   true,  GATE_HOLY },  -- v4: hidden from deep Holy
  { "Consecration",        26573, nil,   true,  GATE_HOLY },  -- v3: hidden from deep Holy; v7: now glows
  { "Hammer of Justice",     853, nil,   false, GATE_HOLY },  -- v4: hidden from deep Holy
  { "Avenging Wrath",      31884, nil,   false, GATE_HOLY },  -- v3: hidden from deep Holy
  { "Divine Shield",         642, nil,   false },
  { "Lay on Hands",          633, nil,   false },
  { "Holy Shock",          20473, 20473, false },
  { "Divine Favor",        20216, 20216, false },
  { "Divine Illumination", 31842, 31842, false },
  { "Avenger's Shield",    31935, 31935, true },
  { "Crusader Strike",     35395, 35395, true },
}
for _, e in ipairs(CDS) do
  local ic = reg(F.icon("Paladin CD - " .. e[1], CLASS, 32, 32, 0, 0, gCds.id))
  -- trigger 2 is the always-active state feeder that carries inCombat (disjunctive "all"
  -- stays satisfied); trigger 1 keeps driving the swipe. v7: the rotational icons stay
  -- showAlways so their glow can fire; everything else exists only while it is DOWN.
  ic.triggers = F.triggers({
    F.cdTrigger(e[2], e[1], e[4] and "showAlways" or "showOnCooldown"),
    F.unitCharTrigger(),
  })
  ic.cooldownTextDisabled = false  -- WA swipe text; no %p subtext (OmniCC would double it)
  ic.useTooltip = true
  ic.conditions = {}
  -- LAST condition: out of combat the row dims and the ready glow is forced off, so the
  -- HUD is still while you ride around (a later match overwrites the same property).
  local quiet = F.condition(2, "inCombat", "==", 0, "alpha", 0.5)
  if e[4] then
    -- showAlways, so both states are on screen and both need saying: grey while down,
    -- gold the instant it is up. (v7 leaves this branch byte-identical to v6.)
    ic.subRegions[1] = F.subglow(false, GOLD)  -- index 1 stays the glow; polish appends the border
    ic.conditions[#ic.conditions + 1] = F.condition(1, "onCooldown", "==", 1, "desaturate", true)
    ic.conditions[#ic.conditions + 1] = F.condition(1, "onCooldown", "==", 0, "sub.1.glow", true)
    quiet.changes[2] = { property = "sub.1.glow", value = false }
  end
  -- v7: NO desaturate on the situational icons — under showOnCooldown every visible icon
  -- is on cooldown by definition, so greying them all would only blur them together.
  ic.conditions[#ic.conditions + 1] = quiet
  if e[3] then gate(ic, e[3]) end
  if e[5] then gateNot(ic, e[5]) end
  polish(ic)
  adopt(gCds, ic)
end

-- ===== 31-33) v3: Retribution seal twisting ("swing dancing") =====
-- The twist: Seal of Command is up, and you re-seal with Seal of Blood (Horde) or
-- Seal of the Martyr (Alliance) in the last fraction of a second before the white
-- swing lands, so the swing procs BOTH seals. The window is ~0.4s, which is why this
-- needs a swing runway rather than a bare prompt.
--
-- Gate is Seal of Command's own rank-1 id (20375). SoC is a tier-3 Retribution talent,
-- so the gate reads "has ~10 points in Ret" — i.e. exactly "can twist", which is the
-- right semantic here even though it is not a Ret spec detector.
--
-- Swing Timer trigger, verified against WeakAuras Prototypes.lua (identical at tag
-- 3.5.0 and current, and NO Modernize migration touches it, so the current field names
-- are what to emit): type = "unit", event = "Swing Timer", weapon selector arg is
-- `hand` with values "main" / "off" / "ranged" (lowercase, from Private.swing_types).
-- Its state is a normal timed state (duration + expirationTime), so an aurabar animates
-- it, and `expirationTime` is a valid condition variable (type "timer" => the value is
-- remaining seconds), which is the repo's field-proven condition shape.
-- GOTCHA (from the prototype's own hidden test, `not inverse and duration > 0`): the
-- trigger produces NO state when the swing timer is not running. Before the first swing
-- of a fight the bar does not exist — it is not a bar sitting at zero — so it cannot be
-- used as an always-present anchor. That is the desired behaviour here: the runway
-- appears when you start swinging and vanishes when you stop.
local SWING_GATE = 20375                     -- Seal of Command r1
local SEAL_OF_COMMAND = { 20375, 20915, 20918, 20919, 20920, 27170 }
local TWIST_WINDOW = "0.4"                   -- seconds before impact
local function swingTrigger()
  local tr = { type = "unit", event = "Swing Timer", use_hand = true, hand = "main" }
  tr.names = {}; tr.spellIds = {}; tr.debuffType = "HELPFUL"
  tr.subeventPrefix = "SPELL"; tr.subeventSuffix = "_CAST_START"
  return tr
end

-- 31) the runway: main-hand swing draining toward impact, gold inside the twist window
local swing = reg(F.aurabar("Paladin - Swing Timer", CLASS, 172, 10, 0, -55, gRes.id,
  { 0.55, 0.55, 0.62, 1 }))
swing.triggers = F.triggers({ swingTrigger() })
swing.subRegions[2] = F.subborder("bar")
swing.conditions = {
  F.condition(1, "expirationTime", "<=", TWIST_WINDOW, "barColor", { 1, 0.82, 0.1, 1 }),
}
gate(swing, SWING_GATE)
adopt(gRes, swing)

-- 32) twist armed + NOW: shows while Seal of Command is up and you are swinging
-- (both triggers required), and glows in the last 0.4s — the press-SoB moment.
local twist = reg(F.icon("Paladin - Twist NOW", CLASS, 40, 40, 0, 0, gAlerts.id))
twist.iconSource = 0
twist.displayIcon = "Interface\\Icons\\ability_paladin_sealofblood"
twist.cooldown = false
twist.triggers = F.triggers({
  swingTrigger(),
  F.auraTrigger("player", true, SEAL_OF_COMMAND),
})
twist.subRegions[1] = F.subglow(false, { 1, 0.82, 0.1, 1 })
twist.conditions = {
  F.condition(1, "expirationTime", "<=", TWIST_WINDOW, "sub.1.glow", true),
}
twist.load.use_combat = true
gate(twist, SWING_GATE)
polish(twist)
adopt(gAlerts, twist)

-- ===== 34-44) v5: the PvP layer — arena and battleground only =====
-- Everything below is gated on WeakAuras' `size` load arg (UI label "Instance Size
-- Type"), verified in references/pvp.md against WA source:
--   * `use_size = false` is NOT "off". Multiselect load args are live for both true
--     and false and inert only at nil; false selects MULTI mode, which ORs entries.
--   * TBC's legal keys are none/party/ten/twenty/twentyfive/fortyman/pvp/arena.
--     `ratedarena`/`ratedpvp` are deleted for Classic flavors and can never match.
--   * anything that reads arena1..arena5 must be arena-ONLY: those unit ids do not
--     exist in a battleground, so a BG-loaded arena element is a permanently blank
--     slot.
-- Every PvP child carries its own gate. A group's load is not a child gate, and
-- per-child gates are also what lets the dynamic groups close their own gaps.
--
-- NOT built, because WeakAuras cannot express them without custom code (pvp.md §4):
--   * DIMINISHING RETURNS. There is no DR prototype, type table or bundled library
--     in WA, and faking it with an 18s timer models the reset window rather than the
--     category — wrong the moment two spells share one. Nothing in this layer is a
--     DR tracker; the CC readouts show the effect that is running right now, and
--     that is all they show.
--   * enemy spec/talents, reading an opponent's cooldowns (only the "saw the cast,
--     start my own countdown" inference below), and "only show casts I can
--     interrupt" — WA disables the interruptible filter on TBC outright, so the
--     stun prompt keys off "target is casting" plus "the stun is actually usable".
local function pvpLoad()    -- arena OR battleground
  return { use_size = false, size = { multi = { arena = true, pvp = true } } }
end
local function arenaLoad()  -- arena only (arena units, or rows that would flood a BG)
  return { use_size = false, size = { multi = { arena = true } } }
end
local function applyLoad(t, extra)
  for k, v in pairs(extra) do t.load[k] = v end
  return t
end

-- trigger stub identical to the factory's private one (names/spellIds/subevent
-- defaults every generic trigger table carries)
local function trig(t)
  t.names = {}; t.spellIds = {}
  t.subeventPrefix = "SPELL"; t.subeventSuffix = "_CAST_START"
  t.debuffType = t.debuffType or "HELPFUL"
  return t
end

-- Crowd Controlled: the ONLY non-custom-code way to see CC generically, with a real
-- duration and without enumerating ids — and the only way to see a school lockout at
-- all (a lockout is not an aura, so no aura trigger can find it). Omitting
-- use_controlType matches ANY loss-of-control effect.
local function ccTrigger()
  return trig{ type = "unit", event = "Crowd Controlled" }
end
-- item cooldown by NUMERIC item id; genericShowOn is REQUIRED or the aura never shows
local function trinketCdTrigger(itemId)
  return trig{ type = "item", event = "Cooldown Progress (Item)",
    use_itemName = true, itemName = itemId,
    use_genericShowOn = true, genericShowOn = "showOnCooldown" }
end
-- "Action Usable" folds cooldown + mana + (as a state var) range into one boolean:
-- the prompt exists only when the button can actually be pressed.
local function usableTrigger(spellId, name)
  return trig{ type = "spell", event = "Action Usable",
    use_spellName = true, spellName = spellId, realSpellName = name,
    use_exact_spellName = true, use_ignoreoverride = true }
end
-- enemy cast. No spell filter: TBC has no interruptible flag (WA disables the arg),
-- and an id whitelist of every enemy heal is unmaintainable. `remaining` narrows it
-- to the end of the cast, which is the window where a stun is worth spending.
local function castTrigger(unit, remaining)
  local tr = trig{ type = "unit", event = "Cast", unit = unit, use_unit = true }
  tr.use_remaining = true; tr.remaining = remaining; tr.remaining_operator = "<"
  return tr
end
-- aura2 hostility filtering is silently ignored on target/arena units (it only
-- applies to group/nameplate), so hostility needs its own Unit Characteristics
-- trigger AND-ed alongside.
local function targetHostileTrigger()
  local tr = F.unitCharTrigger()
  tr.unit = "target"; tr.use_hostility = true; tr.hostility = "hostile"
  return tr
end

-- PvP trinkets a PALADIN can equip, verified on wowhead/tbc (numeric item ids; a
-- name string reaches GetItemCooldown() -> nil and never fires):
--   37864 Medallion of the Alliance / 37865 Medallion of the Horde — 2 min, 2.4.3
--   18864 Insignia of the Alliance (Paladin) / 29592 Insignia of the Horde (Paladin)
--         — the 5 min level-60 pair, still on plenty of alts
-- The equipment-slot trigger is deliberately NOT used: it tracks whatever sits in
-- slot 13/14, so a PvE on-use trinket would report "medallion down" while it is up.
local PVP_TRINKETS = { 37864, 37865, 18864, 29592 }
local PVP_TRINKET_CAST = "42292"   -- "PvP Trinket", the spell the medallion casts
local FORBEARANCE = { 25771 }      -- 1 min; blocks Divine Shield / BoP / Avenging Wrath
-- Hard stops only. Mitigation cooldowns (Barkskin, Shield Wall, Pain Suppression)
-- do not change your next press and are deliberately absent.
local IMMUNITIES = {
  642, 1020,            -- Divine Shield r1-r2
  1022, 5599, 10278,    -- Blessing of Protection r1-r3 (physical immunity)
  45438,                -- Ice Block
  31224,                -- Cloak of Shadows
  34471,                -- The Beast Within (fear/stun immune — your HoJ is wasted)
  19752,                -- Divine Intervention
}
-- The short list worth a GCD in an arena, all ranks. NOT filtered by debuffClass:
-- that is UnitAura's dispel type, non-retail maps nil to "none", and physical CC has
-- no dispel type at all — a magic filter silently misses half of this and fires on
-- every trivial magic debuff besides.
local CLEANSABLE = {
  118, 12824, 12825, 12826, 28271, 28272,   -- Polymorph r1-r4 + turtle/pig
  5782, 6213, 6215,                         -- Fear r1-r3 (warlock)
  8122, 8124, 10888, 10890,                 -- Psychic Scream r1-r4
  5484, 17928,                              -- Howl of Terror r1-r2
  339, 1062, 5195, 5196, 9852, 9853, 26989, -- Entangling Roots r1-r7
  13218, 13222, 13223, 13224, 27189,        -- Wound Poison r1-r5 (healing -10%/stack)
  3409, 25809,                              -- Crippling Poison r1-r2
  3034, 14279, 14280, 27018,                -- Viper Sting r1-r4 (mana drain)
}

-- 34) the PvP column: mirrors the Alerts column on the other side of the character,
-- so the PvE layout never moves. Must be a dynamicgroup — two children are clone
-- sources, and clones inside a STATIC group stack on one spot.
local gPvP = reg(F.dynGroup("Paladin - PvP", 150, 96, TOP, "DOWN", "TOP", 6))
gPvP.animate = true
adopt(top, gPvP)

-- 35) CC ON ME — which break works, and whether to spend it now. Stun: the trinket
-- (you cannot bubble while stunned). Fear: trinket, then bubble. Root/snare:
-- Blessing of Freedom, NOT the trinket. School lockout: your Holy spells are gone
-- for the duration, so the answer is the trinket or distance, never another cast.
-- The icon is the effect's own (iconSource -1) and the number is the time left,
-- which is the whole "ride it or spend it" decision. NO combat gate: the opening
-- Sap lands before you are in combat.
local ccMe = alert("Paladin - CC ON ME", "Interface\\Icons\\spell_nature_polymorph", RED, nil)
ccMe.iconSource = -1
ccMe.triggers = F.triggers({ ccTrigger() })
table.insert(ccMe.subRegions, F.subtext("%p", 14, "INNER_BOTTOM"))
ccMe.load.use_combat = nil
applyLoad(ccMe, pvpLoad())
-- v6: colour IS the answer. Under a stun nobody reads text, and the icon of the effect
-- alone does not say which button breaks it — a paladin's four answers are genuinely
-- different spells. Red stun: only the trinket (you cannot bubble while stunned). Purple
-- fear: trinket, then bubble. Blue root/snare: Blessing of Freedom, NOT the trinket —
-- spending the medallion on a Frost Nova is how the next Hammer of Justice kills you.
-- Green confuse/polymorph: ride it, any damage breaks it, so do nothing and let a partner
-- clip it. Amber silence or school lockout: your Holy school is gone, nothing you press
-- will land, so trinket EARLIER than the timer suggests. Same five colours as the mage
-- pack (and every other pack in this repo) so one player learns one language.
--
-- `sub.1.glowColor` — verified in WA source, and all three preconditions hold here:
--   1. INDEX. Conditions.lua builds the key positionally from ipairs(data.subRegions),
--      so "sub.1" is correct only while the subglow is subRegions[1]. It is: alert()
--      assigns subRegions[1] = F.subglow(...), polish() APPENDS the border and the %p
--      subtext is table.insert-ed after that. Never insert a subregion ahead of index 1.
--   2. useGlowColor MUST be true or the setter is a silent no-op: SetGlowColor only
--      stores the value and re-runs SetVisible, which does `if self.useGlowColor then
--      color = self.glowColor end` and otherwise hands nil to LibCustomGlow. F.subglow
--      sets it true whenever a colour is passed, and RED is passed here.
--   3. The glow must be on — SetGlowColor's restart is guarded by `if self.glow`. alert()
--      passes glow = true, so it is lit the moment the aura shows.
-- Value shape is an ARRAY of four numbers: the property type is "color", and WA emits
-- {v[1], v[2], v[3], v[4]}, so an {r=,g=,b=,a=} hash would serialise to four nils.
-- The comparison is against the RAW loss-of-control key ("STUN", not a localised label),
-- and controlType is stored by the prototype (store = true) even without use_controlType,
-- so the bare Crowd Controlled trigger above feeds these conditions unchanged.
-- The five keys with no condition (NONE, CHARM, DISARM, PACIFY, POSSESS) fall back to the
-- aura's own base glowColor — red — which reads as "trinket food", the right default.
local CC_STUN    = { 1, 0.15, 0.15, 1 }   -- trinket, and only the trinket
local CC_FEAR    = { 0.7, 0.3, 1, 1 }     -- trinket, then bubble
local CC_ROOT    = { 0.3, 0.7, 1, 1 }     -- Blessing of Freedom — do NOT trinket
local CC_CONFUSE = { 0.4, 0.95, 0.5, 1 }  -- ride it; any damage breaks it
local CC_SILENCE = { 1, 0.85, 0.2, 1 }    -- school gone: trinket earlier than you think
ccMe.conditions = {
  F.condition(1, "controlType", "==", "STUN",             "sub.1.glowColor", CC_STUN),
  F.condition(1, "controlType", "==", "STUN_MECHANIC",    "sub.1.glowColor", CC_STUN),
  F.condition(1, "controlType", "==", "FEAR",             "sub.1.glowColor", CC_FEAR),
  F.condition(1, "controlType", "==", "FEAR_MECHANIC",    "sub.1.glowColor", CC_FEAR),
  F.condition(1, "controlType", "==", "CONFUSE",          "sub.1.glowColor", CC_CONFUSE),
  F.condition(1, "controlType", "==", "ROOT",             "sub.1.glowColor", CC_ROOT),
  F.condition(1, "controlType", "==", "SILENCE",          "sub.1.glowColor", CC_SILENCE),
  F.condition(1, "controlType", "==", "PACIFYSILENCE",    "sub.1.glowColor", CC_SILENCE),
  F.condition(1, "controlType", "==", "SCHOOL_INTERRUPT", "sub.1.glowColor", CC_SILENCE),
}

-- 36) Trinket DOWN — is my get-out-of-jail available. Shows ONLY while on cooldown,
-- so absence means ready and the column stays empty in the normal case. One trigger
-- per item id (itemName has no multiEntry), OR-ed.
local trinketTriggers = {}
for i, itemId in ipairs(PVP_TRINKETS) do trinketTriggers[i] = trinketCdTrigger(itemId) end
local trinket = reg(F.icon("Paladin - Trinket DOWN", CLASS, 32, 32, 0, 0, gPvP.id))
trinket.iconSource = 0
trinket.displayIcon = "Interface\\Icons\\INV_Jewelry_TrinketPVP_01"
trinket.triggers = F.triggers(trinketTriggers, { disjunctive = "any" })
trinket.cooldownTextDisabled = false   -- swipe numbers; no %p (OmniCC would double it)
trinket.desaturate = true              -- reads as "unavailable" at a glance
trinket.useTooltip = true
applyLoad(trinket, pvpLoad())
polish(trinket)
adopt(gPvP, trinket)

-- 37) Enemy Trinket — their medallion is down for two minutes: THIS is when the real
-- CC chain goes in. An inference, not a read (no API on 2.5.x reports another
-- player's cooldowns): the countdown starts when the cast is seen, so an opponent
-- who trinkets out of sight starts nothing. unit = "arena" makes one clone per
-- opponent, which is why the parent is a dynamic group and why this is arena-only.
local enemyTrinket = reg(F.icon("Paladin - Enemy Trinket", CLASS, 32, 32, 0, 0, gPvP.id))
enemyTrinket.iconSource = 0
enemyTrinket.displayIcon = "Interface\\Icons\\INV_Jewelry_TrinketPVP_02"
enemyTrinket.triggers = F.triggers({ trig{
  type = "event", event = "Spell Cast Succeeded",
  unit = "arena", use_unit = true,
  use_spellId = true, spellId = { PVP_TRINKET_CAST },
  duration = "120",     -- REQUIRED on a timedrequired trigger; missing = a 1s flash
} })
enemyTrinket.cooldownTextDisabled = false
applyLoad(enemyTrinket, arenaLoad())
polish(enemyTrinket)
adopt(gPvP, enemyTrinket)

-- 38) Forbearance — one icon per affected team member (yourself included), with the
-- time left. It answers the paladin question nothing else in the UI answers: who can
-- still be given Divine Shield, Blessing of Protection or Lay on Hands. BoP-ing a
-- partner locks your own bubble out of them for a minute, so "which of us survives"
-- is decided the moment you press it. Arena-only: in a 40-man battleground every
-- other paladin's bubble would push a clone into this column.
local forbear = reg(F.icon("Paladin - Forbearance", CLASS, 36, 36, 0, 0, gPvP.id))
forbear.triggers = F.triggers({ F.auraTrigger("group", false, FORBEARANCE,
  { showClones = true, combinePerUnit = true, perUnitMode = "affected" }) })
forbear.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
applyLoad(forbear, arenaLoad())
polish(forbear)
adopt(gPvP, forbear)

-- 39) CLEANSE — one icon per team member holding an effect worth a global, showing
-- WHICH effect (iconSource -1) and how long is left, because with the strongest
-- dispel in the game the decision is ordering, not speed. Gated on Cleanse's own id:
-- Purify (the level 8 version) cannot touch magic, which is most of this list.
-- Arena-only for the same reason as Forbearance.
local cleanse = reg(F.icon("Paladin - CLEANSE", CLASS, 36, 36, 0, 0, gPvP.id))
cleanse.triggers = F.triggers({ F.auraTrigger("group", false, CLEANSABLE,
  { showClones = true, combinePerUnit = true, perUnitMode = "affected" }) })
cleanse.subRegions[1] = F.subglow(true, BLUE)   -- the one row here that means "press it"
cleanse.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
gate(cleanse, 4987)
applyLoad(cleanse, arenaLoad())
polish(cleanse)
adopt(gPvP, cleanse)

-- 40) HAMMER NOW — a paladin has no interrupt, so the stun is the interrupt. Both
-- triggers must be true: the target is inside the last 1.5s of a cast AND Hammer of
-- Justice is genuinely castable (Action Usable covers cooldown and mana). A prompt
-- that fires while the stun is down teaches you to ignore it. Hammer is 10 yards, so
-- out of range the icon desaturates: the prompt then reads "walk in first", which is
-- a different decision from "press it".
local hammerNow = alert("Paladin - HAMMER NOW", "Interface\\Icons\\spell_holy_sealofmight", GOLD, 853)
hammerNow.triggers = F.triggers({
  castTrigger("target", "1.5"),
  usableTrigger(853, "Hammer of Justice"),
})
table.insert(hammerNow.subRegions, F.subtext("%p", 12, "INNER_BOTTOM"))
hammerNow.conditions = { F.condition(2, "spellInRange", "==", 0, "desaturate", true) }
hammerNow.load.use_combat = nil
applyLoad(hammerNow, pvpLoad())

-- 41) TARGET IMMUNE — stop. Judging, Crusader Striking or burning Avenging Wrath
-- into Divine Shield / Ice Block / Blessing of Protection / Cloak of Shadows spends
-- the whole set for zero damage; The Beast Within means the stun is wasted too.
-- Trigger 2 keeps it off a friendly target (aura2 cannot filter hostility here).
local immune = alert("Paladin - TARGET IMMUNE", "Interface\\Icons\\spell_holy_divineintervention", RED, nil)
immune.iconSource = -1
immune.triggers = F.triggers({ F.auraTrigger("target", true, IMMUNITIES), targetHostileTrigger() })
table.insert(immune.subRegions, F.subtext("%p", 12, "INNER_BOTTOM"))
immune.load.use_combat = nil
applyLoad(immune, pvpLoad())

-- 42-44) cooldown row, PvP-only additions. Same language as the rest of the row (swipe
-- numbers, 50% alpha out of combat) and deliberately NO ready-glow: these are held for a
-- moment, not pressed on cooldown. v7 makes that classification literal — all three are
-- situational by definition (a peel, a snare-break and a stun), so they show only while
-- they are DOWN and the desaturate goes with the always-on display.
local function pvpCd(label, spellName, spellId, gateSpell)
  local ic = reg(F.icon("Paladin CD - " .. label, CLASS, 32, 32, 0, 0, gCds.id))
  ic.triggers = F.triggers({ F.cdTrigger(spellId, spellName, "showOnCooldown"), F.unitCharTrigger() })
  ic.cooldownTextDisabled = false
  ic.useTooltip = true
  ic.conditions = {
    F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  }
  gate(ic, gateSpell)
  applyLoad(ic, pvpLoad())
  polish(ic)
  adopt(gCds, ic)
  return ic
end
-- Freedom is the answer to every root and snare — including the ones a trinket
-- should never be spent on — so "is it up" decides whether the trinket has to go.
pvpCd("Blessing of Freedom", "Blessing of Freedom", 1044, 1044)
-- BoP is the peel, and it burns Forbearance: read it next to the Forbearance row.
pvpCd("Blessing of Protection", "Blessing of Protection", 1022, 1022)
-- v4 hid the shared Hammer of Justice icon from deep Holy, which is right in a raid
-- (bosses are stun-immune) and wrong in an arena, where the stun is a healer's main
-- peel. This copy is the exact inverse gate — Holy Shock known — plus the PvP gate,
-- so it can never double up with the icon above it.
pvpCd("Hammer of Justice (PvP)", "Hammer of Justice", 853, GATE_HOLY)

-- ===== assemble (v2000 nested), encode, verify, write =====
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

local outPath = dir .. "/all-specs.txt"
-- compare against the previously shipped build BEFORE overwriting it: every future
-- version gets the uid-continuity check for free (changed must stay 0)
local cont = W.uidContinuity(encoded, outPath)

local out = io.open(outPath, "w")
out:write(encoded)
out:close()

print(("OK: %d auras (1 top + %d children), %d chars -> all-specs.txt")
  :format(#transmit.c + 1, #transmit.c, #encoded))
if cont then
  print(("uid continuity vs previous all-specs.txt: stable=%d changed=%d parentSame=%s")
    :format(cont.stable, cont.changed, tostring(cont.parentSame)))
else
  print("uid continuity: no previous all-specs.txt (first build)")
end
