local Core, Constants, Utils = unpack(select(2, ...))
local Router = Core:GetModule("MessageRouter")
local Metadata = Core:GetModule("MessageMetadata")

local function createMessage(text, red, green, blue)
  if Utils.canAccessValue(text) then
    if text == nil then return nil end
    text = tostring(text)
  end
  local function component(value)
    if Utils.canAccessValue(value) and value == nil then return 1 end
    return value
  end
  return {text = text, r = component(red), g = component(green), b = component(blue)}
end

local function usableBuffer(buffer)
  return Utils.canAccessValue(buffer) and type(buffer) == "table"
    and type(buffer.GetEntryAtIndex) == "function"
    and type(buffer.PushFront) == "function" and type(buffer.PushBack) == "function"
end

local function readChatHistory(chatFrame)
  local messages = {}
  local last = chatFrame:GetNumMessages()
  local buffer = chatFrame.historyBuffer
  for index = math.max(1, last - Constants.MESSAGE_HISTORY_LIMIT + 1), last do
    local message
    if usableBuffer(buffer) then
      message = Metadata:GetRecord(buffer:GetEntryAtIndex(last - index + 1), "history")
    else
      message = createMessage(chatFrame:GetMessageInfo(index))
    end
    if message then messages[#messages + 1] = message end
  end
  return messages
end

function Router:OnInitialize()
  self.chatSources = {}
  self.bindings = {}
  self.requestedSources = {}
  self.bufferSources = {}
end

-- History readers return unprocessed messages, oldest first. Renderers must not mutate them.
function Router:CreateSource(readHistory)
  assert(type(readHistory) == "function", "A message source needs a history reader")
  return {readHistory = readHistory, subscribers = {}}
end

function Router:Append(source, messages)
  for renderer in pairs(source.subscribers) do renderer:AppendMessages(messages) end
end

function Router:Prepend(source, messages)
  for renderer in pairs(source.subscribers) do renderer:PrependMessages(messages) end
end

local function connect(router, renderer, source)
  local previous = router.bindings[renderer]
  if previous == source then return end
  if previous then previous.subscribers[renderer] = nil end
  router.bindings[renderer] = source
  if source then source.subscribers[renderer] = true end
  renderer:ReplaceMessages(source and source.readHistory() or {})
end

function Router:Unbind(renderer)
  self.requestedSources[renderer] = nil
  local source = self.bindings[renderer]
  if source then source.subscribers[renderer] = nil end
  self.bindings[renderer] = nil
end

function Router:Bind(renderer, source)
  -- Keep enabled views with unavailable sources registered for temporary previews.
  self.requestedSources[renderer] = source or false
  connect(self, renderer, self.override or source)
end

function Router:HasSource(renderer)
  return self.bindings[renderer] ~= nil
end

function Router:SetOverride(source)
  if self.override == source then return end
  self.override = source
  for renderer, requested in pairs(self.requestedSources) do
    connect(self, renderer, source or requested or nil)
  end
end

function Router:GetChatSource(chatFrame)
  if not chatFrame or chatFrame == _G.ChatFrame2 then return nil end
  if _G.IsCombatLog and _G.IsCombatLog(chatFrame) then return nil end
  local source = self.chatSources[chatFrame]
  if not source then
    source = self:CreateSource(function()
      self:GetChatSource(chatFrame)
      return readChatHistory(chatFrame)
    end)
    self.chatSources[chatFrame] = source
    -- This prehook only reattaches reused frames; accepted buffer entries do the routing.
    self:Hook(chatFrame, "AddMessage", function() self:GetChatSource(chatFrame) end, true)
  end

  -- Temporary chat frames can be reused with a different history buffer.
  local buffer = usableBuffer(chatFrame.historyBuffer) and chatFrame.historyBuffer or nil
  if source.historyBuffer ~= buffer then
    local previous = source.historyBuffer
    if previous then
      local sources = self.bufferSources[previous]
      sources[source] = nil
      if not next(sources) then
        self:Unhook(previous, "PushFront")
        self:Unhook(previous, "PushBack")
        self.bufferSources[previous] = nil
      end
    end
    source.historyBuffer = buffer
    if buffer then
      if not self.bufferSources[buffer] then
        self.bufferSources[buffer] = {}
        self:HookBufferMethod(buffer, "PushFront", "live")
        self:HookBufferMethod(buffer, "PushBack", "backfill")
      end
      self.bufferSources[buffer][source] = true
    end
  end
  return source
end

function Router:HookBufferMethod(buffer, method, origin)
  self:RawHook(buffer, method, function(object, entry, ...)
    local inserted = self.hooks[object][method](object, entry, ...)
    if Utils.canAccessValue(inserted) and inserted then
      pcall(self.ObserveBufferInsertion, self, object, entry, origin)
    end
    return inserted
  end, true)
end

function Router:ObserveBufferInsertion(buffer, entry, origin)
  local message = Metadata:GetRecord(entry, origin)
  if not message then return end
  for source in pairs(self.bufferSources[buffer] or {}) do
    if origin == "backfill" then self:Prepend(source, {message})
    else self:Append(source, {message}) end
  end
end

function Router:BindChat(renderer, chatFrame)
  self:Bind(renderer, self:GetChatSource(chatFrame))
end
