local Core, Constants = unpack(select(2, ...))
local Fonts = Core:GetModule("Fonts")

local LSM = Core.Libs.LSM

local UPDATE_CONFIG = Constants.EVENTS.UPDATE_CONFIG

-- luacheck: push ignore 113
local CreateFont = CreateFont
-- luacheck: pop

local function ConfigureMessage(font, settings)
  font:SetFont(LSM:Fetch(LSM.MediaType.FONT, settings.font), settings.messageFontSize, settings.fontFlags)
  font:SetShadowColor(0, 0, 0, 1)
  font:SetShadowOffset(1, -1)
  font:SetJustifyH("LEFT")
  font:SetJustifyV("MIDDLE")
  font:SetSpacing(settings.messageLeading)
end

local function ConfigureTab(font, settings)
  font:SetFont(LSM:Fetch(LSM.MediaType.FONT, settings.tabFont or settings.font),
    settings.tabFontSize or 12, settings.tabFontFlags or settings.fontFlags)
  font:SetShadowColor(0, 0, 0, 0)
  font:SetShadowOffset(1, -1)
  font:SetJustifyH("LEFT")
  font:SetJustifyV("MIDDLE")
  font:SetSpacing(3)
end

function Fonts:CreateWindowFonts(id, settings)
  self.windowFonts = self.windowFonts or {}
  local pair = self.windowFonts[id]
  if not pair then
    pair = {
      message = CreateFont("GlassWindowMessageFont" .. tostring(id)),
      tab = CreateFont("GlassWindowTabFont" .. tostring(id))
    }
    self.windowFonts[id] = pair
  end
  ConfigureMessage(pair.message, settings)
  ConfigureTab(pair.tab, settings)
  return pair
end

function Fonts:UpdateWindowFonts(id, settings)
  return self:CreateWindowFonts(id, settings)
end

function Fonts:OnInitialize()
  self.fonts = {}
  self.windowFonts = {}
end

function Fonts:OnEnable()
  -- GlassMessageFont
  self.fonts.GlassMessageFont = CreateFont("GlassMessageFont")
  self.fonts.GlassMessageFont:SetFont(
    LSM:Fetch(LSM.MediaType.FONT, Core.db.profile.font),
    Core.db.profile.messageFontSize,
    Core.db.profile.fontFlags
  )
  self.fonts.GlassMessageFont:SetShadowColor(0, 0, 0, 1)
  self.fonts.GlassMessageFont:SetShadowOffset(1, -1)
  self.fonts.GlassMessageFont:SetJustifyH("LEFT")
  self.fonts.GlassMessageFont:SetJustifyV("MIDDLE")
  self.fonts.GlassMessageFont:SetSpacing(Core.db.profile.messageLeading)

  -- GlassChatDockFont
  self.fonts.GlassChatDockFont = CreateFont("GlassChatDockFont")
  ConfigureTab(self.fonts.GlassChatDockFont, Core.db.profile)
  self.fonts.GlassChatDockFont:SetShadowColor(0, 0, 0, 0)
  self.fonts.GlassChatDockFont:SetShadowOffset(1, -1)
  self.fonts.GlassChatDockFont:SetJustifyH("LEFT")
  self.fonts.GlassChatDockFont:SetJustifyV("MIDDLE")
  self.fonts.GlassChatDockFont:SetSpacing(3)

  -- GlassEditBoxFont
  self.fonts.GlassEditBoxFont = CreateFont("GlassEditBoxFont")
  self.fonts.GlassEditBoxFont:SetFont(
    LSM:Fetch(LSM.MediaType.FONT, Core.db.profile.font),
    Core.db.profile.editBoxFontSize,
    Core.db.profile.fontFlags
  )
  self.fonts.GlassEditBoxFont:SetShadowColor(0, 0, 0, 0)
  self.fonts.GlassEditBoxFont:SetShadowOffset(1, -1)
  self.fonts.GlassEditBoxFont:SetJustifyH("LEFT")
  self.fonts.GlassEditBoxFont:SetJustifyV("MIDDLE")
  self.fonts.GlassEditBoxFont:SetSpacing(3)

  Core:Subscribe(UPDATE_CONFIG, function (key)
    if key == "font" or key == "fontFlags" or key == "messageFontSize" then
      self.fonts.GlassMessageFont:SetFont(
        LSM:Fetch(LSM.MediaType.FONT, Core.db.profile.font),
        Core.db.profile.messageFontSize,
        Core.db.profile.fontFlags
      )
    end

    if key == "messageLeading" then
      self.fonts.GlassMessageFont:SetSpacing(Core.db.profile.messageLeading)
    end

    if key == "font" or key == "fontFlags" or key == "tabFont" or
      key == "tabFontFlags" or key == "tabFontSize" then
      ConfigureTab(self.fonts.GlassChatDockFont, Core.db.profile)
    end

    if key == "font" or key == "fontFlags" or key == "editBoxFontSize" then
      self.fonts.GlassEditBoxFont:SetFont(
        LSM:Fetch(LSM.MediaType.FONT, Core.db.profile.font),
        Core.db.profile.editBoxFontSize,
        Core.db.profile.fontFlags
      )
    end
  end)
end
