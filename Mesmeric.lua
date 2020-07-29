Mesmeric = LibStub("AceAddon-3.0"):NewAddon("Mesmeric", "AceConsole-3.0", "AceHook-3.0")

local lodash = LibStub("lodash.wow")

local reduce = lodash.reduce
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
  local container = CreateFrame("Frame", "Mesmeric", UIParent)

  self.timeElapsed = 0
  container:SetScript("OnUpdate", function (frame, elapsed)
    self:OnUpdate(elapsed)
  end)

  container:SetHeight(400)
  container:SetWidth(450)
  container:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 260)

  -- Main font
  local font = CreateFont("MesmericFont")
  font:SetFont("Fonts\\ARIALN.TTF", 14)
  font:SetShadowColor(0, 0, 0, 1)
  font:SetShadowOffset(1, -1)
  font:SetJustifyH("LEFT")
  font:SetJustifyV("MIDDLE")
  font:SetSpacing(3)

  -- Frame that translates up when a new message comes in
  self.slider = CreateFrame("Frame", nil, container)
  self.slider:SetAllPoints(container)

  self.chatMessageFramePool = CreateFramePool("Frame", self.slider)

  self.chatMessages = {}
  self.incomingChatMessages = {}
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

function Mesmeric:AddMessage(...)
  -- Enqueue messages to be displayed
  local args = {...}
  table.insert(self.incomingChatMessages, args)
end

function Mesmeric:CreateChatMessageFrame(frame, text, red, green, blue, messageId, holdTime)
  holdTime = 10
  red = red or 1
  green = green or 1
  blue = blue or 1

  local width = 450
  local Xpadding = 15
  local Ypadding = 3
  local opacity = 0.4

  local chatMessage = self.chatMessageFramePool:Acquire()
  chatMessage:SetWidth(width)
  chatMessage:SetPoint("BOTTOMLEFT")

  -- Attach previous chat message to this one
  if self.prevLine then
    self.prevLine:ClearAllPoints()
    self.prevLine:SetPoint("BOTTOMLEFT", chatMessage, "TOPLEFT")
  end

  self.prevLine = chatMessage

  -- Background
  -- Left: 50 Center:300 Right: 100
  local chatLineLeftBg = chatMessage:CreateTexture(nil, "BACKGROUND")
  chatLineLeftBg:SetPoint("LEFT")
  chatLineLeftBg:SetWidth(50)
  chatLineLeftBg:SetColorTexture(0, 0, 0, opacity)
  chatLineLeftBg:SetGradientAlpha(
    "HORIZONTAL",
    0, 0, 0, 0,
    0, 0, 0, 1
  )

  local chatLineCenterBg = chatMessage:CreateTexture(nil, "BACKGROUND")
  chatLineCenterBg:SetPoint("LEFT", 50, 0)
  chatLineCenterBg:SetWidth(150)
  chatLineCenterBg:SetColorTexture(0, 0, 0, opacity)

  local chatLineRightBg = chatMessage:CreateTexture(nil, "BACKGROUND")
  chatLineRightBg:SetPoint("RIGHT")
  chatLineRightBg:SetWidth(250)
  chatLineRightBg:SetColorTexture(0, 0, 0, opacity)
  chatLineRightBg:SetGradientAlpha(
    "HORIZONTAL",
    0, 0, 0, 1,
    0, 0, 0, 0
  )

  local textLayer = chatMessage:CreateFontString(nil, "ARTWORK", "MesmericFont")
  textLayer:SetTextColor(red, green, blue, 1)
  textLayer:SetPoint("LEFT", Xpadding, 0)
  textLayer:SetWidth(width - Xpadding * 2)
  textLayer:SetText(text)

  -- Adjust height to contain text
  local chatLineHeight = (textLayer:GetStringHeight() + Ypadding * 2)
  chatMessage:SetHeight(chatLineHeight)
  chatLineLeftBg:SetHeight(chatLineHeight)
  chatLineCenterBg:SetHeight(chatLineHeight)
  chatLineRightBg:SetHeight(chatLineHeight)

  -- Intro animations
  local introAg = chatMessage:CreateAnimationGroup()
  local fadeIn = introAg:CreateAnimation("Alpha")
  fadeIn:SetFromAlpha(0)
  fadeIn:SetToAlpha(1)
  fadeIn:SetDuration(1)
  fadeIn:SetSmoothing("OUT")

  -- Outro animations
  local outroAg = chatMessage:CreateAnimationGroup()
  local fadeOut = outroAg:CreateAnimation("Alpha")
  fadeOut:SetFromAlpha(1)
  fadeOut:SetToAlpha(0)
  fadeOut:SetDuration(0.5)
  fadeOut:SetEndDelay(1)

  -- Hide the frame when the outro animation finishes
  outroAg:SetScript("OnFinished", function ()
    chatMessage:Hide()
  end)

  -- Start intro animation when element is shown
  chatMessage:SetScript("OnShow", function ()
    introAg:Play()

    -- Play outro after hold time
    C_Timer.After(holdTime, function()
      outroAg:Play()
    end)
  end)

  return chatMessage
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
    self.timeElapsed = self.timeElapsed - 0.1
    self:Draw()
  end
end

function Mesmeric:Draw()
  if #self.incomingChatMessages > 0 then
    -- Create new chat message frame for each chat message
    local newChatMessages = {}

    for _, message in ipairs(self.incomingChatMessages) do
      table.insert(newChatMessages, self:CreateChatMessageFrame(unpack(message)))
    end

    local offset = reduce(newChatMessages, function (acc, chatMessage)
      return acc + chatMessage:GetHeight()
    end, 0)

    -- Create a new container animation
    local sliderAg = self.slider:CreateAnimationGroup()
    local startOffset = sliderAg:CreateAnimation("Translation")
    startOffset:SetDuration(0)
    startOffset:SetOffset(0, offset * -1)

    local translateUp = sliderAg:CreateAnimation("Translation")
    translateUp:SetDuration(0.3)
    translateUp:SetOffset(0, offset)
    translateUp:SetSmoothing("OUT")

    -- Display and run everything
    for _, chatMessageFrame in ipairs(newChatMessages) do
      chatMessageFrame:Show()
    end

    sliderAg:Play()

    -- Reset
    self.incomingChatMessages = {}
  end
end
