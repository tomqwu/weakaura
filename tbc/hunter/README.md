# Hunter TBC — Beast Mastery & Survival (v2)

A single WeakAuras pack for TBC Anniversary (2.4.3) hunters that covers both raid specs:
Beast Mastery (41/20/0) and Survival (0/20/41). It is built from the rotation, not from a
list of trackers — every element maps to one line of the priority list, and anything that
does not change which button you press next was left out. Everything matches by **spell ID**
(never by name), so it works identically on a zhCN or any other localized client.

33 auras: one draggable top-level group `Hunter TBC - BM & Survival` anchored at screen
centre `(0, -140)`, holding five sub-groups you can drag independently. Built for WeakAuras
`internalVersion 45` / `tocversion 20501`; modern WA migrates it forward on import.

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
doubles as the alignment cue for Rapid Fire and Readiness.

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
| Expose Weakness timer | none — the debuff can only exist if talented | Survival |
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

Beast Mastery and Survival never both light up at `x=44`, but not because of the `spellknown`
gate — a 31/0/30 build knows Bestial Wrath *and* the Expose Weakness talent. What makes the
shared slot safe is the tracked auras: 34471 only exists for the 41-point talent The Beast
Within, and Expose Weakness costs 31 points in Survival, so 62 talent points would be needed
to make both live and a level 70 has 61.

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
which is why every v1 aura kept its UID (`stable=27 changed=0`).

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

## Import string (v2)

```
!WA:2!LV1AWTX11zVgwXsWpIiSKCKuSnSSLcLITcaibFOyzhaqqrsrWhlafPEytSa7LyxXf7UA3f8vAsJzuCzFLMYM6mnnPjMPXDMonjTCMM2jtN0wM4mDMM2Ck)rN9hnTnQTPTPpMg1)L(J2Z9Ex8IeeKwpsmD)bVC37E37EV3Z335CUNZfcxiq(pFWLEI1ZjLFAzldZegAgwd4ZNVr8f60rndK3q3XYqtJiNqrvt2IOpWn7RKUdXk4ZgSpIKMJY6vUpLKUu1NMrXIi5yEWnurWE1KSvUrodlzIvCVpR5(JRPUWcswYbZyyO5OAAn3WtnLnXriNPe(vDmpIx)KjEcSVINk4jcMUK1mQZiPLJ3zkwZZFNRTIfPGQHEM5njIfSmkzUcVfPvxGSNvv1NYWQOKd2c)RYFaFAlii4BDPsokgwdBsFST)C4cWuQf8BjLNvrhI2oswo(ZnLQUQTI)44)C8VOJLAHcel7HoHL3LVACh6xxQKLuK1OL2Mennvz7Jeiu8s4lLZutAEI1IS67x22)nSlLJmdovtxAQPuNB1jtelDMjtNjMyMkpAelc(iX0JKCWbVzjBsY5WXvAEpKvuxQiX2)kYKCypqN8w9LCWr6DSbxgx64dl)RkRAF1s64SzgsejnnZwKyxNH)8ugYKFN7XB5kPCbIzlPVwjuceS3sAAbhxr1HSg)P8169TSKUkFXSd4q9UgrYMK2bLyfCuUF4OX1n0jRlJZFAlMKUMyztWfvz7fPnLokHiXlkPQ3legFbic0g0oef))JUXAw2MOn1igQ6o5sKCOmjfpMQSzGk4lrITrjR8e7BQsRrxs7c4hd)SxE1PSWLgCyj5i57Ms65rjCV0QOF(CPtiMm5qR4yKFgE737ihmsjv5v1MRZbfV2fU0CXMw0oVKgX3kOGqKHTSldD6xhxf8TcDkPYXmX1mKK9Vk)ZWgUqxlfAfBeip94QYokhCfvS5Pzd2399a7taEO)M7b6f6ADwBenCyRwcMTu39uzt8yJLz440xxbo8lDc4iVkUa94WtchtKbqYX5Kyvpbe0)Iiezskyll8uWtdNWp8EGwHt6V23dszEGXWMemHIefLtSuTDuZB71fWWB4DHtbVx4zqmcDqmz(Y6l8bN5YqNqxlMtYJnnY9f60HJsl7SlAzKO(qOPTKdfmquwJn34GOlkaXpZHGJUkLOGDWK4FlDiZaoK5CM0wrs2y2j8uhSmRoAH5(pocMYJtAf2C(4h3C)18cvP03GxBzSdCEZhHvdY0nOi38mHs8y4T3K9aKIrKzv(YRZLIx07RVg75xTeUcn18qxRyrfnKmyLXhA4Hsch1cbi02ScRHvxD4d7PqTPM7Vxl1fcoAjjzkCmyMmMHQmNMKRzAY6MytktYJumTjnTWlSziJAxAkp4wNv3SiQCCljZfh37I1R8PzQegESmd2)qj9wRQbKUA)dnusXjf7)C9LX8KBZqcvQQlZOZItPzyyXxyMbhD50izR(jPACpS3IyzrO5X3MoNxzUHkvmhXAg4OlJlQCY268)5nSJGWKY1y4jG8UnFvPVxnLhBE02jjOYn40LVZghN(YPqulO48yqYlSmL5KhTuzNnNdY81DoKyXsOHj)ISAproBv9cAKC9ngvre8roe8rZgh1LN)qWhXFCA3rV4gmqEC89LPS3iX6PhZ9JDDmzkgIitKtjnNc4h6MREirv60J4FJTuf58pSLhfboG)AzqtiSmJpARktezIqievF8g1P2X2RLfoi(I(Hh1p8U8Vk7t0hBz5SwujwjlIycnIKUOKMPIKp(Gid)jMT2pvZ7us5jxjHess0lexY6kJ1)Zw9UNnntNg71uGNh11IAXbFXxWWOOa8(9jolL49n9dphCw4fwvVJZrMyOb7)QMZAPQtvqtu8gvQYYeDXHsEHKIRAyPIYiMAYv6ByX(V0WdLj2Gqph5eI5vi5NUx4i7zXzKSuLqmWIQ6jmkMtYreDEOer4ygMh7SN1kVIKEbI9rob8AmVFw0e9mHy5mpSm0I)BsDrQad3xr1cTzDUui4Che6Ztr(FKavro0VamaCEyqpT0F1QABfhXywIfv76YM0ROCiH6u0Uof7v5zzBOoByKTt)mmATQLbXb46GPLrzLDh1hKwbY4P7fgBPdbxqag)MLvRYgch)4Wfz8i4s485YWvGx8LHxsaMe7ZSGe(E5G88VKmqGccMTUvSBw)vJMdWauav4QW0GguemZA(0n)v51boW1omyjy((AER3SwtuvcucMbMfMtaMNpRwil8bHtd)u(GpeL3dF4SWpnL5cV8jGfHpkNydxNv1hJv(kWpdSeJZc)SLPQWphsnHFEKuc)ccWVi8XVJW(GFPZcFc4xgw2h8RaFs4xTkD5(GxLYvGpvfEsx5dVGvXlnG8j7e(1uGpn8RdFg4Zc9CQta)gi43h85wR2vh41owKqiUpWZbRqb8m0rxrPa6iScFWxae5V7EGph85HxZJMWBpJGGnHYmGFZTGl8zU3nYfgQwu8koSneqD(a1XAvG4GO4Bqb)vFqwkepL5(927qAvNsmsodZVZa844QlArBngUV2X5FnZ8ovW6MpZMGwvAudWvnMAy(KnPtQaL3e)PwordSuwTlQJiXyeifA7H4ZGq8vPlYO6y6wJ8W7wE3IxFc4DMnULKQC23Atc2ZMibN88PmlfBOXoFOrQJeCMkKGLRS(HmGoPmGJ98Eq6by75TdAr4Aq)4lbFnSXDxFJ5AqRcX2WRikvaxoHxZxTKMbOnSBMFXr4LSxAduOG0v1B6zRL6ah1ZbZdKyWyPgb99FWyjop6gr)z6)cj5eQVvzc16v5o4eml8LHVc1UWVBw4RDSUcHmj0TXkWhQPnjhdl6ukf871icvlOZoChsyZqEbtpbkTZvu1YYWsHrZFyueDa)lNRSJoi6Oh)BH4Fk4O5qUd60c7E8XFJvy(smsjnBYIL3RyGWSxztydZwWDWM3I4qM0Q8gLQdV8jmptvVqIjlpSU9vgNinDm6MWVskISQ0v88xX(k8n3ojBFTN2PGedCrvHG4kulcfM9oO6YwMQ8yXQFWxyvs0yI92D4XCU4em0hvt3h64547iqHZZGVAzRj)bE8k4pSjKQp199al9eGqLWVa37aMhQY2BttSmr13bttDKQMWQWVWoyk0NiZdxt0wibJJBX2j44QokQ6MVRkpk5CMg2KG0ffDITnC)WEPZr)WdapikpFqbuE(oH9VhkWmaxhcYUrADTlZv0L)UHh7ibcv2DeQ3juO0XZ2axsEwun07BF36Qf4sKBuzIeVe68RN0IkdycVxyvvT8ZCYuZ3AFZnaeZhe3pKWhfpM0pvkT0tXmqHZOhI5R265nm0WTrPNEwv0DR1kFln6hkBEk)68P8VD8WD3zxIHBlA7DtlJgIvgMvgHv2gRSDwzuXirJ0nw2zOWDyH9(W6AZNfx0(knyrZQVyIP6DSbRDP7mx(MttiMXOBXWrKIcvyM5qtAXpZF96f0mMTxlY1kr0ZppxRuCADkRH6eoNM32HvwMwxAEOmOxoilonhCv61L3gjRnv3ic7zL36gFdU0AyFXmkQ5zqiFlYUfTfTEUsoog6dJEQRjnpRVgufBslSVxCEG6w6ryMEp2XnFt6CzvJJRX3TA8HZKz4uW1EmU5VPyM)AOPVr3zE39WWGir47a77BFVuK0qT1VrQcYMADb)j8bYRY8LyXYOKSvmh9NBEGYvsvV0JQnDVgOruu3XNAuyWSugeAvIJ(Pq6JYv)5H(3qnp6MQHIWXn0u2eZniZzQY1vMrTibETaTrn28CEgBYcFbA0QoD4ttx4Pu53VVnc9H)QSW6kBjTEG4Hd3gIRBVTiTXkBNvgDlGTWFB9aw4VRwik83ZHLW3tbUHc8p4d(hpi8pjaFF(Y6)mITG)f4F1h8dG)n4FVf4)4obkb(pVBanOQ)hTT4dLE6ot2P8O1JmG)RQqIVn8dVdl(9FljipIyBT3ENH3r6O3Dj3OwzzBzGfg9P1zmsUC86BsAUs1gT3bNzJs1lIs1wxyKbV4WktRDTj2AP6FXpPLQVEvPA0qHHVB2))oHKk6KVO0irLJoL0aDT1IU)Y7AIUqXr)9N9yJncCVF6ACo78QAAbtyuSOKUS5JwP6yPhjzImbt1F609p05QXjVug6fmOoNfhDi18OvQVxIAb9G9G(UReCelJIMoMTu5HNZi4fqxxSQ57stSwqhJG9jn70MV7QDVQTSkUVvQrJn3pPqV3docXX8rQjNkZOodHwjZlrk08pLbn5(fsdJxEYdD76y4Q42mkvupnTZ4BGph3WUOKgoVHUSSDKOPNsG6mh6gxvFKT4PFIKL5(AmFOp6Z61pOVSuhoF41KNxxQOAE2(Br3AJBBy5arwUGLkpk)pWI0lPEVCmXEe1ulQ68a0uNmi9kLBK3qh)86o9kLh3VuoXy90)yPZzjjRwY(6pi6q7Ysw55EsHOtpOw18GgtJy5yVYuL00sOALxdhQEUR(NjqDmDFA3gEeJqyoe8fwnU2WPkO0)0tCUbw6PH(eAUEKVokKEfUMtwEO4bB5OlNNfyunJcRuTEua(Kwt2tSuXoxY1ybg3s1rf9Iml8gbIcPwHhn1GdAuaEkrXydDUK8aw(kUcpg2PUcpURWtq7fxHGUcpP3R5kWre70MkMECKSWB(sTi6yHy840K4y2cDqvGOtSuZNwXy2H1ZUED3UQn7FIej55zHELzjyiPIK9E9FaCur2TEzd7Wj88IJsqkGBs0oyRSuSEsZaS4Muq3WIyGo4IGgs21XnuRLUC3TwTe(1RyyI(iwOSO4EE4AzzyGnhYA(i0Rj0C5wBZP8JC5lz7G00a8)7LLwCHwnVzhtXYJRHERoNmiUH4sw6bB15YHFXGgwbDUCeV)32lEYG4GbVQ9xmiYWBUXaQo)BKf(bIJOohrRQjb2((J4fPd02W3ll1IbAD4NiM8HF0wBLh(FOY0ASq4kCeAwVP5BVFKlBEQQHhGEV9vILtvt1z(j5u2jPIqpji3xpRoMU0LmlnN249VLMwCfUNTW2cD28nGOw00DpCjhwapw1wdXo5mWTkveEJi0UIYOBGvNL2)YSupZ2BLnIxOPIHTdokzPTCShopD0GkeCfodVI54v8gbcdllWqASQZgyE59fyoHLzXBH2LlwUlPF41XR1T1Oz0eFKzlLFwMYvJJQ19GT8kYY6BwVLTE7HBVgOA8K5tJ7roChrP7UiCxSYUz70GV3JWSYiSDq3bDh0T3o65tOoBFDuXFEfInNJVoNJJM4OPM7wWx3tTzwGRqh1tb4j0oC0gWbAoQ9v8qTC8kd7Uctvkt1z2nIGBR4gqWUcDAEIncCzQDMCiAk1jtkkndrVxdRICqBScZKhVThlRRTrqRsvqRqZbTiGIHxDfE)WB4k8CBnk1v4SUcppdt6k8cvXJUcFGAXIUcXkdcDfI7kKG2vUc94kKe7mxHEZ6kCU30qPVm3Jd04b1qf1RQK9uJHdxHNErzITd3wgZcwreLqb5zz3v(HzxSC9I9mCpLTIvUNDfUqDgUCfghEcxHjWH8fX)UKRWLlBCYv44UcNWv49G13QRWjPOrxHt58I0U69Yn04k8mUcpl2GtVEDE95keAdMkCfcJnlc3IaBbUDZtVDk)lR0VT3ek9RfUZKA(4LVvxHpUUUz2Y2PMp9SQt5K2XsDAcNXeAUr6mAOmXMt9Cnrn)9(2cgZlvBEdGVE95kOBAUcG)4nNzGMHT37b3Bdb3RwZwx2gO9TSw52JUvoM0CK1RxxC5RfFXJDFDOSFeoqtt1nJt0nJ2ADRqBIgfkrMKTiWwd4yTmAJPVGwVJMy8bBcwZ3BBWAF)YynZdwxs6lNfQaph8LowKqiE7lsXtSJ(sDPZpl861FkjGFRAozeLJiIRWiUcJ6kiEN38pt6WYqNV7eg)zyPny0)JDKgaSEFBJAmEgbmMYrHWccahFLAQfchB8CAor6Vjw)VV3(HVCfYt1B9LOj80dm5ki3C0ZRwf9C3b3S12rVJGBAKZIUcz4iHCTwAWexTyR5kuOjiH9Slaj8uqF752WQwN3sw1ELVudTQTwTrs7ULzTTE)23nmRHZ06rrC8tHqtCnYfZDHogBSMGFEh7oWp3FZXp61DAkQ7qPES2P6tgcE8iMSZPevEtL1dNLh9P6ACwZdv)jATgZCvWCFRQQSUAaVo3vy666Bxbn8VIbE(Dau96n2)Rflhv37cO0BhDBBVx9xFVneqMi1yJM4cJmXiIJ3ea59)2pfABpoHM83ThOiF2gcuwPAS(VBPq7wo6jBpybNuncS0910l0JM65TmNVjGL9UlaSec(FHpln5sLpIpj6HMNhITJQKwWXr1lkvoIpShH(nQwuvMDabQKzi2tOHbNEMmSR)fgF(ziw6ENVOdv3lizQkhSx0Ex91NIEI4F20kgovYTfR(yw5L0jbzpOUprTwnR)vQzxIvY00ZCF1KQjxH9TVB38m5k4V85d1v4bPfp0MZOKRWdxozsUcVZQPrYvy)W(3JRqlqexHapGRWJCmruIDa8QdI7S9qUcpQRW7ILqixHdxntq18luQCMfSDfo6gZcKWDKKa19eXNizKRMA2itq9CE7YM8lv7zeiC3r7SDUULTyDCZAvwHg01yAZknVDzpMgCMghKR6GQBJgMis6ZFNiwak7qvmX2rPvO(ZmGRWhKgbxVFVIz56BMIOznq4mLIvAHMSVEl4hQW03e7ovAOpvLJQ9kg6LHzB44NMf(cq6khFO4ujxnT4uET4)g)VcTLv3)1o5mjSjRnF4k4H5BSh01QF620GZo(emC7dbMFdqaxHx2t0h6QHoV2jBpx)HVute923Xf9vpryUcF0gjYVtjiFXF)gkixUI5KDnsrCMSvsXwtzh6cTRLA0Rj2ePOZUxP45)AnMowR1)DncsCYSvcYi9ziAoqHb6UJ0nrqw6TYcYATohVTqThTz(40mHEMV(w4XFf)622Ko9rUvJHruVForVjnhVJp)x1j0NO32NyUOofZy1mDWZCx087wi0RbuC9Fmy0T9VyJf4vDy)Tgu8BnP8jNQ)2SUA)9fAE5MiLNDxRo6EAmDD1A2w1UzXxMw7Rnj9WsNCMOnr8n3UxtSBrmJDfu21yyDJbdUgXNmXoLw4bk03mnl1LZV7v8TfjY2vi7UzwxScDxk205e7wAIMi2w4NyInA8T(4W9EeZdujCjJwsn)0m1D2vIju47wHek(Gj7nZp(Iku1FeBJyzKVrbe67EhjGqNR98Je)89eAO(AFh)ZlGfuNeAg4E6Yw29Zochn0T3VFKDMlI3noLrhEBpLrV5yvVkNrfvHmM40xl34JQ0eg1NSCSL3aJ6BXIsmp4Yu5gnQWXHVjpcYSGhhMI6(aE)pwwQqMEurJYInCd4F12J0g2f2NbMxiWC)WDAqMdumGCa5LE86(nOEjOB47WsQ8hKo19(XIs)HI(T37BT)HIIS1n9BdD0lDPlMmH5Cly3wd(THgWwSTth90HcmZ99H()c
```
