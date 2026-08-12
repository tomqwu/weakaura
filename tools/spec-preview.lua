-- spec-preview.lua — show what each SPEC actually sees in a pack.
-- Run: lua5.1 tools/spec-preview.lua [packname]      (no arg = every pack)
--
-- A multi-spec pack is only usable if each spec loads its own rotation and nothing
-- else. Elements are gated with load.use_spellknown = <signature talent id>, so the
-- set of distinct gates in a pack IS its list of specs. This decodes the shipped
-- string and simulates, per spec, exactly which elements load — plus the "levelling"
-- case where the player has no capstone talent yet.
--
-- Read the UNGATED list critically: an ungated element loads for EVERY spec, so it
-- must be justified for every spec. An ungated element that only one spec presses is
-- noise in the other specs' HUDs (rotation-design.md: cut anything that doesn't
-- change which button gets pressed next).

local ROOT = (arg and arg[0] or ""):match("^(.*)[/\\]tools[/\\]") or "."
local SCRIPTS = ROOT .. "/tools/tbc-weakaura-creator/scripts"
local savedArg = arg
arg = { [0] = SCRIPTS .. "/wa_lib.lua" }
local WA = dofile(SCRIPTS .. "/wa_lib.lua")
arg = savedArg

local PACKS = {
  { "rogue",   "tbc/rogue/all-specs.txt" },
  { "paladin", "tbc/paladin/all-specs.txt" },
  { "druid",   "tbc/druid/all-specs.txt" },
  { "warlock", "tbc/warlock/all-specs.txt" },
  { "hunter",  "tbc/hunter/all-specs.txt" },
  { "priest",  "tbc/priest/all-specs.txt" },
  { "mage",    "tbc/mage/all-specs.txt" },
}

-- Readable names for the signature talents used as spec gates. Purely cosmetic;
-- an unknown id still prints, so nothing breaks when a pack adds a gate.
local GATE_NAMES = {
  [13750] = "Combat (Adrenaline Rush)", [14177] = "Assassination (Cold Blood)",
  [36554] = "Subtlety (Shadowstep)", [14185] = "Subtlety (Preparation)",
  [14183] = "Subtlety (Premeditation)", [14251] = "Riposte (Combat)",
  [20473] = "Holy (Holy Shock)", [20925] = "Protection (Holy Shield)",
  [35395] = "Retribution (Crusader Strike)", [31935] = "Protection (Avenger's Shield)",
  [20216] = "Holy (Divine Favor)", [31842] = "Holy (Divine Illumination)",
  [20375] = "Retribution (Seal of Command)",
  [33878] = "Feral bear (Mangle)", [18562] = "Restoration (Swiftmend)",
  [24858] = "Balance (Moonkin Form)", [16864] = "Omen of Clarity",
  [17116] = "Nature's Swiftness", [33831] = "Force of Nature",
  [30108] = "Affliction (Unstable Affliction)", [18708] = "Demonology (Fel Domination)",
  [17962] = "Destruction (Conflagrate)", [18288] = "Amplify Curse",
  [19574] = "Beast Mastery (Bestial Wrath)", [19386] = "Survival (Wyvern Sting)",
  [34490] = "Survival (Silencing Shot)", [23989] = "Readiness",
  [15473] = "Shadow (Shadowform)", [34914] = "Shadow (Vampiric Touch)",
  [33206] = "Discipline (Pain Suppression)", [10060] = "Discipline (Power Infusion)",
  [12042] = "Arcane (Arcane Power)", [12472] = "Frost (Icy Veins)",
  [31687] = "Frost (Water Elemental)", [11426] = "Frost (Ice Barrier)",
  [11129] = "Fire (Combustion)",
}

local function label(id) return GATE_NAMES[id] or ("spell " .. tostring(id)) end

local only = arg and arg[1]
for _, p in ipairs(PACKS) do
  if not only or only == p[1] then
    local f = io.open(ROOT .. "/" .. p[2], "r")
    if f then
      local T = WA.decode(f:read("*a")); f:close()

      local elements, gates = {}, {}
      for _, a in ipairs(T.c) do
        if a.regionType ~= "group" and a.regionType ~= "dynamicgroup" then
          local l = a.load or {}
          local g = l.use_spellknown and l.spellknown or nil
          -- inverse gate: element loads only for players who do NOT know this spell
          local ng = l.use_not_spellknown and l.not_spellknown or nil
          elements[#elements + 1] = { id = a.id, gate = g, notGate = ng }
          if g then gates[g] = true end
        end
      end
      local gateList = {}
      for g in pairs(gates) do gateList[#gateList + 1] = g end
      table.sort(gateList)

      local ungated, inverse = {}, {}
      for _, e in ipairs(elements) do
        if e.notGate then
          inverse[#inverse + 1] = ("%s  (hidden from: %s)"):format(e.id, label(e.notGate))
        elseif not e.gate then
          ungated[#ungated + 1] = e.id
        end
      end

      print(("=========== %s — %d elements, %d spec gates ==========="):format(
            p[1], #elements, #gateList))
      print(("  UNGATED (loads for EVERY spec, incl. while levelling): %d"):format(#ungated))
      for _, id in ipairs(ungated) do print("     . " .. id) end
      if #inverse > 0 then
        print(("  INVERSE-GATED (loads for everyone EXCEPT one spec): %d"):format(#inverse))
        for _, s in ipairs(inverse) do print("     - " .. s) end
      end
      for _, g in ipairs(gateList) do
        local vis = {}
        for _, e in ipairs(elements) do
          if e.gate == g then vis[#vis + 1] = e.id end
        end
        print(("  + knows %-34s adds %d: %s"):format(label(g), #vis, table.concat(vis, ", ")))
      end
      print(("  LEVELLING (no capstone talent yet) sees only the %d ungated elements.")
            :format(#ungated))
      print("")
    end
  end
end
