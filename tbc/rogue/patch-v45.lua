-- rogue v44 -> v45: the cooldown row shows what you CANNOT press.
--
-- The default row was inverted: 15 icons on screen at all times, dimmed when down, so it
-- was busiest exactly when the rogue had fewest options — and a rogue knows their own
-- spellbook. What they cannot know is what is unavailable and for how long.
--
-- Every cooldown icon becomes genericShowOn = "showOnCooldown" (the pattern v42 introduced
-- for Stealth): the icon exists only while its cooldown runs, carrying the swipe and its
-- countdown, and disappears the moment the ability is back. The row is a dynamic group, so
-- the gap closes — ABSENCE IS THE READOUT. An empty row means everything is up; two icons
-- means exactly two things are down, both counting back.
--
-- The desaturate-while-on-cooldown condition is removed with it: under showOnCooldown every
-- visible icon is by definition on cooldown, so desaturating them all would grey the entire
-- row and make the abilities harder to tell apart. Full colour + countdown reads better.
--
-- NOT applied to press-on-cooldown rotational buttons, whose ready-glow is the instruction
-- and cannot fire from a hidden icon — the rogue pack has none (verified: zero glows across
-- all 16 icons), so every cooldown here qualifies as situational. Other packs DO have them
-- (paladin Judgement / Crusader Strike, druid Mangle, priest Mind Blast) and must keep those
-- on showAlways.
--
-- Run: lua5.1 tbc/rogue/patch-v45.lua   (rewrites all-specs.txt in place)
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

local function iseq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not iseq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

local converted, alreadyDone = 0, 0
for _, a in ipairs(T.c) do
  if a.id:find("^Rogue CD %- ") then
    local tr = a.triggers[1].trigger
    assert(tr.event == "Cooldown Progress (Spell)", a.id .. ": trigger 1 is not a cooldown trigger")
    -- no icon in this row may carry a ready-glow; a hidden icon could never fire one
    for _, c in ipairs(a.conditions or {}) do
      assert(not tostring(c.changes[1].property):find("glow"),
             a.id .. ": has a ready-glow condition — must stay showAlways")
    end
    if tr.genericShowOn == "showOnCooldown" then
      alreadyDone = alreadyDone + 1              -- Stealth, converted in v42
    else
      assert(tr.genericShowOn == "showAlways", a.id .. ": unexpected genericShowOn")
      tr.genericShowOn = "showOnCooldown"
      -- drop the now-meaningless desaturate (every visible icon is on cooldown)
      local kept = {}
      for _, c in ipairs(a.conditions or {}) do
        if not (c.check.variable == "onCooldown" and c.changes[1].property == "desaturate") then
          kept[#kept + 1] = c
        end
      end
      a.conditions = kept
      converted = converted + 1
    end
  end
end
assert(converted == 15, "expected 15 conversions, did " .. converted)
assert(alreadyDone == 1, "expected Stealth to already be showOnCooldown")

local encoded = WA.encode(T)
WA.verify(T, encoded)
local cont = WA.uidContinuity(encoded, PACK)
assert(cont.parentSame and cont.changed == 0, "uid continuity broken")

-- audit: only cooldown-row icons may differ, and only in the two intended fields
local back = WA.decode(encoded)
assert(#back.c == #OLD.c, "child count changed")
local newById = {}
for _, a in ipairs(back.c) do newById[a.id] = a end
for _, old in ipairs(OLD.c) do
  local new = assert(newById[old.id], "child vanished: " .. old.id)
  if not old.id:find("^Rogue CD %- ") then
    assert(iseq(old, new), "unexpected change outside the cooldown row: " .. old.id)
  else
    for k in pairs(old) do
      if k ~= "triggers" and k ~= "conditions" then
        assert(iseq(old[k], new[k]), old.id .. ": unexpected change in " .. k)
      end
    end
    assert(new.triggers[1].trigger.genericShowOn == "showOnCooldown", old.id .. ": not converted")
    for _, c in ipairs(new.conditions or {}) do
      assert(c.changes[1].property ~= "desaturate", old.id .. ": desaturate survived")
    end
  end
end
print(("audit ok: %d icons converted (+%d already), everything outside the row byte-identical")
  :format(converted, alreadyDone))
print(("uid continuity: stable=%d changed=%d parentSame=%s")
  :format(cont.stable, cont.changed, tostring(cont.parentSame)))

local out = assert(io.open(PACK, "w")); out:write(encoded); out:close()
print(("wrote %s (%d chars)"):format(PACK, #encoded))
