# Mage — Arcane & Frost HUD (v3)

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

## v3 — per-spec audit: each spec sees only what it presses

v3 is an in-place update of v2 (same UIDs — the import dialog offers **Update**, not a
duplicate group) and adds, removes and moves **nothing**: it only changes which spec loads
what. The test was tightened from "can this spec *cast* it" to "does this spec *press* it as
part of playing well", which is the question the HUD actually answers. Three elements failed
it somewhere:

- **Frost no longer sees the mana conserve breakpoint** (the amber line and its lit crossing
  marker are now gated on Arcane Power, 12042). The line marks where Arcane stops spamming
  Arcane Blast and starts the 3x Arcane Blast / 3x Frostbolt conserve cycle — it is a switch
  between two rotations. Frost has no second rotation to switch into; it is Frostbolt spam all
  the way down, with Ice Lance while moving. Its actual low-mana actions are Evocation and the
  mana gem, and both already have their own prompts carrying their own thresholds, so for
  Frost the line marked a mana level nothing was done about — and the lit marker put motion on
  the HUD for a non-decision.
- **Arcane no longer sees the Ice Lance / SHATTER prompt** (inverse gate: `not_spellknown` =
  Arcane Power 12042, the 31-point Arcane capstone and therefore a true spec discriminator —
  no deep-Frost build can reach it). Ice Lance is *trained* at 66 by every mage, so gating on
  Ice Lance's own id hid the prompt while levelling but not from the wrong spec: 40/0/21
  Arcane loaded a reactive prompt it never acts on. Arcane's rotation is Arcane Blast with
  Frostbolt as the mana filler, and the Arcane guides state outright that the spec uses
  neither Ice Lance nor Frost Nova/shatter combos; it also has neither Frostbite nor the Water
  Elemental, so two of the three ways the freeze window opens do not exist for it. Frost keeps
  the prompt — Ice Lance into a frozen target is its one reactive button outside a raid.
- **The Evocation prompt is Spell Known gated** (12051), like its cooldown icon already was.
  A cooldown trigger on a spell you have not trained reports "ready", so below level 20 the
  prompt fired for a button that does not exist. Neither spec at 70 is affected.

**Requires WeakAuras 5.4.0+ for the inverse gate.** The `not_spellknown` load argument does
not exist before that release; on an older client the unknown field is ignored and the SHATTER
prompt simply loads for everyone, exactly as it did in v2, so the pack degrades gracefully
instead of erroring.

Everything else survived the audit unchanged, and deliberately so:

- **Both specs press Icy Veins and Cold Snap.** The Arcane raid build is 40/0/21 — "Arcane
  IV" — and spends its 21 Frost points precisely on Icy Veins plus Cold Snap, so it can use
  Icy Veins twice per burn. Cold Snap's *glow* is still the Frost sequencing cue (both Icy
  Veins and Summon Water Elemental spent); for Arcane the icon is availability only, since
  the mage never has a Water Elemental to bank. That is a condition, not a gate, so it is
  left for a future version rather than smuggled into a gating pass.
- **Clearcasting stays ungated**: the standard Frost raid build is an Arcane Concentration
  build, exactly like Arcane's, so the free-cast proc is a real decision for both.
- **Ice Block, Counterspell, Blink and Invisibility stay** for whoever has them. They are
  emergency and utility buttons both specs press under pressure, and each is gated on its
  own id, so a build that lacks the talent never sees it — no spec gate needed.
- **The mana gem prompt stays ungated**: both specs gem in their regen phase, and the Item
  Count trigger already hides it from anyone without a gem in their bags.

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
and the lit crossing marker is combat-only. Since v3 the conserve line and its lit marker load
for Arcane only: they mark a rotation switch that Frost does not have.

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
30% **and** Evocation is off cooldown, once you have trained it. Barrier MISSING fires when Ice Barrier is absent
**and** its 30 s recast is ready, so it stays quiet during the cooldown instead of nagging.
The Ice Block prompt fires below 30% health **and** only when Ice Block is ready. The
Invisibility prompt fires at 70%+ threat **and** only when Invisibility is ready, in a party
or raid. The mana gem prompt fires below 70% mana **and** only with a Mana Emerald off
cooldown in your bags. The SHATTER prompt fires when your target is frozen **and** Ice Lance
is castable, with the freeze window running as the icon's swipe and bottom timer — for every
build except deep Arcane, which does not use Ice Lance. Every
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
| Mana conserve line + lit crossing marker | Spell Known 12042 — **Arcane only** (v3) |
| Presence of Mind CD | Spell Known 12043 |
| Icy Veins CD + Icy Veins window | Spell Known 12472 (loads for deep Arcane *and* Frost) |
| Summon Water Elemental CD | Spell Known 31687 |
| Cold Snap CD | Spell Known 11958 (both raid builds take it) |
| Ice Block CD + Ice Block prompt | Spell Known 45438 |
| Ice Barrier timer + Barrier MISSING alert | Spell Known 11426 (rank 1) |
| Ice Lance SHATTER prompt | Spell Known 30455 (learned at 66) **and NOT** 12042 — hidden from Arcane (v3) |
| Evocation CD **and Evocation prompt** (v3), Counterspell CD, Blink CD, Invisibility CD | Spell Known 12051 / 2139 / 1953 / 66 |
| Invisibility prompt | Spell Known 66 |
| Threat bar, Threat Flash, Invisibility prompt | party/raid only (`ingroup`) |
| All six alert prompts | in combat only |
| Everything | class MAGE |

Only six elements are ungated after v3 — the health, mana and threat bars, the threat flash,
Clearcasting and the mana gem prompt — and every one of them is a decision both Arcane and
Frost make. The inverse gate (`use_not_spellknown` / `not_spellknown`, WA 5.4.0+) is used
once, on the SHATTER prompt; `use_exact_not_spellknown` is deliberately left unset so the
rank-1 id resolves through the spell name to whatever rank the player has. Audit any future
change with `lua5.1 tools/spec-preview.lua mage`, which decodes the shipped string and prints
each spec's loaded set.

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
(sha256 `564fef30f0552bd3df8e5dbf906d4bbed5cc54aaa812e36b45548386d74ac8a1`, 7253 chars,
32 auras). It round-trip verifies the encoded string and checks UID continuity against the
committed `all-specs.txt` **before** overwriting it; `changed` must stay 0 so in-game
re-imports offer *Update* instead of duplicating the group. v2 added six auras and changed
none of the 25 v1 UIDs (`stable=25 changed=0`); v3 added none and changed none of the 31
(`stable=31 changed=0 parentSame=true`) — it edits load conditions only. Future versions must keep the
seed, never reorder existing `W.uid()` calls, and append new auras at the end of the
creation order. One import-time note for users: the Update dialog's *Arrangement* category
is checked by default and will reset any positions dragged in game back to the string's
defaults — uncheck it, or report the coordinates so they can be baked into the script.

## Import string (v3)

```
!WA:2!DV1AWTX11zVgwXsq2jKuw0wkwXWmMkIo2YGae8HIusaabejnji0cqsjBvdSa4sGvCXUR2DbFLMKAw7u23TSUPXttBsOBCBZ0F0GMjJ7mzABytQB7KzYPSDYStBAZunTjPVBvNM(Utp37UlEraqjk6Xw6hC5U3x79EpFNV739CxWnBxz)0pY6pY2zeYUqonf1WkskAt4YLR4U8E6aQDLvr2qtrsIKlCbrPCAe5RS9uc5jEEspJreKmku2(PPeKfCYjzbnIGH6rQ7rprLe0lOESAkVNWkY6eTfjEMuuMO(qTilJRLrrlhrlKDFuTJqsIRUQGwopjvuKmev1wE65NxNyWLrva7Ig2VLKHcJnxqTScYepN0tunfDJmwTvbTvSQYv3uJKxuro5kQe(8AkLu30QejexLCGYIYZROvuWalH7YwzynfXXX5ABHsgfu0MwLMTU7m4K18I5DRjKLLWG86gcAgUZmVOSOEb3HW)z4EndnX85jA6XoPM9TF8qg03UqjnbFBrVQRsKKeZPF8U8gQewPmQscRq0wJL(450DFn9szilIJ0eLMFEXLlNkCWejtLizq(KvYkUgbZIpr8ito51lPtISm2Vsy1cP5Lfks0DVzosgSfOdETXImz8OZm5gLKT7wUlNtu)kLKXrZIeFcssQDkWUpPv(tPKJ8RDx2txrYLNO2zIRwcnaEIwssYZCfeniBzLR1C9H2qqw0AYCq4HIUfrqNKWany5nkCVWjcjRit2oho(PLifDortNGtQ50xJwuAVegiurbr5OGFScWaqayqyi8)hRXu2qNinFCfrzJmHJelze(EeZP2HncJNORusllr)6y(enzbPzXxf(sF2YZRHtmyNsWqW11fKZI23O0KOV8mjcZhjsSnnuYUOv5py8J6RKyUYNkFGRUQXfvtgAeE9ScsexBIMbEgYs3b4moIOnCTjDajAHycjPiKZDzRxdRZcNzDVBQJO4fMtmNrHJUPiw8eSo7dFxWH5G3X38UGXGZSnRm8kgS5ko1oR7zQLjuWzsoDiA1laVZN7KWd)XXPhpW7gEmEg8iJL)lM0Jc94EneGKIc1sd9cNeoLBOp4XH3R7ARhmT6dmdwepHliqX4enrDdXS62nbCHgQl8eWtcNgri0orQSomlUGZ(SWiWzwlJGTVu87X7P7pa96qdtV6lGleyQlyqHcKcBXgBwqOlXbJEMUHtuM6MGnqk8V17wTldYYgP0liKtzPlAZfSbln6f1o6fHszXbDb2yU3Ev7OMku1H(AwP6GCGPupclf0pxHIBZYmkHcIpEDwgOdgjhlXNFBlR4LSF7BXY)kLWzO5xboZMAutdjjMyOythlcCcneGqlZMScwD2XQBppY7Q2runXv9CHsc5OWrpjtQ6TYykLfVuQ6gyPYrYIoysPu1WB0ziJANAC6CBZsBjevoNMG6AZzFZ2vE1mcHPNj5KJhlI9CvnG0YJhlwe(u8JF(XsQ23U0Lqkv5CmNz(5Luu0SMywe7DzKiPR(kP8ThZEs0XeQ27U04wjMjwPIzWflGtSboPA5STT1)S72(qyItkk2gi7hZw16BNItFZ2TnfbP2aVopPJ9txzkqeZxW4eW5NDdQNtwCTn90zmqpFzJU5lwcxvYnpl1tMrxuoVej0ubpFeyTUHxmDiKhpB3WAUdrBm6nxJbXdH1oh131xWrhvTdSHdMJIGi5i5Msy5cW9bVplYHWvDMoQ7glPi6X3HMTdc0T7A9FUi3gmVrDXCeEMbe8r5IBKpD4DNHfEqSIUHJ5goU7YSxXySjLZPrTxL0i8HLicY8csQfeCz1jsALJ6PgNY7oVqwYLdlGUiY5djOD5zg)jR(0tMGXOXQwb4dImTido4k0Qkkf5GZ5IFjQB3xXn8(HpaeSmj)YzMC6bdoP(uAIYu6zsb7ELyUCez(yrMncFzfnr0cXij3CSP5h)zMowYGtcrpZj5ZwGKDHOWdFG1wuqtuaraRjkhwPygbd(ffKkr46rrTNZDoTSfeKZt0p(jHxHPsAnvuucrZyf4Loj8PXwWf8z2UoCk8k9eWlw7Uol8lrR2em5vdsV0Vl4ZcjRup4vXY6VUYsl1imksFwxz1aoI7RtfTLN5FvHcJw4Hw3lm(rHjSxW4lXrxWaEAoysykiM9QbFXQS68XvwIOrzX3qLEh1xLRoc9TPy8k5LUPRna8726aqIAP)HKtyX1ZMdP3osaxWmfGzTP4H5wVB4ICWLUUd7nRh0BVWZYCxHlJdNVp45GuppKMdeWMmdKfRxoGy9IMhYdICQNQvKiS2Rgck4QWvGfajOiidkGwA1hR9v1knyrq)yaYw9uTV07KCgzSGLGLHvGv5GpK1O67pn8HbVWhXf8rP0lWpqA45PueWp4jHxaErlge4JXs6hIDDD4hg(ryKdWpQdNa8JHCaWpo69d)eCWpj8tTV4Md)0Nd2a(zGxYf8ZcFC4NRQF59aFcQtj8YvCihp0Z4TV(gzOjgkl8Zxa(KWVa8lcFki6XTW6haX6BcVITpLfuNHeqW9lHGB4xUfW5p5D3iCowTaXnny72GQtbPJ1YtmqG41O43QzKMIsNwTd7nMKq0OeJrGbBVHXSdtV4V5q2T616TPM1OcEv9j2b8OsHAc2O5WB1hTnnsf44o8bQfx3KfvR2e15mWq1OBWUdtxeHPLPtYi3nDpu2ywn7hX7pj0z6qAcI5s)wBG8b2bqoCXqZnYfgD1PhpADa5hVcP9gvM)qY7HOK398(p3UX0ZlKhNBGxXvTEaTMSVw)bp0PORBVklv4gvZG6deEYGtfh18pzWWpnkGy8KJpBelVJFphVJTR6iG920WVo85P80LtdFPEg2l6wGYfRGfOlQjyOOrhmtd)gnZ74iOihlPiSrO1fSFpCa00LPOOMMIwbMpBh48D3U3iJJeh0uh1DlSLZdNid6iGYvypJz)v3KPIiEjjDYAo7qSR(zvzhgA1oX9TMvJyqsP5SbP6m(BOEMQ6pcMl30Y6xEoIWcbPB9(YtrYjkCzBLk6x2AlTPy7M90g5fyifkFacsqkbkM5TrjMEjktWAvFHbll80ZhpsuL5MFUImOeL26J2BgRDcuWYPbEnh69FZV7l3ApJx(EoSLvh(TGF7DSao8RWw69xT(fTHp3EEHAeUTfAsPBiJr1XWIbO2u43TatrHL5e(k8HMmsSrVbz13ZEU)(ny)G)GMyfUx4WN9UTmdWFiD(FoVZpw8NoWido1mvN)Fu4Rzp1ZwuGfrLfKvws2Xo8X2XITBwTqh8PQyroqTgeQt232zkw9O1TSFf3OZEUTQnduMNJPJPGVoXcPBT1S1wjxnXav1pd9QGVkmKgnuktxYG5wLrVaYrVa86HORQXMVBI9WUM2UIHMxaDFFDFynyf5gY4CWgnolovSPU4OLMC0fdxJZbZ48XO(fFDhhaMvzt2MSyAXBy9dOgtYHw)raUkbVeU7jupUDaFSJbyiCdz469gOUzD1USZB8SygcA4gd0AS8mHXEMtug37S6dwP8R4zwIOSUDgWHa3ucG7dUF4TJt(3hDYVtORdqnqpG1QLODbng1onvr1Y7cEKJ3LxhxsQhk1G)Es3e3YNcxWT)dT3DJSSfBzpocvc3rOTvIAbygTGLdmzXatigo6cb4HWUGrDdrCrHqN3n1gT(7MjedhpVd22k2oRIIeojiNyjrCNbB58inCGfA9aM3)GE977gAqF2N96lqiQbP7z2GNsUwGjfdbsJoX3y78sklfvJC1se5SRyjoZk2k0m2cHnNxYocpPxJMeloVXfxMiTj9XjzbF8OLP37eDKnY7ufMAVbdyj0ZfRqoHMie9HcSIMGfWpwpjzbXSlit01DXYHgwB9ozVOqwHDE9JW0h2tV63K7IPgfCNb0FulHzvAn19CRTLvSCcnDYKtpfO)Gwn88mfFnvT3fSx46R3AcZADk7aIHEgFlQdsWYtgp(vlKnq8XcOqPUO9NpbBYDnhCt6kcX(ZuFaNePRfpQOoDl5O8rKe5LVaeln1Jc1Jz5nqH4NWIGY2BOHuo2osHI5Dw3c1JLrNrlaVsx(RD1R0WNLgk3t3)PPwrQl95C1Ota8xMgUwRr7xHV)(hW3G8973R)(zx9XU6N33q97FaE)(hWBGBqFb4VQk6)mFd4V2bXdFB47Kg(UWFd83Eu4VJd(7zkjhWslgon)pWb)JfG)jxW)Sl4FPt46f2hGoW)ALDiClJxEInBgEj24jYFXrlo2fYxOE8c8VvfO8nHV3ByGIRrwwv0sTzsXIeeCeGcooBvWb8FSNWehNVFFEhW3(Uv3vfZonAkV5z1JShzjUpx0y5TkPVLMtoN(i(BTz)p3XShz)3SBYDx7VM6bg6w0uJMXVdZswXq7YYRMIbqR73D7mLmmuKNErIMKWkVL0A791A0AlGg7vIo2iRezG(KLNQ1g7)I9DJTBBBP3q4UWxQNzId39QvoXAAGRrfGSqrxr3xKfvYYyc8extPOQHA3ocPSep6zQXtKy8yNVgHIufNkzxWPcoQlhxMDedIsIgR0yJXo87Ztk6K(dvtJnPGmEnXybtMmcpt2jfd(LzyqlHM0WLNLC)3QknlJBQVur5e0gZk2xzSeiWlijMhvGOHlwspcyoQ(quzyvv3AwhXljntpCyx4oIxYUDqXXufSDSvUvKfkkMLfAiuNCiDfndyGnYRjADwAhEn6TuLA9WpkVKyrrJdtpGYjP3v4AzvKXxVSruHS42QYWhC0XNjrgnHCIL0FH7dviVbA8Se29cD7aHC(2eckr0m03C(sssHf1YkHDuB9V42sqLUhw6wqGncmTawbl7RVlCQWx5kl2)mNApWxeW)GVbS0atmG9ofPlnK(nlbbZxnQ2)PTjEGmEctUhXsmq0(Yp(aZsU0i8l2sIctU7TfQbC2d7FcBpSL1LeZrYOGuMfzBL1VZEFBK9y9o2GDG(u0426gAc0J4IP4horMSL0XgidRaRWw5L(gSEEzRNF9U6hEjo2HeYsoDxRK7qDTm3gSaArB11CAv67EB8EzDj6rfJzP2PtEjDsg7ywbXZjH0S2M1APRNA7XGj4ApQ75QnSfWFuxNf2UMOsa)XPBBmLwVtESxKDHq0JhxTtA3iprMOjMnrbLLMwo9219yzD2)4jc5wHDytSWQetOi5Gp1rGtWZE0(7m4yHTL(tPbZRHBOYZPyF6k9P2flmZ5Lv0ik4IDirbj92AebPeon3gvyQ3UsiEOPZc7pT3Bnw2WEAm7cPvpc9Ec9dKP2I3shThFxvE7NfPwxnXpR9Egnj2h7WfbOZx17Hq)sDOFJqJJCJQ9un4M0N1VmBMjvm63tbjv8sA5jwEux4s5fp10xImBCsJEufQ6rDWBipktUhdEDtUEBTFKj3jn5EpWjm5oLjxFv8wm5E8A9um5EVoUiMCpHj3tsBjtUtBY9uyBzY5nTjx)7jG(RAVBm4)e(VG)B4)b(FH)VTXLQYwGOBHq32cHoLOo9i7Bhbmd9BY5ZKZVj3ayxkGjhJX2KBi6EzWb5WwqztUrm5odwI3x5Ac0Kj35AanAY9(Xc9bULaD1VDV9Dux97rdrDMCFqvpnhSHJ1utIorYgwqTGXg7PNZ3Qr7pq02a1o0DiqTkN3c8Qw8PXzGje(G2CQ9(cPT4lR7ReiTA31)1T4e5yKx(ga295)inf2TrfzOVba6SI9S1UnFdc1HdRDI6E0MJ6yFHNwxTGDdhAf(OleFHOLgPnWo33Xb7(DQ)O9gIE0EWxENhKx7auVytHtBv7Mx2)rumrQdeW(8sVjbuVk7q0AYxlHfo71CGAiidZANOQ(Aevf0AyMIU3Hu1oWTqxtfEiffHr8p)kTJu7W3bGUKBIqXHUHfk(fHtes0GuKwzkmdf49qnrG34yr6ZIK0giIT1wm5EyomjzR5C3bN9HR2(Fd6KsCRpepLsYgPTaTBsBqpHPPq)gqyzv7HABjL0s1xL3a(Y5zLeNnXxVjhpoHLO6RBpZt63MN06OuVPX23KBzIcN7Tr484XMnfkUjBQZtkMkHHImjL3(TGYEFML1lm8SJU6Z4Vnq577oeIs7DAVQV(95Z3Wdgi0G9tJmVxF(9Y7BiVdpmnKDJqJmV)rOrM)Z3eDGAJfKFQOZm5UTS8I)7TEzzwaD2lKONzxHBbyCOJ46n5D6)QTKo(AYkgPQ7K1T8hRp5APSPtL7eLFYDvka7uFTG5J(mYkcAN)uIbgTnXq4(Flpm3Rj3Bd(uWD)5SJBy4rB4qRTJ1il940pLgAKdvM3ZuIY5SdZjlVkhMTQNQjMOuXIkYEMtaNy9erIqLXlivB1cJK3EsilOwFBzl0S2eRSx8A7PmozIgZmF9QjhssuEHAlxDl56eVZN4EQjGNMCV9dDRgTttU3HZh4NjxN0lDTZ4AAYDeNqAAY9avdMPj3rHUoGjx3WaMCp4Hn5EOE4h1K7y4DhVGj370K7Hn5oblSKMCVRQXJSYVffNfc1n580ySi52xcf5udF1rxAwdvvvEk)4UfkYNBN0zBs3yCqPLewr3Hw7PC3C5H1ccBlZ2n9hL0nTmY6I1zHBWLAdUho4kton6hOI9pgT02ND5qsxAYf1cy4FP2q1ua(Efyunb3VoyJQFwIBQi7aUA4ZmKEywZGLBq4HFI7c(m(cgB0mSp)D9hFq7daBz4vW1WC(GUCTZdb7XUXcQ9owy0Occ6WnfbP2rJ8v3I7Yyxp6mtU7z)cwC4gGfMClAdhuYpPkz0fdp8qR2g4G4(oCO2d1C5MbdUXnNpxBnNEFTwPZXEfM7CzdQ)GnRZSlV6SdNSVIJCHNjqBm7x5nqwGwy2R69BYH7JF19vh)2Ju(qVEZD87U56oUZf3GteTc30)KrK8VsKzNjz)Tb3SWDy4g52IBo9xS5mmveJUBiLgA6RzfU)kRr2EImtUp8nz7BYT2Ua5n5(O7YIB(eKxzpEwa1S9V9xylAhAfS1y4axuBXKYZmyS2aBLEZh2EMDcBdrHdyDXNUxAoV4BmYEAry6n5M42hDongt(Aqar8xA0C6f8lns42Gak(wzDo7IS1J0c73zVnsN6rAP9lUOr2yzNRKFIwBSFY32A)(cT4ynQnKe32yi)cVylTJxS)jYpXC9hzfJ2T9tLBBTJpWQn1oYZIH0TngqCu0kdyYlgSVaAl4lP3(AJbu92wd4l2cA0PUTX41ANVm(MIeBOHtiNC82y7U6Bw2UUk2vUUYT(7Q(FSuW7d(wSyQR58lAI(Rz6RDW3A)RzcU)D(tyAzPHVIS(txuCOjAYpHPU059F6aN2BxlEpF4))p
```
