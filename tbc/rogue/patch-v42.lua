-- rogue v41 -> v42: add a Stealth re-stealth timer to the cooldown row.
--
-- Design: NOT a permanent icon. Stealth cannot be cast in combat, and out of combat
-- it is almost always ready, so a persistent icon would be a passive readout ~99% of
-- the time — exactly what rotation-design.md says to cut. Instead it answers the one
-- question that IS a decision: "I just broke stealth — when can I re-stealth?"
--   * genericShowOn = "showOnCooldown"  => the icon exists only while Stealth is on cd
--   * load.use_combat = false           => and only out of combat (combat is a WA
--     tristate load arg: true = must be in combat, false = must NOT be, nil = ignore)
-- In a dynamic group the row simply collapses when it is absent, so it costs nothing.
--
-- The rogue pack's historical generate.lua needs the original workspace and cannot be
-- re-run, so this patches the shipped string directly: decode -> add -> encode, which
-- keeps every existing uid byte-identical (the in-game Update flow depends on it).
local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local SCRIPTS = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local PACK = dir .. "/all-specs.txt"
local savedArg = arg
arg = { [0] = SCRIPTS .. "/wa_lib.lua" }
local WA = dofile(SCRIPTS .. "/wa_lib.lua")
arg = savedArg

local f = assert(io.open(PACK, "r")); local src = f:read("*a"); f:close()
local T = WA.decode(src)
local OLD = WA.decode(src)   -- pristine copy for the audit

local CDID = "Rogue - Cooldowns"
local NEWID = "Rogue CD - Stealth"
-- Fixed, hand-picked uid: the original seeded stream cannot be replayed (the build
-- script is not runnable), so the new uid is a literal. Verified unique across every
-- pack by tools/verify-packs.lua's global uid check.
local NEWUID = "St3aLthCd42"

-- locate the cooldown group and an existing cooldown icon to use as the prototype
local group, proto, protoIdx
for i, a in ipairs(T.c) do
  if a.id == CDID then group = a end
  if a.id == "Rogue CD - Kick" then proto, protoIdx = a, i end
end
assert(group, "cooldown group not found")
assert(group.regionType == "dynamicgroup", "cooldown group is not a dynamic group")
assert(proto, "prototype cooldown icon not found")

-- the cooldown group's children must be the tail of c (depth-first order), so the new
-- child can simply be appended
local lastCdIdx = 0
for i, a in ipairs(T.c) do if a.parent == CDID then lastCdIdx = i end end
assert(lastCdIdx == #T.c, "cooldown children are not the tail of c; cannot append blindly")

for _, a in ipairs(T.c) do
  assert(a.id ~= NEWID, "id already present")
  assert(a.uid ~= NEWUID, "uid collision inside the pack")
end

local function deepcopy(t)
  if type(t) ~= "table" then return t end
  local r = {}; for k, v in pairs(t) do r[k] = deepcopy(v) end; return r
end

local icon = deepcopy(proto)
icon.id, icon.uid = NEWID, NEWUID
icon.parent = CDID
-- cooldown trigger: numeric rank-1 id (cd is shared across ranks), exact match,
-- override-following off — the only locale-proof form. showOnCooldown so the aura
-- only exists while the 10s cooldown is running.
icon.triggers = {
  [1] = {
    trigger = {
      type = "spell", event = "Cooldown Progress (Spell)",
      use_spellName = true, spellName = 1784, realSpellName = "Stealth",
      use_exact_spellName = true, use_ignoreoverride = true,
      use_genericShowOn = true, genericShowOn = "showOnCooldown",
      use_track = true, track = "auto", unit = "player",
      names = {}, spellIds = {}, debuffType = "HELPFUL",
      subeventPrefix = "SPELL", subeventSuffix = "_CAST_START",
    },
    untrigger = {},
  },
  activeTriggerMode = -10, disjunctive = "all",
}
icon.conditions = {}          -- no desaturate: the icon only exists while on cooldown
icon.cooldownTextDisabled = false
icon.useTooltip = true
icon.load = deepcopy(proto.load)
icon.load.use_combat = false  -- tristate: false => load ONLY out of combat
icon.load.use_spellknown = nil
icon.load.spellknown = nil

table.insert(group.controlledChildren, icon.id)
table.insert(T.c, icon)

-- ---- encode + verify ----
local encoded = WA.encode(T)
WA.verify(T, encoded)
local cont = WA.uidContinuity(encoded, PACK)
assert(cont.parentSame, "top-level uid changed")
assert(cont.changed == 0, "uid continuity broken: changed=" .. cont.changed)

-- ---- audit: nothing but the addition may differ ----
local back = WA.decode(encoded)
local function iseq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not iseq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end
assert(#back.c == #OLD.c + 1, "child count changed by more than one")
local newById = {}
for _, a in ipairs(back.c) do newById[a.id] = a end
for _, old in ipairs(OLD.c) do
  local new = assert(newById[old.id], "child vanished: " .. old.id)
  if old.id == CDID then
    -- only difference allowed: one extra entry at the end of controlledChildren
    assert(#new.controlledChildren == #old.controlledChildren + 1, "cd group cc changed oddly")
    assert(new.controlledChildren[#new.controlledChildren] == NEWID, "new child not appended last")
    local a, b = deepcopy(old), deepcopy(new)
    a.controlledChildren, b.controlledChildren = nil, nil
    assert(iseq(a, b), "cooldown group changed beyond controlledChildren")
  else
    assert(iseq(old, new), "unexpected change in " .. old.id)
  end
end
print(("audit ok: +1 aura (%s), all %d existing auras byte-identical"):format(NEWID, #OLD.c))
print(("uid continuity: stable=%d changed=%d parentSame=%s")
  :format(cont.stable, cont.changed, tostring(cont.parentSame)))

local out = assert(io.open(PACK, "w")); out:write(encoded); out:close()
print(("wrote %s (%d chars, %d auras)"):format(PACK, #encoded, #back.c + 1))
