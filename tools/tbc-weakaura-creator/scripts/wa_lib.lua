-- wa_lib.lua — WeakAuras import-string toolkit (encode/decode/verify)
-- Replicates WeakAuras Transmission.lua exactly (verified against WA source).
-- Requires LibDeflate.lua + LibSerialize.lua next to this file (run setup.sh).

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local LibDeflate = dofile(dir .. "/LibDeflate.lua")
local LibSerialize = dofile(dir .. "/LibSerialize.lua")

local M = { LibDeflate = LibDeflate, LibSerialize = LibSerialize }

-- ---------- table utils ----------
function M.deepcopy(t)
  if type(t) ~= "table" then return t end
  local r = {}
  for k, v in pairs(t) do r[k] = M.deepcopy(v) end
  return r
end

local function sortedKeys(t)
  local ks = {}
  for k in pairs(t) do ks[#ks + 1] = k end
  table.sort(ks, function(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then return ta < tb end
    if ta == "number" then return a < b end
    return tostring(a) < tostring(b)
  end)
  return ks
end

function M.ser(v, indent)
  indent = indent or ""
  local t = type(v)
  if t == "table" then
    local parts = { "{\n" }
    for _, k in ipairs(sortedKeys(v)) do
      local key
      if type(k) == "string" and k:match("^[%a_][%w_]*$") then key = k .. " = "
      else key = "[" .. (type(k) == "string" and string.format("%q", k) or tostring(k)) .. "] = " end
      parts[#parts + 1] = indent .. "  " .. key .. M.ser(v[k], indent .. "  ") .. ",\n"
    end
    parts[#parts + 1] = indent .. "}"
    return table.concat(parts)
  elseif t == "string" then
    return string.format("%q", v)
  else
    return tostring(v)
  end
end

-- ---------- UIDs ----------
-- WA UIDs: 11 chars from this alphabet. CRITICAL: seed math.randomseed with a
-- FIXED per-pack seed and never reorder/remove uid() calls between versions —
-- identical UIDs are what make re-imports show "Update" instead of duplicating.
-- New auras must consume NEW uid() calls appended AFTER all existing ones.
local B64 = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789()"
function M.uid()
  local s = {}
  for i = 1, 11 do local n = math.random(1, 64); s[i] = B64:sub(n, n) end
  return table.concat(s)
end

-- ---------- encode / decode (exact WA pipeline) ----------
-- transmit envelope: { m="d", d=<parent data>, c=<flat child list>, v=<1421|2000>, s="3.5.0" }
--   v=1421: single-level group. Strip parent/controlledChildren from every table;
--           WA rebuilds them from the order of c on import.
--   v=2000: nested groups. KEEP parent + controlledChildren on every table;
--           c must list all descendants depth-first (parent's CC order, recursing).
function M.encode(transmit)
  local serialized = LibSerialize:SerializeEx({ errorOnUnserializableType = false }, transmit)
  local compressed = LibDeflate:CompressDeflate(serialized, { level = 9 })
  return "!WA:2!" .. LibDeflate:EncodeForPrint(compressed)
end

function M.decode(str)
  str = str:gsub("%s", "")
  assert(str:sub(1, 6) == "!WA:2!", "not a !WA:2! string")
  local compressed = LibDeflate:DecodeForPrint(str:sub(7))
  assert(compressed, "DecodeForPrint failed")
  local serialized = LibDeflate:DecompressDeflate(compressed)
  assert(serialized, "DecompressDeflate failed")
  local ok, data = LibSerialize:Deserialize(serialized)
  assert(ok, "Deserialize failed")
  return data
end

-- ---------- verification (run before delivering ANY string) ----------
local function deepeq(a, b, path)
  if type(a) ~= type(b) then return false, path end
  if type(a) ~= "table" then
    if a ~= b then return false, path end
    return true
  end
  for k, v in pairs(a) do
    local ok, p = deepeq(v, b[k], path .. "." .. tostring(k))
    if not ok then return false, p end
  end
  for k in pairs(b) do
    if a[k] == nil then return false, path .. "." .. tostring(k) end
  end
  return true
end

-- Verifies: round-trip fidelity, unique ids/uids, parent refs resolve,
-- controlledChildren complete & duplicate-free. Errors out loudly on failure.
function M.verify(transmit, encoded)
  local back = M.decode(encoded)
  local ok, where = deepeq(transmit, back, "root")
  assert(ok, "round-trip mismatch at " .. tostring(where))

  local ids, uids = { [back.d.id] = true }, { [back.d.uid] = true }
  for _, ch in ipairs(back.c or {}) do
    assert(not ids[ch.id], "duplicate id: " .. ch.id)
    assert(not uids[ch.uid], "duplicate uid: " .. tostring(ch.uid))
    ids[ch.id], uids[ch.uid] = true, true
  end
  if (transmit.v or 1421) >= 2000 then
    for _, ch in ipairs(back.c or {}) do
      assert(ids[ch.parent], "unresolved parent on " .. ch.id .. ": " .. tostring(ch.parent))
    end
    local listed = {}
    local function walk(t)
      for _, cid in ipairs(t.controlledChildren or {}) do
        assert(ids[cid], "controlledChildren references missing id: " .. cid)
        assert(not listed[cid], "id listed twice in controlledChildren: " .. cid)
        listed[cid] = true
      end
    end
    walk(back.d)
    for _, ch in ipairs(back.c) do walk(ch) end
    local n = 0; for _ in pairs(listed) do n = n + 1 end
    assert(n == #back.c, ("controlledChildren covers %d of %d children"):format(n, #back.c))
  end
  return true
end

-- Compares uids of a new build against the previous version's string.
-- Same id must keep the same uid, or the in-game Update flow breaks.
function M.uidContinuity(encoded, prevPath)
  local f = io.open(prevPath, "r")
  if not f then return nil end
  local old = M.decode(f:read("*a")); f:close()
  local new = M.decode(encoded)
  local oldById = {}
  for _, ch in ipairs(old.c or {}) do oldById[ch.id] = ch.uid end
  local stable, changed = 0, 0
  for _, ch in ipairs(new.c or {}) do
    if oldById[ch.id] then
      if oldById[ch.id] == ch.uid then stable = stable + 1 else changed = changed + 1 end
    end
  end
  return { stable = stable, changed = changed, parentSame = old.d.uid == new.d.uid }
end

return M
