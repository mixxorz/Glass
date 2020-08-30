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

Constants.DOCK_HEIGHT = 20
Constants.TEXT_XPADDING = 15

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
  HYPERLINK_CLICK = "Glass/HYPERLINK_CLICK",
  HYPERLINK_ENTER = "Glass/HYPERLINK_ENTER",
  HYPERLINK_LEAVE = "Glass/HYPERLINK_LEAVE",
  LOCK_MOVER = "Glass/LOCK_MOVER",
  MOUSE_ENTER = "Glass/MOUSE_ENTER",
  MOUSE_LEAVE = "Glass/MOUSE_LEAVE",
  REFRESH_CONFIG = "Glass/REFRESH_CONFIG",
  SAVE_FRAME_POSITION = "Glass/SAVE_FRAME_POSITION",
  UNLOCK_MOVER = "Glass/UNLOCK_MOVER",
  UPDATE_CONFIG = "Glass/UPDATE_CONFIG",
}

Constants.ACTIONS = {
  HyperlinkClick = function (payload)
    return Constants.EVENTS.HYPERLINK_CLICK, payload
  end,
  HyperlinkEnter = function (payload)
    return Constants.EVENTS.HYPERLINK_ENTER, payload
  end,
  HyperlinkLeave = function (link)
    return Constants.EVENTS.HYPERLINK_LEAVE, link
  end,
  LockMover = function ()
    return Constants.EVENTS.LOCK_MOVER
  end,
  MouseEnter = function ()
    return Constants.EVENTS.MOUSE_ENTER
  end,
  MouseLeave = function ()
    return Constants.EVENTS.MOUSE_LEAVE
  end,
  RefreshConfig = function ()
    return Constants.EVENTS.REFRESH_CONFIG
  end,
  SaveFramePosition = function (payload)
    return Constants.EVENTS.SAVE_FRAME_POSITION, payload
  end,
  UnlockMover = function ()
    return Constants.EVENTS.UNLOCK_MOVER
  end,
  UpdateConfig = function (payload)
    return Constants.EVENTS.UPDATE_CONFIG, payload
  end,
}
