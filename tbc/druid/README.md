# Druid TBC — All Specs (v5)

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

A horizontally-centred dynamic group of 32x32 icons; the WA cooldown text is enabled, icons
desaturate while on cooldown, mouseover shows the real spell tooltip, and hidden icons
collapse their gaps automatically. **Mangle** is the exception to the "quiet readout" rule —
it is the bear's every-6-seconds press, so it also carries an orange pixel glow that fires the
instant it comes off cooldown. **Enrage** is bear-gated *and* out-of-combat-gated: it is a
pre-pull rage generator whose armour penalty makes it a mistake mid-fight, so it simply is not
on screen once the fight starts. Restoration sees **Swiftmend**; **Nature's Swiftness** and
**Force of Nature** gate themselves on their own talent (so a talented hybrid correctly gets
them alongside another spec's row); **Barkskin** and **Innervate** show for every druid *except*
a feral one. Both carry the `Cannot be used while shapeshifted` flag in 2.4.3, so a bear must
drop form — and its armour multiplier and Dire Bear health — to press either; v3 gives them an
inverse load gate (`not_spellknown` = Mangle (Bear), 33878) so they no longer take up two slots
in a tank's cooldown row. Tree of Life whitelists both, and a moonkin can drop form for them.
Per spec that renders as Feral → Mangle, Enrage (out of combat), Frenzied Regen ·
Resto → Swiftmend, Nature's Swiftness, Barkskin, Innervate · Balance → Force of
Nature, Barkskin, Innervate.

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
unticked.

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
constructors** (nine conditions on one aura, a load gate on two). The script round-trip
verifies with `W.verify` before writing and reports `W.uidContinuity` against the previously
shipped `all-specs.txt` (v4 reported `stable=38 changed=0 parentSame=true` against v3; v5
reports `stable=45 changed=0 parentSame=true` against v4 — all 45 children plus the top group,
i.e. the entire pack, unchanged); a re-run with no source change reproduces the file byte for
byte.

## Import string (v5)

```
!WA:2!T33E0XXv99NXBm4SHqSLFeIBciBIDKttm7o7UA3nqcS7QvwY6XUA2vYwoMOD2DURMrA2zgpZSR0AEvejbZ7wbnLgcNsfemKsHtv)DO0wAHiEDkpA)wD6jDaCP8tqPqlh6PUfAlTq79END2xA1AzjfITj)HVA27CN7mZ97NVF((9(979oMzSoY9bUNZ9swolFUPf0v1IPkRQFCxUCL0LNJgqRJCQkM6QYYiHyIsYc6iLNCLE0lkj0590zFiEztXLC(jh)KiT948RH4v47SloKHP6r02xJ1gLxMxjh6iA71P(0I6iEt8zq86hr7wAU6y8gMi8jEr1FV6CqjfePhNugv7ou)zkkRDBR1vGp2uB)T(QiNBLSQ6ci9Ovgx02zuzPZEwEDHotRQkBkPPpBI85nqMmz14XdlMoVmPJgd3HrKL7mLgkNrw7(ruVSDZpZc6OjLuvsxwdXnPUArTfSBrkPZI2(Isk5v1lWBIBH7fTpHTiHHHX1Y8fnfv1tOroTH7SyHtEPjDRZNJwr3CgM86MUZMxsrYq0Du8FmDpNPU0KtI0ng(W6vo8rJAsU78f15zxIuAOHKLLem2FhEIweFrz1K5lJ0NJwF)cgUxXOywuj8BzQI5Zln7ItelsQ0tKkDeU0vpvsDe(uCPsgFWbVyrdu8zXpxPS7HmCk8fqgUxqaLf3dKxE9(IpyYEhDW5lQu5XY9Icsgtvub)2ucXYllRTlE6XPTp)qQcOp21vz4kUagTTRuNPiEWVZElIhUpHOKjAj7ZApwFdZZRizpy2nCB9UeI3aLYelSM0u85dhiQIQcAzb87pPftqgt0nq4bvbJ5inL8ucHIwGxsPxii(cGqqy4EHxo(V3EZ1mVbsoFsvjfZSXIpC64ChusqBxvXxid1I65qgxe3aKUcV8y47f(U(alMxhpYGFQ4n5DDrSAbwa3lPkYDpBQyCXJp8cMQ5kz3(DKCVS4UCXshl9Pgyq14do1j4mYXlJCTawoWrHwgoiN(vWdcUwG8gjzdzIkRYl4Er7Bd9PfU)Z5zbdmeE6tijykU3fKWnpf9H92Uo4MzGDFHRdgeU)LPTHt1KoyXOTRg(nr0enYOPteLC5IWl5bpm05JIhFUd4obmlabFK1MVax1HGd7EomczccwldCe4UG72nCpWrHxM76VoiL2Egf3KoJjYta5iDjdtPCgv6cy0MUwWd4fyXqeYdXe5COYCbVQhaUp4(NllFfLPKxVNJ6naPmyisjBaxyKPbVjblGexI(UzJHgNb67E3hCGfj6j4oyc8)o3(06WenR5egI8cQZCYkebZtRJuOTZdHXs5WV0I035dDiTDw3futJEf7ADGoWiA7MwdwrxLaCZrfkrJG)5fPNaRHHeOv(gx2wkoEL7(s0Zpvr8iu(YW9VGor0GsJRm6WjgooCaDmaH0MfOnS2OJ9JDEmrV2o7vx6SDosrEbcCSZ0P18u9DAcBIPjA4fBcbuoSgM8eA64dmOiJ6hACE4wMw3myu5j051M7evoy5Q3AkJqIrtpy)dhVYyvDG0f7F4HJZnbx)hRV0Ah5s8iH5uveOAZC5Lvv1ThykHF6YkJYu7wsiCV1kdIoIqTdDj6C7kZoCXczr6LGdmpEq1wzBz7)u5XMfdtCQrTIaQYpZvt6xPgNNTkQTtGWCBGFNFzGFoDLvejnPO5Tddm28enNCY8ggzYAI18vm3hxHIytsU5O1E4SgselCC9WnA)9apY(G3sMOyM8C7dEe3rj9g5GvOy8O4lxGO8YgPNE02jUNJiqGqibKWq8Zkc7eEL2SdXQPnDRUBULsyv(9Oxrdb2V76vGojZ8u1rdjbehvccDtyJBMr9vCP5yHFf8f6gUD3Wl29I0BrF0rL7tNiWkQJ4IjJ4v44L1e5Dz)qK2(mAD1pH4npFo0PjEtGhHIYRF6r7)EQ9R7jfLsJEzIqpyQwmho4k6zvvlWarCXndrV7Z7gIcXG4lE2CI6dB2TyFNIxxsHWpJeR8ujjiGu4go(yX5wuvxclIOSKl0xcU(pvIHthzq447)WC5er5MUxOZTpxjCxWJHaZjPetTqwEtUs8Yfrmhuv7G339PNte7ZcYy)hgop1VS50WUKG0nldVx4wCFrIZBtsH9vzwinl458adTxy4k84FAgcpoKGbscJaCviP)K1iB5sQodsNqUoVg5iIkKRg4zxMa9QEUmTKYgg7srpdNOEwz4Ku64qbQrk7nGlyCr4uvOEHh4C7gond8Qp4H0GjOAoqg8RapKfY9gbbgaH7M8WK4Mkcs2D(uW0awQPaQGgCgqhmGzUvywgOugSAl8AGxl86Gxpd8gS7VFTmWBe8dZ5cEtyDSsWdLzfY7k1bOPvuNrjd8We1g4TslFZhgoh8wS1TwOwJ2Xdng82On4TdVd4DsvFG3LJwd8RJ1sGFdS(bmpd8UH3ZwIIa8BEFWJc)wW71f8Bdpg8(QHCVE4XjWw49xfYQoz2yNAkz2tMin87icFa43fwa(GeSi8Hi4q4jGpmC(kOo4JufVbFukqdEYnk0c(9OGIpgtJ4IF)TuieBa6dlPiCZaO9rbqx0XSmfdFOdDzIM06ATSoq7V6S8afBa5vkJ2D0(l1Uo4S2GuTxw7B9QT6U(W0WhFTHXWNyh9n3vqO3TVk0B4rgpHbpkfB8r)Ls0l8hC5Y(T4QWHWFOdgd()T1aA43)vqGMN3QanDnwj9K9CQEIN94BPGMhFBndAgUEyWcM0qxqM9c2jn9jrMyya1KsTtKHGrsPTZkr5iLKzrQBcuqZ6gXeIu4R1iMLoK9DtlNzvYoT7EvClvBuliwAnwt7aTPtQYL1wZXTWv7ADrdmPRF72pcgUsNyjXlxXk4vBSlge3eWTIT6sCyx2mlNHvRKwM5WpjMLlWRKH1ePKzbZzWCULZlvcH91MECgiuMRiG6p)vb1pwpZKmPsu9GLd2kOUl4j44Ne7NytW9JtPCO(DXAx6cd(p5Ma8d)rWNIW69hBJWH)KToen8N6Wb(PxdOj8NDPqEWF(LnOc(mxk0ufAWsWNnd8uzGLYaFUmWNpd8fUIbWSJvbysNvz0j7EWbsCCZgam3vvaZ8vvjHZFWGEiWM73b2qdrC3KcVuat1lc(sW5DD5JW6Km8CXkZKJeDaY8s12tSbJmuY0jIoyKydGNKA)P7FS424TwyH21AyHUkQ7wWtsUAiGyPZ2imT0pTmqaSGjBbjDDvDrQNb7bpAUF3ZN1zIYCrhm(W9ah39gwAPTlbjJC6it0e6oHtRbj4JQDV1MSAebHekgN(ei(PJqIu7PhcjiXF6ktR1402raDcAWppQ5K8uXnrRclPXkweb)na38GUiaIXfNR2Dm(ISD1tXeHn85DAEkGGOs)Moqw7ahjUUm(xD(oV)TBl)GVm8v2msh4RIXvK4YrzcyRktGVw9Id4Ve(R2mIaaAAeh(RBX4MB4MJBpSbltgVY3Lwk5bhn5WL7PUXl4Vztpu99CgQwX29EYC75nv1X6AZxDg3zCgh5O)8GSEwVdORgQ7QTJO5HdKf7aGb2NLxUojq4jkAsga)6zne1LuMEoNqMhL0V0X0wmMJ7f4RtpKCPrZZlGGlWIVcAtwxcGBSgW1wc4DYzMrSp2qdLoynjWHU8La3WAkbGNMqW93wDWgSW0EBeK7LCiMo48nOdoW3eUa83T(giHVfUT)9R)XWxqtGyHCdWxmgBVXcgFtoe(saMQjke22tQTtNKDmiM3Ieh9AP3Rsk36HM8NAzDRxEKUeQZEL0roP(RAgtgukpkRSQAHAPuKdnvXsifk0R2DJdHDPzgtXATJK2JCy)PNHxVqT2nKkjBz6iTBV13ENCsERoNUhubvDEzPZkPmzNCQ86WnbVqI7p7e2f0bwY(cis29c7B7eP)lY21bSqhlPRxSu11OdcV093HhN5gsWAe00VAMwm)qFyVpcCdBC6nBz)YoVjrXJ6gvGfezofLeFXXt0vcDFdiN8ykWXCb95g63fbGoGBcQ4CVuQ7E4xODtNF8Y5uvLfuNrj1msAOml58tsI4ex9B8hUYBmNpFb9halHusOiJ9E(oWUgU6xF9(IWnuVJoy9dcVQh4ItJqAriHU2KJi1fPUkIrY9D8NE5jLvNPxD0zkIuYv2MIlkPoXLWuMhtUswweNNuxk7mKroCqA2)27IKJDYobTn1cWn9CozeWoVjKAO3X0Is5Mwbzy4Ao6pXZqz5SfnnvvsucPlZxM2xKmjBSl69lQD6FRgbtJnEemVFyMdy706wq8qxYoLkrtKoDIHGzUf7oop1B4w6j8ixEee7b4Wkk)q4MV7RNmlCVHJMis3J0vercpj5b6XPE5pNdmktv)uxrBpovs8YPhjdsKXfYqyXE)4zBKHOHHDx1w7Ga5pGn3yfTJMQ52xvnevG68XnRHjFUPnGZ3raStRD8kS9znd2d1XR2MvqZQjzB0lTubuL2EWxX9vTXK0VEuVhLiYj0brC1S(d8JYa)lRTIY9IvucfmeUmCOUPLbH)11sDbUyJkkW)wnvJ79PH)DB1b4hlc)er4)Wf8FUx4)Ib(P2d8)3ymn8)a)mxWph(FTyUUDzXWiUfGOSy2gmZT)mgosMy9QKWjpE8CX91vHanIJSyU(AiOVJfZ23IHlUV8eQv47Fs2Gb9G)xOOHd6pC0WH9eKJT7WH9X5T7qbcY5nOVWEOLEPLSCSb9417Zj1Rk1VhSqVq3hzYJnWyc(t7Vnc9V7wVqVwGtSyE(TqN3IzhBiDDQrXU91g97JU2s6JV5K0xPy)HIB2QS6unXfvXnF1TrMG7u9PliR1J5ahRnaN)HTEGZDvhW55Hbo(wtdl2al2TiG13aZ14pQxpbcf1RFFEIY6jmTWBuFDZgmAOWE9enCiFyMOq(jh53lhBa2WHjKsH8slz3yOYRn4FwnoIy0bjEeXHyZp(jms3gy037zE(hFBrWKNeJe81nPiePimUadhWfEX2Pcqagb6MueKueIcl88CWI6HfJJHfNOSsrr9cENwOR2al(hV6bwmv0abc6HJ1p2zfAzaAz30YGuxt89lZ(KwntNnALHRywFhpUSuxN5mTbh89Fw3N0ks5VmwrN1lPWpPiaPGWfqTpWsieyj2h85Ju4NueGYaq9CnuONda0S5HUML1tpjh8eZwsQnY)FWvkY)N0I5MSyEHwm3SfZoTyWd0DyXSBlM9yXSxlM99CY3M55hi5zyzZZhqiLsBKV)txfm9JkZkDQdgoCu80ndenSFS)Hy2EIH(Wud9Hd9Ct(SQ0)HXs)ujsQpJH)rpXOEBJ0)F(ztPVNOKiGFWrtcB7XQl626iLZkHeibihP0zsD1cAM1csozLYQNZETVQTBNAtOgRZHKmilG4AB2M(vuq6L4nroDYURfx)IYovwDN2KwhH6unpnc(v7SQHHpwSovv6CiuTSaeLxFAJPLu6SRuMfX3kH63xq0LotN9xOqrfen(7eq(trb52rCNSCDZHUPnBi3xmNQCXckPiDM9IsiRDOr54LLMubUFDdtEYMqHHeN8bCxxUp0T3KjOm0edCmxZHfgv6NoePHYFpljuwHVGuo6(9b232JAOQBcHMFsDj7fZ)noh5qs0KpixpCYsfKmVrYczzqYrIRKtvbF7vm7LpNPQEwUi90)OPYQZliv04HEbqGByESS0oY2p0(CaLv3NwrKr6MglKVOSCmj9CY4N0kjcyzgsi)Vz5nrQgWqDBdrXx0V)uMzvtloMqIZDhWWmTNqISg7(IoPDB5gwL9h0VhifKMk3WskSOJi2gnJ2UOzdT(MMrBFnUa9DYDkE62vxCENBxCM685MokzBvy3jyvcKUuUuIQZKqjZYn8ZfnO)HdXluMUAOPlW3H5lG2X4y9uo6pRS)uU1yvcvnrnysDKHbggto)r06GCFWyhvDKAjKow(IYSSo(PmLt3PT3gvsr2ryE5QR8ysJORHgYRIDUhPjeM(2KrB3KJrKTzv9nFnPPVRA00e24Fsg4NZLuAwKCvYA7fEdP0pL0(hNHqL)ZC5qz3Eo2hXMJDb6(tGUk2x38TKD(fzpN1pgPR1zTv)a53gNMpRKSKz5jYIrW6fnebSFls2oFLFGtE8X6UF(Pp2SRIEU6sFXIjXAXp3yIyx0qglLYQAAQwGMSAFojLTzo7ZTZ5PB7kAcGmWYdY(qGMMj4azZv0a3bzPnOmD0KChS)9S2)(cD4fEVmuHjT6mDuw4g6ywM5P7DbsVoNtVsU3lJpwXqMSHEWNsBxoNlTt14hSLRGmSRidTVP9wMntiS3pju1bxFPTCn9kWbUzX86Q5yqLv9VDYYBby7xO(hub7AX86BlMnY3UEFeQIcZwY7iDpuwTrhQnPLWIj56dfAXmhCblM30AJ9SyEilMhgoGfZJyX8MRIWSyox9OllM3IdSYI5TAX82i9KfZB3I5DG7llM3j(19D1e44sZB3qCSXyJU9Vm26xorKHn75Y2SNvm8VbWn316a3uBFICzZsTo8eSEPSfZBO(9oKnHeLTDcfY(fet1PxgBCwolp2OqniXrInw(yjNsYNA62rmnY1cqIhS(vqJ2EByRkuZE8s1xpz5lvzj2q3mznS)gY02LA)5WczvlgnlMZGFAX6409dQfJ5ooZpI8(x020SftjlMzWTy25R6aRfZzBYCQfZRb3KxBMnmCKo6sxaJU2GMmTDuqr1S(DB0kn(BIXskGLsq1aC1gb3aE9WTfVktmCOq0nRHwtCYyhVyS0E8m6uTdTYDTcb2ME9ED5tz19gNYADACQEhQiWGdUw(rjqMyWefWtERoiGikCIGDRL0Rbx7GaPUMZgMpFHc71I5DBX8E26TwroLVMw7LpJj)ZDjmB1O83eppD18Y4zPxhk4SMhHDQEnYh(iT1Sv6R8rbRt3ClrzcQiZDSlKsBNXWZIxOZyv)8NqacBkxDBRll)c1x38v2qdp8Qbr1mMCy4PYWr(WMGN(qJo7oye)9MSVsHkmQw7C2D0RCHipw1qRTyLVVn0p1hNpAQ0JoCdBCHMKCF0lwBvErxVG1fJUZdNFzY1pXqXJ1xKH7pwB7ilMpAJxB0EJhHBvBAIG2ZiVvxWYKlO13SlXvQhlXW9oAQ4R6A8xHNIevRw(mYLir6vDv(C8(Pf3Pu9py8HJfF1dfvN4xlEXsgjw)9o(g5s12zQy9LiXGt0p5lWc3OjtFjU81pxXd2wpph)2APNNZ5eBZ264z9BDk8RHfZhH0hFi7qFDr7OPufLMPv7LQlBpwT3MPB0a98HRXEyty8q4xL3xJ(LAX84ehs(4edt4rhhkflMNOz(KcdCwoFXtWkRk2otoJDnJjNkrw5Xy72pBuVEy9qkyJgiq4WC4JcgIZFa)(cX5ZllRFoVHde0pNp)(d6DZTamUwYYulGrAsNj34sJCCKwxTZS0jUYhg5XIzy4dcB7T6SBiI1t19qrdvfxrN8nx7wRRQgdOSt6EONk1ms5nlGueCYreT2HPtk8onSpnzLT7Kzg7(tfpTCs2CSBNtQFONZHCRH7s15AxnBn391xx6ASyo5nSzZvJfZ4o7BulMhGuC6vNvglMxTtczSyEWAPIXIzcyFB3IjdeYIH)gTyYEqUESyYHpsq0IbzXK3IzsAsvSyQlBk12zkor83WIzQMZKcZwsIuIXwihIBy1OryjtMz9WP0KPPfibHlI8m8LRAIctg3ktulxzV5yV)BEgiajUS3dF1tXiUUn2ezdK5wlMVejfev(m9LXMDyKZIotKIhHxTREAh7WNbZoiszhIS1VwqxqvXb700gKT51e6xRPTODdP7DJHiSy(lCqc7PqlrczTPt2KqGlJfaq7L71M0R4LLS3I5RurM3fkWWk5IhDmrL2jZ)SB9Y893OSC1Y6TkrjjFKTquAXu(kfX4gr9TMiSWi9LS8m9m5Xepw7eHp1vXIW(MR1bTUQ56RIKKnUqzBqsoq5UdmBqXzkNps7KKlDvSKm6fAPKuRJv7J1vrYu8B1AjtnsLOKmkVPHEBD5(ZDvSm9HUZwktVyt(fF1eB7DUMYZt19mtxUNrowyv)TtE(5VA2G5TTggmx8kjrinAkvY3hnmkTlJFnje9lDMtPnuHszJNRDcXVWvXcX1ipVwmp21kcXr8OmAG(4NUxpO2je)Ip7jejbPiApjoXWW2U3Alv0KLs2zAY3ieKzN9GNNtTvYzCfuHYoNBL6wnOKpUiTAHDAXCYBAllsbSPtK8xCXkyX6goArqce2AwULdDgHatn(i(sCYqRNip(PEEBJ8v5zojtub6Azuza7aoFMmqkTxulwhJ9JB5rSJcnw)Bf711t1zWIhZxIUchR0FzGdeLCCTfQXN0I5BVdLrQDxSy()xT7SywH0fwmFNmeL5VBtx27(7VXUSFWg6Y6)tSXUSN4Y6YapS8kLBMbkZZmmqBOqP(TSzFcnwIEqdK8uE8wUDSpFJTE2NlZiPtw)WP0R8)sb7NZplBywkHWfy9swGrA7HUwB7K8nEUZufZLdr(Cvd3b(DEXQlY2(fY02pwNpdBTO)1PSAFTqqP0NwQPM0FzfP(ANG6Bwvq1)ZscQNMgqYyYQ4j)KXMc)Ns2e8H6M1NVWr96PB2Ob8goaPGU1tzjf(OB5SWCEdhoOhAPxAjlT0hT0pTmaD3j6zrnKo5lRj5d12C85ZJYzIf3KD0eEWBfYAswsbL0UnzUQAtUCRxY0NSzWrXN2Cip(gb5DypTdhDHQ5ozRgh1rHoe6q4CV4g(KsDk4vc)qlgjQNrFlNV(sKV8sF1DCL9xEjSReR6RTuOCAZgpIuFrMSVw81wQddoFhnWr90rPR)19)b
```
