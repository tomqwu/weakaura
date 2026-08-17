-- generate.lua — Druid TBC Bear / Restoration / Balance HUD (v18).
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
--
-- v10 (Diablo globes) — see README "## v10 — the rings become globes". The concentric ring
-- clusters are gone and so are the portraits. Health and primary power are two large VESSELS
-- that fill bottom-to-top like liquid, with a smaller target vessel between them:
--   life x = -300 (116px) · target x = 0 (76px) · power x = +300 (116px), all at screen y = -150
-- The percentage now sits INSIDE the glass, which is precisely what removing the portrait
-- buys: a `model` region cannot carry a text sub-region at all (SubText's supports() lists
-- texture / progresstexture / icon / aurabar / empty), which is why every ring version had to
-- park its numbers outside the arc where they competed with the world.
--
-- REGION MECHANICS — same progresstexture, different fill path. `orientation = "VERTICAL"` is
-- WA's "Bottom to Top": a circular texture filling upward is a round vessel with a rising
-- waterline. The name lies about direction in the usual WA way — VERTICAL fills UP,
-- VERTICAL_INVERSE fills DOWN and would drain the globe from the top as you take damage, which
-- looks deliberate and is wrong. Switching from the circular path to the linear one also swaps
-- which fields are live: compress / slanted / slantMode were inert on a ring and matter here
-- (all left off — a straight waterline is what reads as liquid), while startAngle / endAngle
-- are now ignored. crop_x / crop_y stay 0.41: on the circular path that cancelled the sqrt(2)
-- expansion, on the linear path it is simply the identity texcoord scale.
--
-- THE ABSOLUTE POSITION RULE, and it is the one thing this version could get silently wrong.
-- y = -150 is an ABSOLUTE screen offset, but every globe is nested two groups deep and
-- WeakAuras anchors a child to its group, so what lands on screen is the SUM of every
-- xOffset/yOffset down the chain. Writing -150 straight onto a child would put the globes at
-- -140 + 30 - 150 = -260. Both group offsets are constants below and every globe coordinate is
-- converted absolute -> local exactly once, by localX()/localY(); the build then re-walks the
-- assembled parent chain and asserts the three globes land at (-300 / 0 / +300, -150) before it
-- will write a string.
--
-- THREAT HAS NO NATURAL VESSEL, so it becomes the TARGET GLOBE'S RIM COLOUR: green base,
-- orange at 70% of the pull threshold on the caster rim, red on the aggro flip, with the
-- percentage above the globe. That costs no extra element and no extra screen space. Both
-- threat auras keep their v5 not-in-arena gate, their v7 Bear-form gate and the mandatory
-- `threatvalue <= 0 -> alpha 0` guard, without which a rim reads as full aggro at zero threat.
--
-- RESOURCE BREAKPOINTS GOT EASIER, not harder. On a ring the bear's 20/70 rage marks needed
-- trigonometry on the stroke; on a vessel a threshold is a horizontal line at a fixed height,
-- y = (threshold/max - 0.5) * GLOBE_MAIN, and its width is the chord of the globe there. The
-- dim + lit pair, their colours, their Feral gate, their Bear-form gate and the pop-in
-- animation are all unchanged — only the shape and the arithmetic behind the coordinates.
--
-- UID DISCIPLINE FOR v10. No aura is added or removed: 48 tables before, 48 after, every uid
-- byte-identical, drawn in the same order from the same seed. All thirteen tables in the layer
-- are recycled in place (eleven renamed, five retyped), because a deleted aura's uid is gone
-- forever and the in-game Update flow cannot reconcile it:
--   uid slot (v9 element)         -> v10 element
--   2   Druid - Unit Orbs         -> Druid - Globes             (group, renamed only)
--   6   Druid - Player Health     -> Druid - Life Globe
--   7   Druid - Player Power      -> Druid - Power Globe        (form-adaptive colour, kept)
--   8   Druid - Target Health     -> Druid - Target Globe
--   9   Druid - Target Mana       -> Druid - Target Globe Rim   (the brass rim under threat)
--   10  Druid - Threat (Bear)     -> Druid - Threat (Bear)      (now the target rim's colour)
--   11  Druid - Threat (Caster)   -> Druid - Threat (Caster)    (same)
--   33-36 Rage Tick x4            -> Rage Mark x4               (lines across the power globe)
--   last-2 Druid - Player Portrait-> Druid - Life Globe Rim
--   last-1 Druid - Target Portrait-> Druid - Power Globe Rim
-- The one readout that ends: the target's MANA ring. Its uid becomes the target globe's plain
-- brass rim, which the two spec-gated threat rims draw over — so a resto druid, or anyone in
-- an arena, still gets a rimmed target globe instead of a bare disc.
--
-- FIELD-NAME TRAP, the same class of silent no-op the v8 header lists twice: on a `texture`
-- region the condition property for tint is `color`, not the progresstexture's
-- `foregroundColor` and not the aurabar's `barColor`. Conditions.lua skips a change whose
-- property is absent from the region's properties table with no error and no editor warning,
-- so the three threat/rim escalations would have been dead on arrival if ported mechanically.
--
-- v11 (the globes flank the character and the glass catches light) — see README "## v11 — the
-- globes move up beside you and the glass catches light". TWO changes, both cosmetic, NO aura
-- added, removed or reordered: 48 tables before, 48 after, every uid byte-identical to v10, so
-- the in-game import dialog still offers Update. Every trigger, load gate, condition, colour,
-- spell id and region type is untouched, as is everything outside the globe layer.
--
--   1. POSITION. v10 parked all three vessels on one band at absolute y = -262, which reads as
--      a second bar bolted under the HUD rather than as part of the character. They now FLANK
--      the character: life at (-190, 40), power at (+190, 40), target at (0, 110). The two
--      main globes rise to eye level either side of the model and the target sits above and
--      between them, so the layer surrounds the character instead of underlining him.
--      |x| = 190 IS THE TIGHTEST COLLISION-FREE ARRANGEMENT and is not a taste call: the
--      Alerts column sits at x = -150 and the PvP column at x = +150 (icons up to 40 wide, so
--      they occupy |x| <= 170), and the PvP layer also has elements at (200, -44). A 72px
--      vessel spans 36 either side of its centre, so at |x| = 190 its inner edge is at 154 and
--      its outer edge at 226 — clear of the icon columns, and clear in y of (200,-44) because
--      the globes are now 84px above it. |x| = 170 would sit ON the icon columns and |x| = 210
--      would sit ON the PvP element. Do not "tidy" these numbers.
--      The target globe is the one element whose y is no longer GLOBE_Y, so its own absolute
--      height is a constant of its own (GLOBE_Y_TGT) and globe()/rim() now take an explicit
--      absolute y. The absolute->local conversion still happens exactly once, in localY(), and
--      the assembled parent chain is still re-walked and asserted before anything is written.
--
--   2. LOOK. Each vessel gains a SPECULAR HIGHLIGHT: a soft off-centre bright spot in the
--      upper left, which is what the eye reads as a curved glass surface catching light. It is
--      a `subtexture` sub-region on the same Circle_Smooth.tga disc, 46% x 34% of the globe's
--      diameter, offset (-17%, +21%) of it, white at 28% alpha.
--      TWO RULES THIS OBEYS, both of them silent-breakage class:
--        * APPENDED, NEVER INSERTED. Conditions address sub-regions POSITIONALLY as sub.N
--          (Conditions.lua builds the property name from the 1-based subRegions index), so
--          inserting ahead of a referenced index silently retargets that condition at the new
--          occupant. No condition on any of the three globes references sub.N today, but the
--          pattern is enforced here anyway because it is the rule the rogue pack's energy
--          breakpoints (sub.4 / sub.5) live and die by.
--        * BLEND MODE "ADD", not "BLEND". The percentage sits INSIDE the glass and sub-regions
--          draw in index order, so an appended BLEND overlay would draw OVER the number and
--          dim it. ADD can only brighten what is under it, so the number stays readable — and
--          that constraint is the whole reason the recipe is a highlight rather than the more
--          obvious dark edge vignette, which would have to be a BLEND and would have to be
--          inserted before the text to avoid muddying it.
--      `textureRotate` is the gate that makes `textureRotation` do anything, and xOffset /
--      yOffset are read only in anchor_mode = "point" — the same two traps the priest pack's
--      marks document; both are set accordingly.
--
-- v12 (the rings come back, and the faces with them) — see README "## v12 — the globes become
-- rings again, around a live portrait". The Diablo vessels are gone. Health, primary power and
-- threat are RINGS once more, drawn concentrically around a LIVE UNIT PORTRAIT in two matched
-- clusters:
--   PLAYER at (-270, 40):  outer 84 = health, inner 62 = primary power, centre 44 = your face
--   TARGET at (+270, 110): outer 84 = THREAT, inner 62 = target health, centre 44 = its face
-- TWO rings and a face per cluster, deliberately. The v8-v9 target carried a THIRD ring (its
-- mana) and that extra arc is exactly what made the old clusters read as busy and uneven, so no
-- target power ring is rebuilt: the uid that used to draw it becomes the target's outer TRACK
-- ring, the empty groove the threat arc runs in (see below).
--
-- REGION MECHANICS — the same `progresstexture`, back on the CIRCULAR fill path.
--   orientation = "CLOCKWISE" -> CLOCKWISE / ANTICLOCKWISE are the only radial values; every
--     other key in orientation_with_circle_types is linear, which is where v10-v11 lived.
--   startAngle 0 / endAngle 360 -> LIVE again (they were ignored on the linear path). WA
--     normalises 0/360 -> 0/0 and then corrects endAngle back up by 360, so a full ring is a
--     handled case, not a degenerate one.
--   compress / slanted / slant / slantFirst / slantMode -> the mirror image: LIVE on the vessel,
--     INERT here. Left exactly as they were; they are in the default table, so they are emitted.
--   crop_x / crop_y = 0.41 -> the IDENTITY value on the circular path, NOT "no crop": the path
--     expands the texture by sqrt(2) so rotated quadrants never run off it and 1 + 0.41 cancels
--     that exactly. Setting 0 blows the ring up 1.41x and clips it.
--   backgroundOffset 0 -> keeps the unfilled track the same annulus as the fill; the default 2
--     fattens it into a halo.
--   Ring_20px.tga is a true ANNULUS (the number is the stroke weight of the source art, so the
--     drawn band is diameter * 20/256). Circle_Smooth.tga — the globe disc — would fill as a pie
--     wedge here, which is why the texture changes with the orientation.
--
-- THE PORTRAIT is a `model` region and it needs BOTH unit fields:
--   modelIsUnit = true + model_fileId = "<unit>" -> PlayerModel:SetUnit(unit)
--   portraitZoom = true                          -> SetPortraitZoom(1), Blizzard head framing
-- Current WeakAuras reads the unit from `model_fileId`; WA 3.5.0 read `model_path`, and the
-- Modernize block that bridges them is gated on IsClassicEra(), which is a DISTINCT predicate
-- from IsTBC() — so on a 2.5.x client emitting only model_path is a silent no-op. Both are
-- emitted. The portrait is also why the percentages are back OUTSIDE the arcs: SubText's
-- supports() lists texture / progresstexture / icon / aurabar / empty and pointedly not model,
-- so a model region can never carry a number. Both clusters label themselves identically —
-- health 13pt at y -54 (just under the outer ring), power 10pt at -70, threat 10pt at +54.
--
-- WHAT CARRIES OVER FROM THE GLOBES, UNCHANGED: every trigger, every load gate, every danger
-- escalation (amber under 50% health, red under 25%, the power-type recolour, threat green ->
-- orange at 70% -> red on the flip), both threat gates (v5 not-in-arena, v7 Bear form) and the
-- mandatory `threatvalue <= 0 -> alpha 0` guard — a progresstexture with total 0 draws FULL, so
-- without it the threat ring reads as full aggro at zero threat. The colour escalations live on
-- `foregroundColor`: `barColor` is aurabar-only, `color` is texture-only, and Conditions.lua
-- skips a change whose property the region does not have with no error and no editor warning.
-- WHAT IS DROPPED: the v11 specular highlight. It was a glass effect for a filled vessel and
-- means nothing on an annulus, so `glassHighlight`/`appendSub` go with it.
--
-- RESOURCE BREAKPOINTS GO BACK TO TRIGONOMETRY. On a vessel the bear's 20/70 rage marks were
-- horizontal waterlines; on a ring a threshold is a POINT ON THE CIRCUMFERENCE, placed from the
-- inner ring's radius:
--   r = INNER/2 * 0.94 ;  x = r * sin(2*pi*f) ;  y = r * cos(2*pi*f)   (f = threshold/max)
-- which puts f = 0 at 12 o'clock and runs clockwise — the exact direction the ring fills, so a
-- mark always sits where the arc will reach it. They are ROUND PIPS, not lines: rotating a thin
-- quad on a texture region rotates the ART INSIDE the quad (DoTexCoord -> GetRotatedPoints), so
-- a straight line can never be laid along an arc. Pip diameters derive from the Ring_20px stroke
-- so they sit in the band rather than across it. The dim + lit pair, their colours, the pop-in
-- animation, the Feral gate and the v7 Bear-form gate are all unchanged.
--
-- POSITIONS ARE STILL ABSOLUTE, and this is still the one thing the layer can get silently
-- wrong: every region is nested two groups deep and WeakAuras anchors a child to its group, so
-- what lands on screen is the SUM of every xOffset/yOffset down the chain. localX()/localY() do
-- that conversion exactly once and the assembled parent chain is re-walked and asserted before
-- a string is written — for both cluster centres AND for all four rage pips.
-- |x| = 270 IS NOT A TASTE CALL. The Alerts column occupies x -170..-130 and the PvP column
-- x 182..218, and both are DYNAMIC GROUPS that grow vertically: at |x| = 190 an 84px outer ring
-- spans 148..232 and the alert stack climbs straight into it from the second simultaneous prompt
-- onward. At |x| = 270 the ring spans 228..312 — the tightest symmetric position that is clear
-- of both columns at any stack depth. Do not "tidy" these numbers.
--
-- UID DISCIPLINE FOR v12. No aura is added or removed: 48 tables before, 48 after, every uid
-- byte-identical, drawn in the same order from the same seed. All thirteen tables in the layer
-- are recycled in place, because a deleted aura's uid is gone forever and the in-game Update
-- flow cannot reconcile it:
--   uid slot (v11 element)         -> v12 element
--   2   Druid - Globes             -> Druid - Rings              (group, renamed only)
--   6   Druid - Life Globe         -> Druid - Player Health Ring (outer, player cluster)
--   7   Druid - Power Globe        -> Druid - Player Power Ring  (inner, form-adaptive colour)
--   8   Druid - Target Globe       -> Druid - Target Health Ring (inner, target cluster)
--   9   Druid - Target Globe Rim   -> Druid - Target Ring Track  (outer groove, threat's base)
--   10  Druid - Threat (Bear)      -> Druid - Threat (Bear)      (outer ring, id unchanged)
--   11  Druid - Threat (Caster)    -> Druid - Threat (Caster)    (same)
--   33-36 Rage Mark x4             -> Rage Mark x4               (pips on the power ring)
--   last-2 Druid - Life Globe Rim  -> Druid - Player Portrait    (model)
--   last-1 Druid - Power Globe Rim -> Druid - Target Portrait    (model)
--
-- v13 (ONE CLUSTER — the target cluster is deleted and threat comes home) — see README
-- "## v13 — one cluster, and threat is yours".
--   * THE ENTIRE TARGET CLUSTER IS GONE: its 62px health ring, the 84px track ring that groove
--     ran in, and its live portrait. Three auras removed, 48 tables -> 45. The target's health
--     is already on the target frame and on its nameplate, so for the whole game that cluster
--     was a second copy of the default UI parked at (+270, 110). The group that held it,
--     `Druid - Rings`, STAYS — it is the player cluster's layer and the rage pips' too.
--   * THREAT MOVES, IT DOES NOT DIE. It is the one thing that cluster carried which nothing
--     else on screen shows, and a dps who pulls aggro dies. Both threat rings (Bear and
--     Caster, mutually exclusive spec gates) become the OUTERMOST ring of the PLAYER cluster,
--     which is also the more honest reading: it is YOUR threat, not the target's.
--       THREAT_RING 100  (outermost, same Ring_20px annulus)
--       OUTER        84  (health, unchanged)
--       INNER        62  (primary power, unchanged)
--       PORTRAIT     44  (unchanged)
--       cluster at ABSOLUTE (-270, 40), unchanged
--       threat percentage: 10 pt, CENTER, anchorYOffset +58 (above the new outer ring)
--     There is no threat flash halo in this pack to resize: decoding v12 for `alphaPulse`
--     returns zero hits, and the only animations in the layer are the rage pips' shrink/fade.
--   * THREAT KEEPS EVERYTHING ELSE IT HAD: the Threat Situation trigger, the escalations on
--     `foregroundColor` (Bear tank-inverted red on aggro lost; Caster green -> orange at 70%
--     -> red on the flip), the v5 not-in-an-arena size gate, the v7 Bear-form trigger, the
--     spec gates, and the mandatory `threatvalue <= 0 -> alpha 0` guard without which a
--     progresstexture at total 0 draws FULL and reads as complete aggro at zero threat.
--     NO gate is added either: this pack has never carried a party/raid `ingroup` gate on
--     threat (its gates are per-spec), and inventing one here would be a behaviour change
--     rather than a preserved one. The ring still self-hides with no hostile target, because
--     the Threat Situation prototype produces no state for a unit that is not there.
--   * THE TRIGGER'S UNIT ARG IS `threatUnit`, NOT `unit`. F.threatTrigger emits the era-correct
--     use_threatUnit/threatUnit pair. v12's orbThreat() ADDITIONALLY set `unit = "target"` on
--     the belief that threatUnit was dead data; it is the other way round — the Threat
--     Situation prototype renamed that argument to `unit` at internalVersion 51 and Modernize
--     migrates < 51 data forward, so IV-45 data must emit the OLD name and let the migration
--     rename it. The stray `unit` field is dropped and the factory trigger is used unchanged.
--   * ORPHANS ARE EXPECTED HERE, AND THAT IS THE POINT. Every version up to v12 recycled every
--     uid so an update left nothing behind; v13 genuinely REMOVES regions, and inventing filler
--     regions to absorb their freed slots is how a HUD accumulates junk nobody can explain a
--     year later. Two of the three removed regions sat MID-STREAM (uid slots 8 and 9 of the
--     seeded sequence), so their W.uid() calls are still DRAWN AND DISCARDED where they always
--     were — a retired slot, not a filler region — and every later uid keeps its value. The
--     third (Druid - Target Portrait) was the very last draw in the file and is retired the
--     same way, so no future version can ever re-issue a uid a player may still have installed.
--     Result: all 45 surviving uids are byte-for-byte identical (changed = 0) and the only
--     missing ones are the three declared below.
--     WeakAuras never deletes an aura that an import does not mention, so those three survive
--     in the player's collection after an Update and MUST be deleted by hand. They are named,
--     exactly, in the README for that reason.
--   * NOTHING OUTSIDE THE CLUSTERS CHANGED: not one trigger, load gate, condition, colour or
--     spell id in the buffs, alerts, cooldown row, rage pips or PvP layer.
--
-- v14 (THE HEALTH NUMBER MOVES INTO THE MIDDLE) — see README "## v14 — the health number is in
-- the middle again". NO aura added, removed, renamed or re-triggered: 45 tables before, 45
-- after, every uid byte-identical, so the import dialog still offers Update. Exactly three
-- things change, and two of them are one change:
--   * PCT_HP      13pt / y -54  ->  16pt / y   0   (dead centre, ON the portrait)
--   * PCT_POWER   10pt / y -70  ->  12pt / y -54   (the slot health just vacated)
--   * PCT_THREAT  unchanged at 10pt / y +58        (still above the 100px annulus)
--     WHY IT HAD TO MOVE. v12-v13 parked both player numbers OUTSIDE the arcs, under the
--     cluster, because a `model` region cannot carry a text sub-region and the centre is a
--     face. That reasoning was half right and the conclusion was wrong: the number does not
--     have to live on the PORTRAIT's region, it only has to land on the portrait's PIXELS —
--     and it is a sub-region of the RING, which is free to put its text wherever it likes.
--     Detached at -54 and -70 the two numbers sat over open world with nothing behind them and
--     were unreadable against a bright background, which is exactly what the field report said.
--   * DRAW ORDER, and this is the non-obvious half: moving the offset ALONE looks like nothing
--     happened if the face is stacked over the text. The portrait becomes the FIRST child of
--     `Druid - Rings` instead of the last, so every ring — and therefore every ring's text —
--     stacks above it (FixGroupChildrenOrder walks controlledChildren and adds +4 frame levels
--     per child, so FIRST = furthest behind). This also ENDS A CONTRADICTION that has sat in
--     this file since v12: the portrait is written at frameStrata 2, which is WA's BACKGROUND,
--     i.e. BELOW the inherited strata the rings use — the old comments here claimed the exact
--     opposite ("nothing ever draws over your face") and the child order was arranged to match
--     the claim rather than the data. Strata and frame level now agree, and both say the face
--     is the backdrop.
--     THIS IS SAFE BECAUSE A RING IS AN ANNULUS. Ring_20px paints diameter * 20/256 at the
--     OUTER edge, so the three bands occupy radius 42.19..50 (threat), 35.44..42 (health) and
--     26.16..31 (power) while the portrait occupies 0..22 — no ring's art touches the face at
--     all, and the only thing any of them puts over it is the text that is the whole point.
--   * REORDERING CONSUMES NO UIDS. Construction order is the seeded uid stream and is
--     untouched; only the adopt() call for the portrait moves, from the end of the group to the
--     front. controlledChildren and the flat `c` list stay depth-first consistent because
--     F.assemble derives `c` from controlledChildren, and W.verify fails the build otherwise.
--   * NOTHING ELSE CHANGED: no trigger, load gate, condition, colour, size, position, text
--     token or text colour anywhere in the pack. The threat number keeps its 10pt / +58.
--
-- v15 (THE SILL — the ring cluster becomes a 102x31 instrument strip under your feet) — see
-- README "## v15 — The Sill". NO aura is added, removed or re-uid'd: 45 tables before, 45
-- after, every uid byte-identical, so the import dialog still offers Update. What changes is
-- geometry, region type and draw order — all of which travel in the dialog's ARRANGEMENT
-- category, which must be left ticked.
--
--   THE THESIS. A ring buys gauge length with area squared and spends most of it re-drawing
--   states the eye cannot separate on a curve. A 0-100 quantity has exactly 100 distinguishable
--   states, so the lossless gauge for it is 100 PIXELS LONG: one pixel is one percent, and
--   every breakpoint becomes arithmetic instead of trigonometry —
--       x(v) = (v / maxpower - 0.5) * RAIL_LEN,  which for a 100-max resource is x = v - 50.
--   Compare v14's ring, which needed r = size/2 * 0.94; x = r*sin(2*pi*f); y = r*cos(2*pi*f)
--   and landed 20 rage on (28, 9). The cluster was 100x100 = 10,000 px2, of which the 44px
--   model was 1,936 px2 (19.4%) carrying zero decisions. The Sill is 102x31 = 3,162 px2 and
--   carries strictly more: three gauges, two numbers, three ruler ticks per rail, a 70-threat
--   notch and two rage waterlines.
--
--   THE STRIP, four stacked lanes, all offsets LOCAL to `Druid - Player Sill` which resolves to
--   ABSOLUTE (0, -110) — under the character, not on the waist:
--       plate        texture         102 x 31  at (0,  +3)
--       threat rail  progresstexture 100 x  4  at (0, +15.5)
--       health rail  progresstexture 100 x 11  at (0,  +7)
--       power rail   progresstexture 100 x 11  at (0,  -5)
--       (lane 4, the discrete-class-resource pip row, does not exist for a druid)
--   Lane stack arithmetic: 4 + 1 + 11 + 1 + 11 = 28 of content spanning local +17.5..-10.5,
--   plus a 1px margin all round and the 1px border art -> 102 x 31 centred on local (0, +3).
--
--   WHY (0, -110) AND NOT THE WAIST. A 102x37 rectangle scan of all seven packs (dynamic groups
--   projected six clones deep) is clean at y -21, -100 and -110 and dirty everywhere between.
--   -110 has the best margins by a wide margin: 11.5px to paladin's and hunter's buff rows at
--   y -80..-40 and 7.5px to the other five packs' buff rows at y -176..-136. This pack's own
--   strip is only 31 tall, so its clearance to `Druid - Buffs` (y -176..-136) is 13.5px. The
--   scan is re-run from the ASSEMBLED tables at the bottom of this file and fails the build on
--   a single overlapping pixel.
--
--   MIGRATION — every uid is recycled in place, none is drawn or discarded:
--       uid 2   Druid - Rings              -> Druid - Player Sill    (group, renamed + re-laid)
--       uid 6   Druid - Player Health Ring -> Druid - Health Rail    (84x84 ring -> 100x11 rail)
--       uid 7   Druid - Player Power Ring  -> Druid - Power Rail     (62x62 ring -> 100x11 rail)
--       uid 10  Druid - Threat (Bear)      -> same id, 100x4 rail
--       uid 11  Druid - Threat (Caster)    -> same id, 100x4 rail
--       uid 33-36 Rage Mark x4             -> power-rail WATERLINES at x -30 / +20
--       last-2  Druid - Player Portrait    -> Druid - Sill Plate     (model -> texture)
--   Re-parenting, renaming, re-typing and resizing are all free; only the uid() CALL ORDER is
--   sacred, and not one call moves.
--
--   WHAT IS LOST, said plainly:
--   * THE LIVE 3D PORTRAIT IS GONE. Its uid becomes the plate: a 102x31 Square_White_Border
--     quad in black at 45% alpha, drawn FIRST so every rail and every number sits on something
--     opaque. v14 put the health number on the face because the face was the only opaque
--     backdrop the HUD owned; the plate is that backdrop, at 1/62nd of the ink and none of the
--     decoration. The face itself never changed a druid's next button press.
--   * THE THREAT PERCENTAGE IS SWITCHED OFF, not deleted. sub.1 keeps its index (a user can
--     re-tick it in /wa) with text_visible = false. threatpct is SCALED so 100 = pulling aggro,
--     which makes it an early-warning ratio rather than a quantity you act on; a full-height
--     notch at the 70 line answers "am I close" faster than reading 68 vs 72.
--   * THERE IS NO ALARM FRAME IN THIS PACK. The Sill design gives the 80%-threat pulse to the
--     `<Pack> - Threat Flash` aura. This pack has never had one — v13's notes already record
--     that decoding v12 for `alphaPulse` returns zero hits — and inventing one would consume a
--     NEW uid for a region that has never existed here. The 70 notch and the aggro-red rail are
--     the escalation this pack ships, exactly as they were.
--
--   WHAT IS UNCHANGED, and asserted below field by field: every trigger (including the power
--   trigger that still omits use_powertype so it follows the current form), every load gate
--   (both spec gates, the not-in-arena size gate, the Bear form trigger), every condition
--   (threat escalations, health 50/25, powertype 1 rage / 3 energy, the alpha guards, the
--   out-of-combat fade) and every colour.
--
-- v16 (the number offsets were never actually applied) — see README "## v16". WeakAuras anchors
-- a subtext with text_anchorXOffset / text_anchorYOffset; SubText.lua's own default() writes the
-- bare anchorXOffset / anchorYOffset and NOTHING reads them, and no Modernize step bridges the
-- two. Both spellings are now written and kept equal by F.subtextOffset, which is the only
-- sanctioned way to move a number in this repo.
--
-- v17 (the rails were filling the wrong way) — see README "## v17". orientation = "HORIZONTAL"
-- is the LEFT-ANCHORED fill on a progresstexture; the dropdown label lies
-- (HORIZONTAL_INVERSE is captioned "Left to Right" and is right-anchored).
--
-- v18 (LONG AND THIN, NOT BIG) — see README "## v18 — long and thin, not big". PURELY geometry:
-- no aura added, removed, renamed, re-parented or re-triggered, 45 tables before and after,
-- every uid byte-identical (changed = 0, missing = 0, parentSame = true, NO allowance list), so
-- the import dialog still offers Update. Not one trigger, load gate, condition, colour, spell id
-- or region type moves; the form-adaptive power trigger (no use_powertype) is untouched, and so
-- are both spec-gated threat rails.
--
--   THE ARGUMENT. v15-v17's rails were 100x11 on a 102x31 plate, which read as too SHORT. The
--   sibling packs answered that by scaling the whole strip UNIFORMLY, and the player rejected it
--   twice — at 300px rails and again at 200px — because a uniform scale preserves the original
--   2.8:1 plate and just makes the same stubby block bigger: it reads as a UI panel, not as a
--   readout. A vitals bar wants to be LONG AND THIN. The fill's TRAVEL is the signal; its
--   thickness carries nothing. So the length goes up 60% and the height goes back near the
--   original.
--
--     rails    100 x 11  ->  160 x 13        plate   102 x 31  ->  164 x 36
--     threat   100 x  4  ->  160 x  5        number   11pt @ +32 -> 12pt @ +51
--     ruler      1px     ->    2px           waterlines  3/5px  ->  4/8px
--     threat number 10pt ->  9pt, still switched off, still parked at x -32
--
--   WHY 160 AND NOT A ROUND NUMBER: 1.6 pixels per percent. Every value this pack marks is a
--   multiple of five and 1.6 x 5 = 8, so every mark still lands on a WHOLE pixel — 20 rage at
--   -48, 70 rage and the threat notch at +32, the ruler at -40 / 0 / +40. The invariant was
--   never the number 100; it is that waterX() is the only place a coordinate is derived.
--
--   THE LANE STACK IS DERIVED, NOT COPIED. This pack has THREE lanes (a druid has no discrete
--   class resource) and its plate has sat at local y +3 since v15, so the offsets fall out of
--   that convention rather than out of rogue's: content 5 + 1 + 13 + 1 + 13 = 33 centred on +3
--   spans -13.5..+19.5, giving threat +17, health +7 (unchanged) and power -7, with 1.5px of
--   margin above AND below inside a 36px plate. The build asserts the arithmetic, the gutters
--   and the evenness of those margins.
--
--   NOTHING MOVES ON SCREEN, AND THAT IS MEASURED. The plate grows by 5px of height, so the
--   frontier was re-scanned before anything was changed: the strip stays at (0,-110), clears
--   every other region in the pack by 11.0px (the buff row below; v17 had 13.5px), has nothing
--   above it at all, and would still clear by 7.0px if this pack ever grew the profile's +-4px
--   alarm rim. It does NOT grow one: this pack has never had a threat flash, and inventing one
--   would consume a new uid for a region that has never existed here. The build additionally
--   runs an ALL-PAIRS check across the four flanking stacks (Buffs / Alerts / Cooldowns / PvP),
--   which the sill-versus-everything scan structurally cannot see; tightest is 14px.
--
-- The three auras v13 deleted, declared for the verifier (tools/verify-packs.lua reads these
-- lines). They were the LICENCE for three disappearing uids, and that licence has now EXPIRED
-- BY ITSELF: the tag carries the version, verify-packs.lua honours only tags matching the
-- version the pack currently ships, and this pack ships v14. Nothing is deleted in v14, the
-- three ids are already absent from the v13 string every continuity check compares against, and
-- W.assertUidContinuity below is therefore called with NO allowance — the strict default, where
-- any disappearing uid is a hard failure. The list stays as the REMOVAL PROOF's input (nothing
-- may quietly come back) and as the record of what a player still has to delete by hand.
-- WA-REMOVED (v13): Druid - Target Health Ring
-- WA-REMOVED (v13): Druid - Target Ring Track
-- WA-REMOVED (v13): Druid - Target Portrait
local REMOVED_V13 = {
  "Druid - Target Health Ring",
  "Druid - Target Ring Track",
  "Druid - Target Portrait",
}

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

-- ===== CANONICAL SILL GEOMETRY (v18) — SHARED BY ALL SEVEN CLASS PACKS =====
-- These numbers are the contract. They are identical in every tbc/*/generate.lua and MUST NOT
-- be edited in one pack alone: v9 exists only because seven packs each picked their own
-- diameters and the HUD read as uneven. Derive from them; never hand-write a size, a colour or
-- an offset anywhere below.
--
-- A VITALS BAR WANTS TO BE LONG AND THIN (v18). The fill's TRAVEL is the signal; its thickness
-- carries nothing. v15-v17 shipped 100x11 rails on a 102x31 plate, which read as too SHORT, and
-- the sibling packs' answer — scale the whole strip uniformly — was rejected twice in play at
-- 300px and 200px rails, because it preserved the 2.8:1 plate and simply made the same stubby
-- block bigger, i.e. a UI panel rather than a readout. The profile below keeps the length and
-- puts the height back near the original: rails 60% longer than v17's, on a plate that is only
-- 5px taller.
--
-- WHY 160 AND NOT A ROUND NUMBER. 1.6 PIXELS PER PERCENT. Every value this pack marks is a
-- multiple of five (20 and 70 rage, the 70-threat notch, the 25/50/75 ruler) and 1.6 x 5 = 8,
-- so every mark still lands on a WHOLE pixel — asserted mark by mark at the bottom of this
-- file. The invariant was never the number 100; it is that waterX() is the only place a
-- coordinate is derived, so the length is one constant.
--
-- LANE ASSIGNMENT — stacked rails, top to bottom, in ascending decision frequency order
-- reading downward from the character:
--   1  threat   160 x  5   thinnest, because it is a warning and not a quantity, and no number
--   2  health   160 x 13
--   3  power    160 x 13
--   4  class resource — DOES NOT EXIST FOR A DRUID. Rage, energy and mana are all continuous
--      pools already carried by lane 3, so this pack has THREE lanes: 5 + 1 + 13 + 1 + 13 = 33
--      of content, where a four-lane pack (rogue's combo pips, mage's arcane charges) has 42.
--      The plate is 36 rather than 45, and it sits at this pack's own local y +3 rather than 0
--      (see LANE_PLATE) — the lane offsets below are DERIVED from that convention, not copied.
local RAIL_TEX  = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White.tga"
local PLATE_TEX = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White_Border.tga"
local RAIL_LEN  = 160  -- 1.6 pixels per percent; every marked value is a multiple of 5
local THREAT_H  =   5
local HEALTH_H  =  13
local POWER_H   =  13
local PLATE_W   = 164  -- RAIL_LEN + 4: 2px of margin each side
local PLATE_H   =  36  -- 5 + 1 + 13 + 1 + 13 = 33 of content + 1.5px margin top and bottom

-- ABSOLUTE screen centre of the strip. (0, -110) is UNDER the character, not on its waist, and
-- v18 does NOT move it: the new plate is 164x36 where v17's was 102x31, i.e. only 5px taller,
-- and the rectangle scan at the bottom of this file reports 11.0px of clearance to the buff row
-- below (v17 had 13.5px) with nothing above the strip at all. Nothing in this pack has to move
-- to make room, which is measured rather than assumed — see the frontier numbers in the scan
-- block, which also reports the margin a hypothetical +-4px alarm rim would leave (7.0px).
local SILL_X =    0
local SILL_Y = -110

-- Lane offsets, LOCAL to the sill group, DERIVED from this pack's own plate convention rather
-- than copied from a four-lane pack. The plate centre is local y +3 (it has been since v15), the
-- content is 33 tall, so the stack spans +3 +- 16.5 = -13.5 .. +19.5 and every lane centre falls
-- out of it, top down, with 1px gutters:
--     threat  +19.5 - 5/2            = +17
--     health  +19.5 - 5 - 1 - 13/2   =  +7
--     power   +19.5 - 5 - 1 - 13 - 1 - 13/2 = -7
-- The plate is 36, so the margin is 1.5px top AND bottom — asserted for evenness at the bottom
-- of this file, together with the 1px gutters and the whole-stack fit.
local LANE_PLATE  = { x = 0, y =   3 }
local LANE_THREAT = { x = 0, y =  17 }
local LANE_HEALTH = { x = 0, y =   7 }
local LANE_POWER  = { x = 0, y =  -7 }

-- Numbers, printed INSIDE the rail that owns them so each appears and vanishes with its readout
-- and neither of them ever prints onto open screen again. anchorXOffset +51 puts the digits at
-- the right-hand end of a 160px rail (which spans -80..+80 about its own centre): "100%" at 12pt
-- is at most 4 glyphs of ~8px, so it spans +35..+67 and stays 13px inside the rail's edge.
-- text_anchorPoint stays CENTER, which is the only anchor proven on a progresstexture in this
-- repo; INNER_RIGHT is proven on aurabars and icons only. 12pt also fits INSIDE the 13px lane it
-- prints in, which is the other half of "the number lives in the rail".
--   THREAT is the exception: it is SWITCHED OFF (text_visible = false), not deleted, because
--   threatpct is scaled so 100 = pulling aggro and is therefore a ratio rather than a quantity.
--   It keeps sub.1 so /wa can re-tick it, and v18 leaves it exactly WHERE IT ALREADY IS, parked
--   at x -32: still comfortably inside the longer rail, still nowhere near the health percentage
--   at +51 if a user re-ticks it, and moving a hidden number would be churn. Only its size
--   follows the profile, 10pt -> 9pt.
local PCT_HP     = { size = 12, x =  51, y = 0 }
local PCT_POWER  = { size = 12, x =  51, y = 0 }
local PCT_THREAT = { size =  9, x = -32, y = 0, visible = false }

-- ABSOLUTE -> LOCAL. SILL_X/SILL_Y are screen coordinates, but these regions are nested two
-- groups deep and WeakAuras anchors a child to its group (anchorFrameType "SCREEN" resolves to
-- the parent frame for a grouped aura), so the on-screen position is the SUM of every offset
-- down the chain. The two group offsets are therefore constants, and the conversion happens
-- exactly once, here — never at a call site. TOP + SILLG already summed to (0, -110) in v14
-- (top -140 + the layer's +30), which is exactly where the Sill wants to be, so NEITHER GROUP
-- OFFSET MOVES: the whole change is that the leaves stop carrying a local (-270, +150) and
-- carry the lane table instead. The assembled string is re-walked and asserted at the bottom of
-- this file, so a future edit to either group offset fails the build instead of quietly sliding
-- the strip somewhere else.
local TOP_X,   TOP_Y   = 0, -140  -- the pack's draggable top-level group
local SILLG_X, SILLG_Y = 0,   30  -- the sill layer inside it: -140 + 30 = -110
local function localX(absX) return absX - (TOP_X + SILLG_X) end
local function localY(absY) return absY - (TOP_Y + SILLG_Y) end

-- RESOURCE BREAKPOINT WATERLINES. On a ring a threshold was a point on the circumference and
-- needed trigonometry. On a rail it is one subtraction:
--   x(v) = (v / maxpower - 0.5) * RAIL_LEN
-- measured from the centre of the rail the mark belongs to. The general form is written out
-- rather than the shortcut because a cap-raising talent (a rogue's Vigor, 100 -> 110) changes
-- maxpower and must move the mark; see gotchas.md.
-- Written as (v*len)/max - len/2 rather than (v/max - 0.5)*len: they are the same number in
-- exact arithmetic, but the second form routes an integer answer through 0.7 - 0.5 and lands on
-- 31.999999999999996 for 70 rage at RAIL_LEN 160. The build asserts EXACT pixel positions, so
-- the algebra has to be arranged to stay on integers wherever the inputs are integers.
-- THIS IS THE ONLY PLACE A MARK COORDINATE IS DERIVED (v18). At 1.6px per percent every value
-- this pack marks is a multiple of five, and 1.6 x 5 = 8, so every mark is still a whole pixel:
--   20 rage -> -48    70 rage / the threat notch -> +32    ruler 25/50/75 -> -40 / 0 / +40
local function waterX(value, maxValue) return value * RAIL_LEN / maxValue - RAIL_LEN / 2 end
-- Waterline widths, scaled with the rail (v18: 3/5 -> 4/8). A breakpoint is a FULL-HEIGHT line
-- across the rail, not a dot beside it: the dim line is the permanent "this is where 20 rage
-- is", the lit twin is twice as fat and pops in when you cross it, which is how the crossing
-- reads at a glance. A ruler hairline is a HINT and stays a hairline (2px on a 160px rail); the
-- 70-threat notch stays 2px as well, because against a 5px rail it is already a hairline and
-- widening it would turn the top lane into a two-tone bar.
local WATER_DIM = 4
local WATER_LIT = 8
local RULE_W    = 2
local NOTCH_W   = 2
-- The ruler: three hairlines at 25 / 50 / 75 percent, at 18% white. Zero footprint, and it
-- converts a rail from "estimate a fraction" into "count quarters".
local RULER_AT = { waterX(25, 100), waterX(50, 100), waterX(75, 100) }

local byId = {}
local function reg(t) byId[t.id] = t; return t end
local function adopt(parent, child)
  child.parent = parent.id
  table.insert(parent.controlledChildren, child.id)
end
-- SAME ADOPTION, OPPOSITE END OF THE STACK. controlledChildren is the sibling DRAW ORDER —
-- FixGroupChildrenOrder walks it and adds +4 frame levels per child, so FIRST is furthest
-- BEHIND — and it is completely independent of the seeded uid stream, which is fixed by
-- CONSTRUCTION order. v14 needs the portrait at the back of its group so the rings' percentage
-- text lands on the face instead of under it, and the portrait is constructed near the bottom
-- of this file (uid discipline), so it is adopted at the front instead of the end. No uid()
-- call moves, none is consumed; F.assemble derives the flat `c` list from controlledChildren,
-- so the transmit stays depth-first consistent and W.verify proves it.
local function adoptFirst(parent, child)
  child.parent = parent.id
  table.insert(parent.controlledChildren, 1, child.id)
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
local top     = F.group(TOP, TOP_X, TOP_Y, nil)
-- uid slot 2, RENAMED for the fifth time and re-uid'd for the zeroth. v7 called this
-- "Druid - Resources" at (0,56) and parked a 172x14 bar stack in the middle of the screen;
-- v8-v9 made it the ring-orb layer, v10-v11 the globe layer, v12-v14 "Druid - Rings". v15 makes
-- it `Druid - Player Sill` — the same table, the same uid, the same (0,30) offset — because
-- (0,30) under a top group at (0,-140) already resolves to the Sill's canonical ABSOLUTE
-- (0,-110). Nothing about the group moves; its nine children stop carrying a local (-270,+150)
-- and carry the lane table instead. WA matches by uid, so the rename is invisible to an Update.
local gRes    = reg(F.group("Druid - Player Sill", SILLG_X, SILLG_Y, nil))
local gBuffs  = reg(F.group("Druid - Buffs", 0, -16, nil))
local gAlerts = reg(F.dynGroup("Druid - Alerts", -150, 96, nil, "UP", "BOTTOM", 6))
local gCDs    = reg(F.dynGroup("Druid - Cooldowns", 0, -66, nil, "HORIZONTAL", "CENTER", 4))
adopt(top, gRes)
adopt(top, gBuffs)
adopt(top, gAlerts)
adopt(top, gCDs)

-- ================= v15 The Sill — state drawn as an instrument under your feet ==============
-- One strip inside the group that used to hold the centre bar stack, then the v8-v9 rings, the
-- v10-v11 globes and the v12-v14 clusters: three 160px rails, two numbers printed inside them,
-- a ruler on each rail and two rage waterlines, all on one dark plate at absolute (0, -110).
-- The middle of the screen stays empty, which is what v8 bought and no version since has spent.
--
-- Every READOUT keeps the trigger, gate and escalation it had as a ring; what changes is the
-- shape, the fill path and where the number sits.
local COL = {
  -- Canonical palette, identical in all seven packs — not one value changes in v15.
  health = { 0.15, 0.82, 0.28, 1 },     -- the health rail
  mana   = { 0.20, 0.45, 0.95, 1 },     -- caster/tree/moonkin power rail
  rage   = { 0.75, 0.15, 0.15, 1 },     -- bear
  energy = { 0.90, 0.80, 0.20, 1 },     -- cat
  track  = { 0, 0, 0, 0.55 },           -- the UNFILLED part of every rail
  -- Pack escalations, carried across from v7-v14 unchanged.
  threat = { 0.25, 0.80, 0.30, 1 },  -- v7's threat-bar green
  warn   = { 1.00, 0.60, 0.10, 1 },  -- threat >= 70%
  hurt   = { 1.00, 0.65, 0.10, 1 },  -- health < 50%
  danger = { 0.90, 0.12, 0.12, 1 },  -- aggro lost / gained, health < 25%
  text   = { 1, 1, 1, 1 },
  -- v15 additions: the plate the whole instrument is drawn on, and the ruler ink.
  plate  = { 0, 0, 0, 0.45 },        -- black at 45%: opaque enough to survive snow and lava
  ruler  = { 1, 1, 1, 0.18 },        -- the 25/50/75 hairlines
  notch  = { 1, 1, 1, 0.85 },        -- the 70-threat notch on the threat rail
}

-- Square_White.tga is a flat white quad and ships inside WeakAuras (Private.texture_types),
-- as does Square_White_Border.tga, the same quad with a 1px inset outline; wa_factory names
-- both as F.TEX_SQUARE / F.TEX_SQUARE_BORDER and the other packs' pips already use the border
-- variant. The v10-v14 Ring_20px annulus is gone from this file: an annulus can only be filled
-- on the CIRCULAR path, and the texture and the orientation change together or not at all.
local IV, TOC = 45, 20501

-- wa_factory has no progresstexture builder, so that region table is written out in full below
-- and needs the same scaffolding stub() applies inside the factory.
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

-- v10 retires the PINNED-mana trigger (use_powertype + powertype 0 + use_requirePowerType)
-- along with the target's mana readout it fed. The globe layout has three vessels and the
-- target's is its health; a fourth vessel for a number that never changes a druid's next
-- button press is exactly the kind of tracker this pack is supposed to cut.

-- THE THREAT TRIGGER'S UNIT ARG IS `threatUnit` ON IV-45 DATA (v13 correction). F.threatTrigger
-- emits use_threatUnit/threatUnit = "target", which is the ERA-CORRECT pair: the Threat Situation
-- prototype renamed that argument to `unit` at internalVersion 51, and Modernize migrates < 51
-- data forward, so an IV-45 string must emit the OLD name and let the migration rename it on
-- load. v12 wrapped the factory trigger in an orbThreat() that ADDITIONALLY set `unit = "target"`,
-- on the belief that threatUnit was dead data; it is the other way round, and an IV-51+ field on
-- IV-45 data is at best ignored. The wrapper is gone and the factory trigger is used unchanged —
-- it reads the target with the same default it always had.

-- THE RAIL. The SAME progresstexture region the rings and the globes used, moved onto the LINEAR
-- path — and the fields that are traps, in the order they bite:
--   orientation HORIZONTAL -> "Left to Right". Private.orientation_with_circle_types is
--     transcribed verbatim in poc/diablo-globes/generate.lua:
--       HORIZONTAL = "Left to Right"   HORIZONTAL = "Right to Left"
--       VERTICAL = "Bottom to Top"             VERTICAL_INVERSE = "Top to Bottom"
--     The key lies about the direction in the usual WA way, and it lies DIFFERENTLY from the
--     aurabar, where HORIZONTAL is left-anchored and grows right (gotchas.md). On a
--     progresstexture, left-to-right is HORIZONTAL. VERTICAL from that same table is
--     live in the shipped poc/diablo-globes string, so the linear path itself is proven here;
--     HORIZONTAL is the one field in v15 that no committed string in this repo has
--     rendered. 30-second in-game check: at full resource the rail is solid; drop to ~50% and
--     the EMPTY half must be on the RIGHT. If it is reversed the fix is one token, HORIZONTAL.
--   startAngle 0 / endAngle 360 -> IGNORED on the linear path. Emitted for the schema.
--   backgroundColor = COL.track -> the UNFILLED part of the rail. backgroundOffset 0 keeps it
--     exactly the same quad as the fill; the default 2 fattens it into a halo around the rail.
--   crop_x / crop_y = 0.41 -> on the CIRCULAR path this was the identity that cancels a sqrt(2)
--     expansion; on the linear path it is simply the texcoord scale, and with a UNIFORM
--     Square_White.tga it cannot alter the art at all. Kept at 0.41 so the value never has to
--     mean two things in one repo.
--   compress / slanted / slant / slantMode -> INERT on a ring, LIVE here. compress false and
--     slanted false is a straight, uncompressed bar, which is the whole point of a ruler.
--   auraRotation = 0 -> absent from the 3.5.0 default table but read unconditionally by
--     current code as data.auraRotation / 180 * math.pi, so it must be emitted.
--   adjustedMin/Max are STRINGS, because SetAdjustedMin does adjustedMin:find(...).
--   progressSource is rewritten to {-1, ""} (Automatic) by Modernize < 71 whatever is
--     emitted, which is why each rail has exactly ONE progress-supplying trigger and it is
--     trigger 1: activeTriggerMode -10 is first_active, and Automatic reads that trigger's
--     value/total. A second trigger can only feed conditions, never the fill — which is why
--     health and power cannot share a region, and therefore why the strip is stacked lanes.
--   foregroundColor is the conditionable tint on a progresstexture. It is `barColor` on an
--     aurabar and `color` on a plain texture, and Conditions.lua skips an unknown property
--     SILENTLY — which is also the decisive reason these rails are not aurabars. The other
--     reason is structural: an aurabar requires subRegions[1] = {type = "aurabar_bar"}, which
--     would shift every existing sub.N index by one and silently retarget every condition that
--     addresses one.
-- `lane` is one of the LANE_* tables at the top of the file: a local offset inside the sill
-- group, never a screen coordinate written at a call site.
local function rail(id, height, lane, color, triggerList, gate)
  return reg(stub{
    regionType = "progresstexture", id = id, uid = W.uid(), parent = nil,
    width = RAIL_LEN, height = height,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = localX(SILL_X) + lane.x, yOffset = localY(SILL_Y) + lane.y,
    frameStrata = 1, alpha = 1,
    orientation = "HORIZONTAL", startAngle = 0, endAngle = 360,
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
    triggers = F.triggers(triggerList),
    load = F.load(CLASS, gate),
  })
end

-- A SUBTEXTURE on a progresstexture — the ruler hairlines and the threat notch. Field set taken
-- verbatim from the shipped `Hunter - Mana` sub.2/sub.3 and `Rogue - Energy Ring` sub.2-5, which
-- is the only form of this sub-region proven in this repo. anchor_mode "point" with self_point
-- and anchor_point CENTER makes xOffset/yOffset a plain offset from the rail's centre, which is
-- exactly the coordinate system waterX() speaks.
local function subtex(w, h, x, y, color)
  return {
    type = "subtexture",
    anchor_area = "ALL", anchor_mode = "point", anchor_point = "CENTER", self_point = "CENTER",
    width = w, height = h, xOffset = x, yOffset = y,
    scale = 1, mirror = false, rotate = false,
    textureBlendMode = "BLEND", textureColor = color,
    textureDesaturate = false, textureMirror = false, textureRotate = false, textureRotation = 0,
    textureTexture = RAIL_TEX, textureVisible = true,
  }
end
-- The ruler, APPENDED after everything the rail already carries. Sub-region indexes are
-- positional and conditions address them by index, so this may only ever append.
local function ruler(region)
  for _, x in ipairs(RULER_AT) do
    region.subRegions[#region.subRegions + 1] = subtex(RULE_W, region.height, x, 0, COL.ruler)
  end
  return region
end

-- v13 retires the TRACK RING helper along with the region it built. It existed only to give the
-- TARGET cluster a base groove under its threat arc, so that a resto druid — who loads neither
-- threat aura — still saw two arcs on the target where the player side had two. With the target
-- cluster gone there is nothing to balance: the player cluster's own health and power rings are
-- unconditional, and each already draws its unfilled arc in COL.track as its own background.
-- The threat ring simply is not there when threat is not real, which is the honest readout.
-- (FIELD-NAME TRAP it documented, kept for the next person: on a `texture` region the
-- conditionable tint is `color`; on a progresstexture it is `foregroundColor` and on an aurabar
-- `barColor`, and Conditions.lua skips an unknown property silently.)

-- THE SILL PLATE, and this is where the 3D portrait's uid goes (v15). A `model` region is
-- re-typed to a `texture` region — free, exactly as v10 re-typed globe rims and v12 re-typed
-- them back, because WA matches by uid and the region type is just data. What was a 44x44 live
-- face becomes a 164x36 dark quad with a 1px border, drawn FIRST in the group so every rail,
-- every number and every waterline sits on something opaque.
--   WHY IT EARNS ITS PIXELS. The field complaint the ring versions kept chasing was legibility:
--   "a bright floor or a fire washed it out". v14's answer was to print the health number on the
--   portrait, because the face was the only opaque thing the HUD owned. The plate is that same
--   answer without the 1,936 px2 of decoration — and it is also what makes four separate bars
--   read as ONE instrument instead of four floating things.
--   COLOUR IS EXPLICIT, ALWAYS. On a `texture` region the tint field is `color`; leaving it
--   empty draws in WeakAuras' default rather than the intended shade (the sibling rogue pack
--   has shipped exactly that bug on its Threat Flash). COL.plate is black at 45%.
--   frameStrata 2 is WA's BACKGROUND — the LOWEST strata, below the inherited 1 the rails use.
--   The plate inherits that field from the portrait unchanged, and it is finally telling the
--   truth: this region IS the backdrop, and it is also first in controlledChildren, so strata
--   and frame level agree instead of contradicting each other.
-- The plate carries the portrait's Health + Unit Characteristics trigger pair and both of its
-- conditions unchanged, so the whole instrument fades out of combat and vanishes as one object.
local function plate(id, lane, triggerList)
  return reg(stub{
    regionType = "texture", id = id, uid = W.uid(), parent = nil,
    texture = PLATE_TEX, desaturate = false,
    width = PLATE_W, height = PLATE_H, alpha = 1,
    color = COL.plate, blendMode = "BLEND", textureWrapMode = "CLAMPTOBLACKADDITIVE",
    rotation = 0, discrete_rotation = 0, mirror = false, rotate = false,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = localX(SILL_X) + lane.x, yOffset = localY(SILL_Y) + lane.y, frameStrata = 2,
    subRegions = {},
    triggers = F.triggers(triggerList),
    load = F.load(CLASS),
  })
end

-- WHERE THE NUMBERS LIVE (v15). A progresstexture accepts a subtext (SubText's supports() lists
-- texture / progresstexture / icon / aurabar / empty), so every number is a sub-region of the
-- RAIL it reports and appears and vanishes with it: no threat table, no threat number. v12-v14
-- had to solve "the centre of the cluster is a face"; a rail has no centre problem — the number
-- goes INSIDE the bar, at the right-hand end, on the plate. text_anchorPoint stays CENTER (the
-- only anchor this repo has proven on a progresstexture) and anchorXOffset does the work.
-- The size/offset triple comes from one of the three canonical placements (PCT_HP / PCT_POWER /
-- PCT_THREAT), never from a call site, so no two packs and no two numbers can drift apart.
local function pct(sym, place, color)
  local st = F.subtext("%" .. sym .. "%%", place.size, "CENTER", sym)
  F.subtextOffset(st, place.x, place.y)
  st.text_color = color
  if place.visible == false then st.text_visible = false end
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

-- ===== the four rails, in the v7 uid order they inherit =====
-- CONSTRUCTION order below is uid order and MUST NOT CHANGE — not even where a region has been
-- deleted. Two of v12's six slots (8 and 9) are now RETIRED: their W.uid() calls are still made,
-- in place, and the value is thrown away, because the seeded stream is positional and dropping a
-- call outright would shift every uid drawn after it. A retired slot is not a filler region: it
-- builds nothing, ships nothing and can never be re-issued to a future aura.
-- DISPLAY order is set separately by the adopt() calls at the end of this section:
-- FixGroupChildrenOrder walks controlledChildren and adds +4 frame levels per child, so
-- EARLIER = further behind.

-- uid 6 (v7 "Druid - Health", v8-v9 "Druid - Player Health", v10-v11 "Druid - Life Globe",
-- v12-v14 "Druid - Player Health Ring"). THE HEALTH RAIL, 160x13 — lane 2, the widest gauge in
-- the strip because it is the one you read most.
-- Trigger 2 is the always-on Unit Characteristics feeder that v7's bars used for the
-- out-of-combat fade; it never gates visibility and trigger 1 stays the progress source.
-- The escalations are v8's, untouched: amber under 50%, red under 25% (severe condition last,
-- so it wins), on `foregroundColor`. The last condition is the zero-total guard: an aurabar with
-- total 0 draws EMPTY but a progresstexture draws FULL, and UnitHealthMax has no floor, so a
-- unit whose max health has not streamed yet would flash a complete rail.
-- v15 appends the ruler at sub.2-4 — three 1px hairlines at 25 / 50 / 75 — which is what turns
-- the rail from "estimate a fraction" into "count quarters". sub.1 keeps the percentage.
local playerHP = rail("Druid - Health Rail", HEALTH_H, LANE_HEALTH, COL.health,
  { orbHealth("player"), F.unitCharTrigger() })
playerHP.subRegions[1] = pct("percenthealth", PCT_HP, COL.text)
ruler(playerHP)
playerHP.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "percenthealth", "<", "50", "foregroundColor", COL.hurt),
  F.condition(1, "percenthealth", "<", "25", "foregroundColor", COL.danger),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

-- uid 7 (v7 "Druid - Rage", v8-v9 "Druid - Player Power", v10-v11 "Druid - Power Globe",
-- v12-v14 "Druid - Player Power Ring"). THE POWER RAIL, 160x13 — lane 3, and it is one gauge for
-- all three of the druid's resources. The trigger is form-adaptive (no use_powertype), and the
-- resolved type is a stored, conditionable arg (`powertype`, init = powerTypeToCheck,
-- conditionType select), so the rail is coloured for the power type it actually reads: mana blue
-- as the base, rage red in bear, energy yellow in cat. Numeric select values compile correctly —
-- Conditions.lua takes the tonumber branch. Both conditions are kept VERBATIM.
-- No load gate at all: every druid has a primary resource in every form. v7's rage bar was
-- Feral-gated and Bear-form-gated, so a feral in caster form saw no resource bar whatsoever.
-- The number is `%percentpower%%` and stays that way: rage and energy both cap at 100, so on a
-- 0-100 scale the percentage IS the absolute value, and mana is the one resource where percent
-- is the right reading anyway. Ruler appended at sub.2-4.
local playerPower = rail("Druid - Power Rail", POWER_H, LANE_POWER, COL.mana,
  { orbPower("player"), F.unitCharTrigger() })
playerPower.subRegions[1] = pct("percentpower", PCT_POWER, COL.text)
ruler(playerPower)
playerPower.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "powertype", "==", 1, "foregroundColor", COL.rage),
  F.condition(1, "powertype", "==", 3, "foregroundColor", COL.energy),
  F.condition(1, "maxpower", "<=", "1", "alpha", 0),
}

-- uid 8 — RETIRED SLOT (v7 "Druid - Mana (Resto)", v8-v9 "Druid - Target Health", v10-v11
-- "Druid - Target Globe", v12 "Druid - Target Health Ring"). The target's health ring is DELETED
-- in v13: it was a second copy of the target frame and the nameplate, which every player already
-- reads. The draw stays because the uid stream is POSITIONAL — remove the call and uid 10 becomes
-- what uid 9 was, and every aura after it in the file changes identity on the next import.
W.uid()  -- retired: Druid - Target Health Ring (never re-issue this uid)

-- uid 9 — RETIRED SLOT (v7 "Druid - Mana (Balance)", v8-v9 "Druid - Target Mana", v10-v11
-- "Druid - Target Globe Rim", v12 "Druid - Target Ring Track"). The track existed only to keep
-- the target cluster looking like a matched pair for a resto druid who loads neither threat
-- aura. With the target cluster gone there is no pair to match, and the player's own rings each
-- draw their unfilled arc in COL.track already.
W.uid()  -- retired: Druid - Target Ring Track (never re-issue this uid)

-- uid 10 — Threat (Bear), id unchanged since v7. THREAT IS THE TOP LANE (v15), 160x5 since
-- v18: the thinnest rail in the strip, because it is a warning and not a quantity. It is still YOUR
-- threat, as v13 made it, and it is still the one thing on screen nothing else shows.
-- Tank-inverted semantics preserved from v7: green while you are securely tanking, RED the
-- moment aggro is lost. The percentage is SWITCHED OFF (PCT_THREAT.visible == false), because
-- threatpct is scaled so 100 = pulling aggro — a ratio, not a quantity you spend — and a
-- full-height notch at the 70 line answers "am I close" faster than reading 68 against 72.
-- The threatvalue guard is NOT cosmetic and is mandatory: threattotal is
-- (threatvalue or 0) * 100 / threatpct, so it is 0 whenever threatvalue is 0 — post-Vanish,
-- post-Feign, the instant before your first hit lands — and a progresstexture with total 0 draws
-- FULL, which would read as complete aggro at exactly zero threat. alpha 0 removes the rail
-- entirely, which is precisely the "no threat table" state: with no hostile target, or before
-- your first point of threat, lane 1 is simply empty.
-- sub.2 is the 70 NOTCH, appended after the (now hidden) percentage so no index moves. Its x
-- comes from the same waterX() every breakpoint in the pack uses, so it cannot drift from the
-- scale it marks. On the bear rail it reads as the floor you must stay ABOVE; on the caster rail
-- below it is the ceiling you must stay under, and the orange condition fires on the same value.
local threatF = rail("Druid - Threat (Bear)", THREAT_H, LANE_THREAT, COL.threat,
  { F.threatTrigger() }, notInArena(GATE_F))
threatF.subRegions[1] = pct("threatpct", PCT_THREAT, COL.text)
threatF.subRegions[2] = subtex(NOTCH_W, THREAT_H, waterX(70, 100), 0, COL.notch)
threatF.conditions = {
  F.condition(1, "aggro", "==", 0, "foregroundColor", COL.danger),
  F.condition(1, "threatvalue", "<=", "0", "alpha", 0),
}

-- uid 11 — Threat (Caster), id unchanged since v7. The SAME lane-1 rail, at the same 160x5 in
-- the same place: the two are mutually exclusive spec gates (Mangle (Bear) vs Moonkin Form) and
-- only one can ever load, so they share the slot exactly as they have since v7. Non-inverted
-- semantics: green, orange at 70% of the pull threshold, red when you pull (severe condition
-- last, so it wins) — which is exactly where the notch sits.
local threatB = rail("Druid - Threat (Caster)", THREAT_H, LANE_THREAT, COL.threat,
  { F.threatTrigger() }, notInArena(GATE_B))
threatB.subRegions[1] = pct("threatpct", PCT_THREAT, COL.text)
threatB.subRegions[2] = subtex(NOTCH_W, THREAT_H, waterX(70, 100), 0, COL.notch)
threatB.conditions = {
  F.condition(1, "threatpct", ">=", "70", "foregroundColor", COL.warn),
  F.condition(1, "aggro", "==", 1, "foregroundColor", COL.danger),
  F.condition(1, "threatvalue", "<=", "0", "alpha", 0),
}

-- DISPLAY order (v15). Sibling stacking is exact, not "roughly creation order":
-- FixGroupChildrenOrder walks controlledChildren and adds +4 frame levels per child, so EARLIER
-- = further behind. The Sill's canonical order is
--     plate, threat rail, health rail, power rail, [lane-4 pips], waterlines, [alarm frame]
-- The PLATE MUST BE FIRST — it is the opaque backdrop every rail and every number is legible
-- against — and it gets there with adoptFirst() in the block at the bottom of this file where it
-- is constructed (construction order is the seeded uid stream and cannot move; adoption order
-- is free). The WATERLINES MUST COME AFTER THE POWER RAIL or they draw underneath it; they are
-- adopted in the v2 block, which runs after this one, so they land last by construction.
-- This pack has no lane-4 pip row and no alarm frame (see the v15 header note).
adopt(gRes, threatF)
adopt(gRes, threatB)
adopt(gRes, playerHP)
adopt(gRes, playerPower)

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

-- R7-R10 Rage thresholds — the bear's two spend decisions, and in v15 they are WATERLINES again.
-- v7 drew them as vertical lines over a 172x14 bar; v10-v11 as horizontal lines across a vessel;
-- v12-v14 as round pips ON the circumference of a ring, which needed
--   r = INNER/2 * 0.94 ; x = r*sin(2*pi*f) ; y = r*cos(2*pi*f)
-- and landed 20 rage at (28, 9) — a dot whose position you had to learn. On a rail the same
-- threshold is one subtraction, waterX(v, max) = (v/max - 0.5) * RAIL_LEN, and at v18's 160px
-- (1.6px per percent) both marks are still whole pixels because both values are multiples of 5:
--   20 rage -> x -48      70 rage -> x +32        (rage is a flat 0-100 pool in TBC)
-- and it is a FULL-HEIGHT LINE ACROSS the rail, at exactly the pixel the fill reaches at that
-- value, so "have I got 20 rage" is answered by whether the fill edge has passed the line.
--
-- ROUND PIPS ARE GONE WITH THE RING, and the reason they had to be round is gone with it too:
-- rotating a thin quad on a texture region rotates the ART INSIDE the quad (DoTexCoord ->
-- GetRotatedPoints), so a straight line could never be laid ALONG an arc. Across a horizontal
-- rail no rotation is needed at all, so these are Square_White quads: 4px wide dim, 8px lit,
-- both POWER_H tall so they span the rail exactly.
--
-- These stay FOUR SEPARATE AURAS rather than becoming sub-regions of the rail, deliberately:
-- the aurabar tick sub-region cannot come along at all (SubRegionTypes/Tick.lua's supports()
-- returns true only for "aurabar"), and the two sub-region types that DO support
-- progresstexture would cost the pop. A subtexture mark can change colour by condition but
-- cannot carry its own animation, and the pop-in on crossing IS the signal here. Keeping them
-- as regions also keeps their triggers, their Feral gate and their v7 Bear form gate exactly as
-- they were, and keeps them out of the sub.N condition index entirely.
--
-- THE STANDING TRAP: these are stand-alone texture regions anchored to the SCREEN, not
-- sub-regions of the rail, so nothing moves them when the rail they mark changes size or
-- position — and in v15 it changed both, again. Every coordinate is therefore derived from the
-- canonical constants (the sill origin, the power lane, waterX) and none is written down, so the
-- marks follow the rail if those numbers ever move again.
local RAGE_MAX = 100  -- TBC rage is a flat 0-100 pool, so threshold/max is threshold/100

local function rageMark(id, rageValue, width, color, minRage)
  local mark = reg(F.texture(id, CLASS, width, POWER_H,
    localX(SILL_X) + LANE_POWER.x + waterX(rageValue, RAGE_MAX),
    localY(SILL_Y) + LANE_POWER.y,
    nil, RAIL_TEX, color))
  mark.triggers = F.triggers({ F.powerTrigger(1, minRage) })  -- rage only exists in bear form
  mark.load = F.load(CLASS, GATE_F)
  if minRage then
    mark.animation.start  = F.animPreset("shrink", "0.25", "easeOut")  -- WA "shrink" = pop-in
    mark.animation.finish = F.animPreset("fade", "0.2")
  end
  adopt(gRes, mark)
  return mark
end

-- The dim/lit pair and their colours are v2's, unchanged; only the shape and the arithmetic are
-- new. The lit twin is the fatter of the two, which is how the crossing reads at a glance.
rageMark("Druid - Rage Mark Mangle",     20, WATER_DIM, { 0.25, 0.95, 0.45, 0.55 }, nil)
rageMark("Druid - Rage Mark Maul",       70, WATER_DIM, { 1, 0.75, 0.2, 0.55 },     nil)
rageMark("Druid - Rage Mark Mangle Lit", 20, WATER_LIT, { 0.25, 0.95, 0.45, 1 },    20)
rageMark("Druid - Rage Mark Maul Lit",   70, WATER_LIT, { 1, 0.75, 0.2, 1 },        70)

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

-- ================= v15 — the SILL PLATE, on the uid the portrait has always had ============
-- v8 added two `model` portraits here, the only genuinely new auras that version drew, and they
-- still draw the last two uids in the file. v10 recycled them into the life and power globe
-- rims when the vessels replaced the clusters; v12 turned them back into faces at the centre of
-- each cluster; v13 deleted the target one and kept yours; v14 moved it to the back of the
-- group so the health number could be printed on it.
-- v15 SPENDS IT. The 44x44 live 3D face becomes the plate (164x36 since v18) the whole
-- instrument is drawn on — same uid, same position in the seeded stream, `model` re-typed to `texture`, which is
-- free (WA matches by uid; the region type is data). THIS IS THE ONE THING THE REDESIGN TAKES
-- AWAY FROM A PLAYER, and it is a deliberate trade: the model was 1,936 px2 — 19.4% of the old
-- cluster — carrying zero decisions, and what v14 actually needed from it was not a face but an
-- OPAQUE BACKDROP for a number. The plate is that backdrop at 1/62nd of the ink, and it is also
-- what makes three separate bars read as one instrument.
-- It keeps the trigger pair and BOTH alpha conditions unchanged, so plate, rails and waterlines
-- appear, fade out of combat and vanish as one object.
-- Adopted FIRST, exactly as v14 adopted the portrait: it is still CONSTRUCTED here (the uid
-- stream is positional and moving the constructor would re-identify every aura after it) but
-- adoptFirst() puts it at the FRONT of controlledChildren, i.e. the BOTTOM of the group's
-- frame-level stack, so every rail, number, ruler tick and waterline draws over it. That agrees
-- with its frameStrata 2 (BACKGROUND), which it inherits from the portrait unchanged.
local playerPortrait = plate("Druid - Sill Plate", LANE_PLATE,
  { orbHealth("player"), F.unitCharTrigger() })
playerPortrait.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}
adoptFirst(gRes, playerPortrait)

-- last uid — RETIRED SLOT (v8-v9 "Druid - Target Portrait", v10-v11 "Druid - Power Globe Rim",
-- v12 "Druid - Target Portrait"). The target's 3D face went with the rest of its cluster: it was
-- the prettiest thing in the pack and it still never changed a button press, and the target frame
-- carries the same portrait for free. This draw is the LAST in the file, so nothing shifts either
-- way — it is retired rather than simply dropped so that no future version can hand this uid to a
-- new aura and silently "Update" over the leftover Target Portrait in a player's collection.
W.uid()  -- retired: Druid - Target Portrait (never re-issue this uid)

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
-- spec-neutral, because the form-adaptive power globe serves every druid in every form and so
-- must not carry a Bear gate. The four rage marks, the Bear threat rim and the nine icon
-- elements are unchanged, so v10 is still 14. spec-preview.lua's `forbidSpellGate = 33878` Cat
-- profile fails the build if any 33878-gated aura ever loses this trigger, so the count is belt
-- and braces.
assert(bearFormGated == 14, "expected 14 Bear-only elements, gated " .. bearFormGated)

-- ================= assemble (v2000 nested), encode, verify, write =================
local transmit = F.assemble(top, byId)

-- ABSOLUTE POSITION PROOF. localX/localY convert once, but a group offset edited later, a
-- forgotten conversion or an extra nesting level would all move the strip silently — the
-- string would still verify, and the mistake would only show up in game. So re-walk the
-- ASSEMBLED parent chain, sum every xOffset/yOffset exactly as WeakAuras does, and assert the
-- canonical screen coordinates before anything is written.
local nodeById = { [top.id] = top }
for _, child in ipairs(transmit.c) do nodeById[child.id] = child end
local function absolutePos(node)
  local x, y = 0, 0
  while node do
    x, y = x + (node.xOffset or 0), y + (node.yOffset or 0)
    node = node.parent and nodeById[node.parent] or nil
  end
  return x, y
end
local function assertAt(id, wantX, wantY)
  local node = assert(byId[id], "missing aura: " .. id)
  local x, y = absolutePos(node)
  assert(x == wantX and y == wantY,
    ("%s lands at (%g,%g), canonical position is (%g,%g)"):format(id, x, y, wantX, wantY))
end
-- The canonical numbers themselves, spelled out as literals exactly once, so that a sign flip in
-- the constants block cannot pass a proof that is written in terms of those same constants.
assert(SILL_X == 0 and SILL_Y == -110,
  ("the sill anchor is (%g,%g), the canonical position is (0,-110)"):format(SILL_X, SILL_Y))
assert(RAIL_LEN == 160 and THREAT_H == 5 and HEALTH_H == 13 and POWER_H == 13,
  "rail geometry drifted from the canonical v18 160x5 / 160x13 / 160x13")
assert(PLATE_W == 164 and PLATE_H == 36,
  ("the plate is %gx%g; a druid has no discrete class resource, so three lanes make it 164x36")
    :format(PLATE_W, PLATE_H))
assert(PLATE_W == RAIL_LEN + 4,
  ("the plate is %gpx wide for a %gpx rail; the profile is RAIL_LEN + 4 (2px of margin each side)")
    :format(PLATE_W, RAIL_LEN))
-- 1.6 PIXELS PER PERCENT, AND THAT IS WHY 160 (v18). Every value this pack marks is a multiple
-- of five and 1.6 x 5 = 8, so every mark lands on a whole pixel. Assert the property, not the
-- individual answers — the answers are asserted separately, mark by mark, further down.
for _, value in ipairs({ 20, 25, 50, 70, 75 }) do
  local x = waterX(value, 100)
  assert(value % 5 == 0, ("this pack marks %d, which is not a multiple of five"):format(value))
  assert(x == math.floor(x),
    ("%d%% lands at x %s on a %dpx rail, which is not a whole pixel")
      :format(value, tostring(x), RAIL_LEN))
end
-- THE GROUP ITSELF resolves to the canonical anchor — this is the proof that matters, because
-- every lane offset below is measured from it and every other pack measures from the same point.
assertAt(gRes.id, SILL_X, SILL_Y)
-- THE STRIP (v15): the plate, three rails on one x, and the four waterlines.
assertAt("Druid - Sill Plate",     SILL_X + LANE_PLATE.x,  SILL_Y + LANE_PLATE.y)
assertAt("Druid - Threat (Bear)",  SILL_X + LANE_THREAT.x, SILL_Y + LANE_THREAT.y)
assertAt("Druid - Threat (Caster)",SILL_X + LANE_THREAT.x, SILL_Y + LANE_THREAT.y)
assertAt("Druid - Health Rail",    SILL_X + LANE_HEALTH.x, SILL_Y + LANE_HEALTH.y)
assertAt("Druid - Power Rail",     SILL_X + LANE_POWER.x,  SILL_Y + LANE_POWER.y)
-- and the four rage waterlines, the only things in the layer off the strip's centre line.
-- The literals are v18's: 20 rage at 1.6px per percent is -48, 70 rage is +32.
assertAt("Druid - Rage Mark Mangle",     SILL_X + LANE_POWER.x - 48, SILL_Y + LANE_POWER.y)
assertAt("Druid - Rage Mark Mangle Lit", SILL_X + LANE_POWER.x - 48, SILL_Y + LANE_POWER.y)
assertAt("Druid - Rage Mark Maul",       SILL_X + LANE_POWER.x + 32, SILL_Y + LANE_POWER.y)
assertAt("Druid - Rage Mark Maul Lit",   SILL_X + LANE_POWER.x + 32, SILL_Y + LANE_POWER.y)

-- REMOVAL PROOF (v13). The target cluster is gone, and "gone" has to mean gone from the SHIPPED
-- string, not merely from the constructors above — a stray adopt() or a byId entry that survived
-- an edit would ship a region nothing references. Assert against the assembled child list.
local shippedIds = {}
for _, child in ipairs(transmit.c) do shippedIds[child.id] = true end
for _, id in ipairs(REMOVED_V13) do
  assert(not shippedIds[id], id .. " is declared WA-REMOVED but is still in the shipped string")
end
for id in pairs(shippedIds) do
  assert(not id:find("Target", 1, true) or id == "Druid - Target Immune",
    id .. ": a target-cluster region survived the v13 removal")
end

-- 1.6 PIXELS PER PERCENT (v18) — the proof the whole design rests on. A waterline is only a
-- breakpoint if it sits at the pixel the fill reaches at that value, so measure each mark back
-- from the CENTRE of the rail it marks and assert that the offset equals (v/max - 0.5) * length
-- exactly (no rounding: these are whole pixels by construction, and if they ever stop being, the
-- build must say so rather than shrug). Also assert each line spans the rail's full height, which
-- is what makes it a waterline instead of a dot beside the bar.
local powerCx, powerCy = absolutePos(byId["Druid - Power Rail"])
local function assertWaterline(id, value, width)
  local node = assert(byId[id], "missing aura: " .. id)
  local x, y = absolutePos(node)
  -- The expected offset is written in the READABLE algebra, deliberately not in waterX's
  -- integer-safe rearrangement, so this is a genuinely independent check of the formula rather
  -- than a restatement of it. That costs a 1e-9 tolerance (0.7 - 0.5 is not exactly 0.2 in a
  -- double, and x1.6 that error is what makes 70 rage 31.999999999999996 in this spelling), so
  -- the shipped coordinate is separately asserted to be a whole pixel.
  local want = (value / RAGE_MAX - 0.5) * RAIL_LEN
  assert(math.abs((x - powerCx) - want) < 1e-9 and y == powerCy,
    ("%s sits at (%g,%g) i.e. %g from the rail centre; %d rage of %d implies %g")
      :format(id, x, y, x - powerCx, value, RAGE_MAX, want))
  assert(x == math.floor(x) and node.xOffset == math.floor(node.xOffset),
    ("%s ships a fractional x (%s): the mark would land between pixels"):format(id, tostring(node.xOffset)))
  assert(node.height == POWER_H,
    ("%s is %gpx tall; a waterline spans the whole %gpx rail"):format(id, node.height, POWER_H))
  assert(node.width == width and node.texture == RAIL_TEX,
    ("%s is a %gpx %s; expected a %gpx Square_White line")
      :format(id, node.width, tostring(node.texture), width))
  assert(math.abs(x - powerCx) + node.width / 2 <= RAIL_LEN / 2,
    id .. ": the line hangs off the end of the rail")
end
assertWaterline("Druid - Rage Mark Mangle",     20, WATER_DIM)
assertWaterline("Druid - Rage Mark Mangle Lit", 20, WATER_LIT)
assertWaterline("Druid - Rage Mark Maul",       70, WATER_DIM)
assertWaterline("Druid - Rage Mark Maul Lit",   70, WATER_LIT)

-- RAIL CANON (v15) — the replacement for v13's ring canon, and it exists for the same reason:
-- a geometry change in this repo has never silently shipped wrong, because the build asserts the
-- shape it believes it drew. Only a `progresstexture` on the LINEAR path draws a bar at all — a
-- stray "CLOCKWISE" here would silently draw a Square_White pie wedge instead — and the
-- orientation token is the one field in v15 that no committed string in this repo has rendered,
-- so it is named explicitly rather than derived. Sub-region indexes are positional and
-- conditions address them by index, so the expected COUNT and the type of every index is
-- asserted too: sub.1 must still be the subtext, and nothing may be inserted before it.
local function assertRail(id, height, lane, subTypes)
  local node = assert(byId[id], "missing aura: " .. id)
  assert(node.regionType == "progresstexture", id .. ": not a progresstexture")
  assert(node.orientation == "HORIZONTAL",
    id .. ": orientation is " .. tostring(node.orientation) .. ", not the left-to-right linear path")
  assert(node.width == RAIL_LEN,
    ("%s is %gpx long; the canonical rail is %d, i.e. 1.6px per percent")
      :format(id, node.width, RAIL_LEN))
  assert(node.height == height,
    ("%s is %gpx tall, canonical lane height is %g"):format(id, node.height, height))
  assert(node.foregroundTexture == RAIL_TEX and node.backgroundTexture == RAIL_TEX
    and node.sameTexture, id .. ": not drawn on the Square_White rail")
  assert(node.backgroundColor[4] > 0 and node.backgroundOffset == 0,
    id .. ": the unfilled track is invisible or offset into a halo")
  assert(node.crop_x == 0.41 and node.crop_y == 0.41, id .. ": crop drifted from 0.41")
  assert(node.compress == false and node.slanted == false,
    id .. ": compress/slant are LIVE on the linear path and would bend the scale")
  assert(node.xOffset == localX(SILL_X) + lane.x and node.yOffset == localY(SILL_Y) + lane.y,
    id .. ": not on its canonical lane offset")
  assert(#node.subRegions == #subTypes,
    ("%s has %d sub-regions, expected %d"):format(id, #node.subRegions, #subTypes))
  for i, want in ipairs(subTypes) do
    assert(node.subRegions[i].type == want,
      ("%s sub.%d is %q, expected %q"):format(id, i, tostring(node.subRegions[i].type), want))
  end
end
-- sub.1 percentage, sub.2 the 70 notch on the threat rails; sub.1 percentage + sub.2-4 ruler on
-- the two wide rails.
assertRail("Druid - Threat (Bear)",   THREAT_H, LANE_THREAT, { "subtext", "subtexture" })
assertRail("Druid - Threat (Caster)", THREAT_H, LANE_THREAT, { "subtext", "subtexture" })
assertRail("Druid - Health Rail",     HEALTH_H, LANE_HEALTH,
  { "subtext", "subtexture", "subtexture", "subtexture" })
assertRail("Druid - Power Rail",      POWER_H,  LANE_POWER,
  { "subtext", "subtexture", "subtexture", "subtexture" })

-- LANE STACK (v18). Three stacked rails only read as one instrument if they do not overlap each
-- other, if all of them sit inside the plate, and if the leftover margin is EVEN — an instrument
-- with 1px of sky and 2px of floor reads as slipped. The lane offsets are DERIVED from this
-- pack's own plate convention (the plate centre is local y +3, not 0), so the arithmetic is
-- asserted here rather than trusted: 5 + 1 + 13 + 1 + 13 = 33 of content in a 36px plate leaves
-- 1.5px above and 1.5px below.
local STACK_CONTENT = THREAT_H + 1 + HEALTH_H + 1 + POWER_H
assert(STACK_CONTENT == 33,
  ("the three-lane stack is %gpx of content; 5 + 1 + 13 + 1 + 13 is 33"):format(STACK_CONTENT))
assert(PLATE_H - STACK_CONTENT == 3,
  ("a %gpx plate around %gpx of content leaves %gpx of margin, which cannot split evenly into "
    .. "1.5 top and 1.5 bottom"):format(PLATE_H, STACK_CONTENT, PLATE_H - STACK_CONTENT))
local function vspan(id)
  local node = byId[id]
  local _, y = absolutePos(node)
  return y + node.height / 2, y - node.height / 2   -- top, bottom
end
local plateTop, plateBottom = vspan("Druid - Sill Plate")
local lanes = { "Druid - Threat (Bear)", "Druid - Health Rail", "Druid - Power Rail" }
for i, id in ipairs(lanes) do
  local top_, bottom_ = vspan(id)
  assert(top_ <= plateTop - 1 and bottom_ >= plateBottom + 1,
    ("%s spans y %g..%g and the plate only covers %g..%g"):format(id, bottom_, top_, plateBottom, plateTop))
  if i > 1 then
    local prevTop, prevBottom = vspan(lanes[i - 1])
    assert(prevBottom - top_ == 1,
      ("the gutter between %s and %s is %gpx, canonical is 1"):format(lanes[i - 1], id, prevBottom - top_))
  end
end
do
  local contentTop = (vspan(lanes[1]))
  local _, contentBottom = vspan(lanes[#lanes])
  assert(contentTop - contentBottom == STACK_CONTENT,
    ("the lanes span %gpx of the plate but the stack arithmetic says %g")
      :format(contentTop - contentBottom, STACK_CONTENT))
  local marginTop, marginBottom = plateTop - contentTop, contentBottom - plateBottom
  assert(marginTop == marginBottom and marginTop == (PLATE_H - STACK_CONTENT) / 2,
    ("the plate margins are %gpx above and %gpx below the lane stack; a %gpx plate around %gpx "
      .. "of content owes %gpx to each"):format(marginTop, marginBottom, PLATE_H, STACK_CONTENT,
        (PLATE_H - STACK_CONTENT) / 2))
  -- The threat rail is the top lane and the two threat auras share it, so assert the CASTER one
  -- lands on the same line as the bear one rather than only checking lanes[1].
  local otherTop, otherBottom = vspan("Druid - Threat (Caster)")
  assert(otherTop == contentTop and otherBottom == contentTop - THREAT_H,
    "the two threat rails no longer share lane 1")
  print(("  lane stack: threat %+g/%d, health %+g/%d, power %+g/%d -> %g of content, y %g..%g, "
    .. "%.1fpx of margin each side of a %dx%d plate")
    :format(LANE_THREAT.y, THREAT_H, LANE_HEALTH.y, HEALTH_H, LANE_POWER.y, POWER_H,
      STACK_CONTENT, contentBottom, contentTop, marginTop, PLATE_W, PLATE_H))
end
-- The whole strip, as one rectangle, spelled out for the record.
local STRIP_L, STRIP_R = SILL_X - PLATE_W / 2, SILL_X + PLATE_W / 2
local STRIP_B, STRIP_T = plateBottom, plateTop
print(("  the sill: x %g..%g  y %g..%g  (%gx%g = %g px2)")
  :format(STRIP_L, STRIP_R, STRIP_B, STRIP_T, PLATE_W, PLATE_H, PLATE_W * PLATE_H))

-- COLLISION SCAN (v15, re-run against v18's bigger strip), the proof that replaces v13's single
-- alert-column clearance. Project EVERY drawn region in the pack to an absolute rectangle and
-- test it against the strip. Clones inside a dynamic group are projected SIX DEEP, in the group's
-- own grow direction, using its own spacing — six is well past this pack's realistic worst case
-- (the alert group holds nine prompts and no spec can load them all at once). A single
-- overlapping pixel fails the build.
--
-- THE SCANNED BOX IS THE WHOLE ENVELOPE, and for this pack the envelope IS the plate: there is
-- no alarm rim here (see the v15/v18 header notes — this pack has never had a threat flash and
-- inventing one would consume a uid for a region that has never existed), and every rail, ruler
-- hairline, number and waterline is inside the plate by the lane-stack proof above. The scan
-- ALSO reports what a hypothetical +-4px rim would have left, so the next person can see the
-- headroom without re-deriving it.
--
-- NOTHING MOVED IN v18, AND THAT IS A MEASUREMENT. The plate went 102x31 -> 164x36, i.e. 5px
-- taller, so the buff row that sat 13.5px below the v17 strip now sits 11.0px below it and the
-- Alerts/PvP columns are still x-separated by 48px. The frontier was searched before the change
-- (the strip clears everything up to a +-8px pad and only collides with the buff row at +-12),
-- so no column has to move and none does.
local DEEP = 6
local function rectOf(node)
  local x, y = absolutePos(node)
  local w, h = node.width or 0, node.height or 0
  local l, r, b, t = x - w / 2, x + w / 2, y - h / 2, y + h / 2
  local parent = node.parent and nodeById[node.parent]
  if parent and parent.regionType == "dynamicgroup" then
    local reach = (DEEP - 1) * (((parent.grow == "HORIZONTAL" or parent.grow == "LEFT"
      or parent.grow == "RIGHT") and w or h) + (parent.space or 0))
    local g = parent.grow
    if g == "UP" then t = t + reach
    elseif g == "DOWN" then b = b - reach
    elseif g == "RIGHT" then r = r + reach
    elseif g == "LEFT" then l = l - reach
    elseif g == "HORIZONTAL" then l, r = l - reach / 2, r + reach / 2
    elseif g == "VERTICAL" then b, t = b - reach / 2, t + reach / 2
    else error("unhandled dynamic grow: " .. tostring(g)) end
  end
  return l, r, b, t
end
local sillChildren = {}
for _, id in ipairs(gRes.controlledChildren) do sillChildren[id] = true end
local RIM_HEADROOM = 4     -- the profile's rim width; this pack draws no rim, so this is margin
local scanned, nearest, closest = 0, nil, nil
for _, node in ipairs(transmit.c) do
  if node.regionType ~= "group" and node.regionType ~= "dynamicgroup" and not sillChildren[node.id] then
    local l, r, b, t = rectOf(node)
    scanned = scanned + 1
    assert(r <= STRIP_L or l >= STRIP_R or t <= STRIP_B or b >= STRIP_T,
      ("%s (x %g..%g, y %g..%g) overlaps the sill (x %g..%g, y %g..%g)")
        :format(node.id, l, r, b, t, STRIP_L, STRIP_R, STRIP_B, STRIP_T))
    -- report the tightest VERTICAL margin as a number in the build log rather than as a claim
    -- in a comment: gaps are what a future edit erodes first.
    if not (r <= STRIP_L or l >= STRIP_R) then
      local gap = (b >= STRIP_T) and (b - STRIP_T) or (STRIP_B - t)
      if not nearest or gap < nearest[2] then nearest = { node.id, gap } end
    end
    -- and the tightest gap on EITHER axis, which is the number that actually bounds the strip
    local gap = math.max(STRIP_L - r, l - STRIP_R, STRIP_B - t, b - STRIP_T)
    if not closest or gap < closest[2] then closest = { node.id, gap } end
  end
end
assert(nearest, "the collision scan found nothing in the strip's x range — the projection is broken")
assert(closest[2] >= RIM_HEADROOM,
  ("the strip clears everything by only %gpx (%s); the profile's rim is %gpx, so a pack that "
    .. "ever grows one here would already be touching")
    :format(closest[2], closest[1], RIM_HEADROOM))
print(("  collision scan: %d regions, %d clones deep, 0 overlaps | tightest gap on any axis: "
  .. "%gpx to %s (vertical: %gpx to %s; a hypothetical %gpx rim would still leave %gpx)")
  :format(scanned, DEEP, closest[2], closest[1], nearest[2], nearest[1], RIM_HEADROOM,
    closest[2] - RIM_HEADROOM))

-- ALL-PAIRS ACROSS THE FLANKING COLUMNS (v18). The scan above tests everything against the
-- SILL, which structurally cannot see two flanking columns overlapping EACH OTHER — and that
-- exact blind spot hid a real defect in the sibling rogue pack, where a 140px kick-lockout bar
-- covered a weapon-proc icon for several versions. Nothing moves in this pack's v18, so this is
-- a proof rather than a fix, and it is added now so it is already here the day something does.
-- Each column's box is the UNION of its children's projected rectangles, which is the honest
-- box for a static row (Buffs, whose children carry their own x offsets) and for a dynamic
-- column alike: rectOf() already grows a dynamic child six deep in its parent's direction, and
-- a vertically growing group is horizontally CENTRED on its anchor (only LEFT/RIGHT hang to one
-- side), which is why the PvP column's box is x 132..168 around x = 150.
do
  local COLUMNS = { "Druid - Buffs", "Druid - Alerts", "Druid - Cooldowns", "Druid - PvP" }
  local boxes = {}
  for _, id in ipairs(COLUMNS) do
    local g = assert(byId[id], "missing column: " .. id)
    local l, r, b, t = math.huge, -math.huge, math.huge, -math.huge
    local kids = 0
    for _, cid in ipairs(g.controlledChildren or {}) do
      local cl, cr, cb, ct = rectOf(assert(nodeById[cid], "unresolved child " .. cid))
      l, r, b, t = math.min(l, cl), math.max(r, cr), math.min(b, cb), math.max(t, ct)
      kids = kids + 1
    end
    assert(kids > 0, id .. ": a flanking column with no children cannot be projected")
    boxes[#boxes + 1] = { id = id, l = l, r = r, b = b, t = t }
  end
  local tightest, tightPair = math.huge, nil
  for i = 1, #boxes do
    for j = i + 1, #boxes do
      local a, c = boxes[i], boxes[j]
      assert(not (a.l < c.r and a.r > c.l and a.b < c.t and a.t > c.b),
        ("columns %s (x %g..%g y %g..%g) and %s (x %g..%g y %g..%g) overlap; one would render "
          .. "behind the other"):format(a.id, a.l, a.r, a.b, a.t, c.id, c.l, c.r, c.b, c.t))
      local gap = math.max(a.l - c.r, c.l - a.r, a.b - c.t, c.b - a.t)
      if gap < tightest then tightest, tightPair = gap, a.id .. " / " .. c.id end
    end
  end
  print(("  column all-pairs: %d flanking stacks at %d deep, %d pairs, 0 overlaps | tightest "
    .. "%gpx (%s)"):format(#boxes, DEEP, #boxes * (#boxes - 1) / 2, tightest, tightPair))
end

-- THE PLATE (v15). It replaces the model, so the assertion that used to prove the model's unit
-- fields now proves the plate's: the right region type, the right art, and — the one that matters
-- — an EXPLICIT colour. On a `texture` region the tint is `color`, and leaving it empty draws in
-- WeakAuras' default rather than the intended shade.
local function assertPlate(id)
  local node = assert(byId[id], "missing aura: " .. id)
  assert(node.regionType == "texture", id .. ": not a texture region")
  assert(node.texture == PLATE_TEX, id .. ": not drawn on Square_White_Border")
  assert(type(node.color) == "table" and #node.color == 4 and node.color[4] > 0,
    id .. ": colour is not an explicit opaque-enough RGBA — it would draw in WA's default")
  assert(node.width == PLATE_W and node.height == PLATE_H,
    ("%s is %gx%g, canonical is %dx%d"):format(id, node.width, node.height, PLATE_W, PLATE_H))
  assert(node.frameStrata == 2, id .. ": the plate is the backdrop and belongs on BACKGROUND")
end
assertPlate("Druid - Sill Plate")
-- The 3D portrait is genuinely gone, not merely unreferenced: no `model` region survives.
for _, node in ipairs(transmit.c) do
  assert(node.regionType ~= "model", node.id .. ": a model region survived the v15 re-type")
end

-- READABILITY PROOF (v18). The numbers are only "inside the rail" if the digits fit. The widest
-- string either of them ever prints is "100%" — four glyphs — and a Friz Quadrata glyph at 12pt
-- is at most ~8px wide, so a CENTER-anchored number at x = +51 spans +35..+67 and the rail ends
-- at +80. The other half of "the number lives in the rail" is vertical: 12pt must fit inside the
-- 13px lane it prints in. Assert the canonical placements as literals here exactly once, so a
-- later edit to the constants block cannot pass a proof written in those same constants.
assert(PCT_HP.x == 51 and PCT_HP.y == 0 and PCT_HP.size == 12,
  ("the health percentage is %gpt at (%g,%g); v18 ships 12pt at (51,0)")
    :format(PCT_HP.size, PCT_HP.x, PCT_HP.y))
assert(PCT_POWER.x == 51 and PCT_POWER.y == 0 and PCT_POWER.size == 12,
  ("the power percentage is %gpt at (%g,%g); v18 ships 12pt at (51,0)")
    :format(PCT_POWER.size, PCT_POWER.x, PCT_POWER.y))
assert(PCT_THREAT.visible == false and PCT_THREAT.size == 9 and PCT_THREAT.x == -32,
  ("the threat percentage is %gpt at x %g, visible=%s; v18 ships it 9pt, switched off and left "
    .. "exactly where v15 parked it (x -32)")
    :format(PCT_THREAT.size, PCT_THREAT.x, tostring(PCT_THREAT.visible ~= false)))
local DIGIT_W, WIDEST = 8, 4  -- a Friz Quadrata glyph at 12pt, conservatively; "100%" is 4 of them
assert(PCT_HP.x + WIDEST * DIGIT_W / 2 <= RAIL_LEN / 2,
  ("%d glyphs centred on x %g reach %g and the rail ends at %g")
    :format(WIDEST, PCT_HP.x, PCT_HP.x + WIDEST * DIGIT_W / 2, RAIL_LEN / 2))
assert(PCT_HP.size <= HEALTH_H and PCT_POWER.size <= POWER_H,
  "a number is taller than the rail it prints in")
assert(math.abs(PCT_THREAT.x) + WIDEST * DIGIT_W / 2 <= RAIL_LEN / 2,
  "the (hidden) threat number would hang off the end of its rail if it were re-ticked")
local function assertLabel(id, token, place)
  local st = assert(byId[id], "missing aura: " .. id).subRegions[1]
  assert(st and st.type == "subtext", id .. ": the percentage is no longer sub.1")
  assert(st.text_text == token, ("%s: text is %q, expected %q"):format(id, tostring(st.text_text), token))
  assert(st.text_fontSize == place.size and st.anchorXOffset == place.x and st.anchorYOffset == place.y,
    ("%s: %gpt at (%g,%g), expected %gpt at (%g,%g)")
      :format(id, st.text_fontSize, st.anchorXOffset, st.anchorYOffset, place.size, place.x, place.y))
  -- BOTH SPELLINGS, EQUAL (v16). WeakAuras anchors on text_anchorXOffset/text_anchorYOffset;
  -- SubText.lua's own default() writes the bare anchorXOffset/anchorYOffset and nothing reads
  -- them, and no Modernize step bridges the two. Emitting one without the other is the silent
  -- no-op v16 fixed, so v18's move from +32 to +51 has to land on both.
  assert(st.text_anchorXOffset == place.x and st.text_anchorYOffset == place.y,
    ("%s: text_anchor offsets are (%s,%s), expected (%g,%g) — only the text_ spelling is read")
      :format(id, tostring(st.text_anchorXOffset), tostring(st.text_anchorYOffset), place.x, place.y))
  assert(st.text_anchorPoint == "CENTER" and st.text_fontType == "OUTLINE",
    id .. ": the percentage lost its CENTER anchor or its OUTLINE")
  assert((st.text_visible ~= false) == (place.visible ~= false),
    id .. ": the percentage's visibility does not match its canonical placement")
end
assertLabel("Druid - Health Rail",     "%percenthealth%%", PCT_HP)
assertLabel("Druid - Power Rail",      "%percentpower%%",  PCT_POWER)
assertLabel("Druid - Threat (Bear)",   "%threatpct%%",     PCT_THREAT)
assertLabel("Druid - Threat (Caster)", "%threatpct%%",     PCT_THREAT)

-- THE RULER AND THE NOTCH (v18), on the same 1.6-pixels-per-percent scale as everything else,
-- and every one of them a WHOLE pixel because every marked value is a multiple of five. The
-- expected x is a LITERAL here, not waterX(v) again: a proof written in the formula it is
-- checking proves only that the formula equals itself.
local function assertSubtexAt(id, index, wantX, wantW, wantH)
  local st = assert(byId[id], "missing aura: " .. id).subRegions[index]
  assert(st and st.type == "subtexture", ("%s sub.%d is not a subtexture"):format(id, index))
  assert(st.xOffset == wantX and st.yOffset == 0,
    ("%s sub.%d sits at (%g,%g), expected (%g,0)"):format(id, index, st.xOffset, st.yOffset, wantX))
  assert(st.xOffset == math.floor(st.xOffset),
    ("%s sub.%d ships a fractional x (%s): the mark would land between pixels")
      :format(id, index, tostring(st.xOffset)))
  assert(st.width == wantW and st.height == wantH,
    ("%s sub.%d is %gx%g, expected %gx%g"):format(id, index, st.width, st.height, wantW, wantH))
  assert(math.abs(st.xOffset) + st.width / 2 <= RAIL_LEN / 2,
    ("%s sub.%d hangs off the end of a %gpx rail"):format(id, index, RAIL_LEN))
  assert(st.textureTexture == RAIL_TEX and st.textureVisible,
    ("%s sub.%d is not a visible Square_White line"):format(id, index))
end
for _, id in ipairs({ "Druid - Threat (Bear)", "Druid - Threat (Caster)" }) do
  assertSubtexAt(id, 2, 32, NOTCH_W, THREAT_H)  -- the 70 notch: 70 * 1.6 - 80 = +32
end
for _, pair in ipairs({ { "Druid - Health Rail", HEALTH_H }, { "Druid - Power Rail", POWER_H } }) do
  assertSubtexAt(pair[1], 2, -40, RULE_W, pair[2])  -- 25%: 25 * 1.6 - 80
  assertSubtexAt(pair[1], 3,   0, RULE_W, pair[2])  -- 50%
  assertSubtexAt(pair[1], 4,  40, RULE_W, pair[2])  -- 75%
end
assert(RULE_W == 2 and NOTCH_W == 2 and WATER_DIM == 4 and WATER_LIT == 8,
  ("mark widths drifted from the profile: ruler %g, notch %g, waterlines %g/%g; v18 ships 2, 2, "
    .. "4/8"):format(RULE_W, NOTCH_W, WATER_DIM, WATER_LIT))
-- Every mark in the pack, printed with its value and its x, so the whole-pixel claim is in the
-- build log rather than in a comment.
do
  local marks = {}
  for _, m in ipairs({ { "rage 20", 20 }, { "ruler 25", 25 }, { "ruler 50", 50 },
                       { "threat/rage 70", 70 }, { "ruler 75", 75 } }) do
    marks[#marks + 1] = ("%s -> x %+g"):format(m[1], waterX(m[2], 100))
  end
  print(("  marks (x = (v/100 - 0.5) * %d, %.1fpx per percent, all whole): %s")
    :format(RAIL_LEN, RAIL_LEN / 100, table.concat(marks, ", ")))
end

-- DRAW ORDER (v15). controlledChildren IS the sibling stack — FixGroupChildrenOrder adds +4
-- frame levels per child, so FIRST is furthest behind. The Sill's order is fixed: the plate is
-- the backdrop and must be first, the waterlines mark the power rail and must come after it, and
-- the flat `c` list must be depth-first in the SAME order because that is what actually ships.
-- (There is no alarm frame in this pack; see the v15 header note. If one is ever added it goes
-- LAST, after the waterlines.)
local WANT_ORDER = {
  "Druid - Sill Plate",
  "Druid - Threat (Bear)", "Druid - Threat (Caster)",
  "Druid - Health Rail", "Druid - Power Rail",
  "Druid - Rage Mark Mangle", "Druid - Rage Mark Maul",
  "Druid - Rage Mark Mangle Lit", "Druid - Rage Mark Maul Lit",
}
assert(#gRes.controlledChildren == #WANT_ORDER,
  ("the sill has %d children, expected %d"):format(#gRes.controlledChildren, #WANT_ORDER))
for i, want in ipairs(WANT_ORDER) do
  assert(gRes.controlledChildren[i] == want,
    ("sill child %d is %q, expected %q"):format(i, tostring(gRes.controlledChildren[i]), want))
end
local cIndex = {}
for i, child in ipairs(transmit.c) do cIndex[child.id] = i end
for i = 2, #WANT_ORDER do
  assert(cIndex[WANT_ORDER[i]] == cIndex[WANT_ORDER[i - 1]] + 1,
    ("the flat c list is not depth-first in controlledChildren order at %q"):format(WANT_ORDER[i]))
end
assert(cIndex[WANT_ORDER[1]] == cIndex[gRes.id] + 1,
  "the sill's children do not immediately follow the sill group in the flat c list")

local encoded = W.encode(transmit)
W.verify(transmit, encoded)

local txtPath = dir .. "/all-specs.txt"
-- Continuity vs the PREVIOUS shipped string (read before overwriting it). v13 spent this pack's
-- one removal licence and v15 does not need it: no aura is added or removed, and renaming,
-- re-typing, resizing and reordering children all consume no uid, so the STRICT default applies —
-- every previous uid must survive (missing = 0) and an id that keeps its name while swapping uid
-- (changed) is never forgivable at all. Four ids are RENAMED in v15 (Rings -> Player Sill,
-- Player Health Ring -> Health Rail, Player Power Ring -> Power Rail, Player Portrait -> Sill
-- Plate); a rename shows up as a drop in `stable`, never in `changed` or `missing`, because WA
-- matches by uid and every one of those uids is carried across untouched.
local cont = W.uidContinuity(encoded, txtPath)
W.assertUidContinuity(cont, "druid")

local out = io.open(txtPath, "w")
out:write(encoded)  -- single line, no trailing newline
out:close()

print(("OK: %d auras (%d children + top), %d chars -> all-specs.txt")
  :format(#transmit.c + 1, #transmit.c, #encoded))
if cont then
  print(("uid continuity vs previous: stable=%d changed=%d retained=%d missing=%d parentSame=%s")
    :format(cont.stable, cont.changed, cont.retained, cont.missing, tostring(cont.parentSame)))
  if #cont.missingIds > 0 then
    print("  deliberately removed: " .. table.concat(cont.missingIds, ", "))
  end
end
