# Paladin — TBC WeakAuras (All Specs v23)

One import string covering all three specs. Elements load through Spell Known gates, so
the HUD adapts to your talents with no action from you.
Toolkit setup, once: `cd ../../tools/tbc-weakaura-creator/scripts && ./setup.sh`.

## All Specs — v23 (`all-specs.txt`, seed 20260811)

The full Holy / Protection / Retribution HUD: 45 auras in one import, arranged as a top-level
group at (0, -140) with five draggable sub-groups — the fifth being the PvP column added in v5,
which only ever loads inside an arena or a battleground. Every trigger matches by spell ID
(never by name), so it works unchanged on a zhCN client. `internalVersion` stays 45 /
`tocversion` 20501; modern WeakAuras migrates that forward on import.

**The Sill is a 164 × 36 px plate under a 172 × 44 px alarm rim at (0, −125), carrying three
160 px rails — threat, health, mana — with the numbers printed *inside* the rails and every
breakpoint drawn as a full-height waterline.** No aura is added or removed in v23; all 44
UIDs carry across.

## v23 — long and thin, not big

Third size pass, and the first two were fixing the wrong axis. v22 scaled the whole strip
uniformly to 300 px rails, which preserved the plate's original proportions and simply made the
same stubby block bigger — it read as a **UI panel** rather than a readout, and the identical
move was rejected in play in the rogue pack twice, at 300 px and again at 200 px rails.

**A vitals bar wants to be long and thin.** The fill's *travel* is the signal; its thickness
carries nothing. So v23 keeps the rails long and takes the height back to near the original:

| | v22 | **v23** | original v16 |
|---|---|---|---|
| rails | 300 × 22 | **160 × 13** | 100 × 11 |
| threat | 300 × 8 | **160 × 5** | 100 × 4 |
| plate | 304 × 62 | **164 × 36** | 102 × 31 |
| rim | ±6 | **±4** | ±3 |
| number | 20pt | **12pt** at x +51 | 11pt |
| mana floor / ruler | 6 / 2 px | **4 / 2 px** | 3 / 1 px |
| plate area | 18,848 px² | **5,904 px²** | 3,162 px² |

Less than a third of v22's area, while every rail stays **60 % longer** than the 100 px version.

**1.6 pixels per percent, and every mark still lands whole.** Every value this pack marks is a
multiple of five and 1.6 × 5 = 8, so the 20 % mana floor sits at x −48, the 70 threat notch at
+32 and the 25/50/75 ruler at −40 / 0 / +40 — all exact integers, verified by decoding the
shipped string. The invariant was never the number 100, and it was never "a whole number of
pixels per percent" either: it is that `markX()` is the only place a coordinate is derived.

**The lane stack is derived from this pack's own plate offset, not copied.** Paladin has
centred its plate at local y +6 since v16, so the three lanes are laid out symmetrically about
+6: threat 5 px at +20, health 13 px at +10, mana 13 px at −4, with 1 px gaps. That is 33 px of
content inside a 36 px plate — an even 1.5 px margin top and bottom. The build asserts the
arithmetic against the decoded string rather than trusting the comment.

**Both flanking columns go back to ±150**, the slots they held from v5 through v21; v22 had
pushed them to ±210 to clear a 316 px rim. Measured on the shipped string, with every dynamic
group projected six children deep:

| pair | clearance |
|---|---|
| Alerts column → alarm rim | **44 px** horizontally (53 px on the vertical axis) |
| PvP column → alarm rim | **46 px** |
| PvP column → cooldown row | **26 px** — the real binder on that side |
| Alerts column → cooldown row | 24 px horizontally (146 px vertically) |
| Alerts column → buff row | 44 px |
| alarm rim → seal buff row | **17 px** — the tightest number in the pack |

The frontier was swept, not guessed: the alert column is clean inwards to |x| = 106 and the PvP
column to |x| = 124 (where it meets the cooldown row, *not* the strip), so ±150 sits 44 px and
26 px inside their respective limits. The whole-pack scan is 178 projected rectangles, **0
overlaps**, and v23 adds an **all-pairs scan across the flanking stacks themselves** — Alerts,
PvP, Cooldowns, Buffs and the strip envelope, 10 pairs, 0 overlaps. That scan closes a real
blind spot: a scan that only tests everything against the strip structurally cannot see two
columns overlapping *each other*, and exactly that gap hid a 140 px bar sitting on top of an
icon in the rogue pack for a version.

A side benefit worth recording: the strip's clearance to the seal buff row above went from
**2.0 px to 17.0 px**, because the height came out of the axis that was tight.

**Nothing else moves.** No aura is added, removed, renamed, re-parented or re-triggered; the
uid stream is untouched (stable = 44, changed = 0, missing = 0, parentSame), so the re-import
is an Update. The swing runway stays deleted (v19) — it is not resurrected here.

## v22 — the rails get longer: 300px, three pixels per percent

Rails 200 → **300** long, plate 204 → **304**, alarm rim 216 → 316, the number moves to x +96.
Heights are unchanged — the strip is a **long** instrument now, not a taller one, because height
is what it has no room for and length is what a gauge is actually read by.

**Two columns moved to make it possible, and neither is a fudge.**

- **PvP column: x 150 → 210.** Rogue has always kept its PvP column at 200; paladin was the
  outlier. It is arena/BG-gated, so this is invisible in PvE.
- **Alert column: x −150 → −210**, mirroring it. The two flanking stacks are now symmetric
  about the character.

The alert move is worth explaining, because the strip could in principle have run *under* the
alerts without ever touching them: alerts grow **UP** from y −44 and the strip tops out at −88,
44px clear. But the build asserts x-separation from the alert column, and widening the strip
until it depends on the alert stack never growing *downward* is exactly the implicit coupling
that guard exists to prevent. Moving the column keeps the guard honest rather than arguing
around it.

**Three pixels is one percent.** Every mark still lands on a whole pixel, because every
breakpoint this pack draws is a multiple of five: the mana floor at −90, the 70 threat notch at
+60, the 25/50/75 ruler at −75 / 0 / +75.

Measured after the move: 178 projected rectangles, dynamic groups grown 6 deep, **0 overlaps**.
The alert column now clears by 32px. The tightest thing in the pack is still the 2px above the
strip to the seal buff row, which is a height constraint and unaffected by any of this.

## v21 — the rails were filling the wrong way

**Every rail filled right-to-left.** They should fill left-to-right, and now do.

The Sill shipped `orientation = "HORIZONTAL"` because WeakAuras' own dropdown labels it
that way — `Private.orientation_with_circle_types` maps `HORIZONTAL_INVERSE = L["Left to Right"]`.
That label is wrong, or at least describes something other than where the fill sits. The
implementation is the authority, `BaseRegions/LinearProgressTexture.lua`, where a bar calls
`SetValue(0, progress)`:

| orientation | texture x-range | fill sits | grows |
|---|---|---|---|
| `HORIZONTAL` | `0 → progress` | left | rightward |
| `HORIZONTAL_INVERSE` | `1-progress → 1` | right | leftward |

So every rail is now `HORIZONTAL`. This also finally aligns the breakpoint waterlines with the
fill: they were always placed by `x = value − 50` assuming a left-anchored bar, so on an
inverted rail the fill crossed them from the wrong side.

The design flagged this field as its one unverified value and asked for a 30-second live check.
That check has now happened, and the answer was the opposite of the transcription.

### Also in v21: the strip is twice the size

Health and mana rails go 100×11 → **200×22**, threat 4 → 8, the plate 102×31 → **204×62**, the
alarm rim 3px → 6px per side, and the numbers 11pt → **20pt** (threat 8 → 14). The strip moves
from y −110 to **y −125** to sit in the middle of the band its buff row leaves free.

**One pixel is one percent became two pixels is one percent.** The invariant was never the
number 100 — it is that a rail is a whole number of pixels per percent, so a breakpoint is
arithmetic rather than trigonometry. `markX()` is the single place that knows, so the mana
floor, the 70 threat notch and the 25/50/75 ruler all followed from one constant.

Verified collision-free: the 216×74 alarm envelope against 178 projected rectangles with every
dynamic group grown 6 deep, 0 overlaps, tightest clearance 2px to the seal buff row above.

The other six packs stay at the old size for now — paladin is the template.

## v20 — the number offsets were never actually applied

**A silent no-op that had shipped for a long time.** WeakAuras anchors a subtext with
`text_anchorXOffset` / `text_anchorYOffset` — `SubRegionTypes/SubText.lua` reads exactly those
keys, and the options panel writes them. But `SubText.lua`'s own `default()` still emits the
bare `anchorXOffset` / `anchorYOffset`, **and no `Modernize` step bridges the two**. This repo
emitted only the bare pair, so every offset was dropped and every number rendered dead on its
anchor point.

Across the seven packs that was **21 non-zero offsets doing nothing** — most visibly the rail
percentages, which sat centred in their rails instead of right-aligned at `x +32`.

This is not the `text_anchorPoint` case, and the distinction is the whole trap: *that* key **is**
renamed (`Modernize.lua`, `internalVersion < 80`, `subtext.text_anchorPoint → anchor_point`), so
emitting the old name is correct there. There is no such migration for the offsets. Both
spellings are now written and kept equal, `F.subtextOffset` is the only sanctioned way to move a
number, and `verify-packs.lua` now fails any subtext that sets one spelling without the other or
sets them to different values.

Nothing else in this version changed: no aura added, removed, renamed or re-parented, and every
uid is byte-identical.

## v19 — the swing runway is removed

**Removed on the player's report that it did not read well in combat.** `Paladin - Swing Timer`
is gone, and with it the three v18 ticks and the countdown that lived on it. 46 auras → 45.

This is a judgement the string cannot make for itself. WeakAuras' Swing Timer trigger is not
obviously broken from source — `GenericTrigger.lua` does clip `lastSwingMain` on a `PARRY`
against you and re-scale on `UNIT_ATTACK_SPEED` — but *handles the events* and *reads right while
you are actually swinging* are different claims, and only the second one matters. A runway you
cannot trust is worse than no runway: it invites you to time a 0.4s press against a bar that may
be lying to you.

[SwedgeTimer](https://github.com/hypernormalisation/SwedgeTimer) is dedicated to this one job and
carries `LibClassicSwingTimerAPI` plus a live latency monitor that no WeakAuras string can
reproduce without custom Lua. **Swing timing is its job now.** This pack keeps what it is
genuinely better at: what your seals are doing.

### What this does NOT remove, and the caveat that comes with it

`Twist NOW` and `RE-SEAL` **stay**, and they still read the same WeakAuras Swing Timer trigger —
that is how they know a swing is in flight at all. So if the trigger itself is what was
misbehaving, these two inherit it. They are kept because:

- the seal-state half of each prompt (Seal of Command present / missing, a twist seal up) is
  independent of swing timing and is correct regardless;
- with SwedgeTimer drawing the runway, the prompts and the bar are no longer two views of the
  same possibly-wrong number sitting next to each other, which is the confusing case;
- and both are one right-click from disabled in `/wa` if they turn out to share the fault.

**Tell me if they do.** The two of them are the last things in this pack that depend on WA's
swing timing, and they would go the same way.

### Everything else is untouched

Seal uptime and the missing-seal alarm, the Judgement debuff, Holy Shield, the Sill, the alert
column, the 14-icon cooldown row and the PvP layer are byte-identical. The removal is declared
in two places — `-- WA-REMOVED (v19): Paladin - Swing Timer` beside the burned uid, and an
explicit one-id allowance on the continuity check — so it shows up as a reviewable line in a
diff rather than as a count that quietly dropped. All 44 surviving auras keep their uids.

The uid the runway consumed is **burned, not freed**: `W.uid()` is still called where the bar
used to be built, so every aura created after it keeps the draw it has always had. Reusing that
number later would make a brand-new aura "Update" over a swing bar still sitting in someone's
saved variables.

### After updating

WeakAuras will not delete the old aura for you. Right-click **`Paladin - Swing Timer`** in `/wa`
and delete it once.

## v18 — what SwedgeTimer knows, rebuilt from WeakAuras primitives

[SwedgeTimer](https://github.com/hypernormalisation/SwedgeTimer) (hypernormalisation, GPL-3.0) is
the reference swing-timer addon. **No code is copied from it** — it is a separate addon, and this
repo ships pure WeakAuras with no custom logic beyond two one-line trigger expressions. But two of
its ideas are the right ones, and both answer the question a twister actually asks, which is not
*where is my swing* but **can I act before it lands**.

### The runway now has three marks, not one

| mark | at | means |
|---|---|---|
| gold, solid | 0.40s | the seal must **land** by here — the mechanic's own truth |
| gold, faint | 0.55s | you must **press** by here, allowing ~150ms of latency |
| cool white, thin | 1.50s | past this, **no filler fits** before the swing |

**The press/land distinction is one this pack previously had wrong.** SwedgeTimer draws a
right-aligned latency "deadzone" — `frac = (self.latency.world_ms / 1000) / self[hand].speed` —
the tail of the swing in which a press can no longer reach the server in time. 0.4s is when the
seal must *land*; the moment you must *press* is 0.4s **plus your latency**. WeakAuras cannot read
latency without custom Lua, so this cannot be automatic: the faint mark ships at a nominal 150ms.

> **Set it to your own ping.** In `/wa`, select `Paladin - Swing Timer` → the second Tick
> sub-region → Placement, and enter `0.4 + your world latency in seconds` (250ms ping → `0.65`).
> It is a plain editable list; nothing else needs to change.

**The GCD floor** is SwedgeTimer's GCD underlay — `gcd_progress = (self.gcd.expires - tab.start) /
(tab.ends_at - tab.start)` — reduced to a static mark. 1.5s is the TBC base global cooldown, so
treat it as a **floor**: fill left of the mark, a filler definitely fits; just right of it, it
still might, since haste can shorten the GCD.

### Both twist prompts now grey out when you cannot press

A prompt you cannot obey is noise — and worse than noise here, because a twist started on a locked
GCD lands *after* the swing and loses the proc you were reaching for. `Twist NOW` and `RE-SEAL`
each gained WeakAuras' native **Global Cooldown** trigger, and desaturate while it is running.
**Grey means wait, colour means press** — the same distinction the Hammer of Wrath prompt already
draws with range.

The GCD trigger deliberately **does not gate visibility**. `F.triggers` defaults to
`disjunctive = "all"`, so simply appending it would have hidden each prompt whenever the GCD was
*not* running — the exact inverse of the intent, and it would have looked like "the twist prompt
barely fires any more". A one-line `customTriggerLogic` keeps the visibility test on the real
triggers; the GCD trigger exists only to feed the condition, read through the built-in `show`
("Active") bool that WeakAuras defines for every trigger.

### What SwedgeTimer does that this pack cannot

Stated plainly, because these are real:

- **Latency compensation is manual here.** SwedgeTimer measures your latency live and moves its
  deadzone with it. This pack ships a constant you set once.
- **Swing-timer edge cases.** SwedgeTimer uses `LibClassicSwingTimerAPI` for parry-haste, weapon
  swaps and swing resets. This pack uses WeakAuras' own Swing Timer trigger. Which is more
  accurate on a 2.5.x client is not something the string can prove — if the runway ever
  disagrees with reality, that is the first suspect.
- **Its own paladin module has no twist logic at all.** It tracks Exorcism and Art of War
  (59578), which are Wrath abilities. On seal twisting specifically, there was nothing to port.

Running both is fine — they share no saved variables — but you will have two swing bars.

## v17 — the twist cycle is prompted end to end

**The gap.** `Twist NOW` requires Seal of Command to be **up** and you to be **swinging**. So it
told you to press your second seal — and the instant you obeyed, Seal of Command was gone, the
prompt vanished, and nothing told you to put it back on before the next swing. `Seal MISSING
(Ret)` didn't cover it either: it fires only when *no* seal is up, and after a twist a seal
**is** up. The half of the cycle that is easiest to forget under pressure was the half with no
cue at all.

**`Paladin - RE-SEAL`** is its mirror image — swinging **and** Seal of Command missing **and** a
twist seal (Seal of Blood or Seal of the Martyr) present — so between the two prompts the
`SoC → twist seal → SoC` loop is covered from both ends. It uses the same gold glow inside the
0.4s window, sits in the same alert column, and carries the same Seal-of-Command spell-known
gate, so no Holy or Protection paladin ever loads it.

**Why the third trigger.** Requiring the twist seal makes RE-SEAL and `Seal MISSING (Ret)`
mutually exclusive *by construction*: with no seal at all the missing-seal alarm owns the
moment, and RE-SEAL stays quiet rather than shouting a second, less urgent instruction over it.

### The icon is resolved by your client, not hard-coded

`Twist NOW` ships `displayIcon = ability_paladin_sealofblood` — the **Horde** seal. Its logic is
faction-correct (it watches Seal of Command, not the seal you twist *to*), but an Alliance
paladin sees the wrong art, and guessing a Seal of the Martyr texture path is exactly the kind
of unverifiable string that renders as a question mark.

So RE-SEAL asks the game instead. Verified in the installed WeakAuras **5.21.10**:

- `RegionTypes/Icon.lua` `UpdateIcon()` — `iconSource == -1` uses `state.icon`, `0` uses
  `displayIcon`, and a positive `N` uses `states[N].icon`.
- `BuffTrigger2.lua` `GetNameAndIconSimple()` — when `useExactSpellId` is set it walks
  `trigger.auraspellids` and returns `GetSpellInfo(spellId)`'s icon.
- That value becomes `fallbackIcon`, which is what an unmatched (`showOnMissing`) state carries.

`iconSource = 2` therefore pulls **Seal of Command's real in-game art** out of the missing-aura
trigger: correct on every client, locale and faction, with no texture path to get wrong.

### Honest limitation: both prompts assume you are twisting

`Twist NOW` nags whenever Seal of Command is up and you are swinging; RE-SEAL nags whenever it
is missing and a twist seal is up. If you deliberately run a **single** seal without twisting,
one of the two will fire constantly. That assumption predates v17 — RE-SEAL just makes it
symmetrical rather than introducing it. Disable whichever one you don't want in `/wa`; nothing
else in the pack depends on either.

### Where the aura is built in the script

`F.icon()` consumes a `W.uid()` **where it is called**, so constructing RE-SEAL at its logical
position beside `Twist NOW` shifted every later call site and re-numbered **13 existing auras**.
WeakAuras matches auras across imports by uid, so that would have imported a third of the pack
as duplicates instead of an Update. The aura is therefore *constructed* at the foot of
`generate.lua`, next to the v14 uid burners, and adopted into the alert column from there. The
rationale still lives beside `Twist NOW`, with a pointer. 45 auras become 46; all 45 keep
byte-identical uids.

## v16 — The Sill: the ring cluster becomes a 102×31 instrument under your feet

**What changed:** the three concentric rings and the 3D portrait that sat 270px to your left
are gone. In their place is **The Sill** — a 102 × 31 px strip directly under your character at
absolute **(0, −110)**, built from three 100px rails stacked on a dark plate, **where one pixel
is exactly one percent**.

```
                       your character
     +--------------------------------------------------+
     |===============================...o...............|  threat 100x4   o = the 70 notch
     |############:###########:############:# 78        |  health 100x11  : = 25/50/75 ruler
     |#########!##:#######....:............:. 41        |  mana   100x11  ! = the 20% floor
     +--------------------------------------------------+
      0%                       50%                   100%
     x -51 . . . . . . . . . . . . . . . . . . . . . +51    y -91.5 .. -122.5
```

One character above is two pixels: threat at 62% (short of the 70 notch), health at 78%, mana
at 41% and still well above the floor. At 80%+ threat a 3px red rim lights up around the outside
of that box — a 108 × 37 quad drawn *behind* the 102 × 31 plate, so only the part that sticks out
is visible and no number is ever painted over.

No aura is added and none is removed — all 45 keep their UIDs (`changed = 0`, `missing = 0`),
so this is an **Update**, not a second copy.

| | v15 | v16 |
|---|---|---|
| shape | three arcs + a face, 100 / 84 / 62 / 44 px | three rails, 100 × 4 / 11 / 11 on a 102 × 31 plate |
| position | (−270, +40) — open screen, left of centre | **(0, −110)** — the centre line, under you |
| footprint | 10,000 px² | **3,162 px²** (3.16× denser) |
| health % | 16pt, centre of the cluster, on your face | 11pt, **inside the health rail** at x +32 |
| mana % | 12pt, below the rings | 11pt, **inside the mana rail** at x +32 |
| threat % | 10pt, above the outer arc | **off** — replaced by a notch at the 70 line |
| breakpoints | one arc-mark, placed with `sin`/`cos` | full-height waterlines at `x = v − 50` |
| pixels spent on decoration | 1,936 (the portrait) | 0 |

### Why a strip instead of a ring

A 0–100 quantity has exactly **100 distinguishable states**. A 100px rail carries all 100 and
not one pixel more — that is the exact length at which the gauge is lossless. The rings bought
712.5px of arc inside a 10,000 px² box to show the same 300 states, and 19.4% of that box was a
3D model that decides nothing: no paladin button press follows from looking at your own face.

It also makes every breakpoint arithmetic instead of trigonometric. The old 20% mana mark was
`r = 62/2 × 0.94; x = r·sin(2π·0.2); y = r·cos(2π·0.2)` → `(27.71, 9)`. The new one is:

> **x(v) = (v / maxpower − 0.5) × 100**, i.e. **x = v − 50** for a 100-max resource. 20% mana
> is at **x = −30**. That is the whole placement system.

And the numbers finally have something behind them. v13/v14 hung them on open screen; v15 moved
the health number onto a 44px face to give it *some* contrast. v16 gives **every** number a dark
bordered plate of its own to print on, which is what makes 11pt survive a snow field, a lit
floor and a Netherstorm skybox.

### The three rails, top to bottom

- **Threat** — 100 × 4, the thinnest lane, because `threatpct` is an early-warning *ratio*, not
  a quantity you spend. Green, **orange from 70%**, **red once you hold aggro**. A white
  **2 × 4 notch at x +20** marks the 70 line: when the fill touches it, stop or dump. Party or
  raid only, never in an arena, and it hides itself at zero threat — so solo, this lane is
  simply empty.
- **Health** — 100 × 11, green, **hot red below 30%**. `%percenthealth%` prints inside it at
  11pt, x +32. Three faint hairlines at 25 / 50 / 75 turn "estimate a fraction" into "count
  quarters". Fades to 50% out of combat.
- **Mana** — 100 × 11, blue, **red below 20%**, with the same number and the same ruler, plus
  the one genuinely new signal in this version.

### The mana floor is now drawn, not only coloured

A decode of the shipped string says something worth saying out loud: **`percentpower < 20 → red`
on the mana ring is the only power threshold in the entire pack.** Nothing in the Alerts column
fires on mana; no other aura in the string even carries a Power trigger. For a Holy paladin,
whose whole game is mana, this rail *is* the mana instrument — and a threshold you can only see
*after* you cross it is half a signal.

So the mana rail carries a permanent **3 × 11 waterline at x = −30 (20% mana)**, in a bright
red-orange chosen to stay visible *on top of* the red the rail turns underneath it. You can now
watch the floor coming from 60% instead of finding out about it when the colour changes. Prot
and Ret will mostly ignore it; it costs 33 px² and never moves.

The mana number also gets lighter — `(0.55, 0.75, 1)` → `(0.82, 0.90, 1)`. The old tint was
picked when the two percentages were stacked outside the cluster on open screen and the colour
was the only thing telling them apart. Printed *inside* a blue rail it was the lowest-contrast
choice available; the rail itself now says which number this is.

### What you lose, stated plainly

- **The live 3D portrait is gone.** Its UID is now the Sill Plate — the dark panel the rails are
  drawn on. That panel is load-bearing rather than decorative (it is what makes an 11px bar and
  an 11pt number readable against a bright world), but it is not a face, and this is the change
  most likely to annoy you. v15's own notes argued the opposite case; that argument was about a
  ring cluster, which no longer exists here.
- **The threat percentage is switched off**, not deleted. It keeps its sub-region index, so it
  is one checkbox away in `/wa` (select `Paladin - Threat` → Display → the text sub-region →
  tick it back on). It is off because `threatpct` is scaled so 100 = pulling aggro: "is the fill
  past the notch" is read faster than "is 68 nearly 70", and it was the last element of the old
  cluster printing onto bare screen.
- **The numbers straddle the fill edge.** With a left-to-right fill and the number at x +32, the
  edge passes under the digits at about 82%. `OUTLINE` + a black shadow + the plate are the
  mitigation. Judge it in combat, not in the editor.
- **A ring is prettier than a bar.** Three stacked rails are a car dashboard; the old cluster
  was a character. That is the honest aesthetic cost of a 3.16× density gain.

### The ≥80% threat alarm is a rim around the strip, not a wash over it

`Paladin - Threat Flash` keeps its UID, its `threatpct ≥ 80` trigger, its Retribution gate, its
not-in-an-arena gate and its explicit red `(1, 0.10, 0.10, 0.85)` on `ADD` blend. It is now
**108 × 37** — the 102 × 31 plate plus **3px on every side** — drawn **first**, at the very
bottom of the strip's stack. Only the 3px band that sticks out past the plate reaches your eye:
a pulsing red rim around the whole instrument. Everything inside it sits behind a 45%-black
plate and behind every rail, number and waterline, so **nothing is ever composited over a
readout**.

That construction is forced by the art, and the art was measured rather than guessed.
`Square_White_Border.tga` as WeakAuras ships it is a 256 × 256 32-bit TGA in which **64,516 of
65,536 pixels (98.44%) are fully opaque**. Every pixel inset 8px or more from the edge —
57,600 of them — has alpha 255 and a minimum RGB channel of 167. The centre scanline's red
channel over x = 0…13 reads `0, 156, 100, 56, 40, 57, 102, 158, 206, 236, 250, 254, 255, 255`,
and the centre pixel is `rgba(255, 255, 255, 255)`. In plain terms: it is a **filled white
square with a dark bevel baked into its edge**. It is *not* an outline, it is *not* hollow, and
its interior is *not* transparent.

So a single region on that texture cannot trace a frame. Drawn at the plate's own size, on
`ADD`, on top of the strip — which is what the first cut of v16 did — it is a full-area red
quad over every rail and every number for as long as threat stays ≥ 80%, washing out the
readouts at exactly the moment you most need to read them. Making it 3px bigger per side and
putting it **underneath** is the fix, and it is the right one whether the art turns out to be
filled or hollow. The build asserts **both halves** — `alarm.width == plate.width + 6`,
`alarm.height == plate.height + 6`, `controlledChildren[1]` is the alarm and `[2]` is the plate
— because dropping either one silently turns the rim back into the wash.

### Where it sits, and why it fits

Absolute **(0, −110)**. The plate is **x −51…+51, y −91.5…−122.5**; the alarm rim, which is the
widest thing the instrument ever draws, is **x −54…+54, y −88.5…−125.5**. The collision scan is
run on the **rim**, not the plate — verified by decoding the shipped string and projecting every
region in the pack, with all three dynamic groups grown six children deep because they grow
without bound:

```
scanned envelope    108x37 (the alarm rim), x -54..+54, y -88.5..-125.5
173 projected rectangles, 0 overlaps
tightest clearance   8.5px  (the buff row at y -80..-40; plate alone: 11.5px)
cooldown row        64.5px  below (y -190..-222; plate alone: 67.5px)
alert column        76.0px  to the left (x -170..-130, grows UP without bound)
PvP column          78.0px  to the right (x +132..+168, grows DOWN without bound)
swing timer         26.0px  clear: it runs x -220..-80 at y -71.5..-80.5
```

Nothing else in the pack moves by a pixel. That scan is not a one-off — it is re-run inside
`generate.lua` against the string it is about to write, so a future version cannot slide a row
into the strip without failing the build.

### After updating

**Leave the `Arrangement` category CHECKED in the update dialog.** This version re-parents,
re-orders and moves the group — all of which travel in that category, and none of which arrive
without it. If you had dragged the cluster somewhere you liked, you will have to drag the strip
there instead; if you leave Arrangement unchecked you will get a 102 × 31 strip still sitting at
(−270, +40) with rails in the wrong draw order.

There is **nothing to delete**: v16 adds and removes no aura. Two are renamed in place —
`Paladin - Player Rings` → `Paladin - Player Sill` and `Paladin - Player Portrait` →
`Paladin - Sill Plate` — and WeakAuras matches by UID, so the rename applies on Update.

### What did not change

Every trigger, every load gate, every condition and every escalation colour on the three rails
is **byte-identical** to v15 — diffed field by field against the shipped v15 string, not
eyeballed: the Threat Situation trigger and its `threatUnit` argument, the party/raid and
not-in-an-arena gates, the 70%/aggro/`threatvalue ≤ 0` conditions, the health 30% red, the mana
20% red, both `maxhealth ≤ 0` / `maxpower ≤ 1` guards, the out-of-combat fades, the alarm's
80% threshold and Ret gate, and the three canonical colours. The other 38 auras in the pack —
buff row, alert column, cooldown row, PvP layer, Swing Timer — are byte-identical tables.

The two deliberate exceptions, both listed above: the plate gains the Unit Characteristics
state feeder and the `inCombat == 0 → alpha 0.5` condition the rails already had, so the whole
instrument dims as one object out of combat; and the mana number's tint is lightened.

The Swing Timer's table is byte-identical **except** for the two sub-regions v16 appends to it,
which is the next section.

### The twist window is now a mark you can see coming

The Retribution swing runway told you about the twist window only by turning gold at ≤ 0.4s,
with the `Paladin - Twist NOW` icon glowing in the same instant. Both of those fire **inside**
the window — the moment you needed to have already pressed. So the runway gains two things:

- **A gold tick at the 0.4s line**, so you watch the fill travel toward a fixed mark instead of
  waiting for a colour to arrive.
- **The exact time remaining, at one decimal**, right-aligned inside the bar. A 0.4s window is
  not learnable from a bar edge alone, and at zero decimals every value inside the window
  displays as `0`.

**Why the mark could not simply be drawn at a fixed offset.** The twist window is an absolute
0.4 seconds, but the runway's length is your weapon speed. A hard-coded pixel position would be
right for one weapon and wrong for every other — and wrong again the moment Wrath of Air or
Swift Retribution changes your haste. It is the kind of defect no screenshot reveals: the bar
looks correct, the twist just misses.

WeakAuras' `subtick` sub-region solves it natively. With `tick_placement_mode = "AtValue"` and
`tick_placements = {"0.4"}`, `UpdateTickPlacementOne` re-reads `GetMinMaxProgress()` on every
update, so on a timed progress — where the value is seconds *remaining* — the mark lands exactly
where 0.4s are left, at any weapon speed, under any haste, with nothing to recompute on a respec
or a weapon swap. The build asserts the mark's placement against the same `TWIST_WINDOW`
constant that drives the gold recolour, so the tick and the colour can never disagree about
where the window is.

`subtick` is **aurabar-only** — `Tick.lua`'s `supports()` returns `regionType == "aurabar"` and
nothing else. This runway is the pack's one aurabar, which is exactly why the mark can live here
and could never have gone onto one of the Sill's progresstexture rails.

### Honest limitation: this raises the client floor

`subtick` did not exist in WeakAuras 3.5.0, the data version these strings declare. It renders
on any current client (verified against the installed **5.21.10**) and is simply absent on a
genuinely old one. Nothing else depends on it — the gold recolour at ≤ 0.4s and the glowing
Twist NOW icon both still fire — so an old client loses the early warning but keeps the cue it
already had.

## v15 — your health number moves into the middle of the cluster

**What changed:** the **health percentage now prints in the centre of the cluster, on your
portrait**, at 16pt instead of 13pt. Through v14 it hung 54px *below* the rings and the mana
number 70px below that — two small glyphs floating on open screen with nothing behind them but
whatever the game world happened to be showing. Against a snow field, a lit floor or a
Netherstorm skybox they were unreadable, which is the complaint this version exists to fix.
Mana takes the slot health has vacated, just under the health ring, and grows to 12pt now that
it is the only number down there. Threat does not move.

```
              64%    <- threat %, above the outermost ring (unchanged)
        ,-----------.
      /   ,-------.  \   <- THREAT  (outermost, 100px)  — party/raid only
     |   /  ,---.  \  |  <- health  (84px)
     |  |  | 74% |  | |  <- your face (44px) with your HEALTH % on it, 16pt
     |   \  `---'  /  |  <- mana    (62px)
      \   `-------'  /
        `-----------'          your character
              41%    <- mana %, 12pt, in the slot health used to occupy
        you, (-270, 40)
```

| Number | v14 | v15 |
|---|---|---|
| **Health** `%percenthealth%` | 13pt, `y −54` (below the rings) | **16pt, `y 0` — dead centre, over your portrait** |
| **Mana** `%percentpower%` | 10pt, `y −70` | **12pt, `y −54`** — the slot health vacated |
| **Threat** `%threatpct%` | 10pt, `y +58` | unchanged |

### Why this needed the draw order changed too

Moving the offset on its own would have done **nothing visible**. Children of a WeakAuras group
draw in `controlledChildren` order and later children draw on top; through v14 the portrait was
adopted **last**, on purpose — "so nothing draws over it". That also meant the 44px portrait
covered anything a ring's text put in the middle. The number would have been in the string and
invisible on screen.

So the portrait becomes the **first** child of the cluster, and the rings draw over it:

```
v14   Threat  ->  Health  ->  Mana  ->  Threat Flash  ->  Player Portrait
v15   Player Portrait  ->  Threat  ->  Health  ->  Mana  ->  Threat Flash
```

**Your face is not covered by this**, and that is a fact about the texture rather than a matter
of taste. `Ring_20px.tga` is a **true annulus** — its art occupies only its own band — and the
stroke is 20/256 of the drawn size, so at this pack's diameters the bands sit at **42.19…50.00**
(threat and the flare), **35.44…42.00** (health) and **26.16…31.00** (mana) from the centre,
while the portrait is **0…22**. Nothing overlaps. The only ring-owned pixels that now reach the
middle of the cluster are the sub-texts, which is the entire point.

This also settles a v13 note that was half right (*"the portrait is back, so the numbers are
outside the rings again"*). A `model` region genuinely cannot carry text — that limit is real
and unchanged. But it is a limit on which region *owns* the text, not on where the text may
*land*: the health percentage is a sub-text of the **health ring**, a `progresstexture`, which
always could carry one. Anchored at its own ring's centre, it lands on the face.

### What did not change

**Nothing else at all.** No aura was added or removed — still 45 — and every UID is
byte-identical to v14 (`changed = 0`, `missing = 0`), so this re-imports as a clean **Update**
with no leftovers to delete. Not one trigger, load gate, condition, colour, spell ID, ring
diameter or position changed anywhere in the pack; the exhaustive field diff against v14 is
**nine fields**: two offsets, two font sizes and the five-entry child order. The text tokens,
their colours, the `OUTLINE` font and the shadows are untouched — mana keeps its blue tint,
which is now what identifies it, since it no longer sits beneath a white sibling. The Swing
Timer clearance is unaffected: the mana number rising from `y −30` to `y −14` moves it *away*
from the runway at `y −71.5`.

## v14 — one cluster, and threat is your own outermost ring

*Historical. The percentage positions this version describes were changed in v15 — the health
number is in the middle of the cluster now; see above. Everything else below still ships.*

**What changed:** the **target cluster is deleted**. Its health ring, its live portrait and the
group that held them are gone — three auras removed, 48 down to 45. **Threat did not go with
it**: it moved onto *your* cluster as a new **100px outermost arc** around the health and mana
rings you already had.

Everything else is untouched. Not one trigger, load gate, condition, colour, spell ID, size or
position outside the cluster changed — buffs, alerts, cooldown row, procs and the whole PvP
layer are byte-identical to v13, and all 44 surviving auras keep their exact UIDs.

```
              64%    <- threat %, above the outermost ring
        ,-----------.
      /   ,-------.  \   <- THREAT  (outermost, 100px)  — party/raid only
     |   /  ,---.  \  |  <- health  (84px)
     |  |  |  @  |  | |  <- your face (44px)
     |   \  `---'  /  |  <- mana    (62px)
      \   `-------'  /
        `-----------'          your character
              74%    <- health %
              41%    <- mana %
        you, (-270, 40)
```

| Ring | Size | Reads | Escalates to |
|---|---|---|---|
| **Threat** (outermost) | 100px | your % of the pull threshold on your target | orange at **70%**, red once you **hold aggro** |
| **Health** | 84px | your health | hot red under **30%** |
| **Mana** | 62px | your mana — the paladin resource in all three specs | red under **20%** |
| **Portrait** | 44px | your live 3D model | — |

### Why the target cluster went

Your target's health is already on the target frame *and* on its nameplate. For the entire
game, a third copy of it parked at (+270, 110) changed nothing about the next button you press
— it duplicated the very frame you were looking at when you selected the target. A HUD element
earns its place by changing a decision; that one never did, so it is removed rather than shrunk
or moved.

### Why threat moved instead of dying

Threat is the one thing that cluster showed which **nothing else in the game shows**, and a dps
who pulls aggro dies — losing it would have been a real regression. So it comes home as the
outermost ring of your own cluster, which is also the more honest reading: it is *your* threat,
and the target only names the table it is measured against.

It keeps everything it had: the Threat Situation trigger, the party-or-raid gate, the
never-in-an-arena gate (v6), the green → orange at 70% → red on aggro escalation, and the
zero-threat guard without which a ring with a zero total draws as a **full** circle — i.e. as
total aggro at the exact moment you have none. The Retribution-only **Threat Flash** resized
84 → 100 with it, so the 80%+ pulse happens *on* the threat ring instead of orbiting a radius
nothing occupies any more; it is still Ret-only, so a tank sitting at 100% is never alarmed.

Because of those two load gates, **solo and in the open world the cluster is still just two
rings and a face**. The third arc only appears when threat is a real relationship.

Health (84), mana (62) and the portrait (44) do not move by one pixel, and the cluster stays at
its absolute **(-270, 40)**. The threat percentage moved out with its ring, from `+54` to `+58`,
so it clears the larger radius. The wider cluster now spans `x −320…−220`, still **50px clear**
of the Alerts column at `x −170…−130` — and because that column is a dynamic group that only
grows *upward*, the gap holds at any stack depth, not just while one alert is showing.

### After updating: one group to delete by hand

**WeakAuras never deletes an aura that an import does not mention.** Everything this pack has
ever done before was a transform in place, so previous versions could promise there was nothing
to clean up. v14 genuinely removes regions, so after you import it there will be **one leftover
group** sitting in your WeakAuras:

> **`Paladin - Target Rings`** — right-click it in `/wa` and choose **Delete**. Deleting the
> group deletes the two auras still inside it, `Paladin - Target Health` and
> `Paladin - Target Portrait`.

Nothing else is left behind, and nothing breaks if you leave it — it simply keeps drawing the
old target cluster at (+270, 110) forever. Leave **Display** and **Arrangement** handling as
usual in the Update dialog (untick Arrangement if you have dragged the pack somewhere you like).

## v13 — the rings are back, and so are the faces

*Historical. The target cluster this version describes was deleted in v14, and threat moved
onto the player cluster — see above.*

**What changed:** the Diablo globes are gone. Your health and mana are **two rings around a
live portrait of you** again, and your target's health and your threat on it are two rings
around a live portrait of *them*. Two arcs and a face, twice — that is what makes the two
clusters read as a matched pair instead of as three unrelated jars of coloured liquid.

Nothing outside the two clusters changed: not one trigger, load gate, condition, spell ID,
size or position anywhere else in the pack. No aura was added or removed — 48 before, 48
after — and every UID is identical, so this imports as a plain in-place **Update**.

```
                                                    64%      <- threat %, above its ring
                                                 ,-------.
                                               /  ,---.   \  <- THREAT  (outer, 84px)
                                              |  |  @  |   | <- their face (44px)
                                               \  `---'   /  <- health  (inner, 62px)
                                                 `-------'
                                                    88%      <- target health %
                                            the target, (+270, 110)

       ,-------.
     /  ,---.   \  <- health (outer, 84px)
    |  |  @  |   | <- your face (44px)
     \  `---'   /  <- mana   (inner, 62px)
       `-------'                  your character
          74%    <- health %
          41%    <- mana %
     you, (-270, 40)
```

| Cluster | Where | Outer ring | Inner ring | Centre |
|---|---|---|---|---|
| **You** | `x = -270, y = 40` | **health**, 84px, green — hot red under **30%** | **mana**, 62px, blue — red under **20%** | your live 3D portrait, 44px |
| **Target** | `x = +270, y = 110` | **threat**, 84px — green, orange from 70%, red once you hold aggro | **health**, 62px, green — orange-red under **20%** | the target's live 3D portrait, 44px |

Those sizes and positions are **identical in all seven class packs**: outer 84, inner 62,
portrait 44, clusters at `x = ±270`. Roll another class and the two clusters are in the same
place, at the same size, meaning the same things.

`x = ±270` is clearance, not taste. The Alerts column occupies `x −170…−130` and the PvP
column `x +132…+168`, and both are *dynamic* groups that grow vertically — at `±190` the
alert stack climbs into the cluster from the second simultaneous prompt onward. `±270` is the
tightest symmetric pair of positions that stays clear at any stack depth. The 140×9 **swing
runway** did not move either: it stays at `(−150, −76)`, 8px clear of the cluster horizontally
and 31px clear of the lowest percentage vertically.

### The portrait is back, so the numbers are outside the rings again

A WeakAuras `model` region cannot carry text — that is a hard limit of the region type, not a
choice — so with a face in the middle of each cluster the percentages hang below the arcs
again: health at 13pt just under the outer ring, mana at 10pt stacked under that, threat at
10pt above the ring it belongs to. The mana number is tinted to echo its own ring, which is
what tells two stacked percentages apart without spending a label on either.

The **specular highlight** v12 added is gone with the globes. It was a glass effect for a
filled vessel; on an annulus there is no glass to catch light.

### Threat is the target's outer ring

Threat is your standing on that unit's table, so it belongs at that unit — and it costs the
target side no extra element, because the cluster is two rings and a face and threat simply
*is* the outer one. Green normally, orange from 70%, red once you actually hold aggro, with
`%threatpct%` above it. Party or raid only and, since v6, never inside an arena, so solo or in
the open world the target cluster is just a health ring and a face. The Retribution-only
**Threat Flash** pulses red on that same outer ring at 80%+.

All three threat escalations moved with it, from the `color` property a plain texture uses back
to the `foregroundColor` a progresstexture uses. WeakAuras silently *skips* a condition whose
property the region does not have — no error and no editor warning — so getting that wrong
ships a threat ring that never changes colour and looks fine in the editor. The zero-threat
guard came along too: without it a ring whose total is 0 draws as a **full** circle, i.e. as
full aggro on a target you have not touched.

There is deliberately **no target mana ring**. Two rings and a face on both sides is the
design; a third arc is what made the v9 target orb look busy and uneven next to yours. It is
also the right call on the merits — see *Still not built: an enemy mana bar* below.

### If you are updating from v11 or v12

Leave **Display** ticked in the Update dialog. That is the category carrying the region type,
and it is what turns the globes back into rings and the two glass rims back into the portraits
they were built as in v9. Untick **Arrangement** if you have dragged the pack somewhere you
like. Nothing needs deleting: the rims *are* the portraits — same auras, same UIDs, handed
back.

## v12 — the globes flank you, and the glass catches light

**What changed:** two things, and nothing else. The vessels **moved off the bottom of the screen
to either side of your character**, and each one now has a **highlight** on it, so it reads as
curved glass with liquid in it rather than a flat coloured sticker.

Not one trigger, load gate, condition, colour, spell ID or region type changed. No aura was
added or removed, every UID is identical to v11, and nothing outside the globes moved — the
buffs, the alerts, the cooldown row and the PvP layer are all exactly where v11 left them. This
imports as a plain in-place **Update**.

### They flank the character now

v11 parked all three vessels on one band at `y = -262`, below the cooldown row — which read as a
separate bar bolted underneath the HUD rather than as your own state. They now sit beside you at
eye height, with the target above the gap between them:

```
                             ,---.
                            | 88% |   target, (0, 110)
                             `---'
     ,-----.                                        ,-----.
    /  .-.  \                                      /  .-.  \
   |  ( ) 74% |          your character           |  ( ) 62% |
    \       /                                      \       /
     `-----'                                        `-----'
  life, (-270, 40)                               mana, (+270, 40)
```

| Vessel | Where | Size | What it says |
|---|---|---|---|
| **Life** | `x = -270, y = 40` | 72px | your health, in D2 red, `%percenthealth%` inside at 18pt. Goes hot red under **30%**. |
| **Mana** | `x = +270, y = 40` | 72px | your mana, in D2 blue, `%percentpower%` inside at 18pt. Goes red under **20%** — the paladin threshold that ends a tank's threat, a healer's raid and a ret's uptime. |
| **Target** | `x = 0, y = 110` | 44px | the target's health, half size so it reads as secondary. Red under **20%** — the Hammer of Wrath execute window on an enemy, the Lay on Hands emergency on an ally. Vanishes completely with no target. |

Those three positions are **identical in all seven class packs**, and so are the sizes and the
colours. They are also the tightest arrangement that collides with nothing: `x = ±170` would run
into the Alerts column at `x = -150` and the PvP column at `x = +150`, and `x = ±210` would run
into the PvP-layer icons at `(200, -44)`. Roll another class and the vessels are in the same
place, at the same size, meaning the same things.

The **swing runway did not follow the life globe** — it stays at `(-150, -76)`, exactly where
v11 shipped it. Its x offset used to be written as *the globe's* x, so this pass had to cut that
link on purpose rather than drag a non-globe element sideways as a side effect.

### The glass catches light

Each vessel carries one more sub-region: a soft, off-centre bright spot in its **upper left**,
46% of the globe wide and 34% tall, at 28% white. That is the whole trick — a highlight offset
from centre is what the eye reads as a *curved* surface with a light source somewhere above and
to the left, and it turns the flat disc into a jar.

It is drawn in **ADD** blend, not normal blend, and that is not a style choice. The percentage
lives *inside* the glass and sub-regions draw in order, so an overlay appended on top of the
number in normal blend would grey it out. ADD can only brighten, so the number stays readable —
which is exactly why the highlight is a bright spot rather than the more obvious dark rim
vignette, which would have had to sit under the text to be safe.

The highlight is **appended** as the last sub-region on each globe, never inserted. WeakAuras
conditions address sub-regions by position (`sub.1`, `sub.2`, …), so slipping a new one in ahead
of a referenced index silently re-points that condition at the wrong thing.

## v11 — Diablo globes

**What changed:** the rings are gone. Your life and your mana are now **globes** — vessels that
fill from the bottom like liquid, with the number **inside the glass** — and your target is a
third, smaller globe between them.

```
     ,-----.                                        ,-----.
    /       \              threat 41%              /       \
   |   74%   |               ,---.                |   62%   |
    \       /               | 88% |                \       /
     `-----'                 `---'                  `-----'
   life, x = -150         target, x = 0          mana, x = +150
```

| Vessel | Where (v11 — v12 moved all three) | Size | What it says |
|---|---|---|---|
| **Life** | `x = -150, y = -262` | 72px | your health, in D2 red, `%percenthealth%` inside at 18pt. Goes hot red under **30%**. |
| **Mana** | `x = +150, y = -262` | 72px | your mana, in D2 blue, `%percentpower%` inside at 18pt. Goes red under **20%** — the paladin threshold that ends a tank's threat, a healer's raid and a ret's uptime. |
| **Target** | `x = 0, y = -262` | 44px | the target's health, half size so it reads as secondary. Red under **20%** — the Hammer of Wrath execute window on an enemy, the Lay on Hands emergency on an ally. Vanishes completely with no target. |

Those three positions were **identical in all seven class packs**, and so are the sizes and the
colours. Roll another class and the vessels are in the same place, at the same size, meaning the
same things. (v12 moved the three of them together, in every pack at once, for the same reason.)

The empty part of each globe is a near-black disc rather than nothing at all: that is what makes
it read as a *container* — coloured liquid rising into a jar, not a shape appearing out of the
void — and a brass rim rings each one. The fills still fade to 50% out of combat; **the rims do
not**, so the vessels are still findable while you ride around. That is the job the portraits
used to do.

### The portrait is gone, and that is what buys the number its place

Diablo has no portrait. Dropping it is not a subtraction here, it is the whole trade: a
WeakAuras `model` region **cannot carry a text sub-region at all**, which is exactly why v9 and
v10 had to park the percentages *outside* the rings, at 11–14pt, where they competed with the
world behind them. With the face gone, each number sits in the middle of its own vessel at 18pt
— where your eye already is.

**Nothing was orphaned, and you do not have to delete anything.** Neither portrait aura was
removed: both were *recycled*, UID and all, into the two glass rims. `Paladin - Player Portrait`
is now `Paladin - Life Globe Rim` and `Paladin - Target Portrait` is now `Paladin - Mana Globe
Rim`. 48 auras before, 48 auras after, every UID stable, so this imports as a plain in-place
**Update** with no leftovers.

### Threat became the target globe's rim

Threat is the one readout with no natural vessel — it is not a resource anybody holds, it is
your standing on someone else's table. So `Paladin - Threat` kept its id, its UID, its trigger,
its thresholds and both of its load gates, and became **the glass around the target globe**:

| Rim colour | Meaning |
|---|---|
| **Green** | you are below 70% of the pull threshold |
| **Orange** | 70%+ — you are closing on the tank |
| **Red** | you hold aggro (for Protection, that red is the goal state, not an alarm) |

The percentage prints just above the globe, and the red **Threat Flash** still pulses on that
same rim at 80%+ for Retribution only. This costs no extra element and no extra screen space —
which is the entire argument for putting it there. Threat still loads in a party or raid only,
and still never inside an arena, so **out in the open world or solo the target globe simply has
no rim**: that is not a missing piece, it is the absence of a threat table.

### Two things moved out of the way — and only moved

Nothing about either one changed except where it sits: same triggers, same gates, same
conditions, same sizes.

- **The buff row** (Seal Active / Judgement Debuff / Holy Shield or Light's Grace) went from
  `y = -156` to `y = -60`. The target globe now occupies exactly where it used to be. It sits
  above the threat percentage instead.
- **The swing runway** went from `(-260, -170)` to `(-300, -76)` — it used to sit under the
  player's ring cluster, and a 122px life globe now fills that space. It rides just above the
  life globe, on the same x, still 140x9, still gold in the last 0.4 seconds.

### One colour changed, to keep a signal from going silent

The low-health escalation was `{0.90, 0.12, 0.12}` — a red chosen back when the ring underneath
it was **green**. On a D2-red vessel that is the vessel's own colour: the condition would fire
every time and show you nothing. Both health escalations therefore use the prototype's
escalation reds on a red vessel — a hot `{1, 0.15, 0.15}` for your own life and an orange-red
`{1, 0.35, 0.10}` for the target. Same triggers, same 30% / 20% thresholds, same property, same
order. **Mana's red is untouched**: red on a blue vessel needs no help.

### What did not change at all

Every trigger, load gate and condition outside the globes; the spec gating; the alert flow; the
cooldown row; the PvP layer; the seal-twisting pair; and the `threatvalue <= 0` guard that stops
the threat rim painting a full-aggro colour on a target you have no threat on yet.

**One thing to watch in the Update dialog:** leave the **Display** category ticked — that is the
category carrying the region types, and unticking it would keep the old ring shapes while
accepting the new positions, which is the one combination that looks broken. If you have dragged
the HUD around in game, untick **Arrangement** as usual.

## v10 — the orbs are one shared size now, in every pack

**What changed:** nothing but geometry. Not one trigger, load gate, condition, colour, spell
ID or region type moved, no aura was added or removed, and every UID is identical to v9 — so
this imports as a plain in-place Update.

v9 shipped the unit orbs seven times over, once per class pack, and every pack had picked its
own ring diameters. Worse, the **two clusters inside this pack disagreed with each other**: the
player orb was 88px across and the target orb 118px, so the same two faces read as different
sizes side by side. That is what "the sizes look uneven" was. All seven packs now build from
one shared set of numbers:

| | v9 (paladin) | v10 (every pack) |
|---|---|---|
| Player health ring (outer) | 88 | **104** |
| Player mana ring | 60 | **78** |
| Target threat ring (outer) | 118 | **104** |
| Target health ring | 88 | **78** |
| Threat halo (Ret) | 132 | **104** — pulses *on* the threat ring |
| Portrait | 28 | **46** |
| Cluster offset | (±252, −78) | **(±260, −60)** |

Both clusters now present the **same outer diameter and the same portrait**; the target simply
nests one more ring inside. The percentages moved onto the shared baselines with them (health
14pt at −60, mana 11pt at −76, threat 11pt at +60 above the ring).

The ring art changed with the size: **Ring_20px replaces Ring_10px**. These annuli scale their
stroke with the drawn size, so the old 10px art at these diameters was a 4px wire — thin and
cheap-looking, the first thing anyone noticed about v9. The 20px art draws an 8px band on the
outer ring and 6px on the inner one.

The **swing runway did not move on screen**. The orbs rose 18px onto the shared cluster line and
the runway's offset absorbed the re-anchoring, so it sits exactly where it did — now with 22px
of clearance under the mana percentage instead of 5px, because the orb above it got shorter.

## v9 — the middle of your screen is yours again

**What changed:** the three 172px bars that sat under your character since v1 — health, mana,
threat — are gone. In their place are **two unit orbs**, flanking the middle instead of filling
it: **you on the left, your target on the right**, each a live 3D portrait ringed by its own
progress arcs with the percentages underneath.

```
        ( 88%  )                                          ( 62% )
       ( ( 🧑 ) )        ← character stands here →       ( ( 👹 ) )
        ( 74%  )                                          threat 41%
        ▁▁▁▁▁▁▁ swing
```

**The player orb (left, at x = −252).** Outer ring = health, inner ring = mana, live portrait
in the middle, the two percentages stacked below it. The main-hand **swing runway** for seal
twisting rides underneath as a short bar — see *Why the swing timer is still a bar* below. Both
rings still fade to 50% out of combat, exactly as the bars did.

**The target orb (right, at x = +252).** Outermost ring = **your threat on that target**, then
health, then the target's portrait. Threat's percentage sits *above* its ring, health's below,
so the two numbers never queue up under one orb. The whole cluster **vanishes completely when
you have no target** — that is not a load gate or a condition, it is the health trigger
producing no state at all for a unit that does not exist, so there is nothing to switch off.

**Every warning the bars carried is still here, in the same colours:**

| Signal | v8 (bar) | v9 (orb) |
|---|---|---|
| Mana under 20% | bar turns red | mana ring turns the same red |
| Threat at 70%+ | bar turns orange | threat ring turns the same orange |
| You hold aggro | bar turns red | threat ring turns the same red |
| Threat at 80%+ (Ret only) | red rectangle pulsing over the bar | red halo pulsing around the target orb |
| Out of combat | health and mana bars at 50% alpha | health and mana rings at 50% alpha |

Two signals are **new**, both free because a ring says less with length than a bar does and has
to say more with colour: your own health ring turns red **under 30%**, and the target's health
ring turns red **under 20%** — which on an enemy is the Hammer of Wrath execute window the alert
column is already prompting for, and on a friendly target is the Lay on Hands emergency.

### Nothing is orphaned — you do not have to delete anything

This is worth stating plainly, because migrations like this normally leave litter. The three
bars were **transformed, not replaced**: `Paladin - Health`, `Paladin - Mana` and
`Paladin - Threat` keep their aura ids *and* their UIDs and simply became ring displays, and
`Paladin - Threat Flash` kept its id and UID and became the halo. WeakAuras matches auras across
imports by UID, so all four update in place. Only five auras are genuinely new (the two cluster
groups, the target's health ring, and the two portraits), and they append after everything else.
43 auras → 48, zero removals, `changed=0` on the UID continuity check.

**One thing to watch in the Update dialog:** leave the **Display** category ticked. That is the
category that carries the region type, and unticking it would keep the old bar shapes while
accepting the new positions — the one combination that looks broken. If you have dragged the
HUD around in game, untick **Arrangement** as usual; the Resources group keeps its own UID, so
your dragged position for it survives.

### Why the swing timer is still a bar

`Paladin - Swing Timer` was the one thing in the old stack that is **not a unit resource**, and
it did not become a ring:

1. It is a property of your weapon swing, not of the player or the target, so there is no unit
   whose orb it would ring.
2. A sub-second window is judged as *distance to an edge*. On a linear bar the 0.4s twist window
   is a visible run-up to a fixed right-hand edge; wrapped onto an arc it becomes a rotating tick
   with no edge to aim at. That judgement is the entire skill the element exists to support.

So it stays a bar — 140x9 instead of 172x10 — and sits **with the player's own readout** rather
than back in the vacated centre (under the player orb in v9/v10, above the life globe in v11, and
since v12 at a fixed (−150, −76) of its own while the globes moved up beside you). It still turns
gold in the last 0.4s, still only exists while you are actually swinging, and is still gated on
Seal of Command.

It is a *sibling* of the two clusters inside Resources rather than a child of either, so it
can be dragged somewhere personal — many twisters want a sub-second window right under the
crosshair — without dragging your health and mana readouts along with it, and so it survives if
you turn the player globes off in favour of your unit frames.

### Nothing was lost on the way across

- **No resource breakpoint marks were lost, because this pack never had any.** The tick marks
  that mark thresholds on a bar (rogue's 35/40 energy lines, druid's bear-rage marks) are an
  aurabar-only sub-region and genuinely cannot be ported to a ring. The paladin pack does not
  use them: its one resource threshold is "mana under 20%", which was a colour change on the bar
  and is the same colour change on the ring.
- **No numbers were lost.** Health %, mana % and threat % all still print, on the ring they
  belong to.
- **Threat keeps both of its load gates** — party/raid only, and never inside an arena.

### Two failure modes that were designed out

Worth knowing about, because both are invisible until they bite:

- **A ring at "no data" fills, where a bar empties.** WeakAuras draws a bar with a zero total as
  *empty* and a ring with a zero total as *full*. Threat hits a zero total whenever your threat
  value is zero — the moment before your first hit lands, and right after a Divine Shield drops
  you off the table — so a naive port would slam the threat ring to a complete circle, meaning
  "you are at the pull threshold", while the colour stayed green. Every ring here carries an
  explicit hide-when-there-is-no-data condition, so it disappears instead of lying.
- **`barColor` does not exist on a ring.** The property is `foregroundColor`, and WeakAuras
  silently *skips* a condition whose property the region does not have — no error, no warning in
  the editor, the escalation simply never fires. Every colour condition that moved onto a ring
  was renamed; the swing bar, still a bar, correctly kept `barColor`.

## v8 — the execute prompt is hostile-only for real

`Paladin - Hammer of Wrath` fired for a **wounded ally** under 20% health, not just an
enemy. v4 claimed to have fixed exactly this, but did it by setting a hostility filter on
the health trigger — and hostility is not an argument the health trigger reads, so
WeakAuras silently ignored it. The prompt now carries a third trigger that checks target
hostility properly, so a glowing damage button no longer appears over a dying party member.
Nothing else changed; all 42 UIDs are stable, so this imports as an Update.

## v7 — the cooldown row now shows what you *cannot* press

**Absence means available.** The row used to show all fourteen icons all the time and grey out
whichever were down, which meant it was busiest exactly when you had the fewest options — and you
already know your own spellbook. What you cannot know is what is *unavailable, and for how long*.

So the situational half of the row now appears **only while it is on cooldown**, carrying its swipe
and its countdown, and vanishes the moment the ability is back. The row is a dynamic group, so the
gap closes behind it: **an empty row means everything is up**, and two icons mean exactly two things
are down and both are counting back. No aura was added, removed, renamed or moved — re-importing is
still an **Update**, and every position you dragged survives.

Those icons also **lost their grey-while-down tint**, because it stopped meaning anything: if the
only icons on screen are the ones on cooldown, greying all of them just makes them harder to tell
apart. Full colour plus the number reads faster.

### What still sits there permanently — and glows

The four buttons the rotation says to press *the moment they are up* stay on screen in both states,
still greyed while down, still flashing gold the instant they come back. A hidden icon cannot
announce a moment, and these are the moments:

| Always on screen, glows gold when ready | Why it is not hidden |
|---|---|
| **Judgement** | 10s, off the global cooldown — Protection and Retribution press it on sight |
| **Crusader Strike** | 6s, the Retribution rotation's metronome |
| **Avenger's Shield** | on the pull, then on cooldown, for Protection |
| **Consecration** *(new in v7)* | Protection's largest threat source and an explicit press-on-cooldown line in the tank rotation |

**Consecration is the one classification this version changes.** It never had the glow, because the
same icon also loads for Retribution, where Consecration is a mana-permitting filler rather than a
rotation button — a glow overstates it there. Under v7 that trade stopped being symmetric: the only
alternative to glowing it was *hiding a tank's biggest threat button whenever it is available*,
which is the wrong direction for the button they press most. Retribution still reads the row
correctly, because Judgement and Crusader Strike wear the same glow and sit ahead of Consecration in
the priority — a lit Consecration there means "your filler is up", spend it if the mana is there.

### What now hides while it is ready

Everything pressed because a *circumstance* called for it, rather than because it came off cooldown:

- **Divine Shield**, **Lay on Hands** — panic buttons. Lay on Hands already has its own alert that
  fires at under 25% health, so the row only needs to answer "when do I get it back".
- **Avenging Wrath** — a 3-minute burst you spend on a window, and it locks out your bubble.
- **Hammer of Justice** — a stun and your only interrupt, pressed at a cast, not on sight. In an
  arena or battleground the **HAMMER NOW** prompt already owns the moment.
- **Holy Shock** — deliberately *not* promoted to a glowing button. TBC Holy is Holy Light and Flash
  of Light; Holy Shock is the expensive instant you keep for moving and for emergencies, so pressing
  it every 15 seconds is a mana bug, not a rotation.
- **Divine Favor** (2 min, saved for a Holy Light on someone actually taking damage) and **Divine
  Illumination** (3 min mana cooldown) — spent at a window you choose.
- **Blessing of Freedom**, **Blessing of Protection**, **Hammer of Justice (PvP)** — the arena/BG
  additions, all three held for a moment rather than pressed on cooldown.

A Holy paladin riding out of combat now sees an empty cooldown row instead of five greyed icons; a
Protection paladin mid-pull sees Judgement and Consecration lit, plus however many situational
icons are genuinely down.

## v6 — the CC icon tells you which button, and the threat bar leaves the arena

Two things v5 shipped with an open question. Both answers are now confirmed against WeakAuras'
own source, and both land on auras that already exist — **no aura was added, removed, renamed or
moved**, so re-importing is still an **Update** and every position you dragged survives.

### CC ON ME is now colour-coded by what has you

Under a stun nobody reads text. v5 gave you the effect's own icon and a countdown in a red glow;
the red never changed, so the icon told you *that* you were controlled and left *which button
breaks it* to memory — and for a paladin those are four genuinely different answers. The glow now
carries the category:

| Glow | What has you | What you press |
|---|---|---|
| **Red** | Stun | The trinket. It is the only answer — you cannot bubble while stunned. |
| **Purple** | Fear | Trinket, then bubble. |
| **Blue** | Root or snare | **Blessing of Freedom — not the trinket.** Spending the medallion on a Frost Nova is how the next Hammer of Justice kills you. |
| **Green** | Polymorph / confuse | Nothing. Ride it: any damage breaks it, so let a partner clip it rather than burning a cooldown. |
| **Amber** | Silence or school lockout | Your Holy school is gone, so nothing you cast will land. Trinket **earlier** than the timer makes you feel you should. |

Anything outside those five categories keeps the red default, which reads as "trinket food" — the
right assumption when the HUD does not know better. These are the same five colours the other packs
in this repo use, deliberately: roll a second class and you already know the language.

The countdown and the effect's own icon are unchanged, and this is still **not** diminishing-returns
tracking — see the v5 note below, which has not moved an inch.

### The threat bar and threat flash no longer load in an arena

An arena has no threat table, so both were dead PvE furniture sitting in the middle of the screen at
the exact moment space matters most. They now carry an instance-size gate listing every instance type
**except** arena: open world, 5-man, 10/20/25/40-man raid and battleground. Battlegrounds keep them on
purpose — Alterac Valley is full of elite NPCs with real threat tables.

v5 deliberately did *not* ship this, because the gate has to be spelled as "everywhere except arena"
(WeakAuras has no "not arena" key) and it was unclear whether the open world even has a size value to
list — if it did not, the gate would have silently unloaded your threat bar everywhere outside an
instance, which is a far worse bug than two dead bars in an arena. It does: WeakAuras returns the
literal size `"none"` outside instances, `none` is listed, and **nothing changes for a PvE player.**
No other aura's loading was touched.

### Still not built: an enemy mana bar

A per-opponent mana readout is now a proven WeakAuras primitive on 2.5.x (the Power trigger accepts
arena units and clones one row per opponent), and other packs in this repo will get one. A paladin
does not: there is no paladin mana drain, burn or punish — Judgement of Wisdom *gives* the attacker
mana. Watching a healer's bar tick down would not change one paladin button press, and an element
that does not change your next press does not belong in this pack.

## v5 — PvP layer

Ten new elements plus the dynamic group that holds them, and **every element carries its own
instance-type load gate — `arena` + `pvp`, or `arena` alone**. (The container group itself has no
gate, exactly like the four groups already in the pack: it draws nothing, and gating each child
individually is what lets the column close its own gaps.) In PvE — raid, dungeon, heroic, open
world — nothing appears, nothing moves, and nothing about the v4 HUD changes: no existing aura had
a trigger, gate, size or position touched. Re-importing is still an **Update** (no existing
`W.uid()` call was added, removed or reordered), so your dragged positions survive.

**This is not diminishing-returns tracking, and must not be read as one.** WeakAuras on TBC has no
DR prototype, no DR type table and no bundled DR library, and faking DR with an 18-second timer
models the *reset* window rather than the category — it is wrong the moment two spells share a
category, and a DR tracker that is wrong is worse than none because it gets trusted. Every CC
readout below shows the effect that is running **right now**, with its own remaining time. Whether
the next stun lands at full, half or quarter duration is still your own count.

### New: the PvP column (dynamic group at (150, 96), mirrors the Alerts column)

State readouts, growing downward, on the opposite side of the character from the alert flow so the
PvE layout never shifts.

- **Trinket DOWN** — visible *only while your PvP trinket is on cooldown*; absence means it is
  ready, so the column is empty in the normal case. Desaturated with a swipe countdown. Decides the
  single biggest PvP question a paladin has: ride the stun, or spend the medallion now. Tracked by
  exact item id (Medallion of the Alliance/Horde, and the level-60 paladin Insignias), never by
  equipment slot — a slot tracker would report "trinket down" whenever any *other* on-use trinket
  was ticking, and that false alarm costs a life.
- **Enemy Trinket** *(arena only)* — a 2-minute countdown per opponent, started when you see them
  trinket. While it runs, their get-out is gone: that is the window your real CC chain and your
  kill attempt go into. This is an **inference, not a read** — no API on 2.5.x can query another
  player's cooldowns — so an opponent who trinkets out of your sight starts no countdown, and an
  opponent still using the old 5-minute Insignia will be shown as ready long before they are.
- **Forbearance** *(arena only)* — one icon per team member carrying Forbearance, with the time
  left. It answers the paladin-only question the default UI buries in a debuff row: who can still
  be given Divine Shield, Blessing of Protection or Lay on Hands. BoP-ing a partner locks *your*
  bubble out of them for a minute, so this is where "which of us survives" is actually decided.
- **CLEANSE** *(arena only)* — one glowing icon per team member holding an effect worth a global,
  showing **which** effect and how long is left, because with the strongest dispel in the game the
  decision is ordering, not speed: Polymorph, Fear, Psychic Scream, Howl of Terror, Entangling
  Roots, Wound Poison, Crippling Poison, Viper Sting (all ranks). Filtered by exact spell id, never
  by dispel type — a "magic" filter would fire on every trivial magic debuff and still miss
  physical CC, which has no dispel type at all on non-retail.

Both clone rows read *group* units, so they are arena-only on purpose: in a 40-man battleground
every stray fear and every other paladin's bubble would push another icon into the column, and a
wall of icons is the same as no HUD at all.

### New prompts in the alert flow

Same language as the rest of the pack — glowing icon, slides in from below, flies off on exit. None
of them takes the usual in-combat gate: the opening Sap, poly or Hammer all happen before the
combat flag, and the arena/BG gate already keeps them out of the rest of the game.

- **CC ON ME** — appears the moment anything takes control of you, shows *that effect's own icon*
  and counts it down. Which break works is what the icon tells you: a stun means the trinket (you
  cannot bubble while stunned), a fear means trinket-then-bubble, a root or snare means **Blessing
  of Freedom, not the trinket**, and a school lockout means your Holy spells are gone for the
  duration so the answer is the trinket or distance — never another cast. This is also the only way
  to see a Kick/Counterspell lockout at all: a lockout is not a debuff, so no aura trigger can find
  it. *(v6 puts that decision in the glow colour instead of leaving it to memory — see above.)*
- **HAMMER NOW** — a paladin has no interrupt, so the stun *is* the interrupt. The prompt exists
  only when both halves are true: your target is in the **last 1.5 seconds of a cast** *and* Hammer
  of Justice is genuinely castable (cooldown and mana both checked). If the target is outside
  Hammer's 10 yards the icon desaturates, which reads as "close the gap first" rather than "press
  it". There is no filter for "casts I can interrupt" — WeakAuras disables that argument on TBC
  entirely — so fake-casting still beats you; that is a player skill, not a HUD feature.
- **TARGET IMMUNE** — stop. Judging, Crusader Striking or dumping Avenging Wrath into Divine
  Shield, Blessing of Protection, Ice Block, Cloak of Shadows or Divine Intervention spends the
  whole set for zero; The Beast Within means your stun is wasted too. Hostility is checked
  separately, so your partner's own bubble never fires it.

### Cooldown row, PvP additions

Three more 32x32 icons, same swipe/desaturate/out-of-combat-fade language as the rest of the row,
and deliberately **no** gold ready-glow — these are held for a moment, not pressed on cooldown.
*(v7 makes that classification literal: all three now show only while they are on cooldown, and the
grey-while-down tint went with the always-on display — see above.)*

- **Blessing of Freedom** — the answer to every root and snare, i.e. the reason not to spend the
  trinket. Whether it is up decides which of the two goes.
- **Blessing of Protection** — the peel, read next to the Forbearance row it will burn.
- **Hammer of Justice (Holy, PvP only)** — v4 hid the shared Hammer icon from deep Holy, which is
  right in a raid (bosses are stun-immune) and wrong in an arena, where the stun is a healer's main
  peel. This copy carries the exact inverse gate — Holy Shock *known* — plus the PvP gate, so it can
  never double up with the icon Protection and Retribution already have.

### Not built, and why

- **Diminishing returns** — see above. Not expressible without custom code.
- **Enemy cooldowns and enemy spec** — no API on 2.5.x reads either. The enemy trinket countdown is
  the one sanctioned approximation, and it is labelled as one.
- **A Will of the Forsaken readout** — TBC has no Undead paladins (Human, Dwarf, Draenei, Blood
  Elf), so the second trinket charge that element exists for cannot happen here.
- **Hiding the threat bar inside arena** — the inverse instance-size gate needed a field check first
  (WeakAuras only assigns the size value inside instances, and if it were nil in the open world that
  gate would silently unload the bars everywhere outside one). **Resolved and shipped in v6**: the
  open-world value is the literal string `none`, so the complement can be listed safely.
- **Enemy health frames and an enemy cooldown wall** — Gladius already owns the first, and the
  second is unreadable inside a stun.

### Field check before you lean on CC ON ME

The Crowd Controlled trigger is the one piece here that WeakAuras' own source cannot prove works on
a 2.5.x client: the prototype was deleted for Classic flavours in WA 3.5.0–5.1.x and ungated again
in 5.2.0, and it reads the loss-of-control API rather than the aura table. Get sapped and kicked in
a duel once and confirm the icon appears. If your client does not populate that API the icon simply
never shows — nothing else in the pack depends on it.

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

- **Paladin - Swing Timer** — a slim main-hand swing bar under the resource stack (v9: under
  the *player orb*, and 140x9 rather than 172x10). It drains
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

### Resources (The Sill, group offset (0, 140))

Since v9 this group has held a draggable cluster group instead of a bar stack; since v16 that
group is **Player Sill**, at absolute `(0, −110)`. It carries its **whole** screen position and
every region inside it carries only its lane offset, so the strip is one rigid object and the
rails cannot drift off their own plate. The parent chain sums to exactly
`(0, −140) + (0, +140) + (0, −110)`, which is why the Resources group anchors at the screen
origin rather than under the character: give it a drop of its own and the Sill's offset stops
being the number it says it is. `generate.lua` walks that chain in the decoded string on every
build and fails if it does not land on `(0, −110)`.

**Player Sill.** A 102 × 31 plate (`Square_White_Border.tga`, black at 45%) carrying three
`progresstexture` rails drawn on `Square_White.tga`, filling **left to right**
(`orientation = "HORIZONTAL"` — on a progresstexture, plain `HORIZONTAL` drains from
the right; this is the exact opposite of the aurabar convention the Swing Timer uses). Every
rail is **100px long, so one pixel is one percent**, and every mark on it is placed by
`x = v − 50`:

| lane | region | size | local y | reading |
|---|---|---|---|---|
| 1 | **Threat** | 100 × 4 | +15.5 | green → **orange at 70** → **red on aggro**; white notch at x +20 = the 70 line |
| 2 | **Health** | 100 × 11 | +7 | green, **hot red below 30%**; `%percenthealth%` at 11pt, x +32; ruler at −25 / 0 / +25 |
| 3 | **Mana** | 100 × 11 | −5 | blue, **red below 20%**; `%percentpower%` at 11pt, x +32; **20% waterline at x −30**; same ruler |

Threat loads in a party or raid only and, since v6, never inside an arena, and it hides itself
at zero threat, so solo the top lane is simply empty. Mana is red below 20% because mana is the
paladin resource in all three specs — it is what ends a tank's threat, a healer's raid and a
ret's uptime — and that one condition is the *only* power threshold anywhere in this pack,
which is why v16 draws it as a permanent line rather than leaving it as a colour change you
notice too late.

The Sill's children are ordered **alarm rim first**, then the plate, then threat, health, mana,
because WeakAuras draws later children on top (`FixGroupChildrenOrder` adds +4 frame levels per
child). The rim is `Square_White_Border.tga` and that art is **filled** — 98.44% of its pixels
are fully opaque — so it cannot trace an edge by itself; it reads as an edge only because it is
108 × 37 against the plate's 102 × 31 and is drawn *underneath*, leaving a 3px band proud on
every side. Put it last instead and the same region is an `ADD` red quad over every rail and
number. The plate is second because it is the surface everything prints on *and* the thing that
hides the rim's interior; the three rails come last, so no readout is ever drawn under
anything. The flat `c` list in the import string is depth-first in the same order, and the build
asserts all of it.

Health, mana and the plate fade to 50% alpha out of combat, so the instrument dims as one
object. The red **Threat Flash** rim pulses around the strip at 80%+ threat, gated to
Retribution only so a tank at 100% is never nagged, and carrying the same not-in-an-arena gate.
The 140 × 9 **Swing Timer** runway sits at (−150, −76), spanning x −220…−80 — a sibling of the
Sill rather than a child of it, so it drags on its own — gated to Seal of Command; it clears the
strip on both axes and the build proves it by name.

The strip clears every other row in the pack with all three dynamic groups projected six
children deep. The scan runs on the **108 × 37 alarm rim**, the widest thing the instrument ever
draws: 8.5px to the buff row above, 64.5px to the cooldown row below, 76px to the Alerts column
and 78px to the PvP column, with 26px to the Swing Timer. On the 102 × 31 plate alone the same
four numbers are 11.5 / 67.5 / 79 / 81px.

There is deliberately **no target cluster** since v14 and **no mana rail for anyone but you**.
Your target's health was already on the target frame and the nameplate; an opponent's mana was
never actionable for this class in the first place — a paladin has no mana drain, burn or
punish (Judgement of Wisdom *gives* the attacker mana), so it would not change one paladin
button press. See *Still not built: an enemy mana bar* above.

Each rail is fed by exactly one progress trigger, because WeakAuras rewrites a v45
progresstexture's progress source to *Automatic* on import and Automatic reads the first active
trigger — health and mana can never share one region. That is why they are three stacked rails
and not one.

Every percentage belongs to the **rail it measures**, as a `subtext` sub-region, so it appears
and disappears with its own bar: no threat table, no threat lane, and nothing left floating on
screen. The breakpoint marks are `subtexture` sub-regions on the same rails — `subtick`, the
tick sub-region, is aurabar-only, while `subtexture`'s `supports()` does list progresstexture.

### Buffs (icon row, group offset (0, 80))

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

Eleven 32x32 icons (plus the three PvP additions) with WeakAuras swipe text, mouseover
tooltips and a 50% fade out of combat. Since v7 the row is split by how the ability is
pressed, not by what it does:

- **Press-on-cooldown rotational — always on screen.** **Judgement**, **Consecration**,
  **Crusader Strike** and **Avenger's Shield** are greyed while down and add a gold pixel
  glow the instant they are ready in combat. The glow is the instruction, so these can
  never be hidden.
- **Situational — on screen only while on cooldown.** Everything else shows up when you
  spend it, counts back down, and disappears when it returns; no grey tint, because under
  that display every visible icon is on cooldown by definition. Absence is the readout.

Only two are baseline for everyone — **Divine Shield** and **Lay on Hands**, the panic buttons
every spec presses under pressure.
Four more are baseline but hidden from deep Holy by the inverse gate, because a healer never
presses them: Judgement, Consecration, Hammer of Justice, Avenging Wrath. Five are
talent-gated and sit at the end of the row
so the shared part never shifts: Holy Shock, Divine Favor and Divine Illumination for Holy,
Avenger's Shield for Protection, Crusader Strike for Retribution. The dynamic group closes the
gaps left by whatever is not talented — and, since v7, the gaps left by whatever is available.

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

v5 adds a second axis on top of that: every PvP aura also carries an **instance-size** gate
(`arena` + `pvp`, or `arena` alone for the pieces that read arena units or would flood a
battleground). The two gates are ANDed by WeakAuras, so "Hammer of Justice (PvP)" means *Holy, in
an arena or battleground*, and the Cleanse row means *knows Cleanse, in an arena*. `spec-preview`
does not model instance types, so the PvP auras show up there as ordinary extra entries — the PvE
per-spec sets are unchanged from v4.

v6 uses that same axis in reverse for the two threat elements: `none` + `party` + `ten` + `twenty` +
`twentyfive` + `fortyman` + `pvp`, i.e. every instance type **except** `arena`. WeakAuras has no
"not arena" key — the `size` load argument supports no negation — so the complement has to be listed
out, and `none` (the open world) is the entry that makes it safe.

### Regenerating

```bash
(cd ../../tools/tbc-weakaura-creator/scripts && ./setup.sh)   # once
lua5.1 generate.lua                                 # from tbc/paladin/
```

The script is deterministic: the fixed seed `20260811` reproduces the exact same UIDs, so the
output file is byte-identical run to run and re-imports in game as an **Update** rather than a
duplicate. It also runs `uidContinuity` against the existing `all-specs.txt` before overwriting
it, so future versions report `changed=0` for free, and since v14 it asserts the cluster's
**absolute** geometry against the decoded string it is about to ship, so a drifted layout fails
the build instead of shipping. v16 rewrites that proof from the ring canon to the **rail
canon** — it does not drop it — and widens it:

- the Sill group is walked through the real parent chain in the decoded string and must land on
  **(0, −110)**, and the Resources band must still resolve to the screen origin;
- every rail must be a **linear** `progresstexture`, exactly **100px long** (one pixel, one
  percent), non-square, drawn from `Square_White` on both layers, with `backgroundOffset = 0`,
  `compress`/`slanted` off, Automatic progress, and an exact sub-region count — because
  sub-region indexes are positional and conditions address them as `sub.N`;
- the plate must be **102 × 31** and the alarm **108 × 37**, concentric at local y +3, both on
  `Square_White_Border`, and the alarm must carry an explicit **red** four-component colour (a
  texture shipping `color = {}` draws in WeakAuras' default);
- **the alarm canon**, which is the pair of facts that makes the ≥80% warning a rim instead of a
  wash: `alarm.width == plate.width + 6` and `alarm.height == plate.height + 6` (3px proud on
  every side), *and* the alarm is `controlledChildren[1]` with the plate at `[2]`. The texture is
  filled art, so either fact on its own is worthless — drop the size and the rim vanishes behind
  the plate, drop the draw index and it becomes an `ADD` red quad over every readout. The build
  also re-checks the alarm's `ADD` blend, its `threatpct ≥ 80` trigger, its `alphaPulse` and its
  Retribution gate, so the fix cannot be undone by a "harmless" edit;
- every number must sit inside its own rail at x +32 with `OUTLINE`, and a three-digit number
  must still fit;
- every waterline must be at exactly `x = v − 50`, full rail height, in its declared colour;
- the draw order must be **alarm, plate, threat, health, mana** in both `controlledChildren`
  *and* the flat child list, with every rail proven to draw above *both* the rim and the plate,
  so a half-done reorder fails the build;
- and the whole pack is re-scanned as rectangles — every region, every dynamic group projected
  six children deep — with **zero overlaps** required against the **alarm rim's** 108 × 37
  envelope, not the plate's, plus named checks for the Swing Timer and the Alerts column.

When you extend the pack, append new `W.uid()`-consuming constructors at the END of the script
— never reorder or delete existing ones. v14 deletes three regions and keeps this rule by
*drawing and discarding* their three UID slots in place (`W.uid()` with no assignment, marked
"retired uid slot"): removing the calls would have shifted the plate's UID and orphaned it for
everyone. Contains zero custom Lua code, so the import dialog shows no code-review panel.

Importing: copy the whole string below → `/wa` in game → Import → paste. Note that the `/wa`
editor preview force-shows every aura with fake data and ignores load conditions — judge the
layout there, judge the behaviour in combat.

**Coming from v15, leave every category CHECKED — Arrangement most of all.** The usual advice
for this pack is the opposite (uncheck Arrangement to keep positions you dragged), and it is
wrong for this one version: v16 moves the group 270px right and 150px down, re-parents nothing
but re-orders the group's children, and every one of those changes travels in the Arrangement
category. Unchecking it leaves you with a 102 × 31 strip still parked at (−270, +40) with its
plate drawn over its own rails and the alarm rim drawn over everything instead of under it.
**Leave Display ticked too, whatever version you are coming
from** — Display is the category that carries the region type, and it is what turns three rings
into three rails and the 3D portrait into the plate. From v11 or v12 it is also what turns the
globes back into progress regions and the glass rims back into textures.

**One thing does need deleting, once, if you are coming from v13 or earlier.** Every version up
to v13 transformed its regions in place, so there were never any leftovers — bars became rings
in v9, rings became globes and the portraits became rims in v11, v12 moved and re-lit those
globes, v13 handed every one of those UIDs back to a ring or a portrait. v14 is the only
version that genuinely **removes** auras, and WeakAuras never deletes an aura that an import
does not mention. After updating, right-click **`Paladin - Target Rings`** in `/wa` and choose
**Delete**; that takes `Paladin - Target Health` and `Paladin - Target Portrait` with it. Those
three are the only leftovers, and nothing breaks if you keep them — the old target cluster
simply carries on drawing at (+270, 110). **Coming from v14 or v15 there is nothing to
delete**: neither v15 nor v16 adds or removes a single aura.

## Import string (v23)

```
!WA:2!T33E8XXX99PbNOf5rPysikkkQxNOePaKPOUBV7aoizP47oCGeqahoU3basrAIDV7272LyVDxU7Ea4GLDOrvuqDDCRHD9Rw7pYWPYTj2Uoi1PPUnXjSUoVBMpWjUBBCBsyCBvDC9hzMx2T51VzM9EId4aFjlsM)Gd3B2zMDNz((77Vh7VDbAYUZ9khEPhETSI5MjVPUrCDvDZr84Xtkp(psyJUZPRzBQRQkLpUSIAEtjT9BCpPevfZRO57j9LsvSIKPV0kQQxmRUzEjZyUdKXUIPQSWcIM59Lrxx1wXiRHi0DBJ7TA3Zelomervv9L2qkN1QkAf0nljAROR5nlB0KnRmEHcws2F1TVIPur4mzQyiXx0uVSXkSMKwzbPTTMyzBzDZXniD2Y7QStXMmieYtwyEuqPOxERCIQsEmfZrByF8w2IM2EZwqrtXs2Bm4)S9UOTPsXIsMwjpKP7HFKy2KRRyztrUlqkTmKuvvYBT)U9hRm0PSg0vIfP1pCElVx0QCwPzH5B6YfkOm)QthpA6mtNotu(m1ovktj4u8PtLy0rVuzlPeZd3xPzJGaVMyjjlVRKxklmcKPT5XsmAQHMy0LlR5EB5D18kwNTSgmBMvItuv1y3I0JZWo)y65L(C32YIAkSL1(W39qxqs0skTnSvu0w(oW7lMMUM0A5H5ePfttMNMwsW6vERfjnLCLXhowjrfTHWVnOd4dJFs8rWpf8)7P1AUaBHNTNTJlPOzlzQjQojmKWGFQLTKulKshQoB8ejZKG)ak5nU76WjEjl9YM5KSwXwp3SSoT9u3ZQfmH1c4Ew0w0ZLe1YbB1drQICVLnDC(ejsUkRA6GJdXvwj)Q8JL6fkgEGt2NuexaXWAWTLNvG1FEkycwEzNir(Isg7o95kdquFdvgGKtjRylTczzqHHPIPQlM3R58S5gAPhgJQjNG76fm2B9PrgztjrBFdPkAjBSN61tetiIm2sg7Q1w3ynhtsu1w(I1Rymrnr8TJ3g(TGdJ3Ux8oKXE)M3bEN47eFxBd)J4f)wPOC8U8I3ThC3W2Sx8E8IVhV49M8q479JaBr3hE)awfF)4ha)GEXpe(HX(Wpc(ac4h1l(XWheFiV4hh3dU3p3THFccmP1TA)DEZhhyhyUtHdIdbBRyp4(GToC)EWrWdGFACi8ZSAbP8jIhAi(jMkg(z9GFoV4Fu87ah1loMxCC0s(G5NNlzlnVDztPPmfni4xJ9eF0OJLkZ4XgnA8Np6GdoCMHNmbBI91Gl)9tMmRbsptBZwiZzlSc7WjicMGaErjByAEX6THCcHLR1(deXpSOy0DTkMwheceT1npWZ9S8urvJD5UPMwXUmvsHU(1Yk329YNJrGsGfbyf3U)JejmSjLTKIPPUjS1Dx4DA6olHTSLZQkPLNmv5Gzhz1O9BafW7lRHPea(O)go9jxru1qwmvzvlPfRkb3DaAxw3UJXUbUICMs2stBQBtBkQjOYKgrhMiVwqmN0PJMp)4AwNEkjXzIsO7o9ys5vepDg2DT1PzIkttLsMogvg6i2ffz75aia22DXbdc7S807tpaxMLOn5(usEX63epZQJgz0P6l(j6jMrHQOLSYskfLTpzwA7KKXXEvtfnkX)E5lvguOCi8DkeZuujVaShdlH27fl5ngqaNJCWYKD7CGeOLWQKdD7RapTUdL1cQqvYmv0rJo4WjXs7fxsGIqOm4ZOPpNMWI0Fd6xKxPETB)9fpgPo4ImlpOsZUIaNXSgclckVSRusutGZwsdGGZb3svkaKXW9h9yb8Hf4NtjVT8x1ldRJhb)849EgxruksgZNLj(7kQsVhiAyeOaUAsRn3hJ9qG0(IllsuTjzQyzRKZQQ0(cT03gWR4meMdcgnebJINGbpXts4sMIp2OjscqY9Fi(CYs5Mzi89UTfNv0ureWSlQOfxVuwrB(zfvllHoGUXbE2N1mNSOwrjR9Fi85PCJlAysKMSRGpZvoZYPBbQIFNTbPLaqA4Z4bpTmwGGQICUPcmz8rgkyUs14GYomohGLMeRiGlsWj4zoewfxIbaWY0QohTC(b9U0tNfw(nNUcI9)ZJGlXQI5pBzlBP8JjoFx1)HIwxyV9sUig7PooNyoeb4PLxEvlIglMaKqJTziDW0gwB4Tuf1Srlcecrj4ZxAVWu8IWkyrqOZknv54t8a3wxKPmfab7sWUMaDEh9Ppe(DdBrEWVhCk85pq)(jBjp3ZIFVKndgNuFuojp4fVuHAxvQzs16kVyrOA859W2pD7mPBdqGjb4yLWqG)a160QmQtkqaF(UPx43UBFrqlpd(5EIL2hWWct)PTKfZRp3jCvKUmTosXfoync4dEqJD1qBRBiNXHR18PzwlwN2F68s5adDuNgyjZPqSDaDr2Gu1QJyrNiZ4g3nTsWIrDIvr5MIirglk8ZlXgwL5LYtR89UgZOIt6EREb65j73kfQGdTcJAISLgl54jty8iBY9gRISjlxkRKjEFMGniKg6UKWUoUljfxHwhttcz1UF6A(aHPhhYZYUxbIwPHmvwW3XllMNyBKVmzAA8QEFVgTU5awAIs1fNY9G1QnouRlhFImJomml2vdJGR5ughCtMzume1Ur(cQ66MnTl38Ta5ArSx)UxR5jmBHDwypd4vKxApR5QDCmxnMGrneIj0kKDYPny3uvnuGVQIKl6wXKSXrW1KWPlbQw5PDQAnGQlrUOJokEFR4UpaDZy3UhmyDTuvhsxXwJN(ktdjv148B7cUJwDNSy2gepko7oVG79M7SdOPwRXjOKmBJb(DSQ2lGFrOFxXKQzZbeZtxHY9hOr6vJDbKDrD51O0CYg7oBnIm3zi(xKsbVc1dkkzfch7Lj8QNvaRl7YUMhkjkQXfe2iM2zXMcylbmOHRSaEwb8CefL1TCLPIBmCsIcSXfik04XPBN5xti36TUIMmENxQk)P763I6GRfG7AwGgo8lsDNRogYQKUUTCk3EiScLqEiftlB5vD7xovfdzQgfq9TXUQVY4I1Vu9AQrCrwLdhEXC6LiMWzjt0xne(dqfV5ctyxJqkc6HOpB(B3RXURZpxFb)zwDHjlANjK(jcyFmWCiIlssYltVhjaISdNm9WdMyvDtfWGd6mALJno)WVW4jZeDu2g(8UB4B3RjTFs5Lx6PXVec)JtuUHF5UW)eGIS7HQTCjz8)qb87tg)pcHF)uDr4FYoQ(zBG6NFmG2Vr9hmVKa9a10ySgW4KdUjLzg7C(deKO0O73EnLveTmHzLnRRz5saG0TxTvtZilTp8heHx2yxhSPlYbpi(dZ8t6JG)O4pg(JJ)eVx8)me(Fomz(K4pfa1(04vkI)mejtp4Fk8)cd)RJ2RPbSnkCWVkYO3o0R6eM4pp(ZI)xI)xH)PX)mWnXpRa(lGW)RVp8xSyByCBEqyvIFLL2dE16eK4Foyy(3GWFjb8pp(Fl(xa)VdMvFz8)Ez8)ba(m)2W)svPDcebh)93fo79J)kuYg8VSm(xb)IxUd3R9RsanxlgLJVUrHuXvSfJxy98A4)JY4VQlTf()eARzfyRwNJRSrwv3s7ExD06ByX5Rb0t4Fv8VgLjc)RJW)gc4Ftz8Vvn6f8Vnc)F(1(84FhkJXrDzmycgrOMfWfPkNbgtPiKMAYu5v7jy289Gxtg)1X)U4Fp83a)FPMCp2PDs8JEBxVf5VGlc2qFoWeOZFaUMK4z6c3yX(fbXE3E2DG2i1)cUs9x6GnEz2YY8UlOeZCDf(7zJKaPdCZsXVkIi82GSSXJT59UQ4BDb(NAZ7W6PAUSeY2brYNmhdg2vLd1IsC870Z1eP3)EQKTivYpFDkc(uu4mqtSmDpMGLqnXyqdRvTZj8ghrZXienGSahlYamWsl8mdw8yPM34ClmvKE3yEMMJs6in(SdsdkY8fLgUAJ9xV6rkNVOuja37BqAKVn2xdbgvxTIV0YksQ59nHrJHCDusWIS8DutW0C3iLEhvJu6N(n1bk9s1NeXGPRvBcBAKWdwAgUbkgyoU2f20hDfLC6ASGd8a3go(HVDIKc011YPRRcoHPLEofa(CHQ)KeTB5yKoj008(voepN)aHdXZfWFeO0pxK(PLrOLdqkhWpTmaTKJwgKNR)aHdt7fPMa9rkd6pmTSpAz)0Yi0wsgTG9to7abyLrOLKXFao)K20VF(GbIaJpu6paDmPJtywz)K2qRjqF0Rsi64hIoYHgGEw)0ZgIooHZcNRF)(z)xOT0Ml3PU0mssgrjbu0MNylTmvh40Y4N7P)gRvuvFUHmLoxzjTCvyuQXi1jFbqM9OQUXSqEzsDPPp0Pvihok9XUCpRsoUQVX02uZNqp0Zvn6iSifqQHEfZiRKBgnWbcpls)jWkSw2Y226AJZ8nHowJQanz30Rhl0SYlDpuDJh4GgBb1HOgmbMOzRMATlmCYKj4No24zYm(yunxpi(ls08vaVVLHBt2Zszn2)nTUBqtC)zUAXWX9jfw1FFb3hoZ0saSe)oQ(lsmwbDthFRXTUt8Fkr8gKvo(ibcplFjUZDwGd47IZqNkXwqxVe1bRfRkeiqf0iKDFBJ9uTsIRwdQyrcVzEbkD3XDLYjIU7Jf2DxP8wQzpRRgGKb4fBKKHishD)1mP5IsZBOWIAFgLsKaNfUrdBeWlscpXrcCeYojHn7mEw6rXVorgxf5kJJ)Ec4ljJ)tDLKFvxj5UjO)imzJq0s2X9rLnOsPryYs0ZsKE7NiTWfiqKG0ZsLL87NwgGwYKQzs7dqBdt6QptyLBCn1kcGGvY2iyzESO8Jn0eJ2S4LdA)nkr5GUFMyKd6bKDqpi8VhYJd6HVhhKpKd6rO7JoOdaIeoOh1b9yWpoOd6qoOhF3oOEUgbXDq92cW2b9eoO3gChCy6O6GEsbh0rWVdh0tDfapJjkf6K5SZjBePb4PdI(SIc6G4Qdl)tCqbVEHb92mA6jBpyYvTWiuEzktnx)0skpE)dSf5rBAJEKRDB0wxnB0qJi7ZpcBF(Al45E36GNzjGhTQ4h51JIm2(X)fBfe98XlgDbTZnvETyDce9DEZciA)eQIGHUsGm3aZnSf2Eh)h062BYCLJmXrpzpP07TtBV)FVoU9wxpLdkuB0n5Gc7ca8hRiOc4atKc31x24bAXc)XgoD6HtEuF9Wlz3RXdUrNnLPoC6gswc(HQEsJ7R9EaKC8PA6uILkjz6tVGVPaDQYnEPgvSIpDnOfA5T8bxPsg2nM2jzMtXYMoCDxVY4X9nEsFJLOX7PJfDSXsWtB592q3JYF0ez8n8yJnrYeg7UHPqINmDIOJs9hjU6oWE)vOYhmFq4TmaFvURRwNqwfSRQCjT0KbZd1RISm7Z4fvvkQHdzAzlsYfieXVbWHH6(JzYYlijHfHDp3by3EwUOPc7XFTtI3tepn25fYxrtSKso6Jqh8KkMLUPn(WlsAkXg0dWpiVQsjf7DsEC1JsosoRjSku26LUZlc(za3dA2djMZw3mlF0bhEI0llAMJzm8lTxWFOvkuwvnUIzoWEWQO7gtjMOQGpWwKWo56zeX)oWxORyxWajna3Z4WEMvZu8etTG)GPMkEXLEm8RtJl2MAF1HW)z4)C8Fb(Ve)9X)a8)p8)F8Ff(Vg)3G)BDq3Mdcye6YHWhC7oOT5GEloO7WbTDh0oCqEDq70bDNoO7Yb9J4GERoOD5GasQUDq3TdApoiGtBVoO71bbSl33AW(tozjR0Y6ZnU2Aw0)Bmfls2lCLqL(e1PsDPkFqGX6G8PuMxsTjc1McehHAfOEfy0Ue2vgV6wHc8LDPazKFuIWvO5Mbn3beALo89fVoDij72i5v3WacY4q1F0BKFBDAAkzmTmqimTfqLOxiRQUEEgfkxWHKuoN8S8twbdR(gRNdvUkkZbLUfsuywHpj(Pmjz)24LTPzAZQwQk5LYQdUAvcFkoymOiP2qVU0UwMMKHuFZSSnfjrMG6biEFzZv2cgGS0guHCRec)uoOkSkMNvXP6oa(miA(RqRwO7k53r3ZJwMMenKHDXQdl5IVgCSMfjPYiNYy3vpxMQvd3zS0JQAfc0XMoAcDs3(BMegCqMoiRRHWEhKDdy(xVRUUgJZDqLf2mR5CqZA8OTcRfZQOQyxzAB5YAGFWz1vTzy6E5loucPZMrkO)oJPZ0EmnG1OWzh0cyyj6DTXGyh0l6GE3K5nO()hRou1bD(gHPoO3Bv8Pdcmj4FazOCqVKd6hhgmh0ldRs)extqz7NNlC)r8Ftji4GDKBRqzZkmyqGX1o(rdgnYaMBbyWe3CadotDyWioON3bnQdAmhuYodgGoU0U5bQVCZeJKXpg7MW9vustYujhtRQWAn9Zvzkz5LeZtFuFlt3lskwsISTTpE6pDZ6U7lUBCJ8vnHb81dn)T71OBAshwut3uIK2aGHsscRbQuutxD4wTbBzxRwMhsodnhhi3)SW5VSl7DUzemUBYXsK8eVXMFvc6zA7zp9RaE(Ha()P2e8FwvjQ5o6fmaxeKOjUptsyWzJKzqZkLo(8H6SKWK3CijO1ywpJ)VEao)UpsAA2XaWgcKzbbgmVPmgqWyVnNbbvZX5UF7nkR4G(jDqFah0)y4(8FId6dsebCqlV9Z81jt9ped47G(WoO)Pql(ixQfVUCqFSwqVoOpo0WpHa7cqF8xu0USULnvtNqdphls0dxU2zmzhjTXpzRRmkETRgi(R2Uy9rr9xut3UH0hg8SNXc0C1UchuXcdYY6LL5a5ufnyO)PcoFGSsHdhAYJ1z0)u38OhOj0F4AjKrJOFh0Ne(3NAlbS)WpEBX1xOXqgSPG6RoMx6EfPOFpxveVfQfe61Z32sGO7KbhGdx6AYK5ndOvCHS98c90FHtwjANbAN4MdG2xO5NX(QPNd0a5J8qAmzinAA5twKOmtXihH938ZNhmw5SR3JNoySYSm0OBdQc44V0rv1ZkQ6RQ9gK(qGEWQKr3mNkDFLVgvVOsoJhRa9LctxRh7E9zkzx2uZN9Pc8o9b3NWbCVtFsWn81u7fKVoAVW4F0MHVVTnIL0GfWO1hqGEcA1)zdCYbgllFNbXN86yuvFIMJQkhaPxFCvzT5oWVNyeJrBjx8HMGNUoaMe69nWZPzPi4wXsg7kUP(C5bSu1xTZQOPog(9Rh(nDDj2815eRLjYBaL4HWwc8KxmvrHQORnistAKKcNKooQvkPBAiZawzYey0sJiMmspd1zG1lCdb74NO(R1H7R)l9Da98XsNzIKn9wH0Aw6EP6pU6MFPsCq)c4ZVgP)tpwI4hlAYHJ34a96EctW9F5MBFSHseLFDVfk9ZYtApTPdRr6WgCbEU20EZ4JNCOjsNyDxJqUVVfKOK3Ulum(XhpZ66vv94T7kLE4rtKmEI1V6fHEv4A70jv04dp0jBtxFDphVnT3yxPJFSXhF0PhM8Q1YprQmTRpxw2yz0TPe5n)f0(1O)c8XIlAztSxF5ANNlWrcdCnuB7RvPq7Ys2VwdwCTwuQAkFtqZ5cIjvGXxg7UUxfJqEBBYj1otWigQTCMWx9uxAVPG66(AG6QQEXASxT7rhct9QmyoOVuNOVAiysLOXoMfO8EnpAFhp7iNC(t0z6RtDdb91(RLtYxG924RXtEJeBj9K3AArptDB5(eC9fIlwa)C(jfCXchEGb4HJ6pcFOWHcgHpyaoUq8bdfQ)a8bgO)WCBq2WuvmG6kSd6vA1)xh0N2bTYw2N3BOupFFxjQNBeC)KBc4oVYSkAs0V5aKxz7AXjQW56vSGASzmhQCNX4N(gkhyEu8RVT2cC)LA2bgh0pnZVfh0pdfx5G(Cn6VYRUH(RSLcXQRiYtqFCo77kZfhh0NVbVACqFbJNSJoXWoi4nWEZWqOk9Du5XMkBfPbgVZi035BCEN4GwDJCozhKM8ZTjUM43bXJ)g4U(21tt74d2y(Dxp3nO1dUJyjLJLnKgputNADwdyC)nD(OG4ErId6Se)y)nDYbPScUXzVLRzJb5PEgDWUMSGZRNBMw6J74nK4SGta(A3PgwvTCjfn2m5bx)DQK5JBv9(5bAEnWSSLyEYhuhBtLzKAz4J5gjCYcXqMss51lz8OBylsvlA5gp2MVA6RNuZMQxwwQaujh(2BilvCqNzhxTPOIdAApU57UdsKuKD9jJIdkhiZLNKbkoiP6PEIdQa(UasPI4d7GKpa)GoifOYZcnEMx6oDqQoOsoinAsK4G0RN8inKFpvJAY1V8hzIcHehSWXd0t00DWAIwce5keh8JQoNyfRQrAF8NQTrKC5AcoDkg7xEVCixDHq)YNNmklR4Cq)u1cy5NHKeCBwiljjmI7xrkbgJ5SNlt0ZM0oKsulcJ5RTjjjNd6)gWyktzmJEnNXS(3CHv01QfEU2ql2aZ63D92IwJxT1xLUNO5xLUZl3yI3Dzb1CqF7QqSI)2TpO3nYbFRhkZb9DCrxZuPOITAFPhl1j6m663)ne0ff18Mqu1fzpU8AiFgclt42cWCq)6VrbRUcZu4RZaRePmgPS0XMCQG92zG1386iWA)BHxC3RmsMVxvsMx893wmWfB2ATBXXdwkfgnREV2vMVZ4H)73qJhESEAlCyTMSp)Ma0Ww81bQogyHJX)8XNFMcNn1KDgd8)4gAmWg8W2DqF2Bf34ROLp(KNuBStKoCN34)dUXwzaWi2UD(vQ7M9njkcUmEBFQJe67Kj6xmHXcCJ3xNrc)H3yJes(9BVVhngxLBnWcWkrBWchtBUWvINlxPOgDgl8hDdUjIzBlwW4UBtK0U1ataRiTbtCUG9KtAu)tLyYr6mM4I3qIjQfBIx8R0EmXUAn2P3ueGIobh(kTdomWXhjwFrSgoO)P6mC4p(w6Wt0aW69fV9zWClbD)wbyvJVKD1Hv6zol)KQbNjQC2odR(w3IdRQQdBWOBGkS280AUjqf2wkXuG1K1)S7RIYYnZzp6zxOsarJaDgL9)8gA7B(w)OThBS32)C6UvbEallBm8WCYPImL9eYsVWwiIy)VUHgECtDqY3siHQUd3EOGK)bnmsESj6FKTq8r(F)MdOajRhIn44tLK8XURX)KGyQOnJKTpYPA8BhrcnPsvQE2g)64nKUzwjrtrTCsn(jLi(OjIMmDc2dRpFlFsjCqN5UUM9W65YmEQn9X1lCT8X1Vwd)nfA2ux3Eo9tMowFp)OZMo5eClDWnkdyFpKKZBrfBPs036Zp0RrwWisVyEJ91M34ZHHw2B10RIkFdlUxG((F6ogc49fJCCdj)NtxV1T)H()uFKD6AxToeoDTBOJoD1DlDB4V4vu3S(yxwDd)4CIAvwhbIWBueixbPh43rGKIG92AkcoCYjNEeP5KunRmTRKwQjtnT)amAgJWPkWNKpJvSfaAMUURnJMPRTFDKMzl92WtsnBEt3)mtTF(qCCdWrfOpfxaYldQXEOVGX(ijOTV0LZLtI8HqNKOPFPvR9sgpCEH38PXylTHV3gtg0T8onN77QXS9yF8J33chDC5oVtVJ3a2PF0n9135RrtoO4Q6Aswcn8rqO)aRAizs(d(c5B((IIfka2ps2JXKV1oLYQOjLIDEH2W27Gg(gOV1w33w8BT1WxU4h30is3oSE)bkfvQqNreERL4Ld)dleHtxpOls4vEeYNQr(aCr4crldtl7Jhk6paTKlw4(JWfRpUabjfHJfjahhPa6G)irIqkhWFSWHIav0)aqxcgCGyb83h0XadeMu0xSbIeMJueKNRVbImaFGGCKlBqoooAzqAziYheWidelyi)daq0i(Hd9heg2qC9paPmc5Z6Q)arC66HD6YhbQ601JCvbp3S4N8lVrj7(p0aNBnZHV73v7aPsN9e8bs0Z5cLESods351FqA3L6oF35x6HA(paE4W4VRdYaStNCl6MmPKp)Y)wBV63F5Tx77VmZQSR2V)YelodSJRCBdD)7g1D4(NrkYCK(Xx(zwTGC88JuYCIXYEuYhkAW6xWgu2hCzqQSBl(Ghj8r839S3(7(V7p
```
