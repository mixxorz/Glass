local Core, Constants = unpack(select(2, ...))
local Fonts = Core:GetModule("Fonts")

local LSM = Core.Libs.LSM

local UPDATE_CONFIG = Constants.EVENTS.UPDATE_CONFIG

-- luacheck: push ignore 113
local CreateFont = CreateFont
-- luacheck: pop

local function SetFont(font, name, size, flags)
  local fallback = _G.GameFontNormal:GetFont()
  local path = LSM:Fetch(LSM.MediaType.FONT, name, true) or fallback
  local ok, applied = pcall(font.SetFont, font, path, size, flags)
  if not ok or applied == false then font:SetFont(fallback, size, flags) end
end

local function ConfigureMessage(font, settings)
  SetFont(font, settings.font, settings.messageFontSize, settings.fontFlags)
  font:SetShadowColor(0, 0, 0, 1)
  font:SetShadowOffset(1, -1)
  font:SetJustifyH("LEFT")
  font:SetJustifyV("MIDDLE")
  font:SetSpacing(settings.messageLeading)
end

local function ConfigureTab(font, settings)
  SetFont(font, settings.tabFont, settings.tabFontSize, settings.tabFontFlags)
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
  SetFont(self.fonts.GlassMessageFont, Core.db.profile.font,
    Core.db.profile.messageFontSize, Core.db.profile.fontFlags)
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
  SetFont(self.fonts.GlassEditBoxFont, Core.db.profile.font,
    Core.db.profile.editBoxFontSize, Core.db.profile.fontFlags)
  self.fonts.GlassEditBoxFont:SetShadowColor(0, 0, 0, 0)
  self.fonts.GlassEditBoxFont:SetShadowOffset(1, -1)
  self.fonts.GlassEditBoxFont:SetJustifyH("LEFT")
  self.fonts.GlassEditBoxFont:SetJustifyV("MIDDLE")
  self.fonts.GlassEditBoxFont:SetSpacing(3)

  Core:Subscribe(UPDATE_CONFIG, function (key)
    if key == "font" or key == "fontFlags" or key == "messageFontSize" then
      SetFont(self.fonts.GlassMessageFont, Core.db.profile.font,
        Core.db.profile.messageFontSize, Core.db.profile.fontFlags)
    end

    if key == "messageLeading" then
      self.fonts.GlassMessageFont:SetSpacing(Core.db.profile.messageLeading)
    end

    if key == "tabFont" or key == "tabFontFlags" or key == "tabFontSize" then
      ConfigureTab(self.fonts.GlassChatDockFont, Core.db.profile)
    end

    if key == "font" or key == "fontFlags" or key == "editBoxFontSize" then
      SetFont(self.fonts.GlassEditBoxFont, Core.db.profile.font,
        Core.db.profile.editBoxFontSize, Core.db.profile.fontFlags)
    end
  end)
end
