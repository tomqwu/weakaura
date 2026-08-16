-- generate.lua — Warlock TBC All-Specs HUD (v13).
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
-- CANONICAL RING CLUSTER — BYTE-IDENTICAL IN ALL SEVEN CLASS PACKS (v11)
--
-- Declared as named constants so a later edit has to notice it is breaking a
-- shared contract. Every one of these numbers is fixed repo-wide: v7 gave seven
-- packs a design intent instead of dimensions and every pack invented its own
-- sizes, which is exactly what read on screen as "the orbs do not match".
-- DO NOT retune, scale or "improve" any of them in one pack.
-- =====================================================================

-- Bundled WeakAuras media, present for everyone with no media addon.
-- Ring_20px is a TRUE ANNULUS (the number is the stroke weight of the 256 px
-- source art, so at 84 px it draws a ~7 px band and its hole is ~71 px wide —
-- room for the 44 px face inside the 62 px inner ring). Circle_Smooth, which the
-- v9/v10 globes used, is a SOLID DISC and on the circular path would sweep as a
-- pie wedge instead of an arc.
local RING_TEX = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Ring_20px.tga"

-- v12: ONE cluster, three rings. THREAT_RING is the new outermost ring; the
-- three numbers below it are unchanged, so a v11 cluster simply gains an arc.
local THREAT_RING = 100  -- outermost ring: YOUR threat (v12)
local OUTER       = 84   -- health ring
local INNER       = 62   -- primary power ring
local PORTRAIT    = 44   -- live unit portrait (44/84 = the 0.52 face-to-ring ratio)
local CLUSTER_X   = -270 -- ABSOLUTE screen x of the (only) cluster
local CLUSTER_Y   = 40   -- ABSOLUTE screen y of the (only) cluster

-- v13: THE HEALTH NUMBER LIVES IN THE MIDDLE, ON YOUR FACE.
--
-- A `model` region cannot carry a text sub-region at all (SubText's supports()
-- gate lists texture / progresstexture / icon / aurabar / empty — never model), so
-- the portrait itself can never hold a number. But the RINGS can, and every ring
-- is concentric on the cluster's centre, so a ring's text at anchorYOffset 0 lands
-- exactly in the middle — over the face. That is where the health number goes:
-- the middle of the cluster is the darkest, most stable backdrop it has, and it is
-- where the eye already is. Outside the rings it was two small figures floating
-- over the game world, which is precisely the "can't be seen" complaint.
--
-- The offsets are measured from the shared centre:
--   health  0    dead centre, ON the 44 px portrait (radius 22)
--   mana    -54  just under the 84 ring's radius of 42 — the slot health vacated
--   threat  +58  unchanged, outside the 100 ring's radius of 50
-- One number below the cluster instead of two stacked, and one in the middle.
--
-- This ONLY works together with the child order at the bottom of this file: the
-- portrait must be drawn FIRST (furthest back) or it covers the text. See the
-- draw-order note there — the offset alone is not the fix.
local PCT_HP        = 16   -- health percentage, CENTER — the headline number
local PCT_HP_Y      = 0    -- DEAD CENTRE, over the portrait (v13; was -54)
local PCT_POWER     = 12   -- power percentage, CENTER
local PCT_POWER_Y   = -54  -- just under the health ring, radius 42 (v13; was -70)
local PCT_THREAT    = 10   -- threat percentage, CENTER
local PCT_THREAT_Y  = 58   -- ABOVE the 100 px threat ring (radius 50), unchanged

-- -270 IS A CONTRACT, NOT A TASTE CALL, and it was not chosen for looks. The
-- Alerts column occupies x -170..-130 in the seven-pack layout — a DYNAMIC GROUP
-- that grows vertically — so at -190 the alert stack climbs into the cluster from
-- the second simultaneous prompt onward. -270 is the tightest position that is
-- clear at any stack depth, and v12's wider threat ring does not change that: the
-- cluster now reaches x -320..-220, still 48 px clear of the column's -172 edge
-- (this pack's Alerts group sits at -150 and its widest prompt is 44 px). That
-- clearance is ASSERTED at the bottom of this file against the decoded string,
-- with the alert stack projected six children deep, because "it looked fine with
-- one alert up" is exactly how an earlier pass shipped an overlap.

-- THE ABSOLUTE-POSITION RULE, and the trap it exists to close.
-- CLUSTER_Y is an ABSOLUTE screen offset, not a local one. The cluster hangs two
-- groups deep — `top` at (0, TOP_Y) and `Warlock - Resources` at (0, RES_Y) — and
-- WeakAuras ADDS every offset down the parent chain. Typing 40 onto the cluster
-- group would put it at -140 + 56 + 40 = -44. So the group offset is DERIVED from
-- its absolute target and can never drift out of sync with it:
--   PLAYER_GY = CLUSTER_Y - TOP_Y - RES_Y =  40 + 140 - 56 = 124
-- The x chain is all zeroes above the cluster, so the cluster group carries
-- CLUSTER_X directly and every ring and portrait inside it sits at a local
-- (0, 0) — which is what makes the three rings concentric BY CONSTRUCTION.
-- Proven below by walking the DECODED parent chain.
local TOP_Y     = -140   -- top-level group, unchanged since v1
local RES_Y     = 56     -- Resources group inside it, unchanged since v1
local PLAYER_GY = CLUSTER_Y - TOP_Y - RES_Y

-- The >=80% threat halo is not a readout, it is a warning overlay — and since v12
-- it sits exactly ON the threat ring (100 -> 100) rather than standing off from a
-- ring that is no longer the outermost one. Same alphaPulse, same 80% threshold.
local FLASH_RING = THREAT_RING

-- Canonical colours. health/mana/track/threat are the shared spec; the
-- escalation colours are v8's, unchanged, so nothing has to be relearned.
local GCOL = {
  health    = { 0.15, 0.82, 0.28, 1 },     -- the health arc
  mana      = { 0.20, 0.45, 0.95, 1 },     -- a warlock's power type IS mana, and
                                           -- the arc colour must always match
                                           -- what its trigger reads; the same
                                           -- constant table gives a rogue yellow
                                           -- energy and a warrior red rage.
  track     = { 0, 0, 0, 0.55 },           -- the unfilled arc behind every ring
  healthLow = { 0.95, 0.5, 0.15, 1 },      -- <=60%: the Life Tap health input
  manaLow   = { 0.75, 0.25, 0.95, 1 },     -- <30%: the Life Tap mana input
  threat    = { 0.25, 0.80, 0.30, 1 },
  threatHi  = { 1, 0.6, 0.1, 1 },          -- >=70%
  aggro     = { 0.9, 0.12, 0.12, 1 },      -- you pulled
  text      = { 1, 1, 1, 1 },              -- the health and power numbers
  thText    = { 1, 0.8, 0.55, 1 },         -- above the threat ring, v8's colour
}

-- ===== top-level group, anchored below the character =====
local top = F.group(TOP, 0, TOP_Y, nil)

-- =====================================================================
-- Resources — v12: ONE RING CLUSTER, three arcs around your own face.
--
-- A globe encoded its value as a WATERLINE inside a container. A ring encodes it
-- as ARC LENGTH around a hoop, which is what lets two values share one centre and
-- still be read separately — the whole reason a cluster can be two rings AROUND A
-- FACE instead of two vessels side by side. Same WeakAuras region type, one
-- different field:
--
--   orientation = "CLOCKWISE"  -- Private.orientation_with_circle_types
--
-- CLOCKWISE / ANTICLOCKWISE are the only two radial values; every other entry in
-- that table is linear and its name lies about direction the same way the
-- aurabar's VERTICAL does. Switching back from the linear path to the circular
-- one also swaps which fields are LIVE:
--   * startAngle / endAngle MATTER again. 0 / 360 = a full ring; WeakAuras
--     normalises 0/360 -> 0/0 and then corrects endAngle back up by 360, so the
--     full circle is a handled case, not a degenerate one.
--   * compress / slanted / slant / slantFirst / slantMode were live on the globe
--     and are INERT here. They stay in the table because they are in the region's
--     default table, not because they do anything.
--   * crop_x / crop_y 0.41 is the IDENTITY value on this path, not "no crop": the
--     circular path expands the texture by sqrt(2) so rotated quadrants never run
--     off it, and 1 + 0.41 exactly cancels that. Setting 0 blows the ring up 1.41x
--     and clips it.
--   * auraRotation = 0 is absent from the 3.5.0 default table but read
--     unconditionally as data.auraRotation / 180 * math.pi, so it must be emitted.
--   * backgroundColor is the UNFILLED ARC and backgroundOffset = 0 keeps that
--     track exactly concentric with the fill instead of a fatter halo around it.
--
-- LAYOUT (v12 — ONE cluster, ABSOLUTE screen coordinates):
--   PLAYER cluster (-270, 40)   threat 100 (outermost) / health 84 / mana 62,
--                               centre = your live 44 px portrait
-- The target cluster that stood at (+270, 110) is GONE — see the v12 note at the
-- top of this file. Its health readout duplicated the target frame and the
-- nameplate; its threat ring did not duplicate anything, so threat is the one
-- thing that moved rather than died, and it moved onto YOUR cluster because it
-- was always YOUR threat.
--
-- The health and mana rings carry a real decision and neither is decoration: Life
-- Tap trades the outer ring for the inner one, so "can I tap?" is literally "is
-- the 84 arc long and the 62 one short" — one cluster, one glance.
--
-- THE PORTRAIT IS BACK, and it is what puts the numbers back outside the rings. A
-- `model` region cannot carry a text sub-region at all (SubText's supports() gate
-- lists texture / progresstexture / icon / aurabar / empty — never model), so with
-- a live face in the middle each percentage rides on its own ring just past the
-- outer radius. That also means each number appears and vanishes with its ring.
--
-- THREAT IS YOUR CLUSTER'S OUTERMOST RING (v12). It is YOUR threat, so it belongs
-- on YOUR cluster: green -> orange at 70% -> red on aggro, most severe last, with
-- the percentage 58 px above the centre where it never collides with the health
-- and mana numbers below. Its party/raid gate, its not-in-an-arena gate, the
-- out-of-combat fade and the zero guard all come across untouched — which also
-- means the common solo case is still two rings and a face, and the third arc
-- only appears when threat is a real thing you can lose a raid slot to.
--
-- THE TRAPS, all of them silent no-ops if you get them wrong:
--   * the colour property on a PROGRESSTEXTURE is `foregroundColor`; on a TEXTURE
--     it is `color` (setter "Color"). The aurabar's `barColor` is neither, and
--     Conditions.lua skips a change whose property is not in the region's property
--     table with no error and no editor warning. THREAT CHANGED REGION TYPE in
--     v11 (texture -> progresstexture), so its escalation was RE-POINTED from
--     `color` to `foregroundColor`; a mechanical copy would have left it dead.
--   * ONE PROGRESS TRIGGER PER RING. Modernize (<71) rewrites every
--     progresstexture's progressSource to {-1,""} = Automatic regardless of what
--     is emitted, and Automatic reads the FIRST ACTIVE trigger's value/total. So
--     trigger 1 always supplies the arc, and the second trigger on each region
--     (Unit Characteristics) exists only to feed the out-of-combat fade.
--   * ZERO-TOTAL INVERSION: an aurabar with total == 0 draws EMPTY, a
--     progresstexture with total == 0 draws FULL (AuraBar.lua `local progress = 0`
--     vs ProgressTexture.lua `local progress = 1`). Threat hits total == 0
--     whenever threatvalue is 0 — the instant before your first cast lands, and
--     after a Soulshatter — so an unguarded threat ring reads as full aggro at
--     zero threat. Every region below therefore carries an explicit zero guard as
--     its LAST condition (later conditions overwrite earlier ones on the same
--     property, so the guard must win).
--
-- UID DISCIPLINE, v12 — THE FIRST VERSION THAT DELETES RATHER THAN RECYCLES.
-- Every version up to v11 recycled every uid, so an update left nothing behind.
-- v12 genuinely REMOVES four regions, and the honest way to do that is to remove
-- them: inventing filler regions to absorb their uids is how a HUD accumulates
-- junk nobody can explain a year later. What makes it safe is WHERE they sat.
-- The four removed regions consumed the LAST FOUR W.uid() calls in the seeded
-- stream (slots 3-6 of v7's six bottom-of-file auras):
--   1  "Warlock - Player Orb"          KEPT   (group, unchanged)
--   2  "Warlock - Player Portrait"     KEPT   (unchanged)
--   3  "Warlock - Target Orb"          REMOVED (group)
--   4  "Warlock - Target Health"       REMOVED
--   5  "Warlock - Target Ring Track"   REMOVED
--   6  "Warlock - Target Portrait"     REMOVED
-- Nothing is built after slot 6, so deleting the tail shifts no earlier call and
-- every one of the 40 surviving uids is byte-for-byte identical to v11's
-- (W.uidContinuity: changed = 0, and the only missing uids are those four).
-- "Warlock - Threat" and "Warlock - Threat Flash" keep the uids they have had
-- since v7 — they are re-parented and resized, not rebuilt.
-- WeakAuras never deletes an aura that an import does not mention, so those four
-- survive as a leftover `Warlock - Target Orb` group in the player's collection
-- and MUST be deleted by hand after updating. That is stated in the README.
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
-- A RING. Every ring in the pack is concentric on its cluster's centre, so it
-- carries a local (0, 0) and inherits its whole position from the cluster group.
-- `trigs` is the trigger list; trigger 1 always supplies the arc (see the
-- Automatic-progress note above).
local function ring(id, size, color, trigs)
  return orbStub{
    regionType = "progresstexture", id = id, uid = W.uid(), parent = nil,
    -- geometry
    width = size, height = size,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = 0, yOffset = 0, frameStrata = 1, alpha = 1,
    -- RADIAL fill: the arc sweeps round. 0 -> 360 is a full ring.
    orientation = "CLOCKWISE",
    startAngle = 0, endAngle = 360,
    inverse = false, mirror = false,
    -- LINEAR-only and inert on this path; emitted because they are in the
    -- region's default table.
    compress = false, slanted = false, slant = 0, slantFirst = false, slantMode = "INSIDE",
    -- textures
    foregroundTexture = RING_TEX, backgroundTexture = RING_TEX, sameTexture = true,
    desaturateForeground = false, desaturateBackground = false,
    foregroundColor = color, backgroundColor = GCOL.track,
    backgroundOffset = 0,
    blendMode = "BLEND", textureWrapMode = "CLAMPTOBLACKADDITIVE",
    -- 0.41 is the IDENTITY crop on the circular path, not "no crop".
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

-- A LIVE UNIT PORTRAIT — a real 3D model of whoever the unit is, not a static
-- image and not a class icon, which is what makes the target side work without
-- ever knowing the target's class: it renders NPCs and mobs too.
--   modelIsUnit = true + model_fileId = "<unit>" -> PlayerModel:SetUnit(unit)
--   portraitZoom = true                          -> SetPortraitZoom(1) head framing
-- CRITICAL: current WeakAuras reads the unit from `model_fileId`. WA 3.5.0 read
-- `model_path`, and the migration that bridges the two (Modernize < 72) is
-- guarded by WeakAuras.IsClassicEra(), which is a DISTINCT predicate from
-- IsTBC() — so on a 2.5.x client that migration DOES NOT RUN and emitting only
-- model_path is a silent no-op. BOTH are emitted; model_fileId does the work.
-- frameStrata 2 puts the face BEHIND its rings, which is what v13's centred health
-- number needs. WeakAuras' frame_strata_types[2] is BACKGROUND — the LOWEST
-- strata, below the inherited strata (1) every ring uses, not above it. (This file
-- claimed the opposite until v13; the mage pack documents the same fact for its
-- rims, which are likewise drawn behind at frameStrata 2.) Strata outranks frame
-- level entirely, so this alone already kept the face behind the arcs; the v13
-- child reorder makes the frame-level layer agree rather than contradict it.
-- Nothing is lost by being behind: the rings are annuli and none of their bands
-- reaches the face's radius. The portrait carries its cluster's own triggers, so
-- it appears, fades and vanishes with the rings around it.
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
    xOffset = 0, yOffset = 0, frameStrata = 2,
    border = false, borderColor = { 1, 1, 1, 0.5 }, backdropColor = { 1, 1, 1, 0.5 },
    borderEdge = "None", borderOffset = 5, borderInset = 11,
    borderSize = 16, borderBackdrop = "Blizzard Tooltip",
    subRegions = {},
    triggers = F.triggers(trigs),
    load = F.load(CLASS),
  }
end

-- The number rides on its ring, anchored to the ring's CENTRE, so `yOffset` is
-- measured from the shared cluster centre: 0 is dead middle (v13 puts health
-- there, over the face), negative is below, positive above. `sym` is the stored
-- trigger variable, which is also what makes the text a rounded integer rather
-- than 63.428571%.
local function pct(sym, size, yOffset, color)
  local st = F.subtext("%" .. sym .. "%%", size, "CENTER", sym)
  st.anchorYOffset = yOffset
  st.text_color = color
  return st
end

local gRes = reg(F.group("Warlock - Resources", 0, RES_Y, nil))
adopt(top, gRes)

-- --- player OUTER ring: health (was the life globe, same id and uid) -----
-- The outer ring gets the more-read number: the longer arc is the one the eye
-- catches first. Amber at or below 60% is the Life Tap prompt's health input, so
-- both halves of the "can I tap?" decision are readable on the cluster itself.
-- maxhealth <= 0 is the health equivalent of the threat guard: the Health
-- prototype's total is UnitHealthMax(unit) with no floor, so a unit whose max
-- health has not streamed yet would otherwise show a full ring (see the
-- zero-total inversion note above).
local pHealth = reg(ring("Warlock - Player Health", OUTER, GCOL.health,
  { F.healthTrigger(), F.unitCharTrigger() }))
pHealth.subRegions[1] = pct("percenthealth", PCT_HP, PCT_HP_Y, GCOL.text)
pHealth.conditions = {
  F.condition(1, "percenthealth", "<=", "60", "foregroundColor", GCOL.healthLow),
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

-- --- player INNER ring: mana (was the power globe, same id and uid) ------
-- Violet under 30%: the visual pair of the Life Tap prompt. The ring is blue
-- because a warlock's power type IS mana — powertype = 0 is what the trigger
-- reads, and the colour must always match what the trigger reads. maxpower's
-- guard is written <= 1, not <= 0, because the Power prototype floors total at
-- math.max(1, UnitPowerMax(...)) — a powerless unit reports exactly 1.
local pMana = reg(ring("Warlock - Player Mana", INNER, GCOL.mana,
  { F.powerTrigger(0), F.unitCharTrigger() }))
pMana.subRegions[1] = pct("percentpower", PCT_POWER, PCT_POWER_Y, GCOL.text)
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

-- --- OUTERMOST ring: YOUR THREAT (v12 — same id, same uid, new home) -----
-- Threat is YOUR threat, so v12 puts it on YOUR cluster as the outermost arc at
-- THREAT_RING (100), one ring further out than health: green -> orange at 70% ->
-- red on aggro, most severe last, exactly as the ring, the rim and the bar before
-- it escalated. Its readout sits 58 px ABOVE the centre, clear of the health and
-- mana numbers that hang below it. It is built HERE, in its v7 uid slot, and
-- re-parented to the player cluster in the wiring block at the bottom — the aura
-- moved on screen, its W.uid() call did not move at all.
-- THE PROPERTY IS `foregroundColor`. v9/v10 made threat a `texture`, whose colour
-- setter is `color`; since v11 it is a `progresstexture`, whose colour setter is
-- `foregroundColor` (and the aurabar's `barColor` is neither). Conditions.lua
-- silently skips a change whose property is not in the region's property table,
-- so a mechanically copied `color`/`barColor` would leave the escalation dead
-- with no warning anywhere.
-- Party/raid only and never in an arena, both carried over unchanged: solo you
-- are the tank on your own target, so an ungated ring sits permanently red, and
-- an arena has no threat table at all. Both gates plus the zero guard below are
-- why the solo cluster is still just two rings and a face — the third arc appears
-- only when threat is real.
-- THE GUARD IS MANDATORY, not defensive coding — see the zero-total note at the
-- top of this section. threatvalue is a stored conditionType "number" arg; the
-- prototype's hidden `total` is not, which is why the guard is written against
-- the value rather than the total.
local threat = reg(ring("Warlock - Threat", THREAT_RING, GCOL.threat,
  { F.threatTrigger(), F.unitCharTrigger() }))
threat.subRegions[1] = pct("threatpct", PCT_THREAT, PCT_THREAT_Y, GCOL.thText)
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

-- --- 80%+ threat halo ("Warlock - Threat Flash", same id and uid) --------
-- The v6 overlay was a 176x18 red rectangle pulsing across the threat bar; v7/v8
-- made it a ring outside the threat arc and v9/v10 a halo outside the globe's rim.
-- v12 sizes it to THREAT_RING exactly, so it pulses ON the threat ring instead of
-- orbiting a radius no ring occupies any more. Same trigger, same 80% threshold,
-- same load gates, same alphaPulse — only the diameter changed.
-- ADD blend so it reads as light over the ring rather than paint on top of it.
local flash = reg(F.texture("Warlock - Threat Flash", CLASS,
  FLASH_RING, FLASH_RING, 0, 0, nil, RING_TEX, { 1, 0.1, 0.1, 0.85 }))
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
-- v7's bottom-of-file auras, still built at the VERY BOTTOM, after every
-- v1/v2/v4/v5 uid() call, so all 38 older uids keep their position in the seeded
-- stream. v7-v11 kept all six of them and only changed WHAT each one was. v12 is
-- the first version to REMOVE any aura, and it removes exactly the tail:
--
--   1  "Warlock - Player Orb"        KEPT     (group, unchanged)
--   2  "Warlock - Player Portrait"   KEPT     (unchanged)
--   3  "Warlock - Target Orb"        REMOVED  (the target cluster's group)
--   4  "Warlock - Target Health"     REMOVED  (duplicated the target frame)
--   5  "Warlock - Target Ring Track" REMOVED  (existed only to balance the pair)
--   6  "Warlock - Target Portrait"   REMOVED  (duplicated the target frame)
--
-- REMOVING THE TAIL IS WHY EVERY SURVIVING UID IS STABLE. Slots 3-6 were the last
-- four W.uid() calls in the whole script; nothing is built after them, so deleting
-- them shifts nothing and the 40 remaining uids are byte-for-byte v11's.
--
-- AND YES, THEY LEAVE ORPHANS — deliberately. WeakAuras never deletes an aura that
-- an import does not mention, so after updating, the four removed regions remain
-- in the player's collection as a leftover `Warlock - Target Orb` group. The
-- README says so, by that exact name. The alternative — inventing filler regions
-- to absorb four uids — is how a HUD fills up with elements nobody can justify,
-- and this pack is rotation-first: if it does not change the next button press,
-- it does not ship.
--
-- The cluster group is a static F.group(), not a dynamic one: a dynamic group
-- ignores child x/y offsets, and the cluster is nothing but concentric children
-- on one centre.
--
-- SIBLING ORDER IS DRAW ORDER, exactly: FixGroupChildrenOrder walks
-- controlledChildren and adds +4 frame levels per child, so EARLIER = further
-- BEHIND. v13 puts THE FACE FIRST, which is the half of the centred-health-number
-- change that is not a coordinate:
--   v12  { Threat, Health, Mana, Portrait, Threat Flash }   face on top
--   v13  { Portrait, Threat, Health, Mana, Threat Flash }   face at the back
-- With the portrait last, it was drawn over everything the rings put in the middle,
-- so moving the health number to y 0 would have looked like nothing happened.
--
-- DRAWING THE RINGS OVER THE FACE HIDES NONE OF IT, because a ring is an ANNULUS.
-- Ring_20px paints a band from 0.84375r to r, so the three arcs occupy radii
-- 42.19..50, 35.44..42 and 26.16..31 while the face is 0..22 — the nearest band
-- still clears the face by 4 px. The only thing that lands on the portrait is the
-- text sub-region, which is the entire point.
--
-- (frameStrata was never the mechanism here: the portrait's frameStrata 2 is
-- BACKGROUND, the lowest strata, so it was ALREADY behind the rings' inherited
-- strata 1. Strata outranks frame level, so this reorder does not change what wins
-- — it makes the frame-level layer say the same thing the strata layer already
-- said, instead of contradicting it. See the portrait factory note above.)
--
-- The halo stays last of all so it pulses OVER the threat ring it shares a radius
-- with rather than under it. sharedFrameLevel is deliberately left off the cluster
-- group — it would set the offset to 0 and make the overlap ambiguous.
-- =====================================================================

-- --- the cluster: three rings and your face, at ABSOLUTE (-270, 40) -----
-- One group, because it is one decision surface: Life Tap trades the health ring
-- for the mana ring, and threat says whether you can afford to keep casting at
-- all. Dragging this group moves everything. The group carries CLUSTER_X and the
-- DERIVED PLAYER_GY; every child sits at a local (0, 0), which is what makes all
-- three rings and the face concentric BY CONSTRUCTION.
local gPlayer = reg(F.group("Warlock - Player Orb", CLUSTER_X, PLAYER_GY, nil))

-- Your face, in the middle of your own rings. It carries the health ring's
-- triggers and guard conditions, so the whole cluster appears, fades out of
-- combat and vanishes as one object.
local pPortrait = reg(portrait("Warlock - Player Portrait", "player",
  { F.healthTrigger(), F.unitCharTrigger() }))
pPortrait.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

-- --- wiring (v13 draw order; no uid moves — uids are assigned at CONSTRUCTION,
--     above, and not one constructor call changed place) -------------------
adopt(gRes, gPlayer)
adopt(gPlayer, pPortrait)   -- the face FIRST, furthest back, so the rings' text
                            -- draws ON it — this is what makes health at y 0 read
adopt(gPlayer, threat)      -- ...then the outermost arc...
adopt(gPlayer, pHealth)     -- ...then health (its number is the centred one)...
adopt(gPlayer, pMana)       -- ...then mana...
adopt(gPlayer, flash)       -- the 80% halo, on the threat ring, over everything

-- ===== assemble (v2000 nested), encode, verify =====
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

-- =====================================================================
-- v12 PROOF, run against the DECODED string rather than the tables above, so
-- what is asserted is what a player actually imports.
--
-- 1. ABSOLUTE POSITIONS. WeakAuras adds xOffset/yOffset all the way down the
--    parent chain, and the cluster hangs three groups deep (top -> Resources ->
--    cluster -> region). A locally correct number is therefore not evidence of
--    anything; only the walked sum is. This is the check the derivation of
--    PLAYER_GY exists to satisfy, and it fails loudly if a later edit types a
--    coordinate onto a group instead of deriving it.
-- 2. CONCENTRICITY. All three rings, the face and the halo must land on the SAME
--    absolute point, or "outermost ring" is just a bigger ring somewhere near by.
-- 3. RING GEOMETRY. The canonical diameters, the circular fill path and the
--    identity crop, asserted per region: a globe-era "VERTICAL" or a crop of 0
--    would still import and still round-trip, and would simply look wrong.
-- 4. THE PORTRAIT IS A REAL LIVE UNIT. modelIsUnit plus BOTH model_fileId and
--    model_path — current WA reads the unit from model_fileId, and the migration
--    that would bridge model_path is gated on IsClassicEra, which is NOT IsTBC,
--    so emitting only model_path is a silent no-op on a 2.5.x client.
-- 5. SUB-REGION SHAPE. The percentage must be subRegions[1] and the ONLY
--    sub-region: sub.N conditions are positional.
--    (This pack ships no resource breakpoint marks — health and mana escalate by
--    colour, not by threshold ticks — so there is no mark to place on a
--    circumference here.)
-- 6. THREAT SURVIVED THE MOVE INTACT: the era-correct threatUnit arg and NOT the
--    IV-51+ `unit`, the party/raid gate, the not-in-an-arena gate, all three
--    escalation steps on `foregroundColor`, and the zero guard LAST.
-- 7. THE ALERT COLUMN STILL CLEARS THE CLUSTER at the widened 100 px radius,
--    with the alert stack PROJECTED SIX CHILDREN DEEP. The column is a dynamic
--    group that grows upward, so a check made with one prompt showing proves
--    nothing about a real pull — which is exactly how an earlier pass shipped an
--    overlap. The projection is vertical, so the horizontal gap is what has to
--    hold, and it is asserted from the decoded widths rather than assumed.
-- 8. THE REMOVALS ARE THE DECLARED ONES, in the string and in the uid stream:
--    the four target-cluster ids are absent, and every uid that disappeared
--    belongs to one of them.
-- 9. (v13) THE NUMBERS ARE WHERE THEY ARE CLAIMED TO BE, AND THE FACE IS AT THE
--    BACK. Both halves are asserted, because either one alone is a no-op: health
--    at anchorYOffset 0 / 16 pt and mana at -54 / 12 pt, AND the portrait as the
--    FIRST entry of the cluster's controlledChildren with all three rings after
--    it. The annulus clearance that makes drawing rings over the face safe is
--    asserted too, from the decoded diameters rather than from the comment above.
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
    ("%s sits at (%d, %d), expected (%d, %d)"):format(id, x, y, ax, ay))
end

-- THE ONE CLUSTER, and everything in it on the same centre. Every id below must
-- land on exactly (-270, 40) — that is what "concentric" means once the geometry
-- is spread across four regions and a group, and it is the assertion that would
-- catch a threat ring that had been given a local offset when it was re-parented.
local CLUSTER = {
  "Warlock - Player Orb",       -- the group
  "Warlock - Threat",           -- 100, outermost (v12)
  "Warlock - Player Health",    -- 84
  "Warlock - Player Mana",      -- 62
  "Warlock - Player Portrait",  -- 44, the face
  "Warlock - Threat Flash",     -- 100, the >=80% halo, ON the threat ring
}
for _, id in ipairs(CLUSTER) do assertAt(id, CLUSTER_X, CLUSTER_Y) end
for _, id in ipairs(CLUSTER) do
  local n = assert(nodes[id])
  if n.regionType ~= "group" then
    assert(n.xOffset == 0 and n.yOffset == 0,
      id .. ": a cluster child must sit at a LOCAL (0, 0)")
  end
end

-- the target cluster is GONE, ids and all
for _, id in ipairs({
  "Warlock - Target Orb", "Warlock - Target Health",
  "Warlock - Target Ring Track", "Warlock - Target Portrait",
}) do
  assert(nodes[id] == nil, id .. " is still in the shipped string")
end

-- every ring: canonical diameter, circular path, identity crop
for _, r in ipairs({
  { id = "Warlock - Threat",        size = THREAT_RING },
  { id = "Warlock - Player Health", size = OUTER },
  { id = "Warlock - Player Mana",   size = INNER },
}) do
  local n = assert(nodes[r.id])
  assert(n.regionType == "progresstexture", r.id .. ": not a progresstexture")
  assert(n.orientation == "CLOCKWISE", r.id .. ": not on the circular fill path")
  assert(n.startAngle == 0 and n.endAngle == 360, r.id .. ": not a full ring")
  assert(n.width == r.size and n.height == r.size,
    ("%s is %sx%s, expected %d"):format(r.id, tostring(n.width), tostring(n.height), r.size))
  assert(n.crop_x == 0.41 and n.crop_y == 0.41, r.id .. ": crop is not the identity value")
  assert(n.backgroundOffset == 0, r.id .. ": track is not concentric with the arc")
  assert(n.foregroundTexture == RING_TEX and n.backgroundTexture == RING_TEX,
    r.id .. ": not drawn with the ring annulus")
  assert(n.auraRotation == 0, r.id .. ": auraRotation must be emitted")
  local subs = n.subRegions
  assert(#subs == 1 and subs[1].type == "subtext",
    r.id .. ": the percentage must be the one and only sub-region")
end

-- the one portrait: a live unit, on both fields, at the canonical face size
do
  local id, unit = "Warlock - Player Portrait", "player"
  local n = assert(nodes[id])
  assert(n.regionType == "model", id .. ": not a model region")
  assert(n.modelIsUnit == true, id .. ": not bound to a unit")
  assert(n.model_fileId == unit, id .. ": model_fileId is not the unit string")
  assert(n.model_path == unit, id .. ": model_path is not the unit string")
  assert(n.portraitZoom == true, id .. ": not framed as a portrait")
  assert(n.width == PORTRAIT and n.height == PORTRAIT, id .. ": wrong face size")
end

-- v13: THE PERCENTAGES, AND THE DRAW ORDER THAT MAKES THE CENTRED ONE VISIBLE.
-- Asserted together and from the DECODED string, because each half is useless
-- without the other: a centred number under an opaque portrait is invisible, and a
-- reordered portrait under a number that is still at -54 changes nothing.
do
  local want = {
    { id = "Warlock - Player Health", sym = "%percenthealth%%", size = PCT_HP,    y = PCT_HP_Y },
    { id = "Warlock - Player Mana",   sym = "%percentpower%%",  size = PCT_POWER, y = PCT_POWER_Y },
    { id = "Warlock - Threat",        sym = "%threatpct%%",     size = PCT_THREAT, y = PCT_THREAT_Y },
  }
  for _, w in ipairs(want) do
    local sub = assert(nodes[w.id].subRegions[1], w.id .. ": no percentage sub-region")
    assert(sub.type == "subtext", w.id .. ": sub-region 1 is not a subtext")
    assert(sub.text_text == w.sym,
      ("%s: text token is %q, expected %q"):format(w.id, tostring(sub.text_text), w.sym))
    assert(sub.text_fontSize == w.size,
      ("%s: font is %s, expected %d"):format(w.id, tostring(sub.text_fontSize), w.size))
    assert(sub.anchorYOffset == w.y,
      ("%s: anchorYOffset is %s, expected %d"):format(w.id, tostring(sub.anchorYOffset), w.y))
    assert(sub.text_anchorPoint == "CENTER", w.id .. ": percentage is not CENTER-anchored")
    -- the readability kit the v13 note promises to keep
    assert(sub.text_fontType == "OUTLINE", w.id .. ": lost its OUTLINE font type")
    assert(sub.text_shadowColor and sub.text_shadowXOffset == 0 and sub.text_shadowYOffset == 0,
      w.id .. ": lost its shadow settings")
  end
  -- the health number is the one in the middle, and it is the only one there
  assert(PCT_HP_Y == 0, "the health percentage is not at the cluster's centre")
  assert(PCT_POWER_Y ~= 0 and PCT_THREAT_Y ~= 0,
    "two numbers are stacked on the same centre point")

  -- DRAW ORDER: the face first (furthest back), every ring after it.
  local cc = assert(nodes["Warlock - Player Orb"].controlledChildren)
  assert(cc[1] == "Warlock - Player Portrait",
    ("the portrait must be the FIRST cluster child, but child 1 is %q — with it later "
      .. "it draws OVER the centred health number"):format(tostring(cc[1])))
  local ringsAfter = 0
  for i = 2, #cc do
    if nodes[cc[i]].regionType == "progresstexture" then ringsAfter = ringsAfter + 1 end
  end
  assert(ringsAfter == 3,
    ("only %d of 3 rings are drawn after the portrait"):format(ringsAfter))
  -- ...and the flat c-list agrees with it, depth-first (F.assemble derives it from
  -- controlledChildren, so this catches a hand-edit that desynchronised the two).
  local order = {}
  for _, ch in ipairs(back.c) do
    if ch.parent == "Warlock - Player Orb" then order[#order + 1] = ch.id end
  end
  assert(#order == #cc, "cluster c-list and controlledChildren differ in length")
  for i = 1, #cc do
    assert(order[i] == cc[i],
      ("c-list is out of step with controlledChildren at %d: %q vs %q")
        :format(i, tostring(order[i]), tostring(cc[i])))
  end

  -- WHY DRAWING RINGS OVER THE FACE IS SAFE: Ring_20px is an annulus whose band
  -- runs 0.84375r..r, so the innermost band must still clear the portrait radius.
  local BAND = 1 - 40 / 256   -- inner radius as a fraction of the outer
  local face = nodes["Warlock - Player Portrait"].width / 2
  local tightest = math.huge
  for _, id in ipairs({ "Warlock - Threat", "Warlock - Player Health", "Warlock - Player Mana" }) do
    tightest = math.min(tightest, nodes[id].width / 2 * BAND)
  end
  assert(tightest > face,
    ("the innermost ring band starts at r=%.2f and the face ends at r=%.2f — a ring "
      .. "drawn over the portrait would cover it"):format(tightest, face))
  print(("v13 layout: health %d pt @ y=%d (centre, over the %d px face), mana %d pt @ y=%d, "
    .. "threat %d pt @ y=%d"):format(PCT_HP, PCT_HP_Y, face * 2, PCT_POWER, PCT_POWER_Y,
      PCT_THREAT, PCT_THREAT_Y))
  print(("  draw order: %s"):format(table.concat(cc, " -> ")))
  print(("  annulus clearance: innermost band r=%.2f vs face r=%.2f (%.2f px clear)")
    :format(tightest, face, tightest - face))
end

-- the halo pulses ON the threat ring, at the same diameter, with the same gates
do
  local n = assert(nodes["Warlock - Threat Flash"])
  assert(n.width == FLASH_RING and n.height == FLASH_RING and FLASH_RING == THREAT_RING,
    "threat flash: not on the threat ring's diameter")
  assert(n.texture == RING_TEX, "threat flash: not the ring annulus")
  assert(n.animation.main.preset == "alphaPulse", "threat flash: lost its pulse")
end

-- THREAT KEPT EVERYTHING. The trigger's unit arg, both load gates, all three
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
  assert(c[1].check.variable == "threatpct" and c[2].check.variable == "aggro",
    "threat: escalation steps are not green -> orange(70) -> red(aggro)")
  local last = c[#c]
  assert(last.check.variable == "threatvalue" and last.check.op == "<="
    and last.check.value == "0" and last.changes[1].property == "alpha"
    and last.changes[1].value == 0,
    "threat: the mandatory zero guard is missing or is not the LAST condition")
  local sub = assert(nodes["Warlock - Threat"].subRegions[1])
  assert(sub.text_fontSize == PCT_THREAT and sub.text_anchorPoint == "CENTER"
    and sub.anchorYOffset == PCT_THREAT_Y,
    "threat: the percentage is not 10 pt CENTER at +58")
end

-- THE ALERT COLUMN, PROJECTED SIX DEEP. Both are dynamic-group facts read out of
-- the decoded string: the column grows vertically, so its stack depth never moves
-- it sideways, and the horizontal gap is the whole of the clearance. Widths come
-- from the widest child actually shipped, not from a remembered number.
do
  local alerts = assert(nodes["Warlock - Alerts"])
  local ax, ay = absPos("Warlock - Alerts")
  local widest, tallest, kids = 0, 0, 0
  for _, cid in ipairs(alerts.controlledChildren) do
    local ch = assert(nodes[cid])
    widest  = math.max(widest, ch.width or 0)
    tallest = math.max(tallest, ch.height or 0)
    kids = kids + 1
  end
  assert(alerts.regionType == "dynamicgroup" and alerts.grow == "UP",
    "alerts: no longer an upward dynamic group — re-derive this clearance")
  local DEPTH = 6
  local stackTop = ay + DEPTH * tallest + (DEPTH - 1) * alerts.space
  local alertLeft = ax - widest / 2
  local clusterRight = CLUSTER_X + THREAT_RING / 2
  local gap = alertLeft - clusterRight
  assert(gap > 0, ("the %d px threat ring reaches x %d and the alert column starts at x %d")
    :format(THREAT_RING, clusterRight, alertLeft))
  -- The stack DOES climb past the cluster vertically (that is the point of
  -- projecting it), so record both numbers rather than only the happy one.
  print(("alert clearance: cluster right edge x=%d, alert column left edge x=%d, gap=%d px")
    :format(clusterRight, alertLeft, gap))
  print(("  alert stack %d deep (%d children shipped, %dx%d icons, space %d): y %d -> %d, "
    .. "cluster y %d -> %d — vertical overlap, horizontal gap is the clearance")
    :format(DEPTH, kids, widest, tallest, alerts.space, ay, stackTop,
      CLUSTER_Y - THREAT_RING / 2, CLUSTER_Y + THREAT_RING / 2))
end

-- uid continuity vs the previous on-disk version (checked BEFORE overwriting, so
-- re-running after any future edit compares against the shipped string).
--
-- v13 PASSES NO ALLOWANCE, and that is the point. v12 handed over a licence for
-- four deliberate removals; a licence that stays open outlives the deletion it was
-- written for and quietly permits the next one. It expires at the version bump —
-- exactly as tools/verify-packs.lua treats the `-- WA-REMOVED (vN):` tags, which it
-- honours only when the tag matches the version the pack currently ships. Those
-- four tags stay above as lineage and are now inert on both sides. v13 removes
-- nothing, so it is back on the default contract: no uid may disappear, full stop.
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
