local Core, Constants = unpack(select(2, ...))
local C = Core:GetModule("Config")

local AceConfig = Core.Libs.AceConfig
local AceConfigDialog = Core.Libs.AceConfigDialog
local AceDBOptions = Core.Libs.AceDBOptions
local LSM = Core.Libs.LSM

local RefreshConfig = Constants.ACTIONS.RefreshConfig
local UnlockMover = Constants.ACTIONS.UnlockMover
local UpdateConfig = Constants.ACTIONS.UpdateConfig

local SAVE_FRAME_POSITION = Constants.EVENTS.SAVE_FRAME_POSITION

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
            section1 = {
              name = "Frame",
              type = "group",
              inline = true,
              order = 1,
              args = {
                frameWidth = {
                  name = "Width",
                  desc = "Default: "..Core.defaults.profile.frameWidth,
                  type = "range",
                  order = 1.1,
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
                    Core:Dispatch(UpdateConfig("frameWidth"))
                  end
                },
                frameHeight = {
                  name = "Height",
                  desc = "Default: "..Core.defaults.profile.frameHeight,
                  type = "range",
                  order = 1.2,
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
                    Core:Dispatch(UpdateConfig("frameHeight"))
                  end
                }
              }
            }
          }
        },
        messages = {
          name = "Messages",
          type = "group",
          args = {
            section1 = {
              name = "Appearance",
              type = "group",
              inline = true,
              order = 1,
              args = {
                font = {
                  name = "Font",
                  desc = "Font to use throughout Glass",
                  type = "select",
                  dialogControl = "LSM30_Font",
                  values = LSM:HashTable("font"),
                  get = function()
                    return Core.db.profile.font
                  end,
                  set = function(info, input)
                    Core.db.profile.font = input
                    Core:Dispatch(UpdateConfig("font"))
                  end,
                  order = 1.1,
                },
                messageFontSize = {
                  name = "Size",
                  desc = "Default: "..Core.defaults.profile.messageFontSize.."\nMin: 1\nMax: 100",
                  type = "range",
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
                    Core:Dispatch(UpdateConfig("messageFontSize"))
                  end,
                  order = 1.2,
                },
                chatBackgroundOpacity = {
                  name = "Background opacity",
                  desc = "Default: "..Core.defaults.profile.chatBackgroundOpacity,
                  type = "range",
                  order = 1.3,
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
                    Core:Dispatch(UpdateConfig("chatBackgroundOpacity"))
                  end,
                },
              },
            },
            section2 = {
              name = "Animations",
              type = "group",
              inline = true,
              order = 2,
              args = {
                chatHoldTime = {
                  name = "Fade out delay",
                  desc = "Default: "..Core.defaults.profile.chatHoldTime..
                    "\nMin: 1\nMax: 180",
                  type = "range",
                  order = 2.1,
                  min = 1,
                  max = 180,
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
                  name = "Show on mouse over",
                  desc = "Default: "..tostring(Core.defaults.profile.chatShowOnMouseOver),
                  type = "toggle",
                  order = 2.2,
                  get = function ()
                    return Core.db.profile.chatShowOnMouseOver
                  end,
                  set = function (info, input)
                    Core.db.profile.chatShowOnMouseOver = input
                  end,
                },
              }
            },
            section3 = {
              name = "Misc",
              type = "group",
              inline = true,
              order = 3,
              args = {
                mouseOverTooltips = {
                  name = "Mouse over tooltips",
                  desc = "Should tooltips to appear when hovering over chat links.",
                  type = "toggle",
                  order = 3.1,
                  get = function ()
                    return Core.db.profile.mouseOverTooltips
                  end,
                  set = function (info, input)
                    Core.db.profile.mouseOverTooltips = input
                  end,
                },
                iconTextureYOffset = {
                  type = "range",
                  name = "Icon texture Y offset",
                  desc = "Default: "..Core.defaults.profile.iconTextureYOffset..
                    "\nAdjust this if text icons aren't centered.",
                  order = 3.2,
                  min = 0,
                  max = 12,
                  softMin = 0,
                  softMax = 12,
                  step = 3.1,
                  get = function ()
                    return Core.db.profile.iconTextureYOffset
                  end,
                  set = function (info, input)
                    -- TODO: Update messages dynamically
                    Core.db.profile.iconTextureYOffset = input
                  end,
                },
              }
            },
          },
        },
        profile = AceDBOptions:GetOptionsTable(Core.db)
      }
  }

  AceConfig:RegisterOptionsTable("Glass", options)

  self:RegisterChatCommand("glass", "OnSlashCommand")

  Core.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
  Core.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
  Core.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

  Core:Subscribe(SAVE_FRAME_POSITION, function (position)
    Core.db.profile.positionAnchor = position
  end)
end

function C:OnSlashCommand(input)
  if input == "lock" then
    Core:Dispatch(UnlockMover())
  else
    AceConfigDialog:Open("Glass")
  end
end

function C:RefreshConfig()
  Core:Dispatch(UpdateConfig("chatBackgroundOpacity"))
  Core:Dispatch(UpdateConfig("font"))
  Core:Dispatch(UpdateConfig("frameHeight"))
  Core:Dispatch(UpdateConfig("frameWidth"))
  Core:Dispatch(UpdateConfig("messageFontSize"))

  -- For things that don't update using the config frame e.g. frame position
  Core:Dispatch(RefreshConfig())
end
