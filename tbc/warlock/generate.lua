-- generate.lua — Warlock TBC All-Specs HUD (v17).
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
-- v10 (the globes FLANK the character, and the glass CATCHES LIGHT):
--   * POSITION. v9 parked all three vessels on one band under the HUD
--     (y = -262), which read as a separate bar bolted on rather than as part of
--     the character. They now stand beside the character, at ABSOLUTE screen
--     coordinates shared byte-for-byte with the other six packs:
--         LIFE   (-190,  40)   POWER  (+190,  40)   TARGET  (0, 110)
--     The two player vessels keep one shared line so the Life Tap read is still
--     one glance; the target's sits above and between them, where the eye goes
--     for a nameplate. Sizes are UNCHANGED — 72 px main, 44 px target, rim +4.
--   * WHY NOT ±170 OR ±210. Both collide. x = ∓170 runs into the Alerts column
--     (x = -150) and the PvP column (x = +150), which every pack carries; ±210
--     runs into the PvP layer's elements at (200, -44). ±190 is the one width
--     that clears both, so it is a fixed cross-pack contract, not a taste call.
--   * TWO CLUSTER OFFSETS NOW, both still DERIVED from the absolute targets
--     (see THE ABSOLUTE-POSITION RULE below): the player pair and the target
--     vessel no longer share a line, so `Warlock - Target Globe` gets its own
--     CLUSTER_TGT_Y. Nothing below the clusters changed — each globe still
--     carries its own GLOBE_X and a local y of 0.
--   * This also ends v9's honest note about the target globe sitting on top of
--     the DoT row: the DoT icons are at y = -156 and the target vessel is now
--     at +110, so the two no longer share screen space.
--   * LOOK. Every one of the three vessels gets a SPECULAR HIGHLIGHT: a soft,
--     off-centre bright spot in the upper left, which is what the eye reads as a
--     curved glass surface catching light instead of a flat coloured sticker.
--     It is a `subtexture` sub-region — Circle_Smooth again, white at 28%,
--     0.46 x 0.34 of the globe, offset (-0.17, +0.21) of the globe.
--   * BLEND MODE IS "ADD", AND THAT IS THE WHOLE REASON THE RECIPE IS A
--     HIGHLIGHT RATHER THAN THE MORE OBVIOUS DARK EDGE VIGNETTE. The percentage
--     lives INSIDE the glass and sub-regions draw in order, so an appended BLEND
--     overlay would paint over the number and dim it. ADD only ever brightens,
--     so the text stays readable underneath.
--   * THE HIGHLIGHT IS APPENDED, NEVER INSERTED. Conditions address sub-regions
--     POSITIONALLY as sub.N, so inserting ahead of a referenced index silently
--     retargets it at a different sub-region with no error anywhere. Appending
--     cannot: the percentage text stays subRegions[1] on all three vessels and
--     the highlight lands at [2], last. (Nothing in this pack points a condition
--     at a globe sub-region today — the sub.N conditions here are all on Alerts
--     icons — but the rule is what keeps that true after the next edit.)
--   * NO AURA WAS ADDED, REMOVED, RENAMED OR REORDERED and not one W.uid() call
--     moved: a highlight is a sub-region of an aura that already exists, and a
--     position is a group offset. All 44 v9 uids are byte-for-byte stable.
--   * NOTHING ELSE CHANGED: not one trigger, load gate, condition, colour, spell
--     id or region type. Buffs, alerts, the DoT row, the cooldown row, the procs
--     and the whole PvP layer are untouched.
--
-- v11 (THE RINGS ARE BACK — two rings and a live face, per cluster):
--   * The Diablo globes are gone. The v7/v8 design returns, at ONE canonical set
--     of proportions shared byte-for-byte by all seven packs and declared as
--     named constants below: OUTER 84 / INNER 62 / PORTRAIT 44 (44/84 = the 0.52
--     face-to-ring ratio), clusters at ABSOLUTE (-270, 40) and (+270, 110).
--   * TWO MATCHED CLUSTERS, each two rings around a live 3D portrait:
--       PLAYER  outer = health, inner = mana,          centre = player portrait
--       TARGET  outer = THREAT, inner = target health, centre = target portrait
--     Identical outer, inner and face diameters on both sides is the whole reason
--     they read as a pair. A target POWER ring is deliberately NOT built: three
--     rings on one side and two on the other is exactly what made v8 look busy
--     and uneven.
--   * orientation flips "VERTICAL" -> "CLOCKWISE", which switches the region from
--     the linear fill path back to the circular one and changes which fields are
--     live: startAngle/endAngle matter again, compress/slanted/slantMode go inert,
--     and crop_x/crop_y 0.41 is the IDENTITY value on the circular path (it
--     cancels the sqrt(2) expansion) rather than a texcoord scale. Texture goes
--     back to Ring_20px, a true annulus; Circle_Smooth (a solid disc) would fill
--     as a pie wedge.
--   * THE PORTRAITS ARE BACK, which is what moves the percentages back OUTSIDE
--     the rings: a `model` region cannot carry a text sub-region at all, so with
--     a face in the middle the numbers ride on their rings just past the outer
--     radius — health 13 pt at y = -54, power 10 pt at y = -70, threat 10 pt at
--     y = +54, the same offsets on both clusters. Both `model_fileId` AND
--     `model_path` carry the unit string (see the portrait note below).
--   * THE SPECULAR HIGHLIGHT IS DROPPED: it was glass on a filled vessel and does
--     nothing on a ring. Both player rings and the target's lose their v10
--     sub-texture and keep the percentage as their only sub-region.
--   * EVERYTHING BEHAVIOURAL CARRIES OVER UNCHANGED: health amber at <=60%, mana
--     violet at <30%, threat green -> orange at 70% -> red on aggro, the
--     out-of-combat fade, the party/raid + not-in-an-arena gates, the >=80% flash
--     halo and every zero-total guard including the mandatory threatvalue <= 0 ->
--     alpha 0. Threat's escalation is RE-POINTED from the texture property
--     `color` to the progresstexture property `foregroundColor`, because its
--     region type changed back — a mechanically copied `color` (like a copied
--     `barColor`) is a silent no-op that Conditions.lua skips without a warning.
--   * NOT ONE W.uid() CALL WAS ADDED, REMOVED OR REORDERED. All ten cluster auras
--     are recycled in place, and six of them go back to the identity they had in
--     v8: the two player globes become the player's two rings, the threat rim
--     becomes the threat RING, the two "globe rims" that were the v8 portraits
--     become the two PORTRAITS again, the target globe becomes the target's inner
--     health ring, and the brass target rim — which was v8's target MANA ring —
--     becomes the target's outer TRACK (see its note below). All 44 uids are
--     byte-for-byte stable, so a v10 import offers Update with nothing orphaned.
--   * NOTHING OUTSIDE THE CLUSTERS CHANGED: not one trigger, load gate, condition
--     or spell id in the buffs, alerts, DoT row, cooldown row, procs or PvP layer.
--
-- v12 (ONE CLUSTER — the target cluster is deleted and threat comes home):
--   * THE ENTIRE TARGET CLUSTER IS GONE: its health ring, its outer track ring,
--     its live portrait and the group that held them. The target's health is
--     already on the target frame and on its nameplate, so for the whole game
--     that cluster was a second copy of the default UI parked at (+270, 110).
--     Four auras removed, 44 -> 40.
--   * THREAT MOVES, IT DOES NOT DIE. It is the one thing that cluster carried
--     which nothing else on screen shows, and a dps who pulls aggro dies. It
--     becomes the OUTERMOST ring of the PLAYER cluster, which is also the more
--     honest reading: it is YOUR threat, not the target's.
--       THREAT_RING 100  (outermost, same Ring_20px annulus)
--       OUTER        84  (health, unchanged)
--       INNER        62  (mana, unchanged)
--       PORTRAIT     44  (unchanged)
--       cluster at ABSOLUTE (-270, 40), unchanged
--       threat percentage: 10 pt, CENTER, anchorYOffset +58 (above the new ring)
--     The >=80% flash halo resizes 96 -> 100 so it pulses ON the threat ring
--     instead of orbiting the radius of a ring that no longer exists there.
--   * THREAT KEEPS EVERYTHING ELSE: the same Threat Situation trigger, the same
--     escalation on `foregroundColor` (green -> orange at 70% -> red on aggro),
--     the party/raid gate, the not-in-an-arena gate, the out-of-combat fade and
--     the mandatory `threatvalue <= 0 -> alpha 0` guard. Because it is still
--     party/raid-gated and still self-hides at zero threat, the common solo case
--     is two rings and a face; the third arc only appears when threat is real.
--   * THE TRIGGER'S UNIT ARG IS `threatUnit`, NOT `unit`. The Threat Situation
--     prototype renamed that arg at internalVersion 51 and Modernize migrates
--     < 51 data forward, so IV-45 data must emit the OLD name and let the
--     migration rename it. v11 additionally emitted `unit`, an internalVersion-51+
--     field on internalVersion-45 data; it is dropped, the era-correct
--     `use_threatUnit`/`threatUnit` pair (which was always there) does the work.
--   * ORPHANS ARE EXPECTED HERE, AND THAT IS THE POINT. Every previous version of
--     this pack recycled uids so an update left nothing behind; this time regions
--     are genuinely REMOVED, and inventing filler regions to absorb their uids is
--     how a HUD accumulates junk. The four removed regions were the LAST FOUR
--     W.uid() calls in the seeded stream, so removing them shifts nothing: all 40
--     surviving uids are byte-for-byte identical (changed = 0). WeakAuras never
--     deletes an aura an import does not mention, so after updating, the leftover
--     group `Warlock - Target Orb` must be deleted by hand — it is named in the
--     README for exactly that reason.
--   * NOTHING ELSE MOVED: every trigger, gate, condition and colour outside the
--     clusters is untouched — buffs, alerts, DoT row, cooldown row, procs, PvP.
--
-- v13 (THE HEALTH NUMBER MOVES INTO THE MIDDLE, ONTO YOUR FACE):
--   * THE COMPLAINT, VERBATIM: "percentage in middle can't be seen". It could not
--     be seen because it was never in the middle. v11 pushed both numbers OUTSIDE
--     the rings when the portrait came back (a `model` region cannot carry a text
--     sub-region, so the numbers had to ride on the rings), and they stayed there
--     through v12: health 13 pt at y -54 and mana 10 pt at y -70 — two small
--     detached figures floating under the cluster, over whatever the game world
--     happened to be showing. Against a bright background they are unreadable.
--   * THE FIX IS TO USE THE MIDDLE. The rings' text sub-regions are anchored to
--     the ring CENTRE, so a y offset of 0 puts the health number dead centre, over
--     the portrait — the darkest, most stable backdrop in the whole cluster and
--     the one place the eye already goes. It grows 13 -> 16 pt because it is now
--     the cluster's headline number rather than a caption under it.
--       health  %percenthealth%%  y -54 -> 0    13 -> 16 pt
--       mana    %percentpower%%   y -70 -> -54  10 -> 12 pt
--       threat  %threatpct%%      y +58 unchanged, 10 pt unchanged
--     Mana takes the slot health vacates rather than staying at -70: one number
--     under the cluster instead of two, tucked just under the 84 ring's radius of
--     42, and 2 pt larger now that it is not competing with a bigger sibling
--     directly above it. Every label keeps its OUTLINE font type, its shadow, its
--     colour and its text token — only the offsets and two sizes moved.
--   * AND THE HALF THAT IS NOT A COORDINATE: DRAW ORDER. Moving the health number
--     to y 0 alone would have looked like nothing happened, because the portrait
--     was the LAST child of the cluster. FixGroupChildrenOrder walks
--     controlledChildren and adds +4 frame levels per child, so LATER = further
--     FORWARD, and the face was drawn over everything the rings put in the middle.
--     The portrait becomes the FIRST child instead:
--       v12  { Threat, Health, Mana, Portrait, Threat Flash }
--       v13  { Portrait, Threat, Health, Mana, Threat Flash }
--     This is safe ONLY because a ring is an ANNULUS. Ring_20px draws a band from
--     0.84375r to r, so the three arcs occupy 42.19..50, 35.44..42 and 26.16..31,
--     and the face is 0..22 — no band overlaps the face at any radius. Drawing the
--     rings above the portrait therefore hides none of it; the only thing that
--     lands on the face is the text, which is the entire point.
--   * A COMMENT THAT WAS WRONG IS NOW RIGHT. Two places in this file claimed
--     "frameStrata 2 puts the face above its rings no matter how the children are
--     ordered". That is backwards: WeakAuras' frame_strata_types[2] is BACKGROUND,
--     the LOWEST strata — below the inherited strata (1) the rings use, not above
--     it. The mage pack documents the same fact for its rims. The portrait keeps
--     frameStrata 2, which means it was ALREADY behind its rings and the strata
--     never fought this change; the child reorder makes the frame-LEVEL layer agree
--     with the strata layer instead of contradicting it. The comment mattered
--     because the next person to read it would have "fixed" the strata to put the
--     face genuinely on top, and buried the number again.
--   * NOT ONE AURA ADDED, REMOVED OR RENAMED, and not one W.uid() call added,
--     removed or reordered. uids are assigned where a region is CONSTRUCTED, and
--     nothing moved there — only the `adopt` calls that wire the cluster changed
--     order, and F.assemble derives both controlledChildren and the flat c-list
--     from those, so the two stay depth-first consistent by construction. All 40
--     uids byte-for-byte stable: stable=39, changed=0, missing=0.
--   * THE v12 REMOVAL LICENCE EXPIRES HERE, as designed. The four
--     `-- WA-REMOVED (v12):` tags stay as lineage but are no longer honoured — the
--     verifier only accepts tags matching the version a pack currently ships — and
--     W.assertUidContinuity is called with NO allowance, so v13 is back on the
--     default contract: no uid may disappear, full stop.
--   * NOTHING ELSE CHANGED: not one trigger, load gate, condition, colour, size,
--     diameter or position. The cluster is still at (-270, 40), the rings are still
--     100/84/62 around a 44 px face, and everything outside the cluster — buffs,
--     alerts, DoT row, cooldown row, procs, PvP — is untouched.
--
-- v14 (THE SILL — the ring cluster becomes a 102x31 instrument strip under you):
--   * THE CLUSTER IS GONE. Three concentric arcs around a live 3D portrait at
--     (-270, 40) are replaced by THREE STACKED 100 px RAILS on a dark plate at
--     ABSOLUTE (0, -110) — the design's four-lane strip minus lane 4, because a
--     warlock has no discrete class resource to put there — sitting directly
--     under the character, where ONE PIXEL IS ONE PERCENT. A 0-100
--     quantity has exactly 100 distinguishable states, so a 100 px rail is the
--     length at which the gauge is lossless: every pixel beyond it re-draws a
--     state the eye cannot separate, every pixel below it discards one. The
--     shipped cluster spent 10,000 px2 to carry three of those gauges; the strip
--     carries the same three in 3,162 px2 — 3.16x the information per pixel —
--     and 19.4% of the old box was a 44 px model carrying no decision at all.
--   * WHY A BAR BEATS AN ARC HERE. A ring buys arc length with area squared: at
--     the shipped diameters the three arcs were 289.6 / 243.3 / 179.6 px of
--     gauge, i.e. 712 px of ink for 300 readable states, all of it curved, none
--     of it comparable between rings because each arc had a different radius.
--     Four parallel rails on one origin are directly comparable by eye, and every
--     breakpoint becomes arithmetic instead of trigonometric:
--         x(v) = (v / maxpower - 0.5) * 100,  which for a 100-max gauge is x = v - 50
--     The shipped rogue pack needs r = size/2 * 0.94; x = r*sin(2*pi*f) to put the
--     35-energy mark at (23.575, -17.128). The Sill puts the 70% threat notch at
--     x = +20 and that is the whole calculation.
--   * GEOMETRY, exact, local to the group at absolute (0, -110), in DRAW ORDER:
--       Alarm rim     texture         108 x 37   (0, +3)
--       Sill Plate    texture         102 x 31   (0, +3)
--       Threat rail   progresstexture 100 x  4   (0, +15.5)
--       Health rail   progresstexture 100 x 11   (0, +7)
--       Power rail    progresstexture 100 x 11   (0, -5)
--     4 + 1 + 11 + 1 + 11 = 28 px of content spanning local +17.5 .. -10.5; the
--     plate adds a 1 px margin above and 2 px below. A warlock has NO discrete
--     class resource, so there is no lane 4 (the rogue's combo pips and the mage's
--     arcane pips live there) and the plate is 31 tall rather than 37. The three
--     rails' local offsets are identical in all seven packs, so the strip reads
--     the same on every character.
--   * (0, -110) IS UNDER THE CHARACTER AND IT IS THE ONLY GOOD y. The universal
--     free band below the crosshair is bounded by two rows this repo already
--     ships: paladin's and hunter's buff rows at y -80..-40, and the other five
--     packs' buff rows at y -176..-136 (this pack's DoT row is exactly that, at
--     y -156). A 102x37 rectangle centred on -110 clears the first by 11.5 px and
--     the second by 7.5 px, and is the widest-margin position that is collision
--     free in ALL SEVEN packs with dynamic groups projected six children deep.
--     -21 (the design's first draft) also scans clean but is the character's
--     WAIST, not under it, and leaves 0.5 px to two packs' buff rows.
--   * ORIENTATION IS "HORIZONTAL", which is WeakAuras for "Left to Right"
--     (Private.orientation_with_circle_types: HORIZONTAL = "Left to Right",
--     HORIZONTAL = "Right to Left"). This is the linear fill path, the same one
--     the v9/v10 globes used with "VERTICAL"; startAngle/endAngle go inert,
--     compress/slanted/slantMode go live, and crop_x/crop_y 0.41 stops being the
--     circular identity value and becomes a plain texcoord scale on a uniform
--     white square, where it cannot alter the art.
--   * EVERY NUMBER MOVES INSIDE ITS OWN RAIL. `%percenthealth%%` and
--     `%percentpower%%` drop 16/12 pt -> 11 pt and sit at anchorXOffset +32,
--     anchorYOffset 0 — the right-hand end of their own rail, on the dark plate,
--     which is what the v13 "percentage in middle can't be seen" complaint was
--     actually about: contrast, not coordinates. The plate is the fix that
--     survives a snowfield and a fire.
--   * THE RULER. Each 11 px rail gains three 1 px hairlines at x -25 / 0 / +25 at
--     18% white: 33 px of ink, zero footprint, and it turns "estimate a fraction"
--     into "count quarters". The threat rail gains ONE 2 px notch at x +20 = the
--     70% line where this pack has always turned the arc orange.
--   * WHAT IS LOST, said plainly: the live 3D portrait (v11 brought it back on
--     the grounds that "two arcs around a face read as a unit — you"; v14 reverses
--     that on density grounds, and it is the most likely complaint), and the
--     threat NUMBER, which is switched off rather than deleted — `text_visible =
--     false` on a sub-region whose index is preserved, so it is one checkbox away
--     in /wa. threatpct is scaled so 100 = pulling aggro, i.e. an early-warning
--     ratio rather than a quantity you spend, and a fill crossing a notch answers
--     it faster than reading "68" and comparing it to a remembered 70.
--   * THE 80% ALARM IS AN OVERSIZED QUAD DRAWN UNDERNEATH, WHICH IS HOW A FILLED
--     TEXTURE MAKES A RIM. Square_White_Border.tga was decoded out of a real game
--     install: 256x256, 32 bpp, RLE, and 64,516 of its 65,536 pixels — 98.44% —
--     are FULLY OPAQUE (alpha 255). Every pixel inset 8 px or more from the edge
--     (n = 57,600) has alpha 255 and no RGB channel below 167; the centre pixel is
--     rgba(255,255,255,255) and the centre scanline's red channel runs
--     0,156,100,56,40,57,102,158,206,236,250,254,255,255 across x = 0..13. It is a
--     FILLED square with a dark bevel baked into its EDGE — not an outline, and its
--     interior is not transparent.
--     A single region on that art therefore cannot trace a hollow edge. Shipped at
--     the plate's size on top of the stack (the first cut of v14) it is a full-area
--     ADD red quad over every rail, every number and every mark at exactly the
--     moment the player has to read them. So the alarm is 108x37 — 3 px larger than
--     the 102x31 plate on every side — and is drawn FIRST, at the BOTTOM of the
--     stack: the 3 px band protruding past the plate is the only part that ever
--     draws, and everything inside sits behind a 45%-black plate and behind every
--     readout. The construction is correct whether the art is filled or hollow,
--     which is why it is the one built. Size and draw index are two halves of one
--     mechanism and both are asserted; drop either and the rim becomes a wash.
--     (The sibling rogue pack ships the identical 3 px construction.)
--   * THE PLATE'S frameStrata CHANGES, and it is the ONE non-geometry field
--     besides `color` that does: v13's portrait carried frameStrata = 2
--     (BACKGROUND, set deliberately to put the model behind the rings); F.texture
--     emits frameStrata = 1 (Inherited) and v14 keeps that. It is not a
--     regression, because the plate is child #1 of the group and WeakAuras'
--     FixGroupChildrenOrder gives each child +4 frame levels in controlledChildren
--     order, so the plate still draws behind all three rails and behind the alarm.
--     Asserted below rather than left to chance. Measured by a whole-record diff
--     keyed on uid — every leaf field, not a chosen subset — SEVEN records differ
--     from v13: the six strip auras, plus `Warlock - Resources`, whose
--     controlledChildren entry follows the group's rename. Outside geometry, the
--     ring->rail art swap (orientation / fore- and backgroundTexture), the
--     sub-region rebuild, the renames and the model->texture re-type's own field
--     set, `color` and this `frameStrata` are the only two fields that move.
--   * NOT ONE W.uid() CALL WAS ADDED, REMOVED OR REORDERED, and nothing is
--     removed at all. Every one of the six cluster auras is recycled in place:
--     the three rings become the three rails, the PORTRAIT becomes the SILL PLATE
--     (model -> texture, the v9/v11 re-type trick again), the flash halo becomes
--     the ALARM RIM, and the group is renamed. Renaming, re-parenting, re-ordering,
--     re-typing and resizing are all free — only the uid() CALL ORDER is sacred —
--     so all 39 v13 child uids are byte-for-byte stable and W.assertUidContinuity
--     runs with NO allowance list.
--   * THE UPDATE DIALOG'S `Arrangement` CATEGORY MUST BE LEFT CHECKED. This
--     version moves the group from (-270, 40) to (0, -110) and changes every
--     region's size and offset; both travel in Arrangement. Unchecking it keeps
--     the v13 ring geometry and the import does nothing visible. It DOES re-order
--     controlledChildren: v13 listed the portrait first and the ring HALO last,
--     which is right for an annulus with a hole in it; v14's alarm is a filled quad
--     so it moves to child #1 with the plate at #2. Group order travels in
--     Arrangement too.
--   * NOTHING OUTSIDE THE STRIP CHANGED: not one trigger, load gate, condition,
--     colour or spell id in the DoT row, the alerts, the cooldown row, the procs
--     or the PvP layer, and the three rails keep their own triggers, gates and
--     escalation colours byte-for-byte from v13. Measured, not asserted from
--     memory: a whole-record diff of both decoded strings keyed on uid finds ZERO
--     differing fields under `triggers`, `conditions`, `load`, `animation` or
--     `actions` on any of the 40 auras, inside the strip or outside it.
--   * THE PROOF BLOCK PINS VALUES, NOT JUST WIRING (build-script only — the
--     shipped string is byte-identical, so this is not a version bump). The first
--     cut of the v14 canon contained assertions that could not fail, because they
--     were phrased in the same symbol that produced the value:
--         assert(PLAYER_GY == SILL_Y - TOP_Y - RES_Y)  -- PLAYER_GY IS that
--         assertAt(id, SILL_X, SILL_Y + s.y)           -- SILL_Y proving SILL_Y
--     Mutation-tested: SILL_Y -110 -> -21, PLATE_H 31 -> 37, LANE_THREAT 15.5 ->
--     14 (which makes the threat and health rails OVERLAP by 0.5 px) and RULER_W
--     1 -> 3 all rebuilt and printed "OK: 40 auras" with the wrong geometry in a
--     perfectly valid string. Section 0 below now writes every number the design
--     fixes a second time as a bare LITERAL and checks the build constants AND the
--     decoded string against it, plus four INDEPENDENT derivations that catch a
--     two-place edit as well: free-band containment for the absolute y, exact
--     inter-lane gaps, exact plate margins, and the ruler's ink budget. Two more
--     holes closed with them: the silent-no-op guard covered only the THREAT rail
--     (health and mana could have been switched to `barColor`/`color` — dead
--     escalation, no error anywhere — and shipped), and nothing asserted that the
--     three lanes do not overlap EACH OTHER, only that they fit on the plate.
--
-- v15 (the number offsets were never applied) and v16 (every rail filled
-- right-to-left) are one-field corrections with no lineage block of their own; both
-- are documented at the site they changed — F.subtextOffset in wa_factory.lua, and
-- the `orientation = "HORIZONTAL"` note in the Sill section below.
--
-- v17 (LONG AND THIN — the canonical strip profile, 1.6 PIXELS PER PERCENT):
--   * THE SHAPE IS THE POINT, AND IT IS NOT "BIGGER". The repo tried scaling the
--     strip uniformly twice (paladin/rogue at 300 px and at 200 px rails) and the
--     player rejected both: uniform scaling preserves the original 2.8:1 plate, so
--     it makes the same stubby block bigger and reads as a UI PANEL rather than a
--     readout. A vitals bar wants to be LONG AND THIN — the fill's TRAVEL is the
--     signal and its thickness carries nothing. This pack therefore goes to the
--     canonical profile rogue arrived at in v60, which is 60% longer than v14's
--     rail while being barely taller:
--
--         rails      100 x 11   ->  160 x 13
--         threat     100 x  4   ->  160 x  5
--         plate      102 x 31   ->  164 x 36      ( = RAIL_LEN + 4 x 33 of content)
--         alarm rim  108 x 37   ->  172 x 44      (RIM 3 -> 4 per side)
--         numbers     11 pt @ +32 -> 12 pt @ +51  (threat 10 -> 9 pt, still OFF)
--         ruler        1 px     ->    2 px hairlines; the 70 notch stays 2 px
--
--     The plate goes 3,162 -> 5,904 px2 (+87%) for 60% more travel on every gauge.
--     Compare the alternative that was tried and rejected twice elsewhere in this
--     repo: scaling the whole strip by 1.6 would give a 163 x 50 plate — 8,150 px2,
--     +158% — for exactly the same 60% of extra travel, because area grows with the
--     square while the READING grows with the length. Height is the axis to spend
--     nothing on, which is why the bars go 11 -> 13 and not 11 -> 18.
--   * WHY 160 AND NOT A ROUND NUMBER. Every value this pack marks is a multiple of
--     five — the 70 threat notch and the 25/50/75 ruler — and 1.6 x 5 = 8, so every
--     mark still lands on a WHOLE PIXEL: the notch at x +32 and the ruler at -40 / 0
--     / +40. The invariant was never the number 100 (v14's "one pixel is one
--     percent"); it is that markX() is the ONE place a coordinate is derived, which
--     is what lets the length be a single constant. Proven below, mark by mark.
--   * THE LANE STACK IS DERIVED, NOT COPIED. The canonical stack is threat 5 |
--     health 13 | power 13 with 1 px gaps = 33 px of content, and the plate is 36
--     (a warlock has no discrete class resource, so there is still no lane 4; the
--     four-lane variant is 45). This pack centres its plate at LOCAL y +3, which
--     rogue does not, so the lane offsets are COMPUTED from PLATE_Y and PLATE_H
--     rather than copied from rogue: content top = +19.5, giving threat +17,
--     health +7 (unmoved from v14) and power -7, with EVEN 1.5 px margins above
--     and below instead of v14's 1 / 2 split.
--   * THE STRIP DOES NOT MOVE, AND THAT IS A MEASUREMENT. The new 172 x 44 alarm
--     envelope at the unchanged absolute (0, -110) spans y -129..-85, which still
--     sits inside the repo-wide free band (-136..-80) with 7 px to the DoT row
--     below and 5 px to the band's top edge. Packs that were ENLARGED had to move
--     their buff rows; this one was never enlarged, so nothing moves.
--   * THE PvP COLUMN MOVES, x +150 -> +190, AND IT IS NOT ABOUT THE STRIP. The
--     sill-versus-everything scan structurally cannot see two flanking stacks
--     overlapping EACH OTHER. An ALL-PAIRS scan (added below) says the PvP column
--     was already covering two of its neighbours before this version, because
--     "Warlock - Enemy Mana" is a 120 px aurabar and therefore sets the column's
--     box to x +-60 around its anchor at ANY depth its stack reaches:
--         PvP x 90..210 vs the cooldown row's x -106..106  -> 16 px of overlap
--         PvP x 90..210 vs "Warlock - Siphon Life" at 68..108 -> 18 px of overlap
--     The measured minimum for zero clearance is x +169. This version takes +190,
--     which leaves 24 px to the cooldown row, 22 px to the DoT row and 44 px to the
--     new alarm rim. The column is no longer the mirror image of Alerts at -150,
--     and it cannot be: the 120 px bar is 2.7x the width of the widest alert icon.
--   * NOTHING ELSE CHANGES. No aura is added, removed, renamed or re-parented; not
--     one trigger, load gate, condition, colour or spell id moves; and not one
--     W.uid() call changes place. All 39 child uids are byte-for-byte v16's and
--     W.assertUidContinuity runs with NO allowance list.
--
-- UID ORDER IS SACRED: the two v2 auras are built at the BOTTOM of this file so
-- every pre-v1 uid() call keeps its position in the seeded stream. v3 is a
-- load-gate-only change: no aura added, removed, renamed or reordered. v4's
-- nine auras are built after them, at the very bottom, for the same reason.
-- v5's single new aura is built below all of those, at the very end.

-- The four auras v12 deletes, declared for the verifier (tools/verify-packs.lua reads
-- these lines, and W.assertUidContinuity below is handed the same list). They are the
-- LICENCE for four disappearing uids: an undeclared disappearance is still a hard
-- failure, and the licence expires by itself at v13 because the tag carries the version.
-- WA-REMOVED (v12): Warlock - Target Orb
-- WA-REMOVED (v12): Warlock - Target Health
-- WA-REMOVED (v12): Warlock - Target Ring Track
-- WA-REMOVED (v12): Warlock - Target Portrait
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
-- THE SILL — CANONICAL RAIL GEOMETRY, SHARED BY ALL SEVEN CLASS PACKS (v17)
--
-- Declared as named constants so a later edit has to notice it is breaking a
-- shared contract. Every number here is fixed repo-wide, exactly as the ring
-- diameters were from v11 to v13: seven packs given a design intent instead of
-- dimensions is what produced "the orbs do not match" in v7.
-- DO NOT retune, scale or "improve" any of them in one pack.
--
-- THE PROFILE (v17), and the reason it is shaped this way rather than merely
-- bigger: RAIL_LEN 160, threat 5, bars 13, RIM 4, plate = RAIL_LEN + 4 wide by
-- 36 tall (45 in a pack that has a fourth, class-resource lane), numbers 12 pt at
-- x +51, ruler hairlines 2 px. A vitals bar wants to be LONG AND THIN: the fill's
-- TRAVEL is the signal and its thickness carries nothing, which is why the two
-- earlier attempts at this — uniform 3x and 2x scales, which preserved the plate's
-- original 2.8:1 shape — were rejected in play as UI panels rather than readouts.
-- =====================================================================

-- Bundled WeakAuras media, present for everyone with no media addon.
-- Square_White is a uniform white square: as a progresstexture fill it is a clean
-- bar at any aspect ratio, and as a 1 px sub-texture it is a hairline. There is no
-- orientation in the art, so textureRotate/textureRotation stay off.
-- Square_White_Border is the SAME FILLED SQUARE with a dark bevel baked into its
-- EDGE — it is NOT a hollow frame and its interior is NOT transparent.
--
-- MEASURED, by decoding the shipped .tga out of a real game install rather than
-- inferring it from how the repo happens to use the file:
--   Interface/AddOns/WeakAuras/Media/Textures/Square_White_Border.tga
--   256 x 256, 32 bpp, RLE. 64,516 of 65,536 pixels — 98.44% — are FULLY OPAQUE
--   (alpha 255). Every pixel inset 8 px or more from the edge: n = 57,600,
--   min alpha 255, min RGB channel 167. The centre scanline's red channel over
--   x = 0..13 reads 0, 156, 100, 56, 40, 57, 102, 158, 206, 236, 250, 254, 255,
--   255, and the centre pixel is rgba(255, 255, 255, 255).
-- So the only dark part is a ~6 px bevel ramp at the rim; from 8 px in it is a
-- solid opaque white quad. Drawn at any size it is a FILLED rectangle with a
-- darker border, which is exactly what the plate wants (a bordered dark panel),
-- and it is why the alarm below CANNOT be an outline region.
--
-- THE CONSEQUENCE, and it is the whole reason the alarm is built the way it is:
-- one region on this texture can never trace a hollow edge. A same-size ADD quad
-- over the strip is a full-area red wash across every rail, every number and every
-- mark at exactly the moment the player most needs to read them. The construction
-- that survives filled art is to make the alarm BIGGER than the plate and draw it
-- FIRST, so only the band protruding past the plate is ever visible. See RIM below.
local SQUARE     = F.TEX_SQUARE
local SQUARE_BOX = F.TEX_SQUARE_BORDER

-- 1.6 PIXELS PER PERCENT (v17; v14-v16 shipped 100 px, one pixel per percent).
-- LENGTH IS THE SIGNAL. A 0-100 gauge has 100 distinguishable states, so 100 px is
-- the shortest LOSSLESS rail — but "lossless" is not "legible", and 100 px of
-- travel under the character read as too short in play. 160 px is 60% more travel
-- for 60% more length, and it is not a round number for a reason: every value this
-- pack marks is a multiple of five (the 70 threat notch, the 25/50/75 ruler) and
-- 1.6 x 5 = 8, so EVERY mark still lands on a whole pixel. The invariant was never
-- the number 100; it is that markX() below is the only place a coordinate is
-- derived, which is what makes the length one constant. Proven mark by mark in the
-- canon at the bottom of this file.
--
-- HEIGHT IS WHAT THE EARLIER SIZE PASSES GOT WRONG. Scaling the strip uniformly
-- keeps the plate's shape and simply makes the same block bigger; it reads as a
-- panel. The bars therefore stay near their original thickness — 11 -> 13, threat
-- 4 -> 5 — and only the travel grows.
local RAIL_LEN      = 160  -- every rail, every pack
local RAIL_H        = 13   -- health and power: tall enough for a 12 pt number
local RAIL_THREAT_H = 5    -- threat is a warning, not a quantity you spend:
                           -- the thinnest lane, and the only one with no number
local PLATE_MARGIN_X = 2   -- plate overhang per rail end
local PLATE_W       = RAIL_LEN + 2 * PLATE_MARGIN_X  -- 164
local PLATE_H       = 36   -- warlock has NO discrete resource -> no lane 4 -> 36
                           -- (the four-lane variant of this profile is 45)
local PLATE_Y       = 3    -- local; keeps the plate's TOP edge on the shared line.
                           -- THIS PACK'S OWN CONVENTION — rogue centres its plate on
                           -- local 0, paladin on +6 — so every lane offset below is
                           -- DERIVED from it rather than copied from another pack.

-- THE ALARM RIM. Square_White_Border is FILLED (see the measurement above), so a
-- region on it cannot draw an outline — it can only be BIGGER than the thing that
-- covers it. The alarm is therefore the plate grown by RIM on every side and drawn
-- FIRST, at the bottom of the stack: the RIM-wide band that protrudes past the
-- plate is the only part that ever reaches the eye, and the rest sits behind a
-- 45%-black plate and behind every rail, number and mark. This construction is
-- correct whether the art turns out to be filled or hollow, which is why it is the
-- one to build. Same rim as the sibling rogue pack, so the strip reads identically.
local RIM              = 4                        -- per side
local ALARM_W, ALARM_H = PLATE_W + 2 * RIM, PLATE_H + 2 * RIM   -- 172 x 44

-- THE LANE STACK, DERIVED. The canonical stack is, top down with 1 px gaps,
-- threat 5 | health 13 | power 13 = 33 px of content (a four-lane pack adds a
-- resource lane of 8 and 42). The plate is 36, so the margins are (36 - 33) / 2 =
-- 1.5 px above and below — EVEN, which is what the profile asks for and what v14's
-- 1 / 2 split was not.
--
-- These offsets are COMPUTED from this pack's own plate convention (PLATE_Y = +3)
-- rather than copied from rogue, whose plate is centred on local 0 and whose lane
-- numbers would therefore sit 3 px low here. Content top = PLATE_Y + PLATE_H/2 -
-- MARGIN = 3 + 18 - 1.5 = +19.5, and each lane centre falls out of the stack:
--   threat +17   (+19.5 .. +14.5)
--   health  +7   (+13.5 ..  +0.5)   -- unmoved from v14, which is a coincidence
--   power   -7   ( -0.5 .. -13.5)   -- worth noticing rather than trusting
-- The arithmetic is asserted twice below: once against the plate (exact margins,
-- exact 1 px gaps) and once against independently typed literals in the contract.
local LANE_GAP    = 1
local CONTENT_H   = RAIL_THREAT_H + LANE_GAP + RAIL_H + LANE_GAP + RAIL_H   -- 33
local LANE_MARGIN = (PLATE_H - CONTENT_H) / 2                               -- 1.5
local CONTENT_TOP = PLATE_Y + PLATE_H / 2 - LANE_MARGIN                     -- +19.5
local LANE_THREAT = CONTENT_TOP - RAIL_THREAT_H / 2
local LANE_HEALTH = CONTENT_TOP - RAIL_THREAT_H - LANE_GAP - RAIL_H / 2
local LANE_POWER  = LANE_HEALTH - RAIL_H / 2 - LANE_GAP - RAIL_H / 2

-- THE BREAKPOINT FORMULA, and it is the ONLY place a coordinate is derived:
--     x(v) = (v / maxpower - 0.5) * RAIL_LEN
-- At RAIL_LEN 160 that is 1.6 px per percent, so the 70% threat notch is at
-- x = +32 and the quarter ruler at -40 / 0 / +40. Every value this pack marks is a
-- multiple of five and 1.6 x 5 = 8, which is why a non-round rail length still puts
-- every mark on a WHOLE PIXEL — the property that matters, not the number 100.
-- Compare the ring era, which needed r = size/2 * 0.94; x = r*sin(2*pi*f);
-- y = r*cos(2*pi*f) and landed the rogue pack's 35-energy mark on (23.575, -17.128).
-- NOTE (gotchas.md): a talent that raises the CAP — Vigor's energy 100 -> 110 —
-- moves every mark, because the constant is baked at build time. A warlock's mana
-- rail reads PERCENT, so it is immune; the notch below is a threat percentage and
-- is likewise capless.
-- rounded to 1/1000 px: (70/100 - 0.5) * 160 is 31.999999999999993 in IEEE754, and
-- a coordinate that is "32 to fifteen decimal places" is a coordinate that fails
-- every equality assertion written about it — and, worse, is not a whole pixel.
local function markX(v, maxv)
  local x = (v / (maxv or 100) - 0.5) * RAIL_LEN
  return math.floor(x * 1000 + 0.5) / 1000
end
local NOTCH_THREAT = markX(70)   -- +32: where this pack has always gone orange

-- The numbers live INSIDE their own rail, at its right-hand end, on the plate.
-- text_anchorPoint stays "CENTER" (the value this repo has proven on a
-- progresstexture) and the offset does the work. At 12 pt the widest string either
-- rail can print is "100%", 4 glyphs; at a generous 0.60 em advance that is 28.8 px,
-- so a number centred on +51 spans x +36.6..+65.4 and stays 14.6 px inside the
-- rail's +80 edge. INNER_RIGHT is proven on aurabars and icons only, so it is
-- deliberately not used here.
local PCT_SIZE = 12
local PCT_X    = 51
local PCT_Y    = 0

-- THE RULER. Three 2 px hairlines per 13 px rail at the QUARTER VALUES, 18% white.
-- The x positions are not typed: they come from markX, so the ruler follows the
-- rail length like every other mark. 6 px of ink on a 160 px rail (3.75%) — a hint,
-- never a segment of the fill.
local RULER_V   = { 25, 50, 75 }
local RULER_X   = {}
for i, v in ipairs(RULER_V) do RULER_X[i] = markX(v) end
local RULER_W   = 2
local RULER_COL = { 1, 1, 1, 0.18 }
-- The threat rail's single 70% mark. This pack has no dim/lit breakpoint PAIR (the
-- profile's 4 px / 8 px waterlines belong to a discrete-resource lane, e.g. the
-- rogue's 35 and 40 energy marks) — a warlock's mana rail reads percent and has no
-- spend threshold to draw. The notch stays 2 px, exactly as the rogue's does: it is
-- already a hairline against a 5 px lane, and widening it would make a warning
-- read as a value.
local NOTCH_W   = 2
local NOTCH_COL = { 1, 1, 1, 0.85 }

-- The threat NUMBER is switched off, not deleted: its sub-region index is
-- preserved (sub.N refs are positional) and a player can tick it back on in /wa.
-- threatpct is scaled so 100 = pulling aggro, which makes it an early-warning
-- ratio rather than a quantity you spend — a fill crossing the notch answers it
-- faster than reading a two-digit number and comparing it to a remembered 70.
local PCT_THREAT     = 9      -- pt (v17: 10 -> 9, the profile's threat size)
local PCT_THREAT_Y   = 58     -- LEFT WHERE IT IS, deliberately. The profile fixes the
                              -- threat number's SIZE and says it stays hidden where it
                              -- already is, so this dead ring-era offset is not touched;
                              -- it is inert while text_visible = false. (The rogue pack
                              -- zeroed its own in v58 so that ticking the number on in
                              -- /wa prints it on the rail; if this pack ever wants that
                              -- it is a one-line follow-up, not part of a geometry pass.)
local THREAT_TEXT_ON = false

-- THE ABSOLUTE-POSITION RULE, and the trap it exists to close.
-- SILL_Y is an ABSOLUTE screen offset, not a local one. The strip hangs two groups
-- deep — `top` at (0, TOP_Y) and `Warlock - Resources` at (0, RES_Y) — and
-- WeakAuras ADDS every offset down the parent chain. Typing -110 onto the sill
-- group would put it at -140 + 56 - 110 = -194, in the cooldown row. So the group
-- offset is DERIVED from its absolute target and can never drift out of sync:
--   PLAYER_GY = SILL_Y - TOP_Y - RES_Y = -110 + 140 - 56 = -26
-- Proven below by walking the DECODED parent chain.
--
-- (0, -110) IS THE ONLY GOOD y, and it is not a taste call. The band under the
-- character is bounded by two rows this repo already ships: paladin's and
-- hunter's buff rows at y -80..-40, and the other five packs' buff rows at
-- y -176..-136 — which in THIS pack is the DoT row at y -156, spanning -176..-136.
--
-- v17 KEEPS -110, AND THAT IS A MEASUREMENT, NOT INERTIA. The profile's strip is
-- only ~5 px taller than v14's: the 172 x 44 alarm rim sits at absolute (0, -107)
-- — the sill at -110 plus the plate's local +3 — and spans y -129..-85 against
-- v14's -125.5..-88.5. It still lies inside the free band with 5 px to its top
-- edge and 7 px to the DoT row below, so nothing has to be pushed out of the way.
-- Packs that were ENLARGED (paladin, rogue) had to move their buff rows first;
-- this one never was, so the only thing that moves in v17 is the PvP column, and
-- for a reason that has nothing to do with the strip (see the all-pairs scan).
-- The full rectangle scan is ASSERTED at the bottom of this file against the
-- decoded string, because "it looked fine with one alert up" is exactly how an
-- earlier pass shipped an overlap.
local SILL_X    = 0      -- ABSOLUTE screen x — dead centre, under the character
local SILL_Y    = -110   -- ABSOLUTE screen y
local TOP_Y     = -140   -- top-level group, unchanged since v1
local RES_Y     = 56     -- Resources group inside it, unchanged since v1
local PLAYER_GX = SILL_X - 0        -- the x chain above the strip is all zeroes
local PLAYER_GY = SILL_Y - TOP_Y - RES_Y

-- Canonical colours. health/mana/track/threat are the shared spec; the
-- escalation colours are v8's, unchanged, so nothing has to be relearned.
local GCOL = {
  health    = { 0.15, 0.82, 0.28, 1 },     -- the health rail
  mana      = { 0.20, 0.45, 0.95, 1 },     -- a warlock's power type IS mana, and
                                           -- the rail colour must always match
                                           -- what its trigger reads; the same
                                           -- constant table gives a rogue yellow
                                           -- energy and a warrior red rage.
  track     = { 0, 0, 0, 0.55 },           -- the unfilled part of every rail
  healthLow = { 0.95, 0.5, 0.15, 1 },      -- <=60%: the Life Tap health input
  manaLow   = { 0.75, 0.25, 0.95, 1 },     -- <30%: the Life Tap mana input
  threat    = { 0.25, 0.80, 0.30, 1 },
  threatHi  = { 1, 0.6, 0.1, 1 },          -- >=70%
  aggro     = { 0.9, 0.12, 0.12, 1 },      -- you pulled
  text      = { 1, 1, 1, 1 },              -- the health and power numbers
  thText    = { 1, 0.8, 0.55, 1 },         -- the (hidden) threat number, v8's colour
  plate     = { 0, 0, 0, 0.45 },           -- the instrument's dark ledge
  alarm     = { 1, 0.1, 0.1, 0.85 },       -- the >=80% frame, unchanged since v7
}

-- ===== top-level group, anchored below the character =====
local top = F.group(TOP, 0, TOP_Y, nil)

-- =====================================================================
-- Resources — v17: THE SILL, a 164 x 36 instrument strip under the character.
--
-- A ring encodes a value as ARC LENGTH around a hoop. A rail encodes it as a
-- LENGTH along a line, and at 160 px that length is 1.6 px per percent — long
-- enough that the TRAVEL is readable at a glance, and still exact, because every
-- value this pack marks is a multiple of five and 1.6 x 5 = 8. Same WeakAuras
-- region type as the rings, one different field:
--
--   orientation = "HORIZONTAL"
--
-- THE DROPDOWN LABEL IS WRONG AND THE IMPLEMENTATION IS THE AUTHORITY (v16 fixed
-- this after it shipped backwards). Types.lua's Private.orientation_with_circle_types
-- labels HORIZONTAL_INVERSE as L["Left to Right"], but BaseRegions/
-- LinearProgressTexture.lua's ApplyProgressToCoordFunctions is what actually places
-- the corners when a bar calls SetValue(0, progress):
--     HORIZONTAL          x = 0 .. progress      -> fill anchored LEFT,  grows RIGHT
--     HORIZONTAL_INVERSE  x = 1-progress .. 1    -> fill anchored RIGHT, grows LEFT
-- So the left-to-right rail this design wants is HORIZONTAL, full stop. Getting it
-- backwards gives a rail that empties from the left, which looks deliberate and is
-- wrong — and it also puts every breakpoint mark on the wrong side of the fill,
-- because markX() places them assuming a left-anchored bar.
--
-- Switching from the circular path back to the linear one swaps which fields are
-- LIVE, and it is the exact mirror of the v11 note that reversed it:
--   * startAngle / endAngle are IGNORED. They stay in the table because they are
--     in the region's default table, not because they do anything.
--   * compress / slanted / slant / slantFirst / slantMode are LIVE again. slant is
--     deliberately left off: a slanted fill line is a stylistic choice and a
--     straight waterline is what reads as a measurement.
--   * crop_x / crop_y 0.41 stops being the circular IDENTITY value (which cancels
--     the sqrt(2) expansion that path applies) and becomes a plain texcoord scale.
--     On a uniform white square it cannot alter the art at any aspect ratio, which
--     is why a 160 x 13 rail can use the same 0.41 a 100 x 100 ring used.
--   * auraRotation = 0 is absent from the 3.5.0 default table but read
--     unconditionally as data.auraRotation / 180 * math.pi, so it must be emitted.
--   * backgroundColor is the UNFILLED part of the rail and backgroundOffset = 0
--     keeps that track exactly the same rectangle as the fill rather than a fatter
--     halo around it.
--
-- LAYOUT (v17 — ONE strip, ABSOLUTE screen coordinates), local offsets in
-- brackets and identical in all seven packs:
--   sill group  (0, -110)   under the character, in the free band the whole repo
--                           leaves between the buff rows
--   listed in DRAW ORDER, which IS controlledChildren order:
--     Alarm rim     172 x 44  [0, +3]     the >=80% threat pulse, ADD, drawn FIRST;
--                                         4 px larger per side than the plate, so
--                                         only that band is ever visible
--     Sill Plate    164 x 36  [0, +3]     the dark ledge everything reads against
--     Threat rail   160 x  5  [0, +17]    your share of the pull threshold
--     Health rail   160 x 13  [0,  +7]    %percenthealth%% inside it at x +51
--     Power rail    160 x 13  [0,  -7]    %percentpower%%  inside it at x +51
-- The ring cluster that stood at (-270, 40) is GONE. Nothing it signalled is:
-- health, mana, threat, all three escalation colours, the out-of-combat fade, the
-- party/raid gate, the not-in-an-arena gate, every zero guard and the 80% pulse
-- all come across untouched. What is dropped is the 44 px live portrait — 1,936
-- px2 carrying no decision — and the threat NUMBER, which is switched off rather
-- than deleted (see THREAT_TEXT_ON above).
--
-- The health and power rails carry a real decision and neither is decoration:
-- Life Tap trades the health rail for the mana rail, so "can I tap?" is literally
-- "is the green one long and the blue one short" — and on two parallel rails
-- sharing an origin and a scale that is one comparison, where two arcs on
-- different radii were two.
--
-- THE PLATE EARNS ITS PIXELS, and it is the answer to the complaint v13 tried to
-- fix by moving a number: "the percentage can't be seen" is a CONTRAST problem,
-- not a coordinate one. A dark bordered rectangle behind a 13 px rail and a
-- 12 pt number is what makes them survive a snowfield, a fire and Shattrath at
-- noon, and it is what makes four separate regions read as ONE instrument rather
-- than four floating things. It inherits the portrait's uid, its Health trigger
-- and its out-of-combat fade, so the whole strip still appears, dims and vanishes
-- as one object.
--
-- THE TRAPS, all of them silent no-ops if you get them wrong:
--   * the colour property on a PROGRESSTEXTURE is `foregroundColor`; on a TEXTURE
--     it is `color` (setter "Color"). The aurabar's `barColor` is neither, and
--     Conditions.lua skips a change whose property is not in the region's property
--     table with no error and no editor warning. Both the plate and the alarm
--     frame are TEXTURE regions, so both carry an explicit `color` — the alarm
--     frame's is red at 85% and has been since v7; a frame that inherited
--     WeakAuras' default would pulse white.
--   * ONE PROGRESS TRIGGER PER RAIL. Modernize (<71) rewrites every
--     progresstexture's progressSource to {-1,""} = Automatic regardless of what
--     is emitted, and Automatic reads the FIRST ACTIVE trigger's value/total. So
--     trigger 1 always supplies the fill, and the second trigger on each region
--     (Unit Characteristics) exists only to feed the out-of-combat fade.
--   * ZERO-TOTAL INVERSION: an aurabar with total == 0 draws EMPTY, a
--     progresstexture with total == 0 draws FULL (AuraBar.lua `local progress = 0`
--     vs ProgressTexture.lua `local progress = 1`). Threat hits total == 0
--     whenever threatvalue is 0 — the instant before your first cast lands, and
--     after a Soulshatter — so an unguarded threat rail reads as a FULL bar of
--     aggro at the exact moment you have none. Every region below therefore
--     carries an explicit zero guard as its LAST condition (later conditions
--     overwrite earlier ones on the same property, so the guard must win).
--   * SUB-REGION INDEXES ARE POSITIONAL. The ruler hairlines and the threat notch
--     are APPENDED after each rail's existing percentage text, never inserted, so
--     every sub.N a condition could ever address keeps its meaning. The threat
--     text is turned off in place for the same reason.
--
-- UID DISCIPLINE, v14 — THE v9/v11 RE-TYPE TRICK, RUN ONE MORE TIME.
-- Not one W.uid() call is added, removed or reordered, and nothing is removed at
-- all. Every one of the six cluster auras is recycled where it stands:
--   "Warlock - Player Orb"       -> renamed "Warlock - Player Sill"  (the group)
--   "Warlock - Player Portrait"  -> renamed "Warlock - Sill Plate"   (model -> texture)
--   "Warlock - Threat"           -> the threat rail   (100x100 -> 100x4)
--   "Warlock - Player Health"    -> the health rail   ( 84x84  -> 100x11)
--   "Warlock - Player Mana"      -> the power rail    ( 62x62  -> 100x11)
--   "Warlock - Threat Flash"     -> the alarm rim     (ring -> 108x37 box)
-- uids are assigned where a region is CONSTRUCTED, and no constructor call
-- changed place: the three rails are built here in the health/mana/threat order
-- the rings were, the alarm rim immediately after them, and the group and the
-- plate at the very bottom of the file in that order, exactly as v7 built them.
-- DRAW ORDER IS NOT CONSTRUCTION ORDER. The alarm is built here and adopted FIRST
-- at the bottom of the file; adopt() only appends to controlledChildren and never
-- calls W.uid(), so re-ordering the strip's layers costs nothing in continuity.
-- Renaming, re-parenting, re-ordering, re-typing and resizing are all free —
-- WeakAuras matches auras across imports BY UID and applies the new id — so all 39
-- v13 child uids are byte-for-byte stable and W.assertUidContinuity runs with NO
-- allowance list.
-- The four `-- WA-REMOVED (v12):` tags above stay as lineage and are inert: the
-- verifier honours a tag only while the pack still ships that version.
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

-- THE THREAT TRIGGER'S UNIT ARG IS `threatUnit` ON IV-45 DATA (v12 correction).
-- F.threatTrigger emits use_threatUnit/threatUnit, which is the era-correct pair:
-- the Threat Situation prototype renamed that argument to `unit` at
-- internalVersion 51, and Modernize migrates < 51 data forward, so an IV-45 string
-- must emit the OLD name and let the migration rename it. v11 additionally set
-- `unit = "target"` — an IV-51+ field on IV-45 data, written on the belief that
-- threatUnit was dead. It is dropped; the factory's own trigger is used unchanged,
-- and it still reads the target with the same default it always had.
--
-- A RAIL. Every rail in the strip is RAIL_LEN (160 px) long, sits at x = 0 and
-- inherits its x from the sill group; only `h` and the lane `y` differ. `trigs` is
-- the trigger list; trigger 1 always supplies the fill (see the Automatic-progress
-- note above). No rail ever needs a scale factor, because markX() is the one place
-- that knows the length: every mark on every rail is `x = (v/100 - 0.5) * RAIL_LEN`.
local function rail(id, h, y, color, trigs)
  return orbStub{
    regionType = "progresstexture", id = id, uid = W.uid(), parent = nil,
    -- geometry
    width = RAIL_LEN, height = h,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = 0, yOffset = y, frameStrata = 1, alpha = 1,
    -- LINEAR fill, left to right. The name is inverted; see the section note.
    orientation = "HORIZONTAL",
    -- RADIAL-only and inert on this path; emitted because they are in the
    -- region's default table.
    startAngle = 0, endAngle = 360,
    inverse = false, mirror = false,
    -- LIVE on this path. slant stays off: a straight waterline is what reads as
    -- a measurement.
    compress = false, slanted = false, slant = 0, slantFirst = false, slantMode = "INSIDE",
    -- textures
    foregroundTexture = SQUARE, backgroundTexture = SQUARE, sameTexture = true,
    desaturateForeground = false, desaturateBackground = false,
    foregroundColor = color, backgroundColor = GCOL.track,
    backgroundOffset = 0,
    blendMode = "BLEND", textureWrapMode = "CLAMPTOBLACKADDITIVE",
    -- a plain texcoord scale on this path, and a no-op on a uniform white square.
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

-- THE SILL PLATE and THE ALARM RIM are two CONCENTRIC Square_White_Border boxes at
-- the same local offset: the plate 164 x 36 in near black at 45%, the alarm
-- 172 x 44 — RIM px larger on every side — in red at 85% with ADD blending. The
-- alarm is drawn FIRST and the plate second, so the stack reads
--     alarm rim -> plate -> threat -> health -> power
-- and the only part of the alarm that is ever visible is the 4 px band sticking out
-- past the plate. That is the whole trick, and it is forced by the art: the texture
-- is FILLED (98.44% of its pixels are alpha 255; see SQUARE_BOX above), so a
-- same-size ADD quad on top would be a full-area red wash over both rails, both
-- numbers, the notch and the ruler.
-- F.texture supplies the complete texture field set (`color`, `blendMode`,
-- `texture`, `textureWrapMode`, rotation and mirror flags) and consumes exactly
-- one W.uid() whatever size it is handed, which is what lets the portrait's slot
-- become the plate's and the ring halo's slot become the rim's.
local function box(id, color, w, h)
  return F.texture(id, CLASS, w or PLATE_W, h or PLATE_H, 0, PLATE_Y, nil, SQUARE_BOX, color)
end

-- The number lives INSIDE its own rail, at the right-hand end: text_anchorPoint
-- "CENTER" (proven on a progresstexture by every ring this pack has shipped) plus
-- an anchorXOffset, because INNER_RIGHT is only proven on aurabars and icons.
-- `sym` is the stored trigger variable, which is also what makes the text a
-- rounded integer rather than 63.428571%.
local function pct(sym, size, x, y, color)
  local st = F.subtext("%" .. sym .. "%%", size, "CENTER", sym)
  F.subtextOffset(st, x, y)
  st.text_color = color
  return st
end

-- A WATERLINE: a full-height hairline across a rail at a fixed percentage.
--   xOffset / yOffset are NOT in the subtexture default() table but ARE read by
--   modify -> AnchorSubRegion in "point" mode; omit them and every mark stacks at
--   the centre. textureRotate is the gate for textureRotation and both stay off,
--   because Square_White is a solid square with no orientation.
-- Appended after the rail's existing text, never inserted: sub.N condition refs
-- are positional.
local function waterline(x, w, h, color)
  return {
    type = "subtexture",
    textureVisible = true,
    textureTexture = SQUARE,
    textureDesaturate = false,
    textureColor = color,
    textureBlendMode = "BLEND",
    textureMirror = false,
    textureRotate = false,
    textureRotation = 0,
    anchor_mode = "point", anchor_point = "CENTER", self_point = "CENTER",
    width = w, height = h, scale = 1, mirror = false, rotate = false,
    xOffset = x, yOffset = 0,
  }
end

-- The quarter ruler: three 2 px hairlines at the 25 / 50 / 75 values, which markX
-- puts at x -40 / 0 / +40 on a 160 px rail — whole pixels, because 1.6 x 5 = 8.
local function addRuler(region, h)
  for _, x in ipairs(RULER_X) do
    region.subRegions[#region.subRegions + 1] = waterline(x, RULER_W, h, RULER_COL)
  end
end

local gRes = reg(F.group("Warlock - Resources", 0, RES_Y, nil))
adopt(top, gRes)

-- --- LANE 2: the HEALTH rail (was the health ring, same id and uid) ------
-- The health rail is the middle of the three and the widest band, because health
-- is what you read under pressure. Amber at or below 60% is the Life Tap prompt's
-- health input, so both halves of the "can I tap?" decision are one comparison
-- between two parallel rails that share an origin and a scale.
-- maxhealth <= 0 is the health equivalent of the threat guard: the Health
-- prototype's total is UnitHealthMax(unit) with no floor, so a unit whose max
-- health has not streamed yet would otherwise show a FULL rail (see the
-- zero-total inversion note above).
local pHealth = reg(rail("Warlock - Player Health", RAIL_H, LANE_HEALTH, GCOL.health,
  { F.healthTrigger(), F.unitCharTrigger() }))
pHealth.subRegions[1] = pct("percenthealth", PCT_SIZE, PCT_X, PCT_Y, GCOL.text)
addRuler(pHealth, RAIL_H)                        -- sub.2-4, appended
pHealth.conditions = {
  F.condition(1, "percenthealth", "<=", "60", "foregroundColor", GCOL.healthLow),
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

-- --- LANE 3: the POWER rail (was the mana ring, same id and uid) ---------
-- Violet under 30%: the visual pair of the Life Tap prompt. The rail is blue
-- because a warlock's power type IS mana — powertype = 0 is what the trigger
-- reads, and the colour must always match what the trigger reads. maxpower's
-- guard is written <= 1, not <= 0, because the Power prototype floors total at
-- math.max(1, UnitPowerMax(...)) — a powerless unit reports exactly 1.
-- The number stays `%percentpower%%` rather than the rogue's raw `%p`: a
-- warlock's mana pool is thousands deep, so the percentage is the reading that
-- means anything, and it is the one the rail's own 100 px scale agrees with.
local pMana = reg(rail("Warlock - Player Mana", RAIL_H, LANE_POWER, GCOL.mana,
  { F.powerTrigger(0), F.unitCharTrigger() }))
pMana.subRegions[1] = pct("percentpower", PCT_SIZE, PCT_X, PCT_Y, GCOL.text)
addRuler(pMana, RAIL_H)                          -- sub.2-4, appended
pMana.conditions = {
  F.condition(1, "percentpower", "<", "30", "foregroundColor", GCOL.manaLow),
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxpower", "<=", "1", "alpha", 0),
}

-- v5: "everywhere except an arena", for the threat ring and its flash halo.
-- An arena has no threat table, so both are pure clutter there — but there is
-- genuinely no "not arena" load key: the `size` load arg declares no `inverse`
-- and no `test`, so multi mode is a plain OR over raw string equality and the
-- complement has to be spelled out. The value that mattered is `none`: in the
-- open world the client reports the literal STRING "none" (GetInstanceTypeAndSize
-- returns early with "none" when you are not in an instance), not nil, so listing
-- it keeps the ring loading in Hellfire exactly as before. use_size = false is
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

-- --- LANE 1: the THREAT rail (v12's outermost ring, same id and uid) -----
-- Threat is YOUR threat, so it sits on YOUR instrument: 5 px tall at the top of
-- the strip, green -> orange at 70% -> red on aggro, most severe last, exactly as
-- the bar, the rim and the ring before it escalated. 5 px because threat is a
-- WARNING, not a quantity you spend — it is the thinnest lane and the only one
-- with no number: you never need to read it to a percent, you need to know whether
-- the fill has reached the notch.
-- THE NOTCH IS THE READOUT (v14). sub.2 is a 2 px waterline at markX(70) = +32:
-- when the fill touches it you are at 70 and it is time to stop or dump. That is
-- what replaces the number, which is switched off but kept at sub.1 so its index
-- — and any condition that might ever address it — still means what it meant.
-- THE PROPERTY IS `foregroundColor`. v9/v10 made threat a `texture`, whose colour
-- setter is `color`; since v11 it is a `progresstexture`, whose colour setter is
-- `foregroundColor` (and the aurabar's `barColor` is neither). Conditions.lua
-- silently skips a change whose property is not in the region's property table,
-- so a mechanically copied `color`/`barColor` would leave the escalation dead
-- with no warning anywhere.
-- Party/raid only and never in an arena, both carried over unchanged: solo you
-- are the tank on your own target, so an ungated rail sits permanently red, and
-- an arena has no threat table at all. Both gates plus the zero guard below are
-- why the solo strip is a plate and two rails — the threat lane appears only when
-- threat is real.
-- THE GUARD IS MANDATORY, not defensive coding — see the zero-total note at the
-- top of this section. threatvalue is a stored conditionType "number" arg; the
-- prototype's hidden `total` is not, which is why the guard is written against
-- the value rather than the total.
local threat = reg(rail("Warlock - Threat", RAIL_THREAT_H, LANE_THREAT, GCOL.threat,
  { F.threatTrigger(), F.unitCharTrigger() }))
threat.subRegions[1] = pct("threatpct", PCT_THREAT, 0, PCT_THREAT_Y, GCOL.thText)
threat.subRegions[1].text_visible = THREAT_TEXT_ON   -- switched off, NOT deleted
-- sub.2, appended: the 70% notch, the one mark on this rail.
threat.subRegions[2] = waterline(NOTCH_THREAT, NOTCH_W, RAIL_THREAT_H, NOTCH_COL)
threat.load.use_ingroup = true
threat.load.ingroup = { multi = { group = true, raid = true } }
threat.load.use_size = false
threat.load.size = notArenaSize()
threat.conditions = {
  F.condition(1, "threatpct", ">=", "70", "foregroundColor", GCOL.threatHi),
  F.condition(1, "aggro", "==", 1, "foregroundColor", GCOL.aggro),
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "threatvalue", "<=", "0", "alpha", 0),
}

-- --- 80%+ ALARM RIM ("Warlock - Threat Flash", same id and uid) --------
-- The v6 overlay was a 176x18 red rectangle pulsing across the threat bar; v7/v8
-- made it a ring outside the threat arc, v9/v10 a halo outside the globe's rim and
-- v12 a halo ON the threat ring. v14 makes it the STRIP'S OWN EDGE: a 172x44
-- Square_White_Border box concentric with the 164x36 plate, drawn FIRST, so a 4 px
-- red band pulses around the whole instrument. Same trigger, same 80% threshold,
-- same load gates, same alphaPulse, same colour it has carried since v7 — only the
-- shape and the draw index changed.
--
-- WHY IT IS OVERSIZED AND UNDERNEATH, and it is not a style choice. Square_White_
-- Border.tga is a FILLED square with a dark bevel baked into its edge: 64,516 of
-- its 65,536 pixels are alpha 255 (98.44%), and every pixel 8 px or more in from
-- the edge has alpha 255 with no RGB channel below 167 (n = 57,600). A single
-- region on that file therefore CANNOT trace a hollow edge. Ship this quad at the
-- plate's size on top of the stack and >=80% threat paints a full-area ADD red wash
-- across both rails, both numbers, the 70 notch and the quarter ruler — washing out
-- the readouts at exactly the moment they have to be read. Ship it 4 px larger on
-- every side and FIRST, and only the protruding band draws: inside the plate's
-- footprint the alarm sits behind a 45%-black plate and behind every readout, so
-- nothing is composited over a number and every colour code survives. The size and
-- the draw index are two halves of one mechanism — drop either and the rim
-- silently becomes a wash again — so both are pinned by assertion below.
-- The colour is passed EXPLICITLY (`color` is the texture region's setter). This
-- pack has always shipped {1, 0.1, 0.1, 0.85} here — verified by decoding the v13
-- string, not assumed — and an inherited default would pulse the rim white.
-- ADD blend so the band reads as light rather than paint.
local flash = reg(box("Warlock - Threat Flash", GCOL.alarm, ALARM_W, ALARM_H))
flash.blendMode = "ADD"
flash.triggers = F.triggers({ F.threatTrigger(80) })
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

-- The PvP column: the second flanking stack, on the other side of the character
-- from Alerts, so the PvE layout is untouched. Must be a dynamic group — three of
-- its children are clone sources (one row per opponent).
--
-- v17 MOVES IT, x +150 -> +190, AND THE REASON IS NOT THE STRIP. Every scan this
-- pack shipped before v17 tested things against the SILL, which structurally
-- cannot see two flanking stacks overlapping EACH OTHER. The all-pairs scan added
-- at the bottom of this file does, and it says this column was already covering
-- two of its neighbours at +150:
--   * the column's box is NOT icon-width. "Warlock - Enemy Mana" is a 120 px
--     aurabar, and a DOWN-growing group with selfPoint TOP centres its children
--     horizontally, so the column occupies x +-60 around its anchor at any depth
--     its stack reaches — 90..210 at +150.
--   * the cooldown row grows HORIZONTAL from x 0 and reaches x -106..106 at six
--     32 px icons: 16 px of overlap, in the y band the PvP column passes through.
--     A Destruction lock in an arena genuinely has Conflagrate, Shadowburn,
--     Shadowfury, Death Coil and Howl of Terror down at once, and Enemy Mana alone
--     clones once per opponent, so neither stack being six deep is hypothetical.
--   * "Warlock - Siphon Life", the right-hand DoT icon, spans x 68..108: 18 px of
--     overlap.
-- The measured minimum anchor is +168 — the DoT row's right edge at 108 plus half
-- the 120 px bar — and the cooldown row wants +166, so the DoT row is the binder by
-- 2 px. +190 leaves 22 px to the DoT row, 24 px to the cooldown row and 44 px to
-- the new 172 px alarm rim. The column is therefore NOT the mirror of Alerts at
-- -150 any more, and it cannot be: its widest child is 2.7x the widest alert icon.
-- All of that is re-derived from the decoded string in block 11b, so this comment
-- cannot drift away from what shipped.
local PVP_GX = 190
local gPvp = reg(F.dynGroup("Warlock - PvP", PVP_GX, 96, nil, "DOWN", "TOP", 6))
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
-- v7's bottom-of-file auras, still built at the VERY BOTTOM, after every
-- v1/v2/v4/v5 uid() call, so all 38 older uids keep their position in the seeded
-- stream. v7-v11 kept all six of them and only changed WHAT each one was. v12 was
-- the first version to REMOVE any aura, and it removed exactly the tail:
--
--   1  "Warlock - Player Orb"        KEPT     (the group; renamed in v14)
--   2  "Warlock - Player Portrait"   KEPT     (the plate since v14)
--   3  "Warlock - Target Orb"        REMOVED  (the target cluster's group)
--   4  "Warlock - Target Health"     REMOVED  (duplicated the target frame)
--   5  "Warlock - Target Ring Track" REMOVED  (existed only to balance the pair)
--   6  "Warlock - Target Portrait"   REMOVED  (duplicated the target frame)
--
-- REMOVING THE TAIL IS WHY EVERY SURVIVING UID IS STABLE. Slots 3-6 were the last
-- four W.uid() calls in the whole script; nothing is built after them, so deleting
-- them shifted nothing and the 40 remaining uids are byte-for-byte v11's. v14
-- removes nothing at all and adds nothing: the two calls below are the same two
-- calls, in the same order, building a group and a texture instead of a group and
-- a model.
--
-- THE GROUP IS RENAMED AND THE PORTRAIT IS RE-TYPED, and both are free. WeakAuras
-- matches auras across imports BY UID and then applies the new id, so a rename is
-- invisible to the Update flow; and a region's type is just a field, which is how
-- v9 turned two portraits into globe rims and v11 turned them back. What is NOT
-- free is moving a W.uid() CALL, and neither of these does.
--
-- The sill group is a static F.group(), not a dynamic one: a dynamic group ignores
-- child x/y offsets, and the whole strip is nothing but children at fixed lane
-- offsets from one anchor.
--
-- SIBLING ORDER IS DRAW ORDER, exactly: FixGroupChildrenOrder walks
-- controlledChildren and adds +4 frame levels per child, so EARLIER = further
-- BEHIND. The strip is layered like a real instrument:
--   v13  { Portrait,     Threat, Health, Mana, Threat Flash }  face back, halo top
--   v14  { Threat Flash, Sill Plate, Threat, Health, Mana }    rim back, readouts top
-- THE ORDER CHANGED, and the change is the point. v13's flash was a RING HALO —
-- an annulus with a hole in it, so drawing it last put a red ring around readouts
-- it could not cover. v14's alarm is drawn from Square_White_Border.tga, which is
-- FILLED (64,516 of 65,536 pixels at alpha 255; nothing 8 px in from the edge is
-- below alpha 255 or RGB 167), so the same last-place slot would put a full-area
-- ADD red quad over every rail, number and mark. Moving it to child #1 and growing
-- it 3 px per side inverts that: the alarm is the BOTTOM of the stack and only its
-- protruding rim is visible.
--
-- Both boxes are filled, so both need their layer stated. The plate is a FILLED
-- 102x31 rectangle at 45% black — not opaque, but enough to grey out every rail
-- and both numbers if it were ever drawn over them — so it is child #2, directly
-- on top of the rim and directly under the rails. sharedFrameLevel is deliberately
-- left off the group — it would set the offset to 0 and make the overlap ambiguous.
--
-- Both facts are asserted from the DECODED string below, together with the flat
-- c-list agreeing with controlledChildren depth-first, because for v = 2000 the
-- two have to say the same thing.
-- =====================================================================

-- --- the strip: a plate, three rails and a frame, at ABSOLUTE (0, -110) -----
-- One group, because it is one instrument: Life Tap trades the health rail for the
-- mana rail, and threat says whether you can afford to keep casting at all.
-- Dragging this group moves everything. The group carries the DERIVED PLAYER_GX /
-- PLAYER_GY and every child carries only its LANE offset, which is what makes the
-- lane stack exact BY CONSTRUCTION.
local gPlayer = reg(F.group("Warlock - Player Sill", PLAYER_GX, PLAYER_GY, nil))

-- THE SILL PLATE — this is the v7 portrait's uid, re-typed model -> texture. It
-- keeps the portrait's Health trigger and its out-of-combat fade, so the whole
-- strip still appears, dims to 50% and vanishes as one object. It is the darkest,
-- most stable backdrop the HUD has, which is the actual answer to "the percentage
-- can't be seen": the numbers were never big enough to lose, they were painted on
-- the game world.
--
-- ONE FIELD CHANGES THAT IS NOT GEOMETRY OR COLOUR, and it is declared here rather
-- than left for someone to find in a diff: frameStrata goes 2 -> 1. v13 set the
-- portrait to 2 (BACKGROUND, the LOWEST strata) so the face sat behind its rings;
-- F.texture emits 1 (Inherited), the same strata the rails use, and v14 keeps it.
-- The plate is still the rearmost layer because it is child #1 and frame level,
-- not strata, decides inside a group — asserted from the decoded string below.
local pPlate = reg(box("Warlock - Sill Plate", GCOL.plate))
pPlate.triggers = F.triggers({ F.healthTrigger(), F.unitCharTrigger() })
pPlate.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

-- --- wiring (v14 draw order; no uid moves — uids are assigned at CONSTRUCTION,
--     above, and not one constructor call changed place) -------------------
adopt(gRes, gPlayer)
adopt(gPlayer, flash)       -- the 80% alarm rim FIRST, at the very bottom: 3 px
                            -- larger per side, so only the protruding band shows
                            -- and the rest hides behind the plate and the readouts
adopt(gPlayer, pPlate)      -- the ledge second: it is a filled rectangle, so
                            -- anywhere later it greys out the rails
adopt(gPlayer, threat)      -- ...then the 4 px threat lane at the top...
adopt(gPlayer, pHealth)     -- ...then health...
adopt(gPlayer, pMana)       -- ...then power, on top of everything

-- ===== assemble (v2000 nested), encode, verify =====
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

-- =====================================================================
-- v17 PROOF, run against the DECODED string rather than the tables above, so
-- what is asserted is what a player actually imports. This block is the RAIL
-- CANON — the direct replacement for v11-v13's ring canon (orientation ==
-- "CLOCKWISE", width == height == <diameter>, foregroundTexture == RING_TEX,
-- exact sub-region counts). It has been REWRITTEN TO THE v17 PROFILE, never
-- deleted: these assertions are the reason a geometry change in this repo has
-- never silently shipped wrong, and every one of them would have caught a real
-- mistake made while writing v14.
--
-- v17 ADDS THREE PROOFS AND RE-AIMS THE REST:
--   * 5b. EVERY MARK LANDS ON A WHOLE PIXEL. The rail is no longer a round 100, so
--     "the formula is applied consistently" is no longer enough — the question is
--     whether 1.6 px per percent still puts a mark on a pixel boundary. It does,
--     for every value this pack marks, because they are all multiples of five and
--     1.6 x 5 = 8; that is asserted value by value rather than asserted once.
--   * 11b. THE ALL-PAIRS COLUMN SCAN. Block 11 tests everything against the SILL,
--     which structurally cannot see two flanking stacks overlapping EACH OTHER.
--     That gap hid a real defect in the sibling rogue pack (a 140 px kick-lockout
--     bar sitting on top of a weapon-proc icon) and it was hiding two here.
--   * 2b. THE LANE STACK IS DERIVED FROM THE PLATE, and the derivation is checked
--     against independently typed literals, so a plate convention (+3 here, 0 in
--     rogue, +6 in paladin) cannot be silently copied between packs.
--
--  0. THE CONTRACT. Every number the design fixes, written once more as a bare
--     LITERAL, with the build constants and the decoded string both checked
--     against it. An assertion phrased in the symbol that produced the value it
--     checks pins the WIRING and no VALUE — see the v14 lineage note above for
--     the four geometry mutations that used to ship silently.
--  1. ABSOLUTE POSITIONS. WeakAuras adds xOffset/yOffset all the way down the
--     parent chain, and the strip hangs three groups deep (top -> Resources ->
--     sill -> region). A locally correct number is therefore not evidence of
--     anything; only the walked sum is — against the CONTRACT's (0, -110), not
--     against the constant that built it. The group must additionally carry the
--     DERIVED local -26, which is what catches an absolute coordinate typed onto
--     a group by hand.
--  2. THE LANE STACK, EXACTLY. Every rail on x = 0 at its own lane y; no two
--     lanes overlapping EACH OTHER (containment inside the plate does not imply
--     it, and a 1.5 px retune of one lane is enough to break it); the gaps
--     exactly 1 px; and the plate's margins exactly 1.5 px above and below —
--     EVEN, which is the profile's rule and which v14's 1 / 2 split was not.
--     Asserted from decoded widths and heights, so "164 x 36" is a measurement
--     rather than a comment.
--  3. RAIL CANON. progresstexture on the LINEAR path (HORIZONTAL, which is the
--     value that anchors the fill LEFT — the dropdown's label for it is wrong),
--     160 px long at 1.6 px per percent, and explicitly NOT square, because square
--     is what every progresstexture in this repo was until v14 and a copied ring is
--     the easiest way to regress. Square_White on both fill and track,
--     backgroundOffset 0, crop 0.41, auraRotation emitted, Automatic progress.
--  4. NO RING SURVIVES ANYWHERE IN THE PACK. Not one region may still be on the
--     circular path or still be drawn with Ring_20px. A half-converted strip
--     would import, round-trip and verify perfectly, and would simply look wrong.
--  4b. THE SILENT-NO-OP CENSUS, WHOLE PACK AND EVERY REGION TYPE. The three
--     colour setters are not interchangeable — progresstexture wants
--     `foregroundColor`, texture/icon/model want `color`, aurabar wants
--     `barColor` — and Conditions.lua skips a change whose property is not in the
--     region's table with no error and nothing visible. Checking only the threat
--     rail (which is all v14's first cut did) left health and mana free to ship a
--     dead escalation, so this walks EVERY condition on EVERY aura and also
--     requires each rail to actually have the escalation the design gives it.
--  5. SUB-REGION SHAPE, exactly, because sub.N condition refs are POSITIONAL:
--     the percentage stays sub.1 on all three rails and every mark is APPENDED
--     after it — the threat notch at sub.2, each ruler at sub.2-4.
--  5b. EVERY MARK ON A WHOLE PIXEL, value by value: the 70 notch at +32 and the
--     25/50/75 ruler at -40 / 0 / +40, each one an integer and each one equal to
--     markX(value) recomputed here. This is what makes 160 a legitimate rail
--     length rather than a round-looking one.
--  6. THE NUMBERS ARE WHERE THEY ARE CLAIMED TO BE: 12 pt, CENTER-anchored, at
--     anchorXOffset +51 inside their own rail (BOTH spellings, equal — only the
--     text_ one renders), with the OUTLINE font type and the shadow that make them
--     survive the game world behind them, and with the widest string they can print
--     proven to stay inside the rail.
--  7. THE THREAT NUMBER IS SWITCHED OFF, NOT DELETED. text_visible == false with
--     the sub-region still at index 1 — the difference between "one checkbox away
--     in /wa" and "gone", and the difference between a stable sub.N map and a
--     silently retargeted condition.
--  8. THREAT SURVIVED THE MOVE INTACT: the era-correct threatUnit arg and NOT the
--     IV-51+ `unit`, the party/raid gate, the not-in-an-arena gate, all three
--     escalation steps on `foregroundColor`, and the zero guard LAST.
--  8b. AND SO DID HEALTH AND POWER: each keeps its own escalation step on
--     `foregroundColor` and its own mandatory zero guard as its LAST condition
--     (maxhealth <= 0, maxpower <= 1 — the Power prototype floors total at 1).
--     A progresstexture with total == 0 draws FULL, so a missing guard is a rail
--     that reports 100% at the moment it knows nothing.
--  9. THE PLATE AND THE ALARM RIM are two CONCENTRIC boxes on one filled file,
--     with EXPLICIT colours: `color` is the texture region's setter, and an alarm
--     that inherited WeakAuras' default would pulse white instead of red. Both are
--     pinned to the rails' frameStrata as well, because the plate's strata is the
--     one non-geometry field besides `color` that v14 changes (BACKGROUND ->
--     Inherited) and an undeclared strata is how layering breaks silently.
--     THE RIM IS PINNED AS A SIZE AND A DRAW INDEX TOGETHER: alarm.width ==
--     plate.width + 8, alarm.height == plate.height + 8, same centre, cc[1] ==
--     alarm and cc[2] == plate. Square_White_Border.tga is FILLED (64,516 of
--     65,536 pixels at alpha 255; nothing 8 px in from the edge below alpha 255 or
--     RGB 167), so a same-size or top-of-stack alarm is a full-area red wash over
--     every readout. Drop either half of the pin and the rim silently becomes that
--     wash — which is exactly the bug this construction repairs.
-- 10. DRAW ORDER: the alarm rim FIRST (a filled ADD quad anywhere else washes
--     everything under it), the plate SECOND (at 45% alpha it is not opaque, but it
--     is the surface the rails are painted on, and it is what hides all of the
--     alarm except its 4 px band), all three rails ABOVE both, and the flat c-list
--     depth-first in the same order, because for v = 2000 the two must agree.
-- 11. THE RECTANGLE SCAN. The strip's ALARM ENVELOPE against EVERY other element in
--     the pack, with dynamic groups projected six children deep — the alert
--     column, the PvP column and the cooldown row all grow, so a check made with
--     one prompt showing proves nothing about a real pull, which is exactly how an
--     earlier pass shipped an overlap. Zero overlaps, and the two clearances that
--     define the free band are printed rather than assumed. It also asserts the
--     strip lies INSIDE the free band (y -136 .. -80) — an INDEPENDENT check on
--     the absolute y, because a pack-local overlap scan says nothing about the
--     fleet: -21 collides with nothing in THIS pack and is still wrong, since it
--     is the character's waist and leaves 0.5 px to two other packs' buff rows.
-- 11b. THE ALL-PAIRS STACK SCAN, which block 11 cannot do. Block 11 asks "does
--     anything touch the strip"; this asks "does any stack touch any other stack",
--     over all five layout stacks (the sill, the DoT row, Alerts, Cooldowns, PvP),
--     with dynamic groups projected six deep and static rows boxed as the union of
--     their children. It is the check that catches a column whose widest child is
--     a 120 px bar rather than a 32 px icon — which is what the PvP column is, and
--     why v17 moves it. Every pairwise clearance is printed, not just the failures.
-- 12. THE REMOVALS ARE STILL THE DECLARED ONES: the four v12 target-cluster ids
--     are absent, and v17 removes nothing further.
-- =====================================================================
local back = W.decode(encoded)
local nodes = { [back.d.id] = back.d }
for _, ch in ipairs(back.c) do nodes[ch.id] = ch end

local function absPos(id)
  local n = assert(nodes[id], "no such aura: " .. id)
  local x, y, guard = 0, 0, 0
  while n do
    x, y = x + (n.xOffset or 0), y + (n.yOffset or 0)
    guard = guard + 1
    assert(guard < 32, "parent chain loop at " .. id)
    n = n.parent and nodes[n.parent] or nil
  end
  return x, y
end

local function assertAt(id, ax, ay)
  local x, y = absPos(id)
  assert(x == ax and y == ay,
    ("%s sits at (%s, %s), expected (%s, %s)"):format(id, tostring(x), tostring(y),
      tostring(ax), tostring(ay)))
end

-- 0. THE CONTRACT — the design's numbers, written ONCE MORE as bare LITERALS.
--
-- WHY THIS BLOCK EXISTS, and it is the repair of a real hole rather than belt and
-- braces. An assertion phrased in the same symbol that produced the value it
-- checks can never fail:
--     assert(PLAYER_GY == SILL_Y - TOP_Y - RES_Y)  -- PLAYER_GY IS that expression
--     assertAt(id, SILL_X, SILL_Y + s.y)           -- SILL_Y proving SILL_Y
-- Those forms do pin the WIRING — that the group offset is DERIVED and that each
-- lane offset is written once — and they are kept below for exactly that. What
-- they pin is no VALUE at all. Mutation-tested against the first cut of this
-- block, one constant changed per rebuild: SILL_Y -110 -> -21, PLATE_H 31 -> 37,
-- LANE_THREAT 15.5 -> 14 and RULER_W 1 -> 3 each printed "OK: 40 auras" and would
-- have shipped the wrong instrument inside a perfectly valid string.
--
-- So every number the design fixes is typed here a second time, as a literal, at
-- a site whose only job is to say what the number is and why. Three things are
-- then checked against it: the arithmetic between the literals, the build
-- constants above, and the DECODED string. Retuning still works — it just has to
-- be done in two places, deliberately, with the reason in front of you, which is
-- the whole difference between a design change and a typo.
--
-- Where the design admits an INDEPENDENT derivation it is asserted as well, and
-- those catch even the two-place edit: the free band the absolute y must lie in
-- (block 11), the exact gaps between lanes and the exact plate margins (block 2),
-- the whole-pixel test on every mark (block 5b), the all-pairs stack scan (block
-- 11b) and the ruler's ink budget (block 5). Those come from the geometry itself,
-- not from a number typed anywhere.
local C = {
  -- ABSOLUTE PLACEMENT. -110 is under the character, inside the band this repo
  -- leaves free in every pack: paladin's and hunter's buff rows sit at y -80..-40
  -- and the other five packs' at y -176..-136 (in THIS pack that is the DoT row
  -- at y -156, spanning -176..-136). v17 does not move it: the profile's strip is
  -- ~5 px taller than v14's and still fits, which block 11 measures.
  absX = 0, absY = -110,
  bandTop = -80, bandBottom = -136,      -- the free band, from those two rows
  -- THE PARENT CHAIN, each link typed once and independently. The sill group
  -- carries the DERIVED local offset; the absolute is what the player sees.
  topY = -140, resY = 56, sillGY = -26,
  -- THE PLATE AND THE LANE STACK, local to the sill group. plateY +3 is THIS
  -- pack's convention (rogue centres on 0, paladin on +6) and every lane below is
  -- derived from it, so it is a contract term in its own right.
  plateW = 164, plateH = 36, plateY = 3, plateMarginX = 2,
  -- THE ALARM RIM, typed as its own literals so the +8 relation below is checked
  -- against two independently written numbers rather than against itself. 4 px per
  -- side is the only thing that ever draws: Square_White_Border.tga is filled
  -- (98.44% of its pixels are alpha 255), so the alarm can only read as an edge by
  -- being larger than the plate AND drawn under it.
  rim = 4, alarmW = 172, alarmH = 44,
  -- EVEN margins, which is the v17 profile's rule and what v14's 1 / 2 was not.
  marginAbove = 1.5, marginBelow = 1.5, laneGap = 1,
  laneThreat = 17, laneHealth = 7, lanePower = -7,
  -- THE RAILS. 160 px = 1.6 px per percent; see block 5b for why that is exact.
  railLen = 160, railH = 13, railThreatH = 5, pxPerPct = 1.6,
  -- THE NUMBERS AND THE MARKS.
  pctSize = 12, pctX = 51, pctY = 0, pctThreatSize = 9, pctThreatY = 58,
  rulerV = { 25, 50, 75 }, rulerX = { -40, 0, 40 }, rulerW = 2, rulerAlpha = 0.18,
  notchV = 70, notchX = 32, notchW = 2,
  -- THE FLANKING STACKS, as ABSOLUTE x. Alerts has not moved since v4; PvP moves
  -- in v17 because the all-pairs scan (block 11b) says +150 overlapped both the
  -- cooldown row and the DoT row. See the note at the gPvp constructor.
  alertsX = -150, pvpX = 190, pvpMinX = 168,
}

-- the arithmetic OF the contract, on terms that were each typed separately: if
-- any one of them is edited alone, the chain stops adding up.
assert(C.absY == C.sillGY + C.topY + C.resY,
  ("the parent chain does not reach the absolute target: %g + %g + %g = %g, not %g")
    :format(C.sillGY, C.topY, C.resY, C.sillGY + C.topY + C.resY, C.absY))
assert(C.plateH == C.railThreatH + C.laneGap + C.railH + C.laneGap + C.railH
  + C.marginAbove + C.marginBelow,
  ("the lane stack does not fill the plate: %g + %g + %g + %g + %g margins = %g, "
    .. "but the plate is %g tall"):format(C.railThreatH, C.laneGap, C.railH, C.laneGap,
    C.railH, C.railThreatH + 2 * C.laneGap + 2 * C.railH + C.marginAbove + C.marginBelow,
    C.plateH))
assert(C.marginAbove == C.marginBelow,
  ("the profile wants EVEN margins; the contract says %g above and %g below")
    :format(C.marginAbove, C.marginBelow))
assert(C.plateW == C.railLen + 2 * C.plateMarginX,
  ("the plate must overhang each rail end by exactly %g px"):format(C.plateMarginX))
-- THE RIM ARITHMETIC. alarmW/alarmH/rim/plateW/plateH are five separately typed
-- literals; edit any one alone and this stops the build by name.
assert(C.alarmW == C.plateW + 2 * C.rim and C.alarmH == C.plateH + 2 * C.rim,
  ("the alarm contract is %gx%g, but a %g px rim around a %gx%g plate is %gx%g")
    :format(C.alarmW, C.alarmH, C.rim, C.plateW, C.plateH,
      C.plateW + 2 * C.rim, C.plateH + 2 * C.rim))
assert(C.alarmW - C.plateW == 8 and C.alarmH - C.plateH == 8,
  "the alarm must be exactly 8 px larger than the plate in BOTH axes (4 px per side)")
assert(C.rim > 0, "a rim of zero px is a same-size ADD quad, i.e. a full-area wash")
assert(C.laneThreat - C.railThreatH / 2 - (C.laneHealth + C.railH / 2) == C.laneGap
  and C.laneHealth - C.railH / 2 - (C.lanePower + C.railH / 2) == C.laneGap,
  "the three lane offsets do not leave the contract's gap between the rails")
-- THE LANE STACK IS DERIVED FROM THE PLATE, and this is the check that says so.
-- Content top = plateY + plateH/2 - marginAbove, and each lane centre follows from
-- the stack; a lane offset copied from a pack with a different plate convention
-- lands here rather than on a player's screen.
do
  local top_ = C.plateY + C.plateH / 2 - C.marginAbove
  local want = {
    { "threat", C.laneThreat, top_ - C.railThreatH / 2 },
    { "health", C.laneHealth, top_ - C.railThreatH - C.laneGap - C.railH / 2 },
    { "power",  C.lanePower,  top_ - C.railThreatH - C.laneGap - C.railH - C.laneGap
                              - C.railH / 2 },
  }
  for _, w in ipairs(want) do
    assert(w[2] == w[3],
      ("the %s lane is at %g, but a %g px plate centred on %+g with %g px margins puts "
        .. "it at %g — lane offsets are DERIVED from this pack's plate convention, "
        .. "never copied from another pack's"):format(w[1], w[2], C.plateH, C.plateY,
        C.marginAbove, w[3]))
  end
end
-- 1.6 PX PER PERCENT, and the reason 160 is legitimate: every value this pack
-- marks is a multiple of five, and 1.6 x 5 = 8, so no mark can land off-pixel.
assert(C.railLen / 100 == C.pxPerPct,
  ("a %g px rail is %g px per percent, and the contract says %g")
    :format(C.railLen, C.railLen / 100, C.pxPerPct))
for _, v in ipairs({ C.notchV, C.rulerV[1], C.rulerV[2], C.rulerV[3] }) do
  assert(v % 5 == 0,
    ("this pack marks %g, which is not a multiple of five — the whole-pixel "
      .. "guarantee at %g px per percent depends on that"):format(v, C.pxPerPct))
end

-- the BUILD CONSTANTS, checked against it. This is the pair of eyes the old block
-- did not have: change one of these alone and the build stops here by name.
for _, b in ipairs({
  { "SILL_X", SILL_X, C.absX },          { "SILL_Y", SILL_Y, C.absY },
  { "TOP_Y", TOP_Y, C.topY },            { "RES_Y", RES_Y, C.resY },
  { "PLAYER_GX", PLAYER_GX, C.absX },    { "PLAYER_GY", PLAYER_GY, C.sillGY },
  { "PLATE_W", PLATE_W, C.plateW },      { "PLATE_H", PLATE_H, C.plateH },
  { "PLATE_Y", PLATE_Y, C.plateY },      { "PLATE_MARGIN_X", PLATE_MARGIN_X, C.plateMarginX },
  { "RIM", RIM, C.rim },
  { "ALARM_W", ALARM_W, C.alarmW },      { "ALARM_H", ALARM_H, C.alarmH },
  { "LANE_GAP", LANE_GAP, C.laneGap },   { "LANE_MARGIN", LANE_MARGIN, C.marginAbove },
  { "CONTENT_H", CONTENT_H, C.plateH - C.marginAbove - C.marginBelow },
  { "LANE_THREAT", LANE_THREAT, C.laneThreat },
  { "LANE_HEALTH", LANE_HEALTH, C.laneHealth },
  { "LANE_POWER", LANE_POWER, C.lanePower },
  { "RAIL_LEN", RAIL_LEN, C.railLen },   { "RAIL_H", RAIL_H, C.railH },
  { "RAIL_THREAT_H", RAIL_THREAT_H, C.railThreatH },
  { "PCT_SIZE", PCT_SIZE, C.pctSize },   { "PCT_X", PCT_X, C.pctX },
  { "PCT_Y", PCT_Y, C.pctY },            { "PCT_THREAT", PCT_THREAT, C.pctThreatSize },
  { "PCT_THREAT_Y", PCT_THREAT_Y, C.pctThreatY },
  { "RULER_W", RULER_W, C.rulerW },      { "NOTCH_W", NOTCH_W, C.notchW },
  { "NOTCH_THREAT", NOTCH_THREAT, C.notchX },
  { "PVP_GX", PVP_GX, C.pvpX },
}) do
  assert(b[2] == b[3],
    ("the build constant %s is %s but the design contract says %s — retuning the "
      .. "Sill means editing BOTH, on purpose, not one of them by accident")
      :format(b[1], tostring(b[2]), tostring(b[3])))
end
assert(#RULER_X == #C.rulerX and #RULER_V == #C.rulerV,
  "the ruler no longer has the contract's number of lines")
for i, x in ipairs(C.rulerX) do
  assert(RULER_V[i] == C.rulerV[i],
    ("ruler line %d marks %s, contract says %s"):format(i, tostring(RULER_V[i]),
      tostring(C.rulerV[i])))
  assert(RULER_X[i] == x,
    ("ruler line %d is built at x %s, contract says %s"):format(i, tostring(RULER_X[i]), tostring(x)))
end
assert(RULER_COL[4] == C.rulerAlpha, "the ruler is no longer at the contract's 18% white")

-- 1. THE STRIP, and every lane in it, by the WALKED parent chain, against the
-- CONTRACT's absolute target rather than against the constant that built it. The
-- group must land on (0, -110); each region must land on the group plus its own
-- lane offset and nothing else. This is what would catch a rail that had been
-- given a stray offset when it was re-parented.
local SILL = {
  { id = "Warlock - Player Sill",   y = 0 },             -- the group
  { id = "Warlock - Threat Flash",  y = C.plateY },      -- the alarm rim, drawn FIRST
  { id = "Warlock - Sill Plate",    y = C.plateY },      -- the ledge, second
  { id = "Warlock - Threat",        y = C.laneThreat },  -- lane 1
  { id = "Warlock - Player Health", y = C.laneHealth },  -- lane 2
  { id = "Warlock - Player Mana",   y = C.lanePower },   -- lane 3
}
local SILL_IDS = {}
for _, s in ipairs(SILL) do
  SILL_IDS[s.id] = true
  assertAt(s.id, C.absX, C.absY + s.y)
  local n = assert(nodes[s.id])
  if n.regionType ~= "group" then
    assert(n.xOffset == 0, s.id .. ": a lane must sit on the strip's centre line")
    assert(n.yOffset == s.y,
      ("%s: local y is %s, expected %s"):format(s.id, tostring(n.yOffset), tostring(s.y)))
  end
end
do
  -- and the group itself must carry the DERIVED local offset, not the absolute
  -- one: typing -110 here would put the strip at -140 + 56 - 110 = -194, in the
  -- cooldown row. The walked sum above and this local value are two different
  -- facts and the string has to satisfy both.
  local g = assert(nodes["Warlock - Player Sill"])
  assert(g.xOffset == C.absX and g.yOffset == C.sillGY,
    ("the sill group carries local (%s, %s); the derived offset for absolute "
      .. "(%g, %g) under top %g + Resources %g is (%g, %g)")
      :format(tostring(g.xOffset), tostring(g.yOffset), C.absX, C.absY,
        C.topY, C.resY, C.absX, C.sillGY))
end

-- 2. THE LANE STACK: three lanes that do not touch each other, inside a plate
-- whose margins are exactly what the design claims. All spans are computed from
-- DECODED yOffset/height, so every number below is a measurement.
--
-- THE OVERLAP CHECK IS THE POINT, and containment does not imply it: three rails
-- can all sit inside the plate and still be drawn on top of one another. Moving
-- LANE_THREAT 17 -> 15.5 overlaps the threat and health rails by 0.5 px while
-- every containment test still passes — a 5 px warning bar quietly eating the top
-- half-pixel of the number rail underneath it.
do
  local plate = assert(nodes["Warlock - Sill Plate"])
  assert(plate.width == C.plateW and plate.height == C.plateH,
    ("the plate is %sx%s, expected %dx%d"):format(tostring(plate.width),
      tostring(plate.height), C.plateW, C.plateH))
  assert(plate.width == C.railLen + 2 * C.plateMarginX,
    ("the plate is %s wide; it must overhang each end of a %d px rail by exactly %g px")
      :format(tostring(plate.width), C.railLen, C.plateMarginX))

  local lanes = {}
  for _, id in ipairs({ "Warlock - Threat", "Warlock - Player Health", "Warlock - Player Mana" }) do
    local n = assert(nodes[id])
    lanes[#lanes + 1] = { id = id, t = n.yOffset + n.height / 2, b = n.yOffset - n.height / 2 }
  end
  table.sort(lanes, function(a, b) return a.t > b.t end)
  for i = 2, #lanes do
    local upper, lower = lanes[i - 1], lanes[i]
    local gap = upper.b - lower.t
    assert(gap > 0,
      ("%s [%g..%g] OVERLAPS %s [%g..%g] by %g px — two rails drawn over each other")
        :format(upper.id, upper.b, upper.t, lower.id, lower.b, lower.t, -gap))
    assert(gap == C.laneGap,
      ("the gap between %s and %s is %g px, and the contract says %g")
        :format(upper.id, lower.id, gap, C.laneGap))
  end

  local top_, bottom = lanes[1].t, lanes[#lanes].b
  local plateTop, plateBottom = C.plateY + C.plateH / 2, C.plateY - C.plateH / 2
  assert(top_ <= plateTop and bottom >= plateBottom,
    ("the rails span %g..%g but the plate only covers %g..%g"):format(bottom, top_,
      plateBottom, plateTop))
  -- EXACT, not "inside": the margins are a design term, and a plate that has
  -- grown a lane's worth of slack is a plate built for a lane that is missing.
  assert(plateTop - top_ == C.marginAbove and bottom - plateBottom == C.marginBelow,
    ("the plate's margins are %g px above and %g px below; the contract says %g / %g "
      .. "(36 tall is the NO-LANE-4 variant this pack ships; 45 is the variant with "
      .. "a class-resource lane, which a warlock does not have)")
      :format(plateTop - top_, bottom - plateBottom, C.marginAbove, C.marginBelow))
  print(("v17 sill: plate %dx%d at absolute (%d, %g); rails span local %g..%g "
    .. "(%g px above, %g px below, %g px between lanes)"):format(C.plateW, C.plateH,
      C.absX, C.absY + C.plateY, bottom, top_, plateTop - top_, bottom - plateBottom,
      C.laneGap))
  print(("  lane stack: threat %+g/%g, health %+g/%g, power %+g/%g -> %g of content "
    .. "in a %g plate"):format(C.laneThreat, C.railThreatH, C.laneHealth, C.railH,
      C.lanePower, C.railH, top_ - bottom, C.plateH))
end

-- 3. RAIL CANON — the direct replacement for v11-v13's ring canon.
local RAILS = {
  -- `esc` is how many colour-escalation steps the design gives this rail; block 4b
  -- proves they are all on `foregroundColor` and that none of them went missing.
  { id = "Warlock - Threat",        h = C.railThreatH, subs = 2, esc = 2, colour = GCOL.threat },
  { id = "Warlock - Player Health", h = C.railH,       subs = 4, esc = 1, colour = GCOL.health },
  { id = "Warlock - Player Mana",   h = C.railH,       subs = 4, esc = 1, colour = GCOL.mana },
}
for _, r in ipairs(RAILS) do
  local n = assert(nodes[r.id])
  assert(n.regionType == "progresstexture", r.id .. ": not a progresstexture")
  assert(n.orientation == "HORIZONTAL",
    r.id .. ": not on the LINEAR left-anchored fill path. LinearProgressTexture.lua "
    .. "gives HORIZONTAL the corners x = 0..progress (fill anchored LEFT, grows "
    .. "RIGHT); HORIZONTAL_INVERSE is 1-progress..1 and empties from the left, no "
    .. "matter what the options dropdown labels them")
  assert(n.width == C.railLen,
    ("%s is %s px long; the profile's rail is %d, i.e. %g px per percent")
      :format(r.id, tostring(n.width), C.railLen, C.pxPerPct))
  assert(n.height == r.h,
    ("%s is %s tall, expected %d"):format(r.id, tostring(n.height), r.h))
  assert(n.width > 8 * n.height,
    ("%s is %s x %s; a vitals rail must read as LONG AND THIN — the fill's travel "
      .. "is the signal and its thickness carries nothing")
      :format(r.id, tostring(n.width), tostring(n.height)))
  assert(n.width ~= n.height, r.id .. ": still square — this is a rail, not a ring")
  assert(n.foregroundTexture == SQUARE and n.backgroundTexture == SQUARE,
    r.id .. ": not drawn with the plain white square")
  assert(n.sameTexture == true, r.id .. ": fill and track are not the same art")
  assert(n.crop_x == 0.41 and n.crop_y == 0.41, r.id .. ": crop is not the default scale")
  assert(n.backgroundOffset == 0, r.id .. ": the track is not the same rectangle as the fill")
  assert(n.auraRotation == 0, r.id .. ": auraRotation must be emitted")
  assert(n.blendMode == "BLEND", r.id .. ": a rail must not be additive")
  assert(n.smoothProgress == true, r.id .. ": lost its smoothing")
  assert(type(n.adjustedMin) == "string" and type(n.adjustedMax) == "string",
    r.id .. ": adjustedMin/Max must be STRINGS (SetAdjustedMin does a :find)")
  assert(n.progressSource[1] == -1 and n.progressSource[2] == "",
    r.id .. ": progress source is not Automatic")
  local fg = n.foregroundColor
  assert(fg[1] == r.colour[1] and fg[2] == r.colour[2] and fg[3] == r.colour[3]
    and fg[4] == r.colour[4], r.id .. ": foregroundColor drifted from the canon")
  local bg = n.backgroundColor
  assert(bg[1] == GCOL.track[1] and bg[4] == GCOL.track[4],
    r.id .. ": the unfilled track is not the canonical dark")
  assert(#n.subRegions == r.subs,
    ("%s has %d sub-regions, expected %d"):format(r.id, #n.subRegions, r.subs))
  assert(n.subRegions[1].type == "subtext", r.id .. ": sub.1 is not the percentage")
  for i = 2, r.subs do
    assert(n.subRegions[i].type == "subtexture",
      ("%s: sub.%d is not a mark"):format(r.id, i))
  end
end

-- 4. NO RING SURVIVES. Nothing in the pack may still be on the circular path or
-- still be drawn with the annulus — a half-converted strip verifies perfectly.
for _, ch in ipairs(back.c) do
  assert(ch.orientation ~= "CLOCKWISE" and ch.orientation ~= "ANTICLOCKWISE",
    ch.id .. ": still on the circular fill path after the v14 conversion")
  assert(ch.texture == nil or not tostring(ch.texture):find("Ring_", 1, true),
    ch.id .. ": still drawn with the ring annulus")
  assert(ch.foregroundTexture == nil
    or not tostring(ch.foregroundTexture):find("Ring_", 1, true),
    ch.id .. ": still filled with the ring annulus")
  assert(ch.regionType ~= "model", ch.id .. ": a model region survived the v14 conversion")
end

-- 4b. THE SILENT-NO-OP CENSUS, WHOLE PACK. Conditions.lua looks a change's
-- property up in the REGION TYPE's own property table and skips it if it is not
-- there: no error, no editor warning, nothing on screen. The three colour setters
-- are one letter of thought apart and are not interchangeable —
--     progresstexture -> foregroundColor      (the three rails)
--     texture / icon / model -> color         (the plate, the alarm)
--     aurabar -> barColor                     (the arena Enemy Mana rows)
-- v14's first cut asserted this for the THREAT rail alone, which left the health
-- and power rails free to ship `barColor` or `color` and lose their escalation
-- with nothing anywhere to say so. Mutation-tested: all three of those edits used
-- to rebuild clean. So the census walks EVERY condition on EVERY aura in the pack
-- and then requires each rail to still HAVE the escalation the design gives it.
local COLOUR_SETTER = {
  progresstexture = "foregroundColor",
  texture = "color", icon = "color", model = "color", text = "color",
  aurabar = "barColor",
}
local CONFUSABLE = { foregroundColor = true, barColor = true, color = true }
do
  local seen = {}
  local everyAura = { back.d }
  for _, ch in ipairs(back.c) do everyAura[#everyAura + 1] = ch end
  for _, aura in ipairs(everyAura) do
    for ci, cond in ipairs(aura.conditions or {}) do
      for _, chg in ipairs(cond.changes or {}) do
        if CONFUSABLE[chg.property] then
          local want = COLOUR_SETTER[aura.regionType]
          assert(want, ("%s: no known colour setter for region type %q")
            :format(aura.id, tostring(aura.regionType)))
          assert(chg.property == want,
            ("%s condition %d sets %q on a %s, whose colour setter is %q — "
              .. "Conditions.lua drops it silently and the colour never changes")
              :format(aura.id, ci, tostring(chg.property), tostring(aura.regionType), want))
          seen[aura.id] = (seen[aura.id] or 0) + 1
        end
      end
    end
  end
  for _, r in ipairs(RAILS) do
    assert((seen[r.id] or 0) == r.esc,
      ("%s carries %d colour-escalation step(s) on foregroundColor, expected %d")
        :format(r.id, seen[r.id] or 0, r.esc))
  end
  local total = 0
  for _, n in pairs(seen) do total = total + n end
  print(("  colour-setter census: %d condition colour change(s), every one on its "
    .. "region type's own setter"):format(total))
end

-- 5/6/7. THE NUMBERS AND THE MARKS, from the decoded string.
do
  local want = {
    { id = "Warlock - Player Health", sym = "%percenthealth%%", visible = true },
    { id = "Warlock - Player Mana",   sym = "%percentpower%%",  visible = true },
  }
  for _, w in ipairs(want) do
    local sub = assert(nodes[w.id].subRegions[1], w.id .. ": no percentage sub-region")
    assert(sub.type == "subtext", w.id .. ": sub-region 1 is not a subtext")
    assert(sub.text_text == w.sym,
      ("%s: text token is %q, expected %q"):format(w.id, tostring(sub.text_text), w.sym))
    assert(sub.text_fontSize == C.pctSize,
      ("%s: font is %s, expected %d"):format(w.id, tostring(sub.text_fontSize), C.pctSize))
    -- BOTH SPELLINGS, EQUAL. WeakAuras anchors on text_anchor*Offset (SubText.lua);
    -- the bare anchor*Offset is emitted by the region's own default() and read by
    -- nothing, so a string carrying one and not the other renders the number dead
    -- on its anchor point. That shipped once (v15 fixed it); verify-packs.lua fails
    -- any subtext whose two spellings disagree, and so does this.
    assert(sub.anchorXOffset == C.pctX and sub.anchorYOffset == C.pctY
      and sub.text_anchorXOffset == C.pctX and sub.text_anchorYOffset == C.pctY,
      ("%s: the number sits at (%s, %s) / text_ (%s, %s), expected (%d, %d) on BOTH "
        .. "spellings — inside its own rail")
        :format(w.id, tostring(sub.anchorXOffset), tostring(sub.anchorYOffset),
          tostring(sub.text_anchorXOffset), tostring(sub.text_anchorYOffset),
          C.pctX, C.pctY))
    assert(sub.text_anchorPoint == "CENTER",
      w.id .. ": percentage is not CENTER-anchored (INNER_RIGHT is unproven here)")
    assert(sub.text_visible == true, w.id .. ": its number is switched off")
    -- the readability kit the design leans on, now that the number is 12 pt
    assert(sub.text_fontType == "OUTLINE", w.id .. ": lost its OUTLINE font type")
    assert(sub.text_shadowColor and sub.text_shadowXOffset == 0 and sub.text_shadowYOffset == 0,
      w.id .. ": lost its shadow settings")
    -- THE NUMBER MUST FIT INSIDE ITS OWN RAIL. Widest string either rail can print
    -- is "100%" — 4 glyphs — and 0.60 em is a generous advance for Friz Quadrata
    -- digits, so half the string is 4 * 0.60 * size / 2.
    local half = 4 * 0.60 * C.pctSize / 2
    assert(C.pctX + half < C.railLen / 2,
      ("%s: a %d pt \"100%%\" centred on +%d reaches x %.1f and leaves the %d px rail")
        :format(w.id, C.pctSize, C.pctX, C.pctX + half, C.railLen))
    assert(C.pctSize <= C.railH,
      ("%s: a %d pt number is taller than the %d px rail it prints in")
        :format(w.id, C.pctSize, C.railH))
  end

  -- the threat number: still at sub.1, now 9 pt, switched OFF and LEFT WHERE IT IS
  local th = assert(nodes["Warlock - Threat"].subRegions[1])
  assert(th.type == "subtext" and th.text_text == "%threatpct%%",
    "threat: sub.1 is no longer the threat percentage")
  assert(th.text_fontSize == C.pctThreatSize, "threat: the (hidden) number changed size")
  assert(th.text_visible == false,
    "threat: the number must be switched OFF, not left on top of a 5 px rail")
  assert(th.anchorXOffset == 0 and th.anchorYOffset == C.pctThreatY
    and th.text_anchorXOffset == 0 and th.text_anchorYOffset == C.pctThreatY,
    ("threat: the hidden number moved to (%s, %s); the profile leaves it where it "
      .. "already is (0, %g), inert while text_visible is false")
      :format(tostring(th.text_anchorXOffset), tostring(th.text_anchorYOffset),
        C.pctThreatY))

  -- the 70% notch, and the quarter rulers, all APPENDED after sub.1
  local notch = assert(nodes["Warlock - Threat"].subRegions[2])
  assert(notch.type == "subtexture" and notch.textureVisible == true,
    "threat: sub.2 is not a visible mark")
  assert(notch.xOffset == C.notchX,
    ("threat notch is at x %s, but %g%% of a %d px rail is x +%d")
      :format(tostring(notch.xOffset), C.notchV, C.railLen, C.notchX))
  assert(notch.width == C.notchW and notch.height == C.railThreatH,
    "threat notch: not a full-height waterline")
  assert(notch.textureTexture == SQUARE and notch.anchor_mode == "point"
    and notch.self_point == "CENTER" and notch.anchor_point == "CENTER",
    "threat notch: not a point-anchored white waterline")
  for _, id in ipairs({ "Warlock - Player Health", "Warlock - Player Mana" }) do
    local subs = nodes[id].subRegions
    for i, x in ipairs(C.rulerX) do
      local m = assert(subs[i + 1], ("%s: missing ruler line %d"):format(id, i))
      assert(m.type == "subtexture" and m.xOffset == x and m.width == C.rulerW
        and m.height == C.railH and m.textureVisible == true,
        ("%s: ruler line %d is not a %d x %d hairline at x %d")
          :format(id, i, C.rulerW, C.railH, x))
      assert(m.textureColor[4] == C.rulerAlpha,
        id .. ": ruler line " .. i .. " is not at 18%")
    end
  end
  -- THE RULER'S INK BUDGET — an independent check on RULER_W, and the reason the
  -- design says "hairlines". A mark wide enough to be mistaken for a segment of the
  -- fill has stopped being a scale and started lying about the value. The bound is
  -- 4% of the rail: v14's three 1 px lines on a 100 px rail spent 3.0%, and the v17
  -- profile's three 2 px lines on a 160 px rail spend 3.75% (a 1 px hairline at this
  -- length reads as a wire, which is why the profile doubles it). Three 4 px lines
  -- would be 7.5% and would fail here.
  local RULER_INK_PCT = 4
  assert(#C.rulerX * C.rulerW * 100 <= C.railLen * RULER_INK_PCT,
    ("the ruler spends %g px of a %d px rail (%.2f%%); hairlines must stay under %g%%")
      :format(#C.rulerX * C.rulerW, C.railLen,
        #C.rulerX * C.rulerW * 100 / C.railLen, RULER_INK_PCT))
  assert(C.rulerW < C.notchW * 2 and C.rulerW < C.railThreatH,
    "a ruler hairline must stay thinner than the breakpoint marks it sits beside")
  -- and the formula they all come from, checked rather than trusted
  assert(markX(0) == -C.railLen / 2 and markX(100) == C.railLen / 2 and markX(50) == 0,
    "the breakpoint formula no longer maps 0/50/100 onto the ends and the middle")
  assert(markX(C.notchV) == C.notchX,
    ("the %g%% mark computes to x %s; the contract's notch is at +%d")
      :format(C.notchV, tostring(markX(C.notchV)), C.notchX))

  -- 5b. EVERY MARK LANDS ON A WHOLE PIXEL, value by value, recomputed from markX.
  -- THIS IS THE CHECK THAT LICENSES A NON-ROUND RAIL. At 1 px per percent every
  -- mark is trivially whole; at 1.6 px per percent it is whole only because every
  -- value this pack marks is a multiple of five and 1.6 x 5 = 8. A future mark at,
  -- say, 33% would compute to 52.8 and fail here rather than shipping a hairline
  -- straddling two pixels (which the client resolves by blurring it across both).
  local marks = { { C.notchV, C.notchX, "the threat notch" } }
  for i, v in ipairs(C.rulerV) do
    marks[#marks + 1] = { v, C.rulerX[i], ("the %g ruler line"):format(v) }
  end
  local shown = {}
  for _, m in ipairs(marks) do
    local value, wantX, label = m[1], m[2], m[3]
    local x = markX(value)
    assert(x == wantX,
      ("%s: markX(%g) is %s and the contract says %s")
        :format(label, value, tostring(x), tostring(wantX)))
    assert(x == math.floor(x),
      ("%s: markX(%g) = %s is NOT a whole pixel at %g px per percent")
        :format(label, value, tostring(x), C.pxPerPct))
    assert(math.abs(x) % (5 * C.pxPerPct) == 0,
      ("%s: markX(%g) = %s is not a multiple of %g, so the multiple-of-five "
        .. "guarantee has been broken"):format(label, value, tostring(x), 5 * C.pxPerPct))
    assert(math.abs(x) <= C.railLen / 2,
      ("%s: markX(%g) = %s falls outside the rail"):format(label, value, tostring(x)))
    shown[#shown + 1] = ("%g->%+g"):format(value, x)
  end
  print(("  marks: %s  (x = (v/100 - 0.5) * %d, %g px per percent; every mark a whole "
    .. "pixel)"):format(table.concat(shown, ", "), C.railLen, C.pxPerPct))
end

-- 9. THE PLATE AND THE ALARM RIM: two CONCENTRIC boxes on the same filled file,
-- the alarm 8 px larger in both axes, with explicit colours.
for _, b in ipairs({
  { id = "Warlock - Sill Plate",   colour = GCOL.plate, blend = "BLEND",
    w = C.plateW, h = C.plateH },
  { id = "Warlock - Threat Flash", colour = GCOL.alarm, blend = "ADD",
    w = C.alarmW, h = C.alarmH },
}) do
  local n = assert(nodes[b.id])
  assert(n.regionType == "texture", b.id .. ": not a texture region")
  assert(n.width == b.w and n.height == b.h,
    ("%s is %sx%s, expected %dx%d"):format(b.id, tostring(n.width), tostring(n.height),
      b.w, b.h))
  assert(n.texture == SQUARE_BOX, b.id .. ": not the bordered square")
  assert(n.blendMode == b.blend, b.id .. ": wrong blend mode")
  assert(type(n.color) == "table" and #n.color == 4,
    b.id .. ": ships no explicit colour — it would draw in WeakAuras' default")
  for i = 1, 4 do
    assert(n.color[i] == b.colour[i],
      ("%s: colour component %d is %s, expected %s")
        :format(b.id, i, tostring(n.color[i]), tostring(b.colour[i])))
  end
end
do
  local n = assert(nodes["Warlock - Threat Flash"])
  assert(n.animation.main.preset == "alphaPulse" and n.animation.main.duration == "1",
    "alarm frame: lost its pulse (an animation with no duration plays in 0 s)")
  local plate = assert(nodes["Warlock - Sill Plate"])
  local cc9 = assert(nodes["Warlock - Player Sill"].controlledChildren)
  -- THE RIM IS A SIZE **AND** A DRAW INDEX, and both halves are pinned here
  -- because either one alone silently turns the alarm back into a full-area wash.
  --
  -- The art forces it. Square_White_Border.tga measures 256x256, 32 bpp, RLE, and
  -- 64,516 of its 65,536 pixels — 98.44% — are FULLY OPAQUE. Every pixel inset
  -- 8 px or more from the edge (n = 57,600) has alpha 255 and no RGB channel below
  -- 167; the centre pixel is rgba(255,255,255,255) and the centre scanline's red
  -- channel climbs 0,156,100,56,40,57,102,158,206,236,250,254,255,255 over
  -- x = 0..13. It is a FILLED square with a dark bevel baked into its edge, not an
  -- outline, and its interior is not transparent. One region on it cannot trace a
  -- hollow edge — so the only way this alarm reads as an edge is to be BIGGER than
  -- the plate (8 px in both axes, 4 px per side) and to be drawn UNDER it (child
  -- #1, with the plate at #2). Ship it same-size, or ship it last, and >=80% threat
  -- paints ADD red across both rails, both numbers, the 70 notch and the ruler at
  -- the exact moment they have to be read.
  assert(n.texture == plate.texture and n.texture == SQUARE_BOX,
    ("the alarm is drawn from %q and the plate from %q; they must be the SAME "
      .. "filled file, because the rim is that file's own bevel showing past the "
      .. "plate rather than an outline region")
      :format(tostring(n.texture), tostring(plate.texture)))
  assert(n.width == plate.width + 2 * C.rim and n.height == plate.height + 2 * C.rim,
    ("the alarm is %sx%s; a %d px rim around a %sx%s plate is %dx%d")
      :format(tostring(n.width), tostring(n.height), C.rim,
        tostring(plate.width), tostring(plate.height), C.alarmW, C.alarmH))
  assert(n.width - plate.width == 8 and n.height - plate.height == 8,
    ("the alarm must be exactly 8 px larger than the plate in BOTH axes; it is "
      .. "%+g x %+g"):format(n.width - plate.width, n.height - plate.height))
  assert(n.xOffset == plate.xOffset and n.yOffset == plate.yOffset,
    "the alarm is not concentric with the plate, so the rim is not the same width "
      .. "on all four sides")
  assert(cc9[1] == "Warlock - Threat Flash",
    ("the alarm must be child #1 — the BOTTOM of the stack — but child 1 is %q. "
      .. "A filled ADD quad anywhere else washes everything under it")
      :format(tostring(cc9[1])))
  assert(cc9[2] == "Warlock - Sill Plate",
    ("the plate must be child #2, directly over the rim, but child 2 is %q — "
      .. "without it the whole oversized alarm is exposed, not just its rim")
      :format(tostring(cc9[2])))
  assert(n.blendMode == "ADD", "the alarm rim stopped being additive")
  assert(n.color[1] == 1 and n.color[2] == 0.1 and n.color[3] == 0.1
    and n.color[4] == 0.85,
    "the alarm rim is not the explicit (1, 0.1, 0.1, 0.85) red")
  assert(plate.triggers[1].trigger.event == "Health",
    "the plate lost the portrait's Health trigger")
  assert(plate.conditions[1].check.variable == "inCombat"
    and plate.conditions[1].changes[1].value == 0.5,
    "the plate lost the out-of-combat fade, so the strip no longer dims as one object")
  -- FRAME STRATA, DECLARED RATHER THAN LEFT SILENT. v13's portrait carried
  -- frameStrata 2 (frame_strata_types[2] = BACKGROUND, the LOWEST strata) so the
  -- model sat behind its rings. F.texture emits frameStrata 1 (Inherited) and v14
  -- keeps that, which makes it the ONE non-geometry field besides `color` that this
  -- version changes -- so it is asserted here and disclosed in the README rather
  -- than discovered later by someone diffing the strings. It is not a regression:
  -- the plate is child #2, the alarm rim is child #1, and FixGroupChildrenOrder
  -- gives each child +4 frame levels in controlledChildren order (block 10 pins
  -- that), so rim and plate are still the two rearmost layers of the strip. What
  -- this pin forbids is a future edit lifting either box into a HIGHER strata than
  -- the rails, where strata would outrank frame level: a lifted plate would bury
  -- every rail, and a lifted alarm would go straight back to being a full-area red
  -- wash over the readouts no matter where it sits in controlledChildren.
  local railStrata = assert(nodes["Warlock - Player Health"]).frameStrata
  assert(plate.frameStrata == railStrata,
    ("the plate is on frameStrata %s and the rails on %s; a plate above its rails "
      .. "buries them whatever the child order says")
      :format(tostring(plate.frameStrata), tostring(railStrata)))
  assert(n.frameStrata == railStrata,
    "the alarm is not on the rails' strata; being FIRST only keeps it underneath "
      .. "while frame level, not strata, decides the layering")
end

-- 8. THREAT KEPT EVERYTHING. The trigger's unit arg, both load gates, all three
-- escalation steps on the progresstexture property, and the zero guard LAST
-- (later conditions overwrite earlier ones on the same property, so a guard that
-- is not last does not guard).
for _, id in ipairs({ "Warlock - Threat", "Warlock - Threat Flash" }) do
  local n = assert(nodes[id])
  local tr = n.triggers[1].trigger
  assert(tr.event == "Threat Situation", id .. ": trigger 1 is not Threat Situation")
  assert(tr.use_threatUnit == true and tr.threatUnit == "target",
    id .. ": IV-45 data must carry use_threatUnit/threatUnit")
  assert(tr.unit == nil, id .. ": `unit` is the IV-51+ name and must not be emitted at IV 45")
  assert(n.load.use_ingroup == true and n.load.ingroup.multi.group
    and n.load.ingroup.multi.raid, id .. ": lost the party/raid gate")
  assert(n.load.size.multi.arena == nil and n.load.size.multi.none == true,
    id .. ": lost the not-in-an-arena gate")
end
do
  local c = assert(nodes["Warlock - Threat"]).conditions
  assert(c[1].changes[1].property == "foregroundColor"
    and c[2].changes[1].property == "foregroundColor",
    "threat: escalation is not on foregroundColor (barColor/color are silent no-ops)")
  assert(c[1].check.variable == "threatpct" and c[1].check.value == "70"
    and c[2].check.variable == "aggro",
    "threat: escalation steps are not green -> orange(70) -> red(aggro)")
  local last = c[#c]
  assert(last.check.variable == "threatvalue" and last.check.op == "<="
    and last.check.value == "0" and last.changes[1].property == "alpha"
    and last.changes[1].value == 0,
    "threat: the mandatory zero guard is missing or is not the LAST condition")
end

-- 8b. AND SO DID HEALTH AND POWER. The threat rail is not the only one with a
-- zero-total inversion to guard or an escalation that can be silently switched
-- off: a progresstexture whose total is 0 draws FULL, so an unguarded rail reports
-- 100% at the moment it knows nothing (a unit whose max health has not streamed
-- yet, a unit with no power at all). Both guards must be the LAST condition on
-- their region, because later conditions overwrite earlier ones on the same
-- property — a guard that is not last does not guard. maxpower is written <= 1,
-- not <= 0, because the Power prototype floors total at math.max(1, ...).
for _, r in ipairs({
  { id = "Warlock - Player Health",
    esc   = { var = "percenthealth", op = "<=", value = "60", colour = GCOL.healthLow },
    guard = { var = "maxhealth",     op = "<=", value = "0" } },
  { id = "Warlock - Player Mana",
    esc   = { var = "percentpower",  op = "<",  value = "30", colour = GCOL.manaLow },
    guard = { var = "maxpower",      op = "<=", value = "1" } },
}) do
  local c = assert(nodes[r.id]).conditions
  local e = assert(c[1], r.id .. ": no escalation condition at all")
  assert(e.check.variable == r.esc.var and e.check.op == r.esc.op
    and e.check.value == r.esc.value,
    ("%s: escalation reads %s %s %s, expected %s %s %s")
      :format(r.id, tostring(e.check.variable), tostring(e.check.op),
        tostring(e.check.value), r.esc.var, r.esc.op, r.esc.value))
  assert(e.changes[1].property == "foregroundColor",
    ("%s: escalation is on %q; on a progresstexture the colour setter is "
      .. "foregroundColor and barColor/color are silent no-ops")
      :format(r.id, tostring(e.changes[1].property)))
  for i = 1, 4 do
    assert(e.changes[1].value[i] == r.esc.colour[i],
      ("%s: escalation colour component %d drifted"):format(r.id, i))
  end
  local last = c[#c]
  assert(last.check.variable == r.guard.var and last.check.op == r.guard.op
    and last.check.value == r.guard.value and last.changes[1].property == "alpha"
    and last.changes[1].value == 0,
    ("%s: the mandatory zero guard (%s %s %s -> alpha 0) is missing or is not the "
      .. "LAST condition — a zero-total progresstexture draws FULL")
      :format(r.id, r.guard.var, r.guard.op, r.guard.value))
end

-- 12. the v12 target cluster is still GONE, ids and all, and v17 adds no removals
for _, id in ipairs({
  "Warlock - Target Orb", "Warlock - Target Health",
  "Warlock - Target Ring Track", "Warlock - Target Portrait",
}) do
  assert(nodes[id] == nil, id .. " is still in the shipped string")
end

-- 10. DRAW ORDER: alarm rim first, plate second, the three rails on top of both,
-- and the flat c-list agreeing. v13 listed the portrait first and the ring HALO
-- last, which was right for an annulus with a hole in it; v14's alarm is a FILLED
-- quad, so it moves to the bottom and grows RIM px per side instead. Every readout
-- must draw ABOVE both boxes.
do
  local cc = assert(nodes["Warlock - Player Sill"].controlledChildren)
  assert(cc[1] == "Warlock - Threat Flash",
    ("the alarm rim must be the FIRST child, but child 1 is %q — it is a FILLED "
      .. "quad on ADD blend, so anywhere later it washes out every rail, both "
      .. "numbers, the notch and the ruler"):format(tostring(cc[1])))
  assert(cc[2] == "Warlock - Sill Plate",
    ("the plate must be the SECOND child, but child 2 is %q — it is what covers "
      .. "all of the alarm except its %g px rim, and it is a FILLED rectangle at "
      .. "45%% black, so anywhere later it greys out every rail and both numbers")
      :format(tostring(cc[2]), C.rim))
  local railsAbove = 0
  for i = 3, #cc do
    if nodes[cc[i]].regionType == "progresstexture" then railsAbove = railsAbove + 1 end
  end
  assert(railsAbove == 3,
    ("only %d of 3 rails are drawn above the rim and the plate"):format(railsAbove))
  assert(nodes[cc[#cc]].regionType == "progresstexture",
    ("the top of the stack is %q, not a readout"):format(tostring(cc[#cc])))
  -- the load-bearing claim, stated as a check: NOTHING in the sill is composited
  -- over a readout.
  for i = 2, #cc do
    assert(cc[i] ~= "Warlock - Threat Flash", "the alarm rim appears twice in the draw order")
  end
  -- ...and the flat c-list agrees with it, depth-first (F.assemble derives it from
  -- controlledChildren, so this catches a hand-edit that desynchronised the two).
  local order = {}
  for _, ch in ipairs(back.c) do
    if ch.parent == "Warlock - Player Sill" then order[#order + 1] = ch.id end
  end
  assert(#order == #cc, "sill c-list and controlledChildren differ in length")
  for i = 1, #cc do
    assert(order[i] == cc[i],
      ("c-list is out of step with controlledChildren at %d: %q vs %q")
        :format(i, tostring(order[i]), tostring(cc[i])))
  end
  print(("  draw order: %s"):format(table.concat(cc, " -> ")))
end

-- 11. THE RECTANGLE SCAN. The strip against every other element in the pack, with
-- every dynamic group PROJECTED SIX CHILDREN DEEP. The alert column grows upward,
-- the PvP column downward and the cooldown row sideways, so a scan of what is on
-- screen with one prompt up proves nothing about a real pull — that is exactly how
-- an earlier pass shipped an overlap. Sizes come from the widest and tallest child
-- actually shipped, read out of the decoded string, never from a remembered number.
--
-- THE SCANNED BOX IS THE ALARM ENVELOPE, NOT THE PLATE. The alarm is the widest and
-- tallest thing the strip ever draws (172 x 44 against the plate's 164 x 36), and it
-- is exactly what appears at >=80% threat, i.e. during a real pull. Scanning the
-- plate would prove clearance for the calm case only. The union below is built from
-- every non-group member of the sill, so it picks the alarm up automatically.
do
  local DEPTH = 6
  local function rectOf(id, x, y, w, h)
    return { id = id, l = x - w / 2, r = x + w / 2, b = y - h / 2, t = y + h / 2 }
  end
  local boxes = {}
  local strip
  for _, ch in ipairs(back.c) do
    local x, y = absPos(ch.id)
    if SILL_IDS[ch.id] then
      if ch.regionType ~= "group" then
        local r = rectOf(ch.id, x, y, ch.width, ch.height)
        if not strip then strip = r else
          strip.l = math.min(strip.l, r.l); strip.r = math.max(strip.r, r.r)
          strip.b = math.min(strip.b, r.b); strip.t = math.max(strip.t, r.t)
        end
      end
    elseif ch.regionType == "dynamicgroup" then
      -- project the stack: WeakAuras lays children out from the group's anchor in
      -- `grow`, which is why selfPoint is paired with it (gotchas.md).
      local widest, tallest = 0, 0
      for _, cid in ipairs(ch.controlledChildren) do
        local k = assert(nodes[cid])
        widest, tallest = math.max(widest, k.width or 0), math.max(tallest, k.height or 0)
      end
      local runW = DEPTH * widest + (DEPTH - 1) * ch.space
      local runH = DEPTH * tallest + (DEPTH - 1) * ch.space
      local r
      if ch.grow == "UP" then
        r = { id = ch.id, l = x - widest / 2, r = x + widest / 2, b = y, t = y + runH }
      elseif ch.grow == "DOWN" then
        r = { id = ch.id, l = x - widest / 2, r = x + widest / 2, b = y - runH, t = y }
      elseif ch.grow == "HORIZONTAL" then
        r = { id = ch.id, l = x - runW / 2, r = x + runW / 2, b = y - tallest / 2, t = y + tallest / 2 }
      elseif ch.grow == "RIGHT" then
        r = { id = ch.id, l = x, r = x + runW, b = y - tallest / 2, t = y + tallest / 2 }
      elseif ch.grow == "LEFT" then
        r = { id = ch.id, l = x - runW, r = x, b = y - tallest / 2, t = y + tallest / 2 }
      else
        r = { id = ch.id, l = x - runW / 2, r = x + runW / 2, b = y - runH / 2, t = y + runH / 2 }
      end
      boxes[#boxes + 1] = r
    elseif ch.regionType ~= "group" then
      local parent = nodes[ch.parent]
      if not (parent and parent.regionType == "dynamicgroup") then
        boxes[#boxes + 1] = rectOf(ch.id, x, y, ch.width or 0, ch.height or 0)
      end
    end
  end
  assert(strip, "the strip has no geometry")
  local overlaps = {}
  for _, r in ipairs(boxes) do
    if r.l < strip.r and r.r > strip.l and r.b < strip.t and r.t > strip.b then
      overlaps[#overlaps + 1] = ("%s [x %g..%g, y %g..%g]"):format(r.id, r.l, r.r, r.b, r.t)
    end
  end
  assert(#overlaps == 0,
    ("the strip at x %g..%g, y %g..%g collides with %d element(s): %s")
      :format(strip.l, strip.r, strip.b, strip.t, #overlaps, table.concat(overlaps, "; ")))

  -- THE FREE BAND — an INDEPENDENT check on the absolute y, and the one thing the
  -- overlap scan above cannot give. This pack is not the constraint: the Sill sits
  -- at the same place in all seven, so the y has to clear paladin's and hunter's
  -- buff rows (y -80..-40) and everyone else's (y -176..-136, which in THIS pack
  -- is the DoT row at y -156). A local scan says nothing about that — the design's
  -- first-draft -21 collides with NOTHING in the warlock pack and is still wrong,
  -- because it is the character's waist and leaves 0.5 px to two other packs.
  assert(strip.t <= C.bandTop and strip.b >= C.bandBottom,
    ("the strip spans y %g..%g and the free band under the character is %g..%g — "
      .. "outside it the strip lands on a buff row in at least one of the seven packs")
      :format(strip.b, strip.t, C.bandBottom, C.bandTop))
  -- the envelope IS the alarm, in both axes: it is the largest region in the strip.
  assert(strip.l == C.absX - C.alarmW / 2 and strip.r == C.absX + C.alarmW / 2,
    ("the strip envelope spans x %g..%g; the %d px alarm rim centred on %g spans "
      .. "%g..%g — the scan must cover the widest thing the strip ever draws")
      :format(strip.l, strip.r, C.alarmW, C.absX, C.absX - C.alarmW / 2,
        C.absX + C.alarmW / 2))
  assert(strip.t - strip.b == C.alarmH,
    ("the strip envelope is %g px tall; the alarm rim is %d"):format(strip.t - strip.b, C.alarmH))
  -- the two clearances that define the free band, measured rather than assumed
  local above, below = math.huge, math.huge
  local aboveId, belowId
  for _, r in ipairs(boxes) do
    if r.r > strip.l and r.l < strip.r then          -- only things in the same column
      if r.b >= strip.t and r.b - strip.t < above then above, aboveId = r.b - strip.t, r.id end
      if r.t <= strip.b and strip.b - r.t < below then below, belowId = strip.b - r.t, r.id end
    end
  end
  -- THE TIGHTEST CLEARANCE IN ANY DIRECTION, over every scanned element rather than
  -- only the ones sharing a column. For a disjoint pair this is the largest of the
  -- four axis separations, i.e. the gap you would have to close to touch.
  local tight, tightId = math.huge, nil
  for _, r in ipairs(boxes) do
    local gap = math.max(strip.l - r.r, r.l - strip.r, strip.b - r.t, r.b - strip.t)
    if gap < tight then tight, tightId = gap, r.id end
  end
  print(("  rectangle scan: strip x %g..%g y %g..%g vs %d elements (dynamic groups %d deep) "
    .. "-> %d overlaps"):format(strip.l, strip.r, strip.b, strip.t, #boxes, DEPTH, #overlaps))
  print(("  envelope is the %dx%d ALARM RIM (plate %dx%d + %d px per side); "
    .. "tightest clearance anywhere: %.2f px to %s")
    :format(C.alarmW, C.alarmH, C.plateW, C.plateH, C.rim, tight, tostring(tightId)))
  print(("  clearance above: %s px to %s;  below: %s px to %s")
    :format(above == math.huge and "unbounded" or tostring(above), tostring(aboveId),
      below == math.huge and "unbounded" or tostring(below), tostring(belowId)))
  print(("  free band %g..%g: strip sits %g px clear of the top edge and %g px of the bottom")
    :format(C.bandBottom, C.bandTop, C.bandTop - strip.t, strip.b - C.bandBottom))
end

-- 11b. THE ALL-PAIRS STACK SCAN — the check block 11 STRUCTURALLY CANNOT MAKE.
--
-- Block 11 asks one question: does anything touch the strip. Every stack in this
-- pack is therefore measured against the sill and against nothing else, so two
-- FLANKING stacks can sit on top of each other for versions without a single
-- assertion noticing. That is not hypothetical — the same gap hid a real defect in
-- the sibling rogue pack (a 140 px kick-lockout aurabar drawn over a weapon-proc
-- icon), and it was hiding two here: at x +150 the PvP column overlapped the
-- cooldown row by 16 px and the right-hand DoT icon by 18 px, because its widest
-- child is a 120 px aurabar rather than a 32 px icon.
--
-- THE BOX MODEL, and the two things it is easy to get wrong:
--   * selfPoint names the corner of the CHILD that sits ON the anchor, so it says
--     which way the stack hangs. Only LEFT/RIGHT hang horizontally and only
--     TOP/BOTTOM hang vertically — everything else is CENTRED on that axis. A
--     DOWN-growing column uses selfPoint TOP, which is horizontally centred, which
--     is exactly why a 120 px child pushes this column's box 60 px to each side.
--   * a STATIC row is not projected at all: its children carry real offsets, so its
--     box is their union (the DoT row spans x -108..108 that way).
-- Dynamic stacks are projected DEPTH children deep from their own anchor, with the
-- widest and tallest child read out of the decoded string.
do
  local DEPTH = 6
  local STACKS = {
    "Warlock - Player Sill",   -- the strip itself, so this scan subsumes block 11
    "Warlock - DoTs",          -- static row, five icons at fixed offsets
    "Warlock - Alerts",        -- dynamic, grows UP from y -44
    "Warlock - Cooldowns",     -- dynamic, grows HORIZONTAL from x 0
    "Warlock - PvP",           -- dynamic, grows DOWN from y -44
  }
  local function stackBox(id)
    local g = assert(nodes[id], "stack " .. id .. " is missing")
    local gx, gy = absPos(id)
    local kids = g.controlledChildren or {}
    assert(#kids > 0, id .. ": a layout stack with no children")
    if g.regionType ~= "dynamicgroup" then
      local box
      for _, cid in ipairs(kids) do
        local k = assert(nodes[cid])
        local x, y = absPos(cid)
        local w, h = k.width or 0, k.height or 0
        local r = { x0 = x - w / 2, x1 = x + w / 2, y0 = y - h / 2, y1 = y + h / 2 }
        if not box then box = r else
          box.x0 = math.min(box.x0, r.x0); box.x1 = math.max(box.x1, r.x1)
          box.y0 = math.min(box.y0, r.y0); box.y1 = math.max(box.y1, r.y1)
        end
      end
      box.id, box.kind, box.depth = id, "static", #kids
      return box
    end
    local widest, tallest, widestId = 0, 0, nil
    for _, cid in ipairs(kids) do
      local k = assert(nodes[cid])
      if (k.width or 0) > widest then widest, widestId = k.width, cid end
      tallest = math.max(tallest, k.height or 0)
    end
    local depth = math.min(#kids, DEPTH)
    local space = tonumber(g.space) or 4
    local x0, x1 = gx - widest / 2, gx + widest / 2
    if g.selfPoint == "LEFT" then x0, x1 = gx, gx + widest
    elseif g.selfPoint == "RIGHT" then x0, x1 = gx - widest, gx end
    local y0, y1 = gy - tallest / 2, gy + tallest / 2
    if g.selfPoint == "TOP" then y0, y1 = gy - tallest, gy
    elseif g.selfPoint == "BOTTOM" then y0, y1 = gy, gy + tallest end
    local runX, runY = (depth - 1) * (widest + space), (depth - 1) * (tallest + space)
    if g.grow == "DOWN" then y0 = y0 - runY
    elseif g.grow == "UP" then y1 = y1 + runY
    elseif g.grow == "RIGHT" then x1 = x1 + runX
    elseif g.grow == "LEFT" then x0 = x0 - runX
    elseif g.grow == "HORIZONTAL" then x0, x1 = x0 - runX / 2, x1 + runX / 2
    elseif g.grow == "VERTICAL" then y0, y1 = y0 - runY / 2, y1 + runY / 2
    else
      error(("%s grows %q, which this scan does not project — add it rather than "
        .. "letting the stack go unmeasured"):format(id, tostring(g.grow)))
    end
    return { id = id, x0 = x0, x1 = x1, y0 = y0, y1 = y1, kind = "dynamic",
      depth = depth, widest = widest, tallest = tallest, widestId = widestId }
  end

  -- THE FLANKING COLUMNS RESOLVE TO THEIR ABSOLUTE TARGETS. Both hang off `top`,
  -- so a change to any ancestor would drag them; the walked sum is the only proof.
  -- Alerts is pinned at -150 because it has not moved since v4 and must not start
  -- moving as a side effect of the other column's fix.
  for _, want in ipairs({ { "Warlock - Alerts", C.alertsX }, { "Warlock - PvP", C.pvpX } }) do
    local x = select(1, absPos(want[1]))
    assert(x == want[2],
      ("%s resolves to absolute x %s, and the contract says %g")
        :format(want[1], tostring(x), want[2]))
  end

  local boxes = {}
  for _, id in ipairs(STACKS) do boxes[#boxes + 1] = stackBox(id) end
  local byName = {}
  for _, b in ipairs(boxes) do byName[b.id] = b end

  -- CROSS-CHECK: the sill's box here must be the same envelope block 11 scanned.
  -- Two independent box models that disagree about the same group would make both
  -- results meaningless.
  local sill = byName["Warlock - Player Sill"]
  assert(sill.x1 - sill.x0 == C.alarmW and sill.y1 - sill.y0 == C.alarmH,
    ("the all-pairs scan boxes the sill as %gx%g; block 11 scanned the %gx%g alarm "
      .. "envelope"):format(sill.x1 - sill.x0, sill.y1 - sill.y0, C.alarmW, C.alarmH))

  local hits, worst, worstPair = {}, math.huge, nil
  local lines = {}
  for i = 1, #boxes do
    for j = i + 1, #boxes do
      local a, b = boxes[i], boxes[j]
      -- for two disjoint rectangles this is the gap that would have to CLOSE for
      -- them to touch: overlap on both axes at once is what an overlap is.
      local gap = math.max(a.x0 - b.x1, b.x0 - a.x1, a.y0 - b.y1, b.y0 - a.y1)
      lines[#lines + 1] = ("    %-24s vs %-24s %8.1f px")
        :format(a.id:gsub("^Warlock %- ", ""), b.id:gsub("^Warlock %- ", ""), gap)
      if gap <= 0 then
        hits[#hits + 1] = ("%s [x %g..%g y %g..%g] and %s [x %g..%g y %g..%g] overlap "
          .. "by %g px"):format(a.id, a.x0, a.x1, a.y0, a.y1, b.id, b.x0, b.x1, b.y0,
          b.y1, -gap)
      elseif gap < worst then worst, worstPair = gap, a.id .. " / " .. b.id end
    end
  end
  assert(#hits == 0,
    ("all-pairs: %d stack pair(s) overlap, so one renders behind the other: %s")
      :format(#hits, table.concat(hits, "; ")))

  -- THE PvP COLUMN'S POSITION, DERIVED FROM THE THINGS IT HAS TO CLEAR rather than
  -- chosen. Its box is centred on its anchor (selfPoint TOP), so the anchor has to
  -- sit at least half its widest child past the right edge of everything it passes.
  local pvp = byName["Warlock - PvP"]
  local half = pvp.widest / 2
  local blocker, blockerId = -math.huge, nil
  for _, b in ipairs(boxes) do
    -- only things whose y-range the column actually passes through can bind it
    if b.id ~= pvp.id and b.y0 < pvp.y1 and b.y1 > pvp.y0 and b.x1 > blocker then
      blocker, blockerId = b.x1, b.id
    end
  end
  local minX = blocker + half
  assert(minX == C.pvpMinX,
    ("the PvP column's measured minimum anchor is %g (it must clear %s at x %g by "
      .. "half its widest child, %g px) and the contract says %g")
      :format(minX, tostring(blockerId), blocker, half, C.pvpMinX))
  assert(C.pvpX > C.pvpMinX,
    ("the PvP column is at %g and its measured minimum is %g")
      :format(C.pvpX, C.pvpMinX))
  assert(pvp.widest > 3 * 32,
    "the PvP column's widest child is icon-sized; the whole reason this scan exists "
      .. "is that it is not")

  print(("  all-pairs: %d stacks, %d pairs, dynamic groups %d deep, 0 overlaps; "
    .. "tightest %.1f px (%s)"):format(#boxes, #lines, DEPTH, worst, tostring(worstPair)))
  for _, line in ipairs(lines) do print(line) end
  print(("    PvP column: widest child %s at %g px -> box x %g..%g; measured minimum "
    .. "anchor %g (blocked by %s), shipped at %g")
    :format(tostring(pvp.widestId), pvp.widest, pvp.x0, pvp.x1, minX,
      tostring(blockerId), C.pvpX))
end

-- uid continuity vs the previous on-disk version (checked BEFORE overwriting, so
-- re-running after any future edit compares against the shipped string).
--
-- v14 PASSES NO ALLOWANCE, exactly as v13 did. v12 handed over a licence for four
-- deliberate removals; a licence that stays open outlives the deletion it was
-- written for and quietly permits the next one. It expired at the version bump —
-- exactly as tools/verify-packs.lua treats the `-- WA-REMOVED (vN):` tags, which it
-- honours only when the tag matches the version the pack currently ships. Those
-- four tags stay above as lineage and are inert on both sides. v14 removes nothing
-- and adds nothing — every one of the six strip auras is a v13 aura renamed,
-- re-typed, resized or re-parented — so it is on the default contract: no uid may
-- disappear and no id may change uid, full stop.
local txtPath = dir .. "/all-specs.txt"
local cont = W.uidContinuity(encoded, txtPath)
W.assertUidContinuity(cont, "warlock")

local out = assert(io.open(txtPath, "w"))
out:write(encoded)  -- single line, no trailing newline
out:close()

print(("OK: %d auras, %d chars -> all-specs.txt"):format(1 + #transmit.c, #encoded))
if cont then
  print(("uid continuity vs previous: stable=%d changed=%d missing=%d parentSame=%s")
    :format(cont.stable, cont.changed, cont.missing, tostring(cont.parentSame)))
  if cont.missing > 0 then
    print("  deliberately removed: " .. table.concat(cont.missingIds, ", "))
  end
end
