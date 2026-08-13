# Mage — Arcane & Frost HUD (v5)

Programmatically generated WeakAuras pack for TBC Anniversary (WeakAuras internalVersion
45, tocversion 20501). One import covers raid Arcane (40/0/21) and raid Frost (10/0/51):
spec-specific pieces load themselves through Spell Known checks, so the HUD auto-adapts on
respec with zero user action. Since v4 the same import also carries a PvP layer that only
exists inside arenas and battlegrounds — in PvE nothing about the pack changed, and v5 keeps
that promise (the one element it takes away, it takes away *only* inside an arena).
Spell IDs only — aura triggers carry every rank ID as
strings and cooldown triggers carry the numeric rank-1 ID, so the pack is safe on zhCN and
any other localized client. There is no custom code anywhere, so the import dialog shows no
code-review panel. Import `all-specs.txt` (or the fenced block at the bottom of this file)
whole: copy all → `/wa` → Import → paste. Heads-up: the `/wa` editor preview force-shows
every aura at once with placeholder data (load gates ignored, identical fake "55.1"
timers, both specs' icons visible together) — judge the pack in combat, not in the preview.

## v5 — no threat bar in arena, and their mana on screen

v5 is an in-place update of v4 (same UIDs — the import dialog offers **Update**, not a
duplicate group). It **adds one aura and changes the load gate on two**; nothing else in the
pack moved. All three changes come from closing questions v4 had shipped as open.

- **The threat bar and the threat flash no longer load inside an arena.** An arena team has
  no threat table, so both were painting a meaningless number in the one place where you have
  the least attention to spare — and the flash *pulses*, which is worse than useless there.
  The party/raid gate they already had could not express this by itself, because an arena team
  **is** a party. They now also carry an instance-size gate that lists every instance type
  except arena: open world, 5-man dungeon, 10/20/25/40-man raid, and battleground.
  **Nothing changes anywhere else — including the open world.** That was exactly the doubt
  that kept this out of v4: WeakAuras only assigns the instance-size value inside a check for
  "am I in an instance", so it looked as though the value might be nothing at all while you
  are questing and the gate might match nothing and silently unload the bars everywhere
  outdoors. It does not — that check is a guard, and the function's last line returns the
  literal `none` for the not-in-an-instance case, which is one of the types the gate lists.
  Battlegrounds deliberately **keep** both: Alterac Valley has real NPCs with a real threat
  table, and the bar is honest furniture there.
- **Enemy Mana — one bar per opponent, arena only.** A mage does not drain mana, but a mage
  plays the mana clock harder than almost anyone: Counterspell exists to stop a healer
  spending it, Polymorph exists to stop them drinking it back, and "keep applying pressure or
  commit the burst now" is a read on how much the enemy healer has left. The new bar sits at
  the bottom of the PvP column, one row per opponent, with their name on the left and the
  percentage on the right. It turns **amber below 30%** (they are running low — deny the
  drink, keep them casting) and **green below 10%** (they are out; this is the kill window),
  matching the escalation language the health bar already uses.
  Two honest limits. Rows only appear for opponents whose *primary* resource is mana, which
  is what keeps warriors and rogues (who have no mana pool at all on 2.4.3, and would
  therefore show a permanently empty bar that reads as "go") off the list — the cost is that a
  druid in bear or cat form drops off the list until they shift back. And while the WeakAuras
  side of this is proven (the Power trigger accepts `arena`, registers per-opponent events and
  clones one row per opponent on TBC), whether the 2.5.x server pushes *continuous* power
  updates for arena opponents rather than refreshing on opponent changes is a client question
  no addon source can settle. Take it into one skirmish before a kill call depends on the
  exact number; the readout refreshes on opponent-frame updates at minimum.
- **CC ON ME's colour-coding is now confirmed rather than assumed.** No change to the pack —
  it works, and it was worth proving, because the mechanism has a silent failure mode one step
  away. Recolouring a glow from a condition only reaches the screen if the glow was built with
  a custom colour in the first place; without that flag the recolour is stored and quietly
  discarded, and the prompt would have glowed one single colour for every kind of crowd
  control while looking completely correct in the editor. This pack builds that glow with an
  explicit colour, so all nine categories are live.

## v4 — PvP layer

v4 is an in-place update of v3 (same UIDs — the import dialog offers **Update**, not a
duplicate group). It **adds nine auras and changes none of the 31 that were already there**.

**Nothing changes in PvE.** Every one of the nine new elements carries its own Instance Size
Type load gate — arena + battleground for most of them, arena alone for the three that read
`arena1..arena5`, since those unit ids do not exist in a battleground. In a raid, a dungeon,
or the open world not one of them loads, and no existing element was touched: the raid HUD
is byte-for-byte the v3 HUD. The gate is per aura, not on the group, which is also what lets
the dynamic groups collapse the gaps.

Walk into an arena or a battleground and a second HUD appears:

**Three new prompts join the Alerts flow** (same language as the rest of the pack: they slide
in from below, glow, and fly away when they resolve).

- **COUNTERSPELL NOW** — appears only when your target is casting **and** Counterspell is
  actually castable **and** the target is hostile. It is the highest-value press a mage owns:
  8 seconds of school lockout on a 24 second cooldown, and a healer locked out of Holy for 8
  seconds is a kill window with no CC spent at all. Because the prompt cannot exist while
  Counterspell is down, it never trains you to ignore it — if it is on screen, press it. The
  icon desaturates while the target is outside the 30 yard range, which is your cue to close
  distance instead. There is deliberately **no spell filter**: TBC has no notion of
  "interruptible" that WeakAuras can read (WeakAuras disables that filter on TBC clients
  outright), so judging fake casts stays a player skill. Loads once Counterspell is trained.
- **CC ON ME** — one prompt for every loss-of-control effect, colour-coded by *category* with
  the remaining time under it, because the decision is never "am I CC'd", it is *which break
  works*: red stun (trinket, nothing else), purple fear (trinket), blue root (**Blink** — Blink
  breaks roots and never breaks stuns, so this colour is the difference between escaping and
  wasting your medallion), green polymorph (ride it out, any damage breaks it), amber
  silence / school lockout (your Frost school is locked, so Ice Block, Frost Nova and Ice
  Barrier are all gone — trinket earlier than you otherwise would). Not combat-gated: the
  opener lands before combat starts. This is also the only way to see a school lockout at
  all, since a lockout is not a debuff and no aura trigger can ever find one.
- **TARGET IMMUNE** — fires when your target gains an effect that makes your whole spellbook
  do nothing: Ice Block, Divine Shield, Cloak of Shadows (90% spell resist), Spell Reflection
  (your next cast comes back at you), Bestial Wrath / The Beast Within (uncontrollable, so
  Polymorph and Nova are wasted as well). Stop casting, re-pool, or swap. Two immunities from
  the generic list are **left out on purpose**: Blessing of Protection is physical-only
  (Frostbolt lands straight through it) and Deterrence is dodge/parry, so neither changes a
  single mage decision, and a prompt that fires when nothing is decidable is noise.

**A new "Mage - PvP" column** of state read-outs appears opposite the Alerts flow (it grows
downward on the right of the character, mirroring the alerts on the left).

- **Trinket DOWN** — visible *only while your medallion is on cooldown*, desaturated with the
  swipe running. Absence means ready, so in the normal case the column is empty and the
  question "do I still have my get-out-of-jail" is answered without reading anything. Tracked
  by exact item id (Medallion of the Alliance/Horde, plus the Mage Insignias) rather than by
  equipment slot, because a slot tracker would report "medallion down" whenever any *other*
  on-use trinket was fired — a false negative that gets you killed in the one decision this
  element exists for.
- **Will of the Forsaken DOWN** — same idea, and it only loads if you actually know the racial.
  On 2.4.3 WotF does **not** share a cooldown with the medallion (that arrived in 3.3), so an
  Undead mage really does carry two charges, and whether the second one is up is what decides
  whether the first gets spent early.
- **Enemy Trinket** — a 2 minute countdown per opponent, started when that opponent's trinket
  cast is seen (one row per arena opponent, arena only). Their trinket being down is what
  makes the next full Polymorph chain uncontested; a one-shot "they trinketed!" flash without
  the countdown would change nothing. **This is an inference, not a read** — no 2.5.x API
  exposes another player's cooldowns, so if an opponent trinkets out of sight nothing starts,
  and the timer assumes the 2 minute honor medallion.
- **CS LOCKOUT** — an 8 second bar that starts when *your* Counterspell lands (your interrupt
  only; a partner's does not light it). That bar is the go: burn Icy Veins, Water Elemental
  and Arcane Power now, and do not spend Polymorph on a healer who cannot cast anyway.
- **Polymorph OUT** — your own sheep on each arena opponent, with the remaining time, one row
  per target. It says two things at once: *do not touch that unit* (any damage breaks it and
  the sheep regenerates roughly 6% health per second, so hitting it hands the healer free
  health) and *this is exactly how long the rest of the team has to work*. It glows in the
  last 3 seconds — re-poly now, or the healer is free. `ownOnly`, so another mage's sheep
  never appears here.

### This is NOT diminishing-returns tracking

The Polymorph row is a plain remaining-duration timer on your own sheep and nothing more. It
does **not** know that Polymorph shares the Incapacitate category with Sap, Gouge, Freezing
Trap, Wyvern Sting and Repentance, it does not know whether the next one lands at 100%, 50%
or 25%, and it does not know about anyone else's CC. Real DR tracking needs a custom trigger
maintaining its own category→timer table (which is what Gladius and Diminish exist for);
WeakAuras ships no DR prototype and no DR library, and this pack contains no custom code at
all. Faking it with an 18 second timer would model the *reset window* rather than the
category state — wrong the moment two spells share a category, and worse than having nothing,
because an incomplete DR tracker gets trusted.

Three more things were considered and deliberately left out for the same reason:

- **Enemy cooldowns** cannot be read on 2.5.x at all. The enemy-trinket countdown above is the
  only honest form: a timer you start because you saw the cast.
- **Enemy spec detection** does not exist on TBC either (enemy *class* is readable, spec is
  not), so nothing here branches on what the other team is playing.
- **The threat bar and threat flash still load in arena** — *fixed in v5*, once the open-world
  behaviour of the instance-size gate was confirmed from the source rather than guessed at.
  See the v5 section above.

**One thing to smoke-test before you rely on it.** The CC ON ME prompt is driven by
WeakAuras' *Crowd Controlled* trigger, which reads the client's loss-of-control API. That
trigger was unavailable on Classic/BCC in WeakAuras 3.5.0–5.1.x and was re-enabled in 5.2.0,
but nothing in the WeakAuras source proves the 2.5.x client actually populates the API. Get
sapped and get kicked in a duel and confirm the prompt fires. If it does not, the failure is
silent and harmless — the prompt simply never appears, nothing else is affected. No aura-based
fallback is shipped alongside it, because two prompts for one event is worse than one that
might be quiet, and an aura-based fallback could never see school lockouts anyway.

Every new game id was verified on wowhead.com/tbc for this build: Counterspell 2139 (8 s
lockout, 24 s cooldown), Will of the Forsaken 7744 (2 min), the "PvP Trinket" cast 42292
(120 s, cast by both medallions), items 37864 / 37865 (Medallion of the Alliance / Horde,
2 min) and 18859 / 18850 (Insignia of the Alliance / Horde, **Mage**, 5 min), Polymorph
118 / 12824 / 12825 / 12826 plus Turtle 28271 and Pig 28272, and the immunity list 45438,
642, 1020, 31224, 23920, 19574, 34471. Aura triggers carry every rank as strings; the
cooldown, Spell Known and Action Usable triggers carry the numeric rank-1 id; item triggers
carry the numeric item id, never a name.

## v3 — per-spec audit: each spec sees only what it presses

v3 is an in-place update of v2 (same UIDs — the import dialog offers **Update**, not a
duplicate group) and adds, removes and moves **nothing**: it only changes which spec loads
what. The test was tightened from "can this spec *cast* it" to "does this spec *press* it as
part of playing well", which is the question the HUD actually answers. Three elements failed
it somewhere:

- **Frost no longer sees the mana conserve breakpoint** (the amber line and its lit crossing
  marker are now gated on Arcane Power, 12042). The line marks where Arcane stops spamming
  Arcane Blast and starts the 3x Arcane Blast / 3x Frostbolt conserve cycle — it is a switch
  between two rotations. Frost has no second rotation to switch into; it is Frostbolt spam all
  the way down, with Ice Lance while moving. Its actual low-mana actions are Evocation and the
  mana gem, and both already have their own prompts carrying their own thresholds, so for
  Frost the line marked a mana level nothing was done about — and the lit marker put motion on
  the HUD for a non-decision.
- **Arcane no longer sees the Ice Lance / SHATTER prompt** (inverse gate: `not_spellknown` =
  Arcane Power 12042, the 31-point Arcane capstone and therefore a true spec discriminator —
  no deep-Frost build can reach it). Ice Lance is *trained* at 66 by every mage, so gating on
  Ice Lance's own id hid the prompt while levelling but not from the wrong spec: 40/0/21
  Arcane loaded a reactive prompt it never acts on. Arcane's rotation is Arcane Blast with
  Frostbolt as the mana filler, and the Arcane guides state outright that the spec uses
  neither Ice Lance nor Frost Nova/shatter combos; it also has neither Frostbite nor the Water
  Elemental, so two of the three ways the freeze window opens do not exist for it. Frost keeps
  the prompt — Ice Lance into a frozen target is its one reactive button outside a raid.
- **The Evocation prompt is Spell Known gated** (12051), like its cooldown icon already was.
  A cooldown trigger on a spell you have not trained reports "ready", so below level 20 the
  prompt fired for a button that does not exist. Neither spec at 70 is affected.

**Requires WeakAuras 5.4.0+ for the inverse gate.** The `not_spellknown` load argument does
not exist before that release; on an older client the unknown field is ignored and the SHATTER
prompt simply loads for everyone, exactly as it did in v2, so the pack degrades gracefully
instead of erroring.

Everything else survived the audit unchanged, and deliberately so:

- **Both specs press Icy Veins and Cold Snap.** The Arcane raid build is 40/0/21 — "Arcane
  IV" — and spends its 21 Frost points precisely on Icy Veins plus Cold Snap, so it can use
  Icy Veins twice per burn. Cold Snap's *glow* is still the Frost sequencing cue (both Icy
  Veins and Summon Water Elemental spent); for Arcane the icon is availability only, since
  the mage never has a Water Elemental to bank. That is a condition, not a gate, so it is
  left for a future version rather than smuggled into a gating pass.
- **Clearcasting stays ungated**: the standard Frost raid build is an Arcane Concentration
  build, exactly like Arcane's, so the free-cast proc is a real decision for both.
- **Ice Block, Counterspell, Blink and Invisibility stay** for whoever has them. They are
  emergency and utility buttons both specs press under pressure, and each is gated on its
  own id, so a build that lacks the talent never sees it — no spec gate needed.
- **The mana gem prompt stays ungated**: both specs gem in their regen phase, and the Item
  Count trigger already hides it from anyone without a gem in their bags.

## v2 — rotation fixes

v2 is an in-place update of v1 (same UIDs, so the import dialog offers **Update**, not a
duplicate group). A rotation review found the pack rendered state faithfully but left
several real decisions unrendered, and let three elements fire when nothing was decidable.
What changed:

- **Mana now shows the burn/conserve breakpoint.** v1's mana bar was a bare percentage with
  no threshold — the single most important Arcane decision ("keep spamming Arcane Blast, or
  drop to the 3x Arcane Blast / 3x Frostbolt conserve cycle?") had no element at all. A thin
  amber line now sits at 30% of max mana with a brighter line that pops in the moment you
  cross it (in combat only — drinking afterwards is not a decision). 30% is a percentage
  proxy for Icy Veins' "1500-3000 mana is usually a good time to start this rotation": raw
  mana moves with gear, the fraction of your pool does not.
- **The burn windows have a clock.** A cooldown trigger reports Arcane Power's and Icy
  Veins' 3-minute recharge, never the 15 s / 20 s window they actually buy you, so v1 could
  not tell you whether you were still inside one. Two new 34x34 buff timers flank the shared
  buff slot: Arcane Power (12042) on the left, Icy Veins (12472) on the right. Arcane Power
  glows in its last 5 seconds — that is the Presence of Mind + Arcane Blast finisher cue.
- **Mana gem prompt.** Mana Emerald (item 22044, ~2400 mana, 2 min) was tracked nowhere. It
  now prompts in the alert flow below 70% mana — low enough that the restore is never
  wasted — and only when a gem is actually in your bags, so a mage who forgot to conjure is
  not nagged about a button they do not have.
- **Ice Lance / Shatter window.** Ice Lance (30455) does triple damage into a frozen target
  and v1 had no frozen-target detection at all, which left deep Frost with no reactive
  decision outside a raid. A new prompt fires when your target is held by Frost Nova (all
  five ranks), Frostbite (12494) or the Water Elemental's Freeze (33395) **and** Ice Lance
  is castable. Deliberately not `ownOnly`: your pet's Freeze and a partner's Nova open the
  same window. Bosses are root-immune, so the prompt stays silent in raid.
- **Cold Snap is a sequencing prompt, not a use-on-cooldown icon.** Cold Snap resets the
  Frost cooldowns, so pressing it while Icy Veins or Water Elemental are still up throws the
  reset away. The icon still shows its own 8-minute cooldown, but it only glows once both
  Icy Veins **and** Summon Water Elemental are on cooldown and Cold Snap itself is up.
- **Three cooldowns glow when they are up, in combat.** Arcane Power, Icy Veins and Summon
  Water Elemental are press-on-cooldown, so they now glow gold the moment they come back —
  gated to combat so the row is still while you are riding to the next pull. The reactive
  cooldowns (Ice Block, Counterspell, Invisibility, Evocation, Presence of Mind) do not
  glow; their prompts live in the alert flow instead.
- **Threat bar is party/raid only.** v1 gated the flash overlay and the Invisibility prompt
  on `ingroup` but not the bar itself, so solo — where you are always the aggro target — it
  sat pinned red for every quest mob and trained you to ignore it.
- **Clearcasting is combat-gated**, like the four other alerts. An Arcane Concentration proc
  from a pre-pull cast is not a decision.
- **Ice Barrier warns before it drops.** The timer glows in its last 5 seconds. The MISSING
  alert can only fire once the shield is already gone, which conceded an unshielded gap on
  every fight; a 60 s shield on a 30 s recast should be refreshed pre-emptively.
- **Health bar has colour tiers** (orange under 50%, red under 30%), completing the danger
  pattern whose action half — the Ice Block prompt at 30% — was already there.
- **Every cooldown icon is now Spell Known gated.** v1 left Evocation, Counterspell and
  Blink permanently lit for mages below level 20/24/32.

## Layout

**Resources** (three 172x14 bars stacked flush below the character). Health on top, mana
under it, threat at the bottom, each with a floored percentage readout on the right edge.
Health runs green, turns orange below 50% and red below 30%, where the Ice Block prompt
fires. Mana is the mage's real clock — Arcane plans its mana to hit zero as the boss dies —
and carries the conserve breakpoint line at 30% described above. The threat bar is party/raid
only, never loads in an arena (v5), and only appears when you have a hostile target: it runs
green, turns orange at 70%
threat and red the moment you pull aggro, and a pulsing red overlay flashes across it above
80% threat — mage burst has no passive threat dump, so the bar is the warning system. Health,
mana and the conserve line fade to 50% alpha out of combat so the HUD breathes with the fight,
and the lit crossing marker is combat-only. Since v3 the conserve line and its lit marker load
for Arcane only: they mark a rotation switch that Frost does not have.

**Buffs** (static timer row under the bars). Arcane and Frost are mutually exclusive at 70,
so both 40x40 centre icons share the one slot. Arcane Blast stacks (self-aura 36032, 8 s
window) shows the stack count large in the center and the remaining window at the bottom, and
glows purple at 3 stacks — the cap is the decision point: keep spamming Arcane Blast only
while Arcane Power / Presence of Mind / Icy Veins are burning, otherwise fall back to filler
until the stack aura drops and rebuild. Ice Barrier (all six ranks) shows its remaining uptime
for Frost and glows in its last 5 seconds so the reshield lands before the shield lapses;
pushback protection is completed Frostbolt casts, so the timer is a rotation element, not
decoration. The two 34x34 burn-window timers flank that slot: Arcane Power left, Icy Veins
right, each appearing only while the buff is actually running.

**Alerts** (glowing 40x40 prompts in an upward flow left of the character). Each slides in
from below and flies away upward when it resolves, and the stack collapses gaps
automatically. Clearcasting (12536) fires on the Arcane Concentration proc in combat — the
next spell is free, weave it immediately. The Evocation prompt fires when mana drops below
30% **and** Evocation is off cooldown, once you have trained it. Barrier MISSING fires when Ice Barrier is absent
**and** its 30 s recast is ready, so it stays quiet during the cooldown instead of nagging.
The Ice Block prompt fires below 30% health **and** only when Ice Block is ready. The
Invisibility prompt fires at 70%+ threat **and** only when Invisibility is ready, in a party
or raid. The mana gem prompt fires below 70% mana **and** only with a Mana Emerald off
cooldown in your bags. The SHATTER prompt fires when your target is frozen **and** Ice Lance
is castable, with the freeze window running as the icon's swipe and bottom timer — for every
build except deep Arcane, which does not use Ice Lance. Every
prompt requires all of its conditions at once (`disjunctive = "all"`), so an alert appearing
always means the button is pressable right now, and all six of these are combat-gated. Three
more prompts share the flow in arenas and battlegrounds only — COUNTERSPELL NOW, CC ON ME and
TARGET IMMUNE (v4) — and none of them ever loads in PvE.

**Cooldowns** (auto-collapsing horizontal row of 32x32 icons below the character). Cooldown
text on, mouseover tooltips on, and each icon desaturates while its spell is down. Every icon
is Spell Known gated so only spells you have taken (and trained) take a slot and the row
stays tight: Arcane Power (12042) and Presence of Mind (12043) for Arcane; Icy Veins (12472),
which both the 40/0/21 Arcane build and Frost talent into; Summon Water Elemental (31687),
Cold Snap (11958) and Ice Block (45438) for Frost; Evocation (12051), Counterspell (2139),
Blink (1953) and Invisibility (66) once trained. Arcane Power, Icy Veins and Water Elemental
glow gold when they are up in combat; Cold Snap glows only when both of the cooldowns it
resets have been spent.

**PvP column** (v4, arena and battleground only — invisible everywhere else). A dynamic group
at +150, mirroring the Alerts column on the other side of the character and growing downward:
Trinket DOWN and Will of the Forsaken DOWN (32x32, desaturated, present only while the charge
is spent), the Enemy Trinket countdowns (32x32, one clone per opponent, arena only), the
140x12 CS LOCKOUT bar, the Polymorph OUT rows (36x36, one clone per opponent, arena only), and
since v5 the 140x12 Enemy Mana bars (one row per mana-using opponent, arena only, name on the
left and percentage on the right, amber below 30% and green below 10%).
It is a dynamic group because three of its children are clone sources; clones inside a static
group would stack on one spot. In the quiet case — trinket up, nobody sheeped, nothing
interrupted — the column holds only the opponents' mana.

## Spec gating summary

| Element | Gate |
|---|---|
| Arcane Blast Stacks icon, Arcane Power CD, Arcane Power window | Spell Known 12042 (Arcane Power) |
| Mana conserve line + lit crossing marker | Spell Known 12042 — **Arcane only** (v3) |
| Presence of Mind CD | Spell Known 12043 |
| Icy Veins CD + Icy Veins window | Spell Known 12472 (loads for deep Arcane *and* Frost) |
| Summon Water Elemental CD | Spell Known 31687 |
| Cold Snap CD | Spell Known 11958 (both raid builds take it) |
| Ice Block CD + Ice Block prompt | Spell Known 45438 |
| Ice Barrier timer + Barrier MISSING alert | Spell Known 11426 (rank 1) |
| Ice Lance SHATTER prompt | Spell Known 30455 (learned at 66) **and NOT** 12042 — hidden from Arcane (v3) |
| Evocation CD **and Evocation prompt** (v3), Counterspell CD, Blink CD, Invisibility CD | Spell Known 12051 / 2139 / 1953 / 66 |
| Invisibility prompt | Spell Known 66 **and** party/raid only (`ingroup`) |
| Threat bar, Threat Flash | party/raid (`ingroup`) **and** every instance type **except arena** (`size`, v5) |
| All six PvE alert prompts | in combat only |
| CC ON ME, TARGET IMMUNE, Trinket DOWN, CS LOCKOUT (v4) | arena **or** battleground (`size`) |
| COUNTERSPELL NOW, CS LOCKOUT (v4) | arena/battleground **and** Spell Known 2139 |
| Will of the Forsaken DOWN (v4) | arena/battleground **and** Spell Known 7744 (Undead) |
| Enemy Trinket, Polymorph OUT (v4), Enemy Mana (v5) | **arena only** — they read `arena1..arena5` |
| Everything | class MAGE |

Only six elements carry no *spec* gate after v3 — the health, mana and threat bars, the threat
flash, Clearcasting and the mana gem prompt — and every one of them is a decision both Arcane
and Frost make (the threat bar and flash do carry a group gate, and since v5 an instance-size
gate as well; neither is a spec gate).
`tools/spec-preview.lua` models Spell Known gates only, so from v4 it lists the
PvP elements under "ungated" or under their spell gate; read that list together with the
table above, because every one of them also carries the instance-size gate and none of them
loads in PvE. The inverse gate (`use_not_spellknown` / `not_spellknown`, WA 5.4.0+) is used
once, on the SHATTER prompt; `use_exact_not_spellknown` is deliberately left unset so the
rank-1 id resolves through the spell name to whatever rank the player has. Audit any future
change with `lua5.1 tools/spec-preview.lua mage`, which decodes the shipped string and prints
each spec's loaded set.

Two IDs are worth calling out because TBC reshuffled them relative to the classic era:
**Cold Snap = 11958** (8 min CD) and **Ice Block = 45438** (5 min CD, Frost talent). Every
spell ID in the pack — the twenty-six of the PvE layer (17 distinct spells: Ice Barrier
contributes six ranks and Frost Nova five) and the seventeen added by the v4 PvP layer — plus
all five item IDs (**Mana Emerald 22044**, medallions **37864**/**37865**, mage insignias
**18859**/**18850**) were verified on wowhead.com/tbc before this build. **v5 adds no new game
IDs at all** — its one new element reads a resource, not a spell. The item triggers
(item cooldown + item count) and the PvP layer's Cast, Action Usable, Crowd Controlled, Spell
Cast Succeeded and Unit Characteristics triggers are the only ones in the pack not built by
the shared factory; their field names come straight from the matching WeakAuras prototypes,
and the item ones take the numeric item ID, never a name.

## Regenerate

`lua5.1 tbc/mage/generate.lua` from the repository root (run
`tools/tbc-weakaura-creator/scripts/setup.sh` once beforehand to fetch LibDeflate and
LibSerialize). The script is fully deterministic — fixed UID seed 20260816, no time or
environment inputs — so rebuilding produces a byte-identical `all-specs.txt`
(sha256 `6993e1e570e7823624d1f1b07db58235bf79effe8df7db96598ee44d5803640c`, 8926 chars,
42 auras). It round-trip verifies the encoded string and checks UID continuity against the
committed `all-specs.txt` **before** overwriting it; `changed` must stay 0 so in-game
re-imports offer *Update* instead of duplicating the group. v2 added six auras and changed
none of the 25 v1 UIDs (`stable=25 changed=0`); v3 added none and changed none of the 31
(`stable=31 changed=0 parentSame=true`) — it edits load conditions only; v4 added nine and
changed none of the 31 (`stable=31 changed=0 parentSame=true`); v5 added one and changed none
of the 40 (`stable=40 changed=0 parentSame=true`) — its other two edits are load gates, which
move no UID. Future versions must keep the
seed, never reorder existing `W.uid()` calls, and append new auras at the end of the
creation order. One import-time note for users: the Update dialog's *Arrangement* category
is checked by default and will reset any positions dragged in game back to the string's
defaults — uncheck it, or report the coordinates so they can be baked into the script.

## Import string (v5)

```
!WA:2!DZ1EWTXX5DFgw12q2jsupSLILnSSLIORTmEqWhksjbaeqesGaqhajLKvmXbGLaN4H7oD3bsbMMKgwRu13jmooXPPjoW1oTojDQz946K28hLnnPpY4(v2zCU02)PQTzCM2M0Q(iTDAM29XD4fbaPOOIK8mshpS3U7T7(977333(T7TCJ3tUNR3l(alNvi3051uudPiPODmhoCK0H7d6xTNCkYgAkssO8HkkkLxdjF2LhvOaY1J5AeKGKrXfT(1OcYc2pjDrnKGH62A6NUIijOxuDxnKFxHuK1rAZGCftugPEVD4rgxkRIwEKwqR2O6wckjo3CcA5DLwrrYquv78jMAkDKbxwvbCt0W6TKoyiC1fqlNGmY1(Dfrtr3ilRUkQvHvKZvvdvquroDfveFbnLYQvz5iL4COnTOO8ukALemW5W5IShWgI444CSSqzJIkAjujpw3zw8G1uIfCQjKJMq)86gcAgoZoLOSOErNbX)XW58gAIfkG00JVFnRBFMGgK3UqznbVlrUQRIKKeZRV7EChSmUqzvLeQG0MNME086oVKE5SOzW90uLNAkXZV4KHcKk9KPshGpDThLudHFeFQKHJf7YL1rHppUDLIvdz4LfkH0DwnpklUgiDETrchlzKXITqzzRMLZfZlQF2YY4EZmiVcssQBvGEFA2Zhvjp6lDlwdxHZxaPU1uNRmwa4kszjjxtuu0aTe7PSX67Cbbzr2Gz)W9gzjKGokLbwGvWO4Td7jOSImA584(pjhtsgt00r4b186ZtYkPvc9fSKGOCeWhUaqFGFOFya8F3vRPSGosAQKkIYgzdfoE6W87vmV6wSqy8iDLYA5q6xg)CKMSG044xf(L(eloLgEGb3OemeCCzb5Cy5BessKxE2uH4dhoEvdLCZWY)DKChEllMFXduW)5MZ4KQPdoeVEobjKJQyXapfzPBdCIIr0goQs6qImetqjfH8oxK9AOnw4qx0DvDmkE6jeZBuChvfXzpfTXEF3cSzo4T)3ClWiWHwMMhEfd6yfN6wB63ejtWaJLorqsXlcVJNC)W99m4HhxWdbpmpfEKLP)It6bH96CEmazsculdSpy)WbCc9cpc8t6SXYbju3(y4S4kurbcghPjQBiMt3QkGt0szHhfEm4GyecPrmzoBMfhWHFcyi4qZNvWsxk5T5(GE8tUoWGKRE97adm1fmiqbuXLO9nge6uCWWhANWEwKOMGRGjX))I7uThd05nMuVOqELzpPfxWc00ixu3Y(WqPC4oDrAFEF7tDlnuG6k0xILQnYbgvDB0uW65keCBoQqjya8pVm9byfmuEAIF4LzsXtz92xI(8Zwgpcnvf4qv1iIguACIbJNiEyypAyacjpvPzS(OdRzpfM3vDlr0eNZ1jklKNahDLoTQ7A9Pjz8st2uhBY8OCyfmPjv1W3Otrgno0y34wMM2Syu5eAcQZpH1nlx7vtjesmw6yrJh2ASQbq6IrJhpm)K8rp6iPv7DvAsykv58uLz(PKuu0ydmZGBDzLqzQ)kj8T7YAq0weQUVvPYzjMnE5szXglG9SaEqLPSTm7pwnBVyyIDkkwciRFMRU03kf72MLA7Kim1g42(x642PJSfrIfkASh4OJVarZjh22MEMSgynFzJDYxQm2QKtEAQ7pRUOCbjuWrdC0WW87eUqMGyE8C7eM3zqsLrU5suiEqCPZt0D9gy4Hv3cUIdKNGGq5r5hv48fH7cExmYHq1vM2HZwZPiwJFlAwkiWoD2O(Zj5wGQnQlMhXtfGGxcxCR8PdU6mSW9GlOtyxoHD7Cr6Rye6GYr0iYRYAi(qsibzEbj1IcoynI0SNOEGOeE3PeYHotibSkICHGcANzSOpw9F9yPOmA0IveEVyMwmdo4i4CkkL4GJ4GFwIA3x3j8UH3deyruHZNnwI(detFunrzc9mQOvRsmFEKmF8WJhMFrfnrSeIsswDKe8rpDI4PdedICO9ZNRik30rG7BtZpJGMOagbmVOCiLszfm4NrqQmIBVkQ79ihrlxrb5ci9DVF45PEjnVk2PeKMrf4P3p8C4AWb85xUjCk8871VBCP75WWVoPyhJ6Ev)KlECaVaKUw5GxeNxFnLxsUgIsr6LDLwcyBoVmXPTcu9RAuyKmpWfDdr3bCmldg)(CedgWX5GyWOqClRbVADwD(KkZI0iS4lOsUJORY1eH(YemETNLPT2ga(vZoaKQr6Fi9XyC90XqYTd53bmwryClkEyIlUt4KCWPUSn7nTfSV9bpbvDfodU78(GNeM8ddz4abCvMfYHlxEaXErtbfaro1d0jseA91abfCo4SW0GeucKbfqlJ6d39IYsdMb03fGzRE8UN7vsoJzSGzHZdvG54G3pRx9tLb(aGB4d6a(qe6f4Nod8HjueWpZ(HNcUaJbb(i0K(zPxVi8Zb)8uYb4xWMta(fXCaWVew7h(L5GFf4JUHOMdFSJalaFC4PDaFc4zGpzD9YBd(ueLs4zRPqgn4PD3BVdnWXgih8Rwe(mWVg8zHphez3mS(MWy9QWZBPtXG6uKagC)0yWn8f6aC(ZCRTcNJ3iqSQbD2ge)uW0XAfqgyG4Li436pidbLMqDlwtmjLOrzkJaf2UMXSdsU4R9q2L2h7TPMZOgEv9rxb8OwMAd2O9WB1hSlvsn44k0bAex3gJQ1RIMugOOASAWQdt)iyy6IKbzm3nzouzO(tsSUvKHE1SEa((9dBntqnbX8z6eKEgEmVTrLmEvNbxt42OrLscYz8AGKZu1ywScvLPWtdbBVLEFgOVm3qOeSPvOeeQuWjg6edpxIOrAsj4rQr4VqTXEmX)aeI)9(UpYQzLGxOaE0eEEhnQ90zdfnQl5ImeDzll0eN(i(BOU9qXcmAs88fIfi0XXoFenD0XdZ0S(g2Awlxxjc3AZa)2Wlt44xmd8hU3bDJvPWUAwdhrmikyOOr6mjGFN2PzTnSdsm3yO9q2fC7Eq)yrx2sIAAkAfP67BbpEVtNlK129iSOoIZoilNc2twSse2vh6VXp(BvL6bsYYs6O5TNDzpEOfzfcA1TINZBonKbAsn7jx1KWFb1dv33La5ZNqw)mtGeMoazA7NzuuErHZy5LJ(zythEs6mHpOrbbksHWLGbjy6ecM5NGqQ90ewK5R)cdSOWXNkz4iktm1eLOqjcL3hAFzzZIOitHdETmWxXs)c(QV5Z2w1P38Zbp7TTzMyh(JGVXkS(d)gu72)MnBXhEP1TvEmE7pbltjZMJYtsbJ(jcv4pTi1DeM8e(Z4dglC8HxJMew3QU)5TiabOnIHBh28HVvMCa(licGjCp1ijpU)H6F0XQlaEq4Vep2pdESNArHgoMPLvMv22g9hzfwQRwpt3XJBBX(z3uJceIw231EiwDhn5Zqn9OdFKLA8byFeTfDu3)BYtJmDwA2zPKJ2iGQROHvRGVfmGgjomjkBq1RYQxetRpn86bjMePJ3TrEyvslDXGtjG1FFDV4sqZYAs4ChTkCMz04JEYHlhB4zc1G2bv4qvmEdB4pvQuLodnQJ8TyY5B3Gi5oV4daC1I8jCRhtD3wrlYkaIbXZMd7SGb2PBD1ESEw0C4hiOHNvHwR5N6vTRjeLXt8w9EQL)kUghjkRB9a4obNegG7cUB4THh8VlYG)wHE2eraTDMPwSCblmACyQMlp3p8a7Uh32QKenuIa)DMPnQLpo2ATN7C9RgXKflz1pcwgpDslPercqfAbw0FSs(pMyOit7Nhc5ag2je2bbcDuNez0fFiQxC4(ZBNoNKLZPOiHheKtnRiEAflz)tsSel25omVV(D7Z7AQtF4N4YtJqQbit42GNWUwK6hhgin8XEJLliPmBen05kJKZvH5zhlWmKhSeg2CujRWdLzEss0GeNu88iPQKFgJg5YDSi5E7qRSqb7IqDvSF)mVeDqZKDCncs(rrAwtrJwiTLKUOyUPLr66oOpHetC9TsFrbzXS(IBJ6C5E3N(v4uGAW9Vdb6piZRUA1M66U2wIfiOGjsNoXOG(9WQ4POUl2wxfpbJ9KOG2jcZgvk3cehRz8DjkibwmwYKNRyo)jhXVcH6I0E(u0b35TXnzQ5j2Lu3UDIeJXdlQtMpp2JtmjYZEciEgIgf2HmM2abIVhgbLL2qlPSRvKcbZBB3c7qwwDkTa8894RrRxzGxGeh4d65GePirL(ioAvjaEZmW3RZO9ZY7XtFE7N3Jp3(8qV6LE1hV3b84RpEF(6ZT)1OUa8pwh9FO3a(NSr8W)m89Za)a4Fb(x3bCzo4FJ6kzFmNXWdZ)7CW)rr4)0b8dDa)xBf(VlUbaDG)NAtV4QgV8OvBhEjE0ufo5WLg5efk2mEb(FRdu(7GF01mqXLqNxvK5UzAXsim4WpbCC46Gd4)BDHj2nVhVU7Z7gUu3rnXojumx)K6HxNSe3LdsGaNd17StiNxFiFDwS)3Bl2dVXl2n5U9nwrDFdCvkQXIXVpvswtq7GPvtWayP7py5SLnmuKtmdstsOYnKsB3VwRsBbSWUsKrgQs4(6vwE0olS)h2Wf2oTKLUdINg(S7DSKWT(s1wUBsuVXEasJJDn)(cpJsoktGRKAkLunu3PTJumNhDnA0uPIg)On4OiXJtLCtBxaBVlJktxFcrjrJkTwz0vo)OOs2PFVnuzXeKXxtnsG0PdZFz72AixjI7A0W1ETHsmgzXsPlASR4jMqD72lIFa(JgoTROJo6yXdt9ALaH)dOqyMFQKq1NdD3xToQUyofPYLKtrQmwC3YY8VGxqsSa2bgnSTwYYpZrCVe7yzDN21ylVmkd1D6qoWZOEwR6b7BnXb4TSu(kYcLeZrdgf2n7G6kAgqFluqtKToEBEEYTeh92l)W8sILen2mjywXi3v8s5uKXVEzJic5WZkllFGHJowQSAc5flR)u3f2b7fWYEMFHp1oTrG27lIasind9QtvwskKOwojCd1Y9z8SAWokVzPRc)ZX4AgUmWIE79ehi0zp7mEg7aRd6g)(6)AGLfQVewt0KyzjZ1l)jMQEe1)BZ05GQtPzm56L5lrKEleTVXrNAi(z6ipJj3BRdotypf4)A6uGxuxsmpkRcMXTeDMW(SN6CRKpxCllq3mbe04Y6gAcKLxJoHbypzZvwhxbzPzOc1Wn5nW(95z)(17Xd80C0fOKMCMEQK)o758ClqdigPwN3UwjV7LX3lRlrwMA8Ju3Q9ZsBNmUHXccODczO1nT2Y0mZ4ddhJR7OUNSXOEaM9Cy470qqnG)QmDnKuxCR84wrUPdswAE1TsAgfqYinXCPkQmBc5ml30pxuN(hEKq(k0f6IgvM4cLq3XJVnyp80FAThh2viRzoqyrlOHNpMRdq32m9Q2dne3fKv0qkyBLyIcuML1qcsPSRUfQr0VCTiersNUKdKwpRVSG1WyUPZOUnY9iYMZPXS3rfThzvDC3hnsVoAJEw31mAtOtwHkY3MmE1Sgczxcr2FsrXCJQ7TEWrj)w)m0rMjJt2lhOjtwwRaIPrDItvq8ajofA8KOw1OkwxJ6TVM0Om5oi86MCpEN1Jm5CBY5b2JjNxtoF10wm56Rrnfto)2QiMC9BYnaPMm5g0KBiCDzYDOmMCVR1fq)fTMmNj3TyYHR8B1KZHj3TzYTPLXgSYvePZWPlZWPJkQt20aDJgMQdyYDytUJyY9UXnS3Jj37LuatUaKjeH7QbzaAtUqMCdJZr4fBiAvMChTfmPj3i4mf9Qc618Cg3WXEnprpm2ZK7yQUApKd3xNmgwvs2Gb4ceFKJpH35I4XFKUa42YBraC1w1g4fzSQjPGjm8blZjY7tKHXA20(uiJ6oBE)1yh(zm78Aa29YFW2c7wOMVSxdaDSayZMY61iuhUBTsu3d2EuhDpMYUYGDdgScFKPtoDKYd1fy3wFlhS7B28ceoazbcH)4vUCGDdqDH2cNwQXzaTXJOOUQ2NFRvD9keq9I01HRn7xdgo71SHAyq23(cTbv1BROQaSU5KKzqmzJDCg6A0qdOOimKVPQ0nsTEEla6sUnUloWA2DXxf2tqrdujsHjWmSBE3BBCZlkol9YijTaI46AjQtF4NqDmBE77UJXVV61)BqguonBRaQuw2idd0wLuHUcrsHSluOpQXLgN5qjZ3VAVb8lNNMt8Oj(1BYDg8a27R(RBDZt6ZINKTESxXy7RWjorGZ7Rv4C04Jpj25MCtEuuPjtzOiJM0Thgu29PpVEXbhF45oTVUaL32BrikTMV9CE941R3b73FW(9qcVVBV(CZ7Da3doijUFdrcVVVHiH3)LBJFGAJeGF0iJfB1mlpZpSZMLPrfA9qIEOvfU5NYHoKJRZZ3)f7iD8LKvmMSPLNNPp2CYnsztgkxjkF)RQRa0LoMbZh(0YkcAh9aI(hUlrsy73WdZxJXvA)K9zxinLzZt(IES(uIO04xnrsI9Xc4X)1oO1EwvO1PSyeRTdC6aJ4(HVwgEYxLKqMwcQ0Pd5B8sLpRqPrD3fgVDydfo1nAqHpDTL8yrRptm6xOZZhmv6XI30otRfH2lC56lkkDPYByTtkdp)YKYp5OHdnsG4rd11kYKB2MlBWiHdWVIDf3awlcFBkWYKc0(x2QusTqjIhzSuHxrzSwbnAiPBBBKprI0ROu1IAtBEtPIglC8qHx5qrTqQ2MowYaHIg5uRNIQULuHgjrIytgLSwa8JLm9Qu8RiV4Iq8rJWaKiiz3(tnUrTGnf1mfZ6u0muJsjwoa9BPZ1y0fWhBn7vUqTmdUOXyRiMGL6sCMfQDRg7oe5vX2ZAV8n7HU(uwtxfZ3040vFJwNU6RCHA0oMC6zAYs1d3nlvy3bsvepjDg50CUDFIzo9Pvpx4cDXo1oVHLCQ(EkCj2xnPmp5R2OLTxizHzhBTBrRrp347ZFF(g0B)95ni2Tn38(WEY1hVxFdHV3Zq(ha77wF9nGNo47M9ehOWytU5XT8FgtUNAJcVEZMbYMqQmayH4EgCOjQu8OLoExaG3ZnSaWARrSj3DdFoYceZwL2qd3Ywe0ALDPPNKSZLjRtRYuUgvuoV1IktFwTToOQR6jMQCPsy6XjeW61UclHiX7uqQXIHnWM3vkzb1MRlRiY1yI1w6IgBP0jVI0O6qxUEYbLeLNUX81uSjSxE4h92Ay9Hn5U378QDXHn52L93IHj37GC5(w5YaBYTh7va2K7(RV2VMCpa0ZMm5Cb9zY9GB2KBV7LFytUhcF3dx0KBFMC4jB)oPRIRj3bQV8T1(SHTJyGUj3J06s3YTHSYTJo45gE2Xnuvv5jwtxl8rTmVVQKvqiG0Scv0TN)3J7S9XrRrqyxNc4v8wa)koEBnzFT4AmMebwhBtitUpnz7aBDUbKXANInG0PInJMFdFZ2fQMpk8JksPAcSrTnsQ)vGuvr2gC1Yx1b1cfoF9d33JElWN3BG4dNL(LkQ)i9B5X2ZHnQ1FTTpVJvULJE412C1wree(m1qqBUTii1T0kF1vz4yx1nQKj3M3OGfBUfyHj3N1coOuiMkA4zcn4aZ1f4WhBdho04wi75AhmyTloFYUkoD)ADkGqwwyERlBqZBJSMe7YZn(GP7T0qN40(7IyFHRHSaDqSxx73Kd)VQBOk(DhP8()MTxXFNT3VJ36IBWdeDc34jwyjFvcp(yP90fCZh)Ty4g5UIBo4R2EgMAoJUAiLwQ6lX2xe1Sr2DImtUx4kS(n5EPvbYBY9fwfJBEfKRSo30eneN8nwylwo0jyRXG(pP2mPLhR)4Db2(0x)HThALW2Ge4aUS4FD7KN8LV242th2pdMCPV5XpNw38cnGac7R8W51l6tAOqDbb8jUr2pNvXT1T1b5xKBI8tDBDu(Lu0ix8Ctu2hsRlYVN5Mw53R0H9)rJHK4Mgb5RCHokhpPNJv4yt4jCfJUn9Zp5nTYXTpxBLJ80yiDtJae3l6Kam9jd0RFTP9M2DVDra(PUPvaEHoqJoXnncVoR8L17OO4dmyk50r7IS7zVUj7iHpo4WjMioCRNT(jQj57Uhz4IKUv0GFmxtikjrIdJrrKRikA6ctJKz5W(B4jSmQuf7cRUv7OAMYvSeHoEIXsxlJjvKQusrtTOlsQBTPIt(gJA73)Jj39E3ByX31B6ej)XxeERA3VNjzBcTB(nMVkNt41R4yEMDGqtp(AzTM(GSTTMj3PRVP1m5EIg2DAVuJBpSp(B20UDBnxSV36Qyr)IRVIvTM82K7l2k5qMRjKdRR1G6RXiho)GNm1uNSVuX0pAxihE1nCYHRWnztNNm79)EBF8B2E7ilUIzZV2iWwtRYnPN1fbxGH8kprHWkLI5TlcUF3R3coYbRvcnRt13DZ3NxVd5fob7K0Yk1mWR71Jx3KZEv6I17ke9uiPCUCiYH9izXJ1)XQX21K(0oBJmjB0tFQb6xVyKtKVlYKx7AMmPPtroUoCiYTa7CIrsPGj3s7oOxp(gcEOQ13imWR3ZGqIQSJfsxXukWO3(6whiq0dQx6rmx163Jn71TduUM(SzA(WKBdyP6vwRNIB7ADU)sSp41iY5RxN8AMCFLAh9A3H1rV25MvmNI74hDMCHB6OxZzlhiARrv13GUWQHKuKr6zS(AU86XdzF6oO3(Ox9tV2pp(YaEOx9UOksJabiNAzZlm1uOCgO8AkZkNqwQsgQY7LiiorzuswoZ0gxKm5KUA2iUdATv0UEEKoe9QG4q6Ck6JpC4Ygr6gz(x1ENGe9A1r6GVoDKoS6mlFJMpV1WDs1TtimiN9qIAi6sWNME0QU6NCxR9tr1J1ilc)(ih57RBXCv2r9tSWrsd67W6eeIDyxcFXR0A9lTItAv4lBFkQc)wCRot1vaw6gd(PFVvWpvu)K5oEFJOoWPI1HJgs47yFwaxd116EVSXtoysU90CUB3x9Xkosi7Pup57j)fV)Mo9Zon8UGVlDxd(PjdCwNszKtOSV1DCJ9jugEwHR4yj78sdEwz9JxsCGJ1MJLSE059Dq)h0DpZCBFG))
```
