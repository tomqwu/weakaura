-- generate.lua — "Paladin TBC - All Specs" (v15)
-- Holy / Protection / Retribution HUD in one import; spec pieces auto-load via
-- Spell Known gates. Built entirely with the wa_factory builders (zero custom code)
-- except the ring and portrait region tables, which wa_factory has no builder for.
--
-- v15 — THE HEALTH NUMBER MOVES INTO THE MIDDLE OF THE CLUSTER. No aura is added, removed,
-- retriggered, regated, recoloured, resized or repositioned. This version changes exactly
-- three things: two sub-text offsets, two sub-text font sizes, and the ORDER the cluster's
-- children are drawn in. All 45 auras keep their ids and their uids (changed = 0,
-- missing = 0).
--
--   PCT_HP_Y      -54 ->   0   health %, dead centre, over your portrait   13pt -> 16pt
--   PCT_POWER_Y   -70 -> -54   mana %, into the slot health just vacated   10pt -> 12pt
--   PCT_THREAT_Y   58 ->  58   threat %, unchanged, above the 100px arc    10pt (unchanged)
--
--   * THE COMPLAINT THIS FIXES. v13/v14 hung both numbers BELOW the rings — health 54px down
--     at 13pt, mana 70px down at 10pt — on the reasoning that the middle of the cluster is a
--     face and a `model` region can never carry a text sub-region. That reasoning is still
--     true about the MODEL, and it was the wrong conclusion about the CLUSTER: the numbers
--     ended up as two small detached glyphs floating on open screen, with nothing behind them
--     but whatever the game world happened to be showing. On a snow field, a lit floor or a
--     Netherstorm skybox they simply vanish. The health percentage is the single most-read
--     number in the pack, so it goes where the eye already is — the centre.
--   * A MODEL STILL CANNOT CARRY TEXT, AND IT DOES NOT HAVE TO. The health % is a sub-text of
--     the HEALTH RING, which is a progresstexture and always could carry one. anchorYOffset 0
--     puts it at the ring's own centre, which is the cluster's centre, which is where the
--     portrait is. The text belongs to the ring; it merely LANDS on the face.
--   * WHY THE OFFSET ALONE DOES NOTHING — THE DRAW ORDER IS HALF THE FIX. Children of a
--     WeakAuras group draw in controlledChildren order, later on top. Through v14 the face
--     was adopted LAST, deliberately ("so nothing draws over it"), which also means the face
--     draws over anything a ring's sub-text puts in the middle. Move the health number to
--     y = 0 without touching the order and the 44px model covers it: the build changes, the
--     screen does not. So the portrait becomes the FIRST child of the cluster:
--         v14  { Threat, Health, Mana, Threat Flash, Player Portrait }
--         v15  { Player Portrait, Threat, Health, Mana, Threat Flash }
--   * WHY THAT IS SAFE, FROM THE RADII AND NOT FROM TASTE. Ring_20px is a TRUE ANNULUS, so a
--     ring drawn above the portrait covers only its own band. At this pack's diameters the
--     bands are threat 42.19..50.00, health 35.44..42.00, mana 26.16..31.00 and the portrait
--     is 0..22 — no band reaches the face at all. (The stroke is 20/256 of the drawn size,
--     hence 3.9px at 100 and 3.3px at 84.) The only ring-owned pixels that now land inside
--     22px of centre are the sub-texts, which is the entire point. The Threat Flash is the
--     same annulus at the same 100px radius, so it also cannot touch the face — its old
--     comment already said so "whatever order it is adopted in", and v15 is the version that
--     takes it up on that.
--   * REORDERING CONSUMES NO UID. adopt() only writes `parent` and appends to
--     controlledChildren; every W.uid() call site and its ORDER is untouched, so the seeded
--     stream is identical and all 45 uids are byte-for-byte what v14 shipped. F.assemble
--     walks controlledChildren depth-first, so the flat `c` list reorders WITH the group and
--     stays consistent — W.verify enforces that pairing, which is why a half-done reorder
--     fails the build instead of shipping.
--   * THE MANA NUMBER TAKES THE FREED SLOT rather than staying at -70. Health vacates -54,
--     which is the slot just under the 84px ring; leaving mana at -70 would strand it 70px
--     down with nothing above it. 12pt (up from 10) because it is now the only number under
--     the cluster and no longer has to be the smaller of a stacked pair. It keeps its blue
--     tint, which is what identifies it now that it does not sit beneath a white sibling.
--   * NOTHING ELSE. Same triggers, load gates, conditions, colours, diameters, cluster
--     position, Swing Timer, buff row, alert column, cooldown row and PvP layer as v14. The
--     Swing Timer clearance is unchanged and unaffected: the mana number rising from y = -30
--     to y = -14 moves it AWAY from the runway at y = -71.5.
--
-- v14 — ONE CLUSTER. THE TARGET CLUSTER IS DELETED AND THREAT COMES HOME. Three auras are
-- REMOVED — the first deletion this pack has ever shipped — the threat ring moves onto the
-- PLAYER cluster as its new outermost arc, and nothing else in the pack is touched. 48 auras
-- before, 45 after. Every trigger, gate, condition and colour outside the clusters (buffs,
-- alerts, cooldown row, procs, the whole PvP layer) is byte-identical to v13.
--
--   PLAYER cluster (-270, 40)   threat 100 (outermost) / health 84 / mana 62,
--                               centre = your live 44px portrait
--
--   * WHY THE TARGET CLUSTER GOES. Its health arc and its face were a second copy of data the
--     default UI already draws twice — the target frame and the nameplate — for the entire
--     game. A HUD element earns its place by changing the next button press, and a target
--     health percentage parked at (+270, 110) never did: it duplicated the very frame the
--     player looked at to select the target. Removed, not shrunk and not moved: the group
--     "Paladin - Target Rings", the ring "Paladin - Target Health" and the model
--     "Paladin - Target Portrait" are gone.
--   * WHY THREAT DOES NOT GO WITH IT. Threat is the ONE thing that cluster carried which
--     nothing else on screen shows, and a dps who pulls aggro dies — losing it would be a real
--     regression. It becomes the OUTERMOST ring of the PLAYER cluster, which is also the more
--     honest reading: it is YOUR threat, and the target merely names the table it is measured
--     against.
--       THREAT_RING 100  (outermost, the same Ring_20px annulus)
--       OUTER        84  (health, unchanged)
--       INNER        62  (mana, unchanged)
--       PORTRAIT     44  (unchanged)
--       cluster at ABSOLUTE (-270, 40), unchanged to the pixel
--       threat percentage: 10pt, CENTER, anchorYOffset +58 (above the new outer ring)
--     The >=80% flash halo resizes 84 -> 100 so it pulses ON the threat ring instead of
--     orbiting the radius of a ring that is no longer the outermost one. It stays Ret-gated.
--   * THREAT KEEPS EVERYTHING ELSE. The Threat Situation trigger, its party/raid gate, its
--     never-in-an-arena gate, the 70% orange and aggro red on `foregroundColor` (barColor is
--     aurabar-only and a SILENT no-op on a progresstexture), and the mandatory
--     `threatvalue <= 0 -> alpha 0` guard without which a progresstexture with a zero total
--     draws FULL and reports a complete circle of aggro at the exact moment you have none.
--     Because of those two load gates the common solo case is still two rings and a face; the
--     third arc appears only when threat is a real relationship.
--   * THE TRIGGER'S UNIT ARG IS `threatUnit`, NOT `unit`. The Threat Situation prototype
--     renamed that argument to plain `unit` at internalVersion 51, and Modernize migrates
--     < 51 data forward — so internalVersion-45 data must emit the OLD name and let the
--     migration rename it. v9-v13 additionally emitted `unit`, a post-51 field on pre-51
--     data; v14 drops it. The era-correct `use_threatUnit` / `threatUnit` pair, which was
--     always there, is what does the work, and the prototype's own
--     `trigger.unit = trigger.unit or "target"` init covers the pre-migration read.
--   * ORPHANS ARE EXPECTED HERE, AND THAT IS THE POINT. Three uids now have no home. Nothing
--     is invented to absorb them — a filler region built to keep a uid alive is exactly how a
--     HUD accumulates junk. The uid() CALL ORDER is preserved exactly: the three freed slots
--     are still DRAWN from the seeded stream, in place, and thrown away (see "retired uid
--     slots" in the assembly section), so not one surviving aura's uid shifts by a single
--     call. All 44 survivors are byte-for-byte identical to v13 (changed = 0). WeakAuras
--     never deletes an aura an import does not mention, so after updating the player must
--     delete the leftover "Paladin - Target Rings" group by hand — the README says so, by
--     name, for exactly that reason.
--   * NOTHING ELSE MOVED. The Swing Timer, the buff row, the Alerts column, the cooldown row
--     and the PvP column are all untouched, and the widened cluster still clears them: the
--     100px ring spans x -320..-220 against the Alerts column's -170..-130, which is a
--     vertical-growth dynamic group, so the 50px gap holds at ANY stack depth.
--
-- The three auras v14 removed, declared for the verifier (see tools/verify-packs.lua). Only
-- entries tagged with the version this script currently ships are honoured, so at v15 these
-- lines are EXPIRED — inert history, not a standing licence. That is the design: the
-- allowance dies at the next version bump instead of quietly covering a future deletion.
-- Kept because the README still tells v13-and-earlier upgraders to delete these by hand:
-- WA-REMOVED (v14): Paladin - Target Rings
-- WA-REMOVED (v14): Paladin - Target Health
-- WA-REMOVED (v14): Paladin - Target Portrait
--
-- v13 — THE RINGS AND THE FACES ARE BACK. The Diablo globes of v11/v12 are gone. Each unit
-- is read as TWO CONCENTRIC ARCS AROUND A LIVE 3D PORTRAIT again, which is what makes the
-- player's cluster and the target's cluster read as a matched pair instead of as three
-- unrelated jars of coloured liquid. Nothing outside the two clusters changed: not one
-- trigger, load gate, condition, spell id, size or position anywhere else in the pack, and
-- no aura was added or removed. 48 auras before, 48 after, ZERO new W.uid() calls.
--
--   PLAYER cluster (-270,  40)   outer = health, inner = mana,          centre = player face
--   TARGET cluster (+270, 110)   outer = THREAT, inner = target health, centre = target face
--
-- THE CANONICAL NUMBERS ARE SHARED BY ALL SEVEN PACKS (constants block below): OUTER 84,
-- INNER 62, PORTRAIT 44, CLUSTER_X 270, CLUSTER_Y 40, TARGET_Y 110. They are not paladin
-- tuning knobs — seven packs each inventing their own diameters is exactly the drift v10
-- was created to end, and five later passes drifted again by being handed intent instead of
-- dimensions. 44/84 is the portrait-to-outer ratio the face was approved at; scale one of
-- those two numbers without the other and the cluster stops being the reference design.
--
-- x = +-270 IS NOT A LOOK, IT IS CLEARANCE. The Alerts column occupies x -170..-130 and the
-- PvP column x +132..+168, and BOTH are dynamic groups that grow vertically: at +-190 the
-- alert stack climbs into the player cluster from the second simultaneous prompt onward.
-- +-270 is the tightest symmetric pair of positions that is clear at any stack depth. The
-- absolute positions are carried ONCE, by the two cluster groups, with every region inside
-- them at (0, 0) — proof by parent-chain walk in the assembly section.
--
-- WHAT SWITCHING BACK CHANGES IN THE REGION TABLE. Same `progresstexture` region, one field:
--   orientation = "CLOCKWISE"   -- the radial fill path; VERTICAL was the globes' linear one
-- That single key decides which of the neighbouring fields are live. startAngle / endAngle
-- were dead schema on the linear path and MATTER again (0 / 360 = a full circle; WA
-- normalises 0/360 -> 0/0 and then corrects endAngle back up by 360, so the full ring is a
-- handled case and not a degenerate one). compress / slanted / slant / slantFirst /
-- slantMode were live for the waterline and are INERT again. crop_x / crop_y stay 0.41 —
-- on the circular path that is the IDENTITY value, cancelling the sqrt(2) expansion the
-- fill applies so rotated quadrants never run off the texture; 0 would blow the ring up
-- 1.41x and clip it. backgroundOffset stays 0 so the unfilled arc is the same annulus as
-- the filled one rather than a halo around it.
--
-- THE ART IS Ring_20px.tga, a true annulus that ships inside WeakAuras (Private
-- .texture_types, "Shapes"). Circle_Smooth is a solid DISC and fills as a pie wedge. The
-- number in the file name is the stroke weight in the 256x256 source, so at 84px this draws
-- a 6.6px band; Ring_10px at this diameter is the 3px hairline v9 shipped and everybody
-- complained about.
--
-- THE PORTRAITS ARE MODEL REGIONS, AND THE UNIT FIELD IS A TRAP. modelIsUnit = true plus
-- portraitZoom = true is Blizzard's head framing of whoever the unit is, so the target side
-- renders NPCs and mobs without this pack ever knowing their class. Current WeakAuras reads
-- the unit from `model_fileId`; WA 3.5.0 read `model_path`, and the migration that bridges
-- the two (Modernize < 72) is guarded by WeakAuras.IsClassicEra(), which is a DISTINCT
-- predicate from IsTBC() — so on a 2.5.x client that migration DOES NOT RUN and emitting
-- only model_path is a silent no-op that ships two blank squares. BOTH are emitted.
--
-- WHERE THE PERCENTAGES WENT. Back OUTSIDE the rings, because a `model` region can never
-- carry a text sub-region (SubText's supports() gate lists texture / progresstexture / icon
-- / aurabar / empty — not model) and the centre of each cluster is a face again. Health 13pt
-- at yOffset -54 (just under the outer ring), power 10pt at -70 under it, threat 10pt at +54
-- above the ring it belongs to. Each number still rides on its own region, so it appears and
-- vanishes with that region: no target, no numbers; no threat table, no threat percentage.
--
-- THREAT IS THE TARGET'S OUTER RING, not a third ring on the player and not a fourth ring
-- here. A target POWER ring is deliberately NOT built (see the note at the target cluster) —
-- two rings and a face is the design; a third ring is what made v9 look busy and uneven.
-- "Paladin - Threat" keeps its id, its uid, its triggers, its thresholds and both load
-- gates, and goes back to being a progresstexture. ITS CONDITION PROPERTY MOVED WITH IT:
-- v11/v12 made threat a plain `texture` whose colour property is `color`; a progresstexture
-- has no `color` and Conditions.lua SKIPS a condition whose property the region does not
-- define — no error, no editor warning, the whole escalation simply never fires. All three
-- threat escalations are renamed back to `foregroundColor`. `barColor` would be the same
-- silent no-op one region type further along (it is aurabar-only, which is why the Swing
-- Timer below correctly still uses it).
--
-- NOTHING IS ORPHANED. Every uid is recycled in place, in the same order:
--   Paladin - Health          globe  -> OUTER player ring   (id and uid unchanged)
--   Paladin - Mana            globe  -> INNER player ring   (id and uid unchanged)
--   Paladin - Target Health   globe  -> INNER target ring   (id and uid unchanged)
--   Paladin - Threat          rim    -> OUTER target ring   (id and uid unchanged)
--   Paladin - Threat Flash    rim    -> a pulse on the outer target ring (id/uid unchanged)
--   Paladin - Life Globe Rim         -> Paladin - Player Portrait   (renamed, SAME uid)
--   Paladin - Mana Globe Rim         -> Paladin - Target Portrait   (renamed, SAME uid)
--   Paladin - Player Globes  group   -> Paladin - Player Rings      (renamed, SAME uid)
--   Paladin - Target Globe   group   -> Paladin - Target Rings      (renamed, SAME uid)
-- The last two portrait ids are the ones v11 recycled INTO the glass rims, so they are
-- simply going home. WeakAuras matches auras across imports by uid, never by id, so a rename
-- is applied in place: the re-import is an Update with zero leftovers, and uidContinuity
-- reports changed = 0 with nothing missing.
--
-- WHAT CARRIED OVER FROM THE GLOBES UNCHANGED: every danger-colour escalation (life < 30%,
-- mana < 20%, target < 20%, threat >= 70%, aggro), all three zero-data guards, the
-- out-of-combat fade on the player's two rings, the >=80% Retribution threat pulse, and
-- every load gate. What did NOT come along is the v12 specular highlight sub-region: it was
-- a glass effect for a filled vessel and does nothing on an annulus, so both player rings
-- and the target ring lose it. It was the LAST sub-region on each, and this pack has no
-- sub.N condition anywhere near a ring, so dropping it cannot re-point anything.
--
-- NO RESOURCE BREAKPOINT MARKS TO RE-DERIVE, for the fourth version running. Rogue / druid /
-- mage / hunter place "spend at N" ticks by trigonometry off the ring RADIUS and had to
-- convert their globe-era waterlines back into circumference marks; this pack has none and
-- never did. Its one resource threshold ("mana under 20%") is a COLOUR condition, carried
-- across verbatim since v8. The only thing anchored to a radius here is the percentages.
--
-- THE SWING TIMER DID NOT MOVE, AND IT CLEARS THE CLUSTER. It stays at absolute (-150, -76),
-- 140x9, so it spans x -220..-80 and y -80.5..-71.5. The player cluster is an 84px ring at
-- (-270, 40), i.e. x -312..-228 and y -2..+82, with its mana percentage bottoming out around
-- y = -40 (its 10pt baseline sits at 40 - 70 = -30). The bar's left end is 8px clear of the
-- cluster's right edge horizontally and its top edge is 31px clear of the cluster's lowest
-- pixel vertically. Nothing about the bar changed.
--
-- v12 — THE GLOBES FLANK THE CHARACTER, AND THE GLASS CATCHES LIGHT. Two changes, both
-- applied identically in all seven packs, and NOTHING ELSE MOVED: not one trigger, load
-- gate, condition, colour, spell id or region type changed, no aura was added or removed,
-- every uid is byte-identical to v11 and no W.uid() call was inserted, reordered or dropped.
--
--   1) POSITION. v11 parked all three vessels on one band at absolute y = -262, under the
--      cooldown row, which reads as a separate bar bolted under the HUD rather than as the
--      character's own state. They now FLANK the character at eye height:
--
--        life   x = -190, y =  40      power  x = +190, y =  40      target  x = 0, y = 110
--
--      Sizes are unchanged (72 / 72 / 44, rim = globe + RIM_PAD). These three positions are
--      canonical across all seven packs and were scanned against every element in every one
--      of them; they are the tightest collision-free arrangement, so they are NOT a paladin
--      tuning knob. The two obvious alternatives both collide: x = +-170 runs into the
--      Alerts column (x = -150) and the PvP column (x = +150), and x = +-210 runs into the
--      PvP-layer icons at (200, -44). Because the target vessel now sits 70px ABOVE the
--      player pair rather than beside it, GLOBE_Y stopped being one number: the player
--      cluster carries GLOBE_Y and the target cluster carries GLOBE_TGT_Y. Both are still
--      ABSOLUTE screen offsets carried once by the cluster group, with every globe inside
--      at y = 0 — see the proof in the assembly section.
--
--      The Swing Timer did NOT follow the life globe. Its x was written as -GLOBE_X, which
--      would have dragged a non-globe element 40px sideways as a side effect of this pass;
--      it now has its own G.swingX and stays exactly where v11 shipped it, at (-150, -76).
--
--   2) LOOK. The fills were flat colour, which reads as a sticker rather than liquid in a
--      vessel. Every globe now carries a SPECULAR HIGHLIGHT: a soft off-centre bright spot
--      in the upper left (see gloss() below), which is what reads as a curved glass surface
--      catching light. Two rules make it safe:
--        * APPENDED, never inserted. Conditions address sub-regions POSITIONALLY as sub.N,
--          so inserting ahead of a referenced index silently retargets it. This pack's only
--          sub.N conditions live on icons (sub.1.glow / sub.1.glowColor) and no globe
--          carries one, but the discipline is repo-wide because the rogue energy globe's
--          breakpoint marks ARE driven by sub.4 / sub.5.
--        * BLEND MODE "ADD", not "BLEND". The percentage sits INSIDE the glass and
--          sub-regions draw in order, so an appended BLEND overlay would dim the number.
--          ADD only brightens, so the text stays readable — which is the whole reason the
--          recipe is a highlight and not the more obvious dark edge vignette.
--
-- v11 — DIABLO GLOBES. The concentric rings of v9/v10 are gone. Health, mana and the
-- target are now VESSELS that fill bottom-to-top like liquid: life on the LEFT, power on
-- the RIGHT, the target between them, each with its number inside the glass. The same
-- `progresstexture` region as the ring build, one different field:
--
--   orientation = "VERTICAL"   -- "Bottom to Top": the waterline rises
--
-- The name lies about the direction in the usual WA way (gotchas.md): VERTICAL fills UP,
-- VERTICAL_INVERSE fills DOWN. Backwards, a globe DRAINS FROM THE TOP as you take damage,
-- which looks deliberate and is wrong. Switching from the circular fill path to the linear
-- one also swaps which fields are live: compress / slanted / slantMode were inert on a ring
-- and MATTER here (all three stay off — a straight waterline is what reads as liquid);
-- startAngle / endAngle are ignored on the linear path and are emitted for the schema only.
-- crop_x / crop_y stay 0.41: the sqrt(2) expansion that value cancels is applied in the
-- CIRCULAR branch, so on the linear path 0.41 is simply the texcoord scale.
--
-- THE CANONICAL NUMBERS ARE SHARED BY ALL SEVEN PACKS (see the constants block below).
-- v9 shipped seven packs that had each invented their own orb diameters; v10 ended that for
-- rings and v11 keeps the discipline for globes. GLOBE_Y is an ABSOLUTE SCREEN OFFSET, not
-- a local one — the cluster groups carry it and every globe inside them carries y = 0, so
-- the parent chain sums to exactly -150 (proof in the header of the assembly section).
--
-- THE PORTRAITS ARE GONE, AND THAT IS THE POINT. A `model` region can never carry a text
-- sub-region (SubText's supports() lists texture / progresstexture / icon / aurabar / empty
-- — not model), which is why the ring build had to park its percentages OUTSIDE the rings
-- where they competed with the world. Dropping the face buys the centre of each vessel for
-- its own number. NOTHING IS ORPHANED: neither portrait aura was deleted — both were
-- RECYCLED, uid and all, into the two glass rims (see the assembly section). 48 auras
-- before, 48 auras after, zero new W.uid() calls, changed = 0.
--
-- THREAT BECAME THE TARGET GLOBE'S RIM. Threat has no natural vessel — it is not a
-- resource anyone holds — so "Paladin - Threat" keeps its id, its uid, its triggers, its
-- thresholds and both load gates and becomes the glass around the target globe: green
-- normally, orange from 70%, red once you hold aggro, with the percentage above the globe.
-- It costs no extra element and no extra screen space. TWO TRAPS, both handled:
--   * the property is `color` on a texture region, NOT `foregroundColor` (that is
--     progresstexture-only) and NOT `barColor` (aurabar-only). Conditions.lua skips a
--     condition whose property the region does not have — no error, no editor warning, the
--     escalation simply never fires. Same class of silent no-op v9 renamed FOR, one region
--     type further along.
--   * the mandatory threatvalue <= 0 -> alpha 0 guard is kept verbatim. Without it the rim
--     paints a full-aggro colour at zero threat.
--
-- NO BREAKPOINT MARKS TO RE-DERIVE, AGAIN. On a vessel a threshold is a horizontal line at
-- yOffset = (threshold/max - 0.5) * GLOBE_MAIN, which is far easier than the ring-era
-- trigonometry — but this pack has no resource breakpoint marks and never did. Its one
-- resource threshold ("mana under 20%") is a COLOUR condition, carried across verbatim.
--
-- THE ONE COLOUR THAT HAD TO MOVE, and it moved to keep a signal alive rather than to
-- restyle anything. The canonical life colour is D2 red {0.72, 0.09, 0.09}. The bar-era
-- low-health escalation was {0.90, 0.12, 0.12} — chosen when the ring underneath was GREEN.
-- Painting that red onto a red vessel is a condition that fires and changes nothing you can
-- see: exactly the silent-no-op failure this pack renames properties to avoid, arrived at
-- from the other direction. Both health escalations therefore take the escalation colours
-- the committed prototype (poc/diablo-globes) already uses on a red vessel — a hot
-- {1, 0.15, 0.15} for your own life and {1, 0.35, 0.10} for the target. Trigger, threshold
-- (30% / 20%), property and condition order are untouched. Mana's red is UNCHANGED: red on
-- a blue vessel reads perfectly.
--
-- TWO THINGS OUTSIDE THE GLOBES MOVED, both because a globe now occupies where they sat,
-- and NEITHER changed in any other way — same triggers, gates, conditions, sizes, art:
--   * the Buffs row (0, -156 -> 0, -60): the 76px target globe lands exactly on top of the
--     old row. It now sits above the threat percentage instead.
--   * the Swing Timer (-260, -170 -> -300, -76): it used to sit under the player ring
--     cluster; a 122px life globe now fills that space. It rides just above the life globe,
--     still 140x9, still gold in the last 0.4s. See the v9 note below for why it is still a
--     bar and still a sibling of the clusters rather than a child.
--
-- v10 — ONE ORB SIZE ACROSS EVERY PACK. Pure geometry: not one trigger, load gate,
-- condition, colour, spell id or region type changed, no aura was added or removed, and
-- every uid is byte-identical to v9. What changed is that the seven class packs had each
-- picked their own ring diameters (paladin 118/88/60, mage 120/100/72, warlock 128/96/64,
-- ...) and, worse, the two clusters INSIDE this pack disagreed: the player orb was 88 wide
-- and the target orb 118, so the same two faces read as different sizes side by side.
-- Every pack built from the same seven canonical constants (ORB_OUTER / ORB_MID / ORB_INNER
-- / PORTRAIT / CLUSTER_X / CLUSTER_Y / RING — all retired by v11's globe constants):
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

-- v14 RETIRED the pack-local threatTrigger wrapper; both threat regions now call
-- F.threatTrigger directly. The wrapper existed to add `unit = "target"` on top of the
-- factory's `use_threatUnit` / `threatUnit`, on the v9 reading that `unit` is the Threat
-- Situation prototype's real argument name. It is — but only from internalVersion 51
-- onward, which is when the argument was renamed. This pack ships internalVersion 45 data,
-- and Modernize migrates < 51 data forward on import, so era-correct v45 data must emit the
-- OLD name and let WeakAuras rename it. Emitting a post-51 field on pre-51 data is at best
-- redundant (both spellings resolve to "target" here) and at worst a field the migration
-- then overwrites; the factory pair was always the one doing the work, so `unit` is dropped.
-- Nothing about where threat points changes: pre-migration the prototype's own init still
-- runs `trigger.unit = trigger.unit or "target"`, and ConstructFunction runs it before
-- events()/internal_events() read trigger.unit.

-- ===== v14 CANONICAL RING-CLUSTER GEOMETRY ==================================
-- THESE CONSTANTS ARE SHARED BY ALL SEVEN CLASS PACKS. They are not paladin tuning knobs:
-- retuning one pack in isolation is exactly how v9 ended up with seven different orb sizes
-- on one screen, and five later passes drifted the same way by working from intent instead
-- of dimensions. Change them in every pack or in none. Nothing below is scaled, rounded or
-- "improved" per pack — least of all the 44/84 portrait-to-outer ratio the face is drawn at.
--
-- Ring_20px.tga is a TRUE ANNULUS and ships inside WeakAuras itself (Private.texture_types,
-- "Shapes"), so no media addon is needed. Circle_Smooth*.tga — what the globes used — is a
-- solid disc and would fill as a pie wedge, not a ring. The number in the file name is the
-- stroke weight in the 256x256 source, so it scales with the drawn size: Ring_20px at 84px
-- is a 6.6px band, where Ring_10px is the 3px hairline v9 shipped.
local RING_TEX = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Ring_20px.tga"

-- v14: ONE cluster, THREE rings. THREAT_RING is the new outermost arc; the three numbers
-- under it are unchanged, so a v13 player cluster simply gains an arc around the outside.
local THREAT_RING = 100  -- outermost ring: YOUR threat (v14)
local OUTER       =  84  -- health ring
local INNER       =  62  -- primary power ring — mana, in all three paladin specs
local PORTRAIT    =  44  -- live unit portrait (44/84 = the approved face-to-health ratio)

-- ABSOLUTE SCREEN OFFSETS, carried ONCE by the cluster group; every ring and portrait inside
-- it sits at (0, 0), so the parent chain sums to exactly (-270, 40) and not to those numbers
-- PLUS whatever this pack's own groups happen to be offset by. Local (0, 0) on every region
-- is also what makes the three arcs concentric BY CONSTRUCTION rather than by three offsets
-- that agree today.
-- -270 is clearance, not taste: the Alerts column occupies x -170..-130 — a DYNAMIC group
-- that grows vertically — so a cluster at -190 is climbed into by the alert stack from the
-- second simultaneous prompt onward. v14's wider ring does not change that: the cluster now
-- reaches x -320..-220, still 50px clear of the column's -170 edge, and because the column
-- only ever grows UP that gap is independent of stack depth.
local CLUSTER_X = -270  -- ABSOLUTE screen x of the (only) cluster
local CLUSTER_Y =   40  -- ABSOLUTE screen y of the (only) cluster

-- WHERE THE NUMBERS GO (v15). Health is the most-read number in the pack, so it sits at the
-- cluster's CENTRE — anchorYOffset 0 on the health ring's own sub-text, landing on the 44px
-- portrait, which is the only thing in the middle with enough contrast to read a white 16pt
-- outline against. The face is not covered: it is the FIRST child of the cluster since v15,
-- so the rings (and therefore their text) draw over it, and a ring is an annulus whose band
-- never reaches the middle. See the v15 header for the radii that make that a fact, not a
-- hope. Mana takes the slot health vacated, just under the 84px ring, at 12pt now that it is
-- the only number down there. Threat is unchanged: above the 100px arc it belongs to.
-- These are sub-texts of a `progresstexture`; a `model` still cannot carry text at all, which
-- is exactly why the health number rides the RING and not the portrait.
local PCT_HP_SIZE,     PCT_HP_Y     = 16,   0
local PCT_POWER_SIZE,  PCT_POWER_Y  = 12, -54
local PCT_THREAT_SIZE, PCT_THREAT_Y = 10,  58

-- The RADIAL fill path. Only CLOCKWISE / ANTICLOCKWISE are radial in
-- Private.orientation_with_circle_types; every other value is linear (VERTICAL was the
-- globes'). This one key is what makes startAngle/endAngle live and compress/slanted/
-- slantMode inert again.
local RING_ORIENT = "CLOCKWISE"

-- ===== pack-local layout ====================================================
-- Everything below is paladin's own stacking, not shared geometry. All offsets are
-- relative to the group that owns the region; the top-level group sits at (0, -140).
local TOP_Y = -140
local G = {
  -- Resources holds the cluster group and the Swing Timer, and nothing else. It anchors at
  -- the SCREEN ORIGIN (which is what -TOP_Y means: it cancels the top group's own drop), so
  -- the cluster group's offset IS its screen position and can carry the canonical CLUSTER_X /
  -- CLUSTER_Y verbatim, exactly as every other pack's cluster group does. Give this band a
  -- drop of its own again and the cluster offsets stop being the canonical numbers, which is
  -- the drift the shared constants exist to end.
  bandY  = -TOP_Y,
  -- The runway. Its x used to be written as the life vessel's own x, so a geometry pass
  -- would drag a NON-CLUSTER element sideways as a side effect; v12 cut that link and gave it
  -- these named offsets, and v13/v14 leave them exactly as they were. It stays at the absolute
  -- (-150, -76): spanning x -220..-80 and y -80.5..-71.5. v14's threat ring widened the
  -- cluster to 100px — x -320..-220, y -10..+90 — so the bar's left end now MEETS the
  -- cluster's right edge at x = -220 instead of clearing it by 8px, and the clearance is
  -- purely vertical: the ring's lowest pixel is y = -10 and the bar's top edge is y = -71.5,
  -- 61.5px below it, with the mana percentage (10pt baseline at y = -30) still ~35px clear.
  -- The bar also sits 7.5px under the Alerts column (x = -150, 40px icons, bottom edge
  -- y = -64) and stays far above the cooldown row (top edge y = -190). It is a child of
  -- Resources, not of the cluster, so it is measured from the band anchor and never from
  -- CLUSTER_Y at all. Size, trigger, gate, colour and twist window all untouched.
  swingX = -150, swingY = -76, swingW = 140, swingH = 9,
}

-- Canonical ring colours for the arcs, this pack's own palette for everything that escalates.
local COL = {
  life    = { 0.15, 0.82, 0.28, 1 },   -- health green     | canonical, all seven packs
  mana    = { 0.20, 0.45, 0.95, 1 },   -- mana blue        | paladin power = mana, always
  track   = { 0, 0, 0, 0.55 },         -- the UNFILLED arc behind every ring. Same annulus as
                                       -- the fill (backgroundOffset 0), so the empty part of
                                       -- a ring is a track and not a halo around one.
  threat  = { 0.25, 0.80, 0.30, 1 },   -- the v8 threat green, since v14 YOUR OUTERMOST ring
  flash   = { 1, 0.10, 0.10, 0.85 },   -- the v8 threat flash red, unchanged
  lifeLow = { 1, 0.15, 0.15, 1 },      -- <30% own life. Reads even louder on a green arc than
                                       -- it did on the red vessel it was picked for, so v13
                                       -- and v14 both leave it alone. (v14 drops `tgtLow`,
                                       -- the <20% target-life colour: the only region that
                                       -- ever referenced it was the deleted target health
                                       -- ring, and a colour nothing can paint is dead weight.)
  lowMana = { 0.85, 0.15, 0.15, 1 },   -- the v8 "mana under 20%" red, UNCHANGED
  thHigh  = { 1, 0.60, 0.10, 1 },      -- the v8 ">= 70% threat" orange, unchanged
  thAggro = { 0.90, 0.12, 0.12, 1 },   -- the v8 "you hold aggro" red, unchanged
  pctText = { 1, 1, 1, 1 },            -- health, white
  mpText  = { 0.55, 0.75, 1, 1 },      -- power, tinted to echo its own ring. The numbers are
                                       -- stacked outside the cluster again, so the tint is
                                       -- what tells two adjacent percentages apart without
                                       -- spending a label on either.
  thText  = { 0.72, 0.95, 0.74, 1 },   -- threat prints on open screen above the ring
}

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

-- THE RING. Same region type the globes used, RADIAL fill path. Every region in the cluster
-- sits at (0, 0): the cluster group carries the absolute screen position, which is what keeps
-- CLUSTER_X / CLUSTER_Y the literal on-screen numbers and what makes all three arcs
-- concentric by construction. Field notes on the ones that are traps:
--   orientation CLOCKWISE -> the only radial values are CLOCKWISE / ANTICLOCKWISE; every
--     other entry in Private.orientation_with_circle_types is linear, and the names lie about
--     direction the same way aurabar's VERTICAL does (gotchas.md).
--   startAngle 0 / endAngle 360 -> a full circle, and live again now the path is radial (they
--     were dead schema on the globes' linear path). WA normalises 0/360 -> 0/0 and then
--     corrects endAngle back up by 360, so this is a handled case, not a degenerate one.
--   crop_x / crop_y = 0.41 -> the IDENTITY value, NOT "no crop". The circular path expands
--     the texture by sqrt(2) so rotated quadrants never run off it, and 1 + 0.41 exactly
--     cancels that. Setting 0 blows the ring up 1.41x and clips it.
--   backgroundColor is the UNFILLED arc; backgroundOffset = 0 keeps it the same annulus as
--     the fill rather than the halo the default 2 draws.
--   compress / slanted / slant / slantFirst / slantMode are LINEAR-only and silently inert
--     here (they were live for the waterline). Emitted because they are in the default table.
--   auraRotation = 0 -> absent from the 3.5.0 default table but read unconditionally by
--     current code as data.auraRotation / 180 * math.pi, so it must be emitted.
--   adjustedMin/Max are STRINGS (""), because SetAdjustedMin does adjustedMin:find(...).
--   progressSource is rewritten to {-1, ""} by Modernize < 71 whatever is emitted; it is
--     here for readability. {-1,""} = Automatic, which routes the FIRST ACTIVE trigger's
--     value/total into the fill — which is why health and mana can never share a region and
--     why the progress trigger must be trigger 1 on every ring here.
local function ring(id, size, color, trigs)
  return orbStub{
    regionType = "progresstexture", id = id, uid = W.uid(), parent = nil,
    width = size, height = size,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = 0, yOffset = 0, frameStrata = 1, alpha = 1,
    orientation = RING_ORIENT, startAngle = 0, endAngle = 360,
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
    triggers = F.triggers(trigs),
    load = F.load(CLASS),
  }
end

-- THE FACE. A live 3D portrait of the unit — not a static image and not a class icon. Since
-- v14 there is exactly one, YOURS, at the centre of the only cluster; the builder still takes
-- a unit because nothing about it is player-specific, and a face is what makes a stack of
-- concentric arcs read as a character rather than as a gauge.
--   modelIsUnit = true + model_fileId = "<unit>" -> PlayerModel:SetUnit(unit)
--   portraitZoom = true                          -> SetPortraitZoom(1), Blizzard head framing
-- CRITICAL: current WeakAuras reads the unit from `model_fileId`. WA 3.5.0 read `model_path`,
-- and the migration that bridges the two (Modernize < 72) is guarded by
-- WeakAuras.IsClassicEra(), which is a DISTINCT predicate from IsTBC() — so on a 2.5.x client
-- that migration DOES NOT RUN and emitting only model_path ships a blank square. Emit both;
-- model_fileId is the one that does the work.
-- The portrait carries its own unit's health trigger, so it appears and vanishes with the
-- rings around it, and it carries NO out-of-combat fade: something in the cluster has to stay
-- at full alpha so your eye can still find it while you ride around.
local function portrait(id, unit, trigs)
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
    triggers = F.triggers(trigs),
    load = F.load(CLASS),
  }
end

-- Every percentage is a sub-text of a RING, never of the portrait: SubText's supports() gate
-- lists texture / progresstexture / icon / aurabar / empty — not model — so a `model` region
-- can never carry text. That constraint is about which region OWNS the text, not about where
-- the text may land. Since v15 the health number is anchored at the ring's own centre and
-- therefore draws ON the face; mana and threat sit outside the arcs. Each number rides on its
-- own ring, so it appears and disappears with it: no threat table, no threat percentage.
local function pct(sym, size, yOffset, color)
  local st = F.subtext("%" .. sym .. "%%", size, "CENTER", sym)
  st.anchorYOffset = yOffset
  st.text_color = color
  return st
end

-- Append-only helper, so no call site can ever write a literal index and land on top of an
-- existing sub-region.
local function addSub(region, sub)
  region.subRegions[#region.subRegions + 1] = sub
  return #region.subRegions
end

-- uid order is sacred: one W.uid() per region, consumed by the constructor below,
-- in exactly this creation order. Append new regions at the END in future versions.

-- 1) top-level group, anchored below the character
local top = F.group(TOP, 0, -140, nil)
top.frameStrata = 1

-- ===== 2) Resources: the ring cluster (globes in v11-v12; a 172px bar stack through v8) =====
-- This group only holds the cluster group and the Swing Timer. The cluster is created at the
-- very BOTTOM of this script so its uid appends after every existing one. Its own uid is
-- unchanged, so a dragged Resources position survives the update.
local gRes = reg(F.group("Paladin - Resources", 0, G.bandY, TOP))
adopt(top, gRes)

-- 3) HEALTH — the 84px ring of the cluster. Was the 172x14 health aurabar through v8, the
-- outer ring of the player orb in v9/v10, the life globe in v11/v12 and the outer ring again
-- in v13; same aura id, SAME UID every time, so this updates in place rather than orphaning.
-- v14 does not move it or resize it by a pixel — threat arrives OUTSIDE it, at 100px.
-- Trigger 2 is the existing Unit Characteristics state feeder and drives the out-of-combat
-- fade ONLY; progress comes from trigger 1 (Automatic progress = first active trigger).
-- v15 moves this ring's percentage to the CENTRE of the cluster at 16pt (anchorYOffset 0),
-- where it prints over the portrait. The ring is unchanged in every other respect.
local hp = reg(ring("Paladin - Health", OUTER, COL.life,
  { F.healthTrigger(), F.unitCharTrigger() }))
addSub(hp, pct("percenthealth", PCT_HP_SIZE, PCT_HP_Y, COL.pctText))
hp.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  -- Same trigger, same 30% threshold, same property, same position in the order since v9.
  -- The colour is the globes' hot red, kept verbatim: it was picked to escape a red vessel
  -- and it is even louder on a green arc.
  F.condition(1, "percenthealth", "<", "30", "foregroundColor", COL.lifeLow),
  -- LAST: UnitHealthMax has no floor in the prototype, so a unit whose max health has not
  -- streamed yet gives total == 0 — and progresstexture draws total == 0 as FULL, the exact
  -- inverse of what the aurabar did. Hide instead of lying. Must come after the fade,
  -- because a later condition overwrites the same property.
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}
-- adopted into the cluster at the bottom of this script

-- 4) MANA — the INNER ring of the cluster. A paladin's power is MANA in all three specs
-- and in every form there is, so this ring is mana blue and needs no recolour condition — the
-- druid, whose power type changes with form, is the pack that recolours by condition. Red
-- below 20%, carried across from the v8 bar with `barColor` renamed to `foregroundColor`
-- (the ONLY name progresstexture exposes — a carried-over `barColor` is silently dropped).
local mp = reg(ring("Paladin - Mana", INNER, COL.mana,
  { F.powerTrigger(0), F.unitCharTrigger() }))
addSub(mp, pct("percentpower", PCT_POWER_SIZE, PCT_POWER_Y, COL.mpText))
mp.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "percentpower", "<", "20", "foregroundColor", COL.lowMana),
  -- The Power prototype floors total at math.max(1, UnitPowerMax(...)), which is why this
  -- guard reads <= 1 and not <= 0. Dead weight on a paladin, kept for ring discipline.
  F.condition(1, "maxpower", "<=", "1", "alpha", 0),
}
-- adopted into the cluster at the bottom of this script

-- 5) THREAT — since v14 the OUTERMOST ring of the PLAYER cluster, at THREAT_RING = 100. It
-- was the target cluster's outer ring in v13, and moving it here is the more honest reading:
-- threat is YOUR standing, and the target only names the table it is measured against. It is
-- also what let the target cluster go without losing anything — threat was the one thing that
-- cluster showed which nothing else in the game does. Health (84), mana (62) and the face
-- (44) do not move; this arc is drawn around the outside of them.
-- The Threat Situation prototype is progressType "static" with hidden value/total args —
-- value/total is exactly threatpct/100 — so the arc fills 0..100% of the pull threshold with
-- no extra wiring. Party/raid only, and never in an arena, so the common solo case is still
-- two rings and a face. For prot, red = "I have aggro" = the goal state.
-- Same id, same uid, same trigger, same thresholds, same two load gates as v6-v13; the only
-- edits are the diameter and the percentage's yOffset (54 -> 58, so the number clears the
-- larger radius). The trigger now emits `use_threatUnit` / `threatUnit` ALONE, which is the
-- era-correct spelling for internalVersion-45 data — see the note where the old wrapper was.
-- THE PROPERTY IS `foregroundColor`. v11/v12 drew threat as a plain `texture`, whose colour
-- property is `color`; a progresstexture has no `color` at all, and Conditions.lua SKIPS a
-- condition whose property the region does not define — no error, no editor warning, the
-- escalation just never fires. `barColor` is the same silent no-op one region type further
-- along (it is aurabar-only, which is why the Swing Timer below correctly still uses it).
local th = reg(ring("Paladin - Threat", THREAT_RING, COL.threat, { F.threatTrigger() }))
addSub(th, pct("threatpct", PCT_THREAT_SIZE, PCT_THREAT_Y, COL.thText))
th.conditions = {  -- severe last: a later match overwrites the same property
  F.condition(1, "threatpct", ">=", "70", "foregroundColor", COL.thHigh),
  F.condition(1, "aggro", "==", 1, "foregroundColor", COL.thAggro),
  -- MANDATORY GUARD, kept verbatim from v9. threattotal is threatvalue-derived, so it is 0
  -- whenever threatvalue is 0 — the instant before your first hit lands, and right after a
  -- Divine Shield drop. progresstexture draws total == 0 as a FULL circle, so without this
  -- the ring reads as full aggro on a target you have no threat on at all. `threatvalue` is
  -- a stored number arg; the hidden `total` is not.
  F.condition(1, "threatvalue", "<=", "0", "alpha", 0),
}
inGroup(th)
noArena(th)   -- v6: an arena party is still a party, but has no threat table
-- adopted into the cluster at the bottom of this script

-- 6) >=80% threat FLARE — Ret only (a tank AT aggro must not be alarmed), and v14 KEEPS that
-- gate: it is the whole reason this element is not simply the threat ring turning red. Was a
-- 176x18 rectangle pulsing over the bar through v8, a 132px ring floating outside the threat
-- arc in v9, the threat ring itself flaring in v10, the target globe's rim in v11/v12 and the
-- target's outer ring in v13. It resizes 84 -> THREAT_RING with the arc it warns about, so it
-- is again the SAME CIRCLE — Ring_20px, ADD blend — pulsing in place rather than a halo
-- orbiting a radius nothing occupies any more. Same trigger, same 80% threshold, same three
-- gates, same uid. Being an annulus on the threat ring's own radius it cannot cover the
-- portrait 28px inside it, whatever order it is adopted in.
local flash = reg(F.texture("Paladin - Threat Flash", CLASS,
  THREAT_RING, THREAT_RING, 0, 0, nil, RING_TEX, COL.flash))
flash.blendMode = "ADD"
flash.triggers = F.triggers({ F.threatTrigger(80) })
flash.animation.main = F.animPreset("alphaPulse", "1")
inGroup(flash)
noArena(flash)   -- v6: a pulsing red alarm that can never fire is the worst kind of clutter
gate(flash, GATE_RET)
-- adopted into the cluster at the bottom of this script

-- ===== 7) Buffs: static row of timers =====
-- v11: the row MOVED, and moved only. Its three 40px icons sat at absolute y = -156, x from
-- -86 to +42 — which is precisely where the 76px target globe (centre 0, -150; rim radius
-- 41) then sat. It goes above the cluster instead: absolute y = -60, i.e. icon edges at -40
-- and -80, clearing the threat percentage (y = -98, 11pt) by 11px and the Alerts column
-- (x = -150) and PvP column (x = +150) horizontally as before. Not one trigger, gate,
-- condition, size, icon or uid in this section changed.
-- v13 does not move it back. The target cluster left the centre line entirely (it is at
-- x = +270 now, so the row's old band is free again), but the row is OUTSIDE the clusters and
-- this version moves nothing outside them: a position people have had for two versions is not
-- worth churning to reclaim 96px of empty screen.
local gBuffs = reg(F.group("Paladin - Buffs", 0, 80, TOP))
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
-- on progresstexture), and it is positioned WITH THE PLAYER'S OWN VESSEL rather than in the
-- vacated centre: it is player state, and putting it back in the middle would give up the
-- whole point of v9. It is 140x9 instead of 172x10 so it stays clear of the Alerts column at
-- x = -150 and of the cooldown row below it.
--
-- It is a SIBLING of the two clusters inside Resources, not a child of one, even though it
-- sits with them. Two reasons: a twister who hides the life globe (Blizzard unit frames, a
-- different health addon) must keep the runway, and a 0.4s window is the one element people
-- genuinely want to drag somewhere personal — right under the crosshair, say — without
-- dragging their health and mana readouts along with it. Its x offset therefore repeats the
-- globe's, rather than inheriting it.
--
-- v11 — IT MOVED, because a 122px globe now occupies where it was. It sat at absolute
-- (-260, -170), which is inside the life globe's rim (centre -300, -150; radius 61). It now
-- rides at (-300, -76), directly ABOVE the life globe on the globe's own x: 8.5px of
-- clearance over the rim's top edge (-89), well clear of the Alerts column beside it and of
-- the cooldown row far below. Under the globe was not available — the 140px bar would have
-- had to drop past y = -222 to clear both the rim and the cooldown row's left end in a full
-- 14-icon PvP row. Nothing about the bar itself changed: same size, trigger, gate, colour
-- and gold twist window.
--
-- v12 — IT DID NOT MOVE, and that took an edit. Its x was literally `-GLOBE_X`, so widening
-- the globes to +-190 would have dragged the runway sideways too — a non-globe element
-- displaced as a side effect of a globe change, which is exactly what this version is not
-- allowed to do. It now reads G.swingX and stays at the absolute (-150, -76) v11 shipped,
-- while the globes leave the band entirely. The v11 rationale above for WHY it sits beside
-- the player's own vessel rather than in the vacated centre still holds; it is simply no
-- longer welded to the globe's own x.
--
-- v13 — IT DID NOT MOVE AGAIN, and this time nothing had to be edited: v12's cut is what made
-- the ring restoration free of side effects. Measured against the ring cluster it now sits
-- beside, it spans x -220..-80 and y -80.5..-71.5, where the cluster is an 84px ring at
-- (-270, 40) — x -312..-228, with its mana percentage bottoming out near y = -40. That is 8px
-- of horizontal clearance from the cluster's right edge and ~31px of vertical clearance from
-- its lowest pixel, plus the 7.5px it has always had under the Alerts column.
local swing = reg(F.aurabar("Paladin - Swing Timer", CLASS, G.swingW, G.swingH,
  G.swingX, G.swingY, nil, { 0.55, 0.55, 0.62, 1 }))
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

-- ===== 44-45) the ring cluster (v9-v10 orbs; v11-v12 globes; two clusters in v13) =====
-- THE UID STREAM ENDS HERE, AND ITS ORDER IS SACRED. W.uid() draws from a seeded stream, so
-- a uid() call inserted, removed or reordered ANYWHERE above shifts every later aura's uid
-- and turns the whole re-import from an Update into 45 duplicates. v13 had five constructors
-- here; v14 keeps FIVE DRAWS from the stream but only two of them build a region. Three
-- regions are genuinely deleted, and the slots they used are drawn and thrown away in place
-- ("retired uid slots" below) — because deleting the CALLS instead would pull the player
-- portrait two draws earlier in the stream and silently change its uid, which is the one
-- thing that breaks the in-game Update flow. Regions built earlier are re-parented down here;
-- creation order is what the uid stream sees, parenting order is not.
--
-- WHY NOT REUSE THE THREE FREED SLOTS FOR SOMETHING? Because there is nothing to build. A
-- filler region invented to keep a uid alive is exactly how a HUD accumulates junk, and this
-- pack has spent five versions recycling uids into whatever the new layout needed. This time
-- the auras are gone: three uids end up with no home in the import, WeakAuras never deletes
-- an aura an import does not mention, and the README tells the player to delete the leftover
-- "Paladin - Target Rings" group by hand. That is an honest orphan, declared in the
-- WA-REMOVED lines at the top of this file, not a silent one.
--
-- Sibling stacking inside a group is exact, not "roughly creation order":
-- FixGroupChildrenOrder walks controlledChildren and adds +4 frame levels per child, so
-- EARLIER = FURTHER BEHIND. v15 uses that deliberately: the FACE IS FIRST — furthest back —
-- and the four annuli stack in front of it (threat, health, mana, flare). Putting the face
-- behind is what lets the health ring's centred percentage print ON it; putting it in front,
-- as v14 did, is what would hide that number completely. Nothing about the face is lost,
-- because everything now in front of it is a ring band that never reaches the middle.
--
-- ABSOLUTE POSITIONS — the whole point of CLUSTER_X / CLUSTER_Y being absolute numbers. The
-- cluster group carries its screen position ONCE and every region inside it sits at (0, 0),
-- so a ring cannot drift from its own portrait and the three arcs are concentric by
-- construction. Walk the chain (v15 — same coordinates as v14, listed in the new draw order,
-- back to front):
--   top ................. (   0, -140)
--   + Resources ......... (   0, +140)  = (   0,    0)  bandY cancels the top group's drop
--   + Player Rings ...... (-270,  +40)  = (-270,  +40)  CLUSTER_X / CLUSTER_Y, carried once
--     + player face ..... (   0,    0)  = (-270,  +40)   44px, FIRST = furthest back (v15)
--     + threat ring ..... (   0,    0)  = (-270,  +40)  100px, x -320..-220, y -10..+90
--     + health ring ..... (   0,    0)  = (-270,  +40)   84px, its % at the centre (v15)
--     + mana ring ....... (   0,    0)  = (-270,  +40)   62px
--     + threat flare .... (   0,    0)  = (-270,  +40)  100px, ON the threat ring
-- This is verified by decoding the shipped string and summing the parent chain, not by
-- reading it off this comment; v15 additionally proves the child ORDER off the same decode.

-- 44) THE CLUSTER. Its own group, so it can be dragged as one rigid object; every region
-- inside it is at (0, 0), which is what makes the arcs share a centre. It keeps the id, the
-- uid and the exact offsets it had in v13 — v14 changes nothing about where it sits, only
-- what is drawn around the outside of it.
local gPlayerOrb = reg(F.group("Paladin - Player Rings", CLUSTER_X, CLUSTER_Y, gRes.id))
adopt(gRes, gPlayerOrb)

-- RETIRED UID SLOTS (v14). Two draws from the seeded stream that used to build
-- "Paladin - Target Rings" and "Paladin - Target Health". They are consumed and discarded so
-- the player portrait below still takes the FOURTH draw of this block, exactly as it has
-- since v9, and its uid is byte-identical. Do not delete these lines to "clean up": that
-- would shift the portrait's uid and orphan it in every installed copy of the pack.
W.uid()   -- was: Paladin - Target Rings   (deleted in v14)
W.uid()   -- was: Paladin - Target Health  (deleted in v14)

-- 45) THE FACE — the aura v9/v10 built as the player portrait, v11 borrowed for a glass rim
-- and v13 handed back. Same uid, same position in the stream. It carries the player's Health
-- trigger, so it is always there. A `model` region cannot carry a text sub-region, which is
-- why the percentages hang outside the rings.
local pPortrait = reg(portrait("Paladin - Player Portrait", "player", { F.healthTrigger() }))

-- RETIRED UID SLOT (v14). The draw that used to build "Paladin - Target Portrait". It is
-- consumed rather than removed so that the NEXT aura this pack ever adds takes the sixth
-- draw of this block and not the fifth — reusing a retired uid would make a brand-new aura
-- "Update" over the target portrait still sitting in the player's saved variables.
W.uid()   -- was: Paladin - Target Portrait (deleted in v14)

-- Re-parent the regions into the cluster, BACK TO FRONT. Children draw in controlledChildren
-- order and later ones draw on top, so this list IS the z-order and v15 changes it: the face
-- moves from last to FIRST. Through v14 it was adopted last "so nothing draws over it", which
-- is also what made it cover the health percentage the instant that number moved to the
-- centre — the offset change alone would have been invisible. Putting the face at the bottom
-- of the stack costs nothing, because every region above it is a true annulus (Ring_20px,
-- and the flare is the same texture): their bands are 42.19..50.00, 35.44..42.00 and
-- 26.16..31.00 from centre, all clear of the portrait's 0..22. The only ring-owned pixels
-- that reach the middle are the sub-texts, which is the whole intent.
-- None of these consume a uid — every region was constructed, in its original position and
-- in its original order, above. F.assemble walks controlledChildren depth-first, so the flat
-- child list reorders with this list and W.verify's parent/controlledChildren cross-check
-- fails the build if the two ever disagree.
adopt(gPlayerOrb, pPortrait)   -- the face, FIRST since v15, so the rings' text prints on it
adopt(gPlayerOrb, th)          -- outermost arc: YOUR threat, 100px (v14)
adopt(gPlayerOrb, hp)          -- health, 84px — its % lands dead centre, on the face
adopt(gPlayerOrb, mp)          -- mana, 62px
adopt(gPlayerOrb, flash)       -- the >=80% flare, on the threat arc's own radius

adopt(gRes, swing)             -- sibling of the cluster; see its own note above

-- ===== assemble (v2000 nested), encode, verify, write =====
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

-- ===== v14 GEOMETRY PROOF, against the DECODED string ========================
-- Six previous passes drifted because geometry was asserted in a comment. These checks read
-- the string that is about to ship, sum the parent chain themselves, and fail the build if
-- the cluster is not exactly where this file claims. verify-rebuild.sh re-runs this script,
-- so the proof is re-executed on every suite run rather than trusted from a header.
do
  local back = W.decode(encoded)
  local nodes = { [back.d.id] = back.d }
  for _, ch in ipairs(back.c) do nodes[ch.id] = ch end

  local function absolute(id)
    local node = assert(nodes[id], "geometry proof: no such aura " .. id)
    local x, y, hops = 0, 0, 0
    while node do
      hops = hops + 1; assert(hops < 32, "geometry proof: parent cycle at " .. id)
      x, y = x + (node.xOffset or 0), y + (node.yOffset or 0)
      node = node.parent and nodes[node.parent] or nil
    end
    return x, y
  end

  -- 1) the cluster group lands on the canonical absolute coordinates, once.
  local cx, cy = absolute("Paladin - Player Rings")
  assert(cx == -270 and cy == 40,
    ("geometry proof: cluster at (%d, %d), expected (-270, 40)"):format(cx, cy))

  -- 2) every ring, the flare and the face are CONCENTRIC with it — same absolute centre,
  --    which is only true because each one sits at a local (0, 0) — and carry the canonical
  --    diameters, threat outermost.
  for _, want in ipairs({
    { "Paladin - Threat",           100 },
    { "Paladin - Health",            84 },
    { "Paladin - Mana",              62 },
    { "Paladin - Threat Flash",     100 },
    { "Paladin - Player Portrait",   44 },
  }) do
    local id, size = want[1], want[2]
    local node = nodes[id]
    local ax, ay = absolute(id)
    assert(ax == cx and ay == cy,
      ("geometry proof: %s at (%d, %d), not concentric with the cluster"):format(id, ax, ay))
    assert(node.xOffset == 0 and node.yOffset == 0,
      "geometry proof: " .. id .. " carries a local offset; the group must carry position")
    assert(node.width == size and node.height == size,
      ("geometry proof: %s is %sx%s, expected %d"):format(id, tostring(node.width),
        tostring(node.height), size))
  end
  -- 2b) THE THREE NUMBERS, offset AND size, read off the shipped string. v15 exists because
  --     these were asserted in prose for six versions while the health number sat 54px below
  --     the cluster on open screen.
  for _, want in ipairs({
    { "Paladin - Health", PCT_HP_Y,     PCT_HP_SIZE     },
    { "Paladin - Mana",   PCT_POWER_Y,  PCT_POWER_SIZE  },
    { "Paladin - Threat", PCT_THREAT_Y, PCT_THREAT_SIZE },
  }) do
    local id, y, size = want[1], want[2], want[3]
    local st = assert(nodes[id].subRegions[1], "geometry proof: " .. id .. " lost its percentage")
    assert(st.type == "subtext", "geometry proof: " .. id .. " subRegion 1 is not the percentage")
    assert(st.anchorYOffset == y,
      ("geometry proof: %s%% is at y %s, expected %d"):format(id, tostring(st.anchorYOffset), y))
    assert(st.text_fontSize == size,
      ("geometry proof: %s%% is %spt, expected %dpt"):format(id, tostring(st.text_fontSize), size))
    assert(st.text_fontType == "OUTLINE",
      "geometry proof: " .. id .. " lost its outline, which is what makes it read on open screen")
  end
  assert(nodes["Paladin - Health"].subRegions[1].anchorYOffset == 0,
    "geometry proof: the health percentage is not at the centre of the cluster")

  -- 2c) DRAW ORDER (v15). Children draw in controlledChildren order, later on top, so the
  --     portrait must come FIRST or it covers the health number the centre offset just put
  --     on it. A ring above the face hides nothing: the bands never reach the middle.
  local order = nodes["Paladin - Player Rings"].controlledChildren
  assert(order[1] == "Paladin - Player Portrait",
    ("draw-order proof: cluster child 1 is %s, expected the portrait — the face would cover "
      .. "the centred health percentage"):format(tostring(order[1])))
  for i = 2, #order do
    assert(order[i] ~= "Paladin - Player Portrait",
      "draw-order proof: the portrait is listed twice in the cluster")
  end
  --     ...and the flat child list must agree, because WA rebuilds z-order from it.
  local flat = {}
  for _, ch in ipairs(back.c) do
    if ch.parent == "Paladin - Player Rings" then flat[#flat + 1] = ch.id end
  end
  assert(#flat == #order, "draw-order proof: cluster child count differs between c and CC")
  for i = 1, #order do
    assert(flat[i] == order[i],
      ("draw-order proof: child %d is %s in controlledChildren but %s in the flat list")
        :format(i, order[i], flat[i]))
  end

  -- 3) the deleted regions really are gone from the shipped string.
  for _, id in ipairs({ "Paladin - Target Rings", "Paladin - Target Health",
                        "Paladin - Target Portrait" }) do
    assert(not nodes[id], "geometry proof: " .. id .. " is still in the string")
  end

  -- 4) THE ALERT-COLUMN CLEARANCE, projected six children deep. The column is a dynamic
  --    group that grows UP from its anchor, so its x band is fixed by the widest child and
  --    its y band grows without bound — an earlier pass shipped a cluster that only cleared
  --    while a single alert was showing, which is why depth is projected rather than assumed.
  local alerts = nodes["Paladin - Alerts"]
  local alertX = absolute("Paladin - Alerts")
  local widest = 0
  for _, cid in ipairs(alerts.controlledChildren) do
    widest = math.max(widest, nodes[cid].width or 0)
  end
  local DEPTH = 6
  assert(#alerts.controlledChildren >= DEPTH,
    "geometry proof: fewer than 6 alerts to project a 6-deep stack from")
  local alertLeft, alertRight = alertX - widest / 2, alertX + widest / 2
  local clusterLeft, clusterRight = cx - THREAT_RING / 2, cx + THREAT_RING / 2
  local gap = alertLeft - clusterRight
  assert(gap > 0, ("geometry proof: the %dpx cluster (x %d..%d) overlaps the alert column "
    .. "(x %d..%d) at a %d-deep stack"):format(THREAT_RING, clusterLeft, clusterRight,
    alertLeft, alertRight, DEPTH))
  -- The stack's own extent, for the record: growth is vertical only, so this number is what
  -- makes the horizontal gap above depth-independent.
  local stackTop = select(2, absolute("Paladin - Alerts"))
    + DEPTH * 40 + (DEPTH - 1) * (alerts.space or 4)
  print(("geometry: cluster (%d, %d) concentric 100/84/62/44; alert column x %d..%d clears "
    .. "the cluster's %d by %dpx with a %d-deep stack reaching y %d")
    :format(cx, cy, alertLeft, alertRight, clusterRight, gap, DEPTH, stackTop))
  print(("draw order: %s"):format(table.concat(order, " -> ")))
  print(("numbers: health %dpt @ y%+d (centre, on the face), mana %dpt @ y%+d, threat %dpt @ y%+d")
    :format(PCT_HP_SIZE, PCT_HP_Y, PCT_POWER_SIZE, PCT_POWER_Y, PCT_THREAT_SIZE, PCT_THREAT_Y))
end

local outPath = dir .. "/all-specs.txt"
-- Compare against the previously shipped build BEFORE overwriting it: every future version
-- gets the uid-continuity check for free (changed must stay 0). v14 was the one version of
-- this pack that DELETED regions and it passed an explicit removal list here; that licence
-- expired with the version bump, exactly as designed — the three ids are now absent from both
-- sides of the comparison, so the list is gone and the strict default is back.
local cont = W.uidContinuity(encoded, outPath)
-- v15 hands NO allowance list: the three ids v14 deleted are absent from both sides of the
-- comparison now, so the strict default is back — no uid may disappear, full stop. v15 adds
-- and removes nothing, and reordering children consumes no uid, so this must report
-- changed = 0 AND missing = 0 against v14.
W.assertUidContinuity(cont, "paladin")

local out = io.open(outPath, "w")
out:write(encoded)
out:close()

print(("OK: %d auras (1 top + %d children), %d chars -> all-specs.txt")
  :format(#transmit.c + 1, #transmit.c, #encoded))
if cont then
  print(("uid continuity vs previous all-specs.txt: stable=%d changed=%d missing=%d (%s) "
    .. "parentSame=%s"):format(cont.stable, cont.changed, cont.missing,
    table.concat(cont.missingIds, "; "), tostring(cont.parentSame)))
else
  print("uid continuity: no previous all-specs.txt (first build)")
end
