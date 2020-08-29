local Core, Constants = unpack(select(2, ...))
local C = Core:GetModule("Config")
local CT = Core:GetModule("ChatTabs")
local EB = Core:GetModule("EditBox")
local M = Core:GetModule("Mover")
local MC = Core:GetModule("MainContainer")
local Fonts = Core:GetModule("Fonts")
local UIManager = Core:GetModule("UIManager")

local AceConfig = Core.Libs.AceConfig
local AceConfigDialog = Core.Libs.AceConfigDialog
local AceDBOptions = Core.Libs.AceDBOptions
local LSM = Core.Libs.LSM

local UnlockMover = Constants.ACTIONS.UnlockMover

function C:OnEnable()
  local options = {
      name = "Glass",
      handler = C,
      type = "group",
      args = {
        general = {
          name = "General",
          type = "group",
          args = {
            fontHeader = {
              order = 0,
              type = "header",
              name = "Font"
            },
            font = {
              order = 10,
              type = "select",
              dialogControl = "LSM30_Font",
              name = "Font",
              desc = "Font to use throughout Glass",
              values = LSM:HashTable("font"),
              get = function()
                return Core.db.profile.font
              end,
              set = function(info, input)
                Core.db.profile.font = input
                Fonts:OnRefreshConfig("font")
                UIManager:OnUpdateFont()
                EB:OnUpdateFont()
                CT:OnUpdateFont()
              end,
            },
            messageFontSize = {
              order = 20,
              type = "range",
              name = "Font size",
              desc = "Controls the size of the message text",
              min = 1,
              max = 100,
              softMin = 6,
              softMax = 24,
              step = 1,
              get = function ()
                return Core.db.profile.messageFontSize
              end,
              set = function (info, input)
                Core.db.profile.messageFontSize = input
                Fonts:OnRefreshConfig("messageFontSize")
                UIManager:OnUpdateFont()
                EB:OnUpdateFont()
              end,
            },
            messageFontSizeNl = {
              order = 30,
              type = "description",
              name = ""
            },
            iconTextureYOffset = {
              order = 40,
              type = "range",
              name = "Icon texture Y offset",
              desc = "Controls the vertical offset of text icons",
              min = 0,
              max = 12,
              softMin = 0,
              softMax = 12,
              step = 1,
              get = function ()
                return Core.db.profile.iconTextureYOffset
              end,
              set = function (info, input)
                Core.db.profile.iconTextureYOffset = input
              end,
            },
            iconTextureYOffsetDesc = {
              order = 50,
              type = "description",
              name = "This controls the vertical offset of text icons. Adjust this if text icons aren't centered."
            },
            mouseOverHeading = {
              order = 60,
              type = "header",
              name = "Mouse over tooltips"
            },
            mouseOverTooltips = {
              order = 70,
              type = "toggle",
              name = "Enable",
              get = function ()
                return Core.db.profile.mouseOverTooltips
              end,
              set = function (info, input)
                Core.db.profile.mouseOverTooltips = input
              end,
            },
            mouseOverTooltipsDesc = {
              order = 80,
              type = "description",
              name = "Check if you want tooltips to appear when hovering over chat links.",
            },
            chatHeader = {
              order = 90,
              type = "header",
              name = "Chat"
            },
            chatHoldTime = {
              order = 100,
              type = "range",
              name = "Fade out delay",
              min = 1,
              max = 100,
              softMin = 1,
              softMax = 20,
              step = 1,
              get = function ()
                return Core.db.profile.chatHoldTime
              end,
              set = function (info, input)
                Core.db.profile.chatHoldTime = input
              end,
            },
            chatShowOnMouseOver = {
              order = 105,
              type = "toggle",
              name = "Show on mouse over",
              get = function ()
                return Core.db.profile.chatShowOnMouseOver
              end,
              set = function (info, input)
                Core.db.profile.chatShowOnMouseOver = input
              end,
            },
            chatHoldTimeNl = {
              order = 110,
              type = "description",
              name = ""
            },
            chatBackgroundOpacity = {
              order = 120,
              type = "range",
              name = "Chat background opacity",
              min = 0,
              max = 1,
              softMin = 0,
              softMax = 1,
              step = 0.01,
              get = function ()
                return Core.db.profile.chatBackgroundOpacity
              end,
              set = function (info, input)
                Core.db.profile.chatBackgroundOpacity = input
                UIManager:OnUpdateChatBackgroundOpacity()
              end,
            },
            chatBackgroundOpacityDesc = {
              order = 130,
              type = "description",
              name = ""
            },
            frameHeader = {
              order = 140,
              type = "header",
              name = "Frame"
            },
            frameWidth = {
              order = 150,
              type = "range",
              name = "Width",
              min = 300,
              max = 9999,
              softMin = 300,
              softMax = 800,
              step = 1,
              get = function ()
                return Core.db.profile.frameWidth
              end,
              set = function (info, input)
                Core.db.profile.frameWidth = input
                M:OnUpdateFrame()
                MC:OnUpdateFrame()
                UIManager:OnUpdateFrame()
                EB:OnUpdateFrame()
                CT:OnUpdateFrame()
              end
            },
            frameHeight = {
              order = 160,
              type = "range",
              name = "Height",
              min = 1,
              max = 9999,
              softMin = 200,
              softMax = 800,
              step = 1,
              get = function ()
                return Core.db.profile.frameHeight
              end,
              set = function (info, input)
                Core.db.profile.frameHeight = input
                M:OnUpdateFrame()
                MC:OnUpdateFrame()
                UIManager:OnUpdateFrame()
              end
            }
          }
        },
        profile = AceDBOptions:GetOptionsTable(Core.db)
      }
  }

  AceConfig:RegisterOptionsTable("Glass", options)

  self:RegisterChatCommand("glass", "OnSlashCommand")

  Core.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
  Core.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
  Core.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

function C:OnSlashCommand(input)
  if input == "lock" then
    Core:SendMessage(UnlockMover())
  else
    AceConfigDialog:Open("Glass")
  end
end

function C:RefreshConfig()
  UIManager:OnUpdateFont()
  EB:OnUpdateFont()
end
