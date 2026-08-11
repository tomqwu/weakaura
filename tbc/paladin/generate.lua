-- generate.lua — Protection Paladin starter pack (tank-starter.txt).
-- Run: lua5.1 generate.lua   (after ../../tools/tbc-weakaura-creator/scripts/setup.sh)

-- FIXED seed per pack; append-only uid order across versions. Seeds must be UNIQUE
-- per pack: two packs sharing a seed generate identical uids, and WA matches auras
-- across imports by uid, so importing both would conflate them. Registry of seeds
-- in use is in the root README.
math.randomseed(20260810)
local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
-- wa_factory/wa_lib resolve their own dependencies (wa_lib.lua, assets/icon_proto.lua)
-- from arg[0], so a bare relative dofile fails for scripts outside scripts/.
-- Point arg[0] at wa_factory.lua for the duration of the load, then restore it.
local SCRIPTS = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local realArg0 = arg and arg[0]
if arg then arg[0] = SCRIPTS .. "/wa_factory.lua" end
local F = dofile(SCRIPTS .. "/wa_factory.lua")
if arg then arg[0] = realArg0 end
local W = F.W

local CLASS = "PALADIN"
local TOP = "Paladin Tank - Starter"
local byId = {}
local function reg(t) byId[t.id] = t; return t end
local function adopt(parent, child)
  child.parent = parent.id
  table.insert(parent.controlledChildren, child.id)
end

-- top-level group, anchored below the character
local top = F.group(TOP, 0, -140, nil)
top.uid = W.uid()

-- 1) Righteous Fury missing (in combat): the tank's "you forgot RF" alarm
local rf = reg(F.icon("Paladin Tank - RF MISSING", CLASS, 48, 48, 0, 60, nil))
rf.triggers = F.triggers({
  F.auraTrigger("player", true, { 25780 }, { matchesShowOn = "showOnMissing" }),
})
rf.iconSource = 0
rf.displayIcon = "Interface\\Icons\\spell_holy_sealoffury"
rf.cooldown = false
rf.subRegions[1] = F.subglow(true, { 1, 0.15, 0.15, 1 })
rf.load.use_combat = true
adopt(top, rf)

-- 2) cooldown row: dynamic group, icons desaturate while on cooldown
local cds = reg(F.dynGroup("Paladin Tank - Cooldowns", 0, -40, nil, "HORIZONTAL", "CENTER", 4))
adopt(top, cds)
local list = {
  { "Holy Shield",    20925 },  -- rank-1 ids: always known, cooldown shared across ranks
  { "Consecration",   26573 },
  { "Avenging Wrath", 31884 },
}
for _, e in ipairs(list) do
  local icon = reg(F.icon("Paladin Tank CD - " .. e[1], CLASS, 32, 32, 0, 0, nil))
  icon.triggers = F.triggers({ F.cdTrigger(e[2], e[1], "showAlways") })
  icon.cooldownTextDisabled = false
  icon.conditions = { F.condition(1, "onCooldown", "==", 1, "desaturate", true) }
  icon.zoom = 0.3
  table.insert(icon.subRegions, F.subborder())
  adopt(cds, icon)
end

-- assemble (v2000 nested), encode, verify, write
local transmit = F.assemble(top, byId)
local encoded = W.encode(transmit)
W.verify(transmit, encoded)

local OUT = dir .. "/tank-starter.txt"
local cont = W.uidContinuity(encoded, OUT)  -- compare BEFORE overwriting the shipped string

local out = io.open(OUT, "w")
out:write(encoded)
out:close()

print(("OK: %d auras, %d chars -> tank-starter.txt"):format(#transmit.c, #encoded))
if cont then
  print(("uid continuity vs previous: stable=%d changed=%d parentSame=%s")
    :format(cont.stable, cont.changed, tostring(cont.parentSame)))
end
