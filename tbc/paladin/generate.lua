-- example_paladin.lua — end-to-end demo: Protection Paladin starter pack.
-- Run: lua5.1 example_paladin.lua   (after ./setup.sh)
-- Produces paladin_starter.txt: a "!WA:2!" string importable in game.

math.randomseed(20260809)  -- FIXED seed per pack; append-only uid order across versions
local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local F = dofile(dir .. "/../../tools/tbc-weakaura-creator/scripts/wa_factory.lua")
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
local rf = reg(F.icon("Paladin - RF MISSING", CLASS, 48, 48, 0, 60, nil))
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
local cds = reg(F.dynGroup("Paladin - Cooldowns", 0, -40, nil, "HORIZONTAL", "CENTER", 4))
adopt(top, cds)
local list = {
  { "Holy Shield",    20925 },  -- rank-1 ids: always known, cooldown shared across ranks
  { "Consecration",   26573 },
  { "Avenging Wrath", 31884 },
}
for _, e in ipairs(list) do
  local icon = reg(F.icon("Paladin CD - " .. e[1], CLASS, 32, 32, 0, 0, nil))
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

local out = io.open(dir .. "/paladin_starter.txt", "w")
out:write(encoded)
out:close()

print(("OK: %d auras, %d chars -> paladin_starter.txt"):format(#transmit.c, #encoded))
local cont = W.uidContinuity(encoded, dir .. "/paladin_starter_prev.txt")
if cont then
  print(("uid continuity vs previous: stable=%d changed=%d parentSame=%s")
    :format(cont.stable, cont.changed, tostring(cont.parentSame)))
end
