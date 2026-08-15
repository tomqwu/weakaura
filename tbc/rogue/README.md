# Rogue — All Specs HUD (v47)

Import `all-specs.txt` whole. Layout groups (drag each in /wa): Buffs, Alerts, Resources
(combo pips + the two unit orbs), Procs, Cooldowns, PvP. The two orbs are their own
sub-groups — `Rogue - Player Orb` and `Rogue - Target Orb` — so each can be dragged, or
disabled, on its own.

**v47 — the centre bar stack becomes two unit orbs.** The 172×14 health / energy / threat
bars that sat in the middle of the screen since v1 are gone. Your state is now a compact
cluster on the **left** of your character and the target's is the mirror of it on the
**right**, each a live 3D portrait with its readouts drawn as rings around it. The middle
of the screen is empty apart from the combo pip row, which is unchanged.

| Ring | Where | What it is |
|---|---|---|
| Health | player orb, outer | Your health, green. Turns red under 30% — the tier below the Evasion prompt. `%` below the orb. |
| Energy | player orb, inner | Your energy, yellow, with the **35 and 40 marks** still on it (below). The number under the orb is the big one, because it is the number the rotation actually runs on. |
| Health | target orb, middle | The target's health, green, red under 20%: stop building, spend what you have. |
| Power | target orb, inner | Whatever bar that unit really shows — blue mana, red rage, yellow energy, orange focus. It disappears entirely on a unit with no power pool, so trash mobs do not get a permanent empty circle. |
| Threat | target orb, outermost | Your threat on *that* target, 0–100% of the pull threshold. Green → orange at 70% → red when you have aggro, with the same pulsing red halo at 80% that used to flash over the bar. `%` above the orb. |

Both orbs **self-hide when there is nothing to show**: no target means the whole right-hand
cluster vanishes, with no condition and no load gate — the unit triggers simply produce no
state. The player orb still fades to 50% out of combat, portrait included.

**The 35/40 energy marks survived.** They could not come across as-is: WeakAuras' bar-tick
sub-region is aurabar-only, by an explicit `supports()` gate in its source. They are rebuilt
as marks *on* the energy ring — a permanent dim mark showing where the breakpoint is
(red = Eviscerate at 35, purple = Sinister Strike at 40, the same two colours as before),
plus a larger bright mark that appears the moment you can actually afford the ability. That
is the same dark-line / lit-line pair the bar had, and they now sit 10.6px apart along the
arc, slightly *more* room than the 8.6px they had on the 172px bar. What changed is their
shape: square marks rather than vertical lines, because rotating art inside a ring
sub-region needs directional source art that WeakAuras does not bundle.

**Nothing to delete after updating.** This is deliberate and it is the one thing that makes
this migration safe: WeakAuras matches auras across imports by UID and never removes an
aura an import does not mention, so a rebuild that simply dropped the nine old bar-stack
auras would leave nine orphans sitting in the middle of your screen forever. Instead every
one of those nine UIDs is carried forward onto an orb region, so the re-import is a clean
**Update** with no leftovers and only one genuinely new aura (`Rogue - Target Portrait`).
Four of the carried UIDs move to a region with a different job — the old `Rogue - Bars`
group becomes `Rogue - Player Orb`, `Rogue - SS Line` becomes `Rogue - Target Orb`, and the
two lit threshold lines become the target health and target power rings — so if you had
renamed or recoloured one of those by hand, that edit is what gets replaced.

**Two honest changes in behaviour, not just in shape:**

- **The threat ring no longer loads solo, or in an arena.** Every other pack has gated its
  threat display to party/raid-and-not-arena for several versions; the rogue pack's missing
  gate has been flagged in this README since v3 as "a one-line addition whenever the pack
  next moves". This is that move. Solo you are always the aggro target, so the old bar sat
  pinned red on every quest mob, and an arena team has no threat table at all.
- **The target power ring is new.** It is the only element here that did not exist as a bar.
  A rogue's kit is built on denying casts and resources — Kick's 5-second lockout already
  has its own bar in the PvP column — and an arena healer's mana is the match clock. In PvE
  it will show a near-full blue ring on any boss that uses mana; that is the cost of it, and
  it is why it carries no number.

Ring arcs read differently from bars: a 172px bar showed a 3% change as 5px of length, and a
ring shows it as a few degrees. The numbers under each orb are what you read for precision;
the rings are what you read for *state*. The one number in the build script that may want an
in-game tuning pass is the radius the 35/40 marks sit at (`G.tickRadius`), since it depends
on the stroke weight of WeakAuras' bundled `Ring_10px.tga`.

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
embedded in the script, then replays `patch-v42.lua` through `patch-v47.lua` in order. Every
step decodes, edits and re-encodes through the shared toolkit, and the final build asserts
historical UID continuity before writing. Re-importing therefore offers **Update**.

**Closed in v47 — the threat display used to load in an arena.** Every other pack gates its
threat readout to "in a party or raid, and everywhere except an arena", because an arena has
no threat table. The rogue pair carried no such gate through v46; it was largely self-hiding
(the trigger produces no state without a hostile target you are on the threat table of), so
in practice it stayed blank rather than lying. The threat ring and its 80% halo now carry
the same gate as every other pack.

Keybind labels currently baked: Sprint=G, Vanish=Z, Gouge=E, Distract=B5.

## Import string (v47)

```
!WA:2!T33E4XX1195HlLejKCmb4djrjzUIYsHupy2DXUybuf5NXUaGybbWUy2fKGqIc7S7o7odWU7mCMzbWYe5edlRWetBlb54efvBRG2M644V0w0AL2060ighLuBhNRrADNVwR6uw14hYUwMP5vRtDpN7DMDM9bEqiqgkz9hyWo35ENzU3ZVZV75CUpgUt2HoFNhj0r81rPoY1rUZ)UxjJq2zYPPOgvPOI2qE84jHhFhjKAhzvkBOPuSOyUOsYfZPjwE6v4vkur07d5nsL851VK9z9wuuZqxTD7Z5f1vQOLvuVw(tOPK1vgIQOumNYCL1xUwgMnXLYOOLtulI1RJ6UIuu(CNtqlN3uq2nKv1Mpo8ufn4YWYP0sS)3FUcIQTN8Sve0e9oqLIf9EkjzdXLfkNvsrlHICzJmr7F0u9ZBvGKYNt8gwstSGSs5uvvf5lOPurDz2fzndCCCEwwUCEfTscgq2AJxpRqrrpAczXt17Ix3qqZOTm5LllRl1we4FgTTGHMCHcIA67)(0S(5tXxwOKOEBrmWhKqfnHalORkwSySC6TDj9kzeNvSSrsO9uE(LNkAVjtnvYu9YNQ2LsOjcxIpzI(hE4LYjMbYj(oRny)dNyGXhMNMPmdkku0qksf4TiJArHQIAlwPS1RqBxgAbe1klu8KWRg82)OxKvvznN7CrHYYSAzxKBFGlkkOlM0ae3fmKUjYbIuwPS4k5GxCmhtHvdnDraCKtFbmR4ldXFKscYLhG4dkaXpjaPtsq4)7VXuwuxSyEQeH0(bLZPUxM8pvKOuyurVjvfZQVKHs2zzVQ7iXExoVg0ccVrcgcEUmtOoaMe(KZKmkF)9pQLSlwzO(4jd8YLxUqBbQiNB5o1NTRINnw8dh4WlbnP8uHUEBRiuXaUpXvPsZ2wcRpYSFhPOIqUbIOdGK9XxQcG8AlciXYUps)TXNTOGUo(RmgaCOSb(tTQSgYV8o6i7lC0ZFaY2QPfr8mP6(SX4jlkNv0Rq5CE7d(XLRPTur1OIMODBXd5TprHCfR6fAM0vk7K8aYqjpLOWmLf11v7Wo5bflPOPjjuqK0g5Mj3QhYUiTtENsKy3chz3K9q64gi7RnYEPqAcK2r2j52abDBK93g5oAJCN7)(i31trE3TbYjVK7UnYbj3d59qUxY9r(jjhICyY9tEaYd2gPBquqEOhLC02i)uioPrzDO1x6dsCY2jpIhspEipm5FqgvqHfqcHjhBzvr1j8NBSC91zNKUG3)3BBKEBJePns0bi9HnYKbOhpo94G0J)eK315VNLKbrxskDZD(oiXH7FmoSfyLSwCmjNtwvm9fTpfjlKIGfkn5ohfQ6)606nwPTRSqBau)ViQRs1uLZPF)rc5pS)iDfoCqOL6Yv0f7FEGjijtronTT6bBB5CY6txPmWqmRyaHIfvBxG(7um9WruYj(zFhqB4LNruuTxetzWJAvsyvg0T1fmq1mrjY79H)ARuOOYCdOjE2kILZwnX29DKaHihqdWW4fwgpmHfF4c4jO2WkzQyyOuooO8aCalHjpmvpEV08FAR8ViEsn6EpxeQoh3ofj6ftsj7IG)uI(IKssolf45HE9HLHF3o9beHXfF(DR2HH48gtPljKZ5vBrAA4HdEVaLURC4WZEjwQ2mdr6D8uXv3nnrqlvbPMYEk5Ca9wVWPxMEbGsumhnX3)kmkb7k3fPxF6k6gY5RcnRAkgqtAkiXiJgF0(znHyEwIMXS1AgyVQ5HE9u31aAYNZ7yveYHKoEtLQU6M9tAfAAZb1)tPjOUWPS(Xk1UpuE64JNA4yJ2VvD3vFsxm2OJ2p)urINkv8rCke250DzvNMOU60SY6YzkkMo)km2UPuyx1I8BkKXYJf1Uv9I28ALIDXTZUiOjqExKdSi0EWskJKOCbjJXirp5IaMykkzxAlTTJFFz0LlxOOipF8JpE)K(3h5JM2sRKPHUBsQ6ywawNE8WphkKgtDp2kGOKOpzDb4vbuCo2YZnzw)fJf(C5JmhLJbjjgYIIb5oakexumnKY(BmfEHIQscu6fKa5OTPjxg7kruI3rstULhC7Ki7)(4ZkjMDMbi3LNfMvqtgFLUK48QYSU6sjxs8GkQh8rok)ScfRi2riTSscLlic9UtEU0lOcgPa29uf7w5i(pcQlSGDLmDKZPOuc7cOZZFpKXQJzIWNMKuIKYI)5fT5F0GYfVCXQPzerqhmAfenq2Ojstg)Cr83tWoJ0DxD2dCiOpE)(deUt6XG0JH4d0v3DfgjYPS3Ad2l)iGbci39PjtsEuk1d5XOKnKZq5yipUnVczksAoIajdj7Ej54iISgQ8sKcEissezpKPBNmdOMtkYrkbkZKYSEuuiQKZs0i6VFIbhPcCVNLmhCdNNuLDpoh5NM8ZWrEcY7J8Zs(5iVFYcKpWDrEsoYhmDEYtXr(59qop7w9lKM8lIisYhICbees(WoGpYhH8r3OyoYtpg5zqS1mcNMxg6SuF6bRHToXMgBrEwx4kYhtI8lzHMGweONQprAYN8ktIt(uwYAYl4iMd0T)UXd9as1od1j9yq(aH6mypGeUNU6Mpqy)D7iNjF6vxcp0BejS(Mxc3o5dC3mj8weE5wV2GxINlvWrMnyFvuoBn8YWB94Lh6kcUSAgOqgFs(o9hOZG0JHOh7IEmm9y3iezcBBt(XwoG5ZfTRd7xaCUisnz6iB9Y0p4Biz6lutMoeV)Uc53pV)WDgmm9y3uI9G1KMVT((wg24qboXzLNCi9zl6y7XOx1Xg(Iua6R)GJNG45CQ7UM3HL7Z7iXsMm2Oh3X1qzvfDdXAHrzarWUrhhk7Fwb0hzm6kLubRwRfELOEJpQ3r63jLtel6j8oA8t54nzQE5pE)P8gBKrghmkg9C8wkUtsSxIcwzolUa8wMuviRONnJdJld2BvPuzRBaGt3SEncM0jxOmPDnDdb0nko05W1WTqhVV1yb2qmnPRmmZSb3J51X3O3j6Hm4ajz3xmx1YcLKZsJbe4SmFr5sYg38s5RuSyuzTSGfZz0eYjxr)jVfMO9sGZJW7szJba37u0YW3BFXgpj6xl4ADCWDwBO0nayTflOjZCu5MrWXcu3raHgha)0o80djfCAD1QDUOGwwMRAp5(walc67Wb57lIUIMb0webHUlagLpm(2jD(3dzmo0z(12aJvGApyJREsjL5IxEfD6)gbSicmK3DVjOLh3p5KKt5yvXA0NX93mldFcWFSIomn4L9hIDe4Cst5CsxJZzT1RZxtVEjQxikLYiyyRwxNMUJoocUYtoqgvnrWLisqnm0uXRyqbr(UPfSJFvaqbK8klRdo1lMrbCwUuR0Sp)UWFVIbaG0lIEpccd121HZr)JszNm88Yc(zc3JGK)Blsdqi1lC7ms9Iodn9QiGmi5z5iFJo83r1C7SJ55wK6RcwIfSlb1TlAbsZk38SY57MwbVsTxO00mslFAKtlcLwdqNmkgKDZge(7IKrwmtXbi5XwoBUEQ2DVPkoMOQlwQNEmm8fySdJb4B1FYyymdZdQkpgEU(JjKrUOSr1P0qcKP0XyzLd(J8jKCZoS6aZFlay(XbVnzIZIkfihuBkKWR)(G2KqKdTuu6v8omCP3dFYtbeHlKtu3y8YYgKhadsXuLaOl2ELMEM9ftVGD68j6LN)0aYL9Si)aqj4YS7o5VGcS)lba)FvAYFDAYFd5VLLXZ3op0UMDMiyWguBhVZfellQjNLP2KEL6oDzMweVOqUQO(ZI0yenQqjXDe(3KCaE6PSU2vVD7aDJu0faOPU3drJz0Hv3n(CeXGinvTBq6vayBXK2NQzt)tbf1YeOWQ2bMeWkQOjQaU3c8fq6mD3fTakzNXLPFVQAhmKQvOOG2y5SQhjpnyvkLpKXH9QjAurRS3dz8O(pJxfnVgpAGZCyA0knE0opJxXY52GMp(FTEAGUdGqs)TGf4APDKZcCkxQw74mLrF0T6VOzELLCYektBILH8kOcVf1c5Bq(ZGe(VV68iKlr(Fax6vPf6)j5pN8nBbza5Br(2KVtAYRzRWt(UPjFV1t5(FFtk3L6DKJp04hY)GJoFDk3KVV6Hxnv65eaeKI2uzLekweJWbASYgsP(Xb9NxgQB3pT3gkYtcWWgQzbc7dPURu0Z8Mu2OcL(fWOxYjxuL3fRvIdg2hfBxlHPWaSiaDXEWJDueAVKtXalMzGBQcm5)d5)l5hMM83r()r7s7h9QNJCatU3btn0KJZKBBPn58WtnGYK7gqLitUB0wNXK7MsFf3NxJa9GHwnG(6dnn5AB1HJMC3muFUogf(71ek8esJpF4HkFO(0NSru49S2DSKhLqBs8hGwYkw2qIowyhmKVAM4Gm)3n18PPWridf7mI(6krA19v351GFD8iRjyBh75t0s0MML95B94nQeape2ZvmC7PSHBF91eXHvQRJHCVutqUP9LxUOE4j6wOAJqUMSLHYVBfnFR)bCG5A0wgMt8w3PwAP99HKCrb)KY5nATHlNIhBsYwFtiunXMoSjeBOSAcTAyTBcTAUWwqO9QwR4RvRveAFTBfXIA1swRjCd2dDDgQZWrfUk1fnccbWz9itaQAB2pvffhhdP12X(7Jhh6qH0buNvnnfHIko7ZgVaafeyydwUOna6zPacGiH5F(XwMVqIztKnl4uKifgf5)Y9r(44acq(Lx2A(pqDetr9Gh9OKNlsYuJpk5xfJ)FJnDp)LDgga6qBv7gzYDp2LFfS8tns)rhS3rJfDvUrMC3BRklFumG(xzLrlrCW(6KjVYkvKb6VxERIqjzOnEEw9cScwGgRwBOsQfn(OdmEY(DvMG4Rxp0(sxR3r(4Xt5Qu1ydx1NuYyd3)Or73Dtr30NsGvVqzs0B0ydC6ROYScRmBMhN6UsgDW4XhEQy4KvHF8ePUYEB7lwYgGibPcBFwnKo8B3bsXX6wTv0BUYe5old8CdqJrjYRDOirf0btOUT0S(dFrxD9TsVuVj8ooD09y9cs76J8JYv2v3Fo9MIrQ4(P2nkbE6qTdiTLVt7bnZZBujbCk3aUFbxoRURqLUyTsOX(LiC3PVxTSJ1RFPFRjxVAX(E7Be2xMzbhqYLLOnZ9c2fKRmJa2KZlK)7UoY3i7NblVbYV8fzZXPY8O7e2auog0mn55jNbjIBzp7)(n1ZoLKEg5SZm6CiRnqFdS8FF17SXE171YqYtazfH6PsVo9G)4wHjWlgamxbHhqPJ)zc0vWar87lGVab7P7iHcfUt8SaWV6PhE4xH7MpyOGD2nV)EcfoiFNbdg2pf6wp42KlyABddd56HyY1Ljx43KczVoYIbeZUo2k0kOAlTt4lS22jixQuLYw2j0wJCP1pRV(IobPhJQLI3KkzNr0WRFNaWZsNotqGKBD2d06ShyvYENTo7DUkzpyRZEWvj7HAD2d5mv0sqN4HEJRLXjTu0zXaMwJtpTZED4St7gDMDA0i5FSLdDYE0YCAF(dKl0v0etZlKn6uvQIMioRGWj)L6EIoCVJKiv8id3B0t0BF9flvSt2FdmNlixMfiuGV0I4KYAYqwpp5zb6mQ2xNUo2fRJeYTuC7zkjRPPObnW7KSBnR3aOYCJlc9jxoh(EWhbSnPpg)3lA79m5q8juMtuJgttv8x4u9CNoCIirfTR6AxmTdx3h352W45EGA8C3gTB)gy4a50FkNBjTj3Pu71HrV3C5Idu640DSxCE49yJiMtw4XsXQo6pgB2(ofDI(ofBkODeJccubhadar4MDu8ayGj3auukqdCgj12ZjRNvteEoUh7g(crvrfdF(8ZaFpDVKlCxzyZ2mPn2Gtc4jaNahn5sAYLQUcTAJ2HjxA05wMjdmAACgOSDtUtYe5qdj8wBYnraaGrBfEzAFa2oU)SyH6me5BTeD4dsuPOUi0VX29J4hS3fSZdwFcVMvQqhdBa9hOrj6WgdFUWd0)HJwXK7X5CtqcVwMCNbBLaXd0WAX5AYDCAtTLo3FkLYLcm)ZTruxII3ChlWfRHctJWTjr4gp98o8BY9O7SEONj3JTraQRsxXGIdixDRGAYnEdg04OAUpKDGQ7BjsRx3gk6MsR(r2wDIx4DcKVMCNUjvyRgdxncwvRnyJWvG2kkn3I02g0rBJcBCRDfWL2ff7FvxZcAZdfYYjulRCAuaq1Vm5ewl1ltUmBvQv5gD0EnKh8KHtn9gwTk26PwzYLduLm5et7c2KVJaVLubI7T06pdTg6pDEnx)bei944xRFpn26Fnw5zqLKNTuSj8fQ852WkpNytQ805BjvEo(BPvEgEnuEcETw5HArxxSG21TNgB6VgR5uAYjL01Ko5iZm3gwZzKnPMtW3sQ58HFlTMZORHMtO)ErZXjC3n00FnwZrz4eZxOQUVy(YTH1CIVj1CcD9GMdg9looowyg98WxYzXjIdKETt7VSOwHQQ3AdbmkHIgo)3mytd1VCh0jMjgIi4TbBu64gWOTmytrBHbA2l1KJq1FOBmst92w9JKblwsydWQemjqf6bBBZp)FpYntdrunrAcakuoQEMCj47(Wdu1jWs3ikDFepyWKauaDUDIbd78pCgWZwTPQYX()84KEyzHC4Iztm3icZVnNtKlVnRaARUhNvoiU4PXjYA5CslRJlrww8ss7opdOOjALhE9IcLn4wqSCUEXL21tUp495sQwZvn2QQ8(VZ3X2OvR4yf6O0WFbWta6g5H3ieKUgPQBL8ChStFqU64rCn0DuJf9hGDehi181EbRFGuxSKW8SzMb556WhBPzXUpCuO47D)NFF0GpRUR7TUjYX9EVTkw0dFdRsWOv9vBrlofBbGx)8ezQCIzLljuCkvn4h60acv)0Hx9WRZDGw7ORLA(8fvu0iFW0SXPr9ExNsYsmZOvkLruJCHxAthUZmz1uuNIUWsd63DNeQ7caF9AHZOWoj12ZudyzbPudVXdwhVC5ct53N680q0HQhlrx98umh3gRRHAdwZ93WsHHsHznQnRnNxZ50MZd7ROXQTCzjYUVSTUGvCuxqHT0A1BJ1toDrcZBhwWlPxsrXqYEUEMEjQ61aYA6gslBvYSfLvLqAawxCQ7YPL1AXEEzNuQTgzzbLyHSkLWj4SUeLErXK7jgYz4yc3TD4aXv4WlP2UJEKLKWK78yq6k1tr5Wt0ZOZjs(yslsFhXOcNj2OjJ1x)lROjdWnAnAXOdhp6jovSK9ZqlZBHw2xBA0IjMt68pSjNo4GNbh1pVkBZKBwBMjtU5G(DNhSIPk8)Zbx(NMYWyY9ZSgSkdDfYQKhzvcH56yhT2amQUhC6ye8iwYTtYw7RnuQG(AzPcTALAbGaIgMrG)XFl4FMCTh8RVRNgjCQr)fm06SQAwX6vAeRG7FREy23mXn6VNJ0Dp(xcx(0tPY2zfSh3bhGz9vO0wBngtvchmawHoWswllAu3UDRF0NZss3(wyR()WBUy1tzaE6B(Iw3nRfHU7XuKb1j3sIBmq4J0z4WKlCZx0611Q6Hw8TI7QOOeB1vdNhXEmoaLZZdM(9PC3uXUHMCVaEp(1a44sa08FKj3)yCom8pXK7xhqP)tn5(0WlOj3VXqw(IrNcloVvS2B4TYK7ZWExm5(nH)(ST6jYYS7NO0Q8eBhFInm4QUAdAFJ80AU(TMpn31ppURAT6HrUWZSP7QXK7d2C3mMCpfCR)5rojShbtUFHRKEcAPZt3u9K8BaZGx7Uem5(fLq)h(qMCxWIW3K7ddTRFea38rHl)0UyYn5Eg4kl(6BFwtUNLrqRIe0wtcEogT8ZyY9Xy0W59DYPhyYrNBSG4SAWK7JBYb0s)kMCpNj3VAnEwtUNx68DUmQOwmMoDctJwjhqqvwYzgXQrVoAV4EDge66gg1RM9EErvl73NurPuAGF)ISxN8YffJLJ8alXovvamC7byvLP0bBCQYbu(UoFE6k76c9SXGbod3(c6SnjdrpU7nbxFxrgvPSiz380NbPJ725HvrFmO115CTZXPjKBwGOruAtJZrj8JCRwcJZXH(duZxGZALCvx1yT5F1DrE6EOofCSLhB8XMns05hU3QHXEgv3fnF9zTMCkNxrI294gkQeUAvpN7hyvUgCvBs19uBK6zZv)bkkO74XglrxlBq2W5Z8RZvzzjthazh37QLQB37(cVLX9UXWOlxj7WDE8XNGp4WRV7DEr85ywX2Go)H)Aoo3)taCk7M8cuERDb)U9d2TpQAxhOfk4ehcugFxTA15b39FjMTe(zhyrFcJLf2VahleihTnRqGez1MIe2Z1iAL(vWWHGZHi8YTGr)XBoWsNV2SWaAj6IUbpzY97JSu0yeH23DSLNlLqxDD45lF6HtqBTqaWf6BhSyeHtcTLPlTPY0LJPRz3JMvs4e6HSN0raavU0Rg7WS8QG7fvtt8NoJXCG1SvthWqSC6LyNKxEwX0laMhBuTKqz2Cd6P7BhBbMYowlDqMAWz7GbNHRZGtMmRlRrj55HolQLDEHcqTL8CECRD3sVLDxQLzRpg6UvY64I8fV3ARYMAEhR(Gn57PZsXPf(86222pSTPTQ39ACtyjyY9KwgatDBjGZyTgoyRmdUf(e7ClD8K2KZzHJtUW37AG1kS5m5x0fk1K7lzbqn5(YRo80K7pgXMMCFf4V)e4pc83xLbeRT)ayXl4WjGuARbpWwHflFbBxkdWOzzghsTC57vZYLjJ0xYHpz39mI)KRNLlB5Au3FdHtkG7Wj96Bpr9keMCVV1rpWK7NTvUQ9z3E9UQ96BFceyAY9Z1yOEm5E)iWdJFdoNfn5(ai8(cFURxmwE0wy43lCv3Y3)aqk86BFokW5Zvd4mHWeIHhsiCy(XUMdCgYfO4rxvI1aUMJ9pr9L4gQRemlpTd4sZ5(MCN7xF7)2nMLp5QecbW(3N46uOdZpRR(yNxUEoiRPIdJe6jQHLgriF2Q8rp1i9iUUUpzY9Br9AYK7FMlNMm5(NV6(lTzuB(xKMIcxM8cMC)lXd)RqhCm5(CBs)Am5ErpUrYOhnMC)2yB7)AWzgtU)nJrRI)oWZ4F7BuVwm5(3vVdl)HMCFE4g)762ff(cX1YKQaUXxWgLUFpMpjWlXlb59ICN3h5ZZZh74dMI4z)oUhCkrbv2(uswDMxaVcjMFxB1iK)Gn1Emc5LFdTZIq(dHxG)On((jc5)qAsxrgU)bsHUF8L2zT9qeYxgDI5p(MjFL0K)e7TjecH8vBXMcYnHT3RCZ2dZ3XwwCKuJRpwQjYo9Hi)NaMSV2b57J8F2Ep)GykvBZe6MwLT7JLWTKGOfbFD1tVQBwupmFaF(8fMpq3(6Pt(Gb6jCxB2niQ1ybSCvzf(F7R7k8V33q7gq9Y2nGeMTqyjXH6B6qfDudELggY4VtACzuqhSyef9ncG4cCOIFTeE8d)eqyFt2VyJwCJEv(Y0ffBTbFMU8x7y(FaEl6Okh9(1TZ6Xy12rHAydN7NIcC88c7sD)mvUO9H7NU4E2Sqr5YIE5ROlz7xo9ArkkKte81VIMwvBV7PxiQsXCWvvuYvxYjPlswDdrv7vhan5eAIGNw0GmREB1NEjXCYSWpBVyaOxXAnrBVxqtt7Kc4EOS6D4(1OOIWmEvYB)GVSRRHRVN6kFsvnCFrAxUs64kvkiwxkrGgIC1LcB3uA3UsPpzCJyjRrDVXjnyJ5iYBbcIyp42DtC9L2zRccXgH4cjkmLOCqapWgKaIPyERE28CEnXzb67iBdGP(8lnyC(ytgF0u9omL96yllDyLUpCc5zelKbjYOCt2mz7WftgWFduDaifP6awqg31FehUgdbURvBNkY1QP)sS9vf7DmfRLwFOxSLlT(l3a2ERAj2VEBwARnf0gzNCaRroKrpJe2mTPJivDRoE3eB1OV(M1TA62bUhho)mr7k6e5N030UxN89YyuWDCjRTB90BCzNj3FRL8QRqTuEDr38nVjsybvNRHcRVvtcRtvQWmH08FOJ3DpTqyzY9d3ucPWcTuiTKd3)BIerqL5AOi6B3Ki6KH6PAwPOtlN)4BHIOpYxS1IiN(HFtKicQmxdfrFNMergXICsJbhsM3OYwPwKClfrl7YMO3mPgjFTug9AnjJMOFLSgLhsTO(0BLYOcTugTsD2N(MjPuHRLsPVBtsjz(INvE2ZP4p5P2cLsRY(NKj3DC9HOzJ6A5vDbY3RjbYzJkoXHlfvFqLTqbY2nAP8idZpTnJm5nW2mDhtUPJDWkSVWcPINGgZMpWE3kJJWvDH9)RMTgutShFvMwQpTtVfQ9v9VPLsB1D1Op4VTYyDYNVFtYNeXcFOWtpz8qIIBDYNCLBP4jcgfK3wIuNe51BsI0tGCZymh)Gsr3c1ym(DAn9ilmuxRPhp(MME0CB78nBCI)GM15gQ7z0sfyAJrNzlSdqLwV9HsJQ41AbC))4Ka(YnjGZZxiEYSNy(KZuDRta)Ql0AbmniXVnRADIK)IM9vR0P6lXG5gD4uBH6CRYw2Rj3EEB5rDYJ)3njpIfmYzhF4tm7PsKzRtE8FCMwkpwWEmsUgtdEWiH(XjEW)YMeYb0sfmq(ti03CLwBHmogvBaHmiZ(rpzR7NtZAiVClIT2gLVI18a5ztYyqUdYyzQy2sZdKiOmOEPciPqHs(gxeWFDPv5Zab2kGdl6MEWXGMtRg2NP(DbZAcM)kquK0OtHHnKIMlya7j9BT9kouyrNseiaX(d(cB4zN218LgSue3t16l(Pgv9URnnjKlwe93Yqs07akA6cZiwMLL96Af0wQQDXDUF0VVl4A1k(4PC(m7osv6NcgijNzIboDjT(0IwBenFPwotmSgqZrRFts8bCVjjU)o85AlpSgGGnRmSgBtR5xrJZJcO16wzJbAtdi5x6DU51SUf4g(vsBn4L0DTp6SgoyJZcJDw)SW4r8q(8rWw6gN9fDfiv8eRZ2i57JTEuIiBiwI2C8dX9((BRfF7hIb5Gon0zTHlGLG(LJ4z)wuLs6N1c7etx3ojP52UNA3BZT9ECUjMB7E3XZ(TPf3CB33vqHI9BSzk0VwJfIC6acLR2W2wztBoLTy7QSPuot66ypaYbgrrJ9pG0kiNIt)2R6MezVBfBsKsU3Kin32(DVlr2Bt7sKgOUPFaSTtR5OH7DjY1FhfVLHO5D)EBKN(gPHOzpTIXOgR92Cwiu30ASfJEDKSAJUj0InixHsT7yTLAZPyKpyWnTuBwOADinRVR37NpyGa9ea37x9UCTV5i4Nj4Vra)b8H7TX0VXlEXDszVjRKnRiUIJT2tL3YKqs)9N20(q5Y6ltUZ1wMisvLwfzIVL0vf0MH(L1AV1B3Zk0RuBXVQ2EDNJlouWaYusoDT9dm32dmze)H7Ql8qy8q34HE47SB4NKdUKRDKBxFnHm32dz9rLHUtjqxDEl58B2m9XsCs)ov76RnSZ8w8kVxUfYiO5ALZwB(3DgPlsRQSfs(PHoEF49roWY4AuhkXuWFBbtiVLzbvNnjpTNAEi()dz)zjMTADdapUwdJU9n)Un9LO1pxlYxbC6nZMlQlAVS2ctNZ44KqwZQQZWkU(Ix7QzAcUfPIgDz8(91zxYEvoFiNv5mQSkxUqebThB8ypKZzpusSaaYDzAjhK(ju(OMCNIpArrHYi2(tYXtVMKd0)UOAc4Kp8lSdRckNlNyz(r7)K9ZBRbuuj7mkgmZk3jD2n)xBzxYvg90xZK7pJnZqh)ZejGVEcIFjZ9b)km97iCpiKpmc(dhos3Dfa)0ZgO7q0JDr1bcEj8Z2LCzXeIASfH6NknJFtLLaknwqiFEXSgI5q7fytTuS)hMbIF6TyQT1EEP6OweI9fsH5q518nw9yVrzmtxpJ572nJzSMymlvnAuaVqzm3FTvBa5xXAHg8CDeWzhy)F4vEVCSVAPJpjV)od4VB8yGa0JDspgK(LjUhk0OUnt9jsFvcem06p5K7me74AHcUU8lF6BCm1gEJp3CBhyTXvZHEn6FnWvDU64QoMD7pX)))
```
