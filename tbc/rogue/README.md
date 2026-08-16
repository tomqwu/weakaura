# Rogue — All Specs HUD (v49)

Import `all-specs.txt` whole. Layout groups (drag each in /wa): Buffs, Alerts, Resources
(combo pips + the three globes), Procs, Cooldowns, PvP. The globes are their own
sub-groups — `Rogue - Player Globes` (life and energy) and `Rogue - Target Globe` — so each
can be dragged, or disabled, on its own.

**v49 — the orbs become Diablo globes.** The rings are gone. Your health and your energy are
two 72px **vessels that fill bottom-to-top like liquid**: life on the left at `x = -150`,
energy on the right at `+150`, and your target's health as a smaller 44px globe between them
at `x = 0`. All three sit on one band at `y = -262`, and every class pack in this repo now
puts its globes at exactly those three screen positions.

| | Globe | What it shows |
|---|---|---|
| **Life** | left, 72px, D2 red | Your health. Brightens to a hot red under 30% — the tier below the Evasion prompt. |
| **Energy** | right, 72px, yellow | Your energy, with the **35 and 40 marks** still on it (below). The number is your actual energy, not a percentage, because 35 and 40 are absolute. |
| **Target** | centre, 44px, D2 red | Your target's health, red under 20%: stop building, spend what you have. It vanishes completely with no target. |

The unfilled part of each globe is a near-black disc rather than nothing, which is what sells
the container read — coloured liquid rising into a vessel, not a shape appearing out of the
void — and a brass rim is drawn on each globe's edge.

**The number is now inside the glass**, and that is the whole point. It is also why the
portrait had to go: a `model` region cannot carry a text sub-element at all, so the ring build
was forced to park every percentage *outside* its ring, where it competed with the world. A
globe is a `progresstexture`, which can carry text, so the health number sits dead centre at
13pt (10pt on the target) where your eye already is. **The trade is real: no portrait** — no
live face for you or your target any more. Diablo never had one, and nothing in a rogue's
rotation is decided by looking at a model.

**Threat moved onto the target globe's rim.** It has no vessel of its own, so it became the
colour of that glass: **green** while you are safe, **orange from 70%**, **red the moment you
have aggro**, with the percentage above the globe and the same pulsing red halo at 80% the
ring had. That costs no extra element and no extra screen space. Threat still only loads in a
party or raid and never in an arena, so solo the rim simply stays brass instead of vanishing.

**The 35/40 energy marks got simpler, not harder.** On a ring they needed trigonometry; on a
vessel a threshold is a horizontal line at a fixed height — `(35/100 − 0.5) × 72` puts the 35
mark 10.8px below centre — reaching exactly as far as the globe does there. Same dim + lit
pair as before (red = Eviscerate at 35, purple = Sinister Strike at 40): a permanent hairline
marking where the breakpoint is, plus a thicker bright line that appears the moment you can
afford the ability. They are now full waterlines across the energy globe rather than 5px squares on a ring, which is the most legible they have ever been.

**Nothing to delete after updating.** All ten UIDs in the two orb clusters — the two group
UIDs and the eight regions, both portraits included — are carried onto globe regions, so the
re-import is a clean **Update** with no orphans and no new auras: 62 auras before, 62 after.
Three of them move to a region with a different job — the two portraits become the life and
target rims, and the old target power ring becomes the energy globe's rim — so a hand edit to
one of those is what gets replaced. Everything outside the globes is byte-identical to v48,
combo pips included.

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
!WA:2!T3xF0XX119PHl1hCfLej4hsIwKEfvOebJi9Ul2flGmLC2DbaXscGfC2fGKGsc7S7my3by3zgoZS4dMy7yizfMezBzOg7QOyfv0w3eN00ZbT1)rpN8HzCvtCsAFbvvEASJJdTRJtCJRn7PPPTP19EFVz2z2f7ccacstgR)adM5nV3SZ7DV3F3pE33B4gTnd(oow0JfSTkTj2M4LoWY5fkmLOUQws1YQ6N0NpFd7l4XIQ1wbvftD1YLLetwsUSOUKYKlZRwSQuGJgir1jMW4koxfVSKUPH2oDUMxYqTQEbjJA1FyD1cEQqsv1YIQZOySuTkm9WxjVQUOKEc7xhTDKOS8fVOGUyGSq1nL10Nnn8RkzYLNvZs6ZXk4p8EwuxQOSQs250K4lQRwvBrwvYiFrP7CjbLcLu1hwvwXmFYEhkBV8lXUnRlZXX5BjzLju1Riycpf)llu1eAqAn8kd)6cfON0jVHPGUP)8tiRiBuYFc4FM(N3uxUyrjDJ99462N(s8kcvKm8NWeFFeQQleEEdnPYLtjA4)kgvZlnTKIzgymuE2Lgpz8mzhpt248zRDRH1LGBXNz4EhyGffLYd1e7A6937ad33idWtRu((LekBwkrv4TiVwzH5K0xOQI9RG)lZ6HSbOTDvORlPRiuEu4ff6lNFbbfzwVTtYd13LLemKYycK4IMLUBYbsOOQiTSi8IJ1yCSBOBibmeIgZJvfFzibturqwPpY7dAajijejmPd4)pCJLSGHu5jOd(KDDqzrT9WO5ztKKY6uoqgnPcglAQwyA2l39m8EwAcDyeeEJemf8Dvg9RpSi8xoFMK8927q20Wukqh0x4QYIl1HX0Dw(cPs3E42ZdVStix0)IWqkpL3WWpVrbHYs(we7hYmsBIYQcI9LWayt2lFLQaxM)eaLQWEj94NVqzbdd8S8Mq7umXtT5R6vSOK2oZCHQc6sb6Rk0jotjztP2k8Mp9LEVKTutkI4BmT96WJNPSCbPackIb6bo5Q1KwQQzwvxYzC5Ob6rsqS8CbGHmdvf3I7tgA5zKeMsrYWqRnNI7xQIQUEjHIse)K7L8t4J8aKDqUVsK(jPiTr2fzN3jzp(j7MYMtU)TZro65jpiq19tEy)K95N8E23JtEKxISF)ar79sc4N8OKdsEmYpg5qKhN8eKdtANCeYpUFsu4z9KBJ8(9rogYZ0iDpY1MtaO(KTsEg)KU8r6M8u51GrpGROtYXxsts7SHepTypD0bjgWaq(a(jWRAC)Ke9rsIJ8KEPh7JE8e0J71)LESfLbYzgkCZJCh8fCWWGEkh27xUGnutMzK1KYDzNlrcyP6hggcgg(S4yWvRAi17SGqFgMmBUAJcWGdoWGdq73)LrbBQyTSOXrsenuSqj6mwSi0XTFC)ljkBmzvfa6yAPWcLlRTtb65zzcOdQkk9RFhaT4QtjjPfhz6m5rXTs4ani0BiyIYFWB5h4PENLlwwDM(0LUqvjLcZn8wdESWrjhqhyUXBSeE4S2GJZJxGIjlNVQPPQsAqQcahwelEaQa(EO1)C21Fb8IAy)(Um05pHtjLO3mdvSjbEAj6ls2sYfOCH(O3Faz48Ds)bsWaMV0U0AZuAwZXnkji6(QTaTm8WbpeGV7PgUaXxHvQdKrI4JKnT2UOfcOYQiMvHZilc4EXHlVk9gawPKiTWpYYmScNo3LP3FYQgMYtmhmSQRAcdPzHctmu6H6LneI1zrAfDzFyVQtaQa12rF6YxmWPRkiIOrbYMTU(MZV0Y0YMb6)NrxqB(ZyFYY1Eoua80JKDGud1RDF3JEPlNAOH6LF8ePZMn9GUnc1FTF7(0zRRpnTSHC(Ys5MGCGfG(adwAz2)gx1UM2xwWD01UeNwBJHoUeioqs5Cfch6lFjj5ILmpnjXOla8eJtrdZzl513JN3qwPyzjE(0NyKEj9SxYNiNTektA9bsGcMKxjhc(WK3tCrv1kiSyhigakLJacN0gobXja4cpWjnuYd3yj8cL1kj4JFgKYFAanaWrMzScHkNk2fNiXm6YkOcfqaA7p5wjPbKN477X5lusQWu9rEeFZpTGUSamiCfPz1KzA6Ykxr6GQAh84pn)0cLRk1wu9cLeukkbk3jVwU51a7satDMd1QCSqhd54N3brjN2UDof5V6r2aF4I5U0Jro9JCheEVOsKm5izBc8ZNNcbdWl6WtjTs55SHEafq6fLmr8NrYrg9Ijc1DKos0vND0nCisq(qHchRd6Xi0Jr5d3zxDgdX0Pa569hNFqWWbeg)CKXiNNI8qEwkwd55OqmKN3bwHmojhhrGKNuyperoIe7vFIsKI(iLkrK9rMCNKPaPCszosfqwMOW0UOs0ixGOtm(ietosv4zpnzg4bolzo2Z4IKFsYpfh5ds(qKpm5NM8riZtEH9tEroYhfzKjVe5NHJCj2Z6Nnh5Nd0G9Z7J8Yipi5J5Y7r(4KprZy5iVsD8BKp5ky2o1gMzJSGpYRAZKnLW54LbDWgt2p5xayVGrbk7LFYNjh5n2yuCYVSJAM30LmhURqDHh6gOQDeTd6Xi8HJ2rKUbkC3D2fF4yH6YLot(vAnf(KxpuyJnofExKx4rzu4nj(Lh8Mi)YaBk8lPfZgzWPJ0tv1lq5xo6gMDHAFcYC0ulsiJogFhHc3re6XO0JDspgJESlBtt(rBmGb3uOPZkMSZ2dja(VKGst)OBw003SrA6j5d1z0qH4dfRJiXOh7IcVh5DL3305ngAtH34WHp1fKh7KgtxEMMXBeCbb9cmtXFX9s8DrTDvZdrLEcmyQmzsn0jCDpuwt1WuQwOu6tcmx01PYENwa9zgJWsfnWy1AHyjzG0dfyWEDl5uPsEQadL(mUEuMno)j6nBGudo4iGTWO3JWR)9)fMVOUSiAU6b57X2VX5bdsYOjuqY3gX1XLadqRwrX(bC0Zppyp5aYvKnlbMWjxuHSlDdtb0Rio0VVvXJpxpR1zbWqk3g2BuWv586cIYvnEXT74V8dCzX5ueQixGgejW15egQ6MKGlob4JFsz9cGnZ8gy)4(a1(OZWxbSYfE5vm7dCVtvppF8EsnsgKNc8von4BRdR1DcCDlGJSuhvUxKbCEQ7ia1JdyA0BFYtwkYKgAZ1rc4xFMdoYWiQbFzCG6ErUhGXnAEMhcx6hJCAUMcVam41ByXYWOey0RrMsQZKwzzd6)gemFbSF3RAe0IJJqod5SUwtSk6koYkrx4hgCdRSlcdE7qrzhbSMCuSMC1WAwD55jQjpVi15d1k5fmDeNRtc3v2(nOY2WafikMggVTfV9YW6qm(TSJcHJeBbXUNRR4zlFAjnQelhsEqp4X4QLciXAprkmcAtau(NfV24zfYlxw2CUX1rHPXnWy7ic)r(mLOCKq3lVMUe4ggPdDmMzPRAImGF9LGQkkLxf8nVY8oHylm(II8LnbP5s7apFztGJ3Om69kizQTtd4A0)SSofd)Efa)CvRaT6pFbAOUOrbWPIuV4ZtlFoCGjczboY3OTqTnN42ABwUfOotHTyENwqD7J2GCS2nlRDVV7Ez8o1EHYrRiT95wDgZFdGX8tboSYiNLvlsEu9XraVE7bEvIsEIftsVtGbGB9y8zodaeoVOKH5ikYMKJGXMy8kaRl(AMJELZnZnVt58dhNN)CaNl73I89bHGRYE6K)7ug7)had)FtoY)ZCK)wY)lwfV0o5HUtHPsGXyqBN4tUOKIKUCbMytULR7YLysr8scIZHpYfOHbAiHks3tSFnYb4PxsbdFcTh2jy3ieDrGJWiWHPbwQDTDH)osyKMgV2di3Ya3s5moxQ7a)tPf1QeiWQ1gweGEQQlPco6cilq5OW8(9VGn9PWu5CfJ)l0AJXGyhbkymwUG2XMGgJkvLdB2EaDjZQ6kboS55d9Cbu1dyE(Wpx70iwAE(oEUaskIRrZg)k1dd0vyKZjutqbUzA)40aMYvQnooLc60UTELvIRSOBLqA6gcL53UbuMkXh8eNCKdhQ)HM1fLH810AVvylZiaKvv9XlusOCzmoeOfe2OlKVokOtHuixH8niFZvh)G8FH8TGB9xqB03M8xs(RAcia57q(Vs(RZr(Uoc6K)B5iFVRHq9ZdYpVf8OBNQTHY5vc4Hn1kaa2pH2oYsVkqgzZQuSoG)8kU1Ik8UqTwCWybP821kyCmIlcGM1d(mpnkQTOBZatLzm3ubyY)BY)hYFxoY)xY)pQu(p4BErYbS4UdMyOfhNf3wYzX5JNAaLf3DIcrwC3LJmJf3DNBDRZRrg9irBfJ(1M10IZFRzhT4UxO)SH4c)DAGl8uLgz2yNu5W9ymwDCHp2QRHBcCy7wF(pGBPGKIzj6CJDWObRzIdYteWpA6544mMLdi5mG(6AroT9w311y)A74RkZ29S7ptt520TTpFZNFJsWXdX8TUz3Ejh2T6SKIX79vTTYc44Wo1gIL7l0al3KbNqUSrSZ2LWC1XYTcJQOGU2rw3(FagOOhJQUzY2XCIh7RnXd(9r70uBTFCeMljyZUyGK1M0Ckh56kwlFLvX2zgPT4niTMaBbYUupVcW84yjovQbNvGsRUp2popoJEc5cRnTwoktt9unKKHefKSbJY2unSe4khQMnvajA2elhAhqXqchqsDiCytTjEounB)7bwpGHDVU8Kx2HHDbMZ)BhD6IV4WtpCHcGdrsiJjW1AJYe)p5XjFkCAciF6LStecQhXQAh8PFAYRLit2rgI8lIZkqJeRx)QUtoaDATQ9GS4EmN2Vm2(XhS3K9hFOujBXdYI7qnRT8jXO5V(AJ(WPbJSZKz91Qe91BCE7MqrAOdG(ADdwgBqJDR1ul1tMEO(gjtVEAte81RBQc1v7DKpD6SEAvniXw(lLj1a9ouYE9ou0f9xjCRBu(HJNmvFNBD1MLzTzJ8ZPTJmj7pD6bgpfMSk8JmC213BBpPY0alsekXoO9ajIN(k2Qvb5GwJUPaOB9rdkjIM9ejskyaMo9q5y6b)8Eu5TCCQxebgHoTxmTFuvEKFGOcvTxDHvWocfTtTxSe4Hd1uJC2(mTB08UajljGPEd42fC7cgEIn6c1AHo7mjQc1hQfku)Hai0A1Xihs5nki(hETaXZmh49wYJfOReGhShquHHYBXfaQ)JMZRzb7JXiENKp9LzP6Kcp6WIdljhJzmh51jphf(1JfeGrCoG0)Uny4afFEk5ctnensQ2GZac(xt7rA02H42MREkO6idoOQDnPb)5TduaBA48eaEm47FUWDgjCIqbdhmCKU7kr0OX6aVkmCw3DZdNfRl(irJ0rx8H6oASi8DejsSqyS0QNn3IlsohtdJ653WIRtlUyRkZ7TNwmGStxdBfQJl6wh7e(IT0ob5kvQQ0ODc(TXsRpRV(sUbOhJOLAGmQfMsYmqi3GVZkNM8hqXnV6HBE1d3IQ3rZREhTO6rAE1J0IQhT5v3tXdttcXaNOSAEjdTDxBAgOjVaR41uoQDHF4MIA3LBkQrJG)Xxk6ODRN)Cbdfwm66k70caT)UO5OuvDjmDGWS(sB3jhi(GdNnDIbIN8uX7PNuztnAVnaIoVScluOa0PngkfaLXF96KfagqQWEhEo2jtLcz7L3A(kY66Q6Li3)2ipGU9Ba8kTaOCwreFn4ta2L0Jf3z0I7IKgxumnaLIzzyCm72E2bLeLfE2SS2B8SSmECCAYooolzVoMzrbCa7T5QNK98oyFmCp(HvNrshjulOHNH5u62CrAr8pQTa1UPhi0pL7JHbFEKAWNpe1UIgaorchWbbKqBHAlU(OSz4C0fxBNIYgf0LGEG35FHVysnKtpyWqB8jbeaQF59NNLLzLwBZkjQMkaE0IlJfx26AuRMUdlUCOYqMTdmLc(qQUf3OmkoqwHEQf3zdd8xmw2JVuYbmh4IX6R32tw1I755wPwWVLZ48vOubVHEBHA0MCir48irGNEDBHS4E2TvpbXI75wlKVwO3dgebQ3cmH43IIOJi74y8cyNTJOKVZI0PBy4QLnKa0)Tgcz7rTfO2agi)31UuaPFTj3BXDcktITKpWp)mWR3zS4gdvp8Y73R4Pf3inyzJRGjiids9mzFBAA9Y2qJ3qs1hFl1rF3l82DwlUZz)oETfbTjBEix2eG1i5ATlT1VR0gLtZR0v4RtPlkV)nCjlyipAuBhqTTPQXXFQ8LfNGJ4L4qdf3uU)rJLDYRH4LfxbqKYItmNhIIuBH)HHGKf3eBEcqPU1waI72f5NtUkYpDCBH8dqp621b3q(ACWVrHN(vZCHkPoBWOkxCJj80XT9cpN6wBHNtC7IWZaRIWtKBheEOw01jlGDqhRHr(gLCQm2yLm0ln6GtnZgtYjYT9sodERTKZh72fjNHwfjNO32i54gQ7gg5BuYrDGHNT4CgbtfuCJj5e92EjN0BMsoyiW444yXIZ3jDxIIdipHel8pUHwYTSa8YvCdwuVks6fNZU2puZkfRVtyKGxZ7diWp59sdO0oVtmEmNyfXJHXxTBQvjrR)qx0bGT3aXNfUjKC1I4nbItazBdlraezkpyu6kI1IByGBujPrEXH57Q9(MZn4t3fgllaI4d4N8Ko5aA)Kux6PYd(JRp(CCS)plhMnQljiIR0njXbfMDlUxiRSf7OFRTB3LviUmRXKCvrS0sg4cRLfINCERtFQ6s21H3OSGIj38skIXX191lUxOtCfn7mAJT(lpYJChBzdh4nTDKV2BK9cDRouX4p1Abh2ZSH9GKx7GDeeQvBh3Z0dsnknuy2rCYANOwFS(jRDHkcZYsbeYR1wq2IcJ9C4O88Vn3I0vdoD0GBTHS9b23L2lnm8A74q1LLjh6qRNOYRfS26OCC2IwV(CyzCrPcYvekpUMoCIbn(w1NI(ATFnEc0be66(MFIYQQ6KpAoYlCiYlYPDORrlzfMFOQvYlPtE5pjjnWENVGUQ2401TAKqa)S2oa2242mOu(1sA70L(BZlQ9(x7bMKLB2JNPIQQzjAijRnVo2aW1Y0zkWR987S6i1RSMoi1A70LVX(DWI7NNk0UGpuPtJ9qzLsKh4QoYl2XJLUcI5DIbjZSGfPcA9jRBaCEiiXc0cWi2Mp1qzs1tVlPYwrVfklRvAE7lm8BRTCV(VQ7ajBz1Yuh65ymMLjZxqTcMIYgLOGqQxXGo65KMQ5OtpYN0I7dtFcXOcnb7MD0hgpXkDxwo2z7EOzOtkcaMTKQUmWkq7pZpAV8ztLm(amI)S2e)94xN2HKelDPhLMd92Zm3kmbQL0UgNi5wt7AzMSVHxZaGg63MUifE5xBfw00AJtqkd1uKhGQE128pTeBq(BVrEhfVO8D1SItJAmdAf3RzBwANHTJNfQzgPCNEKtpDIKZoq85IHQqXPn5z8Vo0231DEPNYIZeyzRcAEe3Mf30BXIBgh9mwCZwYIBoWa1lc))NeQ2pfvFHf3h86shHf3hQbLcNCDQuqcvkefR1Z801MrATDJzStKJzlvokBTr3qRIeSPTkARA18G(dA8Xb1hHAM6dlUpYAvTXyRZzVTMIUirB(c06qolqRLTF7h0E2ICIsZz3AiaHyrCz4pUgBR7WzASQHxDL6755S3MvgVco5sSgDGfTxE9iA(oTpPh3T2aNhHdG)tTXMjkQGWRo8D1zxhRZUIWwC9qLs4mvxG4gAS4lF3x2(v0UlHsWl7TBjv6Y2xAVHi4Dw1zYqxcA1IEgO8f7yHT4(hJpS)jqz)tbM(pRf3)mmZy(vS4(vb()pNf3Vg(2fdAEeWLHF9AVowC)ZzVewC)gWF)loPTJ)0CLQ5)Cu6I3FVsT83JnA4537ExXVx9znW1QRvAT31U3vTR5ZXUalUlvZMalUFwOI)COA0w7b8DxVw51G3wTwhUf3lxVoBlUpgfH(JBX9j4CqPFfMwyloqr4cwCVkuR)bU6AT4(fAP6vlUpftX6fS4(0nOmTlAnJvBUfo(steC0j7BSHM50rMXwzQfhOI5x0I71RP50I7xIQ0uS1kn3mh1U1w7Pf3NPjk)0V2k)guyIcZXN8md2Tulv(1Y48Wu(1ONUpCdP6GhhEFOMLfeuxER5ES9cKOo3GTlRVYcgL(7zo7EAmC)vlmqhNyKZYhzG1GZUUMAW9dnlnosdUwg2RRLFVTokMxLFyp15NUvUnUo0774UOf38Rb9(FVTwev2BX9cn6UNf3lAX9rP(W9Ean)wCVKf3pd5Lphk)C6wHbputmb)nV1aqDPAaQNR1ENCwHZkf7KcXIXF6RjGkxtXtx1rGBKGJcBwGJNUEWX)L1ahfAf4iFX065ZwexnZEbh9Bd8TQJvFw3WLUlyGcv0SdAgaJdB4GfOG5bUbmI5iMC5dvBvJvlGkAp5kIxH7slRjXjXR8LSJ8L2JUkpewbOafZ6BxUrwQdelstTbhfgFWMhqf3NTByyq5xh(cN01Dj6cavHUu1BnyIUDnWuUKSJCj0fKfzCptZRjOBohnjmNh(TnNRIGsUWMsk5w0CgWp(5MqEAPC5zNNJem36JD7F1ky3cZudXSce42glrpzgy0U6EWqz8YT9uEWr3jG1gRoFVy(30P98k)6e(A1MxOi0vjVMpV6UBAy)80OLyd3097PMJzZy9dyJwwBIHWm8d7WmRLTvhHdfENLbet955wPSY74kRC)58kVa94d2vqkktByxgLDOYnnbTHnDbDDN1uT(Vgfpzd4Vno9nZKvOZoBFwLZnWWTqkZjNBds(64elqt622cHvBLIB8Sr(qSdSj3QEEYFtp59Rf3VLnlNf3VDlx5(tBX97W4S(IWFxg(73f(7lyNyWW45Lcs(nXDjJ95ABe4tOgBhVOGrTDTIqK)TUBxfK3AdTpvq(3H7ofKFVsKFFGt8lT23mki)bxxBdfK)qp7afK)i00U)9Wn(pKJq2gz7)POzr)XKLBYEkXDJkb)pEVoZEZXxsAWSJyC6SNTWKhM8o88Por)zPy1F5ABGejgO3(YUU2HQwexS7jlRQizK7AS9d9u8Hdgmym(WDfS7o4JeU7yDEDNu7ExIe3qw74p81CTJhFZA)LXI73VHP27VohMP6FNAYEHrUjCk9(Ud7leCkWR8xXoJnREnAT9BrxGJ1MKq6szSTz)(4JOT54OpVUCt5D6u7YwzfctxmwjPt2ZKrlBVKmtdSt12JAEFK3zX(tZNAS0dLn(aeFV5o02ht(lzp422kUDaluwwbCLPQrjTh0Z9suwquc8CPQU(Co5go9gjvllc3vvvSUIZqxMNgMsAoZoiT4H1La1t0qn54eLt5vKeLzbHYXjk6DSxQToBZW0Ygva3QE1EpEFnkRkmva1jC(HVQN7HRDK6AFgnDC72zhEk6eQvlkvxjjGbcX6kHTj9SlpL0JmUTAuWSU34mMSzycbXq567)j3kvuKj53eV0wliyiyIle2Ae)Q01f(fkoVs8lqu)ltbNraCea74lvQD1UAFy5PKkMhXYOq2oGz3JhWS3I6i47htBmhiDg(1BZHRATwGD5S334z9zFf2o1HZEWH9I1o6NVPlw7R2aB9AArBJ7pn2Bq15UwRE7R1(V1QJbTw2KaWUMlAKna0E8FDTTwLginVrPMTqVT4(p5SGTSHvsp7uj7m5zNySGt6zLEZGvo65xF0olUVLn9QZOnLEDzVqnRjILf33(wbIe0FUzsKENgisNPsXPIQh6WNORU3ejsXeAkrArxy)BNirqV5Mjj6l3ajA0ODpxHsjNuEItSjsI(4FPMtICvbF7ejc6n3mjrwnqImtLyuZ(pPmVz1ntPi5MsIwYJ5q3wjgjFtLg9FUbA0z7vTGPYj1kBSzQokwXMsJwUottVTIkv8Mkv6pPbQKmF5lip9fvdL5mBIuPwSJ8yX9EUfH0Sw9P8gpb5R0ab5cjLoB7vsA0V6MibzRMnLEKN5I2gIMCDSJf32yB4GgSmBV6pB6HXyPqEH9SzgaHB8e7VAJwdQl1DWQtwQh9ZTjk9n3FBtP2A7Or3VFxHXgOp)PnqFgovSdhBYXshvsAZJ(iQ0uYtcmaiVlfPbkYxRbks3HfNYCg((lLCtuIX8FtZHhzrG6Mo84j2WWJwC)n32Hj(N1Om3j7Ak9SHN0COP2evaQ28nKsAafVPtG79hPiWF9giWtWxmDMcNA2mtn3Mhb(BoFZjW04d)UOQnqs(ZB0xTkNPNH7xCObYUjkZ1InbwlUD)U0JgOhxPb6rQijUWidCQPpZW538OhV9unLEmVZ0JCZgg8GjI(Ju4GFJgiYH1Zgj8eNsONzQ0AIm(axZu4xS5A50TNRlVe497NLGQRxXoGyUccmq0bcSmLgBl2budy8VEccsLqkYenMBvF1sT6ZkWrpVZUE8gA6XS3dXQB3YLnNE1ikFtGqKXSdHbmlLumsy7PP1w0cOxaHzVuQgBoWEJsxki5Ds0t6ZmeX3KEYzuWqrCJ6cVH2JwlBjKlxgD3YSKuG(u1neMssHvL94z1vwzoNM7(8OFWqgiDYtLEKSUF7whCo63weOi3eYattj7VxL05YC7V42j3)xO5zKHN9nxV76EhX7UU3(AlO7EOxTuhGLDgrddoE7nbnAEIySbeDAzIyqUpCgzD3qcP5tvKwKtgBR(CY497Jo9N1Leg)ELQTXeUTvzJj8dXYN7eYMsvOJs)D4(P(d1KVNaPGA0ooYXgdNhBb9RrWR(TPsM0pvcofw)EtO1w2rTNT1w2P7dXAlTDpV6FjT5wBzxRJgL6xDJ0O)rn2iY5clOmxJ5msU6adazDMCFJy9ikbcr4QdULByHX34ByHRyBjSjBuHROK94G)(gL8STdATL7PL77GMOGzOvUVdMd33bxlmsnbQgg8)b3Zb(jAeQ(UOXOz3ndZOgW9wY5SFQFn2cZVHqRwR7vPyN7MavBBTKQnJQ5erICDs1MgEpEcD7VD07Jps4WDhg3nrdSuTVJf43N2Vr4qHdI7BU0VBibWDP3azQwOGeU2tT3VEV2BY83uLM2lsxUXqt83sAIevuQf0KGlAOjOpf9ZZ0EUm9C2cr)SC0mmK99eMwET1aN2oR7ACXMbwr2ufDFFRT8qJLiuSo7epedp0fEOB(o6coL8Ol6z3E2ZNRgRTSp7VAj0fzp97LXIUNZs7hNCrb)MR65RylvFjzxZNxq3ZcARwg19CL82nphOo9P2l5alHRkzOfJd)TjKIDlXIwolxeDs2UPboiNpwTS1Kxy4xRf8up8gFhk(k0(NNfcOaUehiVsjCDgyVcEIHYHSLQGUDx3HFPSAHPunrz1fOJSgY4Z4pGnQ5SOfpS7Iwef8KvkMqq)zhj1rDV6OzWgW4VC)ulVe96(PFMDFAlUZWNSSKGcYt)j54P3JTujSRNSOOKc)q9oAV82RXcYR(fVhkh)9ABLiU(yEnlU322oJnQLqRz4P3XI7pILtOJ(5seoy3rWpa2bHZIr)M02nYLhd53JflrxDgg)mMgURO0JDsz7JCf8tbLSI0Ws6uoB8ZGkfFtJvas1MxyIjKkykjI2lSF6xQmNKoDv)ciU6jxQRKqu2hqdMZH303)TtDZhXmv9B5XwBz7TeXSYCjtcsa1JyUVAjpp5FOD6Y)ATf2Dh((xADQL7Z69JGB9Ba34xLUX4d1r4qDHhdhMESd6Xi0V(TDV()my2qgg3ru2XvJl4wYpiMx)8uBUwhTc(Q7BvSocCzm0AHVQJvWx120B9d())d
```
