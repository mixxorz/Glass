Mesmeric = LibStub("AceAddon-3.0"):NewAddon("Mesmeric", "AceConsole-3.0", "AceHook-3.0")

local unpack = unpack

-- Use `message` for print because calling `print` will trigger an infinite loop
local print = function(...)
  local args = {...}
  ViragDevTool_AddData(unpack(args))
end

function Mesmeric:OnInitialize()
  self.config = {
    hideDefaultChatFrames = true
  }
  self.state = {
    hiddenChatFrames = {}
  }

  -- Main container
  self.container = CreateFrame("Frame", "Mesmeric", UIParent)

  self.timeElapsed = 0
  self.container:SetScript("OnUpdate", function (frame, elapsed)
    self:OnUpdate(elapsed)
  end)

  self.container:SetHeight(400)
  self.container:SetWidth(450)
  self.container:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 260)

  self.containerAg = self.container:CreateAnimationGroup()
  self.startOffset = self.containerAg:CreateAnimation("Translation")
  self.startOffset:SetDuration(0)

  self.translateUp = self.containerAg:CreateAnimation("Translation")
  self.translateUp:SetDuration(0.3)
  self.translateUp:SetSmoothing("OUT")

  -- Main font
  local font = CreateFont("MesmericFont")
  font:SetFont("Fonts\\ARIALN.TTF", 14)
  font:SetShadowColor(0, 0, 0, 1)
  font:SetShadowOffset(1, -1)
  font:SetJustifyH("LEFT")
  font:SetJustifyV("MIDDLE")
  font:SetSpacing(3)

  self.chatLinePool = CreateFramePool("Frame", self.container)
end

function Mesmeric:OnEnable()
  if self.config.hideDefaultChatFrames then
    self:HideDefaultChatFrames()
  end
  self:Hook(_G.ChatFrame1, "AddMessage", true)
end

function Mesmeric:OnDisable()
  self:ShowDefaultChatFrames()
  self:Unhook(_G.ChatFrame1, "AddMessage")
end

function Mesmeric:AddMessage(frame, text, red, green, blue, messageId, holdTime)
  holdTime = 10
  red = red or 1
  green = green or 1
  blue = blue or 1

  local width = 450
  local Xpadding = 15
  local Ypadding = 3
  local opacity = 0.4

  local chatLine = self.chatLinePool:Acquire()
  chatLine:SetWidth(width)
  chatLine:SetPoint("TOPLEFT", self.container, "BOTTOMLEFT")

  if self.prevLine then
    self.prevLine:ClearAllPoints()
    self.prevLine:SetPoint("BOTTOMLEFT", chatLine, "TOPLEFT")
  end

  self.prevLine = chatLine

  -- Background
  -- Left: 50 Center:300 Right: 100
  local chatLineLeftBg = chatLine:CreateTexture(nil, "BACKGROUND")
  chatLineLeftBg:SetPoint("LEFT")
  chatLineLeftBg:SetWidth(50)
  chatLineLeftBg:SetColorTexture(0, 0, 0, opacity)
  chatLineLeftBg:SetGradientAlpha(
    "HORIZONTAL",
    0, 0, 0, 0,
    0, 0, 0, 1
  )

  local chatLineCenterBg = chatLine:CreateTexture(nil, "BACKGROUND")
  chatLineCenterBg:SetPoint("LEFT", 50, 0)
  chatLineCenterBg:SetWidth(150)
  chatLineCenterBg:SetColorTexture(0, 0, 0, opacity)

  local chatLineRightBg = chatLine:CreateTexture(nil, "BACKGROUND")
  chatLineRightBg:SetPoint("RIGHT")
  chatLineRightBg:SetWidth(250)
  chatLineRightBg:SetColorTexture(0, 0, 0, opacity)
  chatLineRightBg:SetGradientAlpha(
    "HORIZONTAL",
    0, 0, 0, 1,
    0, 0, 0, 0
  )

  local textLayer = chatLine:CreateFontString(nil, "ARTWORK", "MesmericFont")
  textLayer:SetTextColor(red, green, blue, 1)
  textLayer:SetPoint("LEFT", Xpadding, 0)
  textLayer:SetWidth(width - Xpadding * 2)
  textLayer:SetText(text)

  -- Adjust height to contain text
  local chatLineHeight = (textLayer:GetStringHeight() + Ypadding * 2)
  chatLine:SetHeight(chatLineHeight)
  chatLineLeftBg:SetHeight(chatLineHeight)
  chatLineCenterBg:SetHeight(chatLineHeight)
  chatLineRightBg:SetHeight(chatLineHeight)
  self.startOffset:SetOffset(0, chatLineHeight * -1)
  self.translateUp:SetOffset(0, chatLineHeight)
  print(self.startOffset, "startOffset")
  print(self.translateUp, "translateUp")

  -- Intro animations
  local introAg = chatLine:CreateAnimationGroup()
  local fadeIn = introAg:CreateAnimation("Alpha")
  fadeIn:SetFromAlpha(0)
  fadeIn:SetToAlpha(1)
  fadeIn:SetDuration(1)
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
  fadeOut:SetDuration(0.5)
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
  for i=1, NUM_CHAT_WINDOWS do
    local frame = _G["ChatFrame"..i]
    local tab = _G["ChatFrame"..i.."Tab"]

    -- Remember the chat frames we hide so we can show them again later if
    -- necessary
    if frame:IsVisible() then
      table.insert(self.state.hiddenChatFrames, frame)
    end

    if tab:IsVisible() then
      table.insert(self.state.hiddenChatFrames, tab)
    end

    frame:SetScript("OnShow", function(...) frame:Hide() end)
    tab:SetScript("OnShow", function(...) tab:Hide() end)

    frame:Hide()
    tab:Hide()
  end
end

function Mesmeric:ShowDefaultChatFrames()
  for i=1, NUM_CHAT_WINDOWS do
    local frame = _G["ChatFrame"..i]
    local tab = _G["ChatFrame"..i.."Tab"]

    frame:SetScript("OnShow", function(...) frame:Show() end)
    tab:SetScript("OnShow", function(...) tab:Show() end)
  end

  for _, frame in ipairs(self.state.hiddenChatFrames) do
    frame:Show()
  end

  self.state.hiddenChatFrames = {}
end

function Mesmeric:ChatHandler(input)
  if input == "hidedefault" then
    self:HideDefaultChatFrames()
  elseif input == "showdefault" then
    self:ShowDefaultChatFrames()
  end
end

Mesmeric:RegisterChatCommand("mesmeric", "ChatHandler")

function Mesmeric:OnUpdate(elapsed)
  self.timeElapsed = self.timeElapsed + elapsed
  while (self.timeElapsed > 0.1) do
    self.timeElapsed = self.timeElapsed - 0.01
    self:Draw()
  end
end

function Mesmeric:Draw()
end
