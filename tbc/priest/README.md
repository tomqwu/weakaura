# Priest — All Specs HUD (v3)

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

## v3 — per-spec load audit

v3 re-judged every one of the 23 elements against a stricter question than "can
this spec cast it?": **does this spec press it as part of playing well?** The
audit was run per spec with `lua5.1 tools/spec-preview.lua priest`, which decodes
the shipped string and prints each spec's real loaded set.

**What changed: the Holy proc row is no longer ungated.** Surge of Light sits at
tier 6 of the Holy tree (25 points in) and Holy Concentration at tier 7 (30 points
in), so no Shadowform build — the raid standard is 23/0/38 — can ever proc either
one. The icon now carries `not_spellknown = 15473` (Shadowform), the same inverse
gate Weakened Soul, Renew and Prayer of Mending already use, so Shadow no longer
loads a healer-only proc watcher. That leaves exactly **four** ungated elements:
the health bar, the mana bar, the threat bar and Inner Fire.

*The inverse gates need WeakAuras 5.4.0 or newer.* On an older client the
`not_spellknown` field is ignored and those four elements simply load for
everyone, exactly as before — it degrades, it does not break.

**What each spec no longer sees**

| Spec | No longer loads | Why |
|---|---|---|
| Shadow | Holy Procs | Surge of Light (25 Holy points) and Clearcasting from Holy Concentration (30) are unreachable from a 31-point Shadowform build; the icon could never fire |
| Shadow | *(already gone in v2)* Weakened Soul, Renew, Prayer of Mending | healing presses, and all three are Holy-school spells a priest cannot even cast while in Shadowform |
| Holy / Discipline | *(nothing new)* | the audit found no Shadow-only element reaching a healer — Shadow Word: Pain, Vampiric Touch, Vampiric Embrace, the Shadowform alarm, Mind Blast and Shadow Word: Death are all gated on Shadowform or on their own talent id |

**Deliberately kept, with reasons.** Each of these failed a first-pass reading and
survived a second one; a false cut is worse than a marginal keep.

- **Threat bar + Fade prompt for Holy and Discipline.** Both need a hostile target,
  which reads at first like "DPS only". It is not: a healer using mouseover or
  click-casting keeps the boss targeted, healing puts you on its threat table, and
  Fade is the only threat dump a priest owns. Kept for every spec, and there is no
  single spell id that means "healer" for an inverse gate anyway (Circle of Healing
  identifies Holy, Pain Suppression identifies Discipline, and `not_spellknown`
  takes one id).
- **Fear Ward for Shadow.** Fear Ward is a Holy-school spell, so a priest in
  Shadowform has to drop form to cast it — which is why this was the closest call in
  the pack. Kept because the press still happens: it goes on the tank **before** the
  pull, out of combat, where leaving form costs nothing, and Icy Veins lists it in
  the Shadow priest spell summary. The icon answers the only question that press
  needs — "is it back yet?" — and a Shadow priest is the raid's Fear Ward provider
  whenever no priest is healing.
- **Desperate Prayer for Shadow.** Also Holy-school and also a form drop, but it is
  a genuine emergency button under pressure (instant, and cancelling Shadowform is
  itself instant), especially in arena. Emergency survival stays.
- **Shadowfiend (prompt + cooldown) for all three specs.** Verified rather than
  assumed: it is a mana cooldown, not a damage one, and Holy, Discipline and Shadow
  guides all list it. Correctly ungated beyond its own level-66 spell id.
- **Inner Focus for Shadow.** The gate is Inner Focus' own talent id, so it loads
  only for builds that took it — and the standard 23/0/38 Shadow build does, using
  it on Mind Blast.
- **Health bar, mana bar and Inner Fire.** Every spec plans around mana, every spec
  keeps Inner Fire up (Shadow applies it before entering form), and the health bar
  is half of the Desperate Prayer danger state.

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
Since v3 the icon also carries an inverse load gate (`not_spellknown = 15473`), so
it does not even load in Shadowform: both procs come from talents 25 and 30 points
deep in Holy, which a 31-point Shadow build cannot reach. A 41/20 Discipline build
cannot proc them either (20 Holy points stop at tier 5), but it keeps the icon
loaded — no single spell id separates deep Holy from deep Discipline without
risking a false cut on a Holy build that skipped one of the two talents, and the
trigger keeps it silent regardless.

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
| Holy proc clones | does **not** know 15473 Shadowform | Holy in practice (both procs are 25+ points into the Holy tree) |
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

The four `not_spellknown` gates require **WeakAuras 5.4.0 or newer**. Older builds
ignore the field, so those elements load for everyone — the pre-v2 behaviour.

Ungated (always loaded for every priest, and the whole of the levelling HUD): the
health, mana and threat bars, and Inner Fire. Each is justified for all three
specs — mana is the resource every priest plans around, Inner Fire is maintained by
all three (Shadow applies it before entering form), the health bar is half of the
Desperate Prayer danger state, and the threat bar exists only while you are on a
hostile threat table, which includes a healer who keeps the boss targeted for
mouseover healing.

## Regenerating

```bash
cd tools/tbc-weakaura-creator/scripts && ./setup.sh   # once per machine
lua5.1 tbc/priest/generate.lua                        # rewrites all-specs.txt
```

The build is fully deterministic: fixed seed `20260815`, no clock or randomness
beyond it, so re-running produces a byte-identical `all-specs.txt`
(sha256 `41162464fa8b6e245a4093a6d13b6f803c2a7c56364ac17c14c42118cb5bee85`,
6614 characters, 29 auras). When editing, never remove or reorder existing
`W.uid()` call sites — append new auras after all existing ones — so re-imports
offer "Update" instead of duplicating the pack. (v2 does exactly that: Renew is
built at the end of the script and re-parented into the Buffs row, so all 27
v1 auras keep their UIDs. v3 adds no auras at all — it only sets load fields — so
all 29 UIDs are untouched and it imports as a clean Update over v2.) The script
prints a UID continuity report against the
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

## Import string (v3)

```
!WA:2!TV16ZTX11DVcwXsq2Xsqw0w0wX00wYskwYaGaeGYsUgGe8L4ZfGsIYoMyb2lXUIl2D1Ul4dLMKkMex2hPTMTXtBQBIktA6mD6RHFWtFKKPHtN8HmPTNG2MUUnPzktB)w70Q)c65E3fpjaeLeLNeM(bUC379U39(43VF375CUG7s(YERNzLNTygHSZjAOP3RMIMXWE84zcp(pByDFz1uTm0uuiI9kjRiAqup3TNWqMyA1Xz6yqIGILuXYppQGQqLCtjzqeS2mJMHiXiUB9RFW4kY34gcgIDKsttXsw3yXXNDwtIfxgDbS6T0BZTgsfVxSwIPO0rsDswZmovKKXsoL)6RzqYjRPMAjDcFodTc6R5uIKY3GS31LvNvZiVGfwcVR7KHtFJJJZtrHcwsAgJRtZ20BgSxoRCoVgczzj0nVPLGHL3mZkRkBk5no(plVlBziNlhXWCSty4E77e3I(1fkyieCd6vtDIIISOz7(8hVa(sz0vewIySml9Hen9UPzHmK5XUzYcZoR8IRptVXsMAMKPIXNQCwtyqWS4torIrg52fmjjweBxjDQH08Qc5jMExtKKbRbAN3yWeJmr)tnYQfuDBwExxu28AfuXEZ8KGckk6hsGDFkN8hvtK8h(qUdxjeZr0puYRxah97O)c4W9LLKTiB4KRZy9(xvqv2zWSB4i9VbrWKK0cNTYzj9iq7Xv1ujffX(pTeZqhtmmj4GQO5Y0IsBLqG45fKv7h8JVaeaccDbHW)3w9PSQjrz2j0KvTY0BIXsLGVtzrDFLrv8etTcgzjM3glbXqvq5s4hd)SV(6ZAGdnyZsWsWZTfuZIZW9ttI(5ZKSx(ejgBnlTSZ7u(9nXrcwqwC9qAxtmu0asNCHq8MzfuiEwdNi4zylZsqNHuXrbpRr7sYoyM4kAcIEx35ZWAUqKv8VMjcIN7YYIwshznzS4jzn2N5HG9Xbp63)HGeqKISYWRzXgT40punptNBIhBQuJhN(6sWt9MNao67Gdqhd6aEoEgajJdXdt6JapR3LriYmuWwAOt45HJ7fob8IWj9w97bJO)etHfPJELeOOCIHSPLCwt3QagRU3fofCA4JIyeAJyMSLef8a986q3qKLZi4YMM4H9F2aHPxJeLEnyypi00uWIcgisBW6BoGOP5GyNRnO91PefScMb)BL209zrw0AgtjbrTfUIRuWQS0Ox0p4XrWuwStlX6Zh)46hSQxOcLEtNulHDGH1pmlfKPRrrUzztkXJHpEBwgifJiYs8MfDMfN29RVbl)RvahHMDjiYAg0PgskmX4Jn(yjG2nqacTmRXkyLrhNM9SOKP(b73q(gDmzbbrkCSJuP09xUpnJJY0m10XMrKKfPykZOBG3yYqgvp0uQXvKL2ciQ8Ygc6lFz3Bkw(tZKegFQuJm0yjChRQcKU(qJnwc(z4hAGbtPFQ7qtcfvvfz0z(zv00mCgyMhBDzuiPR8jPkUh1DqS0uO(XVdvUtIzgRq(meJ5H2xfhuDiBfD(NBZoictkLIM7eK7JzRm77MsP2MlTDgckUbNP0tMy70tgjICojRJb9DPvPmNSkcMMPZyHmFvR24ZxaxuYlpl1tKXuwnNcjZe8dLizk4t1gSC64OwE22GpL340QJEZMmqEC89fPS3GX6Rp9dIvDmrkgIisehvyrjy)quh5HERqN85T(skJC(hZWLIah2B1mORWTkJpAkls4ztHWlt1JRxtn8DwLfEc8f9cT5fEsVRZ(edYgwUGbDgRGbHVxfIGkVGIUKGhNgrkNC0p5quL3zfYsEJEfqsIAU4cgVXudDMkpDMKmnn2Rjbxa1ArvCWt8BOPLNdoNh(fOeV)AVWRaNhE11hxzYKljMrp3crnKvPc0ej3wLSOirLFSexkb)6A4IaQoYKRn448dD1XhlvSrGEp9j4ZkrYox)Wr37YZlyilGyGLLv7vlFgbl(5fukq46utVZlCbJSscQ5iMTFc4wST4SSoUReIH1sWBFc43bRbpWxSyniv4wDgYp(2(op87sFTHPVxpmHVGox9aRbtch07TP7IkhJ1uwyIwyCHbO)Jad4UmWxJJUmamihmemmCrxn(3RIwn)eAlqmOAZRQtVJYa5QrMUif5woV0nuXhg)oPUdtuTOom5Wok4SXf6T9G9mEjiPRWnKAL2GP4GlD7sAYSwWXpoCfgjeMg7oxfED4nUj8X4G3eRYzG047jazC(qzbrywo9t2mPbw9vLSdOc5ajqgUgmhOaAP1FHw)QoPbMG(rHRZP)YTU0BvYf1HalOampSahSOtVAP0WnGZaFCpWplv0a(ePHpjL2d)CNaUjSSJQa8Pzj9zyx)SWBb)8mcpSsjEo8lG8A4xez0WVeh8ldFUDeQl8RCb4xf(1G32dSk8Rd)gv4Apm85Pen4DktYIowOzLJiNixMuWVPe8BbFb43gExO32DW97f(IWxcULlpXbQZqci4(TrWn8vAcC(D3t9W5XQgiUMfZoa6UpqrwJCeleiUjf)wjJ0uu6i6h0XKHoskBvGXYzW2TnMnk9sxngYUXXD(A6zTkJx1FPTapkxOgGnAm8w)5ArLugoUfoq146gSuzLQOgYadvJ0GDpW09Ufy61jJMpCkLRpYvJxdm90LLNxT8OdknhHkn35R6cyhMz3A30lbyQYLFjEHCOYmClpvJVBUuE1O9Nf4kBrmSNRPF0YgJKKT1SoOBcRJjqRB0FYYzDjH86YgYzrZClKvQQ3PCgjYNb3koPS9UNPJlteMJOse7aTAqr)WLtFivvIrh9lBq2Sk7GujlaFi4rOCW9dEHdibp6JYHtEFy4X3lThCihCboNItMvpzuMF(0WZGgQwAvc6Igu(2lKUbRu8si06S7)EhmGCvC6UsZpoA8QjLeJZ905DkEaN81hWV1qIXcDQfhaEnpqmVqCpqVEH(8s1yw55zIoyp6rzlHwmRMMcobOMCbzCvWnk9i1KwPA7Y0vy)QoD5)GGHJ2tWW9ekypr8hSNEcgpyKUJWhWpMk7AxSRH4dgUlmD61OgyToUQcYXog8h3GblJbJXpkAd(9YIW9863EocrpgDFLw8uDpjM0gkJf7CFVI5u0wOFdY1lquZUKJyxCAAsBGAOdO4AdK0Q00s6y)k92rygNFK1P3xY2bwzQS7twEL2VUJvn0uyFXusYzNtLyA6zz2JO(tXmfSS0uhh3EMIWsS6AezSihI99I74DMvomtUTZJRFxUPGkcIB4yIs8XtLA8rb9J5i5nltYRHYDtc9npk3XwtH5OL5uXPRsYFF6TicUwLcTVZFDxXWhdUisJ(gW(EPhgXHH6DC)xuQ7rdm3K8vz97NNTcZYLWzPllJ9NP)eLsKUl5(KnPBbvmnvX7DMeUyAkhevZC4pusbLCGCex(tDP02wsHYrQscCtYIOicBnYuY5jWT8fGQRDExDT0WAuNyC2aNLo1SnxF)CEQNFb)vPHVzZjsNJVRq9eie7A3SRrGVtZyiWFZ9g3a(BRMna)DomaablFxjOOh4V)iW)ah8p6m)89qym8pb2EG3h(NH)LdbF)Dcaj8dUlqHW)AZbEWpCFRKPE8MchI3IV4fV2q(V0cx)ubH)TQXAWMvaz)5Wp6bgGc(3rmux1HHG)JhuqN25deoy0U))Hl3b4YR8E1dxodIwiM3qkPHK40NQ)MJw(l2fGwkTjL4DhjA0FkhPO7JU(MQM1wxJBZAtLUOwt30FTRZf7QKHMAYfdp)0xV5iP)Yh0iPaFGHKUbU3VOXJeiy0GD7py8a(93nUzVEchGDniUzVqDfOvBi((eOn89dqZ8EhOfb0FohG2oeS9j3oW2TJrOLXJFweo2DKREj(5o1KzirBoC8RTJdhB)b1YCF7Gb6QN4D7psi6LW0lDtVeHEjkfZfmc7QZ99qn2iqy8AWGbyxd2IviFXFkzfY)RsyO)7TNWgBdvlm1adn8udCP8tfU5iPV(dAHTG3hcB(JNdT6SZPMa2ZW6pDDUCG6MOogDOKjhASb2AMYevXoMWqlVUL(tuoZ(fejLsTJYP2hbx4GgRomjAOQDlbZZcuy(3KbZD8La1F(zjp29RZewhTOQqE1K0kZXrEzCm2JxqroNkeXW0sGgNAoQdaqt)R4(fdN4qtsZC5XR5zzCiYTEoGeZjfp2gIlPkKxol7ibap(EJBQzybbwnNHSt4(oWY0BPw02jFF8kY5LToangQJqVtAZSAQ4Nx1QFHSwAgz4J13qtLmJHGOCbZpZJcND)RkyK1X6Ae45cLQCQhIPqmSmxB2ckk9kBKvbBQoU4yzJsr8L6tJ9PCF4mfeP2RxkmbxaxzIKMPsyQgk3kVamaxRLMgR2DGhksxfXrZSseZKsAlmUArt2)gv2Kg4RTLJHQvq50veuO6gF30W7ZpH8IeLkYkvIyCGWmbguRaLDqjgM8sRfeEl3Tm7q8zYcRXcIhlspPRF7Z1ADVn3ttpye0JKXq4SS(lwjow0NnFd2wOCJ3Q7)OenQh2E11nJ5VNRmL5fpP6a1ROu2DM2CFOMiPGDRm6getIfeYGEMigVGfoTAZ9IRBQilsYOzzPLF5sNHIG06LoD3aLNvo4QSZPaZNmMwgc042X88d(nYwWeRNmScSeT5fcczZDsNewKLGn3P9faEBow0pzPN23sI733ICRYI2hTExUu9s)6fX7vnvOXahZs)qLYlvPKXMglGuLlxAwDZQT0ocJEDv1UZyu6YN)NLwtt)i1eWgnMuLMHVZVr1P3zy)4IF)Eu8klCQ1eLN0WxT2yNb)(vfVSvoep2QZoxC65eq)q0xohrLyiN1HrKUynpUUdbHNiiUel(CmiZyc5j77TUj0op7r3dCXr711Jquj1C4CVzhNKDkEoLZw5rPondI28eduoIKUicluswQ6wVkP8ILDSfnhwSsOTFNEZQUd8zNlT(HP3tONwOQl(Ddz1MRZYmvAwHze1Uc7zNGPAZ98BHHIJA1YqT5EHQdWCZjM0rghM50rvIgnqpctVy(wWmFKMZmrwiJL4qiT5ofsrS5(OnNaAZ9s2CNH(IN1M7LRqZS58xdfZMlqjULnxqBogN2MdZpm7B1DABUi3tmKVvjgsXkrstplQa(hHBweX4)jPH3RZi(rSIUVkbtQe)HgVKrG)0QcVgJkyZ9k2CN3M7cyZ6vT5(zOiCBUx7R8c0EAmhyTnxCBUEXc0xC6gkS56VoaPn3ayUdEVJ7yRqekSBmCEGa7WE0wrDNPXOU8c5KZoJcsFj0ZMa9aMiRyTKd0RxX(V2qxzXyHMiqlGE7B3j0d(YDgIk8okBJciOdXbumWyPDesR5uuKwVTAp)pv0Y3gqW91DQgIb1py97F9baG0jSYS9F(Gsge7EBfqEIgdiL0uwAgC5eCSZji5mKyYrhlw483ixsfXwGe3)pHGe9BZTx4DH98fkhD0E7JEaJLrdBIRiyAPFSQtV64W2hQ1jvoqSvLnBfJAFpxtE0MTJrX8WT8w775g3vnCtv6TxZ7r3ybM9SfONma9NPM8eKv7izbD6U9y5EKQZDe6gNwaNgRn5(jcgDCzbdXY2D9spCvgEzZ5D)3VwDzZDGsNAcBUhJE5dVv7RS5ECjxtRS5oyfJQS5oeAkLnNpiGn3HpGn3tG2ozZDe8U2KS5EsBUNYM7OmZJS5AVIDrvDWDlTBitBUNPKnr2ChZXAiUDeJHcjlm1Scd0x(EgKQLTDCutDkoRr3FxmLfewYSKYZZ(Unu5zTkyXwk5CF6HM7(9OjTnfNITTcar9wq9MuZTCp5(PDuE4Zj2xIeZlzLDQM6QfBUPGFKet5j2oLVwoxzFTSMMAj0vDhWdQpx4lxoBoX6C6YDPpz2gGk1gTmw6sGPp5hVXlJ5RkfSZ5iHD3GQgTzOQhOOV)N98(FqG4S5Y4I0I03ysbNYF2PtnxlqAxAhhPnCTiO7he2xgUfATAvNMuPk5)i7miW3SLiqQzQnabAZL4dizSTTJMVVrs1BBzviPPJF9PJM6uH1MuOfiPlVJJKo92djT3piqc3muJ1Io0w2v0pzHmENgfYjN4iWIGq5DJ)dPdbndHykL4Y9ncPFRtfTfiKRSRgH0ZxQHiK1RAFX76enW(Ctx(j30tejq8Xf0eBbKy6D1qIxCKgcj2SwlI21HkWUDZqfxxq4KNkS6KH7F6wGkU6U7LsEVM4DM6ngExhW4MVxtbglQR3J1ugMtQEJwamE9DZaJ(otdXfRw2li72WdyhUzWH(coVLzpwdKz4bBbC4n2vRt8uF7gJhk7(RDD6dypUzaImdny3xsXV2jZ3xlaeFSFCgqWCt7Nd2t7v9JvzqnLLOr8mRzzFzg4bLRmJpsI(t1sVzMEN0BMv(5RW6FnYrM)GDehzQETRenU4yJ3hP)TZjoJDSoyUUSxfnvIzANrZtZ3vxbchGVRqrch6E4WCCUTrC6IYItxWgexKDOZj2rVJNtSy3dNtmBU5DDeWstFzERP19F1R0csOvPWMuhj8BXI(HtytOtJ0GDeCn25EyIckMeNqKWIosakC0V7)dKMf5JthKbsJKUrK3QQBNsgfREFlX5BX)3TByu8L3NOpXv(i187x7Qqu4BWIW0BshfC)fKr)1J9D23pE)RhdjYB5hmwHubnIkpGO4cZ1GFWy(m576SHpRFFZ)WFI)V)
```
