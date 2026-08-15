-- generate.lua — "Paladin TBC - All Specs" (v10)
-- Holy / Protection / Retribution HUD in one import; spec pieces auto-load via
-- Spell Known gates. Built entirely with the wa_factory builders (zero custom code)
-- except the two unit-orb region tables, which wa_factory has no builder for.
--
-- v10 — ONE ORB SIZE ACROSS EVERY PACK. Pure geometry: not one trigger, load gate,
-- condition, colour, spell id or region type changed, no aura was added or removed, and
-- every uid is byte-identical to v9. What changed is that the seven class packs had each
-- picked their own ring diameters (paladin 118/88/60, mage 120/100/72, warlock 128/96/64,
-- ...) and, worse, the two clusters INSIDE this pack disagreed: the player orb was 88 wide
-- and the target orb 118, so the same two faces read as different sizes side by side.
-- Every pack now builds from the same seven canonical constants (see ORB_OUTER below):
--
--   ring          v9 (paladin)   v10 (all seven packs)
--   player health      88                104   ORB_OUTER
--   player mana        60                 78   ORB_MID
--   target threat     118                104   ORB_OUTER
--   target health      88                 78   ORB_MID
--   threat halo       132                104   ORB_OUTER (pulses ON the threat ring)
--   portrait           28                 46   PORTRAIT
--   cluster x        +-252              +-260   CLUSTER_X
--
-- Both clusters now present the SAME outer diameter and the SAME portrait; the target
-- simply nests one more ring inside. ORB_INNER (54) is the third target ring in the packs
-- that draw target power — paladin deliberately draws none (see the note at the target
-- cluster), so it is defined and left unused rather than absorbed into another ring.
--
-- The art changed with the size: Ring_20px.tga replaces Ring_10px.tga everywhere. The
-- stroke of these annuli is proportional to the drawn size (the number is the weight in
-- the 256x256 source), so Ring_10px at 104px is a 4px wire — it read as a hairline, which
-- was the first thing anyone said about v9. Ring_20px at 104px is an 8.1px band.
--
-- NO BREAKPOINT MARKS TO RE-DERIVE. Rogue/druid/mage/hunter position "spend at N" ticks by
-- trigonometry off the ring RADIUS, so their marks had to be recomputed for the new
-- diameters. This pack has none, and never did: its one resource threshold ("mana under
-- 20%") is a colour condition, not a mark. Nothing here is anchored to a radius except the
-- percentages, which hang below/above the cluster centre and moved with the canonical
-- PCT_* offsets.
--
-- The Swing Timer stayed exactly where it was on screen (absolute y = -170): the Resources
-- anchor moved so the cluster groups could carry the canonical offsets, and the bar's own
-- offset absorbed that, so the runway keeps its clearance from the cooldown row while
-- gaining room under the now-smaller orb (22px from the mana percentage instead of 5px).
--
-- v9 — THE CENTRE OF THE SCREEN IS EMPTY. The 172px health / mana / threat bar stack
-- that sat under the character since v1 is gone, replaced by two UNIT ORBS flanking it:
-- the player's own state on the LEFT, the target's on the RIGHT, each a live 3D portrait
-- ringed by concentric progress arcs with the percentages underneath. Unit state belongs
-- AT the unit; the middle of the HUD is the most expensive real estate there is and a
-- paladin was spending it on three bars that never move relative to each other.
--
-- NOTHING IS ORPHANED AND NOTHING IS DELETED. The three bars were TRANSFORMED, not
-- replaced: "Paladin - Health", "Paladin - Mana" and "Paladin - Threat" keep their aura
-- ids AND their uids and simply become `progresstexture` rings, so the re-import is an
-- in-place Update with zero leftovers. Five genuinely new auras (the two cluster groups,
-- the target health ring and the two portraits) consume five NEW W.uid() calls appended
-- after every existing one, at the bottom of this script. 43 auras -> 48.
--
-- WHAT MOVED, AND THE ONE FIELD RENAME THAT WOULD HAVE BEEN SILENT
--   * Ring fill colour is `foregroundColor`, NOT `barColor`. `barColor` does not exist on
--     progresstexture, and Conditions.lua skips a condition whose property is absent from
--     the region's property table — no error, no editor warning, just a dead escalation.
--     Every colour condition that moved onto a ring was renamed. The Swing Timer below is
--     still an aurabar, so it correctly keeps `barColor`.
--   * THREAT IS NOW THE OUTERMOST RING OF THE TARGET ORB. Threat is your threat on that
--     target, so it belongs at the target, and the Threat Situation prototype is
--     progressType "static" with hidden value/total args — value/total is exactly
--     threatpct/100, so the ring fills 0..100% of the pull threshold with no extra wiring.
--     Both threat elements keep their in-group and not-in-an-arena load gates unchanged.
--   * ZERO-TOTAL INVERSION — the one true regression risk of this migration, and it is
--     guarded. aurabar draws EMPTY at total == 0 (AuraBar.lua: `local progress = 0`);
--     progresstexture draws FULL (`local progress = 1`). Threat hits total == 0 whenever
--     threatvalue is 0 — post-Divine-Shield, before your first hit lands — so an unguarded
--     threat ring would slam to a full circle, meaning "at the pull threshold", while the
--     colour conditions stayed green. Every ring therefore carries an explicit
--     hide-at-no-data condition on its own trigger: `threatvalue <= 0 -> alpha 0`,
--     `maxhealth <= 0 -> alpha 0` (UnitHealthMax has no floor, so a target whose max
--     health has not streamed yet would flash full), `maxpower <= 1 -> alpha 0` (the Power
--     prototype's total IS floored at 1, which is why this one reads <= 1 and not <= 0).
--   * ONE PROGRESS-SUPPLYING TRIGGER PER RING, and it must be trigger 1. Modernize's
--     internalVersion < 71 block rewrites `progressSource` to {-1, ""} (Automatic) on every
--     progresstexture no matter what is emitted, and Automatic reads the FIRST ACTIVE
--     trigger's value/total (`activeTriggerMode = -10`). Health and mana can never share a
--     ring — which is precisely what makes the concentric layout necessary. The second
--     trigger on the player rings is the existing Unit Characteristics state feeder and is
--     used for conditions only (the 50% out-of-combat fade), exactly as the bars used it.
--   * The Swing Timer runway is NOT a unit resource and did not become a ring; see the v3
--     block below for where it went and why.
--   * `F.threatTrigger` emits `use_threatUnit` / `threatUnit`, but the prototype's argument
--     is plain `unit`. It is dead data that works only by accident (the prototype's `init`
--     does `trigger.unit = trigger.unit or "target"` before events() reads it). This pack
--     now emits the real field name too. The factory and gotchas.md still teach the wrong
--     name — a toolkit fix, not a pack fix, so it is deliberately not made here.
--
-- NO RESOURCE BREAKPOINT MARKS WERE LOST, because this pack never had any: the aurabar
-- `subtick` sub-region (which is aurabar-only and could not have come along) is used by
-- rogue, druid and mage, not by paladin. The paladin's one resource threshold is
-- "mana under 20%", which was a colour change on the bar and is a colour change on the
-- ring — carried across verbatim.
--
-- v8 — the Hammer of Wrath execute prompt now really is hostile-only. v4 set
-- use_hostility on its Health trigger, but hostility is not an argument of the Health
-- prototype (only Unit Characteristics defines it), so WeakAuras ignored the field and
-- the prompt fired for a wounded ALLY under 20% too. Fixed with a third trigger — a
-- Unit Characteristics hostility check AND-ed alongside, the same form the TARGET
-- IMMUNE prompt already used. Gating and uids untouched.
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

-- v9: F.threatTrigger emits `use_threatUnit` / `threatUnit`, which are NOT arguments of
-- the Threat Situation prototype — its unit argument is plain `unit` (default "target").
-- The shipped strings work only because the prototype's init runs
--   trigger.unit = trigger.unit or "target"
-- and GenericTrigger calls ConstructFunction (which runs init and mutates the trigger
-- table) BEFORE events() and internal_events() read trigger.unit. Aiming threat anywhere
-- other than "target" via `threatUnit` would silently stay on target. Emit the real name.
local function threatTrigger(minPct)
  local tr = F.threatTrigger(minPct)
  tr.unit = "target"
  return tr
end

-- ===== v10 CANONICAL unit-orb geometry ======================================
-- THESE SEVEN CONSTANTS ARE SHARED BY ALL SEVEN CLASS PACKS. They are not paladin tuning
-- knobs: retuning one pack in isolation is exactly how v9 ended up with seven different
-- orb sizes on one screen. Change them in every pack or in none.
--
-- Ring assignment (identical in every pack, which is what makes the two sides match):
--   PLAYER cluster: health = ORB_OUTER, primary power = ORB_MID, portrait = PORTRAIT
--   TARGET cluster: threat = ORB_OUTER, health = ORB_MID, power = ORB_INNER, portrait
-- so both clusters present the same outer diameter and the same face, and the target just
-- nests one more ring. A pack with no target power ring leaves ORB_INNER unused rather
-- than resizing anything else — which is this pack (no target mana ring; see below).
local ORB_OUTER = 104   -- outermost ring, BOTH clusters, EVERY pack
local ORB_MID   = 78
local ORB_INNER = 54    -- unused here on purpose: paladin draws no target power ring
local PORTRAIT  = 46    -- the live 3D face in the middle of both clusters
local CLUSTER_X = 260   -- player cluster at -260, target cluster at +260
local CLUSTER_Y = -60   -- both cluster centres, in screen coords (see G.bandY)
-- Ring_20px.tga is a true annulus and ships inside WeakAuras. The number is the stroke
-- weight in the 256x256 source, so a ring drawn at S px carries a band of S*20/256:
-- 8.1px at ORB_OUTER, 6.1px at ORB_MID. Ring_10px — what v9 used — is half that, a 4px
-- wire at these diameters, which is what read as "thin and cheap" in game.
-- (F.TEX_CIRCLE / Circle_Smooth2.tga, what the rest of this repo uses, is a SOLID DISC
-- and would fill as a pie wedge, not a ring.)
local RING = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Ring_20px.tga"

-- Percentage placement, also canonical across the seven packs. Each number rides on its
-- own ring as a subtext anchored CENTER, i.e. offsets are from the CLUSTER CENTRE, so the
-- two clusters put their numbers on the same baselines even though their rings differ.
local PCT_MAIN_SIZE,   PCT_MAIN_Y   = 14, -60   -- health, just under the outer ring
local PCT_SUB_SIZE,    PCT_SUB_Y    = 11, -76   -- power, under it
local PCT_THREAT_SIZE, PCT_THREAT_Y = 11,  60   -- threat, ABOVE the ring: three numbers
                                                -- stacked under one orb is a queue, not a
                                                -- readout
-- ===== pack-local layout ====================================================
-- Everything below is paladin's own stacking, not shared geometry. All offsets are
-- relative to the group that owns the region; the top-level group sits at (0, -140).
local TOP_Y = -140
local G = {
  -- Resources holds the two cluster groups and the Swing Timer, and nothing else. It
  -- anchors at the SCREEN ORIGIN (which is what -TOP_Y means: it cancels the top group's
  -- own drop), so the cluster groups' offsets ARE their screen position and can carry the
  -- canonical (+-CLUSTER_X, CLUSTER_Y) verbatim, exactly as every other pack's cluster
  -- groups do. Give this band a drop of its own again and the cluster offsets stop being
  -- the canonical numbers, which is the drift this whole version exists to end. v9 had the
  -- band at 62 and the clusters at 0 — centres at -78; they now sit at -60, the 18px of
  -- headroom the percentages needed once they moved to the shared baselines.
  bandY      = -TOP_Y,
  clusterX   = CLUSTER_X,   -- clears the Alerts column (x = -150, 40px icons) and the PvP
                            -- column (x = 150): the widest cluster is ORB_OUTER, so its
                            -- inner edge sits at 208, and the whole cluster stays above
                            -- the cooldown row (top edge y = -190).
  clusterY   = CLUSTER_Y,
  thRing     = ORB_OUTER,   -- OUTERMOST, target cluster only: threat toward the pull point
  flashRing  = ORB_OUTER,   -- the >=80% threat halo, pulsing ON the threat ring
  hpRing     = ORB_OUTER,   -- PLAYER health: the outer ring of the player cluster
  tHpRing    = ORB_MID,     -- TARGET health: one ring in from the target's threat ring
  mpRing     = ORB_MID,     -- player mana, inside the player's health ring
  portrait   = PORTRAIT,
  hpTextY    = PCT_MAIN_Y,   hpTextSize = PCT_MAIN_SIZE,
  mpTextY    = PCT_SUB_Y,    mpTextSize = PCT_SUB_SIZE,
  thTextY    = PCT_THREAT_Y, thTextSize = PCT_THREAT_SIZE,
  -- The runway keeps its v9 SCREEN position (absolute y = -170, between the mana
  -- percentage at -136 and the cooldown row at -190); the offset changed only to absorb
  -- the band move above. It is a child of Resources, not of the player cluster, so it is
  -- measured from the band anchor and not from CLUSTER_Y.
  swingY     = -170, swingW = 140, swingH = 9,
}

-- The bar colours are carried across byte-for-byte so the HUD still speaks the same
-- language; only the shape changed.
local COL = {
  health  = { 0.15, 0.78, 0.25, 1 },   -- the v8 health bar green
  mana    = { 0.10, 0.45, 0.95, 1 },   -- the v8 mana bar blue
  threat  = { 0.25, 0.80, 0.30, 1 },   -- the v8 threat bar green
  flash   = { 1, 0.10, 0.10, 0.85 },   -- the v8 threat flash red
  track   = { 0, 0, 0, 0.55 },         -- the unfilled arc behind every ring
  lowHp   = { 0.90, 0.12, 0.12, 1 },
  lowMana = { 0.85, 0.15, 0.15, 1 },   -- the v8 "mana under 20%" red, unchanged
  thHigh  = { 1, 0.60, 0.10, 1 },      -- the v8 ">= 70% threat" orange, unchanged
  thAggro = { 0.90, 0.12, 0.12, 1 },   -- the v8 "you hold aggro" red, unchanged
  hpText  = { 1, 1, 1, 1 },
  mpText  = { 0.55, 0.75, 1, 1 },      -- echoes its own ring, so the two numbers under an
  thText  = { 0.72, 0.95, 0.74, 1 },   -- orb never need labels to tell them apart
}

-- RING (the bundled Ring_20px.tga annulus) is declared with the canonical geometry above.
local IV, TOC = 45, 20501

-- wa_factory's stub() is local to the factory, so the two hand-written region types below
-- get the identical scaffolding here.
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

-- Radial progress ring. Field notes on the ones that are traps:
--   orientation CLOCKWISE  -> the only radial values are CLOCKWISE / ANTICLOCKWISE; every
--     other entry in orientation_with_circle_types is linear and would silently draw a bar.
--   startAngle 0 / endAngle 360 -> a full circle. WA normalises 0/360 -> 0/0 and then
--     corrects endAngle back up by 360, so this is handled, not a degenerate case.
--   crop_x / crop_y = 0.41 -> the IDENTITY value, NOT "no crop". The circular path expands
--     the texture by sqrt(2) so rotated quadrants never run off it, and 1 + 0.41 exactly
--     cancels that. Setting 0 blows the ring up 1.41x and clips it.
--   auraRotation = 0 -> absent from the 3.5.0 default table but read unconditionally by
--     current code as data.auraRotation / 180 * math.pi, so it must be emitted.
--   backgroundOffset = 0 -> the default 2 fattens the track relative to the fill, which
--     reads as a halo instead of a concentric track.
--   adjustedMin/Max are STRINGS (""), because SetAdjustedMin does adjustedMin:find(...).
--   progressSource is rewritten to {-1, ""} by Modernize < 71 whatever is emitted; it is
--     here for readability. {-1,""} = Automatic, which routes the first active trigger's
--     value/total into the fill with no further wiring.
--   compress / slanted / slant / slantFirst / slantMode are LINEAR-only and inert on a
--     circular ring; they are emitted because they are in the region's default table.
local function ring(id, size, color, trigs)
  return orbStub{
    regionType = "progresstexture", id = id, uid = W.uid(), parent = nil,
    width = size, height = size,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = 0, yOffset = 0, frameStrata = 1, alpha = 1,
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
    triggers = F.triggers(trigs),
    load = F.load(CLASS),
  }
end

-- Live unit portrait — a real 3D portrait of whoever is targeted, not a static image and
-- not a class icon, which is what lets the target orb work without ever knowing the
-- target's class: it renders NPCs and mobs too.
--   modelIsUnit = true + model_fileId = "<unit>" -> PlayerModel:SetUnit(unit)
--   portraitZoom = true                          -> SetPortraitZoom(1), Blizzard framing
-- CRITICAL: current code reads the unit from `model_fileId`. WA 3.5.0 read `model_path`,
-- and the migration bridging the two (Modernize < 72) is guarded by IsClassicEra(), which
-- is a DISTINCT predicate from IsTBC() — so on a 2.5.x client that migration DOES NOT RUN
-- and emitting only model_path is a silent no-op. Both are emitted; model_fileId works.
-- The portrait carries the same Health trigger as its own orb, so it self-hides with it.
local function portrait(id, unit, size)
  local tr = F.healthTrigger()
  tr.unit = unit
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
    triggers = F.triggers({ tr }),
    load = F.load(CLASS),
  }
end

-- The percentages sit OUTSIDE the rings: the middle is occupied by the portrait, and a
-- `model` region cannot carry a text sub-region at all (SubText's supports() gate lists
-- texture / progresstexture / icon / aurabar / empty — not model). So each number rides on
-- its own ring, which also means it appears and disappears with that ring: no target, no
-- numbers; no threat table, no threat number.
local function pct(sym, size, yOffset, color)
  local st = F.subtext("%" .. sym .. "%%", size, "CENTER", sym)
  st.anchorYOffset = yOffset
  st.text_color = color
  return st
end

-- uid order is sacred: one W.uid() per region, consumed by the constructor below,
-- in exactly this creation order. Append new regions at the END in future versions.

-- 1) top-level group, anchored below the character
local top = F.group(TOP, 0, -140, nil)
top.frameStrata = 1

-- ===== 2) Resources: the two unit orbs (v9; was a 172px bar stack through v8) =====
-- This group now only holds the two cluster groups, which are created at the very BOTTOM
-- of this script so their uids append after every existing one. Its own uid is unchanged,
-- so a dragged Resources position survives the update.
local gRes = reg(F.group("Paladin - Resources", 0, G.bandY, TOP))
adopt(top, gRes)

-- 3) PLAYER HEALTH — the outer ring of the player orb. Was the 172x14 health aurabar
-- through v8; same aura id, SAME UID, so this updates in place rather than orphaning.
-- Trigger 2 is the existing Unit Characteristics state feeder and drives the out-of-combat
-- fade ONLY; progress comes from trigger 1 (Automatic progress = first active trigger).
-- v9 adds the low-health tier the bar never had: at ring scale colour does far more work
-- than length, and "I am about to die" is the one state a 52px radius must shout.
local hp = reg(ring("Paladin - Health", G.hpRing, COL.health,
  { F.healthTrigger(), F.unitCharTrigger() }))
hp.subRegions[1] = pct("percenthealth", G.hpTextSize, G.hpTextY, COL.hpText)
hp.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "percenthealth", "<", "30", "foregroundColor", COL.lowHp),
  -- LAST: UnitHealthMax has no floor in the prototype, so a unit whose max health has not
  -- streamed yet gives total == 0 — and progresstexture draws total == 0 as FULL, the exact
  -- inverse of what the aurabar did. Hide instead of lying. Must come after the fade,
  -- because a later condition overwrites the same property.
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}
-- adopted into the player cluster at the bottom of this script

-- 4) PLAYER MANA — the inner ring. The paladin resource in every spec; red below 20%,
-- carried across from the v8 bar with `barColor` renamed to `foregroundColor` (the ONLY
-- name progresstexture exposes — a carried-over `barColor` is silently dropped).
local mp = reg(ring("Paladin - Mana", G.mpRing, COL.mana,
  { F.powerTrigger(0), F.unitCharTrigger() }))
mp.subRegions[1] = pct("percentpower", G.mpTextSize, G.mpTextY, COL.mpText)
mp.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "percentpower", "<", "20", "foregroundColor", COL.lowMana),
  -- The Power prototype floors total at math.max(1, UnitPowerMax(...)), which is why this
  -- guard reads <= 1 and not <= 0. Dead weight on a paladin, kept for ring discipline.
  F.condition(1, "maxpower", "<=", "1", "alpha", 0),
}
-- adopted into the player cluster at the bottom of this script

-- 5) THREAT — now the OUTERMOST ring of the TARGET orb, because your threat is threat on
-- that target. Party/raid only, and never in an arena. For prot, red = "I have aggro" =
-- the goal state, not an alarm. The Threat Situation prototype is progressType "static"
-- with hidden value/total args and threattotal = threatvalue * 100 / threatpct, so
-- value/total is exactly threatpct/100 and the ring fills 0..100% of the pull threshold.
local th = reg(ring("Paladin - Threat", G.thRing, COL.threat, { threatTrigger() }))
th.subRegions[1] = pct("threatpct", G.thTextSize, G.thTextY, COL.thText)
th.conditions = {  -- severe last: a later match overwrites the same property
  F.condition(1, "threatpct", ">=", "70", "foregroundColor", COL.thHigh),
  F.condition(1, "aggro", "==", 1, "foregroundColor", COL.thAggro),
  -- THE MIGRATION'S WORST TRAP, guarded. threattotal is threatvalue-derived, so it is 0
  -- whenever threatvalue is 0 — the instant before your first hit lands, and right after a
  -- Divine Shield drop. The v8 aurabar drew that as EMPTY; a progresstexture draws it as
  -- FULL, i.e. "you are at the pull threshold", while these colour conditions stay green
  -- because threatpct is 0. Shape and colour would contradict each other at the worst
  -- possible moment. `threatvalue` is a stored number arg; the hidden `total` is not.
  F.condition(1, "threatvalue", "<=", "0", "alpha", 0),
}
inGroup(th)
noArena(th)   -- v6: an arena party is still a party, but has no threat table
-- adopted into the target cluster at the bottom of this script

-- 6) >=80% threat HALO — Ret only (a tank AT aggro must not be alarmed). Was a 176x18
-- rectangle pulsing over the bar through v8, then a 132px ring floating outside the 118px
-- threat arc in v9. v10 draws it at ORB_OUTER with the same art as the threat ring, so the
-- halo pulses exactly ON that ring (ADD blend over the same circle = the ring itself
-- flaring red) instead of hovering in empty space 7px outside it — the same failure the
-- other packs' breakpoint ticks had. Same trigger, same threshold, same gates, same uid.
local flash = reg(F.texture("Paladin - Threat Flash", CLASS, G.flashRing, G.flashRing, 0, 0,
  nil, RING, COL.flash))
flash.blendMode = "ADD"
flash.triggers = F.triggers({ threatTrigger(80) })
flash.animation.main = F.animPreset("alphaPulse", "1")
inGroup(flash)
noArena(flash)   -- v6: a pulsing red alarm that can never fire is the worst kind of clutter
gate(flash, GATE_RET)
-- adopted into the target cluster at the bottom of this script

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

-- Hostility is NOT an argument of the Health prototype — only Unit Characteristics
-- defines it. Setting use_hostility on a Health trigger is a silent no-op: WeakAuras
-- ignores the unknown field and the trigger fires for any unit under the threshold,
-- friendly included. The only working form is a separate Unit Characteristics trigger
-- AND-ed alongside (disjunctive "all"), which is what the TARGET IMMUNE prompt below
-- also relies on.
local function targetHostileTrigger()
  local tr = F.unitCharTrigger()
  tr.unit = "target"; tr.use_hostility = true; tr.hostility = "hostile"
  return tr
end

-- 17) execute window: HOSTILE target under 20% HP AND Hammer of Wrath ready.
-- Baseline at 44 and a numbered Protection priority line too, so it gates on its own
-- rank-1 id (known from 44 onward) instead of on a spec capstone. Trigger 3 is what
-- actually stops a wounded ALLY under 20% from firing a prompt for a spell you cannot
-- cast on them — v4 tried to do it with use_hostility on trigger 1, which did nothing.
local howHealth = F.healthTrigger(20)
howHealth.unit = "target"
local how = alert("Paladin - Hammer of Wrath", "Interface\\Icons\\ability_thunderclap", GOLD, 24275)
how.triggers = F.triggers({
  howHealth,
  F.cdTrigger(24275, "Hammer of Wrath", "showOnReady"),
  targetHostileTrigger(),
})
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

-- 31) the runway: main-hand swing draining toward impact, gold inside the twist window.
--
-- v9 — WHY THIS IS STILL A BAR, AND WHERE IT WENT. The swing timer is the one thing in the
-- old Resources stack that is NOT a unit resource: it is an ability-timing runway for a
-- ~0.4s press window, and it does not belong on a unit orb for two independent reasons.
--   1. It is not a property of the player or the target — it is a property of your weapon
--      swing, so there is no unit whose orb it would ring.
--   2. A sub-second window is read as DISTANCE TO AN EDGE. On a 140px linear bar the 0.4s
--      window is ~15px of travel to a fixed right-hand edge; wrapped onto a 52px-radius
--      arc it becomes a rotating tick with no edge to aim at, which is measurably harder
--      to time and is exactly the judgement the twist depends on.
-- So it stays an aurabar (and therefore correctly keeps `barColor`, which does not exist
-- on progresstexture), and it is positioned UNDER THE PLAYER ORB rather than in the vacated
-- centre: it is player state, it is read together with the player's own mana, and putting it
-- back in the middle would give up the whole point of v9. It is 140x9 instead of 172x10 so it
-- stays clear of the Alerts column at x = -150 and of the cooldown row below it.
--
-- It is a SIBLING of the two orb clusters inside Resources, not a child of the player orb,
-- even though it sits under it. Two reasons: a twister who hides the player orb (Blizzard
-- unit frames, a different health addon) must keep the runway, and a 0.4s window is the one
-- element people genuinely want to drag somewhere personal — right under the crosshair, say —
-- without dragging their health and mana ring along with it. Its x offset therefore repeats
-- the cluster's, rather than inheriting it.
--
-- v10 — it did not move on screen. The Resources anchor moved to the screen origin so the
-- cluster groups could carry the canonical (+-260, -60) verbatim, and G.swingY absorbed
-- exactly that re-anchoring (-92 -> -170, both of which are absolute y = -170). The bar is
-- therefore where it always was: 22px below the mana percentage (was 5px, because v9's orb
-- hung 18px lower and its numbers with it) and 15px above the cooldown row's top edge.
local swing = reg(F.aurabar("Paladin - Swing Timer", CLASS, G.swingW, G.swingH,
  -G.clusterX, G.swingY, nil, { 0.55, 0.55, 0.62, 1 }))
swing.triggers = F.triggers({ swingTrigger() })
swing.subRegions[2] = F.subborder("bar")
swing.conditions = {
  F.condition(1, "expirationTime", "<=", TWIST_WINDOW, "barColor", { 1, 0.82, 0.1, 1 }),
}
gate(swing, SWING_GATE)
-- adopted into the player cluster at the bottom of this script

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

-- ===== 44-48) v9: the unit orbs =====
-- EVERYTHING BELOW IS NEW UID TERRITORY. These five constructors sit at the very bottom of
-- the script on purpose: W.uid() draws from a seeded stream, so a new uid() call inserted
-- anywhere above would shift every later aura's uid and turn the whole re-import from an
-- Update into 48 duplicates. Regions built earlier are re-parented down here instead —
-- creation order is what the uid stream sees, parenting order is not.
--
-- Sibling stacking inside a group is exact, not "roughly creation order":
-- FixGroupChildrenOrder walks controlledChildren and adds +4 frame levels per child, so
-- EARLIER = FURTHER BEHIND. Outer ring first, inner rings next, portrait LAST so nothing
-- ever draws over the face.

-- 44/45) the two clusters. Separate groups so each orb can be dragged on its own, and so a
-- player who wants only one of them can disable a single group.
-- v10: both carry the canonical (+-CLUSTER_X, CLUSTER_Y) — the same pair of offsets the
-- cluster groups hold in every other pack.
local gPlayerOrb = reg(F.group("Paladin - Player Orb", -G.clusterX, G.clusterY, gRes.id))
adopt(gRes, gPlayerOrb)
local gTargetOrb = reg(F.group("Paladin - Target Orb", G.clusterX, G.clusterY, gRes.id))
adopt(gRes, gTargetOrb)

-- 46) TARGET HEALTH — the target orb's own ring, and the only fill it has besides threat.
-- Red under 20% is a single unambiguous statement ("this unit is nearly dead") that reads
-- correctly in both directions: on a hostile target it is the Hammer of Wrath execute
-- window that the alert column is already prompting for, and on a friendly target it is
-- the Lay on Hands / Flash of Light emergency. The self-hide needs no condition and no
-- load gate: the Health prototype ANDs in `WeakAuras.UnitExistsFixed(unit, smart)`, so
-- unit = "target" with no target produces NO STATE and this entire cluster vanishes.
local tHealthTrigger = F.healthTrigger()
tHealthTrigger.unit = "target"
local tHp = reg(ring("Paladin - Target Health", G.tHpRing, COL.health, { tHealthTrigger }))
tHp.subRegions[1] = pct("percenthealth", G.hpTextSize, G.hpTextY, COL.hpText)
tHp.conditions = {
  F.condition(1, "percenthealth", "<", "20", "foregroundColor", COL.lowHp),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),   -- see the player ring's note
}
-- adopted below, in back-to-front order with the rest of the target cluster

-- NO TARGET MANA RING, deliberately — which is why ORB_INNER (the third target ring in the
-- packs that do draw target power) is defined above and left unused instead of being spent
-- on something else here: the target cluster's outer two rings must stay at the canonical
-- ORB_OUTER / ORB_MID whatever this pack chooses not to show. Most TBC bosses report mana as their primary bar and
-- sit near full all fight, so the ring would be a permanent blue circle carrying no
-- decision — and v6 already settled the PvP half of this question for this pack: a paladin
-- has no mana drain, burn or punish (Judgement of Wisdom GIVES the attacker mana), so an
-- opponent's mana would not change one paladin button press. The packs that can act on it
-- (warlock / priest / hunter / mage) are where that readout belongs.

-- 47/48) the faces. Created last of all so nothing draws over them.
local pPortrait = reg(portrait("Paladin - Player Portrait", "player", G.portrait))
local tPortrait = reg(portrait("Paladin - Target Portrait", "target", G.portrait))

-- Re-parent the surviving v8 regions into their clusters, back to front. None of these
-- consume a uid — they were constructed in their original positions above.
adopt(gPlayerOrb, hp)          -- outer ring
adopt(gPlayerOrb, mp)          -- inner ring
adopt(gPlayerOrb, pPortrait)   -- face on top

adopt(gTargetOrb, th)          -- outermost ring: threat
adopt(gTargetOrb, flash)       -- the >=80% halo, just outside it
adopt(gTargetOrb, tHp)         -- health ring
adopt(gTargetOrb, tPortrait)   -- face on top

adopt(gRes, swing)             -- sibling of both clusters; see its own note above

-- ===== assemble (v2000 nested), encode, verify, write =====
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

local outPath = dir .. "/all-specs.txt"
-- compare against the previously shipped build BEFORE overwriting it: every future
-- version gets the uid-continuity check for free (changed must stay 0)
local cont = W.uidContinuity(encoded, outPath)
W.assertUidContinuity(cont, "paladin")

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
