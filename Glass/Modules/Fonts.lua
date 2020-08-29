local Core = unpack(select(2, ...))
local Fonts = Core:GetModule("Fonts")

local LSM = Core.Libs.LSM

-- luacheck: push ignore 113
local CreateFont = CreateFont
-- luacheck: pop

function Fonts:OnInitialize()
  self.fonts = {}

  self.fonts.GlassMessageFont = CreateFont("GlassMessageFont")
  self.fonts.GlassMessageFont:SetFont(
    LSM:Fetch(LSM.MediaType.FONT, Core.db.profile.font),
    Core.db.profile.messageFontSize
  )
  self.fonts.GlassMessageFont:SetShadowColor(0, 0, 0, 1)
  self.fonts.GlassMessageFont:SetShadowOffset(1, -1)
  self.fonts.GlassMessageFont:SetJustifyH("LEFT")
  self.fonts.GlassMessageFont:SetJustifyV("MIDDLE")
  self.fonts.GlassMessageFont:SetSpacing(3)
end

function Fonts:OnRefreshConfig(key)
  self.fonts.GlassMessageFont:SetFont(
    LSM:Fetch(LSM.MediaType.FONT, Core.db.profile.font),
    Core.db.profile.messageFontSize
  )
end
