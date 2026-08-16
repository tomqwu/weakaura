# Druid TBC — Bear, Restoration & Balance (v12)

One pack covering **Feral tank (bear)**, **Restoration** and **Balance** for TBC Anniversary
(2.4.3 / WeakAuras `internalVersion` 45, `tocversion` 20501). Built with
`tools/tbc-weakaura-creator`, 48 tables (5 sub-groups + 42 elements under one top-level
group), **zero custom code**, and locale-proof by construction: every trigger matches by
exact spell ID — never by name — so it works identically on a zhCN client. Every
spec-specific element is gated on that build's signature ability, so the HUD reshapes
itself on respec with no user action; mutually exclusive elements share screen slots.
Six of the 42 elements are the **PvP layer** and load only inside an arena or a
battleground — in PvE the pack is exactly what v3 was, minus nothing.

The whole thing hangs off one draggable top-level group anchored at screen centre `(0,-140)`;
the five sub-groups below can be dragged independently. **From v12 your state is drawn as two
ring clusters around live 3D portraits** — your health and power as concentric arcs around your
own face at `(-270, 40)`, your target's threat and health around its face at `(+270, 110)` —
which replaces the v10/v11 Diablo globes and brings back the portraits the globes had dropped.

## v12 — the globes become rings again, around a live portrait

**Two rings and a face, per unit.** v10 traded the ring clusters for Diablo globes and paid for
the number-inside-the-glass by deleting the portraits. Side by side, the rings win: an arc around
a face reads as *that unit's* state, where a vessel is a meter that happens to be near you, and a
live 3D portrait tells you what you are actually fighting — including every NPC and mob no icon
or gate in this pack could ever name.

| | outer ring (84px) | inner ring (62px) | centre (44px) |
|---|---|---|---|
| **Your cluster** at `(-270, 40)` | health | primary power — mana, rage or energy | your live portrait |
| **Target cluster** at `(+270, 110)` | **threat** | target health | its live portrait |

Both clusters are the same three sizes, which is what makes them read as a matched pair rather
than as two unrelated widgets. **There is deliberately no target power ring.** v8–v9 gave the
target a third arc for its mana, and that extra ring is exactly what made the old cluster look
busy and uneven — and a target's mana pool never changes a druid's next button press. Its aura is
not deleted (that would strand a UID): it becomes the target's **outer track**, the empty groove
the threat arc runs in, so a resto druid — who loads neither threat aura — still sees two rings
where you have two.

**The percentages hang just outside the arcs again, and the portrait is why.** A WeakAuras `model`
region cannot carry a text sub-region at all — `SubText`'s `supports()` lists texture,
progresstexture, icon, aurabar and empty, and pointedly not model — so the centre of a cluster is
a face and can never be a number. Both clusters label themselves identically: health 13pt just
under the outer ring, power 10pt below that, threat 10pt *above* the ring where it can never
collide with a health number.

**`|x| = 270` is not an eyeballed number.** The Alerts column occupies `x` `-170..-130` and the
PvP column `182..218`, and both are *dynamic groups that grow vertically*: an 84px outer ring
spans 42px either side of its centre, so at `|x| = 190` it reaches 148 and the alert stack climbs
straight into it from the second simultaneous prompt onward. At `|x| = 270` the inner edge is at
228 — the tightest symmetric position that is clear of both columns at any stack depth. The build
proves this rather than asserting it: after assembling the string it re-walks the parent chain and
asserts both cluster centres and all four rage pips.

**The rage breakpoints go back to trigonometry.** On a vessel, 20 and 70 rage were horizontal
waterlines. On a ring a threshold is a point on the circumference, placed from the inner ring's
radius as `r = 62/2 × 0.94`, `x = r·sin(2πf)`, `y = r·cos(2πf)` — which puts `f = 0` at 12 o'clock
and advances *clockwise*, the same direction the ring fills, so each pip sits exactly where the
arc will reach it: **20 rage at 72°** (upper right), **70 rage at 252°** (lower left). They are
round pips rather than lines because rotating a thin quad on a texture region rotates the *art
inside* the quad, so a straight line can never be laid along an arc. The dim + lit pair, their
colours, the pop-in when you cross, and both gates are unchanged.

**What did not change:** every trigger, every load gate, every escalation (amber under 50% health,
red under 25%, the power-type recolour, threat green → orange at 70% → red on the flip), both
threat gates and the `threatvalue <= 0 → alpha 0` guard; the buff row, alert flow, cooldown row and
PvP layer are byte-identical. **No aura was added or removed** — 48 tables before, 48 after,
`stable=40 changed=0 retained=47 missing=0 parentSame=true` against v11, so the import dialog still
offers **Update**. The two globe rims were the v8–v9 portraits and are handed straight back to
them. **What is dropped:** the v11 specular highlight, which was a glass effect for a filled
vessel and means nothing on an annulus.

Tick the **Arrangement** category when you update: the position and geometry *are* the arrangement.

## v11 — the globes move up beside you and the glass catches light

Two changes, both cosmetic, and between them they are the difference between "three meters
parked under the UI" and "the character is holding these".

**The globes flank the character now.** v10 put all three vessels on one horizontal band at
absolute `y = -262`, below everything else in the pack. That reads as a *second* status bar
bolted under the HUD: your eye leaves the character to check it and comes back. They now sit
either side of the model at eye level, with the target above and between them:

| | v10 | v11 |
|---|---|---|
| life globe | `(-150, -262)` | **`(-270, 40)`** |
| power globe | `(+150, -262)` | **`(+270, 40)`** |
| target globe | `(0, -262)` | **`(0, 110)`** |

Sizes are untouched — 72px for life and power, 44px for the target, each rim its globe + 4px.

**`|x| = 190` is not an eyeballed number, and it is the tightest arrangement that fits.** The
Alerts column sits at `x = -150` and the PvP column at `x = +150`, with icons up to 40px wide,
so those columns occupy `|x| ≤ 170`; the PvP layer also holds elements at `(200, -44)`. A 72px
vessel spans 36px either side of its centre and its rim 38px, so at `|x| = 190` the inner edge
lands at 152 and the outer at 228 — inside the gap, and clear of the PvP row in `y` as well,
since the globes now sit 84px above it. `|x| = 170` would sit *on* the icon columns and
`|x| = 210` *on* the PvP element. The build proves this rather than asserting it: after
assembling the string it re-walks the parent chain and asserts the three absolute positions,
and the same numbers are used by all seven class packs.

**The glass catches light.** A flat colour inside a circle reads as a sticker, not as liquid in
a vessel. Every globe gains one **specular highlight**: a soft, off-centre bright spot in the
upper left, 46% × 34% of the globe's diameter, offset `(-17%, +21%)` of it, white at 28% alpha —
which is the cue your eye already reads as *a curved surface catching a light source*. It is a
`subtexture` sub-region on the same `Circle_Smooth.tga` disc the globe is drawn from, so it
scales with the vessel and the small target globe gets the same read as the big pair.

Two rules that recipe obeys, both of them silent-breakage class if broken:

- **It is appended, never inserted.** Conditions address sub-regions *positionally* — `sub.N` is
  the 1-based index into `subRegions` — so inserting a sub-region ahead of a referenced index
  silently retargets that condition at the new occupant, with no error anywhere. The highlight
  goes on the end: the percentage stays `sub.1`, the highlight is `sub.2`, and the build asserts
  exactly that before it will write a string.
- **Its blend mode is `ADD`, not `BLEND`.** The percentage sits *inside* the glass and
  sub-regions draw in index order, so an appended overlay draws over the number. `ADD` can only
  brighten what is beneath it, so the number stays readable; a `BLEND` overlay at the same alpha
  would grey it out. That single constraint is the reason this is a *highlight* rather than the
  more obvious dark edge vignette, which would have to be `BLEND` and would have to be inserted
  ahead of the text.

**What did not change:** every trigger, load gate, condition, colour, spell id and region type;
the buff row, alert flow, cooldown row and PvP layer; every size in the globe layer. **No aura
was added or removed** — 48 tables before, 48 after, `stable=47 changed=0 retained=47 missing=0
parentSame=true` against v10, so the import dialog still offers **Update**. The four bear rage
marks moved with the power globe, because their coordinates were already derived from the
canonical constants rather than written down.

Tick the **Arrangement** category when you update: the position change *is* the arrangement.

## v10 — the rings become globes

**Life and power are now vessels, not arcs.** A ring encodes a value in *arc length*: you read
it by judging how far around a hoop the colour has travelled. A globe encodes it in a
**waterline**, which is the same read your eye already does on a glass of water, and it is
what Diablo has used for thirty years. Same WeakAuras region type as the rings
(`progresstexture`), one different field:

```lua
orientation = "VERTICAL"   -- WeakAuras for "Bottom to Top": the fill line rises
```

| | where | size | what it shows |
|---|---|---|---|
| **Life globe** | `x = -150` | **72px** | your health, in D2 red, `%percenthealth` **inside the glass** at 18pt |
| **Target globe** | `x = 0` | **44px** | your target's health, `%percenthealth` inside at 13pt — smaller because it is secondary, and it vanishes entirely with no target |
| **Power globe** | `x = +150` | **72px** | mana, rage or energy — whichever you are actually using — with `%percentpower` inside at 18pt |

All three sat at screen `y = -262` in v10 (v11 moves them beside the character), and each is
wrapped in a brass **rim** texture at its own size + 4px, drawn one frame strata above the fill
so the liquid reads as being *inside* glass.
The unfilled part of a globe is a near-black disc rather than nothing, which is what sells the
container: colour rising into a vessel, not a shape appearing out of the void.

**The portrait is gone, and that is what buys the numbers their place.** A WeakAuras `model`
region cannot carry a text sub-region at all — `SubText`'s `supports()` lists texture,
progresstexture, icon, aurabar and empty, and pointedly not model — which is why every ring
version had to park its percentages *outside* the arcs, where they competed with the world for
your attention. Drop the portrait and the centre of each vessel is free for the one number that
belongs there. Diablo never had a portrait either. The trade is real and worth naming: **no
live face** for you or your target.

**Threat became the target globe's rim.** It is the one readout with no natural vessel of its
own — it is not a resource, it is a relationship — so instead of inventing a fourth globe for
it, it colours the ring of glass around the target: **green** while your threat is healthy,
**orange at 70%** of the pull threshold on the caster rim, **red** on the aggro flip, with
`%threatpct` sitting just above the globe. This costs no extra element and no extra screen
space. Both rims keep their v5 not-in-arena gate, their v7 Bear-form gate and the
`threatvalue <= 0 → alpha 0` guard, and the bear rim keeps its tank-inverted meaning: green
while you are securely tanking, red the moment aggro is *lost*.

**The bear's rage breakpoints got simpler, not harder.** On a ring, 20 and 70 rage needed
trigonometry against the arc's stroke. On a vessel a threshold is a horizontal line at a fixed
height — `y = (threshold/max - 0.5) × 72` — so 20 rage is a line 22px below the centre of the
glass and 70 rage is one 14px above it, each as wide as the globe's chord at that height (58px
and 66px). The dim + lit pair, their colours, the pop-in when you cross, and both gates are
unchanged.

**What else did not change:** every trigger, every load gate, every escalation (amber under
50% health, red under 25%, the power-type recolour), the whole cooldown row, buff row, alert
flow and PvP layer. **No aura was added or removed** — 48 tables before, 48 after, every UID
stable (`changed=0, missing=0`). All thirteen tables in the layer were *recycled in place* —
eleven renamed, five given a new region type — so nothing is orphaned in your WeakAuras,
including both portraits, which became the life and power rims, and the target's mana ring,
which became the target globe's brass rim. **The one readout that ends is the target's mana** —
a fourth vessel for a number that never changes a druid's next button press.

Tick the **Arrangement** category when you update: the change *is* the arrangement.

## v9 — the orbs are one shared size

**The orbs are now one shared size across every pack.** v8 shipped the unit-orb layout to all
seven class packs, and each of them landed on its own diameters — and inside a single pack the
player cluster and the target cluster did not match each other either. Side by side that read as
uneven rather than as one HUD. v9 replaces every hand-written diameter with **one canonical set
of numbers, identical in all seven packs**, declared once at the top of `generate.lua` as named
constants (`ORB_OUTER`, `ORB_MID`, `ORB_INNER`, `PORTRAIT`, `CLUSTER_X`, `CLUSTER_Y`, `RING_TEX`)
and referenced everywhere below, so they cannot drift apart again.

| | player cluster, `x = -260` | target cluster, `x = +260` |
|---|---|---|
| outer ring, **104px** | **health** | **threat** |
| middle ring, **78px** | **primary power** | **health** |
| inner ring, **54px** | — | **mana** |
| centre, **46px** | your portrait | the target's live portrait |

Both sides therefore present the **same outer diameter** and the **same portrait**; the target
simply nests one more ring inside the same footprint. The numbers match too — health at 14pt,
`y = -60`; power at 11pt, `y = -76`; threat at 11pt, `y = +60` above the ring — so the two
clusters label themselves identically instead of at four different sizes and six different
offsets. Druid is the one pack with **two** threat rings (Bear and Caster, mutually exclusive
load gates); both are `ORB_OUTER`.

**The arcs are drawn with `Ring_20px.tga` instead of `Ring_10px.tga`.** A bundled ring texture is
256×256 and the number in its name is the stroke weight *in that space*, so the band scales with
the drawn size: the 10px art on a 104px ring is a 4px hairline that read as a wire, where the
20px art gives 8px of arc at the same diameter.

**What did not change:** every trigger, load gate, condition, colour, spell ID and region type is
byte-identical to v8, and **no aura was added, removed or reordered** — 48 tables before, 48
after, all 47 child UIDs and the top-level UID stable (`changed=0, missing=0`). The import dialog
offers a clean **Update**; as in v8, **tick the Arrangement category** for this one version, since
the change *is* the arrangement.

**The bear rage pips moved with their ring**, which is the one thing this pass could have broken
silently. The four pips at 20 and 70 rage are stand-alone `texture` regions anchored to the
screen and positioned by trigonometry on the power ring's stroke, so nothing drags them along
when that ring changes — and in v9 it both grew (64 → 78) and moved (`y` 0 → -60). Their radius
is no longer the literal `30`: it is derived as `ORB_MID / 2 × (1 - 20/256)`, the middle of the
Ring_20px band at that diameter, and their `y` now includes the cluster's own offset. Decoding
the shipped string puts all four at radius 35.74 inside a stroke spanning 32.91–39.00, at 72.07°
and 252.07° against the 72° and 252° their thresholds demand.

## v8 — the centre of the screen is now empty

Every version up to v7 parked a 172px-wide stack of health / power / threat bars directly under
your character, in the most expensive real estate on the screen — the place you are actually
trying to *watch the fight* through. v8 moves that state to where it belongs: **at the unit**.

Two compact clusters flank your character. Each is a **live 3D portrait** with the readouts
drawn as concentric **rings** around it:

| | player cluster, `x = -250` | target cluster, `x = +250` |
|---|---|---|
| outermost ring (120px) | — | **threat**, `%threatpct` above the orb |
| outer ring (96px) | **health**, `%percenthealth` under the orb | **health**, `%percenthealth` |
| inner ring (64px) | **primary power**, `%percentpower` | **mana**, `%percentpower` |
| centre (28px) | your portrait | the target's live portrait |

The target cluster **hides completely when you have no target** — portrait, rings and numbers.
That is not a condition or a load gate: the Health and Power triggers end in WeakAuras' own
hidden `UnitExistsFixed(unit)` test, so an absent target produces no state at all and every
region carrying that trigger simply is not drawn. Deselect and the right-hand side of your
screen goes quiet.

`±250` is not an eyeballed number. The Alerts column sits at `x = -150` and the PvP column at
`x = +150` with icons up to 40px wide, so they reach `|x| ≤ 170`; the widest orb reaches
`|x| ≥ 190`. Nothing overlaps, and everything between the two orbs is now free.

**One ring now does what three bars used to.** The player's power ring is *form-adaptive*: its
Power trigger deliberately omits `use_powertype`, so WeakAuras reads `UnitPowerType(unit)` and
follows you through caster → bear → cat with no gate, no respec dependency and no second aura.
The ring recolours itself from the resolved type — **blue mana**, **red rage**, **amber energy**
— so the colour names the resource without a label. v7 needed three mutually exclusive bars for
this and still showed a feral **nothing at all** outside Bear form; a cat had no resource
display in the entire pack. The trade is that the number reads `%percentpower`, i.e. a
percentage: for mana that is what you want, and for rage and energy the percentage *is* the raw
value, because both cap at 100.

**Nothing was quietly dropped.** Point by point:

- **The bear rage breakpoints survive**, as two pips sitting *on* the power ring rather than two
  lines sitting on a bar. The ring starts at 12 o'clock and fills clockwise, so 20 rage lands
  near 2 o'clock and 70 rage near 8 o'clock, each with the same dim marker plus the wider
  fully-lit twin that **pops in over 0.25s the instant you cross it**. They are still four
  separate auras, on purpose: the aurabar tick sub-region cannot be attached to a ring at all
  (its `supports()` accepts only `aurabar`), and the two sub-region types that *can* ride a ring
  would have cost the pop — a sub-region can change colour by condition but cannot carry its own
  animation, and the pop is the signal.
- **Threat keeps both role semantics and moves to the target orb**, which is where it belongs:
  it is *your* threat *on that unit*. The bear ring is green while you are securely tanking and
  turns **red the moment aggro is lost**; the caster ring is green, **orange at 70%** of the
  pull threshold and **red when you pull**. Both keep the v5 arena exclusion.
- **The out-of-combat fade survives** on the player rings (50% alpha), and now applies to the
  target rings too.

Two things are genuinely **new** rather than ported: a low-health escalation on the player
health ring (**amber under 50%, red under 25%** — the flat green bar never had one), and target
health and mana, which v7 did not draw anywhere.

Under the hood this is a **progresstexture** ring in `CLOCKWISE` orientation on WeakAuras'
bundled `Ring_10px.tga`, and a `model` region bound to the unit. Three field names in that
migration are silent no-ops if you get them wrong, and all three were checked against current
WeakAuras source rather than assumed:

- an aurabar's fill colour property is `barColor`; a progresstexture's is **`foregroundColor`**.
  A condition naming a property the region does not have is *skipped without any error*, so a
  mechanical port of the threat escalation would have produced a dead condition that still looks
  correct in the editor.
- an aurabar with `total == 0` draws **empty**; a progresstexture draws **full**. Threat reaches
  a zero total whenever your threat value is zero — post-Vanish, post-Feign, the instant before
  your first hit lands — so a naive port would slam the threat ring to a *complete circle*
  meaning "at the pull threshold" while the colour stayed green. Every threat ring therefore
  carries `threatvalue <= 0 → alpha 0`, and every health ring `maxhealth <= 0 → alpha 0`.
- current WeakAuras reads a model region's unit from **`model_fileId`**; WA 3.5.0 read
  `model_path`, and the migration bridging them is gated on `IsClassicEra()`, which is a
  *different* predicate from `IsTBC()` and therefore never runs on a 2.5.x client. Both fields
  are emitted.

**Updating from v7 — read this.** The eleven v7 Resources tables were **repurposed in place**,
not deleted: each kept its UID, so WeakAuras matches them and the import dialog offers a clean
**Update** in which each old bar simply *becomes* its replacement ring. All 45 v7 children and
the top-level UID survive (`missing=0, changed=0`), and only the two portraits are new. **Tick
the Arrangement category in the import dialog for this one version** — the entire layout has
moved, and unticking it keeps the v7 bar positions and stacks all six rings on top of each
other in the middle of the screen.

Because nothing was deleted, an Update leaves **no orphaned auras** and there is nothing to
clean up. The one case that does leave debris is importing as **new** instead of Update (or
having previously renamed/detached the group): then your old `Druid - Resources` group and its
ten bars stay behind alongside the new `Druid - Unit Orbs` group, and you should delete
`Druid - Resources` by hand — `/wa` → right-click the group → **Delete** → confirm *including
children*. If you see both a bar stack and a pair of orbs after updating, that is the case you
are in.

## v7 — Cat no longer receives the Bear HUD

The Mangle talent teaches both **Mangle (Bear)** and **Mangle (Cat)**. A Spell Known gate can
therefore identify a Feral build, but it cannot identify the form currently being played. Up
through v6 that distinction was missing: a Cat player loaded the rage bar, Lacerate, Maul and
the complete Bear cooldown row.

Every Bear-only element now ANDs its existing trigger with WeakAuras' built-in
**Stance/Form/Aura** state for form 1, the Bear/Dire Bear position on a fully trained TBC
druid. Cat form gets only the genuinely shared elements and the instance-gated PvP layer;
shifting into Bear makes the tank HUD appear immediately. No aura was added, removed or
reordered, all 45 child UIDs and the top-level UID are unchanged, and the top-level group has
been renamed to state the supported scope honestly.

## v6 — the cooldown row shows what you cannot press

**No new auras, no removed auras, no moved auras.** Every UID is identical to v5, so the import
dialog offers a clean **Update** and nothing on your screen moves.

The old cooldown row was inverted. It drew all eight icons all the time and dimmed the ones that
were down, so it was at its busiest exactly when you had the *fewest* options — and you already
know your own spellbook. What you cannot know at a glance is what is **unavailable, and for how
long**.

So the seven situational cooldowns now appear **only while they are on cooldown**, wearing the
swipe and the countdown, and disappear the instant the ability is back. The row is a dynamic
group, so the gap closes behind them:

> **Absence is the readout.** An empty row means everything is available. Two icons means
> exactly two things are down, and both are counting back to you.

The dim-while-down shading went with it. Under the new rule every icon you can see is on
cooldown *by definition*, so desaturating all of them would grey the whole row and make the
abilities harder to tell apart. Full colour plus the number reads better.

**Mangle (Bear) is the exception and keeps its always-on icon and its orange ready-glow**, for
the same reason the glow exists at all: it is the bear's every-six-seconds press, and the glow
is not a status light, it is the instruction *press this now*. An icon that hides itself while
the ability is ready can never fire that instruction — hiding the button you press most often
would trade a "press this now" signal for a "you cannot press this" one, which is the wrong
direction. It keeps its dim-while-down shading too, because it is the one icon that is still on
screen while it is down.

One small fix rides along with it: **the ready-glow now goes quiet out of combat.** Previously a
bear standing in Shattrath sat looking at a permanently lit Mangle icon, which is the fastest way
to teach yourself to ignore a glow. It is driven by a second, always-active trigger that only
reports whether you are in combat; the icon, the swipe and the tooltip are unchanged.

| Cooldown | v6 behaviour | Why |
|---|---|---|
| **Mangle (Bear)** | **always on**, dims while down, **orange glow the instant it is ready** (in combat) | 6s cooldown, "use Mangle whenever available" — the press the whole bear rotation is built around |
| Enrage | on cooldown only | a *pre-pull* rage generator that strips your armour; it was already out-of-combat gated, and absence now answers "can I open with it again" |
| Frenzied Regeneration | on cooldown only | emergency healing, and the alert flow already owns its moment (HP < 40% *and* ready). The row only needs to answer "when does it come back" |
| Swiftmend | on cooldown only | it **consumes** a Rejuvenation or Regrowth, so pressing it on sight throws away a HoT that was already healing. It is a burst/emergency button, not a rotation button |
| Nature's Swiftness | on cooldown only | a 3-minute emergency instant-cast enabler — never a loop press |
| Force of Nature | on cooldown only | a 3-minute summon you deliberately **hold**: the treants want a target that lives 30s and no AoE that kills them, so "it is up" is not "cast it" |
| Barkskin | on cooldown only | a defensive, pressed at a moment; it also breaks shapeshift in 2.4.3 (already hidden from feral) |
| Innervate | on cooldown only | a mana cooldown that already has its own prompt at < 20% mana; likewise breaks shapeshift, likewise hidden from feral |

Per spec that means a **bear** in combat sees Mangle (glowing when ready) plus a Frenzied Regen
icon only while it is down; a **resto** druid sees an empty row until they spend something, then
Swiftmend / Nature's Swiftness / Barkskin / Innervate counting back; a **moonkin** likewise for
Force of Nature / Barkskin / Innervate. Nothing else in the pack changed — the load gates,
including the PvP and shapeshift ones, are untouched.

## v5 — the CC prompt answers itself

**No new auras, no removed auras, no moved auras.** v5 is two behaviour changes on two
existing elements, both of them things v4 wrote down as *unverified and therefore not shipped*.
Both have since been settled against the WeakAuras source, so they ship now. Every UID is
identical to v4 and the import dialog offers a clean **Update**.

### CC on Me now tells you *which* break works, in colour

v4's prompt answered "something has control of you" and left the rest to you. Under a 6-second
fear you do not read an icon, and you certainly do not read text — you see a colour. So the
glow is now colour-coded by the loss-of-control **category**, and each colour is a different
instruction:

| Colour | Category | What to press |
|---|---|---|
| **Red** | Stun (`STUN`, `STUN_MECHANIC`) | **Trinket.** It is the only answer a druid owns — you cannot shift out of a stun. |
| **Purple** | Fear (`FEAR`, `FEAR_MECHANIC`) | **Trinket.** 2.4.3 gives a druid no fear break of its own; there is nothing else. |
| **Blue** | Root (`ROOT`) | **A movement answer, *not* the trinket.** Any shapeshift clears roots and snares — Travel Form, Cat, back to Bear. Spending a 2-minute trinket on a root you can shift out of for free is the single most common druid arena mistake. |
| **Green** | Confuse / Polymorph (`CONFUSE`) | **Ride it.** Any damage breaks it, your team is already breaking it, and trinketing here throws the cooldown away for nothing. |
| **Amber** | Silence / lockout (`SILENCE`, `PACIFYSILENCE`, `SCHOOL_INTERRUPT`) | **Trinket *earlier* than you otherwise would.** A Nature lockout takes Cyclone, Entangling Roots, Healing Touch, Regrowth and Innervate all at once — your whole kit is one school. Waiting out a lockout costs more than waiting out a stun. |

Anything not in that list (charm, possess, disarm, pacify) keeps the red default, which reads
correctly as "trinket food".

These are **the same five colours the mage pack uses**, deliberately. If you play both, you
learn one language, not two.

The trigger itself is unchanged and still carries **no category filter**, so it keeps catching
the one thing no aura tracker can ever see: a Kick / Counterspell **school lockout**, which is
not a debuff. The colour comes from nine conditions on the trigger's stored `controlType`, and
the prototype stores that variable whether or not the trigger filters on it.

### Threat bars no longer load in an arena

There is no threat table in an arena, so both threat bars sat there pinned and meaningless,
taking the bottom bar slot in the one place screen space matters most. They are now gated to
load **everywhere except an arena**: open world, dungeon, every raid size, and battlegrounds
(a BG has NPCs and a real threat table, so the bar keeps working there).

v4 refused to ship this and said so in writing, because WeakAuras has no "not arena" key — the
`size` load argument declares no inverse flag, so the only spelling is to list every *other*
instance type, and it was not proven what `size` is in the **open world**. If that value were
`nil` rather than a listed string, the gate would have silently unloaded the threat bars for
every questing druid: a PvE regression traded for PvP tidiness.

It has now been read out of the source. `GetInstanceTypeAndSize` ends with an explicit
`return "none", "none", nil, nil, 0` that sits *below* the `if inInstance or instanceType ~=
"none"` guard, so outdoors `size` is the literal string `"none"`, never nil. Listing `none`
keeps the bars loaded everywhere in PvE, and the gate is safe. Nothing else in the pack moved.

## v4 — PvP layer

Six new elements and one new sub-group. **Every one of them is gated on the instance type**,
so they exist only inside an arena or a battleground.

**Nothing changes in PvE.** Not one v1–v3 element was added to, removed, reordered or
re-gated: in a raid, a dungeon, the open world or a 5-man the pack loads exactly the v3 set,
pixel for pixel. The gate is WeakAuras' `size` load argument in multi mode
(`use_size = false, size = { multi = { arena = true, pvp = true } }`), the only PvP instance
keys that can ever match on TBC. Two of the six read `arena1..arena5` and are therefore
**arena-only** (`size = { multi = { arena = true } }` — those unit ids do not exist in a
battleground, where the element would be a permanently blank slot). Each child carries its own gate — a group's load condition is not a
child gate in WeakAuras — which is also what lets the dynamic groups collapse their gaps.

### New prompts, in the existing Alerts flow at `(-150, 96)`

- **CC on Me** — appears the instant anything takes control of your character, wearing that
  effect's own icon with the remaining time under it. The decision it changes is *ride it or
  spend the trinket*: a 2s Bash you sit through, a 6s Kidney Shot with your healer already
  dead you break. It uses WeakAuras' **Crowd Controlled** trigger with no category filter, so
  it also catches the one thing no aura-based tracker can ever see — a **Kick / Counterspell
  school lockout**, which is not a debuff. No combat gate: the opening Sap lands before combat.
  **v5 colour-codes the glow by category** so the colour names the answer before you read the
  icon — see [v5](#v5--the-cc-prompt-answers-itself).
- **Barkskin (Stunned)** — appears only when you are **stunned** *and* Barkskin is off
  cooldown. Barkskin's 2.4.3 tooltip reads "Can be used while stunned", which makes it the one
  button a stunned druid still has, and it is exactly the button nobody remembers at the
  bottom of a stun chain. Inverse-gated like every other Barkskin element here (v3): the spell
  cannot be cast while shapeshifted and you cannot shift out while stunned, so a feral would
  be looking at a prompt for a button that does not exist.
- **Target Immune** — appears when your current target gains a hard defensive: Divine Shield,
  Blessing of Protection, Ice Block, Cloak of Shadows, Bestial Wrath / The Beast Within. The
  matched buff supplies the icon, so you read *which* one and act: stop the burst and re-pool,
  swap, or (Bestial Wrath) do not throw the Cyclone that is about to fail. Mitigation
  cooldowns are deliberately absent — Barkskin, Shield Wall and Pain Suppression change how
  much your damage is worth, not whether pressing the button is worth a GCD. TBC's Deterrence
  is +25% parry / +25% dodge, not an immunity, so it is not here either.

### New state column — `Druid - PvP` at `(150, 96)`, growing down

A dynamic group mirroring the Alerts flow on the other side of the character. It is empty
when there is nothing to say.

- **PvP Trinket Down** — visible *only while your trinket is on cooldown*, desaturated, with
  the countdown on the swipe. Absence means ready, which is the state you want to be able to
  check without reading anything. It matches the six trinkets a druid can actually equip by
  **item id** (both Medallions, the two 2.4 all-class Medallions, and both druid Insignias),
  not by equipment slot — a slot tracker would report "trinket down" while a PvE on-use
  trinket in the other slot ticked, and that false negative is a death in the one decision
  this element exists for.
- **Enemy Trinket** *(arena only)* — one icon per opponent, counting **120 seconds** from the
  moment you see them use their trinket. The flash is worthless; the countdown is the whole
  point, because it tells you when a real Cyclone → re-Cyclone → kill chain will actually
  stick. Note what this is: an **inference**, not a read (see the caveats below).
- **CC Out** *(arena only)* — one icon per opponent carrying **your** Cyclone or **your**
  Entangling Roots (including the Nature's Grasp ones), with the time left. Both effects mean
  the same thing and it is the single most expensive druid mistake in arena: a cycloned target
  is immune to **all** damage and healing, so every point you send at it is thrown away, and
  roots break the moment they take damage. The timer is the window you just bought on the
  *other* target. Own-only — somebody else's roots are not your clock. Bash and Maim are
  deliberately **not** in this row: a stun is exactly when you should be pouring damage in, so
  putting stuns in a "stop hitting that" row would invert its meaning.

### What this is not

- **This is not diminishing-returns tracking.** There is no DR in this pack, and none is
  faked. WeakAuras ships no DR primitive on TBC — no prototype, no library — and the usual
  fake (an 18-second timer after a CC) models the reset window rather than the category, so it
  is simply wrong the moment two spells share a category. An incomplete DR tracker is worse
  than none because it gets trusted. Count your own Cyclones.
- **Enemy cooldowns cannot be read on 2.5.x**, so the Enemy Trinket countdown starts only when
  the cast is *seen*: if an opponent trinkets while you are dead, cycloned or looking
  elsewhere, nothing starts. 120s is the Medallion cooldown every level-70 arena player
  carries; a low-level battleground opponent on a 5-minute Insignia would show ready early.
- **Enemy spec is unreadable** on TBC (enemy *class* is, enemy spec is not), so nothing here
  branches on "is that a resto druid".
- **Druids get no interrupt prompt.** The pack's sibling packs get one built on "target is
  casting AND my interrupt is usable"; a druid has no castable interrupt to hang it on, and
  "can I interrupt this cast" does not exist as a filter on TBC at all — WeakAuras disables it
  on this client.
- **The Crowd Controlled trigger wants one live smoke test.** WeakAuras deleted that prototype
  on BCC in 3.5.0–5.1.x and un-deleted it in 5.2.0; a current client registers it, but the
  WeakAuras source cannot prove the 2.5.x client populates the `C_LossOfControl` API behind it.
  Get sapped and kicked in a duel once. If it turns out dead on your client, the two elements
  that use it (CC on Me, Barkskin (Stunned)) simply never appear — nothing else is affected.
- ~~**PvE furniture is not suppressed inside arena.**~~ **Fixed in v5.** The threat bars now
  carry an inverse `size` gate and do not load in an arena. v4 held this back because the
  open-world value of `size` was unverified and a wrong guess would have unloaded the bars for
  every questing druid; it is the literal string `"none"`, so enumerating the complement is
  safe. See [v5](#v5--the-cc-prompt-answers-itself).

## v3 — each spec loads only what it presses

v2 gated on *"can this spec cast it"*. The correct test is *"does this spec **press** it as
part of playing well"*, and by that test the bear inherited three elements it can never act
on. v3 fixes exactly that; **no element was added, removed or reordered**, so every UID is
identical to v2 and the import dialog still offers **Update**.

**Feral (bear) no longer sees Barkskin, Innervate or the Innervate prompt.** Both spells carry
the `Cannot be used while shapeshifted` flag in 2.4.3, and there is no auto-unshift — pressing
either as a bear means dropping bear form first, i.e. giving up the armour multiplier and the
Dire Bear health bonus mid-pull. Icy Veins' TBC feral tank guide puts it plainly: Barkskin
"takes you out of form when used, making it only usable while you are **not actively tanking**".
The Innervate prompt was the worst of the three: it fires at under 20% *mana*, and a bear's mana
neither pays for nor gates a single thing it presses, so on any long fight it sat lit in the
alert flow demanding a button that costs the tank its form. A bear's cooldown row is now Mangle,
Enrage (out of combat) and Frenzied Regeneration — three buttons, all pressable in form.

Restoration and Balance keep all three: Tree of Life form explicitly whitelists Innervate,
Nature's Swiftness, Rebirth, Swiftmend, Barkskin and the HoTs, and Innervate is the mana
decision of a caster druid's fight. Balance keeps Barkskin as a deliberate marginal call —
Moonkin Form blocks it too, so it costs a form drop, but it is the spec's only damage-reduction
cooldown and the shift-out-and-heal flow it belongs to is real, especially in PvP.

**Deliberately kept everywhere.** The **health bar** stays ungated: it is the bear's paired
state for the Frenzied Regen prompt at 40%, and for the caster specs it is the number both
Barkskin and "stop casting and heal yourself" key off. **Clearcasting** and the **OoC Missing**
nag stay gated on Omen of Clarity's own spell id (16864) rather than on a spec: the talent is
melee-proc'd and so mostly a feral pick, but TBC Balance builds do spend into it (41/0/20), and
the rule for a shared gate is the ability, not the tree — if you spent the point, the pack
shows you the buff you forgot to cast and the free cast when it lands.

**Requires WeakAuras 5.4.0+ for the inverse gate.** `not_spellknown` does not exist in older
builds; there the field is ignored and those three elements simply load for everyone again —
v2's behaviour — so nothing breaks, the bear just gets its three dead icons back.

## v2 — rotation fixes

v1 was a solid tracker collection that left three rotation lines unrendered and mis-signalled
four more. v2 fixes what an adversarial rotation review confirmed, judged against one
standard: *does this element change which button gets pressed next?*

**Bear**

- **Rage thresholds on the rage bar.** Two thin lines sit over the bar where the two spend
  decisions live — `20` (a Mangle is affordable; below it, do not spend on anything else) and
  `70` (you have room for Maul *and* the next Mangle and will still cap — dump it). Each has a
  wider, fully-lit twin that pops in the instant you cross it. v1 printed the rage number and
  nothing else.
- **Maul prompt.** Maul is off the GCD, has no cooldown and is *pure* rage-dump, so the only
  question is "am I about to waste rage". The prompt appears in the alert flow above 70 rage
  and leaves when you have spent it. (No swing timer is involved — the trigger is the rage
  value, nothing else.)
- **Demoralizing Roar** is now tracked, on the fourth bear buff slot. It is the bear's joint
  priority #1 with Faerie Fire and v1 tracked neither the debuff nor any of its six ranks. It
  is deliberately **not** own-only: any druid's roar satisfies the −240 AP debuff.
- **Mangle now glows when it is ready.** It is the every-6-seconds press, so it gets the
  orange pixel glow the moment the cooldown clears, on top of the desaturate-while-down
  readout every other cooldown icon has. v1 shipped an inert glow no condition ever lit.
- **Lacerate is desaturated below 5 stacks.** Colour coming back *is* "the stack is capped,
  stop feeding it"; v1 printed the stack count as text and never changed state at cap.
- **Enrage loads out of combat only.** It is a pre-pull rage generator that also strips your
  armour, so mid-fight it is a button the tank must not press. v1 showed it always.

**Restoration**

- **Tree of Life Missing** is a new alert. "Be in Tree of Life whenever possible" is the
  spec's priority #1, and the form blocks Healing Touch and Tranquility — so the prompt after
  an emergency shift-out is exactly the moment you need reminding to shift back. Gated on the
  41-point talent (33891) and combat-gated, so it is silent for anyone who did not take it.
- **Rejuvenation and Regrowth glow under 3s.** v1 gave both an inert glow sub-region no
  condition ever lit, so the two refreshable HoTs signalled only present/absent — no refresh
  window, and no warning that your Swiftmend fuel was about to vanish.
- **Lifebloom is desaturated below 3 stacks**, so "roll it to a triple stack" is a state, not
  a number to read.

**Balance**

- **Faerie Fire (Balance) is now own-only.** A feral druid's Faerie Fire (Feral) satisfies the
  armour debuff but supplies no Improved Faerie Fire, so v1's shared tracker went green while
  the raid was quietly missing the +3% hit that is the moonkin's priority #1.
- **Insect Swarm lost its refresh glow.** TBC Balance refreshes Insect Swarm *only while
  moving*, and WeakAuras cannot see movement without custom code, so an unconditional
  "refresh now" glow was wrong most of the time. The timer stays; the instruction is gone.

**All specs**

- **Omen of Clarity Missing is no longer combat-gated.** Omen of Clarity is a 30-minute
  out-of-combat buff that cannot even be cast while shapeshifted, so a combat gate meant the
  nag could only ever fire at the one moment you could not act on it.

Known gaps, deliberately left for a future version rather than guessed at: AoE lines (bear
Swipe, Balance Hurricane), raid-wide HoT tracking (this pack is single-target: it follows your
current friendly target), a purpose-built Cat rotation, and pre-70 levelling coverage. See
[Not covered](#not-covered).

## Rings — `Druid - Rings` at `(0, 30)`

Since **v12** this group holds two ring clusters instead of the v10–v11 globes (the v8–v9
clusters before them, and the v7 bar stack before those), drawn at the canonical ring geometry
shared by all seven class packs:

| | absolute screen position | outer ring | inner ring | portrait |
|---|---|---|---|---|
| your cluster | `(-270, 40)` | **84px** health | **62px** power | **44px** you |
| target cluster | `(+270, 110)` | **84px** threat | **62px** health | **44px** your target |

Those are **absolute** coordinates. The group itself sits at `(0, 30)` inside the top-level
group at `(0, -140)`, and WeakAuras adds every offset down the parent chain, so your cluster
carries a *local* `y` of `+150` and the target's `+220`; `generate.lua` converts absolute → local
in exactly one place and then re-walks the assembled string and asserts both centres — and all
four rage pips — before it will write a file. Twelve auras in all: five rings, one track, two
portraits, four rage pips.

`|x| = 270` is the tightest collision-free arrangement in this pack, and it is dictated by two
*vertically growing* dynamic groups: the Alerts column occupies `x` `-170..-130` and the PvP
column `182..218`. An 84px ring spans 42px either side of its centre, so at `|x| = 190` it
reaches 148 — inside the alert column as soon as two prompts stack. At `|x| = 270` its inner edge
is at 228.

Every ring is a `progresstexture` in **`CLOCKWISE`** orientation on the bundled `Ring_20px.tga`
annulus (the number is the stroke weight of the source art, so the drawn band is
`diameter × 20/256`). `startAngle 0 / endAngle 360` is a full circle; `crop_x / crop_y = 0.41` is
the **identity** value on the circular path, not "no crop" — the path expands the texture by √2 so
rotated quadrants never run off it, and `1 + 0.41` cancels that exactly. `backgroundOffset 0`
keeps the unfilled arc the same annulus as the fill instead of a halo around it. The unfilled arc
is black at 55% alpha on every ring, which is what makes a half-empty arc read as *half* rather
than as a shape that shrank.

Each portrait is a `model` region at `frameStrata 2` (so nothing draws over a face) with
`modelIsUnit` and `portraitZoom` set, and it emits the unit string in **both** `model_fileId` and
`model_path`: current WeakAuras reads the former, WA 3.5.0 read the latter, and the migration
between them is gated on `IsClassicEra()`, which a 2.5.x TBC client is not.

**Your cluster** — always loaded, for every spec and every level:

- **Health**, the 84px outer arc in green, with `%percenthealth` at 13pt just under the ring.
  It keeps the low-health escalation added in v8: **amber under 50%, red under 25%** (severe
  condition last, so it wins), plus a `maxhealth <= 0 → alpha 0` guard, because a
  progresstexture with a zero total draws a *full* ring rather than an empty one.
- **Power**, the 62px inner arc, with `%percentpower` at 10pt below the health number. Its Power
  trigger omits `use_powertype` entirely, so WeakAuras resolves the type from `UnitPowerType(unit)`
  at runtime and the ring follows every shapeshift — the trigger registers `UNIT_DISPLAYPOWER`
  unconditionally, so the switch is immediate. The resolved type is a stored conditionable
  value, which is what drives the colour, and the ring is always coloured for the resource it
  is actually reading: **blue mana** as the base (caster, tree, moonkin), **red** when the type
  resolves to rage (bear), **yellow** when it resolves to energy (cat).
- **Your portrait**, 44px, in the middle. This is the recycled v8–v9 portrait aura, back where it
  started.

Both rings and the portrait carry the extra Unit Characteristics trigger that has fed the
out-of-combat fade since v1 and drop to **50% alpha out of combat**.

**Target cluster** — the same three sizes at `(+270, 110)`, and it **self-hides entirely with no
target**, because the Health prototype's hidden `UnitExistsFixed` test produces no state for an
absent unit:

- **Health**, the 62px inner arc in the same green, `%percenthealth` at 13pt under the ring — the
  mirror of your own cluster one ring in.
- **Its portrait is a live 3D render of whatever you are fighting**, which is how the target side
  identifies NPCs and mobs the pack has no gate or icon for.
- **Threat is the outer arc.** Three auras share that ring. The plain **track** is always there
  whenever the cluster is; over it, two mutually exclusive threat rings draw when their spec gate
  passes. The **bear** ring (Feral-gated, Bear-form-gated) is tank-inverted: green while you are
  securely tanking, **red the moment aggro is lost**. The **caster** ring (Balance-gated) is
  green, **orange at 70%** of the pull threshold and **red when you pull**. `%threatpct` sits at
  10pt just *above* the ring — the one number in the layer that is above its arc, so it can never
  collide with the health number below.

Every one of those recolours is on **`foregroundColor`**, the progresstexture spelling. It is
`barColor` on an aurabar and `color` on a plain texture, and `Conditions.lua` skips a change whose
property the region does not have, silently and with no editor warning, so a mechanically ported
escalation would simply never fire.

Both threat rings carry, since **v5**, an **instance-size gate that excludes arena**
(`use_size = false, size = { multi = { none, party, ten, twenty, twentyfive, fortyman, pvp } }`
— every TBC instance type *except* `arena`). An arena has no threat table, so the ring would be
pure clutter in the one place screen space is scarcest; everywhere else, including the open
world (`size` is the string `"none"` there) and battlegrounds, it behaves as it did in v4. Both
also carry a `threatvalue <= 0 → alpha 0` guard: `threattotal` is derived from `threatvalue`, so
it is zero exactly when your threat is zero — post-Vanish, post-Feign, before your first hit —
and without the guard the ring would read as **full aggro** at exactly that moment. When either
guard fires, the track underneath shows through, which is precisely the "no threat table" state.
That track is also why a resto druid — who loads neither threat aura — still sees two rings on
the target instead of one lone arc.

Four bear-only **rage pips** sit on the power ring. A threshold on a ring is a point on the
circumference, so each is placed from the ring's own radius —
`r = 62/2 × 0.94`, `x = r·sin(2πf)`, `y = r·cos(2πf)` — which puts `f = 0` at 12 o'clock and runs
*clockwise*, the same direction the arc fills: **20 rage** (the cost of a Mangle — the reserve you
never spend below) lands at **72°**, upper right, as a 5px dim green dot, **70 rage** (where Maul
plus the next Mangle still leaves you capping) at **252°**, lower left, in dim amber. Each has a
7px opaque twin that **pops in over 0.25s when you cross its value** and fades when you drop back
under, so the crossing itself is the signal. They stay four separate auras rather than sub-regions
because the aurabar tick sub-region does not support a progresstexture at all and the two
sub-region types that do cannot carry their own animation — and the pop *is* the point. Both the
angle and the radius are derived from the canonical constants, so the pips follow the arc if those
numbers ever move. They only exist while you have rage, i.e. in bear form.

## Buffs — icon row at `(0, -16)`

40x40 timers on shared slots, each with the WA cooldown swipe plus a `%p` seconds text. The
caster specs use three slots at `x = -44 / 0 / 44`; the bear uses four at `x = -66 / -22 / 22 /
66`, both rows centred on the group, and only one spec's row ever loads.

Bears get **Lacerate** (own bleed, big centred `%s` stack count, desaturated until it hits 5
and glowing when under 5s left), the **Mangle (Bear)** debuff timer (all three ranks, uptime
awareness — the actual press lives on the cooldown row), **Faerie Fire** — matched against both
the regular and Feral rank sets and *not* own-only, because anyone's armour debuff satisfies
the bear's rule — and **Demoralizing Roar** (all six ranks, likewise not own-only), which
glows under 5s like Faerie Fire does.

Restoration gets **Lifebloom** on your friendly target (stack count plus timer, desaturated
below a triple stack and glowing in the last 2s — that glow *is* the rolling-refresh window),
plus own-only **Rejuvenation** (all 13 ranks) and **Regrowth** (all 10 ranks) HoT timers,
which glow under 3s and double as your Swiftmend fuel check.

Balance gets **Insect Swarm** (a plain uptime timer — no refresh glow, because the TBC rule is
"refresh only while moving" and no zero-custom-code trigger can see movement), **Moonfire**
(deliberately **no** expiry glow either: TBC guides want it to fully expire before you recast,
so the icon simply vanishing is the signal), and an **own-only Faerie Fire** tracker, which
glows under 5s. Own-only matters here and only here: a feral's Faerie Fire (Feral) blocks your
cast without supplying Improved Faerie Fire, and you need to see that.

## Alerts — animated prompts at `(-150, 96)`

A dynamic group that grows upward; each prompt slides in from below over 0.3s and, on expiry,
flies up 150px while fading and shrinking to 40%. The **Frenzied Regen Prompt** (bear) needs
HP < 40% *and* Frenzied Regeneration off cooldown before it appears — appearance itself is the
instruction. The **Maul Prompt** (bear) appears above 70 rage: Maul is off the GCD and has no
cooldown, so excess rage is the entire decision. **Clearcasting** lights up with a gold glow
and a 15s swipe whenever Omen of Clarity procs a free cast. **Innervate Prompt** appears at
under 20% mana with Innervate ready, for every druid *except* a feral one (v3: a bear cannot
cast Innervate in form, and its mana pays for nothing it presses). **Tree of Life Missing** nags a talented
resto druid who is in combat out of form. Those five are combat-gated; **OoC Missing** is not,
because Omen of Clarity is a 30-minute buff you can only apply *outside* combat and while not
shapeshifted — it nags in red whenever the buff is absent, and the fix is one cast.

Three more prompts share this flow **only inside an arena or battleground** — **CC on Me**
(whose glow colour names the break: red/purple = trinket, blue = shapeshift out, green = ride
it, amber = your school is locked out), **Barkskin (Stunned)** and **Target Immune**. See
[v5](#v5--the-cc-prompt-answers-itself) and [v4 — PvP layer](#v4--pvp-layer); in PvE they do
not exist.

## Cooldowns — icon row at `(0, -66)`

A horizontally-centred dynamic group of 32x32 icons; the WA cooldown text is enabled, mouseover
shows the real spell tooltip, and hidden icons collapse their gaps automatically. Since **v6**
the row shows what you **cannot** press: the seven situational cooldowns are visible *only while
they are on cooldown* and vanish when the ability returns, so an empty row means everything is
available (see [v6](#v6--the-cooldown-row-shows-what-you-cannot-press)). **Mangle** is the
exception to that rule as well as to the "quiet readout" one — it is the bear's every-6-seconds
press, so it stays on screen at all times, desaturates while down, and carries an orange pixel
glow that fires the instant it comes off cooldown (and stays dark out of combat). **Enrage** is
bear-gated *and* out-of-combat-gated: it is a
pre-pull rage generator whose armour penalty makes it a mistake mid-fight, so it simply is not
on screen once the fight starts. Restoration sees **Swiftmend**; **Nature's Swiftness** and
**Force of Nature** gate themselves on their own talent (so a talented hybrid correctly gets
them alongside another spec's row); **Barkskin** and **Innervate** show for every druid *except*
a feral one. Both carry the `Cannot be used while shapeshifted` flag in 2.4.3, so a bear must
drop form — and its armour multiplier and Dire Bear health — to press either; v3 gives them an
inverse load gate (`not_spellknown` = Mangle (Bear), 33878) so they no longer take up two slots
in a tank's cooldown row. Tree of Life whitelists both, and a moonkin can drop form for them.
Per spec the row *contains* Feral → Mangle, Enrage (out of combat), Frenzied Regen ·
Resto → Swiftmend, Nature's Swiftness, Barkskin, Innervate · Balance → Force of
Nature, Barkskin, Innervate — but from v6 on, all of those except Mangle are only *drawn* while
they are counting back down.

## Spec gating

| Gate | Spell ID | Gates |
|---|---|---|
| Feral tank — Mangle (Bear), 41 pts + Bear form 1 | 33878 | The four rage marks, bear threat rim, Lacerate, Mangle debuff, bear Faerie Fire, Demoralizing Roar, Frenzied Regen prompt, Maul prompt, Mangle / Enrage / Frenzied Regen cooldowns |
| Restoration — Swiftmend, 31 pts | 18562 | Lifebloom, Rejuvenation, Regrowth, Swiftmend cooldown |
| Restoration — Tree of Life, 41 pts | 33891 | Tree of Life Missing alert |
| Balance — Moonkin Form, 31 pts | 24858 | Caster threat rim, Insect Swarm, Moonfire, balance Faerie Fire |
| Omen of Clarity, 11 pts | 16864 | Clearcasting proc, OoC Missing alert |
| Nature's Swiftness | 17116 | Nature's Swiftness cooldown |
| Force of Nature | 33831 | Force of Nature cooldown |
| **Inverse** — *not* Mangle (Bear) | not 33878 | Barkskin cooldown, Innervate cooldown, Innervate prompt (v3: hidden from feral) |
| Barkskin | 22812 + not 33878 | Barkskin (Stunned) PvP prompt |

The last row is an inverse gate: `use_not_spellknown = true, not_spellknown = 33878`, which WA
compiles to `not WeakAuras.IsSpellKnownForLoad(33878, false)`. `use_exact_not_spellknown` is
deliberately left unset so the rank-1 id resolves through the spell *name* and matches every
rank of Mangle (Bear) — and only Mangle (Bear), since Mangle (Cat) is a different name. It
needs **WeakAuras 5.4.0+**; older builds ignore the unknown field, which just restores v2's
"loads for everyone" behaviour rather than erroring.

Combat gates on top of those: the Frenzied Regen, Maul, Clearcasting, Innervate and Tree of
Life prompts load **in** combat only, and the Enrage cooldown icon loads **out** of combat
only (WeakAuras load booleans are tri-state — `use_combat = false` means "must not be in
combat"). OoC Missing carries no combat gate at all.

Ungated by spec: the whole ring layer except the two threat rings — both clusters' health and
power arcs, the target's track and both portraits load for every druid at every level, which from
**v8** is the first time a Feral in Cat form has any resource display at all. Plus the five v4 PvP elements
that carry no talent gate — those are instead gated on the **instance type**, so in PvE they load
for nobody. `tools/spec-preview.lua` evaluates the combined level-70 exemplar profile,
combat/instance load gates, inverse gates and the Bear/Cat form state; its output is the
offline-eligible set, before live aura and cooldown state decides what is currently drawn.

Instance-type gates are a second, independent axis and run in both directions. The six PvP
elements list only the PvP instance types (`arena`, or `arena` + `pvp`), so they exist *only*
there. The two threat rings do the opposite from **v5** on: they list every TBC instance type
*except* `arena`, which is the only way to spell "not arena" — WeakAuras' `size` load argument
declares no inverse flag and no custom test, so multi mode is a plain OR over raw string
equality and the complement has to be enumerated by hand. Both threat rings keep their spec gate
on top of it (Mangle (Bear) for the bear ring, Moonkin Form for the caster ring).
All 42 element children additionally carry the `DRUID` class load gate; the five sub-groups
and the top group carry no load conditions of their own (they inherit visibility from what
they contain — the same arrangement as the field-proven rogue pack).

## Not covered

Named here so nobody assumes they were forgotten:

- **AoE.** No bear Swipe and no Balance Hurricane. Both specs have a documented AoE line; both
  need a target-count decision this pack has no way to render, and Swipe has no cooldown to
  hang a `showOnReady` glow on. It needs a design pass, not a copy of an existing element.
- **Raid-wide HoT tracking.** Lifebloom, Rejuvenation and Regrowth follow your current
  friendly target. Tracking them across every raid member needs cloned auras in a dynamic
  group, which is a different layout, not a flag.
- **Cat-form rotation.** v7 prevents the Bear HUD from leaking into Cat by form-gating all
  Bear elements (15 in v7, 14 from v8 on — the rage bar became the spec-neutral form-adaptive
  power readout and correctly lost its Bear gate). A cat gets a live yellow energy arc where
  v7 gave it nothing, but the pack still does not invent a Cat rotation: powershifting, combo
  points and the Mangle/Shred/Rip decision loop need their own reviewed design before they ship.
  **Combo points are not drawn anywhere** — neither a ring nor a globe is the right shape for
  five discrete pips, and the rogue pack's socket row is the design that should be adapted, not
  a colour change here.
- **Energy breakpoints for Cat.** The two rage pips are Bear-gated and rage-specific. Cat's
  Shred/Mangle costs would be two more pips on the same ring with their own form gate — the
  placement formula takes any fraction — but they are not here because the Cat rotation they
  would serve is not here either.
- **Levelling.** A druid without a 31/41-point talent loads the health ring plus the three
  inverse-gated pieces (Barkskin, Innervate, Innervate prompt — a levelling druid does not know
  Mangle (Bear), so the "not feral" gate passes). Pre-70 coverage is a separate gating pass.
- **Balance keeps Barkskin knowing Moonkin Form blocks it.** Pressing it costs a moonkin its
  form, so in a raid rotation it is close to dead weight; it is kept as the spec's only
  damage-reduction cooldown and because the PvP shift-out-and-heal flow it belongs to is real.
  A genuinely 50/50 call, kept rather than cut.
- **Clearcasting / OoC Missing are gated on the talent, not on a spec.** Omen of Clarity procs
  from melee attacks, so it is overwhelmingly a feral pick, but TBC Balance builds do spend into
  it (41/0/20) and a shared element gates on the ability, not on the tree. If you took the
  point you see the proc and the "you forgot to buff it" nag; if you did not, you see neither.
- **Diminishing returns (v4).** Not tracked, not approximated — see
  [v4 — PvP layer](#v4--pvp-layer). Nor is any enemy cooldown other than the trinket
  countdown, which is an inference from a cast you saw rather than a read of their cooldowns.
- **A PvP mana prompt.** The Innervate prompt still fires at under 20% mana, where arena play
  would rather see ~30%. The blocker v4 named is gone — v5 proves the inverse `size` gate is
  safe, so the PvE prompt *could* now be hidden inside arena and a 30% twin added beside it —
  but that is a rotation-design call about the right threshold, not a mechanics question, and
  it is not being smuggled in on the back of a verification fix. Two prompts for one button
  would still be worse than a threshold that is 10% late.
- **Enemy mana is not read.** WeakAuras' Power trigger does work on `arena1..arena5` on 2.5.x
  (one clone per opponent, `powertype = 0` for mana), so a per-opponent enemy mana row is
  buildable — it is simply not a *druid* element. A druid has no mana drain, no Mana Burn and
  no way to punish an empty healer beyond what the health bars already tell it; that row
  belongs to the warlock, priest, hunter and mage packs, which own the buttons it would feed.
- **Bash / Maim windows (v4).** Your stuns are not shown anywhere. They are the opposite
  instruction to the CC Out row (stun = burst now), so they need their own element and their
  own colour, not a seat in a row that means "stop hitting that".

## Importing

Copy the whole string from the code block below (GitHub's copy button on that block is the
easiest path), then in game: `/wa` → **Import** → paste. If you are updating from an earlier
version, WeakAuras matches by UID and offers **Update**; untick the **Arrangement** category
in that dialog if you have dragged the groups somewhere you like, otherwise your positions
snap back to the defaults above. Note that v2 moves the four bear buff icons onto a four-slot
row, so a bear who unticks Arrangement will keep v1's three-slot spacing and see Demoralizing
Roar land on top of Faerie Fire — tick it once for that upgrade, then drag the group back.
v3 changes load conditions only, so it is a clean Update over v2 with no layout consequences —
but a bear on **WeakAuras older than 5.4.0** will still see Barkskin and Innervate, because the
inverse gate that hides them is a field those builds do not know about. v4 adds one new
sub-group (`Druid - PvP`) and six new auras and touches nothing that already existed, so it is
a clean Update over v3 too: every pre-v4 UID is unchanged, and the new group arrives at
`(150, 96)` where you can drag it wherever your arena UI has room. **v5 adds and removes
nothing at all** — it changes conditions on one aura and load settings on two — so it is the
cleanest Update in the pack's history: no layout consequences, and Arrangement can stay
unticked. **v6 likewise adds and removes nothing**: it changes how eight cooldown icons decide
whether to be on screen, so it is another clean Update with Arrangement left unticked — the row
simply starts out shorter, and fills up as you spend things. **v7 is another gating-only Update**:
all existing UIDs remain stable, and Bear elements now disappear when the player shifts to Cat.

**v8 through v12 are the versions where you should tick Arrangement.** v8 is still a clean
Update — every v7 UID survives, because the eleven Resources tables were repurposed in place
rather than deleted and re-created — but the entire resource layout moved from a centre bar
stack to two orbs at `x = ±250`, and with Arrangement unticked WeakAuras keeps the old
coordinates and stacks all six rings on top of each other in the middle of the screen. **v9 adds
and removes nothing at all** — it is purely the orb geometry and the ring texture — but for
exactly that reason Arrangement is the *only* category that carries it: untick it and you keep
the v8 sizes and positions and see none of the change. **v10 is the same story, larger**: the
rings become globes, the clusters move to `x = ±150` and every size changes, so unticking
Arrangement leaves you with v9's ring geometry wearing v10's colours. **v11 adds and removes
nothing at all** — it moves the three globes to `(±190, 40)` and `(0, 110)` and appends one
highlight sub-region to each — so, exactly like v9, Arrangement is the *only* category that
carries the position change: untick it and the globes stay on v10's band under the HUD (you
still get the highlight, which travels with the display data). **v12 is the largest of them
and also adds and removes nothing**: the globes become ring clusters, both cluster positions and
every size change, and the two rims become portraits again — untick Arrangement and you keep
v11's globe geometry wearing v12's region types, which is not a layout anyone wants. Tick it
once, then drag `Druid - Rings` wherever you want it.

**What to delete after updating: normally nothing.** Because no aura was removed, an Update
replaces each old region with its replacement in place and leaves no orphans — including the two
globe rims, which go back to being the player and target portraits, and the target globe's brass
rim, which becomes the target's outer track. WeakAuras never deletes auras it does not recognise,
though, so if you import as **new** rather than Update — or if you had previously renamed or
dragged the old group out of the pack — the older group survives alongside the new one. The
symptom is obvious: you will see *both* the old layout and the new one. In that case delete the
leftover group by hand: `/wa` → right-click the stale group (**`Druid - Resources`** from v7,
**`Druid - Unit Orbs`** from v8–v9, **`Druid - Globes`** from v10–v11) → **Delete**, confirming
that it deletes the children too.

One warning about the editor: selecting a group in `/wa` force-shows **every** aura with
fake data — both threat rings, all three specs' buff rows and every rage pip at once, all with
identical placeholder timers, and the rings sitting at a fake 100%. That is the documented
WeakAuras preview illusion, not a bug. Judge this pack in combat, not in the preview.

## Regenerating

```bash
cd tools/tbc-weakaura-creator/scripts && ./setup.sh   # once: fetches LibDeflate + LibSerialize
cd ../../../tbc/druid && lua5.1 generate.lua          # rewrites all-specs.txt in place
```

`generate.lua` is the single source of truth — never hand-edit `all-specs.txt`. The script
seeds `math.randomseed(20260812)` and draws UIDs in a fixed construction order (top group,
the four sub-groups, then the ring layer → Buffs → Alerts → Cooldowns, then the v2 block, the
v4 block and the v8/v10/v12 block at the bottom of the file), which is what makes a re-import offer
*Update* instead of duplicating the pack. Keep that seed and never reorder or remove an existing
element's construction; new auras append their constructor calls at the end and are
re-parented into the right group there — which is why the v2, v4 and v8 additions are built last
and not next to their siblings. v3 added no constructors at all — it only set load fields on
three existing elements — so the uid stream is untouched, and **v5 likewise adds no
constructors** (nine conditions on one aura, a load gate on two), neither does **v6** (a
trigger flag and the conditions on the eight cooldown icons, plus one extra trigger on Mangle),
and **v7** only appends a form-state trigger to the 15 existing Bear elements.

**v8 is the first version that changes what an existing constructor builds**, and the rule it
follows is worth stating because the rest of the repo will need it. `W.assertUidContinuity`
fails the build if *any* previously shipped UID disappears, and rightly so: a deleted aura's UID
is gone forever and the in-game Update flow cannot reconcile it. So the eleven v7 Resources
tables were not deleted and re-created — each constructor still draws **the same UID at the same
position in the seeded stream**, and only the region type, id, geometry and triggers changed:

| uid slot | v7 | v8 |
|---|---|---|
| 2 | `Druid - Resources` (group) | `Druid - Unit Orbs` (group) |
| 6 | `Druid - Health` (aurabar) | `Druid - Player Health` (progresstexture) |
| 7 | `Druid - Rage` (aurabar) | `Druid - Player Power` (progresstexture) |
| 8 | `Druid - Mana (Resto)` (aurabar) | `Druid - Target Health` (progresstexture) |
| 9 | `Druid - Mana (Balance)` (aurabar) | `Druid - Target Mana` (progresstexture) |
| 10 | `Druid - Threat (Bear)` (aurabar) | `Druid - Threat (Bear)` (progresstexture) |
| 11 | `Druid - Threat (Caster)` (aurabar) | `Druid - Threat (Caster)` (progresstexture) |
| 33–36 | `Druid - Rage Line …` ×4 | `Druid - Rage Tick …` ×4 |
| new ×2 | — | `Druid - Player/Target Portrait` (model) |

**v10 recycles nine tables the same way**, and adds and removes nothing:

| uid slot | v9 | v10 |
|---|---|---|
| 2 | `Druid - Unit Orbs` (group) | `Druid - Globes` (group) |
| 6 | `Druid - Player Health` (ring) | `Druid - Life Globe` (vessel) |
| 7 | `Druid - Player Power` (ring) | `Druid - Power Globe` (vessel) |
| 8 | `Druid - Target Health` (ring) | `Druid - Target Globe` (vessel) |
| 9 | `Druid - Target Mana` (ring) | `Druid - Target Globe Rim` (texture) |
| 10 | `Druid - Threat (Bear)` (ring) | `Druid - Threat (Bear)` (rim texture) |
| 11 | `Druid - Threat (Caster)` (ring) | `Druid - Threat (Caster)` (rim texture) |
| 33–36 | `Druid - Rage Tick …` ×4 (pips) | `Druid - Rage Mark …` ×4 (lines) |
| last 2 | `Druid - Player/Target Portrait` (model) | `Druid - Life/Power Globe Rim` (texture) |

**v12 recycles seven tables the same way**, and again adds and removes nothing — including both
portraits, which are handed back the two uids they held in v8–v9:

| uid slot | v11 | v12 |
|---|---|---|
| 2 | `Druid - Globes` (group) | `Druid - Rings` (group) |
| 6 | `Druid - Life Globe` (vessel) | `Druid - Player Health Ring` (84px arc) |
| 7 | `Druid - Power Globe` (vessel) | `Druid - Player Power Ring` (62px arc) |
| 8 | `Druid - Target Globe` (vessel) | `Druid - Target Health Ring` (62px arc) |
| 9 | `Druid - Target Globe Rim` (texture) | `Druid - Target Ring Track` (84px texture) |
| 10 | `Druid - Threat (Bear)` (rim texture) | `Druid - Threat (Bear)` (84px arc) |
| 11 | `Druid - Threat (Caster)` (rim texture) | `Druid - Threat (Caster)` (84px arc) |
| 33–36 | `Druid - Rage Mark …` ×4 (lines) | `Druid - Rage Mark …` ×4 (round pips) |
| last 2 | `Druid - Life/Power Globe Rim` (texture) | `Druid - Player/Target Portrait` (model) |

Construction order is UID order and is fixed; **display** order (which controls frame level, +4
per child in `controlledChildren` order) is set separately by the `adopt()` calls, which is why
the five arcs are adopted first, the target's track before the two threat rings that draw over
it, the rage pips after the power ring they mark, and the two portraits last — on top of
`frameStrata 2`, so nothing ever draws over a face.

The script round-trip verifies with `W.verify` before writing and reports `W.uidContinuity`
against the previously shipped `all-specs.txt` (v4 reported `stable=38 changed=0
parentSame=true` against v3; v5–v7 report `stable=45 changed=0 parentSame=true`; **v8 reports
`stable=36 changed=0 parentSame=true` with `missing=0` and `retained=45`** — the 36 is lower
only because eleven surviving auras were *renamed*, and `stable` counts ids that appear in both
strings. `changed=0` and `missing=0` are the numbers that matter: no id changed UID and no UID
was lost. **v9 renames nothing, so it reports the full `stable=47 changed=0 retained=47
missing=0 parentSame=true`**; **v10 renames eleven, so it reports `stable=36 changed=0
retained=47 missing=0 parentSame=true`** — same shape as v8, same conclusion; **v11 renames
nothing either, so it is back to the full `stable=47 changed=0 retained=47 missing=0
parentSame=true`**; **v12 renames seven, so it reports `stable=40 changed=0 retained=47
missing=0 parentSame=true`**). A re-run with no source change reproduces the file byte for byte.

Since **v10** the script also proves the layout, not just the encoding: after assembling, it
re-walks the parent chain summing every `xOffset`/`yOffset` exactly as WeakAuras does, and from
**v12** asserts that every member of your cluster lands at `(-270, 40)`, every member of the
target's at `(+270, 110)`, and that each rage pip lands at its computed point on the arc. A group
offset edited later, or a coordinate written locally instead of converted, fails the build instead
of quietly sliding the HUD. **v12 replaces v11's highlight proof with three of its own**, because
the failure modes moved with the shape:

- **the breakpoint proof** measures each rage pip back from the cluster centre and asserts *both*
  polar components — the angle within a degree of `360 × f` measured clockwise from 12 o'clock,
  and the radius inside the drawn annulus — so a rounding error or a changed ring diameter cannot
  push a pip off its band unnoticed;
- **the cluster proof** asserts every ring's region type, `CLOCKWISE` orientation, canonical
  diameter, ring texture, `0.41` crop and that its percentage is still `sub.1` — a stray
  `VERTICAL` here would silently draw a filled disc instead of an arc;
- **the portrait proof** asserts that both `model_fileId` *and* `model_path` carry the unit
  string, since emitting only the latter is a silent no-op on a 2.5.x client.

## Import string (v12)

```
!WA:2!T3xd4XrX59ZOZgSfqWs4padeoKXgzcXCFQtNlKYDNo9T0DAVt2yd162725UDT2B317UNKoLqiiieLVlIesc5BvcjMqiT6PLN00M0w3escn9FNQN8q3N2MwQsAcjnnnXnTp9FEAt6mZU79LoDsww(dCHNhgT3SZm7oZ7V3FVVZ8oZAWHAnZN6oN9MxmnBMX5uLvIilkR2VdhoI7W1b8R0AgzjDvzrrixeEbrovO0lQS7UuliW58n6mUiBrOQZEHSI68ozeKYPC91CV4YtItP3Qu1sYQMdQx)QzDpsMotQIFPu2rPBXRcz1D2EyiR6(v2vTzhHvthIVX1zFdg2CqNdXQooorkNiuzN17ofevUXvQgohuqV8RD11IEVDTSERQUkBL3WQ)yFJLslRYbvdBnARSTWIctpnRkNZKYYI6ckQtflBwnOoiTclEWwx52mBPKHJGBnsx)oCYa10Lvz1fKLCUpNHzfzLYatB2Y8QfnBG7EEvyoCjswubYKtvUGY8MLiHW0WnVGGuwz1802O5fmVHPOhaaowKTGoVSAmfYT1AongeKvixZyXbnJoy00zv1BoDwbjbn(MdJ)JEZZORkKlhuvB49PAD5tewN80zlOY65uKunfOOOaN2UB1v4c4kLwHoUndn)(40AEjTcPHtG73jkKnRWulmwKqjsowIKHysw6wXvH4BXKiE0bh80f0GrNc)ELWSfsXiXMhQ188CW04wG05v7n6GX7E0bNRGK1RvZlWjOD8cs4EZeqpSIIkTWsVoP59hsMd(SxM1WvuUCqLwsCIcyXHZUlik68W8c6WtzExZX6TohRKG5GzhOxF3NcYQbtOJfF505Vc0EcljlbxKRGPiBmYyIQgepOYPndPOK3s0bdNNvqQBuqCfqhe9BGUl0DJ)7nxBoZPbfZgxwqspDKOdNmktBcClwcIIvB0on(EqvjwXdHFm4h49Tqwv8Gc(fIvN1XPXGfSSTBswKhC6eryIgD451LZmHz53s8D4b3Clmrpjp6adkhDWJFygTmSIqhZJfbmuuLMnOPpjC)3X8KoJGjAjSOmlxZly(yOVOO7z2dMglOuhRiW8VtbqT8t22cSChVawPLBi2PAQ8peKAcTdUTIggDpkBNdQXQtg5GeDgcowIJFbnYlpCk8nGPQSmDlJb9MLHrdRwOdMbkXfIOl)i7ef((wsrvoNkutlHCb1mWB)gVSMq)MO7b1kke6gBgDdnpJQSovkbyyfv4zDGgS)9XKHhMz8UrTT5zMGvvGnTiCgbPiY5tZQZmbRybiOnzL2U77wndpM3aQT79HogL)Cg8ZdlS1lIo6(q3hUfCGU)fXzKbdJ5P0FOJ1MFx4A36DHgJuT(DeFtUoqh(jv3TduQtNTuxIQFwQzqS4Q6XFLvLuNGKQ72JzkU(O0LQXC5zNY(H2k5z22DD3M1eGl3rr9V7z3PsR64H1X04z5KN8ETOIMJMhjrzB7TQ3(9UxLTvrfkZGSKzU2q1WHgnzmLRLMjMBrMORK5WcC68HdH)5PP3aRud5Oz(qlAIEoI5lGOJtrlabFiKTi6EMNkLOiGWdhB4OO9OIrMKYmpTGzSnI5W8vpl2iMY26wvyANJuGLJOh4mzsfxL6xJzsgowvDUX4GzWA1IJPOIVGOzaQA4X6TdSinVjXQdhwLvzMdBDXILE0uwOyJMCW(goQ14vvAhk7FvErOIFkVbtwrzzvZHJjWVtyOyQYpic1(nyn2zl8u27Q04MzME4c5tdvtZdfYXRFsuNeISAjJEtRo9u6mye)yfj4pFUr3eUvAgDZnJC2SY2WA(HS0XPQ88kTKUKoTL2SsG(iKxzzZaV)qCCXK0U)ddzhpeX2X9peKtG9(TkP29ti7gZJlLPoGEowu3yAR5P2LOQ7a0qhAo8tCSmISAAPsRJ5VK03jt(cyRSnZqZDFP1eiLLPlMr7Rl07ENO3xQWytrz2j6D3Cyn8Gj5c0TCS9HA7jWDY9H2p62zO2GsB68coRBd1EZZqEqe7zPqVb0DGoqZO7e5c5U5kRh6Xu2(O4I4mcplXqkuvaJMZOz1eOhVM6I8G8I89Sxw68cQQYQ81o(jiXJ25PT5Z0nhuMrgZHJnPQ18CyKHehXsgt4bJoCxuZVm2KBlPLxwwNpUvTtnpLSSBbvnD(fSAJmIck8OUqrpTvJta1Kguz7rgm0qXtgl8GHImqOU6QVK9DimWUSW0c6D6Y5uIzGam87FMmY5vipzES1lKdu6(Pew(jPDsjV80PduehmtsOdoPslLzbTe)O3bQNfModV6W6DW37rX0YseZxq(5ODfY7z6(gorFDfDbzvbSeJ2XNlYGXImWH7lrutC6uw40RVzvA1GC8ZEqumako1afAKMqmLmgHsWJsMcnkp6qa0HP2tq37YnHGocaDuQDdkX7MXu1)wykwtleM8TuBdeo3YCZke)KjA4OJ5OYIshyc4V8WJB)vZQJEo0XUIQRb1maoPtssngbMbBeG(SW2aCxFBaioacEABIEAH37Er5O86iEKa64OXrIpekV4Mqs4EUmsbdYpbs9v6aPH0rtauAFL4COTwf8zOhanjAkur00O3mUPERPuU1gxvZ8qZGEWDGEBaL7SXLE5m4Oh(bw3CBOhz50AO3op6rXGrc9dAwcRd6DMc9UOehVN9HEVO3NjVc69tZ63UomkOhJHolPvIjO6YI(aRgJb6dYJEcm5a6dH(WnJ(iONe9rbOpwk0hNh9jOk0Opj6tH(0a08Vss0VdvdCtenqcyH2bP4SG(jkGON6bqFgQUMCU0ro6Xf9CVXsI(S8Oph6KONb95rpBjni0xOcDNVFjDNV2vVo0DU9ZeDhuMv2FgkwgLTUOxh1f9waGbWvbkFlyq6Bnf6bVbmGd9qyO3fJqi0CO9HnYrMS5fim0MrPFLrRcYeCKJetJfMWt0rxziZTqbl2WKkhwQxxe98Bi9om6dJ7MV8eh4jiV(Bg9WNmTPVL8RnXazuapuTtvlBK0HQVmU3tG04XcImLm4C5muFsXdwy49tDscuVNfA)qtOgVRJ2v009JH)kTGNvAgvOoCSstcz9JZ2yuHWIiSSEJwTg)azyZHnNxZ71RCGQmvTGoDLDOtWAv0Wp1EnlRsg9sMQuUJLzBOuHQNHHk5gYBtnOClnOrkzlQARFvsEuhVVlx)QmdsTNr4zE4tEULD5rXWAQdRehC5TqZuy(s0CjlKY4sYtkLQky)8LVXwEKdrH)tWOGD3UykpktOKAgC3tVyEwPuE0HsPMxFsSv4IzfMaID(MEDk0btzQu)02kRZBoyq8lgRzFaZ3GY5LIOet05FmLTzTmFje0lq1nOA2lx9pmzug)A7G0RWvlHozXXUZUX5ENKzrqidSCyNuYuv0mNfCFxHLhSE8xYVlVMMppPfxypDnz84sHvdumW5EZNhSSFLLqBOJ1waQk0B6UlTsd4xZoSxOHkDP8RwJtO1OyI(twndU)P2gC)Zwb9k0PAOAd6p)8Tgb6RvLQa6Rxn6h9cBHD3MGE03if6BMc9TsHEXuO)IuOVTjUE4kX1O)skCg9)Rmcg9xTXa12ck9pdSRQWwjtlnAUogCGy9RVYylNuycP5OQGpFf2l)9P2lFohvzYCrIksPzLKQEwArL0Zq)1M6vOfRRcf(n4pYw)G6Azz3m97NGBXdd74xSv84WxMaKjJdd286xM)vavjU)Yk31AFrfIiOMreowc68J9uALfikC4HCS2grgSvul3X1q00(su)g6zbpT3vHyb186ECwQuJOY(Wxj6pe7fXeeW1x32rI3)YDN4fSPtBg9ux5zSyc9sBaIghwtY0EgaLfkFNTCUsOG(BQZaBZOwE2wRCGnB7kjehC04dxSRn2b2FG9q1sMZuKSmTS6YQy6X5kH8tzpQZq)zBECDoz4F5AgoAOsrw0Estw9eSR(3TkjacXkOtgU)UP14vfKgFg7qneM0UujqDKq4wb9DPxsQA4SSCq0l7bxdArwtIRRSw9a35MCs(E905qjduwCDnN5IRRzffxO)wIbS)Ussg0Fp2S25CLchnuFWEK8FGosI(hrVm6FATnQJwcx2V3AFa)QQv)GlZaSfI4P7ibIEwoG7DH8YCqX(0mD86AqBZdRIapDzWSwamvAjibVz3LIq8QpJTnK104ukwbq9OYYyN2cFFNY8DjRGiSpo0TnV5pvy15r3MzpzmnSV2fb4XPk(9uMZY7iRTz3bk1nNrdEIcqSNKoQWBRTZJ8hEyzjiANm0hb66ULYpRcAJGbsL)T60avwUjiUJYV(PrJSz0a7Ysqmnaf4klnfZR2k3Iv0FvNc7j5tDek0ONfIM1h3Hs4BqyUCeaLY2OLRlbnsuy7tkRm)g2IVuXq(0v((uemRx0pGcVq)q(QM6)RCMbR2ywiGFeblH(X4w7Fb)))ecAb9VUoXiOFATGd0)gMT4NHrfOFoblGona9VF2k7r)IQK6Vo0)ba9FwPuUWror4rIf7Ohpxq6Sd(V24KQO))a0Vem7nxzNUPNrzB2HFEqShwKvtP8E2WAFu0fnA8L3kfDZcvfGo7wqfAVFoAPuJiKfMweRMRS9sH1gE8ctaLO20k)0yireysD(YLJem6m45iojRA(YLBizY2xqfQCt1)XBU)j2F59GsxW8YQSIctt2ekmYSQu4AlaS09AjY1DCvaSCDxORBZeH6UnNPdwKJf8vbBh2coERO9U7wDzJfjqtcy8nMQo4r)Ooqb266hIyANO0(bimEuxZYecbDqTO0Zchjw7Xu9oGy8EKq95GG2hWbXy2qnt0eNDpZlKrwYme534Lr6z7aqUXIzKLf5KNukXKc4PeCk7Fs2Ie8lxJ9PT66mE9gWNFSOskMKyXu26U1moO2BiMH6E0bx3gTdFFNECiujejaE6meScpf)Jnv2F)V0I5eLNSBvtw8IMECfMKh)PWU71JOvWR5NJKxcZD7a5YbPBIJDSa5A7a(sltPnkLd69Sd3QzOOj5qFIj5fYmUeutZXm0FINk1IPlORllfZmkB02AqbCrAH(8cBUlEM9APtKUT9QvVLUgu9kxtFlQ3SOFWBXCg0LAnL1DRDQ(gE4OmJfowYKXgc9G7YSHXEZmhU7AUvqw08pJjBosyTdzScgpDtbyLJDGRT2cjJbX4huh2)ISSuoqp8iNzEWSZWemlQvdWLJDkDtKvx1DWWXc1XiThIN4nh()cpnMvHU2mZydDtvIi9)wz72zsMmi2QizFEWLIUGTJyaU1ue97pRn9nrHBpMEXzPBwto38YYHOawXsGMwtNnZ4AyI2k3ehPW8SFPsLzj4ukcM(YNuip0QSLiLXfMSLCoG7dqGoeYOioMDpgGTuPwRbyRPmanVYkOheRG2zGoXPb7SdAAadWvTs6PgGR(Sqf1a86kRvEWxYaCnMQIgGTXBaAb))T6WaCT7WaSDGbyhuXMbyNy1kdWUmaxh(hxVby3gGBOfdWnYVbaSna3e6bVPsWzdWR3aCZ4NTtA7zaUf8GxBOoma7zDakXWgliPiXB9j4U3(JMjQ32Z73csAa2hfqAaUTYqX)hdq7B04UMpJrhwwUEgpbc4c))DgoyaFbdhmORamE6iyqVmU7Ot)byChWBqx0u30upmEc4YT7xd9SrIEEJyWt(o2FUEg4qC(s6RrGNF15aWZUlrizaU96qczaEdNrWRHRX7Go82acNgcc6FJdeCXILwkKAxBOqQENz5qQVDtK1T849QYjQ0L(a90im1V(CaM62RatTFmMY7kAe0eZ5zJdZ93IPZ8f2Tl)Dg2TpVUc7XvqAI7WE7WtGWDg0TRWb70lMSRtFKR85MXJFpbds4960nn1Z6fWEPkRv9GyetEq(9ZpKNSh5WAjBacZaCzNhOT8UXbHEgmkXBhKKojjbXjyOcoXn2mPFcOXFhKKaKKoPqgxVgKz1HmhbdzoCrPc8Q5Dpox7neYaE1fK54H97pGlgp(W(rrt9tt7GMgG61K3v1V7)VggXkORl3YftH0E7pQOq7N4eneK00fCFPRac8IygcpUjj(ij(jjeseQrhpeMepeJoE9ss8rs8tPoOEC3zNVg6ynGoigDAFkpU6k(GhEQjeAi4WXftGJNXaGnr42aG9Ta)E6ZaGfw4Hd8KXXs(GVMWFni8jMpgi(j84jlRFUesnu4VPxfmrPkMh(XBlyWW4jy7pCqFy3vXgri(weK6BrWoFTPBVroD73oggLiwC1j18n6Hh1DdHrB(ckmYvysmqAB04OMEYkIVHkuAAbihjejqjNXvLZROxomjreHSQzy10jN82R1o3yYrCoKGg5iXu(m02NKeuDcwDODJCTLJStbr7mlDaAtQcHoLZsJHtPgRuGyIeXPSKZHGLJduyw1X1gxqYz7j0lGFuC7VIJ7R5jNTV85libPrGHOS8NrJvOzmxy0uyZaV6Z2GUSqgzXc5LsqAmh0TgCAZL5MHvuihgvQQPZsoxO04couLH8t18CFctrdnuFoMblmSAhA8)6aTZtXvuInVqg6rWfDDBoSMSQo6GZLtvW8WUDLZqUKezG2y6IruiVG(vs2FIdsUIFPmYs4hVKE3Sz0LvtZeQR(gnrAvwoHcApYvHcS15WYsZOu8i70gwUK9GyirOQU28zlikAUZMszhkOJaib9PfXZIGnHH6MM76zbF(sONwoj)H4In7TIP2aRgZMewm9cLiLyBZNRsBxatsjI06XtP0cDZ4u5bwlLYoR(aSzV1DA9Ukhf4zBHrNC6XdtoTHMncwtaQkKjbV8KXKsTyv)Cbn6FyGSCfjVdZr3SRdZMhULJCq0EyO)06uCD9rSctGt7Jpfg9sU)(vAL8CWqgzvi5quHfRWulQIFlty3Ck7OADtO5I7VyPDElPq0nniPRygZA6(rI2BsPCTKRHKd8CLfFdII)2ltXBrH3cwYD9mXfMckwjrV5(BLK6Js4JniKY0yaHZ3KTFTqp)OM0ZZtpNE0Jt7ANQMCgUP7BbScIIZYBWpYV1UF20cIc6fhlng4RwqJNqS)EmDom7a3B)hQJ(yhVNPwoXoFzID1vKyV697ZcAIy5CAzDD580nqLx79(tTK9ZUT5ONJAAua1iBNLC860ynI2t6mf0WnqAAbkshAjpbZFpL5VF5wDJokGchOzNQ1ICBT1PaZrpQYKwDg7wL8SxeFTKMi5GYIVLsl23lPD24xSfTWwMzKI220wl161BwBUxs4bcS2c69k7PrLWqdWNSkNnONvqRTN1kbcVa4YHfM2a8PAiwo0lxJBhwOZ0t4EKogkTYOd5VHUDOTgrNgGNc9YgGpZkJjnapTb4Zs6zFodWjlH8maptLOodWN3gUzaEwdWxG0sgGNZa8fXTLb43f3J)9Qb0SMmeuvSaWyMo8Ti2IAgEOMj18IMuZwotSEWt3(Ahpv6iwE2WQTgC6SkPVb4tR0ETeyu29XKihpjm3OArSpaIPzXgHkdv2FKdLns8Jl4vozdjY0VubQu1gbvzhvDspl7eWPQmFYw21ANIspa1vD8qtHEoWkVVrNflWFmdWCgGhh)U8bmaFqsRyaEITCIFkzi4dz6pGb4dBa(i4s8KZvYzzdWhRgB4gGpoUiFIuN1Wu6anjjGJZAtVM(RijRx5H(zPQ)nXOlfitj0wXDbNnoEFnehlsm)iruJlJIJDVr6VqKKUCn6XBikUWLKO4ZlBN51pFyhBe8HRrlIv5Dhbl12k5uhhzYnJLhpb0kWr8WGXc0HsC3AmnehnXLKgo96TZGUna)bgGN)CNjssb8w95u48bUiZQzRSACHUkekNvuilSc0X0673ZX7wlBW93yBLt(Qa0XA3x8jOCfwybBJrpMY2IOkpjNZiL(0UraiBi(JVQ(pDbWH8SwNUVgUpU3h6BMIH8bxdpXNA8iFWq(6oEVt0z(rvAOh5tDrm05jlFOQT(G(r)MJDSWjso6Wv9XdXrnFProD59xy1F)PmaFl0XwKu)XgkAKEdnCFrAydza(lQUUH7oAiML9HljG5AluVkSiPc1)HTk1unsSH7E0erxwD8zrMrwlV6(oYelwYLvlVw(FvVNuI(gm6WrIU8Hc7PQwVow8qr6R7JSEQQY2seP3yXgCS(iFk4ygnEYvP6NXHFyLDd(i3yDDdEg7f1THEbxPNm4EIb4fjTXly6hZPnxqOsa1noVAOs6sFGCo7w9QNUmRIjrY7exGVs1ojBa(QehB(6edz4XlBQgdW3yz8m5hyAgVrJ5ruMVHMOkEjLjkRLl6j90HppHD7YJlsINW(9hmid(QaDY4ZVpVDY41Thp(yCh0FaFmE95lG7ZYDsZL0wYQh8sr4ezoIWi9dvA8UQz6xfaVCzaoX89gJPVJgB4KHge107Y(4dfPRsh6OQYkQKkBoO9r8HMv1leVD0XO3kXKcz1ZdL4SdPgn3HPtI920mVn5qDyhilZ2twndn4xMLZosz07ztjw1tP0Yfuk4w3XMQi6wgG38wpBdTLb4T4W6JDJb4TssEWLheldWBZo(vgGhQCKRmaZGUUnBaEy0bnapYvAaE7TX0Lb4rXx9o4naZAaENgG3fngugG3D5Gpv(OCzhPendW7T2apb2qI7uep5ZazgwoCip0znT6Kosl3M28KLymK4KSf1STTH5SRNTTfTopBMNzT1SbUgDuepFpLE)1qSXFgB6l06lU6)ysyES(khNYKtAKPHNiuH9Zk3ExnKtAjmNe9um(uH2WIXE5VrkZllzduR57EsT7d5FwnhCsZqXVYhSs(kdv)TUED5AjZvaV07OfeD75RlenTjv3AhBUbG5wNBiK1csR8IeWFMH2ma)uluw7q)dlLjA4dX34ne037CakR5ZwHVb4NxYF7dwxbUb4JEPIWEDrRuwqNFKEJxCYUY1dFpnuq)9VGlOhUHc6ENP(XxOKBjNTXx4cRiCz777keHduSd)tfGFYIzd1qr4)8f5IWW)91veQ06YDI8v3ctChDffMAjInHimRUMAJNYXp4ICH5JCB1vyE6A84)v3csCNCffKhTJjhVyxJ0tqzFnuq(dVixqUcRyLb47CrUSJUUswHHLUGsnmqS1i98jCIJQmu(jshntdLEVYf5sVviS7gG)4lLLEJ4sAu)9YoE3UGnu69Johk9iR3s4UID4HrnDWY7n44te3zsY3BmOUZUWtmP8w3nQemFr77TufB)xYhQS6TtEnaV5REdBTo8Kmw8ZFR2XcvmCuNL5GBJz)1o0j48F8JmI3y3BNRXfx9lD5nr((boJGompDJSknG5AT)4PqpMY1vNnXAF4sUFZjfyP4HhQpfDlTA1gPq7jm56YlDXZB00M2I0iLBzJM2CTnHrtxoUIgnDf1uTh)vwFv7hTUQwFFX1x1(mNrvd5XdRuXLr3K68fDZ6AjIBQjtQMopuSUGde)OUCxSHun)QZHunR9ihq294pMQ1)YrTBgFE8e0dLG4L94MSRVu2oDxx7K8Vlyotuitgi5F3mq7d3ZxO02TUpUuRYhk8Z32m6Bnke3z9KGs9QK4458vusO3gkb)1LKG9Dbuc(s0fEnIOmEAqPm56)LKpheD2HhVEdg2TRo8e2V7G(jj0ttThsIx6HHmiJ7Gbd4IM6MM6HM6LM6JM6NEOADTGcuL8rnK8VjiZWMnlmJoKZ840HhdxISXZfKGXnluQxfF(6U(1yOKoRGyrhxFixEhb6EyxncI1u5d0)goeR18TY1k3SV(Q(m0DueMm6YnaVhI3t4xwRpzBKpxBF7TCX9NRnSZil7t0wNzuMkAiHEdLR368jARvngVhW)bC16eB6b(Fp
```
