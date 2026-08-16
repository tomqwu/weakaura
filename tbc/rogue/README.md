# Rogue — All Specs HUD (v50)

Import `all-specs.txt` whole. Layout groups (drag each in /wa): Buffs, Alerts, Resources
(combo pips + the three globes), Procs, Cooldowns, PvP. The globes are their own
sub-groups — `Rogue - Player Globes` (life and energy) and `Rogue - Target Globe` — so each
can be dragged, or disabled, on its own.

**v50 — the globes flank your character, and the glass catches light.** Two changes, both
shared verbatim by every class pack in this repo.

**They moved off the band.** v49 parked all three globes in a row at `y = -262`, and a
horizontal strip of widgets under the HUD reads as *another action bar* — your eye files it
with the screen furniture and stops going there. Diablo's globes were never a strip: they
**flank the character**, and that is what makes them feel like part of you rather than part
of the interface. So life and energy move up and out to either side of you, and your target's
globe moves onto the centreline above you.

| | Where it sits now | Size |
|---|---|---|
| **Life** | `x = -270`, `y = 40` — left of your character | 72px (rim 76) |
| **Energy** | `x = +270`, `y = 40` — right of your character | 72px (rim 76) |
| **Target** | `x = 0`, `y = 110` — above your character | 44px (rim 48) |

Those exact numbers are the tightest arrangement that collides with nothing else in the HUD.
`x = ±170` runs a 76px rim through the Alerts column at `x = -150` and the PvP column at
`x = +150`; `x = ±210` pushes the right-hand globe into the PvP layer at `(200, -44)`, whose
kick-lockout bar is 140 wide and so reaches `x = 270`. `190` is the band left in between.
Nothing else moved and nothing resized: same 72px vessels, same 44px target, same rims.

**The fill stopped being flat.** Each globe now carries a **specular highlight** — one soft
white ellipse, 46% × 34% of the globe, offset up and to the left by 17%/21% — which is what
the eye reads as *a curved glass surface catching the light*. Before it, the fill was a single
flat colour and the globe read as a sticker: a coloured disc printed on the screen rather than
liquid sitting in a vessel. The highlight is scaled from each globe's own width, so the 44px
target globe gets the same shine, not a shrunken copy of someone else's.

The highlight blends with **ADD**, and that is load-bearing rather than a taste call. Your
percentage sits *inside* the glass, and overlays draw over it: a 28% white sheet on the normal
blend mode would wash the number toward grey and cost exactly the readability that putting it
inside the vessel bought. ADD only ever brightens, so the text stays white and crisp. It is
also why this is a highlight and not the more obvious dark vignette around the rim — a
vignette has to darken, and it would dim the number.

**Nothing to delete after updating.** No aura is added, removed or retyped: the highlight is a
*subregion* of an existing globe, appended after everything already on it, so all 62 UIDs are
untouched and the re-import is a clean **Update**. Every trigger, load gate, condition, colour
and spell id in the pack is byte-identical to v49, and so is everything outside the globes.

**v49 — the orbs become Diablo globes.** The rings are gone. Your health and your energy
became two 72px **vessels that fill bottom-to-top like liquid**, with your target's health as
a smaller 44px globe — at the time all three sat on one band at `y = -262`, which is the part
v50 replaced.

| | Globe | What it shows |
|---|---|---|
| **Life** | left, 72px, D2 red | Your health. Brightens to a hot red under 30% — the tier below the Evasion prompt. |
| **Energy** | right, 72px, yellow | Your energy, with the **35 and 40 marks** still on it (below). The number is your actual energy, not a percentage, because 35 and 40 are absolute. |
| **Target** | above you, 44px, D2 red | Your target's health, red under 20%: stop building, spend what you have. It vanishes completely with no target. |

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
embedded in the script, then replays `patch-v42.lua` through `patch-v50.lua` in order. Every
step decodes, edits and re-encodes through the shared toolkit, and the final build asserts
historical UID continuity before writing. Re-importing therefore offers **Update**.

**Closed in v47 — the threat display used to load in an arena.** Every other pack gates its
threat readout to "in a party or raid, and everywhere except an arena", because an arena has
no threat table. The rogue pair carried no such gate through v46; it was largely self-hiding
(the trigger produces no state without a hostile target you are on the threat table of), so
in practice it stayed blank rather than lying. The threat ring and its 80% halo now carry
the same gate as every other pack.

Keybind labels currently baked: Sprint=G, Vanish=Z, Gouge=E, Distract=B5.

## Import string (v50)

```
!WA:2!T33E0XX519PHG0ICPEqcjrlszjTIuKHuvcE3f7IfGY0v7UaGybXJLZUa8HKmMz3DwmdWU7mCMzXdgzNyejfyllxzyffR2MwBKM0tFL2d(d1eNx1S(O6OMJ9xqtKg7yN4aPKMEs6PomnPXnnN2797BMDM9baxcbqtvP)adM9BMV5X9(7(7E)UFpgUXBp3x(ul(GRMvm3051v1sOwuvFW2ARTuTfOJiATNtTSPUAXIs5tiRumVUu5lQDaE1jRi5)X8NUOsoj)ILZ7VxyNR6umFfnZk6sA3Jtb9kjMV48(tPQyOw2T4(vGAEojXPllzyO1UtXdivsvxxwCsP1YQQNxspU9ZM2(Ixu5YxwupV)mQQfnv04nYjwuQTvfRykRQpQMPIAzdFzzvtwF(rluWqY824wwxAs4qzMxtIFsD1kAlZoL0kxwAxXlQkMV)SMWvQS5b4lvbUY(IBOjL7aK7YhFUIIgg4EXnGZg3zfwLzIkooU2wrSCo4(dVFLnZMOVrY0hV(CS7nNUyo6tvx8gMI6M(IRuwX0x2cW)mK9TGPUYKtkPBCOJPBV7ZhVcCgz1kkop8QBIpYIv0fdTa8evSyY8g(wZOswPzGh20vkuqzUvMirS0zMiDMy8zQEOu6sWH4tNQVHgA58szHZeF71hOVHs1)ydXtpPSdijw0uMVSyjjdFlvPS9JGVLelRuseFU7I8r6NCK4LvllDfjrdP0Maeyst5BD18WdfEgtGpI6gsasjVXc45G3isW4Levkd1LeKe6wjDsctIa7(a1xYvbzMKEzXIJdxe4Y9KlBQMBg2(7o19SKHuXcubl5Ghwj)QoGK4WlKrOkk5xrts78bZF2892zNRuqhEtGhrrtX2UktP0pwe(eLnDc((6BKSAIWBGPdkmt8eWvlwXI(tdkCdBvBYYGQRTSWRubLj9Tmiu5PaidFxHDcmL7EwgFPvyOUvukxqvNj18zJV6l)KsA7p9LQa3t)9xbUlNtwXuAXJSScuZ0Qv0Zj9rUfYE9rUDoY9so4Q5aCDE1zlNEwfnjHR48t86ihhRJa5bh5ye))IGu8HjhJ8JrEuYJrEiYHjh1h54KtCfeQqbkk5nEK4rcgny8UIgnmPdFxTIHuFZbOX0mCKa5ri)9iFuFRKxXyQkLbu6msHelwuB)I09ZWWcdRMx6F9TqI(KxDAjjTyOzHjp(skt6HCqaAziAIibjzsVN8nxDYIQZ2VU0LQivo38P2zGocfHCeDqaIh4kWJWPH)tTCKxalc1mRMTIPPA5rbToa6xglEiki7Ewb3)c2wslnPtvr(P2Oh78EpwAgza9YkRKJsR0wC8NY0JpKcuY(Px)4mgIfVlT2nLMZCcdzX8EUA0YWnh(OaRJNZW1MFnwPoOZ4XglZOA3fTqGnsfXb5oNsEt54XGFEv6balsP80c)0RYqNoVBxHE8PQyyQuyEqSQRAcI0mqHXhz0r6JjcXZzz6jMRQuG9OwayP12x)6kx2)zRiMhX)(ZKPM3nN70Q0YMfE)pNUO2cNZENvREDO0eJowMHsosF2V7EO3UsYrgPp(jIpAMmJoSBLqI073(D6818onJIHs2IscfwLzsmHk7O2wAtGKQTzBvz)ErfV2L4uDNtxcSeijjhzjqEWkkRSKYKYMNLS)XxcWxtq5RfiTJm1K7MU9EowwdLYtwuINF0tpwFK76aKffihGES7GmS2D7yNHc8EvmeH7yEHfCkvGxSOMSyBKNGCY4xwvTe6BStYHE0Ds6gOOaAjsBKauMsGxdP3Cy76QHsEGgk5uTr(4K)(8UQuscF6kLrkqWM6Xxz2lMlyXKrVCH4ZYplIDolP)dDm(CYs5MUFI)2wygrDf8jEnP50uyCYzukjXpJyXksTh5WQAh(JDk9CYILNuc8ZqEzHf0aVPs6MZJmBDeSd0IGCAFK7dEh8rUFFKhW3IhHmOxMjYzeidjtg2M)51O8pNvqhepJwU48cmEiWjQ(KsMizeYnbesaXdzKlhpypH7mE3D1zpWMWb4dgmu0oPBdt3gHpuxD3vuYJOpqm(Hb)taVeHNKMKHs9qgJs2qgNYXqoNdVc58KlitUi5jjp19qEAoYNGj)MGJi0gb0xzLj52pjpyMtK4ifaJzYKu0frMOqMImnP4NMuIJugU2Qen4cEjIToWGysQWrMHmlzoY8Klt(XjpZ9t(KCKpLqbYpbh5NSnYNMDPwqG8tHisYZsEoeesE(6bFKFAYI1J5iFgbYNvG8cuqf5ZzJOkYvfrTZ3TikYl6GMiFEehnT4f4vG4SmMAaYlbyiFBono5lzRRjVAJQ5qDhSBCtpGwTZiDs3gMpuKod3dOH7PRU5dfny3GEM8vwFn8GVB0WgBEn8bjpZdX0WBr4Lp82oE5XQcx21wnCz08zcp8mH7TI6L2mWL1lafYixKVZGH6mmDBe62UOBJs32nIKoRtSjVFKd45QQt)qB1605YNORteueI2n(wHo9vRQthKpyxrcgKpy0odhLUTBkJE4QAZpWEFRfBCRB1yJJh6mxs5IdAmtXzBo2iWsI65yXL)ShGSJlRDxvtdq5E9pCY0PtoYPDZbGIMQHPu12R1Vee8OBMd6BgrSbE(tPRwsdcD1P8ej8p6i(hUp3sotYeNX)iJEo30gaTZ909LXFYHhEmiY4Dt2d43CpKB)RTWK6k5XOxpmFVlxaASvcf9CqOJ8gAI5KUDVVmKheIdY)Zt5LqmThhziXdcVbGl02iiQSkLkNgVaTHWwMqVU20211UvUqeKktcWiDdtrSvvCKE9r2F)1ceOBziaUQPGrN1uCjbspzzrDt812cqCx2pu3MmzaaEDhxj)8qZ4vYrtVbzF7kUHQUj8m8HPOq(IkLum3lAuhhoJzp8yPwdAnj80u2SFO9EQ6z5J1BYXsdib9tm1GYHNYqB(oj9TNfOnfb0vvdnznhfrSIqmKglHIDAJA2Rd06jiXiXPqR96lRUyELkgp7TXGulaHOpe(SiV4dtgKdo1V1ghVXQWlpeRRrAz1zhT8Qg0)nmeideqVxFlEde5riJssTXUqEK6iDeixKpf08SIUep4HdgHT1lfKaJcAJnZlu1mFzAJsulLv0uyJn5rWvbYrYQPlbTqIerhtMYOvmPGOq36cozCjeYf8wRyaTXxkRk005snZUFX9LLMDS5ryu4vnbGKrrSrLGfI2(nGFJnBkJtXlrpzAZXDogT90WfZcEMYbnnfUp4v)f4yx45Ox42Np)EAFooAtVOflSeT1s4vAbNRe5B3oAnSkEsvFqeO1HEYaxNmMhcmPxjbCP2pwsmRqfae(tH)24PeZQuuXC(j0rS3egyIhZd)rHBhIZHGeinDii)3di5C57z(UJLP4zL0qMuGwRgspWphayBKPB9bM)saW8vGgFYuNfvNKCm9jqQV(6fEfJqE0LtqpI)HGdDC(0NdOexiVKH5yLvmjhgZ)XeLaSlkCeO)Y5Gcl4uoFQy88xaqUS7f5pdG2)5SRo5)ofI))aq8)abYFHa5QK)s2jU4(5b5AUPJJ5EqB)4vEsPYs6k5y2ncRwZpxHzgXljMFE0aAjAkJgrSK0UJ(VICeE6pzE61oyc7MbJK1tcqtd)hNMcPtODx49rcZP0evVacRcW2IPD(PUJJak(O6jHwSO9zh0aiwYgxKBAbT2X9bUsvDjvOnWa3cC2uZ4)iT2zOq7mtbYyLCADuGM7k1Yh38e(1LmROx2)XnFYGpTFvD)MpzON(e0euB(KD(0(LkNVfIMeOci)E1sd0DieFfSjSa3idRCgGtzTQYXPlJPMW2dsnmkusMLDpjuN2ald5TOw2mQfY3M8DGc(9Bopc57sT0jFpYFa5pK89zmcK)iBYaYAE5biVTa5Di)X2g8K)ebY)vAGm)PANy9mPNve0YQ6tKtwSyrmjfRVr9Vmyuxk2WNEWXoEWbgzUTgJ6pby)86Wl0dHaEgfLmGHn1Ybe2pQ2(Yq)L)0kMvO0VaODn3ZIA8Uu1AC4ObaSTw7vlycmtlIGd2d)XpfI1x2TAqa0mFuudyY)tYFf5VwG8)I83q9P9dFNldpu)VTJ3(VL8)rG83XtdJI8)To7hlUBrWIJt46YDx9y8Wrwpm(1gvAXTZ1hjAXTl4v5h9aWJSX(ukqfTRl07xbGENrES5Ioy5J3RXf3oGEaqjNuztzANYC4ibQgEds6FuAOttG9nKaO2zC81udbTduZVRI8A)JTH4SDF3)Cna00TdqFlhQrLR4MOTDDJ0EEhK2BU(TGcaB47ZpArBYaARHiyO8X2jJ3(FaZx(1hX9vbe3ubkOu0i657wC(RhexZBhp7mEa6jrJX(yi9wcO5a59NOA)8sHJnODRvmcVQO4dfJOubeJ4)SBYtDIrueIIhhXit(HsY3wWrkIIq8kGI8QIXw03CnHOdajgIABX5mcebaATOtaU6eWp1cf7qd51LmKImpwiTz0e4XoIec9frPdtrnGg2w9cWaqd7Ge(vDqhvBF13cWg8tMAMu5YbTgscXca2aGr9)Dog5lGDlazPvS77EA3X(YXtNzSrW(c4uNI8ZG9cq9sVx5QUDgaTBUQEHS4UFYlVkw)jgUVedeBKKj2WlKf3dwBD5tGP1)6Ro6PgfcRoD6RVAfV)(IXxtvOCnuPxBnRcRIvO5VwxJAQNy0r6FS091qDcJpE9q9M28Nr(rhntd1QkPytUtPtouFJKOVgffDtVlHAwLYMkwIK9FHRR6SkRoBMBN2(sNyGrhDOjsIJ(b(XsL567PT3KPBkejmvzhWwqI8CGFM1XJAn8BLb(T(T4AxGYN9OXtiAysZzj1n4R56XB1y0Mp4FmA3(HE)C95XsOa1F3pmFz3Q(q0WeLHg2qJGqWUPs3ngvN)eYI4G(aATfC4CgEsuk9XPdFlvTI6S9KAEUkU5LZTQMC7IY9GTcLRt8awChuEJcia0CuwxlUdb)8(ymUy4kuh1FK6DuhZoSWZOKBApuYn6G(xZHeEA4mhzwh2zGfUQ35xI2zTuO(UilDf2q4PmpTvoVmNx4Ua5viJJ47HfAf33Fc7Sd8WKr(xgQRWHIhmqOaHc3t3XJejAN4Vcb71tp8WEr7MpCKWD2nFWEIenmFNHdhnO303Fwg(TdFUHjsb5wCDyJST4(OncJT4cyXf89Aq3BIcxWdUD9cuOgi7ghKWV(6hKGsPsvk7nibFoePpONmnt2XB4MGEmpwQ(tRMBAjt)bDt(oRC6qbbkU5NEOMF6HwNtVZMF6DUoNE4MF6HxNtpsZpDpfNIos78F6IQzLm0U7QDZaDOmWkM2ld(AdnjVnzYTFjqDCNK9TRnkd(S8UtnFbj(MOVh2091aAcIGcubdadT9xTpzKmOJ4mdaxez8E0ZEHabdLpsJzTVxFK(2JnkzasYf9Jxk6qyQIUeoAHWbfM2DNyOydNkZOXhkwIZeR3EtMj5491sDWvw2WBsgaYuJXo9STlM)fYHkUZSLu01v1bb(Ei3HU9ThSZxc8txop(mWhhIuP3nFxHH2hj0qKsGab12FEfJC6sMst42NhEuCwC8AXCDwelF(rbVf44xngoO7EQHLYRi(uzypMgpfBu)nbDa)nbB8M1H5KIKxkgQGaRyBdxlUNGIsS1cFtQ3dk)(R5KzaYJYNsDwjDAQA1W9WXC5EC4VrQ42fOHKu9GcUC5VI7LHXJF4ARy9m4pHf3qKN7(964AbLYSeBB7X6L5yoTy8gVc5fqKYE9bafSYwCJyXnkwKNlHf3twNhp3k)IdYcNGrD3gQ7T4oltVdsD4kBXLoeaXGFyXDoua9n5A0F4FIZl6AuXG3mVTuvHJakfopkf4P)U9GwCxOorPf3fBf5NTFW6LFOwe0WNYJgogvdJnGpMf34CaUlXqMdD5O933jsuHcFFDQZo0P33n1odIgaVakn6mc5DwM2fjPQu0qIcCxZ(eqpLVTGt6mapGTc3a4L85UFlUuY1yOUoUFy(iOw)260wX6ME13il7p2oQr7oUmODT4YS1yghIkGR1SfXmnA2f)AB2zJu20iKw3cdmp22STaXEKi2nk1o2N61bulmlUNQfnWS4EAWOYI7ti4rgnr7HUbykLObtP8JmsmtLbgpAMPUwMswCI))hMqCBJwqD2Ywq9((fliy)ECB3BW2QxbS1y(05naZN(AW8za10xQuYZhis5l)(gZNtVnA(eULnF6)9jMp0466ILiVUBREP)wJTt4Ba2oNUbBNsx8IYg6YJp80Z((gBNxCB02jslB7mW7NSDCtcEDs)TgBNi3aSDs2GTJ6qPMBY5ncKmq(BwTDWSJXXXXYa5og0DkQoKsbjwMHCZ6KBz(5vk5MhP(klPp582N992SsXZNnow5OJLtmft)qQ8AF7cblFyAairQDt3y(O6BV1QTzzwcuiRtILqn3hLLYqubLW3M2SLQuheZxKt2JqZIhFLYjmYMpfF3NO)5PPyVxe(JPsA)9Bly9MQS2T7M(7CXtMfAHU(eZZX()CC4fCWveZJZjoP8dlo3oC)Hs5DyNACT72DciIttyC0VwoV8kg4K(KLjgbV8j8gfflBYTGu58XWje2ZEaqoSMM9aBJnHmFKpYTSJnDY30P3aP8YEFY6xvxY(jlBoDvTjMJAvheTwRMj)hQUzlHJTLJ(B9TeB8mRAjsvbpYIhGMyBT9D0AgGih9Oxp55wlq1zf5eSj6ATd)KjYlLtPKyXj00HDmOzpR2XBV2jUgxbQiIoFI5luuvvN8PeipZrjFsoTJEnQjRWSJuPuwj9fVRvTtw4W2jq8qNFxbd1rOWmYZu7kyKocgAzCYBoHgBUf7KDtENm)TMDbJ7mbeztUXjkHPDKvPJSS9KYeNS773ENEDNqSoxcBGO2J36jpKn01NiDjvvtzwAdh4jEI)bp1X)RUYlDf7lR7u1htBgYhCf7Nr73jYZLAxHc3r4UrwVv9(ckjZMzNWVJ7KlvWnc55(cKd9NVVwBsk84RKOupfvIE(EgzwjT9bMTXSTpPMRYA7pBvds73llUp7vlu1wG98Jp8rdr9V1dBBBltNP8u7toYl9fagguVv)TqPSm5oUQJPR9BZAgujMZivvGfCYsuJs8LmBYrsNS3(wiNAjCuwBiVm9q9ROBykVIkBgiNROIM8vDF6DFqdeXZ2O2reHoHr)6lyxDdFUU9MIoHSRcQqhGazjJeyEBsaANfQTFxbJR0AfvDfaKtR8cJ3hFMKjIneP)t2krE4Pd23pCoT)XiV8H7mGNrCavChmeBlT)1xQADwQeObzJdn60hL8YTBxvo7OA02NRaYEc)U4dzh4yxHSZ5e64SnNEXSM(azdz9Shh)TaRxnNP3(GCt35jqycFt6SZ45E1woybM(NsUCh0qXqqh2DbX3Kw8E7VGtTlYl9QUiQPPogTbsi25Xx5SJD2zINyUHInFuQ5ls6V3wogZt7ddiBXtAXPYzXPXC8AXDPDyXP74M1IZaIZ3uO2qZRaN)mupOwCZ(UYRPf3CW1FE4VlxNNXMgp)TwR6Vfcw9A5ICQRZ((TQ9t4inFMLDuNzwMf3NwgOMzEEo)odcugwClGI0Fkq89Sad1ZzX98KJyX9tBXTiib(mANCZ1jtm3eP(qD1DhD1n4Q7ZtbHVqTD7nZW0I7ZHUhUveHBX9IGdsU6FsBlAhHUgpOwC)ZX7xu4kgoI79ZU1(0bovlF7AqWiVU3Vn89Rn771EVoE1K3uVABWDQPHBCnfMFwp(4PVxE8SBFV84phVJ0hmMx73PL9AxiW4t1)fhz2ZgEwlUxcUgFb4wdC)dANGt0FSRW8l6XdSf3ltj4(zS4EfbhsUFwlUVKf3Rch8Fi83)i4V)XxBxLwC)CECsw0I7FIJRrlU)PEDlAX9LPpDFflULj9p41PFVjWZ5JFk0XxKQJYgT7ghNJH7O247AATchOUAfz9Q1cG)sA3jw1DzWADxAX9p762)4wj33n3okT4(fQ3pxPg9ZnSyHCZZN4Cd3JefW3u)CBqIyO(5QVn9hSUX7HNM2FVnBOGqBCF1ebyp3qQPb)2L1Frrd56Bw)dFBVxOD9NPX21pqLCd15Ph788Hh66RD9EdR4m3uewXinj0Zx96Oz0wC)4Tqmc)GD(4yGbwCpt9nd2I7tAX9POTT9(GOeS4(jS4(jR65yNrPe8uhh7ShQtKwXVr4tP9Z)w((4RRFJGH7ONUQ3VXfqOzl6248INxk6GIrJYF2gDBuxd4yUnUW2SBJ)nTQBJhPznfkKn3(pyNJvBtFS4(5xV28C9sIVHiTTtgzXTmgzrx59Ve1eUggz(jhvpBMjXPqocLCiK95q26iRcXO2yboTUIQFr38uF7GCcDU5JouSrPg4qBpnZ0ClqGDiBd7RC0QZAVQPgt7rBiZtUtTVMKXlVmckomcAp0gCryfaua2TTW1EInCnIgUzTWOjzeZ9s6MhnKOXzDPOkSah30RqNMTLPRwaEgiQ62fHJ9uYDkexxujVW6bEMHxtuhh97bfYAoRuzy3qMsLfwM9JckZijSa8WzoFjXYcSHYAlJ2(32iA7IX7n9qJ3DpdhmTx02j9y6U3QXUfnq1PraG66YUF7FfYlw9S5fNeExDIxOTniZiEQ0kmPmDT1A9PjaOVF73qwhV982d3xlUF5nAIs(Ryl3T4(QmM3zS4(vTLC)MWF)6WF)gWF)AOmNQm3RTTZB6A7SBbV2pOmP7ausNBdLmOTeAgrTNQ1wI51HzC(Im5wq2gknmRRMwhRnNb7nT03c7WgCqCJhUrZUhFLzZi2vxNyUYxyOuU9yLBh(9lGiH66WV)DOkhWiuY(XPD4N9mo85eThQQiGzXaKxdxEsoKB8yqJN1yl1i5myXJ99i3EqYVXH57L8Bkq(pSNn1OZ9R9UA9aHCf4z))yRVkGq(6cKEIpuF9Nbdp81Dx2pi)NWGj)gvxOpi)w0f5dYBWZN80dKH8FM8BdYBPHZmMXzZC(CtDCCK9(nRUwEuD9zHjDinDj8G874S6Dqwv(ATmHTmU0cKOOAzjdH1DnG6K8Hceiqu(qDhONo5dhQNODTzw3NUgZmLTLzQ)bVMZu)yBMf5hlUVr1v5hoxu)xVUUg1EoOs7r03waNZeb7G1FORX2f7t0qiGH1RO1hUF9xP2NNR95(lOtKc60yne2aKQtPIMVsbjoZKrLLgS3PIue7y(gN9PFuMj4xEFAhIbVs0lUAXGlEWIfvkdnHQIHS2h2ZXIxumVe0IPk66Z7mW8PhiHAX8WrvvZxtXPPtFwdtjnN(FLwCkDjWJenB5onEZP8ss5vy5r3PXB0JypnNDgJ80YgxexAE1UpVpgfvfN2VAbNB8v9CmCAcvt9tRPJR1r7ZtrNwTYKs1usCqqKVMsyRqs3LNs6vbx)uYzwZtCAtAA5PezOr4JUtQvOxISAA04niISwKfJgWfWGTQCDmyaTfYYytIbMaa5dYDLGoveE9QocCNndolljEzTOC6p(kYNqT7tKszAPjZsEJLhyu(KxC0rYeBikRgYv6obyEykBgy(99BoFMN5l)ASfnfN7R9KNpYR1WKN)Q1b1BLjrpUkbzVOwlSrZM(wzXrBJ5MAL1Rb8TYLLcGhal1MEa(u7eC3RV2Q0CeCbhCUPt0vIZx4IbMInorw)P6(Nr(6rVzX9226QUI0GU6kEPEAffLf3F8ndki4v5gPc63buqNR0Kthrp4XpD39SDPGIk2GcAzxxaVhs9aVi3ivpRcQNXJ0Z85KtmLsHtVDPE(8VrJQhxxXVhs9aVi3ivp)xa1JzY4JBoWGk8Mv22SEuAq9SINqIEVK5JYnu9ZVlMFZ(uZzwEqTIgBBUFIozd6NvRj003lPHM8gQg63d0qk8fVKYmxwny6ZTDPHAYkHKf39CZHAPvBt52VY4nbLXLsiD(tukHXaQBxkJDA2GUilRPzBg9X7ILm62V4MoHbRY(AjKz0u0u38m3ZwzYd2(v0Vfg1NUupbQmLCV6xy7YQB()Mg00A7R(MC)bgH1QBSaDtQKrpE0PU4OrKK2M0n5l3GQjoDDr5d0g1On(2G2ONq5N2Cw(bKtSDzPy(vBKsKLTPB0uINEttjAX9x(EoEWVdARny3tRNj0uMJm92Ldp1gxVpPjo8gTYTV3xPC)9XXeh)KJMo3zMl90ZVnPCFNfAu5sZb8hWKwR647ITfR056n1a5hzOmBx2AnzT11I7o(aDrT6IVhOlsgo(LgBOZmZ5sLDBsx87oDd6IfC66JBWuFhoEK3xX99hak4q6zchQWze7D2sTScgUSTI6fuz)WNTrVA6o9HLRY1Evo(6E1fguKnOCbfUavZ6SUUvavfOWVw1bOIqTrH61gVP862DTYOuyt3vzNIUaIvJ(G1vDv1h)HOq)fQoWl)(G6jTzNIdzkNiF4qO6Ww3W631pRaI9xma5nI37ONBeYoMYZOqfclex)ZWdO9qvhlekflInQYuwYF)Q6gItlvMDk3JNzMAP5DQU71J(DyzOrtCMrhlJBNWn880pzlqrUd3cCWhz)TETAVu(1ChUf3EJRdX2lKHhQ9aEhLa1VSewfr4Thl3e2fEg6f1pelwvUfhEfyhCJDpz82QD8uSs1XtXmPQB0uyVw8rhEvHr98HE2BZZiRONqzgnvRSYp(PyJm84kMsLOcO)ACvQ)EBYxPHKWzqhJH2FBqPd5lOm2xGb0cDbNFU7V4FAnl(Jw74oQETT2XD6ErS2X(yv1Ah7F3FX)BBIkL8FXMPsFLQGGqILNVUvAYgwpjBYkmzdLmUqnSjaFbJ4OEhfindWKG0m2SjR766ySn)66OG311rzpRRJw7yx1VWoATJ96GMmrZ0G0v2Xy1UYo2Ilb4nnHmpWt4LZMsi)3PD3nJ7OjRvU3IasY30ve0BI0tT6AhlklUU1yFOnqJnRQzHWHFxOXMbEVEuD7pg0hIpCOq9echqXRu9ldc(T99BhkyOa4ssm9lXIFC1p2F6k5YjHZDwCPD9(2kvrY)OZu6aTQs5w3aLIe1oQzkLalBOjQpn97B19yhClup7pxZ0JvD29QT)A(noFJjk4aB3E(Me11B3FM1ooWfJhmAxDHBIIB6g30dFNDd7so2YUlK2E)2)yTJ71(tadDPkG(Xhzz39ztdeNHuc(9I2ZNkyuldVslKv0(txETdyUXLVc9XNnzEVa4G8KhGCKvW5VmuJjG)2cgbDRWsioBSj6mw6qe9Z685bMnf2db3UMdmo4MFDFEn67N3j8ootg28bsmSmdC4(nPMnvh0TLzOT8H4wIQgmuWB4Rt(C4ixDfA1gG(Dl(uwC88jkkjwMIs3ntj4SKbCC3PckAcRuEY4I6p1yjFm3F9yPPGoA1KPWD7lVs(8sL5hPVX7JN8sF9D7G7bdeBuFr1CtRAcOEVk(ZZrN2eRvZ46Js)0QeuVPf3VLG9stD8qb6jm(fipaSxu6h(3Eq0Eue3hnA8U7ke(TInu3rOB7Ic)dVIMKocNrT0cIfkiLZeiT(scuER1Wp(wkLLsXohbVJSTZAVA08v2Ij324bEQRzuegpxw5FKSKONClGZuOgoZ9SbCMLMprck6H8sjPCMhQ6GKN8fjVC7HShE8vxDZ)zVoD05(5gf18E(AJEr(GDgky342qHOB7KUnm9RlCpBBOGbV2d)4oJW2UrWGBk)KL(UhuDnIqQwGLVnmcjObKbxFGvNRhWQ9sTNV98l(a1SMMpf5KKVfDT36BanOgVn2TjfNoM)272z6yIT2ZUjEBWqzDtUsE7J2krmfgB2ChGlW7XqjOT86XxPtJz6Q4Lso6jcDcSvO0P(j0KwaMZiUVdYD2UbFNDePJaTpZo)K))(
```
