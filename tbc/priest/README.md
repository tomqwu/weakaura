# Priest — All Specs HUD (v1)

One pack for Discipline, Holy and Shadow on TBC Anniversary (2.4.3 client,
WeakAuras internalVersion 45). Copy the whole string at the bottom of this file
(or the contents of `all-specs.txt`) → `/wa` → Import → paste. 28 auras: a
top-level group holding five draggable sub-groups. Spec-specific pieces load
through `spellknown` gates, so the HUD reshapes itself on respec with no user
action, and mutually exclusive pieces share screen slots. Every trigger matches
by exact spell ID — all ranks, never by name — so it works identically on zhCN
and every other client. There is no custom Lua anywhere in the pack.

**The `/wa` editor preview lies.** Selecting a group force-shows every aura with
placeholder data: load gates ignored, identical fake durations, empty `%` on
threat, simulated clone slots, mutually exclusive auras (Shadow Word: Pain and
Weakened Soul share a slot) visible at once, and no real animation or condition
behaviour. Judge this HUD in combat, not in the preview.

## Groups

**Resources** (`0, 56` — three 172×14 bars stacked flush). Health (green,
`y=-13`), mana (blue, `y=-27`) and threat versus your target (`y=-41`), each
with a floored percentage on the right edge and a 1px border. Health and mana
are always on and fade to 50% alpha out of combat (a second Unit Characteristics
trigger feeds the `inCombat` condition). The threat bar carries a bare threat
trigger, so it exists only while you are on a hostile threat table and vanishes
by itself the moment you are not: it runs green, turns orange at 70% of the
tank's threat, and red the instant you actually have aggro.

**Buffs** (`0, -16` — static row of 40×40 icon timers with time remaining
underneath). Shadow Word: Pain (all 10 ranks) and Vampiric Touch (all 3 ranks)
show only your own DoT on the current target and glow when 3 seconds or less
remain — that glow is the "re-cast it now" signal. Vampiric Embrace shows your
own debuff on the boss for the raid-healing/mana loop. Weakened Soul on
*yourself* occupies the same slot as Shadow Word: Pain and tracks the shield
cadence for Discipline (it is not own-only: any priest's Power Word: Shield
applies it). Inner Fire sits on the right for every spec, with its remaining
charge count large in the centre and the time left below. An empty slot in this
row is the refresh prompt.

**Alerts** (`-150, 96` — dynamic group growing upward, 40×40 glowing prompts).
Each prompt slides in from below and flies up, shrinking and fading, when it is
handled; the stack re-flows automatically. Four prompts, each requiring both a
state *and* the ability being off cooldown, so none of them ever nags uselessly:
Shadowform MISSING (red, in combat, Shadow only — you dropped form), Shadowfiend
(violet, in combat, mana below 30% and the fiend ready), Fade (orange, threat at
70%+ and Fade ready — the only threat dump a priest has), and Desperate Prayer
(green, in combat, health below 40% and the racial ready).

**Cooldowns** (`0, -66` — dynamic group growing horizontally, 32×32 icons).
Blizzard cooldown swipe and numbers are on (no WA `%p` text, so OmniCC users do
not get two numbers), icons desaturate while the spell is down, mouseover shows
the real tooltip, and the row auto-collapses gaps left by icons your spec never
loads. Nine cooldowns in fixed order: Mind Blast and Shadow Word: Death (Shadow
gated), Shadowfiend, Prayer of Mending, Inner Focus, Power Infusion, Pain
Suppression, Lightwell and Fear Ward. Mind Flay, Smite, Circle of Healing and
the rest of the filler are deliberately absent — they have no cooldown to watch,
so an icon for them would not change which button you press next.

**Procs** (`110, 24` — dynamic group growing right, 32×32 cloned icons). One
gold-glowing icon per *active* Holy proc, so two procs show as two icons side by
side: Surge of Light (your next Smite is instant and free) and Clearcasting from
Holy Concentration (your next Flash Heal / Binding Heal / Greater Heal is free).
Each pops in with an alpha pulse and slides off to the right when it is spent.
No load gate is needed — the icon can only exist while one of those buffs does,
so it stays silent for Shadow and Discipline.

## Spec gating

Everything is class-gated to PRIEST. On top of that:

| Element | Loads when this spell is known | In practice |
|---|---|---|
| Shadow Word: Pain timer | 15473 Shadowform | Shadow |
| Vampiric Touch timer | 34914 Vampiric Touch | Shadow |
| Vampiric Embrace timer | 15286 Vampiric Embrace | Shadow |
| Shadowform MISSING alert | 15473 Shadowform | Shadow |
| Mind Blast cooldown | 15473 Shadowform | Shadow |
| Shadow Word: Death cooldown | 15473 Shadowform | Shadow (baseline spell, gated on purpose) |
| Weakened Soul timer | 33206 Pain Suppression | Discipline |
| Pain Suppression cooldown | 33206 Pain Suppression | Discipline 41-pt |
| Power Infusion cooldown | 10060 Power Infusion | Discipline 31-pt |
| Inner Focus cooldown | 14751 Inner Focus | Discipline and Holy builds |
| Prayer of Mending cooldown | 33076 Prayer of Mending | any priest ≥ 68 |
| Lightwell cooldown | 724 Lightwell | Holy 40-pt (optional) |
| Shadowfiend cooldown + prompt | 34433 Shadowfiend | any priest ≥ 66 |
| Fade prompt | 586 Fade | any priest ≥ 8 |
| Fear Ward cooldown | 6346 Fear Ward | any priest ≥ 20 (all-priest spell since patch 2.3.0 — no longer a dwarf racial) |
| Desperate Prayer prompt | 13908 Desperate Prayer | only races that learn it |

Ungated (always loaded for every priest): the health, mana and threat bars,
Inner Fire, and the Holy proc clones.

## Regenerating

```bash
cd tools/tbc-weakaura-creator/scripts && ./setup.sh   # once per machine
lua5.1 tbc/priest/generate.lua                        # rewrites all-specs.txt
```

The build is fully deterministic: fixed seed `20260815`, no clock or randomness
beyond it, so re-running produces a byte-identical `all-specs.txt`
(sha256 `38e435018391bafc014954805ddc375b4f6d14447dd9fa1e52aaafaad96892da`,
6293 characters, 28 auras). When editing, never remove or reorder existing
`W.uid()` call sites — append new auras after all existing ones — so re-imports
offer "Update" instead of duplicating the pack. The script prints a UID
continuity report against the previous `all-specs.txt` before overwriting it;
expect `changed=0`. On an update, WeakAuras' Arrangement checkbox (ticked by
default) resets any positions you dragged in game back to the values in the
string — untick it, or report your coordinates so they can be baked into the
build script.

Note for anyone who imported the earlier priest draft string: v1 is a different
pack (it adds the Weakened Soul timer, the Shadowfiend and Desperate Prayer
prompts, the Prayer of Mending / Lightwell / Fear Ward cooldowns and the Holy
proc group, and drops the Shield prompt, Silence, Psychic Scream and the Fade
cooldown icon), and its UIDs do not match that draft. It therefore imports as a
new group — delete the old "Priest TBC - All Specs" group first.

## Import string (v1)

```
!WA:2!LR1AWTX11zVcYjsWYTIqw0w0w2W0wYsowYaGaeGk2EcajijKibjxakjk7gIf7Ej2vCXUl3DbFO0KuXK4Y(iT1SnEAtDtuztZp6K2odNPUV80oLtN8J00KtzBt22MmTrDM()QPVN(6CV7IxKauuVMg6(dUCX9E37EV3Z3339Co3L7IbeVXtUYZSzrbXzLm1n6xxv388(85BCFHoBmJaI6A2M6QQeP(LvuLmjAN7wJBQqSSdEMGdteuTL3S2VhvqtOET5Lnjc23SOUPeXmLx)BC4uQkx7AcMsbZRRRARyyU4yZmJfXMROHa292gD61d5t1p2ljvvdMZGiAv0TJKnxYT9ZTMjPKIUw(Lmi8Lm1RySMBlYPCnYdVUI2m6MLfSXw4FD3kCNBCCC(2uOITSU5yg0QT8xeNLZOuYVPGiRGE5TSfmT9xCgfnflz)PW)z7FzBtLsLiMwzpPP3TVDkB6BxOIPqKnOxTmiQQkswDfiuQk4dv0qvyjI5YSYZiz5)MwvksMhNM5QmZmklU(09Nmx(PZLpjF(AvnUjbRIp34PhzKBvXIKErCCLZThkWRjuMy5FnjsrShOtEZHtpY4do5iRwrZBy5FDjfRRwrdNnZtIiOQA0Ha7(8U1pQUe5R8qElxPLkrm6i3CvWv)GdwbxUVKSInzd3ADxRp4QcAkUlM9chDWnicwKC2O1QKT8he6kLMUgztjC(tBX001etlcUOkzTmTP0rjeovzbfTbHq4daHHiqpqu8)DU1sw1IOoZ46kA2f7pD28P57wrYiqnufpXsVIPiX6wyliMAcQxeFz4R91xFgtCPbhwc2c(ULGMiAHhKwe91xmx)8PtNDnBDX5DB)bg)OrQOiTEu9Rkfnry5tTquElrbvIV1qdbpdBzvf6Krdxf8TgDkP4IzsPQli5FD3xdB4cXxj0AwiiE2lPizlF01uWMNJnyFQhcoahCOVZdbPH4BYAdVUnB1IZOJM(n12Kk5K5hlf9XLHN4JEs4yVnUaDCii8S8masrxIhw0tdpJ)LriY0uWwbOB45Gt4hoj8cWP834ZbJy8ytInjy)YcuuoXuXYwr0YRlGSB5zHtdVi8HqmcDqmTyvrbFqFVo0leF5IcESPX3FOZgog9A8e0RrI5dHMwc2uWarEd2CZfenfhK8CDcDToLOGDW04FR0PraBYI2tBjliPVWL9KcwLvg9IXHpbcMeXjTmBoFItyC4gEG6u6B6wAvSdCEJJWkbz66uKRiZOKkj(ZBXQaPyejwHxFtxR4uEV9ny1F1k4k0mlbXxZKAAi5XctLDSSPHUmracTnRXAy9vh3H9mOKPXHh0u5AbNOIGefogmFEJq1Mtt7QmnDttSPLiIiftDAdt8glgYOXLMQdUnzLTaIkVKPGXYxY7MnR9QzscJnz(rYKnT3AvdG01ZKnBA(P5Zm0W5no9TziHIQAsm6m)mQ66MUlmZJJUIQKc1FLuf3J5Tiw1eACIBtN7wyXSvkxKyop01Q4IQlzBt3)5nSJGWKQLO7zG8(PyDRVxjvhBE02PjO4gCMQ)YchN(kktukjBFCyGlUkL5iQkyzvOOnY81S7KVCfCtj)8SspzrlfTsQKIJZNjDU8WNSty5cPqTCXoHpP)u0UJEZnzG8u4ZlrzVrsoWaghg76KsumerIinQWIYWbHeUYd9xNofW)wBPcY5FutpkcCe)nYGUm3Qm(OLIeHNzcHxMQhVvn1y3Evw4XWh0p0PF4X9Vo7vmmBz5vnPwSkMe((vjcA8cQgYc(Che5DRX4uzOkVZiisEJ(fqsIwPucMVXKzot9FDMCmnn2JjdVkQ1IQ4GVuxtxVmhCoF8lqjE)X(Hpm8kWRT(yQtKBjPIgLwiHPIgvGMi7nQuKKiA8ztFX08RRJBcO5ktU2WJXN5kJLnFYrG(76K8IYeXzheo2dV88cMkcigyzfT(1lxuWMFEb1keUU1n6(vFvtrzbTseRUojCdMlolBGELqmTxcEl4W(Vf1pOsmCFnPfAZqPDyWJcd5jK)ECuHCyyoidCE4cEQ0VBD1w(X1xGysvxx1GEhLdX1Kq7MuSxT6k0snBySBN(mmEJYYWeN3vdMnZO32xeFaVmKZt6fYVsNWKCWfVvvvv2i4eNaUmJgbtHtNRaVo8gxh(H4Gpk2LtdfWNtak6(IebjygoJt1oYnR)Aq4a0GsGmOaxfMfub9cgp)o)OULbwGXXG54mE5DU1Bx0evsaBOcmpSahSO7SAPcW1GZaFmFWpmL2dF8cWNGsCHFKtcxhw2LxdFkwrFA21pd8MWpkJYcRuLPc)yiZe(Xroj8tWb)KWN9(c5d(PEv4Ng(zG3YhSk8Zc)C1zl7h(CuQc821OjjYgDgL4kPlvmp8Zld)cWNh(fH3HI)HFjk2h(cWxeUHhsh(LRHXH1yGB4xPnW53zFBfoNTrG4A2mp5P(pGYKMLi2iq8Mu8B9kkqrPJyCyxN(dMtXUcJNYGT7AmBc6LEAnKDJt4(2meTRHxnEPTbpQ1OwGnAn824z3HoPgCCBCGgX1TyZU6DrtKbgQgPbV)bM(WBdMohz0YXYRo3ixjvtW0x0fM6d(cRwB1bUr3XdrbSVMhG98Sip7LEjSpe4orThIxOeQmd3WxJ47ZtByFmVqJ4EL9qBbT)maxTyAH9DfJJvlCICmNRcsDJk44y8jgpETQUOqzdftfrmq1kIYn8m1QiD5IOZ0KArSEMGxIimlrJife97x14i1kpJMgXm4GkMe4daFqkP7GGF4rKHdDio0A9da)GpmDi3HlqanIO1RXv)AeYNeEkm2YQBlq3LGsWE(cTyRHxcXsN9G39wFKCI23BwBoKcJ30IYArJn1qtbaO12yOq2zKsg90loe8r8bj9dP8b97hgWpvuzLNJPYGZOdX2ZCtrmQFCfxl3ck42EBu9N0OqL3(u(l7oL)1IelrFrI1x0i9fpuK(6lsQiX7noF4qyPSR9WUgLpsSEWYPxtyI96yAQiP64WVElwSmhoj)OyyZnUK13RFRzjeJKux8S5PcyYmnkupk55(wBwsvFHbnjZvHOjUKRQvkAzYBGIHdP6foI8Q0YY5gkj92ryXjF01P3x1nEwBQ7iiRUQUo7gGbTe2BmVSI4SAellFlZ(jkKSzXk226AJHEkPkSeRVgrbBshS3xk3eLSYry6MDFcJ7WD3RRSTHB0cPglF(XgfmoUR21mmTRwQBnbmW8OUfBZbwopMvdndv1X(uBtnBT6n6aVYCEQApkCbKE8EWbEP9J4RO9pwOli37OHNDc(gce9ZX2Qy5Q4Nc10J(TnESQfsDyDaflQ3GsfOsxV9eWfkq5wOSKlVGc2PGEe77Xl2sjDUTsOy)QB5IYs3KSiQgW2SlVszcCJa9qfOEfpbQcWA08jC2WNLAAOK8Z5BRKc4pOa8h2E0)547jAFHJYU2l7AC4R1oyn8N0mGg(6ncHH)uxyl8nKHVPma(G)SJcBYb)5UlQ)fi2d(lHVLp4BdoWFvhWF99due83ChaDGVt7rlW39aRuCRGevoeKKAXlC1mHU4cZD6iWFBJae4VRoY43b(EpWqbWnBHHh(7VRS3DXhowKe9()BTXF43DR24ZGMyI11KZzkln1PhS9M4F377My)3zMWQ7rNQ34js0UTPF)T576VBl1XtEfsMjNyXyZp1CT3(9799j2VRHoCKiv8WrseP3qrsfouOErpm6lwy21iOhgr7j8UYlSMnVN)EX8AD3BEJdgpRR59(ey5X3nGLDtim1ajFgeJ0B8RCr(zp9efjjApg53)bggjukmaJf6EYXH9DEJNClXiqJRl4OzYLlt2H2ELkenmact9Yg2gpwTkhuqIuT0G1kDac61dn94yr0thYRfSidOa0)iga1nwaAk0ejp69AWaRJEovPSwoAN5g5DrxN64fuvkPbXnTSfOhneh1bE0196Xlz6E0pKcSqw(i(wgxI86hm(fAqgp6gslPjuwrKDkCyOmPS0nTHWRwYuXnd7pYY0BPEU2n)a8QkLvSFe6Xwmc9o5BkQRHVEn7bfeT1nlYNCGmtMddTssPI1N(qyqmRkyk66fncA8Wb1pOXKQetBR1MPIQA)kMIQ4q1neLLnREil0ysoG69qWqimZfMGczQJNZkFAlTOLw55HH4UJ2xpA8E2exnfLjw5K1xymTnTy)BuflAUMVlKuEX6skuLJVzb4BZpUYIe16cl1pKMWXysmFJcuHhuKHjWSZK430tX3L0YyZRXYBol5Qf2Q6FZEX7WXols6PGMbTYgVq9uht)T1BW8)37io8(hLOrJq(1w3kzO(U8Kwx4uAdTv5G65F4FUnYb4SQOHjbdOcIAspfYXQyJwvhUox3svrIuuhdHQ8Yvp1Yi0ULATBHQXkhEv2jdYc9YY2uGMPCwaE47qSIf2pfznyj6Olke1H7XDlyrwboChlqy4T4yN3aR8cbws6GbwKBvw(1P97Yv7x6BFt8Enlv6PoHvz0r16YxTyCOXsGCT2vG13SERqZIA3Eikn31)dvt2NXrBkbR6mLkDZaVYgnwE39ecgb(su4k7amAkRSfGF1MZ1n8LBi)2R0bpoQfNnf9K5m6G(WLiAetfrxcrHnB6NR7Yp4jcslXYNodXKvOm5aV51HU4z)07iopw)Eb(rvulH2ERGNIDU5N2ia99GkD6MeDmQzunIuytewOMRA3TEdk5Bwl(vAnSCBsh)UZMv9w4fNTGXrO3tONpFJn)oHR6W1rnIkTQymEApX8D)GO6WfyBeuCvRzcQd3rA8iDApVKUY4smNkHAIeH7tyQfl3EI5)s7jMijKrsC5JoCpbYqC46Q98phUN0H7POp4XD4E66SmhUNPjgMdxWQulhUN1HRBAF5W9CoCpp7DDIcoCN8UIG8vRsq2SEIVner9VVcgIgcX)nka)wDhpecvmcup3VvPp00Boc8B2q2WzmbhUx0H7d5W9s4W6moCNLcWD4E5V0ZtNPHCr1oCHD4IGnONuu3jC4ITf8OdxVyTXV7HDS9hIgZlLR3HOUBFab4Sz7aUZ0AaxzHskItRImxc9GaPNMRIQ9sUOU(Lg8QzU8IjJoE42J6(xFFkQRPdpV7Ou53rzElGypeoqHczl4kN2utly0zZN7EDf9Dbs8a9MVLqrJdVvNyFaGlDpmiMtOpOedXP32XMNS1ytzD1LMg3ubx7CpAlgOm3OztgR81kLtvQ9GY)T9iGYqW)e8oW((81orJ(hG(z9PGX2KsvWY244nwEJNDYaOGNCTdpPHQz7A08Z5f1J(mbhfRd96T5NZ7Ss0rhRm6QPNJ6Cbw9mvONMNXt1uDckAbZvXG6XhR2J2yTJqDEAb0i2CXdsemdEjbtPAHE9s7VHyVG)9dEpFim)h1oNZ)t8V)RThEf8Fl7fyf8)upIkhUhcJJYHJdqg3(EehoFyGtoC7hV7HLD4(aoCOf8aSyJC4oy9GIA4dLRQVqwoCps1aIC4oKBOqC3xIekQIWKZim0aL7ByQE2Uj)kBrPznQ3DjvxqyjRQkopZ70sfN1QJcVhLA21jEzhuysURYe2wJfklnWjVp71cUYh8LKgiD65LTfNSTz8WHln89Kz6hjV)N56101Qcv2YzRsZGnF9TRUlmVoCJx1S(j(yTEJKanOICoxzK9U2xhoEp7A8bYkhzYqItLF2DWUo4dq7Qdx(hK2tAWxTWE6WfDpJ5BRrc1G5BQuZnvI8NoM(ec7G5BO9UMVRhT10Xo22MZ7zmN4uQDMtl50xAGridAF6e7G5C49UMZ((IT0CUEd(sTNXoIZL2QQwAQXJho1yc6s7GDmZEx74lmslTJ3SzxF3ZykXPt7mLZjiCQthtBIydo1oykp)Eyf23TnroV1qv27iW(UT1AUOHrF2tAAnH212bR5f2ZAnh4mT0yUATal3RyeXjs7SHdezEBR(ShQ45hEhSHJS3Lr(eFTwBeRLgG9mmrCM0oRyXmd37fvdPFQYdSdwXr))mRinftFwyFD1Whh7W6QlrpXgrRA5Hj8dM0WKAK0dMV9zIPW9XmXu)7MLnZAvsy(U3xscJ2vVCIuszhBaYG76VZmwAx6xvxJyvWDH8f57PNWXcZ3t04XIExCk0NBxCedjyhXqKwKl37tFukh72(rPK8o4JsXHBgVGbxAQlXBpLrORC5DGsjvnhVBHs9vzPQ1nhVuZhnZSp7AStQD8kQwe385YsLB4ZgJLfx2)dwGLM2Jfje9xNSqROIn03UTmb29bwIlWI)J72C(gOCaPasR80n)fYdjG3JLn8S0vbVpzD6NR(x)aF)9NRoYF32xOEL8rmtOmKK0cZ2IVq9aw89C2yNnuG53)h))n
```
