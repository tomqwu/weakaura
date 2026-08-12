# Mage — Arcane & Frost HUD (v2)

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

## v2 — rotation fixes

v2 is an in-place update of v1 (same UIDs, so the import dialog offers **Update**, not a
duplicate group). A rotation review found the pack rendered state faithfully but left
several real decisions unrendered, and let three elements fire when nothing was decidable.
What changed:

- **Mana now shows the burn/conserve breakpoint.** v1's mana bar was a bare percentage with
  no threshold — the single most important Arcane decision ("keep spamming Arcane Blast, or
  drop to the 3x Arcane Blast / 3x Frostbolt conserve cycle?") had no element at all. A thin
  amber line now sits at 30% of max mana with a brighter line that pops in the moment you
  cross it (in combat only — drinking afterwards is not a decision). 30% is a percentage
  proxy for Icy Veins' "1500-3000 mana is usually a good time to start this rotation": raw
  mana moves with gear, the fraction of your pool does not.
- **The burn windows have a clock.** A cooldown trigger reports Arcane Power's and Icy
  Veins' 3-minute recharge, never the 15 s / 20 s window they actually buy you, so v1 could
  not tell you whether you were still inside one. Two new 34x34 buff timers flank the shared
  buff slot: Arcane Power (12042) on the left, Icy Veins (12472) on the right. Arcane Power
  glows in its last 5 seconds — that is the Presence of Mind + Arcane Blast finisher cue.
- **Mana gem prompt.** Mana Emerald (item 22044, ~2400 mana, 2 min) was tracked nowhere. It
  now prompts in the alert flow below 70% mana — low enough that the restore is never
  wasted — and only when a gem is actually in your bags, so a mage who forgot to conjure is
  not nagged about a button they do not have.
- **Ice Lance / Shatter window.** Ice Lance (30455) does triple damage into a frozen target
  and v1 had no frozen-target detection at all, which left deep Frost with no reactive
  decision outside a raid. A new prompt fires when your target is held by Frost Nova (all
  five ranks), Frostbite (12494) or the Water Elemental's Freeze (33395) **and** Ice Lance
  is castable. Deliberately not `ownOnly`: your pet's Freeze and a partner's Nova open the
  same window. Bosses are root-immune, so the prompt stays silent in raid.
- **Cold Snap is a sequencing prompt, not a use-on-cooldown icon.** Cold Snap resets the
  Frost cooldowns, so pressing it while Icy Veins or Water Elemental are still up throws the
  reset away. The icon still shows its own 8-minute cooldown, but it only glows once both
  Icy Veins **and** Summon Water Elemental are on cooldown and Cold Snap itself is up.
- **Three cooldowns glow when they are up, in combat.** Arcane Power, Icy Veins and Summon
  Water Elemental are press-on-cooldown, so they now glow gold the moment they come back —
  gated to combat so the row is still while you are riding to the next pull. The reactive
  cooldowns (Ice Block, Counterspell, Invisibility, Evocation, Presence of Mind) do not
  glow; their prompts live in the alert flow instead.
- **Threat bar is party/raid only.** v1 gated the flash overlay and the Invisibility prompt
  on `ingroup` but not the bar itself, so solo — where you are always the aggro target — it
  sat pinned red for every quest mob and trained you to ignore it.
- **Clearcasting is combat-gated**, like the four other alerts. An Arcane Concentration proc
  from a pre-pull cast is not a decision.
- **Ice Barrier warns before it drops.** The timer glows in its last 5 seconds. The MISSING
  alert can only fire once the shield is already gone, which conceded an unshielded gap on
  every fight; a 60 s shield on a 30 s recast should be refreshed pre-emptively.
- **Health bar has colour tiers** (orange under 50%, red under 30%), completing the danger
  pattern whose action half — the Ice Block prompt at 30% — was already there.
- **Every cooldown icon is now Spell Known gated.** v1 left Evocation, Counterspell and
  Blink permanently lit for mages below level 20/24/32.

## Layout

**Resources** (three 172x14 bars stacked flush below the character). Health on top, mana
under it, threat at the bottom, each with a floored percentage readout on the right edge.
Health runs green, turns orange below 50% and red below 30%, where the Ice Block prompt
fires. Mana is the mage's real clock — Arcane plans its mana to hit zero as the boss dies —
and carries the conserve breakpoint line at 30% described above. The threat bar is party/raid
only and only appears when you have a hostile target: it runs green, turns orange at 70%
threat and red the moment you pull aggro, and a pulsing red overlay flashes across it above
80% threat — mage burst has no passive threat dump, so the bar is the warning system. Health,
mana and the conserve line fade to 50% alpha out of combat so the HUD breathes with the fight,
and the lit crossing marker is combat-only.

**Buffs** (static timer row under the bars). Arcane and Frost are mutually exclusive at 70,
so both 40x40 centre icons share the one slot. Arcane Blast stacks (self-aura 36032, 8 s
window) shows the stack count large in the center and the remaining window at the bottom, and
glows purple at 3 stacks — the cap is the decision point: keep spamming Arcane Blast only
while Arcane Power / Presence of Mind / Icy Veins are burning, otherwise fall back to filler
until the stack aura drops and rebuild. Ice Barrier (all six ranks) shows its remaining uptime
for Frost and glows in its last 5 seconds so the reshield lands before the shield lapses;
pushback protection is completed Frostbolt casts, so the timer is a rotation element, not
decoration. The two 34x34 burn-window timers flank that slot: Arcane Power left, Icy Veins
right, each appearing only while the buff is actually running.

**Alerts** (glowing 40x40 prompts in an upward flow left of the character). Each slides in
from below and flies away upward when it resolves, and the stack collapses gaps
automatically. Clearcasting (12536) fires on the Arcane Concentration proc in combat — the
next spell is free, weave it immediately. The Evocation prompt fires when mana drops below
30% **and** Evocation is off cooldown. Barrier MISSING fires when Ice Barrier is absent
**and** its 30 s recast is ready, so it stays quiet during the cooldown instead of nagging.
The Ice Block prompt fires below 30% health **and** only when Ice Block is ready. The
Invisibility prompt fires at 70%+ threat **and** only when Invisibility is ready, in a party
or raid. The mana gem prompt fires below 70% mana **and** only with a Mana Emerald off
cooldown in your bags. The SHATTER prompt fires when your target is frozen **and** Ice Lance
is castable, with the freeze window running as the icon's swipe and bottom timer. Every
prompt requires all of its conditions at once (`disjunctive = "all"`), so an alert appearing
always means the button is pressable right now, and all six are combat-gated.

**Cooldowns** (auto-collapsing horizontal row of 32x32 icons below the character). Cooldown
text on, mouseover tooltips on, and each icon desaturates while its spell is down. Every icon
is Spell Known gated so only spells you have taken (and trained) take a slot and the row
stays tight: Arcane Power (12042) and Presence of Mind (12043) for Arcane; Icy Veins (12472),
which both the 40/0/21 Arcane build and Frost talent into; Summon Water Elemental (31687),
Cold Snap (11958) and Ice Block (45438) for Frost; Evocation (12051), Counterspell (2139),
Blink (1953) and Invisibility (66) once trained. Arcane Power, Icy Veins and Water Elemental
glow gold when they are up in combat; Cold Snap glows only when both of the cooldowns it
resets have been spent.

## Spec gating summary

| Element | Gate |
|---|---|
| Arcane Blast Stacks icon, Arcane Power CD, Arcane Power window | Spell Known 12042 (Arcane Power) |
| Presence of Mind CD | Spell Known 12043 |
| Icy Veins CD + Icy Veins window | Spell Known 12472 (loads for deep Arcane *and* Frost) |
| Summon Water Elemental CD | Spell Known 31687 |
| Cold Snap CD | Spell Known 11958 |
| Ice Block CD + Ice Block prompt | Spell Known 45438 |
| Ice Barrier timer + Barrier MISSING alert | Spell Known 11426 (rank 1) |
| Ice Lance SHATTER prompt | Spell Known 30455 (learned at 66) |
| Evocation CD, Counterspell CD, Blink CD, Invisibility CD | Spell Known 12051 / 2139 / 1953 / 66 |
| Invisibility prompt | Spell Known 66 |
| Threat bar, Threat Flash, Invisibility prompt | party/raid only (`ingroup`) |
| All six alert prompts | in combat only |
| Everything | class MAGE |

Two IDs are worth calling out because TBC reshuffled them relative to the classic era:
**Cold Snap = 11958** (8 min CD) and **Ice Block = 45438** (5 min CD, Frost talent). All
twenty-six spell IDs in the pack (17 distinct spells — Ice Barrier contributes six ranks and
Frost Nova five) plus the one item ID (**Mana Emerald 22044**) were re-verified on
wowhead.com/tbc before this build. The two item triggers (item cooldown + item count) are the
only triggers in the pack not built by the shared factory; their field names come straight
from the WeakAuras `Cooldown Progress (Item)` and `Item Count` prototypes and take the
numeric item ID, never a name.

## Regenerate

`lua5.1 tbc/mage/generate.lua` from the repository root (run
`tools/tbc-weakaura-creator/scripts/setup.sh` once beforehand to fetch LibDeflate and
LibSerialize). The script is fully deterministic — fixed UID seed 20260816, no time or
environment inputs — so rebuilding produces a byte-identical `all-specs.txt`
(sha256 `1591bb6903427f0c075a40dd988651113acdbdb7ea57d5d4aee5228564761e88`, 7224 chars,
32 auras). It round-trip verifies the encoded string and checks UID continuity against the
committed `all-specs.txt` **before** overwriting it; `changed` must stay 0 so in-game
re-imports offer *Update* instead of duplicating the group. v2 added six auras and changed
none of the 25 v1 UIDs (`stable=25 changed=0`). Future versions must keep the
seed, never reorder existing `W.uid()` calls, and append new auras at the end of the
creation order. One import-time note for users: the Update dialog's *Arrangement* category
is checked by default and will reset any positions dragged in game back to the string's
defaults — uncheck it, or report the coordinates so they can be baked into the script.

## Import string (v2)

```
!WA:2!DV1AWTX11zVgw1sq2juuw0wkw2WkMkIo2YGae8LLscaiOiPjbHwaskzRAGfaxGDfxS7QDxWxP5ftCQ67wwx34PPnj0nUTz6pQzZKXDMmTnSj1TDYm9u(JmBBtM2rTjn9DRY003D65E3DXlcasltn2s)Gl39EV7DV798D(UFNZDb3SDM7Z(Wx9H3kRqU5ZRRQfvvwvFcpE8KWJ)thsRZCQkM6QYYK8rfLKZRtuU8wtjuK47j8ngrq2uCdNRMsqrWTMuI6ebtTdx3L(gvwWqu7O10EFrvvmi6lq8nPKcr7bArvMxlRQEEIEeNXOwhrKLwzfb98(sPQkBkPPV00fkyqm5YQjGdrtNNsQirXUlSEobfIVt6BuDvdZS29LO(Y23YvwxNuusvj1YAe(I6QL1w3UfjLwHSVnKukOQxsWeBH3nSRWEkIJJZZwcLnfv1NwJwTH3S4KvbPIE1fYXkOFEdtbDtVzliPizi6nc(ptVRAQlvSir3i(j1Do9fJysF6cL1fcSj9OHgrwwkVXX60FKY4nLvtwyzI(QSYhpVH3Rzuolzb8nnz5cfKwAJ0rdNmv6KPcZNQsvj0jyv8jteBYjVEzdsSLWXvs7EidVIqjIH31ZtYI9a9LxFSytMy0zMCTYkodlVBKxY4YLvW3MfibeKL1oKa78u21pLAEYV(D4mDflFrI2HsELYObW3OLLL9nNOKjzt7ATNRpWAcks2tM9dpWOBsemijnrdwrtX7goEefvfYw5X3FAlstNt0ni4KAEJvPnLokH(IusqszuiiEdqFqiOFya8)hTXswZGixiHQKIz2OXINkg)jKYR1HdcJNyOwwphX46y9eDfb5zXhf(qF2nkOJtm4GsWuWZ1fuYH23rPfrF4ztgLpwS4RBQMBb72V)ehjqzP8BCQIHUYkMxqlvKH4nYjit8SoAg4zildxGZ4iI20Z60xijBetezvH8E3W(XWgSWWx1)6gikE(5KYBkEK1LWMNKnyFW7aoih8o)M3bmgm8wS2WRAYMR40ouDxtTmrcptQPJqVDr4D9CNeEWxeNE8bVB4r5zWJS2(VyrpcCcVRIaK0uOwgOB4KWP8c9apg8E9w79btRDFZGnXxurbkgNOlzykLZWPlGZ3W9cpo8eWPrecDqKoNlZIh4mplmem8QzfC8LsCx(pDVHOhhyq6XaH8GatdbtkuGiUj7DZgcDroyKH7co(gu3eSdsJ)D1U060KSKzAdrH8QlEbhUG1yLrpO1r3iukh(slYEN7UBToQ5gQ6qFn7sDroWuAhMvc6NRsXT5ygLiHXlVoRc0bJKNv4hBlBR4fDE6BYQ)YLXzOclddVUo10qsHfgj(0XJbhxhbi02SoRHvNDSh2fqExTogvxAfFNVSqEkC0xQuA(R8oL2MxkDDVyPZtYHoyYP10XtmyiJANAChCBXkBrevoNUG2QZ5CYwvE0mcHPNj1KJhpMZCvnG0ngpE8y8P5h)CJLsRNDyiHuQk5zoZ8fKvv1TNywahDzLjzQ(iP8Th1zs01eQ19o052fMnE5szXflGJVgoPA7STL9)Cg2bqyIBjQogiNlZv167uI7yZXTnnbP2a)UxzGJtpzfjsffnpoCUzxJ65KdxBZitwt0ZxXSl(sLXvL8YZk9KznKukktImv4ZfdwTl45Zeb5XZ1fSQ3i0oJEY1yq8i4DNN67gi8iJO1b2XHZtrqK8K8tjSKiCpWtztoeTQZ0r82ylLqp(o0DCqGU8wR)Zf4wJ5nAiLNWZmGqakxCJ8PdUZmSW9J3Ox4OEHJ5Dd2Jym2KYz1P2RY6e(OYebfEbznrbp2dIu21ODQXP8UfeYrUuub0frPyeb9lnZ4pr1REIKmgn2TjcFaKPfzWbprwrvTehCwp8lsD7(QEH3h8(HWBqkUu2jNU)WtAmLUKcLEMi6mQKYNNOWhp2SX43qvxcTqmsY1hBA(XFMPJNk8KWOdFs(CIKCZpk8G7B1fe0LeqeWQskrvlLvWKFbb5YeUtOQDIZEw9CIckfjgh7KWlZujTQgkkHOBUm8cNe(Syp4b(CBvhofE5teYpE3DEg4xMEBtWKx1p9qVEGppKQY9bVc22G11wARgIrrgW(i7oGd796urBfz(xvOWOnEGR6hg)iWeoly8L5Olyapnhmjmfe3z1GVuvwD(eQls0PS4RPrpJ6RYvhH(wumEL6Y001ga(DADaizT0)qQjS56zZH0thkKhygrywhkEyUR2fCbo4Ix3L9Mnc6UB4zzURWLWxNFq45G0FmidhiGDzwihEF5bI9dQaueK40ovRiry9xneuWvGldZdYqjqbub9mApA7Vv7YGfaJJciB1t2(wVDYzKXcwewcwgwHd(G2Vv)qzGpe4h(WEGpcLEb(OzGpgLIa(4Ne(eWZBZGaFswr)WSJxf(rGFug5a8J5Yja)4iha8tGE)Wpjh8tb)07jU5WpZzH1GFw4f8a)CWlc)8v9lVl4trDkHxQId54rEg)90ZqdmXa5GFbr4td)IWVe8zGrpMnwFFiwFD4LD8PSH6mKacUFbeCd)kTao)PVZgHZXRfiUUjlAdQofKowViXebIxJIFRwrgkkDAToCcmjPKzzgJad2URXSdspeS5q2n72(PPLZScEv7X3g8OsJAc2O5WBThPnDsf4428bQfx3KfvR2f15mWq1OBWodtxaHPBqNKrUBAmuoywDNlXZpjCOmr0fKYN5T3a59TnGC0srMBOZpYktp(O1bKFSkK2Rvz(djVhGsEFI33z3jMEEHI4Cd8YEQ1dO1K916p4JofDDNvzPc3OAg0UVOtgEQeOM)jdh9PrbeJNA8zJz7D8776DSvvhbC0Mb(nGxLYtVrg4lFIb9JUfOCXkyb6IAcMQ60xMPHFZM5DCyuKJTue2BO9bCCpyi00LTKKUUQUiZNTdC(UlVRL1vIdAQh1BlSLfGJNfDeq5kSRXQ)ARZurKOSSbzv3ie7Sx2TSndT2HW4wZPtmjP1DdqQoJ)AAdxv)r485NwX4sZreMpmn07lnfjVKWLCuQyCj7qAtZIM90MffyifkFacsqkbkM5hGsm9cuMGvR(adVHWtxirSrvNRWCLyqjkT1hP7S2rciA70aVMl9(V139LATNXlDxh02Qd)2WVZ2wah(vzl9(Rv)I2Wx4gEHAeUTjAsPbKXO6yyXquBk87jYuuyBoHVkFKjJfFKDjR(nSN7Fqd2p4pSjwH7go4zUtBZa8hrN)NZFHXs80HgQ)PMP68)JaFDXD3YQV0(QDkN6g9DCNe1osDlSxXr5mNDZARafY5ACyA0RtoqMwBVATDWttmbv9Kq)g4RbdOttwY0Lnzooznerw45HxpcDDl2mAtMXDUthNTifeqh0xpaEhSMSRM(3FJt)lmv8PUWiLNCKfIwd8Nn9xOY0)6SONyISBZcdV0bU6ddCvsljCNtODmNu54KDViyOw4k5MOIydToDQB8Cyfc6OKF9gBptYRV5KuWOI1U)kTFzFZsKumCQaoa4L6AFpW9cVdCs)EOt6hc6CFudZ9zVoiApqJqTtpv0J8qWdFSo976Sr99Og63tMM4W9K4sP9EGBCheBBWMoVhrkJX65yDOZ8mJv4ncnzPqtifD05dXdr9aJ4fI5HcDoNxQT5QVBMel895DYcyyRCQQY4KGsYfLqn)B6EjnrFIT(fMpy)(dgyx9sFMN96ZtiAHPrdBYtPnfzISqa0it8n2QOS6IJQtUszIsULTLDzN1eAfBI4MZj7K7MmRslILb3eslrKxNE5KS0kEKnON7M3J1k6ElmDC9hYwcNhwJCt6qe6fISMMKLkp2ijLOuU5viggEy1qtyTXHypOi2ju(QhMP87eDB8gm(KA0Mnmy8i2sUQ0BA3W92M2zPjY0Psn9uGX9B3XfyA5AQoUZBVKetSmltZZRG2BxEYp52ylxVAJ2)t66Q2beh9x(wu3MWBmzIexrmxOeJfsLsKrhLFk2u(QUOPmveE9NQDFUfsx7DejdAi4OCrKs5Lopepd1pd1Fz7Jqb(h3MUYXhPHso62kH6j4UofQ)kRbJSaE5odw7QvzGppn1TNU3ttTTuh9Z6Prxd4Vid8x2AFGlZ3BV9fOF(Ed6pyVSJbyhdYhyGEd2hFWG95p0U0dbUwvFIH)gWFLRFa8xdF7mW3b(BGV7rG)wo4VJPCSpBTx408Fph8pic)JEG)jpW)8HG)fX9aaf8VwjIGDgfbxV1ah47T)hF9MHxIpEYIxyKsJD(II1JxG)TQaL)m47FtduCnYsAs2QltjvIGGJquWXzQcoG)JBimXX47nG)(cSNB19uXStZEYBDw9y7kR(2zjUhp0C3TcPNfNtjVXqbBTz)p31ShBV3SBXDh7TM6(g4nPPgnJFBMLSIH2JTxnfdGw3VZwzlBAQQm9ceDzHLFBP12)R1O1wan2lp6ydTCS(6rrzQwBS)M75gBVo2s)rWOUx8eZKaUZvQSd10evJ6czPEUIAWylOMJXe4lHUAjntTUCLxzlP03uJNm54XpxnYhP6qvZnV7n4Q5CCf2wkijlzUCJDgBZUphPKB5pqnD2Kck4XKJfovQy8mXOum4xHHbTLFstpEoY9(Mv)5gyq8LlPKK2z256kRTSbEbzPIOUeDCXs6w(YrvnI6fRQfx3ElDjzyQKJ6bJaErN(bLmt112XM5xwrOKuowQGq1Zrmu1nH(wROUK9ENDWvPNs1VDc(r4LLkjzEq6gsoj9mXRLtvbF8kMJkKddYklF4rgFMKz1fYlv24tCpOU51qJNTCVprxUqi3VfHWYeDtJ1luwwoQKEozCG6Okgdsb1)Eq53eYUrGPnWk8gb658Nk6LV8c9oZPUb4lcfS)BclnWed4e3iDPHmVvjiOA8EGvBcZJXtyX9W2IbgTNIJ33SKloe)cTKOWI7UBHAa3iA3Ifr7ggYs5jzvrkZsSaBd6gjCJShxTJ1yBGpfnULHPUaDlTyXbahpBUYgyhKL1GLzR8sFc2xVK91VEN9cVahBtbzfNPZLZFGoxIBnwcSO96QU9k9zVfEUIHmDRHXQ0oKBDPClghy2jTZTGmS(M1BzQNA7rHj4ApQ75QnjgWFCNNbGAYrb8NKPT5q6QhIhhf5MpcD7W1oeDyuKOq0LYLuuDXPvYSvDxUHb7F8eH8lZ2Cjw4cXfkr2)tEy448SlD(UcoAuhP)uAWI6yyw(of7tvPhTozPvUOIQorfxSdjkiz2sNiiN0T7wRct9wvcDHwoln)0rV97YAotJ5MpJ2HPNtOFqm128w6O9y7OY7GSmZ6Pj(z7PEg0Vih63c04iNO2jQMet61gxInJKoo97MGKorz9IeBpPZFXIsNA6lsMnbPrpjXQEs7Fx5jzX9OWRBX1DR9FS4oPf37boUf3PS46PIxIf3JvRhIf37111WI7XT4EcApzXDAlUNe7llo)zS469gcG)korHb)NW)f8Fd)pW)l8)TfUevorIHnYClBK5usg0TMVDeVmuVfxalUGwC9HdPqwCmMAlUbOXWGVKdAdHT4gYIBySfp1g1K2jlUZ2ak0I79Hn69)McSvFyEVbqBFshrB2qRMd7Am2me1zX9b081CWg(UMEs05rX0gQfo(yp9Cbwz0EdnABGAh42eOwL9vbEfBE0emWecFqBo1EF(m28K191aKrRR6)kwCZFmYhVlGDV6hUPWU1Qi)8MaOZod02rzEtc1HVwBh19inh1X(soTpAd7gmYY8JoFI5hT8qTb2592oy3VB9BH3a0TWd(kBFd7AhG65BkCAZAdAzVhrXeN2xiN9f9niG6vyBwwt2(gBC2R5c1qq2375BcQQNgrvHTFnttJziDTV42ORPIoGQQWqblSC7i1o4TbOlLMiqCGDTaXVeC8isMKs0BMcZqHDpqte2no2KESjjDaIyFTjtMhwdtk2QUNT)zFWQ9)3GoPKW(dUtTSIzgBq760o0xuAj0V1dwv1U512siTv7v5jGpCEwlXzt8XBXXJtyjR(4UH5jd6WtAVLP3SfesHZD3iCE84ZMgf3Kl95iLsN0uvHK2FV2qz)pZsgIdo7iR8mbBdu(EUnHO0jc7vc0BGabgS)qr6VxAg59hiOF(ad4FWbPPQBiAg5doenJ8VAt0bQpwy(PgDMj3PLLx4FV1llZsKZncj6W7iCleJdDipVfhH)UBnECoA7W3tUJRXZ2CxB87ipJIQG(5oLuOrAtsbU332JF9BX9daFg4o)cojcm6inS30ojpKvEc63cdnvGQf8nLKsEN8wYQRYEwR5RAHjlxQKQIV5eWjwFXKju95cY1EBrrwzFjve0QVVCuqwBHvcUU2rkJSLOZID(6vloISKY812U6wl1nbMp(DvtgmT4Ehh4nB6lT4ENUFHEwChIEOZTNOslUd7MJslU7RA2jT4oc05(S46c6ZI7(pOf3dCc(rS4okE2XeT4ExwCpOf3Xz5z0I7HQMGXk)ysCxHZWIZxJjxKBpj3Itn4vgzXzn1004PeF7uUfFUTZtTonI3WYlkSSHlF1t6T56(Qfe2wkR3WFvrVH1hwxYlf3LRHg(gyNOS40OFiko)AYY4SzKdiFXjxqpKzWfBdvtb47lYOAcVxTtfv)UcxxvXfC1W3jiD3PMbBx)Wd(43b85ceo(izzF)6gpw)o7O1cWlJlo5(fz5z77Q1JU7Ys92wXtVcc6GnfbP1rJ8vVjdFyh3lmlU7AVcwCWgGfwCMoWb1ItQrgzHOdoWkTbouCphou7UuUqZGb7EZ5Z1wZP)xRvcyCwH52x2G63PY6m7kRm7GP6P0qN)zc1gZU4nrwGwy2R69BXTOf3s7Po(ThP8bF9M743vZ1DC7lUbNiAfUP3jJjhC5yZotQEBdUr62mCJsBXnN(l1CgMkIr3jKsdD91SZJFL1iBprMf3h8ny)BX9r3biVf3hAhwClGGYY3Gj5VM462BHTODOvWwZbdDb9fsPmt)XBdS9YV1dBhE7W2iu4aEV4v3nTMp(nhzpTi)7wCtCRJoNgt2EniGyblpsEdXGYdfTniG5F7SoNDq26HBH97m3cPt9WT0(LqYmx8CZvoirVn2p5BzTFFXwSFf1MsIBzmKFXNVL2Xl07efNyUEJTSz7c)S0TS2X7BLMAh5z5q6wgdi(w0kdyQleUNq6ZhiL)EAJbu5wwd4Z3cA0PULX41ANVSbMIeFGbtQKA82y7uFRY21zPoZ3z(R(q1)BIcEk4BXYPUM7pCj6pAPV((F79pAj4E3(VuPLKh8YkgpDjPbMOj)sL60Gp4PdDA)DUWD9H()d
```
