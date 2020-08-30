local Core, Constants = unpack(select(2, ...))
local TP = Core:GetModule("TextProcessing")

local AceHook = Core.Libs.AceHook

local lodash = Core.Libs.lodash
local drop, reduce, take = lodash.drop, lodash.reduce, lodash.take

local CreateMessageLinePool = Core.Components.CreateMessageLinePool

local MOUSE_ENTER = Constants.EVENTS.MOUSE_ENTER
local MOUSE_LEAVE = Constants.EVENTS.MOUSE_LEAVE
local UPDATE_CONFIG = Constants.EVENTS.UPDATE_CONFIG

-- luacheck: push ignore 113
local C_Timer = C_Timer
local CreateFrame = CreateFrame
local Mixin = Mixin
-- luacheck: pop

----
-- SlidingMessageFrameMixin
--
-- Custom frame for displaying pretty sliding messages
local SlidingMessageFrameMixin = {}

function SlidingMessageFrameMixin:Init(chatFrame)
  self.config = {
    height = Core.db.profile.frameHeight - Constants.DOCK_HEIGHT - 5,
    width = Core.db.profile.frameWidth,
    overflowHeight = 60,
  }
  self.state = {
    mouseOver = false,
    showingTooltip = false,
    incomingMessages = {},
    messages = {},
    isCombatLog = false,
  }
  self.chatFrame = chatFrame

  -- Override Blizzard UI
  _G[chatFrame:GetName().."ButtonFrame"]:Hide()

  chatFrame:SetClampRectInsets(0,0,0,0)
  chatFrame:SetClampedToScreen(false)
  chatFrame:SetResizable(false)
  chatFrame:SetParent(self:GetParent())
  chatFrame:ClearAllPoints()

  -- Skip combat log
  if chatFrame == _G.ChatFrame2 then
    self.state.isCombatLog = true
    self:RawHook(chatFrame, "SetPoint", function ()
      self.hooks[chatFrame].SetPoint(chatFrame, "TOPLEFT", self:GetParent(), "TOPLEFT", 0, -45)
      self.hooks[chatFrame].SetPoint(chatFrame, "BOTTOMRIGHT", self:GetParent(), "BOTTOMRIGHT", 0, 0)
    end, true)
    return
  end

  self:RawHook(chatFrame, "SetPoint", function ()
    self.hooks[chatFrame].SetPoint(chatFrame, "TOPLEFT", self:GetParent(), "TOPLEFT", 0, -45)
  end, true)

  -- Chat scroll frame
  self:SetHeight(self.config.height + self.config.overflowHeight)
  self:SetWidth(self.config.width)
  self:SetPoint("BOTTOMLEFT", 0, self.config.overflowHeight * -1)

  -- Set initial scroll position
  self:SetVerticalScroll(self.config.overflowHeight)

  self.bg = self:CreateTexture(nil, "BACKGROUND")
  self.bg:SetAllPoints()
  self.bg:SetColorTexture(0, 1, 0, 0)

  self.timeElapsed = 0
  self:SetScript("OnUpdate", function (frame, elapsed)
    self:OnUpdate(elapsed)
  end)

  -- Scrolling
  self:SetScript("OnMouseWheel", function (frame, delta)
    local currentScrollOffset = self:GetVerticalScroll()
    local scrollRange = self:GetVerticalScrollRange()

    -- Adjust scroll
    if delta < 0 and currentScrollOffset < scrollRange + self.config.overflowHeight then
      self:SetVerticalScroll(math.min(currentScrollOffset + 20, scrollRange + self.config.overflowHeight))
    elseif delta > 0 and currentScrollOffset > self:GetHeight() then
      self:SetVerticalScroll(currentScrollOffset - 20)
    end

    -- Show hidden messages
    for _, message in ipairs(self.state.messages) do
      if not message:IsVisible() then
        message:Show()
      end
    end
  end)

  -- Mouse clickthrough
  self:EnableMouse(false)

  -- ScrollChild
  self.slider = CreateFrame("Frame", nil, self)
  self.slider:SetHeight(self.config.height + self.config.overflowHeight)
  self.slider:SetWidth(self.config.width)
  self:SetScrollChild(self.slider)

  self.slider.bg = self.slider:CreateTexture(nil, "BACKGROUND")
  self.slider.bg:SetAllPoints()
  self.slider.bg:SetColorTexture(0, 0, 1, 0)

  -- Initialize slide up animations
  self.sliderAg = self.slider:CreateAnimationGroup()
  self.sliderTranslateUp = self.sliderAg:CreateAnimation("Translation")
  self.sliderTranslateUp:SetDuration(0.3)
  self.sliderTranslateUp:SetSmoothing("OUT")

  -- Pool for the message frames
  self.messageFramePool = CreateMessageLinePool(self.slider)

  self:Hook(chatFrame, "AddMessage", function (...)
    self:AddMessage(...)
  end, true)

  -- Hide the default chat frame and show the sliding message frame instead
  self:RawHook(chatFrame, "Show", function ()
    self:Show()
  end, true)

  self:RawHook(chatFrame, "Hide", function (f)
    self.hooks[chatFrame].Hide(f)
    self:Hide()
  end, true)

  chatFrame:Hide()

  -- Listeners
  Core:Subscribe(MOUSE_ENTER, function ()
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
  end)

  Core:Subscribe(MOUSE_LEAVE, function ()
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
  end)

  Core:Subscribe(UPDATE_CONFIG, function (key)
    if self.state.isCombatLog == false then
      if key == "frameWidth" or key == "frameHeight" then
        self.config.height = Core.db.profile.frameHeight - Constants.DOCK_HEIGHT - 5
        self.config.width = Core.db.profile.frameWidth

        self:SetHeight(self.config.height + self.config.overflowHeight)
        self:SetWidth(self.config.width)

        self.slider:SetHeight(self.config.height + self.config.overflowHeight)
        self.slider:SetWidth(self.config.width)
      end

      if key == "font" or key == "messageFontSize" or key == "frameWidth" or key == "frameHeight" then
        for _, message in ipairs(self.state.messages) do
            message:UpdateFrame()
        end
      end

      if key == "chatBackgroundOpacity" then
        for _, message in ipairs(self.state.messages) do
          message:UpdateTextures()
        end
      end
    end
  end)
end

function SlidingMessageFrameMixin:CreateMessageFrame(frame, text, red, green, blue, messageId, holdTime)
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

function SlidingMessageFrameMixin:AddMessage(...)
  -- Enqueue messages to be displayed
  local args = {...}
  table.insert(self.state.incomingMessages, args)
end


function SlidingMessageFrameMixin:OnUpdate(elapsed)
  self.timeElapsed = self.timeElapsed + elapsed
  while (self.timeElapsed > 0.1) do
    self.timeElapsed = self.timeElapsed - 0.1
    self:Update()
  end
end

function SlidingMessageFrameMixin:Update()
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
    self.sliderTranslateUp:SetOffset(0, offset)

    -- Display and run everything
    self.sliderAg:SetScript("OnFinished", function ()
      self:SetVerticalScroll(newHeight - self:GetHeight() + self.config.overflowHeight)
    end)
    self.sliderAg:Play()

    for _, messageFrame in ipairs(newMessages) do
      messageFrame:Show()
      table.insert(self.state.messages, messageFrame)
    end

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

Core.Components.CreateSlidingMessageFrame = function (name, parent, chatFrame)
  local frame = CreateFrame("ScrollFrame", name, parent)
  local object = Mixin(frame, SlidingMessageFrameMixin)
  AceHook:Embed(object)
  object:Init(chatFrame)
  object:Hide()
  return object
end
