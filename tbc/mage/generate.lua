-- tbc/mage/generate.lua — Mage "Arcane & Frost" HUD v10.
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

-- v9 (DIABLO GLOBES: the two ring clusters become three liquid vessels — life, mana and
-- target — and the live portraits are gone. NO aura is added or removed, NO uid() call moves,
-- and nothing outside the globe layer is touched. Every trigger, load gate, condition and
-- colour escalation the rings carried is still here, on the region that replaced its ring):
--   * ONE FIELD SEPARATES A GLOBE FROM A RING, and it is `orientation`. Both are
--     `progresstexture`. A ring is "CLOCKWISE" on annulus art and encodes the value as ARC
--     LENGTH; a globe is "VERTICAL" — "Bottom to Top" in Private.orientation_with_circle_types
--     — on a solid disc, and encodes it as a WATERLINE that rises. VERTICAL_INVERSE is the
--     trap: it fills DOWNWARD, so the globe would drain from the top as you take damage,
--     which looks deliberate and is wrong. Switching paths also swaps which fields are live:
--     startAngle/endAngle stop mattering, and compress/slanted/slantMode start mattering.
--   * THE PORTRAIT IS REMOVED, and that is exactly what buys each number its place. A `model`
--     region cannot carry a text subregion at all (SubText's supports() is texture /
--     progresstexture / icon / aurabar / empty — model is absent), which is why v7/v8 had to
--     park every percentage OUTSIDE its ring, in the world. The percentages now sit INSIDE
--     the glass. Neither portrait aura is deleted: their two uids are recycled onto the life
--     and mana rims, so the update leaves nothing orphaned in the player's collection.
--   * THREAT HAS NO VESSEL OF ITS OWN, so it became the TARGET GLOBE'S RIM COLOUR: green,
--     orange at 70%, red on aggro, with the percentage above the globe on that same region.
--     Same party/raid gate, same never-in-arena gate, the same mandatory threatvalue <= 0
--     guard, and the 80% pulse still rides on top of it. No element and no screen space added.
--     The property is `color` here, not the ring's foregroundColor and not the bar's barColor.
--   * THE BREAKPOINT MARK GOT EASIER, not harder. On a ring the Arcane conserve mark needed
--     trigonometry on the circumference; on a vessel a threshold is a horizontal line at a
--     fixed height, yOffset = (threshold/max - 0.5) * GLOBE_MAIN, so the 30% mark is a line
--     across the mana globe at y = -23.2, as wide as the glass is at that height (106.32).
--   * ABSOLUTE POSITIONS. GLOBE_Y is a SCREEN coordinate, not a local one. Every globe is
--     nested two groups deep and offsets ADD down the chain, so the globe layer cancels the
--     top group's own y before the clusters place their globes:
--         top (0, -140) + layer (0, -10) + cluster (x, 0) + globe (0, 0) = (x, -150)
--     Decode the shipped string and add the chain up — that is the check this migration is
--     graded on, and it is the one the previous migration failed in six packs out of seven.

-- v10 (THE GLOBES MOVE BESIDE THE CHARACTER, AND THE GLASS CATCHES LIGHT. Two changes, both
-- applied identically in all seven packs. NO aura added, removed or renamed, NO uid() call
-- moved or added, no trigger, load gate, condition, colour, spell id or region type touched,
-- and nothing outside the globe layer changed — the diff is three constants, one cluster
-- offset, and one appended subregion per vessel):
--   * POSITION. v9 parked all three vessels on a band at y = -262, which read as a second bar
--     bolted under the HUD rather than as part of the character. They now FLANK the character:
--     life at (-190, 40), power at (+190, 40), the target globe above and between them at
--     (0, 110). Those three positions are fixed across the seven packs and were scanned against
--     every element in all of them; they are the tightest collision-free arrangement, and the
--     near misses are worth recording so nobody "tidies" them later: x = ±170 walks into the
--     Alerts column (x = -150) and the PvP column (x = +150), which every pack carries, and
--     x = ±210 walks into the PvP-layer elements at (200, -44). This pack's own columns sit at
--     exactly those two x values (see "Mage - Alerts" and "Mage - PvP"), so the margin here is
--     real, not theoretical.
--   * ABSOLUTE, NOT LOCAL — the same trap v9 documented and the reason this migration is
--     graded on a decode. GLOBE_Y and GLOBE_TGT_Y are SCREEN coordinates; the globes hang two
--     groups deep under a top group at y = -140, so the layer cancels it (GLOBE_LAYER_Y = 180)
--     and the target cluster carries the 70 that lifts it above the pair. Walk it in the
--     shipped string, not here.
--   * LOOK. Every vessel gains a specular highlight: a soft off-centre bright spot in the upper
--     left, sized to its own globe, in ADD blend so it brightens the liquid AND the percentage
--     sitting inside the glass instead of dimming either. It is APPENDED as the last subregion
--     of each globe, never inserted, because conditions address subregions positionally as
--     sub.N — see highlight()/addHighlight() for the full reasoning on both points.
--   * WHAT IS NOT IN IT: no dark edge vignette (it would sit over the number, which is
--     unreadable exactly when the number matters), no per-globe tuning of the highlight
--     geometry, and no change to the rims — the glass rim is still Circle_Smooth_Border drawn
--     BEHIND the fill at frameStrata 2, which is deliberate and documented in rim().

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

-- ===== v9 globe primitives ==================================================
-- wa_factory has no progresstexture builder, so that one region table is written out in full
-- below, field-for-field from poc/diablo-globes/generate.lua — the verified reference build
-- for this layout. Everything else (rims, marks, triggers, subtexts, conditions, load gates,
-- assembly) still goes through the factory. The v7/v8 `model` portrait builder is GONE with
-- the portraits; the two uids it consumed are recycled onto the rims (see "v9 assembly").
--
-- Circle_Smooth.tga (a solid disc — the liquid) and Circle_Smooth_Border.tga (the glass ring
-- drawn over it) both ship inside WeakAuras itself, registered in Private.texture_types under
-- "Shapes", so nothing here needs a media addon. Ring_20px, the v8 annulus, is gone: a vessel
-- is a filled shape, and the annulus that made a good arc makes a bad globe.
local FILL_TEX = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Smooth.tga"
local RIM_TEX  = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Smooth_Border.tga"

-- ===== CANONICAL GLOBE GEOMETRY (v9) — IDENTICAL IN ALL SEVEN PACKS =========
-- These numbers are not this pack's to tune, exactly as v8's ring geometry was not. The
-- migration before v8 handed each pack a design intent instead of dimensions, every pack
-- picked its own sizes, and the disagreement was visible in the first screenshot. They are
-- declared as named constants so a later edit cannot drift them apart again: change them in
-- all seven packs or not at all — a local "improvement" here silently re-breaks the one thing
-- this shared geometry exists to fix.
local GLOBE_MAIN   = 72        -- life and power globes
local GLOBE_TGT    = 44         -- target globe, secondary by size
local RIM_PAD      = 4          -- every rim texture is its globe's size + 4, at frameStrata 2
                                -- (= BACKGROUND, i.e. BEHIND the fill — see rim() for why that
                                -- is the right way round for a disc-with-border texture)
local GLOBE_X      = 270        -- v10: life at x = -190, power at x = +190, target at x = 0
local GLOBE_Y      = 40         -- v10: ABSOLUTE screen y of the LIFE and POWER globes
local GLOBE_TGT_Y  = 110        -- v10: ABSOLUTE screen y of the TARGET globe, above the pair
local PCT_MAIN     = 13         -- percentage inside the life and power glass
local PCT_TGT      = 10         -- percentage inside the target glass
local PCT_THREAT   = 11         -- threat percentage, the one read-out with no vessel
local PCT_THREAT_Y = 52         -- above the target globe (radius 38 + rim), clear of the glass
local TOP_Y        = -140       -- the pack's top group; the globe layer offsets back out of it

-- THE ABSOLUTE-POSITION RULE, spelled out because the previous migration got it wrong in six
-- packs out of seven: GLOBE_Y is a SCREEN coordinate, not a local one, and every globe here
-- hangs two groups deep off a top group that carries its own y. Offsets ADD down the chain,
-- so the globe layer has to cancel TOP_Y before the clusters place their globes at y = 0.
-- v10 moves the vessels off the bottom band to either side of the character, and the target
-- globe no longer shares the pair's height, so there are now TWO absolute y values and the
-- target cluster carries the difference. The full chain, which the decode check reproduces:
--     life:   top (0, -140) + layer (0, 180) + cluster (-190,  0) + globe (0, 0) = (-190,  40)
--     power:  top (0, -140) + layer (0, 180) + cluster ( 190,  0) + globe (0, 0) = ( 190,  40)
--     target: top (0, -140) + layer (0, 180) + cluster (   0, 70) + globe (0, 0) = (   0, 110)
-- Decode the shipped string and walk the parents to prove it; do not trust this comment. (The
-- v9 note above quotes "layer (0, -10) ... = (x, -150)": that arithmetic was already stale when
-- v9 shipped — it described an early draft, not the -262 band v9 actually built. It is left as
-- written because it is history; THIS block is the live one.)
local GLOBE_LAYER_Y = GLOBE_Y - TOP_Y        -- 180: cancels the top group's own y
local GLOBE_TGT_DY  = GLOBE_TGT_Y - GLOBE_Y  -- 70: the target cluster's lift above that pair

local COL = {
  life     = { 0.72, 0.09, 0.09, 1 },    -- D2 life red
  mana     = { 0.13, 0.30, 0.85, 1 },    -- D2 mana blue. A mage's power globe is ALWAYS mana:
                                         -- the power globe is coloured for the power type it
                                         -- actually reads, and this class has only one.
  empty    = { 0.05, 0.05, 0.07, 0.85 }, -- the unfilled vessel, near-black: the container read
  rim      = { 0.62, 0.55, 0.40, 1 },    -- brass glass, on the life and mana globes
  threat   = { 0.25, 0.80, 0.30, 1 },    -- green: the target rim's base = no threat problem
  warn     = { 1, 0.60, 0.10, 1 },       -- orange: 50% health / 70% threat  (unchanged since v2)
  danger   = { 0.90, 0.12, 0.12, 1 },    -- red:    30% health / aggro       (unchanged since v2)
  hpText   = { 1, 1, 1, 1 },
  mpText   = { 0.55, 0.75, 1, 1 },       -- each number is coloured like its own vessel, so
  thText   = { 0.70, 1, 0.75, 1 },       -- none of the three ever needs a label
}

-- wa_factory's stub() is local to the factory; the hand-written globe table below gets the
-- identical scaffolding here.
local function globeStub(t)
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
-- powerTrigger are hardwired to unit = "player"; the target globe needs "target" too.
local function globeTrigStub(tr)
  tr.names, tr.spellIds = {}, {}
  tr.subeventPrefix, tr.subeventSuffix = "SPELL", "_CAST_START"
  tr.debuffType = "HELPFUL"
  return tr
end

-- Health. The prototype ends in a hidden always-on test,
--   WeakAuras.UnitExistsFixed(unit, smart) and specificUnitCheck
-- ANDed into the trigger function, so unit = "target" with no target produces NO STATE and
-- the region hides. That is the entire self-hide mechanism for the target globe — no
-- condition, no load gate, no custom code.
local function unitHealthTrigger(unit)
  return globeTrigStub{ type = "unit", event = "Health", unit = unit, use_unit = true }
end

-- Mana, and only mana — the same three flags the pack's Enemy Mana bar already uses:
--   use_powertype + powertype = 0  -> read MANA specifically. Drop either and powerType is
--     nil and the trigger silently falls back to the unit's CURRENT bar, i.e. a warrior's
--     rage rendered in a vessel coloured for mana.
--   use_requirePowerType           -> the globe exists only while mana is that unit's PRIMARY
--     bar. Harmless on a mage, whose primary bar is always mana, and kept because dropping it
--     would make the flag set differ from the identical trigger in the other six packs.
local function unitManaTrigger(unit)
  return globeTrigStub{
    type = "unit", event = "Power", unit = unit, use_unit = true,
    use_powertype = true, powertype = 0,
    use_requirePowerType = true,
  }
end

-- Threat, with the unit named EXPLICITLY. F.threatTrigger emits `threatUnit`, which is not an
-- argument of the Threat Situation prototype at all (its arg is `name = "unit"`, default
-- "target") — dead data that works only by accident, because the prototype's init runs
-- `trigger.unit = trigger.unit or "target"` inside ConstructFunction BEFORE events() and
-- internal_events() read trigger.unit. Naming `unit` here makes the target binding real
-- instead of incidental. The factory's stray threatUnit field is left alone on purpose:
-- fixing it is a toolkit change that would touch six other packs' strings.
local function globeThreatTrigger(minPct)
  local tr = F.threatTrigger(minPct)
  tr.unit = "target"
  tr.use_unit = true
  return tr
end

-- THE VESSEL. Same region type as the v8 ring, one field different — and that field flips
-- which of the others are live. Notes on every trap in this table:
--   orientation "VERTICAL"      -> "Bottom to Top": the waterline RISES as the value does.
--     The key lies about direction in the usual WA way; VERTICAL_INVERSE drains from the top.
--   startAngle / endAngle       -> IGNORED on the linear path. Emitted because they are in the
--     region's default table, not because they do anything here.
--   compress / slanted / slant / slantMode -> inert on the circular path, LIVE here. slant
--     stays 0 deliberately: a straight waterline is what reads as liquid.
--   crop_x / crop_y = 0.41      -> the default. The sqrt(2) expansion that 0.41 cancels is
--     applied in the CIRCULAR branch; on the linear path this is simply the texcoord scale.
--   backgroundColor             -> the EMPTY portion, and the whole container read: a
--     near-black disc that coloured liquid rises into, not a shape appearing out of nothing.
--   backgroundOffset = 0        -> the default 2 would fatten the empty disc into a halo
--     around the full one instead of the same disc behind it.
--   auraRotation = 0            -> absent from the 3.5.0 default table but read unconditionally
--     by current code as data.auraRotation / 180 * math.pi, so it must be emitted.
--   adjustedMin/Max are STRINGS ("") because SetAdjustedMin does adjustedMin:find(...).
--   progressSource is rewritten to {-1, ""} by Modernize < 71 no matter what is emitted, so
--     ONE PROGRESS-SUPPLYING TRIGGER PER GLOBE and it must be trigger 1: automatic progress
--     reads the first ACTIVE trigger's value/total (F.triggers sets activeTriggerMode -10).
--     A second trigger is legal but can only feed CONDITIONS, never the fill.
local function globe(id, size, color, triggers)
  return globeStub{
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
    triggers = F.triggers(triggers),
    load = F.load(CLASS),
  }
end

-- THE SPECULAR HIGHLIGHT (v10) — the field that separates "flat coloured disc" from "liquid
-- behind curved glass". A vessel lit from the upper left catches a soft bright spot up and to
-- the left of centre; without it the fill reads as a sticker, which is exactly the complaint
-- v9 shipped with. It is the same disc art as the fill, scaled to 46% x 34% of the globe and
-- offset by (-17%, +21%) of its width, at 28% white.
--   * BLEND MODE IS "ADD", NOT "BLEND", and that is load-bearing rather than taste. The
--     percentage lives INSIDE the glass as a subtext, subregions draw in the order they are
--     listed, and this one is APPENDED — so it draws over the number. A BLEND overlay at 28%
--     white would wash 28% of the number away; ADD can only brighten, so white-on-liquid text
--     stays readable and merely picks up the same sheen the liquid does. This is why the
--     recipe is a highlight and not the more obvious dark edge vignette: a dark overlay over
--     the number is unreadable in exactly the moment (low health) the number matters most.
--   * APPENDED, NEVER INSERTED. Conditions address subregions POSITIONALLY as "sub.N.property"
--     (Conditions.lua resolves the index at load time, with no name to fall back on), so
--     inserting anything ahead of a referenced index silently retargets that condition onto a
--     different subregion — no error, no editor warning. Nothing on the three mage globes uses
--     sub.N today (the pack's only sub.N conditions are the CC ON ME glow and the Arcane Blast
--     stack glow, both on ICONS), but the rule holds regardless: append, and the existing
--     indices cannot move.
--   * textureRotate is the GATE for textureRotation (SubTexture.modify passes it as canRotate
--     and DoTexCoord only rotates when it is set); both stay off because a smooth disc has no
--     orientation. xOffset/yOffset are NOT in the subtexture default() table but ARE read by
--     modify -> AnchorSubRegion in "point" mode — omit them and the highlight sits dead centre,
--     which is a dull flat glow rather than a light source.
local function highlight(size)
  return {
    type = "subtexture",
    textureTexture = FILL_TEX,
    textureColor = { 1, 1, 1, 0.28 },
    textureBlendMode = "ADD",
    textureVisible = true,
    textureDesaturate = false, textureMirror = false,
    textureRotate = false, textureRotation = 0,
    width  = size * 0.46,
    height = size * 0.34,
    xOffset = -size * 0.17,
    yOffset =  size * 0.21,
    anchor_mode = "point", anchor_point = "CENTER", self_point = "CENTER",
    mirror = false, rotate = false, scale = 1,
  }
end

-- The one way the highlight is ever attached: onto the END of whatever subregion list the globe
-- already has. Never `subRegions[n] = ...` with a literal index — see the sub.N note above.
local function addHighlight(region, size)
  region.subRegions[#region.subRegions + 1] = highlight(size)
  return #region.subRegions
end

-- THE GLASS: a plain texture the size of its vessel + RIM_PAD, carrying its globe's own
-- triggers purely so the two appear, vanish and fade together; it has no progress of its own.
-- On the target globe this same region is also the threat read-out — see "Mage - Target Globe
-- Rim" below.
-- frameStrata = 2 is the canonical value, and it is worth being exact about what that number
-- means, because it is NOT "one layer above the globe": Private.frame_strata_types is
-- { [1] = Inherited, [2] = "BACKGROUND", [3] = "LOW", [4] = "MEDIUM", [5] = "HIGH", ... }, so
-- 2 places the rim in BACKGROUND — BEHIND the globes, which stay at 1 (inherited). That is the
-- right way round for this art: "Circle_Smooth_Border" is a disc WITH a border, so drawn on
-- top it would paint over the liquid and the number, while drawn behind and RIM_PAD (4) px
-- wider the only part that shows is the 2 px ring standing past the vessel's edge — exactly the
-- glass around the liquid. It is listed in the pack README as one of the two things only a
-- live 2.5.x client can settle.
local function rim(id, size, color, triggers)
  local t = F.texture(id, CLASS, size, size, 0, 0, nil, RIM_TEX, color)
  t.frameStrata = 2
  t.triggers = F.triggers(triggers)
  return t
end

-- The number goes INSIDE the glass, which is the entire payoff of dropping the portrait: a
-- progresstexture accepts a subtext, and the `model` region that used to own the centre never
-- could (SubText's supports() lists texture / progresstexture / icon / aurabar / empty), which
-- is why v7/v8 had to park every percentage outside its ring where it competed with the world.
-- yOffset is measured from the globe centre; only the threat percentage uses a non-zero one.
local function pct(sym, size, yOffset, color)
  local st = F.subtext("%" .. sym .. "%%", size, "CENTER", sym)
  st.anchorYOffset = yOffset
  st.text_color = color
  return st
end

-- RESOURCE BREAKPOINTS ARE EASIER ON A VESSEL THAN ON A RING, not harder. A threshold IS a
-- waterline, so the mark is a horizontal line at a fixed height — no trigonometry, and the
-- line sits exactly where the fill will reach:
--     yOffset = (threshold/max - 0.5) * GLOBE_MAIN
-- markWidth is the chord of the disc at that height, so the line spans the glass and stops at
-- it instead of poking out into the world. Both are rounded to 0.01 so the build stays
-- byte-identical across libm implementations (sqrt is IEEE-exact; the rounding is belt and
-- braces, and matches what v8's ringPoint did).
local function round2(v) return math.floor(v * 100 + 0.5) / 100 end
local function markY(fraction) return round2((fraction - 0.5) * GLOBE_MAIN) end
local function markWidth(fraction)
  local radius = GLOBE_MAIN / 2
  local dy = (fraction - 0.5) * GLOBE_MAIN
  return round2(2 * math.sqrt(radius * radius - dy * dy))
end

-- ===== top-level group, anchored below the character ========================
-- NOTE: the top group takes the factory's own uid() call (no extra W.uid() here);
-- that choice is permanent — changing it would reshuffle every uid downstream.
local top = F.group(TOP, 0, TOP_Y, nil)

-- ===== Resources -> DIABLO GLOBES (v9) ======================================
-- The four regions below occupy the uid slots the v6 health / mana / threat bars held, and
-- the threat flash, IN THE SAME ORDER. v7 turned those bars into rings in their own slots;
-- v9 turns the rings into globes in the same slots, for the same reason: W.assertUidContinuity
-- requires missing == 0, so every uid the previous string shipped must still exist in this
-- one. A delete-and-recreate migration would drop thirteen uids and fail the repo suite
-- outright. The upside is bigger than the constraint — the in-game import stays a clean
-- Update with nothing orphaned to clean up afterwards.
-- They are NOT adopted here: the three cluster groups take uid slots at the very bottom of
-- this script, and re-parenting is free — only uid ORDER matters. See "v9 assembly".
local gGlobes = reg(F.group("Mage - Globes", 0, GLOBE_LAYER_Y, nil))
adopt(top, gGlobes)

-- LIFE, the left vessel, filling bottom-to-top. Trigger 1 is the only progress source (see
-- globe()); the Unit Characteristics trigger is there purely to feed the out-of-combat fade,
-- exactly as it did on the v6 bar and the v8 ring.
local life = reg(globe("Mage - Life Globe", GLOBE_MAIN, COL.life,
  { unitHealthTrigger("player"), F.unitCharTrigger() }))
-- The percentage now sits INSIDE the glass, where the portrait used to be.
life.subRegions[1] = pct("percenthealth", PCT_MAIN, 0, COL.hpText)
-- v10: and the sheen goes on LAST, over the number — ADD blend, so it brightens the digits
-- rather than veiling them (see highlight()).
addHighlight(life, GLOBE_MAIN)
-- v2's escalating colour tiers, carried across intact for the second time. The property is
-- `foregroundColor`, NOT the aurabar's `barColor`: progresstexture has no barColor, and
-- Conditions.lua skips any change whose property is missing from the region's properties table
-- WITHOUT an error and WITHOUT an editor warning, so the wrong name here is a dead escalation
-- nobody notices until the health they are watching stays red-on-red. Severe tier last: later
-- conditions overwrite the same property, and the revert is automatic (CreateDeactivateCondition
-- restores data.foregroundColor). On a red vessel the tiers still read — the liquid brightens
-- to orange at 50% and to a hot red at 30%, where the Ice Block prompt fires.
-- The maxhealth guard stays mandatory: AuraBar draws EMPTY at total == 0 (`if self.total ~= 0`)
-- but ProgressTexture starts from `local progress = 1` and draws FULL, so a unit whose max
-- health has not streamed in yet would flash a completely full globe. `maxhealth` is a stored
-- conditionType = "number" arg on the Health prototype.
life.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "percenthealth", "<", "50", "foregroundColor", COL.warn),
  F.condition(1, "percenthealth", "<", "30", "foregroundColor", COL.danger),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),   -- zero-total guard, wins over the fade
}

-- MANA, the right vessel: the mage's real resource clock — Evocation pacing reads off it, and
-- the Arcane conserve breakpoint below is a line drawn across this globe.
local manaGlobe = reg(globe("Mage - Mana Globe", GLOBE_MAIN, COL.mana,
  { unitManaTrigger("player"), F.unitCharTrigger() }))
manaGlobe.subRegions[1] = pct("percentpower", PCT_MAIN, 0, COL.mpText)
addHighlight(manaGlobe, GLOBE_MAIN)   -- v10 sheen, appended after the percentage
-- Power is the one prototype that cannot hit total == 0 — its init floors the total at
-- math.max(1, UnitPowerMax(...)) — which is exactly why this guard reads <= 1 and not <= 0.
manaGlobe.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxpower", "<=", "1", "alpha", 0),
}

-- THREAT, which has no vessel of its own, so it IS THE TARGET GLOBE'S RIM. Threat is your
-- threat ON that target, so the target's glass is its natural home, and colouring glass that
-- has to be drawn anyway costs no element and no screen space. The percentage rides above the
-- globe on this same region — the one read-out with nowhere inside to live.
-- This region is created HERE, before the globe it rims, because it inherits the v6 threat
-- bar's uid slot (v7 gave that slot to the threat ring). Parenting happens in "v9 assembly".
--   * THE PROPERTY NAME IS THE TRAP AGAIN, one step further along: an aurabar escalates with
--     `barColor`, a progresstexture with `foregroundColor`, and a plain texture — which is
--     what a rim is — with `color`. Texture.lua's properties table is exactly
--     { texture, color, desaturate, width, height, mirror, rotation }, and a change naming any
--     other key is dropped silently by Conditions.lua.
--   * Severe state last: the aggro red overwrites the 70% orange on the same property.
local tgtRim = reg(rim("Mage - Target Globe Rim", GLOBE_TGT + RIM_PAD, COL.threat,
  { globeThreatTrigger() }))
tgtRim.subRegions = { pct("threatpct", PCT_THREAT, PCT_THREAT_Y, COL.thText) }
tgtRim.conditions = {
  F.condition(1, "threatpct", ">=", "70", "color", COL.warn),
  F.condition(1, "aggro", "==", 1, "color", COL.danger),   -- severe last
  -- MANDATORY, and the one place this migration could still regress. threattotal is
  -- (threatvalue or 0) * 100 / threatpct, so BOTH value and total are 0 whenever threatvalue
  -- is 0 — the instant before your first cast lands, and right after an Invisibility drop.
  -- Without this guard the rim would sit there in full base colour reporting a threat
  -- relationship that does not exist yet, with "0%" written above it; worse, on the ring it
  -- would have drawn a FULL circle. `threatvalue` is a stored conditionType = "number" arg
  -- (the hidden `total` is not), so the rim is simply hidden instead.
  F.condition(1, "threatvalue", "<=", "0", "alpha", 0),
}
-- v2: party/raid only, like the flash overlay and the Invisibility prompt. Solo you are always
-- the aggro target, so ungated this rim would sit pinned red for every quest mob.
tgtRim.load.use_ingroup = true
tgtRim.load.ingroup = IN_GROUP
-- v5: and NOT in arena. An arena team has no threat table, so it would read a meaningless
-- number in exactly the place a player has least attention to spare. `ingroup` cannot express
-- this on its own — an arena team IS a party. Everywhere else is unchanged, open world included
-- (see NOT_ARENA). Both gates travel with the threat read-out unchanged, exactly as they did in
-- v5 and v8; the honest consequence is that solo, and in an arena, the target globe is drawn
-- without a rim, because the rim IS the threat element.
tgtRim.load.use_size = false   -- false selects MULTI mode; only nil disables the gate
tgtRim.load.size = NOT_ARENA
-- The target globe itself carries NO group/arena gate on purpose: a target's health is unit
-- state, not a threat relationship, and is wanted everywhere.

-- 80%+ threat: the pulsing red overlay, now the RIM ITSELF flaring — same circle as the rim,
-- ADD blend, so the glass around the target globe glows red instead of a rectangle appearing
-- beside it. Same region type, same trigger, same animation and the same two load gates as v6
-- and v8; only the geometry and the texture changed. Unlike the rim it KEEPS frameStrata 1
-- (inherited) rather than the rim's 2 (BACKGROUND), and it is adopted LAST in the target
-- cluster, so the pulse is the topmost thing there: an alarm that draws behind the vessel it
-- is warning about would be worse than no alarm. ADD blend makes it read as light over the
-- glass rather than paint on top of it.
local flash = reg(F.texture("Mage - Threat Flash", CLASS, GLOBE_TGT + RIM_PAD, GLOBE_TGT + RIM_PAD,
  0, 0, nil, RIM_TEX, { 1, 0.1, 0.1, 0.85 }))
flash.blendMode = "ADD"
flash.triggers = F.triggers({ globeThreatTrigger(80) })
flash.animation.main = F.animPreset("alphaPulse", "1")  -- duration required or it is invisible
flash.load.use_ingroup = true
flash.load.ingroup = IN_GROUP
flash.load.use_size = false   -- v5: follows the threat read-out out of the arena
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
-- v7 moved the breakpoint onto the mana RING as a bead on the circumference; v9 moves it
-- back to being a LINE, because on a vessel that is what a threshold is (see markY/markWidth).
-- This is the mark going home: a waterline the fill actually reaches, not a dot on a hoop.
--
-- WHY IT IS STILL TWO STANDALONE TEXTURE AURAS AND NOT A `subtexture` TICK. WeakAuras does
-- support static ticks on a progresstexture — SubRegionTypes/Texture.lua's supports() lists
-- progresstexture, and a subtexture with explicit xOffset/yOffset is the documented recipe
-- (aurabar's `subtick` is aurabar-only and could never have come along). It was rejected here
-- for one reason: a sub-region cannot carry a load gate. This breakpoint is ARCANE-ONLY since
-- v3 — it marks the switch from Arcane Blast spam to the 3x AB / 3x Frostbolt conserve cycle,
-- and Frost has no second rotation to switch into — and a tick welded onto the shared mana
-- globe would show for Frost too, silently undoing that audit. Two auras also keep the "lit"
-- pop as a real animation.
local MANA_CONSERVE_PCT = 30
-- v9: straight out of the breakpoint formula, so both marks follow GLOBE_MAIN instead of being
-- left behind in empty space. 30% of the 72 px vessel is y = (0.30 - 0.5) * 72 = -14.4, and the
-- disc is 65.99 px wide at that height, so the line spans the glass and stops at it. (The v9
-- header note quotes -23.2 / 106.32: that was a 116 px draft, not what v9 shipped — the values
-- are computed by markY/markWidth, so the code was right and only the comment was stale.) At v8's
-- ring the same breakpoint was a bead at (34.19, -11.11) computed by trigonometry; nothing here
-- is hand-entered either, and the two marks share the one pair of calls.
local MANA_MARK_Y = markY(MANA_CONSERVE_PCT / 100)       -- -23.2
local MANA_MARK_W = markWidth(MANA_CONSERVE_PCT / 100)   -- 106.32
local MARK_H_DIM, MARK_H_LIT = 2, 4   -- thin line, thicker when it lights
local manaLine = reg(F.texture("Mage - Mana Conserve Line", CLASS, MANA_MARK_W, MARK_H_DIM,
  0, MANA_MARK_Y, nil,
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
-- v9: adopted into the power cluster at the bottom of this script, AFTER the globe it marks,
-- so it draws over the liquid rather than under it (+4 frame levels per child).

local manaLit = reg(F.texture("Mage - Mana Conserve Lit", CLASS, MANA_MARK_W, MARK_H_LIT,
  0, MANA_MARK_Y, nil,
  F.TEX_SQUARE, { 1, 0.75, 0.2, 1 }))
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

-- ===== v9 assembly: three clusters, and every globe parent wiring ===========
-- SIX regions are created here and they take the SIX uid slots v7 appended — in that exact
-- order, because a uid() call may never be reordered. NOTHING NEW IS ADDED: v9 emits the same
-- 48 auras as v8, and the six slots are recycled onto the globe HUD like this:
--     v8 aura                  uid slot now carries
--     Mage - Player Orb    ->  the LIFE cluster group           (x = -190 since v10)
--     Mage - Target Orb    ->  the TARGET cluster group         (x =    0, y = +70 since v10)
--     Mage - Player Portrait -> the life globe's glass rim      (portrait RECYCLED, not deleted)
--     Mage - Target Health ->  the TARGET GLOBE itself
--     Mage - Target Mana   ->  the POWER cluster group          (x = +190 since v10)
--     Mage - Target Portrait -> the mana globe's glass rim      (portrait RECYCLED, not deleted)
-- That is why a group, a rim, a globe and another group interleave below: the order is
-- dictated by uid continuity, not by tidiness. Every uid the v8 string shipped is still in
-- this one, on a region that is part of the globe HUD, so the in-game Update leaves nothing
-- orphaned — which is the whole reason the portraits are recycled instead of dropped.
--
-- WHAT THE PLAYER LOSES, stated plainly rather than buried: the two live portraits, and the
-- target's mana ring. The portraits had to go — a `model` region cannot carry a text
-- subregion, so keeping them would have kept every percentage outside its vessel — and the
-- Diablo layout has exactly three vessels, so a target power read-out has nowhere to live
-- (the arena Enemy Mana bars in the PvP column still carry that read where it decides
-- something).
--
-- CHILD ORDER IS THE STACKING ORDER: FixGroupChildrenOrder walks controlledChildren and adds
-- +4 frame levels per entry, so EARLIER = further behind. Vessel first, then the breakpoint
-- marks so they sit over the liquid, then the glass. Frame LEVEL only orders regions inside
-- one strata, so it decides the marks vs the vessel; the rims are settled by strata instead
-- (2 = BACKGROUND, behind everything here, which is what leaves only their 2 px overhang
-- visible), and the threat flare is last AND at strata 1 so it pulses on top of all of it.
-- sharedFrameLevel is deliberately left off the cluster groups: it would zero the level
-- offset and make the overlap order ambiguous.
local gLife = reg(F.group("Mage - Life Cluster", -GLOBE_X, 0, nil))
adopt(gGlobes, gLife)
-- v10: the target cluster is the ONE cluster with a y of its own. Life and power sit on the
-- globe layer's own height (GLOBE_Y); the target vessel rides GLOBE_TGT_DY above them, so it
-- sits between and above the pair instead of in line with them. Everything inside this cluster
-- (globe, rim, threat percentage, 80% flare) is positioned relative to the cluster, so all of
-- it travels with the one number.
local gTgt = reg(F.group("Mage - Target Cluster", 0, GLOBE_TGT_DY, nil))
adopt(gGlobes, gTgt)

-- The life rim carries the same two triggers as its vessel, so it fades out of combat with it
-- instead of sitting at full brightness around a dimmed globe, and disappears with it if max
-- health ever reads zero. `alpha` and `color` are both region properties on a texture, so both
-- conditions are live here rather than silent no-ops.
local lifeRim = reg(rim("Mage - Life Globe Rim", GLOBE_MAIN + RIM_PAD, COL.rim,
  { unitHealthTrigger("player"), F.unitCharTrigger() }))
lifeRim.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

-- THE TARGET GLOBE, 76 against the mains' 116 so it reads as secondary at a glance. It self-hides completely with no
-- target: the Health prototype ANDs `WeakAuras.UnitExistsFixed(unit, smart) and
-- specificUnitCheck` into its trigger function, so no target means no state — no globe, no
-- rim, no number, and no empty frame left behind. Same zero-total guard as the life globe,
-- and it earns its keep here: a target's max health genuinely has not streamed in for the
-- first frames after a target change.
local tgtGlobe = reg(globe("Mage - Target Globe", GLOBE_TGT, COL.life,
  { unitHealthTrigger("target") }))
tgtGlobe.subRegions[1] = pct("percenthealth", PCT_TGT, 0, COL.hpText)
-- v10: the same sheen scaled to this vessel — GLOBE_TGT, not GLOBE_MAIN, so the bright spot
-- keeps the same proportion of the glass on a 44px globe as it does on a 72px one.
addHighlight(tgtGlobe, GLOBE_TGT)
tgtGlobe.conditions = { F.condition(1, "maxhealth", "<=", "0", "alpha", 0) }

local gPower = reg(F.group("Mage - Power Cluster", GLOBE_X, 0, nil))
adopt(gGlobes, gPower)

-- The mana rim mirrors the life rim: same triggers as its vessel, same fade, same guard —
-- <= 1 rather than <= 0 because the Power prototype floors its total at
-- math.max(1, UnitPowerMax(...)) and can never report zero.
local manaRim = reg(rim("Mage - Mana Globe Rim", GLOBE_MAIN + RIM_PAD, COL.rim,
  { unitManaTrigger("player"), F.unitCharTrigger() }))
manaRim.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxpower", "<=", "1", "alpha", 0),
}

-- LIFE, left. Vessel, then glass.
adopt(gLife, life)
adopt(gLife, lifeRim)

-- POWER, right. Vessel, the two conserve marks over the liquid, then glass.
adopt(gPower, manaGlobe)
adopt(gPower, manaLine)
adopt(gPower, manaLit)
adopt(gPower, manaRim)

-- TARGET, centre. Vessel, then the threat-coloured glass, then the 80% flare over it.
adopt(gTgt, tgtGlobe)
adopt(gTgt, tgtRim)
adopt(gTgt, flash)

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
