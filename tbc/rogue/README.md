# Rogue — All Specs HUD (v46)

Import `all-specs.txt` whole. Layout groups (drag each in /wa): Buffs, Alerts, Resources
(pips + health/energy/threat with 35/40 threshold lines), Procs, Cooldowns, PvP.

**v46 — earned combo points pop into place.** The five dark sockets stay visible exactly
as before, but each earned pip is now a separate lit overlay that appears at 1.85× scale,
flashes brighter, and settles over 0.3 seconds when that point is gained. Two-point gains
pop both new pips together. Spending points removes only the lit overlays, immediately
revealing the same dark sockets underneath. The five existing combo-point UIDs stay with
the lit overlays; five new, append-only UIDs provide the backgrounds, so Update continuity
is preserved.

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

`generate.lua` is now a reproducible lineage build: it starts from the committed v41 snapshot
embedded in the script, then replays `patch-v42.lua` through `patch-v46.lua` in order. Every
step decodes, edits and re-encodes through the shared toolkit, and the final build asserts
historical UID continuity before writing. Re-importing therefore offers **Update**.

**Known exception — the threat bar loads in arena.** Every other pack gates its threat bar
and flash to "everywhere except arena", because an arena has no threat table. The rogue pair
does not carry that gate yet. It is largely self-hiding (the trigger produces no state
without a hostile target you are on the threat table of), so in practice it stays blank
rather than lying — but it is an inconsistency, and the gate is a one-line addition whenever
the pack next moves.

Keybind labels currently baked: Sprint=G, Vanish=Z, Gouge=E, Distract=B5.

## Import string (v46)

```
!WA:2!T33E0XX159Prlvf5sBlsirAtAlPvqMmeQu07tSamuQE3fliwqGDbNDbijKKXm7oZUZaS7odNzw8G12PgwsMwY2rbMvn5CsphBCACoU2T)bonQToVSzCuCD8X5gCAvNJRvBdRF7KJRzstJBAoTFF3zMD2x4jjGfJ0FGb7mZ9E3zU)(997E)(UpwMj6QWN5mx9HxnpFHze0uutOuwrBypE8mMh)NkIAxfuQAOPuUSOqcj5YcAIvNu9WSkLQj67X9LTSCbrF8vf8na8HB6Cz2AQg10evpKZfgqKxO8c(gtrwxPQ7LhugY5fe5NPQOUUAxoxEiXkkAAs8LeVrEfnbrT42pBQhiEz5RCfEnbF5uukBiRQnFMIf1fnywLVMHKIwgvdzLQ6EZBLrPLT(FsHsIQhm7LRXRj6BWALl77csYgIlRjwcsEUfufzlPPut1o5zLVI49eVScVWG5n4llw14WSvQbFFEJRRkw4WKhWlBHY8664NIRdPg)Wkwz2QcKHHXJ2cwpCVngw9cqX4rJVa9XRxwDdEndVXLRkB4nFr4F6sEx0qtUujrn9JECn7p(8XRbPiVAz(fGAbd85KVMgFWfHhJYLtjO79g61Ylol8eMTwXIYZVYujILn3uzZfJnx9BnMMiCl2SJLCKrwwqmpKs8vwBOKJm2GJpclnr5hsKVSHeBv(kI6ExQwv7hbVlXxvUcp(C3l59mi5rJxvPQ41f51fZAaSHsgs37QcWdfMIPWhrnDrG0iOViMg8lIeiEfE5QqEjbibVxsisyse4JpuRx5MYvne1QYxEcOqGI7Pw2qPWSwFEVJDOL0flxe4qWdBIKPZLKTBzHvDinXH3k9G1Kfwrvu9IbeoVWaHcTsrn41bEo5n49Ct(QfakYG4LWhR8ztWMmz68QaPOQHdRmx8eqPfdOizbOw3gutvfWrp5H3RIYL8UmuZYsPo6EVUvcSq69Tm(MlBXbxrUArfnRQoVRy9LtF6jN(Qp6YYqkZQutRG475Ui73l5imKuKtVAbGxlOmx1SZjRkYDDNtrcSuCmpCKho9Xj((Cqv379M10ftopqQYArh4iNK84KhH0n5yEjNG0d54KFbYP8EDKZqzmYc6pw8ibIgiEVrJgM8yK)HK3N3veK1NUwvGAoRyq(YLvpip9Z5SiaJQii(fVls0N6MZikQgdnamyXxkjs)Ktd8jDEde(fLijp9RTAPYkZnOM4LRjwTWcJTh)NkyeYJQbvy4nUo8aFw4)uBePfXlHiXQ5RzyOunda1atFz8YJqzwhAf8ZxY2gFPsozf1N8qV3fB8EzPwz0hHCsYfOYkEIJNkrV)iYWvoiT8JBPpC17xTldX5nMsxIxOHsJEn8q3hduDAifUw33W6QouY4Xgpxg17NErqlsbX9cxqwWqkEm40BsVbygkkqV4hzvlcHZ721P3F6A6gYfxaQw1umGQ0CWfJNot6KwvHyAwMMWc1RfSEulcQ0Qhyqn5R47814fq(UVC5A6DZ5BAv61MdE)VGgV6IxW(dRwVCOAdzgp3iPsN0(DVbY71tLoDs2PINjxUmJ6MjuY8bTFNUytVtZkRlNVSixrYJUe8oyzUSQ1)MsXoL2NwWT21(ko522oCkrWqG8oCodLE9KxsuUKKX5jDnXsa)AkQYmh5(rnzYHOhp8XZRlxTuzrw2mND8KKh4WKRYrEN07DFKrvFah7mScFazDE4RuGBrNRYXYxwvI3dRB1E8ROOubBImejg5xK0hipbQrepe)uvsqtdL2Cu66TTR8qTDLN0d5Fe59t8EY9qgWRMCvu3dSPoZkZnzHaLtf9kfJph7Ci358KZE0JZwqsSWmds85zXz51KXN4BioVQSLqCo5kISZYxUMyxr6wrT7Z8eAfK4RwseACHCnUfvHwtf1mwavYovGtHweKH8sE3WdVxYd6L8qEV6JsgUrLjY54iJirg1w)5vq9hsAonO6jt1Ylyl9anxQvs0a1FqThud6uEjzUs8a9hou8(6nu)WHW(zdeiy0q0JHPhJWgS3(6nk5X0gkg7OqJsGUeHLKLKJk9qgNk2qMGQXqUGJUc5IKljrMK8uKN(qKNHH8bOydzkgcNhcVhsEjsHdseaZCIidPiymtkrPxejImzAYmKYFesfgsvOSviQqbEzIf(s0jgKAmKzjZrMNSa5kK)XKp4ds(qmKpmYKj)sK)jmKpIvzTih5JsEhKN1d55qsi55BL8r(yKR2kNJ8X5iVah5f9q(ewFHFY2zt75wNnvMbytKpfYJMH)sSYq)S0NEiYlbCiVBpeN8R60mZVw7WCW(c0hEOFavdfje9yy2GrcfUFaH7V3(ydgnqFaot(SRncp8TccRV9r4tt(GpIfcFBIV8o3L5l3ZToF5XRtxYiKl8OZgEGAkxE7qx(Co0Lo2LesMjzdfiyOW0JrOh7LEmk9yF29n5T0a(hCRJPpxDmDEHe92taEO3TXVnGP)ATIPdZgO3ibcWgiAOWrPh7JQRh(TS33r4g37TtUXjcEUllp5W6ZwEUoZn8VeVwbR(L)ShMC3xr9(RhgGQd4B0uzZMk9zDJbGSQIUHyD)Zgue68OBKdsolp6vNVX0uQOcDD156js4ltAFJM09kNlvIZ5lDMl4g2aW52ZMmNVuJo64qpJ3lzFqZC7JCKVYIL0KfWEV2n7alxe8YpHSwbOVJS6Q8feF7n(YqEyOFq(EEQWeYPBOHmu4b53aHg8nc6XxTkvZIfGhG2Ui0bZrKRidokZxwUeWl0ax5r3Kyij9s6AWMrw6rliLPEmv0SCOwKZg9AXR4E3y)Kjh1ZIqhVSFQEBsK3oqVUVRlSa48UCbAKmih8EIRROzaj(DrzHSLXh79Jw1XHumx3Jp2na3jHN(Qgdco8POLNn2aPgplqf06z6HLcpTU6cHidUVfP(IaGfJdX7goirSYqNi1xcR3PE1SFhEvmsCscpi3A)EZRXlixt)zFB2CQ(ZB58WvFVKHzGu(NS(93yvOUc6RREwjL5YuDvD6)gf6id0H(gBCPXoI8yKXiNF9Bc5XAr0HJmj7yG7zLDfEWBhiI1XgLG4SKGwFZ8I1nZxM6uIsL88gCBSjVe6oogWNua6O(lKcJisraNFA8C9NMpVCzzJfMsdrGP0X4Vja)zzmZ4is0it3rS4FlaSfe6FH(ILR85fvrLfWm3wCXsea09b8ZcLqUj8gMxvte8qJerdJMtMAgin8BTc8fliMxb8AVYIob)ji(nJm0oO)C1dKNgcSfWNVWRAa2a6LrhCbRv1dQdNJUWLZ5Ylrtmn0ao3J6Bpuy)xGNPcGBYkvOL(lYyvWZtl4UwqyFDnpd1nq6L5wI65gwsl6usKxVl0yAvmr1Fq4O5HMyU1Hy(VgiMVm4iRfCwwPe54AtHsFjhak2iKtUCc6D8ncCRtWM9cGK4IcI6gJxv2G0ng)JPQaCx8bIJEMZn5w056SJfJL9saZ167I8JbQ9FUvPt(lOu8FcW4)FYr(PCKBs(lTs4vpil8UuyM4yShupiwYLeRkQjxWYUHB1MoDflZiwrEHfWICjA4HsZxrCVr)cKhLLEk1K6KQhjHTBWOyDjGoO77e0ao1J69JFpIyeOMQEbWTkqvkN15unNgcOys9eHwSO9jA8EkVlzJffMHtTl8ZG0QIMOc4dmiTaPMAg)Du7Yc5TJmfuhlxq9ufPXUsP6jm6XNMOrnTQ(oHXtf4z8PO5Z4Pc(m9qdqTXtf6z8jwvyt0BsqkG8FQzzG(cI8RaDqfy3SBLZcAk3OE94mvXqty3GttkkurMLDteIPT2XI)ZQ9SwAlZXd16kAtvqIVCzmObBc1L)DG6sLyJE2Hh)ebgk98Bs1fY3IArJskKVn51j)xxB9dY)nQfo5)o5pJCdY)dlLaY3XweG8DB0(N894iFFYpW2qN8d5i)O1ZO(da2pVkuypcs4TKfKaoSHAbqW(KQhih9mFzLnQrf6ac7nCtf14DP65O7O(bUTAx1VWuyKw4H2x7(jFc0uBz3Sb9G2QnkQbm5VI8)I8xZr(Ft(BOw5)SVZvGhQ)pwwHK)wY)xoYFhlTBuK)FTy)yYCxCMmmCBPM7ALJhoYAXX3ywPjZEwBMOjZ9aVkTtaF01VXTI0x1nM69VhOENtA85JoC1tmG(K3bt9aIsbXQgs0rIP7i(R39gKoCmVyNpNchqioaYT04BkhCQhUPZRZ866mRlpBVpW)82iAA2Dq)2ovJIJ4HOE2YmTN3HP1ehZI29AUKn89PLovbST26kfvF0o442)du(e2emUVeW4M2Fr5Y6rVyF8l8gqgNLF8WBrtmoR3LhI(6q7J9Xr5TeG3ac(suFCEP0X2q3MFjW3a8HbFlGVu4LapZ2lfNxcRht6lG97JZ7b(S(I4tUZ7a(cGLa(c78sSzBBUPUOdejlg1osJZape5Nntob2Qth(PwO4GsiTMIHuM5XdQoRkhloWJ8CuwQn5byQazcugaw7aUeUFBh24tszAOuYzwHT0yZowHcGZqIiJdPTaR7SFRJt(vWHfGS0k2JDpDmyVw8S5gpnowapXtq(NIJcqR1EV8nDhma6WCvVGmzEqY1wfZ)uJMmXqXsNkX6wqMmpCZ5Lnbgw)TwE0gld0T6Sz3A5k(GjJX2uwOAn0AppDkdRIzOZVwBqo1sKj9GJNnzB5jm(41pT10o)mYMjtU2YvDrXo8nLn1ijtNiz7vf9r)wc2PmLFSyjsn4L2s5zvR8SD(6upq2edLjZitLchzE2Xhl3w7PDGuz7ifjmfS9BxrsJFa50RrlQnPVvf03g0KPloQE2jJNGx3Gg0sAZGVIBlERgJ6(GVXPd7h26NBBEwbuG2E3ptOQBwFeA3eLahBO9yHZ2vPha7vNVes84m9a82cUDb9gIuk9XbC3PEg1S(KyNJvXBC1CRJK7usUhzZi560FatMJiTMHuf6qaGCuvxtMJcN(U5AQFbVNw7xqm7EHEo5cZ4OldkY2kWG8SJQ8VJJi8mqktpx9yQY42hGxIowTuM(9qw66wtBNQSuNQUgtJSDoYltMWHEVjA((dyhDG3ljZ)YG9goy8a(d6py4(7lEKirdHNfe(u)9ZcFkAFSHJeouFSb6ps0WSHchoAGgJFFAoNq4xVBIusUjZPSz2MmVV2PXMm(nzcCNg19nqDxObE7A1rHMOSRFNe(DxZojixPsTQn1jbVomThUHattU7VKBa6X4yP4lRsHzen8fWn47wxNovqGl35KhSZjp4AK8qDo5HwJKhUZjp8AK8iDo5rUE9zogVMU1OiWG1noHtNCaYbVN1lI(wXvNCKltoQNTZylS9d)pyIHGocGaWREW6J5IOoDgLPdaFKj6xl)L8hiOqK2dkFsVKb3Nnla0xUQpSOOtrPAAI4SbcN0xQpqIrIn6y5YeFKyjoxSbgivUutKCtnaw5TM(ssaJLASfQHJ9A1(bXB59KVISMMIMe5i7JCFA2F9GD8sq7WvfWNb24qprgy7pmxObqcvKj43Fa1dkiRxqt0qCk3H0ObGZK58QXCBniMGqgO5aC(PgdNaDp9OIcY8pDoRht9N2A6KofDMKoL18j7ugL4jVumeGCBNWK59tfXTrHVjT5bQ(9R445p5KSJPmNOgYzwsf)eork3NJ(mk12fhTlh1VjNRw9l7wmw60D3CgBvHoMjZ5ip3d2yltlkx1kW12njDngRwLS0fEzYlImL97fikyMnzg1KjnEPgkctMjBPjn3m)jg2Q7cwsZEqS3KzmlChQ1Hs2KHniqXGtmzMaRG(MmT3E33Z5f9g0QHgJS2s1RC4WAHlG1cS0Z7kGjZfBPQ0K5sBM6p725AT(drraHFYgq4yuegJdau)modW7smIXixj6Gj7jrnk99vPTKHTOrDIhRjcfH89xMoKdJvRSUODlF7jaAD8DT)p4CpqPX2nHw42mAdqRGp3dAYKrQjd11O5fR2aOw)2y6MX6Mw6RNL9zU7Mq3jKa01Kj7ThZ4G0k4MnBrot7MDX3yZoBMY2MHS5TWaZJDmBlOApseBNoT7BtRya1cZK5P2KgyMmpnyuzY8mCnuh9b6k4UGPuI2mLesNoMH8qten30RNPKj4K2FVXeIzh0ck0M2cAG3SybbFUFx)Ad4Pva42J5tODbZNKTz(mKs2lxj1f9hP6vEtJ5Zz3bnFcVPnFg8njMp0(11RvG66ZtR1(3ESDcVly7C22SDQm5Ks6Astm6mZ9MgBNp5oOTtKnTTZqVzY2Xni3Tu7F7X2jYUGTtQ2SDugzS5lTGU)u(fEJQTdg9lgggROnE3VWnCxbQ44Nx)0Kvf1kTq9tTMpiQpqZN7BWY86sUbJj5SY6(WvCw9PeB2S0ZDJhv9KahmAy60MT(f3EXLIYVA(qFyOK)5BCQmzggyfvtONxym2(6zWfQhxk0GZnWu7VHat5FzDvETzOtU0dDD6NTwCzxKbZ2WKJ8TVl66MKElwNO6OEWMohJKer(M4sCgNCSvfQVk(OJ5MBW0TTbAAfl0SjWw3yHUspByb7H1kB3A0fZZBV(IDJKD0(CIQYesnwdDjgsYtFyYJUcU6pH8nf83vpmna3Qh4ynnrro2X2kX7w1F9vh5uwlW1MNgktjiwqUcF5Pu1GpOtJYwJHiFfRvqiBQZouo1E2GYIcx0LvmBXYkkAKpmN1GdPESniNwxmF6AvYlQnlgiENfDO1QumiuF05zAYdUPeqUbTUoUtKkbrA1dutxmMaUioffefgLF(MhZMrXHeQ1ejxvICFA2yKfB3DjUIdd0su(JUSGilTkZcJTJcP6jCJxjoaNYvlfNx7Php1J7E2JNfZagsQk9xwo6f7p9CIRqlKHOlCsO9IZZMOSiFvQrQm5tYWsVTe161oPYccIvztNCIKSKx6R61X29fDMWlEzwrrtgQ(PwClpug2utMjDUyJSzBk0Eaj8BYODi6WFzzF)7qhbmtgdWHSAeztMzBXUTJDi4EBDKQUfATZKzU6gU0UAnVZCcLXdT7rlyBPzYCLBdJGKjZhQ(WFsPTMmlAY8rVvOQMmplTpepN02xlFu4f9Q0NytMNxc7DYhdBvc9t(JBY8caPbicMmFQNG2vLFzkvAAtMx0K5tyY8swujtMFftMLAH(CMvk6FIPhCY0ZD(WZbmjtgDOm)0MmxBlWCAWmZIbHLInd6x)Uxhgu6w5d7Jsx8YvNs82Rpln7eHy7wFISilDBARZwZYK2ytwY1x)y1NmP1vQvpzBYFUZ40oia3rAO6JSofI1fmz(iBazTdcXUfIR8TjZV0oiTUnz26KuhwlkPyrvTiLaVBY4dKDKj6R)rdKTfI7maDE9zToIEom1hRHPZY(jxR7O(rU6t6ovwaaUx7yl9Ya4xp5S8LG(KqUMN2Mqq0asfiO1rRC5iss92y4g82Wl1tcS4To0CueblGw9Mq90BVb6IocxDWnK0norwnz2lxJ2sqvs39HtlAtM3M9SGUt2vDYTIY1DRyp732VI5YX3BV9mF1lnYyRHtPtypXdcq(wO3f2wDT7zk6XWXS8yaNeZRqx5bvPRFQ12lAn7uGJop5aCX14Lf4AYF8wWMTKNGoZobRy6t8(fTHqOzWgHWSuY6V(A5q4oEBIDcQQuhQUhBK68JF(zJNy(rITq0TFdpii9iB1qISnHa74yrfJDqG3ZDoiq12qGHQvyKqND8lYgEK7mqGwMIoBt()geqKUdfzxanuQJg7ZgnUi)ffJomF0OSNVdtk886sG2YmKxpoD(lzp5WBfDkwxBdZt8I8GRTVEqih0K0GI2UQXINTRDYgHuH9VlGuQTHuJYxSWcSjUWO9l2bKYK5Fb51nz(n2CyKjZNdt9V52fG8tEfC9wFu3aobTuRAT2PlypZLEDYrcq(96MDaYVph5lVVTvyE(k0o0EDjYFauz8v38RNzYF4T0kzM8QUlHzYFegBRVw9fTm5)aDblt(6Ohg)XKVbGmIJMBC9ZN7IfM(e4Cy6BwFrjxFLMBvTq64ArM8N6UmKJpsYbZTrB6jlJluYeLvQkQZTb7OfNMnOF)(JYgSp)9hInCW(J27wBxSydMNT7iR7WJSHR7Wy36BzbMmFbxJTpFNcgmJvCG)EC4u)maWPWic)DT(igf4GipZkoWToEdTwsDTatxZ)tPtnu6YIjig8Z6ts0wNJUNzf(zlfvsC4bMoszCyiAFFp49zz)9zoG6rTOyjgax674wHiFzmoTS10LuFNnCV4LbvzFdwUMM2cor7LEJekLfG7QOi00LZsx8r6gIQoZHr6LhttuL3ATvR(UA(6vGEOBfPfNTnr6DSx0wobHMETj4XDxq13DJpgLv4NXNsrNV4B2W9Wz9Ct5pRQgUZnCGgU0zvQvsSPRehQieA6kw73d3FdxzazCfyxWOPN4Sg0O1rvXqd1JCY9qndBugZU5ITKm22wqYw8BtQ8jHcqGggOA2SggiCHsn2YyG8cOaHcydqN5LVA9gFChVaNvzDJsxuf9ZSIupk91ZyYZiwkpkfEnK(IIKUtJ33RteZ(QDwhRHv93nSw63oFD2lbWiVsBlbWB2cfFZSuaX96a7TMtU1BnbUz2IxwFnPnZQofFRCvNawXlWT9hgZnCzbAY8Vb32KMFMe9M4IfN0)0wJg2AVUa)4sBfCZK5vTXQEJ0gwD9gLC2maLjZx7ncae8QSBcq)waaDHkLMjIwGtC2(6FNcGIY3gaTSR0)DqWd8ISBcpVcapteP)fkiLyA5INDNcE(uF92Hh3MGVdcEGxKDt4b3bzmsfFcJHgwM1O2oM1JCBWZkn0vO7KmFK3vXhCp44IjvkyuDy1Y67yn)eTuB4ZQn1L07KqOs7QieUvviZw(YYZEfLazVWofc1H9ZbtMd9gdyzZ6l5opyG7IdxoH4f7Psc9Hu2PaJ9y0gwK3YLSTdEClSXx21KB7afSQ1m2ixMXWqMq(Gh62zqd25b6FBSxFAI97V20sdODPDkRUf(BAdPvpqRUA)wgHnJn4AOESurpr0PNmterXDiSrOABqtC6Y7(TqJMqJFxan6pOWmgZXoKuIDklfJVu7sIwrzA3ws8S3cZsNx7ooDWFp0wB4(MrlxWPnspZovdEkTVRLrdy4Un4M8nvG7VporQylLjBHZnF2zwyhcC)ol2o4sJ97BPK2mC8LrFXQCHbgBiH0JKBNYwRd7qGMmVJ3clAgl(kawKkC8lp(iNB2lmw(DiS4)4mTHfl6mKh7YsFDhpYBQ0(UoaWb1YfoyXZXpWCv20aCRBWoRh8(ST3SMMZGx5IUNYR1exylUhjcazBGla4CuK1z3PPiIeqDFZGbIqiAuSv041KwZHPvYzxjCBnczpjD8SAcpSgHU64XFawP)I1xChFvaEYAeIFedPecHdIWHn2ynERVahY9VQFYxp(azUqAYDpDdRTgCkXiA4dVH6JuFcqixUm6uLHKOVbv005NrSQvsoudRzNkl4KD3YJUBYpsMeNlZ45Ch7TrxGUXZdxYDowGZCv7FX6OJojofb(kwJiN9O69LF7TphiT3sMoAx(BCkc06gSuDwH1Gv2FqW16gN2fTo9kUU0AorjSNHe4GnIdtnogJj808mJyL6ZmIzhRL5fH9geeDcnggh0vVq5STnvTmVgW7Mz)R6dBnj5IlBiwHw58xJ71UVRoSxtNcsbDBD3QYKURzJ5YAFKgTqx0509(P)bnTfwzY8tRx2Mm30Tqmz(lTYQjZF1E)0)WTrMs953oz6ZwNaeKV6cTSFz12UIvh2NSA7ktW1KAcOxyjC0AdfOmdOKGYm2QjR5UtvSBTDNkoNDNkPg2DQmz(bnU9ufd1f(jo0pd0knqh3FQ2KBKPTOyd1()S9(qV)gvSP6X)DQpqNKoAP5zkQDxCOgFh3xZEdeoTz3b8WkJTmI9dxBeBofJIHdFRGy4Aa4KA2)owEu2Wbd2FqCg7Ts993C83ZWxpyGG(Xnwr6(jVpCrn5lBTcfeX1ofUb19UVDcrs)8Zu6WBwq5hT2GIi1oQJGstRQQFIn0SbljMFSjZpBY4bI2BV4HO4H(Wd9ZgQp4JKJVS7E9zJ)8eyY83AVl1t3mYO7p6l7(zWaB9wknB9MDCxqwotwUD6fL1Z6XEXR0zq)iB)DMYgwsl7NUswAWUXDDxzJ3LvkmJIr9LGfLE8JDxLwoROf6AzPZRdR926kAPXfF1w1I(1mz(xXzVJugpO)(dJ)iJ6h(uu6V3F9JmOOixkA0491Bq8NiUG9fHESxkLk8kQIAifbxpLlYxSOybdWk)xLJAOFd83Cd5QIJzLgUgNbyPTNOVF2BZQbR)m00LZfXsyiV0px2jutDBqKHRjrM)8gfzs1KitLfsKaiDniYC06RLjYNMCTUcA97nP7UA6)STipY6xzmeArK3DxknZKSbcfmqF4XGbPhdrpgM(Jky)7ySGH345PBOiwhxpAWBi)Lk7wNuTbDPOzI1FXAtSMdD4kW6qScTweRUQ0Lqxcx9HAARmDAYVi5pHULC8fapqXVhBN4axOoY3yVuci4cf6nLT7CRZu(0lZ2Ag1FuQJyOp)BxNTX9114ynOTo9zwjK(S9w(YPY0tWEqh9O7VcGlJan3sW((ihOlD2qNkYP831S75d9))p
```
