-- generate.lua — Hunter TBC HUD, Beast Mastery & Survival (v10).
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
-- v6 (see README "v6 — the cooldown row shows what you CANNOT press"): no new auras, no
-- new uids, no load-gate changes. The row is re-split along the one line that matters —
-- which of these buttons is pressed the moment it is up, and which is pressed when a
-- circumstance calls for it (references/rotation-design.md, "Show what the player CANNOT
-- press"). Each of the eleven icons was classified against the BM (41/20/0) and SV
-- (0/20/41) raid priorities, not converted wholesale:
--   * ROTATIONAL, stay showAlways and GAIN the gold ready-glow they never had:
--     Multi-Shot and Arcane Shot. Both guides are explicit that Multi-Shot replaces a
--     Steady Shot on cooldown (it is more damage per use than Steady Shot even on one
--     target), and Arcane Shot is the same weave slot's other half plus the instant you
--     press while moving. Hiding the two buttons a hunter presses most would trade a
--     "press this now" signal for a "you cannot press this" one.
--   * SITUATIONAL, become showOnCooldown and lose the now-meaningless desaturate:
--     Intimidation, Readiness, Wyvern Sting, Misdirection, Feign Death, and the two
--     PvP-gated ones, Freezing Trap and Scatter Shot. Misdirection and Feign Death are
--     the two whose moment is already owned by a threat-paired prompt in the alert flow,
--     so the row icon only has to answer "when does it come back".
--   * Rapid Fire and Bestial Wrath are burst cooldowns spent at a window (the opener,
--     and again after Readiness), so they are situational too and become showOnCooldown.
--     They KEEP their desaturate: on those two it is not the generic dimmer, it is the
--     second half of the v2 active-window readout (full colour + glow = the window is
--     live, dim = the window is spent and the button is recharging), and it is overridden
--     during the window by the later sub.1.glow condition. The stated reason for dropping
--     desaturate — "every visible icon is on cooldown, so greying them all makes the
--     abilities harder to tell apart" — does not hold for an icon whose visible states
--     include a live buff window.
--
-- v7: the PvP trinket readout tracked item 30346, which wowhead confirms is the
-- PRIEST-restricted Medallion of the Horde — a hunter can never equip it, so its
-- cooldown trigger could never fire and a Horde hunter's "Trinket DOWN" state was
-- silently dead. Replaced with 37865, the all-class 2.4 Medallion of the Horde (the
-- twin of 37864), which is the pair every other pack in this repo uses.
--
-- v8: the centre of the screen is FREED. The three stacked 172x14 bars (health, mana,
-- threat) and the threat flash are gone as *rectangles*; the same four auras — same ids,
-- same uids, same triggers, same load gates — are now radial rings around two unit orbs
-- that flank the character: PLAYER on the left at x=-250, TARGET on the right at x=+250.
-- Nothing outside the Resources group changed at all.
--   * A ring is a `progresstexture` region (WeakAuras' own Ring_10px.tga) filling
--     CLOCKWISE from 12 o'clock. wa_factory.lua has no progresstexture or model builder,
--     so those two tables are spelt out below; every other piece still goes through it.
--   * The colour escalations SURVIVE, renamed: on an aurabar the condition property is
--     `barColor`; on a progresstexture it is `foregroundColor` (ProgressTexture.lua's
--     module-level `properties` table). The rename is SILENT — Conditions.lua skips a
--     change whose property is not in the region's properties table, with no error — so a
--     mechanical port that kept `barColor` would have shipped four dead escalations.
--   * Threat becomes the OUTERMOST ring of the target orb, which is where it belongs:
--     it is your threat on that target. Same three tiers, same party/raid + not-arena
--     gates. The 80% flash becomes a pulsing red halo ring just outside it.
--   * MANDATORY zero-total guards. AuraBar.lua draws EMPTY at total == 0;
--     ProgressTexture.lua draws FULL (`local progress = 1; if self.total > 0 then ...`).
--     Threat's total is threatvalue*100/threatpct, so it is 0 the instant after a Feign
--     Death — a ring would slam to a full circle meaning "at the pull threshold" while
--     the colour stayed green. Every ring therefore carries an alpha-0 condition on its
--     own trigger's total (threatvalue <= 0, maxhealth <= 0, maxpower <= 1).
--   * The mana ring gains the two aspect-swap breakpoints as static marks: a red tick at
--     20% (Go Viper) and a green one at 80% (Back to Hawk), the exact thresholds the two
--     alerts already fire on. Sub-region ticks are `subtexture`, which is the only tick
--     recipe that works here — `subtick`, the aurabar tick, is aurabar-ONLY
--     (SubRegionTypes/Tick.lua `supports()` returns regionType == "aurabar").
--   * Six NEW auras, all constructed at the very bottom: two cluster groups, the two
--     live unit portraits (`model` regions bound to the unit) and the target's own
--     health and mana rings. stable=46 changed=0 missing=0 — nothing is orphaned.
--
-- v9: PURE GEOMETRY. Not one trigger, load gate, condition, colour, spell id or region
-- type moved; no aura was added or removed (stable=52 changed=0). v8 shipped seven packs
-- that each invented their own orb sizes, and inside this pack the player and target
-- clusters did not even agree with each other — the player orb read 84px across, the
-- target 108, which is what a player sees as "uneven". v9 adopts the ONE canonical orb
-- geometry now shared by all seven packs (see the CANON block below):
--   * Ring_20px replaces Ring_10px on every ring. At these diameters the 10px art scaled
--     down to a ~3px hairline and read as a wire, not an arc.
--   * Both clusters now present the SAME outer diameter (104) and the SAME portrait (46).
--     The target simply nests one more ring inside: threat 104 / health 78 / mana 54,
--     against the player's health 104 / mana 78. Nothing else about either side changed.
--   * The readouts move to the shared baselines (health 14pt at -60, power 11pt at -76,
--     threat 11pt at +60), so the target's health number is no longer 20px lower than the
--     player's. Both clusters move to the shared anchor: absolute (-260, -60) and
--     (+260, -60), which is also what lifts a 104px orb clear of the cooldown row.
--   * THE TRAP: the mana ring's two aspect-swap ticks are `subtexture` marks placed by
--     TRIGONOMETRY from the ring RADIUS (x = r*sin, y = r*cos). Growing the ring 60 -> 78
--     without re-deriving them would leave both marks floating 9px inside their own arc.
--     They are computed from G.mpRing here, so they moved with it: the 20% mark from
--     (26.63, 8.65) to (35.19, 11.43) and the 80% mark from (-26.63, 8.65) to
--     (-35.19, 11.43). Both still land on the ring's circumference at their own angle.
--
-- v10: DIABLO GLOBES. The rings are gone and so are the portraits. Health and mana are
-- now VESSELS that fill bottom-to-top like liquid, with the percentage inside the glass.
-- No trigger, load gate, spell id or escalation outside the orb cluster moved; no aura was
-- removed (stable=47 changed=0 missing=0 — the four renamed auras keep their uids).
--   * A globe is the SAME progresstexture region the rings were, with one different field:
--     orientation = "VERTICAL", which WeakAuras names "Bottom to Top". The name lies about
--     direction in the usual way — VERTICAL fills UP, VERTICAL_INVERSE fills DOWN — so
--     getting it backwards would drain the globe from the top as you take damage.
--     Switching to the LINEAR fill path also swaps which fields are live: compress /
--     slanted / slantMode matter now and startAngle / endAngle no longer do. crop stays at
--     the 0.41 default (on the linear path it is just the texcoord scale).
--   * THE PORTRAITS ARE DELETED AS REGIONS, NOT AS AURAS. Diablo has no portrait, and
--     dropping it is what frees the centre of each globe for its number: a `model` region
--     can never carry a text subregion (SubText's supports() lists texture /
--     progresstexture / icon / aurabar — not model), which is the only reason the ring
--     build had to park its percentages outside. Both portrait auras are RECYCLED onto
--     glass rims instead — same uid, same triggers, same conditions, new region type — so
--     no orphan is left behind in anyone's WeakAuras.
--   * THREAT HAS NO NATURAL VESSEL, so it becomes the TARGET GLOBE'S RIM COLOUR: green
--     base, orange at 70%, red-orange at 90%, deep red on aggro, with the percentage above
--     the globe. Same aura, same trigger, same party/raid + not-arena gates, same three
--     tiers and the same mandatory threatvalue <= 0 alpha guard. The property renames
--     AGAIN — `foregroundColor` on a progresstexture, `color` on a texture — and the rename
--     is silent, so a mechanical port would have shipped three dead escalations.
--   * The two aspect-swap breakpoints get EASIER, not harder. On a ring they were placed by
--     trigonometry; on a vessel a threshold is a horizontal waterline at a fixed height,
--     yOffset = (threshold/max - 0.5) * GLOBE_MAIN, and its width is the circle's chord at
--     that height. Same two marks, same two colours, same subRegion indices.
--   * TWO NEW AURAS, both rims (the player's power globe and the target's small power
--     globe), appended at the very end so every existing uid() call keeps its position.
--   * THE ONE THING OUTSIDE THE ORBS THAT HAD TO MOVE: the buff row. The canonical target
--     globe sits at absolute (0, -150) and the buff row sat at absolute (0, -156) — the
--     globe would have been drawn straight through Serpent Sting and Hunter's Mark. The
--     group is re-anchored to absolute (0, -60), the band the player orb used to occupy,
--     which also puts the target's two debuff timers directly above the target globe.
--     Nothing else about those icons changed: same ids, uids, triggers, gates, sizes.
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
-- NB 37865, not 30346: wowhead item=30346 is the PRIEST-restricted Medallion of the
-- Horde (classes bitmask 16), so a hunter can never equip it and its cooldown trigger
-- could never fire — a Horde hunter's trinket readout was silently dead. 37865 is the
-- 2.4 all-class Medallion of the Horde, the Alliance twin of 37864. Both verified on
-- wowhead.com/tbc; the same pair is used by every other pack in this repo.
local TRINKETS = {
  37865,  -- Medallion of the Horde    (all classes, lvl 70, 2 min)
  37864,  -- Medallion of the Alliance (all classes, lvl 70, 2 min)
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

-- ===== globe machinery (v8 rings, rebuilt as v10 vessels) =====
-- `progresstexture` is the one region type wa_factory.lua does not build, so that table is
-- spelt out below; the rims are plain F.texture regions and everything else still goes
-- through the factory. internalVersion stays 45, and no Modernize block at IV >= 45 renames
-- a progresstexture fill field or a subtexture field, so what is emitted here is what the
-- current client runs. (The `model` builder v8 needed is gone with the portraits.)
local IV, TOC = 45, 20501

-- ===== v10 CANON: the globe geometry every pack in this repo shares ==========
-- These constants are IDENTICAL in all seven packs. Do not scale, round or "improve" them
-- here: the moment one pack drifts, the player sees differently-sized globes the instant
-- they run two classes, which is exactly the bug the shared canon exists to prevent.
-- Change them in all seven build scripts or not at all.
--
-- Circle_Smooth.tga is a SOLID DISC — the liquid. Circle_Smooth_Border.tga is the ring of
-- glass drawn around it. Both ship inside WeakAuras itself (Private.texture_types,
-- "Shapes"), so nothing here needs a media addon. Note it is Circle_Smooth, NOT the
-- Circle_Smooth2 the rest of this repo uses for pips: the border art is cut for the former.
local FILL_TEX   = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Smooth.tga"
local RIM_TEX    = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Smooth_Border.tga"
local GLOBE_MAIN = 72   -- the life and power globes
local GLOBE_TGT  = 44    -- the target globe
local RIM_PAD    = 4     -- a rim texture is its globe's size + 6, drawn at frameStrata 2
local GLOBE_X    = 150   -- ABSOLUTE screen x: life at -300, power at +300, target at 0
local GLOBE_Y      = -262  -- ABSOLUTE screen y of all three globe centres

-- The readouts, and the whole point of losing the portrait: the number goes INSIDE the
-- glass, dead centre, where the eye already is.
local PCT_MAIN   = { size = 18, y =  0 }   -- life and power, inside the main globes
local PCT_TGT    = { size = 13, y =  0 }   -- target health, inside the small globe
local PCT_THREAT = { size = 11, y = 52 }   -- threat, ABOVE the target globe

-- Pack-local geometry, all of it derived from the canon so the two can never drift.
--   resY expresses GLOBE_Y in the top group's frame: `top` sits at -140, so the Resources
--   group offsets a further 10 DOWN to land its children at an absolute -150, and every
--   globe below carries its own x. Walk it: top(0,-140) -> Resources(0,-10) -> cluster
--   group(0,0) -> globe(±300,0) = (±300,-150).
--   flashHalo and the target's power globe are the only sizes NOT in the canon (no other
--   pack has this pack's threat halo, and the canon has no fourth vessel). Both are
--   DERIVED, never guessed: the halo is one rim-pad outside the target rim, and the target
--   power globe is half the target globe, set beside it with one rim-pad of clearance —
--   power to the RIGHT of life, the same sentence the two main globes speak.
local TOP_Y = -140
local TGT_POWER = GLOBE_TGT / 2                                        -- 38
local TGT_POWER_X = (GLOBE_TGT + RIM_PAD) / 2                          -- rim radius, 41
                  + (TGT_POWER + RIM_PAD) / 2                          -- its rim radius, 22
                  + RIM_PAD                                            -- clearance -> 69
local G = {
  resY       = GLOBE_Y - TOP_Y,     -- -10: the Resources group's own offset
  globeX     = GLOBE_X,
  lifeGlobe  = GLOBE_MAIN,          -- PLAYER health, left
  powerGlobe = GLOBE_MAIN,          -- PLAYER mana, right
  tgtGlobe   = GLOBE_TGT,           -- TARGET health, centre
  tgtPower   = TGT_POWER,           -- TARGET mana, beside it
  tgtPowerX  = TGT_POWER_X,
  flashHalo  = GLOBE_TGT + RIM_PAD * 2,   -- the 80% threat halo, one pad outside the rim
}

-- Colours. The three globe colours and the rim are canon (identical in every pack); the
-- text colours and the threat green are carried over UNCHANGED from the v7 bars, so the
-- HUD keeps speaking one language across the versions.
--
-- THE POWER GLOBE IS COLOURED FOR THE POWER TYPE IT ACTUALLY READS. A hunter's is mana,
-- always and in every spec, so it is D2 mana blue; the energy/rage colours in the canon
-- belong to the packs whose power globe reads those bars.
local COL = {
  life   = { 0.72, 0.09, 0.09, 1 },     -- D2 life red — player AND target vessels
  mana   = { 0.13, 0.30, 0.85, 1 },     -- D2 mana blue — the hunter's only power type
  rim    = { 0.62, 0.55, 0.40, 1 },     -- brassy glass
  empty  = { 0.05, 0.05, 0.07, 0.85 },  -- the UNFILLED vessel, nearly black
  threat = { 0.25, 0.8, 0.3, 1 },       -- v7 threat green, now worn by the target's rim
  hpText = { 1, 1, 1, 1 },
  mpText = { 0.55, 0.75, 1, 1 },        -- echoes the mana globe, so the two numbers
  thText = { 0.75, 0.95, 0.78, 1 },     -- never need labels to be told apart
}

-- wa_factory's stub() is local to the factory; the hand-written region tables below get
-- the identical scaffolding here.
local function orbStub(t)
  t.internalVersion, t.tocversion = IV, TOC
  t.actions = { init = {}, start = {}, finish = {} }
  t.animation = {
    start  = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
    main   = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
    finish = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
  }
  t.conditions = t.conditions or {}
  t.config, t.authorOptions, t.information = {}, {}, {}
  return t
end

-- The factory's private trigger stub, and the two unit triggers it hardwires to
-- unit = "player" (these clusters need "target" as well).
local function orbTrig(t)
  t.names, t.spellIds = {}, {}
  t.subeventPrefix, t.subeventSuffix = "SPELL", "_CAST_START"
  t.debuffType = "HELPFUL"
  return t
end

-- Health. The prototype ANDs a hidden always-on test into the trigger function,
--   WeakAuras.UnitExistsFixed(unit, smart) and specificUnitCheck
-- so unit = "target" with no target produces NO STATE and the region hides. That is the
-- entire self-hide mechanism for the target cluster: no condition, no load gate, no code.
local function unitHealth(unit)
  return orbTrig{ type = "unit", event = "Health", unit = unit, use_unit = true }
end

-- Mana, and only mana, for the TARGET orb. All three flags are load-bearing:
--   use_powertype + powertype = 0  -> read MANA specifically. Drop either and powerType
--     is nil and the trigger silently falls back to the unit's CURRENT bar — a rogue's
--     energy rendered in a ring coloured for mana.
--   use_requirePowerType           -> the ring only exists while mana is that unit's
--     PRIMARY bar, so a warrior or rogue target produces no state and the ring vanishes
--     instead of parking a permanently empty blue circle. It is enabled by use_powertype,
--     so both are needed. The player's own ring keeps F.powerTrigger(0) verbatim from v7.
local function unitMana(unit)
  return orbTrig{
    type = "unit", event = "Power", unit = unit, use_unit = true,
    use_powertype = true, powertype = 0, use_requirePowerType = true,
  }
end

-- THE VESSEL. Same progresstexture region the rings were; the fields that changed are the
-- ones that turn a radial sweep into a rising waterline. Field notes on the traps:
--   orientation VERTICAL -> "Bottom to Top" in WeakAuras' own naming
--     (orientation_with_circle_types). The key LIES about direction in the usual WA way:
--     VERTICAL fills UP, VERTICAL_INVERSE fills DOWN. Backwards, the globe would drain
--     from the top as you take damage — which looks deliberate, and is wrong.
--   foreground/backgroundTexture = a SOLID DISC. The fill is clipped to a rising
--     rectangle of that disc, which is precisely a liquid line in a round vessel.
--   backgroundColor = the EMPTY portion, and it is what sells the container read: a
--     nearly-black disc that coloured liquid rises into, not a shape appearing from the
--     void. backgroundOffset 0 keeps the empty part the same disc as the full part rather
--     than a halo around it.
--   crop_x / crop_y = 0.41 -> unchanged from the ring build, but for a different reason:
--     the sqrt(2) expansion that 0.41 cancelled is applied in the CIRCULAR branch only. On
--     the linear path it is simply the texcoord scale, and 0.41 is the default.
--   compress / slanted / slant / slantFirst / slantMode were inert on a ring and are LIVE
--     here. slant stays 0 deliberately: a straight waterline is what reads as liquid.
--   startAngle / endAngle are now the ignored pair. They are emitted because they are in
--     the default table.
--   auraRotation = 0 -> absent from the 3.5.0 default table but read unconditionally by
--     current code as data.auraRotation / 180 * math.pi, so it must be emitted.
--   adjustedMin/Max are STRINGS (""), because SetAdjustedMin does adjustedMin:find(...).
--   progressSource is rewritten to {-1, ""} by Modernize < 71 no matter what is emitted;
--     it is here for readability only. {-1,""} = Automatic, which is what routes the
--     Health/Power prototype's value/total into the fill with no further wiring.
-- ONE PROGRESS TRIGGER PER GLOBE, and it must be trigger 1: Modernize < 71 forces
-- Automatic, and F.triggers sets activeTriggerMode = -10 (first_active). A second trigger
-- can only feed conditions (that is what F.unitCharTrigger does below), never the fill.
local function globe(id, size, color, triggers)
  return orbStub{
    regionType = "progresstexture", id = id, uid = W.uid(), parent = nil,
    width = size, height = size,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = 0, yOffset = 0, frameStrata = 1, alpha = 1,
    orientation = "VERTICAL", startAngle = 0, endAngle = 360,
    inverse = false, mirror = false,
    compress = false, slanted = false, slant = 0, slantFirst = false, slantMode = "INSIDE",
    foregroundTexture = FILL_TEX, backgroundTexture = FILL_TEX, sameTexture = true,
    desaturateForeground = false, desaturateBackground = false,
    foregroundColor = color, backgroundColor = COL.empty,
    backgroundOffset = 0,
    blendMode = "BLEND", textureWrapMode = "CLAMPTOBLACKADDITIVE",
    crop_x = 0.41, crop_y = 0.41, rotation = 0, auraRotation = 0,
    user_x = 0, user_y = 0,
    progressSource = { -1, "" },
    useAdjustededMin = false, useAdjustededMax = false,
    adjustedMin = "", adjustedMax = "",
    smoothProgress = true, overlayclip = false, overlays = {},
    subRegions = {},
    triggers = triggers,
    load = F.load(CLASS),
  }
end

-- THE GLASS. A plain `texture` region carrying the border art, its globe's size + RIM_PAD,
-- at frameStrata 2 — it has no progress of its own. It carries the SAME triggers as the
-- globe it wraps purely so the two appear and vanish together; a rim outliving its vessel
-- would be an empty hoop, which is the ring HUD this version deletes.
-- The colour is a condition target on a texture region under the property name `color`
-- (Texture.lua's module-level properties table) — NOT `foregroundColor`, which is the
-- progresstexture name. Conditions.lua skips a change whose property is unknown to the
-- region, in silence, so the wrong name here ships a dead escalation.
local function rim(id, size, color, triggers)
  local t = F.texture(id, CLASS, size, size, 0, 0, nil, RIM_TEX, color)
  t.triggers = triggers
  t.frameStrata = 2
  return t
end

-- The percentage numbers now sit INSIDE the glass, which is the whole dividend of dropping
-- the portrait: a progresstexture accepts a subtext, a `model` region never could (SubText's
-- supports() gate lists texture / progresstexture / icon / aurabar / empty — not model), and
-- that is the only reason the ring build had to park its readouts outside where they
-- competed with the world. Each number still rides on its own region, so it appears and
-- disappears with it: no target, no number; no threat state, no threat number.
--
-- THE OFFSET KEY IS `text_anchorYOffset`, NOT `anchorYOffset`. Both names live in the
-- subtext default table, but SubText.modify only ever reads the text_-prefixed pair
-- (`region.text_anchorXOffset = data.text_anchorXOffset`, then Anchor() passes
-- `self.text_anchorYOffset or 0` to AnchorSubRegion) — in WA 3.5.0 AND in current code,
-- and no Modernize block renames one to the other. Writing only `anchorYOffset` is a
-- silent no-op that stacks every readout dead centre, on top of the portrait. Both are
-- set here: the text_ pair does the work, the bare pair keeps the table self-consistent.
local function pct(sym, size, y, color)
  local st = F.subtext("%" .. sym .. "%%", size, "CENTER", sym)
  st.text_anchorXOffset, st.text_anchorYOffset = 0, y
  st.anchorXOffset, st.anchorYOffset = 0, y
  st.text_color = color
  return st
end

-- A static breakpoint mark on a globe — a WATERLINE, and this is where the vessel pays for
-- itself. On the ring these two marks were placed by trigonometry from the ring radius, and
-- resizing the ring without re-deriving them left both floating inside their own arc. On a
-- vessel a threshold is just a horizontal line at a fixed height:
--
--   yOffset = (threshold/max - 0.5) * GLOBE_MAIN
--
-- and the line's WIDTH is the circle's chord at that height, GLOBE * sqrt(1 - (2f-1)^2),
-- so the mark spans the glass exactly and stops at the edge instead of poking out of it.
-- At f = 0.20 and f = 0.80 that is y = -+34.8 and a width of 92.8 on a 116px globe.
--
-- Still a `subtexture`: `subtick`, the tick sub-region, is aurabar-ONLY (SubRegionTypes/
-- Tick.lua: supports() returns regionType == "aurabar"), while subtexture's supports() does
-- list progresstexture. The art is a plain white square stretched into a thin bar, so
-- textureRotate/textureRotation stay off — rotation there is texture-COORDINATE based and a
-- square is invariant under it, which removes that gate as a failure mode.
-- xOffset/yOffset are NOT in the subtexture default() table but ARE what modify() hands to
-- AnchorSubRegion, so they must be emitted or every mark stacks at dead centre.
local MARK_H = 3   -- thin enough to read as a line on the liquid, thick enough to see
local function waterMark(fraction, diameter, color)
  local function round(v) return math.floor(v * 100 + 0.5) / 100 end
  return {
    type = "subtexture",
    textureVisible = true,
    textureTexture = F.TEX_SQUARE,
    textureColor = color, textureBlendMode = "BLEND",
    textureDesaturate = false, textureMirror = false,
    textureRotate = false, textureRotation = 0,
    anchor_mode = "point", anchor_point = "CENTER", self_point = "CENTER",
    anchor_area = "ALL",
    width = round(diameter * math.sqrt(1 - (2 * fraction - 1) ^ 2)), height = MARK_H,
    scale = 1, mirror = false, rotate = false,
    xOffset = 0,
    yOffset = round((fraction - 0.5) * diameter),
  }
end

-- ===== 1. top-level group, anchored below the character =====
local top = F.group(TOP, 0, -140, nil)
top.uid = W.uid()

-- ===== 2. Resources: the three globes =====
-- v8 emptied the middle of the screen of its bar stack; v10 fills the low band with the
-- three vessels instead. The group keeps its id and its uid — a v9 user gets an in-place
-- Update, not a second copy — and only its own offset changes, from +80 (which put the
-- clusters at an absolute -60) to -10, which puts every globe centre at an absolute -150.
local gRes = reg(F.group("Hunter - Resources", 0, G.resY, nil))
adopt(top, gRes)

-- 3. LIFE — don't die. The same aura as v7's health bar and v9's health ring: same id,
--    same uid, same two triggers, same escalation. It is now the LEFT VESSEL, filling
--    bottom-to-top, with the percentage inside the glass. It is re-parented into the
--    player cluster in the block at the bottom of this file, because that cluster group is
--    a newer aura and every new W.uid() call has to come after all the existing ones.
--    The <30% escalation is on `foregroundColor` — NOT `barColor`, which does not exist on
--    a progresstexture and would have been dropped in silence.
local hp = reg(globe("Hunter - Health", G.lifeGlobe, COL.life,
  F.triggers({ F.healthTrigger(nil), F.unitCharTrigger() })))
hp.xOffset = -G.globeX
hp.subRegions[1] = pct("percenthealth", PCT_MAIN.size, PCT_MAIN.y, COL.hpText)
hp.conditions = {
  F.condition(1, "percenthealth", "<", "30", "foregroundColor", { 0.9, 0.12, 0.12, 1 }),
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  -- ZERO-TOTAL GUARD, and it is not optional. The Health prototype's total is
  -- UnitHealthMax(unit) with NO floor, and ProgressTexture.UpdateValue starts at
  -- progress = 1 and only divides when total > 0 — so a unit whose max health has not
  -- streamed in yet would flash a FULL vessel. The aurabar did the opposite (it starts at
  -- 0), which is why v7 needed no such guard. Last, so it wins over the combat fade.
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

-- 4. POWER — the hunter resource, and it is MANA in every hunter spec, so the vessel is
--    D2 mana blue. Turns red at the Viper threshold (20%: Viper's regen scales off MISSING
--    mana, so swapping at 15% is already late). The RIGHT VESSEL, carrying the two
--    aspect-swap breakpoints as waterlines so the swap band is visible before either alert
--    fires.
local mana = reg(globe("Hunter - Mana", G.powerGlobe, COL.mana,
  F.triggers({ F.powerTrigger(0), F.unitCharTrigger() })))
mana.xOffset = G.globeX
mana.subRegions[1] = pct("percentpower", PCT_MAIN.size, PCT_MAIN.y, COL.mpText)
-- APPEND-ONLY: no condition in this pack points at sub.N on this aura today, but the
-- readout must stay index 1 if one ever does — so the two marks keep indices 2 and 3.
-- v10: the trigonometry is GONE. Both marks are derived from the globe diameter by the
-- one formula in waterMark(), so 20% is a line at y = -34.8 spanning 92.8px of glass and
-- 80% is its mirror at +34.8 — the fill line crosses the red mark exactly when Viper is
-- due and the green one exactly when Hawk is.
mana.subRegions[2] = waterMark(0.20, G.powerGlobe, { 0.85, 0.2, 0.2, 1 })   -- Go Viper
mana.subRegions[3] = waterMark(0.80, G.powerGlobe, { 0.4, 1, 0.4, 1 })      -- Back to Hawk
mana.conditions = {
  F.condition(1, "percentpower", "<", "20", "foregroundColor", { 0.85, 0.2, 0.2, 1 }),
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  -- Power is the one prototype that floors its own total (math.max(1, UnitPowerMax)),
  -- which is why this guard reads <= 1 and not <= 0. Inert for a hunter, kept for shape.
  F.condition(1, "maxpower", "<=", "1", "alpha", 0),
}

-- v5: "everywhere except an arena", spelled out. The `size` load arg declares no
-- `inverse` and no `test`, so there is genuinely no "not arena" key — the complement has
-- to be enumerated, and the emitted load test is a plain OR of string compares. `none` is
-- the load-bearing entry: in the open world GetInstanceTypeAndSize returns the literal
-- STRING "none" (its explicit fallthrough return, not nil), so leaving it out would delete
-- the threat readout while questing. `pvp` (battleground) stays in: AV has NPCs and a real
-- threat table. `arena` is the only key left out — an arena has no threat table at all, so
-- there the readout is a dead green shape wrapped around every opponent you click.
local function noArenaSize()
  return { multi = {
    none = true, party = true, ten = true, twenty = true,
    twentyfive = true, fortyman = true, pvp = true,
  } }
end

-- 5. threat — escalating tiers, each one paired with the ability that answers it:
--    orange at 70 (Misdirection prompt), red at 90 (Feign Death prompt), deep red
--    on aggro. Most severe condition last. Group-gated: solo you ARE the threat
--    list, so it would sit pegged at 100%.
--    v10: THREAT HAS NO NATURAL VESSEL — you cannot fill a globe with it without inventing
--    a fourth container and a fourth patch of screen — so it becomes the TARGET GLOBE'S
--    RIM: the glass around your target is green, then orange, then red as your threat on
--    THAT target climbs, with the percentage above it. Same aura, same trigger, same
--    gates, same three tiers, and it costs no extra element and no extra space.
--    The property renames a second time: `barColor` on the v7 aurabar, `foregroundColor`
--    on the v8/v9 progresstexture, `color` on this texture (Texture.lua's properties
--    table). Every one of those renames is SILENT — Conditions.lua skips a change whose
--    property the region does not declare, without an error — so a mechanical port would
--    have shipped three dead escalations and a rim that never changed colour.
local threat = reg(rim("Hunter - Threat", G.tgtGlobe + RIM_PAD, COL.threat,
  F.triggers({ threatTrigger(nil) })))
threat.subRegions = { pct("threatpct", PCT_THREAT.size, PCT_THREAT.y, COL.thText) }
threat.conditions = {
  F.condition(1, "threatpct", ">=", "70", "color", { 1, 0.6, 0.1, 1 }),
  F.condition(1, "threatpct", ">=", "90", "color", { 0.95, 0.25, 0.1, 1 }),
  F.condition(1, "aggro", "==", 1, "color", { 0.9, 0.12, 0.12, 1 }),
  -- THE GUARD THIS READOUT CANNOT SHIP WITHOUT, and the globe migration does not retire
  -- it: threattotal is threatvalue * 100 / threatpct, so it is 0 whenever threatvalue is
  -- 0 — the instant after a Feign Death, and the instant before your first hit lands.
  -- threatpct is 0 there too, so with no guard the rim would sit GREEN, which reads as
  -- "you are fine" at the exact moment the readout exists to speak. Hide it instead and
  -- let the brass base rim below show through, which says nothing at all.
  F.condition(1, "threatvalue", "<=", "0", "alpha", 0),
}
threat.load.use_ingroup = true
threat.load.ingroup = { multi = { group = true, raid = true } }
threat.load.use_size = false   -- false = MULTI mode (nil would disable the gate)
threat.load.size = noArenaSize()

-- 6. threat >= 80% in a party/raid: a pulsing red halo just outside the target globe's
--    rim. Same trigger, same gates, same colour and same alphaPulse as v7's bar overlay —
--    only the shape changed, and in v10 only its size and art: it wears the same glass
--    border as the rims, one RIM_PAD further out, so a threat emergency looks like the
--    target's own glass catching fire rather than an unrelated ring appearing.
local flash = reg(F.texture("Hunter - Threat Flash", CLASS, G.flashHalo, G.flashHalo, 0, 0, nil,
  RIM_TEX, { 1, 0.1, 0.1, 0.85 }))
flash.blendMode = "ADD"
flash.triggers = F.triggers({ threatTrigger(80) })
flash.load.use_ingroup = true
flash.load.ingroup = { multi = { group = true, raid = true } }
flash.load.use_size = false
flash.load.size = noArenaSize()
flash.animation.main = F.animPreset("alphaPulse", "1")

-- ===== 7. Buffs: static row of aura timers =====
-- v10, and this is the ONE thing outside the globes that had to move. The canonical target
-- globe sits at an absolute (0, -150) and this row sat at an absolute (0, -156): the globe
-- would have been drawn straight through Serpent Sting and Hunter's Mark. The row is
-- re-anchored 96px up to an absolute (0, -60) — the band the player orb occupied until
-- this version, now empty — which also puts the two TARGET debuff timers directly above
-- the TARGET globe, where they belong. Only this group's yOffset changed: every icon in it
-- keeps its id, uid, trigger, load gate, condition, size and x offset.
--   The height is derived, not picked: the threat percentage above the target globe sits at
--   GLOBE_Y + PCT_THREAT.y = -98 and an 11pt line is ~13px tall, so its top edge is ~-91;
--   a 40px icon row centred at BUFF_Y = -60 hangs down to -80 and clears it by 11px.
local BUFF_Y = -60
local gBuffs = reg(F.group("Hunter - Buffs", 0, BUFF_Y - TOP_Y, nil))
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

-- 19-26. one recipe, two displays. WA cooldown text on and tooltip on hover for both.
--
-- v6: which display an icon gets is a CLASSIFICATION, made per ability against the raid
-- priority, not a blanket conversion (references/rotation-design.md, "Show what the player
-- CANNOT press").
--
--   rot = true  — a press-on-cooldown rotational button. Stays showAlways and carries the
--     gold ready-glow, because the glow IS the instruction and a hidden icon can never fire
--     one. Two states and no third: dim = still coming back, full colour + gold = press it.
--     Trigger 2 is the always-active state feeder that carries inCombat (disjunctive "all"
--     stays satisfied, and trigger 1 keeps driving the swipe), so out of combat the icon
--     fades and the glow is forced off — the row is still while you ride around.
--
--   rot = false — situational / utility / emergency / burst-window. genericShowOn becomes
--     showOnCooldown: the icon exists only while its cooldown runs, carrying the swipe and
--     the countdown, and disappears the moment the ability is back. The row is a dynamic
--     group, so the gap closes — ABSENCE IS THE READOUT. The desaturate goes with it: every
--     visible icon is on cooldown by definition, so greying them all would only make the
--     abilities harder to tell apart. (withActiveWindow below re-adds a desaturate to the
--     two burst icons, where it means something else entirely — see its comment.)
local GOLD = { 1, 0.82, 0.1, 1 }   -- this pack's "press it now" colour: Kill Command,
                                   -- the Misdirection prompt, SILENCE NOW — and now the row

local function addCD(name, spellId, gate, rot)
  local ic = reg(F.icon("Hunter CD - " .. name, CLASS, 32, 32, 0, 0, nil))
  ic.cooldownTextDisabled = false
  ic.useTooltip = true
  if rot then
    ic.triggers = F.triggers({ F.cdTrigger(spellId, name, "showAlways"), F.unitCharTrigger() })
    -- subRegions[1] is ALREADY a subglow — the icon prototype ships one with glow = false —
    -- so this REPLACES index 1 in place. Nothing shifts, and every sub.N condition in the
    -- pack keeps pointing at the subregion it was written for (the border stays index 2).
    ic.subRegions[1] = F.subglow(false, GOLD)
    -- LAST condition wins on a shared property: out of combat the icon dims and the ready
    -- glow is forced back off, so an idle hunter's row does not sit lit.
    local quiet = F.condition(2, "inCombat", "==", 0, "alpha", 0.5)
    quiet.changes[2] = { property = "sub.1.glow", value = false }
    ic.conditions = {
      F.condition(1, "onCooldown", "==", 1, "desaturate", true),
      F.condition(1, "onCooldown", "==", 0, "sub.1.glow", true),
      quiet,
    }
  else
    ic.triggers = F.triggers({ F.cdTrigger(spellId, name, "showOnCooldown") })
    ic.conditions = {}
  end
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
-- cooldown, joined with disjunctive "any". While the window is live the icon is lit and
-- full colour; afterwards it desaturates for the rest of the cooldown. This is what tells
-- you the haste/damage window is still running, which is the part of the button that
-- changes the next 15-18s.
--
-- v6: trigger 2 is now showOnCooldown, so the icon leaves the row while the button is
-- ready — absence means available here exactly like everywhere else in the row. The two
-- visible states are unchanged: buff up (trigger 1 active, glow on, full colour, swipe =
-- the window) and recharging (trigger 2 only, glow off, dim). That is why THIS desaturate
-- survives the v6 pass while the plain row icons lost theirs: it does not mean "on
-- cooldown", it means "the window is spent", and the later sub.1.glow condition overrides
-- it for as long as the window is live.
local function withActiveWindow(ic, unit, auraIds, glowColor)
  local cd = ic.triggers[1].trigger
  ic.triggers = F.triggers({ F.auraTrigger(unit, true, auraIds), cd }, { disjunctive = "any" })
  ic.subRegions[1] = F.subglow(false, glowColor)
  local lit = F.condition(1, "show", "==", 1, "sub.1.glow", true)
  lit.changes[2] = { property = "desaturate", value = false }
  ic.conditions = { F.condition(2, "onCooldown", "==", 1, "desaturate", true), lit }
  return ic
end

-- The 4th column is the v6 classification. Only Multi-Shot is a press-on-cooldown button
-- in this block: both raid guides say to press it on cooldown in place of a Steady Shot
-- because it is more damage per use than Steady Shot even on a single target.
local cdBWrath = addCD("Bestial Wrath", BWRATH,  BWRATH, false)  -- BM 31-pt; opener burst
addCD("Intimidation",  INTIMID, INTIMID, false)  -- BM; a 3s stun, pressed at a moment
addCD("Readiness",     READY,   READY,   false)  -- SV 41-pt; spent to re-arm the opener
addCD("Wyvern Sting",  WYVERN,  WYVERN,  false)  -- SV 31-pt; CC, no raid rotation slot
local cdRapid = addCD("Rapid Fire",    RAPID,   nil, false)  -- baseline lvl 26; burst window
local cdMulti = addCD("Multi-Shot",    MULTI,   nil, true)   -- baseline lvl 18; ROTATIONAL
-- Misdirection and Feign Death both already have a threat-paired prompt in the alert flow
-- (70% and 90%), and the alert owns the moment. The row icon only answers "when is it back".
addCD("Misdirection",  MISDIR,  MISDIR, false)  -- trained at 70
addCD("Feign Death",   FEIGN,   nil,    false)  -- baseline, lvl 30

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
--     v6: ROTATIONAL. It is a 6s instant inside the core damage loop — the weave slot's
--     other half when mana allows, and the shot you press on cooldown the moment you have
--     to move — so it gets the ready-glow rather than being hidden. This is the closest
--     call in the row (a mana-permitting filler is not Multi-Shot), and it goes the
--     showAlways way on the tie-break rule: anything in the core loop keeps its glow.
local arcane = addCD("Arcane Shot", ARCANE, nil, true)  -- baseline, 6s cd (r1 = 3044)

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
-- v6: both are CC openers held for a moment, never pressed on sight, so they are
-- situational like the rest of the row — showOnCooldown, and their PvP load gates are
-- untouched. In arena the row therefore reads "the trap is on cooldown for 22 more
-- seconds", and an empty row means the whole opener is available.
local cdTrap = addCD("Freezing Trap", FRZTRAP[1], nil, false)
cdTrap.load = pvpLoad(PVP_SIZE, { use_spellknown = true, spellknown = FRZTRAP[1] })
local cdScatter = addCD("Scatter Shot", SCATTER, nil, false)
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

-- ===== v8 clusters, rebuilt as v10 globes =====
-- Same append-only rule as v2, v4, v5 and v8. The SIX v8 uid() calls stay exactly where
-- they are and in exactly the order they were made — what each one BUILDS has changed, and
-- that is the point: a recycled uid updates the region the player already has instead of
-- orphaning it and installing a stranger beside it.
--   v8 order (unchanged):  player cluster group, player portrait, target cluster group,
--                          target health, target mana, target portrait
--   v10 meaning:           player globe group,   LIFE RIM,        target globe group,
--                          target globe,         target power globe, TARGET RIM
-- The two portraits are gone as REGIONS and survive as the two rims. Nothing is deleted, so
-- nobody ends up with a stray 46px model floating where their face used to be.
-- TWO genuinely new auras follow after them, at the very end, as new uid() calls.

-- 46. Player globes. A plain group, not a dynamic one: its children are placed by hand at
--     -300 and +300 rather than flowed.
local gPlayerOrb = reg(F.group("Hunter - Player Globes", 0, 0, nil))
adopt(gRes, gPlayerOrb)

-- 47. LIFE RIM — was the player portrait, and it inherits that aura's uid, its two triggers
--     and its out-of-combat fade verbatim. The glass is what makes the disc read as a
--     vessel rather than a coloured blob, and it fades with the liquid it wraps.
local pPortrait = reg(rim("Hunter - Life Rim", G.lifeGlobe + RIM_PAD, COL.rim,
  F.triggers({ F.healthTrigger(nil), F.unitCharTrigger() })))
pPortrait.xOffset = -G.globeX
pPortrait.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }

-- 48. Target globe group. Every element inside it self-hides with no target (the Health,
--     Power and Threat prototypes all end in a UnitExistsFixed test), so with nothing
--     selected the centre of the screen is genuinely empty.
local gTargetOrb = reg(F.group("Hunter - Target Globe", 0, 0, nil))
adopt(gRes, gTargetOrb)

-- 49. Target health — the kill-window read (execute range, swap decisions, and whether the
--     pull is going anywhere). No combat fade: you only have a target when you mean to.
--     v10: the small centre vessel, life-red like your own because it is the same quantity,
--     with its percentage inside the glass at the smaller PCT_TGT size.
local tHealth = reg(globe("Hunter - Target Health", G.tgtGlobe, COL.life,
  F.triggers({ unitHealth("target") })))
tHealth.subRegions[1] = pct("percenthealth", PCT_TGT.size, PCT_TGT.y, COL.hpText)
tHealth.conditions = { F.condition(1, "maxhealth", "<=", "0", "alpha", 0) }

-- 50. Target mana — deliberately a SHAPE and not a number. Rogues, warriors and every
--     powerless mob produce no state at all (use_requirePowerType), so a vessel here means
--     "this one casts, and here is how much it has left" — the Viper Sting / Silencing
--     Shot read in the open world, where the arena-only Enemy Mana bars do not load. The
--     percentage is still left off on purpose: it is a glance, not a readout.
--     It is half the target globe and sits to its RIGHT, because power is to the right of
--     life everywhere else on this HUD.
local tMana = reg(globe("Hunter - Target Mana", G.tgtPower, COL.mana,
  F.triggers({ unitMana("target") })))
tMana.xOffset = G.tgtPowerX
tMana.conditions = { F.condition(1, "maxpower", "<=", "1", "alpha", 0) }

-- 51. TARGET RIM — was the target portrait, and it keeps that aura's uid and its trigger
--     unchanged, so it appears and vanishes with the target exactly as the face did.
--     This is the BASE rim: brass, always present when you have a target. The threat rim
--     above is drawn over it and takes it over whenever threat is live, which is what lets
--     threat own the glass without leaving the globe naked while solo, in an arena, or in
--     the instant after a Feign Death when the threat readout hides itself.
local tPortrait = reg(rim("Hunter - Target Rim", G.tgtGlobe + RIM_PAD, COL.rim,
  F.triggers({ unitHealth("target") })))

-- ===== v10 additions: the two rims with no ancestor =====
-- The player's power globe and the target's power globe never had a portrait to recycle, so
-- these are the only genuinely NEW auras in v10 and both uid() calls are appended here,
-- after every existing one, exactly as v2/v4/v5/v8 did.

-- 52. POWER RIM — the same glass as the life rim, on the right-hand vessel. Its triggers
--     mirror the power globe's (power + the always-on characteristics feeder) so it fades
--     out of combat with it.
local powerRim = reg(rim("Hunter - Power Rim", G.powerGlobe + RIM_PAD, COL.rim,
  F.triggers({ F.powerTrigger(0), F.unitCharTrigger() })))
powerRim.xOffset = G.globeX
powerRim.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }

-- 53. TARGET POWER RIM — the small glass, carrying the same mana trigger as the vessel it
--     wraps, so on a rogue or a boar there is no empty hoop left behind.
local tPowerRim = reg(rim("Hunter - Target Power Rim", G.tgtPower + RIM_PAD, COL.rim,
  F.triggers({ unitMana("target") })))
tPowerRim.xOffset = G.tgtPowerX

-- Sibling stacking is exact, not "roughly creation order": FixGroupChildrenOrder walks
-- controlledChildren and adds +4 frame levels per child, so EARLIER = further behind.
-- Liquid first, glass over it, and the threat rim LAST of all so it takes the target's
-- glass from the brass base rim whenever there is threat to report.
adopt(gPlayerOrb, hp)
adopt(gPlayerOrb, pPortrait)
adopt(gPlayerOrb, mana)
adopt(gPlayerOrb, powerRim)

adopt(gTargetOrb, flash)
adopt(gTargetOrb, tHealth)
adopt(gTargetOrb, tMana)
adopt(gTargetOrb, tPortrait)
adopt(gTargetOrb, tPowerRim)
adopt(gTargetOrb, threat)

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

-- ===== ABSOLUTE POSITION PROOF =====
-- GLOBE_X / GLOBE_Y are ABSOLUTE screen offsets, and every globe here is nested two groups
-- deep under a top group that carries its own -140. Applying the canon numbers LOCALLY is
-- the exact mistake that put seven packs' orbs at seven different heights, so the build
-- refuses to write a string whose globes do not land where the canon says. It walks each
-- region's parent chain and sums every xOffset/yOffset, which is what WeakAuras does when
-- it anchors a child to its group.
local nodes = { [top.id] = top }
for id, t in pairs(byId) do nodes[id] = t end
local function absolutePos(a)
  local x, y, node = 0, 0, a
  while node do
    x, y = x + (node.xOffset or 0), y + (node.yOffset or 0)
    node = node.parent and nodes[node.parent] or nil
  end
  return x, y
end
local EXPECT = {
  { hp,         -GLOBE_X,       GLOBE_Y, "life globe" },
  { pPortrait,  -GLOBE_X,       GLOBE_Y, "life rim" },
  { mana,        GLOBE_X,       GLOBE_Y, "power globe" },
  { powerRim,    GLOBE_X,       GLOBE_Y, "power rim" },
  { tHealth,     0,             GLOBE_Y, "target globe" },
  { tPortrait,   0,             GLOBE_Y, "target rim" },
  { threat,      0,             GLOBE_Y, "threat rim" },
  { flash,       0,             GLOBE_Y, "threat halo" },
  { tMana,       G.tgtPowerX,   GLOBE_Y, "target power globe" },
  { tPowerRim,   G.tgtPowerX,   GLOBE_Y, "target power rim" },
}
for _, e in ipairs(EXPECT) do
  local region, wantX, wantY, label = e[1], e[2], e[3], e[4]
  local gotX, gotY = absolutePos(region)
  assert(gotX == wantX and gotY == wantY,
    ("%s (%s) lands at absolute (%d,%d), canon says (%d,%d)")
      :format(label, region.id, gotX, gotY, wantX, wantY))
end

-- ===== assemble (v2000 nested), encode, verify, write =====
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

local txtPath = dir .. "/all-specs.txt"
-- uid continuity vs the PREVIOUS version's string, read before it is overwritten
local cont = W.uidContinuity(encoded, txtPath)
W.assertUidContinuity(cont, "hunter")

local out = io.open(txtPath, "w")
out:write(encoded)
out:close()

print(("OK: %d auras (top + %d children), %d chars -> all-specs.txt")
  :format(#transmit.c + 1, #transmit.c, #encoded))
if cont then
  print(("uid continuity vs previous: stable=%d changed=%d missing=%d parentSame=%s")
    :format(cont.stable, cont.changed, cont.missing, tostring(cont.parentSame)))
end
for _, e in ipairs(EXPECT) do
  local x, y = absolutePos(e[1])
  print(("  %-19s %-26s absolute (%+d,%+d)"):format(e[4], e[1].id, x, y))
end
