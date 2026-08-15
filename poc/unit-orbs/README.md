# Unit Orbs — layout proof of concept

**This is a proof of concept, not a class pack.** It exists to answer one question in game:
*can unit health and mana be read as rings around a small unit portrait, well enough to
delete the health/mana bar stack from the middle of the screen?*

Import it, look at it in a fight, and decide. Then delete it, or ask for it to be folded
into a real pack.

```
        player                                                 target
                                                     
      ╭─────────╮                                        ╭─────────╮
     ╭╯  ╭───╮  ╰╮                                      ╭╯  ╭───╮  ╰╮
     │   │ ◕ │   │   ← 96px health ring (green, outer)   │   │ ◕ │   │
     ╰╮  ╰───╯  ╭╯   ← 64px mana ring  (blue,  inner)    ╰╮  ╰───╯  ╭╯
      ╰─────────╯    ← 28px live portrait, centre         ╰─────────╯
          84%        ← health %, 16pt white                   62%
          71%        ← mana %,   11pt blue                    93%

  ────────────────────── the whole middle is empty ──────────────────────
```

## Why it is here and not in `tbc/`

- `tools/verify-packs.lua` and `tools/verify-rebuild.sh` discover packs from
  `tbc/*/all-specs.txt`. Nothing in `poc/` is discovered as a shipped pack, which is the
  point — this has no version lineage, no root README table row, and no promise of
  support.
- It is **class-agnostic**. Every aura carries `use_class = false`; it loads for whoever
  imports it. A class folder demands a class gate and exactly one string per class, and
  this is neither.
- It is one layout experiment, not a spec's rotation. `references/rotation-design.md`
  governs packs; this is the step before a pack.

Its seed **is** still under repo discipline: `math.randomseed(20260890)`, deliberately
outside the eight registered pack seeds (20260809–20260816, including the retired
20260810). `verify-packs.lua` scans every `.lua` in the repo for seed reuse and passes
with this file present. Its 9 ids and 9 uids were checked against all 316 auras in the
seven shipped packs — **zero collisions**, so importing this can never "Update" over a
pack you already have.

## What it shows

Two static groups flanking the character, one per unit, at `(±180, -100)` from screen
centre — the same vertical band the packs' `<Class> - Resources` stack occupies today.

Per cluster, three auras:

| Aura | Region | What it does |
|---|---|---|
| `… Health` | `progresstexture`, 96px, CLOCKWISE | outer green ring, `%percenthealth%` at 16pt below the cluster |
| `… Mana` | `progresstexture`, 64px, CLOCKWISE | inner blue ring, `%percentpower%` at 11pt below that |
| `… Portrait` | `model`, 28px | a **live 3D portrait** of the unit, Blizzard head framing |

Design decisions worth naming:

- **Health is the outer ring.** Longer arc = finer visual resolution on the number that
  gets read most. The two numbers are colour-matched to their rings (white/green ring,
  blue/blue ring), so neither needs a label.
- **The target cluster self-hides completely.** The Health and Power prototypes both end
  in a hidden `WeakAuras.UnitExistsFixed(unit, smart)` test ANDed into the trigger, so
  with no target there is no state and all three regions vanish. No condition, no load
  gate, no custom code.
- **The mana ring is mana, not "current power".** `use_powertype = true, powertype = 0,
  use_requirePowerType = true` — the same three flags the shipped warlock/mage/priest
  enemy-mana bars use. A warrior or rogue target has no mana pool, so the inner ring
  disappears for them rather than parking a permanently empty blue circle. (Without
  `requirePowerType` the prototype's `total = math.max(1, UnitPowerMax(...))` floor turns
  a rageless unit into a valid *0%* state — an empty ring forever. That is the trap.)
- **The numbers sit below the rings, not in the middle.** The middle is the portrait, and
  a `model` region cannot carry a text subregion at all — SubText's `supports()` gate
  lists `texture / progresstexture / icon / aurabar / empty`, and `model` is absent. Each
  number rides on its own ring, so it appears and disappears with it.
- **Child order is the stacking order.** `FixGroupChildrenOrder` adds +4 frame levels per
  entry in `controlledChildren`, so the list is outer ring → inner ring → portrait, and
  nothing ever draws over the face. `sharedFrameLevel` is deliberately *not* set on the
  cluster groups: it would zero that offset and make the overlap order ambiguous.
- **`frameStrata` stays Inherited (1).** Raising it to sit over unit frames also puts the
  clusters over bags, vendors and quest panels.

## How to try it

1. Copy the whole of [`unit-orbs.txt`](unit-orbs.txt) — it is a single line, no trailing
   newline — or use the copy button on the [code block below](#import-string-v1).
2. In game: `/wa` → **Import** → paste. It arrives as a new group called
   **`Unit Orbs PoC`**. Nothing you already have is touched.
3. **Free the middle to see the actual comparison.** In the `/wa` aura list, right-click
   your pack's `<Class> - Resources` group and **Disable** it. Nothing is deleted and the
   same menu turns it back on. (Do not delete it — that would cost you a re-import.)
4. Go hit something. Target a caster, then a warrior, then a critter, then clear your
   target, and watch what each cluster does.
5. Done judging? Delete the `Unit Orbs PoC` group and re-enable your Resources group.

**The `/wa` editor preview will misrepresent this badly.** Selecting a group force-shows
every region with identical placeholder progress, so both rings sit at the same fill and
the target cluster renders with no target — exactly the two things this layout is about.
Judge it in combat, never in the editor.

## Verified vs assumed

**Verified** — from the WeakAuras source and this repo's own pipeline:

- `progresstexture` is the region type (lowercase, one word), registered in both 3.5.0 and
  current `ProgressTexture.lua`. `CLOCKWISE`/`ANTICLOCKWISE` are the only radial values.
- No Modernize block running on IV45 data renames *any* progresstexture fill field.
  `orientation`, `startAngle`, `endAngle`, `inverse`, `mirror`, `crop_*`,
  `foregroundTexture`, `backgroundTexture` all pass through untouched.
- `crop_x = crop_y = 0.41` is the **identity** value for a circular fill, not "no crop" —
  the circular path expands the texture by √2 so rotated quadrants never run off it, and
  `1 + 0.41` exactly cancels that. Setting 0 blows the ring up 1.41× and clips it.
- `auraRotation` is absent from the 3.5.0 default table but read unconditionally by
  current code as `data.auraRotation / 180 * math.pi`, so it is emitted explicitly.
- `progressSource` is overwritten with `{-1, ""}` by Modernize `< 71` regardless of what
  is emitted — which is why there is exactly **one trigger per ring**. Automatic progress
  reads a single trigger's state; a health and a power trigger on one region give you one
  fill, not two.
- `Ring_10px.tga` ships inside WeakAuras itself (registered under `Private.texture_types`
  → "Shapes", and present in the addon's `Media/Textures`). No media addon needed. Note
  the repo's usual `Circle_Smooth2.tga` is a **solid disc** and would fill as a pie wedge.
- The model region's unit binding: current code reads `model_fileId` (3.5.0 read
  `model_path`), and the migration bridging them is guarded by `WeakAuras.IsClassicEra()`,
  a *distinct* predicate from `IsTBC()` — so on a 2.5.x client that migration does not
  run. Both fields are emitted; `model_fileId` is the one that works.
- `unit = "target"` is legal on both prototypes on TBC (`Private.actual_unit_types_cast`
  strips only `boss` and `arena` for Classic).
- Round-trip: `W.verify` passes (fidelity, unique ids/uids, parent refs, complete
  `controlledChildren`). The build is deterministic — three runs, from two different
  working directories, produce the byte-identical 3222-char string
  `sha256 4bc60711…3d3f16`. Both repo suites still pass with this file in the tree.

**Assumed — nothing here has been rendered on a 2.5.x client.** Four things want a look:

1. **Ring stroke weight and the gap between the two rings.** The `10px` in `Ring_10px.tga`
   is the stroke in the *source* art, whose pixel dimensions are unknown, so "96 outer /
   64 inner leaves a clean gap" is estimated, not measured. Worst case the two bands touch
   instead of separating. Every number lives in the `G` table at the top of
   `generate.lua`; retune and re-run.
2. **Portrait framing.** `SetUnit` + `SetPortraitZoom(1)` is the Blizzard head-framing
   path and the code path is unambiguous, but `model_x/y/z` were not tuned against a real
   render. If the head sits wrong, those three numbers are the knobs.
3. **`maxpower` as a condition variable.** The inner ring carries
   `maxpower <= 1 → alpha 0` to kill the last empty-ring case: most NPCs report mana as
   their primary bar with a 0/0 pool, and the `math.max(1, ...)` floor makes that a valid
   0% state. The variable name was read out of the Power prototype, not exercised in game.
   If it is wrong the condition is a silent no-op and a powerless mob shows an empty inner
   ring — annoying, not broken.
4. **Legibility.** 16pt health / 11pt mana below a 96px cluster, and whether a 28px 3D
   portrait reads as a face at all.

## Honest limitations

- **No low-health colour escalation**, and that is deliberate. Recolouring a
  `progresstexture` fill from a condition needs the region's *condition property* name
  (`foregroundColor` is the likely one), and the research behind this PoC verified the
  region's **data** fields, not its `GetProperties` table. Guessing a property name
  produces a silent no-op that looks fine in the editor and does nothing in game — the
  exact failure this repo has been bitten by three times. The only condition property used
  here is `alpha`, which lives on the region prototype and is proven across all seven
  shipped packs. Colour tiers go in once that name is confirmed against the source.
- **No rage or energy ring.** Pinning the ring to mana is what buys the clean self-hide.
  A "whatever this unit uses" ring is possible — drop `use_powertype` and the trigger
  reads the unit's current bar — but colouring it per power type needs the same
  unverified condition property, and an uncoloured ring that is blue for a rogue's energy
  is worse than no ring. So a rogue or warrior sees a health ring and no inner ring.
- **Threat has nowhere to go.** The middle stack this replaces is health/mana/**threat**.
  Health and mana belong at a unit; threat is a relationship, not a unit property, so
  freeing the middle leaves threat homeless. That is an open design question, not an
  oversight — it is out of scope for a layout PoC and must be answered before any pack
  adopts this.
- **Real unit portraits are possible** — that was the open question, and the answer is
  yes. `modelIsUnit` + `SetUnit` renders whoever is targeted, including NPCs and mobs,
  and re-renders itself on `PLAYER_TARGET_CHANGED`, so the target's class never has to be
  known. The costs are real though: a 3D model frame is heavier than a texture, it cannot
  carry text, and its framing is the one thing here most likely to need tuning. If it
  disappoints in game, the documented alternatives are a static class icon for the player
  (class is known at build time via a load gate) and either a condition-driven class icon
  or no icon at all for the target.
- **Two clusters, no clones.** This is a fixed player/target pair. Focus, party or boss
  units are not built.

## Rebuilding

```bash
lua5.1 poc/unit-orbs/generate.lua
```

Deterministic and idempotent: it re-verifies uid continuity against the previous
`unit-orbs.txt` *before* overwriting it, so a re-run always imports as an Update rather
than a duplicate. `unit-orbs.txt` is canonical; the block below is a copy of it.

## Import string (v1)

```
!WA:2!nF163nXXv8SOqcSeAmkeOHKcgAmfstCSnymqt4ujB5erKLfRKTjeALMD3rAx7v7oE2vgz3M2IAARB6JK62M(m9H6RtBtFP((0NqoN(P8H7X)jWPFGp7)c6DMDLTm2bAO5CA(GxVAM7oZDU3Fp2vzY4gV4IhyzDIXmMCp2WEoE8ZglwSCX6R3bzXn8Cd4EoouZHTSDm5u3tZEGjCTd6ECUUF3pw35CiZt5D)0uItGfBVBYuJrCjShCtMiNhpGtSdUMUh3KYtgLcSUs6yVWceUz3f88CcSz86JxUSpniZo0zemfcwETvlN3W6HpVfF(WWuAYPvS9ClmpJQvH7vJ1mmI82lq3AlB3YE8QKamc1wHteEQvuuITmPwGLhFCMyAFvD88x2UIkNyih4eA(beEGQEzBxBFl1K4)cuBeWTRuHY9ZEyE0TVsYaXUtQXjdCvXvFg1XX20FFX7lzn8H0zYIqd54Pn9vVMFnD6C4HlFTYLTR3Q4WjYxOy(cj0kS6u54uCkT85sLjZk18PPQJ5v(WvOKMlPk1xTPjvhxbXHN)0PYKB0jYSun3O0sTLPT)01CXtZC0biooSDrK3xiC(X8mPV2DevUszwHY2v(zRH18UhTMJt3tzzhqVA4SH16TVeX1oSyEc4(h9QuIpnFa2JQeyD3W(s665sx2ep)IikkQjCFkwun9BicvKLq)jRsSDhf6dFaOFya4yWXX)VNBCKL8PoLZ5z7gOpCQSfsPDiBtw8ncSwbJGYDjotIBgUTpxRYCS0GPfjGeBfIRb2HhvmKy71ZpSwQuzBg4zmxy8Bl39pqnBZwzmp(rTS4J7mZX18nio0ynXgHMeB53g6K2fRcXAkos2HyMKoEet1wHBJmDHHw806y7IxCELW)xxb2MslI5018dOMJrQVL1(HT7wG7rbsbdX2Tj1NeiQEub7qGLDnTA5lsDADCcAPoJzupe4hgJMVdXnqPb11mHBfh6lSh4up31yCVkCQVFEVACd6J8q3XwGtadbBhojCFQqC1gCVazNsrJ4WSiXGHvHe7BX9WIhG7xrFlIP3LoFenBj5yIlSU6bBSgic1sQd0tpSU64bwJEDTWrB3htMyIcJZUp5GiXZtaKmMY2mWkzc8NRiNar8ut5GxE5WI6ZgMaVrSRkdqu3Slppmutz6llnjZoE2uW(4ydtettzGgTf3IfM6LrXnwxJYTxO7ZvJykGhDxOaRVvpxfdvkkUUdxrtQbc5DkY44ncaJY6kprzNYYYXUeIsMItynMk6MLxDRLu0XNOqM0ztfvVwhOHD0BrIiB1ssLwzhppEy5yomN0DOLwBJe6EhmQ21U5X65wS4HdQNTwvDkx3IAxXk4kWJly53itDWBn3v3av2loFU7SVEpE)WUXvrf2JkSxvwxiHire2xsfSy7sFvWEemNnuAbNUmXGEXeMMJ76FXPOKzsiewV4yutBYfJI0)IA2Uvk2FFS69guHapjYMBkfTL8afyKjxc3XIgoeFFl9aKw7gShTQ1qJgvn5O7bMxnjQlBeEdw8e3aV7ShgEGxbpuVhOB4GAsbz9qFpCO9dhqTHyHfI7LGdbVxOhv4WW7doIkCu4rG3)RDh6vT5CpU1nEMTDTGDUsBYzq4bPHhkhH6z(QlHDtxtH0SwYmPYoI0prRnt9A(v98cSYf90LAkz(JAZ9dSAfTggo2ml4dapXkrlUaikwq2UhotIXYvy8Kzsm8ZKyKrsxi9KiyCTgqeCzL1gzv2SOzo4Gnm8QYe7SfkhdXwP8QIqHbkIQ)bfxp5aIRdCYyWPJPDjbH(kSDTw4rnqOgCMwPpAHzo)KdEKJoaNB7k0LPwljpyISwpD28PhjvlpUn2dKLHLgoZ4d)mtLoFQqKw9iKwxQC5JrnTw80WOkWtjuEHNElq62QSWzTGNPeKXcgtbYkfkHX3O2iKtbohkiUVdRzyrnMzu4bI1yoc3MGTNgvj1zExIY1MJ4uJgV)d5Xo0t8KCdlIBfQ)(om8QknWgmsXcMhoNutf0uG8R0w4u(090dmHuNeMeMcop8SWfUm8C3ZwHlIzYhc(Wi4Riu6SHfEX1HgmwmGa6GPc7iVzeA5s3HybmdqHYqfWcSX11Pe7HV5pA4yadQUxaf7E8BE0BuEeM9Y32chaFJAgGVfeG4eb3gMtqPHlzb1LS0fKx)iYRF014T)R28w451YjstjL9JxAjzolQkkiboI2Y2TGiZPZwZMtLrlKQlTSy0vJV0nqUHpHfCzKhdnGpPk8cWNc(0kWNPeSOf8zLCp4fHph85vGVW1Fs4lkjl3j8sYE5adkFBBXTNAqb7aE5ldFjjrOWr1gP2etxXDYzGVSf8vGVk8kWxd(6RcVHVH1IhRvvKv4K2FcP2ZDb39aeMTLaOhcX5Y5fV1XUw9D7xxbD9ABWZdFSijnSeT5AzxLf927xWZRAjKZC1W9OSTdnTjS)MH)Krq1X9hMFf9ruZ8kirQJFJ5ucvy2tDlAIkRM3n8X(c11GgRdU5oSGhnzw8DnHDQjxB4Ep4ABsn)ZHvQ1(nFbfoXCo0qKAD7dmX2uY9gvzxqb6Dhs8OOVU1OrNVJdkV()Ul4LpLeiCMwLNe5nNy(zUWjMwOYW6sg3i2(IVkin(bkwsTMoY5Gf6CXMxzXd0rnb2Yn8vzfi8k0Gn9RYIMAJFvw0eT)Qmbmc22i7aRYY6lIK2j8UG7DRcq3UcvPWkpw)3uG0dcpe(PoTrrcqLag9WL2iscEu4XGE3(TFJalGB4lbcpmcPCSnjQ5sTIZ06Pkp0Sh5eS(Doz)WhmMa6Lu(sUJOk4j3Uwexz9weQRPVdf2mf93i26v0V(dlfXnuqD81PnpnQv7ucQEqu3f8qf4zVY)VvsVbvc8nOKv6BIuXTHY4FhEPRFgPq4vIecpwIzg7SZEb)KdQ)Mle(2t7dDR)Mc3D4BbFB4vB7LdFhPlo8D70(g(E)3yyF9mrE0W3FdEVqZ2(QWp4DygLWpeV71fT1FuhMJWpUe8tEBW87FGTy6686Yx2iBQQjw4sdL6M41b)uPdh8Z6WFd(5V1C2E9BkC91e2zWVaJ6xI)9RegwWV(TQnf8BI1bYs4pbTW6ZVfnMGFNWoc(9kWF4)v7h4pUoJN)j8NuG)CNgn(oJunrq96tZoVeS)xImwG)Qc83uIxnUzCZf3)6SsEe0v9kHQ)ksH)m317Sv(r)PnOZFQGjMoXK1mYF(uBIoFCFTJ17G92x85UZN))8
```
