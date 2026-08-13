-- rogue v42 -> v43: make the combo point pips readable at a glance.
--
-- Problem: an unlit pip had NO state — its trigger was "combo points >= N", so nothing
-- was drawn where it would be. At 2 combo points you saw two 32x8 slivers floating with
-- gaps and had to count positions to read the value. Thin, and no frame of reference.
--
-- Fix, in two parts:
--   1. Every pip is now ALWAYS on (the Power trigger loses its >= N threshold, so it
--      produces a state regardless of the current value) and sits dark as an empty
--      socket. A condition "power >= N" lights it to its gradient colour. The result
--      reads like a filled bar: five sockets, the earned ones lit, the rest dim — you
--      see the total and the count in one glance instead of counting floating dots.
--   2. Height 8 -> 14, so the row has real presence next to the 14px resource bars.
--      Width and x positions are unchanged, keeping the 3px gaps and the layout.
--
-- No new auras and no uid changes: this only edits the five existing pip regions, so
-- re-importing still offers Update.
--
-- Run: lua5.1 tbc/rogue/patch-v43.lua   (rewrites all-specs.txt in place)
local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local SCRIPTS = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local PACK = dir .. "/all-specs.txt"
local savedArg = arg
arg = { [0] = SCRIPTS .. "/wa_lib.lua" }
local WA = dofile(SCRIPTS .. "/wa_lib.lua")
arg = savedArg

local f = assert(io.open(PACK, "r")); local src = f:read("*a"); f:close()
local T = WA.decode(src)
local OLD = WA.decode(src)

-- lit colours: the v41 green -> orange left-to-right gradient, unchanged
local LIT = {
  { 0.20, 1.00, 0.25, 1 },
  { 0.55, 0.95, 0.15, 1 },
  { 0.90, 0.85, 0.10, 1 },
  { 1.00, 0.65, 0.08, 1 },
  { 1.00, 0.45, 0.05, 1 },
}
-- empty socket: dark but not invisible, so the five slots read as a bar of its own
local SOCKET = { 0.13, 0.13, 0.16, 0.85 }
local NEW_HEIGHT = 14

local function iseq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not iseq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

local patched = 0
for _, a in ipairs(T.c) do
  local i = tonumber(a.id:match("^Rogue %- Combo Point (%d)$"))
  if i then
    assert(LIT[i], "unexpected pip index " .. i)
    local tr = a.triggers[1].trigger
    assert(tr.event == "Power" and tr.powertype == 4, a.id .. ": trigger 1 is not the combo point Power trigger")
    assert(tr.use_power and tr.power == tostring(i), a.id .. ": unexpected power threshold")
    local fade = a.conditions[1]
    assert(fade and fade.check.variable == "inCombat" and fade.changes[1].property == "alpha",
           a.id .. ": conditions[1] is not the out-of-combat fade")
    assert(#a.conditions == 1, a.id .. ": expected exactly one condition")

    -- 1. always-on trigger
    tr.use_power, tr.power, tr.power_operator = nil, nil, nil
    -- 2. dark socket by default, lit by condition
    a.color = { SOCKET[1], SOCKET[2], SOCKET[3], SOCKET[4] }
    a.height = NEW_HEIGHT
    -- conditions apply in order; the fade stays LAST so it still dims the whole row
    a.conditions = {
      {
        check = { trigger = 1, variable = "power", op = ">=", value = tostring(i) },
        changes = { [1] = { property = "color", value = { LIT[i][1], LIT[i][2], LIT[i][3], LIT[i][4] } } },
      },
      fade,
    }
    patched = patched + 1
  end
end
assert(patched == 5, "expected 5 pips, patched " .. patched)

local encoded = WA.encode(T)
WA.verify(T, encoded)
local cont = WA.uidContinuity(encoded, PACK)
assert(cont.parentSame and cont.changed == 0, "uid continuity broken")

-- audit: only the five pips may differ, and only in the intended fields
local back = WA.decode(encoded)
assert(#back.c == #OLD.c, "child count changed")
local newById = {}
for _, a in ipairs(back.c) do newById[a.id] = a end
for _, old in ipairs(OLD.c) do
  local new = assert(newById[old.id], "child vanished: " .. old.id)
  local i = tonumber(old.id:match("^Rogue %- Combo Point (%d)$"))
  if not i then
    assert(iseq(old, new), "unexpected change in " .. old.id)
  else
    for k in pairs(old) do
      if k ~= "color" and k ~= "height" and k ~= "conditions" and k ~= "triggers" then
        assert(iseq(old[k], new[k]), old.id .. ": unexpected change in " .. k)
      end
    end
    assert(new.height == NEW_HEIGHT and iseq(new.color, SOCKET), old.id .. ": socket not applied")
    assert(#new.conditions == 2 and iseq(new.conditions[1].changes[1].value, LIT[i]),
           old.id .. ": lit condition wrong")
    assert(iseq(new.conditions[2], old.conditions[1]), old.id .. ": fade condition altered")
    assert(new.triggers[1].trigger.use_power == nil, old.id .. ": threshold still present")
  end
end
print(("audit ok: 5 pips now always-on sockets, h=%d, all %d other auras byte-identical")
  :format(NEW_HEIGHT, #OLD.c - 5))
print(("uid continuity: stable=%d changed=%d parentSame=%s")
  :format(cont.stable, cont.changed, tostring(cont.parentSame)))

local out = assert(io.open(PACK, "w")); out:write(encoded); out:close()
print(("wrote %s (%d chars)"):format(PACK, #encoded))
