# Rogue — All Specs HUD (v52)

Import `all-specs.txt` whole. Layout groups (drag each in /wa): Buffs, Alerts, Resources
(combo pips + the ring cluster), Procs, Cooldowns, PvP. The cluster is its own sub-group —
`Rogue - Player Cluster` — so it can be dragged, or disabled, on its own.

**v52 deletes the target cluster and brings threat home.** Your target's health was already
on the target frame *and* its nameplate, so that half of the HUD duplicated the default UI
for the whole game and is gone — while threat, the one thing it showed that nothing else in
the game does, becomes the **outermost ring of your own cluster** at 100px. Four auras are
removed, which is a first for this pack, so **there is one leftover group to delete by hand
after updating** (see below).

## v52 — the target cluster is deleted, and threat becomes your own outer ring

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

### After updating

**There is one group to delete by hand: `Rogue - Target Cluster`.**

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

### Honest limitations

- **The two outer arcs are flush, not spaced.** `Ring_20px`'s stroke is 20/256 of the drawn
  size, so in the decoded string the threat band occupies radius 42.19–50 and the health band
  35.44–42: they touch, with 0.19px between them. That is meant to read as one double band
  around the portrait, but it is the first thing to check on a live client.
- **The threat ring does not dim out of combat.** Health, energy and the portrait each carry a
  second Unit Characteristics trigger that fades them to 50% alpha out of combat; threat has
  only its Threat Situation trigger, and adding a second one to it is a rotation-irrelevant
  change this version did not make. In practice it is invisible out of combat anyway — the
  `threatvalue <= 0` guard takes it to alpha 0 — so the fade would have nothing to fade.
- **`threatpct` is scaled so 100 = pulling aggro**, not "100% of the tank's threat". The 70%
  orange is therefore an early warning, not a near-miss.

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
embedded in the script, then replays `patch-v42.lua` through `patch-v52.lua` in order. Every
step decodes, edits and re-encodes through the shared toolkit, and the final build asserts
historical UID continuity before writing — from v52 on, with the four deleted target-cluster
ids declared to the verifier as `WA-REMOVED (v52)` lines, so a deliberate deletion is a
reviewable line in the diff and any *other* UID that vanished would still fail the build.
Re-importing therefore offers **Update**.

**Closed in v47 — the threat display used to load in an arena.** Every other pack gates its
threat readout to "in a party or raid, and everywhere except an arena", because an arena has
no threat table. The rogue pair carried no such gate through v46; it was largely self-hiding
(the trigger produces no state without a hostile target you are on the threat table of), so
in practice it stayed blank rather than lying. The threat ring and its 80% halo now carry
the same gate as every other pack.

Keybind labels currently baked: Sprint=G, Vanish=Z, Gouge=E, Distract=B5.

## Import string (v52)

```
!WA:2!T3xF4XXX59PfGYIeuoMaIKYIuY6effnHIj19jUdmuQ(UdhiosGdh37a)a6dC7D3cSlWD7UC39aWrhLuJqldBzZMaZOe)h95jg)rEEC)iTfTvjX9ZG64e7Kh7j4jvDFCIItyK)k2TnHTnjoTPTVVZS7T3xaeeKGM0r)bwS7SZm7mZ7V3FZmVZ7mh356PWVu)l(KRLxOWmf1v1IRwsv)0D2zNP707XdP1tbvftD1sLelgxsUurDrLX12pV6uve9Cmpzkjxq0JGsrpda3CdNG5ROzwrxuBFobmGOqXsv9Kwv2qvXn4bLHuEErHzuenm06Xj4HelRQRljmL41ZRQxuupMDztBpXkjF5llOx0twv1sMYA8gfekj25Y6ItjRQKTQMi)u6Qv0YZsO0YS)NO4uIADN5sve0f9myLsL8CEjztXveukiPQdflfZ8XtKkBcE7eKr(YIpySsQcfhmVj8fum3pF5kWxSRygAIf2pzFDXxOKGHbExmdi24nRWsmRjKJJRt95hDYjnen5wtOIj8LgvZekMgDPluGEtF8gMc6MDftwr2SR8tc)ZqQRfm1LNAkrDJdCeD7BFTyvGyKxRKqvO5WeRNcv0f8VauAkvkzrJUUUrL8IZcf0mvMCs55xzI4rZKDImzJYNT2RsRlcVIpt6edp8YffZdXeBY0hkXWPhCSH5Prk)qIcLmL4veklA01svuSlcDTKGICzbSC3h5jgKC4ykQkIRkkyiMXeGftzk9qRvekuymMalI6gIa6POXcyCWpeXFSYcYkqAj(jbEisqsisFWTpzZHSkRHK14TRLmelnjvir6Ezt1cZc5m8n2z69Di5IR5GAIb1gd)vKlUIMO2f8v8SfhiqGvMuhQgq5tWuOZBWe3dIbHfN8zIZNirQ8AaQqX0bwMnwCi3IcyKmGK2ipufMuEkhzBsfOe15YqlkpfYz01nGYLOUIqPZXkwV4YyLwMjOxrwzsvDwRwx6vzvOhMBXNEzziwzuROxq8XFaYb7IKKJShs3RvaW1fvNtjZCYAI5w15realrECOHVlYhOlYt2fXtQJqEQFzOD7zUrfdXeZdiQmmSqoYXihNCiYttosxKEjpl5dsok556AveWqHlYfnE2yH8f2xS(choi5hN8HiE7ALIYgtxrbWLZk6xOujTUfO3NLj9hrTO4)KhGm4lEJzef1IIkbM8y1sI0pivkkAiyIYEOuM4eV1AtvsDUb1fVufrLcvtVdVh3FiYH1Hwn8fRcf4tb)NQNiTagekowlFfttvLrbXlaZxgdEykSAFRG3FrBvPLMYjPilvN03DH6FxgkLaTiKvsUaLCPZy4Js03pSmes308pgJLyXhrRhtX5nNWqsOyD5gnm8YHEgG7PUy4QHFDwOoa0yrhl7OApcnqqLxfL8foVCrtPyrHhVb9fGoOyrAGF01yqsN62Q03pDfdt5jRcnR6QMqtAwiWyPgnvcwtigNLPrSqTwbwrDsGRwBpdQlFzpNTIqre07jB2gQBoFP1OHnhu)pVUG2cN3(M1QLpuIHrhl7WjtLWUUxhB5QjtLkb)eXgnB2rhXnriT5tyxNUqd1PzLnKZxsm3KKdVeuhyktRX(3eQ2X0(XcUTU2H4KABLWjeb1bY7Z5jK(TZ8sIYtjzEwYJCULa81eu25CK9I8YK9tV(OhjVHSYuLe55h9uJLGSV9t(45iVF672DmuHm2LvvlJD8fybhnVC8cL0Ke6K3TXwBVoVeLmdiBiaLnqTlk5NGCcgRePtIpkljWPHuBomDHBjKNSLqEHo5NdbhNLCGp0oiNCL5gVGVsjdF5jJnNUScs(bkzX7I83J8HjN6ahHVGKyHzgK8uDUWSc6Yyz56IZRjZiIZkxwKFwHsve7j0Hu1o0jFE9cscktjcDUqUwUf0GUvf1nRImAh33XrLcYqDrwm3Ipn501ZmrotoYWTHc6nrkiYi50HMJrvkv1M9b61uFkrtKccPFqAONRlsQlhZx)bdelsFb6hUe0lVpF(dhGEni9AiE)9fPVWKFC9HIYpc0PeqnrolHNKHY(qYs5BiJrPziNZHAHCEYfKixKmo5f3h5L4iVmvqrEfoYeDsY1jrqIKVBsbqtNuKJic6ZKjPimYuejImzAYmFusjosziVviQqgQrUelp0jgetosfYSK5iZtQsUm5J8eKFsoYRIGzYpf5NMJ83NLxF0CKfiVpYptNKRG4qYhRz8h51iF8gHDKfjFckGJ8jZrE9ojFk2h9t3iAAh3oOjYvbKeu3o5kZiCrEzyKwgtpe5N1fd11wtIt(fD6P5Z2Qy2FeFrWl9ds1aHcqVgK3FOab7hKW93xeE)H9fbKZKp36lHp9TJe2yRlH7M8rEkMe(oeE5rVlJxEWBB8YXa4YOfZgCKzdoqf1lDBax(LDGlTDujKuJZhWN)abPxdrV2h9Ay61i2dp5D5aEp32Y0pgitNVy8(61Nam82y35KPF2MLPNM3xFH85J3x4abdtVgHYRh8D133wWgp0DeSXr9FMljp(PnMT0CTdB4ngm165o0yPjDCzThPMjaugWZijZKjzQt5o)FznvdtXAtnBqryiJUwniXSc4eL8KwxTSgmGvNWJh3ZOP8msc3qotY4NXtQrpVRjdG5ZEQez9KCKrgdgp8oj7Icw)nqW6YtctSpUSEbyGIlaL0mAcfe7SrWlmONN61OSqiaUUETqwgemdOxyUqWy9QuwHLb51fkkxX4kp8cWWkhwUSmm3yHsYtPq6whM9oo5iosIUipYGnkmPxzsrUA2trNnhAXC2cSMMiC4B(uJjD1jQ18ELi)yauA3RwSkmrD5cuREq65b5lHLWDtEmkIlMHQUjX)ctPlxehq)H4hyjb9cSPvDL9FDyiVqvqXCqyUEQ655JoqYXYaib9EN(0sbN2qRAasKDTaDAiGeJZbWDDhXr0sWGhnwcZF6eA2nINqutusmeanqNWqp2fVb2s(ETHs9NNnTHfpm50CTW1SyUghLXAqZfmcxJmsQZnQYAg0)ncmkgyK813Ls9d)4zjJssVXDC8Snr1KJCr(0W8Yk5s3GV2xi216jEYXiE2yL7jRPCVmD2iQLZlyMBJv0bL6pPeopC0mpjbzJ2hmjABHjHgVxcF24LeYlxs2S6e6y7)egO53kc)HQW2md2Sf1J6Dyj(vbjBHI9xns0SLoROMJO6aCOKcu4Js(AifdtkH4tOkMxtxeMBgPpD0ioJwXeHIF9vGVCrX8QW81lVGJnF8JFxeL2gANf3tEQL6QILUGRzc6bgLWP2cGsTUnGNXjVL1j4LOrMAuaN3rNvpKz)bqzQambz1Y0C)15yz880mUNQf3vpZZrNain4ClrN9gMtl4KtK3UhFqbCnms1ki5OPHg5CRpW8xbaMVbmdwM4SK6uKpO(ei7xIbGCne5ylhN(gpddVQx(mNhyfxOOOH5ykYMKNgn8XeLbSlwEYrFY5L5wWjC(0r55ViGCzFlY3dG2FFwUt(VsH4)3be)FEoYFroYni)pyrCXU5HQsHzIHgDqRBmNNsuruxUatVj3An84km1iErHIvXSCjQDHsjuwCNH)htomp9rQk1X0ES42t2f5RNcqdgEok1st9Q9i43ren90e1YGCRbiLszCEu3PVaQiPwKqnwu)evEFUUwYwuuyMCA9G3dSRQ6IQWCDbIfi2u143rRhMG32KuqBSCbTJpj1OvQkh1Sxp6IMv0v8CuZx03l7rv3J5l6)L7LAFAZxmWl7ruP4MymKava5)CJ0ar8JWlFTHf4U5GjNf4uUET2XzuqRty3NtdmkusMLDJektBKLjh5)IwVRh3YCcqRUQ(efKekvcnvWMJD5xdyxkhDKtD6XoQVHsn)MIDH81PA0iLc5pK82K)O1N)G8nOA4K)yYFc56K)ugta5DSjbiFZ61)jFRCKVn57yROt(U5i)zBGs9Ra6pFjiVoec4zScsag2uRaqyFmT9KL(KNmYMvO8CaG96UXIQ8UuTuCOWEbSTwp1cyc0(kcqVRh6fEEuvBz3KbJBM1hfvbM8)K8)I8xMJ8xr(RPA5)G35YqH6VHPfs(Ft()KJ83Ythjf5)xt6pwCpqoloUC3sD31mgpyO1dJFZrLwC7y9rIwCpiuvAfa(0BCNBtsRQBkO3Voa9oJ0yZh(0khDaJXVFf6baLcIkMs01F5qH8wB4niC4iDHJ)CcCzGYbICghFdPiN2(B45AiVEo5gIZ25E)h2cqt3Em63XHAuHiEjCN3YiTxZbP1agJb7ElxWgwFAAqvaARLHsr5hTTkU9)aMVIBoe3xaqCt7Ds5sgHVqeHQ3ZH4A)84DgB9rqAT4WuKk6jETL3Lcd30gAPneinmwzqIYeTBl9scaceO0ikbGnoJ8MQQGllG06YkrHihXV2SA54X1)dkWiCHjSFsQ8gWnGmefLai6KRWpv6ztxOam7dXA4G)noGe20OTbommaagOZF(RFeYphAEEYsRyVy601c9AXYKDSuOn5F(NN8ZJwJV5MX34gUgLNUIt1YilUNGCT1W0pXijIpu0ujJVHzKf3t2yA5JJMx)wln6PhfgOBMm3APk2GjIY3qsOA)0wToBxcwdtq7Rw3KuQhF0udowMeTKMGyXRFA)BTVmYp6OzBjv1OPAZxktYHtKkEIwBkIq)k(BxIYNoA8KdEXBP0SglnBLpN2EYeFOrhD4jsI(1a)yPZERvAhizM2crcsf2ETBiBLFdj3qEkKGd4Ja(n8jBJy4WVXyWOCB2uDouCin2RJKAo0Bi3gMdix4g3JA96UEuaEUbT46jhLx7yXIlyysnvjTBW30ThV1IsN(GNXOlJh27NBFEmdkq7V7huuXnPhIomrjyIn0rSKZEQs7fhvNN4scO)DaZ2cEDbJ6SpkT4at3Pwc1z3j2EBvC3VDDtpFihCZ2ft)JTzy6DgpGf3JjTUgsfgqai5OK9wChaE8G5AyCbpEZJliQ9OqpJCHzqADGg3MJh6(0H3)FRt)bZaXk1Cy)ent)J9ByVeTufRhKS0QmV1rHNoRQRXvVYvoYBqgJAEms3Bq33VITvbEgsQ)r(7lO)y(863R)G9hjwOqHdGp5hUR)(5H7chHpyOGbIW7R)qHdYhiyWW(A2A9JGas3Hhsb3wCh3grBX9CTcFT48AX57wBDzU3E4c1bGwVbk0a25Mnib5YLRO4oiH)DBIbj01pKisFY6monPJVGRr6rdzP6jJAHzen94Z1a8SWPobceC7JU)2hD)Rt0d0(OhyDIEW2h9GRt0d1(OhYn6PPEvNN4LQyaub0fvORobb9d7yLDufSNhCJSWpZC7O0euA3cR4WwF5aISlQsNnwtR7ARbJOb17YmaqzOZ1VE(l61N)IHA1(8j6c1DzaWKxArpy2r9tPk6IOlbHE(L2EJpC0rsND0ydhn(zIoWajZM8Cj2ulHvEMpmjbWEQ(EG6U2hRVeYbkTJ8LL11v1Lij3fz362FEYvJUe0NSsrSmWhdgd0a0kkvplUgkG961Nw3fLnkOlAkoH7cv0Gm4vCy2ySA8PvNdKZGmzjn8o0xf3LdPiYV1toA)71EzoxcY3WnByKJpDJjSzArGmeADF9TU7abcvlUpmfcAl6(Q4KmT4oRwu3UUIwS4OqFxOV0gfDZVxAeXIYcVuww7OXlXC91jOE96emVE74MtjGO1R8e13f1cYkmtyB33014yDpXiiEdYRJWKOwCNbakhekfJyXLcdQUSWIB8M6BZnXFQtZg4aRVbCXH2HfxAMuhQs0C2IJ3paXyITVLt791PsJ6TM2s1Kr5qHX5qHbp95E8zXD(MKOwCxyZigT7JRzXiOQ8v5QN3hkSwCxKkpa57lWKVFjkXlsa)nsVdFiY(1XkAGqKV9Y0LwiDLsgIuj730ociXnmbEqMJ08WiW2e68uirukKaawJjzXng6DpXh2C4lhEWe9gVctl5QrbHRf3OsnOOUo9WXg4bv73wQUz0UP5(gPzFYoAq(EvqaZBXLPv1y)0AXgP2AlI3YI2Tvn0yTtdfriTOHbQhBB6wqJEOq2t21EWvnlbS1WS4EXMuWS4EjqPYI7LZvxt9R0J)75uLS4M4oJku8wuHkMkvut5Hox4StFVJke3MudkW93AqdCpHgeCF)UZW1xNn38FRQ(e4hDvFs0I6ZqQzUu5KxWBiLlFVJ6ZP2KQpbV)w9zW7fuFOJRRpMbcJ0zZT93Q6ob)rxDNt1IUt5XhxYqx6CJmZC37O78P3K6oHU)w3zO7z0DCnUEtT93Q6oH(rxDNKTO7OoC65NQQH3KElUL1DqdHXXXXSHwhJ76GR2U)bVSYuUbY2JKnfycfr9PQYcCVnL8bljyiP9OnzYP0Q6OtPzsT50b((7HK8huZZojpmAZPHqBlrHjnEjcTraA4ByrpygBceERJTMqPSxA9Lez3OXFUTuBonckCSNeGpbjHsCJ8ftZhP3bRYKej6cTL2POUh77VfJNXKlhSRfprEyY86tuLJ9)55Wm80Riue3lCIfhry(oCFqwPdssUBmPQUi62RkfzBhpxJkhXp1(cr6uBVUBmrCteZIU0kg4oaLzBKC1tBXBusqXKBbrLIrXnk2v2p0eFDnB)EJTDnF2h)b6aBb1PXvSOKRr5T1NQ5uQoQsoIG1xXR1y6O4LVGUQ2eZtjh8bQGSNRA)mccsCGf3p1E5A75zAWbqEMNPDMpVuNRJ9Z18wB)oobBtR2O)LmrrXcYLfknHMoCJb1mBn6g9A9EtYbAZpDVbZpzjvvDYRMJ8roi5NKt7zUjPKfy(uvkNxuNCLppAQ1nLh0FYvIxU)sYHVq)PMdAHa4vuBCefwjP1D(AadBiHw4nVH1qL9j87vBE0CA1d3gSg6e(eUqv7eAX9Xix9ZdkpijFZLkzfjYUVHdQZ2wOx3OSQQPKJpyMJ1v8suqiAE08jtLj5ajwOGAz0LDnKwM(QbL1nmLwrLTPAluswt6gUv4A7JvMLdQ1X1c2X3OMhVyXnnDdeZxZcRVotXFlB4A66FSmD)Vt114wrvxge40SFP4dpA8ZC(Kzsqo1j2m9(w3Ix3neNEoj5AhkG36wnF6S685NDLU21g1sZsLbGaZRROBrsY16XoPC29SRTh3gn7916IbwPm0UxkPb1farkC)cAYsUlBNo99iz2J5UglTmiPTlIJv1S7CzCv1Y5aESvzfNjLljMSi5PxM9OMGPe5PzvLjmavWQCaltDpppD3nCLlU5u3CxnPfmyB)BXoDZm9Q1NZxMXYt7XlwkvfrYU5PVL0Zt5gTkgNfWA1LhqYg4rP9HDYvo7yND2yXNF4OvdtrJr2DDrC(3zpUW3Y2sdO6Hld3fz(QLDGxMtBp07gW257vMuvsxO4Scq5x6wyaGBvTHfpHfNkNfNgRjXI7sDyXPJDZb4uB8l2RpZ65wCMWqFQ0qxxwCZcXDoApwwCZ70lLfxvPnyW4pKdeYzyI30HiU(aolUlxRxklUps99qn(gVIUL2rZDjvtJnyO2VFT2NZ(1AnB(XrSx)OdK(94pWXdfoeB4Zx494lmOWhzzCl6pHg7qKWz5TQrMDD7aoNZ(mNTf2NaXe8SeD4LT369yheDBFZaUh7bozHtFiNyRT4m0vL5Qp0Q25M95Cq9RxoJQMTL8HyeZz9XGEdw1UyBxnjx5HWXaVw91wan3vNl(iwC)tPnvSghNMkNgUFfe38pdeI)ZHUz(xyXTc5WwC)lT4(xbOU)1wCVjuaT4(vpT9K9P(JfRuzX9RbfdlUF9AFClUVqJFX2jCQ)lkToFXDJFXgDCGg(A7UTFTBw9Bd)A1x)w)pg5kV6TWGrM075MEWXtn3zdoNf3pdKhxbgkGf3Rb39XPdk4vThuGf3Is4u)(ewCFs7o7T4EDlUpLf3NgE5vH)(ha)9Z2MEVT4(5QRF7zS4w6ouV1wCFgOr7AwC)8KtD6BXELFfmoVWZJDlhQMhVOTx0dhdE8gv)ABQc6TPufA9s1cqV50LbSwN5(ASZClUFbU1NWfzSCiyrbJ7oE1E(2VxYNLsv2f1nXq3Jb5cbkYD1cHy7PJBG12LZCllCODrqxq1A9reOt3PfS6ZuBZiuBgbAFOwgVT7owOnJZVE26koK1Ap1gKjSaS4(O2u6ybmSF31MkCW2sSJtiyFTFcbU5T70iS4(Pjx5ltnsVthoNCLXJnqMHpxK(hXxgxDmh3f7XKwHUdJuO7yY130a62XaD(hYdNlgmsQIm14z51GXSwnh6sqlaLnZQLfuY53uuj3YMZbJGT6KYZkMlp7(Ce)5q9gYv)Y3P1SLRtZg7(3rj9JtPuyQPNOoLPDdQrH9ARr54rNayPp7L6OHXeZlmfu)jxRZw8l2nAK0RWes0dCeCu02QGTQ(5HAwlhBv6iAS4(I52ap5730wyyX9LSffwC)w5yUM1Vn83xg(7Ra)97WA0Pg3Kwd9XUWSQj2yI9hyRPFwARf1YA221CUSc91xVZRCXHt7AZR6297VLlxWoZvpFa0eFOiEPds6HX24nGBaHdmlxcScuPzjSxKxOMvTIVEdM0XbX8t(6oMuZ21)BL1gP8b1dMZ9G8Cl6L8M88jp1qzjDCaxJubdnrJTHSlyuBtvZg72)(CK)dBPnrn5)yNKFJR8WKvLi)NG85lU53K0KFZ7yBpAYxcnI2VLZ(HM8BdX4lFi(biFfGz(3H87csBXrYoMXzZEHctFu0zQ(Q12KZ12(6SMfs72BZVn53BxoBR5ydNyWSB6drLLXTGz8sWSEmYDtoHmobVFVE9gM3FeV9hGpO)(d33TT3xwVh8UTSJgFSB6oAm6T)rGGf3AU0HKMSaT9MLHA45Vvo09i9DCMzN)MSBrtp7hXBmJp3SnpBoN6PkxpZ)xqDFs6(TXpAf2AEonoPYOOk8jxry2PcljE6bMouP2Dok8CK3C5HgLp54JMkB0HjD8lThTdWGAXha3s94zSOqjzfrp8vCTzm9DXkjuu0ZGLQORx1XTgPVaMNqr4TQQfBi4m0T1KHPOMJ3osdonm)eb2M2w793y4LHPMWMuKZ5Xi9n2Bhmh3lKg25eWtRqTdwFXOKQWmEuN05dFJ6Eh6p1nK(mA64XcXEQlOtPwzkXgcjg0quSHqyhMepsDHatAh38WMnuIZysnOdLndvyt(H2bvF0MiauBBJLZ3mCAGQgQNHCAaxXMKqtc5)aQjGmSrQjKqczjbAwGZaGkiPeWSamraTBlE1PZEXUE6ikF2jxrQx1i9MwEgXPYtz3aOiW756yXBjZsC4nCFKv3Mj86SDuUt5ZENfg6nBzNfEJMW33b2HHBMJjMnMhAZShwXktngj8qDW(iiLUBw3Yh)kaNHdFMu72PHwC)H4jX08ZeVV4xyYX9oDRB1qlUVV7EnKXuU5LBwC)3SLv9fQfz1Q1Z3C)JGcQj1euwC)5B3cO3geqNV8uZes33rpvK(32eqHfAraTSlV)9pIhOEC3u88hbINZfQ)QfKIpT8KNABt8C1VsRIh3(FV)r8a1J7MINVbiEmtg7CMdDAzEZkBFApYTiEwPUXbDFK6J8Dv5ZFmiFUqc1cMkNwRKX2x3pHNQf5ZAnmE07JKqtDxvc9Nasiz(sxsE2lR6lZ532KqT5yIWIBF3tiw2KZJ8UGW46GW4sXfVqVLJBmK62MWyhMTilYZMp2wqECBCiA2Z4BzJeSg7iKo7OPr7MuBf9UFrq)NIJ6txSFVvMwAa9lUTP1v9VUfjT2EAEE2VRsydYM3bKnPtg(OHNE8rdjkUDjBkQ0IOjgDxJ)UsJ6LgFtqA0V)IZyoh)qsX320um)cTsjYmX0DzkXtTLPeT4()EFhp43c11oDKz0Z6FAZuZST1HNARhgAuRfExw4M4VtjC)2OhlWp1OzkCM5Zmt1TlH77SqRcxQHFFxM0gehFhCUyLp)aPhQyQHZUTPR1MdEqlUFS3vw0GS47cYIKbJDPXg(mZE(053UKf)(Z0ISybN174Ul13HIf6VtX99Nbcy)6zd6FYZimWCLVveW258MwiFLw7Ct3z9RCLXpxxmN2SfzmTXy9v7abAlczqWpbvc7CK7mjkrazqJcfusHsLjBwQ8ws3KLQ92yrNONNoyJ7NUXJ0RAsMVN9(obKHhe9PUmMbeg2ukEXG(B8i15tIU98IEPlhwhtx3EYbgviE0WmWONpL2tvZjiKlvcNtLPKONbv1neMruHfL9v3o8PCvNK7MF0JPE0H1hDSSURv3ivPNO9qqU(zb64s2)m4X2Zpx5HTp96BWrlSxuYuUh2thOhVn7AaJ0UTPLTtx0VFyE1173fT3)k2ckoBs)R4nJHTC1TAMU(vXk18RIzt3QxvyFekr99QGO893Z5CJFvPn4CX6NI5HZXKnfltBD(lXZU33FBo7QtcXOxSLJ1uspfUXuXoxQrLYfCECNFMVtdhnwwD8y1YBRooGBMy1Xbzj1QJhFNFMV7wirj)8BLe95Qj(9lOuTz((Cnqfak7mT(Mz7rocGga5iSPcw3ZlRO3boVSYX0V74rr9BBPTjQr5RMgEhVV6pXSIEtoXSA5CXQnNuwnhYn5asTjsAO1)hSZpWhUEsAkf8FR2EBhPrt9lt3tLpqoKwV99lVTiN2ShoEy9AliXMt1CYGbDLy75hYsSzHOEmD7FnmpaFq)(73pUvfwP25Lo(dJ4B73NFV4b1i98P3dEMq6jtLcfeX9DfEW3DWn1GzVRQkT)nVqrKQh5ku6EBxO4Dzdnb9zO)2FSVvP3Z2EuxGd)c2)OwsdV2MTqR7gEg37cKA(7kEKR62X33ZQJNA8y(c3xF4LW4Li4L(5debUL8bx290nT(FIeS64PTpP8PBzt6g0Az37z7cwBXm9xIZ6(Puef7B1EhxiVGEDBzJAoz3ys132CrOl5tSFYHxb3qDqkMa(7oGx3TcZG6mV70X)7MfqGo)mlY2Di(HV26GjFST(zQ51P1V62mkVi661uLN6HT2a1sQfMr1K5i062TcOQnINxIkpmKXm5Rr(eCmewD)GFsFEi6V2JpVf3z5JxsuqXou5Iffv4tL4Cj4zT4oBhNJ6UDCqTEzLPIjO)sJL8yUpDSmuyjnzsUkr9qU6xCNo7FIxWr9b4IOUy9FGJF9jDtiOEllUF)C2hCNX87T)G4p(QEH7ct)rqSFeChgH5HdhlsF(XF388hje9AFu0EWv0e1r0l2(UGWKtkwWeiT(fZr5TUo(tsISIyAwCYvVlS5mqXp3w1JrDXYHy8Ccs)q5mFn5DooZANvNLRgpUQPR4(rQNZmz75mpqn)DN8zixRh)17L74546VW2yhDSF61snoVVa(9fbV63p9Aa61G0Fxf7NclA)j96TWV)ATXVHdeIDDJGb3t(lX2TpOAZncPCUJqcMRxDJPDV36aRa3rbw9uUNI9uCXpqdN4Rtt(jiFn6zlYAWuUXAG9XFAJhdfj)D3PZu82apE9aCBPnkWb7YXPA3QMmapLDJbn8bmMTVsxk5O96VxNPvYCuFNZIIioERpOy1JbFGJh64E7z2D8Q))p
```
