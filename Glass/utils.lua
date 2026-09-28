local Core, _, Utils = unpack(select(2, ...))

local map = Core.Libs.lodash.map

-- luacheck: push ignore 113
local strsplit = strsplit
-- luacheck: pop

-- Utility functions
Utils.super = function (obj)
  return getmetatable(obj).__index
end

Utils.getEditBoxXPadding = function ()
  local profile = Core.db.profile
  return math.max(0, math.min(profile.editBoxXPadding, math.floor((profile.frameWidth - 1) / 2)))
end

Utils.getMessagePadding = function (settings)
  local profile = settings or Core.db.profile
  -- Unset sides inherit the old shared padding so existing profiles keep their layout.
  local left = math.max(0, profile.contentLeftPadding or profile.contentXPadding)
  local right = math.max(0, profile.contentRightPadding or profile.contentXPadding)
  local available = math.max(0, profile.frameWidth - 1)
  if left + right > available then
    local scale = available / (left + right)
    left, right = math.floor(left * scale), math.floor(right * scale)
  end
  return left, right
end

Utils.getMessageScrollBounds = function (scrollHeight, paneHeight, overflowHeight)
  local last = math.max(0, scrollHeight - paneHeight)
  local first = math.min(paneHeight + overflowHeight, last)
  return first, last
end

Utils.getMessageEdgeFades = function (settings, height, atBottom)
  local limit = math.max(0, height / 2)
  local top = math.max(0, math.min(settings.messageTopFade or 0, limit))
  local bottom = atBottom and 0 or math.max(0, math.min(settings.messageBottomFade or 0, limit))
  return top, bottom
end

Utils.getDockHeight = function (settings)
  local profile = settings or Core.db.profile
  return (profile.tabFontSize or 12) + (profile.tabYPadding or 4) * 2
end

Utils.getTabXPadding = function (settings)
  local profile = settings or Core.db.profile
  return math.max(0, math.min(profile.tabXPadding or profile.contentXPadding,
    math.floor((profile.frameWidth - 1) / 2)))
end

---
-- Print to VDT
Utils.print = function (str, t)
  if _G.ViragDevTool_AddData then
    _G.ViragDevTool_AddData(t, str)
  else
    -- Buffer print messages until ViragDevTool loads
    table.insert(Core.printBuffer, {str, t})
  end
end

---
-- Prints Glass' notification messages
Utils.notify = function (message)
  print("|c00DFBA69Glass|r: ", message)
end

---
-- Returns true if version is newer
Utils.versionGreaterThan = function (current, previous)
  local cur = {strsplit('.', current)}
  local prev = {strsplit('.', previous)}

  local curPre = {strsplit('-', cur[3])}
  local prevPre = {strsplit('-', prev[3])}

  cur[3] = curPre[1]
  prev[3] = prevPre[1]

  cur = map(cur, function (v) return tonumber(v) end)
  prev = map(prev, function (v) return tonumber(v) end)

  if cur[1] > prev[1] then
    return true
  end

  if cur[2] > prev[2] then
    return true
  end

  if cur[3] > prev[3] then
    return true
  end

  -- Previous was a prerelease
  if #curPre ~= 2 and #prevPre == 2 then
    return true
  end

  return false
end
