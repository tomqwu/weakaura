# Druid TBC — All Specs (v4)

One pack covering **Feral tank (bear)**, **Restoration** and **Balance** for TBC Anniversary
(2.4.3 / WeakAuras `internalVersion` 45, `tocversion` 20501). Built with
`tools/tbc-weakaura-creator`, 46 tables (5 sub-groups + 40 elements under one top-level
group), **zero custom code**, and locale-proof by construction: every trigger matches by
exact spell ID — never by name — so it works identically on a zhCN client. Every
spec-specific element is load-gated on that spec's signature ability, so the HUD reshapes
itself on respec with no user action; mutually exclusive elements share screen slots.
Six of the 40 elements are the **v4 PvP layer** and load only inside an arena or a
battleground — in PvE the pack is exactly what v3 was.

The whole thing hangs off one draggable top-level group anchored at screen centre `(0,-140)`;
the five sub-groups below can be dragged independently.

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
- **PvE furniture is not suppressed inside arena.** The threat bars still load in an arena
  party. Hiding them needs an inverse `size` gate whose open-world behaviour is unverified in
  WeakAuras' source, and shipping it unverified risks silently unloading the threat bars
  everywhere outside instances — a PvE regression traded for PvP tidiness, which is not a
  trade worth making.

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

Three more prompts share this flow **only inside an arena or battleground** — **CC on Me**,
**Barkskin (Stunned)** and **Target Immune**. See [v4 — PvP layer](#v4--pvp-layer); in PvE
they do not exist.

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
- **A PvP mana prompt (v4).** The Innervate prompt still fires at under 20% mana, where arena
  play would rather see ~30%. A PvP-gated twin is only correct once the original can be hidden
  inside arena, and that needs the inverse `size` gate this pack declines to ship unverified —
  two prompts for one button would be worse than a threshold that is 10% late.
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
`(150, 96)` where you can drag it wherever your arena UI has room.

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
three existing elements — so the uid stream is untouched. The script round-trip verifies with
`W.verify` before writing and reports `W.uidContinuity` against the previously shipped
`all-specs.txt` (v4 reports `stable=38 changed=0 parentSame=true` against v3 — the 38
pre-existing tables, all stable); a re-run with no source change reproduces the file byte for
byte.

## Import string (v4)

```
!WA:2!TZ3ECUXv5zNXkgSvsi2RVeSBciBIDwNMyKgjTskqmiPv79DL2rAx71XKvJ0C0oZUJMz8mJ2lMRzXemuOxwGukL8bDPq6xkf(XcfcfOxCBPTCPFVDHKo)APT0TLw(6fO19cT0FL2Z5mA0LDLK3BHyBYFSND0zoZzM5888(CEpVNZzygTT8FW7)sV0LZXNFkbDvT4QYQ695YLRuU8EYGATLxvXuxvwgjexuswqhP8KR0PEjjbp3VNEq8YMIx25NC8tG02VZVgKxH3t7Cidt1tODW6ZngVmVsE0j0oGt(ze1r8M4ZG41pH2DS6SJZByIWN4fx79YZaskisnoHmQ6DO2Zusw7oB2vGp2u7Wn(QiNBLCQ6ci9yLBx02tmzPlCbEDbpzuvLnL00NnzHcgitMCA84MftNxMmXIJRWOYYEsRHYBKZUEe1NZU4NFrD0esQkzMtdXnHUAjTfTlrAPlG25sskfu1lYBIlH7LSpHnKWWW4Az(sMIQ6j1iN2WDom4uqAc3685Pz0bNHjVUP7CfKuKmeDhd)pt3ZBQlnXeiDJHoUE5dFSyMK7oFjDE2ltsn0qYYscghUnVXkHVOCAY8ZH0NNMFVcgUxXOuo0043Y0LkuqA2LgpE00zgpDMOCzQCQu6i8P4sNkXadCLsgOeZIFUsBxdz5u4lImCVOakhUgiV869KyGuDnYalusP8JL7LeKmMSKc(TzAelVSS2E5PhNX(8dQkG(O3u5MRecy22EtF(s4gFpDvc3CFArjt0LTpRDB9UxGxrYUXSd4o76YiEduAtmynHP4leosmfvf0Yc43FsjgN0MOBGWnQcgZtkk5PechRiVKsxqi8faHHiWdaVc8)VRvNZcgi5cPuLumZfpXqzsWDujbT9wHFHmulPNhzCfCbq6k8YJIVx476dTubDCld(PI3K31vWMfyaUlswK7EU0X5sKyOfnvZpTD53vQdWIRYLMU7mNT)butmWKNMZipVmY1IyCGJsTmCyo9QGBeCTi5nsYMYetwLxW9s23g6tlCQl5DrdmfEQtljykEGfLWfpn9H9oVj42zG99nUjya4ultldNQjTXIrBV19Bc0el6izsgJC5IWl9Hpo45XWTp3nCpawfGWpYzRxGZ6yWXDppMHmoHRLfobCVW95gUF4KWl3DTxhKwB)JGlIN4I8esosxYWukVr5Qagzvxl4f8bSykc5Hy88oszUGx9dbpiCQ5ZXx2yk1n79K(cssdfMKYg0fMzAWBs4ciXltF3S5qJXa98aheoYse7eCfmo(VlDqT2mrZAoUHiVG6mNPSqWc08ijA75yyUuE8lTi9D(yhtBp1CbvTOxXoxhQdmS2(O5Gn0vje38uqjwu8pVc9eylmKanZhzzBuCSY39ltp)KLWTqfMdo1I6eObLbNzSHsouc4i6yccPmlsly1wh7h7cyHET90LU0f8mCjEbcD0tMmAER8onUTW0419InUakp2ctECnD8bguMrTnnopCltZBgmR8068AZF6YhSCLBnvri5izgO3HsuUTQgs6s9o0qj4gNR3U7jJ2jUkpsynvfbQ1mxbzvvD7gMPXpD5KrzREljcUhQCJOdeQDSRsLBNzUHkvmhsFA4ilGBuTn2w2(FLFSzX0eNCuldqL)z(QOF5CCE2kB2oocRTbbC(Lb(50vorK0eIM3f0)OlqSCYlZByKnNj2YxX8GCflH7sYnhn3JNZqI0dhxNCJ0BNWJEq4TLngwjp)bHh1DmsTroyfkhpg(YfigVSr7StT9GR5Ocekesajmi)SIWEGxLT6q8QwthY9QlPe2KF)6LTqGd7UwdOZWSa1C0qsaXrrqOdIA8QvuFLxDnw4hdFHUH7Yn8sCVe9w0dTv5b1jawjDexCzeVchVSMiVl7hIm2NrR9EjcVf4ZJohXBcClumE9ZnsV3F1FD)PPsA0lte6el1I1WbxXUGQArgiQlUzi2D)oUHyqCiXsxiVO(qMDi2Zz51Lui6ZiXYpvsccifUHsmAcULu1LWqevLCXEsY17ztouMOda9D4JZLxeLFQUap7C(PXvbpMcmVKsC1I54n5MMxUeI5OQAh9bFq98IyFwqgh(4Wtq9lBEnSljiDZ5G3lChUVcX5TjO0(kklKIf6sEHbpamuzD8ppdrhhsYaPGHbUYI0F6QITCPuNbPtexxqJCeXeYvD6SltOEvox2gkzdJE1KNHtxRQmCgQCC4GvfL9f0fmMiC2YsVWdDP9bNJbEnh9yAW4ulhil(vGhYb5FeqGbq4QPambUOIGKDLpjmfGrnfqf0GZd6GbmZHGzzGPZInBHxl86Gxp8gyG3OD99MYcpceaM3f8MX2ytdxm7kK3vQdqtPOoJsw4TqmBG3on9TEC4sWBZ22AXQfAxxCu4NGwG3b8oHFsQ5d8t5y1a)0yRe4NbBFalWaVl4DVTyiaVNheEm4NfEVUGFo49b)8vzU3m8(j0w4XRqzvNix8ZoPm7zsMb(aIWhe(fGfHpeHlc)IeEi8HHpc8eLzDWVuf(g8)Ls0GNCZsTGFzkP4JYupV4xzBLcXgK(WssISAc0bPeOR40TmLdFSJTbztAT3SEhO1xn98aLQJ5nDwT7U1xQDEWfSjPAV8wx612R76JtdFSMtJHp(U6z(RHyV7CnS3idpwsdEuA2eJ8JKSx4tSrv)wAn8q4t6WXGp12dPH)WxdrAEbRH00(OtRNQZZ2zIC9TTsAE)7y1KMHQLgSOjn0fKrVGDstFcKjMgq7sP6jYs4iP12t5OCKwYSe1nbkPzDZycts83ygZLpM9DtlVzfXoT7BnAlvkudewAmxt7iTOsQOL1YUJBGR2vRI6us3y9BFvORxt1d9lCn01U7CMuPuIPhAUqnIU6c(WC8tG91Bvu2(OYguFNyTtDHjWNzlqGHpd8ueLRpRnlf(12(yLWNZrh7Z3e6f8fUASh4xF7MyCnLo2UwdXitoLrMOJb6pzFM1rmU3keJfQy(apXrd5LqpoLd9Ggo3oij(OeJkxe8BcpHRnotYdP55kLh1fzK8KXqQT)4deDWuzsgBGOX7hpGYEZ07OjS5vnO3uxnP30kSR7apG2kHRHLoYGi00a00GbXatUIs66Q6I0EX3pU18WUxiNZGA5InqIH6e6Z9MgT02RGKrEDKjACDNqFvhc(yApq1bwgvqiPIX5onIFQOKOQEUbrcs8NR8qqnoND0khNgOYtAobpfUjwpyKgBara(Dd3(aUieIXeNV6DmXsST3zPKrm87BkEkHGy6(Mpso7G8iUXu(E8DAJFWVn87Svqh43fZRiXqJAXZwbtGVyTWb87b)(Bfia(dwvlo8LAq7MB42ty3SbFzs7vH21slpWiPgAUoRP9c(QB5MQ)gNMQvSDfNmoCEtvDST2cvgDCwN2ro6ppkR31Bd6AP6UAzlAb4i5WDwBG9V4vOtcADYsMKgWLZziQlPm18oH3ogPEPTPnOnhxlWY0djxASc8ci4PzXxbTiRla4wQsCTraFtmZmI9WgEWmHQIahBJJa7UPia8)JiWbvASH)iSS3MH5EvBIPnoFnAJd81HNgEM1xdj8hJlR16Vn8wxfjwiF)8LIZ2v8qj2InHVuGPYK6b74j12JZetmaw3IeZ7Qtfx5PhRt6e1uDgY6IhPlH80LKoYzA6Qm7gdivaLtwvTy1P)JdnzPPrkuQx17ghc76YmMIvlhzkkYJ99DgE9Ivl3GQKz2shPDxn(27m)HhY50DIkQQZllDbjLj8WPYRd3g8IiU5ShyVqByK9wji7bGdUtc6)ITDrad6yKUwyPIlqhfEzhUnVoJJJW1iSPF8SnySC(XEzeC3BE5nBSFzN3Ky4wDJY0ccMtzjjwASKTNu3F)YP6wb62f0JBOxxecA)UjSIl9YOU1HFH2hDSSlNxvvwqDgL0ZiPHYEzNFsM0mX1(g)rk)gZ53FOabXiKssf55YIF9FQg86R3tuUb7AKbQTr4v)qxzkeslkjmZMCeuxK6siMj3tFpZYtiRotx6OZxcPKFoBjUyK8eVmwYSB5YZiI4cK8sBpBwKdhGotDhyjYXoZKaTmvdgn9CorV3Eooi5qVJzeLYpLcYWW180FIhnXY5kzAQQKCAKUm)C06ImRVg7LE)IzpvTvI2OXMpAJNcM5i2oNUne7YlBp9hXsMjtYbHzUd7kUa1R3g6X7WBmbI9dCydLVfC733ntgXSViXsgTJHBpQirNK8a9(PEZpVdnkBf)u)t12VtMeVC6uYGefBHSevShhpQISelmS7Q2whek)rS1glBDSQCUR1KdXeOgFCZzyYNFkd4jAli2P12EL2(SMf7H6yvkZkOz1KS70lJuru5YE0x5dwPWKPk9K(ojbYjYbrDTA7h4Vnl8TBUHYdGnuchkmons4oOPHG)UMzUa)91BOa)dvnnEGNb(hTnhGVJi8DfH)jxW)8bGRWa)l2n8)Ryon8Vb)7UGVh8Fa)N7f((IBhXc))cM5UEwJejt66AAHZ0xI8j83EXG1tIG)7QSNVb8d2MzkU3y4zzP(NKnuiV4)chlsOarIfjI3qCSDejIFoFDeoyioFH8hXln1hnLLJnKxF(EEa3gWVFmExSJtmr39pQqGmbAoE)NTTJ3vdlIfZn1alDlgMnLfoTRWo83cR6t2CqUVTciFTsFoekZ2vhnvMxHkuMVYoiJPDYE0fK160S)UBoN5pFBNZuT3e4)btz830osSPuSBtuQ)eSatGy(8gmCmFb87ngR3i0eFX83bBOyHJ4ZBSiH9JLFchGCuaFCSbzJeHOef2hnLDZXhVbq0zTmisNmiXtioiBHXoTrMMtG(lEwx0X)2ed5jXKa)DqsctsIGtWmbCIpC)sbjCIGDqscrsctzeEFEgrfgXyygXPNtPKOErFtj0EZzeFZRByetglyWqE5ydG9lHMgKM2bnne1le))iRNNvcyF99QWvkN)(sil1(5pFZPa)Lpx75zza(lHnVz9rscqscssika0oeyjYaSKoe87NKeGKeKA3t9pnC4Nh7RR)G2NL1BNPg40ZoTuZH(vUgb6FslMxGfZl0Izxwm72IXTfZTyXCRwm3MfZlYI52FEOToH9(tDEw2c8bfsR0CO9V6A)XxuEeNtE0irIHhkzWyrcGDdelVt6upcTt9iHF(bwAd8VfmWNozk9zmcmYPhXxZb()6NdbEVXiX0(OJKc2X7RM4vRJuUGesGeYBKINu6Qf1mRg2BY6uvpV9kpvBFo5MunUNbLmilF3QB1LEvuq6tZBICQK9vns9LKDYSY(CjJoc5rTanM8vQSkbwpECpQkEgevnU(X41NYykjfpTN2Se(wju7UYHUWv80BXILuq0iQt43)wu(TDm0jlw28OBBRge9LYRkxQOsAsLzVCcYzhStoEzPjuGtPByYt2cimKiF3V7AMndD7T4bklnu)D7AEmyuUEAtKgC(9FzH5u4lkLNUBBGdUZygQ6Mq4fMqxYEP0FlZtoKeF4JY1jNSurjZBHS)egGCK4k5vvW3EfZU4ZBQQNJlAN9os6C68csLmU4Tcb39cyS0ow1x8GoCYk7sQOYiDtJfluswoUKEEz8tA5q7)LzibX)2L3ctEaMQB39tILceiTzo1mIJkK8s3nmetR1IiRWTVOZePTCDRX9JgWlKgYqXnmsHHocSnswT9sNFZAlAwTdw)YJ3z2qXdOUYsJ7s7LZuNp)uXiBQb7kbBsG0LYNwuDMKkzxUUFUKb9FCiEH5ORfz6YRDi(IODng2oLJ(ZY7oKdfVCWNjMbtOJmmW0yY5pHwBK7dM7OQJuNgPJXxu2L1XpLPDQoTduVrkYoMXlxzD)skeD1VqEvSNnr6u8sFBYQTpYXiYMCQ2I3uf67TQcnri(7Mf(ECPKMfjxrN2EjZqsdq1R)ozjQ4yfBQADR1xFuB91fP7na6kiFDR1s21vK97vVyEUMNQRMbYVnohFojzjZ5gphM)QxYqe2JftoB3Tk0)z6B0o6LFQUND1sZvwjlwm90eT56Nw1LmKXiuovtt1I0PE2VZuSUA96lTNfOB4j605yGXcYoaGoPrWrYLVKbUcYrlWC0wsYDW(3ZA)7NUnFW7LHcK0SZ22Cc7UTzzwGURbi168o1k5EVm(yfdzYwPbFkT96CUmozJFWwUmRWoJS06MwBz3krL(WKOphA9njKn1zahQMfZ0v9hO86T3EQVxdr7hMUfuM2AXmtlPRr)M16AqfcyUP9nChdMtBKbB(KmyX076IaAX8AHN2I511CANfZR3I5nahXI5nAX8MQqUSyEKAjwwmZ7WOSyEZwmxKutwmVflMhfxxwmVv8l7LwfV4QlxxxOPX0IocSmUtV8IidBrZLTfnl3F)MGYCVRdkt1nNXguCAD48xTiSfZS1UDDS1HOsSJRq2IEyfo95W9ilNJh3tqv6WjIpAH4PMuYVAMwOh13na0HhU2LbJ2bQBVbuTl4lxB(K1Gu51jdD3Bv3gkiBlxB7xAVwmIwmswmtIFANYIrMulwmf315)oK3Ff7EJTyuTy0WL48luXNvlgJv1dQfJjUiLYUPPI0wx6Qq01MQxsBpduunRDZ9Ss9)M0)iLSsfMQJQAZERJRE8wYvLj9wOqSkRYutEM49vkEgVEhzYwWu7)geHRT8c2AJlv1XMvQAD2HuT(prOahTzUnjqgfW4fXJuRg4xefjzOo0s5ZGRfW)a3O1VLF)HJ4ZI5DyX8o3(7HICk)RAHt(Se2N)Q0vv9yVjEa5QfKXdhVggWfmpb7KDzuiYjAvxvdEnpdyD6r70ufGY4TtFbP12tC8G1f8eVY3yecjyl5vBlCr5hMU1waZKOFGdi72AXYKPM0nYXz1Mwllh5BicE8c17G7ard0vQEMoCXr0AHdUdDJan5HBPJgJDNn0rJ5DIEvl9ZO2T1YsL)G2qgmxS0zgzis1942X54k2dEUY5Z2OT8Yg2xf7D03MBu9FelM)pI1PfDr8l17UExsSyEpK(J(yeTjC7eLtzX8bW5)bxnFQy)xGZFIKSYQITq2j5nkYoLhi97JTJaSX85L1ljHnwWGrIWHpkuyUabd4pmNFFSSb48fjyOaC(deiKVT2uQF9G6uneRMPl1eoKM05ZpM0W9H0AVfAsPUMNd51IPB4db74T7So2J3zLv)EDzLqrN8LT6q1Kv9bo0jS(0tLEgPcMfrkcoZfan3HOJf4EmSpnznj7ebE76tfpwmsu7TlNti(PNZrIRU7sLbyvjQ833nxty5TygE3B1yYBXW5SZ(SyYqsgzTrF3IzuNaVBXC6QHC3I5mWb3PfZyqylMZElwmp0r560I5C4JEnyf(h2IzClMS0GNBXWxnQ5v3tbor21WIj)QJyoZ2saZJZwmpIBi1yrzjEYUEeuwvhulsI6su5z4NZWPJkSqCJ6OA5Y7Qc7DoXZcJk2L9UVQw9fX1z)mr3eZoNfZNLeQ5YFk0YARmm8fqNpAPtWR2ENTqz4ta)arQYq0T)f03IQko8MvTTgx9k773yvBG26MsVnhBWI5Z5Wc2FXgYcYzlLSfH)19872AmV6ODe3q4UfZxOmE3ok4qk5teBurLwG3lTTJ3hUECCT482fmsMVPgaJwm6xBaHBgZ2QWxXH7j1CZ05eDl2DlGVp51VWxpZ34OtwPl6RBqX6xSJ1HI9pxhbNnK4mZviAlqXp11VOySVrdrrT2wRpvx3GN43PMHNgPtoTmQGPHERCV(x96x88I3tdXZRSkFGV(rH9EAkwE2oMzQ56C4UJOgOfy5N(64oiVZM0b5Ix7aF04LuEYCObkPvtNZQaWasN)SAdwC6CjY3ca8ZC9la2KjWZI5DDJbaoSxLrc2d)uD5f1ca8PEodajbHiwNjp9qWoEGQl5VutNYtgYxVbKPNoXJLP6kYlHcQ4CoNBLAwvFKp7dnAb6zXm8TTTfja2mjt9dVybSunnhniiacBplBUbpVqWjhBy)jpt41tyfFQxWoiFVuMxYevKUM0u6N02rSSG0AV4gSE06fxYtyhGzST3k2luJkJsf3MFz6kvRC9LfosmYXvN99pTfZY7sz4Q3flMVwLQZI5RtQclMNolXq(zw1L9U(2BUl7))M6Y69JV5USp8g6YaVS8kZTA1NSpBO(SjdukyR9eE0KDI6p1z96BUwO98v221E2GbjNSkqtRx(l9(H5cWYgHLkh80S(iRzeT9txXKEiFNC9KUu(8iYN8x4UXVXlvzPs2Rq2w(bp8z1(j6D9IuhSbOKspAPNCIaZPi1tlqPVQdk17ZrO0ZqJ1yCzv84CYARE)9j7r5WDW63FKy(82bBSG(IeKKq3KGSKe)0TjueoFrIeYln1hnLLM6NMgGMgKUzY8UKgsN8PjK81ZAE(cfq5nXynzROGB6wHSWsLuqPSlt2RF2Ich6QoTiBjouIPmh0R)Hr(gYBl4q)HotjY2nhQTITj0MWLEj19n(5SWRc(wwm5OUdboFoCiFkC(k76A7pfoypiwZN)MW51MnruPEIorpn4ZFtBgC(pzWt6TTPV5x))7
```
