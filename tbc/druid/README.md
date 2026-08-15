# Druid TBC — Bear, Restoration & Balance (v8)

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
the five sub-groups below can be dragged independently. **From v8 the middle of the screen is
empty**: health, power and threat are drawn as rings around two small unit portraits, one
flanking each side of your character.

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

## Unit orbs — `Druid - Unit Orbs` at `(0, 30)`

Since **v8** this group holds two clusters instead of a bar stack: the player at `x = -250` and
the target at `x = +250`, both vertically centred on the group (screen `y = -110`, the band the
bars used to occupy). Every ring is a `progresstexture` in `CLOCKWISE` orientation on the
bundled `Ring_10px.tga`, filling from 12 o'clock; every centre is a live `model` portrait bound
to the unit with Blizzard portrait framing. Twelve auras in all.

**Player cluster** — always loaded, for every spec and every level:

- **Health**, the 96px outer ring in green, with `%percenthealth` under the orb at 16pt. It
  carries the low-health escalation added in v8: **amber under 50%, red under 25%** (severe
  condition last, so it wins), plus a `maxhealth <= 0 → alpha 0` guard, because a
  progresstexture with a zero total draws a *full* circle rather than an empty one.
- **Power**, the 64px inner ring, with `%percentpower` at 11pt below the health number. Its
  Power trigger omits `use_powertype` entirely, so WeakAuras resolves the type from
  `UnitPowerType(unit)` at runtime and the ring follows every shapeshift — the trigger registers
  `UNIT_DISPLAYPOWER` unconditionally, so the switch is immediate. The resolved type is a stored
  conditionable value, which is what drives the colour: **blue mana** as the base, **red** when
  the type resolves to rage (bear), **amber** when it resolves to energy (cat).
- **Portrait**, 28px, carrying the same Health trigger as the rings.

Both player rings carry the extra Unit Characteristics trigger that has fed the out-of-combat
fade since v1 and drop to **50% alpha out of combat**.

**Target cluster** — same shape, plus threat, and it **self-hides entirely with no target**:

- **Threat**, the 120px outermost ring, `%threatpct` above the orb. Two mutually exclusive
  auras share the slot. The **bear** ring (Feral-gated, Bear-form-gated) is tank-inverted: green
  while you are securely tanking, **red the moment aggro is lost**. The **caster** ring
  (Balance-gated) is green, **orange at 70%** of the pull threshold and **red when you pull**.
  Threat is a `static` progress trigger whose value/total works out to exactly `threatpct/100`,
  so the ring fills 0–100% of the pull threshold with no extra wiring.
- **Health**, the 96px ring in green with `%percenthealth` at 14pt, and **Mana**, the 64px inner
  ring with `%percentpower` at 10pt. The mana trigger is *pinned* to mana (`powertype = 0`) and
  carries `use_requirePowerType`, so it only exists while mana is that unit's primary bar — a
  warrior or rogue target produces no state and the ring vanishes rather than parking an empty
  blue circle. A `maxpower <= 1` guard catches the remaining case: most NPCs report mana as
  their primary bar with a 0/0 pool, and the prototype's `math.max(1, UnitPowerMax(...))` floor
  would otherwise render that as a valid 0% ring.
- **Portrait**, 28px, a real 3D model of whatever is targeted — players, NPCs and mobs alike, so
  the target side needs to know nothing about the target's class.

Both threat rings additionally carry, since **v5**, an **instance-size gate that excludes
arena** (`use_size = false, size = { multi = { none, party, ten, twenty, twentyfive, fortyman,
pvp } }` — every TBC instance type *except* `arena`). An arena has no threat table, so the ring
would be pure clutter in the one place screen space is scarcest; everywhere else, including the
open world (`size` is the string `"none"` there) and battlegrounds, it behaves as it did in v4.
Both also carry a `threatvalue <= 0 → alpha 0` guard: `threattotal` is derived from
`threatvalue`, so it is zero exactly when your threat is zero — post-Vanish, post-Feign, before
your first hit — and without the guard the ring would read *full* at that moment.

Four bear-only **rage pips** sit on the player's power ring. The ring fills clockwise from 12
o'clock, so a value `v` lands at angle `v/100 × 360°`, i.e. `x = r·sin θ`, `y = r·cos θ` with
`r = 30`: **20 rage** (the cost of a Mangle — the reserve you never spend below) near 2 o'clock
in dim green, **70 rage** (where Maul plus the next Mangle still leaves you capping) near 8
o'clock in dim amber. Each has a larger, opaque twin that **pops in over 0.25s when you cross
its value** and fades when you drop back under, so the crossing itself is the signal. They are
round pips rather than radial dashes for a concrete reason: rotation on a texture region rotates
the *art inside the quad*, so a thin line rotated 126° clips instead of tilting — a circle needs
no rotation to point the right way. They only exist while you have rage, i.e. in bear form.

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
| Feral tank — Mangle (Bear), 41 pts + Bear form 1 | 33878 | The four rage pips, bear threat ring, Lacerate, Mangle debuff, bear Faerie Fire, Demoralizing Roar, Frenzied Regen prompt, Maul prompt, Mangle / Enrage / Frenzied Regen cooldowns |
| Restoration — Swiftmend, 31 pts | 18562 | Lifebloom, Rejuvenation, Regrowth, Swiftmend cooldown |
| Restoration — Tree of Life, 41 pts | 33891 | Tree of Life Missing alert |
| Balance — Moonkin Form, 31 pts | 24858 | Caster threat ring, Insect Swarm, Moonfire, balance Faerie Fire |
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

Ungated by spec: the whole unit-orb layer except the two threat rings — both health rings, both
power rings and both portraits load for every druid at every level, which from **v8** is the
first time a Feral in Cat form has any resource display at all. Plus the five v4 PvP elements
that carry no talent gate — those are instead gated on the **instance type**, so in PvE they load
for nobody. `tools/spec-preview.lua` evaluates the combined level-70 exemplar profile,
combat/instance load gates, inverse gates and the Bear/Cat form state; its output is the
offline-eligible set, before live aura and cooldown state decides what is currently drawn.

Instance-type gates are a second, independent axis and run in both directions. The six PvP
elements list only the PvP instance types (`arena`, or `arena` + `pvp`), so they exist *only*
there. The two threat rings do the opposite from **v5** on: they list every TBC instance type
*except* `arena`, which is the only way to spell "not arena" — WeakAuras' `size` load argument
declares no inverse flag and no custom test, so multi mode is a plain OR over raw string
equality and the complement has to be enumerated by hand. Both rings keep their spec gate on
top of it (Mangle (Bear) for the bear ring, Moonkin Form for the caster ring).
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
  power ring and correctly lost its Bear gate). v8 gives a cat a live energy ring where v7 gave
  it nothing, but it still does not invent a Cat rotation: powershifting, combo points and the
  Mangle/Shred/Rip decision loop need their own reviewed design before they ship. **Combo points
  are not drawn anywhere** — a ring is the wrong shape for five discrete pips, and the rogue
  pack's socket row is the design that should be adapted, not a colour change here.
- **Energy breakpoints for Cat.** The two rage pips are Bear-gated and rage-specific. Cat's
  Shred/Mangle costs would need their own pips on the same ring with their own form gate; they
  are not in v8 because the Cat rotation they would serve is not in v8 either.
- **Levelling.** A druid without a 31/41-point talent loads the health bar plus the three
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

**v8 is the one version where you should tick Arrangement.** It is still a clean Update — every
v7 UID survives, because the eleven Resources tables were repurposed in place rather than
deleted and re-created — but the entire resource layout moved from a centre bar stack to two
orbs at `x = ±250`, and with Arrangement unticked WeakAuras keeps the old coordinates and
stacks all six rings on top of each other in the middle of the screen. Tick it once, then drag
`Druid - Unit Orbs` wherever you want it.

**What to delete after updating: normally nothing.** Because no aura was removed, an Update
replaces each old bar with its replacement ring in place and leaves no orphans. WeakAuras never
deletes auras it does not recognise, though, so if you import as **new** rather than Update —
or if you had previously renamed or dragged the old group out of the pack — the v7 group
survives alongside the v8 one. The symptom is obvious: you will see *both* a 172px bar stack in
the centre and a pair of orbs. In that case delete the leftover group by hand: `/wa` →
right-click **`Druid - Resources`** → **Delete**, confirming that it deletes the children too.

One warning about the editor: selecting a group in `/wa` force-shows **every** aura with
fake data — both threat rings, all three specs' buff rows and every rage pip at once, all with
identical placeholder timers, and the orb rings sitting at a fake 100%. That is the documented
WeakAuras preview illusion, not a bug. Judge this pack in combat, not in the preview.

## Regenerating

```bash
cd tools/tbc-weakaura-creator/scripts && ./setup.sh   # once: fetches LibDeflate + LibSerialize
cd ../../../tbc/druid && lua5.1 generate.lua          # rewrites all-specs.txt in place
```

`generate.lua` is the single source of truth — never hand-edit `all-specs.txt`. The script
seeds `math.randomseed(20260812)` and draws UIDs in a fixed construction order (top group,
the four sub-groups, then the orb layer → Buffs → Alerts → Cooldowns, then the v2 block, the
v4 block and the v8 block at the bottom of the file), which is what makes a re-import offer
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

Construction order is UID order and is fixed; **display** order (which controls frame level, +4
per child in `controlledChildren` order) is set separately by the `adopt()` calls, which is why
the portraits are adopted last and never have a ring drawn over a face.

The script round-trip verifies with `W.verify` before writing and reports `W.uidContinuity`
against the previously shipped `all-specs.txt` (v4 reported `stable=38 changed=0
parentSame=true` against v3; v5–v7 report `stable=45 changed=0 parentSame=true`; **v8 reports
`stable=36 changed=0 parentSame=true` with `missing=0` and `retained=45`** — the 36 is lower
only because eleven surviving auras were *renamed*, and `stable` counts ids that appear in both
strings. `changed=0` and `missing=0` are the numbers that matter: no id changed UID and no UID
was lost). A re-run with no source change reproduces the file byte for byte.

## Import string (v8)

```
!WA:2!T3xd4XXr59NrxCIJcbSK)ijMeYf5yBztIZ9PoDUjqU70jRVVt7DYo2X1627U5UDL2B317UNKorOP5WeudekrecqW8LkeGqaccAG(8uGgxABAi)7ZuviSTLsjgkekuGO(X)NsFAPZm7U3x60zzj5pIBYZtgD7UZo7SZ7V3FVVZ8(oRbhS1uFSBFMBAHKSPgpTIKCijbjL(SzZwuBo2Nx5wtjjQPijiathIJxiTcu85K3Axk55tB)2ShNtbYQzV9GqwL9iFT1E6qSQAq8fkv)OcSfGk27bYkOXvrZWQKfQzD6TutTJknjurEZ1u5bzfzLVoRtYWMfApoFQXjNpRauEB17k5fKVHL7oSpaVM82R)DrV21UKULIMcBLxWSNzDHtNusjnujO5aR8MckWp90SkPThxssqJxwzQizYOc1ajLzXJRAY72OLIhmeU1iJP3QDgOQMKcRgVKO9DzpiRaRykysJwMtPGrdCNZPaZIRr8cYqMSks5LNZOgX4NgUH55fZiPKJ2gnpVXfmKYaaW2cS514KuIitUSAZjXY7m8zBwHnf9eDWOQXQO1CYm8I8QCnhe)hTMlQPWNnlurDODPy(ZhnOg5PZMxH11PiLQYqbb(0QBVvhbZJVPKY0XTI0Z3BA1MpTA(KWjWV3XYNjd)uZpAOaXIpAS4byIx6srvG4lXelA4bgyX8QWWtH7xXmAHemIS5GQnpxAysClqE5v6j8ar7EKbMnVOz3Q55tZRowEr8BZeqxSccYTWs)DCJRpOuA4tEzMdxHtNfk3sSJNhloS3DEbb7hIJxdEkJRAmwFvZYkYBmy2b6n09PGSQWyAyXxwnUReTJGIsIWfsN3qKnkzmrrfIhutRwKuvsVeT)G5y5f7g5hFdO9J(Tq3b6oX)9MQ9mZQcfYevIxulzOWdfpmtB8PLBXcUncEq1EeLKQlIRaurKv4G4Nf(PEpZNrbpYG7vSAS2weJyWc4UjNI80tglet4WdnNMuQjmQ)gJUvx4MC(joq8J0)asHhySdXOMIvaABoSCGHcTuTqo9kIheSnh5nI3aYeuqInDZZB8yO9w0DnZ(tILwkJway83PaOw(eVU5ztpwEmLq6bzNQPYhWl2eARa0qO7sElPHQSAKrpirVHGLftZnVkPVdNcFbyIkRt3syGVrDyuXQgAGIqX0bi6ZNyBOG3ZPLvKYQavvJjLxjfCV3WL1e6nJUluROaOBOz0RV5IksAujfGHvqMJ1gAG9UlMuCWuJ3nQnBfNGvHNnPagxNf)CyMGvipe0MKCB35DQKIdtCav3(UqhRpczP)OxUJ950LrPTI4hnw2RvyXmL6KuTUDHUhstJo68AuAsABIowRoin7DCNOrjniaLaDeuFBFMTj3Qg(fFuvo20stE3MegZsphP4u70OvKtPTZDkVPkQBzvC5BTu1h1Gjy0s30OPHPWWzHrLvW)GGgaN2OrSGEbdms8iYBMEsmxHeb7N6q8P14cgaF4Ignl)uW00tE)lyaeoSrx9Hpf96ejnFMcO7Ao6aovygCOidfw(MBqFZ4ejhkFUKqf0ouWOrsfNJw7uwgQSnR5DJzq3u3k8tBF48SPjyF7XJx1WNzFcSa9CtIXZhsHvU4Hm)XcLAhkxsKrIpqV4EOXGAvWB5D2GEnvut18zYiijPuUzj0XxV54JLO0y8zc8qpgMLijhKplN2lJ6KqUulbXB6mtzKmfg2nAbci0Jt0nIBLMr3uZi7nlVjSIyatvoQgiNCljlPJzQDj7Rxcxsg2uWJgiD6iIQh9qq2Xdq4Zp6GW08Sh1SMQhLHxm7OoDip1(0YYI6gZImh1wbv9dGg8bMf)ehnLaRQAIIKFQIF95cI5)tTnMC5XwaBoPgMLruBBO3zZNMwdcZ(4IstkMGHEJ7kPkpP5y6IzKE7c9o3g69KyUY1AJN4GbjTkUbMGbBevRqcxYtiNOiwOOvihRycxAqXeZPnj(PuidM2prsJFNaT)eOB(y7c12JJh(2fApO9oNHiKqRI7xet5O9z0TkFHeO2Bgx7hJHADsEtME6eJxlpLgb9gr3k62roqoBg30pQvthKas2f633g(ffDs5nftJyg)2X0x5UDYyl(bHBy6GePMjQOzqUqUrEEYllzoEffjfUALJ8ICOTTOfpNMHWPOeMAhBUvT5zXOkX0eRCmbhi8qDrnnZyr6DA1CssACrnVB8qlHeTBEfvnU5nBJuc8YCOUqHx0SXjQkKguElHgiWGrJhj4abc1FGU6Q349EqS6szqLjeFXYNPePebG61BXus5KjpzoSLnKneBFKZ7YlHoTtsHBBOq2yMKqS8YYTuMj1eeIEa0bM)aDnz0OIbv8vWNcViXMgKBw6lcPxMS3HI1BxHNxsHhlXOV2ZgAGiH6)q9glSH2YuMAlxFZk0BdMMBM9JIaqrPwTqd3eIXYcfkghkEc0iCOdcqhIAKbD3l1Uc6Wa0rWgt2Fj2(zlrqGowB(OK9VjtY((O(A3bPWPnmXpBPBc9BJoMndZngv9L2z1xp5YB4aLcGsJGOmuBaOSaehIhngACKW9JY9WirC)vcjJooctTIurAV0THYJManjanfQaAA0BbDV4Q8wr)oO776r)Ua09NavC1tmHEBlLtcDco0BhldjChO3bHYantc0Vhh6bjmcO3fT8HsGE3yvh07Xq7h9WBKD7OzjA8O3Bc0JKa9(sGE0eO3Fc0hWqPEOkvQrFq0Jr0U(qwAUOtI(W1r9c9X5qZH1Kq)bOprZOpj6XrFka6tNa9z4qpbf9J(SONe95aOp)lni6lqHRxoI9Lgcdprp1lJ(IuKy8KIJKTJb6psFAOVeh6lJ(drpn6RG(QLWxO)Okqwp5Acz1NbiydOJwKxmKuUKSyGfOsScDcCe4qj4YcyRAPWAbC0jAHXHEjyNwVJsWqC)SdV1dh(1Wv2L3kQCnaXzZHTNy2QneqkVPDwvNyN70cGwj685TvcEwb0u2XsS6wvBvhFzQbnlVNZqlu22ng2Jb833nJr(1XAF13LXjX6rfFMZT6hhKOFyOwuLoHH(YS0sQrTswEqNmPX0QXhUBlBm5PwYikbynJLATcBHAl0jxeIJLmpqOcp27TuQMnb6BwZ9Ug0H2GjLVtVKsFDAq)BJQv9mMAvtNItziTo465iSRaTQ1gF9ElPvH(JpJQtOV(zI99BupW9tE51dCJ(tQfSIEgtm4nsyFp1fPWl0FkLvToWIAQ3F25a4ZvGPG)Yvbw8p8HJOYcJ5k8iNhPGxbGLzLjlJfLzPAt6u8FNElRf40BnKVpl6yxzv3HnZBb)qCvDDlI5HPpimY0zdqMlAXctRC9jH)51GtPDuF0532PlB2mDwqU9LJCK20vZOwj6((tiFln(wlrREFxlHf(2BCTRd5FX7)Ip9fg6YzUC6cNh0zUYQ8YMw43GW9(n1HKYMm0rgtW1Dhj(fzeU)LNbyn65QR3eBOgc3)hlhD)wlbtIEEcEBReg3)FxebG(ZRau8xrjCXiINfqGgg4c5TqmSRapEEEfifIrwdJelqoBjMNeN)qzBeX(Ra3qvWQ2p4ekr76iDfozFlpSYofIqAo679txZ79UrpRTQ7P)119L6JuAY2OpQXKRrFS6nRA8tLXyHKmvjWL(PLE8Amfvcwf)6V1nJ2MI5eGjiyYGWanVQrhYTKMxnLcudlZSMmEviLVT8DSYxjMq8kPeGJgJozExLwogIQhwaG17isKRc1Y37AW6CZvE5t5iAHhyExT3v(i(vD7CCwQWKOfx8AsASsDCObNGGsFilG6dUu46dVXtCqt06tDnxaeHO)gdtI(mmjwTG7Kxgg4(TxhKzOVtnIi0luNH5MrTCVTqO2(UMJUzAxoMWaJeDOcDvXOl6VDnpW(JTgQoTHbqYYnZQjP02B6oNTKAFcRrDg6HT5YX5KH)LQ9yRcfNLm8NbTJKK19bQHUtfsyrIKxJmA)9tQYPWloErRaOeK0SubqDeq4wb99P)KCRbZWMgIErx47GwLvK06QnvkkjTCMDYj56XvNdg3xzP1wp7LwBDzLwO)EYc)89kjyq)dT5ZX5CDcBnuDWAK8FKosI(bOxeD6v2Oo6hIR7pALpG)AQv9iDQ(zZhYv3H8fEnoG7E(CsPHc9QASqTVo0MCXkZZr9Y3W3efAfibJA7LIWDv9z6Ahv7KBAOPXtjBgT3JijLlb(D9ugpJm8cWEtJ29CghkZINb(Un6GJQI9ITaa)6xXX4(uFnJk6FL5taOu3VOk2Kpumf0wf(wTfoK3GdjjcrBJH(iqx3nx(zLxDym(O8XktduytpbzfP5w9KJyrC)xR5a80aKVRMk8jI8RX8SfQ49vzQF0MqpLFQe)aZhoJN0hmMNbGzZsWjYBIwVU4vjHmUxXmsCuFfROpRnDLnwbWmUr)eQih9sCuxsnDg9NE2jQFSg6f0)mr(I(z4A9ZX)))crcI(fRs5g6xwRad9RWkMVmwsHwKiFq)Ra0)2AvEG(3Rss8Ar)ha0))kh5ZF4JhC4iroYyz9t9p))0CKg9RbO)lWm3uL94MEc5nzf75bWULq8GOCoCyMffDrJfF5ePOBwOcp0E3yVsTstKsbWEa(mWKcy9MYP8bdCS8tafPC)LFAmKv9FYktnesuOtPzp2KSk5kxVbLijVGcu(gR)J3i7j2J81BD5UG5Kuyf4NMxmRDgjwfkeQfaw0SzIqzRVgawOCTORBdejY2nMAbwEHLA1flDlODU9wDyXzqWveK0TLOoGjVOoq(UQvV81GpDbR3KG4rDvtQwIOLY8EG5pCK2JO4UFHOhqe1RncuTFQ4DWMjQhZSJ54tjjAeC8B4YiVzg6nlKsssiT0KIXMKhpTHtzDijbj4Q(v3keAKxDg3U95XlwujgruOqclfQAghu6jaZGDpYaRAJBbVNfhhcLdqIKOgdbRWrbVytk913lSqwbPj7wXGwSGHJjbjNJ7uyVIoGGzKX5MLCUygP5a5NdqtHJTop53wbkMwNszeLn61ScCRr8OjNH(eJZXNACrOQQTI0dXt3AHK510KeJyehnABnapUkTqFEbnYHNz2mDMRTTt16n1vqnlbdPxuVO0qxNA80xl1AYR6w7u9o0qHzgnyK4XJmOXsVGBySv)zXVUg5aYcg)zujZqyBEyQszCGzQpvkS2M5oYOqm(b1H1rKi3AdvC4Zol9BlibZIAvhCLOwU1lNmXsN(dgjqhd3EaoIxp4)l40ywfA8dlAbDtuIf8)wElwNKmdkSzgsgEKobH57PgwhSZee97VKf3lrHBhgE7yQBwZzUPLCgIcO1kBydD0KQASPgxfDSwRmckjqjqF3s150WPK5n85noFoOzDlToh4ktYfN95CFeOdHmkKTz2Ho4QQuRvh0CcDWvV8kO7hRG2PVoXL(7SdAPpDW1SC6P6Gx7Aqfvh86kRvU)xqhSjdvrDqlC6GwX))MTPd2Yw1bBfOd2gvSPdUwSALo460bxp(GTRdE96GBOfDWnYToaS1bVbZ1sNcN1b3KoWo(zFZ02th0gEWBhOo0b3YQauIHnMqsbIxTtK(U7lCQWUBpNxtiPoy3uaPoO9YqX)hDWEwVXDnFwJomTC9eU85Zb()7mOFFE8h0VFh(yC1HF)UzC2rNE9X40NB)oOLoPLUyC5ZHtNVk6z9e9CByWtUo2t2d0)bt7jUNgbE(nNdapBVeHKo4nwhsiDWTEwbVgQgVd6WDdiCAiiOV1pqWflwAPqQRDDfs1tXLcPE(MiRX3y9OKwqUlT(pqdWu6Gl7CaOAVvaQ2lgu5EzTcAa6CT(b6(7W8zEc60H3od60JBhbD5WpTWzq3D4YxWo970rq)D6gZ21PhYV84KXLxx(9ti(60jT01QfXEPkTv9WyeBEqU9WnORmh(qQXBiedCEG3Y96he6jWOe3Dqk6Ku4hxGHk4cNy7KEjGgVDqk8rk6KczC8QqMZmK5WyiZHkiMNtjNZXt3EdHmn9kliZyb961NdgxEWosrl9sl7Gw6J62K7ZOJ3)FnmIzw9Tutxm5t6UVWc8TF8J3qqITl4otxbe45WmeUCsk8qk8skiKiuJoUimjUigDC7Mu4Hu4LsDqD5UZoFv0XkaDqm60(uUC0v0bo0utW3qWXLFXe44j0bo1byhlWDsp6aSKcpwGNkowS7xhS)xv4Vce(eZh9h94UCLH1B6yInu4VHxbmtPkMi(yT53Fq8mS9g0VhS7QyJieFl8t9TWFNV68TxpNV9BhdJIfjQYKQEg5qJ4SHWOR4ckmYrqsqqABKOOMESkcWHcuCAEyAsmsGI2JQiLtwRCCscjazvsXQQXlMT8wOnIui7dYRs2AnL3cT9kkcvMGvdA1iBUCODYlyDYs7F24kqODPm0G4uQXkfjMqHSljAFqy5abfKvzC1X5fT3EmT84hv69SK9)BV5YLxesdbdrz5zOrWZiOlmQYSPGxZAnQlZNssiFoXyKgZgjAjV5KgRZndRaFwmQurvJLSTqPr1BWkdyNIX2(eMGgBOETvelmmBhA076aTTtLUGiBo(u0DGl662qqvjfn0(NnRcVXEJ7Qls(jj0aTX0fJaFoETRMKq2dq(f3PtjjIF8IADZMstsjjtGU6DKyjvytZNx9eVgKVRAwSS0imfNyBwWYtBnigqaQOPoxM8ccg5ducRybDyajQpTiSgI2egQByU7aZ7XtmTKsX5oy6iZClyQnWzIztSQ8x7R1MhhLcSUbPerA9nti3cnPvQmX6tiVTQt0ERuCP17OC2rmtlmAkSPgpizZjA0iynbOcFQyCstgrmXcvD48Q0)WaztxG0hMLUBYgInhCJhE)ODWqp0ml4V(qMXjWU1oKcJEjxFpYTsEoyiJKcKSpPWIvyIfuW9YywnN8wRw3eAS6(luAFUrQeDxPqEvmI4mnVDOVnjK3m53qY(DUYQVorXV3Yu8Mu4TILCBNjk)uqHkj6n2ewKspucFSbHeggdiC(gS9Re65hWGEEo6wcKUBvw5u1KTWnntaWkiY2lNwCKJvpkBsEbETcJMed8vYRYri2FidNdZ0)D33b7Ox2XpWulLyNRmXU6YsSxDIXmVQawoNusttkhntJCBLKm1s2pZMMLUdQPHbuLKGiz50ObBeTJKPYRIBGK0kuGo0sEcghpLXXVyRorhbqHd0tNO1cPVQwNcmlDxktA1IwTk5zVa(3IQcKnwl(sYTyDT4wNg3XwWeBzCIe02M2AjwTEZAX9sIpGVvwuVxEpnQegQd(yv5SrLP7(YbcVa4YHjMwh8XBiwoWpOg3omrNjNW5WDmys5rg0BdD7qBfIo1bFs0lQdE8LhtQd(u6Gpn5n7ZOdEIsipDWNTsuNo4jTGB6GpNo4ZtAjDWxqh8u42sh8fXVXZxdOzfziOQGbGXmD4zbSf1uCqvdQ5fmOMnDMy1GN27khpvAVwSwy1wboDwL0xhmNC71sGrz3hvKKtUyUrLcyFaesYIncvgQSNqhmtOOJX7wkEdjYYFPcuPQmMuERvTrpk7eWPQ88KuB1mLkP7r6Q2DiwjlF9tWYzWc8z1bVxDWJG7lVpDWJsAfDW7FJh)xqgc(ag(dOd(G6GhdxJp0SLCwwh8HRXgUo4JGRYhnXAgMshOjf(STMn9A4VIOKwLBX(tx9XeJUuGmLqBzZHnlC8UAiowGy(rKOgxgfh5Ud1x(qXD4yKXAikEIljrXNxY73vpFyhRh8HRqlIv5Dhbl12Y5uxAYKBgnhEcOvGJ4G(J4Rd5OovzAioAYljnC62DN(DQdEADWx5CNjssfCxD(8F(axK6mzRSACHMcekLrGpdSc0X0A7X1yDRMX)EASTYPEfa6yL7l(euUctSGLXOtkVPqkstM2EOsFe3iaK1f)XpJ(pDbWH8mMF(iAywyVl0JKGH89wdpXNA8iFGaE6oApt0zUrKBOh5fUig68yL)(sz(P7J(jh7ybJfFKHw6UiUITC8ILtWWQ)qvPdEo0XwGC)Joy4q9eyOEd1Wgsh88vFVb7oCaMQ3ZZe3AmwBH6DdlqUH6)Wod3PsOid19iXcVK7XJjzgzT8QBFKjsK4l5UCB6)v9EsX6DGWdfkCJ2z2l9flAGq929Hxn3Q8MIfQNirgy0EjFj4ygjA8ZWTFwh(HL3n4dFd11n4IwlQBd9cUspzWVj6GVfPn(lm8JzrJfeQeqD9ZRMY7U51(Qx94LzvmisMbxHVE1ojRd(gehBEiIHm84LfvJo4zxcptU(NMXD4iUeK4AOjQPVKYeL5Yf9yU6WJRGoD4YbPWvqVE97Nb)lFDY4XRh3DY42PlxEyC63RppmU94XNZ1yM0CjTLS6bVK5pEQdZpCFq5gNvnVLxbaVCOduMRNim9EKidfpWaOMEqR9puOUkTRJQ6uHfvyZcT2Jp0tv9cXBfDm6LInjFgTCqX0wHuJE2HOtID3QgxMSRoScKLr7jPKIg8lJ6zfPm61SOeR6PuA5ckfCRB9YRi6w6G79QwRH2sh8wnIOfrf8(if)Ulniw6G73k(v6GILJCLo4THUUnOdobA)6G3(vRdEG2y6sh8oW)AgoDWVNo4b1bVtAmO0bVRYbFQ8E5YksjQ6G3DTbEcSUe3PqUYLcYmKuWaUOZA6mt6iUuBAZrwIXactYwq1Y2gMZUE22wWCdTzSP1wXg4A0NtHZ3tP3BneBCN1M(cS6IR(pJeMhZpYXjm4KgEA4XdKFpSsT3vd5K(Hyoj6Eq8PcSUfJ9YFe(Mts0cOwZxHNAZd5xUMpgjgHIF5)yLWvzO6VLvRlxN2yfWl1hnHOBjxDHOjnO6w5yZ1bm3QmHqwjiTYlsa3zhAth8lnrzTd9oKyQWbpixJtiOF05auwZRvHVoyXs(BV)6kW1bN8sfH9QIwPSGo3W9eTWKDL9aCnE7m8pDbxqpudf09uS(XxOKBjR14lCHveUK8(Ucry)f6W7u(4MSqManue(JVixeg87vxrOCRl1jYxzlmXVOlRWunwKjeGz0uvA8uo(jxKlmpXURRWCXA84)v2cs8l5YkipshtoEHUg(a(L80qb5lDrUGCzwXkDW35ICzhDDLmddlDbLAyGyRr65H)4hrEWCtKmCQgk9(PxKl9wMWURd(Axkl9g2H4iE7HD8UDaBO07F(CO0JSElb7kYHgc10(lNBWrNiQ94Kpmxqn7DHNys5u3nSimxbRRD6ks)xYx0R6LjV6G79Aw3wRdxXJe983QDmFfdh1zzosV(KFTdE80Eh7Wd7oYD35kCXv)QxrtKVZEf51G5OjYQy)gR1(JKaDs5RRojXAV4AUhJjfyQ4HhQpfnLwnBJeODeK87YlDXtR30g2O4WLBz9MUIABc9MUs8nQ30gR52EVV0Q72(PRQBR3VWQ72(KNv3gYLlwXclHUjX5l6Mv1se3KndQMopyKUG9h9ioCwOHun)MZHunR8ihqYE8tQy(pCuBNXJlx(DrjiErxojz9L8wOzDTDY)EJzpw(uPGK)PXaTl8B(8Ls36EtNOHFDVo)BZO3vOqCB1tck2JCSXY6PGiFpnsc20Lvsc27fqj4lqx41qcs4PbLWGR)xt(Eq0zhUC72FqNo6WvqVo97Luq3n1UifUPBgs)mo973NdAPtAPlAPBAPhAPx6MQ1X8YqfYx)pY)WFuKntgyknyAJTthEm80KepNxeg1OsjEf8(R76xHHsAnbXcpU2GoCpm05qoAieR8g6FDhI1AUwt3A6zEdv9DO7iimz0vQdEiI3t4oR53SnY3RTNFJxC)9Ad7mYs(gT1zk5PchGVNaz7PoFJ2AvLX9(8UphToXL)w)F)d
```
