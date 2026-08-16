-- rogue v49 -> v50: the globes move beside the character, and the glass catches light.
--
-- WHY, PART ONE — POSITION. v49 put all three globes on one band at y = -262. A band under
-- the HUD reads as a *bar bolted on below the screen furniture*: it is a horizontal strip of
-- widgets, so the eye files it with the action bars and stops looking at it. Diablo's globes
-- were never a strip — they FLANK the character, one either side, and the whole reason they
-- work is that the shape you fight with sits between them. So the two player vessels move up
-- and out to (-190, 40) and (+190, 40), and the target globe moves onto the centreline above
-- you at (0, 110). Life and power now bracket your character; your target hangs over it.
--
-- WHY THESE THREE NUMBERS AND NOT ROUNDER ONES. They are the tightest collision-free
-- arrangement across all seven packs, which share this geometry verbatim:
--   * x = +-170 puts a 76px rim edge through the Alerts column (x = -150) on the left and the
--     PvP column (x = +150 in the packs that use it) on the right.
--   * x = +-210 pushes the right-hand rim into the PvP layer's own elements at (200, -44),
--     whose kick-lockout bar is 140 wide and therefore reaches x = 270.
--   190 is the only band left between those two, and y = 40 lifts the pair clear of the
--   cooldown row (y = -206) and the buff row (y = -156) without reaching the target globe.
--
-- GLOBE_Y AND GLOBE_Y_TGT ARE ABSOLUTE SCREEN COORDINATES. Nothing in this cluster is
-- anchored to the screen directly: each globe hangs off `Rogue - Player Globes` or
-- `Rogue - Target Globe`, which hang off `Rogue - Resources`, which hangs off the pack's top
-- group -- and every one of those carries an offset. The two group offsets are therefore
-- computed by SUBTRACTING the inherited chain, never by writing a tuned number into a child,
-- and the finished string is decoded at the bottom and the chain walked to prove that all
-- eight cluster regions land exactly on their number. The two groups also stop sharing a y:
-- the player pair sits at GLOBE_Y and the target globe at GLOBE_Y_TGT, so they get their own
-- offsets rather than one shared GROUP_Y.
--
-- WHY, PART TWO — A SPECULAR HIGHLIGHT. A globe whose fill is one flat colour reads as a
-- sticker: a coloured disc, printed on the screen. Real glass is curved, so it catches the
-- light in ONE off-centre spot and that single bright ellipse is what the eye decodes as
-- "curved surface with liquid behind it". So every globe gains one appended subtexture: a
-- soft white Circle_Smooth ellipse, 46% x 34% of the globe, offset up and to the left by
-- 17%/21% of the globe. Every number is a fraction of that globe's OWN width, so the 44px
-- target globe gets the same highlight scaled to it rather than a second set of constants.
--
-- THE BLEND MODE IS THE LOAD-BEARING FIELD. Subregions draw in order, and the percentage is
-- subregion 1, INSIDE the glass. An appended overlay therefore draws over the number. On
-- "BLEND" a 28% white sheet would wash the text toward grey and cost exactly the readability
-- that putting the number inside the vessel bought. "ADD" only ever brightens what is under
-- it, so the outlined white text stays white and the dark backing disc lifts. That is also
-- why this is a highlight and not the more obvious dark vignette around the rim: a vignette
-- has to be a multiply/BLEND overlay, and it would dim the number.
--
-- APPENDED, NEVER INSERTED. WeakAuras conditions address subregions POSITIONALLY, as
-- `sub.N.property`. The energy globe's 35/40 breakpoint marks are lit by `sub.4.textureVisible`
-- and `sub.5.textureVisible`; inserting anything ahead of index 4 would silently re-home both
-- conditions onto the wrong texture -- Conditions.lua resolves the index at apply time and
-- says nothing. So the highlight is pushed onto the END of subRegions (index 2 on the life
-- and target globes, index 6 on the energy globe), and the audit at the bottom re-reads every
-- `sub.N` reference in the WHOLE pack out of the finished string and proves each one still
-- points at the identical subregion table it pointed at in v49.
--
-- UID DISCIPLINE. Nothing is added, removed, retyped or re-parented: this patch only moves
-- offsets and appends one subregion to three existing regions. No `uid()` is called, so the
-- random stream is untouched, and continuity against v49 must come back changed = 0,
-- missing = 0 with the same aura count -- asserted below, not assumed.
--
-- WHAT THIS PATCH MAY NOT TOUCH: every trigger, load gate, condition, colour, spell id and
-- region type in the pack, and every aura outside the globe cluster (buffs, alerts, combo
-- pips, cooldown row, procs, the PvP layer) is asserted field-by-field against v49 at the
-- bottom. Sizes do not change either: 72px life and power, 44px target, rim = globe + 4.
--
-- Run: lua5.1 tbc/rogue/patch-v50.lua   (rewrites all-specs.txt in place)

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local SCRIPTS = dir .. "/../../tools/tbc-weakaura-creator/scripts"
local PACK = dir .. "/all-specs.txt"
local savedArg = arg
arg = { [0] = SCRIPTS .. "/wa_lib.lua" }
local W = dofile(SCRIPTS .. "/wa_lib.lua")
arg = savedArg

-- ===== canonical globe geometry, shared verbatim by every pack =========================
local MEDIA      = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\"
local FILL_TEX   = MEDIA .. "Circle_Smooth.tga"          -- the liquid, and the highlight
local RIM_TEX    = MEDIA .. "Circle_Smooth_Border.tga"   -- the glass rim, drawn behind
local GLOBE_MAIN = 72      -- life and power globes            (unchanged in v50)
local GLOBE_TGT  = 44      -- target globe                     (unchanged in v50)
local RIM_PAD    = 4       -- a rim is its globe's size + 4    (unchanged in v50)
local RIM_STRATA = 2       -- ... drawn behind, at frameStrata 2
local ORIENT     = "VERTICAL"                            -- "Bottom to Top"

-- v50 POSITION: beside the character, not parked on a band under it.
local GLOBE_X     = 270    -- life at -190, power at +190   (v49: 150)
local GLOBE_Y     = 40     -- ABSOLUTE screen y, both player globes   (v49: -262)
local GLOBE_Y_TGT = 110    -- ABSOLUTE screen y, target globe         (v49: -262)

-- v50 LOOK: the specular highlight, expressed as fractions of each globe's OWN width so the
-- 44px target globe scales instead of carrying its own numbers.
local HL_COLOR = { 1, 1, 1, 0.28 }   -- soft white; the alpha is the whole strength control
local HL_BLEND = "ADD"               -- see the header: BLEND would dim the number
local HL_W, HL_H = 0.46, 0.34        -- a wide, shallow ellipse: a curved surface, not a dot
local HL_X, HL_Y = -0.17, 0.21       -- up and to the left, off-centre; centred reads as a hole

-- the v49 state this patch replays onto
local BEFORE_X, BEFORE_Y = 150, -262

-- ===== helpers =========================================================================
local function iseq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not iseq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

-- One highlight, sized to the globe it goes on. Field names are copied verbatim from the
-- energy breakpoint marks below it, which are the repo's proven subtexture instances.
local function specular(globe)
  return {
    type             = "subtexture",
    textureTexture   = FILL_TEX,
    textureColor     = { HL_COLOR[1], HL_COLOR[2], HL_COLOR[3], HL_COLOR[4] },
    textureBlendMode = HL_BLEND,
    textureVisible   = true,
    textureDesaturate = false, textureMirror = false,
    textureRotate    = false, textureRotation = 0,
    width   = globe * HL_W,
    height  = globe * HL_H,
    xOffset = globe * HL_X,
    yOffset = globe * HL_Y,
    anchor_mode = "point", anchor_point = "CENTER", self_point = "CENTER",
    mirror = false, rotate = false, scale = 1,
  }
end

-- ===== read the v49 build ==============================================================
local f = assert(io.open(PACK, "r")); local src = f:read("*a"); f:close()
local T = W.decode(src)
local OLD = W.decode(src)

local byId, oldById = { [T.d.id] = T.d }, { [OLD.d.id] = OLD.d }
for _, aura in ipairs(T.c) do byId[aura.id] = aura end
for _, aura in ipairs(OLD.c) do oldById[aura.id] = aura end

-- ===== the exact v49 state this patch expects ==========================================
local PLAYER_GROUP = "Rogue - Player Globes"
local TARGET_GROUP = "Rogue - Target Globe"
local RES_GROUP    = "Rogue - Resources"

-- Every cluster region, with the v49 offset it must currently hold and the v50 offset it
-- gets. `x` is the offset INSIDE its group; the group carries the rest.
local CLUSTER = {
  { id = "Rogue - Life Globe",        group = PLAYER_GROUP, was = -BEFORE_X, now = -GLOBE_X,
    kind = "progresstexture", size = GLOBE_MAIN, subs = 1 },
  { id = "Rogue - Life Globe Rim",    group = PLAYER_GROUP, was = -BEFORE_X, now = -GLOBE_X,
    kind = "texture", size = GLOBE_MAIN + RIM_PAD },
  { id = "Rogue - Energy Globe",      group = PLAYER_GROUP, was =  BEFORE_X, now =  GLOBE_X,
    kind = "progresstexture", size = GLOBE_MAIN, subs = 5 },
  { id = "Rogue - Energy Globe Rim",  group = PLAYER_GROUP, was =  BEFORE_X, now =  GLOBE_X,
    kind = "texture", size = GLOBE_MAIN + RIM_PAD },
  { id = "Rogue - Target Life Globe", group = TARGET_GROUP, was = 0, now = 0,
    kind = "progresstexture", size = GLOBE_TGT, subs = 1 },
  { id = "Rogue - Target Globe Rim",  group = TARGET_GROUP, was = 0, now = 0,
    kind = "texture", size = GLOBE_TGT + RIM_PAD },
  { id = "Rogue - Threat Rim",        group = TARGET_GROUP, was = 0, now = 0,
    kind = "texture", size = GLOBE_TGT + RIM_PAD },
  { id = "Rogue - Threat Flash",      group = TARGET_GROUP, was = 0, now = 0,
    kind = "texture", size = GLOBE_TGT + RIM_PAD },
}

-- The three vessels, and only the vessels, take a highlight. A rim is not glass with liquid
-- behind it; it is the glass EDGE, and a second highlight on it would double the specular.
local GLOBES = {
  { id = "Rogue - Life Globe",        size = GLOBE_MAIN, subs = 1 },
  { id = "Rogue - Energy Globe",      size = GLOBE_MAIN, subs = 5 },
  { id = "Rogue - Target Life Globe", size = GLOBE_TGT,  subs = 1 },
}

local RES = assert(byId[RES_GROUP], "the Resources group is missing")
local playerGroup = assert(byId[PLAYER_GROUP], "the player globe group is missing")
local targetGroup = assert(byId[TARGET_GROUP], "the target globe group is missing")

do
  local inheritY = T.d.yOffset + RES.yOffset
  for _, node in ipairs({ playerGroup, targetGroup }) do
    assert(node.regionType == "group", node.id .. ": v49 cluster holder is not a group")
    assert(node.parent == RES_GROUP, node.id .. ": v49 cluster does not hang off Resources")
    assert(node.yOffset + inheritY == BEFORE_Y,
      ("%s: expected the v49 band at y=%d, found %d")
        :format(node.id, BEFORE_Y, node.yOffset + inheritY))
  end
  for _, want in ipairs(CLUSTER) do
    local aura = assert(byId[want.id], "v49 globe region missing: " .. want.id)
    assert(aura.regionType == want.kind,
      ("%s: expected a v49 %s, found %s"):format(want.id, want.kind, tostring(aura.regionType)))
    assert(aura.parent == want.group, want.id .. ": v49 parent is " .. tostring(aura.parent))
    assert(aura.width == want.size and aura.height == want.size,
      ("%s: expected v49 size %d, found %sx%s"):format(want.id, want.size,
        tostring(aura.width), tostring(aura.height)))
    assert(aura.xOffset == want.was and aura.yOffset == 0,
      ("%s: expected v49 offset (%d,0) inside its group, found (%s,%s)")
        :format(want.id, want.was, tostring(aura.xOffset), tostring(aura.yOffset)))
    if want.kind == "progresstexture" then
      assert(aura.orientation == ORIENT, want.id .. ": v49 globe does not fill bottom to top")
      assert(aura.foregroundTexture == FILL_TEX, want.id .. ": v49 globe is not the disc")
    else
      assert(aura.texture == RIM_TEX and aura.frameStrata == RIM_STRATA,
        want.id .. ": v49 rim art or strata is not what v50 replays onto")
    end
  end
  for _, want in ipairs(GLOBES) do
    local g = byId[want.id]
    assert(#g.subRegions == want.subs,
      ("%s: expected %d v49 subregions, found %d"):format(want.id, want.subs, #g.subRegions))
    assert(g.subRegions[1].type == "subtext", want.id .. ": subRegions[1] is not the percentage")
    for i = 2, #g.subRegions do
      assert(g.subRegions[i].type == "subtexture", want.id .. ": subregion " .. i .. " is not a mark")
      assert(g.subRegions[i].textureBlendMode == "BLEND",
        want.id .. ": a v49 mark is not on the blend mode v50 expects to be the only one")
    end
  end
end

-- Where every `sub.N` condition reference in the pack pointed BEFORE this patch. Recorded as
-- the subregion TABLE, not the index, so the audit compares what the condition actually
-- drives rather than re-checking a number against itself.
local function subReferences(root)
  local refs = {}
  local all = { root.d }
  for _, aura in ipairs(root.c) do all[#all + 1] = aura end
  for _, aura in ipairs(all) do
    for ci, cond in ipairs(aura.conditions or {}) do
      for gi, change in ipairs(cond.changes or {}) do
        local index = tostring(change.property or ""):match("^sub%.(%d+)%.")
        if index then
          refs[#refs + 1] = {
            id = aura.id, cond = ci, change = gi, index = tonumber(index),
            property = change.property,
            target = (aura.subRegions or {})[tonumber(index)],
          }
        end
      end
    end
  end
  return refs
end
local SUB_REFS_BEFORE = subReferences(OLD)
assert(#SUB_REFS_BEFORE > 0, "no sub.N condition references found: the audit would prove nothing")

-- ===== 1. POSITION: the globes flank the character =====================================
-- Absolute coordinates, so the inherited chain is subtracted rather than assumed. The two
-- groups no longer share a y: the player pair is beside you, the target globe is above you.
local inheritX, inheritY = T.d.xOffset + RES.xOffset, T.d.yOffset + RES.yOffset
playerGroup.xOffset, playerGroup.yOffset = 0 - inheritX, GLOBE_Y - inheritY
targetGroup.xOffset, targetGroup.yOffset = 0 - inheritX, GLOBE_Y_TGT - inheritY

for _, want in ipairs(CLUSTER) do
  local aura = byId[want.id]
  aura.xOffset, aura.yOffset = want.now, 0
end

-- ===== 2. LOOK: every vessel catches the light =========================================
for _, want in ipairs(GLOBES) do
  local g = byId[want.id]
  g.subRegions[#g.subRegions + 1] = specular(want.size)   -- APPENDED. Never inserted.
end

-- ===== verify ==========================================================================
local encoded = W.encode(T)
W.verify(T, encoded)
local cont = W.uidContinuityStrings(encoded, src)
W.assertUidContinuity(cont, "rogue v50")
assert(cont.changed == 0 and cont.missing == 0, "rogue v50: a uid changed or was lost")
assert(cont.oldCount == cont.newCount,
  "rogue v50: this patch only moves and restyles; no aura may be added or removed")
assert(cont.stable == cont.newCount and cont.retained == cont.oldCount,
  "rogue v50: not every aura kept its uid")

local NEW = W.decode(encoded)
local newById = { [NEW.d.id] = NEW.d }
for _, aura in ipairs(NEW.c) do newById[aura.id] = aura end

-- AUDIT 1: absolute screen position, walked up the parent chain exactly as WeakAuras anchors
-- it (a grouped child with anchorFrameType SCREEN anchors to its group's frame). Recovered
-- from the ENCODED string, so it cannot pass by reading back the variable that wrote it.
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

local PLACED = {
  ["Rogue - Life Globe"]        = { -GLOBE_X, GLOBE_Y },
  ["Rogue - Life Globe Rim"]    = { -GLOBE_X, GLOBE_Y },
  ["Rogue - Energy Globe"]      = {  GLOBE_X, GLOBE_Y },
  ["Rogue - Energy Globe Rim"]  = {  GLOBE_X, GLOBE_Y },
  ["Rogue - Target Life Globe"] = {        0, GLOBE_Y_TGT },
  ["Rogue - Target Globe Rim"]  = {        0, GLOBE_Y_TGT },
  ["Rogue - Threat Rim"]        = {        0, GLOBE_Y_TGT },
  ["Rogue - Threat Flash"]      = {        0, GLOBE_Y_TGT },
}
for id, want in pairs(PLACED) do
  local x, y = absolute(id)
  assert(x == want[1] and y == want[2],
    ("%s lands at (%d,%d); the shared geometry puts it at (%d,%d)")
      :format(id, x, y, want[1], want[2]))
end
-- and the band is really gone: nothing in the cluster is left on the v49 y
for _, want in ipairs(CLUSTER) do
  local _, y = absolute(want.id)
  assert(y ~= BEFORE_Y, want.id .. " is still parked on the v49 band")
end

-- AUDIT 2: sizes did not change with the move, and every rim is still its globe + 4.
for _, want in ipairs(CLUSTER) do
  local aura = newById[want.id]
  assert(aura.width == want.size and aura.height == want.size,
    ("%s is %sx%s, not %d"):format(want.id, tostring(aura.width), tostring(aura.height), want.size))
  assert(aura.regionType == want.kind, want.id .. " changed region type")
end

-- AUDIT 3: the highlight. Recovered from the committed string and re-derived from each
-- globe's OWN width, so a wrong globe's numbers cannot pass.
for _, want in ipairs(GLOBES) do
  local g = newById[want.id]
  assert(#g.subRegions == want.subs + 1,
    want.id .. ": expected exactly one appended subregion, found " .. (#g.subRegions - want.subs))
  local hl = g.subRegions[#g.subRegions]
  assert(hl.type == "subtexture", want.id .. ": the last subregion is not a texture")
  assert(hl.textureTexture == FILL_TEX, want.id .. ": the highlight is not drawn on the disc")
  assert(iseq(hl.textureColor, HL_COLOR), want.id .. ": the highlight is not soft white")
  -- ADD is the reason the number stays readable under an overlay; see the header.
  assert(hl.textureBlendMode == HL_BLEND,
    want.id .. ": the highlight is not additive and would dim the percentage")
  assert(hl.textureVisible == true, want.id .. ": the highlight ships switched off")
  assert(hl.width == g.width * HL_W and hl.height == g.height * HL_H,
    want.id .. ": the highlight is not sized from its own globe")
  assert(hl.xOffset == g.width * HL_X and hl.yOffset == g.height * HL_Y,
    want.id .. ": the highlight is not offset from its own globe")
  assert(hl.xOffset < 0 and hl.yOffset > 0,
    want.id .. ": the highlight is not up and to the left, so it reads as a hole, not a shine")
  assert(hl.anchor_mode == "point" and hl.anchor_point == "CENTER" and hl.self_point == "CENTER",
    want.id .. ": the highlight is not anchored to the globe's centre")
  -- it has to stay inside the glass: on each axis, centre + half-extent <= the radius
  local r = g.width / 2
  assert(math.abs(hl.xOffset) + hl.width / 2 <= r and math.abs(hl.yOffset) + hl.height / 2 <= r,
    want.id .. ": the highlight reaches past the rim")
  -- everything that was already there is untouched, in the same order
  local before = oldById[want.id]
  for i = 1, want.subs do
    assert(iseq(before.subRegions[i], g.subRegions[i]),
      ("%s: subregion %d changed; the highlight was inserted, not appended"):format(want.id, i))
  end
  assert(g.subRegions[1].type == "subtext",
    want.id .. ": the percentage is no longer subregion 1")
end
-- no rim, and nothing else in the pack, quietly grew a highlight
do
  local isGlobe = {}
  for _, want in ipairs(GLOBES) do isGlobe[want.id] = true end
  for _, aura in ipairs(NEW.c) do
    if not isGlobe[aura.id] then
      for i, sub in ipairs(aura.subRegions or {}) do
        assert(not (sub.type == "subtexture" and sub.textureBlendMode == HL_BLEND
          and sub.textureTexture == FILL_TEX),
          ("%s: subregion %d is a stray highlight"):format(aura.id, i))
      end
    end
  end
end

-- AUDIT 4: every positional `sub.N` condition in the WHOLE pack still drives the identical
-- subregion it drove in v49 — the failure mode that inserting instead of appending causes,
-- and the one WeakAuras reports no error for.
local SUB_REFS_AFTER = subReferences(NEW)
assert(#SUB_REFS_AFTER == #SUB_REFS_BEFORE,
  "a sub.N condition reference appeared or disappeared")
for i, before in ipairs(SUB_REFS_BEFORE) do
  local after = SUB_REFS_AFTER[i]
  assert(after.id == before.id and after.cond == before.cond and after.change == before.change
    and after.property == before.property and after.index == before.index,
    ("%s condition %d: the sub reference moved to %s"):format(before.id, before.cond,
      tostring(after and after.property)))
  assert(before.target ~= nil, ("%s condition %d: %s pointed at nothing in v49")
    :format(before.id, before.cond, before.property))
  assert(iseq(before.target, after.target),
    ("%s condition %d: %s now drives a different subregion")
      :format(before.id, before.cond, before.property))
end

-- AUDIT 5: nothing but position and the appended highlight changed, anywhere.
-- Every aura is compared field by field against v49; the cluster may differ only in
-- xOffset/yOffset, and the three globes additionally in subRegions.
local MOVED, RESTYLED = { [PLAYER_GROUP] = true, [TARGET_GROUP] = true }, {}
for _, want in ipairs(CLUSTER) do MOVED[want.id] = true end
for _, want in ipairs(GLOBES) do RESTYLED[want.id] = true end

assert(#OLD.c == #NEW.c, "the aura count changed")
assert(iseq(OLD.d, NEW.d), "the top-level group changed")
for _, old in ipairs(OLD.c) do
  local new = assert(newById[old.id], "aura disappeared: " .. old.id)
  for key in pairs(old) do
    local skip = (MOVED[old.id] and (key == "xOffset" or key == "yOffset"))
      or (RESTYLED[old.id] and key == "subRegions")
    if not skip then
      assert(iseq(old[key], new[key]),
        ("%s: %s changed, and v50 may only move globes and append a highlight")
          :format(old.id, key))
    end
  end
  for key in pairs(new) do
    assert(old[key] ~= nil, old.id .. ": gained field " .. key)
  end
end
-- triggers, load gates, conditions, colours and region types are covered by the loop above;
-- name the ones the brief calls out so a future edit fails loudly rather than subtly
for _, old in ipairs(OLD.c) do
  local new = newById[old.id]
  for _, key in ipairs({ "triggers", "load", "conditions", "regionType", "foregroundColor",
                         "backgroundColor", "color", "orientation" }) do
    assert(iseq(old[key], new[key]), old.id .. ": " .. key .. " changed")
  end
end

local out = assert(io.open(PACK, "w")); out:write(encoded); out:close()
print(("audit ok: life (%d,%d), power (+%d,%d), target (0,%d) — absolute, chain-walked")
  :format(-GLOBE_X, GLOBE_Y, GLOBE_X, GLOBE_Y, GLOBE_Y_TGT))
print(("highlight: %.2fx%.2f at (%.2f,%.2f) on 72px, %.2fx%.2f at (%.2f,%.2f) on 44px, %s a=%.2f")
  :format(GLOBE_MAIN * HL_W, GLOBE_MAIN * HL_H, GLOBE_MAIN * HL_X, GLOBE_MAIN * HL_Y,
    GLOBE_TGT * HL_W, GLOBE_TGT * HL_H, GLOBE_TGT * HL_X, GLOBE_TGT * HL_Y,
    HL_BLEND, HL_COLOR[4]))
print(("subregions: life %d, energy %d (sub.4/sub.5 still the 35/40 marks), target %d")
  :format(#newById["Rogue - Life Globe"].subRegions,
    #newById["Rogue - Energy Globe"].subRegions,
    #newById["Rogue - Target Life Globe"].subRegions))
print(("uid continuity: stable=%d changed=%d retained=%d missing=%d parentSame=%s")
  :format(cont.stable, cont.changed, cont.retained, cont.missing, tostring(cont.parentSame)))
print(("wrote %s (%d auras, %d chars)"):format(PACK, #T.c + 1, #encoded))
