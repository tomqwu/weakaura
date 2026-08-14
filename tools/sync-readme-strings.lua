-- sync-readme-strings.lua — refresh final README import blocks from all-specs.txt.
-- Run after a generator changes a shipped string:
--   lua5.1 tools/sync-readme-strings.lua [pack]

local ROOT = (arg and arg[0] or ""):match("^(.*)[/\\]tools[/\\]") or "."
local only = arg and arg[1]

local function quote(s)
  return "'" .. tostring(s):gsub("'", "'\"'\"'") .. "'"
end

local function read(path)
  local f = assert(io.open(path, "r"))
  local value = f:read("*a"); f:close(); return value
end

local function write(path, value)
  local f = assert(io.open(path, "w"))
  f:write(value); f:close()
end

local cmd = "find " .. quote(ROOT .. "/tbc")
  .. " -mindepth 2 -maxdepth 2 -type f -name all-specs.txt -printf '%h\\n' | sort"
local pipe = assert(io.popen(cmd, "r"))
local synced = 0
for directory in pipe:lines() do
  local name = directory:match("([^/]+)$")
  if not only or name == only then
    local txtPath, mdPath = directory .. "/all-specs.txt", directory .. "/README.md"
    local encoded, markdown = read(txtPath), read(mdPath)
    assert(markdown:match("\n## Import string %(v%d+%)\n"), name .. ": missing versioned import heading")
    local count
    markdown, count = markdown:gsub("```%s*\n!WA:2![^\n]*\n```%s*$",
      "```\n" .. encoded .. "\n```\n")
    assert(count == 1, name .. ": expected one final import block, replaced " .. count)
    write(mdPath, markdown)
    synced = synced + 1
    print(("  %-14s synced %d chars"):format(name, #encoded))
  end
end
pipe:close()
assert(synced > 0, "no matching packs")
