Mesmeric = LibStub("AceAddon-3.0"):NewAddon("Mesmeric", "AceConsole-3.0", "AceHook-3.0")

local lodash = LibStub("lodash.wow")

local drop, reduce, take = lodash.drop, lodash.reduce, lodash.take
local unpack = unpack

-- Use `message` for print because calling `print` will trigger an infinite loop
local print = function(...)
  local args = {...}
  ViragDevTool_AddData(unpack(args))
end

function Mesmeric:OnInitialize()
  self.config = {
    hideDefaultChatFrames = true,
    holdTime = 7
  }
  self.state = {
    hiddenChatFrames = {}
  }

  -- Main container
  self.container = CreateFrame("ScrollFrame", "MesmericFrame", UIParent)
  self.container.bg = self.container:CreateTexture(nil, "BACKGROUND")
  self.container.bg:SetAllPoints()
  self.container.bg:SetColorTexture(0, 1, 0, 0)

  self.timeElapsed = 0
  self.container:SetScript("OnUpdate", function (frame, elapsed)
    self:OnUpdate(elapsed)
  end)

  self.container:SetHeight(360)
  self.container:SetWidth(450)
  self.container:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 260 - 60)

  -- Scrolling
  self.container:SetScript("OnMouseWheel", function (frame, delta)
    local currentScrollOffset = self.container:GetVerticalScroll()
    local scrollRange = self.container:GetVerticalScrollRange()

    -- Adjust scroll
    if delta < 0 and currentScrollOffset < scrollRange + 60 then
      self.container:SetVerticalScroll(math.min(currentScrollOffset + 20, scrollRange + 60))
    elseif delta > 0 and currentScrollOffset > self.container:GetHeight() then
      self.container:SetVerticalScroll(currentScrollOffset - 20)
    end

    -- Show hidden chat messages
    for _, message in ipairs(self.chatMessages) do
      if not message:IsVisible() then
        message:Show()
      end
    end
  end)

  -- Don't hide chats when mouse is over
  self.container:SetScript("OnEnter", function (frame, motion)
    self.state.mouseOver = true

    for _, message in ipairs(self.chatMessages) do
      if message.outroTimer then
        message.outroTimer:Cancel()
      end
    end
  end)

  -- Hide chats when mouse leaves
  self.container:SetScript("OnLeave", function (frame, motion)
    self.state.mouseOver = false

    for _, message in ipairs(self.chatMessages) do
      if message:IsVisible() then
        message.outroTimer = C_Timer.NewTimer(self.config.holdTime, function()
          message.outroAg:Play()
        end)
      end
    end
  end)

  -- Frame that translates up when a new message comes in
  self.slider = CreateFrame("Frame", "MesmericScrollChild", self.container)
  self.slider:SetHeight(360)
  self.slider:SetWidth(450)
  self.container:SetScrollChild(self.slider)

  self.slider.bg = self.slider:CreateTexture(nil, "BACKGROUND")
  self.slider.bg:SetAllPoints()
  self.slider.bg:SetColorTexture(0, 0, 1, 0)

  -- Initialize slide up animations
  self.sliderAg = self.slider:CreateAnimationGroup()
  self.sliderStartOffset = self.sliderAg:CreateAnimation("Translation")
  self.sliderStartOffset:SetDuration(0)

  self.sliderTranslateUp = self.sliderAg:CreateAnimation("Translation")
  self.sliderTranslateUp:SetDuration(0.3)
  self.sliderTranslateUp:SetSmoothing("OUT")

  -- Main font
  local font = CreateFont("MesmericFont")
  font:SetFont("Fonts\\ARIALN.TTF", 14)
  font:SetShadowColor(0, 0, 0, 1)
  font:SetShadowOffset(1, -1)
  font:SetJustifyH("LEFT")
  font:SetJustifyV("MIDDLE")
  font:SetSpacing(3)

  -- Pool for the chat message frames
  self.chatMessageFramePool = CreateObjectPool(
    function () return self:ChatMessagePoolCreator() end,
    function (_, chatMessage)
      -- Reset all animations and timers
      if chatMessage.outroTimer then
        chatMessage.outroTimer:Cancel()
      end

      chatMessage.introAg:Stop()
      chatMessage.outroAg:Stop()
      chatMessage:Hide()
    end
  )

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

function Mesmeric:ChatMessagePoolCreator()
  local width = 450
  local Xpadding = 15
  local opacity = 0.4

  local chatMessage = CreateFrame("Frame", nil, self.slider)
  chatMessage:SetWidth(width)

  -- Background
  -- Left: 50 Center:300 Right: 100
  chatMessage.chatLineLeftBg = chatMessage:CreateTexture(nil, "BACKGROUND")
  chatMessage.chatLineLeftBg:SetPoint("LEFT")
  chatMessage.chatLineLeftBg:SetWidth(50)
  chatMessage.chatLineLeftBg:SetColorTexture(0, 0, 0, opacity)
  chatMessage.chatLineLeftBg:SetGradientAlpha(
    "HORIZONTAL",
    0, 0, 0, 0,
    0, 0, 0, 1
  )

  chatMessage.chatLineCenterBg = chatMessage:CreateTexture(nil, "BACKGROUND")
  chatMessage.chatLineCenterBg:SetPoint("LEFT", 50, 0)
  chatMessage.chatLineCenterBg:SetWidth(150)
  chatMessage.chatLineCenterBg:SetColorTexture(0, 0, 0, opacity)

  chatMessage.chatLineRightBg = chatMessage:CreateTexture(nil, "BACKGROUND")
  chatMessage.chatLineRightBg:SetPoint("RIGHT")
  chatMessage.chatLineRightBg:SetWidth(250)
  chatMessage.chatLineRightBg:SetColorTexture(0, 0, 0, opacity)
  chatMessage.chatLineRightBg:SetGradientAlpha(
    "HORIZONTAL",
    0, 0, 0, 1,
    0, 0, 0, 0
  )

  chatMessage.text = chatMessage:CreateFontString(nil, "ARTWORK", "MesmericFont")
  chatMessage.text:SetPoint("LEFT", Xpadding, 0)
  chatMessage.text:SetWidth(width - Xpadding * 2)

  -- Intro animations
  chatMessage.introAg = chatMessage:CreateAnimationGroup()
  local fadeIn = chatMessage.introAg:CreateAnimation("Alpha")
  fadeIn:SetFromAlpha(0)
  fadeIn:SetToAlpha(1)
  fadeIn:SetDuration(0.6)
  fadeIn:SetSmoothing("OUT")

  -- Outro animations
  chatMessage.outroAg = chatMessage:CreateAnimationGroup()
  local fadeOut = chatMessage.outroAg:CreateAnimation("Alpha")
  fadeOut:SetFromAlpha(1)
  fadeOut:SetToAlpha(0)
  fadeOut:SetDuration(0.6)
  fadeOut:SetEndDelay(1)

  -- Hide the frame when the outro animation finishes
  chatMessage.outroAg:SetScript("OnFinished", function ()
    chatMessage:Hide()
  end)

  -- Start intro animation when element is shown
  chatMessage:SetScript("OnShow", function ()
    chatMessage.introAg:Play()

    -- Play outro after hold time
    if not self.state.mouseOver then
      chatMessage.outroTimer = C_Timer.NewTimer(self.config.holdTime, function()
        chatMessage.outroAg:Play()
      end)
    end
  end)

  return chatMessage
end

function Mesmeric:CreateChatMessageFrame(frame, text, red, green, blue, messageId, holdTime)
  holdTime = self.config.holdTime
  red = red or 1
  green = green or 1
  blue = blue or 1

  local Ypadding = 3

  local chatMessage = self.chatMessageFramePool:Acquire()
  chatMessage:SetPoint("BOTTOMLEFT")

  -- Attach previous chat message to this one
  if self.prevLine then
    self.prevLine:ClearAllPoints()
    self.prevLine:SetPoint("BOTTOMLEFT", chatMessage, "TOPLEFT")
  end

  self.prevLine = chatMessage

  chatMessage.text:SetTextColor(red, green, blue, 1)
  chatMessage.text:SetText(text)

  -- Adjust height to contain text
  local chatLineHeight = (chatMessage.text:GetStringHeight() + Ypadding * 2)
  chatMessage:SetHeight(chatLineHeight)
  chatMessage.chatLineLeftBg:SetHeight(chatLineHeight)
  chatMessage.chatLineCenterBg:SetHeight(chatLineHeight)
  chatMessage.chatLineRightBg:SetHeight(chatLineHeight)

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
  -- Make sure previous iteration is complete before running again
  if #self.incomingChatMessages > 0 and not self.sliderAg:IsPlaying() then
    -- Create new chat message frame for each chat message
    local newChatMessages = {}

    for _, message in ipairs(self.incomingChatMessages) do
      table.insert(newChatMessages, self:CreateChatMessageFrame(unpack(message)))
    end

    -- Update slider offsets animation
    local offset = reduce(newChatMessages, function (acc, chatMessage)
      return acc + chatMessage:GetHeight()
    end, 0)

    local newHeight = self.slider:GetHeight() + offset
    self.slider:SetHeight(newHeight)
    self.sliderStartOffset:SetOffset(0, offset * -1)
    self.sliderTranslateUp:SetOffset(0, offset)

    -- Display and run everything
    self.container:SetVerticalScroll(newHeight - self.container:GetHeight() + 60)

    for _, chatMessageFrame in ipairs(newChatMessages) do
      chatMessageFrame:Show()
      table.insert(self.chatMessages, chatMessageFrame)
    end

    self.sliderAg:Play()

    -- Release old chat messages
    local chatHistoryLimit = 128
    if #self.chatMessages > chatHistoryLimit then
      local overflow = #self.chatMessages - chatHistoryLimit
      local oldChatMessages = take(self.chatMessages, overflow)
      self.chatMessages = drop(self.chatMessages, overflow)

      for _, chatMessage in ipairs(oldChatMessages) do
        self.chatMessageFramePool:Release(chatMessage)
      end
    end

    -- Reset
    self.incomingChatMessages = {}
  end
end
