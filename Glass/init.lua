local _G = _G

local AceAddon = _G.LibStub("AceAddon-3.0")

local AddonName, AddonVars = ...
local Core = AceAddon:NewAddon(AddonName)
local Constants = {}
local Utils = {}
AddonVars[1] = Core
AddonVars[2] = Constants
AddonVars[3] = Utils
_G[AddonName] = Core

-- Core
Core.Libs = {
  AceConfig = _G.LibStub("AceConfig-3.0"),
  AceConfigDialog = _G.LibStub("AceConfigDialog-3.0"),
  AceDBOptions = _G.LibStub("AceDBOptions-3.0"),
  AceDB = _G.LibStub("AceDB-3.0"),
  LSM = _G.LibStub("LibSharedMedia-3.0"),
  lodash = _G.LibStub("lodash.wow")
}

-- Modules
-- These need to be initialized first
Core:NewModule("Mover", "AceConsole-3.0")
Core:NewModule("MainContainer", "AceHook-3.0")

Core:NewModule("ChatTabs", "AceHook-3.0")
Core:NewModule("Config", "AceConsole-3.0")
Core:NewModule("EditBox", "AceHook-3.0")
Core:NewModule("SlidingMessageFrame", "AceHook-3.0")

function Core:OnInitialize()
  local defaults = {
    profile = {
      frameWidth = 450,
      frameHeight = 230,
      positionAnchor = Constants.DEFAULT_ANCHOR_POINT,
      font = "Friz Quadrata TT",
      messageFontSize = 12,
      editBoxFontSize = 12,
      iconTextureYOffset = 4,
      mouseOverTooltips = true,
      chatHoldTime = 10,
      chatBackgroundOpacity = 0.4,
      chatShowOnMouseOver = true
    }
  }

  self.db = self.Libs.AceDB:New("GlassDB", defaults, true)
  self.printBuffer = {}
end

function Core:OnEnable()
  -- Buffer print messages until ViragDevTool loads
  for _, item in ipairs(self.printBuffer) do
    Utils.print(unpack(item))
  end
  self.printBuffer = {}
end
