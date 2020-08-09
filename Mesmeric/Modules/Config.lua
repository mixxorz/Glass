local Core, _, Utils = unpack(select(2, ...))
local C = Core:GetModule("Config")
local M = Core:GetModule("Mover")

local AceConfig = Core.Libs.AceConfig
local AceConfigDialog = Core.Libs.AceConfigDialog
local AceDBOptions = Core.Libs.AceDBOptions

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
            msg = {
                type = "input",
                name = "My Message",
                desc = "The message for my addon",
                set = "SetMyMessage",
                get = "GetMyMessage",
            },
            subgroup = {
              type = "group",
              name = "What happens now?",
              args = {
                msg = {
                    type = "input",
                    name = "Another message",
                    desc = "The message for my addon",
                    set = "SetMyMessage",
                    get = "GetMyMessage",
                },
              }
            }
          }
        },
        profile = AceDBOptions:GetOptionsTable(Core.db)
      },
  }

  AceConfig:RegisterOptionsTable("Mesmeric", options)

  self:RegisterChatCommand("mesmeric", "OnSlashCommand")
end

function C:OnSlashCommand(input)
  if input == "lock" then
    M:Unlock()
  else
    AceConfigDialog:Open("Mesmeric")
  end
end


function C:SetMyMessage(info, input)
  Utils.print('Input', input)
end

function C:GetMyMessage(info)
  Utils.print('Get', 'getting')
  return 'Hello, world!'
end
