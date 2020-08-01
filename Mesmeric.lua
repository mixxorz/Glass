Mesmeric = LibStub("AceAddon-3.0"):NewAddon("Mesmeric", "AceConsole-3.0", "AceHook-3.0")

local lodash = LibStub("lodash.wow")

local drop, reduce, take = lodash.drop, lodash.reduce, lodash.take
local unpack = unpack

-- Use `message` for print because calling `print` will trigger an infinite loop
local print = function(...)
  local args = {...}
  ViragDevTool_AddData(unpack(args))
end

local function color(r, g, b)
  return { r = r / 255, g = g / 255, b = b / 255 }
end

local colors = {
  black = color(0, 0, 0),
  codGray = color(17, 17, 17),
  apache = color(223, 186, 105)
}

function Mesmeric:OnInitialize()
  self.config = {
    hideDefaultChatFrames = true,
    holdTime = 10,
    height = 200,
    width = 450,
    overflowHeight = 60
  }
  self.state = {
    hiddenChatFrames = {},
    mouseOver = false,
    showingTooltip = false
  }

  -- Main container
  self.container = CreateFrame("ScrollFrame", "MesmericFrame", UIParent)
  self.container:SetHeight(self.config.height + self.config.overflowHeight)
  self.container:SetWidth(self.config.width)
  self.container:SetPoint(
    "BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 260 - self.config.overflowHeight
  )

  self.container.bg = self.container:CreateTexture(nil, "BACKGROUND")
  self.container.bg:SetAllPoints()
  self.container.bg:SetColorTexture(0, 1, 0, 0)

  self.timeElapsed = 0
  self.container:SetScript("OnUpdate", function (frame, elapsed)
    self:OnUpdate(elapsed)
  end)

  -- Scrolling
  self.container:SetScript("OnMouseWheel", function (frame, delta)
    local currentScrollOffset = self.container:GetVerticalScroll()
    local scrollRange = self.container:GetVerticalScrollRange()

    -- Adjust scroll
    if delta < 0 and currentScrollOffset < scrollRange + self.config.overflowHeight then
      self.container:SetVerticalScroll(math.min(currentScrollOffset + 20, scrollRange + self.config.overflowHeight))
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

  -- Mouse clickthrough
  self.container:EnableMouse(false)

  -- ScrollChild
  self.slider = CreateFrame("Frame", "MesmericScrollChild", self.container)
  self.slider:SetHeight(self.config.height + self.config.overflowHeight)
  self.slider:SetWidth(self.config.width)
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
  font:SetFont("Fonts\\FRIZQT__.TTF", 12)
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

  self.dock = {}
  self.chatMessages = {}
  self.incomingChatMessages = {}
end

function Mesmeric:OnEnable()
  if self.config.hideDefaultChatFrames then
    self:HideDefaultChatFrames()
  end

  self:MountChatTabs()

  self:Hook(_G.ChatFrame1, "AddMessage", true)
end

function Mesmeric:OnDisable()
  self:ShowDefaultChatFrames()
  self.UnmountChatTabs()
  self:Unhook(_G.ChatFrame1, "AddMessage")
end

function Mesmeric:OnEnter()
  -- Don't hide chats when mouse is over
  self.state.mouseOver = true

  for _, message in ipairs(self.chatMessages) do
    if message.outroTimer then
      message.outroTimer:Cancel()
    end
  end
end

function Mesmeric:OnLeave()
  -- Hide chats when mouse leaves
  self.state.mouseOver = false

  for _, message in ipairs(self.chatMessages) do
    if message:IsVisible() then
      message.outroTimer = C_Timer.NewTimer(self.config.holdTime, function()
        message.outroAg:Play()
      end)
    end
  end
end

function Mesmeric:AddMessage(...)
  -- Enqueue messages to be displayed
  local args = {...}
  table.insert(self.incomingChatMessages, args)
end

local linkTypes = {
  item = true,
  enchant = true,
  spell = true,
  quest = true,
  achievement = true,
  currency = true,
  battlepet = true,
}

function Mesmeric:OnHyperlinkEnter(f, link, text)
  local t = string.match(link, "^(.-):")

  if linkTypes[t] then
    if t == "battlepet" then
      self.state.showingTooltip = BattlePetTooltip
      GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
      BattlePetToolTip_ShowLink(text)
    else
      self.state.showingTooltip = GameTooltip
      ShowUIPanel(GameTooltip)
      GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
      GameTooltip:SetHyperlink(link)
      GameTooltip:Show()
    end
  end
end

function Mesmeric:OnHyperlinkLeave(f, link)
  if self.state.showingTooltip then
    self.state.showingTooltip:Hide()
    self.state.showingTooltip = false
  end
end

function Mesmeric:ChatMessagePoolCreator()
  local width = 450
  local Xpadding = 15
  local opacity = 0.4

  local chatMessage = CreateFrame("Frame", nil, self.slider)
  chatMessage:SetWidth(width)
  chatMessage:SetHyperlinksEnabled(true)

  chatMessage:SetScript("OnHyperlinkClick", function (frame, link, text, button)
    SetItemRef(link, text, button)
  end)

  chatMessage:SetScript("OnHyperlinkEnter", function (...)
    local args = {...}
    self:OnHyperlinkEnter(unpack(args))
  end)

  chatMessage:SetScript("OnHyperlinkLeave", function (...)
    local args = {...}
    self:OnHyperlinkLeave(unpack(args))
  end)

  -- Background
  -- Left: 50 Center:300 Right: 100
  chatMessage.chatLineLeftBg = chatMessage:CreateTexture(nil, "BACKGROUND")
  chatMessage.chatLineLeftBg:SetPoint("LEFT")
  chatMessage.chatLineLeftBg:SetWidth(50)
  chatMessage.chatLineLeftBg:SetColorTexture(
    colors.codGray.r,
    colors.codGray.g,
    colors.codGray.b,
    opacity
  )
  chatMessage.chatLineLeftBg:SetGradientAlpha(
    "HORIZONTAL",
    0, 0, 0, 0,
    0, 0, 0, 1
  )

  chatMessage.chatLineCenterBg = chatMessage:CreateTexture(nil, "BACKGROUND")
  chatMessage.chatLineCenterBg:SetPoint("LEFT", 50, 0)
  chatMessage.chatLineCenterBg:SetWidth(150)
  chatMessage.chatLineCenterBg:SetColorTexture(
    colors.codGray.r,
    colors.codGray.g,
    colors.codGray.b,
    opacity
  )

  chatMessage.chatLineRightBg = chatMessage:CreateTexture(nil, "BACKGROUND")
  chatMessage.chatLineRightBg:SetPoint("RIGHT")
  chatMessage.chatLineRightBg:SetWidth(250)
  chatMessage.chatLineRightBg:SetColorTexture(
    colors.codGray.r,
    colors.codGray.g,
    colors.codGray.b,
    opacity
  )
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

function Mesmeric:MountChatTabs()
  self.state.chatTabsBefore = {
    point = GeneralDockManager:GetPoint(),
    size = GeneralDockManager:GetSize()
  }

  -- ChatTabDock
  GeneralDockManager:SetPoint("BOTTOMLEFT", self.container, "TOPLEFT", 0, 5)
  GeneralDockManager:SetSize(self.config.width, 20)
  GeneralDockManagerScrollFrame:SetHeight(20)
  GeneralDockManagerScrollFrame:SetPoint("TOPLEFT", _G.ChatFrame2Tab, "TOPRIGHT")
  GeneralDockManagerScrollFrameChild:SetHeight(20)

  local opacity = 0.4
  self.dock = {}

  self.dock.leftBg = GeneralDockManager:CreateTexture(nil, "BACKGROUND")
  self.dock.leftBg:SetPoint("LEFT")
  self.dock.leftBg:SetWidth(50)
  self.dock.leftBg:SetHeight(20)
  self.dock.leftBg:SetColorTexture(
    colors.black.r,
    colors.black.g,
    colors.black.b,
    opacity
  )
  self.dock.leftBg:SetGradientAlpha(
    "HORIZONTAL",
    0, 0, 0, 0,
    0, 0, 0, 1
  )

  self.dock.centerBg = GeneralDockManager:CreateTexture(nil, "BACKGROUND")
  self.dock.centerBg:SetPoint("LEFT", 50, 0)
  self.dock.centerBg:SetWidth(150)
  self.dock.centerBg:SetHeight(20)
  self.dock.centerBg:SetColorTexture(
    colors.black.r,
    colors.black.g,
    colors.black.b,
    opacity
  )

  self.dock.rightBg = GeneralDockManager:CreateTexture(nil, "BACKGROUND")
  self.dock.rightBg:SetPoint("LEFT", 200, 0)
  self.dock.rightBg:SetWidth(250)
  self.dock.rightBg:SetHeight(20)
  self.dock.rightBg:SetColorTexture(
    colors.black.r,
    colors.black.g,
    colors.black.b,
    opacity
  )
  self.dock.rightBg:SetGradientAlpha(
    "HORIZONTAL",
    0, 0, 0, 1,
    0, 0, 0, 0
  )

  local tabTexs = {
    '',
    'Selected',
    'Highlight'
  }

  -- Customize chat tabs
  for i=1, NUM_CHAT_WINDOWS do
    local tab = _G["ChatFrame"..i.."Tab"]

    for _, texName in ipairs(tabTexs) do
      _G['ChatFrame'..i..'Tab'..texName..'Left']:SetTexture()
      _G['ChatFrame'..i..'Tab'..texName..'Middle']:SetTexture()
      _G['ChatFrame'..i..'Tab'..texName..'Right']:SetTexture()
    end

    tab:SetHeight(20)
    tab:SetNormalFontObject("MesmericFont")
    tab.Text:ClearAllPoints()
    tab.Text:SetPoint("LEFT", 15, 0)
    tab:SetWidth(tab.Text:GetStringWidth() + 15 * 2)

    self:RawHook(tab, "SetAlpha", function (alpha)
      self.hooks[tab].SetAlpha(tab, 1)
    end, true)

    -- Set width dynamically based on text width
    self:RawHook(tab, "SetWidth", function (_, width)
      self.hooks[tab].SetWidth(tab, tab:GetTextWidth() + 15 * 2)
    end, true)

    self:RawHook(tab.Text, "SetTextColor", function (...)
      self.hooks[tab.Text].SetTextColor(tab.Text, colors.apache.r, colors.apache.g, colors.apache.b)
    end, true)
  end
end

function Mesmeric:UnmountChatTabs()
  GeneralDockManager:SetPoint(unpack(self.state.chatTabsBefore.point))
  GeneralDockManager:SetSize(unpack(self.state.chatTabsBefore.size))

  if self.dock then
    self.dock.leftBg:Hide()
    self.dock.centerBg:Hide()
    self.dock.rightBg:Hide()
  end
end

function Mesmeric:HideDefaultChatFrames()
  for i=1, NUM_CHAT_WINDOWS do
    local frame = _G["ChatFrame"..i]

    -- Remember the chat frames we hide so we can show them again later if
    -- necessary
    if frame:IsVisible() then
      table.insert(self.state.hiddenChatFrames, frame)
    end

    frame:SetScript("OnShow", function(...) frame:Hide() end)
    frame:Hide()
  end
end

function Mesmeric:ShowDefaultChatFrames()
  for i=1, NUM_CHAT_WINDOWS do
    local frame = _G["ChatFrame"..i]

    frame:SetScript("OnShow", function(...) frame:Show() end)
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
    self.container:SetVerticalScroll(newHeight - self.container:GetHeight() + self.config.overflowHeight)

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

  -- Mouse over tracking
  if self.state.mouseOver ~= MouseIsOver(self.container) then
    if not self.state.mouseOver then
      self:OnEnter()
    else
      self:OnLeave()
    end
  end
end
