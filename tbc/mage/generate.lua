-- tbc/mage/generate.lua — Mage "Arcane & Frost" HUD v8.
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
--
-- v5 (source verification closed two v4 unknowns; ONE new aura, no existing aura's uid moved):
--   * the threat bar and the threat flash now carry the inverse instance-size gate, so they
--     no longer load in arena, where there is no threat table at all. v4 left them alone
--     because the open-world value of `size` was unconfirmed; it is the literal string
--     "none" (WeakAuras.lua GetInstanceTypeAndSize ends `return "none", "none", nil, nil, 0`
--     for the not-in-an-instance case), so enumerating the complement is safe outdoors.
--   * NEW: "Mage - Enemy Mana", one bar per mana-using arena opponent. The Power prototype's
--     unit arg accepts `arena` on TBC (the deletion of arena from actual_unit_types_cast is
--     inside `if WeakAuras.IsClassicEra()`, not TBC), registers UNIT_POWER_FREQUENT per
--     arena1..5, and clones on statesParameter = "unit".
--   * CC ON ME's nine `sub.1.glowColor` conditions were re-verified against the shipped
--     string and the WA source and are LIVE — no change. The trap they avoid: SetGlowColor
--     only stores the colour, and SetVisible forwards it to LibCustomGlow only when
--     useGlowColor is true, so a subglow built WITHOUT a colour makes every glowColor
--     condition a silent no-op. F.subglow(on, color) sets useGlowColor whenever a colour is
--     passed, and this aura's subglow is subRegions[1], which is what "sub.1" resolves to.

-- v6 (the cooldown row shows what you CANNOT press; NO new aura, no uid moved, nothing
-- removed — only genericShowOn and the desaturate condition on six existing icons change):
-- the default row was inverted. Ten icons sat on screen permanently and merely dimmed when
-- down, so the row was busiest exactly when the mage had fewest options — and a mage knows
-- their own spellbook. What they cannot know is what is unavailable and for how long. Every
-- icon in the row was therefore classified, ability by ability, against
-- references/rotation-design.md's "Show what the player CANNOT press":
--   * PRESS-ON-COOLDOWN (stay showAlways, keep the ready-glow — a hidden icon can never fire
--     one, and hiding the button you press most trades "press this now" for "you cannot"):
--     Arcane Power, Icy Veins, Summon Water Elemental. These are the damage cooldowns both
--     raid builds press the moment they come up (icy-veins.com/tbc-classic states Frost's
--     rotation as "use Icy Veins and Summon Water Elemental when possible, and cast
--     Frostbolt"; Arcane opens its burn phase with AP + IV stacked), and all three have
--     glowed gold in combat since v2. Cold Snap keeps showAlways for a structural reason:
--     its glow is a SEQUENCING instruction (it fires only once both cooldowns it resets have
--     been spent), which is the one moment pressing an 8 min reset is correct — and that
--     moment cannot be announced by an icon that is hidden while the ability is ready.
--   * SITUATIONAL (now genericShowOn = "showOnCooldown"): Presence of Mind (spent inside the
--     burn window Arcane Power's glow already announces — same 3 min cooldown, so a second
--     glow would be a duplicate cue), Ice Block (emergency defensive, owned by the HP<30%
--     prompt), Evocation (mana cooldown, owned by the mana<30% prompt), Counterspell
--     (interrupt, owned by COUNTERSPELL NOW in the PvP alert flow), Blink (movement),
--     Invisibility (threat dump, owned by the 70%-threat prompt). None of the six is part of
--     the Arcane Blast / Frostbolt damage loop, so none of them earns a glow instead: no
--     mage cooldown is a rotational filler the way a hunter's Arcane Shot or a destruction
--     warlock's Conflagrate is.
-- The desaturate condition goes with the conversion: under showOnCooldown every visible icon
-- is on cooldown by definition, so greying the whole row would only make the abilities harder
-- to tell apart. The row is a dynamic group, so the gap closes — ABSENCE IS THE READOUT.
-- Subregion safety: F.icon's prototype already ships a subglow at subRegions[1] on every
-- icon, so nothing was inserted or reordered here and every existing "sub.1.glow" condition
-- still resolves to a subglow (audited on the decoded string, all 17 refs).

-- v7 (the middle of the screen is given back: the Resources bar stack becomes two UNIT ORBS;
-- SIX new auras, no existing uid moved, nothing outside the Resources group touched):
-- health / mana / threat left the centre and moved to where the units are. The player orb
-- sits left of the character and the target orb right of it, each a live 3D unit portrait
-- ringed by concentric arcs — outer health, inner mana, and on the target a third, outermost
-- threat ring. Percentages ride below (threat above) instead of inside a bar. The target orb
-- self-hides completely with no target, which no bar stack ever did.
--   * REGION TYPE. The rings are `progresstexture` in CLOCKWISE orientation on WeakAuras'
--     own bundled Ring_20px / Ring_10px art, with a `model` portrait in the middle. Both
--     region tables are written out in full from poc/unit-orbs/generate.lua (the verified
--     reference build) because wa_factory has no builder for either.
--   * THE RENAME THAT WOULD HAVE BEEN SILENT: progresstexture has no `barColor`. Every
--     colour escalation is now `foregroundColor`, and Conditions.lua drops changes whose
--     property is absent from the region's properties table with no error and no editor
--     warning, so a mechanical port would have shipped four dead escalations.
--   * THE INVERSION THAT WOULD HAVE BEEN A LIE: AuraBar draws EMPTY at total == 0,
--     ProgressTexture draws FULL. Every ring therefore carries a zero-total guard
--     (`maxhealth <= 0`, `threatvalue <= 0`, `maxpower <= 1`) that hides it instead.
--   * UID DISCIPLINE. W.assertUidContinuity requires missing == 0 — every uid the previous
--     string shipped must still be in this one — so the bars could not be deleted and
--     replaced. They were TRANSFORMED in their own uid slots: health bar -> player health
--     ring, mana bar -> player mana ring, threat bar -> target threat ring, threat flash ->
--     the halo on that ring, and the two conserve-line textures -> two beads on the mana
--     ring. Six genuinely new auras (two cluster groups, two portraits, the target health
--     and mana rings) are appended at the very bottom. Nothing is orphaned in game.
--   * WHAT DID NOT SURVIVE, exactly: nothing. Both health tiers, the threat escalation and
--     its 80% pulse, the out-of-combat fade, the Arcane-only conserve breakpoint and every
--     load gate came across. The conserve mark is a bead on the ring instead of a vertical
--     line on a bar; it is still two auras precisely so it can keep its Arcane-only gate,
--     which a `subtexture` tick welded to the shared mana ring could not have.

-- v8 (PURE GEOMETRY: the orbs are one shared size across all seven packs. NO aura added or
-- removed, no uid moved, and not one trigger, load gate, condition, colour, spell id or
-- region type touched — diff the decoded strings and only width/height/xOffset/yOffset,
-- two font sizes and one texture path move):
--   * THE BUG WAS DISAGREEMENT, NOT ANY SINGLE NUMBER. v7 shipped a 120 px target cluster
--     beside a 100 px player cluster, and each of the seven packs had picked its own sizes
--     (96/84/88/100 outer rings across the repo). Side by side that reads as sloppiness,
--     which is what the live-client review reported as "the size uneven".
--   * ONE CANONICAL SET, declared as named constants at the top of the orb section so the
--     next edit cannot drift them apart again: ORB_OUTER 104, ORB_MID 78, ORB_INNER 54,
--     PORTRAIT 46, CLUSTER_X 260, CLUSTER_Y -60. Both clusters now present the SAME outer
--     diameter and the SAME portrait; the target just nests one more ring inside, since it
--     is the side that carries threat. Player 104/78, target 104/78/54.
--   * Ring_10px is gone. Its stroke is 10/256 of the drawn size — 4.7 px on a 120 px ring —
--     which read as a wire rather than a band. Every ring is Ring_20px now, so the threat
--     arc is a real band and the three concentric arcs read as one system.
--   * The read-outs are one set of offsets for both sides (health 14 pt at -60, power 11 pt
--     at -76, threat 11 pt at +60). They can be, because every ring in a cluster is
--     concentric and each subtext anchors CENTER: the offset is measured from the cluster
--     centre, not from whichever ring happens to carry the text. v7 needed four numbers
--     because its two clusters had different outer diameters.
--   * THE TRAP THIS PACK HAD: the Arcane conserve bead is positioned by trigonometry on the
--     mana ring's circumference (ringPoint), so resizing that ring without re-deriving the
--     bead would leave a mark floating in empty space. It is computed from G.pMpRing and
--     moves 31.56,-10.26 -> 34.19,-11.11 on its own; both bead auras share the one call.

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

-- v5: "everywhere except arena", for PvE furniture that would be pure clutter in an arena.
-- There is no "not arena" key: the `size` load arg (Prototypes.lua) declares no `test` and no
-- `inverse`, and multiselect mode is a plain OR over raw string equality, so the exclusion has
-- to be spelled out as every OTHER legal instance_types value. On TBC the full key set is
-- none / party / ten / twenty / twentyfive / fortyman / pvp / arena (Types.lua deletes
-- ratedpvp, ratedarena, flexible and scenario for Classic-family clients, and deletes `arena`
-- only for Classic Era). `twenty` is legal but no TBC difficultyIndex maps to it; listing it is
-- free. `none` is the load-bearing entry: GetInstanceTypeAndSize returns the literal strings
-- "none", "none" from its final line when you are not in an instance, so the open world MATCHES
-- and the bars keep loading while questing — the doubt that kept this gate out of v4.
-- `pvp` stays listed on purpose: Alterac Valley has real NPCs with a real threat table.
local NOT_ARENA = { multi = {
  none = true, party = true, ten = true, twenty = true,
  twentyfive = true, fortyman = true, pvp = true,
} }

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

-- ===== v7 orb primitives ====================================================
-- wa_factory has no progresstexture or model builder, so those two region tables are
-- written out in full below, field-for-field from poc/unit-orbs/generate.lua — the
-- verified reference build for this layout. Everything else (triggers, subtext,
-- conditions, load gates, assembly) still goes through the factory.
--
-- Ring_20px.tga ships inside WeakAuras (Private.texture_types -> "Shapes"), so no media
-- addon is needed. It is a true annulus; Circle_Smooth2.tga — the texture the rest of this
-- pack uses — is a SOLID DISC and would fill as a pie wedge, not a ring.
--
-- v8: Ring_10px is GONE from this pack. The 10 px stroke is measured in the texture's own
-- 256x256 space, so a ring drawn at S px carries a band of S*10/256 — 4.7 px at 120 px.
-- At orb diameters that reads as a wire, not as a band, which was the first thing the live
-- client review complained about. Every ring in both clusters is now Ring_20px.
local RING_TEX = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Ring_20px.tga"

-- ===== CANONICAL ORB GEOMETRY (v8) — IDENTICAL IN ALL SEVEN PACKS ===========
-- These numbers are not this pack's to tune. Before v8 every pack picked its own ring
-- sizes AND the two clusters inside a pack disagreed with each other (mage shipped a
-- 120 px target orb next to a 100 px player orb), which is what the live-client review
-- saw as "the size uneven, looks bad". Seven packs now emit the same six numbers, so a
-- reviewer can diff any two strings and get the same diameters.
--
-- Change them in all seven packs or not at all — a local "improvement" here silently
-- re-breaks the thing v8 exists to fix.
local ORB_OUTER = 104   -- outermost ring, on BOTH clusters, in EVERY pack
local ORB_MID   = 78
local ORB_INNER = 54
local PORTRAIT  = 46
local CLUSTER_X = 260   -- cluster centres, SCREEN coordinates: player -X, target +X
local CLUSTER_Y = -60
local TOP_Y     = -140  -- the pack's top group; the orb layer offsets back out of it

-- RING ASSIGNMENT. Both clusters present the SAME outer diameter and the SAME portrait;
-- the target simply nests one more ring inside, because it carries threat as well.
--   player: health = ORB_OUTER, mana = ORB_MID,   portrait = PORTRAIT
--   target: threat = ORB_OUTER, health = ORB_MID, mana = ORB_INNER, portrait = PORTRAIT
-- The percentages are subtexts on their own rings, anchored CENTER, and every ring in a
-- cluster is concentric — so one Y offset per read-out places it identically on both
-- sides, measured from the cluster centre rather than from whichever ring carries it.
local G = {
  orbY        = CLUSTER_Y - TOP_Y,   -- +80: the orb layer hangs off `top` at (0, -140),
                                     -- so this lands both cluster centres at y = -60
  orbX        = CLUSTER_X,           -- must clear the Alerts column (-150, 44 px icons
                                     -- -> -172) and the PvP column (+150 -> +168): the
                                     -- cluster is 108 wide, so +-260 puts its inner
                                     -- edge at 206.
  threatRing  = ORB_OUTER,   -- OUTERMOST of the target cluster
  flashRing   = ORB_OUTER + 4,        -- the 80% threat pulse, a halo just outside its ring
  pHpRing     = ORB_OUTER,   -- player: health is the outer arc, the more-read number
  pMpRing     = ORB_MID,     -- player: mana nests inside it
  tHpRing     = ORB_MID,     -- target: health nests inside the threat ring
  tMpRing     = ORB_INNER,   -- target: mana innermost
  portrait    = PORTRAIT,    -- live 3D portrait in the middle
  hpTextSize  = 14, mpTextSize = 11, threatTextSize = 11,
  hpTextY     = -60,   -- health %: just under the ORB_OUTER ring (radius 52), both sides
  mpTextY     = -76,   -- power %: under the health number, both sides
  threatTextY = 60,    -- threat %: above the ring, where nothing else sits
}

local COL = {
  health   = { 0.15, 0.82, 0.28, 1 },   -- green, same language as the v6 health bar
  mana     = { 0.25, 0.50, 0.95, 1 },   -- blue,  same as the v6 mana bar
  threat   = { 0.25, 0.80, 0.30, 1 },   -- green, same as the v6 threat bar
  warn     = { 1, 0.60, 0.10, 1 },      -- orange: 50% health / 70% threat
  danger   = { 0.90, 0.12, 0.12, 1 },   -- red:    30% health / aggro
  track    = { 0, 0, 0, 0.55 },         -- the unfilled arc behind every ring
  hpText   = { 1, 1, 1, 1 },
  mpText   = { 0.55, 0.75, 1, 1 },      -- each number is coloured like its own ring, so
  thText   = { 0.70, 1, 0.75, 1 },      -- none of the three ever needs a label
}

-- wa_factory's stub() is local to the factory; the hand-written region tables below get
-- the identical scaffolding here.
local function orbStub(t)
  t.internalVersion, t.tocversion = 45, 20501
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

-- Same stub fields trigStub applies inside the factory. The factory's healthTrigger and
-- powerTrigger are hardwired to unit = "player"; these clusters need "target" too.
local function orbTrigStub(tr)
  tr.names, tr.spellIds = {}, {}
  tr.subeventPrefix, tr.subeventSuffix = "SPELL", "_CAST_START"
  tr.debuffType = "HELPFUL"
  return tr
end

-- Health. The prototype ends in a hidden always-on test,
--   WeakAuras.UnitExistsFixed(unit, smart) and specificUnitCheck
-- ANDed into the trigger function, so unit = "target" with no target produces NO STATE and
-- the region hides. That is the entire self-hide mechanism for the target cluster — no
-- condition, no load gate, no custom code.
local function unitHealthTrigger(unit)
  return orbTrigStub{ type = "unit", event = "Health", unit = unit, use_unit = true }
end

-- Mana, and only mana — the same three flags the pack's Enemy Mana bar already uses:
--   use_powertype + powertype = 0  -> read MANA specifically. Drop either and powerType is
--     nil and the trigger silently falls back to the unit's CURRENT bar, i.e. a warrior's
--     rage rendered in a ring coloured for mana.
--   use_requirePowerType           -> the ring exists only while mana is that unit's PRIMARY
--     bar, so a warrior or rogue target produces no state and the inner ring vanishes
--     instead of parking a permanently empty blue circle. It is enabled by use_powertype,
--     so both are needed. (Harmless on the player: a mage's primary bar is always mana.)
local function unitManaTrigger(unit)
  return orbTrigStub{
    type = "unit", event = "Power", unit = unit, use_unit = true,
    use_powertype = true, powertype = 0,
    use_requirePowerType = true,
  }
end

-- Threat, with the unit named EXPLICITLY. F.threatTrigger emits `threatUnit`, which is not
-- an argument of the Threat Situation prototype at all (its arg is `name = "unit"`,
-- default "target") — dead data that works only by accident, because the prototype's init
-- runs `trigger.unit = trigger.unit or "target"` inside ConstructFunction BEFORE events()
-- and internal_events() read trigger.unit. Naming `unit` here makes the target binding real
-- instead of incidental. The factory's stray threatUnit field is left alone on purpose:
-- fixing it is a toolkit change that would touch six other packs' strings.
local function orbThreatTrigger(minPct)
  local tr = F.threatTrigger(minPct)
  tr.unit = "target"
  tr.use_unit = true
  return tr
end

-- Radial progress ring. Field notes on the ones that are traps:
--   orientation CLOCKWISE  -> the only radial values are CLOCKWISE / ANTICLOCKWISE; every
--     other value in orientation_with_circle_types is linear.
--   startAngle 0 / endAngle 360 -> full circle. WA normalises 0/360 -> 0/0 and then
--     corrects endAngle back up by 360, so a full ring is handled, not a degenerate case.
--   crop_x / crop_y = 0.41 -> the IDENTITY value, NOT "no crop". The circular path expands
--     the texture by sqrt(2) so rotated quadrants never run off it, and 1 + 0.41 exactly
--     cancels that. Setting 0 blows the ring up 1.41x and clips it.
--   auraRotation = 0 -> absent from the 3.5.0 default table but read unconditionally by
--     current code as data.auraRotation / 180 * math.pi, so it must be emitted.
--   backgroundOffset = 0 -> the default 2 fattens the track relative to the fill, which
--     reads as a halo instead of a concentric track.
--   adjustedMin/Max are STRINGS (""), because SetAdjustedMin does adjustedMin:find(...).
--   progressSource is rewritten to {-1, ""} by Modernize < 71 no matter what is emitted, so
--     ONE PROGRESS-SUPPLYING TRIGGER PER RING and it must be trigger 1: automatic progress
--     reads the first ACTIVE trigger's value/total (F.triggers sets activeTriggerMode -10).
--     A second trigger is legal but can only feed CONDITIONS, never the fill.
--   compress / slanted / slant / slantFirst / slantMode are LINEAR-only and silently inert
--     on a circular ring; they are emitted because they are in the default table.
local function ring(id, size, texture, color, triggers)
  return orbStub{
    regionType = "progresstexture", id = id, uid = W.uid(), parent = nil,
    width = size, height = size,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = 0, yOffset = 0, frameStrata = 1, alpha = 1,
    orientation = "CLOCKWISE", startAngle = 0, endAngle = 360,
    inverse = false, mirror = false,
    compress = false, slanted = false, slant = 0, slantFirst = false, slantMode = "INSIDE",
    foregroundTexture = texture, backgroundTexture = texture, sameTexture = true,
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
    triggers = F.triggers(triggers),
    load = F.load(CLASS),
  }
end

-- Live unit portrait: a real 3D portrait of whoever is targeted, not a class icon, which is
-- what makes the target side work without ever knowing the target's class — it renders NPCs
-- and mobs too.
--   modelIsUnit = true + model_fileId = "<unit>" -> PlayerModel:SetUnit(unit)
--   portraitZoom = true                          -> SetPortraitZoom(1), Blizzard head framing
-- CRITICAL: current code reads the unit from `model_fileId`. WA 3.5.0 read `model_path`, and
-- the migration bridging the two (Modernize < 72) is guarded by WeakAuras.IsClassicEra(),
-- which is a DISTINCT predicate from IsTBC() — so on a 2.5.x client that migration DOES NOT
-- RUN and emitting only model_path is a silent no-op. Both are emitted; model_fileId works.
-- The portrait carries its unit's Health trigger, so it self-hides with the rings.
local function portrait(id, unit, size, triggers)
  return orbStub{
    regionType = "model", id = id, uid = W.uid(), parent = nil,
    model_fileId = unit, model_path = unit, modelIsUnit = true, modelDisplayInfo = false,
    portraitZoom = true, api = false,
    model_x = 0, model_y = 0, model_z = 0,
    model_st_tx = 0, model_st_ty = 0, model_st_tz = 0,
    model_st_rx = 270, model_st_ry = 0, model_st_rz = 0, model_st_us = 40,
    sequence = 1, advance = false, rotation = 0,
    width = size, height = size, alpha = 1,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = 0, yOffset = 0, frameStrata = 1,
    border = false, borderColor = { 1, 1, 1, 0.5 }, backdropColor = { 1, 1, 1, 0.5 },
    borderEdge = "None", borderOffset = 5, borderInset = 11,
    borderSize = 16, borderBackdrop = "Blizzard Tooltip",
    subRegions = {},
    triggers = F.triggers(triggers),
    load = F.load(CLASS),
  }
end

-- The percentages sit OUTSIDE the rings: the middle is the portrait, and a `model` region
-- cannot carry a text subregion at all (SubText's supports() lists texture / progresstexture
-- / icon / aurabar / empty — model is absent). Each number therefore rides on its own ring,
-- which also means it appears and disappears with that ring: no target, no numbers.
local function pct(sym, size, yOffset, color)
  local st = F.subtext("%" .. sym .. "%%", size, "CENTER", sym)
  st.anchorYOffset = yOffset
  st.text_color = color
  return st
end

-- Where a percentage sits ON a ring, in the ring's own coordinates. Angle convention proven
-- from BaseRegions/TextureCoords.lua's exactAngles table: index 1 (0 deg) = {0.5, 0} = top
-- centre, index 3 (90 deg) = {1, 0.5} = right middle. So 0 deg is 12 o'clock and the angle
-- increases CLOCKWISE, matching the rings' orientation = "CLOCKWISE", startAngle = 0. Hence
-- x = r*sin(theta), y = r*cos(theta), with r measured to the STROKE CENTRE of the band.
-- Rounded to 0.01 so the build stays byte-identical across libm implementations.
local function ringPoint(size, strokePx, fraction)
  local radius = size * (1 - strokePx / 256) / 2
  local theta = math.rad(fraction * 360)
  local function round(v) return math.floor(v * 100 + 0.5) / 100 end
  return round(radius * math.sin(theta)), round(radius * math.cos(theta))
end

-- ===== top-level group, anchored below the character ========================
-- NOTE: the top group takes the factory's own uid() call (no extra W.uid() here);
-- that choice is permanent — changing it would reshuffle every uid downstream.
local top = F.group(TOP, 0, TOP_Y, nil)

-- ===== Resources -> UNIT ORBS (v7) ==========================================
-- The four regions below occupy the uid slots the v6 health / mana / threat bars and the
-- threat flash held, IN THE SAME ORDER, because W.assertUidContinuity requires
-- missing == 0: every uid the previous string shipped must still exist in this one. A
-- delete-and-recreate migration would drop six uids and fail the repo suite outright, so
-- the bars are TRANSFORMED in place instead. The upside is bigger than the constraint: the
-- in-game import is a clean Update with nothing orphaned to clean up afterwards.
-- They are NOT adopted here — their cluster groups are new auras and therefore live at the
-- very bottom of this script, where the appended uid() calls belong. See "v7 assembly".
local gOrbs = reg(F.group("Mage - Orbs", 0, G.orbY, nil))
adopt(top, gOrbs)

-- PLAYER HEALTH, outer ring. Trigger 1 is the only progress source (see ring()); the Unit
-- Characteristics trigger is there purely to feed the out-of-combat fade, exactly as it did
-- on the v6 bar.
local hp = reg(ring("Mage - Player Health", G.pHpRing, RING_TEX, COL.health,
  { unitHealthTrigger("player"), F.unitCharTrigger() }))
hp.subRegions[1] = pct("percenthealth", G.hpTextSize, G.hpTextY, COL.hpText)
-- v2's escalating colour tiers, carried over intact. The property is `foregroundColor`, NOT
-- the aurabar's `barColor`: progresstexture has no barColor, and Conditions.lua skips any
-- change whose property is missing from the region's properties table WITHOUT an error or an
-- editor warning — a mechanical port of the old line would have been a silent dead
-- escalation. Severe tier last: later conditions overwrite the same property, and the revert
-- is automatic (CreateDeactivateCondition restores data.foregroundColor).
-- The maxhealth guard is new and mandatory. AuraBar draws EMPTY at total == 0
-- (`if self.total ~= 0`) but ProgressTexture starts from `local progress = 1` and draws
-- FULL, so a unit whose max health has not streamed in yet would flash a complete ring.
-- `maxhealth` is a stored conditionType = "number" arg on the Health prototype.
hp.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "percenthealth", "<", "50", "foregroundColor", COL.warn),
  F.condition(1, "percenthealth", "<", "30", "foregroundColor", COL.danger),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),   -- zero-total guard, wins over the fade
}

-- PLAYER MANA, inner ring: the mage's real resource clock — Evocation pacing reads off it.
local mana = reg(ring("Mage - Player Mana", G.pMpRing, RING_TEX, COL.mana,
  { unitManaTrigger("player"), F.unitCharTrigger() }))
mana.subRegions[1] = pct("percentpower", G.mpTextSize, G.mpTextY, COL.mpText)
-- Power is the one prototype that cannot hit total == 0 — its init floors the total at
-- math.max(1, UnitPowerMax(...)) — which is exactly why this guard reads <= 1 and not <= 0.
mana.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxpower", "<=", "1", "alpha", 0),
}

-- THREAT, the outermost ring of the TARGET cluster. Threat is your threat ON that target, so
-- the target orb is its natural home once the middle stack is gone. The Threat Situation
-- prototype is progressType = "static" and stores hidden value/total args just like Health
-- and Power (threattotal = threatvalue * 100 / threatpct), so value/total is threatpct/100
-- and the ring fills 0-100% of the pull threshold with no custom code.
local threat = reg(ring("Mage - Target Threat", G.threatRing, RING_TEX, COL.threat,
  { orbThreatTrigger() }))
threat.subRegions[1] = pct("threatpct", G.threatTextSize, G.threatTextY, COL.thText)
threat.conditions = {
  F.condition(1, "threatpct", ">=", "70", "foregroundColor", COL.warn),
  F.condition(1, "aggro", "==", 1, "foregroundColor", COL.danger),   -- severe last
  -- MANDATORY on a ring, and the one place this migration could have regressed. threattotal
  -- is (threatvalue or 0) * 100 / threatpct, so total is 0 whenever threatvalue is 0 — the
  -- instant before your first cast lands, and right after an Invisibility drop. The v6 bar
  -- drew empty there; a ring would slam to a FULL circle meaning "at the pull threshold"
  -- while the colour conditions stayed green, i.e. shape and colour contradicting each other
  -- at the worst possible moment. `threatvalue` is a stored conditionType = "number" arg
  -- (the hidden `total` is not), so the ring is simply hidden instead.
  F.condition(1, "threatvalue", "<=", "0", "alpha", 0),
}
-- v2: party/raid only, like the flash overlay and the Invisibility prompt. Solo you are
-- always the aggro target, so ungated the ring would sit pinned red for every quest mob.
threat.load.use_ingroup = true
threat.load.ingroup = IN_GROUP
-- v5: and NOT in arena. An arena team has no threat table, so it would read a meaningless
-- number in exactly the place a player has least attention to spare. `ingroup` cannot
-- express this on its own — an arena team IS a party. Everywhere else is unchanged, open
-- world included (see NOT_ARENA). Both gates travel with the ring; without them v7 would
-- silently regress to the v1 behaviour they were added to fix.
threat.load.use_size = false   -- false selects MULTI mode; only nil disables the gate
threat.load.size = NOT_ARENA
-- The health and mana rings of the target cluster carry NO group/arena gate on purpose: they
-- are unit state, not a threat relationship, and are wanted everywhere.

-- 80%+ threat: the pulsing red overlay, now a fat red halo drawn ON the threat ring instead
-- of a bar-shaped rectangle over a bar. Same region type, same trigger, same animation, same
-- load gates as v6 — only the geometry and the texture changed. Ordered after the threat
-- ring in controlledChildren so it layers above it (+4 frame levels per child).
local flash = reg(F.texture("Mage - Threat Flash", CLASS, G.flashRing, G.flashRing, 0, 0, nil,
  RING_TEX, { 1, 0.1, 0.1, 0.85 }))
flash.blendMode = "ADD"
flash.triggers = F.triggers({ orbThreatTrigger(80) })
flash.animation.main = F.animPreset("alphaPulse", "1")  -- duration required or it is invisible
flash.load.use_ingroup = true
flash.load.ingroup = IN_GROUP
flash.load.use_size = false   -- v5: follows its ring out of the arena
flash.load.size = NOT_ARENA

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
-- v6: the third field is the CLASSIFICATION, not a glow flag (see the v6 note at the top):
--   "glow" — press-on-cooldown damage cooldown: showAlways + the gold ready-glow in combat
--   "seq"  — showAlways, glow supplied below (Cold Snap's is a sequencing cue, not a ready cue)
--   "hide" — situational/utility/emergency: showOnCooldown, no desaturate, absence = available
local cdList = {
  { "Arcane Power",           12042, "glow" },  -- Arcane 31: 3 min burst, press on CD
  { "Presence of Mind",       12043, "hide" },  -- Arcane 21: spent inside the AP burn window
  { "Icy Veins",              12472, "glow" },  -- both 40/0/21 arcane and frost talent it
  { "Summon Water Elemental", 31687, "glow" },  -- Frost 41: 3 min pet, press on CD
  { "Cold Snap",              11958, "seq"  },  -- Frost 21: 8 min, sequencing rebuilt below
  { "Ice Block",              45438, "hide" },  -- Frost 31: 5 min immunity, HP<30% prompt owns it
  { "Evocation",              12051, "hide" },  -- 8 min mana refill, mana<30% prompt owns it
  { "Counterspell",           2139,  "hide" },  -- 24 s interrupt, COUNTERSPELL NOW owns it
  { "Blink",                  1953,  "hide" },  -- 15 s reposition
  { "Invisibility",           66,    "hide" },  -- 5 min threat drop, 70%-threat prompt owns it
}
for _, e in ipairs(cdList) do
  local kind = e[3]
  local icon = reg(F.icon("Mage CD - " .. e[1], CLASS, 32, 32, 0, 0, nil))
  icon.cooldownTextDisabled = false   -- swipe numbers here; no %p subtext (OmniCC doubles)
  icon.useTooltip = true
  if kind == "hide" then
    -- Exists only while the cooldown runs, carrying the swipe and its countdown, and gone the
    -- moment the ability is back. No desaturate: every visible icon here is on cooldown, so
    -- greying them all would just make them harder to tell apart at a glance.
    icon.triggers = F.triggers({ F.cdTrigger(e[2], e[1], "showOnCooldown") })
    icon.conditions = {}
  else
    icon.conditions = { F.condition(1, "onCooldown", "==", 1, "desaturate", true) }
    if kind == "glow" then
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
-- v6 keeps it on showAlways for exactly that glow: the sequencing cue fires while Cold Snap
-- is READY, so an icon hidden until it goes on cooldown could never deliver it.
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
-- v7: the same breakpoint, moved onto the mana RING. It is a bead sitting on the ring's
-- stroke at the 30% angle (0 deg = 12 o'clock, clockwise), not a vertical line on a bar.
--
-- WHY IT IS STILL TWO STANDALONE TEXTURE AURAS AND NOT A `subtexture` TICK. WeakAuras does
-- support static ticks on a progresstexture — SubRegionTypes/Texture.lua's supports() lists
-- progresstexture, and a subtexture with textureRotate/textureRotation plus explicit
-- xOffset/yOffset is the documented recipe (aurabar's `subtick` is aurabar-only and could
-- never have come along). It was rejected here for one reason: a sub-region cannot carry a
-- load gate. This breakpoint is ARCANE-ONLY since v3 — it marks the switch from Arcane Blast
-- spam to the 3x AB / 3x Frostbolt conserve cycle, and Frost has no second rotation to
-- switch into — and a tick welded onto the shared mana ring would show for Frost too,
-- silently undoing that audit. Two auras also keep the "lit" pop as a real animation.
local MANA_CONSERVE_PCT = 30
-- v8: derived from the ring it marks, so the bead follows the ring's diameter instead of
-- being left behind in empty space. ORB_MID (78) -> stroke centre radius 35.95 -> the 30%
-- angle (108 deg clockwise from 12 o'clock) lands at (34.19, -11.11); at the v7 diameter
-- of 72 the same bead sat at (31.56, -10.26). Nothing here is hand-entered.
local MANA_BEAD_X, MANA_BEAD_Y = ringPoint(G.pMpRing, 20, MANA_CONSERVE_PCT / 100)
local manaLine = reg(F.texture("Mage - Mana Conserve Line", CLASS, 8, 8,
  MANA_BEAD_X, MANA_BEAD_Y, nil,
  F.TEX_CIRCLE, { 1, 0.75, 0.2, 0.55 }))
manaLine.triggers = F.triggers({ F.powerTrigger(0), F.unitCharTrigger() })
manaLine.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }
-- v3: Arcane only. The line marks the point where Arcane STOPS spamming Arcane Blast and
-- starts the 3x Arcane Blast / 3x Frostbolt conserve cycle — it is the switch between two
-- rotations. Frost has no second rotation: it is Frostbolt spam all the way down, and its
-- low-mana actions (Evocation, mana gem) already have their own prompts, both of which
-- carry their own thresholds. So for Frost the line marked nothing pressable.
manaLine.load.use_spellknown = true
manaLine.load.spellknown = 12042      -- Arcane Power == deep-Arcane spec gate
-- v7: adopted into the player cluster at the bottom of this script, with the ring it marks.

local manaLit = reg(F.texture("Mage - Mana Conserve Lit", CLASS, 12, 12,
  MANA_BEAD_X, MANA_BEAD_Y, nil,
  F.TEX_CIRCLE, { 1, 0.75, 0.2, 1 }))
manaLit.blendMode = "ADD"
manaLit.triggers = F.triggers({ manaPctTrigger("<=", MANA_CONSERVE_PCT) })
manaLit.load.use_combat = true   -- drinking after a pull is not a rotation decision
manaLit.load.use_spellknown = true   -- v3: Arcane only, with the line it lights
manaLit.load.spellknown = 12042
manaLit.animation.start  = F.animPreset("shrink", "0.25", "easeOut")  -- WA "shrink" = UI "Grow"
manaLit.animation.finish = F.animPreset("fade", "0.2")

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
--   * hiding the threat bar/flash inside arena — DONE IN v5, see NOT_ARENA. v4 left it out
--     because WeakAuras only assigns `size = Type` inside `if inInstance or instanceType ~=
--     "none"`, so the open-world value was unproven and the gate risked unloading the bars
--     everywhere outdoors. It does not: that block is a guard, and the function's final line
--     returns the literal "none" for the not-in-an-instance case, which the gate lists.
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
--
-- v5 re-verified the colour-coding below against the WeakAuras source rather than by
-- inspection, because three separate things have to hold for it to be anything but a no-op:
--   1. "sub.1" is POSITIONAL — Conditions.lua builds the key from ipairs(data.subRegions), so
--      it resolves to the subglow only while the subglow is subRegions[1]. Never insert a
--      subregion ahead of it; append, exactly as wa_factory.lua already warns.
--   2. useGlowColor must be true. SetGlowColor only stores the value; SetVisible passes it to
--      LibCustomGlow behind `if self.useGlowColor then color = self.glowColor end`, so with it
--      false the setter runs and the screen never changes. F.subglow sets it whenever a colour
--      is passed — which is why the base colour below is given explicitly, not left to default.
--   3. the glow must be on (SetGlowColor's restart is guarded by `if self.glow`), which the
--      `true` below does unconditionally.
-- The value shape matters too: property type "color" is emitted as {v[1],v[2],v[3],v[4]} and
-- expanded to four positional args, so these MUST be 4-element arrays — an {r=,g=,b=,a=} hash
-- would serialise to four nils. controlType carries store = true in the prototype, so it is a
-- state variable even without use_controlType, and the comparison is against the raw API key
-- ("STUN"), never a localised label.
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

-- ===== v5 additions: enemy mana =============================================
-- ONE new aura, appended after the whole v4 uid stream: the 41 existing auras keep their uid,
-- so a re-import still offers "Update". The two other v5 changes are load gates on the threat
-- bar and threat flash (see NOT_ARENA), which move no uid.

-- ENEMY MANA, one bar per opponent. A mage does not drain mana, but the mage plays the mana
-- clock harder than anyone: Counterspell exists to keep a healer from spending it, Polymorph
-- exists to stop them drinking it back, and the whole decision "keep applying pressure vs.
-- commit the burst now" is a read on how much the enemy healer has left. A single number the
-- team can call out is worth more than another cooldown icon.
--   * unit = "arena" clones — one row per opponent — hence the dynamic-group parent.
--   * use_powertype + powertype = 0 are BOTH required to read MANA specifically. Drop either
--     and powerType is nil, the trigger falls back to UnitPowerType(unit), and the row happily
--     reports a rogue's energy as if it were mana.
--   * use_requirePowerType hides every opponent whose PRIMARY bar is not mana, so warriors and
--     rogues (who have no mana pool at all on TBC, i.e. a 0/0 bar that reads as "empty = go")
--     never take a row. The honest cost: a druid in bear or cat form drops off the list until
--     they shift back, because their primary bar is rage/energy while shifted.
--   * arena-only, never arena+pvp: arena1..arena5 do not exist in a battleground, where this
--     would be permanently blank rows.
local emanaTrig = F.powerTrigger(0)
emanaTrig.unit = "arena"
emanaTrig.use_requirePowerType = true
local emana = reg(F.aurabar("Mage - Enemy Mana", CLASS, 140, 12, 0, 0, nil,
  { 0.25, 0.50, 0.95, 1 }))
emana.triggers = F.triggers({ emanaTrig })
emana.subRegions[2] = F.subtext("%name", 10, "INNER_LEFT")
emana.subRegions[3] = F.subtext("%percentpower%%", 12, "INNER_RIGHT", "percentpower")
emana.subRegions[4] = F.subborder("bar")
-- Two tiers, same escalation idiom as the health bar: amber = they are running low, so deny
-- the drink and keep them casting; green = they are out, which is the kill window. Severe
-- tier last, because a later matching condition overwrites the same property.
emana.conditions = {
  F.condition(1, "percentpower", "<=", "30", "barColor", { 1, 0.85, 0.2, 1 }),
  F.condition(1, "percentpower", "<=", "10", "barColor", { 0.35, 0.95, 0.55, 1 }),
}
emana.load = pvpLoad(true)
adopt(gPvP, emana)

-- ===== v7 assembly: the six NEW orb auras, and every orb parent wiring ======
-- SIX new auras, and every W.uid() call in this block is appended AFTER the whole v6 uid
-- stream, so all 42 existing auras keep their uid and the in-game import still offers
-- "Update". Nothing above this line was reordered, nothing was deleted: the four bar auras
-- became rings and beads IN PLACE, in their own uid slots.
--
-- Re-parenting is free — only uid ORDER matters — which is what lets the cluster groups be
-- created last and still adopt regions built at the top of the script.
--
-- CHILD ORDER IS THE STACKING ORDER: FixGroupChildrenOrder walks controlledChildren and adds
-- +4 frame levels per entry, so EARLIER = further behind. Outermost ring first, portrait
-- LAST so nothing ever draws over the face. sharedFrameLevel is deliberately left off the
-- cluster groups — it would zero that offset and make the overlap order ambiguous.
local gPlayerOrb = reg(F.group("Mage - Player Orb", -G.orbX, 0, nil))
adopt(gOrbs, gPlayerOrb)
local gTargetOrb = reg(F.group("Mage - Target Orb", G.orbX, 0, nil))
adopt(gOrbs, gTargetOrb)

adopt(gPlayerOrb, hp)
adopt(gPlayerOrb, mana)
adopt(gPlayerOrb, manaLine)
adopt(gPlayerOrb, manaLit)
-- The player portrait carries the same two triggers as its rings, so it fades out of combat
-- with them instead of sitting at full brightness over a dimmed cluster. `alpha` is a region
-- prototype property (regionPrototype.AddAlphaToDefault is called on the model default), so
-- the condition is live on a model region, not a silent no-op.
local pPortrait = reg(portrait("Mage - Player Portrait", "player", G.portrait,
  { unitHealthTrigger("player"), F.unitCharTrigger() }))
pPortrait.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }
adopt(gPlayerOrb, pPortrait)

-- TARGET CLUSTER. Every member self-hides with no target: the Health and Power prototypes
-- both AND `WeakAuras.UnitExistsFixed(unit, smart) and specificUnitCheck` into the trigger
-- function, and Threat Situation ANDs `status ~= nil and ok`. No target -> no state -> the
-- whole right-hand orb is simply not there.
adopt(gTargetOrb, threat)
adopt(gTargetOrb, flash)   -- the 80% halo layers over the threat ring
local tHealth = reg(ring("Mage - Target Health", G.tHpRing, RING_TEX, COL.health,
  { unitHealthTrigger("target") }))
tHealth.subRegions[1] = pct("percenthealth", G.hpTextSize, G.hpTextY, COL.hpText)
-- Same zero-total guard as the player ring, and it earns its keep here: a target's max
-- health genuinely has not streamed in for the first moments after a target change.
tHealth.conditions = { F.condition(1, "maxhealth", "<=", "0", "alpha", 0) }
adopt(gTargetOrb, tHealth)

local tMana = reg(ring("Mage - Target Mana", G.tMpRing, RING_TEX, COL.mana,
  { unitManaTrigger("target") }))
tMana.subRegions[1] = pct("percentpower", G.mpTextSize, G.mpTextY, COL.mpText)
-- The last gap requirePowerType leaves: most NPCs report mana as their primary bar with a
-- 0/0 pool, and the prototype's total = math.max(1, UnitPowerMax(...)) floor turns that into
-- a valid 0% state — an empty ring on a powerless mob. A real caster has maxpower in the
-- thousands; a powerless unit has exactly 1, because of that floor.
tMana.conditions = { F.condition(1, "maxpower", "<=", "1", "alpha", 0) }
adopt(gTargetOrb, tMana)

local tPortrait = reg(portrait("Mage - Target Portrait", "target", G.portrait,
  { unitHealthTrigger("target") }))
adopt(gTargetOrb, tPortrait)

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
W.assertUidContinuity(cont, "mage")

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
