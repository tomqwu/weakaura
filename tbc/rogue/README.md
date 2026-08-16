# Rogue — All Specs HUD (v51)

Import `all-specs.txt` whole. Layout groups (drag each in /wa): Buffs, Alerts, Resources
(combo pips + the two ring clusters), Procs, Cooldowns, PvP. The clusters are their own
sub-groups — `Rogue - Player Cluster` and `Rogue - Target Cluster` — so each can be dragged,
or disabled, on its own.

**v51 — the globes go back to being rings, and your face is back in the middle.** Held up
against the older ring-and-portrait build, the rings won: two concentric arcs around a live
3D portrait read as *a unit* — you, and your target — where two filled discs read as two
gauges bolted to the screen. So both units are drawn as rings again, at the geometry every
pack in this repo now shares.

| | player cluster, `(-270, 40)` | target cluster, `(+270, 110)` |
|---|---|---|
| **outer ring, 84px** | your health, green → red under 30% | **threat**, green → orange at 70% → red on aggro |
| **inner ring, 62px** | your energy, yellow, with the 35/40 marks | the target's health, green → red under 20% |
| **portrait, 44px** | you | your target — a live 3D model, so it renders mobs and NPCs too |

**Two rings and a face, not three.** v48's target cluster nested threat *plus* health *plus*
power, and that third arc is what made the two sides look busy and uneven. The target power
ring is not rebuilt; its UID had somewhere better to go (below).

**The percentages moved back outside the rings.** That is the direct price of a face in the
middle, and it is worth naming: a `model` region cannot carry text at all — WeakAuras' SubText
`supports()` gate lists texture / progresstexture / icon / aurabar / empty, and `model` is not
on it. So each number rides its own ring and sits just outside the cluster: health 54px below
at 13pt, energy 70px below at 10pt, threat 54px above at 10pt. The same three slots on both
sides, so the two clusters line up rather than each finding its own spot.

**The 35/40 energy marks went back onto the circumference.** On a vessel a threshold was a
horizontal waterline; on a ring it is a point on the arc, so they are re-derived from the
inner ring's radius — `r = 62/2 × 0.94`, `x = r·sin(2πf)`, `y = r·cos(2πf)` — which puts the
35 mark at `(23.6, -17.1)` and the 40 mark at `(17.1, -23.6)`, both on the stroke, 11.5px
apart along the arc. Same dim + lit pair, same colours (red = Eviscerate at 35, purple =
Sinister Strike at 40), same conditions, same `sub.4` / `sub.5` indexes. They are square pips
again rather than lines, because a chord width on a ring would reach straight across the
middle and through the portrait.

**Threat kept everything it gained as a rim, on the property that exists.** It is a
progresstexture again, so its escalations move back from `color` to `foregroundColor` —
`color` belongs to `texture` regions and Conditions.lua skips unknown properties *without a
warning*, so getting this backwards is a silent no-op, not an error. The
`threatvalue <= 0 → alpha 0` guard is still there (without it the ring reads as full aggro at
zero threat), the party/raid gate is unchanged, and the 80% pulsing halo now pulses on the
84px ring.

**The specular highlight is gone.** It was a curved-glass effect for a filled vessel; on a
20px stroke it is a white blob in the middle of a hole.

**One region changed job, and it is where the spare UID went.** This is the only pack of the
seven that ever built a target power ring, so after the rebuild it had one UID more than a
two-rings-and-a-face cluster needs — and a dropped UID is not free: WeakAuras never removes an
aura an import does not mention, so it would sit orphaned on your screen forever. It became
`Rogue - Target Ring Track`: the outer ring's unfilled track, drawn unconditionally under the
threat ring. It earns the space, because the threat ring only loads in a party or raid, and
without it the target cluster solo would be one lonely inner ring next to your two.

**Nothing to delete after updating.** All ten UIDs in the two clusters — the two group UIDs
and the eight regions — carry straight across, so the re-import is a clean **Update** with no
leftovers and no new auras. Six of them move to a region with a different job:

| v50 | v51 |
|---|---|
| `Rogue - Life Globe` | `Rogue - Health Ring` |
| `Rogue - Life Globe Rim` | `Rogue - Player Portrait` (it *was* the portrait before v49) |
| `Rogue - Energy Globe` | `Rogue - Energy Ring` |
| `Rogue - Energy Globe Rim` | `Rogue - Target Ring Track` (it was the target power ring before v49) |
| `Rogue - Target Life Globe` | `Rogue - Target Health Ring` |
| `Rogue - Target Globe Rim` | `Rogue - Target Portrait` (it *was* the portrait before v49) |
| `Rogue - Threat Rim` | `Rogue - Threat Ring` |
| `Rogue - Threat Flash` | unchanged, re-arted and resized onto the 84px ring |

so a hand edit to one of those is what gets replaced. Every trigger, load gate, condition,
colour and spell id outside the two clusters is byte-identical to v50, and the player cluster
still fades to 50% out of combat, portrait included.

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
embedded in the script, then replays `patch-v42.lua` through `patch-v51.lua` in order. Every
step decodes, edits and re-encodes through the shared toolkit, and the final build asserts
historical UID continuity before writing. Re-importing therefore offers **Update**.

**Closed in v47 — the threat display used to load in an arena.** Every other pack gates its
threat readout to "in a party or raid, and everywhere except an arena", because an arena has
no threat table. The rogue pair carried no such gate through v46; it was largely self-hiding
(the trigger produces no state without a hostile target you are on the threat table of), so
in practice it stayed blank rather than lying. The threat ring and its 80% halo now carry
the same gate as every other pack.

Keybind labels currently baked: Sprint=G, Vanish=Z, Gouge=E, Distract=B5.

## Import string (v51)

```
!WA:2!T3xE8XX1995HlLejKCmj4HKOo4kQJqQdM9elGQi)iSlaiwsaSaZUGhqIc7S7o7UdWUZmCMzbWYe5edlRWKiBldgRefhBRG26g5KpP9d(0Q2MwNeZ4OM442(kIQY0wRwxw14ZuBZ0C4uN4(737nZoZEbacbclkR)ad254nZ8(D893X737nCNStD(Gho8H91z5oZ1zUlC3lNri7050uuJPusr74E84zup(oCy1oZQiBOPuQKyUyfLkLttuEQL5vkur07J4nAL851VS9E9wsuZqxDN27ZlQRurlROETRFunLSUUGykkLYPmRS(s1UGzg9Yzu0YjQf161rDhrljD(ZlOLZBk4YnKu1Mlb8ufn4YWUYIlY(F)5kiQUZKNRIGMO3bQuQK3tvuYqCjb5Sfv0gvrs2itS(hjv)8wniP05fVHf1eliPiNQQQiFbnLkQlXojJmWXX5zjj58kALfmGlRdE9ScLe9OjKf3vVlEDdbnJoYKxswsVyhrH)z0X8gAsfkiQPVVhqZ6NplVSqzr9oIAGpiHkAcbMxxvSuP45074Y6vYioJOSrsGEkn3stgR3KPMmzQE5tv7uJQjcNIp5O9p0qlMtmdCL47S2G9p0Odm(q80lkZGIcLmkgTc8wKrTKqvrTfQiB9k0XvakGOMSqPtcVAWB)tCjwxLro3(ccYsSEzxKBFGljkOlM0ay3fmkEtK9hvwrwC5CWloEftIDdnDrq4iN(84LIVme)rllijpaXh0aIFsasqsi4)7RXJSGUyP8uoczNhqkN6Ey8)urJrfJk5nPQyw9fnuYod7vDBJUNLYRbuq4nsWqWZvym1bWdHp5mjJX3F)JyX7Ild9hpzGxU8sf6iqfPClfuFMUkDU4jouGdTiqs5PmD9owwOIbCFsOs5MDSi2FKy)oAjfHCdevhes2lF5kGKxhrbow29s6Vd(SLe01XFLXaehKnWFQvLri)sBRZSV0rUW(jBPMweXZeQ71wgpzjPSIEfKZ5Tp4hxPM2sfvJkAI20IhXBFIc5kv1lqM0vKDo8asqlpLOW0YI66QDAF4bflROPvuOGiPdYntUfoYpg59rEVfjXHFUdYojDEdK92bzpurAYT6HC4TtUnGr3bzFDqUJoi35(EaYD9SK7UdGp5LCpDqoa5Ej3h5(jpa5hNCqYHipi5HipChKUbwb5rEcYr6G8tGYjnYRdV6CFGJt2k5X8q6Xd5rj)dYOckSGKqeYrxsvu90(ZnwU(cgK0f8s)4Dq6Tds0oiXgG0hsKjdq3Em62bPB3fz3x4ExucyDjPWn357HClp8wjXPD7LZAHXKCwjvX0xYExeSOyuSrPj35iqx)ZG97lHkMu1sPC6py0W(J4pAxrIeQgbaOlan5kv0f7Foacijtdons2q6fsRE4owkNK(uvKbeIzediuQK6ofO)oftpCyLCI)MVhGgELPffv7fLPm4rTQIyxg0T1fmq1mXIKh)rF9Llusz2b0epxfr5SvhDR(oCGWK9RbYW4jwc3CAl8W5XDqTHLZuXWqrobO8ayalIhEiQE8EOx)zSU(fWDQb375sqV6y2hPi9KjPGDrXFwK(IKQOuwQGNh65hsc(9oPpGOmS4lSl1oneNZys9Ic5CE1wGEmCZbUFas31v4GZEz2rTrgI274PsOUl6bbTufeAk7PKYbWB9c7Ef6jairXC0d(bwMbjy35Ue98tvr3qkFvGSQPyaK0uWbJosIr6NrcXRzr6fMTgzG9QMhS6PUJb0KoV3XQiKdbD8MkvD9n7N0Y0Jnl0)pLMG68NY6hlx7(qXPtmEQHIps)w9Dx2KUu8rgPF(jJMivQed70i040Dz1NoDD9PzK0LYusmDEl0UjrikpK9Va0HyhXcx3QtrPTwhXUT2nveudiVVLT2tXYUArrPcfngJe7KlaYetsb7sBPTDShiJUKCHsI88jo249t6FVKpAAlTY(S0htvhYcG60Jh(zrM0yQ72wbe5e9jPlaVnG(ZrxA2jY6Vu8iNpF0zPymiiXXTGyqSdacXfetdhzFnEeEHsQffOWliaYr6qtsgnLa6ujiBL3HBtIUVhGpBrXStpa5U8m)mcAs4R0LfNtvIzQlLuzXdOOEGh7i8ZiuQIyNH1YwuqUGiyDN8IPNxfCsb87PkAw5W(pmQlmVDNmD0ZROugnbe8c3lzmezQeNfYeHpnjzrskl8NxHI7cGiAq7sixQAAgOdyGrRGObI8C60KXpFu)9eky0U7kypWMq(497pqKG0THOBdZhORU7kcIirrV1gSx(HbheqS7ZqMG8euOhYtsbBiNLIXqEkBCfYKK0Cebsgs29qYXrezeP8fjf8qkwKi5Hm1ojtdQ5eOJuguMjYmlkkevY5iAe9paXGJubU3ZqMfUHZrQYUhNN8ts(P4ipn59t(Pj)mKpazEYh8Uipdh5dLop5zb5xYpl5cS71pxAYppy86xGJ8COqi5d7i8r(iKp6AvMJ88Jr(yOS10cNHxcmwQp1G1KToX6w2ICrxYvKFrQef5JBjn1b5tMM8PQJJ)iRcdN8PTy1KxYHlhOB)DJB6byQbdhKUneFGWbd1dWG7PRU5deXF3oSzYVE7zWh)TcdwF9ZG3j5dEpmg8gK4YTU5iUKixQqdptO(QOCUAIldTPjU8HAT4c1)eY4tWh0FGGHOBdt32fDBe62UBWrfuyQoxt(rwiG5YfRRd5xaITiAnE6WVnHNECE)Df2VFE)rcgkcDB3uq8qUHfAKB(U67ByYghmWjoN0ehxFMsoUEmY1EzdFrla26pW4Js8CE1Dvl6q5(8oC8KjJpYXCcnusvr3qSwAugqe8B0jGY(NraJrgZUszvWR1APxjM3eJ4D4(DoYjIh7eEhjXPCIMmvV8hR)uEJp8WJdoftJCS02jX)8uPvwWIZdVLjvfYc(yUocyCjWxRkLLTUbGGAxzyU6cUOjvqMStnDdbmSiomyVvimpNOP1yjQqm98G3PdjvwYOieqlVo(iEVyiVyKV76s5QkluwklnPoq0V8LWR8MxmFLsLIjPLf8coJMqoPk6pZTWywxgIgeEzKngaIxtrldFV9fF8KyGQqSYjG4tTfoUbq6zHcAsSipUzKDppn(cGlWbcuAhAQJxm0u6QvdUGGwwwSxpZENhBcgmWb47lQUIMbiSeLkmUEJK(c3hzmomw)v2dJLbQf4JREYIkZMqEzD6)gg8icCK3Tfd01JhKCsYPCCRyfmA8GndZWpkepwjhOg80(dZ2cGoPPGoPRb6SYk25RPyVinkeLYzemS1RRtvVTk5rP65aZLPYrPZ5j7pJQMieOdjKgM5QevmiVXs6qi)IzuG4MlJu35TZ0vaSDavVfA(xyh4Vx2aKh1lHbxcSw1DQd7JHpLY(WWZllegkCFdr(VVan)H0G0TVqAq2zOhVk(AgICroYxPt)Dwn327CoUfOHYGTyE7wqJkJ2G0S2nhRD(UPLXZu7fkn9cPTpDnH3FhewYcJkbikF0LYMRNQD3BQsJjQI4vwyvp)yyEmWKigh0lu)XJJjpmpOI9K4(6pPqgPssgvNudrsMuhtQvo4pYNSiGQ2EbZFlqW8fGGvzSZskfihqBseWR)(GoDyYbxmg9mEhco19XN8uaq485e1ngxwYG8qyskMSmi6IeK009Spz65Tpo)O9YZFgqYL9SiFxqj4kS7o5VGky)xcc8)vPj)1Pj)nKVh7cVWo5bcx2PJIjBqDN4DUGOSOMuwMAt6LRB3LyAr8Ic5QcQllqZA0icLf3wKFdY(5P7sHepO6TBNNBeHUai6P79G0mhDi1DHpgrmvstw7gKEzqSSus7D1Sr)Pm9AxeOVQ2jEiaevrtubIUfqxGJJDpqFEbljHStN2rn(nv7KjkALkkGglLv9W5PjRsr(GghYRMOrfnzVh04j8FwVkAEnEIaN9q0SvA8ebpRxr5CRr)h)Vvpmq3bqzu)TafyZ0rYzamLlxJqoTmgJUL9LMXvw05IqM6vlkd5nqfEy7)dkKXxH8)CfXrixM8)co1BsB0)BYFg5R2cWaYxJ81jFJ0KVPTcp5BLM8N7OC)72KYD5Eh(yhF8d6FWrMRoLBY3w9qTtLEwbqwsrBYSffkvct1b61YkPu)uG(ZRcV8pi1AdvYRiieBOMfaSpO6osr3ZBsjJkuqvqH5Yoxfv5DHAT4ar8rfURDGjXeSiawKpWrpckEVOtZaFJzc3ufyYFl5)h57NM83r(7rly)G388K9BY9EyQHMCCMCBjTjNhEQ)tMC3aQezYDJ10zm5UP0x128Auqpu42jOV6IMMCD0EXrtUBg6qxpif(71Ku4jko(CroU8b7tFIgLcV3v2WsEKxD1j)bslzfLnkshlSde2xnxCq2890b614K4iKHrtXa6RRfPv3BD7xt8RZhBLe222U)KTuAtZY98RbYBugnUjINRAXTN1wCBax(yxNxvFzuId7vxpiY95BsKBkF5LkPh50DluTrrUM8LHc0BLwFR)byG5S8LHfeV1nOLEA)aiixmioPCEJvB4YPYJnXzRNgHDFOVGKiKCzrJSoQnncOcu6JvFVzYeqaTjtytTiv1OrRrl015OotoQW1it0GmiiBwVCjkPA72pvffhwJIRCK9papo0HcPdOoJAAQekQ4WIUhWjGO7b(TTiYLSftBma9JUeFHrNz0SzHGIePspr)V(aKxahqaYV0sw1)anUnf1dCKJqEXOjtn(iKFfm))ns6(exXzyaOdTvTBKj39A3(LX2p5W9hBWEhjES2CJm5U)w1w(yyc9V6AJ2Oja)RtM8QRvrhO)E5TAcfKHs980(gSm2Gg7wRPwQflXidmEY(D1Mq4RxpuBPR07iFIePC1QAOHT9jLm(q9psS(Dtk6M(uc0(gLz0EJfFGZCv1MLzTz984u3rYydMiXqtghlwf(Xhn1v3BBFXt2GisikZ2NfHeH1yi53bcMZmR2k4nxxe5oLbCUbOzJeX1oy0yc6Gpu3wAM9WxXLTVL7LgnH3XPJUhZmi12h5hKtMA)RU0lyLPIhK63yriuhQ5)0wbpTB0npVXkkGLCde(fC6S6Usk6c1AHg7xIWDN(E1sdRV9f(TgF9Af67TVwqFzUfS)IU8eTzSxWVGCYmaytoVW1FpmWxWCi6vW(ysL3a5x6sSsCsMhdIWw(KJjzMM8jiNfXND8FabVTrR)9BYGofKEAPStpYSiQnGVdO8FB17SrJ59A5)4jGlDnzb)PSstGxmbyUs3oiLo(NnqxHce1VVa(ceQNUJgoCKG4EbGF1tp8WVI0nFOWHc2nV)EchjeFWqHI431aUylCBYfkTTNHHD9qm56YKlY1PISVnYJbuMDv8vOor1vWpHVWQ4NGu5YvKT8tOJgXsRVQV(IojPhZQLI3KkzNw0WRFNeWZooTsqGd36lpqRV8aT5Yd26lpyBU8qT(Yd1MlpCRV8Wox(O0cp0BSsv0bntNJNIwjd2hVXYu7CVnSk1UrNQuJoaahDPWNShTmNXN)a5cFvvGAEHlJwYsv0eXQdclcm1DhBOEhE0ujIouVXorV91x8uXpz)naHoVKmlHOaWPfckf(KjH9jixeG1OAHbDTTlMbfYTuARzklPPPObe4Tt2LM1Ba0zUXfaBZY5W3d(OGpk9XWbFf7OOjhKFuLzb2eMlrv8xyjFUDhSreWIAYU2jt7G59co3ggE3dvdV72OM)BaPd4tVgNBoTj3Pu71bzV3C5saq7yzp2lwIEp5WI5KeEYuSUJ(tYQ63jPf87KSsr7WgfeOmoqmayHR3HZdedm5gGkBc4bNTO6oZjPNvteEoUhYh(cXurfeF(8Ze(E(Ejp3DLHv1zfxBJsjipbYjWwtUKMCPQRrTBupm5sJX2YCDGbx7bz7MCNKXYbcj8wBYD6aGagLk8QuBb22sUi2OGHjFTfPJtWOvkPlcgk2QFu(bTYG2ry2g(MwhfmqSg0FaIsSHmg68rgO)dfRIj3tX5gOeETm5olsLa2dqyTaFn5ogLuBPZbYeGKbvW8pZwI6Yu5n35eCHAsHPrXTjqXnE6(D63K7j2E9IEMCp5ArqTnMKbfhGV6wb1KB8g8SXr1CVi6av33ILwVUn001Lw9JTL6yVW7eWFn5ottQWwedxebRU1AKiCvOTICZniTTbD02OInU1Uc4s7Ik7FnxZcO5HdBfmQL3onYaO6xMCcRK6LjxMnk1QCJmsVgsdEYiPMAnRwfF1uRm5YbQsMCIPDj2KVZaVJubI7D06phFf0FcUPR)amKECIV1VNgP(BYkpdQK8CLJFAFHLp)Aw55eRtLNGVJu55yVJw5zOvq5j0MTYd1JUUyjVRBpns63K1CkpXef11kEYHNE21SMZWRtnNqVJuZ5d)oAnNrwbnNW)qrZXjT3nq63K1CugA05kuv3xCF5wZAojwNAoHF7GMdMfmooow6g98Oov3kB(P6LxsUGZb7xwuRqv2bV1gsI0OkAyrVzqZw0T6bZLIDfEALUOyduVeHl5N9q9(iC9B6MClFRDGjTPUr3GLxjKy0MelbQtpChR)Ic(W3S7SBBYnkiwihtptUr57(qdu1jjt3iYPFmpyILajcw5Hg)7DHhndeKR2Kv5y)FoSoiwsiho)2eZnSWCBXzhj5TqIZDL8kAIyTVkNJnf7CsyB3bOjkOBpQ72zYgIZ3A2LxCjDCw1YsTs66t)2tvVauTshLk4yLZ8vwsR5R0wsBEr5C9IZSSNzVqx)YQw1khBsD(G357zlifuDhzQ9IAnR4w3z4Je9rxlq6UgJTBL8IhiOp4Q68XCnOJu3B9hGTLoeBZwRnluwyowzKqEXo9XMhzSMYr1xEnoE9scYgCQ70HHzr7vJS2tagQ8mzaFQZrt71JVVlSxA(3v3X9xxTSC)3FRshFjpTjF8Q(QnVnNKnh4RVuzMmNywPYcLMuvd(Honxy1pLaup0QChODy60jNpFjffnYhkn5dEhKNHt9(xLwYoyMrQuoJOg55EzscuTAnzy5iDOUdqpQxlvgQgur1D6iAzrxn5(zYKvtrDs6eVnK)fPZ2FQqkhvF9IEq7knEZKKls21vSfGTY5kDUfZBNYqML)fP8(bK00b5deByb6bWKYMj(ijJ3x)lPWMeVzljPwCERD0TDlP3oUIZ7CTzsllLfZNvPmwNZ6fPaokxwVSIIrr7sqnnDgq8YUHagOMaiowhXk3tjPiNUNrMveh8daTDjfnjG8t7aleBOeXoXPINSFgbAogbcqR0ODbXCfVqWLkdDKsX1Pf4hIGhqqvQiJpXgfon6vGWz7Xzyt20qCUKQL1LjuukNgaDUe71jVujX45ip0ISDvfaUZdX6mtQdIKv5a9wx7phDUl8CNzTj85marZRZMw3IEy2nrOF04w0ruKfj7IN(eiDEpopQk6JTUH7CUlANNtti3mcWtUi5XUv04upESyfNNwHD1StDoRdx1v)vBU3ChKN)mufGJU0yJp2mrJn3q9wncdGMED9zv64Y5vkI(1S28E2fn98UFGv5UWJAYPdAngC08huzlMCZGM5aSwlmy00oln4MCZb(3vTfMUAPp23u9YiRbVLAVeLj35PwVm5(jTTyzY9t9wXe1XVknrLhnrfgVQJEKAd0U6UXQsk0HTGIojBwG3qRc5RLTkC7A18GPnAw2blB(BLLntU3p83pnaIsE8jw5beU0wB0cundRHc36PA2ESNQzlB9(nS1aDDREy(6F6B0FeWGC3lIlPatQYwTrShdUAaXxU(ExARLlMjrHpEwJ2)IwlvaOn5DA9J(CwMgSVf2MTF0134wrTC)830LSUBwlmdUhNDgWo5wg9gde8WHJeM8C30LSEDT6Ey0pl7UlkwKTIda7h1E8(adpxacd6FUBsf7gAY9VaVhVcW2(xcbB(VYK7Fnwxp)2MC)BanQ)TMCFo4f0K7354w5LGwwxoVvm6n8wzY97YExm5(9G)(8T6jYUy3pXIT5jEZ4tSHcoWfn4MxlpTM7FR4tZD)ZJ7UwREyKN7PVQ89WK7NfA5fa9ctUFoMDttUFE3ouyY9lueJu95m5(WwUkyY9ryUiyY9rn5EEtUpgCvl44iGj3fDS9BY9lYS6RAY9Xzw6FAtUxanRN33jNAGjgz2XcnRLzDtUFztUx0K7xPMjCtUprXlCpyFAm7QLPoO0rAHn5xYgxSTtDS1ng4zlIbaJwyF5MYDq7tdasxOC)DrJXMrdpfLOdHG)8VSTno1BVH6taDL2BkCMZaKRHfYNTkFStnCpI2XOXSt)XDO20i7aJMSG1UONgc)DctUFFNGDTMke0GD3xdpz3rhV7gAWaLe0l6eESvlUMeE8B(d)WJhdZuFLSdf8yJFA(qdTkHhFF3Yk6EqZb(2ApewrX6njZ9pydrBgWD0MFNTMP(Oln5E62fwPBJV2rdAY9bwlH)9D26uOfxtU5BmAotUpOj3ZulentUpKj3ZAb)n2BdH)E1MG)oTWPfJCCHir4hBLH)cAY9RsJzXK7tw0nuOj3NQ9rRSEeH(0PPsqVe5Lm5(1WnlYr5F)dxNrvyY9pQH4jm5(hJKZpdekHj3)K1FeeMC)6W71l7eZGj3NT(Wf(dn5(nGl530Dac8fsOLjvbCwvZuq(TyreaeL)PW1(pRT(2ZO2Ttt9Z4Ki0Db0y0X9DqlYyKIdoR)(AHzO2OVI6k1sgevTANwUc)I4KrZUqQbIBxwJHzDAH8cfGWMTtjQN1yMHwInl2ORPqwkWGQCJkXVqrQUrnv4lD)1MwC1YLJ6d3uMsCM7CTidnU19lBR6REpRWnHDauxN5Do2HIeWPOiIeQv(O3Im44ClDY7dIOy7nVvACgRgYqD4fVfeCPaHxdqy(dQHW8YSINEj6CYvMUQd4QQu1SoewiQKDNoky0oxBNl7ZWRkOHLaV)0zmMvug(zadr50lY2jV0mIPNhOOgvlliZQP1JU0er7l5qNS7Eg2FsazZ2WxGW1cmoON2a151IKxBKU6GoakOKoBdB4Rqsa6mnZHWAdHcA3gzspfxZ6OVUJo6pwA36POgw3(OaJDI6zRGoBtdpvJSF7AJUwvqJv)8BGdFtRQPttU)DiI1fPCSxdhLQztj0vxhAo5Zm0Ow8F0lXAoBYQi(LDXln5(tSyJMCVw62bjpJj3)zKdAY96WF)PWFMWF)xSkbz4HCbFKphpF8JnykIN954VheROkBX8iRoRgzFdsC)Uwpoi)bRRfIdYRYw(nIou)dKI8hc3U)O1(sUb5lMM8hJXtr(sBV2kSb5Fp6G5)HBM8FmnHyViAq(prwUflzg3eY)(tUz7rZ6OljoCQX1hl1PZo1bjVoak)NEa((iMV1xrmSwXDA3sIXI402pwjfzr90SvFNhLpGpF(IWhOBF9eKpuGEI01g4QO0kmjpUMml4V9vDwW37BPLmNEzlzocZuisrXJ33uHl5y8)nAy4u)gPXPAaDGuPZd0aOGK10sWp8tGZ9vz)InsQngLWRsNzO1gyw6CaTZ5(U4TOZQC07x3oZzHMx2DUPwUS78tqf388s7Wo8Ry9Hl6S4cBSqjjzrV8vCc0IEUOLeYjcbGvrtRQDXVtprmLs5GZQOKRUdNKobs1nevTR9D6HhvteG1PzDs92Q)4LfZjXYhL9c6k9mwZCy7fmz6XoPaUqdREhUFnkPimTxL82p4R46C4KGPU2Nuvdx8G2HRdDmLkfeR7irbcrU6ocBjhAxUosFs4YrswJ6EJtAWgRlRA7p(dVv3axFPT3QOkxlaxi8cG)GOwa6XAeYIPzEREw)HJ1eshOWJyuiY2NBXbtWhFIeJKQ3HOGEhDPIhsP7dnQ00IfYG4FuinBaWT5caeaWbeYJqDrhWoziE)rC4eXBfWUCnLZVmBXhXEDfHn)Zd)kTC(NFLgeT3WMh6R2sk2kJbTwwUdWUKdA0hROJHH1rkgQBMQ7gzRg(1xTUPC22WvcW5MowxXoD(j8nL75qEVmefCzjYAnjp9AN3zY99y8RUc3s(1LCd3C9eZc6pBImRVwtmRtvUW0H18FWJ1DpTGzzY99xpmPicTKjTOd0)1tSiO3SjYI(6nXIoz4EQMTySPKYFSnow0h5l2AwKJz4RNyrqVztKf9nAIfzep6jng84s8gv2a1IKAjlAjxUeDDLAK0Mjp6B2ep609RK1q(4QL0NAdKhvOL8OLRZ90RR4sf2m5sFRM4ss8LoN0mNxXFYtTXXLAZImKj3D82ewZAn2YR5mK)8MyiNlM4Ppu5y6dQSXXq2Qrl5hzyHPTU4jVfwmM7CI1DYdwM9ziivIrP5hYoHSxNWS))0S3GAI94RYuf7t7mBCAFv)BAj3wDhngc(7Qmwp)5B3e)z04royKPMiryrXnm(to5wYEIIjb5D5i1Zr(onXr6jqUPnMLFWIX240ym(TBn8illuB6WJhBDdpAULTF9gM43TzDUJ390APcmLXitVXzauP1RXM0KkUPZG7)hLyWxPjgCE(cjsM9eZLC6QBym43C(wZGP5i(DrvRNL8x0CSALpvFJoyUrgk1gNoxBwxBn5297YpQNF8)Tj(r8qrp34dDIzo1Oz2W4hV20TKFmV9qKSzddEGOH)rjCW)YMyYb0sfkq(ti03SLxzMmCNxlmzCGO(bptRT0PznMxnYKXcD4QuZd4NnXJb(oWJLOSzlnpKJa8G6zkaNczk5BS0y)YfBZ3kbKkGdl66EWXaYPfH9Jv)sfzngZFfWksAeuyiJIXYfkGDvCElC1gI2TXQemuaX(RIcB4zNYvbWcUkIl8y9L4uJOEp1ktcPsLWaUmkk6DafnDHPfLzxYECnVslx1U5o3p6hbfC2lLy8uoFlAhUk97LcCiNkXalrjRV)M0r0eLw(8TSsmSgqZrQFLe8HCVscUVo91QsiGvvgwJTPvfz0yLx0vaiSCAXx8EBBXxClWFwvFH16uhTEJc1yHyS96leJhZd5ZffjBTUamU61xxL1AX3pBw4evYqSmLC89Xfi(BRfFHeIdxbTUIz0W5Xwq)(kCXVgvPK(TFW(GPRB5w0Cl3BT7T5wUpNBI5wU)TDXVoT5MB5bUkAu8xE90OFTgBe5mbeKR2WA7ytRGJTynDSPJC201HEaGdmGIgTpGWkiMIJD72Usk27gXkPyrewWgayl7BvwkfnqDtC403UvnA4EPuC1x2TBaLg10(bB7UF8gHPVrAoA2DRqmQbAVfAj(SIgMFBgVATUsTIeKRoU2DSkCTzvmYhk06MRnd0foOM1h)69XhkqGEcGlqQExQ2hMd8tQ7xjG)a(Wfay6xcfV4YnS3KvYMveNITwl8WByCOI)WtBAViFzv5j35QWtePQsTHN4BrDvbTPPFTQ2t9(9Sm9m1MnCQ7SU9Xzlg4azQIoM2(UMB5HMiQ)iD1fUjcUPBCtp8b7g(j5al6AzR21NChZT8iwF5vOZNF6ucErNFZQ0hl2j9J5SRpjVoZEORE7rZNrqZ1uPRwb4D2IxI2vzlIaNbm8(O7LS)LWjPn0IjH)2aQiVLyjvNvKN21M3mGqJ9xCx2S3la80AJy0TV(xsMVmT)5Aw)jGvsD9l(ix0EEkfHw69yrrRzrca5l3uOtZTaLROlH3QVm7u2Z4Xd6mJhr9uj5crf0EYXJ)io79ijXgylUwsj70kglrVjds)AdFetUtXhRKOGmkI)P44PNROJgWDrL7XAq8lSnRgkLlNOm)i9FY(5zs4oFmRzUxUDAfp)xB5sdUCYS6WtVUj3xXQ0q)Srd4RNq4xaCFWVIq)y72dkYhbf(JejA3Dfa)aTgO7W0TDr1bcDz8BBLKS4OIASz((NondFtLDaKBmVq(8IzneZH(lC30p9AO5R2(TD8Te02kxyQoQfHzFgrybuUPV6Jh)TkIzAYZh3rE5UxfeZYvJftXGHyUVAZkdYVCT5IraN1P8F1RERC1(ET6pya)DJBdeGUniDBi63V3EOIg1TIJF60xJeco(QxDYbdZ2UssbVT87d6BDzQvz1b3LC1(xvVJGOg9VcYvbBVCvNZS1N()p
```
