local Core, Constants = unpack(select(2, ...))
local Fonts = Core:GetModule("Fonts")

local LSM = Core.Libs.LSM

local UPDATE_CONFIG = Constants.EVENTS.UPDATE_CONFIG

local ALPHABETS = {"roman", "korean", "simplifiedchinese", "traditionalchinese", "russian"}
local nativeMembers = {}
local nativeFontPaths = {}

local function CreateChatFont(name)
  return _G.CreateFontFamily(name, nativeMembers)
end

local function ConfigureFont(font, name, size, flags, shadowAlpha, spacing)
  local latinPath = LSM:Fetch(LSM.MediaType.FONT, name, true) or nativeFontPaths.roman
  for _, alphabet in ipairs(ALPHABETS) do
    local member = font:GetFontObjectForAlphabet(alphabet)
    local fallback = nativeFontPaths[alphabet]
    local path = alphabet == "roman" and latinPath or fallback
    local ok, applied = pcall(member.SetFont, member, path, size, flags)
    if not ok or applied == false then member:SetFont(fallback, size, flags) end
    member:SetShadowColor(0, 0, 0, shadowAlpha)
    member:SetShadowOffset(1, -1)
    member:SetSpacing(spacing)
  end
  font:SetJustifyH("LEFT")
  font:SetJustifyV("MIDDLE")
end

local function ConfigureMessage(font, settings)
  ConfigureFont(font, settings.font, settings.messageFontSize, settings.fontFlags, 1, settings.messageLeading)
end

local function ConfigureTab(font, settings)
  ConfigureFont(font, settings.tabFont, settings.tabFontSize, settings.tabFontFlags, 0, 3)
end

local function ConfigureEditBox(font, settings)
  ConfigureFont(font, settings.font, settings.editBoxFontSize, settings.fontFlags, 0, 3)
end

function Fonts:CreateWindowFonts(id, settings)
  self.windowFonts = self.windowFonts or {}
  local pair = self.windowFonts[id]
  if not pair then
    pair = {
      message = CreateChatFont("GlassWindowMessageFont" .. tostring(id)),
      tab = CreateChatFont("GlassWindowTabFont" .. tostring(id))
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
  -- Copy the native paths, not the font objects; Glass must not restyle Blizzard's chat.
  for _, alphabet in ipairs(ALPHABETS) do
    local native = _G.ChatFontNormal:GetFontObjectForAlphabet(alphabet)
    local path, size, flags = native:GetFont()
    nativeFontPaths[alphabet] = path
    nativeMembers[#nativeMembers + 1] = {alphabet = alphabet, file = path, height = size, flags = flags}
  end
end

function Fonts:OnEnable()
  self.fonts.GlassMessageFont = CreateChatFont("GlassMessageFont")
  ConfigureMessage(self.fonts.GlassMessageFont, Core.db.profile)

  self.fonts.GlassChatDockFont = CreateChatFont("GlassChatDockFont")
  ConfigureTab(self.fonts.GlassChatDockFont, Core.db.profile)

  self.fonts.GlassEditBoxFont = CreateChatFont("GlassEditBoxFont")
  ConfigureEditBox(self.fonts.GlassEditBoxFont, Core.db.profile)

  Core:Subscribe(UPDATE_CONFIG, function (key)
    if key == "font" or key == "fontFlags" or key == "messageFontSize" or key == "messageLeading" then
      ConfigureMessage(self.fonts.GlassMessageFont, Core.db.profile)
    end

    if key == "tabFont" or key == "tabFontFlags" or key == "tabFontSize" then
      ConfigureTab(self.fonts.GlassChatDockFont, Core.db.profile)
    end

    if key == "font" or key == "fontFlags" or key == "editBoxFontSize" then
      ConfigureEditBox(self.fonts.GlassEditBoxFont, Core.db.profile)
    end
  end)
end
