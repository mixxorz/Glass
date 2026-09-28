local Core, Constants = unpack(select(2, ...))
local Router = Core:GetModule("MessageRouter")

local function createMessage(text, red, green, blue)
  if text == nil then return nil end
  return {text = tostring(text), r = red or 1, g = green or 1, b = blue or 1}
end

local function readChatHistory(chatFrame)
  local messages = {}
  local last = chatFrame:GetNumMessages()
  for index = math.max(1, last - Constants.MESSAGE_HISTORY_LIMIT + 1), last do
    local message = createMessage(chatFrame:GetMessageInfo(index))
    if message then messages[#messages + 1] = message end
  end
  return messages
end

function Router:OnInitialize()
  self.chatSources = {}
  self.bindings = {}
  self.requestedSources = {}
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
    source = self:CreateSource(function() return readChatHistory(chatFrame) end)
    self.chatSources[chatFrame] = source
    -- Capture each native frame once, regardless of how many Glass views follow it.
    self:Hook(chatFrame, "AddMessage", function(_, text, red, green, blue)
      local message = createMessage(text, red, green, blue)
      if message then self:Append(source, {message}) end
    end, true)
  end

  -- Temporary chat frames can be reused with a different history buffer.
  if source.historyBuffer ~= chatFrame.historyBuffer then
    if source.historyBuffer then self:Unhook(source.historyBuffer, "PushBack") end
    source.historyBuffer = chatFrame.historyBuffer
    if source.historyBuffer then
      self:Hook(source.historyBuffer, "PushBack", function(_, entry)
        local message = createMessage(entry.message, entry.r, entry.g, entry.b)
        if message then self:Prepend(source, {message}) end
      end, true)
    end
  end
  return source
end

function Router:BindChat(renderer, chatFrame)
  self:Bind(renderer, self:GetChatSource(chatFrame))
end
