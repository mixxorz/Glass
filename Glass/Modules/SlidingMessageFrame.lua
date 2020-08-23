local Core, Constants = unpack(select(2, ...))
local MC = Core:GetModule("MainContainer")
local SMF = Core:GetModule("SlidingMessageFrame")
local TP = Core:GetModule("TextProcessing")

local LSM = Core.Libs.LSM

-- luacheck: push ignore 113
local BattlePetToolTip_ShowLink = BattlePetToolTip_ShowLink
local BattlePetTooltip = BattlePetTooltip
local C_Timer = C_Timer
local CreateFont = CreateFont
local CreateFrame = CreateFrame
local CreateObjectPool = CreateObjectPool
local GameTooltip = GameTooltip
local GeneralDockManager = GeneralDockManager
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
local SetItemRef = SetItemRef
local ShowUIPanel = ShowUIPanel
local UIParent = UIParent
-- luacheck: pop

local lodash = Core.Libs.lodash
local drop, reduce, take = lodash.drop, lodash.reduce, lodash.take

local Colors = Constants.COLORS

local linkTypes = {
  item = true,
  enchant = true,
  spell = true,
  quest = true,
  achievement = true,
  currency = true,
  battlepet = true,
}

local SlidingMessageFrame = {}

----
-- SlidingMessageFrame
--
-- Custom frame for displaying pretty sliding messages
function SlidingMessageFrame:Create()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function SlidingMessageFrame:Initialize()
  self.config = {
    height = MC:GetFrame():GetHeight() - GeneralDockManager:GetHeight() - 5,
    width = MC:GetFrame():GetWidth(),
    messageOpacity = Core.db.profile.chatBackgroundOpacity,
    overflowHeight = 60,
    xPadding = 15
  }
  self.state = {
    mouseOver = false,
    showingTooltip = false,
    incomingMessages = {},
    messages = {}
  }

  -- Chat scroll frame
  self.scrollFrame = CreateFrame("ScrollFrame", "GlassScrollFrame", MC:GetFrame())
  self.scrollFrame:SetHeight(self.config.height + self.config.overflowHeight)
  self.scrollFrame:SetWidth(self.config.width)
  self.scrollFrame:SetPoint("BOTTOMLEFT", 0, self.config.overflowHeight * -1)

  self.scrollFrame.bg = self.scrollFrame:CreateTexture(nil, "BACKGROUND")
  self.scrollFrame.bg:SetAllPoints()
  self.scrollFrame.bg:SetColorTexture(0, 1, 0, 0)

  self.timeElapsed = 0
  self.scrollFrame:SetScript("OnUpdate", function (frame, elapsed)
    self:OnUpdate(elapsed)
  end)

  -- Scrolling
  self.scrollFrame:SetScript("OnMouseWheel", function (frame, delta)
    local currentScrollOffset = self.scrollFrame:GetVerticalScroll()
    local scrollRange = self.scrollFrame:GetVerticalScrollRange()

    -- Adjust scroll
    if delta < 0 and currentScrollOffset < scrollRange + self.config.overflowHeight then
      self.scrollFrame:SetVerticalScroll(math.min(currentScrollOffset + 20, scrollRange + self.config.overflowHeight))
    elseif delta > 0 and currentScrollOffset > self.scrollFrame:GetHeight() then
      self.scrollFrame:SetVerticalScroll(currentScrollOffset - 20)
    end

    -- Show hidden messages
    for _, message in ipairs(self.state.messages) do
      if not message:IsVisible() then
        message:Show()
      end
    end
  end)

  -- Mouse clickthrough
  self.scrollFrame:EnableMouse(false)

  -- ScrollChild
  self.slider = CreateFrame("Frame", nil, self.scrollFrame)
  self.slider:SetHeight(self.config.height + self.config.overflowHeight)
  self.slider:SetWidth(self.config.width)
  self.scrollFrame:SetScrollChild(self.slider)

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

  -- Pool for the message frames
  self.messageFramePool = CreateObjectPool(
    function () return self:MessagePoolCreator() end,
    function (_, message)
      -- Reset all animations and timers
      if message.outroTimer then
        message.outroTimer:Cancel()
      end

      message.introAg:Stop()
      message.outroAg:Stop()
      message:Hide()
    end
  )
end

function SlidingMessageFrame:Show()
  self.scrollFrame:Show()
end

function SlidingMessageFrame:Hide()
  self.scrollFrame:Hide()
end

function SlidingMessageFrame:IsVisible()
  return self.scrollFrame:IsVisible()
end

function SlidingMessageFrame:MessagePoolCreator()
  local message = CreateFrame("Frame", nil, self.slider)
  message:SetWidth(self.config.width)

  -- Hyperlink handling
  message:SetHyperlinksEnabled(true)

  message:SetScript("OnHyperlinkClick", function (frame, link, text, button)
    SetItemRef(link, text, button)
  end)

  message:SetScript("OnHyperlinkEnter", function (...)
    if Core.db.profile.mouseOverTooltips then
      local args = {...}
      self:OnHyperlinkEnter(unpack(args))
    end
  end)

  message:SetScript("OnHyperlinkLeave", function (...)
    local args = {...}
    self:OnHyperlinkLeave(unpack(args))
  end)

  -- Gradient background
  message.leftBg = message:CreateTexture(nil, "BACKGROUND")
  message.leftBg:SetPoint("LEFT")
  message.leftBg:SetWidth(50)
  message.leftBg:SetColorTexture(1, 1, 1, 1)
  message.leftBg:SetGradientAlpha(
    "HORIZONTAL",
    Colors.codGray.r, Colors.codGray.g, Colors.codGray.b, 0,
    Colors.codGray.r, Colors.codGray.g, Colors.codGray.b, self.config.messageOpacity
  )

  message.centerBg = message:CreateTexture(nil, "BACKGROUND")
  message.centerBg:SetPoint("LEFT", 50, 0)
  message.centerBg:SetPoint("RIGHT", -250, 0)
  message.centerBg:SetColorTexture(
    Colors.codGray.r,
    Colors.codGray.g,
    Colors.codGray.b,
    self.config.messageOpacity
  )

  message.rightBg = message:CreateTexture(nil, "BACKGROUND")
  message.rightBg:SetPoint("RIGHT")
  message.rightBg:SetWidth(250)
  message.rightBg:SetColorTexture(1, 1, 1, 1)
  message.rightBg:SetGradientAlpha(
    "HORIZONTAL",
    Colors.codGray.r, Colors.codGray.g, Colors.codGray.b, self.config.messageOpacity,
    Colors.codGray.r, Colors.codGray.g, Colors.codGray.b, 0
  )

  message.text = message:CreateFontString(nil, "ARTWORK", "GlassMessageFont")
  message.text:SetPoint("LEFT", self.config.xPadding, 0)
  message.text:SetWidth(self.config.width - self.config.xPadding * 2)

  -- Intro animations
  message.introAg = message:CreateAnimationGroup()
  local fadeIn = message.introAg:CreateAnimation("Alpha")
  fadeIn:SetFromAlpha(0)
  fadeIn:SetToAlpha(1)
  fadeIn:SetDuration(0.6)
  fadeIn:SetSmoothing("OUT")

  -- Outro animations
  message.outroAg = message:CreateAnimationGroup()
  local fadeOut = message.outroAg:CreateAnimation("Alpha")
  fadeOut:SetFromAlpha(1)
  fadeOut:SetToAlpha(0)
  fadeOut:SetDuration(0.6)

  -- Hide the frame when the outro animation finishes
  message.outroAg:SetScript("OnFinished", function ()
    message:Hide()
  end)

  -- Start intro animation when element is shown
  message:SetScript("OnShow", function ()
    message.introAg:Play()

    -- Play outro after hold time
    if not self.state.mouseOver then
      message.outroTimer = C_Timer.NewTimer(Core.db.profile.chatHoldTime, function()
        if message:IsVisible() then
          message.outroAg:Play()
        end
      end)
    end
  end)

  -- Methods

  ---
  -- Update height based on text height
  function message.UpdateFrame()
    local Ypadding = message.text:GetLineHeight() * 0.25
    local messageLineHeight = (message.text:GetStringHeight() + Ypadding * 2)
    message:SetHeight(messageLineHeight)
    message.leftBg:SetHeight(messageLineHeight)
    message.centerBg:SetHeight(messageLineHeight)
    message.rightBg:SetHeight(messageLineHeight)

    message:SetWidth(self.config.width)
    message.text:SetWidth(self.config.width - self.config.xPadding * 2)
  end

  ---
  -- Update texture color based on setting
  function message.UpdateTextures()
    self.config.messageOpacity = Core.db.profile.chatBackgroundOpacity

    message.leftBg:SetGradientAlpha(
      "HORIZONTAL",
      Colors.codGray.r, Colors.codGray.g, Colors.codGray.b, 0,
      Colors.codGray.r, Colors.codGray.g, Colors.codGray.b, self.config.messageOpacity
    )

    message.centerBg:SetColorTexture(
      Colors.codGray.r,
      Colors.codGray.g,
      Colors.codGray.b,
      self.config.messageOpacity
    )

    message.rightBg:SetGradientAlpha(
      "HORIZONTAL",
      Colors.codGray.r, Colors.codGray.g, Colors.codGray.b, self.config.messageOpacity,
      Colors.codGray.r, Colors.codGray.g, Colors.codGray.b, 0
    )
  end

  return message
end

function SlidingMessageFrame:CreateMessageFrame(frame, text, red, green, blue, messageId, holdTime)
  red = red or 1
  green = green or 1
  blue = blue or 1

  local message = self.messageFramePool:Acquire()
  message:SetPoint("BOTTOMLEFT")

  -- Attach previous message to this one
  if self.prevLine then
    self.prevLine:ClearAllPoints()
    self.prevLine:SetPoint("BOTTOMLEFT", message, "TOPLEFT")
  end

  self.prevLine = message

  message.text:SetTextColor(red, green, blue, 1)
  message.text:SetText(TP:ProcessText(text))

  -- Adjust height to contain text
  message:UpdateFrame()

  return message
end

function SlidingMessageFrame:OnEnterContainer()
  -- Don't hide chats when mouse is over
  self.state.mouseOver = true

  for _, message in ipairs(self.state.messages) do
    if Core.db.profile.chatShowOnMouseOver and not message:IsVisible() then
      message:Show()
    end

    if message.outroTimer then
      message.outroTimer:Cancel()
    end
  end
end

function SlidingMessageFrame:OnLeaveContainer()
  -- Hide chats when mouse leaves
  self.state.mouseOver = false

  for _, message in ipairs(self.state.messages) do
    if message:IsVisible() then
      message.outroTimer = C_Timer.NewTimer(Core.db.profile.chatHoldTime, function()
        if message:IsVisible() then
          message.outroAg:Play()
        end
      end)
    end
  end
end

function SlidingMessageFrame:OnHyperlinkEnter(f, link, text)
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

function SlidingMessageFrame:OnHyperlinkLeave(f, link)
  if self.state.showingTooltip then
    self.state.showingTooltip:Hide()
    self.state.showingTooltip = false
  end
end

function SlidingMessageFrame:AddMessage(...)
  -- Enqueue messages to be displayed
  local args = {...}
  table.insert(self.state.incomingMessages, args)
end


function SlidingMessageFrame:OnUpdate(elapsed)
  self.timeElapsed = self.timeElapsed + elapsed
  while (self.timeElapsed > 0.1) do
    self.timeElapsed = self.timeElapsed - 0.1
    self:Update()
  end
end

function SlidingMessageFrame:Update()
  -- Make sure previous iteration is complete before running again
  if #self.state.incomingMessages > 0 and not self.sliderAg:IsPlaying() then
    -- Create new message frame for each message
    local newMessages = {}

    for _, message in ipairs(self.state.incomingMessages) do
      table.insert(newMessages, self:CreateMessageFrame(unpack(message)))
    end

    -- Update slider offsets animation
    local offset = reduce(newMessages, function (acc, message)
      return acc + message:GetHeight()
    end, 0)

    local newHeight = self.slider:GetHeight() + offset
    self.slider:SetHeight(newHeight)
    self.sliderStartOffset:SetOffset(0, offset * -1)
    self.sliderTranslateUp:SetOffset(0, offset)

    -- Display and run everything
    self.scrollFrame:SetVerticalScroll(newHeight - self.scrollFrame:GetHeight() + self.config.overflowHeight)

    for _, messageFrame in ipairs(newMessages) do
      messageFrame:Show()
      table.insert(self.state.messages, messageFrame)
    end

    self.sliderAg:Play()

    -- Release old messages
    local historyLimit = 128
    if #self.state.messages > historyLimit then
      local overflow = #self.state.messages - historyLimit
      local oldMessages = take(self.state.messages, overflow)
      self.state.messages = drop(self.state.messages, overflow)

      for _, message in ipairs(oldMessages) do
        self.messageFramePool:Release(message)
      end
    end

    -- Reset
    self.state.incomingMessages = {}
  end
end

function SlidingMessageFrame:OnUpdateFont()
  for _, message in ipairs(self.state.messages) do
    message:UpdateFrame()
  end
end

function SlidingMessageFrame:OnUpdateChatBackgroundOpacity()
  for _, message in ipairs(self.state.messages) do
    message:UpdateTextures()
  end
end

function SlidingMessageFrame:OnUpdateFrame()
  self.config.height = MC:GetFrame():GetHeight() - GeneralDockManager:GetHeight() - 5
  self.config.width = MC:GetFrame():GetWidth()

  self.scrollFrame:SetHeight(self.config.height + self.config.overflowHeight)
  self.scrollFrame:SetWidth(self.config.width)

  self.slider:SetHeight(self.config.height + self.config.overflowHeight)
  self.slider:SetWidth(self.config.width)

  for _, message in ipairs(self.state.messages) do
    message:UpdateFrame()
  end
end

----
-- SMF Module
function SMF:OnInitialize()
  self.state = {
    frames = {}
  }

end

function SMF:OnEnable()
  -- Message font
  self.font = CreateFont("GlassMessageFont")
  self.font:SetFont(
    LSM:Fetch(LSM.MediaType.FONT, Core.db.profile.font),
    Core.db.profile.messageFontSize
  )
  self.font:SetShadowColor(0, 0, 0, 1)
  self.font:SetShadowOffset(1, -1)
  self.font:SetJustifyH("LEFT")
  self.font:SetJustifyV("MIDDLE")
  self.font:SetSpacing(3)

  -- Replace default chat frames with SlidingMessageFrames
  local containerFrame = MC:GetFrame()
  local dockHeight = GeneralDockManager:GetHeight() + 5
  local height = containerFrame:GetHeight() - dockHeight

  for i=1, NUM_CHAT_WINDOWS do
    repeat
      local chatFrame = _G["ChatFrame"..i]

      _G[chatFrame:GetName().."ButtonFrame"]:Hide()

      chatFrame:SetClampRectInsets(0,0,0,0)
      chatFrame:SetClampedToScreen(false)
      chatFrame:SetResizable(false)
      chatFrame:SetParent(containerFrame)
      chatFrame:ClearAllPoints()
      chatFrame:SetHeight(height - 20)

      self:RawHook(chatFrame, "SetPoint", function ()
        self.hooks[chatFrame].SetPoint(chatFrame, "TOPLEFT", containerFrame, "TOPLEFT", 0, -45)
      end, true)

      -- Skip combat log
      if i == 2 then
        do break end
      end

      local smf = SlidingMessageFrame:Create()
      self.state.frames[i] = smf

      smf:Initialize()
      smf:Hide()

      self:Hook(chatFrame, "AddMessage", function (...)
        local args = {...}
        smf:AddMessage(unpack(args))
      end, true)

      -- Hide the default chat frame and show the sliding message frame instead
      self:RawHook(chatFrame, "Show", function ()
        smf:Show()
      end, true)

      self:RawHook(chatFrame, "Hide", function (f)
        self.hooks[chatFrame].Hide(f)
        smf:Hide()
      end, true)

      chatFrame:Hide()
    until true
  end
end

function SMF:OnEnterContainer()
  for _, smf in ipairs(self.state.frames) do
    smf:OnEnterContainer()
  end
end

function SMF:OnLeaveContainer()
  for _, smf in ipairs(self.state.frames) do
    smf:OnLeaveContainer()
  end
end

function SMF:OnUpdateFont()
  self.font:SetFont(
    LSM:Fetch(LSM.MediaType.FONT, Core.db.profile.font),
    Core.db.profile.messageFontSize
  )

  for _, frame in ipairs(self.state.frames) do
    frame:OnUpdateFont()
  end
end

function SMF:OnUpdateChatBackgroundOpacity()
  for _, frame in ipairs(self.state.frames) do
    frame:OnUpdateChatBackgroundOpacity()
  end
end

function SMF:OnUpdateFrame()
  for _, frame in ipairs(self.state.frames) do
    frame:OnUpdateFrame()
  end
end
