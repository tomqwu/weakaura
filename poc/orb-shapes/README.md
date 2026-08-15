# Orb shapes — pick one

A **proof of concept**, not a class pack. Import it, look at it, tell me which shape wins,
and that one gets rolled into the seven packs. Delete it afterwards.

It draws **four variants side by side, all reading your own health and mana**, so every one
shows live data at the same time and the comparison is honest rather than a mock-up.

## Why the shipped orb looks like a wire

It is a **ratio** problem before it is a shape problem. The current packs put a **28px
portrait inside an 88px `Ring_10px` ring**: the arc is ten pixels thick, the gap around the
portrait is thirty, and about 70% of the circle is empty. It reads as a hoop with something
small lost in the middle. Variants A and B keep the circle and fix the proportions; C and D
answer the "maybe square?" question.

| | Shape | What it is | What it is testing |
|---|---|---|---|
| **A** | thick ring | `Ring_30px`, 84px, health outer + mana inner, 52px portrait | the same idea with the arc ~3× thicker and the empty gap ~4× smaller |
| **B** | one bold arc | `Ring_40px`, 88px, **health only**, 60px portrait | whether one heavy arc reads faster than two thin concentric ones |
| **C** | square sweep | square texture in `CLOCKWISE` orientation | the square you asked about, still radial — wipes like a Blizzard cooldown swipe and frames like a normal WoW icon |
| **D** | square + edge bars | square portrait flanked by two slim vertical bars | the most WoW-native option, and the only one that is not radial at all |

D is the safest bet mechanically: it uses `aurabar`, which every shipped pack already
depends on, rather than `progresstexture`. C is the most novel — a square texture in a
circular orientation is legal but is the one combination nothing in this repo has shipped.

## Trying it

Copy `orb-shapes.txt` whole → `/wa` → Import → paste. It appears just above centre, four
clusters in a row, captioned A–D.

Two things to expect. It is **class-agnostic with no load gates at all**, so it draws
everywhere including out of combat — that is deliberate for a comparison and would never
ship in a pack. And the `/wa` options window force-shows every aura with placeholder data,
so **close the options window before judging it**; identical fake timers on unrelated icons
and a bare `%` on a threat readout are the preview lying, not the auras being wrong.

Its seed is `20260891` — outside the registry, and verified to share no uid with any pack
or with `poc/unit-orbs`, so importing it cannot Update over anything you have installed.

## What happens next

Say which letter reads best in a fight and I will rebuild the seven packs' orbs to match,
keeping the parts that are already verified: the live portrait, the danger-colour
escalation on `foregroundColor`, the threat ring on the target with its zero-guard, and
the resource breakpoint ticks.
