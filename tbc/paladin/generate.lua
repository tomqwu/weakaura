-- generate.lua — "Paladin TBC - All Specs" (v17)
-- Holy / Protection / Retribution HUD in one import; spec pieces auto-load via
-- Spell Known gates. Built entirely with the wa_factory builders (zero custom code)
-- except the rail region tables, which wa_factory has no builder for.
--
-- v16 — THE SILL. The 100x100 concentric ring cluster at (-270, 40) is replaced by a
-- 102x31 instrument strip directly under your character at ABSOLUTE (0, -110), built from
-- three 100px rails stacked one on top of the other, WHERE ONE PIXEL IS EXACTLY ONE PERCENT.
-- No aura is added and none is removed: all 45 keep their ids where the id is still true and
-- ALL 45 KEEP THEIR UIDS (changed = 0, missing = 0). Two auras are renamed because their old
-- names became lies, five are re-typed/resized/re-positioned, and the group is re-ordered.
--
--   Paladin - Player Rings     group  -> Paladin - Player Sill      (renamed, SAME uid)
--   Paladin - Player Portrait  model  -> Paladin - Sill Plate       (re-typed to texture,
--                                                                    renamed, SAME uid)
--   Paladin - Threat     ring 100x100 -> threat rail  100 x 4       (id/uid unchanged)
--   Paladin - Health     ring  84x84  -> health rail  100 x 11      (id/uid unchanged)
--   Paladin - Mana       ring  62x62  -> mana rail    100 x 11      (id/uid unchanged)
--   Paladin - Threat Flash tex 100x100-> alarm RIM    108 x 37      (id/uid unchanged)
--
--   * WHY A STRIP AND NOT A RING. A 0-100 quantity has exactly 100 distinguishable states.
--     A 100px rail carries all 100 and not one pixel more: x = (v/maxpower - 0.5) * 100, so
--     for a 100-max resource a breakpoint is simply x = v - 50. The shipped rings bought
--     712.5px of arc inside a 10,000px^2 box to show 300 states, spent 1,936px^2 (19.4% of
--     the cluster) on a 3D portrait that decided nothing, and needed
--     r = size/2*0.94; x = r*sin(2*pi*f); y = r*cos(2*pi*f) to place a single notch. The
--     Sill is 3,162px^2 -- 3.16x denser -- and every breakpoint is arithmetic.
--   * WHY IT MOVES UNDER THE CHARACTER. The cluster sat at (-270, 40), 270px off the
--     crosshair, because a 100px-TALL disc does not fit anywhere near the middle. The
--     binding constraint below the character is HEIGHT, not width: the strip's WIDEST
--     envelope -- the 108x37 alarm rim, not the 102x31 plate -- at (0, -110) is collision-free
--     against every other region in this pack with the alert, cooldown and PvP dynamic groups
--     projected six children deep: 0 overlaps out of 173 projected rectangles, tightest
--     clearance 8.5px (the buff row above, y -80..-40), 64.5px to the cooldown row below
--     (y -190..-222) and 76px to the alert column. The plate alone clears by 11.5px / 67.5px.
--     That scan is re-run against the DECODED string on every build; see the proof block.
--   * THE THREE RAILS AND THEIR NUMBERS.
--       threat  100 x  4  at local y +15.5   green -> orange at 70 -> red on aggro
--       health  100 x 11  at local y  +7     green, red under 30%, number at x +32
--       mana    100 x 11  at local y  -5     blue,  red under 20%, number at x +32
--     Each number now prints INSIDE its own rail, on a dark plate, instead of floating on
--     open screen -- which is the v15 complaint ("nothing behind them but whatever the game
--     world happened to be showing") solved properly rather than by moving one glyph onto a
--     44px face.
--   * THE MANA FLOOR IS NOW DRAWN, NOT ONLY COLOURED. This pack has exactly ONE power
--     threshold in the whole string -- the mana ring's `percentpower < 20 -> red` -- and no
--     alert anywhere fires on mana. Under 20% mana a Holy paladin's next heal is his last,
--     so the mana rail gets a permanent 3x11 waterline at x = 20 - 50 = -30: you can see the
--     floor coming from 60% instead of finding out when the bar changes colour.
--   * THE RULER. Both 11px rails carry three 1px hairlines at 25 / 50 / 75 (x -25, 0, +25) at
--     18% white. 33px of ink, zero footprint, and it turns "estimate a fraction" into "count
--     quarters".
--   * WHAT IS LOST, SAID PLAINLY. The live 3D portrait is gone -- its uid is now the plate
--     the rails are drawn on. The threat PERCENTAGE is switched off (text_visible = false,
--     index preserved, one checkbox away in /wa) and replaced by a 2x4 notch at the 70 line.
--     Both are deliberate; both are the things a player is most likely to miss.
--   * THE ALARM FRAME IS A RIM, BUILT OUT OF FILLED ART. Square_White_Border.tga is NOT an
--     outline and its interior is NOT transparent: the shipped 256x256 32bpp file has 64,516
--     of 65,536 pixels (98.44%) FULLY OPAQUE, every pixel inset 8px or more from the edge has
--     alpha 255 and min RGB 167, the centre pixel is rgba(255,255,255,255), and the centre
--     scanline's red over x = 0..13 reads 0,156,100,56,40,57,102,158,206,236,250,254,255,255
--     -- a dark bevel baked into the edge of a solid white square.
--     A single region on that art therefore cannot trace a hollow frame. So the >=80% flare is
--     NOT drawn at the plate's size on top of the strip: that is a full-area ADD red quad over
--     every rail and every number, which washes out the readouts at the exact moment they are
--     needed. It is 108x37 -- RIM (3px) proud of the 102x31 plate on every side -- and it is
--     controlledChildren[1], the BOTTOM of the stack. Only the 3px protruding band draws at
--     full strength; the rest hides behind a 45%-black plate and behind every readout. Both
--     the size and the draw index are asserted from the decoded string (see "alarm canon"),
--     because dropping either half silently turns the rim back into a wash.
--   * REPARENTING, RENAMING, RE-TYPING AND RESIZING CONSUME NO UID. Every W.uid() call site
--     and its ORDER is byte-identical to v15, including the three retired slots v14 left
--     behind, so the seeded stream is unchanged and all 45 uids are what v15 shipped. The
--     in-game Update dialog's ARRANGEMENT category must be left CHECKED for this one: the
--     group moves 270px left and 150px down, its children are re-ordered, and none of that
--     arrives if arrangement is unchecked.
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
-- `subtick` sub-region is aurabar-only and could not have come along onto a ring.
-- (CORRECTED AT v16: this note used to add "is used by rogue, druid and mage". That was
-- false — `subtick` appeared in no shipped string in this repo at all until v16 put one on
-- this pack's swing runway. Those packs draw their breakpoints with `subtexture`, which is
-- a different sub-region entirely.) The paladin's one resource threshold is
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

-- ===== v16 CANONICAL SILL GEOMETRY ==========================================
-- THESE CONSTANTS ARE SHARED BY ALL SEVEN CLASS PACKS. They are not paladin tuning knobs:
-- retuning one pack in isolation is exactly how v9 ended up with seven different orb sizes
-- on one screen, and five later passes drifted the same way by working from intent instead
-- of dimensions. Change them in every pack or in none.
--
-- THE ONE RULE THE WHOLE LAYOUT FALLS OUT OF: a rail is 100px long and ONE PIXEL IS ONE
-- PERCENT. That is the exact length at which a 0..100 gauge is lossless — every pixel beyond
-- it re-draws a state the eye cannot separate, every pixel below it discards one — and it is
-- what makes every breakpoint arithmetic instead of trigonometric:
--       x(v) = (v / maxpower - 0.5) * RAIL_LEN,  i.e. x = v - 50 for a 100-max resource.
-- Compare the ring this replaces, which needed r = size/2*0.94; x = r*sin(2*pi*f);
-- y = r*cos(2*pi*f) and landed the 20% mana mark on (27.71, 9).
local MEDIA     = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\"
-- The rails are drawn from Square_White.tga: a UNIFORM white square, so crop_x/crop_y (a
-- texcoord scale on the linear path) cannot alter the art however the 100x11 aspect stretches
-- it, and textureRotate/textureRotation are irrelevant on the marks for the same reason.
local RAIL_TEX  = MEDIA .. "Square_White.tga"
-- The plate and the alarm frame are Square_White_Border.tga. IT IS A FILLED SQUARE WITH A DARK
-- BEVEL BAKED INTO ITS EDGE — NOT an outline, NOT hollow, and its interior is NOT transparent.
-- That is MEASURED, not assumed: the shipped file is a 256x256 32bpp RLE TGA in which 64,516 of
-- 65,536 pixels (98.44%) are FULLY OPAQUE (alpha 255). Every pixel inset 8px or more from the
-- edge — n = 57,600 — has alpha 255 and a minimum RGB channel of 167. The centre scanline's red
-- channel over x = 0..13 climbs 0, 156, 100, 56, 40, 57, 102, 158, 206, 236, 250, 254, 255, 255
-- (the bevel: a dark trough about 4px in, ramping to solid white by x = 12), and the centre
-- pixel is rgba(255, 255, 255, 255).
--   THE CONSEQUENCE FOR THIS PACK. One region on this texture can NEVER trace a hollow frame.
-- It is exactly what the plate wants — a bordered dark panel. It is why the alarm frame is
-- BIGGER than the plate and drawn UNDERNEATH it (see RIM below): being larger than the thing
-- that covers you is the only way filled art can read as an edge. Draw it the same size, on
-- top, on ADD blend, and it is a full-area red wash over every rail and every number at the
-- one moment the player most needs to read them.
local PLATE_TEX = MEDIA .. "Square_White_Border.tga"

-- ABSOLUTE SCREEN POSITION of the strip, carried ONCE by its group. Directly under the
-- character, on the centre line, where distance-from-the-crosshair matches read frequency.
-- -110 is a MEASURED value, not a taste call: a 102x37 probe rectangle (the widest any pack's
-- Sill gets; paladin's plate is 102x31) is collision-free at this y in all seven packs with
-- every dynamic group projected six children deep, and it is the y with the best margins of
-- the five that were tested. In THIS pack the scan below is run on the ALARM ENVELOPE — the
-- 108x37 rim, which is the widest thing the instrument ever draws — and it clears the buff row
-- (y -80..-40) by 8.5px above and the cooldown row (y -190..-222) by 64.5px below, and it
-- never comes near the Swing Timer, which is 140px of runway at x -220..-80 — entirely outside
-- the rim's x -54..+54. The plate alone clears by 11.5px and 67.5px.
local SILL_X    =    0
local SILL_Y    = -110

-- THE LANES, all local to the Sill group. Stack arithmetic, top to bottom:
--   1px margin | threat 4 | 1px gap | health 11 | 1px gap | mana 11 | 2px margin  = 31
-- spanning local +18.5 .. -12.5, hence a 102x31 plate centred at local y = +3. The three rail
-- y-offsets are IDENTICAL in all seven packs; only the plate height differs, because the four
-- packs with a discrete class resource carry a 6px pip lane under the mana rail and are 37
-- tall. Paladin has no discrete resource (mana in all three specs, in every form there is),
-- so lane 4 is omitted and the strip is 31.
local RAIL_LEN     = 100   -- one pixel is one percent. Never change this without changing the
                           -- breakpoint formula, which is the only reason it is 100.
local THREAT_H     =   4   -- threat is an early-warning ratio, not a quantity: it gets the
                           -- thinnest rail and no number.
local BAR_H        =  11   -- health and mana: tall enough for an 11pt number inside them.
local LANE_THREAT_Y = 15.5
local LANE_HEALTH_Y =  7
local LANE_POWER_Y  = -5
local PLATE_W, PLATE_H, PLATE_Y = 102, 31, 3
-- THE RIM. How far the >=80% alarm frame sticks out past the plate, PER SIDE. The alarm is the
-- same filled art as the plate (see PLATE_TEX above: 98.44% of that texture is fully opaque),
-- so the ONLY construction that reads as an edge instead of a wash is "bigger than the plate,
-- drawn first". 3px on every side is 6px on each axis: a 102x31 plate wears a 108x37 alarm,
-- and the 3px band protruding past the plate is the only part of it the player ever sees at
-- full strength. Everything inside sits behind a 45%-black plate and behind every rail, number
-- and waterline. Both halves — the size AND the draw index — are asserted from the decoded
-- string in the proof block at the bottom; drop either one and the rim is a wash again.
local RIM = 3
local ALARM_W, ALARM_H = PLATE_W + 2 * RIM, PLATE_H + 2 * RIM

-- x(v) for a 100-max resource, and the general form for anything else. Every breakpoint,
-- notch and ruler hairline in this file goes through it — there is no second place a
-- coordinate can be written by hand and drift.
--   THE ROUNDING IS NOT COSMETIC. (70/100 - 0.5) * 100 is 19.999999999999996 in IEEE754, and
--   shipping that instead of 20 puts a 17-digit float in the import string for a value that is
--   a whole pixel. Three decimals is far finer than a pixel and lands every mark this pack
--   draws on an exact integer.
local function markX(value, maxValue)
  local x = (value / (maxValue or 100) - 0.5) * RAIL_LEN
  return math.floor(x * 1000 + 0.5) / 1000
end

-- WHERE THE NUMBERS GO (v16). Each percentage is a sub-text of its OWN rail, printed INSIDE
-- it at x +32 — 82% along a 100px rail, so two digits at 11pt (~14px) span x +25..+39 and
-- three digits (~21px) span +21.5..+42.5, both still inside the rail's right edge. That is
-- the v15 complaint fixed properly: v13/v14 hung the numbers on open screen, v15 moved one
-- of them onto a 44px face, and v16 gives every number a dark plate of its own to print on.
-- text_anchorPoint stays "CENTER" and the offset does the work: INNER_RIGHT is proven on
-- aurabars and icons in this repo but NOT on a progresstexture, and this is not the version
-- to find out. The trade-off is stated where a player can see it: with a left-to-right fill
-- the fill edge passes UNDER the digits at ~82%, and OUTLINE + a black shadow + the plate are
-- what carry them through it.
local NUM_X, NUM_SIZE = 32, 11
-- The threat rail is 4px tall, so a number cannot live inside it. Its sub-text is KEPT (the
-- index is preserved and a user can re-enable it in /wa) but switched off, and parked at the
-- same x as the others at 8pt so that re-enabling it puts it somewhere sane instead of 58px
-- up in the buff row where v15 left it.
local THREAT_NUM_SIZE = 8

-- The LINEAR fill path. Private.orientation_with_circle_types:
--   HORIZONTAL_INVERSE = "Left to Right"   HORIZONTAL       = "Right to Left"
--   VERTICAL           = "Bottom to Top"   VERTICAL_INVERSE = "Top to Bottom"
--   CLOCKWISE / ANTICLOCKWISE              = the radial path the rings used
-- so LEFT TO RIGHT IS `HORIZONTAL_INVERSE`, and the name lies about the direction in the
-- usual WA way (gotchas.md) — plain HORIZONTAL drains from the right. Note this is the exact
-- OPPOSITE of the aurabar convention, where HORIZONTAL is left-anchored and grows right; the
-- Swing Timer below is an aurabar and correctly keeps HORIZONTAL.
-- Switching to the linear path also swaps which fields are live: startAngle/endAngle go inert
-- (emitted for the schema), compress/slanted/slant/slantMode become live and are deliberately
-- left off, and crop_x/crop_y become a plain texcoord scale.
local RAIL_ORIENT = "HORIZONTAL_INVERSE"

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

-- Canonical rail colours, this pack's own palette for everything that escalates. Every value
-- below is byte-identical to v15 EXCEPT `mpText`, which is stated in the v16 header and in the
-- README, plus the three new entries the Sill needs (plate / ruler / notch / manaFloor).
local COL = {
  life    = { 0.15, 0.82, 0.28, 1 },   -- health green     | canonical, all seven packs
  mana    = { 0.20, 0.45, 0.95, 1 },   -- mana blue        | paladin power = mana, always
  track   = { 0, 0, 0, 0.55 },         -- the UNFILLED part of every rail. backgroundOffset 0
                                       -- keeps it exactly the same rectangle as the fill, so
                                       -- the empty part is a track and not a halo around one.
  threat  = { 0.25, 0.80, 0.30, 1 },   -- the v8 threat green, YOUR threat since v14
  flash   = { 1, 0.10, 0.10, 0.85 },   -- the v8 threat flash red, unchanged. EXPLICIT, and it
                                       -- has always been explicit in this pack — an empty
                                       -- colour table would draw the alarm in WA's default.
  lifeLow = { 1, 0.15, 0.15, 1 },      -- <30% own life, unchanged since the globes
  lowMana = { 0.85, 0.15, 0.15, 1 },   -- the v8 "mana under 20%" red, UNCHANGED
  thHigh  = { 1, 0.60, 0.10, 1 },      -- the v8 ">= 70% threat" orange, unchanged
  thAggro = { 0.90, 0.12, 0.12, 1 },   -- the v8 "you hold aggro" red, unchanged
  pctText = { 1, 1, 1, 1 },            -- health, white
  mpText  = { 0.82, 0.90, 1.00, 1 },   -- power. v15 shipped (0.55, 0.75, 1) — a mid blue that
                                       -- was picked when the two numbers were stacked OUTSIDE
                                       -- the cluster on open screen and the tint was the only
                                       -- thing telling them apart. The number now prints
                                       -- INSIDE the mana rail, on mana blue, so the tint is
                                       -- both redundant (the rail identifies it) and the
                                       -- lowest-contrast choice available. This is the same
                                       -- hue at much higher luminance: still reads as "the
                                       -- mana one", legible on the fill and on the track.
  thText  = { 0.72, 0.95, 0.74, 1 },   -- threat, unchanged (the sub-text is off by default)
  -- v16 additions
  plate     = { 0, 0, 0, 0.45 },       -- the Sill itself: a dark bordered panel. This is what
                                       -- makes an 11px rail and an 11pt number survive snow,
                                       -- lava and Shattrath at noon, and what makes three
                                       -- bars read as ONE instrument instead of three things.
  ruler     = { 1, 1, 1, 0.18 },       -- the 25/50/75 hairlines. Deliberately faint: they are
                                       -- for counting quarters, never for alarming.
  notch     = { 1, 1, 1, 0.85 },       -- the threat rail's 70 notch — the one place on that
                                       -- rail where a number would have told you something.
  manaFloor = { 1, 0.35, 0.25, 0.95 }, -- the 20% mana waterline. Brighter and oranger than
                                       -- lowMana (0.85, 0.15, 0.15) on purpose: it must stay
                                       -- visible ON the red the rail turns when you cross it.
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

-- THE RAIL. The same `progresstexture` region the rings and the globes used, on the LINEAR
-- fill path this time. Only three things differ from the v15 ring builder — orientation, the
-- texture, and a width/height that are no longer equal — and everything else is byte-identical
-- because those fields were never about being a circle. Field notes on the traps:
--   orientation HORIZONTAL_INVERSE -> "Left to Right". See RAIL_ORIENT above; getting this
--     backwards ships a rail that empties from the left, which looks deliberate and is wrong.
--   startAngle 0 / endAngle 360 -> INERT on the linear path (they were live for the rings).
--     Emitted because they are in the region's default table.
--   crop_x / crop_y = 0.41 -> on the linear path this is a plain texcoord scale, not the
--     sqrt(2) cancellation the circular branch needed. Square_White.tga is a uniform white
--     square, so any sub-rectangle of it is the same white: the value cannot alter the art
--     however the 100x11 aspect stretches it. Kept at the default rather than "cleaned" to 0,
--     which on the CIRCULAR path would have blown a ring up 1.41x — the value is shared
--     schema, and 0.41 is the one that is proven on both paths in this repo.
--   backgroundColor is the UNFILLED part of the rail; backgroundOffset = 0 keeps it exactly
--     the same rectangle as the fill rather than the halo the default 2 draws.
--   compress / slanted / slant / slantFirst / slantMode are LINEAR-only and are LIVE here,
--     unlike on the rings. All deliberately off: a slanted fill edge is decoration, and
--     `compress` would break the one-pixel-one-percent contract the rail is built on.
--   auraRotation = 0 -> absent from the 3.5.0 default table but read unconditionally by
--     current code as data.auraRotation / 180 * math.pi, so it must be emitted.
--   adjustedMin/Max are STRINGS (""), because SetAdjustedMin does adjustedMin:find(...).
--   progressSource {-1, ""} = Automatic, which routes the FIRST ACTIVE trigger's value/total
--     into the fill — which is why health and mana can never share a region and why the
--     progress trigger must be trigger 1 on every rail here.
local function rail(id, height, yOffset, color, trigs)
  return orbStub{
    regionType = "progresstexture", id = id, uid = W.uid(), parent = nil,
    width = RAIL_LEN, height = height,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = 0, yOffset = yOffset, frameStrata = 1, alpha = 1,
    orientation = RAIL_ORIENT, startAngle = 0, endAngle = 360,
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
    triggers = F.triggers(trigs),
    load = F.load(CLASS),
  }
end

-- THE FACE IS GONE. v9-v15 drew a live 3D portrait in the middle of the cluster
-- (modelIsUnit = true, model_fileId = "player", portraitZoom = true). It was 1,936px^2 —
-- 19.4% of the cluster — and it decided nothing: no button press in any paladin rotation
-- follows from looking at your own model. v51 of the rogue pack argued the opposite case
-- ("two concentric arcs around a live 3D portrait read as a unit — you"), and that argument
-- was about a RING CLUSTER, which no longer exists here. Its uid does not go to waste and is
-- not parked in a filler region: it becomes the Sill Plate, the dark bordered panel the three
-- rails are drawn on, which is the single element that makes an 11pt number readable over
-- snow, lava and a Netherstorm skybox. `model` -> `texture` re-typing carries the uid exactly
-- as re-parenting and resizing do — only the uid() CALL ORDER is sacred — and it is the same
-- move the rogue pack made in v47/v51 when portraits became rim textures.
-- (A model region could never have carried text anyway: SubText's supports() lists
-- texture / progresstexture / icon / aurabar / empty and not model. A texture CAN, which is
-- one more thing the plate could grow later and the face never could.)

-- Every percentage is a sub-text of its OWN rail, printed INSIDE it at x = NUM_X. That is what
-- makes each number appear and disappear with the thing it measures — no threat table, no
-- threat number — and it is why the rails are `progresstexture` and not `texture`: SubText's
-- supports() gate lists progresstexture, and the fill and the number then share one region.
-- text_anchorPoint stays "CENTER"; the offset does the work (INNER_RIGHT is unproven on this
-- region type in this repo). text_fontType OUTLINE and the black shadow are unchanged from
-- v15 and are what carry the digits across the fill edge that passes under them at ~82%.
local function pct(sym, size, xOffset, color)
  local st = F.subtext("%" .. sym .. "%%", size, "CENTER", sym)
  st.anchorXOffset = xOffset
  st.anchorYOffset = 0
  st.text_color = color
  return st
end

-- A WATERLINE: a full-height mark at a known value on a rail, placed by the one formula.
-- This replaces the ring era's trigonometry entirely — v15's 20% mana mark would have been
-- r = 62/2*0.94; x = r*sin(2*pi*0.2); y = r*cos(2*pi*0.2) = (27.71, 9), and is now -30.
--   `subtexture`, not `subtick`: Tick.lua's supports() returns regionType == "aurabar",
--     full stop, while subtexture's supports() does list progresstexture.
--   textureRotate is the GATE for textureRotation (SubTexture.modify passes it as canRotate
--     and DoTexCoord only rotates when it is set). Both stay off: the art is a solid white
--     square and is invariant under texture-coordinate rotation.
--   xOffset / yOffset are NOT in the subtexture default() table but ARE read by
--     modify -> AnchorSubRegion in "point" mode; omit them and every mark stacks at centre.
local function waterline(value, width, height, color, maxValue)
  return {
    type = "subtexture",
    textureVisible = true,
    textureTexture = RAIL_TEX,
    textureColor = color, textureBlendMode = "BLEND",
    textureDesaturate = false, textureMirror = false,
    textureRotate = false, textureRotation = 0,
    anchor_mode = "point", anchor_point = "CENTER", self_point = "CENTER",
    anchor_area = "ALL",
    width = width, height = height,
    scale = 1, mirror = false, rotate = false,
    xOffset = markX(value, maxValue), yOffset = 0,
  }
end

-- Append-only helper, so no call site can ever write a literal index and land on top of an
-- existing sub-region. Sub-region indexes are POSITIONAL and conditions address them as
-- sub.N: append, never insert.
local function addSub(region, sub)
  region.subRegions[#region.subRegions + 1] = sub
  return #region.subRegions
end

-- The ruler: 25 / 50 / 75 as 1px hairlines at 18% white, appended AFTER everything a version
-- might ever point a condition at. 33px of ink, zero footprint, and it is the difference
-- between estimating a fraction and counting quarters.
local RULER = { 25, 50, 75 }
local function addRuler(region, height)
  for _, value in ipairs(RULER) do
    addSub(region, waterline(value, 1, height, COL.ruler))
  end
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

-- 3) HEALTH — LANE 2 of the Sill, 100 x 11 at local y +7. Was the 172x14 health aurabar
-- through v8, the outer ring of the player orb in v9/v10, the life globe in v11/v12, an 84px
-- ring in v13-v15; same aura id, SAME UID every time, so this updates in place rather than
-- orphaning. v16 changes its shape, its position and where its number prints, and NOTHING
-- else: the two triggers, all three conditions, the 30% threshold, both colours and the load
-- gate are byte-identical to v15.
-- Trigger 2 is the existing Unit Characteristics state feeder and drives the out-of-combat
-- fade ONLY; progress comes from trigger 1 (Automatic progress = first active trigger).
-- THE NUMBER IS INSIDE THE RAIL NOW, at x +32, 11pt. Two digits span x +25..+39 on a rail
-- that ends at +50, so it sits clear of the right edge with room for a third digit.
local hp = reg(rail("Paladin - Health", BAR_H, LANE_HEALTH_Y, COL.life,
  { F.healthTrigger(), F.unitCharTrigger() }))
addSub(hp, pct("percenthealth", NUM_SIZE, NUM_X, COL.pctText))   -- sub.1
addRuler(hp, BAR_H)                                              -- sub.2-4: 25 / 50 / 75
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
-- adopted into the Sill at the bottom of this script

-- 4) MANA — LANE 3 of the Sill, 100 x 11 at local y -5. A paladin's power is MANA in all three
-- specs and in every form there is, so this rail is mana blue and needs no recolour condition
-- — the druid, whose power type changes with form, is the pack that recolours by condition.
-- Red below 20%, carried across from the v8 bar with `barColor` renamed to `foregroundColor`
-- (the ONLY name progresstexture exposes — a carried-over `barColor` is silently dropped).
--
-- THE 20% WATERLINE IS THE ONE NEW SIGNAL IN THIS VERSION, and it exists because of what a
-- decode of the shipped string says: `percentpower < 20 -> red` on this one region is the
-- ONLY power threshold anywhere in the pack. Nothing in the Alerts column fires on mana; no
-- other aura carries a Power trigger at all. So for a Holy paladin — the one spec whose whole
-- game is mana — this rail is the entire mana instrument, and a threshold you can only see
-- AFTER you cross it is half a signal. sub.2 draws it permanently at x = 20 - 50 = -30, a
-- 3x11 line brighter and oranger than the red the rail turns, so it stays visible once the
-- fill is red behind it. Prot and Ret get it too and will mostly ignore it, which is correct:
-- it costs 33px^2 and never moves.
local mp = reg(rail("Paladin - Mana", BAR_H, LANE_POWER_Y, COL.mana,
  { F.powerTrigger(0), F.unitCharTrigger() }))
addSub(mp, pct("percentpower", NUM_SIZE, NUM_X, COL.mpText))          -- sub.1
addSub(mp, waterline(20, 3, BAR_H, COL.manaFloor))                    -- sub.2: the mana floor
addRuler(mp, BAR_H)                                                   -- sub.3-5: 25 / 50 / 75
mp.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "percentpower", "<", "20", "foregroundColor", COL.lowMana),
  -- The Power prototype floors total at math.max(1, UnitPowerMax(...)), which is why this
  -- guard reads <= 1 and not <= 0. Dead weight on a paladin, kept for rail discipline.
  F.condition(1, "maxpower", "<=", "1", "alpha", 0),
}
-- adopted into the Sill at the bottom of this script

-- 5) THREAT — LANE 1 of the Sill, 100 x 4 at local y +15.5, the thinnest rail and the only
-- one with no number. It was the target cluster's outer ring in v13 and YOUR outermost arc in
-- v14/v15; the reading has not changed, only the shape.
-- The Threat Situation prototype is progressType "static" with hidden value/total args —
-- value/total is exactly threatpct/100 — so the rail fills 0..100% of the pull threshold with
-- no extra wiring. Party/raid only, and never in an arena, so the common solo case is a strip
-- with its top lane empty. For prot, red = "I have aggro" = the goal state.
-- Same id, same uid, same trigger, same thresholds, same conditions, same two load gates as
-- v6-v15. The trigger emits `use_threatUnit` / `threatUnit` ALONE, which is the era-correct
-- spelling for internalVersion-45 data — see the note where the old wrapper was.
-- THE PROPERTY IS `foregroundColor`. v11/v12 drew threat as a plain `texture`, whose colour
-- property is `color`; a progresstexture has no `color` at all, and Conditions.lua SKIPS a
-- condition whose property the region does not define — no error, no editor warning, the
-- escalation just never fires. `barColor` is the same silent no-op one region type further
-- along (it is aurabar-only, which is why the Swing Timer below correctly still uses it).
--
-- THE THREAT NUMBER IS SWITCHED OFF, NOT DELETED. sub.1 keeps its index (a condition in some
-- future version could still address it, and a player can tick it back on in /wa) and gets
-- text_visible = false. `threatpct` is SCALED so 100 = pulling aggro: it is an early-warning
-- ratio, not a quantity you spend, and "is the fill past the notch" is read faster than "is
-- 68 nearly 70". It was also the one element of the old cluster that printed onto open screen
-- at 10pt with nothing behind it. sub.2 replaces it with a 2x4 notch at x = 70 - 50 = +20 —
-- the exact pixel where the first escalation condition fires.
local th = reg(rail("Paladin - Threat", THREAT_H, LANE_THREAT_Y, COL.threat,
  { F.threatTrigger() }))
local thPct = pct("threatpct", THREAT_NUM_SIZE, NUM_X, COL.thText)
thPct.text_visible = false
addSub(th, thPct)                                        -- sub.1: kept, off
addSub(th, waterline(70, 2, THREAT_H, COL.notch))        -- sub.2: the 70 notch
th.conditions = {  -- severe last: a later match overwrites the same property
  F.condition(1, "threatpct", ">=", "70", "foregroundColor", COL.thHigh),
  F.condition(1, "aggro", "==", 1, "foregroundColor", COL.thAggro),
  -- MANDATORY GUARD, kept verbatim from v9. threattotal is threatvalue-derived, so it is 0
  -- whenever threatvalue is 0 — the instant before your first hit lands, and right after a
  -- Divine Shield drop. progresstexture draws total == 0 as FULL, so without this the rail
  -- reads as a complete bar of aggro on a target you have no threat on at all. `threatvalue`
  -- is a stored number arg; the hidden `total` is not.
  F.condition(1, "threatvalue", "<=", "0", "alpha", 0),
}
inGroup(th)
noArena(th)   -- v6: an arena party is still a party, but has no threat table
-- adopted into the Sill at the bottom of this script

-- 6) >=80% threat ALARM — Ret only (a tank AT aggro must not be alarmed), and v16 KEEPS that
-- gate: it is the whole reason this element is not simply the threat rail turning red. It was
-- a 176x18 rectangle pulsing over the bar through v8, a 132px ring in v9, the threat ring
-- itself flaring in v10, the target globe's rim in v11/v12, the target's outer ring in v13
-- and a 100px annulus on the threat arc in v14/v15. It is now A RIM AROUND THE WHOLE STRIP:
-- 108x37 — the 102x31 plate plus RIM (3px) on every side — concentric with the plate at local
-- y +3, ADD blend, explicit red (1, 0.10, 0.10, 0.85), pulsing once a second.
-- Same trigger, same 80% threshold, same three gates, same uid, same explicit red.
--
-- WHY IT IS BIGGER AND DRAWN FIRST, AND WHY THAT IS THE WHOLE DESIGN. Square_White_Border.tga
-- is a FILLED square with a dark bevel baked into its edge — 64,516 of its 65,536 pixels
-- (98.44%) are fully opaque, every pixel 8px or more inside the edge has alpha 255 and min RGB
-- 167, and the centre pixel is rgba(255,255,255,255). A single region on that art therefore
-- CANNOT trace a hollow frame. Shipped at the plate's own size on ADD blend and drawn LAST,
-- this was a full-area red quad over every rail, every number and every waterline for as long
-- as threat stayed >=80% — washing out the readouts at exactly the moment they matter most.
-- The fix is geometric, not artistic: make it 3px larger per side and put it FIRST in
-- controlledChildren, i.e. at the BOTTOM of the stack. Only the 3px band protruding past the
-- plate draws at full strength — a pulsing red rim around the instrument — while everything
-- inside it sits behind a 45%-black plate and behind every readout, so no colour code is ever
-- composited over. That construction is correct whether the art is filled or hollow, which is
-- why it is the one to use. See the adopt order below and the alarm canon in the proof block.
local flash = reg(F.texture("Paladin - Threat Flash", CLASS,
  ALARM_W, ALARM_H, 0, PLATE_Y, nil, PLATE_TEX, COL.flash))
-- ADD blend is restated here rather than inherited, and COL.flash is an EXPLICIT four-component
-- red: a texture that ships color = {} draws in WeakAuras' default (white), which would make
-- the >=80% warning a white rim indistinguishable from a highlight.
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
-- The seals you actually twist SoC against: the damage-for-health pair, one per faction.
-- Deliberately NOT every non-SoC seal — see the RE-SEAL note for why the third trigger is
-- narrow. Both ids are already in the SEALS census above (Blood 31892 / the Martyr 348700).
local TWIST_SEALS = { 31892, 348700 }
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
-- v16 — THE TWIST WINDOW IS NOW A MARK YOU CAN SEE COMING, not only a colour that arrives.
-- Until now the sole cues were the whole bar turning gold at <= 0.4s and the Twist NOW icon
-- glowing. Both fire INSIDE the window — the moment you needed to have already pressed. A
-- mark on the runway shows the window approaching, so the press can be planned instead of
-- reacted to, which is the entire skill the twist tests.
--
-- WHY A STATIC MARK CANNOT WORK, AND WHY THIS ONE DOES. The twist window is an absolute
-- 0.4s, but the runway's length is your weapon speed. A fixed pixel offset would be correct
-- for exactly one weapon and wrong the moment Wrath of Air or Swift Retribution changes your
-- haste. WeakAuras' own `subtick` re-places itself against the LIVE maxValue every update:
--     UpdateTickPlacementOne: local minValue, maxValue = self.parent:GetMinMaxProgress()
--     tick_placement_mode == "AtValue" -> tick_placement = self.tick_placements[i]
--     percent = (tick_placement - minValue) / (maxValue - minValue)
-- On a timed progress the value is remaining seconds, so AtValue 0.4 lands exactly where
-- 0.4s remain — any weapon speed, any haste, nothing to recompute on respec or re-gear.
--
-- VERIFIED FROM THE INSTALLED ADDON, NOT INFERRED. WeakAuras 5.21.10,
-- SubRegionTypes/Tick.lua, whose final statements are:
--     local function supports(regionType) return regionType == "aurabar" end
--     WeakAuras.RegisterSubRegionType("subtick", L["Tick"], supports, create, modify, ...)
-- so it is aurabar-only, full stop. This runway is the pack's one aurabar, which is exactly
-- why the twist mark can live here and could never have gone onto a progresstexture rail.
-- `SetTickPlacementAt` calls tonumber() on the placement, so the string form the addon's own
-- default table uses ({"50"}) is the correct shape to emit.
--
-- THIS RAISES THE CLIENT FLOOR, and that is stated rather than hidden: `subtick` did not
-- exist in WA 3.5.0, the data version these strings declare. It renders on any current
-- client and is simply absent on a genuinely ancient one; nothing else about the bar
-- depends on it, so the gold recolour below remains the fallback cue.
swing.subRegions[3] = {
  type = "subtick",
  tick_visible = true,
  tick_color = { 1, 0.82, 0.1, 1 },      -- the same gold the bar turns once inside the window
  tick_placement_mode = "AtValue",
  tick_placements = { TWIST_WINDOW },    -- seconds REMAINING, not a fraction of the bar
  progressSources = { { -2, "" } },      -- Automatic, matching the addon's default
  automatic_length = true,               -- span the bar's full 9px height
  tick_thickness = 2,
  tick_length = 30,
  use_texture = false,
  tick_texture = "Interface\\CastingBar\\UI-CastingBar-Spark",
  tick_blend_mode = "ADD",
  tick_desaturate = false,
  tick_rotation = 0,
  tick_xOffset = 0,
  tick_yOffset = 0,
  tick_mirror = false,
}
-- ...and the exact time left, at one decimal, because a 0.4s window is not learnable from a
-- bar edge alone. The mark says WHERE the window is; the number says how far you are from it.
-- Precision 1 is deliberate: at precision 0 every value inside the window floors to "0".
local swingLeft = F.subtext("%p", 10, "INNER_RIGHT", "p")
swingLeft.text_text_format_p_decimal_precision = 1
swing.subRegions[4] = swingLeft
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

-- 33) v17 — RE-SEAL: the OTHER half of the twist cycle, which nothing prompted until now.
--
-- THE GAP THIS CLOSES. `Twist NOW` above requires Seal of Command to be UP (trigger 2) and
-- you to be swinging (trigger 1). So it tells you to press your second seal — and the instant
-- you obey, Seal of Command is gone, the prompt vanishes, and NOTHING told you to put it back
-- on before the next swing. `Seal MISSING (Ret)` does not cover it either: it fires only when
-- no seal at all is up, and after a twist a seal IS up. The half of the cycle that is easiest
-- to forget under pressure was the half with no cue. This is its mirror image:
--     swinging  AND  Seal of Command MISSING  AND  a twist seal present
-- so between the two auras the SoC -> twist-seal -> SoC loop is prompted end to end.
--
-- WHY THE THIRD TRIGGER, RATHER THAN JUST "SoC IS MISSING". Requiring the twist seal makes
-- this prompt and `Seal MISSING (Ret)` MUTUALLY EXCLUSIVE by construction: with no seal at all
-- the missing-seal alarm owns the moment, and this stays silent instead of shouting a second,
-- less urgent instruction over it.
--
-- THE ICON IS NOT HARD-CODED, AND THAT IS DELIBERATE. `Paladin - Twist NOW` ships
-- displayIcon = ability_paladin_sealofblood, which is the HORDE seal — its logic is
-- faction-correct (it watches Seal of Command, not the seal you twist to) but an Alliance
-- paladin sees the wrong art, and guessing a Seal of the Martyr texture path is exactly the
-- kind of unverifiable string that renders as a question mark. So this aura resolves its icon
-- from the client instead. Verified in the installed WeakAuras 5.21.10:
--   * Icon.lua UpdateIcon(): iconSource == -1 -> state.icon, 0 -> displayIcon, N -> states[N].icon
--   * BuffTrigger2.lua GetNameAndIconSimple(): when useExactSpellId is set it walks
--     trigger.auraspellids and returns GetSpellInfo(spellId)'s icon
--   * that value becomes `fallbackIcon`, which is what an UNMATCHED (showOnMissing) state
--     carries (BuffTrigger2.lua lines 978, 1003, 1017-1018)
-- so iconSource = 2 pulls Seal of Command's real in-game art out of the missing-aura trigger:
-- correct on every client, every locale, and every faction, with no texture path to get wrong.
-- IT IS BUILT AT THE FOOT OF THIS SCRIPT, NOT HERE, AND THAT IS NOT A STYLE CHOICE.
-- F.icon() consumes a W.uid() the moment it is called, so constructing a new aura at its
-- logical position would shift every uid() call after it and re-number 13 existing auras —
-- which WeakAuras matches on, so half the pack would import as duplicates instead of an
-- Update. New auras append their uid AFTER every existing call site, next to the v14
-- burners. Search "RE-SEAL, built last" below; it is adopted into gAlerts all the same, so
-- it lands in the alert column exactly as if it had been written here.

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

-- ===== 44-45) THE SILL (v9-v10 orbs; v11-v12 globes; two clusters in v13; rings v14-v15) ====
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
-- EARLIER = FURTHER BEHIND. v16 uses that as the whole layering rule:
--   THE ALARM RIM IS FIRST — furthest BACK, 108x37, 3px proud of the plate on every side. It
--     is filled art (98.44% of Square_White_Border.tga is fully opaque), so the only part of it
--     that ever reaches the eye is the 3px band sticking out past the plate. Put it last
--     instead and the same region becomes a full-area ADD red quad over every readout.
--   THE PLATE IS SECOND — the 102x31 surface the rails print on, 45% black, which is also what
--     hides the interior of the alarm.
--   THE THREE RAILS stack on the plate in reading order, so a future overlay inserted between
--     two of them lands where the comment says it will.
-- Get this backwards and either the numbers vanish under the plate or the alarm stops being a
-- rim and becomes the wash it was built as.
--
-- ABSOLUTE POSITIONS. The Sill group carries its screen position ONCE and every region inside
-- it carries only its LANE offset, so a rail cannot drift from its own plate. The group offset
-- is COMPUTED from the real parent chain below rather than typed, so it stays correct if the
-- band ever moves. Walk the chain (v16, listed in draw order, back to front):
--   top ................. (   0, -140)
--   + Resources ......... (   0, +140)  = (   0,     0)  bandY cancels the top group's drop
--   + Player Sill ....... (   0, -110)  = (   0,  -110)  SILL_X / SILL_Y, carried once
--     + alarm frame ..... (   0,   +3)  = (   0,  -107)  108x37, x -54..+54, y -88.5..-125.5
--     + Sill Plate ...... (   0,   +3)  = (   0,  -107)  102x31, x -51..+51, y -91.5..-122.5
--     + threat rail ..... (   0, +15.5) = (   0, -94.5)  100x4,  y -92.5..-96.5
--     + health rail ..... (   0,   +7)  = (   0,  -103)  100x11, y -97.5..-108.5
--     + mana rail ....... (   0,   -5)  = (   0,  -115)  100x11, y -109.5..-120.5
--   The alarm and the plate are concentric; the alarm's extra 3px per side is the rim, and it
--   is the ONLY part of the alarm the player sees.
-- This is verified by DECODING the shipped string and summing the parent chain, not by reading
-- it off this comment, and v16 additionally re-runs the whole-pack rectangle scan off the same
-- decode — see the proof block at the bottom.

-- 44) THE SILL GROUP. Its own group, so the instrument can be dragged, disabled and updated as
-- one rigid object; every region inside it carries only a lane offset. Same uid as the group
-- that has held this cluster since v9 — RENAMED, because "Player Rings" describes something
-- this pack no longer draws and a name that lies is worse than a rename. WA matches auras by
-- uid, so the rename applies in place on Update and costs nothing.
--   Resources resolves to absolute (0, 0) — G.bandY cancels the top group's own drop — so the
--   Sill group's LOCAL offset is its ABSOLUTE one. That is computed here from TOP_Y and
--   G.bandY instead of assumed, and asserted against the decoded string below, so moving the
--   band can never silently drag the strip off the centre line.
local SILL_LOCAL_X = SILL_X - 0
local SILL_LOCAL_Y = SILL_Y - (TOP_Y + G.bandY)
local gPlayerOrb = reg(F.group("Paladin - Player Sill", SILL_LOCAL_X, SILL_LOCAL_Y, gRes.id))
adopt(gRes, gPlayerOrb)

-- RETIRED UID SLOTS (v14). Two draws from the seeded stream that used to build
-- "Paladin - Target Rings" and "Paladin - Target Health". They are consumed and discarded so
-- the plate below still takes the FOURTH draw of this block, exactly as the player portrait
-- has since v9, and its uid is byte-identical. Do not delete these lines to "clean up": that
-- would shift the plate's uid and orphan it in every installed copy of the pack.
W.uid()   -- was: Paladin - Target Rings   (deleted in v14)
W.uid()   -- was: Paladin - Target Health  (deleted in v14)

-- 45) THE SILL PLATE — the aura v9/v10 built as the player portrait, v11 borrowed for a glass
-- rim, v13 handed back and v14/v15 drew as a live 44px face. Same uid, same position in the
-- stream, re-typed `model` -> `texture` and renamed. It is the dark bordered panel the three
-- rails print on, and it is load-bearing rather than decorative: it is what makes an 11px rail
-- and an 11pt number readable on snow, on a lit floor and against a Netherstorm skybox, and it
-- is what makes three bars read as ONE instrument.
-- It keeps the player Health trigger it has always carried, so the strip appears and vanishes
-- with you, and it GAINS the Unit Characteristics state feeder plus the same
-- `inCombat == 0 -> alpha 0.5` condition the health and mana rails have carried since v9, so
-- the whole instrument dims as one object out of combat instead of the plate staying lit under
-- three faded rails. Both triggers are always-active for "player", so `disjunctive = "all"`
-- does not gate anything new.
local pPortrait = reg(F.texture("Paladin - Sill Plate", CLASS,
  PLATE_W, PLATE_H, 0, PLATE_Y, nil, PLATE_TEX, COL.plate))
pPortrait.triggers = F.triggers({ F.healthTrigger(), F.unitCharTrigger() })
pPortrait.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }

-- RETIRED UID SLOT (v14). The draw that used to build "Paladin - Target Portrait". It is
-- consumed rather than removed so that the NEXT aura this pack ever adds takes the sixth
-- draw of this block and not the fifth — reusing a retired uid would make a brand-new aura
-- "Update" over the target portrait still sitting in the player's saved variables.
W.uid()   -- was: Paladin - Target Portrait (deleted in v14)

-- ===== v17) RE-SEAL, built last =====
-- The aura this pack adds in v17. Its full rationale sits at its logical position, next to
-- `Paladin - Twist NOW`; only the CONSTRUCTION lives down here, because F.icon() consumes a
-- W.uid() where it is called and this must take the NEXT draw from the seeded stream — after
-- every existing call site, including the three burners above. Built here, the other 45 auras
-- keep byte-identical uids and the pack imports as an Update.
local reseal = reg(F.icon("Paladin - RE-SEAL", CLASS, 40, 40, 0, 0, gAlerts.id))
reseal.iconSource = 2                      -- Seal of Command's own icon, resolved by the client
reseal.cooldown = false
reseal.triggers = F.triggers({
  swingTrigger(),
  F.auraTrigger("player", true, SEAL_OF_COMMAND, { matchesShowOn = "showOnMissing" }),
  F.auraTrigger("player", true, TWIST_SEALS),
})
reseal.subRegions[1] = F.subglow(false, { 1, 0.82, 0.1, 1 })
reseal.conditions = {
  F.condition(1, "expirationTime", "<=", TWIST_WINDOW, "sub.1.glow", true),
}
reseal.load.use_combat = true
gate(reseal, SWING_GATE)
polish(reseal)
adopt(gAlerts, reseal)

-- Re-parent the regions into the Sill, BACK TO FRONT. Children draw in controlledChildren
-- order and later ones draw on top, so this list IS the z-order:
--   ALARM FIRST   — the 108x37 rim. It is the same FILLED art as the plate, so it cannot trace
--                   an edge; what it can do is be 3px bigger per side and hide underneath. Only
--                   the protruding band shows, and nothing is ever composited over a readout.
--   PLATE SECOND  — it is the surface; the rails print ON it, and it is what covers the alarm's
--                   interior. Anything drawn before it (only the alarm) shows only where it
--                   sticks out past it.
--   rails in reading order, top lane to bottom lane, so a future overlay inserted between
--                   two of them lands where the comment says it will.
-- None of these consume a uid — every region was constructed, in its original position and
-- in its original order, above. F.assemble walks controlledChildren depth-first, so the flat
-- `c` list reorders with this list and W.verify's parent/controlledChildren cross-check
-- fails the build if the two ever disagree.
adopt(gPlayerOrb, flash)       -- 1) the >=80% alarm rim, 108x37, UNDER everything
adopt(gPlayerOrb, pPortrait)   -- 2) the plate: the surface everything else prints on
adopt(gPlayerOrb, th)          -- 3) lane 1, threat  100x4  @ local y +15.5
adopt(gPlayerOrb, hp)          -- 4) lane 2, health  100x11 @ local y  +7
adopt(gPlayerOrb, mp)          -- 5) lane 3, mana    100x11 @ local y  -5

adopt(gRes, swing)             -- sibling of the Sill; see its own note above

-- ===== assemble (v2000 nested), encode, verify, write =====
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

-- ===== v16 SILL PROOF, against the DECODED string ============================
-- Six previous passes drifted because geometry was asserted in a comment. These checks read
-- the string that is about to ship, sum the parent chain themselves, and fail the build if the
-- strip is not exactly what this file claims. They are the v14/v15 RING canon rewritten to the
-- RAIL canon — rewritten and not deleted, because they are the only reason a geometry change
-- in this pack has never silently shipped wrong. verify-rebuild.sh re-runs this script, so the
-- proof is re-executed on every suite run rather than trusted from a header.
local SILL_ID = "Paladin - Player Sill"
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

  -- 1) THE SILL GROUP LANDS ON THE CANONICAL ABSOLUTE COORDINATES, ONCE — walked through the
  --    real parent chain in the decoded string, not read off the constant it was built from.
  local cx, cy = absolute(SILL_ID)
  assert(cx == SILL_X and cy == SILL_Y,
    ("geometry proof: the Sill is at (%s, %s), expected (%d, %d)")
      :format(tostring(cx), tostring(cy), SILL_X, SILL_Y))
  --    ...and the band it hangs from really does cancel the top group's drop, which is the
  --    assumption that lets the group's local offset be its absolute one.
  local rx, ry = absolute("Paladin - Resources")
  assert(rx == 0 and ry == 0,
    ("geometry proof: Resources resolves to (%s, %s), not the screen origin — the Sill's "
      .. "local offset is no longer its absolute one"):format(tostring(rx), tostring(ry)))

  -- 2) THE RAIL CANON. Every lane is a LINEAR progresstexture, 100px long (one pixel = one
  --    percent), drawn from the uniform white square, on the x centre line, at its own lane
  --    offset. This replaces the v15 block that asserted CLOCKWISE / width == height /
  --    Ring_20px / concentric-at-(0,0); every one of those is now false by design, and every
  --    one of them is replaced rather than dropped.
  for _, want in ipairs({
    { "Paladin - Threat", THREAT_H, LANE_THREAT_Y, 2 },  -- sub.1 number (off), sub.2 notch
    { "Paladin - Health", BAR_H,    LANE_HEALTH_Y, 4 },  -- sub.1 number, sub.2-4 ruler
    { "Paladin - Mana",   BAR_H,    LANE_POWER_Y,  5 },  -- sub.1 number, sub.2 floor, 3-5 ruler
  }) do
    local id, h, laneY, subCount = want[1], want[2], want[3], want[4]
    local node = nodes[id]
    assert(node.regionType == "progresstexture",
      ("rail canon: %s is a %s, expected progresstexture"):format(id, tostring(node.regionType)))
    assert(node.orientation == RAIL_ORIENT,
      ("rail canon: %s fills %s, expected %s (Left to Right)")
        :format(id, tostring(node.orientation), RAIL_ORIENT))
    assert(node.width == RAIL_LEN,
      ("rail canon: %s is %s long, expected %d — one pixel must be one percent")
        :format(id, tostring(node.width), RAIL_LEN))
    assert(node.height == h,
      ("rail canon: %s is %s tall, expected %d"):format(id, tostring(node.height), h))
    assert(node.width ~= node.height, "rail canon: " .. id .. " is square; it is a rail, not a ring")
    assert(node.foregroundTexture == RAIL_TEX and node.backgroundTexture == RAIL_TEX
      and node.sameTexture == true,
      "rail canon: " .. id .. " is not drawn from Square_White on both layers")
    assert(node.backgroundOffset == 0,
      "rail canon: " .. id .. " draws its track as a halo instead of the same rectangle")
    assert(node.blendMode == "BLEND", "rail canon: " .. id .. " is not BLEND")
    assert(node.smoothProgress == true, "rail canon: " .. id .. " lost smoothProgress")
    assert(node.compress == false and node.slanted == false,
      "rail canon: " .. id .. " compresses or slants; one pixel would stop being one percent")
    assert(node.progressSource[1] == -1 and node.progressSource[2] == "",
      "rail canon: " .. id .. " is not on Automatic progress")
    local ax, ay = absolute(id)
    assert(ax == cx, ("geometry proof: %s is at x %s, not on the Sill's centre line")
      :format(id, tostring(ax)))
    assert(node.xOffset == 0 and node.yOffset == laneY,
      ("geometry proof: %s sits at local (%s, %s), expected (0, %s)")
        :format(id, tostring(node.xOffset), tostring(node.yOffset), tostring(laneY)))
    assert(ay == cy + laneY, "geometry proof: " .. id .. " does not sum to its lane")
    assert(#node.subRegions == subCount,
      ("rail canon: %s has %d subregions, expected %d — indexes are positional and conditions "
        .. "address them as sub.N"):format(id, #node.subRegions, subCount))
  end

  -- 2b) THE PLATE AND THE ALARM are CONCENTRIC textures on the same filled art, at local y +3 —
  --     and they are NOT the same size. The plate is the 102x31 surface; the alarm is 108x37,
  --     RIM (3px) proud on every side. Both are checked against their own declared size here,
  --     and the RELATION between them is pinned separately in 2b-ii below.
  for _, want in ipairs({
    { "Paladin - Sill Plate",   "BLEND", COL.plate, PLATE_W, PLATE_H },
    { "Paladin - Threat Flash", "ADD",   COL.flash, ALARM_W, ALARM_H },
  }) do
    local id, blend, color, w, h = want[1], want[2], want[3], want[4], want[5]
    local node = nodes[id]
    assert(node.regionType == "texture",
      ("plate canon: %s is a %s, expected texture"):format(id, tostring(node.regionType)))
    assert(node.texture == PLATE_TEX, "plate canon: " .. id .. " is not Square_White_Border")
    assert(node.width == w and node.height == h,
      ("plate canon: %s is %sx%s, expected %dx%d"):format(id, tostring(node.width),
        tostring(node.height), w, h))
    assert(node.xOffset == 0 and node.yOffset == PLATE_Y,
      ("plate canon: %s sits at local (%s, %s), expected (0, %d)")
        :format(id, tostring(node.xOffset), tostring(node.yOffset), PLATE_Y))
    assert(node.blendMode == blend,
      ("plate canon: %s blends %s, expected %s"):format(id, tostring(node.blendMode), blend))
    -- AN EXPLICIT COLOUR, NOT AN EMPTY TABLE. A texture that ships color = {} draws in
    -- WeakAuras' default, which for the alarm would be a white flash instead of a red one.
    assert(type(node.color) == "table" and #node.color == 4,
      "plate canon: " .. id .. " has no explicit 4-component colour")
    for i = 1, 4 do
      assert(node.color[i] == color[i],
        ("plate canon: %s colour component %d is %s, expected %s")
          :format(id, i, tostring(node.color[i]), tostring(color[i])))
    end
  end

  -- 2b-ii) THE ALARM CANON — the two facts that make the >=80% warning a RIM and not a WASH.
  --     Square_White_Border.tga is FILLED art: 64,516 of its 65,536 pixels (98.44%) are fully
  --     opaque, every pixel inset 8px or more has alpha 255 and min RGB 167, and the centre
  --     pixel is rgba(255,255,255,255). One region on that texture cannot trace a hollow frame.
  --     So the alarm reads as an edge for exactly two reasons, and BOTH are asserted here
  --     because dropping either half silently turns it back into a full-area red wash over
  --     every rail and every number:
  --       (1) it is 2*RIM = 6px larger than the plate on BOTH axes, so a 3px band protrudes;
  --       (2) it is controlledChildren[1] — the BOTTOM of the stack — so everything else in the
  --           strip, starting with the 45%-black plate at [2], draws over its interior.
  do
    local plate = nodes["Paladin - Sill Plate"]
    local alarm = nodes["Paladin - Threat Flash"]
    assert(alarm.width == plate.width + 2 * RIM,
      ("alarm canon: the alarm is %s wide and the plate is %s; a %dpx rim needs +%dpx")
        :format(tostring(alarm.width), tostring(plate.width), RIM, 2 * RIM))
    assert(alarm.height == plate.height + 2 * RIM,
      ("alarm canon: the alarm is %s tall and the plate is %s; a %dpx rim needs +%dpx")
        :format(tostring(alarm.height), tostring(plate.height), RIM, 2 * RIM))
    assert(alarm.width > plate.width and alarm.height > plate.height,
      "alarm canon: the alarm does not protrude past the plate, so it is a wash, not a rim")
    assert(alarm.xOffset == plate.xOffset and alarm.yOffset == plate.yOffset,
      "alarm canon: the alarm is not concentric with the plate, so the rim is uneven")
    local cc = nodes[SILL_ID].controlledChildren
    assert(cc[1] == "Paladin - Threat Flash",
      ("alarm canon: the alarm is not the bottom of the stack (child 1 is %s); a filled ADD "
        .. "quad drawn anywhere above the plate washes every readout"):format(tostring(cc[1])))
    assert(cc[2] == "Paladin - Sill Plate",
      ("alarm canon: child 2 is %s, expected the plate — the plate is what hides the alarm's "
        .. "interior"):format(tostring(cc[2])))
    assert(alarm.blendMode == "ADD", "alarm canon: the alarm frame stopped being additive")
    assert(alarm.color[1] > 0.5 and alarm.color[2] < 0.2 and alarm.color[3] < 0.2,
      "alarm canon: the >=80% alarm is not RED")
    assert(alarm.triggers[1].trigger.threatpct == "80"
      and alarm.triggers[1].trigger.threatpct_operator == ">=",
      "alarm canon: the alarm frame is no longer the >=80% warning")
    assert(alarm.animation.main.preset == "alphaPulse" and alarm.animation.main.duration == "1",
      "alarm canon: the alarm frame lost its pulse")
    assert(alarm.load.use_spellknown == true and alarm.load.spellknown == GATE_RET,
      "alarm canon: the alarm frame lost its Retribution gate")
  end

  -- 2b-ii) THE TWIST CANON. The 0.4s window is the whole Ret rotation, and it is readable
  --     only if the mark is placed by VALUE. Placement by percent or a raw pixel offset would
  --     be correct for one weapon speed and silently wrong for every other, which is a defect
  --     no screenshot would reveal — the bar looks fine, the twist just misses. So the mode,
  --     the placement value and the aurabar host are all pinned, and the placement is tied to
  --     the same TWIST_WINDOW constant that drives the recolour, so the mark and the colour
  --     can never disagree about where the window is.
  do
    local sw = assert(nodes["Paladin - Swing Timer"], "twist canon: the swing runway is gone")
    assert(sw.regionType == "aurabar",
      "twist canon: the runway is a " .. tostring(sw.regionType) .. "; subtick supports() "
      .. "returns regionType == \"aurabar\" only, so the mark would vanish silently")
    local tick
    for _, s in ipairs(sw.subRegions) do if s.type == "subtick" then tick = s end end
    assert(tick, "twist canon: the swing runway lost its twist mark")
    assert(tick.tick_placement_mode == "AtValue",
      "twist canon: placement mode is " .. tostring(tick.tick_placement_mode)
      .. "; only AtValue is weapon-speed independent")
    assert(tick.tick_placements[1] == TWIST_WINDOW,
      ("twist canon: the mark sits at %s but the recolour fires at %s — they must be the "
        .. "same window"):format(tostring(tick.tick_placements[1]), tostring(TWIST_WINDOW)))
    assert(tick.tick_visible == true, "twist canon: the twist mark is not visible")
    assert(sw.conditions[1].check.value == TWIST_WINDOW
      and sw.conditions[1].check.variable == "expirationTime",
      "twist canon: the gold recolour no longer fires on the twist window")
    local num
    for _, s in ipairs(sw.subRegions) do
      if s.type == "subtext" and s.text_text == "%p" then num = s end
    end
    assert(num, "twist canon: the runway lost its remaining-time number")
    assert(num.text_text_format_p_decimal_precision == 1,
      "twist canon: the countdown is at precision "
      .. tostring(num.text_text_format_p_decimal_precision)
      .. "; at 0 every value inside a 0.4s window floors to \"0\" and the number is useless")

    -- BOTH HALVES OF THE CYCLE, OR NEITHER. Twist NOW fires while Seal of Command is UP;
    -- RE-SEAL fires while it is MISSING and a twist seal is up. If either loses its shape the
    -- loop goes half-prompted again, which is the exact defect v17 exists to fix — and it is
    -- invisible in testing, because the aura that remains still looks correct on its own.
    local rs = assert(nodes["Paladin - RE-SEAL"], "twist canon: the RE-SEAL prompt is gone")
    local tw = assert(nodes["Paladin - Twist NOW"], "twist canon: the Twist NOW prompt is gone")
    assert(#rs.triggers == 3 and rs.triggers.disjunctive == "all",
      "twist canon: RE-SEAL must require ALL of swinging + SoC missing + a twist seal")
    assert(rs.triggers[2].trigger.matchesShowOn == "showOnMissing",
      "twist canon: RE-SEAL's Seal of Command trigger is no longer the MISSING case, so it "
      .. "now duplicates Twist NOW instead of mirroring it")
    assert(tw.triggers[2].trigger.matchesShowOn == nil,
      "twist canon: Twist NOW's Seal of Command trigger became a missing-check; the two "
      .. "prompts would then fire on the same half of the cycle and never on the other")
    assert(#rs.triggers[3].trigger.auraspellids == #TWIST_SEALS,
      "twist canon: RE-SEAL's third trigger no longer watches exactly the twist seals, so it "
      .. "can now fire alongside Seal MISSING instead of being mutually exclusive with it")
    assert(rs.iconSource == 2,
      "twist canon: RE-SEAL's iconSource is " .. tostring(rs.iconSource) .. "; it must stay 2 "
      .. "so the icon resolves from the Seal of Command trigger. Hard-coding a texture path "
      .. "here is how Twist NOW ended up showing Horde art to Alliance paladins")
  end

  -- 2c) THE NUMBERS. Each percentage prints INSIDE its own rail at x +32, y 0. The threat one
  --     is switched OFF but keeps index 1, because sub.N refs are positional.
  for _, want in ipairs({
    { "Paladin - Health", NUM_SIZE,        true  },
    { "Paladin - Mana",   NUM_SIZE,        true  },
    { "Paladin - Threat", THREAT_NUM_SIZE, false },
  }) do
    local id, size, visible = want[1], want[2], want[3]
    local st = assert(nodes[id].subRegions[1], "geometry proof: " .. id .. " lost its percentage")
    assert(st.type == "subtext", "geometry proof: " .. id .. " subRegion 1 is not the percentage")
    assert(st.anchorXOffset == NUM_X,
      ("geometry proof: %s%% is at x %s, expected %d (inside its own rail)")
        :format(id, tostring(st.anchorXOffset), NUM_X))
    assert(st.anchorYOffset == 0,
      ("geometry proof: %s%% is at y %s, expected 0 — it must ride its rail's centre line")
        :format(id, tostring(st.anchorYOffset)))
    assert(st.text_fontSize == size,
      ("geometry proof: %s%% is %spt, expected %dpt"):format(id, tostring(st.text_fontSize), size))
    assert(st.text_fontType == "OUTLINE",
      "geometry proof: " .. id .. " lost its outline, which is what carries it over the fill edge")
    assert(st.text_anchorPoint == "CENTER",
      "geometry proof: " .. id .. " uses an anchor point this repo has not proven on a rail")
    assert(st.text_visible == visible,
      ("geometry proof: %s%% visibility is %s, expected %s")
        :format(id, tostring(st.text_visible), tostring(visible)))
  end
  --     A number must fit inside the rail it prints in: three digits at 11pt is ~21px wide.
  local widestNumber = 21
  assert(NUM_X + widestNumber / 2 <= RAIL_LEN / 2,
    ("geometry proof: a 3-digit number at x %d spills past the rail's right edge"):format(NUM_X))

  -- 2d) THE WATERLINES, each at x = v - 50, read off the shipped string. This is the check
  --     that would have caught the ring era's trigonometry drifting away from its own arc.
  for _, want in ipairs({
    { "Paladin - Threat", 2, 70, 2, THREAT_H, COL.notch,     "the 70 notch"        },
    { "Paladin - Mana",   2, 20, 3, BAR_H,    COL.manaFloor, "the 20% mana floor"  },
    { "Paladin - Health", 2, 25, 1, BAR_H,    COL.ruler,     "the health 25 rule"  },
    { "Paladin - Health", 3, 50, 1, BAR_H,    COL.ruler,     "the health 50 rule"  },
    { "Paladin - Health", 4, 75, 1, BAR_H,    COL.ruler,     "the health 75 rule"  },
    { "Paladin - Mana",   3, 25, 1, BAR_H,    COL.ruler,     "the mana 25 rule"    },
    { "Paladin - Mana",   4, 50, 1, BAR_H,    COL.ruler,     "the mana 50 rule"    },
    { "Paladin - Mana",   5, 75, 1, BAR_H,    COL.ruler,     "the mana 75 rule"    },
  }) do
    local id, index, value, w, h, color, label = want[1], want[2], want[3], want[4], want[5],
      want[6], want[7]
    local sub = assert(nodes[id].subRegions[index],
      ("mark canon: %s has no sub.%d (%s)"):format(id, index, label))
    assert(sub.type == "subtexture",
      ("mark canon: %s sub.%d is a %s, not %s"):format(id, index, tostring(sub.type), label))
    assert(sub.textureTexture == RAIL_TEX, "mark canon: " .. label .. " is not a white square")
    assert(sub.anchor_mode == "point" and sub.self_point == "CENTER",
      "mark canon: " .. label .. " is not point-anchored; it would stack at dead centre")
    assert(sub.xOffset == markX(value),
      ("mark canon: %s is at x %s, expected %s (= %d - 50)")
        :format(label, tostring(sub.xOffset), tostring(markX(value)), value))
    assert(sub.yOffset == 0, "mark canon: " .. label .. " is off its rail's centre line")
    assert(sub.width == w and sub.height == h,
      ("mark canon: %s is %sx%s, expected %dx%d"):format(label, tostring(sub.width),
        tostring(sub.height), w, h))
    assert(sub.height == nodes[id].height,
      "mark canon: " .. label .. " is not full rail height; a waterline must span the rail")
    assert(sub.textureVisible == true, "mark canon: " .. label .. " is invisible")
    for i = 1, 4 do
      assert(sub.textureColor[i] == color[i], "mark canon: " .. label .. " changed colour")
    end
  end
  --     The mana floor must stay distinguishable from the red the rail turns underneath it,
  --     or the one threshold this pack has disappears exactly when it fires.
  assert(COL.manaFloor[1] > COL.lowMana[1] and COL.manaFloor[2] > COL.lowMana[2],
    "mark canon: the mana floor is not brighter than the low-mana fill it sits on")

  -- 3) DRAW ORDER (v16). Children draw in controlledChildren order, later on top. The ALARM
  --    RIM must be FIRST — it is filled art, so anywhere above the plate it is a full-area ADD
  --    red quad over the readouts — the PLATE second (it is the surface, and it is what hides
  --    the rim's interior), and the three rails last, in reading order.
  local order = nodes[SILL_ID].controlledChildren
  local expectedOrder = {
    "Paladin - Threat Flash", "Paladin - Sill Plate", "Paladin - Threat",
    "Paladin - Health", "Paladin - Mana",
  }
  assert(#order == #expectedOrder,
    ("draw-order proof: the Sill has %d children, expected %d"):format(#order, #expectedOrder))
  for i, id in ipairs(expectedOrder) do
    assert(order[i] == id,
      ("draw-order proof: Sill child %d is %s, expected %s"):format(i, tostring(order[i]), id))
  end
  assert(order[1] == "Paladin - Threat Flash", "draw-order proof: the alarm rim is not drawn first")
  assert(order[2] == "Paladin - Sill Plate", "draw-order proof: the plate is not drawn second")
  --    ...and EVERY readout must draw above BOTH of them. This is the claim the whole rim
  --    construction exists to make: nothing is ever composited over a rail or a number.
  local function indexOf(list, value)
    for i, v in ipairs(list) do if v == value then return i end end
    return nil
  end
  for _, id in ipairs({ "Paladin - Threat", "Paladin - Health", "Paladin - Mana" }) do
    assert(indexOf(order, id) > indexOf(order, "Paladin - Threat Flash"),
      "draw-order proof: " .. id .. " draws under the alarm rim, so the rim washes it")
    assert(indexOf(order, id) > indexOf(order, "Paladin - Sill Plate"),
      "draw-order proof: " .. id .. " draws under the plate and would be invisible")
  end
  --    ...and the flat `c` list must be depth-first in the SAME order, because WA rebuilds
  --    z-order from it.
  local flat = {}
  for _, ch in ipairs(back.c) do
    if ch.parent == SILL_ID then flat[#flat + 1] = ch.id end
  end
  assert(#flat == #order, "draw-order proof: Sill child count differs between c and CC")
  for i = 1, #order do
    assert(flat[i] == order[i],
      ("draw-order proof: child %d is %s in controlledChildren but %s in the flat list")
        :format(i, order[i], flat[i]))
  end

  -- 3b) the regions v14 deleted and the names v16 retired really are gone from the string.
  for _, id in ipairs({ "Paladin - Target Rings", "Paladin - Target Health",
                        "Paladin - Target Portrait",
                        "Paladin - Player Rings", "Paladin - Player Portrait" }) do
    assert(not nodes[id], "geometry proof: " .. id .. " is still in the string")
  end

  -- 4) THE WHOLE-PACK RECTANGLE SCAN. The strip moved from x -270 (open screen, beside the
  --    alert column) onto the CENTRE LINE directly under the character, where every other row
  --    in this pack lives. A single "does it clear the alert column" check is no longer
  --    enough, so this projects EVERY region in the pack — with every dynamic group grown six
  --    children deep, because those grow without bound — and asserts that the strip overlaps
  --    NONE of them.
  --      THE ENVELOPE SCANNED IS THE ALARM'S 108x37, NOT THE PLATE'S 102x31. The widest thing
  --    this instrument ever draws is the rim, which is RIM (3px) proud on every side, and it
  --    is drawn precisely when the player is under threat pressure and least able to tolerate
  --    a collision. Scanning the plate would certify 3px of screen the strip actually uses.
  local DEPTH = 6
  local strip = {
    x1 = cx - ALARM_W / 2, x2 = cx + ALARM_W / 2,
    y1 = cy + PLATE_Y - ALARM_H / 2, y2 = cy + PLATE_Y + ALARM_H / 2,
  }
  -- The plate's own footprint, kept for the printout so both numbers are on the record.
  local plateRect = {
    x1 = cx - PLATE_W / 2, x2 = cx + PLATE_W / 2,
    y1 = cy + PLATE_Y - PLATE_H / 2, y2 = cy + PLATE_Y + PLATE_H / 2,
  }
  assert(strip.x1 == plateRect.x1 - RIM and strip.x2 == plateRect.x2 + RIM
    and strip.y1 == plateRect.y1 - RIM and strip.y2 == plateRect.y2 + RIM,
    "geometry proof: the scanned envelope is not the plate plus a 3px rim on every side")
  local mine = {
    [SILL_ID] = true, ["Paladin - Sill Plate"] = true, ["Paladin - Threat"] = true,
    ["Paladin - Health"] = true, ["Paladin - Mana"] = true, ["Paladin - Threat Flash"] = true,
  }
  local rects, overlaps, nearest, nearestWho = {}, 0, math.huge, "nothing"
  for _, ch in ipairs(back.c) do
    local isGroup = ch.regionType == "group" or ch.regionType == "dynamicgroup"
    if not isGroup and not mine[ch.id] then
      local parent = ch.parent and nodes[ch.parent]
      local w, h = ch.width or 0, ch.height or 0
      if parent and parent.regionType == "dynamicgroup" then
        local ax, ay = absolute(parent.id)
        local space = parent.space or 4
        for i = 1, DEPTH do
          local px, py = ax, ay
          if parent.grow == "UP"     then py = ay + (i - 1) * (h + space) + h / 2
          elseif parent.grow == "DOWN"  then py = ay - (i - 1) * (h + space) - h / 2
          elseif parent.grow == "RIGHT" then px = ax + (i - 1) * (w + space) + w / 2
          elseif parent.grow == "LEFT"  then px = ax - (i - 1) * (w + space) - w / 2
          elseif parent.grow == "HORIZONTAL" then
            px = ax - (DEPTH * w + (DEPTH - 1) * space) / 2 + (i - 1) * (w + space) + w / 2
          elseif parent.grow == "VERTICAL" then
            py = ay + (DEPTH * h + (DEPTH - 1) * space) / 2 - (i - 1) * (h + space) - h / 2
          end
          rects[#rects + 1] = { id = ("%s [%d/%d]"):format(ch.id, i, DEPTH),
            x1 = px - w / 2, x2 = px + w / 2, y1 = py - h / 2, y2 = py + h / 2 }
        end
      else
        local ax, ay = absolute(ch.id)
        rects[#rects + 1] = { id = ch.id,
          x1 = ax - w / 2, x2 = ax + w / 2, y1 = ay - h / 2, y2 = ay + h / 2 }
      end
    end
  end
  for _, r in ipairs(rects) do
    local ox = math.min(strip.x2, r.x2) - math.max(strip.x1, r.x1)
    local oy = math.min(strip.y2, r.y2) - math.max(strip.y1, r.y1)
    if ox > 0 and oy > 0 then
      overlaps = overlaps + 1
      print(("  ! the Sill overlaps %s by %.1f x %.1f"):format(r.id, ox, oy))
    else
      local gap = math.max(math.max(strip.x1 - r.x2, r.x1 - strip.x2, 0),
                           math.max(strip.y1 - r.y2, r.y1 - strip.y2, 0))
      if gap < nearest then nearest, nearestWho = gap, r.id end
    end
  end
  assert(overlaps == 0,
    ("geometry proof: the Sill (x %.1f..%.1f, y %.1f..%.1f) overlaps %d region(s) with every "
      .. "dynamic group projected %d deep"):format(strip.x1, strip.x2, strip.y1, strip.y2,
      overlaps, DEPTH))
  assert(#rects >= 100, "geometry proof: the rectangle scan found suspiciously few regions")

  -- 4b) THE SWING TIMER, named explicitly because it is the one row that shares the strip's
  --     band of screen: 140px of runway at absolute (-150, -76), i.e. x -220..-80. It clears
  --     the strip on BOTH axes and the scan above proves it, but a named assertion is what
  --     stops a future version from nudging one of them into the other unnoticed.
  local swingNode = nodes["Paladin - Swing Timer"]
  local sx, sy = absolute("Paladin - Swing Timer")
  local swingRect = { x1 = sx - swingNode.width / 2, x2 = sx + swingNode.width / 2,
                      y1 = sy - swingNode.height / 2, y2 = sy + swingNode.height / 2 }
  local swingGapX = math.max(strip.x1 - swingRect.x2, swingRect.x1 - strip.x2)
  local swingGapY = math.max(strip.y1 - swingRect.y2, swingRect.y1 - strip.y2)
  assert(swingGapX > 0 or swingGapY > 0,
    ("geometry proof: the Swing Timer (x %.1f..%.1f, y %.1f..%.1f) runs through the Sill")
      :format(swingRect.x1, swingRect.x2, swingRect.y1, swingRect.y2))

  -- 4c) THE ALERT COLUMN, kept from v14/v15 and re-pointed at the strip. It grows UP without
  --     bound from (-150, -44), so only the HORIZONTAL gap is depth-independent — and that gap
  --     is what the check has always been about.
  local alerts = nodes["Paladin - Alerts"]
  local alertX = absolute("Paladin - Alerts")
  local widest = 0
  for _, cid in ipairs(alerts.controlledChildren) do
    widest = math.max(widest, nodes[cid].width or 0)
  end
  assert(#alerts.controlledChildren >= DEPTH,
    "geometry proof: fewer than 6 alerts to project a 6-deep stack from")
  local alertLeft, alertRight = alertX - widest / 2, alertX + widest / 2
  local alertGap = strip.x1 - alertRight
  assert(alertGap > 0,
    ("geometry proof: the Sill (x %.1f..%.1f) overlaps the alert column (x %.1f..%.1f) at a "
      .. "%d-deep stack"):format(strip.x1, strip.x2, alertLeft, alertRight, DEPTH))

  print(("geometry: Sill (%d, %d); plate %dx%d at x %.1f..%.1f, y %.1f..%.1f; alarm rim %dx%d "
    .. "at x %.1f..%.1f, y %.1f..%.1f (+%dpx per side); rails 100x%d/%dx%d at lanes "
    .. "%+.1f/%+.1f/%+.1f")
    :format(cx, cy, PLATE_W, PLATE_H, plateRect.x1, plateRect.x2, plateRect.y1, plateRect.y2,
      ALARM_W, ALARM_H, strip.x1, strip.x2, strip.y1, strip.y2, RIM,
      THREAT_H, RAIL_LEN, BAR_H, LANE_THREAT_Y, LANE_HEALTH_Y, LANE_POWER_Y))
  print(("collision scan (ALARM envelope %dx%d): %d projected rectangles (dynamic groups %d "
    .. "deep), %d overlaps; tightest clearance %.1fpx (%s); alert column clears by %.1fpx")
    :format(ALARM_W, ALARM_H, #rects, DEPTH, overlaps, nearest, nearestWho, alertGap))
  print(("draw order: %s"):format(table.concat(order, " -> ")))
  print(("numbers: health %dpt and mana %dpt inside their rails at x %+d; threat %dpt OFF; "
    .. "waterlines threat 70 @ %+d, mana 20 @ %+d, rulers 25/50/75 @ %+d/%+d/%+d")
    :format(NUM_SIZE, NUM_SIZE, NUM_X, THREAT_NUM_SIZE, markX(70), markX(20),
      markX(25), markX(50), markX(75)))
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
