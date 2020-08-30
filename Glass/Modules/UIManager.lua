local Core, Constants = unpack(select(2, ...))
local UIManager = Core:GetModule("UIManager")

local CreateMainContainerFrame = Core.Components.CreateMainContainerFrame
local CreateMoverDialog = Core.Components.CreateMoverDialog
local CreateMoverFrame = Core.Components.CreateMoverFrame
local CreateSlidingMessageFrame = Core.Components.CreateSlidingMessageFrame

local MOUSE_ENTER = Constants.EVENTS.MOUSE_ENTER
local MOUSE_LEAVE = Constants.EVENTS.MOUSE_LEAVE
local UPDATE_CONFIG = Constants.EVENTS.UPDATE_CONFIG

-- luacheck: push ignore 113
local BNToastFrame = BNToastFrame
local ChatAlertFrame = ChatAlertFrame
local ChatFrameChannelButton = ChatFrameChannelButton
local ChatFrameMenuButton = ChatFrameMenuButton
local GeneralDockManager = GeneralDockManager
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
local QuickJoinToastButton = QuickJoinToastButton
local UIParent = UIParent
-- luacheck: pop

----
-- UIManager Module
function UIManager:OnInitialize()
  self.state = {
    frames = {}
  }
end

function UIManager:OnEnable()
  self:InitMainContainer()
  self:InitSlidingMessageFrames()
  self:InitBlizzardUI()
end

function UIManager:InitBlizzardUI()
  -- Fix Battle.net Toast frame position
  BNToastFrame:ClearAllPoints()
  self:RawHook(BNToastFrame, "SetPoint", function ()
    BNToastFrame:ClearAllPoints()
    self.hooks[BNToastFrame].SetPoint(BNToastFrame, "BOTTOMLEFT", ChatAlertFrame, "BOTTOMLEFT", 0, 0)
  end, true)

  ChatAlertFrame:ClearAllPoints()
  ChatAlertFrame:SetPoint("BOTTOMLEFT", self.container, "TOPLEFT", 15, 10)

  -- Hide other chat elements
  QuickJoinToastButton:Hide()
  ChatFrameChannelButton:Hide()
  ChatFrameMenuButton:Hide()
end

function UIManager:InitMainContainer()
  self.moverFrame = CreateMoverFrame("GlassMoverFrame", UIParent)
  self.moverDialog = CreateMoverDialog("GlassMoverDialog", UIParent)

  self.container = CreateMainContainerFrame("GlassFrame", self.moverFrame)
  self.container:SetPoint("TOPLEFT", self.moverFrame)
end

function UIManager:InitSlidingMessageFrames()
  -- Replace default chat frames with SlidingMessageFrames
  local dockHeight = GeneralDockManager:GetHeight() + 5
  local height = self.container:GetHeight() - dockHeight

  for i=1, NUM_CHAT_WINDOWS do
    repeat
      local chatFrame = _G["ChatFrame"..i]

      _G[chatFrame:GetName().."ButtonFrame"]:Hide()

      chatFrame:SetClampRectInsets(0,0,0,0)
      chatFrame:SetClampedToScreen(false)
      chatFrame:SetResizable(false)
      chatFrame:SetParent(self.container)
      chatFrame:ClearAllPoints()
      chatFrame:SetHeight(height - 20)

      self:RawHook(chatFrame, "SetPoint", function ()
        self.hooks[chatFrame].SetPoint(chatFrame, "TOPLEFT", self.container, "TOPLEFT", 0, -45)
      end, true)

      -- Skip combat log
      if i == 2 then
        do break end
      end

      local smf = CreateSlidingMessageFrame("Glass"..chatFrame:GetName(), self.container)
      self.state.frames[i] = smf

      smf:Hide()

      self:Hook(chatFrame, "AddMessage", function (...)
        smf:AddMessage(...)
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

  Core:Subscribe(MOUSE_ENTER, function ()
    for _, smf in ipairs(self.state.frames) do
      smf:OnEnterContainer()
    end
  end)

  Core:Subscribe(MOUSE_LEAVE, function ()
    for _, smf in ipairs(self.state.frames) do
      smf:OnLeaveContainer()
    end
  end)

  Core:Subscribe(UPDATE_CONFIG, function (key)
    if key == "frameWidth" or key == "frameHeight" then
      for _, smf in ipairs(self.state.frames) do
        smf:OnUpdateFrame()
      end
    end

    if key == "font" or key == "messageFontSize" then
      for _, smf in ipairs(self.state.frames) do
        smf:OnUpdateFont()
      end
    end

    if key == "chatBackgroundOpacity" then
      for _, smf in ipairs(self.state.frames) do
        smf:OnUpdateChatBackgroundOpacity()
      end
    end
  end)
end
