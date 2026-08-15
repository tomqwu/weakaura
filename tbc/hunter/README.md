# Hunter TBC — Beast Mastery & Survival (v8)

A single WeakAuras pack for TBC Anniversary (2.4.3) hunters that covers both raid specs:
Beast Mastery (41/20/0) and Survival (0/20/41). It is built from the rotation, not from a
list of trackers — every element maps to one line of the priority list, and anything that
does not change which button you press next was left out. Everything matches by **spell ID**
(never by name), so it works identically on a zhCN or any other localized client.

52 auras: one draggable top-level group `Hunter TBC - BM & Survival` anchored at screen
centre `(0, -140)`, holding six sub-groups you can drag independently (since v8 the
*Resources* group holds two further clusters, each draggable on its own). Built for
WeakAuras `internalVersion 45` / `tocversion 20501`; modern WA migrates it forward on
import.

## v8 — the middle of the screen is empty

The three 172x14 bars that sat under your feet — health, mana, threat — are gone as
rectangles. The **same four auras**, with the same ids, the same UIDs, the same triggers
and the same load gates, are now radial rings around two small **unit orbs** that flank
your character:

```
        Alerts                                            PvP stack
          ↑                                                   ↓
   ( health ring )                                  (( threat ring ))
   (  mana ring  )        ← your character →        ( target health  )
   (  portrait   )                                  (  target mana   )
     -250                       0                    (   portrait   )
                                                            +250
```

Each orb is a live 3D portrait of the unit with its health drawn as the outer arc and its
primary power as the inner one, and the numbers that matter printed just outside the rings
(see the table below for exactly which). **Player on the left, target on the right.** With
no target, the entire right-hand cluster disappears — the
Health, Power and Threat triggers all end in a "does this unit exist" test, so there is no
empty circle sitting there.

**Why.** Unit state belongs *at the unit*, not stacked in the most expensive real estate on
the screen. The band directly under your character is where you look for a boss's cast bar,
a void zone, or the thing that is about to kill you; v7 parked 172px of green rectangle
there and made you read past it. That band is now clear.

### What each ring says

| Ring | Where | Reads |
|---|---|---|
| **Health** (green) | both orbs, outer | Your own goes **red below 30%** — the escalation the flat green bar never had. Percentage printed beneath. |
| **Power** (blue) | both orbs, inner | Yours is mana, and it turns **red below 20%**: the Aspect of the Viper line, the same number the *Go Viper* prompt fires on. |
| **Threat** (green → orange → red) | target orb, outermost | Same three tiers as v7 — orange at 70% (press *Misdirection*), red at 90% (press *Feign Death*), deep red the moment you are actually pulling aggro — plus the pulsing red halo at 80%+. Percentage printed *above* the orb. Party/raid only, never in an arena. |

Threat moved onto the **target** orb on purpose: threat is a number about a specific mob,
and now it is drawn around that mob's face. It appears only while you actually have a
threat state on your target and vanishes with the target.

### New: the mana ring shows the aspect-swap band

Two static ticks sit on the mana ring at exactly the thresholds the two aspect alerts fire
on: a **red tick at 20%** (*Go Viper*) and a **green tick at 80%** (*Back to Hawk*). The
arc sweeps anticlockwise past the green mark and down towards the red one, so the swap
window is a thing you can *see coming* rather than a prompt that arrives. Nothing was lost
here — the v7 bars carried no tick marks at all; these are new.

### New: the target orb

Four of the six new auras make the right-hand cluster:

- **Target health** — the kill-window read: execute range, whether the pull is going
  anywhere, whether to swap.
- **Target mana** — deliberately an arc with **no number**. Rogues, warriors and every
  powerless mob produce no state at all, so an arc appearing here means *"this one casts,
  and here is what it has left"* — the Viper Sting / Silencing Shot read out in the open
  world, where the arena-only *Enemy Mana* bars do not load. Three stacked numbers under
  one orb would just be a bar stack again, rounder.
- **Two live portraits** — a real 3D head, so the orb identifies the mob or the player
  without a nameplate and without the pack ever knowing their class.

### Updating from v7 — leave "Arrangement" **checked**

**Nothing is orphaned and nothing needs deleting.** Every one of the 45 v7 auras keeps its
UID (`stable=45 changed=0 missing=0`), so WeakAuras offers a plain **Update** and the four
Resources auras change shape in place. There is no leftover "Hunter - Resources" group to
clean up, because it is the same group.

One thing does matter in the update dialog: **leave *Group Arrangement* checked** (it is
checked by default). That category carries width, height and position *for child auras*, and
the rings are 84x84 and 60x60 where the bars were 172x14. Uncheck it and you get three
squashed ellipses stacked where the bars used to be. Your dragged position of the *whole*
HUD is a separate category (*Size & Position*, on the top-level group only) and is
unchecked by default, so that is still preserved.

### Honest losses

- **A ring is less precise than a bar.** A 172px rectangle lets you read "about 40%" at a
  glance more accurately than a 84px arc does. The percentage numbers are still printed
  under both orbs, and the *decisions* the pack cares about — 20% mana, 30% health, 70/90%
  threat — are all colour flips, which read faster on an arc than a length ever did.
- **The threat number moved above the orb** instead of sitting at the right end of a bar.
- **The three bars' 1px borders are gone.** A `progresstexture` has no bar-border
  sub-region; the dark unfilled track behind each arc does that job instead.
- **No resource breakpoint marks were lost.** The aurabar tick sub-region is aurabar-only
  and could not have been carried over — but v7 used none, so there was nothing to carry.
  v8 adds two.

## v7 — the Horde trinket readout actually works

`Hunter - Trinket DOWN` was watching item **30346**, which is the *Priest-only* Medallion
of the Horde. A hunter can never equip it, so the trigger could never fire: a Horde hunter
who trinketed a fear saw nothing, and would reasonably conclude their medallion was still
up. It now watches **37865**, the all-class Medallion of the Horde, matching every other
pack. Alliance (37864) and both level-60 Insignias were already correct. UIDs unchanged —
imports as an Update.

## v6 — the cooldown row shows what you CANNOT press

v6 changes **only the cooldown row**, and only how its eleven icons decide when to be on
screen. No new auras, nothing removed, no load gate touched, no new custom code
(`stable=45 changed=0` — every v5 aura keeps its UID, so re-importing offers **Update**).

**The old row was inverted.** All eleven icons sat on screen permanently and merely dimmed
when the ability was down, so the row was busiest exactly when you had the fewest options —
and you already know your own spellbook. What you cannot know is what is *unavailable*, and
for how long.

So the situational buttons now appear **only while their cooldown is running**, carrying the
swipe and the countdown, and vanish the moment the ability is back. The row is a dynamic
group, so the gap closes: **absence is the readout.** An empty stretch of row means
everything is up. Two icons means exactly two things are down, and both are counting back.
The grey went with the change — under the new rule every visible icon is on cooldown by
definition, so greying them all would only make them harder to tell apart at a glance.

### The two buttons that stay, and now glow gold

Hiding an icon is the wrong answer for a button you press the moment it is up, because a
hidden icon cannot announce itself. Two shots in this row are exactly that, and neither had
a glow before — v6 gives them one:

| Icon | Why it stays visible |
|---|---|
| **Multi-Shot** | Both raid guides say to press it on cooldown in place of a Steady Shot — it is more damage per use than Steady Shot even on a single target. This is the button you press most. |
| **Arcane Shot** | The other half of the same weave slot when mana allows, and the instant you fire while moving. A 6s shot inside the core damage loop. |

Both are always on screen with two states and no third: **dim** while the cooldown runs,
**full colour with a gold pixel glow** the instant it is back — the same gold *Kill Command*
and the *Misdirection* prompt already wear, so the pack speaks one colour language. Out of
combat the pair fades to half alpha and the glow is forced off, so an idle row is still.

Arcane Shot was the closest call in the row: a mana-permitting filler is not Multi-Shot. It
went the visible-and-glowing way because it is in the core loop, and for anything in the core
loop a "press this now" signal is worth more than a "you cannot press this" one.

### Everything else answers only "when is it back"

**Intimidation, Readiness, Wyvern Sting, Misdirection, Feign Death** — plus the two
arena/battleground icons, **Freezing Trap** and **Scatter Shot** — are all pressed when a
circumstance calls for them, not on sight. They are gone from the row while ready.
Misdirection and Feign Death are the clearest case: their moment is already owned by a
threat-paired prompt in the *Alerts* flow (70% and 90%), which interrupts you; the row icon
only ever had to answer "when does it come back".

**Rapid Fire** and **Bestial Wrath** join them — a burst window is spent at a moment (the
opener, and again after Readiness), not on sight — but they keep both of their existing
states, because those states mean something the other icons do not have:

- **absent** — ready, use it when the window is worth it;
- **full colour + glow, swipe counting the buff** — the window is *live* (15s of +40% ranged
  haste; 18s of +50% pet damage);
- **dim, swipe counting the cooldown** — the window is spent and the button is recharging.

That is why those two alone kept their grey: on them it does not mean "on cooldown", it means
"the window is over", and it is the only thing that distinguishes the two visible states.

### What this looks like in a pull

Out of combat: two half-faded shots, nothing else. Pull, and the row fills only as you spend
things — Bestial Wrath lit while its window runs, then grey, then gone at 2 minutes; Multi-Shot
flashing gold every time it comes up. Glance down mid-fight and the row is a short list of
what you *cannot* do, in the order it comes back.

## v5 — the CC glow speaks, and the arena stops lying

v5 is a small, surgical Update of v4: **one new aura, two changed elements, nothing removed**
(`stable=44 changed=0` — every v4 aura keeps its UID, its triggers and its position). All
three changes come from three questions v4 shipped as "not proven"; each one has now been
settled against the WeakAuras source, and this is what the answers buy you.

### 1. `CC ON ME` is colour-coded — the glow tells you which break works

v4's prompt told you *that* you were controlled and for how long. It now tells you **what to
do about it**, in colour, which is the only thing you can actually read while stunned:

| Glow | Category | What you do |
|---|---|---|
| 🔴 **red** | stun (`STUN`, `STUN_MECHANIC`) | Nothing you own breaks a stun. It is the medallion or you eat it — and *Trinket DOWN* in the PvP stack is the other half of that sentence. |
| 🟣 **purple** | fear (`FEAR`, `FEAR_MECHANIC`) | The medallion, **or** Will of the Forsaken if you are Undead. The pack tracks that racial's own cooldown, so "which break do I spend" is answerable at a glance. |
| 🔵 **blue** | root (`ROOT`) | **Do not trinket.** A hunter shoots at full effect while rooted; a root only kills you if a melee is closing, and that has its own alert (*DEADZONE*). Save the break for the stun that follows. |
| 🟢 **green** | confuse / polymorph (`CONFUSE`) | Ride it out — any damage breaks it and your pet is already hitting something. Trinketing here throws the break away for an effect that is about to end anyway. |
| 🟡 **amber** | silence & school lockout (`SILENCE`, `PACIFYSILENCE`, `SCHOOL_INTERRUPT`) | Your shots *and* your traps are gone for the duration, so there is no "play through it" line. Trinket **earlier** than you otherwise would. |

Anything not in that list (charm, disarm, pacify, possess) keeps the red default, which reads
as "spend the break" — the safe fallback. The colours are **identical to the mage pack's**, on
purpose: if you play both, you learn one language and it transfers.

This works because `sub.1.glowColor` is a real, settable condition property (the glow
subregion exposes all fourteen of its keys to conditions, not just visibility) and because
this element's glow was already built with a custom colour, which is what arms `useGlowColor`
— without that flag the colour is stored and then silently ignored.

### 2. The threat bar and threat flash no longer load in an arena

An arena has **no threat table**. In v4 the bar loaded there anyway (an arena team is a
party), so it sat as a dead green rectangle in the slot closest to your crosshair. Both
elements now carry an instance-size gate that lists everywhere *except* `arena`:
open world, 5-man, 10/20/25/40-man and battleground.

Nothing about PvE changed. The open world is the literal instance-size value `none`, so it is
listed explicitly and the bar behaves exactly as it did while questing, in dungeons and in
raids. Battlegrounds keep it too — Alterac Valley has NPCs and a real threat table. (There is
no "not arena" switch in WeakAuras; the complement has to be spelled out, which is what this
does.)

### 3. New: `Enemy Mana` — one bar per opponent, arena only

A 120x12 bar per arena opponent **whose primary resource is mana**, showing their name and
their remaining mana percent. Rogues and warriors never produce a row, so what is left on
screen is the enemy healer and casters — the list of people you can drain.

Mana denial is how a hunter wins a long game, and Viper Sting is a choice of *target*, not a
rotation slot. This bar is the target-selection half of the *Viper Sting Out* row you already
have: it says who is worth the sting, and when the drain has done its job. Below **20%** the
bar turns amber — this pack's "press now" colour — because a healer under 20% cannot chain
heal through a swap, and that is the moment to stop kiting and kill something.

Arena-only (`arena1..arena5` do not exist in a battleground) and gated on `spellknown 3034`,
so it appears next to the drain it exists to aim. One honest caveat: how often the 2.5.x
server pushes power updates for arena units is a client behaviour, not an addon one — the
readout refreshes at minimum whenever the arena frames update, so treat a number that has not
moved in a while as stale rather than as a measurement.

## v4 — PvP layer

v4 adds twelve auras that load **only inside an arena or a battleground**. Everything else
is untouched: same uids, same triggers, same load rules, same positions
(`stable=32 changed=0` against v3).

**Nothing changes in PvE.** Every new aura carries its own instance-type load gate
(`use_size = false, size = { multi = { arena = true, pvp = true } }`), not just the group it
sits in — a group's load is not a child gate. In a raid, a dungeon, or out in the world the
new group is empty, the cooldown row is the same nine icons it was in v3, and the alert flow
holds the same nine prompts. Three of the current elements read `arena1..arena5` and are therefore
**arena-only**, because those unit ids do not exist in a battleground and a BG-loaded arena
element is a permanently blank slot.

### New group: `Hunter - PvP` `(150, 96)`

A downward dynamic stack on the opposite side of your character from `Alerts`, holding the
state readouts. It is empty when nothing needs saying:

| Element | What it shows | What you do differently |
|---|---|---|
| **Trinket DOWN** | your medallion/insignia **while it is on cooldown**, desaturated, with the swipe | Absence means ready. While the icon is up your only break is Bestial Wrath / The Beast Within, so you eat the next CC instead of pre-trinketing, and you stop pushing into a setup you cannot escape. Four item ids are watched (Medallion of the Horde/Alliance, hunter Insignia of the Horde/Alliance) — never the equipment slot, which would report "trinket down" for a PvE on-use trinket in the other slot. |
| **Will of the Forsaken DOWN** | Undead only: the racial while it is on its own 2-minute cooldown | A second, independent break. Knowing it is up is what lets you spend the medallion on the first stun instead of saving it for the fear. Gated on `spellknown 7744`, so nobody else ever sees it. |
| **Enemy Trinket** | one clone per opponent, counting 120s down from the moment you *saw* them use it | Their break is gone: this is the window where a Scatter → Freezing Trap or a Wyvern Sting actually sticks, so the whole team's CC chain goes in now instead of being wasted. |
| **Trap Armed** | a Freezing Trap you just dropped, counting down its 1-minute lifetime | Pull the target across it, and recall your pet first — your own pet is the most common trap-breaker. It also stops you burning the second trap while the first is still live. |
| **Viper Sting Out** | one clone per opponent carrying **your** Viper Sting, with the remaining 8s | Mana denial is how a hunter wins a long game, and the sting is dispellable. The row emptying *is* the re-apply prompt; tracked on the opponents, not on the kill target, because the drain belongs on whoever heals. Arena-only. |

### New prompts in `Alerts`

Same language as the rest of the flow — they slide in from below, glow, and fly up on exit:

- **CC ON ME** — any loss-of-control effect on you, with its own icon and a countdown.
  It answers "ride it or spend the break": a stun means trinket, a root does not, and a
  school lockout means the spell you were about to use is gone for the duration. This is
  also the only element in the pack that can see a Kick/Counterspell **school lockout**,
  because a lockout is not an aura and no aura trigger can ever find it. No combat gate —
  the opening Sap or trap lands before you are in combat. Since v5 the glow **colour** carries
  that answer, so you do not have to read anything: see *v5* above.
- **DEADZONE** — a hostile target inside roughly 8 yards, in combat. Your shots do not work
  right now, so the next press is Wing Clip, Scatter Shot, a trap or melee, never a shot.
  The deadzone kills more hunters than any cooldown mistake and is one of the very few
  positioning facts a HUD can express. It is a range *estimate* (WeakAuras' range check is
  approximate), so treat it as a warning, not a measurement — and it is the pack's only
  frame-update trigger, which is exactly why it is behind the PvP and combat gates.
- **SILENCE NOW** — your target is casting **and** Silencing Shot is genuinely castable
  (off cooldown, in range, mana available). The prompt uses "Action Usable", so it never
  glows for a button that would fail; the countdown under it is the remaining cast time.
  Marksmanship only, via `spellknown 34490`.
- **TARGET IMMUNE** — the target gained a hard stop: Divine Shield, Blessing of Protection
  (physical immunity, i.e. every shot you own), Ice Block, Cloak of Shadows, or The Beast
  Within. Stop the burst — swap, pool, or wait it out. The icon shows *which* immunity,
  because that decides swap versus wait.

### Two icons join the cooldown row (arena/BG only)

**Freezing Trap** and **Scatter Shot**, both gated on their own spell id *and* the PvP gate.
Scatter → Trap is the hunter's entire opening game plan and neither button has any place in
a raid row, which is why they were not there before and why the row is byte-for-byte
unchanged in PvE.

### What this layer is **not**

- **It is not diminishing-returns tracking.** TBC DR (Freezing Trap shares the Incapacitate
  category with Polymorph, Sap, Gouge, Wyvern Sting and Repentance) cannot be expressed in
  WeakAuras without a custom trigger maintaining its own category table — there is no DR
  concept anywhere in the addon. Nothing here approximates it: `Trap Armed` is the trap's
  own lifetime and `Viper Sting Out` is a debuff timer. Neither says anything about whether
  your next trap will land at full duration. An incomplete DR tracker is worse than none,
  because it gets trusted.
- **It does not read enemy cooldowns.** No API on 2.5.x can. `Enemy Trinket` is an
  *inference* started by seeing the cast: if an opponent trinkets out of your view, nothing
  starts, and the 120s assumes the level-70 medallion (the old level-60 insignias are 5
  minutes).
- **It cannot see a trap being sprung.** `Trap Armed` runs the trap's maximum lifetime; if
  the trap is broken by your pet or a stray tick, the icon keeps counting.
- **It cannot tell which opponent is the healer,** and no element pretends to. Enemy *class*
  is readable on TBC, enemy *spec* is not. (v5's `Enemy Mana` narrows the field to the
  opponents who *run on* mana, which is a strong hint and still not an answer — a shadow
  priest and a holy priest look identical to it.)
- **It cannot filter casts by interruptibility.** WeakAuras disables that argument entirely
  on TBC clients, so `SILENCE NOW` fires on any cast your target starts. Fake-casting stays
  a player skill, not a HUD feature.
- **`CC ON ME` depends on the client's loss-of-control API.** WeakAuras registers the
  trigger for TBC and calls `C_LossOfControl`; that the 2.5.x client populates it is the one
  thing here that source cannot prove. Get sapped and kicked in a duel once and confirm the
  icon appears. Everything else in the layer is built on primitives this repo already ships.

## v3 — spec-selective loading

v3 is a **gating-only** in-place Update of v2: no new elements, nothing removed, every UID
unchanged (`stable=32 changed=0`). The audit question was not "can this spec cast it" but
"does this spec *press* it as part of playing well", asked element by element for Beast
Mastery (41/20/0) and Survival (0/20/41, or the 0/21/40 variant that skips Readiness — the
Readiness icon gates on its own spell id, so the row is right either way).

The answer for this pack is mostly *yes, both*. BM and SV run the same shots in TBC — the
Auto Shot ↔ Steady Shot weave, Multi-Shot on cooldown, Kill Command off the GCD after a crit,
Serpent Sting / Arcane Shot as the instants you press while moving, one pet, Aspect of the
Viper for mana, Misdirection then Feign Death for threat. Both raid guides describe the same
loop, so the shared core is legitimately large and it stays shared. Cutting it per spec would
have been noise, not clarity.

Exactly one element failed the test:

| Element | No longer loads for | Why |
|---|---|---|
| **Expose Weakness** timer | Beast Mastery | The 7s debuff is a **Survival talent proc** and the trigger is `ownOnly`, so a BM hunter could never fill this timer — it was an SV raid mandate sitting in the "loads for everyone" set. Now `use_not_spellknown = 19574` (Bestial Wrath): anyone 31 points deep in Beast Mastery is not the hunter this element speaks to. |

That also upgrades the shared `x=44` buff slot from a talent-arithmetic argument to a load
rule: BM sees **The Beast Within** there and nothing else; every other build sees
**Expose Weakness** there and nothing else. The two can no longer overlap by construction.

**Requires WeakAuras 5.4.0+** for the inverse gate (`not_spellknown`). Older clients ignore
the field, which means Expose Weakness simply loads for everyone — exactly v2's behaviour, so
nothing breaks.

Kept deliberately, and worth naming because they look like cut candidates:

- **Mongoose Bite** stays for both specs. Both raid guides discourage melee weaving, so the
  cut would have to hit *both* specs, not one — and its trigger already gates it perfectly:
  it only appears when something was dodged **by you**, i.e. when you are standing in melee.
  It is silent for a ranged hunter of either spec, and it is the right button for the
  levelling/solo case both specs share.
- **Kill Command, Mend Pet, Revive Pet** stay for both. Survival runs a pet too and uses Kill
  Command on cooldown; a dead pet costs an SV hunter the same button it costs a BM hunter.
- **Serpent Sting and Arcane Shot** stay for both — both specs press them on the move.
- **Intimidation** (BM) and **Wyvern Sting** (SV) are already single-spec via their own spell
  ids and were left exactly as they were.

## v2 — rotation fixes

v2 is an in-place **Update** of v1 (same UIDs — WeakAuras offers *Update*, not a duplicate
group). Five new elements, seven corrections; nothing was removed.

| Fix | Why |
|---|---|
| **Arcane Shot** joins the cooldown row (3044) | The guides' weave slot is "Multi-Shot **or** Arcane Shot", and Arcane Shot is the instant you press while moving. v1 shipped one half of an either/or and called the other half situational. |
| **Back to Hawk** prompt (new alert) | v1 only taught the *entry* to Viper. Viper is a flat damage loss (Hawk r8 = +155 ranged AP), and `ASPECT MISSING` structurally cannot catch it — Viper counts as an aspect, so that alert stays silent forever. The new prompt fires in combat when you are in Viper **and** back above 80% mana. |
| **Misdirection prompt** (new alert) at 70% threat | The threat bar's danger state was paired with the wrong ability. Feign Death is a full threat wipe that costs shots; Misdirection is the actual 70%-band answer and every TBC hunter presses it on cooldown. It now has a prompt instead of only a flat icon in the outer row. |
| **Feign Death prompt** moved 70% → 90%, and gated `combat` + party/raid | Solo you *are* the entire threat list, so `threatpct` reads 100 and v1's prompt glowed permanently while questing. 90% is also the honest threshold now that Misdirection owns 70%. |
| **Mend Pet** and **Revive Pet** prompts (new alerts) | The pet is ~35-40% of Beast Mastery damage and the prerequisite for Kill Command — and with a dead pet, spell 34026 is still *known*, so v1's best element glowed for a button that does nothing. `unit = "pet"` is a first-class WeakAuras unit, so v1's "no reliable pet-state trigger" was simply wrong. |
| **Rapid Fire** and **Bestial Wrath** icons now show their **active window** | v1 showed only the cooldown, so the icon went flat for exactly the 15s / 18s in which the burst decision is live. Trigger 1 is now the buff (Rapid Fire 3045 on you, Bestial Wrath 19574 on the pet — that one is a *pet* aura in TBC), trigger 2 the cooldown; while the window runs the icon stays full colour and glows. |
| **Threat bar**: third colour tier at 90%, party/raid gate | One tier per paired ability — orange at 70 (Misdirection), red at 90 (Feign Death), deep red on aggro. Solo the bar sat pegged at 100% red in the closest slot to the crosshair. |
| **Viper threshold 15% → 20%** (bar and prompt together) | Viper's regen scales off *missing* mana, so 15% is late. The bar's colour flip and the prompt still share one number. |
| **Kill Command** also opens on a **melee** crit | TBC Kill Command is enabled by any critical strike of yours. v1 watched `RANGE_DAMAGE` and `SPELL_DAMAGE` only, so in the one scenario where a hunter melees (pet tanking a dungeon, which is why `Mongoose Bite` ships) the window went unnoticed. |
| **Kill Command anchored** at the bottom of the alert flow | It is the pack's one reflex prompt, so it gets a fixed home instead of being pushed up whenever another alert appears. |

Still **not** in the pack, and deliberately so — see *Deliberately not included* at the
bottom for the reasoning: the Auto Shot ↔ Steady Shot weave (a swing-timer question, and a
design decision you should make before it is built) and the AoE breakpoint suite.

## Groups

**Resources** `(0, 40)` — since v8, two unit orbs instead of a bar stack, each its own
draggable cluster inside the group.

*Player Orb* `(-250, 0)`: an 84px health ring (green, `%` beneath), a 60px mana ring (blue,
`%` beneath) and a 26px live portrait. Both rings are always up and fade to 50% alpha out of
combat. Health goes red below 30%; mana goes red below 20% — the same threshold that fires
the Go-Viper prompt, so the ring and the alert agree — and carries the two aspect-swap ticks
(red at 20%, green at 80%).

*Target Orb* `(250, 0)`: a 108px threat ring outermost (`%` above the orb), then the
target's own 84px health ring (`%` beneath) and 60px mana ring, then the target portrait.
The whole cluster disappears when you have no target. The threat ring loads only in a party
or raid, never in an arena (v5 — there is no threat table there), and only exists while you
have a threat state on your target: green normally, orange from 70% (press Misdirection),
red from 90% (press Feign Death), deep red the moment you are actually pulling aggro. Just
outside it sits a red `ADD`-blend halo that pulses at 80%+ threat, same gates, because solo
threat is your pet's problem, not yours. The target's mana ring shows no number and only
exists for units whose primary resource *is* mana, so a warrior or a rogue never draws one.

**Buffs** `(0, -16)` — a static row of four 40x40 icon timers with the remaining duration
under each icon. Serpent Sting (your own DoT only, all ten ranks) sits left and glows in its
last 3 seconds so you refresh instead of clipping; Hunter's Mark (any hunter's, all four
ranks) sits centre. The right slot is spec-shared: Beast Mastery sees **The Beast Within**
(the 18s self-buff from the 41-point talent, spell 34471 — not the passive talent), Survival
sees **Expose Weakness** (your own 7s debuff on the target, spell 34501). Keeping that debuff
as close to 100% uptime as possible *is* the Survival raid job, so it gets the prime slot and
doubles as the alignment cue for Rapid Fire and Readiness. Since v3 the two are exact load
complements on Bestial Wrath, so a Beast Mastery hunter never loads the Survival timer at all.

**Alerts** `(-150, 96)` — a dynamic stack of glowing 40x40 prompts growing upward beside your
character; each one slides in from below and flies up while fading out when it stops applying,
so the appearance itself is the signal. Nine prompts in PvE (four more in arena/battleground,
see *v4 — PvP layer*), with *Kill Command* anchored at the bottom of the flow so the one
reflex prompt never moves:

- *Kill Command* — you landed a ranged, spell **or** melee crit **and** Kill Command is off
  cooldown, i.e. the exact 5-second window in which the button works.
- *no aspect at all* — neither any rank of Hawk nor Viper, in combat only.
- *Mongoose Bite* — something was just dodged by you **and** the bite is ready.
- *Feign Death* — threat at 90%+ **and** FD ready, in combat, party/raid only.
- *Go Viper* — mana under 20% **and** you are not already in Viper, in combat.
- *Back to Hawk* — mana back over 80% **and** you are still in Viper, in combat.
- *Misdirection* — threat at 70%+ **and** MD ready, in combat, party/raid only.
- *Mend Pet* — the pet is alive and under 40% health.
- *Revive Pet* — the pet is dead (this is also why Kill Command stopped working).

**Cooldowns** `(0, -66)` — a horizontal, self-collapsing row of 32x32 icons with WA cooldown
text and tooltips on hover. Since v6 the row shows what you **cannot** press (full reasoning
under *v6* above):

- **Always there:** *Multi-Shot* and *Arcane Shot*, the two shots you press the moment they
  are up — dim while recharging, full colour with a gold glow when ready, both at half alpha
  with the glow off out of combat.
- **There only while on cooldown:** *Intimidation*, *Readiness*, *Wyvern Sting*,
  *Misdirection*, *Feign Death*, and in an arena or battleground *Freezing Trap* and
  *Scatter Shot* (v4). Each carries its own countdown and disappears when it is back, so a
  gap in the row means the button is available.
- **Both, plus a live-window state:** *Rapid Fire* and *Bestial Wrath* show their *active*
  window first (15s of +40% ranged haste; 18s of +50% pet damage) — full colour plus a glow
  while it runs, a dim cooldown swipe afterwards, and absent once it is ready again.

Talent and late-trained abilities load-gate on their own spell, so the row shows exactly the
buttons your current build owns and the gaps close by themselves. Kill Command deliberately
has no icon here — a 5-second cooldown says nothing useful; its reactive alert owns it.

**PvP** `(150, 96)` — a downward dynamic stack of state readouts that exists only in an arena
or a battleground: trinket down, Will of the Forsaken down (Undead), enemy trinket countdowns,
trap armed, Viper Sting out, and (v5, arena only) one **Enemy Mana** bar per opponent who runs
on mana. Empty in PvE, and empty in PvP whenever nothing needs saying. Full description in
*v4 — PvP layer* and *v5* above.

**Procs** `(110, 24)` — a cloned 32x32 icon right of the bars for **Quick Shots**, the 12s
+15% ranged-haste proc from Improved Aspect of the Hawk. It pops in with a scale-and-pulse
and flies right on expiry. It is the smaller of the two haste windows the pack sees; the
bigger one (Rapid Fire) lives on its own icon in the cooldown row.

## Spec gating

The pack auto-adapts on respec with zero user action — every spec-specific element gates on
`spellknown` of a spell that is only in your book when the talent (or the training level) is
actually there:

| Element | Gate | Shows for |
|---|---|---|
| The Beast Within timer | `spellknown 19574` (Bestial Wrath) | Beast Mastery |
| Expose Weakness timer | `not_spellknown 19574` (v3) — inverse gate | everyone except Beast Mastery |
| Bestial Wrath / Intimidation CD | `spellknown 19574` / `19577` | Beast Mastery |
| Readiness CD | `spellknown 23989` | Survival (41-pointer) |
| Wyvern Sting CD | `spellknown 19386` | only if you took it (raid SV skips it) |
| Kill Command alert | `spellknown 34026` | level 66+ |
| Misdirection CD / prompt | `spellknown 34477` (+ combat, party/raid on the prompt) | level 70 |
| Go Viper prompt | `spellknown 34074` + in combat | level 64+ |
| Back to Hawk prompt | `spellknown 13165` + in combat | any hunter with Hawk |
| Aspect-missing alert | `spellknown 13165` + in combat | any hunter with Hawk |
| Mongoose Bite alert | `spellknown 1495` | any hunter |
| Feign Death prompt / CD | `spellknown 5384` + combat + party/raid / none | level 30+ |
| Mend Pet prompt | `spellknown 136` | any hunter with a pet |
| Revive Pet prompt | `spellknown 982` | any hunter with a pet |
| Threat bar / threat flash | party/raid **and** not in an arena (v5) | grouped PvE, and battlegrounds |
| CC ON ME / Trinket DOWN / TARGET IMMUNE | arena + battleground | everyone, PvP only |
| DEADZONE prompt | arena + battleground + in combat | everyone, PvP only |
| SILENCE NOW prompt | `spellknown 34490` + arena/BG | Marksmanship (Silencing Shot) |
| Will of the Forsaken DOWN | `spellknown 7744` + arena/BG | Undead |
| Trap Armed / Freezing Trap CD | `spellknown 1499` + arena/BG | level 20+, PvP only |
| Scatter Shot CD | `spellknown 19503` + arena/BG | Survival 20-pointer, PvP only |
| Enemy Trinket | **arena only** (reads `arena1..arena5`) | arena |
| Viper Sting Out | `spellknown 3034` + **arena only** | level 36+, arena |
| Enemy Mana (v5) | `spellknown 3034` + **arena only** (reads `arena1..arena5`) | level 36+, arena |

Beast Mastery and Survival never both light up at `x=44`. Since v3 that is enforced by the
load rules themselves and not by talent arithmetic: The Beast Within needs `spellknown 19574`,
Expose Weakness needs `not_spellknown 19574`, so the two are exact complements — whatever your
build, exactly one of them is eligible for that slot. (Belt and braces: the tracked auras
already made a double-show implausible, since 34471 only exists for the 41-point talent The
Beast Within.) On a pre-5.4.0 WeakAuras the inverse gate is ignored and the aura falls back to
the v2 situation, where the tracked debuff itself is what a BM hunter can never produce.

## Deliberately not included

- **Auto Shot ↔ Steady Shot weave timing.** This is the spec's central skill, and it is *not*
  unbuildable: WeakAuras in this client does ship a Swing Timer trigger with a `ranged` hand
  (v1's README claimed no sanctioned trigger provides it, which was wrong). It is left out
  because it is a design decision, not an oversight — the trigger's own tooltip warns that
  non-retail swing results are inaccurate in edge cases, and a weave bar that lies costs more
  than no weave bar. Bloodlust/Heroism and the "tighten the weave under haste" reading of
  Quick Shots are parked with it, since they only become actionable next to a swing bar.
- **The AoE breakpoint suite** (Explosive Trap at 7+ targets, Volley at 10+, situational
  Survival traps). A plain on-cooldown trap icon would prompt a ranged hunter to walk into
  melee, so these need a target-count scenario gate and a group of their own.
- **A pet health bar, a pet unit frame, or (since v8) a third pet orb.** The pet is
  ~35-40% of Beast Mastery damage, so this was reconsidered when the orbs went in, and the
  answer is still no. There are exactly two pet decisions in the rotation and both are
  *threshold* decisions, not readings: heal it below 40%, resurrect it at 0. Each already
  has a prompt in *Alerts* that interrupts you at the moment it applies. A permanent third
  orb would show a number you act on twice, and would spend the screen space the v8 layout
  just freed to say something the pack already says louder.
- Master Tactician (a passive crit proc you cannot react to).
- **Deterrence**, deliberately, even in the PvP layer: on 2.4.3 it is +25% parry and dodge,
  not an immunity, so it is not a hard stop on the target-immunity alert and it is not a
  button whose readiness changes your next press the way the trinket's does.
- **A per-opponent range column, enemy health frames, or an enemy-cooldown wall.** The first
  is impossible (WeakAuras' range check has no arena unit and every extra unit costs its own
  frame-update trigger); the other two are Gladius' job and fail the "changes my next press"
  bar. *Enemy mana* used to sit in this list on the grounds that arena-unit power was not a
  verified primitive — it now is (WeakAuras only removes arena units on Classic Era, not on
  TBC), so v5 ships it as a real element.

## Importing

Copy the whole string from the fenced block at the bottom (GitHub's copy button on that block
grabs it exactly) or from `all-specs.txt`, then in game: `/wa` → **Import** → paste.

Four things to expect, all normal:

- The thirteen **PvP auras show as greyed-out / not loaded** in the `/wa` list whenever you
  are not in an arena or a battleground. That is the load gate working, not a fault — step
  into a BG and they light up. Three of them (`Enemy Trinket`, `Viper Sting Out`, `Enemy Mana`)
  stay greyed out in a battleground too: they read `arena1..arena5`, which only an arena has.
- The import dialog shows a **code-review panel**. This pack contains exactly two lines of
  custom code — one on the Kill Command alert and one on Mongoose Bite, both the same
  sanctioned "either of these events fired, and the ability is ready" one-liner.
- The `/wa` **editor preview lies**: selecting a group force-shows every aura with fake data,
  so you will see both spec slots at `x=44` at once, identical fake durations like "55.1", and
  an empty threat "%", and both orbs' rings pegged at some arbitrary fake fill. Judge the
  layout there, judge behaviour in combat.
- On a future re-import the Update dialog's **Arrangement** checkbox (checked by default)
  resets any positions you dragged in game back to the string's defaults. Uncheck it to keep
  your own placement, or tell me your coordinates and they get baked into the script.
  **Coming from v7, leave it checked** — it is the category that carries width and height for
  child auras, i.e. the thing that turns the old 172x14 bars into 84px rings (see *v8* above).

## Regenerating

```bash
lua5.1 tbc/hunter/generate.lua
```

Run it from anywhere — the script resolves the toolkit and its own output directory from its
own path. It rebuilds `tbc/hunter/all-specs.txt`, round-trip verifies the string (decode +
deep-compare + structural wiring check) and prints the aura count, string length and the UID
continuity report against the previous version of the file. The build is fully deterministic:
the same source produces a byte-identical string every run.

`math.randomseed(20260814)` at the top of the script is this pack's **fixed seed** and must
never change: it is what makes the UIDs stable, which is what makes WeakAuras offer *Update*
instead of creating a duplicate group. When adding auras in a future version, append new
elements at the end of the build order — never reorder or delete existing ones. v2's five new
auras are built at the bottom of the script and re-parented into their groups afterwards,
which is why every v1 aura kept its UID (`stable=27 changed=0`). v3 adds no constructors at
all — it only sets two load fields — so it reports `stable=32 changed=0` against v2. v4's
twelve PvP auras follow the same rule — constructed in a block at the very bottom, then
re-parented into `Alerts`, the cooldown row and the new `Hunter - PvP` group — so it reports
`stable=32 changed=0` against v3, with every pre-existing aura's load table, triggers and
parent unchanged as well. v5 adds exactly one constructor (`Enemy Mana`), again at the very
end of the file, and changes three existing auras in place without touching a single `uid()`
call: `stable=44 changed=0` against v4. v6 adds **no** constructors — it rewrites the
cooldown row's display in place (one trigger field per icon, the conditions that go with it,
and a glow subregion *replaced* at index 1 on the two rotational shots, never inserted, so no
`sub.N` condition anywhere in the pack is silently retargeted): `stable=45 changed=0`
against v5, with every load gate, position and parent untouched. v7 changes one item id and
adds no constructors: `stable=45 changed=0` against v6.

v8 is the largest in-place rewrite so far and still obeys the rule exactly. The four
Resources auras keep their original build positions in the script — `Hunter - Health`,
`Hunter - Mana` and `Hunter - Threat` swap `F.aurabar` for a hand-written `progresstexture`
table at the *same* point in the file, so each consumes the same `W.uid()` call it always
did — and the six genuinely new auras (two cluster groups, two portraits, the target's two
rings) are constructed in a block at the very bottom, then everything is re-parented.
Re-parenting, renaming and reordering `controlledChildren` all cost nothing; only the `uid()`
call order matters. Result: `stable=45 changed=0 missing=0` against v7, so **no v7 aura is
left orphaned** and nothing has to be deleted by hand after the update.

## Verified spell IDs

All checked on wowhead.com/tbc. Aura triggers carry every rank; cooldown triggers and
`spellknown` gates carry the rank-1 ID.

| Spell | Use | IDs |
|---|---|---|
| Serpent Sting | own DoT timer (r1-r10) | 1978, 13549, 13550, 13551, 13552, 13553, 13554, 13555, 25295, 27016 |
| Hunter's Mark | debuff timer (r1-r4) | 1130, 14323, 14324, 14325 |
| Aspect of the Hawk | missing-check + gate (r1-r8) | 13165, 14318, 14319, 14320, 14321, 14322, 25296, 27044 |
| Aspect of the Viper | missing-check, Back-to-Hawk check + gate | 34074 |
| The Beast Within | BM burst-window buff (18s, 41-pt talent) | 34471 |
| Expose Weakness | SV target debuff (7s) | 34501 |
| Quick Shots | haste proc (12s) | 6150 |
| Kill Command | reactive alert + gate | 34026 |
| Mongoose Bite | reactive alert + gate | 1495 |
| Feign Death | prompt + CD icon | 5384 |
| Bestial Wrath | CD icon + 18s **pet** buff window + BM gate | 19574 |
| Intimidation | CD icon (BM) | 19577 |
| Readiness | CD icon (SV 41-pointer) | 23989 |
| Wyvern Sting | CD icon (SV 31-pointer) | 19386 |
| Rapid Fire | CD icon + 15s +40% haste window | 3045 |
| Multi-Shot | CD icon | 2643 |
| Arcane Shot | CD icon (r1) | 3044 |
| Misdirection | CD icon + threat prompt + gate | 34477 |
| Mend Pet | pet prompt + gate (r1) | 136 |
| Revive Pet | dead-pet prompt + gate (r1) | 982 |
| Silencing Shot | v4 interrupt prompt + gate (MM) | 34490 |
| Scatter Shot | v4 CD icon + gate | 19503 |
| Freezing Trap | v4 CD icon, trap-armed inference + gate (r1-r3) | 1499, 14310, 14311 |
| Viper Sting | v4 arena clone row (r1-r4), v5 `Enemy Mana` gate (r1) | 3034, 14279, 14280, 27018 |
| Will of the Forsaken | v4 second-break readout + gate | 7744 |
| PvP Trinket | v4 enemy-trinket inference (the spell every medallion casts) | 42292 |
| Divine Shield | v4 target-immunity alert (r1-r2) | 642, 1020 |
| Blessing of Protection | v4 target-immunity alert (r1-r3) | 1022, 5599, 10278 |
| Ice Block / Cloak of Shadows | v4 target-immunity alert | 45438, 31224 |
| The Beast Within | v4 target-immunity alert (their trap immunity) | 34471 |

PvP trinket **item** ids watched by *Trinket DOWN* (all four verified on wowhead.com/tbc;
only one can ever be equipped, so they are ORed into one element):

| Item | Id | Cooldown |
|---|---|---|
| Medallion of the Horde | 37865 | 2 min |
| Medallion of the Alliance | 37864 | 2 min |
| Insignia of the Horde (Hunter) | 18846 | 5 min |
| Insignia of the Alliance (Hunter) | 18856 | 5 min |

## Import string (v8)

```
!WA:2!L3xF4TXX5DMH0QsgwowIws2sXYgMXsvsXwgFqWp0zLeaqqsqrcaTa8d9HnXcSlWUIa7UA3fKe0j1nSookF4MwMl(UM2M4YK6RoNtVRSj9UZPj9k7Z17RC3nh7D9207sUw20uNu)KRw33pp3FCVZmlawqacsrrzl5(hC5UZo7SZmV)MFVVVZ8UdqJ3r2x2)1EKvZWNDAbDvTWQfu1hU92Bpr7EoDaToYQQyQRwOGOqyj5cc6IkNs7(hQKIPOU7NWDIc8LHtIRNXrIP41ZlAssCTmQ6cI6HSlBT9fQG88ZZRl4oLQAbtzn95INlNHOjkJgpu0MAhXUusfkmusHg19XDNSK(mYZWxidRWK0lZEMZVKUyEzvLuL1e5YRRwsBjwoskpV4UwwwjNQErEtihUwMDdwBdHqTVkFjtjv94AKBB4kd0kZjN3LoFwAcDZzyYRB6ktozfzdjxHG)z6AbtD585f1nIDCD7tFPqMK3oFjDEFRqoAOjwOGSGXr6WtOsWdLrJ2dTan9OcgUwZOugXzGMAYs5Yjp3YtfoyYutLmvqUuvVvcDr4wCjtezKrUEjdXiZb1RKSsinNcFrrdxljiMbkbsJxFOiJKyGXgzrORJvTCTSGSXvkPaTMze9XxOG2(5PNNID)rvfeFT3JD3veH8IA7p5vlbsa3duQqb3tijBkUc7US(67ErEfzwNz34dmWkI8gIjnbjwEtPDJpCifvfXvfG2pjhtr6t0neHovbJfizLulXEcvKxwza8tcpa2d2l2h2p8)dU(uw0qSqUeQYkMzchjwQiCDklO1rv0fNOHAj9SIgxxMKIcFHXHxg8AV0Y50HUgOAXBY3(15vYcs4bijrE9zsgMlsKylzQMDgw(3tId6RKSWYfMRNr4U64xCUGtZzKLVGy7lbccok2YOc0jQc0l0(sKMKmdZeQGkVGRLzVgA1f391EemQ6yhCBN56vR1djYxWuA1QxpkVcV2dU(XrjubGfVSjEx4Fk8UFT7dVhCpyxs47bH3l(EXV3DHVpx49rrW497c3Hl89dIdx4d6cFix4hi2XXp4lbDLhb)(a8h(HWhf)WUWpc2n(rXDIF)PXpMl8XWhh)t7cFc8jXN61Ep4pa(XXpXDJpnrQUEjtxBUScha3niEWTJ79s4(AhFg8Fl8tbDS4ZUCPIAxDGzozYXZEf8hQD8h2foy74qUWHDH7h6PotgayRpvze7)ZHW7gTmVWvkzykkmk)CTv7czL2i9aWtPDabrdEtcotKqQqg1RiiTSbrilohCdX0oZZaQafblpCgf4vmrliQieujFbXN)qqvEnnD186IggjPqQt9qVN2iTiOBVDsN7(DTGUQjftJ44lOjXdTGZCCUSsIzNEa8d2(cZWRlZNPG4QaGplmYvIkM5a2QsID63tNQAD8u6zL4vYlACKJJNCycYOVe3LNt71h7y7la1b4PnlF9CvRTuIQJJhdEh7cp(cYkHvlMH3epjckXop7zXxGuymu2fXPy5SD84lwKFowvapzhK3ENpLDErK8H)Wh5ApOwhMqp1ugs8cQZoPn97I00ih023XQRTCSJPTphpqnk01yPwzSAOGJLkU29tteixvjKfzNqwWukuq4YRtVbWQjkqt8JTkBGZfyvGrAFfAgisC5CLXDVeTJNkudflESi4dRddkPvqw9N94vQ)lrtlBfDxTZAp5aDxA7BaD55DF(s8ceEb3PsP5PAJDkMkIPQRfpLGywGRRWuA6WjeMcuD9z2vzuDvKQTJvPjolqAmHoV2ctyFYQvRqug74JLAKOXIy31whhI2j3KQhfHq5y5YvqvvN1ZndutbGy6AViIAWhz167N0o2Mu4SeZeRuXmI6zKeLZlz(QBB6HmzbS9uLji9U86KRsBFWO(G2dWPJ3L02FMQJOThlR1tuc)yo(SIxoOGqCfJlpHi)0bj6zV8OIcY8x2oNgxMtwj)uE9On3PnZZt5GwIQdNoyhHdp(IWBCQSf4nmsNXey5vmpexXsGriU4OPE8mgYK8MzOXikDWFIdH)uPdb6TZEi8NWvidO3KCc(bEgBw2hIWSYrvyNHrVBZ4Ua5nru(NMY7wL015ZHFrTdmgKf3HL4jwDiQldi)SgviT)SR7zRqyNPOSUUQU067aLvKW796vOZmz9klOcQ6anlgUweGgkce1(CHgjsS(P2QWvHBBnJIQQMsjSF60lr5khqw3WuAz7YiBbznjc)(1TlCcQMuGAhi8ibhnrQ4Hgjy4ZfS)(JMk64aYUM00g7D9APuLfHGmceyHSQf1iVzjIUKi4lnmLBma5yp9so6lq7G6fUzjuhVQ2(RXuAl)X)CGghLUhuCYyJe9kAZQlRq0YlkTiTPqQNzIglz0(JSSQUmiXOn8fdps8WNBIOjJWaQZzduVpx60htuq6ANbhfHhMODcFU2WJurteEujCS044s4ei85PktWCnQ)aNeHtrvAuHIEf7XBAQZkQJNStFmLemwAA7U3aeIDF0dTd02xQQIa8L3unalaAaSl6o82efaN5Api(zq4PU(XCwpo2XW8mRkYGZIfWI4CFmC(c3fwcAmY4RaO2PXfq4IdZeyubtG2BhRGvX6q(Uks7eBeZc9n4G1cxgBGnXLWZGNfk(5tR9yT(rzPH)zWp7dG)iiTNS15Ur27RDGvTXSJYg8qSh5xeSQkXD17P7oWseDytPXyFRGURn2WoHXT5xTn4BQIKXs0hQskG5Z8(coYi4dVKTQkcf2(TpP)QgLivPiRWYDMTolhZk9POgOtj6E57Bf7sJnMQra0UtSlFDF6U9JFU7Bf7AQDBndthR0QoBZIsmLsW1HQWzGFPRDa8)W11TH)TaH3Yi8VDA8xh)nW)o4)rak5Fm(FIe(1XFtOEH)DPg70v7SJ4Dpz16b(Bbp63wc)7jH)NIFj8ZvE7B)5pBJ6wWFmj8caHa1o0NNq9J)4PXVaL8(Ahh)jXFkg3o(ttt6ZuJv)3Pg7mxc6GiGnErkSIaCr1rmVkHLV69s3uoE8VWMXNt6qxeOUXFo8FBx4pp0B83bH)7Mg)ljH)cu6w8Vm(xb)RIWFX3qc)LO8JdyZp6lqTbJ9r5hXVCz8VgLkS3SENxV4fhw4K9G)Ys4Vc(xh)k4)E4FJQeC4xv6ADTmbexiQXyuDvGph(41KLiuDmsoD69j2MVVAE1uNhhpZ6AV)8Bu79gTFzfnBxHUOQAX0a76kS6so5cIrfWhDj2LA8Gw3JYAhtzaScLraLRJRH6o45XZfyRHcC48gqHVGH4vljQKvKsM)HOUCboJ9bcfd82fVxo6Bb)EF0AVUsgNh6BRDT(8iDEHzGHDIsBFmoiyd(a2YI5r4N4EOqBcuyq7ul7OjRp3pyF4xoaf7C2LZpW0ZFHZL)C9o9eentA7JMV(LniZlruLCQsu9thzlOJXrV68oFFLrRZT3lQDWAZfKeWkA6EaWclPRVUu1o06NYiMzuAhy9PVoVLTtTEVL)k354T8D1O3YHhEyLX9BMAO4D3mVLDdTT7IsfqR2)HvgkrjHmz9MzntVe7uY4zWgxsNe0iwRwEOd0xSA(7Sxpqtg8JPsctr8eL3uvVZp4zblu3NT0lPSzjQ2qApZ66tUpW(zMFxeXVx2bQwisN(VitCOBRsHie(8(aJejTTM3nMdF4meJbH6o5A42)4LO(ENOubdXfQmjtD4L(in0hRTFbzJS6IMItv1396K7VrfvdmzGTi5pHW6LQ9LQn3bseB3o7YIbcYnqFEhZ8ctsLxeB)EU3IO9k8lamklt6Cb)git)yAQH)ehfKyen623ao)447nDiaSkKEJyFMHtdCxPCAFAZaLeyzJz5I8kP9zkQaY1zb7BkNtEgrW5f65PXEsJF53A7AF6DvV9Pdx1as8pamkTh6Ch8bTzays2UPswhgKwjZ9vFMzQJSvq14JWXNh6tWt2UtoMMmTi19qlZqO0PvzJNzdQHTRCSQO5Qw1Q94nyYyniFJ2lwNrWF(k2aR9OTOqQAIADgk3tGADg90lZA5RIQZ6x9pFtCjVw5wNvZp7HbZFb7LXp339wRbteGn(Von(TSXX4RBJGX)33y4l()rA8)Z04)xPX)VtJ))Kg))LIqRYYY08)NHxJqR(NNMq1(I4FyZiuUXTi6)CnlIaCuVKd(z2d9DTTh6KNBuTsbJn258KyJThANzO0rQn64P3eSkoDZC76Z0OBxVXWuSJgIaF0Hm4ecnhanaqXZ(ie0XhfWGp3REBG90XAILHRTdBj8)f8LEdzQC(vTLZt2vqj)5919v7B(3gLZ)93aNTDD7HRn1zXaik(9PIcqoSc1JgM0q7aeLx6GfVY6IuNFsrDR5pi9nVC67bYPLQZ)KqZwKV)j6n2qZpDl8pb)pJ6vc(p0Hpj4)5BS3i34yU)fexlW)lHC9Vc(7FnX5b83z77YWDH)3SoFfW)BHEQ)DGtcymX1a8)EeE1BwxbW)r15eW3h)FaH)p60O)CJ2DVDhps0H1crXU)Nyg57cBHWF31BT(WomdpPOUgyCH7KMGLloSINDIbyhU(0Ah2Hz8IUdjYBy6EcztjzfhMOhzonvdr3KjYqr0WGzIoc6IUBQf6792Ct0xRAdjuPC5mA0ED5czN5KJw(edn3WnZE93)sYzvvyRQ0d9Einng6D1SQQfeuNvj5SYWORvQCjznyLAST)kS2(xnK3(6PxoV(d0vFKJb8qp6LE0h9OF6XUOhdW5lGV(GJ94XB36qPhxPayVO9yH117PpuqUrhySrC2h27LU(0IIAbjt(TjhXgAjko6NiH)WN5pE18fuNDaDMVXLz6DdrstAfGczWc2lsK0IK0sYwqvYPJqxT4dUm58kRHcnpvd5G2P3RYAvWwYhsk03ykj5SuSu7lqVeyNwntjttvL4SzOMwwJidzz)03xiw4cCT7NQRTZJP1mLTO601wKwlAWoTvIglweUPcfpvQ4JIF2JYmddCuzrOcYwF4vz)BkvwD3EXZTxrk6YLzNsL1PXEDLNseK84hVYveNhAh)CNFRX9S3qeugEpwO7gV7VtBeyzm)rvhnVGwHEX)L0gtO5vvlsTiAHkGT0vOoSq7s7avsLmhJ9lBqwntWjfGV4LpVfcSGdgt(LRWyrgKCyMtz2JNwxkhSHuiJzCORCnX50KzEWLsUiXyE)ovCMgFrYKNEAVNMibjKd91(1E)wO7X5Gil0EtBHUxPnKRy4qE96hgJ0LFF(Ph7IEmWgmeWcD46r)wOJ4eWBHEFmuUf6HKSqhf(7HB3c9ih0c5gzHEuA)SfQtaXAHGk7Jbxaf6XTq)073cDIDceOf6KoXDwOtzH(aW7(XPLNf6jGoKtJFCl0tEdGEaXRn2H4O759hkwYP7jspcN3g6yHOZHSFlKFhqMFklux704dxBxj9r483vx94DlPz4DdY1za5kD(COXt00k0rZm58NUbP9s1Y0EgzMgL6xaK6Ny(eJCH4stx4Qt2sP(UVTqQ)k1K6b841c9GP)BodPjIEToiYEfvZgL)RvFQeb(wzKpbdiCb(ebecKJF4EBjgyp3cXaEcLhSuPZXsGB7pXHHNNtUqb3HvlwKxrq7bQMCWKjIeoL7rJMmz0yd6Wa2rvvYRsm8mKSPO27RA6dikNxXD)I8MsUtORwuZuB)vV5GQUhhSgt3X7LeCrUnvDpe)StR9q1kEzdbW9iAqc2y5mQOIG7eIMocfsoXzKNrKMyT8foS74XCpAehj1FKG9FX4XI4yQVtgDKiXchXDS4t4CIYdYnyKuUJo6OJflc1QAYWMFFQNrm7O5m04ZkEV3SgsVmy6sPIkjjfgn6UcKHz)dhFbOVe3TUHjpjwcPElf2PJq6SyfeCEKyU)hQ9fajRD5qDj6XX7DfHYk8fLZsNEuWnGqgQ6MyplMxxMfFq3ZcKtjg51jx)CfKlkBEpKPxDeYzsRbM9aVEfZb4ZAQQNHly)rhlzgDEb5sgp)EbhawKxplZGtWrEBeCT1FiybrDtJLYvQqHWY6zbZXQyEp4)hyi)UlCt4bbmSGbRb3CleF08srNEYbh(ApgWYH2msUVniNEbgbp13b2kZD4fZsJ)RcQ5xQw6Gm8r0NQ)GJgCWiRqdUfDztzWE7043SJa4xCjwqJ5Ee184hLJlySbJWwiUxWcLlnHXjVfsIukwizl0vSFml00uqXwnRCjNagdYY(12pNPom0jejcW02pPsLxuruxoBsj1zJRKE16UCzd6)4e5fktxQvk)vm(II755)X4dZrV0oAzoCyB7uDxjmvCFcAiXEsgPiGjv1fjbRcGBetVQUiFHKvkUvCYJSAv9NKBrNjsc0Nnbb0OeI2gsRD)KZfjXERZStgIKjBjdty0FhS)BhvTqhTCwTUZrJ7wvLtyEs36IML0vCFcZl59PDRQ728s(S)V)N(KUHkdCwxpTBG4yt0tzRh6OaM5yCjKNtSqDAROl4Ip20TtuBbQ1sZuPr0C9oQoll0z3ytuSqFqIOUE1szjrVmD9jHH5ANQw0rqU24YbZixq2S8uSrZtreT2swMHS6DpDPlQvAUcteTLQZISHQZGMg(hJ9RtcD54LmPRb1YgfaCvgvWHZI430huA0b8nrr3123I0WiM6HQbzfkZlzs9dM0J9rYqVzzAurGHQ0phlH5yj8MD4fNcrrH0Kt3rzH7UJ5qlsxcmsrUqLIK8IxfoxXOajsjHBPT)k3lvLKHA1Q2qAwcPPLnT0sxVk4TebLdRW(cCE97T7aexR82l9yFu3SyoE5LE0hDQi6MmveD1fy1MNE6Avq1qwjrdgfWQmkaqXkj672o2XFQMpiXc9CnmcHfrzEdSHdr2ky6xOcMMHMPi7LO0Vu620nGV9xC94Bl0pR2XxpSMswnvmYQpkofh)mIkdOQxKbPdMFMSWL9RRF1gH0s1G0dSzqAaUrrZwONh)MwOp(gJHTqa3)NGIyTqxRgA1c9jDIuTqFQkqul0N2c9zifLfcun8ZdfMf6ZcDb)cBhG2VjZIfqZdrlhXsVi97qRJfQ4ccIgMmfHu1FfbmeDoRPxv5MPxOs6C9hV)kQaRuYwOVuDA9SqVm(OwOFnOcTe83x2c9vQOzZcPyHuTqAq6x1crJnilKH5ttkktMwklujl0mqgMD16Se1cvED6zSqZdz7zzQtO9XFuTtVzAoQOXW)nQgJ1nyWzCzDhM2cO7UjdM2mDejNvoNzstD5PfzdO8mxIEc4jvW5KhSL6ig8DpdOEM6wfO)00owl2FqN9rcee8FbnSpQBvzBf0FphCpnf7VSdVT2eK)nnLExbATrpBfC3Ru36B7e8Xwg86HGNf(7xHsSdn)MGfpXgHf5uZxsCkAFdTRHHetvymL5lmW5dpXiTejo07UqI)WkirTdwx07wjaK64PWF1o95XE1kpknC3RloFRS6L1wAV)ahXGzLjkYc9lzH(cwOF5BDwwqLvKd90(oUDfeKwd2t8XpsZGDp5MqbYwmh1CMsI0j7GH(gn38EdorMcM(I2sdlI(Uu0Nf61iCEFvsKWzd1SqFTwJTEPAyRBTOQntf9okQQPwPAH(vz4KmNO0iHVsXtKjF(wItg(ocCczcN31nL(YE2w6lFHVwt1xUIZPv8wTcZnBwcUvQWeA)RdJXqx59m5vfVqMX7ESXAj66C3XGU29MHUuQdDnrND5HfVk(0OXSBL4Y5ZMMnlA19r6Lw7q1)r75qPzvuOJcVd7Y2c9BxxrBH(6WFFJo(GBbS7Z3Ct9wOYCEFle2UtrfUvCV453tZrOHhDSZhE8etMGBIwIqh5DR8FBgiISc(Boks4SnffTuTLj5wn93oYuaTvqsqtTPiP(UQs((liFoDTYTejn6DmiPT2s3odfkzBRufP7lQTVW6QZk4oC1Dzec4AlTYT30s63bMHJCefKvJQ6ny9zpohzRqHNgn1Rd8KWVr5bfZu0Zj7VLGNy3wdE(c1IRF7Dxg6(dYKHsMASy19zbuVGeFXRxl2GCSfjafKf6BHNCvYZp1OrcpuWyrd3YcYc97v)ZgAGib5A4tsOhwOK3ShyvYd08x2M8K6HJhBGXsgPHNPl7VwaYAO206ix84PA4PQ47zZEt2RHCJDf2FIOnTHLiy4OdCHTZJQTVKHhkE8rMkk5lONBSeP2Kh)g1VnhFGMlZr2unChMSvCqcceoDY1D0lqXqxHd6Lv8FBn6v1(6MCQSIwM01irs1WK6ZCAhFLI1h)Wlwnp6SZeVnB1jMXjdtdo65KLXc9nRNIHmlcNCZMivtYA1Mus1KriLnF3kArgiI)ONOLesXF3LDrocY8qH5nm3O4mNzcvvlEwnilYrgJgLLeJAaJFwljGIuYkRK3nPFTzgarmsc8E813zumwze4TA9IhERRx8fyO2nDPIHUGMJDzOXsLhCORmrOzJjQ2s0yI3LzBL9ms9P81Dx(c51JppKd(cfiqF9XbN1tVCDfOl)9Y53RpFDzHEQniO52QHl57ET8AdWvD3)4NyGEU4aL9oAlXvN)ocCLhlu)lnuCUOxmESubhb32Rx9t6iC)KyFteuSXxW9eGUsPQFsh0BbAhKlklqdF7Qrlh9oKy4He69g1)atuEgrDf7VNKdv3dWRjl4EazDX6tFuYwYZtqycRgVF00dQNLxrKsrw)RW5KNv)J4yzOQVfoGUO48ec3u68A1xAjZYBsUGQIRs41943LJ4RZcXD33SbxNfkjlM6iJQhJCy8gdJol0evIGol0K1IDol0fWV3DzHUigKKx6ESqxUtU(TqpnC2ZauOtzHaHopnk4SqzQf(Bo2d9QelvgwiH1h6BODKiFRVjdnzeFxz0z9nj18UnNi7zCgv3E7lqpDXMSHnORSXPzynwOKuPTvzsxhzMMVa91bZ3KPDWhVs5D2fQu6g24UGBXWPQHi9(hrIof79BZ0mcTCIf0h2BQsblnFlx0XVpqOr)2XE5G7yr87PQUvtSKAnHv9Fp4PXxe)tQ6BriIG1rooflhwOUHtKiz1HFeBnnMnmdvVzv4s5Mph9oP(UzNKQTzqNVZbrkVEiIf6)Mn0WZv8CUcNSRmr9EXwcn(VElaA4Ahuo(0FJMkhxSQIQ70fIqdCdfINyudpJ3vHrp)v5APq8p92CH45E9Mpy0Pzf3Plhp3RVXYrFdPYPnC(H7R7KTuo(N9oUC0P27q(90vGwzguRK5P(2BWseu1EXnny6(j3SlrA9oiVTuvFJ8b45qGp5aDn5CbmlMsV1SVRDlvXSf6TAPczl0135uh)mnIgwIOWpyHz5lByJk66xV5OIAEl0suXn8UY2o26R)2j45K5I6x)krhYtzHwcE(ZVfaEoJdWXMbEER1TdJvb80SDGStv)UCjbFb59MfGzH()zdS6V50nl7WDZ35rw)176l9oaCk1jgYpVIx(totGwcN(b)nl4uRTyzdcXhl0V1D62P0qW74aQiiAmAbVdNFOzADqS(xCBU9MBqanBHE1BJLEBZH3bZ3xPGtNHRp(w)LF)dV9wM913GV)I6MJVBJLEBXL(4R)0nFgQDA74SkQNRxJ8JP06j15V828bHJ8Kn3PpNtn7D(cusZCZKOc9px4mgMZNAY5APe9nUfkrjRwahx0bhkfUTJ44Zt)8LKZonvwyuDEY9ERAAYdnsKbs923mLxB3FkHUA2Mnj5FVDKjjFWUYMi0563tSH66gztWG6Eu4cQkIgPR4YD3Ed45MCxq5oT1n(gt1xBUyJPcijog30xnZeNxQvJPAR2MDX6htrxr)pcBX8icvYQW9PX)vSvSJUyDEjqYpP9)HQdGaiFXWbORfxtgb6SejzSxOm7OmQJ5ERBOf1lu)XNigUTR4C7xwxwzArt3K7O1z1KNG85WRMZTPKO7bu1n4NwuHLNA70eruelwUsb48x3lqFQ7G6fffCSDVr)KsyZhN74LCMDwXq2aNB6UvbqtCV7y0e(sfpXBFSeRuJLyMenHJqyNzpKqyG(9nuXjUA3k(2IKe)mKOAAbztXI0TsHp3pI9LUOLg)IApyt2gfIc58KSG61wtm0tt)iARugand5ZyTOJOMYQT33E(CVrTs2QThA9fHvBhLS3r02dVUhl6xC79y)g3qpwZNjW0VDzgW2kGdA7WmsktbFxi6mjelDI(Bjjvh3cv8)(3bmL7H)Wn1uoTd0mcOBCB6sF7MnDq7TvIvpdm656UVINSq(wlwV)BleRKi2(f1T)Hl8iCD5ZxF(WFw2oEUDQPb1vEjFLMAhGU9f4MemCUtwkBwrYVkrKfW)B(oUb5BPrIhIkYwN8Q7C95TR(vhtCOl0s51bU9rEz1wNNjK3U6JUvC4LUvC41l5Z0OThdewD2ThswoovR6Dc7pABvBbJEZ6iDvrUzjT(M)C94VCWwkYpyvZdJ(oOi)p2QT9MUYEEPFp(j7ZL(6Hi791Rh6()AVldgMr2hmi)o(SaFUCIznffy7CEqxWAKnTezfXeSmL(o4TsVDEOYx5BTXud933mbVYmJE1lo4mTeNCOBH4eplzOXRpnD)s7Gmmt1Tj7vP3Q6VIvA7VURP)OoLfQqsnD3bhAWwO2AXxbDf0aDxo2Xp7I2X02cz41R9Zr16)Dk6NiTcTYW2MFVayO(WhcF4Lj)I0bp3uWF2qImhJ8tD7X22WILyBBVK5oa)ShKbpU2Hy78(V2nAP(1C(Zw2YSsMnTiZNg)Bs(XjJ(g(hGOHB2PQSFaZ(f3Yh0OAbK8WBli5A0EXA)iD9Ji7o8eekdwuBxvMWKq2X21T7IbqOtjWKOfPIrdzbrR22923Pfh0tltl)HO)8rEw8BWfUGiVcmmG9ER8dFMJTkdIHdGZJH41V8yrFIAx9ejP4w6JvlsBB7bGrBi6ok)BzVNNluCW5VWefnZFIZdJWSF)YccIkCXImEeo8RyH(E1TR9)vB4xFV1)bQ0wVKrAFr6puHKpYMok2Hqhcx7HRB)t)k4ESq3n97N4hz1MlcdH9MDozJo)7SNBZ)Ti6UBCVn)8x8IxisyT5M3WFt2BZ7WGZ)PdCApDmZD9r))d
```
