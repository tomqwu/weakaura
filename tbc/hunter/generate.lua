-- generate.lua — Hunter TBC HUD, Beast Mastery & Survival (v14).
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
-- v11: THE GLOBES COME UP BESIDE THE CHARACTER AND THE GLASS CATCHES LIGHT. Nothing else at
-- all: not one trigger, load gate, condition, colour, spell id or region type moved, no aura
-- was added or removed (stable=53 changed=0 missing=0), and everything outside the vessels —
-- buffs, alerts, cooldown row, procs, the whole PvP layer — is byte-for-byte what v10 shipped.
--   * POSITION. v10 parked all three globes on one band at absolute y = -262, which reads as
--     a separate bar bolted under the HUD rather than as part of the character. They now
--     FLANK them: life at (-190, +40), power at (+190, +40), the target globe above and
--     between at (0, +110). Those three coordinates are the tightest collision-free
--     arrangement available in this repo's shared layout and were scanned against every
--     element in all seven packs — x = ±170 hits the Alerts column at -150 and the PvP
--     column at +150, x = ±210 hits the PvP layer's elements at (200, -44).
--     The target cluster is now the only thing at a different height, so ITS GROUP carries
--     the 70px difference and every child rides along; nothing below the canon block names a
--     coordinate, and the position proof at the bottom of this file walks each parent chain
--     and refuses to write a string whose globes land anywhere else.
--   * LOOK. A flat-coloured disc reads as a sticker; a sphere reads as one because light
--     strikes its curve off centre. Every vessel — including the target's 22px power globe —
--     gains a SPECULAR HIGHLIGHT: the same Circle_Smooth disc, squashed to 0.46 x 0.34 of
--     the globe, pushed up and left, white at 0.28 alpha, blend mode ADD.
--     ADD IS THE LOAD-BEARING FIELD. Subregions draw in order and the percentage lives
--     INSIDE the glass, so this overlay is painted over the number; a BLEND sheet would grey
--     out the readout the vessel exists to carry, while ADD can only brighten. That is also
--     why the recipe is a highlight and not the more obvious dark edge vignette — a dark
--     overlay has no additive form.
--     APPENDED, NEVER INSERTED: sub.2 on life, sub.4 on mana (after both waterlines), sub.2
--     on the target globe, sub.1 on the target's power globe. Conditions reach subregions
--     positionally as sub.N, and an insert ahead of a referenced index retargets it with no
--     error at all, so the build asserts the pre-v11 prefix of every vessel is untouched.
--
-- v12: THE RINGS COME BACK, AND SO DOES YOUR FACE. The globes are gone; health, power, threat
-- and target health are radial ARCS again, two per cluster, drawn around a live 3D portrait of
-- the unit they belong to. Nothing outside the cluster moved: not one trigger, load gate,
-- condition, spell id or offset in the buffs, alerts, cooldown row, procs or the PvP layer,
-- and no aura was added or removed (stable=46 changed=0 missing=0 — the seven auras missing
-- from `stable` are the ones that changed NAME, and every one kept its uid).
--   * WHY. Side by side with the ring build, the globes lost. A vessel says "how full", which
--     is the same sentence a bar says, in a rounder frame; two concentric arcs around a face
--     say "this unit, this much" in one glance and put the unit's identity in the middle of
--     its own readout. The portrait is the part a globe can never have: it is what makes the
--     target cluster tell you WHAT you are shooting without a nameplate, and it is why the
--     percentages sit just outside the rings again (a `model` region cannot carry a text
--     subregion at all — SubText's supports() gate does not list it).
--   * THE CLUSTER, and every number in it is canon, shared byte-for-byte with the other six
--     packs: outer ring 84, inner ring 62, portrait 44, player cluster at an absolute
--     (-270, +40), target cluster at (+270, +110). Health is the player's outer arc and mana
--     its inner one; THREAT is the target's outer arc and target health its inner one, so both
--     sides are two rings around a face and read as a matched pair.
--   * A TARGET POWER ARC IS DELIBERATELY NOT BUILT. v8/v9 had one and it is what made that
--     cluster look busy and uneven — three arcs on one side, two on the other. Its aura is not
--     orphaned: the uid carries the target's track ring now (see the cluster block below).
--   * WHAT CARRIES OVER UNTOUCHED: every escalation (health <30, mana <20, threat 70/90/aggro),
--     every zero-total alpha guard, threat's party/raid + not-arena gates, the 80% halo, the
--     out-of-combat fade, and the two aspect-swap breakpoints. The escalations move BACK to
--     `foregroundColor` — `barColor` was the aurabar name and `color` the texture name the
--     v10/v11 rim used, and Conditions.lua drops an unknown property in silence, so each of
--     those renames is a dead escalation if it is missed.
--   * THE BREAKPOINTS GO BACK TO TRIGONOMETRY. On a vessel a threshold is a horizontal
--     waterline; on a ring it is an angle, x = r*sin(2*pi*f), y = r*cos(2*pi*f) with
--     r = INNER/2*0.94. The 20% and 80% marks land at (27.71, 9.0) and (-27.71, 9.0), and the
--     build re-derives the angle from the emitted offsets and refuses to write a string whose
--     marks are not on their ring at their own threshold.
--   * THE SPECULAR HIGHLIGHT IS DROPPED. It was a glass effect for a filled vessel; on an arc
--     there is no glass to catch light, and it was the only subregion in the cluster that
--     existed for the globes alone.
--   * THREE AURAS BECOME TRACK RINGS. The globe build carried four rims and a target power
--     globe that the ring build has no use for, and a uid may never simply disappear — an
--     orphan is an aura the player has to hunt down and delete by hand. They are respent on
--     the dark track rings behind the mana arc, the target's threat arc and the target's health
--     arc, which is the one job the ring build genuinely needs doing: threat does not load
--     solo or in an arena and hides itself at zero threat, and without a track ring the target
--     cluster would read as one arc and a face while the player's reads as two.
--
-- v13: THE TARGET CLUSTER IS DELETED, AND THREAT MOVES HOME. The right-hand cluster is gone
-- entirely — target health arc, target portrait, and the two target track rings (one of them
-- the last remnant of the v8/v9 target MANA arc, respent as a track in v12). Its whole job was
-- already done twice by the default UI: the target frame and the nameplate both print that
-- unit's health, all game, in the place every player already looks. A HUD element that
-- duplicates the default UI costs screen, draw order and attention and returns nothing.
--   * THREAT IS NOT LOST, IT IS REHOMED. It is the one thing the target cluster carried that
--     nothing else in the game shows, and losing it is a real regression: a dps who pulls
--     aggro dies. It becomes the OUTERMOST ring of the PLAYER cluster at 100px, which is also
--     the more honest reading — it is YOUR threat, so it belongs around YOUR face. The cluster
--     is now threat 100 / health 84 / mana 62 / portrait 44, concentric on one centre.
--   * THREAT KEEPS EVERYTHING ELSE. Same aura, same uid, same Threat Situation trigger with
--     `threatUnit` (the arg was renamed to plain `unit` at internalVersion 51 and Modernize
--     migrates < 51 data, so IV-45 data MUST emit the old name), the same three escalation
--     tiers on `foregroundColor` (barColor is aurabar-only and a SILENT no-op here), the same
--     party/raid + not-arena load gates, and the same mandatory threatvalue <= 0 -> alpha 0
--     guard without which ProgressTexture draws a FULL circle at zero threat.
--   * THE 80% HALO RESIZES TO 100 and rides the player cluster too, so it pulses ON the threat
--     ring instead of orbiting the radius the old outer arc used to have.
--   * THE COMMON SOLO CASE IS STILL TWO RINGS AND A FACE. Threat load-gates to party/raid,
--     never loads in an arena, and self-hides at zero threat, so the third arc only appears
--     when threat is a real quantity.
--   * ORPHANS ARE EXPECTED HERE AND THAT IS THE POINT. Five regions are genuinely REMOVED,
--     so five uids have no home. No filler region is invented to absorb them — that is how a
--     HUD accumulates junk. Their uid() DRAWS are burned in place (a uid is a position in a
--     seeded stream; skipping a draw shifts every later one and would change the uid of every
--     surviving aura built after it), and the README names the leftover group the player has
--     to delete by hand, because WeakAuras never deletes an aura an import does not mention.
--
-- v14: THE HEALTH NUMBER MOVES INTO THE MIDDLE, AND THE PORTRAIT MOVES BEHIND IT. v13 left the
-- three readouts stacked OUTSIDE the rings — health 54px below the cluster, mana 70px below —
-- and the reported result was the obvious one: small unbacked digits on open sky, unreadable
-- against any bright zone, while the one opaque surface in the cluster (the portrait) sat in
-- the centre showing nothing but a face. v14 spends that centre.
--   * HEALTH GOES TO DEAD CENTRE at 16pt, ON the portrait, which is both where the eye already
--     rests and the only place in the cluster with something solid behind the glyphs.
--   * MANA TAKES THE SLOT HEALTH VACATED, -54 at 12pt: one number just under the outer ring
--     instead of two stacked numbers trailing off the bottom of the HUD.
--   * THREAT DOES NOT MOVE. +58 at 10pt, above the 100px threat ring, exactly as in v13.
--   * THE DRAW ORDER IS HALF THE FIX, AND THE NON-OBVIOUS HALF. The health number is a
--     subregion of the health RING, and through v13 the portrait was the cluster's LAST child
--     — FixGroupChildrenOrder gives later children higher frame levels, so the face drew over
--     every sibling. Sending the text to the centre without touching the order would have
--     painted it straight under the portrait and looked like nothing had happened. The
--     portrait becomes the FIRST child instead, so every ring and every ring's text draws in
--     front of it. That is safe only because a ring is an ANNULUS: the innermost ink in this
--     cluster is at radius 26.16 and the portrait ends at 22, so no ring's art can touch the
--     face — only its text can, which is the point. The build asserts that gap.
--   * NOTHING ELSE CHANGES. No aura added or removed, every uid stable, no trigger, load gate,
--     condition, colour, size or position touched outside those two offsets, two font sizes
--     and the child order. Reordering controlledChildren costs no uid draw at all.
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

-- ===== ring machinery (the v8/v9 rings, restored as v12) =====
-- `progresstexture` and `model` are the two region types wa_factory.lua does not build, so
-- those two tables are spelt out below; the track rings are plain F.texture regions and
-- everything else still goes through the factory. internalVersion stays 45, and no Modernize
-- block at IV >= 45 renames a progresstexture fill field, a model field or a subtexture
-- field, so what is emitted here is what the current client runs.
local IV, TOC = 45, 20501

-- ===== v12 CANON: the ring cluster every pack in this repo shares ============
-- These constants are IDENTICAL in all seven packs. Do not scale, round or "improve" them
-- here: the moment one pack drifts, the player sees differently-sized clusters the instant
-- they run two classes, which is exactly the bug the shared canon exists to prevent.
-- Change them in all seven build scripts or not at all.
--
-- Ring_20px.tga is a true ANNULUS — the number is the stroke weight of WeakAuras' 256px
-- source art, so a ring of diameter d draws a d*20/256 arc (6.6px at OUTER, 4.8px at INNER).
-- It ships inside WeakAuras itself (Private.texture_types, "Shapes"), so nothing here needs a
-- media addon. Circle_Smooth — the v10/v11 globe art — is a SOLID DISC and on the circular
-- path would fill as a pie wedge, not as an arc.
local RING_TEX  = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Ring_20px.tga"
local THREAT_RING = 100 -- v13: the OUTERMOST ring, YOUR threat, same Ring_20px art
local OUTER     = 84    -- health ring diameter, unchanged
local INNER     = 62    -- primary power ring diameter, unchanged
local PORTRAIT  = 44    -- the live unit portrait in the middle, unchanged
local CLUSTER_X = 270   -- ABSOLUTE screen x of the (only) cluster's centre: -270
local CLUSTER_Y = 40    -- ABSOLUTE screen y of the cluster's centre

-- The readouts. A `model` region can never carry a text subregion (SubText's supports() gate
-- lists texture / progresstexture / icon / aurabar / empty — not model), so every number still
-- rides on a RING. What changes in v14 is WHERE the ring puts it.
--
-- v13 pushed all three numbers OUTSIDE the rings, on the theory that clear space beats
-- overlap. In play that theory loses: health ended up as a 13pt number floating 54px below
-- the cluster with nothing behind it, so against a bright zone — Nagrand grass, Netherstorm,
-- any snowfield — it was two unreadable digits on open sky, and the only actually-opaque
-- thing in the whole cluster, the portrait, sat in the middle displaying nothing at all.
--
-- v14 puts the health number where the eye already is and where there is something solid
-- behind it: dead centre, ON the portrait. y = 0 is the cluster's own centre, so it needs no
-- offset arithmetic to stay there, and 16pt is legible at a glance rather than a squint. The
-- power number inherits the slot health just vacated (-54, just under the outer ring) at
-- 12pt, and threat is untouched at +58 above the 100px threat ring.
--
-- This only WORKS because the portrait is reordered to draw first — see the cluster block.
local PCT_HP     = { size = 16, y =   0 }   -- health, dead centre, ON the portrait
local PCT_POWER  = { size = 12, y = -54 }   -- power, the slot health vacated in v14
local PCT_THREAT = { size = 10, y =  58 }   -- threat, ABOVE the 100px outermost ring

-- Pack-local geometry, all of it derived from the canon so the two can never drift.
--   NOTHING below hard-codes a coordinate. Each CLUSTER is placed by a canon constant minus
--   the offsets its ancestors already carry, and every region inside a cluster sits at (0,0)
--   in that cluster's frame — which is what makes the rings concentric BY CONSTRUCTION
--   instead of by four hand-typed offsets that drift apart one version later.
--   resY expresses CLUSTER_Y in the top group's frame: `top` sits at -140, so the Resources
--   group offsets +180 to land the player cluster at an absolute +40. Walk it:
--   top(0,-140) -> Resources(0,+180) -> player cluster(-270,0) -> ring(0,0) = (-270,+40).
--   v13 deletes the second walk with the second cluster: there is exactly one cluster now, and
--   every one of its five regions — three arcs, the halo and the portrait — sits at (0,0) in
--   its frame, which is what makes them concentric BY CONSTRUCTION.
--   HALO is the one size NOT in the canon (no other pack has this pack's threat halo). It is
--   DERIVED, never guessed: v12 put it one ring-stroke outside the outer arc because threat
--   WAS that arc; v13 makes it exactly the threat ring's own diameter, so the pulse lands ON
--   the arc it is warning about instead of orbiting a radius nothing draws any more.
local TOP_Y = -140
local HALO  = THREAT_RING
local G = {
  resY     = CLUSTER_Y - TOP_Y,      -- +180: the Resources group's own offset
  clusterX = CLUSTER_X,
  threat   = THREAT_RING,            -- outermost: YOUR threat
  outer    = OUTER,                  -- health
  inner    = INNER,                  -- mana
  portrait = PORTRAIT,
  halo     = HALO,                   -- the 80% threat halo, ON the threat ring
}

-- Colours. The ring colours and the track are canon (identical in every pack); the text
-- colours and the threat green are carried over UNCHANGED from the v7 bars, so the HUD keeps
-- speaking one language across the versions.
--
-- THE POWER RING IS COLOURED FOR THE POWER TYPE IT ACTUALLY READS. A hunter's is mana, always
-- and in every spec, so it is the canon mana blue; the energy and rage colours in the canon
-- belong to the packs whose power ring reads those bars.
local COL = {
  health = { 0.15, 0.82, 0.28, 1 },     -- the health ring
  mana   = { 0.20, 0.45, 0.95, 1 },     -- the hunter's only power type
  threat = { 0.25, 0.80, 0.30, 1 },     -- the outermost ring, base tier
  track  = { 0, 0, 0, 0.55 },           -- the unfilled arc inside every ring, and the colour
                                        -- of the mana track ring drawn behind the mana arc
  hpText = { 1, 1, 1, 1 },
  mpText = { 0.55, 0.75, 1, 1 },        -- echoes the mana ring, so the two numbers
  thText = { 0.75, 0.95, 0.78, 1 },     -- never need labels to be told apart
}

-- wa_factory's stub() is local to the factory; the hand-written region tables below get the
-- identical scaffolding here.
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

-- v13 NOTE: the hand-rolled `unit = "target"` Health trigger that fed the target cluster's
-- arcs, track rings and portrait is gone with them. Every unit trigger left in this pack is
-- the factory's, hardwired to unit = "player", which is the whole point of the version: the
-- cluster reads YOU. The target-unit triggers that remain are aura triggers (Serpent Sting,
-- Hunter's Mark, Expose Weakness) and they are untouched.

-- THE RING. A progresstexture on the CIRCULAR path — the same region type the globes were,
-- with ONE different field, and that field silently changes which of the others are live.
-- Field notes on the ones that are traps:
--   orientation CLOCKWISE -> the only radial values are CLOCKWISE / ANTICLOCKWISE; every
--     other value in orientation_with_circle_types is LINEAR, and v10/v11's globes used
--     VERTICAL. Coming back therefore re-arms startAngle / endAngle and makes compress /
--     slanted / slant / slantFirst / slantMode inert (they are still emitted because they are
--     in the 3.5.0 default table).
--   startAngle 0 / endAngle 360 -> a full circle. WA normalises 0/360 -> 0/0 and then corrects
--     endAngle back up by 360, so this is a handled case, not a degenerate one.
--   crop_x / crop_y = 0.41 -> the IDENTITY value on the circular path, NOT "no crop". The
--     circular path expands the texture by sqrt(2) so rotated quadrants never run off it, and
--     crop = 1 + 0.41 exactly cancels that. Setting 0 blows the ring up 1.41x and clips it.
--     (On the linear path 0.41 is merely the default texcoord scale, which is why the globes
--     could carry the same number for a completely different reason.)
--   backgroundOffset = 0 -> the default 2 fattens the track relative to the fill, which reads
--     as a halo around the arc instead of the track the arc runs in.
--   sameTexture = true -> backgroundTexture becomes dead code; both are set anyway.
--   auraRotation = 0 -> absent from the 3.5.0 default table but read unconditionally by
--     current code as data.auraRotation / 180 * math.pi, so it must be emitted.
--   adjustedMin/Max are STRINGS (""), because SetAdjustedMin does adjustedMin:find(...).
--   progressSource is rewritten to {-1, ""} by Modernize < 71 no matter what is emitted; it is
--     here for readability. {-1,""} = Automatic, which is what routes the Health/Power/Threat
--     prototype's value/total into the fill with no further wiring.
-- ONE PROGRESS TRIGGER PER RING, and it must be trigger 1: Modernize < 71 forces Automatic and
-- F.triggers sets activeTriggerMode = -10 (first_active). A second trigger can only feed
-- conditions (that is what F.unitCharTrigger does below), never the fill. That constraint is
-- what makes the concentric look possible at all — health and power cannot share a region, so
-- they have to be two rings.
local function ring(id, size, color, triggers)
  return orbStub{
    regionType = "progresstexture", id = id, uid = W.uid(), parent = nil,
    width = size, height = size,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = 0, yOffset = 0, frameStrata = 1, alpha = 1,
    orientation = "CLOCKWISE", startAngle = 0, endAngle = 360,
    inverse = false, mirror = false,
    compress = false, slanted = false, slant = 0, slantFirst = false, slantMode = "INSIDE",
    foregroundTexture = RING_TEX, backgroundTexture = RING_TEX, sameTexture = true,
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
    triggers = triggers,
    load = F.load(CLASS),
  }
end

-- A TRACK RING: the same annulus at the same diameter, in the track colour, drawn BEHIND a
-- readout ring. A plain `texture` region — it has no progress of its own — carrying the same
-- trigger as the arc it stands under, so it appears and vanishes with the cluster.
-- WHY IT EXISTS, and it is not decoration: a ring POSITION must not read as a hole when the
-- readout that owns it has nothing to say, and the mana arc carries a zero-total alpha guard.
-- v13 leaves exactly ONE of these. The health arc never needs one (it is not conditional while
-- you are alive) and the new threat ring deliberately does not get one: threat only loads in a
-- party or raid and hides itself at zero threat, so a permanent dark 100px hoop would draw a
-- third ring for every solo player purely to say nothing. Two of the three v12 tracks belonged
-- to the target cluster and are removed with it.
local function trackRing(id, size, triggers)
  local t = F.texture(id, CLASS, size, size, 0, 0, nil, RING_TEX, COL.track)
  t.triggers = triggers
  return t
end

-- THE LIVE UNIT PORTRAIT in the middle of the cluster. A real 3D portrait of the unit — not a
-- static image and not a class icon, so it needs to know nothing about who it is drawing.
-- v13 emits exactly one, for `player`.
--   modelIsUnit = true + model_fileId = "<unit>" -> PlayerModel:SetUnit(unit)
--   portraitZoom = true                          -> SetPortraitZoom(1), Blizzard head framing
-- CRITICAL: current WeakAuras reads the unit from `model_fileId`. WA 3.5.0 read `model_path`,
-- and the migration that bridges the two (Modernize < 72) is guarded by
-- WeakAuras.IsClassicEra(), which is a DISTINCT predicate from IsTBC() — so on a 2.5.x client
-- that migration DOES NOT RUN and emitting only model_path is a silent no-op that leaves an
-- empty frame in the middle of the cluster. Both are emitted; model_fileId does the work.
-- The portrait carries the same triggers as the health ring it sits inside, so the whole
-- cluster fades and hides as one.
local function portrait(id, unit, triggers)
  return orbStub{
    regionType = "model", id = id, uid = W.uid(), parent = nil,
    model_fileId = unit, model_path = unit, modelIsUnit = true, modelDisplayInfo = false,
    portraitZoom = true, api = false,
    model_x = 0, model_y = 0, model_z = 0,
    model_st_tx = 0, model_st_ty = 0, model_st_tz = 0,
    model_st_rx = 270, model_st_ry = 0, model_st_rz = 0, model_st_us = 40,
    sequence = 1, advance = false, rotation = 0,
    width = PORTRAIT, height = PORTRAIT, alpha = 1,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = 0, yOffset = 0, frameStrata = 1,
    border = false, borderColor = { 1, 1, 1, 0.5 }, backdropColor = { 1, 1, 1, 0.5 },
    borderEdge = "None", borderOffset = 5, borderInset = 11,
    borderSize = 16, borderBackdrop = "Blizzard Tooltip",
    subRegions = {},
    triggers = triggers,
    load = F.load(CLASS),
  }
end

-- The percentage numbers sit just OUTSIDE the rings, because the middle is a face and a `model`
-- region cannot carry a subtext at all. Each number rides on its own ring, so it appears and
-- disappears with it: no threat state, no threat number. v13 pushes the threat readout from
-- +54 to +58 for one reason — the ring under it grew from 84 to 100, so +54 would print the
-- number ON the new arc instead of above it.
--
-- THE OFFSET KEY IS `text_anchorYOffset`, NOT `anchorYOffset`. Both names live in the subtext
-- default table, but SubText.modify only ever reads the text_-prefixed pair
-- (`region.text_anchorXOffset = data.text_anchorXOffset`, then Anchor() passes
-- `self.text_anchorYOffset or 0` to AnchorSubRegion) — in WA 3.5.0 AND in current code, and no
-- Modernize block renames one to the other. Writing only `anchorYOffset` is a silent no-op
-- that stacks every readout dead centre, on top of the portrait. Both are set here: the text_
-- pair does the work, the bare pair keeps the table self-consistent.
local function pct(sym, size, y, color)
  local st = F.subtext("%" .. sym .. "%%", size, "CENTER", sym)
  st.text_anchorXOffset, st.text_anchorYOffset = 0, y
  st.anchorXOffset, st.anchorYOffset = 0, y
  st.text_color = color
  return st
end

-- A static breakpoint mark ON THE RING. v10/v11 drew these two as horizontal waterlines across
-- a vessel, where a threshold is a HEIGHT; on a ring a threshold is an ANGLE, so they go back
-- to trigonometry from the ring's own radius:
--
--   r = INNER/2 * 0.94 ;  x = r*sin(2*pi*f) ;  y = r*cos(2*pi*f)
--
-- sin on x and cos on y, not the other way round: the fill starts at 12 o'clock and runs
-- CLOCKWISE, so f = 0 has to land at the TOP and f = 0.25 at 3 o'clock. The 0.94 pulls the
-- mark just inside the arc's centreline, so it reads as a notch cut into the ring rather than
-- a dot floating beside it. Both marks are derived from the ring diameter passed in, so
-- resizing the ring can never leave them behind — which is the exact bug v9 had to fix by hand
-- after v8 grew the mana ring and left both ticks 9px inside their own arc.
--
-- Still a `subtexture`: `subtick`, the tick sub-region, is aurabar-ONLY (SubRegionTypes/
-- Tick.lua: supports() returns regionType == "aurabar"), while subtexture's supports() does
-- list progresstexture. The art is a plain white square, so textureRotate / textureRotation
-- stay off — rotation there is texture-COORDINATE based and a square is invariant under it,
-- which removes that gate as a failure mode.
-- xOffset/yOffset are NOT in the subtexture default() table but ARE what modify() hands to
-- AnchorSubRegion, so they must be emitted or every mark stacks at dead centre.
local MARK_SIZE = 6   -- a little wider than the 4.8px arc it notches, so it reads at a glance
local function ringMark(fraction, diameter, color)
  local function round(v) return math.floor(v * 100 + 0.5) / 100 end
  local r = diameter / 2 * 0.94
  local theta = 2 * math.pi * fraction
  return {
    type = "subtexture",
    textureVisible = true,
    textureTexture = F.TEX_SQUARE,
    textureColor = color, textureBlendMode = "BLEND",
    textureDesaturate = false, textureMirror = false,
    textureRotate = false, textureRotation = 0,
    anchor_mode = "point", anchor_point = "CENTER", self_point = "CENTER",
    anchor_area = "ALL",
    width = MARK_SIZE, height = MARK_SIZE,
    scale = 1, mirror = false, rotate = false,
    xOffset = round(r * math.sin(theta)),
    yOffset = round(r * math.cos(theta)),
  }
end

-- ===== 1. top-level group, anchored below the character =====
-- TOP_Y is this group's own offset and every absolute number in the canon is expressed
-- against it, so the literal below and TOP_Y must stay the same value.
local top = F.group(TOP, 0, TOP_Y, nil)
top.uid = W.uid()

-- ===== 2. Resources: the ring cluster (singular, since v13) =====
-- v8 emptied the middle of the screen of its bar stack, v10 filled the low band with three
-- globes instead, v12 put the rings back beside the character, and v13 drops the right-hand
-- cluster entirely: this group now holds exactly one child. It keeps its id and its uid across
-- every one of those versions — an existing user gets an in-place Update, not a second copy —
-- and only its own offset ever changes: +80 in v9, -122 in v10, and +180 since v11, which is
-- simply CLUSTER_Y expressed in the top group's frame.
local gRes = reg(F.group("Hunter - Resources", 0, G.resY, nil))
adopt(top, gRes)

-- 3. LIFE — don't die. The same aura as v7's health bar, v8/v9's health ring and v10/v11's
--    globe: same id, same uid, same two triggers, same escalation, same 84px diameter it has
--    had since v12 — the threat ring is added OUTSIDE it rather than by moving anything —
--    with the percentage printed just under it. It is re-parented into the player cluster in
--    the block at the bottom of this file, because that cluster group is a newer aura and
--    every new W.uid() call has to come after all the existing ones.
--    The <30% escalation is on `foregroundColor` — NOT `barColor` (aurabar-only) and NOT
--    `color` (the texture name the v10/v11 rim used). Conditions.lua skips a change whose
--    property the region does not declare, in silence, so the wrong name ships a dead
--    escalation that nothing warns you about.
local hp = reg(ring("Hunter - Health", G.outer, COL.health,
  F.triggers({ F.healthTrigger(nil), F.unitCharTrigger() })))
hp.subRegions[1] = pct("percenthealth", PCT_HP.size, PCT_HP.y, COL.hpText)
hp.conditions = {
  F.condition(1, "percenthealth", "<", "30", "foregroundColor", { 0.9, 0.12, 0.12, 1 }),
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  -- ZERO-TOTAL GUARD, and it is not optional. The Health prototype's total is
  -- UnitHealthMax(unit) with NO floor, and ProgressTexture.UpdateValue starts at
  -- progress = 1 and only divides when total > 0 — so a unit whose max health has not
  -- streamed in yet would flash a FULL ring. The aurabar did the opposite (it starts at
  -- 0), which is why v7 needed no such guard. Last, so it wins over the combat fade.
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

-- 4. POWER — the hunter resource, and it is MANA in every hunter spec, so the ring is the
--    canon mana blue. Turns red at the Viper threshold (20%: Viper's regen scales off MISSING
--    mana, so swapping at 15% is already late). The PLAYER cluster's INNER ring, carrying the
--    two aspect-swap breakpoints as marks on its own circumference, so the swap band is
--    visible before either alert fires.
local mana = reg(ring("Hunter - Mana", G.inner, COL.mana,
  F.triggers({ F.powerTrigger(0), F.unitCharTrigger() })))
mana.subRegions[1] = pct("percentpower", PCT_POWER.size, PCT_POWER.y, COL.mpText)
-- APPEND-ONLY: no condition in this pack points at sub.N on this aura today, but the readout
-- must stay index 1 if one ever does — so the two marks keep the indices 2 and 3 they have
-- held since v8. v12 changes what they ARE (v10/v11 waterlines back to circumference marks)
-- and not where they live: 20% lands at (27.71, 9.0) and 80% at (-27.71, 9.0), both exactly on
-- the inner ring at the angle their own threshold implies — 72 and 288 degrees clockwise from
-- 12 o'clock, which the mark proof at the bottom of this file re-derives and asserts.
mana.subRegions[2] = ringMark(0.20, G.inner, { 0.85, 0.2, 0.2, 1 })   -- Go Viper
mana.subRegions[3] = ringMark(0.80, G.inner, { 0.4, 1, 0.4, 1 })      -- Back to Hawk
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
--    v13: threat comes home. It is the OUTERMOST ring of the PLAYER cluster at 100px, drawn
--    around YOUR face with the percentage above it — which is both where it survives the
--    target cluster's deletion and the more honest reading of the number: this is your threat,
--    not the target's. Same aura, same uid, same trigger (`threatUnit`, never `unit` — the arg
--    was renamed at internalVersion 51 and Modernize migrates < 51 data forward), same
--    party/raid + not-arena gates, same three tiers, same zero-total guard.
--    The property renames a THIRD time: `barColor` on the v7 aurabar, `foregroundColor` on the
--    v8/v9 ring, `color` on the v10/v11 rim texture, and now `foregroundColor` again. Every
--    one of those renames is SILENT — Conditions.lua skips a change whose property the region
--    does not declare, without an error — so a mechanical port would ship three dead
--    escalations and an arc that never changes colour.
local threat = reg(ring("Hunter - Threat", G.threat, COL.threat,
  F.triggers({ threatTrigger(nil) })))
threat.subRegions[1] = pct("threatpct", PCT_THREAT.size, PCT_THREAT.y, COL.thText)
threat.conditions = {
  F.condition(1, "threatpct", ">=", "70", "foregroundColor", { 1, 0.6, 0.1, 1 }),
  F.condition(1, "threatpct", ">=", "90", "foregroundColor", { 0.95, 0.25, 0.1, 1 }),
  F.condition(1, "aggro", "==", 1, "foregroundColor", { 0.9, 0.12, 0.12, 1 }),
  -- THE GUARD THIS READOUT CANNOT SHIP WITHOUT, and the ring needs it even more than the
  -- vessel did. AuraBar.lua draws EMPTY at total == 0; ProgressTexture.lua draws FULL
  -- (`local progress = 1; if self.total > 0 then ...`). threattotal is
  -- threatvalue * 100 / threatpct, so it is 0 whenever threatvalue is 0 — the instant after a
  -- Feign Death, and the instant before your first hit lands. With no guard the arc would slam
  -- to a COMPLETE GREEN CIRCLE, i.e. "you are at the pull threshold and fine", at the exact
  -- moment the readout exists to speak. Hide it instead and let the track ring behind it show
  -- through, which says nothing at all.
  F.condition(1, "threatvalue", "<=", "0", "alpha", 0),
}
threat.load.use_ingroup = true
threat.load.ingroup = { multi = { group = true, raid = true } }
threat.load.use_size = false   -- false = MULTI mode (nil would disable the gate)
threat.load.size = noArenaSize()

-- 6. threat >= 80% in a party/raid: a pulsing red halo ON the threat ring. Same trigger, same
--    gates, same colour and same alphaPulse as v7's bar overlay — only the shape and the art
--    ever change. v12 drew it one stroke outside the threat arc; v13 gives it the threat
--    ring's own 100px diameter, so the emergency reads as that arc catching fire instead of
--    as a hoop orbiting a radius nothing draws any more.
local flash = reg(F.texture("Hunter - Threat Flash", CLASS, G.halo, G.halo, 0, 0, nil,
  RING_TEX, { 1, 0.1, 0.1, 0.85 }))
flash.blendMode = "ADD"
flash.triggers = F.triggers({ threatTrigger(80) })
flash.load.use_ingroup = true
flash.load.ingroup = { multi = { group = true, raid = true } }
flash.load.use_size = false
flash.load.size = noArenaSize()
flash.animation.main = F.animPreset("alphaPulse", "1")

-- ===== 7. Buffs: static row of aura timers =====
-- v10 was the ONE version in which something outside the globes had to move: this row sat at
-- an absolute (0, -156), the globes landed on the band at -262, and the target globe would
-- have been drawn straight through Serpent Sting and Hunter's Mark. The row was re-anchored
-- 96px up to an absolute (0, -60).
-- v11 DID NOT TOUCH IT and NEITHER DOES v12: this row keeps v10's home and every icon in it
-- keeps its id, uid, trigger, load gate, condition, size and both offsets — byte-identical
-- across all three versions.
--   The clearance is derived, not picked, and the ring clusters make it wider than it was:
--   the row is 40px icons centred at BUFF_Y = -60 spanning x -64..64 and y -80..-40, while
--   the nearest cluster edge is the player's outer ring at x = -CLUSTER_X + OUTER/2 = -228
--   and its lowest ink is the mana percentage at CLUSTER_Y + PCT_POWER.y, which v14 lifts
--   from -30 to -14 by pulling the readouts inward. The two never share a column at all, so
--   the margin was never load-bearing in y — but v14 only ever widens it.
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

-- ===== the cluster block: v8's slots, five of them retired by v13 =====
-- Every version since v8 has kept this block's uid() calls in exactly the order they were
-- first made, and v13 keeps that order too — it just stops EMITTING five of the regions.
--   v8/v9 slot order:  player cluster group, player portrait,  target cluster group,
--                      target health ring,   target mana ring, target portrait
--   v10/v11 meaning:   player globe group,   LIFE RIM,         target globe group,
--                      target globe,         target power globe, TARGET RIM
--   v12 meaning:       player cluster group, PLAYER PORTRAIT,  target cluster group,
--                      target health ring,   TARGET TRACK RING, TARGET PORTRAIT
--   v13 meaning:       player cluster group, PLAYER PORTRAIT,  RETIRED, RETIRED, RETIRED,
--                      RETIRED,              player mana track, RETIRED
--
-- WHY THE DRAWS ARE BURNED RATHER THAN DELETED. W.uid() is 11 draws from a seeded stream, so
-- a uid is a POSITION, not a value. Delete the four target constructors outright and the next
-- surviving aura built after them — `Hunter - Power Ring Track` — silently inherits the uid
-- that belonged to the target cluster GROUP. WeakAuras matches auras across imports by uid,
-- so on the player's machine that mana track would import as an Update over their target
-- cluster group, and a second track ring would appear beside the one they already have.
-- Burning the draw costs one line each and keeps all 48 surviving uids byte-for-byte.
--
-- AND NO FILLER REGION IS INVENTED to give the five freed uids a home. That is how a HUD
-- accumulates junk — a region that exists only so a number has somewhere to live. WeakAuras
-- never deletes an aura an import does not mention, so the five simply stay behind in the
-- player's collection until they delete the leftover group by hand, which the README says in
-- as many words and names exactly.
--
-- WA-REMOVED (v13): Hunter - Target Cluster
-- WA-REMOVED (v13): Hunter - Target Health
-- WA-REMOVED (v13): Hunter - Target Ring Track
-- WA-REMOVED (v13): Hunter - Target Portrait
-- WA-REMOVED (v13): Hunter - Target Health Track
local REMOVED = {
  "Hunter - Target Cluster",      -- 48: the group itself, and the only one the player deletes
  "Hunter - Target Health",       -- 49: duplicated the target frame and the nameplate
  "Hunter - Target Ring Track",   -- 50: the last remnant of the v8/v9 target MANA arc
  "Hunter - Target Portrait",     -- 51: the target's face
  "Hunter - Target Health Track", -- 53: the socket under the target's health arc
}
local burned = 0
local function retire() burned = burned + 1; W.uid() end

-- 46. The cluster — the only one now. A plain group, not a dynamic one: its children are
--     CONCENTRIC, every one of them at (0,0) in its frame, and the group itself carries the
--     cluster's x. That is what makes the rings share a centre by construction rather than by
--     five hand-typed offsets that drift apart the first time somebody retunes one of them.
--     It keeps its id and its uid from v8, so this is an Update in place.
local gPlayerCluster = reg(F.group("Hunter - Player Cluster", -G.clusterX, 0, nil))
adopt(gRes, gPlayerCluster)

-- 47. PLAYER PORTRAIT — your face in the middle, the aura that carried it in v8 and v9:
--     it keeps that uid, its two triggers and its out-of-combat fade verbatim.
local pPortrait = reg(portrait("Hunter - Player Portrait", "player",
  F.triggers({ F.healthTrigger(nil), F.unitCharTrigger() })))
pPortrait.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }

-- 48-51. THE TARGET CLUSTER: the group, its health arc, its track ring (the old target mana
--     satellite) and its portrait. All four are gone. The target's health is already on the
--     target frame AND on its nameplate, so for the whole game this cluster restated something
--     the default UI never stops saying, in a place you have to look away to read.
retire()  -- 48. Hunter - Target Cluster
retire()  -- 49. Hunter - Target Health
retire()  -- 50. Hunter - Target Ring Track
retire()  -- 51. Hunter - Target Portrait

-- 52. POWER RING TRACK — the socket the mana arc runs in, and the one track ring that survives:
--     the mana arc carries a zero-total alpha guard, so its position must not read as a hole
--     when it hides. Its triggers mirror the mana ring's (power + the always-on characteristics
--     feeder), so it fades out of combat with the rest of the cluster instead of staying lit
--     behind a faded arc. The threat ring deliberately gets NO track: threat is gated to
--     party/raid and self-hides at zero threat, and a permanent dark hoop at 100px would put a
--     third ring on screen for every solo player precisely to say nothing.
local powerTrack = reg(trackRing("Hunter - Power Ring Track", G.inner,
  F.triggers({ F.powerTrigger(0), F.unitCharTrigger() })))
powerTrack.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }

-- 53. TARGET HEALTH TRACK — the socket under the target's health arc. Gone with it.
retire()  -- 53. Hunter - Target Health Track

assert(burned == #REMOVED,
  ("%d uid draws burned, %d regions declared removed"):format(burned, #REMOVED))

-- Sibling stacking is exact, not "roughly creation order": FixGroupChildrenOrder walks
-- controlledChildren and adds +4 frame levels per child, so EARLIER = further behind.
-- The track ring first, then the arcs, with the HALO drawn directly ON TOP of the threat arc
-- it warns about — it is an ADD-blend ring at the same 100px diameter now, so behind the arc
-- it would only light the part of the circle threat has not filled, which is backwards.
adopt(gPlayerCluster, powerTrack)
adopt(gPlayerCluster, threat)
adopt(gPlayerCluster, flash)
adopt(gPlayerCluster, hp)
adopt(gPlayerCluster, mana)
adopt(gPlayerCluster, pPortrait)

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

-- ===== v14: THE PORTRAIT DROPS TO THE BACK, AND THAT IS THE WHOLE FIX =====
-- Moving PCT_HP to y = 0 on its own would have looked like nothing happened. The health
-- number is a subregion of the HEALTH RING, and through v13 the portrait was the LAST child
-- of the cluster — highest frame level, drawn over every sibling — so a number sent to the
-- centre would have been painted straight over by the face. Two edits, one effect: the
-- offset moves the text in, and this moves the surface it would have hidden behind out.
--
-- Order becomes: portrait, track, threat, halo, health, mana — the portrait furthest back,
-- every ring and therefore every ring's text in front of it.
--
-- WHY THIS DOES NOT BURY THE FACE. A ring here is an ANNULUS, not a disc: Ring_20px.tga is a
-- 20px stroke on 256px art, so a ring of diameter d paints only the band from 0.84375*d/2 out
-- to d/2 and is empty everywhere inside that. Measured against this cluster, the innermost
-- ink of any sibling is the mana arc and the power track at radius 26.16, while the portrait
-- ends at radius 22 — a 4.16px gap, so no ring's ART can reach the face no matter which order
-- they draw in. The only thing that now lands on the portrait is the health SUBTEXT, which
-- is the entire point of the change. The assert below pins that gap so a future resize of
-- INNER or PORTRAIT fails the build instead of quietly covering the face.
placeFirst(gPlayerCluster, pPortrait.id)
do
  local innermostRing = math.min(INNER, THREAT_RING, OUTER) / 2 * (1 - 20 / 256)
  assert(innermostRing > PORTRAIT / 2,
    ("innermost ring ink reaches radius %.2f but the portrait ends at %.2f, so a ring drawn "
     .. "above the portrait would cover the face"):format(innermostRing, PORTRAIT / 2))
  assert(gPlayerCluster.controlledChildren[1] == pPortrait.id,
    "the portrait is not the cluster's first child, so it still draws over the readouts")
  for i = 2, #gPlayerCluster.controlledChildren do
    assert(gPlayerCluster.controlledChildren[i] ~= pPortrait.id,
      "the portrait is listed twice in the cluster")
  end
end

-- The two on-cooldown shots sit together in the row.
placeAfter(gCDs, arcane.id, cdMulti.id)
-- Kill Command is the pack's one reflex prompt, so it gets a fixed home: first in
-- a grow-UP flow means it is anchored at the bottom and never reflows when another
-- alert appears above it.
placeFirst(gAlerts, kc.id)

-- ===== ABSOLUTE POSITION PROOF =====
-- CLUSTER_X / CLUSTER_Y are ABSOLUTE screen offsets, and every region here is nested two
-- groups deep under a top group that carries its own -140. Applying the canon numbers LOCALLY
-- is the exact mistake that put seven packs' clusters at seven different heights, so the build
-- refuses to write a string whose rings do not land where the canon says. It walks each
-- region's parent chain and sums every xOffset/yOffset, which is what WeakAuras does when it
-- anchors a child to its group. v13 deletes the target cluster, and the deletion is not
-- allowed to nudge the surviving one by a pixel: -270,+40 is asserted, not assumed.
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
  { threat,     -CLUSTER_X, CLUSTER_Y, "threat ring" },
  { flash,      -CLUSTER_X, CLUSTER_Y, "threat halo" },
  { hp,         -CLUSTER_X, CLUSTER_Y, "health ring" },
  { mana,       -CLUSTER_X, CLUSTER_Y, "mana ring" },
  { powerTrack, -CLUSTER_X, CLUSTER_Y, "mana track" },
  { pPortrait,  -CLUSTER_X, CLUSTER_Y, "portrait" },
}
for _, e in ipairs(EXPECT) do
  local region, wantX, wantY, label = e[1], e[2], e[3], e[4]
  local gotX, gotY = absolutePos(region)
  assert(gotX == wantX and gotY == wantY,
    ("%s (%s) lands at absolute (%d,%d), canon says (%d,%d)")
      :format(label, region.id, gotX, gotY, wantX, wantY))
end

-- ===== CONCENTRICITY =====
-- "Concentric" is a claim about CENTRES, and the position proof above has just established
-- that all six regions share one. What is left to prove is that the new ring genuinely WRAPS
-- the old ones instead of landing on top of one: strictly nested diameters, every region
-- anchored by its own CENTRE (a region anchored by any other point would sit off-centre even
-- with identical offsets), and every child at (0,0) inside the cluster frame so the nesting —
-- not a hand-typed offset — is what holds the centre.
local NEST = {
  { threat,     THREAT_RING, "threat ring" },
  { flash,      HALO,        "threat halo" },
  { hp,         OUTER,       "health ring" },
  { mana,       INNER,       "mana ring" },
  { powerTrack, INNER,       "mana track" },
  { pPortrait,  PORTRAIT,    "portrait" },
}
local cx, cy = absolutePos(gPlayerCluster)
for _, n in ipairs(NEST) do
  local region, size, label = n[1], n[2], n[3]
  assert(region.xOffset == 0 and region.yOffset == 0,
    label .. " carries its own offset inside the cluster, so it is centred by hand")
  assert(region.selfPoint == "CENTER" and region.anchorPoint == "CENTER",
    label .. " is not anchored centre-to-centre, so equal offsets do not mean one centre")
  assert(region.width == size and region.height == size,
    ("%s is %dx%d, expected %d square"):format(label, region.width, region.height, size))
  assert(region.parent == gPlayerCluster.id, label .. " is not in the cluster")
  local x, y = absolutePos(region)
  assert(x == cx and y == cy,
    ("%s centre (%d,%d) is not the cluster centre (%d,%d)"):format(label, x, y, cx, cy))
end
assert(THREAT_RING > OUTER and OUTER > INNER and INNER > PORTRAIT,
  "the rings do not nest: threat must wrap health must wrap power must wrap the face")
assert(HALO == THREAT_RING, "the threat halo no longer pulses ON the threat ring")
-- The threat readout has to clear the arc it rides on, or it prints across its own ring.
do
  local st = threat.subRegions[1]
  assert(st.type == "subtext" and st.text_fontSize == PCT_THREAT.size
     and st.text_anchorPoint == "CENTER" and st.text_anchorYOffset == PCT_THREAT.y,
    "threat readout is not font 10 / CENTER / +58")
  assert(st.text_anchorYOffset > THREAT_RING / 2,
    ("threat readout at +%d prints on a ring whose top edge is +%d")
      :format(st.text_anchorYOffset, THREAT_RING / 2))
end
-- v14's two moved readouts, pinned to the values the version exists to ship. The health
-- number is the one the player complained they could not read, so its centre placement and
-- its 16pt are asserted literally rather than derived — a later tweak that drifts it back out
-- of the middle has to change this line and say so.
do
  local h = hp.subRegions[1]
  assert(h.type == "subtext" and h.text_fontSize == 16 and h.text_anchorPoint == "CENTER"
     and h.text_anchorYOffset == 0 and h.anchorYOffset == 0,
    "health readout is not font 16 / CENTER / dead centre")
  assert(h.text_anchorYOffset == 0 and math.abs(h.text_anchorYOffset) < PORTRAIT / 2,
    "health readout no longer lands on the portrait, which is the whole of v14")
  local p = mana.subRegions[1]
  assert(p.type == "subtext" and p.text_fontSize == 12 and p.text_anchorPoint == "CENTER"
     and p.text_anchorYOffset == -54 and p.anchorYOffset == -54,
    "power readout is not font 12 / CENTER / -54")
  assert(p.text_anchorYOffset < -OUTER / 2,
    ("power readout at %d prints on the health ring, whose bottom edge is %d")
      :format(p.text_anchorYOffset, -OUTER / 2))
  assert(h.text_fontType == "OUTLINE" and p.text_fontType == "OUTLINE",
    "a moved readout lost its outline, which is what keeps it legible on a bright background")
  assert(h.text_text == "%percenthealth%%" and p.text_text == "%percentpower%%",
    "v14 moved a readout and changed its text token, which it must not")
end
-- The trigger arg IV-45 data must carry. Modernize renames threatUnit -> unit for < 51 data,
-- and it assigns unconditionally, so emitting `unit` here would be overwritten with nil.
for _, t in ipairs({ { threat, "threat ring" }, { flash, "threat halo" } }) do
  local tr = t[1].triggers[1].trigger
  assert(tr.event == "Threat Situation" and tr.use_threatUnit and tr.threatUnit == "target",
    t[2] .. " lost its Threat Situation trigger on threatUnit")
  assert(tr.unit == nil, t[2] .. " emits the internalVersion-51 `unit` arg on IV-45 data")
  assert(t[1].load.use_ingroup and t[1].load.ingroup.multi.group
     and t[1].load.ingroup.multi.raid and t[1].load.size.multi.arena == nil,
    t[2] .. " lost its party/raid or its not-arena gate")
end
-- The guard the readout cannot ship without: threattotal is threatvalue*100/threatpct, so it
-- is 0 the instant after a Feign Death, and ProgressTexture draws a FULL circle at total == 0.
do
  local guarded = false
  for _, c in ipairs(threat.conditions) do
    if c.check.variable == "threatvalue" and c.check.op == "<="
       and tostring(c.check.value) == "0" and c.changes[1].property == "alpha"
       and c.changes[1].value == 0 then guarded = true end
  end
  assert(guarded, "threat ring lost the threatvalue <= 0 -> alpha 0 guard")
end

-- ===== ALERTS COLUMN CLEARANCE, PROJECTED SIX DEEP =====
-- The threat ring makes the cluster 100px wide, so its right edge moves 8px closer to the
-- Alerts column than the 84px health arc ever was. Alerts is a DYNAMIC group: it grows UP,
-- one 40px icon at a time, so its footprint is a function of how many prompts are live and a
-- clearance measured with one alert showing proves nothing. It is projected instead — six
-- deep, more simultaneous prompts than this pack can raise — and every icon box is tested
-- against the cluster box, not eyeballed.
local ALERT_ICON = 40
local alertsX, alertsY = absolutePos(gAlerts)
local clusterL, clusterR = cx - THREAT_RING / 2, cx + THREAT_RING / 2
local clusterB, clusterT = cy - THREAT_RING / 2, cy + THREAT_RING / 2
local minGap, sharedRows = math.huge, 0
for depth = 1, 6 do
  -- grow "UP" with selfPoint "BOTTOM": child n's bottom edge sits n-1 pitches above the anchor
  local bottom = alertsY + (depth - 1) * (ALERT_ICON + gAlerts.space)
  local top_, left, right = bottom + ALERT_ICON, alertsX - ALERT_ICON / 2, alertsX + ALERT_ICON / 2
  if not (top_ <= clusterB or bottom >= clusterT) then sharedRows = sharedRows + 1 end
  assert(left > clusterR or right < clusterL,
    ("alert %d (x %d..%d, y %d..%d) overlaps the cluster (x %d..%d, y %d..%d)")
      :format(depth, left, right, bottom, top_, clusterL, clusterR, clusterB, clusterT))
  minGap = math.min(minGap, left - clusterR)
end
assert(minGap > 0, "the alert column and the cluster share screen")

-- ===== RING PROOF =====
-- Three things have to be true of the cluster and not one of them is visible by
-- reading a single line of this file:
--   1. Every readout is a progresstexture on the CIRCULAR path at a CANON diameter. A globe
--      and a ring differ by ONE field (orientation), and that field silently changes which of
--      the others are live, so it is asserted rather than trusted.
--   2. Every portrait carries its unit in BOTH model fields. model_path alone is a silent
--      no-op on a 2.5.x client (the migration that copies it across is gated on IsClassicEra),
--      and the failure mode is an empty square where the face should be — which looks exactly
--      like "the portrait did not load yet" and never gets reported as a bug.
--   3. Each breakpoint mark sits ON its ring at the angle its own threshold implies. This is
--      the one thing the vessel build made trivial and the ring build does not: a waterline is
--      a height, an arc mark is an angle, and a mark 9px inside its own arc looks exactly like
--      a mark on it until somebody measures it.
local RINGS = {
  { threat, THREAT_RING, { "subtext" },                             "threat ring" },
  { hp,     OUTER,       { "subtext" },                             "health ring" },
  { mana,   INNER,       { "subtext", "subtexture", "subtexture" }, "mana ring" },
}
for _, r in ipairs(RINGS) do
  local region, size, subs, label = r[1], r[2], r[3], r[4]
  assert(region.regionType == "progresstexture", label .. " is not a progresstexture")
  assert(region.orientation == "CLOCKWISE",
    label .. " is on the LINEAR fill path (" .. tostring(region.orientation) .. ")")
  assert(region.startAngle == 0 and region.endAngle == 360, label .. " is not a full circle")
  assert(region.crop_x == 0.41 and region.crop_y == 0.41,
    label .. " lost the identity crop, so it draws 1.41x oversized and clipped")
  assert(region.backgroundOffset == 0, label .. " has a fattened track")
  assert(region.foregroundTexture == RING_TEX and region.backgroundTexture == RING_TEX
     and region.sameTexture, label .. " is not drawn with the canon ring art")
  assert(region.width == size and region.height == size,
    ("%s is %dx%d, canon says %d"):format(label, region.width, region.height, size))
  assert(#region.subRegions == #subs,
    ("%s has %d subregions, expected %d"):format(label, #region.subRegions, #subs))
  for i, want in ipairs(subs) do
    assert(region.subRegions[i].type == want,
      ("%s: sub.%d is a %s, expected %s")
        :format(label, i, tostring(region.subRegions[i].type), want))
  end
end

-- The one surviving track ring, and the halo: both plain textures on the same annulus art.
-- The halo is checked at HALO (= THREAT_RING) and for its ADD blend, because "pulses ON the
-- threat ring" is exactly a diameter claim plus a blend claim.
local BASES = {
  { powerTrack, INNER, "BLEND", "mana track" },
  { flash,      HALO,  "ADD",   "threat halo" },
}
for _, b in ipairs(BASES) do
  local region, size, blend, label = b[1], b[2], b[3], b[4]
  assert(region.regionType == "texture" and region.texture == RING_TEX,
    label .. " is not drawn with the canon ring art")
  assert(region.blendMode == blend,
    ("%s blends %s, expected %s"):format(label, tostring(region.blendMode), blend))
  assert(region.width == size and region.height == size,
    ("%s is %dx%d, canon says %d"):format(label, region.width, region.height, size))
end

local PORTRAITS = {
  { pPortrait, "player", "portrait" },
}
for _, p in ipairs(PORTRAITS) do
  local region, unit, label = p[1], p[2], p[3]
  assert(region.regionType == "model", label .. " is not a model region")
  assert(region.model_fileId == unit and region.model_path == unit,
    label .. " does not carry its unit in BOTH model_fileId and model_path")
  assert(region.modelIsUnit and region.portraitZoom,
    label .. " is not a zoomed live unit portrait")
  assert(region.width == PORTRAIT and region.height == PORTRAIT,
    ("%s is %dx%d, canon says %d"):format(label, region.width, region.height, PORTRAIT))
  assert(#region.subRegions == 0, label .. " carries a subregion a model cannot draw")
end

local MARKS = { { 2, 0.20, "Go Viper" }, { 3, 0.80, "Back to Hawk" } }
for _, m in ipairs(MARKS) do
  local sub, fraction, label = mana.subRegions[m[1]], m[2], m[3]
  local wantR = INNER / 2 * 0.94
  local gotR = math.sqrt(sub.xOffset ^ 2 + sub.yOffset ^ 2)
  assert(math.abs(gotR - wantR) <= 0.02,
    ("%s mark sits at radius %.2f, its ring's mark radius is %.2f"):format(label, gotR, wantR))
  local turns = math.atan2(sub.xOffset, sub.yOffset) / (2 * math.pi)
  if turns < 0 then turns = turns + 1 end
  assert(math.abs(turns - fraction) <= 0.0005,
    ("%s mark is %.4f of the way round the ring, its threshold is %.2f")
      :format(label, turns, fraction))
end

-- ===== assemble (v2000 nested), encode, verify, write =====
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

local txtPath = dir .. "/all-specs.txt"
-- uid continuity vs the PREVIOUS version's string, read before it is overwritten.
-- v13 is the first version of this pack that is ALLOWED to lose uids, and the licence is
-- exactly as wide as the declared list: changed must still be 0, the top-level uid must still
-- match, and every uid that disappears must be one of the five regions REMOVED names. A sixth
-- missing id would mean a surviving aura silently lost its identity, which is the failure this
-- check has always existed to catch.
local cont = W.uidContinuity(encoded, txtPath)
W.assertUidContinuity(cont, "hunter", REMOVED)
local declared = {}
for _, id in ipairs(REMOVED) do
  declared[id] = true
  assert(not byId[id], "declared WA-REMOVED but still built: " .. id)
end
local droppedThisRun = 0
if cont then
  -- Direction that must ALWAYS hold: nothing may vanish that is not on the list. The other
  -- direction is only true on the run that does the removing — the build is idempotent, so a
  -- second run compares v13 against v13 and correctly reports nothing missing at all.
  for _, id in ipairs(cont.missingIds or {}) do
    assert(declared[id], "undeclared uid removal: " .. id)
    droppedThisRun = droppedThisRun + 1
  end
end

local out = io.open(txtPath, "w")
out:write(encoded)
out:close()

print(("OK: %d auras (top + %d children), %d chars -> all-specs.txt")
  :format(#transmit.c + 1, #transmit.c, #encoded))
if cont then
  print(("uid continuity vs previous: stable=%d changed=%d missing=%d parentSame=%s")
    :format(cont.stable, cont.changed, cont.missing, tostring(cont.parentSame)))
  print(("declared removed (%d, %d dropped out against the string on disk): %s")
    :format(#REMOVED, droppedThisRun, table.concat(REMOVED, ", ")))
end
for _, e in ipairs(EXPECT) do
  local x, y = absolutePos(e[1])
  print(("  %-12s %-26s absolute (%+d,%+d)  %dpx"):format(e[4], e[1].id, x, y,
    e[1].width or 0))
end
print(("  cluster box x %d..%d, alerts column x %d..%d, gap %dpx, projected %d deep "
  .. "(%d of those rows share the cluster's y band)")
  :format(clusterL, clusterR, alertsX - ALERT_ICON / 2, alertsX + ALERT_ICON / 2,
    minGap, 6, sharedRows))
