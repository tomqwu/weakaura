# Hunter TBC — Beast Mastery & Survival (v3)

A single WeakAuras pack for TBC Anniversary (2.4.3) hunters that covers both raid specs:
Beast Mastery (41/20/0) and Survival (0/20/41). It is built from the rotation, not from a
list of trackers — every element maps to one line of the priority list, and anything that
does not change which button you press next was left out. Everything matches by **spell ID**
(never by name), so it works identically on a zhCN or any other localized client.

33 auras: one draggable top-level group `Hunter TBC - BM & Survival` anchored at screen
centre `(0, -140)`, holding five sub-groups you can drag independently. Built for WeakAuras
`internalVersion 45` / `tocversion 20501`; modern WA migrates it forward on import.

## v3 — spec-selective loading

v3 is a **gating-only** in-place Update of v2: no new elements, nothing removed, every UID
unchanged (`stable=32 changed=0`). The audit question was not "can this spec cast it" but
"does this spec *press* it as part of playing well", asked element by element for Beast
Mastery (41/20/0) and Survival (0/20/41, or the 0/21/40 variant that skips Readiness — the
Readiness icon gates on its own spell id, so the row is right either way).

The answer for this pack is mostly *yes, both*. BM and SV run the same shots in TBC — the
Auto Shot ↔ Steady Shot weave, Multi-Shot on cooldown, Kill Command off the GCD after a crit,
Serpent Sting / Arcane Shot as the instants you press while moving, one pet, Aspect of the
Viper for mana, Misdirection then Feign Death for threat. Both raid guides describe the same
loop, so the shared core is legitimately large and it stays shared. Cutting it per spec would
have been noise, not clarity.

Exactly one element failed the test:

| Element | No longer loads for | Why |
|---|---|---|
| **Expose Weakness** timer | Beast Mastery | The 7s debuff is a **Survival talent proc** and the trigger is `ownOnly`, so a BM hunter could never fill this timer — it was an SV raid mandate sitting in the "loads for everyone" set. Now `use_not_spellknown = 19574` (Bestial Wrath): anyone 31 points deep in Beast Mastery is not the hunter this element speaks to. |

That also upgrades the shared `x=44` buff slot from a talent-arithmetic argument to a load
rule: BM sees **The Beast Within** there and nothing else; every other build sees
**Expose Weakness** there and nothing else. The two can no longer overlap by construction.

**Requires WeakAuras 5.4.0+** for the inverse gate (`not_spellknown`). Older clients ignore
the field, which means Expose Weakness simply loads for everyone — exactly v2's behaviour, so
nothing breaks.

Kept deliberately, and worth naming because they look like cut candidates:

- **Mongoose Bite** stays for both specs. Both raid guides discourage melee weaving, so the
  cut would have to hit *both* specs, not one — and its trigger already gates it perfectly:
  it only appears when something was dodged **by you**, i.e. when you are standing in melee.
  It is silent for a ranged hunter of either spec, and it is the right button for the
  levelling/solo case both specs share.
- **Kill Command, Mend Pet, Revive Pet** stay for both. Survival runs a pet too and uses Kill
  Command on cooldown; a dead pet costs an SV hunter the same button it costs a BM hunter.
- **Serpent Sting and Arcane Shot** stay for both — both specs press them on the move.
- **Intimidation** (BM) and **Wyvern Sting** (SV) are already single-spec via their own spell
  ids and were left exactly as they were.

## v2 — rotation fixes

v2 is an in-place **Update** of v1 (same UIDs — WeakAuras offers *Update*, not a duplicate
group). Five new elements, seven corrections; nothing was removed.

| Fix | Why |
|---|---|
| **Arcane Shot** joins the cooldown row (3044) | The guides' weave slot is "Multi-Shot **or** Arcane Shot", and Arcane Shot is the instant you press while moving. v1 shipped one half of an either/or and called the other half situational. |
| **Back to Hawk** prompt (new alert) | v1 only taught the *entry* to Viper. Viper is a flat damage loss (Hawk r8 = +155 ranged AP), and `ASPECT MISSING` structurally cannot catch it — Viper counts as an aspect, so that alert stays silent forever. The new prompt fires in combat when you are in Viper **and** back above 80% mana. |
| **Misdirection prompt** (new alert) at 70% threat | The threat bar's danger state was paired with the wrong ability. Feign Death is a full threat wipe that costs shots; Misdirection is the actual 70%-band answer and every TBC hunter presses it on cooldown. It now has a prompt instead of only a flat icon in the outer row. |
| **Feign Death prompt** moved 70% → 90%, and gated `combat` + party/raid | Solo you *are* the entire threat list, so `threatpct` reads 100 and v1's prompt glowed permanently while questing. 90% is also the honest threshold now that Misdirection owns 70%. |
| **Mend Pet** and **Revive Pet** prompts (new alerts) | The pet is ~35-40% of Beast Mastery damage and the prerequisite for Kill Command — and with a dead pet, spell 34026 is still *known*, so v1's best element glowed for a button that does nothing. `unit = "pet"` is a first-class WeakAuras unit, so v1's "no reliable pet-state trigger" was simply wrong. |
| **Rapid Fire** and **Bestial Wrath** icons now show their **active window** | v1 showed only the cooldown, so the icon went flat for exactly the 15s / 18s in which the burst decision is live. Trigger 1 is now the buff (Rapid Fire 3045 on you, Bestial Wrath 19574 on the pet — that one is a *pet* aura in TBC), trigger 2 the cooldown; while the window runs the icon stays full colour and glows. |
| **Threat bar**: third colour tier at 90%, party/raid gate | One tier per paired ability — orange at 70 (Misdirection), red at 90 (Feign Death), deep red on aggro. Solo the bar sat pegged at 100% red in the closest slot to the crosshair. |
| **Viper threshold 15% → 20%** (bar and prompt together) | Viper's regen scales off *missing* mana, so 15% is late. The bar's colour flip and the prompt still share one number. |
| **Kill Command** also opens on a **melee** crit | TBC Kill Command is enabled by any critical strike of yours. v1 watched `RANGE_DAMAGE` and `SPELL_DAMAGE` only, so in the one scenario where a hunter melees (pet tanking a dungeon, which is why `Mongoose Bite` ships) the window went unnoticed. |
| **Kill Command anchored** at the bottom of the alert flow | It is the pack's one reflex prompt, so it gets a fixed home instead of being pushed up whenever another alert appears. |

Still **not** in the pack, and deliberately so — see *Deliberately not included* at the
bottom for the reasoning: the Auto Shot ↔ Steady Shot weave (a swing-timer question, and a
design decision you should make before it is built) and the AoE breakpoint suite.

## Groups

**Resources** `(0, 56)` — three 172x14 bars stacked flush: health (green, `%` at the inner
right), mana (blue, `%` at the inner right) and threat. Health and mana are always up and
fade to 50% alpha out of combat. The mana bar turns red below 20% — the same threshold that
fires the Go-Viper prompt, so the bar and the alert agree.
The threat bar loads only in a party or raid and only exists while you have a threat state on
your target: green normally, orange from 70% (press Misdirection), red from 90% (press Feign
Death), deep red the moment you are actually pulling aggro. On top of it sits a red
`ADD`-blend flash that pulses at 80%+ threat, also party/raid only, because solo threat is
your pet's problem, not yours.

**Buffs** `(0, -16)` — a static row of four 40x40 icon timers with the remaining duration
under each icon. Serpent Sting (your own DoT only, all ten ranks) sits left and glows in its
last 3 seconds so you refresh instead of clipping; Hunter's Mark (any hunter's, all four
ranks) sits centre. The right slot is spec-shared: Beast Mastery sees **The Beast Within**
(the 18s self-buff from the 41-point talent, spell 34471 — not the passive talent), Survival
sees **Expose Weakness** (your own 7s debuff on the target, spell 34501). Keeping that debuff
as close to 100% uptime as possible *is* the Survival raid job, so it gets the prime slot and
doubles as the alignment cue for Rapid Fire and Readiness. Since v3 the two are exact load
complements on Bestial Wrath, so a Beast Mastery hunter never loads the Survival timer at all.

**Alerts** `(-150, 96)` — a dynamic stack of glowing 40x40 prompts growing upward beside your
character; each one slides in from below and flies up while fading out when it stops applying,
so the appearance itself is the signal. Nine prompts, with *Kill Command* anchored at the
bottom of the flow so the one reflex prompt never moves:

- *Kill Command* — you landed a ranged, spell **or** melee crit **and** Kill Command is off
  cooldown, i.e. the exact 5-second window in which the button works.
- *no aspect at all* — neither any rank of Hawk nor Viper, in combat only.
- *Mongoose Bite* — something was just dodged by you **and** the bite is ready.
- *Feign Death* — threat at 90%+ **and** FD ready, in combat, party/raid only.
- *Go Viper* — mana under 20% **and** you are not already in Viper, in combat.
- *Back to Hawk* — mana back over 80% **and** you are still in Viper, in combat.
- *Misdirection* — threat at 70%+ **and** MD ready, in combat, party/raid only.
- *Mend Pet* — the pet is alive and under 40% health.
- *Revive Pet* — the pet is dead (this is also why Kill Command stopped working).

**Cooldowns** `(0, -66)` — a horizontal, self-collapsing row of 32x32 icons with WA cooldown
text, tooltips on hover and desaturation while the ability is down: Bestial Wrath,
Intimidation, Readiness, Wyvern Sting, Rapid Fire, Multi-Shot, Arcane Shot, Misdirection,
Feign Death. Talent and late-trained abilities load-gate on their own spell, so the row shows
exactly the buttons your current build owns and the gaps close by themselves. Two of them do
double duty: **Rapid Fire** and **Bestial Wrath** show their *active* window first (15s of
+40% ranged haste; 18s of +50% pet damage) — full colour plus a glow while it runs, the
cooldown swipe afterwards. Kill Command deliberately has no icon here — a 5-second cooldown
says nothing useful; its reactive alert owns it.

**Procs** `(110, 24)` — a cloned 32x32 icon right of the bars for **Quick Shots**, the 12s
+15% ranged-haste proc from Improved Aspect of the Hawk. It pops in with a scale-and-pulse
and flies right on expiry. It is the smaller of the two haste windows the pack sees; the
bigger one (Rapid Fire) lives on its own icon in the cooldown row.

## Spec gating

The pack auto-adapts on respec with zero user action — every spec-specific element gates on
`spellknown` of a spell that is only in your book when the talent (or the training level) is
actually there:

| Element | Gate | Shows for |
|---|---|---|
| The Beast Within timer | `spellknown 19574` (Bestial Wrath) | Beast Mastery |
| Expose Weakness timer | `not_spellknown 19574` (v3) — inverse gate | everyone except Beast Mastery |
| Bestial Wrath / Intimidation CD | `spellknown 19574` / `19577` | Beast Mastery |
| Readiness CD | `spellknown 23989` | Survival (41-pointer) |
| Wyvern Sting CD | `spellknown 19386` | only if you took it (raid SV skips it) |
| Kill Command alert | `spellknown 34026` | level 66+ |
| Misdirection CD / prompt | `spellknown 34477` (+ combat, party/raid on the prompt) | level 70 |
| Go Viper prompt | `spellknown 34074` + in combat | level 64+ |
| Back to Hawk prompt | `spellknown 13165` + in combat | any hunter with Hawk |
| Aspect-missing alert | `spellknown 13165` + in combat | any hunter with Hawk |
| Mongoose Bite alert | `spellknown 1495` | any hunter |
| Feign Death prompt / CD | `spellknown 5384` + combat + party/raid / none | level 30+ |
| Mend Pet prompt | `spellknown 136` | any hunter with a pet |
| Revive Pet prompt | `spellknown 982` | any hunter with a pet |
| Threat bar / threat flash | party/raid only | grouped play |

Beast Mastery and Survival never both light up at `x=44`. Since v3 that is enforced by the
load rules themselves and not by talent arithmetic: The Beast Within needs `spellknown 19574`,
Expose Weakness needs `not_spellknown 19574`, so the two are exact complements — whatever your
build, exactly one of them is eligible for that slot. (Belt and braces: the tracked auras
already made a double-show implausible, since 34471 only exists for the 41-point talent The
Beast Within.) On a pre-5.4.0 WeakAuras the inverse gate is ignored and the aura falls back to
the v2 situation, where the tracked debuff itself is what a BM hunter can never produce.

## Deliberately not included

- **Auto Shot ↔ Steady Shot weave timing.** This is the spec's central skill, and it is *not*
  unbuildable: WeakAuras in this client does ship a Swing Timer trigger with a `ranged` hand
  (v1's README claimed no sanctioned trigger provides it, which was wrong). It is left out
  because it is a design decision, not an oversight — the trigger's own tooltip warns that
  non-retail swing results are inaccurate in edge cases, and a weave bar that lies costs more
  than no weave bar. Bloodlust/Heroism and the "tighten the weave under haste" reading of
  Quick Shots are parked with it, since they only become actionable next to a swing bar.
- **The AoE breakpoint suite** (Explosive Trap at 7+ targets, Volley at 10+, situational
  Survival traps). A plain on-cooldown trap icon would prompt a ranged hunter to walk into
  melee, so these need a target-count scenario gate and a group of their own.
- **A pet health bar / pet unit frame.** The pet decisions the *rotation* needs are covered by
  the two prompts above; a second set of unit frames is not this pack's job.
- Master Tactician (a passive crit proc you cannot react to) and Deterrence (PvP defensive).

## Importing

Copy the whole string from the fenced block at the bottom (GitHub's copy button on that block
grabs it exactly) or from `all-specs.txt`, then in game: `/wa` → **Import** → paste.

Three things to expect, all normal:

- The import dialog shows a **code-review panel**. This pack contains exactly two lines of
  custom code — one on the Kill Command alert and one on Mongoose Bite, both the same
  sanctioned "either of these events fired, and the ability is ready" one-liner.
- The `/wa` **editor preview lies**: selecting a group force-shows every aura with fake data,
  so you will see both spec slots at `x=44` at once, identical fake durations like "55.1", and
  an empty threat "%". Judge the layout there, judge behaviour in combat.
- On a future re-import the Update dialog's **Arrangement** checkbox (checked by default)
  resets any positions you dragged in game back to the string's defaults. Uncheck it to keep
  your own placement, or tell me your coordinates and they get baked into the script.

## Regenerating

```bash
lua5.1 tbc/hunter/generate.lua
```

Run it from anywhere — the script resolves the toolkit and its own output directory from its
own path. It rebuilds `tbc/hunter/all-specs.txt`, round-trip verifies the string (decode +
deep-compare + structural wiring check) and prints the aura count, string length and the UID
continuity report against the previous version of the file. The build is fully deterministic:
the same source produces a byte-identical string every run.

`math.randomseed(20260814)` at the top of the script is this pack's **fixed seed** and must
never change: it is what makes the UIDs stable, which is what makes WeakAuras offer *Update*
instead of creating a duplicate group. When adding auras in a future version, append new
elements at the end of the build order — never reorder or delete existing ones. v2's five new
auras are built at the bottom of the script and re-parented into their groups afterwards,
which is why every v1 aura kept its UID (`stable=27 changed=0`). v3 adds no constructors at
all — it only sets two load fields — so it reports `stable=32 changed=0` against v2.

## Verified spell IDs

All checked on wowhead.com/tbc. Aura triggers carry every rank; cooldown triggers and
`spellknown` gates carry the rank-1 ID.

| Spell | Use | IDs |
|---|---|---|
| Serpent Sting | own DoT timer (r1-r10) | 1978, 13549, 13550, 13551, 13552, 13553, 13554, 13555, 25295, 27016 |
| Hunter's Mark | debuff timer (r1-r4) | 1130, 14323, 14324, 14325 |
| Aspect of the Hawk | missing-check + gate (r1-r8) | 13165, 14318, 14319, 14320, 14321, 14322, 25296, 27044 |
| Aspect of the Viper | missing-check, Back-to-Hawk check + gate | 34074 |
| The Beast Within | BM burst-window buff (18s, 41-pt talent) | 34471 |
| Expose Weakness | SV target debuff (7s) | 34501 |
| Quick Shots | haste proc (12s) | 6150 |
| Kill Command | reactive alert + gate | 34026 |
| Mongoose Bite | reactive alert + gate | 1495 |
| Feign Death | prompt + CD icon | 5384 |
| Bestial Wrath | CD icon + 18s **pet** buff window + BM gate | 19574 |
| Intimidation | CD icon (BM) | 19577 |
| Readiness | CD icon (SV 41-pointer) | 23989 |
| Wyvern Sting | CD icon (SV 31-pointer) | 19386 |
| Rapid Fire | CD icon + 15s +40% haste window | 3045 |
| Multi-Shot | CD icon | 2643 |
| Arcane Shot | CD icon (r1) | 3044 |
| Misdirection | CD icon + threat prompt + gate | 34477 |
| Mend Pet | pet prompt + gate (r1) | 136 |
| Revive Pet | dead-pet prompt + gate (r1) | 982 |

## Import string (v3)

```
!WA:2!DV1A0TXX15SgwXsWooIWsYrs2XW0wkKk2YaGe8HJLDbabfjfbj1cqrQxMyb2HyxXf7UA3f8vIBtyCCzFLMY260MM0eZ04Eo90K0YZPP9KtpPnmX50ZPPn3YF0Z(JM2g12020hNg1)L(NENzw8IeeKwpsm9p4WDND2zNzUFF37DU3bcxiq(pxWLFSnYjLFgzldZegAgwd5ZNVX8f60rndK3q3XYqtJiNqrvt2IOp0nhOKUdXk4thCaIKMJYgvUpLKUu1NMrXIi5yE4nvrW(1KSvUrodlzIvCVpR5bJRPU4IswYbZyyO5OAAn)OtpTnXriNPe(vDmpMx)KjEcSVINk4jdMUK1SQZkPLJ3zkwlWFNRVQfPGQHEMfmjIfSmkzUkVfPvxKSV1u1N2WQOKd2c)RXFaFAlii4BdPsokgwJAsFST)C4cW0Qf8BjLNvrxI2oswo(ZnTQUQTI)44)C8VKJLAHcel7roPL3LVACh6xxQKLuK1PL2Mennvz7Jfiu8s4lLZutAbI1sS6hu22)nSlLJmlovtxA6PvNFTPselDMPsNjMyMkpAmlc(iX0JLC4HVzjBsY5XXvAEpKvuxQiX2)QYKCypqN8wdKC4X6F8Hxbx64dl)RjRAFTs64SzwsejnnZwKyxNH)8ugYKF)3H3Yvs5ceZwsF9sOeiy)L00coHIQdzD(t5R1hyfjDv(IzxWr6FDIKnjTdkXk4OCFWXJRBOt2qgN)0wmfDnXYMGlQY2lrBkDucrIxusvVFim(cqeOdOtik()hEZ1SInrB6Xmu1DYLi5izsk2QQSzGk4lrITrjR8e7BQsRrxs7c4hd)SxETPTWLgCyj5i57Ms65rjC)0QOF(CPtiMm5iR6yKFwE73)yhosjv510MV7HfV(fU08XMr0oVKgX3QOGqKHTSldDguhxf8TkDkPYXmX1mKK9Vg)ZWgUqplhAvBeipZeQYokhEvvS5Pzd2h5DahqaEx)DVdOFONnyTr0WHTAjy2sD3tLnXJnEMrJtFDf4OV4jHJ9Q4c07fECOvrgajhNtIv9yqq)lHqKPOGTSWtapjCs)W7dAdA3FTVhKY8qJJnjycfjkkNyPA7OM32RlGr307cNcE)WtHye6GyQ8L1x4dE2ldDd9Suojp20y3BOthokTS7EOLrI6dHM2souWarzD2CJdIUOae)zpcC81OefSdMc)B5JygWHmVZu2ksYgZnPN6Gvy1rlmp4jqWuECsRWMZN4eMhSMxOkL(g8AlJDGZz(qSAqMUbf5MNjuIhdV9MShGumImRYpYgCP4f9(6RZE(1kHRqtVa0ZQwurdjdwz8rgDKKWXTqacTnRYAy1vh(WEAuBQ5b73sDXGNVKKmfogmtgZqvMttX1mnvDtSPKj5rkM2uMw4f2mKrTlnLhCBWQBoevoHLK5st4DXgv(0mvcJoEMHhCKKERv1asxBWrgjP4uIdE2bYy2(omKqLQ6Ym6S40Aggw8fMzXrxons2QFsQg3J6TiwweAEIDOZ5vMBKsfZrSMfo(k4IkNSTb)FEd7iimPCngEciVBZxv67vt5XMhTDkcQCdoD57SXXPVCke1ckopkK8cRqzo5rlv2zZ5GmFDNJiwSeAyYViR2tMZwvVGgj3aJtvebF4JaF0SXrD55pc8H9hN2D0lUbdKhhFFzk7nsS(6Z8GyxhtMIHiYe5usZRa(HE5QhsuLo9q(3Clvro)dA5rrGd5Vwg0KcRW4J2QYerMiecr1hVzDQDTZAzHdJVOF4H9dVh)RX(edWwwoJfvIvYIiMqJiPlkPzQi5JpiYWFIzBds18oTuEYvsiHKe9cXLSUY4d(0vV7PtZ0PXEnf45rDTOwCWx8fnmkkaFaFIZrjEFt)WZbNbEH1076SKjhz4bVM5CwQ6uf0efVrLQSmrxCKKxiP4AgwQOmIPMC1bgvCWln6izInm03XoPyEfs(z6ho2(wAwjlvjedSKQEcJI5KCerNhkreA1WS1ZCgR8ks6fi2h7KWRX8(zjt0ZeILZcWkql(Vj1fPcmCFfvl0M19YHGZEyyapf5)Pcuf5WGcWqW5GH90s)vQQTvCmJ5iwuTRRysVIYHeQtr7guSxLNLTH6SHX2j9ZW5RvTmioexhmTmkRS3O(G0kqgpDVW4lFe4ccWe3SSAv2q4eNaUiJhbxcNpxgUcC1pc8IcWuyFMfKW3lhKN)LKbcuqWSTTJDZ6VA0CagGcOcxdMb0GIGzwZNS5VkVoWbU(rblbZNP5TERAnrvjqjywyoyEbyb(SAXSWheon8H8bVeL3d)0zHFgkZf(iNewc(OCIn8YSQ(ySYxb(zHLzCw4NRmvf(5rQj8lGKs4xua(LGp(De2h8lFg4ta)kWk(GFv4xd(1RsxUx4vPCf4twHN0t(WlAv8sdj3E3WVPc8PGFl4tdFgOVtDs43gb)(Gp761U6aVwRrcH4(aphSkfWZqh9eLcOJWk8bFEqK)U7d(SWNdEnpAcV9mcc2ekZa(D2gUWN(E2mxyKArXR6W2qa15duhRvbIdIIVbf8x9bzPq8uMh0BVdPvDkXi5mm)UdWJJREOfD0y4(6NG)1mZ7ubRB(uBbAvPrnax1yQH5J3KoPcuEl8NA5enWsz1UOoIeJrGuODgIplcXxJUiJQJPBnYdVB5DlE9jH3D24wsQYzFRnjyFBHe0(5szwk2iJFUqJvhj4zRqcwPY6hYa6MYaA959G0dX2ZBx0IW1G(Xxc(QyJ7T(gZ1GwfITPxruQaUCcVMVAjndrByVm)IJWlzV0MOqbPRQ30Zwl1boQNdMhkXWXsng67)WXsCo0nIbZm4fsYjuFRYeQnQYDWjyw4lbFzQDH)GSWxT1EcHmj0TXkWhQPnjhdl6ukf8h2icvlOZoChsyZqEbtpbkTZvu1YYWsHrZFqueDi)RKRSJoi6Op)BJ4FA445qUd60c7E8XFJvz(smwjnBYsL3RyGWSxzlydZwWDWM3I4qMYQ8gLQdV8jmF2QEHetwEuD7RmbrAMy0nHFLuezvPR45VI9v4BUDk2(ApTtbjg4IQcbXvOwekm7Ds1LTcv5Xsv)GVWAKOXe7V3WJ7CXjzOpQMUx6e547iqHZZGVszRj)XE8k4pPjKQp59E)l)yGqLWVa3ZqMhPY2BttSmr13bttDKQMWQWVWoyk0NiZJwt0wibJJBX2j4eQokQ6MVNkpk58Mg2KG0ffDITnCFW(PZr)W9dpakpFabuE(UHdUpkWmaxhcYUrADTlZv0L)iWJESaHk7oc17eku6ezBGljpnQg6zoWTUAbUe5gvMiXlHo)6jTOYaMW7fwtvl)STNAH2gy(HGy(G4(He(O4XK(PsPLFcMbkCg9Uy(QTrEddnCBu6PNtfD3A9Y3sJ(HYwNYVoFk)7fpCVD3Jy4oI2zV0YOHyLHzLryLDWk7Kvgvms0i9ILDhkCxwyVpQU2czXfTVCdw0SgiMyQ(hF4Ax6E2lFZzieZy0Ty4isrHkmZCOjT4p7F7gf0mMRFlY1lr0ZVaxRuCADkRJ6eoRM32HvwHwxAEOmOxomlonhEn61L3gjRnv3ic7zL36gFdU0AyFXmkQ5zqiFlXUfTfTrUsoog6JIEQRjTaRVgwfBslSVxCEG6w(HyMEB9eMVjDUSQXX157wn(OzYmAk46pk3830mZFn00353DE39GWWir47ah4BFpuK0iDmOrQcYMA9a)58bYRY8LyPYOKSvmh9xAEOYvsvV0NQnDVgOruu3XN88WWzPmi0Qeh9tH0hNR(Zd9VPAE4TudfHJBOPSjMBqM3uLRRmJArc8Ab6GAS558m2Kf(80OvD6WNMUWtPYFaFBg6d)nzHnu2wA9qXdhUdex3zhr6Gv2jRm62aBH)(6bSW)qTqu4FKdlHVNcCdf4FYh8pFy4Fra((8L1)veBb)BW)Up4ha)hW)zlW)1Dcuc8FF3aAqv)F(oIps6z6oz3YNVEKb8)ufs8THF4DyXV)Bjb5Xe7OZo7o8Ush9El5g1klBldSWOpJoJrYLJV8wKMRwTr7F4z3Su9IOuTTfhB4loQYmAxFYTxQ(x9tAP6RxvQgnuy47M9THesQG1mavYQB4SvP7nQVwQ4CN5TujS8fLglQC0PLgQNTxc)xFxtchkoUTG5AD8XG75tvJpCNtvtlycJIfL0LnF4kvhl9yjtKjyQbtNEWroBn(cMYqVGb1hU4OFRMhVs99tulOhSp0fFLGJzzu00XSLkp8SgbVa6HJvnFxA(3c6yeCaP5MX8rQ29Q2YQ42BP2w2A)KcDYp4yehZhQMuVmR6SeALmNjPi4VodbZDFKgTV8K31TR)JRH7gPur900oJVp)CC7)IsA48g6XY2rIMflbQpFO3EvDL2INLkswMxUX8HUYpNx)GU8s9l9bxxEbDPIQ5zBdg9(nUTHLdezLcwQ8KbC)lrVK6KtRI9jQPwu15(Pzyzy6vk3iVHo(51D6xkpUTQCIX6BWXtNZsswTK9l)aOFVRizLN7WfIo9GAvtxAmnILJ9QtxstlHQvEnCO65v7FHa1)1dODB44mcH5qWxyT4AJMQGYGZm5zhA5NegqO5QB(AOq6v4kyzPRIhtMJVsEw8t1mkSA16rb4JBnvFXsf7SjxNf)Clvhv0zZSWBeikKAvEqxdoSrb4jefJnYztYJR5R4k8yyN6ke0v4XP9IRqRUcpH3R5k8KmeXUTPIPNajl8MVClIowigponxpMTqhufi6el18PvmMBu9SBu3TRzZ(NirsEbweAzAygrQiz)V8paoUi7wVKMD0eEo7rjifW9sAhSnwMyBNR2cbKgwed0pye0qYUbUVBT0L7U1RLWVrf7x0hXI4ff3ZJQllreS5qwZhIEnHMY3ABoLFKlFjBhKMgG)FVK5Il0Q5n7AAw6En0BZP9G4(MlzPhSnNlh(QbnSc6C5iE)VJR2EqCWGx15vdIm8MBZGAA4gzHFG4yQZt0QA5GfEGiEbebnH89YsnSGgr(jIbe4hT9oda)FuzAnwiCfEeAYXPPLFqKlBEQQrrGEV9vILtvt1zHP4u2POIqpji3LqRUMP0LmlnV2edUTMwCfUNTX2cD28nGOw0SIpAjhwCrwZwdXo5mWDuveEJi0UIYOBGvNLp4kSmuZ2cMnIxOzSHTrpkzjAo2dxGoAqfcUcphVI55v8gbcdRiWqASQZgyb5deyEHvyHLH2LlvUlPF4nWR1T1Oj(eFKzlLFwMYvJJQn8GT8kYY6BwVLTE7H7SgOAC45tHBLoCxrPBcjCpSYEzBiHVfLWSYiSnA3fDJ2D2j6GuOU7CduXFEfInNJVbNJJM4OzW7wWL4tTvwGRqp1tb459oC0gWbAoQ9v8qTC8kd7Uktvkt1z2nJG7O4MqWUc9AEYndCzQDMAeAM3jtjknlrVFdRICqBScZMhVTplRRVzqRsvqRVMdArafdV6kCg4nCfE(ThL6k8cUc)ummPRqSQ4rxH41IfDfsuge6k0NRqsAx5k0VRWzXoZvyGSUcd(Mgk9L4ECGgpOgQOEvLSVAmC4kCYLKj2oCBzmlyfrucfKNLDx5hMDPY1l23O9v2kw5E2vyY6mC5kCr4XCfUeoKVm(3vCfUAzJtUcVpxH2CfAhR)uUcVFkA0v4PCUkTREAUHgxHt7k8mydcTrDE95keztMkCf6aBwNClcSf4Ump9oP8VSs)oEtO0Vw4otQ5Jx(wDf(466wzl7KA(0ZPoTtAhl1ziCgtO5hR7OHYeBE1Z2e1837BlymVyTPxa(A1NsHEPPua(Z2AceAg2E)hE)neCVwnBDzhG23YAL7m625ysZrwVEDHVVw8fpe)1HY(r4aDCQUzCIUv0wBBhAt0OqjYuSfb2AahRLrBC9f16)8jMy4MG123BBWAF)YynZdxxU8lNSQaph8fBnsieV9fO4j2jKPUS(NfE96pmfWVBnhGIYboXvq0viTRqM78M)zshwI88DNW4pdlTjJ(FSJ1aG1ZSdQX4joWyAhfcliaC8vQPxmCSjYP5ezWMy9)D(2p8LRaHQ36lsZlQhyYvy6MJEE1QON7o4MT3o6DeCtJCw0v4cCKqU2knCIRvSTCfk0eKW9Thaj8eWa772WQw33sw1ELVydTQTETrs7ULzTTF)23nmRHZ06rrC8tHqtEDYfZDHUgF8MGF2)Ed8Z91C8JEDh6I6o7QT2jvFYiW7nIj74mrL3uz9Oz5rFQUgN18i1FWxRXmxfm33QQklTaEDURqX66BxbD8pJap)UaQ(Yn2)RLkhv37cO0BhDB7Sx9V8(BiGmrQXpFIlm2KJjortaKh4TFk02zCcnhX7mqr(mneOSA1y9F3sH2TC0t2zWcoPAeyP3RRxOpn1ZzzUqtal(3dawc5kiaFgA2LkFuGs0hnrpeBhvjTGtG6xuQCuGypcDCuTOQm7Geuj1qSNqJdo9SByx)lmXcZsS09ohshPUxqYuvoy)ObV6Rpf9KZ)0PvmCQKClw9XSYlPtcYEqDFIAnBw)RuZ2eRKQPN6ERjxtUc3)bUDt0KRWdu(CK6k8G0I39wtPKRWblNnjxHwQMhjxHaWb3NRWdbrCfo097kC4wfrH3rWREyCRTVhxHJ6kCmwgHCfoE1ubvZVKPYPwW2v4r3CAGeUJKfOENm(KjJCTuZfzsQRZ7uwNFXAplbH7nA3DYvUSnRJBvTYQ0OUgtBoPfSl7Y0WZ24OCvhuDhuXersFH7ebdqzxQJj2UkVc1F2cCfEjAiC9(DnMLRWzAIM1qHZukwPfBYg7DGFOctHtS7u5H(uvos3RAOxgMTPJPAw4ZdPRCmJItLC10It51I)x8)k0wwDdy7MZUWwm38HRGhwOXUqxR(PBtlo76t6WTpeyHnbbCf(OEI(qxl050AVZCdg(snr0x6oUOV6jhZv4J1ir(Dkb5v)JAOGCLkMt2ZifXzY2jfBlLDOl0PwQZFDXMifNDVRu8CF1gthR16)Egbjoz2obzKbmenhQWq92v6MiiN7TYcYATohVJqDgTz(40mHEMV224YFf)62XSoT0TAqmI69Zo6nP54D9b3SoH(K935KZh1PygRMPdE(7IMF3gHEnGIx5hdgD78l0ybEvh2FRbf)wtk3(0d2H11gCGqli3eP8c7z1r3xJPRRvZ2Q2ll(Y02aDiPhwQ9zJ2eX3I7DnXUnbn2v4A7zmSU5ObxJ4tMyNsl8qfgy2ML7Yp4ExX32KjBxHC7LzDXk0BPyZKtSxPjBIy7d9tmXglaxFC4EoM5HQeVKZxsn)mm9D2vcku47wXek(Wj7pZp(clu1FTBJzzKVrre67EhjIqNTZ8Jf)C9fAKb6Cx)7qGfvNeAg4M6Yw2)ZUchn0T3p0KDNpI3noNrhDhpNrV5Ov)gCkvufY4IZC9CtCELMqPE1YrxEtuQVfloX8WltLB04c3h8n5XqMf(4WuuxCV)NilvitpSOrzrhUbeWA7rAd7b7Zaliey(F4UnmZbkgqoG8YV36(XQEjOx47WsR8lrN6E)QsP)Is)27)T2)Isr26w(rKE(lDPlMmH58lA3rd(rKgWwSJth90Hcm79(s))
```
