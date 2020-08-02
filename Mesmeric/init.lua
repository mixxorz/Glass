local _G = _G

-- luacheck: push ignore 113
local UIParent = UIParent
-- luacheck: pop

local AceAddon = _G.LibStub("AceAddon-3.0")

local AddonName, AddonVars = ...
local Core = AceAddon:NewAddon(AddonName)
local Constants = { }
AddonVars[1] = Core
AddonVars[2] = Constants
_G[AddonName] = Core

-- Core
Core.Libs = {
  lodash = _G.LibStub("lodash.wow"),
  AceDB = _G.LibStub("AceDB-3.0")
}

-- Buffer print messages until ViragDevTool loads
local printBuffer = {}

Core.print = function(str, t)
  if _G.ViragDevTool_AddData then
    _G.ViragDevTool_AddData(t, str)
  else
    table.insert(printBuffer, {str, t})
  end
end

-- Constants
Constants.DEFAULT_ANCHOR_POINT = {
  point = "BOTTOMLEFT",
  relativeTo = UIParent,
  relativePoint = "BOTTOMLEFT",
  xOfs = 20,
  yOfs = 230
}
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
Core:NewModule("Mover", "AceConsole-3.0")
Core:NewModule("MainContainer")

Core:NewModule("ChatTabs", "AceHook-3.0")
Core:NewModule("EditBox", "AceHook-3.0")
Core:NewModule("SlidingMessageFrame", "AceHook-3.0")

local mesmericDefaults = {
  profile = {
    frameWidth = Constants.DEFAULT_SIZE[1],
    frameHeight = Constants.DEFAULT_SIZE[2],
    positionAnchor = Constants.DEFAULT_ANCHOR_POINT
  }
}

function Core:OnInitialize()
  self.db = self.Libs.AceDB:New("MesmericDB", mesmericDefaults)
end

function Core:OnEnable()
  for _, item in ipairs(printBuffer) do
    Core.print(unpack(item))
  end
  printBuffer = {}
end
