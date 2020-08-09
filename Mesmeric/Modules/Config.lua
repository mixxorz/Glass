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
      childGroups = "tab",
      args = {
        general = {
          name = "General",
          type = "group",
          args = {
            fontHeader = {
              type = "header",
              name = "Font"
            },
            font = {
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
