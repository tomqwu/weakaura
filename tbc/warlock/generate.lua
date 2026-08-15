-- generate.lua — Warlock TBC All-Specs HUD (v9).
-- Run: lua5.1 generate.lua   (works from any cwd; paths resolve from this file)
-- Produces all-specs.txt: a "!WA:2!" string importable in game (/wa -> Import).
--
-- Design: proven rogue-pack skeleton adapted to warlock. One pack for
-- Affliction / Demonology / Destruction: every spec-specific piece loads
-- through a spellknown gate, so the HUD auto-adapts on respec.
-- Every spell ID verified on wowhead.com/tbc (aura triggers carry ALL rank
-- ids as strings; cooldown triggers use the numeric rank-1 id) -> zhCN-safe.
-- Zero custom code anywhere in this pack.
--
-- v2 (rotation review fixes):
--   * NEW Demonic Sacrifice MISSING prompt — the 0/21/40 SM-Ruin loop's first
--     line, and the only thing that turns the Fel Domination icon into a press.
--   * NEW Fel Armor MISSING prompt — priority line 1 of every spec's guide.
--   * Soulshatter prompt moved from threat 70% to 90%: at 70% a good caster is
--     just doing their job, so the old prompt was lit for most of a fight.
--   * Threat bar gets the party/raid gate + out-of-combat fade its siblings and
--     its own flash overlay already had (solo you are always at 100%).
--   * Health bar flips amber at 60%, the other half of the Life Tap decision.
--   * Curse slot also feeds on Curse of Recklessness / Curse of Tongues.
--   * Refresh glow moved 2s -> 1.5s (real cast time of Immolate w/ Bane and UA);
--     the three instant-recast DoTs lost their inert, unreachable glow layer.
--   * spellknown gates added to Death Coil, Shadow Trance and Backlash.
--
-- v3 (per-spec load audit — "does this spec PRESS it", not "can it CAST it"):
--   * Demonic Sacrifice MISSING is now INVERSE-gated on Soul Link (19028), so it
--     never loads for a Felguard Demonology lock. Demonic Sacrifice is a 1-point
--     prerequisite tax on the way to Soul Link in every Felguard build — the
--     talent is known and the button must never be pressed. v2 leaned on the
--     live "Soul Link buff absent" trigger for that, which inverted at the worst
--     moment: when the Felguard died, the buff dropped and the HUD told a
--     Demonology lock to burn the pet the whole spec is built on. The trigger
--     stays as the graceful pre-WA-5.4.0 fallback (see gateNot note below).
--   * No other element changed: the three ungated DoTs were audited against the
--     current guides and all three appear in all three specs' priority lists.
--
-- v4 (PvP layer — arena and battleground only):
--   * NEW "Warlock - PvP" column (mirrors Alerts on the other side) plus two
--     new prompts in the Alerts flow. Nine auras, EVERY one of them carrying
--     its own instance-size load gate, so a PvE warlock sees the v3 HUD
--     unchanged — nothing new loads in a raid, a dungeon or the open world.
--   * The fear economy is the layer's centre of gravity: your own damage
--     breaks your own Fear, so "my CC out, per opponent, with remaining" is
--     the highest-press-frequency element in the pack.
--   * This is NOT diminishing-returns tracking. DR does not exist anywhere in
--     WeakAuras (no prototype, no library), and an 18 s "DR timer" models the
--     reset window rather than the category state, so it is wrong the moment
--     two spells share a category. Nothing here pretends otherwise.
--
-- v5 (three verified findings applied — see the notes at each site):
--   * CC ON ME is now COLOUR-CODED by controlType. The glow colour is driven by
--     nine conditions on the property "sub.1.glowColor", which is verified live:
--     the subglow is subRegions[1], it is built with a colour (so useGlowColor
--     is true — with it false the setter runs and nothing changes on screen),
--     and glow is already true, which is what lets SetGlowColor restart it.
--     Colours are byte-identical to the mage pack's so a player who rolls both
--     learns one language: red stun, purple fear, blue root, green confuse,
--     amber silence/lockout.
--   * Threat bar and threat flash no longer load in an ARENA. There is no "not
--     arena" load key, so the complement is enumerated on the `size` arg —
--     including `none`, which is the literal string the client reports in the
--     open world, so every PvE case is unchanged.
--   * NEW per-opponent Enemy Mana row (arena only): the Power prototype's unit
--     arg accepts "arena" on 2.5.x and clones one row per opponent. This is the
--     Drain Mana / Curse of Tongues readout the v4 notes deferred as unverified.
--
-- v6 (the cooldown row shows what you CANNOT press):
--   * Every icon in the cooldown row becomes genericShowOn = "showOnCooldown".
--     The row is a dynamic group, so the gap closes and ABSENCE IS THE READOUT:
--     an empty row means every cooldown you own is up, and two icons mean
--     exactly two things are down, both counting themselves back. The old row
--     was inverted — seven icons on screen at all times, busiest exactly when
--     the warlock had fewest options — and a warlock knows their own spellbook.
--   * The "onCooldown == 1 -> desaturate" condition goes with it: under
--     showOnCooldown every visible icon is on cooldown by definition, so
--     desaturating them all would grey the whole row and make the icons harder
--     to tell apart. Full colour plus the swipe reads better.
--   * NO icon here is exempt, because the exemption is for press-on-cooldown
--     ROTATIONAL buttons, whose ready-glow is the instruction and cannot fire
--     from a hidden icon (paladin Judgement/Crusader Strike, druid Mangle,
--     priest Mind Blast). The warlock's press-on-cooldown loop is Shadow Bolt /
--     Incinerate and the DoTs — none of which has a cooldown, and all of which
--     are already rendered by the DoT row and the Alerts flow. Every one of the
--     seven row icons is situational, and TBC (not Wrath, not retail) is
--     explicit about the two that look rotational:
--       - Conflagrate CONSUMES your Immolate, so firing it on cooldown is a
--         DPS loss. Icy Veins: "Do NOT use Conflagrate on cooldown or at the
--         end of your Immolate" — use it "only if you have to move and if you
--         do not need to Life Tap". It is a movement answer, and v2 already
--         wrote that into the README; a glow every 10 s would be an instruction
--         to eat your own DoT.
--       - Shadowburn costs a Soul Shard and eats Improved Shadow Bolt charges;
--         the same guide reserves it for "you cannot finish a Shadow Bolt or
--         you are moving", i.e. movement filler, execute and PvP burst windows.
--       - Amplify Curse (3 min) only pays off on a Curse of Agony/Doom you are
--         usually not assigned, Fel Domination (15 min) is the pet emergency,
--         Shadowfury and Howl of Terror are CC, Death Coil is CC/self-heal.
--     So this pack, like the rogue's, adds zero glows: not one row icon is a
--     press-on-cooldown button. Note the latent subglow the icon prototype puts
--     at subRegions[1] is left exactly where it is (glow = false, no condition
--     reaches it) — nothing was inserted or reordered, so no sub.N condition
--     anywhere in the pack changed meaning.
--   * Not one W.uid() call was added, removed or reordered: v6 is a trigger and
--     condition change on seven existing auras, so all 38 uids are stable and a
--     v5 import offers Update.
--
-- v7 (the centre of the screen is given back):
--   * The 172x14 health / mana / threat bar stack is GONE from under the
--     crosshair. In its place: two unit ORBS flanking the character — a live
--     portrait ringed by concentric progress arcs, the player's at x = -260 and
--     the target's at x = +260, with the percentages on one shared baseline
--     underneath. The centre column now carries only the DoT row and the
--     cooldown row, which is the whole point of the change.
--   * Nothing the bars signalled was dropped. Health still flips amber at 60%
--     and mana still tints violet under 30% (the two halves of the Life Tap
--     decision, now two concentric arcs on one orb); threat is still green ->
--     orange at 70% -> red on aggro, still party/raid-only and still absent in
--     an arena, and its 80% flash is still there as a pulsing halo instead of a
--     bar overlay. Every arc also dims to 50% out of combat as the bars did.
--     The colour PROPERTY changed name — progresstexture has foregroundColor,
--     not the aurabar's barColor, and a mechanically ported barColor is a silent
--     no-op — so each escalation was re-pointed, not copied.
--   * GAINED, because the layout makes them free: the target's own health and
--     mana arcs (a warlock reads both — Drain Soul range, and whether a caster
--     target is worth Curse of Tongues), and two live 3D portraits.
--   * The target orb self-hides completely with no target, through the Health
--     prototype's built-in UnitExistsFixed test — no condition, no load gate.
--   * Every arc carries an explicit zero-total alpha guard. This is the one
--     genuine regression risk in the move, and it is silent: an aurabar with
--     total == 0 draws EMPTY, a progresstexture with total == 0 draws FULL. See
--     the long note in the Resources section.
--   * The five bar-stack auras are CONVERTED IN PLACE — same uids, so a v6
--     import offers Update and there is nothing left over to delete. Six new
--     auras (both cluster groups, both portraits, the target's health and mana
--     arcs) are built at the very bottom of this file, after every existing
--     uid() call, so all 38 v6 uids are byte-for-byte stable.
--
-- v8 (one orb size across all seven class packs — geometry and texture only):
--   * Every pack invented its own orb dimensions in v7, and inside this pack the
--     player cluster (96 outer) and the target cluster (128 outer) did not match
--     each other either, which is what read on screen as "the sizes are uneven".
--     The whole repo now shares ONE canonical set, declared as named constants at
--     the top of the orb section so the next edit cannot drift them apart again:
--       ORB_OUTER 104 / ORB_MID 78 / ORB_INNER 54 / PORTRAIT 46,
--       clusters at (-260, -60) and (+260, -60).
--     Ring assignment is what makes the two sides match: the PLAYER shows health
--     on the outer ring and mana on the mid ring; the TARGET shows threat on the
--     outer ring, health on the mid and mana on the inner. Both clusters
--     therefore present the same outer diameter and the same face size, and the
--     target simply nests one more ring inside.
--   * Ring_10px -> Ring_20px everywhere (arcs and halo). At 104 px the 10px art
--     drew a ~4 px wire; the 20px annulus reads as a band at these diameters.
--   * The readouts move onto the canonical baseline shared by every pack: health
--     14 pt at y = -60 (just under the 104 ring), power 11 pt at y = -76, threat
--     11 pt at y = +60 above the orb. Both clusters use the SAME offsets, which
--     they can because every ring is concentric on one centre — the target's
--     health number clears the threat ring by sitting under the outer radius, not
--     by being pushed further down as it was in v7.
--   * NOTHING ELSE CHANGED: not one trigger, load gate, condition, colour, spell
--     id or region type, and no aura was added, removed, renamed or reordered.
--     Not a single W.uid() call moved, so a v7 import offers Update and every one
--     of the 44 uids is byte-for-byte stable.
--
-- v9 (DIABLO GLOBES replace the ring orbs — geometry, region layout and threat):
--   * The concentric-ring orbs are gone. In their place three VESSELS that fill
--     bottom-to-top like liquid: LIFE at x = -300, POWER at x = +300, TARGET
--     between them at x = 0, all three centred on the ABSOLUTE screen line
--     y = -150. Same `progresstexture` region as the rings; the field that
--     changes everything is `orientation = "VERTICAL"` ("Bottom to Top"), which
--     switches the region from the circular fill path to the LINEAR one.
--   * The canonical numbers are shared byte-for-byte with the other six packs
--     and are declared as named constants below: 116 main / 76 target, rim =
--     globe + 6 at frameStrata 2, x = ∓300 / 0, ABSOLUTE y = -150, percentages
--     18 / 13 pt inside the glass and 11 pt above the target globe.
--   * GLOBE_Y IS ABSOLUTE. The clusters hang under `top` (0, -140) and
--     `Warlock - Resources` (0, +56), so the cluster offset is DERIVED —
--     CLUSTER_Y = GLOBE_Y - TOP_Y - RES_Y = -66 — rather than typed. Applying
--     -150 locally would have landed the globes at y = -234.
--   * THE PORTRAITS ARE GONE, and that is what buys the numbers their place:
--     a `model` region cannot carry a text subregion (SubText's supports() lists
--     texture / progresstexture / icon / aurabar / empty, never model), which is
--     the only reason v7/v8 had to park the percentages outside the rings. With
--     the face removed the middle of each vessel is free and the number sits
--     inside the glass, where the eye already is.
--   * THREAT HAS NO VESSEL, so it becomes the TARGET GLOBE'S RIM COLOUR: green,
--     orange at threatpct >= 70, red on aggro (most severe last, exactly as the
--     ring escalated), with the percentage above the globe. No extra element and
--     no extra screen space. Its party/raid gate, its not-in-an-arena gate, the
--     out-of-combat fade and the mandatory `threatvalue <= 0 -> alpha 0` guard
--     are carried across unchanged. A second, brass rim sits underneath it so the
--     target globe still has a rim when threat does not load (solo, arena) or has
--     not started yet.
--   * The colour property on a TEXTURE region is `color` (setter "Color"), the
--     counterpart of a progresstexture's `foregroundColor`; the aurabar's
--     `barColor` is a silent no-op on both. The threat rim's escalation was
--     re-pointed at `color`, not copied.
--   * NOT ONE W.uid() CALL WAS ADDED, REMOVED OR REORDERED. All eleven orb-era
--     auras are recycled in place — the two player rings become the life and
--     power globes, the threat ring becomes the threat rim, the flash halo stays
--     a halo, and the two portraits and the target's two rings become the three
--     rims and the target globe — so every one of the 44 v8 uids is byte-for-byte
--     stable and a v8 import offers Update with nothing orphaned.
--   * Lost, and named in the README: the two live portraits, and the target's
--     mana ring (the spec ships one target vessel, and it reads health).
--
-- UID ORDER IS SACRED: the two v2 auras are built at the BOTTOM of this file so
-- every pre-v1 uid() call keeps its position in the seeded stream. v3 is a
-- load-gate-only change: no aura added, removed, renamed or reordered. v4's
-- nine auras are built after them, at the very bottom, for the same reason.
-- v5's single new aura is built below all of those, at the very end.

math.randomseed(20260813)  -- FIXED pack seed; append-only uid order across versions

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
-- wa_factory.lua locates wa_lib.lua/assets relative to arg[0]; point arg[0]
-- at the factory for the duration of the dofile so its internal paths resolve.
local factoryPath = dir .. "/../../tools/tbc-weakaura-creator/scripts/wa_factory.lua"
local realArg0 = arg[0]
arg[0] = factoryPath
local F = dofile(factoryPath)
arg[0] = realArg0
local W = F.W

local CLASS = "WARLOCK"
local TOP = "Warlock TBC - All Specs"

local byId = {}
local function reg(t) byId[t.id] = t; return t end
local function adopt(parent, child)
  child.parent = parent.id
  table.insert(parent.controlledChildren, child.id)
end

-- ===== verified spell ids (wowhead.com/tbc, fetched individually) =====
local IDS = {
  corruption = { 172, 6222, 6223, 7648, 11671, 11672, 25311, 27216 },
  -- one slot for "your curse on the target": a target can only carry one of
  -- your curses, so all six chains share a single trigger.
  curse = {
    980, 1014, 6217, 11711, 11712, 11713, 27218,  -- Curse of Agony r1-7
    603, 30910,                                   -- Curse of Doom r1-2
    1490, 11721, 11722, 27228,                    -- Curse of the Elements r1-4
    17862, 17937, 27229,                          -- Curse of Shadow r1-3
    704, 7658, 7659, 11717, 27226,                -- Curse of Recklessness r1-5
    1714, 11719,                                  -- Curse of Tongues r1-2
  },
  immolate = { 348, 707, 1094, 2941, 11665, 11667, 11668, 25309, 27215 },
  unstableAffliction = { 30108, 30404, 30405 },
  siphonLife = { 18265, 18879, 18880, 18881, 27264, 30911 },
  shadowTrance = { 17941 },  -- Nightfall proc (10 s)
  backlash = { 34936 },      -- Backlash proc (8 s)
  soulLink = { 25228 },      -- Soul Link buff aura (drops when the pet dies)
  felArmor = { 28176, 28189 },  -- Fel Armor r1-2 (30 min, lost on death)
  -- Demonic Sacrifice grants ONE of five buffs, depending on the demon burned:
  -- Imp/Burning Wish, Voidwalker/Fel Stamina, Succubus/Touch of Shadow,
  -- Felhunter/Fel Energy, Felguard/Touch of Shadow(10%). All 30 min.
  demonicSacrifice = { 18789, 18790, 18791, 18792, 35701 },
}
local GATE = {
  unstableAffliction = 30108,  -- Affliction 41 signature (rank-1 castable)
  siphonLife = 18265,          -- Affliction talent (rank-1 castable)
  soulLink = 19028,            -- Demonology talent (castable Soul Link)
  demonicSacrifice = 18788,    -- Demonology talent (castable, 1 rank)
  felArmor = 28176,            -- trained at 62 (rank-1) -> doubles as a level gate
  nightfall = 18094,           -- Affliction talent rank 1 (passive)
  backlash = 34935,            -- Destruction talent rank 1 (passive)
}
local CD = {
  amplifyCurse = 18288, felDomination = 18708, conflagrate = 17962,
  shadowburn = 17877, shadowfury = 30283, deathCoil = 6789,
  soulshatter = 29858,
}
local SHADOW = { 0.7, 0.3, 1, 1 }  -- shared shadow-purple glow

-- =====================================================================
-- CANONICAL GLOBE SPEC — BYTE-IDENTICAL IN ALL SEVEN CLASS PACKS (v9)
--
-- Declared as named constants so a later edit has to notice it is breaking a
-- shared contract. Every one of these numbers is fixed repo-wide: v7 gave seven
-- packs a design intent instead of dimensions and every pack invented its own
-- sizes, which is exactly what read on screen as "the orbs do not match".
-- DO NOT retune, scale or "improve" any of them in one pack.
-- =====================================================================

-- Bundled WeakAuras media, present for everyone with no media addon.
-- Circle_Smooth is a SOLID DISC — the liquid itself. Circle_Smooth_Border is the
-- ring drawn over it, the glass the liquid sits inside. (Ring_20px, which v8
-- used, is an annulus: correct for an arc, wrong for a vessel.)
local FILL_TEX = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Smooth.tga"
local RIM_TEX  = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Smooth_Border.tga"

local GLOBE_MAIN = 116   -- life and power globes
local GLOBE_TGT  = 76    -- target globe
local RIM_PAD    = 6     -- rim texture is its globe's size + 6, at frameStrata 2
local GLOBE_X    = 300   -- life at -X, power at +X, target at 0
local GLOBE_Y      = -280  -- ABSOLUTE screen y for all three (see the derivation below)
local PCT_MAIN   = 18    -- percentage font inside a main globe, CENTER, yOffset 0
local PCT_TGT    = 13    -- percentage font inside the target globe
local PCT_THREAT = 11    -- threat percentage, ABOVE the target globe
local PCT_THREAT_Y = 52

-- THE ABSOLUTE-POSITION RULE, and the trap it exists to close.
-- GLOBE_Y is an ABSOLUTE screen offset, not a local one. These clusters hang two
-- groups deep — `top` at (0, TOP_Y) and `Warlock - Resources` at (0, RES_Y) — and
-- WeakAuras ADDS every offset down the parent chain. Typing -150 onto the cluster
-- would put the globes at -140 + 56 - 150 = -234. So the cluster offset is
-- DERIVED from the absolute target and can never drift out of sync with it:
--   CLUSTER_Y = GLOBE_Y - TOP_Y - RES_Y = -150 + 140 - 56 = -66
-- The x chain is all zeroes above the globes, so each globe carries its own
-- GLOBE_X directly. Proven by decoding the shipped string and walking the chain.
local TOP_Y     = -140   -- top-level group, unchanged since v1
local RES_Y     = 56     -- Resources group inside it, unchanged since v1
local CLUSTER_Y = GLOBE_Y - TOP_Y - RES_Y

-- The >=80% threat halo is DERIVED, not canonical: it keeps the same 12 px
-- stand-off it has had since v7, now measured from the rim instead of the outer
-- ring (104 -> 116 becomes 82 -> 94). It is a warning overlay, not a readout.
local FLASH_RING = GLOBE_TGT + RIM_PAD + 12

-- Canonical colours. life/mana/rim/empty are the shared spec; the escalation and
-- threat colours are v8's, unchanged, so nothing has to be relearned.
local GCOL = {
  life      = { 0.72, 0.09, 0.09, 1 },     -- D2 life red
  mana      = { 0.13, 0.30, 0.85, 1 },     -- D2 mana blue. A warlock reads MANA,
                                           -- so the power globe is blue; the same
                                           -- constant table gives a rogue yellow
                                           -- energy and a warrior red rage.
  rim       = { 0.62, 0.55, 0.40, 1 },     -- brass glass
  empty     = { 0.05, 0.05, 0.07, 0.85 },  -- the unfilled vessel, near-black
  healthLow = { 0.95, 0.5, 0.15, 1 },      -- <=60%: the Life Tap health input
  manaLow   = { 0.75, 0.25, 0.95, 1 },     -- <30%: the Life Tap mana input
  threat    = { 0.25, 0.8, 0.3, 1 },
  threatHi  = { 1, 0.6, 0.1, 1 },          -- >=70%
  aggro     = { 0.9, 0.12, 0.12, 1 },      -- you pulled
  text      = { 1, 1, 1, 1 },              -- inside the glass, on red or on blue
  thText    = { 1, 0.8, 0.55, 1 },         -- above the target globe, v8's colour
}

-- ===== top-level group, anchored below the character =====
local top = F.group(TOP, 0, TOP_Y, nil)

-- =====================================================================
-- Resources — v9: THREE DIABLO GLOBES, not two ring orbs.
--
-- A ring encodes its value as ARC LENGTH around a hoop. A globe is the opposite
-- idea: the shape is a CONTAINER and the WATERLINE encodes the value. Same
-- WeakAuras region type, one different field:
--
--   orientation = "VERTICAL"   -- Private.orientation_with_circle_types: "Bottom to Top"
--
-- Watch the name, it lies about direction in the usual WeakAuras way: VERTICAL
-- fills UP, VERTICAL_INVERSE fills DOWN. Getting it backwards gives a globe that
-- drains from the top as you take damage, which looks deliberate and is wrong.
--
-- Switching from the circular fill path to the linear one also swaps which fields
-- are live:
--   * startAngle / endAngle are IGNORED on the linear path (emitted for schema).
--   * compress / slanted / slantMode were inert on a ring and are LIVE here.
--     slant stays 0 on purpose: a straight waterline is what reads as liquid.
--   * crop_x / crop_y stay at the default 0.41. On the circular path 0.41 cancels
--     a sqrt(2) expansion; on the linear path it is simply the texcoord scale.
--   * backgroundColor is the EMPTY portion, which is what sells the container
--     read — a near-black disc that coloured liquid rises into — and
--     backgroundOffset = 0 keeps the empty part exactly the same disc as the full
--     part instead of a halo around it.
--
-- LAYOUT (all three centred on the absolute line y = -150):
--   LIFE   x = -300, 116 px, red    — your health
--   POWER  x = +300, 116 px, blue   — your mana
--   TARGET x =    0,  76 px, red    — the target's health, half size so it reads
--                                     as secondary; vanishes with no target
-- Both player globes carry a real decision here and neither is decoration: Life
-- Tap trades the left vessel for the right one, so the "can I tap?" question is
-- literally "is the red one high and the blue one low" — two objects, one glance.
--
-- THE PORTRAIT IS REMOVED, and that is what pays for the numbers. A `model`
-- region cannot carry a text subregion at all (SubText's supports() gate lists
-- texture / progresstexture / icon / aurabar / empty — not model), which is the
-- only reason v7/v8 had to park the percentages outside the rings where they
-- competed with the world. With the face gone the middle of each vessel is free
-- and the percentage sits inside the glass. Diablo has no portrait either.
--
-- THREAT BECOMES THE TARGET GLOBE'S RIM COLOUR. It has no natural vessel — it is
-- not a pool that fills — so instead of inventing a fourth globe it colours the
-- glass: green, orange at 70%, red on aggro, with the percentage above. That is
-- zero extra elements and zero extra screen space, and it puts the readout on the
-- object it is about. Every gate and guard comes across untouched.
--
-- THE TRAPS, all of them silent no-ops if you get them wrong:
--   * the colour property on a PROGRESSTEXTURE is `foregroundColor`; on a TEXTURE
--     it is `color` (setter "Color"). The aurabar's `barColor` is neither, and
--     Conditions.lua skips a change whose property is not in the region's property
--     table with no error and no editor warning — so a mechanically ported
--     barColor would leave every escalation below dead.
--   * ONE PROGRESS TRIGGER PER GLOBE. Modernize (<71) rewrites every
--     progresstexture's progressSource to {-1,""} = Automatic regardless of what
--     is emitted, and Automatic reads the FIRST ACTIVE trigger's value/total. So
--     trigger 1 always supplies the fill, and the second trigger on each region
--     (Unit Characteristics) exists only to feed the out-of-combat fade.
--   * ZERO-TOTAL INVERSION: an aurabar with total == 0 draws EMPTY, a
--     progresstexture with total == 0 draws FULL (AuraBar.lua `local progress = 0`
--     vs ProgressTexture.lua `local progress = 1`). Threat hits total == 0
--     whenever threatvalue is 0 — the instant before your first cast lands, and
--     after a Soulshatter — so an unguarded threat element reads as full aggro at
--     zero threat. Every region below therefore carries an explicit zero guard as
--     its LAST condition (later conditions overwrite earlier ones on the same
--     property, so the guard must win).
--
-- UID DISCIPLINE. Not one W.uid() call is added, removed or reordered by v9. The
-- eleven orb-era auras are all recycled in place, in their existing call order:
--   Player Health ring -> LIFE globe        (same id, same uid)
--   Player Mana ring   -> POWER globe       (same id, same uid)
--   Threat ring        -> target THREAT RIM (same id, same uid)
--   Threat Flash halo  -> the same halo, on the globe's rim radius
--   Player Orb group   -> "Warlock - Player Globes"
--   Player Portrait    -> "Warlock - Life Globe Rim"
--   Target Orb group   -> "Warlock - Target Globe"
--   Target Health ring -> TARGET globe      (same id, same uid)
--   Target Mana ring   -> "Warlock - Target Rim" (the brass rim under the threat rim)
--   Target Portrait    -> "Warlock - Power Globe Rim"
-- so all 44 v8 uids are byte-for-byte stable, a v8 import offers Update, and the
-- two portraits leave no orphans behind in anyone's WeakAuras.
-- =====================================================================

local IV, TOC = 45, 20501

-- wa_factory's stub() is local to the factory, so the hand-written region tables
-- below get the identical scaffolding here.
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

-- wa_factory's healthTrigger/powerTrigger are hardwired to unit = "player", which
-- is right for the two player globes and useless for the target one, so the
-- target trigger is spelt out with the same stub fields the factory applies.
local function orbUnitTrigger(t)
  t.names, t.spellIds = {}, {}
  t.subeventPrefix, t.subeventSuffix = "SPELL", "_CAST_START"
  t.debuffType = "HELPFUL"
  return t
end

-- The Health prototype ends in a hidden always-on test,
--   WeakAuras.UnitExistsFixed(unit, smart) and specificUnitCheck
-- ANDed into the trigger function, so unit = "target" with no target produces NO
-- STATE and the region hides. That is the entire self-hide mechanism for the
-- target globe and its rims — no condition, no load gate, no custom code.
local function targetHealthTrigger()
  return orbUnitTrigger{ type = "unit", event = "Health", unit = "target", use_unit = true }
end

-- Threat, with the factory's latent bug corrected locally. F.threatTrigger emits
-- use_threatUnit/threatUnit, but the Threat Situation prototype's argument is
-- named `unit` (required, default "target") — threatUnit is dead data that has
-- only ever worked by accident, because the prototype's init() runs
-- `trigger.unit = trigger.unit or "target"` before events() reads it. Emitting
-- the real field is behaviourally identical (same string, same code path) and it
-- is what makes the `threatvalue` condition below reachable without relying on
-- that ordering. The factory itself is out of scope for this pack's change.
local function orbThreatTrigger(minPct)
  local tr = F.threatTrigger(minPct)
  tr.unit = "target"
  return tr
end

-- A VESSEL. `trigs` is the trigger list; trigger 1 always supplies the fill
-- (see the Automatic-progress note above).
local function globe(id, size, x, color, trigs)
  return orbStub{
    regionType = "progresstexture", id = id, uid = W.uid(), parent = nil,
    -- geometry
    width = size, height = size,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = x, yOffset = 0, frameStrata = 1, alpha = 1,
    -- LINEAR fill: the waterline rises. VERTICAL == "Bottom to Top".
    orientation = "VERTICAL",
    startAngle = 0, endAngle = 360,   -- ignored on the linear path; emitted for the schema
    inverse = false, mirror = false,
    -- live on the linear path, unlike on the ring: a straight waterline (slant 0)
    -- is what reads as liquid.
    compress = false, slanted = false, slant = 0, slantFirst = false, slantMode = "INSIDE",
    -- textures
    foregroundTexture = FILL_TEX, backgroundTexture = FILL_TEX, sameTexture = true,
    desaturateForeground = false, desaturateBackground = false,
    foregroundColor = color, backgroundColor = GCOL.empty,
    backgroundOffset = 0,
    blendMode = "BLEND", textureWrapMode = "CLAMPTOBLACKADDITIVE",
    crop_x = 0.41, crop_y = 0.41, rotation = 0, auraRotation = 0,
    user_x = 0, user_y = 0,
    -- progress plumbing. adjustedMin/Max are STRINGS because SetAdjustedMin
    -- does adjustedMin:find(...).
    progressSource = { -1, "" },
    useAdjustededMin = false, useAdjustededMax = false,
    adjustedMin = "", adjustedMax = "",
    smoothProgress = true, overlayclip = false, overlays = {},
    subRegions = {},
    triggers = F.triggers(trigs),
    load = F.load(CLASS),
  }
end

-- The glass, drawn OVER its vessel at frameStrata 2 so the liquid appears to be
-- inside it. It is a plain texture with no progress of its own; it carries its
-- globe's triggers purely so the two appear and vanish together.
local function rim(id, size, x, color, trigs)
  local t = F.texture(id, CLASS, size, size, x, 0, nil, RIM_TEX, color)
  t.triggers = F.triggers(trigs)
  t.frameStrata = 2
  t.subRegions = {}
  return orbStub(t)
end

-- The number goes INSIDE the vessel — the whole advantage of dropping the
-- portrait. `sym` is the stored trigger variable, which is also what makes the
-- text a rounded integer rather than 63.428571%.
local function pct(sym, size, yOffset, color)
  local st = F.subtext("%" .. sym .. "%%", size, "CENTER", sym)
  st.anchorYOffset = yOffset
  st.text_color = color
  return st
end

local gRes = reg(F.group("Warlock - Resources", 0, RES_Y, nil))
adopt(top, gRes)

-- --- LIFE globe (was the player health ring, same id and uid) ------------
-- Amber at or below 60%: the Life Tap prompt's health input, so both halves of
-- the "can I tap?" decision are readable on the globes themselves.
-- maxhealth <= 0 is the health equivalent of the threat guard: the Health
-- prototype's total is UnitHealthMax(unit) with no floor, so a unit whose max
-- health has not streamed yet would otherwise show a full vessel.
local pHealth = reg(globe("Warlock - Player Health", GLOBE_MAIN, -GLOBE_X, GCOL.life,
  { F.healthTrigger(), F.unitCharTrigger() }))
pHealth.subRegions[1] = pct("percenthealth", PCT_MAIN, 0, GCOL.text)
pHealth.conditions = {
  F.condition(1, "percenthealth", "<=", "60", "foregroundColor", GCOL.healthLow),
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

-- --- POWER globe (was the player mana ring, same id and uid) -------------
-- Violet under 30%: the visual pair of the Life Tap prompt. The globe is blue
-- because a warlock's power type IS mana — powertype = 0 is what the trigger
-- reads, and the colour must always match what the trigger reads. maxpower's
-- guard is written <= 1, not <= 0, because the Power prototype floors total at
-- math.max(1, UnitPowerMax(...)) — a powerless unit reports exactly 1.
local pMana = reg(globe("Warlock - Player Mana", GLOBE_MAIN, GLOBE_X, GCOL.mana,
  { F.powerTrigger(0), F.unitCharTrigger() }))
pMana.subRegions[1] = pct("percentpower", PCT_MAIN, 0, GCOL.text)
pMana.conditions = {
  F.condition(1, "percentpower", "<", "30", "foregroundColor", GCOL.manaLow),
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxpower", "<=", "1", "alpha", 0),
}

-- v5: "everywhere except an arena", for the threat rim and its flash halo.
-- An arena has no threat table, so both are pure clutter there — but there is
-- genuinely no "not arena" load key: the `size` load arg declares no `inverse`
-- and no `test`, so multi mode is a plain OR over raw string equality and the
-- complement has to be spelled out. The value that mattered is `none`: in the
-- open world the client reports the literal STRING "none" (GetInstanceTypeAndSize
-- returns early with "none" when you are not in an instance), not nil, so listing
-- it keeps the rim loading in Hellfire exactly as before. use_size = false is
-- MULTI mode, not "off" — only nil disables a multiselect load arg.
-- `pvp` (battleground) is kept deliberately: Alterac Valley has real NPC bosses
-- and a real threat table, so a BG threat readout is still PvE furniture that works.
-- Fresh table per aura, so the two auras never share one by reference.
local function notArenaSize()
  return { multi = {
    none = true,        -- open world / city / no instance
    party = true,       -- 5-man normal or heroic
    ten = true,         -- Karazhan, Zul'Aman
    twenty = true,      -- legal key on TBC, unreachable; listing it is free
    twentyfive = true,  -- SSC / TK / Hyjal / BT / Sunwell
    fortyman = true,    -- vanilla 40s
    pvp = true,         -- battleground (AV has NPC bosses); arena is the one omission
  } }
end

-- --- THREAT, as the target globe's rim (was the threat ring, same id/uid) -
-- Threat is YOUR threat on THAT target, so it colours the glass around that
-- target's vessel: green -> orange at 70% -> red on aggro, most severe last,
-- exactly as the ring and the bar before it escalated. The readout sits above the
-- globe so it never shares space with the percentage inside the glass. The
-- property is `color` — the texture region's colour setter, the counterpart of
-- the progresstexture's foregroundColor that the ring used.
-- Party/raid only and never in an arena, both carried over unchanged: solo you
-- are the tank on your own target, so an ungated rim sits permanently red, and an
-- arena has no threat table at all. When it does not load, the brass rim built
-- below it is what the target globe wears.
-- THE GUARD IS MANDATORY, not defensive coding — see the zero-total note at the
-- top of this section. threatvalue is a stored conditionType "number" arg; the
-- prototype's hidden `total` is not, which is why the guard is written against
-- the value rather than the total.
local threat = reg(rim("Warlock - Threat", GLOBE_TGT + RIM_PAD, 0, GCOL.threat,
  { orbThreatTrigger(), F.unitCharTrigger() }))
threat.subRegions[1] = pct("threatpct", PCT_THREAT, PCT_THREAT_Y, GCOL.thText)
threat.load.use_ingroup = true
threat.load.ingroup = { multi = { group = true, raid = true } }
threat.load.use_size = false
threat.load.size = notArenaSize()
threat.conditions = {
  F.condition(1, "threatpct", ">=", "70", "color", GCOL.threatHi),
  F.condition(1, "aggro", "==", 1, "color", GCOL.aggro),
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "threatvalue", "<=", "0", "alpha", 0),
}

-- --- 80%+ threat halo (was "Warlock - Threat Flash", same id and uid) ----
-- The v6 overlay was a 176x18 red rectangle pulsing across the threat bar; v7/v8
-- made it a pulsing ring outside the threat arc. It stays exactly that, now on
-- the globe's radius (94 vs the 82 rim, the same 12 px stand-off it has always
-- had). Same trigger, same 80% threshold, same load gates, same alphaPulse — only
-- the geometry and the texture changed. ADD blend so it reads as light over the
-- rim rather than paint on top of it.
local flash = reg(F.texture("Warlock - Threat Flash", CLASS,
  FLASH_RING, FLASH_RING, 0, 0, nil, RIM_TEX, { 1, 0.1, 0.1, 0.85 }))
flash.blendMode = "ADD"
flash.triggers = F.triggers({ orbThreatTrigger(80) })
flash.load.use_ingroup = true
flash.load.ingroup = { multi = { group = true, raid = true } }
flash.load.use_size = false
flash.load.size = notArenaSize()
flash.animation.main = F.animPreset("alphaPulse", "1")

-- =====================================================================
-- DoTs (0,-16): five 40x40 own-debuff timers on the target.
-- A gap in the row IS the refresh signal; glow = "start the recast now".
-- =====================================================================
local gDots = reg(F.group("Warlock - DoTs", 0, -16, nil))
adopt(top, gDots)

-- glowColor is passed ONLY for the icons whose conditions drive sub.1.glow: a
-- subglow no condition can ever reach is dead config, so the instant-recast
-- DoTs simply do not get the layer.
local function dotIcon(id, x, ids, glowColor)
  local icon = reg(F.icon(id, CLASS, 40, 40, x, 0, gDots.id))
  icon.triggers = F.triggers({ F.auraTrigger("target", false, ids, { ownOnly = true }) })
  icon.zoom = 0.3
  icon.subRegions = {}
  if glowColor then icon.subRegions[1] = F.subglow(false, glowColor) end  -- conditions flip sub.1.glow
  table.insert(icon.subRegions, F.subtext("%p", 14, "INNER_BOTTOM"))
  table.insert(icon.subRegions, F.subborder())
  adopt(gDots, icon)
  return icon
end

-- instant recast: disappearance is the whole signal, no lead-time glow and no
-- glow layer at all (TBC has no pandemic window — an early cue trains clipping)
dotIcon("Warlock - Corruption", -88, IDS.corruption)
dotIcon("Warlock - Curse", -44, IDS.curse)

-- hardcast: glow one CAST TIME out so the refresh lands as the DoT falls off.
-- Immolate is 1.5s with Bane 5/5 (every build that maintains it), UA is 1.5s
-- base — the old shared 2s literal fired half a second early on both.
local immolate = dotIcon("Warlock - Immolate", 0, IDS.immolate, { 1, 0.45, 0.1, 1 })
immolate.conditions = { F.condition(1, "expirationTime", "<=", "1.5", "sub.1.glow", true) }

local ua = dotIcon("Warlock - Unstable Affliction", 44, IDS.unstableAffliction, SHADOW)
ua.conditions = { F.condition(1, "expirationTime", "<=", "1.5", "sub.1.glow", true) }
ua.load.use_spellknown = true
ua.load.spellknown = GATE.unstableAffliction

local siphon = dotIcon("Warlock - Siphon Life", 88, IDS.siphonLife)
siphon.load.use_spellknown = true
siphon.load.spellknown = GATE.siphonLife

-- =====================================================================
-- Alerts (-150,96): vertical prompt flow, glowing icons, animated
-- =====================================================================
local gAlerts = reg(F.dynGroup("Warlock - Alerts", -150, 96, nil, "UP", "BOTTOM", 6))
adopt(top, gAlerts)

-- glow is ALWAYS on here: the icon appearing at all is the signal
local function alertIcon(id, glowColor, withTimer)
  local icon = reg(F.icon(id, CLASS, 40, 40, 0, 0, gAlerts.id))
  icon.zoom = 0.3
  icon.subRegions[1] = F.subglow(true, glowColor)
  if withTimer then icon.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM") end
  table.insert(icon.subRegions, F.subborder())
  icon.animation.start = F.animPreset("slidebottom", "0.3", "easeOut")
  icon.animation.finish = F.animCustom("1", { y = 150, alpha = 0, scale = 0.4 }, "easeOut")
  adopt(gAlerts, icon)
  return icon
end

-- Nightfall proc -> free instant Shadow Bolt (Affliction talent)
local trance = alertIcon("Warlock - Shadow Trance", SHADOW, true)
trance.triggers = F.triggers({ F.auraTrigger("player", true, IDS.shadowTrance) })
trance.load.use_spellknown = true
trance.load.spellknown = GATE.nightfall

-- Backlash proc -> free instant Shadow Bolt / Incinerate (Destruction talent)
local backlash = alertIcon("Warlock - Backlash", { 1, 0.55, 0.15, 1 }, true)
backlash.triggers = F.triggers({ F.auraTrigger("player", true, IDS.backlash) })
backlash.load.use_spellknown = true
backlash.load.spellknown = GATE.backlash

-- mana < 30% AND health > 60% -> Life Tap window, in combat only
local lifetap = alertIcon("Warlock - Life Tap", { 0.3, 0.55, 1, 1 }, false)
local ltMana = F.powerTrigger(0)
ltMana.use_percentpower = true
ltMana.percentpower = "30"
ltMana.percentpower_operator = "<"
local ltHealth = F.healthTrigger(60)
ltHealth.percenthealth_operator = ">"   -- flip: health ABOVE 60%
lifetap.triggers = F.triggers({ ltMana, ltHealth })
lifetap.iconSource = 0
lifetap.displayIcon = "Interface\\Icons\\Spell_Shadow_BurningSpirit"
lifetap.cooldown = false
lifetap.load.use_combat = true

-- threat >= 90% AND Soulshatter ready -> dump threat now (party/raid only).
-- 90 is the "about to pull" tier, not the "doing your job" tier: a 5 min, one
-- shard, 8%-base-health button must not be prompted for half the fight.
local shatter = alertIcon("Warlock - Soulshatter", { 1, 0.35, 0.1, 1 }, false)
shatter.triggers = F.triggers({
  F.threatTrigger(90),
  F.cdTrigger(CD.soulshatter, "Soulshatter", "showOnReady"),
})
shatter.iconSource = 0
shatter.displayIcon = "Interface\\Icons\\Spell_Arcane_Arcane01"
shatter.cooldown = false
shatter.load.use_spellknown = true
shatter.load.spellknown = CD.soulshatter
shatter.load.use_ingroup = true
shatter.load.ingroup = { multi = { group = true, raid = true } }

-- Soul Link dropped (pet died / never recast) -> Demonology, in combat only
local soullink = alertIcon("Warlock - Soul Link MISSING", { 1, 0.15, 0.15, 1 }, false)
soullink.triggers = F.triggers({
  F.auraTrigger("player", true, IDS.soulLink, { matchesShowOn = "showOnMissing" }),
})
soullink.iconSource = 0
soullink.displayIcon = "Interface\\Icons\\Spell_Shadow_GatherShadows"
soullink.cooldown = false
soullink.load.use_combat = true
soullink.load.use_spellknown = true
soullink.load.spellknown = GATE.soulLink

-- =====================================================================
-- Cooldowns (0,-66): horizontal row of what you CANNOT press (v6).
-- Each icon EXISTS ONLY WHILE ITS COOLDOWN RUNS and vanishes the moment the
-- ability is back; the dynamic group closes the gap, so an empty row means
-- everything is available. No %p subtext: the swipe (plus OmniCC) already
-- shows the number, and there is no desaturate condition either — under
-- showOnCooldown every visible icon is on cooldown, so greying them all would
-- only make them harder to tell apart.
-- =====================================================================
local gCds = reg(F.dynGroup("Warlock - Cooldowns", 0, -66, nil, "HORIZONTAL", "CENTER", 4))
gCds.animate = false
adopt(top, gCds)

-- NB: F.icon's prototype already carries a subglow at subRegions[1] (glow off,
-- no colour) and the border below is appended at [2]. Nothing in this row drives
-- sub.1.glow — see the v6 note at the top for why none of these seven is a
-- press-on-cooldown button — and the layer is deliberately left untouched rather
-- than removed, so no subregion index anywhere in the pack shifts.
local function addCD(name, spellId, gated)
  local icon = reg(F.icon("Warlock CD - " .. name, CLASS, 32, 32, 0, 0, gCds.id))
  icon.triggers = F.triggers({ F.cdTrigger(spellId, name, "showOnCooldown") })
  icon.cooldownTextDisabled = false
  icon.useTooltip = true
  icon.zoom = 0.3
  table.insert(icon.subRegions, F.subborder())
  if gated then
    icon.load.use_spellknown = true
    icon.load.spellknown = spellId
  end
  adopt(gCds, icon)
  return icon
end

-- talent CDs, spellknown-gated -> only your spec's icons appear, gaps collapse
addCD("Amplify Curse",  CD.amplifyCurse,  true)   -- Affliction (3 min)
addCD("Fel Domination", CD.felDomination, true)   -- Demonology (15 min)
addCD("Conflagrate",    CD.conflagrate,   true)   -- Destruction fire (10 s)
addCD("Shadowburn",     CD.shadowburn,    true)   -- Destruction (15 s)
addCD("Shadowfury",     CD.shadowfury,    true)   -- Destruction 41 (20 s)
-- baseline, but still gated: Death Coil is trained at 42, and the icon used to
-- render (permanently ready) for warlocks who cannot cast it yet
addCD("Death Coil",     CD.deathCoil,     true)   -- all specs (2 min)

-- =====================================================================
-- v2 maintenance-buff prompts. Built LAST on purpose: every uid() call above
-- keeps its place in the seeded stream, so re-importing offers "Update".
-- They are re-parented into the Alerts flow, which is free.
-- =====================================================================

-- Fel Armor dropped (death, or never cast) -> line 1 of every spec's priority.
-- Gated on the rank-1 id, which is trained at 62, so it never nags a leveller.
local felarmor = alertIcon("Warlock - Fel Armor MISSING", { 1, 0.15, 0.15, 1 }, false)
felarmor.triggers = F.triggers({
  F.auraTrigger("player", true, IDS.felArmor, { matchesShowOn = "showOnMissing" }),
})
felarmor.iconSource = 0
felarmor.displayIcon = "Interface\\Icons\\Spell_Shadow_FelArmour"
felarmor.cooldown = false
felarmor.load.use_combat = true
felarmor.load.use_spellknown = true
felarmor.load.spellknown = GATE.felArmor

-- Demonic Sacrifice buff gone -> resummon and re-sacrifice (this is what the
-- Fel Domination icon is FOR). Two gates, positive AND inverse:
--   + knows Demonic Sacrifice (18788, Demonology 21) — you can do it at all;
--   - does NOT know Soul Link (19028, deep Demonology) — you should.
-- Every Felguard build spends 1 point on Demonic Sacrifice purely as the
-- prerequisite for Soul Link and then never presses it (sacrificing the pet
-- deletes Soul Link, Demonic Knowledge, Demonic Tactics and Master Demonologist
-- at once), so Soul Link is an exact "keeps its demon" discriminator. A 0/21/40
-- SM-Ruin lock reaches Demonic Sacrifice but not Soul Link, and still sees it.
-- Trigger 2 ("Soul Link buff absent") is left in place: it is the pre-WA-5.4.0
-- fallback, where the unknown not_spellknown field is ignored and the prompt
-- loads for everyone again. The load gate is strictly better than the trigger,
-- because the trigger inverts exactly when the Felguard dies.
local demonsac = alertIcon("Warlock - Demonic Sacrifice MISSING", { 1, 0.15, 0.15, 1 }, false)
demonsac.triggers = F.triggers({
  F.auraTrigger("player", true, IDS.demonicSacrifice, { matchesShowOn = "showOnMissing" }),
  F.auraTrigger("player", true, IDS.soulLink, { matchesShowOn = "showOnMissing" }),
})
demonsac.iconSource = 0
demonsac.displayIcon = "Interface\\Icons\\Spell_Shadow_PsychicScream"
demonsac.cooldown = false
demonsac.load.use_combat = true
demonsac.load.use_spellknown = true
demonsac.load.spellknown = GATE.demonicSacrifice
-- Inverse gate. There is no negated form of use_spellknown (use_spellknown =
-- false means IGNORE, not "must not know"), so WA exposes a separate arg —
-- verified in Prototypes.lua's load prototype:
--   test = "not WeakAuras.IsSpellKnownForLoad(%s, %s)"
-- Needs WeakAuras 5.4.0+; older clients ignore the unknown field and fall back
-- to v2 behaviour. use_exact_not_spellknown is deliberately NOT set: with exact
-- falsy, IsSpellKnownForLoad resolves the rank-1 id through the spell name to
-- whatever rank the player actually has.
demonsac.load.use_not_spellknown = true
demonsac.load.not_spellknown = GATE.soulLink

-- =====================================================================
-- v4 PvP layer. Built LAST for the same reason v2's prompts were: every
-- uid() call above keeps its place in the seeded stream, so a v3 user gets
-- "Update" instead of a duplicate group.
--
-- Gating: the load arg is `size` ("Instance Size Type"). use_size = false is
-- NOT "off" — multiselect load args are live at both true and false and inert
-- only at nil; false selects multi mode, which ORs the listed instance types.
--   PVP   = arena OR battleground
--   ARENA = arena only. Anything reading arena1..arena5 MUST be arena-only:
--           those unit ids do not exist in a battleground, so a BG-loaded
--           arena element is a permanently blank slot.
-- Every child below carries its own gate; a group's load is not a child gate.
-- =====================================================================
local PVP   = { use_size = false, size = { multi = { arena = true, pvp = true } } }
local ARENA = { use_size = false, size = { multi = { arena = true } } }

-- GenericTrigger stub fields the factory adds to its own builders.
local function gTrig(tr)
  tr.names = {}; tr.spellIds = {}
  tr.subeventPrefix = "SPELL"; tr.subeventSuffix = "_CAST_START"
  tr.debuffType = tr.debuffType or "HELPFUL"
  return tr
end

-- ===== verified PvP game data (wowhead.com/tbc, fetched individually) =====
local PVP_IDS = {
  -- MY crowd control, all ranks. ownOnly also matches my pet's, which is why
  -- Seduction belongs in the same slot: it is one more "do not damage that
  -- unit" timer. Death Coil is here because Horror is a separate DR category
  -- and Fear -> Death Coil is the standard extension; the icon says which.
  myCC = {
    5782, 6213, 6215,           -- Fear r1-3 (10/15/20 s)
    5484, 17928,                -- Howl of Terror r1-2 (6/8 s)
    6789, 17925, 17926, 27223,  -- Death Coil r1-4 (3 s horror)
    6358,                       -- Seduction (succubus, 15 s)
  },
  -- Spell Lock r1 (19244) and r2 (19647) BOTH trigger aura 24259, a real
  -- Silence debuff with a real duration — so the go-window is read from the
  -- game rather than guessed with a combat-log timer.
  spellLock = { 24259 },
  fearWard  = { 6346 },         -- Fear Ward (3 min buff, 3 min cd)
  -- Hard stops only: buffs that make your next cast worthless. Blessing of
  -- Protection is deliberately absent — it is physical-only, and shadow
  -- damage goes straight through it.
  immunities = {
    642, 1020,                  -- Divine Shield r1-2 (10/12 s, immune all)
    498, 5573,                  -- Divine Protection r1-2 (6/8 s, immune all)
    45438,                      -- Ice Block (10 s, immune all)
    31224,                      -- Cloak of Shadows (5 s, 90% spell resist)
  },
}
-- Item ids, not names: C_Container.GetItemCooldown("...") returns nil for a
-- name and the trigger then never fires. Warlock-relevant trinkets only.
local TRINKETS = {
  30343, 30348,   -- Medallion of the Horde / Alliance, warlock (2 min)
  37865, 37864,   -- Medallion of the Horde / Alliance, any race (2 min)
  18852, 18858,   -- Insignia of the Horde / Alliance, warlock (5 min)
}
local WOTF = 7744          -- Will of the Forsaken (undead racial, 2 min)
local HOWL = 5484          -- Howl of Terror rank 1 (40 s cooldown)
local PVP_TRINKET = "42292"  -- "PvP Trinket", the spell every medallion casts
local GOLD = { 1, 0.85, 0.2, 1 }
local RED  = { 1, 0.15, 0.15, 1 }

-- The PvP column: mirrors the Alerts flow on the other side of the character,
-- so the PvE layout is untouched. Must be a dynamic group — three of its
-- children are clone sources (one row per opponent).
local gPvp = reg(F.dynGroup("Warlock - PvP", 150, 96, nil, "DOWN", "TOP", 6))
adopt(top, gPvp)

local function pvpIcon(id, w, glowColor, withTimer)
  local icon = reg(F.icon(id, CLASS, w, w, 0, 0, gPvp.id))
  icon.zoom = 0.3
  icon.subRegions = {}
  if glowColor then icon.subRegions[1] = F.subglow(true, glowColor) end
  if withTimer then table.insert(icon.subRegions, F.subtext("%p", 14, "INNER_BOTTOM")) end
  table.insert(icon.subRegions, F.subborder())
  adopt(gPvp, icon)
  return icon
end

-- --- CC ON ME (prompt) -------------------------------------------------
-- Which break works, and whether to spend it now: the icon IS the identity of
-- the effect (stun -> trinket only; fear -> trinket / Death Coil / WotF; root
-- -> never the trinket) and the countdown answers "ride it or spend it".
-- No combat gate: the opener Sap lands out of combat.
local ccme = alertIcon("Warlock - CC ON ME", RED, true)
ccme.width, ccme.height = 44, 44
ccme.triggers = F.triggers({ gTrig{ type = "unit", event = "Crowd Controlled" } })
-- v5: the glow colour now CARRIES the category, because under a 3 s stun a
-- player parses colour and never text. Property string is "sub.1.glowColor" —
-- "sub." .. <1-based index into subRegions> .. "." .. <key from the subregion
-- type's property table>. Three preconditions, all satisfied here:
--   1. the subglow really is subRegions[1] (alertIcon writes it at [1], the
--      %p subtext lands at [2] and the border at [3]) — the index is positional,
--      so never INSERT a subregion ahead of it, only append;
--   2. useGlowColor is true — F.subglow sets it whenever a colour is passed, and
--      RED is passed below. With it false SetGlowColor stores the value and the
--      glow silently keeps LibCustomGlow's default: a real no-op, not an error;
--   3. glow is already true (the icon appearing at all is the signal), which is
--      what lets SetGlowColor's `if self.glow` restart actually repaint it.
-- The value must be a 4-element ARRAY, not {r=,g=,b=,a=} — a hash serialises to
-- four nils. controlType is stored by the prototype even without use_controlType,
-- so the bare Crowd Controlled trigger above feeds these comparisons, and the
-- comparison is against the RAW key ("STUN"), never a localised label.
-- Colours are byte-identical to the mage pack's, on purpose: one language.
--   red    stun          -> the trinket is the only answer
--   purple fear          -> trinket, Death Coil or Will of the Forsaken
--   blue   root          -> a movement answer; do NOT burn the trinket on a root
--   green  confuse/poly  -> ride it, any damage breaks it (yours or a partner's)
--   amber  silence/lockout -> your Shadow school is gone, so Fear went with your
--                             damage: trinket EARLIER than you otherwise would
-- The five loss-of-control types with no condition (NONE, CHARM, DISARM, PACIFY,
-- POSSESS) fall back to the base colour, which is the same red — "trinket food".
ccme.conditions = {
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
ccme.load = F.load(CLASS, PVP)

-- --- TARGET IMMUNE (prompt) -------------------------------------------
-- Stop the burst: casting into Divine Shield / Ice Block / Cloak of Shadows
-- burns your whole DoT investment for nothing. Any caster, all ranks.
local immune = alertIcon("Warlock - TARGET IMMUNE", RED, true)
immune.width, immune.height = 44, 44
immune.triggers = F.triggers({ F.auraTrigger("target", true, PVP_IDS.immunities) })
immune.load = F.load(CLASS, PVP)

-- --- Trinket DOWN (state) ---------------------------------------------
-- Is my get-out-of-jail available. Visible ONLY while on cooldown, so absence
-- means ready and the column stays empty in the normal case. One trigger per
-- item id (itemName has no multiEntry), OR-combined.
local trinket = pvpIcon("Warlock - Trinket DOWN", 32, nil, false)
local trinketTrigs = {}
for i, itemId in ipairs(TRINKETS) do
  trinketTrigs[i] = gTrig{
    type = "item", event = "Cooldown Progress (Item)",
    use_itemName = true, itemName = itemId,
    use_genericShowOn = true, genericShowOn = "showOnCooldown",
  }
end
trinket.triggers = F.triggers(trinketTrigs, { disjunctive = "any" })
trinket.iconSource = 0
trinket.displayIcon = "Interface\\Icons\\INV_Jewelry_TrinketPVP_01"
trinket.cooldownTextDisabled = false   -- swipe number; no %p, OmniCC doubles it
trinket.desaturate = true              -- reads as "unavailable" at a glance
trinket.load = F.load(CLASS, PVP)

-- --- Will of the Forsaken DOWN (state) --------------------------------
-- Undead only, gated on the ability rather than the race. On 2.4.3 WotF does
-- not share a cooldown with the medallion, so an undead warlock genuinely
-- carries two breaks and the second one decides whether to spend the first.
local wotf = pvpIcon("Warlock - Will of the Forsaken DOWN", 32, nil, false)
wotf.triggers = F.triggers({ F.cdTrigger(WOTF, "Will of the Forsaken", "showOnCooldown") })
wotf.cooldownTextDisabled = false
wotf.desaturate = true
wotf.load = F.load(CLASS, PVP)
wotf.load.use_spellknown = true
wotf.load.spellknown = WOTF

-- --- Enemy Trinket (clone row) ----------------------------------------
-- Their trinket is down for two minutes: this is when the real fear chain
-- goes in. An INFERENCE, not a read — no API on 2.5.x exposes another
-- player's cooldowns, so the countdown starts from the cast you saw.
local etrinket = pvpIcon("Warlock - Enemy Trinket", 32, nil, false)
etrinket.triggers = F.triggers({ gTrig{
  type = "event", event = "Spell Cast Succeeded",
  unit = "arena", use_unit = true,           -- one clone per opponent
  use_spellId = true, spellId = { PVP_TRINKET },
  duration = "120",                          -- medallion cooldown, verified
} })
etrinket.iconSource = 0
etrinket.displayIcon = "Interface\\Icons\\INV_Jewelry_TrinketPVP_02"
etrinket.cooldownTextDisabled = false
etrinket.load = F.load(CLASS, ARENA)

-- --- Fear Out (clone row) ---------------------------------------------
-- The highest press-frequency element in the layer: your own DoTs break your
-- own Fear, so this is a live "do not press that button, and do not re-apply
-- Corruption on that unit" timer. One row per feared opponent.
local fearout = pvpIcon("Warlock - Fear Out", 40, SHADOW, true)
fearout.triggers = F.triggers({ F.auraTrigger("arena", false, PVP_IDS.myCC,
  { ownOnly = true, showClones = true, combinePerUnit = true, perUnitMode = "affected" }) })
fearout.load = F.load(CLASS, ARENA)

-- --- Spell Lock ON (clone row) ----------------------------------------
-- The go is open: the felhunter's silence is running on that opponent. Read
-- from the debuff itself, so the remaining time is exact for either rank.
local slock = pvpIcon("Warlock - Spell Lock ON", 40, GOLD, true)
slock.triggers = F.triggers({ F.auraTrigger("arena", false, PVP_IDS.spellLock,
  { ownOnly = true, showClones = true, combinePerUnit = true, perUnitMode = "affected" }) })
slock.load = F.load(CLASS, ARENA)

-- --- Fear Ward UP (clone row) -----------------------------------------
-- Your fear plan is dead on that unit: open with Death Coil / Howl, or bait
-- the ward first. Every priest has carried it since 2.3.
local fward = pvpIcon("Warlock - Fear Ward UP", 36, RED, false)
fward.triggers = F.triggers({ F.auraTrigger("arena", true, PVP_IDS.fearWard,
  { showClones = true, combinePerUnit = true, perUnitMode = "affected" }) })
fward.load = F.load(CLASS, ARENA)

-- --- Howl of Terror in the cooldown row --------------------------------
-- A 40 s AoE fear is an arena button, not a raid button, so it joins the row
-- only in arena or a battleground.
local howl = addCD("Howl of Terror", HOWL, true)
howl.load.use_size = false
howl.load.size = { multi = { arena = true, pvp = true } }

-- =====================================================================
-- v5's one new aura. Built at the VERY BOTTOM, after every v1/v2/v4 uid()
-- call, so all 35 existing uids keep their position in the seeded stream and
-- a v4 import offers "Update" instead of a duplicate group. It is re-parented
-- into the PvP column afterwards, which appends it to controlledChildren and
-- therefore never reorders anything above it.
-- =====================================================================

-- --- Enemy Mana (clone row, arena only) --------------------------------
-- The drain plan, made legible: one bar per mana-using opponent, with the name
-- on the left and the percentage on the right. Drain Mana, Curse of Tongues and
-- a felhunter parked on the healer are all investments that only pay off if you
-- can SEE them paying off; without this you are draining on faith and switching
-- targets on a guess. Gold under 30% is the go: that healer is one drain from
-- being a damage-free body, so stop switching and finish the pressure.
--
-- Verified shape, and every field is load-bearing:
--   unit = "arena" + use_unit -> one clone per opponent (the prototype's
--     statesParameter is "unit" and arena is a multi-unit id, so WA expands it
--     to arena1..arena5 and gives each its own cloneId). Needs the dynamic
--     group it is parented into; clones in a static group stack on one spot.
--   use_powertype = true AND powertype = 0 -> read MANA specifically. Omit
--     EITHER and powerType is nil, and the trigger silently falls back to the
--     opponent's PRIMARY bar — a rogue's energy in a bar labelled mana.
--   use_requirePowerType = true -> the row only exists while mana is that
--     opponent's primary bar, so warriors and rogues self-hide instead of
--     parking an empty slot in the column. It is enabled by use_powertype.
-- ARENA-gated, never PVP: arena1..arena5 do not exist in a battleground, so a
-- BG-loaded row would be permanently blank.
-- Honest caveat, and it is a client question the addon source cannot settle:
-- whether 2.5.x pushes UNIT_POWER_FREQUENT for arena units continuously or only
-- around ARENA_OPPONENT_UPDATE. WA re-evaluates the unit on that event either
-- way, so the worst case is a coarser refresh, never a wrong number.
local emana = reg(F.aurabar("Warlock - Enemy Mana", CLASS, 120, 12, 0, 0, gPvp.id,
  { 0.25, 0.45, 0.95, 1 }))
emana.triggers = F.triggers({ gTrig{
  type = "unit", event = "Power",
  unit = "arena", use_unit = true,
  use_powertype = true, powertype = 0,   -- 0 = Mana
  use_requirePowerType = true,
} })
emana.subRegions[2] = F.subtext("%name", 10, "INNER_LEFT")
emana.subRegions[3] = F.subtext("%percentpower%%", 10, "INNER_RIGHT", "percentpower")
emana.subRegions[4] = F.subborder("bar")
emana.conditions = {
  F.condition(1, "percentpower", "<", "30", "barColor", { 1, 0.85, 0.2, 1 }),
}
emana.load = F.load(CLASS, ARENA)
adopt(gPvp, emana)

-- =====================================================================
-- v7's six auras, still built at the VERY BOTTOM, after every v1/v2/v4/v5 uid()
-- call, so all 38 older uids keep their position in the seeded stream. v9 changes
-- WHAT each of the six is, never WHERE its W.uid() call sits:
--
--   1  Player Orb group   -> "Warlock - Player Globes"   (group, unchanged type)
--   2  Player Portrait    -> "Warlock - Life Globe Rim"  (model  -> texture)
--   3  Target Orb group   -> "Warlock - Target Globe"    (group, unchanged type)
--   4  Target Health ring -> the TARGET globe            (same id, same region type)
--   5  Target Mana ring   -> "Warlock - Target Rim"      (progresstexture -> texture)
--   6  Target Portrait    -> "Warlock - Power Globe Rim" (model  -> texture)
--
-- Recycling rather than deleting is the whole point: a deleted aura leaves an
-- orphan in the player's WeakAuras that the Update flow cannot clean up, and a
-- new uid at the end would import as a second copy alongside the old one. Every
-- region below therefore consumes exactly the uid its predecessor consumed.
--
-- Note that the POWER globe's rim is built last even though it belongs to the
-- player cluster. That is deliberate: call ORDER is what fixes the uids, and this
-- position is the one the Target Portrait held. Parenting is done afterwards in
-- the wiring block, and re-parenting is free.
--
-- The two cluster groups are static F.group()s, not dynamic ones: a dynamic
-- group ignores child x/y offsets, and the three globes are nothing but child
-- offsets around a shared centre.
--
-- SIBLING ORDER IS DRAW ORDER, exactly: FixGroupChildrenOrder walks
-- controlledChildren and adds +4 frame levels per child, so EARLIER = further
-- BEHIND. Fills first, then rims, so the glass always draws over its liquid; on
-- the target, the brass rim goes down before the threat rim that colours over it.
-- sharedFrameLevel is deliberately left off the cluster groups — it would set the
-- offset to 0 and make the overlap ambiguous.
-- =====================================================================

-- --- player cluster: BOTH player globes, at y = CLUSTER_Y ---------------
-- One group for the pair, because they are one decision. Dragging it moves the
-- life and power vessels together and keeps them on one line.
local gPlayer = reg(F.group("Warlock - Player Globes", 0, CLUSTER_Y, nil))

-- The glass over the life vessel. It carries the life globe's own triggers and
-- its own guard conditions, so rim and liquid appear, fade and vanish as one
-- object rather than leaving an empty ring floating when the fill hides.
local lifeRim = reg(rim("Warlock - Life Globe Rim", GLOBE_MAIN + RIM_PAD, -GLOBE_X, GCOL.rim,
  { F.healthTrigger(), F.unitCharTrigger() }))
lifeRim.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

-- --- target cluster: one globe, its rims and the halo -------------------
local gTarget = reg(F.group("Warlock - Target Globe", 0, CLUSTER_Y, nil))

-- Target health. No low-health escalation: nothing in v6 signalled a target's
-- health, and this pack does not invent rotation claims it cannot cite. The
-- zero-total guard is the same one the player's globe carries, and it matters far
-- more here — a freshly targeted unit whose max health has not streamed yet is
-- exactly the case that would otherwise show a full vessel.
local tHealth = reg(globe("Warlock - Target Health", GLOBE_TGT, 0, GCOL.life,
  { targetHealthTrigger(), F.unitCharTrigger() }))
tHealth.subRegions[1] = pct("percenthealth", PCT_TGT, 0, GCOL.text)
tHealth.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

-- The target globe's brass rim, drawn UNDER the threat rim. It exists because the
-- threat rim is load-gated to a party or raid outside an arena and hides itself
-- at zero threat, and a rimless vessel next to two rimmed ones reads as a bug.
-- Same size as the threat rim, so when threat is live it is covered exactly.
local tRim = reg(rim("Warlock - Target Rim", GLOBE_TGT + RIM_PAD, 0, GCOL.rim,
  { targetHealthTrigger(), F.unitCharTrigger() }))
tRim.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

-- The glass over the power vessel — built here because this is the Target
-- Portrait's uid slot (see the note at the top of this block), parented to the
-- player cluster below.
local powerRim = reg(rim("Warlock - Power Globe Rim", GLOBE_MAIN + RIM_PAD, GLOBE_X, GCOL.rim,
  { F.powerTrigger(0), F.unitCharTrigger() }))
powerRim.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxpower", "<=", "1", "alpha", 0),
}

-- --- wiring (append-only, so no uid above this line moves) --------------
adopt(gRes, gPlayer)
adopt(gPlayer, pHealth)     -- liquid first...
adopt(gPlayer, pMana)
adopt(gPlayer, lifeRim)     -- ...glass over it
adopt(gPlayer, powerRim)

adopt(gRes, gTarget)
adopt(gTarget, tHealth)     -- liquid
adopt(gTarget, tRim)        -- brass glass
adopt(gTarget, threat)      -- threat colours the glass, drawn over the brass
adopt(gTarget, flash)       -- the 80% halo, outside all of it

-- ===== assemble (v2000 nested), encode, verify =====
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

-- uid continuity vs the previous on-disk version (checked BEFORE overwriting,
-- so re-running after any future edit compares against the shipped string)
local txtPath = dir .. "/all-specs.txt"
local cont = W.uidContinuity(encoded, txtPath)
W.assertUidContinuity(cont, "warlock")

local out = assert(io.open(txtPath, "w"))
out:write(encoded)  -- single line, no trailing newline
out:close()

print(("OK: %d auras, %d chars -> all-specs.txt"):format(1 + #transmit.c, #encoded))
if cont then
  print(("uid continuity vs previous: stable=%d changed=%d parentSame=%s")
    :format(cont.stable, cont.changed, tostring(cont.parentSame)))
end
