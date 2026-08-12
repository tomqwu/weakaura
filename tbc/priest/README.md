# Priest — All Specs HUD (v2)

One pack for Discipline, Holy and Shadow on TBC Anniversary (2.4.3 client,
WeakAuras internalVersion 45). Copy the whole string at the bottom of this file
(or the contents of `all-specs.txt`) → `/wa` → Import → paste. 29 auras: a
top-level group holding five draggable sub-groups. Spec-specific pieces load
through `spellknown` / `not_spellknown` gates, so the HUD reshapes itself on
respec with no user action, and mutually exclusive pieces share screen slots.
Every trigger matches by exact spell ID — all ranks, never by name — so it works
identically on zhCN and every other client. There is no custom Lua anywhere in
the pack.

**The `/wa` editor preview lies.** Selecting a group force-shows every aura with
placeholder data: load gates ignored, identical fake durations, empty `%` on
threat, simulated clone slots, mutually exclusive auras (Shadow Word: Pain and
Weakened Soul share a slot, Vampiric Touch and Renew share another) visible at
once, and no real animation or condition behaviour. Judge this HUD in combat,
not in the preview.

## v2 — rotation fixes

An adversarial rotation review judged v1 against one standard: every element must
change which button gets pressed next. These are the changes it forced.

- **Weakened Soul now watches the heal target, not you.** v1 tracked `6788` on
  `unit = "player"` and gated it behind `33206` (Pain Suppression, the 41-point
  Discipline talent). Power Word: Shield is the #1 Disc/Holy press and the only
  thing that stops it is Weakened Soul *on the person you are about to shield*, so
  v1 answered a question the rotation never asks and hid the answer from Holy
  entirely. It is now `unit = "target"`, still not own-only (any priest's shield
  blocks yours), and loads for every priest **without** Shadowform — the exact
  complement of Shadow Word: Pain's gate, so the shared `x = -66` slot is still
  provably occupied by exactly one aura.
- **New: Renew on your target.** All 12 TBC ranks (139 → 25222), own-only, in the
  slot Vampiric Touch uses for Shadow. Icy Veins ranks Renew third in the Holy
  priority list ("keep this HoT up on the tank and anyone taking consistent
  damage"); v1 had no friendly-target buff tracking of any kind.
- **Mind Blast and Shadow Word: Death glow when they come up.** These are the two
  presses the Shadow rotation cancels a Mind Flay channel for, and in v1 they were
  indistinguishable from Lightwell in the same 32px strip. Both now light a violet
  pixel glow the moment the cooldown ends. Shadow Word: Death's glow additionally
  switches **off** below 50% health: the backlash is the one thing in this pack
  that can kill you, so the HUD stops asking for it when it is dangerous.
- **Shadow Word: Pain's re-cast glow moved from 3s to 1s.** SW:P is instant and
  ticks every 3s, so a glow at 3s remaining was instructing a clipped tick — a DPS
  loss. Vampiric Touch (1.5s cast) and Vampiric Embrace (60s, no tick to clip)
  keep the 3s lead; Renew gets 2s.
- **Vampiric Embrace got the expiry glow its row-mates already had** (v1 shipped it
  with an empty conditions table — the only buff timer that expired silently).
- **Shadowfiend prompt moved from 30% to 50% mana.** The fiend returns roughly a
  quarter of your maximum mana over 15s; firing it at 30% wastes part of the return
  and five minutes of cooldown.
- **Prayer of Mending no longer loads for Shadow** (`not_spellknown = 15473`), and
  the **Fade prompt is combat-gated** like the other three alerts.
- **The health bar turns red below 40%**, the same number the Desperate Prayer
  prompt fires at, so bar and prompt read as one danger state.
- **The always-on icon layer fades to 50% alpha out of combat**, matching the
  health and mana bars — the buff row and the whole cooldown strip stayed at full
  opacity in v1.

Not changed, deliberately: the health bar, mana bar, Fear Ward and Lightwell all
stay (each one answers a real question), and no element was deleted, so this
string imports as an **Update** over v1 with every UID intact.

**Known limit — threat while healing.** The threat bar and the Fade prompt measure
your threat on *your current target*. Holy and Discipline target friendly units, so
both stay hidden while you heal. WeakAuras' "At Least One Enemy" threat option
cannot fix this: the prototype's final hidden test is
`WeakAuras.UnitExistsFixed(unit, false)` and `UnitExists("none")` is false by
definition, so a `none` threat trigger never activates. A healer-facing aggro
warning needs a different mechanism (a boss-unit or nameplate scan) and is left for
a future version rather than shipped dead. Also note that WeakAuras deletes the
whole Threat Situation trigger on Classic-family clients that do not expose
`UnitDetailedThreatSituation` — if the threat bar never appears on your client,
that is why.

## Groups

**Resources** (`0, 56` — three 172×14 bars stacked flush). Health (green,
`y=-13`), mana (blue, `y=-27`) and threat versus your target (`y=-41`), each
with a floored percentage on the right edge and a 1px border. Health and mana
are always on and fade to 50% alpha out of combat (a second Unit Characteristics
trigger feeds the `inCombat` condition); the health bar turns red below 40%,
where the Desperate Prayer prompt fires. The threat bar carries a bare threat
trigger, so it exists only while you are on a hostile threat table and vanishes
by itself the moment you are not: it runs green, turns orange at 70% of the
tank's threat, and red the instant you actually have aggro.

**Buffs** (`0, -16` — static row of 40×40 icon timers with time remaining
underneath). Shadow Word: Pain (all 10 ranks) and Vampiric Touch (all 3 ranks)
show only your own DoT on the current target; SW:P glows at 1 second or less
(instant cast, ticks every 3s — refreshing earlier throws a tick away) and
Vampiric Touch at 3 seconds, which is its cast time plus a moment to react.
Vampiric Embrace shows your own debuff on the boss for the raid-healing/mana loop
and glows at 3 seconds. For every priest without Shadowform the same row becomes a
healer row: Weakened Soul on your *target* takes the SW:P slot (icon up = you
cannot shield this person; it glows in the last second, meaning "shield again
now"), and your own Renew on your target takes the Vampiric Touch slot, glowing at
2 seconds so the refresh is already in flight when it drops. Inner Fire sits on the
right for every spec, with its remaining charge count large in the centre and the
time left below. An empty slot in this row is the refresh prompt.

**Alerts** (`-150, 96` — dynamic group growing upward, 40×40 glowing prompts).
Each prompt slides in from below and flies up, shrinking and fading, when it is
handled; the stack re-flows automatically. Four prompts, all combat-gated and each
requiring both a state *and* the ability being off cooldown, so none of them ever
nags uselessly: Shadowform MISSING (red, Shadow only — you dropped form),
Shadowfiend (violet, mana below 50% and the fiend ready), Fade (orange, threat on
your target at 70%+ and Fade ready — the only threat dump a priest has), and
Desperate Prayer (green, health below 40% and the racial ready).

**Cooldowns** (`0, -66` — dynamic group growing horizontally, 32×32 icons).
Blizzard cooldown swipe and numbers are on (no WA `%p` text, so OmniCC users do
not get two numbers), icons desaturate while the spell is down, the strip dims to
50% alpha out of combat, mouseover shows the real tooltip, and the row
auto-collapses gaps left by icons your spec never loads. Nine cooldowns in fixed
order: Mind Blast and Shadow Word: Death (Shadow gated, both with a violet ready
glow; SW:D's glow is suppressed below 50% health because of the backlash),
Shadowfiend, Prayer of Mending, Inner Focus, Power Infusion, Pain Suppression,
Lightwell and Fear Ward. Mind Flay, Smite, Circle of Healing and the rest of the
filler are deliberately absent — they have no cooldown to watch, so an icon for
them would not change which button you press next.

**Procs** (`110, 24` — dynamic group growing right, 32×32 cloned icons). One
gold-glowing icon per *active* Holy proc, so two procs show as two icons side by
side: Surge of Light (your next Smite is instant and free) and Clearcasting from
Holy Concentration (your next Flash Heal / Binding Heal / Greater Heal is free).
Each pops in with an alpha pulse and slides off to the right when it is spent.
No load gate is needed — the icon can only exist while one of those buffs does,
so it stays silent for Shadow and Discipline.

## Spec gating

Everything is class-gated to PRIEST. On top of that:

| Element | Load gate | In practice |
|---|---|---|
| Shadow Word: Pain timer | knows 15473 Shadowform | Shadow |
| Vampiric Touch timer | knows 34914 Vampiric Touch | Shadow |
| Vampiric Embrace timer | knows 15286 Vampiric Embrace | Shadow |
| Shadowform MISSING alert | knows 15473 Shadowform | Shadow |
| Mind Blast cooldown | knows 15473 Shadowform | Shadow (baseline spell, gated on purpose) |
| Shadow Word: Death cooldown | knows 15473 Shadowform | Shadow (baseline spell, gated on purpose) |
| Weakened Soul (target) timer | does **not** know 15473 Shadowform | Discipline, Holy, and any non-Shadowform build |
| Renew (target) timer | does **not** know 15473 Shadowform | Discipline, Holy, and any non-Shadowform build |
| Prayer of Mending cooldown | knows 33076 **and** not 15473 | any healing priest ≥ 68 |
| Pain Suppression cooldown | knows 33206 Pain Suppression | Discipline 41-pt |
| Power Infusion cooldown | knows 10060 Power Infusion | Discipline 31-pt |
| Inner Focus cooldown | knows 14751 Inner Focus | Discipline and Holy builds |
| Lightwell cooldown | knows 724 Lightwell | Holy 40-pt (optional) |
| Shadowfiend cooldown + prompt | knows 34433 Shadowfiend | any priest ≥ 66 |
| Fade prompt | knows 586 Fade, in combat | any priest ≥ 8 |
| Fear Ward cooldown | knows 6346 Fear Ward | any priest ≥ 20 (all-priest spell since patch 2.3.0 — no longer a dwarf racial) |
| Desperate Prayer prompt | knows 13908 Desperate Prayer, in combat | only races that learn it |

Shadowform (15473) costs 31 Shadow points and Vampiric Touch (34914) costs 41, so
neither can coexist with a "not Shadowform" gate: the two shared slots at `x=-66`
and `x=-22` are single-occupancy for every possible 61-point build.

Ungated (always loaded for every priest): the health, mana and threat bars,
Inner Fire, and the Holy proc clones.

## Regenerating

```bash
cd tools/tbc-weakaura-creator/scripts && ./setup.sh   # once per machine
lua5.1 tbc/priest/generate.lua                        # rewrites all-specs.txt
```

The build is fully deterministic: fixed seed `20260815`, no clock or randomness
beyond it, so re-running produces a byte-identical `all-specs.txt`
(sha256 `2f32d97f6d69f2ef0ee76db63d11a02948697128737908615988685e4991c346`,
6594 characters, 29 auras). When editing, never remove or reorder existing
`W.uid()` call sites — append new auras after all existing ones — so re-imports
offer "Update" instead of duplicating the pack. (v2 does exactly that: Renew is
built at the end of the script and re-parented into the Buffs row, so all 27
v1 auras keep their UIDs.) The script prints a UID continuity report against the
previous `all-specs.txt` before overwriting it; expect `changed=0`. On an update,
WeakAuras' Arrangement checkbox (ticked by default) resets any positions you
dragged in game back to the values in the string — untick it, or report your
coordinates so they can be baked into the build script.

Note for anyone who imported the earlier priest draft string: v1 was a different
pack (it added the Weakened Soul timer, the Shadowfiend and Desperate Prayer
prompts, the Prayer of Mending / Lightwell / Fear Ward cooldowns and the Holy
proc group, and dropped the Shield prompt, Silence, Psychic Scream and the Fade
cooldown icon), and its UIDs do not match that draft. It therefore imports as a
new group — delete the old "Priest TBC - All Specs" group first. v2 is a true
update of v1 and imports over it.

## Import string (v2)

```
!WA:2!TV16ZTX11DVcwXsq2Xsqw0w0wX00wYskwYaGaeGYsUgGe8L4ZfGsIYoMyb2lXUIl2D5Ul4dLMKkMex2hPTMTXtBQBIktA6mD6RHFWtFKKPHtN8HmPTNG2MUUnPzQsB)w70Q)c65E3fpjaeLeLNeM(bUC379U39(43VF375CUG7s(YEZNz1NTygHSZjAOP3RMIMXWE84zcp(pByDFz1uTm0uuiI9kjRiAqup3TNWqMyA1Xz6yqIGILuXYppQGQqLCtjzqeSUvgndrIrC36x)GXvKV(1fme7iLMMILSUXsJp7SMelUm6cy1BP3MBnKkEVyTetrPJK6KSMzCQijJLDk)8RBqYjRPMAzDcFodTc6R7uIKYxNS3nKvNvZiVGfwcVB4KHtFJJJZtrHcwsAgJRtZ20BgSxoRCoVgczzj0nVPLGHL3mZkRkBk5no(plVRyziNlhXWCSty4E77e3I(1fkyieCt6vtDIIISOz7(8hVa(sz0vewMyScl9Hen9ElZczilGDZKfMDw5L2yMEJLm1mjtfJpv5SMWGGzXNCIeJmYTlyssSe2Us6udP5vfYtm9UUijdwd0oVXGjgzI(NAK1kO62S8UHOS51kOI9Mfibfuu0pKa7(uo5pQMi5p8HChUsiMJOFOKZxah97O)c4W9LLKTiB6KRZy9(xtqv2zWSB4i9VjrWKK0cNTYzj9iq7Xv1ujffX(pTeZqhtmmj4GQO5k0IsBLqG45fKv7h8JVaeaccDbHW)3w9PSMjrz2j0KvTY0BIXsLGVtzrDFLrv8etTcgzjM3glbXqvq5s4hd)SV(gZAGdnyZsWsWZTfuZIZW9ttI(5ZKSx(ejgBDlTSl4u(9nXrcwqwCJqAxtmu0asNCXq8MzfuiEwhNi4zylZsqNHuXrbpRt7sYoyM4kAcIE3W5ZWAUqKv9VUjcIN7YYIwshzDzS4jzn2N5HG9Xbp63)HGeqKISYWRzXgT40punptNBIhBQuJhN(6sWt9MNao67Gdqhd6aEoEgajJdXdt6JapR3vqiYmuWwAOt45HJ7fob8IWj9w97bJO)etHfPJELeOOCIHSPLCwt3QagRU3fofCA4JIyeAJyMSLef8a986q3qKvYi4YMM4H9F2aHPxJeLEnyypi00uWIcgisBY6BoGOP5GyNRnO9nOefScMb)B1209zrwYAgtjbrTfVIRuWAS0Ox0p4XrWuwStlX6Zh)46hSQxOcL(woPwc7adRFywkitxJICZYMuIhdF82SmqkgrKL4nk6mloT7xFtw(xRaocn7YqK1nOtnKuyIXhB8XsaTBGaeAzwNvWkJoon7zrjt9d2VH817yYccIu4yhPsP7VCFAghLPzQPJnJijlsXuMr3aVXKHmQEOPuJRilTfru5Lne0x5YU3uS8NMjjm(uPgzOXs4owvfiDJHgBSe8ZWp0adMs)u3HMekQQkYOZ8ZQOPz4mWSa26YOqsx5tsvCpQ7GyPPq9JFhQCNeZmwH8ziglaTVgoO6q2k68p3MDqeMukfn3ji3hZwz23nLsTnxA7meuCdotPNmX2PNmse5Cswhd67sRrzozvemntNXcz(QwTXNVaUOKxEwQNiJPSAofsMj4hkrYuWNQnyL0XrT8STbFkVXPvh9MBXa5XX3xKYEdgRV(0piw1XePyiIirCuHLKG9drDKh6TcDYN36lPmY5FmdxkcCyVvZGUc3Am(OPSiHNnfcVmvpUEn1W3zvw4jWx0l0Mx4j9Ub7tmiBy5cg0zScge(EvicQ8ck6scECAePCYr)KdrvENvil5n6vajjQ5Ily8gtn0zQ80zsY00yVMeCbuRfvXbpXVUMwEo4CE4xKs8(R9cVcCE4v3yCLjtUSyg9Clg1qwLkqtKCBvYIIev(XsCPe8BOHlcO6itU(GJZp0vhFSuXgb690NGpRej7C9dhDVRSGGHSaIbwrwTxT8zeS4xqqPaHRtn9oVWfmYkjOMJy2(jGBY2IZk64UsigwldV9jGFhSg8aFXI1GuHB2zi)4B778WVl91gM(E9We(c6C1dSomjCqV3MUlQCmwtzHjAHXfgG(pcmG7YaFno6YaWGCWqWWWfD14FVkA18tOTiXGQnVMo9okdKRgz6IuKB58s3qfFy87K6omr1I6WKd7OGZgxO32d2Z4LGKUc3qQvBdMIdU0TlPjZAbh)4WvyKqyAS7Cv41H34gWhJdEtSkNbsJVNaKX5dLfeHz50pzZKgy1xvYoGkKdKaz4AWCGcOLw)fA9R6Kgyc6hfMNt)LBDP3QKlQdbwqbybyroyjNE1YPHRdNb(4EGFwQOb8jsdFskTh(5obCdyfhvb4tZs6ZWU(zH3c(5zeEy1s8C4xa51WViYOHFjo4xg(C7iux4x5cWVk8RbVThyn4xh(nQW1Ey4ZtjAW7uMKfDSqZkhrorUmPGFtj43c(cWVn8UqVT7G73l8fHVeCtxEIduNHeqW9BJGB4R0e487UN6HZJvnqCDlMDa0DFGISg5iwiq8wu8BLmstrPJOFqhtg6iPSvbglNbB32y2O0lD1yi7Mh35RPN1QmEv)L2c8OCHAa2OXWB9NRfvsz44w4avJRBWsLvQIAidmunsd29at37wGPZtgnF4ukZpYvJxdm90LLNxR8OdknhHkn35R6cyhMz3A30lbyQYLFjEHCOYmCtpvJVBUuE1O9Nf4kBrmSNRPF0YgJKKT1SoOBcRJjqRB0FYYzDjH86YgYzrZClKvQQ3PCgjYNb3koPS9UNPJlteMJOse7aTAqr)WLtFivvIrh9lBqUvv2bPswe(qWJq5G7h8chqcE0hLdN8(WWJVxAp4qo4cCofNmREYOm)8PHNbnuT0Qe0fnO8TxiDdwP4LqO1z3)9oya5Q40DLMFC04vtkjgN7PZ7u8ao5RpGFRHeJf6ulna8AEGyEH4EGE9c95LQXS6ZZeDWE0JYwcTywnnfCcqn5IY4QGBw6rQjTs12LPRW(vD6Y)bbdhTNGH7juWEI4pyp9emEWiDhHpGFmv21UyxdXhmCxy60RrnWADCvfKJDm4pUbdwgdgJFu0g87LfH751V9CeIEm6(kT4P6EsmPnugl25(EfZPOTy)gK5lquZUSJyxCAAsBIAOdO4AdK0A00s6y)k92rygNFKnO3xY2bwzQS7twEL2VUJvn0uyFXusYzNtLyA6zf2JO(tXmfSS0uhh3EMIWYS6AezSihI99I74DMvpmtUTZJRFxUPGkcIB6yIs8XtLA8rb9J5i5nltYRHYDtc9Tak3XwtH5OL5uXPRsYFF6TicUELcTVZpVRy4JbxePrFdyFV0dJ4Wq9oU)lk19ObMBs(QS(9ZZwHzLs4S0LLX(Z0FIsjs3LCFYM0TGkMMQ49otcxmnLdIQzo8hkPGsoqoIl)PUuABlPq5ivjbElYsOicBnYuY5jWn9fGQRDExDT0W6uNyC2aNLo1SnxF)CEQNFb)vPHVzZjsNJVRq9eie7A3SRrGVtZyiWFZ9g3a(BRMna)DomaablFxjOOh4V)iW)ah8p6m)89qym8pb2EG3h(NH)LdbF)Dcaj8dUlqHW)AZbEWpCFRMPE8MchI3IV0fV2q(V0IZFQGW)w1yn4wvaz)5Wp6bgGc(3rmux1HHG)JhuqN25deoy0U))Hl3b4YR8E1dxodIwiMxxkPHK40NQ)MJw(l2fGwkTjL4DhjA0FkhPO7JU(MQM1wxJ7w1MkDrTMUP)AxNl2vjdn1KlfEHPNV5iP)Yh0iPaFGHKUoU3VOXJeiy0GD7py8a(93nUzVEchGDniUzVqDfOvBi((eOn89dqZ8EhOfb0FohG2oeS9j3oW2TJrOLXJFweo2DKREj(5o1KzirBoC8RTJdhB)b1YCF7Gb6QN4D7psi6LW0lDtVeHEjkfZfmc7QZ99qn2iqy8AWGbyxd2IviFXFkzfY)RsyO)7TNWgBdvlo1adn8udCP8tfU5iPV(dAHTG3hcB(JNdT6SZPMa2ZW6pDDUCG6MOogDOKjhASb2AMYevXoMWqlVUL(tuoZ(fejLsTJYP2hbx4GgRomjAOQDlbZZcuy(3KbZD8La1F(zjp29RZe2aTOQqE1K0kZXrEzCm2JxqroNkeXW0sGgNAoQdaqt)R4(fdN4qtsZC5XR5zfCiYTEoGeZjfp2MIlRkKxol7ibap(EJBQzybbwlNHSt4(oWk0BPw02jFF8kY5LToangQJqVt6wz1uXpVQv)czT0mYWhRVHMkzgdbr5cMFMhfo7(xtWiRJ11iWZfkv5upetHyyzU(Sfuu6v2iRc2uDCXXkgLI4l1Ng7t5(WzkisTxVuycUaUYejntLWunuUvFbyaUwlnnwT7apuKUkIJMzLiMjL0wCC1IMS)nQSjnWxBlhdvRGYPRiOq1n(UPH3NFc5LikvKvQeX4aHzcmOwbk7Gsmm5Lwli8wUBz2H4ZKfwNfepwKEsx)2NR16EBUNMEWiOhjJHWzz9xSsCSOpB(gSTq5gVv3)rjAupS9QBygZFpxzkZlEs1bQxrPS7mT5(qnrsb7wz0niMeliKb9mrmEblCA1M7f3WurwKKrZYsl)kLodfbP1lD6UbkpREW1yNtbMpzmTmeOXTJ55h8BKTGjwpzyfyzAZleeYM7KojSelbBUt7la82CSOFYspTVLf3VVL4wJfTpA9UsP6L(1lI3RAQqJboML(HkLxQsjJnnwaPkxU0S6MvBPDeg96QQDNXO0Lp)plTMM(rQjGnAmPkndFNFZQtVZW(Xf)(9O4vw4uRjkpPHVATXod(9RkEzREiESvNDU40ZjG(HOVCoIkXqoRdJiDXAECdhccprqCzw85yqMXeYt23BDdODE2JUh4IJ2RRhHOsQ5W5EZooj7u8CkNTYJsDAgeTfigOCejDrewOKSu1Trvs5fl7ylAoSyLqB)o9M1Ch4ZoxA9dtVNqpTqvx87gYQnxNLzQ0ScZiQDf2Zobt1M753cdfh1QLHAZ9cvhG5MtmPJmomZPJQenAGEeMEP8TGz(inNzISqglXHqAZDkKIyZ9rBob0M7LS5od9fpRn3lxHMzZ5VgkMnxGsClBUG2CmoTnhMFy23Q702CrUNyiFRsmKIvIKMEwub8pc3SiIX)tsdVxNr8JyfDFvcMuj(dnEjJa)PvfEngvWM7vS5oVn3fWM1RAZ9Zqr42CV2x5fO90yoWABU42C9IfOV40nuyZ1FDasBUbWCh8Eh3XwHiuy3y48ab2H9OTI6otJrD5fYjNDgfK(sONnb6bmrwXAzhOxVI9FTHUYsXcnrGwa923UtOh8L7mev4Du2gfqqhIdOyGXs7iKwZPOiTEB1E(FQOLVnGG7R7unedQFW63)6daaPtyLz7)8bLmi292kG8engqkPPS8m4Yj4yNtqYziXKJowSW5VEUKkITajU)Fcbj63MBVW7c75luo6O92h9aglJg2exrW0s)yvNE1XHTpuRtQCGyRkB2kg1(EUM8OnBhJI5HB5T23ZnURA4MQ0BVM3JUXcm7zlqpza6ptn5jiR2rYc60D7XY9ivN7i0noTionwBY9tem64YcgILT76LE4Qm8YMZ7(VFT6YM7aLo1e2Cpg9YhER2xzZ94sUMwzZDWkgvzZDi0ukBoFqaBUdFaBUNaTDYM7i4DTjzZ9K2CpLn3rzMhzZ1Ef7IQ6G7wA3qM2CptjBIS5oMJ1qC7igdfswyQzfgOV89mivlB74OM6uCwNU)UyklkSSzjLNN9DBOYZ6vWITuY5(0dn397rtABkofBBfaI6TG6nPMB5EY9t7O8WNtSVejwqYk7un1vl2Ctb)ijMYtSDkFTCUY(AzDn1sOR6oGhuFUWxUC2CI150L7sFYSnavQnAzS0LatFYpEJxgZxvkyNZrc7UbvnAZqvpqrF)p759)GaXzZLXfPfPVXKcoL)StNAUwG0U0oosB4Arq3piSVmCt0A1QonPsvY)r2zqGVzlrGuZuBac0MlXhqYyBBhnFFJKQ32YQqsthF(PJM6uH1MuOfiPlVJJKo92djT3piqc3iuJ1Io0w2v0pzHmENgfYjN4iWIGq5DJ)dPdbndHykL4Y9ncPFRtfTfiKRSRgH0ZxQHiKnQAFX76enW(Ctx(j30tejq8Xf0eBbKy6D1qIxCKgcjUvTweTRdvGD7MHkMxq4KNkS6KH7F6wGkU6U7LsEVM4DM6ngExhW4gVxtbglPR3J1ugMtQE9wamE9DZaJ(otdXfRv2li72WdyhUzWH(cUGLzpwdKz4bBbC4n2vRt8uF7gJhk7(RDD6dypUzaImdny3xsXV2jZ3xlaeFSFCgqWCt7Nd2t7v9JvzqnLLPr8mRzzFzg4bLRmJpsI(t1sVzMEN0BMv(5RW6FnYrM)GDehzQETRenU4yJ3hP)TZjoJDSoyUUSxfnvIzANrZtZ3vxbchGVRqrch6E4WCCUTrC6IYItxWgexKDOZj2rVJNtSy3fh0qBUfCDaWYtFzERP19F1R0cYNvPWLuh57BXI6Ht4sOtF0GCeCD25DyIckMeNqJWIksakm0V7)dKMfXJthKboJKUrK2QQBNsgfREFlZ5BP)3TB4t8L3NOpXv)i187w7Qqu4BWIS0BshfC)LJr)vJ9D23pE)RgdjWB5hkwHubnIkpGO4IZ1GFOy(m576SHpRFFl8WFI)V)
```
