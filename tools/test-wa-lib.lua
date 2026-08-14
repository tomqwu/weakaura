-- Regression tests for verifier failure paths. Positive pack verification alone
-- cannot prove that a malformed structure or broken UID history is rejected.

local ROOT = (arg and arg[0] or ""):match("^(.*)[/\\]tools[/\\]") or "."
local tool = ROOT .. "/tools/tbc-weakaura-creator/scripts/wa_lib.lua"
local savedArg = arg
arg = { [0] = tool }
local W = dofile(tool)
arg = savedArg

local f = assert(io.open(ROOT .. "/tbc/paladin/all-specs.txt", "r"))
local encoded = f:read("*a"); f:close()

-- A child must be listed by the same group named in child.parent.
local malformed = W.decode(encoded)
local groups = {}
for _, aura in ipairs(malformed.c) do
  if aura.regionType == "group" or aura.regionType == "dynamicgroup" then
    groups[#groups + 1] = aura
  end
end
local child
for _, aura in ipairs(malformed.c) do
  if aura.parent == groups[1].id and not aura.controlledChildren then child = aura; break end
end
assert(child and groups[2], "test fixture has no movable child")
child.parent = groups[2].id
local badStructure = W.encode(malformed)
local accepted = pcall(W.verify, malformed, badStructure)
assert(not accepted, "W.verify accepted contradictory parent/controlledChildren wiring")

-- A same-id UID change must fail continuity, even if the new UID is unique.
local changed = W.decode(encoded)
changed.c[1].uid = "AuditUidBad"
local badUid = W.encode(changed)
local cont = W.uidContinuityStrings(badUid, encoded)
local continuityAccepted = pcall(W.assertUidContinuity, cont, "negative-test")
assert(not continuityAccepted and cont.changed == 1 and cont.missing == 1,
  "UID continuity did not reject a replaced existing UID")

print("PASS: verifier rejects parent mismatches and historical UID replacement")
