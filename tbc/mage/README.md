# Mage — Arcane & Frost HUD (v4)

Programmatically generated WeakAuras pack for TBC Anniversary (WeakAuras internalVersion
45, tocversion 20501). One import covers raid Arcane (40/0/21) and raid Frost (10/0/51):
spec-specific pieces load themselves through Spell Known checks, so the HUD auto-adapts on
respec with zero user action. Since v4 the same import also carries a PvP layer that only
exists inside arenas and battlegrounds — in PvE nothing about the pack changed.
Spell IDs only — aura triggers carry every rank ID as
strings and cooldown triggers carry the numeric rank-1 ID, so the pack is safe on zhCN and
any other localized client. There is no custom code anywhere, so the import dialog shows no
code-review panel. Import `all-specs.txt` (or the fenced block at the bottom of this file)
whole: copy all → `/wa` → Import → paste. Heads-up: the `/wa` editor preview force-shows
every aura at once with placeholder data (load gates ignored, identical fake "55.1"
timers, both specs' icons visible together) — judge the pack in combat, not in the preview.

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
- **The threat bar and threat flash still load in arena**, where threat means nothing. The
  only way to hide them would be an inverse instance-size gate, and WeakAuras only assigns
  the instance-size value inside instances — in the open world the gate may match nothing and
  silently unload the bars everywhere outside a dungeon. Two dead bars in arena is a much
  cheaper mistake than a threat bar that disappears while questing, so they stay until the
  open-world behaviour is confirmed in game.

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
only and only appears when you have a hostile target: it runs green, turns orange at 70%
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
140x12 CS LOCKOUT bar, and the Polymorph OUT rows (36x36, one clone per opponent, arena only).
It is a dynamic group because two of its children are clone sources; clones inside a static
group would stack on one spot. In the quiet case — trinket up, nobody sheeped, nothing
interrupted — the whole column is empty.

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
| Invisibility prompt | Spell Known 66 |
| Threat bar, Threat Flash, Invisibility prompt | party/raid only (`ingroup`) |
| All six PvE alert prompts | in combat only |
| CC ON ME, TARGET IMMUNE, Trinket DOWN, CS LOCKOUT (v4) | arena **or** battleground (`size`) |
| COUNTERSPELL NOW, CS LOCKOUT (v4) | arena/battleground **and** Spell Known 2139 |
| Will of the Forsaken DOWN (v4) | arena/battleground **and** Spell Known 7744 (Undead) |
| Enemy Trinket, Polymorph OUT (v4) | **arena only** — they read `arena1..arena5` |
| Everything | class MAGE |

Only six elements are ungated after v3 — the health, mana and threat bars, the threat flash,
Clearcasting and the mana gem prompt — and every one of them is a decision both Arcane and
Frost make. `tools/spec-preview.lua` models Spell Known gates only, so from v4 it lists the
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
**18859**/**18850**) were verified on wowhead.com/tbc before this build. The item triggers
(item cooldown + item count) and the PvP layer's Cast, Action Usable, Crowd Controlled, Spell
Cast Succeeded and Unit Characteristics triggers are the only ones in the pack not built by
the shared factory; their field names come straight from the matching WeakAuras prototypes,
and the item ones take the numeric item ID, never a name.

## Regenerate

`lua5.1 tbc/mage/generate.lua` from the repository root (run
`tools/tbc-weakaura-creator/scripts/setup.sh` once beforehand to fetch LibDeflate and
LibSerialize). The script is fully deterministic — fixed UID seed 20260816, no time or
environment inputs — so rebuilding produces a byte-identical `all-specs.txt`
(sha256 `fabdcd33a219e8ffb536eb53cf0cd6cbeb932c62ced48fd6172cdce86a43499a`, 8681 chars,
41 auras). It round-trip verifies the encoded string and checks UID continuity against the
committed `all-specs.txt` **before** overwriting it; `changed` must stay 0 so in-game
re-imports offer *Update* instead of duplicating the group. v2 added six auras and changed
none of the 25 v1 UIDs (`stable=25 changed=0`); v3 added none and changed none of the 31
(`stable=31 changed=0 parentSame=true`) — it edits load conditions only; v4 added nine and
changed none of the 31 (`stable=31 changed=0 parentSame=true`). Future versions must keep the
seed, never reorder existing `W.uid()` calls, and append new auras at the end of the
creation order. One import-time note for users: the Update dialog's *Arrangement* category
is checked by default and will reset any positions dragged in game back to the string's
defaults — uncheck it, or report the coordinates so they can be baked into the script.

## Import string (v4)

```
!WA:2!DZ3EWTXX997ZWkwcYoHIsI2sXYgw2sr0Xwgpi4dfPKaacicjqaOdGKsYQM4aWsGt8WDNU7aFLgNg(lovT5vdJZd)ljnju1UPP9pQzCtDNjtAdBsvBNmt(w2oEUPnTzQM2eN(UQttF3P7J7Wlcasrrf94p4Xd7T7E7UF)89Z(D)(DVLB0oZ9fp0fFKvYkKBY8AkQHuKu0oHdhos6W9H9R2zofzdnfjju(qffLYRHKp)kdlua56PCnesqYO4sw)Aybzb7NKUOgsWqDN19txrKe0lQUNAYVRqkY6iTPqUIjkJuFWw8iJRKvrlpslOvBuTJGsIZnNGwExPvuKmev1MjXetOJm4YQkGBIgwVL0bdHRUaA5eKrUoORiAk6gzz1vrTzzf5clQHkiQiNEwveFbnLYQlYYrkX5qBzjr5ju0kjyGZHZLypGneXXX5yfHYgfv0sOsESUZS4bRjel4utihnHE51ne0mCMDcrzr9IodI)NHZ5n0eluaPPh)GAw3(PcAqE7cL1e8Um5QUksssmV(E70DWY4cLvvsywK2800JMx35v0lNfnfUNMQ8etioZsJhkqQ0JNkDa(0vEusne(r8PsgowSRwwhfEgC7kfRgYWllucP7CX8OS4AG051gkCSKrgj2cLLTAwoxkVO(5llJ7ntH8kijPUdb69PzpFyL8OFT7YA4kC(ci1DK6cLXcaxrklj5ASIIgOLzpLnwVTfeKfzdM9cpyKLrc6OugybwbJI3lSVGYkYOvYJ7)KCmozmrthHhuZRppjRKwj0tWscIYraF4ca9a(HEH(W)FpnMYc6iPjsQikBKnu44PdZVFX8QDyHW4r6kL1YH0Vk(5inzbPrXVk8l9zwAcn8adUrjyi44QcY5WY3iKKiV8SPcXhoC8fnuYnfl)Bn5U9wwm)shQG)lmNXPvthCaE9CcsihlIfd8uKLUnWjkgrB4yrshsKHyckPiK35sSxdTXch5IUxuhJINCmX8gf39II4SNI2yFO7c2oh8w(E3fmeCKvO5HxXGowXPUJ6(nrYemWiPteKu8IWB9zpi8qFk8WJl4XGhNNcpYY0FXj9OW(DopgGmobQLboaCq4qoHUHNaE7oRTCqc1DncolUcvuGGXrAI6gI50TQc4unuw4jHNcomgHqAeJNZMzXbC0NbgaoY8zfS0LsEpUpSh)KR91p5Qx)oWatDbdcuavCzAFJbHodhm4r6c23se1eCfmo(Vl2LANgOzmgxVOqELPpTfxWc00ixu74ayOuoCNUiTpFGdO2rnfOQc9vyPAJCGHv3jnfSEUcb3MJkucga)ZRsFawbdLNM47FfMu8mwV9LPp)8LXJqtmlCKf1iIguACIbJNiEyyFAyacjplsZy1rhwZEcmVRAhr0eNZ1PklKNahDLoTQ7k9PXz8sJxxhB88OCyfmPXv1W3Otrg1o0y34wHM20yu5yAcQZpM1nRu5vtjesms6yrJh2ASQgq6srJhpm)48rp(qPv7EnAsykv58uLz(jKuu0ydmtHBDzLqzQ(kj8T7XAq0weQEG1OYzjMnE5szXtwa7Bb8GktzBf2)SA2EXWe7uuSeqw)mxvPVvk2Tnl12XryQnWT9V0XTthzlIelu0yFWXhDbIMto8CB6zYAG18Ln6IVuz8Sso5PPEWS6IYfKqbhoWXddZ3f88zcI5XZ1fmVZGKkJCZvOq8G4sNNO76nWGdQ2bUIdKNGGq5r5hwyMIW9bVdg5qOQkt72zJ5ueRX3HMLcc0LZA1Fon3cuTrDX8iEQae8s4IBKpT)1MHfEaCbDc7XjSxNlrFfdrhuoMgrEvwdXhscjiZliPwuWbRrKM9e1dfLW7oHqo05cjGvrKleuq7CJe9PQ(RNkfLrJwSIW7gZ0IzWbhbNtrPehCmh8ttu7(woH3j8UGalHkmt2yj6nqm9H1eLj0ZOIwTkX85rY8XdpAy(Lu0eXsikj5IdLGp6ztepDGyqKJCq(Cfr5Mmc8qBz(Pe0efWiG5fLdPukRGb)ucsLrC7xrD)h7yA5kkixaPV3dcxIAL08QyJsqAgZcVWbHViUgCaFPvQdNcxA)(DJlDNhf(Lif7euZR6LCXJd4LG0vkh8Y486RU8sY1auksVSR0sa705vjgTvGQFvHcJK5(UOBi6UHtynHXxNJmHbCsoigmme3A2GVwvwD(KktJ0iS4lOsUJORYvhH(kemELNLPPZna8R18aqQAP)H0NGX1thdj3oGFhWifHrTO4HXUyxWP5GZCvB2BAl4ahaEgQ6kCoC35NcEwy83pKHdeWvzwihUC5be7fnbuae5upuRirO1xneuWfGZdtcsqjqguaTmQpE7lklnykqFpaMT6PBFUxn5mMXcMgMbMfMJdEpSE1pDg49cUHNZb8(i0lWptg49tOiG)Fhe(aWZZyqGpinPFw61lc)CWppLCa(q2CcWhgZbaFeS2p8r5Gpg8lSPOMdF8JblaFc4fCaFs4tbF6Q6L3d8zikLWlwrHmAWZ6U7UhOVt0xo4Zwe(CWNh(fHVaezVmS(wWy9fHlzPtXG6uKagC)cyWn8l3c48N7UBeohVwG4Ig0vBqStbthRvazGbIxHGFR(GmeuAc1oSwyskrJYugbkSDDJz7NCXxZHSlFa2BtnNrf8Q6tUk4rLm1eSrZH3QpABQKkWXvPdulUUjtQwTkQtzGIQXQbRnmDkmmDjYGmM7MSgklmRM1pX3FqyhzcQjiMpZT2a5TSkGCOsbhBGtn4CjIgPoG8tuH0EHkJFyY7(iK37)DES1IPNxOaESbUKJA1aAnzFT6dUidrx1AwwIHBeBgu3vOybgoj2M)ybcDsSberthD0WmTJFpBTJvQQiGBTzGFD4vi80lLb(67VF3y1cS5IvWcKj1emu0iDMeWxTzAh7eBKdZueApKDb3U73pw0LTKOMMIwrQoBh4X7UCUqwBtCWI6ioBHSCcyFzXkcyZvO)g)4V9IuRiswwshnV9ke70dTiRsqRUd86wZPHmqJRzVaP6e(lOEKQ2FeiF(eY6NBmKWKbil9(CdJYlkCollv0phBjTJtxn7Hnkiqrke(amibtjqWmVjcX0lqycMV6lmWscNCIKHJOm2eJvIcLi0wVVdKLTsGImLg41SP3)TEJxS1AgV49SDMuh(gWV9QMah(Y0PE)vQFsB4RSHNOgd3wglsjliJs1rXI(jYu43Ti1IcM4e(w8bJfo(GRtw9nSM7VFdYp4pOjsH7f2(rVBMya(djJ)J5EIHsEs)d07WJuD8)rHVJ1qpDsbQhvMuwzAzB5WhCvt2Uy1mT1NUIezl1kqikz)a7Hy1Dx30(vuJo6XwU2hGnZZw0rTGVoJfY0APzRLsoAIaQQEgwRc(2qFAexPKOSbvTkRErmh9KWLdsMvJoE3e5HvjTufdoHaw99YEXLGML1LWzRnkCMA44dF6blhBWPcvJYbv48bj6fFxBfaQuzr6ISO2I3W8hqnIKTDXhb4Q48s4UpH6ETC4JLpadIxqgE(EdSDZ6QDA9SO5WpqqdVWaTgZp1WyxJjkJx7S6duj)Z6AuKOSU1dGTbojea3hC)WBgp4FFKb)DaDUfIaAxSzlXYfSWO2HPkwT8WWJS3oDBRss0qjc83wMMOw(04jC9STnUAetwSSv)iyz8kcTKsejavOfyj)Xk5)eIHImPFEiKdyqNqyhei0XDsKrx8XOgIH7pVf6YkwjNIIeEqqo10I4vgSS9pjUdSyR7W8(61TpVRRo9rFMRojcPgGSMzdEc5ArQPyyG0GN41xPGKY0r0qxOmso3SmJZy(wH8GLXWMJlz5HNmZtsI6N3KIZGKwK8ZyuNpU7Li3B7DKfkyxeQ1E96NzONdAMSDnrqYpksZAkQd)OTK0ffZnPmsx3b9je3ARVd6lkiZTZxCNu7d3)b0VgxftnwWDeq)rzgMvP2u3W12YmF5emr60jgg0Fawfpb1IVMAT3PSM4672AcZAvk7aIJ1m((efKalflzYlumN)Kd5xHqDrApFg6G7824Mmvme7ptDx2jsMlEqrDYsYXMpIjrEXtbXZq0OW2JX0giq89XiOS0gAiL9SQuiyE75TW2JLvNslaxQtF1o7vg4LiUY9WEomrksuPpMJgvcG)YmWvAnA)88E80J3E594ZTpp0REPx9X7Tpp(6H3NVEC7FDQla)vvr)h51H)ABep8dGFyg4nGFe83SB4VLd(7Ows2dZwm8W8Fph8pue(hDa)toG)5DaxT4Ma0b(xQScHRB8YtUyZWlXJMQWPhS0qNQqX6XlW)AvGY3d(X3WafxbnJQiZAZ0ILqyWHFc44OvbhW)(gctSxEpED3J3nDPUJkIDI3uU5j1dVbzjUpheF5nhQ7PhtoV(a(ATy)p3wShEZxSBYDxBUI6E676uuJfJ)qQKSIG2btRMGbWs33yLSLnmuKtmfstsy2BjL2UFTgL2cyH9SrgAGzd3t3YYd3AH9FXMUW2PLS0Dq8QWNE)JKeU7VsLiwtCCn2cqQRORy3x4PuYrzcCLutPKQHAx2gsXmE01WrtLkA8JxJHIelovYnPDbSTUmQmnedIsIgZ2yLrd(9XrLSt)bRPYIjiJVMAOaPthM)Q2T1qUse31WHR8AdLyes8oPX91v8eJPUl74WhG)4Ht7k6Wdps8WuRwjq4VjfcZStL4T9CO7)61q1LYPivUKCksLXCDwwM9f8csIfWgWOHNRLebzoI5LydlRA0UglcXOmuZPd5aVG6PTQhST1edG7y58Zklusmh1ZsyZSdQROza9SqbnrwO42(8KBjg6TF(b5LeljASDs8nJrUR4vYPiJF9YgreYHxvww(adgDKuz1eYlww)dCFydSxal7z2f(b6YgbAV1gciH0m0xCIYssHe1YjHBOwMpJxvd2q5TlDDyFogxZWLbwYB3N6qHo)5NYZihAdq343xV3aMzHAlH1cnjZSK5ML9etu1P4)PTXDIuAgtU9ZSLis3fI2ZOOZma)uTKNXK7EBHXe2lb(pHUe4L0LeZJYQGzClrxjSp7Lo3i5Zf7yb6(bGGgxr3qtGeHm6cgG9LnxzDCfKLMHzPtCtEdSFpd73xUtpWlWrJXin5mDoB(T15mClq9hgPwN3UwjV7vW3lRlrI0m(rQ7W(zPTtg3Wy(a0oHm06MwBzQNz8XHtW1Eu3ZwRxpG)OopkSsno1a(JZ0wxsDXDWJBf5Mmij66Q7G0mkGKrAI5svuz6eYzwPUFUKo9F8iH8ZsJvf1RmXfkH26tVtyF80FATnf2tiRvoqyrlOHxpMRdr35lDR2j1l1fKv0qk45kXefOmROHeKszxDluHOFLkEiIKonQbKwpRVSG1WyUjZOUtY9iY(RP2S3sfTNynnC3h1rVoAIEw71mAIRtwLkcqgVQxdHSrFiBXOOyUr19x13OKFRFo6iZ4XjBhd04jlRvaX0Oo1zkiEOeNbnAsuJAufRQrT11LgLj3BdUSj3HATEKjx3MCpbSptU3Uj3twrBXK7PQvtXK7W2QiMCpTjNBsnzY5XKZlUUm58LXKRNneq)LTwmh8Fa)NW)f8Fd)pW)7k4PQYvePZqORWqOdlQtI4F7iGPOFto)MC42wF4Mu)MCdqkGj3rilfc3jFhmOSj3rn5ogohVZLQXpvMCV7gqJMCbWzk41fOR(vlUPJ6QFjEyuNjxivxnhSH7RJhdRejBWGAbIp0jhZ7Cr84psBGAB7oeOwLW1aVmJpnjfmHHpyzorEFQmm(Y62Kbzu7Q(nhJTJNX8YRdy3R8Cnf2TqfRyVba6yUUMTy1BqOoC3A1OUhT5Oo6geLDLb76p4S8rMm5KrkpqBGDoVJd297uFKb7Jezq4BU64a2oa1Z3u40Y1U2NnFef1i1E8BfU1Rra1ltJbxt2SfmC2Rzd1WGm8JwnQQ7grvbyDZXjRDy8A74m01WH6trryaFtmB7i12(DaOl5MyOyFRBdf)AW(ckAGkrkmbMHnW7bBIbErXzPBgjPfqexxltn3d)eQjzZBF3wh9HQw)VozqjfBF8Puw2idd0UiPcDfIKczlKqFuTXeNzkjZQVkVb8lNNMt8Oj(1BYncEaB0QVUnmpPplEswKyVMX2xJlzIaNpqJW5OXhDCSXn5g)4OsJNYqrgnUBpmOS7ZoJEX(hDW5oRV2aLVV7qikTwP9CE941R3(71FWE9qCSVBV(CZ7Tp393pXJFdqCSVVbio2)vAIDGAdfGF4iJeBTMwEQ)TwpTm1FqBes0JSMWn)uo0bCCtEL(VClPJVISIX41fyEM(y9jxlLnzOC1O8dUMMcqdAmdMp4zLve0o(He9pyB8HW9FlpmFD6rPds2KCH0uMop5ZXX67aIsJF94dj2o93J)BCqR9TMqRZWyePF1dK9GDX2VhlpOx1PuZWt(2IeY0GFLoBiFJwQ85fknS72q99MTXeN5wnmX))kr9yjRp2l63zZLcMk9iXRBVP1G07LUA14IsJwEnHprfU0kKYp(WHdnuG4rd12kYKRHYgms4a8RAFX1NvC4BsbwHuGM)YwJsQfkr8iJKk8QkJvq0OELUPTr(ejsVQsvXXnn5nLkASWXdfE1dfv8QAt6yjdekAKZSrkQAhPcnuIeXgpkjCa8JKm9Au8RjZ5IqmwJqfKiizp7tNLJov2e05RyttfmdD2PeReG(fX5AeAm8XtR9QpFLmdUOUzRiMPLABCMfQCRg7oe5vX22AVYT7EV(mS1TAYjvSUfU(DBCHRVkBfgylilHZTCM6M06XB3KwyldsveVEDg90CUDFQPo7zvVq4cTzkR3YTS0tv3yHlZ(6hL5jF9fnShdjrNDK1)KB1AehFp(7Xx)E7ThVbXwW5M3h2OUE496Ba89EgWFFyZ46PN(80cZ4SxdbfiBY9EXT8NZK79TzHyVfAUskKT9ZsUkSkdcwiUN(hySzlE8sNSnqWoULfcwjuXMCVj4lqItmlyTHgSHDkOvaEPPNKS)LjHRvzcxdlkN3k2Y0NvzheQ6QAIPkxQeMICmbSMTRWsiIZpfKQTy4jzZ7kLSGA91LL75QnXkrWO2wkDLSinQw0vRMCqjr5jRnF15Oc7Oe)K3tnHj2KBhB76ngXMCDA)vvyYTlYLDV6ObBY1LDGGn5EGQHa2K7bHo3Ij3EGEm5272n5ER7NFqtUhcF3(kAY9WMCpIjNlAWCn5E0QrXTYhaST7d0n5ESgJGl3MsaChU)lm40JAOQQYtMrD9Wi1WIaxKeoHastlmRU9IbFANn3PA1ccB76bVM3j4xZoFRU5ylUoDqrGnWUfYK7ts2vWwNaazS2Wy9jDMytP53W30THQ5db)4IuQMaBw7MKQFlilQiBdUA4B7GohfoF9cp0tExWxYBG4dML(nhQ)e9Az12NfpTwVv2f9ow9op6XxFlCBvUt4txbbT9MIGu7Or(QRtFZUM7xjtU7zZcwS9gGfMCVOfCqPqmv0GtfQ)(MRnWHp8MoCO2Ds2NTzWG1V48zBR409R1kVdzndZDUSb1VBYQtSlp3O9NU7sdCQZ6VnI9pYnqwGwi2RQ9BY95m5(8BQk(ThP8EUCZv87Q52DCNlUbpq0kCJNyHL8nB4rhjTN2GB(O3HHBKBlU5WFTMZWuXy01cP0qvFf2MKOYCKTNiZK7lEnw)MCV0Aa5n5wCnMCZRG8SBWDqrnonFZf2ILdTc2A0V)tRnvA5r6nEBGTFSB(W2JSAyBqcCaxw8VUxYt(Y3ym7PfBUbtUHV9XoNg3jd1Gac7R8G51l6tAGqTbb8lCRSDoRHzR7SfYV31Tr2PUZwk)skAKlEUXk7dP1g53h)2w53R2IndsTUK42gb5R(8TuoEApNOWjgZt4znA3Ypx42w54UMRPYrEQpKUTraI7fTsaM(0b62V2KEt7U72ia)e32kaF(wqJM82gHxRv(Y6Dyu8(6pLC6OTr29c30KDe3hhCWeJfhU7Zw9SXK853JmCrs3YBWpLRXeLKi(HXOiYvefnDHjrYSCy)P8ewgvAw7cRUdBVAMYvSeHozIrsxjJjvKMTKIMArx4uB638Jj3oU)nnN56nDIK)KZDUlA3jNkzt8JB(nNVeNt51R4iEMUVqto66j0sphBdRzYLQ62vZKlDn7lTxQ2ng2N4nQBFUTUl2pAdvSO)QBSITyf5Tj3l3itqMBimbBWqo9BY4cMP)tNAIt3tQy6hVnCbVYMoxW14gSP1RD9HF3n3Dn7QzCdxZK33yezRVaBt6ATt0fyaVYJviSsPyEBJOBPB2IoYzIvcnRdK39Y3JxVd4fof7qWYk1mWL96XRBYXMkn(8Ucrp9rkNlhIConsIxS8prNDD9Pt1vtekzJE2Z0xV6fJCQ8TrO8vVHjuQ7eGJRfhaClWoGyKukyY913BqVE8na8ylwD7VaxUZ(HelYoshDftPaJJ7ByDsarpKDPhpClw9E8CFT7WGRUVAM6pi42ecpVY69eyBpB4DvI9rUgrsFZ6mxZK7vRCORTvRdDTlmTyof3Xp(u5cx3HUMZgok0wNARVonyQHKuKr6zS(qU86XdzJ62V3EOx9tV2lp(sFEOx9UKksJaciNxzZlmXeOCgO8AktlNqwA2mu93RqWCIYOKSCMPjwkzYHUE2jU9BTf0UzEAoe96H7q6ck6Joy4YgrAhH(VH92)i6nQJZbFT44COZsDMVZ8x8HR7OJ6SW7a((0DB1NK0rSoINihVtFNTER9X7e286vDMonJu)Nxw)KLe77en5mDQtDEFh2)HD35u3Z79)7p
```
