-- tbc/mage/generate.lua — Mage "Arcane & Frost" HUD v15.
-- Run: lua5.1 tbc/mage/generate.lua   (toolkit libs live in tools/tbc-weakaura-creator/scripts/)
-- Produces all-specs.txt: a "!WA:2!" string importable in game (internalVersion 45).
--
-- Every spell id below was verified on wowhead.com/tbc (re-checked 2026-08-11), ids
-- only, never names (zhCN-safe): aura triggers carry ALL ranks as strings, cooldown
-- triggers carry the numeric rank-1 id. NB the classic->TBC id swap:
--   TBC Cold Snap = 11958 (8 min CD), TBC Ice Block = 45438 (5 min CD).
--
-- v2 (rotation review fixes): mana conserve breakpoint on the mana bar, Arcane Power /
-- Icy Veins burn-window timers, a mana gem prompt, an Ice Lance shatter prompt, Cold Snap
-- turned into a sequencing prompt instead of a use-on-cooldown icon, threat bar gated to
-- party/raid, Clearcasting gated to combat, spell-known gates on every cooldown icon.
-- UID stream is append-only: no existing W.uid() call moved, so re-import offers Update.
--
-- v3 (per-spec audit — gating only, no element added or removed, no uid moved): the
-- question changed from "can this spec CAST it" to "does this spec PRESS it as part of
-- playing well". Three elements failed that test somewhere:
--   * the mana conserve breakpoint (line + lit marker) encodes Arcane's burn/conserve
--     switch — Frost has no second rotation to switch into, so it is now Arcane-only;
--   * the Ice Lance SHATTER prompt is hidden from deep Arcane (inverse gate), whose
--     guides state outright that the spec does not use Ice Lance or shatter combos;
--   * the Evocation prompt gained its own spell-known gate so it stops firing for
--     mages below level 20, who do not have the button it asks for.
-- Everything else survived the audit unchanged: both specs press Icy Veins, Cold Snap
-- (Arcane IV spends 21 Frost points precisely for Icy Veins + Cold Snap), Evocation,
-- mana gems, Clearcasting (both raid builds take Arcane Concentration), Counterspell,
-- Blink, Invisibility and Ice Block, and every spec-specific piece was already gated on
-- the ability that defines it.
--
-- v4 (PvP layer — nine NEW auras, no existing aura touched): a second HUD that exists only
-- inside arenas and battlegrounds. Every one of the nine carries its own Instance Size Type
-- load gate (arena + battleground, or arena alone where it reads arena1..arena5), so a raid
-- or dungeon mage sees byte-for-byte the v3 HUD. One new dynamic group, "Mage - PvP", holds
-- the state read-outs opposite the Alerts column; three new prompts join the Alerts flow.
-- No custom code: every composite is a multi-trigger AND, an OR (disjunctive "any"), or a
-- condition. What is NOT in it — diminishing returns, enemy cooldown reads, enemy spec,
-- "only interruptible casts" — is listed with its reason at the top of the v4 section.
--
-- v5 (source verification closed two v4 unknowns; ONE new aura, no existing aura's uid moved):
--   * the threat bar and the threat flash now carry the inverse instance-size gate, so they
--     no longer load in arena, where there is no threat table at all. v4 left them alone
--     because the open-world value of `size` was unconfirmed; it is the literal string
--     "none" (WeakAuras.lua GetInstanceTypeAndSize ends `return "none", "none", nil, nil, 0`
--     for the not-in-an-instance case), so enumerating the complement is safe outdoors.
--   * NEW: "Mage - Enemy Mana", one bar per mana-using arena opponent. The Power prototype's
--     unit arg accepts `arena` on TBC (the deletion of arena from actual_unit_types_cast is
--     inside `if WeakAuras.IsClassicEra()`, not TBC), registers UNIT_POWER_FREQUENT per
--     arena1..5, and clones on statesParameter = "unit".
--   * CC ON ME's nine `sub.1.glowColor` conditions were re-verified against the shipped
--     string and the WA source and are LIVE — no change. The trap they avoid: SetGlowColor
--     only stores the colour, and SetVisible forwards it to LibCustomGlow only when
--     useGlowColor is true, so a subglow built WITHOUT a colour makes every glowColor
--     condition a silent no-op. F.subglow(on, color) sets useGlowColor whenever a colour is
--     passed, and this aura's subglow is subRegions[1], which is what "sub.1" resolves to.

-- v6 (the cooldown row shows what you CANNOT press; NO new aura, no uid moved, nothing
-- removed — only genericShowOn and the desaturate condition on six existing icons change):
-- the default row was inverted. Ten icons sat on screen permanently and merely dimmed when
-- down, so the row was busiest exactly when the mage had fewest options — and a mage knows
-- their own spellbook. What they cannot know is what is unavailable and for how long. Every
-- icon in the row was therefore classified, ability by ability, against
-- references/rotation-design.md's "Show what the player CANNOT press":
--   * PRESS-ON-COOLDOWN (stay showAlways, keep the ready-glow — a hidden icon can never fire
--     one, and hiding the button you press most trades "press this now" for "you cannot"):
--     Arcane Power, Icy Veins, Summon Water Elemental. These are the damage cooldowns both
--     raid builds press the moment they come up (icy-veins.com/tbc-classic states Frost's
--     rotation as "use Icy Veins and Summon Water Elemental when possible, and cast
--     Frostbolt"; Arcane opens its burn phase with AP + IV stacked), and all three have
--     glowed gold in combat since v2. Cold Snap keeps showAlways for a structural reason:
--     its glow is a SEQUENCING instruction (it fires only once both cooldowns it resets have
--     been spent), which is the one moment pressing an 8 min reset is correct — and that
--     moment cannot be announced by an icon that is hidden while the ability is ready.
--   * SITUATIONAL (now genericShowOn = "showOnCooldown"): Presence of Mind (spent inside the
--     burn window Arcane Power's glow already announces — same 3 min cooldown, so a second
--     glow would be a duplicate cue), Ice Block (emergency defensive, owned by the HP<30%
--     prompt), Evocation (mana cooldown, owned by the mana<30% prompt), Counterspell
--     (interrupt, owned by COUNTERSPELL NOW in the PvP alert flow), Blink (movement),
--     Invisibility (threat dump, owned by the 70%-threat prompt). None of the six is part of
--     the Arcane Blast / Frostbolt damage loop, so none of them earns a glow instead: no
--     mage cooldown is a rotational filler the way a hunter's Arcane Shot or a destruction
--     warlock's Conflagrate is.
-- The desaturate condition goes with the conversion: under showOnCooldown every visible icon
-- is on cooldown by definition, so greying the whole row would only make the abilities harder
-- to tell apart. The row is a dynamic group, so the gap closes — ABSENCE IS THE READOUT.
-- Subregion safety: F.icon's prototype already ships a subglow at subRegions[1] on every
-- icon, so nothing was inserted or reordered here and every existing "sub.1.glow" condition
-- still resolves to a subglow (audited on the decoded string, all 17 refs).

-- v7 (the middle of the screen is given back: the Resources bar stack becomes two UNIT ORBS;
-- SIX new auras, no existing uid moved, nothing outside the Resources group touched):
-- health / mana / threat left the centre and moved to where the units are. The player orb
-- sits left of the character and the target orb right of it, each a live 3D unit portrait
-- ringed by concentric arcs — outer health, inner mana, and on the target a third, outermost
-- threat ring. Percentages ride below (threat above) instead of inside a bar. The target orb
-- self-hides completely with no target, which no bar stack ever did.
--   * REGION TYPE. The rings are `progresstexture` in CLOCKWISE orientation on WeakAuras'
--     own bundled Ring_20px / Ring_10px art, with a `model` portrait in the middle. Both
--     region tables are written out in full from poc/unit-orbs/generate.lua (the verified
--     reference build) because wa_factory has no builder for either.
--   * THE RENAME THAT WOULD HAVE BEEN SILENT: progresstexture has no `barColor`. Every
--     colour escalation is now `foregroundColor`, and Conditions.lua drops changes whose
--     property is absent from the region's properties table with no error and no editor
--     warning, so a mechanical port would have shipped four dead escalations.
--   * THE INVERSION THAT WOULD HAVE BEEN A LIE: AuraBar draws EMPTY at total == 0,
--     ProgressTexture draws FULL. Every ring therefore carries a zero-total guard
--     (`maxhealth <= 0`, `threatvalue <= 0`, `maxpower <= 1`) that hides it instead.
--   * UID DISCIPLINE. W.assertUidContinuity required missing == 0 at the time — every uid the
--     previous string shipped had to be in this one (v12 is the first version to declare
--     deliberate removals and be allowed them) — so the bars could not be deleted and
--     replaced. They were TRANSFORMED in their own uid slots: health bar -> player health
--     ring, mana bar -> player mana ring, threat bar -> target threat ring, threat flash ->
--     the halo on that ring, and the two conserve-line textures -> two beads on the mana
--     ring. Six genuinely new auras (two cluster groups, two portraits, the target health
--     and mana rings) are appended at the very bottom. Nothing is orphaned in game.
--   * WHAT DID NOT SURVIVE, exactly: nothing. Both health tiers, the threat escalation and
--     its 80% pulse, the out-of-combat fade, the Arcane-only conserve breakpoint and every
--     load gate came across. The conserve mark is a bead on the ring instead of a vertical
--     line on a bar; it is still two auras precisely so it can keep its Arcane-only gate,
--     which a `subtexture` tick welded to the shared mana ring could not have.

-- v8 (PURE GEOMETRY: the orbs are one shared size across all seven packs. NO aura added or
-- removed, no uid moved, and not one trigger, load gate, condition, colour, spell id or
-- region type touched — diff the decoded strings and only width/height/xOffset/yOffset,
-- two font sizes and one texture path move):
--   * THE BUG WAS DISAGREEMENT, NOT ANY SINGLE NUMBER. v7 shipped a 120 px target cluster
--     beside a 100 px player cluster, and each of the seven packs had picked its own sizes
--     (96/84/88/100 outer rings across the repo). Side by side that reads as sloppiness,
--     which is what the live-client review reported as "the size uneven".
--   * ONE CANONICAL SET, declared as named constants at the top of the orb section so the
--     next edit cannot drift them apart again: ORB_OUTER 104, ORB_MID 78, ORB_INNER 54,
--     PORTRAIT 46, CLUSTER_X 260, CLUSTER_Y -60. Both clusters now present the SAME outer
--     diameter and the SAME portrait; the target just nests one more ring inside, since it
--     is the side that carries threat. Player 104/78, target 104/78/54.
--   * Ring_10px is gone. Its stroke is 10/256 of the drawn size — 4.7 px on a 120 px ring —
--     which read as a wire rather than a band. Every ring is Ring_20px now, so the threat
--     arc is a real band and the three concentric arcs read as one system.
--   * The read-outs are one set of offsets for both sides (health 14 pt at -60, power 11 pt
--     at -76, threat 11 pt at +60). They can be, because every ring in a cluster is
--     concentric and each subtext anchors CENTER: the offset is measured from the cluster
--     centre, not from whichever ring happens to carry the text. v7 needed four numbers
--     because its two clusters had different outer diameters.
--   * THE TRAP THIS PACK HAD: the Arcane conserve bead is positioned by trigonometry on the
--     mana ring's circumference (ringPoint), so resizing that ring without re-deriving the
--     bead would leave a mark floating in empty space. It is computed from G.pMpRing and
--     moves 31.56,-10.26 -> 34.19,-11.11 on its own; both bead auras share the one call.

-- v9 (DIABLO GLOBES: the two ring clusters become three liquid vessels — life, mana and
-- target — and the live portraits are gone. NO aura is added or removed, NO uid() call moves,
-- and nothing outside the globe layer is touched. Every trigger, load gate, condition and
-- colour escalation the rings carried is still here, on the region that replaced its ring):
--   * ONE FIELD SEPARATES A GLOBE FROM A RING, and it is `orientation`. Both are
--     `progresstexture`. A ring is "CLOCKWISE" on annulus art and encodes the value as ARC
--     LENGTH; a globe is "VERTICAL" — "Bottom to Top" in Private.orientation_with_circle_types
--     — on a solid disc, and encodes it as a WATERLINE that rises. VERTICAL_INVERSE is the
--     trap: it fills DOWNWARD, so the globe would drain from the top as you take damage,
--     which looks deliberate and is wrong. Switching paths also swaps which fields are live:
--     startAngle/endAngle stop mattering, and compress/slanted/slantMode start mattering.
--   * THE PORTRAIT IS REMOVED, and that is exactly what buys each number its place. A `model`
--     region cannot carry a text subregion at all (SubText's supports() is texture /
--     progresstexture / icon / aurabar / empty — model is absent), which is why v7/v8 had to
--     park every percentage OUTSIDE its ring, in the world. The percentages now sit INSIDE
--     the glass. Neither portrait aura is deleted: their two uids are recycled onto the life
--     and mana rims, so the update leaves nothing orphaned in the player's collection.
--   * THREAT HAS NO VESSEL OF ITS OWN, so it became the TARGET GLOBE'S RIM COLOUR: green,
--     orange at 70%, red on aggro, with the percentage above the globe on that same region.
--     Same party/raid gate, same never-in-arena gate, the same mandatory threatvalue <= 0
--     guard, and the 80% pulse still rides on top of it. No element and no screen space added.
--     The property is `color` here, not the ring's foregroundColor and not the bar's barColor.
--   * THE BREAKPOINT MARK GOT EASIER, not harder. On a ring the Arcane conserve mark needed
--     trigonometry on the circumference; on a vessel a threshold is a horizontal line at a
--     fixed height, yOffset = (threshold/max - 0.5) * GLOBE_MAIN, so the 30% mark is a line
--     across the mana globe at y = -23.2, as wide as the glass is at that height (106.32).
--   * ABSOLUTE POSITIONS. GLOBE_Y is a SCREEN coordinate, not a local one. Every globe is
--     nested two groups deep and offsets ADD down the chain, so the globe layer cancels the
--     top group's own y before the clusters place their globes:
--         top (0, -140) + layer (0, -10) + cluster (x, 0) + globe (0, 0) = (x, -150)
--     Decode the shipped string and add the chain up — that is the check this migration is
--     graded on, and it is the one the previous migration failed in six packs out of seven.

-- v10 (THE GLOBES MOVE BESIDE THE CHARACTER, AND THE GLASS CATCHES LIGHT. Two changes, both
-- applied identically in all seven packs. NO aura added, removed or renamed, NO uid() call
-- moved or added, no trigger, load gate, condition, colour, spell id or region type touched,
-- and nothing outside the globe layer changed — the diff is three constants, one cluster
-- offset, and one appended subregion per vessel):
--   * POSITION. v9 parked all three vessels on a band at y = -262, which read as a second bar
--     bolted under the HUD rather than as part of the character. They now FLANK the character:
--     life at (-190, 40), power at (+190, 40), the target globe above and between them at
--     (0, 110). Those three positions are fixed across the seven packs and were scanned against
--     every element in all of them; they are the tightest collision-free arrangement, and the
--     near misses are worth recording so nobody "tidies" them later: x = ±170 walks into the
--     Alerts column (x = -150) and the PvP column (x = +150), which every pack carries, and
--     x = ±210 walks into the PvP-layer elements at (200, -44). This pack's own columns sit at
--     exactly those two x values (see "Mage - Alerts" and "Mage - PvP"), so the margin here is
--     real, not theoretical.
--   * ABSOLUTE, NOT LOCAL — the same trap v9 documented and the reason this migration is
--     graded on a decode. GLOBE_Y and GLOBE_TGT_Y are SCREEN coordinates; the globes hang two
--     groups deep under a top group at y = -140, so the layer cancels it (GLOBE_LAYER_Y = 180)
--     and the target cluster carries the 70 that lifts it above the pair. Walk it in the
--     shipped string, not here.
--   * LOOK. Every vessel gains a specular highlight: a soft off-centre bright spot in the upper
--     left, sized to its own globe, in ADD blend so it brightens the liquid AND the percentage
--     sitting inside the glass instead of dimming either. It is APPENDED as the last subregion
--     of each globe, never inserted, because conditions address subregions positionally as
--     sub.N — see highlight()/addHighlight() for the full reasoning on both points.
--   * WHAT IS NOT IN IT: no dark edge vignette (it would sit over the number, which is
--     unreadable exactly when the number matters), no per-globe tuning of the highlight
--     geometry, and no change to the rims — the glass rim is still Circle_Smooth_Border drawn
--     BEHIND the fill at frameStrata 2, which is deliberate and documented in rim().


-- v11 (THE RINGS COME BACK, AND THE PORTRAITS WITH THEM. The three liquid vessels become two
-- ring clusters — health and mana around the player's face on the left, threat and target health
-- around the target's face on the right. NO aura is added or removed, NO uid() call moves, and
-- nothing outside the ring layer is touched. Every trigger, load gate, condition and colour
-- escalation the globes carried is still here, on the region that replaced its globe):
--   * ONE FIELD SEPARATES A RING FROM A GLOBE, and it is `orientation` — the same field that
--     took v8's rings to v9's globes, read the other way. Both are `progresstexture`. A globe
--     is "VERTICAL" on a solid disc and encodes the value as a WATERLINE; a ring is "CLOCKWISE"
--     on annulus art and encodes it as ARC LENGTH. Switching back also swaps which fields are
--     live: startAngle/endAngle matter again, and compress/slanted/slantMode go inert.
--     crop 0.41 is the identity value on the circular path and stays exactly where it is.
--   * THE PORTRAIT IS BACK, and it is what pushes the percentages out of the middle. A `model`
--     region cannot carry a text subregion at all (SubText's supports() is texture /
--     progresstexture / icon / aurabar / empty — model is absent), so the read-outs sit just
--     outside the rings again: health 13pt at -54, mana 10pt at -70, threat 10pt at +54, all
--     measured from the CLUSTER centre because every subtext anchors CENTER. The two globe rims
--     hand their uids straight back to the two portraits they replaced in v9.
--   * TWO RINGS AND A FACE PER SIDE, and no more than that. The target does NOT get a power
--     ring: a third arc on one side only is what made v7/v8 look busy and uneven, and the
--     matched pair — same OUTER, same INNER, same PORTRAIT on both sides — is the whole point.
--     The freed cluster group becomes "Mage - Target Ring Track": the outer circle the target
--     keeps when threat is not loaded (solo, arena), so the pair stays matched there too — a
--     region invented to hold a uid, which is precisely what v12 stopped doing and deleted.
--   * THE BREAKPOINT MARK FOLLOWS ITS RING. On a vessel the Arcane conserve mark was a
--     waterline; on a hoop it is a point on the circumference again, r = INNER/2 * 0.94 at
--     2*pi*fraction measured clockwise from the top — (27.71, -9.0) for the 30% switch. Same two
--     auras, same colours, same Arcane-only gate, same lit-pop animation.
--   * THE SPECULAR HIGHLIGHT IS DROPPED. It was glass over a filled vessel; on an arc there is
--     no glass to catch light, so v10's subtexture goes away with the globes it was drawn for.
--   * ABSOLUTE POSITIONS, the check this migration is graded on. CLUSTER_Y and TARGET_Y are
--     SCREEN coordinates; the rings hang two groups deep under a top group at y = -140, so the
--     layer cancels it (RING_LAYER_Y = 180) and the target cluster carries the 70 that lifts it
--     above the player's. Player cluster (-270, 40), target cluster (+270, 110). Walk it in the
--     shipped string, not here.

-- v12 (THE TARGET CLUSTER IS DELETED, AND THREAT COMES HOME. FOUR auras are REMOVED — the first
-- deletion this pack has ever shipped — the threat ring moves to the player cluster as its new
-- outermost arc, and nothing else in the pack is touched. Every trigger, gate, condition and
-- colour outside the two clusters (buffs, alerts, cooldown row, procs, the whole PvP layer) is
-- byte-identical to v11):
--   * WHY THE TARGET CLUSTER GOES. Its health arc, its face and its track were a second copy of
--     data the default UI already draws twice — the target frame and the nameplate — for the
--     entire game. A HUD element earns its place by changing the next button press, and the
--     target's health percentage never did: it duplicated the frame the player is already
--     looking at to select the target. Removed, not shrunk, not moved.
--   * WHY THREAT DOES NOT GO WITH IT. Threat is the ONE thing the target cluster carried that
--     nothing else in the game shows, and a dps who pulls aggro dies — losing it would be a real
--     regression. It becomes the OUTERMOST ring of the player cluster at THREAT_RING = 100, which
--     is also the more honest home: it is YOUR threat, not the target's, and the target merely
--     names the table it is measured against. Health (84) and mana (62) and the portrait (44) do
--     not move by one pixel, and the 80% flare resizes to 100 so it pulses ON the threat arc
--     rather than orbiting the radius the old cluster used.
--   * IT KEEPS EVERYTHING. The Threat Situation trigger (threatUnit — see threatTrigger below,
--     that spelling is load-bearing on internalVersion 45 data), the 70% orange and aggro red on
--     `foregroundColor` (barColor is aurabar-only and a SILENT no-op on a progresstexture), the
--     party/raid gate, the never-in-arena gate and the mandatory `threatvalue <= 0 -> alpha 0`
--     guard without which a ProgressTexture with a zero total draws FULL and reports a complete
--     circle of aggro at the exact moment you have none. Because of those two load gates the
--     common solo case is still two rings and a face; the third arc appears only when threat is
--     a real relationship.
--   * ORPHANS ARE EXPECTED HERE, AND THAT IS THE POINT. Four uids now have no home. Nothing is
--     invented to absorb them — that is how a HUD accumulates junk, and v11 already spent one
--     slot that way (the target ring track existed to keep a uid alive). The uid() CALL ORDER is
--     preserved exactly: the four freed slots are still drawn from the stream, in place, and
--     thrown away (see "retired uid slots" in the v12 assembly), so no surviving aura's uid
--     shifts by one call. The removals are declared to the verifier as WA-REMOVED lines below,
--     and WeakAuras never deletes an aura an import does not mention, so the pack README tells
--     the player to delete the leftover "Mage - Target Cluster" group by hand after updating.
--   * ABSOLUTE POSITIONS ARE UNCHANGED for everything that survives: the player cluster is still
--     at (-270, 40) — top (0, -140) + layer (0, 180) + cluster (-270, 0) + ring (0, 0) — and the
--     100px threat ring is concentric with the 84/62/44 that were already there. Walk it in the
--     shipped string, not here.
--
-- v13 (THE PERCENTAGES BECOME READABLE: health moves to the middle of the cluster, onto the
-- portrait, and the portrait moves to the BACK of the draw order so it can). No aura added,
-- removed, renamed or re-uid'd; no trigger, load gate, condition, colour, size or position
-- touched anywhere. The entire version is two subtext offsets, two font sizes and one child
-- reordering — but the reordering is what makes the offsets do anything, and it is the half a
-- reader will not predict:
--   * THE COMPLAINT, and what actually caused it. v11 parked the percentages outside the rings
--     (health 54px below the cluster, mana 70px below) because the portrait owns the middle and
--     a `model` region cannot carry a subtext. That reasoning was sound about WHERE THE TEXT CAN
--     LIVE — it must belong to a ring — and wrong about WHERE IT CAN BE DRAWN: a subtext anchors
--     to the cluster centre, so a ring's number can sit anywhere, its own band included. The
--     result was two small numbers on bare screen with nothing behind them, illegible over
--     anything bright, reported from the client as "percentage in middle can't be seen".
--   * THE FIX. Health goes to y = 0 at 16pt — dead centre, on the portrait, which is the one
--     opaque always-present backdrop the cluster has. Mana inherits the -54 slot health leaves,
--     at 12pt. Threat does not move (58, 10pt): it is above the outer ring and was never the
--     problem. Text tokens, colours, outline and shadow are all untouched.
--   * THE HALF THAT IS NOT IN THE CONSTANTS. Cluster children draw in controlledChildren order,
--     +4 frame levels each, and the portrait was LAST — i.e. over everything. A number at y = 0
--     under the old order is drawn UNDER the face and is simply invisible, so shipping the offset
--     change alone would have looked like a no-op. v13 moves the portrait to FIRST. That is safe
--     because every other child is an annulus or a bead with no art at the centre (innermost band
--     radius 26.16; the face ends at 22.00), so the rings hide none of the face — only their text
--     lands on it, which is the entire point. Measured radii and the flare case are worked
--     through in the assembly note at the bottom of this file.
--   * UID STREAM UNTOUCHED. Reordering adopt() calls edits controlledChildren only; the portrait
--     is still created in its original position in the uid stream. changed = 0, missing = 0.
--
-- v14 (THE SILL: the 100x100 ring cluster becomes a 102x37 instrument strip UNDER the character,
-- four stacked 100px rails where ONE PIXEL IS ONE PERCENT. NO aura is added or removed, NO uid()
-- call is added, moved or discarded, and every trigger, load gate and colour escalation the rings
-- carried is still here on the region that replaced its ring. What changes is region SHAPE,
-- region TYPE, POSITION and DRAW ORDER — all four of which are free of the uid stream):
--   * WHY A RAIL BEATS A RING, measured rather than asserted. A 0-100 quantity has exactly 100
--     distinguishable states. The old cluster spent 10,000 px2 delivering 712 px of arc for three
--     of them, 1,936 px2 of it on a 3D portrait that decides nothing, and every breakpoint on it
--     needed trigonometry (the 30% conserve bead lived at (27.71, -9.0), derived from sin/cos on
--     a stroke radius). A 100px rail is the exact length at which the gauge is lossless: every
--     breakpoint is x = value - 50, a full-height waterline instead of a bead on a curve, and the
--     whole instrument is 3,774 px2 — 2.65x denser, and 2.7x shorter on the axis that is scarce.
--   * ONE FIELD SEPARATES A RAIL FROM A RING, and it is the same field that took v8's rings to
--     v9's globes and back again: `orientation`. Both are `progresstexture`. A ring is "CLOCKWISE"
--     on annulus art and encodes the value as ARC LENGTH; a rail is "HORIZONTAL_INVERSE" on a flat
--     white square and encodes it as a LENGTH that grows left to right. The name is the usual WA
--     trap and it is the one field in this version that no committed string in this repo has ever
--     rendered: Private.orientation_with_circle_types reads HORIZONTAL_INVERSE = "Left to Right",
--     HORIZONTAL = "Right to Left" (transcribed verbatim in poc/diablo-globes/generate.lua), i.e.
--     the OPPOSITE of the aurabar convention in references/gotchas.md. If a live client fills the
--     rails from the right, the fix is this one token and nothing else moves.
--     Switching to the linear path also swaps which fields are live: startAngle/endAngle go inert
--     (emitted for the schema), compress/slanted/slant/slantFirst/slantMode become live and are
--     all left at their neutral defaults, and crop_x/crop_y stop being the circular branch's
--     sqrt(2) identity and become a plain texcoord scale on uniform white art, where they cannot
--     alter what is drawn. 0.41 therefore stays exactly where it is.
--   * THE PORTRAIT IS GONE, AND ITS UID BECAME THE PLATE. `Mage - Player Portrait` is re-typed
--     model -> texture and becomes the SILL PLATE: a flat 102x37 black-at-45% slab on the uniform
--     fill art — no border and no rounding, because Square_White has neither — drawn SECOND, over
--     the alarm rim and under everything else, so that four rails, three numbers, a ruler and
--     five waterlines all read against one even backdrop instead of a lava floor. It keeps the
--     portrait's Health trigger and both of its conditions, so it fades out of combat and hides
--     itself at max health 0 exactly as before. model -> texture is the v7/v9/v11 precedent read
--     the other way; the uid carries, so the in-game Update renames the region in place.
--   * THE ARCANE BLAST STACK ICON LEAVES THE BUFF ROW AND BECOMES LANE 4. The 40x40 icon at
--     (0, -156) is re-typed icon -> progresstexture and becomes `Mage - Arcane Lane`, 100x6 at the
--     bottom of the strip, fed by its OWN existing aura2 trigger (auraspellids {"36032"}) — so the
--     lane DRAINS with the debuff's remaining time — with three subtexture pips lit by the same
--     `stacks` variable the icon's glow condition already used. 1,600 px2 of buff row becomes 600
--     px2 inside the instrument, 12px under the mana rail, and the stack count and the window
--     clock become one object instead of two numbers on an icon. No new uid.
--   * THE CONSERVE BEADS BECOME WATERLINES. The Arcane 30% mark needed ringPoint() trigonometry on
--     the mana ring's circumference; on a rail it is x = 30 - 50 = -20, a full-height 11px hairline
--     across the mana rail with the lit one 5px wide over it. Two auras still, with the same
--     colours, the same Arcane-only spellknown gate and the same pop animation — the gate is why
--     they are auras and not subtextures (a subregion cannot carry a load gate).
--   * THE FLARE BECOMES THE INSTRUMENT'S RIM. `Mage - Threat Flash` keeps its uid, its
--     threatpct >= 80 trigger, its ADD blend, its party/raid + never-in-arena gates and its
--     alphaPulse animation, and changes from a 100px annulus to a 108x43 quad in the red it
--     already ships explicitly ({1, 0.1, 0.1, 0.85} — decoded, not assumed). It is a RIM AND NOT
--     AN OUTLINE: both squares WeakAuras bundles are FILLED (measured — see the texture note
--     below), so no single region can trace a hollow edge. What makes it read as an edge is that
--     it is 3px larger than the plate on every side and is adopted FIRST, at the BOTTOM of the
--     stack: only the 3px band that protrudes is visible, and the rest of the quad hides behind a
--     45%-black plate and behind every rail, number, waterline and pip. Nothing is composited
--     over a readout. Its footprint is 108x43 = 4,644 px2 and it exists only at >= 80% threat.
--   * POSITION IS ABSOLUTE AND IT IS (0, -110), not the ring cluster's (-270, 40). The strip sits
--     UNDER the character, on the crosshair, where the eye already is. A rectangle scan of the
--     full 108x43 ALARM ENVELOPE (not just the plate) against every other element in this pack,
--     dynamic groups projected six children deep, finds ZERO overlaps with 4.5px of clearance to
--     the nearest neighbour — the proof is re-run against the DECODED string at the bottom of
--     this file on every build.
--   * WHAT IS LOST, said out loud: the live 3D portrait (1,936 px2, zero decisions, and the one
--     thing in the pack that read as "you"), the threat percentage as a NUMBER (its subtext is
--     switched off, not deleted — one checkbox in /wa brings it back), and the Arcane Blast stack
--     COUNT and window countdown as text (three pips and a draining rail replace them).
--
-- The four auras v12 removes, declared for the verifier (see tools/verify-packs.lua). These
-- lines are the licence for the four disappearing uids and they expired at v13, so they are
-- inert: the removal already happened in the committed v12 string, both sides of the continuity
-- check agree, and `missing` is 0 without needing the allowance:
-- WA-REMOVED (v12): Mage - Target Cluster
-- WA-REMOVED (v12): Mage - Target Health Ring
-- WA-REMOVED (v12): Mage - Target Ring Track
-- WA-REMOVED (v12): Mage - Target Portrait
math.randomseed(20260816)  -- FIXED pack seed; uid() call order is append-only forever
local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
-- wa_factory/wa_lib resolve their own dependencies (wa_lib.lua, assets/icon_proto.lua)
-- from arg[0], so a bare relative dofile fails for scripts outside scripts/.
-- Point arg[0] at wa_factory.lua for the duration of the load, then restore it.
local SCRIPTS = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local realArg0 = arg and arg[0]
if arg then arg[0] = SCRIPTS .. "/wa_factory.lua" end
local F = dofile(SCRIPTS .. "/wa_factory.lua")
if arg then arg[0] = realArg0 end
local W = F.W

local CLASS = "MAGE"
local TOP = "Mage TBC - Arcane & Frost"
local OUT = dir .. "/all-specs.txt"

local byId, order = {}, {}
local function reg(t) byId[t.id] = t; order[#order + 1] = t; return t end
local function adopt(parent, child)
  child.parent = parent.id
  table.insert(parent.controlledChildren, child.id)
end

-- shared bits ---------------------------------------------------------------
local IN_GROUP = { multi = { group = true, raid = true } }  -- party or raid only

-- v5: "everywhere except arena", for PvE furniture that would be pure clutter in an arena.
-- There is no "not arena" key: the `size` load arg (Prototypes.lua) declares no `test` and no
-- `inverse`, and multiselect mode is a plain OR over raw string equality, so the exclusion has
-- to be spelled out as every OTHER legal instance_types value. On TBC the full key set is
-- none / party / ten / twenty / twentyfive / fortyman / pvp / arena (Types.lua deletes
-- ratedpvp, ratedarena, flexible and scenario for Classic-family clients, and deletes `arena`
-- only for Classic Era). `twenty` is legal but no TBC difficultyIndex maps to it; listing it is
-- free. `none` is the load-bearing entry: GetInstanceTypeAndSize returns the literal strings
-- "none", "none" from its final line when you are not in an instance, so the open world MATCHES
-- and the bars keep loading while questing — the doubt that kept this gate out of v4.
-- `pvp` stays listed on purpose: Alterac Valley has real NPCs with a real threat table.
local NOT_ARENA = { multi = {
  none = true, party = true, ten = true, twenty = true,
  twentyfive = true, fortyman = true, pvp = true,
} }

local ICE_BARRIER = { 11426, 13031, 13032, 13033, 27134, 33405 }  -- ranks 1-6

local function alertAnims(aura)   -- slide in from below, fly out upward
  aura.animation.start  = F.animPreset("slidebottom", "0.3", "easeOut")
  aura.animation.finish = F.animCustom("1", { y = 150, alpha = 0, scale = 0.4 }, "easeOut")
end

local function polishIcon(icon)   -- crop + 1px outline on every icon
  icon.zoom = 0.3
  table.insert(icon.subRegions, F.subborder())
end

-- Multi-check condition (WA stores an ANDed group as trigger = -2, variable = "AND", with
-- the sub-checks in `checks`; bool sub-checks compare `value` 1/0 and ignore `op`).
-- F.condition only expresses a single check, so combined states are built here.
local function allOf(checks, property, value)
  return {
    check = { trigger = -2, variable = "AND", checks = checks },
    changes = { [1] = { property = property, value = value } },
  }
end

-- Item triggers. The factory has no item builder (no earlier pack needed one), so these
-- come straight from the WeakAuras prototypes: "Cooldown Progress (Item)" takes a NUMERIC
-- itemName (the item id) plus genericShowOn exactly like the spell version, and "Item
-- Count" takes the same id with use_exact_itemName so the count is read off the id instead
-- of a localized GetItemInfo name lookup (which is nil until the item is cached).
local function itemTrigger(event, itemId, extra)
  local tr = {
    type = "item", event = event,
    use_itemName = true, itemName = itemId,
    names = {}, spellIds = {}, debuffType = "HELPFUL",
    subeventPrefix = "SPELL", subeventSuffix = "_CAST_START",
  }
  for k, v in pairs(extra or {}) do tr[k] = v end
  return tr
end

-- Power trigger filtered on percent of max mana (raw mana varies too much with gear).
local function manaPctTrigger(op, pct)
  local tr = F.powerTrigger(0)
  tr.use_percentpower = true
  tr.percentpower = tostring(pct)
  tr.percentpower_operator = op
  return tr
end

-- ===== v14 rail primitives ==================================================
-- wa_factory has no builder for `progresstexture`, so the region is written out in full below,
-- field for field, from the same table v11's ring() used — one field different (`orientation`)
-- and one texture different. Everything else (marks, triggers, subtexts, conditions, load gates,
-- assembly) still goes through the factory.
--
-- TWO BUNDLED TEXTURES, AND BOTH OF THEM ARE FILLED. Both ship inside WeakAuras itself
-- (Private.texture_types → "Shapes"; wa_factory exposes them as F.TEX_SQUARE and
-- F.TEX_SQUARE_BORDER), so nothing here needs a media addon.
--   Square_White.tga        — a FILLED, uniform white quad. This is the art every rail fills
--                             with, every waterline is cut from, the art the SILL PLATE is drawn
--                             on, and the art the ALARM RIM is drawn on.
--   Square_White_Border.tga — ALSO FILLED. A white square with a dark BEVEL baked into its edge.
--                             It is NOT an outline and its interior is NOT transparent.
--
-- THE SECOND LINE IS A MEASUREMENT, AND v14 SHIPPED ITS EXACT OPPOSITE. This file previously
-- claimed the border art was "an OUTLINE, the interior is transparent", inferred from two poc
-- builds. It was decoded out of the client instead:
--     Interface/AddOns/WeakAuras/Media/Textures/Square_White_Border.tga — 256x256, 32bpp, RLE
--   * 64516 of 65536 pixels (98.44%) are FULLY OPAQUE, alpha 255. The 1020 that are not are
--     exactly the 1px outer ring (4 * 256 - 4 = 1020);
--   * every pixel inset 8px or more from the edge: n = 57600, MIN alpha 255, MIN RGB channel 167.
--     There is no hole — a 240x240 core of the alleged "outline" is solid, opaque white;
--   * the centre scanline's red channel over x = 0..13 reads
--         0, 156, 100, 56, 40, 57, 102, 158, 206, 236, 250, 254, 255, 255
--     i.e. a dark inward bevel across roughly the outer 8 texels, bottoming out at 40 at x = 4
--     and fully recovered by x = 12;
--   * the centre pixel is rgba(255, 255, 255, 255).
-- The two poc builds that were cited as proof prove nothing: a filled square whose bevel darkens
-- its edge reads as "a frame" at low alpha and nests exactly as an outline would, so both
-- observations are consistent with the measurement. Neither poc was ever decoded. What v14 built
-- on that inference was a full-area additive red quad over the whole instrument.
--
-- THE CONSEQUENCE, and it is the entire reason this note exists: A SINGLE REGION ON EITHER OF
-- THESE TEXTURES CANNOT TRACE A HOLLOW EDGE. The alarm is not an outline and never was one. It is
-- a RIM, and it is a rim for two structural reasons that have nothing to do with which art it
-- uses (see ALARM_W / ALARM_H below, and post-build assert 2b, which pins both):
--   * it is RIM = 3px larger than the plate on every side (108x43 against 102x37), so a 3px band
--     protrudes past the plate on all four sides and that band is the alarm;
--   * it is drawn FIRST — cc[1], the BOTTOM of the stack — so the other 102x37 of it sits behind
--     a 45%-black plate and behind every rail, number, waterline and pip. NOTHING is composited
--     over a readout. Drawn LAST at the plate's own size, which is what v14 did, an ADD red at
--     0.85 washes all four lanes at exactly the moment threat >= 80% makes them worth reading.
-- Drop either half and the rim silently degrades back into that wash, which is why both halves
-- are asserted against the decoded string rather than left to this comment.
--
-- WHICH ART THE ALARM USES IS NOW A BRIGHTNESS QUESTION, NOT A CORRECTNESS ONE, and the same
-- scanline settles it. The visible rim is the outer 3 screen pixels of a 108px-wide quad, so its
-- columns sample texel centres (i + 0.5) * 256/108 = 1.19, 3.56, 5.93 — red ~156, ~48, ~102, a
-- banded left/right rim at roughly 40% strength (a mipmapped average over texels 0..7 is
-- 83.6/255 = 33%, which agrees). Vertically, 256 texels resampled onto 43px put those rows at
-- 2.98, 8.93, 14.9 — red ~56, ~236, ~255, i.e. nearly full. That is a rim that is dim on two
-- sides and bright on the other two. On Square_White every rim pixel is 255 on all four sides, so
-- the alarm is drawn on the FILL art: identical construction, uniform rim. (The rogue pack ships
-- the same construction on the border art; it is equally correct there, because correctness comes
-- from the size and the order. This is the one place the seven packs may differ.)
-- v11's Ring_20px annulus is gone with the rings: an annulus on the LINEAR path would fill as a
-- growing rectangle clipped out of a hoop, which is exactly the mirror of why a solid disc could
-- not be used on the circular path.
local RAIL_TEX  = F.TEX_SQUARE          -- the fill AND the track: one flat white square
local SLAB_TEX  = F.TEX_SQUARE          -- the plate: a FILLED quad, because it is a backdrop
local ALARM_TEX = F.TEX_SQUARE          -- the alarm rim: also filled. It reads as an edge because
                                        -- it is +3px per side and drawn FIRST, not because of art

-- ===== CANONICAL SILL GEOMETRY (v14) — IDENTICAL IN ALL SEVEN PACKS =========
-- These numbers are not this pack's to tune, exactly as v8's, v11's and v12's were not. They are
-- declared as named constants so a later edit cannot pull them apart: change them in all seven
-- packs or not at all. The whole design is one sentence — ONE PIXEL IS ONE PERCENT — and every
-- other number here follows from it:
--     x(v) = (v / maxpower - 0.5) * 100 ,  which for a 100-max resource is simply  x = v - 50
-- Compare the ring this replaces, whose 30% conserve mark needed r = size/2 * 0.94 and
-- sin/cos to land on (27.71, -9.0). The rails are 100px because 100 is the exact length at
-- which a 0-100 gauge is lossless: every pixel beyond it redraws a state the eye cannot
-- separate, every pixel below it throws one away.
local RAIL_LEN  = 100           -- the gauge itself: 1px == 1%
local SILL_W    = 102           -- the plate: RAIL_LEN + a 1px margin on each side
local SILL_H    = 37            -- 4 + 1 + 11 + 1 + 11 + 1 + 6 content + 1px margin top and bottom
local H_THREAT  = 4             -- lane 1: an early-warning ratio, so the thinnest rail
local H_HEALTH  = 11            -- lane 2: the glance read while taking damage
local H_POWER   = 11            -- lane 3: the mage's real clock
local H_LANE    = 6             -- lane 4: Arcane Blast stacks + the window they live in
-- THE ALARM RIM. Not a separate design — it is the plate plus a band, and the band is the only
-- part of it anyone ever sees. RIM is per side, so the quad is 6px bigger in each axis:
--     plate 102 x 37  ->  alarm 108 x 43
-- The two numbers below and the cc[1] position of the alarm are the SAME mechanism stated twice;
-- neither is optional. A 108x43 quad drawn LAST is a wash over every lane; a 102x37 quad drawn
-- FIRST is invisible (the plate covers it exactly). Only "bigger AND underneath" is a rim.
local RIM       = 3             -- how far the alarm protrudes past the plate, per side
local ALARM_W   = SILL_W + 2 * RIM   -- 108
local ALARM_H   = SILL_H + 2 * RIM   -- 43
-- Lane y offsets, LOCAL to the sill group. The stack runs top to bottom with a 1px gutter
-- between every pair, and the plate adds a 1px margin all round:
--     +18.5 .. -18.5  plate            (37 tall)
--     +17.5 .. +13.5  threat rail      (4)
--     +12.5 ..  +1.5  health rail      (11)
--      +0.5 .. -10.5  power rail       (11)
--     -11.5 .. -17.5  arcane lane      (6)
local Y_THREAT  =  15.5
local Y_HEALTH  =   7
local Y_POWER   =  -5
local Y_LANE    = -14.5

-- THE ABSOLUTE-POSITION RULE, spelled out because it is what four migrations in a row got wrong:
-- SILL_Y is a SCREEN coordinate, not a local one, and the strip hangs two groups deep off a top
-- group that carries its own y. Offsets ADD down the chain, so the sill group has to cancel BOTH
-- of them. The full chain, which the geometry proof at the bottom re-derives from the decoded
-- string rather than trusting this comment:
--     top (0, -140) + layer (0, 180) + sill (0, -150) + lane (0, y) = (0, -110 + y)
-- (0, -110) is not a taste call. It is the only place in this HUD where the strip is UNDER the
-- character, on the crosshair, and still clears everything — AND THE THING THAT HAS TO CLEAR IS
-- THE ALARM RIM, not the plate. The rim is 3px proud on every side, so the envelope is 108x43,
-- x -54..+54, y -131.5..-88.5. The buff row's icons span y -136..-176, so the rim's bottom edge
-- at -131.5 leaves 4.5px (the plate alone would have left 7.5px, which is the number this comment
-- used to print and the reason the scan below now boxes the envelope). 4.5px is the tightest
-- clearance anywhere in the pack; the next is 7.5px to the two burn-window timers. Scanned as a
-- rectangle against every element in this pack, dynamic groups projected six children deep.
local SILL_X       = 0          -- ABSOLUTE screen x of the strip: dead centre, on the crosshair
local SILL_Y       = -110       -- ABSOLUTE screen y of the strip: under the character's feet
local TOP_Y        = -140       -- the pack's top group; the sill layer offsets back out of it
local LAYER_Y      = 180        -- "Mage - Sill Layer", unchanged since v7 — the sill cancels it
local SILL_LOCAL_X = SILL_X                        -- 0
local SILL_LOCAL_Y = SILL_Y - TOP_Y - LAYER_Y      -- -110 + 140 - 180 = -150

-- The read-outs. Every number is printed INSIDE its own rail now, so there is exactly one
-- offset pair for both of them: x = +32 puts two 11pt digits at x +25..+39 and three at
-- +21.5..+42.5, i.e. still 7.5px inside the 100px rail's right edge, and y = 0 is the rail's
-- own middle. The subtext still anchors CENTER and is offset from the region's centre, which is
-- the mechanism v13 proved; what changes is that the region is now 11px tall instead of 84px
-- wide, so "inside the rail" and "legible" are finally the same place.
local PCT_SIZE        = 11      -- health and mana, printed in their own rails
local PCT_X           = 32      -- right-hand end of the rail, clear of the ruler tick at +25
local PCT_THREAT_SIZE = 10      -- unchanged size; the subtext SHIPS SWITCHED OFF (see below)
-- The one offset in this file that is measured from a RAIL rather than from the sill, and the
-- one v14 first got wrong: a subtext anchors to ITS OWN REGION's centre, and the threat rail's
-- centre is already at local +15.5, so this number is added to that, not to the group. The claim
-- it has to satisfy is "if a user re-enables it in /wa it lands just above the plate": the plate
-- ends at local +18.5, the rail sits at +15.5, and a 10pt line is ~12px tall, so its centre
-- belongs at local +26 -> 26 - 15.5 = 10.5 here, i.e. ABSOLUTE (0, -84), clearing the plate's top
-- edge at -91.5 by 1.5px. At the old value of 26 it landed at absolute (0, -68.5), 23px above
-- the instrument in open space — which is the placement the whole design set out to remove.
-- Assert 4 re-derives the absolute from the decoded string so the sentence cannot drift again.
local PCT_THREAT_Y    = 10.5

local COL = {
  health   = { 0.15, 0.82, 0.28, 1 },    -- green: the player's health rail
  mana     = { 0.20, 0.45, 0.95, 1 },    -- blue. A mage's power rail is ALWAYS mana: it is
                                         -- coloured for the power type it actually reads,
                                         -- and this class has exactly one.
  track    = { 0, 0, 0, 0.55 },          -- the UNFILLED part of every rail. Without a track a
                                         -- rail is a shape appearing out of nothing; with one
                                         -- it is a fill travelling along a known length.
  threat   = { 0.25, 0.80, 0.30, 1 },    -- green: the threat rail's base = no threat problem
  warn     = { 1, 0.60, 0.10, 1 },       -- orange: 50% health / 70% threat  (unchanged since v2)
  danger   = { 0.90, 0.12, 0.12, 1 },    -- red:    30% health / aggro       (unchanged since v2)
  arcane   = { 0.65, 0.30, 1, 1 },       -- v14: the arcane lane's fill. This is the exact colour
                                         -- the Arcane Blast icon's 3-stack glow used, moved onto
                                         -- the region that replaced the icon.
  plate    = { 0, 0, 0, 0.45 },          -- v14: the slab every rail and number is read against.
                                         -- The reported failure was "a bright floor washed it
                                         -- out"; this is the fix, and it is load-bearing.
  ruler    = { 1, 1, 1, 0.18 },          -- v14: quarter hairlines. 33px of ink, zero footprint,
                                         -- and they turn "estimate a fraction" into "count
                                         -- quarters" on an 11px rail.
  notch    = { 1, 1, 1, 0.85 },          -- v14: the 70% threat notch — the one number on the
                                         -- threat rail worth acting on, drawn instead of printed
  pip      = { 1, 1, 1, 0.90 },          -- v14: an Arcane Blast stack, lit
  hpText   = { 1, 1, 1, 1 },
  mpText   = { 0.55, 0.75, 1, 1 },       -- each number is coloured like its own rail, so none
  thText   = { 0.70, 1, 0.75, 1 },       -- of the three ever needs a label
}

-- wa_factory's stub() is local to the factory; the hand-written region tables below get the
-- identical scaffolding here.
local function regionStub(t)
  t.internalVersion, t.tocversion = 45, 20501
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

-- Same stub fields trigStub applies inside the factory. The factory's healthTrigger and
-- powerTrigger are hardwired to unit = "player" AND to a percentage filter; these two spell the
-- unit out and filter nothing, because a ring reads the whole range rather than a threshold.
-- The `unit` parameter survives v12's removal of the target cluster on purpose: it is what makes
-- the binding explicit at the call site instead of implicit in the factory.
local function unitTrigStub(tr)
  tr.names, tr.spellIds = {}, {}
  tr.subeventPrefix, tr.subeventSuffix = "SPELL", "_CAST_START"
  tr.debuffType = "HELPFUL"
  return tr
end

-- Health. The prototype ends in a hidden always-on test,
--   WeakAuras.UnitExistsFixed(unit, smart) and specificUnitCheck
-- ANDed into the trigger function, so a unit that does not exist produces NO STATE and the
-- region hides itself with no condition, no load gate and no custom code. That mechanism is what
-- the v11 target cluster was built on; on unit = "player" it never fires, which is one more
-- reason the surviving cluster needs no self-hide machinery.
local function unitHealthTrigger(unit)
  return unitTrigStub{ type = "unit", event = "Health", unit = unit, use_unit = true }
end

-- Mana, and only mana — the same three flags the pack's Enemy Mana bar already uses:
--   use_powertype + powertype = 0  -> read MANA specifically. Drop either and powerType is
--     nil and the trigger silently falls back to the unit's CURRENT bar, i.e. a warrior's
--     rage rendered in a ring coloured for mana.
--   use_requirePowerType           -> the ring exists only while mana is that unit's PRIMARY
--     bar. Harmless on a mage, whose primary bar is always mana, and kept because dropping it
--     would make the flag set differ from the identical trigger in the other six packs.
local function unitManaTrigger(unit)
  return unitTrigStub{
    type = "unit", event = "Power", unit = unit, use_unit = true,
    use_powertype = true, powertype = 0,
    use_requirePowerType = true,
  }
end

-- THREAT, and the one field name in this pack that a "modernising" edit would break silently.
-- The Threat Situation prototype's unit argument is `threatUnit` on internalVersion 45 data and
-- was renamed to `unit` at internalVersion 51; WeakAuras' Modernize pass migrates anything below
-- 51 forward, so a string that declares internalVersion 45 — as every region in this pack does —
-- MUST emit the OLD name and let the client rename it on import. v11 additionally set `unit`
-- (belt and braces, from a source read that had it the other way round); v12 drops that, because
-- emitting both names hands the migration two sources of truth for one binding. F.threatTrigger
-- already emits exactly `use_threatUnit` / `threatUnit = "target"`, which is why the threat ring,
-- the 80% flare and the Invisibility prompt now all go through the factory unmodified.
--
-- "target" is not a contradiction of v12's "it is YOUR threat": threat is a relationship, and
-- the unit names the TABLE it is read from — your standing on your current target. The ring is
-- on your cluster because the number is about you.

-- THE RAIL. Same region type as the v11 ring and the v9 globe, ONE field different —
-- `orientation` — and that field decides which of the others are live. Notes on every trap:
--   orientation "HORIZONTAL_INVERSE" -> "Left to Right" in Private.orientation_with_circle_types
--     (HORIZONTAL is "Right to Left", VERTICAL "Bottom to Top", VERTICAL_INVERSE "Top to
--     Bottom"; CLOCKWISE / ANTICLOCKWISE are the two radial values the rings used). NOTE this
--     is the OPPOSITE convention to an aurabar, where HORIZONTAL is the left-anchored one —
--     see references/gotchas.md. This is the one field in v14 that no committed string in this
--     repo has rendered; if a live client fills the rails from the right, swap this single
--     token to "HORIZONTAL" and nothing else in the build changes.
--   startAngle 0 / endAngle 360 -> INERT on the linear path (they were live on the rings).
--     Emitted because they are in the region's default table, not because they do anything.
--   compress / slanted / slant / slantFirst / slantMode -> the mirror image: inert on the
--     rings, LIVE here. All left at their neutral defaults: a slanted fill line is a stylistic
--     choice, and a square end is what makes a pixel-per-percent rail readable against a ruler.
--   crop_x / crop_y = 0.41      -> on the CIRCULAR path this was the identity value cancelling
--     a sqrt(2) expansion; on the linear path it is a plain texcoord scale, and the art is a
--     uniform white square, so it cannot change what is drawn either way. Left where it was.
--   backgroundColor             -> the UNFILLED part of the rail, drawn on the same white art;
--     with sameTexture = true, backgroundTexture is dead code and both are set anyway.
--   backgroundOffset = 0        -> the default 2 fattens the track relative to the fill, which
--     on an 11px rail reads as a halo rather than as the same rail behind it.
--   auraRotation = 0            -> absent from the 3.5.0 default table but read unconditionally
--     by current code as data.auraRotation / 180 * math.pi, so it must be emitted.
--   adjustedMin/Max are STRINGS ("") because SetAdjustedMin does adjustedMin:find(...).
--   progressSource is rewritten to {-1, ""} by Modernize < 71 no matter what is emitted, so
--     ONE PROGRESS-SUPPLYING TRIGGER PER RAIL and it must be trigger 1: automatic progress
--     reads the first ACTIVE trigger's value/total (F.triggers sets activeTriggerMode -10).
--     A second trigger is legal but can only feed CONDITIONS, never the fill — which is exactly
--     what the Unit Characteristics trigger is for on the health and mana rails.
--   foregroundColor is the conditionable colour. NOT the aurabar's `barColor`, which a
--     progresstexture does not have and which Conditions.lua drops SILENTLY.
local function rail(id, w, h, x, y, color, triggers)
  return regionStub{
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
    triggers = F.triggers(triggers),
    load = F.load(CLASS),
  }
end

-- THE SILL PLATE, which is where the portrait's uid goes. v11's `model` region is re-typed to a
-- plain `texture`: a 102x37 dark slab drawn FIRST so everything else in the instrument reads
-- against it. That is not decoration — the complaint this whole line of versions has been
-- chasing is "a bright floor or a fire washed it out", and an 11px rail with an 11pt number on
-- it survives snow, lava and Shattrath at noon only if it has an opaque backdrop. It is also
-- what makes four rails read as ONE instrument instead of four floating bars.
-- IT IS DRAWN ON Square_White (SLAB_TEX). Either bundled square would in fact back it — the
-- decode above shows Square_White_Border is filled too (98.44% of its pixels at alpha 255, min
-- RGB 167 across the whole 240x240 inset core), so the "a plate on the border art is a hollow
-- rectangle" claim this comment used to carry was simply false. Square_White is chosen because it
-- is UNIFORM: the border art's baked-in bevel (centre-scanline red 0,156,100,56,40,57,102,158,...
-- over the outer 8 texels) would resample onto the plate's outer ~2px as a dark lip, and a
-- backdrop wants one flat value behind an 11px rail and an 11pt number, not a vignette. The plate
-- therefore has no edge of its own, which is right: the instrument's only edge is the alarm rim,
-- and an alarm reads as an alarm because nothing else looks like it. F.texture consumes exactly
-- one uid() call, in the portrait's original position in the stream, so the re-type is free:
-- WeakAuras matches by uid and updates the region in place.
local function plate(id, w, h, color, triggers)
  local t = F.texture(id, CLASS, w, h, 0, 0, nil, SLAB_TEX, color)
  t.triggers = F.triggers(triggers)
  return t
end

-- The percentages ride on the rails and are printed INSIDE them. A subtext anchors to its
-- region's centre and is then offset (the mechanism v13 proved on the rings), so x = +32 puts
-- the number at the right-hand end of its own 100px rail with the ruler tick at +25 clear of it.
-- Each number still appears and disappears with the rail that owns it.
local function pct(sym, size, xOffset, color)
  local st = F.subtext("%" .. sym .. "%%", size, "CENTER", sym)
  F.subtextOffset(st, xOffset, st.anchorYOffset or 0)
  st.text_color = color
  return st
end

-- RESOURCE BREAKPOINTS ARE ARITHMETIC NOW. On a ring a threshold was a point on the hoop and
-- needed r = size/2 * 0.94 with sin/cos; on a 100px rail it is one subtraction, because the
-- rail's length IS the percentage scale:
--     x(v) = (v / maxValue - 0.5) * RAIL_LEN , i.e. x = v - 50 for a 100-max resource
-- Written as v * RAIL_LEN / maxValue - RAIL_LEN / 2 so the common case is exact in binary
-- floating point (30/100 - 0.5 is not), and rounded to 0.01 anyway so the build stays
-- byte-identical across libm implementations, exactly as v8's ringPoint did.
-- Vigor-style talents that raise a cap move the mark: the general form above is the reason
-- this takes maxValue rather than assuming 100 (see references/gotchas.md).
local function round2(v) return math.floor(v * 100 + 0.5) / 100 end
local function railX(value, maxValue)
  return round2(value * RAIL_LEN / (maxValue or 100) - RAIL_LEN / 2)
end

-- A SUBTEXTURE MARK, the field set copied verbatim from the rogue pack's shipped energy
-- breakpoint marks — the repo's proven subtexture instances, and the ones whose
-- `sub.N.textureVisible` conditions prove the property name too.
--   xOffset/yOffset are NOT in the subtexture default table but ARE read by modify ->
--   AnchorSubRegion, and only while anchor_mode = "point"; omit either and the mark stacks in
--   the dead centre of the region.
--   `subtick` still cannot come along: SubRegionTypes/Tick.lua's supports() returns
--   regionType == "aurabar", full stop. `subtexture` does list progresstexture.
local function submark(w, h, x, y, color, visible)
  return {
    type = "subtexture",
    textureVisible = visible ~= false, textureTexture = F.TEX_SQUARE,
    textureColor = color, textureBlendMode = "BLEND",
    textureDesaturate = false, textureMirror = false,
    textureRotate = false, textureRotation = 0,
    anchor_mode = "point", anchor_point = "CENTER", self_point = "CENTER",
    width = w, height = h, scale = 1, mirror = false, rotate = false,
    xOffset = x, yOffset = y,
  }
end

-- THE RULER: three 1px hairlines at 25 / 50 / 75%, appended to a rail AFTER everything already
-- on it (subregion indexes are positional and conditions address them as sub.N — append, never
-- insert). 33px of ink at 18% alpha, zero footprint, and it is what converts an 11px rail from
-- "estimate a fraction" into "count quarters".
local function addRuler(region, h)
  for _, x in ipairs({ -25, 0, 25 }) do
    region.subRegions[#region.subRegions + 1] = submark(1, h, x, 0, COL.ruler)
  end
end

-- ===== top-level group, anchored below the character ========================
-- NOTE: the top group takes the factory's own uid() call (no extra W.uid() here);
-- that choice is permanent — changing it would reshuffle every uid downstream.
local top = F.group(TOP, 0, TOP_Y, nil)

-- ===== Resources -> THE SILL (v14) ==========================================
-- The four regions below occupy the uid slots the v6 health / mana / threat bars held, and the
-- threat flash, IN THE SAME ORDER. v7 turned those bars into rings, v9 into globes, v11 back
-- into rings, v12 moved threat onto the player's own cluster, and every hop kept the slots
-- because W.assertUidContinuity forbids a uid from disappearing. v14 is a shape change, not a
-- membership change: all four survive, re-typed from arcs into rails and re-positioned into a
-- single instrument under the character. Not one uid() call is added, moved or discarded.
-- They are NOT adopted into the sill here: the sill group takes a uid slot at the very bottom of
-- this script, and re-parenting is free — only uid ORDER matters.
local gLayer = reg(F.group("Mage - Sill Layer", 0, LAYER_Y, nil))
adopt(top, gLayer)

-- LANE 2 — PLAYER HEALTH, 100 x 11 at local y +7: the widest rail with the biggest number,
-- because it is the read you take at a glance while something is killing you. Trigger 1 is the
-- only progress source (see rail()); the Unit Characteristics trigger is there purely to feed
-- the out-of-combat fade, exactly as it did on the v6 bar, the v8 ring, the v10 globe and the
-- v12 arc. Its colour, its conditions and its text token are untouched by v14 — what changes is
-- that 84x84 of annulus becomes 100x11 of rail, and the number moves from the middle of a
-- cluster to the right-hand end of the rail that owns it.
local hpRail = reg(rail("Mage - Health Rail", RAIL_LEN, H_HEALTH, 0, Y_HEALTH, COL.health,
  { unitHealthTrigger("player"), F.unitCharTrigger() }))
hpRail.subRegions[1] = pct("percenthealth", PCT_SIZE, PCT_X, COL.hpText)
-- ...and the ruler, APPENDED at sub.2-4. Quarter marks are what make a linear gauge readable
-- without a scale printed under it.
addRuler(hpRail, H_HEALTH)
-- v2's escalating colour tiers, carried across for the third time. The property is
-- `foregroundColor`, NOT the aurabar's `barColor` and not the plain texture's `color`:
-- progresstexture has no barColor, and Conditions.lua skips any change whose property is
-- missing from the region's properties table WITHOUT an error and WITHOUT an editor warning, so
-- the wrong name here is a dead escalation nobody notices until the health they are watching
-- stays green at 20%. Severe tier last: later conditions overwrite the same property, and the
-- revert is automatic (CreateDeactivateCondition restores data.foregroundColor).
-- The maxhealth guard stays mandatory: AuraBar draws EMPTY at total == 0 (`if self.total ~= 0`)
-- but ProgressTexture starts from `local progress = 1` and draws FULL, so a unit whose max
-- health has not streamed in yet would flash a completely full rail. `maxhealth` is a stored
-- conditionType = "number" arg on the Health prototype.
hpRail.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "percenthealth", "<", "50", "foregroundColor", COL.warn),
  F.condition(1, "percenthealth", "<", "30", "foregroundColor", COL.danger),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),   -- zero-total guard, wins over the fade
}

-- LANE 3 — PLAYER MANA, 100 x 11 at local y -5: the mage's real resource clock — Evocation
-- pacing reads off it, and the Arcane conserve breakpoint below is now a waterline ACROSS it
-- rather than a bead on a circumference. Colour, conditions and text token unchanged.
local mpRail = reg(rail("Mage - Mana Rail", RAIL_LEN, H_POWER, 0, Y_POWER, COL.mana,
  { unitManaTrigger("player"), F.unitCharTrigger() }))
mpRail.subRegions[1] = pct("percentpower", PCT_SIZE, PCT_X, COL.mpText)
addRuler(mpRail, H_POWER)   -- appended at sub.2-4
-- Power is the one prototype that cannot hit total == 0 — its init floors the total at
-- math.max(1, UnitPowerMax(...)) — which is exactly why this guard reads <= 1 and not <= 0.
mpRail.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxpower", "<=", "1", "alpha", 0),
}

-- LANE 1 — THREAT, 100 x 4 at local y +15.5, the top rail of the instrument. Everything that
-- makes it worth keeping is unchanged — the trigger, both escalations, both load gates and the
-- zero-value guard. What changes is the shape and, deliberately, the READ:
--   * THE NUMBER IS SWITCHED OFF, not deleted. `threatpct` is scaled so 100 = pulling aggro, so
--     it is an early-warning RATIO, not a quantity you spend. Reading "68" against "72" is
--     slower than watching a fill cross a notch, and it was the one element of the old cluster
--     printing 10pt text onto open screen. The subtext keeps its index (sub.1), its token, its
--     colour and its font, and ships with text_visible = false: one checkbox in /wa brings it
--     back, and it lands just above the plate rather than on top of a rail.
--   * THE 70 NOTCH REPLACES IT, appended at sub.2 — a 2x4 white tick at x = 70 - 50 = +20. When
--     the fill touches the notch you are at 70% of the pull threshold: stop, or dump.
--   * THE PROPERTY NAME IS THE TRAP: an aurabar escalates with `barColor`, a plain texture with
--     `color`, and a progresstexture with `foregroundColor`. Conditions whose property is
--     missing from the region's table are dropped SILENTLY, with no error and no editor warning.
--   * Severe state last: the aggro red overwrites the 70% orange on the same property.
--   * Renaming it is safe and is not a new aura: WeakAuras matches auras across imports by uid,
--     which this region keeps, so the in-game Update renames the existing region in place.
local threatRail = reg(rail("Mage - Threat Rail", RAIL_LEN, H_THREAT, 0, Y_THREAT, COL.threat,
  { F.threatTrigger() }))
local threatPct = pct("threatpct", PCT_THREAT_SIZE, 0, COL.thText)
F.subtextOffset(threatPct, threatPct.anchorXOffset or 0, PCT_THREAT_Y)
threatPct.text_visible = false     -- switched off, index preserved — see the note above
threatRail.subRegions = {
  threatPct,
  submark(2, H_THREAT, railX(70, 100), 0, COL.notch),   -- sub.2: the 70 notch
}
threatRail.conditions = {
  F.condition(1, "threatpct", ">=", "70", "foregroundColor", COL.warn),
  F.condition(1, "aggro", "==", 1, "foregroundColor", COL.danger),   -- severe last
  -- MANDATORY, and the one place this migration could still regress. threattotal is
  -- (threatvalue or 0) * 100 / threatpct, so BOTH value and total are 0 whenever threatvalue
  -- is 0 — the instant before your first cast lands, and right after an Invisibility drop.
  -- On a ProgressTexture a zero total draws FULL, so without this guard the rail would report
  -- a complete bar of aggro at the exact moment you have none. `threatvalue` is a stored
  -- conditionType = "number" arg (the hidden `total` is not), so the rail is hidden instead.
  F.condition(1, "threatvalue", "<=", "0", "alpha", 0),
}
-- v2: party/raid only, like the flash overlay and the Invisibility prompt. Solo you are always
-- the aggro target, so ungated this rail would sit pinned red for every quest mob.
threatRail.load.use_ingroup = true
threatRail.load.ingroup = IN_GROUP
-- v5: and NOT in arena. An arena team has no threat table, so it would read a meaningless
-- number in exactly the place a player has least attention to spare. `ingroup` cannot express
-- this on its own — an arena team IS a party. Everywhere else is unchanged, open world included
-- (see NOT_ARENA). Both gates travel with the threat read-out unchanged, exactly as they did in
-- v5, v8, v10 and v11. The honest consequence is now a FEATURE rather than a compromise: solo
-- and in arena the rail does not load at all, so the common case is a three-lane instrument, and
-- the fourth lane appears only when threat is a real relationship. Nothing draws a placeholder
-- in its place — v11's target ring track existed to keep a uid alive, and v12 deletes it.
threatRail.load.use_size = false   -- false selects MULTI mode; only nil disables the gate
threatRail.load.size = NOT_ARENA

-- LANE 5 — THE ALARM RIM: 80%+ threat, pulsing red, and since v14 it IS the strip's own edge
-- rather than a halo orbiting a cluster. Same region type, same trigger, same animation and the
-- same two load gates as v6, v8, v10, v11 and v12.
--
-- ALARM_W x ALARM_H = 108x43, WHICH IS THE PLATE PLUS 3px PER SIDE, AND IT IS ADOPTED FIRST.
-- Those two facts together are the alarm; either one alone is a defect:
--   * IT IS NOT AN OUTLINE, because there is no outline available. Both bundled squares are
--     FILLED (Square_White_Border decodes to 98.44% fully-opaque pixels, min RGB 167 over its
--     entire 240x240 inset core — see the texture note above). v14 believed the border art was
--     hollow, shipped this region at the plate's own 102x37 in ADD blend, and adopted it LAST.
--     The result was a full-area additive red quad over all four lanes: the health fill, the mana
--     fill, both numbers, the 70 notch and the three arcane pips all washed to one colour at
--     exactly the moment threat >= 80% makes them worth reading.
--   * WHAT IT IS INSTEAD: 3px bigger than the plate on every side and at the BOTTOM of the draw
--     order. Only the 3px band protruding past the plate is ever visible — a pulsing red rim
--     around the whole instrument. The remaining 102x37 sits behind a 45%-black plate and behind
--     every readout, so nothing is composited over a number and every colour code survives.
--     This construction is correct whether the art is filled or hollow, which is exactly why it
--     is the one to use: it does not depend on a claim about a .tga.
-- THE COLOUR IS SET EXPLICITLY and always has been in this pack ({1, 0.1, 0.1, 0.85}, decoded
-- from the shipped v13 string, not assumed): a texture that ships `color = {}` draws in
-- WeakAuras' default white, which on an alarm is the difference between a warning and a flicker.
-- ADD blend is likewise explicit, because a rim that stops being additive stops glowing.
local flash = reg(F.texture("Mage - Alarm Frame", CLASS, ALARM_W, ALARM_H,
  0, 0, nil, ALARM_TEX, { 1, 0.1, 0.1, 0.85 }))
flash.color     = { 1, 0.1, 0.1, 0.85 }   -- restated, never inherited: assert 2b checks all four
flash.blendMode = "ADD"
flash.triggers = F.triggers({ F.threatTrigger(80) })
flash.animation.main = F.animPreset("alphaPulse", "1")  -- duration required or it is invisible
flash.load.use_ingroup = true
flash.load.ingroup = IN_GROUP
flash.load.use_size = false   -- v5: follows the threat read-out out of the arena
flash.load.size = NOT_ARENA

-- ===== Buffs: static timer row (mutually-exclusive specs share the slot) ====
local gBuffs = reg(F.group("Mage - Buffs", 0, -16, nil))
adopt(top, gBuffs)

-- LANE 4 — ARCANE BLAST STACKS, and v14's one genuine gain in information rather than density.
-- Arcane driver: Arcane Blast stacks (8 s window, each stack +75% mana cost). Three stacks = the
-- cap: keep spamming AB only while Arcane Power / Presence of Mind / Icy Veins are burning,
-- otherwise fall back to filler until the aura drops and rebuild.
--
-- THIS AURA IS CREATED HERE, in the buff row's uid slot, and ADOPTED INTO THE SILL at the bottom
-- of the file. It keeps its uid, its aura2 trigger (auraspellids {"36032"}, ids not names, so it
-- survives a zhCN client) and its Arcane-only spellknown gate byte for byte; the region TYPE
-- changes, icon -> progresstexture, which is free of the uid stream exactly as model -> texture
-- is on the plate. What that buys:
--   * THE LANE IS THE WINDOW CLOCK. Fed by the same aura2 trigger, a progresstexture's automatic
--     progress is the aura's remaining duration, so the rail DRAINS as the 8s stack window runs
--     out. The icon needed a separate 11pt "%p" subtext to say the same thing.
--   * THE PIPS ARE THE STACK COUNT. Three 7x6 subtexture pips at x -20 / 0 / +20, each lit by
--     the SAME `stacks` variable the icon's glow condition already used, so "how many" is a
--     count of blocks instead of a digit — and at three the whole lane turns red, which is the
--     one state that changes the next button press.
--   * IT COSTS 1,000 px2 LESS AND SITS 12px UNDER THE MANA RAIL. "Am I at cap" and "can I
--     afford another Arcane Blast" are now one fixation instead of two: the buff row was 46px
--     below the strip and the mana ring was 250px to the left of it.
-- WHAT IS LOST, said plainly: the 40x40 spell icon art, the 16pt stack NUMBER and the countdown
-- text. The pips and the draining rail carry both facts; the icon carried them in 1,600 px2.
--   * AND IT BREATHES WITH THE REST OF THE INSTRUMENT. Trigger 2 is the same always-active Unit
--     Characteristics feeder the plate and the health and mana rails carry, added in v14 for the
--     one reason a trigger is ever added here: the lane is part of the strip now, and without it
--     a stack window that outlives the pull drew at 100% over a plate at 50%. It cannot change
--     WHEN the lane shows (F.triggers defaults to disjunctive = "all" and the feeder is always
--     active, so the aura trigger alone still decides) and it cannot change WHAT the lane fills
--     with (activeTriggerMode -10 takes progress from the first ACTIVE trigger, which is the
--     aura). It exists only to expose `inCombat` to the fade condition below.
local ab = reg(rail("Mage - Arcane Lane", RAIL_LEN, H_LANE, 0, Y_LANE, COL.arcane,
  { F.auraTrigger("player", true, { 36032 }), F.unitCharTrigger() }))
ab.subRegions = {
  submark(7, H_LANE, -20, 0, COL.pip, false),   -- sub.1: stack 1
  submark(7, H_LANE,   0, 0, COL.pip, false),   -- sub.2: stack 2
  submark(7, H_LANE,  20, 0, COL.pip, false),   -- sub.3: stack 3
}
-- `stacks` is a stored conditionType = "number" arg on the aura2 prototype — the shipped v13
-- condition compared it with "==" for the glow, so the variable is proven on this exact trigger.
-- Ordered least severe first: a later matching condition overwrites the same property, and the
-- three pip conditions each address a different one, so only the colour escalates.
ab.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),   -- the same fade the rest of the strip has
  F.condition(1, "stacks", ">=", "1", "sub.1.textureVisible", true),
  F.condition(1, "stacks", ">=", "2", "sub.2.textureVisible", true),
  F.condition(1, "stacks", ">=", "3", "sub.3.textureVisible", true),
  F.condition(1, "stacks", "==", "3", "foregroundColor", COL.danger),  -- at cap: max cost
}
ab.load.use_spellknown = true
ab.load.spellknown = 12042      -- Arcane Power known == deep-arcane spec gate (unchanged)
-- NOT adopted into gBuffs any more; see the v14 assembly at the bottom of this file.

-- Frost: Ice Barrier uptime (all 6 ranks) — pushback protection = more Frostbolts.
local ib = reg(F.icon("Mage - Ice Barrier", CLASS, 40, 40, 0, 0, nil))
ib.triggers = F.triggers({ F.auraTrigger("player", true, ICE_BARRIER) })
ib.subRegions[1] = F.subglow(false, { 0.4, 0.85, 1, 1 })  -- preset color, lit by condition
ib.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
-- v2: 60 s shield on a 30 s recast, so refresh BEFORE it drops — the MISSING alert can
-- only fire once the shield is already gone, which concedes an unshielded gap every time.
ib.conditions = { F.condition(1, "expirationTime", "<=", "5", "sub.1.glow", true) }
ib.load.use_spellknown = true
ib.load.spellknown = 11426
adopt(gBuffs, ib)

-- ===== Alerts: glowing prompt flow beside the character =====================
local gAlerts = reg(F.dynGroup("Mage - Alerts", -150, 96, nil, "UP", "BOTTOM", 6))
adopt(top, gAlerts)

-- Clearcasting: next spell is free — weave it immediately. Icon comes from the aura.
local cc = reg(F.icon("Mage - Clearcasting", CLASS, 40, 40, 0, 0, nil))
cc.triggers = F.triggers({ F.auraTrigger("player", true, { 12536 }) })
cc.subRegions[1] = F.subglow(true, { 1, 0.85, 0.2, 1 })
cc.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
cc.load.use_combat = true   -- v2: a proc out of combat is not a decision
alertAnims(cc)
adopt(gAlerts, cc)

-- Mana < 30% AND Evocation ready, in combat: channel now, not at 0.
local evo = reg(F.icon("Mage - Evocation Prompt", CLASS, 40, 40, 0, 0, nil))
evo.triggers = F.triggers({ manaPctTrigger("<", 30), F.cdTrigger(12051, "Evocation", "showOnReady") })
evo.iconSource = 0
evo.displayIcon = "Interface\\Icons\\Spell_Nature_Purge"
evo.cooldown = false
evo.subRegions[1] = F.subglow(true, { 0.3, 0.7, 1, 1 })
evo.load.use_combat = true
-- v3: both specs evocate, but a cooldown trigger on a spell you have not trained reports
-- "ready", so below level 20 this prompted a button that does not exist. Its own rank-1 id
-- is the right gate — it scopes the levelling case without touching either spec.
evo.load.use_spellknown = true
evo.load.spellknown = 12051
alertAnims(evo)
adopt(gAlerts, evo)

-- Barrier fell off AND the 30 s recast is ready, in combat (Frost).
local bmiss = reg(F.icon("Mage - Barrier MISSING", CLASS, 40, 40, 0, 0, nil))
bmiss.triggers = F.triggers({
  F.auraTrigger("player", true, ICE_BARRIER, { matchesShowOn = "showOnMissing" }),
  F.cdTrigger(11426, "Ice Barrier", "showOnReady"),
})
bmiss.iconSource = 0
bmiss.displayIcon = "Interface\\Icons\\Spell_Ice_Lament"
bmiss.cooldown = false
bmiss.subRegions[1] = F.subglow(true, { 0.4, 0.85, 1, 1 })
bmiss.load.use_combat = true
bmiss.load.use_spellknown = true
bmiss.load.spellknown = 11426
alertAnims(bmiss)
adopt(gAlerts, bmiss)

-- HP < 30% AND Ice Block ready, in combat: the panic button (Frost talent in TBC).
local block = reg(F.icon("Mage - Ice Block Prompt", CLASS, 40, 40, 0, 0, nil))
block.triggers = F.triggers({
  F.healthTrigger(30),
  F.cdTrigger(45438, "Ice Block", "showOnReady"),
})
block.iconSource = 0
block.displayIcon = "Interface\\Icons\\Spell_Frost_Frost"
block.cooldown = false
block.subRegions[1] = F.subglow(true, { 0.75, 0.95, 1, 1 })
block.load.use_combat = true
block.load.use_spellknown = true
block.load.spellknown = 45438
alertAnims(block)
adopt(gAlerts, block)

-- Threat >= 70% AND Invisibility ready, in combat, grouped: drop threat or die.
local invis = reg(F.icon("Mage - Invisibility Prompt", CLASS, 40, 40, 0, 0, nil))
invis.triggers = F.triggers({
  F.threatTrigger(70),
  F.cdTrigger(66, "Invisibility", "showOnReady"),
})
invis.iconSource = 0
invis.displayIcon = "Interface\\Icons\\Ability_Mage_Invisibility"
invis.cooldown = false
invis.subRegions[1] = F.subglow(true, { 1, 0.45, 0.1, 1 })
invis.load.use_combat = true
invis.load.use_spellknown = true
invis.load.spellknown = 66
invis.load.use_ingroup = true
invis.load.ingroup = IN_GROUP
alertAnims(invis)
adopt(gAlerts, invis)

-- ===== Cooldowns: one row; talent CDs appear via Spell Known, gaps collapse ==
local gCDs = reg(F.dynGroup("Mage - Cooldowns", 0, -66, nil, "HORIZONTAL", "CENTER", 4))
adopt(top, gCDs)

-- v2: every icon is Spell Known gated (v1 left Evocation/Counterspell/Blink permanently lit
-- for mages below level 20/24/32), and the three use-on-cooldown burst CDs glow the moment
-- they come up IN COMBAT — out of combat the row stays still.
-- v6: the third field is the CLASSIFICATION, not a glow flag (see the v6 note at the top):
--   "glow" — press-on-cooldown damage cooldown: showAlways + the gold ready-glow in combat
--   "seq"  — showAlways, glow supplied below (Cold Snap's is a sequencing cue, not a ready cue)
--   "hide" — situational/utility/emergency: showOnCooldown, no desaturate, absence = available
local cdList = {
  { "Arcane Power",           12042, "glow" },  -- Arcane 31: 3 min burst, press on CD
  { "Presence of Mind",       12043, "hide" },  -- Arcane 21: spent inside the AP burn window
  { "Icy Veins",              12472, "glow" },  -- both 40/0/21 arcane and frost talent it
  { "Summon Water Elemental", 31687, "glow" },  -- Frost 41: 3 min pet, press on CD
  { "Cold Snap",              11958, "seq"  },  -- Frost 21: 8 min, sequencing rebuilt below
  { "Ice Block",              45438, "hide" },  -- Frost 31: 5 min immunity, HP<30% prompt owns it
  { "Evocation",              12051, "hide" },  -- 8 min mana refill, mana<30% prompt owns it
  { "Counterspell",           2139,  "hide" },  -- 24 s interrupt, COUNTERSPELL NOW owns it
  { "Blink",                  1953,  "hide" },  -- 15 s reposition
  { "Invisibility",           66,    "hide" },  -- 5 min threat drop, 70%-threat prompt owns it
}
for _, e in ipairs(cdList) do
  local kind = e[3]
  local icon = reg(F.icon("Mage CD - " .. e[1], CLASS, 32, 32, 0, 0, nil))
  icon.cooldownTextDisabled = false   -- swipe numbers here; no %p subtext (OmniCC doubles)
  icon.useTooltip = true
  if kind == "hide" then
    -- Exists only while the cooldown runs, carrying the swipe and its countdown, and gone the
    -- moment the ability is back. No desaturate: every visible icon here is on cooldown, so
    -- greying them all would just make them harder to tell apart at a glance.
    icon.triggers = F.triggers({ F.cdTrigger(e[2], e[1], "showOnCooldown") })
    icon.conditions = {}
  else
    icon.conditions = { F.condition(1, "onCooldown", "==", 1, "desaturate", true) }
    if kind == "glow" then
      -- Unit Characteristics is always active, so trigger 1 still drives icon and swipe.
      icon.triggers = F.triggers({ F.cdTrigger(e[2], e[1], "showAlways"), F.unitCharTrigger() })
      icon.subRegions[1] = F.subglow(false, { 1, 0.85, 0.2, 1 })
      icon.conditions[2] = allOf({
        { trigger = 1, variable = "onCooldown", value = 0 },
        { trigger = 2, variable = "inCombat", value = 1 },
      }, "sub.1.glow", true)
    else
      icon.triggers = F.triggers({ F.cdTrigger(e[2], e[1], "showAlways") })
    end
  end
  icon.load.use_spellknown = true
  icon.load.spellknown = e[2]
  adopt(gCDs, icon)
end

-- Cold Snap is not a press-on-cooldown button: it resets the Frost cooldowns, so it is
-- only worth pressing once Icy Veins AND Water Elemental have been spent. The icon keeps
-- showing its own 8 min cooldown (trigger 1, showAlways, disjunctive "any"), and glows only
-- when both resets are banked and Cold Snap itself is up. A mage who never learned Water
-- Elemental simply never gets the glow — the icon still behaves as before.
-- v6 keeps it on showAlways for exactly that glow: the sequencing cue fires while Cold Snap
-- is READY, so an icon hidden until it goes on cooldown could never deliver it.
local coldsnap = byId["Mage CD - Cold Snap"]
coldsnap.triggers = F.triggers({
  F.cdTrigger(11958, "Cold Snap", "showAlways"),
  F.cdTrigger(12472, "Icy Veins", "showOnCooldown"),
  F.cdTrigger(31687, "Summon Water Elemental", "showOnCooldown"),
}, { disjunctive = "any" })
coldsnap.subRegions[1] = F.subglow(false, { 0.4, 0.9, 1, 1 })
coldsnap.conditions[2] = allOf({
  { trigger = 1, variable = "onCooldown", value = 0 },
  { trigger = 2, variable = "show", value = 1 },
  { trigger = 3, variable = "show", value = 1 },
}, "sub.1.glow", true)

-- ===== v2 additions ==========================================================
-- NEW auras only from here down: every W.uid() call below is appended AFTER the whole v1
-- stream, so all 25 v1 auras keep their uid and the in-game import still offers "Update".
-- They are re-parented into the v1 groups (re-parenting is free; uid ORDER is what matters).

-- Mana conserve breakpoint. Arcane's whole game is spending the mana budget to zero by the
-- time the boss dies: above the line keep burning Arcane Blast, below it drop to the
-- 3x Arcane Blast / 3x Frostbolt conserve cycle (Icy Veins puts the switch at ~1500-3000
-- mana, i.e. roughly 30% of a raid pool — a percentage keeps it honest across gear).
-- The dim waterline is always there; the lit one pops in the moment mana crosses it.
-- v7 put the breakpoint on the mana RING as a bead on the circumference; v9 flattened it into
-- a waterline across the mana globe; v11 put it back on the hoop; v14 makes it a FULL-HEIGHT
-- WATERLINE across the mana rail. This is the mark following its gauge, not a redesign — and on
-- a rail it is the cheapest form it has ever taken: x = 30 - 50 = -20, no trigonometry, no
-- dependence on a ring diameter, and the mark spans the whole 11px height instead of being a
-- 6.6px bead sitting near an arc.
--
-- WHY IT IS STILL TWO STANDALONE TEXTURE AURAS AND NOT A `subtexture` TICK. WeakAuras does
-- support static ticks on a progresstexture — SubRegionTypes/Texture.lua's supports() lists
-- progresstexture, and a subtexture with explicit xOffset/yOffset is the documented recipe
-- (aurabar's `subtick` is aurabar-only and could never have come along). It was rejected here
-- for one reason: a sub-region cannot carry a load gate. This breakpoint is ARCANE-ONLY since
-- v3 — it marks the switch from Arcane Blast spam to the 3x AB / 3x Frostbolt conserve cycle,
-- and Frost has no second rotation to switch into — and a tick welded onto the shared mana
-- rail would show for Frost too, silently undoing that audit. (The ruler hairlines on that rail
-- CAN be subtextures precisely because they are spec-neutral: 25/50/75 is arithmetic, not
-- rotation.) Two auras also keep the "lit" pop as a real animation.
local MANA_CONSERVE_PCT = 30
-- Straight out of railX(), so both waterlines follow RAIL_LEN instead of being left behind in
-- empty space if the rail is ever resized: 30% of a 100px rail is x = -20, and y is the mana
-- rail's own local y so the mark sits ON it. Height is the rail's height, exactly — a waterline
-- is the full depth of the gauge it crosses, which is what distinguishes it from a bead.
-- (v9's line spanned the glass at y = -14.4; v11's bead orbited to (27.71, -9.0). Both numbers
-- went with the shape that needed them.)
local MANA_MARK_X, MANA_MARK_Y = railX(MANA_CONSERVE_PCT, 100), Y_POWER
local MARK_DIM, MARK_LIT = 3, 5   -- hairline, wider when it lights
local manaLine = reg(F.texture("Mage - Mana Conserve Line", CLASS, MARK_DIM, H_POWER,
  MANA_MARK_X, MANA_MARK_Y, nil,
  F.TEX_SQUARE, { 1, 0.75, 0.2, 0.55 }))
manaLine.triggers = F.triggers({ F.powerTrigger(0), F.unitCharTrigger() })
manaLine.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }
-- v3: Arcane only. The line marks the point where Arcane STOPS spamming Arcane Blast and
-- starts the 3x Arcane Blast / 3x Frostbolt conserve cycle — it is the switch between two
-- rotations. Frost has no second rotation: it is Frostbolt spam all the way down, and its
-- low-mana actions (Evocation, mana gem) already have their own prompts, both of which
-- carry their own thresholds. So for Frost the line marked nothing pressable.
manaLine.load.use_spellknown = true
manaLine.load.spellknown = 12042      -- Arcane Power == deep-Arcane spec gate
-- v14: adopted into the sill at the bottom of this script, AFTER the mana rail it marks, so it
-- draws over the fill rather than under it (+4 frame levels per child).

local manaLit = reg(F.texture("Mage - Mana Conserve Lit", CLASS, MARK_LIT, H_POWER,
  MANA_MARK_X, MANA_MARK_Y, nil,
  F.TEX_SQUARE, { 1, 0.75, 0.2, 1 }))
manaLit.blendMode = "ADD"
manaLit.triggers = F.triggers({ manaPctTrigger("<=", MANA_CONSERVE_PCT) })
manaLit.load.use_combat = true   -- drinking after a pull is not a rotation decision
manaLit.load.use_spellknown = true   -- v3: Arcane only, with the line it lights
manaLit.load.spellknown = 12042
manaLit.animation.start  = F.animPreset("shrink", "0.25", "easeOut")  -- WA "shrink" = UI "Grow"
manaLit.animation.finish = F.animPreset("fade", "0.2")

-- Burn windows. A cooldown trigger reports the 3 min recharge, never the 15/20 s window, so
-- v1 had no clock on the burst itself. Buff auras give the real one: Arcane Power 12042
-- (15 s) left of the shared slot, Icy Veins 12472 (20 s) right of it. Arcane Power glows in
-- its last 5 s — that is the Presence of Mind + Arcane Blast finisher cue.
local apw = reg(F.icon("Mage - Arcane Power Window", CLASS, 34, 34, -48, 0, nil))
apw.triggers = F.triggers({ F.auraTrigger("player", true, { 12042 }) })
apw.subRegions[1] = F.subglow(false, { 1, 0.4, 0.95, 1 })
apw.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
apw.conditions = { F.condition(1, "expirationTime", "<=", "5", "sub.1.glow", true) }
apw.load.use_spellknown = true
apw.load.spellknown = 12042
adopt(gBuffs, apw)

local ivw = reg(F.icon("Mage - Icy Veins Window", CLASS, 34, 34, 48, 0, nil))
ivw.triggers = F.triggers({ F.auraTrigger("player", true, { 12472 }) })
ivw.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
ivw.load.use_spellknown = true
ivw.load.spellknown = 12472
adopt(gBuffs, ivw)

-- Mana gem. Mana Emerald (item 22044, ~2400 mana, 2 min) is free damage the moment it is
-- not overheal: prompt at <70% mana so the restore is never wasted, and only when a gem is
-- actually in the bags (Item Count) — no gem, no nag.
local MANA_EMERALD = 22044
local gem = reg(F.icon("Mage - Mana Gem Prompt", CLASS, 40, 40, 0, 0, nil))
gem.triggers = F.triggers({
  manaPctTrigger("<", 70),
  itemTrigger("Cooldown Progress (Item)", MANA_EMERALD,
    { use_genericShowOn = true, genericShowOn = "showOnReady" }),
  itemTrigger("Item Count", MANA_EMERALD,
    { use_exact_itemName = true, use_count = true, count = "1", count_operator = ">=" }),
})
gem.iconSource = 0
gem.displayIcon = "Interface\\Icons\\INV_Misc_Gem_Stone_01"
gem.cooldown = false
gem.subRegions[1] = F.subglow(true, { 0.35, 0.95, 0.55, 1 })
gem.load.use_combat = true
alertAnims(gem)
adopt(gAlerts, gem)

-- Shatter window. Ice Lance (30455) does triple damage into a frozen target, so the freeze
-- is the only reactive decision Frost has outside a raid: Frost Nova (all 5 ranks), the
-- Frostbite root and the Water Elemental's Freeze all open it. NOT ownOnly on purpose — the
-- pet's Freeze and a partner's Nova freeze your target just as well. The swipe and %p run
-- off the debuff, so the icon is also the window clock.
local FROZEN = { 122, 865, 6131, 10230, 27088, 12494, 33395 }
local shatter = reg(F.icon("Mage - Ice Lance SHATTER", CLASS, 40, 40, 0, 0, nil))
shatter.triggers = F.triggers({
  F.auraTrigger("target", false, FROZEN),
  F.cdTrigger(30455, "Ice Lance", "showOnReady"),
})
shatter.iconSource = 0
shatter.displayIcon = "Interface\\Icons\\Spell_Frost_FrostBlast"
shatter.subRegions[1] = F.subglow(true, { 0.55, 0.9, 1, 1 })
shatter.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
shatter.load.use_combat = true
shatter.load.use_spellknown = true
shatter.load.spellknown = 30455
-- v3: hidden from deep Arcane. Ice Lance is trained at 66 by EVERY mage, so the positive
-- gate above scopes the levelling case but not the spec: 40/0/21 Arcane loaded a prompt it
-- never acts on. Its rotation is Arcane Blast with Frostbolt as the mana filler, and the
-- guides say outright that Arcane uses neither Ice Lance nor Frost Nova/shatter combos —
-- it also has neither Frostbite nor the Water Elemental, so two of the three ways the
-- window opens do not exist for it. Frost keeps the prompt: Ice Lance into a frozen target
-- is its one reactive button outside a raid.
-- Inverse gate: there is no negated form of `spellknown` (use_spellknown = false means
-- IGNORE, not "must not know"), so WA exposes a separate `not_spellknown` arg — verified
-- in Prototypes.lua's load prototype: test = "not WeakAuras.IsSpellKnownForLoad(%s, %s)".
--   * needs WeakAuras 5.4.0+; on an older client the unknown field is ignored and the
--     prompt simply loads for everyone (the v2 behaviour), so it degrades gracefully.
--   * do NOT set use_exact_not_spellknown: with `exact` falsy, IsSpellKnownForLoad
--     resolves a rank-1 id through the spell name to whatever rank the player has.
--   * 12042 (Arcane Power) is a true discriminator, not a shallow dip: it is the 31-point
--     Arcane capstone, so no Frost build can reach it while keeping deep Frost.
shatter.load.use_not_spellknown = true
shatter.load.not_spellknown = 12042
alertAnims(shatter)
adopt(gAlerts, shatter)

-- ===== v4 additions: the PvP layer ==========================================
-- NEW auras only from here down, appended after the whole v2/v3 uid stream: the 32
-- existing auras keep their uid, so a re-import still offers "Update".
--
-- EVERYTHING below is gated on Instance Size Type, so a PvE player sees no change at all:
--   PVP   = arena OR battleground
--   ARENA = arena only, for anything that reads arena1..arena5 — those unit ids do not
--           exist in a battleground, where such an element would be a permanently blank slot
-- `use_size = false` is not "off": multiselect load args are inert only at nil; false
-- selects MULTI mode, which ORs the listed instance types. Load is per aura on purpose —
-- a group's load is not a child gate, and per-child gates are what let the dynamic groups
-- collapse their gaps.
--
-- Deliberately NOT built (each would be a lie, not a feature):
--   * diminishing returns. WeakAuras has no DR prototype and no bundled DR library, so any
--     DR read-out here would be a hand-rolled 18 s timer that models the reset window rather
--     than the category state — wrong the moment two spells share a category, and worse than
--     nothing because it gets trusted. The Polymorph row below is a plain remaining-duration
--     timer on MY OWN poly and nothing more.
--   * "only show casts I can interrupt". WeakAuras disables the Cast prototype's
--     interruptible arg on TBC clients outright (enable = not IsTBC()), so emitting it does
--     nothing; the prompt is built from "target is casting" AND "Counterspell is usable".
--   * enemy cooldown reads and enemy spec detection. No 2.5.x API exposes either. The enemy
--     trinket row is an inference started by SEEING the cast, not a read.
--   * hiding the threat bar/flash inside arena — DONE IN v5, see NOT_ARENA. v4 left it out
--     because WeakAuras only assigns `size = Type` inside `if inInstance or instanceType ~=
--     "none"`, so the open-world value was unproven and the gate risked unloading the bars
--     everywhere outdoors. It does not: that block is a guard, and the function's final line
--     returns the literal "none" for the not-in-an-instance case, which the gate lists.
local function pvpLoad(arenaOnly)
  local l = F.load(CLASS, { use_size = false })
  l.size = arenaOnly and { multi = { arena = true } }
                      or { multi = { arena = true, pvp = true } }
  return l
end

-- The PvP column: state read-outs, mirroring the Alerts column on the other side of the
-- character (Alerts sits at -150 and grows up; this sits at +150 and grows down). It must
-- be a dynamic group — two of its children are clone sources, one row per arena opponent,
-- and clones inside a static group stack on a single spot.
local gPvP = reg(F.dynGroup("Mage - PvP", 150, 96, nil, "DOWN", "TOP", 6))
adopt(top, gPvP)

-- CC ON ME. Which break works is the decision, not "am I CC'd": root -> Blink (Blink breaks
-- roots, never stuns), stun -> trinket, fear -> trinket, polymorph -> ride it out (any damage
-- breaks it), school lockout -> Ice Block / Nova / Barrier are all Frost and all gone, so
-- trinket EARLIER than you would otherwise. The Crowd Controlled trigger is the only
-- non-custom-code way to see this generically with a real duration, and the only way to see
-- a Counterspell/Kick school lockout at all (a lockout is not an aura, so no aura trigger can
-- ever find it). Colour carries the category and %p the countdown — under a stun a player
-- parses colour, never text. No combat gate: the opener Sap lands out of combat.
--
-- v5 re-verified the colour-coding below against the WeakAuras source rather than by
-- inspection, because three separate things have to hold for it to be anything but a no-op:
--   1. "sub.1" is POSITIONAL — Conditions.lua builds the key from ipairs(data.subRegions), so
--      it resolves to the subglow only while the subglow is subRegions[1]. Never insert a
--      subregion ahead of it; append, exactly as wa_factory.lua already warns.
--   2. useGlowColor must be true. SetGlowColor only stores the value; SetVisible passes it to
--      LibCustomGlow behind `if self.useGlowColor then color = self.glowColor end`, so with it
--      false the setter runs and the screen never changes. F.subglow sets it whenever a colour
--      is passed — which is why the base colour below is given explicitly, not left to default.
--   3. the glow must be on (SetGlowColor's restart is guarded by `if self.glow`), which the
--      `true` below does unconditionally.
-- The value shape matters too: property type "color" is emitted as {v[1],v[2],v[3],v[4]} and
-- expanded to four positional args, so these MUST be 4-element arrays — an {r=,g=,b=,a=} hash
-- would serialise to four nils. controlType carries store = true in the prototype, so it is a
-- state variable even without use_controlType, and the comparison is against the raw API key
-- ("STUN"), never a localised label.
local ccme = reg(F.icon("Mage - CC ON ME", CLASS, 44, 44, 0, 0, nil))
ccme.triggers = F.triggers({ { type = "unit", event = "Crowd Controlled" } })
ccme.cooldown = false
ccme.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })   -- red default = "trinket food"
ccme.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
ccme.conditions = {
  F.condition(1, "controlType", "==", "STUN", "sub.1.glowColor", { 1, 0.15, 0.15, 1 }),
  F.condition(1, "controlType", "==", "STUN_MECHANIC", "sub.1.glowColor", { 1, 0.15, 0.15, 1 }),
  F.condition(1, "controlType", "==", "FEAR", "sub.1.glowColor", { 0.7, 0.3, 1, 1 }),
  F.condition(1, "controlType", "==", "FEAR_MECHANIC", "sub.1.glowColor", { 0.7, 0.3, 1, 1 }),
  F.condition(1, "controlType", "==", "CONFUSE", "sub.1.glowColor", { 0.4, 0.95, 0.5, 1 }),
  F.condition(1, "controlType", "==", "ROOT", "sub.1.glowColor", { 0.3, 0.7, 1, 1 }),
  F.condition(1, "controlType", "==", "SILENCE", "sub.1.glowColor", { 1, 0.85, 0.2, 1 }),
  F.condition(1, "controlType", "==", "PACIFYSILENCE", "sub.1.glowColor", { 1, 0.85, 0.2, 1 }),
  F.condition(1, "controlType", "==", "SCHOOL_INTERRUPT", "sub.1.glowColor", { 1, 0.85, 0.2, 1 }),
}
ccme.load = pvpLoad(false)
alertAnims(ccme)
adopt(gAlerts, ccme)

-- COUNTERSPELL NOW. The highest-value press a mage owns: 8 s school lockout on a 24 s
-- cooldown, and a healer locked out of Holy for 8 s is a kill window with zero CC spent.
-- Three triggers ANDed: target is casting, Counterspell is genuinely castable (Action Usable
-- folds cooldown + mana into one boolean, so the prompt is never a lie), and the target is
-- hostile (aura/unit triggers do no hostility filtering of their own — that is a separate
-- Unit Characteristics trigger). No spell whitelist: interruptibility does not exist on TBC
-- and an id list of every enemy heal is unmaintainable, so junk casts are the player's read.
-- The prompt simply does not exist while Counterspell is down, which is what stops it
-- training the player to ignore it. Desaturates when the target is out of the 30 yd range.
local csnow = reg(F.icon("Mage - COUNTERSPELL NOW", CLASS, 44, 44, 0, 0, nil))
csnow.triggers = F.triggers({
  { type = "unit", event = "Cast", unit = "target", use_unit = true },
  { type = "spell", event = "Action Usable", use_spellName = true, spellName = 2139,
    use_exact_spellName = true, use_ignoreoverride = true },
  { type = "unit", event = "Unit Characteristics", unit = "target", use_unit = true,
    use_hostility = true, hostility = "hostile" },
})
csnow.iconSource = 0
csnow.displayIcon = "Interface\\Icons\\Spell_Frost_IceShock"
csnow.subRegions[1] = F.subglow(true, { 1, 0.85, 0.2, 1 })
csnow.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")   -- remaining cast time
csnow.conditions = { F.condition(2, "spellInRange", "==", 0, "desaturate", true) }
csnow.load = pvpLoad(false)
csnow.load.use_spellknown = true
csnow.load.spellknown = 2139
alertAnims(csnow)
adopt(gAlerts, csnow)

-- TARGET IMMUNE. Everything a mage does is a spell, so casting into one of these burns the
-- whole burst for zero: Ice Block (45438), Divine Shield (642/1020), Cloak of Shadows
-- (31224, 90% spell resist), Spell Reflection (23920, your next spell comes back at you),
-- Bestial Wrath (19574) and The Beast Within (34471), which make the target uncontrollable
-- so Polymorph and Nova are wasted too. Stop, re-pool, swap, or wait it out.
-- Trimmed from the shared list on purpose: Blessing of Protection (physical immunity only —
-- Frostbolt lands through it) and Deterrence (dodge/parry, does nothing to spells) change
-- no mage decision, and a prompt that fires when nothing is decidable is noise.
local IMMUNE = { 45438, 642, 1020, 31224, 23920, 19574, 34471 }
local immune = reg(F.icon("Mage - TARGET IMMUNE", CLASS, 44, 44, 0, 0, nil))
immune.triggers = F.triggers({
  F.auraTrigger("target", true, IMMUNE),   -- any caster: it is the target's state that matters
  { type = "unit", event = "Unit Characteristics", unit = "target", use_unit = true,
    use_hostility = true, hostility = "hostile" },
})
immune.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
immune.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
immune.load = pvpLoad(false)
alertAnims(immune)
adopt(gAlerts, immune)

-- TRINKET DOWN. The one question the medallion asks is "is my get-out-of-jail available",
-- so this is visible ONLY while it is on cooldown — absence means ready, and the column
-- stays empty in the normal case. Desaturated with the swipe running, i.e. it reads as
-- unavailable at a glance. Exact item ids, never the equipment slot: the slot trigger tracks
-- whatever sits in slot 13/14, so a PvE on-use trinket would report "medallion down" while
-- it is actually ready, and that false negative is a death in this exact decision. The pack
-- is class-gated to MAGE, so the class-specific Insignias reduce to two ids.
local PVP_TRINKETS = {
  37864,   -- Medallion of the Alliance (TBC honor, 2 min)
  37865,   -- Medallion of the Horde     (TBC honor, 2 min)
  18859,   -- Insignia of the Alliance (Mage, 5 min)
  18850,   -- Insignia of the Horde    (Mage, 5 min)
}
local trinketTrigs = {}
for i, id in ipairs(PVP_TRINKETS) do
  trinketTrigs[i] = itemTrigger("Cooldown Progress (Item)", id,
    { use_genericShowOn = true, genericShowOn = "showOnCooldown" })
end
local trink = reg(F.icon("Mage - Trinket DOWN", CLASS, 32, 32, 0, 0, nil))
trink.triggers = F.triggers(trinketTrigs, { disjunctive = "any" })   -- whichever one you wear
trink.cooldownTextDisabled = false   -- swipe numbers; no %p subtext (OmniCC would double it)
trink.desaturate = true
trink.load = pvpLoad(false)
adopt(gPvP, trink)

-- WILL OF THE FORSAKEN DOWN. On 2.4.3 WotF does NOT share a cooldown with the medallion
-- (that arrived in 3.3), so an Undead mage genuinely carries two charges and whether the
-- second is up changes whether the first gets spent. Gated on the ability, not the race.
local wotf = reg(F.icon("Mage - Will of the Forsaken DOWN", CLASS, 32, 32, 0, 0, nil))
wotf.triggers = F.triggers({ F.cdTrigger(7744, "Will of the Forsaken", "showOnCooldown") })
wotf.cooldownTextDisabled = false
wotf.desaturate = true
wotf.load = pvpLoad(false)
wotf.load.use_spellknown = true
wotf.load.spellknown = 7744
adopt(gPvP, wotf)

-- ENEMY TRINKET. Their trinket down for two minutes is when the real Polymorph chain goes
-- in; a one-shot "they trinketed!" flash without the countdown changes nothing. One clone
-- per opponent (unit = "arena" => clones, hence the dynamic-group parent). This is an
-- INFERENCE, not a read: no 2.5.x API exposes another player's cooldowns, so the timer
-- starts when the trinket cast is SEEN. Arena-only — arena1..5 do not exist in a BG.
local etrink = reg(F.icon("Mage - Enemy Trinket", CLASS, 32, 32, 0, 0, nil))
etrink.triggers = F.triggers({
  { type = "event", event = "Spell Cast Succeeded", unit = "arena", use_unit = true,
    use_spellId = true, spellId = { "42292" },   -- "PvP Trinket", cast by both medallions
    duration = "120" },                          -- REQUIRED on timed events; medallion CD
})
etrink.cooldownTextDisabled = false
etrink.load = pvpLoad(true)
adopt(gPvP, etrink)

-- COUNTERSPELL LOCKOUT. The eight seconds bought by the interrupt, which is the go: burn
-- Icy Veins / Water Elemental / Arcane Power now and do NOT spend Polymorph on a healer who
-- cannot cast anyway. A lockout is not an aura, so the only way to see it is the combat log
-- event plus a duration supplied here (Counterspell 8 s, verified). sourceUnit = player, so
-- a partner's interrupt does not light my bar.
local lockout = reg(F.aurabar("Mage - CS LOCKOUT", CLASS, 140, 12, 0, 0, nil,
  { 0.4, 0.85, 1, 1 }))
lockout.triggers = F.triggers({
  F.clogTrigger("SPELL", "_INTERRUPT", "8", {
    use_sourceUnit = true, sourceUnit = "player",
    use_spellId = true, spellId = { "2139" },
  }),
})
lockout.subRegions[2] = F.subtext("%p", 12, "INNER_RIGHT")
lockout.subRegions[3] = F.subborder("bar")
lockout.load = pvpLoad(false)
lockout.load.use_spellknown = true
lockout.load.spellknown = 2139
adopt(gPvP, lockout)

-- MY POLYMORPH, per opponent. Two decisions at once: do not touch that unit (any damage
-- breaks it and the sheep regenerates ~6% HP/sec, so hitting it hands the healer free
-- health), and the countdown is exactly the window the rest of the team has to work in.
-- ownOnly, so another mage's sheep never shows here. All four ranks plus the Turtle and Pig
-- variants. Glows in the last 3 s: re-poly now or the healer is free. Arena-only clones.
local POLYMORPH = { 118, 12824, 12825, 12826, 28271, 28272 }
local poly = reg(F.icon("Mage - Polymorph OUT", CLASS, 36, 36, 0, 0, nil))
poly.triggers = F.triggers({
  F.auraTrigger("arena", false, POLYMORPH,
    { ownOnly = true, showClones = true, combinePerUnit = true, perUnitMode = "affected" }),
})
poly.subRegions[1] = F.subglow(false, { 0.85, 0.5, 1, 1 })
poly.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
poly.conditions = { F.condition(1, "expirationTime", "<=", "3", "sub.1.glow", true) }
poly.load = pvpLoad(true)
adopt(gPvP, poly)

-- ===== v5 additions: enemy mana =============================================
-- ONE new aura, appended after the whole v4 uid stream: the 41 existing auras keep their uid,
-- so a re-import still offers "Update". The two other v5 changes are load gates on the threat
-- bar and threat flash (see NOT_ARENA), which move no uid.

-- ENEMY MANA, one bar per opponent. A mage does not drain mana, but the mage plays the mana
-- clock harder than anyone: Counterspell exists to keep a healer from spending it, Polymorph
-- exists to stop them drinking it back, and the whole decision "keep applying pressure vs.
-- commit the burst now" is a read on how much the enemy healer has left. A single number the
-- team can call out is worth more than another cooldown icon.
--   * unit = "arena" clones — one row per opponent — hence the dynamic-group parent.
--   * use_powertype + powertype = 0 are BOTH required to read MANA specifically. Drop either
--     and powerType is nil, the trigger falls back to UnitPowerType(unit), and the row happily
--     reports a rogue's energy as if it were mana.
--   * use_requirePowerType hides every opponent whose PRIMARY bar is not mana, so warriors and
--     rogues (who have no mana pool at all on TBC, i.e. a 0/0 bar that reads as "empty = go")
--     never take a row. The honest cost: a druid in bear or cat form drops off the list until
--     they shift back, because their primary bar is rage/energy while shifted.
--   * arena-only, never arena+pvp: arena1..arena5 do not exist in a battleground, where this
--     would be permanently blank rows.
local emanaTrig = F.powerTrigger(0)
emanaTrig.unit = "arena"
emanaTrig.use_requirePowerType = true
local emana = reg(F.aurabar("Mage - Enemy Mana", CLASS, 140, 12, 0, 0, nil,
  { 0.25, 0.50, 0.95, 1 }))
emana.triggers = F.triggers({ emanaTrig })
emana.subRegions[2] = F.subtext("%name", 10, "INNER_LEFT")
emana.subRegions[3] = F.subtext("%percentpower%%", 12, "INNER_RIGHT", "percentpower")
emana.subRegions[4] = F.subborder("bar")
-- Two tiers, same escalation idiom as the health bar: amber = they are running low, so deny
-- the drink and keep them casting; green = they are out, which is the kill window. Severe
-- tier last, because a later matching condition overwrites the same property.
emana.conditions = {
  F.condition(1, "percentpower", "<=", "30", "barColor", { 1, 0.85, 0.2, 1 }),
  F.condition(1, "percentpower", "<=", "10", "barColor", { 0.35, 0.95, 0.55, 1 }),
}
emana.load = pvpLoad(true)
adopt(gPvP, emana)

-- ===== v14 assembly: ONE strip, the same six uid slots, and the stream held still =====
-- TWO regions are created here where v11 created six, and the four uid slots that v12 freed are
-- still RETIRED IN PLACE rather than reused. That is the whole trick of this migration, and it
-- is worth being explicit about both halves:
--
--   1. WHAT IS GONE, and why it is not replaced by anything. The target cluster group, the
--      target's health ring, its portrait and the outer track that v11 invented purely to keep
--      an eleventh uid alive. Target health is already on the target frame and the nameplate,
--      so those regions duplicated the default UI for the entire game. The temptation at this
--      point is to invent a region to absorb each freed uid — that is exactly what v11 did with
--      the track, and it is how a HUD accumulates junk. v12 declines: the slots are drawn from
--      the stream and thrown away (see below), which costs four uids and buys a HUD with
--      nothing in it that does not change a decision.
--
--   2. WHY THE DISCARDED CALLS STILL HAPPEN. math.random is a stream, not a dictionary: the Nth
--      W.uid() call returns the Nth value regardless of who asks. Deleting a call therefore
--      shifts every uid AFTER it by one position, which would silently re-uid every surviving
--      aura downstream and turn the in-game Update into 40-odd duplicates. So the four calls are
--      still made, in their exact original positions, and their results are discarded. Only
--      gSill (slot 1) and pPlate (slot 3) are consumed, and both get the value they got in v11.
--      Future versions append after ALL SIX slots, so a new aura can never inherit the uid of a
--      region a player may still have sitting in their collection.
--
--   uid slot   v11 aura                    v14
--     1        Mage - Player Cluster    -> Mage - Player Sill      (renamed, moved to (0,-110))
--     2        Mage - Target Cluster    -> RETIRED (since v12)
--     3        Mage - Player Portrait   -> Mage - Sill Plate       (model -> texture, 102x37)
--     4        Mage - Target Health Ring-> RETIRED (since v12)
--     5        Mage - Target Ring Track -> RETIRED (since v12)
--     6        Mage - Target Portrait   -> RETIRED (since v12)
--
-- EVERY OTHER SURVIVOR IS RESHAPED IN PLACE, in the slot it has held since v6: the health, mana
-- and threat bars-turned-rings-turned-globes-turned-rings become rails; the threat flash becomes
-- the alarm frame; the two conserve beads become waterlines; and the Arcane Blast stack icon,
-- created up in the buff row's slot, becomes the arcane lane. Not one of them changes uid, and
-- not one uid() call moves.
--
-- CHILD ORDER IS THE STACKING ORDER: FixGroupChildrenOrder walks controlledChildren and adds
-- +4 frame levels per entry, so EARLIER = further behind. sharedFrameLevel is deliberately left
-- off the sill group: it would zero the level offset and make the overlap order ambiguous.
--
-- v13 moved the portrait from last to FIRST so the rings' text could print on it. v14 keeps that
-- position and makes it structural: the region in that slot is now the PLATE, and everything in
-- the instrument is read against it — with the ALARM RIM one place further back still.
--
--   v11/v12:  threat, health, mana, beads, flare, PORTRAIT   <- face on top of everything
--   v13:      PORTRAIT, threat, health, mana, beads, flare   <- face behind everything
--   v14:      ALARM RIM, PLATE, threat, health, mana, waterlines, arcane lane
--
-- WHY THIS ORDER, lane by lane. The ALARM RIM is first because it is a FILLED 108x43 quad, not an
-- outline (measured; see the texture note at the top of the file). Anywhere else in this list it
-- covers what it is warning about in additive red. At the bottom of the stack, oversized by 3px
-- per side, the only part of it that can be seen is the band protruding past the plate — so it
-- rings the instrument instead of flooding it, and every readout draws over it. The plate is
-- second: it is opaque, so anything before it is hidden (which is the point for the rim) and
-- anything after it is legible. The three rails do not overlap each other at all (the lane
-- arithmetic gives every pair a 1px gutter), so their relative order is free and they are listed
-- top to bottom simply because that is how the instrument reads. The two conserve waterlines MUST
-- come after the mana rail they cross, or the rail's own fill is drawn over them and the
-- breakpoint disappears exactly when mana is near it.
-- THE SIZE AND THE ORDER ARE ONE MECHANISM. +6px with the rim drawn last is a wash; cc[1] at the
-- plate's own size is invisible. Post-build assert 2b pins both halves against the decoded
-- string, so dropping either fails the build instead of shipping.
--
-- Reordering and re-parenting are controlledChildren edits ONLY. They consume no uid and move no
-- uid() call — every region is still CREATED in its original position in the stream above, and
-- only its adopt() call moves — so every uid is unchanged and the in-game Update flow is
-- unaffected. F.assemble derives the flat c-list depth-first from controlledChildren, so the
-- transmit's two orderings cannot drift apart here; W.verify enforces that they agree, and the
-- geometry proof at the bottom re-reads both out of the DECODED string.
local gSill = reg(F.group("Mage - Player Sill", SILL_LOCAL_X, SILL_LOCAL_Y, nil))
adopt(gLayer, gSill)

-- RETIRED UID SLOT 2 — "Mage - Target Cluster". Consumed and discarded; see (2) above.
W.uid()

-- THE SILL PLATE, in the portrait's uid slot. It carries the same two triggers the portrait did,
-- so the whole instrument fades out of combat instead of sitting at full brightness, and it
-- disappears if max health ever reads zero. `alpha` is a region-prototype property, valid on
-- every region type, so both conditions are live here rather than silent no-ops. The two
-- conditions and both triggers are byte-identical to v13's portrait; the region type, the size
-- and the texture are what changed.
local pPlate = reg(plate("Mage - Sill Plate", SILL_W, SILL_H, COL.plate,
  { unitHealthTrigger("player"), F.unitCharTrigger() }))
pPlate.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

-- RETIRED UID SLOTS 4, 5 and 6 — "Mage - Target Health Ring", "Mage - Target Ring Track" and
-- "Mage - Target Portrait", in their original creation order. Nothing consumes them. They are
-- still drawn so that anything a future version appends starts at slot 7 and cannot collide with
-- a uid a player still has installed under the old target cluster.
W.uid()
W.uid()
W.uid()

-- THE SILL: the alarm rim underneath everything, then the plate, then the lanes top to bottom,
-- with the waterlines over the rail they mark. This list IS the z-order.
adopt(gSill, flash)         -- 1  the alarm rim, 108x43 — 3px proud of the plate, and BEHIND it
adopt(gSill, pPlate)        -- 2  the slab everything is read against; it hides the rim's middle
adopt(gSill, threatRail)    -- 3  lane 1, 100x4  @ +15.5
adopt(gSill, hpRail)        -- 4  lane 2, 100x11 @ +7
adopt(gSill, mpRail)        -- 5  lane 3, 100x11 @ -5
adopt(gSill, manaLine)      -- 6  the 30% conserve waterline, over the mana rail
adopt(gSill, manaLit)       -- 7  ...and its lit twin, over that
adopt(gSill, ab)            -- 8  lane 4, 100x6  @ -14.5 (Arcane Blast stacks + window)

-- ===== icon polish everywhere ===============================================
for _, aura in ipairs(order) do
  if aura.regionType == "icon" then polishIcon(aura) end
end

-- ===== assemble (v2000 nested), encode, verify, write =======================
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

-- ===== v14 GEOMETRY PROOF, against the DECODED string ========================
-- Through v13 this pack asserted its geometry in prose, and every migration that did so drifted.
-- These checks read the string that is about to ship, sum the parent chain themselves and fail
-- the build if the instrument is not exactly what this file claims. They are the RAIL canon,
-- rewritten from the ring canon they replace (orientation == "CLOCKWISE", width == height ==
-- <diameter>, foregroundTexture == Ring_20px, concentric offsets) — rewritten rather than
-- deleted, because a geometry change that ships silently wrong is the exact failure this repo
-- has spent six versions learning to catch. tools/verify-rebuild.sh re-runs this script, so the
-- proof is re-executed on every suite run rather than trusted from a header.
--
-- THE CANON IS WRITTEN AS LITERALS, AND THAT IS THE WHOLE POINT OF THIS TABLE. v14 first shipped
-- a proof block that compared the decoded string against the constants that had just produced it
-- — `assert(n.width == RAIL_LEN)` where RAIL_LEN is what set n.width, and `assert(sy == SILL_Y)`
-- where SILL_LOCAL_Y is derived from SILL_Y. Both are tautologies: editing the single constant
-- moves the string AND the expectation together, and the build passes. Measured, four one-token
-- sabotages sailed through it: RAIL_LEN 100->96, SILL_W 102->96, SILL_Y -110->-21, PCT_X 32->20.
-- CANON is the independent second opinion. Every number the design PROMISES appears here once,
-- as a literal, and is compared against BOTH the tunable constant above and the value decoded out
-- of the shipped string — so a constant edit fails at the constant, and a hand-edited string
-- fails at the string. Change a number here only by changing the design in all seven packs.
local CANON = {
  absX     = 0,     absY    = -110,   -- where the instrument sits, in SCREEN coordinates
  -- ...and the three hops that add up to it, pinned individually. The sum alone is not enough:
  -- SILL_LOCAL_Y is computed as SILL_Y - TOP_Y - LAYER_Y, so the layer's offset CANCELS out of
  -- the total and can be set to anything without moving the strip one pixel. It still has to be
  -- pinned, because these three numbers are printed as a chain in both READMEs and an unpinned
  -- number in a published diagram is a number that goes stale.
  chainTop = -140,  chainLayer = 180, chainSill = -150,
  rail     = 100,                     -- one pixel is one percent; this is the whole design
  plateW   = 102,   plateH  = 37,     -- rail + 1px margin each side; lane stack + 1px top/bottom
  rim      = 3,                       -- how far the alarm protrudes past the plate, per side
  alarmW   = 108,   alarmH  = 43,     -- plate + 2 * rim. The rim IS the alarm; see assert 2b
  margin   = 1,     gutter  = 1,      -- plate margin, and the gap between adjacent lanes
  hThreat  = 4,     hHealth = 11,     hPower = 11,   hLane  = 6,
  yThreat  = 15.5,  yHealth = 7,      yPower = -5,   yLane  = -14.5,
  pctX     = 32,    pctSize = 11,     -- the health and mana numbers, inside their own rails
  notchX   = 20,                      -- threat 70  ->  70 - 50
  conserveX = -20,                    -- mana   30  ->  30 - 50
  rulerX   = { -25, 0, 25 },          -- quarter hairlines
  pipX     = { -20, 0, 20 },          -- arcane stack pips
  threatPctAbsY = -84,                -- the switched-off threat number, if a user turns it on
  scanDepth = 6,                      -- minimum projection depth for a dynamic group
}
-- The z-order, bottom to top. The alarm rim is cc[1] and the plate cc[2]; both positions are
-- load-bearing and assert 2b names them individually rather than trusting this list.
local SILL_CHILDREN = {
  "Mage - Alarm Frame", "Mage - Sill Plate", "Mage - Threat Rail", "Mage - Health Rail",
  "Mage - Mana Rail", "Mage - Mana Conserve Line", "Mage - Mana Conserve Lit",
  "Mage - Arcane Lane",
}
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

  -- 0) THE CONSTANTS THEMSELVES, against the canon literals. This runs first so that a one-token
  --    edit above fails HERE, naming the constant, instead of surfacing thirty asserts later as a
  --    decoded number that disagrees with a number nobody can trace. It is also the only place
  --    the DERIVED relationships are stated as arithmetic rather than as a comment:
  --      * the plate is the rail plus one pixel of margin on each side, so a plate can never
  --        again end up NARROWER than the rails it is supposed to be backing;
  --      * the plate's height is the lane stack plus its gutters plus its margins, added up
  --        rather than asserted, so adding a lane without growing the plate cannot pass.
  local function mustBe(name, got, expect)
    assert(got == expect, ("canon: %s is %s, expected %s (change the design, not the constant)")
      :format(name, tostring(got), tostring(expect)))
  end
  mustBe("SILL_X", SILL_X, CANON.absX)          mustBe("SILL_Y", SILL_Y, CANON.absY)
  mustBe("RAIL_LEN", RAIL_LEN, CANON.rail)      mustBe("SILL_W", SILL_W, CANON.plateW)
  mustBe("SILL_H", SILL_H, CANON.plateH)        mustBe("H_THREAT", H_THREAT, CANON.hThreat)
  mustBe("H_HEALTH", H_HEALTH, CANON.hHealth)   mustBe("H_POWER", H_POWER, CANON.hPower)
  mustBe("H_LANE", H_LANE, CANON.hLane)         mustBe("Y_THREAT", Y_THREAT, CANON.yThreat)
  mustBe("Y_HEALTH", Y_HEALTH, CANON.yHealth)   mustBe("Y_POWER", Y_POWER, CANON.yPower)
  mustBe("Y_LANE", Y_LANE, CANON.yLane)         mustBe("PCT_X", PCT_X, CANON.pctX)
  mustBe("PCT_SIZE", PCT_SIZE, CANON.pctSize)
  mustBe("SILL_W (as RAIL_LEN + 2 * margin)", SILL_W, CANON.rail + 2 * CANON.margin)
  mustBe("SILL_H (as the lane stack + 3 gutters + 2 margins)", SILL_H,
    CANON.hThreat + CANON.hHealth + CANON.hPower + CANON.hLane + 3 * CANON.gutter
    + 2 * CANON.margin)
  mustBe("railX(70)", railX(70, 100), CANON.notchX)
  mustBe("railX(30)", railX(MANA_CONSERVE_PCT, 100), CANON.conserveX)
  mustBe("RIM", RIM, CANON.rim)
  mustBe("ALARM_W", ALARM_W, CANON.alarmW)      mustBe("ALARM_H", ALARM_H, CANON.alarmH)
  mustBe("ALARM_W (as SILL_W + 2 * RIM)", ALARM_W, CANON.plateW + 2 * CANON.rim)
  mustBe("ALARM_H (as SILL_H + 2 * RIM)", ALARM_H, CANON.plateH + 2 * CANON.rim)

  -- 1) THE STRIP IS AT (0, -110), walked from the real parent chain and compared with the CANON
  --    LITERAL, not with SILL_Y. top (0, -140) + layer (0, 180) + sill (0, -150) = (0, -110).
  --    SILL_LOCAL_Y is computed from SILL_Y, so `sy == SILL_Y` could never have caught a moved
  --    strip; `sy == -110` does, and check 0 above catches the constant on the way past.
  local sx, sy = absolute("Mage - Player Sill")
  assert(sx == CANON.absX and sy == CANON.absY,
    ("geometry proof: the sill is at (%s, %s), expected (%d, %d)")
      :format(tostring(sx), tostring(sy), CANON.absX, CANON.absY))
  assert(nodes["Mage - Player Sill"].parent == "Mage - Sill Layer"
    and nodes["Mage - Sill Layer"].parent == back.d.id,
    "geometry proof: the sill no longer hangs top -> layer -> sill")
  --    ...and each hop of that chain, individually, because both READMEs print the sum as
  --    `top (0, -140) + layer (0, +180) + sill (0, -150)`. The layer's offset cancels out of the
  --    total, so only a per-hop check can keep the published arithmetic true.
  for _, hop in ipairs({
    { id = back.d.id,             y = CANON.chainTop,   name = "the top group" },
    { id = "Mage - Sill Layer",   y = CANON.chainLayer, name = "the sill layer" },
    { id = "Mage - Player Sill",  y = CANON.chainSill,  name = "the sill group" },
  }) do
    assert(nodes[hop.id].xOffset == 0 and nodes[hop.id].yOffset == hop.y,
      ("geometry proof: %s is at local (%s, %s), expected (0, %s)"):format(hop.name,
        tostring(nodes[hop.id].xOffset), tostring(nodes[hop.id].yOffset), tostring(hop.y)))
  end
  assert(CANON.chainTop + CANON.chainLayer + CANON.chainSill == CANON.absY,
    "geometry proof: the published chain does not add up to the published position")

  -- 2) THE RAIL CANON. Every lane is a LINEAR progresstexture on flat white art, 100px long
  --    because one pixel is one percent, at the lane offset this file declares — and each one
  --    lands at the absolute y its lane implies, which is the check that catches a group offset
  --    and a lane offset drifting in opposite directions.
  --    Every number compared below is a CANON literal, never the constant that produced it.
  local LANES = {
    { id = "Mage - Threat Rail", h = CANON.hThreat, y = CANON.yThreat },
    { id = "Mage - Health Rail", h = CANON.hHealth, y = CANON.yHealth },
    { id = "Mage - Mana Rail",   h = CANON.hPower,  y = CANON.yPower  },
    { id = "Mage - Arcane Lane", h = CANON.hLane,   y = CANON.yLane   },
  }
  for _, want in ipairs(LANES) do
    local n = assert(nodes[want.id], "geometry proof: no such aura " .. want.id)
    assert(n.regionType == "progresstexture",
      ("rail canon: %s is a %s, not a progresstexture"):format(want.id, tostring(n.regionType)))
    assert(n.orientation == "HORIZONTAL_INVERSE",
      ("rail canon: %s fills %s, not HORIZONTAL_INVERSE (Left to Right)")
        :format(want.id, tostring(n.orientation)))
    assert(n.foregroundTexture == RAIL_TEX and n.backgroundTexture == RAIL_TEX
      and n.sameTexture == true,
      "rail canon: " .. want.id .. " is not drawn on the flat white square, fill and track alike")
    assert(n.backgroundOffset == 0, "rail canon: " .. want.id .. " has a fattened track")
    assert(n.smoothProgress == true, "rail canon: " .. want.id .. " lost smoothProgress")
    assert(n.progressSource[1] == -1 and n.progressSource[2] == "",
      "rail canon: " .. want.id .. " does not take automatic progress from trigger 1")
    assert(n.width == CANON.rail,
      ("rail canon: %s is %s long, expected %d (one pixel is one percent)")
        :format(want.id, tostring(n.width), CANON.rail))
    assert(n.height == want.h,
      ("rail canon: %s is %s tall, expected %d"):format(want.id, tostring(n.height), want.h))
    assert(n.xOffset == 0 and n.yOffset == want.y,
      ("rail canon: %s sits at local (%s, %s), expected (0, %s)")
        :format(want.id, tostring(n.xOffset), tostring(n.yOffset), tostring(want.y)))
    local ax, ay = absolute(want.id)
    assert(ax == CANON.absX and ay == CANON.absY + want.y,
      ("rail canon: %s lands at (%s, %s), expected (%d, %s)")
        :format(want.id, tostring(ax), tostring(ay), CANON.absX, tostring(CANON.absY + want.y)))
  end

  -- 2b) THE PLATE AND THE ALARM RIM: TWO CONCENTRIC RECTANGLES, THE ALARM 6px BIGGER IN BOTH AXES
  --     AND DRAWN FIRST. This assert used to pin something else entirely, and it pinned it on a
  --     false premise, so it is worth recording what it said: it required the plate and the alarm
  --     to be on DIFFERENT ART, because the file claimed Square_White_Border was "an OUTLINE, the
  --     interior is transparent" and called that "not a guess". It was inverted. Decoded from the
  --     client's own file, Square_White_Border.tga is 256x256 32bpp RLE with 64516 of 65536 pixels
  --     (98.44%) at alpha 255; every pixel inset 8px or more has min alpha 255 and min RGB 167
  --     across n = 57600; the centre pixel is rgba(255,255,255,255). It is a FILLED square with a
  --     dark bevel baked into its edge. NO SINGLE REGION ON IT TRACES A HOLLOW EDGE.
  --
  --     So an art check can never make this alarm safe, and v14 proved it: the alarm shipped on
  --     the border art at the plate's own 102x37 with blendMode ADD, LAST in controlledChildren,
  --     and therefore drew a full-area red quad over every rail, every number and every pip
  --     whenever threat >= 80% — washing out the readouts at exactly the moment they matter most.
  --     The art assert passed the whole time.
  --
  --     WHAT ACTUALLY MAKES IT A RIM is geometry plus z-order, and BOTH HALVES ARE PINNED HERE:
  --       * SIZE:  alarm.width == plate.width + 2 * RIM and alarm.height == plate.height + 2 * RIM.
  --                Only the 3px band protruding on each side can be seen.
  --       * ORDER: cc[1] is the alarm and cc[2] is the plate. Everything else in the strip draws
  --                over the alarm, so nothing is composited on top of a readout.
  --     Drop either one and the rim silently becomes a wash again, which is why they are asserted
  --     together, off the decoded string, against CANON literals. The art is deliberately NOT
  --     asserted: this construction is correct whether the texture is filled or hollow.
  local plateN = nodes["Mage - Sill Plate"]
  local alarm  = nodes["Mage - Alarm Frame"]
  local RECTS = {
    { id = "Mage - Sill Plate",  w = CANON.plateW, h = CANON.plateH },
    { id = "Mage - Alarm Frame", w = CANON.alarmW, h = CANON.alarmH },
  }
  for _, want in ipairs(RECTS) do
    local n = nodes[want.id]
    assert(n.regionType == "texture",
      ("rail canon: %s is a %s, not a texture"):format(want.id, tostring(n.regionType)))
    assert(n.width == want.w and n.height == want.h,
      ("rail canon: %s is %sx%s, expected %dx%d")
        :format(want.id, tostring(n.width), tostring(n.height), want.w, want.h))
    assert(n.xOffset == 0 and n.yOffset == 0,
      "rail canon: " .. want.id .. " carries a local offset; the group must carry position")
    local ax, ay = absolute(want.id)
    assert(ax == CANON.absX and ay == CANON.absY,
      ("rail canon: %s lands at (%s, %s), expected (%d, %d) — the rim is only a rim while it is "
        .. "CONCENTRIC with the plate"):format(want.id, tostring(ax), tostring(ay),
        CANON.absX, CANON.absY))
    assert(type(n.color) == "table" and #n.color == 4,
      "rail canon: " .. want.id .. " ships without an explicit 4-component colour")
  end
  --     HALF ONE — THE SIZE, stated as the relationship and not just as two literals, so that a
  --     future edit which grows the plate without growing the rim fails here.
  assert(alarm.width == plateN.width + 2 * CANON.rim,
    ("rim proof: the alarm is %s wide and the plate is %s; a %dpx rim needs plate + %d")
      :format(tostring(alarm.width), tostring(plateN.width), CANON.rim, 2 * CANON.rim))
  assert(alarm.height == plateN.height + 2 * CANON.rim,
    ("rim proof: the alarm is %s tall and the plate is %s; a %dpx rim needs plate + %d")
      :format(tostring(alarm.height), tostring(plateN.height), CANON.rim, 2 * CANON.rim))
  assert(alarm.width > plateN.width and alarm.height > plateN.height,
    "rim proof: the alarm does not protrude past the plate at all, so it can never be seen")
  --     HALF TWO — THE ORDER. cc[1] is the alarm, cc[2] is the plate. Checked here as well as in
  --     the draw-order proof below, because on its own the size check licenses a full-area wash.
  local ccSill = nodes["Mage - Player Sill"].controlledChildren
  assert(ccSill[1] == "Mage - Alarm Frame",
    ("rim proof: cc[1] is %s, not the alarm frame. A FILLED ADD quad anywhere but the bottom of "
      .. "the stack covers the readouts it is warning about"):format(tostring(ccSill[1])))
  assert(ccSill[2] == "Mage - Sill Plate",
    ("rim proof: cc[2] is %s, not the sill plate. The plate is what hides the alarm's middle; "
      .. "without it directly above the alarm, the whole quad shows"):format(tostring(ccSill[2])))
  for i = 3, #ccSill do
    assert(ccSill[i] ~= "Mage - Alarm Frame" and ccSill[i] ~= "Mage - Sill Plate",
      "rim proof: the alarm or the plate appears twice in the draw order")
  end
  --     ...and the alarm's colour and blend are EXPLICIT. A texture that ships `color = {}` draws
  --     in WeakAuras' default, i.e. a white flash where a red alarm was intended, so the check is
  --     on the four numbers rather than on the presence of the field.
  assert(alarm.color[1] == 1 and alarm.color[2] == 0.1 and alarm.color[3] == 0.1
    and alarm.color[4] == 0.85,
    ("rim proof: the alarm is (%s, %s, %s, %s), expected the explicit (1, 0.1, 0.1, 0.85)")
      :format(tostring(alarm.color[1]), tostring(alarm.color[2]), tostring(alarm.color[3]),
        tostring(alarm.color[4])))
  assert(alarm.blendMode == "ADD",
    "rim proof: the alarm frame stopped being additive, so the rim no longer glows")
  --     The plate is BLEND, not ADD: an additive black is a no-op, so a plate that picked up the
  --     alarm's blend mode would draw nothing at all while still passing every size check — and
  --     an invisible plate is an exposed rim, i.e. the wash again by another route.
  assert(plateN.blendMode == "BLEND" and plateN.color[4] > 0 and plateN.color[1] < 0.3
    and plateN.color[2] < 0.3 and plateN.color[3] < 0.3,
    "rail canon: the sill plate is not a BLEND-mode dark slab")

  -- 3) THE LANE STACK, MEASURED EXACTLY. 1 + 4 + 1 + 11 + 1 + 11 + 1 + 6 + 1 = 37: a 1px margin,
  --    four lanes, a 1px gutter between each adjacent pair, a 1px margin. The earlier version of
  --    this check only forbade OVERLAP, which let the gutters collapse to zero silently — the
  --    lanes would touch, the instrument would read as one smeared block, and the build would
  --    still print "0 overlaps". Every gap is now measured against CANON.gutter / CANON.margin,
  --    and the spans are read out of the DECODED string rather than recomputed from the
  --    constants, so a hand-edited string fails here too. The stack is walked top-to-bottom in
  --    declaration order and that order is itself asserted, because "the next lane down" is only
  --    meaningful if the list really is sorted.
  local plateTop, plateBottom = CANON.plateH / 2, -CANON.plateH / 2
  local spans = {}
  for _, want in ipairs(LANES) do
    local n = nodes[want.id]
    spans[#spans + 1] = {
      id = want.id, top = n.yOffset + n.height / 2, bottom = n.yOffset - n.height / 2,
    }
  end
  assert(plateTop - spans[1].top == CANON.margin,
    ("lane stack: the top margin is %s, expected %s")
      :format(tostring(plateTop - spans[1].top), tostring(CANON.margin)))
  assert(spans[#spans].bottom - plateBottom == CANON.margin,
    ("lane stack: the bottom margin is %s, expected %s")
      :format(tostring(spans[#spans].bottom - plateBottom), tostring(CANON.margin)))
  for i = 2, #spans do
    local gap = spans[i - 1].bottom - spans[i].top
    assert(gap == CANON.gutter,
      ("lane stack: the gutter between %s and %s is %s, expected %s (a collapsed gutter is not "
        .. "an overlap, which is why this is measured and not merely tested for intersection)")
        :format(spans[i - 1].id, spans[i].id, tostring(gap), tostring(CANON.gutter)))
  end
  local stacked = CANON.margin * 2 + (#spans - 1) * CANON.gutter
  for _, s in ipairs(spans) do stacked = stacked + (s.top - s.bottom) end
  assert(stacked == CANON.plateH,
    ("lane stack: the lanes, gutters and margins add up to %s in a %s plate")
      :format(tostring(stacked), tostring(CANON.plateH)))

  -- 4) THE SUBREGION CANON, read positionally because conditions address subregions as sub.N.
  --    The threat number is switched OFF and still at index 1; the notch is APPENDED at 2.
  local th = nodes["Mage - Threat Rail"]
  assert(#th.subRegions == 2, "subregion canon: the threat rail should carry the % and the notch")
  assert(th.subRegions[1].type == "subtext" and th.subRegions[1].text_text == "%threatpct%%"
    and th.subRegions[1].text_visible == false,
    "subregion canon: the threat percentage is not a switched-off subtext at index 1")
  assert(th.subRegions[2].type == "subtexture"
    and th.subRegions[2].xOffset == CANON.notchX
    and th.subRegions[2].height == CANON.hThreat and th.subRegions[2].textureVisible == true,
    "subregion canon: the 70 notch is not a full-height mark at x = +20")
  --    ...and WHERE the switched-off number would land if a user ticks Show Text in /wa. A
  --    subtext anchors to its own REGION's centre, so this offset stacks on the threat rail's
  --    +15.5 and not on the group: at the value v14 first shipped it landed 23px above the
  --    instrument, in the open screen the whole design exists to clear. Re-derived here from the
  --    decoded string so the README sentence "it returns just above the plate" stays true.
  local thAbsY = select(2, absolute("Mage - Threat Rail")) + (th.subRegions[1].anchorYOffset or 0)
  assert(thAbsY == CANON.threatPctAbsY,
    ("subregion canon: the threat number would appear at absolute y %s, expected %s")
      :format(tostring(thAbsY), tostring(CANON.threatPctAbsY)))
  assert(thAbsY > CANON.absY + CANON.plateH / 2,
    "subregion canon: the threat number would appear on top of the plate, not above it")
  --    Health and mana: the number at the right-hand end, then the three ruler hairlines.
  for _, want in ipairs({
    { id = "Mage - Health Rail", token = "%percenthealth%%", h = CANON.hHealth },
    { id = "Mage - Mana Rail",   token = "%percentpower%%",  h = CANON.hPower  },
  }) do
    local n = nodes[want.id]
    assert(#n.subRegions == 4,
      ("subregion canon: %s carries %d subregions, expected the %% plus a 3-tick ruler")
        :format(want.id, #n.subRegions))
    local st = n.subRegions[1]
    assert(st.type == "subtext" and st.text_text == want.token and st.text_visible == true,
      "subregion canon: " .. want.id .. " lost its percentage at index 1")
    assert(st.anchorXOffset == CANON.pctX and st.anchorYOffset == 0
      and st.text_fontSize == CANON.pctSize and st.text_anchorPoint == "CENTER",
      ("subregion canon: %s's number is at (%s, %s) %spt, expected (%d, 0) %dpt")
        :format(want.id, tostring(st.anchorXOffset), tostring(st.anchorYOffset),
          tostring(st.text_fontSize), CANON.pctX, CANON.pctSize))
    assert(st.text_fontType == "OUTLINE",
      "subregion canon: " .. want.id .. " lost the outline that makes it read on a bright floor")
    --    The number must stay INSIDE its own rail: two digits at 11pt are ~14px wide and three
    --    are ~21px, so the widest case spans pctX +/- 10.5 and has to clear the rail's right end
    --    at +50. This is what stops a later edit pushing the number back out onto open screen.
    assert(CANON.pctX + 10.5 <= CANON.rail / 2,
      "subregion canon: a three-digit number at PCT_X would hang off the end of the rail")
    for i, x in ipairs(CANON.rulerX) do
      local tick = n.subRegions[i + 1]
      assert(tick.type == "subtexture" and tick.width == 1 and tick.height == want.h
        and tick.xOffset == x and tick.yOffset == 0 and tick.textureVisible == true,
        ("subregion canon: %s's ruler tick %d is not a 1x%d hairline at x = %d")
          :format(want.id, i, want.h, x))
    end
  end
  --    The arcane lane: three pips, all shipping dark, each addressed by its own condition.
  local lane = nodes["Mage - Arcane Lane"]
  assert(#lane.subRegions == 3, "subregion canon: the arcane lane should carry exactly 3 pips")
  for i, x in ipairs(CANON.pipX) do
    local pip = lane.subRegions[i]
    assert(pip.type == "subtexture" and pip.width == 7 and pip.height == CANON.hLane
      and pip.xOffset == x and pip.textureVisible == false,
      ("subregion canon: arcane pip %d is not a dark 7x%d block at x = %d")
        :format(i, CANON.hLane, x))
  end
  local drives = {}
  for _, c in ipairs(lane.conditions) do
    assert((c.check.trigger == 1 and c.check.variable == "stacks")
      or (c.check.trigger == 2 and c.check.variable == "inCombat"),
      "subregion canon: an arcane lane condition reads neither `stacks` off trigger 1 nor "
      .. "`inCombat` off trigger 2")
    drives[c.changes[1].property] = true
  end
  assert(drives["sub.1.textureVisible"] and drives["sub.2.textureVisible"]
    and drives["sub.3.textureVisible"] and drives["foregroundColor"],
    "subregion canon: the arcane lane's pips or its at-cap colour are not driven by `stacks`")
  assert(lane.triggers[1].trigger.auraspellids[1] == "36032"
    and lane.load.spellknown == 12042,
    "subregion canon: the arcane lane lost its Arcane Blast trigger or its Arcane-only gate")
  --    The lane's progress must come from the AURA, so the aura trigger has to stay at index 1;
  --    the fade feeder is trigger 2 and the trigger logic has to stay conjunctive, or an
  --    always-active feeder would pin the lane on screen with no stacks up.
  assert(lane.triggers[2].trigger.event == "Unit Characteristics"
    and lane.triggers.disjunctive == "all" and lane.triggers.activeTriggerMode == -10,
    "subregion canon: the arcane lane's fade feeder is not a conjunctive trigger 2")

  -- 5) THE CONSERVE WATERLINES cross the mana rail at 30%, full height, still Arcane-only, and
  --    still two separate auras — a subregion cannot carry a load gate.
  for _, want in ipairs({
    { "Mage - Mana Conserve Line", MARK_DIM }, { "Mage - Mana Conserve Lit", MARK_LIT },
  }) do
    local n = nodes[want[1]]
    assert(n.width == want[2] and n.height == CANON.hPower,
      ("waterline canon: %s is %sx%s, expected %dx%d"):format(want[1], tostring(n.width),
        tostring(n.height), want[2], CANON.hPower))
    assert(n.xOffset == CANON.conserveX and n.yOffset == CANON.yPower,
      ("waterline canon: %s is at (%s, %s), expected (%s, %s)"):format(want[1],
        tostring(n.xOffset), tostring(n.yOffset), tostring(CANON.conserveX),
        tostring(CANON.yPower)))
    assert(n.load.use_spellknown == true and n.load.spellknown == 12042,
      "waterline canon: " .. want[1] .. " lost its Arcane-only gate")
  end

  -- 5b) THE OUT-OF-COMBAT FADE, stated as a contract rather than as a sentence in the README.
  --     There is no parent that can carry it: the plate is a SIBLING of the rails, so its alpha
  --     does not propagate, and every region that can be seen out of combat has to carry the
  --     condition itself. So the instrument is partitioned, exhaustively, into the regions that
  --     fade and the regions that cannot be on screen out of combat at all — and the second list
  --     has to PROVE that claim rather than assert it:
  --       Threat Rail        hides itself at threatvalue <= 0, which is every out-of-combat frame
  --       Mana Conserve Lit  load.use_combat
  --       Alarm Frame        its trigger only fires above 80% threat
  --     Add a lane without one or the other and this fails, which is what v14 needed: the arcane
  --     lane arrived in the strip carrying neither, and drew at full brightness over a faded
  --     plate whenever a stack window outlived the pull.
  local FADERS = {
    "Mage - Sill Plate", "Mage - Health Rail", "Mage - Mana Rail",
    "Mage - Mana Conserve Line", "Mage - Arcane Lane",
  }
  local COMBAT_ONLY = { "Mage - Threat Rail", "Mage - Mana Conserve Lit", "Mage - Alarm Frame" }
  local classified = {}
  for _, id in ipairs(FADERS) do
    classified[id] = true
    local found = false
    for _, c in ipairs(nodes[id].conditions or {}) do
      if c.check.variable == "inCombat" and c.check.value == 0
        and c.changes[1].property == "alpha" and c.changes[1].value == 0.5 then found = true end
    end
    assert(found, "fade contract: " .. id .. " does not fade to 50% out of combat")
  end
  for _, id in ipairs(COMBAT_ONLY) do
    classified[id] = true
    local n = nodes[id]
    local proof = n.load.use_combat == true
    for _, c in ipairs(n.conditions or {}) do
      if c.check.variable == "threatvalue" and c.changes[1].property == "alpha"
        and c.changes[1].value == 0 then proof = true end
    end
    for i = 1, 10 do
      local t = n.triggers[i]
      if not t then break end
      if t.trigger.use_threatpct then proof = true end
    end
    assert(proof, "fade contract: " .. id .. " carries no fade and is not in-combat-only either")
  end
  for _, id in ipairs(SILL_CHILDREN) do
    assert(classified[id],
      "fade contract: " .. id .. " is in the strip but in neither the fading nor the "
      .. "in-combat-only list; every lane has to be one or the other")
  end

  -- 6) DRAW ORDER. controlledChildren IS the z-order (+4 frame levels per entry, later on top),
  --    so the ALARM RIM must be first, the plate second, and every readout after both — and the
  --    flat child list WA rebuilds the order from must agree with it, depth-first.
  local order_ = nodes["Mage - Player Sill"].controlledChildren
  assert(#order_ == #SILL_CHILDREN,
    ("draw-order proof: the sill has %d children, expected %d"):format(#order_, #SILL_CHILDREN))
  for i, id in ipairs(SILL_CHILDREN) do
    assert(order_[i] == id,
      ("draw-order proof: child %d is %s, expected %s"):format(i, tostring(order_[i]), id))
  end
  local flat = {}
  for _, ch in ipairs(back.c) do
    if ch.parent == "Mage - Player Sill" then flat[#flat + 1] = ch.id end
  end
  assert(#flat == #order_, "draw-order proof: sill child count differs between c and CC")
  for i = 1, #order_ do
    assert(flat[i] == order_[i],
      ("draw-order proof: child %d is %s in controlledChildren but %s in the flat list")
        :format(i, order_[i], flat[i]))
  end
  --    ...and the Arcane Blast aura really did leave the buff row.
  assert(nodes["Mage - Arcane Lane"].parent == "Mage - Player Sill",
    "draw-order proof: the arcane lane is not in the sill")
  assert(#nodes["Mage - Buffs"].controlledChildren == 3,
    "draw-order proof: the buff row should hold 3 icons once the stack lane moves out")

  -- 7) THE RECTANGLE SCAN, RUN AGAINST THE ALARM ENVELOPE AND NOT THE PLATE. The plate is 102x37
  --    at (0, -110) — x -51..+51, y -128.5..-91.5 — but the widest thing the strip ever draws is
  --    the 108x43 alarm rim, x -54..+54, y -131.5..-88.5, and it appears exactly when the player
  --    is least able to absorb a surprise. Scanning the plate would have declared 3px of the rim
  --    "clear" without ever testing it. Every other region in the pack is boxed and tested
  --    against the ENVELOPE. Dynamic-group children
  --    ignore their own offsets — WA lays them out — so each dynamic group is PROJECTED as a
  --    band `max(children, 6)` deep: six is the floor, because that is the depth at which an
  --    alert stack stops being hypothetical, but a group that OWNS ten icons is projected ten
  --    deep, because all ten can be on screen at once. An earlier pass in this repo shipped a
  --    layout that only cleared while a single prompt was showing; that is why depth is projected
  --    rather than assumed. Every box is printed below with the depth it was projected at, so
  --    the table in the README is a transcript rather than a retelling.
  local DEPTH = CANON.scanDepth
  local function box(x, y, w, h)
    return { l = x - w / 2, r = x + w / 2, b = y - h / 2, t = y + h / 2 }
  end
  local function overlaps(a, b)
    return a.l < b.r and b.l < a.r and a.b < b.t and b.b < a.t
  end
  --    The scanned box is the ENVELOPE — the alarm rim, which is the biggest thing in the strip —
  --    and it is derived from the ALARM's own decoded size, not from a constant, so a rim that
  --    grows is a rim that gets re-scanned. The plate box is kept alongside it for the printout.
  local strip = box(CANON.absX, CANON.absY, alarm.width, alarm.height)
  local plateBox = box(CANON.absX, CANON.absY, CANON.plateW, CANON.plateH)
  assert(strip.l <= plateBox.l and strip.r >= plateBox.r
    and strip.b <= plateBox.b and strip.t >= plateBox.t,
    "collision scan: the envelope does not contain the plate, so it is not an envelope")
  local inSill = {}
  for _, id in ipairs(SILL_CHILDREN) do inSill[id] = true end

  local boxes, hits = {}, {}
  for _, ch in ipairs(back.c) do
    if not inSill[ch.id] and ch.id ~= "Mage - Player Sill" and ch.id ~= "Mage - Sill Layer" then
      if ch.regionType == "dynamicgroup" then
        local ax, ay = absolute(ch.id)
        local widest, tallest, n = 0, 0, #ch.controlledChildren
        for _, cid in ipairs(ch.controlledChildren) do
          widest = math.max(widest, nodes[cid].width or 0)
          tallest = math.max(tallest, nodes[cid].height or 0)
        end
        local depth = math.max(n, DEPTH)   -- project at least six deep, never fewer than it has
        local space = ch.space or 4
        local runW = depth * widest + (depth - 1) * space
        local runH = depth * tallest + (depth - 1) * space
        if ch.grow == "UP" then
          boxes[#boxes + 1] = { id = ch.id .. " (stack x" .. depth .. ")",
            l = ax - widest / 2, r = ax + widest / 2, b = ay - tallest / 2, t = ay + runH }
        elseif ch.grow == "DOWN" then
          boxes[#boxes + 1] = { id = ch.id .. " (stack x" .. depth .. ")",
            l = ax - widest / 2, r = ax + widest / 2, b = ay - runH, t = ay + tallest / 2 }
        elseif ch.grow == "HORIZONTAL" then
          boxes[#boxes + 1] = { id = ch.id .. " (row x" .. depth .. ")",
            l = ax - runW / 2, r = ax + runW / 2, b = ay - tallest / 2, t = ay + tallest / 2 }
        else
          error("collision scan: unhandled dynamic group growth " .. tostring(ch.grow))
        end
      elseif ch.regionType ~= "group" and ch.width and ch.height then
        local parent = nodes[ch.parent]
        if not (parent and parent.regionType == "dynamicgroup") then
          local ax, ay = absolute(ch.id)
          local b = box(ax, ay, ch.width, ch.height); b.id = ch.id
          boxes[#boxes + 1] = b
        end
      end
    end
  end
  --    ...and the TIGHTEST CLEARANCE is measured, not just the absence of overlap. A layout that
  --    clears by 0.5px is one edit away from not clearing at all, so the number is printed per
  --    box and the minimum is named. Separation on either axis is enough to be clear, so the gap
  --    for a non-overlapping pair is the LARGEST of the four one-sided distances.
  local closest, closestId = math.huge, nil
  for _, b in ipairs(boxes) do
    if overlaps(strip, b) then
      hits[#hits + 1] = ("%s (x %s..%s, y %s..%s)")
        :format(b.id, tostring(b.l), tostring(b.r), tostring(b.b), tostring(b.t))
    else
      b.gap = math.max(strip.l - b.r, b.l - strip.r, strip.b - b.t, b.b - strip.t)
      if b.gap < closest then closest, closestId = b.gap, b.id end
    end
  end
  assert(#hits == 0, ("collision scan: the alarm envelope (%sx%s) overlaps %d element(s): %s")
    :format(tostring(alarm.width), tostring(alarm.height), #hits, table.concat(hits, "; ")))
  assert(#boxes > 0, "collision scan: nothing was scanned")
  assert(closest > 0, "collision scan: the tightest clearance is not positive")
  --    The neighbour the margin actually depends on, named so a future edit that moves it fails
  --    here instead of on a live client. Measured from the ENVELOPE's bottom edge, not the
  --    plate's: the rim reaches 3px lower than the plate does.
  local buffY = select(2, absolute("Mage - Buffs"))
  local gapBelow = (strip.b) - (buffY + 40 / 2)
  assert(gapBelow > 0, "collision scan: the alarm rim has eaten into the buff row")

  print(("geometry: sill (%d, %d) plate %dx%d, alarm envelope %sx%s (rim %dpx/side); lanes "
    .. "threat %d@%s health %d@%s power %d@%s arcane %d@%s; %d neighbours scanned, 0 overlaps; "
    .. "tightest clearance %.1fpx (%s); %.1fpx to the buff row")
    :format(sx, sy, CANON.plateW, CANON.plateH, tostring(alarm.width), tostring(alarm.height),
      CANON.rim,
      CANON.hThreat, tostring(CANON.yThreat), CANON.hHealth, tostring(CANON.yHealth),
      CANON.hPower, tostring(CANON.yPower), CANON.hLane, tostring(CANON.yLane),
      #boxes, closest, tostring(closestId), gapBelow))
  print(("  %-32s x %s..%s  y %s..%s"):format("ALARM ENVELOPE (scanned)",
    tostring(strip.l), tostring(strip.r), tostring(strip.b), tostring(strip.t)))
  print(("  %-32s x %s..%s  y %s..%s"):format("plate (inside it)",
    tostring(plateBox.l), tostring(plateBox.r), tostring(plateBox.b), tostring(plateBox.t)))
  for _, b in ipairs(boxes) do
    print(("  %-32s x %s..%s  y %s..%s   clear by %.1fpx")
      :format(b.id, tostring(b.l), tostring(b.r), tostring(b.b), tostring(b.t), b.gap))
  end
  print(("draw order (bottom -> top): %s"):format(table.concat(order_, " -> ")))
end

-- uid continuity vs the previously shipped string, checked BEFORE overwriting,
-- so every future version gets the "same id keeps its uid" check for free.
--
-- v14 hands NO allowance list, and that is the point of the version. v12 deleted four regions
-- and declared them one id at a time; that licence expired at v13, and the four ids are absent
-- from both sides of the comparison now, so the strict default is back: no uid may disappear,
-- full stop. v14 adds nothing and removes nothing — it re-types, resizes, re-parents and
-- re-orders, none of which touches the uid stream — so this must report changed = 0 AND
-- missing = 0 against v13. The `-- WA-REMOVED (v12):` tags at the top of this file stay as
-- lineage and are inert: tools/verify-packs.lua only honours tags matching the version the
-- README currently ships.
local cont = W.uidContinuity(encoded, OUT)
W.assertUidContinuity(cont, "mage")

local out = io.open(OUT, "w")
out:write(encoded)
out:close()

print(("OK: %d auras (1 top + %d children), %d chars -> all-specs.txt")
  :format(#transmit.c + 1, #transmit.c, #encoded))
if cont then
  print(("uid continuity vs previous: stable=%d changed=%d retained=%d missing=%d parentSame=%s")
    :format(cont.stable, cont.changed, cont.retained, cont.missing, tostring(cont.parentSame)))
  if cont.missing > 0 then
    print("  declared removals gone: " .. table.concat(cont.missingIds, ", "))
  end
else
  print("uid continuity: no previous all-specs.txt (first build)")
end
