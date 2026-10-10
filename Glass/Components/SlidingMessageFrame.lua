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
    scrollAtBottom = true, jumpingToBottom = false, unreadMessages = false, scrollOffset = 0,
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
  self:SetScrollOffset(0)
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
    local minScroll, maxScroll = self:GetScrollBounds()
    local scrollValue = math.max(minScroll, math.min(self.state.scrollOffset - delta * 20, maxScroll))
    self:StopScrollAnimation()
    self:SetScrollOffset(scrollValue)
    self.state.scrollAtBottom = scrollValue == maxScroll
    if self.state.scrollAtBottom then
      self:SnapToBottom()
    else
      self:SetHeight(self.config.height)
      self:UpdateEdgeFades()
      self.overlay:Show()
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
      self.overlay:HideDelay(self:GetSettings().chatHoldTime)
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
      if key == "messageTopFade" or key == "messageBottomFade" then
        self:UpdateEdgeFades()
        return
      end
      if key == "chatBackgroundOpacity" or key == "leftGradientWidth" or key == "rightGradientWidth" then
        for _, message in ipairs(self.state.messages) do message:UpdateTextures() end
        return
      end
      if key == "tabBarBackgroundOpacity" or key == "tabLeftGradientWidth" or
        key == "tabRightGradientWidth" or key == "editBoxBackgroundOpacity" or key == "editBoxXPadding" then
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

function SlidingMessageFrameMixin:SetScrollOffset(offset)
  self.state.scrollOffset = math.max(0, offset)
  -- Keep messages in the clipped frame's render layers, as Blizzard's ScrollBox does.
  self.slider:SetPoint("TOPLEFT", self.viewport, "TOPLEFT", 0, self.state.scrollOffset)
end

function SlidingMessageFrameMixin:GetScrollBounds()
  return Utils.getMessageScrollBounds(self.slider:GetHeight(), self.config.height, self.config.overflowHeight)
end

function SlidingMessageFrameMixin:GetBottomOffset()
  local _, bottom = self:GetScrollBounds()
  return bottom
end

function SlidingMessageFrameMixin:StopScrollAnimation()
  if self.state.prevEasingHandle then
    LibEasing:StopEasing(self.state.prevEasingHandle)
    self.state.prevEasingHandle = nil
  end
  self.state.jumpingToBottom = false
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
  self.slider:SetWidth(self.config.width)
  local contentHeight = 0
  for _, message in ipairs(self.state.messages) do
    message:UpdateFrame()
    contentHeight = contentHeight + message:GetHeight()
  end
  self.slider:SetHeight(self.config.height + self.config.overflowHeight + contentHeight)
  self.overlay:RefreshLayout(self.config.height, self.window and self.window.fonts.message)
  self.overlay.snapToBottomFrame:EnableMouse(self:IsInteractive("scrollEnabled"))
  self:SetHeight(self.config.height + (self.state.scrollAtBottom and self.config.overflowHeight or 0))
  local minScroll, maxScroll = self:GetScrollBounds()
  local offset = math.max(minScroll, math.min(self.state.scrollOffset, maxScroll))
  if self.state.scrollAtBottom or not self:IsInteractive("scrollEnabled") or offset == maxScroll then
    self:SnapToBottom()
  else
    self:SetScrollOffset(offset)
  end
  self:UpdateEdgeFades()
end

function SlidingMessageFrameMixin:SnapToBottom(animated)
  self:StopScrollAnimation()
  self.state.scrollAtBottom = true
  self.state.unreadMessages = false
  local target = self:GetBottomOffset()
  if animated then
    -- Keep history clipped while jumping. The extra viewport space is only for new-message animations.
    self.state.jumpingToBottom = true
    self:SetHeight(self.config.height)
    local start = math.min(target, math.max(self.state.scrollOffset, target - self.config.height * 2))
    self.state.prevEasingHandle = LibEasing:Ease(
      function (offset) self:SetScrollOffset(offset) end, start, target, 0.3, LibEasing.OutCubic,
      function ()
        self.state.jumpingToBottom = false
        self.state.prevEasingHandle = nil
        self:SetHeight(self.config.height + self.config.overflowHeight)
        self:SetScrollOffset(self:GetBottomOffset())
        self:UpdateEdgeFades()
      end
    )
  else
    self:SetHeight(self.config.height + self.config.overflowHeight)
    self:SetScrollOffset(target)
  end
  self:UpdateEdgeFades()
  self.overlay:QuickHide()
  self.overlay:HideNewMessageAlert()
end

function SlidingMessageFrameMixin:RevealMessages()
  for _, message in ipairs(self.state.messages) do message:Show() end
end

function SlidingMessageFrameMixin:ScheduleFade()
  if self.state.mouseOver or self.state.moverUnlocked or self.state.editBoxFocused then return end
  for _, message in ipairs(self.state.messages) do message:HideDelay(self:GetSettings().chatHoldTime) end
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
        message.text:SetText(Core:GetModule("TextProcessing"):ProcessText(message.rawText, self:GetSettings()))
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
  self.state.head, self.state.tail = nil, nil
  self.state.scrollAtBottom = true
  self.state.unreadMessages = false
  if self.messageFramePool then self.messageFramePool:ReleaseAll() end
  if self.slider then
    self.slider:SetHeight(self.config.height + self.config.overflowHeight)
    self:SnapToBottom()
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
  local oldHeight = self.slider:GetHeight()
  for _, record in ipairs(incoming) do
    local message = self.messageFramePool:Acquire()
    message:SetMessage(record)
    message:ClearAllPoints()
    message:SetPoint("BOTTOMLEFT")
    if reverse then
      if self.state.tail then
        message:ClearAllPoints()
        message:SetPoint("BOTTOMLEFT", self.state.tail, "TOPLEFT")
      end
    elseif self.state.head then
      self.state.head:ClearAllPoints()
      self.state.head:SetPoint("BOTTOMLEFT", message, "TOPLEFT")
    end
    self.state.tail = self.state.tail or message
    self.state.head = self.state.head or message
    if reverse then self.state.tail = message else self.state.head = message end
    table.insert(newMessages, message)
    if reverse then table.insert(self.state.messages, 1, message) else table.insert(self.state.messages, message) end
  end
  local removedHeight = 0
  while #self.state.messages > Constants.MESSAGE_HISTORY_LIMIT do
    local old = table.remove(self.state.messages, 1)
    removedHeight = removedHeight + old:GetHeight()
    self.messageFramePool:Release(old)
  end
  self.state.tail = self.state.messages[1]
  local retained = {}
  local newHeight = self.config.height + self.config.overflowHeight
  for _, message in ipairs(self.state.messages) do
    retained[message] = true
    newHeight = newHeight + message:GetHeight()
  end
  self.slider:SetHeight(newHeight)
  local scrollAdjustment = reverse and newHeight - oldHeight or -removedHeight
  self:SetScrollOffset(self.state.scrollOffset + scrollAdjustment)
  if self.state.jumpingToBottom then
    self:SnapToBottom(not immediate)
  elseif self.state.scrollAtBottom then
    self:StopScrollAnimation()
    local endOffset = self:GetBottomOffset()
    if not immediate and settings.chatSlideInDuration > 0 then
      self.state.prevEasingHandle = LibEasing:Ease(
        function (value) self:SetScrollOffset(value) end,
        self.state.scrollOffset, endOffset, settings.chatSlideInDuration, LibEasing.OutCubic
      )
    else
      self:SetScrollOffset(endOffset)
    end
  elseif not reverse and not immediate and self:IsInteractive("scrollEnabled") then
    self.state.unreadMessages = true
    self.overlay:Show()
    self.overlay:ShowNewMessageAlert()
    if not self.state.mouseOver then self.overlay:HideDelay(settings.chatHoldTime) end
  end
  for _, message in ipairs(newMessages) do
    if retained[message] then
      if immediate then message:QuickShow() else message:Show() end
      if not self.state.mouseOver and not self.state.moverUnlocked and not self.state.editBoxFocused then
        message:HideDelay(settings.chatHoldTime)
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
