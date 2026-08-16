-- generate.lua — Priest TBC All-Specs HUD (v12).
-- Run: lua5.1 tbc/priest/generate.lua   (works from any cwd; paths resolve from this file)
-- Produces all-specs.txt: a "!WA:2!" string importable in game (/wa -> Import -> paste).
--
-- Design: the proven rogue/paladin skeleton adapted to priest. Shadow drives the
-- DoT/threat side; Holy and Discipline pieces load through spellknown gates, so a
-- single pack auto-adapts on respec with no user action. Mutually exclusive spec
-- elements share screen slots (SW:P and Weakened Soul both sit at x=-66).
--
-- Every spell id below was verified on wowhead.com/tbc: aura triggers carry EVERY
-- rank id (as strings, via the factory), cooldown triggers carry the numeric rank-1
-- id, spellknown gates use ids that are really in the spellbook when talented.
-- Zero custom code, zero name matching (zhCN-safe), internalVersion stays 45.
--
-- v2 (rotation review fixes; UIDs are append-only, so this imports as an Update):
--   * Weakened Soul now reads the HEAL TARGET (unit = "target"), not the player, and
--     loads for every non-Shadowform priest — it is the gate on the #1 healer press.
--   * NEW Priest - Renew: your own Renew on the current friendly target (all 12 ranks).
--   * Mind Blast and Shadow Word: Death get a violet ready-glow (the two presses the
--     Shadow rotation clips Mind Flay for); SW:D's glow is suppressed below 50% HP
--     because its backlash is the one thing in this pack that can kill you.
--   * SW:Pain's re-cast glow moved to <= 1s (glowing at 3s told you to clip a tick).
--   * Vampiric Embrace got the same expiry glow as its row-mates; Shadowfiend prompt
--     moved to 50% mana; Fade prompt is combat-gated; Prayer of Mending no longer
--     loads for Shadow; the health bar turns red at the Desperate Prayer threshold;
--     the always-on icon layer fades to 50% alpha out of combat.
--
-- v3 (per-spec load audit — "does this spec PRESS it", not "can it CAST it"):
--   * Holy Procs is no longer ungated: not_spellknown = 15473 (Shadowform). Surge of
--     Light and Holy Concentration are 25- and 30-point Holy talents, so the icon was
--     dead weight in the only spec that could still load it. That leaves exactly four
--     ungated elements (health, mana, threat, Inner Fire), each verified below.
--   * Everything else was audited element-by-element per spec and deliberately kept —
--     see the "Spec gating" section of README.md for the reasoning on the close calls
--     (threat bar + Fade prompt for healers, Fear Ward + Desperate Prayer for Shadow).
--   No element was added, removed or re-ordered, so every uid is unchanged.
--
-- v4 (PvP layer — nine gated elements plus their container group):
--   * Every v4 element carries load.use_size = false with size.multi = { arena, pvp }
--     (or { arena } alone where it reads arena1..arena5). Nothing new loads in a
--     raid, a dungeon or the open world, and no v3 aura was touched, so a PvE
--     player sees exactly the v3 HUD.
--   * Alerts gains four prompts: CC ON ME (any loss of control, with the
--     countdown), FEAR WARD MISSING, MASS DISPEL NOW (target immunity + Mass
--     Dispel ready) and SILENCE NOW (target casting + Silence usable, Shadow).
--   * New "Priest - PvP" column mirrors Alerts on the right with five state
--     read-outs: my trinket down, Will of the Forsaken down, an enemy trinket
--     clock per opponent, Unstable Affliction on a team-mate, and my own CC on
--     each opponent.
--   * NOT built, deliberately: diminishing-returns tracking (no prototype and no
--     library exists — an incomplete DR tracker gets trusted and gets you killed),
--     enemy cooldowns beyond the trinket inference, enemy spec, an interruptible
--     filter (WA disables the arg on TBC), enemy mana (the Power prototype's arena
--     unit support is unverified), and the inverse "hide the threat bar in arena"
--     gate (its open-world behaviour is unproven and it would change a PvE aura).
--
-- v5 (three v4 deferrals resolved against the WeakAuras source; one new aura):
--   * CC ON ME is now colour-coded by controlType, because "which break works" is
--     the decision, not "am I controlled". Same colour language as the mage pack:
--     red stun, purple fear, blue root, green confuse/poly, amber silence/lockout.
--     Verified: subglow is subRegions[1], glow = true and useGlowColor = true, so
--     "sub.1.glowColor" really repaints the glow (with useGlowColor = false the
--     setter runs and nothing changes on screen — the trap this was deferred on).
--     Values are 4-element ARRAYS; a {r=,g=,b=} hash serialises to four nils.
--   * The threat bar and the Fade prompt no longer load in an ARENA. Arena has no
--     threat table, so both were pure clutter there. The open-world worry that
--     blocked this in v4 is settled: GetInstanceTypeAndSize returns the literal
--     string "none" outdoors (WeakAuras.lua:1626 explicit fallthrough), so listing
--     `none` in the multi table keeps them loaded everywhere in PvE.
--   * NEW Priest - Enemy Mana: one bar per arena opponent whose PRIMARY resource
--     is mana, class-coloured, red under 20%. The Mana Burn scoreboard. The Power
--     prototype is present on TBC, its unit arg accepts "arena" (only ClassicEra
--     deletes that value), arena1..5 are registered, and statesParameter = "unit"
--     clones one row per opponent — hence the dynamicgroup parent.
--
-- v6 (the cooldown row now shows what you CANNOT press; no new auras, no new uids):
--   * Six of the nine cooldown icons become genericShowOn = "showOnCooldown" —
--     Shadowfiend, Inner Focus, Power Infusion, Pain Suppression, Lightwell and Fear
--     Ward. Each is situational: a mana cooldown, a burst window, an emergency, a
--     pre-placed well, a pre-fear ward. The icon now exists only while its cooldown
--     runs, carrying the swipe and the countdown, and vanishes when the ability is
--     back. The row is a dynamic group, so the gap closes: ABSENCE IS THE READOUT.
--     Their onCooldown == 1 -> desaturate condition goes with the change — under
--     showOnCooldown every visible icon is on cooldown by definition, so desaturating
--     them all would grey the whole row and make the icons harder to tell apart.
--   * The three press-on-cooldown rotational buttons stay showAlways WITH a ready
--     glow, because a hidden icon cannot announce the moment it comes up: Mind Blast
--     and Shadow Word: Death (violet, the two presses that cancel a Mind Flay), and
--     NEW — Prayer of Mending, which gains the gold Holy glow it never had. PoM is a
--     10s-cooldown cast-on-cooldown staple of the Holy/Disc loop, the most mana-
--     efficient heal in the game, kept rolling on the tank; hiding the healer's most
--     frequent scheduled press would have been exactly the wrong direction.
--     Those three keep their desaturate-while-down condition — they are on screen in
--     both states, so it is still what separates "up" from "down".
--   * Every ready glow is now switched OFF out of combat (inCombat == 0 ->
--     sub.1.glow = false, appended last so it wins). Out of combat every cooldown is
--     up, so the glow was permanent decoration on an idle HUD — and after this pass
--     the out-of-combat row contains nothing BUT those three icons.
--   * No aura added, removed or reordered: only triggers and conditions changed, so
--     all 39 uids are untouched and this imports as an Update.
--
-- v7 (the centre of the screen is given back — health/mana/threat become UNIT ORBS):
--   * The three 172x14 bars that sat stacked under the character are gone as bars.
--     The same three auras are now RINGS around two small live unit portraits: the
--     PLAYER orb out at x = -250 and the TARGET orb at x = +250, flanking the
--     character, so the middle of the screen carries nothing but the buff row, the
--     cooldown strip and the prompts. Layout proof: poc/unit-orbs/.
--   * Each orb is a `model` portrait of the unit (SetUnit + portrait zoom, so the
--     target side renders any mob or player without knowing its class) inside an
--     outer HEALTH ring and an inner MANA ring, with the percentages underneath.
--     The target orb carries a third, outermost THREAT ring — threat is your threat
--     ON THAT TARGET, so it belongs at the target, not on your own body.
--   * Nothing is renamed, deleted or reordered. "Priest - Health", "Priest - Mana"
--     and "Priest - Threat" keep their ids AND their uids and change region type in
--     place; the four new auras (target health, target mana, and the two portraits)
--     are built at the very bottom of this script and re-parented, so all 40 v6 uids
--     keep their positions in the seeded stream. This imports as an Update, and it
--     leaves NO orphan behind.
--   * Every danger state survives the move, with one rename that would otherwise be
--     a silent no-op: on a progresstexture the fill colour property is
--     `foregroundColor`, NOT the aurabar's `barColor`. Conditions.lua skips a change
--     whose property is absent from the region's properties table without any error,
--     so a mechanical port of `barColor` would look right in the editor and do
--     nothing in game. Health still turns red below 40% (the Desperate Prayer line),
--     threat still runs green -> orange at 70% -> red on aggro.
--   * Two guards are NEW and mandatory, because the two region types disagree about
--     an empty total in opposite directions: aurabar draws EMPTY at total == 0
--     (AuraBar.lua `local progress = 0`), progresstexture draws FULL
--     (ProgressTexture.lua `local progress = 1`). Threat total is
--     threatvalue * 100 / threatpct, which is 0 for the whole moment after a Fade,
--     so an unguarded threat ring would slam to a FULL circle — "you are at the pull
--     threshold" — exactly when you have no threat at all. `threatvalue <= 0 ->
--     alpha 0` and `maxhealth <= 0 -> alpha 0` hide the ring instead.
--   * NEW breakpoint pips, which the bars never had: a mark at 40% on the player
--     health ring (where the ring turns red and Desperate Prayer is prompted) and at
--     50% on the mana ring (where the Shadowfiend prompt fires). Sub-region type
--     `subtexture` — the aurabar `subtick` used elsewhere in this repo is aurabar-
--     only and cannot ride a ring.
--   * Untouched: buffs, alerts, the cooldown row, procs and the whole PvP layer.
--
-- v8 (one orb geometry for all seven packs — pure layout, no aura added or removed):
--   * v7 shipped each class pack with its own diameters, and the two clusters inside
--     a pack did not agree either: priest drew 128/96/64 rings with a 28px face, and
--     the player cluster's outer ring (96) was a different size from the target's
--     (128). Seven packs times two clusters read as fourteen differently-scaled
--     gauges. v8 replaces all of it with ONE canonical set, identical in every pack:
--     ORB_OUTER 104, ORB_MID 78, ORB_INNER 54, PORTRAIT 46, clusters at x = +-260.
--     Priest: player health 96 -> 104 (ORB_OUTER) and mana 64 -> 78 (ORB_MID); target
--     threat 128 -> 104 (ORB_OUTER), health 96 -> 78 (ORB_MID) and mana 64 -> 54
--     (ORB_INNER); both faces 28 -> 46. Both clusters now present the SAME outer
--     diameter and the SAME face; the target simply nests one more ring inside.
--   * Ring_10px -> Ring_20px everywhere. The number is the stroke weight in the art's
--     own 256x256 space, so the old texture drew a ~3.8px arc at 96px and thinner on
--     the inner rings: a wire, not a gauge. The 20px art gives ~8.1px at ORB_OUTER.
--   * The percentages become one shared set too — health 14px at y = -60, power 11px
--     at y = -76, threat 11px at y = +60 — and the target cluster now uses the same
--     offsets as the player cluster instead of its own (-84 / -102).
--   * The breakpoint pips were RE-DERIVED, not left where they were: their x/y come
--     from the ring radius, so resizing a ring without recomputing them leaves a mark
--     floating in empty space. The radius formula is now the stroke CENTRE of the
--     actual art, size * (1 - 20/256) / 2, replacing v7's flat `size/2 - 5` inset.
--     40% health pip: r 43 -> 47.9375, (25.275, -34.788) -> (28.177, -38.782).
--     50% mana pip:   r 27 -> 35.953125, (0, -27) -> (0, -35.953). Both still land on
--     their own ring's circumference at their own threshold angle.
--   * NOTHING else changed: no aura added, removed or reordered, no trigger, no load
--     gate, no condition, no colour, no spell id, no region type. All 44 uids are
--     byte-identical to v7, so this imports as a clean Update.
--
-- v9 (the rings become DIABLO GLOBES — same seven auras, no uid added or lost):
--   * A ring encodes a value by SWEEP; a globe encodes it by WATERLINE. Same region
--     type, one different field: orientation "CLOCKWISE" -> "VERTICAL" ("Bottom to
--     Top" — WA's orientation keys lie about direction, VERTICAL_INVERSE would drain
--     the vessel from the top as you take damage). Switching to the linear fill path
--     also swaps which fields are live: compress/slanted/slantMode now matter (all
--     left off — a straight waterline is what reads as liquid), startAngle/endAngle
--     no longer do. Layout proof: poc/diablo-globes/.
--   * THREE vessels on ONE canonical geometry, identical in all seven packs: life
--     116px at x = -300, power 116px at x = +300, target 76px at x = 0, every one of
--     them at ABSOLUTE screen y = -150, each wrapped in a rim of its own size + 6 at
--     frameStrata 2. The y is absolute, so it is DERIVED here (GLOBE_Y - top - group)
--     rather than typed in locally — see GLOBE_LOCAL_Y below.
--   * THE PORTRAITS ARE GONE, and that is what buys the numbers their place: a model
--     region cannot carry a text sub-region at all, which is why v7/v8 had to park
--     every percentage outside its ring. The percentages now sit INSIDE the glass
--     (18px on the two main globes, 13px on the target). Both portrait auras are
--     RECYCLED, not deleted: their uids carry the life and power rims, so the update
--     leaves no orphan in anyone's WeakAuras.
--   * THREAT BECOMES THE TARGET GLOBE'S RIM COLOUR — green, orange at 70%, red on
--     aggro — with the percentage above the globe. It costs no extra element and no
--     extra screen space, which a fourth vessel would. "Priest - Threat" therefore
--     changes region type from progresstexture to texture (the colour property goes
--     with it: `color` on a texture, as `foregroundColor` is on a progresstexture and
--     `barColor` was on the aurabar — Conditions.lua silently skips a property the
--     region does not have). Its arena gate and its mandatory `threatvalue <= 0 ->
--     alpha 0` guard are unchanged. A SECOND, brass rim underneath it (the recycled
--     "Priest - Target Mana" uid, renamed "Priest - Target Rim") carries the target's
--     Health trigger, so the target globe still has a rim when you are on nobody's
--     threat table — which for a healer is most of the time.
--   * The two breakpoint marks get simpler, not harder: on a vessel a threshold is a
--     horizontal line at yOffset = (threshold/max - 0.5) * GLOBE_MAIN, so the 40%
--     health mark is at y = -11.6 and the 50% mana mark at y = 0, both re-derived
--     from the formula rather than carried over. Width is the chord of the globe at
--     that height, so a mark never pokes out of the glass.
--   * LOST: the target's mana ring. Three vessels is the whole canonical set and a
--     target power globe is not one of them. The arena Mana Burn scoreboard (Priest -
--     Enemy Mana, v5) is untouched and still covers the case that decides a press.
--   * Untouched: every trigger, load gate and condition outside the orb cluster, the
--     Desperate Prayer danger tier at 40%, the zero-total guards, buffs, alerts, the
--     cooldown row, procs and the whole PvP layer. No aura added or removed, no uid()
--     call added or reordered: all 44 uids are exactly v8's, so this is an Update.
--
-- v10 (the globes move BESIDE the character, and the glass catches light):
--   * POSITION. v9 parked all three vessels on one band at absolute screen y = -262,
--     directly under the cooldown row, which reads as a second bar bolted under the
--     HUD rather than as part of your character. They now FLANK the character:
--     life at (-190, 40), power at (+190, 40), target at (0, 110) — absolute screen
--     coordinates, identical in all seven packs. The x was scanned against every
--     element in every pack: +-170 collides with the Alerts column (x = -150) and the
--     PvP column (x = +150), +-210 collides with the PvP-layer elements at (200, -44),
--     so 190 is the tightest collision-free arrangement, not a taste call.
--     The target globe rises to its own y (110), which is why GLOBE_TGT_Y exists:
--     the three vessels no longer share one band. Both numbers are ABSOLUTE, so both
--     local offsets stay DERIVED (GLOBE_Y - TOP_Y - RES_Y), exactly as in v9.
--     Nothing else moved: no group, no icon row, no prompt, no PvP element.
--   * LOOK. Every vessel gains ONE new sub-region, a soft specular highlight: a
--     Circle_Smooth disc at 28% white, 0.46 x 0.34 of the globe, offset up and to the
--     left (-0.17, +0.21 of the globe). A flat disc of colour reads as a sticker; an
--     off-centre bright spot is what the eye parses as a CURVED surface catching
--     light, which is the whole difference between a filled shape and liquid in glass.
--   * BLEND MODE "ADD", not "BLEND", and that is load-bearing rather than cosmetic.
--     Sub-regions draw in order and the percentage now sits INSIDE the glass (v9), so
--     an appended BLEND overlay would wash grey over the number. ADD can only
--     brighten, so the text stays readable — which is why the recipe is a highlight
--     and not the more obvious dark edge vignette (a vignette must be BLEND to
--     darken, and would have had to be inserted BEFORE the text to be legal).
--   * APPENDED, never inserted. Conditions address sub-regions positionally as
--     sub.N, so inserting ahead of a referenced index silently retargets it. The
--     highlight is the LAST sub-region on each globe: life [3], power [3] (both after
--     their breakpoint mark), target [2]. No pre-existing sub.N reference in this pack
--     changes meaning.
--   * Sizes, colours, triggers, load gates, conditions, spell ids and region types are
--     all unchanged, and no aura is added or removed: all 44 uids are exactly v9's, so
--     this is an Update.
--
-- v11 (the globes go back to being RINGS around a live portrait — same 44 auras):
--   * THE DESIGN IS TWO RINGS AND A FACE, PER UNIT, and both clusters are built to
--     the same numbers so they read as a matched pair:
--       PLAYER at absolute (-270, 40): outer 84 health, inner 62 mana, 44px face
--       TARGET at absolute (+270, 110): outer 84 THREAT, inner 62 health, 44px face
--     A target POWER ring is deliberately not built — a third ring is what made the
--     v7/v8 version look busy and uneven, and its uid is recycled (see below).
--   * ONE FIELD flips the vessels back into rings: orientation "VERTICAL" ->
--     "CLOCKWISE". That also swaps which of the neighbouring fields are live —
--     startAngle/endAngle matter again, compress/slanted/slantMode go inert — and
--     the texture goes back to the Ring_20px annulus. crop 0.41 stays: it is the
--     identity value on the circular path (it cancels the sqrt(2) expansion), so
--     setting 0 would blow every ring up by 1.41x and clip it.
--   * THE PORTRAITS COME BACK, in the two uid slots they held in v7/v8, and that is
--     what pushes the percentages back OUTSIDE the rings: a `model` region cannot
--     carry a text sub-region at all, so the numbers ride on their own ring, health
--     13px at y = -54 (just under the outer ring), power 10px at -70, threat 10px at
--     +54. Both `model_fileId` AND `model_path` carry the unit string: current WA
--     reads model_fileId, 3.5.0 read model_path, and the migration that bridges them
--     is gated on IsClassicEra — which is NOT IsTBC, so on this pack's 2.5.x client
--     emitting only model_path is a silent no-op.
--   * THREAT IS A RING AGAIN rather than a rim colour, so its region type changes
--     from texture back to progresstexture and its two danger escalations move from
--     `color` back to `foregroundColor` (Conditions.lua skips an unknown property
--     silently — no error, no warning, nothing on screen). Its arena gate and the
--     mandatory `threatvalue <= 0 -> alpha 0` guard are unchanged, and that guard
--     matters more on a ring than it did on a rim: a progresstexture draws FULL at
--     total == 0, so without it zero threat would read as full aggro.
--   * THE BREAKPOINT MARKS go back to circumference marks, each derived from ITS OWN
--     ring's radius (r = size/2 * 0.94, x = r*sin(2*pi*f), y = r*cos(2*pi*f), angle 0
--     at 12 o'clock increasing clockwise like the fill): 40% health at (23.206,
--     -31.94) on the 84px ring, 50% mana at (0, -29.14) on the 62px one. Each pip is
--     a square of its own ring's band width (size * 20/256), so it fills the stroke
--     instead of poking out of it. Same colour, same thresholds, same conditions.
--   * DROPPED: the v10 specular highlight. It was a glass effect for a filled vessel
--     and does nothing on a ring. It was the LAST sub-region on every globe, so
--     removing it retargets no `sub.N` reference anywhere in the pack.
--   * The fourth recycled uid — the v7/v8 target mana ring, the v9/v10 brass target
--     rim — becomes "Priest - Target Track": the dark outer annulus the threat arc
--     sweeps over, carrying the target's Health trigger. The threat ring self-hides
--     whenever you are not on a threat table, which for a healer is most of the time,
--     and without the track the target cluster would collapse to one ring and a face
--     while the player cluster still showed two. It occupies exactly the threat
--     ring's circle, so the design is still two rings and a face.
--   * Untouched: every trigger, load gate and condition outside the cluster, the
--     Desperate Prayer danger tier at 40%, the zero-total guards, the out-of-combat
--     fade, buffs, alerts, the cooldown row, procs and the whole PvP layer. No aura
--     added or removed, no uid() call added or reordered: all 44 uids are exactly
--     v10's, so this imports as an Update with nothing left to delete.
--
-- v12 (the TARGET cluster is deleted; threat comes home as YOUR outermost ring):
--   * THE WHOLE TARGET CLUSTER IS GONE — target health ring, target track and target
--     portrait, three auras, deleted rather than repurposed. The target's health is
--     already on the Blizzard target frame and on its nameplate, an arm's length from
--     where this pack drew it a second time, so for the entire game the cluster was a
--     duplicate of the default UI wearing a nicer ring. A HUD earns its space by
--     showing what nothing else shows.
--   * THREAT IS THE ONE THING THAT SURVIVES, because it is the one thing that cluster
--     carried that no default UI element shows, and a dps who cannot see aggro coming
--     dies. It becomes the OUTERMOST ring of the PLAYER cluster at THREAT_RING = 100,
--     concentric with health (84), mana (62) and the 44px face at absolute (-270, 40).
--     That is also the more honest place for it: it is YOUR threat, so it belongs on
--     your own body, and the v7 argument that it "belongs at the target" only ever
--     held while there was a target cluster to hang it on.
--   * Threat changes SIZE and POSITION and NOTHING ELSE. Same uid, same id, same
--     Threat Situation trigger with `threatUnit` (renamed to plain `unit` only at
--     internalVersion 51, and Modernize migrates < 51 data by copying threatUnit ->
--     unit, so IV-45 data must keep emitting the OLD name), same escalation on
--     `foregroundColor` (`barColor` is aurabar-only and a SILENT no-op on a
--     progresstexture), same not-arena load gate, same mandatory
--     `threatvalue <= 0 -> alpha 0` guard — without which a progresstexture draws
--     FULL at total == 0 and zero threat reads as "you are at the pull threshold".
--     Its percentage moves from y = +54 to y = +58, clearing the bigger ring.
--   * There is no threat flash halo in this pack to resize: the only alphaPulse
--     animation priest ships is on Priest - Holy Procs, which is not a cluster
--     region. Decoding v11 for `alphaPulse` returns exactly that one hit.
--   * SOME UIDS ARE NOW ORPHANS, ON PURPOSE. Three regions are genuinely deleted, so
--     three uids have no home, and no filler region was invented to absorb them —
--     that is precisely how a HUD accumulates junk. Their uid() slots are BURNED in
--     place (W.uid() called and discarded, at the exact positions they occupied) so
--     that no surviving aura shifts in the seeded stream and no future version can
--     ever hand a deleted region's uid to a new aura. The 41 surviving uids are
--     byte-identical to v11's; see README "After updating" for the three auras the
--     player must delete by hand, because WeakAuras never deletes an aura an import
--     does not mention.
--   * Untouched: every trigger, gate, condition and colour outside the clusters —
--     buffs, alerts, the cooldown row, procs and the whole PvP layer, plus the player
--     cluster's own health/mana rings, their 40%/50% breakpoint marks, the Desperate
--     Prayer danger tier, the zero-total guards and the out-of-combat fade.

math.randomseed(20260815)  -- FIXED pack seed; the uid() call order below is append-only forever

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
-- wa_factory.lua resolves wa_lib.lua and assets/icon_proto.lua from arg[0]'s
-- directory, so a bare relative dofile fails when the build script lives outside
-- scripts/. Point arg[0] at the factory for the duration of the load, then restore.
local factoryPath = dir .. "/../../tools/tbc-weakaura-creator/scripts/wa_factory.lua"
local realArg0 = arg[0]
arg[0] = factoryPath
local F = dofile(factoryPath)
arg[0] = realArg0
local W = F.W

local CLASS = "PRIEST"
local TOP = "Priest TBC - All Specs"

-- ===== DELIBERATE REMOVALS, DECLARED ONCE =====
-- tools/verify-packs.lua grants a version its licence to drop a uid by scanning THIS
-- FILE for tagged comment lines, one aura id per line, carrying the version the pack
-- currently ships; anything else that disappears from the string is still a hard
-- failure. The build needs the same list to pass to W.assertUidContinuity, and two
-- hand-kept copies of a list are two lists that drift, so the list is READ BACK OUT of
-- the source instead of retyped. (The scan pattern below contains no literal two-hyphen
-- run, so it cannot match itself and declare a phantom removal.)
--
-- The three ids are the entire target cluster. Nothing replaces them.
local VERSION = "v12"
-- WA-REMOVED (v12): Priest - Target Health
-- WA-REMOVED (v12): Priest - Target Track
-- WA-REMOVED (v12): Priest - Target Portrait
local REMOVED = {}
do
  local selfPath = realArg0 or (dir .. "/generate.lua")
  local src = assert(io.open(selfPath, "r"), "cannot read own source: " .. selfPath)
  local body = src:read("*a"); src:close()
  for tag, id in body:gmatch("%-%-%s*WA%-REMOVED%s*%((v%d+)%)%s*:%s*([^\n]-)%s*\n") do
    if tag == VERSION then REMOVED[#REMOVED + 1] = id end
  end
  assert(#REMOVED == 3,
    ("expected 3 declared %s removals, found %d"):format(VERSION, #REMOVED))
end

local byId = {}
local icons = {}  -- ordered icon list for the polish pass (deterministic iteration)
local function reg(t)
  byId[t.id] = t
  if t.regionType == "icon" then icons[#icons + 1] = t end
  return t
end
local function adopt(parent, child)
  child.parent = parent.id
  table.insert(parent.controlledChildren, child.id)
end

-- alert flow: slide in from below, fly up and shrink out when handled
local function alertAnimations(a)
  a.animation.start = F.animPreset("slidebottom", "0.3", "easeOut")
  a.animation.finish = F.animCustom("1", { y = 150, alpha = 0, scale = 0.4 }, "easeOut")
end

-- Threat unit stays the factory's `threatUnit`. That IS the correct key for the
-- internalVersion 45 (WA 3.5.0) data this pack emits: the arg was renamed to plain
-- `unit` only in internalVersion 51, and Modernize.lua migrates < 51 data by copying
-- threatUnit -> unit on import. Writing `unit` here instead is actively wrong — that
-- migration assigns unconditionally, so it would overwrite our value with nil.
-- "none" ("At Least One Enemy") is NOT usable here regardless: the prototype's last
-- hidden test is WeakAuras.UnitExistsFixed(unit, false) and UnitExists("none") is false,
-- so a "none" threat trigger never activates. Threat stays target-relative.
local function threatTrigger(_unit, minPct)
  return F.threatTrigger(minPct)
end

-- v5: keep a PvE element out of the arena, where its mechanic does not exist.
-- There is no "not arena" key — the `size` load arg is a plain multiselect with no
-- `inverse` and no `test`, so the exclusion is spelled out as every OTHER legal
-- instance type. `use_size = false` is MULTI mode (only nil disables the gate).
-- `none` is the value this was deferred on and it is now proven: GetInstanceTypeAndSize
-- guards the "assign size = Type" block with `if inInstance or instanceType ~= "none"`
-- and then falls through to `return "none", "none", nil, nil, 0`, so the open world
-- reports the literal string "none" and the element stays loaded out there.
-- `pvp` (battleground) is kept on purpose: BGs have NPCs and a real threat table.
local function hideInArena(a)
  a.load.use_size = false
  a.load.size = { multi = {
    none = true,        -- open world / city / no instance
    party = true,       -- 5-man normal or heroic
    ten = true,         -- Karazhan, ZA
    twenty = true,      -- legal key, unreachable on TBC; free to list
    twentyfive = true,  -- SSC / TK / Hyjal / BT / Sunwell
    fortyman = true,    -- the vanilla raids
    pvp = true,         -- battleground
  } }
end

-- Always-on elements breathe with the fight: append an always-active Unit
-- Characteristics trigger and dim to 50% alpha while out of combat.
local function fadeOutOfCombat(a)
  local n = #a.triggers + 1
  a.triggers[n] = { trigger = F.unitCharTrigger(), untrigger = {} }
  a.conditions[#a.conditions + 1] = F.condition(n, "inCombat", "==", 0, "alpha", 0.5)
end

-- =====================================================================
-- Ring toolkit. wa_factory.lua has no progresstexture builder and no model builder, so
-- the ring and portrait tables below are written out in full; every other piece
-- (triggers, subtext, conditions, load gates, assembly) still goes through the factory.
-- Field names verified against the CURRENT WeakAuras source, which is what
-- actually runs: internalVersion 45 only drives migration, and no Modernize block
-- at IV >= 45 renames any progresstexture fill field or any model field.
-- =====================================================================

-- Bundled WeakAuras media. Ring_20px.tga is a true ANNULUS (the number is the
-- stroke weight in the art's own 256x256 space, so a ring drawn at S px carries a
-- band of S*20/256 — 6.6px at OUTER, 4.8px at INNER). Circle_Smooth.tga, the v9/v10
-- vessel art, is a SOLID DISC and is gone from this pack: a disc encodes a value by
-- waterline, and nothing here encodes anything by waterline any more.
local RING_TEX = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Ring_20px.tga"

-- ===== CANONICAL RING CLUSTER — IDENTICAL IN ALL SEVEN PACKS =====
-- These are not priest tuning knobs. Every pack in this repo ships this exact set,
-- and the whole point of naming them is that the seven copies cannot drift apart:
-- change them in all seven or in none. (Five earlier passes drifted because they
-- were handed intent instead of dimensions.)
local THREAT_RING = 100  -- v12: OUTERMOST ring, YOUR threat, player cluster only
local OUTER     = 84   -- health ring diameter, unchanged
local INNER     = 62   -- primary power ring diameter, unchanged
local PORTRAIT  = 44   -- live unit portrait (44/84 = the approved ratio), unchanged
local CLUSTER_X = 270  -- the ONE cluster, at x = -270; nothing is drawn at +270 now
local CLUSTER_Y = 40   -- ABSOLUTE screen y for the player cluster, unchanged

-- THE ABSOLUTE-POSITION RULE, written as arithmetic instead of as a comment.
-- A child anchored anchorFrameType = "SCREEN" inside a group anchors to THAT GROUP's
-- frame (GetAnchorFrame returns the parent region for "SCREEN"), so offsets ADD all
-- the way down the parent chain. CLUSTER_Y is the ABSOLUTE number, so the local one is
-- DERIVED — type 40 straight into a child of these two groups and the cluster lands at
-- -44, which is how a "one canonical layout" pass ends up with seven different HUDs.
--   top (0, TOP_Y) + Resources (0, RES_Y) + region (x, LOCAL_Y) = (x, absolute y)
-- All four cluster regions take the SAME x and the SAME local y, which is what makes
-- them concentric: one shared centre, four diameters.
local TOP_Y = -140       -- the top-level group, unchanged since v1
local RES_Y = 56         -- the Resources group inside it, unchanged since v1
local CLUSTER_LOCAL_Y = CLUSTER_Y - (TOP_Y + RES_Y)   -- = 124  -> absolute  40

-- x is not a taste call. The Alerts column is a dynamic group at x = -150 carrying
-- 40-44px icons (span -172..-128) and it GROWS VERTICALLY, so a cluster parked closer
-- in has the prompt stack climbing into it from the second simultaneous prompt onward.
-- The cluster's widest ring is now THREAT_RING, so it spans -320..-220 rather than
-- v11's -312..-228 — still 48px clear of the alert column's inner edge, and the build
-- proves it at the bottom of this script with the stack projected six children deep
-- instead of assuming the single-prompt case.
local ALERTS_X    = -150  -- the Alerts dynamic group's absolute x
local ALERT_W     = 44    -- widest alert icon (the four 44px PvP prompts)
local ALERT_SPACE = 6     -- dynamic-group spacing, matches the F.dynGroup call below
local ALERT_DEPTH = 6     -- how deep the stack is projected in the clearance proof

-- Percentage read-outs, also shared across the seven packs. A `model` region cannot
-- carry a text sub-region at all (SubText's supports() lists texture / progresstexture
-- / icon / aurabar / text / empty — not model), so with the portrait in the middle
-- every number rides on its own RING and sits just OUTSIDE the cluster: health under
-- the health ring, power under that, threat above.
--   Threat moves +54 -> +58 in v12. Its ring grew from 84 to 100, so the old offset
--   sat 4px INSIDE the new stroke (radius 50, band 42.2..50) instead of clear above it.
local PCT_HP     = { size = 13, y = -54 }   -- health, just under the health ring
local PCT_POWER  = { size = 10, y = -70 }   -- power, under the health number
local PCT_THREAT = { size = 10, y =  58 }   -- threat, above the 100px outermost ring

local COL = {
  life   = { 0.15, 0.82, 0.28, 1 },   -- health green, both clusters
  mana   = { 0.20, 0.45, 0.95, 1 },   -- mana blue; every priest spec runs on mana
  track  = { 0, 0, 0, 0.55 },         -- the UNFILLED arc behind every ring's fill
  threat = { 0.25, 0.80, 0.30, 1 },   -- threat ring base, unchanged since v1
  warn   = { 1, 0.6, 0.1, 1 },        -- threat >= 70%
  danger = { 0.9, 0.12, 0.12, 1 },    -- health < 40%, and aggro
  hpText = { 1, 1, 1, 1 },
  mpText = { 0.55, 0.75, 1, 1 },      -- unchanged from the bar era, so the two
  thText = { 0.75, 0.95, 0.8, 1 },    -- numbers never need labels to be told apart
  mark   = { 1, 1, 1, 0.8 },
}

-- wa_factory's stub() is local to the factory, so the hand-written ring and portrait
-- tables below get the identical scaffolding here.
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
  t.load = F.load(CLASS)
  return t
end

-- THE RING. Same region type as the v9/v10 globe, one different orientation — and
-- that one field decides which of the others are live:
--   orientation "CLOCKWISE" -> the RADIAL fill path. The only radial values are
--     CLOCKWISE / ANTICLOCKWISE; every other value in orientation_with_circle_types
--     is linear. Under VERTICAL (the globes) startAngle/endAngle were dead and
--     compress/slanted/slantMode were live; under CLOCKWISE it is exactly the other
--     way round, which is why the slant fields below are emitted but inert.
--   startAngle 0 / endAngle 360 -> full circle. WA normalises 0/360 -> 0/0 and then
--     corrects endAngle back up by 360, so a full ring is handled, not degenerate.
--   crop_x / crop_y = 0.41 -> the IDENTITY value on the circular path, NOT "no crop":
--     the circular path expands the texture by sqrt(2) so rotated quadrants never run
--     off it, and 1 + 0.41 exactly cancels that. Setting 0 blows the ring up 1.41x
--     and clips it. It was also 0.41 on the linear path, where it meant something
--     else (the texcoord scale) — same number, different job, and it must stay.
--   backgroundOffset = 0 -> the default 2 fattens the track relative to the fill,
--     which reads as a halo around the ring instead of the track beneath it.
--   backgroundColor = COL.track -> the unfilled arc is a dark annulus of exactly the
--     same size, so a ring at 20% is an arc on a circle, not an arc in the void.
--   sameTexture = true -> backgroundTexture becomes dead code; both are set anyway.
--   auraRotation = 0 -> absent from the 3.5.0 default table but read unconditionally
--     by current code as data.auraRotation / 180 * math.pi, so it must be emitted.
--   adjustedMin/Max are STRINGS, because SetAdjustedMin does adjustedMin:find(...).
--   progressSource is rewritten to {-1, ""} (Automatic) by Modernize < 71 whatever is
--     emitted, which is WHY there is exactly one progress trigger per ring and it has
--     to be trigger 1: Automatic reads the first active trigger's value/total.
local function ring(id, size, color, x, y, trigger)
  return orbStub{
    regionType = "progresstexture", id = id, uid = W.uid(), parent = nil,
    width = size, height = size,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = x, yOffset = y, frameStrata = 1, alpha = 1,
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
    triggers = trigger and F.triggers({ trigger }) or nil,
  }
end

-- THE FACE. A live 3D portrait of the unit — not a static image and not a class
-- icon, which is what makes the target side work without ever knowing the target's
-- class: it renders NPCs and mobs too.
--   modelIsUnit = true + model_fileId = "<unit>" -> PlayerModel:SetUnit(unit)
--   portraitZoom = true                          -> SetPortraitZoom(1), head framing
-- CRITICAL: current code reads the unit from `model_fileId`. WA 3.5.0 read
-- `model_path`, and the migration that bridges the two (Modernize < 72) is guarded by
-- WeakAuras.IsClassicEra(), which is a DISTINCT predicate from IsTBC() — so on this
-- pack's 2.5.x client that migration DOES NOT RUN and emitting only model_path is a
-- silent no-op. BOTH are emitted; model_fileId is the one that does the work.
-- Each portrait carries the same triggers as the rings around it, so a cluster
-- appears, fades and vanishes as ONE object.
local function portrait(id, unit, x, y)
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
    xOffset = x, yOffset = y, frameStrata = 1,
    border = false, borderColor = { 1, 1, 1, 0.5 }, backdropColor = { 1, 1, 1, 0.5 },
    borderEdge = "None", borderOffset = 5, borderInset = 11,
    borderSize = 16, borderBackdrop = "Blizzard Tooltip",
    subRegions = {},
    triggers = nil,   -- always supplied by the caller
  }
end

-- v11's separate "target track" texture region is gone with the cluster it padded. It
-- existed only so the target side never dropped to one ring while the player side
-- showed two; with one cluster on screen there is nothing to keep symmetric, and the
-- threat ring already carries its own dark backgroundTexture annulus, so a second
-- region drawing the same circle would be a duplicate rather than a track.

-- The percentages ride on their own ring and so appear and disappear with it: no
-- threat, no threat percentage.
--
-- THE OFFSET KEY IS A TRAP, and it is the exact silent-no-op shape this repo keeps
-- getting caught by. SubText's modify() reads `data.text_anchorXOffset` /
-- `data.text_anchorYOffset` — in WeakAuras 3.5.0 (SubText.lua:408) and in current
-- code (SubText.lua:486) alike — but the `default()` table it ships alongside them
-- writes `anchorXOffset` / `anchorYOffset`, and NO Modernize block in any version
-- copies one to the other (grep both: zero hits for text_anchorYOffset). So the
-- factory's anchorYOffset is a DEAD key: setting it moves nothing. Every number in
-- this cluster is offset from the centre now that the portrait is back, so with only
-- the dead key all three would pile up in the middle of the cluster, on top of the
-- face, with no error anywhere. Both spellings are emitted; text_* does the work.
-- (text_anchorPoint is the opposite case and is fine: Modernize < 80 renames it to
-- anchor_point, which is what current code reads, so the factory value survives.)
-- `spec` is one of the shared PCT_* tables, so a number's size and its distance from
-- the centre come from the canonical set rather than from a per-call literal.
local function pct(sym, spec, color)
  local st = F.subtext("%" .. sym .. "%%", spec.size, "CENTER", sym)
  st.anchorYOffset = spec.y
  st.text_anchorXOffset = 0
  st.text_anchorYOffset = spec.y
  st.text_color = color
  return st
end

-- Breakpoint mark: the level a resource has to stay above, drawn ON ITS OWN RING at
-- the angle its threshold implies. On a vessel (v9/v10) this was a horizontal
-- waterline; on a ring it goes back to being a point on a circumference, so it needs
-- the trigonometry again — and it must be derived from THE RING IT RIDES, never from
-- a shared radius, or a mark orbits a circle its ring no longer draws:
--   r = size/2 * MARK_RADIUS ;  x = r*sin(2*pi*f) ;  y = r*cos(2*pi*f)
-- Angle 0 is 12 o'clock and increases CLOCKWISE, matching the ring's own fill
-- direction, so the mark sits exactly where the arc will end at that fraction:
-- 40% -> 144 degrees (lower right), 50% -> 180 degrees (bottom).
--
-- MARK_RADIUS 0.94: Ring_20px's band runs from 1 - 20/128 = 0.844 of the outer radius
-- to 1.0, so 0.94 is inside the stroke on every diameter this pack draws.
-- The pip is SQUARE and sized to its own ring's band (size * 20/256), so it fills the
-- stroke exactly instead of poking out of it — and because it is square it needs no
-- rotation to sit on the circle (textureRotate is the gate that makes textureRotation
-- do anything; the art is a plain white square, so both stay off).
--   xOffset/yOffset are NOT in the subtexture default table but ARE read by
--   modify -> AnchorSubRegion, and only in anchor_mode = "point"; omit either and the
--   mark stacks in the dead centre of the ring.
--   `subtick` still cannot come along (SubRegionTypes/Tick.lua's supports() returns
--   regionType == "aurabar", full stop); `subtexture` does list progresstexture.
local MARK_RADIUS = 0.94
local function round(v) return math.floor(v * 1000 + 0.5) / 1000 end
local function mark(size, percent)
  local r = size / 2 * MARK_RADIUS
  local f = percent / 100
  local pip = round(size * 20 / 256)
  return {
    type = "subtexture",
    textureVisible = true, textureTexture = F.TEX_SQUARE,
    textureColor = COL.mark, textureBlendMode = "BLEND",
    textureDesaturate = false, textureMirror = false,
    textureRotate = false, textureRotation = 0,
    anchor_mode = "point", anchor_point = "CENTER", self_point = "CENTER",
    anchor_area = "ALL",
    width = pip, height = pip,
    scale = 1, mirror = false, rotate = false,
    xOffset = round(r * math.sin(2 * math.pi * f)),
    yOffset = round(r * math.cos(2 * math.pi * f)),
  }
end

-- ===== top-level group, anchored below the character =====
local top = F.group(TOP, 0, TOP_Y, nil)
top.uid = W.uid()

-- =====================================================================
-- Resources (0,56): since v12 this group holds ONE CLUSTER — yours, a live 3D
-- portrait of you inside three concentric rings, all four regions sharing the one
-- centre at absolute (-270, 40):
--   THREAT_RING 100  your threat on your target   (outermost)
--   OUTER        84  your health
--   INNER        62  your mana
--   PORTRAIT     44  your face
-- The target cluster that used to sit at (+270, 110) is deleted: the target's health
-- is already on the Blizzard target frame and its nameplate, so it duplicated the
-- default UI for the whole game.
--
-- THREAT COMES HOME. It is the only thing the target cluster carried that nothing
-- else on screen shows, and losing it would be a real regression — a dps who cannot
-- see aggro coming dies — so it moves to the outermost ring of YOUR cluster, which is
-- also the more honest reading: it is YOUR threat. Because it is gated out of arena
-- and self-hides whenever the Threat Situation trigger has no hostile target to
-- report on, the common solo case is still just two rings and a face; the third arc
-- appears only when threat is real.
--
-- Health, mana and threat are built here (they are the v6 bar auras, converted in
-- place so they keep their uids); the portrait is built at the bottom of this script,
-- after every pre-existing W.uid() call, and is re-parented here.
-- =====================================================================
local gRes = reg(F.group("Priest - Resources", 0, RES_Y, nil))
adopt(top, gRes)

-- HEALTH — the cluster's MIDDLE ring (absolute -270, 40). Trigger 1 is the
-- progress source; trigger 2 (Unit Characteristics) feeds the inCombat fade, exactly
-- as the v6 bar did. Conditions apply in order and a later match wins, so the alpha
-- guard is LAST.
local health = reg(ring("Priest - Health", OUTER, COL.life, -CLUSTER_X, CLUSTER_LOCAL_Y))
health.triggers = F.triggers({ F.healthTrigger(nil), F.unitCharTrigger() })
health.subRegions[1] = pct("percenthealth", PCT_HP, COL.hpText)
health.subRegions[2] = mark(OUTER, 40)   -- the Desperate Prayer line, on the ring
health.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  -- red below 40%: the same number the Desperate Prayer prompt fires at, so ring and
  -- prompt read as one danger state. On a progresstexture the property is
  -- foregroundColor; `barColor` exists only on aurabar and would be dropped silently
  -- by Conditions.lua (unknown property = the change is skipped, with no warning).
  F.condition(1, "percenthealth", "<", "40", "foregroundColor", COL.danger),
  -- zero-total guard. Health's total is UnitHealthMax(unit) with no floor, and a
  -- progresstexture draws a FULL region at total == 0 (an aurabar drew an empty
  -- one), so an unstreamed max health would flash a complete green circle.
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}
adopt(gRes, health)

-- MANA — the cluster's INNER ring, concentric inside health at the SAME
-- centre (absolute -270, 40). Priest is mana in every spec and every form, so this
-- ring is blue with no recolouring condition — a druid's is what needs one.
local mana = reg(ring("Priest - Mana", INNER, COL.mana, -CLUSTER_X, CLUSTER_LOCAL_Y))
mana.triggers = F.triggers({ F.powerTrigger(0), F.unitCharTrigger() })
mana.subRegions[1] = pct("percentpower", PCT_POWER, COL.mpText)
mana.subRegions[2] = mark(INNER, 50)     -- the Shadowfiend window, on the ring
mana.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }
adopt(gRes, mana)

-- THREAT — v12: the cluster's OUTERMOST ring (THREAT_RING = 100) at YOUR centre,
-- absolute (-270, 40), concentric with health, mana and your face. It moved off the
-- deleted target cluster and it is the only thing that came with it: nothing else in
-- this HUD or in the default UI tells you that you are about to pull, and that is the
-- one number a dps dies for not watching.
--
-- SIZE AND POSITION ARE THE ONLY FIELDS THAT CHANGED. Same uid, same id, same Threat
-- Situation trigger (threatUnit = "target"), same escalation on foregroundColor, same
-- not-arena load gate, same threatvalue guard, same green/orange/red. The trigger only
-- produces a state for a hostile unit whose threat table you are on, so the ring
-- self-hides out of combat and while you have a friendly targeted — no fade condition
-- needed, and no dark track region needed either: a progresstexture's own
-- backgroundTexture annulus is the track, and when the ring is stateless there is
-- nothing left on screen to leave a hole in.
--
-- Green -> orange at 70% -> red on aggro; conditions run in order, most severe last.
-- It is adopted at the very BOTTOM of this script rather than here: adoption order is
-- draw order within a frame strata (+4 frame levels per child), and the outermost ring
-- is the one that should draw last.
local threat = reg(ring("Priest - Threat", THREAT_RING, COL.threat,
  -CLUSTER_X, CLUSTER_LOCAL_Y))
threat.triggers = F.triggers({ threatTrigger("target", nil) })
threat.subRegions[1] = pct("threatpct", PCT_THREAT, COL.thText)
threat.conditions = {
  -- back on a progresstexture, so the fill property is `foregroundColor` again —
  -- it was `color` while threat was a v9/v10 texture rim and `barColor` in the bar
  -- era. Conditions.lua skips a change whose property is absent from the region's
  -- properties table WITHOUT any error, so the wrong name here would look right in
  -- the editor and do nothing in the game.
  F.condition(1, "threatpct", ">=", "70", "foregroundColor", COL.warn),
  F.condition(1, "aggro", "==", 1, "foregroundColor", COL.danger),
  -- MANDATORY, and carried across from v7 byte for byte (same trigger, variable,
  -- operator, value and property). threattotal = threatvalue * 100 / threatpct, so
  -- total is 0 whenever your threat is 0: the instant after a Fade, and before your
  -- first cast lands. A progresstexture draws a FULL region at total == 0
  -- (ProgressTexture.lua `local progress = 1`), so without this the ring would slam
  -- to a complete circle — "you are at the pull threshold" — exactly when you have
  -- no threat at all. Last, so it wins over both colour rules.
  F.condition(1, "threatvalue", "<=", "0", "alpha", 0),
}
hideInArena(threat)  -- v5: no threat table exists in an arena; everywhere else unchanged

-- =====================================================================
-- Buffs (0,-16): static row of 40x40 aura timers at x = -66/-22/22/66
-- =====================================================================
local gBuffs = reg(F.group("Priest - Buffs", 0, -16, nil))
adopt(top, gBuffs)

-- Shadow Word: Pain — own DoT on the target, all 10 ranks. The glow sits at <=1s,
-- not <=3s: SW:P is instant and ticks every 3s, so re-casting early throws away a
-- tick. Re-apply as it drops, never before.
local swp = reg(F.icon("Priest - Shadow Word Pain", CLASS, 40, 40, -66, 0, nil))
swp.triggers = F.triggers({
  F.auraTrigger("target", false, {
    589, 594, 970, 992, 2767, 10892, 10893, 10894, 25367, 25368,
  }, { ownOnly = true }),
})
swp.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
swp.conditions = { F.condition(1, "expirationTime", "<=", "1", "sub.1.glow", true) }
swp.load.use_spellknown = true
swp.load.spellknown = 15473  -- Shadowform: Shadow-only slot (shares x=-66 with Weakened Soul)
adopt(gBuffs, swp)

-- Vampiric Touch — own DoT, 3 ranks; rank 1 doubles as the talent gate
local vt = reg(F.icon("Priest - Vampiric Touch", CLASS, 40, 40, -22, 0, nil))
vt.triggers = F.triggers({
  F.auraTrigger("target", false, { 34914, 34916, 34917 }, { ownOnly = true }),
})
vt.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
vt.conditions = { F.condition(1, "expirationTime", "<=", "3", "sub.1.glow", true) }
vt.load.use_spellknown = true
vt.load.spellknown = 34914
adopt(gBuffs, vt)

-- Vampiric Embrace — own debuff on the boss (raid heal / mana loop), single rank.
-- 60s duration and no tick to clip, so it takes the same <=3s re-apply glow as VT.
local ve = reg(F.icon("Priest - Vampiric Embrace", CLASS, 40, 40, 22, 0, nil))
ve.triggers = F.triggers({
  F.auraTrigger("target", false, { 15286 }, { ownOnly = true }),
})
ve.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
ve.conditions = { F.condition(1, "expirationTime", "<=", "3", "sub.1.glow", true) }
ve.load.use_spellknown = true
ve.load.spellknown = 15286
adopt(gBuffs, ve)

-- Weakened Soul on the HEAL TARGET — the gate on the #1 Disc/Holy press. Power Word:
-- Shield is unusable while this is on them, so the icon answers "can I shield this
-- person?"; the glow at <=1s is "you can shield again now". NOT ownOnly: any priest's
-- shield blocks yours. Loads for every priest WITHOUT Shadowform, which is the exact
-- complement of SW:P's gate, so the shared x=-66 slot is still provably single-occupancy.
local wsoul = reg(F.icon("Priest - Weakened Soul", CLASS, 40, 40, -66, 0, nil))
wsoul.triggers = F.triggers({
  F.auraTrigger("target", false, { 6788 }),
})
wsoul.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
wsoul.conditions = { F.condition(1, "expirationTime", "<=", "1", "sub.1.glow", true) }
wsoul.load.use_not_spellknown = true
wsoul.load.not_spellknown = 15473  -- everyone except Shadowform (which owns this slot)
adopt(gBuffs, wsoul)

-- Inner Fire — all 7 ranks: %s = charges left, %p = time left. Every spec keeps it up.
local innerfire = reg(F.icon("Priest - Inner Fire", CLASS, 40, 40, 66, 0, nil))
innerfire.triggers = F.triggers({
  F.auraTrigger("player", true, { 588, 7128, 602, 1006, 10951, 10952, 25431 }),
})
innerfire.subRegions[2] = F.subtext("%s", 16, "CENTER")
innerfire.subRegions[3] = F.subtext("%p", 11, "INNER_BOTTOM")
adopt(gBuffs, innerfire)

-- =====================================================================
-- Alerts (-150,96): vertical prompt flow, glowing icons, animated in/out
-- =====================================================================
local gAlerts = reg(F.dynGroup("Priest - Alerts", -150, 96, nil, "UP", "BOTTOM", 6))
adopt(top, gAlerts)

-- Shadowform dropped while in combat (Shadow only)
local sform = reg(F.icon("Priest - Shadowform MISSING", CLASS, 40, 40, 0, 0, nil))
sform.triggers = F.triggers({
  F.auraTrigger("player", true, { 15473 }, { matchesShowOn = "showOnMissing" }),
})
sform.iconSource = 0
sform.displayIcon = "Interface\\Icons\\spell_shadow_shadowform"
sform.cooldown = false
sform.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
sform.load.use_combat = true
sform.load.use_spellknown = true
sform.load.spellknown = 15473
alertAnimations(sform)
adopt(gAlerts, sform)

-- mana < 50% AND Shadowfiend ready -> send the fiend (percent-based, so it works at
-- any mana pool size); both triggers must hold (disjunctive "all"). 50%, not 30%: the
-- fiend returns ~25% of your maximum mana over its 15s, so firing it while nearly dry
-- wastes both the return and five minutes of cooldown.
local sfiend = reg(F.icon("Priest - Shadowfiend Prompt", CLASS, 40, 40, 0, 0, nil))
local sfiendPower = F.powerTrigger(0)
sfiendPower.use_percentpower = true
sfiendPower.percentpower = "50"
sfiendPower.percentpower_operator = "<"
sfiend.triggers = F.triggers({
  sfiendPower,
  F.cdTrigger(34433, "Shadowfiend", "showOnReady"),
})
sfiend.iconSource = 0
sfiend.displayIcon = "Interface\\Icons\\spell_shadow_shadowfiend"
sfiend.cooldown = false
sfiend.subRegions[1] = F.subglow(true, { 0.55, 0.35, 1, 1 })
sfiend.load.use_combat = true
sfiend.load.use_spellknown = true
sfiend.load.spellknown = 34433  -- level-66 baseline; the gate just hides it for lowbies
alertAnimations(sfiend)
adopt(gAlerts, sfiend)

-- threat >= 70% on your target AND Fade ready -> dump threat now. Combat-gated like
-- the other three prompts (the threat trigger already needs a hostile target, but the
-- gate keeps the whole alert flow uniformly silent outside a fight).
local fade = reg(F.icon("Priest - Fade Prompt", CLASS, 40, 40, 0, 0, nil))
fade.triggers = F.triggers({
  threatTrigger("target", 70),
  F.cdTrigger(586, "Fade", "showOnReady"),
})
fade.iconSource = 0
fade.displayIcon = "Interface\\Icons\\spell_magic_lesserinvisibilty"  -- that misspelling is the real filename
fade.cooldown = false
fade.subRegions[1] = F.subglow(true, { 1, 0.45, 0.1, 1 })
fade.load.use_combat = true
fade.load.use_spellknown = true
fade.load.spellknown = 586
-- v5: same arena exclusion as the bar that drives it. Trigger 1 is the threat
-- trigger, so this prompt was already unreachable in an arena — the gate makes it
-- unreachable at LOAD time, which is one fewer aura evaluating every frame there.
hideInArena(fade)
alertAnimations(fade)
adopt(gAlerts, fade)

-- HP < 40% AND Desperate Prayer ready -> emergency self-heal. Racial spell: the
-- spellknown gate simply never loads it for races that do not learn it.
local dprayer = reg(F.icon("Priest - Desperate Prayer Prompt", CLASS, 40, 40, 0, 0, nil))
dprayer.triggers = F.triggers({
  F.healthTrigger(40),
  F.cdTrigger(13908, "Desperate Prayer", "showOnReady"),
})
dprayer.iconSource = 0
dprayer.displayIcon = "Interface\\Icons\\spell_holy_restoration"
dprayer.cooldown = false
dprayer.subRegions[1] = F.subglow(true, { 0.3, 1, 0.5, 1 })
dprayer.load.use_combat = true
dprayer.load.use_spellknown = true
dprayer.load.spellknown = 13908
alertAnimations(dprayer)
adopt(gAlerts, dprayer)

-- =====================================================================
-- Cooldowns (0,-66): horizontal row. Since v6 the row is INVERTED — it shows
-- what you cannot press. Situational cooldowns appear only while they are
-- down; the three press-on-cooldown rotational buttons stay on screen and
-- glow the instant they are up.
-- =====================================================================
local gCDs = reg(F.dynGroup("Priest - Cooldowns", 0, -66, nil, "HORIZONTAL", "CENTER", 4))
gCDs.animate = false
adopt(top, gCDs)

-- The classification lives in one flag: an icon with a readyGlow is a press-on-cooldown
-- rotational button, everything else is situational.
--
-- opts.readyGlow = colour  -> ROTATIONAL. genericShowOn = "showAlways", so it is on
--                             screen in both states: desaturated while down, and lit by
--                             a pixel glow the moment it is up. The glow IS the
--                             instruction, and a hidden icon could never fire one.
--                             Suppressed out of combat, where everything is always up.
-- opts.healthGuard = N     -> that glow is switched back off below N% health
-- opts.notGate = spellId   -> also require that spell to be UNknown (spec exclusion)
-- (no readyGlow)           -> SITUATIONAL. genericShowOn = "showOnCooldown": the icon
--                             exists only while the cooldown runs, carrying the swipe
--                             and its countdown, and disappears when the ability is
--                             back. The row is a dynamic group, so the gap closes —
--                             absence is the readout. No desaturate condition either:
--                             every visible icon is on cooldown by definition, so
--                             greying them all would only make them harder to tell apart.
local function addCD(id, name, spellId, gate, opts)
  opts = opts or {}
  local rotational = opts.readyGlow ~= nil
  local icon = reg(F.icon("Priest CD - " .. id, CLASS, 32, 32, 0, 0, nil))
  local trigs = { F.cdTrigger(spellId, name, rotational and "showAlways" or "showOnCooldown") }
  if opts.healthGuard then trigs[#trigs + 1] = F.healthTrigger(nil) end
  icon.triggers = F.triggers(trigs)
  icon.cooldownTextDisabled = false  -- swipe numbers on; no %p subtext (OmniCC double-number trap)
  icon.useTooltip = true
  icon.conditions = {}
  if rotational then
    -- desaturate still carries information here: this icon is visible in BOTH states
    icon.conditions[1] = F.condition(1, "onCooldown", "==", 1, "desaturate", true)
    -- the factory's icon prototype already puts a (disabled) subglow at subRegions[1],
    -- so this REPLACES index 1 rather than inserting — every "sub.1.glow" reference in
    -- this pack keeps pointing at a subglow, and the subborder stays at index 2
    icon.subRegions[1] = F.subglow(false, opts.readyGlow)
    icon.conditions[#icon.conditions + 1] =
      F.condition(1, "onCooldown", "==", 0, "sub.1.glow", true)
    if opts.healthGuard then
      -- conditions apply in order and the later match wins, so this one un-glows the
      -- icon when pressing it would be dangerous
      icon.conditions[#icon.conditions + 1] =
        F.condition(2, "percenthealth", "<", tostring(opts.healthGuard), "sub.1.glow", false)
    end
  end
  if gate then
    icon.load.use_spellknown = true
    icon.load.spellknown = gate
  end
  if opts.notGate then
    icon.load.use_not_spellknown = true
    icon.load.not_spellknown = opts.notGate
  end
  fadeOutOfCombat(icon)
  if rotational then
    -- v6: out of combat every cooldown is up, so the ready-glow would sit lit forever on
    -- an idle HUD. Appended AFTER the fade condition (and so after the glow-on rule) —
    -- later match wins — and it reads the Unit Characteristics trigger fadeOutOfCombat
    -- just added, which is now the last trigger.
    icon.conditions[#icon.conditions + 1] =
      F.condition(#icon.triggers, "inCombat", "==", 0, "sub.1.glow", false)
  end
  adopt(gCDs, icon)
  return icon
end

local SHADOW_READY = { 0.55, 0.35, 1, 1 }  -- same violet as the Shadowfiend prompt
local HOLY_READY   = { 1, 0.85, 0.2, 1 }   -- same gold as the Holy proc row

-- ROTATIONAL (showAlways + ready glow) --------------------------------------------
-- Mind Blast (8s, 5.5s with 5/5 Improved) and SW:Death (12s) are the two presses the
-- Shadow rotation cancels a Mind Flay channel for, so both glow the instant they are up.
addCD("Mind Blast",        "Mind Blast",          8092, 15473, { readyGlow = SHADOW_READY })
addCD("Shadow Word Death", "Shadow Word: Death", 32379, 15473, { readyGlow = SHADOW_READY, healthGuard = 50 })
-- SITUATIONAL (showOnCooldown) ----------------------------------------------------
-- Shadowfiend is a mana cooldown fired at a mana window, and the Alerts column already
-- owns that moment (mana < 50% AND the fiend ready), so the row icon only has to answer
-- "when is it back".
addCD("Shadowfiend",       "Shadowfiend",        34433, 34433)  -- all specs, 5 min
-- ROTATIONAL: the healer's most frequent scheduled press. 10s cooldown, cast on cooldown
-- on the tank — the cheapest heal per point of healing a TBC priest owns — so it takes the
-- gold Holy glow rather than being hidden while it is available.
addCD("Prayer of Mending", "Prayer of Mending",  33076, 33076, { notGate = 15473, readyGlow = HOLY_READY })  -- Holy/Disc staple, 10s CD
-- SITUATIONAL, continued ----------------------------------------------------------
addCD("Inner Focus",       "Inner Focus",        14751, 14751)  -- Disc tier-2 talent, 3 min; paired with a specific big cast
addCD("Power Infusion",    "Power Infusion",     10060, 10060)  -- Disc 31-pt talent, 3 min; a burn-phase window
addCD("Pain Suppression",  "Pain Suppression",   33206, 33206)  -- Disc 41-pt signature, 2 min; an emergency
addCD("Lightwell",         "Lightwell",            724,   724)  -- Holy 40-pt optional talent; placed before a damage phase
addCD("Fear Ward",         "Fear Ward",           6346,  6346)  -- baseline for every priest since 2.3.0 (lvl 20, 3 min CD)

-- =====================================================================
-- Procs (110,24): cloned proc icons, one per active Holy proc
-- =====================================================================
local gProcs = reg(F.dynGroup("Priest - Procs", 110, 24, nil, "RIGHT", "LEFT", 4))
adopt(top, gProcs)

local procs = reg(F.icon("Priest - Holy Procs", CLASS, 32, 32, 0, 0, nil))
procs.triggers = F.triggers({
  -- 33151 Surge of Light (free instant Smite), 34754 Clearcasting (Holy Concentration).
  F.auraTrigger("player", true, { 33151, 34754 }, { showClones = true }),
})
-- v3: inverse-gated off Shadow. Surge of Light sits at tier 6 of the Holy tree (25 points
-- in) and Holy Concentration at tier 7 (30 points in), so a Shadowform build — 31 points
-- into Shadow, 23 into Discipline in the standard 23/0/38 — can never own either proc.
-- The trigger already made this icon impossible for Shadow; the gate makes it impossible
-- to LOAD, which is what "an ungated element must be justified for every spec" asks for.
-- Discipline keeps it loaded on purpose: a 41/20 Disc build stops at tier 5 of Holy and
-- also never procs it, but no single spell id separates "deep Holy" from "deep Disc"
-- without risking a false cut on a Holy build that skipped one of the two talents.
procs.load.use_not_spellknown = true
procs.load.not_spellknown = 15473  -- everyone except Shadowform
procs.subRegions[1] = F.subglow(true, { 1, 0.85, 0.2, 1 })
procs.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
procs.animation.start = F.animCustom("0.5", { alpha = 0, alphaType = "alphaPulse", scale = 1.5 }, "easeOut")
procs.animation.finish = F.animCustom("0.8", { x = 120, alpha = 0 }, "easeOut")
adopt(gProcs, procs)

-- =====================================================================
-- v2 additions. Every new aura is created AFTER all pre-existing W.uid()
-- calls so the shipped uids keep their positions in the seeded stream;
-- re-parenting it into the row where it belongs costs nothing.
-- =====================================================================

-- Renew on the current friendly target — Icy Veins ranks it #3 for Holy ("keep this HoT
-- up on the tank and anyone taking consistent damage"), and it is the one heal a priest
-- schedules rather than reacts to. All 12 TBC ranks (139 -> 25222), own-only because
-- Renews from different priests are separate auras, glowing at <=2s so the refresh is
-- already in flight when it drops. It takes the Vampiric Touch slot: VT costs 41 Shadow
-- points, so a priest without Shadowform can never own both.
local renew = reg(F.icon("Priest - Renew", CLASS, 40, 40, -22, 0, nil))
renew.triggers = F.triggers({
  F.auraTrigger("target", true, {
    139, 6074, 6075, 6076, 6077, 6078, 10927, 10928, 10929, 25315, 25221, 25222,
  }, { ownOnly = true }),
})
renew.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
renew.conditions = { F.condition(1, "expirationTime", "<=", "2", "sub.1.glow", true) }
renew.load.use_not_spellknown = true
renew.load.not_spellknown = 15473  -- healer row: everyone except Shadowform
adopt(gBuffs, renew)

-- the buff row is the other always-on layer, so it fades out of combat as well
for _, a in ipairs({ swp, vt, ve, wsoul, innerfire, renew }) do fadeOutOfCombat(a) end

-- =====================================================================
-- v4 additions — the PvP layer. Every aura below carries an instance-type
-- load gate, so NOTHING here loads in a raid, a dungeon or the open world:
-- a PvE player sees exactly the v3 HUD. Created after every earlier W.uid()
-- call and re-parented into the rows they belong to, so all 29 v3 uids keep
-- their positions in the seeded stream.
-- =====================================================================

-- Load gates (references/pvp.md §1.1). `use_size = false` is NOT "off": a
-- multiselect load arg is active for both true and false and only inert at nil,
-- and false selects MULTI mode, which ORs the listed instance types.
--   pvpLoad(false) -> arena OR battleground
--   pvpLoad(true)  -> arena only. Mandatory for anything that reads arena1..5:
--                     those unit ids do not exist in a battleground, so a
--                     BG-loaded arena element is a permanently blank slot.
local function pvpLoad(arenaOnly, extra)
  local l = F.load(CLASS, {
    use_size = false,
    size = { multi = arenaOnly and { arena = true } or { arena = true, pvp = true } },
  })
  for k, v in pairs(extra or {}) do l[k] = v end
  return l
end

-- GenericTrigger stub: the inert companion fields every non-aura2 trigger table
-- carries in WeakAuras' own exports (they only do anything behind their use_*
-- flag). The factory applies these inside its builders; these triggers are
-- hand-written from the prototypes, so they get the same treatment.
local function gTrigger(t)
  t.names = {}; t.spellIds = {}
  t.debuffType = t.debuffType or "HELPFUL"
  t.subeventPrefix = "SPELL"; t.subeventSuffix = "_CAST_START"
  return t
end

-- ===== the PvP column: state read-outs, mirroring Alerts on the right =====
-- A dynamicgroup, because three of its children are clone sources (clones
-- inside a STATIC group all stack on one spot). It grows upward from the same
-- y as the Alerts column so the two read as a matched pair, and it collapses
-- to nothing whenever no PvP state is live.
local gPvP = reg(F.dynGroup("Priest - PvP", 150, 96, nil, "UP", "BOTTOM", 6))
adopt(top, gPvP)

-- ---- prompt: something is controlling me --------------------------------
-- The Crowd Controlled trigger is the only non-custom-code way to see CC
-- generically WITH its real duration, and the only way to see a Kick /
-- Counterspell school lockout at all (a lockout is not an aura, so no aura
-- trigger can ever find one). No controlType filter: it matches every loss of
-- control effect. iconSource stays -1, so the icon IS the identity of the
-- effect — stun, poly, fear or a locked school — and %p is the countdown that
-- answers "ride it or spend the trinket". NOT combat-gated: the opening Sap
-- and the pre-gate fear land before you are in combat.
--
-- v5 — the glow is colour-coded by controlType, because under CC a player parses
-- COLOUR, never text, and the category is the whole decision:
--   red    stun          the trinket is the only answer
--   purple fear          trinket, or Fear Ward the next one before it lands
--   blue   root          NOT the trinket — a priest has no root break, so this is
--                        "reposition, LoS, and keep casting; you are not helpless"
--   green  confuse/poly  ride it, and hold your DoT/damage: any tick breaks it
--   amber  silence/lockout  your school is gone (every priest defensive is Holy or
--                        Shadow), so trinket EARLIER than you otherwise would
-- Same five colours as the mage pack, on purpose: one language across two classes.
--
-- Mechanically this needs three things and has all three: the subglow really is
-- subRegions[1] (so "sub.1.glowColor" resolves), it was built with a colour so
-- useGlowColor = true (with it false the setter is a silent no-op), and glow = true
-- so SetGlowColor's restart guard passes. Values must be 4-element ARRAYS.
-- The five loss-of-control types with no condition (NONE, CHARM, DISARM, PACIFY,
-- POSSESS) fall back to the base colour below, i.e. red "trinket food" — correct.
local ccOnMe = reg(F.icon("Priest - CC ON ME", CLASS, 44, 44, 0, 0, nil))
ccOnMe.triggers = F.triggers({
  gTrigger{ type = "unit", event = "Crowd Controlled" },
})
ccOnMe.cooldown = false
ccOnMe.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
ccOnMe.subRegions[2] = F.subtext("%p", 16, "INNER_BOTTOM")
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
ccOnMe.load = pvpLoad(false)
alertAnimations(ccOnMe)
adopt(gAlerts, ccOnMe)

-- ---- prompt: Fear Ward is off you AND off cooldown ----------------------
-- Fear Ward is consumed by the first fear, so "missing" is a live state in
-- every arena, not a pre-pull constant. Both triggers must hold, so the prompt
-- is exactly the moment the press exists: re-ward before the next go, and know
-- that until it is back up the first fear costs the trinket.
local fward = reg(F.icon("Priest - FEAR WARD MISSING", CLASS, 44, 44, 0, 0, nil))
fward.triggers = F.triggers({
  F.auraTrigger("player", true, { 6346 }, { matchesShowOn = "showOnMissing" }),
  F.cdTrigger(6346, "Fear Ward", "showOnReady"),
})
fward.iconSource = 0
fward.displayIcon = "Interface\\Icons\\spell_holy_excorcism"
fward.cooldown = false
fward.subRegions[1] = F.subglow(true, { 0.4, 0.8, 1, 1 })
fward.load = pvpLoad(false, { use_spellknown = true, spellknown = 6346 })
alertAnimations(fward)
adopt(gAlerts, fward)

-- ---- prompt: the target went immune AND Mass Dispel is up ---------------
-- Every other class treats Divine Shield / Ice Block / Blessing of Protection
-- as a stop sign; the priest is the one class that can answer it, so this is a
-- press, not a warning. Trigger 1 is first and therefore owns the dynamic
-- info: %p counts down the bubble, which is the whole decision (dispel it now
-- or you burn the kill window waiting it out). Divine Shield 642/1020,
-- Ice Block 45438 (27619 is the older id, kept for safety), Blessing of
-- Protection 1022/5599/10278 — all ranks, all verified on wowhead.com/tbc.
local mdispel = reg(F.icon("Priest - MASS DISPEL NOW", CLASS, 44, 44, 0, 0, nil))
mdispel.triggers = F.triggers({
  F.auraTrigger("target", true, { 642, 1020, 45438, 27619, 1022, 5599, 10278 }),
  F.cdTrigger(32375, "Mass Dispel", "showOnReady"),
})
mdispel.iconSource = 0
mdispel.displayIcon = "Interface\\Icons\\spell_arcane_massdispel"
mdispel.cooldown = false
mdispel.subRegions[1] = F.subglow(true, { 1, 0.85, 0.2, 1 })
mdispel.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
mdispel.load = pvpLoad(false, { use_spellknown = true, spellknown = 32375 })
alertAnimations(mdispel)
adopt(gAlerts, mdispel)

-- ---- prompt: the target is casting AND Silence is castable (Shadow) -----
-- No spell-id filter, on purpose: WeakAuras disables the "interruptible" arg
-- on TBC clients outright (enable = not IsTBC()), so there is no way to ask
-- "can I interrupt this", and a whitelist of every enemy heal is unmaintainable.
-- The second trigger is Action Usable, which folds cooldown, mana AND range
-- into one boolean — that is what stops the prompt from screaming while
-- Silence is down. %p is the remaining cast time.
local silence = reg(F.icon("Priest - SILENCE NOW", CLASS, 44, 44, 0, 0, nil))
silence.triggers = F.triggers({
  gTrigger{ type = "unit", event = "Cast", unit = "target", use_unit = true },
  gTrigger{ type = "spell", event = "Action Usable",
            use_spellName = true, spellName = 15487, realSpellName = "Silence",
            use_exact_spellName = true, use_ignoreoverride = true },
})
silence.iconSource = 0
silence.displayIcon = "Interface\\Icons\\spell_shadow_impphaseshift"
silence.cooldown = false
silence.subRegions[1] = F.subglow(true, { 0.55, 0.35, 1, 1 })
silence.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
silence.load = pvpLoad(false, { use_spellknown = true, spellknown = 15487 })
alertAnimations(silence)
adopt(gAlerts, silence)

-- ---- state: my own PvP trinket is DOWN ----------------------------------
-- Visible ONLY while on cooldown, so an empty column means "your break is
-- ready" — the normal case stays silent. One trigger per item id, OR-combined:
-- the equipment-slot trigger would read whatever sits in slot 13/14, so a PvE
-- on-use trinket would report "trinket down" while the medallion is ready, and
-- that false negative is a death in the one decision this element exists for.
-- Priest-usable ids, both factions (wowhead.com/tbc): 18862/18851 Insignia
-- (5 min), 30349/30346 Medallion (2 min), 37864/37865 the 2.4 epic Medallion.
local trinket = reg(F.icon("Priest - Trinket DOWN", CLASS, 32, 32, 0, 0, nil))
local trinketTrigs = {}
for i, itemId in ipairs({ 18862, 18851, 30349, 30346, 37864, 37865 }) do
  trinketTrigs[i] = gTrigger{
    type = "item", event = "Cooldown Progress (Item)",
    use_itemName = true, itemName = itemId,          -- NUMERIC id; a name never resolves
    use_genericShowOn = true, genericShowOn = "showOnCooldown",
  }
end
trinket.triggers = F.triggers(trinketTrigs, { disjunctive = "any" })
trinket.cooldownTextDisabled = false  -- swipe numbers; no %p subtext (OmniCC double-number trap)
trinket.desaturate = true             -- greyed = unavailable, readable without reading
trinket.load = pvpLoad(false)
adopt(gPvP, trinket)

-- ---- state: Will of the Forsaken is DOWN (Forsaken only) ----------------
-- On 2.4.3 WotF does not share a cooldown with the medallion (that arrived in
-- 3.3), so an undead priest genuinely carries two breaks — and whether the
-- second one is up is what decides if the first gets spent on a Sap. Gated on
-- the racial's own id, so it simply never loads for anyone else.
local wotf = reg(F.icon("Priest - Will of the Forsaken DOWN", CLASS, 32, 32, 0, 0, nil))
wotf.triggers = F.triggers({ F.cdTrigger(7744, "Will of the Forsaken", "showOnCooldown") })
wotf.cooldownTextDisabled = false
wotf.desaturate = true
wotf.load = pvpLoad(false, { use_spellknown = true, spellknown = 7744 })
adopt(gPvP, wotf)

-- ---- state: an opponent's trinket is on cooldown (arena) ----------------
-- There is no API that reads another player's cooldowns on 2.5.x. This is the
-- sanctioned inference: see the cast, start your own 2-minute clock. One clone
-- per opponent (unit = "arena" clones, hence the dynamicgroup parent). Spell
-- 42292 "PvP Trinket" is what every medallion and insignia casts (verified on
-- the item pages); the 120s duration is the medallion, which is what everyone
-- wears at 70 — an opponent still on the 5-minute vanilla insignia will show a
-- clock that ends early.
local etrinket = reg(F.icon("Priest - Enemy Trinket", CLASS, 32, 32, 0, 0, nil))
etrinket.triggers = F.triggers({
  gTrigger{ type = "event", event = "Spell Cast Succeeded",
            unit = "arena", use_unit = true,
            use_spellId = true, spellId = { "42292" },
            duration = "120" },  -- REQUIRED on a timedrequired trigger; missing = 1s flash
})
etrinket.cooldownTextDisabled = false
etrinket.load = pvpLoad(true)
adopt(gPvP, etrinket)

-- ---- state: Unstable Affliction on a team-mate (arena) ------------------
-- Dispel Magic is the highest-frequency button a TBC priest owns, and this is
-- the one state that must interrupt the habit: dispelling UA costs ~1050
-- damage and a 5s silence, which is the warlock's whole game plan. One clone
-- per affected ally, all three ranks (30108/30404/30405), not own-only.
-- Arena-gated on purpose: in a 40-man battleground this would be a permanent
-- wall of icons for people you will never dispel.
local uaAlly = reg(F.icon("Priest - UA on Ally", CLASS, 36, 36, 0, 0, nil))
uaAlly.triggers = F.triggers({
  F.auraTrigger("group", false, { 30108, 30404, 30405 },
    { showClones = true, combinePerUnit = true, perUnitMode = "affected" }),
})
uaAlly.cooldown = false
uaAlly.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
uaAlly.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
uaAlly.load = pvpLoad(true)
adopt(gPvP, uaAlly)

-- ---- state: my control effects on the enemy team (arena) ---------------
-- One clone per controlled opponent, own-only, with the remaining duration:
-- Psychic Scream (8122/8124/10888/10890) and Mind Control (605/10911/10912)
-- say HOLD DAMAGE — a tick breaks them; Silence (15487) on their healer says
-- GO, and counts down exactly how long the kill window lasts. No glow: this is
-- a state read-out, and in this pack glow means "press something".
local myCC = reg(F.icon("Priest - My CC Out", CLASS, 36, 36, 0, 0, nil))
myCC.triggers = F.triggers({
  F.auraTrigger("arena", false, { 8122, 8124, 10888, 10890, 15487, 605, 10911, 10912 },
    { ownOnly = true, showClones = true, combinePerUnit = true, perUnitMode = "affected" }),
})
myCC.cooldown = false
myCC.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
myCC.load = pvpLoad(true)
adopt(gPvP, myCC)

-- =====================================================================
-- v5 addition — the Mana Burn scoreboard. Created after every earlier
-- W.uid() call, so all 39 v4 uids keep their positions in the seeded stream.
-- =====================================================================

-- ---- state: enemy mana, one bar per opponent (arena) --------------------
-- Mana Burn is the priest's second win condition and it is the only one you
-- cannot see: burning 700-750 mana a cast into a 9k healer is a decision you
-- have to be able to score. This is that scoreboard.
--
-- unit = "arena" makes the Power prototype clone one state per opponent
-- (statesParameter = "unit"), hence the dynamicgroup parent — the same
-- mechanism the enemy trinket clock and the CC rows already use.
--
-- Both use_powertype AND powertype = 0 are required: without the flag the
-- trigger silently reads whatever bar the opponent primarily uses, so a rogue
-- row would show ENERGY as if it were mana. use_requirePowerType then hides
-- every opponent whose primary resource is not mana, so rogues and warriors
-- never take up a row and the column is exactly the people worth burning.
--
-- Colour is identity: standard class colours, which every player already reads
-- without thinking (warrior red and rogue yellow can never appear — those two
-- are filtered out by requirePowerType, which is also why red is free to mean
-- something else here). Under 20% the bar goes red: that is roughly two heals
-- left, the point where mana, not damage, is the fastest way to win.
--
-- Arena-only, never battleground: arena1..arena5 do not exist in a BG, so a
-- BG-loaded copy would be permanently blank rows.
local emana = reg(F.aurabar("Priest - Enemy Mana", CLASS, 120, 14, 0, 0, nil,
  { 0.25, 0.5, 0.92, 1 }))
local emanaTrigger = F.powerTrigger(0)   -- 0 = Mana, with use_powertype set
emanaTrigger.unit = "arena"              -- clones: arena1..arena5
emanaTrigger.use_requirePowerType = true -- mana must be their PRIMARY bar
emana.triggers = F.triggers({ emanaTrigger })
emana.subRegions[2] = F.subtext("%percentpower%%", 12, "INNER_RIGHT", "percentpower")
emana.subRegions[3] = F.subborder("bar")
emana.conditions = {
  F.condition(1, "class", "==", "DRUID",   "barColor", { 1, 0.49, 0.04, 1 }),
  F.condition(1, "class", "==", "HUNTER",  "barColor", { 0.67, 0.83, 0.45, 1 }),
  F.condition(1, "class", "==", "MAGE",    "barColor", { 0.41, 0.8, 0.94, 1 }),
  F.condition(1, "class", "==", "PALADIN", "barColor", { 0.96, 0.55, 0.73, 1 }),
  F.condition(1, "class", "==", "PRIEST",  "barColor", { 1, 1, 1, 1 }),
  F.condition(1, "class", "==", "SHAMAN",  "barColor", { 0, 0.44, 0.87, 1 }),
  F.condition(1, "class", "==", "WARLOCK", "barColor", { 0.58, 0.51, 0.79, 1 }),
  -- last, so it wins over the class colour: nearly dry, go now
  F.condition(1, "percentpower", "<", "20", "barColor", { 0.9, 0.12, 0.12, 1 }),
}
emana.load = pvpLoad(true)
adopt(gPvP, emana)

-- =====================================================================
-- THE FACE, and the three uid slots the target cluster used to occupy. Created after
-- every earlier W.uid() call, so all 40 v6 uids keep their positions in the seeded
-- stream, then re-parented into the Resources group. Adoption order is also draw
-- order: FixGroupChildrenOrder adds +4 frame levels per child as it walks
-- controlledChildren, so EARLIER = further behind.
--
-- BURNED SLOTS, AND WHY THEY ARE NOT FILLED. v12 deletes three regions, so three uids
-- from this seeded stream have no home. The tempting fixes are both wrong:
--   * inventing a filler region to absorb a slot is how a HUD accumulates junk, and
--   * simply deleting the three ring()/track()/portrait() calls would SHIFT every
--     later call in the stream — Priest - Player Portrait sits BETWEEN two of them and
--     would silently inherit Priest - Target Health's uid, which WeakAuras would then
--     match against the installed target ring and "Update" a face over it.
-- So the calls are replaced by bare W.uid() calls whose result is discarded, at the
-- exact positions they held since v7. The surviving portrait keeps the uid it has had
-- for five versions, and no future version can ever hand a deleted region's uid to a
-- new aura, because these three draws stay burned forever.
--   slot 1 (was Priest - Target Health)    burned
--   slot 2 (was Priest - Target Track)     burned
--   slot 3      Priest - Player Portrait   KEPT
--   slot 4 (was Priest - Target Portrait)  burned
-- The three deleted ids are declared at the top of this file in the WA-REMOVED lines
-- tools/verify-packs.lua reads, and named in README "After updating" — WeakAuras never
-- deletes an aura an import does not mention, so the player deletes them by hand once.
-- =====================================================================

W.uid()  -- burned: the v7-v11 "Priest - Target Health" slot (target inner ring)
W.uid()  -- burned: the v7-v11 "Priest - Target Track" slot (target outer annulus)

-- YOUR FACE. The portrait takes the same triggers as the rings around it, so the
-- cluster lives and fades as ONE object: the player Health + Unit Characteristics
-- pair, hence the same out-of-combat fade the rings have and the same zero-total
-- guard. The target's face is gone with the rest of its cluster.
local pPortrait = reg(portrait("Priest - Player Portrait", "player",
  -CLUSTER_X, CLUSTER_LOCAL_Y))
pPortrait.triggers = F.triggers({ F.healthTrigger(nil), F.unitCharTrigger() })
pPortrait.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}
adopt(gRes, pPortrait)

W.uid()  -- burned: the v7-v11 "Priest - Target Portrait" slot (target face)

-- The threat ring goes in LAST: same frame strata (1), and within a strata the later
-- child carries the higher frame level (+4 per child, in controlledChildren order), so
-- the outermost ring of the cluster is also the one drawn on top.
adopt(gRes, threat)

-- ===== icon polish: crop + 1px outline on every icon =====
for _, icon in ipairs(icons) do
  icon.zoom = 0.3
  table.insert(icon.subRegions, F.subborder())
end

-- ===== assemble (v2000 nested), encode, verify =====
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

-- ===== POSITION PROOF: the build refuses to ship a cluster that is not on its
-- canonical absolute screen coordinate. Local offsets are derived from the absolute
-- numbers, so a stale TOP_Y/RES_Y — or one hard-coded local y typed in by hand — is
-- exactly the mistake that produced seven differently-placed HUDs before. This walks
-- the real parent chain of the ENCODED data rather than re-running the arithmetic
-- that produced it, and also re-derives every breakpoint mark's radius and angle back
-- out of its committed x/y, so a mark can never be left orbiting a ring it no longer
-- rides. =====
local decoded = W.decode(encoded)
local nodes = { [decoded.d.id] = decoded.d }
for _, ch in ipairs(decoded.c) do nodes[ch.id] = ch end

local function absolute(id)
  local x, y, node, guard = 0, 0, assert(nodes[id], "no such aura: " .. id), 0
  while node do
    x, y = x + (node.xOffset or 0), y + (node.yOffset or 0)
    guard = guard + 1; assert(guard < 50, "parent chain cycle at " .. id)
    node = node.parent and nodes[node.parent] or nil
  end
  return x, y
end

local CLUSTER = {
  { "Priest - Threat",           -CLUSTER_X, CLUSTER_Y, THREAT_RING },
  { "Priest - Health",           -CLUSTER_X, CLUSTER_Y, OUTER },
  { "Priest - Mana",             -CLUSTER_X, CLUSTER_Y, INNER },
  { "Priest - Player Portrait",  -CLUSTER_X, CLUSTER_Y, PORTRAIT },
}
for _, want in ipairs(CLUSTER) do
  local id, wx, wy, size = want[1], want[2], want[3], want[4]
  local x, y = absolute(id)
  assert(x == wx and y == wy,
    ("%s lands at (%d,%d), canon is (%d,%d)"):format(id, x, y, wx, wy))
  local node = nodes[id]
  assert(node.width == size and node.height == size,
    ("%s is %sx%s, canon is %d"):format(id, tostring(node.width), tostring(node.height), size))
end

-- CONCENTRIC, stated as its own assertion rather than inferred from the table above:
-- four regions of four different diameters are only a cluster if they share ONE
-- centre, and "each is at (-270, 40)" and "all four are at the same point" are
-- different claims when one of them is typed wrong.
do
  local cx, cy = absolute(CLUSTER[1][1])
  for _, want in ipairs(CLUSTER) do
    local x, y = absolute(want[1])
    assert(x == cx and y == cy,
      ("%s centre (%d,%d) is not concentric with (%d,%d)"):format(want[1], x, y, cx, cy))
    assert(nodes[want[1]].selfPoint == "CENTER" and nodes[want[1]].anchorPoint == "CENTER",
      want[1] .. ": a shared centre only means concentric if both anchors are CENTER")
  end
end

-- THE TARGET CLUSTER IS GONE, checked against the shipped data rather than against
-- the source that built it: an id left behind in a table somewhere would otherwise
-- ship a lone target ring with no cluster around it.
for _, id in ipairs(REMOVED) do
  assert(not nodes[id], id .. " is declared removed but is still in the string")
end

-- ALERT-COLUMN CLEARANCE, with the stack projected ALERT_DEPTH children deep. The
-- Alerts column is a dynamic group: it is one aura wide in the source and as tall as
-- the number of simultaneous prompts, so measuring it at rest is what let an earlier
-- pass ship a cluster that only cleared while a single alert was showing. Growth is
-- vertical ("UP"), so depth changes the column's HEIGHT, never its width — the proof
-- therefore computes the projected stack's full bounding box and requires the ring to
-- clear it in x whatever the height turns out to be.
do
  local ringSpan     = THREAT_RING / 2
  local clusterRight = -CLUSTER_X + ringSpan            -- -220
  local alertLeft    = ALERTS_X - ALERT_W / 2           -- -172
  local stackHeight  = ALERT_DEPTH * ALERT_W + (ALERT_DEPTH - 1) * ALERT_SPACE
  local ax, ay       = absolute("Priest - Alerts")
  local stackTop     = ay + stackHeight                 -- grow = "UP", selfPoint BOTTOM
  assert(ax == ALERTS_X,
    ("Alerts column sits at x=%d, the clearance proof assumes %d"):format(ax, ALERTS_X))
  assert(clusterRight < alertLeft,
    ("threat ring reaches x=%d; the %d-deep alert stack starts at x=%d")
      :format(clusterRight, ALERT_DEPTH, alertLeft))
  -- The vertical overlap is real and expected (the stack climbs past the cluster's
  -- band from the third prompt on), which is exactly why the x gap has to be proven
  -- rather than assumed away.
  assert(stackTop > CLUSTER_Y - ringSpan,
    "projected alert stack does not reach the cluster band; recheck ALERT_DEPTH")
  print(("clearance: threat ring x %d..%d | %d-deep alert stack x %d..%d, y %d..%d -> %dpx gap")
    :format(-CLUSTER_X - ringSpan, clusterRight, ALERT_DEPTH,
      alertLeft, ALERTS_X + ALERT_W / 2, ay, stackTop, alertLeft - clusterRight))
end

-- Each breakpoint mark, checked the other way round: radius and angle are recovered
-- from the committed offsets, so the proof does not depend on the arithmetic above.
for _, want in ipairs({
  { "Priest - Health", 2, OUTER, 40 },
  { "Priest - Mana",   2, INNER, 50 },
}) do
  local id, index, size, percent = want[1], want[2], want[3], want[4]
  local sub = assert(nodes[id].subRegions[index], id .. ": no mark at " .. index)
  assert(sub.type == "subtexture", id .. ": sub." .. index .. " is not the mark")
  local r = math.sqrt(sub.xOffset ^ 2 + sub.yOffset ^ 2)
  assert(math.abs(r - size / 2 * MARK_RADIUS) < 0.001,
    ("%s mark radius %.4f, expected %.4f"):format(id, r, size / 2 * MARK_RADIUS))
  -- atan2(x, y): angle from 12 o'clock, clockwise — the ring's own fill direction.
  local angle = math.deg(math.atan2(sub.xOffset, sub.yOffset)) % 360
  assert(math.abs(angle - percent * 3.6) < 0.01,
    ("%s mark sits at %.3f degrees, %d%% implies %.1f"):format(id, angle, percent, percent * 3.6))
  assert(#nodes[id].subRegions == index, id .. ": the mark must stay the last sub-region")
end

-- uid continuity against the previous on-disk version, measured BEFORE the file is
-- overwritten, so every future re-run is checked against the string that shipped
local txtPath = dir .. "/all-specs.txt"
-- REMOVED is the licence: exactly the three target-cluster ids may lose their uid, and
-- any OTHER disappearance still fails here. `changed` (an id that kept its name and
-- swapped uid) is never forgivable and is asserted independently inside the helper.
local cont = W.uidContinuity(encoded, txtPath)
W.assertUidContinuity(cont, "priest", REMOVED)

local out = assert(io.open(txtPath, "w"))
out:write(encoded)  -- single line, no trailing newline
out:close()

print(("OK: %d auras (top group + %d children), %d chars -> all-specs.txt")
  :format(#transmit.c + 1, #transmit.c, #encoded))
if cont then
  print(("uid continuity vs previous: stable=%d changed=%d retained=%d missing=%d parentSame=%s")
    :format(cont.stable, cont.changed, cont.retained, cont.missing, tostring(cont.parentSame)))
  if cont.missing > 0 then
    print("  deliberately removed: " .. table.concat(cont.missingIds, ", "))
  end
end
