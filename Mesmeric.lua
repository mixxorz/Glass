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
  self.translateUp:SetDuration(0.2)
  self.translateUp:SetSmoothing("OUT")

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
