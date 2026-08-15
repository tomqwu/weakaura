-- generate.lua — Druid TBC Bear / Restoration / Balance HUD (v9).
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
--
-- v6 (the cooldown row shows what you CANNOT press) — see README "## v6 — the cooldown row
-- shows what you cannot press". NO new auras, NO removed auras, NO reordering, so every uid is
-- byte-identical to v5 and the import dialog still offers Update. Seven of the eight cooldown
-- icons are situational (Enrage, Frenzied Regen, Swiftmend, Nature's Swiftness, Force of
-- Nature, Barkskin, Innervate) and become genericShowOn = "showOnCooldown" with their
-- now-meaningless desaturate condition dropped; absence in the dynamic group is the readout.
-- Mangle (Bear) is the one press-on-cooldown rotational button in the row, so it keeps
-- showAlways + desaturate + its ready-glow, and gains a Unit Characteristics trigger purely so
-- that glow can be silenced out of combat. See the classification table above addCD().
--
-- v7 (Cat no longer receives the Bear HUD) — the Mangle talent teaches both Bear and Cat
-- versions, so spellknown alone cannot distinguish the forms. Every Bear-only element now
-- ANDs its existing state with the verified Stance/Form/Aura trigger for form 1. No aura or
-- uid was added, removed or reordered; Cat keeps the shared/PvP layer and Bear behavior is
-- unchanged while actually in Bear/Dire Bear Form.
--
-- v8 (unit orbs) — see README "## v8 — the centre of the screen is now empty". The centre
-- bar stack is gone. Health, primary power and threat are drawn as concentric RINGS around a
-- live unit portrait, in two clusters flanking the character: player at x=-250, target at
-- x=+250. The target cluster self-hides completely when there is no target, because the
-- Health/Power prototypes' hidden UnitExistsFixed test produces no state for an absent unit.
--
-- UID DISCIPLINE FOR v8, and it is the reason this version is shaped the way it is.
-- W.assertUidContinuity fails the build if ANY previously shipped uid disappears (a deleted
-- aura's uid is gone forever and the in-game Update flow cannot reconcile it). So the eleven
-- v7 Resources tables are REPURPOSED IN PLACE rather than deleted and re-created: each
-- constructor below still draws the same uid at the same position in the seeded stream, and
-- only the region type, id, geometry and triggers change. WeakAuras matches auras across
-- imports by uid, so in game each old bar becomes its replacement ring on Update and nothing
-- is orphaned. Only the two portraits are genuinely new, and they draw their uids in the v8
-- block at the very BOTTOM of this file, after every pre-existing uid() call.
--   uid slot (v7 element)        -> v8 element
--   2   Druid - Resources        -> Druid - Unit Orbs           (group, retyped position)
--   6   Druid - Health           -> Druid - Player Health       (ring)
--   7   Druid - Rage             -> Druid - Player Power        (ring, form-adaptive)
--   8   Druid - Mana (Resto)     -> Druid - Target Health       (ring)
--   9   Druid - Mana (Balance)   -> Druid - Target Mana         (ring)
--   10  Druid - Threat (Bear)    -> Druid - Threat (Bear)       (ring, id unchanged)
--   11  Druid - Threat (Caster)  -> Druid - Threat (Caster)     (ring, id unchanged)
--   33-36 Rage Line x4           -> Rage Tick x4                (pips on the power ring)
--   new x2                       -> Druid - Player/Target Portrait
--
-- THREE FIELD-NAME TRAPS THIS VERSION HAD TO CLEAR, all of them silent no-ops if missed:
--   * `barColor` is an AURABAR property and does not exist on progresstexture. Conditions.lua
--     skips a change whose property is absent from the region's properties table, with no
--     error and no editor warning, so a mechanical port of the threat escalation would have
--     produced a dead condition. The progresstexture spelling is `foregroundColor`.
--   * a progresstexture with `total == 0` draws FULL (ProgressTexture.lua `local progress = 1`
--     before the `if self.total > 0` guard), where an aurabar with total 0 draws EMPTY. Threat
--     reaches total 0 whenever threatvalue is 0 — post-Vanish, pre-first-hit — so every threat
--     ring carries `threatvalue <= 0 -> alpha 0`, and every health ring `maxhealth <= 0 ->
--     alpha 0`. Power is the one safe case: its total is math.max(1, UnitPowerMax(...)).
--   * current code reads a model region's unit from `model_fileId`; WA 3.5.0 read
--     `model_path`, and the Modernize block that bridges them is gated on IsClassicEra(),
--     which is NOT IsTBC(), so on 2.5.x it does not run. Both are emitted.
--
-- v9 (one orb size across every pack) — see README "## v9 — the orbs are one shared size".
-- PURELY geometry and the ring art. No trigger, load gate, condition, colour, spell id or
-- region type changed; NO aura added, removed or reordered, so every uid is byte-identical
-- to v8 and the import dialog still offers Update. Each of the seven class packs had drifted
-- to its own orb diameters and the two clusters inside a pack disagreed with each other, so
-- the HUD read as uneven. Every pack now takes the SAME canonical numbers, declared once in
-- the ORB block below and referenced everywhere:
--   * outer diameter 104 on BOTH clusters. Player: health 104, power 78. Target: threat 104,
--     health 78, mana 54 — the target simply nests one more ring inside the same footprint.
--     Druid's TWO threat rings (Bear and Caster, mutually exclusive load gates) are both 104.
--   * portrait 46 on both sides (was 28 — a face too small to recognise).
--   * clusters at x = +-260, y = -60.
--   * Ring_20px.tga replaces Ring_10px.tga. At 104 px the 10 px art draws a 4 px band, which
--     read as a wire rather than an arc; the 20 px art draws 8 px at the same diameter.
--   * the number sizes/offsets are shared too: health 14 at y -60, power 11 at -76, threat
--     11 at +60, so the two clusters label themselves identically.
-- THE TRAP THIS VERSION HAD TO CLEAR: the four bear rage pips are separate texture regions
-- positioned by TRIGONOMETRY on the power ring's stroke, so growing that ring 64 -> 78 would
-- have left them floating inside it. tickR is now DERIVED from ORB_MID and the Ring_20px
-- stroke weight (see G.tickR) instead of being a literal, and it re-derives automatically if
-- the canonical numbers ever move again.

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
local TOP = "Druid TBC - Bear, Restoration & Balance"

-- ===== CANONICAL ORB GEOMETRY (v9) — SHARED BY ALL SEVEN CLASS PACKS =====
-- These seven numbers are the contract. They are identical in every tbc/*/generate.lua and
-- MUST NOT be edited in one pack alone: the whole point of v9 is that the player cluster, the
-- target cluster and all seven classes present the same footprint. Derive from them, never
-- hand-write a diameter or a cluster offset anywhere below.
--
-- RING ASSIGNMENT — this is what makes the two sides match:
--   PLAYER cluster: health = ORB_OUTER, primary power = ORB_MID, portrait = PORTRAIT
--   TARGET cluster: threat = ORB_OUTER, health = ORB_MID, mana = ORB_INNER, portrait = PORTRAIT
-- Both clusters therefore show the SAME outer diameter and the SAME portrait; the target just
-- nests one more ring inside. Druid has two threat rings (Bear and Caster) and BOTH are
-- ORB_OUTER — their load gates are mutually exclusive, so only one is ever on screen.
local RING_TEX  = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Ring_20px.tga"
local ORB_OUTER = 104   -- outermost ring, on BOTH clusters, in EVERY pack
local ORB_MID   = 78
local ORB_INNER = 54
local PORTRAIT  = 46
local CLUSTER_X = 260   -- player cluster at -260, target cluster at +260
local CLUSTER_Y = -60

-- Number placement, also shared: health under the outer ring, power under that, threat above.
-- Anchored CENTER on the ring that owns them, so each number appears and vanishes with its arc.
local PCT_MAIN   = { size = 14, y = -60 }  -- health
local PCT_SUB    = { size = 11, y = -76 }  -- power / mana
local PCT_THREAT = { size = 11, y =  60 }  -- threat, above the ring

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
-- NOT_FERAL keeps caster-only buttons hidden from both supported Bear builds and unsupported
-- Cat builds. Mangle (Cat) is a different spell NAME (33876), so name resolution is
-- unambiguous. The v7 Bear-vs-Cat distinction is enforced separately by the form trigger.
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
-- uid slot 2. v7 called this "Druid - Resources" at (0,56) and parked a 172x14 bar stack in
-- the middle of the screen. Same table, same uid: it is now the orb layer, and it sits lower
-- (screen y = -140+30 = -110) so the two clusters occupy the band the bars used to.
local gRes    = reg(F.group("Druid - Unit Orbs", 0, 30, nil))
local gBuffs  = reg(F.group("Druid - Buffs", 0, -16, nil))
local gAlerts = reg(F.dynGroup("Druid - Alerts", -150, 96, nil, "UP", "BOTTOM", 6))
local gCDs    = reg(F.dynGroup("Druid - Cooldowns", 0, -66, nil, "HORIZONTAL", "CENTER", 4))
adopt(top, gRes)
adopt(top, gBuffs)
adopt(top, gAlerts)
adopt(top, gCDs)

-- ================= v8 Unit orbs — state drawn AT the unit, centre freed =================
-- Two clusters flanking the character: player at x=-260, target at x=+260, inside the group
-- that used to hold the centre bar stack. Each cluster is a live 3D portrait with concentric
-- progresstexture rings around it; the target cluster also carries the threat ring, because
-- threat is YOUR threat ON THAT TARGET and that is where it belongs.
--
-- v9: every diameter below is now DERIVED from the canonical constants at the top of the file
-- rather than written here, which is what stops the seven packs drifting apart again. |x| is
-- CLUSTER_X = 260 and still clears this pack's own furniture: the Alerts column sits at x=-150
-- and the PvP column at x=+150 (icons up to 40 wide, so |x| <= 170), and the widest orb is now
-- ORB_OUTER = 104, so the cluster's inner edge is at 260 - 52 = 208. Nothing overlaps, and the
-- entire middle of the screen — where v7 parked a 172px bar stack — is still empty.
--
-- G.tickR is the ONE derived number that is not simply a canonical constant, and it exists
-- because the four bear rage pips are positioned by trigonometry on the player POWER ring.
-- Both bundled ring textures are 256x256 and the number in the file name is the stroke weight
-- in THAT space, so a ring drawn at S px carries a band of S*20/256 hugging the OUTER edge of
-- the region box (crop 0.41 is the identity crop, so the art exactly fills the box). The
-- middle of that band therefore sits at S/2 - S*10/256 = S/2 * (1 - 20/256). At ORB_MID = 78
-- that is 35.95, where v8's literal 30 was the same calculation for a 64 px ring with the
-- 10 px art. Change ORB_MID and the pips follow it; see rageTick() in the v2 block.
local RING_STROKE = 20 / 256  -- Ring_20px band weight, as a fraction of the drawn diameter
local G = {
  orbX     = CLUSTER_X,   -- player at -X, target at +X
  orbY     = CLUSTER_Y,
  hpRing   = ORB_OUTER,   -- player cluster, outermost: health
  pwRing   = ORB_MID,     -- player cluster, inside it: primary power (form-adaptive)
  tHpRing  = ORB_MID,     -- target cluster, inside the threat ring: health
  tMpRing  = ORB_INNER,   -- target cluster, innermost: mana
  thRing   = ORB_OUTER,   -- target cluster, outermost: threat (Bear and Caster both)
  portrait = PORTRAIT,    -- the live unit model in the middle of each cluster
  tickR    = ORB_MID / 2 * (1 - RING_STROKE),  -- bear rage pips, on the power-ring stroke
}

local COL = {
  health = { 0.15, 0.78, 0.25, 1 },  -- v7's health-bar green
  mana   = { 0.25, 0.50, 0.90, 1 },  -- v7's mana-bar blue
  rage   = { 0.85, 0.15, 0.15, 1 },  -- v7's rage-bar red
  energy = { 1.00, 0.85, 0.20, 1 },  -- cat, which v7 never drew at all
  threat = { 0.25, 0.80, 0.30, 1 },  -- v7's threat-bar green
  warn   = { 1.00, 0.60, 0.10, 1 },  -- threat >= 70%
  hurt   = { 1.00, 0.65, 0.10, 1 },  -- health < 50%
  danger = { 0.90, 0.12, 0.12, 1 },  -- aggro lost / gained, health < 25%
  track  = { 0, 0, 0, 0.55 },        -- the unfilled arc behind every ring
  text   = { 1, 1, 1, 1 },
  ptext  = { 0.72, 0.82, 1, 1 },     -- power numbers, tinted so they never need a label
}

-- Ring_20px.tga is a true annulus and ships inside WeakAuras (Private.texture_types,
-- "Shapes"). Circle_Smooth2.tga — the texture the rest of this pack uses — is a SOLID DISC
-- and would fill as a pie wedge, not a ring.
-- v9 swaps Ring_10px for Ring_20px: the stroke is a fraction of the DRAWN size (S*N/256), so
-- the 10 px art at these diameters resolved to a 3-4 px hairline that read as a wire instead
-- of an arc. Same file family, same annulus geometry, twice the band.
local RING = RING_TEX
local IV, TOC = 45, 20501

-- wa_factory has no progresstexture or model builder, so those two region tables are written
-- out in full below and need the same scaffolding stub() applies inside the factory.
local function stub(t)
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

local function orbTrigger(t)
  t.names, t.spellIds = {}, {}
  t.subeventPrefix, t.subeventSuffix = "SPELL", "_CAST_START"
  t.debuffType = "HELPFUL"
  return t
end

-- Health on an arbitrary unit. F.healthTrigger is hardwired to "player"; the target cluster
-- needs "target". The prototype ends in a hidden always-on test,
--   WeakAuras.UnitExistsFixed(unit, smart) and specificUnitCheck
-- so unit = "target" with no target produces NO STATE and every region carrying this trigger
-- hides. That is the whole self-hide mechanism for the target cluster: no condition, no load
-- gate, no custom code.
local function orbHealth(unit)
  return orbTrigger{ type = "unit", event = "Health", unit = unit, use_unit = true }
end

-- FORM-ADAPTIVE power, and this is the single biggest behavioural win of v8. Omitting
-- use_powertype makes the prototype emit `local powerType = nil`, so powerTypeToCheck falls
-- back to UnitPowerType(unit) and UnitPower(unit, nil) reads whatever bar the unit is
-- currently showing. The trigger re-fires on shapeshift because events() registers
-- UNIT_DISPLAYPOWER unconditionally. One ring therefore follows a druid caster -> bear ->
-- cat with no gate and no second aura, where v7 needed three mutually exclusive bars and
-- still showed a feral nothing at all outside Bear form.
local function orbPower(unit)
  return orbTrigger{ type = "unit", event = "Power", unit = unit, use_unit = true }
end

-- PINNED mana, for the target ring only. Both flags are load-bearing:
--   use_powertype + powertype = 0 -> read MANA specifically, never "whatever bar this unit
--     happens to show", so a warrior target cannot render rage in a blue mana ring.
--   use_requirePowerType          -> the ring only exists while mana is that unit's PRIMARY
--     bar, so a rogue or warrior target produces no state at all instead of a permanently
--     empty blue circle. It is gated on use_powertype (enable = trigger.use_powertype), so
--     it is inert without it — which is also why the adaptive player ring above cannot use it.
local function orbMana(unit)
  return orbTrigger{
    type = "unit", event = "Power", unit = unit, use_unit = true,
    use_powertype = true, powertype = 0,
    use_requirePowerType = true,
  }
end

-- The Threat Situation prototype's unit argument is named `unit` (Prototypes.lua, required,
-- init = "arg", default "target"). F.threatTrigger emits `threatUnit`, which is DEAD DATA —
-- no such arg exists — and the shipped packs only aim at the target by accident, because the
-- prototype's init does `trigger.unit = trigger.unit or "target"` and ConstructFunction runs
-- before events()/loadFunc read it. Setting the real field here makes the intent explicit and
-- lets loadFunc's AddWatchedUnits("target") fire regardless of call order. The factory itself
-- is not touched: changing it would rewrite five other packs' strings in one commit.
local function orbThreat()
  local tr = F.threatTrigger()
  tr.unit = "target"
  return tr
end

-- Radial progress ring. The fields that are traps, in the order they bite:
--   orientation CLOCKWISE  -> the only radial values are CLOCKWISE / ANTICLOCKWISE; every
--     other key in orientation_with_circle_types is linear.
--   startAngle 0 / endAngle 360 -> a full circle; WA normalises 0/360 and corrects endAngle
--     back up by 360, so this is handled rather than degenerate.
--   crop_x / crop_y = 0.41 -> the IDENTITY value, NOT "no crop". The circular path expands
--     the texture by sqrt(2) so rotated quadrants never run off it; 1 + 0.41 cancels that
--     exactly. Setting 0 blows the ring up 1.41x and clips it.
--   auraRotation = 0 -> absent from the 3.5.0 default table but read unconditionally by
--     current code as data.auraRotation / 180 * math.pi, so it must be emitted.
--   backgroundOffset = 0 -> the default 2 fattens the track into a halo instead of a track.
--   adjustedMin/Max are STRINGS, because SetAdjustedMin does adjustedMin:find(...).
--   progressSource is rewritten to {-1, ""} (Automatic) by Modernize < 71 whatever is
--     emitted, which is why each ring has exactly ONE progress-supplying trigger and it is
--     trigger 1: activeTriggerMode -10 is first_active, and Automatic reads that trigger's
--     value/total. A second trigger can only feed conditions, never the fill.
local function ring(id, size, x, color, triggerList, gate)
  return reg(stub{
    regionType = "progresstexture", id = id, uid = W.uid(), parent = nil,
    width = size, height = size,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = x, yOffset = G.orbY, frameStrata = 1, alpha = 1,
    orientation = "CLOCKWISE", startAngle = 0, endAngle = 360,
    inverse = false, mirror = false,
    compress = false, slanted = false, slant = 0, slantFirst = false, slantMode = "INSIDE",
    foregroundTexture = RING, backgroundTexture = RING, sameTexture = true,
    desaturateForeground = false, desaturateBackground = false,
    foregroundColor = color, backgroundColor = COL.track,
    backgroundOffset = 0,
    blendMode = "BLEND", textureWrapMode = "CLAMPTOBLACKADDITIVE",
    crop_x = 0.41, crop_y = 0.41, rotation = 0, auraRotation = 0,
    user_x = 0, user_y = 0,
    progressSource = { -1, "" },
    useAdjustededMin = false, useAdjustededMax = false,
    adjustedMin = "", adjustedMax = "",
    smoothProgress = true, overlayclip = false, overlays = {},
    subRegions = {},
    triggers = F.triggers(triggerList),
    load = F.load(CLASS, gate),
  })
end

-- Live unit portrait — a real 3D model of whoever is targeted, which is what lets the target
-- side work without ever knowing the target's class, and renders NPCs and mobs too.
--   modelIsUnit + model_fileId = "<unit>" -> PlayerModel:SetUnit(unit)
--   portraitZoom = true                   -> SetPortraitZoom(1), Blizzard head framing
-- model_fileId is the field current code reads; model_path is the 3.5.0 spelling and is
-- emitted only because the Modernize bridge between them never runs on a 2.5.x client.
-- The portrait carries the same Health trigger as its rings, so it self-hides with them.
local function portrait(id, unit, x)
  return reg(stub{
    regionType = "model", id = id, uid = W.uid(), parent = nil,
    model_fileId = unit, model_path = unit, modelIsUnit = true, modelDisplayInfo = false,
    portraitZoom = true, api = false,
    model_x = 0, model_y = 0, model_z = 0,
    model_st_tx = 0, model_st_ty = 0, model_st_tz = 0,
    model_st_rx = 270, model_st_ry = 0, model_st_rz = 0, model_st_us = 40,
    sequence = 1, advance = false, rotation = 0,
    width = G.portrait, height = G.portrait, alpha = 1,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = x, yOffset = G.orbY, frameStrata = 1,
    border = false, borderColor = { 1, 1, 1, 0.5 }, backdropColor = { 1, 1, 1, 0.5 },
    borderEdge = "None", borderOffset = 5, borderInset = 11,
    borderSize = 16, borderBackdrop = "Blizzard Tooltip",
    subRegions = {},
    triggers = F.triggers({ orbHealth(unit) }),
    load = F.load(CLASS),
  })
end

-- The numbers sit OUTSIDE the rings, because the middle is occupied by the portrait and a
-- `model` region cannot carry a text sub-region at all (SubText's supports() lists texture /
-- progresstexture / icon / aurabar / empty — not model). Each number therefore rides on its
-- own ring and appears and disappears with it: no target, no numbers; no mana pool, no mana
-- number; no threat table, no threat number.
-- v9: the size/offset pair is no longer passed per call site — it comes from one of the three
-- canonical placements (PCT_MAIN / PCT_SUB / PCT_THREAT) declared at the top of the file, so
-- the player's health number and the target's health number cannot drift apart again.
local function pct(sym, place, color)
  local st = F.subtext("%" .. sym .. "%%", place.size, "CENTER", sym)
  st.anchorYOffset = place.y
  st.text_color = color
  return st
end

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

-- ===== the six rings, in the v7 uid order they inherit =====
-- CONSTRUCTION order below is uid order and must not change. DISPLAY order is set separately
-- by the adopt() calls at the end of this section: FixGroupChildrenOrder walks
-- controlledChildren and adds +4 frame levels per child, so EARLIER = further behind.

-- uid 6 (v7 "Druid - Health"). Outer ring, player cluster. Trigger 2 is the always-on Unit
-- Characteristics feeder that v7's bars used for the out-of-combat fade; it never gates
-- visibility and trigger 1 stays the progress source.
-- v8 ADDS a low-health escalation the flat green bar never had: amber under 50%, red under
-- 25%. `foregroundColor` is the progresstexture spelling of what an aurabar calls `barColor`.
-- The last condition is the zero-total guard: an aurabar with total 0 draws EMPTY but a
-- progresstexture draws FULL, and UnitHealthMax has no floor, so a target whose max health
-- has not streamed yet would flash a full green circle.
local playerHP = ring("Druid - Player Health", G.hpRing, -G.orbX, COL.health,
  { orbHealth("player"), F.unitCharTrigger() })
playerHP.subRegions[1] = pct("percenthealth", PCT_MAIN, COL.text)
playerHP.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "percenthealth", "<", "50", "foregroundColor", COL.hurt),
  F.condition(1, "percenthealth", "<", "25", "foregroundColor", COL.danger),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

-- uid 7 (v7 "Druid - Rage"). Inner ring, player cluster — and it now replaces all THREE of
-- v7's mutually exclusive power bars. The trigger is form-adaptive, and the resolved type is
-- a stored, conditionable arg (`powertype`, init = powerTypeToCheck, conditionType select),
-- so the ring recolours itself: mana blue is the base, rage red in bear, energy amber in cat.
-- Numeric select values compile correctly — Conditions.lua takes the tonumber branch.
-- No load gate at all: every druid has a primary resource in every form. v7's rage bar was
-- Feral-gated and Bear-form-gated, so a feral in caster form saw no resource bar whatsoever.
local playerPower = ring("Druid - Player Power", G.pwRing, -G.orbX, COL.mana,
  { orbPower("player"), F.unitCharTrigger() })
playerPower.subRegions[1] = pct("percentpower", PCT_SUB, COL.ptext)
playerPower.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "powertype", "==", 1, "foregroundColor", COL.rage),
  F.condition(1, "powertype", "==", 3, "foregroundColor", COL.energy),
  F.condition(1, "maxpower", "<=", "1", "alpha", 0),
}

-- uid 8 (v7 "Druid - Mana (Resto)"). MIDDLE ring of the target cluster, nested inside the
-- threat ring that owns the outer slot on this side — the mirror of the player's health, which
-- IS the outer ring because the player has no threat arc. New capability: v7 drew no target
-- state at all.
local targetHP = ring("Druid - Target Health", G.tHpRing, G.orbX, COL.health,
  { orbHealth("target"), F.unitCharTrigger() })
targetHP.subRegions[1] = pct("percenthealth", PCT_MAIN, COL.text)
targetHP.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

-- uid 9 (v7 "Druid - Mana (Balance)"). INNERMOST ring, target cluster: the healing target's mana
-- for a resto druid, the caster target's mana in PvP. The maxpower guard catches the last
-- honest gap in requirePowerType — most NPCs report mana as their primary bar with a 0/0
-- pool, and the prototype's total = math.max(1, UnitPowerMax(...)) floor turns that into a
-- valid 0% state. A real caster has maxpower in the thousands; a powerless unit has exactly
-- 1, which is why the guard is `<= 1` and not `<= 0`.
local targetMana = ring("Druid - Target Mana", G.tMpRing, G.orbX, COL.mana,
  { orbMana("target"), F.unitCharTrigger() })
targetMana.subRegions[1] = pct("percentpower", PCT_SUB, COL.ptext)
targetMana.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxpower", "<=", "1", "alpha", 0),
}

-- uid 10 — Threat (Bear), id unchanged from v7. Outermost ring on the TARGET cluster, because
-- threat is your threat on that unit. The Threat Situation prototype is progressType "static"
-- and stores value = threatvalue, total = threatvalue*100/threatpct, so value/total is
-- exactly threatpct/100: the ring fills 0..100% of the pull threshold with no extra wiring.
-- Tank-inverted semantics preserved from v7: green while you are securely tanking, RED the
-- moment aggro is lost. `barColor` -> `foregroundColor` is the whole port.
-- The threatvalue guard is NOT cosmetic. threattotal is (threatvalue or 0) * 100 / threatpct,
-- so total is 0 whenever threatvalue is 0 — post-Vanish, post-Feign, the instant before your
-- first hit lands — and a progresstexture with total 0 draws a FULL ring while threatpct 0
-- keeps the colour green. Shape and colour would contradict each other at exactly the wrong
-- moment. alpha 0 removes the ring instead, matching what v7's aurabar did by accident.
local threatF = ring("Druid - Threat (Bear)", G.thRing, G.orbX, COL.threat,
  { orbThreat() }, notInArena(GATE_F))
threatF.subRegions[1] = pct("threatpct", PCT_THREAT, COL.text)
threatF.conditions = {
  F.condition(1, "aggro", "==", 0, "foregroundColor", COL.danger),
  F.condition(1, "threatvalue", "<=", "0", "alpha", 0),
}

-- uid 11 — Threat (Caster), id unchanged from v7. Same ring, non-inverted semantics: green,
-- orange at 70% of the pull threshold, red when you pull (severe condition last, so it wins).
local threatB = ring("Druid - Threat (Caster)", G.thRing, G.orbX, COL.threat,
  { orbThreat() }, notInArena(GATE_B))
threatB.subRegions[1] = pct("threatpct", PCT_THREAT, COL.text)
threatB.conditions = {
  F.condition(1, "threatpct", ">=", "70", "foregroundColor", COL.warn),
  F.condition(1, "aggro", "==", 1, "foregroundColor", COL.danger),
  F.condition(1, "threatvalue", "<=", "0", "alpha", 0),
}

-- DISPLAY order: threat rings furthest back, then the health rings, then the power rings.
-- The four rage pips are adopted in the v2 block below and the two portraits in the v8 block
-- at the bottom, so both end up in front of every ring — which is what keeps a pip readable
-- and stops anything drawing over a face.
adopt(gRes, threatF)
adopt(gRes, threatB)
adopt(gRes, playerHP)
adopt(gRes, targetHP)
adopt(gRes, playerPower)
adopt(gRes, targetMana)

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

-- ================= Cooldowns (0,-66): 32x32 row, shows what you CANNOT press ============
-- v6 splits this row in two (see README "## v6 — the cooldown row shows what you cannot press"):
--
--   * SITUATIONAL cooldowns (`rotational` false) are genericShowOn = "showOnCooldown". The
--     icon exists only while its cooldown runs, carrying the swipe and the countdown, and
--     disappears the instant the ability is back. The row is a dynamic group, so the gap
--     closes and ABSENCE IS THE READOUT: an empty row means everything is up. Their
--     desaturate-while-down condition goes with the change — under showOnCooldown every
--     visible icon is on cooldown by definition, so desaturating them all would grey the whole
--     row and make the icons harder to tell apart.
--   * PRESS-ON-COOLDOWN ROTATIONAL buttons (`rotational` true) stay showAlways and keep both
--     the desaturate readout and a ready-glow. A hidden icon cannot announce the moment it
--     comes up, and hiding the button you press most often is exactly the wrong direction.
local function addCD(label, realName, spellId, gate, rotational)
  local ic = reg(F.icon("Druid CD - " .. label, CLASS, 32, 32, 0, 0, nil))
  ic.zoom = 0.3
  if rotational then
    -- trigger 2 is the always-active Unit Characteristics state feeder: with disjunctive
    -- "all" it never gates visibility (and activeTriggerMode -10 keeps trigger 1 driving the
    -- icon and swipe), it exists only so the ready-glow can be silenced out of combat.
    ic.triggers = F.triggers({ F.cdTrigger(spellId, realName, "showAlways"), F.unitCharTrigger() })
    ic.conditions = { F.condition(1, "onCooldown", "==", 1, "desaturate", true) }
  else
    ic.triggers = F.triggers({ F.cdTrigger(spellId, realName, "showOnCooldown") })
    ic.conditions = {}
  end
  ic.cooldownTextDisabled = false   -- WA prints the CD number; no %p subtext (OmniCC)
  ic.useTooltip = true
  ic.load = F.load(CLASS, gate)
  ic.subRegions[2] = F.subborder()
  adopt(gCDs, ic)
  return ic
end

-- The classification, ability by ability (TBC 2.4.3 rotations, re-checked on icy-veins.com/
-- tbc-classic and wowhead.com/tbc for v6):
--   C1 Mangle (Bear)  ROTATIONAL. 6s cooldown, "use Mangle whenever available" is the bear's
--                     #2 priority and every Lacerate/Maul decision is built around it.
--   C2 Enrage         situational: a PRE-PULL rage generator that strips armour, already
--                     out-of-combat gated. Absence now answers "can I open with it again".
--   C3 Frenzied Regen situational/emergency, and the Alerts flow already owns its moment
--                     (HP < 40% AND ready). Icy Veins: use it when "you are either getting
--                     low or ... about to go into a period of high sustained damage".
--   C4 Swiftmend      situational. It CONSUMES a Rejuvenation/Regrowth, so pressing it on
--                     cooldown throws away a HoT that was already healing. Icy Veins puts it
--                     on "targets taking heavy damage" and emergencies — "you want to be
--                     casting other spells and only using it for emergencies".
--   C5 Nature's Swift 3min emergency instant-cast enabler. Never a loop press.
--   C6 Force of Nature situational burst on a 3-MINUTE cooldown, and explicitly NOT used on
--                     sight: the guides hold it for "times where there are no abilities going
--                     off that will kill your treants and against targets that will live
--                     through its 30 second duration".
--   C7 Barkskin       defensive, and it breaks shapeshift in 2.4.3 (already hidden from feral).
--   C8 Innervate      mana cooldown with its own alert prompt at < 20% mana; likewise breaks
--                     shapeshift, likewise hidden from feral.
local mangleCD =                                                            -- C1
addCD("Mangle",             "Mangle (Bear)",         CD_MANGLE,    GATE_F, true)
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
-- of the desaturate-while-down readout. subRegions[1] is ALREADY the icon prototype's subglow,
-- so this replaces index 1 in place and shifts nothing — sub.1 keeps pointing at a subglow.
-- v6 appends the third condition: out of combat the glow is forced back off, so a bear parked
-- in a city is not staring at a lit icon (conditions apply in order, the last match wins).
mangleCD.subRegions[1] = F.subglow(false, { 1, 0.55, 0.15, 1 })
mangleCD.conditions[2] = F.condition(1, "onCooldown", "==", 0, "sub.1.glow", true)
mangleCD.conditions[3] = F.condition(2, "inCombat", "==", 0, "sub.1.glow", false)

-- ================= v2 additions =================
-- APPEND-ONLY: every constructor below draws a uid AFTER all v1 ones, which is what keeps the
-- in-game import dialog on "Update". Each element is re-parented into its v1 group by the
-- helper it is built with (adopt() appends to that group's controlledChildren).

-- R7-R10 Rage thresholds — the bear's two spend decisions, v8 moves them onto the power ring.
-- v7 drew them as thin vertical lines over a 172x14 bar at x = -86 + 1.72*v. The ring is a
-- circle starting at 12 o'clock and filling CLOCKWISE, so the same value v now lands at angle
-- v/100 * 360 and, per BaseRegions/TextureCoords.lua's exactAngles (index 1 = {0.5, 0} = top
-- centre, index 3 = {1, 0.5} = right middle), x = r*sin(theta), y = r*cos(theta). 20 rage
-- lands around 2 o'clock, 70 rage around 8 o'clock.
--
-- These stay FOUR SEPARATE AURAS rather than becoming sub-regions of the ring, deliberately:
-- the aurabar tick sub-region cannot come along at all (SubRegionTypes/Tick.lua's supports()
-- returns true only for "aurabar"), and the two sub-region types that DO support
-- progresstexture would cost the pop. A subtexture/subcirculartexture mark can change colour
-- by condition but cannot carry its own animation, and the pop-in on crossing IS the signal
-- here. Keeping them as regions also keeps their triggers, their Feral gate and their v7 Bear
-- form gate exactly as they were, and keeps them out of the sub.N condition index entirely.
--
-- Round pips, not lines: rotating a thin quad on a texture region rotates the ART INSIDE the
-- quad (DoTexCoord -> GetRotatedPoints), so a 2x16 line rotated 126 degrees clips instead of
-- tilting. A circle needs no rotation to point the right way.
--
-- v9 — THE TRAP. These are stand-alone texture regions anchored to the SCREEN, not sub-regions
-- of the ring, so nothing moves them when the ring they mark changes size or position. Both
-- happened in v9 (the power ring grew 64 -> 78, the whole cluster moved to y = -60), and a pip
-- left at the v8 coordinates would be a mark floating in empty space. The fix is that BOTH
-- coordinates are now derived rather than partly hard-coded: the centre is (-G.orbX, G.orbY)
-- and the radius is G.tickR, itself computed from ORB_MID. v8's y line omitted the cluster's
-- own y entirely because the cluster happened to sit at 0.
local function rageTick(id, rageValue, size, color, minRage)
  local theta = math.rad(rageValue / 100 * 360)
  local x = math.floor(-G.orbX + G.tickR * math.sin(theta) + 0.5)
  local y = math.floor( G.orbY + G.tickR * math.cos(theta) + 0.5)
  local pip = reg(F.texture(id, CLASS, size, size, x, y, nil, F.TEX_CIRCLE, color))
  pip.triggers = F.triggers({ F.powerTrigger(1, minRage) })  -- rage only exists in bear form
  pip.load = F.load(CLASS, GATE_F)
  if minRage then
    pip.animation.start  = F.animPreset("shrink", "0.25", "easeOut")  -- WA "shrink" = pop-in
    pip.animation.finish = F.animPreset("fade", "0.2")
  end
  adopt(gRes, pip)
  return pip
end

rageTick("Druid - Rage Tick Mangle",     20,  6, { 0.25, 0.95, 0.45, 0.55 }, nil)
rageTick("Druid - Rage Tick Maul",       70,  6, { 1, 0.75, 0.2, 0.55 },     nil)
rageTick("Druid - Rage Tick Mangle Lit", 20, 10, { 0.25, 0.95, 0.45, 1 },    20)
rageTick("Druid - Rage Tick Maul Lit",   70, 10, { 1, 0.75, 0.2, 1 },        70)

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

-- ================= v8 additions — the two unit portraits =================
-- The ONLY genuinely new auras in v8, so they draw the only new uids, and they draw them here
-- at the bottom, after every pre-existing uid() call in the file. Everything else in the orb
-- layer reuses a v7 Resources uid in place (see the map in the header), which is what lets
-- the in-game import stay a clean Update with nothing orphaned.
--
-- Adopted last, so they carry the highest frame level in the group and nothing draws over a
-- face. No load gate beyond the class: a portrait has no spec.
adopt(gRes, portrait("Druid - Player Portrait", "player", -G.orbX))
adopt(gRes, portrait("Druid - Target Portrait", "target",  G.orbX))

-- Mangle (Bear) and Mangle (Cat) are granted by the same talent. A spell-known
-- load gate therefore identifies the Feral build, not the active form. Make the
-- distinction at runtime by ANDing every Bear-gated element with form 1
-- (Bear/Dire Bear in the fully trained TBC druid form list). Trigger 1 remains
-- the progress/icon source, so all existing conditions and displays keep their
-- trigger indexes and behavior.
local bearFormGated = 0
for _, aura in pairs(byId) do
  local load = aura.load or {}
  if load.use_spellknown and load.spellknown == 33878 then
    assert(aura.triggers and aura.triggers.disjunctive == "all",
      aura.id .. ": Bear form gate requires all-trigger logic")
    table.insert(aura.triggers, { trigger = F.formTrigger(1), untrigger = {} })
    bearFormGated = bearFormGated + 1
  end
end
-- 15 in v7, 14 in v8: the rage bar was the only Feral-gated element the orb migration made
-- spec-neutral, because the form-adaptive power ring serves every druid in every form and so
-- must not carry a Bear gate. The four rage pips, the Bear threat ring and the nine icon
-- elements are unchanged. spec-preview.lua's `forbidSpellGate = 33878` Cat profile fails the
-- build if any 33878-gated aura ever loses this trigger, so the count is belt and braces.
assert(bearFormGated == 14, "expected 14 Bear-only elements, gated " .. bearFormGated)

-- ================= assemble (v2000 nested), encode, verify, write =================
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

local txtPath = dir .. "/all-specs.txt"
-- continuity vs the PREVIOUS shipped string (read before overwriting it)
local cont = W.uidContinuity(encoded, txtPath)
W.assertUidContinuity(cont, "druid")

local out = io.open(txtPath, "w")
out:write(encoded)  -- single line, no trailing newline
out:close()

print(("OK: %d auras (%d children + top), %d chars -> all-specs.txt")
  :format(#transmit.c + 1, #transmit.c, #encoded))
if cont then
  print(("uid continuity vs previous: stable=%d changed=%d parentSame=%s")
    :format(cont.stable, cont.changed, tostring(cont.parentSame)))
end
