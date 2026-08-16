# Druid TBC — Bear, Restoration & Balance (v10)

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
the five sub-groups below can be dragged independently. **From v10 your health and power are
two Diablo-style globes** — vessels that fill bottom-to-top like liquid — flanking your
character at `x = ±300`, with a smaller target globe between them and the percentage inside
each one.

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

All three sit at screen `y = -262`, and each is wrapped in a brass **rim** texture at its own
size + 6px, drawn one frame strata above the fill so the liquid reads as being *inside* glass.
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
height — `y = (threshold/max - 0.5) × 72` — so 20 rage is a line 21.6px below the centre of the
glass and 70 rage is one 23px above it, each as wide as the globe's chord at that height (93px
and 106px). The dim + lit pair, their colours, the pop-in when you cross, and both gates are
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

## Globes — `Druid - Globes` at `(0, 30)`

Since **v10** this group holds three vessels instead of the v8–v9 ring clusters (and the v7 bar
stack before them), drawn at the canonical globe geometry shared by all seven class packs:

| | absolute screen position | size | rim |
|---|---|---|---|
| life globe | `(-300, -150)` | **72px** | 122px |
| target globe | `(0, -262)` | **44px** | 82px |
| power globe | `(+300, -150)` | **72px** | 122px |

Those are **absolute** coordinates. The group itself sits at `(0, 30)` inside the top-level
group at `(0, -140)`, and WeakAuras adds every offset down the parent chain, so each globe
carries a *local* `y` of `-40`; `generate.lua` converts absolute → local in exactly one place
and then re-walks the assembled string and asserts the three positions before it will write a
file. Twelve auras in all: three globes, five rims, four rage marks.

Every globe is a `progresstexture` in **`VERTICAL`** orientation — WeakAuras' name for "Bottom
to Top" — on the bundled `Circle_Smooth.tga` disc, so the shape stays constant and the fill line
rises. (`VERTICAL_INVERSE` would drain it from the top as you take damage, which looks
deliberate and is wrong.) Every rim is a plain `texture` region on `Circle_Smooth_Border.tga` at
`frameStrata 2`, carrying its globe's trigger and alpha guards so the two behave as one object.

**Player globes** — always loaded, for every spec and every level:

- **Life**, 72px in D2 red at `x = -150`, with `%percenthealth` **inside the glass** at 18pt.
  It keeps the low-health escalation added in v8: **amber under 50%, red under 25%** (severe
  condition last, so it wins), plus a `maxhealth <= 0 → alpha 0` guard, because a
  progresstexture with a zero total draws a *full* vessel rather than an empty one.
- **Power**, 72px at `x = +150`, with `%percentpower` inside at 18pt. Its Power trigger omits
  `use_powertype` entirely, so WeakAuras resolves the type from `UnitPowerType(unit)` at runtime
  and the globe follows every shapeshift — the trigger registers `UNIT_DISPLAYPOWER`
  unconditionally, so the switch is immediate. The resolved type is a stored conditionable
  value, which is what drives the colour, and the globe is always coloured for the resource it
  is actually reading: **blue mana** as the base (caster, tree, moonkin), **red** when the type
  resolves to rage (bear), **yellow** when it resolves to energy (cat).
- **Two brass rims**, 122px, one per globe. These are the recycled portrait auras.

Both player globes and both rims carry the extra Unit Characteristics trigger that has fed the
out-of-combat fade since v1 and drop to **50% alpha out of combat**.

**Target globe** — 44px between them at `x = 0`, and it **self-hides entirely with no target**,
because the Health prototype's hidden `UnitExistsFixed` test produces no state for an absent
unit:

- **Health**, in the same D2 red, `%percenthealth` inside at 13pt. Half the size of yours, so it
  reads as secondary at a glance without needing a label.
- **Its rim is the threat readout.** Three auras share that ring of glass. The plain brass rim
  is always there whenever the globe is; over it, two mutually exclusive threat rims draw when
  their spec gate passes. The **bear** rim (Feral-gated, Bear-form-gated) is tank-inverted:
  green while you are securely tanking, **red the moment aggro is lost**. The **caster** rim
  (Balance-gated) is green, **orange at 70%** of the pull threshold and **red when you pull**.
  `%threatpct` sits at 11pt just above the globe — the one number in the layer outside its
  glass, because it belongs to the rim and not to the liquid.

On a texture region the conditionable tint property is **`color`**, not the progresstexture's
`foregroundColor` and not the aurabar's `barColor`; `Conditions.lua` skips a change whose
property the region does not have, silently and with no editor warning, so a mechanically ported
escalation would simply never fire.

Both threat rims carry, since **v5**, an **instance-size gate that excludes arena**
(`use_size = false, size = { multi = { none, party, ten, twenty, twentyfive, fortyman, pvp } }`
— every TBC instance type *except* `arena`). An arena has no threat table, so the rim would be
pure clutter in the one place screen space is scarcest; everywhere else, including the open
world (`size` is the string `"none"` there) and battlegrounds, it behaves as it did in v4. Both
also carry a `threatvalue <= 0 → alpha 0` guard: `threattotal` is derived from `threatvalue`, so
it is zero exactly when your threat is zero — post-Vanish, post-Feign, before your first hit —
and without the guard the rim would read as **full aggro** at exactly that moment. When either
guard fires, the brass rim underneath shows through, which is precisely the "no threat table"
state. That base rim is also why a resto druid — who loads neither threat aura — still gets a
rimmed target globe instead of a bare disc.

Four bear-only **rage marks** lie across the power globe. A threshold on a vessel is a
horizontal line at a fixed height, `y = (threshold/max - 0.5) × 72`, as wide as the globe's
chord there, so the arithmetic is two lines of code where the ring needed trigonometry:
**20 rage** (the cost of a Mangle — the reserve you never spend below) is a 93px line 35px below
the centre of the glass in dim green, **70 rage** (where Maul plus the next Mangle still leaves
you capping) is a 106px line 23px above it in dim amber. Each has a thicker, opaque twin that
**pops in over 0.25s when you cross its value** and fades when you drop back under, so the
crossing itself is the signal. They stay four separate auras rather than sub-regions because the
aurabar tick sub-region does not support a progresstexture at all and the two sub-region types
that do cannot carry their own animation — and the pop *is* the point. Both coordinates and the
width are derived from the canonical constants, so the marks follow the glass if those numbers
ever move. They only exist while you have rage, i.e. in bear form.

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

Ungated by spec: the whole globe layer except the two threat rims — all three globes and all
three plain rims load for every druid at every level, which from **v8** is the first time a
Feral in Cat form has any resource display at all. Plus the five v4 PvP elements
that carry no talent gate — those are instead gated on the **instance type**, so in PvE they load
for nobody. `tools/spec-preview.lua` evaluates the combined level-70 exemplar profile,
combat/instance load gates, inverse gates and the Bear/Cat form state; its output is the
offline-eligible set, before live aura and cooldown state decides what is currently drawn.

Instance-type gates are a second, independent axis and run in both directions. The six PvP
elements list only the PvP instance types (`arena`, or `arena` + `pvp`), so they exist *only*
there. The two threat rims do the opposite from **v5** on: they list every TBC instance type
*except* `arena`, which is the only way to spell "not arena" — WeakAuras' `size` load argument
declares no inverse flag and no custom test, so multi mode is a plain OR over raw string
equality and the complement has to be enumerated by hand. Both rims keep their spec gate on
top of it (Mangle (Bear) for the bear rim, Moonkin Form for the caster rim).
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
  power readout and correctly lost its Bear gate). A cat gets a live yellow energy globe where
  v7 gave it nothing, but the pack still does not invent a Cat rotation: powershifting, combo
  points and the Mangle/Shred/Rip decision loop need their own reviewed design before they ship.
  **Combo points are not drawn anywhere** — neither a ring nor a globe is the right shape for
  five discrete pips, and the rogue pack's socket row is the design that should be adapted, not
  a colour change here.
- **Energy breakpoints for Cat.** The two rage marks are Bear-gated and rage-specific. Cat's
  Shred/Mangle costs would be two more lines across the same globe with their own form gate —
  trivial to place now that a threshold is just a height — but they are not here because the Cat
  rotation they would serve is not here either.
- **Levelling.** A druid without a 31/41-point talent loads the health globe plus the three
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

**v8, v9 and v10 are the versions where you should tick Arrangement.** v8 is still a clean
Update — every v7 UID survives, because the eleven Resources tables were repurposed in place
rather than deleted and re-created — but the entire resource layout moved from a centre bar
stack to two orbs at `x = ±250`, and with Arrangement unticked WeakAuras keeps the old
coordinates and stacks all six rings on top of each other in the middle of the screen. **v9 adds
and removes nothing at all** — it is purely the orb geometry and the ring texture — but for
exactly that reason Arrangement is the *only* category that carries it: untick it and you keep
the v8 sizes and positions and see none of the change. **v10 is the same story, larger**: the
rings become globes, the clusters move from `x = ±260` to `x = ±300` and every size changes, so
unticking Arrangement leaves you with v9's ring geometry wearing v10's colours. Tick it once,
then drag `Druid - Globes` wherever you want it.

**What to delete after updating: normally nothing.** Because no aura was removed, an Update
replaces each old region with its replacement in place and leaves no orphans — including the
two portraits, which become the life and power rims, and the target's mana ring, which becomes
the target globe's brass rim. WeakAuras never deletes auras it does not recognise, though, so if
you import as **new** rather than Update — or if you had previously renamed or dragged the old
group out of the pack — the older group survives alongside the new one. The symptom is obvious:
you will see *both* the old layout and the new one. In that case delete the leftover group by
hand: `/wa` → right-click the stale group (**`Druid - Resources`** from v7, **`Druid - Unit
Orbs`** from v8–v9) → **Delete**, confirming that it deletes the children too.

One warning about the editor: selecting a group in `/wa` force-shows **every** aura with
fake data — both threat rims, all three specs' buff rows and every rage mark at once, all with
identical placeholder timers, and the globes sitting at a fake 100%. That is the documented
WeakAuras preview illusion, not a bug. Judge this pack in combat, not in the preview.

## Regenerating

```bash
cd tools/tbc-weakaura-creator/scripts && ./setup.sh   # once: fetches LibDeflate + LibSerialize
cd ../../../tbc/druid && lua5.1 generate.lua          # rewrites all-specs.txt in place
```

`generate.lua` is the single source of truth — never hand-edit `all-specs.txt`. The script
seeds `math.randomseed(20260812)` and draws UIDs in a fixed construction order (top group,
the four sub-groups, then the globe layer → Buffs → Alerts → Cooldowns, then the v2 block, the
v4 block and the v8/v10 block at the bottom of the file), which is what makes a re-import offer
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

Construction order is UID order and is fixed; **display** order (which controls frame level, +4
per child in `controlledChildren` order) is set separately by the `adopt()` calls, which is why
the three vessels are adopted first, the target's brass rim before the two threat rims that
colour it, and the life and power rims last.

The script round-trip verifies with `W.verify` before writing and reports `W.uidContinuity`
against the previously shipped `all-specs.txt` (v4 reported `stable=38 changed=0
parentSame=true` against v3; v5–v7 report `stable=45 changed=0 parentSame=true`; **v8 reports
`stable=36 changed=0 parentSame=true` with `missing=0` and `retained=45`** — the 36 is lower
only because eleven surviving auras were *renamed*, and `stable` counts ids that appear in both
strings. `changed=0` and `missing=0` are the numbers that matter: no id changed UID and no UID
was lost. **v9 renames nothing, so it reports the full `stable=47 changed=0 retained=47
missing=0 parentSame=true`**; **v10 renames eleven, so it reports `stable=36 changed=0
retained=47 missing=0 parentSame=true`** — same shape as v8, same conclusion). A re-run with no
source change reproduces the file byte for byte.

Since **v10** the script also proves the layout, not just the encoding: after assembling, it
re-walks the parent chain summing every `xOffset`/`yOffset` exactly as WeakAuras does, and
asserts that the three globes land at `(-300, -150)`, `(0, -262)` and `(+300, -150)` and that
each rage mark sits at its computed height. A group offset edited later, or a coordinate written
locally instead of converted, fails the build instead of quietly sliding the HUD.

## Import string (v10)

```
!WA:2!T31cWTXX5zFcw2sW2js0sY2k2XWuwYuUoY4niuItnai4djscWdGswYUI4aWcCN4H7oD3bsc1M4y6hr5DfDItSZJMY8Q1Xnzg2mUUPEABuBtBDsA(dtQZnnpAmBNoonP5btt700M0U7E3HxeeIIKYsw1EgV8WE7U3T7)3)3))U)7EI5qDK7JENN6MNplxUXZRkRetwuw9aoC4iPd37lGsh5KL0vLffr5JXliMxfj9CkD0JAzH8UEDUguOaYvFIYzrkxRDEjLNePAL52SZmnNArKUvUxFRY1fRqjLTx9o8QioDxDffXPUxLRR5SJXPPJW3OAlXYve5Aio1XXjsffrk7Ov3PSOYnUC1a3x0v2zRRf9E7yPDA67811Ioo5glKvwnpsnQ14QYwIkkCYtYPM3vAzzrDbf1PsuOGgsNjRchEyvx52mBP0rJHBnsp)oCXI00Lv50fKLCThxr5e5KYHYA2Y8QvmBG7AwvurCjsxrbXwuvUSYSMLiLWjrBCobPcYQLOTHZ5mVHPqMHHXX8CL15LvtOqUTMZSyXDbHIov5YrZiiRMoNQUZSfeKe04Dgf)hDNtRRkuSisvB49OAD5JfvN805kRY59mKunfKOOqETD2H7OLXvkRIixfK6008hiVMZf0kNfnbUFNQCHcctn3yXIKk9yPshHnD1BLufHVfBQKXhCWflRHIpf(9kLzlKHvIResZ5S5rzXTaPZR2F8bt27OdotzjRxlNZLxq74LLW9MjqE5efv2kh960M3Fi58ON6YSgUINViszRPorzS4WvVLffDDyEbD0zmVR5y9MNHtsWCWmi8A79mionukDS4ROo)vc7kQKSeA(8LnfzJrgtu1q4b18Attkk5Te2F0sCcs9cHXva2p86H3aCx4)EZnNZmAiXcjLfK0Zgl(WPJZ2Pq(fSrBuCM2I4BIuL4epe(5GFI37CfuXJk43ioDohlIrlyHBVKSip5SPIXgp(WZQlNBcZYVPKB3lU9MBI(sF0doOC8bp(Hz1YXjICmlwgWsHvA2OMbKWdaoML0BemHlrfL5Y7CoZhd9nfU7tT)SyjL6yvym)7umWwf38CC5pEzSsB(H4MAd1(HG0gGT)o3mmmC3kBlpsJtNm0HikneGSuE(50iV8OPW3aLP(Y0Rmg1BwgwnSEHoZ0iP8ri6Yp0oGO37ckQYfvrAAPKlRMdD734LTb4xhUBOdicCJoHxJZPvL1PIjgworfEohWGhypS54r5gVxOZno9eCQcCzfrtliftUuwoD2j4elJy6uwPZ76UuZXJ5nqA7CpWXOuLtJFEyPTEf4O7bUxCl4aUV5XzKdJJ5rCI68WX6mGBCT74naJrQ2bCK8YDVVGbiv3JdiZIfQ2LOkOvBgGdxvVbQVQK6eMuDpEntX1hYwTgZuIBk7hAhKNzNVH7YSMm4YDu4a78u7qPdD8W6yA8C5LN8ES4IMHMhjrzl7UH3(DVBLTuxfQrHSGzU2y1OrgnDcLRLMjMCrMOSK7Wc515Jgb)ZfP3aRvJYtZ8bM3e9CeRxGZqVpbEiuOcC3Zsfsuaq0HtmCCyxQyGjPmZslyoBZvomFZlGnxPSLEvfoPRrkZLNOg4kDAf3v7wJzsgowd9TXYJYH1QfhtrfFbrXGPHrh7xU5P5njwB4WQCktFyRlMV6JMYcLy00doWWXTgUAq5qzVNLxeQ0NYBWwquww1C4yc87egjMP2dIqTVBRHoBzNYUplnUzMzhUCPSi1S8iHI86Ng6MqK1mz0B8StpLnhgWpwfc8ZVh4MWTIt4MDcUCQSfSIFelvCQgpVYwZwvL2szw51paH7Qaxo09fjF(esA33HrCJhHy74(gcLxG7(SkP29ftqnNiASuLKL153NEroOxmZ1SuBtunEgyOdnd(PoworonTmz1Xuys67GTuzSLwNS0C3twnbszz7HD0b6bEh7aE3zIInhLBhW7Wzun8ak5c4wo2EGoFmChDpWEHBNLAhkB)M6s7bUnOlNttEqeBAzGFn4oG95eUtWn4Xz91doTY2gfxexX45igtrQcyeDonRMaE0MQl4f8b(FQllBjbvvzv(MhdfK4HDSOnLMU5aZ0YyACSzvnNZGrhs5jwZyJoy8H7HAcM1MFBbn6axsRANzwkFzVcQA68Zz1g5efu4HEG4lA14eGnPbv2wSbJmuY0jIoyKyhmsp9mq6boegCxtGAb)wSwoMKdeKH7a1LgIK2DGPZjxsH8IWJnOboGS0sgIsK5oSzQdiMd2jjeeNwzR14fTqeWBf6BUtMJxDy9G89FumrTeXGgIFgApJ8ANDGHtnqpXNtwvalaPJdtFO4SPhiwKbnrUtzHCVbNQ0AHYZFQ9djyGKylw53mmYga2QwNGu8q6mWO8WHyGdtnWa3ZsTPahHbok1qcLjEJyU7FdmNRPjdtcyQXccjCnYAfINJeDE4yoQVOuw(qlplp8zGJDLnwb6amD4KM6jqJ1yASDb6tdBwWtRnla5za0I2C)0cV7DdfPu9apiahhgheFaOediH76YGcgZFcq9fdcAGombJsxlhneTXQJIdEtWKWuqf4KWVjUPEZzuU12xvZ8GPH7F3WBHr5oBFPxkPo8GRE6o4Hwkth8W8WJGbJe2i4uesi4TLbE7uEK35EG3f8UnPzG3dnRF7wqWaNMLoXHLJyOXYcV3Zgbc8(4HhdZvaVF4d4eEC4jGpid8HYaFyE4Jq1VHFh4Jc)UmWSVyA4Jr1aVClnqp(i4nFMyiIci8Xpn8jO6AYfZg7Ohx079Kin8P4HFp43hEs4tdpvvvi4pOoLhM1KUZTFUO7a5wEhCOizOWkh7wMbdFBas(BHHOV5mW9)AWWn4bWaVh8ix8bGGzG9GT4rMl9fie0gHSV4OuaZrSamHh5ij04qP8gF0LhWCleOIniP(rLw1dHNEDPZHXEyu3S1Mhbpb3DaNWdYL10xt(vMuGmiGhP2HQL9s6i1Nxj6Q0RMXIsNJf15gIkrSnsbfKr3RGnxv7PbPgccqNZGFhe9Lpohr3PV566qtOMSNJ2t8ShaRpPSv8eFZPI0rJvDAoREK76JojwOJrpNfP(N0wAoRoDXEiorHf97Z5ceVUQLxgIuMakoTYwSwwOuc6LP9uQOFP4JOeJeyXPdI4dxTu6Kvt5oXtKS0Dseqe0IL3DKsMPUMPj4d8mMOgBsMZSBZxmLC6vTvQChlX6u1c1ktt1tpjytpPClTPrQAnSr7V1tG1IPeuR(nyi((VocfhMR7b5G)ySkWJGvbOdfehJ5Tq(uvcQGGUmoJljpPuMgurMT2n20dDiQQYeSky30RKXRYekzMg)wOxPeNugV6iPmZQpj2CDLcctGWoTtVodS)mvvUGpVPAf8N0SsXvcplvHWlvvOBQLRg0h6RNjtMukQAOkHi2x(txhG)ySnlxrSNOnPc8I7dJVF2QLzoZHy6QfSk1egUEnb4pJQaa)51W8WxyLdoH)kBlGFXLbLb)1Tfeb)nld(a(BBayapxJyb4lTjUDAcbGVCg4RKb(7YaF1maEi4RTcLYBcE2FcZvwVynDwPrlgCWdM4a6RzX6(R5cEvTc4yDgIkXEJ3v1vPbJTcAVin1jNHVEt(R3eoa(gTv67I2zjJbuIVNUoZyFoQzSpJJgSKnprVR6ufY0kdGNPk7g8xyYMb)LTKgd)kuv9bNgMM6pGPTfYanwSS9FOtQO5gnDcyqNR(rASuQE49Nxz)RCRKMRh7y0LIT6u)jqDS7gy0obLSz681WGetKFFZ5TREkNiSMppJZrDyHOF9GBKIBNGGBFoBR7VNLAJ)lzZB5e(4LpNfsW3CDqW4WAcCyiN3gfjp1MoFjsaJwmW6S5b2cDPKsCWrtoCLEwtdSpCZdS)l2dvlyo3nYsPYPlRIvdNPkUpJ9Ool9ND6195LH)LQx4OTQefGDLLSEgy3VVlvYQ8NOSoz4(7MvJxvqA8PTJhqus7sLaTqcHBf47sVKu1Of4YJGxWlUg0ISIexxvZIlpfNCs((929qPdvtCDLRd6bvfxW3Iqu(TRkzGVdM(88UsHJ2Qpyps(pshjHVh8cWcRSrD4Fcx2)5v(a(v38aE(ChKRCmV9glu810a(dt8nqCZR8jhDBRJtoY2bc8CIEC6R(5Y0HwEB5xd8SVOb1u(JBAkpEb)5puk)dIkwC9YdT1RjOKFfo0)5E5Xq)RQ5H(Yh5erhjrIJE8IHFjEO)Z26vE0AO)MbMQ79aydpPYwQg0DSRcKzRxBlcyf2(EOr)TwK77LdPkGC1RGkYE7dS16JCFwrz5s12ycSOJxEcKeLEU2tJLSCZtQZxRCKyFMdpfZj5ulvRCdjtcxUks5MA9J3mE97v5gSVDpOsYQCIcNuqQOlwzov4vdBHmlGoGRf2gMq7QzWYXRdU(nsgr2PPB7yjgwgTK5hqWx3kS7D2HBBWfbRrqxVUmTaGfaccH28QxoBs5nVDpjkEuxZInKW0rjh7BUJKOReQ(oOyY(KGbCqaYh0bHxEiNeLPtTRzfYjlzgr2B8Yi9STZqUX85KLfZJN0yQjfW(2Eg7FscjpFRxKasxN1NVq(dGfvsjKeXZC0ArIAACqT)iSd17OdUQT)e9ExCCesjcjyr6SeScVTY6boWZpFrr5j7vfDIYiPCvmDEikjp(ZG9CPprRyLYpdjVuMbxNC5G0nnW2NJCTDagPLP6wWXb9E2H3Zm0NKCOpX08c5gxcPP5yA6pXZjy(SL11LLsygrhABnOaUiBL(8mxGj(tDT0zf25U1wblmk9TOvtj8(VfZPdwT1uw1T2zgy4HJZow0ePtNyOQZZeByEgC31CNhmV5Fgt2kgXw)mxTyqBLJDGsT2XcJHW4hiO9VilLHd4bh5CZy8oIsWSyn0FgS174YjR0MNWrtej4iDfHN4xc()IEsmPcDjiM2g5MPk573xzB2zsMutpcAKDvq(mu(4rmy2AgI69NI3s1KOVTlt)rSunBkNBEj5q0)QBnkYQPZLBCnmrB9BzGmyE2NPAzwanLIGPxPPfkHSkBvszCHjBaK95zFeKdHlkMJtTl4NxVol8FKb(pxELZ9Jvo7ou340WDhKMgc(Vwovu4xSguoH)7AQJ7)5H)htvq4xYd)kE4)1HbZLTDdmiXGzduHLbJdSUKbZLBWSr8pUcdMR0GztB1GzZ8RdOzdgNW9FtvXWgmxLbZvJF2xdT9myEvzmyE1qqdMTSkqIyWIjouK4S5e5VNdepxCFDvkGfo0G5APOqdMTvd)9VAWS91BWMZZniHLPQN0BOqUX)F3rdhYF4OHd7oeR3GHd7J1tWUdeI1tiFHDtt9qt9Y6nKBpEEfmZ6cM51HHmLcU3I9DWdL3FA)TdY8dopaz2zvUhdMRRf8ngmx)khunCtobe0xB4wAJO)aRpI(lwmLsbsx36kqQ)Pxcq6lVbYsSD8(vZlQ0J(b7RDiPF45bK0TxhsAhyKKVL1kNjsZ76es7FatD5pQh3b6oQh)(Ch1R7W0epr9f0BOODh2J7OH72hMyRB)KR87H1BaVHdt4462dn17QdMEPidvlaweJAi(9YpK3ch5WAPBhU6F7LagkFRt4MNedn8fKK0njjmobJpWjEW2bdqqkbcsscrs6MItC)k4K2GtocgNC4ksL5vl5z88D1oCYp6Lr4KJhnqGqUz96h7Dennanninne1xiFNfxO))r4cRqlUedtSLZ67aXff66eNODaJF8fwVIRtS)CyQaVEij(jjbije2cQjfVekdVetk(8rs8tscq5iO(o3D3VcIOnicIfLUMYR7Eso4HNAcH2bi(jx0aiEsdMBYG51AWCZgmUmyUfdMonyWJq3QbZUny2ZRiWBJaNyA4GjpHxVf4cKpLu7e4)0l2NKtDZC(4DgoCu8uIdenSFStNydeeNfctDwiC3VYeKxxMG8dJXoPsKuDsn)JE4r90oSZIxqXoUJscprNJMe2WtuxOhursNuaLNe9cKKRKQYLu0RfbJyIio1CCA6csfRDAntihZ1qcAKtgrTtt5assi1j40r2nY1wlOlLfTZS6rPmTkc5sUG5bJ0UXQgJKyXCjl5AiuTq0eLtDCTXfKC1vk9Y4hv(9w3b)08iHoqPsLLq0GJqur(cuveZWHWQPWLdDnR14HmxozXYLKsrAmh0OVL1CfOz5efkIXKQA6CKJiinACd5SUatPAEearzOrTzahtJfgwTZ24PXzzhNjFfjUsc5ONgt463yunzvDy)ZuuvW8ypDvttUKSO9DY2dROqjb9RISD7gKCf)c5KLWpEj9E5YPlRMLnspdmAQSQC5fkR9qxneAZZGLLMbq4H2HnQS6zdmIisvxB2cLffn3JPzSJsZryiXJHez5vDCGWqDt7A9nNF)P0ZkNM)q5tCQBf(5mTNotclJ(IvPI460V7QXU2KkIiQE0mkBLUFpQ)GlLrzhnEqMS3Di4z9xnCRNARS6QC5gpk5qNz2iy1aKQqUu8YtMqkZ8n8Z50O)HfXLVc5Dyg6gxCyUsOnDK9d7IL(tRtYZneZA97DzFeAWqxY93RshKNdgViRIihKgSmfLzEv8Bzk7Mtz7nQyImx195RUlkjfIUZ(iDfZGdt3Yl0EtgLRLCnICWxRV4Rpe73EnIDc3n8RWKmxbBsHPqI1tWBU5kn3YXuI(FzgQjactVjh)kHu(rmjLNLEmTOhOYvobn5y8soaXdGvmuCvBZJr(T29XLvquqVYyzXaE1YA8qhgmvmD(RWbVNdCOGdWnEFtTu(CEBnhdMXwwc9g3njZPjIfXzL11Llr3Eo(S3zjntYFQTmd9K0sdmNgwysoTD0W)b7kBUYA4gilTavOdSKNG5VNY83VqhEGJYqrc0SZ0rL8BUJPyMHEyvjT602Tk5zpp(AjnrYzLeFlLTAFV02zJFXM3cwzMrgABtBTmRk3vTjCjREFOvwqOxw)kQb)myENn4CH1rAIUTFAn47cGdgwyzdM3vBXWr(En4Krvuz2j8msWHYQm6qTlYngmzwHOsdMtdVGbZmlpw0G5rnyEVKE27ZG5XQI4myE)1J2my(a2WmdMh3G5jiTKbZh0G5dHBldMpm(f6J0ey5St83WI1JXkb9pp28zoEKMjv88MuXwEoSkWr3(kfh5X(qXT6zXwbUw2Gu3G5DR0vZewuI8XKiNafmxOAfSTEXSCy7n1Gi7n2Hkel5Xf8jNUTexCxsarAypfQS9gogF1m2FM6ZNS7pT2aw0dlBdN9VmWNHz53cINclvEZgm3VbZBb)2(agmttAfdMhCtN4hr6)pKPDFdMh2G5rWL4TotvpInyEBnzR2G5TJlY7iZAdEshIPh3thRrtSMUKijRx)z0yHg)nX4kfatjWw2nwMn(DpTf)ksmZir0CRHEtCpXoq5yPD7E0J3w0B2l9qVVKSJyxL8Fbx78FRqlFn49gbd15Y50wEYKwgReEIL1HF4rHtekOsspASTf)K7spdK(81DypgmZAW8XopzkKCFFnU)2p)JhYD2Sj2iEqxfHKlikuavhQ4K6717X7vRq492EBI5FzaQyf6J9euUblmGTrNtRSLyQYtM3vSQFCUiaJ1UF2Nf)JUa4ODbRJzwB3c07b(kzyjFdTWtKPjpThmI)Et2)eDxAuL26Pn6IyiZtu7KfA91yJ(zK6yrtLE0HB4Z)qJcriZI12dFn(ffYG5PHJnpP(Jnu8y9hz4bI12gYG5zASUr7nEe2w8TQGUsbTQcZtQqRFyNLAQglXW9oAQ4lPo(TOWiRjxlFhztKi9sQLplVSA1tk1adgF4yXx6qH9eqBvhlzKyd07rwnvvzlPI1FIedo2aKVUxSJMm9zP6NBXoy5DZ9i3ylDZDA7vMTTE5wVhl4UHbZFePn(dn9xzrZv3PkkDDY7fQm28BE1ACvO(K1ytmjqEB4c8Kn6eSbZNM4aZZrmCHhQSPymy(ClHFP0bpjRV4j8kkZ3wtsfU0XKK1Y(8eEd63BupU96MK4nAGaHdZIVku3S(d43x3S(841RFwpHdeYpRp)(d5zTTHwUK1YvRGvkcNi3reg5aiLUARzRIVmaw52G5yZ2Fc2boAIHthzqydVD7tKtSEQEoEAiR4sQCfr2NAgAwnUg62r1IERutkuqVeskVDOWO5omDYP3MM5TjNtc7aqz2EYQ5ObTYSC2r4IEpBwWgEkvxbGQbL6oU86IkLbd)MxRHKYGrWH15aZGzCsI4sd(Kbtj74ozWivlItgmYW1Vrdgfy)gmNaJnv7KThdgn8v68gmLnyMWGzsASJmyMQwqJQD6OSdYHMbZjBoGrmRlXlkM3s5qSdlhnIxYSIoBKnsl1g2SKLkmI4KCv0STLHjQBLTS5ToFyMNbSvSbT2Dw9EjDQ6bAKqJ)C1uxKvtuWny(MKWZy9bQnJjx0iNeDIiL3lNCx90wUOVkMlINYffzDlM41(cnmRSKnaTPV6cnVLF)onDiendD(YFif5Rp0636QY1Qfmxb7QVGwqZTvQLqZSM8BRCm5AhRTk22gReewTj)ZFUHYmy(wwORUqbgwkx8OhIxQTOl48a6Y5AsOBW8DR6p9(BPG2G5uxciKxv0i1eWLgP)KvMSNI9X3xBfWFTlSc4HBRaU)PBDCbQ67XAmUax4eDnT9QBq0DWkbdmvi(jRuisBfDZFXSOl63ULIoLowQhIVSviI7JlRqulvIjerf01uB)uj(6xmleFOBRLcXfBYn(x2kaX9VLvaE0GtoELEgPVWY(BRa8BCXSaCzwXjdMVWfVYm66czfMu6cc12aL2KuZVWjoQYqLMiB8CTvQ93FXSuBzchUbZV)LOsTrClnAG(5gVx3O2k1E(ZJsnY6LeTNehEyyd7V2EYn5ejDLM81KcP7Qh8CmQTLzJlHkvX(Elu32UL8zOQv7Gwdg(RzDBTk8MorYx6wTI5QB4Ofltr(1N916qNiFGJFKr8L4E6ELSOOpZvSbYNgUPf0rLOBGuPdAU24VLmWPvU(wS5rhaxY9A6KVLchEC(m0TsQvBKb2vuY11w6HN2G5NUjPrQ1Ygml2CtyW8ZYqut(3BQAp6lU6Q23FvvTb(SRUQ9joNQg41lNuLMPzY8sbnZQBPD)XMumDFOe9GoyYJ62tL2sX8dopsXScxPFYU1(0Qw)l2Zoz971ByVuwHxWRhYUVszB0D5SlY)Cm5kv5C5qK)Tka2dUBpx1T38a5ZC2(Wx9sNnIbwHcVD0kjNu)kPoEr)vKe6VTsUFyvj3axOKCppDHsJjkJNwtgtI9Fb57Kq3b96Zx4OECh0B0aEchGKqp7XEjj(ONOWWSEchoKBAQhAQxAQpAQFAAa6Pr19CkivYhJzY)GlmnxHcOC6y5p58PHh)wGSjVfKqjnltMxwEG1UHvyaFwtaR4JRpKBFJG8mS72cSQDO3x3bwDuQJ8DK)uV2g((RDuic8ZmyQqDr6hB)PkJ8zk7lVPlU)mLH94yjFAY6oNYuXJi0FKI93IpnzDOX6BFb2N7oM4YFt)Fd
```
