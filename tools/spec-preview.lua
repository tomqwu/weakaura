-- spec-preview.lua — profile-aware load/form eligibility audit.
-- Run: lua5.1 tools/spec-preview.lua [pack] [pve|arena|prepull]
--
-- This does not pretend that cooldown/aura state is knowable offline. It does
-- evaluate every load gate used by the packs plus Stance/Form/Aura state gates,
-- against explicit level-70 exemplar builds. That makes combined positive and
-- inverse spell gates, instance gates, combat gates and the Druid Cat/Bear split
-- visible in one deterministic report.

local ROOT = (arg and arg[0] or ""):match("^(.*)[/\\]tools[/\\]") or "."
local SCRIPTS = ROOT .. "/tools/tbc-weakaura-creator/scripts"
local savedArg = arg
arg = { [0] = SCRIPTS .. "/wa_lib.lua" }
local WA = dofile(SCRIPTS .. "/wa_lib.lua")
arg = savedArg

local function known(...)
  local result = {}
  for _, list in ipairs({ ... }) do
    for _, id in ipairs(list) do result[id] = true end
  end
  return result
end

local ROGUE_BASE = { 1766, 1966, 5277 }
local PALADIN_BASE = { 853, 1022, 1044, 4987, 24275 }
local WARLOCK_BASE = { 5484, 6789, 28176, 29858 }
local HUNTER_BASE = { 136, 982, 1495, 1499, 3034, 5384, 13165, 34026, 34074, 34477 }
local PRIEST_BASE = { 586, 32375, 33076, 34433 }
local MAGE_BASE = { 66, 1953, 2139, 12051, 30455 }

-- Explicit exemplars, not inferred from arbitrary spell gates. Optional talents
-- get separate profiles when they materially change a supported rotation.
local PROFILES = {
  rogue = {
    { name = "Combat", known = known(ROGUE_BASE, { 13750, 13877, 14251 }) },
    { name = "Assassination", known = known(ROGUE_BASE, { 14177 }) },
    { name = "Subtlety", known = known(ROGUE_BASE, { 14183, 14185, 36554 }) },
  },
  paladin = {
    { name = "Holy", known = known(PALADIN_BASE, { 20216, 20473, 31842 }) },
    { name = "Protection", known = known(PALADIN_BASE, { 20925, 31935 }) },
    { name = "Retribution", known = known(PALADIN_BASE, { 20375, 35395 }) },
  },
  druid = {
    { name = "Bear", known = known({ 33878, 16864, 22812 }), form = 1 },
    { name = "Cat (unsupported-scope guard)", known = known({ 33878, 16864, 22812 }), form = 3,
      forbidSpellGate = 33878 },
    { name = "Restoration", known = known({ 18562, 17116, 33891, 22812 }), form = 0 },
    { name = "Balance", known = known({ 24858, 33831, 16864, 22812 }), form = 5 },
  },
  warlock = {
    { name = "Affliction", known = known(WARLOCK_BASE, { 18094, 18265, 18288, 30108 }) },
    { name = "Demonology", known = known(WARLOCK_BASE, { 18708, 18788, 19028 }) },
    { name = "Destruction (0/21/40)", known = known(WARLOCK_BASE,
      { 17877, 17962, 18708, 18788, 34935 }) },
    { name = "Destruction (Shadowfury)", known = known(WARLOCK_BASE,
      { 17877, 17962, 30283, 34935 }) },
  },
  hunter = {
    { name = "Beast Mastery", known = known(HUNTER_BASE, { 19574, 19577 }) },
    { name = "Survival", known = known(HUNTER_BASE, { 19386, 19503, 23989 }) },
    { name = "Marksmanship (unsupported-scope guard)", known = known(HUNTER_BASE,
      { 19503, 34490 }) },
  },
  priest = {
    { name = "Holy", known = known(PRIEST_BASE, { 724, 6346, 13908, 14751 }) },
    { name = "Discipline", known = known(PRIEST_BASE, { 10060, 14751, 33206 }) },
    { name = "Shadow", known = known(PRIEST_BASE, { 15286, 15473, 15487, 34914 }) },
  },
  mage = {
    { name = "Arcane (40/0/21)", known = known(MAGE_BASE, { 11958, 12042, 12043, 12472 }) },
    { name = "Frost", known = known(MAGE_BASE, { 11426, 11958, 12472, 31687, 45438 }) },
  },
}

local SCENARIOS = {
  pve = { label = "grouped PvE combat", combat = true, ingroup = "group", size = "party" },
  arena = { label = "arena combat", combat = true, ingroup = "group", size = "arena" },
  prepull = { label = "grouped pre-pull", combat = false, ingroup = "group", size = "party" },
}

local function quote(s)
  return "'" .. tostring(s):gsub("'", "'\"'\"'") .. "'"
end

local function discover()
  local cmd = "find " .. quote(ROOT .. "/tbc")
    .. " -mindepth 2 -maxdepth 2 -type f -name all-specs.txt -printf '%h\\n' | sort"
  local pipe = assert(io.popen(cmd, "r"))
  local result = {}
  for directory in pipe:lines() do
    local name = directory:match("([^/]+)$")
    result[#result + 1] = { name = name, path = directory .. "/all-specs.txt" }
  end
  pipe:close()
  return result
end

local function multiselectMatches(value, config, useValue)
  if useValue == nil then return true end
  if useValue == true then return config and config.single == value end
  return config and config.multi and config.multi[value] == true
end

local function loadMatches(load, profile, scenario)
  load = load or {}
  if load.use_class and not multiselectMatches(profile.class, load.class, load.use_class) then
    return false
  end
  if load.use_spellknown and not profile.known[load.spellknown] then return false end
  if load.use_not_spellknown and profile.known[load.not_spellknown] then return false end
  if load.use_combat ~= nil and load.use_combat ~= scenario.combat then return false end
  if load.use_ingroup and not multiselectMatches(scenario.ingroup, load.ingroup, load.use_ingroup) then
    return false
  end
  if not multiselectMatches(scenario.size, load.size, load.use_size) then return false end
  return true
end

local function formMatches(aura, profile)
  for _, wrapped in ipairs(aura.triggers or {}) do
    local trigger = wrapped.trigger or {}
    if trigger.event == "Stance/Form/Aura" and trigger.use_form ~= nil then
      local matches = multiselectMatches(profile.form or 0, trigger.form, trigger.use_form)
      if trigger.use_inverse then matches = not matches end
      if not matches then return false end
    end
  end
  return true
end

local only = arg and arg[1]
local scenarioName = arg and arg[2] or "pve"
local scenario = assert(SCENARIOS[scenarioName], "scenario must be pve, arena or prepull")
local failures = {}
local seen = {}
local supportedLoadUses = {
  use_class = true,
  use_spellknown = true,
  use_not_spellknown = true,
  use_combat = true,
  use_ingroup = true,
  use_size = true,
}

for _, pack in ipairs(discover()) do
  if not only or only == pack.name then
    seen[pack.name] = true
    local profiles = PROFILES[pack.name]
    if not profiles then
      failures[#failures + 1] = pack.name .. ": no explicit profile definitions"
    else
      local f = assert(io.open(pack.path, "r"))
      local T = WA.decode(f:read("*a")); f:close()
      print(("=========== %s — %s ==========="):format(pack.name, scenario.label))
      for _, aura in ipairs(T.c or {}) do
        for key, value in pairs(aura.load or {}) do
          if key:match("^use_") and value ~= nil and not supportedLoadUses[key] then
            failures[#failures + 1] = ("%s / %s uses unsupported load selector %s")
              :format(pack.name, aura.id, key)
          end
        end
      end
      for _, profile in ipairs(profiles) do
        profile.class = pack.name:upper()
        local eligible = {}
        for _, aura in ipairs(T.c or {}) do
          if aura.regionType ~= "group" and aura.regionType ~= "dynamicgroup"
             and loadMatches(aura.load, profile, scenario) and formMatches(aura, profile) then
            eligible[#eligible + 1] = aura.id
            if profile.forbidSpellGate and aura.load
               and aura.load.use_spellknown and aura.load.spellknown == profile.forbidSpellGate then
              failures[#failures + 1] = ("%s / %s incorrectly receives %s")
                :format(pack.name, profile.name, aura.id)
            end
          end
        end
        table.sort(eligible)
        print(("  %-36s %2d eligible: %s")
          :format(profile.name, #eligible, table.concat(eligible, ", ")))
      end
      print("")
    end
  end
end

if only and not seen[only] then failures[#failures + 1] = "unknown pack: " .. only end
if #failures > 0 then
  print("FAILURES:")
  for _, failure in ipairs(failures) do print("  ! " .. failure) end
  os.exit(1)
end
