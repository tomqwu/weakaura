# Druid TBC — All Specs (v6)

One pack covering **Feral tank (bear)**, **Restoration** and **Balance** for TBC Anniversary
(2.4.3 / WeakAuras `internalVersion` 45, `tocversion` 20501). Built with
`tools/tbc-weakaura-creator`, 46 tables (5 sub-groups + 40 elements under one top-level
group), **zero custom code**, and locale-proof by construction: every trigger matches by
exact spell ID — never by name — so it works identically on a zhCN client. Every
spec-specific element is load-gated on that spec's signature ability, so the HUD reshapes
itself on respec with no user action; mutually exclusive elements share screen slots.
Six of the 40 elements are the **PvP layer** and load only inside an arena or a
battleground — in PvE the pack is exactly what v3 was, minus nothing.

The whole thing hangs off one draggable top-level group anchored at screen centre `(0,-140)`;
the five sub-groups below can be dragged independently.

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
current friendly target), cat-form Feral, and pre-70 levelling coverage. See
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
| Feral tank — Mangle (Bear), 41 pts | 33878 | Rage bar + its four threshold lines, bear threat bar, Lacerate, Mangle debuff, bear Faerie Fire, Demoralizing Roar, Frenzied Regen prompt, Maul prompt, Mangle / Enrage / Frenzied Regen cooldowns |
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
for nobody. `tools/spec-preview.lua` only understands talent gates, so it lists them under
UNGATED; read that line as "no spec gate", not "always on".

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
- **Cat-form Feral.** Mangle (Cat) comes from the same 41-point talent as Mangle (Bear), so
  `spellknown 33878` cannot tell the two apart and a cat currently loads the bear HUD. Fixing
  it properly means form-aware gating on every bear element.
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
simply starts out shorter, and fills up as you spend things.

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
constructors** (nine conditions on one aura, a load gate on two), and neither does **v6** (a
trigger flag and the conditions on the eight cooldown icons, plus one extra trigger on Mangle).
The script round-trip
verifies with `W.verify` before writing and reports `W.uidContinuity` against the previously
shipped `all-specs.txt` (v4 reported `stable=38 changed=0 parentSame=true` against v3; v5 and v6
both report `stable=45 changed=0 parentSame=true` against their predecessor — all 45 children
plus the top group, i.e. the entire pack, unchanged); a re-run with no source change reproduces
the file byte for byte.

## Import string (v6)

```
!WA:2!T33E0XXv99NXBm4SHqSLFeIBciBIDKttm7tT7Aib2D1klz9yxn7kzlht0o7o3vZin7mJNz2vAnVkIKG5DRGMsdHt5NObdPu4u1FhkTLFfI415WR(T60t6aykTck)Gwo0tDl0wAH279oZSV0Q1YskGsi)HVA27CN7mZ97NVF((9(979oMzSoY)bUNl(swohx(P51uuJRiPODkxUCLYLNJhuTJ8kYgAkssi(4cIs8Ai5NyLE0kjY3590zFiojdHLC(jl3Ki1958RH4K56SlwKUHYXupqJ1gJtItop6yQ73P(mcAiod8zqCAht9wAU64C6gi8jEr1FV6CqrzePhNucv7ou)zkjPEBR1vGp2q9GT(QiNBLCkA8iTy2JlQ7oMK4fUaNgFNzuuKmev1MnzHc6idMCQC4HfdNxMmXIJ7WOssDMwfLxpNv)iOvXQ5NFbn0KIkYzQOIyNutPK6cwTiT4fq7Crr5ckAf5mWTW9IwNWsKWWW4AzUsgckAjvjNw3DoSWPG4KU14YtROBwDdond35kiklQl4og(pgUNZqtCYjrA6dFun7dFKygK7oxjnoFlrk1vrssI86hSdpXkHVOCQsCvqAZrRVFED3ROxkhQm(TmDPcfeNDXjIhnDMjsNjkBMQNkLgcFk20Psm4GxPKokXS4NR0w9qwwzUIiD3lWJYH7bYlVwFjgmvVJo48LKTFSCViVO(uLKXVnLr(4KKu3dh94mwNFifE0h96ShUsWJrB7j95lHh87S3s4H7tliAGwY6SwJ13W8CYIwdMDd3wVlH40rPnWcRjneE(WHIjRiJwMh)(tAXeKXenDeEqLxFostjpLq4yf5eL7fcHVaimebob8YX)92BUM51rsfsPikBKlEIHZKG9WI8Q7Pk(cPRuslps)k4gG0K5KgdFVW317FXcA4rg8tfNbNRRGvlWc4EjvrU75shNnrIHxWqjFzR2VRu73hUlxS8jZC2bgujXGtDAw98CsixlGLdSuOLUdYPFz8GGRfiVrIwqMyskC8Ux062qFAH77IEwqhdHN(0I8gc7FbrCZttFyVTRdUzgyVx(6GbH7BzAByvmOdwmQ7PHFtenXIoAMKXixUa8sEGJcD(i4XN7aUtaZcqWh5S4lWvDe4OUNdJqMGG1YchdUl4UDd3dCC4L5U(RdsRUVrXnPZ4cCeqostu3qmVUDxaJ201cEaVGpmeH8qmrEhQmxWR6(H7fUV5YXzRmL669CCVbjLHctk9f0fgzQZzqWciHLOVBwyOXzG(oXbGdTirpb3btG)3fpGAhgOznMqxGJxzMZytempTosH6UpcglLh)slqFNpYru3DDxqnn6vSQ1b6aJOUxAnyfDfcWnpvOelk(NxHEcSggINw5BCzlP44239LONFQs4rOcvG7BbnIObLbxzSHtoCc4qAyacPnlqByTrhRh7cyIE1D3RM4f6CKsC8e4yNzYO6P670ewett0Wl2e8O8ynmPju1WhOtrg1p048WTmTUzWOYtRXPo3PTpy5Q3AkJqYrZmy)dNWESQoq6I9p8WjyNGT)t2xg1JDvEKWCQY8uTz2cskkAwdmLXpD5KqzRDljeU3Q9GOJiu9ixLo3QYCdxQyoKwz4qZJhuTu2w26p2p2(WWeNAuSfq2)mFnPVDnopB2QTtGWCBqaNFPJFoDLtajoPGXTddm28enN8sC66zZzG18LnoaBXsytsUzP1E0C6IelCS9WoA)9ap8bG3s2yyM88haEy3Xi9g5GvOy8y4lNNO86lAp9OUBCphLNaHq8i(H4Mva2n8kTyhIxtB6wD3ClfXQ87tZwdboO76vGodZ8u1rDrEelvccDtyJBMr9vC15yHFn8f6gUD3Wl29I0BrF0rL7vJiWkPHyJlH4Kz5Kuf4Cz9qKX6mQD1pH4TaxE05iEtGhHIXPDUr7)EQ9R7jnLsJEzcqpyQwmho4k2fuukYarDXodrV7Z5gIbXHelEH8cAdB0TqFNLttuMWpJeSFQe55rYSdNySeSlQOjIfruwYf6ljB)Nn5WzIoiCQdEu28cO8t3l05oNRmUl4WqG5eLJRumhNbBzoPsiMdROE479E1YlG9zbPFWJcxI6x2CQyxsqAgvG3lClUVcX5TjPW(QmlKMf6IEGH2pmSnp(NIHWJdjzGuWiaRnj9NOgzlBkLzqAeY15vjhruHC1ap7YeOx1ZLTLu2Wyxn6z401ZkdNHshhoynszVbDbJlaN1M6fU)lUx4CmWR(WhrfMGQ5azXVcCqoi)Be4zaeUBkatIBQaiA15tbtdyPMmOaQW5bnqhM5wHzzGYzXQTWRbETWRdE9mWBWQ)(nYcVriamNl4nH1Xkdpy2viVRuhGMwwzg5SWdruBG3kT8nFu4IWBXs3AHAnAxp4yWBJ2G3o8oG3jv9bExoAnWVjwlb(TW6hW8mW7gEpBjkcWV99cpc87aVxxWVl8OW7RgY96HhJaBH3FviRYK5IF2PK8DMKzGFpb4da)FGfGpiblc)(eCi84WhcUKnQd(WvXBWhHc0GNyJcTG)akO4JY0iU4pClfc5li9HLuePza0bOaOR4ywMIHpYrUgrtQDTwwhO9xDwEGsnG8kNv9oA)LAvhCblqQ6lR9TE1wDxFyA4JT2Wy4JVR(MBBe6DNRc9gzKXtQZHs7lXO)kj6f(JUwz)wCv4q4p2bJb)F3AanChCBeO55TkqtxJvwlvpNTNe5o1wkO5X2rZGMHRhgSGbn0fKzVGDstBsKbggqnPu7ezjyK0Q72okhPfnkrDtGcAw3iMWKc)TgXS0rSUBQ5nQs2PE3RIBPAJAbXsRXAQhQnDsvUS2AoUfUAxRlAGjD9B3(HXWv6eljE5kyJxTWUyqCtaxBB1LzXUSzujRp1YQzNd)KyuPiNCwFgi5SlymdMZTsbXYiSV20JZcHZUTaQ)8xfu)K9mtQuYX0cvjuRG6UGhNLBsSFInb3pfLYH63LpRsxyW)z2eGF4pb(KewV)uleo8NT1HOH)ChoWp1AanH)FxnKh8xCndQGp9vdnztdwg(mzHNmlSuw4ZMf(CzHp)2gaZUwfGjto5rNS7bhi5PmAaWCxvbmZxvLeU0Hd5HaBUphydneXDtk8sbmvVi4lcxY11ocRtYWZvSNjhj6aK5LQUV4dgDOuzsgBWOXhapj1(Z0)yjSWBTWcTR1WcDvu3TGNKC1qa5JoBJi0Ya0YGbXcMCff10u0eOEgSp8O5bDpFoNjkZgBWed3dCk3ByPL6E4f1ZRHmqtO5eoTgKGpI6jQnz1O88jL1p3PrCthLeP2ZneIxK7C2tRv)CwraDcAWppUXKCuXnrRclPXkweb)na38GUiaIXfMR2DmXI(6QNsjJO7370CuabrL(nDOCwbosyDz8V68DE)70s(bFj4lVzKoWxbJRiXLJYe4RQmb(Q1loGVg8xUzeba00io8x1IXn3WnNWAydwMmEvOl10sdoAQHR0tDJxWF9MEO675muTIL79K52ZzOOH11MV6mUZ6moYs)5H95z9oGUAOUR2oIwaouoSda6yFwE5AKaHNSKbza8RNtxqtuE65CczEms)shtBXyoUxGVo9qYLgRahpcUSp8vqBY6saCJ1aUwsaVtoZmc95l8qzcvtcCKRDjWnSMsa4PieC)nvhSbtmT3gb5EvhIPdoFd6Gd8nHldFR13aj83IB73E9pg(cAceZNFaUsX91B8qj2KdHVeGPAIcHD8eQ72jzhdI5TiXrVw69St5wp0K)ulRB9YH0erD2ROgYj1FvZyYGIfq5KuukwlLISOPkvgjtHE1UBSiSlnZyiuRDK0EKh7p9mCAfR1UHuizltdPE7T(27KtYB1509GkQOXjjEbr5j7KvHtdUj4fsC)z3WEGoWs2xarYUF4a7Ki9FrwUoGf6yjD9ILQUgDy4LEWo84m3qcwJGM(1Z2I5h6h79rWByJtVzj7x25njgEux3gwqK5uusIfhpzxj18pGuQtkdN0f0NBOFxea6aUjOIl(sPU7HFH2lD(XlNxrrIxzg50ZiQIYUKZpjjIty1VXFi73yw)(dfiiwcjNuwc798DGDnC1V(A9fLDOEhDW6heEv3)vMgHuJscDTblrQlqDveJK77up1YtkPmtVAOZxcjNVIffxmsDclHPmpPKDwweMNuxARmKroCqA2)2)IKJDYobTn1cWn9CozeWkVjKAO3XmcI5NwgPR7Ao6pXZqz5CLmmuKtwgPjXvH2xKmjRVh69lMv6FRgbt9nEemVpyMdz506wq8qxYkLkXsMjtYHGzUfRoUa1B4w6j8ixBee7dyXkk)q4MV7RNmlCVrILmA3J0vubcpj5b6XOE5pNdmkBv)uxrDFovs8YPhrDsKX5ZsyXE)4zBKLOHHDx1s7Ga5pKf3OT2rt1C7RQgIkqD(4Mt3Gl)06WL6ii2P1oEfw(SMf7H64vBZkOzvfTm6LrSiYUTh(vCVvBmj9Rh37XjICcDquxnR)a)OSW)8AROCcSIs4qHXLrc3nTme8VSwQlWvAurb(xRPACINc(3SuhGFSa8teG)DxW)X(H)tg4NAnW)FHX0W)n8ZCb)C4)XK562JjdJWwaIYKzhWm3(tB4ijI1RY8N5ujYNWFxfd2ioYK56RHG(oMm7ClgU4(AtOAZ3)e(cfYd(FHJfjuGiXIeXtiwFDhjIFwVDhoyiwVH8hXdT0lT0hRVqE8695K6vL63dwOxS7Jn5jhym(azc0gH(3DRxOxlWjMmp)wOZBYSRnKUo1Oy3(BJ(9XxBj9P2Cs6Tl2FO4MTkRovtCrvCZxzhKj4ovFA8sQ9ymWjBdW5FyRh4Cx1bCEEyGJ)10WIfWY3weW6BG5AceZRNGHJ5nGFpX85jcTWBm)D7luSWr86jwKW(XmrHdqokGxwFb9fjcHukSxAPVngQ8zh8pRghrm6GeoMWq(km(P1Z0gy037PF(h)BrWKNaJe83nPimPicUadhWfEX2Pcsagb7MueIueMcl88CWI6HfJJHfNUICjbTIENMVR2al())mhyXuXcgmKhwFbWoRqldsl7MwgI6AI)Fv2N0Qz6SrRmSLY5)ujKe768NVn4GV)V09j1wk)LWk6(8skcqkcskiCbu7d(iec(i2h87NueGueKYaq9CnC4Nda0S5HUM1NNEsn4PNTSyBK))GTlY)NWK5MmzEHMm3SjZUnzWd0DyYSxtM9zYSFtMd8CY3M55hi1595Raxq(0YTr((p(mGPFypR0PoCKiXWt3mySibW(hIz7jg6Jqn0hj8Zn5ZQs)hcl9tNmL2m6bg90J6Tns))PFzk99eJeb8dpAkyhpADr3wdjFbrepja5i5otPPuu1OwqYjRuwT8wR9v196uBsL4DoKOozbexBZ20VSmsRmNbYPt2BT46xsYPYQ70MmAiuNkfOrWVANvnm8XJ3PICNdHQLfGyCAtRpTOCNDL2Oe(wXx)(cIU0z6S)IfljJOXFNaYFski3kI7KLRBE0nTzd5(I5vKkvuonPZSwuc5ScnklNK4KYW9PPBWr2ekmK4KpG76Y9HM1MmbLLMyGt6AoSWWUF6qGgk)9TeFfzUII5P73h4a7mMUIMbeE(j1eTwm)34CKdjrt(WS9Wkjwu04gjlKLbjhjSsEfz8Tx2OxU8gkA5yJ2t)JMoNghVyj9h8fabVH5XYsRiB)GhWbuwDFAfvcPzOVqHsssXf1YlHFsTteWYmKq(FZsBIunGH6wgIsSyGaPnYPKrym(Kx8oGHzApHezn29fCs72YnSk7pCapqAidvUHLuyrhrSnAw19qZgA9nnR6bACb67K7u80TRU48U4Eyn04YpDmY2QWQtWQeinX8PfuMjPC2LB4NlQt)dlIJVcD1qtxGVdZveTRXX6PS0FAV)uU142HQMOgmPgsxhdJjN)yQDqUpySJIgsPmsdlFrzxwd)uM2P7u3FJkPiRimVC1vEmPr01qd5vXk3J0ectFBYQUxYXiY2SQ(MVM003vnAAcB8pjl8ZztjolsQkzT1cVHugGsA)JZsOY)zUCOSBph7dBXXUaD)jqxf7RB(wYo)ISNZ6hJ0v7S2QFG8B9ZXLtus0OYe5WiyTs6ca2VfrlNVkmWzo1yD3p30NC2vrpxDPVyYKCT4NBmrSlQlHLs5ummukstwTFNKY2mN9f3980TDfnbq6y5bzFiqtZeCOC5lPJ7GC0guHoAsUdw)EwRFF5o8cVxgQWKwD2oQWFdDmlZ809UaPxNZPxj37LXhlRlr2qp4tPUhNZLXPA8d2Y2idRkYs7BAVLDZec7dscvDO1xAlxtVcCGBMmVUAogyVQ)TswElaB)c1)aBSRjZRVTy2O)D17JqvuyUYEhP7HYPo6qTjTeMmPwFOqtM5GlBY8MwBSNjZdAY8qWHmzEytM3CveMjZfRhDzY8wCGvMmVvtM3gPNmzE7MmVdCFzY8oXVUVRMahxDE7gIJngB0DGLXw)YlG0Typx2I902W)ga3CxRdCtT9jY1ml16WtW6LYMmVH637qwesu22jKj7xqmvNwfSXzPCCyJc1Gehl(yfINAkr)kzAhX0ipBas8a1VcAu3FdBvHA2JxQ(6jlFj7LydDZK1W(BiBBxQ9xelKvmzunzop(PfRJt3pOMmg768)iY7FjltZMmLnzMb3IzNVQdSMmxOjZPMmVgCtETz3WWr6OlDbm6AdAY0YrbzfJ63TrR04VjglPawkbvdWvleCd41J2w8QeXWHmr3SgAn5zIFQsXZ4XZOt1o0k7ZwiW20R3RRDkRU34uwRtJt17qfbgC41YpkEYedMOiEYB1bbeqrsgQB1uE1zBhei9Z6SH53F4iEnzE3MmVNTERvKt5VP1E5tBY)8xfZwnk)nWZtxPGeEw61HcUGXX8nvV6fICS2A2kZ2FuW60n3YuMaBzUJDH0Q7ooEw88DgV6N)ecqyt5QBBDz5xO(6wWEdn8qRgevZyYrHNmll5dBcE6dn6S7Grd0BQ(khU4OQTZz3r3(crE0QHwBr7VVn0p1hxkw6mJoCdBCHMKCFKRuBvErxVG1fJUlbxAzY1pXqjI3x0H7pEB7itMpsJxBSEteLDvBAIqwZiVvxWYKlO13SRYvQfp5W9oA6eR6AcyZtrIQvlFgztMmZQUk)oE)0I7u6(hmXWXtS6HIQt8RfVyPIgV)EhFJCPQ7oD8(sMCWj6N8fyHD0uzUkx(6NR4bARNNJFBT0ZZ5CITzBD8S(Tof(1WK5dt6JFFRqFDfROPufLMTv7LQRzpwT2MPB0a98HQXEyry8G4xL3xJ(LAY8yehs(yedt4rhhkftMhVz(KIdCbw)js6tsrODMCg7znMCSJSYJ6R7a(I51JppKcFXcgmsew8rHcZgiya)Hz971NVaSEJemuaw)bceY7MBby8SjltTagPkE(8JloYPqQD1oZsNE7pmYJjZWWhe2XB1z3qeVNQ7HIgQkHSg5BU2TwxvngqzN09qpv6zelyuejZ7KJiATdtNu4DQBDAYkB3jZmw9NcEA5KS5y1oNu)qpNd5wd3LQZ1UA2AU7RVU01yYCMByZMRgtMXD23OMm3pP4CRoRmMmVANeYyY8a1sfJjZeWb2PjtwiSjd3nAYK7WS9yYKhFeVGjdYKPGjZK0KQyYux2uQTZuCI4VUjZunNjfMTKePe3xX8i2HvIf1hzYmBattlqccxuPz4Qu1efMmUvMOw2EV5yT)Bw32PwxFMdU2NKCWgOIew3gLIUbYWRjZxKKQc7pNFzTyrg5cOZhT0X4u6QN2XI8PXSicuwKOBv579evDLzbfzhmwtBK2Mx7OF1M2k3wPfET)YgiuFAJVJ1N1QMqwRyfE3QpG2OR9vSLORCwuuBY4UDnSOcApgP2ePfUMWjMmFzB8rxOGdlNprSXeKBh(4ZS1JpCVPeBMmFTQ(QEIwkQmzQSDrmTruLRjIkosFPQmtptEsHt2or0tUnwe13CToq2vnH)mijvJlE2gKuduP7GZgsyMkfI2oj1sBJLuXUClLuQDSA)QEgKmd)wTwYm90jllHkyOR1w3S)SBJLzp4D2sz2vAYx3NjXgENRP86SDpZ0v6zKtgrjq7KxFUTZgSUT1WG1IBNer0iGyNJoAOpAxw6Asifq88NvDOILZLiF7esF(TXcP1i3RMmp6ZwesJ4rE0G9XnDVEqTti9fE6tircmqSEsE6HHDCIAlpZuLt1zgY3LdKrN9GDjV2QNmHmQyfNZTsDRatYh0JwTykXZo)M2YMDUVmjt9lU5NVyDdhTyI58BnlXXHopFWPgFe)jpt41t0((KpVDq(s4mNObQiD9dkpGvqEpFwiT6lQfRDW(XT8ywr(1w)cpoVeDLeA3hzHdfJCCTfeXNWK5VFxYJuRNnzwP5UWK57KLOG(DB6YE3F)n2L9d2qxw)F8n2L94xtxg4XhNCLMzvY(0dRYgkKLFBlgLWJLSh0aPoRhVvAhJY38PpgL1zeRjRt30A2)VbWbzd4ZxeFusGl7ZlzH8OUp6AATtY3s5otxkFEe5ZcnCh435fRUyw7Np7glArBnYQ(xNYQd0cbLCFQPNAYavKf7RDcQlxvq1)VKeupfnWFXLuWt4iRfT9pLSzZd3Tp)(JeZRNU9flO3ibjf0T4PpsHF6w7kcR3irc5Hw6Lw6Jw6NwgGwgKUla9SOksJ8fSK8brBoUcfq5nWIBYohcp4TczT)kkJsz1MSpJAZKCRx10uSzWrjM2yip(hb5DypTdh9TQMJITACuhf7GVd(l(IB4t30zHxj8dnzePE78TD(khr(ch9v2127VWry3hw1x1OW5vNnruX(IozFT4RAuh6S(pEWJ7PJYx)R7)9
```
