# Druid TBC — Bear, Restoration & Balance (v7)

One pack covering **Feral tank (bear)**, **Restoration** and **Balance** for TBC Anniversary
(2.4.3 / WeakAuras `internalVersion` 45, `tocversion` 20501). Built with
`tools/tbc-weakaura-creator`, 46 tables (5 sub-groups + 40 elements under one top-level
group), **zero custom code**, and locale-proof by construction: every trigger matches by
exact spell ID — never by name — so it works identically on a zhCN client. Every
spec-specific element is gated on that build's signature ability, so the HUD reshapes
itself on respec with no user action; mutually exclusive elements share screen slots.
Six of the 40 elements are the **PvP layer** and load only inside an arena or a
battleground — in PvE the pack is exactly what v3 was, minus nothing.

The whole thing hangs off one draggable top-level group anchored at screen centre `(0,-140)`;
the five sub-groups below can be dragged independently.

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

## Resources — bars at `(0, 56)`

Three flush-stacked 172x14 bars. **Health** (green, `%percenthealth`) is always on for every
druid. The middle slot at `y=-27` is the primary resource and is shared: bears see a red
**Rage** bar, restoration sees a blue **Mana (Resto)** bar with `%percentpower`, balance sees
the identical **Mana (Balance)** bar. Only one of the three can ever load — Swiftmend is the
31-point Restoration talent and Moonkin Form the 31-point Balance talent, and 31+31 = 62
exceeds TBC's 61 points, so the two mana bars are mutually exclusive rather than merely
overlapping. The bottom slot at `y=-41` is **threat**, and its colour semantics are inverted
per role: the bear bar is green while you are securely tanking and turns **red the moment you
lose aggro**, while the caster bar is green, turns **orange at 70%** of the tank's threat and
**red when you pull**. Health and the power bars carry an extra Unit Characteristics trigger
and fade to 50% alpha out of combat; the threat bars self-hide when you have no engaged
target, so they need no fade.

Since **v5** both threat bars additionally carry an **instance-size gate that excludes arena**
(`use_size = false, size = { multi = { none, party, ten, twenty, twentyfive, fortyman, pvp } }`
— every TBC instance type *except* `arena`). An arena has no threat table, so the bar was pure
clutter in the one place screen space is scarcest; everywhere else, including the open world
(`size` is the string `"none"` there) and battlegrounds, it behaves exactly as it did in v4.

Over the rage bar sit four bear-only **threshold lines** (rage caps at 100 and the bar is 172
wide, so a value `v` lands at `x = -86 + 1.72v`): a dim green marker at **20 rage** — the cost
of a Mangle, the reserve you never spend below — and a dim amber one at **70 rage**, where
Maul plus the next Mangle still leaves you capping. Each has a wider, opaque twin that pops in
over 0.25s when you cross its value and fades when you drop back under, so the crossing itself
is the signal. They render above the bar and only exist while you have rage, i.e. in bear form.

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
| Feral tank — Mangle (Bear), 41 pts + Bear form 1 | 33878 | Rage bar + its four threshold lines, bear threat bar, Lacerate, Mangle debuff, bear Faerie Fire, Demoralizing Roar, Frenzied Regen prompt, Maul prompt, Mangle / Enrage / Frenzied Regen cooldowns |
| Restoration — Swiftmend, 31 pts | 18562 | Mana (Resto) bar, Lifebloom, Rejuvenation, Regrowth, Swiftmend cooldown |
| Restoration — Tree of Life, 41 pts | 33891 | Tree of Life Missing alert |
| Balance — Moonkin Form, 31 pts | 24858 | Mana (Balance) bar, caster threat bar, Insect Swarm, Moonfire, balance Faerie Fire |
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

Ungated by spec: the Health bar (every druid, every level), plus the five v4 PvP elements that
carry no talent gate — those are instead gated on the **instance type**, so in PvE they load
for nobody. `tools/spec-preview.lua` evaluates the combined level-70 exemplar profile,
combat/instance load gates, inverse gates and the Bear/Cat form state; its output is the
offline-eligible set, before live aura and cooldown state decides what is currently drawn.

Instance-type gates are a second, independent axis and run in both directions. The six PvP
elements list only the PvP instance types (`arena`, or `arena` + `pvp`), so they exist *only*
there. The two threat bars do the opposite from **v5** on: they list every TBC instance type
*except* `arena`, which is the only way to spell "not arena" — WeakAuras' `size` load argument
declares no inverse flag and no custom test, so multi mode is a plain OR over raw string
equality and the complement has to be enumerated by hand. Both bars keep their spec gate on
top of it (Mangle (Bear) for the bear bar, Moonkin Form for the caster bar).
All 40 element children additionally carry the `DRUID` class load gate; the five sub-groups
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
- **Cat-form rotation.** v7 prevents the Bear HUD from leaking into Cat by form-gating all 15
  Bear elements. It does not invent a Cat rotation: powershifting, energy/combo points and the
  Mangle/Shred/Rip decision loop still need their own reviewed design before they ship.
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

One warning about the editor: selecting a group in `/wa` force-shows **every** aura with
fake data — both mana bars, both threat bars, all three specs' buff rows and every rage
threshold line at once, all with identical placeholder timers. That is the documented
WeakAuras preview illusion, not a bug. Judge this pack in combat, not in the preview.

## Regenerating

```bash
cd tools/tbc-weakaura-creator/scripts && ./setup.sh   # once: fetches LibDeflate + LibSerialize
cd ../../../tbc/druid && lua5.1 generate.lua          # rewrites all-specs.txt in place
```

`generate.lua` is the single source of truth — never hand-edit `all-specs.txt`. The script
seeds `math.randomseed(20260812)` and draws UIDs in a fixed construction order (top group,
the four sub-groups, then Resources → Buffs → Alerts → Cooldowns, then the v2 block and then
the v4 block at the bottom of the file), which is what makes a re-import offer *Update*
instead of duplicating the pack. Keep that seed and never reorder or remove an existing
element's construction; new auras append their constructor calls at the end and are
re-parented into the right group there — which is why the v2 and v4 additions are built last
and not next to their siblings. v3 added no constructors at all — it only set load fields on
three existing elements — so the uid stream is untouched, and **v5 likewise adds no
constructors** (nine conditions on one aura, a load gate on two), neither does **v6** (a
trigger flag and the conditions on the eight cooldown icons, plus one extra trigger on Mangle),
and **v7** only appends a form-state trigger to the 15 existing Bear elements.
The script round-trip
verifies with `W.verify` before writing and reports `W.uidContinuity` against the previously
shipped `all-specs.txt` (v4 reported `stable=38 changed=0 parentSame=true` against v3; v5–v7
report `stable=45 changed=0 parentSame=true` against their predecessor — all 45 children
plus the top group, i.e. the entire pack, unchanged); a re-run with no source change reproduces
the file byte for byte.

## Import string (v7)

```
!WA:2!T31c0XXv55mEJb7nqJT8Je7MaRnXoYPjo7tT7Aib2D1klz9yxn7kzlhx0o7o3vZin7mJNz2vsMNrKempAbeTbAkPqffmeOLIofApT0hicpkhk9h1cDknLq1P8QpGt9Ppa6Z79oZSpKwTwwsorXnNt8vZEN79oZ9()9)9)FV)37eMHBRWh4EU4lDX8CfMGxtrnHIKI2PC5YvAxEpEi12kOiBOPijH4tiikXRHKFIL6uRSiVN7Xt3iojdHfC(jl3yi1968R(5K580ols3q5yQ7VXCJZjXjxaDm195KFwbneNb(oioTJPEllp7eC6gi8nU16FwE6tugrAXXKq1Ec1FNYsQ32Qvd81gQhS51ICVLYROXJ0IBpUOUR4sIx4cCA8EYQOiziQQnvQIf1rgm5v5WdlgQ3PvJLnEcCds6i3ThA3xJZqur2Zr9y3TZB1YcAtB1aNFon0y4sKDAve7yAkLvNZQezeVaA7ZlkxurReTnCpV1nSesmmmUwKRSHGIwkvYT1DNhlUkkoMBnUc0m6Gv3GtZWD(IIYI6cUJJ)JH7zm0ehBmKM(ahvZ(YhnUb5PZvwJZ)cKuDvKKKiV(bBZB8Y4kLxvIBAK2m087Hx39s6LZJQG73zkxSO4uZpAIyzYoAMSXyZw9wP1q4BXMjDY(67YL1rjNc)ELXQfYXkZvcP7EoEuEClq68ADNSV0DnuFZww2(1Y988I6Jxwg3BQG8ZjjPUBo61zTUF)k8Op(nypCLKhJ)2DMZxglo80vzjjpNwq0aTG1DTgR35SCYIwdMDa3wxlG40rzmWIVXmeEHWHIlRiJwKVSLiBuYyIMocpOYRpdPOK3sis8sCIYDbHXvaIarHtaVC8FV9LNZS6iPIPveLnYNi5aztYEyrE1DxfXH0vkRvaPFzCbqAYCsdJFw4N6dmFrn8id(TIZGZ1LXigSaUlswKNE(mjytMCG5mukuXQ87i9(8JBY5RCYSNT3(us234NMvVaNeY1Cy5alfAP7GC6rgpi4Aosps0cYexsHJ398wpg6BlC)x07C6yq9eNwK3qyFZjIlEg6l7TDdWnZa75PUbOp4(xKwgwfd6GfJ6UB43ert8ydLnvCs1fGx6R(OGNhfp(ChWDcyEbc(iVfdcoRJah19myeYOeSwo4yWDb3TB4EGJd3R76RhKrDVdHlINecCeqostu3qSGUDtadTS6cEbFGFmeH8smAbhYnxWR6bG7dU)zYZzRmL(g9ECFHiPHJqs9hYfgzQZzqWciHfO9nlm0imq3Ny)WHMNONGBGrX)7I7xTnd0ugJQlWXRm5zSPgMLMhjrDxhbJLkG70c0(8roI6UQRc10OxYkxhOdmO6EO5Gv0via3cuHs8y4FEz6nWAyiEAMp4IwsXrSF6lqV)4LXJqfNgU)50iIguwCMXhi1ajHdPHbiKYmhTG1gDSETlIP(v3vxAIxWZGL54jWrpzZQ6TAFAulIPrBOJnkpQawdtAuvn8f6uKr9dnoVClsZBsmQ80ACQZCA7lwS6JMYiKAOS91ZajThRQdKoFpdmqs2rz75KDNv9yxHxjmNQmpvBMTOKIIM1atf8BxEjuUApscH7bSheDeHQh5k04wzMFGYLYJ0QahAw8GQLY2Iw)X(12pgM4KJITaY(NfQj9TZX5DZwTDueMBdc68lD87PR8ciXXemUDO3HNLO5uqItxpxEdSMVSX(zlvgBKYnln3JMxxKyZJTt2H6Pt4r2p8wYfhZKxy)WJ4ooP1ixSefJhhxDEIYR)yD2P6UWTCmEcecXJ47NBkbyxWR0IDirnTPd4E5LueRYVxnBne4GURxb6mmZsvh1f5rSuji0bHnE5mQVIRmhl8ZIROB42DdVe3ZtFeDthvUpnIaRSgInHeItMLtsvGZL1lrwR7O2EpeI3ICfqNJ4FbEekoN25gQN7P2VUNmuknA1eGoXuTyoCWv8lOOuIbI5IDsIE3t6gIdjGKZFHccAdy0Hq3NLttuMWpJeSFRe55rYSdKC4KSZROjIfruwY56ofBpNn1azJ1hCQdEu2ccOct0f4z7Zub3eCyiWmIYjukLNZGTcNuzeZHvup89DFAfeWEXG0p4rHlr9uBgvStkinJPH3lClUVmXDUXOW(QmlKIf(IEH(3hmGnp(NHHWJdPyG0WGalMKwgt2(PRr2YMwzsKgHCDwvYvevixnWZUib6v9E5AkLnm8QrpxF5ItuKokCrxyOiMMFxzmiolDVDHZ9EJHXrKAzBKGusRwQrwE401tUdNHYQhjunUDFHCbJiaN1MbhEGlUh4CmWp)HpIkmkvbeYHhj4G8qHhe4zaeUzkcJHlQaiA14JdtayHVmOaQW5bnqhM8aWumqLCyTF41aVw41bVEg4ny1EVXCWdcbHzCbVjSQAf4HYTePlq9JAczLjLZbpmr7dER003mEeaElwQOZvRq74HggEB0c82HFb4xKQfcVdhLp4DIv2G3fwndMLbE3WV0MI(e8lFFWJcVh496c(vGhd(vRPaCJW7JG(HhVkYxzS8jo74s(ptQSW7xa(aWVomh8bjqA43GaNHpe8HHlzdEHpsvyl8rP4v4jwZi0xDJiu4JrXwFCMgHx)MxTiXwcH8hI(YssIUCa0(PaOl7yDNQkCKJCvIMuBF1mYqBV6mGbLBa5vjN6D06QALhCblqQ6926sVsJ3Rnmn8jxDymm)o6EMTqO3TVc0B0bhjLohkJ)Kd9)lrVWVZvl73NAf4q4t7GXGF3nhqd3b3cbAEbRa00(Wv0s35z7mz(tTPcAEFBRzGMQWG5mORjczsqyF90gdzGHbutk1UrocgbBc1E5tYiAuM6TrDMmBaz9Bv1Sl8jSmZc)2Rz7RwWRiKKanhETWrSE1ulyuLzu9Uxbru1c1ewOMdmvpulAKQeFT02DtCVVwt0aT7A3i)JGX2u)uiEwlydUTa6ye)Yq52g2RWIDt0y6C(vROMBg8BIX0L4KZ53ajNBoJjXe0txuScc7Fp96CqKCBj0lEHRqV4KDoz60YX1cpD4MPx4c(qSCJH9nDz6gNIYprDsZVvQlSMYzU60ugOby9Vp8hqqZFgl1b4pCZdrd)roeM)XRc0e(tUsip4ZEvdQGfUsOjBoZkWNlh8K5GpFo4lKd(I5GV0wgaZowbGjBE5HgRJ(6n1PmAaWCxvbmZwvLeU0Hd7LaBUFhydDHQ7GK4JcyQwj4ldxY1vpcZdz45Y2ZEKSIeK5cRU3e9fR)0ztfVVyj6fpX4EY2ZWjxvZ5UwlMZxZKU3cEw8vxJk)05XeLMgKMgkewkMVKOMMIMa1NJ9Ih6pO7zZ7mtE249LCGoHt5EDlAv3nVOEbnKbAunN17RbX9JQEIAZMogpFkz9ZDAe3eKjUPFU(r8ICNZEE36NZAjAhLU6Sh3ymok2GOcIHfyTqckzNWn3Nlc6zeHzQ9etoV)27SCQO6b8nbhf9q0)FthkV1kBjSMCRO6mPE8TBjSH)m4R(mMOe(ZXiwYQms5y8xvacq9Yo4RblUrKxWFXYepWFztgKDd3CsRXy4RtgCl2UAgP(gk9at3zDdUWF1gEC976msTK1SmiRubNHIgwlE2QRFqoNbDw6ppSFVxtg9xPsKRwo8xeouESFi6y)SE5AKyaKQSbz0(PYRlOjkpXmorlioPDPcGMiGWTc8u0ljvnEroEe80(X1GwK1K06MQPsyjU8n2Ktk0T)i9NnCnX1rU6fx7CvfxWFnHN9BwvYa)ny23R56exr5bDK8VLoscFl4PHV9ABuh(7WLDP1(a(lAzQh8f6LRCc)DLiCYn449lfyQgIvyBpH6UCckuFy6ts8gQfyu7Gv2jniz1IxzxCinrKNUe1qobnTAKL6tSikVKIsPAbJLfnE5kizkoT2tJfHDdBsdHALJeEOc4jmmjNwPALRFfsuf1qQ3EZF8orZ9ao3UtujfnojXlikpMhwfon4fd)mex22fSBOnSK9frKS7d2)2js)B1YDhSqhlPRxSu1DUddVSd2MxNj)sqxeC0pxUMmb4aypMcTZ1pXPLSFrNEsC8OUUnSGiZPOKKZpsQ2tPfOxP0NugoPlOB3qpUia0EDtqfx8LrDrf3H2dDbawSGIIeVYKYzMuufLBbNFscyPqJ9yI63h2UhZgiq4GHWsi5uYsyp(VdS7SRS7R1Dm2(7AO(w36FVQh4YtGqQXiXdWGLareO(cJH9DFQVXIJjPmzxAOZxgjxyAlYZ4K8ewaZCFsj7qxjmljVmwHDKCzF0qQUV5jx7eYhAzQf1a69CcZIvWOi5qFIzfelmHmsx31m0FINc2I5lByOiNQcstIBAABrcyV(UPpV4wXuV665QV(xp37hM8qwELVjS6WlyfNQ4PYMnv)WK3IvdxK6UFtD1FWRo2K9cSyTQFeCZ39nswtcFrJNkwhd2EmbcPk5f69rNgZmoyUCvDe)7OUxNmjEM1POojCd85iuEpoE6u5iQJy)XTuLi6hhYIi1wvAz5C7RihI(sDoXNx3GRWe6WLAle2R82EfwoLNd7c(ivlZsOPufTmNMvSeYUSh(vCFvlmjM2h33XjICc3rmxlxzd(xYbxE11QobwRks4i40Or6GMgg(xxnDl4FBdOvb)710JoX3a(pS0DGFSa8teGFQl4)CFW)fd8FBjL(FWkaW)RjZn4YKHXKzBMmU2TjZnkSjGanz2om5TFnd3jrmnwH)mNkzHKbAVuOgXDMmVWAiUVRjZo2KHxUV6ab2gtEc)Hd7f)ViXJgoy04rJ6nmR)oIgnaRVoIekmRVWbI6LM6JM6N1FyV(898OK1nk5EWGKsDCSXozVdZhmBWwas(EB(GKAR8KjJ7MWPyYCtRDy0alZcDhbAb)rle2NAdlS3QyIJcD2SmSvnsrvHoFLTrM3)4DRXlP2PrVNSfyNV)Mp25UQd7Stm2jWQA7YcB5FtcB9nX0tbJ7ZBOiX9fmG34(9gLM4lEGo8hoEKO(8gpAKayYRibjxf0hR)q(JgLWJfXhn1)6dyEDdl0kHsetviHJj0V)IJCA9STaj9dU2ZcfytcP8eyWqGoijrijrXjyeboXh26wic2iuhKKWKKiuKH3NhzSmKXiyKXPNwUSGwjFtW3Elqg)dp3bzmE8qHc7L1FqSxo00q00oOPHP(0e4k48717iHQXyUrZnSLZh4ujLeB)8NVfqH)XNv9NTob9xgRU73hjjijjejHWiqnu4Nql4NyOiqassqssikpa1R3irEEmqtSt0(u(92z6(o9uveBbe4FARce4jmz2LjdE8TntM9yYSxtM9zYSFtMBXK5wnzoWZlIBcHFVPpVF)f5cXNrUfI4)5T4tiPU51o(HJgnoEcRHIhni2DrmTpXOFuQr)OrE(PVUUN(6dJrlzsLwBs9GdD6H81c0Yp8zt0I34Kf0)WdLg22Jv3I1RHKVGiINSE)izpP1ukPAuBn)jBqATcwB5z194KBkLeE6xuNSVXRDQR6rwgPvHZa50i7Pwykkl5Kz1JCvwneYJsrAajQ2yvJQqIeEuK90pQwqnIZPnH(eIYEApJrz8JIV(digDRo5PNsLklJOHtGOu8zPkfwbqGSlTlGEXB0iimFbfPYLKZqAmR9fsERfVLLtsCmz4(10n4iN9igYY(3R76cLJM1zlcLJgNJt6AgSWWUDAtGgzI9Ua)0YCLelqpMxW(3ECDfndiYSJPjADgoUPzixswV7dZ2jRKyjrJBISxI6JCLWsfuKXpEzJU4kyOOLNnwN9muM8AC8IL1FOxeeANZILLwR9(dTFhqz1dSxmjKMH(CflljLquRGe(n1oUgFDgsemUzPnqKtWqDlBxjNpyWmg5vYkmmFQlEhWamTMaJSNZ)coKpl2WHR4Wb9IjHYsLBwereX2q5u3nnSX1x0CQ7VXZLHtqMXZwVA4jV4Uzn04kmrCYPPXQrWQeinXczeuMmLCUfB4NZRt)dlIJFA6MGNUHShGReAhJG1tzP)0(yjDGe2lMornymnKUoggtU)XuBJ8CWyhfnKsfKgw(IYTOg(TmJtZPUVgvsrwRb(Iv3P4Kcr3gtKUIvCxProN2BYPUhY1iYPRR(IV5qRFx1O1XS3WpjhM8MnT4uiPQS7w7uksAqkl)pohM73IN3IHV1uYpIfL8C0tXc9SoSMPNjNpqYjtShSIHQNABbfYV1phxErjrJPhnpgWRvwxaWUijz5ExXEpZPgUJE4M4KtTc28QBwjtg2vJoVXWqpVUewOMxXWqPenU(bCcj9YP4V4UMLE48Or0shl(iNwfACZGdLVqzDCdKNwGPPdNKNG1VNY63pDB(G3ldv2tZoxBtZVZ2MIzw6jCH0QZ40QKN9I4RL1Lih7l8Tu3TZ9Y6Kn(fBrBGKvg5OTnT1YTUCi1HULSw6HxBbTDv9JOkGZK5nwZxc7t1H1EfOzWTNrDOWg9AY8GTe1g7BxVtfvXH5R4BWo6pV6q93IiNyYKzTHdnzEy4PnzEKvh9zY8MnzUiCitM3IjZBTkgZK5Tvp(YK5T7aSmz(fmz(fjTKjZ7WK5DIBltM3fU7o7YGhxzI(gw6Cm6OJGlInxwqaPBr3UOfDRTNcRdKZDTwqo1ojqx9mvRbNhRxoBYmt9NYmlsjkb9OYKtwkMUtBAS9CP8Cy7i1afhlXWftKECXakzBf5u2RhafnSHJu3xdNgLAMWxO(8jBnm7DKe9yh2WryjxlpnfxelKX626Mmg432YMmviTIjZK748)qs)FklR5MmtBYCbCjEnZw1NxtMx3YSaBY86Xf5nKB9diPdV09DQR1RHtlVlKvmQ)iLTuJ)MyYKczPKunayTWWnGypAlrSseZhYe9ZA41uNjXPkNiRxVdnERWRdDDhE9zKni36GJRJnah3A0Ew9EHrqnhE1C(INm5JrlHNGyDigbu0uH7qnTpD2wHyg(6oZEbcejQptMh1K59CnWah5Ebw2MB9AhcOWvWsxJiadnesPOKyruD4GlyCm)J3LEXOhRLw6o9wFCWA074ku9FBPUJPKmQ7kHMYK8Esu9RTdbkSX8qU1(58mQlYfTp7kp8kHr1S)Cu4jZXs(s6GN3rJ(i3xSGDLU7krknKAR8r(mBDbjpw1LWBE7pOs0VKmxkEMSdnqdNrLLj6(OxU2(DJUZjRBTaFc4slsQ)O9Nmr3XgONeTSHmz(4nw34DLmg7koFmHTMlFZQWIKk08h2vOMAjsnqxdLj5kQtqBQkYQN103r2uPYUIAfWXJPM8KY0tFjhirYvouuDcJnPJLowIE6AK1tvv3vMeDNkvFJ2d5d8d7qPZEfQ(v366V6URoYT1u3vNXznuBP3Q17hcUByY8XiTXLS8c5Ywldtvu6MGpj1o)XR71i6dxJ)WIY4HWpKFTgDM1K59tCl5tsmoHhFCivmz(ilNrPuVxGnqYu(LueALzNrUUXSJ9IY8y(7iO)4(863ljXF8qHIgLfFv4iSbdfmqe2a(87piRVOHchKnqWGH9TX2MixFzDQjajvXZxyeXbpfsT9wzA6SB9bsEnzge(GW2ERohKKeDw94N0qwjL1iFO)oqDz14Ix7eAj6TYmPyrJsizEN4rrZDa6CjVtDRBt2N)orbYQ9uWZNNe5iRY5eMj69Ci4A4PuDs6vJm0DFJ1fAitMhyNB04czYCoNJjSjZRMKm6kJaKjtoNG)yYWvlSpMm5H9VDtMcqetg(BYKHeDhtMI4RgtWKb)FIMmJtdGJjZe1ICtTd1Jt0fWMckT8O2WSPe0Me(lvaXoGs8y(jtQ5kXQiVsZtZrw)UystYnTUJzkmDCZmtTO9XAY6OlTMTvTw)ucDnDU1HAG5syTBfl26i4ZMmFzsyrS)KtMZI0zWlGoFSYhJtP9oBfPZcyshbkPtSnRqrFIQE)mNISdKCzhZ6LVRyHLDq)TIy9Q)rYqO(iAFhRl)KwYAHKR(cAdg3BPMcgZBXOT2rHBC01v3(JO1yQAZwx4QcxzY8vTXtTJcnGCHKXhwqUv4Pp3MpEY9gsmBY81Q6o8jAQO1K51(CvX66HQOMiT0GDNE6j7CStkCYwjsFYNvfPd0srA3Z08fKVQhfBWfK)zyHvJ754gew9oDhHMkSWKtxmwRewF(TWcR4pvtfwQTTsp9EULyd3XwnXMEMuvKqfn01APV)FHTWITh6oBQy7YlZb8NBjYWDQvtKD2oMCIP7CWtgvjyRezFXTWISvzHFmz(uBXKs0LNXoQJ01LPvXDCzYPGIN)SQ9xQs(KfALC6lTfwoTkXt2K5XVosonOx5Hc1n3eD5f1k50F61o5ezzlI3zQtpaSTtuBJQMUsApzjFDwqgE6epdGA7J0KYOst7CVLQBVOs(SU0STvQjZd8I30w7a)ztL(zUvpy(6goAYYgWV5Szp7)88HgFKbdK6mrwlRg5V3lyBKV0sZiAGkr3jLY9ATm0g5GmQ3At2fL9Gl5XSCi3wfdpoVaDpvA3g5GdfNCDTLc4tBY83Vd5bR1YMmFNL3eMmF3CeD0V3YQ27(7V(Q2pyDvTE(eRVQ9HUQQg41pN80lNyj31mIL11AQUKfPsKHt1jQ30N1RVPBfPY36AhPYACr1jBA5mA2)FeJdYg0V)O(P8apTFFKTOK6EPBWxpKVN4EYuUqbe5tJoCh4(88v3zV9WNRLFrxV2BhON1O4A)nrwj3TAMXhl40YID3kz1txvw1ZZsYQVbDXjtiPGNcsolY7Fk547hPd)bcenUpVD4pEiFrdrsOhxw)KKa0dixuwFrJg2ln1hn1pnnanninne94u6DEvKg5lWk5ZU3mCflIkyGL4KdFfEWBjYMBwugL2Qm5EU2PX6axXOPSrGsjNWOFVbge5BaVTck9TRgkLnBOuBLAJVn(l(sA4JZ1zHxj8JmzKOU9SKZ3XkY3WQVYo2A)nSc7hXk(UvfPG6ujJj2DSX6UjF3QAtNnWXdDCVTv5gFD)F)
```
