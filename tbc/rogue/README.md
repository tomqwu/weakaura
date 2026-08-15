# Rogue — All Specs HUD (v48)

Import `all-specs.txt` whole. Layout groups (drag each in /wa): Buffs, Alerts, Resources
(combo pips + the two unit orbs), Procs, Cooldowns, PvP. The two orbs are their own
sub-groups — `Rogue - Player Orb` and `Rogue - Target Orb` — so each can be dragged, or
disabled, on its own.

**v48 — the orbs are one shared size across every pack.** Purely geometry: every class pack
in this repo now draws its orbs at the same diameters, and the two clusters inside a pack
are finally the same size as each other. The outer ring is **104px on both sides** and the
portrait is **46px on both sides**; the target simply nests one more ring inside it. Before
this, the player orb ran 96 / 72 with a 28px face while the target ran 118 / 90 / 62 with the
same 28px face and a 132px halo — the left and right of one HUD were visibly different sizes,
and no two class packs agreed either.

| | player orb | target orb |
|---|---|---|
| outer ring 104 | health | threat |
| middle ring 78 | energy | health |
| inner ring 54 | — | power |
| portrait 46 | you | your target |

The ring art changes with it: **Ring_20px** replaces Ring_10px everywhere, because at these
diameters the 10px stroke read as a wire. The 80% threat halo is now the same 104px as the
threat ring, so it pulses *on* that ring instead of orbiting outside it. The percentages are
standardised too — health 14pt just under the outer ring, energy/power 11pt below that,
threat 11pt above — and the clusters sit at `x = ±260`. The 35/40 energy marks were
re-derived from the new ring radius, not left where the smaller ring had put them.

Nothing else moved: no trigger, load gate, condition, colour or spell id changed, no aura was
added or removed, and every UID is untouched, so this re-imports as a plain **Update**.

**v47 — the centre bar stack becomes two unit orbs.** The 172×14 health / energy / threat
bars that sat in the middle of the screen since v1 are gone. Your state is now a compact
cluster on the **left** of your character and the target's is the mirror of it on the
**right**, each a live 3D portrait with its readouts drawn as rings around it. The middle
of the screen is empty apart from the combo pip row, which is unchanged.

| Ring | Where | What it is |
|---|---|---|
| Health | player orb, outer | Your health, green. Turns red under 30% — the tier below the Evasion prompt. `%` below the orb. |
| Energy | player orb, middle | Your energy, yellow, with the **35 and 40 marks** still on it (below). Its number sits under the health number, in the shared power slot every pack uses (v47 shipped it as the larger of the two). |
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
is the same dark-line / lit-line pair the bar had, and they now sit 11.5px apart along the
arc (10.6px as v47 shipped them, before v48 widened the ring to 78px), *more* room than the
8.6px they had on the 172px bar. What changed is their
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
in-game tuning pass is the radius the 35/40 marks sit at (`TICK_RADIUS` in `patch-v48.lua`,
0.94 of the ring's outer radius), since it depends on the stroke weight of WeakAuras' bundled
`Ring_20px.tga`.

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
embedded in the script, then replays `patch-v42.lua` through `patch-v48.lua` in order. Every
step decodes, edits and re-encodes through the shared toolkit, and the final build asserts
historical UID continuity before writing. Re-importing therefore offers **Update**.

**Closed in v47 — the threat display used to load in an arena.** Every other pack gates its
threat readout to "in a party or raid, and everywhere except an arena", because an arena has
no threat table. The rogue pair carried no such gate through v46; it was largely self-hiding
(the trigger produces no state without a hostile target you are on the threat table of), so
in practice it stayed blank rather than lying. The threat ring and its 80% halo now carry
the same gate as every other pack.

Keybind labels currently baked: Sprint=G, Vanish=Z, Gouge=E, Distract=B5.

## Import string (v48)

```
!WA:2!T33E4XX1195bGYIC1Jsarrjr9AfOfdPIe9Ul2flaLPR2DbaXcIxC2f8beLWm7oZIDa2DNHZmlaw6yNyuAzylzwhygfR26wB0(1VgN00w0wLgNe7ywhLeh3pFn(AvghBN2sl7yxN0iZK4A3281Eo378yFbqqqcAsB9hyWS35EN5o3ZVZV75CUpgUJ3E2p5Hx8rxnJy2zK0v1sOwqvFWwBT1XAnWbJO1Ew1sM6QfkilLiVsbjD5stOTBE1Pkl7)P8NQGswz)ILK83lCYLDsMVSMzzDzT71jHELfLkuX)yQkgQL8sUFfOKNqwCMsYggAT7K8aYfv11ZloL8LYOQljRh3UUPTZ4fuo7zf1L8NwvTGPIM(8JMlNHSj3YSC2N0uYATL6mLf1L93F5cf8FI8kMYzyxnVEfw2VtUvelLnVQouJkzMjrFJKUpE7BrkLZkFBXlOkk1FgtXcYLm3nFXYWdZxCdn5S7MSlF8zliAyGNf3aYnEYkScZA9444AL3ilu4wxvSSj8CgvZurTKHpDXS0t6I3Wuu30xCLskM(YKd(NrEFlyQRm1uY6g7zF62N(cXld5iJwbXkq7GzfnzEXY6IHwaQlfkKuYW3LmkNrEwOAMQCUCkZVYKjILk9KPshJpT7LgtxgUeFQX6BOHwwsodKZ0WTsFG(gAS(hFiEAMYmGSybZ88LelkB4BPYLSRc(wsSKsrrSE3f5H6NS34LuljFrzrd5uMaEykZ83(QsqLcZXKyvu3qgGnsglG5bFqKGXlkQuckljij0Tt6KeMebo9rQpLlYAgzsPDSKHCHCurezNlBQMDw4odpJTp292HI0QoWL4WBJrOYksROjRDYGshtQ3o7CLC6WRbu)enfB9YmHD)ysy1jtQe8913iz0ausjth8y64jG7wmaZKcKZgzGxHCkt5iztwcQrTUm0IYlpfvwEzOEjRxsSWXzvRNDz8LwHjOxrPuovDwRMVL1PfbF08tPRwwBX9UScK5uQL1Zk)qVnYE8rUBoYFhYoxnlGRLuNRuQ5u0KfUOZprCDEYdcT)(ipSpYJ4J8OJSpI))5qZ374IiGGchuKmEI4rcgny8UIgnm5jjpf5XiDqECFK9toWLlBi338a(lfd5iqoOpY(i)mKNG8ZsEN(wrsXy6YLa45SYHeluqRnr65PzGGHvLK)1EBK(E2lpJSSwmutWKhF7Yt6geosYgIMieaQL9EOxF1PkOox)6YNPSCPSvgBBboyOiK9QdnE4fUiutoc8FQYs(fWKWMMvZu20uT0OGugq7lJjpefDDVRGNFkBn9LMYPOilvR0RDYQVwkMIh92MxjlLCP144pZtV(qkqkTrV)Xz0clEpATBkpV5Kg5fLQ6Urtdp0XJdCpvLdp18lXs1bNgp24Phv7EOjcA(Qiai7juKmZhpg8ZltVaOkklrt89Vkdz68UDr61NUSHPsUkqZQUQj0KMgsm(iJosFSMqmpltZyw3wbwvnhWvRTZ(1voR)JvwucX((tNUM3nNN0Q00MdE)pHUO2cNW(KvDVpu(Hrhp9qjhPp739QOmVyYrgPp(jJpA60JoSxHqUZh2(D6K18onRIHsMcYc5SvNMejoBLS3LGxiwk2Q(2Vu02w7uCkRtrLbLbYDUQ9VuzpMm5LvMkV5XiTF8La81KukAbY9GKZK7LEC37lJHsPPkiZZp6rgVpYU2n5dkqUp61gioQqg)SQQfXo(6CbhnpbEXcA5fBL47j3M2UCsffj9QyicvljbEp5aPhg5ePvsakzjqTHmCoeED1qkpsdPC4w5NdbhhJ8mKdrE6vMBISblKm6zZfFoDLsihiOKf3h5Dt(7s6Fp7JpBE5SZ0pXFRlmROUcwLUK88Akm(40kfL5NvSqz52J0HQwhVRdRNnVyPPKH(yixqybnOBvzDZkiX2bdEquPGCeFKffwCVKbRMzICubYqnHc6vrkiYyc6qRYOLkurGr7aDDQpLSjY9GCma)ds3m8zJhSNWDgV7U6Sh4q4a8bdgkAN0JHPhJWhQRU7kk5j0hig)WqFta1e5yeEskk7djnLVHmoLMHCChQfYjiNmp5uKjip79sonh55ysJNNJmzReHwjI5jzAJKf00jsCezqFMKJIXitrYtuittM59tkWrkc37sev4gQrod7EOtmiMCKYKzjZrMNuHCwY75Hj)CCK3RqoY7dGWKFEYVa7E9(filqUtYFpoY5qCi5dup(J8cKpyTWoYIKpefWr(WcKxeqzqL4LeiFKArtB7AbnroVdsAgXtXRawAzm9aKpQhgY3MtIt(42YAYR0Oyou3b7gp0div7msN0JH5dfPZW9as4E6QB(qrd2niNjFQ1wcp41Ie2yZlH3j598ymj81j8Y9T1HxEQMaxUTRpWLrLshE4zd3Bz1ZCnaxO2OqgEc(odgQZW0JrOh7IEmk9y31zSccVQX8KFQId4d0ez6B)6JmDEPeDDGGIGvUXV2LPdYhSRibdYhmANHJsp2nL(oC18c1lnFl99R7yJB)6d2y)Ho6zuMyqJzlmxZWgbId(UmxhJpgPLZQDpUHaOuV(hozQujh5iE()ROPAyk76Hw)YGjJErnOVzfr)L8pMUArnWGvN0tKW)OJ4F4(8s5OjtCu)Jm6j8cza4w7r6lT)Kdp84G9WBNSdky9ZJG1LZb(7NqrplyQ4cqnnLMywWeZAaVGrp(FbkpdcGRQxlKLbbTamf8fcmORCXsSBqgDrjLYgN7ojDNHzVlyrOYuLi7uh8Hh9nIJ0Rps79xRSKEKje5CdNIoZtAO(bMOoKsrfZ8KhOvul4UYtUdaAmWfLQa(FRKL6MiPTBJVaMR7GC)ueuCdvDtsWfMsxrcnqVd(ExsuplZnPZT7lbMWc1PsM9d(UPQNHpwVjhpfiz1pW0dMp80gAv6KeDhlqDRaKaCoiOl508gRaymOXs49N6GYDGaeef8mKyiGibAHYo4nWwM7YgAWWE15zFxxzF9x8DqgKRbUMffQ1kJvH2lWcxJu5vNB0sRAq)3WGvmGL8v3Pr1MF8eKriJU(DC8e1r1iqof)yGFzf8OBWlhmc7y1epcmIN1x5oNRY9YuVrulMr0uy9v0RgP(HZJoKJH9jjiu1(zsIXAih0QFA83gNwmJsbfZktQJcUjnW4Wjb)HkZ2Kd20gO0jhzVz00Lb3Kir0XyYmAztYxDfOusYzubNUlIYKfCIHtiSCGCQj8hlUZm04AvbV5Hx1ea0gfqxubWOwBgWVrNWs7K8s0mtDU35AuVZHB2FcuNYco6YE2KxKJDJNNEJBVI0oAFEoQJC0KfwI6fgENwW5or(6TJWPvXm5wreOLHMzbx(XFdqfiRupv6ow6chtwZbt7JdH0at3Zqii3kdo)scRnW8xhaMVm40ktCwqDkY(0Nez)6RxO2eH8KlNGEf)dbxA)8PobWkUGKSH54LumjDGb(yYIa2fFpeO)Y5Icl4Ko)yX45pfGCzplY3dG2)5S7o5VGcX)lbe)Bkq((cKlt(RyzCX24HMGSZehd6GwB4DEk5sY6kzz6ncRwZpxHPgXllkvb0ywIg9OrelkV9O)QK9Yt)jvJ6j1EGe2U8I01tbGid)7NgbPdODp4JrgdP0KU3aHvbawHuo)u3PRaQK0ntOclQEIVnG(7s2IWSZiO1oEoqVQQlRc(6cerq2PQXFtT2zag7qsbTXkz1oyoAqRulTFZd4xx2SSEj)738zd(C(v19B(SHEUdqJpT5Z25Z5xUK0gWgsGkG8FPwAGUdHWYGnHf4gPXKZcCkxYTHCMsy0jS70PggfkjZYEzcfQRblJa5pw7aRf3YCIqZVQ(KzZlwOagZG1KDH8vPA0FvYxJQm)1jFJ1K)G8Ns1Wj)xj)3i)3jxIXeq(M2KaK3OA9FY3sG8Tj)z2k6KVJa576Pu)FauQlgB4Jm447p4aJm)MxP(5b9NxdQdpgI4zSj5bqSPwwGW(j12zA6V8NsXSmLEeuyUKxUOkVl5wIoIgaa3AT7MWKy8veHEJ74DFyeVVSxXa7Jz9rrvGj)1K)gYpqG8)I8dXoX(rVXzH60)BMwi5)d5)Ra5VLNAif5)x96pwCVnblooHRQU7QhJhoYAHXVYOslUTT2irlUBdExwha4Ex)o3YrFPVzc69BcqVJMF85JoyP93RXexVGEaqjRCjZ80HHPJibCnVbfZpUp0MXjXrdcDMIXXxtje02Dn)2f51(7A9WzBFxFIgaA62MOF9hQrLD4HOTEvJ0EbhKgZkQMG3ED463g(cTwgvbOTgmLIsuAhEC7)bmFs3uH4(maIB6a5ukye9KDlw5kI4y(XdxUP2wVpKwlb4IKK)eUdVlfgUHd0stiqQXwzqIYeTBj9scacaOulibHnowEtvvWryi)AYkrHi7lK2SAc84Wacvyp4YJqrmaCbAtXMwWL7NEf(PgB2XYMf8(q2vU8B5GnSfi2agMqb04bmu))j7J8lIHNNS0k2dMoDirVq8uPhFemM8h(WKFjmA813m(Yx2lO80rCY9gzX9WKlSkw(jhUVedeBKKjw3BKf3JwBz5tGHx)QRm6JnkyOBQuxDLkE)9fJVMIq1(PTAT2ScSkwGM)ADfkPEIrhP)Xt1xdLjmw96H2)wZRJ8JoA6gkLlnvtEsPsouFJKOVgBk6M(uc1ScLzSyjs2)PUQkZQSYSzECA7mvIbgD0HMmjo5g4hFS0xD12EtMQPqKWuHDa7gsNaa4XlICBa)fslIuKaViMITR)o8IijhsiYyaD5fTPlFrKm0Hwe5eX7aYH6Wl28EuRw39rlb8C9BX1UaLx7jJNq0WKgssA3GVQxxERgJ6(G)XPJMh29xTD6DqF0(7(rsL8k6Jrntmp4zd1qfbBFL2fAvN)e5fXP5b4TfC5SgvfhuA1bC3YTG6SZKBESkUX3UUH9hYb3SvX0)aBeMEh7bS4EG8RzGubdcajhLS3IBpWpFqgrp0xi1CGhQEZbIzB85rvYodsRdDIAZXJ9f6q8)B70HWmq2gzoSJcp7f86t2EmAPAw3gzPlYM1oL4PEtDbUQ1UeiVmz8Ry33pVDubEhKH)0H6kCO4bdekqOW90D8irI2j(RqWz90dpCw0U5dhjCNDZhSNirdZ3z4WrdwDu5rqllY8UMhsb3wCh0grBX9oBe(AXfWIl4v34YCZT5cvbGwldfQb7CLmsqPyXYL8ms43zdyKGVFmrK(OvfDAslFrVG0JbYs1Fk1SZiB6pOxa4zPtNeiqYnp7HAE2dTgzVZMN9oxJShU5zp8AK9inp7r8MVHJrNCD(hvpJxAPPtFbmn6GmaQIy45VR8K7(munY2UT1lI)SO1JH2heVBIbGythtDs0DunnLwBUdjJSbDYMzay0ihVh9mNkqWqsrAm8(96dvLz4Xbijx0pE)OZBPY6Y4uecNjyA7kXqXgES0JgFOyjoASE7nz6KhVVn0qALHnNMYdAbu9)oR6yxS(wi(kSTmfv01v1H27Dqgq3(XtoFSLG(OljH1b(4Gnr9sFtP6Dj0qbEGab1AtsXiRUSP8KEd0rncHN3HPJXYXpM6CY60arQHNHtHXD4qsI8DTlq7V39IcEeMVS3THrw2rTfSEAsGCeAEFXn)0dcKQwCpdfdAl7(YOtGwC8AX86klMK0OqFz4CRngo7ap9WYskINonRD040Szi7K0jh7KSzb3bnNseHRN7HRUhRfukXcPTDxvxGJ1BfJW4LjViItEglUHaGYEGAXiwCJIjv1TWI7zRRRoVc)rgKzibRVcCWL2Mf3XysD4vIENT4sfcGymX232P9(suPr1rxBjxzKakmobkm4P)U9GwCNSojQf3P2iIr7(8Qxmc6kFzUQ7haQSwCtqLhG89Wm57Rr5Iro5)0X2wqez)I4lANriF7LPdrXyLlyitLSVHDgqU8VLGdVpyr2gqPNcjIrHeaWA88wChNdujsmK5qNnA)9DGeLzAjNpgiCT4glFnkQRrpE(q9EM2VTuDJODtV7RNM97QLAKVNpgiDT4s3OACi6BX6P2AlI30I2Tun04ntdfrinOHbQhBz6wqJEKi2o)ABSv9saBnmlUtxNcMf3ZbkvwCpVqvn1t2EOB6uLSaVZUUOcLObviPrgjMPYahpA6PV5rfIBdQb15T2Aq9EtHgeCEpEE8gS16B(VAvF68NCvF6Rb1NbutDMIjpzGiLo7npQphzdQ(e(wB1N(Vzq9HAxxxSag2DR132F1Q7e(NC1Dosd6ofNyI8g65p(WZm3np6oFKnOUtKBT1Dg4MgDhVGTxxB)vRUtKFYv3jzd6oQdn28tvXiqYasBADhmWyCCCS4O1YHUK3ItfhBD3F2xjz9PQODF1flPXu1XzPMjn4rpqRyKuCMIN2rp6iyuIOY7Ap0n5U)s0zeAnJMblSrGuynIAekUEN0koj6DGHX5Ac)pikDDImea0GM0sjmYingF3hO)kSM0E9r8n0oXaf1E)2nBvhhmwl8E8T4HYaULRpzfo2)NNdSGAfrjCnUjlnS48T49dLsTyhWBTD5TGcXf)loByljLFfdCbCYIHHq10l8gfelzYTGCjPy4c86C7gAbVKM9ewJTmlFIh6T1YMoUA60hGSenc3zYQRQn58u9ZGGwq112(v1LTRTlrldgQQmjhjvYE7J07EwC30iBRTZhVMPQXJ)4nlq3aoO5r6wlG7ktCs2QmT2zcYKsYzvkkwysnD4edAaWQDcVRDGRWDG(kqxmV85kOQQtEVcSaQR94xHsYsmZiLlMrwNCUVcIGgK1KvXUj7PxjrXEkOe9K9mYCqBbamIzJbOqI8ATLXvOBlU1IUXdUfVsPPMmuaT5XqAP1woxrIDoS4EHLPl)AkwHJC(Vca2r216RkkLYtg4YoWi7GqEzV7hBzG6nygr72oowS(fVKrrvvZ8oZBsHfYQweNgUg5xMcn6xr3Wm)kQSf8A2ckA5VS3lU7AmL5fVBNilyNFdFor51IBA6AaM3nANVit31D0ISj2DNT0oC6ouiRDpanMZQ7b4JMFdzxXkQ6kaaHw5wkXqJM4ONizQ(i9FOns)OvnS0Tb5P93f5cD0zGQgNEQ)zbdXoshvAVYSuraoXMpv0f)i5cTBxuo7(O12PxtU9kwDXdzXvcCZtLJ6TNwlwCNXHzYIth6LXOg2hlotiBLPKowCZEnr0yXnxEMvBE8lwCvGN5zT4EpKENy9hBSV02QNYWTfkCKMVYxUpNv(YQ2a8HTJ8UVXE7H6bSEVhMHhN8Thk4bJeU7LXf78KASvLVZad4c9UKDch3zn7YwmWtweJypRq7Dz7fXmQw3M9j96TaYDUfoA(hAZfwBA8Sp)DCr77M9kgV6rEKPyXwCZqoI7mYcGQ7fTR22VMKZDhO1dRw9BRmU0nw8ES4(Lznv0gh3Mk7gUpokjFfqc(pam36FOf3)iYET4(ewC)Jbb6)elUpjubT4(udA7MeDMTWQvwCldvdlU)PUpClU)z19eBIWP6Ny(14j2g(eRDiyR5P1wZFAxH3V19Pv973A)WiN7tq7SWIBb3okYf44t3)eJm3XcpNf35GC(ba2BlUpi94Ia39NWM72I7dLhnn(ddQ)otABoBIylUxcA()iqEop83FF4Vp6BUTqUmQwC)IvXLoJf3s1YG2u3wUDhYrhdQVIgtFDHk1I7JzXDbs)dEvsDojMN39HrUZiUZ3aTDHtWSWhSwD2MwQWbQRurwRsTaq5sh1fxg3G1Y4AX9YCl25kiJqHKg05pnAMCirnL8u5VnvRonhOfJ3V3qu3GpLBvDVDrnBt4NqvTOaWSFrw1jNsb5KsKowM9tnrZ8KoyVmtAa2fvHdySR63ZtxDyN752yR3pVbJFbd2UNHCRE3m9kvFNpl29e1RI4JOwsMmap9AK2EmVmv24yauUQ7auOn9ylJEx80RCSXp2SXtm)qXQefvrSLsNTQAM(8VXo90NkyNdOHbxSHph6GcouZ3N2oPxOx7L5uPCQ51fLMfyEbQ1nUp2Gpg16R2eA7YDu8ztD)(liA45YglXQwsHSH6N5yxvLLLmDSH98VZn1BL9V7On6F3aLZouNhz8tYhEip)76Dd4FNFW8zNqm9c2ZLMvORHNs01W4Ad51TZbo9AijfIdTNsm9Gz51aRZRiGt6MfaZTnRuuSKqit5sclBohyjzLCkZklKHDUajOa13(94Jg2emo9Sd0OwX6YIJf2eQfC0OMGV7p9kZLwSRUoW8Lo1qJ5foJQwOZVUxyv2o8qUlYRq569bNFhD0DakdYDImK4SKcfya3YoQNDhLAvhvQ6v9CMYpbDNYpaL5xfJpsZd4XNf17pSB8oIZ68Ig)LxaD4In5nab7rVz2swhFHV4J7UwzCDdw7jBWjtVfuttCUTAtGR4ybS2JTo3ewcwCVFB7KPUVfYBOsJgUPwlJEbFFn3lyV7TNVZwC)82EaF0QnQzI49MAOJ3DpdhmvZnQ5R0mJAy(ws5qywsTjmU5ZvJXnolLFBeUh6gPGwpeTT9ko67wCFbH1zcy(7zRHBX9A263wC)(cSzu3Fa83Fi83xe(7pIPjZmW5qvzgYD4Ags0aUtfzOjOl7XKRgx(4fNcOvC6XO1nOJIRWeF0DkN1YvrQHl3cOrzX9ZTrcN0BUTaie3I79wF0HS4EFiY1jKpwC)cOIcZ68AaYNu8KYrhumAu(JTXTo)n3wWnbY93TbKB9w(9kxVTX(jAwOhczdkEZTLQweKf3V0TQahW(0IniBhwmx2k8joXW9i3CzBX1NKYEENSzyP(8RNSM5c2RSf5qfvqEY1K9iuvlyIxSzL42QMFkIZ0ABTY9T7GLuRpl)lwFVNS4(vOonzX9PP(mDuxK0V6A7U0vVsJf3VMaf)9VK8kwC)64H)vCuWZ)6nPBnwC)BaeXkWD4FRR7lwC)7q8Z)EWZflUxfDyXI734A2pf(Pgvpt6PW9cdehzX9Bcp0pt1EMCrlUFR6DkXI73gWM)o5TnIcmWna5v55tEKbstAzpEEhCczrn2wyswd3THKGuJ))ScKp3MABhH872k5ZJ7ZiXhQV(tt(pc3RVWgFVfH87jqET63ori)(OVi)bo7FiK)qO55l2bFVK)iGy5lr(pbTtYdNECJJL(KzNE)4Sh(l7UPG4U9TWEj)knBVa5BqwDhxRBdiB0TDSLXnTGefaxDneyRaIdXhkqGar5d1DGE6KpCOEI211P9rQRWAEzlzpa4bUI7baX2SBAqnzpLZIZQUrO1ErPshy2VLaUeccEWiolUa8u0ZKqisJn4S17Qz93P2RW1(8FF6YnGUUwdHo)6UsJq1Uyi11xdWGIZov08Yd270rk0SDEO3j5vxEGr5toXOJKo2qKw(K7uBpmWzIEXnTgCxjwSGsjz)8LnY74So9AXlikj7V)cL11R44Yp9cjulibxvvvQMKtrx)VgMYAolNaAYJPldUKsdXT29xB6fLLuyb)2z1dqVI9kO2zg4tt74I428R2dwD1OGQ4m(vZ58GVCvxdxbs1u(uA64gP0oRkPJOwEk5Asjo0qivtkSTFP7PQu6vb3evYAwtnoLjncioR3H7(j3gvD0M5a0ZBsel2iuAGMgQMH0za5YgKllps9bCzaJwTCzidgsscSS28qingWfbCxFUwBCHp4S9LunbgLb8Pxj)bu7(aJPmJ8uzO8HafeWuETVPg1e2mNvEDvl)(lX2dwCQFS1IFKxTH1I)LRdEF9yn5Vr2y1wFEOnYU(a(24YiHBds2BA3ciT0MEhldynSzYEPA7LWLy7nW9UW5NjrxjozUjcmDJlwElU)AVvlpJPCJl3S4(bmzvxrAqwDXQPBUfsqbVkUcklUF4wTa6BbcOtuCQzIOhC)hP7E2QeqrfBqaTShT)TqIh4f5gP45BdINJhPNkzZNyALChzRs8C(VyJIhVUFVfs8aVi3ifp)zG4Xmz8JBoWGk8ML3Y0EuAq8SsvMbDRK6JYnu5Z3bdmwFQznlnOwbJTSUFIovdYNvRXC0BLKqtDdvc9DbjKcFHZOm7zvdM6eBvsOMSXkzXDV3Ciw2G(rEdqy8)aegNjH8jpqXegdOUvjm2MzdYImm3X2mYJRHTD62NythKGvzF0fsp6y04d9EU3RJbm4gGG(7Hw9Pl3tGYtNVx9tTvP1v5h2GKwBN17M9BPewRS5phKnJLm6(Jo9eJgrwEls2ivQbrtC62SYBjnQrA8xasJEcjnJ5C8dKpXwLMI5NPrkrweMUrtjEKnnLOvlV9B54b)FI6Ad29m6PdnT5iZSv1HNAJBFO0GfEJw423pvjC)lX5Sk)uJMk7rNp1mv2IeUVXcnkCPX99TysRvC8MOVyfprVJnG0idLERsxRjBvVwC39BjlQvw89bzrYWXpZ4dD0zpXyz2IKf)NNPbzXcod3XnyQVoIh5NQ4(UmiGdPNoCOChvS35kE1iGTVZBeHmoKt)OZ1yVB6oJFvJBFJniJPngRTAhiqBqidc(jPsyNnPUCurcieQvQaIkuQKREPYRN)kmuTxdd6eDhOdBCFPA3emDLm)v2t4xqgcQsp9kPm7uCiZ8jKchcfmGeYE8w)W409yXa0HdRLPRAYqdMfIBMA9o6jgr7XCNeekfkGovzMx2F)Q6gIZixILL7TQ1hBXkof37(r)WUGleSrhpT3y1nCf63agijV5zboxkT)WXYgzYZDN2FVxChzY7Q2rMCeVTiX90EGQNma1VHh6QYBpXlET8vpPlQFYv0DiWZ71A(v85QAUv8QXX2GQgxsV5uXkUZPIzhRXzuH92hiDwrhgLuFwHAgoYRET21zNK89XwzlXvmLlsBz(b4UD)93Kp3djHCq)WQWAgPF3kWsX(uoGkLl48ZT)X(o1SzsA1YJ5EVTAPdVBIvl7LvuRwEhB)J9D3efk5VYMPqFkxrFiXsvQNVxOgQaqzNP1xpBpYra0aihHnvWAUdtg76WomPat)ULhf1VTXiMOgvqxn8wUVR0EmzSAqs1Tts2K9wY6t5kSLIxhjnQT9J2(J8mvZst5G)B12vZynQI0(G(C6ygP1BE)YBjYPn62jl(ATjKyZPAMlCypj29)Jzj2SqwFsD7pJ07HpCOq9ecNjGR4(fgb)gb)1dfmuaCRnM(jDXpUlk7pv5SzLXfinUvX(GBiJzVHQkT7nUqrMQh5juEGTCHsGLn0e1NH(116EVi9C2Yo(KCEIQvPP7UOA1ARMFJRrvcodADw0tr96077z1YbMiEWOD1fEikEOB8qp8D2nCkzFl7TFGx9hviRw(zT)2Yq3SeORkVL9oNT8JSfZ0VD1v9Xhgf7B2oOwiJOEvlnx3jz345RUT5uqpYhA3K9UcUm3Hsmj831HzD3kSaQZMDNoZ)UzbeOZ3wy2Qaoe80wdm5dS53fQVe99RQfD8PXPzDnqwurc37zW5xTU9RoIcrq8suHGHcwY)yYhIZbrxqn7mQMRqV5dq)KiFyloE(efKflzNQIKKCj(r6749XZAKDwP173BLwJk6kLMkUO(Php5t59RNkffjslwEp9M9qo)xy7oZy7d3kdJ79r6g1EaUi6CT(B6mV(YFfiOEDlUVU9e98thpuGEcJFvZdaNfL(zdUheChfH5rJgV7UcHFPzd1De6XUOO9WROjRJOxS9DbXC5KZAcKwFCbkV1LWpIxkLKhJLhHQNdBogj(P2SZyupSCegpNy(FSSlPN86hNP7UBDXkjsOA6j7FWReNzs3vZzRKLiFmYfApK9SB3DJp)xElSJo3paTb7muWUXJHcrp2j9yy6xI4EOWIMV3OFv8flTjZB4oJWoUEWGBk)2LETdQ2ywij4zHe4Rxv20(qx9aRoVUcSAVy7sTlT4JuZEK(0Kdri0DFRVg4Yn(gyVgGD9jmj6t4D)L2UJdQRZuE1h3MAHcShFoZQ2nBidW9L(yqdFNgZ2vHZKC0de6aonZSP2VZIaoQZ87huSA3GVZdg5GbAF2T9E))d
```
