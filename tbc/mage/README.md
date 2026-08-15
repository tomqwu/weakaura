# Mage — Arcane & Frost HUD (v6)

Programmatically generated WeakAuras pack for TBC Anniversary (WeakAuras internalVersion
45, tocversion 20501). One import covers raid Arcane (40/0/21) and raid Frost (10/0/51):
spec-specific pieces load themselves through Spell Known checks, so the HUD auto-adapts on
respec with zero user action. Since v4 the same import also carries a PvP layer that only
exists inside arenas and battlegrounds — in PvE nothing about the pack changed, and v5 keeps
that promise (the one element it takes away, it takes away *only* inside an arena). v6 adds
and removes nothing anywhere: it changes *when* six cooldown icons draw, so the row shows
what you cannot press instead of everything you own (see below).
Spell IDs only — aura triggers carry every rank ID as
strings and cooldown triggers carry the numeric rank-1 ID, so the pack is safe on zhCN and
any other localized client. There is no custom code anywhere, so the import dialog shows no
code-review panel. Import `all-specs.txt` (or the fenced block at the bottom of this file)
whole: copy all → `/wa` → Import → paste. Heads-up: the `/wa` editor preview force-shows
every aura at once with placeholder data (load gates ignored, identical fake "55.1"
timers, both specs' icons visible together) — judge the pack in combat, not in the preview.

## v6 — the cooldown row shows what you CANNOT press

v6 is an in-place update of v5 (same UIDs — the import dialog offers **Update**, not a
duplicate group). It **adds nothing, removes nothing and moves no UID**: six icons in the
cooldown row change how they display, and that is the whole version.

Six of the ten cooldown icons now appear **only while their cooldown is running**, carrying
the swipe and the countdown, and vanish the moment the ability is back: **Presence of Mind,
Ice Block, Evocation, Counterspell, Blink and Invisibility**. The row is a dynamic group, so
the gap closes behind them — **absence is the readout**. An empty stretch of row means
everything there is available; two icons means exactly two things are down, and both are
counting back. Before this, all ten sat on screen permanently and merely dimmed, so the row
was at its busiest exactly when you had the fewest options — and you already know your own
spellbook. What you cannot know at a glance is what is *unavailable*, and for how long.

The desaturation went with them. Under the new rule every visible icon is on cooldown by
definition, so greying the whole row would have told you nothing and only made the icons
harder to tell apart; they now show in full colour with the countdown on top.

**Four icons deliberately stay visible at all times, because their glow is an instruction
and a hidden icon cannot glow:**

| Icon | Why it stays | What the glow means |
|---|---|---|
| Arcane Power | 3 min damage cooldown, pressed as the burn window opens | gold: it is up, and you are in combat |
| Icy Veins | both raid builds press it on cooldown — Frost's rotation is *Icy Veins and Water Elemental when possible, Frostbolt in between* | gold: it is up, and you are in combat |
| Summon Water Elemental | 3 min DPS cooldown, pressed on sight for the same reason | gold: it is up, and you are in combat |
| Cold Snap | its moment is a *sequence*, not availability | blue: Icy Veins **and** Water Elemental are both spent, so the reset is finally worth its 8 minutes |

Presence of Mind is the one judgement call worth spelling out: it is a damage cooldown, but
it is spent *inside* the burn window that Arcane Power's glow already announces, and it
shares Arcane Power's 3 minute cooldown, so a second glow would have been a duplicate cue for
the same moment. It is now a countdown that answers "when is the next window", which is the
question it actually gets asked. Everything else that converted is situational by nature —
an emergency button, a mana cooldown, an interrupt, a blink — and every one of them already
has a prompt in the alert flow that fires at the moment it should be pressed (Ice Block below
30% health, Evocation below 30% mana, Invisibility at 70% threat, Counterspell on an enemy
cast in arenas and battlegrounds). The alert says *press this now*; the row icon only has to
say *when does it come back*.

Nothing else moved: same load gates (including every Spell Known gate, so the row still only
shows spells you have actually taken), same positions, same alerts, same PvP layer.

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
Type load gate — arena + battleground for most of them, arena alone for the ones that read
`arena1..arena5` (three as of v6, counting the v5 Enemy Mana row), since those unit ids do
not exist in a battleground. In a raid, a dungeon,
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
text on, mouseover tooltips on. Every icon is Spell Known gated so only spells you have taken
(and trained) take a slot and the row stays tight: Arcane Power (12042) and Presence of Mind
(12043) for Arcane; Icy Veins (12472), which both the 40/0/21 Arcane build and Frost talent
into; Summon Water Elemental (31687), Cold Snap (11958) and Ice Block (45438) for Frost;
Evocation (12051), Counterspell (2139), Blink (1953) and Invisibility (66) once trained.
Since v6 the row is split by how the ability is used. Four icons are always on screen because
their glow is the instruction: Arcane Power, Icy Veins and Water Elemental glow gold the
moment they are up in combat (all three are pressed on cooldown), and Cold Snap glows blue
only when both of the cooldowns it resets have been spent, which is the one moment the reset
is worth spending. The other six — Presence of Mind, Ice Block, Evocation, Counterspell,
Blink and Invisibility — are situational, so they appear **only while their cooldown is
running**, in full colour with the countdown, and disappear when the ability is back. The
group collapses the gap, so absence means available: an empty row is everything up.

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
**18859**/**18850**) were verified on wowhead.com/tbc before this build. **Neither v5 nor v6
adds a single new game ID** — v5's one new element reads a resource rather than a spell, and
v6 adds no element at all, only changing when six existing icons draw. The item triggers
(item cooldown + item count) and the PvP layer's Cast, Action Usable, Crowd Controlled, Spell
Cast Succeeded and Unit Characteristics triggers are the only ones in the pack not built by
the shared factory; their field names come straight from the matching WeakAuras prototypes,
and the item ones take the numeric item ID, never a name.

## Regenerate

`lua5.1 tbc/mage/generate.lua` from the repository root (run
`tools/tbc-weakaura-creator/scripts/setup.sh` once beforehand to fetch LibDeflate and
LibSerialize). The script is fully deterministic — fixed UID seed 20260816, no time or
environment inputs — so rebuilding produces a byte-identical `all-specs.txt`
(sha256 `b7acbf74e776dbf5ff7db4a896b48098e2670363a76f566253de6e2fd1599c29`, 8918 chars,
42 auras). It round-trip verifies the encoded string and checks UID continuity against the
committed `all-specs.txt` **before** overwriting it; `changed` must stay 0 so in-game
re-imports offer *Update* instead of duplicating the group. v2 added six auras and changed
none of the 25 v1 UIDs (`stable=25 changed=0`); v3 added none and changed none of the 31
(`stable=31 changed=0 parentSame=true`) — it edits load conditions only; v4 added nine and
changed none of the 31 (`stable=31 changed=0 parentSame=true`); v5 added one and changed none
of the 40 (`stable=40 changed=0 parentSame=true`) — its other two edits are load gates, which
move no UID; v6 added none and changed none of the 41 (`stable=41 changed=0
parentSame=true`) — it edits `genericShowOn` and one condition on six cooldown icons, and
every other aura decodes byte-identical to v5. Future versions must keep the
seed, never reorder existing `W.uid()` calls, and append new auras at the end of the
creation order. One import-time note for users: the Update dialog's *Arrangement* category
is checked by default and will reset any positions dragged in game back to the string's
defaults — uncheck it, or report the coordinates so they can be baked into the script.

## Import string (v6)

```
!WA:2!DZxE0TXX9971WQ2gYoHI6Wwkw2WYwkIU2Y4GGhksjbaeqesGaqlajLKvmXcGHaR4IDxT7csbMMKgwRu17eghN400Ca14MMJ((zw)CDsB(JYMM0J8C)w23Zzt7V)5N(1MNZRTjTQhPTVMx7CSlUiaiffvKSFpPLlMDMzNz((579Sd3e9M7Z23LEOvYkKBM8AkQHuKu0oUdhos6W9H8R2Bofzdnfjju(qffLYRHKp3kJjua56jCnksqYO4sw)Ambzb7NKUOgsWqD7n9txrKe0lQU7gQVRqkY6iTzrUIjkJuV)o8iJRKvrlpslO1yuTNGsIZpVGwExPvuKmev1UqIPNwhzWLvvapenSElPdgc3Db0YjiJCDaxr0u0nYY6RIAvyn58v1qfevKtxrfXxqtPSAvwnsjopAlljkpTIwjbdCnCUe7bSLiooohRiu2OOIwcvYJ1DMfVynTybNAc5OfmaVUHGMHZStlklQx0zq8FmCUGHMyHcin94hqZ62NlOb5TluwtW7YKR6QijjX867Px3blJBuwvjHkiTfOLhnVUZROxolAw8mnv5PNw8clnvOaPspvQ0b4tx7rj1q4hXNkz4yXUAzDu4lGhxPy9qgEzHsiDNvZJYI7bYKxB0WXsgz8ylww2Ay5CP8I6NRSmE2mlYRGKK62eO3NM98XuYJ(Y3M1Yv48fqQBl15lJjaUIuwsY1KffnqlZEkBT(UxuqwKTyoaC)rwgjOJszGjyfmkENWEdkRiJwjpE(tQXuK1enDeErnV(cKQsgLq)bljikhb8HBa0p4hgage)3D3AjlQJKMoPIOSr2qHJNom)(eZR2JfcJhPRuwlhs)Q4NJ0KfKMa)QWV0NAPP1Wlm4bLGHGJRkiNdtFJqkI8YZMkeF4WXRAOKBww9VRK70BzX8lDWc(p)8gNsnDWH51ZjiHCuftg4PilDBGtumI2WrvYesKHyckPiK35sSxdDWch(sURQJrXZmPyEJI7SQiU6POd2h42GTYbV1)V3gmkC4vO1HxXGUwXPUTM(nHYemW4PteK08IWB7Ppa8aphE5Xf8iWJYtHhzz8V4IEyyFoxadqMIa1Ya7hoaCqNqFWJb)0oBSDqc1DmoUkUcvuGGXrAI6gI50T6c4KT0w4XHNaoegHqgetLZwYId4ipfmmC4fYkyXlL8oCFip(jxhCiYvV(DGbM6cgeOaQ4Y05gdcDAoyKdVlyVlrytWDWu4)FPDP2Rb6cgtPxuiVYCNYswWI0Yixu7z)yOuo8KUiDoV)9R2tdnOod9vyLAJCGXu3oTemFUcb3MJsucga)ZRsFaMbdLNw4hCfgv80wV9LPp)CLXRqtxboCvncPbLgxyW4jIhg2RggGqQtvAfRV6Wg2tJL7Q2tenX5DDYYc5jWrxPtR6U2CAkMCPPAAInvEuomdM0uQA4B0PiJgxAShCRqlBomQCsnb1fM06MvQ9QPcesmE6yrJh2ATQbq6srJhpm)u8rp2OPv7BngsyrQY5PmZ8tlPOOXwyMfp6YkHYu)vsK3UBRfrBsO6(xJoNvy24LlLfRSa27I4fvgZ2kS)ynS9IHj2LOyrGS(zU6uFRsShBwSTtHWI2a32)shpoDKTisSqrJ9chBIfjCo5W620ZK1aZ5lBSl(sLXALCYtl9az1fLliHcowGJfgwyxWfZeelhp3UGfCgK0zKBUcfIhe368eExVbgze1EWDCG8eeekpk)ycxOiCpW7GjCiuDMPD6S1AkI547rZIbb2LZg5Fof3IuUrDX8iEkbe8sKf3Q80HwBjSW9HBOty3oH94Cj6Ryu6IYr1i0RYAi(qsibzEbj1IcoydI0SNOEWOe5UtlKdD2qcywe5cbf0o74rFI6)6jsrLOrBwr4DJL0ILGdocoVIsjo4Oo4NJW29nCcVt4Dbbwcv4czJLyGaX0httuMiEgv0AujMppsMpE4jcZVKIMiMcrfswD0e8rptI4PdedIC4dWNRik3mrGhyllmRGMOagbSGOCiLszfm4NvqQmIBFkQ77Ohvlxrb5ci99Ca4YuRKwqfBucsZOc8Sha(S4EWb85wPjCkC5953nU19Ee43K0SJtnVAaYfpoGppKUw7GxaxxFnvxsTgMkI0l7kTfW2DEvIrBfO8x1eHrQ8GxYneDNWXTuy8hWruyaNGdIbJbXT0g8Y1LQZNuzoKgrk(IQK7i8QCnjqFfcgV2ZY0wDda)APhas1O4Fi9XzY6PRHKBh2Vdy8IWewI4HjV0UGtXbN(Q2sVPJG9VF4POSRWzXtN3d80WuFqidhiG7YSqoC7Ydi2lAAOaiYPEWojeH2FniGcopCoygqckbYGcOLr9r7EtzLbZc67gWsREYUx7vlCglXcMdUaubMNdEVSz1ptg49bUH3Vd4dqeVa)SzGpireb8ZDa4zGlYKGaFiAr)80Rxc(fGFrQWb4xYwMa8lJLba)kyUF4xLd(1Gp8McBo8rokSi8rHN1b8XGNd(415lVd4tqykHNVgdz0GNXDF9n8GhFWCWVEr4tb)gWNg(mqK9WW6BbJ1Rcx2INIb1Pibm4(zXGB43QdW5p1T3kCoEJaXQguVni2PGfhRvazGbIxHGFR)GmeuAc1ESCmjLOrzQebkSDDJzhICXx7HSlVF2BtnNrn8Q6JVk4rTk1gSr7H3QpCx6KAWXvXd0iUUnkvR3fnXmqr1y2G1gM(HWW0LilYyz3eFOYqTNKODRid9Qz9a89ha2wMGAcI5Z0ji9S8y52gvY4vDwCpHhJgvkjiNXRbsotvJ5WmuvMg7gcwFl9(mq)zULGjylRIjiuPGto8jhz(erJ0etWJvtG)I1w7Xc(hKi4FFVZJUwAj4fkGxnHl7OrUNoROOrEjxKLORAPHMy0hXEd1DekwGXsI9xiwGqNaB8r00rNimJZ6BAZzTsDMi8Ond8)bErIm(LYa)r7Bi3ywkSPM1WrefIcgkAKjtc43TDCwBhBGeZmg6mKDbpUhYpM0LTKOMMIwrk)Ep417D5CXS2MhHj1rC2bA50WEZIzIWM6q)n(XF7QulqswwshTGT3L96H2KvrOv3g2N3CAid0uA2ox1eXFr1dx32La5ZNqw)StIeMjaXT9ZogkVOWzTSYr)Sm3HNI6j8HmkiqrkezjyqcwCcbZ8treQ9SePilu)fgyjHtmDYWruMC6jlrHserEFG9NL5frrgdh8kzGVQf)f81E9NVTStV(NbE(7yRmYo8hdFZvP9h(cu92)2nRXh(IByT8y82FkMMs8MJkNKcg9tiQWFwrQ5im6j8NZhmw44JSovjSHzD)lAHacqBid3jS1JC7m6a8xsiat6E6rtEc)dpWyJxNa8WWFfETFw8ApvJcnCmZiRmNSTo6p0Q0uxTELURN0wJ9ZVLgjieUSVN9sS6oBYMHA8rh5Ol34dW2iAt6OM)3KLgz6m1SZujhTHavNrdZwbFByqnsCysu2GYxLvViwS(mWRgKOsKUE3g6HvlT4fdoTaM)9v9IBbTkRlIZD1kXz2XIp2PgPCSrMnudChuIdLX41SH)uQsvQhAud5BrLZ3PbsYDFPhc4Qf5t42pU6ESIwKvaedI9MdBSGb2OBD1ETEw0C4hiOH9QqR16tTQ21KIYyhVvVVA1VIRjqIY6wpaUBWjrcW9a3l8wWl(3dzXFBqVBHqG2btvlMUGjgnUmvZKNheEO90RBBwschkHG)2Z0g2YNeRT2ZDVXzJy0ILTMhblJDN0IkrOauIwGL8hRK)JlgkYm(5HqoGrCcHDqGqhZjHgDPhHAfhE(8wP(KSsoffj8IGCQ5eXUvSS9pjXsSyNNW8(gWTpVRRj9rEQRodcPgG4WTbpr6ArQDCyG0ih)1wPGKYCr0qNVmsoxfMLDSaZqEWYyyZXKScpuMfifrdsCsXlGKQs(zmAKl35sK7TdTYIfSBc1uXb8ZSs0bTs2X1ii5hfPvnfnAH0rs6II5MrgPR7G(esmX13g9ffKfZ6lTDQXL7B)6xJUa1G5Fhg0FyMvD16n1nCVTmlqqbtKoDIXa97J1XttnxSTMkEsM0tcdANey2itzpqCmNX3JWGeyPyjtE(I58NCu)kerxKXZNGU4UGnUjtnlXUI6oSlKOmEerDI)8yloXcrE(tcXZq4OWgKX4giq89YeqzXn0sj7EvLqW826TWgKLvNkwaUCV(Au7vg4ZtId8H8CicvKWsFuhTYeaVEg473z0(5494PFVdW7XNBFEOx9sV6J37GE81pVpF972)6Kxa(7RJ(p8Rb)d2iE4Fe(bzGFi8pb)Z7eUkh8VqnLSFMXy4L5)vo4FRi8V7a(roG)JTb)Nf3eGoW)vn3lUUXlpE12HxIhnvHtnsPrpzHInJxG)76aL))Wp(ggO4kOlOkYm3mTyjegC4NaoosDWb8)SHWe7H3Jx397DtNQ7OgzNekMBEu9WBqPe3JdsGaNh13CtkNxFyFDMS)3At2dV5t2n5UZnxsD)dEDsQXKXFaLswJq7GXvtWayQ7pCLSLnmuKtmlstsOYTKuB3VsRuBbmXUsKrhUs4(7twESotS)720j2oTOLUdIDdFU9nEs42)I1s3njQ3ylaPXXUMDFHNvjhvsGRKAkLunu3LTHumJhDnw0uPIg)ynyOiXItLCZy3aBRlJktZpHOKOrLw7mAMZpgQKD53FdDwmbz81uJgiD6W8x1ESgYvI4UglCTxBOeJtswknPXUINys1DyNe)a8hlCAxrhBSXJhMA1kbc)hsHWm7ujHQph6EVEnuDPCksLljNI0zS4ULLzFbVGKybSbmAyDTK0pZrmVeByzDJ21yPxgLHAoDihypQNZQFW2wtmaUNLZxrwOKyoAWOWMzhuxrZa6FXcAIS84T1fi3sm0BF8JWljws0yRKGzfJCxXRKtrg)6LnIiKd7vww(aJeD8uz1eYlww)zUhSb2lIP9m7cFMDzJaT3xebKqAg6vNUSKuirTCs4bQL5ZyVAWgkVvPRd7ZX4AgUmWsE77Khm05o3SEg)GBaXn(9nWnanluBjSC0KOzjZnl7jMUEe1))LPZbvNkMXKRpMTer6Rq0(NaD6H5NTJYzm5ElDWycBxG)BOUaVKUKyEuwfSe3supH9z76CRcFUupls3mbe04k6gAcK0RrDya2B2CL1XDqwAfQqvCtEdSFFb2VF1E9aplhnbL0IZ0BL83DVxGBrAaXi96c29k5DVc(EzDjsAQXpsDB2plTDX4bgliG2fKH230EltZsgFu44CDh190ng1dWS3JaF3gcQb8xNPRHK6sBJhpkYntqsQ5v3gzyuajJ0eZLQOYCjKZSst)CjD6F4rc5Rqt0fnQmXfkHURNC7WE5P)0ApoS7qwEoqKIwqd7pMRds32m9P2lne3fKv0qkyDLybfOmROHeKsz3Dlwtq)k1IqePCAkhiJE2CzrRLXCZKrD7K7rKnNtJvVJmAp2AA4UpAKED0g(SUZz0MqNSkwKVdz9QzoeYUeIS)KIILnQUV6bhL8B9ZsxzMkozVCGMkzzTcigh1jpDbXdM40OjsIALJQyDoQ366IJYK7qWRAY9KDMpYKZTjNhyVMCEn58vJBXKR)g5um58BZIyYnGj3GKEYKBitUHX9Lj3HZyY9o2qa9xWYzotUBZKd353UjNdtU7WKBlRGvyLRisNHtxHHthtuNSPb6MyykpGj3rm5oQj37epWExMCVBsdm5cqCicpvdYa0MCHm5gbxJWl1q0Qm5owlystUrXvk61f0RzFg30XEn7Ohg7zYDCvxThYHNRtfdZkjBWaCbIp6jM078r84psxaC98MeaxTS2aVatQAskycdFW0Cc9(KzysnBAFkKrDxnV)ASd)mw686a29IV)2c7wSMTS3aaDSayZCz9geQdpTwnQ7HBpQJUhtzxzWUHcwHpYmjNjs5H7cSBBVPd29TAobHdssqi8NS60b2na1fBlCA5g9aAZhrrnvTF)wzD9Aeq9c08W1M9RbdN9k2qnmi77CX2GQ6Rvuva20CkIhet14eNHUgl0Gkkcd7B6kDtOwVVjaDj3gZfhCDBU4ld7nOObQePXeyg2mV7VnM5ffxL(ycjTaI4(AzQrF4NqnmBb77URjEG69)RrwuodBRaQuw2idd0wL0HUcrkHSluOpQXuJZmOKz7xT3a(LZtRjE1e)6n5olEb79u)1THLt6ZsojlFSxZy7RrhNiW593kCoA8jMcBCtUPogQ0uPmuKrt52ddk7(mxqV4qtmY8NXxxGYB)njckT83EEVE8617qd4p4aEiH33TxFU59oO7HgIe3VHjH333WKW7)ITXoqTrdWpwKXJTwQLN9h1z1Y0OcTreIE41eU5NkdDyh3K93)f6O44RiRymvtPNNXp2CXnkYMSuUAu(bwttbOPoMbZh5mYkcAh7GI(hPlrsyh3YdZxNXv6aK9zxinL5Yt(IES(uIOIXVEIKe7JfWJ)BCqR9UMqRtBjrS2oWPdsepa81ZWt(QKeY0sqLotiFtuQ85eknM7UiXBN2qHtFRgu4twlLhlz9zIr)cDUCWuPhpEt7mTwiAF(RwpPO0uL3qUtkdxEfs7NASWHgnq8OH6AhzYnxZTnyKWb4x1UIBqRKW3MgScPbT)LTgTuluI4rgpv4v1gRmOrdjDBhJ8jsKEvTQwuBAZBkv0yHJhk8QxkQfs12mXsgiu0iNEJ0u1EsfA0ejInvusUa4hpz61O5xtwXfHyJgrcqIGKD7pv5gvd20u1umTtrZqvkLyLa0VLoxJttGpwB2lDXAvgCrJXwrSawQjXzwS2TAS7qKxfBpR9IVrp01N2YDvS8MgDx91A1D1x6I1e7yYPNPjnvpA30uHnhivrSt6mHtZ729jN9mNr98Hl0f9u76wwHt13tHlZ(QjL5jF1gTS9cjjMD81VgTgTCJVF)97BiVd0V3GyZ2CZ7dBjx)8E9nm(Epd7FqSTB93)GE6GTB2ooqHXMClGh5)CMCpZMfE9nAkiBcPYaGfI7zOHNSsXJv6eDbaEF3YcaRLJytU7f(mKeeZYsBOrAzlcALzxA5jj7CzsEAvM21yIY5TsQm9z126GQUQxyQYLkHfpoPaMV2vyjejENcsn2mSc28UsjlO2CFzfrUglSwQlACKsDEfPr5HUA9IdkjkptJ1RPytyNE4h)oAi)WMC3)DF9MCytUDB)TyyY92ixEGvNgytU9ANbytUhSEUFn5EiO3TyY5c63K7H3Qj3(2h)iMCpc(UhTOj3(n5WoB)2PzX1K7G1tFBTpBy7igOBY9yTM6wUnLm3o2qNFK5MWqvvLNOnD9ipQf)(QsYGqaP5eQOB7)3t6S9XrRrqyxDb8AElGFnhVTM0VwCDgtIaBGTjKj3NKSDGTo3aYyTtXgu60XMvZVHV56IOMpm8Jlsf1eyZABKu)RaPQISn4QLVQdQgkC9gaEGh)2GpN3aXhjl9lvu)XgWYITplwP2a12(8ow9wo6rxF(Q1cs6kSCrvBCzJM2ABrtQ90QSRRZqZUMBAjtUTUzbr2AlqetUpTf0qPqmv0iZgAObNVlqJpYMo0W56N090Tl4pFkBYL7xPtb)XsBYBE58BElJ1ezvE(jgkDFLg(KNXFxiRlEdKJNY22noDto8)QUPYK3DKY79B1Eg7D1EBmEZlUbVq0jCJNyHL8vj8eJN2txWnF03KHBK7kU5qVC7LWuZWZ1cPSQU(YRHWltUxyJ3NDaMBY9fwdfwEfKRSb3ueneh8nxOkETVtqvJH8FkTztlp(aX7cu9zV5dvp8QHQbjMEGBl(x3j5jFLnrZAAak0H9RGjx634y7sRBoHgqaH9vEK86f9jnCOUGa(y3mTDP70hYwZRT0NiVbY2YT3r6tsrJCXZnzzFiTUqFEUBzPpVuh2FgngYG3WqOEPl2r60P8C8chFspHRy0n3d)43YsN2X8TLoXtJHZByiq4zrNiqPpvG(8RnJ30U7RleOpXTSeOl2bXCt(ggItNzEY6Dmu8bhkLC6ODH2883WOnKWVgCKetghU9Zv)ePK8DRJmCrk3kAQpHRjfLKiXUWOiYvefnDHzqYSAy)nWewgvQIDJv3MDubt5kwIqNiX4PRvXKksvkPOPw0fP0T1uZjFJoT97NXK7(V3nT4J6nDIK)KlcPvTN3ZMSnHgn)MZx1Yj96vCCpZnyOzMy9KRM3pBBFzYDM6B6ltUNQHD31LBC7v9rF9M2TyR7M993qnl6xAJ1SQ1O3MCFPwz(ZCdH5FdLdNVoJ5)cdDQutFQ(tft)yDH5)LVHX8)ixVwG(GV72htKD0oHfxZsRVXqWwxzjMmZ6cHlWWELNSqyLsX82fc3V3nBch5GPkHM1PI7E473R3H9cNKDsuzvAg4v96XRBYzxknz3UcrpfpkNlhICyjss(Q(prvMUU4N2vBOjzJEMtp4a6fJCY8DHM8k340K24PWgxhoe2wKDoRiPuWKB59e0RhFddps16BKe4v7Diirv2XQORykfyI3(gwhOo0d6w6r0w163Jv71TdKTM(StA(WyBtiv3kR3tbTDVb3Fg2hCze68nRtUmtUVATJUS7Y6Ol78ZjMtXD8JnBUWnD0L5SLduS1jR6RrtmzijfzKEgRVgkVE8q2NRd5TF6v)0RdWJVmOh6vVlPI0iqaYP(1cctpnkNbkVMYCYjKLQKHY8EfcItugLKvZmTXejtoPRNnY6qwBLRBMhjcrVoeCiDEf9jgjCzJiDty(xZENue9g1rIGVoDKiS2sw(MnFELHNKQ7GiWGC29iQHOPWon9OjDTp5Rw)NcPhVrPi87NCKPVHjZvzhvoXchjnOVtRtGh2Hfj8LUw71V8QoPsHVI9Pqk87WT2sQUgWs3AiF63FvYNkQFQCNO)rvh80X6WrRi8DTplDRH6ADVl24jVlP2EAU2T7RMyvhPI9wQ389M)spytNEyNbEhW3JUR7(KKfoRt5lYj813(UU1(e(c7v4QowVUG0qNtw)eLeh84T5y9QxDEFhY)HC37S3X77)9
```
