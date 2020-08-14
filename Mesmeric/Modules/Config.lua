local Core, _, Utils = unpack(select(2, ...))
local C = Core:GetModule("Config")
local CT = Core:GetModule("ChatTabs")
local EB = Core:GetModule("EditBox")
local M = Core:GetModule("Mover")
local SMF = Core:GetModule("SlidingMessageFrame")

local AceConfig = Core.Libs.AceConfig
local AceConfigDialog = Core.Libs.AceConfigDialog
local AceDBOptions = Core.Libs.AceDBOptions
local LSM = Core.Libs.LSM

function C:OnEnable()
  local options = {
      name = "Mesmeric",
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
              desc = "Font to use throughout Mesmeric",
              values = LSM:HashTable("font"),
              get = function()
                return Core.db.profile.font
              end,
              set = function(info, input)
                Core.db.profile.font = input
                SMF:OnUpdateFont()
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
                SMF:OnUpdateFont()
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
            }
          }
        },
        profile = AceDBOptions:GetOptionsTable(Core.db)
      },
  }

  AceConfig:RegisterOptionsTable("Mesmeric", options)

  self:RegisterChatCommand("mesmeric", "OnSlashCommand")

  Core.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
  Core.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
  Core.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

function C:OnSlashCommand(input)
  if input == "lock" then
    M:Unlock()
  else
    AceConfigDialog:Open("Mesmeric")
  end
end

function C:RefreshConfig()
  SMF:OnUpdateFont()
  EB:OnUpdateFont()
end
