-- rogue v52 -> v53: the HEALTH NUMBER MOVES INTO THE MIDDLE, and the portrait moves BEHIND
-- the rings so it can be read there.
--
-- THE COMPLAINT THIS FIXES. v52 shipped three concentric arcs around a live 3D face with all
-- three percentages parked OUTSIDE the cluster: health 54px below at 13pt, energy 70px below at
-- 10pt, threat 58px above at 10pt. Three small numbers floating on open screen, over whatever
-- the world happens to be rendering behind them, with the largest empty space in the whole HUD —
-- the middle of the cluster — carrying nothing but a portrait. The reported symptom was exactly
-- that: the percentage in the middle cannot be seen. It could not, because there was none.
--
--     HEALTH %  anchorYOffset -54 -> 0     font 13 -> 16   dead centre, over the portrait
--     POWER  %  anchorYOffset -70 -> -54   font 10 -> 12   takes the slot health vacates
--     THREAT %  anchorYOffset  58 (unchanged, font 10)     still above the 100px outer ring
--
-- The power label keeps the token `%p`. It is RAW ENERGY, not a percentage, and it has to stay
-- raw: 35 and 40 are absolute thresholds (Eviscerate, Sinister Strike) and the ring's own
-- breakpoint pips are placed at those absolute values. "62%" would be unactionable next to two
-- marks that mean 35 and 40. Only its position and size change.
--
-- THE NON-OBVIOUS HALF: DRAW ORDER. Moving the offset alone looks like nothing happened.
-- FixGroupChildrenOrder gives each child +4 frame levels in controlledChildren order, so LATER =
-- drawn ON TOP, and v52's cluster ended with the portrait:
--     { Threat Ring, Health Ring, Energy Ring, Threat Flash, Player Portrait }
-- The face therefore covered anything the rings' subtexts put in the middle. v53 makes the
-- portrait the FIRST child, so the rings — and with them their text — draw over it:
--     { Player Portrait, Threat Ring, Health Ring, Energy Ring, Threat Flash }
--
-- WHY THAT DOES NOT BURY THE FACE. A ring is an ANNULUS. Ring_20px's stroke is 20/256 of the
-- drawn size, so the art occupies only its own band and the centre of each ring is empty pixels:
--     threat  100px  r 42.19 .. 50.00
--     health   84px  r 35.44 .. 42.00
--     energy   62px  r 26.16 .. 31.00
--     portrait 44px  r  0.00 .. 22.00
-- Nothing overlaps r <= 22, so promoting three rings above the model hides no part of it. The
-- only thing that lands on the face is the FontString, which is the entire point. The bands and
-- the fit of the 16pt number inside the innermost hole are recomputed from the finished string
-- below, not asserted from these comments.
--
-- REORDERING IS NOT FREE BOOKKEEPING. `c` must list every descendant depth-first in each
-- parent's controlledChildren order, so the child list is reordered WITH the group's. v52 left
-- these two disagreeing inside the cluster (c said health, face, energy, threat, flash while
-- controlledChildren said threat, health, energy, flash, face); v53 makes the whole transmit
-- depth-first consistent and asserts it for every group in the pack, not just this one.
--
-- NO uid() IS CALLED. Reordering children consumes nothing from the random stream and adds and
-- removes no aura, so math.randomseed and the uid() call order are untouched: 58 auras in, 58
-- out, every uid stable, missing = 0 — the v52 removal licence has expired and this step needs
-- none. The pack seed stays 20260809.
--
-- WHAT THIS PATCH MAY NOT TOUCH: the text tokens (%percenthealth%%, %p, %threatpct%%) and their
-- colours, every OUTLINE and shadow setting, the 35/40 energy pips and the sub.4/sub.5 condition
-- indexes that drive them, every trigger, load gate, condition, size and position in the pack.
-- All of it is compared field by field against v52 at the bottom; only two subtext offsets, two
-- font sizes and one child order may differ.
--
-- Run: lua5.1 tbc/rogue/patch-v53.lua   (rewrites all-specs.txt in place)

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local SCRIPTS = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local PACK = dir .. "/all-specs.txt"
local savedArg = arg
arg = { [0] = SCRIPTS .. "/wa_lib.lua" }
local W = dofile(SCRIPTS .. "/wa_lib.lua")
arg = savedArg

-- ===== geometry, unchanged from v52 =====================================================
local MEDIA       = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\"
local RING_TEX    = MEDIA .. "Ring_20px.tga"
local THREAT_RING = 100
local OUTER       = 84
local INNER       = 62
local PORTRAIT    = 44
local CLUSTER_X   = -270
local CLUSTER_Y   = 40
local STROKE      = 20 / 256  -- Ring_20px stroke as a fraction of the drawn size

-- ===== the labels: before -> after ======================================================
local PCT_HEALTH_Y_BEFORE, PCT_HEALTH_Y = -54, 0
local PCT_HEALTH_SIZE_BEFORE, PCT_HEALTH_SIZE = 13, 16
local PCT_POWER_Y_BEFORE, PCT_POWER_Y = -70, -54
local PCT_POWER_SIZE_BEFORE, PCT_POWER_SIZE = 10, 12
local PCT_THREAT_Y, PCT_THREAT_SIZE = 58, 10

local TOK_HEALTH, TOK_POWER, TOK_THREAT = "%percenthealth%%", "%p", "%threatpct%%"

-- An upper bound on Friz Quadrata's advance width as a fraction of the font size, used only to
-- prove the centred number fits the hole. Generous on purpose: the real digits are narrower.
local ADVANCE  = 0.60
local WIDEST   = 4    -- "100%" — the widest string %percenthealth%% can produce

local PLAYER_GROUP = "Rogue - Player Cluster"
local RES_GROUP    = "Rogue - Resources"
local THREAT       = "Rogue - Threat Ring"
local FLASH        = "Rogue - Threat Flash"
local HEALTH       = "Rogue - Health Ring"
local ENERGY       = "Rogue - Energy Ring"
local FACE         = "Rogue - Player Portrait"

local ORDER_V52 = { THREAT, HEALTH, ENERGY, FLASH, FACE }
local ORDER_V53 = { FACE, THREAT, HEALTH, ENERGY, FLASH }

-- ===== helpers ==========================================================================
local function iseq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not iseq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

local function indexOf(list, value)
  for i, v in ipairs(list) do if v == value then return i end end
  return nil
end

-- ===== read the v52 build ===============================================================
local f = assert(io.open(PACK, "r")); local src = f:read("*a"); f:close()
local T = W.decode(src)
local OLD = W.decode(src)

local byId = { [T.d.id] = T.d }
local oldById = { [OLD.d.id] = OLD.d }
for _, aura in ipairs(T.c) do byId[aura.id] = aura end
for _, aura in ipairs(OLD.c) do oldById[aura.id] = aura end

-- ===== the exact v52 state this patch expects ===========================================
local V52 = {
  [THREAT] = { kind = "progresstexture", size = THREAT_RING },
  [HEALTH] = { kind = "progresstexture", size = OUTER },
  [ENERGY] = { kind = "progresstexture", size = INNER },
  [FLASH]  = { kind = "texture",         size = THREAT_RING },
  [FACE]   = { kind = "model",           size = PORTRAIT },
}
for id, want in pairs(V52) do
  local aura = assert(byId[id], "v52 state missing: " .. id)
  assert(aura.parent == PLAYER_GROUP, id .. " does not hang off the player cluster")
  assert(aura.regionType == want.kind, id .. " is not a " .. want.kind)
  assert(aura.width == want.size and aura.height == want.size,
    ("%s is %sx%s, expected %d"):format(id, tostring(aura.width), tostring(aura.height), want.size))
end
local playerGroup = assert(byId[PLAYER_GROUP], "the player cluster is missing")
assert(iseq(playerGroup.controlledChildren, ORDER_V52),
  "the v52 cluster is not threat / health / energy / halo / face — re-derive this patch")
assert(playerGroup.controlledChildren[#ORDER_V52] == FACE,
  "the portrait is not v52's last child, so there is nothing to promote")

local healthLabel = byId[HEALTH].subRegions[1]
local powerLabel  = byId[ENERGY].subRegions[1]
local threatLabel = byId[THREAT].subRegions[1]
assert(#byId[HEALTH].subRegions == 1, "the health ring is not the single-label region v52 shipped")
assert(#byId[ENERGY].subRegions == 5, "the energy ring lost its four 35/40 breakpoint pips")
assert(#byId[THREAT].subRegions == 1, "the threat ring is not the single-label region v52 shipped")
assert(healthLabel.type == "subtext" and healthLabel.text_text == TOK_HEALTH
  and healthLabel.anchorYOffset == PCT_HEALTH_Y_BEFORE
  and healthLabel.text_fontSize == PCT_HEALTH_SIZE_BEFORE,
  "the health percentage is not the 13pt label at -54 this patch moves")
assert(powerLabel.type == "subtext" and powerLabel.text_text == TOK_POWER
  and powerLabel.anchorYOffset == PCT_POWER_Y_BEFORE
  and powerLabel.text_fontSize == PCT_POWER_SIZE_BEFORE,
  "the energy readout is not the 10pt %p label at -70 this patch moves")
assert(threatLabel.type == "subtext" and threatLabel.text_text == TOK_THREAT
  and threatLabel.anchorYOffset == PCT_THREAT_Y
  and threatLabel.text_fontSize == PCT_THREAT_SIZE,
  "the threat percentage is not the 10pt label at +58 this patch leaves alone")

-- ===== the edit: two labels move, the portrait goes to the back =========================
healthLabel.anchorYOffset, healthLabel.text_fontSize = PCT_HEALTH_Y, PCT_HEALTH_SIZE
powerLabel.anchorYOffset,  powerLabel.text_fontSize  = PCT_POWER_Y,  PCT_POWER_SIZE

playerGroup.controlledChildren = { unpack(ORDER_V53) }

-- `c` is the wire order and must stay depth-first in each parent's controlledChildren order,
-- so the flat child list is reordered WITH the group. Only the five cluster entries move
-- relative to each other; every other aura keeps its place.
do
  local rank, slot = {}, {}
  for i, id in ipairs(ORDER_V53) do rank[id] = i end
  for i, aura in ipairs(T.c) do
    if rank[aura.id] then slot[#slot + 1] = i end
  end
  assert(#slot == #ORDER_V53, "the cluster's five regions are not all in the child list")
  local ordered = {}
  for _, id in ipairs(ORDER_V53) do ordered[#ordered + 1] = byId[id] end
  for i, index in ipairs(slot) do T.c[index] = ordered[i] end
end

-- ===== verify ===========================================================================
local encoded = W.encode(T)
W.verify(T, encoded)
local cont = W.uidContinuityStrings(encoded, src)
W.assertUidContinuity(cont, "rogue v53")
assert(cont.changed == 0, "rogue v53: an existing id changed uid")
assert(cont.missing == 0, "rogue v53: a uid disappeared, and v53 removes nothing")
assert(cont.parentSame, "rogue v53: the top-level uid changed")
assert(cont.oldCount == cont.newCount, "rogue v53: the aura count moved")
assert(cont.stable == cont.newCount, "rogue v53: an aura did not keep both its id and its uid")

local NEW = W.decode(encoded)
local newById = { [NEW.d.id] = NEW.d }
for _, aura in ipairs(NEW.c) do newById[aura.id] = aura end

-- AUDIT 1: the three labels, read back out of the ENCODED string.
do
  local h = newById[HEALTH].subRegions[1]
  local p = newById[ENERGY].subRegions[1]
  local t = newById[THREAT].subRegions[1]
  assert(h.anchorYOffset == 0 and h.text_fontSize == 16,
    ("the health label is at %s pt %s, not dead centre at 16pt")
      :format(tostring(h.anchorYOffset), tostring(h.text_fontSize)))
  assert(h.anchorXOffset == 0 and h.text_anchorPoint == "CENTER",
    "the health label is not centred on its ring")
  assert(p.anchorYOffset == PCT_POWER_Y and p.text_fontSize == PCT_POWER_SIZE,
    ("the power label is at %s pt %s, not -54 at 12pt")
      :format(tostring(p.anchorYOffset), tostring(p.text_fontSize)))
  assert(t.anchorYOffset == PCT_THREAT_Y and t.text_fontSize == PCT_THREAT_SIZE,
    "the threat label moved, and v53 leaves it exactly where v52 put it")
  -- tokens, colours, outline and shadow are untouched; so is every other subtext key
  assert(h.text_text == TOK_HEALTH and p.text_text == TOK_POWER and t.text_text == TOK_THREAT,
    "a text token changed")
  assert(p.text_text == "%p", "the power label stopped being raw energy")
  for _, pair in ipairs({ { HEALTH, "anchorYOffset", "text_fontSize" },
                          { ENERGY, "anchorYOffset", "text_fontSize" } }) do
    local was = oldById[pair[1]].subRegions[1]
    local now = newById[pair[1]].subRegions[1]
    for key, value in pairs(was) do
      if key ~= pair[2] and key ~= pair[3] then
        assert(iseq(value, now[key]), pair[1] .. ": the label changed " .. key)
      end
    end
    for key in pairs(now) do assert(was[key] ~= nil, pair[1] .. ": the label gained " .. key) end
    assert(now.text_fontType == "OUTLINE", pair[1] .. ": the label lost its outline")
    assert(iseq(now.text_shadowColor, was.text_shadowColor)
      and now.text_shadowXOffset == was.text_shadowXOffset
      and now.text_shadowYOffset == was.text_shadowYOffset, pair[1] .. ": the shadow changed")
    assert(iseq(now.text_color, was.text_color), pair[1] .. ": the label colour changed")
  end
  assert(iseq(oldById[THREAT].subRegions[1], t), "the threat label is not byte-identical to v52")
  -- the 35/40 pips and the sub.4/sub.5 indexes that drive them
  for i = 2, 5 do
    assert(iseq(oldById[ENERGY].subRegions[i], newById[ENERGY].subRegions[i]),
      ("energy sub.%d changed; the breakpoint pips are not this patch's business"):format(i))
  end
  local drives = {}
  for _, cond in ipairs(newById[ENERGY].conditions or {}) do
    for _, change in ipairs(cond.changes) do drives[change.property] = true end
  end
  assert(drives["sub.4.textureVisible"] and drives["sub.5.textureVisible"],
    "the 35/40 conditions no longer address sub.4 / sub.5")
end

-- AUDIT 2: draw order — the portrait is FIRST and every ring is strictly after it, in both the
-- group's child list and the wire order, and `c` is depth-first across the WHOLE pack.
do
  local cc = newById[PLAYER_GROUP].controlledChildren
  assert(iseq(cc, ORDER_V53), "the cluster order is not face / threat / health / energy / halo")
  assert(cc[1] == FACE, "the portrait is not the first child, so it still draws over the numbers")
  local faceAt = indexOf(cc, FACE)
  for _, ring in ipairs({ THREAT, HEALTH, ENERGY, FLASH }) do
    assert(indexOf(cc, ring) > faceAt, ring .. " draws behind the portrait")
  end
  local expected, seen = {}, {}
  local function walk(node)
    for _, id in ipairs(node.controlledChildren or {}) do
      assert(not seen[id], "controlledChildren lists " .. id .. " twice")
      seen[id] = true
      expected[#expected + 1] = id
      walk(assert(newById[id], "unresolved child " .. id))
    end
  end
  walk(NEW.d)
  assert(#expected == #NEW.c,
    ("depth-first walk covers %d of %d children"):format(#expected, #NEW.c))
  for i, id in ipairs(expected) do
    assert(NEW.c[i].id == id,
      ("c is not depth-first at %d: %s, expected %s"):format(i, NEW.c[i].id, id))
  end
  local faceWire, ringWire = indexOf(expected, FACE), indexOf(expected, THREAT)
  assert(faceWire < ringWire, "the wire order still puts the portrait after the rings")
end

-- AUDIT 3: the annulus argument, recomputed — no ring's art reaches the middle, so promoting
-- the rings above the model hides no part of the face, and the 16pt number fits the hole.
do
  local bands = {
    { id = THREAT, size = THREAT_RING },
    { id = HEALTH, size = OUTER },
    { id = ENERGY, size = INNER },
  }
  local hole = math.huge
  for _, band in ipairs(bands) do
    local region = newById[band.id]
    assert(region.width == band.size and region.height == band.size, band.id .. " changed size")
    assert(region.foregroundTexture == RING_TEX and region.backgroundTexture == RING_TEX,
      band.id .. " is not drawn on the canonical ring art, so its stroke width is unknown")
    local outer = band.size / 2
    local inner = outer - band.size * STROKE
    assert(inner > PORTRAIT / 2,
      ("%s reaches r=%.2f and would cover the %dpx portrait"):format(band.id, inner, PORTRAIT))
    hole = math.min(hole, inner)
    print(("  %-22s r %6.2f .. %6.2f"):format(band.id, inner, outer))
  end
  print(("  %-22s r %6.2f .. %6.2f"):format(FACE, 0, PORTRAIT / 2))
  -- the centred health number lives inside the innermost hole
  local halfWidth = WIDEST * ADVANCE * PCT_HEALTH_SIZE / 2
  local halfHeight = PCT_HEALTH_SIZE / 2
  assert(halfWidth < hole and halfHeight < hole,
    ("a %dpt %d-glyph number is %.1f x %.1f and does not fit the %.2f hole")
      :format(PCT_HEALTH_SIZE, WIDEST, halfWidth * 2, halfHeight * 2, hole))
  print(("  health number  %.1f x %.1f centred, innermost hole r=%.2f")
    :format(halfWidth * 2, halfHeight * 2, hole))
  -- and the power label clears every ring, in the slot health has just vacated
  assert(PCT_POWER_Y == PCT_HEALTH_Y_BEFORE, "the power label did not take health's old slot")
  assert(math.abs(PCT_POWER_Y) > OUTER / 2, "the power label sits on the health ring")
  assert(PCT_THREAT_Y > THREAT_RING / 2, "the threat label sits inside the outer ring")
end

-- AUDIT 4: nothing moved. Sizes, offsets and the chain-walked absolute position are v52's.
do
  local function absolute(id)
    local x, y = 0, 0
    local node = assert(newById[id], "missing region " .. id)
    while node do
      assert(node.anchorFrameType == "SCREEN" and node.selfPoint == "CENTER"
        and node.anchorPoint == "CENTER", id .. ": " .. node.id .. " is not centre-anchored")
      x, y = x + (node.xOffset or 0), y + (node.yOffset or 0)
      node = node.parent and assert(newById[node.parent], "unresolved parent " .. node.parent)
    end
    return x, y
  end
  for _, id in ipairs({ PLAYER_GROUP, FACE, THREAT, HEALTH, ENERGY, FLASH }) do
    local x, y = absolute(id)
    assert(x == CLUSTER_X and y == CLUSTER_Y,
      ("%s lands at (%d,%d); the cluster is at (%d,%d)"):format(id, x, y, CLUSTER_X, CLUSTER_Y))
    if id ~= PLAYER_GROUP then
      assert(newById[id].xOffset == 0 and newById[id].yOffset == 0,
        id .. " is not concentric in the cluster")
    end
  end
end

-- AUDIT 5: everything else is byte-identical to v52. Exactly three objects may differ — the two
-- moved labels and the cluster's child list — and the aura SET is unchanged.
do
  assert(iseq(OLD.d, NEW.d), "the top-level group changed")
  assert(#OLD.c == #NEW.c, "the aura count changed")
  local oldIds = {}
  for _, aura in ipairs(OLD.c) do oldIds[aura.id] = aura.uid end
  for _, aura in ipairs(NEW.c) do
    assert(oldIds[aura.id] == aura.uid, aura.id .. ": id/uid pair changed or is new")
    oldIds[aura.id] = nil
  end
  assert(next(oldIds) == nil, "an aura disappeared")

  local TOUCHED = { [HEALTH] = true, [ENERGY] = true, [PLAYER_GROUP] = true }
  for _, old in ipairs(OLD.c) do
    local new = newById[old.id]
    if not TOUCHED[old.id] then
      for key in pairs(old) do
        assert(iseq(old[key], new[key]),
          ("%s: %s changed, and v53 only moves two labels and the child order"):format(old.id, key))
      end
      for key in pairs(new) do assert(old[key] ~= nil, old.id .. ": gained field " .. key) end
    end
  end
  for _, id in ipairs({ HEALTH, ENERGY }) do
    local a, b = oldById[id], newById[id]
    for key in pairs(a) do
      if key ~= "subRegions" then assert(iseq(a[key], b[key]), id .. ": " .. key .. " changed") end
    end
    for key in pairs(b) do assert(a[key] ~= nil, id .. ": gained field " .. key) end
    assert(#a.subRegions == #b.subRegions, id .. ": a subregion appeared or vanished")
  end
  do
    local a, b = oldById[PLAYER_GROUP], newById[PLAYER_GROUP]
    for key in pairs(a) do
      if key ~= "controlledChildren" then
        assert(iseq(a[key], b[key]), PLAYER_GROUP .. ": " .. key .. " changed")
      end
    end
    for key in pairs(b) do assert(a[key] ~= nil, PLAYER_GROUP .. ": gained field " .. key) end
    assert(#a.controlledChildren == #b.controlledChildren, PLAYER_GROUP .. ": lost or gained a child")
    for _, id in ipairs(a.controlledChildren) do
      assert(indexOf(b.controlledChildren, id), PLAYER_GROUP .. " dropped " .. id)
    end
  end
  assert(iseq(oldById[RES_GROUP].controlledChildren, newById[RES_GROUP].controlledChildren),
    RES_GROUP .. ": the resources child order changed")
end

local out = assert(io.open(PACK, "w")); out:write(encoded); out:close()
print(("cluster order: %s"):format(table.concat(newById[PLAYER_GROUP].controlledChildren, " -> ")))
print(("labels: health %d@%dpt, power %d@%dpt (%s), threat %d@%dpt")
  :format(PCT_HEALTH_Y, PCT_HEALTH_SIZE, PCT_POWER_Y, PCT_POWER_SIZE, TOK_POWER,
    PCT_THREAT_Y, PCT_THREAT_SIZE))
print(("uid continuity: stable=%d changed=%d retained=%d missing=%d parentSame=%s")
  :format(cont.stable, cont.changed, cont.retained, cont.missing, tostring(cont.parentSame)))
print(("wrote %s (%d auras, %d chars)"):format(PACK, #T.c + 1, #encoded))
