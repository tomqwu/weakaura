# Mage — Arcane & Frost HUD (v8)

Programmatically generated WeakAuras pack for TBC Anniversary (WeakAuras internalVersion
45, tocversion 20501). One import covers raid Arcane (40/0/21) and raid Frost (10/0/51):
spec-specific pieces load themselves through Spell Known checks, so the HUD auto-adapts on
respec with zero user action. Since v4 the same import also carries a PvP layer that only
exists inside arenas and battlegrounds — in PvE nothing about the pack changed, and v5 keeps
that promise (the one element it takes away, it takes away *only* inside an arena). v6 adds
and removes nothing anywhere: it changes *when* six cooldown icons draw, so the row shows
what you cannot press instead of everything you own (see below). **v7 gives the middle of
the screen back**: the three stacked Resources bars are gone, and health, mana and threat are
now rings around a live portrait of you and of your target, out at the sides (see below).
**v8 makes the orbs one shared size across every pack in this repo** — pure geometry, not one
trigger, gate or colour moved (see below).
Spell IDs only — aura triggers carry every rank ID as
strings and cooldown triggers carry the numeric rank-1 ID, so the pack is safe on zhCN and
any other localized client. There is no custom code anywhere, so the import dialog shows no
code-review panel. Import `all-specs.txt` (or the fenced block at the bottom of this file)
whole: copy all → `/wa` → Import → paste. Heads-up: the `/wa` editor preview force-shows
every aura at once with placeholder data (load gates ignored, identical fake "55.1"
timers, both specs' icons visible together) — judge the pack in combat, not in the preview.

## v8 — one orb size, shared by all seven packs

v8 is **pure geometry**. It adds and removes no aura, moves no UID, and changes no trigger,
load gate, condition, colour, spell ID or region type — decode v7 and v8 side by side and the
only fields that differ are widths, heights, offsets, two font sizes and one texture path.

The complaint it answers was not about any single number, it was about **disagreement**. v7
shipped a 120 px target cluster next to a 100 px player cluster, and each of the seven class
packs had picked its own ring sizes (96, 84, 88 and 100 px outer rings across the repo). Side
by side that reads as sloppiness. Every pack now emits the same canonical set, declared as
named constants at the top of its build script so nothing can drift apart again:

| | v7 (mage) | v8 (every pack) |
| --- | --- | --- |
| Outer ring, **both** clusters | 100 player / 120 target | **104** |
| Middle ring | 72 | **78** |
| Inner ring (target only) | — | **54** |
| Portrait, both clusters | 40 | **46** |
| Threat halo | 124 | 108 |
| Cluster centres | ±260, −100 | **±260, −60** |

Both clusters therefore present the *same* outer diameter and the *same* portrait; the target
simply nests one more ring inside, because it is the side that carries threat. Player rings
are health 104 / mana 78; target rings are threat 104 / health 78 / mana 54.

The thin ring art is gone too. `Ring_10px`'s stroke is 10/256 of the drawn size — 4.7 px on a
120 px ring — so the threat arc read as a wire rather than a band. Every ring in the pack is
now `Ring_20px`, and the concentric arcs read as one system.

The read-outs collapsed to one set of offsets for both sides: health 14 pt at −60, power 11 pt
at −76, threat 11 pt at +60. They can be shared because every ring in a cluster is concentric
and each percentage is a `CENTER`-anchored subtext, so the offset is measured from the cluster
centre rather than from whichever ring happens to carry the text. v7 needed four different
numbers only because its two clusters had different outer diameters.

One mage-specific trap was handled on the way: the Arcane conserve bead is placed by
trigonometry on the mana ring's circumference, so resizing that ring without re-deriving the
bead would have left a mark floating in empty space. It is computed from the ring size
(`ringPoint`), and moved from `(31.56, −10.26)` to `(34.19, −11.11)` on its own — still on the
stroke centre (radius 35.95), still at 108°, still exactly the 30% mark.

## v7 — unit orbs: the bar stack leaves the middle of the screen

v7 is an in-place update of v6 (same UIDs — the import dialog offers **Update**, not a
duplicate group). It **adds six auras and rebuilds the seven** that made up the Resources
group; every one of the 42 auras v6 shipped is still here, and nothing outside that group was
touched — buffs, alerts, the cooldown row, the procs and the whole PvP layer are byte-for-byte
v6.

The three 172x14 bars stacked under your feet are gone. Unit state now lives **at the unit**:

```
        player orb, x = -260              target orb, x = +260

                                              47%   <- threat %
                                       .-----------------.
    .-----------.                      |  .-----------.  |
    |  .-----.  |                      |  |  .-----.  |  |
    |  |  O  |  |                      |  |  |  O  |  |  |
    |  '-----'  |                      |  |  '-----'  |  |
    '-----------'                      |  '-----------'  |
                                       '-----------------'
         84%
         71%                                  62%
                                              93%

  outer ring   health, green   |   inner ring   mana, blue   |   centre   3D portrait
  target only  the outermost thin ring is threat: green -> orange at 70% -> red on aggro
  numbers      health % 16pt white below the orb, mana % 11pt blue under that,
               threat % 12pt above the target orb
```

- **The player orb** sits left of your character: an outer green health ring, an inner blue
  mana ring, your own portrait in the middle, and the two percentages underneath. Both rings
  fade to 50% alpha out of combat exactly as the bars did.
- **The target orb** sits on the right and is **completely invisible until you have a
  target** — no target, no rings, no portrait, no numbers, and no empty frames left behind.
  It adds two readouts the pack never had: your target's health and (for casters) its mana.
  The portrait is a real 3D model of whatever you are targeting, so it works on NPCs and mobs
  without the pack ever knowing their class.
- **Threat became the outermost ring of the target orb**, which is where it belongs: threat
  is your threat *on that target*, not a property of you. It still runs green, turns **orange
  at 70%** and **red the moment you pull aggro**, and above 80% a fat red halo pulses over
  it. Same party/raid gate, same "never in an arena" gate as v5.
- **The mana conserve breakpoint is still there**, now as an amber bead sitting on the mana
  ring at the 30% mark, with the brighter bead popping in the instant you cross it. Still
  Arcane-only, still combat-only, exactly as v3 left it.

**Every danger signal the bars carried came across.** Health still turns orange below 50% and
red below 30% (where the Ice Block prompt fires); threat still escalates green → orange → red
plus the 80% pulse. Those recolours are a different mechanism on a ring than on a bar, and
getting it wrong would have been invisible: a ring has no `barColor`, and WeakAuras drops a
condition whose property does not exist on the region **without an error and without any sign
in the editor**. The rings use the property that actually exists, and it was verified against
the WeakAuras source before this build.

**Three rings gained a guard the bars never needed.** A bar with a maximum of zero draws
empty; a ring with a maximum of zero draws **full**. That is a real difference at the exact
worst moments — the instant before your first cast lands (threat total is zero), or the first
frames after a target change (max health has not arrived yet). Left alone, the threat ring
would have shown a complete circle, meaning "you are at the pull threshold", while its colour
stayed green. Each ring now hides itself in that state instead. The visible consequence: at
exactly zero threat there is no threat ring at all, where v6 showed an empty bar.

### After updating

**Nothing to delete.** This is a genuine in-place update: the health, mana and threat bars,
the threat flash and the two conserve-line textures were *rebuilt* into the orbs rather than
replaced, so they keep their UIDs and WeakAuras rewrites them where they stand. The old
`Mage - Resources` group is renamed `Mage - Orbs` and gains two sub-groups, `Mage - Player
Orb` and `Mage - Target Orb`. You should see 48 auras afterwards and no leftovers. (If you
ever *do* end up with a stale duplicate group from some earlier hand-edited import,
WeakAuras never deletes auras on import — right-click it in `/wa` and delete it yourself.)

**Uncheck *Arrangement* in the update dialog if you have dragged the pack around**, as
always: it resets positions to the string's defaults, and v7 changes a lot of positions.

Four elements changed region type in place (bar → ring, rectangle → halo). That is a normal
data update for WeakAuras, but it is the most unusual thing this pack has ever asked of the
import dialog: if anything looks structurally wrong afterwards, deleting the `Mage - Orbs`
group and re-importing rebuilds it cleanly.

### Honest limitations

- **The geometry has not been rendered on a 2.5.x client.** Ring stroke weights, the gap
  between the two rings, portrait framing and the placement of the numbers are all computed,
  not measured. Everything is in the `G` table at the top of `generate.lua` — retune and
  re-run rather than dragging pieces in game, or the next update resets them.
- **The conserve mark is a bead on an arc, not a line on a bar.** A position on a circle is
  slightly harder to read precisely than a tick on a straight bar. The rotation-based tick
  WeakAuras offers for rings was deliberately not used: sub-elements cannot carry a load
  gate, so a tick welded to the shared mana ring would have reappeared for Frost and undone
  the v3 audit that removed it. The bead keeps the gate *and* keeps its pop animation.
- **Two 3D model frames are heavier than two textures.** They are small, they only render one
  portrait each, and the target's does not exist without a target, but a live model is not
  free the way a coloured rectangle is.
- **The target ring is mana, not "whatever that unit uses".** A warrior or rogue target shows
  a health ring and no inner ring, rather than a blue ring reporting rage. The rings sit at
  `±260` from centre, clear of the Alerts column at `-150` and the PvP column at `+150`.

## v6 — the cooldown row shows what you CANNOT press

v6 is an in-place update of v5 (same UIDs — the import dialog offers **Update**, not a
duplicate group). It **adds nothing, removes nothing and moves no UID**: six icons in the
cooldown row change how they display, and that is the whole version.

Six of the ten cooldown icons now appear **only while their cooldown is running**, carrying
the swipe and the countdown, and vanish the moment the ability is back: **Presence of Mind,
Ice Block, Evocation, Counterspell, Blink and Invisibility**. The row is a dynamic group, so
the gap closes behind them — **absence is the readout**. An empty stretch of row means
everything there is available; two icons means exactly two things are down, and both are
counting back. Before this, all ten sat on screen permanently and merely dimmed, so the row
was at its busiest exactly when you had the fewest options — and you already know your own
spellbook. What you cannot know at a glance is what is *unavailable*, and for how long.

The desaturation went with them. Under the new rule every visible icon is on cooldown by
definition, so greying the whole row would have told you nothing and only made the icons
harder to tell apart; they now show in full colour with the countdown on top.

**Four icons deliberately stay visible at all times, because their glow is an instruction
and a hidden icon cannot glow:**

| Icon | Why it stays | What the glow means |
|---|---|---|
| Arcane Power | 3 min damage cooldown, pressed as the burn window opens | gold: it is up, and you are in combat |
| Icy Veins | both raid builds press it on cooldown — Frost's rotation is *Icy Veins and Water Elemental when possible, Frostbolt in between* | gold: it is up, and you are in combat |
| Summon Water Elemental | 3 min DPS cooldown, pressed on sight for the same reason | gold: it is up, and you are in combat |
| Cold Snap | its moment is a *sequence*, not availability | blue: Icy Veins **and** Water Elemental are both spent, so the reset is finally worth its 8 minutes |

Presence of Mind is the one judgement call worth spelling out: it is a damage cooldown, but
it is spent *inside* the burn window that Arcane Power's glow already announces, and it
shares Arcane Power's 3 minute cooldown, so a second glow would have been a duplicate cue for
the same moment. It is now a countdown that answers "when is the next window", which is the
question it actually gets asked. Everything else that converted is situational by nature —
an emergency button, a mana cooldown, an interrupt, a blink — and every one of them already
has a prompt in the alert flow that fires at the moment it should be pressed (Ice Block below
30% health, Evocation below 30% mana, Invisibility at 70% threat, Counterspell on an enemy
cast in arenas and battlegrounds). The alert says *press this now*; the row icon only has to
say *when does it come back*.

Nothing else moved: same load gates (including every Spell Known gate, so the row still only
shows spells you have actually taken), same positions, same alerts, same PvP layer.

## v5 — no threat bar in arena, and their mana on screen

v5 is an in-place update of v4 (same UIDs — the import dialog offers **Update**, not a
duplicate group). It **adds one aura and changes the load gate on two**; nothing else in the
pack moved. All three changes come from closing questions v4 had shipped as open.

- **The threat bar and the threat flash no longer load inside an arena.** An arena team has
  no threat table, so both were painting a meaningless number in the one place where you have
  the least attention to spare — and the flash *pulses*, which is worse than useless there.
  The party/raid gate they already had could not express this by itself, because an arena team
  **is** a party. They now also carry an instance-size gate that lists every instance type
  except arena: open world, 5-man dungeon, 10/20/25/40-man raid, and battleground.
  **Nothing changes anywhere else — including the open world.** That was exactly the doubt
  that kept this out of v4: WeakAuras only assigns the instance-size value inside a check for
  "am I in an instance", so it looked as though the value might be nothing at all while you
  are questing and the gate might match nothing and silently unload the bars everywhere
  outdoors. It does not — that check is a guard, and the function's last line returns the
  literal `none` for the not-in-an-instance case, which is one of the types the gate lists.
  Battlegrounds deliberately **keep** both: Alterac Valley has real NPCs with a real threat
  table, and the bar is honest furniture there.
- **Enemy Mana — one bar per opponent, arena only.** A mage does not drain mana, but a mage
  plays the mana clock harder than almost anyone: Counterspell exists to stop a healer
  spending it, Polymorph exists to stop them drinking it back, and "keep applying pressure or
  commit the burst now" is a read on how much the enemy healer has left. The new bar sits at
  the bottom of the PvP column, one row per opponent, with their name on the left and the
  percentage on the right. It turns **amber below 30%** (they are running low — deny the
  drink, keep them casting) and **green below 10%** (they are out; this is the kill window),
  matching the escalation language the health bar already uses.
  Two honest limits. Rows only appear for opponents whose *primary* resource is mana, which
  is what keeps warriors and rogues (who have no mana pool at all on 2.4.3, and would
  therefore show a permanently empty bar that reads as "go") off the list — the cost is that a
  druid in bear or cat form drops off the list until they shift back. And while the WeakAuras
  side of this is proven (the Power trigger accepts `arena`, registers per-opponent events and
  clones one row per opponent on TBC), whether the 2.5.x server pushes *continuous* power
  updates for arena opponents rather than refreshing on opponent changes is a client question
  no addon source can settle. Take it into one skirmish before a kill call depends on the
  exact number; the readout refreshes on opponent-frame updates at minimum.
- **CC ON ME's colour-coding is now confirmed rather than assumed.** No change to the pack —
  it works, and it was worth proving, because the mechanism has a silent failure mode one step
  away. Recolouring a glow from a condition only reaches the screen if the glow was built with
  a custom colour in the first place; without that flag the recolour is stored and quietly
  discarded, and the prompt would have glowed one single colour for every kind of crowd
  control while looking completely correct in the editor. This pack builds that glow with an
  explicit colour, so all nine categories are live.

## v4 — PvP layer

v4 is an in-place update of v3 (same UIDs — the import dialog offers **Update**, not a
duplicate group). It **adds nine auras and changes none of the 31 that were already there**.

**Nothing changes in PvE.** Every one of the nine new elements carries its own Instance Size
Type load gate — arena + battleground for most of them, arena alone for the ones that read
`arena1..arena5` (three as of v6, counting the v5 Enemy Mana row), since those unit ids do
not exist in a battleground. In a raid, a dungeon,
or the open world not one of them loads, and no existing element was touched: the raid HUD
is byte-for-byte the v3 HUD. The gate is per aura, not on the group, which is also what lets
the dynamic groups collapse the gaps.

Walk into an arena or a battleground and a second HUD appears:

**Three new prompts join the Alerts flow** (same language as the rest of the pack: they slide
in from below, glow, and fly away when they resolve).

- **COUNTERSPELL NOW** — appears only when your target is casting **and** Counterspell is
  actually castable **and** the target is hostile. It is the highest-value press a mage owns:
  8 seconds of school lockout on a 24 second cooldown, and a healer locked out of Holy for 8
  seconds is a kill window with no CC spent at all. Because the prompt cannot exist while
  Counterspell is down, it never trains you to ignore it — if it is on screen, press it. The
  icon desaturates while the target is outside the 30 yard range, which is your cue to close
  distance instead. There is deliberately **no spell filter**: TBC has no notion of
  "interruptible" that WeakAuras can read (WeakAuras disables that filter on TBC clients
  outright), so judging fake casts stays a player skill. Loads once Counterspell is trained.
- **CC ON ME** — one prompt for every loss-of-control effect, colour-coded by *category* with
  the remaining time under it, because the decision is never "am I CC'd", it is *which break
  works*: red stun (trinket, nothing else), purple fear (trinket), blue root (**Blink** — Blink
  breaks roots and never breaks stuns, so this colour is the difference between escaping and
  wasting your medallion), green polymorph (ride it out, any damage breaks it), amber
  silence / school lockout (your Frost school is locked, so Ice Block, Frost Nova and Ice
  Barrier are all gone — trinket earlier than you otherwise would). Not combat-gated: the
  opener lands before combat starts. This is also the only way to see a school lockout at
  all, since a lockout is not a debuff and no aura trigger can ever find one.
- **TARGET IMMUNE** — fires when your target gains an effect that makes your whole spellbook
  do nothing: Ice Block, Divine Shield, Cloak of Shadows (90% spell resist), Spell Reflection
  (your next cast comes back at you), Bestial Wrath / The Beast Within (uncontrollable, so
  Polymorph and Nova are wasted as well). Stop casting, re-pool, or swap. Two immunities from
  the generic list are **left out on purpose**: Blessing of Protection is physical-only
  (Frostbolt lands straight through it) and Deterrence is dodge/parry, so neither changes a
  single mage decision, and a prompt that fires when nothing is decidable is noise.

**A new "Mage - PvP" column** of state read-outs appears opposite the Alerts flow (it grows
downward on the right of the character, mirroring the alerts on the left).

- **Trinket DOWN** — visible *only while your medallion is on cooldown*, desaturated with the
  swipe running. Absence means ready, so in the normal case the column is empty and the
  question "do I still have my get-out-of-jail" is answered without reading anything. Tracked
  by exact item id (Medallion of the Alliance/Horde, plus the Mage Insignias) rather than by
  equipment slot, because a slot tracker would report "medallion down" whenever any *other*
  on-use trinket was fired — a false negative that gets you killed in the one decision this
  element exists for.
- **Will of the Forsaken DOWN** — same idea, and it only loads if you actually know the racial.
  On 2.4.3 WotF does **not** share a cooldown with the medallion (that arrived in 3.3), so an
  Undead mage really does carry two charges, and whether the second one is up is what decides
  whether the first gets spent early.
- **Enemy Trinket** — a 2 minute countdown per opponent, started when that opponent's trinket
  cast is seen (one row per arena opponent, arena only). Their trinket being down is what
  makes the next full Polymorph chain uncontested; a one-shot "they trinketed!" flash without
  the countdown would change nothing. **This is an inference, not a read** — no 2.5.x API
  exposes another player's cooldowns, so if an opponent trinkets out of sight nothing starts,
  and the timer assumes the 2 minute honor medallion.
- **CS LOCKOUT** — an 8 second bar that starts when *your* Counterspell lands (your interrupt
  only; a partner's does not light it). That bar is the go: burn Icy Veins, Water Elemental
  and Arcane Power now, and do not spend Polymorph on a healer who cannot cast anyway.
- **Polymorph OUT** — your own sheep on each arena opponent, with the remaining time, one row
  per target. It says two things at once: *do not touch that unit* (any damage breaks it and
  the sheep regenerates roughly 6% health per second, so hitting it hands the healer free
  health) and *this is exactly how long the rest of the team has to work*. It glows in the
  last 3 seconds — re-poly now, or the healer is free. `ownOnly`, so another mage's sheep
  never appears here.

### This is NOT diminishing-returns tracking

The Polymorph row is a plain remaining-duration timer on your own sheep and nothing more. It
does **not** know that Polymorph shares the Incapacitate category with Sap, Gouge, Freezing
Trap, Wyvern Sting and Repentance, it does not know whether the next one lands at 100%, 50%
or 25%, and it does not know about anyone else's CC. Real DR tracking needs a custom trigger
maintaining its own category→timer table (which is what Gladius and Diminish exist for);
WeakAuras ships no DR prototype and no DR library, and this pack contains no custom code at
all. Faking it with an 18 second timer would model the *reset window* rather than the
category state — wrong the moment two spells share a category, and worse than having nothing,
because an incomplete DR tracker gets trusted.

Three more things were considered and deliberately left out for the same reason:

- **Enemy cooldowns** cannot be read on 2.5.x at all. The enemy-trinket countdown above is the
  only honest form: a timer you start because you saw the cast.
- **Enemy spec detection** does not exist on TBC either (enemy *class* is readable, spec is
  not), so nothing here branches on what the other team is playing.
- **The threat bar and threat flash still load in arena** — *fixed in v5*, once the open-world
  behaviour of the instance-size gate was confirmed from the source rather than guessed at.
  See the v5 section above.

**One thing to smoke-test before you rely on it.** The CC ON ME prompt is driven by
WeakAuras' *Crowd Controlled* trigger, which reads the client's loss-of-control API. That
trigger was unavailable on Classic/BCC in WeakAuras 3.5.0–5.1.x and was re-enabled in 5.2.0,
but nothing in the WeakAuras source proves the 2.5.x client actually populates the API. Get
sapped and get kicked in a duel and confirm the prompt fires. If it does not, the failure is
silent and harmless — the prompt simply never appears, nothing else is affected. No aura-based
fallback is shipped alongside it, because two prompts for one event is worse than one that
might be quiet, and an aura-based fallback could never see school lockouts anyway.

Every new game id was verified on wowhead.com/tbc for this build: Counterspell 2139 (8 s
lockout, 24 s cooldown), Will of the Forsaken 7744 (2 min), the "PvP Trinket" cast 42292
(120 s, cast by both medallions), items 37864 / 37865 (Medallion of the Alliance / Horde,
2 min) and 18859 / 18850 (Insignia of the Alliance / Horde, **Mage**, 5 min), Polymorph
118 / 12824 / 12825 / 12826 plus Turtle 28271 and Pig 28272, and the immunity list 45438,
642, 1020, 31224, 23920, 19574, 34471. Aura triggers carry every rank as strings; the
cooldown, Spell Known and Action Usable triggers carry the numeric rank-1 id; item triggers
carry the numeric item id, never a name.

## v3 — per-spec audit: each spec sees only what it presses

v3 is an in-place update of v2 (same UIDs — the import dialog offers **Update**, not a
duplicate group) and adds, removes and moves **nothing**: it only changes which spec loads
what. The test was tightened from "can this spec *cast* it" to "does this spec *press* it as
part of playing well", which is the question the HUD actually answers. Three elements failed
it somewhere:

- **Frost no longer sees the mana conserve breakpoint** (the amber line and its lit crossing
  marker are now gated on Arcane Power, 12042). The line marks where Arcane stops spamming
  Arcane Blast and starts the 3x Arcane Blast / 3x Frostbolt conserve cycle — it is a switch
  between two rotations. Frost has no second rotation to switch into; it is Frostbolt spam all
  the way down, with Ice Lance while moving. Its actual low-mana actions are Evocation and the
  mana gem, and both already have their own prompts carrying their own thresholds, so for
  Frost the line marked a mana level nothing was done about — and the lit marker put motion on
  the HUD for a non-decision.
- **Arcane no longer sees the Ice Lance / SHATTER prompt** (inverse gate: `not_spellknown` =
  Arcane Power 12042, the 31-point Arcane capstone and therefore a true spec discriminator —
  no deep-Frost build can reach it). Ice Lance is *trained* at 66 by every mage, so gating on
  Ice Lance's own id hid the prompt while levelling but not from the wrong spec: 40/0/21
  Arcane loaded a reactive prompt it never acts on. Arcane's rotation is Arcane Blast with
  Frostbolt as the mana filler, and the Arcane guides state outright that the spec uses
  neither Ice Lance nor Frost Nova/shatter combos; it also has neither Frostbite nor the Water
  Elemental, so two of the three ways the freeze window opens do not exist for it. Frost keeps
  the prompt — Ice Lance into a frozen target is its one reactive button outside a raid.
- **The Evocation prompt is Spell Known gated** (12051), like its cooldown icon already was.
  A cooldown trigger on a spell you have not trained reports "ready", so below level 20 the
  prompt fired for a button that does not exist. Neither spec at 70 is affected.

**Requires WeakAuras 5.4.0+ for the inverse gate.** The `not_spellknown` load argument does
not exist before that release; on an older client the unknown field is ignored and the SHATTER
prompt simply loads for everyone, exactly as it did in v2, so the pack degrades gracefully
instead of erroring.

Everything else survived the audit unchanged, and deliberately so:

- **Both specs press Icy Veins and Cold Snap.** The Arcane raid build is 40/0/21 — "Arcane
  IV" — and spends its 21 Frost points precisely on Icy Veins plus Cold Snap, so it can use
  Icy Veins twice per burn. Cold Snap's *glow* is still the Frost sequencing cue (both Icy
  Veins and Summon Water Elemental spent); for Arcane the icon is availability only, since
  the mage never has a Water Elemental to bank. That is a condition, not a gate, so it is
  left for a future version rather than smuggled into a gating pass.
- **Clearcasting stays ungated**: the standard Frost raid build is an Arcane Concentration
  build, exactly like Arcane's, so the free-cast proc is a real decision for both.
- **Ice Block, Counterspell, Blink and Invisibility stay** for whoever has them. They are
  emergency and utility buttons both specs press under pressure, and each is gated on its
  own id, so a build that lacks the talent never sees it — no spec gate needed.
- **The mana gem prompt stays ungated**: both specs gem in their regen phase, and the Item
  Count trigger already hides it from anyone without a gem in their bags.

## v2 — rotation fixes

v2 is an in-place update of v1 (same UIDs, so the import dialog offers **Update**, not a
duplicate group). A rotation review found the pack rendered state faithfully but left
several real decisions unrendered, and let three elements fire when nothing was decidable.
What changed:

- **Mana now shows the burn/conserve breakpoint.** v1's mana bar was a bare percentage with
  no threshold — the single most important Arcane decision ("keep spamming Arcane Blast, or
  drop to the 3x Arcane Blast / 3x Frostbolt conserve cycle?") had no element at all. A thin
  amber line now sits at 30% of max mana with a brighter line that pops in the moment you
  cross it (in combat only — drinking afterwards is not a decision). 30% is a percentage
  proxy for Icy Veins' "1500-3000 mana is usually a good time to start this rotation": raw
  mana moves with gear, the fraction of your pool does not.
- **The burn windows have a clock.** A cooldown trigger reports Arcane Power's and Icy
  Veins' 3-minute recharge, never the 15 s / 20 s window they actually buy you, so v1 could
  not tell you whether you were still inside one. Two new 34x34 buff timers flank the shared
  buff slot: Arcane Power (12042) on the left, Icy Veins (12472) on the right. Arcane Power
  glows in its last 5 seconds — that is the Presence of Mind + Arcane Blast finisher cue.
- **Mana gem prompt.** Mana Emerald (item 22044, ~2400 mana, 2 min) was tracked nowhere. It
  now prompts in the alert flow below 70% mana — low enough that the restore is never
  wasted — and only when a gem is actually in your bags, so a mage who forgot to conjure is
  not nagged about a button they do not have.
- **Ice Lance / Shatter window.** Ice Lance (30455) does triple damage into a frozen target
  and v1 had no frozen-target detection at all, which left deep Frost with no reactive
  decision outside a raid. A new prompt fires when your target is held by Frost Nova (all
  five ranks), Frostbite (12494) or the Water Elemental's Freeze (33395) **and** Ice Lance
  is castable. Deliberately not `ownOnly`: your pet's Freeze and a partner's Nova open the
  same window. Bosses are root-immune, so the prompt stays silent in raid.
- **Cold Snap is a sequencing prompt, not a use-on-cooldown icon.** Cold Snap resets the
  Frost cooldowns, so pressing it while Icy Veins or Water Elemental are still up throws the
  reset away. The icon still shows its own 8-minute cooldown, but it only glows once both
  Icy Veins **and** Summon Water Elemental are on cooldown and Cold Snap itself is up.
- **Three cooldowns glow when they are up, in combat.** Arcane Power, Icy Veins and Summon
  Water Elemental are press-on-cooldown, so they now glow gold the moment they come back —
  gated to combat so the row is still while you are riding to the next pull. The reactive
  cooldowns (Ice Block, Counterspell, Invisibility, Evocation, Presence of Mind) do not
  glow; their prompts live in the alert flow instead.
- **Threat bar is party/raid only.** v1 gated the flash overlay and the Invisibility prompt
  on `ingroup` but not the bar itself, so solo — where you are always the aggro target — it
  sat pinned red for every quest mob and trained you to ignore it.
- **Clearcasting is combat-gated**, like the four other alerts. An Arcane Concentration proc
  from a pre-pull cast is not a decision.
- **Ice Barrier warns before it drops.** The timer glows in its last 5 seconds. The MISSING
  alert can only fire once the shield is already gone, which conceded an unshielded gap on
  every fight; a 60 s shield on a 30 s recast should be refreshed pre-emptively.
- **Health bar has colour tiers** (orange under 50%, red under 30%), completing the danger
  pattern whose action half — the Ice Block prompt at 30% — was already there.
- **Every cooldown icon is now Spell Known gated.** v1 left Evocation, Counterspell and
  Blink permanently lit for mages below level 20/24/32.

## Layout

**Orbs** (v7 — two clusters flanking the character, replacing the v6 bar stack; resized to the
repo-wide canonical geometry in v8, so both clusters and all seven class packs share one set
of diameters: outer ring 104, middle 78, inner 54, portrait 46, centres at `±260, -60`). The
**player orb** is a 104px green health ring around a 78px blue mana ring around your live 46px
portrait, with the floored health percentage (14pt white) and mana percentage
(11pt blue) below it; each number is coloured like its own ring, so neither needs a label.
Health runs green, turns orange below 50% and red below 30%, where the Ice Block prompt
fires. Mana is the mage's real clock — Arcane plans its mana to hit zero as the boss dies —
and carries the conserve breakpoint bead at the 30% mark described above, dim by default with
a brighter bead popping in the moment you cross it. Health, mana, the portrait and the
conserve bead fade to 50% alpha out of combat so the HUD breathes with the fight, and the lit
bead is combat-only. Since v3 the conserve bead and its lit marker load for Arcane only: they
mark a rotation switch that Frost does not have.
The **target orb** mirrors it on the right — same outer diameter, same 46px portrait, its own
percentages at the same offsets — and vanishes entirely when you have no target, because the
Health and Power triggers produce no state for a unit that does not exist. It nests one ring
more than the player side, so its health ring is the 78px band and its mana ring the 54px one.
The outermost band there is the **threat
ring** (104px since v8, on the same `Ring_20px` art as every other ring), drawn on the target
because threat is your threat on
*that* target: party/raid only, never in an arena (v5), green until 70%, orange from there,
red the moment you pull aggro, with a pulsing red halo above 80% — mage burst has no passive
threat dump, so this ring is the warning system. Every ring hides itself rather than showing
a misleading full circle when its maximum is zero (no threat table yet, health not streamed
in, a target with no mana pool).

**Buffs** (static timer row under the bars). Arcane and Frost are mutually exclusive at 70,
so both 40x40 centre icons share the one slot. Arcane Blast stacks (self-aura 36032, 8 s
window) shows the stack count large in the center and the remaining window at the bottom, and
glows purple at 3 stacks — the cap is the decision point: keep spamming Arcane Blast only
while Arcane Power / Presence of Mind / Icy Veins are burning, otherwise fall back to filler
until the stack aura drops and rebuild. Ice Barrier (all six ranks) shows its remaining uptime
for Frost and glows in its last 5 seconds so the reshield lands before the shield lapses;
pushback protection is completed Frostbolt casts, so the timer is a rotation element, not
decoration. The two 34x34 burn-window timers flank that slot: Arcane Power left, Icy Veins
right, each appearing only while the buff is actually running.

**Alerts** (glowing 40x40 prompts in an upward flow left of the character). Each slides in
from below and flies away upward when it resolves, and the stack collapses gaps
automatically. Clearcasting (12536) fires on the Arcane Concentration proc in combat — the
next spell is free, weave it immediately. The Evocation prompt fires when mana drops below
30% **and** Evocation is off cooldown, once you have trained it. Barrier MISSING fires when Ice Barrier is absent
**and** its 30 s recast is ready, so it stays quiet during the cooldown instead of nagging.
The Ice Block prompt fires below 30% health **and** only when Ice Block is ready. The
Invisibility prompt fires at 70%+ threat **and** only when Invisibility is ready, in a party
or raid. The mana gem prompt fires below 70% mana **and** only with a Mana Emerald off
cooldown in your bags. The SHATTER prompt fires when your target is frozen **and** Ice Lance
is castable, with the freeze window running as the icon's swipe and bottom timer — for every
build except deep Arcane, which does not use Ice Lance. Every
prompt requires all of its conditions at once (`disjunctive = "all"`), so an alert appearing
always means the button is pressable right now, and all six of these are combat-gated. Three
more prompts share the flow in arenas and battlegrounds only — COUNTERSPELL NOW, CC ON ME and
TARGET IMMUNE (v4) — and none of them ever loads in PvE.

**Cooldowns** (auto-collapsing horizontal row of 32x32 icons below the character). Cooldown
text on, mouseover tooltips on. Every icon is Spell Known gated so only spells you have taken
(and trained) take a slot and the row stays tight: Arcane Power (12042) and Presence of Mind
(12043) for Arcane; Icy Veins (12472), which both the 40/0/21 Arcane build and Frost talent
into; Summon Water Elemental (31687), Cold Snap (11958) and Ice Block (45438) for Frost;
Evocation (12051), Counterspell (2139), Blink (1953) and Invisibility (66) once trained.
Since v6 the row is split by how the ability is used. Four icons are always on screen because
their glow is the instruction: Arcane Power, Icy Veins and Water Elemental glow gold the
moment they are up in combat (all three are pressed on cooldown), and Cold Snap glows blue
only when both of the cooldowns it resets have been spent, which is the one moment the reset
is worth spending. The other six — Presence of Mind, Ice Block, Evocation, Counterspell,
Blink and Invisibility — are situational, so they appear **only while their cooldown is
running**, in full colour with the countdown, and disappear when the ability is back. The
group collapses the gap, so absence means available: an empty row is everything up.

**PvP column** (v4, arena and battleground only — invisible everywhere else). A dynamic group
at +150, mirroring the Alerts column on the other side of the character and growing downward:
Trinket DOWN and Will of the Forsaken DOWN (32x32, desaturated, present only while the charge
is spent), the Enemy Trinket countdowns (32x32, one clone per opponent, arena only), the
140x12 CS LOCKOUT bar, the Polymorph OUT rows (36x36, one clone per opponent, arena only), and
since v5 the 140x12 Enemy Mana bars (one row per mana-using opponent, arena only, name on the
left and percentage on the right, amber below 30% and green below 10%).
It is a dynamic group because three of its children are clone sources; clones inside a static
group would stack on one spot. In the quiet case — trinket up, nobody sheeped, nothing
interrupted — the column holds only the opponents' mana.

## Spec gating summary

| Element | Gate |
|---|---|
| Arcane Blast Stacks icon, Arcane Power CD, Arcane Power window | Spell Known 12042 (Arcane Power) |
| Mana conserve bead + lit crossing bead | Spell Known 12042 — **Arcane only** (v3) |
| Presence of Mind CD | Spell Known 12043 |
| Icy Veins CD + Icy Veins window | Spell Known 12472 (loads for deep Arcane *and* Frost) |
| Summon Water Elemental CD | Spell Known 31687 |
| Cold Snap CD | Spell Known 11958 (both raid builds take it) |
| Ice Block CD + Ice Block prompt | Spell Known 45438 |
| Ice Barrier timer + Barrier MISSING alert | Spell Known 11426 (rank 1) |
| Ice Lance SHATTER prompt | Spell Known 30455 (learned at 66) **and NOT** 12042 — hidden from Arcane (v3) |
| Evocation CD **and Evocation prompt** (v3), Counterspell CD, Blink CD, Invisibility CD | Spell Known 12051 / 2139 / 1953 / 66 |
| Invisibility prompt | Spell Known 66 **and** party/raid only (`ingroup`) |
| Target threat ring, Threat Flash halo | party/raid (`ingroup`) **and** every instance type **except arena** (`size`, v5) |
| All six PvE alert prompts | in combat only |
| CC ON ME, TARGET IMMUNE, Trinket DOWN, CS LOCKOUT (v4) | arena **or** battleground (`size`) |
| COUNTERSPELL NOW, CS LOCKOUT (v4) | arena/battleground **and** Spell Known 2139 |
| Will of the Forsaken DOWN (v4) | arena/battleground **and** Spell Known 7744 (Undead) |
| Enemy Trinket, Polymorph OUT (v4), Enemy Mana (v5) | **arena only** — they read `arena1..arena5` |
| Everything | class MAGE |

Ten elements carry no *spec* gate after v7 — the player and target health and mana rings, the
two portraits, the target threat ring and its flash halo, Clearcasting and the mana gem prompt
— and every one of them is a decision both Arcane and Frost make (the threat ring and its halo
do carry a group gate, and since v5 an instance-size gate as well; neither is a spec gate).
`tools/spec-preview.lua` models Spell Known gates only, so from v4 it lists the
PvP elements under "ungated" or under their spell gate; read that list together with the
table above, because every one of them also carries the instance-size gate and none of them
loads in PvE. The inverse gate (`use_not_spellknown` / `not_spellknown`, WA 5.4.0+) is used
once, on the SHATTER prompt; `use_exact_not_spellknown` is deliberately left unset so the
rank-1 id resolves through the spell name to whatever rank the player has. Audit any future
change with `lua5.1 tools/spec-preview.lua mage`, which decodes the shipped string and prints
each spec's loaded set.

Two IDs are worth calling out because TBC reshuffled them relative to the classic era:
**Cold Snap = 11958** (8 min CD) and **Ice Block = 45438** (5 min CD, Frost talent). Every
spell ID in the pack — the twenty-six of the PvE layer (17 distinct spells: Ice Barrier
contributes six ranks and Frost Nova five) and the seventeen added by the v4 PvP layer — plus
all five item IDs (**Mana Emerald 22044**, medallions **37864**/**37865**, mage insignias
**18859**/**18850**) were verified on wowhead.com/tbc before this build. **Neither v5 nor v6
adds a single new game ID** — v5's one new element reads a resource rather than a spell, and
v6 adds no element at all, only changing when six existing icons draw. The item triggers
(item cooldown + item count) and the PvP layer's Cast, Action Usable, Crowd Controlled, Spell
Cast Succeeded and Unit Characteristics triggers are the only ones in the pack not built by
the shared factory; their field names come straight from the matching WeakAuras prototypes,
and the item ones take the numeric item ID, never a name.

## Regenerate

`lua5.1 tbc/mage/generate.lua` from the repository root (run
`tools/tbc-weakaura-creator/scripts/setup.sh` once beforehand to fetch LibDeflate and
LibSerialize). The script is fully deterministic — fixed UID seed 20260816, no time or
environment inputs — so rebuilding produces a byte-identical `all-specs.txt`
(sha256 `a7df8c3e2feb351ece78e06b5ff9498706d4a729d67dd76f755bdf204ada7961`, 10354 chars,
48 auras). It round-trip verifies the encoded string and checks UID continuity against the
committed `all-specs.txt` **before** overwriting it; `changed` must stay 0 so in-game
re-imports offer *Update* instead of duplicating the group. v2 added six auras and changed
none of the 25 v1 UIDs (`stable=25 changed=0`); v3 added none and changed none of the 31
(`stable=31 changed=0 parentSame=true`) — it edits load conditions only; v4 added nine and
changed none of the 31 (`stable=31 changed=0 parentSame=true`); v5 added one and changed none
of the 40 (`stable=40 changed=0 parentSame=true`) — its other two edits are load gates, which
move no UID; v6 added none and changed none of the 41 (`stable=41 changed=0
parentSame=true`) — it edits `genericShowOn` and one condition on six cooldown icons, and
every other aura decodes byte-identical to v5; v7 added six and changed none of the 42
(`stable=37 changed=0 parentSame=true`, and all 41 previous child UIDs retained). `stable`
reads 37 rather than 41 because four of the rebuilt auras were also **renamed** — the
continuity check counts an aura as *stable* only when its id is unchanged, and counts a
`missing` UID as a hard failure, which is the number that matters: it is 0. The four renames
are `Mage - Resources` → `Mage - Orbs`, `Mage - Health` → `Mage - Player Health`,
`Mage - Mana` → `Mage - Player Mana` and `Mage - Threat` → `Mage - Target Threat`; each keeps
its own UID, so each updates in place rather than arriving as a new aura. v8 added none,
removed none and renamed none — `stable=47 changed=0 parentSame=true` with `missing=0` and
the same 47 child UIDs on both sides, which is the strictest result this check can report.
That constraint is also *why* v7 is a rebuild rather than a delete-and-recreate:
`W.assertUidContinuity` fails on any UID that disappears, so the bars could not simply be
dropped and replaced with new orb auras — and the in-place transform is the better outcome
anyway, since it leaves nothing orphaned in the player's collection. Future versions must keep
the seed, never reorder existing `W.uid()` calls, and append new auras at the end of the
creation order. One import-time note for users: the Update dialog's *Arrangement* category
is checked by default and will reset any positions dragged in game back to the string's
defaults — uncheck it, or report the coordinates so they can be baked into the script.

## Import string (v8)

```
!WA:2!L33d0TXXz(5HWkwgs2MIws2sNDmSILQKJTm(db)JoRlgaeGesGaqlajLyKnXcGfyxrGDxT7csc6M4eg7CQ3vFPLxV0EPjPo8ADBVKR9cFoPUxYLlH1V027CAhZ2Z3M71E)r3DTUVxU8UQ23523L(NVzMDX)iaeffzoAF690YDNDMz3z((9977B(MzhGMSVCVYtDThz9S85MnVMIAiLskANZHdhjD4(0(v7lNISHMsPsc5djkvkVMG8JREGX5lk46jDLSeFvbnxj0YwlP08AffmijD9SkA5f0cAvVQ9gSK0IlYRL3vAfLsgsQAlKOqbDbduwvEOAnupcToshmeupb0YXll46eUIOPOBKLvxIAvzf5lTIMqrjf50vvf4kQPurDfwosjTOWEwvsUGIwzEdihoxLDdwZcHqowNVIHOIwcvYT1DMfAGfKk6uJphnHb40n41mCMTGKSKUOZGWFmCUKHMuXIcA6XpHM1PF2GgKNoFfnEVRroQRkuQKuE9J2N7GvGcLvL29Sen9O51DED9kzfMdAPPQuOG0cRotOaPsptQ0b4sx7wj1eGBXLkz4yXUrfDHWlaVxPy1qgoz(Yc6oxjVqwOginETXchlzKjITCfzRxlNRMxs)kvKHwZCcE5lvs9a80ZtZU)4k5f(k3Hv3v48ffupqQRwbeaUIuPujxtjkziSg7US(67EzEzjwN5a4dgznbEDHugGaROH4DHpsqzfzH1ZdTFsoMH0NOPlaDQ51xIKvYBj2DWY8sYrWpfuaSBShSxSp4VhQ1uwwxOuHKksYgzdfoE6WChtk)QwilasPFd4ocAY8LMeEiWJ7JUAbnOlbED4n4DCdE5CGKncjjYJnBQqCHdhFfdLCZXY)EtEiVvGQ8Kf9F1fnUOA6GdZPNJVKGJvabahftPBdzIkdTEhRqAksmSsWsk85DUk7XqFnXdCThbJQPUG7zA1d2SYXyc8Lmev7R5uhNxM3cV)K0lCfcEacAZj4kMKSG6d2HBzOE4MROKkaEKxYaVh8haFxX6fVx8GyNI49HW7hFp47Dp47ZjUxkWhFaN4(CIVFqk6eFiN4d7e)aXpb(b)SGe4O4Fca2IFi8dJ)GoXpc2f(rXhd)HYGFmN4JJpb(VMt8jXNc)4FL7a)HXpb(jVB8PjGHwfO9FZfXy)4baPk2bEOpkEyh4ZG)jXpnixWND18UD3FO5KJm9ItI)ioWpJtCah4GoXHCIhb6OptwqFqBMQi2FxaHVl0Q85VsfDdH8JZVqp1VqsUhspauk1dMxqN3GapfiureYc58IRQtWicla3qitJ5jIcWSWYdNEjEzd0scY5dixSKWlEy4v(6QAkf1e01tPurlNWJ)q3rpKwe0T7G05EaNlPPyqvfqC8Luf5HwW5obxorHCZgb)G7zP541K4Zwsyjj5qkLZYBWnhFPkcOJPOESZEwTCI8Yff0p6jWttrulbppqJYOkEYtGNcQbh4lUoKqoGRqKcTWtFm)UHs33tJ)OKIDokuCaYbpoWx(gfQ1IOCG1Qf8ZcL0xtLKuMHtENqb9YocLh)C1kXYL5xW(z2hPGh7PplRKiiFtIFMJETdR2Nb0RoJUiFEL5VOfb)Y00ihu794n9YF8JR2BdfOol91zPAthemWePtOE)0eb(BfcFuUPKYBigmaC5nO3aiofYtt8tUoth9sSxG30XA0mqqhsfQIhyfQqIcacgpr8W4JOb6)K8ScnJ5Snc6G9QxamcQ2BenPfDDHk85jSnUsNw1DT21mmdoZ0uJBM8c5aMZsZOQbNq4Fqn19y92HwNM28aPZuA8QlnL1jRx7rtz6tmr6yrJh2Q)Qjoi1tDtErOIFk3mxHskkASUJ5G3jajMP(dIy(8HT67SfEQh)Mu5SeZgVs5ScAzffKkkA8wBz(HS5aa)mvj4V(90izLAVGAFalnCQcVO6bYwtL2szwDWOetef4ZjC5a5ZNqw)YtjWpBaI95lpUqEj(lBLt9lZjjxCgVUvx40gf5PKqRqT9t12r4qtUm8eNjxjED9mznaReYghMRCfW3fNC0uprwDjsEdoEGrdJ)Ppm(NjtqWAFUdJ)PDguh6ljNGFGNZIK9HieRCuZ8zzMfSiCxI8CiUmKHs7wJZTXYHFz1dobKfxHe5j(QiOjbG5C62C2FMwkRnFD2YsAAkAIT29jjlI3)nSzZmy9jlPagkbdl6oxgagY5jolWfmw44Jq9WHZMA766LvumetAv6mRqPkJiPPBiUQvDKRKKQiHE)gwvobttQq1dgkwGXtMorWybcD(aJms00rNeW11LLwiVBupLAedeCHF)lLtPSk5jlsmLeg)CNJYx5NCCik3L3HCawx4MNWg8wQhOojOL0h)PadocfxiBSedeiM(4AsYeFeeexM2uiVNzJgpv0rcVQIMeiXOn8LdflrOZpv0uHzW0fSGP3NtnAXeYlETZGppchJyCcpEp442gIWjeXjZGVGiMdHtrTLGtVrZh4jq4jbBgpoJ1Dpap9La(vM1bgzlZtJl3GbHLaIzvL5f0aEzpTNxgNbH5VHn5lnZh)44CmhdYJfWfWfXIFsS0BEN4RaVqZIlbiVYy5ZX6Xjhh0VdhyfSkwdPEYorkqR6giCWvX6ydCf8C45H6DXmQpw3lkln8hh)8pa(Vos9P6EU3ifl(f(cBDNt(eBK3b)jfXlbWfQtkViHwa)szWFAQQ91ob(Vb(NHP5J)zPj93SUo)3TUUlxsQ4HOR(zYSm9vN05GiAUm1w1dsib0eUAfjnbAUjS(zwNKAT8NPTed4)w3msa8FBr8YG(o(Nh)3Xj(xa)zX)Dr4)EzW)II4phvhf)3h)5XFbe(l(oLX)dOkvrSuQ86NI3iNoSFIof(v(c4Vev9jAWPDFQtn8GNBWC4Fjr8)q8)i8RI)hJ)NutPa)pv8AUOyBs1t7t(6n8A)pN(A)RIA(nF1TCJ8(aAzMHBgAL8I7LbFjAwqFW(U4E8450E8G3VMfPerRJ0Fe8OBcfUTmUs9aWGYYPjyasyBo0MWyFn1NEZB3kKKwUscZKIYb7TMXllhQT8VEu8DLCp(6)0Egg4twPUdUIegMZU6uUlmwYZ7F4bgFcQ8NWq9chilZVirCO5aq(1jyp6OxNvwzEzBq)p7gG(Rupt79PSvbELd0OSNmqJ)l2st1d1KomXbxEdfnG2ATgVb4DQnkHA9Qjn)mDg40aGa)AnbgCSbCa(RrraEbZqKHAqeWfWhjlX4IGb2NgziSjQyqKNFNS6IGzIzxYEWUbjAhurCBGaqTG)o0tjfnyb(8c43WlucAw(6Ti(X)lAJiCSgfH4x3sYn34Xh)IJuj2iZfQUK7i4FnqO9PjmtFdBMiQ0AfQlm0bAKPz6QVzdIQJCnFRwgm5vkQ(eu3qGrt6LxvsKyfJz)sJEFYOU6T(WDBASKpxlkS)CDsH9wvXEnvRb5oTIs5mqF0AS3LcsLeIMh)WRWUuLhCO6HzTJz0bBgvrqpwdxdV7WykFHNDZrHxFu9lPdSYcY5eC0GDAym2F4GXvKfW7NJ(iW37Jw)zvr)ca6R(1AlI04Zph4znOCTLTobqJapGLGyre(j3hf0qGkrTsTAdTxTf(J7f)kplfKC2vdo8OgHNuvBoJce8LAV08nIKojkvrLlOis97yZqd2qx6In(8QI6yWqSclyArqHYq9(TtLEPRiGV0ITM1wIBIvQ04MC4MtR5qGmY7DcbYDUXqGKJl8Ox5sUtMCWbBBiq2A(wENn7B5zQpIEdMajNbE6JniDi9)uws73jytJ9NJVi4)mEAhnIiENrBkpRYQnA8m6CecOEIU2XR9KR5gQ6tSbx9QLP25NxJETw12Pv1hTlvsnxlT8SfqPdAzEW2X2gDwTnJ8TED1KhUuxvbFBXVWBTZ67jHHFvcLomUtsyVZqh6izOMIm(mnRBaNFc89KjiOyKptNi5MJtfgUB1mEvNdQjOjAuTmVCgVgcYzwXyEWuB1csZjad(LEEgS7mm9LAEXTcRdHy0agHmrDeuxO(nu)gzS42Fi87cdITxlL(usgvOwrPQz32UR(73K7Qdro4J5T6Bz5TAOYbNA4lmYIjIgP7ERENTXJf49F96Tkq(Nb)NdnhGA4)vg8FYXgYn0gv7Ro6OMlnG6eTDJ)F3U2PLdkKq1Xoqg)AnNvr1Cpb)TTDozJiRMD0yfAqhtwPKo4UrFEOzBJqTn4(XNQnUF8hqOzAWXd(Zxiz4iktvyQY1D847x3XJFqg8FQfke)d)ZqJ0wu3Fg6C4x57VnrKD06bZCMBcHdoBBhSRJMhS77KGsdCvulmb4faLCq9(5FyIE(hdyq2vmiZ4TXJR3DBECG)H4N7DKBAyFZwk6OlM14sxC(WDwrABxa)lFtITb(lVzIMX78jS55)kBiWe4Ff7GoG)NHWVq5Djc4VBlJy(Djs3F1gICa(RMPnJ95wxsFDqs)fPs6YwsAvVjYXPLACzXZ1zjTp8VjD8c4FRggTa(n784eU1rTFpIt)4)DqU(3d)htCRh)wBrN5XR7ObCgXlE8)bOB6)i4(o(3M40o(Tr4FNBxN0XMn5E(Fe(7JW)Un6o(ebYfozLPhEXtkrH()NyUF7e)FgH)9A1p6ZPEulxETMw8GGhZGjud(CZQxZf5O5GBWRPjjO1A(PXtY1usY5vMx9bQL)QUMuqsw36gm)NrqVZDtDFE)7Y9FEnR2rWkfkOVrxP9hRS)ZjfkYS(5ANR0FOvKYPiZMfVh6oinmgYD9CkkLGEd5uZlPkKzn7ljtvUyNB5C(gWTpVBQw)qF0BmRGGAaYmfyWr8bsKcba7SpZ5E71lwsz(iASrCwL5sdB6Pi3ynWjKrlznrzzwIKeDnqKuAbHsRqUmgDI5p0QKZTNGPLlAxeQpsd4N5EKdAMSNNNGKlePznfDkXPVjPfLYnRSGUUd6DitoT(bOpOGSLKX1UFk97XoUE74FrTemzYuQ1gpTXp)JYCGUwTPULRT1IgpEyUzcMiD6eJxZZCWlPLH(q2m7Vo7pZOWA5wl3bRz9Jo7JwPypdzwRiGzeaqa(jSVI42Td8lCbw0YibEPtbiRXGTS)GeGhEVMiQ22zxnwYKxvmN)KJ5xH4ni8VGlQOuMkJwYg(LXMlXe1J6bTtLesqyi8K5tg8YhiqELlyIowgIo6VKnfgrP5imVdT0VAjLdTHuiArny7nRoLObma7RXr)LbFzYQM40Eonboqijg2X1(qMO92O6Kj6UZyIC2znNRW5Xt)EhGZJp3(8qp6LE0hN3b94RFoF(63T)nPELjA)1vLoZBBIUhB9ht09AIUp4nPxt0bmr9Dit09JmrhKogW(zUD7WHj6qqIhw0e9aW5pi8)Jaz(OIBdOst0pb(5psnSOj6Hmrpm8W(G06Ze9iW7Ml8tyIE0nnI6jwXgrbY8gWtXJMQ4fhP8yxOOOfEYe9yu0Kj64nGJGKpXohO56clOkXItAAPYK4b4VrV3aWJj6KBvqZr5841D)E35GfoQHlg2)Ugyr4BrIM6WI97GmBNlkCQ5NsoV(W(6kU4oRHlcVdGlmrU3(Xc9p4TlwGjFVplzCdabhmAblScr4376zRyyOiNGnp37UrdUF9nIg4bWq1iJnC1W9Fkz5X7kyyp7aGbNwIA3blQPm)XMijUNF5AXeoujbEWPvDdj5I1Cvn8Ck5OujUsQPuwT(QGZYFxxJhnvQOXhTbFBjojRKBw7cy7qCuzQnDPssgvBTYOl2UrfkBN(d2qLfJe6ExPglq60H5UH97AixjI7A8W1ESHsmbzvlsx9MUINyQ6b1oa3OHt7k64Jpr8WuhTja8VdDOsmxR50v5ZjCp3U(wVk4etLYYPivgDj25plZtio(ssfLXdObgZjRdu6WNc14iJ0yRZtHm0ra8rCSeiCSQh6WKEc8(xlFvz(Ys5OHyegzqqDfndS7LlQjXw4v7BjYPexspg3iCLKklzSpsikJrot86GJpWJx2icFodfTSCbgj6ePYQXNxQI(lUFymbldYEMhSV4HTbHRBpwMscAg6RuOsPsSzanJTh)WWbbF7VRs3gdPaW1mC5zx17PUWjdDLRmNNjo5wJnYVVb2jTmrDwHnDMwwMYSlWHLc1hf()2mDEG420qCmFvICQIr7FsHlnm3CDLgAWo6RID4pxJg(Zv1ljLxiRcWpxMoDR(SNF2wPMUwVltx5VeS666KjqQOObDGp4JKnxfDOcYsZqvQRaKNa76fyxtcU6Ki6keJMCM(QM)U7Bb0Y0aWsQ1LSRvYZED4Cz9sKfDiCl1dyFV02jdVySimBNqgADtRTmnZB(yaOeDZWKpxtHV(xVVNg)TAy(0X)gz66cV4AhGdErYnBqYITu9aK3KIcYcAs5sjQmFc5mR30LRQt)dNaF(QKQFz6ccioFzH9(u3p(iC0lTwfBhjK1GxCzV8XCDs6cC)uQ9rNzJIYkAcKfrgWKiKzDnb(sPSRULRzjy9Alobs605yG82ZAllB1tMB2mQ3p5CbYYOVXS3z1WhFtpUbFSjqQJAHBg1M2mL9Bq)5Bs6eBr9HSk)PZClqPQES6RDeY16xM2FntCYs(qyMKv0GrTsv3UWLkkDYexsyYKcBuDtSU62qBs1nt0u43WeDXoRKzIUKjAAshb0lF5AQsMONTr1it0ZzR)yIMXeLHutMiEtuwOUmr5GET8BvTGx1AGMMOtzIECt0h2eb9)pPj60RdM7YjkOZaXRZaXJlPtwvNDJbNQGyIemrfmrfHhl42OePaMORqgwg0ANLH2nrLmrLHCiVAdHNZeP2cG1eDvitABp4Ywhp7oiWCdJbLZePR6Q94rOhyMyG2NSbdngi(yNFkVlgXJ)iDfno87NqJ1dN)ZY4JzltgaBzfq)ptggFBtlY6mQhU5fDT9emc86Bcm5x9J3wm5Y1CtENerYw(vSHs)Jbij0wBdK8rBpKK(1LXoYWKdfSkxKztoBKkd3vm5zE)jM8VO551EqY8AJ)rKzXU5zWUBOTxQTyT1ACKx7GWnQ)X97N95VC7G2Ev2Ky3MjwIHc)b2arac(nFP2H5ovRyUaSw)mKb0mtJ9hmS34HgurHFyFfQ2D(WFY3VG9KBJpQdUP9r9RJpsqjdHYKctaHGVLpyB8TmkKLtX4xTGPqDTg1tt4ouVbxY(S9o5dvV(FBs)YNI9nGOur2iddsVcPcDfIKczTUqVvJR3dMxSmhoR9eGhohnNqhk84nrVe0D8PR)4U9Py9zrXYwVZ3wi)B1HYrW6hVvSE04tod4kvUzgvO8mPmuKfMXThgo390lOlo0KJS40(6ko)PF)ehRv8bw0RhVE9o0a(doGhY8D42Rp3CEh09qdrcJ5WK57W3W(TNr8wC(uBSaCJhzIy3mZ9Z9UD2CpnqwBj(3ZSPXI(P0Vd7y3u8jE1oYKFDzfJzAAfSZuHBo5gz7jDWTrh4e3uFmOZBptjyKPLv41g9Ks(hPRr(4SVhqjyZhLStqwbGH0uMpp5RA2AJfGAbyBjUySVamp(3XbEp8Me4Djl20AlmUoWMEc8)9mCKDbb(mTgISPd5BYYvUcF5XD3v2YFQAaLlTRdO85QVgHT2pjOBlathmv6jI34Ck3IyeF5BuFgMB(Zx2e9fXtVoP8ZmE4qJfiE0qDTImrVsZLnyKWb4AQi0W5yT0iAtbwNuG2)WUjLuluI4rMiv4nugRzyKg(92(oYLir6nuk74o1UNuQOXchpu4n2vyhY421Wsgiu0ixARuu1EtfASejIntuY8EWnrY03KIFR6EyeIZFe(Hxoyic3jXWi16hv1BwMLnTmudAV86bO7HhUMGUIialHV2lvlZ4hIgXqrGfM6YDMLRDQg7mbYJI95O8UV)mm9xYAm0aBuJJH(B06yOFTxQgPKj6ZNPzRCpw3SYbEyKsuj3SmQRfD7(cZn90QxnCXUAJ7JSlM6Q(heZASnYfzoYo0qlFBmzWxg)63swdB0NqU(93VVH8oq)Edcoe6MZh4Jy)CE9nmCUNH9pi4vy)9pONo4vO94vOGCt0xgEyFft0VY2oA(90gxBghZGNfJ7zOHNQQ4OLpFxHNpZUy4zT5s3enWkJLGl60jINoqmYmQZMw7qJ0YYa1AQWPPNK8zosMyBLcUgxsoV1SWtVxTLhQQR6jMQs5Yab7u8afGRWLeibZLVuJfdSsN3vkzE1MRlR4m2yI1MkNgFtPJRwqJQQDJ6jhSKK8SnMVMIEI98P)e3zdtOUjkWDF7oB6MOGSjrNOftvLdVX5n3efXEkZnrJwFYYnrJHV39yIIIbHZ52Nj68hJBetum4SXHrRf3eLWeLKoT3MOluF(Uv71E1eyfmdDtuQwNRB02YuDp(qxDK5N0qvvLJAsEZrB1YapxHmVjbknpFvD7bG(uoBFmaBeh21XGEl)TFV1JvylgPfVLJysGT2YY6niFAUwBfAzSw5Edw6sXMtZVHV57kH0VgqirxV4VsGTTfLZJxZXUvuKTrET89(rTYb5Ba8d(e3b(IEdeFKS0D2i9hFalFc)nbdJdu77h1rBwGxp2MEWITGZUoB(5Q9UzJ12xBXAQ92k52TBqNVvwIyMO(3UXp7Rv8Jj6FJfUrPymvHrMl0qdUyxXnFJDaCJZBjX6Z1U4w9DTfLUF9of3kltr)vmoJnS49AqMlV4KdL(uLh(ct7VRY8V5okxbvHVBCeMOFlt0BUTtp0DC0Z)VU9uchU9UV8xXqvqVthrvEIfUKVQHNCI0E6kQ6x)9LOk5UIQo9xV9St1849MHJ2qv)9UjeFMi8wVo7GsGjA9BIHqV8YvVDxaknf()DkGmiq6iq2yi)xuBU0Ytmq8UcK)w7gaYNzJa5GeNDGYcxDxK787Sn7mvdaLoS4qmrFS3B7X0gwiinapc7RYi51f9vA4qDfE8B8x6Em1Dzhz1v2wzNY7X929(7SSlPKrU45MQIpbTUk7(27ULDVwhwNmngbK3tleFTxQZYWl65Cfp3uEcx1O7J097S7wgEWfBRmKJgUQ3tl8GwwhfEPVyGt5xBwVPDFQUk8wB3TW7L6a15N490cUUO0L174cXhCOuYPJ2v52)QDq5gjo1bhjXuXX9CL67dyKTvpbdxK0TI28t6AkPsLiHUXquWvefnD(zfKz5W(JQkSSq5Q2fU2VabHs5ISjTMyI013k2vkvTSIMQOlsQhOPIt(OVA7hKLjkW9STf)yVPtK8hFrqEf729CjBtOJZV98zsDbVELMWZ8dgA2j3Kt51hNTO9mrFQ6lzpt0l2WAZ7714IJ7N)DAAT(TPl2)TTuXI(L3AfBLAICt0V9gigY8JlIHT2eH9FLrmSWqxmvHl2FQy6J2vIH)GDqIHp02G3WFWNP9X95GTJl5wNL)hBcZn1K0tATDtOgyyVYtvmSs5yE7Qq9pCxHqDoOoEznRFQuokx)E9oSx8NHTx3zLAg8B41Jx3KncD6soWvi6MGtLC5ei7O5K5((Z)x6gO3u6HhUDYRSrN(sdoGUyKlKVRYRRVtADEfDvETzPFkVhIj7QTLoTo9w12c4vpqtxt2W0XGw5XeRzNCz22oBjLIMOFWrd61JVHXpYk1xPq43OVHWV8kSFfmCftPiJx9hATVdt3zEO7FGRu)CWKBDjmDh8PHFRgSMP2LYYB9Z9ttFmuaiyn6RmB)U5sGz4ZCy8rwLSX2dLyg4)BdlGHvz7(mCrhDS01wyoZrbo276mSFEf8cpVUaLoYwBP6CDAlmO9E3p(Bt23XiymMGnu9(kqNKS)GPz18byuJ9oxeTmTZvxkVahRXSL9zObD9vPpIXO)erCw8xJJ8X(ldyz2J2(NWHtwFfgfITraeKx7Yte9jRF1tMIc(OfRH1a5FeOYGOBHzVXET2OTU68qdXD8rNlhz3QZ6fqkFEbzU4HNmmh(vnr)lT0a(I0FHbilUUBbMR3Mo)3HkPilONX6tn0RhpK1Z9qE7NE0p94aCWHb9qp6DvvbncGMiLwIVqbHCgc51uMxoHCPQzOCzxNO)ijlKKLZmTXztt0VW2Yc2EiRLG4UMT6KO3omPLUQI(KJeUIrKUB57pU266j6o2gDIVoUrNaU0FJw5ynr)pGEK)NnsK2Y2)hXg3xDtS3NBI(lAKt0e9JA3U5)Rdc6)par45omrG8)1skZDCYVZyBzb9kmkWyHJamGhYAF9QBBsJDRwBABA0e9)R2(04ry7tJmQvZEUdZEqDNoDZJNm7PN6eNM94OjctZEi7DGM9ShKzpFaZEURTfErZE2lqhA2ZDdOrZEGl3Nzp7VbET)KnYRjQFXCNV)Xuh8sXauRzp3Rzp3Nfxw95Fa)TS)nEQggCJRj3FuZz3tZzVnFBr0c1mFzFL7lFF5V2hS5T)B8GMOpaDzJ(geLtR9xqYEl4BU3D57n339g3qbxO0qxrw)8LLg8CTzdfSpDoFN2)PD33C35h7))
```
