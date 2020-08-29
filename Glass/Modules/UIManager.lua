local Core = unpack(select(2, ...))
local MC = Core:GetModule("MainContainer")
local UIManager = Core:GetModule("UIManager")

local CreateSlidingMessageFrame = Core.Components.CreateSlidingMessageFrame

-- luacheck: push ignore 113
local GeneralDockManager = GeneralDockManager
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
-- luacheck: pop

----
-- UIManager Module
function UIManager:OnInitialize()
  self.state = {
    frames = {}
  }
end

function UIManager:OnEnable()
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

      local smf = CreateSlidingMessageFrame("Glass"..chatFrame:GetName(), containerFrame)
      self.state.frames[i] = smf

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

function UIManager:OnEnterContainer()
  for _, smf in ipairs(self.state.frames) do
    smf:OnEnterContainer()
  end
end

function UIManager:OnLeaveContainer()
  for _, smf in ipairs(self.state.frames) do
    smf:OnLeaveContainer()
  end
end

function UIManager:OnUpdateFont()
  for _, frame in ipairs(self.state.frames) do
    frame:OnUpdateFont()
  end
end

function UIManager:OnUpdateChatBackgroundOpacity()
  for _, frame in ipairs(self.state.frames) do
    frame:OnUpdateChatBackgroundOpacity()
  end
end

function UIManager:OnUpdateFrame()
  for _, frame in ipairs(self.state.frames) do
    frame:OnUpdateFrame()
  end
end
