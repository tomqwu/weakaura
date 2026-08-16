-- generate.lua — Druid TBC Bear / Restoration / Balance HUD (v14).
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

-- ===== CANONICAL RING CLUSTER GEOMETRY (v13) — SHARED BY ALL SEVEN CLASS PACKS =====
-- These numbers are the contract. They are identical in every tbc/*/generate.lua and MUST NOT
-- be edited in one pack alone: v9 exists only because seven packs each picked their own
-- diameters and the HUD read as uneven. Derive from them; never hand-write a size, a colour or
-- an offset anywhere below.
--
-- CLUSTER ASSIGNMENT (v13) — ONE cluster, three concentric arcs around a live portrait, all of
-- it about YOU. The target cluster is gone: the target's health was already on the target frame
-- and on its nameplate, so it duplicated the default UI for the whole game.
--   PLAYER cluster at (CLUSTER_X, CLUSTER_Y)
--     outermost THREAT_RING = YOUR threat   (spec-gated, self-hiding — see the threat rings)
--     outer     OUTER       = health
--     inner     INNER       = primary power (mana / rage / energy, form-adaptive)
--     centre    PORTRAIT    = live player face
-- 44/84 is the portrait-to-outer ratio the layout is tuned around — a face any smaller is not
-- recognisable at a glance, any larger and the arcs stop reading as concentric. THREAT_RING sits
-- one band further out: Ring_20px paints diameter * 20/256, so the 84 ring's annulus runs from
-- radius 35.4 to 42 and the 100 ring's from 42.2 to 50 — adjacent, never overlapping.
local RING_TEX    = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Ring_20px.tga"
local THREAT_RING = 100  -- outermost ring: YOUR threat (v13)
local OUTER       = 84   -- health ring
local INNER       = 62   -- primary power ring
local PORTRAIT    = 44   -- live unit portrait
-- x = -270 is unchanged from v12 and is not a taste call. The Alerts column occupies x
-- -170..-130 and is a DYNAMIC GROUP that grows vertically, so a cluster level with it collides
-- as soon as a second prompt stacks. The threat ring now spans 50 either side of the centre:
-- at x = -270 the cluster occupies -320..-220 and its inner edge is still 50px clear of the
-- alert column at ANY stack depth (grow UP with stagger 0 and align CENTER cannot move a clone
-- sideways). Asserted from the assembled tables at the bottom of this file, six clones deep.
local CLUSTER_X = -270  -- ABSOLUTE screen x of the (only) cluster
local CLUSTER_Y =   40  -- ABSOLUTE screen y of the (only) cluster (see localY below)

-- Numbers, all anchored CENTER on the ring that owns them, so each appears and vanishes with its
-- readout. A `model` region still cannot carry a text sub-region — but v14 is the version that
-- noticed the number does not have to live on the PORTRAIT's region, only on the portrait's
-- PIXELS. Every one of these is a sub-region of a RING, and a ring can put its text anywhere.
--   HEALTH sits at y = 0: dead centre of the cluster, ON the face, at 16pt. It is the
--     most-read number in the pack and the face is the only opaque backdrop the HUD owns, so
--     this is the one place it is legible over a bright game background. Requires the portrait
--     to be the FIRST child of the group (see the adopt() calls) or the face covers it.
--   POWER takes the slot health vacates, y = -54, at 12pt — just under the 84px health band
--     (radius 42), where it reads as a caption to the cluster rather than a second centre.
--   THREAT is unchanged at y = +58, the one number ABOVE its arc (clear of the 100px annulus at
--     radius 50), so it can never collide with either number below.
local PCT_HP     = { size = 16, y =   0 }  -- dead centre, over the portrait (v14: 13pt/-54 -> 16pt/0)
local PCT_POWER  = { size = 12, y = -54 }  -- under the health ring (v14: 10pt/-70 -> 12pt/-54)
local PCT_THREAT = { size = 10, y =  58 }  -- above the outermost threat ring (v13: 54 -> 58)

-- ABSOLUTE -> LOCAL. CLUSTER_X/CLUSTER_Y are screen coordinates, but these regions are
-- nested two groups deep and WeakAuras anchors a child to its group (anchorFrameType "SCREEN"
-- resolves to the parent frame for a grouped aura), so the on-screen position is the SUM of every
-- offset down the chain. The two group offsets are therefore constants, and the conversion
-- happens exactly once, here — never at a call site. The assembled string is re-walked and
-- asserted at the bottom of this file, so a future edit to either group offset fails the build
-- instead of quietly sliding the cluster somewhere else.
local TOP_X,  TOP_Y  = 0, -140   -- the pack's draggable top-level group
local ORBG_X, ORBG_Y = 0,  30    -- the ring layer inside it
local function localX(absX) return absX - (TOP_X + ORBG_X) end
local function localY(absY) return absY - (TOP_Y + ORBG_Y) end

-- RESOURCE BREAKPOINT MARKS. A threshold on a RING is a point on the circumference, so it takes
-- trigonometry (a vessel only needed a horizontal line). The canonical placement, measured from
-- the centre of the ring the mark belongs to:
--   r = INNER/2 * 0.94 ;  x = r * sin(2*pi*f) ;  y = r * cos(2*pi*f)      (f = threshold/max)
-- sin on x and cos on y put f = 0 at 12 o'clock and advance CLOCKWISE, which is the direction the
-- ring fills — so a mark sits exactly where the arc reaches that value. 0.94 lands the pip in the
-- middle of the drawn band: Ring_20px paints diameter * 20/256, so at INNER = 62 the annulus runs
-- from radius 26.2 to 31 and 0.94 * 31 = 29.1.
local MARK_R = INNER / 2 * 0.94
local function markX(fraction) return math.floor(MARK_R * math.sin(2 * math.pi * fraction) + 0.5) end
local function markY(fraction) return math.floor(MARK_R * math.cos(2 * math.pi * fraction) + 0.5) end
-- Pip diameters come from the stroke too, so they sit IN the band instead of across it; the lit
-- twin is 2px fatter, which is how the crossing reads at a glance.
local RING_STROKE = INNER * 20 / 256
local PIP_DIM = math.floor(RING_STROKE + 0.5)
local PIP_LIT = PIP_DIM + 2

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
-- uid slot 2. v7 called this "Druid - Resources" at (0,56) and parked a 172x14 bar stack in
-- the middle of the screen; v8-v9 made it the ring-orb layer and v10-v11 the globe layer. Same
-- table, same uid: it holds the two ring clusters again. Its own offset is ORBG_X/ORBG_Y and is
-- part of the absolute-position sum — see localX/localY above; nothing below writes a screen
-- coordinate directly onto a child.
local gRes    = reg(F.group("Druid - Rings", ORBG_X, ORBG_Y, nil))
local gBuffs  = reg(F.group("Druid - Buffs", 0, -16, nil))
local gAlerts = reg(F.dynGroup("Druid - Alerts", -150, 96, nil, "UP", "BOTTOM", 6))
local gCDs    = reg(F.dynGroup("Druid - Cooldowns", 0, -66, nil, "HORIZONTAL", "CENTER", 4))
adopt(top, gRes)
adopt(top, gBuffs)
adopt(top, gAlerts)
adopt(top, gCDs)

-- ================= v12 ring clusters — state drawn AT the unit =================
-- Two clusters inside the group that used to hold the centre bar stack, then the v8-v9 rings,
-- then the v10-v11 globes: the player's at (-270, 40) and the target's at (+270, 110), each two
-- concentric arcs around a live portrait. The middle of the screen stays empty, which is what
-- v8 bought and no version since has spent.
--
-- Every READOUT keeps the trigger, gate and escalation it had as a vessel; what changes is the
-- shape, the fill path and where the number sits. Threat comes off the target rim and becomes
-- the target cluster's OUTER RING, and the plain rim's uid becomes the track that ring runs in.
local COL = {
  -- Canonical ring palette, identical in all seven packs.
  health = { 0.15, 0.82, 0.28, 1 },     -- the health arc, both clusters
  mana   = { 0.20, 0.45, 0.95, 1 },     -- caster/tree/moonkin power ring
  rage   = { 0.75, 0.15, 0.15, 1 },     -- bear
  energy = { 0.90, 0.80, 0.20, 1 },     -- cat
  track  = { 0, 0, 0, 0.55 },           -- the UNFILLED arc behind every ring, and the target's
                                        -- stand-alone outer groove
  -- Pack escalations, carried across from v7-v11 unchanged.
  threat = { 0.25, 0.80, 0.30, 1 },  -- v7's threat-bar green
  warn   = { 1.00, 0.60, 0.10, 1 },  -- threat >= 70%
  hurt   = { 1.00, 0.65, 0.10, 1 },  -- health < 50%
  danger = { 0.90, 0.12, 0.12, 1 },  -- aggro lost / gained, health < 25%
  text   = { 1, 1, 1, 1 },
}

-- Ring_20px.tga is a true ANNULUS and ships inside WeakAuras (Private.texture_types, "Shapes");
-- the number is the stroke weight of the source art, so the drawn band is diameter * 20/256.
-- The globes' Circle_Smooth.tga is a SOLID DISC and would fill as a pie wedge on the circular
-- path — the texture and the orientation change together or not at all.
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

-- THE RING. Same progresstexture region the globes used, back on the radial path — and the
-- fields that are traps, in the order they bite:
--   orientation CLOCKWISE  -> the only radial values are CLOCKWISE / ANTICLOCKWISE; every other
--     key in orientation_with_circle_types is linear, which is where the globes lived. The keys
--     lie about direction in the usual WA way, so this is worth stating: CLOCKWISE starts the
--     arc at startAngle and grows the way a clock's hand moves.
--   startAngle 0 / endAngle 360 -> a full circle, and LIVE again (they were ignored on the
--     linear path). WA normalises 0/360 -> 0/0 and then corrects endAngle back up by 360, so
--     this is a handled case, not a degenerate one.
--   backgroundColor = COL.track -> the UNFILLED arc. backgroundOffset 0 keeps it the same
--     annulus as the fill; the default 2 fattens it into a halo around the ring.
--   crop_x / crop_y = 0.41 -> the IDENTITY value, NOT "no crop". The circular path expands the
--     texture by sqrt(2) so rotated quadrants never run off it, and 1 + 0.41 cancels that
--     exactly. Setting 0 blows the ring up 1.41x and clips it.
--   compress / slanted / slant / slantMode -> LIVE on a vessel, INERT here. Untouched.
--   auraRotation = 0 -> absent from the 3.5.0 default table but read unconditionally by
--     current code as data.auraRotation / 180 * math.pi, so it must be emitted.
--   adjustedMin/Max are STRINGS, because SetAdjustedMin does adjustedMin:find(...).
--   progressSource is rewritten to {-1, ""} (Automatic) by Modernize < 71 whatever is
--     emitted, which is why each ring has exactly ONE progress-supplying trigger and it is
--     trigger 1: activeTriggerMode -10 is first_active, and Automatic reads that trigger's
--     value/total. A second trigger can only feed conditions, never the fill — which is also
--     why health and power cannot share a region, and that constraint is what makes the
--     concentric look possible in the first place.
-- absX/absY are ABSOLUTE screen coordinates; localX/localY do the one conversion (see the
-- constants block), because the two clusters sit at different heights.
local function ring(id, size, absX, absY, color, triggerList, gate)
  return reg(stub{
    regionType = "progresstexture", id = id, uid = W.uid(), parent = nil,
    width = size, height = size,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = localX(absX), yOffset = localY(absY), frameStrata = 1, alpha = 1,
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
    triggers = F.triggers(triggerList),
    load = F.load(CLASS, gate),
  })
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

-- THE LIVE PORTRAIT — a real 3D portrait of whoever is there, not a static image and not a class
-- icon, which is what lets the target side work without ever knowing the target's class: it
-- renders NPCs and mobs too. frameStrata 2 is WA's BACKGROUND — the LOWEST strata, below the
-- inherited one the rings use, not above it. v12-v13 carried a comment here claiming the
-- opposite ("nothing ever draws over the face") and ordered the group to match the claim; v14
-- keeps the field exactly as it is and fixes the order instead, so strata and frame level agree
-- that the face is the cluster's backdrop. That is what makes a number legible on it.
--   modelIsUnit = true + model_fileId = "<unit>" -> PlayerModel:SetUnit(unit)
--   portraitZoom = true                          -> SetPortraitZoom(1), Blizzard head framing
-- CRITICAL: current code reads the unit from `model_fileId`. WA 3.5.0 read `model_path`, and the
-- migration that bridges the two (Modernize < 72) is guarded by WeakAuras.IsClassicEra(), which
-- is a DISTINCT predicate from IsTBC() — so on a 2.5.x client that migration DOES NOT RUN and
-- emitting only model_path is a silent no-op. Both are emitted; model_fileId does the work.
-- The portrait carries its cluster's health trigger, so it self-hides exactly when its rings do.
local function portrait(id, unit, absX, absY, triggerList)
  return reg(stub{
    regionType = "model", id = id, uid = W.uid(), parent = nil,
    model_fileId = unit, model_path = unit, modelIsUnit = true, modelDisplayInfo = false,
    portraitZoom = true, api = false,
    model_x = 0, model_y = 0, model_z = 0,
    model_st_tx = 0, model_st_ty = 0, model_st_tz = 0,
    model_st_rx = 270, model_st_ry = 0, model_st_rz = 0, model_st_us = 40,
    sequence = 1, advance = false, rotation = 0,
    width = PORTRAIT, height = PORTRAIT, alpha = 1,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = localX(absX), yOffset = localY(absY), frameStrata = 2,
    border = false, borderColor = { 1, 1, 1, 0.5 }, backdropColor = { 1, 1, 1, 0.5 },
    borderEdge = "None", borderOffset = 5, borderInset = 11,
    borderSize = 16, borderBackdrop = "Blizzard Tooltip",
    subRegions = {},
    triggers = F.triggers(triggerList),
    load = F.load(CLASS),
  })
end

-- WHERE THE NUMBERS LIVE, and v14 corrects the reasoning v12 shipped. A progresstexture accepts
-- a subtext (SubText's supports() lists texture / progresstexture / icon / aurabar / empty) and
-- a `model` region never did — but that only means the text cannot be a sub-region OF THE
-- PORTRAIT, not that it cannot be drawn OVER the portrait. Every number here is a sub-region of
-- a RING, anchored CENTER on that ring, and anchorYOffset puts it wherever the layout wants:
-- v14 puts the health number at 0, i.e. on the face. Each number still rides on the region that
-- owns it and appears and disappears with it: no threat table, no threat number. The size/offset
-- pair comes from one of the three canonical placements (PCT_HP / PCT_POWER / PCT_THREAT), never
-- from a call site, so no two packs and no two numbers can drift apart.
local function pct(sym, place, color)
  local st = F.subtext("%" .. sym .. "%%", place.size, "CENTER", sym)
  st.anchorYOffset = place.y
  st.text_color = color
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

-- ===== the four rings, in the v7 uid order they inherit =====
-- CONSTRUCTION order below is uid order and MUST NOT CHANGE — not even where a region has been
-- deleted. Two of v12's six slots (8 and 9) are now RETIRED: their W.uid() calls are still made,
-- in place, and the value is thrown away, because the seeded stream is positional and dropping a
-- call outright would shift every uid drawn after it. A retired slot is not a filler region: it
-- builds nothing, ships nothing and can never be re-issued to a future aura.
-- DISPLAY order is set separately by the adopt() calls at the end of this section:
-- FixGroupChildrenOrder walks controlledChildren and adds +4 frame levels per child, so
-- EARLIER = further behind.

-- uid 6 (v7 "Druid - Health", v8-v9 "Druid - Player Health", v10-v11 "Druid - Life Globe").
-- YOUR HEALTH RING, 84px — the middle arc since v13 put threat outside it, and still the
-- most-read number in the pack.
-- Trigger 2 is the always-on Unit Characteristics feeder that v7's bars used for the
-- out-of-combat fade; it never gates visibility and trigger 1 stays the progress source.
-- The escalations are v8's, untouched: amber under 50%, red under 25% (severe condition last,
-- so it wins), on `foregroundColor` — the progresstexture spelling of what an aurabar calls
-- `barColor`. The last condition is the zero-total guard: an aurabar with total 0 draws EMPTY
-- but a progresstexture draws FULL, and UnitHealthMax has no floor, so a unit whose max health
-- has not streamed yet would flash a complete ring.
local playerHP = ring("Druid - Player Health Ring", OUTER, CLUSTER_X, CLUSTER_Y, COL.health,
  { orbHealth("player"), F.unitCharTrigger() })
playerHP.subRegions[1] = pct("percenthealth", PCT_HP, COL.text)
playerHP.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "percenthealth", "<", "50", "foregroundColor", COL.hurt),
  F.condition(1, "percenthealth", "<", "25", "foregroundColor", COL.danger),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

-- uid 7 (v7 "Druid - Rage", v8-v9 "Druid - Player Power", v10-v11 "Druid - Power Globe").
-- THE PLAYER'S INNER RING, and it is one arc for all three of the druid's resources. The
-- trigger is form-adaptive, and the resolved type is a stored, conditionable arg (`powertype`,
-- init = powerTypeToCheck, conditionType select), so the ring is coloured for the power type it
-- actually reads: mana blue as the base, rage red in bear, energy yellow in cat. Numeric select
-- values compile correctly — Conditions.lua takes the tonumber branch.
-- No load gate at all: every druid has a primary resource in every form. v7's rage bar was
-- Feral-gated and Bear-form-gated, so a feral in caster form saw no resource bar whatsoever.
local playerPower = ring("Druid - Player Power Ring", INNER, CLUSTER_X, CLUSTER_Y, COL.mana,
  { orbPower("player"), F.unitCharTrigger() })
playerPower.subRegions[1] = pct("percentpower", PCT_POWER, COL.text)
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

-- uid 10 — Threat (Bear), id unchanged since v7. THREAT IS NOW YOUR OUTERMOST RING (v13), one
-- band outside your health arc on YOUR cluster — which is both where it belongs and what it
-- always measured: your threat, not the target's. It is also the one thing the deleted target
-- cluster carried that nothing else on screen shows, and a feral who pulls aggro dies.
-- Tank-inverted semantics preserved from v7: green while you are securely tanking, RED the
-- moment aggro is lost. `%threatpct` sits ABOVE the ring (PCT_THREAT, +58 — clear of the 100px
-- annulus), the one number in the layer that is above its arc rather than below it, so it can
-- never collide with the health number underneath.
-- The threatvalue guard is NOT cosmetic and is mandatory: threattotal is
-- (threatvalue or 0) * 100 / threatpct, so it is 0 whenever threatvalue is 0 — post-Vanish,
-- post-Feign, the instant before your first hit lands — and a progresstexture with total 0 draws
-- FULL, which would read as complete aggro at exactly zero threat. alpha 0 removes the ring
-- entirely, which is precisely the "no threat table" state: with no hostile target, or before
-- your first point of threat, the cluster is just two rings and a face.
local threatF = ring("Druid - Threat (Bear)", THREAT_RING, CLUSTER_X, CLUSTER_Y, COL.threat,
  { F.threatTrigger() }, notInArena(GATE_F))
threatF.subRegions[1] = pct("threatpct", PCT_THREAT, COL.text)
threatF.conditions = {
  F.condition(1, "aggro", "==", 0, "foregroundColor", COL.danger),
  F.condition(1, "threatvalue", "<=", "0", "alpha", 0),
}

-- uid 11 — Threat (Caster), id unchanged since v7. The SAME outermost ring, at the same 100px on
-- the same centre: the two are mutually exclusive spec gates (Mangle (Bear) vs Moonkin Form) and
-- only one can ever load, so they share the slot exactly as they have since v7. Non-inverted
-- semantics: green, orange at 70% of the pull threshold, red when you pull (severe condition
-- last, so it wins).
local threatB = ring("Druid - Threat (Caster)", THREAT_RING, CLUSTER_X, CLUSTER_Y, COL.threat,
  { F.threatTrigger() }, notInArena(GATE_B))
threatB.subRegions[1] = pct("threatpct", PCT_THREAT, COL.text)
threatB.conditions = {
  F.condition(1, "threatpct", ">=", "70", "foregroundColor", COL.warn),
  F.condition(1, "aggro", "==", 1, "foregroundColor", COL.danger),
  F.condition(1, "threatvalue", "<=", "0", "alpha", 0),
}

-- DISPLAY order. Sibling stacking is exact, not "roughly creation order": FixGroupChildrenOrder
-- walks controlledChildren and adds +4 frame levels per child, so EARLIER = further behind.
-- v14 INVERTS THE ENDS OF THIS LIST. The portrait goes FIRST (adoptFirst, in the block at the
-- bottom of this file where it is constructed), so it is the backdrop and every ring — with its
-- percentage text — stacks above it; the health number now lands ON the face, which is the only
-- opaque thing the HUD owns. That is safe because a ring is an ANNULUS: at 100/84/62 the drawn
-- bands are radius 42.19..50, 35.44..42 and 26.16..31 while the portrait is 0..22, so no arc's
-- art reaches the face at all and only the text does.
-- Order below the portrait: the arcs, then the rage pips (adopted in the v2 block, so they read
-- ON the power ring). The three arcs are concentric at three different diameters and their
-- annuli do not overlap at all, so their relative order is cosmetic — it is kept in uid order.
adopt(gRes, playerHP)
adopt(gRes, playerPower)
adopt(gRes, threatF)
adopt(gRes, threatB)

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

-- R7-R10 Rage thresholds — the bear's two spend decisions, back ON the power ring since v12.
-- v7 drew them as vertical lines over a 172x14 bar; v10-v11 as horizontal waterlines across a
-- vessel. On a ring a threshold is a POINT ON THE CIRCUMFERENCE and needs the trigonometry
-- again, from the ring's own radius (markX / markY at the top of the file):
--   r = INNER/2 * 0.94 ;  x = r * sin(2*pi*f) ;  y = r * cos(2*pi*f)
-- Rage is a 0-100 resource, so the two fractions are simply 0.20 and 0.70 — and because f = 0
-- is 12 o'clock and the angle advances clockwise, each pip sits exactly where the CLOCKWISE fill
-- reaches that value: 20 rage at 72 degrees (upper right), 70 rage at 252 (lower left).
--
-- ROUND PIPS, not lines, and that is forced rather than chosen: rotating a thin quad on a
-- texture region rotates the ART INSIDE the quad (DoTexCoord -> GetRotatedPoints), so a straight
-- line can never be laid along an arc. Circle_Smooth2.tga (F.TEX_CIRCLE) is a solid disc, which
-- is exactly right for a dot and exactly wrong for a ring — the opposite of the ring art.
--
-- These stay FOUR SEPARATE AURAS rather than becoming sub-regions of the ring, deliberately:
-- the aurabar tick sub-region cannot come along at all (SubRegionTypes/Tick.lua's supports()
-- returns true only for "aurabar"), and the two sub-region types that DO support
-- progresstexture would cost the pop. A subtexture/subcirculartexture mark can change colour
-- by condition but cannot carry its own animation, and the pop-in on crossing IS the signal
-- here. Keeping them as regions also keeps their triggers, their Feral gate and their v7 Bear
-- form gate exactly as they were, and keeps them out of the sub.N condition index entirely.
--
-- THE STANDING TRAP: these are stand-alone texture regions anchored to the SCREEN, not
-- sub-regions of the ring, so nothing moves them when the ring they mark changes size or
-- position — and in v12 it changed both, again. Every coordinate is therefore derived from the
-- canonical constants (localX(CLUSTER_X) + markX(f), localY(CLUSTER_Y) + markY(f)) and none is
-- written down, so the marks follow the arc if those numbers ever move again. v13 moved the
-- threat ring onto this cluster but did NOT move the power ring, so every pip is byte-identical.
local RAGE_MAX = 100  -- TBC rage is a flat 0-100 pool, so threshold/max is threshold/100

local function rageMark(id, rageValue, size, color, minRage)
  local fraction = rageValue / RAGE_MAX
  local mark = reg(F.texture(id, CLASS, size, size,
    localX(CLUSTER_X) + markX(fraction), localY(CLUSTER_Y) + markY(fraction),
    nil, F.TEX_CIRCLE, color))
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
rageMark("Druid - Rage Mark Mangle",     20, PIP_DIM, { 0.25, 0.95, 0.45, 0.55 }, nil)
rageMark("Druid - Rage Mark Maul",       70, PIP_DIM, { 1, 0.75, 0.2, 0.55 },     nil)
rageMark("Druid - Rage Mark Mangle Lit", 20, PIP_LIT, { 0.25, 0.95, 0.45, 1 },    20)
rageMark("Druid - Rage Mark Maul Lit",   70, PIP_LIT, { 1, 0.75, 0.2, 1 },        70)

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

-- ================= v12/v13 — the portrait, on the uid it has always had =================
-- v8 added two `model` portraits here, the only genuinely new auras that version drew, and they
-- still draw the last two uids in the file. v10 recycled them into the life and power globe
-- rims when the vessels replaced the clusters; v12 turned them back into faces at the centre of
-- each cluster. v13 deletes the target one with the rest of that cluster and keeps yours, on the
-- same uid, at the same position in the seeded stream.
-- The portrait carries the cluster's trigger pair and alpha guards, so face and arcs appear,
-- fade out of combat and vanish as one object.
-- v14: adopted FIRST, not last. It is still CONSTRUCTED here — the uid stream is positional and
-- moving the constructor would re-identify every aura after it — but adoptFirst() puts it at the
-- FRONT of controlledChildren, i.e. the BOTTOM of the group's frame-level stack, so the rings
-- and their percentage text draw over it. That finally agrees with its frameStrata 2
-- (BACKGROUND), which has said the same thing since v12 while the child order said the reverse.
-- The face is not hidden by this: the arcs are annuli at radius 26.16..50 and the portrait ends
-- at radius 22, so the only thing that ever lands on it is the health number.
local playerPortrait = portrait("Druid - Player Portrait", "player", CLUSTER_X, CLUSTER_Y,
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
-- forgotten conversion or an extra nesting level would all move the clusters silently — the
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
    ("%s lands at (%d,%d), canonical position is (%d,%d)"):format(id, x, y, wantX, wantY))
end
-- The canonical numbers themselves, spelled out as literals exactly once, so that a sign flip in
-- the constants block cannot pass a proof that is written in terms of those same constants.
assert(CLUSTER_X == -270 and CLUSTER_Y == 40,
  ("cluster centre is (%d,%d), the canonical position is (-270,40)"):format(CLUSTER_X, CLUSTER_Y))
assert(THREAT_RING == 100 and OUTER == 84 and INNER == 62 and PORTRAIT == 44,
  "ring diameters drifted from the canonical 100/84/62/44")
-- THE cluster (v13): three concentric rings and a face, all on one centre.
assertAt("Druid - Player Health Ring", CLUSTER_X, CLUSTER_Y)
assertAt("Druid - Player Power Ring",  CLUSTER_X, CLUSTER_Y)
assertAt("Druid - Player Portrait",    CLUSTER_X, CLUSTER_Y)
assertAt("Druid - Threat (Bear)",      CLUSTER_X, CLUSTER_Y)
assertAt("Druid - Threat (Caster)",    CLUSTER_X, CLUSTER_Y)
-- and the four rage pips, the one thing in the layer that is not on the cluster centre
assertAt("Druid - Rage Mark Mangle",     CLUSTER_X + markX(0.20), CLUSTER_Y + markY(0.20))
assertAt("Druid - Rage Mark Mangle Lit", CLUSTER_X + markX(0.20), CLUSTER_Y + markY(0.20))
assertAt("Druid - Rage Mark Maul",       CLUSTER_X + markX(0.70), CLUSTER_Y + markY(0.70))
assertAt("Druid - Rage Mark Maul Lit",   CLUSTER_X + markX(0.70), CLUSTER_Y + markY(0.70))

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

-- BREAKPOINT PROOF (v12). A pip is only a breakpoint if it sits ON the ring it marks, at the
-- angle its threshold implies — and rounding the polar coordinates to whole pixels is the one
-- thing that could quietly push it off the band. Measure each pip back from the cluster centre
-- and assert BOTH polar components: the angle within a degree of 360 * f measured clockwise from
-- 12 o'clock, and the radius inside the drawn annulus (Ring_20px paints diameter * 20/256, so
-- the inner ring's band runs from INNER/2 - stroke to INNER/2).
local function assertOnRing(id, fraction)
  local node = assert(byId[id], "missing aura: " .. id)
  local x, y = absolutePos(node)
  local dx, dy = x - CLUSTER_X, y - CLUSTER_Y
  local radius = math.sqrt(dx * dx + dy * dy)
  local angle = math.deg(math.atan2(dx, dy)) % 360   -- atan2(x, y): 0 = up, grows clockwise
  local want = (fraction * 360) % 360
  local drift = math.min(math.abs(angle - want), 360 - math.abs(angle - want))
  assert(drift <= 1,
    ("%s sits at %.2f degrees, threshold %.0f%% implies %.2f"):format(id, angle, fraction * 100, want))
  assert(radius >= INNER / 2 - RING_STROKE and radius <= INNER / 2,
    ("%s sits at radius %.2f, outside the %g..%g band of the power ring")
      :format(id, radius, INNER / 2 - RING_STROKE, INNER / 2))
end
assertOnRing("Druid - Rage Mark Mangle",     0.20)
assertOnRing("Druid - Rage Mark Mangle Lit", 0.20)
assertOnRing("Druid - Rage Mark Maul",       0.70)
assertOnRing("Druid - Rage Mark Maul Lit",   0.70)

-- CLUSTER PROOF (v13). The cluster only reads as one object while the arcs are concentric at the
-- canonical diameters, and only a `progresstexture` on the CIRCULAR path draws an arc at all — a
-- stray "VERTICAL" here would silently draw a filled disc instead. Assert the geometry and the
-- fill path on the assembled tables, and that every ring's percentage is still sub.1 (conditions
-- address sub-regions positionally, so an inserted sub-region retargets them silently).
local function assertRing(id, size)
  local node = assert(byId[id], "missing aura: " .. id)
  assert(node.regionType == "progresstexture", id .. ": not a progresstexture")
  assert(node.orientation == "CLOCKWISE", id .. ": not on the circular fill path")
  assert(node.width == size and node.height == size,
    ("%s is %gx%g, canonical is %d"):format(id, node.width, node.height, size))
  assert(node.foregroundTexture == RING_TEX and node.backgroundTexture == RING_TEX,
    id .. ": not drawn on the ring annulus")
  assert(node.crop_x == 0.41 and node.crop_y == 0.41, id .. ": crop is not the circular identity")
  assert((node.subRegions[1] or {}).type == "subtext", id .. ": the percentage is no longer sub.1")
end
assertRing("Druid - Player Health Ring", OUTER)
assertRing("Druid - Player Power Ring",  INNER)
assertRing("Druid - Threat (Bear)",      THREAT_RING)
assertRing("Druid - Threat (Caster)",    THREAT_RING)

-- CONCENTRICITY AND SEPARATION (v13). Three arcs on one centre is only true if the annuli do not
-- collide: Ring_20px paints diameter * 20/256 at the OUTER edge of the diameter, so ring d
-- occupies radius (d/2 - d*20/256) .. d/2. Prove the new 100px threat ring shares the health
-- ring's centre exactly and that its band starts outside the health band's end.
local function bandOf(d) return d / 2 - d * 20 / 256, d / 2 end
local hpInner, hpOuter = bandOf(OUTER)
local thInner, thOuter = bandOf(THREAT_RING)
assert(thInner > hpOuter,
  ("the %dpx threat band (%.2f..%.2f) overlaps the %dpx health band (%.2f..%.2f)")
    :format(THREAT_RING, thInner, thOuter, OUTER, hpInner, hpOuter))
for _, id in ipairs({ "Druid - Threat (Bear)", "Druid - Threat (Caster)" }) do
  local tx, ty = absolutePos(byId[id])
  local hx, hy = absolutePos(byId["Druid - Player Health Ring"])
  assert(tx == hx and ty == hy,
    ("%s is not concentric with the health ring: (%d,%d) vs (%d,%d)"):format(id, tx, ty, hx, hy))
  assert(byId[id].subRegions[1].anchorYOffset == PCT_THREAT.y
    and PCT_THREAT.y > THREAT_RING / 2,
    id .. ": the threat percentage is not clear of the " .. THREAT_RING .. "px annulus")
end

-- ALERT-COLUMN CLEARANCE (v13), projected six prompts deep. The threat ring widened the cluster
-- from 84 to 100, i.e. from x -312..-228 to -320..-220, and the Alerts column is a DYNAMIC GROUP
-- that grows vertically at x -150. A dynamic group cannot move a clone sideways while align is
-- CENTER and stagger is 0, so depth cannot change the horizontal answer — but assert that too,
-- because an earlier pass in this repo's history shipped a cluster that only cleared while a
-- single alert was showing. Six deep is well past the pack's realistic worst case (the alert
-- group holds nine prompts in total, of which no spec can ever load all nine at once).
local alerts = byId["Druid - Alerts"]
assert(alerts.grow == "UP" and alerts.align == "CENTER" and alerts.stagger == 0,
  "Druid - Alerts no longer grows straight up: re-derive the clearance below")
local widestAlert = 0
for _, id in ipairs(alerts.controlledChildren) do
  widestAlert = math.max(widestAlert, byId[id].width or 0)
end
local ax, ay = absolutePos(alerts)
local alertLeft, alertRight = ax - widestAlert / 2, ax + widestAlert / 2
local ringLeft, ringRight = CLUSTER_X - THREAT_RING / 2, CLUSTER_X + THREAT_RING / 2
assert(ringRight < alertLeft,
  ("the %dpx cluster reaches x %g and the alert column starts at x %g")
    :format(THREAT_RING, ringRight, alertLeft))
local STACK_DEEP = 6
local stackTop = ay + STACK_DEEP * widestAlert + (STACK_DEEP - 1) * alerts.space
print(("  clearance: cluster x %g..%g | alerts x %g..%g (%d deep reaches y %g) | gap %gpx")
  :format(ringLeft, ringRight, alertLeft, alertRight, STACK_DEEP, stackTop, alertLeft - ringRight))

-- The portrait is the other half of the cluster, and both unit fields are load-bearing:
-- current WA reads model_fileId, WA 3.5.0 read model_path, and the migration between them is
-- gated on IsClassicEra(), which a 2.5.x client is not.
local function assertPortrait(id, unit)
  local node = assert(byId[id], "missing aura: " .. id)
  assert(node.regionType == "model", id .. ": not a model region")
  assert(node.modelIsUnit and node.model_fileId == unit and node.model_path == unit,
    id .. ": must emit BOTH model_fileId and model_path as " .. unit)
  assert(node.portraitZoom, id .. ": portraitZoom off — the model renders full-body")
  assert(node.width == PORTRAIT and node.height == PORTRAIT,
    ("%s is %gx%g, canonical is %d"):format(id, node.width, node.height, PORTRAIT))
end
assertPortrait("Druid - Player Portrait", "player")

-- READABILITY PROOF (v14). The health number is only "in the middle" if BOTH halves of this
-- change shipped, and each half is silent on its own: the offset without the reorder puts the
-- text under a face, and the reorder without the offset moves nothing anyone can see. Assert
-- both, against the ASSEMBLED tables, and spell the canonical numbers as literals here exactly
-- once so a later edit to the constants block cannot pass a proof written in those constants.
assert(PCT_HP.y == 0 and PCT_HP.size == 16,
  ("the health percentage is %gpt at y %g; v14 ships 16pt dead centre"):format(PCT_HP.size, PCT_HP.y))
assert(PCT_POWER.y == -54 and PCT_POWER.size == 12,
  ("the power percentage is %gpt at y %g; v14 ships 12pt at -54"):format(PCT_POWER.size, PCT_POWER.y))
assert(PCT_THREAT.y == 58 and PCT_THREAT.size == 10, "the threat percentage moved; v14 does not move it")
-- The two moved labels, as they are actually shipped: offset, size, and the OUTLINE that is what
-- keeps a white number legible on a lit 3D model.
local function assertLabel(id, token, size, y)
  local st = assert(byId[id], "missing aura: " .. id).subRegions[1]
  assert(st and st.type == "subtext", id .. ": the percentage is no longer sub.1")
  assert(st.text_text == token, ("%s: text is %q, expected %q"):format(id, tostring(st.text_text), token))
  assert(st.text_fontSize == size and st.anchorYOffset == y and st.anchorXOffset == 0,
    ("%s: %gpt at (%g,%g), expected %dpt at (0,%d)")
      :format(id, st.text_fontSize, st.anchorXOffset, st.anchorYOffset, size, y))
  assert(st.text_anchorPoint == "CENTER" and st.text_fontType == "OUTLINE",
    id .. ": the percentage lost its CENTER anchor or its OUTLINE")
end
assertLabel("Druid - Player Health Ring", "%percenthealth%%", 16, 0)
assertLabel("Druid - Player Power Ring",  "%percentpower%%",  12, -54)
assertLabel("Druid - Threat (Bear)",      "%threatpct%%",     10, 58)
assertLabel("Druid - Threat (Caster)",    "%threatpct%%",     10, 58)

-- DRAW ORDER (v14). controlledChildren IS the sibling stack — FixGroupChildrenOrder adds +4
-- frame levels per child, so FIRST is furthest behind — and the health number lands ON the face,
-- so the face has to be first and every ring has to follow it. Assert on the group AND on the
-- flat child list, because the transmit is what actually ships and F.assemble is the only thing
-- keeping the two in step.
assert(gRes.controlledChildren[1] == "Druid - Player Portrait",
  "the portrait is not the first child of Druid - Rings: its face would cover the percentages")
local cIndex = {}
for i, child in ipairs(transmit.c) do cIndex[child.id] = i end
for _, id in ipairs({ "Druid - Player Health Ring", "Druid - Player Power Ring",
                      "Druid - Threat (Bear)", "Druid - Threat (Caster)" }) do
  assert(cIndex[id] > cIndex["Druid - Player Portrait"],
    id .. " is listed before the portrait: its percentage would draw under the face")
end
-- And the reason that is safe: no ring's ART touches the face, only its text. Ring_20px paints
-- diameter * 20/256 at the outer edge, so each band starts well outside the 22px portrait radius.
for _, pair in ipairs({ { "Druid - Threat (Bear)", THREAT_RING }, { "Druid - Threat (Caster)", THREAT_RING },
                        { "Druid - Player Health Ring", OUTER }, { "Druid - Player Power Ring", INNER } }) do
  local bandInner = bandOf(pair[2])
  assert(bandInner > PORTRAIT / 2,
    ("%s's band starts at radius %.2f, inside the %gpx portrait radius — it would cover the face")
      :format(pair[1], bandInner, PORTRAIT / 2))
end

local encoded = W.encode(transmit)
W.verify(transmit, encoded)

local txtPath = dir .. "/all-specs.txt"
-- Continuity vs the PREVIOUS shipped string (read before overwriting it). v13 spent this pack's
-- one removal licence and v14 does not need it: no aura is added, removed or renamed, and
-- reordering children consumes no uid, so the STRICT default applies again — every previous uid
-- must survive (missing = 0) and an id that keeps its name while swapping uid (changed) is never
-- forgivable at all. v13's three ids are already gone from the string this compares against.
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
