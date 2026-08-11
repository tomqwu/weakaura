# Mage — Arcane & Frost HUD (v1)

Programmatically generated WeakAuras pack for TBC Anniversary (WeakAuras internalVersion
45, tocversion 20501). One import covers raid Arcane (40/0/21) and raid Frost (10/0/51):
spec-specific pieces load themselves through Spell Known checks, so the HUD auto-adapts on
respec with zero user action. Spell IDs only — aura triggers carry every rank ID as
strings and cooldown triggers carry the numeric rank-1 ID, so the pack is safe on zhCN and
any other localized client. There is no custom code anywhere, so the import dialog shows no
code-review panel. Import `all-specs.txt` (or the fenced block at the bottom of this file)
whole: copy all → `/wa` → Import → paste. Heads-up: the `/wa` editor preview force-shows
every aura at once with placeholder data (load gates ignored, identical fake "55.1"
timers, both specs' icons visible together) — judge the pack in combat, not in the preview.

**Resources** (three 172x14 bars stacked flush below the character). Health on top, mana
under it, threat at the bottom, each with a floored percentage readout on the right edge.
Mana is the mage's real clock — Arcane plans its mana to hit zero as the boss dies, and
this bar is what you pace Evocation against. The threat bar only appears when you have a
hostile target: it runs green, turns orange at 70% threat and red the moment you pull
aggro, and a pulsing red overlay flashes across it above 80% threat (party/raid only) —
mage burst has no passive threat dump, so the bar is the warning system. Health and mana
fade to 50% alpha out of combat so the HUD breathes with the fight.

**Buffs** (static 40x40 timer slot under the bars). Arcane and Frost are mutually exclusive
at 70, so both icons share the one slot. Arcane Blast stacks (self-aura 36032, 8 s window)
shows the stack count large in the center and the remaining window at the bottom, and glows
purple at 3 stacks — the cap is the decision point: keep spamming Arcane Blast only while
Arcane Power / Presence of Mind / Icy Veins are burning, otherwise fall back to filler until
the stack aura drops and rebuild. Ice Barrier (all six ranks) shows its remaining uptime for
Frost; pushback protection is completed Frostbolt casts, so the timer is a rotation element,
not decoration.

**Alerts** (glowing 40x40 prompts in an upward flow left of the character). Each slides in
from below and flies away upward when it resolves, and the stack collapses gaps
automatically. Clearcasting (12536) fires on the Arcane Concentration proc — the next spell
is free, weave it immediately. The Evocation prompt fires when mana drops below 30% **and**
Evocation is off cooldown, in combat. Barrier MISSING fires when Ice Barrier is absent
**and** its 30 s recast is ready, in combat, so it stays quiet during the cooldown instead
of nagging. The Ice Block prompt fires below 30% health **and** only when Ice Block is
ready. The Invisibility prompt fires at 70%+ threat **and** only when Invisibility is ready,
in a party or raid. Every paired prompt requires both conditions at once (`disjunctive =
"all"`), so an alert appearing always means the button is pressable right now.

**Cooldowns** (auto-collapsing horizontal row of 32x32 icons below the character). Cooldown
text on, mouseover tooltips on, and each icon desaturates while its spell is down. Talent
cooldowns are Spell Known gated so only your spec's icons take a slot and the row stays
tight: Arcane Power (12042) and Presence of Mind (12043) for Arcane; Icy Veins (12472),
which both the 40/0/21 Arcane build and Frost talent into; Summon Water Elemental (31687),
Cold Snap (11958) and Ice Block (45438) for Frost. Evocation (12051), Counterspell (2139) and
Blink (1953) are always shown; Invisibility (66) is gated on its own ID so it hides until
it is trained at 68.

## Spec gating summary

| Element | Gate |
|---|---|
| Arcane Blast Stacks icon, Arcane Power CD | Spell Known 12042 (Arcane Power) |
| Presence of Mind CD | Spell Known 12043 |
| Icy Veins CD | Spell Known 12472 (loads for deep Arcane *and* Frost) |
| Summon Water Elemental CD | Spell Known 31687 |
| Cold Snap CD | Spell Known 11958 |
| Ice Block CD + Ice Block prompt | Spell Known 45438 |
| Ice Barrier timer + Barrier MISSING alert | Spell Known 11426 (rank 1) |
| Invisibility CD + Invisibility prompt | Spell Known 66 |
| Threat Flash, Invisibility prompt | party/raid only (`ingroup`) |
| Four of the five alert prompts (all but Clearcasting) | in combat only |
| Everything | class MAGE |

Two IDs are worth calling out because TBC reshuffled them relative to the classic era:
**Cold Snap = 11958** (8 min CD) and **Ice Block = 45438** (5 min CD, Frost talent). All
eighteen spell IDs in the pack (13 distinct spells — Ice Barrier contributes six ranks) were
re-verified on wowhead.com/tbc before this build.

## Regenerate

`lua5.1 tbc/mage/generate.lua` from the repository root (run
`tools/tbc-weakaura-creator/scripts/setup.sh` once beforehand to fetch LibDeflate and
LibSerialize). The script is fully deterministic — fixed UID seed 20260816, no time or
environment inputs — so rebuilding produces a byte-identical `all-specs.txt`
(sha256 `eb0c003a5310a28e064f9ceb9892fa06dbc2b328294e26055d9c5b86ea59886e`, 6148 chars,
26 auras). It round-trip verifies the encoded string and checks UID continuity against the
committed `all-specs.txt` **before** overwriting it; `changed` must stay 0 so in-game
re-imports offer *Update* instead of duplicating the group. Future versions must keep the
seed, never reorder existing `W.uid()` calls, and append new auras at the end of the
creation order. One import-time note for users: the Update dialog's *Arrangement* category
is checked by default and will reset any positions dragged in game back to the string's
defaults — uncheck it, or report the coordinates so they can be baked into the script.

## Import string (v1)

```
!WA:2!DRvEWTX15DVgYXsq(GKsIkskXgM2ur0XwIhcIK2XwfaeqeuGGqlajLSvdWIDFe7kUy3v7UGuKPonMXoL9ofT1EABstmDR7mD6jMoE60MzYyoEA606P9ROjUOnPxAA6KEoTQnTtV737T7cascqjzj3g6)Gl39D)EF)(9D9a3mDj(5p0Qpy18cIZlzQBerxv3CcF(8LYx)hpOrxI6A2M6QQePiYkQsMeTjQoPqbsGhpW4ebvB5kUFnPGMGxnzKnjc2g7BdFgiMQGL8vZRBkrmd7oDgDewvz5LfmLcKrxx1wXW8ktn3CweBU8gc4SzBCi2OKjCeCKczkkOrcC0aXm1TSZ7mwYMl50LlVMjPGIUwMLmi8fm1lzSMtlsRSm5UQOOnNUzrbBSf(R4uHZULJJZxvHs2Y6MtzqR2YFECFpNsb)McIScofVLTGPT)8ZPOPyj7pm(pB)RyBQuOaX0k5rnDF9LcBtNDHsMcdUo9PLbrvvrY6WD1F4syNYBOkSeXCfw5XLS8FvRs5jlG700LMBoLRujBKqPZKnDMq8zQxvktcwfF6urtK4ALSirVcUUs7mc541eksS8VMejpoc0nV54rtKk20jkxsZDz5VIKI1LkPH7MfidkOQA0Pa79mo1pPUe5N7oCpUIkvGy0z6lxcfabIvsvnWSYk2K1DQ15SEpLf0uCompf0DS1jcwK02OaRGT8DdhjSMUgPQeU)PTil9mX0IGhQswRqBkDvcdgUOGIwmyaSdWGWqWjHG4)p4MlPSfrDUu6kA25JenzMO89Oiz0Hl4INyPxYuKyDnSEIPMG6m4uHt6Zwzot8Gbxuc2c(UMGMikFJrlIo55thHpA0KRzRlUGt73DQdmyjfPkhRqWlVS95nYeEuElrbvIV1qXapdzz5bCIRHNb(wJUHuCqmHv1fK8xXzAylwyKv7Fnlefp)Sks2YhynfS5Pzl2pWDa7HdU3V2DaXGrQYAdVUn7SIZOZn8nvYeo00zMkmT7YWH(Ohfo8lHhppa8qqp8m4rEhQiw0dcb8VccqYsHA5GhgEe4O(HpeCmOp)n3pysJ9pn2KarKfOyCIPILTIOL7qatTP(cpk8HHhdri0frwrpLe(GN4zHHHrwjVGlxk1U6)4deK(C4rOphmOpeyAjytHce51z7nhi0f4GWpr3WrQqPj4aKf)B1Un6YMCf7SwYcs6lEExDbLzLrFy0rViuse30YS9CV9A0rtDObH(QoL6HCGZASpwjipxNIBfzcLWHWpVgRcKGrKyf(8vDKIxWD2xNv)LkHNqZTemYAMurdjdwy4KtLmkCeteGqBZASg240XzzphQc1OJyMklh4CLeKOWXazYy0F99uwh9sz3WglRerejyQznmXxSyiJMpA8wCvzLTiIkN1uWyLzDFPA9PMPqyQPZKiEYOUNvnbsRepzYO8z5JFMXZy031zjHQu1KyKz(5u11nDoywaxD5vj5AmLu9ThY9q0teA071zWDkmFYsfZtmxaosz8q1HSv15FUl7bryIxj6Uci3pfBi9DlXBT5sBZsqvBWX9(YcxN(YltukiB)bHOZuMYCerZuw5YBJmFn7U5lwcTk5NNv6rZBPOvqLeEYqNjk8j6g(K5cJ6Xf7g(e(dthm6lxLbXdJ9wIYDhm0yJz0boWHKOiiIerAsHRid(HrDuoePbzAF(3Clvqg)9z6sqG97Vz(Z55kZyJwkseEMae6NQlEZ6tp11xdlCaSJ(Hd6hE)(RWMIXzhkpLjvEvYKWhrLiOXlOAil4ZzrKXPgJJfNQ3DobrYfJiGueTcHfmV40XF8gF94PzA0yDtgEAutlQbh8fEzD9ICWt6JFrkT7n9dFe4PGtxHu4k5tm1PcLWAstfnQ6zIS7QsrsIOXNm6mr5ROBQGsiMsY1gFk(4pZujZekbm2HpkVOmrC(yWHVRvwqWuraraROOfrVyEbB(feulr46r3ONN6PmfLf0kqSo8rHxH5WZkgOtjet7LGYqN(Vg1ROcmuFDfl0Mn8Q9dN5aW4UQX)cCu14qCoyc4SqcxD0VEdDT8P0xKys1Tw2G(gLbXTb1SvPiV61LRLASHuxpTZW5AwPmWpHJgy2oJ(6Ob9bPLHmUkEHPxTBygoy2R5PtLTc6Tx4cmse8m425zHlcF7pp8r5GS4qMdeW(LheDMijGaf4mow7O2SXRj1gGoidkWLG5bvOiyKZ4r2(U6ugydx(qGjNXj2(wVvvMOEeOeSaSiCfoyjND1Y5GpgCC47Wh8Cusp8XZbFNuIl88hfwb(Ko8A4fyf9ISNFk47cwLrzHVBpMk89Gmt47f5KW3hh89d)a3wiFWp4tbFA4hck7d(HHFe4hTbBzxWlrPkWlxNMep8Z0FF9n6WtmSi8Jjd)4Wpb8zGplf)d)KuSp85Gpp8kUiDyT6yC4vzGB4NQnW5pZDUz4CYMbIRzZCNN69aQK0SaXgbIxLIFBurokkDsJoC98pTIDjgpLbBVHXSJqFmuRHSR3RZSziAxhVA8yBbEuVrTaB0A4TXdTndsD44w4anJRBHPUgdXgidmunsdEVdm9U2cmnsXWZo65gB5PIhBdW0h1bM6d(CLRF6aVspd3pfW(0Ua2jyXHEk6Jb8Hax(6DIxOaQzgEfFnJVNG2Wrz(GoOZtwN2eApa9i6AUw2OolrTtBS)ijcnzk0p7eHICw0OD8mXNjQd2)3Wd7xTbmhxT5GFE4xGQf(xmh869ms)iOhDrRUKMAirWw3KUzMe(LAf2Vt0XchZ)SDOZdCDpsqu0LVOIPPUPmJrEF459(9xoVNBfOOEm)TrwohCK8imhDrG9nw9xCnML7uLuTiR4fvwxdW6Ywe0gDIXkkAsSjzn9ckzdc)pTXt0WMFijPP0SU4SeH5drd39ItsKueUOR3bwx0jmYSSiipUDbbgsHY2rqcs4PyM3hvTtzkpFLgt4PRiC25sfnM(SZnBrguIQu656nVJ33Yq0fqkrfQabDYGgSVl)W09t89Jc3FUWMcks5ApP5L31Ex9bbU6P8aUZh14WUXw6MUHWOVFOsmB0zalJUCRlUiwHGj6dIjC3WUPBb)WEH7bfx3dhkUUFOJ7II76YHnJmrKc28PyDTQFa4dE4U63Z2o1upfP0BUwyF)XrfcNypVZPWoh4R7Ufcxc9J0vuqpGzsMtxjyIIbNqjsS5dYdH8bH9dr8rbBr9tfbR(Wmdf4(5EzU9uvuxxfJhrl9IkONlR79jnjcYTFdZp0P6FObVH20pXZET5jeJqupTT5PWdzMPc0Sq4jE7Qfu1xmMj5YLiAIl5y8WjImAfRJ4JZO6gxyUvOfXYoukmyp11OFMGLYIduH(UxmvLl41fM1Otf0XqKpwJ8cOjm9dzwttZstaBLKrwrCEnILLpwnjuW37KnrHDsw1Q7Jz)QNETUj9YQjlmJax(HCmCuF0mEhpAR7eby4PYKzQjHlFqNbEoMfPwAn6CoupMjFwwSMxdL3EwNEHTyJATgnA3NWJ2DFqcKV8wuAZPRKivQlllgm14b1HVGZQ8Lyh5R4HMYv3aZVLX(9kKQJzmflQ79idhvG8YNdsKJYZq7moCekW)io6aD5iBQKdULsOmbpFOq7m5Ty8E4v6AOMT0KdEvAAHo(ahNkBPe9N03MPgWVto43T9CGlXpWaNCWtXpWq9p0aSNdYEoe)GdpWqNKFOHoz)bVbziWVxdoXt82qvxEWxvg(YYWxZh8hCaOgh8h6C2(hXHlGFF4p2h8vQMVKTTU2uyqwQclb)jDc)PY3gWuWFwDxBU(aj4pV9yh4Q7(XwRvqMKXtx48JvC8ZvqEJqg4VObw53g(63MXf(DL09hgTXSyptNcUZNPEEUPXiJwmyr9ACq3cJUGUiZKwGuM6fnSn62t7RJXJatgpD64jpt9oWmSOQloVxh8SgfxJLndfvf7LCRJz5HI3EdgEZXwdnoBrY9ERASPc6zsPIAPPdMJ755D0rWlOQuqdgXezg0ChZrnrGghAyd10j3WyCSutIH8HM1x0DCq7JuJy336slPjuurKzQgnvg2s30ggSCbtfNKWT3vOVsvw3d)y8QkfvS3lnZMjOVjFvrDnC61SJjiIUyLNp0yXNoDEtbjLswVW9GgjlJIchD7iQYfq4D)eHuX4STwBUsQQrumfvXfQRjW3KJASBpQ3c2yryMdm50vgSVZDSix6slmW0h7Mu3WH5hyWGdDQBn2pLK)LZbFf4TBW)D8UKkLgKPi4RMJQEavf8)5u)BKiAyu(AC3TdNpwFfIFYzixyu(fApN)FSnCE6I5lcbnP3(WuLSzEfxXsvrIKxhvbweEJbPJevk2cTbR2rz2DbqXJvTSrFkliBZm7J(AlwYchG8SgSeDbHaHAC3JtbxXPG3a92UmhlbJSIZ11ss7PRRWvM5yoDyxXByPtEv8DnlvAAMXQm60RUmEfJRmNGr8kihBSzJwUnQR6rGX52EGhnDv)LEX4yCGnKtfVOy66JSEZL3Zq9Jb18ttbOSCwUHeXKdETnMEl4NPPuATAN84QwC(W0uXB0jTZfiAetfX0Y6loLwUQB4ZkwS)XteKwILcnM7ejfks29j2hCeE2NU3PXHI46Aav)ybm8dRahJDnz9z0flsHcA6MeD0AhQBHKRkIgut7nCLRRQUADxBOLZsMbD17Sxk7ESloFoJ9rFNqVmUMBEB5Mp62YnzqzweQ(Ab1C7jtZvNmTglh2SuDM76tSOxli9cjJJ6tn6PruD0VXy3O7PSjPxEdjBQsMfioeXZDHckhBQlqMjfzZeXgzc4ABprejimoynU7fEJAC3x7zE14U)ACDahPgxN146Qb)Qg3(AMBvJB)EKQAChOgx30HQg3bRX9(XbRg3HYvJ7WVJOgVMR)AW3a(RG)A4Vb(BH)UQO9nrzILdgTQdgDsfl6feSDATz4)ACpqnUhSgxaCj9q146H2HACpm1vhCx(ioG5AC9wJ7Oyl(qvAkwZAC9Tj8ynUhfB0h(wc2DshZc384UpLR)BoylgaSg3JLB79HdXD14ECJaTgUHB2SjqEKMTdyluYXp7SdUCSbcgR9GT)P3Za2AKRPnC9yo6BtYGwiycrauP)u5C0FUHMMZO7nEZAnuHFJac)L)4TeewUUFPVlabPxxS3nu8Ufge3xBfd(qTgdY(5L480beos4L4JnFQ5JvA02dc)NFVhie(12ysohMMKt4xFRP0C7GuVylbuR3C8m3(XumpDpzq3mhFtcPEn438B8MTY5uhK2xYfSXGzx9fBbUQVnJRc5SpZsJajBZ7Ch81Krgwxxy0HMBPTrj33Cha(QF4Fa(SWD(Z6gMBKXAKgv2LG6gnlR8u0CuRHQv0NlWKkAsUbsZQlU4sbMHOOzzeOrHPlvSigi9SO7UMbIQsOgjqpEBQBrq3)cKwtWyJJLRMRMlSUZEnVsJOxIk3y(YDTgfhwvrB(MB3geGEXG)y7QPGWH)L9ClNT3)163k2)g(3)(wJZg(p8IWg(pBeAn8Frt98)nkQ)F2BnU7adFUghh(2DkxJZxnUDvJ7UyrixJ791i046)EQ88G2Qg3U3CyXC3wIkEYrU8yloJTHHbpvD0nsuXBs1YAu3TcPUOWswEwToH)wRKPzS3TOsMRBY0G)(RRULq3qP86eBYn9XPo17(7JmNB(Vgw9cjwWmO9ql22yHRX90WxxMPXi0T)eJUMUMhwzt3cxo4vH0nS38oqaxJBI6c292sbRrhBw7XohP7E3K0TgxcxPQEHegKXwiYidV82ivp97Is1ACjF3uA2)VA7CU0vD)ogPiUtANuuB5zgjtFfh9CptWTrk(TTZvk(X(sTMt2DRnqVJrMI7R2jthiru1Hwk6mtNzGTrMgANRm94VERzM19OAhJue3jTtkApsWZBUqgTPpvYTrkgENRuSnbVxJBKDmIVnhNEtIVOdvAmjl5HuhnY2i(ISZv8rtODlfFh7BneF3e3zttITuk2IjfNT0qeZTrSn2owX2VsBsWrZrtUtw(D(bMOWeZoq0LS3UynIUJv(T)LBP8JNf2)ozbxMZhQVGMZpyM(7BBeCX2Xk4EX2OT8j3PyS7fBROl)Gtsso8iP1YeFBeDN5)VeDDvSlPUKw9b2WpCYjGrH3ILa0X9(jrs)5q(w7(BT)5qc7DR)giVI6ixsZ6SfvgEIw8BGSll(HoEWJ3FxlSRN7)9d
```
