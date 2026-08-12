# Paladin — TBC WeakAuras (All Specs v4)

One import string covering all three specs. Elements load through Spell Known gates, so
the HUD adapts to your talents with no action from you.
Toolkit setup, once: `cd ../../tools/tbc-weakaura-creator/scripts && ./setup.sh`.

## All Specs — v4 (`all-specs.txt`, seed 20260811)

The full Holy / Protection / Retribution HUD: 32 auras in one import, arranged as a top-level
group at (0, -140) with four draggable sub-groups. Every trigger matches by spell ID (never by
name), so it works unchanged on a zhCN client. `internalVersion` stays 45 / `tocversion` 20501;
modern WeakAuras migrates that forward on import.

## v4 — each spec sees only what it presses

A Holy paladin reported the pack showing them buttons they never press. They were right: the
gates asked "can this spec *cast* it", when the only question that matters is "does this spec
*press* it as part of playing well". Three more elements now carry the inverse load gate
(`not_spellknown` = Holy Shock 20473, "not deep Holy"). Gating only — no element was added,
removed or moved, so re-importing is still an **Update** that keeps your dragged positions.

**Holy no longer sees:**

- **Judgement** (cooldown icon). Protection and Retribution press Judgement the moment its 10s
  cooldown is up — a numbered line in both rotations, and what the gold ready-glow means. Holy
  judges on a different clock entirely: Seal of Wisdom → Judgement of Wisdom, refreshed when the
  **20-second debuff** expires. Because the cooldown is half the debuff, it was off cooldown
  every time the decision came up, so the glow sat lit for most of every fight — a permanent
  "press me" that was wrong more often than right. The decision Holy actually makes is already
  rendered by **Paladin - Judgement Debuff** (own-only, 20s, on the boss), which stays. So this
  removes the false prompt, not the information — Holy paladins in a raid without a Retribution
  paladin should still keep Judgement of Wisdom up, and now watch the debuff timer to do it.
- **Hammer of Justice**. A 6s stun. Protection uses it to interrupt casters and to pin a runner
  while gathering a pack, Retribution carries it as its only interrupt; for a healer it is a PvP
  button that never enters a healing decision, and raid bosses are stun-immune.
- **Hammer of Wrath** (the execute prompt). It keeps its own `spellknown` gate on 24275 and adds
  the inverse gate on top — WeakAuras ANDs load conditions, so it now reads "knows Hammer of
  Wrath *and* is not deep Holy". A glowing damage button on a boss at 19% is not a healing cue.

**Deliberately kept for Holy** (a false cut costs more than a marginal keep):

- **Divine Shield** and **Lay on Hands** — genuine panic buttons, and bubble doubles as a debuff
  wipe. With Avenging Wrath gone from the Holy row since v3, these are the only Forbearance-
  burning presses left in it, which is exactly the pairing a healer needs to see together.
- **Threat** — a healer who pulls the boss off the tank wipes the raid, and the bar self-hides
  while you are targeting a friendly, so it costs a healer nothing when it is not relevant.
- **Seal Active** and **Judgement Debuff** — Seal of Wisdom → Judgement of Wisdom upkeep is the
  Holy paladin's one non-healing job when the raid has no Retribution paladin.

Protection and Retribution lost nothing: Judgement, Hammer of Justice and Hammer of Wrath are
all in their published rotations. **Seal twisting stays gated on Seal of Command (20375) rather
than on Retribution's capstone on purpose** — a Sanctity-Aura Protection paladin who takes Seal
of Command does so precisely to twist with a two-hander on fights they are not tanking.

*Requires WeakAuras 5.4.0 or newer for the inverse gate*, same as v3: on an older client the
unknown field is ignored and those elements simply load for everyone, exactly as before.

## v3 — seal twisting + spec-selective cooldown row

**Retribution seal twisting ("swing dancing").** Two new elements, both gated on Seal of
Command's own rank-1 id (20375), so they appear for anyone who can actually twist and stay
hidden otherwise:

- **Paladin - Swing Timer** — a slim main-hand swing bar under the resource stack. It drains
  toward impact and turns gold in the last 0.4s: that gold band *is* the twist window. Note
  the bar does not exist until you start swinging (the WA Swing Timer trigger produces no
  state while the timer is not running), so it appears on your first white hit and vanishes
  when you stop.
- **Paladin - Twist NOW** — an alert-flow icon that is present only while Seal of Command is
  up *and* you are swinging (both triggers required), and glows gold inside the same 0.4s
  window. That glow is the moment to re-seal with Seal of Blood (Horde) or Seal of the Martyr
  (Alliance); both are already in the seal list, so the seal readout follows either.

Twisting is an advanced, high-APM play. If you do not want it, untick these two auras in
`/wa` — nothing else depends on them.

**The cooldown row is now spec-selective.** A healing Holy paladin was being shown
Consecration (a threat/mana dump) and Avenging Wrath (a damage cooldown) — buttons that never
enter a healing rotation, sitting in the row where their real cooldowns live. Both now carry
an inverse load gate (`not_spellknown` = Holy Shock 20473, a 30-point Holy talent), so they
load for Protection, Retribution and shallow hybrids but not for deep Holy. This needed the
inverse gate rather than one copy per spec: no single spell is known by Prot and Ret but not
Holy, and duplicating the icon would double-show it to a 21-Prot/40-Ret hybrid who knows both
capstones.

*Requires WeakAuras 5.4.0 or newer for the inverse gate.* On an older client the field is
ignored and those two icons simply load for everyone, exactly as in v2 — it degrades, it does
not break.

Audit any spec's actual element list with `lua5.1 tools/spec-preview.lua paladin`.

## v2 — rotation fixes

A rotation review judged v1 against one standard: every element must change which button you
press next. Four things failed that test. v2 fixes them without adding or moving a single
`W.uid()` call, so re-importing offers **Update** and keeps your dragged positions.

- **Seal of the Martyr (348700) and Seal of Corruption (348704) added to the seal list.**
  These are the 2.5.1 Alliance/Horde damage seals and were missing from all 36 ids v1 knew, so
  an Alliance Retribution paladin — running the spec's *default* seal — had a permanently blank
  Seal Active icon **and** a red SEAL MISSING alert glowing in the alert flow for the entire
  fight. That is the worst failure mode a pack can have: the alert that fires when nothing is
  wrong is the alert you learn to ignore. Same fix covers Horde Protection on Seal of Corruption.
- **Hammer of Wrath is no longer Retribution-only, and only fires on hostile targets.** It was
  gated on Crusader Strike (35395, a 41-point Ret talent) even though HoW is baseline at level 44
  and is an explicit numbered Protection priority line — a Protection paladin never saw the
  execute prompt at all. It now gates on its own rank-1 id (24275), so it appears for every spec
  that has learned the spell and stays hidden while levelling toward it. Trigger 1 also gained a
  `hostility = hostile` filter: targeting a wounded *ally* under 20% no longer fires a glowing
  prompt for a spell that cannot be cast on them.
- **The press-on-cooldown buttons now say "press this NOW".** Judgement (10s, off the GCD),
  Crusader Strike (6s) and Avenger's Shield were passive icons that only desaturated while down —
  the pack never once told you to press the buttons Ret and Prot press all fight. Each now
  carries a gold pixel glow wired to `onCooldown == 0`. Consecration and Holy Shock deliberately
  stay passive: Consecration is a mana-permitting filler for Ret and Holy Shock is a Holy
  emergency instant, so a "press now" glow would push the wrong button.
- **The cooldown row breathes with the fight.** All eleven icons gained the same
  `inCombat == 0 → alpha 0.5` fade the health and mana bars already had, and the ready glow is
  forced off out of combat, so the HUD is still while you ride around.

### Not changed in v2 (deliberate)

**Seal twisting** (Seal of Command R1 → Seal of Blood/Martyr in the last ~0.4s of the swing) is
the Retribution skill-expression line and is genuinely missing — it needs a Swing Timer trigger
and a design decision about how loud a sub-second window should be, so it is left for a future
version rather than guessed at. Also unchanged: **Threat** still paints held aggro red for
Protection (a tank's goal state), and **Consecration / Avenging Wrath** still load for Holy —
both would need either negated load gates or duplicated per-spec elements, which is a redesign,
not a fix. Exorcism, Blessing of Light, Divine Protection and a Holy seal-missing alert remain
uncovered; they are new elements, not corrections.

### Resources (bar stack, group offset (0, 56))

Three flush 172x14 bars. **Health** (green) and **Mana** (blue) are always on and fade to 50%
alpha out of combat; mana turns red below 20%, because mana is the paladin resource in all three
specs — it is what ends a tank's threat, a healer's raid, and a ret's uptime. **Threat** only
loads in a party or raid and only fills while you have a hostile target: green normally, orange
from 70%, red once you actually hold aggro (for Protection that red is the goal state, not an
alarm). A red **Threat Flash** pulses over the bar at 80%+ threat, gated to Retribution only so a
tank at 100% is never nagged.

### Buffs (icon row, group offset (0, -16))

Four 40x40 timers, left to right. **Seal Active** matches every rank of every seal
(Righteousness, Crusader, Command, Blood, Vengeance, Wisdom, Light, Justice, plus the 2.5.1
Martyr / Corruption pair) and glows in the last 5 seconds so you re-seal before the 30s window
closes. **Judgement Debuff** shows your own judgement on the target (own-only, all ranks of
Light / Wisdom / Crusader / Justice) so you know when to re-judge. The third slot is spec-shared: Protection sees **Holy Shield Up** with its
remaining charges in the centre and time at the bottom; Holy sees **Light's Grace** instead,
glowing under 5 seconds as the cue to land another Holy Light before the 0.5s discount lapses.

### Alerts (dynamic group, offset (-150, 96), grows upward)

Seven glowing prompt icons that slide in from below and fly off on exit; the stack re-collapses
itself as prompts come and go. All of them are combat-gated, so nothing fires while you are
riding around. **Seal MISSING** appears when no seal is up — one copy for Retribution, one for
Protection, because a single load gate cannot OR two talents. Holy has no copy yet; that is a
gap, not a principle (see *Not changed in v2*), and it costs a third element to close.
**RF MISSING** is the classic Protection failure alarm: Righteous Fury off while tanking.
**Holy Shield NOW** requires both conditions at once — buff down *and* the ability off cooldown.
**Hammer of Wrath** appears when a *hostile* target drops under 20% health *and* HoW is ready,
and re-pops every time the 6s cooldown comes back, which is the "press it again" pulse; it is
baseline, so it loads for every spec that has learned it rather than for Retribution only —
minus deep Holy, for whom an execute nuke is not a healing decision (v4).
**Lay on Hands Prompt** is the panic button for every spec: your health under 25% and LoH ready.

### Cooldowns (dynamic group, offset (0, -66), grows horizontally)

Eleven 32x32 icons with WeakAuras swipe text, mouseover tooltips, desaturation while the spell
is down, and a 50% fade out of combat. **Judgement**, **Crusader Strike** and **Avenger's
Shield** — the buttons you press the moment they are up — add a gold pixel glow while they are
ready in combat; the rest stay passive readouts. Only two are baseline for everyone —
**Divine Shield** and **Lay on Hands**, the panic buttons every spec presses under pressure.
Four more are baseline but hidden from deep Holy by the inverse gate, because a healer never
presses them: Judgement, Consecration, Hammer of Justice, Avenging Wrath. Five are
talent-gated and sit at the end of the row
so the shared part never shifts: Holy Shock, Divine Favor and Divine Illumination for Holy,
Avenger's Shield for Protection, Crusader Strike for Retribution. The dynamic group closes the
gaps left by whatever is not talented.

### Spec gating

No spec picker and no respec chore: every spec-specific piece carries a `Spell Known` load gate
on a signature talent, and the pack reshapes itself the moment the spell enters or leaves your
spellbook. Holy is gated on **Holy Shock (20473)**, Protection on **Holy Shield (20925)**,
Retribution on **Crusader Strike (35395)**; the talent cooldown icons additionally gate on their
own rank-1 ids (20216, 31842, 31935). Baseline-but-late abilities gate on their own id instead of
on a spec — the Hammer of Wrath prompt gates on **24275**, so it exists from level 44 in every
spec and nowhere before it. Threat pieces add an `in group / raid` gate, and every alert adds an
`in combat` gate.

Five elements go the other way with an **inverse** gate (`not_spellknown` = Holy Shock 20473):
Judgement, Consecration, Hammer of Justice, Avenging Wrath and the Hammer of Wrath prompt load
for everyone *except* a deep Holy paladin. There is no negated form of `spellknown`
(`use_spellknown = false` means *ignore*, not *must not know*), and no positive gate expresses
"Protection and Retribution but not Holy" — no spell is shared by those two and absent from
Holy. One aura with one inverse gate also cannot double-show on a hybrid the way one copy per
spec would. Audit any spec's real element list with `lua5.1 tools/spec-preview.lua paladin`.

### Regenerating

```bash
(cd ../../tools/tbc-weakaura-creator/scripts && ./setup.sh)   # once
lua5.1 generate-all-specs.lua                                 # from tbc/paladin/
```

The script is deterministic: the fixed seed `20260811` reproduces the exact same UIDs, so the
output file is byte-identical run to run and re-imports in game as an **Update** rather than a
duplicate. It also runs `uidContinuity` against the existing `all-specs.txt` before overwriting
it, so future versions report `changed=0` for free. When you extend the pack, append new
`W.uid()`-consuming constructors at the END of the script — never reorder or delete existing
ones. Contains zero custom Lua code, so the import dialog shows no code-review panel.

Importing: copy the whole string below → `/wa` in game → Import → paste. Note that the `/wa`
editor preview force-shows every aura with fake data and ignores load conditions — judge the
layout there, judge the behaviour in combat. If you re-import over a pack you have dragged into
place, uncheck **Arrangement** in the Update dialog to keep your positions.

## Import string (v4)

```
!WA:2!LV1w0TXX5zpgsjsWo2IuxSTSCmcTLmLJTmaibjOJDCbabfjnji0cqsjBftSy3byxXf7UA3fKeS5MzDtvCU5WO64tAAQlAAEkNtt5d9Ep5uLM2(qs7)HPnDpnP3uBtV3MQElP3NllUsibzzjxB6h4WDNz2zNDMVVV5))FgGMRxPx(Ep39UzErPfLTmmtyOzynPpF(s7l4XIy2RKHUJLHMgwoHIQMSfw)Pm3tArnrzv9apCGXXIAokxSrgtlQl2CfYQyHfDmpq75eymnrBfZ93i)mlRQxmqw1syRlM3WsgBf3RpzUN4AQRUQOLCGSggAoQM5nfj9ehZ7O2JNnEcstettlqgtSK9gQ6fmSkj6OAO7ppV1uSQmtHc2yNZw1cxKuq2kMyHIwgLnRYRrg1vX7CtXYokgwZysFwB)BWlIpSGqiF5jJiful6xWwsud7ZsuIvXHeSDeTC8NVGQUQTI)4K)54Fnhl1IfXw2PoIL3LVyCh67vSSLy4lqtTnXAAQY2hS3GXltEO8MAIvWwRXYFczB)x0UCE8sKp3mLluqDLnwirSmzxit2yczRxuAlmPiHmPto1uxQSno5kK(vgElKtqxSe22FvzCEslq)STgp5uPhB2PwVSUx3Y)gYQ2NPSo5RzjCyrnnZEezxNLx(0gY4V4nTUOUkFuDi4og7cyrBCghYmrrhL3kCO46g64nLjFt0ASa970YgtgVKTxJwv6BgcgVKOQ(yWJqEaiieccddq()D2EoxGpWZNY29Lu1DWw6IAZrAssJ)0RBJ1kK2GKD(ejtLnPqFQYM7TbAsaBBu2scBx1XqAj(dTR07FJcwKXcsFw0r03Le1Lit1JrZI23YNjHqYKP2GNnRXHOHlRkVHW0PFQIrg5udHJ6biMqN0T8vLm(lWatKHxEbjLlIn7jZzltqObgRmbroVIQdUkDyqLJPIRzik73Af(3g6CbRAtWZloVQSJY(RQsQzgwF)q3e4hgbUTV9nbVBi6MSkjy4WgDrM90Y905N4XMn7mXPpVcCWN5iWD)IKb07f6dUpbgijpNTsYka8o8VgbMSafWLdUF4WWd4h6hok8G(B(5GuM7BwsvcKqrKI0XwQ2oQs2EnbKUTNfENWdbp8x8MyFelivtlXhm0tdddrxlVOhtk9ocESqrOPdhLMgoIpc80w0HcEWkxG9TXhFofcI)Ohao0guYcPbwG835oGzVo4vCwWwru2y5t6nsUolpAI5Eomb8jr(OvyFZh(WM7PPhObD(I8CRbMGPm3llhIkGbfPlXMvIhJC7LyfqOzyzwMp7MCGYP8E7xGv(zktgHkubIw1Io1GZsYmEQzsLeoKfbTqRtvwfBm6W72fikTM7zml1vdCIYIYueAGSzndw)BAbUK2cT8HTGmwIqj1wW0ICHndz08qtTo3MS8wMarN3s0CT59UyZ6VAMSWmZMDQjsL0BSQjEWgtKkvsHfeM44JN18ODPlrKu1Lz0FHcAggw8bMLi9U8A4CnELu927YBqS2uO5H7sJZZmFQYLYJTwco06KbvoZBt()862HjWKA5y4nb5DRuJzFVCQ138i3lGjKyy0A3zt6N(YRGvlQ4CpWyZToL5irw)YoxEhYIa6ohqOuzY6s(fy5EK82KLY0WwPJnvSrNif8ShaEUCXjc6shaEw)XPTh9IlYq5XjnGmL(go2OJAUhsBhtMcIWYy5PfxrHloKObxQx)W(83EfvjC(B3YJI0m95Ki4yuX62fChS7sWRZyX2QYyb2epCasd5hUt)WD5p(QggLqBWErJZgzECl6KwzlSqcnSOUGOMPIOpExjlVeZ(NGkJxqucF6eIeEIEX4IwNE2jE4g39WzyYAShtbEuIMnrzh8bhhbVlFcltjE)6(HhdEC4j2ap)CPL16FG8Y9BPQtv5XkEDjvzzSUqQKZLuyddlvYCetMS64ZimXtntQSXMcsEWJiiPGLwCm4U35AljAPksWaRPQNWOuErhHLe1kJr9zy23J)4wskI6fX2h8iqvMLrRzsmmbB5ubopCR(Ve18PImCFDPfA1g(CbHX3pmrnL8FfevjhMebpjmfmTNm9pxd5wH0glJTOYRRBsVIsIqTO0Ujf8vVSCDu0gor3eObHM1LHmts7THOkXdYuLhjIpiRcmRN2lm35oampco5LQjRY6bh(WWtX4rWtt(Con8EGN5zHfqqostkc5jpNeiZFryOaOGm7)YXUzTxtkhGjOcNbwe0GsGoC2CM3)v(r55bLbR7cSrMpYvU2Bv1KiLalbldRavqWQ8VQFWCW7fgfEF(G3pL3dFGCWhKsCH1oc8dbphNxd)WSS(qS0Fe4CWhwbE(MyQWhHWmHpk8XU2jIWhh(ent(GxabFYhhwh(uW59b)OWlcF6guLDWPkWlvNMmAXXtVI5zxD(Ohf(mkWpg8zHFC4ZbjFWJa)eeSVp4LVqZdoq1(chKa779XGFkkENTyD0inwYoebC85Hm8NENWld)KqvpEc)jymesvOud4N(Yrg(S3C7KHundJR6WCuGA(brL1Qi2HaJVif93OGCumEkZ945trgvNYmAod03nepZSdAhlknzGod4VWH5VntjN6ODZhAlGR6vQdiRotomFhxHgPoyElmOMzfDyTYgnrlujgNGqI6oiFjciFd6GmrnM6AKhI3Y7wY1hb2tU4wIQY5EDnnyNBHgS6CfDYoOXjd5m(LHgSE9HpchyykhOV3ThKEsMdXdXKjBc9tEibXIKHgOQVMzam90ryKLW8u2d1gFiahY)BudYVzd0nPpKd(zGVev6(Nnh8l3x0GeSoX0U6tW0LFeDmSODXuWgDaYFjVfKPg6rnWWCFjMk20Pj(imvSepjXAJjYoXCjP9jYmeLsUp)5lPAzzyPWyN3ozOnP)1ZxZafYKANN6kahkpbVtS2GDpP4Vsv2Y)PlRzJxRMhH9gI9iBDELoNrNRAEUDDZhTHXcXKLNr3(0ZJfxmg1L5tpnwwv80EMvyFAU7wlW806yofff8mUMVQwTL2IgHY(jWcIaafI8wyaJZtj(RzvZVkcqzQOtn)qjoz)XnlqvOm7H4ASKf2bVqJA9(pCEU99kWyVi8l4XlGFXARqWzdFGCmblMR8lQBSSEBCMF(CvBu2UE(eE0NxAh3sBALVxFxrTsi1gnf(ekMXZ)oIvlYmtaItVcg8QrumsKgPdfUUS4dYKf7IcY(5kiWxR1XHw(O)67AMp9RF0jERBvNyXIhT)bsMnw8kTOtCW6u(lIxXuLJPPd4q1We7MO0)hRHAbfVfUHCrBm)7fq1dYgCZt2sCWi(5eigl2lMhSr2twM4tsjYA0bgLfghZ7SPOWzOvjqgfvSMCGznBoyBtrTm3oWXjoVJHDb7MGMUfAx5Try43kImqVhONDsh43lFQKm(V)w5H1bA3d82pyVbRzyjf0rvCosUoyC518exKD7bfjZmxQXxrCY3RDDvc6SeLm8eBenYOLwm8ifdTCyiMpiUFibbhM0pmMFYS65Upg)54p0oGBJz39MsggAeFI1jCfIPZxO2T0q2OatNRLV1x(icHdgkYGcHdfmkjny4OdZsJYshHMosqwAiwAyw6acHhouKiSNIMtOHOPdemclDiw6WS0OSAsBTbgMw6iH4PrzP02FKWbP1z4GcdekkP9jPbdXAtw7eHNomToSCcne7TmiR9hK1YdocR0GSshK1orYtkB4Gb5)BWRQj0HE6lTigBgJ6cRJaf4RWemisdXF0V5Mf1mwEml8zlJ1LQWTRkonpLlq0GoUMx8wuwNMxgwytRsVCkwGd3)g0RRfNcwDA4SlRSAXgGhbfAoS3ywfvPf1X22(wJDlXuNnZx2XXqFgIRGAIvyT1uQKQ0d79fNhh4ZTxMLD9DyZxHEV0W2RlWdhs8zYMDMPbR7HBDvbM2yh1fpXvN7d3omnLmsq2NyYqrwsOu4ZEgcL1f(n59JxGzP6A1aU5QRI97AUVAzsxuCuvBQVSePFQY2j8iKuw2H4Rp7riBlN7Cl5q0disGnRhqzFnjfcBcv7nsZAF5GppnSOhl0XOJ5uXMZ7Rgvud5rfH)GCW3QbN7l4X56LItJYrXdYs5xpedfZ4tr5OEwPuE2WuCD4qHIoaRugQpyqwAiwkN)X5LJWQdNhmKfzWAgDTk5iuGVuhOawJhty6XMDQwjcUOBUzSVlYhhW7I2HIlANK)El(CrV197I2fYfTB28MlYpb86IUfx0TsU5T5IUnx0T3JlApxpaJUOEUrabJlIh8usoskMr3ke0fT3gGVFpx0(UrH083ka6H7m(XtZEsMOjtgn8WSuMi7WJCvkY1YC7Kx)MBTVMNBj1W6DWNAVEHuUJRgKYvHrCN4xTDeZtMOySv1p78Y6X7cI5B(6feZbPsbdm41c(4nyC)RgZY)(TpJMsQC0zp(P6pTXr7Ym6V)nWz0USAJlA)Et5bJt8eF5(MnnCZRAEO2mPE6jYKzIuhpq)cyNJAEpxUsttCR7OM7RPDsCSAfAExD2K7uZmFlfjwI4ewaJcbioE7O08RAkXkbm0j1qx2oa5nvY0P5nTm7YQ2o0MJzQ(X12nCB)AmSl36CAqXLWVTxTMNVbX54YL0ZqBmURF55gYiiQPwuhIAz7is3Zxe1IAIP0nCvXIV)V4Ce)Lx2Rb2VV1lAPY3sSBH6yb1g8B)cYv0flPkXIAeXhJ42gwoqW1OvLAPwFcJkOPws15wO(Pof9kL8wKXHY2p3TErjdDsFq3zmrjhdR8cXgDIzZSUOLe3KXN7aepfQwOSMwcvljnCDyyZN8GyAylhB43cvZNbQRpeVeUMDoH7EkxF5j2iBXto)Qbhi98jkEU7hMarDJ8kABZrGVn8hc)rWFm8Na)PWfH)m4ph(lGVd8xc)vWFn83a)TWFh83d)dW)i8DH)j4sW)m8Va)RW)g8VdFp47d)hW)j8Fb)3W)d8)6IUjxeAtY8GKc2oJIXYZOVPn7FtRAt36PRf5ShSHCMNC1oZrKResRUcwRfrTwcemvEJi)LJl9rv44ABxzXOpKNyexgIjjvLTPASDEjx7ct1dmcryIEofONqIjiyeZJ0ier07TpnlAklOqiNlytO1gfYRzyiZfZcpWyy1ZQSKWCva)UOP2IAw9Gc4IgOn5m6NZxbgWIEmgMPSdlexByRPkJZBq84Oe8vdtAdguPdcDNBpRZoTimxuSDSePELZCecouEPY2KgipRcvODLbbYBFwEgRWZ4R2Bi48i2(oYYoxVvK3DVRGwNfLnAZUwTML(Y3KCTUTgD3Njfz2tTYYwlBspJhRXAzKJ12Swlx3wy9)pq7UOuUOzUoIRDrPBcu)DrFRRBazx0jYDLSvYfjyEFTJBfZRQP6uzbhLY6eFuZBO5WbThvO4yjXNjlEGGDf0oyNbTeWedV6IMd(QUO5V8Oux0jDrNIom9uUONUbw0fD6MXHUO3tnaOl6zCrlqBkxezOtK0yUO8KRKUUaJoOq4idhn42Sz)d3vvRcLTQWN)dnJ(jo(aXIoIv3N)JS9y()zAm)pPl6D6IEix0d7Iow3rbKh8C9iqe1Kwmo9a8y2dvvRiwhBPkXxOm3MTC7g81nfWIYvy76oBQiLyjmDw7qcSB9oju3vcViSqTCROf22oq)SJy3rn7LTJzf1nSWglHTi24GZTjzXcTm1AUnAYGXnRVNa0sy7HjT)Z3O(190LLwmN5EPxJPhLVMR(Rs0ERXM(1uG)JCfa(51WmBxmkysSahZovLCkWOlfn7OwvkDIvgSRuGH2(qb(o0n3HbvumSDylpKJTjHTCEO6lCqifqzfFP1Rxpl(vy(gbXawPZXjdT8W5mpqRhUQA7PyVpwZmkxKQl6mUOfjFuetblrjkUi9D9mFd64KbNE4ImDrNLudRl1MdqUiN2W4UOYKkU0RAO839Mp(1g(9l0POGXG0xu3WPP9RJ4tmNC3A2EiFgM)RthhEfT6UKMOjhAp)aRekposKbNB8UcThE7d0U(gE7IwTpYemhahOf4Ql69r(79FvHep)d0rG4fA2D7BCOq2E9paBF98DnQNwOEGz3QmABbNTBgqqCnYqNUzV2CiwXvZ3)t1)WfovLyDfIfD7deR5td3VThW63HFy4G6BdEJqNCMwCg5gLHMDCPxLBil9wFl29GmVZlNMKjpGjB1D5(hWE4Ze6uJmDEHUcCg51SO)bFJlF0)CrHHphCZ)sn2a8eJ28oN3iiDS8tqggWs8TX38T3srnwbBs6X5wcBE3TuESLW6fPN3cEe(oylfoQ6sQ6ypB9A7D2SIuJF9k83j3ardPfB7z8AVXexYWYmqNkAcnTYLu15Fj3Zw7PyRhWUw)5qTogyv2wKSKuGmowQlYpIauk1dTJMI7Ol6r39R2Go6IEx1oMjUOhNM8U3A4fDrpbHn8dqJPOlkwJGj6IId9StxucGmhpAFcJ6IssyyJrQ8XFUB1fnUlAcx0KSWc6IEYgHdSPyRwZ49BCreC2cdkoAHteQ)yzOAt0nF4Yio12czvPoHetBzXk21mTAMhPJROTEDS8vC5SxXNg4xDgF9krblgFNiCrpB9f8(G0nE4kTKhn0GE)WVYX1Mw6SzJDMuodQgZMQnD(l)gt4I(WeTjfM2uSR7AtpADTPQg61qyTDuajAuq261Zf9zA7WYY1W68HP9bB(W0sUwPz9Uxrymx0lwdBv8R3zRLAwp81k4114oNDDgG5IEjpG1IvkQ6OnuMPtFYUcSE(BGaRhSvaZLdq11dF91omjBKoIsm7zlRn(MvSsY0Mtwgp(CZpWr7kw5JSTgRSR37hTJGLl2QDsVPfOyRwyQ8gh1PYkDfO8r3wduU)(7iozZwmz(n0WKRYJyvdWXQJl8KjwzXcNj9CDfC8X2wdoUmrXXf9CV5crurxoXCNsF6tMjsxreF8T3RRqKy7eKOAdFLFd)AkVcotwnGidDQKdlM0C1WZmuxHiFIT3qKuFVo7ntZrnz7oiHmg0bqY46lhPscjPsXm7ki5f2MBFA(o7mZE7qa02UdwiJfDaSC2b6xcpvW5to3KDfS8j3Mdw(YDgSSN2JL6BWJbx3WjF5oHtg5etgFOO2tmqW57koz9xtI82veN86JiU98j68gL3w033EJNA(qC2apzK9mcZPnWIXuY3v80NABgEQ3s9k3R85E7T(BbfgbCDrtrhl82ng6pwZV2UQ9J18wR)J1KV9dVA)XAs3HLi7(AFtq8(XuFl0D3XBFvy)snFInkOKqEYswZoD(Jt)vLg3pDZw4)6mjSNETfg4yrowWExAhVV)Vd
```
