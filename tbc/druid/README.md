# Druid TBC — All Specs (v1)

One pack covering **Feral tank (bear)**, **Restoration** and **Balance** for TBC Anniversary
(2.4.3 / WeakAuras `internalVersion` 45, `tocversion` 20501). Built with
`tools/tbc-weakaura-creator`, 32 tables (4 sub-groups + 27 elements under one top-level
group), **zero custom code**, and locale-proof by construction: every trigger matches by
exact spell ID — never by name — so it works identically on a zhCN client. Every
spec-specific element is load-gated on that spec's signature ability, so the HUD reshapes
itself on respec with no user action; mutually exclusive elements share screen slots.

The whole thing hangs off one draggable top-level group anchored at screen centre `(0,-140)`;
the four sub-groups below can be dragged independently.

## Resources — bars at `(0, 56)`

Three flush-stacked 172x14 bars. **Health** (green, `%percenthealth`) is always on for every
druid. The middle slot at `y=-27` is the primary resource and is shared: bears see a red
**Rage** bar, restoration sees a blue **Mana (Resto)** bar with `%percentpower`, balance sees
the identical **Mana (Balance)** bar — only one of them ever loads, except for the rare
21-Resto/31-Balance hybrid, where the two mana bars overlap pixel-perfectly and read as one.
The bottom slot at `y=-41` is **threat**, and its colour semantics are inverted per role:
the bear bar is green while you are securely tanking and turns **red the moment you lose
aggro**, while the caster bar is green, turns **orange at 70%** of the tank's threat and
**red when you pull**. Health and the power bars carry an extra Unit Characteristics trigger
and fade to 50% alpha out of combat; the threat bars self-hide when you have no engaged
target, so they need no fade.

## Buffs — icon row at `(0, -16)`

Three 40x40 timers per spec on shared slots at `x = -44 / 0 / 44`, each with the WA cooldown
swipe plus a `%p` seconds text. Bears get **Lacerate** (own bleed, big centred `%s` stack
count so you can drive it to 5, glowing when under 5s left), the **Mangle (Bear)** debuff
timer (all three ranks, uptime awareness — the actual press lives on the cooldown row), and
**Faerie Fire** — matched against both the regular and Feral rank sets and *not* own-only,
because anyone's armour debuff satisfies the rule; it glows under 5s. Restoration gets
**Lifebloom** on your friendly target (stack count plus timer, glowing in the last 2s — that
glow *is* the rolling-refresh window), plus own-only **Rejuvenation** (all 13 ranks) and
**Regrowth** (all 10 ranks) HoT timers, which double as your Swiftmend fuel check. Balance
gets **Insect Swarm** (glow at 3s — refresh it, especially while moving), **Moonfire**
(deliberately **no** expiry glow: TBC guides want it to fully expire before you recast, so
the icon simply vanishing is the signal), and the same combined **Faerie Fire** tracker.

## Alerts — animated prompts at `(-150, 96)`

A dynamic group that grows upward; each prompt slides in from below over 0.3s and, on
expiry, flies up 150px while fading and shrinking to 40%. All four are combat-gated. The
**Frenzied Regen Prompt** (bear) needs HP < 40% *and* Frenzied Regeneration off cooldown
before it appears — appearance itself is the instruction. **Clearcasting** lights up with a
gold glow and a 15s swipe whenever Omen of Clarity procs a free cast, and **OoC Missing**
nags in red whenever you are in combat without the Omen of Clarity buff (both load only if
you actually talented Omen of Clarity, so they serve resto and feral-OoC builds alike).
**Innervate Prompt** appears for any druid at under 20% mana with Innervate ready.

## Cooldowns — icon row at `(0, -66)`

A horizontally-centred dynamic group of 32x32 icons; the WA cooldown text is enabled, icons
desaturate while on cooldown, mouseover shows the real spell tooltip, and hidden icons
collapse their gaps automatically. Bears see **Mangle**, **Enrage** and **Frenzied
Regeneration**; restoration sees **Swiftmend**; **Nature's Swiftness** and **Force of
Nature** gate themselves on their own talent (so a talented hybrid correctly gets them
alongside another spec's row); **Barkskin** and **Innervate** show for every druid. Note that
in 2.4.3 both of those break shapeshift — a bear has to leave form to press either, so in bear
they are situational (emergency / post-fight) rather than part of the tanking rotation. Per spec
that renders as Feral → Mangle, Enrage, Frenzied Regen, Barkskin, Innervate · Resto →
Swiftmend, Nature's Swiftness, Barkskin, Innervate · Balance → Force of Nature, Barkskin,
Innervate.

## Spec gating

| Gate | Spell ID | Gates |
|---|---|---|
| Feral tank — Mangle (Bear) | 33878 | Rage bar, bear threat bar, Lacerate, Mangle debuff, bear Faerie Fire, Frenzied Regen prompt, Mangle / Enrage / Frenzied Regen cooldowns |
| Restoration — Swiftmend | 18562 | Mana (Resto) bar, Lifebloom, Rejuvenation, Regrowth, Swiftmend cooldown |
| Balance — Moonkin Form | 24858 | Mana (Balance) bar, caster threat bar, Insect Swarm, Moonfire, balance Faerie Fire |
| Omen of Clarity | 16864 | Clearcasting proc, OoC Missing alert |
| Nature's Swiftness | 17116 | Nature's Swiftness cooldown |
| Force of Nature | 33831 | Force of Nature cooldown |

Ungated (every druid): Health bar, Barkskin and Innervate cooldowns, Innervate prompt.
All 27 element children additionally carry the `DRUID` class load gate; the four sub-groups
and the top group carry no load conditions of their own (they inherit visibility from what
they contain — the same arrangement as the field-proven rogue pack).

## Importing

Copy the whole string from the code block below (GitHub's copy button on that block is the
easiest path), then in game: `/wa` → **Import** → paste. If you are updating from an earlier
version, WeakAuras matches by UID and offers **Update**; untick the **Arrangement** category
in that dialog if you have dragged the groups somewhere you like, otherwise your positions
snap back to the defaults above.

One warning about the editor: selecting a group in `/wa` force-shows **every** aura with
fake data — both mana bars, both threat bars and all three specs' buff rows at once, all with
identical placeholder timers. That is the documented WeakAuras preview illusion, not a bug.
Judge this pack in combat, not in the preview.

## Regenerating

```bash
cd tools/tbc-weakaura-creator/scripts && ./setup.sh   # once: fetches LibDeflate + LibSerialize
cd ../../../tbc/druid && lua5.1 generate.lua          # rewrites all-specs.txt in place
```

`generate.lua` is the single source of truth — never hand-edit `all-specs.txt`. The script
seeds `math.randomseed(20260812)` and draws UIDs in a fixed construction order (top group,
the four sub-groups, then Resources → Buffs → Alerts → Cooldowns), which is what makes a
re-import offer *Update* instead of duplicating the pack. Keep that seed and never reorder or
remove an existing element's construction; new auras append their constructor calls at the
end. The script round-trip verifies with `W.verify` before writing and reports
`W.uidContinuity` against the previously shipped `all-specs.txt` (expect `changed=0`); a
re-run with no source change reproduces the file byte for byte.

## Import string (v1)

```
!WA:2!TV1(3nY1D9mrj0nAtBw7KDt3LSnoBZUXEjzJKSKL9MSf0l)ATTShj79rsJ1OzUsZypAMzNzKTLPT0yslMYBti0cfARdTaHNhtP840ZbQPu6PuGVvaHHqGtzHdNdfOa7Fb89Ehnsw2wAF5q2nn)GVEM7CN7m37NpF)89E)oFf3mDk(PF4vF4Q5feNxYu3iHUQU5O(85BsFboveJof11Sn1vvjsjKvuLmjAZD5KMLvK66j6AyIGQT8MENYluKy8aENnUGMqxDZtSS17X4qnxBCbvbnrspgh0R(SYMebB8kebZEmEWTxDcblBIzpxoVUPeXmET3vJdexvz5LfmL6kRUUQTIH5sPluWIyZL3qaFvT9EazJNa7TyQQDLXGiAL3TFKnR428lTUjPOIUw2kge(IM6Lnw3TfzuwMC3BOOvq3SKGn2c)B4Eb3PjoooFvfkBlRBM2GEzl)5XjSckf9BkiYQOpElBbtB)5lOOPyj7po(pB)RyBQuSiX0AItyw7WxkUn9Plu2ui0M0sldIQQIK1r6mq8Y4nL3qvOcXCfw9Jiz5)YwLZtwahLzkxOGYsBmBIyzYoBMSX4Zw)stAsWlXNzYuJn2vkBrsTe(ELXThYXRjuIy5FDjsEShOdEZHtn2Kdo9yRvwR2RL)nKuSMRSgoAwGesqv1Odb2XzDV(46sKF97O20vkjKb0rMlvgN87AWY4095KvSjB6Ev3567znbnf3jZ(G39GBseSizSrWQOT87aoACnDnsvjC8tBXS05etlcoPkzTcTP03siC8sckAdc9I3aegIa9brX)F4TxZAwe1ctQROzNprQjYMI)yksgDuNVsS0lBksSUc2aIPMG6m4ZcFQpZgfmXzg8TsWwW3vqQkcWdsRI(0ZNjbFQutSUTU4cUTFFtEWqyxUXcdL9INDm9uJn354Tefuj(whXbEg1YYJ5mIgoj4BD6isXLYexvxqY)gUpg2BlC6vdSUfsHN)Cks2YhCDfS5zyVSp0Da7NdUVx)oGHHtxL1gEDB2KfNrhnDofAIhB6SPJtVDz47(5ob8qVeo)0f8EHhLNXpY7AdJv9iWX8VcYqMLY1Ybhhob0TFOh4KW3J)TEFqAJhyASjDLqwGsYjMkw2kIw16cyQTDVWJdpbCkKIqFjMv0tEXh80pdmaC6vYluZyAY7kWPcgHwgTFAzOi(qMPLGnLlqK3Kn2C5qxGdsE6dbhDdQDc2bZI)T6Hm60MSK9SwYcs6lE(AcbRXQJwyCGJJCjrCqlZgZh)4ghyl3qdl6l7wRh1bg34(z1Gg66uIRiduIhdp9kSlGwyejwLpFvxu8c1E6BYU(CLXzOcvGtVUjfAizXkJpr6jsbh1eji02SoRHnMDCFTlGIVghyqtLL7AQYcsu6yxzZAeO(yAwxHPzBAGnRereTWuN1WepWIXm26uJ3lxvwDlISYZzkySY5QDq16pAMIq6PZo2itKQ2C1wiPBmYetKIFw(rgA4Sg9CvELqnvnjM1mFbvDDt3jMfW3U8QKCnEKub3dxBs0dcno(vPZDRm)eLlLNyUaC01WjvxJTQU)R2RDiKM4vJEnaQ2PInq)A149UvZSDwcQTbb8oZcFp9LxMOuu2(OWqZSg1YruvWYkxEB0YxZ(q8LkJUK8ZZQ9e5Tu0kQs4tYp9ijHvoe8rYfhvYfpeSI)40EJEWLzC844TlrnEdflzsJdG9CmjkfIirKgxyjz4EHNYvDirdRPd6F7Tubn5pGznle4q(3Qb055wJzoAPir4ziieIQgVDf1(V6ASWdI3OF4W(HJ4Fd2Jyy2SYzmPawztcFcvIGgVGQHSGp3xISUxXO7rOcVfeejpl1dpodfxW8zNEKNOXzprgMKg72KHVpuQf1WbFXxwxVehCgF8lsT7(Y(H3h89cX2yzrzZjS7tE4lkyQOr1NjY1ERuKKiA8tKAMu8BOBQGqetLC9HtZpYftpr2yJbdEKtWlkteNFq4HU7vwa7cbKcSIIwc9s5fS5xqqTmH7y6gh7mNXuuwqRiX6iNaEz2ALwXaxscX0Uc8IW97)k0fuvKr7RRSqBw0vdaJCqy0A64FroQooCwoymyCyIAI0FHgIT8tQViXKkUUMb9iQjKVM0zRsPE1VwUDvYg4VAYZqMTQkdzzYX9hPHOCWi(GPLHzQj9cNB17hophCHJDCd4zywoWZIdH3p8CWSppKJdeWUjpiInvciUDEbOiOWbZbZdQqjqd0bRdd2CGzo0SfwewcQalZbF)U93hih8bHaWhYh8dG2ylaF4CxMowzlaAEn9f1Ybpp1Sb(OSYFWtaVa8rCTTwVrJ23lmd8dXAWQWpm8XyMpWpINvd8JIwjWpgAFa)4CWpb8tUNyia)uNbwd(PHx0h8ZaVe8Z2G5ExWhNsBHprDkREX8jU4CQHoF6SWpVm8jHFb4xe(uuUi8PP8q4ZaRdVCnwh8lvNVbFwgrd(C3Oul4xMrk(v4AMx8RUNsHcfH9Yslgy7eOdXiqxXZTmJdF8JFDYMm6UvEhy93w88axQjMNzoJhT93QBDWcUKuJNS9TENEDV240WR0AAm8RTVHx5wi27DVd27atDH0wcKmHsn93rYEHFJRx1VFZDWdHFlpog8BV3qAeoYTqKMVRDqA6EMfmNm5ftMk)O7PKMp5DUDsZeBLgSUnlCc0DVGlsZSiXgPbmxknUqokhjTXbQf5Hmk2LzltGrAUMzm9tl6D3zmBEC3NMHODDXoJhFhAl1B0UiSS7CnJhPnDsDTS26oExwQDJUOjL0Rp)2xf66TuEOFh7GUouYfNCsT4MrReD3OR(GpdVqrCTEBJYokt2GT2PqUL(qcC2Bccm87aFEQY1VRllf(c7DSs43Zth73Vf0l4p4QXEG)W9AIXTu6y7BheJS51MUyFJD20JA3eX4K1jgRv38bE5JfnaLE8(8OhSqS2hTiiJyu)MGVi8Y(U(zspmWvpWTWD(ZzCaVaDngUblAmuAeU1XfOBgTRKSa)zCeVQhuGGBmQRbvmjEHITE0YgtPajpU19sncXlpzUYlq0y6JnEA8e0uyrB5gTJgYlrulDrbZsnA3460iLI7c8O7(JVwmIH7b8tTnUx4DcVlz4(Uxoe07a68UPJ(hWLxHCbKeSvqSUDZ7bE4J0zapN)uBiQjZJLBxwaWtIuZG3Znojcn3qAsvVrtCCQ1IAgIugkDHsJqoZfs3DAZEpR6KdPbj8bj9dP8bd6hgYp10F13ltlahq3hBbqvf11vLWDXKzrfCZDB6DknsRY7Ce)5QnI57T3OHJGWGwAn1k5WH)NFxg(MdhJF8bNESToj80pZvMNqmIrJnHnpfALz6iOMrYrF1Qfv1xCqtYLkt0eR4QSeNwN8MOB0HuRfgn51O1LXneO0dhJfE3dUb9yVWpXAtJiyWUMxiFCdmgTg2tmRSI48AellFRWofDbvnFzBBDT04w8vfQW6RXuWM0b75f3n((13IQ1n(wupny9iUkA7bB4Dt3yMfpD2SPhhSEq3oUatQCxLjN66Z)5bGjqdLVkS)V(DsxMvWbINowFt1Dmz(Te41poZnWkEuPC1f4(JmEaVkPrOjPIfn8hs5OAHFIPGjYrTYqDoxlekTNs)rRGAwiBRMdVJAOMbBXR5LjlzO4gO)SkLiWl3zeQQ3txt1lh8zPXp)ubpffsPM7NX32TpGVwo4pV1gcNgne6pA)y5a93hRmk8x0kZb4VSzdb4VQb1)0VkaU0D4BidvLH)AFWFZbH)wo4vDNu)7qol4a)9(Gxd(hGxVd4FuEViaj)tG1rFdJKWHCKfKo)OPet1B3LIaFZTYpG)5geJ)y4Y7XKa)xFWznL8xju0ObW)6p(ardpq8bgiqu(q9nWa9YhSV(JeLpy0EhiaRmiRmeFOObcg8TXBx8(ciExQVEko0zNrkC2WTgV)s754DdJE4FzxSZH)1BiZBMFU(6TnM0NS1q8O3mq8TkouOeM9kVi1J0uZErcn3WMsQgjTp7qTMXS5B0mMq7nmMxdvpchpyGi9hpy4EdepuGbyfbJ3BFHIgV)bcgi(a93lQT0Fy6rHdYhksObgGkZ0FqwzOBm62Bbuu2jbH6bHi3J84HkCHZzLT18J)K3S9Gud)FfeI7TpAr)0IbWceNXIGOlLiuepsF0IO0I(z4DG3gVBYdY5QOvw2SuW5L6U149x(we8EU4rIenaFOW4cgyLryL9XkJYwEqVFh7kcRhDLMf85lNV3rtPQ09LUuRb4)03Of87DVrW)RHg3HcslctlIqlO2)mX(qurGquX(E7LweMweHz1Zwyz)9)2CJM067EPqbso5yNBPfuAn14RCRYUfG)D4Bb)hW)j8FbFB4)g(FG)x4kVnA2qj)StEPqHkierkJwRrZ)S302lqG40ajESPNeUZr3sqcnjAlRqKOXzKO11KM6LmSBeRrAYMyk6M(ig3VxTP1t014kw0CWX4D3iSKAeZfeSj16ewKgPKRVeJC5gBrAMNisEN3SbxCdrD1YL0Yq7m3yZN3niq8cQkfXnfyAzlqZNsoAebhY)wcLRPB(ssYXcbAcFRGtk16N3LmlOLhytPkAcLuezPUk05Dh3s30gcVwrtf38sB)RqpKg3SJXNKxvPKI9(Pj73y0JKVSOUg(41Shuq0w3mpFSKJmDM8McskLTEH7fcEpRHZPUXW7foKhZOEAahtLyABTEHYQQjumfvX3u3qEUIPxMjsJX5(vVjITkY7CvbITr4WzSZRNvEgP0R(OWOCTxpG(vJ)kEF)KQnL3yhlCainmjd(qadrqk6nvoJoyzuZwBAoJd1CkNrZ0hbCUQZNUXNBE1o4TnfeNponrbD7eKHsmveZiRVyATCvB60nSy)JNiivHLFpSuwzcHsK9DHtdhLNDATmU8WjQfxokvTOjXYQRUzzXBpgDsFoifs3KOVaXeHzsUQM4BzgVUZ4GnBZqCd5w165sdTrSVOeDO4(XXz5ZgB0KZ4(PhtOjo8wBElLlpzd5sQQy1CWRXpPYse16IMUFgkAzyM453ihvsfLpzsNTxS7J6k2TolF7yzL11CqqOzYmnhQhbP7gD1i1ZONB9Sc5vuvSRmBEKgBw2sgUxhUt761RWzp)OZ03icZp0sBxNS(xhYH74TqOehp5nqiJydrnPPWC6Y2i92Hl7gwQiALx32wV0kEP8CiA)sP97IE6QhynwEfZcaUfcp0eTJfMD8ziw2c7N8SguHn5crD4M2TILyv4WDUodcVihdDz1NRZks3tNlXTgl98O97kE9l9PxfpwZsLMZQ4Lm6W7Az9QgF1QwJQ4wrowFZ6TC3moVpcnKErV2(WnT0DTh)ZHlDdp21sSnC(i0UW(()th314YoCt2woCSV5wDExNvMFHGt1345nME8wh5whUt0AwjYazmexYOd3mi9WH78TM85WDbhUlsVXNXH7zBqXC4E)nrVC4EopELd3SoC5O9LdNGdxE2ZsehYsBJDC1vYBkUFi5OVWvr3IIYelx90QU6P1CZFdqCo51aXPrUqEJPBD9G1oCtT1mK1vMIPapRgnR4rbqZkOFB18cOJIgeJEsmtHetoNsV6zBJC1J9wgIb1f))MNlEJd2us51Wp9MBT(JfkGxgKXsB6MYKVCTnPYwTdhUyoCXD4sGVTjD4sr7fhUb33L(20zGHCDz7WnSd3iylgDT6RZ0HBST5M1HBCSjtK7gMuYMEzF(FFx3uYcukjJlYyLnXeDjNnrfprBPIQu3cAudVgeX0NpXOLtKnqGPNRneXUVnHigWH7rHpfCNFmVCIirY6zsrtvLsZK(lH7WBPQMxaM3UvyxkZIkfSlr0K82IdR2jyZQpML7LPF6BVS0WT)0r6Ax6fQ1oVn6WUwCbZ5TMxP5NsDoy9n58431w2LJdxp3Zn7wCC4oPxwh5W940INyNBMXH7uE7JXH7jBSdghUa4(wC4ccigfA)oC9IBuXHlmEuezhoeBqySF2ErC4gOXMqAKFkERq2YH7P82aId3t7U1dU9KDEKiujrc)e6XJfIklDTSAMTPwSo1hvm1ffQy5PAGRqD3unQwlfDCtdNBsLJR5Ww0gbJy3aF0rhULPluV2poZCUQctTm5sXk3JGE3jBZ6wmHllZufIT3h2H1118ylBlrROHFy6goEUbqyhUpGhY(aL2vKnVR(WTVqQd3hQgu2njYeAIPIpJSwBGsR3aHshUp8BKqiDJ47ce6WD23kaFLMA4jRSyYIdjpuBGp7BFHVHxz3xrwDFU32GIn)P4AcfpBL(ISuu5fRuiwBqXY3(IIXF9Dffn6CNls62g8ehtTcpTYKEbvsbBlZUBdEUWTV45l8y7kEELTTO2BFuyFSwILxSVfNVsYPgAa9WTblx82yhKp0UILR4TjKBnaXzQVt32Ul3TbEHvU0fngV0c5tj2gWBPBFbVweWcho9BNHTPcOnDKHfMFWaK2aBvEZc26SuNsDkT67PPFSgJcpf8vD4W9mVS3V3b6V1HV((U1(36aUp(D87BOFrJLsftz4yfhEx(9n0PfFVNkYPc05c31h8)l
```
