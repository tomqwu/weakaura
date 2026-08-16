-- verify-packs.lua — repo-wide pack integrity and release-contract test.
-- Run: lua5.1 tools/verify-packs.lua   (from the repo root, after scripts/setup.sh)
--
-- Packs are discovered from tbc/*/all-specs.txt. A new pack cannot silently
-- escape verification by being omitted from a hand-maintained registry.

local ROOT = (arg and arg[0] or ""):match("^(.*)[/\\]tools[/\\]") or "."
local SCRIPTS = ROOT .. "/tools/tbc-weakaura-creator/scripts"
local savedArg = arg
arg = { [0] = SCRIPTS .. "/wa_lib.lua" }
local WA = dofile(SCRIPTS .. "/wa_lib.lua")
arg = savedArg

local function quote(s)
  return "'" .. tostring(s):gsub("'", "'\"'\"'") .. "'"
end

local function capture(cmd)
  local p = assert(io.popen(cmd .. " 2>/dev/null", "r"))
  local out = p:read("*a")
  local ok = p:close()
  return out, ok
end

local function read(path)
  local f = io.open(ROOT .. "/" .. path, "r")
  if not f then return nil end
  local s = f:read("*a"); f:close(); return s
end

local function discoverPacks()
  local cmd = "find " .. quote(ROOT .. "/tbc")
    .. " -mindepth 2 -maxdepth 2 -type f -name all-specs.txt -print | sort"
  local out = capture(cmd)
  local packs = {}
  for absolute in out:gmatch("[^\r\n]+") do
    local relative = absolute:gsub("^" .. ROOT:gsub("([^%w])", "%%%1") .. "/", "")
    local name = relative:match("^tbc/([^/]+)/all%-specs%.txt$")
    if name then
      packs[#packs + 1] = {
        name = name,
        txtPath = relative,
        mdPath = "tbc/" .. name .. "/README.md",
        genPath = "tbc/" .. name .. "/generate.lua",
      }
    end
  end
  assert(#packs > 0, "no tbc/*/all-specs.txt packs discovered")
  return packs
end

local fails = {}
local function fail(fmt, ...) fails[#fails + 1] = string.format(fmt, ...) end

local rootReadme = read("README.md") or ""
local idOwner, uidOwner, seedOwner = {}, {}, {}
local totalAuras = 0
local packs = discoverPacks()

local function previousCommittedString(path)
  local diff = capture("git -C " .. quote(ROOT) .. " diff --name-only HEAD -- " .. quote(path))
  local ref
  if diff:match("%S") then
    ref = "HEAD" -- normal pre-commit workflow: compare the worktree to HEAD
  else
    local log = capture("git -C " .. quote(ROOT) .. " log --format=%H -- " .. quote(path))
    local commits = {}
    for hash in log:gmatch("[0-9a-f]+") do commits[#commits + 1] = hash end
    ref = commits[2] -- clean tree/CI: compare the latest shipped revision to its predecessor
  end
  if not ref then return nil end
  local old, ok = capture("git -C " .. quote(ROOT) .. " show " .. quote(ref .. ":" .. path))
  if not ok or old == "" then return nil end
  return old
end

for _, p in ipairs(packs) do
  local s = read(p.txtPath)
  local md = read(p.mdPath)
  local gen = read(p.genPath)
  if not s then
    fail("%s: missing string file %s", p.name, p.txtPath)
  elseif not md then
    fail("%s: missing README %s", p.name, p.mdPath)
  elseif not gen then
    fail("%s: missing build script %s", p.name, p.genPath)
  else
    local okDecode, T = pcall(WA.decode, s)
    if not okDecode then
      fail("%s: decode failed: %s", p.name, tostring(T))
    else
      local okV, err = pcall(WA.verify, T, s)
      if not okV then fail("%s: verify failed: %s", p.name, tostring(err)) end

      local all = { T.d }
      for _, ch in ipairs(T.c or {}) do all[#all + 1] = ch end
      local needsLossOfControlSmokeTest = false
      for _, aura in ipairs(all) do
        if idOwner[aura.id] then
          fail("aura id collision: %q in both %s and %s", aura.id, idOwner[aura.id], p.name)
        else idOwner[aura.id] = p.name end
        if uidOwner[aura.uid] then
          fail("uid collision: %s in both %s and %s", tostring(aura.uid), uidOwner[aura.uid], p.name)
        else uidOwner[aura.uid] = p.name end
        for _, wrapped in ipairs(aura.triggers or {}) do
          if (wrapped.trigger or {}).event == "Crowd Controlled" then
            needsLossOfControlSmokeTest = true
          end
        end
      end
      totalAuras = totalAuras + #all

      local lowerMd = md:lower()
      if needsLossOfControlSmokeTest
         and not (lowerMd:find("live acceptance", 1, true)
           or lowerMd:find("smoke test", 1, true)
           or lowerMd:find("smoke-test", 1, true)
           or lowerMd:find("source cannot prove", 1, true)
           or lowerMd:find("source cannot settle", 1, true)
           or lowerMd:find("field check", 1, true)) then
        fail("%s: Crowd Controlled ships without a live-client acceptance warning", p.name)
      end

      local blocks, found = 0, false
      for block in md:gmatch("```\n(!WA:2![^\n]*)\n```") do
        blocks = blocks + 1
        if block == s then found = true end
      end
      if blocks ~= 1 or not found then
        fail("%s: README must contain exactly one fenced block identical to %s", p.name, p.txtPath)
      end

      local version = md:match("\n## Import string %((v%d+)%)\n")
      if not version then fail("%s: missing final '## Import string (vN)' heading", p.name) end
      local genVersion = gen:match("^[^\n]-%((v%d+)%)") or gen:match("^[^\n]-[Hh][Uu][Dd]%s+(v%d+)")
      if version and genVersion ~= version then
        fail("%s: generator says %s, README ships %s", p.name, tostring(genVersion), version)
      end

      local rootRows = 0
      local rootVersion, rootCount, rootLine
      for line in rootReadme:gmatch("[^\r\n]+") do
        if line:match("^|") and line:find(p.txtPath, 1, true) then
          rootRows = rootRows + 1
          rootVersion, rootCount = line:match("|%s*(v%d+)%s*|%s*(%d+)%s*|")
          rootLine = line
        end
      end
      if rootRows ~= 1 then
        fail("%s: root README must contain exactly one import-table row", p.name)
      elseif version and (rootVersion ~= version or tonumber(rootCount) ~= #all) then
        fail("%s: root row version/count is %s/%s; expected %s/%d",
          p.name, tostring(rootVersion), tostring(rootCount), version, #all)
      elseif version and not rootLine:find("#import-string-" .. version, 1, true) then
        fail("%s: root README copy link does not target %s", p.name, version)
      end

      local seed = gen:match("math%.randomseed%((%d+)%)")
      if not seed then
        fail("%s: generate.lua has no fixed math.randomseed", p.name)
      elseif seedOwner[seed] then
        fail("seed %s is reused by %s and %s", seed, seedOwner[seed], p.name)
      else
        seedOwner[seed] = p.name
        local registry = "| " .. seed .. " | " .. p.name .. " |"
        if not rootReadme:find(registry, 1, true) then
          fail("%s: root seed registry is missing %s", p.name, seed)
        end
      end

      -- DELIBERATE REMOVALS. The default contract is that no uid ever disappears, which
      -- is what makes an in-game re-import an Update. A version that genuinely DELETES a
      -- region breaks it, and the honest fix is not to invent a filler region to absorb
      -- the freed slot — it is to say out loud which auras are going, one id per line, in
      -- the build script that drops them:
      --     -- WA-REMOVED (v12): Mage - Target Cluster
      -- Only entries tagged with the version this pack currently ships are honoured, so
      -- the licence expires by itself at the next version bump rather than standing open
      -- forever. Anything else that vanishes is still a hard failure.
      local removals, removalCount = {}, 0
      for tag, id in gen:gmatch("%-%-%s*WA%-REMOVED%s*%((v%d+)%)%s*:%s*([^\n]-)%s*\n") do
        if version and tag == version and not removals[id] then
          removals[id] = true
          removalCount = removalCount + 1
        end
      end
      local shipped = {}
      for _, aura in ipairs(all) do shipped[aura.id] = true end
      for id in pairs(removals) do
        if shipped[id] then
          fail("%s: %q is declared WA-REMOVED but is still in the shipped string", p.name, id)
        end
      end

      local previous = previousCommittedString(p.txtPath)
      if previous then
        local okCont, cont = pcall(WA.uidContinuityStrings, s, previous)
        if not okCont then
          fail("%s: could not compare previous committed UIDs: %s", p.name, tostring(cont))
        else
          local okAssert, contErr = pcall(WA.assertUidContinuity, cont, p.name,
            removalCount > 0 and removals or nil)
          if not okAssert then fail("%s", tostring(contErr)) end
          if removalCount > 0 then
            print(string.format("  %-14s     %d declared removal(s), %d uid(s) actually gone",
              p.name, removalCount, cont.missing))
          end
        end
      end

      print(string.format("  %-14s ok  version=%-3s auras=%3d chars=%5d",
        p.name, version or "?", #all, #s))
    end
  end
end

-- Seed discipline extends BEYOND tbc/*/generate.lua. Any script in the repo that seeds
-- the uid stream with a shipped pack's seed produces that pack's uids, and WeakAuras
-- matches auras across imports BY uid — so importing its output silently "Update"s over
-- the real pack. This actually happened: the toolkit demo example_paladin.lua carried the
-- rogue pack's seed 20260809 and its six auras collided with six shipped rogue auras.
-- Retired seeds are protected too: a user may still have the retired pack installed.
local retiredSeeds = {}
for seed in rootReadme:gmatch("|%s*(%d+)%s*|%s*%*retired%*") do retiredSeeds[seed] = true end

local otherScripts = capture("find " .. quote(ROOT)
  .. " -name '*.lua' -not -path '*/.git/*' -not -path '*/tbc/*/generate.lua' -print | sort")
for absolute in otherScripts:gmatch("[^\r\n]+") do
  local relative = absolute:gsub("^" .. ROOT:gsub("([^%w])", "%%%1") .. "/", "")
  local body = read(relative)
  if body then
    for seed in body:gmatch("math%.randomseed%((%d+)%)") do
      if seedOwner[seed] then
        fail("%s seeds the uid stream with %s, which belongs to the %s pack — its output "
          .. "would import as an Update over that pack", relative, seed, seedOwner[seed])
      elseif retiredSeeds[seed] then
        fail("%s uses retired seed %s; users may still have that pack installed", relative, seed)
      end
    end
  end
end

print(string.format("\n%d discovered packs, %d auras, %d unique ids",
  #packs, totalAuras, totalAuras))

if #fails > 0 then
  print("\nFAILURES:")
  for _, message in ipairs(fails) do print("  ! " .. message) end
  os.exit(1)
end
print("PASS: structure, history, metadata, README blocks, and cross-pack uniqueness")
