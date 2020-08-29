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

-- Events
Constants.EVENTS = {
  LOCK_MOVER = "Glass/LOCK_MOVER",
  UNLOCK_MOVER = "Glass/UNLOCK_MOVER",
}

Constants.ACTIONS = {
  LockMover = function ()
    return Constants.EVENTS.LOCK_MOVER
  end,
  UnlockMover = function ()
    return Constants.EVENTS.UNLOCK_MOVER
  end,
}
