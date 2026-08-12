# Druid TBC — All Specs (v3)

One pack covering **Feral tank (bear)**, **Restoration** and **Balance** for TBC Anniversary
(2.4.3 / WeakAuras `internalVersion` 45, `tocversion` 20501). Built with
`tools/tbc-weakaura-creator`, 39 tables (4 sub-groups + 34 elements under one top-level
group), **zero custom code**, and locale-proof by construction: every trigger matches by
exact spell ID — never by name — so it works identically on a zhCN client. Every
spec-specific element is load-gated on that spec's signature ability, so the HUD reshapes
itself on respec with no user action; mutually exclusive elements share screen slots.

The whole thing hangs off one draggable top-level group anchored at screen centre `(0,-140)`;
the four sub-groups below can be dragged independently.

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

Ungated (every druid, every level): the Health bar, and nothing else.
All 34 element children additionally carry the `DRUID` class load gate; the four sub-groups
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
inverse gate that hides them is a field those builds do not know about.

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
the four sub-groups, then Resources → Buffs → Alerts → Cooldowns, then the v2 block at the
bottom of the file), which is what makes a re-import offer *Update* instead of duplicating the
pack. Keep that seed and never reorder or remove an existing element's construction; new auras
append their constructor calls at the end and are re-parented into the right group there —
which is why the v2 additions are built last and not next to their siblings. v3 added no
constructors at all — it only set load fields on three existing elements — so the uid stream is
untouched. The script round-trip verifies with `W.verify` before writing and reports
`W.uidContinuity` against the previously shipped `all-specs.txt` (v3 reports
`stable=38 changed=0 parentSame=true` against v2); a re-run with no source change reproduces
the file byte for byte.

## Import string (v3)

```
!WA:2!TZxF4XXXD9NnxCR9L0glzBLgtCRSATJCiX9ErNU7sJD7DNo9U0jV3jjBh3OBVBN72vAVDxp7E6KCBABuEb1WBTciuAtOTQVKsOapi4bkqHh(zkfOT8WxeKY(afOyOap8sly4hLxEOWmZE79M0DwwsHANM)WJ2D25MDN5ZNVF(oZ3zgZnv7z)ihF53W6zeYoNiwtpMMIgEyxUCnHlpNmGE7z1unXAkkiXysYkIyK6lCL(WfLf78b6CqKGIP0LDULxips)Go3nMGQqNDZJmm1oHEh1NBubfb1SOtOFiN8tjHrcMKNGeWNq)UAm7ycgMiYdED1(U6CuzveTgZRGQ(gQ9jfv0VNM9lixBQF4n)xrF2vYOHfr4OL7x03Fuf5lDjbSyNP00umL1XlKixodKjxgDbs3IPtJjv0yKkmIIsNj1rznYyxps4fTl(fxfJYlRPMArDeFESwr9vTlrs5lH2ZAYQ50WfemjLW9A2pWgs444CTUqrtjnCcD6JnCNHao5KZ7glKLLrV8gMcyt3zYjRkBi5ok5pMUxYelNppcBm(XXLV8zIAsF7cfXc(Umn1qhPOilAC429eTi5hLrxryreEjw(djA4(kgfZGMN0ktwmxo5fwBMyrsMAMKPIWNQYJMaJipIp5eXhD0Rw0afFbY3vs7AinVQqbKH7vfrzi1aTXJhm(Ot0)KJUsr1YFwUxtu2y2IQKwZ8iFckk6TjWUoL9Zhtte9PVLYDxXfjST2sEXIKo)o7ViP7EAjzt0LTFQDF9(wrqv2UZSx4E6)YibdustcyL3u6vdhnQQMkADrs7NwIzO9jydePtv0yjArPFLqOOfeKv7hcs(bqiim8GWBH83J0yoRyGuYnHMSQzMyXhpvC(UKf1BRc)czOveNfzCvsbqyvbLPiVlYB9HxlhM0Zq(QemfCDvIzbbG7NMf9TNjzm(4XhFvtTSZBx(9oXH8rQY1MFGuNFKr1Ip6StZBKvqb5AvcoWZOwgomNHujDcUwL2IKTPmrv0eeDVM9RH91cNEzpRAqOWZnTSOP0HwvMu8KSp275wG7KdoWx5wGrHtVoRm8AMSolo92Q7Ek0enYKPseL(ZLG3WJCCOZNH0)8MG7fiQau(rgB9cswhdoU7LimKzOCT0WjG7dUF3WdaNeEZUR93bj1p4KKI0zmjbkjhHLnmLZAuUkGjB43cEaVGpcfH(rmtwhPmxWB7HHtbNEPmcLnMM428CsVbOPbdrt9fWfHzAiys5ciPlZAB2COZXbd(GDahDnQDcPcMH8VL7qVDt0cMZyijiQv6SLfcwHLhnrF)hJWLYsA0sS28XoM((R5hu1I(k256qDGZOFawoedDnkXnlduIgHC7vzpGyHHezz(yRBJINR8B)YSNpBrspuUfHtVkMcnOuKmJoEIXJdhftii0YSkRGv7DS)SZre613F)y5l15zkkisPJDMkLUNkTPzSfMMPUg2mIOSelmLz0XKlmymJA7AC(4wNLxjcRCASG(stx(I1R8QzkcjMm1OdnE8Y9v1qsxBOXhpo)m8dnWGP0pX14tIOPQkYSM5ZPOPHT7yMN81LrbLU6RKk4E3L7eDGq9JDnQC7mZmEXczq45HJUcPt12yBD7)u(Z2hHM4KJwzaQ8TzRI(LZX5BRSz7miI2g0JZDgKVtxzKqY5LmpcmYuRqTCYQiyyKoJjXYx1Sd(cfjUKCZZY94zmKPE447JFYH6dEQoG3B6OeL8SDapL7O0AJEXvyC8OKFUi141xK(6tF)KAoIiLcHerIJjSGeSF4TARoeRQ10D7UXsktm5piUSfcCy31AaDwUvyMJgYIiEgcc9svJBur9HU2ASW3f5h6goIB417En2RyqwVYPWuaRigXhtbjOYlOOlj4Y(JiL9t07EiQWBoHSOlqhnbPhkQa(cto0du9UhijtsJ9ZKG(isTenCWv0lPPvGdI4IVe1U7Z5gIcXG4RDPSs4Xn7vAWZlGLvP6ZiPYFvYIIiv(XJpvC(10WYeiIPsU6Gj4h68jgpvKrHHp8X5ZkHYox)qN7zP5jvHaHcSKSAmTczem5NxqPiIRln9Uo1PWzLiJzbzC4JdppBCzlPtgsccBUi8bG7Y9vPdElpJ2xrzHwSGl7bg7qW4L1X)SCuDCibhmbCgGVSi9VqvXw(j0kHWuX1v0PxrnHCvNo76uQxLNLEtLSHPUwYZW01QkdNLjhhkqvrzVbCbNtcoFzPx4Hx(aWf4G3ExhthMHz5aPjnbbidK9XaroarQMCqEsrLaz7kFwyoGGAQGgOdxeWGbu6UHf4G5ttmBH3b8oHhfExCW72U(EpPHhd6bwYf84eBS5HNi9vOTv2aGMtvRKAA4jPMnWtZs)EooSm8ETTTwTAH27tmf89YkW3h89d)amZh4h0XQbEFeRe49tSpGv4GFi4hExXqa(rof8mWpk8bCb)yWhe(qvzU3g8SuAl8CvOSA5Ze78ZQ47SjsbFyj4JaFuyv4Jr5IWhNYdHpb8jHNVmRd(uv4BWpbJObVW2LAb)KmsXNMREEXp1UkfYxa2hlnjCJeOoyeOR64wMXHp2XUozt6D3mVdS6RgppqX6yEZNw)n16FQDEWLSjP6V5wx6n61DRXPHF6MtJHFM9o4s3aXE3ZgyVHpZ5syiGs6l(KFhj7f(zVEv)wBd8q4NZHJb)87oKgHdFdeP5vTbst3tnpEI(oFFXZm8UkP5zV1gjnJxlnyvtwOlOZEHminCEKjHgWCPu9bPPCKK67VCuoskBwKnmbgPzlZycrt8V5mMlFm73MEwZkID63)g0wQuOnryzZ5A6hTfvsfTSw6oEtgQD1QOoL0Rp)2xd66nuEOF1BGUoqFLMyc1O4GlgCZORUGpbVqEYy9AGYomt2Gn2jF2PUie4ZUdiWWVi8zOkx)s2Su4xE3Jvc)ko6yF2MqVGF1Rf7b(12Tjg3qPJT3nqmsLrDY89o6ijg2SoIX9vHySsfZh457kOhk940o0dw4C7LM4LrmQ8JGFD45DD9ZK6K29C1YZ6IotE6Ci1pySrJm2ePseD0iXgHmHYHsn0uXT5vBI3uxnXBAf21DrMqBLW14JnZGWS0EyPbcqaMmfKXynSeZl(bj9Mh29kzCMulF0rJpEFWWU32OLEBIYgzXit0myNqFvhc(m6py1jwgrumHQXfMgjmxeAuvVWyirzHluEkOgxWoALZWcu5jnZlWGBQ1dbPjgquGFFWDoQlkH4Cslv9ngFnFD3xXeHn87DobgHGA6(4hnJDqEKU(u(EU9yJFWVb852jOd8Bs4v0yOXS49vbtGpFTWb8Bb)27eia(DAOhh(cBs)MB4oJB3TbFrA)vUU1tQm6Ktm(I9vt)f87UJ7Q(RD6QUI9qXPZdxWudtS1wPYSJt70pYZUTlFE2QDOBKQ7QL9O5GJMH4S2Gm(I3cMg06efnPDGRNXqclRo3soH3okTEz9PBsFoPwG1zxs)PrZjiIGx0h5xWkYwcaU9QexBeWB(sLKg0xOXsfSkcCSRFeyFnfbGFpQahuPZg(9jYEBhM71SlM158hW6CG)q4fHV8wRJe(JiL1AR3hEhnqIfZoIqXy(6pwW47WUW3aWvzr9GB9f03VZctmkr3IgZ7Qlfx5LhRp2c1uDfY6xaHLrD2Vmg5SmDvwDJrLZHYOOPvO6Y)XJMT48ivg1R6BJhrg6sjtPQLJUefzjJ9TKaUq1YnMgDLTWi9JS5VEN1p8UDECFOcAybf5ljRMVtEnbm8AGxlDyo7hAdANGS3bfzpe0XEOO)RZEiceqNG01clvgcuxWB8WT7XzECuUgLn9DNEtMlNFYOmcSVTV8Mn2VUtljkPx3OmTGI5mws81oxIUtG9pIYedOcd4cg0nmKlkbDe3uwXYVr2W6inOdWMl76z10ue1kPMSKSok9LDULUOzsBSf)jl3I597pypbiiKAcvLfttA(FMnP5Jhmc)y9p5O12j82E4RohcPhHgMztEkQlXgsiHjp4WF51ZROvQFm6IfrQzx0wIlknpPltKmhqP8kIiTcnVK2RMf9YrzRu3HwJETZkjWkt1GrZEMt07TxJdAoS3ykj5SZPImmCTe7wYSjwptrttn1eZJWkclYQl6Q(A0g79f1EPAReTrJTF0gpnu6O2doDxi2Lx2E5pIMivQeJbLUl7kohBuVB6iEpZ1NaXbbEIHYxdUZ7)2OZy2B4OjI07z6oIevNK(b9SSrZVKdnkDLXP(NOFqNmPJYPpzdAuSfttvXEoYSkstTWidx126Gs5pQT2yzRJgY5iBihQjqnJXnJHPq25mGNV9aKbT2(dzpM10KrOEUkL5kOf0LTD6LsUaQCz76HovLctxQ0t69KuiNkheXvJ2pWFtA4VT5gkpiXqjuWqK0WH6LLge(7AM5c83xVHc8pu104b)YW)OT5a81LGVHe8p5c(NpeCvo4FXUJ)FLWPH))W)Ml4Bc)7W)rBW)P0UrSW)VGsh5LmsKc1118IND44zJ7V7cbQNeb)3vzpFf4BTlZuCF9HNLL6FbFbd6H8VqrdhSNWrdh2tqEF9goSFEV9gkqqEVb9h2dl1ll1hVVGE869vaCBa)bi4DHEpr(bgzkXEs1tZX7)0DD8UAyrS4ULnXs3IJBBzHZCf2R)wyvFYMdYdVta5Bu85qPm7woAQSUcvOmFPBLoN2zhelQO3N5id0CoZF2UoNPQ3e4)Hqz83uhj2ukF7suQ)yIatpr96jqOOE7XVNO(8eML4nQ)E9fmAOWE9enCi)e5Nq9qVQhV8(c4lCyQsuiVSuFBp(4ldeD2idI6KbjDcPX8L7CtBKQ5eO)8xYfD8VlXqEbcjWFV0Kq0KWKectGK4L4xkaLteOxAsqAsigJWZRWiQWiohHrm9IQfLWf8oNy3nNr8vVPHrmB0abc6H3xpKXLWsdWs7LLgKnke)Fh7ipReW(69QWxmJ)HJRi39fVyZPa)fF7EKNLb4VaX82NxAsp0Ka0eQcaZHGpQmGpQdb)(Pj9qtcWS7zJpnuOxb7RZFq3l4ZtFtm60lmVCZH(RCdc0)cwCVklUxTf3ET42NfNBlUB3I7oS4EnwCVwlU78vG26e2hzIl6ZxoHaIjvBo0(xEJ)8lkpJZz7kC4OKPsgiA4EiddKiVtDQhM5upCOxzIL2a)tsa(KjMaxYONjNEsVnh4)R(2iW7jknM2Dn5eWToBnXRgJuVKmsKgYBKANtG1kOBwnS309PkoR9opv)ao5MqlwNJjBq3(UvpQldPQIWZlyICQKduns9fvCYSY5CjfgH6ulhlM8ovgly4uQ5)pg10o83095Aw0RzNg)71YQPuSGAsALzVtaYyhNsEbf58QWPXgMc0tVbhnO1J4UMfIaBF6mqPzrPFaxlr6hlxpTlXIR(bVS4IQcfKZYoOmqh7jQHg2ecTsESS9UG)2xIEjn0UDX3hVICbzZBNE0cgLEL0vYQPsE9QM9lK1udNHpsFdnzYmybr5IgpXDab23keyWomZprho0PkhWPikiSPXQ5kQOetgNvH8LwoQ8FroA83VtLDqC)jSuBphXxRNEsAMrlL0uIjw(nbJZ1Aze6Mt7Z7SgyRx32tVRE8ajHumCJGueOJcBtMwVn2stwBrtR3r97SDNfYKmx4k7QTLBJ3elKDUO0ZJGDLqyZiSC2KsALsOME96UDnd2F4rcIlY2gXSDg74cfq79CetmE2TLpyh3DSYXnMYGZJrggD2n7WcDc92PVhc3rdJ0MhHj4lk96yYxzsNQt)q1BFHSd376v2YU0cX24k0MI9cbYwDwwRjT(bOxJONpPAlEtfxVVQIRun0VrA4BYpH8ciLksS272fAApmP2VEAQamrSLj02APXNYwACv226NT5V3YYK0dmf9OAneHNR3z1nIa9EJliKrwr2CXzYq4V4IgsW(T4MXEKs5g5SdpvVdjm3al0OQALnHIf3GnrwT(veDndfccLrZ0uRaBvJ97S6Onk1U8(xHDwLyReJbblOBEF269ahnt2IgKkidRalY6jPVb77xW((xSDVWhGJbKSSt3(II7R9f4wHTH)P16so1k9DVo5Avdf6PGH8i92CEwkNSjFyRxMvyNrAwDZQT07KakFyAGJdU1w)WM6h3HQzXzu1vE5TkV9QwVbI2)x6rVmT1IR101iF1A9QxHaMzEVNP3XYOp5ynF9bS4gAlraT4waErlUfBoTZI7swCVd4OwCVtlUhTc5YI7DvlXYI7D7WOS4EpwCpgTMS4wYI7Xj1Lf3tqASpzd8IRTCDDrvMql6TN1jo9YkHmSfnx3w00Xv91pL5(2cuMQNRIRtXPTW42QfHT4kw7jTXwhIjXoJk901ru4Wls8iRKrG4jOkD4eXMkxSjMv2VwQwOhn8ldOdpsT7Gf9dv326VQl4lxB(0Tpu5T4c7Gxv3zbiDl3w6l3MfhYIlNfxEYxRKfNmTwS4MDVx8RtB)Zz7n2ItXIRaPeQRuz4MwC6n4b1I7IKIGtVTPISEx2gi012YlP9idu1mR9C5CL6VN6FKrwzct1rvTzV1XvpEl5QkuVfQuRYQm1eNn2WfJLYJNjNTfm1rEzIW1oEVwD9lv172vQAl6qQ2XprPaD1SHnjsNfWmfitYQg4xcforWE1NWRbFlG)rF5MFl)(df2Rf371I7P399qrFK)g2ZJVeH9zVgUQQh7njZLwlNczM01WaUK5j8nB)g5cFIw5QASB4zaES4ga(yWT(0o7JVy9vz3)vxwXvX0)N94URjR6N9Ltynypkzj5CMfqQIoXcHL74mb171W(X09KLZol0U(0io0OrTWUCoH4G9SOc45mMtU(3sfVuvcTX9FB1eBdlUX33onWgwCjCozdwCNHMWVXqyyXL0j6fwCPQg3clUjHo2Jf3uqilUPVDlUZ2fFFwCNJC15jEHFylUlyX92zrGWI7rQg6HQ7PsNPhByXLUXWoWTRe1Hy(kKfXpUw0i(OYbBLP30WWjwLo01ikLew0Wzyfe11nByfRxExLAVZrFjyOfUS395166qAlkFezBeDslUvPZxV8)vWK2wz4mxcDXifpHGw391I508bHVLetziYU)gAyvnvhEtdhRJg3zdFQgoar1fsZThBWI7J7WcoyHnLfKXwkzhc)B54B3AmVQldPRlC3I7twgV7gfyC1SXJoLKAlW7p0UoEF46XXnIZ7wWinODBcmAXPDJbeUDmBRcFfoZGtSyP(YpG0aTa(E2BEHVbxAZNIxfx030GI1VzpQdfhzXEdSqqPslMlslqXN7Mxum6xztrr9234yQUPbpjTPMHNgjtmVckNPbU7wGN)438INpX9UP45vBymW38OWEVnflpFVLMBX(oZaH16Pfy5h(MyhK3ZMILl5mNLBCarlU3FAN4ITc1RyRImwdWypYx886Jvy(mXZ2cy8JCZlm2KyHAX9(E5baEgpQtgyqH563dQfa4h9Bxay7fAxSDXLF91DgfhgERWxZIBgsdX5S8rphFFP9EJ954dABJNDVqz1xiEe5bJKFWn5S71UbV)tg4KEAF(B7r)Fp
```
