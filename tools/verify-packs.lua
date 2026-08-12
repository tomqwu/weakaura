-- verify-packs.lua — repo-wide pack integrity test.
-- Run: lua5.1 tools/verify-packs.lua   (from the repo root, after scripts/setup.sh)
--
-- Checks, for every shipped pack:
--   1. the import string round-trips and is structurally sound (wa_lib.verify)
--   2. the pack README's fenced "## Import string" block is byte-identical to the .txt
--   3. aura ids are globally unique ACROSS packs — WeakAuras requires unique ids, so a
--      collision means the second import silently renames auras
--   4. uids are globally unique ACROSS packs — WA matches auras across imports BY uid, so
--      a collision (two packs sharing a randomseed) makes one pack "Update" over another
-- Exits non-zero with a report on any failure.

local ROOT = (arg and arg[0] or ""):match("^(.*)[/\\]tools[/\\]") or "."
local SCRIPTS = ROOT .. "/tools/tbc-weakaura-creator/scripts"
local savedArg = arg
arg = { [0] = SCRIPTS .. "/wa_lib.lua" }
local WA = dofile(SCRIPTS .. "/wa_lib.lua")
arg = savedArg

-- pack dir, string file, README, version label used in the "## Import string (vN)" heading
local PACKS = {
  { "rogue",        "tbc/rogue/all-specs.txt",       "tbc/rogue/README.md",   "v41" },
  { "paladin-tank", "tbc/paladin/tank-starter.txt",  "tbc/paladin/README.md", "v1"  },
  { "paladin-all",  "tbc/paladin/all-specs.txt",     "tbc/paladin/README.md", "v3"  },
  { "druid",        "tbc/druid/all-specs.txt",       "tbc/druid/README.md",   "v2"  },
  { "warlock",      "tbc/warlock/all-specs.txt",     "tbc/warlock/README.md", "v2"  },
  { "hunter",       "tbc/hunter/all-specs.txt",      "tbc/hunter/README.md",  "v2"  },
  { "priest",       "tbc/priest/all-specs.txt",      "tbc/priest/README.md",  "v2"  },
  { "mage",         "tbc/mage/all-specs.txt",        "tbc/mage/README.md",    "v2"  },
}

local function read(path)
  local f = io.open(ROOT .. "/" .. path, "r")
  if not f then return nil end
  local s = f:read("*a"); f:close(); return s
end

local fails, warns = {}, 0
local function fail(fmt, ...) fails[#fails + 1] = string.format(fmt, ...) end

local idOwner, uidOwner = {}, {}
local totalAuras = 0

for _, p in ipairs(PACKS) do
  local name, txtPath, mdPath = p[1], p[2], p[3]
  local s = read(txtPath)
  if not s then
    fail("%s: missing string file %s", name, txtPath)
  else
    -- 1. structural verification
    local okDecode, T = pcall(WA.decode, s)
    if not okDecode then
      fail("%s: decode failed: %s", name, tostring(T))
    else
      local okV, err = pcall(WA.verify, T, s)
      if not okV then fail("%s: verify failed: %s", name, tostring(err)) end

      -- 3/4. cross-pack uniqueness
      local all = { T.d }
      for _, ch in ipairs(T.c or {}) do all[#all + 1] = ch end
      for _, a in ipairs(all) do
        if idOwner[a.id] then
          fail("aura id collision: %q in both %s and %s", a.id, idOwner[a.id], name)
        else idOwner[a.id] = name end
        if uidOwner[a.uid] then
          fail("uid collision: %s in both %s and %s (packs must use distinct randomseeds)",
               tostring(a.uid), uidOwner[a.uid], name)
        else uidOwner[a.uid] = name end
      end
      totalAuras = totalAuras + #all

      -- 2. README embedded string
      local md = read(mdPath)
      if not md then
        fail("%s: missing README %s", name, mdPath)
      else
        local found = false
        for block in md:gmatch("```\n(!WA:2![^\n]*)\n```") do
          if block == s then found = true break end
        end
        if not found then
          fail("%s: README %s has no fenced code block byte-identical to %s",
               name, mdPath, txtPath)
        end
      end
      print(string.format("  %-14s ok  auras=%3d  chars=%5d", name, #all, #s))
    end
  end
end

print(string.format("\n%d packs, %d auras, %d unique ids, all strings verified",
                    #PACKS, totalAuras, totalAuras))

if #fails > 0 then
  print("\nFAILURES:")
  for _, f in ipairs(fails) do print("  ! " .. f) end
  os.exit(1)
end
print("PASS: structure, README blocks, cross-pack id/uid uniqueness")
