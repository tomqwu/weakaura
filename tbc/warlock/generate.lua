-- generate.lua — Warlock TBC All-Specs HUD (v16).
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
-- THE SILL — CANONICAL RAIL GEOMETRY, SHARED BY ALL SEVEN CLASS PACKS (v14)
--
-- Declared as named constants so a later edit has to notice it is breaking a
-- shared contract. Every number here is fixed repo-wide, exactly as the ring
-- diameters were from v11 to v13: seven packs given a design intent instead of
-- dimensions is what produced "the orbs do not match" in v7.
-- DO NOT retune, scale or "improve" any of them in one pack.
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

-- ONE PIXEL IS ONE PERCENT. 100 px is the exact length at which a 0-100 gauge is
-- lossless: longer re-draws states the eye cannot separate, shorter discards them.
-- It is also what makes every breakpoint arithmetic — see MARK below.
local RAIL_LEN      = 100  -- every rail, every pack
local RAIL_H        = 11   -- health and power: tall enough for an 11 pt number
local RAIL_THREAT_H = 4    -- threat is a warning, not a quantity you spend
local PLATE_W       = 102  -- 1 px of plate each side of a 100 px rail
local PLATE_H       = 31   -- warlock has NO discrete resource -> no lane 4 -> 31
local PLATE_Y       = 3    -- local; keeps the plate's TOP edge on the shared line

-- THE ALARM RIM. Square_White_Border is FILLED (see the measurement above), so a
-- region on it cannot draw an outline — it can only be BIGGER than the thing that
-- covers it. The alarm is therefore the plate grown by RIM on every side and drawn
-- FIRST, at the bottom of the stack: the RIM-wide band that protrudes past the
-- plate is the only part that ever reaches the eye, and the rest sits behind a
-- 45%-black plate and behind every rail, number and mark. This construction is
-- correct whether the art turns out to be filled or hollow, which is why it is the
-- one to build. Same rim as the sibling rogue pack, so the strip reads identically.
local RIM              = 3                        -- per side
local ALARM_W, ALARM_H = PLATE_W + 2 * RIM, PLATE_H + 2 * RIM   -- 108 x 37

-- Lane offsets, LOCAL to the sill group and identical in all seven packs, so the
-- three rails land in the same place on every character:
--   4 + 1 + 11 + 1 + 11 = 28 px of content, local +17.5 .. -10.5
--   plate 31 tall at +3 -> local +18.5 .. -12.5 (1 px above, 2 px below)
local LANE_THREAT = 15.5
local LANE_HEALTH = 7
local LANE_POWER  = -5

-- THE BREAKPOINT FORMULA, and the reason the rails are 100 px:
--     x(v) = (v / maxpower - 0.5) * RAIL_LEN
-- which for a 0-100 gauge collapses to x = v - 50. The 70% threat notch is at
-- x = +20 and that is the whole calculation. Compare the ring era, which needed
-- r = size/2 * 0.94; x = r*sin(2*pi*f); y = r*cos(2*pi*f) and landed the rogue
-- pack's 35-energy mark on (23.575, -17.128).
-- NOTE (gotchas.md): a talent that raises the CAP — Vigor's energy 100 -> 110 —
-- moves every mark, because the constant is baked at build time. A warlock's mana
-- rail reads PERCENT, so it is immune; the notch below is a threat percentage and
-- is likewise capless.
-- rounded to 1/1000 px: (70/100 - 0.5) * 100 is 19.999999999999996 in IEEE754, and
-- a coordinate that is "20 to fifteen decimal places" is a coordinate that fails
-- every equality assertion written about it.
local function markX(v, maxv)
  local x = (v / (maxv or 100) - 0.5) * RAIL_LEN
  return math.floor(x * 1000 + 0.5) / 1000
end
local NOTCH_THREAT = markX(70)   -- +20: where this pack has always gone orange

-- The numbers live INSIDE their own rail, at its right-hand end, on the plate.
-- text_anchorPoint stays "CENTER" (the value this repo has proven on a
-- progresstexture) and the offset does the work: two digits at 11 pt are ~14 px
-- wide, so +32 spans x +25..+39 and three digits x +21.5..+42.5 — still 7.5 px
-- inside the rail's right edge. INNER_RIGHT is proven on aurabars and icons only,
-- so it is deliberately not used here.
local PCT_SIZE = 11
local PCT_X    = 32
local PCT_Y    = 0

-- THE RULER. Three hairlines per 11 px rail at the quarter lines, 18% white:
-- 33 px of ink, zero footprint, and it converts the rail from "estimate a
-- fraction" into "count quarters".
local RULER_X   = { -25, 0, 25 }
local RULER_W   = 1
local RULER_COL = { 1, 1, 1, 0.18 }
local NOTCH_W   = 2                        -- the threat rail's single 70% mark
local NOTCH_COL = { 1, 1, 1, 0.85 }

-- The threat NUMBER is switched off, not deleted: its sub-region index is
-- preserved (sub.N refs are positional) and a player can tick it back on in /wa.
-- threatpct is scaled so 100 = pulling aggro, which makes it an early-warning
-- ratio rather than a quantity you spend — a fill crossing the notch answers it
-- faster than reading a two-digit number and comparing it to a remembered 70.
local PCT_THREAT     = 10     -- pt, unchanged from v13
local PCT_THREAT_Y   = 58     -- unchanged from v13; inert while text_visible=false
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
-- A 102x37 rectangle centred on -110 clears the first by 11.5 px and the second by
-- 7.5 px, and is the widest-margin position that scans clean in all seven packs
-- with dynamic groups projected six children deep. The full rectangle scan is
-- ASSERTED at the bottom of this file against the decoded string, because "it
-- looked fine with one alert up" is exactly how an earlier pass shipped an overlap.
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
-- Resources — v14: THE SILL, a 102 x 31 instrument strip under the character.
--
-- A ring encodes a value as ARC LENGTH around a hoop. A rail encodes it as a
-- LENGTH along a line, and at exactly 100 px that length IS the percentage: one
-- pixel, one percent, no scaling in either direction. Same WeakAuras region type
-- as the rings, one different field:
--
--   orientation = "HORIZONTAL"  -- Private.orientation_with_circle_types:
--     HORIZONTAL = "Left to Right",  HORIZONTAL        = "Right to Left",
--     VERTICAL           = "Bottom to Top",  VERTICAL_INVERSE  = "Top to Bottom",
--     CLOCKWISE / ANTICLOCKWISE = the two RADIAL values (v11-v13 used CLOCKWISE)
--
-- The name lies about direction in the usual WeakAuras way, exactly as the
-- aurabar's VERTICAL does (gotchas.md) — and note the two region types disagree:
-- on an AURABAR, HORIZONTAL is anchored left and grows right; on a
-- PROGRESSTEXTURE, HORIZONTAL is "Right to Left" and the left-to-right value is
-- HORIZONTAL. Getting it backwards gives a rail that empties from the
-- left, which looks deliberate and is wrong. This is the ONE field in the redesign
-- that no committed string in this repo has rendered — v9/v10 shipped the sibling
-- linear value VERTICAL in poc/diablo-globes — so it is the one thing to eyeball
-- on a live client: at ~50% the EMPTY half must be on the RIGHT.
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
--     is why a 100 x 11 rail can use the same 0.41 a 100 x 100 ring used.
--   * auraRotation = 0 is absent from the 3.5.0 default table but read
--     unconditionally as data.auraRotation / 180 * math.pi, so it must be emitted.
--   * backgroundColor is the UNFILLED part of the rail and backgroundOffset = 0
--     keeps that track exactly the same rectangle as the fill rather than a fatter
--     halo around it.
--
-- LAYOUT (v14 — ONE strip, ABSOLUTE screen coordinates), local offsets in
-- brackets and identical in all seven packs:
--   sill group  (0, -110)   under the character, in the free band the whole repo
--                           leaves between the buff rows
--   listed in DRAW ORDER, which IS controlledChildren order:
--     Alarm rim     108 x 37  [0, +3]     the >=80% threat pulse, ADD, drawn FIRST;
--                                         3 px larger per side than the plate, so
--                                         only that band is ever visible
--     Sill Plate    102 x 31  [0, +3]     the dark ledge everything reads against
--     Threat rail   100 x  4  [0, +15.5]  your share of the pull threshold
--     Health rail   100 x 11  [0, +7]     %percenthealth%% inside it at x +32
--     Power rail    100 x 11  [0, -5]     %percentpower%%  inside it at x +32
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
-- not a coordinate one. A dark bordered rectangle behind an 11 px rail and an
-- 11 pt number is what makes them survive a snowfield, a fire and Shattrath at
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
-- A RAIL. Every rail in the strip is 100 px long, sits at x = 0 and inherits its
-- x from the sill group; only `h` and the lane `y` differ. `trigs` is the trigger
-- list; trigger 1 always supplies the fill (see the Automatic-progress note
-- above). The whole point of the shape is that 100 px = 100%, so a rail never
-- needs a scale factor and every mark on it is `x = v - 50`.
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
-- the same local offset: the plate 102 x 31 in near black at 45%, the alarm
-- 108 x 37 — RIM px larger on every side — in red at 85% with ADD blending. The
-- alarm is drawn FIRST and the plate second, so the stack reads
--     alarm rim -> plate -> threat -> health -> power
-- and the only part of the alarm that is ever visible is the 3 px band sticking out
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

-- The quarter ruler: three 1 px hairlines at x -25 / 0 / +25 on an 11 px rail.
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
-- Threat is YOUR threat, so it sits on YOUR instrument: 4 px tall at the top of
-- the strip, green -> orange at 70% -> red on aggro, most severe last, exactly as
-- the bar, the rim and the ring before it escalated. 4 px because threat is a
-- WARNING, not a quantity you spend — you never need to read it to a percent, you
-- need to know whether the fill has reached the notch.
-- THE NOTCH IS THE READOUT (v14). sub.2 is a 2 px waterline at x = 70 - 50 = +20:
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
-- v12 a halo ON the threat ring. v14 makes it the STRIP'S OWN EDGE: a 108x37
-- Square_White_Border box concentric with the 102x31 plate, drawn FIRST, so a 3 px
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
-- the readouts at exactly the moment they have to be read. Ship it 3 px larger on
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
-- v14 PROOF, run against the DECODED string rather than the tables above, so
-- what is asserted is what a player actually imports. This block is the RAIL
-- CANON — the direct replacement for v11-v13's ring canon (orientation ==
-- "CLOCKWISE", width == height == <diameter>, foregroundTexture == RING_TEX,
-- exact sub-region counts). It is rewritten, not deleted: these assertions are
-- the reason a geometry change in this repo has never silently shipped wrong,
-- and every one of them would have caught a real mistake made while writing v14.
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
--     exactly 1 px; and the plate's margins exactly 1 px above / 2 px below.
--     Asserted from decoded widths and heights, so "102 x 31" is a measurement
--     rather than a comment.
--  3. RAIL CANON. progresstexture on the LINEAR path (HORIZONTAL, which
--     is WeakAuras for "Left to Right"), 100 px long — the length at which one
--     pixel is one percent — and explicitly NOT square, because square is what
--     every progresstexture in this repo was until v14 and a copied ring is the
--     easiest way to regress. Square_White on both fill and track, backgroundOffset
--     0, crop 0.41, auraRotation emitted, and Automatic progress plumbing.
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
--  6. THE NUMBERS ARE WHERE THEY ARE CLAIMED TO BE: 11 pt, CENTER-anchored, at
--     anchorXOffset +32 inside their own rail, with the OUTLINE font type and the
--     shadow that make them survive the game world behind them.
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
--     plate.width + 6, alarm.height == plate.height + 6, same centre, cc[1] ==
--     alarm and cc[2] == plate. Square_White_Border.tga is FILLED (64,516 of
--     65,536 pixels at alpha 255; nothing 8 px in from the edge below alpha 255 or
--     RGB 167), so a same-size or top-of-stack alarm is a full-area red wash over
--     every readout. Drop either half of the pin and the rim silently becomes that
--     wash — which is exactly the bug this construction repairs.
-- 10. DRAW ORDER: the alarm rim FIRST (a filled ADD quad anywhere else washes
--     everything under it), the plate SECOND (at 45% alpha it is not opaque, but it
--     is the surface the rails are painted on, and it is what hides all of the
--     alarm except its 3 px band), all three rails ABOVE both, and the flat c-list
--     depth-first in the same order, because for v = 2000 the two must agree.
-- 11. THE RECTANGLE SCAN. The strip's bounding box against EVERY other element in
--     the pack, with dynamic groups projected six children deep — the alert
--     column, the PvP column and the cooldown row all grow, so a check made with
--     one prompt showing proves nothing about a real pull, which is exactly how an
--     earlier pass shipped an overlap. Zero overlaps, and the two clearances that
--     define the free band are printed rather than assumed. It also asserts the
--     strip lies INSIDE the free band (y -136 .. -80) — an INDEPENDENT check on
--     the absolute y, because a pack-local overlap scan says nothing about the
--     fleet: -21 collides with nothing in THIS pack and is still wrong, since it
--     is the character's waist and leaves 0.5 px to two other packs' buff rows.
-- 12. THE REMOVALS ARE STILL THE DECLARED ONES: the four v12 target-cluster ids
--     are absent, and v14 removes nothing further.
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
-- and the ruler's ink budget (block 5). Those four come from the geometry itself,
-- not from a number typed anywhere.
local C = {
  -- ABSOLUTE PLACEMENT. -110 is under the character, inside the band this repo
  -- leaves free in every pack: paladin's and hunter's buff rows sit at y -80..-40
  -- and the other five packs' at y -176..-136 (in THIS pack that is the DoT row
  -- at y -156, spanning -176..-136).
  absX = 0, absY = -110,
  bandTop = -80, bandBottom = -136,      -- the free band, from those two rows
  -- THE PARENT CHAIN, each link typed once and independently. The sill group
  -- carries the DERIVED local offset; the absolute is what the player sees.
  topY = -140, resY = 56, sillGY = -26,
  -- THE PLATE AND THE LANE STACK, local to the sill group.
  plateW = 102, plateH = 31, plateY = 3,
  -- THE ALARM RIM, typed as its own literals so the +6 relation below is checked
  -- against two independently written numbers rather than against itself. 3 px per
  -- side is the only thing that ever draws: Square_White_Border.tga is filled
  -- (98.44% of its pixels are alpha 255), so the alarm can only read as an edge by
  -- being larger than the plate AND drawn under it.
  rim = 3, alarmW = 108, alarmH = 37,
  marginAbove = 1, marginBelow = 2, laneGap = 1,
  laneThreat = 15.5, laneHealth = 7, lanePower = -5,
  -- THE RAILS. 100 px because one pixel is one percent.
  railLen = 100, railH = 11, railThreatH = 4,
  -- THE NUMBERS AND THE MARKS.
  pctSize = 11, pctX = 32, pctY = 0, pctThreatSize = 10,
  rulerX = { -25, 0, 25 }, rulerW = 1, rulerAlpha = 0.18,
  notchX = 20, notchW = 2,
}

-- the arithmetic OF the contract, on terms that were each typed separately: if
-- any one of the four is edited alone, the chain stops adding up.
assert(C.absY == C.sillGY + C.topY + C.resY,
  ("the parent chain does not reach the absolute target: %g + %g + %g = %g, not %g")
    :format(C.sillGY, C.topY, C.resY, C.sillGY + C.topY + C.resY, C.absY))
assert(C.plateH == C.railThreatH + C.laneGap + C.railH + C.laneGap + C.railH
  + C.marginAbove + C.marginBelow,
  ("the lane stack does not fill the plate: %g + %g + %g + %g + %g margins = %g, "
    .. "but the plate is %g tall"):format(C.railThreatH, C.laneGap, C.railH, C.laneGap,
    C.railH, C.railThreatH + 2 * C.laneGap + 2 * C.railH + C.marginAbove + C.marginBelow,
    C.plateH))
assert(C.plateW == C.railLen + 2, "the plate must overhang each rail end by exactly 1 px")
-- THE RIM ARITHMETIC. alarmW/alarmH/rim/plateW/plateH are five separately typed
-- literals; edit any one alone and this stops the build by name.
assert(C.alarmW == C.plateW + 2 * C.rim and C.alarmH == C.plateH + 2 * C.rim,
  ("the alarm contract is %gx%g, but a %g px rim around a %gx%g plate is %gx%g")
    :format(C.alarmW, C.alarmH, C.rim, C.plateW, C.plateH,
      C.plateW + 2 * C.rim, C.plateH + 2 * C.rim))
assert(C.alarmW - C.plateW == 6 and C.alarmH - C.plateH == 6,
  "the alarm must be exactly 6 px larger than the plate in BOTH axes (3 px per side)")
assert(C.rim > 0, "a rim of zero px is a same-size ADD quad, i.e. a full-area wash")
assert(C.laneThreat - C.railThreatH / 2 - (C.laneHealth + C.railH / 2) == C.laneGap
  and C.laneHealth - C.railH / 2 - (C.lanePower + C.railH / 2) == C.laneGap,
  "the three lane offsets do not leave the contract's gap between the rails")

-- the BUILD CONSTANTS, checked against it. This is the pair of eyes the old block
-- did not have: change one of these alone and the build stops here by name.
for _, b in ipairs({
  { "SILL_X", SILL_X, C.absX },          { "SILL_Y", SILL_Y, C.absY },
  { "TOP_Y", TOP_Y, C.topY },            { "RES_Y", RES_Y, C.resY },
  { "PLAYER_GX", PLAYER_GX, C.absX },    { "PLAYER_GY", PLAYER_GY, C.sillGY },
  { "PLATE_W", PLATE_W, C.plateW },      { "PLATE_H", PLATE_H, C.plateH },
  { "PLATE_Y", PLATE_Y, C.plateY },
  { "RIM", RIM, C.rim },
  { "ALARM_W", ALARM_W, C.alarmW },      { "ALARM_H", ALARM_H, C.alarmH },
  { "LANE_THREAT", LANE_THREAT, C.laneThreat },
  { "LANE_HEALTH", LANE_HEALTH, C.laneHealth },
  { "LANE_POWER", LANE_POWER, C.lanePower },
  { "RAIL_LEN", RAIL_LEN, C.railLen },   { "RAIL_H", RAIL_H, C.railH },
  { "RAIL_THREAT_H", RAIL_THREAT_H, C.railThreatH },
  { "PCT_SIZE", PCT_SIZE, C.pctSize },   { "PCT_X", PCT_X, C.pctX },
  { "PCT_Y", PCT_Y, C.pctY },            { "PCT_THREAT", PCT_THREAT, C.pctThreatSize },
  { "RULER_W", RULER_W, C.rulerW },      { "NOTCH_W", NOTCH_W, C.notchW },
  { "NOTCH_THREAT", NOTCH_THREAT, C.notchX },
}) do
  assert(b[2] == b[3],
    ("the build constant %s is %s but the design contract says %s — retuning the "
      .. "Sill means editing BOTH, on purpose, not one of them by accident")
      :format(b[1], tostring(b[2]), tostring(b[3])))
end
assert(#RULER_X == #C.rulerX, "the ruler no longer has the contract's number of lines")
for i, x in ipairs(C.rulerX) do
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
-- LANE_THREAT 15.5 -> 14 overlaps the threat and health rails by 0.5 px while
-- every containment test still passes — a 4 px warning bar quietly eating the top
-- half-pixel of the number rail underneath it.
do
  local plate = assert(nodes["Warlock - Sill Plate"])
  assert(plate.width == C.plateW and plate.height == C.plateH,
    ("the plate is %sx%s, expected %dx%d"):format(tostring(plate.width),
      tostring(plate.height), C.plateW, C.plateH))
  assert(plate.width == C.railLen + 2,
    ("the plate is %s wide; it must overhang each end of a %d px rail by exactly 1 px")
      :format(tostring(plate.width), C.railLen))

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
      .. "(31 tall is the NO-LANE-4 variant this pack ships; 37 is the variant with "
      .. "a class-resource lane, which a warlock does not have)")
      :format(plateTop - top_, bottom - plateBottom, C.marginAbove, C.marginBelow))
  print(("v14 sill: plate %dx%d at absolute (%d, %g); rails span local %g..%g "
    .. "(%g px above, %g px below, %g px between lanes)"):format(C.plateW, C.plateH,
      C.absX, C.absY + C.plateY, bottom, top_, plateTop - top_, bottom - plateBottom,
      C.laneGap))
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
    r.id .. ": not on the LINEAR left-to-right fill path (HORIZONTAL is Right to Left)")
  assert(n.width == C.railLen,
    ("%s is %s px long, and one pixel is one percent only at %d")
      :format(r.id, tostring(n.width), C.railLen))
  assert(n.height == r.h,
    ("%s is %s tall, expected %d"):format(r.id, tostring(n.height), r.h))
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
    assert(sub.anchorXOffset == C.pctX and sub.anchorYOffset == C.pctY,
      ("%s: the number sits at (%s, %s), expected (%d, %d) — inside its own rail")
        :format(w.id, tostring(sub.anchorXOffset), tostring(sub.anchorYOffset), C.pctX, C.pctY))
    assert(sub.text_anchorPoint == "CENTER",
      w.id .. ": percentage is not CENTER-anchored (INNER_RIGHT is unproven here)")
    assert(sub.text_visible == true, w.id .. ": its number is switched off")
    -- the readability kit the design leans on, now that the number is 11 pt
    assert(sub.text_fontType == "OUTLINE", w.id .. ": lost its OUTLINE font type")
    assert(sub.text_shadowColor and sub.text_shadowXOffset == 0 and sub.text_shadowYOffset == 0,
      w.id .. ": lost its shadow settings")
    -- the number must fit inside its own rail: 3 digits at 11 pt is ~21 px wide
    assert(C.pctX + 21 / 2 <= C.railLen / 2,
      w.id .. ": three digits would overrun the right-hand end of the rail")
  end

  -- the threat number: still at sub.1, still 10 pt, switched OFF
  local th = assert(nodes["Warlock - Threat"].subRegions[1])
  assert(th.type == "subtext" and th.text_text == "%threatpct%%",
    "threat: sub.1 is no longer the threat percentage")
  assert(th.text_fontSize == C.pctThreatSize, "threat: the (hidden) number changed size")
  assert(th.text_visible == false,
    "threat: the number must be switched OFF, not left on top of a 4 px rail")

  -- the 70% notch, and the quarter rulers, all APPENDED after sub.1
  local notch = assert(nodes["Warlock - Threat"].subRegions[2])
  assert(notch.type == "subtexture" and notch.textureVisible == true,
    "threat: sub.2 is not a visible mark")
  assert(notch.xOffset == C.notchX,
    ("threat notch is at x %s, but 70%% of a %d px rail is x +%d")
      :format(tostring(notch.xOffset), C.railLen, C.notchX))
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
  -- design says "hairlines". Three lines at 1 px is 3% of the rail; at 3 px each
  -- it is 9%, and a mark wide enough to be mistaken for a segment of the fill has
  -- stopped being a scale and started lying about the value.
  assert(#C.rulerX * C.rulerW * 100 <= C.railLen * 3,
    ("the ruler spends %g px of a %d px rail; hairlines must stay under 3%%")
      :format(#C.rulerX * C.rulerW, C.railLen))
  -- and the formula they all come from, checked rather than trusted
  assert(markX(0) == -C.railLen / 2 and markX(100) == C.railLen / 2 and markX(50) == 0,
    "the breakpoint formula no longer maps 0/50/100 onto the ends and the middle")
  assert(markX(70) == C.notchX,
    ("the 70%% mark computes to x %s; the contract's notch is at +%d")
      :format(tostring(markX(70)), C.notchX))
end

-- 9. THE PLATE AND THE ALARM RIM: two CONCENTRIC boxes on the same filled file,
-- the alarm 6 px larger in both axes, with explicit colours.
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
  -- the plate (6 px in both axes, 3 px per side) and to be drawn UNDER it (child
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
  assert(n.width - plate.width == 6 and n.height - plate.height == 6,
    ("the alarm must be exactly 6 px larger than the plate in BOTH axes; it is "
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

-- 12. the v12 target cluster is still GONE, ids and all, and v14 adds no removals
for _, id in ipairs({
  "Warlock - Target Orb", "Warlock - Target Health",
  "Warlock - Target Ring Track", "Warlock - Target Portrait",
}) do
  assert(nodes[id] == nil, id .. " is still in the shipped string")
end

-- 10. DRAW ORDER: alarm rim first, plate second, the three rails on top of both,
-- and the flat c-list agreeing. v13 listed the portrait first and the ring HALO
-- last, which was right for an annulus with a hole in it; v14's alarm is a FILLED
-- quad, so it moves to the bottom and grows 3 px per side instead. Every readout
-- must draw ABOVE both boxes.
do
  local cc = assert(nodes["Warlock - Player Sill"].controlledChildren)
  assert(cc[1] == "Warlock - Threat Flash",
    ("the alarm rim must be the FIRST child, but child 1 is %q — it is a FILLED "
      .. "quad on ADD blend, so anywhere later it washes out every rail, both "
      .. "numbers, the notch and the ruler"):format(tostring(cc[1])))
  assert(cc[2] == "Warlock - Sill Plate",
    ("the plate must be the SECOND child, but child 2 is %q — it is what covers "
      .. "all of the alarm except its 3 px rim, and it is a FILLED rectangle at "
      .. "45%% black, so anywhere later it greys out every rail and both numbers")
      :format(tostring(cc[2])))
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
-- tallest thing the strip ever draws (108 x 37 against the plate's 102 x 31), and it
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
