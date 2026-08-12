# Warlock — All Specs HUD (v2)

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

Upgrading from v1: paste the new string and the import dialog offers **Update**
(the UIDs are unchanged), which upgrades the group in place instead of
duplicating it.

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

The Demonic Sacrifice prompt carries a second trigger — "Soul Link buff absent" —
purely as a spec discriminator, and it needs no custom code. Demonic Sacrifice
sits below Soul Link in the Demonology tree, so a deep Felguard build knows the
talent but must never use it — burning the Felguard the whole spec is built on —
and their permanent Soul Link buff suppresses the prompt. A 0/21/40 Destruction
lock has the points for Demonic Sacrifice but not for Soul Link, so they always
see it.

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
| Demonic Sacrifice MISSING alert | 18788 (Demonology talent) + no Soul Link buff |
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

## Import string (v2)

```
!WA:2!DVv2ZXXX5DpAfTixQdqWdzrAzbdjqtqlrTha7UGwuP2DbwWfCXbNDb4HOf2zNP3DgIzNzypZcqqBzjbDeehN4yOe5koYXIqjo5Huo24HCu5OQqhLKhus(mYrnpKRIUQ8Ck(xq(6EM9cyjafLOSiFa9ot390t393VVFFh9aHz6w(Dp4YpX6LKKNtHAAL2u3KowGabMkqOJnOv3YMgoutDDIsAvnDfkXymRUoJev3uEUEEMEojrs3r96nRyCjdPw7qbvkrYX6aBSMEYOlzRE9sMufcnL)l3QRu6Ax5ksuLEkyAQ7OzrV8KLlBtCekzjHVBhRhT(avivACWsQR3tElISDjVrsLUO3dCPvPKkAMgfw0IiwHAwZAvVEKx7kKDSMMrztAvjhShbxZRbVvUGGqG1LQ5OAsN0I1SDWs4EqzTkbPsY8kIjA7irDcwQSMHMTAWu4pobxYHQvPcHApXHP(x(2PCyVDPAuPixJvABr011uSpy3HsvdFOsw6slsOlXRpRIDWRBxRezECDMVw5YAxETztNmFHzZxiPyHgnnfLGnjMFQrYL7g1SjJCzCEL3BekkAivLyhCvfsjCeylE6jhj3uzMo3k1m8NwbxtrZ(I1mWvZ8Kis66w7rIFDbV2h3uH8h9z83UgrPcXAp5VunC7VNm1WT7ZOQ5qUMxRE717AfjdnVnZyWbYCnIKnjVdkUQ4O(aWHszyAqwxbx)SEmlBpHAtWnvf7LyDLnlHiPQkPzKbcJpaebIcdadI)(OBSMvSj6LNYuZWPu6rMOWiI9QPyT3MOlrITznQmX(gyxiudj9zW3g(EFH1ktX9gCEj5if4gsgYOiodRk27Vu(0IJmYeR6ykpVx)35u7psnnL1gn2LCkrZioZ0Ns0wwsNeyvusiYbx21XoznWTHaRYwtAEGMu6MskbxZ71WNVqILdTQncJN7mAkoQ7FvnS755t2p)Nbccdbp0)XNbYajwN3jrth((LG1EA7EM0jvYPlmzk2ZRcp2lEy4GVnUf9fGVi0RihIuYtTeR6jGEcUecsMLb3kcpj8uWHdcFj4iq)bB95GXT230yx6jTQedNtOA2oAY2(dbm5gEw4OWxgEAeLWMeZkxN0iaC8xaIdjwQKKV(0u3FOJfEqwz8eSYidgabN2som4ar9A81Mhm6CcqQJFa4qRXuvWbyw8VLpGv3oKl7mRTQKI5cN1NnyfEDScRU6dHtY4IwLVM7RpRUA5bAQuFDVARJEGtzTxEnOUUjd7kZLkPsI3EdEdOsgrHx5RUUNy8C(V9RXB)I1WDOYlcjwLYenKcyLPMyYjgboefriS(SkVJn3D8M2LrkvRUYq1UspNUMKcdp2tHcwHASMM1JBA22wyZQqKrLm9zTO4f2CKrRBn1NCRZRBbewEgQK1sNX)I1B8Q5KctoDHCzNye)9QwqPRLDIjgrCwXSJEYcw9VntjKw1qHRqlww30K6TXmpo7kPtk28vY4CFm)nX6IqR(2Mb3RYstuRAjcDE4qRGBQEABR79J)0occtQxJPVaY)w5MsF)AQp381BNLG0BWXQFNnopdusLOvr15XHrMzfMMJmAOYUyjhu13W5aIvRH2LckYR9WLS1mQOtONjPyUjtFk4voa8AftH05YhaELGPyJh7IRZr5PWbqHP(gj5WdB1fo2jvyGiIcrzCPlR6roKUPU0Edc7l4g7OgQZ)WuFvKwvFoRaeIr)Urk0y3cKQCTyBnfIixWd7hhOGWJge(CbtDftZQcRXFrNKVZCcktOvJsetRtKmeL0TuLc4nvk41I1rYYyFlljtUqAjupXOskj6fMo7Z08UNjpNwJ)yQWZJ8Tivoea2La8vciUatX7Vni8CWjGFP1Y0FHkzo1Czo7WPPAgmgAIQ)ustrHyioXiZmI4AMunugXPjx9KtkM98torHK5GHp6HfLvjYZLboyGLMxIQjHyG1BdUjoVKEnsVXc1RPvVp3jOYQsgvi2h8WWv5Cydni3Hip6SalzHERqOolcIhg(DXHDhWpyjnJ0Mvlj5axvGniN4eWQShN)CW7bVfSNG3G5MvfUAtdMjw7Xxoem6(Htw3qWFPaZqaKvagdofKZNL)pPjBT4uMlqOm25vSyxX0bfAJOEDg2TrBf7iNpm12XVdNUvADqCmpoCw5ad6TVeaYRcf85UHPx(aWmcWzUrDAz(uOV(GZX1dHZJRNxaUa8vFv4ffGzXXSiiHpxjq27nPaeOIG1rUzSd8XRfMhWeubn4IWCGoufSkA9uB9J6vh4ax6XaQG1ZU19EZSUiveudMhwaUSaSO3Q6kfHVgCm4RhaEjgVb8nkcVmtXhE1ddlbVMhVa868QEdE5Bc)YWYQWVslA6W3e1SHFv4BD7Rid)AWVERkVW3wa(nob8DGvG3ka8Bc)wWB3uv7(9u1GVBd1Sqx8YPVOUE48IZa)2QW3d(DG3b((m9hoipa8dUwRBoWv7nktFP7NZdPZbhXhSjeHboEVwurGFVTq3a(9VzAdVZ91jTHg44vD4ruWCFbzPPvioio(6m4FZgkYa5JB1LFWh51CQXPj4O(pEvnWfqcwr0oRyCT(8MvwYon0kSE6nbcB0PoGa7SsK1xClgKgG(nPP1Q2thSj3CiAtLJR7GkBBVYW8OYWAmHbY6ZcdZxZG6FlE9HHhPykQKMsXpvRUSJnPUm0roR5WPhsxkTEBQlhVH6Ykn2(qDL4CBlpVp0FmEe2XyfHBrlbFirPk4wdC1aTQPmgRJdXn)eXR82u1Qh4XMaH6)D1H6R3urbNMfH)y4hZW6)KIWFrVjcHkaOxMnWamJEsoMu2QyCyTw0EQRvCdFFdy(CY81XAFPZLC8PWWvYLm9PqhFYwi7mJWMtOqKPDVVGLQQrPMuvUI(dJ7(dhCLs19vcL7Dw6wgoujuLaD8HFp28pDvUNitvt3MSu9Wn7om)r2SONjwzIZwf)FhRJ30VLKkktAyFHZqKMljl29lmorrt6c(E4yFbVyINLho8XCQij67NpxI6vGYPedYiiqKdYrWqrFwo25TyCdlrRhIhILkm2PTNEof9XJopJSZApym6YuIdz2M96L6RKxOgQEQvWFADZm)z(QrWF(wOd9DV)DV8tacnsUdCFN3AFnJCoTjLwJNYJB0sL1qxTS6UzfzRw1uhNcwpEZ6M2W2H5rvpjlxwxJNKeR93S58AwQMg9KtRmbEayNSnJGWUHhef4pOakWFeORDWaeD7rF4PC3QyHdyzCZFE4Xpy3HQtmZ4PzaW(k2bY5NbzGE2DD7Zm4jUAjXwdBwWMjkridtcYHpifqTr0Yul8CkNtdsgasfeshaXVWibzsXLFsUrSD9T2b8qCp6wx20uhdwZi)cAOtzxR(TSSSOc5k6Tu)HEl1VzKWXJKkwKi8IOPIhBGeIHdhlEyEzeXidgnCyXiXJeogfhKjn0xSiU58J7WMd9KjfhpZ05ADl64VWnMJqSsYcxXrKHXu5wYqRwPo6Y7LBTQ3(S(q65wt7jxZluYutwOWKJdx6X9SyuMBXOJwlo9TMRtpmKJbsq3vknoT)ZANEijjer9ZG)EV5X3MB9DP67TfBWG)bw7RELmT4H1SzOw0SdJv)0(yfga4qEek(yLnuZJUPAq4ks)3kILHqquacQFRa1bbFW95dcG)LIW)6MK2V7JgzOeHsfou4bqXD44OmoE4W8Yi8YOCjDIiXcfvmAOHcJ9DGHcXAkcVBrIW6qeeIeprm8rIpu048Agks8qdGONbtWkgIpyETelfE5a8kgc(pVzyh4)QDud8F)Xlob(FUtaoMWE6ZTWGlAATq2ndoGR3ev8pc)8pHqacBja47fj6ajqrvCedm0aPIm0aC98ydYlJZltW05dnehjm4TNe74)7Rxr3CHmuYLQrmKx0ZRvVCwXA4AO)aJQ7N5SIlXQINd9P0UmrFv2T54j2D)RXUUEwNwPs9hbna6fCi3XgENQNYNuSBu5DnpptQ8zsbvn55mi22b4TKtdVEp8xukVu6)PwiwHmYLM3OS28XU4wdX(NUZbXoyd3gVo5YwAEo9uqRkbUAKWhBqVSz45ryr49yPU(yHpgBZTDO552sO5XrcNWHsGLdeAaE5Tn4Zvyh1rCUcFwxHhOORWoDf2LRqW97kSBbxHhK7QBCVqOc4k8qyDpSQRWJGx3f(3E2JRq3FIcky(AXJNKFonZzWnQ4bsE9nbvwTzN2zT3zJqMevVyHrYjoso7ZU1qM)5pjGmUc7dUQRW(3akXv4aTJo(jBj64IImRsinvIeXhIvMieVK7AsSb4gRcFxG5fMy2v4G3CrRRWH25ONBJIuhIMXWlKo0GZvBRfPWDEdnHsHroUqVtpfCFxP5rLIUGZpIGEkqLmKBZDE2jVYoi2wRJ5OEpfKSAZhEtmQkvjhm4iRd1E1y)nMRNXZMpF2jgT1gZq07jjTQjTrJpzlUttQAAOj3tEjzQwznzs9oXdra3yFO)goIZlOawwILjp0h1OcwddrRwvJ8SbZlXnL88ovusxRIbKGIbYWocubMN8Op8ndwI6DeNKI8yxsgadEBb)XbdKHfTXdFnLfnKQQjZZRbgttkBtQdezLkunVZrA3lXUKznTxXHf11QQ5SB2HZLJDL61LnzXrz4KrsgdXUKyYHZoD(sujfTA2V(dIrZSIev2Z4lIn9rvTEw7j1juh7vlxtxpTgvwNuSE0k)dcS4s2L(hHaIqKNhmJrID6lsp3ivtKCXTX1M6IhM3Ode(wkWTBddg)FcZ7BMO4VOntST8hz(rBK)OSwKtF(5Vuf1X0HGUcN4MsG4k0x7miSPZpfgKYoe9jR5WZbYA26AkKsMooMvH3pcBeysWoWTSCxRWppBgECDBhQe7SD4(LbhQKCnBCakX7WISjcccCfs5vXL9Q497om8wc8ZiJxDXUxuzxDFzHv4PHHnSlvFyzV81XRnSz5oG1K1EQ3wH6vJZmVKrvVII8XMpAf)O5IDdCy0bgkAS7u4qpxFhS(HeDxdMC5f2iM06StnUXWJU45sFQTdtE4oIjrScho6kKgEFxHHV5GqxHrCfYW2uh1v4KnHAUczBfM5kmwD8LRWPCfYXgkxHXDfMahmxHjXvYuBlk5PGtk0rqc7af(FRNsuR932ravpPND)CWpQ3OHGXHFidbXpy22oSOIWFq7Nbh8h2Y5U1iJRW72Bm2OmbhhI9cFew)NSO1EAzi9oxYIwhO9JfVXS553Ae7rVLD1oQhQnWnfWU1qSYnczAv(XLZpd0IBz4tSpaj2N(uw0KN1rBMYv292xG)TmnRNllZMQg1qZOsEm0gnhpWz6CrSiY6zsrNOJGt1MGZV09mGZMON)Q2Zr)qSC0d)1BoJ84dT8EerYu55sX(ix8axvigeQMCEvZfM0O46TD7A28FejsklYpAzEOmtivLStNvHdjYV1)Rf6Xs7NjTEMIAwHIHV3Zr4cU(T6MFApvmmPeZ5ju0LhsX1rJu65RpCR1I7KR3iWkwl8ZPJn)9uGwX3EG8CfT2l7Ac7JDR1U)re)ZzSJ6NSIBp8)B3w237qUd4jQNtcZvdymU42zdLbxHZA1xN1bssLLmi()ekSh83orQjQEYzotH(ZUDW)JCpb8VLqnpOyKbJejX6ON4YQeBpy76EW2X1SzFno3gg3)qavcVDg33ASYBw3CShH4l7HhotXnzsEScTdq2AsYrLqRduVBS9qjlKBMZxrdJPswD7qj9FVgk5OIrseoEmwzIHCf0DfQEVbQWOR2rfhElrfy83SWVRr95nYjNxBXfgp88v2oeXrVNXSPpI48IHtepbl5uXzhzcwgMxgrm6GXdfE7XiTqb5km39syQSkFyyAMYErzv0Fbz0EEvpCv)gZpajY5QyQ3)2HR(Y3nHRc5k8uW3hUVlADW6Pyj9WSSSu1sxR8I(hn(HARnwkVg2SQMbpn8wFU2AmTPrzDPkSV75M5MJ3I3MBj0v3o2q5A0f3qddtqkFCe10BKVSN((BjHzUcp9U(OMTmxHNP(x3KRWZYkcT58I5kew1pLyUcrAMmmxHOqx7WvyaiIRWG72viwVId7kehVkHQRaslFCxHVcpTwUcpxl5ZAVT(fj45IPTRWZVXuzj8XsMSYs1Zn8PLM22wKXJSfzqyzuN7fCfUGRWxfrpV4QmFosQVG0I8prExHI7CulgWuYZ)yxHsUcYypvwVn8IRq5n4IRRqfSBQ3AEY6DsipG)PH0cJraVO38jvyKe7C9s1CCmnMeDbhd16wG1i5TAkWTAYyWc5Z)FvNI(hkwSOwNEYetnNTfJo4v3Iuh81GFUkNoi5DWZ4yvtJ64On8jvveEpiFtJi36cFxHxRUqp7(6Oq)6Tte8jOu3v4n(yuuJlVwmo8M(I4yvMxo)aZmt)uPTte)1)Kqe7kS8DarBMJ2rr7ATqJFxRCfxBDqUQhDKidyOPpqKkBNC9LU7vUoY)whLRR20i8DTIvCP1bX6mvoZIkjhBHPgE4TtS(nU7vSo)P2kXkZfQ7AfR4sRdI1(h9IrTgm6OXKxC7eRV8DVI1d(gDwS20b47AfR4sRdI1fh4s5kLA4bYA0)2jwFLFHlw7UA3kDRS8xOTVQ4XGHGFggiiBY7)9(Y(wF)GD(P7V1xmgMn9596KqjFSj7p005pzh(8E72wm6Xg8yH6E(7)L()d
```
