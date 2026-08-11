# Warlock — All Specs HUD (v1)

Import `all-specs.txt` whole (copy all → `/wa` → Import → paste). One pack for
Affliction, Demonology, and Destruction: every spec-specific piece loads through
a `spellknown` gate, so the HUD auto-adapts on respec with no user action. All
triggers match by exact spell ID — aura triggers carry every rank, cooldown
triggers use the numeric rank-1 ID — never by name, so the pack is safe on zhCN
and every other client. There is zero custom code, so the import dialog shows no
code-review panel. Four draggable groups sit under the character; drag whole
groups in `/wa` to taste. Note: the `/wa` editor preview force-shows everything
with fake data (all load gates ignored, both curse states and all three specs'
icons at once, placeholder durations, no animations) — judge the HUD in combat,
not in the preview.

## Groups

**Resources** (center, above the DoT row) — three 172×14 bars stacked flush:
health (green, y=-13), mana (blue, y=-27), and threat vs target (y=-41), each
with a percent readout on the right edge. Health and mana are always on but fade
to 50% opacity out of combat; the mana bar tints violet below 30% — the visual
pair of the Life Tap prompt, so the "tap now" decision is readable without
looking away from the crosshair. The threat bar only appears once you are on a
hostile threat table, turns orange at 70% and red the moment you pull aggro, and
a pulsing red overlay flashes across it at 80%+ in a party or raid. Warlock
threat is dangerous in all three specs, which is why the bar sits with the
every-GCD information instead of off to one side.

**DoTs** (center row, five 40×40 icon timers) — your own debuffs on the current
target only, with the time left under each icon: Corruption (x=-88) and your
curse (x=-44) for every spec, Immolate (x=0) for the Demonology/Destruction fire
rotations, Unstable Affliction (x=44) and Siphon Life (x=88) for Affliction. The
curse slot is one icon fed by all sixteen rank IDs of Curse of Agony, Curse of
Doom, Curse of the Elements, and Curse of Shadow — a target can only carry one of
your curses, so whichever one you are assigned lights the same slot. An icon
exists only while the DoT is actually up, so a gap in the row is the "recast it"
signal; Immolate and Unstable Affliction also glow at 2 seconds remaining, which
is the lead time you need to start the hardcast so the refresh lands exactly as
the old tick falls off. Never clip, never let one drop.

**Alerts** (left of the character, growing upward) — glowing 40×40 prompts that
slide in from the bottom and fly off when handled; appearance itself is the
signal. Five prompts: Shadow Trance (purple, the Nightfall proc — cast the free
instant Shadow Bolt, with the 10s window counting down), Backlash (orange, the
Destruction proc — free instant Shadow Bolt/Incinerate, 8s window), Life Tap
(blue: mana below 30% **and** health above 60%, in combat only — the exact window
where tapping is free value), Soulshatter (orange: threat at 70%+ **and**
Soulshatter off cooldown, party/raid only), and Soul Link MISSING (red, combat
only — Soul Link dropped, which almost always means your pet died, so resummon
and recast it). The two threshold prompts require the ability to actually be
ready, so they never nag uselessly.

**Cooldowns** (center, below the DoT row) — a horizontal row of 32×32 icons with
cooldown text and mouseover tooltips; icons desaturate while the spell is down
and the row auto-collapses the gaps left by icons your spec does not load. Amplify
Curse (Affliction), Fel Domination (Demonology), and Conflagrate, Shadowburn and
Shadowfury (Destruction) appear only when the talent is known; Death Coil is
baseline and always shown. There is deliberately no timer text on these icons —
the swipe (plus OmniCC, if you run it) already provides the number.

## Spec gating

| Element | Loads when known |
|---|---|
| Unstable Affliction timer | 30108 (Affliction 41-point signature) |
| Siphon Life timer | 18265 (Affliction talent) |
| Soul Link MISSING alert | 19028 (Demonology talent) |
| Amplify Curse cooldown | 18288 (Affliction talent) |
| Fel Domination cooldown | 18708 (Demonology talent) |
| Conflagrate cooldown | 17962 (Destruction talent) |
| Shadowburn cooldown | 17877 (Destruction talent) |
| Shadowfury cooldown | 30283 (Destruction 41-point) |
| Soulshatter alert | 29858 (trained TBC spell; party/raid only) |

Everything else is baseline warlock and always loads (class-gated to WARLOCK).
The Threat Flash overlay and the Soulshatter prompt additionally require a party
or raid — solo, pulling aggro is the plan. Life Tap and Soul Link MISSING are
combat-gated. The Shadow Trance and Backlash prompts need no gate at all: those
auras can only exist if the talent that grants them is trained.

## Regenerating

```bash
cd tools/tbc-weakaura-creator/scripts && ./setup.sh   # once per machine
lua5.1 tbc/warlock/generate.lua                       # rewrites all-specs.txt
```

The build is fully deterministic (fixed seed `20260813`): re-running produces a
byte-identical string. When editing, never remove or reorder existing `W.uid()`
call sites — append new auras after all existing ones — so re-imports show
"Update" instead of duplicating. The script checks UID continuity against the
previous `all-specs.txt` automatically before overwriting it (expect
`changed=0`). One more re-import caveat: the Update dialog's **Arrangement**
checkbox is checked by default and will reset any positions you dragged in game
back to the string's defaults — uncheck it, or report your coordinates so they
can be baked into the script.

## Import string (v1)

```
!WA:2!DR56ZTX11bCVgwnsWpIi1dBl6h0mMkIk2YaGVavSCkaiifPaFOfGKsYkMyXUxGDjxS7Q7UGuuTUjMXjLnnTPHQ1zAQtJnCB6xABA4hAN2PZKXSz6K262Eg0PD2pK(iSTPUVMMrt)dON7Dx8IeIu(HCJ8hWf7EFT39E(Do3Z5ExHzBx(1EO1E8k5KKxuHAALWu3KoEGabMoqOt1Vv7YMgoutDDIscvnDfkXyCRdoNev3uEXoF6oplrs3rDR6zmHKHuJviJkLi5yD0TNtNJOlzRUvotQcHg3)HBDW46Ax7AsuLoZyAQ7OzrV6u5ZBtCeYzjHpBhRhSAhLjEcSZIPR3zAlISDoVEsLUIxdUszkPGMPrMvSiIfOMLSk7vJ0AxJSVn0mYBslk5G1i4gEf49MliieOIujhvt6uwSITdMdNdYRviivsMNXaI2osuNG5YRzOzRgmo(NtWvDOAfkqO2tECQ)LVsCh2txQevkYMSuBlIUUMI9XApu8syJYzPlTcHUkp)XuSdULDPCKLW3Z0LYNx7QBmFIyPZmF6mXeZuROPPeSiX0tNmvQBuYMK8Q44kTxpKv0qQiXoyzfsoShyV80ZMm10JmtQ1lz4pScUHIM9cLmW3MLirK01TAtIFDgVYNWuH8BFx(txjvkqSAl9vkHt)DosjC6EovnhYMEL6nxFG1Lm08Mmhao6iBsKSjPDqXvbh1pc0rCdtdsff89NvJ5zZjuBcoPQyVkRQSrjejErjnJrGWydGiqVqFq)4)p42ZzDBIE(Pn1mCYLi5Kzsk2LMI1HQtxIeBZsuzI9nWQqOgs6ZIpn85(8BKNIZn44sYrkWnKmKrr8iSSyp)CPtiMm5KLDmLxYR(7F6JePKMYgJoWvCYrhrC2zoNOTSKojqzusiYHl7QSZyg40qGYS3jnpOjUUPKsWn8Em8XleDTqLTrmEX50uCupsznS6P5d2h5UGGWqW9)9VlyeiAfELenD4ZxcwT109mPt8yZKzQ4S2Rcp8lCC4yVcof9yWtaDjYrKCEQLywpo0zWvrizEgULf(yWtchpi8XHta9eSX2btyD4zWQ0zcvjgNtOA2oAY2(Dbm12AlCs4tapfsjSbX8YvnAeao9ZddcrxnNKV(003tOtfUFw6GrzPr6pacN2somCGOUj)DZdJUOae)0hf6ydMQc2bZJ)w7OwT7qUQZ82QskMlFbFRbRZZJLyDWUrCsgFPv5VZD3T1bBOb1vQ3Yl3Q0dCoRdXZb11nzSRmxQepgE7n4fGkzefEMVufpX4f9F6BYlFHs4mu(vGOLPmrdjdMz8jNAYKqhuKqy1PmVI1ND8g25rtQwhCeQ21688LKuy8yNzYyfQ2708E2MMVPxS5viYOsM(8wu8cBoz04ut1bxfEElJy5CujRvNZ)Ik1E0CJctntMuJnzs)5QgO0ngBYjtkoV4yJE2mw9Shdj0SQHcxHwmVUPj1BIzjC0LtNKT(JKzZ9H9NeRkcT6Ep6CVmZnzPI5i0LGowhNu902Q49N)WocIjvZX0xa5FRCDPVFovhB(6TZtqZBWPQENnoodKtLOvq15rHKZUotZrgxOYoBohu13W5OIflHRlfuKN7XZzRzuqNqNlMyQPsCo4ZEu4ZLnoAox(OWNnyCw)XUyloLhh7afM6BKydpS1bX(oMcdIikeLjKUQQNXHe11Louq4Wb3Ef1qD(hG6RI0O6ZfeGqmZVB3e6a3cgv5AX2AkerUGhoc2rbHhmi8qbJFntZIcBWFqNLpZCgktOvIsetOtKmeL0TuLc4nuY4vI1jgJz9nVKm5YjKq9eJcXLOxEMXE66390P5M14ntfEo0ElAkhcahqa(KbexMP49DdcplCg4tTXi9KPWiNBXrUWWjOAgml0ev)HKMIcXqCYKZMuCdtQgkJ4MjlF2Peh7stnzMyPGHp2XfLvjYlocCS9T6ssunjKbwvZiHzXCsoIljPxIi0LPvxN5muzvjJce7JDC415UaTQf6ycH6ScCDOTG3G5Nubo3xZ0cRAdUwiy0JaNTQL8)ybMLCymbyC4CqkFZ0)(1n3koT5YekZ866wSRykrcnzPTcd(Qvw2wA0gMEVmqdNVr7YG44EgHzP9XthQ)aqAviJVXxyM1okmRam3nQAxLpe6UB4ICfj4s47ZZdxg(0Ve8ccW8yFMfKW2LdK9EskabkiyDIBM6nV)AW0bycQGgSaSiOdfbRSwp5U3uV8ah4kpmqfSEMDV270SjAlbkblbldxvawX7T6AzHFk4uWpDa4fzk(Wptw4ZW0CHx64WQWNZtXgEzEwFEE6xa(zH1uHFUguvHViQAc)8Wx6DVMi8la)InQ9bFzb4x6mWxbwhUEa4xg(vGxPUUY94PRaF1A6jHw4QjwqxpCAXzHFvv4Rb)AWRcFDy4tEC4xhH)aW3yZgNCGxVREdHCF7pluMb8C4yW(RJim44narVwVp4BaVg86(kkETGRIGvHPBa)g3mTHx9U3U2WKnYXLD4HeW8)anZslqCqoElg(xVGSmiFcRd6h9qAnNsC9Co1FRH84alklP3wd8B2T3tZs2PgTB9u7aUQvPwqwTw5W6j2LoPgmVdnOg1kAXIL17IMuL46eOs0hAG89TdiFOtCbZHtmKUuc9BcKVETjhKWhKr4D9C(a748aBhGLeUb2gBKOub0Wo86bAKVhNvXH4oXgXlL3OTr7D6b0)Pvb6k1zxCmKf(DHVfZY8Vxw4pOROHqsg9CRM4JT6IKJjLneNa(2TaOVH)6Tm)4y(pyD4ePInX0yiaPIL4COZeJLzSztYgtOeIPWD4G5kQrPMuvUU3dGtTdhC9Cv9)afQTw0Lh6ihsZOZe87XI)oL5RUpDjDBYQvdHR9W8MSt5ktMXKvnkB)kwNUUVaXuuMYW(YZrKwmglE4lpbrrt6Y(EnyFzV4mNNhI5PCkij677mxC5LGcHO9Z0TrSavVziYpbhmUotTEvA1WMqqjZ4N3EMfv0NO3Ly2FSAdJ7vMsCiZxVwVy358CFxfsUeQrSbt0HoOW2XaF1dQ)T41hh(OzJtL0uYEZ1z(Q3Z9U2Jdc12df4UVK1HRhGActkTeFNfUrdzwc9OXQ96zmwXIM64OY6rRN3mg2omhx6mw(86A89IW6i1loTMLQPrNP0YtGpcSF28tq4EH7dzG7tazGpkCW9XyK29mg4Pm3OKQMr5hbE0J1EOQEwWC0GXKDNTfEx80O9KN5aV7Te4jbBy)Jg2mJnt6IuetOYjkuLVusTrkfErLlQbXcaXdcjcGinKmitWU2hJVuZb(s7dUFUFxvKnn1XyImsVSg660MvVLTzgQqQSEVQFtVx1VyKWdgj(arIWt6n(Gd0xuXWHhyWW80iIr6V3WHfJmyKWdqXozkd9vYItoFRwm5qpBmXjgzMunofD6N)glsiwXyrf4iYWov(6s4AqXp9FxLc6MlpcLCLsed5v8wPYlaswbBI04O6(HXMDvww8n0AAm2u9YSBtX3LLJSb76QHaUEHQnHB(AqVf9cWRt1WVIZUrLxZ08D1GpqYOQjVObX2oaVKuA41TXFoX92ET1oeFTYU626DO)G1xnBtVimJpvMmtnbCLh1B9Q881RA5AvN)wBTQhasXGA0jOCtq75c2jgssc1aa4pXBC8L5tdRwLfYwBfM)cRdxntMHOH1SzAzOkoBvNZ7Z2mGTdpBI(S92Y5b3roO6fU8uJAymIgPwuj86bQcTV1D7dTqLSWFZoOZx7GrgkAO4HdfUpepdpiYKdgompncpTxozgnYaH6vS3qdfgRBFdfIvueE1IeHvHiispy0bWMm4q9oipNHGV)ndJH)(Mby4FOrKf(hRIPW)e8dYcBb)ZW)YrG)vb4h(2)VW)Ma82QW)Ea4)ia8F2g8F9(bYa)33o4KjTN5Il3)kMwlp2o5e4)PoG8wWp6diyqyxzHVwKE7lAKbdniIdd1x8id1h3e1a9ZthKNgLzUk0qCOO)BdsyCTyVqh9CG6ohPDMrKZTKrETLgyHDxA)xE7tAFSAoBUf5QwAEEtLrRibE92JWC78z9D7ml8gSDz(uHpfZ2BZmYf3vg50OrGWHIIP9fQpEA)FiupN5Pgpar(jNSOb3EUhj8Y7GhkxVs7V0RUDUiAXfYKmLyYu2xy35I)Qpi4cxH7RfSGRW93md8T3vgybr26bOvHOrhCiwA0q8uUtmd0hFzIWFiLkCfA7MtcUcTV)rV42jahIMXWlNiu)lwA3jG)6B)RdekogQXYDnZ0SOgEWgCUNVh)DMHkzi3uGcSJoLDsQnMhleGoZiz1u0bMyiCQsoyKywD0C2y9nwSZjglD6XMCuEOd40Y9)MC(Ylyb2M0ktU)3RrlSbgnxPIgPzDM32ZKZZlqrjDTcgqukgGd7eifyE4J(2xpikQ3jmsYYJPjwamoVL97hmahwuipWMkRyivutMhRggRtCBtQdez9cunVJX5ExLDjZ)5UehwuxROMZ9YoBSuSRu3s2KfFLHZisYy045eJn8yZKohvsrRK9lFFyuoRlrL9C3gjlFMOXJ6oMoH6yxoFjD9eAuzDs2QrX8DfyXRCa93dbkHCJhKWSyD(fOxmzXOXwzp8BOQ4H51xFHVLcO7DU6E27iw(pVwKZFPLUsb1X1HGUcrUPA5UcpsZQ5SbX3b6NYoQ6Pk5W3vKnS11ui5mDCmlcVzewpWeuTWaWAhCD(PgZWUk2ouj2jOWJ4c6iNCjBSdYXRWkSbckRDfg0lJR6LXB2Ey46c8tIIND22xr5aTFvH15BmdRBxTA3YE4vWRnSzBDaRiR2QwwMQzJJmVTNQAgz59nV3Y(EZn1A4wV9nuVd8(nU555z)97DIYbUdI9SUW0tym8ORCXeNBVyVhTLShYeCSZvik8MUcdDZHnxHt7k8jHoCfEwxHZuhPCfEUgXjxHpvvoYv4N0vigRRCfI7kKa7mxHHXLktUN0WtcNvOLWa7SU(Hv3muRJ005XuD7oB)zHFNU6nemb8BYif(XC20j3Kf(MnFGyWVvdhcw99ATPtnURby94KC2dBb2CwBNkRvBn09EvnR1rB(aNRnYEUDNsp5UsPCzQhPgOfq6UJv5RHvL5h9m)8jZURig7J5H9zengU(L1jRVvRS7TVm)7cAEpVhMpEjQHMrH0yKhAoEOzIurSiY6JeNozlrt16O5J9Hg0Sg7a)HnV38dY2BE4pAN7ep2O1AtenzkVyC2hmIhovGyqOAYPvnxEkJSvA62nS5)jsKuwHFkV8GqMuQiz)oLHoe536)L38Wj83(PoNMAwGsST78eCbxpwTZ3o6cgMuI5sek6)cjBfCPi90v7UnAWZUk1cjIvc)iZyJFp1N19T6lVywRdXUMW(WXAS6VljEUD5EBChbEhq8Vc8N5VV6WFElTOIkeFppV65GpZfECcSg(7kmPv3TM6JrLLmi()fkShWBhn(Kfp7SZLPNX2lG)X)qbW3qCHhtms)rIeTc6iTSkX2duR4bQtOzZ(wwExSO9TaCe(MVO9UthFHQr05z07Z4ratKDhr1nEMMrID3q4OsOnFQ3n2ECXYPM9sf0WGGKv3lUOZ7K4IqUcDaFD4UxW6yvJujXWSGvkAPRLFf)tEQJMkBeIENdBwuZGV)uwputfMW0iVUub2xVx9au5L4nFMdxKPLfKVeDLTvWWeuqG9OMETWoFQ7PH4oDfEId8EnOtxHUQ(Pa4k8KSKU3z4LUchx1pYsxHpE9ykDfobgjPRqpqexHtEVUcFcm0rxHNcV6PvDfoLRWZ4keIhDORq4gcl8qnEGFEg3TDf6D7rek8(saHJr1tn85LMX2wKzhyx8qFT2CfoVRGORqAKEYuMP7htFzPv4FONUcZU)rTyG5CERm5kCbxHlI18svAIxCfU82wCXv4tJv7fU1wd5TvHFaFtIQzKiGNRsm7hOHHTQKRegzLXu4kEONn7PHIy3QB9JvDJem)R8)gZZ6VbXd0R15Nk60lABXSaOVlEPNh(rQClaXUnUvGLnnQIoB7Jsil8gq6629V1L3UcgvLZJD4wkN3QzD)B3cAxbR33KU4BudlbCfFP6afwsoDFZoBpuP9sQw4dcPQRG9TbP5iNSLsZnAWy9DsIs81PfIs9EtgPpdn9(IuyVeLQ35kkt(32srz56RUENKKeFBAHKC2cZTIsSXxE6HhEVKKA35kjx6C7MKK5o0Dsss8TPfsYEgDHET6V3rhqEL9ssUWDUsYJ95BTKSU)R)yIK8wCBjRl)wPVRKkx8H7BmJE2l53I))U8R9ITR0UYApwtFCDJddbagWgBW7)zVX(K3ER9)J3FYBySg74RCZjQs6bMQNqZK(ST4RCRDBXEpv)Nku7lDpV4)3p
```
