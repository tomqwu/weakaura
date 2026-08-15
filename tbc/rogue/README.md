# Rogue — All Specs HUD (v49)

Import `all-specs.txt` whole. Layout groups (drag each in /wa): Buffs, Alerts, Resources
(combo pips + the three globes), Procs, Cooldowns, PvP. The globes are their own
sub-groups — `Rogue - Player Globes` (life and energy) and `Rogue - Target Globe` — so each
can be dragged, or disabled, on its own.

**v49 — the orbs become Diablo globes.** The rings are gone. Your health and your energy are
two 116px **vessels that fill bottom-to-top like liquid**: life on the left at `x = -300`,
energy on the right at `+300`, and your target's health as a smaller 76px globe between them
at `x = 0`. All three sit on one band at `y = -280`, and every class pack in this repo now
puts its globes at exactly those three screen positions.

| | Globe | What it shows |
|---|---|---|
| **Life** | left, 116px, D2 red | Your health. Brightens to a hot red under 30% — the tier below the Evasion prompt. |
| **Energy** | right, 116px, yellow | Your energy, with the **35 and 40 marks** still on it (below). The number is your actual energy, not a percentage, because 35 and 40 are absolute. |
| **Target** | centre, 76px, D2 red | Your target's health, red under 20%: stop building, spend what you have. It vanishes completely with no target. |

The unfilled part of each globe is a near-black disc rather than nothing, which is what sells
the container read — coloured liquid rising into a vessel, not a shape appearing out of the
void — and a brass rim is drawn on each globe's edge.

**The number is now inside the glass**, and that is the whole point. It is also why the
portrait had to go: a `model` region cannot carry a text sub-element at all, so the ring build
was forced to park every percentage *outside* its ring, where it competed with the world. A
globe is a `progresstexture`, which can carry text, so the health number sits dead centre at
18pt (13pt on the target) where your eye already is. **The trade is real: no portrait** — no
live face for you or your target any more. Diablo never had one, and nothing in a rogue's
rotation is decided by looking at a model.

**Threat moved onto the target globe's rim.** It has no vessel of its own, so it became the
colour of that glass: **green** while you are safe, **orange from 70%**, **red the moment you
have aggro**, with the percentage above the globe and the same pulsing red halo at 80% the
ring had. That costs no extra element and no extra screen space. Threat still only loads in a
party or raid and never in an arena, so solo the rim simply stays brass instead of vanishing.

**The 35/40 energy marks got simpler, not harder.** On a ring they needed trigonometry; on a
vessel a threshold is a horizontal line at a fixed height — `(35/100 − 0.5) × 116` puts the 35
mark 17.4px below centre — reaching exactly as far as the globe does there. Same dim + lit
pair as before (red = Eviscerate at 35, purple = Sinister Strike at 40): a permanent hairline
marking where the breakpoint is, plus a thicker bright line that appears the moment you can
afford the ability. They are now full waterlines across a 116px globe instead of 5px squares
on a 78px ring, which is the most legible they have ever been.

**Nothing to delete after updating.** All ten UIDs in the two orb clusters — the two group
UIDs and the eight regions, both portraits included — are carried onto globe regions, so the
re-import is a clean **Update** with no orphans and no new auras: 62 auras before, 62 after.
Three of them move to a region with a different job — the two portraits become the life and
target rims, and the old target power ring becomes the energy globe's rim — so a hand edit to
one of those is what gets replaced. Everything outside the globes is byte-identical to v48,
combo pips included.

**One thing to settle in a tuning pass:** the target globe sits at `y = -280` because that is
the shared cross-pack band, and this pack's buff row sits at `y = -156`, so the two overlap.
Drag `Rogue - Buffs` (or `Rogue - Target Globe`) once in `/wa` if it bothers you before the
band is retuned across all seven packs.

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
embedded in the script, then replays `patch-v42.lua` through `patch-v49.lua` in order. Every
step decodes, edits and re-encodes through the shared toolkit, and the final build asserts
historical UID continuity before writing. Re-importing therefore offers **Update**.

**Closed in v47 — the threat display used to load in an arena.** Every other pack gates its
threat readout to "in a party or raid, and everywhere except an arena", because an arena has
no threat table. The rogue pair carried no such gate through v46; it was largely self-hiding
(the trigger produces no state without a hostile target you are on the threat table of), so
in practice it stayed blank rather than lying. The threat ring and its 80% halo now carry
the same gate as every other pack.

Keybind labels currently baked: Sprint=G, Vanish=Z, Gouge=E, Distract=B5.

## Import string (v49)

```
!WA:2!T33E4XX119PHl1dUIsIe8HKOfPxrfkrqlsVpXcqtjBSlaiwsaSGZUae8He2z3zWUdXU7mCMzbWYeBhdjRWelBld1yxgfRQIw7M4KM(9HM6)iFF5HzuvtCCAVfvvEASJRdTJFex7AZ(500M06Eo37m7m7IDbbabPjR1FGbZCN7D25EpNZVZJ75EhUrBtNp0HICi)TvQnX2eV4EwmRqUjf1uuJRuur7yE84zyp(pue12YPu2qtPyrjX4fKlkQjv(ClYRKVIKVd6lwLjMq)k2x1DrjndD1TAFnVKUsfTCs61Q)WAk5CvH4kkffvMUS(c1QWudFLSkAIsAXSEDu3sSIYx4ccAI(sdv3qwvBMKWVQKbxwwnlOvLvWx6EMxtkVSs50vvL4ZRPurDEwvsjFbP7CbHY5kOOnSICzJSX7DO09YVa72SUmhhNNfKlpHIwjbd4P4DrHkgqdsQIxP7vtih9Ko41ne0m8MDc5YY6f8gd(NH3zn0KZNxstFxpUM1PVaFzHss6EJzGVpcv0ecoRUQuXIje19Ef9kzLMsQSrkymuEMfgpE3PspEQ0DZNU2TgwtcUfFQH7DGbMxuklutSRP1FVdmCFJmapTsz7xsOOrHyvG3ISQffQkPnxLYwVcEVmRhYgG20vHUUKwzHIJcVOqF5mZjuwM1B7G8q9DzjbDPugajoVrH7MSNyLvklTOi8IJ1yCSBOPlbmeI6ZIvfFzi(JvsqUCFK3n0aIFsasqsi4)pCJLmNUuXjOd(KTTxzr1DWO5PJfNY6u0xkvPC6ZBOKBk2l39m8owycnyeeEJeme8Cvg9RpSi8xoBQ48927qw0WeLHoONGvKfxiK(uDu88js2EW2ZcVStiN378WqkpL3q3lVEoHIsEMh7hYmsBSIkcI9fthyt2jFPkaxM3yaLk3oj94LpxrbDD8SSgq7kBGNAXx1RyEj1TM68ve0K81xfOtCYcYgsTL71EQl(ojBOMueXZPv3PnpEQIY5K8juw0xpWjxTM0sfvJkAs2Jlh0xpscIfR6dgY0vk7uCFYqlpPKWKLL01vBZU4(LkPOPvqiVeXl5EjVppKhGSfY9vG0pjbPnY2iB9oj7Wlz7u2CY9VzoYbpd5bbQUxYd7LSlVK3XUECYJ8cKD7fiAVtIpVKhLSxYJr(5i7J84KNGSFs7KdqExEjrGN1tUjY7Xd5qiptJ09WxBobG6t2i5P9s60dPlYHZQcJEaxrhKJSGQK6ybepHypHcrIcmaK3Rxc8Q2TxsS(iXXrEsV0J9rpEu6XD69Ip28Ya5mffU5rUd(C2yyqpLd79lMZcQj10YQszUS9LibSq9dddbddFwCm4Qv0L6DgqOpftMntTrbyWbhyWbOD79YOGnvSwwu)aXIeiAGyDenAy6427Y7cIY6NRsza6ykPGcflQUvb65PzcOdQik9BFhaT4QtkjP2nY0zWJIBfWbAqOxxWaL)G3Y37HFRfZxuz6(0KoFfPY5Qo8g9FOGri7rdyUXBSaEymlWXzXlqXKfZwXWqPCsqQcahMhlEaQa(oO1)uw1Fo8IAy)EUm05pQDjfO3mfvSjgEAb6ls6cY5OCHEO3Faz48Ts)bIXaMV42uBZqAgJX1lii68QnhTm8WE3hGV7QgoaXxHvQnKrSUhjDs1TrleqLvqmRCNuweW96gU8Q0BayLsI0c)qlYWkS7CxME)Zvr3qEIQWWQMIbmKMgkm2qjhQx2qiwN5Pv0H9H9QobOcuDl9PjFbFNOIGiIg5lD666B2)slslBAO)Fsnb1zpP1jlw75qbWtos6bsmuVw9Dx6LUCIHgQx(XJLmD6Kd60iu)1UT6tJvxFAkzD5SfLYmbzpZb9bgS0IS)nUIvnTUmNZORvj2T2cdDCjqCGKW(keo0t2csY5lyCcsSrNd4jgNIgMXsYRVhpRUC58fL45tE0r6L0ZojF8mwsOmP1higkysEPmi4dtEp2fuukHWIHqmaukhbeoMfCcItaWfUGtAOKhUXs4fkQwqWd)0iL)eaAaGJm9PZfOyIOxyIytRjxgvOacqB(j3ijjG809UEC(CfKYnzFKhXZStjOjladcxrAgvzMMU0YLK2RI6EpYtXpLqXksTfrlxbHY5LaL7KlLzwvWUeWuNQOwLdf4qih)S2ikzu3U9Pi)vpY64dxmZfFmYjEK7GW7gvIKkdjDtGF(8uiyaErdEkjlxSQf0dOaslVKbI)msgYOxiwGUchkwNDeQl4qy)8bcemAi6XW0Jr4d2rNDefX0Pa5A93n)GGHdim(PiNMCgkYd5SuSgYZqHyipRnSczCsgoIajlj3oiICej2R(efi59qkuGi7HCUTsMeKYjf5iLazzszM2ffIk58enI(hIyWrQap7PitdpWzivzpJlq(5j)cCK3p5dq(GKFrYhIml552n555iFyKrM8cKFjoYfzpRF5mKFfqd2hXd5frEqYh1H3J8XiF8MXYrEP643iFILWSD81mZgzopKx2IjBsHtXld6G1px)KFvG9cgfOSxEjF6mKxDTrXj)tSvZ8AoK5GDgOt8qxavnuKq0JH5dgju4UakCxD0jFWOb60Hot(nAnf(yxpuy91ofEBKN7rzu41j(Lh8Mi)YaRl8ljfthEWPc3tfLZt5xo4AMDHAFcYC0ulsiJEA(qbcgkm9ye6XoOhJsp2PLPj)SngWGRl00zeJ3r7bea)xIrPPF41lA6R1in9y8b6isGa8bIgkCu6XoPW7HFB591DEJHwx4n2FWJFE5tFm9PkoDZ4n8pNGwoMP4p)ojEUG62Q5Hy5E8nyIuPsm0rDCpuwvr3qQwOu6tcmx0XPYENsa9zgJWsjvWy1AHyjUVKd5BWEDk54jIFCFdL8KoEuMUB(J2BAFjgCWraBHrVhHx)7)lmBEnzr0C19Y3JLFJZcgKKsviNKN1IRJlagGwPuzRhWbpZSG9Kdixs2OaycNC(YKTPPBiGEfXH(9TmE854zTglagszwZEJcUkNvtquUI(ZVzB)LFGllwTSqj5C0GibUohtxrZG4F(jaF8JlRLdSzMxh7h3hO2hDg(kGvUWlFzJ(a37u0YY3DpjgjfYtb(kNe8T1M16obUU5WrwQJk3lYaol1DeG6XbmnATFUJvi850vRgkg8Rp9Ehzye1GVioqDVi3dW4gjlZdHl(ZrobxtHxag86nSyryucm6vpvbLPtwErD6)gemFbSF3TAe0IJdqojzmhRjwgDfhyPOl8ddUHv0bHbVDGiSJawtgkwtMAynlV88e1KNNN68HsPScg2IZ1jH7iB)QuzByGceftcJ3wI3UzyTjg)bwrHWwInNyxv7S70fpHKkvILdjpOh8yC1saKy1NibgbTjak)zXR1pRqw5IYgvhxdfMgxhJTJi8h5txGYrcDVSQAsGByKqAymZswXaza)6lavvukRc4BEPzTdXwq8ff5lBcsZf3cE(IgahVEr07vqYuDR6W1O)zPTlg(9Yb(5QucA1F1C0qDrJcGDfPEXNLwEvCGjmzooY3OTaTvvCtTnd3CuNPWwmRDlOU9rBqgw7MH1U39DViENAVqzOvK2(mlpJ5VdWy(jbhwzKZIk5jpQ24iGxV9aVkripX8XP3X3aWTEm(uNeacNvus3yKYYgKdGXMy8saRl(AMHEL9nZmRD58d3np)Paox2Vf5hbcbxL90j)pOm2)yGH)Vnd5)zgYFh5)fRIxCR8q3j3KXWymOUv8jNxQSKMCoMytMfR7Yfysr8scIvXh5C0WanKqjP7j6Vfzp80lPGHpH6dBhSBeIopWrO7B)0al1U62WFhjmstJx7bKzrGBPyk7l1SH)P0IAvceyvBdlcqpv0KuahDbKfOCuyE3ENZI(KBYmoIXFB12ymiwrGcgJLZPEOjOXOsP8(nA3NMKrfTY(2VXzc8m(u08zCMGpt70iwACMqpJpPYIRqZg)k1dd0zqKZjqtqbUzA)4uaMYvQnoozz0PDl9klfxzENkH001ekZFydOmL6EWJESr2FG(hAghugYxtT9wHTmTaqwv0gpxbHIfX4qGwqyHUq(6OGofsHCfY3G8nxE8dYFn5Bb36BtB03H8Dj)nnbeG89i)3iF)mKFGTGo5)EgYp8Aiu)SG8ZBap62PABOCEfaEyd1CaG9tOUL00R8Ls2OcfRd4pVItTOcVZvRf7nQFkVDTcghJ4IaOzDVp9tHIAZ70mWuzgZnvaM8)M83t(hYq()q()sLY)jFZlq2Jj3DWedn54m52qgtop8udOm5UtuiYK7USLzm5U7mRADEnYOhosRy0V2SMMCEBn7Oj39c9N1ex4FudCHhVWiZe9yL3Fp6NUoUWhB51WnboSDRp)hWTKtQSrb6CJT3i(RzIdYt4ZlA6544mMLbi5mG(6Arg1Dw311y)A7illZ29S9pDt520SSpF9NFJsWXdr9SQz3EbB2T6SKIX79vTSYc44Wo1AIL7l0al358pHCr9OJ1Pq16y5wIrvuqxRiRB9padu0Lrv3mz7yoXJ91M4b)UODAQT2pocZfhSzx0x8AtAoLJCvfRLVYYy7mJ0M)gKwtGTazxQNxbyESTeNk1GZkqHL3h7hNhNrpHmbvNsndLPPEQgsYqIcs2GrzlQgwcCLnvZIkGenlILnTdOyiHdiP2eoSPwepBQML)9aRhWWUthEYlBZWohZ5)nJoDXNF4PgoxoWHijKXe4ATqz6(V4XjFsCAciFQfSsecQhXkQ79PEkYLILk9idr(1WzfOrI1RCvNjhGoTw1EqMCpMD7xeB)4d2B8(7EOeXBXdYKBFnRT8XXO5V6AJ2WjbJStLA11Qy91B38wnHI0qha906gSi2Gg7wROwQfp5q9nsQED1MW4RxxufQl37iFYKPD1QAqIT8xkvIb6DO496EOOt6VsWw3OSd3D8e9DQvvBwK1M1YpN6wsfV)Kjhy8eyYQWpYWPxDVT9KivdSiHPeB)wdKiE6lzPwfKdAn6wzaDRpAqjr0SNiwCbDW0Phkdtp4N3LkVf7M6fHVrOt7ft7hvLh5NiwMQ2RUWkyfHI2P2lwa8WHAQrglFM2oAENV4feWuVbC7cUDoDxXgDUATqJDMevH6d1cfQ)uaeAL6yKnP8gfe)dVsG4zMd8ol4Yc0LcWd2diwMHYBY5dQ)JMXTzb7IXiENKp1LzP6uzE0HfBwsogZygYRqEgk8RlliaJ4SbP)JBWWbk(8KY5MCiAKuTaNbe8VM6J0OTdDBzU6XHQJm4GQ2vKg8N1kqbSPHZva4XGV)5c2r4GXc4pO)GH7QZyrIeneEvq4SU6IholAN8HJeouN8b6ks0W8HchoAamwA1ZMBYfoJTPHrC9ByY1Hjx0LL592tlgq2PRHTc1XfDRJDcVElTtqUuPkLB0obVwyP1N1xFrNa0Jr0sXxkLCtkz4lGtW3zLtt(dO4Mx9GnV6bBr1d18QhQfvpCZRE4wu9inV6UkEyAsi67OfvYkPRU9AtZan5fyfVIYrTZ)t3uu7UCsrnAe8pYcrgTlTSNYFGGIrwvzNMpO93fnhLQOjHPdeM1xQBp(aDp4WPtgBGUJF8U7PNePtmAVnaIoRCzwOqbOtlmukakJ)6viZbmGuH9qUo2btLczZf3y2sYAAkAfi3)MipGM1Ba8knhOCUSi(AWhdSlPhtUtQ2TdsA3IIjbOumld7gZUTZoOKOSWztZAV(zzz8440KDCCwYEDiJ8c4a2BYvpj7zTX(y4E8dRmTKgsOMtfpdZP0n5G0I4FuBbQDtxqOFsNhdd(8a1GpFiQDfnaCIeoGdciHwc1MC9rzZW5ORB1TkkRNttc6bUN)f(8XvroD)(dS2NeqaO(f3DwwwMvyLnRKOAkF4rtUuMCPRRrTA6om5YGkdz2oWuk4bP6MCJYO4azf6PMCJfe4VySShzH4dymWfI2xVThVIj3ZYTuTGFl7X5RqPcUd92C1OnzqIWzqIap962cyYD2nvpbXK7zwjKVwO3dgebQ3CmH43GIOJi74y8CyNnueY3BE60nmCLI6sa6)gdGS9O2cuBadK)hyvkG0VYK7n5okLjXsYh4NFA417KMCNgvp8I72T4Pj3inyzJJGjiids9mzFlAA9Y2qJxts1hzd1rF3j82nMj3PSEhV2IGwKnxKllcWkKCTYL263rAJYP5w6k41P0fL3)gUKfmKhjILdOw2u144pv(YKtWw8sCOH62qU)rJM(CxdXltUCGiLjNygxefP2c(tdbjtUjw)eGsCRTae3TlYphBzKFcDBH8dqp6YXb3aEACWVrHN(vsD(sjgZFKYxyTj8e62EHNJFRTWZrVDr4zGLr4j8Tdcpul66GfWoOJ1WiFJsoLo9PlORvy0bNC61MKt4B7LCg8wBjNp6TlsodTmsorUTrYXju3nmY3OKJYadpt(Q6(t4xCTj5e52EjNKRNsoyiW444yXIZZXCwIIdipHel8poHwYPmF8YLCcwuVLL0Yx1Q2puZkfRVDyKGxZ7diWdSzAaL26DIXJ5OljEmm(QTtTkjs9h6KoaS5gi(SWnHKRweVjqCciBRzjcGit5bJqxrSMCddCJLJRNvCy(oBVVQobF6UWyzbqeVxVKN0ohq7NK4Ihol4pU24v5y)FgoYM)sTTGGiUs3KehuyMn4CHC5nyf9B1T7SScXLznMKRLflSGoUWAzH4jJ760NIMKvD41lku2GBwPYIDJR7RNFNqN4kQwz0gB9xEGh5o2WAoWBQBjBT3iRf6wDOIDF4vcoSRzd7bjxAVH8d1QTJ4A6bPgLgii7iozTtuRpw)K1oxjHzyPac5sT5NTOWyphokp)BYnpD1Gthn4wziBV3DDXDsddV6w2xDzzY(23QjQ8Q(RTokhNTO1RphwgxukNCjHIJRQbNOtJVv9POVA7xJNaDaHUUV5NOOIIg5dNH8C7J88CQ77A0swHzhQsPSsAKx87sscS3zZPPOooDDRgoaWpRUfGTTBlguk)Ab1T6q)T4fvFpR8atYYn7XtvsrXOanKK1Mxhla4Az6mf41A(DwEK6LwtBKA1T6W3y9oyY9rOcTZ5bv60ypuUCbYdCvB5fR4XsxbX82XGKzwW8ubT(K10bopeKyoAbyeBZMyOuj6P3fuyRO3CfLvlmR1f6ET0wUtVx1zGKTSAzQdDDmkZYKzZPuctrz9cuqiLROth9Stt1m0Ph57AY9bPpHOuHg)DXo6bJNyPUkkhDSUgAA6KIaGzlOOjdSc0(ZSJ2lF6eX7EagXFglI)o8Qr7qsIfU4JIOw2Zm3smbQL0UgNi5wt7AzMSVMxZaGg63KUifEXF8sSOP1gNGugQPipav9QL5FQXwJ83UJ8okEr57QzfNk1yg0kUFSLzPDe0kEwOMzKYDIroXuXIpZaDxnkQcfN2KN27QqBFN35fpSjNbWYwb0886TzYn1gm5M2wpJj3mfm5QcgOEb4))8q1(fO6lm5E)xx6im5(anOu4yRsLcsOsHiyTE6NQ2msRUDmJDcFilPYrzRn6gAvy)nTvrAvRMf0FqJpoO(iqZuFyY9HwPQno9QC2BRPOlCKMVaT2N9c0ArR3(bTMTi7O0m2gde9qHNhxg(JRY26oSNgRA4vxP(EEgRTzLXlHtUeRr7zERLxpIMVvRt6XzRnW(ryd4F412mrrfeE5(FFN5ZT5e)EpBe2QRhQvm756cK3qRfFX7(YwVJw9jueEr39lPcx26sRDeb3tRoti6IqRMVUrQahQdtU)z4t7Fou4Nby7)SMC)lWCJ53WK73eKa(CMC)w473zL)7)2f)i9yY9Bx7fYK7Fj71WK73b(7F1XS89NMUuT6heinU)bl0YFqRbex)G37s(bRpZbUM9UcRIE39US9op2whyYDXAwgyY9ldv8xbvM2A)GV761nVc85Q1AYn5EX61CBY9rP40FmtUpoNnw9lX0fBY9jm5MZK7LHA9pYrJRj3VAlvYAY9jzQxpVj3NQbvQDsRz0AZWWrwyc)JEU(o9qtFIWtBPs1K7sMC)AMCVsn9NMC)6uvNVERvDUEoQDRToutUpDtubQDTvboOWe5QYh)Kd2Lulvb2YO9Wub2O)UpCdj8Gl3EFOMLleuhFR5KS1YKOoNHTkRVIc6f()ZC59eyq)RKBGqhDKX4dpWkWLxhdo4(PM9ghObhmd62bZF4ghfZUYpOR68l2kNhxfA)TDA0KB2vG2)F4gZJQ8n5EUgD6ZK75n5(Wup5EhG(FtUxWK7xI8IxcLForRWGhQjgI)A3AaOUqna1l1AFugtymPOhtiAu(tCnbu5AkE6YocCJeC8ZSEboEI6bh)xxdC8Z0kWr(8j1YMopUMMDdo61c4BzhR(SobnDBWafQOzl08agh2WblqbZdCdyeZwm5Y7R2AhRwyvuFYLe1cNfywtIwIB5lzB5l1hDzEiScqbkMn4oCJSeiiA4MAjokm(GnpSkopBNGXGYV28f2jT7c0LbAz6cwV1GjAw1at8sYwYettqwKX9mfVQGMrvAQyol8BBuTKq5mbnKkNzEJPbV5RoH8uszYYopdXFMvh72V7sy3cYudXSce42oDSEsnWOD21Gbs5MB7WUWr3kG1gTopWyE50H1Sl)ke(A1Mxip0vjxYJBD3nn4FUA0cSHB6U(uZXSzS((SqlRn9qyE(HDyM9YwQJWHc3Z1aIP(SClvw5TCKvU)mULxGE8E70pfLPnSlJYou5MMG2WM0GoVZAQw)3GINSb83eNeNPtl0rhTpt5tnWWTqkZoZB9t(640lqt922cGvBPIB8Sr(aSdSP4QEEYFFxz)Rj3FGflNj3Fylx)(tzY9hX4SED4Vld)9hd)9fSspyy88I(j)(4ELXUCSnc8muLTVxKtV2ExraY)wNnTcYBSM2Tki)7W9OcYFsbYFkWj(fx5BjfK)SRRnJcYxY1(qb5phnT7FpCJ)dziKnr28FjAw0)rYInzNL4UrLG)NUx75W5iliny6r0pr6XYDU9tElE(ehT)0uS6VCTTrIyd0BFPxv7tvZJl594fvklPN5ASjeDy(G(97pkFWo93vi(Wb7kAhx3P2U7fkXnKvq(dFnxb5DVETlZyY9N2We899ZG5R(3RMSxqKBcNyVFWWEcaNc8k)nSZyZTxJwB)g0L5yTPkKUGgBBMFe(iARkh951PtIVtNGx26RqyQ8rliDSEoxKIwlmZKa7uTDQM3n5TMV)K8joDYHs39aepV2wu3ft(lEp4M3kUPaluuUm4ktf9cQpOR7fROGOe45sfnTQ2zio9gXvkkc3vrrSUItrxSN6gsQ2ZriT4H1Ka1t0aoz7eLD5LKeLzHIY2jk6DSwWT2B2W0Ygva3WEvFhUFnkQimPpLjS)HVQR7HRGK6AFkvnCt3zlUk6OkvYlvxjXGbcX6kHTv9SnxL0JmU5AKZOU34ugS5zcbXq567)j3ivuKj53eV0wjiyiyIde2ke)QW1f(fkoVu8lqu)ltbNraCea7iluODLoBFy5jLYNfXYOq22Gz3JlWS3G6i47btEmBiDg(1BYHRDTwGDzVd44AvAFf2(1H9oXH1s2oYNVPlz7R2aB9kAPBJ7snwBt1zUwRH7R1UW1YJbTs2QaWUMdAKfa0o8EDT5wLeinVAHMTCVn5(pBVSTSGvsoZKX7i(ytCA)NZ169MbRCWZS6ODMCFll6vhrAk96YUHAwreltUVZTcejO)CZKi9wnqKozP8tgrlW(pANDTosKIk0uI08oW(3orIGEZnts0xUbs0Or6QAUcXpN8ehDDKe9X(InNe5Oc(2jse0BUzsImBGezKi2Og9FmzEJkRNsrYnLeTGlZHUTsms(Mkn6)sd0OX6vjNr5JPwuF9uDu08nLgTyDMMEBfvk)nvQ0Frdujz(INxEQlOei1jxhPsTyF5XK7DClcPzL6t5nEcYxPbcY5Jlnw7LIR3VY6ibzJgnLEKL5I2AIMCDSVf32PxZbnyr2o2F6KdJXsH8C7y9mac34j2F1gTgutQl)voxHE0o16O0x1)UMsTv3sJUF)2cJnqF(lBG(mCIO7p65oDYissRF0hXYnL8eddaYBtrAGI81AGI0vqXjnMMV)cXxhLym(9Ao8ilcu30Hhp6AgE0K7V92omX)RnkZDSoNulDWZzm0KRJkavA(2sjnGI30jW9(Zue4VEde4j4ZNmvUJptQjRU(rG)MZ2Ccmn(WVnQAdKK)Qg9vR0j7z4(fhAG0RJYCTyRG1KB7Vn9Ob6XvAGEKiCSZpYahFQtoC21p6XBoztPhZAp9i3SHb3BSi)mfo43ObICqT0HdoXXf6z6sTMiJpWvmf(5BUwonR56YnbE3EzjO6QvSdiMlHadeDGaltPXwIDa1ag)RNGGujKImrJ5w1xTqR(4cCWZyV3hVMMEmRDsS62ZCzZPxnIY3eiePmcjmGrH4IHdAnnTwIwa9cim7Ks1yZb2Rw4I(jVvSEsEYHiEoNRCgfmue3UUWBO(O1Ywc5Ifr3Tmki5RpfnDHjLkZQYoCTgllv1U5opp6NnKbsg)4jhjTZxW1bRs)cJaf5KqgyAkz9vRKoxMB(53m5()cnpJmCT756EV37aU3792vB(D2j9QL6aSSZisqWXB3jOrZteJ1GOtltedY9HZiRZ2sinFQc3ICYyt1NtgVhp0P)SUKW4pPqTTNWnTmBpHFaw(Cht2qQeDu6Fa3v1FOM8vfibuJ2Xro2y4SylOFtcE5VdvYK(btWUW63Hcn3WwQ9Sn3WwDEiMBOT75L)U0MBUHTTkAuIFZ1sJ(N2yJiNkOq5QnMZizQdmaK1zY9nI1JOeieHJo4wUTf29AFBlCjBoHnz7kCjLSdB83xTGRnFqZnCpTC3h0afmdS0DFWm4Up4kHrQjq1WG)p5E2Z7RrO67IgJMT3mmJAa3BiJ9UQ(1yJm)gcTALUJLIDUBcuTn1sQ20kgteo81jvBk494j0S(csVl(Wbd2vqCpf13c1(AwGFLA)gbde0pU75s)6H4d3RE9LQsUCs4kq1Ax79AVvZFtvAANiD5gdnXBlPjsurPwqt8pVUQG2K0pst74Y0Zzlh9X4Ozyi7RkmT8AReo1Tw314kodSISPk6(rMB4HoDSar7Od8qu8qN4HU4d1jCk5rN31E(SRpAnMByxwF7sOl1E6xnJ5DoNL2p25Ic(Lx113YwQ(sY2MnRGMRv1wTmQ7zk4UBEkqD6H3jzplGRnzOfJd)ToKIDlWIwolxeTt2UPaoi7pzTSfMxq4xRf8up8AFFk(k0(NRvdOaUehiVubCDgyTcEIIYHSLQGMvx3MFPOsUjvmqz15OJS6Y4Z4pJnQzV0f3VZsxef8KlNpMG2zhjXbDU6GPWgW4VC(GlVa96(PFSDFktUtYhVOKqzKN(tWXtVhBPsyvpzrrPY8d17O9YBTgliV8RFpuo(71YkrC9XCjtU30YoJ1QLqRy4P3YK7pNLtOJ(5If0FxHXpd2(HZIs)Y02fYLhf53JgnwNDee)yMgSZi0JDqz7dFf8dcLCzPHL0OC24hdvk(MkRaKQnRWetiLZqseTxy30Vxz2jD6Y(DqC5tUuhjHiSpJgmNdVPVlCN4MpIzI634Jn3WMBjIzPQXJdsa1JyURAjpp5FSv6YFP2c6SpF)RVk1Y9zD)PWT(THB8Bt3P5dekyGoXJbdspgIEmm9BGBxR(pgMnKHXHIWoUCCb3s(zX86NNA916OLWxDFlJ1rGlJbwj8vHwcFvBtTX3))Vp
```
