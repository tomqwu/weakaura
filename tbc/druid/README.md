# Druid TBC — All Specs (v2)

One pack covering **Feral tank (bear)**, **Restoration** and **Balance** for TBC Anniversary
(2.4.3 / WeakAuras `internalVersion` 45, `tocversion` 20501). Built with
`tools/tbc-weakaura-creator`, 39 tables (4 sub-groups + 34 elements under one top-level
group), **zero custom code**, and locale-proof by construction: every trigger matches by
exact spell ID — never by name — so it works identically on a zhCN client. Every
spec-specific element is load-gated on that spec's signature ability, so the HUD reshapes
itself on respec with no user action; mutually exclusive elements share screen slots.

The whole thing hangs off one draggable top-level group anchored at screen centre `(0,-140)`;
the four sub-groups below can be dragged independently.

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
and a 15s swipe whenever Omen of Clarity procs a free cast. **Innervate Prompt** appears for
any druid at under 20% mana with Innervate ready. **Tree of Life Missing** nags a talented
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
them alongside another spec's row); **Barkskin** and **Innervate** show for every druid. Note
that in 2.4.3 both of those break shapeshift — a bear has to leave form to press either, so in
bear they are situational (emergency / post-fight) rather than part of the tanking rotation.
Per spec that renders as Feral → Mangle, Enrage (out of combat), Frenzied Regen, Barkskin,
Innervate · Resto → Swiftmend, Nature's Swiftness, Barkskin, Innervate · Balance → Force of
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

Combat gates on top of those: the Frenzied Regen, Maul, Clearcasting, Innervate and Tree of
Life prompts load **in** combat only, and the Enrage cooldown icon loads **out** of combat
only (WeakAuras load booleans are tri-state — `use_combat = false` means "must not be in
combat"). OoC Missing carries no combat gate at all.

Ungated (every druid): Health bar, Barkskin and Innervate cooldowns, Innervate prompt.
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
- **Levelling.** A druid without a 31/41-point talent loads only the health bar, Barkskin,
  Innervate and the Innervate prompt. Pre-70 coverage is a separate gating pass.
- **The Innervate prompt is not spec-gated.** It fires for a bear at under 20% mana too, which
  is a button they would have to leave form to press. `use_spellknown` takes a single spell id
  and cannot express "resto **or** balance", so covering both caster specs cleanly means
  splitting the prompt into two gated copies — a change worth making deliberately, not as a
  drive-by.

## Importing

Copy the whole string from the code block below (GitHub's copy button on that block is the
easiest path), then in game: `/wa` → **Import** → paste. If you are updating from an earlier
version, WeakAuras matches by UID and offers **Update**; untick the **Arrangement** category
in that dialog if you have dragged the groups somewhere you like, otherwise your positions
snap back to the defaults above. Note that v2 moves the four bear buff icons onto a four-slot
row, so a bear who unticks Arrangement will keep v1's three-slot spacing and see Demoralizing
Roar land on top of Faerie Fire — tick it once for that upgrade, then drag the group back.

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
which is why the v2 additions are built last and not next to their siblings. The script round-
trip verifies with `W.verify` before writing and reports `W.uidContinuity` against the
previously shipped `all-specs.txt` (v2 reports `stable=31 changed=0`); a re-run with no source
change reproduces the file byte for byte.

## Import string (v2)

```
!WA:2!TZ1E8XXXD9S5IBTVK0yjBR0ysAKvRDKcjU3dD6UlT2T3D60BP78ENKFe3QBVBN72vAVDxp7E6KCFgv3IB4vraH02eAr9rGqb(GGpqbk8bmLc0w(WpoiL9deGIHc8HhPGPq5XhkmZS3EpK0DwYwHyNM)WJ2D25MDNFF)(7X8BMXCZ0zUp(rU49xjRqU5fXA6X0u0WJ5YLRKU8C0a6DMtt1eRPOGeJjjRiIrQp7LhexswS7hU7rqckMsxY5wEHci997C3KcQcD3lpYWuRp9UAU2OckcQ5q9PFaN6tlHrcMKNGeW9PF3RV6ycgMiYdETn(U6EczveThlOGQ)gA8jLu0V3w9lixBQFWn)xrF2LZQHfr4OvLl67nQI85pVawS70AAkMY64ftKpVbYKlRUarSy6myshngPdJOO0DkDuoJS29JeEj7MFUvXOcYAQPxshXxaRvsFv7wKs(8ODTMSAEnCrbtslCVM9dSHeoooxvekzkPHtOtFSH7SeWjVCb3yHCSkgG3WuaB6oBEzvzdj3rj)X09YMy5cfqyJPocU6Lprut6BxOewW3LOLg6iffzrJd2PNOLi)OS6kclHWlZQFurd3x2Ouw0cKrzQs5ZlV4AZglsQ0ZMkDe(01EusmI8i(ujJpXexPKbk(IKVRu29qgEvHIid3RkIYs6b6Ghps8jso00tSsj1QFwUxtu2yUsQKrZciFckk6DiWUoT9ZNute9zULQIR4Ie2whPoxjIWV7Hkre3Nus2eDj7NAlR3ZkcQY2cZbG7DOlHemqPmjGvbtPxnCOOQAQOkIKXpTfZsLjyderOkASmTP0Vsiu0IcYQdbbj)aieegEe4nr(79T(AwXaPKpPMSQz2yXNkDC(EKf17Og)czOvcNdzCfsdqyvbLziVlYB9rxlpMiziFvcMcUUcrTGaWdrRI(2ZMkgF84tTQPwUfSB)UtEaFKUCTfgo9zgFcT4tm3j5nYjOGCTkbh4zuldhMZOQeHGRvPJizBktufnbr3Rz)AyFTWXVONvniu45pPSOP0bwvM08uSp279wG7Id23ZFlWeWXRWAdVMjtyXP3rt3tHMOrMoDIO0FUeC)V9JaD)ee5ZBaEaGyfGYpYABVGu1HHJ4Ezcdzwkxld0h8GWd5gEy4OWB0DJ)oiL((NM0KUJjjqj5iSSHPCoJQDbm96(TGhWl4JqrOFeZMZXuMl4T(OWXGJVCwHQktjVnph1BaAzWq0sFbCryMgcMuUas6sSXMnh60CWipsxWHwJQNq6Gzj)7IDP3PjArZznKee1kFQQgcwHvhTqFVhMWLYrg0sSX8HpS(EB4huxJ(Y216qDGtOVpwnefDnkXnhduIgHC7vypGOHHezv(yvSrXtx9TFj2ZNRercLFj44RIPqdknPYOtLyQ4WHWeccTnRYAyDPJ9NDEIHE99oew(8DFIscIu6y3PtR7P2yAwBdtZ20aBwruoIgMYS6yYfgmMrJIgNpUkS6ktyLNelOV8jRErLAVAMfHetNEIrNkEvzvdK01gDQPIZpl)OdpsA9(UkFseBQQImTz(8kAAyBbZcKVUSkOm1FLudU3tvHOdeQF4RsNBxz2PkvmlcVaCOvicvBLTk2)P6NTpcnXPgTQau1BZvh9RwJZ3wv12zreBBq)o3zq(oDLvcjxqY8(GXNzfQMtofbdJmznjA(QMDXxSeXLKBEwThjRHm1dh)G8tp6GWhOl4dMjkXsEUUGpG7O0EJEXLzC8OKFUiv51xKbhuFVKEoIiLcHerItkSOeSx4TyBDiwDTP7X96BPmrLF)4QAiWbD3Oc0P4wHPoAilI4ziima1A86TO(MV62yHVdYp0nCFUHxN71yVIrysLJHPawjmIpMcsqLxqrxsWL9hrA7NO37OudV5fYHolnAcIekQa(Stp6dx)UhofZKg7Njbdsm1sSHdUIEEnTICqex8LP6DFE3quigeFTZNtcpL5asJCgbSSk1(msQ6xLSOisLFQ4ZeNFnnSmbIywjxDKe8JEMetLoYeWyh8i85Kq5MFiO7DT8cKUqGqbwwwnMwXScM8liOucX1JMEph7y4CsKywqgh8iWZWIlBzDsijiS5sWtc3T7RqdERaJ2xZYcTzbVOhyYdatv1o(NJJAhhsWbjHta8vns)lu3ylFsTYim146k60ROQqUAYoBfk1R2ZYSPMSHzUAMNHt2Ovz4umZXHcu3OS3aUGtlbNPQPx4rV4(GZYbVTEoSomltZbYqgccqwi3JbICaI0n5HcKMkbY2D(CW8ab1ubnqhohGbdO89alYblKHO2cVd4DcVl4DZbVh7(79MbEmOFyzxW7JOJTaCHmxMowzbanVQwz1mW7NQ2apoR876iWfHpOTU1Q1B0UVWmW3nRbFpW3l89XuFGVFhTg4dr0sGFaI(bSch8dc)q7ikcWp8XGNa(rGN0f8HHpc8rRZCVn4PO0w4PRrz1kKn2zMtX3PsKg(ysWhh(XGvHpbLlcFskpe(uWNgEMQSo4hVgFd(jyen4zVwPwWpjJu8z4AMx8tTJsH8fG9XslcVEcuxmc0vCClZ4Wh(WBt2KEVTY7aR)AWZduQjM3cz0FdT)NAxhCEBsQ(BS9TEJED3ACA4NU10y4Nz3JS8nqS3DTb2B4tC6egcOu(Ip93wYEHF2TR1V12ape(5C4yWp)odPr4G3arAEvBG007mlGto4zgmE2X2rjnp1TUEsZunsdw1KL6c6SxibPHlGmj0aMlL6pidLJKsFVvZYrkzZsSWeyKMTmJjeTW)MZyU0HTFB65mRzSt)H2GTLAnAtmSS5Cn9d1MoPMTS26oEtc1UEx0KL0TNF7RcD9gkp0V6nqxhEWYjtQgfhCPGBgD1f8P4fkqI1BDu2XyMnyXo5ZU0fHaFQRdcm8lcFwQLRFjBwk8lVZXkHFfh7yFUwqVGF1Rg7b(12Pjg3qzhB3BGyKoR60fgyIXtmMzteJhSgXyLAQpWZ0tqpu6XXDOhS05oaTWlJyu7hb)6WZ4A7ZK6MkEUs1zDrNjpDoK67p2erMmz6erNisSXjtOC00JotCBE1M4n1vl8MwJDD3Kj0wlDn(yZmimRSFwzGaeGjBrzmwdlX8IVFI08GUxjRZKA5Jor8PgegZ91mAP3HOSromYenl2j1xnHGpH(JuFILreftOAC2tIeMpcnRQNDsKOSWzRofuJZANTYzzjQ8OMfeyWnv7HG0efikWVh4UMWfLqCAPLR)gJVMVEhSuIWg(9oVaJqqvDFFhkRDsEK2Ew(E6DzJFWVj85VEqh43IWRO5qJPX7RgMaFHgHd43g(DUEGa43DDsC4lUjYn3WDf3wSbFjQ8kFV6PuMy6KtT0GniVGFVRBr1FJJO6Y2HItNhUGPgMORTsTzhNXroYZUThFE2Qc0ns1D1wjAE4qzjoRniXx8MW0KwNOKjvawjRHewwD(LDsVDuA)YKPBImN0lqf2L0FA08cIi458r(fSMSLaGBVoX1gb8wOCzPr8fAY0bRJahE7Ja7PLia87tnWb1e2WFaXS31cZ9QkIzcN)qMWb(JGNd(kBnbj8htAR1wxgEhRJelMBCHsX8nuSGXVofH3pWvBr9GB9z13RZctmbXUfnN31xkUQlp2GSfQP(kKnKaclJ6EizmYzz6QT6gtiNhLvrtRy9L)JhnxPfqQmQx93gpIe6sztP6TJUef5iX(wwaxSE7MuJUYwyK(9T5VEN1p8ECE8GOIAybf5ZlRwOBEnbmCNWRHgMZEHoGoji7Dqr2daDTlk6)ATdrGa6eKUryPwiq9aV(d2PhN5Xr5Au203zMnzUC(jrzeypx7M3SX(koJKOePUrvAbfZzSK4RD6e9Ma7FCLKdRcd7cgXnmQlkbDC3uwXfF9SW6idO9XMlBLCAAkIALvtvwwhL5so3sx0mPnoI)0vhX8(9hS)aeesnHQYszid)p7Mm8XJeHFYHMEIgfcV1h9kZJq6rOPz2KNI6sSqcjm5rg7RuPGIw5HWOZvcPMBjBtCrP1jDjIjZHvQUIisRqRlL9QzrVCc2k1DG1Ox7SscS2upz0SN5K9E714Gwd7nMwso38QiddxlZULmBIkzlzAQPMybewryjwFrx1xJoyVVO2lvBTSnACTNTXJdLpKDWP7a5U8s2l)r0ePtNysO8DB3X5zr9UPr8EITNbI9d8efLVgCxp0TrNXS3WrtezGt0BejQDs6h0tXIMFzhAuMAXP(NQVFNkPr5mOSbnl2IzOwXEAYSkYq1WiHRARDqP8hY22yvTJ1vZ9THAOQaneJBwdtHCZBaptNbibT25B2oM1mKiupDT2Cz0I6Y2o9slxevTT98MpwTgtxQ0J69OuiNAoiIR1R)a)TzG)UwRO8iefLqbdrkdhAawzq4VVvQlW)qZkkW)yDvJh5Ra)t2QdWlibFDj4F2f8VCa4kCW)QTG)Bq40W)g8V7c(MW)b8F2b8FjTtKl8)BO899IgjsH66AbXtnw8CX93BXantIG)N6SNNh(w7Wmf3Bp8SQP(N1xWGEi)lu0Wb7pC0WH9eK33aHd7N37aHceK3Bq)H9Wk9Yk9X7lOhVEFfa3gWFycExCG(km84Zi2F6(BnE)NTJJ31tlIf3TSjA6wCCxtA4mxHd4VnA1hT1G8yxpG8nk(COuMDkhn1wxHAuMV8TsNt7CJGfv0h0C8HBnN5pFhNZu3Bc8)sOm(BPJeBkLVDik1FcXat)r96jqOOE73VNO(8eMv4nQ)b8fmAOWE9enCi)eZpH6NEv)E59fWx4WulrH8Yk9DTXhFzGrNnYGOozqs9jnPV8N(KgPBnb6V4fDJo(3HyiplHe4FaAriArysbHjqk8s8lfGYjcmaTiiTieJr45vye1yeNMWio5sQLKWf9oVyVTMr8vVPHrmx0abc6H3x)K4syLbyLdWkdYIcX)32g5zTe23Sxf(sz9pwCf5Ep35Anf4V8L6ipRcWFrI6TpV0I(PfbOfulamhc(OMb8rDi43pTOFAraMEpl(0qHEfSVj)b9UOppdMCItU4cYTg6V8niq)ZAX9QS4E1wC72IBpwCUT4UDlU7WI7oT4EnwC31RaTnzyF8KNZNV8cbetP2AO9V6g)5xuDgNZ1t4WrjtLmq0W9tcdKyEN6upmZPE4qVYelTb(3pb4tLijUSr)tFYP92AG)V(LqG3tuAoT7z6KWToxd5RgJupVmsKMYBKA3jXAf1nRN2B6(ufNZENNQVpNAtOfR7jLnOBF36h1Lrvvr4femroDY(QNP(skovw7CUKgJqDRLNLtENoJLmCk183GrnTt)nDFUMdDNxV5)ETCAkLkQMI2z27eGS25PKxqrUGkCCSHPa90BWrtA94UByHiW2Nodugww6h21Ye5y1(PtjwE13)LexsvOOCo2bLb6Axrn0WMqOvkGLT3f83(Y0lPP2Th(b5vKlkBE70JwWe0RKUConvYRx1CiHCMA4S8rgC0PtLflikxY4c3beypRqGb70mFHUCOt1oGtruqytJvZxsrjMmoNc5lTAw5)sC08VFxkxh59NWsT9CeFT(7pLzwT0sZiM4IVbykU2BgHU50(coRbwLM2E690VhifKMHBeKIaDuyB6m6DWwAYgBAg9UAENT7SqMK5cxBxTDXo4nXc5Mpk98iy3je2mclNlLKw5eQzQ00TRzW(dpsqCj22iMTZyNsOiA3NMOIXZUT6b74EIvnVXugCbmYWO7EzhwO(07K(EiChnmsBbeMGVOmvWKVYuoDN(bAw)czNU3k12YU0gX24k0HI9cbYwDw2OjJ((OxJONpPgBElnU(G1nUsTH(1ZaFt(KYlIuQzI1E3Uql7NzQ9fYqnatm2Ym02EtJFaBtJRY2w)Sn)9w2mj9atrpQwJs456DxFJiqV34SczLvKnxA2Se(lUKHeSxlUzTJuk)4NASzgyuH5hEX1BvT2MqXIBKwywT5veDndfccLvZ0uRiBvJ97S6OR3u7f37kSZQeBLymiybDZ7ZwVh4qzZvYG0bzznyjMKK(gSVFr77FUo9cpjhdizvNPZLe3tNlYTcBd)t71LD6v67Uc5Avdf6PGH8i9oCEwANQjFyvQYkSRidRVz9wMRNekFqAIJdU1w)Ww6h3HQzXzu3vE1TkV9QwVbI2)F6rVkT1IR901iF1g9QxJaMDbVNyGjZQp9KTE9bS4gDlraT4weEolULAnTZI78wCVd4qwCVtlU3vnYLf37UrILf37XHrzX9ET4EmApzXTSf37J0xwCxGmyF)RJxC1nx3uwLj0Ib6VcXPxojKHTrZk2gnDCvV9Pmp4wGYu)CvSnnoTfIBRre2IRuJN0gB7qmtSZQspDDelC4LiEKvYkq8euNo0xSzYhl5CY(1s3g7rJ9Ya6WBVXDWI(bAAB9x3f8LASE62hQ6wCHDWRA6SaKPTBl9l2HfhYIlVfxbYxRKfNmTxS4MB3N7fOJ)5T9gBXPyXvK0c1vQfUPfN(68GAXDostWzUMPImPlBde6ABteZtjImwiZIttCqBAztKWJ0wsOc1nGkvDRofmXPInwPyP94z65AdfC8xMyr66EtuT9TbnW1QnOTONMgdmIsb6PvXdjsdVF2IKzp1a8lHcNi4a6j9AW3g4FIxU5qYV)qH9AX9bT4E8DExp0h5FDBMXxKW(CxfFqnJ9MKjjRLxHmf5gyaN3SpFZnKr(W91oFqtEdpdWJf3WWNaU1h3zd6fBWABRVMQkUkM(Fzh3tdv180QCYxb7rPklN3Sisv0jjhSANIzq9bmSFmDZw5SLbT7pnINkA6iSBNtUlyplQaEEJ5LB(TuZ9tTCw8q3wdjTWIBQ9C9MXclUeohzblUtql43yUjS4s5KwclU01tiHf30qx7YIBgiKf3jVDlUt1d)GwCNMC1ziUxFulUZAX92yPwWI7TxpNc13SKoZ71WIlZ6ZNa3os6eI5Ryoe)uArJ4JAoyRmVL1fNWQ0ysJOuwyjdN4fiwx3S4fQuD7IAVLqFriMbx2BR8gDDiTfnFe5AiTJwCFC6eXR()XlzSTmCIZJoxKs9jO17GTzYkpj8TKywgISZVtfwvt1H3SUZRX63YcR)WS1uUkV2ydwCR6Wc2FXnLfK12uY1j8VLtCD7X86UmK2w4Uf3NSkE3lkWuQ5IhDgj12G3F4DC8(GnJJBeN3PGrA242ey0It7gdi8ArTTo8v8eJKCPYdwyyPHBd89rU5f(gz5nFUB1CrFtdk28U4OjuC8LgiWIbLkVu(iTbf)O38IIrF(nff17CJXuDtdEsgtTcpnsLybfuEtdCVTbpFQBEXZl8aBkEEL1fd8npwyFGwILNzGYZV0GNy4WA93gS8PVj2b59UPy5YoZz5gdqCMA5eRT5dBDGx)YN7m6twCHSXZ1gW7h9MxWRfP20I7dDZmSDcpQthyeH5hYdQnW2h7LkyRZIDk2P4fFDnDqdhdElWxZIBwYaX5a5rpmEF5DFJ9HXJmT)nCa8cLtFX4rKhjsHr2KdGxNg8(pAGJ6PZfUT31)h
```
