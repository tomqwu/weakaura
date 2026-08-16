-- generate.lua — Hunter TBC HUD, Beast Mastery & Survival (v15).
-- Run: lua5.1 tbc/hunter/generate.lua   (toolkit libs must be fetched once:
--      tools/tbc-weakaura-creator/scripts/setup.sh)
-- Produces all-specs.txt: a "!WA:2!" string importable in game.
--
-- Rotation-first: every element below maps to one line of the BM (41/20/0) or
-- SV (0/20/41) raid priority; anything that does not change the next button
-- pressed was cut.
--
-- v2 rotation fixes (see README "v2 — rotation fixes"):
--   * Arcane Shot joins the cooldown row (the OR-partner of Multi-Shot).
--   * Back to Hawk closes the aspect-swap loop (Viper up AND mana recovered).
--   * Misdirection prompt is the paired ability for the 70% threat tier;
--     Feign Death moved to 90% and is now combat + group gated.
--   * Mend Pet / Revive Pet prompts: the pet is ~35-40% of BM damage and the
--     prerequisite for Kill Command (unit = "pet" is a first-class WA unit).
--   * Rapid Fire and Bestial Wrath icons now own their ACTIVE window as well
--     as their cooldown (first-active trigger mode: buff first, cooldown second).
--   * Viper threshold 15% -> 20%; Kill Command also opens on a melee crit.
--
-- v3 spec audit (see README "v3 — spec-selective loading"): gating only, no new
-- elements, no removals, no uid changes. BM and SV run the same shots (Steady Shot
-- weave, Multi-Shot on cd, Kill Command on crit, Serpent/Arcane on the move, one
-- pet, Viper for mana), so the shared core is legitimately large and stays shared.
-- The single leak was Expose Weakness: a Survival-talent debuff sitting in the
-- ungated set, i.e. loading for Beast Mastery, which cannot apply it. It is now
-- inverse-gated off Bestial Wrath.
--
-- v4 PvP layer (see README "v4 — PvP layer"): twelve new auras, every one of them
-- load-gated to arena/battleground, so nothing about the PvE HUD changes. Elements
-- that read arena1..arena5 are arena-ONLY (those unit ids do not exist in a BG).
-- Zero custom code was added: every new composite is a plain AND or OR of triggers.
--
-- v5 (see README "v5 — the CC glow speaks, and the arena stops lying"): one new aura
-- and two changed elements, all three from a source verification of things v4 deferred.
--   * CC ON ME is now colour-coded by controlType: the glow says which BREAK works
--     before you have read a single word. sub.1.glowColor is a real, settable
--     condition property (Glow.lua properties table, Conditions.lua sub.N parser) —
--     it is only a no-op when useGlowColor is false, and F.subglow sets that flag
--     whenever a colour is passed, which this element does.
--   * Threat bar and threat flash no longer load in an ARENA. The size load arg has
--     no inverse, so the complement is enumerated; open world is the literal string
--     "none" (GetInstanceTypeAndSize's explicit fallthrough return), so listing it
--     is what keeps both elements loading while questing.
--   * ENEMY MANA: one bar per opponent who actually runs on mana. The Power
--     prototype is NOT pruned on TBC and its unit arg accepts "arena" (the deletion
--     of arena units is gated on IsClassicEra, not IsTBC), so this is a plain
--     multi-unit clone row with zero custom code.
--
-- v6 (see README "v6 — the cooldown row shows what you CANNOT press"): no new auras, no
-- new uids, no load-gate changes. The row is re-split along the one line that matters —
-- which of these buttons is pressed the moment it is up, and which is pressed when a
-- circumstance calls for it (references/rotation-design.md, "Show what the player CANNOT
-- press"). Each of the eleven icons was classified against the BM (41/20/0) and SV
-- (0/20/41) raid priorities, not converted wholesale:
--   * ROTATIONAL, stay showAlways and GAIN the gold ready-glow they never had:
--     Multi-Shot and Arcane Shot. Both guides are explicit that Multi-Shot replaces a
--     Steady Shot on cooldown (it is more damage per use than Steady Shot even on one
--     target), and Arcane Shot is the same weave slot's other half plus the instant you
--     press while moving. Hiding the two buttons a hunter presses most would trade a
--     "press this now" signal for a "you cannot press this" one.
--   * SITUATIONAL, become showOnCooldown and lose the now-meaningless desaturate:
--     Intimidation, Readiness, Wyvern Sting, Misdirection, Feign Death, and the two
--     PvP-gated ones, Freezing Trap and Scatter Shot. Misdirection and Feign Death are
--     the two whose moment is already owned by a threat-paired prompt in the alert flow,
--     so the row icon only has to answer "when does it come back".
--   * Rapid Fire and Bestial Wrath are burst cooldowns spent at a window (the opener,
--     and again after Readiness), so they are situational too and become showOnCooldown.
--     They KEEP their desaturate: on those two it is not the generic dimmer, it is the
--     second half of the v2 active-window readout (full colour + glow = the window is
--     live, dim = the window is spent and the button is recharging), and it is overridden
--     during the window by the later sub.1.glow condition. The stated reason for dropping
--     desaturate — "every visible icon is on cooldown, so greying them all makes the
--     abilities harder to tell apart" — does not hold for an icon whose visible states
--     include a live buff window.
--
-- v7: the PvP trinket readout tracked item 30346, which wowhead confirms is the
-- PRIEST-restricted Medallion of the Horde — a hunter can never equip it, so its
-- cooldown trigger could never fire and a Horde hunter's "Trinket DOWN" state was
-- silently dead. Replaced with 37865, the all-class 2.4 Medallion of the Horde (the
-- twin of 37864), which is the pair every other pack in this repo uses.
--
-- v8: the centre of the screen is FREED. The three stacked 172x14 bars (health, mana,
-- threat) and the threat flash are gone as *rectangles*; the same four auras — same ids,
-- same uids, same triggers, same load gates — are now radial rings around two unit orbs
-- that flank the character: PLAYER on the left at x=-250, TARGET on the right at x=+250.
-- Nothing outside the Resources group changed at all.
--   * A ring is a `progresstexture` region (WeakAuras' own Ring_10px.tga) filling
--     CLOCKWISE from 12 o'clock. wa_factory.lua has no progresstexture or model builder,
--     so those two tables are spelt out below; every other piece still goes through it.
--   * The colour escalations SURVIVE, renamed: on an aurabar the condition property is
--     `barColor`; on a progresstexture it is `foregroundColor` (ProgressTexture.lua's
--     module-level `properties` table). The rename is SILENT — Conditions.lua skips a
--     change whose property is not in the region's properties table, with no error — so a
--     mechanical port that kept `barColor` would have shipped four dead escalations.
--   * Threat becomes the OUTERMOST ring of the target orb, which is where it belongs:
--     it is your threat on that target. Same three tiers, same party/raid + not-arena
--     gates. The 80% flash becomes a pulsing red halo ring just outside it.
--   * MANDATORY zero-total guards. AuraBar.lua draws EMPTY at total == 0;
--     ProgressTexture.lua draws FULL (`local progress = 1; if self.total > 0 then ...`).
--     Threat's total is threatvalue*100/threatpct, so it is 0 the instant after a Feign
--     Death — a ring would slam to a full circle meaning "at the pull threshold" while
--     the colour stayed green. Every ring therefore carries an alpha-0 condition on its
--     own trigger's total (threatvalue <= 0, maxhealth <= 0, maxpower <= 1).
--   * The mana ring gains the two aspect-swap breakpoints as static marks: a red tick at
--     20% (Go Viper) and a green one at 80% (Back to Hawk), the exact thresholds the two
--     alerts already fire on. Sub-region ticks are `subtexture`, which is the only tick
--     recipe that works here — `subtick`, the aurabar tick, is aurabar-ONLY
--     (SubRegionTypes/Tick.lua `supports()` returns regionType == "aurabar").
--   * Six NEW auras, all constructed at the very bottom: two cluster groups, the two
--     live unit portraits (`model` regions bound to the unit) and the target's own
--     health and mana rings. stable=46 changed=0 missing=0 — nothing is orphaned.
--
-- v9: PURE GEOMETRY. Not one trigger, load gate, condition, colour, spell id or region
-- type moved; no aura was added or removed (stable=52 changed=0). v8 shipped seven packs
-- that each invented their own orb sizes, and inside this pack the player and target
-- clusters did not even agree with each other — the player orb read 84px across, the
-- target 108, which is what a player sees as "uneven". v9 adopts the ONE canonical orb
-- geometry now shared by all seven packs (see the CANON block below):
--   * Ring_20px replaces Ring_10px on every ring. At these diameters the 10px art scaled
--     down to a ~3px hairline and read as a wire, not an arc.
--   * Both clusters now present the SAME outer diameter (104) and the SAME portrait (46).
--     The target simply nests one more ring inside: threat 104 / health 78 / mana 54,
--     against the player's health 104 / mana 78. Nothing else about either side changed.
--   * The readouts move to the shared baselines (health 14pt at -60, power 11pt at -76,
--     threat 11pt at +60), so the target's health number is no longer 20px lower than the
--     player's. Both clusters move to the shared anchor: absolute (-260, -60) and
--     (+260, -60), which is also what lifts a 104px orb clear of the cooldown row.
--   * THE TRAP: the mana ring's two aspect-swap ticks are `subtexture` marks placed by
--     TRIGONOMETRY from the ring RADIUS (x = r*sin, y = r*cos). Growing the ring 60 -> 78
--     without re-deriving them would leave both marks floating 9px inside their own arc.
--     They are computed from G.mpRing here, so they moved with it: the 20% mark from
--     (26.63, 8.65) to (35.19, 11.43) and the 80% mark from (-26.63, 8.65) to
--     (-35.19, 11.43). Both still land on the ring's circumference at their own angle.
--
-- v10: DIABLO GLOBES. The rings are gone and so are the portraits. Health and mana are
-- now VESSELS that fill bottom-to-top like liquid, with the percentage inside the glass.
-- No trigger, load gate, spell id or escalation outside the orb cluster moved; no aura was
-- removed (stable=47 changed=0 missing=0 — the four renamed auras keep their uids).
--   * A globe is the SAME progresstexture region the rings were, with one different field:
--     orientation = "VERTICAL", which WeakAuras names "Bottom to Top". The name lies about
--     direction in the usual way — VERTICAL fills UP, VERTICAL_INVERSE fills DOWN — so
--     getting it backwards would drain the globe from the top as you take damage.
--     Switching to the LINEAR fill path also swaps which fields are live: compress /
--     slanted / slantMode matter now and startAngle / endAngle no longer do. crop stays at
--     the 0.41 default (on the linear path it is just the texcoord scale).
--   * THE PORTRAITS ARE DELETED AS REGIONS, NOT AS AURAS. Diablo has no portrait, and
--     dropping it is what frees the centre of each globe for its number: a `model` region
--     can never carry a text subregion (SubText's supports() lists texture /
--     progresstexture / icon / aurabar — not model), which is the only reason the ring
--     build had to park its percentages outside. Both portrait auras are RECYCLED onto
--     glass rims instead — same uid, same triggers, same conditions, new region type — so
--     no orphan is left behind in anyone's WeakAuras.
--   * THREAT HAS NO NATURAL VESSEL, so it becomes the TARGET GLOBE'S RIM COLOUR: green
--     base, orange at 70%, red-orange at 90%, deep red on aggro, with the percentage above
--     the globe. Same aura, same trigger, same party/raid + not-arena gates, same three
--     tiers and the same mandatory threatvalue <= 0 alpha guard. The property renames
--     AGAIN — `foregroundColor` on a progresstexture, `color` on a texture — and the rename
--     is silent, so a mechanical port would have shipped three dead escalations.
--   * The two aspect-swap breakpoints get EASIER, not harder. On a ring they were placed by
--     trigonometry; on a vessel a threshold is a horizontal waterline at a fixed height,
--     yOffset = (threshold/max - 0.5) * GLOBE_MAIN, and its width is the circle's chord at
--     that height. Same two marks, same two colours, same subRegion indices.
--   * TWO NEW AURAS, both rims (the player's power globe and the target's small power
--     globe), appended at the very end so every existing uid() call keeps its position.
--   * THE ONE THING OUTSIDE THE ORBS THAT HAD TO MOVE: the buff row. The canonical target
--     globe sits at absolute (0, -150) and the buff row sat at absolute (0, -156) — the
--     globe would have been drawn straight through Serpent Sting and Hunter's Mark. The
--     group is re-anchored to absolute (0, -60), the band the player orb used to occupy,
--     which also puts the target's two debuff timers directly above the target globe.
--     Nothing else about those icons changed: same ids, uids, triggers, gates, sizes.
--
-- v11: THE GLOBES COME UP BESIDE THE CHARACTER AND THE GLASS CATCHES LIGHT. Nothing else at
-- all: not one trigger, load gate, condition, colour, spell id or region type moved, no aura
-- was added or removed (stable=53 changed=0 missing=0), and everything outside the vessels —
-- buffs, alerts, cooldown row, procs, the whole PvP layer — is byte-for-byte what v10 shipped.
--   * POSITION. v10 parked all three globes on one band at absolute y = -262, which reads as
--     a separate bar bolted under the HUD rather than as part of the character. They now
--     FLANK them: life at (-190, +40), power at (+190, +40), the target globe above and
--     between at (0, +110). Those three coordinates are the tightest collision-free
--     arrangement available in this repo's shared layout and were scanned against every
--     element in all seven packs — x = ±170 hits the Alerts column at -150 and the PvP
--     column at +150, x = ±210 hits the PvP layer's elements at (200, -44).
--     The target cluster is now the only thing at a different height, so ITS GROUP carries
--     the 70px difference and every child rides along; nothing below the canon block names a
--     coordinate, and the position proof at the bottom of this file walks each parent chain
--     and refuses to write a string whose globes land anywhere else.
--   * LOOK. A flat-coloured disc reads as a sticker; a sphere reads as one because light
--     strikes its curve off centre. Every vessel — including the target's 22px power globe —
--     gains a SPECULAR HIGHLIGHT: the same Circle_Smooth disc, squashed to 0.46 x 0.34 of
--     the globe, pushed up and left, white at 0.28 alpha, blend mode ADD.
--     ADD IS THE LOAD-BEARING FIELD. Subregions draw in order and the percentage lives
--     INSIDE the glass, so this overlay is painted over the number; a BLEND sheet would grey
--     out the readout the vessel exists to carry, while ADD can only brighten. That is also
--     why the recipe is a highlight and not the more obvious dark edge vignette — a dark
--     overlay has no additive form.
--     APPENDED, NEVER INSERTED: sub.2 on life, sub.4 on mana (after both waterlines), sub.2
--     on the target globe, sub.1 on the target's power globe. Conditions reach subregions
--     positionally as sub.N, and an insert ahead of a referenced index retargets it with no
--     error at all, so the build asserts the pre-v11 prefix of every vessel is untouched.
--
-- v12: THE RINGS COME BACK, AND SO DOES YOUR FACE. The globes are gone; health, power, threat
-- and target health are radial ARCS again, two per cluster, drawn around a live 3D portrait of
-- the unit they belong to. Nothing outside the cluster moved: not one trigger, load gate,
-- condition, spell id or offset in the buffs, alerts, cooldown row, procs or the PvP layer,
-- and no aura was added or removed (stable=46 changed=0 missing=0 — the seven auras missing
-- from `stable` are the ones that changed NAME, and every one kept its uid).
--   * WHY. Side by side with the ring build, the globes lost. A vessel says "how full", which
--     is the same sentence a bar says, in a rounder frame; two concentric arcs around a face
--     say "this unit, this much" in one glance and put the unit's identity in the middle of
--     its own readout. The portrait is the part a globe can never have: it is what makes the
--     target cluster tell you WHAT you are shooting without a nameplate, and it is why the
--     percentages sit just outside the rings again (a `model` region cannot carry a text
--     subregion at all — SubText's supports() gate does not list it).
--   * THE CLUSTER, and every number in it is canon, shared byte-for-byte with the other six
--     packs: outer ring 84, inner ring 62, portrait 44, player cluster at an absolute
--     (-270, +40), target cluster at (+270, +110). Health is the player's outer arc and mana
--     its inner one; THREAT is the target's outer arc and target health its inner one, so both
--     sides are two rings around a face and read as a matched pair.
--   * A TARGET POWER ARC IS DELIBERATELY NOT BUILT. v8/v9 had one and it is what made that
--     cluster look busy and uneven — three arcs on one side, two on the other. Its aura is not
--     orphaned: the uid carries the target's track ring now (see the cluster block below).
--   * WHAT CARRIES OVER UNTOUCHED: every escalation (health <30, mana <20, threat 70/90/aggro),
--     every zero-total alpha guard, threat's party/raid + not-arena gates, the 80% halo, the
--     out-of-combat fade, and the two aspect-swap breakpoints. The escalations move BACK to
--     `foregroundColor` — `barColor` was the aurabar name and `color` the texture name the
--     v10/v11 rim used, and Conditions.lua drops an unknown property in silence, so each of
--     those renames is a dead escalation if it is missed.
--   * THE BREAKPOINTS GO BACK TO TRIGONOMETRY. On a vessel a threshold is a horizontal
--     waterline; on a ring it is an angle, x = r*sin(2*pi*f), y = r*cos(2*pi*f) with
--     r = INNER/2*0.94. The 20% and 80% marks land at (27.71, 9.0) and (-27.71, 9.0), and the
--     build re-derives the angle from the emitted offsets and refuses to write a string whose
--     marks are not on their ring at their own threshold.
--   * THE SPECULAR HIGHLIGHT IS DROPPED. It was a glass effect for a filled vessel; on an arc
--     there is no glass to catch light, and it was the only subregion in the cluster that
--     existed for the globes alone.
--   * THREE AURAS BECOME TRACK RINGS. The globe build carried four rims and a target power
--     globe that the ring build has no use for, and a uid may never simply disappear — an
--     orphan is an aura the player has to hunt down and delete by hand. They are respent on
--     the dark track rings behind the mana arc, the target's threat arc and the target's health
--     arc, which is the one job the ring build genuinely needs doing: threat does not load
--     solo or in an arena and hides itself at zero threat, and without a track ring the target
--     cluster would read as one arc and a face while the player's reads as two.
--
-- v13: THE TARGET CLUSTER IS DELETED, AND THREAT MOVES HOME. The right-hand cluster is gone
-- entirely — target health arc, target portrait, and the two target track rings (one of them
-- the last remnant of the v8/v9 target MANA arc, respent as a track in v12). Its whole job was
-- already done twice by the default UI: the target frame and the nameplate both print that
-- unit's health, all game, in the place every player already looks. A HUD element that
-- duplicates the default UI costs screen, draw order and attention and returns nothing.
--   * THREAT IS NOT LOST, IT IS REHOMED. It is the one thing the target cluster carried that
--     nothing else in the game shows, and losing it is a real regression: a dps who pulls
--     aggro dies. It becomes the OUTERMOST ring of the PLAYER cluster at 100px, which is also
--     the more honest reading — it is YOUR threat, so it belongs around YOUR face. The cluster
--     is now threat 100 / health 84 / mana 62 / portrait 44, concentric on one centre.
--   * THREAT KEEPS EVERYTHING ELSE. Same aura, same uid, same Threat Situation trigger with
--     `threatUnit` (the arg was renamed to plain `unit` at internalVersion 51 and Modernize
--     migrates < 51 data, so IV-45 data MUST emit the old name), the same three escalation
--     tiers on `foregroundColor` (barColor is aurabar-only and a SILENT no-op here), the same
--     party/raid + not-arena load gates, and the same mandatory threatvalue <= 0 -> alpha 0
--     guard without which ProgressTexture draws a FULL circle at zero threat.
--   * THE 80% HALO RESIZES TO 100 and rides the player cluster too, so it pulses ON the threat
--     ring instead of orbiting the radius the old outer arc used to have.
--   * THE COMMON SOLO CASE IS STILL TWO RINGS AND A FACE. Threat load-gates to party/raid,
--     never loads in an arena, and self-hides at zero threat, so the third arc only appears
--     when threat is a real quantity.
--   * ORPHANS ARE EXPECTED HERE AND THAT IS THE POINT. Five regions are genuinely REMOVED,
--     so five uids have no home. No filler region is invented to absorb them — that is how a
--     HUD accumulates junk. Their uid() DRAWS are burned in place (a uid is a position in a
--     seeded stream; skipping a draw shifts every later one and would change the uid of every
--     surviving aura built after it), and the README names the leftover group the player has
--     to delete by hand, because WeakAuras never deletes an aura an import does not mention.
--
-- v14: THE HEALTH NUMBER MOVES INTO THE MIDDLE, AND THE PORTRAIT MOVES BEHIND IT. v13 left the
-- three readouts stacked OUTSIDE the rings — health 54px below the cluster, mana 70px below —
-- and the reported result was the obvious one: small unbacked digits on open sky, unreadable
-- against any bright zone, while the one opaque surface in the cluster (the portrait) sat in
-- the centre showing nothing but a face. v14 spends that centre.
--   * HEALTH GOES TO DEAD CENTRE at 16pt, ON the portrait, which is both where the eye already
--     rests and the only place in the cluster with something solid behind the glyphs.
--   * MANA TAKES THE SLOT HEALTH VACATED, -54 at 12pt: one number just under the outer ring
--     instead of two stacked numbers trailing off the bottom of the HUD.
--   * THREAT DOES NOT MOVE. +58 at 10pt, above the 100px threat ring, exactly as in v13.
--   * THE DRAW ORDER IS HALF THE FIX, AND THE NON-OBVIOUS HALF. The health number is a
--     subregion of the health RING, and through v13 the portrait was the cluster's LAST child
--     — FixGroupChildrenOrder gives later children higher frame levels, so the face drew over
--     every sibling. Sending the text to the centre without touching the order would have
--     painted it straight under the portrait and looked like nothing had happened. The
--     portrait becomes the FIRST child instead, so every ring and every ring's text draws in
--     front of it. That is safe only because a ring is an ANNULUS: the innermost ink in this
--     cluster is at radius 26.16 and the portrait ends at 22, so no ring's art can touch the
--     face — only its text can, which is the point. The build asserts that gap.
--   * NOTHING ELSE CHANGES. No aura added or removed, every uid stable, no trigger, load gate,
--     condition, colour, size or position touched outside those two offsets, two font sizes
--     and the child order. Reordering controlledChildren costs no uid draw at all.
--
-- v15: THE SILL. The 100px concentric ring cluster is gone. Health, mana and threat are now
-- three stacked horizontal RAILS on a 102x31 dark plate under your feet, at an absolute
-- (0, -110), where ONE PIXEL IS ONE PERCENT. No aura is added and none is removed: measured
-- against the v14 string, stable=45 changed=0 missing=0 retained=48 parentSame=true, and the
-- three that fall out of `stable` are the three that changed NAME (Player Cluster -> Player
-- Sill, Player Portrait -> Sill Plate, Power Ring Track -> Health 30% Mark), each keeping its
-- uid byte-for-byte. The figure the build PRINTS is stable=48, because by then it is comparing
-- against its own freshly written string, where the renames have already happened on both
-- sides; that is the self-comparison number and not the v14 one. Every region in the old
-- cluster is re-typed, resized and re-parented into the strip, and NOT ONE new W.uid() is drawn.
--   * WHY. A ring buys gauge length with area squared: the cluster spent 10,000 px2 and 19.4%
--     of it (the 44px portrait) carried no decision at all. A 0-100 quantity has exactly 100
--     distinguishable states, so a 100px rail is the exact length at which the gauge is
--     lossless — every pixel beyond it is redundant and every pixel below it discards a state.
--     The strip carries the same three readouts plus four breakpoints and six ruler ticks in
--     3,162 px2, and it makes every breakpoint ARITHMETIC instead of trigonometric:
--         x(v) = (v / maxpower - 0.5) * 100, i.e. x = v - 50 for a 100-max resource.
--     The 20% aspect mark moves from (27.71, 9.0) — an angle on a circumference — to a plain
--     x = -30, and it is a full-height waterline instead of a 6px square beside an arc.
--   * ORIENTATION IS THE ONE FIELD THIS REPO HAS NEVER RENDERED. On a progresstexture the
--     LINEAR left-to-right value is "HORIZONTAL_INVERSE"; plain "HORIZONTAL" is Right to Left
--     (Private.orientation_with_circle_types, transcribed in poc/diablo-globes/generate.lua).
--     It is the exact inverse of the aurabar convention in gotchas.md, which is why the rails
--     are asserted on the literal string below and why the README says to eyeball one drop of
--     mana on a live client. Switching to the circular path also DISARMS startAngle/endAngle
--     and RE-ARMS compress/slanted/slantMode; crop_x/crop_y = 0.41 stops being the identity
--     value that cancels the circular sqrt(2) expansion and becomes the plain linear texcoord
--     scale, which is why the same 0.41 is still correct.
--   * THE PORTRAIT IS SPENT ON THE PLATE. `Hunter - Player Portrait` keeps its uid, its two
--     triggers and its out-of-combat fade and becomes the 102x31 Square_White_Border plate the
--     rails sit on, re-typed model -> texture (the v10/v11 rim precedent, in reverse). The
--     player LOSES a live 3D face; what they gain is the one thing an 11px rail and an 11pt
--     number need to survive Nagrand grass and Shattrath at noon, which is something opaque
--     behind them. That is the single most likely complaint and the README says so.
--   * `Hunter - Power Ring Track` is redundant the moment the rails exist — a rail's unfilled
--     part is its own backgroundColor, not a second region — so it is respent as the health
--     rail's 30% WATERLINE at x = -20, a standalone 3x11 texture drawn over the rail. Its
--     Power trigger becomes a Health trigger, because it now annotates the health rail, and it
--     inherits that rail's maxhealth <= 0 alpha guard so the mark cannot outlive its own bar.
--   * `Hunter - Threat Flash` keeps its uid, its threatpct >= 80 trigger, its ADD blend, its
--     party/raid + not-arena gate and its alphaPulse, and becomes the strip's 108x37 ALARM RIM:
--     3px larger than the plate on every side and the FIRST child, i.e. the bottom of the stack.
--     WHY IT IS BUILT THAT WAY, MEASURED RATHER THAN ASSUMED. Square_White_Border.tga is a
--     FILLED square with a dark bevel baked into its edge: of its 65536 pixels 64516 (98.44%)
--     are fully opaque, every pixel inset 8px or more from the edge (n = 57600) is alpha 255
--     with min RGB channel 167, the centre-scanline red over x = 0..13 reads
--     0,156,100,56,40,57,102,158,206,236,250,254,255,255, and the centre pixel is
--     rgba(255,255,255,255). Its interior is NOT transparent, so ONE region on this art cannot
--     trace an outline. At the plate's size and drawn last it was a full-area ADD red quad over
--     every rail, both numbers and the ruler — a wash at exactly the moment the readouts have to
--     be read. Oversized and drawn FIRST, the only part that survives is the 3px band past the
--     plate; the rest sits behind a 45%-black plate and behind every readout. That construction
--     is correct whether the art is filled or hollow, which is why it is the one used.
--     Its explicit red { 1, 0.1, 0.1, 0.85 } is unchanged and asserted (some packs in
--     this repo ship color = {} on this region, which draws in WA's default, not red).
--   * THE THREAT NUMBER IS SWITCHED OFF, not deleted: sub.1 keeps its index and its text and
--     carries text_visible = false, so it is one checkbox away in /wa. threatpct is scaled so
--     100 = pulling aggro — an early-warning ratio, not a quantity you spend — and the 70 notch
--     on the rail answers it faster than two digits do. It was also the one element of the
--     cluster printing onto open screen at 10pt. Its offset is still the +58 it needed to clear
--     a 100px ring, so ticking it back on in /wa prints it at an absolute (0, -36.5) — 58px
--     above the 4px rail, in the open band above the buff row. The build asserts that number.
--   * THE PARTY/RAID GATE ACTUALLY GATES NOW, and this is a REAL BUG FIX, not a rewording.
--     Every version of this pack since v5 shipped `use_ingroup = true` with only
--     `ingroup.multi = { group, raid }` and no `ingroup.single`. On a multiselect load option
--     `use_X == true` selects SINGLE mode and reads X.single (WeakAuras/GenericTrigger.lua,
--     TestForMultiSelect): with a nil single the shipped TBC client emits the literal test
--     `false`, and ConstructFunction ANDs every test together — so `Hunter - Threat` and
--     `Hunter - Threat Flash` NEVER LOADED AT ALL, in a party, in a raid or anywhere else.
--     The whole top lane and the 80% alarm were dead in game while the README described them.
--     MULTI mode is `use_X == false` — which is exactly what the not-arena size gate on the
--     next line has always used, and why that one works. Both regions now carry
--     `use_ingroup = false`, the same `ingroup.multi = { group, raid }`, and the assert below
--     checks the MODE, not just the values, because the values were never the problem.
--   * DRAW ORDER IS THE STACK. controlledChildren order is the draw order (+4 frame levels per
--     child, later = on top), so it runs alarm rim, plate, threat rail, health rail, power rail,
--     the 30% waterline. A standalone mark listed BEFORE its rail draws under it and is
--     invisible; the alarm rim listed anywhere but FIRST is an ADD red sheet over every readout.
--   * NOTHING OUTSIDE THE STRIP MOVES. Buffs, alerts, the cooldown row, procs and the whole
--     PvP layer are byte-for-byte what v14 shipped, and the Resources group keeps the +180 it
--     has carried since v11 — the sill group itself carries the -150 that lands the strip at
--     (0, -110). The build rectangle-scans the ALARM ENVELOPE — the widest thing the strip ever
--     draws, not its resting 102x31 plate — against every other region in the pack, dynamic
--     groups projected six deep, and refuses to write a string with a single overlap.
--
-- Every spell id was verified on wowhead.com/tbc. Aura triggers carry EVERY
-- rank as strings; cooldown triggers carry the numeric rank-1 id; spellknown
-- gates use ids that really sit in the spellbook when trained/talented.
--
-- Custom code budget: two one-line customTriggerLogic strings (Kill Command,
-- Mongoose Bite) — the sanctioned OR-of-two-events AND a-state pattern.
--
-- UID ORDER IS SACRED: the seed below and the ORDER of the region constructors
-- (each consumes one W.uid()) must never change. v2 elements are created at the
-- BOTTOM of this file and re-parented into their groups afterwards.

math.randomseed(20260814)  -- FIXED pack seed; append-only uid order across versions

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
-- wa_factory.lua resolves wa_lib.lua and assets/icon_proto.lua relative to
-- arg[0], so point arg[0] at the factory for the dofile, then restore it.
local toolDir = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local savedArg0 = arg and arg[0] or nil
if arg then arg[0] = toolDir .. "/wa_factory.lua" end
local F = dofile(toolDir .. "/wa_factory.lua")
if arg then arg[0] = savedArg0 end
local W = F.W

local CLASS = "HUNTER"
local TOP = "Hunter TBC - BM & Survival"

local byId = {}
local function reg(t) byId[t.id] = t; return t end
local function adopt(parent, child)
  child.parent = parent.id
  table.insert(parent.controlledChildren, child.id)
end

-- ===== verified spell ids =====
local SERPENT = { 1978, 13549, 13550, 13551, 13552, 13553, 13554, 13555, 25295, 27016 } -- r1-r10
local MARK    = { 1130, 14323, 14324, 14325 }                                           -- r1-r4
local HAWK    = { 13165, 14318, 14319, 14320, 14321, 14322, 25296, 27044 }              -- r1-r8
local VIPER   = 34074            -- Aspect of the Viper (single rank, lvl 64)
local TBW     = 34471            -- The Beast Within, the 18s self-buff (talent is 34692)
local EXPOSE  = 34501            -- Expose Weakness, the 7s target debuff (talents 34500/2/3)
local QSHOTS  = 6150             -- Quick Shots (Improved Aspect of the Hawk proc, 12s)
local KILLCMD = 34026            -- Kill Command (lvl 66, after a crit)
local MBITE   = 1495             -- Mongoose Bite (after you dodge)
local FEIGN   = 5384             -- Feign Death (30s cd)
local BWRATH  = 19574            -- Bestial Wrath — also THE Beast Mastery gate
local INTIMID = 19577            -- Intimidation (BM)
local READY   = 23989            -- Readiness (SV 41-pointer)
local WYVERN  = 19386            -- Wyvern Sting (SV 31-pointer, skipped by raid builds)
local RAPID   = 3045             -- Rapid Fire (cd id AND the 15s +40% haste buff)
local MULTI   = 2643             -- Multi-Shot
local MISDIR  = 34477            -- Misdirection (lvl 70)
local ARCANE  = 3044             -- Arcane Shot r1 (6s cd; Multi-Shot's OR-partner)
local MENDPET = 136              -- Mend Pet r1 (no cooldown, 15s channel)
local REVIVE  = 982              -- Revive Pet r1 (the dead-pet answer)

-- ===== v4: verified PvP spell / item ids (wowhead.com/tbc) =====
local SILENCE  = 34490                              -- Silencing Shot (MM 41-pt, 20s cd, 3s silence)
local SCATTER  = 19503                              -- Scatter Shot (SV 20-pt, 30s cd, 4s disorient)
local FRZTRAP  = { 1499, 14310, 14311 }             -- Freezing Trap r1-r3; the TRAP lasts 1 min
local VIPERST  = { 3034, 14279, 14280, 27018 }      -- Viper Sting r1-r4 (8s mana drain)
local WOTF     = 7744                               -- Will of the Forsaken (Undead racial, 2 min)
local PVPTRINK = 42292                              -- "PvP Trinket" — the spell EVERY medallion
                                                    -- and insignia casts (verified on item 37864)
-- The four trinkets a hunter can actually be wearing. Item ids, never names, and never
-- the equipment-slot trigger: that one tracks whatever sits in slot 13/14, so a PvE
-- on-use trinket would report "medallion down" while the medallion is ready — a false
-- negative in the one decision this element exists for.
-- NB 37865, not 30346: wowhead item=30346 is the PRIEST-restricted Medallion of the
-- Horde (classes bitmask 16), so a hunter can never equip it and its cooldown trigger
-- could never fire — a Horde hunter's trinket readout was silently dead. 37865 is the
-- 2.4 all-class Medallion of the Horde, the Alliance twin of 37864. Both verified on
-- wowhead.com/tbc; the same pair is used by every other pack in this repo.
local TRINKETS = {
  37865,  -- Medallion of the Horde    (all classes, lvl 70, 2 min)
  37864,  -- Medallion of the Alliance (all classes, lvl 70, 2 min)
  18846,  -- Insignia of the Horde    (Hunter, lvl 60, 5 min)
  18856,  -- Insignia of the Alliance (Hunter, lvl 60, 5 min)
}
-- Hard stops only: while one of these is up, shots and traps do nothing. Mitigation
-- cooldowns are deliberately absent, and so is Deterrence — on 2.4.3 it is +25% parry
-- and dodge, not an immunity, so it does not change which button you press.
local IMMUNE = {
  642, 1020,          -- Divine Shield r1-r2
  1022, 5599, 10278,  -- Blessing of Protection r1-r3 (physical immunity = every shot)
  45438,              -- Ice Block
  31224,              -- Cloak of Shadows
  34471,              -- The Beast Within (their trap/scatter immunity window)
}

-- icons that live in the alert flow all get the same entrance/exit motion
local function alertAnim(a)
  a.animation.start  = F.animPreset("slidebottom", "0.3", "easeOut")
  a.animation.finish = F.animCustom("1", { y = 150, alpha = 0, scale = 0.4 }, "easeOut")
end

-- Threat unit stays the factory's `threatUnit`. That IS the correct key for the
-- internalVersion 45 (WA 3.5.0) data this pack emits: the arg was renamed to plain
-- `unit` only in internalVersion 51, and Modernize.lua migrates < 51 data by copying
-- threatUnit -> unit on import. Writing `unit` here instead is actively wrong — that
-- migration assigns unconditionally, so it would overwrite our value with nil.
local function threatTrigger(minPct)
  return F.threatTrigger(minPct)
end

-- Pet health. unit = "pet" is a first-class WA unit (Types.lua actual_unit_types),
-- and the Health prototype nil-guards percenthealth, so no pet = no state.
local function petHealth(op, pct)
  local tr = F.healthTrigger(nil)
  tr.unit = "pet"
  tr.use_percenthealth = true
  tr.percenthealth = tostring(pct)
  tr.percenthealth_operator = op
  return tr
end

-- ===== rail machinery (v15: the ring cluster becomes The Sill) =====
-- `progresstexture` is the one region type wa_factory.lua does not build, so that table is
-- spelt out below; the plate, the alarm rim and the 30% waterline are plain F.texture
-- regions and everything else still goes through the factory. internalVersion stays 45, and
-- no Modernize block at IV >= 45 renames a progresstexture fill field or a subtexture field,
-- so what is emitted here is what the current client runs.
local IV, TOC = 45, 20501

-- ===== v15 CANON: THE SILL, shared byte-for-byte by every pack in this repo ============
-- These constants are IDENTICAL in all seven packs. Do not scale, round or "improve" them
-- here: the moment one pack drifts, the player sees differently-shaped strips the instant they
-- run two classes, which is exactly the bug the shared canon exists to prevent.
-- Change them in all seven build scripts or not at all.
--
-- THE RAIL IS 100 PIXELS LONG ON PURPOSE. A 0-100 quantity has exactly 100 distinguishable
-- states, so 100px is the exact length at which the gauge is lossless: every pixel beyond it
-- redraws a state the eye cannot separate, every pixel below it discards one. It is also what
-- turns every breakpoint from trigonometry into arithmetic —
--
--     x(v) = (v / maxpower - 0.5) * RAIL_LEN,  i.e. x = v - 50 for a 100-max resource
--
-- — where the ring build had to place the same two marks with r = d/2*0.94, x = r*sin(2*pi*f),
-- y = r*cos(2*pi*f) and landed the 20% aspect mark on (27.71, 9.0).
--
-- Square_White.tga and Square_White_Border.tga both ship inside WeakAuras itself
-- (Private.texture_types), so nothing here needs a media addon.
local RAIL_TEX  = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White.tga"
-- Square_White_Border.tga IS A FILLED SQUARE WITH A DARK BEVEL BAKED INTO ITS EDGE. It is NOT
-- an outline and its interior is NOT transparent. That is measured, not inferred: the file that
-- ships in the live client install is a 256x256 32bpp RLE TGA in which 64516 of 65536 pixels
-- (98.44%) are FULLY OPAQUE at alpha 255, and every pixel inset 8px or more from the edge
-- (n = 57600) has min alpha 255 and min RGB channel 167. The centre scanline's red channel over
-- x = 0..13 climbs 0, 156, 100, 56, 40, 57, 102, 158, 206, 236, 250, 254, 255, 255 -- a dark
-- bevel in the first ~8 columns and solid white from there in -- and the centre pixel is
-- rgba(255,255,255,255).
--   TWO CONSEQUENCES, AND THE SECOND IS THE WHOLE REASON THIS FILE HAS A RIM CONSTANT.
--   1. It is exactly right for the plate: a bordered, opaque dark panel is a single region.
--   2. A SINGLE REGION ON THIS ART CANNOT TRACE A HOLLOW FRAME. Drawn at the plate's own size
--      on ADD, the >=80% threat alarm is a full-area red quad over every rail, every number and
--      every pip -- a wash exactly when the readouts have to be read. The only construction
--      that reads as an EDGE is a bigger quad drawn UNDERNEATH: the alarm is RIM px larger on
--      every side and is the FIRST child, so all that survives the plate is the protruding band.
--      That construction is correct whether the art is filled or hollow, which is why it is the
--      one used, and both halves of it are asserted below.
local PLATE_TEX = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_White_Border.tga"
local RAIL_LEN  = 100   -- ONE PIXEL IS ONE PERCENT. This is the whole design.
local PLATE_W   = 102   -- the rails plus a 1px margin on each side
-- A hunter has NO discrete class resource — no combo points, no arcane stacks — so the strip
-- carries no lane 4 and the plate is 31 tall instead of the 37 rogue and mage need. The three
-- rail offsets below are identical in all seven packs regardless, so the rails land in exactly
-- the same place on every class; only the plate's height and its own yOffset differ.
local PLATE_H   = 31
-- THE RIM. The alarm quad is this much larger than the plate on EVERY side, so its box is
-- PLATE_W + 2*RIM by PLATE_H + 2*RIM and exactly a RIM-wide band of it protrudes past the
-- plate on all four edges. Everything inside that band is covered by the 45%-black plate and by
-- every readout standing on it, which is what turns a filled quad into an edge.
local RIM       = 3
local ALARM_W   = PLATE_W + 2 * RIM   -- 108
local ALARM_H   = PLATE_H + 2 * RIM   -- 37
local SILL_X    = 0     -- ABSOLUTE screen x of the strip's centre
local SILL_Y    = -110  -- ABSOLUTE screen y of the strip group's centre

-- The lane stack, all local to the sill group. Content is 4 + 1 + 11 + 1 + 11 = 28px spanning
-- local +17.5 .. -10.5; the plate wraps it with a 1px top margin at +18.5 and a floor at -12.5.
local LANE = {
  threat = { h = 4,       y =  15.5 },   -- absolute y -92.5 .. -96.5
  health = { h = 11,      y =   7   },   -- absolute y -97.5 .. -108.5
  power  = { h = 11,      y =  -5   },   -- absolute y -109.5 .. -120.5
  plate  = { h = PLATE_H, y =   3   },   -- absolute y -91.5 .. -122.5
}

-- The readouts. Every number is printed INSIDE its own rail now, which is the whole point of a
-- plate: through v14 the health percentage was 16pt text on a 44px portrait and every other
-- number was on open sky. 11pt at the rail's RIGHT end, because the fill runs left to right —
-- so the end the number sits on is dark, unfilled track exactly when the value is low, which
-- is exactly when the number is worth reading.
--
-- text_anchorPoint stays "CENTER" + a +32 x offset rather than "INNER_RIGHT": INNER_RIGHT is
-- proven on aurabars and icons in this repo and NOT on a progresstexture, and the failure mode
-- of an unsupported anchor point is silent. Two digits at 11pt span roughly x +21..+43, which
-- is 7px inside the rail's right edge even at three digits.
local NUM_PT, NUM_X = 11, 32
local PCT_THREAT = { size = 10, x = 0, y = 58 }  -- SWITCHED OFF in v15; index and text kept

-- Pack-local geometry, all of it derived from the canon so the two can never drift.
--   NOTHING below hard-codes a coordinate. The strip is placed by a canon constant minus the
--   offsets its ancestors already carry, and every region inside it sits at its LANE offset in
--   the sill group's frame — which is what makes the rails share one centreline BY
--   CONSTRUCTION instead of by six hand-typed offsets that drift apart one version later.
--   resY is UNCHANGED from v11 (+180, i.e. the Resources group still sits at an absolute
--   (0, +40)); the sill group itself carries the difference down to -110. Walk it:
--   top(0,-140) -> Resources(0,+180) -> Player Sill(0,-150) -> health rail(0,+7) = (0,-103).
local TOP_Y = -140
local G = {
  resY   = 180,                       -- the Resources group's own offset, unchanged since v11
  sillX  = SILL_X,
  sillY  = SILL_Y,
}

-- Colours. The rail colours, the track and the plate are canon (identical in every pack); the
-- text colours and the threat green are carried over UNCHANGED from the v7 bars, so the HUD
-- keeps speaking one language across every version.
--
-- THE POWER RAIL IS COLOURED FOR THE POWER TYPE IT ACTUALLY READS. A hunter's is mana, always
-- and in every spec, so it is the canon mana blue; the energy and rage colours in the canon
-- belong to the packs whose power rail reads those bars.
local COL = {
  health = { 0.15, 0.82, 0.28, 1 },     -- the health rail
  mana   = { 0.20, 0.45, 0.95, 1 },     -- the hunter's only power type
  threat = { 0.25, 0.80, 0.30, 1 },     -- the top rail, base tier
  track  = { 0, 0, 0, 0.55 },           -- the UNFILLED part of every rail: since v15 this is
                                        -- the rail's own backgroundColor, not a second region
  plate  = { 0, 0, 0, 0.45 },           -- the strip's floor, bordered
  alarm  = { 1, 0.1, 0.1, 0.85 },       -- the 80%-threat frame, unchanged from the v13 halo
  ruler  = { 1, 1, 1, 0.18 },           -- quarter hairlines: 33px of ink, zero footprint
  notch  = { 1, 1, 1, 0.85 },           -- the 70 notch on the threat rail
  hpLow  = { 0.9, 0.12, 0.12, 1 },      -- the <30% escalation AND its waterline
  mpLow  = { 0.85, 0.2, 0.2, 1 },       -- the <20% escalation AND the Go Viper waterline
  mpHigh = { 0.4, 1, 0.4, 1 },          -- the Back to Hawk waterline
  hpText = { 1, 1, 1, 1 },
  mpText = { 0.55, 0.75, 1, 1 },        -- echoes the power rail, so the two numbers
  thText = { 0.75, 0.95, 0.78, 1 },     -- never need labels to be told apart
}

-- wa_factory's stub() is local to the factory; the hand-written region tables below get the
-- identical scaffolding here.
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

-- THE POSITION OF A VALUE ON A RAIL. One formula, and it is the reason the strip exists:
-- a breakpoint is now arithmetic. maxValue is passed rather than assumed because Vigor-style
-- talents raise a cap (energy 100 -> 110) and the general form has to survive that; for a
-- hunter's mana percentage the scale is literally 0..100, so x = v - 50.
local function railX(value, maxValue)
  return (value / (maxValue or 100) - 0.5) * RAIL_LEN
end

-- THE RAIL. A progresstexture on the LINEAR fill path — the same region type the rings were,
-- with ONE different field, and that field silently changes which of the others are live.
-- Field notes on the ones that are traps:
--   orientation "HORIZONTAL_INVERSE" -> WeakAuras' own label for this value is "Left to Right".
--     Plain "HORIZONTAL" on a progresstexture is "Right to Left", which is the EXACT INVERSE of
--     the aurabar convention in references/gotchas.md ("HORIZONTAL = anchored left, grows
--     right"). Both names come from Private.orientation_with_circle_types, transcribed verbatim
--     in poc/diablo-globes/generate.lua; the sibling value VERTICAL from that same table is
--     live in a shipped poc string, but no committed string in THIS repo has yet rendered
--     HORIZONTAL_INVERSE. It is the one field in the design that a live client has to confirm,
--     and the check is 30 seconds long: drop to half mana and the EMPTY half must be on the
--     RIGHT. If it is reversed, the fix is this one token.
--   startAngle 0 / endAngle 360 -> INERT on the linear path (they only matter on the circular
--     one). Emitted because they are in the 3.5.0 default table and WA reads them unguarded.
--   crop_x / crop_y = 0.41 -> on the CIRCULAR path this was the identity value that cancels the
--     sqrt(2) expansion; on the LINEAR path it is simply the default texcoord scale. Same
--     number, completely different reason, and with uniform white art it cannot alter the ink.
--   compress / slanted / slant / slantFirst / slantMode -> LIVE again on this path (the rings
--     made them inert). All off, so the rail is a plain rectangle.
--   backgroundOffset = 0 -> the default 2 fattens the track relative to the fill, which reads
--     as a halo around the bar instead of the groove the bar runs in.
--   sameTexture = true -> backgroundTexture becomes dead code; both are set anyway.
--   auraRotation = 0 -> absent from the 3.5.0 default table but read unconditionally by current
--     code as data.auraRotation / 180 * math.pi, so it must be emitted.
--   adjustedMin/Max are STRINGS (""), because SetAdjustedMin does adjustedMin:find(...).
--   progressSource is rewritten to {-1, ""} by Modernize < 71 no matter what is emitted; it is
--     here for readability. {-1,""} = Automatic, which is what routes the Health/Power/Threat
--     prototype's value/total into the fill with no further wiring.
-- ONE PROGRESS TRIGGER PER RAIL, and it must be trigger 1: Modernize < 71 forces Automatic and
-- F.triggers sets activeTriggerMode = -10 (first_active). A second trigger can only feed
-- conditions (that is what F.unitCharTrigger does below), never the fill. That constraint is
-- what makes the stack necessary at all — health and power cannot share a region, so they have
-- to be two rails.
local function rail(id, lane, color, triggers)
  return orbStub{
    regionType = "progresstexture", id = id, uid = W.uid(), parent = nil,
    width = RAIL_LEN, height = lane.h,
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    xOffset = 0, yOffset = lane.y, frameStrata = 1, alpha = 1,
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
    triggers = triggers,
    load = F.load(CLASS),
  }
end

-- A percentage printed inside its own rail.
-- THE OFFSET KEY IS `text_anchorXOffset` / `text_anchorYOffset`, NOT the bare pair. Both names
-- live in the subtext default table, but SubText.modify only ever reads the text_-prefixed pair
-- (`region.text_anchorXOffset = data.text_anchorXOffset`, then Anchor() passes
-- `self.text_anchorYOffset or 0` to AnchorSubRegion) — in WA 3.5.0 AND in current code, and no
-- Modernize block renames one to the other. Writing only `anchorXOffset` is a silent no-op that
-- stacks every readout dead centre. Both are set here: the text_ pair does the work, the bare
-- pair keeps the table self-consistent.
local function pct(sym, size, x, y, color)
  local st = F.subtext("%" .. sym .. "%%", size, "CENTER", sym)
  st.text_anchorXOffset, st.text_anchorYOffset = x, y
  st.anchorXOffset, st.anchorYOffset = x, y
  st.text_color = color
  return st
end

-- A static mark ON A RAIL: a subtexture waterline at x = railX(value). v12/v13/v14 placed the
-- same two aspect marks by trigonometry on a circumference; here a breakpoint is a column, and
-- a full-height bar reads as a waterline the fill crosses rather than as a dot beside an arc.
-- Both marks are derived from railX, so a future change to RAIL_LEN can never leave them
-- behind — which is the exact bug v9 had to fix by hand after v8 grew the mana ring.
--
-- Still a `subtexture`: `subtick`, the aurabar tick, is aurabar-ONLY (SubRegionTypes/Tick.lua:
-- supports() returns regionType == "aurabar"), while subtexture's supports() does list
-- progresstexture. The art is a plain white square, so textureRotate / textureRotation stay
-- off — rotation there is texture-COORDINATE based and a square is invariant under it.
-- xOffset/yOffset are NOT in the subtexture default() table but ARE what modify() hands to
-- AnchorSubRegion, so they must be emitted or every mark stacks at dead centre.
local MARK_W  = 3   -- a breakpoint waterline: wide enough to read, narrow enough to be a line
local RULER_W = 1   -- a quarter hairline
local NOTCH_W = 2   -- the 70 notch on the 4px threat rail
local function railMark(value, maxValue, w, h, color)
  return {
    type = "subtexture",
    textureVisible = true,
    textureTexture = RAIL_TEX,
    textureColor = color, textureBlendMode = "BLEND",
    textureDesaturate = false, textureMirror = false,
    textureRotate = false, textureRotation = 0,
    anchor_mode = "point", anchor_point = "CENTER", self_point = "CENTER",
    anchor_area = "ALL",
    width = w, height = h,
    scale = 1, mirror = false, rotate = false,
    xOffset = railX(value, maxValue), yOffset = 0,
  }
end

-- THE RULER: three hairlines at 25 / 50 / 75, appended AFTER everything already present on a
-- rail so no existing sub.N index moves. 33px of ink and no footprint at all, and it converts
-- the rail from "estimate a fraction" to "count quarters".
local RULER = { 25, 50, 75 }
local function appendRuler(region, lane)
  for _, q in ipairs(RULER) do
    region.subRegions[#region.subRegions + 1] =
      railMark(q, 100, RULER_W, lane.h, COL.ruler)
  end
end

-- ===== 1. top-level group, anchored below the character =====
-- TOP_Y is this group's own offset and every absolute number in the canon is expressed
-- against it, so the literal below and TOP_Y must stay the same value.
local top = F.group(TOP, 0, TOP_Y, nil)
top.uid = W.uid()

-- ===== 2. Resources: the sill (singular, since v13) =====
-- v8 emptied the middle of the screen of its bar stack, v10 filled the low band with three
-- globes instead, v12 put the rings back beside the character, v13 dropped the right-hand
-- cluster entirely, and v15 flattens what is left into one strip: this group still holds
-- exactly one child. It keeps its id and its uid across every one of those versions — an
-- existing user gets an in-place Update, not a second copy — and v15 does NOT touch its offset
-- at all: it stays the +180 it has carried since v11 (an absolute (0, +40)), and the sill group
-- underneath it carries the -150 that puts the strip under the character at (0, -110).
local gRes = reg(F.group("Hunter - Resources", 0, G.resY, nil))
adopt(top, gRes)

-- 3. LIFE — don't die. The same aura as v7's health bar, v8/v9's health ring, v10/v11's globe
--    and v12-v14's 84px arc: same id, same uid, same two triggers, same escalation, same
--    zero-total guard. v15 re-shapes it into the 100x11 HEALTH RAIL, the middle lane, with the
--    percentage printed inside its own right end. It is re-parented into the sill group in the
--    block at the bottom of this file, because that group is a newer aura and every new
--    W.uid() call has to come after all the existing ones.
--    The <30% escalation is on `foregroundColor` — NOT `barColor` (aurabar-only) and NOT
--    `color` (the texture name the v10/v11 rim used). Conditions.lua skips a change whose
--    property the region does not declare, in silence, so the wrong name ships a dead
--    escalation that nothing warns you about. It is byte-identical to what v14 shipped.
local hp = reg(rail("Hunter - Health", LANE.health, COL.health,
  F.triggers({ F.healthTrigger(nil), F.unitCharTrigger() })))
hp.subRegions[1] = pct("percenthealth", NUM_PT, NUM_X, 0, COL.hpText)
-- The 30% waterline is NOT a subregion here: it is the recycled `Hunter - Power Ring Track`
-- region, built at the bottom of this file (a subregion cannot carry a uid, and that uid had
-- to go somewhere useful). sub.2-4 are the ruler.
appendRuler(hp, LANE.health)
hp.conditions = {
  F.condition(1, "percenthealth", "<", "30", "foregroundColor", COL.hpLow),
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  -- ZERO-TOTAL GUARD, and it is not optional. The Health prototype's total is
  -- UnitHealthMax(unit) with NO floor, and ProgressTexture.UpdateValue starts at
  -- progress = 1 and only divides when total > 0 — so a unit whose max health has not
  -- streamed in yet would flash a FULL bar. The aurabar did the opposite (it starts at
  -- 0), which is why v7 needed no such guard. Last, so it wins over the combat fade.
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

-- 4. POWER — the hunter resource, and it is MANA in every hunter spec, so the rail is the
--    canon mana blue. Turns red at the Viper threshold (20%: Viper's regen scales off MISSING
--    mana, so swapping at 15% is already late). The BOTTOM lane, carrying the two aspect-swap
--    breakpoints as full-height waterlines, so the swap band is visible before either alert
--    fires.
local mana = reg(rail("Hunter - Mana", LANE.power, COL.mana,
  F.triggers({ F.powerTrigger(0), F.unitCharTrigger() })))
mana.subRegions[1] = pct("percentpower", NUM_PT, NUM_X, 0, COL.mpText)
-- APPEND-ONLY: no condition in this pack points at sub.N on this aura today, but the readout
-- must stay index 1 if one ever does — so the two marks keep the indices 2 and 3 they have held
-- since v8. v15 changes what they ARE (circumference marks back to waterlines) and not where
-- they live: the 20% mark moves from (27.71, 9.0) to x = -30 and the 80% from (-27.71, 9.0) to
-- x = +30, both by the one formula x = v - 50, which the mark proof at the bottom re-derives.
--   NOT ASPECT-GATED, and it cannot be from here: a subregion carries no load gate of its own,
--   so both marks are always drawn even though "Go Viper" only matters in Hawk and "Back to
--   Hawk" only in Viper. Making them gate would mean promoting them to standalone textures,
--   which costs two NEW uid() draws; v15 spends no new uids at all, so it is left as it was.
mana.subRegions[2] = railMark(20, 100, MARK_W, LANE.power.h, COL.mpLow)   -- Go Viper
mana.subRegions[3] = railMark(80, 100, MARK_W, LANE.power.h, COL.mpHigh)  -- Back to Hawk
appendRuler(mana, LANE.power)                                            -- sub.4-6
mana.conditions = {
  F.condition(1, "percentpower", "<", "20", "foregroundColor", COL.mpLow),
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  -- Power is the one prototype that floors its own total (math.max(1, UnitPowerMax)),
  -- which is why this guard reads <= 1 and not <= 0. Inert for a hunter, kept for shape.
  F.condition(1, "maxpower", "<=", "1", "alpha", 0),
}

-- v5: "everywhere except an arena", spelled out. The `size` load arg declares no
-- `inverse` and no `test`, so there is genuinely no "not arena" key — the complement has
-- to be enumerated, and the emitted load test is a plain OR of string compares. `none` is
-- the load-bearing entry: in the open world GetInstanceTypeAndSize returns the literal
-- STRING "none" (its explicit fallthrough return, not nil), so leaving it out would delete
-- the threat readout while questing. `pvp` (battleground) stays in: AV has NPCs and a real
-- threat table. `arena` is the only key left out — an arena has no threat table at all, so
-- there the readout is a dead green shape wrapped around every opponent you click.
local function noArenaSize()
  return { multi = {
    none = true, party = true, ten = true, twenty = true,
    twentyfive = true, fortyman = true, pvp = true,
  } }
end

-- 5. threat — escalating tiers, each one paired with the ability that answers it:
--    orange at 70 (Misdirection prompt), red at 90 (Feign Death prompt), deep red
--    on aggro. Most severe condition last. Group-gated: solo you ARE the threat
--    list, so it would sit pegged at 100%.
--    v15: threat is the TOP LANE, a 100x4 hairline rail above health and power — the thinnest
--    lane because it is the one you check least often, and still 100px long so it keeps every
--    state. Same aura, same uid, same trigger (`threatUnit`, never `unit` — the arg was renamed
--    at internalVersion 51 and Modernize migrates < 51 data forward), same party/raid +
--    not-arena gates, same three tiers, same zero-total guard, all byte-identical to v14.
--    The property has now been renamed four times across the versions: `barColor` on the v7
--    aurabar, `foregroundColor` on the v8/v9 ring, `color` on the v10/v11 rim texture,
--    `foregroundColor` again on the v12-v14 arc and on this rail. Every one of those renames is
--    SILENT — Conditions.lua skips a change whose property the region does not declare, without
--    an error — so a mechanical port would ship dead escalations and a bar that never changes
--    colour.
local threat = reg(rail("Hunter - Threat", LANE.threat, COL.threat,
  F.triggers({ threatTrigger(nil) })))
-- THE NUMBER IS SWITCHED OFF, NOT DELETED. sub.1 keeps its index, its text token, its font and
-- its offsets so a user can tick it back on in /wa in one click; it only carries
-- text_visible = false. threatpct is SCALED so 100 = pulling aggro, which makes it an
-- early-warning ratio rather than a quantity you spend — "68 vs 72" is slower to read than a
-- fill crossing a notch, and at 10pt above the strip it was the one element of the cluster that
-- printed onto open screen with nothing behind it.
threat.subRegions[1] =
  pct("threatpct", PCT_THREAT.size, PCT_THREAT.x, PCT_THREAT.y, COL.thText)
threat.subRegions[1].text_visible = false
-- sub.2 (APPENDED, never inserted): the 70 notch — the exact point at which you press
-- Misdirection or stop shooting. x = 70 - 50 = +20.
threat.subRegions[2] = railMark(70, 100, NOTCH_W, LANE.threat.h, COL.notch)
threat.conditions = {
  F.condition(1, "threatpct", ">=", "70", "foregroundColor", { 1, 0.6, 0.1, 1 }),
  F.condition(1, "threatpct", ">=", "90", "foregroundColor", { 0.95, 0.25, 0.1, 1 }),
  F.condition(1, "aggro", "==", 1, "foregroundColor", { 0.9, 0.12, 0.12, 1 }),
  -- THE GUARD THIS READOUT CANNOT SHIP WITHOUT. AuraBar.lua draws EMPTY at total == 0;
  -- ProgressTexture.lua draws FULL (`local progress = 1; if self.total > 0 then ...`), on the
  -- linear path exactly as on the circular one. threattotal is threatvalue * 100 / threatpct,
  -- so it is 0 whenever threatvalue is 0 — the instant after a Feign Death, and the instant
  -- before your first hit lands. With no guard the rail would slam to a COMPLETE GREEN BAR,
  -- i.e. "you are at the pull threshold and fine", at the exact moment the readout exists to
  -- speak. Hide it instead and let its own dark track show through, which says nothing at all.
  F.condition(1, "threatvalue", "<=", "0", "alpha", 0),
}
-- BOTH THREAT REGIONS' GROUP GATE IS `use_ingroup = FALSE`, AND THE `false` IS THE WHOLE POINT.
-- A multiselect load option has three states, and only one of them reads the `multi` table:
--   nil   -> the gate is disabled entirely,
--   false -> MULTI mode: WeakAuras ORs every key of ingroup.multi,
--   true  -> SINGLE mode: it reads ingroup.SINGLE and ignores multi completely.
-- Every version of this pack from v5 to v14 wrote `true` next to a `multi` table and no
-- `single`. TestForMultiSelect (WeakAuras/GenericTrigger.lua) does this in that case:
--     elseif(trigger["use_"..name]) then          -- single selection
--       local value = trigger[name] and trigger[name].single
--       if (not value) then test = "false"; return test end
-- and ConstructFunction joins every test with " and " — so the load function of both regions
-- was `if (class==...) and false and (size==...) then`, i.e. the threat rail and the 80% alarm
-- NEVER LOADED, in a party, in a raid, or anywhere. The top lane was dead in the game while
-- three versions of the README explained how to read it. The not-arena size gate two lines
-- below has always been `false`, which is exactly why THAT gate has always worked.
threat.load.use_ingroup = false   -- false = MULTI mode (true would read .single, which is nil)
threat.load.ingroup = { multi = { group = true, raid = true } }
threat.load.use_size = false   -- false = MULTI mode (nil would disable the gate)
threat.load.size = noArenaSize()

-- 6. threat >= 80% in a party/raid: the strip grows a red rim and pulses. Same aura, same uid,
--    same trigger, same gates, same colour and the same alphaPulse it has had since v7 — only
--    the shape and the art ever change. v13 gave it the threat ring's own 100px diameter; v15
--    makes it a 108x37 quad drawn FIRST, at the BOTTOM of the sill's stack.
--    IT IS A RIM, AND THE SIZE AND THE DRAW INDEX ARE BOTH LOAD-BEARING. Square_White_Border.tga
--    is a FILLED square with a dark bevel baked into its edge — 98.44% of its pixels are fully
--    opaque and everything 8px in from the edge is alpha 255 (see the measurement at the texture
--    constants above) — so one region on that art cannot draw a hollow frame. Sized to the plate
--    and drawn last, this aura was a full-area additive red WASH over both readouts, the 30%
--    waterline, the ruler and all three rails, at the exact moment you are reading them to choose
--    Misdirection or Feign Death. Sized to PLATE + 2*RIM and drawn FIRST, the only part of it the
--    player ever sees is the 3px band protruding past the plate: the rest is behind a 45%-black
--    plate and behind every readout standing on it. Nothing is painted over, and the alarm is
--    still 108*37 - 102*31 = 834 px2 of pulsing red framing the instrument, which is unmissable.
--    THE BAND IS NOT EQUALLY BRIGHT ON ALL FOUR SIDES, and that follows from the same
--    measurement. The bevel is a fixed FRACTION of the 256px source (the dark ramp is its first
--    ~8 columns), so it scales with each axis of the quad independently: on a 108-wide, 37-tall
--    quad one screen pixel is 256/108 = 2.37 source px across but 256/37 = 6.92 source px down.
--    The 3px band therefore samples source 0..7.11 on the left and right — almost entirely the
--    dark ramp, mean texel 74/255 — and source 0..20.76 on the top and bottom, which is the ramp
--    plus a dozen rows of solid white, mean texel 185/255. The top and bottom of the rim read
--    about 2.5x brighter than its sides (ADD contribution 0.62 vs 0.25 at alpha 0.85). That is
--    geometry, not a defect, it is identical in every pack on this canon, and the plate's own
--    border has the same 2.5x asymmetry; it is written down so no line here claims an even band.
--    DROP EITHER HALF AND IT SILENTLY BECOMES A WASH AGAIN — equal size means the plate covers
--    it exactly, drawing it last means it covers the plate exactly — so the canon at the bottom
--    of this file asserts BOTH, and re-asserts them on the decoded string.
--    THE COLOUR IS EXPLICIT AND ASSERTED. Some packs in this repo ship `color = {}` on this
--    region, which draws in WeakAuras' default rather than red; this one has always shipped
--    { 1, 0.1, 0.1, 0.85 } and the plate proof at the bottom refuses to let that drift.
local flash = reg(F.texture("Hunter - Threat Flash", CLASS, ALARM_W, ALARM_H,
  0, LANE.plate.y, nil, PLATE_TEX, COL.alarm))
flash.blendMode = "ADD"
flash.triggers = F.triggers({ threatTrigger(80) })
flash.load.use_ingroup = false   -- see the three-state note on the threat rail above
flash.load.ingroup = { multi = { group = true, raid = true } }
flash.load.use_size = false
flash.load.size = noArenaSize()
flash.animation.main = F.animPreset("alphaPulse", "1")

-- ===== 7. Buffs: static row of aura timers =====
-- v10 was the ONE version in which something outside the resources group had to move: this row
-- sat at an absolute (0, -156), the globes landed on the band at -262, and the target globe
-- would have been drawn straight through Serpent Sting and Hunter's Mark. The row was
-- re-anchored 96px up to an absolute (0, -60).
-- v11, v12, v13 and v14 DID NOT TOUCH IT and NEITHER DOES v15: this row keeps v10's home and
-- every icon in it keeps its id, uid, trigger, load gate, condition, size and both offsets —
-- byte-identical across all six versions.
--   The clearance is derived, not picked, and v15 is the version where it finally matters in Y.
--   The row is 40px icons centred at BUFF_Y = -60, spanning x -64..64 and y -80..-40; the strip
--   is 102x31 centred at (0, SILL_Y + LANE.plate.y) = (0, -107), spanning x -51..51 and
--   y -91.5..-122.5. They share a column for the first time in this pack's history, so the
--   11.5px gap between -80 and -91.5 is now load-bearing and the rectangle scan at the bottom
--   of this file measures it instead of trusting it.
local BUFF_Y = -60
local gBuffs = reg(F.group("Hunter - Buffs", 0, BUFF_Y - TOP_Y, nil))
adopt(top, gBuffs)

-- 8. Serpent Sting — own DoT on the target, glows in the refresh window
local serpent = reg(F.icon("Hunter - Serpent Sting", CLASS, 40, 40, -44, 0, nil))
serpent.triggers = F.triggers({ F.auraTrigger("target", false, SERPENT, { ownOnly = true }) })
serpent.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
serpent.conditions = { F.condition(1, "expirationTime", "<=", "3", "sub.1.glow", true) }
serpent.zoom = 0.3
table.insert(serpent.subRegions, F.subborder())
adopt(gBuffs, serpent)

-- 9. Hunter's Mark — any hunter's mark counts, so no ownOnly
local mark = reg(F.icon("Hunter - Hunters Mark", CLASS, 40, 40, 0, 0, nil))
mark.triggers = F.triggers({ F.auraTrigger("target", false, MARK) })
mark.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
mark.zoom = 0.3
table.insert(mark.subRegions, F.subborder())
adopt(gBuffs, mark)

-- 10. The Beast Within — BM burst window (18s). Shares the x=44 slot with SV's
--     Expose Weakness; the two specs are mutually exclusive.
local tbw = reg(F.icon("Hunter - The Beast Within", CLASS, 40, 40, 44, 0, nil))
tbw.triggers = F.triggers({ F.auraTrigger("player", true, { TBW }) })
tbw.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
tbw.zoom = 0.3
table.insert(tbw.subRegions, F.subborder())
tbw.load.use_spellknown = true
tbw.load.spellknown = BWRATH
adopt(gBuffs, tbw)

-- 11. Expose Weakness — the SV raid mandate: keep this 7s debuff at ~100%.
--     The talent is passive, so there is no positive id to gate on. v3 gates it the
--     other way instead: use_not_spellknown = Bestial Wrath hides it from Beast
--     Mastery, the one spec that can never apply it (the proc is a Survival talent,
--     and the trigger is ownOnly). That also makes the shared x=44 slot single-
--     occupancy by LOAD rather than by talent arithmetic — BM sees The Beast Within
--     there, everyone else sees Expose Weakness. Needs WA 5.4.0+; older clients
--     ignore the field and load it for everyone, i.e. exactly the v2 behaviour.
local expose = reg(F.icon("Hunter - Expose Weakness", CLASS, 40, 40, 44, 0, nil))
expose.triggers = F.triggers({ F.auraTrigger("target", false, { EXPOSE }, { ownOnly = true }) })
expose.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
expose.zoom = 0.3
table.insert(expose.subRegions, F.subborder())
expose.load.use_not_spellknown = true
expose.load.not_spellknown = BWRATH
adopt(gBuffs, expose)

-- ===== 12. Alerts: glowing prompts flowing upward beside the character =====
local gAlerts = reg(F.dynGroup("Hunter - Alerts", -150, 96, nil, "UP", "BOTTOM", 6))
adopt(top, gAlerts)

-- 13. no aspect at all (neither Hawk nor Viper), in combat
local aspectIds = {}
for _, id in ipairs(HAWK) do aspectIds[#aspectIds + 1] = id end
aspectIds[#aspectIds + 1] = VIPER
local aspect = reg(F.icon("Hunter - ASPECT MISSING", CLASS, 40, 40, 0, 0, nil))
aspect.triggers = F.triggers({
  F.auraTrigger("player", true, aspectIds, { matchesShowOn = "showOnMissing" }),
})
aspect.iconSource = 0
aspect.displayIcon = "Interface\\Icons\\Spell_Nature_RavenForm"
aspect.cooldown = false
aspect.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
aspect.zoom = 0.3
table.insert(aspect.subRegions, F.subborder())
aspect.load.use_combat = true
aspect.load.use_spellknown = true
aspect.load.spellknown = HAWK[1]
alertAnim(aspect)
adopt(gAlerts, aspect)

-- 14. Kill Command: (ranged crit OR spell crit OR melee crit by me) AND KC ready.
--     Sanctioned one-liner #1 (Riposte pattern). TBC Kill Command is enabled by
--     ANY crit of yours, so the melee swing counts while the pet tanks in a dungeon.
local kc = reg(F.icon("Hunter - Kill Command", CLASS, 40, 40, 0, 0, nil))
local kc1 = F.clogTrigger("RANGE", "_DAMAGE", "5",
  { use_sourceUnit = true, sourceUnit = "player", use_critical = true })
local kc2 = F.clogTrigger("SPELL", "_DAMAGE", "5",
  { use_sourceUnit = true, sourceUnit = "player", use_critical = true })
local kc3 = F.clogTrigger("SWING", "_DAMAGE", "5",
  { use_sourceUnit = true, sourceUnit = "player", use_critical = true })
local kc4 = F.cdTrigger(KILLCMD, "Kill Command", "showOnReady")
kc.triggers = F.triggers({ kc1, kc2, kc3, kc4 }, {
  disjunctive = "custom",
  customTriggerLogic = "function(t) return (t[1] or t[2] or t[3]) and t[4] end",
})
kc.iconSource = 0
kc.displayIcon = "Interface\\Icons\\Ability_Hunter_KillCommand"
kc.subRegions[1] = F.subglow(true, { 1, 0.82, 0.1, 1 })
kc.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
kc.zoom = 0.3
table.insert(kc.subRegions, F.subborder())
kc.load.use_spellknown = true
kc.load.spellknown = KILLCMD
alertAnim(kc)
adopt(gAlerts, kc)

-- 15. Mongoose Bite: (swing OR spell dodged BY me) AND MB ready.
--     Sanctioned one-liner #2 — dest=player, missType DODGE.
local mb = reg(F.icon("Hunter - Mongoose Bite", CLASS, 40, 40, 0, 0, nil))
local mb1 = F.clogTrigger("SWING", "_MISSED", "5",
  { use_missType = true, missType = "DODGE", use_destUnit = true, destUnit = "player" })
local mb2 = F.clogTrigger("SPELL", "_MISSED", "5",
  { use_missType = true, missType = "DODGE", use_destUnit = true, destUnit = "player" })
local mb3 = F.cdTrigger(MBITE, "Mongoose Bite", "showOnReady")
mb.triggers = F.triggers({ mb1, mb2, mb3 }, {
  disjunctive = "custom",
  customTriggerLogic = "function(t) return (t[1] or t[2]) and t[3] end",
})
mb.iconSource = 0
mb.displayIcon = "Interface\\Icons\\Ability_Hunter_SwiftStrike"
mb.subRegions[1] = F.subglow(true, { 0.4, 1, 0.4, 1 })
mb.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
mb.zoom = 0.3
table.insert(mb.subRegions, F.subborder())
mb.load.use_spellknown = true
mb.load.spellknown = MBITE
alertAnim(mb)
adopt(gAlerts, mb)

-- 16. threat >= 90% AND Feign Death ready -> drop it before you tank.
--     90, not 70: 70 is Misdirection's band (see "Misdirection Prompt" below), and
--     FD is a full threat wipe that costs shots and burns your MD setup. Combat +
--     party/raid gated: solo you are the entire threat list, so threatpct reads 100
--     forever and a permanently glowing prompt is exactly the noise this pack cuts.
local fd = reg(F.icon("Hunter - Feign Death Prompt", CLASS, 40, 40, 0, 0, nil))
fd.triggers = F.triggers({ threatTrigger(90), F.cdTrigger(FEIGN, "Feign Death", "showOnReady") })
fd.iconSource = 0
fd.displayIcon = "Interface\\Icons\\Ability_Rogue_FeignDeath"
fd.subRegions[1] = F.subglow(true, { 1, 0.45, 0.1, 1 })
fd.zoom = 0.3
table.insert(fd.subRegions, F.subborder())
fd.load.use_combat = true
-- MULTI mode. `use_ingroup = true` next to a multi table is SINGLE mode with a nil single,
-- which WeakAuras compiles to the literal test `false` — this prompt loaded NOWHERE from v5 to
-- v14. See the long note on the threat rail; the sweep at the bottom of this file now refuses
-- to write a string containing that shape on any aura.
fd.load.use_ingroup = false
fd.load.ingroup = { multi = { group = true, raid = true } }
fd.load.use_spellknown = true
fd.load.spellknown = FEIGN
alertAnim(fd)
adopt(gAlerts, fd)

-- 17. mana < 20% AND not already in Viper -> swap aspect
local viper = reg(F.icon("Hunter - Go Viper", CLASS, 40, 40, 0, 0, nil))
local vp = F.powerTrigger(0)
vp.use_percentpower = true
vp.percentpower = "20"
vp.percentpower_operator = "<"
local viperMissing = F.auraTrigger("player", true, { VIPER }, { matchesShowOn = "showOnMissing" })
viper.triggers = F.triggers({ vp, viperMissing })
viper.iconSource = 0
viper.displayIcon = "Interface\\Icons\\Ability_Hunter_AspectoftheViper"
viper.cooldown = false
viper.subRegions[1] = F.subglow(true, { 0.3, 0.7, 1, 1 })
viper.zoom = 0.3
table.insert(viper.subRegions, F.subborder())
viper.load.use_combat = true
viper.load.use_spellknown = true
viper.load.spellknown = VIPER
alertAnim(viper)
adopt(gAlerts, viper)

-- ===== 18. Cooldowns: horizontal row; talent icons appear only when known =====
local gCDs = reg(F.dynGroup("Hunter - Cooldowns", 0, -66, nil, "HORIZONTAL", "CENTER", 4))
adopt(top, gCDs)

-- 19-26. one recipe, two displays. WA cooldown text on and tooltip on hover for both.
--
-- v6: which display an icon gets is a CLASSIFICATION, made per ability against the raid
-- priority, not a blanket conversion (references/rotation-design.md, "Show what the player
-- CANNOT press").
--
--   rot = true  — a press-on-cooldown rotational button. Stays showAlways and carries the
--     gold ready-glow, because the glow IS the instruction and a hidden icon can never fire
--     one. Two states and no third: dim = still coming back, full colour + gold = press it.
--     Trigger 2 is the always-active state feeder that carries inCombat (disjunctive "all"
--     stays satisfied, and trigger 1 keeps driving the swipe), so out of combat the icon
--     fades and the glow is forced off — the row is still while you ride around.
--
--   rot = false — situational / utility / emergency / burst-window. genericShowOn becomes
--     showOnCooldown: the icon exists only while its cooldown runs, carrying the swipe and
--     the countdown, and disappears the moment the ability is back. The row is a dynamic
--     group, so the gap closes — ABSENCE IS THE READOUT. The desaturate goes with it: every
--     visible icon is on cooldown by definition, so greying them all would only make the
--     abilities harder to tell apart. (withActiveWindow below re-adds a desaturate to the
--     two burst icons, where it means something else entirely — see its comment.)
local GOLD = { 1, 0.82, 0.1, 1 }   -- this pack's "press it now" colour: Kill Command,
                                   -- the Misdirection prompt, SILENCE NOW — and now the row

local function addCD(name, spellId, gate, rot)
  local ic = reg(F.icon("Hunter CD - " .. name, CLASS, 32, 32, 0, 0, nil))
  ic.cooldownTextDisabled = false
  ic.useTooltip = true
  if rot then
    ic.triggers = F.triggers({ F.cdTrigger(spellId, name, "showAlways"), F.unitCharTrigger() })
    -- subRegions[1] is ALREADY a subglow — the icon prototype ships one with glow = false —
    -- so this REPLACES index 1 in place. Nothing shifts, and every sub.N condition in the
    -- pack keeps pointing at the subregion it was written for (the border stays index 2).
    ic.subRegions[1] = F.subglow(false, GOLD)
    -- LAST condition wins on a shared property: out of combat the icon dims and the ready
    -- glow is forced back off, so an idle hunter's row does not sit lit.
    local quiet = F.condition(2, "inCombat", "==", 0, "alpha", 0.5)
    quiet.changes[2] = { property = "sub.1.glow", value = false }
    ic.conditions = {
      F.condition(1, "onCooldown", "==", 1, "desaturate", true),
      F.condition(1, "onCooldown", "==", 0, "sub.1.glow", true),
      quiet,
    }
  else
    ic.triggers = F.triggers({ F.cdTrigger(spellId, name, "showOnCooldown") })
    ic.conditions = {}
  end
  ic.zoom = 0.3
  table.insert(ic.subRegions, F.subborder())
  if gate then
    ic.load.use_spellknown = true
    ic.load.spellknown = gate
  end
  adopt(gCDs, ic)
  return ic
end

-- A burst cooldown owns its ACTIVE window too: trigger 1 is the buff (so
-- first-active mode drives the swipe off the window's own timer) and trigger 2 the
-- cooldown, joined with disjunctive "any". While the window is live the icon is lit and
-- full colour; afterwards it desaturates for the rest of the cooldown. This is what tells
-- you the haste/damage window is still running, which is the part of the button that
-- changes the next 15-18s.
--
-- v6: trigger 2 is now showOnCooldown, so the icon leaves the row while the button is
-- ready — absence means available here exactly like everywhere else in the row. The two
-- visible states are unchanged: buff up (trigger 1 active, glow on, full colour, swipe =
-- the window) and recharging (trigger 2 only, glow off, dim). That is why THIS desaturate
-- survives the v6 pass while the plain row icons lost theirs: it does not mean "on
-- cooldown", it means "the window is spent", and the later sub.1.glow condition overrides
-- it for as long as the window is live.
local function withActiveWindow(ic, unit, auraIds, glowColor)
  local cd = ic.triggers[1].trigger
  ic.triggers = F.triggers({ F.auraTrigger(unit, true, auraIds), cd }, { disjunctive = "any" })
  ic.subRegions[1] = F.subglow(false, glowColor)
  local lit = F.condition(1, "show", "==", 1, "sub.1.glow", true)
  lit.changes[2] = { property = "desaturate", value = false }
  ic.conditions = { F.condition(2, "onCooldown", "==", 1, "desaturate", true), lit }
  return ic
end

-- The 4th column is the v6 classification. Only Multi-Shot is a press-on-cooldown button
-- in this block: both raid guides say to press it on cooldown in place of a Steady Shot
-- because it is more damage per use than Steady Shot even on a single target.
local cdBWrath = addCD("Bestial Wrath", BWRATH,  BWRATH, false)  -- BM 31-pt; opener burst
addCD("Intimidation",  INTIMID, INTIMID, false)  -- BM; a 3s stun, pressed at a moment
addCD("Readiness",     READY,   READY,   false)  -- SV 41-pt; spent to re-arm the opener
addCD("Wyvern Sting",  WYVERN,  WYVERN,  false)  -- SV 31-pt; CC, no raid rotation slot
local cdRapid = addCD("Rapid Fire",    RAPID,   nil, false)  -- baseline lvl 26; burst window
local cdMulti = addCD("Multi-Shot",    MULTI,   nil, true)   -- baseline lvl 18; ROTATIONAL
-- Misdirection and Feign Death both already have a threat-paired prompt in the alert flow
-- (70% and 90%), and the alert owns the moment. The row icon only answers "when is it back".
addCD("Misdirection",  MISDIR,  MISDIR, false)  -- trained at 70
addCD("Feign Death",   FEIGN,   nil,    false)  -- baseline, lvl 30

-- Rapid Fire's 15s +40% ranged haste is the bigger of the two haste windows the
-- pack sees (Quick Shots is the 12s +15% one), so the icon shows the window, not
-- just the button. Bestial Wrath's 18s buff lands on the PET (spell 19574 is the
-- pet aura; 34471 The Beast Within is the 41-pt hunter half, tracked in the buff
-- row), so a 31-pt BM finally gets a burst-window timer too.
withActiveWindow(cdRapid,  "player", { RAPID },  { 1, 0.85, 0.2, 1 })
withActiveWindow(cdBWrath, "pet",    { BWRATH }, { 1, 0.45, 0.1, 1 })

-- ===== 27. Procs: cloned tracker right of the bars =====
local gProcs = reg(F.dynGroup("Hunter - Procs", 110, 24, nil, "RIGHT", "LEFT", 4))
adopt(top, gProcs)

-- 28. Quick Shots — the smaller of the two ranged-haste windows (12s, +15%);
--     the bigger one is Rapid Fire, which now shows its window on its own icon
local quick = reg(F.icon("Hunter - Quick Shots", CLASS, 32, 32, 0, 0, nil))
quick.triggers = F.triggers({ F.auraTrigger("player", true, { QSHOTS }, { showClones = true }) })
quick.subRegions[1] = F.subglow(true, { 1, 0.85, 0.2, 1 })
quick.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
quick.zoom = 0.3
table.insert(quick.subRegions, F.subborder())
quick.animation.start  = F.animCustom("0.5", { alpha = 0, alphaType = "alphaPulse", scale = 1.5 }, "easeOut")
quick.animation.finish = F.animCustom("0.8", { x = 120, alpha = 0 }, "easeOut")
adopt(gProcs, quick)

-- ===== v2 additions =====
-- Everything below is NEW in v2 and must stay at the end: each region constructor
-- consumes one W.uid(), and the v1 auras keep their uids only if no uid() call is
-- inserted before theirs. Placement in the HUD is done by re-parenting afterwards
-- (adopt / reorder), which costs no uid.

-- 29. Arcane Shot — the other half of the "Multi-Shot or Arcane Shot" slot in the
--     1:1.5 weave, and the instant you press while moving. Same row recipe.
--     v6: ROTATIONAL. It is a 6s instant inside the core damage loop — the weave slot's
--     other half when mana allows, and the shot you press on cooldown the moment you have
--     to move — so it gets the ready-glow rather than being hidden. This is the closest
--     call in the row (a mana-permitting filler is not Multi-Shot), and it goes the
--     showAlways way on the tie-break rule: anything in the core loop keeps its glow.
local arcane = addCD("Arcane Shot", ARCANE, nil, true)  -- baseline, 6s cd (r1 = 3044)

-- 30. Back to Hawk — the return half of the aspect swap. Viper is a flat damage
--     loss (Hawk r8 = +155 ranged AP), so the moment mana is back you swap out.
--     Aspect MISSING cannot cover this: Viper counts as an aspect, so it is silent.
local hawkBack = reg(F.icon("Hunter - Back to Hawk", CLASS, 40, 40, 0, 0, nil))
local manaBack = F.powerTrigger(0)
manaBack.use_percentpower = true
manaBack.percentpower = "80"
manaBack.percentpower_operator = ">="
hawkBack.triggers = F.triggers({ manaBack, F.auraTrigger("player", true, { VIPER }) })
hawkBack.iconSource = 0
hawkBack.displayIcon = "Interface\\Icons\\Spell_Nature_RavenForm"
hawkBack.cooldown = false
hawkBack.subRegions[1] = F.subglow(true, { 0.4, 1, 0.4, 1 })
hawkBack.zoom = 0.3
table.insert(hawkBack.subRegions, F.subborder())
hawkBack.load.use_combat = true
hawkBack.load.use_spellknown = true
hawkBack.load.spellknown = HAWK[1]
alertAnim(hawkBack)
adopt(gAlerts, hawkBack)

-- 31. Misdirection prompt — the ability paired with the threat bar's 70% tier.
--     MD is the TBC hunter's actual answer to climbing threat; Feign Death (90%)
--     is the emergency behind it. Icon comes from trigger 2 (iconSource = 2), so
--     it is the real spell icon on every locale. Party/raid + combat gated: MD
--     needs a friendly target to hand the threat to.
local mdPrompt = reg(F.icon("Hunter - Misdirection Prompt", CLASS, 40, 40, 0, 0, nil))
mdPrompt.triggers = F.triggers({
  threatTrigger(70), F.cdTrigger(MISDIR, "Misdirection", "showOnReady"),
})
mdPrompt.iconSource = 2
mdPrompt.cooldown = false
mdPrompt.subRegions[1] = F.subglow(true, { 1, 0.82, 0.1, 1 })
mdPrompt.zoom = 0.3
table.insert(mdPrompt.subRegions, F.subborder())
mdPrompt.load.use_combat = true
mdPrompt.load.use_ingroup = false   -- MULTI mode; `true` reads .single and compiles to `false`
mdPrompt.load.ingroup = { multi = { group = true, raid = true } }
mdPrompt.load.use_spellknown = true
mdPrompt.load.spellknown = MISDIR
alertAnim(mdPrompt)
adopt(gAlerts, mdPrompt)

-- 32. Mend Pet — the pet is ~35-40% of BM damage and the prerequisite for Kill
--     Command. Two health triggers ("< 40" AND "> 0") mean the prompt covers the
--     hurt pet only; a dead pet is a different button and gets its own alert.
local mendPet = reg(F.icon("Hunter - Mend Pet", CLASS, 40, 40, 0, 0, nil))
mendPet.triggers = F.triggers({
  petHealth("<", 40), petHealth(">", 0), F.cdTrigger(MENDPET, "Mend Pet", "showOnReady"),
})
mendPet.iconSource = 3
mendPet.cooldown = false
mendPet.subRegions[1] = F.subglow(true, { 0.4, 1, 0.4, 1 })
mendPet.zoom = 0.3
table.insert(mendPet.subRegions, F.subborder())
mendPet.load.use_spellknown = true
mendPet.load.spellknown = MENDPET
alertAnim(mendPet)
adopt(gAlerts, mendPet)

-- 33. Revive Pet — a dead pet still knows Kill Command, so without this the pack's
--     best element glows for a button that does nothing. Pet exists and is at 0%.
local revivePet = reg(F.icon("Hunter - Revive Pet", CLASS, 40, 40, 0, 0, nil))
revivePet.triggers = F.triggers({
  petHealth("<=", 0), F.cdTrigger(REVIVE, "Revive Pet", "showOnReady"),
})
revivePet.iconSource = 2
revivePet.cooldown = false
revivePet.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
revivePet.zoom = 0.3
table.insert(revivePet.subRegions, F.subborder())
revivePet.load.use_spellknown = true
revivePet.load.spellknown = REVIVE
alertAnim(revivePet)
adopt(gAlerts, revivePet)

-- ===== v4 additions: the PvP layer =====
-- Same rule as the v2 block: everything new is constructed at the BOTTOM of the file
-- so no W.uid() call is inserted before an existing one, then re-parented into place
-- (re-parenting and renaming are free; uid CALL ORDER is what must never move).
--
-- Every element below carries its own arena/battleground load gate. A group's load is
-- not a child gate, so the gate is repeated per aura — which is also what makes the
-- dynamic groups collapse cleanly in PvE, where none of this loads at all.

-- use_size = false is NOT "off": multiselect load args are active for both true and
-- false and only inert at nil. false selects MULTI mode, which ORs the entries.
local PVP_SIZE   = { arena = true, pvp = true }   -- arena OR battleground
local ARENA_SIZE = { arena = true }               -- anything reading arena1..arena5:
                                                  -- those units do not exist in a BG
local function pvpLoad(sizes, extra)
  local l = F.load(CLASS)
  l.use_size = false
  local m = {}
  for k, v in pairs(sizes) do m[k] = v end        -- fresh table per aura
  l.size = { multi = m }
  for k, v in pairs(extra or {}) do l[k] = v end
  return l
end

-- The factory's private trigger stub, replicated for the prototypes it does not wrap.
local function trig(t)
  t.names = {}; t.spellIds = {}
  t.subeventPrefix = "SPELL"; t.subeventSuffix = "_CAST_START"
  t.debuffType = t.debuffType or "HELPFUL"
  return t
end

-- Item cooldown by NUMERIC item id. genericShowOn is mandatory — nil means the aura
-- never shows, the same trap as the spell version.
local function itemCD(itemId, showOn)
  return trig{ type = "item", event = "Cooldown Progress (Item)",
               use_itemName = true, itemName = itemId,
               use_genericShowOn = true, genericShowOn = showOn }
end

-- Spell Cast Succeeded: the only sanctioned enemy-cooldown *inference* on 2.5.x, and
-- the only way to know a trap is on the ground. duration is REQUIRED (string seconds);
-- without it the state lasts 1 second and nobody sees it.
local function castSucceeded(unit, ids, duration)
  local s = {}
  for i, id in ipairs(ids) do s[i] = tostring(id) end
  return { type = "event", event = "Spell Cast Succeeded",
           unit = unit, use_unit = true,
           use_spellId = true, spellId = s, duration = duration }
end

local gPvP = reg(F.dynGroup("Hunter - PvP", 150, 96, nil, "DOWN", "TOP", 6))
adopt(top, gPvP)

-- 34. CC ON ME — which break works, and whether to spend it now. No controlType filter,
--     so it matches ANY loss-of-control effect, including a Kick/Counterspell school
--     lockout, which is not an aura and which no aura trigger can ever see. The icon
--     comes from the trigger (iconSource -1) because the icon IS the identity of the
--     effect, and %p is the answer to "ride it or trinket it". No combat gate: the
--     opener lands before you are in combat.
local ccMe = reg(F.icon("Hunter - CC ON ME", CLASS, 40, 40, 0, 0, nil))
ccMe.triggers = F.triggers({ trig{ type = "unit", event = "Crowd Controlled" } })
ccMe.cooldown = false
ccMe.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })   -- red default = "trinket food"
ccMe.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
-- v5: the glow COLOUR carries the category, because under a stun a player parses colour and
-- never text. sub.1.glowColor is the real property name: "sub." .. <1-based subRegions index>
-- .. "." .. <key from the subregion's properties table>, and the subglow above is index 1.
-- Two preconditions, both satisfied here: useGlowColor must be true (otherwise SetGlowColor
-- stores the value and LibCustomGlow keeps using its own default — a silent no-op), which
-- F.subglow sets whenever a colour is passed; and the glow must be on, which it is. Values
-- are 4-element ARRAYS — an {r=,g=,b=,a=} hash would serialise to four nils.
-- Same five colours as the mage pack on purpose: one language across two characters.
-- Anything not listed (CHARM, DISARM, PACIFY, POSSESS) keeps the red base = "spend the break".
ccMe.conditions = {
  -- RED — stun. Nothing a hunter owns breaks a stun: it is the medallion or nothing,
  -- and the Trinket DOWN readout in the PvP stack is the other half of that sentence.
  F.condition(1, "controlType", "==", "STUN", "sub.1.glowColor", { 1, 0.15, 0.15, 1 }),
  F.condition(1, "controlType", "==", "STUN_MECHANIC", "sub.1.glowColor", { 1, 0.15, 0.15, 1 }),
  -- PURPLE — fear. Trinket, or Will of the Forsaken if you are Undead (the pack tracks
  -- that racial's cooldown separately, which is exactly the "which break do I spend" call).
  F.condition(1, "controlType", "==", "FEAR", "sub.1.glowColor", { 0.7, 0.3, 1, 1 }),
  F.condition(1, "controlType", "==", "FEAR_MECHANIC", "sub.1.glowColor", { 0.7, 0.3, 1, 1 }),
  -- GREEN — confuse / polymorph. Ride it: any damage breaks it, and your pet is already
  -- hitting something. Trinketing here throws the break away for an effect about to end.
  F.condition(1, "controlType", "==", "CONFUSE", "sub.1.glowColor", { 0.4, 0.95, 0.5, 1 }),
  -- BLUE — root. NOT a trinket: a hunter shoots at full effect while rooted, so keep firing
  -- and save the break for the stun that follows. A root only kills you if a melee is
  -- closing, and that case already has its own prompt (DEADZONE -> Scatter / trap / Wing Clip).
  F.condition(1, "controlType", "==", "ROOT", "sub.1.glowColor", { 0.3, 0.7, 1, 1 }),
  -- AMBER — silence or school lockout. Your shots and your traps are gone for the duration,
  -- so there is no "play through it" line: trinket EARLIER than you otherwise would.
  F.condition(1, "controlType", "==", "SILENCE", "sub.1.glowColor", { 1, 0.85, 0.2, 1 }),
  F.condition(1, "controlType", "==", "PACIFYSILENCE", "sub.1.glowColor", { 1, 0.85, 0.2, 1 }),
  F.condition(1, "controlType", "==", "SCHOOL_INTERRUPT", "sub.1.glowColor", { 1, 0.85, 0.2, 1 }),
}
ccMe.zoom = 0.3
table.insert(ccMe.subRegions, F.subborder())
ccMe.load = pvpLoad(PVP_SIZE)
alertAnim(ccMe)
adopt(gAlerts, ccMe)

-- 35. DEADZONE — a hostile target inside ~8 yards means Auto Shot, Steady Shot and
--     every other shot are dead, so the next press is Wing Clip / Scatter / trap /
--     melee, not a shot. "<=" tests max <= 8, i.e. "definitely inside the deadzone".
--     Trigger 2 keeps it off friendly targets. This is the pack's ONLY Range Check —
--     it polls on FRAME_UPDATE, which is exactly why it sits behind a PvP gate and a
--     combat gate. LibRangeCheck is an estimate, so nothing hard depends on it.
local deadzone = reg(F.icon("Hunter - DEADZONE", CLASS, 40, 40, 0, 0, nil))
deadzone.triggers = F.triggers({
  trig{ type = "unit", event = "Range Check", unit = "target",
        use_range = true, range = "8", range_operator = "<=" },
  trig{ type = "unit", event = "Unit Characteristics", unit = "target", use_unit = true,
        use_hostility = true, hostility = "hostile" },
})
deadzone.iconSource = 0
deadzone.displayIcon = "Interface\\Icons\\Ability_Hunter_SteadyShot"
deadzone.cooldown = false
deadzone.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
deadzone.zoom = 0.3
table.insert(deadzone.subRegions, F.subborder())
deadzone.load = pvpLoad(PVP_SIZE, { use_combat = true })
alertAnim(deadzone)
adopt(gAlerts, deadzone)

-- 36. SILENCE NOW — target is casting AND Silencing Shot is genuinely castable.
--     "Action Usable" folds cooldown + mana + range into one boolean, so the prompt
--     never appears for a button that would fail. No spell whitelist: TBC has no
--     interruptibility flag at all (WA disables the arg for IsTBC), so filtering by
--     id would only shrink coverage while pretending to add precision. Trigger 1 is
--     first, so %p counts down the cast; the icon comes from trigger 2 = the button.
local silence = reg(F.icon("Hunter - SILENCE NOW", CLASS, 40, 40, 0, 0, nil))
silence.triggers = F.triggers({
  trig{ type = "unit", event = "Cast", unit = "target", use_unit = true },
  trig{ type = "spell", event = "Action Usable",
        use_spellName = true, spellName = SILENCE, realSpellName = "Silencing Shot",
        use_exact_spellName = true, use_ignoreoverride = true },
})
silence.iconSource = 2
silence.cooldown = false
silence.subRegions[1] = F.subglow(true, { 1, 0.85, 0.2, 1 })
silence.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
silence.zoom = 0.3
table.insert(silence.subRegions, F.subborder())
silence.load = pvpLoad(PVP_SIZE, { use_spellknown = true, spellknown = SILENCE })
alertAnim(silence)
adopt(gAlerts, silence)

-- 37. TARGET IMMUNE — stop. Shooting into Divine Shield / Blessing of Protection /
--     Ice Block / Cloak of Shadows burns the whole burst for zero damage, and The
--     Beast Within means the trap and Scatter will not land either. iconSource -1
--     shows WHICH immunity, which is what decides swap vs wait-out.
local immune = reg(F.icon("Hunter - TARGET IMMUNE", CLASS, 40, 40, 0, 0, nil))
immune.triggers = F.triggers({ F.auraTrigger("target", true, IMMUNE) })
immune.cooldown = false
immune.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
immune.subRegions[2] = F.subtext("%p", 14, "INNER_BOTTOM")
immune.zoom = 0.3
table.insert(immune.subRegions, F.subborder())
immune.load = pvpLoad(PVP_SIZE)
alertAnim(immune)
adopt(gAlerts, immune)

-- 38. Trinket DOWN — "is my get-out-of-jail available". showOnCooldown only, so the
--     column is EMPTY in the normal case and absence means ready. Four triggers ORed
--     because itemName has no multiEntry; only one of them can ever be equipped, and
--     iconSource -1 means the icon is the trinket you actually own.
local trinket = reg(F.icon("Hunter - Trinket DOWN", CLASS, 32, 32, 0, 0, nil))
local trinketTrigs = {}
for i, id in ipairs(TRINKETS) do trinketTrigs[i] = itemCD(id, "showOnCooldown") end
trinket.triggers = F.triggers(trinketTrigs, { disjunctive = "any" })
trinket.cooldownTextDisabled = false
trinket.desaturate = true
trinket.zoom = 0.3
table.insert(trinket.subRegions, F.subborder())
trinket.load = pvpLoad(PVP_SIZE)
adopt(gPvP, trinket)

-- 39. Will of the Forsaken DOWN — Undead carry a second, independent 2-minute break,
--     and whether it is up is what decides if the medallion can be spent early.
--     Gated on the ability, not the race: no racial, no icon, no gap.
local wotf = reg(F.icon("Hunter - Will of the Forsaken DOWN", CLASS, 32, 32, 0, 0, nil))
wotf.triggers = F.triggers({ F.cdTrigger(WOTF, "Will of the Forsaken", "showOnCooldown") })
wotf.cooldownTextDisabled = false
wotf.desaturate = true
wotf.zoom = 0.3
table.insert(wotf.subRegions, F.subborder())
wotf.load = pvpLoad(PVP_SIZE, { use_spellknown = true, spellknown = WOTF })
adopt(gPvP, wotf)

-- 40. Enemy trinket — one clone per opponent, counting down 120s from the cast we
--     SAW. This is an inference, not a read: no API on 2.5.x exposes another player's
--     cooldowns. The countdown is the whole value — "they trinketed" as a one-shot
--     flash changes nothing, "their break is gone for 90 more seconds" is the go.
--     Arena-only, because unit = "arena" is meaningless in a battleground.
local enemyTrinket = reg(F.icon("Hunter - Enemy Trinket", CLASS, 32, 32, 0, 0, nil))
enemyTrinket.triggers = F.triggers({
  castSucceeded("arena", { PVPTRINK }, "120"),
})
enemyTrinket.cooldownTextDisabled = false
enemyTrinket.zoom = 0.3
table.insert(enemyTrinket.subRegions, F.subborder())
enemyTrinket.load = pvpLoad(ARENA_SIZE)
adopt(gPvP, enemyTrinket)

-- 41. Trap Armed — a trap is on the ground: pull the target across it, recall the pet
--     (your own pet is the most common trap-breaker) and do not waste the second one.
--     Inference again, with the trap's own 1-minute lifetime supplied: it cannot see
--     the trap being sprung or broken, so it is a maximum, not a fact.
local trapArmed = reg(F.icon("Hunter - Trap Armed", CLASS, 36, 36, 0, 0, nil))
trapArmed.triggers = F.triggers({ castSucceeded("player", FRZTRAP, "60") })
trapArmed.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
trapArmed.zoom = 0.3
table.insert(trapArmed.subRegions, F.subborder())
trapArmed.load = pvpLoad(PVP_SIZE, { use_spellknown = true, spellknown = FRZTRAP[1] })
adopt(gPvP, trapArmed)

-- 42. Viper Sting out — one clone per opponent carrying YOUR Viper Sting. Mana denial
--     is the hunter's win condition in a long game and the sting gets dispelled, so
--     the row emptying is the re-apply prompt. Tracked on the opponents rather than on
--     the kill target, because the drain belongs on whoever heals.
local viperOut = reg(F.icon("Hunter - Viper Sting Out", CLASS, 36, 36, 0, 0, nil))
viperOut.triggers = F.triggers({
  F.auraTrigger("arena", false, VIPERST, {
    ownOnly = true, showClones = true, combinePerUnit = true, perUnitMode = "affected",
  }),
})
viperOut.subRegions[2] = F.subtext("%p", 12, "INNER_BOTTOM")
viperOut.zoom = 0.3
table.insert(viperOut.subRegions, F.subborder())
viperOut.load = pvpLoad(ARENA_SIZE, { use_spellknown = true, spellknown = VIPERST[1] })
adopt(gPvP, viperOut)

-- 43-44. Scatter -> Trap is the hunter's entire opening game plan, and neither button
--        is in the PvE cooldown row. Both join it under the PvP gate, so the row is
--        byte-for-byte the same row in a raid and grows two icons in arena.
-- v6: both are CC openers held for a moment, never pressed on sight, so they are
-- situational like the rest of the row — showOnCooldown, and their PvP load gates are
-- untouched. In arena the row therefore reads "the trap is on cooldown for 22 more
-- seconds", and an empty row means the whole opener is available.
local cdTrap = addCD("Freezing Trap", FRZTRAP[1], nil, false)
cdTrap.load = pvpLoad(PVP_SIZE, { use_spellknown = true, spellknown = FRZTRAP[1] })
local cdScatter = addCD("Scatter Shot", SCATTER, nil, false)
cdScatter.load = pvpLoad(PVP_SIZE, { use_spellknown = true, spellknown = SCATTER })

-- ===== v5 addition: the one new aura, constructed last =====
-- Same append-only rule as v2 and v4: one new W.uid() call, at the very END of the file.

-- 45. ENEMY MANA — one bar per opponent who actually runs on mana, so the row IS the
--     healer list. Mana denial is the hunter's win condition in a long game, and Viper
--     Sting is a choice of target, not a rotation slot: this says which arena unit is worth
--     the sting and when the drain has done its job. Below 20% a healer cannot chain-heal
--     through a swap, so the bar goes amber — this pack's "press now" colour, the same one
--     SILENCE NOW and Kill Command wear.
--
--     The Power prototype is not pruned on TBC and its unit arg accepts "arena" (WA deletes
--     arena units only under IsClassicEra, not IsTBC), and statesParameter = "unit" makes it
--     clone one state per arena1..arena5 — hence the dynamicgroup parent. Both flags matter:
--     use_powertype = true AND powertype = 0 pin it to MANA, because without them the
--     trigger silently reads whatever bar that opponent primarily uses (a rogue's energy).
--     use_requirePowerType then hides every opponent whose PRIMARY bar is not mana, so the
--     rogue and warrior rows never appear and the row that remains is the one you care about.
--     Arena-gated only: arena1..arena5 do not exist in a battleground, so a BG-loaded copy
--     would be permanently blank rows.
local enemyMana = reg(F.aurabar("Hunter - Enemy Mana", CLASS, 120, 12, 0, 0, nil,
  { 0.25, 0.55, 0.95, 1 }))
local emPower = F.powerTrigger(0)          -- 0 = Mana, and use_powertype is already true
emPower.unit = "arena"                     -- multi-unit: one clone per opponent
emPower.use_requirePowerType = true        -- mana must be their PRIMARY bar
enemyMana.triggers = F.triggers({ emPower })
enemyMana.subRegions[2] = F.subtext("%name%", 10, "INNER_LEFT")
enemyMana.subRegions[3] = F.subtext("%percentpower%%", 10, "INNER_RIGHT", "percentpower")
enemyMana.subRegions[4] = F.subborder("bar")
enemyMana.conditions = {
  F.condition(1, "percentpower", "<", "20", "barColor", { 1, 0.85, 0.2, 1 }),
}
enemyMana.load = pvpLoad(ARENA_SIZE, { use_spellknown = true, spellknown = VIPERST[1] })
adopt(gPvP, enemyMana)

-- ===== the sill block: v8's slots, five retired by v13, all seven respent by v15 =====
-- Every version since v8 has kept this block's uid() calls in exactly the order they were
-- first made, and v15 keeps that order too — it only changes what each slot BUILDS.
--   v8/v9 slot order:  player cluster group, player portrait,  target cluster group,
--                      target health ring,   target mana ring, target portrait
--   v10/v11 meaning:   player globe group,   LIFE RIM,         target globe group,
--                      target globe,         target power globe, TARGET RIM
--   v12 meaning:       player cluster group, PLAYER PORTRAIT,  target cluster group,
--                      target health ring,   TARGET TRACK RING, TARGET PORTRAIT
--   v13/v14 meaning:   player cluster group, PLAYER PORTRAIT,  RETIRED, RETIRED, RETIRED,
--                      RETIRED,              player mana track, RETIRED
--   v15 meaning:       PLAYER SILL group,    SILL PLATE,       RETIRED, RETIRED, RETIRED,
--                      RETIRED,              HEALTH 30% WATERLINE, RETIRED
--
-- v15 DRAWS NO NEW UID AT ALL. Six regions and one group are exactly what the strip needs, and
-- six regions and one group are exactly what the cluster had — so every one of them is
-- re-typed, resized and re-parented in place. Re-parenting, renaming, re-typing and resizing
-- are all free; only the uid() CALL ORDER is sacred.
--
-- WHY THE DRAWS ARE BURNED RATHER THAN DELETED. W.uid() is 11 draws from a seeded stream, so
-- a uid is a POSITION, not a value. Delete the four target constructors outright and the next
-- surviving aura built after them silently inherits the uid that belonged to the target cluster
-- GROUP. WeakAuras matches auras across imports by uid, so on the player's machine that region
-- would import as an Update over their target cluster group. Burning the draw costs one line
-- each and keeps all 48 surviving uids byte-for-byte.
--
-- AND NO FILLER REGION IS INVENTED to give the five freed uids a home. That is how a HUD
-- accumulates junk — a region that exists only so a number has somewhere to live. WeakAuras
-- never deletes an aura an import does not mention, so the five simply stay behind in the
-- player's collection until they delete the leftover group by hand, which the README says in
-- as many words and names exactly.
--
-- WA-REMOVED (v13): Hunter - Target Cluster
-- WA-REMOVED (v13): Hunter - Target Health
-- WA-REMOVED (v13): Hunter - Target Ring Track
-- WA-REMOVED (v13): Hunter - Target Portrait
-- WA-REMOVED (v13): Hunter - Target Health Track
local REMOVED = {
  "Hunter - Target Cluster",      -- 48: the group itself, and the only one the player deletes
  "Hunter - Target Health",       -- 49: duplicated the target frame and the nameplate
  "Hunter - Target Ring Track",   -- 50: the last remnant of the v8/v9 target MANA arc
  "Hunter - Target Portrait",     -- 51: the target's face
  "Hunter - Target Health Track", -- 53: the socket under the target's health arc
}
local burned = 0
local function retire() burned = burned + 1; W.uid() end

-- 46. THE SILL — one plain group, not a dynamic one: its children are a fixed LANE STACK, each
--     at its own (x, y) in this frame, and the group carries the strip's position. That is what
--     makes the rails share one centreline by construction rather than by six hand-typed
--     absolute offsets that drift apart the first time somebody retunes one of them.
--     It keeps the uid it has had since v8 (as `Hunter - Player Cluster`) so this is an Update
--     in place; only its NAME and its offset change. The offset is DERIVED, never typed: it is
--     the canon absolute (0, -110) minus everything its ancestors already carry, so a change to
--     TOP_Y or to the Resources group can never silently drag the strip off the canon.
local sillParentX = (top.xOffset or 0) + (gRes.xOffset or 0)
local sillParentY = (top.yOffset or 0) + (gRes.yOffset or 0)
local gSill = reg(F.group("Hunter - Player Sill",
  G.sillX - sillParentX, G.sillY - sillParentY, nil))
adopt(gRes, gSill)

-- 47. THE SILL PLATE — the aura that was your live 3D portrait in v8, v9 and v12-v14, and the
--     globe's life rim in v10/v11. It keeps that uid, its two triggers and its out-of-combat
--     fade verbatim; it is re-typed model -> texture (the same move v10/v11 made in the other
--     direction) and becomes the 102x31 bordered floor the rails sit on, drawn FIRST so
--     everything else is in front of it.
--     WHY IT EARNS ITS PIXELS. The complaint that produced v14 was that a number on open screen
--     is unreadable over grass, snow or a fire; v14 answered it with the portrait, which is the
--     only opaque thing a ring cluster has. Flattening the cluster would have thrown that away,
--     so the portrait's surface is what the plate is made of: an 11px rail and an 11pt number
--     survive a bright zone because there is something dark and bordered behind them, and four
--     lanes on one plate read as ONE instrument instead of four floating bars.
--     WHAT IS LOST: the face itself. It carried no decision — nothing in a hunter's rotation is
--     decided by looking at a model — but it is the single most likely thing to be missed, and
--     the README says so in as many words rather than burying it.
local plate = reg(F.texture("Hunter - Sill Plate", CLASS, PLATE_W, PLATE_H,
  0, LANE.plate.y, nil, PLATE_TEX, COL.plate))
plate.triggers = F.triggers({ F.healthTrigger(nil), F.unitCharTrigger() })
plate.conditions = { F.condition(2, "inCombat", "==", 0, "alpha", 0.5) }

-- 48-51. THE TARGET CLUSTER: the group, its health arc, its track ring (the old target mana
--     satellite) and its portrait. All four went in v13. The target's health is already on the
--     target frame AND on its nameplate, so for the whole game this cluster restated something
--     the default UI never stops saying, in a place you have to look away to read.
retire()  -- 48. Hunter - Target Cluster
retire()  -- 49. Hunter - Target Health
retire()  -- 50. Hunter - Target Ring Track
retire()  -- 51. Hunter - Target Portrait

-- 52. THE HEALTH RAIL'S 30% WATERLINE — this slot was the mana ring's dark socket from v13,
--     and v15 makes that job disappear: a rail's unfilled part is its own `backgroundColor`,
--     not a second region behind it, so `Hunter - Power Ring Track` is redundant the instant
--     the rings become bars. A uid may never simply vanish (an orphan is an aura the player has
--     to hunt down and delete by hand), and there is exactly one mark on this strip that cannot
--     be a subregion of the rail it belongs to — so it is respent as the health rail's 30%
--     waterline, a standalone 3x11 texture at x = railX(30) = -20.
--     IT MOVES FROM THE POWER TRIGGER TO THE HEALTH TRIGGER, because it now annotates the
--     health rail: it must appear, fade and hide with the bar it is drawn on, and it inherits
--     that rail's maxhealth <= 0 alpha guard for the same reason the rail needs it — otherwise
--     a lone red line would hang in mid-strip while its own bar was hidden.
--     WHY 30 IS WORTH A LINE AT ALL: it is where the health rail changes colour, i.e. the exact
--     edge of the defensive window, and a permanent hairline is what makes "how close am I"
--     answerable BEFORE the colour flips rather than at the moment it does.
local hpMark = reg(F.texture("Hunter - Health 30% Mark", CLASS, MARK_W, LANE.health.h,
  railX(30, 100), LANE.health.y, nil, RAIL_TEX, COL.hpLow))
hpMark.triggers = F.triggers({ F.healthTrigger(nil), F.unitCharTrigger() })
hpMark.conditions = {
  F.condition(2, "inCombat", "==", 0, "alpha", 0.5),
  F.condition(1, "maxhealth", "<=", "0", "alpha", 0),
}

-- 53. TARGET HEALTH TRACK — the socket under the target's health arc. Gone with it in v13.
retire()  -- 53. Hunter - Target Health Track

assert(burned == #REMOVED,
  ("%d uid draws burned, %d regions declared removed"):format(burned, #REMOVED))

-- ===== DRAW ORDER IS THE STACK =====
-- Sibling stacking is exact, not "roughly creation order": FixGroupChildrenOrder walks
-- controlledChildren and adds +4 frame levels per child, so EARLIER = further behind, and the
-- flat transmit `c` list must be depth-first in this same order (references/encoding.md).
--   ALARM RIM FIRST, i.e. at the very BOTTOM of the stack. It is a FILLED 108x37 quad on ADD
--     (Square_White_Border is filled art, measured at the texture constants above), so the only
--     part of it that can read as an edge is the 3px band that protrudes past the 102x31 plate
--     drawn on top of it. Listed LAST it would instead be an additive red sheet over every rail,
--     every number and the ruler — a wash, which is the bug this order exists to prevent.
--   PLATE SECOND or it paints over every rail on it, and it is what buries the rim's interior.
--   The 30% WATERLINE AFTER the health rail, or it is drawn under an opaque bar and is
--     invisible at any health above 30% — which is every moment except the one it exists for.
adopt(gSill, flash)    -- 1  the rim, UNDER the plate: only its 3px overhang is ever visible
adopt(gSill, plate)    -- 2
adopt(gSill, threat)   -- 3  top lane
adopt(gSill, hp)       -- 4  middle lane
adopt(gSill, mana)     -- 5  bottom lane
adopt(gSill, hpMark)   -- 6  over the health rail

-- ===== layout order (no uid cost: controlledChildren order is pure layout) =====
local function placeFirst(group, id)
  for i, cid in ipairs(group.controlledChildren) do
    if cid == id then
      table.remove(group.controlledChildren, i)
      table.insert(group.controlledChildren, 1, id)
      return
    end
  end
  error("placeFirst: " .. id .. " is not a child of " .. group.id)
end

local function placeAfter(group, id, afterId)
  local pos
  for i, cid in ipairs(group.controlledChildren) do
    if cid == id then table.remove(group.controlledChildren, i) break end
  end
  for i, cid in ipairs(group.controlledChildren) do
    if cid == afterId then pos = i + 1 break end
  end
  table.insert(group.controlledChildren, assert(pos, "placeAfter: no " .. afterId), id)
end

-- ===== v15: THE STACK, PROVEN =====
-- The whole strip is one draw order and one lane arithmetic, and neither is visible by reading
-- a single line of this file. `controlledChildren` order IS the draw order (+4 frame levels per
-- child), so an element in the wrong slot is not a subtle bug — the plate paints over every
-- rail, or the alarm turns back into a full-area ADD wash, or the 30% waterline is buried under
-- the bar it annotates at every health above 30%.
do
  local WANT = { flash.id, plate.id, threat.id, hp.id, mana.id, hpMark.id }
  assert(#gSill.controlledChildren == #WANT,
    ("the sill has %d children, the stack declares %d")
      :format(#gSill.controlledChildren, #WANT))
  for i, id in ipairs(WANT) do
    assert(gSill.controlledChildren[i] == id,
      ("draw slot %d is %s, the stack says %s")
        :format(i, tostring(gSill.controlledChildren[i]), id))
  end
  -- THE TWO HALVES OF THE RIM, PINNED SEPARATELY, because either one alone is worthless.
  -- Equal size means the plate covers the alarm exactly; drawing it last means the alarm covers
  -- the plate exactly. Both failures land on the same symptom: a full-area additive red sheet
  -- over every rail, both numbers and the ruler, at >= 80% threat.
  assert(gSill.controlledChildren[1] == flash.id,
    "the alarm rim is not the FIRST child, so it draws over the readouts as a wash")
  assert(gSill.controlledChildren[2] == plate.id,
    "the plate is not the SECOND child, so nothing buries the rim's filled interior")
  assert(flash.width == plate.width + 2 * RIM and flash.height == plate.height + 2 * RIM,
    ("the alarm rim is %sx%s; a %dpx rim on a %sx%s plate is %sx%s")
      :format(tostring(flash.width), tostring(flash.height), RIM,
        tostring(plate.width), tostring(plate.height),
        tostring(plate.width + 2 * RIM), tostring(plate.height + 2 * RIM)))
  assert(gSill.controlledChildren[#WANT] ~= flash.id
     and gSill.controlledChildren[#WANT] ~= plate.id,
    "the top of the sill's stack is not a readout")
  local hpAt, markAt
  for i, id in ipairs(gSill.controlledChildren) do
    if id == hp.id then hpAt = i elseif id == hpMark.id then markAt = i end
  end
  assert(markAt > hpAt,
    "the 30% waterline draws under the health rail, i.e. it is invisible above 30% health")
end

-- The two on-cooldown shots sit together in the row.
placeAfter(gCDs, arcane.id, cdMulti.id)
-- Kill Command is the pack's one reflex prompt, so it gets a fixed home: first in
-- a grow-UP flow means it is anchored at the bottom and never reflows when another
-- alert appears above it.
placeFirst(gAlerts, kc.id)

-- ===== ABSOLUTE POSITION PROOF =====
-- SILL_X / SILL_Y are ABSOLUTE screen offsets, and every region here is nested two groups deep
-- under a top group that carries its own -140. Applying the canon numbers LOCALLY is the exact
-- mistake that put seven packs' clusters at seven different heights, so the build refuses to
-- write a string whose strip does not land where the canon says. It walks each region's parent
-- chain and sums every xOffset/yOffset, which is what WeakAuras does when it anchors a child to
-- its group. The lane offsets are half-pixel values, so the comparison is exact-on-halves
-- rather than integer.
--   SUMMING OFFSETS UP A CHAIN ONLY YIELDS A SCREEN POSITION IF EVERY NODE ON THE CHAIN IS
--   SCREEN-ANCHORED CENTRE-TO-CENTRE AT SCALE 1, and that was previously checked on the six
--   regions in the strip but NOT on the two groups above them. A future version that anchored
--   the Resources group by an edge, or scaled it, would leave every number this build prints —
--   the strip's absolute position and every clearance in the pack — silently wrong while the
--   build still passed. So the walk itself asserts it, on every node it crosses.
local nodes = { [top.id] = top }
for id, t in pairs(byId) do nodes[id] = t end
local function assertAnchor(node)
  assert(node.anchorFrameType == "SCREEN",
    node.id .. " is not screen-anchored, so its offsets are not screen coordinates")
  assert(node.selfPoint == "CENTER" and node.anchorPoint == "CENTER",
    node.id .. " does not anchor centre-to-centre, so summing its offset is not its centre")
  assert(node.scale == nil or node.scale == 1,
    node.id .. " is scaled, so its children's offsets are not in screen pixels")
end
local function absolutePos(a)
  local x, y, node = 0, 0, a
  while node do
    assertAnchor(node)
    x, y = x + (node.xOffset or 0), y + (node.yOffset or 0)
    node = node.parent and nodes[node.parent] or nil
  end
  return x, y
end
local EXPECT = {
  { plate,  SILL_X,             SILL_Y + LANE.plate.y,  PLATE_W, PLATE_H,      "sill plate"  },
  { threat, SILL_X,             SILL_Y + LANE.threat.y, RAIL_LEN, LANE.threat.h, "threat rail" },
  { hp,     SILL_X,             SILL_Y + LANE.health.y, RAIL_LEN, LANE.health.h, "health rail" },
  { mana,   SILL_X,             SILL_Y + LANE.power.y,  RAIL_LEN, LANE.power.h,  "power rail"  },
  { hpMark, SILL_X + railX(30, 100), SILL_Y + LANE.health.y, MARK_W, LANE.health.h, "30% mark" },
  -- Same centre as the plate, RIM px larger on every side: concentric is what makes the
  -- overhang an even WIDTH on all four sides rather than a red edge down one side only. Its
  -- brightness is not even — see the bevel-scaling note on the region itself.
  { flash,  SILL_X,             SILL_Y + LANE.plate.y,  ALARM_W, ALARM_H,      "alarm rim"   },
}
do
  local gx, gy = absolutePos(gSill)
  assert(gx == SILL_X and gy == SILL_Y,
    ("the sill group lands at absolute (%s,%s), the canon says (%s,%s)")
      :format(tostring(gx), tostring(gy), tostring(SILL_X), tostring(SILL_Y)))
end
for _, e in ipairs(EXPECT) do
  local region, wantX, wantY, wantW, wantH, label = e[1], e[2], e[3], e[4], e[5], e[6]
  local gotX, gotY = absolutePos(region)
  assert(gotX == wantX and gotY == wantY,
    ("%s (%s) lands at absolute (%s,%s), canon says (%s,%s)")
      :format(label, region.id, tostring(gotX), tostring(gotY), tostring(wantX), tostring(wantY)))
  assert(region.width == wantW and region.height == wantH,
    ("%s is %sx%s, canon says %sx%s"):format(label, tostring(region.width),
      tostring(region.height), tostring(wantW), tostring(wantH)))
  assert(region.selfPoint == "CENTER" and region.anchorPoint == "CENTER",
    label .. " is not anchored centre-to-centre, so its lane offset does not mean what it says")
  assert(region.parent == gSill.id, label .. " is not in the sill group")
end

-- ===== THE LANE STACK =====
-- "Four stacked rails" is a claim about arithmetic, not about looks: every rail is the same
-- 100px long and shares one centreline, the lanes do not overlap each other, and every scrap of
-- ink is inside the plate. Each of those has a specific failure mode — a rail of a different
-- length silently rescales one pixel per percent into something else; two lanes that overlap
-- put the health number through the power bar; anything outside the plate is the unbacked text
-- on open screen that v14 existed to fix.
-- THE FOOTPRINT SCANNED AGAINST THE REST OF THE PACK IS THE ALARM ENVELOPE, NOT THE PLATE.
-- The widest thing the strip ever draws is the 108x37 alarm rim, and it is drawn whenever
-- threat crosses 80% — i.e. in exactly the fight where the neighbouring rows are busiest. A
-- clearance measured on the 102x31 plate would overstate every gap by RIM px on every side, so
-- the box below is the rim's, and the plate's own box is kept only for the printed area figure.
local PLATE_L, PLATE_R = SILL_X - PLATE_W / 2, SILL_X + PLATE_W / 2
local PLATE_T = SILL_Y + LANE.plate.y + PLATE_H / 2
local PLATE_B = SILL_Y + LANE.plate.y - PLATE_H / 2
local SILL_L, SILL_R = SILL_X - ALARM_W / 2, SILL_X + ALARM_W / 2
local SILL_T = SILL_Y + LANE.plate.y + ALARM_H / 2
local SILL_B = SILL_Y + LANE.plate.y - ALARM_H / 2
local RAILS = { { threat, LANE.threat, "threat rail" },
                { hp,     LANE.health, "health rail" },
                { mana,   LANE.power,  "power rail"  } }
do
  local spans = {}
  for _, r in ipairs(RAILS) do
    local region, lane, label = r[1], r[2], r[3]
    assert(region.width == RAIL_LEN,
      ("%s is %d long; one pixel is one percent only at %d")
        :format(label, region.width, RAIL_LEN))
    assert(region.xOffset == 0,
      label .. " carries an x offset, so the rails do not share a centreline")
    local top_, bottom = lane.y + lane.h / 2, lane.y - lane.h / 2
    local plateTop = LANE.plate.y + PLATE_H / 2
    local plateBottom = LANE.plate.y - PLATE_H / 2
    assert(top_ <= plateTop - 1 and bottom >= plateBottom + 1,
      ("%s spans %s..%s in the sill's own frame, outside the plate's %s..%s (1px margin)")
        :format(label, tostring(bottom), tostring(top_), tostring(plateBottom),
          tostring(plateTop)))
    spans[#spans + 1] = { b = bottom, t = top_, label = label }
  end
  table.sort(spans, function(a, b) return a.t > b.t end)
  for i = 2, #spans do
    assert(spans[i].t < spans[i - 1].b,
      ("%s overlaps %s vertically"):format(spans[i].label, spans[i - 1].label))
    assert(spans[i - 1].b - spans[i].t >= 1,
      ("%s and %s are less than 1px apart, so the lanes read as one bar")
        :format(spans[i - 1].label, spans[i].label))
  end
  -- THE RIM IS CONCENTRIC AND EXACTLY 2*RIM LARGER IN BOTH AXES. Square_White_Border.tga is
  -- filled (98.44% of its pixels are alpha 255; everything 8px in from the edge is alpha 255
  -- with min RGB 167), so an alarm the SAME size as the plate is a full-area wash and an alarm
  -- that is off-centre is a red edge down one side. Concentric + oversized + drawn first is the
  -- only arrangement that reads as a band, and each third of that is asserted somewhere here.
  assert(flash.xOffset == plate.xOffset and flash.yOffset == plate.yOffset,
    "the alarm rim is not concentric with the plate, so its overhang is uneven")
  assert(flash.width == plate.width + 2 * RIM,
    ("the alarm rim is %s wide; a %dpx rim on a %s plate is %s")
      :format(tostring(flash.width), RIM, tostring(plate.width), tostring(plate.width + 2 * RIM)))
  assert(flash.height == plate.height + 2 * RIM,
    ("the alarm rim is %s tall; a %dpx rim on a %s plate is %s")
      :format(tostring(flash.height), RIM, tostring(plate.height),
        tostring(plate.height + 2 * RIM)))
  assert(flash.width > plate.width and flash.height > plate.height,
    "the alarm rim is not larger than the plate, so the plate hides all of it")
  -- A hunter has no discrete class resource, so there is no fourth lane and the plate is 31.
  assert(PLATE_H == 31, "a hunter's strip carries three lanes, so the plate is 31 tall")
end

-- ===== THE RAIL CANON =====
-- Three things have to be true of every rail and not one of them is visible by reading a single
-- line of this file:
--   1. It is a progresstexture on the LINEAR path. A ring and a rail differ by ONE field
--      (orientation), and that field silently changes which of the others are live, so it is
--      asserted on the literal string rather than trusted. HORIZONTAL_INVERSE is "Left to
--      Right"; plain HORIZONTAL on this region type fills RIGHT TO LEFT, which is the exact
--      inverse of the aurabar convention and would silently mirror every reading.
--   2. Its subregion list is exactly what the conditions and the design expect, in order.
--      Condition sub.N refs are positional, so an INSERT ahead of a referenced index retargets
--      it with no error at all — hence a type-by-type check, not just a count.
--   3. Its fill art is the plain white square at the identity crop. A ring texture on a linear
--      path draws an annulus stretched across a bar.
local SUBS = {
  { threat, LANE.threat, { "subtext", "subtexture" }, "threat rail" },
  { hp,     LANE.health, { "subtext", "subtexture", "subtexture", "subtexture" }, "health rail" },
  { mana,   LANE.power,  { "subtext", "subtexture", "subtexture",
                           "subtexture", "subtexture", "subtexture" }, "power rail" },
}
for _, r in ipairs(SUBS) do
  local region, lane, subs, label = r[1], r[2], r[3], r[4]
  assert(region.regionType == "progresstexture", label .. " is not a progresstexture")
  assert(region.orientation == "HORIZONTAL_INVERSE",
    label .. " is not filling left to right (" .. tostring(region.orientation) .. ")")
  assert(region.crop_x == 0.41 and region.crop_y == 0.41,
    label .. " lost the default texcoord scale")
  assert(region.backgroundOffset == 0, label .. " has a fattened track")
  assert(region.foregroundTexture == RAIL_TEX and region.backgroundTexture == RAIL_TEX
     and region.sameTexture, label .. " is not drawn with the canon rail art")
  assert(region.smoothProgress, label .. " lost smoothProgress, so it steps instead of sliding")
  assert(region.width == RAIL_LEN and region.height == lane.h,
    ("%s is %sx%s, canon says %dx%s")
      :format(label, tostring(region.width), tostring(region.height), RAIL_LEN, tostring(lane.h)))
  assert(#region.subRegions == #subs,
    ("%s has %d subregions, expected %d"):format(label, #region.subRegions, #subs))
  for i, want in ipairs(subs) do
    assert(region.subRegions[i].type == want,
      ("%s: sub.%d is a %s, expected %s")
        :format(label, i, tostring(region.subRegions[i].type), want))
  end
  -- The unfilled part of a rail IS its own backgroundColor since v15: there is no second
  -- region behind it any more, which is what freed the old track ring's uid for the 30% mark.
  assert(region.backgroundColor[4] == COL.track[4] and region.backgroundColor[1] == COL.track[1],
    label .. " lost its track colour, so its empty part reads as a hole")
end

-- ===== THE PLATE, THE ALARM RIM AND THE WATERLINE =====
-- The plate is the surface that makes an 11px bar and an 11pt number survive a bright zone, and
-- the alarm rim is the same box grown by RIM on every side, in ADD-blend red, drawn under it.
-- Both are plain textures; the waterline is the third. The alarm's colour is checked component
-- by component because a `color = {}` on this region draws in WeakAuras' default instead of red
-- and looks like nothing is wrong.
local PLATES = {
  { plate,  PLATE_TEX, PLATE_W, PLATE_H,      "BLEND", COL.plate, "sill plate"  },
  { flash,  PLATE_TEX, ALARM_W, ALARM_H,      "ADD",   COL.alarm, "alarm rim"   },
  { hpMark, RAIL_TEX,  MARK_W,  LANE.health.h, "BLEND", COL.hpLow, "30% mark"    },
}
for _, b in ipairs(PLATES) do
  local region, tex, w, h, blend, color, label = b[1], b[2], b[3], b[4], b[5], b[6], b[7]
  assert(region.regionType == "texture", label .. " is not a texture region")
  assert(region.texture == tex, label .. " is not drawn with the canon art")
  assert(region.blendMode == blend,
    ("%s blends %s, expected %s"):format(label, tostring(region.blendMode), blend))
  assert(region.width == w and region.height == h,
    ("%s is %sx%s, canon says %sx%s")
      :format(label, tostring(region.width), tostring(region.height), tostring(w), tostring(h)))
  assert(type(region.color) == "table" and #region.color == 4,
    label .. " ships an empty colour, so it draws in WeakAuras' default")
  for i = 1, 4 do
    assert(region.color[i] == color[i],
      ("%s colour component %d is %s, canon says %s")
        :format(label, i, tostring(region.color[i]), tostring(color[i])))
  end
  assert(region.model_fileId == nil and region.modelIsUnit == nil,
    label .. " still carries model fields, so it was not re-typed cleanly")
end
assert(plate.uid ~= flash.uid, "the plate and the alarm rim collapsed onto one uid")
-- THE ALARM'S RED AND ITS BLEND, PINNED TO LITERALS. The loop above checks the region against
-- COL.alarm, which cannot catch COL.alarm itself being edited; these four numbers and the blend
-- mode are the ones the README quotes, so they are written out here rather than referenced.
do
  local WANT = { 1, 0.1, 0.1, 0.85 }
  for i = 1, 4 do
    assert(flash.color[i] == WANT[i],
      ("the alarm rim's colour component %d is %s, canon says %s — an ADD quad in WeakAuras' "
        .. "default colour is not a red alarm"):format(i, tostring(flash.color[i]),
        tostring(WANT[i])))
  end
  assert(flash.blendMode == "ADD",
    "the alarm rim lost its ADD blend, so it is an opaque red slab and not a glow")
  assert(plate.blendMode == "BLEND",
    "the plate is on ADD, so it lightens the terrain instead of darkening it")
end

-- ===== EVERY BREAKPOINT IS x = v - 50 =====
-- This is the one thing the ring build made hard and the strip makes trivial, so it is the one
-- thing most likely to be typed as a constant and left behind when a lane moves. Each mark is
-- re-derived from its own threshold here; the build refuses to write a string whose 20% mark is
-- anywhere but x = -30.
local MARKS = {
  { mana.subRegions[2], 20, MARK_W,  LANE.power.h,  COL.mpLow,  "Go Viper (20% mana)"      },
  { mana.subRegions[3], 80, MARK_W,  LANE.power.h,  COL.mpHigh, "Back to Hawk (80% mana)"  },
  { threat.subRegions[2], 70, NOTCH_W, LANE.threat.h, COL.notch, "the 70 threat notch"     },
}
for _, m in ipairs(MARKS) do
  local sub, value, w, h, color, label = m[1], m[2], m[3], m[4], m[5], m[6]
  local want = railX(value, 100)
  assert(sub.type == "subtexture", label .. " is not a subtexture")
  assert(sub.xOffset == want,
    ("%s sits at x %s; %d percent of a %dpx rail is x %s")
      :format(label, tostring(sub.xOffset), value, RAIL_LEN, tostring(want)))
  assert(sub.yOffset == 0, label .. " is not centred in its own lane")
  assert(sub.width == w and sub.height == h,
    ("%s is %sx%s, expected %sx%s")
      :format(label, tostring(sub.width), tostring(sub.height), tostring(w), tostring(h)))
  assert(sub.textureTexture == RAIL_TEX, label .. " is not the plain white square")
  for i = 1, 4 do assert(sub.textureColor[i] == color[i], label .. " changed colour") end
  assert(math.abs(sub.xOffset) + sub.width / 2 <= RAIL_LEN / 2,
    label .. " hangs off the end of its own rail")
end
-- The health rail's 30% waterline is the one mark that is a REGION and not a subregion, because
-- it had to absorb a uid. Same formula, checked the same way.
assert(hpMark.xOffset == railX(30, 100),
  ("the 30%% waterline sits at x %s; 30 percent of a %dpx rail is x %s")
    :format(tostring(hpMark.xOffset), RAIL_LEN, tostring(railX(30, 100))))
-- The rulers: three hairlines per rail at the quarters, appended after everything already
-- present so no existing index moved.
for _, r in ipairs({ { hp, LANE.health, 2, "health rail" }, { mana, LANE.power, 4, "power rail" } }) do
  local region, lane, first, label = r[1], r[2], r[3], r[4]
  for i, q in ipairs(RULER) do
    local sub = region.subRegions[first + i - 1]
    assert(sub and sub.type == "subtexture" and sub.xOffset == railX(q, 100)
       and sub.width == RULER_W and sub.height == lane.h,
      ("%s: the %d%% ruler hairline is not a %dx%s subtexture at x %s")
        :format(label, q, RULER_W, tostring(lane.h), tostring(railX(q, 100))))
    for j = 1, 4 do assert(sub.textureColor[j] == COL.ruler[j], label .. " ruler changed colour") end
  end
end

-- ===== THE NUMBERS =====
-- Two are printed inside their own rail at 11pt; the third is switched OFF rather than deleted.
do
  for _, n in ipairs({ { hp, "%percenthealth%%", "health" }, { mana, "%percentpower%%", "power" } }) do
    local region, token, label = n[1], n[2], n[3]
    local st = region.subRegions[1]
    assert(st.type == "subtext", label .. " sub.1 is no longer the readout")
    assert(st.text_text == token,
      ("the %s readout prints %s, expected %s"):format(label, tostring(st.text_text), token))
    assert(st.text_fontSize == NUM_PT and st.text_anchorPoint == "CENTER",
      ("the %s readout is not %dpt / CENTER"):format(label, NUM_PT))
    assert(st.text_anchorXOffset == NUM_X and st.text_anchorYOffset == 0
       and st.anchorXOffset == NUM_X and st.anchorYOffset == 0,
      ("the %s readout is not at the rail's right end (+%d, 0) in BOTH offset pairs")
        :format(label, NUM_X))
    assert(st.text_visible ~= false, "the " .. label .. " readout is switched off")
    assert(st.text_fontType == "OUTLINE" and st.text_shadowColor[4] == 1,
      "a readout lost its outline or its shadow, which is what keeps it legible on the fill")
    -- Three digits at 11pt are about 21px wide, so the block spans NUM_X +/- 11 and has to
    -- stay inside the rail it is printed on.
    assert(NUM_X + 11 <= RAIL_LEN / 2,
      "the readout runs off the right end of its own rail")
  end
  local th = threat.subRegions[1]
  assert(th.type == "subtext" and th.text_text == "%threatpct%%",
    "the threat readout lost its index or its token")
  assert(th.text_visible == false,
    "the threat readout is still printing; v15 switches it off, it does not delete it")
  assert(th.text_fontSize == PCT_THREAT.size,
    "the threat readout changed size while being switched off")
  -- WHERE IT LANDS IF A USER TICKS IT BACK ON, derived here rather than quoted from memory in
  -- the README. A subregion offset is relative to ITS OWN REGION, not to the group: this text
  -- is anchored to the THREAT RAIL, so its absolute y is the RAIL's absolute y (-94.5) plus the
  -- +58 it has carried since v13 = -36.5. Walking it from the SILL GROUP instead gives
  -- -110 + 58 = -52, which is 15.5px too low and is the number a draft of the README printed;
  -- the paragraph that prints it exists only to say where the text appears, so it is asserted.
  local _, railY = absolutePos(threat)
  local thAbsX, thAbsY = SILL_X + th.anchorXOffset, railY + th.anchorYOffset
  assert(th.anchorYOffset == th.text_anchorYOffset and th.anchorXOffset == th.text_anchorXOffset,
    "the threat readout's two offset pairs disagree, so its printed position is undefined")
  assert(thAbsX == 0 and thAbsY == -36.5,
    ("the switched-off threat readout would print at (%g, %g); the README says (0, -36.5)")
      :format(thAbsX, thAbsY))
  -- 10pt is about a 12px line, so re-enabled it spans roughly y -42.5..-30.5: it sits in the
  -- open band ABOVE the buff row and clips the top ~2.5px of the Hunter's Mark icon, which is
  -- why the README says "just above it", not "on top of it".
  local _, markY = absolutePos(mark)
  assert(thAbsY > markY + mark.height / 2,
    "the threat readout's centre is inside the Hunter's Mark icon, not above it")
end

-- ===== EVERY MULTISELECT LOAD GATE IS IN A MODE THAT ACTUALLY TESTS SOMETHING =====
-- The bug this sweep exists for is silent, total and survived ten versions: a multiselect load
-- option has three states and only `false` reads the `.multi` table.
--     nil   -> gate disabled
--     false -> MULTI mode: WeakAuras ORs every key of X.multi
--     true  -> SINGLE mode: it reads X.single and IGNORES X.multi entirely
-- With `use_X = true` and a nil `X.single`, TestForMultiSelect returns the literal string
-- "false" and ConstructFunction ANDs it into the load function, so the aura NEVER LOADS —
-- there is no error, no warning, and the aura simply does not exist in game. v5 wrote that on
-- the threat rail, the alarm, the Feign Death prompt and the Misdirection prompt, and v6..v14
-- copied it forward. The check is cheap and it is on EVERY aura, not on the four that were
-- wrong, because the next one is written by hand the same way.
for id, a in pairs(byId) do
  for _, key in ipairs({ "class", "ingroup", "size", "spec", "talent", "role", "affected" }) do
    local use, cfg = a.load and a.load["use_" .. key], a.load and a.load[key]
    if use == true then
      assert(cfg and cfg.single ~= nil,
        ("%s: load.use_%s is SINGLE mode with no %s.single, which compiles to `false` — "
          .. "the aura would never load. Write use_%s = false for a multi gate.")
          :format(id, key, key, key))
    elseif use == false then
      local any = false
      for _ in pairs((cfg or {}).multi or {}) do any = true; break end
      assert(any,
        ("%s: load.use_%s is MULTI mode with an empty %s.multi, which compiles to `(false)`")
          :format(id, key, key))
    end
  end
end

-- ===== WHICH REGIONS ACTUALLY FADE OUT OF COMBAT =====
-- "The whole strip fades to 50% alpha out of combat" is FOUR of the six members, not six, and
-- the README now says which four. The plate, both tall rails and the 30% waterline carry
-- `inCombat == 0 -> alpha 0.5`; the threat rail and the alarm do NOT and never have. They do
-- not need it: the rail hides itself at zero threat (`threatvalue <= 0 -> alpha 0`, below) and
-- the alarm only exists above 80% threat, so out of combat there is nothing lit to dim. This
-- asserts BOTH directions, because the interesting half is the two that are absent.
do
  local function fades(region)
    for _, c in ipairs(region.conditions or {}) do
      if c.check and c.check.variable == "inCombat" and c.check.op == "=="
         and tonumber(c.check.value) == 0 then
        for _, ch in ipairs(c.changes or {}) do
          if ch.property == "alpha" and ch.value == 0.5 then return true end
        end
      end
    end
    return false
  end
  for _, r in ipairs({ { plate, "the plate" }, { hp, "the health rail" },
                       { mana, "the power rail" }, { hpMark, "the 30% waterline" } }) do
    assert(fades(r[1]), r[2] .. " lost its out-of-combat fade to 50% alpha")
  end
  for _, r in ipairs({ { threat, "the threat rail" }, { flash, "the alarm" } }) do
    assert(not fades(r[1]),
      r[2] .. " grew an out-of-combat fade; the README says it has none, so say so there first")
  end
end

-- The trigger arg IV-45 data must carry. Modernize renames threatUnit -> unit for < 51 data,
-- and it assigns unconditionally, so emitting `unit` here would be overwritten with nil.
for _, t in ipairs({ { threat, "threat rail" }, { flash, "alarm rim" } }) do
  local tr = t[1].triggers[1].trigger
  assert(tr.event == "Threat Situation" and tr.use_threatUnit and tr.threatUnit == "target",
    t[2] .. " lost its Threat Situation trigger on threatUnit")
  assert(tr.unit == nil, t[2] .. " emits the internalVersion-51 `unit` arg on IV-45 data")
  -- THE MODE IS THE GATE. `use_ingroup == false` is MULTI mode, which is the only mode that
  -- reads ingroup.multi; `true` is SINGLE mode and reads ingroup.single, and with a nil single
  -- WeakAuras compiles the literal test `false` into the load function — the aura then never
  -- loads at all. v5..v14 shipped exactly that, so this assert checks `== false` and not merely
  -- "truthy", which is the check that could not have caught it.
  local ld = t[1].load
  assert(ld.use_ingroup == false,
    t[2] .. " is in SINGLE mode on ingroup; with no ingroup.single that compiles to `false`"
      .. " and the aura never loads")
  assert(ld.ingroup and ld.ingroup.multi and ld.ingroup.multi.group and ld.ingroup.multi.raid,
    t[2] .. " lost its party/raid gate")
  assert(ld.ingroup.single == nil,
    t[2] .. " carries an ingroup.single, which is dead data in MULTI mode")
  assert(ld.use_size == false and ld.size.multi.arena == nil,
    t[2] .. " lost its not-arena gate, or put it in SINGLE mode")
end
-- The guard the readout cannot ship without: threattotal is threatvalue*100/threatpct, so it
-- is 0 the instant after a Feign Death, and ProgressTexture draws a FULL bar at total == 0 on
-- the linear path exactly as it drew a full circle on the circular one.
do
  local guarded = false
  for _, c in ipairs(threat.conditions) do
    if c.check.variable == "threatvalue" and c.check.op == "<="
       and tostring(c.check.value) == "0" and c.changes[1].property == "alpha"
       and c.changes[1].value == 0 then guarded = true end
  end
  assert(guarded, "threat rail lost the threatvalue <= 0 -> alpha 0 guard")
end

-- ===== RECTANGLE SCAN: THE ALARM ENVELOPE AGAINST EVERY OTHER REGION IN THE PACK =====
-- v15 moves the readouts from beside the character to UNDER it, into a band this pack has never
-- occupied, so "does it fit" stops being a question about one neighbour and becomes a question
-- about all forty-two other regions. Four of the six top-level groups are DYNAMIC: their
-- footprint is a function of how many elements are live at once, so a clearance measured with
-- one prompt showing proves nothing. Every dynamic child is therefore projected into SIX slots
-- (more simultaneous elements than this pack can raise), and for a centred flow every stack
-- DEPTH is projected too, because a centred row re-centres as it grows.
--   THE BOX IS THE 108x37 ALARM ENVELOPE, NOT THE 102x31 PLATE. The rim is the widest thing the
--   strip ever draws and it lights up in the busiest moment of a pull, so scanning the plate
--   would overstate every clearance in this pack by RIM px on every side.
local PROJECT = 6
local boxes = {}
local scanGroup            -- the top-level group the current box belongs to
local function pushBox(label, l, r, b, t)
  boxes[#boxes + 1] = { label = label, l = l, r = r, b = b, t = t, group = scanGroup }
end
local function collect(node, gx, gy)
  local grow, space = node.grow, node.space or 0
  local kids = {}
  for _, cid in ipairs(node.controlledChildren or {}) do kids[#kids + 1] = nodes[cid] end
  for _, ch in ipairs(kids) do
    if ch.controlledChildren then
      collect(ch, gx + (ch.xOffset or 0), gy + (ch.yOffset or 0))
    else
      local w, h = ch.width or 0, ch.height or 0
      if node.regionType ~= "dynamicgroup" then
        local cx2, cy2 = gx + (ch.xOffset or 0), gy + (ch.yOffset or 0)
        pushBox(ch.id, cx2 - w / 2, cx2 + w / 2, cy2 - h / 2, cy2 + h / 2)
      elseif grow == "UP" then
        for n = 1, PROJECT do
          local bottom = gy + (n - 1) * (h + space)
          pushBox(ch.id, gx - w / 2, gx + w / 2, bottom, bottom + h)
        end
      elseif grow == "DOWN" then
        for n = 1, PROJECT do
          local top_ = gy - (n - 1) * (h + space)
          pushBox(ch.id, gx - w / 2, gx + w / 2, top_ - h, top_)
        end
      elseif grow == "RIGHT" then
        for n = 1, PROJECT do
          local left = gx + (n - 1) * (w + space)
          pushBox(ch.id, left, left + w, gy - h / 2, gy + h / 2)
        end
      elseif grow == "LEFT" then
        for n = 1, PROJECT do
          local right = gx - (n - 1) * (w + space)
          pushBox(ch.id, right - w, right, gy - h / 2, gy + h / 2)
        end
      elseif grow == "HORIZONTAL" then
        for k = 1, PROJECT do            -- k live children re-centre the whole row
          local total = k * w + (k - 1) * space
          for n = 1, k do
            local cx2 = gx - total / 2 + (n - 1) * (w + space) + w / 2
            pushBox(ch.id, cx2 - w / 2, cx2 + w / 2, gy - h / 2, gy + h / 2)
          end
        end
      elseif grow == "VERTICAL" then
        for k = 1, PROJECT do
          local total = k * h + (k - 1) * space
          for n = 1, k do
            local cy2 = gy + total / 2 - (n - 1) * (h + space) - h / 2
            pushBox(ch.id, gx - w / 2, gx + w / 2, cy2 - h / 2, cy2 + h / 2)
          end
        end
      else
        error("unhandled grow mode on " .. tostring(node.id) .. ": " .. tostring(grow))
      end
    end
  end
end
for _, cid in ipairs(top.controlledChildren) do
  local g = nodes[cid]
  if g.id ~= gRes.id then
    scanGroup = g.id
    collect(g, (top.xOffset or 0) + (g.xOffset or 0), (top.yOffset or 0) + (g.yOffset or 0))
  end
end
scanGroup = nil
-- Per-COLUMN clearance, not just the single nearest box. The README quotes a number for every
-- neighbouring group, and a per-group minimum is the only way those numbers can be true: the
-- one global nearest hides, for instance, that the PvP column contains a 120-WIDE aurabar whose
-- half-width reaches back to x +90 and clears the strip by 39px, not by the 99px its +150
-- anchor suggests. Both the axis gap (max, the metric the assert uses) and the true
-- rectangle-to-rectangle euclidean separation are computed, because for a box that is diagonal
-- from the strip they differ and only the euclidean one is a distance.
local overlaps, nearest, nearestId = 0, math.huge, "-"
local perGroup, groupOrder = {}, {}
for _, b in ipairs(boxes) do
  local apart = not (b.r <= SILL_L or b.l >= SILL_R or b.t <= SILL_B or b.b >= SILL_T)
  assert(not apart,
    ("%s (x %s..%s, y %s..%s) overlaps the sill (x %s..%s, y %s..%s)")
      :format(b.label, tostring(b.l), tostring(b.r), tostring(b.b), tostring(b.t),
        tostring(SILL_L), tostring(SILL_R), tostring(SILL_B), tostring(SILL_T)))
  local gapX = math.max(SILL_L - b.r, b.l - SILL_R)
  local gapY = math.max(SILL_B - b.t, b.b - SILL_T)
  local gap = math.max(gapX, gapY)
  local dx, dy = math.max(gapX, 0), math.max(gapY, 0)
  local euclid = math.sqrt(dx * dx + dy * dy)
  if gap < nearest then nearest, nearestId = gap, b.label end
  local G = perGroup[b.group]
  if not G then
    G = { gap = math.huge, euclid = math.huge, who = "-",
          l = math.huge, r = -math.huge, b = math.huge, t = -math.huge }
    perGroup[b.group] = G
    groupOrder[#groupOrder + 1] = b.group
  end
  -- The two minima are tracked SEPARATELY and deliberately: the box with the smallest axis gap
  -- need not be the box that is physically closest, and quoting one box's euclid next to
  -- another box's gap is how a README ends up with a number nothing in the pack measures.
  if gap < G.gap then G.gap = gap end
  if euclid < G.euclid then G.euclid, G.who = euclid, b.label end
  G.l = math.min(G.l, b.l); G.r = math.max(G.r, b.r)
  G.b = math.min(G.b, b.b); G.t = math.max(G.t, b.t)
end
table.sort(groupOrder, function(a, b) return perGroup[a].gap < perGroup[b].gap end)
assert(#boxes > 0, "the rectangle scan found nothing to scan against")
assert(nearest > 0, "the strip touches another element")

-- ===== assemble (v2000 nested), encode, verify, write =====
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

-- ===== THE RIM CANON, RE-MEASURED ON THE DECODED STRING =====
-- Everything above this line inspects the Lua tables this script just built. This block throws
-- them away and reads back the string that will actually ship, because the rim is the one part
-- of the strip whose failure mode is invisible in a diff and total on screen: an alarm the same
-- size as the plate, or an alarm anywhere but first, is a full-area additive red quad over every
-- readout at >= 80% threat, and nothing about the emitted table looks wrong when it happens.
-- The flat `c` list is walked too — F.assemble builds it depth-first over controlledChildren, so
-- the draw order and the wire order can only agree if that walk really is depth-first, and this
-- is where that is proven rather than assumed.
do
  local decoded = W.decode(encoded)
  local byIdD = { [decoded.d.id] = decoded.d }
  for _, a in ipairs(decoded.c) do byIdD[a.id] = a end

  local sill = assert(byIdD[gSill.id], "rim canon: the sill group is not in the shipped string")
  local cc = sill.controlledChildren
  local dAlarm = assert(byIdD[flash.id], "rim canon: the alarm is not in the shipped string")
  local dPlate = assert(byIdD[plate.id], "rim canon: the plate is not in the shipped string")

  assert(cc[1] == flash.id,
    ("rim canon: the sill's first child is %s, not the alarm rim — a filled ADD quad drawn "
      .. "above the plate is a wash over every readout"):format(tostring(cc[1])))
  assert(cc[2] == plate.id,
    ("rim canon: the sill's second child is %s, not the plate — nothing buries the rim's "
      .. "filled interior"):format(tostring(cc[2])))
  assert(cc[#cc] ~= flash.id and cc[#cc] ~= plate.id,
    "rim canon: the top of the sill's stack is not a readout")

  assert(dAlarm.width == dPlate.width + 2 * RIM and dAlarm.height == dPlate.height + 2 * RIM,
    ("rim canon: the shipped alarm is %sx%s, a %dpx rim on a %sx%s plate is %dx%d")
      :format(tostring(dAlarm.width), tostring(dAlarm.height), RIM,
        tostring(dPlate.width), tostring(dPlate.height), ALARM_W, ALARM_H))
  assert(dAlarm.xOffset == dPlate.xOffset and dAlarm.yOffset == dPlate.yOffset,
    "rim canon: the shipped alarm is not concentric with the plate")
  assert(dAlarm.texture == PLATE_TEX and dPlate.texture == PLATE_TEX,
    "rim canon: the plate and the alarm are not both on Square_White_Border")
  assert(dAlarm.blendMode == "ADD" and dPlate.blendMode == "BLEND",
    "rim canon: the plate and the alarm swapped blend modes")
  do
    local WANT = { 1, 0.1, 0.1, 0.85 }
    assert(type(dAlarm.color) == "table" and #dAlarm.color == 4,
      "rim canon: the shipped alarm has no colour, so it draws in WeakAuras' default")
    for i = 1, 4 do
      assert(dAlarm.color[i] == WANT[i],
        ("rim canon: the shipped alarm's colour component %d is %s, canon says %s")
          :format(i, tostring(dAlarm.color[i]), tostring(WANT[i])))
    end
  end

  -- `c` is the wire order and must be the depth-first walk of controlledChildren.
  local order, seen = {}, {}
  local function walk(node)
    for _, cid in ipairs(node.controlledChildren or {}) do
      assert(not seen[cid], "rim canon: " .. cid .. " is listed as a child twice")
      seen[cid] = true
      order[#order + 1] = cid
      walk(assert(byIdD[cid], "rim canon: unresolved child " .. cid))
    end
  end
  walk(decoded.d)
  assert(#order == #decoded.c,
    ("rim canon: the depth-first walk covers %d of %d children"):format(#order, #decoded.c))
  for i, id in ipairs(order) do
    assert(decoded.c[i].id == id,
      ("rim canon: c is not depth-first at index %d: %s, the walk says %s")
        :format(i, tostring(decoded.c[i].id), id))
  end
  local alarmAt, plateAt
  for i, a in ipairs(decoded.c) do
    if a.id == flash.id then alarmAt = i elseif a.id == plate.id then plateAt = i end
  end
  assert(alarmAt and plateAt and plateAt == alarmAt + 1,
    "rim canon: the alarm and the plate are not adjacent in c, so c is not the stack's order")
  print(("rim canon: c[%d]=%s then c[%d]=%s; sill cc[1]=%s cc[2]=%s; alarm %gx%g = plate "
    .. "%gx%g + 2x%d, ADD {%g,%g,%g,%g}; depth-first over %d children")
    :format(alarmAt, flash.id, plateAt, plate.id, cc[1], cc[2],
      dAlarm.width, dAlarm.height, dPlate.width, dPlate.height, RIM,
      dAlarm.color[1], dAlarm.color[2], dAlarm.color[3], dAlarm.color[4], #decoded.c))
end

local txtPath = dir .. "/all-specs.txt"
-- uid continuity vs the PREVIOUS version's string, read before it is overwritten.
-- v13 was the one version of this pack allowed to lose uids. v15 is NOT: it re-types, resizes
-- and re-parents every region in the old cluster and removes none of them, so this runs on the
-- STRICT default — no allowance list at all. changed must be 0, the top-level uid must match,
-- and not one previous uid may disappear. A missing id here would mean a surviving aura
-- silently lost its identity, which is the failure this check has always existed to catch.
local cont = W.uidContinuity(encoded, txtPath)
W.assertUidContinuity(cont, "hunter")
local declared = {}
for _, id in ipairs(REMOVED) do
  declared[id] = true
  assert(not byId[id], "declared WA-REMOVED but still built: " .. id)
end
local droppedThisRun = 0
if cont then
  -- Direction that must ALWAYS hold: nothing may vanish that is not on the list. The other
  -- direction is only true on the run that does the removing — v13 was that run, and every
  -- version since (v15 included) correctly reports nothing missing at all, which is why the
  -- assertUidContinuity call above now runs with no allowance list.
  for _, id in ipairs(cont.missingIds or {}) do
    assert(declared[id], "undeclared uid removal: " .. id)
    droppedThisRun = droppedThisRun + 1
  end
end

local out = io.open(txtPath, "w")
out:write(encoded)
out:close()

print(("OK: %d auras (top + %d children), %d chars -> all-specs.txt")
  :format(#transmit.c + 1, #transmit.c, #encoded))
if cont then
  print(("uid continuity vs previous: stable=%d changed=%d missing=%d parentSame=%s")
    :format(cont.stable, cont.changed, cont.missing, tostring(cont.parentSame)))
  print(("declared removed (%d, %d dropped out against the string on disk): %s")
    :format(#REMOVED, droppedThisRun, table.concat(REMOVED, ", ")))
end
for _, e in ipairs(EXPECT) do
  local x, y = absolutePos(e[1])
  print(("  %-12s %-26s absolute (%+g,%+g)  %gx%g"):format(e[6], e[1].id, x, y,
    e[1].width or 0, e[1].height or 0))
end
print(("  plate box x %g..%g, y %g..%g (%gx%g = %g px2)")
  :format(PLATE_L, PLATE_R, PLATE_B, PLATE_T, PLATE_W, PLATE_H, PLATE_W * PLATE_H))
print(("  ALARM ENVELOPE x %g..%g, y %g..%g (%gx%g, a %dpx rim = %g px2 of red), "
  .. "%d rectangles scanned %d deep, 0 overlaps, nearest neighbour %s at %gpx")
  :format(SILL_L, SILL_R, SILL_B, SILL_T, ALARM_W, ALARM_H, RIM,
    ALARM_W * ALARM_H - PLATE_W * PLATE_H, #boxes, PROJECT, nearestId, nearest))
for _, gid in ipairs(groupOrder) do
  local G = perGroup[gid]
  print(("  %-18s clears by %6.2f px (euclid %6.2f) — nearest %-26s "
    .. "column x %g..%g, y %g..%g")
    :format(gid:gsub("^Hunter %- ", ""), G.gap, G.euclid, G.who, G.l, G.r, G.b, G.t))
end
