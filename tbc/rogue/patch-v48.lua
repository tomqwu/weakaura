-- rogue v47 -> v48: one shared orb geometry across every pack.
--
-- WHY. v47 gave the pack unit orbs, and every pack in the repo grew its own set of ring
-- diameters in its own migration. Seven packs therefore disagreed with each other, and the
-- two clusters inside each pack disagreed too — this pack's player orb topped out at 96px
-- while its target orb ran to 118 (132 counting the threat halo), so the left and right
-- sides of the same HUD were visibly different sizes. That is exactly what "the size uneven,
-- looks bad" describes. v48 adopts the canonical numbers below verbatim in all seven packs.
--
-- WHAT THIS PATCH IS ALLOWED TO TOUCH: region width/height, the ring texture, the two
-- cluster group offsets, the percentage sub-text size/offset, and the four energy tick
-- offsets that are DERIVED from the energy ring's radius. Nothing else. No trigger, no load
-- gate, no condition, no colour, no spell id, no region type, no uid, no aura added or
-- removed — the audit at the bottom proves each of those field by field.
--
-- THE TRAP THIS PATCH EXISTS TO CLEAR. The 35/40 energy breakpoints are `subtexture` marks
-- whose x/y offsets v47 computed from the ENERGY RING'S RADIUS:
--     r = enRing / 2 * TICK_RADIUS,  x = r*sin(2*pi*fraction),  y = r*cos(2*pi*fraction)
-- (angle 0 is 12 o'clock and increases CLOCKWISE, matching the ring's orientation — see the
-- v47 header for the TextureCoords.lua derivation). Those offsets are absolute pixels, NOT a
-- fraction of the region, so resizing the ring alone would leave all four marks orbiting the
-- old 72px circle while the ring redrew at 78px: four marks floating in empty space. They
-- are re-derived from the new radius here and then checked back the other way — radius and
-- angle recovered from the committed offsets — so the proof does not depend on the same
-- arithmetic that produced them.
--
-- RING ART. Ring_20px replaces Ring_10px on all five rings and on the threat halo. Both
-- source textures are 256x256 and the number in the name is the stroke weight in that space,
-- so a ring drawn at S px carries a band of S*20/256: the 10px art at these diameters read
-- as a wire, which was the first thing anyone said about the look.
--
-- THE HALO. v47 sized the >=80% threat halo 14px larger than the threat ring so it pulsed
-- just outside it. ORB_OUTER is now the hard outer bound of a cluster in every pack — that
-- is the whole point of the shared geometry — so the halo takes ORB_OUTER too and pulses
-- ON the threat ring rather than around it. Same trigger, same threshold, same colour, same
-- ADD blend, same alphaPulse: the alarm still lands exactly on the thing it is about.
--
-- Run: lua5.1 tbc/rogue/patch-v48.lua   (rewrites all-specs.txt in place)

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local SCRIPTS = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local PACK = dir .. "/all-specs.txt"
local savedArg = arg
arg = { [0] = SCRIPTS .. "/wa_lib.lua" }
local W = dofile(SCRIPTS .. "/wa_lib.lua")
arg = savedArg

-- ===== canonical orb geometry ========================================================
-- These seven names are the shared contract. Every pack in the repo defines the same
-- constants with the same values; nothing below may hard-code a diameter.
local RING_TEX  = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Ring_20px.tga"
local ORB_OUTER = 104   -- outermost ring, on BOTH clusters, in EVERY pack
local ORB_MID   = 78
local ORB_INNER = 54
local PORTRAIT  = 46
local CLUSTER_X = 260   -- player cluster at -260, target cluster at +260
local CLUSTER_Y = -60   -- offsets of the cluster GROUP, inside `Rogue - Resources`

-- Ring assignment. Both clusters present the same outer diameter and the same portrait;
-- the target simply nests one more ring inside.
--   PLAYER: health ORB_OUTER, energy ORB_MID, portrait PORTRAIT
--   TARGET: threat ORB_OUTER, health ORB_MID, power ORB_INNER, portrait PORTRAIT

-- The percentages ride on their own ring (a `model` region cannot carry text at all), so
-- they are sized and offset by role, not by cluster: the health number sits just under the
-- outer ring on both sides, the power number under it, threat above.
local PCT_MAIN   = { size = 14, y = -60 }   -- health
local PCT_SUB    = { size = 11, y = -76 }   -- power / energy
local PCT_THREAT = { size = 11, y =  60 }   -- threat, above the ring

-- Distance from a ring's centre to its stroke, as a fraction of the outer radius. Carried
-- unchanged from v47: Ring_20px's band runs from 1 - 20/128 = 0.844 of the outer radius to
-- 1.0, so 0.94 still lands inside the stroke — and lands FURTHER inside it than it did on
-- the thinner 10px art. Asserted numerically below rather than argued.
local TICK_RADIUS = 0.94

-- ===== the exact v47 state this patch expects =========================================
-- Asserted before anything is written, so the lineage cannot silently apply to the wrong
-- input, and so the before/after table is in the build script a reviewer reads.
local RING_10 = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Ring_10px.tga"
local BEFORE = {
  ["Rogue - Player Orb"]      = { x = -300, y = -10 },
  ["Rogue - Health"]          = { size = 96,  tex = RING_10, pct = { size = 12, y = -84 } },
  ["Rogue - Energy"]          = { size = 72,  tex = RING_10, pct = { size = 16, y = -62 } },
  ["Rogue - Player Portrait"] = { size = 28 },
  ["Rogue - Target Orb"]      = { x = 300, y = -10 },
  ["Rogue - Threat Flash"]    = { size = 132, tex = RING_10 },
  ["Rogue - Threat"]          = { size = 118, tex = RING_10, pct = { size = 11, y = 70 } },
  ["Rogue - Target Health"]   = { size = 90,  tex = RING_10, pct = { size = 14, y = -74 } },
  ["Rogue - Target Power"]    = { size = 62,  tex = RING_10 },
  ["Rogue - Target Portrait"] = { size = 28 },
}

local AFTER = {
  ["Rogue - Player Orb"]      = { x = -CLUSTER_X, y = CLUSTER_Y },
  ["Rogue - Health"]          = { size = ORB_OUTER, tex = RING_TEX, pct = PCT_MAIN },
  ["Rogue - Energy"]          = { size = ORB_MID,   tex = RING_TEX, pct = PCT_SUB },
  ["Rogue - Player Portrait"] = { size = PORTRAIT },
  ["Rogue - Target Orb"]      = { x = CLUSTER_X, y = CLUSTER_Y },
  ["Rogue - Threat Flash"]    = { size = ORB_OUTER, tex = RING_TEX },
  ["Rogue - Threat"]          = { size = ORB_OUTER, tex = RING_TEX, pct = PCT_THREAT },
  ["Rogue - Target Health"]   = { size = ORB_MID,   tex = RING_TEX, pct = PCT_MAIN },
  ["Rogue - Target Power"]    = { size = ORB_INNER, tex = RING_TEX },
  ["Rogue - Target Portrait"] = { size = PORTRAIT },
}

-- The energy ring's four breakpoint marks, in subRegions order (v47 appended them 2..5).
-- fraction is the point on the ring; energy is capped at 100 on every rogue, so 35 energy
-- is 0.35 of the ring.
local TICKS = { { i = 2, f = 0.35 }, { i = 3, f = 0.40 }, { i = 4, f = 0.35 }, { i = 5, f = 0.40 } }

-- ===== helpers ========================================================================
local function iseq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not iseq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

-- Byte-identical to v47's rounding, so a mark that does not move keeps its exact literal.
local function round(v) return math.floor(v * 1000 + 0.5) / 1000 end

-- ===== read the v47 build =============================================================
local f = assert(io.open(PACK, "r")); local src = f:read("*a"); f:close()
local T = W.decode(src)
local OLD = W.decode(src)

local byId = {}
for _, aura in ipairs(T.c) do byId[aura.id] = aura end

for id, want in pairs(BEFORE) do
  local aura = assert(byId[id], "v47 orb region missing: " .. id)
  if want.size then
    assert(aura.width == want.size and aura.height == want.size,
      ("%s: expected v47 size %d, found %sx%s"):format(id, want.size,
        tostring(aura.width), tostring(aura.height)))
    local tex = aura.foregroundTexture or aura.texture
    assert(tex == want.tex, id .. ": unexpected v47 texture " .. tostring(tex))
  else
    assert(aura.xOffset == want.x and aura.yOffset == want.y,
      ("%s: expected v47 offset (%d,%d), found (%s,%s)"):format(id, want.x, want.y,
        tostring(aura.xOffset), tostring(aura.yOffset)))
  end
  if want.pct then
    local st = aura.subRegions[1]
    assert(st and st.type == "subtext", id .. ": subRegions[1] is not the percentage text")
    assert(st.text_fontSize == want.pct.size and st.anchorYOffset == want.pct.y,
      id .. ": percentage text is not where v47 put it")
  end
end

local en = byId["Rogue - Energy"]
do  -- the four marks really are on the v47 energy radius, at 35% and 40%
  local r47 = BEFORE["Rogue - Energy"].size / 2 * TICK_RADIUS
  for _, tick in ipairs(TICKS) do
    local sub = assert(en.subRegions[tick.i], "energy mark missing at subRegions " .. tick.i)
    assert(sub.type == "subtexture", "energy subRegions " .. tick.i .. " is not a mark")
    assert(math.abs(math.sqrt(sub.xOffset ^ 2 + sub.yOffset ^ 2) - r47) < 0.002,
      ("energy mark %d is not on the v47 radius %.3f"):format(tick.i, r47))
  end
end

-- ===== apply the canonical geometry ===================================================
for id, want in pairs(AFTER) do
  local aura = byId[id]
  if want.size then
    aura.width, aura.height = want.size, want.size
    if aura.regionType == "progresstexture" then
      aura.foregroundTexture, aura.backgroundTexture = want.tex, want.tex
    elseif aura.regionType == "texture" then
      aura.texture = want.tex
    end
  else
    aura.xOffset, aura.yOffset = want.x, want.y
  end
  if want.pct then
    aura.subRegions[1].text_fontSize = want.pct.size
    aura.subRegions[1].anchorYOffset = want.pct.y
  end
end

-- The marks follow their ring. Same formula as v47, new radius.
local tickR = ORB_MID / 2 * TICK_RADIUS
for _, tick in ipairs(TICKS) do
  local angle = tick.f * 2 * math.pi
  local sub = en.subRegions[tick.i]
  sub.xOffset = round(math.sin(angle) * tickR)
  sub.yOffset = round(math.cos(angle) * tickR)
end

-- ===== verify =========================================================================
local encoded = W.encode(T)
W.verify(T, encoded)
local cont = W.uidContinuityStrings(encoded, src)
W.assertUidContinuity(cont, "rogue v48")
assert(cont.changed == 0 and cont.missing == 0 and cont.oldCount == cont.newCount,
  "rogue v48: this is a geometry pass; no aura may be added, lost or re-uided")

local NEW = W.decode(encoded)
local newById = {}
for _, aura in ipairs(NEW.c) do newById[aura.id] = aura end

-- AUDIT 1: the only fields that may differ, anywhere in the pack. Every other key of every
-- aura — triggers, load, conditions, colours, region type, uid, parent, ordering — must be
-- byte-identical to v47.
local GEOM = { width = true, height = true,
               foregroundTexture = true, backgroundTexture = true, texture = true,
               xOffset = true, yOffset = true }
local TEXT = { text_fontSize = true, anchorYOffset = true, xOffset = true, yOffset = true }

assert(#OLD.c == #NEW.c, "aura count changed")
assert(iseq(OLD.d, NEW.d), "the top-level group changed")
for index, old in ipairs(OLD.c) do
  local new = assert(newById[old.id], "aura disappeared: " .. old.id)
  assert(NEW.c[index].id == old.id, "aura order changed at " .. index)
  local touched = AFTER[old.id] ~= nil
  for key in pairs(old) do
    if key ~= "subRegions" and not (touched and GEOM[key]) then
      assert(iseq(old[key], new[key]), old.id .. ": unexpected v48 change in " .. key)
    end
  end
  for key in pairs(new) do assert(old[key] ~= nil, old.id .. ": unexpected new key " .. key) end
  assert(#(old.subRegions or {}) == #(new.subRegions or {}),
    old.id .. ": subregion count changed")
  for i, oldSub in ipairs(old.subRegions or {}) do
    local newSub = new.subRegions[i]
    assert(oldSub.type == newSub.type, old.id .. ": subregion " .. i .. " changed type")
    for key in pairs(oldSub) do
      if not (touched and TEXT[key]) then
        assert(iseq(oldSub[key], newSub[key]),
          ("%s: unexpected v48 change in subRegions[%d].%s"):format(old.id, i, key))
      end
    end
    for key in pairs(newSub) do
      assert(oldSub[key] ~= nil, old.id .. ": unexpected new subregion key " .. key)
    end
  end
end

-- AUDIT 2: the shipped geometry is the canonical geometry, read back out of the string.
for id, want in pairs(AFTER) do
  local aura = assert(newById[id], "orb region missing: " .. id)
  if want.size then
    assert(aura.width == want.size and aura.height == want.size,
      id .. ": size is not the canonical " .. want.size)
    if aura.regionType == "progresstexture" then
      assert(aura.foregroundTexture == RING_TEX and aura.backgroundTexture == RING_TEX,
        id .. ": still on the old ring art")
    elseif aura.regionType == "texture" then
      assert(aura.texture == RING_TEX, id .. ": still on the old ring art")
    else
      -- the portraits: `model` regions carry no texture at all, only a size
      assert(aura.regionType == "model", id .. ": unexpected region type " .. aura.regionType)
    end
  else
    assert(aura.xOffset == want.x and aura.yOffset == want.y, id .. ": cluster offset drifted")
  end
  if want.pct then
    local st = aura.subRegions[1]
    assert(st.text_fontSize == want.pct.size and st.anchorYOffset == want.pct.y
      and st.text_anchorPoint == "CENTER", id .. ": percentage text is not the canonical one")
  end
end

-- Both clusters present the same outer diameter and the same portrait: the thing the whole
-- pass is for, asserted rather than eyeballed.
assert(newById["Rogue - Health"].width == newById["Rogue - Threat"].width,
  "player and target clusters do not share an outer diameter")
assert(newById["Rogue - Player Portrait"].width == newById["Rogue - Target Portrait"].width,
  "the two portraits are not the same size")
assert(newById["Rogue - Threat Flash"].width == ORB_OUTER,
  "the threat halo escapes the cluster's outer bound")

-- AUDIT 3: every breakpoint mark still lands ON its ring's stroke, at the angle its
-- threshold demands. Radius and angle are recovered FROM the committed offsets, so this
-- catches a mark left behind at the old radius even if the formula above were wrong.
local band = ORB_MID * 20 / 256                 -- Ring_20px stroke at this diameter
local outer, inner = ORB_MID / 2, ORB_MID / 2 - band
assert(tickR <= outer and tickR >= inner,
  ("tick radius %.3f is outside the ring band %.3f..%.3f"):format(tickR, inner, outer))
for _, tick in ipairs(TICKS) do
  local sub = newById["Rogue - Energy"].subRegions[tick.i]
  local r = math.sqrt(sub.xOffset ^ 2 + sub.yOffset ^ 2)
  local fraction = math.atan2(sub.xOffset, sub.yOffset) / (2 * math.pi)
  if fraction < 0 then fraction = fraction + 1 end
  assert(math.abs(r - tickR) < 0.002,
    ("energy mark %d sits at radius %.3f, ring radius is %.3f"):format(tick.i, r, tickR))
  assert(math.abs(fraction - tick.f) < 0.0001,
    ("energy mark %d sits at %.4f of the ring, expected %.2f"):format(tick.i, fraction, tick.f))
end

local out = assert(io.open(PACK, "w")); out:write(encoded); out:close()
print(("audit ok: rings %d/%d/%d, portrait %d, clusters at +-%d, %d ticks re-derived at r=%.3f")
  :format(ORB_OUTER, ORB_MID, ORB_INNER, PORTRAIT, CLUSTER_X, #TICKS, tickR))
print(("uid continuity: stable=%d changed=%d retained=%d missing=%d parentSame=%s")
  :format(cont.stable, cont.changed, cont.retained, cont.missing, tostring(cont.parentSame)))
print(("wrote %s (%d auras, %d chars)"):format(PACK, #T.c + 1, #encoded))
