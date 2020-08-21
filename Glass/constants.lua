local _, Constants = unpack(select(2, ...))

-- luacheck: push ignore 113
local UIParent = UIParent
-- luacheck: pop

-- Constants
Constants.DEFAULT_ANCHOR_POINT = {
  point = "BOTTOMLEFT",
  relativeTo = UIParent,
  relativePoint = "BOTTOMLEFT",
  xOfs = 20,
  yOfs = 230
}

-- Colors
local function createColor(r, g, b)
  return {r = r / 255, g = g / 255, b = b / 255}
end

Constants.COLORS = {
  black = createColor(0, 0, 0),
  codGray = createColor(17, 17, 17),
  apache = createColor(223, 186, 105)
}
