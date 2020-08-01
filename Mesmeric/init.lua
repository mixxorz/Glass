local _G = _G

local AceAddon = _G.LibStub("AceAddon-3.0")

-- luacheck: push ignore 113
local ViragDevTool_AddData = ViragDevTool_AddData
-- luacheck: pop

local AddonName, AddonVars = ...
local Core = AceAddon:NewAddon(AddonName)
local Constants = { }
AddonVars[1] = Core
AddonVars[2] = Constants
_G[AddonName] = Core

-- Core
Core.Libs = {
  lodash = _G.LibStub("lodash.wow"),
}

function Core:Print(...)
  local args = {...}
  ViragDevTool_AddData(unpack(args))
end

-- Constants
Constants.DEFAULT_ANCHOR_POINT = {"BOTTOMLEFT", 20, 200}
Constants.DEFAULT_CHAT_HOLD_TIME = 10
Constants.DEFAULT_SIZE = {450, 230}

-- Colors
local function createColor(r, g, b)
  return {r = r / 255, g = g / 255, b = b / 255}
end

Constants.COLORS = {
  black = createColor(0, 0, 0),
  codGray = createColor(17, 17, 17),
  apache = createColor(223, 186, 105)
}

-- Modules
Core:NewModule("ChatTabs", "AceHook-3.0")
Core:NewModule("MainContainer")
Core:NewModule("SlidingMessageFrame", "AceHook-3.0")
