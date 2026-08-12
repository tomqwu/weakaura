# Warlock — All Specs HUD (v3)

Import `all-specs.txt` whole (copy all → `/wa` → Import → paste). One pack for
Affliction, Demonology, and Destruction: every spec-specific piece loads through
a `spellknown` gate, so the HUD auto-adapts on respec with no user action. All
triggers match by exact spell ID — aura triggers carry every rank, cooldown
triggers use the numeric rank-1 ID — never by name, so the pack is safe on zhCN
and every other client. There is zero custom code, so the import dialog shows no
code-review panel. Four draggable groups sit under the character; drag whole
groups in `/wa` to taste. Note: the `/wa` editor preview force-shows everything
with fake data (all load gates ignored, both curse states and all three specs'
icons at once, placeholder durations, no animations) — judge the HUD in combat,
not in the preview.

Upgrading from v1 or v2: paste the new string and the import dialog offers
**Update** (the UIDs are unchanged), which upgrades the group in place instead of
duplicating it.

## v3 — per-spec load audit

v3 asked one question of every element, for every spec that loads it: *does this
change which button that spec presses next?* — the test being "does this spec
**press** it", not "can this spec **cast** it". One element failed, for one spec.

- **Demonic Sacrifice MISSING no longer loads for Felguard Demonology.** In every
  Felguard build, Demonic Sacrifice is a 1-point prerequisite tax on the way down
  to Soul Link: the talent is known, and the button must never be pressed —
  burning the demon deletes Soul Link, Demonic Knowledge, Demonic Tactics and
  Master Demonologist in one keystroke. v2 knew this and used a live "Soul Link
  buff absent" trigger to suppress the prompt, but that discriminator inverts at
  exactly the wrong moment: **when the Felguard dies, the Soul Link buff drops
  too**, so the prompt fired and told a Demonology warlock to sacrifice the pet
  their entire spec is built on, in the middle of the emergency. It is now an
  inverse load gate — `not_spellknown = 19028` (Soul Link) — so a Soul Link build
  never loads the aura at all, in any state. A 0/21/40 SM-Ruin lock reaches
  Demonic Sacrifice but not Soul Link, so nothing changes for them.
  The v2 trigger is deliberately left in place as the fallback for older clients
  (see the WeakAuras 5.4.0 note below).
- **Nothing else changed.** No aura was added, removed, renamed or reordered, and
  all 26 UIDs are byte-for-byte stable, so re-importing offers Update.

### Requires WeakAuras 5.4.0+ (degrades gracefully below it)

The `not_spellknown` load argument does not exist before WeakAuras 5.4.0. On an
older client the unknown field is simply ignored, the Demonic Sacrifice prompt
loads for every warlock with the talent again, and the v2 "Soul Link buff absent"
trigger goes back to being the discriminator — i.e. exactly v2's behaviour, with
no error and no missing aura.

### Audited and deliberately kept

The three ungated DoT timers were the main suspects going in — Corruption, your
curse and Immolate load for all three specs — and all three survived the audit
against the current guides:

- **Corruption is in every spec's priority list.** Affliction and Demonology
  maintain it all fight; Icy Veins' Destruction list (both the Fire and the
  Shadow variant) carries "Corruption on pull". A destro lock still needs to see
  whether it is up.
- **Immolate is in every spec's priority list too, conditionally.** It is core to
  both Destruction builds; Demonology casts it "if you are not wearing a lot of
  Shadow damage gear or if you have a Fire Mage"; Affliction casts it "if you
  have Improved Scorch from a Fire Mage" — a common TBC raid setup. Gating it off
  Affliction would leave an Affliction lock in a raid with a Fire Mage running a
  DoT with no timer, which is a worse failure than one extra icon, so it stays.
- **Death Coil stays in all three cooldown rows.** It is not a rotation button in
  any spec, but it is the warlock's emergency button — a 30% self-heal plus a 3s
  horror to peel something off you — and all three specs press it under pressure.
- **Curse, Life Tap, the health/mana bars and the threat bar and its flash stay
  ungated.** Every spec maintains a curse, every spec Life Taps (the health and
  mana bars are the two halves of that decision), and warlock threat is dangerous
  in all three specs.

Everything else was already gated on the ability or talent that produces it, and
the deep gates hold up: a 0/21/40 destro build has only 40 Destruction points, so
it never loads Shadowfury (a 41-point talent), and Fel Domination loads for both
Demonology (instant Felguard resummon) and destro-sac (the resummon half of the
re-sacrifice loop) because both genuinely press it.

## v2 — rotation fixes

An adversarial rotation review judged the pack against one standard: every
element must change which button you press next, and anything that does not gets
cut. What changed:

- **Demonic Sacrifice MISSING (new).** The 0/21/40 SM-Ruin Destruction loop
  begins "Fel Armor → Demonic Sacrifice your Succubus (Imp if fire)", and the
  buff dies with you and with any resummon. v1 tracked none of it, which also
  left the Fel Domination cooldown icon pointing at nothing: the resummon +
  re-sacrifice cycle is the only reason a Destruction lock presses it. The
  prompt watches all five sacrifice buffs (18789 Burning Wish / 18790 Fel
  Stamina / 18791 Touch of Shadow / 18792 Fel Energy / 35701 the Felguard
  variant) and fires when none is up in combat.
- **Fel Armor MISSING (new).** Priority line 1 of every spec's guide, lost on
  death, tracked nowhere in v1. Both ranks (28176/28189), combat-gated. It asks
  for Fel Armor specifically, as every PvE guide does — if you deliberately run
  Demon Armor instead, disable this one aura in `/wa`.
- **Soulshatter moved from 70% threat to 90%.** `threatpct` is scaled so 100 =
  pulling aggro, and a competent TBC caster rides well above 70 for most of a
  fight — so the old prompt was lit, glowing and sliding for a large fraction of
  every encounter. A 5-minute, one-shard, 8%-of-base-health button belongs at
  the "about to pull" tier, not the "doing your job" tier.
- **Threat bar is party/raid-only and fades out of combat.** Solo you are always
  the tank on your own target, so v1's bar sat permanently full and red while
  levelling. Its own flash overlay already had the `ingroup` gate; the bar now
  matches it, and it dims to 50% out of combat like the health and mana bars.
- **Health bar flips amber at 60%.** Life Tap needs two inputs — mana under 30%
  *and* health over 60% — and v1 only drew the mana half of that line.
- **Refresh glow is 1.5s, not 2s, and the dead glow layers are gone.** Immolate
  is a 1.5s cast with Bane 5/5 — which every Destruction build, i.e. every build
  that actually maintains it, takes — and Unstable Affliction is 1.5s base, so a
  2s cue trained a half-second clip in an expansion with no pandemic window. Corruption, your curse and Siphon Life are
  instant recasts whose only correct cue is the icon vanishing — in v1 they each
  carried a glow layer no condition could ever switch on, so that dead config
  was removed rather than wired up.
- **Curse slot also feeds on Curse of Recklessness and Curse of Tongues** (all
  ranks). v1 covered only Agony/Doom/Elements/Shadow, so a dungeon or PvP
  assignment produced no timer at all.
- **`spellknown` gates added to Death Coil, Shadow Trance and Backlash.** Death
  Coil is trained at 42 and its icon used to render, permanently ready, for
  warlocks who could not cast it; the two proc prompts loaded for every warlock
  and simply never fired.

Deliberately **not** built in v2, because they are design decisions rather than
defects — say the word if you want any of them: an AoE suite (Seed of Corruption
timer plus Rain of Fire / Hellfire awareness), a pet health bar for the Health
Funnel / Drain Life call, a soul shard counter, item-cooldown icons for Flame
Cap and Soulstone (the 30-minute Soulstone cooldown lives on the *item*, not on
a player spell, so a spell-cooldown trigger would track nothing), and a
Conflagrate interlock that visually separates it from the use-on-cooldown icons
it shares a row with.

## Groups

**Resources** (center, above the DoT row) — three 172×14 bars stacked flush:
health (green, y=-13), mana (blue, y=-27), and threat vs target (y=-41), each
with a percent readout on the right edge and each dimming to 50% opacity out of
combat. The mana bar tints violet below 30% and the health bar turns amber at or
below 60% — together they are the visual pair of the Life Tap prompt, so the
"tap now" decision is readable without looking away from the crosshair. The
threat bar loads only in a party or raid, appears once you are on a hostile
threat table, turns orange at 70% and red the moment you pull aggro, and a
pulsing red overlay flashes across it at 80%+. Warlock threat is dangerous in all
three specs, which is why the bar sits with the every-GCD information instead of
off to one side.

**DoTs** (center row, five 40×40 icon timers) — your own debuffs on the current
target only, with the time left under each icon: Corruption (x=-88) and your
curse (x=-44) for every spec, Immolate (x=0) for the Demonology/Destruction fire
rotations, Unstable Affliction (x=44) and Siphon Life (x=88) for Affliction. The
curse slot is one icon fed by twenty-three rank IDs across six chains — Curse of
Agony, Doom, the Elements, Shadow, Recklessness and Tongues — because a target
can only carry one of your curses, so whichever one you are assigned lights the
same slot. An icon exists only while the DoT is actually up, so a gap in the row
is the "recast it" signal. Corruption, the curse and Siphon Life are instant, so
the gap is their *whole* signal and they carry no glow; Immolate and Unstable
Affliction glow at 1.5 seconds remaining, one cast time out, so the refresh
lands exactly as the old tick falls off. Never clip, never let one drop.

**Alerts** (left of the character, growing upward) — glowing 40×40 prompts that
slide in from the bottom and fly off when handled; appearance itself is the
signal. Seven prompts: Shadow Trance (purple, the Nightfall proc — cast the free
instant Shadow Bolt, with the 10s window counting down), Backlash (orange, the
Destruction proc — free instant Shadow Bolt/Incinerate, 8s window), Life Tap
(blue: mana below 30% **and** health above 60%, in combat only — the exact window
where tapping is free value), Soulshatter (orange: threat at 90%+ **and**
Soulshatter off cooldown, party/raid only), and three red "you lost a buff"
prompts, all combat-gated: Soul Link MISSING (Soul Link dropped, which almost
always means your pet died, so resummon and recast it), Fel Armor MISSING, and
Demonic Sacrifice MISSING. The two threshold prompts require the ability to
actually be ready, so they never nag uselessly.

The Demonic Sacrifice prompt is the one aura in the pack with two load gates: it
needs Demonic Sacrifice known (18788) **and** Soul Link *not* known (19028). Every
Felguard build spends a point on Demonic Sacrifice purely to reach Soul Link
further down the tree and then never presses it, so "knows Soul Link" is an exact
"keeps its demon" test — a Demonology warlock never loads this prompt. A 0/21/40
Destruction lock has the points for Demonic Sacrifice but not for Soul Link, so
they always see it. The aura still carries its v2 second trigger, "Soul Link buff
absent", which is now only the fallback on clients older than WeakAuras 5.4.0.

**Cooldowns** (center, below the DoT row) — a horizontal row of 32×32 icons with
cooldown text and mouseover tooltips; icons desaturate while the spell is down
and the row auto-collapses the gaps left by icons your spec does not load. Amplify
Curse (Affliction), Fel Domination (Demonology), and Conflagrate, Shadowburn and
Shadowfury (Destruction) appear only when the talent is known; Death Coil is
baseline for all three specs but is gated on its own rank-1 ID so it stays hidden
until it is trained at level 42. There is deliberately no timer text on these
icons — the swipe (plus OmniCC, if you run it) already provides the number.
Conflagrate is a plain availability readout on purpose: it never glows, because
TBC guides are explicit that you should *not* fire it on cooldown or at the end
of your Immolates — it is there for the "I have to move and cannot Life Tap"
case.

## Spec gating

| Element | Loads when known |
|---|---|
| Unstable Affliction timer | 30108 (Affliction 41-point signature) |
| Siphon Life timer | 18265 (Affliction talent) |
| Shadow Trance alert | 18094 (Nightfall, Affliction talent) |
| Backlash alert | 34935 (Backlash, Destruction talent) |
| Soul Link MISSING alert | 19028 (Demonology talent) |
| Demonic Sacrifice MISSING alert | 18788 (Demonology talent) **and NOT** 19028 (Soul Link) |
| Fel Armor MISSING alert | 28176 (trained at 62) |
| Amplify Curse cooldown | 18288 (Affliction talent) |
| Fel Domination cooldown | 18708 (Demonology talent) |
| Conflagrate cooldown | 17962 (Destruction talent) |
| Shadowburn cooldown | 17877 (Destruction talent) |
| Shadowfury cooldown | 30283 (Destruction 41-point) |
| Death Coil cooldown | 6789 (trained at 42) |
| Soulshatter alert | 29858 (trained TBC spell; party/raid only) |

Everything else is baseline warlock and always loads (class-gated to WARLOCK).
The threat bar, its flash overlay and the Soulshatter prompt additionally require
a party or raid — solo, pulling aggro is the plan. Life Tap and all three
"MISSING" prompts are combat-gated, so nothing nags you between pulls.

## Regenerating

```bash
cd tools/tbc-weakaura-creator/scripts && ./setup.sh   # once per machine
lua5.1 tbc/warlock/generate.lua                       # rewrites all-specs.txt
```

The build is fully deterministic (fixed seed `20260813`): re-running produces a
byte-identical string. When editing, never remove or reorder existing `W.uid()`
call sites — append new auras after all existing ones — so re-imports show
"Update" instead of duplicating. (That is exactly how v2's two new prompts were
added: they are built at the bottom of the script and re-parented into the
Alerts group, so all 24 v1 auras kept their UIDs.) The script checks UID
continuity against the previous `all-specs.txt` automatically before overwriting
it (expect `changed=0`). One more re-import caveat: the Update dialog's
**Arrangement** checkbox is checked by default and will reset any positions you
dragged in game back to the string's defaults — uncheck it, or report your
coordinates so they can be baked into the script.

## Import string (v3)

```
!WA:2!DV123TXX5DVgwXsq(cf1fhlfhZqBQiQyldascaQy5EaabPaf4fTaKuswXel2Da2vCXURMDbPOADSnTDcRBAtdDRZPPonw0TU9HEst4d9YPxoNQu30hCB)c7LZ(qVDuoN(Cp6VG(nZU4gjePSSLJPFGd2DMzNDM5733VVlZsHP7u(Do8Yp(6fLKNtHAALYu3KoAGabMmqOtmGvNYMgoutDDIskvnDfkXyuRoMrIQBkpxxpDxNMiP7OEJgvmMKHuZDiVkLi5yDOnwtxdRlzREJIMufcnP)l3QJK6Ax9QsuLUYBAQ7OzrVYeLkztCekAjHVBhRhP2aLpzkCWsOR3volISDrVrsLUO3dC5vPKYAMg5x0IiwMAw1AvVEKt7QKDTMMrjtAfjhShbxZRbVvUGGqG1LQ6OAsNWI1SDWI4EqjTYbPsY8kIkA7irDcwSKMHMTAWK4pobxYHQvUmHAp(rP(x(wjDyVDPQuPixNvABr011uSpCNHswfFOIw6slsOlXRpJIDWByxTizECDMRAPsAxzTztLix(zZLpHy(6nnjLGnjMBY0zZEZQ2K0xbNx58gHcIgsvi2bxvHuehb2INE60zNC4PYUsvd)PvW1u0SVuvdC1mpjIKUU1(K4xN3R9Xmvi)X3J)2vALYeR9L7YvXT)UgUkUDpJQMd56ET6TxVNvKm082mJchA4RtKSj5CqXvzh17hossdtdY6k46N1Jzz7juBcUPQyVeRRSzjejzfjnJHHW4darG(G(HbWFFKnwZk2e9stAQz4umv6XZNwSBnfR93aDjsSnRsLj23e7cHAiPpn(2W37ZVwjkU3GZljhPa3uYqgfXdZQI9(lMlLy60JVQJP88E9F3tEWiv1uwBKOx2PiDyXPN6mI2Ys6KaRIscro4YUg2jJbUneyv2AsZd0Ku3usj4AEVg(8fIVCOvTry8CZOP4OEWv1WUNJpz)c3deegeEW)J7bggIVoVtIMo89lbR91Y9mPtYetLFIKSNxfE0x4OWHFlCl6lcFjOBroePONAjw1JdDfCjeKmldUvaEc4jHJge(YWXGEd28ZbJzDGPWU0vkvjgoNq1SD0KT9hcyIn8SWXHVc8uikHnjMvUgPra4KppedIVurjF9PjVVqNi8aSYyXzLrgiacoTLCyWbI615Rnpy05fGKN8qWrwJPQGdWS4FlFiRoDixXzwBvjfZfoNpBWk86yfwD0dcNKXfTkFn3tpwD00d0qP(gE1wd9aNXA)8AqDDtg2vMlvsMaV9M8gqLmIcVYxzDpX459F7xN3(LQI7qLweIVkLjAi5Xkto(eJNgocfriS(SkVJn2D8M2LqkvRogMQD1UoBvjfgESR85TcvFnnRh30STSWMvHiJkz6ZArXlS5iJM3AQn5wNx3ciSCgQK1sZ4FX61F1CsHjMkF2mJN2FVQju6AzgF80IZkMzKtN3Q3TzkH0QgkCfAXs6MMuVnM5XzxrDsHgVsgN7J6VjwteA1Z2m4EvwC8QvksOZdhzfCt1tBBDVF8N2rqysTAm9fq(3k3q67xtT5MVE7SeKEdorT7SX5zGIQeTYQopgKE6vyAoYOHk7cfDqvFdNdjwPkAxkOiV2Jw0wZOSoHotcXStK6mWlFi4vlKePZLpe8YbtYgp2f3GJYtIdGct9nsIHgYQdCStOWarefIYysxr1JCivdDP9heoqWn2rnuN)HO(QinR(CobieJ(DJuOrVniv5AX2AkerUGhoioqbHhji85dM8QMMvewJ)IonFN5uuMqRkLiMsNizikPBPkfWBQK3RfRJLHX(wssMCXusOEIr5Ks0lovMNUXDpDooTg)XuHNd5BrQCiaShb4RgqCbMI3Fxq4zHtb)sRnCV5lp8zMB4ZnukQMbJHMO6pL0uuigIJNE60IRzs1qzeNMC1tpHyMlmX45tKfg64hvuwLip3WWHdS08sunjedSElWnX5L0Rs6oAOUnT6(zpfvwvYOmX(WhfUgNdBWb4oe5rNfyjl0Bfc1zrq8OWVhoS7c(blPzKYSsrjh4AcSb5uNcwL948NdEx4nH9f8Mm3SkZvBQZmXAp2YHGroiC6Agc(ReygcGmcWOWzGS(S8)PnyRfN0CbcLXoVIf7kMoOqle1RZWU1BRqB58Hj3o(D4SntRdIJ6XHZk7FaV9LaqoviVp3nm1YhcMwaM5M1OL5tHE6bopxpeUaUEEE4IWx7vGxqaMfhZcGe(CfbzV3KcqGYcwh7wXoWhVMyEatqf0GlbZb6qfWQG1tU1pQxDGdC5hfOcwpZw37nZ6IurqvyEyb4kcWIERQRwa(LHta)kbGxKXBaF9cWlXu8Hx5OWsWR6XlaVgVQxNx(nGVjSSk8R2KMo8gOMn8RbFR7Cfz4xh(nAw5f(2cWV5PGVdSc8MbGFl43gERgQA3NNQg8DRRMf6sxj1L01dNtCA43rf(EWVl82W3NP)Wb5bGFW1BEZbUw39X0x68z9q6CWrSbAaryGJ3Tjve43Fl0nG)GBL2WBFVTtBOooEvhEefm3xqwAAzIdIJVbd(3OHcmq(ywD4h8ronNQCAcoQ)JxvdCbeNv0x7vmUEpEZklzN6Afwp1MaH17uBqGTxjY6lTfdsDq)M00Aw7Pn2KBmeTOYX1DqLTTxzyEuzynMWaz9zHH5Rzq9VfV(OWdxijvstPWNQvx21Muxg8yNZCOudQlLsVf1LtwxDzL6BFOUsmUTLNZh6pkpc7OSIWnPLGpKOuzCRbUwGM1ugL1Xb5MFI4vEhQA1f8OJJq9)(Aq91BOOGtZcWFc8Jyy9FCb4VS74Hqfa0lZ6yaMrpjhtkBvmgSwtAp10kUPVVbmFoz(6yDGuztm2Ky4kztK6mOJpzYNz60S5ekezA3hiyXkAuQjvLRO)q4U)qbxPynFLq5E7LULGJuevjqhF43Jn)twL7jYKv1TjlvlCZodZFKnl6zIvM4SzX)3X6Kn8BjHIYeg2xCgI0CjyXUFXXikAsx03dh7l6ft8S8WHpHtzjrF)85suVcuofFagbbICqocgk6ZXXoVjJByjATq8qSu(rpR9uZPOpwFZZi7S2hgJUmL4qMTrVEXEk6fQHQNAf8NvZmZFUVAe8xSf6qF37BVl)4Gq9K7a37fSoqJiNtzsPv5P84Mnvzv0vlRoBurMkvm1XPG1J1OUPmSDyEu1vIsL014jjX6GnAoNMLQPrxz1krG7h2nBZiiSx4bqb(diGc8hg6yxmarNE0hEk3nlw4awg38xaESd3zOAeZmEAgaSNcTHC(PrgONzp35mdEIRMsS1qM5TzIseYWKGC4dsbunT2WvdpNY51GebGKbHubq8lKoitkU8tWnITNV1UGhK7r36YMM6yWAg5wqdDk761ULLLfviBbVL675TuFJiHJfjz0ir4f9Lmw0(JlgoC0yH5LreJmqFHdlgjwKWrP4GmHH(IfWnNFuB2CONoH4ydpv2M3Io5ZFZ5ieReSWvCezymvULm0QvYJV8(5wR6UhRpKEU1WEY19cLm5e5ZpXyWLFmplgL4wmAR1IZE7560dbzzGe0DLIJr79C2Pguscru)m4N6np(2CRVlvBVTqDg8pW6a1QKPfpKMnd1IMDyS6N1hRWaahXJqXhRSHAEKnvdcxr6)MrSmecIcqq9BgOgi4dUxFqa8Vua(x3K0(DEKidgpuYWHc3pkUdhdLXXchMxgHx2hxshps0q9j2xObdJ9T)bdXAkcVBrIW6qeeIelEu8rInyFX41myKyH6hrpdeNvmiFW8AjAs8Y(5vmi8FERWoW)vROg4)(JxCc8)C3aCmU9uNFHbw00AHmBgCa3ObQ4Fe(5FcHae2saW3lsF9hhfvXqmWG9NmYG9Z1ZJoaVmgVmotNp0GCKWa3zsSt(VVEzDZfgMsUCvIH8IEET6LZkwdxh9hyeD)mNvyjwv8COpP2vi6RYUnlpXUhCn211Y60kLR9iObqVGd5o2W7uTu(KKDJkVR54zsLptYRQjpNbX2oaVLSA417J)Is6Ls)p1cXYpSCX5nkPnF0lT1qS)P7EqSdx3TXBqUILMNtp51QqGRfj8jgWlBgEEewaExwQRpr4tW2CBfAE(TeAEsKWjCO4yz)H6NxEhd(Cf2vneNRWNZv4(l4kSBxH94ke8GUc7vWv4b4U6gZleQaUcpiw3dP6k8W41DG)TV95k05NOGcMVw84j5NtZCgCJkEGKxBtqLvB0PDx9T3iKjELlLpDwX0zTp3wdz(N)KaY4kCa4AUchCdOexHd1k64hVLOJljYSkH0uXJhBqwz8q8sURjr7NBSk8oaZlmXSRWHV1IwxHJS7ro)gfPoenJHwivObMR6wlsH7(gAcLeJCCHUNAs4EVAJJkfDbNFebDLNkzi3I78StELDqSnxhZr9UYlz1Ip8MyuvQsoyWrwhP1QX(BmxxJLjxUmJpsZnomrVRe0kM06n(en5onPIPHMCx5KKPAL0Kj16epebCJ9b)B5ioVGcyzjwM8GFuJkynmeTQvmYXgmVe3u0Z7urjDTYgqCkgid7iqfyEYJ(W3iyjQ3rCskWJDjram4Tf8hhmqgw0gp01vw0qQIMmpVgymnjTnPoqKvkt18ohP9Ue7sM10UfhsuxRIMZEzhoxw2vQ3q2KfhLHZWsYyi2fftmuMPYvKkPOv1(1EamAMvKOYEgFrSPpQQ5ZApHoH6yVAPQ66P0OY6Kc1Iw5FqGfxYE0)ieqeI88GzmsSZEj65txjEIf3gxBQjEyEJ2F4BRa3Udmy8)jmVVzIc)I2mX2YFm8pCJ8hL0IC2lm)LlRoQoe0v4u3scexHEALbHnD(jWau2HOprvhEoqwZwxtHu00XXSc8(ryJatc2gULL7yf(5zZWJRB7qLyNTd3Vm4ifLRAJdqrEhwKnrqqGRqsVkUIxfVFNHH3uGFgz8Ql05Ik7PZRiScpnmSHDPAdl7LVoETHnl3bSMS2xT2YxRACM5LmQAvuGp28rRWhnxSRJd7R)b7l6DlCONRVdu7qI2XGjxEHnIjTo3KJzm0ilE(uNz7WKhTTyseRWHJUcPG33vyOBni0viTRWWSn1rCfoDdOMRqMMHzUcJwdF5kCgxHSSHYvymxHXXbZvycCLm52IsEs40cTfKWoqH)3APe16GTCeq1s6zNpl8d7UVqWyW7Xqq8dMTLdlQa8h26zWb)rnDUB1Z4k8oDhLnkJZXHyVWhH1)jkyTVMgsVZLSG1HA9yXRpBEUTgXE8BBxT7Zd1g4wcy3AiwP6HmTk)4Y5NbAHTm8j2hGe7tFkdAYZ64ns5k7E7lY)wMM1ZLLztwLAOzuohgAJMJh4mv2iwez9HtshVTGt1gGZV8NzaNnqp)1TMJ(bz5Oh(B2Cg5XhA59jIKPYZLK9rU4bUktmiun5CQMlmHrH1B521S5)isKuwKF0Y8qzgxQcz3oRchrKFR)xl0JMYptADnj1SmfdFVRJXfC9A1j)0EkBysjMZtOOlpKcRJgP0ZvB4wRj3jxVEGvSw4NthB(7PaTIV9a55kyTF21e2h7wZD)Ji(NZy3NFYkUZW)VvlzFVn5oGNOEojmxnGX4IBN1vgCfoNvpTxhibvwYG4)tOWEWF74jhVYPNEM89Mz7G)h7ZeW)Mc18WIrgisK4RJEIlRsS9GTR7bBhtZM914ChyC)dbuj82zCFRXkFJAMJ9ieFjp8Wmf2Kj5rZ3kazRjjhrcToq9UX2dLSq2PVqznmMkz1TdL07N1qjhxms8WXIYkJpORGURqLpBGkm6OvuXr3subg)nl87QuFEJSY50wCHXcpF5TdrC8pZy20hrCbXWXJfNLCQySJmbldZlJi23aXcfE7Xinrb5km3oam171Elrmy2nmmDAkvMixJNj7wRUU1Qz4qVmkFyiKM0Erzv0Tcz0SFfp4xVgZ3pjY5lBQ372b)(k7KGFHCfEs47d37LSoCTmXKAiwYyQyPRvAr)tq)iT0glZydzwrZGNTERpFlnMY0OKUuz2NhDJu4XBXBZTi6rCBBOuv6IBOHHiOLbCe10RNwTN6(AkVAUcp1E(OMunxHNU2hbLRWZWkcT50N5kew1pZzUcrAKZmxH(Go2LRq)qexHb2RRq0UfhYvigEvCvxbK9(KUcFvE2VCfE2Ms71(B(dxWZtuBxHNBJz8s4JLeELHQNDOZknLTTiJUzls0WYOQ5Z7kCrxHVgIEEHvzUMKqFbPf5Fj9Ucf29iwmGPKNB0UcfDfKXEQSEl4fxHsBWtyxHYy3uV9C417atUF)dnPjILaEb55Z9W4s296fR64yAmb6Pogr2Tb5sIB3mLB1GXGfzO))rpf8p7SO9zD2jIp5C2wm6GxDlYWWlc)CvoDqI7IhfYQMg1WrB4lVQa8UqUg2AU9f(UcVEnHEMd0wH(nALi4tqPURW38JrrnU8AY4WY(I4OLNxox)tpDVuPTte)1)Kqe7k8g3feTdF82kAxRjA8DSYvCT1g5QEFPJ0VHME)rkVDY1xANRCn9)wBLRR2Wi8owXkU0AJyD6YZSOsIrxyYHgA7eRV8oxX68NzReRmxO2XkwXLwBeR9oYL6ZAG(gjQ8IBNy9v25kwp8R3EXAdhG3XkwXLwBeRl2)LZwm5q9NXO3TtSU0VWfRDwPtLovw(l2YhF8OWGWpddeKn59)SGzFsWFWU)09NemgdZM(kGDIRKl6e9gAQCNUnFfWDAl23jg4eH6C(77f))p
```
