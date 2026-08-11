# Hunter TBC — Beast Mastery & Survival (v1)

A single WeakAuras pack for TBC Anniversary (2.4.3) hunters that covers both raid specs:
Beast Mastery (41/20/0) and Survival (0/20/41). It is built from the rotation, not from a
list of trackers — every element maps to one line of the priority list, and anything that
does not change which button you press next was left out. Everything matches by **spell ID**
(never by name), so it works identically on a zhCN or any other localized client.

28 auras: one draggable top-level group `Hunter TBC - BM & Survival` anchored at screen
centre `(0, -140)`, holding five sub-groups you can drag independently. Built for WeakAuras
`internalVersion 45` / `tocversion 20501`; modern WA migrates it forward on import.

## Groups

**Resources** `(0, 56)` — three 172x14 bars stacked flush: health (green, `%` at the inner
right), mana (blue, `%` at the inner right) and threat. Health and mana are always up and
fade to 50% alpha out of combat, so the HUD breathes with the fight. The mana bar turns red
below 15% — the same threshold that fires the Go-Viper prompt, so the bar and the alert agree.
The threat bar only exists while you have a threat state on your target: green normally,
orange from 70%, red the moment you are actually pulling aggro. On top of it sits a red
`ADD`-blend flash that pulses at 80%+ threat and only loads while you are in a party or raid,
because solo threat is your pet's problem, not yours.

**Buffs** `(0, -16)` — a static row of four 40x40 icon timers with the remaining duration
under each icon. Serpent Sting (your own DoT only, all ten ranks) sits left and glows in its
last 3 seconds so you refresh instead of clipping; Hunter's Mark (any hunter's, all four
ranks) sits centre. The right slot is spec-shared: Beast Mastery sees **The Beast Within**
(the 18s self-buff from Bestial Wrath, spell 34471 — not the passive talent), Survival sees
**Expose Weakness** (your own 7s debuff on the target, spell 34501). Keeping that debuff as
close to 100% uptime as possible *is* the Survival raid job, so it gets the prime slot and
doubles as the alignment cue for Rapid Fire and Readiness.

**Alerts** `(-150, 96)` — a dynamic stack of glowing 40x40 prompts growing upward beside your
character; each one slides in from below and flies up while fading out when it stops applying,
so the appearance itself is the signal. Five prompts: *no aspect at all* (neither any rank of
Hawk nor Viper, in combat only); *Kill Command* — you landed a ranged or spell crit **and**
Kill Command is off cooldown, i.e. the exact 5-second window in which the button works;
*Mongoose Bite* — something was just dodged by you **and** the bite is ready; *Feign Death* —
threat at 70%+ **and** FD ready, dump before the tank pays for it; *Go Viper* — mana under
15% **and** you are not already in Viper.

**Cooldowns** `(0, -66)` — a horizontal, self-collapsing row of 32x32 icons with WA cooldown
text, tooltips on hover and desaturation while the ability is down: Bestial Wrath,
Intimidation, Readiness, Wyvern Sting, Rapid Fire, Multi-Shot, Misdirection, Feign Death.
Talent and late-trained abilities load-gate on their own spell, so the row shows exactly the
buttons your current build owns and the gaps close by themselves. Kill Command deliberately
has no icon here — a 5-second cooldown says nothing useful; its reactive alert owns it.

**Procs** `(110, 24)` — a cloned 32x32 icon right of the bars for **Quick Shots**, the 12s
+15% ranged-haste proc from Improved Aspect of the Hawk. It pops in with a scale-and-pulse
and flies right on expiry. While it is up your autos are faster, so tighten the Steady weave.

## Spec gating

The pack auto-adapts on respec with zero user action — every spec-specific element gates on
`spellknown` of a spell that is only in your book when the talent (or the training level) is
actually there:

| Element | Gate | Shows for |
|---|---|---|
| The Beast Within timer | `spellknown 19574` (Bestial Wrath) | Beast Mastery |
| Expose Weakness timer | none — the debuff can only exist if talented | Survival |
| Bestial Wrath / Intimidation CD | `spellknown 19574` / `19577` | Beast Mastery |
| Readiness CD | `spellknown 23989` | Survival (41-pointer) |
| Wyvern Sting CD | `spellknown 19386` | only if you took it (raid SV skips it) |
| Kill Command alert | `spellknown 34026` | level 66+ |
| Misdirection CD | `spellknown 34477` | level 70 |
| Go Viper prompt | `spellknown 34074` + in combat | level 64+ |
| Aspect-missing alert | `spellknown 13165` + in combat | any hunter with Hawk |
| Mongoose Bite alert | `spellknown 1495` | any hunter |
| Feign Death prompt / CD | `spellknown 5384` / none | level 30+ |
| Threat flash | party/raid only | grouped play |

Beast Mastery and Survival never both light up: The Beast Within and Expose Weakness share the
same screen slot at `x=44`, and only one of them can have a live aura at a time.

## Deliberately not included

Steady-Shot weave timing (that is a swing timer's job, and no sanctioned trigger provides it),
Arcane Shot / Volley / Raptor Strike (situational fillers that never change the next button),
pet management (no reliable pet-state trigger), Master Tactician (a passive crit proc you
cannot react to) and Deterrence (PvP defensive). None of them change the next press in a raid
or dungeon, so none of them earned a slot.

## Importing

Copy the whole string from the fenced block at the bottom (GitHub's copy button on that block
grabs it exactly) or from `all-specs.txt`, then in game: `/wa` → **Import** → paste.

Three things to expect, all normal:

- The import dialog shows a **code-review panel**. This pack contains exactly two lines of
  custom code — one on the Kill Command alert and one on Mongoose Bite, both the same
  sanctioned "either of these two events fired, and the ability is ready" one-liner.
- The `/wa` **editor preview lies**: selecting a group force-shows every aura with fake data,
  so you will see both spec slots at `x=44` at once, identical fake durations like "55.1", and
  an empty threat "%". Judge the layout there, judge behaviour in combat.
- On a future re-import the Update dialog's **Arrangement** checkbox (checked by default)
  resets any positions you dragged in game back to the string's defaults. Uncheck it to keep
  your own placement, or tell me your coordinates and they get baked into the script.

## Regenerating

```bash
lua5.1 tbc/hunter/generate.lua
```

Run it from anywhere — the script resolves the toolkit and its own output directory from its
own path. It rebuilds `tbc/hunter/all-specs.txt`, round-trip verifies the string (decode +
deep-compare + structural wiring check) and prints the aura count, string length and the UID
continuity report against the previous version of the file. The build is fully deterministic:
the same source produces a byte-identical string every run.

`math.randomseed(20260814)` at the top of the script is this pack's **fixed seed** and must
never change: it is what makes the UIDs stable, which is what makes WeakAuras offer *Update*
instead of creating a duplicate group. When adding auras in a future version, append new
elements at the end of the build order — never reorder or delete existing ones.

## Verified spell IDs

All checked on wowhead.com/tbc. Aura triggers carry every rank; cooldown triggers and
`spellknown` gates carry the rank-1 ID.

| Spell | Use | IDs |
|---|---|---|
| Serpent Sting | own DoT timer (r1-r10) | 1978, 13549, 13550, 13551, 13552, 13553, 13554, 13555, 25295, 27016 |
| Hunter's Mark | debuff timer (r1-r4) | 1130, 14323, 14324, 14325 |
| Aspect of the Hawk | missing-check + gate (r1-r8) | 13165, 14318, 14319, 14320, 14321, 14322, 25296, 27044 |
| Aspect of the Viper | missing-check + gate | 34074 |
| The Beast Within | BM burst-window buff (18s) | 34471 |
| Expose Weakness | SV target debuff (7s) | 34501 |
| Quick Shots | haste proc (12s) | 6150 |
| Kill Command | reactive alert + gate | 34026 |
| Mongoose Bite | reactive alert + gate | 1495 |
| Feign Death | prompt + CD icon | 5384 |
| Bestial Wrath | CD icon + BM gate | 19574 |
| Intimidation | CD icon (BM) | 19577 |
| Readiness | CD icon (SV 41-pointer) | 23989 |
| Wyvern Sting | CD icon (SV 31-pointer) | 19386 |
| Rapid Fire | CD icon | 3045 |
| Multi-Shot | CD icon | 2643 |
| Misdirection | CD icon + gate | 34477 |

## Import string (v1)

```
!WA:2!LV1AqYX1vz3AKsKgz7ODSKCKuC841wlsowRNz2D2hYwXmZUZ(sZSp6zwTRE5D6z67mDRTNUB1Dp7lWb7noMLaeclGDriHeVMyQIIKaBvavbbQKTG8hmKd7pO6FqaIacG5rH1pHFaN792ZR9LKTKs8AQY6U9C7BF779E(((UNZ52w4cbY)voXsp665KYpTSLHzpgAgwd5ZNVr9fQ1OMbYBO7yzOPrK7rrvt2IOp0nhOSUdXk4zcoarsZrz9Q)oLKUuT7MrXIi5yEKnurW(0KSvUrodlzIvCVxR5HIRPUWcswYbZyyO5OAAn3ifkytCeYzkHVvhZJ71pzI3d2xXtfSLGPlBnJ6msA54DMI188N56RyrkQAONzEtIyrlJYMRWBrA1fi7Bvv9cgwLKCWw4Fv(n4tBbbbFRlv2rXWAet6TT9NdxakOw0VLuEwfDiA7iz54pxbvDvBf)XX)44Frhl1Ifjw2d3IL3LVACh6BxQSLuK1OL2Mennvz7Jhiu8Y4dLZutAEI1IS6hu22)nSlNJmdovtxUqb15wDQEILoZuPZetmt1BnQfbVLy6rtKm5nlBtsmhoUsZ7HSI6sLi2(xrMKd7b6K3AGejhTVXtUmU0Xhw(xvw1(AL1XzZmKisAAMnjXUod)(PmKj)23N3Yvc5IeZMsF9YOfiyFL10coHIQdzn(D5R1hyzjDv(IzhWr7BnIKnjTdAXk6O8HHtex3qNSUmo)PTyk6AILnbxuLTxK2u6OeIeVKKQEFqy8bGiqBq7qu8Vp8gRzzBIwHrnu1DY1tIHZKqSzvzZavXxIeBJYw5j23uLwJUK2fWxg(AV8QfSWLgCyj5i57Ms65rlCF0QOV(CP7rmrIHxXXi)m82V)rpsKYQYRQnxNjfV(fU0CXMw0oVKgX3kOHqKHTSRaDguhxf8TcDkPYXmX1mKK9Vk)1WgUqxlfAfBeip9eQYokhzfvS5Pzd2p29bhqaEG)M7d6d6ADwBenCyRwcMn1WVP2M4XgpZiXPpUcCSNVf44VkUa9XHhdAwKbqYX5Kyvpke0)Iiezkkyll84WtaT4h(XGtbN2F9phKY8WJJnjypksuuoXs12rnVTxxaJSHNfEs4tapfIrOdIPYxrVWhC2ldDcDTyojp20O7nuRHJsl7SlAzKO(qOPTKdfmquwJn34GOlkaXp7rHtSkLOGDWu4)w6OMbCiZ5mLTIKSXSt6jhSmRoAH5HojcMYJtAf2C(KN08q19a1O03GxBfSdCEZhIvdY0nOi38mJs8y4pVj7gifJiZQ8LwNBfVO3BFn29VwzCfQW8qxRyrnnKmyLXhEKHtaNWcbi02ScRH1wD4d7cOAQ5H6ZsDHGJvwsMchdMjJzOQZPP4ktt1WeBkzsEKIPnLPfEHndzu)stLb36S6MfrLtyjzU4eExSE1xntsyKXZKCWHt4TwvhiD1bhE4eItjoy)dKX803IHekQQlZOZIf0mmS4lmZGJUCAKS1ELuf3J5TiwXeAEYBrNZRm3WLlLJyndCILXfvozBD(F8g2rqysLAm8mqE)mFnRVxnvgBE02PiO4g0ALFzJJtF5uiQfvCEeiXfwMYCYJ7uzNnNdY81DoQyPY4gt(fz12soBv9IAKCdmovicEXJcF6SXrT88hfEr)XPDh9IBWa5XXNxMYEJeR3Enpe21XKPyiImroL0CkGFOBU8qp1OtpK)n2svKZ)GwEue4W(RNbnPWYm(OTQmrKzcHqu94nQP2XTwLfoc(G(Hh2p8r9Vk7vmaBz5CwulwzlIypAejDrjntfjF8brg(Dmp1GuL3cs5jxPhjKKOxmUK1vgFWZu7xNjnttJ9ykWNe1ArvCWx8fmmkjapJpXzPeV)u)WZcNdEUv17OFYKdNCWRzoRLQovGMO4nQuLLj6IdN4cjex1WsfTrmzYvgyeXbV0idNjwsO3J3IyEfs(P7do((wCgjlvjedSOQEpgLYj5iIopuMi0SHzZN7Cw5vK0lsSpElWRZ8(zrt0ZeILZ8WYqt(Vj1fPImCFvPfAZ6CPqq)hbgWti)BkqfYHbfGHGZdj9uP)9RP2koQXSelQ66YM0ROCiHgeAxNI9QEVSBPMnm6TsFggREzzqCiUgmTmkRS7O(G0kqgpTxy8LokCbbyIBwrwLneo5jHlY4rWLW5ZLHRax9LGNxaMc7ZSGe(C5G883KmqGIcMNA7y3S(RoLdWauav4AW0GgucmZA(e78JYRdCGRFmWsW8P35wVzvtukbkdZaZcZjaZZNvlKf(jGwHFsFWlq59WNkl8trzUWl1cSi8P5eB4Lzv9zyLVc8tdlX4SWptfQk8zrQj8ZIKs4Nta(5Hp3Df2h8lCo4Zd)IWY(GFj4xg(vQrx2l8QuUc8Av5jDLp8cwLU0qYNUt4xvb(cWVg8fHVe07t2c8RJGFFWxET6xDGxV5WrrCFGNfwHc4zOJUIsb0ryf(G3ae5p7(GVm8vGx3JMWBpJGGnHYmGFJTHl8f3Zg5cdxpkEfhwabuNpqnwRIehefFdk4V2nYsH4PmpKxSdPvDkZi5mm)ThGhhxDrlABRH7RDs(BZmVtvSU5tTjOv1gTf4QTMAy(y7qNufkVj(t9CITyNYADrdejgJaPqFWbIVVnbXp95tzwo2WJF(qJUnq8LRU6G47odrbSFspa7qSiA7GweUoSn(qIsfrzD419vp(EiAd7M5cBeEj7H2aApiDj6MEBls91IUjV5H7jzSuJIUPNmwpNh3XFWmdEHeCS)3Pc2F9AWCC0Mf(6W3GkH)7Kf(dAURqiOh9WRQLMUlKKJHfDYKc(D3kSFtOFjCFhyZqEbJsJMUCLuTSmSuymYhexVpS)LZvXNe0u3R)TXwwaoroeMJ(xW(nE7V1kST9hTSMnzXkH1fim7r2KH2SjmyZ8wehYuwvIPPbJ)N38S1CyiMS8i62xzcI00XOXlFLuezvPR45AH9v4XHofle0wDkkXqku2ocsqcpfZ8HOYolt55lw7f(CRsIgtSVUdpUZfNKbLOIsVWjZXDExbsmdsjwLAqqpuOzlWJFy59t86wGps24wsQYz3EsZRT3dU0JccvtEcSNHmpA1GtttSmrX3GPPUbvxsr4xyhmf6rJ5XQlxjKGXXaKDcoHQJIQU5hT6TsmNPHnjiDDsNyBdFyy)0PTF4GW9JM47xanXFe4q7JIvdWvaq2lsBRFLVQs8hdEKJhiufNjO(wqrxNm7w4qXzqrKN(aV3P9CJ0nQorIxgDD1Zasnlm75ZTQQw(zoDQ5p1aZneeZhe3p0JpkenHFQHBPhNT9coJEaMNwRN3Wqddcsp9SQOZsRv5N0CxOS5P8BYNY)wXd3DNDjgUTOT3nTmAiwzywzewzBSY2zLrfJens3yzNHc3Hf27JORnFwCr7BSflAwdetmvFJNS(LUZE5BonHygJgGGJifyQW2Kc3qk(z)RxVOMXS9zrUEzIE(55BBfNwNYAiQSFnVGzvwMwxAEIiOxMKLLLJSk96kbbYAtTWiy3RsGx8WtP1WEJzuuZZGq(wK9tCNK1Zv2XXqFe0pBnP5z9vsvSjnXEFX5PzBPhITXzZN08DPRH12ABnESMXhjtMrsbx)r4BEvGT51wUX1y3EBC9GqsKi8DHd8w7HIKgUTbnsvu2uRl4pMpqEvMNalwbLKT62n)5MhUsLufNEvTPrkG8Duo51gdsMLYGWDD4OFkK(eCfrp0)gQ5H3unueogosLDDUbzotvU8zg1se41d0gD)NN1B)NSWBqZ1uRHBLUWtPYpJVnc9H)QSW6kBlTEO4Hd3gIRBVTiTXkBNvgDBGTWFBJaw4VREik83ZHLW3xbUHc8p4d(hpc8pja)a(Y6)mITG)f4F1h82W)g8V3e8FC3aLa)N3lGg0DegRT4dNE6ot0P8ynImG)RAqI3cEN7YMF)VNmKhxST2BVZW3wA07USB0nEzo8Zsc(06mgj3o(YBYAUsTgT)KZSrR6frR6Pwy0KxCeLP1U(KBVv9V4h1w13SMvnAOWW3l7)FNqsnDYxuA0OYrlinuxBVP7V8EMPluC0tVzBE8rH9CjZhUQhkXspAIEYem1GPtp4W9xNxBNxvtlypgLkjPlxNtEPm0lAqDolo6JQ5jQwFFe1I6b7fDNxj4OwgLmDmBQ6n73i4fqxxSyoYrrpFBg6H76gnpz5jpWDQVBRIbhuUKEAANXJqohFVxrjnCObDzz7irp)hbQ)wONw1CJ1IF(oKSmpmJ5d9SEwV(bD3K6t4dUM886sLuZZ8wg98mUTHLdez5IwQ80OFWfPxsDWOzXEf1ulP6Cq6ztKKELYnYBOJVEDN(KYJr5KtmwVdoE6CwsYQLTF57h95CzjR8CNDqaKhAO2bngtJy5yVsHYAA9OALxdhQEEu(Njq9D8aA3boTIOmok55wnU2iPkQm40t2)ql9eWac32u9Va6ez4oIs3(nCxSYUzBfZ3ComRmcZfZoOUy2E7O0qOoBFDCzpVcXoTIXSJOVUn7pPuTPzE(9WMbpznndQ0WnYcVT4OQZr0QPCu7iBchLPH89ZsvwqveMcYoZ5FfkN))UchNr(xHLfDwQw3qGt)p7VTs1Rd4kCu6jtspt0br4Gzl1IlK(Bm6pQ4)udtp9iYuIsZq07ZWQeF38yfNjp(ZETSU(gfpQMpbxH7BBupOZQVfe1IECKJu2HfL7Q2AQYKCgOZWLG1Iq7kkGyl0vw6qlZoAqM3Z2oymIfvCy(OJXoNVSn2b5ynyE6icXuUcNMxXC8kwdJEEzb25nWQoBG5LpqG5ewMfOnTBxSs3sF5RJxRBRrp1j8wMnv5EzQunoY4jxOsfzz9nR3Y2OQ3Tge)1rq8RW3HMDAL8uYDIL52unJIRuREeq(ywt1BSuX6pXAmdVLQJkoLYIZXOqQv45CpysJIWJlkgB4(tWtR9R4k0f2PUcD7kCwAV4k8mUcpR3J5kCogcN10LAseNx5Noo9S7mBI(wks0jwQ55KKSR3WpxLZzejsYZZY4oZfIHLkr2)l)2Wjez)07qqpwpEU)tvOlAHHff8umq3PndWYnqrDdlIbgzekLrYUoIx0sxP7wR(newVQhn0BXYGjLyYZs)YE2M8tN18HOxtOhHF9nNsGDfA1mah94DW84QMAEZwlWo6Ed9t5C6GweKmOh8uoxo8vdAyf05YrU6PdIda8Q2UAqIU8o75qfvaxHNOrjGUI4LMSnPa8dBNdP6jBN)GOgcAeBudXvOfZNCJshXYPQP6m)u8nmMIAQ8SuC5dRoMU8LmlpN2edUT(E4kiSZYhiTMPC4k8KWAUcFITxVWv4PCfodfV3QRWtxtvWviu9kcUcHRif4keXvGPa5kG)xuSZCf6iRRqNVNi0VkJRrjRuhBs0BD8mX0tGo6SOmX2HtPze5s4Eou1MSSFv5MzxSs9I9osVviZv6CxHXAG)6kKgEuxHm4OEC8FxWvyIkuAxHNZv4h3vigwFCxHEOmvxHEDUkTRsWPNUc95k0p2GbwVbNSCfgAdemxHZJnlzvEKRa(Wd)UNjWSf(4LVFNiGlvV75bPNvTGtAhl1PjCEqO5gTZOHYeBo1(3bEWE(abp45Rpz8WFuJjGVtAc4HV5Mt3(obx3)r2)wIxxToN)VfO1Bx322KGD7r3ob77yjwCwTzO1P2oOLOrXYKPyZy2eMdSYOnU(cA9nwptKChaw((adW6hubyzEKgor6kNJtGNf(Anhg1gHVkf8W(opA4SRZcVzJFsaWVzDFgavsGGRaQY2SRWJF3jyGnk(1g7mU8D3ioaxHtUj)))mhFlawp9TqZINaDJcokeEmZm8vQcleo2e50CIm4o4))E3fGVcb)VWxc2ZNT6jb1tV0dkb3Xvvsl4ei6rP6jbXUfUEHXqlZYJC18tWUd1PxAQ7TB8bMyE0dwDVJH6On8asMQYb7t1I0y9POF2tNbDO2PXEcJevgBmZD0Q5mHDN6u8QMuJNAV1LvdxH9DG70uA4k8HQCw)Uc7NwCGnN8cxb)vYBHRWbRLXcxH7ho0(CfEaanmp4bDf(inl2RRWHWRAcvPd4k8qUchML7bxHJulPd191MwjCbBxHhEJjCq4Us(g6EY4tMiY1snBKjPcp3o5wCd7oTcn(NyAZknVDLDPsoZw7vvdyS7W9PUTtj5oiKe72A3PgZdSRW1OzCW7liplxCOarZAOWzkhR8c7WMp5G3rHjoe7U)r9SIHEfWYg(kdYcVbKU2wlVhSWUcAvTSZVLw21QxIy3JHD(nyyDf09mOHUwOZRD62Zny4lTdg083dnOUcM3lnKx93BlnKlxvrFxJveNjBNv8uPSdDH21sn21f3bRO8UxR45)d3A6y9BaVRXqItMTZqgzadrZHkou3DKEhmKKDTgYm)jBPDCLAUl9(dR4T9rU1G1BY(AFY5I6ukJ1ojMwyxR1R9V6wB9Q5u7UzR3PlmyBwxBWbcnV8oy9kU7ve9v(ABTiA9XESRrefNmBNHuMyNsl8qfhyMDkdjk7EnKBtYXCfU8Uz(xSIDxo205e7wAYDWSP(JmZgnDcFoyph38WvdBDSYQ5Noiv4ZUAS5HVxfAE8Kj6lZp8IoV2Nw6Owg53QaZ)E3vcmV)2ZpA8Z3BOHhO9B7p6hwO49OzG(VN1BXmEhHJg6o7R6A7pcVOE)FXX9QtU4y3YtU4DhR6f5mQOkKXfN(65MymLDGr9PQKkVnWO(oSKYXZLh1Urtcxe4BZtyhlxDHPOUqE)nCwQrME8(rzPIBl4F13J0g2f2NbMxiWCVZTBo9cukGCa5L(4n8LHFjOB47YY551OtDVpHB6NV9BT)3F)5BJS1n9fBp2LU0ft0J5Cly32w8fBhWwSTwJ2AOaZS3x4)7d
```
