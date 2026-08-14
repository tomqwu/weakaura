# Rogue — All Specs HUD (v45)

Import `all-specs.txt` whole. Layout groups (drag each in /wa): Buffs, Alerts, Resources
(pips + health/energy/threat with 35/40 threshold lines), Procs, Cooldowns, PvP.

**v45 — the cooldown row shows what you CANNOT press.** All 16 cooldown icons now appear
*only while their cooldown is running*, carrying the swipe and countdown, and vanish the
moment the ability is back — the pattern v42 introduced for Stealth, applied to the whole
row. Because the row is a dynamic group the gap closes, so **absence is the readout**: an
empty row means everything is up, and two icons means exactly two things are down and both
are counting back. Previously all 16 sat on screen permanently and merely dimmed, so the row
was busiest precisely when you had the fewest options. The desaturate went with the change —
under the new rule every visible icon is on cooldown by definition, so greying them all would
just make the abilities harder to tell apart.

This is safe for the rogue specifically because no rogue cooldown is a press-on-cooldown
rotational button: all 16 are situational, and none carries a ready-glow (a hidden icon could
never fire one). Packs that DO have such buttons — paladin Judgement and Crusader Strike,
druid Mangle, priest Mind Blast — keep those on always-visible so their glow still announces
the moment.

**v44 — the PvP layer (ten new auras, nothing else touched).** A second HUD that exists
only inside an arena or a battleground. **Nothing changes in PvE:** every one of the ten
carries its own Instance Size Type load gate, so in a raid, a dungeon or the open world
the pack is byte-for-byte the v43 HUD — same elements, same positions, same behaviour.
The 46 existing auras keep their UIDs, so re-importing offers **Update**.

Three prompts join the existing alert flow (left of the character):

| Element | The decision it changes |
|---|---|
| `Rogue - CC ON ME` | Which break works *right now*. Colour is the category, `%p` is the countdown: red = stun/charm (physical — Cloak does nothing, trinket or eat it), purple = fear, blue = root, green = disorient, yellow = silence or school lockout, orange = disarm (no rotation exists — reset instead). Catches school lockouts too, which no aura trigger can ever see. |
| `Rogue - KICK NOW` | Target is casting **and** Kick is genuinely usable — cooldown, energy and range folded into one boolean, so it never asks for a Kick you cannot press. It does not exist while Kick is down. Desaturates out of melee range. |
| `Rogue - TARGET IMMUNE` | Do not open, do not dump. Divine Shield, Divine Protection, Blessing of Protection (physical immunity — a rogue does *literally nothing* through it), Ice Block, Bestial Wrath / The Beast Within (uncontrollable, so Blind and Kidney Shot are wasted energy too). |

A new `Rogue - PvP` column (right of the character) holds the state read-outs:

| Element | The decision it changes |
|---|---|
| `Rogue - Trinket DOWN` | Spend or hold. Visible **only while on cooldown** — absence means ready. Tracked by exact item id (both Medallions, both rogue Insignias), never by equipment slot, so a PvE on-use trinket in the other slot can never fake "medallion down". |
| `Rogue - Will of the Forsaken DOWN` | Undead only. On 2.4.3 it does *not* share the medallion cooldown, so it is a real second charge and changes whether the first gets spent. |
| `Rogue - Enemy Trinket` | Their 2-minute countdown, one row per arena opponent — the window the real Blind → Sap → kill chain goes into. Arena only. |
| `Rogue - KICK LOCKOUT` | The 5 seconds your Kick just bought: Cold Blood / Adrenaline Rush now, and stop spending Blind on a healer who cannot cast anyway. |
| `Rogue - My CC OUT` | Your own Blind, Sap or Gouge on each arena opponent, with the remaining time. Do not break it — and this is exactly how long the team has. Arena only. |
| `Rogue - Wound Poison` | Stacks and remaining on your current target. Five stacks is −50% healing and it decays silently between swaps; glows in the last 3 seconds — Shiv it back up or get back on the target. |

**`Rogue - My CC OUT` is not diminishing-returns tracking.** It is the remaining duration of
your own CC and nothing else. TBC WeakAuras has no DR prototype and no bundled DR library,
so DR cannot be expressed without custom code — and a hand-rolled timer models the *reset*
window rather than the category state, which is wrong the moment two spells share a
category. A partial DR tracker is worse than none, because it gets trusted.

Also deliberately absent: Cloak of Shadows and Vanish availability, because the v43
cooldown row already shows both as always-on icons that desaturate with a swipe while
down — the same information twice is how a HUD teaches you to stop reading it. Enemy
cooldowns, enemy spec, and "only show casts I can interrupt" are impossible on 2.5.x;
the reasons are in `../../tools/tbc-weakaura-creator/references/pvp.md`.

**Live acceptance note:** `CC ON ME` uses WeakAuras' source-verified Crowd Controlled
prototype, but addon source cannot prove that the 2.5.x client populates the underlying
loss-of-control API. Get sapped and school-locked in a duel once before relying on it; the
repo suite verifies its schema and gates, not live client events.

**v43 — readable combo pips.** All five pips are now always on screen: unearned ones sit
as dark empty sockets and light up green→orange left to right as you build points, so the
row reads like a filled bar instead of floating dots you have to count. They are also
taller (8px → 14px) to match the resource bars. Previously an unlit pip had no state at
all, so nothing was drawn in its place.

**v42 — re-stealth timer.** `Rogue CD - Stealth` answers one question: *I just broke
stealth, when can I re-stealth?* It is deliberately not a permanent icon — Stealth cannot
be cast in combat and out of combat it is nearly always ready, so a persistent icon would
be a passive readout almost all of the time. It loads only **out of combat** and only
**while the 10s cooldown is running** (`showOnCooldown`), then disappears; the dynamic
group closes the gap, so it costs no space the rest of the time. Absence of the icon means
stealth is available.

`generate.lua` is the historical iteration script (v1→v41 patch lineage). It expects the
original workspace (decoded schema template, prior-version strings for UID continuity checks,
LibDeflate/LibSerialize alongside), so it cannot be re-run here — which is why v42-v45 ship as
`patch-v42.lua` … `patch-v45.lua`, decode → edit → encode steps applied to the prior string. That keeps every
existing uid byte-identical, so re-importing offers **Update**. For new work, build through
`../../tools/tbc-weakaura-creator/` instead — same machinery, cleaned up.

Keybind labels currently baked: Sprint=G, Vanish=Z, Gouge=E, Distract=B5.

## Import string (v45)

```
!WA:2!T33E0XT15DAyk)quk2supITITYy5kBrLiL5jhshz3oZqsXrICgkmdLOOuchmdWmdiNbacadFO0K2W44QM3MPjPUPXjHN902TBpz3LT1BB2KnB02n9020n3WMh4Sjz3uv38QTNCI6PD72MTz)(UxGbygo8POKToX)HGaUaxma3F)((D)(U47Ej3z7WGp0XJCC)DuTdXoeVYbxkVqHjf1v1sOwrv)uT1wBd3M)JhrRJcQkM6QvQijMOSCfrDjLjwIxTunjFhZx8AflACnNJIvrs30qB3ohZlzOwtVGKr9RFyD1cEUGeQQvevNwXyX6xWudFT8Q6Is6XTFC02v8kYx(Yc6I(YcxUPSM(mPHFvjtU8SRSS(SSc(I37c6sLKvvYoRMeFjD1AAlWUKmYxw6UwuqPqzv9HvLvmZNOVuz7JFr2PzVYCCCTTOSsrv9QcMWDP9LeQzcviTgEKr76cfO70fVHPGUz75lkRiBuU94W)z2(CM6YLkjPBCGht3E3NHxrOQKr7XnXNhHA6cbNZqtQsLKIgTFnJA5LMssXmd0gkpZIJNiwMSJNjBm(S1p1W6sWP4ZmCFdo4cIs5HReF10hOVbhU)rgKNEr5hqsOIz541GNI8AveMvsF(Ak2pcTFv2BiRbA7xhE1L0veQCw4bfExUW8ckYS32Uipq)xvsWqkJjaXLmlFpKdgxrvrAjr4bhVIXXxdDdjGqiAmhEP4ddXF8QcYk9tEdqfi(jbibjHG))bBUK5nKQuK24t2ZHKf12hdZZgpbL6uXxgnPcglyQwyk2d39o8(wSOo0ccprcMcTDDg(1pwe(lNptc((6lLngMubEbBlynzXfdzmvxvUuY0DgSZ8WdBr5sTVa0KYt5ggTZBuqOIuBlGVhYmOnEfvbX(JBa0K9ZxTgWYApoGuf2pP325lurWWa3lVjupftCxBEvFILK02DMlvtqxYx)1GxIZvw2uQJcFIOx51sUZ6wrK2gtB)oC8mvKli5tqr0xVWoxVU1snnZA6soTlhZxVscIvM1h0KzOQ4wC)YqnpNKWKksggAD4u8asvv11llusI0ozhKDYrgGKK8QktUpy3oi7HS77ISV2j7LsZj3pzxKJDbYRgq92jpy7Kd0o51CGhJ8qpd5HBhaTxlXx7KhHCiYJs(zihM8yKhNCesNKJsEDTtIa3Rx)2jVX2ihh5mnJ7HxBMaG(KTrEQ2jD3gPhYtKxdA9awrxKtSOMK2ObepJyVHcrIceaYpB7KFU2iXANeVFscSLN0hDB)0TNKUD)TFLhDbzaoZqLBEO7GSZx)2i3h91EPc2AmzMwwtk3vDoerUYn((NcE))nWx(RIMQudvzrJJgpsGObI3v0OHR3kanoqdZ1Rzi13mGOqgMnDoSTdB0WgSxx7lkkBmrnfqZykPGcvQOTBb6(zzwMdPkk97ChaiC9jLK0IHSntE0oRm2cdw7gcMOHh8u(Z(eFTLkvrD6(1LUunjLcZo828F8Grihuhy14jwe3mQTQ4C4bO9Xs5RzAQQKgmNavHfWIhKAzVp61FE7RFE8G6I(TDv4T6KoLuMEYmu7L44ULPpizllxGs)AJE(bLH93n9hiotr(k7rRdtPzmh3OSGO7J280YWnh6WGWUNRWvb(ASsD0kIhBKSP12dTqqowffRkCozrqWlgC41PNaejLePf(2xIjs48YDv65NOMHPCXzHMvDvtOjnluy8uPt1hRjeVMfOxyH6ndSh1IqFFA7QFD5l77m1eerziFzZ2W7MZV0s0YMgE)pNUG2CNZENLQFFOk3Phj7Gjt1N97UNoKUAYuP6JF84PZMn9qUvc746HTFNgTH3PPKnKZxrkxrB9VXrXR2ihCE4fIvIT0V9lfTT1UeN66uvjWyGKCj7JuT7DTSKCPYMNHe)SZdCIXPYG5Sn56)XYBiRuQIepF6tosFKE3p59LZ20KzME)XrlsY7phQ6Wm0JFzv1QOEyi04hnVrLGtzRJGceGoHhDKMk5bBUeEHkALfAJFAe5pdidacitpwHavsg9YfJpTUSc2tcyaLMSnExOLe7apgFHYsfMSFYd12CtjOllaTgxtAgnzwpDzLRkDivTdDINKFkHk1K6iIEHYckLKGo3jpxU50a)saxDMf7v54boos8NZryjN2ED2fPz9kBG3CXCx5rjNbvMQWzRmr4ZrY0cjOxGQ)c6i6WTiTsLzZX0DGEF0ljzIIpNlhj7LJhONWHI3DxH6b2e2pFGabJgIUnmDBe(GD1DxrrrjQkU(aX4hc8Aa1WhLCEYyu1hYfO6nKlsLziVjhPfYBMmohjhrGKFFKcCerwth0ywSnsPYKYTrK3nzcWsNmjhPcyptQY6ArHOs0ixIO)2jgCeOZEsnYuWnCAYmS7XSKltElCKFEYBL82i)cKFrYBNm3dtEhCKNoxrY7eOWKNH8lXUxxjh5xg6f7DXrE3ipK8EC5FK3l591kAh593aNJ8bwgH70BAch5zBJmVnrBsHZZldDaBmXaKFfkfJ8HSPxTt(y5ipFDe)yRxaN8XTHAYNWfLd2DGUXn9aGAOiHOBdZhmsOW9aaCpD1nFWOb62fMj)wRmaFQBea2yZdW7Hm3JWa4Ti6YR(wiDzWTe6sAXSHhAQW9wt9sRbD5DUg0fQlkKSJXhkqWqHPBJq32fDBu62UBYxfKm1G3j)0TeWqBjy6mIj6QZacqSlX3AW0tXhORibcWhiAOWrPB7MkIh2RSqZO5RyVV1YnsTLWnosWtFj5XoLXuvMEL4g(NxqVaZJ8NE)K2US2EQhHOsV(gkzMmjtDs3WdL1unmLQpuk9lbEn6guzFtjGXmJJWsvnWN16dXscFPt5BO(Cl50jtCAFPsFo3ikZgJ)K9L1xYHgAeWLym6r4v4((8Zvsxwe9A9q89Ah34CGpjz0ekaoAUjcDCrWhSAvvSVbavnsEM)UGJCYLui7r3WuaJnIdd7Bvc4ZnWAD24xiLBoWf1bLRkBwgIxmVUGOCnJNENy8VyyW3)vfNvrOQCb6GcbHch3qv3e8G0aFwEvluecDpHSEbWNyWdnm42RboVcpnkM9drTPQNNpwVjhjdYtGyFtdXQ6qxUlGjnp2srJ)yhiPAoAugaAWbeb9oN4uLdpHH2SHId)6tFOrggvc4RGpS7azdazCZgj9v(ziNHZHy1GedqYB05ILGMjWPxJmLvNoTYsg0)BiWdgWnEVDwGEDCuYiKZ66rXQ0FXrxUcd)Wq0yvCvzWthicBlO3KJQ3KRUEZQBtxSUn9c0yquRMxW0XKUbRCx7BVmtOTfAHb7Y0aqzBRJn2fjhmVMUeeNdjKoouwPRzs(wlAar8lLxfcBUk2epNZqFfeRh003crGRSlC)LmbMOrfm2sWGrB3gWXy0tzDkg(9karHc33qK)xZthbkAm6oxing780YNfFmdtEwoY3UJaDmR427ygU5PH6G1yoNAqdkJwHCS6ndREVH7zj8m1FGYrVqA9ZvN1(FXE4xCKRki2ZSDhlBLZiPHYv7Kd5X4iyGdOysWwq7XtIdDyrWC5I4XgxuiVCfzZzhxhvrg3ahulr4FKpwzuCBvjMFkGy(HHqvzWzf1sKhrFCuWRVEH35iKhFHe0Z4Bq4upkFMZbcHZjkzyoIISj5O4qumEvG6ITh5Oh5CYCZ5uo)WX45ppWCz)wKFeyeCD2DN83tj2)daH)Fmh5)toY)e5)l7cVYU5H2TctghhQbTDJ35ssks6YfyMn5wQHdxKzfXljiolyUmpDmJsjuv6EJ(VJCqE6HuTWhx7bDgRBuHUeW8m8De64g1P2EWFgjCGKgV(ni3saRSsgNd1Du)PyE9lcSx16alcupv1LuHWDbHiOC81dSNN3MiuyYCUMXVOwhmMO9arbTXYf0oEr6qvPQCeZo9PlzwtxX3rmVqG3KpvDFMxi4BQt6iwAEHqVjFskIRtxh)gnkd0DqKIgOfQa3k9HCkqt5A1BiNubdA3UJLLRRSG7fHG6gwLH8TqdEy7)BQKX3M8xUQ6iKRr(RGt9I0k9xt(oKVBlediFpY3N8dYr(BCm4j)T5i)DUg3FUMmURgBOtEQrosGbsnJRXn5hQ15kzspTaWJu1hVqzHkvWX9W2JLv1O(nd2pFb4zVtAVnuMxzGeBQvaeSFCTDLLEKVmYM1OAQGbZ1CVkQX781RXHI6NsURxW44iUia9eFON6jr69cUvdClMrUPgWK)zY)c5hNJ8)J8VI9G9tEXltoOf3DWmdT44S4UZCwCTXt9FYI7UqJilU7UUnJf39KBd3NxZe9WrwjI(AtnT4AFLPJwC7aEHUTGf(FTjw4PlpYmrpLYr61ySgyHp6Q3XsreN248pGTuqsXSm9BJDOi(R7IdcZ(AhDxCC8lMHbsXe6BOg502FdhxN(1XjwnY29U3pwlzB62UNFtGVrXzCt022W0TNXHU1NhNRBWRQVjY4W3QBlOCF(MOCt4VOCfJOJ2TWSnq5wMVmurE7b03()anqrBFzybXJVITik(dqBlO(A)yOmxcWhFrFjQ)rZPmYn04T8nwfFNzqBXBs9Ac0cGU0ivbjpoEItTAWVZq5vpo7hJh)IEc5cQnLwokPbafGRyZqqq45Z1erb5aaGI8eKZytuSl1HOaubkjXMaSCUcWIC4kyvT5llJOCvKl4jAD(sdp1WfkabejHefGfbkkX(F(yKpm(jciFKfTtccA0WQAh6jFsYZfpt2rsr(1WViqZa1h96UFya6x2Q(nYI7rDQ)sy9hFO(smqSujtSc3ilUd3Q6YNahm)nwD0hon4GDMmBSAfV)(IXBxfQkdfcBBLRWsyfA(1ADvt9ePt1)iz6ZtDcJpE9q7mD1Eg5tNoRNAvxoCf)LYKCW(sLOpVnfDt)vcUYvk)WXsKS)ZVHQZsS6Sz(502vMedKo9GJNetuf(rgo7g7PT3KzAIIeMc2(TBirTnwxPSUv3j3QOUPaQB9thasun7XJNqWa8D6bYX6h8f80N3sXOrr4Be6N9I19hTppYpruH2VxddRG9iu0j1FXYqio0U(Zzh00Er378LOSaM6nqyxWPly4zCqNVEn0z7jb3D6Z1gEqUBosfN23BwAUp46rZL1)8RTShxcxUIl0bTOct21IZhC9pIxj3yhGXoUlYh5QSCpsHh9O3HNWXyi5iFuYfPcZVeOkB3Ta2bRJa9)nudUzb6jLlmzk6WPcQZ2Ub(d1EOM7mpMT)JNgU8nqp4Vz7bkG9P48my7aHn7VDWUchmEa)b9hmCpDhpsKOHWJcc71tp8WEr7MpCKWH6MpqprIgMpu4WrdGJLwJ0ClUW5C8nmINFdlUUS4IUvrEFzKhdi7Dn8vOfK2x24NWFuR8tqUA1AkE9tODpAPnM1xt4oi74iAP6JMRh(c06Id26Id16Id36IJC16jNPGUrZ5c2LEzyQGD3UPcgDK1pXIroBp65pV)abfJSHYcmF4tenLGQPlHzFdMKvA7nXGXgA4SPJpySeNowV9MmBYZ2xdFUOvA4KZZsxieCPwuH8STlw3eKDwzB5RkRRRQdnVBNC)62)8K5Jnp0dOIi(mWhhCaOx27YjwmXGMdE5O93xNjQPTBrzJc6sMsJ7(rdwMS0l4ewl5X5hwDAjD6G7PH7H5K52DvQq9dAFP1pPhjOpS7THj)C0gRyZcpGCdqmE2Bi01IRFkLZgF)QCayBXDgTyUQ2XeftdY2ykngdt8UloKKOSWfZYAhnUil9khNMzLJZsWSJBwsaTiF3pmj2rR7(dp9LM8CDea7D7PEspUegSnMMj47d5dvVhX5Kvyd0Ct9gYSE)OKNfntstUBgXYIBilUuRlIJfx6vN0CI70IBygHbAnaUIfhVfxghgIyQuXmLh4SrZoHf3iRoJWI7SSXr4CnXdS4g9LCW)KTc8T4o)YbplUXaKlyJih0AfjIDmaobQ4b)S4UWTCKJBvbUbuZCPQjh1FeLlF7nWnWge4cTmtUEC9JoWl9W2jxvyR6yJv2qV8zhAYPV9g2sUbHTWnaBurYUyHj29l9y27DvXm1bhEMsZA4pPFXBVXStTbXSilhZ8eA)gdZq3vbVaz(f3276AUZMaCuVRFyFks6LMT(HSpLJ2EB8yF9xrWOS7S7PVPKn8H5gE9Cyjtg6XUoUw)sGnMEY)Lm1lSzhyBCUmqFFACt33Wo0UJBqhAT4oDdE0E3azvjHrEXH57UZ(NDd5rR)fm0e0NKMBj77Q09zzb(OSrS5BEh0j5a9e8ooqQT7gogDafcY79x2ngxBsEJPiydC8nU1aDgy4jd6Pj4dzpZLxWE(v5gAA0UD8g7IL9(sDEoi(29to4I4eWaQ34W)UY(PrSQTRd3WhK5WhEJeaRM)6Z8GXzZVRg)CpJlkvqUQqLX10HDmOEH7nM3fzzNpFYtoqwToxJ7LUAnfr6KLIVyfvvDiqz249OD41OMScZNQw18s6tbrw7Ks(SjaqqO5yf(yop86sX9A0264orLeecgsBxq0cXeXziHKOK4qcZuEtZ9VoofclrF9RpFoOdflyo08VJSsziwjBCMKgTz2F7ZtPqgYqat0MAYhGJX)DNEklspEa6ut4jbDs(evKeuaJngpYoObTJ4gEbowLYkLGOHV4ijpM7rhld1iHwTYuJs77TSOOKcFQ(oBF8ulym())O2Pg25WO3Q2tf5OJ2tQPPJbWzEO7yrvDzaePgBlmqA(KJLov2yd6DS3wdPyp9DDf)wCY7ZIBcoAw49zOcEwCtc(Dwby6RVE5UN6JR0dKJATEd0lNfxvV2ZwCkojZbhA)AXPAB1AXPTfm8swCg1hDu0eWIBglUzVHO9wCGZ4VflUF(YGiOf3B1LxI8olU3wz0dJFbaBl6)St0)yPM(mHNgbwlo4X5TBX9oT4EglU5OpWwCVJNK2)8tJk8Faaw(LyShlURyX9l3mJra7kG(ThT4E3wCVNnaPytNuGUmiSlIF97Srge2pqQMPb3pf73vU68M9upRkwfEatfN2Rl7J7Sm(at8(QhUEECux3w71VmXq3K9OfYXTKiP9iRYnHvGf30RfDBv0NDVBUQ6wC126jMBwWUb6m65Odz2wsLrHP80wWFDO2Rkfopyymw8EZm4z7UNHcKXw0ZHo7170DB7z6ZHPVJJ7PWtwxobbcKg3rRrOe0xHJbqBnh5yGGSTSA1SizdXAGznZI00GtHMFVR83kr3(kWXDMSRCX1fKfBmAe6ZBa2MgJ4hSJyXHSTDqde5T4eiY0zf6QRoNr58do8YdejL3SsXI7(Y51AdBX62pnHq6WoVMALLxZXz0CMPFw7bh3p5BTanpphUwfdjNXeFzPPoful0YrL7j2CJkx9HJ7W25Zms(2SXd2WNWGncqKD(7ydcq3Hmq4UAmyWZmYzMkEIzgm2Sr3abdUv2n5wuWGIToyWNJ28(iBGEpUrGa7HbGkP7Gap0AGaduRWGHo5iJYhEWBVraPxoGan9D8wo)F7n26pQWOsrpLq0O8NP1T(FhN2YRrhKCVPt581)Eb58anJDOqr8aqB9JxINCelVrzqzEswIIfN(Tnz5kwZawrxLU4ffezACF7GqnGlLIEfxn07WVey)0wlmDAc8gsOyHz5tCUH6rAnaplUpgaywCpFJivy)3QqklUpoRn3I7tS2yKf3N05QxWbGkTLcq(jFwCUtDa3XIc6WsJnpOkyuFUmfG8F3Dsmr(cBQzVe5pM56B8b7R)SK)e4L4pD9ppLi)z5iFrCQjr(Z9mRKi)pWrY6lbnvKTt(Y5i78BHd90sK)IwmpJUhSn7RSdNMTtSO0qzhX4mzhTWehH81rF8W2vRB4zuK9mwCnNL6lGZ9HevuvKmYXM9IpbFq)(9hLpy3(7jeF4G9eTRTWzH6QKGo3uMkbp4AovcITvnLdT4(3qXRVanjfq7SFqomjf(EwC)Q1v4I4KqdboovD87Y27VlxRYP2VanDADsxINLM4SDmZpcVfDmlh9(1TB2oG(6hJLGdctvkAzPt17erQWM2I3ZYM2IVbKT9EiT9j2L2bygDj6fxbFWvgkHk4W2YxZOS2R2Z5Ixb0Q91FLA66Z6m4V0tKqTIiCwvvXgkodndCnmL0CMGJ0IhwxstGnHS0EGglVk4CkBayCwrCONXoTRDgtAAzNvax1M0EnEFmQOkmPp1Io)Wx3Z5WSiQH6NrthN5L7YtrNuTwjPgkjo0qi2qjS5R5E8usVY4u5QGzdpXzmPdfOZWEFFV(TrTcbXbqIOHogw)QwOKdi(ylzTo1R28HKIQCOL8Yv5aRCqGcv1qvBuN7elwUt1U7Cy5jLkLhL8O60oAE3Rhnpq0gSya5X9xpZvykDFvombgbnRvBAq6jv9VgBsB5mFSy5TFKxOL5T)1BIvV(YFFCQkAVwLLBTsK)1A6yV66pRN5lc(U5Qezl(uVhIn3SConanpFJ9kuxl7t5Ke(2skPNzYeDLy0IJ5FcpjHpto5yxyJHDwCFogE1vKwIxx1RsZ6dSS4(8VCaKGxOBLG0)(MaPZvT0Kr0dCKt2DpBDGuuHwcsl4Q6FBfebVo3kHO)dnbrNnspZwOCIjKlEYToi699N2AiYTh4BRGi415wje9FSjiYmz8ZAoWPK5nRTfAfj3siArpEdD7LzK8TumAXMWOr7tTGPYP0QySf2Du0sTeJwQbptV9cLkDlfL(DBcLK5RCj5PUSAGmNBRdLwHjNPf3R5LlqZ6nEYB(aYVxtaYLsinANvtymG6whGSnZwIh5zrOT5WKBGfWQogBtpGblXYpKSPhMo4qZTVTYbp4Mpy)73S3G6s94V2eL7v)8BDwFZ(p1s0wBxnh99Rym2m(8cnHpdNm6rIoXyPJijTLHpIkTeEIJJ)XRGinJi)NAcr6jO4KMtZpq5eBDwmMF6wlpYgaQB9YJN8giNE(s32Pj(h0Sn3P6Es9SbNWm1KBDDaQ261Me64jERhG77NQa4)WMa4I8LsNPWPNjZKZULbWV4CTgGPdp8ROQ2mK8PBowTQNR3Hhqm1Gz36S5wH1dilU9(k4rZ4X)5MWJKHJFPrg80tDUHZVLHhFLjBjEmNZxh5wUm4HIh5NQ0b)mnbYb1ZgoyXtl070vxzqgVHRheg)iu)KNU1DZPB)TUAgHXmsyJA2bG5Yaya0baUmfJTn7q4aaGgreaMqePyZP3X3S8kTctESlGngB6Vpg2EcnR2qR3pQxDq5ZcargZqcdAwoHy4G2FIwBtlwgfVFkQX(gypF5R4N81J3B6ZLcN05UtmhmTAKm9HNq7rQNIeYvQGXBzwwYx)Q6gctkPWUK95zc)uDwNQ7E)ORDSdMoXPtpsw3j6ZqZsxMzHICZcdmBzT)txc7Bz(07KCFF(wNggEsvsVladh17cWWb6WV7YPq90gWoLmccbE7nJmAoZlSN4(0u)mm(5jjVQM(6Kw7G(bkFkCs3S5T0WVO5xoxZzUX2BmZnEJTr)6N4hLfnFya4xSC91OITVkRrfVnwE0fx2uQkTv6hJlTEpqlwBjtcxrNylhRnCoSg0vMYp43JAzsx1mDkSXLPclUVF97Tf3pW9MyX93CVFWVpT6wC)TBGkL8F7MPsFYMRez0GckZ2C(IKRbXaWwNz33SwpQsGseU9bVIRDfX2Qw7kk7Hk5zfQOfRzflRK6kb)LolbfX8SeuyIgMbACjOWzjrzDrKAHunAP9tU3d(Z1Sw9DthLM92krJ6k33jnVEw7vZUBky16DvYbF3UvHAxRvO20QMfdh(ge1q)pECD7)mIDa(Wbd2tqCHLX3I1xstX)ue9TdgiOFCjuIUgY6dN2t(YuRqbjC2xzV0nT2R3G3sTM2pIl3eXK)QwHjsutPvatCNinU4sRNin)ilUF0yXdeTRUWnrXnDJB6Hpu3WUKhzbpRJxEweIT4(7TxlAP)PRIUkOUG7(Su4zTMiwoPc3n7jJ17IZEoV0AG(b38lyvUteMMMplB6(IDNimESGyZVf7PedAUztcQOwysvtpZmgGZ10uJHYGErKzsNzm3RNzutJtVlA354FrYwN2ZFnlUFt7eO83oEq)9eg)tnMFyVO0)K(0dYLIISQOrJ3DxbX)mWeS7i0TDrjxHVgUmAlRinSKoL)G)zKHkiOXkaNQNZjuSOubtjrSd2hMUkVJ69R5Fbjw9mX0L9fHT4JYIM6w(sLwYTcjMCBbsm)1osmj9iXuD2ejun9iXCG6ZbkYVk7pZu4kFI7cX2V(MOBHFdV)reQXfVmCf9Fm(aHcgOBCBWG0THOBdt)RhupB8)mI0u64gkcB7QXcEz5FqrUX5uRVfWSBmE13Pv8QPXyScSw8QqTKx1XuB7T())d
```
