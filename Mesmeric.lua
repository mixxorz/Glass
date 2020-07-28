Mesmeric = LibStub("AceAddon-3.0"):NewAddon("Mesmeric", "AceConsole-3.0", "AceHook-3.0")

local unpack = unpack

-- Use `message` for print because calling `print` will trigger an infinite loop
local print = function(...)
  local args = {...}
  ViragDevTool_AddData(unpack(args))
end

local DEFAULT_CHAT_FRAMES = {
  _G.ChatFrame1,
  _G.ChatFrame2,
  _G.ChatFrame3,
  _G.ChatFrame4,
  _G.ChatFrame5,
  _G.ChatFrame6,
  _G.ChatFrame7,
  _G.ChatFrame8,
  _G.ChatFrame9,
  _G.ChatFrame10,
}

local DEFAULT_CHAT_FRAME_TABS = {
  _G.ChatFrame1Tab,
  _G.ChatFrame2Tab,
  _G.ChatFrame3Tab,
  _G.ChatFrame4Tab,
  _G.ChatFrame5Tab,
  _G.ChatFrame6Tab,
  _G.ChatFrame7Tab,
  _G.ChatFrame8Tab,
  _G.ChatFrame9Tab,
  _G.ChatFrame10Tab,
}

function Mesmeric:OnInitialize()
  self.container = CreateFrame("Frame", "Mesmeric", UIParent)
  self.container:SetHeight(400)
  self.container:SetWidth(450)
  self.container:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 260)

  self.containerAg = self.container:CreateAnimationGroup()
  self.startOffset = self.containerAg:CreateAnimation("Translation")
  self.startOffset:SetDuration(0)

  self.translateUp = self.containerAg:CreateAnimation("Translation")
  self.translateUp:SetDuration(0.2)
  self.translateUp:SetSmoothing("OUT")

  self.chatLinePool = CreateFramePool("Frame", self.container)

  self.hiddenChatFrames = {}
end

function Mesmeric:OnEnable()
  self:HideDefaultChatFrames()
  self:Hook(_G.ChatFrame1, "AddMessage", true)
end

function Mesmeric:OnDisable()
  self:ShowDefaultChatFrames()
  self:Unhook(_G.ChatFrame1, "AddMessage")
end

function Mesmeric:AddMessage(frame, text, red, green, blue, messageId, holdTime)
  holdTime = holdTime or 5
  red = red or 1
  green = green or 1
  blue = blue or 1

  local padding = 3
  local lineHeight = 3

  local chatLine = self.chatLinePool:Acquire()
  chatLine:SetWidth(450)
  chatLine:SetPoint("TOPLEFT", self.container, "BOTTOMLEFT")

  if self.prevLine then
    self.prevLine:ClearAllPoints()
    self.prevLine:SetPoint("BOTTOMLEFT", chatLine, "TOPLEFT")
  end

  self.prevLine = chatLine

  local chatLineBg = chatLine:CreateTexture(nil, "BACKGROUND")
  chatLineBg:SetAllPoints()
  chatLineBg:SetColorTexture(0, 0, 0, 0.6)

  local textLayer = chatLine:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  textLayer:SetTextColor(red, green, blue, 1)
  textLayer:SetPoint("LEFT", padding, 0)
  textLayer:SetJustifyH("LEFT")
  textLayer:SetJustifyV("MIDDLE")
  textLayer:SetSpacing(lineHeight)
  textLayer:SetWidth(450 - padding * 2)
  textLayer:SetText(text)

  -- Adjust height to contain text
  local chatLineHeight = (textLayer:GetStringHeight() + padding * 2)
  chatLine:SetHeight(chatLineHeight)
  self.startOffset:SetOffset(0, chatLineHeight * -1)
  self.translateUp:SetOffset(0, chatLineHeight)
  print(self.startOffset, "startOffset")
  print(self.translateUp, "translateUp")

  -- Intro animations
  local introAg = chatLine:CreateAnimationGroup()
  local fadeIn = introAg:CreateAnimation("Alpha")
  fadeIn:SetFromAlpha(0)
  fadeIn:SetToAlpha(1)
  fadeIn:SetDuration(0.2)
  fadeIn:SetSmoothing("OUT")

  -- Start intor animation
  chatLine:Show()
  introAg:Play()
  self.containerAg:Play()

  -- Outro animations
  local outroAg = chatLine:CreateAnimationGroup()
  local fadeOut = outroAg:CreateAnimation("Alpha")
  fadeOut:SetFromAlpha(1)
  fadeOut:SetToAlpha(0)
  fadeOut:SetDuration(5)
  fadeOut:SetEndDelay(1)

  outroAg:SetScript("OnFinished", function ()
    chatLine:Hide()
  end)

  -- Play outro after hold time
  C_Timer.After(holdTime, function()
    outroAg:Play()
  end)
end

function Mesmeric:HideDefaultChatFrames()
  for _, frame in ipairs(DEFAULT_CHAT_FRAMES) do
    if frame:IsVisible() then
      frame:Hide()
      table.insert(self.hiddenChatFrames, frame)
    end
  end

  for _, frame in ipairs(DEFAULT_CHAT_FRAME_TABS) do
    if frame:IsVisible() then
      frame:Hide()
      table.insert(self.hiddenChatFrames, frame)
    end
  end
end

function Mesmeric:ShowDefaultChatFrames()
  for _, frame in ipairs(self.hiddenChatFrames) do
    frame:Show()
  end

  -- Reset
  self.hiddenChatFrames = {}
end

function Mesmeric:ChatHandler(input)
  if input == "hidedefault" then
    self:HideDefaultChatFrames()
  elseif input == "showdefault" then
    self:ShowDefaultChatFrames()
  end
end

Mesmeric:RegisterChatCommand("mesmeric", "ChatHandler")
