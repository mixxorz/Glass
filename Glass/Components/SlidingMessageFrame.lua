local Core, Constants, Utils = unpack(select(2, ...))
local UIManager = Core:GetModule("UIManager")
local MessageRouter = Core:GetModule("MessageRouter")
local AceHook = Core.Libs.AceHook
local LibEasing = Core.Libs.LibEasing
local E = Constants.EVENTS
local SlidingMessageFrameMixin = {}

local function takeMessageBatch(queue, limit)
  local messages = {}
  for _ = 1, math.min(limit, #queue) do
    messages[#messages + 1] = table.remove(queue, 1)
  end
  return messages
end

local function splitHistory(messages)
  local first = math.max(1, #messages - Constants.MESSAGE_UPDATE_BATCH_SIZE + 1)
  local latest, older = {}, {}
  for index = first, #messages do latest[#latest + 1] = messages[index] end
  for index = first - 1, math.max(1, #messages - Constants.MESSAGE_HISTORY_LIMIT + 1), -1 do
    older[#older + 1] = messages[index]
  end
  return latest, older
end

function SlidingMessageFrameMixin:GetSettings()
  return self.window and self.window.settings or Core.db.profile
end

function SlidingMessageFrameMixin:IsInteractive(setting)
  if not self.window then return true end
  local settings = self:GetSettings()
  return not settings.nonInteractive and settings[setting] ~= false
end

function SlidingMessageFrameMixin:GetContentOffset()
  if self.window and not self:GetSettings().showTabBar then return 0 end
  local offset = Utils.getDockHeight(self:GetSettings()) + 5
  if self.state.isCombatLog then
    -- Blizzard anchors the filter toolbar 3px above Combat Log; leave it below our tabs.
    local toolbar = self.chatFrame.CombatLogQuickButtonFrame or _G.CombatLogQuickButtonFrame_Custom
      or _G.CombatLogQuickButtonFrame
    local toolbarHeight = toolbar and toolbar:GetHeight() or 0
    -- Combat Log is load-on-demand, so its toolbar may not exist on first initialization.
    offset = offset + (toolbarHeight > 0 and toolbarHeight or 24) + 3
  end
  return offset
end

function SlidingMessageFrameMixin:Init(chatFrame, window)
  self.window = window
  self.chatFrame = chatFrame
  self.state = {
    mouseOver = false, editBoxFocused = not window and _G.ChatFrame1EditBox:HasFocus() or false,
    moverUnlocked = not window and UIManager.moverFrame:IsShown() or false,
    incomingScrollbackMessages = {}, incomingMessages = {}, messages = {},
    scrollAtBottom = true, jumpingToBottom = false, unreadMessages = false,
    scrollIndex = 1, messageOffset = 0, slideOffset = 0,
    isCombatLog = not window and chatFrame == _G.ChatFrame2,
  }
  self.config = { overflowHeight = 60 }

  if not window then
    _G[chatFrame:GetName().."ButtonFrame"]:Hide()
    chatFrame:SetClampRectInsets(0, 0, 0, 0)
    chatFrame:SetClampedToScreen(false)
    chatFrame:SetResizable(false)
    chatFrame:SetParent(self:GetParent())
    chatFrame:ClearAllPoints()
    self:RawHook(chatFrame, "SetPoint", function ()
      local offset = self:GetContentOffset()
      self.hooks[chatFrame].SetPoint(chatFrame, "TOPLEFT", self:GetParent(), "TOPLEFT", 0, -offset)
      if self.state.isCombatLog then
        self.hooks[chatFrame].SetPoint(chatFrame, "BOTTOMRIGHT", self:GetParent(), "BOTTOMRIGHT", 0, 0)
      end
    end, true)
    if self.state.isCombatLog then
      chatFrame:SetPoint()
      self.subscriptions = { Core:Subscribe(E.UPDATE_CONFIG, function (key)
        if key == "frameWidth" or key == "frameHeight" or key == "tabFontSize" or key == "tabYPadding" then
          chatFrame:SetPoint()
        end
      end) }
      return
    end
  end

  if not self.viewport then
    self.viewport = _G.CreateFrame("Frame", nil, self)
    self.viewport:SetAllPoints()
    self.viewport:SetClipsChildren(true)
    if self.viewport.SetAlphaGradient and self.viewport.SetFlattensRenderLayers then
      -- Frame alpha gradients require flattened render layers.
      self.viewport:SetFlattensRenderLayers(true)
    end
    self.viewport:EnableMouse(false)
    self.viewport:EnableMouseWheel(false)
  end
  if not self.slider then self.slider = _G.CreateFrame("Frame", nil, self.viewport) end
  self.slider:SetFrameLevel(self.viewport:GetFrameLevel())
  self.slider:ClearAllPoints()
  self:SetSlideOffset(0)
  if not self.measurementText then
    self.measurementText = self.viewport:CreateFontString(nil, "ARTWORK")
    self.measurementText:Hide()
  end
  if not self.messageFramePool then
    self.messageFramePool = Core.Components.CreateMessageLinePool(self.slider, self)
  end
  if not self.overlay then
    self.overlay = Core.Components.CreateScrollOverlayFrame(self)
    self.overlay:SetScript("OnClickSnapFrame", function () self:SnapToBottom(true) end)
  end
  -- The jump button is a sibling of the faded viewport, not part of its content.
  self.overlay:SetFrameLevel(self.slider:GetFrameLevel() + 2)
  self.overlay.snapToBottomFrame:SetFrameLevel(self.overlay:GetFrameLevel() + 2)
  self.overlay:QuickHide()
  self:EnableMouse(false)
  self:SetScript("OnMouseWheel", function (_, delta)
    if not self:IsInteractive("scrollEnabled") then return end
    if _G.IsShiftKeyDown() then
      -- Pan within a tall message without asking how many wrapped lines it has.
      self:SetScrollPosition(self.state.scrollIndex, self.state.messageOffset + delta * 20)
    else
      local step = delta > 0 and math.ceil(delta) or math.floor(delta)
      self:SetScrollPosition(self.state.scrollIndex + step, 0)
    end
    self:RevealMessages()
    self:ScheduleFade()
  end)
  self:RefreshSettings()

  local events = window or Core
  self.subscriptions = {
    events:Subscribe(E.MOUSE_ENTER, function ()
      self.state.mouseOver = true
      if not self.state.scrollAtBottom and self:IsInteractive("scrollEnabled") then self.overlay:Show() end
      if self.state.moverUnlocked or self.state.editBoxFocused or self:GetSettings().chatShowOnMouseOver then
        self:RevealMessages()
      end
    end),
    events:Subscribe(E.MOUSE_LEAVE, function ()
      self.state.mouseOver = false
      self.overlay:HideDelay(self:GetSettings().messageHoldTime)
      self:ScheduleFade()
    end),
    events:Subscribe(E.UNLOCK_MOVER, function ()
      self.state.moverUnlocked = true
      self:RevealMessages()
    end),
    events:Subscribe(E.LOCK_MOVER, function ()
      self.state.moverUnlocked = false
      self:ScheduleFade()
    end),
    events:Subscribe(E.UPDATE_CONFIG, function (key)
      if key == "messageNeverFadeOut" then
        if self:GetSettings().messageNeverFadeOut then self:RevealMessages() else self:ScheduleFade() end
        return
      end
      if key == "messageHoldTime" then
        self:ScheduleFade()
        if not self.state.mouseOver and not self.state.scrollAtBottom then
          self.overlay:HideDelay(self:GetSettings().messageHoldTime)
        end
        return
      end
      if key == "messageFadeInDuration" or key == "messageFadeOutDuration" then
        for _, message in ipairs(self.state.messages) do message:UpdateTransitions() end
        return
      end
      if key == "messageSlideInDuration" then
        if self:GetSettings().messageSlideInDuration == 0 and self.state.scrollAtBottom
          and not self.state.jumpingToBottom then
          self:StopScrollAnimation()
          self:SetSlideOffset(0)
          self:UpdatePaneHeight()
        end
        return
      end
      if key == "messageTopFade" or key == "messageBottomFade" then
        self:UpdateEdgeFades()
        return
      end
      if key == "chatBackgroundOpacity" or key == "leftGradientWidth" or key == "rightGradientWidth" then
        for _, message in ipairs(self.state.messages) do message:UpdateTextures() end
        return
      end
      if key == "tabBarBackgroundOpacity" or key == "tabLeftGradientWidth" or
        key == "tabRightGradientWidth" or key == "tabBarNeverFadeOut" or key == "tabBarHoldTime" or
        key == "tabBarFadeInDuration" or key == "tabBarFadeOutDuration" or
        key == "editBoxFadeInDuration" or key == "editBoxFadeOutDuration" or
        key == "editBoxBackgroundOpacity" or key == "editBoxXPadding" then
        return
      end
      self.state.settingsRefreshPending = true
      self.state.reprocessText = self.state.reprocessText or key == "iconTextureYOffset"
    end),
  }

  if not window then
    table.insert(self.subscriptions, Core:Subscribe(E.EDIT_BOX_FOCUS_GAINED, function ()
      self.state.editBoxFocused = true
      self:RevealMessages()
    end))
    table.insert(self.subscriptions, Core:Subscribe(E.EDIT_BOX_FOCUS_LOST, function ()
      self.state.editBoxFocused = false
      self:ScheduleFade()
    end))
    self:RawHook(chatFrame, "Show", function ()
      local wasShown = self:IsShown()
      self:Show()
      if not wasShown then
        self.state.mouseOver = UIManager.container:IsMouseOver()
        self:RevealMessages()
        self:ScheduleFade()
      end
    end, true)
    self:RawHook(chatFrame, "Hide", function (frame)
      self.hooks[chatFrame].Hide(frame)
      self:Hide()
    end, true)
    -- Blizzard's dock uses SetShown, whose native implementation bypasses Lua Show/Hide hooks.
    self:RawHook(chatFrame, "SetShown", function (frame, shown)
      if shown then frame:Show() else frame:Hide() end
    end, true)
    chatFrame:Hide()
  end
end

function SlidingMessageFrameMixin:UpdateEdgeFades()
  local viewport = self.viewport
  if not viewport or not viewport.SetAlphaGradient or not viewport.SetFlattensRenderLayers
    or not _G.CreateVector2D then return end
  -- Keep the lower edge soft through the jump, then reveal the newest line fully.
  local atBottom = self.state.scrollAtBottom and not self.state.jumpingToBottom
  local top, bottom = Utils.getMessageEdgeFades(self:GetSettings(), self.config.height, atBottom)
  if self.state.topEdgeFade ~= top or self.state.bottomEdgeFade ~= bottom then
    viewport:SetAlphaGradient(0, _G.CreateVector2D(0, top))
    viewport:SetAlphaGradient(1, _G.CreateVector2D(0, bottom))
    self.state.topEdgeFade, self.state.bottomEdgeFade = top, bottom
  end
end

function SlidingMessageFrameMixin:SetSlideOffset(offset)
  self.state.slideOffset = offset
  self.slider:SetPoint("TOPLEFT", self.viewport, "TOPLEFT", 0, offset - self.state.messageOffset)
end

function SlidingMessageFrameMixin:UpdatePaneHeight()
  local overflow = self.state.scrollAtBottom and not self.state.jumpingToBottom
    and self.config.overflowHeight or 0
  self:SetHeight(self.config.height + overflow)
  self:UpdateEdgeFades()
end

function SlidingMessageFrameMixin:LayoutMessages()
  local messages = self.state.messages
  if #messages == 0 then return end
  local anchorIndex = #messages - self.state.scrollIndex + 1
  -- Break changed links first to avoid cycles, but keep untouched text layouts cached.
  for index, message in ipairs(messages) do
    local target, relativePoint, point
    if index == anchorIndex then
      target, relativePoint, point = self.slider, "BOTTOMLEFT", "BOTTOMLEFT"
    elseif index < anchorIndex then
      target, relativePoint, point = messages[index + 1], "TOPLEFT", "BOTTOMLEFT"
    else
      target, relativePoint, point = messages[index - 1], "BOTTOMLEFT", "TOPLEFT"
    end
    if not message:IsAnchoredTo(target, relativePoint, point) then message:ClearAnchor() end
  end
  messages[anchorIndex]:SetAnchor(self.slider, "BOTTOMLEFT", "BOTTOMLEFT")
  for index = anchorIndex - 1, 1, -1 do
    messages[index]:SetAnchor(messages[index + 1], "TOPLEFT", "BOTTOMLEFT")
  end
  for index = anchorIndex + 1, #messages do
    messages[index]:SetAnchor(messages[index - 1], "BOTTOMLEFT", "TOPLEFT")
  end
end

function SlidingMessageFrameMixin:GetPublicHeight(message)
  if message.publicHeight ~= nil then return message.publicHeight or nil end
  message.publicHeight = false
  if not Utils.canAccessValue(message.displayText) then return nil end

  -- Even public rows inherit secret geometry from neighbours. Measure off the chain.
  local text = self.measurementText
  local settings = self:GetSettings()
  local left, right = Utils.getMessagePadding(settings)
  Utils.clearFontStringText(text)
  text:ClearAllPoints()
  text:SetPoint("TOPLEFT", self.viewport, "TOPLEFT")
  text:SetFontObject(self.window and self.window.fonts.message or "GlassMessageFont")
  text:SetWidth(math.max(1, settings.frameWidth - left - right))
  text:SetJustifyH("LEFT")
  text:SetWordWrap(true)
  text:SetNonSpaceWrap(true)
  text:SetIndentedWordWrap(settings.indentWordWrap)
  text:SetMaxLines(0)
  text:SetText(message.displayText)
  local height = text:GetHeight()
  Utils.clearFontStringText(text)
  if not Utils.canAccessValue(height) then return nil end
  message.publicHeight = math.max(0, height) + message.yPadding * 2
  return message.publicHeight
end

function SlidingMessageFrameMixin:GetPublicDistanceToBottom()
  local messages = self.state.messages
  local anchorIndex = #messages - self.state.scrollIndex + 1
  local distance = self.state.messageOffset - self.state.slideOffset
  for index = anchorIndex + 1, #messages do
    local height = self:GetPublicHeight(messages[index])
    if height == nil then return nil end
    distance = distance + height
  end
  return distance
end

function SlidingMessageFrameMixin:StopScrollAnimation()
  if self.state.prevEasingHandle then
    LibEasing:StopEasing(self.state.prevEasingHandle)
    self.state.prevEasingHandle = nil
  end
  self.state.jumpingToBottom = false
end

function SlidingMessageFrameMixin:AnimateSlide(start, duration, jumping)
  self:SetSlideOffset(start)
  self.state.jumpingToBottom = jumping or false
  self:UpdatePaneHeight()
  self.state.prevEasingHandle = LibEasing:Ease(
    function (offset) self:SetSlideOffset(offset) end, start, 0, duration, LibEasing.OutCubic,
    function ()
      self.state.prevEasingHandle = nil
      self.state.jumpingToBottom = false
      self:SetSlideOffset(0)
      self:UpdatePaneHeight()
    end
  )
end

function SlidingMessageFrameMixin:SetScrollPosition(index, offset)
  self:StopScrollAnimation()
  self.state.scrollIndex = math.max(1, math.min(#self.state.messages, index))
  self.state.messageOffset = #self.state.messages > 0 and math.max(0, offset) or 0
  self.state.scrollAtBottom = self.state.scrollIndex == 1 and self.state.messageOffset == 0
  self:LayoutMessages()
  self:SetSlideOffset(0)
  self:UpdatePaneHeight()
  if self.state.scrollAtBottom then
    self.state.unreadMessages = false
    self.overlay:QuickHide()
    self.overlay:HideNewMessageAlert()
  else
    self.overlay:Show()
  end
end

function SlidingMessageFrameMixin:RefreshSettings()
  if self.state.isCombatLog then return end
  self:StopScrollAnimation()
  local settings = self:GetSettings()
  self.config.height = math.max(1, settings.frameHeight - self:GetContentOffset())
  self.config.width = settings.frameWidth
  self:SetWidth(self.config.width)
  self:ClearAllPoints()
  self:SetPoint("TOPLEFT", 0, -self:GetContentOffset())
  self:EnableMouseWheel(self:IsInteractive("scrollEnabled"))
  self.slider:SetSize(self.config.width, self.config.height)
  for _, message in ipairs(self.state.messages) do message:UpdateFrame() end
  self.overlay:RefreshLayout(self.config.height)
  self.overlay.snapToBottomFrame:EnableMouse(self:IsInteractive("scrollEnabled"))
  if not self:IsInteractive("scrollEnabled") then
    self.state.scrollIndex, self.state.messageOffset = 1, 0
  end
  self.state.scrollIndex = math.max(1, math.min(#self.state.messages, self.state.scrollIndex))
  self.state.scrollAtBottom = self.state.scrollIndex == 1 and self.state.messageOffset == 0
  self:LayoutMessages()
  self:SetSlideOffset(0)
  self:UpdatePaneHeight()
  if self.state.scrollAtBottom then
    self.state.unreadMessages = false
    self.overlay:QuickHide()
    self.overlay:HideNewMessageAlert()
  end
end

function SlidingMessageFrameMixin:SnapToBottom(animated)
  local distance = animated and self:GetPublicDistanceToBottom()
  self:StopScrollAnimation()
  self.state.scrollIndex, self.state.messageOffset = 1, 0
  self.state.scrollAtBottom = true
  self.state.unreadMessages = false
  self:LayoutMessages()
  if distance and distance > 0 then
    -- Unknown distances snap immediately; public history keeps the animated jump.
    self:AnimateSlide(-math.min(distance, self.config.height * 2), 0.3, true)
  else
    self:SetSlideOffset(0)
    self:UpdatePaneHeight()
  end
  self.overlay:QuickHide()
  self.overlay:HideNewMessageAlert()
end

function SlidingMessageFrameMixin:RevealMessages()
  for _, message in ipairs(self.state.messages) do message:Show() end
end

function SlidingMessageFrameMixin:ScheduleFade()
  local settings = self:GetSettings()
  if settings.messageNeverFadeOut or self.state.mouseOver or self.state.moverUnlocked
    or self.state.editBoxFocused then return end
  for _, message in ipairs(self.state.messages) do message:HideDelay(settings.messageHoldTime) end
end

function SlidingMessageFrameMixin:AppendMessages(messages)
  local queue = self.state.incomingMessages
  local limit = Constants.MESSAGE_HISTORY_LIMIT
  for index = math.max(1, #messages - limit + 1), #messages do
    queue[#queue + 1] = messages[index]
  end
  while #queue > limit do table.remove(queue, 1) end
end

function SlidingMessageFrameMixin:PrependMessages(messages)
  local queue = self.state.incomingScrollbackMessages
  local capacity = Constants.MESSAGE_HISTORY_LIMIT - #self.state.messages - #queue
  -- Update inserts each history record at the front, so queue each batch newest first.
  for index = #messages, math.max(1, #messages - capacity + 1), -1 do
    queue[#queue + 1] = messages[index]
  end
end

function SlidingMessageFrameMixin:OnFrame()
  if self.state.isCombatLog then return end
  if self.state.settingsRefreshPending then
    self.state.settingsRefreshPending = nil
    if self.state.reprocessText then
      self.state.reprocessText = nil
      for _, message in ipairs(self.state.messages) do
        message:ReprocessText()
      end
    end
    self:RefreshSettings()
  end
  if #self.state.incomingMessages > 0 then
    local incoming = takeMessageBatch(self.state.incomingMessages, Constants.MESSAGE_UPDATE_BATCH_SIZE)
    self:Update(incoming, false)
  elseif #self.state.incomingScrollbackMessages > 0 then
    local capacity = Constants.MESSAGE_HISTORY_LIMIT - #self.state.messages
    if capacity <= 0 then
      self.state.incomingScrollbackMessages = {}
    else
      local incoming = takeMessageBatch(self.state.incomingScrollbackMessages,
        math.min(capacity, Constants.MESSAGE_UPDATE_BATCH_SIZE))
      self:Update(incoming, true, true)
    end
  end
end

function SlidingMessageFrameMixin:ClearMessages()
  self:StopScrollAnimation()
  self.state.messages = {}
  self.state.incomingMessages = {}
  self.state.incomingScrollbackMessages = {}
  self.state.scrollIndex, self.state.messageOffset = 1, 0
  self.state.scrollAtBottom = true
  self.state.unreadMessages = false
  if self.messageFramePool then self.messageFramePool:ReleaseAll() end
  if self.slider then
    self:SetSlideOffset(0)
    self:UpdatePaneHeight()
    self.overlay:QuickHide()
    self.overlay:HideNewMessageAlert()
  end
end

function SlidingMessageFrameMixin:ReplaceMessages(messages)
  self:ClearMessages()
  -- Show the latest lines now; restore older history over later ticks without incoming animations.
  local latest, older = splitHistory(messages)
  self.state.incomingScrollbackMessages = older
  if #latest > 0 then self:Update(latest, false, true) end
end

function SlidingMessageFrameMixin:Update(incoming, reverse, immediate)
  local settings = self:GetSettings()
  local newMessages = {}
  local wasAtBottom = self.state.scrollAtBottom
  local selected = self.state.messages[#self.state.messages - self.state.scrollIndex + 1]
  local previousSlide = self.state.slideOffset
  local wasJumping = self.state.jumpingToBottom
  local duration = wasJumping and 0.3 or settings.messageSlideInDuration
  local canSlide = wasAtBottom and not reverse and not immediate and duration > 0
  local addedHeight = 0
  for _, record in ipairs(incoming) do
    local message = self.messageFramePool:Acquire()
    message:SetMessage(record)
    table.insert(newMessages, message)
    if reverse then
      table.insert(self.state.messages, 1, message)
    else
      table.insert(self.state.messages, message)
    end
    if canSlide then
      local height = self:GetPublicHeight(message)
      if height == nil then canSlide = false else addedHeight = addedHeight + height end
    end
  end
  while #self.state.messages > Constants.MESSAGE_HISTORY_LIMIT do
    self.messageFramePool:Release(table.remove(self.state.messages, 1))
  end
  local retained = {}
  for _, message in ipairs(self.state.messages) do retained[message] = true end
  if not wasAtBottom and not reverse then
    self.state.scrollIndex = self.state.scrollIndex + #incoming
  end
  self.state.scrollIndex = math.max(1, math.min(#self.state.messages, self.state.scrollIndex))
  if selected and not retained[selected] then self.state.messageOffset = 0 end
  self.state.scrollAtBottom = self.state.scrollIndex == 1 and self.state.messageOffset == 0
  self:LayoutMessages()

  if not reverse then
    self:StopScrollAnimation()
    if canSlide and (addedHeight > 0 or previousSlide < 0) then
      self:AnimateSlide(previousSlide - addedHeight, duration, wasJumping)
    else
      -- A mixed batch has an unknown total displacement, so skip the whole slide.
      self:SetSlideOffset(0)
      self:UpdatePaneHeight()
    end
  elseif not self.state.scrollAtBottom then
    self:StopScrollAnimation()
    self:SetSlideOffset(0)
    self:UpdatePaneHeight()
  end

  if not reverse and not immediate and not self.state.scrollAtBottom and self:IsInteractive("scrollEnabled") then
    self.state.unreadMessages = true
    self.overlay:Show()
    self.overlay:ShowNewMessageAlert()
    if not self.state.mouseOver then self.overlay:HideDelay(settings.messageHoldTime) end
  end
  for _, message in ipairs(newMessages) do
    if retained[message] then
      if immediate then message:QuickShow() else message:Show() end
      if not settings.messageNeverFadeOut and not self.state.mouseOver and not self.state.moverUnlocked
        and not self.state.editBoxFocused then
        message:HideDelay(settings.messageHoldTime)
      end
    end
  end
end

function SlidingMessageFrameMixin:Dispose()
  MessageRouter:Unbind(self)
  if self.state then self:ClearMessages() end
  for _, unsubscribe in ipairs(self.subscriptions or {}) do unsubscribe() end
  self.subscriptions = nil
  self:UnhookAll()
  self:Hide()
  self:SetScript("OnMouseWheel", nil)
  self:EnableMouseWheel(false)
  if self.viewport and self.viewport.ClearAlphaGradient then self.viewport:ClearAlphaGradient() end
  self.chatFrame, self.window = nil, nil
end

local function CreateSlidingMessageFrame(name, parent, chatFrame)
  local frame = _G.CreateFrame("Frame", name, parent)
  _G.Mixin(frame, SlidingMessageFrameMixin)
  AceHook:Embed(frame)
  if chatFrame then frame:Init(chatFrame) end
  frame:Hide()
  return frame
end

Core.Components.CreateSlidingMessageFrame = CreateSlidingMessageFrame
Core.Components.CreateSlidingMessageFramePool = function (parent)
  return _G.CreateObjectPool(
    function () return CreateSlidingMessageFrame(nil, parent) end,
    function (_, frame) frame:Dispose() end
  )
end
