# TBC spell IDs — verified set + how to find more

## Rules

- **Aura triggers**: pass EVERY rank's ID (aura ids differ per rank in classic). Strings.
- **Cooldown triggers**: rank-1 ID only (always in a classic spellbook once learned;
  cooldown is shared across ranks). Numeric.
- **Finding IDs**: wowhead.com/tbc — the URL slug is the ID. For proc buffs, open the
  enchant/talent and follow the triggered spell. Verify anything not listed below; never
  answer from memory (a wrong ID fails silently).
- Talent-gated cooldowns: gate the aura with `load.use_spellknown = true,
  spellknown = <rank-1 id>` so the pack auto-adapts to spec.

## Verified in the field (rogue pack, 37 versions)

Buff/debuff aura IDs (all ranks):
- Slice and Dice: 5171, 6774
- Rupture: 1943, 8639, 8640, 11273, 11274, 11275, 26867
- Deadly Poison (debuff): 2818, 2819, 11353, 11354, 25349, 26968, 27187
- Find Weakness (buff): 31234, 31235, 31236, 31237, 31238
- Hemorrhage (debuff): 16511, 17347, 17348, 26864
- Holy Strength (Crusader enchant proc): 20007
- Lightning Speed (Mongoose enchant proc): 28093
- Executioner (enchant proc): 42976

Cooldowns (rank-1):
- Adrenaline Rush 13750 · Blade Flurry 13877 · Cold Blood 14177 · Shadowstep 36554
- Preparation 14185 · Premeditation 14183 · Evasion 5277 · Vanish 1856
- Cloak of Shadows 31224 · Kick 1766 · Riposte 14251 · Feint 1966 · Sprint 2983

## Verified paladin sample (example script)

- Righteous Fury (buff): 25780
- Holy Shield 20925 · Consecration 26573 · Avenging Wrath 31884 (rank-1 cooldown ids)

## Power types (WA `powertype`)

0 mana · 1 rage · 3 energy · 4 combo points (classic WA reads combo points via
GetComboPoints when powertype = 4 — target-relative, updates on target swap).
