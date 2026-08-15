-- rogue v45 -> v46: combo points pop when earned.
--
-- v43 made every pip permanently active and changed its colour with a condition. That
-- made the row readable, but WeakAuras start animations only run when a region becomes
-- active; changing a condition cannot retrigger one. Keep the v43 visual language by
-- placing five always-on dark socket textures underneath the existing pips, then restore
-- each existing pip's `power >= N` activation threshold. The earned pip can now appear,
-- play a short 1.85x scale/brightness pop, and settle over its socket. A two-point gain
-- activates both thresholds on the same power update, so both new points pop together.
--
-- Five new socket UIDs are literal and append-only. Every existing aura/UID survives.
-- Run: lua5.1 tbc/rogue/patch-v46.lua   (rewrites all-specs.txt in place)

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local SCRIPTS = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local PACK = dir .. "/all-specs.txt"
local savedArg = arg
arg = { [0] = SCRIPTS .. "/wa_factory.lua" }
local F = dofile(SCRIPTS .. "/wa_factory.lua")
arg = savedArg
local W = F.W

local f = assert(io.open(PACK, "r")); local src = f:read("*a"); f:close()
local T = W.decode(src)
local OLD = W.decode(src)

local LIT = {
  { 0.20, 1.00, 0.25, 1 },
  { 0.55, 0.95, 0.15, 1 },
  { 0.90, 0.85, 0.10, 1 },
  { 1.00, 0.65, 0.08, 1 },
  { 1.00, 0.45, 0.05, 1 },
}
local SOCKET = { 0.13, 0.13, 0.16, 0.85 }
local SOCKET_UIDS = {
  "RgCpSock001", "RgCpSock002", "RgCpSock003", "RgCpSock004", "RgCpSock005",
}

local function iseq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not iseq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

local resource
for _, aura in ipairs(T.c) do
  if aura.id == "Rogue - Resources" then resource = aura; break end
end
assert(resource, "Rogue - Resources group missing")

local sockets = {}
local patched = 0
for _, pip in ipairs(T.c) do
  local i = tonumber(pip.id:match("^Rogue %- Combo Point (%d)$"))
  if i then
    assert(LIT[i] and SOCKET_UIDS[i], "unexpected pip index " .. i)
    local tr = pip.triggers[1].trigger
    assert(tr.event == "Power" and tr.powertype == 4 and tr.use_power == nil,
      pip.id .. ": expected v45 always-on power trigger")
    assert(#pip.conditions == 2, pip.id .. ": expected light + fade conditions")
    local light, fade = pip.conditions[1], pip.conditions[2]
    assert(light.check.variable == "power" and light.check.value == tostring(i),
      pip.id .. ": unexpected light condition")
    assert(fade.check.variable == "inCombat" and fade.changes[1].property == "alpha",
      pip.id .. ": unexpected fade condition")
    assert(iseq(pip.color, SOCKET), pip.id .. ": expected dark v45 socket colour")

    -- Clone the always-active v45 region before turning the original back into
    -- an earned-point overlay. It remains the stable empty socket underneath.
    local socket = W.deepcopy(pip)
    socket.id = "Rogue - Combo Socket " .. i
    socket.uid = SOCKET_UIDS[i]
    socket.conditions = { W.deepcopy(fade) }
    sockets[i] = socket

    -- The existing UID stays with the earned point. Crossing this threshold now
    -- activates the region, which is what makes the start animation replay.
    tr.use_power = true
    tr.power = tostring(i)
    tr.power_operator = ">="
    pip.color = W.deepcopy(LIT[i])
    pip.conditions = { fade }
    pip.blendMode = "ADD"
    pip.animation.start = F.animCustom("0.3", {
      alpha = 0.35, alphaType = "alphaPulse", scale = 1.85,
    }, "easeOut")
    patched = patched + 1
  end
end
assert(patched == 5, "expected 5 combo pips, patched " .. patched)
for i = 1, 5 do assert(sockets[i], "missing socket " .. i) end

-- Make the nested group's order and the flat transmit order agree: socket first,
-- earned overlay second, then the existing bars subtree. Earlier creation keeps the
-- dark socket behind the lit pip without relying on a new frame-strata convention.
local oldChildren = resource.controlledChildren
for i = 1, 5 do
  assert(oldChildren[i] == "Rogue - Combo Point " .. i,
    "unexpected Resources child order at " .. i)
end
local children = {}
for i = 1, 5 do
  children[#children + 1] = sockets[i].id
  children[#children + 1] = "Rogue - Combo Point " .. i
end
for i = 6, #oldChildren do children[#children + 1] = oldChildren[i] end
resource.controlledChildren = children

local rebuilt = {}
for _, aura in ipairs(T.c) do
  local i = tonumber(aura.id:match("^Rogue %- Combo Point (%d)$"))
  if i then rebuilt[#rebuilt + 1] = sockets[i] end
  rebuilt[#rebuilt + 1] = aura
end
T.c = rebuilt

local encoded = W.encode(T)
W.verify(T, encoded)
local cont = W.uidContinuityStrings(encoded, src)
W.assertUidContinuity(cont, "rogue v46")

-- Audit: five intentional overlay edits, five new sockets, all other v45 auras exact.
assert(#T.c == #OLD.c + 5, "expected five new socket auras")
local newById = {}
for _, aura in ipairs(T.c) do newById[aura.id] = aura end
for _, old in ipairs(OLD.c) do
  local new = assert(newById[old.id], "existing aura vanished: " .. old.id)
  local i = tonumber(old.id:match("^Rogue %- Combo Point (%d)$"))
  if old.id == "Rogue - Resources" then
    for key in pairs(old) do
      if key ~= "controlledChildren" then
        assert(iseq(old[key], new[key]), old.id .. ": unexpected change in " .. key)
      end
    end
    assert(#new.controlledChildren == #old.controlledChildren + 5,
      "Resources group did not gain five sockets")
  elseif not i then
    assert(iseq(old, new), "unexpected v46 change in " .. old.id)
  else
    for key in pairs(old) do
      if key ~= "animation" and key ~= "blendMode" and key ~= "color"
         and key ~= "conditions" and key ~= "triggers" then
        assert(iseq(old[key], new[key]), old.id .. ": unexpected change in " .. key)
      end
    end
    assert(new.uid == old.uid, old.id .. ": uid changed")
    assert(new.triggers[1].trigger.use_power and new.triggers[1].trigger.power == tostring(i),
      old.id .. ": activation threshold missing")
    assert(new.animation.start.use_scale and new.animation.start.scalex == 1.85,
      old.id .. ": pop animation missing")
    assert(new.blendMode == "ADD" and iseq(new.color, LIT[i]),
      old.id .. ": highlight styling missing")
  end
end
for i = 1, 5 do
  local socket = assert(newById["Rogue - Combo Socket " .. i], "new socket missing")
  assert(socket.uid == SOCKET_UIDS[i] and iseq(socket.color, SOCKET),
    socket.id .. ": socket identity/style wrong")
  assert(socket.triggers[1].trigger.use_power == nil and #socket.conditions == 1,
    socket.id .. ": socket must stay active with only the fade condition")
end

local out = assert(io.open(PACK, "w")); out:write(encoded); out:close()
print(("audit ok: 5 earned pips pop at 1.85x over 5 persistent sockets"))
print(("uid continuity: stable=%d retained=%d missing=%d parentSame=%s")
  :format(cont.stable, cont.retained, cont.missing, tostring(cont.parentSame)))
print(("wrote %s (%d auras, %d chars)"):format(PACK, #T.c + 1, #encoded))
