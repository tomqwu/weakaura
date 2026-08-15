# Diablo globes

A **proof of concept**, not a class pack. Life on the left, mana on the right, both filling
bottom-to-top like liquid in a vessel, with the number inside the glass.

## Why this is a different thing from the ring orbs

The ring HUD in `tbc/` sweeps an arc around a circle: the shape is a hoop and the *arc
length* encodes the value. A Diablo globe is the opposite idea — the shape is a **container**
and the *waterline* encodes the value. Same WeakAuras region type, one different field:

```lua
orientation = "VERTICAL"   -- "Bottom to Top": the fill line rises
```

Watch the name. WeakAuras' orientation keys lie about direction in the usual way
(`references/gotchas.md`): **`VERTICAL` fills upward, `VERTICAL_INVERSE` fills downward**.
Getting it backwards produces a globe that drains from the top as you take damage — which
looks intentional, and is wrong.

Switching from the circular fill path to the linear one also swaps which fields are live.
`compress`, `slanted` and `slantMode` were inert on a ring and **matter here**; `startAngle`
and `endAngle` no longer do. `slant` is deliberately left at zero, because a straight
waterline is what reads as liquid.

## What it draws

| | Vessel | Notes |
|---|---|---|
| **Life** | left, 116px, D2 red | Brightens to a hot red under 35%. The number sits **inside** the glass. |
| **Mana** | right, 116px, D2 blue | Mana specifically — on a rogue or warrior the globe *vanishes* rather than sitting permanently empty. |
| **Target** | centre, 72px | Diablo has no target globe; WoW needs one. Half size so it reads as secondary, and it disappears entirely with no target. |

The unfilled portion is a near-black disc rather than nothing, which is what sells the
container read: coloured liquid rising into a vessel, not a shape appearing out of the void.
A brass rim is drawn over each globe at a higher frame strata so the fill looks like it is
*inside* the glass.

## The advantage over the ring build

The numbers go **in the middle**, where your eye already is. The ring version could not do
that: its centre is occupied by a live portrait, and a `model` region cannot carry a text
subregion at all — which is why those percentages ended up parked outside the rings where
they compete with the world. Dropping the portrait is what buys the centre back.

The trade is real: **no portrait**, so no live face for you or your target.

## Trying it

Copy `diablo-globes.txt` whole → `/wa` → Import → paste. It draws below centre — life at
`x = -300`, mana at `+300`, target between them.

It is **class-agnostic with no load gates at all**, so it draws everywhere including out of
combat. That is right for a comparison and would never ship in a pack. Close the `/wa`
options window before judging it: the preview force-shows every aura with placeholder data.

Seed `20260892`, verified to share no uid with any pack or with `poc/unit-orbs` and
`poc/orb-shapes`, so importing it cannot Update over anything installed.

## If you want this in the packs

Say so and I will roll it across all seven, keeping what is already verified: the danger
colour escalation on `foregroundColor`, the threat readout, the resource breakpoint marks,
and UID continuity so every pack still imports as an Update. The open question is what
happens to **threat** — it has no natural vessel, and on the ring build it lives as the
target's outermost arc.
