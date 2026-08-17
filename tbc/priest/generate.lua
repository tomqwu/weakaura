-- generate.lua — Priest TBC All-Specs HUD (v15).
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
--
-- v13 (the health number moves INTO the cluster, and the draw order makes that legal):
--   * THE COMPLAINT, VERBATIM: "percentage in middle can't be seen". It was true of the
--     shipped v12 data — decoded, the health number sat 54px BELOW the rings at 13pt
--     and mana 70px below at 10pt, two small detached digits floating over whatever the
--     game happened to be drawing there, while the MIDDLE of the cluster — the one
--     place that is always backed by the portrait's own art — held nothing but a face.
--   * HEALTH GOES DEAD CENTRE at 16pt (PCT_HP y = -54 -> 0, size 13 -> 16). It is read
--     mid-fight, at a glance, and it now reads against your own portrait rather than
--     against the terrain.
--   * MANA TAKES THE SLOT HEALTH VACATES at 12pt (PCT_POWER y = -70 -> -54, size
--     10 -> 12): just under the outer ring, where health used to sit. Threat is
--     unchanged at +58/10pt — it is the outermost ring's own label and it was never
--     the number that was hard to find.
--   * MOVING THE OFFSET ALONE WOULD HAVE DONE NOTHING VISIBLE, which is the actual
--     content of this version. A text sub-region draws with the region that owns it,
--     and FixGroupChildrenOrder assigns frame levels in controlledChildren order
--     (+4 per child), so the portrait — LAST in Priest - Resources since v12 — drew on
--     top of everything the rings put in the middle. The portrait is now the FIRST
--     child of that group and the three rings follow it, so ring art and ring TEXT
--     both draw over the face.
--   * THAT IS SAFE BECAUSE A RING IS AN ANNULUS. Ring_20px's band occupies only its
--     own stroke — threat 42.19..50.00, health 35.44..42.00, mana 26.16..31.00, and
--     the portrait spans 0..22 — so nothing a ring draws lands on the face except its
--     subtext, which is the entire point. The build asserts the radii do not overlap
--     rather than trusting this paragraph.
--   * Nothing else moves. No aura added or removed, no uid() call added, removed or
--     reordered (re-parenting order is not uid order), same seed, same triggers, load
--     gates, conditions, colours, sizes and positions. Two subtext offsets, two font
--     sizes and one child order: that is the whole diff.
--
-- v14 (THE SILL — the ring cluster becomes a 102x31 instrument strip under your feet):
--   * ONE PIXEL IS ONE PERCENT. The 100px concentric cluster is replaced by three
--     stacked 100px-long rails — threat 100x4, health 100x11, mana 100x11 — on a
--     102x31 dark plate, at absolute screen (0, -110), directly under the character.
--     A rail's length is the exact length at which a 0..100 gauge is lossless: every
--     pixel past 100 re-draws a state the eye cannot separate, every pixel short of it
--     discards one. It also turns every breakpoint from trigonometry into arithmetic —
--       x(v) = (v / max - 0.5) * 100,  which for a 0..100 resource is just x = v - 50
--     — where the ring version needed r = size/2 * 0.94, x = r*sin(2*pi*f),
--     y = r*cos(2*pi*f) and landed the 40% health mark on (23.206, -31.94).
--   * THE NUMBERS MOVE INSIDE THE RAILS. Health and mana print at 11pt at
--     text_anchorXOffset = +32 inside their own rail, so the digits always have the
--     pack's own plate behind them instead of snow, lava or a lit floor — which is
--     the failure v13 was still only half-fixing by parking health on a 44px face.
--   * EVERY BREAKPOINT IS A FULL-HEIGHT WATERLINE. The 40% Desperate Prayer mark and
--     the 50% Shadowfiend mark keep their thresholds, their colour and their sub.2
--     index and become 3x11 lines that cut the whole rail at x = -10 and x = 0. Three
--     1x11 hairlines at 25/50/75 are appended after them, which converts a rail from
--     "estimate a fraction" to "count quarters" for 33px of ink and zero footprint.
--     The threat rail gains a 2x4 notch at 70 (x = +20) — the line the Fade prompt and
--     the orange escalation already fire on, now visible before it fires.
--   * THE PORTRAIT BECOMES THE PLATE. "Priest - Player Portrait" is re-typed
--     model -> texture, renamed "Priest - Sill Plate", resized 44x44 -> 102x31, and
--     keeps its uid, its Health + Unit Characteristics triggers and both of its
--     conditions. It is drawn FIRST, so every rail and every number sits on it.
--     LOST: the live 3D portrait. It was 1,936 px2 carrying zero decisions, but it is
--     also the thing that made the cluster read as *you*, and that is a real loss.
--   * THE THREAT NUMBER IS SWITCHED OFF, not deleted: sub.1 keeps its index, its
--     offsets and its colour and takes text_visible = false. threatpct is scaled so
--     100 = pulling aggro, i.e. an early-warning ratio rather than a quantity, and a
--     notch at the 70 line answers it faster than reading "68" vs "72". One checkbox
--     in /wa turns it back on.
--   * THE GROUP MOVES, THE PACK DOES NOT. "Priest - Resources" is renamed
--     "Priest - Player Sill" and its own offset goes (0, 56) -> (0, 30), which under
--     the unchanged top group (0, -140) resolves to absolute (0, -110). Every leaf's
--     local offset is zeroed onto the lane table, so the strip's position is the
--     group's and the group is draggable as one object. NO other row moves: the build
--     proves the 102x31 rectangle against every other region in the pack, with all
--     four dynamic groups projected six children deep, and finds zero overlaps
--     (11.5px clear of the y -80 band above, 13.5px clear of the buff row below).
--   * NOT BUILT, AND SAID OUT LOUD: the design's sixth lane, the alarm frame that
--     pulses the strip's outline red at threatpct >= 80. Every other pack recycles its
--     "<Pack> - Threat Flash" region for it; this pack has never had one (decoding v13
--     for alphaPulse returns only Priest - Holy Procs), so building it would cost a
--     NEW uid, and the three uid slots this pack has spare are BURNED v12 removals
--     that must never be handed to a new region. The threat rail still escalates
--     green -> orange at 70 -> red on aggro, and the Fade prompt still fires at 70.
--   * No aura is added or removed and no uid() call is added, removed or reordered:
--     all 40 child uids are exactly v13's, so this imports as an Update. Leave the
--     update dialog's ARRANGEMENT category checked — this version re-parents nothing
--     but it does re-order the group's children and move the group itself, and both
--     travel in that category.
--   * Untouched, byte for byte: every trigger, every load gate, every condition and
--     every fill colour on all four cluster regions, and the whole of the rest of the
--     pack — buffs, alerts, the cooldown row, procs and the PvP layer.

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
-- v14 REMOVES NOTHING, so the list below is empty and the strict default contract
-- applies again: every uid must survive, full stop. The v12 lines are kept as history
-- (they are what the README's "After updating" still refers to) but they no longer
-- grant anything — the scan honours only entries tagged with the version this pack
-- currently ships, so a removal licence expires by itself at every version bump.
-- The three v12 ids were the entire target cluster. Nothing replaced them, and their
-- burned uid slots must stay burned: v14 wanted a sixth region (the alarm frame) and
-- did NOT take one of them, because WeakAuras matches by uid and would have "Updated"
-- a deleted target ring into it in every copy that never hand-deleted the orphans.
local VERSION = "v14"
-- WA-REMOVED (v12): Priest - Target Health
-- WA-REMOVED (v12): Priest - Target Track
-- WA-REMOVED (v12): Priest - Target Portrait
local REMOVED = {}      -- THIS version's licence to drop uids; empty in v14
local EVER_REMOVED = {} -- every id this pack has ever deleted, whatever the version
do
  local selfPath = realArg0 or (dir .. "/generate.lua")
  local src = assert(io.open(selfPath, "r"), "cannot read own source: " .. selfPath)
  local body = src:read("*a"); src:close()
  for tag, id in body:gmatch("%-%-%s*WA%-REMOVED%s*%((v%d+)%)%s*:%s*([^\n]-)%s*\n") do
    EVER_REMOVED[#EVER_REMOVED + 1] = id
    if tag == VERSION then REMOVED[#REMOVED + 1] = id end
  end
  -- The "is it still in the string" check at the bottom runs off EVER_REMOVED, not off
  -- REMOVED: tying it to the current version would have made it vacuous the moment the
  -- licence expired, and a deleted id that reappears is exactly the accident that
  -- ships a lone target ring with no cluster around it.
  assert(#EVER_REMOVED == 3,
    ("expected 3 historical removals, found %d"):format(#EVER_REMOVED))
  assert(#REMOVED == 0,
    ("%s removes nothing, but %d removal(s) are declared for it"):format(VERSION, #REMOVED))
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
-- controlledChildren order IS draw order — FixGroupChildrenOrder walks it and adds +4
-- frame levels per child, so index 1 is the furthest BACK — and F.assemble's depth-first
-- push emits `c` in that same order, so moving a name here moves the region in the
-- transmit too and the two cannot disagree (W.verify would reject a controlledChildren
-- list that did not match the children it can see). v13 needed an adoptBehind() helper
-- because the portrait had to be BUILT last (uid stream) while drawing FIRST; v14 does
-- not, because the whole Sill is adopted in one ordered block at the bottom of this
-- script, after the plate exists. Nothing about the uid stream changes either way —
-- re-parenting order is not uid order.

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
-- Rail toolkit. wa_factory.lua has no progresstexture builder, so the rail and plate
-- tables below are written out in full; every other piece (triggers, subtext,
-- conditions, load gates, assembly) still goes through the factory.
-- Field names verified against the CURRENT WeakAuras source, which is what
-- actually runs: internalVersion 45 only drives migration, and no Modernize block
-- at IV >= 45 renames any progresstexture fill field.
-- =====================================================================

-- Bundled WeakAuras media. Square_White.tga is a flat, uniform white quad — the only
-- art a linear gauge wants, because the fill is a texcoord crop of it and a crop of a
-- uniform quad is still a uniform quad at any aspect ratio. Square_White_Border.tga is
-- the same quad with a 1px inset border, which is what makes the plate read as ONE
-- instrument rather than three floating bars. Ring_20px.tga, the annulus every version
-- from v11 to v13 drew its arcs with, is gone from this pack: nothing here encodes a
-- value by sweep any more.
local RAIL_TEX  = F.TEX_SQUARE
local PLATE_TEX = F.TEX_SQUARE_BORDER

-- ===== THE SILL — CANONICAL, AND IDENTICAL IN ALL SEVEN PACKS =====
-- These are not priest tuning knobs. Every pack in this repo ships this exact lane
-- stack, and the whole point of naming them is that the seven copies cannot drift
-- apart: change them in all seven or in none.
--
-- ONE PIXEL IS ONE PERCENT. RAIL_W = 100 is the exact length at which a 0..100 gauge
-- is lossless — a longer bar re-draws states the eye cannot separate, a shorter one
-- throws states away — and it is what makes every breakpoint arithmetic:
--   x(v) = (v / max - 0.5) * RAIL_W ,  which for a 0..100 resource is just  x = v - 50
-- against the ring era's r = size/2 * 0.94 ; x = r*sin(2*pi*f) ; y = r*cos(2*pi*f).
local RAIL_W   = 100   -- gauge length: 1px = 1%
local SILL_W   = 102   -- plate width: the rails plus a 1px margin each side
local SILL_H   = 31    -- priest has no discrete class resource, so there is no lane 4
                       -- and the plate is the 37px one with that lane cut off
local PLATE_Y  = 3     -- the 31px plate's own local y (the 37px variant sits at 0)

-- The lane stack, local to the group anchor. Content runs +17.5 .. -10.5:
--   threat 4 | gap 1 | health 11 | gap 1 | power 11
-- and the plate spans +18.5 .. -12.5, so nothing a lane draws touches the plate edge.
local LANE = {
  threat = { h = 4,  y = 15.5 },
  health = { h = 11, y = 7 },
  power  = { h = 11, y = -5 },
}

-- THE ABSOLUTE-POSITION RULE, written as arithmetic instead of as a comment.
-- A child anchored anchorFrameType = "SCREEN" inside a group anchors to THAT GROUP's
-- frame (GetAnchorFrame returns the parent region for "SCREEN"), so offsets ADD all
-- the way down the parent chain. SILL_X/SILL_Y are the ABSOLUTE numbers, so the group's
-- local offset is DERIVED — type 56 straight in (what v13 shipped) and the strip lands
-- at -84, which is how a "one canonical layout" pass ends up with seven different HUDs.
--   top (0, TOP_Y) + Player Sill (0, SILL_LOCAL_Y) + lane (0, LANE.*.y) = absolute
-- Every lane carries x = 0 and its own local y, and NOTHING else in the pack moves.
local SILL_X = 0      -- ABSOLUTE screen x: dead centre, under the character
local SILL_Y = -110   -- ABSOLUTE screen y of the group anchor (the plate's own centre
                      -- is SILL_Y + PLATE_Y, so the strip spans -91.5 .. -122.5)
local TOP_Y  = -140   -- the top-level group, unchanged since v1
local SILL_LOCAL_Y = SILL_Y - TOP_Y   -- = 30  -> absolute -110

-- y = -110 is not a taste call either. The universal free band under the character is
-- bounded above by paladin's and hunter's buff rows (y -80..-40) and below by the other
-- five packs' buff rows (y -176..-136); priest's own is at y -156, i.e. -136..-176. A
-- 102x37 rectangle centred on -110 clears the first by 11.5px and the second by 7.5px,
-- and it is the only value in that band with margin on both sides. Priest's strip is
-- 31 tall and top-aligned inside that 37, so it clears the row below by 13.5px. The
-- build proves it against every region in the pack at the bottom of this script, with
-- all four dynamic groups projected DYN_DEPTH children deep rather than measured at
-- rest — measuring a dynamic group at rest is what let an earlier pass ship a cluster
-- that only cleared while a single alert was showing.
local DYN_DEPTH = 6

-- Percentage read-outs, also shared across the seven packs. The number now prints
-- INSIDE its own rail at x = +32: two digits at 11pt is ~14px wide (x +25..+39) and
-- three digits ~21px (x +21.5..+42.5), both comfortably inside the rail's right edge,
-- and both always backed by the pack's own plate rather than by the terrain. That is
-- the whole reason the plate earns its pixels — the reported failure was never the
-- font size, it was that a bright floor or a fire washed the digits out.
--
-- THE OFFSET KEY IS A TRAP, and it is the exact silent-no-op shape this repo keeps
-- getting caught by. SubText's modify() reads `data.text_anchorXOffset` /
-- `data.text_anchorYOffset` — in WeakAuras 3.5.0 (SubText.lua:408) and in current
-- code (SubText.lua:486) alike — but the `default()` table it ships alongside them
-- writes `anchorXOffset` / `anchorYOffset`, and NO Modernize block in any version
-- copies one to the other (grep both: zero hits for text_anchorYOffset). So the
-- factory's anchorYOffset is a DEAD key: setting it moves nothing. With only the dead
-- key, both numbers would fall back to their own rail's centre and sit on top of the
-- fill instead of at its right end, with no error anywhere. Both spellings are emitted;
-- text_* does the work.
-- (text_anchorPoint is the opposite case and is fine: Modernize < 80 renames it to
-- anchor_point, which is what current code reads, so the factory value survives.)
--
-- THREAT'S NUMBER IS OFF, NOT GONE. `threatpct` is scaled so 100 = pulling aggro, so
-- it is an early-warning RATIO rather than a quantity you act on — reading "68" vs
-- "72" is slower than watching the fill cross the notch at 70 — and a 4px rail has no
-- room to print it inside itself. sub.1 therefore keeps its index, its size and its
-- colour and only takes text_visible = false, so no condition's sub.N reference moves
-- and the number is one checkbox in /wa away.
--
-- BUT ITS OFFSET HAD TO MOVE WITH THE REGION, and that is what v14 fixes here. The ring
-- era anchored that number at y = +58: radius 50 of the 100px threat ring plus 8px of
-- clearance, i.e. a label parked just ABOVE the arc it named. Carried unchanged onto a
-- 4px rail whose centre is absolute -94.5, the same +58 resolves to absolute
-- (0, -36.5) — 55px above the plate's top edge at -91.5, floating on bare terrain.
-- Switched off it is invisible either way, so nothing in the drawn picture was wrong;
-- what was wrong is the PROMISE. "One checkbox away in /wa" has to mean the number
-- comes back ON the instrument, and at +58 re-ticking it would have handed the player
-- the exact failure this version exists to end — a 10pt number on the game's own
-- background. y = 0 parks it on its own rail, which is on the plate.
-- x stays 0 rather than joining the other two at +32. The strip is packed solid (three
-- rails plus their 1px gaps fill the plate top to bottom), so a re-enabled 10pt glyph
-- box cannot avoid overlapping a neighbouring lane; the centre column is the one place
-- it cannot land on top of the HEALTH or MANA number, which is the overlap that would
-- actually cost a read. The build asserts every label's anchor resolves inside the
-- plate — VISIBLE OR NOT — so a hidden region can never quietly keep a dead offset
-- again.
local PCT_HP     = { size = 11, x = 32, y = 0 }
local PCT_POWER  = { size = 11, x = 32, y = 0 }
local PCT_THREAT = { size = 10, x =  0, y =  0, hidden = true }

local COL = {
  life   = { 0.15, 0.82, 0.28, 1 },   -- health green, unchanged since the bar era
  mana   = { 0.20, 0.45, 0.95, 1 },   -- mana blue; every priest spec runs on mana
  track  = { 0, 0, 0, 0.55 },         -- the UNFILLED part of every rail
  threat = { 0.25, 0.80, 0.30, 1 },   -- threat rail base, unchanged since v1
  warn   = { 1, 0.6, 0.1, 1 },        -- threat >= 70%
  danger = { 0.9, 0.12, 0.12, 1 },    -- health < 40%, and aggro
  hpText = { 1, 1, 1, 1 },
  mpText = { 0.55, 0.75, 1, 1 },      -- unchanged from the bar era, so the two
  thText = { 0.75, 0.95, 0.8, 1 },    -- numbers never need labels to be told apart
  mark   = { 1, 1, 1, 0.8 },          -- the two breakpoint waterlines, unchanged
  notch  = { 1, 1, 1, 0.85 },         -- the threat rail's 70 notch
  ruler  = { 1, 1, 1, 0.18 },         -- the 25/50/75 hairlines
  plate  = { 0, 0, 0, 0.45 },         -- the sill plate itself
}

-- wa_factory's stub() is local to the factory, so the hand-written rail and plate
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

-- THE RAIL. Same region type the rings and the v9/v10 globes used, one different
-- orientation — and that one field decides which of the others are live:
--   orientation "HORIZONTAL_INVERSE" -> the LINEAR fill path, anchored LEFT, growing
--     RIGHT. This is the trap that has to be stated: on an AURABAR "HORIZONTAL" is
--     left-anchored and grows right (gotchas.md), but on a PROGRESSTEXTURE the same
--     key is WeakAuras' "Right to Left" and the left-to-right value is the _INVERSE
--     one. Private.orientation_with_circle_types, transcribed verbatim in
--     poc/diablo-globes/generate.lua: HORIZONTAL_INVERSE = "Left to Right",
--     HORIZONTAL = "Right to Left", VERTICAL = "Bottom to Top",
--     VERTICAL_INVERSE = "Top to Bottom". VERTICAL off that same table is live in the
--     shipped poc/diablo-globes string, so the linear path itself is proven here;
--     HORIZONTAL_INVERSE is the one field in this version no committed string in this
--     repo has rendered before. 30-second check in game: drop to ~50% and confirm the
--     EMPTY half is on the RIGHT. If it is reversed the fix is a one-token swap to
--     "HORIZONTAL" and nothing else in the design changes.
--   startAngle / endAngle -> inert on the linear path (they drove the ring's sweep).
--     Emitted anyway: they are in the region's default table and the schema wants them.
--   compress / slanted / slantMode -> LIVE on the linear path (they were inert under
--     CLOCKWISE). All left off: a straight-ended fill is what reads as a gauge.
--   crop_x / crop_y = 0.41 -> on the linear path this is the texcoord scale, not the
--     circular path's sqrt(2) identity value. With a uniform white quad it cannot
--     alter the art at any aspect ratio, which is exactly why a 100x11 non-square
--     progresstexture is safe here even though every previous one in this repo was
--     square.
--   backgroundOffset = 0 -> the default 2 fattens the track relative to the fill,
--     which reads as a halo around the rail instead of the track beneath it.
--   backgroundColor = COL.track -> the unfilled part is a dark bar of exactly the same
--     size, so a rail at 20% is a fill on a track, not a fill in the void.
--   sameTexture = true -> backgroundTexture becomes dead code; both are set anyway.
--   auraRotation = 0 -> absent from the 3.5.0 default table but read unconditionally
--     by current code as data.auraRotation / 180 * math.pi, so it must be emitted.
--   adjustedMin/Max are STRINGS, because SetAdjustedMin does adjustedMin:find(...).
--   progressSource is rewritten to {-1, ""} (Automatic) by Modernize < 71 whatever is
--     emitted, which is WHY there is exactly one progress trigger per rail and it has
--     to be trigger 1: Automatic reads the first active trigger's value/total.
local function rail(id, w, h, color, x, y, trigger)
  return orbStub{
    regionType = "progresstexture", id = id, uid = W.uid(), parent = nil,
    width = w, height = h,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = x, yOffset = y, frameStrata = 1, alpha = 1,
    orientation = "HORIZONTAL_INVERSE", startAngle = 0, endAngle = 360,
    inverse = false, mirror = false,
    compress = false, slanted = false, slant = 0, slantFirst = false, slantMode = "INSIDE",
    foregroundTexture = RAIL_TEX, backgroundTexture = RAIL_TEX, sameTexture = true,
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

-- THE PLATE. A plain dark quad with a 1px border, drawn FIRST and therefore behind
-- everything. This is the region that used to be your face: same uid, same triggers,
-- same conditions, region type re-typed model -> texture (the v47/v51 precedent in the
-- rogue pack, and the same move v9 made in the other direction here).
-- It is not decoration. An 11px rail and an 11pt number survive snow, lava and
-- Shattrath at noon only because there is a known dark ground behind them, and four
-- lanes read as ONE instrument only because a single bordered plate encloses them.
-- Field set is F.texture's, written out here so it can carry orbStub's scaffolding and
-- its own uid() call site (which must stay exactly where the portrait's was).
local function plate(id, w, h, x, y, color)
  return orbStub{
    regionType = "texture", id = id, uid = W.uid(), parent = nil,
    texture = PLATE_TEX, desaturate = false,
    width = w, height = h,
    color = color, blendMode = "BLEND", textureWrapMode = "CLAMPTOBLACKADDITIVE",
    rotation = 0, discrete_rotation = 0, mirror = false, rotate = false, alpha = 1,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = x, yOffset = y, frameStrata = 1,
    subRegions = {},
    triggers = nil,   -- always supplied by the caller
  }
end

-- The percentages ride on their own rail and so appear and disappear with it: no
-- threat, no threat percentage. `spec` is one of the shared PCT_* tables, so a
-- number's size and its place inside the rail come from the canonical set rather than
-- from a per-call literal. Both offset spellings are written (see the trap above).
local function pct(sym, spec, color)
  local st = F.subtext("%" .. sym .. "%%", spec.size, "CENTER", sym)
  st.anchorXOffset = spec.x
  st.anchorYOffset = spec.y
  st.text_anchorXOffset = spec.x
  st.text_anchorYOffset = spec.y
  st.text_color = color
  if spec.hidden then st.text_visible = false end
  return st
end

-- THE ONE FORMULA. A breakpoint on a rail is a horizontal position, so the ring era's
-- trigonometry collapses to:  x(v) = (v / max - 0.5) * RAIL_W.
-- `max` is a parameter rather than a constant because it is the thing that moves: a
-- rogue's Vigor raises the energy cap 100 -> 110 and every mark shifts (gotchas.md).
-- Priest is mana-only in every spec and every form, so max is always 100 here and the
-- formula degenerates to x = v - 50 — but the general form is what is written, because
-- the six sibling packs share this file's geometry and one of them does not.
local function railX(value, max)
  return (value / (max or 100) - 0.5) * RAIL_W
end

-- A WATERLINE: a full-height line cutting the whole rail at a threshold, instead of a
-- 6.6px square sitting somewhere on an arc. Same subtexture field set the ring-era
-- mark() used, so the two shipped priest marks change nothing but their size and their
-- offsets — same type, same texture, same colour, same anchor mode, same sub.N index.
--   xOffset/yOffset are NOT in the subtexture default table but ARE read by
--   modify -> AnchorSubRegion, and only in anchor_mode = "point"; omit either and the
--   line stacks in the dead centre of the rail.
--   `subtick` still cannot come along (SubRegionTypes/Tick.lua's supports() returns
--   regionType == "aurabar", full stop); `subtexture` does list progresstexture.
local function waterline(value, w, h, color, max)
  return {
    type = "subtexture",
    textureVisible = true, textureTexture = F.TEX_SQUARE,
    textureColor = color, textureBlendMode = "BLEND",
    textureDesaturate = false, textureMirror = false,
    textureRotate = false, textureRotation = 0,
    anchor_mode = "point", anchor_point = "CENTER", self_point = "CENTER",
    anchor_area = "ALL",
    width = w, height = h,
    scale = 1, mirror = false, rotate = false,
    xOffset = railX(value, max), yOffset = 0,
  }
end

-- THE RULER: three 1px hairlines at 25 / 50 / 75, appended AFTER everything a
-- condition already points at. 33px of ink, zero footprint, and it turns a rail from
-- "estimate a fraction" into "count quarters" — the one thing a ring could never do,
-- because a quarter of a circle is not a quarter of anything the eye measures.
local RULER = { 25, 50, 75 }
local function addRuler(region, h)
  for _, value in ipairs(RULER) do
    region.subRegions[#region.subRegions + 1] = waterline(value, 1, h, COL.ruler)
  end
end

-- ===== top-level group, anchored below the character =====
local top = F.group(TOP, 0, TOP_Y, nil)
top.uid = W.uid()

-- =====================================================================
-- Player Sill (0,30 -> absolute 0,-110): since v14 this group IS the instrument, and
-- nothing else. Three 100px rails and the plate they sit on, stacked under your feet:
--   plate   102 x 31  at local (0,  +3)   the ground every number is read against
--   threat  100 x  4  at local (0, +15.5) your threat on your target
--   health  100 x 11  at local (0,  +7)   your health
--   mana    100 x 11  at local (0,  -5)   your mana
-- Local offsets, because the group carries the absolute position: drag the group and
-- the whole instrument moves as one object, which is what "Priest - Resources" at
-- (0,56) with four leaves each carrying (-270,124) never allowed.
--
-- WHY A STRIP AND NOT A SMALLER RING. The binding constraint under the character is
-- HEIGHT, not width — the free band is ~38px tall and 200px wide — and a ring buys
-- gauge length with area squared: Ring_20px's stroke is a fixed 7.8% of the drawn
-- size, so a small ring is a wire. The v13 cluster spent 10,000 px2 to carry three
-- gauges plus 1,936 px2 of portrait that decided nothing; the Sill carries the same
-- three gauges, both breakpoints, a 70 notch, three ruler ticks and two numbers in
-- 3,162 px2.
--
-- Health, mana and threat are built here (they are the v6 bar auras, converted in
-- place a fourth time so they keep their uids); the plate is built at the bottom of
-- this script, after every pre-existing W.uid() call, and the whole group is adopted
-- there in one ordered block — because controlledChildren order is draw order and the
-- plate has to be index 1.
-- =====================================================================
local gSill = reg(F.group("Priest - Player Sill", SILL_X, SILL_LOCAL_Y, nil))
adopt(top, gSill)

-- HEALTH — lane 2, the widest lane, 100 x 11. Trigger 1 is the progress source;
-- trigger 2 (Unit Characteristics) feeds the inCombat fade, exactly as the v6 bar did.
-- Conditions apply in order and a later match wins, so the alpha guard is LAST.
-- Triggers, conditions, colours and load gate are byte-identical to v13.
local health = reg(rail("Priest - Health", RAIL_W, LANE.health.h, COL.life,
  SILL_X, LANE.health.y))
health.triggers = F.triggers({ F.healthTrigger(nil), F.unitCharTrigger() })
health.subRegions[1] = pct("percenthealth", PCT_HP, COL.hpText)
-- the Desperate Prayer line, now a full-height waterline at x = 40 - 50 = -10 instead
-- of a 6.6px square at (23.206, -31.94) on an arc. Same sub.2 index, same colour.
health.subRegions[2] = waterline(40, 3, LANE.health.h, COL.mark)
addRuler(health, LANE.health.h)          -- sub.3-5, appended after the mark
health.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  -- red below 40%: the same number the Desperate Prayer prompt fires at, so rail and
  -- prompt read as one danger state — and now the rail's own waterline sits exactly
  -- where the colour changes. On a progresstexture the property is foregroundColor;
  -- `barColor` exists only on aurabar and would be dropped silently by Conditions.lua
  -- (unknown property = the change is skipped, with no warning).
  F.condition(1, "percenthealth", "<", "40", "foregroundColor", COL.danger),
  -- zero-total guard. Health's total is UnitHealthMax(unit) with no floor, and a
  -- progresstexture draws a FULL region at total == 0 (an aurabar drew an empty
  -- one), so an unstreamed max health would flash a complete green bar.
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

-- MANA — lane 3, directly under health, 100 x 11. Priest is mana in every spec and
-- every form, so this rail is blue with no recolouring condition — a druid's is what
-- needs one. The number is `%percentpower%%` and the rail is a percentage scale, so
-- for the first time since the bar era the number and the gauge agree.
local mana = reg(rail("Priest - Mana", RAIL_W, LANE.power.h, COL.mana,
  SILL_X, LANE.power.y))
mana.triggers = F.triggers({ F.powerTrigger(0), F.unitCharTrigger() })
mana.subRegions[1] = pct("percentpower", PCT_POWER, COL.mpText)
-- the Shadowfiend window, at x = 50 - 50 = 0. Same sub.2 index, same colour.
mana.subRegions[2] = waterline(50, 3, LANE.power.h, COL.mark)
addRuler(mana, LANE.power.h)             -- sub.3-5, appended after the mark
mana.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }

-- THREAT — lane 1, the thin rail along the top of the instrument, 100 x 4. It is the
-- one read-out here that nothing in the default UI shows, and a caster who cannot see
-- aggro coming dies.
--
-- SIZE, SHAPE AND POSITION ARE THE ONLY FIELDS THAT CHANGED. Same uid, same id, same
-- Threat Situation trigger (threatUnit = "target"), same escalation on
-- foregroundColor, same not-arena load gate, same threatvalue guard, same
-- green/orange/red. The trigger only produces a state for a hostile unit whose threat
-- table you are on, so the rail self-hides out of combat and while you have a friendly
-- targeted — no fade condition needed, and no separate track region needed either: a
-- progresstexture's own backgroundTexture is the track.
--
-- Green -> orange at 70% -> red on aggro; conditions run in order, most severe last.
local threat = reg(rail("Priest - Threat", RAIL_W, LANE.threat.h, COL.threat,
  SILL_X, LANE.threat.y))
threat.triggers = F.triggers({ threatTrigger("target", nil) })
threat.subRegions[1] = pct("threatpct", PCT_THREAT, COL.thText)
-- THE 70 NOTCH, and the reason the number above can be switched off: 70 is where the
-- rail turns orange and where the Fade prompt fires, so the one threat decision a
-- priest makes ("dump or keep casting") becomes "has the fill reached the notch".
threat.subRegions[2] = waterline(70, 2, LANE.threat.h, COL.notch)
threat.conditions = {
  -- a progresstexture, so the fill property is `foregroundColor` — it was `color`
  -- while threat was a v9/v10 texture rim and `barColor` in the bar era.
  -- Conditions.lua skips a change whose property is absent from the region's
  -- properties table WITHOUT any error, so the wrong name here would look right in
  -- the editor and do nothing in the game.
  F.condition(1, "threatpct", ">=", "70", "foregroundColor", COL.warn),
  F.condition(1, "aggro", "==", 1, "foregroundColor", COL.danger),
  -- MANDATORY, and carried across from v7 byte for byte (same trigger, variable,
  -- operator, value and property). threattotal = threatvalue * 100 / threatpct, so
  -- total is 0 whenever your threat is 0: the instant after a Fade, and before your
  -- first cast lands. A progresstexture draws a FULL region at total == 0
  -- (ProgressTexture.lua `local progress = 1`), so without this the rail would slam
  -- to a complete bar — "you are at the pull threshold" — exactly when you have no
  -- threat at all. Last, so it wins over both colour rules.
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
-- THE PLATE, and the three uid slots the target cluster used to occupy. Created after
-- every earlier W.uid() call, so all 40 v6 uids keep their positions in the seeded
-- stream, then re-parented into the Sill group.
--
-- THE FACE IS GONE, AND THAT IS THE HONEST COST OF v14. This is the uid that carried
-- the v7/v8 player portrait, the v9/v10 life-globe rim, the v11-v13 face — and now the
-- ground the whole instrument is drawn on. Re-typing model -> texture is free (the uid
-- travels, WA renames in place); losing a live 3D portrait of yourself is not free, it
-- is a taste call made on density grounds: 1,936 px2 that decided nothing, against an
-- 11pt number that is only legible because something dark is behind it.
--
-- BURNED SLOTS, AND WHY v14 DID NOT TAKE ONE. v12 deleted three regions, so three uids
-- from this seeded stream have no home, and v14 wanted a sixth region — the design's
-- alarm frame, a red Square_White_Border that alphaPulses at threatpct >= 80. Every
-- other pack in this repo recycles its "<Pack> - Threat Flash" for it; this pack has
-- never had one. Taking a burned slot instead would have been the worst possible fix:
-- WeakAuras matches by uid, so in every copy where the player never hand-deleted the
-- v12 orphans, the import would have "Updated" a deleted target ring into the alarm
-- frame. The slots stay burned; the alarm frame is not built; the threat rail still
-- goes orange at 70 and red on aggro, and the Fade prompt still fires at 70.
--   slot 1 (was Priest - Target Health)    burned
--   slot 2 (was Priest - Target Track)     burned
--   slot 3      Priest - Sill Plate        KEPT (was Priest - Player Portrait)
--   slot 4 (was Priest - Target Portrait)  burned
-- The three deleted ids are declared at the top of this file in the WA-REMOVED lines
-- tools/verify-packs.lua reads, and named in README "After updating" — WeakAuras never
-- deletes an aura an import does not mention, so the player deletes them by hand once.
-- =====================================================================

W.uid()  -- burned: the v7-v11 "Priest - Target Health" slot (target inner ring)
W.uid()  -- burned: the v7-v11 "Priest - Target Track" slot (target outer annulus)

-- THE GROUND. The plate takes the same triggers the face did, so the instrument lives
-- and fades as ONE object: the player Health + Unit Characteristics pair, hence the
-- same out-of-combat fade the rails have and the same zero-total guard. Both
-- conditions are byte-identical to v13's.
local sillPlate = reg(plate("Priest - Sill Plate", SILL_W, SILL_H,
  SILL_X, PLATE_Y, COL.plate))
sillPlate.triggers = F.triggers({ F.healthTrigger(nil), F.unitCharTrigger() })
sillPlate.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

W.uid()  -- burned: the v7-v11 "Priest - Target Portrait" slot (target face)

-- DRAW ORDER, in one place. FixGroupChildrenOrder walks controlledChildren and adds
-- +4 frame levels per child, so index 1 is the furthest BACK, and F.assemble's
-- depth-first push emits the transmit's `c` list in the same order. The plate must be
-- first or it paints over every rail; the rails follow it top lane to bottom lane.
-- (The design puts the alarm frame last here; this pack has none — see above.)
adopt(gSill, sillPlate)
adopt(gSill, threat)
adopt(gSill, health)
adopt(gSill, mana)

-- ===== icon polish: crop + 1px outline on every icon =====
for _, icon in ipairs(icons) do
  icon.zoom = 0.3
  table.insert(icon.subRegions, F.subborder())
end

-- ===== assemble (v2000 nested), encode, verify =====
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

-- ===== THE RAIL CANON. Every version from v11 to v13 carried a RING canon here —
-- orientation == "CLOCKWISE", width == height == <diameter>, foregroundTexture ==
-- Ring_20px, exact subregion counts — and it is the reason a geometry change in this
-- pack has never silently shipped wrong. v14 changes the geometry, so it REWRITES the
-- canon rather than deleting it. Everything below is checked against the DECODED
-- string, walking the real parent chain, never against the arithmetic that produced
-- it: a stale TOP_Y, or one hard-coded local y typed in by hand, is exactly the
-- mistake that produced seven differently-placed HUDs before. =====
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

local SILL_GROUP = "Priest - Player Sill"
local PLATE_ID   = "Priest - Sill Plate"

-- (0) THE GROUP ITSELF. The whole design is "the group carries the absolute position
-- and every leaf carries a lane offset", so this is the assertion the other seven
-- depend on. -110 is the only y in the free band under the character with margin both
-- above (paladin/hunter buff rows, y -80..-40) and below (every other pack's buff row,
-- y -176..-136); v13's group sat at -84 and its leaves at (-270, 124).
do
  local gx, gy = absolute(SILL_GROUP)
  assert(gx == SILL_X and gy == SILL_Y,
    ("%s resolves to (%d,%d); the Sill is anchored at (%d,%d)")
      :format(SILL_GROUP, gx, gy, SILL_X, SILL_Y))
  assert(nodes[SILL_GROUP].selfPoint == "CENTER"
     and nodes[SILL_GROUP].anchorPoint == "CENTER"
     and nodes[SILL_GROUP].anchorFrameType == "SCREEN",
    SILL_GROUP .. ": the group must stay CENTER/CENTER on SCREEN or the lane table lies")
end

-- (1) THE LANES. id, absolute (x,y), w, h, regionType, subregion count. The counts are
-- part of the canon because conditions address sub-regions positionally: a lane that
-- quietly grew or lost one is how a `sub.N` reference silently retargets.
local SILL = {
  { PLATE_ID,          SILL_X, SILL_Y + PLATE_Y,      SILL_W, SILL_H,        "texture",         0 },
  { "Priest - Threat", SILL_X, SILL_Y + LANE.threat.y, RAIL_W, LANE.threat.h, "progresstexture", 2 },
  { "Priest - Health", SILL_X, SILL_Y + LANE.health.y, RAIL_W, LANE.health.h, "progresstexture", 5 },
  { "Priest - Mana",   SILL_X, SILL_Y + LANE.power.y,  RAIL_W, LANE.power.h,  "progresstexture", 5 },
}
for _, want in ipairs(SILL) do
  local id, wx, wy, w, h, rt, subs = want[1], want[2], want[3], want[4], want[5], want[6], want[7]
  local node = assert(nodes[id], "no such aura: " .. id)
  local x, y = absolute(id)
  assert(x == wx and y == wy,
    ("%s lands at (%s,%s), canon is (%s,%s)"):format(id, tostring(x), tostring(y),
      tostring(wx), tostring(wy)))
  assert(node.width == w and node.height == h,
    ("%s is %sx%s, canon is %dx%d"):format(id, tostring(node.width), tostring(node.height), w, h))
  assert(node.regionType == rt,
    ("%s is a %s, canon is %s"):format(id, tostring(node.regionType), rt))
  assert(#(node.subRegions or {}) == subs,
    ("%s carries %d sub-regions, canon is %d — a sub.N condition may have retargeted")
      :format(id, #(node.subRegions or {}), subs))
  assert(node.selfPoint == "CENTER" and node.anchorPoint == "CENTER",
    id .. ": every lane anchors CENTER/CENTER or the lane table's y is meaningless")
end

-- (2) THE RAIL RECIPE, on every rail, from the shipped data. ONE PIXEL IS ONE PERCENT
-- is the whole design, so width == RAIL_W is asserted per rail and not inferred from
-- the table above; and HORIZONTAL_INVERSE is the single field this version cannot
-- prove from a previously shipped string, so it is the one most worth pinning here.
for _, want in ipairs(SILL) do
  local node = nodes[want[1]]
  if node.regionType == "progresstexture" then
    local id = want[1]
    assert(node.orientation == "HORIZONTAL_INVERSE",
      ("%s fills %q; a rail fills left to right, which on a progresstexture is %q")
        :format(id, tostring(node.orientation), "HORIZONTAL_INVERSE"))
    assert(node.width == RAIL_W,
      ("%s is %s long; one pixel is one percent, so a rail is exactly %d")
        :format(id, tostring(node.width), RAIL_W))
    assert(node.height ~= node.width, id .. ": a rail is not square — that was the ring era")
    assert(node.foregroundTexture == RAIL_TEX and node.backgroundTexture == RAIL_TEX,
      id .. ": a rail is drawn with Square_White, not an annulus")
    assert(node.sameTexture == true, id .. ": foreground and background must share the art")
    assert(node.backgroundOffset == 0, id .. ": a non-zero backgroundOffset haloes the track")
    assert(node.crop_x == 0.41 and node.crop_y == 0.41, id .. ": crop must stay 0.41")
    assert(node.smoothProgress == true, id .. ": the fill must interpolate")
    assert(node.blendMode == "BLEND", id .. ": a rail blends, it does not add")
    assert(node.progressSource and node.progressSource[1] == -1,
      id .. ": progressSource must be Automatic, i.e. trigger 1's value/total")
    assert(node.compress == false and node.slanted == false,
      id .. ": compress/slant are LIVE on the linear path and must stay off")
    local track = node.backgroundColor
    assert(track[1] == COL.track[1] and track[2] == COL.track[2]
       and track[3] == COL.track[3] and track[4] == COL.track[4],
      id .. ": the unfilled part of a rail is the shared dark track")
  end
end
do  -- and the plate
  local p = nodes[PLATE_ID]
  assert(p.texture == PLATE_TEX, PLATE_ID .. ": the plate needs the BORDERED square")
  assert(p.blendMode == "BLEND", PLATE_ID .. ": an ADD plate cannot darken anything")
  for i, v in ipairs(COL.plate) do
    assert(p.color[i] == v, PLATE_ID .. ": the plate must ship its explicit dark colour")
  end
end

-- (3) THE STACK. Four regions of four different heights are an INSTRUMENT only if they
-- share one x centre-line, never overlap each other, and all sit inside the plate.
-- "each is at x = 0" and "no two lanes collide" are different claims when one of the
-- lane offsets is typed wrong.
do
  local plateTop, plateBottom
  local lanes = {}
  for _, want in ipairs(SILL) do
    local node, id = nodes[want[1]], want[1]
    local _, y = absolute(id)
    local top_, bottom = y + node.height / 2, y - node.height / 2
    local x = select(1, absolute(id))
    assert(x == SILL_X, ("%s sits at x=%s, every lane shares x=%d"):format(id, tostring(x), SILL_X))
    if id == PLATE_ID then plateTop, plateBottom = top_, bottom
    else lanes[#lanes + 1] = { id = id, top = top_, bottom = bottom, halfW = node.width / 2 } end
  end
  table.sort(lanes, function(a, b) return a.top > b.top end)
  for k = 2, #lanes do
    assert(lanes[k].top <= lanes[k - 1].bottom - 1e-9,
      ("%s (%.1f..%.1f) overlaps %s (%.1f..%.1f)")
        :format(lanes[k].id, lanes[k].top, lanes[k].bottom,
                lanes[k - 1].id, lanes[k - 1].top, lanes[k - 1].bottom))
  end
  for _, lane in ipairs(lanes) do
    assert(lane.top <= plateTop and lane.bottom >= plateBottom,
      ("%s (%.1f..%.1f) hangs off the plate (%.1f..%.1f)")
        :format(lane.id, lane.top, lane.bottom, plateTop, plateBottom))
    assert(lane.halfW <= SILL_W / 2,
      lane.id .. " is wider than the plate it is drawn on")
  end
  print(("sill: plate %dx%d at abs (%d,%.1f), spanning y %.1f..%.1f | %d lanes")
    :format(SILL_W, SILL_H, SILL_X, SILL_Y + PLATE_Y, plateTop, plateBottom, #lanes))
end

-- (4) THE NUMBERS. text_* is the live spelling (see pct()'s header), so both keys are
-- checked: an edit that moved only the dead anchorXOffset would ship a string that
-- looks right in a diff and does not move a pixel in game. Threat is switched OFF and
-- re-aimed, and BOTH halves are asserted as loudly as the other two labels: deleting it
-- would have shifted the 70 notch from sub.2 to sub.1, and leaving it at the ring era's
-- y = +58 would have left a live offset pointing 55px off the top of the instrument.
for _, want in ipairs({
  --  id                   sub   x    y  size  visible  what
  { "Priest - Health", 1,  32,  0, 11, true,  "inside its own rail, at the right end" },
  { "Priest - Mana",   1,  32,  0, 11, true,  "inside its own rail, at the right end" },
  { "Priest - Threat", 1,   0,  0, 10, false, "switched off, but still aimed at its rail" },
}) do
  local id, index, x, y, size, visible, where =
    want[1], want[2], want[3], want[4], want[5], want[6], want[7]
  local sub = assert(nodes[id].subRegions[index], id .. ": no label at sub." .. index)
  assert(sub.type == "subtext", id .. ": sub." .. index .. " is not the percentage")
  assert(sub.text_anchorXOffset == x and sub.anchorXOffset == x,
    ("%s label is at text_x=%s / x=%s, v14 puts it at %d (%s)")
      :format(id, tostring(sub.text_anchorXOffset), tostring(sub.anchorXOffset), x, where))
  assert(sub.text_anchorYOffset == y and sub.anchorYOffset == y,
    ("%s label is at text_y=%s / y=%s, v14 puts it at %d")
      :format(id, tostring(sub.text_anchorYOffset), tostring(sub.anchorYOffset), y))
  assert(sub.text_fontSize == size,
    ("%s label is %spt, v14 ships %dpt"):format(id, tostring(sub.text_fontSize), size))
  assert((sub.text_visible ~= false) == visible,
    ("%s label visibility is %s, v14 ships %s"):format(id, tostring(sub.text_visible), tostring(visible)))
  -- Unchanged by this pass, asserted so a future "readability" edit cannot quietly
  -- trade the outline for a size bump: the outline plus the plate is what holds an
  -- 11pt number up against a bright game background.
  assert(sub.text_fontType == "OUTLINE", id .. ": the label lost its outline")
  assert(sub.text_anchorPoint == "CENTER", id .. ": the label is no longer centre-anchored")
end
-- and the two live numbers must actually fit inside the rail they print on: three
-- digits at 11pt is ~21px, so the right edge of "100%" lands at x + 10.5.
for _, id in ipairs({ "Priest - Health", "Priest - Mana" }) do
  local sub = nodes[id].subRegions[1]
  local halfWidth = sub.text_fontSize * 0.55 * 2   -- "100%" ~= 4 glyphs at 11pt
  assert(sub.text_anchorXOffset + halfWidth <= RAIL_W / 2,
    id .. ": a three-digit percentage would run off the end of its own rail")
end

-- A SWITCHED-OFF LABEL IS STILL A PROMISE. Both READMEs tell the player the threat
-- number is one /wa checkbox away, so the offsets it would come back AT have to land on
-- the instrument — an invisible region's geometry is unfalsifiable by looking at the
-- HUD, which is exactly how the ring era's y = +58 survived the rails landing 100px
-- shorter. At +58 the anchor resolved to absolute (0, -36.5): 55px above the plate,
-- on open terrain, i.e. the failure this whole version is about. So every label's
-- anchor is proved to resolve INSIDE the plate, whether it is drawn or not, and the
-- offsets are walked off the decoded parent chain rather than off the constants that
-- produced them.
do
  local px, py = absolute(PLATE_ID)
  local plate  = nodes[PLATE_ID]
  local left, right  = px - plate.width / 2,  px + plate.width / 2
  local bottom, top  = py - plate.height / 2, py + plate.height / 2
  for _, id in ipairs({ "Priest - Health", "Priest - Mana", "Priest - Threat" }) do
    local sub = nodes[id].subRegions[1]
    local rx, ry = absolute(id)
    local ax, ay = rx + sub.text_anchorXOffset, ry + sub.text_anchorYOffset
    assert(ax >= left and ax <= right and ay <= top and ay >= bottom,
      ("%s label anchors at abs (%.1f,%.1f), which is off the plate (x %.1f..%.1f, y %.1f..%.1f)")
        :format(id, ax, ay, left, right, bottom, top))
  end
  print(("labels: all 3 anchors inside the plate (x %.1f..%.1f, y %.1f..%.1f), hidden ones too")
    :format(left, right, bottom, top))
end

-- (5) DRAW ORDER, the half that source review keeps missing. FixGroupChildrenOrder
-- assigns frame levels in controlledChildren order (+4 per child), so index 1 is the
-- BACK. The plate must be index 1 or it paints over every rail and every number.
-- (The design's sixth region, the alarm frame, would be last; this pack has none.)
do
  local order = nodes[SILL_GROUP].controlledChildren
  local expect = { PLATE_ID, "Priest - Threat", "Priest - Health", "Priest - Mana" }
  assert(#order == #expect,
    ("%s holds %d children, the draw-order proof knows %d"):format(SILL_GROUP, #order, #expect))
  for i, id in ipairs(expect) do
    assert(order[i] == id,
      ("%s child %d is %q, v14 draws %q there"):format(SILL_GROUP, i, order[i], id))
  end
  assert(nodes[order[1]].regionType == "texture",
    "the FIRST child of the Sill must be the plate, or the rails draw behind it")
  for i = 2, #order do
    assert(nodes[order[i]].regionType == "progresstexture",
      order[i] .. " is not a rail, so it must not sit above the plate")
  end
  -- The transmit's own child list has to agree: F.assemble pushes depth-first, and the
  -- in-game order is read off THAT list as much as off controlledChildren, so a
  -- reorder that touched only one of the two would be half-applied.
  local seen = {}
  for i, ch in ipairs(decoded.c) do
    if ch.parent == SILL_GROUP then seen[#seen + 1] = { i = i, id = ch.id } end
  end
  assert(#seen == #expect, "c-list holds a different number of Sill regions")
  for k, entry in ipairs(seen) do
    assert(entry.id == expect[k],
      ("c-list position %d is %q, controlledChildren says %q — the two disagree")
        :format(entry.i, entry.id, expect[k]))
  end
  print("draw order: " .. table.concat(order, " -> "))
end

-- (6) EVERY BREAKPOINT, recovered the other way round: the threshold is read back OUT
-- of the committed xOffset through the inverse of railX, so the proof does not depend
-- on the arithmetic that produced it. Each one must also be FULL HEIGHT — a waterline
-- that is shorter than its rail is the 6.6px pip this version replaced.
for _, want in ipairs({
  --  id                  sub  value  rail height       what
  { "Priest - Threat", 2, 70, LANE.threat.h, "the pull-threshold notch" },
  { "Priest - Health", 2, 40, LANE.health.h, "the Desperate Prayer line" },
  { "Priest - Mana",   2, 50, LANE.power.h,  "the Shadowfiend window" },
  { "Priest - Health", 3, 25, LANE.health.h, "ruler" },
  { "Priest - Health", 4, 50, LANE.health.h, "ruler" },
  { "Priest - Health", 5, 75, LANE.health.h, "ruler" },
  { "Priest - Mana",   3, 25, LANE.power.h,  "ruler" },
  { "Priest - Mana",   4, 50, LANE.power.h,  "ruler" },
  { "Priest - Mana",   5, 75, LANE.power.h,  "ruler" },
}) do
  local id, index, value, h, what = want[1], want[2], want[3], want[4], want[5]
  local sub = assert(nodes[id].subRegions[index], id .. ": no mark at sub." .. index)
  assert(sub.type == "subtexture", id .. ": sub." .. index .. " is not a mark")
  local recovered = (sub.xOffset / RAIL_W + 0.5) * 100
  assert(math.abs(recovered - value) < 1e-9,
    ("%s sub.%d sits at x=%s, i.e. %.3f%% — %s is at %d%%")
      :format(id, index, tostring(sub.xOffset), recovered, what, value))
  assert(sub.yOffset == 0, id .. " sub." .. index .. ": a waterline is centred on its rail")
  assert(sub.height == h,
    ("%s sub.%d is %s tall, its rail is %d — a waterline cuts the whole rail")
      :format(id, index, tostring(sub.height), h))
  assert(sub.textureTexture == F.TEX_SQUARE and sub.anchor_mode == "point",
    id .. " sub." .. index .. ": marks stay point-anchored white squares")
end

-- THE TARGET CLUSTER IS GONE — AND STAYS GONE, checked against the shipped data rather
-- than against the source that built it: an id left behind in a table somewhere would
-- otherwise ship a lone target ring with no cluster around it. EVER_REMOVED, so this
-- keeps biting after v12's removal licence has expired.
for _, id in ipairs(EVER_REMOVED) do
  assert(not nodes[id], id .. " was removed in an earlier version but is back in the string")
end

-- ===== (7) THE RECTANGLE SCAN. v13 proved ONE clearance (the Alerts column) because
-- the cluster only had one neighbour worth worrying about, out at x = -270. The Sill
-- sits in the middle of the screen, so "does it clear the alerts column" is no longer
-- the question — "does it clear EVERYTHING" is. This walks every region in the decoded
-- pack, projects each dynamic group DYN_DEPTH children deep (measuring a dynamic group
-- at rest is what let an earlier pass ship a layout that only cleared while a single
-- prompt was showing), and requires ZERO overlaps against the Sill's own footprint.
-- Growth rules, from F.dynGroup's contract: UP/BOTTOM stacks upward from the anchor,
-- RIGHT/LEFT runs rightward from it, HORIZONTAL/CENTER centres on it.
-- DEPTH IS NOT CHILD COUNT, and that distinction is load-bearing rather than pedantic:
-- the projection multiplies by DYN_DEPTH whatever the group's #controlledChildren is,
-- because an aura2 trigger carrying showClones renders one row PER MATCH. Priest ships
-- three of those (Holy Procs, UA on Ally, My CC Out), and Priest - Procs is the one that
-- matters here — a single 32px child whose trigger watches two spell ids, so it can draw
-- two icons at once out of "one" child. Counting children would have projected it 1 deep
-- and measured a group that is never that small in a fight. =====
do
  local function rectOf(id)
    local node = nodes[id]
    local x, y = absolute(id)
    return { id = id,
      x1 = x - node.width / 2, x2 = x + node.width / 2,
      y1 = y - node.height / 2, y2 = y + node.height / 2 }
  end

  -- the Sill's own footprint: the plate, which encloses every lane (proved in (3))
  local sill = rectOf(PLATE_ID)
  local mine = {}
  for _, want in ipairs(SILL) do mine[want[1]] = true end

  -- children by parent, so a dynamic group can be measured from its widest/tallest kid
  local kids = {}
  for _, ch in ipairs(decoded.c) do
    kids[ch.parent] = kids[ch.parent] or {}
    table.insert(kids[ch.parent], ch)
  end

  local boxes = {}
  local function addRect(r) boxes[#boxes + 1] = r end
  for _, ch in ipairs(decoded.c) do
    if mine[ch.id] then                                    -- the Sill itself
    elseif ch.regionType == "dynamicgroup" then
      local maxW, maxH, n = 0, 0, 0
      for _, kid in ipairs(kids[ch.id] or {}) do
        maxW = math.max(maxW, kid.width or 0)
        maxH = math.max(maxH, kid.height or 0)
        n = n + 1
      end
      if n > 0 then
        local gx, gy = absolute(ch.id)
        local space = ch.space or 0
        local d = DYN_DEPTH
        local runW = d * maxW + (d - 1) * space
        local runH = d * maxH + (d - 1) * space
        local r
        if ch.grow == "UP" then
          r = { x1 = gx - maxW / 2, x2 = gx + maxW / 2, y1 = gy, y2 = gy + runH }
        elseif ch.grow == "DOWN" then
          r = { x1 = gx - maxW / 2, x2 = gx + maxW / 2, y1 = gy - runH, y2 = gy }
        elseif ch.grow == "RIGHT" then
          r = { x1 = gx, x2 = gx + runW, y1 = gy - maxH / 2, y2 = gy + maxH / 2 }
        elseif ch.grow == "LEFT" then
          r = { x1 = gx - runW, x2 = gx, y1 = gy - maxH / 2, y2 = gy + maxH / 2 }
        elseif ch.grow == "HORIZONTAL" then
          r = { x1 = gx - runW / 2, x2 = gx + runW / 2, y1 = gy - maxH / 2, y2 = gy + maxH / 2 }
        elseif ch.grow == "VERTICAL" then
          r = { x1 = gx - maxW / 2, x2 = gx + maxW / 2, y1 = gy - runH / 2, y2 = gy + runH / 2 }
        else
          error(("%s grows %q, which the scan cannot project")
            :format(ch.id, tostring(ch.grow)))
        end
        r.id = ("%s (%d deep)"):format(ch.id, DYN_DEPTH)
        addRect(r)
      end
    elseif ch.regionType == "group" then                   -- static: measure the leaves
    elseif nodes[ch.parent] and nodes[ch.parent].regionType == "dynamicgroup" then
    else
      addRect(rectOf(ch.id))
    end
  end

  local hits = {}
  for _, r in ipairs(boxes) do
    if r.x1 < sill.x2 and r.x2 > sill.x1 and r.y1 < sill.y2 and r.y2 > sill.y1 then
      hits[#hits + 1] = ("%s x %.1f..%.1f y %.1f..%.1f"):format(r.id, r.x1, r.x2, r.y1, r.y2)
    end
  end
  assert(#hits == 0, ("the Sill (x %.1f..%.1f y %.1f..%.1f) overlaps %d region(s): %s")
    :format(sill.x1, sill.x2, sill.y1, sill.y2, #hits, table.concat(hits, "; ")))

  -- and report the two margins that are actually tight, so a future row move is seen
  local above, below = math.huge, math.huge
  for _, r in ipairs(boxes) do
    if r.x1 < sill.x2 and r.x2 > sill.x1 then
      if r.y1 >= sill.y2 then above = math.min(above, r.y1 - sill.y2) end
      if r.y2 <= sill.y1 then below = math.min(below, sill.y1 - r.y2) end
    end
  end
  local function gap(v) return v == math.huge and "nothing" or ("%.1fpx"):format(v) end
  print(("rect scan: %d boxes (dyn groups %d deep), 0 overlaps | sill x %.1f..%.1f y %.1f..%.1f"
    .. " | %s above, %s below")
    :format(#boxes, DYN_DEPTH, sill.x1, sill.x2, sill.y1, sill.y2, gap(above), gap(below)))
end
-- uid continuity against the previous on-disk version, measured BEFORE the file is
-- overwritten, so every future re-run is checked against the string that shipped
local txtPath = dir .. "/all-specs.txt"
-- v14 passes NO licence (REMOVED is empty, so nil), which restores the strict default:
-- not one uid may disappear. Reordering the cluster's children is a re-parenting change
-- and nothing else — it consumes no uid() call and moves none — so a reorder that
-- somehow cost a uid fails right here instead of shipping as a duplicate import.
-- `changed` (an id that kept its name and swapped uid) is never forgivable and is
-- asserted independently inside the helper.
local cont = W.uidContinuity(encoded, txtPath)
W.assertUidContinuity(cont, "priest", #REMOVED > 0 and REMOVED or nil)

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
