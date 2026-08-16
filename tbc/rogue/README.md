# Rogue — All Specs HUD (v53)

Import `all-specs.txt` whole. Layout groups (drag each in /wa): Buffs, Alerts, Resources
(combo pips + the ring cluster), Procs, Cooldowns, PvP. The cluster is its own sub-group —
`Rogue - Player Cluster` — so it can be dragged, or disabled, on its own.

**v53 puts your health percentage in the middle of the cluster, over your own face.** It used
to sit 54px *below* the rings at 13pt, on open screen, where a bright floor or a fire washed it
out — the exact complaint this version answers. It is now **dead centre at 16pt**, and the raw
energy number takes the slot it vacated. Making that readable took a second change that is not
obvious from the outside: **your portrait is now the first child of the cluster**, so the rings
— and therefore their text — draw *over* it instead of under it. No aura is added or removed,
every UID is stable, and there is nothing to delete after updating.

## v53 — the health number moves into the middle, and your face moves behind the rings

v52 left the biggest empty space in the HUD — the inside of a 100px ring cluster — holding
nothing but a portrait, while all three percentages floated *outside* the arcs on whatever the
world happened to be rendering. Small, detached, unreadable against a bright background. v53
puts the number that matters most where your eye already is.

| Label | v52 | v53 | Token |
|---|---|---|---|
| **health** | 13pt, `y = -54` | **16pt, `y = 0`** — dead centre, over the portrait | `%percenthealth%%`, unchanged |
| **energy** | 10pt, `y = -70` | **12pt, `y = -54`** — the slot health just vacated | `%p`, unchanged |
| **threat** | 10pt, `y = +58` | unchanged | `%threatpct%%`, unchanged |

```
                47%     <- threat %, 10pt, +58 (unchanged)
        .-----------------.
       /   .-----------.   \
      |   /   .-----.   \   |
      |  |   |       |   |  |     100px  threat ring    (party/raid only, unchanged)
      |  |   |  84%  |   |  |      84px  your health    — 16pt, dead centre, over your face
      |   \   '-----'   /   |      62px  your energy    (35/40 marks intact)
       \   '-----------'   /       44px  live portrait  — now the FIRST child, drawn behind
        '-----------------'
                71      <- energy, raw, 12pt, -54 (health's old slot)
```

**The energy number stays raw.** It is `%p`, not a percentage, and it has to be: 35 and 40 are
*absolute* thresholds (Eviscerate, Sinister Strike) and the ring's own breakpoint pips mark
those absolute values on the circumference. "62%" next to two marks that mean 35 and 40 would be
unactionable. Only its position and size changed.

**The non-obvious half: draw order.** Moving the offset alone would have looked like nothing
happened. WeakAuras' `FixGroupChildrenOrder` gives each child **+4 frame levels** in
`controlledChildren` order, so **later = drawn on top**, and v52's cluster ended with the
portrait:

```
v52:  { Threat Ring, Health Ring, Energy Ring, Threat Flash, Player Portrait }
v53:  { Player Portrait, Threat Ring, Health Ring, Energy Ring, Threat Flash }
```

The face was on top of everything, so any text a ring put in the middle went *under* it. The
portrait is now first — furthest back — and the rings, with their subtexts, draw over it.

**That does not bury your face, because a ring is an annulus.** `Ring_20px`'s stroke is 20/256
of the drawn size, so each ring's art occupies only its own band and its middle is empty pixels.
Measured out of the shipped string:

| Region | Band it actually paints |
|---|---|
| threat, 100px | `r 42.19 .. 50.00` |
| health, 84px | `r 35.44 .. 42.00` |
| energy, 62px | `r 26.16 .. 31.00` |
| **portrait, 44px** | `r 0.00 .. 22.00` |

Nothing reaches `r ≤ 22`, so promoting three rings above the model hides no part of it. The only
thing that lands on the face is the FontString — which is the entire point. The 16pt number is
at most 38.4 × 16px, so it also clears the innermost hole (`r = 26.16`) rather than being cut by
the energy stroke.

**Reordering is not free bookkeeping.** The import envelope's flat child list must stay
depth-first in each parent's `controlledChildren` order, so the child list was reordered *with*
the group. v52 left those two disagreeing inside the cluster; v53 makes the whole transmit
depth-first consistent, and the build now asserts it for **every** group in the pack rather than
just this one.

**Nothing else changed.** 58 auras in, 58 out — `stable=57 changed=0 retained=57 missing=0
parentSame=true` against v52, with exactly **three** objects differing in the decoded string:
`Rogue - Health Ring` (one subtext offset + font size), `Rogue - Energy Ring` (the same two
fields; its four 35/40 pip subregions and the `sub.4`/`sub.5` conditions that drive them are
byte-identical) and `Rogue - Player Cluster` (child order). Text tokens, colours, `OUTLINE`,
shadows, every trigger, load gate, condition, size and position are untouched, and the cluster
still lands on `(-270, 40)` with all five regions concentric.

### After updating

**Nothing to delete.** No aura is added, removed or retyped, so all 58 UIDs carry straight
across and the re-import is a clean **Update**. Because the change includes a re-ordering, leave
the update dialog's *Arrangement* category at its default rather than unchecking it — that is
the category the new draw order travels in, and without it the portrait stays on top and the
health number stays invisible.

**Coming from v51 or earlier?** The v52 note below still applies: you have a leftover
`Rogue - Target Cluster` group to delete by hand, once.

### Honest limitations

- **The 3D portrait is the one thing source cannot settle.** Frame levels are what put the
  rings above the model, and a `model` region renders a real 3D scene rather than a texture, so
  this is the bullet to check first on a live 2.5.x client: the number should sit crisply on
  your face. If a client draws the model over everything regardless of level, the fix is not a
  bigger font — it is moving the number back out, and that is a version, not a setting.
- **The two outer arcs are flush, not spaced.** In the decoded string the threat band occupies
  radius 42.19–50 and the health band 35.44–42: they touch, with 0.19px between them. That is
  meant to read as one double band around the portrait.
- **The threat ring does not dim out of combat.** Health, energy and the portrait each carry a
  second Unit Characteristics trigger that fades them to 50% alpha out of combat; threat has
  only its Threat Situation trigger. In practice it is invisible out of combat anyway — the
  `threatvalue <= 0` guard takes it to alpha 0 — so the fade would have nothing to fade.
- **`threatpct` is scaled so 100 = pulling aggro**, not "100% of the tank's threat". The 70%
  orange is therefore an early warning, not a near-miss.

**v52 — the target cluster is deleted, and threat becomes your own outer ring.**

v52 is the first version of this pack that **removes** auras: 62 → **58**. Four go, one moves
out to a bigger radius, and nothing else changes — `stable=57 changed=0 retained=57 missing=4
parentSame=true` against v51, where `stable` equals the entire new child count (every surviving
aura kept both its name and its UID) and the four missing UIDs are exactly the four deletions
below. Every other aura — the buffs row, the alert flow, the combo pips, the cooldown row, the
procs, the whole PvP layer — decodes byte-identical to v51.

**What went, and why.**

| Removed | Why |
| --- | --- |
| `Rogue - Target Cluster` | the group that held the other three |
| `Rogue - Target Health Ring` | your target's health is already on the target frame **and** the nameplate — this was a third copy of it, all game |
| `Rogue - Target Portrait` | a live 3D model of the thing whose portrait is already in the target frame you clicked to select it |
| `Rogue - Target Ring Track` | an empty black hoop that v51 invented to keep a spare UID alive and to make the two clusters look symmetrical |

A HUD element earns its place by changing the next button press. A target health percentage
270px to the right of your character never did, and once it goes, the face and the symmetry
hoop have nothing left to be symmetrical *with*. The ring track is the clearest case: v51's own
notes say outright that it exists because a dropped UID would be orphaned — that is a
bookkeeping reason, not a reason a rogue needs it mid-fight.

**What moved instead of dying: threat.** It is the one thing the target cluster carried that
nothing in the game shows on its own, and a dps who pulls aggro dies, so deleting it would have
been a regression rather than a simplification. It is now the **outermost ring of your own
cluster**, which is also the more honest place for it: it is *your* threat. The trigger still
reads the target — threat is a relationship, and the unit names the table it is measured
against — but the arc is drawn on you, because the number is about you.

```
                47%     <- threat %, 10pt, +58 (above the new outer ring)
        .-----------------.
       /   .-----------.   \
      |   /   .-----.   \   |
      |  |   |  ( )  |   |  |     100px  YOUR THREAT      (green / 70% orange / aggro red)
      |  |   |   o   |   |  |      84px  your health      (unchanged)
      |   \   '-----'   /   |      62px  your energy      (unchanged, 35/40 marks intact)
       \   '-----------'   /       44px  live portrait    (unchanged)
        '-----------------'
                84%     <- health %, 13pt, -54
                71%     <- energy %, 10pt, -70
```

Health, energy and the portrait do not move by one pixel, and neither do the 35/40 energy pips
on the inner stroke. Only the threat percentage moves, from `+54` to `+58`, so it clears the new
outer radius of 50. The 80% flare resizes 84 → **100** with the ring, so it pulses *on* the
threat arc instead of orbiting a radius nothing occupies any more.

**Threat kept everything.** The Threat Situation trigger, both escalations on `foregroundColor`
(`barColor` is aurabar-only and `color` is texture-only; Conditions.lua drops an unknown
property *silently* — no error, no editor warning), the party/raid gate, the never-in-arena
gate, and the mandatory `threatvalue <= 0 → alpha 0` guard without which a ProgressTexture with
a zero total draws **full** and reports a complete circle of aggro at the exact moment you have
none. One trigger field is deliberately *not* modernised: the prototype's unit argument is
`threatUnit` on internalVersion 45 data and was renamed to `unit` at 51, and WeakAuras' Modernize
pass migrates anything below 51 forward — so this string emits the old name and lets the client
rename it.

Because those load gates travel with it, **the common case is still two arcs and a face**: solo
and in arenas the threat ring does not load at all, and nothing is drawn in its place. That was
the excuse for the target ring track in v51, and it is why the track is gone rather than reused.

**Positions are absolute, and the surviving cluster did not move.** Nothing anchors to the
screen directly — every ring hangs two groups deep under a top group carrying its own `y =
-140`, and the offsets add down the chain:

```
top (0, -140) + Resources (0, 56) + cluster (-270, 124) + ring (0, 0) = (-270, 40)
```

That chain was walked in the **decoded shipped string** for all five surviving cluster regions —
threat 100, health 84, energy 62, portrait 44 and the flare 100 — and every one lands on
`(-270, 40)` with a `(0, 0)` offset inside the group, i.e. they are genuinely concentric. The
Alerts column is the one neighbour on that side: it sits at `x = -150` with 40px icons, so it
spans `-170..-130` **at any stack depth**, while the 100px threat ring spans `-320..-220`.
Projected six prompts deep the stack climbs to `y = 226` and its lower rows do share the
cluster's rows — and it still clears the ring by **50px horizontally**, which is the margin that
matters for a column that only ever grows upward. The PvP column is at `+200`, on the other side
of the character entirely.

**After updating to v52 there is one group to delete by hand: `Rogue - Target Cluster`.**

WeakAuras never deletes an aura that an import does not mention — an import can only add and
update — so the four removed auras stay in your collection after the update, sitting in that
group. Delete it and its children (`Rogue - Target Health Ring`, `Rogue - Target Portrait`,
`Rogue - Target Ring Track`) once, and the pack is exactly what this README describes:
right-click `Rogue - Target Cluster` in `/wa` → Delete, and accept deleting the children with it.

**Check the group holds nothing you want to keep before you delete it.** The import moves the
threat ring and its flare into `Rogue - Player Cluster`, so in the normal case the leftover group
holds only the three dead regions — but re-parenting is part of the update dialog's *Arrangement*
category, so for this one update leave the dialog's categories at their defaults rather than
unchecking Arrangement. If you have dragged the pack around, expect to re-drag it afterwards;
that is the cost of a version that changes one region's size, parent and offset at once.

Nothing was invented to absorb the four freed UID slots, and that is the deliberate part: a HUD
that may never delete a region can only grow, and v51's target ring track is what "keep the slot
alive" looks like after a few versions. This step calls no `uid()` at all — it only removes and
re-homes — so the pack seed and the UID call order are untouched and no surviving aura's UID
shifted by one call.

You should see **58 auras** afterwards (plus whatever is left of the old target group until you
delete it). `Rogue - Threat Ring` and `Rogue - Threat Flash` keep both their names and their
UIDs, so they update in place rather than arriving as new auras.

**v51 — the globes go back to being rings, and your face is back in the middle.** Held up
against the older ring-and-portrait build, the rings won: two concentric arcs around a live
3D portrait read as *a unit* — you, and your target — where two filled discs read as two
gauges bolted to the screen. So both units are drawn as rings again, at the geometry every
pack in this repo now shares.

| | player cluster, `(-270, 40)` | target cluster, `(+270, 110)` |
|---|---|---|
| **outer ring, 84px** | your health, green → red under 30% | **threat**, green → orange at 70% → red on aggro |
| **inner ring, 62px** | your energy, yellow, with the 35/40 marks | the target's health, green → red under 20% |
| **portrait, 44px** | you | your target — a live 3D model, so it renders mobs and NPCs too |

**Two rings and a face, not three.** v48's target cluster nested threat *plus* health *plus*
power, and that third arc is what made the two sides look busy and uneven. The target power
ring is not rebuilt; its UID had somewhere better to go (below).

**The percentages moved back outside the rings.** That is the direct price of a face in the
middle, and it is worth naming: a `model` region cannot carry text at all — WeakAuras' SubText
`supports()` gate lists texture / progresstexture / icon / aurabar / empty, and `model` is not
on it. So each number rides its own ring and sits just outside the cluster: health 54px below
at 13pt, energy 70px below at 10pt, threat 54px above at 10pt. The same three slots on both
sides, so the two clusters line up rather than each finding its own spot.

**The 35/40 energy marks went back onto the circumference.** On a vessel a threshold was a
horizontal waterline; on a ring it is a point on the arc, so they are re-derived from the
inner ring's radius — `r = 62/2 × 0.94`, `x = r·sin(2πf)`, `y = r·cos(2πf)` — which puts the
35 mark at `(23.6, -17.1)` and the 40 mark at `(17.1, -23.6)`, both on the stroke, 11.5px
apart along the arc. Same dim + lit pair, same colours (red = Eviscerate at 35, purple =
Sinister Strike at 40), same conditions, same `sub.4` / `sub.5` indexes. They are square pips
again rather than lines, because a chord width on a ring would reach straight across the
middle and through the portrait.

**Threat kept everything it gained as a rim, on the property that exists.** It is a
progresstexture again, so its escalations move back from `color` to `foregroundColor` —
`color` belongs to `texture` regions and Conditions.lua skips unknown properties *without a
warning*, so getting this backwards is a silent no-op, not an error. The
`threatvalue <= 0 → alpha 0` guard is still there (without it the ring reads as full aggro at
zero threat), the party/raid gate is unchanged, and the 80% pulsing halo now pulses on the
84px ring.

**The specular highlight is gone.** It was a curved-glass effect for a filled vessel; on a
20px stroke it is a white blob in the middle of a hole.

**One region changed job, and it is where the spare UID went.** This is the only pack of the
seven that ever built a target power ring, so after the rebuild it had one UID more than a
two-rings-and-a-face cluster needs — and a dropped UID is not free: WeakAuras never removes an
aura an import does not mention, so it would sit orphaned on your screen forever. It became
`Rogue - Target Ring Track`: the outer ring's unfilled track, drawn unconditionally under the
threat ring. It earns the space, because the threat ring only loads in a party or raid, and
without it the target cluster solo would be one lonely inner ring next to your two.

**Nothing to delete after updating.** All ten UIDs in the two clusters — the two group UIDs
and the eight regions — carry straight across, so the re-import is a clean **Update** with no
leftovers and no new auras. Six of them move to a region with a different job:

| v50 | v51 |
|---|---|
| `Rogue - Life Globe` | `Rogue - Health Ring` |
| `Rogue - Life Globe Rim` | `Rogue - Player Portrait` (it *was* the portrait before v49) |
| `Rogue - Energy Globe` | `Rogue - Energy Ring` |
| `Rogue - Energy Globe Rim` | `Rogue - Target Ring Track` (it was the target power ring before v49) |
| `Rogue - Target Life Globe` | `Rogue - Target Health Ring` |
| `Rogue - Target Globe Rim` | `Rogue - Target Portrait` (it *was* the portrait before v49) |
| `Rogue - Threat Rim` | `Rogue - Threat Ring` |
| `Rogue - Threat Flash` | unchanged, re-arted and resized onto the 84px ring |

so a hand edit to one of those is what gets replaced. Every trigger, load gate, condition,
colour and spell id outside the two clusters is byte-identical to v50, and the player cluster
still fades to 50% out of combat, portrait included.

**v50 — the globes flank your character, and the glass catches light.** Two changes, both
shared verbatim by every class pack in this repo.

**They moved off the band.** v49 parked all three globes in a row at `y = -262`, and a
horizontal strip of widgets under the HUD reads as *another action bar* — your eye files it
with the screen furniture and stops going there. Diablo's globes were never a strip: they
**flank the character**, and that is what makes them feel like part of you rather than part
of the interface. So life and energy move up and out to either side of you, and your target's
globe moves onto the centreline above you.

| | Where it sits now | Size |
|---|---|---|
| **Life** | `x = -270`, `y = 40` — left of your character | 72px (rim 76) |
| **Energy** | `x = +270`, `y = 40` — right of your character | 72px (rim 76) |
| **Target** | `x = 0`, `y = 110` — above your character | 44px (rim 48) |

Those exact numbers are the tightest arrangement that collides with nothing else in the HUD.
`x = ±170` runs a 76px rim through the Alerts column at `x = -150` and the PvP column at
`x = +150`; `x = ±210` pushes the right-hand globe into the PvP layer at `(200, -44)`, whose
kick-lockout bar is 140 wide and so reaches `x = 270`. `190` is the band left in between.
Nothing else moved and nothing resized: same 72px vessels, same 44px target, same rims.

**The fill stopped being flat.** Each globe now carries a **specular highlight** — one soft
white ellipse, 46% × 34% of the globe, offset up and to the left by 17%/21% — which is what
the eye reads as *a curved glass surface catching the light*. Before it, the fill was a single
flat colour and the globe read as a sticker: a coloured disc printed on the screen rather than
liquid sitting in a vessel. The highlight is scaled from each globe's own width, so the 44px
target globe gets the same shine, not a shrunken copy of someone else's.

The highlight blends with **ADD**, and that is load-bearing rather than a taste call. Your
percentage sits *inside* the glass, and overlays draw over it: a 28% white sheet on the normal
blend mode would wash the number toward grey and cost exactly the readability that putting it
inside the vessel bought. ADD only ever brightens, so the text stays white and crisp. It is
also why this is a highlight and not the more obvious dark vignette around the rim — a
vignette has to darken, and it would dim the number.

**Nothing to delete after updating.** No aura is added, removed or retyped: the highlight is a
*subregion* of an existing globe, appended after everything already on it, so all 62 UIDs are
untouched and the re-import is a clean **Update**. Every trigger, load gate, condition, colour
and spell id in the pack is byte-identical to v49, and so is everything outside the globes.

**v49 — the orbs become Diablo globes.** The rings are gone. Your health and your energy
became two 72px **vessels that fill bottom-to-top like liquid**, with your target's health as
a smaller 44px globe — at the time all three sat on one band at `y = -262`, which is the part
v50 replaced.

| | Globe | What it shows |
|---|---|---|
| **Life** | left, 72px, D2 red | Your health. Brightens to a hot red under 30% — the tier below the Evasion prompt. |
| **Energy** | right, 72px, yellow | Your energy, with the **35 and 40 marks** still on it (below). The number is your actual energy, not a percentage, because 35 and 40 are absolute. |
| **Target** | above you, 44px, D2 red | Your target's health, red under 20%: stop building, spend what you have. It vanishes completely with no target. |

The unfilled part of each globe is a near-black disc rather than nothing, which is what sells
the container read — coloured liquid rising into a vessel, not a shape appearing out of the
void — and a brass rim is drawn on each globe's edge.

**The number is now inside the glass**, and that is the whole point. It is also why the
portrait had to go: a `model` region cannot carry a text sub-element at all, so the ring build
was forced to park every percentage *outside* its ring, where it competed with the world. A
globe is a `progresstexture`, which can carry text, so the health number sits dead centre at
13pt (10pt on the target) where your eye already is. **The trade is real: no portrait** — no
live face for you or your target any more. Diablo never had one, and nothing in a rogue's
rotation is decided by looking at a model.

**Threat moved onto the target globe's rim.** It has no vessel of its own, so it became the
colour of that glass: **green** while you are safe, **orange from 70%**, **red the moment you
have aggro**, with the percentage above the globe and the same pulsing red halo at 80% the
ring had. That costs no extra element and no extra screen space. Threat still only loads in a
party or raid and never in an arena, so solo the rim simply stays brass instead of vanishing.

**The 35/40 energy marks got simpler, not harder.** On a ring they needed trigonometry; on a
vessel a threshold is a horizontal line at a fixed height — `(35/100 − 0.5) × 72` puts the 35
mark 10.8px below centre — reaching exactly as far as the globe does there. Same dim + lit
pair as before (red = Eviscerate at 35, purple = Sinister Strike at 40): a permanent hairline
marking where the breakpoint is, plus a thicker bright line that appears the moment you can
afford the ability. They are now full waterlines across the energy globe rather than 5px squares on a ring, which is the most legible they have ever been.

**Nothing to delete after updating.** All ten UIDs in the two orb clusters — the two group
UIDs and the eight regions, both portraits included — are carried onto globe regions, so the
re-import is a clean **Update** with no orphans and no new auras: 62 auras before, 62 after.
Three of them move to a region with a different job — the two portraits become the life and
target rims, and the old target power ring becomes the energy globe's rim — so a hand edit to
one of those is what gets replaced. Everything outside the globes is byte-identical to v48,
combo pips included.

**v48 — the orbs are one shared size across every pack.** Purely geometry: every class pack
in this repo now draws its orbs at the same diameters, and the two clusters inside a pack
are finally the same size as each other. The outer ring is **104px on both sides** and the
portrait is **46px on both sides**; the target simply nests one more ring inside it. Before
this, the player orb ran 96 / 72 with a 28px face while the target ran 118 / 90 / 62 with the
same 28px face and a 132px halo — the left and right of one HUD were visibly different sizes,
and no two class packs agreed either.

| | player orb | target orb |
|---|---|---|
| outer ring 104 | health | threat |
| middle ring 78 | energy | health |
| inner ring 54 | — | power |
| portrait 46 | you | your target |

The ring art changes with it: **Ring_20px** replaces Ring_10px everywhere, because at these
diameters the 10px stroke read as a wire. The 80% threat halo is now the same 104px as the
threat ring, so it pulses *on* that ring instead of orbiting outside it. The percentages are
standardised too — health 14pt just under the outer ring, energy/power 11pt below that,
threat 11pt above — and the clusters sit at `x = ±260`. The 35/40 energy marks were
re-derived from the new ring radius, not left where the smaller ring had put them.

Nothing else moved: no trigger, load gate, condition, colour or spell id changed, no aura was
added or removed, and every UID is untouched, so this re-imports as a plain **Update**.

**v47 — the centre bar stack becomes two unit orbs.** The 172×14 health / energy / threat
bars that sat in the middle of the screen since v1 are gone. Your state is now a compact
cluster on the **left** of your character and the target's is the mirror of it on the
**right**, each a live 3D portrait with its readouts drawn as rings around it. The middle
of the screen is empty apart from the combo pip row, which is unchanged.

| Ring | Where | What it is |
|---|---|---|
| Health | player orb, outer | Your health, green. Turns red under 30% — the tier below the Evasion prompt. `%` below the orb. |
| Energy | player orb, middle | Your energy, yellow, with the **35 and 40 marks** still on it (below). Its number sits under the health number, in the shared power slot every pack uses (v47 shipped it as the larger of the two). |
| Health | target orb, middle | The target's health, green, red under 20%: stop building, spend what you have. |
| Power | target orb, inner | Whatever bar that unit really shows — blue mana, red rage, yellow energy, orange focus. It disappears entirely on a unit with no power pool, so trash mobs do not get a permanent empty circle. |
| Threat | target orb, outermost | Your threat on *that* target, 0–100% of the pull threshold. Green → orange at 70% → red when you have aggro, with the same pulsing red halo at 80% that used to flash over the bar. `%` above the orb. |

Both orbs **self-hide when there is nothing to show**: no target means the whole right-hand
cluster vanishes, with no condition and no load gate — the unit triggers simply produce no
state. The player orb still fades to 50% out of combat, portrait included.

**The 35/40 energy marks survived.** They could not come across as-is: WeakAuras' bar-tick
sub-region is aurabar-only, by an explicit `supports()` gate in its source. They are rebuilt
as marks *on* the energy ring — a permanent dim mark showing where the breakpoint is
(red = Eviscerate at 35, purple = Sinister Strike at 40, the same two colours as before),
plus a larger bright mark that appears the moment you can actually afford the ability. That
is the same dark-line / lit-line pair the bar had, and they now sit 11.5px apart along the
arc (10.6px as v47 shipped them, before v48 widened the ring to 78px), *more* room than the
8.6px they had on the 172px bar. What changed is their
shape: square marks rather than vertical lines, because rotating art inside a ring
sub-region needs directional source art that WeakAuras does not bundle.

**Nothing to delete after updating.** This is deliberate and it is the one thing that makes
this migration safe: WeakAuras matches auras across imports by UID and never removes an
aura an import does not mention, so a rebuild that simply dropped the nine old bar-stack
auras would leave nine orphans sitting in the middle of your screen forever. Instead every
one of those nine UIDs is carried forward onto an orb region, so the re-import is a clean
**Update** with no leftovers and only one genuinely new aura (`Rogue - Target Portrait`).
Four of the carried UIDs move to a region with a different job — the old `Rogue - Bars`
group becomes `Rogue - Player Orb`, `Rogue - SS Line` becomes `Rogue - Target Orb`, and the
two lit threshold lines become the target health and target power rings — so if you had
renamed or recoloured one of those by hand, that edit is what gets replaced.

**Two honest changes in behaviour, not just in shape:**

- **The threat ring no longer loads solo, or in an arena.** Every other pack has gated its
  threat display to party/raid-and-not-arena for several versions; the rogue pack's missing
  gate has been flagged in this README since v3 as "a one-line addition whenever the pack
  next moves". This is that move. Solo you are always the aggro target, so the old bar sat
  pinned red on every quest mob, and an arena team has no threat table at all.
- **The target power ring is new.** It is the only element here that did not exist as a bar.
  A rogue's kit is built on denying casts and resources — Kick's 5-second lockout already
  has its own bar in the PvP column — and an arena healer's mana is the match clock. In PvE
  it will show a near-full blue ring on any boss that uses mana; that is the cost of it, and
  it is why it carries no number.

Ring arcs read differently from bars: a 172px bar showed a 3% change as 5px of length, and a
ring shows it as a few degrees. The numbers under each orb are what you read for precision;
the rings are what you read for *state*. The one number in the build script that may want an
in-game tuning pass is the radius the 35/40 marks sit at (`TICK_RADIUS` in `patch-v48.lua`,
0.94 of the ring's outer radius), since it depends on the stroke weight of WeakAuras' bundled
`Ring_20px.tga`.

**v46 — earned combo points pop into place.** The five dark sockets stay visible exactly
as before, but each earned pip is now a separate lit overlay that appears at 1.85× scale,
flashes brighter, and settles over 0.3 seconds when that point is gained. Two-point gains
pop both new pips together. Spending points removes only the lit overlays, immediately
revealing the same dark sockets underneath. The five existing combo-point UIDs stay with
the lit overlays; five new, append-only UIDs provide the backgrounds, so Update continuity
is preserved.

**v45 — the cooldown row shows what you CANNOT press.** All 16 cooldown icons now appear
*only while their cooldown is running*, carrying the swipe and countdown, and vanish the
moment the ability is back — the pattern v42 introduced for Stealth, applied to the whole
row. Because the row is a dynamic group the gap closes, so **absence is the readout**: an
empty row means everything is up, and two icons means exactly two things are down and both
are counting back. Previously all 16 sat on screen permanently and merely dimmed, so the row
was busiest precisely when you had the fewest options. The desaturate went with the change —
under the new rule every visible icon is on cooldown by definition, so greying them all would
just make the abilities harder to tell apart.

This is safe for the rogue specifically because no rogue cooldown is a press-on-cooldown
rotational button: all 16 are situational, and none carries a ready-glow (a hidden icon could
never fire one). Packs that DO have such buttons — paladin Judgement and Crusader Strike,
druid Mangle, priest Mind Blast — keep those on always-visible so their glow still announces
the moment.

**v44 — the PvP layer (ten new auras, nothing else touched).** A second HUD that exists
only inside an arena or a battleground. **Nothing changes in PvE:** every one of the ten
carries its own Instance Size Type load gate, so in a raid, a dungeon or the open world
the pack is byte-for-byte the v43 HUD — same elements, same positions, same behaviour.
The 46 existing auras keep their UIDs, so re-importing offers **Update**.

Three prompts join the existing alert flow (left of the character):

| Element | The decision it changes |
|---|---|
| `Rogue - CC ON ME` | Which break works *right now*. Colour is the category, `%p` is the countdown: red = stun/charm (physical — Cloak does nothing, trinket or eat it), purple = fear, blue = root, green = disorient, yellow = silence or school lockout, orange = disarm (no rotation exists — reset instead). Catches school lockouts too, which no aura trigger can ever see. |
| `Rogue - KICK NOW` | Target is casting **and** Kick is genuinely usable — cooldown, energy and range folded into one boolean, so it never asks for a Kick you cannot press. It does not exist while Kick is down. Desaturates out of melee range. |
| `Rogue - TARGET IMMUNE` | Do not open, do not dump. Divine Shield, Divine Protection, Blessing of Protection (physical immunity — a rogue does *literally nothing* through it), Ice Block, Bestial Wrath / The Beast Within (uncontrollable, so Blind and Kidney Shot are wasted energy too). |

A new `Rogue - PvP` column (right of the character) holds the state read-outs:

| Element | The decision it changes |
|---|---|
| `Rogue - Trinket DOWN` | Spend or hold. Visible **only while on cooldown** — absence means ready. Tracked by exact item id (both Medallions, both rogue Insignias), never by equipment slot, so a PvE on-use trinket in the other slot can never fake "medallion down". |
| `Rogue - Will of the Forsaken DOWN` | Undead only. On 2.4.3 it does *not* share the medallion cooldown, so it is a real second charge and changes whether the first gets spent. |
| `Rogue - Enemy Trinket` | Their 2-minute countdown, one row per arena opponent — the window the real Blind → Sap → kill chain goes into. Arena only. |
| `Rogue - KICK LOCKOUT` | The 5 seconds your Kick just bought: Cold Blood / Adrenaline Rush now, and stop spending Blind on a healer who cannot cast anyway. |
| `Rogue - My CC OUT` | Your own Blind, Sap or Gouge on each arena opponent, with the remaining time. Do not break it — and this is exactly how long the team has. Arena only. |
| `Rogue - Wound Poison` | Stacks and remaining on your current target. Five stacks is −50% healing and it decays silently between swaps; glows in the last 3 seconds — Shiv it back up or get back on the target. |

**`Rogue - My CC OUT` is not diminishing-returns tracking.** It is the remaining duration of
your own CC and nothing else. TBC WeakAuras has no DR prototype and no bundled DR library,
so DR cannot be expressed without custom code — and a hand-rolled timer models the *reset*
window rather than the category state, which is wrong the moment two spells share a
category. A partial DR tracker is worse than none, because it gets trusted.

Also deliberately absent: Cloak of Shadows and Vanish availability, because the v43
cooldown row already shows both as always-on icons that desaturate with a swipe while
down — the same information twice is how a HUD teaches you to stop reading it. Enemy
cooldowns, enemy spec, and "only show casts I can interrupt" are impossible on 2.5.x;
the reasons are in `../../tools/tbc-weakaura-creator/references/pvp.md`.

**Live acceptance note:** `CC ON ME` uses WeakAuras' source-verified Crowd Controlled
prototype, but addon source cannot prove that the 2.5.x client populates the underlying
loss-of-control API. Get sapped and school-locked in a duel once before relying on it; the
repo suite verifies its schema and gates, not live client events.

**v43 — readable combo pips.** All five pips are now always on screen: unearned ones sit
as dark empty sockets and light up green→orange left to right as you build points, so the
row reads like a filled bar instead of floating dots you have to count. They are also
taller (8px → 14px) to match the resource bars. Previously an unlit pip had no state at
all, so nothing was drawn in its place.

**v42 — re-stealth timer.** `Rogue CD - Stealth` answers one question: *I just broke
stealth, when can I re-stealth?* It is deliberately not a permanent icon — Stealth cannot
be cast in combat and out of combat it is nearly always ready, so a persistent icon would
be a passive readout almost all of the time. It loads only **out of combat** and only
**while the 10s cooldown is running** (`showOnCooldown`), then disappears; the dynamic
group closes the gap, so it costs no space the rest of the time. Absence of the icon means
stealth is available.

`generate.lua` is now a reproducible lineage build: it starts from the committed v41 snapshot
embedded in the script, then replays `patch-v42.lua` through `patch-v53.lua` in order. Every
step decodes, edits and re-encodes through the shared toolkit, and the final build asserts
historical UID continuity before writing. v52's `WA-REMOVED (v52)` licence for the four deleted
target-cluster ids **expired with the bump to v53**, which is how that allowance is designed to
work — it is scoped to the one version that spends it. v53 removes nothing, so the strict
default is back in force: no UID may disappear, and none did. Re-importing therefore offers
**Update**.

**Closed in v47 — the threat display used to load in an arena.** Every other pack gates its
threat readout to "in a party or raid, and everywhere except an arena", because an arena has
no threat table. The rogue pair carried no such gate through v46; it was largely self-hiding
(the trigger produces no state without a hostile target you are on the threat table of), so
in practice it stayed blank rather than lying. The threat ring and its 80% halo now carry
the same gate as every other pack.

Keybind labels currently baked: Sprint=G, Vanish=Z, Gouge=E, Distract=B5.

## Import string (v53)

```
!WA:2!T3xF0XX1195HRKOiKSej4hsIwIEfvOebJe9(jwazkBV7caILea7YzxascszSZUZSygGDNz4mZIpyRtRrvCzSITmHBTJJILvrp1n2jnTfT1T1Nt)WSokXUojVGQJ8CAIRCyu8xYP(yMtBtAtR79(EZSZSlxacccrtES(dmyM38EZmV393937(UV77TCJ1PjF0dh)WH6SwNIDkEH9TsjHYtlAOPNwRQMXXceiqUaHoCC9olRPAzOvTQKyAzLQIgsQtTcV2K1Lc(ubtvVsfZl7EvYQsgwM67W9AEjtT6gLLmBK)CgAL9LH0AAvf1Mv1C5gzyMCxUKMHOKrkNph9TNQQY5pVGHyWcq2Tu0nMll8wLS4kXYPSX8Se(g39sgstQOPwyEDj(jn0QRVell5voV0DUSGAzznJCAkQwLs3)if6NFz2TzvzooUalROwrZOMGf8u6yfH6wqbYQJxz2HHqz6jDZBAjyy1rPkkQkMYDKc(NvhlyzOm5KsgM79XnCo9JWRkutYSJuw43JqDdHilyQlvTAgrZoUSz9ssZiPALhAdvMB5jsNmFHjYxijFHg3kNHeCl(856FOHwsuQeKtSQzmy)dLBGrhINMPsdkju1sovD4ROKEvH5LmwSUQZNqhxIvdznqB7kqvxYqvO6yWhkuxoZIcQkSAB3KhCGljjykL3ceXtAjVvY(sPQPkTIi8HJ5ycSAyykbacrZfWSIFmKqPQjOOoa59afGeIeMeHef()d1AklAkvTcTXNSZ9RiQVBMmVqQ0uOt1G51LkBUKLw5zyFC3DUDVCfdOfe(IeSecCfM8Bamj8nxkFA((7FehzygvOcgisDfXLJAot3vpxMSDfPRsWhBfLj7yjOjLNInm7G3SSqvPalH1dfMOnvvnbXbszcWK9WxRoGY6ifiPkVhsFDWxUQGPjEwjlOCQw4Po4Q(fNusFh5pxDbdPGduhQeNuwXsQZYVCVx4Dt2sdTisGX13JlgpFvLYsbfufd2hCYvAOTux3QUHKB7YtfSpjbXQZheAYm1u9sEafOKNusyAvjtt9oDtEqPAAggYctkr6GCpK7LJCFWFVtzYGKmK7NSDYoUtYU7GSlkmN0jzNKN6mKhaK6DqEOoi7TdY7AVpo5H)iKhPdqO9Ujb7G8OK9tEmYph5aKhN8eKds6ICiYpFhK4qrFYTrEVbihgXmTk3JDTrcG0NChK3xhKEcq6L80L0Hwpav0n5ilRlPFQWINqSVOrjjaaa593b5deGKSdsQbiPXwEs)0JdqpEu6X90XfESLuaXzEkDZd)oizHN)9XH1Yvk7WXKFwfDPIxY9suYj3C9FeO()5PvESM7wJHgcOr4sO2lv3vr08qPIhor4uDNirmO56k1nL6FoGBipt1UiTb7NVJLfvmNQUkWzmJueHQv13Ha98cmnZH1eL(nFhGq4ktljPNerBw8OEMm2cdA7McwOIh8v((F6xBLjRQn7agsNRUKA55ZDhHoCK4K9zaOA8glJhoLdR4c4fO(XkLQBzPPMfuNawHLWKhIQzVBA(pTt(xeVObPFGlbvNJ6MIm9M5P6lPWtLPFifKvktHFbO3Fif48DqFbPymYxyN6DAjnN1eMYcIEFAlstdpS)dae7(YHhd8LzP6YvKk5OfYQVtAIaDSgswv(KkIaHxs4YRqVbqskjst8dVcJKWTYDj69NQUPLsL5HMvdnlOjTaKyQrYos)SMqmplrZy5gndSp1kqFF6BFadLZh8e1ferAOGfk0uDZ9nTcnTzH6)jne0x4KoNSsJNdL5o7OfgkZi97u391H0LYmYi9ZprQSfkKDyVcHDC9io1Pt1uDAgftLsvLkwzfgv0eAS76qhobYLfWH93PErBEDsXT4Uzxc0haII9Ti0EWsQKSKYKYwNGKASfbmXeuAWIoQCd84LmvuNSQepF2JoA)K(2d5Jx0r1KPME)PqnsYluezDyk6PoVMwnKpmkQ8JQ3itWXC4rqccGNWhpslP8qTMcVqvDzHa8ZIs(ta0aabYSJxoC1mjoFLuZAOOI9KijZ7jwj37tEhKK79X5lllvE6bipCGfMrWqraAkUS0C6kSE6kOutA)A67)ipd)mcvRl1zCJYYcQtkbDUt(mfxqhSlbm1zESxLdh(WiWFbxILI67Y9ueM1NIj(WflEHhJCIMyMi8fj5Bdf0xYLcYaEezvRoFrgxe07JXKswiH0jlskC(uH7nw0u90D0EHdXcXhoCKerPhJrpgNps390DcKqNYIBmys(HbRgqo8tronzCk7d5mu(gYzP0mKN1LAH8bjtWrkseiL2nPmhrK18bSrvcqMuMihGOSdYuGMozAosvqFMuJ11IkrJOtohX4dtm5iqN9K6KzGh4SK5ypJ5jNN83GJ83K8Hi)cK)wK)2KpmzHhH83HJ8CfRq(f5iFKaK)USh1fks(Lqqj5JsEEehs(L9WFKpg5J3oyh5fAcZr(exfG74Byah5Ibil6a0Mw408kqhWMtni5VNm5VVd8Qkh2z1NTi5L2asCYNZrwtEzpXCKEc3dEOxqQgnEu6Xy8rIhnwVGeU3U7HpsIW94jNj)6RUe(y3isyZnUeENKfEuMeEtcV8a3eXldTPGxYkwi2WZeRV6ANZpE5PU(HlRMnkKcJZhnCKOXOhJtp2n9yc6XEqiYjDnp5NT5agEtrMoNy6U7kSam4Lu(LP)I34Y0xUHm9y8H7oE4W8Htenwc6XEOe7XAinFB99nxSXiBkyJdg54Ntz8Jzot1zxfSrOffmkZSi)52djW513zJriQ2xWHZKpFMroQ3Wdv01mTKA4kLbKaRg9guz)ZiGJzg9WsnDWM1gUyjDWSJeC4(9s54zsF8GJK9KEJOSqs(J2FHGzgE4rbtIXrpc1G77RSWKgkIOvR7NVpNXnUaytsEDHYsb2idDCzWoS61uDEaasDJoasWWpLjvj70W0sahlfhomX1yaIEde3G5VdPIK4Ly2AddVSKHGOsDZN7EBmC5ljoVQqnLYuFibJCoLPMHfj0svGH4NwXOmy4mVjwnENqp(4yHVmyRl8XOAnamipnJs8j7lZO5rufmu5SWqBDbx3jG7weByPdx5Eqi4c0bLacpoa2y01uhto2uM6Zhnf82ND)JMd5n4RQutX6EqWZU7ybWC8HWRLVWph5eCUyRMyyamEZ2wScuTbJEnZlRnBw1vmP)ByWcgWmE)DKGgDCiYOKX8mOyn6U4qxnbdFoy0yv9izWBhoo7iq3uKs3uSbDZARsxPHk9s0XGOvRKGLRgDtk5EQ3iQQczFL0nKGberIAGUQkBDlk659S1fC9NveuV)BTSjmKEPsAWqLR1oD8lSD88vSaKJzvCSJGcH(omHRXrhvWnz49vggLj8mIs(VTi1dt0XG7Mr6yOlrtFEejgJCroYR3z4oNxCBDoh3I0HYGLyb3sqh0fTafzLBow5EpBDf8on(GksZiT8uEnaIa0qzbKMd12lvSb67FVJxxCjPkl2789KSq1tiPJKu3lhIhrhxG(rmdGP1FImOhdRaq9ZIxBEwHskvvSMFcdK8yct0xwIWFKpBt9QT2aZFlay(PGXAYeNv1MK8OgtGeE93h0MeN8elLMENGdb36X4ZFsGiCbrjtRrvvSihcDrXe1aOl2EvKEL7nlUGB685sYZFAa5YExKFmOeCf2tN8xqb2)paa))ZIK)xfj)LK)kwgVWo4H21YtNcD1G(oWN8KsQsgkLzQnfxPPlxMPfXljiopQ)Si1drJiut6Ut8Bq2hp9swV66pKRZUrk6jbOPzWds9yux67eFpsOlKMOXdO4kaSTAE3lnCP)PGIgzcuy17etcOd1mK0GX7culq6mD3fDakLN2NvFVHENmKQJJOG2yLY6hUc1vvAQh0QRGgsw1nudEqRZe(zdQze06mrE2UOES06mrF2GsQIRtlh)JAMgONiiImCBybUzAc5maNYLB0ooTkoODNokUAELL8YektVkwgY3cv4DOwiVo5Bdj8NS68iKlt(tHB9g0c9Nr(oKVBBidiFpY3N8dksEtxfEYpSi5p)AQC)FOfL7Ajh(OhB0dgEWrMZt5M8J07A1uPNvaqpAgtuwwOAv0DhOHkRBL6piO)8kqDRlAVnuKNmGHT0lde2pH(2lqVkyEfR6u6xaJEzVCrvExSrj2FIquSDJeMa94Ia016(FFpdcTxYRyGXYmWnvbM8)M8)H8xxK8)L8)J2L2p5nopzF2CVdMAOnhNn3wkAZfGNAaLn3DIkr2C3LRoJn3wlED3NxRa9yXxnG(1gAAZ1XQdhT5UhO(CRmk8)ylOWJlp6CjoM6b7ZC8MqHp2A3Xsfu6CdG)a0szjvlz6CJT)4HAyIdY8hKAc1e4mMHIDgrFtLOO(EA66gWVopYAc2U7D9zBlAZWX(8nF8gvaGhse46gU9rCHB)XRjIdRu3kd5(kTa5MkufLQMjovpcZ3eK7QSLHYT74hFN)bCGITAlJ7G4VZ2ni(9sZf1w7hhP5sdgTlgmDJjnNIiVUC3YF0Ay7mt0w5TOEnrCbGxAgSaOhxlXPAn4eliV2dZ(X5Xz0tOye9z0l2gqdiyrWccAqOHdOXbk5cACaiiMbqinWnVzdCdGOCXnyrDWo(bnodXhGkagWfTCjxeKVbRZpzUzYvUmmGijeXaWjhwMK)xFCYNcNMaYNEzNaHGoIyn99)mpd5ZKkFHrhH8RIZkqRcRx8kEtoaD2TA8GS5Em3YVcw(jgU)0dMCKmPxLhKn3bAxz5tJo0)6Rmg5YcgzNp)1xPsnq)j5DkcLPH2(fy1lWkybATATUkPr6SJmWO573xzIHFE9s7qDT(g5ZMTGVs1GsCvFt5Zmu)JKUF)nf9qFlrw9cvkxY0zg40xxLzfwz2iVo9TNp9GzZo0ezWGvHF0CfU((A7lt(wGiXOc7qonKir3luK1TkgWaRk7MkWUna1TKiB2tKkTGjy60dwK1p4xYxxERKKokIGJsN2lwVF0U8i)ervFD751lk6HIUO2lkdJWHAdqrNXmTl08UGPLfWqVbg2fC7YM(8o6InkHb7mj4Pt)UABhQ)uGeA9oWixr5Bvu8p06HINzoW7w2NfOxnbpypGOkJL3MliK)hLXWJ9OH9tVxgs8ojF6lXI1jvECOeUysogASi5fjNLso3(U0)p1sx6uc6Pvkp9i(9MkWG)J0F4w7vpPJHKhhYUdcF90d(h0Xrbm3W7Zf8aGTWxms3XIKkCOiHIeR3EsfpEIO4vrGZ6TxE4Se9WhlESO9WhU34jIXhnwSeH9MSfxyUnxSIUMgg337WMRBBUeRj492tlgq401WwHMqr3czNWxD1StqPwT6QTANqhoiTMJ6RVSNd6rpAPfmVw5PLScg2Z57S0PXacKC7ZEK2N9iRs2J2(ShDvYES2N9yRs2J3(Sh3l75ObHyW0vRBcAMnchTZDRB0ODxErJg1B9hz54J1RrPthkCeX4xxbIwqO83fnQKQBiHbaegNx67k9qjhoxHSPgkz6JNSV(YuiZy93cD5ckQmVEcKKoSLuQsgu6fjxeWAu96O(o2nR3dY9w9okvtXWqZqMCFBJC)goFbWN0Iq)WQI4NbFkWeK(S5gtpPhNzsrXSaPjgqHjXyC7SdljQiC2cSYBEwwWnobnUgNGfExh2AsbSb7v5AwK9bDP5yuC850Mfe)OFr1XZWWhDBEKQivhTB)g30hB5NY7XWykpudMYhKAcrlCKOGdqqGi0r91MBakScvEtQVdrfZYgsqnW)CTWpzADeuhku4n(u(bCYp)JuIfxzYRV5GeWSaoboAZXBZLVPcTAZSHn3ey3EmZey8)y0MCh2CJYK4GyfQP2CNmcGVyq2JSC6HSg68jgO)Usx3M7z5U6o8(oUTZxMkf87LTfBiBkIcHXrHap96odBZDMT1SaXM7SRhX3Q0fh0icsVlYuIFfk)TRZfUiwzJgN89wIofh5Qx1uc48VJWiSh7zaj(z85VPtQaP(6tV3M7OuqIJMpGNFFWN3y2CNgP7F(hXV6PnxHwSHXtXeuKbTEMUVJmTzDBOWBiT6JSLMKV7b(6oPn3PC(gV2QGoInFIlhbW6uCT(12g0tBJI08RDf5gu7II9FlxZcAYJh3zSMoMp1A7pv)YMROR6L4iJK0szWXsuyQRH6LnxjqLYMRCrFcfXoJ8tdfjBUnrfOm3ARaXD7I(ZXwd9NO3wO)aYJE9glB4aT243QYZGA5pxTmNkuC1ZVXuEIEBVYZXV1w55O3UO8m0AO8e72bLhQfDDZ8nhuXAPLVvnNAJpUSPH8ydp9SBmnNy32R5m8T2AoFSBx0Cgzn0CIFBJMJNxTBPLVvnhTHYn3KZBgktiXnMMt8B71CYUzQ5GE7IJJJ5QTaJR)aT4cOCAgy0Sz5fARorbcVI6KEjYwbRTKy)QsgtoplXD1sXhOQGPmZXs)WTJF5VtqM)xrRz74orp0C0RYdnmK2UO2PeV5d9q9k1hiqZWbMdOqb4Q4bkqbdeKByDeqStrLXPlhwBUCa(unTzjXC8901aZ75oQ7c9UfqA8(7G8Korak6cTleD5AAIsvZysJDgS1iIGUImjl(Sy(52GMJjMJdQ4n8k5vX84dZ2ioqPyvhVFV2G7RoNUG7lP7i(hxtRwrOcFj2NtfLQszejhAj2L6cwYKdXQmtyAnH18CaW031ZrJV3N)0RpYep)VUGjB9skTXDoi2wJUye9CzQr0uLi3pp9dJSJh17lSU5jmeeNraEvYEPACEoqG5icopQPbMe772q1CXt7rfR6Kti5lYe9ac49(a(kWCVX213o9Y(CIqt1kAYaS5eJEIzsLEUHsoFI1zVx(ADHVS90XfE6s1nLmGxo7)ZHti4YcI4kNusCyH52I3fkQBbGxxPIMHegF0QISfVjZPuu9j2S8QVlVfXkUA(zzwEztC9BZCVyr)5zGgpqzVffHdz8ojVmLaD70PseN4eabE)Tj(KxqsvmjUWeFU9aaUlR7eRLSvg8HE43Xw2Wqb9TxQrLWzLysHgjFAFZ96oWw73hWyIbWM78UcTgD7mMOx0M7J1i78ctcpoxo2a(M9A6aPchHDSLsTmlY3Olmr2IuK8z605LXrjNbwD6C5TmnYqvPbXUVzIXWjjCYxiBVykqdvS4QPpndVUGboJSHkwYAwjv40iwsQfxIDrfLzKkUaafSMVMGkDEC03HhYWrmRNy97VzKVFIiH0NJ6L53)EVWEOZy1LoqJqb8ahWzUR0FYgRN4jy7AdEHC4eIsLvQjaSlgWjMup(6FQUQ7ovx6p6A8qyjuAK61kjz4mPyOqjrephfLiw7wam6hynES02g62PaFLQAAgKf2nBc1ip)xJsFxQSHM(e015DSWaXH(2brzshfqQ(OS(o8GJonE2CFoEZQcQwClr3HkO6bSGF6Ibq7IA9XOOktU)R4QJ4mLb0L6oVRBYzwUUe9XoGIHjqvJmwlstaNuHszgjFM(6Fzn2YmVCvfD5fCUWSdhd62thxX7RTXA9M5YTfkRvddvFtzknO2LnRPPzj7gL0fPtd8xRPEToYYJNQV8dnwp9oC484eXbD1TSMHcGiPF1lMEOSPp(jZKVFwd5ConK7Udd63TKO8fEABUFjO29r5O(P453In3V8wC610M7JlBZ9cfV51tPn3fP8v2Cls5OOMc)jHVRVaxd(L1Mq3hh0daSprdb5QZJSoPuwSgaOO2GHujoKknrOyZ9jGMKViNNcP(2pqtrizdTY11mkRh6QupAoElBJ6BlkyDDnEcEkz2C)JqDl6ssRn6LnxmwI2C)djp)xGQlAZ95BOhAZ9pgAg(1bfTnC3i2CVewCpLsBUFdzC0k)M2C)t4ChO4VftnZM7FQn3)mBU)5qUw2tzYM7FHN(Jn3)sMMJUn3)kM2Yxy9zP0rwoDTERQK4u9oYS48zdqIJ5f)a9qXkr6b(i)xBZ9VXM7FBdTiBUV8gubQTdYDRnRBSogq1gut6yxNAsIOMuCNU0DJBf9DHb2xSd7qxogBJuOLsfluBlv8vRulaAG05wduadV2kGJV2XWr1aTQY1q7pw82VunFi3LQ5koFDd7mtY3BU7ks0dhprC2GQp1DfobqE0Zs4UZXe6STYh356UrpgxU5QyrNTDPjqlo5zfAFl5SRBG2gSdNt6ZBhpX9r4A(WtVXMUAQfelUv2MTbC3uUteoOIHd37536LC(2CQlOpfwXF9rs(sox6SbP4p8AyQFxak1xL2uXACCBQCB4(TXh7RaYVFhW6OFxBUVggSCFDBU)ZG48ByZ97bFG2C)(n(IS5(dyFh2Ce4V)WJ54zqQf1T(gBNWX)BuEvEJ3JV349CvVXMJHO1F9BJ928x)Gm8HU9IZ9Cn4C)qRxo3kHgBQbgFKzprSzD5CPkOUdCkYQr4g0PPPHFkXaoH6cmCSfSdu)pYerSaDdQZoUaR9nEUbBf11eFl0ttyquH3(QhlmklE2M8Cj11rFohNy53VIgye)CrQHBVk6vXzli0D3DnN6PhkhDqt0X39AEJV7(k6FmE44O6jeLNVtKeDngVhyXmZpJSGx8t5BCo2CFANH4yZ9RSQRz0zS5(m4OBS5(vH)Er4VFn4VpRtiPbvWleI8VdxF271Zlua7JoBTwx2SX6Lom532BHstELn0kKM87CdTUOj)Uqt7xB9VAOjF9IK4PgQ)bkGkNFdFlaAYVh6iTFF4r(huKq2g5E)wOtO(djR0ML08wrj))L7X1HIhzzPHlmQ5jkCQYtDqYRXZN5OdwGIf)MUEVYwUrezU1R1EJYs4ASmDvnvjyOaR2gFXtZhjuOqj4J0tOEJYhlsVj6EJUzxSgrM7BjlzXh6AUKftUzTZgyZ9QT4M5FqrmajPoygHqVEeeuGUx(nZfimCkaV(USZyEyUvNA(k0L1tdhwtxapDo3pgFeDoph951JxKwsNMbwGukmZKjKLowFtfVQ)DhbFBEoVhYRT0Gz5ZmE2rkKCisGxE767LP)LUpCdde3ikfQQOkfKVUPSRNNP3lvvbrPGduTUHX8UbRi9gqN4IWD10eBk580v(dm(xD3yyKMCoWYdb2sfx)bBo9AGrhmZDC3a(O3XzrE5UbxstBmbCtIu)D5)ZOQMW0b1Q4(IVIV7HbTCtLpVUbUrpSDFjDuT6tk1ukPGgcXMsHT9qStFP0NcUYYlB10xCEl2W(CjXEY7GQmYu6BJ7WxpeyipITSlx06KisEJt6buxUUOTzQlqz)Bsd9uK)g5UoYYYDP1tx5uMwAYsingLX2Lh7U9XJ9kupU)Edqj6CO0zCxVkhUEjaUR1AxxW3kd8YS1iU7Q)2zzcg)l12Lj4vAbwVUwUG4oJGZwJAXR16g8AT5VS20qRNLNkw18iKC4G2Dh3q7PkzbzZl1CNdnO0(2URuahMLSZnD6UtFQkJhAkFl(pgTYtDMRpzNn3p2rE1D82kVUKFQM1LWYM7V4wbHeuFUzkK(tAriDYAtoDCJWh8O907MOqkHqBfsl5r7F7KicQn3mfrxUfr0yX7D(YYPNsPYr3efrF8VE7frEDbF7KicQn3mfr)PTiISYKAmRbpMcVv9ntTiL2kIw2N5q3wPgPCtvg9gTiJov)ALTupMEvZnZUJsmzBLrR0KPP3wjLM8MQu6pRfPKcF1ZPmZ51cN)KBIsPvzVGWM7DDlIOz9oSY36fiFNweiNlT0P6QwAZb12efi3HvBLhLydrBdjtUb2Um7C8nSFdwHTzrxiBoQVBCN94Bxe2F3wTg0qQ3q1NsUpJtVjQ9n)FzBL26BV1HF)2kJTiF(ETiFYLjXbtm14zJljT5jFevBR4jf6aK3wI0Ie573IeP3iItBnl)GYP3e1yS(YTNEK5bQB60JhDdtpAVfUB74e)bTQZDSEM2OqKPSgz6nXoa1A)wHg1HI30fW9)Zuc43SfbCf(jZMV8XNl)0ZV5jGFJfAVaM6F43MvTfrYpS1XQv7K9LBqXrgQWMOo3QS9dAZTR3wE0I84pVf5rMyPo3OdD8zozUsBEYJxD62kpwWD6rUztdU)uX)zkEW)7TiKJyuiwKkhxOVzRT6cz8bUEKWGa7N8CTVtodNP6YV81z)G86xTdeMxLage6GawMkJDu7aXbkaAwKaIjuIuP1L40FS8QTHw)uNbBm2WZpg2EcnRoIw)tQxdHYpcee5TIkmKLCAXyrCMPwhvlqEbcM9qLAS5a7LKVqiYRLQVSNCesGP8T6CadfXTig8g6pAJOLqPAvC4wwYsbhqZWuyAjvww2TV16tT5DlU3ZJUv1JHYB2rl49Rg4WZt3v7HK8cidmwpD(LsJTSGEU7LCFFL2hrg(2Xg9VFpDi)73t7TZqTj6b8hDgBandFrNrRrHHT8AhbgVtF7)q0G3p2QemgBR5GX49gGo5Nnf9fXJuiBUgbGX2wJTeRFbweBMsXsQgTv6Vg3jFFW2StwNbYrxylhRnCbSe09b7p53JQzs3KUDtS5Dfl7T8UA8ST3Yd79qS3YJC3FYVpT42BzFxhfkZxyJuO)bTwiYPIiOoFRHnsXMidaDDMEFRC9ilbsr41h8QUvzLCJVvzDvBiwTzlY6QsX3gELSVn8k7TSt)74vj9H4SqfZWx9oEvr)7TAB7AS7O2wN0SVpqRK13f1jn7QDKgnOU3IxOcVMBEUVLiRwV7sEyD7MHuBxRMuBwnRkXIDdk1q7pEcdNF1s3lFSir6ncUp2fC5g7G64p5HVEKWrcH7yJ0DS(G4(dzW81lxwcxNjo7uKx7T34BQAt7bLlVfjt29QjtKOQsRImj0sM6cgtt)Lbz3xIEoBHMDkoAW5W(bTKMEJOTwFhnDngDZGvKTTJoGB7Xgpv4eD3nEibEOh8qV8r7boL8Ol5BFg13puc2B5ao7x(0frhD1MUK35S4(XnwuWF0)89ZOikRbb9cLem8fb1ncQUZk7VAEAOVXNEpK9TmUcKGsmb83Mqu2TmZB5S4q0nE7Ws8rD)PtKff4rGxx7Xup0gFVX8Y06NVipVigpZKxq2nEIXTPwupKfsYgovDgsW7xLtuBDrABRPc(u(MS2n3aK)GEbipQ6POozkbJZoAMNY7QNkpwaa2TmTKds)XD8zS5gJpDvjbvei)j44P3Jfh0o5truusLFK(hRFENaOMS4x9UPO894IQRQvEAnlM570Gx(1Dm1yJAQ06ME61S5SzHfAHVyQiH6ng(RYAi4Se0Fqe7fr5jq8EIeP6P7i4VHEr6jo9y3uyFSlJ)iKOOkLtYGToQ)Cfz8B6SeqP2ccvQiv2sseTxGfxPy)pyNwR5p)wRD8L6PjeNT1TZgC4n9D(1m)0HXSytmMpGFgZm(ymRnF60mSLpgZ92yHZq(vASgyJ4T1Y(RDD2l3N3)VaJnV1VI)EinoF4Orc3dEmse6XO0JXO)0l271)VbBTeKXrJZoUwOGBj)1y7ghtT5BDuZ4QhC1WvZIdzm86bxf9QWvDoZD8H())d
```
