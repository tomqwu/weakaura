# Paladin — TBC WeakAuras (All Specs v13)

One import string covering all three specs. Elements load through Spell Known gates, so
the HUD adapts to your talents with no action from you.
Toolkit setup, once: `cd ../../tools/tbc-weakaura-creator/scripts && ./setup.sh`.

## All Specs — v13 (`all-specs.txt`, seed 20260811)

The full Holy / Protection / Retribution HUD: 48 auras in one import, arranged as a top-level
group at (0, -140) with five draggable sub-groups — the fifth being the PvP column added in v5,
which only ever loads inside an arena or a battleground. Every trigger matches by spell ID
(never by name), so it works unchanged on a zhCN client. `internalVersion` stays 45 /
`tocversion` 20501; modern WeakAuras migrates that forward on import.

## v13 — the rings are back, and so are the faces

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

### Resources (the ring clusters, group offset (0, 140))

Since v9 this group holds two draggable cluster groups instead of a bar stack. Since v13 each
cluster group carries its **whole** screen position — **Player Rings** at `(−270, 40)`,
**Target Rings** at `(+270, 110)` — and every ring and portrait inside sits at `(0, 0)`, so a
cluster is one rigid object rather than three offsets that can drift apart. The parent chain
sums to exactly those two coordinates, which is also why the Resources group anchors at the
screen origin rather than under the character: give it a drop of its own and the cluster
offsets stop being the canonical numbers. Both clusters stay clear of the Alerts column
(x = −150), the PvP column (x = +150 and its icons at (200, −44)), the buff row and the
cooldown row underneath.

**Player Rings.** An 84px **Health** arc in green outside a 62px **Mana** arc in blue, drawn
on `Ring_20px.tga` (a true annulus that ships inside WeakAuras — the disc texture the globes
used would fill as a pie wedge), around a 44px **live 3D portrait** of you. Both arcs fade to
50% alpha out of combat; the portrait does not, so your eye can still find the cluster while
you ride around. Health turns hot red below 30%; mana turns red below 20%, because mana is the
paladin resource in all three specs — it is what ends a tank's threat, a healer's raid and a
ret's uptime. `%percenthealth%` prints at 13pt just under the outer ring and `%percentpower%`
at 10pt under that, tinted to its own ring. The 140x9 **Swing Timer** runway sits at
(−150, −76) — a sibling of both clusters rather than a child of either, so it drags on its own
— gated to Seal of Command.

**Target Rings.** The same shape, so the two sides read as one design: an 84px **Threat** arc
outside a 62px **Health** arc, around a 44px live portrait of whatever you are targeting
(a real model, so it renders NPCs and mobs without the pack knowing their class). Target health
turns orange-red below 20% — the Hammer of Wrath execute window on an enemy, the Lay on Hands
emergency on an ally. The outer arc **is** the threat readout: green, orange from 70%, red once
you hold aggro, with `%threatpct%` above it. Threat loads in a party or raid only and, since
v6, never inside an arena, so solo or in the open world the cluster is just a health ring and a
face. A red **Threat Flash** pulses on that same outer arc at 80%+ threat, gated to
Retribution only so a tank at 100% is never nagged, and carrying the same not-in-an-arena gate.
The whole cluster is absent whenever you have no target, which is why it carries no
out-of-combat fade: it is already invisible unless you have deliberately targeted something.

There is deliberately **no target mana ring**: two arcs and a face on both sides is the design,
and a third arc is what made the v9 target orb look busy and uneven beside yours. It is also
the right call on the merits — most TBC bosses report mana as their primary bar and sit near
full all fight, and v6 already settled the PvP half of the question for this pack: a paladin has
no mana drain, burn or punish (Judgement of Wisdom *gives* the attacker mana), so an opponent's
mana would not change one paladin button press. See *Still not built: an enemy mana bar* above.

Each ring is fed by exactly one progress trigger, because WeakAuras rewrites a v45
progresstexture's progress source to *Automatic* on import and Automatic reads the first active
trigger — health and mana can never share one region. That is why they are concentric arcs and
not one.

The percentages sit outside the rings rather than in the middle because a `model` region cannot
carry a text sub-region at all (WeakAuras' SubText supports texture / progresstexture / icon /
aurabar / empty — not model). The centre of each cluster is a face, so the numbers hang below
it.

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
it, so future versions report `changed=0` for free. When you extend the pack, append new
`W.uid()`-consuming constructors at the END of the script — never reorder or delete existing
ones. Contains zero custom Lua code, so the import dialog shows no code-review panel.

Importing: copy the whole string below → `/wa` in game → Import → paste. Note that the `/wa`
editor preview force-shows every aura with fake data and ignores load conditions — judge the
layout there, judge the behaviour in combat. If you re-import over a pack you have dragged into
place, uncheck **Arrangement** in the Update dialog to keep your positions — but **leave Display
ticked whatever version you are coming from**. Display is the category that carries the region
type, and from v11 or v12 that is what turns the globes back into rings and the two glass rims
back into portraits; unticking it keeps the old shapes while accepting the new positions, which
is the one combination that looks broken. Nothing needs deleting afterwards: every version of
this pack transformed its regions in place rather than replacing them — bars became rings in v9,
rings became globes and the portraits became rims in v11, v12 moved and re-lit those globes, and
v13 hands every one of those UIDs back to a ring or a portrait — so there are no leftover auras
from any old layout.

## Import string (v13)

```
!WA:2!L33F0nYX99PH4KZjkjBE8Kojr9ddDs3jszPtalaiapRlsaGGhbfji4cqYJNolIfyxGDpUy392DbjbTLInJIcTJItcTQ)vRJvOTvIsZlVwMeNF044AghN0MK3BcBI7M2MMK75wlxx)Eo3ZT2onTPFNzxaSae8aVFPOt3FCdxm7mZo)4Z3pF)Xm7EOz6TWR(eR9U3opxHf41v1IRkRQpMhpEs7X3XcP1BbvftDvzzb(4IsY86ckhx7qP5K54Lu8(4EtlZvvq3lRKsjd35NLtVKGPt(3zJ8ZSeKJ3SsLf0pFEvDEb9yopyTEIjlTYkC68EZQQkBkPLxJdECMA3vTQNnwCOjIkl7nJMqbJnLukQQxMZusvP782TMOE1jlw0qW8RU)n0fkb3jBvnb2s6Qv02WUizKwr4M3MRIPOQ(KAKkB09M23YEWJqip5HXDrPsDZAuGtwWJoxbAbhK1WKt3S78fLuKme7og8hZUx1uxQujbDJuhv35YpEmtYZLRIohZwKudnbzzjEJ(61xSkqLYRrN5wLMFsEJUpVrL8clcJ3mvkwuA5nNpE0mzNpt2OSzRFR06cWTyZKoX4JFHkgcjwg6xzSBHCSkCLfm6EdEH8qlqg26JMy80Jm94RxrXPB19M8sgNTIcmAwuGHtww7aC0RZAF)ju5f(vUP15uKSNwheFNJSLaNHqgtyPOKP4pcUVykQkcBZdJjsjMNmo1neG5lEJvjfL8KXhlwzojLrWpoub8XWpb2h2p83d1AoBzpXBVMDlxqsXuqxHtEgOjHg)zx3qqUyAvi78XtKkBc2dlXRDWgWjwbd1k6fem2WuTWI2vA)PVZnlQdZfqFMZKZZf4ukal1JqYI03YNjoBIeP20oBAJJhKPIe)MStK(0Lcn0CdkeXbqKub6wE2aM)zPGjy61(gj4ljODGmNRcar9osfasoROKPWgKPbjBmvmzvo(U1x2ESHw7DJr1LRWDDCTEAmmgvGt2u88nYycofoT7zhIzPvb8fNKj(DG)rW7hhg3D34BveFBtHVD87e)UUzCpDJpaf)I7TB8b9GVdybSB8H6gFxDJV7uhfFpFCyY)EX3hGcX3p(bWV7UXEXpi(W4hc)W5WhPB8rXpcU)UXdGFu875x5MWpgba06IitNxwXbUfCWNfhcpiSGH9GJalk4H8Gpo(9IFs8G4tSzrb(eXdoc70Zgd)uEWpD34O4y44DJhUBCI)N9S2XZd4B95RIS)7YiCc0MC8NTIHPa)eCl3vJFiP0f(2qK2v7o4fm4mjqtbcVcrSxHxCtdYsVWYWneY5UmJOcCe2LH1qMtXeTQGcFuLsYcV4HGbW510vlPlyyKHIYE077M6ImMGPE6eCpDVQUQjvmaXYjRjY5bh)4hLTGOqHfgbFp38QlYPlXLxwyvjL4QLZZzYUiNCfb0Hv1o8joHEbroLscg9Du8CuyXQWZdKMmRIN(O4zGwWdE2THmkaY(IumcEUdhWhu7EFs8PjvBmpP3NVJ5pKDQh8ZEHI1htu2S6TZ6L5wUwB0lPjo8tEc72aHFw804NUV1oKwVMWS08gIC8QlDkhG7608ijA9CKM6mh5iA94QcnyppVDU1KDJfD6StQDqAMaVRkHBPWSs8MIXIc)8c0BaeBc80m)qBBlAoNDhq2Zw0cqwTLkwfp4g0jD6cASutMkbUpDqaLuMnOfSqnvyES76fbvyA9mIU0kENQchpHuWB2SA(QpUM3wnY8nn4MNxOaWckpVMoCbHyb100JtVdTnnVLawHz150wDwNl2U(JMYep50zhpzQeoZxnr9Onqh6i0ftkplBrzvvD7PJfH(eGSY14bruSDVoZD1w80oshAC7mZNQs58c65ffKkjA(6x2Y95laa45RsqJb97M9rRhqmoQJelvawu7a5RlI6iCQfojrbqrUccNjkp)KkgNzwbUfIs0FEMje4L4oJtjnodX0I5z8PT8XmlXrjy2GQBMk9IWdpZ6WtC(cYCgg5YBckXvmpeB5kGHfDZsZ9O5nKiLvpD0XJoCYu4x6q4pCUyGc5chc)sDhZaMojxGV7NZH48(jKLSunX5TPSDirxL8OiA1ZrPsRZJ6UE4xw7oMgkI34ICeZje0La8CbJA8WF0wQBno48LL01v1fBDgusreF7xOgbLP90YQQGsqqxHr3RdydfEI(C2yJNi1WuJqyRXwDEJYQQMIPDQDUnOSFJiPBykUPtBuqwstKWyFbNgNaRjnO2DeF8OtKo7KXgpA8Nj6WdNmBYzaODJLthW3fAKtDUbc0iuOvlOwwJ8Kfj6hgb)(gRbnwegsktepGcd2LiecVU2bAWQ5aaWRckreMDM08Y9hipF)6ske9)cIRthkK(z(KPYKC4eBQQlbRy0b(6XhFY4pZSjZKWgPUSdsT7U1PvtGxCTJJhdHFgI(g84DHNOMUfCkr8K5WPfXtHWSu1d4m7uJaolcpnvnaL49MXZIpfqXAt4BZ3ABbWZ6IJFlhzsn1Le0bkEMMO4PtkHAHNh)(Qx7vbMDNA2R)2tSJNhHZDHJ4(XCKJGZBBQqbmpwaxex6dHfL3hwcgoNfVaGBLXLhZE9IKgoKhpyfSk(CiT(3nwfAt7IXcVmwhBGnXvWlcTB1CAp8fVQ25HFE8k3j(9J0EIlEP3jhn(fE(lFRw(X2jXf(dkI)qayJAbZpoHxb)I5W)euIHFYJIxd)HT5nWFeAw)unym(InK8zttxEaj91P9BYmdQjH(Tjmi1VxU2YFG)z6exb(Nve)Zb0c41XFSUXVc(Fg(JJWFIC4pPi(trfLXFA8)C8)ce(Z8gI4FEQS3jjYEaGKk0fKUqpuiIOh(Z(84xLkLnCPrtVS25wz2idG3qe)5WFE8xa)A4FX6Yo4FjX1cSzzqKtoPX0uAqWavgonjrIuKT8Jo9(ed5oqdZGBR9P1gU)0DA4ULMJ9WNwvTCoqGCl7NrrjzHK84hyd7FQXbe1pGD)BEdanvfbsPU(n0Na7pFH52BlUnSIFvdHZvrqPGGhxY)G94rJLcCrcF7S0hb(D9GnEwvmMcMWA8B9vq6C8lckTfeV8XTWQ1tDxotWRGWbUvkCLS8oQtUvDnE1x(B0d(ZohfpCInJCUz9pt8XgjqHYeMmTEOLByjdIdQjbpSfP8zU6ZMR4UXQ2QNnJ52ZMSI6cCUCHVEKbS1F2uidOf17iGUzr3((4uHDZ3N)Q3A77Z(AJVpjYipxuZaQtfUWo995B0ZLRgO91wnqet)nTxfkyc6wctT9)h9e19Faw1gKK4VzTkSCLafU4584w1fLQyiQsig70MR0M2pjQto7UBguTrBDK69Q6QI0ESDq3xVqTJR3TMRY1uCP9GxKgPU6LgA3cZyt6rVoynvCUvB1gJOB0InPRJQ0c0YHFHx)ARwOxciQ2KOZamHLeBRCutqjMSkAZFP7Cd46JIFN5IbIo852nsTfz1alNRMJrBrOLGHOz1YCk5ymfuYTH5sG62QfLwuaSJMEDo8XYzls9A1OR3WEcHq(dgBteybjQZt6tnUroIi39J)RblH7XrypJKzfQHzuXWRyLz)rogsYeIGtJqscyRl71D0LTYmLmZgu9u(nhD31LD1r(7rRlvGpZoSPJ62EGqTrUd)CDqWbZ1wd380SHBVXyuGSgQfSmEjaMcRGRCVeK6haKeElHbtTt3)F9vztD(3HFFVHutw2ijRpBMbYOf6uv2D0Gx6slP1O9YVETE52nq3apqo8)vOddDZ)MC4)0dhXh0316TblbjSoCMQ6eIxQia(VTDq(UbFtTJEbfzyNqn)NaSGHmGeVDDh)XiWTxHb8)IO6O9lHfX9LN4Nfios(nC7V1g0avLUISHWQ1cIBV(PvzhRVAhGxYOGUGPW81d0vtR1FZAl0GOamX6OZ7FprYzApB0iqBIeHItS54rgF2bJFQ(JPvSU6Wx41ZBhphr8WVg(R7WxH)pwdZydtai0FEZ0xuYfA0ZxqrDjLC4)cXnA8Z9)rIBZSHTYH)lZH)pLd)Foh()so8FfL86Z(6Rfa)Rrntf)R7Yiv8VXLM5PxCi6xKytk(3ek1Vf8VFBIvN4FNltBnX)B84IIHyKj(3fq)FjW6s8VhXMs8xgH)3ELAdj(R0K1J)X4Tq4FF3wlY7FILY4lFkMfonL17pWX6q8xdH)drR5dwc40xGggV7CdPcQk2ro9(UjCc5BbFB)j7JmlVnTq1dgH2bA63ex3X8XivwChZ6B6AdKiZ4oXErKtHNUkeJCfMPLvcApXvCbDSpB18CoB5tdVCTtheSR57iUfTFzhmdGf(PF0dH7BtsCuG6np8VfX9TUrfNDEAB7)4eBpg421Yr1oAioB1Ht3GgMuNCQfkpNnDyEb(sc4y1(frPUh8lCq8WlsqmF3MfmAc683T)j)e2iNZt76XQfdi8BqOLbRMTxFI3yMaateAuDNHfGVCpQpfAD6uNHeValBYtoA2lFaMlHPnPpIrPbB8e4VjBCzbofaiz)ORfmW(BemW4CgMW6Emo9ZmDYhVXVE8muKdTAI1HT3CSvahcruQ(V6(DqURSqPb6pqISrJvf46D6bs88ckSPsmtcw8xyJrNKn5PNmv2OJJJ3xDfYNxyznjBEscSdphdOCWT(zBL5ryQRm)FGio(zOr7cYk8o8pY9(HcUb5nkDl406Rr2JvbGaLbBT8omD380UBxBwKQCvVzeLeK59oTMBpOgNmFA49K6WuMJBs3sn3K(fElTBsxOXGigmCnAJttrcnC5fygQK)Ly2PttO1Ei83JqY8y7ZHjF7cQQY8GMaGWqti3w1(jzJ7eXF)CnnwF1JYY4ZFOGSm(9fbs9XejmnncnDis6q(OP(PPm00aSmH9hkeTwKC8pijnGVq00bPPHPPrOLK0AbctU7q(TtJqtjT)qm(iLjSp2a(JaTpK6ZpTnPTti70WKYqZX)G0NsqA7hK2YbhIExF07gK2oHYd3lSpF2)j4EAbn4ZEHfee0IsceUjlb3lsP6)oI4N(4F9TljRU0i62b(OQTX2Xi5jUfqeFszNTbsCDsEzOBE(gKlhNU9X35MKRRT1j0Y0GlIEVABCH9M6qYH(eZkkvybfbddpRs)j4U125RyAQQmPD0QPT14sqroa95fZ(4aS2bP2mF4JO1oJMrTeStkJyR()TvYuPsWoFSjZMDYjWRC)2E4bwwH)hTqDHSqEOnSfAF5Sq3moMf6Da01tT3uWF74VprIeG3tnM)qlYwM5CNfVFl09J)Vt7nwOEPEXSAn8BUASCwO7r7oQLlHYCyjdYwnc6bj8Et5iysK26Z20phbZwY5q7ihGxamg2nVark0fJOf6UaFuc5Mdmh(zj7s(X8FmYKpH0zAp1KjLRzDLf6DdtrEBi(9AoIF9sGSrSb0bPP2xpifqtfTIylaqVlrKlmbIZ43FKa07sfa85JM6NMAlkAlIoeTm2IedQdZxtQid(a5y)wlsd6JgLDIrME8MLjSqN0TyGfAuBSVfkPOfAm4FpdSyn(DAHMaGePCw8MeWXwO0wOPGFWAHYyHYEal00xnWLwOzUMHgJXjeCUcMfe1I0o0Of6uUWHWiCURvGUUBgk947gsYHiFmktkLBLjmnLY8gEO9iZxtRYJD1Bv24YEvgkXkpO9I8vlmZDTNXm7bdoN6l1k25zIxk6kkNBwELyDg7CVV1b70hHEiqWlhKY1J8b7fNj(HTU2MQqLitFY56pT6aDET9(UgU22jLrwOt7S67lwjGX)WtNg31VS291IL3tKmtMKPoP3(zfmhq7(3T7MwxfU9D46CNnsTB6ENkCBzEQjNTPBXvg8y1RArVZcUsi6(rnoxvVQkqju4n8cpPYAMUpIBzxsYWK2C92iZ4X9ozkVtKWDFA0OtmrcwAjDVDlrzpzISEtoXetNkb1PaQJ4FfQv12ocqCFQGWTFL6jWMGJTvkRKH0y2EyN32MjwozPsk4b1nm5ihYqAeqg2DWn0TpWHc5wfwQCAGd6z9s6s2NiOB1oGhXW3(w8vv4klvGgBBWDMygQ6M4JTkPOeJcpm7WSYsLLmVvsCbgNCLyEDyUOIXlEBNhCLf6dkMJWvWuvppB0HtoDM150lyBD6lEiWPKnkwrwoUKEbWH8Ayz37OvuzbDtdsOCCCpH4Kf4qYLTFqGGfaYTzRoXMzlDQzxXxG0ZgV0Apm(7HAeBQD16PJAHEql0HTqpKf6HTqhXcb58iwO(TqdyHEul07Xc9ywOh3cDml0tyH8zH8BHySqG8AqleqzbTDyluel0qwOJBHEVwON0cDcl0pQf6PSqpTfkQfcyoIBHg2cLWcnY2WQvbrbJmIQlnPY2g0)mHKb5e1C5qG(OniqDiihdgRSSPLwwqUjA0MogeecvGWnNnzlHt1MnDpq)9so0F2eFusWnOhyi6X0lxRuHoHtKsfsodT0nhfGtAhTrqki)24m0yqoViqfmVbqIOwmVSQkVn9jtGreKoN4ISZuLqF(k7K(uSb95YTqFsguFlSFDYzSDYkM0G5UPHSeVqEvWrOY4Vnd0guyvBiwxRN1PhLzQNtgKDsTKOj1)mCF5luXaAG80cuL0vcIbeYNXoJLTZ4B3RF80i6HQIMDUERYFl9UmADA8Kjn7Q1AwYdFB4AfdzY50dUL2bQDVS1Yg6z2rqVwg5OTnT1Y1jv6V1vYWc9XTqFIRIYawOpPlbGVBxV)RUGEl0Nk3fZMol0Nw7HAfJZLxswYS68MIvuaVSZRkBAdWhGT0ijeoBwHa(6maVA7b4aWJITTq)84VTf6ZU7iAl0RAH(fitwByH(CnWTwOpVBmRf6ludSAHEnl0ViPPSq)swOxhAml0Vmml9V8QeKRpwMqHJ47TJOGJ0rMUIv0RAJd8pPYuNmq0idPVhWbR82fCWZ1ahmMfsZcDolKUfYOZObOIRDawGkSWcXiNqATdq4cljOiOlvWwjBUTB6NBARZLvGJVk9GLrxnsXvwGSW1hl9NoN707jUtyI8w7aF6TF6BnYaA9spdbLuu1fih7tWkkHCBdQyKZuR520LvTBxFp3i3HUF(K(V9UFTUdBEHfYPDqY1cK3of3f)ke13CC2FZxa4jUica5LfOg)Owud8vqG(2czlkm8IrYoSE1YtTCWolk8(F7IOGcGO)A132UZCygF13Xu6U2rXmF0C248Mor650ouZNq9ABDEVpPBHfl0)Al0MwOFn4z(RBH(niYawOV4(FU)dKb)VPnY3c9BzH(THs87CHwCaZc972c81c9LGc(7LZ(bqp8Mu4UOQHjvBxoxNctsCdxV(D0TVsy33j4lps(V5vag)1AxS(OW(ZROA6AJZbV8TzbAoBhPdQCXFhzw9sYIGcYCA2W)zdSS)8cHcfCMr7m8)d82jnbnb)dv)8S6g(BH(kW)2ApHSFLhPTa7TCh(GlkQ(kJ7LUAr3otpxjuVfRhf6DY42sKO7KnhGhyQkKT73WgPvAL89F6(dxCUQr7ms75F7esZ9Ps5h4aW(H2ur)91plenINZz3PloxZSuTT6SfV2PZU25FOga69SBevA2b0zN(O3FaJWN1)CdnrE2odJEH38cXPf6U31yC(W2r4ExDozrkaXz9Tg5WlR1tCD1L49gV(R4nzrFpfL7RbUMCvoc4nyB(leV4B71rX)L5yjVP5C5QHA2LG6OqonBKxtd5QLv11eTbmzZ6F8YJXLks)J0zaZp21f8oF6ghOBN3)F6l19CXYKD6unDEW3XRFAJnbU5x)ul0FoEUTj1F(jseF0OPsg3Dd9D98fia6VEZLp2ijIYUJZFEy7Z1RN2uHTjvyxEa)QTP86XNm1itNjXoEgbDot4KOt3Uhum2jNm7oQvnfKT7jLj54jsfpXoN9IqFkmTD4KoA8KJmxBQ631ZxPnLxRNmXhDYjhF(KK3vE2PtNTD15s08fTE1fiVm)K33sx2I)YXihdlITWRx)(m(pwiGMHA3C9mZTdZITB96gZSDuQ7sENME(fiwRa21ODGgwSpg5n)TGq7SUHyd0xmBORCwRV5)0YADpUyTQPQRoXv72CoymxJ8Yc9N1jMlxbPPmncT2HJEa9to4u5hBULpvNzU(GxxWC1x9x7YTS)YAOWsEf7B5nWeuEI)o7bDNpxdJM(0mdgKjMFFm(ijmXcfAOHyHRchHnyOGbIWgWpdtq2abdg2pR)HchIzxoEj1KaOEyAH(QT6wPf6pWc912ZUsE9Hs575YrPSBC9JFrW18slkPiq)0HqE1SRh5LINBaUIYXwqFKkDgE)HUUYHaOglzHoeUR)hno)NXh29bhTXMptZhSXZqOG9Pyv7bA6w7GNv7EB6(rHj1sKdDT9ox3xt3Cy6CVt4bB5z62Z0gBjT9Z0oMIQfwOL640EJWTiyGL32DRKYYvklPypsU)D2tf0FeJA9N7R55a9kgC8WqnJPU0ccT08XCIGhzIyeDbbE1YAp0UwI01JYN2dFXNn92F6ftpG9oVdKmp2(CTZ7wOvVLR0TD3c9Jx78SBH(jijV0o3GDl0pj401AKDv3c9HBSD6wOpc(DDZwOFk8XSqV8Hzh2c9tFRwOpku4FMx82Sq)SwOFol060ng3c9XASH4UoGc1cU81U9eF6Ib5gU4u(7pAMosx3s8t2GeM8OYlXv1OwecN8jABGuwVUOtNIn4L2RK9vwO)UKDvoQ9j7Xc9hvpol)HKdYZflslKn(25BUvoBQZfpx2ONnLzqPOga1zxDDrpNpFpG6uKsDg9QUtWnEjw3qvPgsRLxkvQ28ggc31(3P2EWv52)9y4rB(7Xamo2JUv3gSMvx7RggR0FA7dwNBA4B4GzwD9oCGxluTKKP8GzMi9P6m86)1BkWlkS5TKWQZBVtF1b)2qSSHAlcZc9F7nlC1L5jD8AlYkrATXQim6mZgyGoJS(FFnez13E47)YLlnZTwJM5d8YTfeC(Mnz7gBaHHuXXZRoGz1L7mG47FDoG4H7VT4HTBYk9R)Hd7XxLHgGGvgL9zIV8cfpB6z6mi4hCDoiyx2Oql0F8nGR8vv4JpZCktCQmH68k)p86D9baRy7w63OH72V9qxWLW7TqdOWGZLimxcTvyMCWodf(7VEhkK6h0EpqChGLBiadWerBadJQSuOQXluOCuTodg()CDVDI5Blyq7GTjMA3qakGjK2akoxG(limUVztmZyDgu8pCDkOOEmk(aF52dk6P1WO(2Hav0j8WxUD4HHMASydgXizaFZ2z8W)3BWdtHlK1hjE7pdMTea(BaWvUFTHAGRuZEw2zKdSquX8Dgx9)7gECvn1ydhDx0I1MTU56FTy7PtbamLSJDlTomRWcN9KNDLQ(5083zy2)415248nEQ2doou731UBqWhWSYUJp0Nz2iZAoTOWP7COX66MUohF8254LVNGc18kU9ybbFdRPLA0PdpwNJtcPR8wbSa5qqeB4jNnf5BQL7pKW6skliy6LCl3Vk8juekxT2DD)r4Aev98cC6KpcZAhW1gBpEIOPY48sZZ3YlnVfA1B)Q2w3ZKDY0x0nVp3vZnVFBx))kZIPVMTR9ZKj2GpZ4lMj10mRDKD)Sg(cKZc1QsMcLPV8AFS3GmLreFXVS2D3MxCTKqjhW(qU7iGdtVBrFn2CAJC4(IrU21zTYQRb2)h7B1OLT66rBTjS669av0QRhRLQL8F1Lv1m(KxsvdpadNs1DWGK7njgKl9ZKfWCqoxwd065YkzQzMFmHLeK1RoVJOw6zspVp)28mAHsxKnfBwJyRq4zEKlkpZHVgYZShFTEjNc2xw35)KU6JnidZqmuz6VnJFY70M2DqFrj9solSEZuPqbbY)5CqoyF)zBw)LLmjFU3YPZypTIFi3hbV98snJZ5IFX(nNAQbx5Ktk25L6h6nHL6hQdVLeFn6HfkUSQIGroxVo3H9VPMGo5lyn5tP5QCflc2qswKXVZZt(CriPiK2((5AdJVfs56IVCq3ZE7lhuYlvOJZbks1mKAy)LJkuSZGHhU(zXm5)0bgS6kSdi4vFqY3zow)mrycstdrthKfsc7NMYelu4imXgKXFassOyr8ZWqsGk4lsKiK0H8fluWiqgHhcQsGadfZVVbHk6FOqKKbJnuKqmKKaSmdouKHy9hGH8ydWWWqtdqtds(GMfzOybc6BiaDgXhCPVaqZgKj8qK0iKpKK(8hXQRHS664euQvxV3RiK5fjakEgA3oyXV5Jl3BMbFW3F7WNcN9uS(t0)5cMzIoJppY1E8zVL7LVx(1EGM(YXEACyleOA5vad0j9rNZuk5Z76FY(R99DT76FFxTnh7k977kXuZa3YLVrHoFtWVfNpr4Kbj9J76j2SOyC(XkRp9e5pj5drly27t5X5d6kir2RbBGJf6y(6DX998)))
```
