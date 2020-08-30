local Core = unpack(select(2, ...))
local UIManager = Core:GetModule("UIManager")

local CreateChatDock = Core.Components.CreateChatDock
local CreateChatTab = Core.Components.CreateChatTab
local CreateEditBox = Core.Components.CreateEditBox
local CreateMainContainerFrame = Core.Components.CreateMainContainerFrame
local CreateMoverDialog = Core.Components.CreateMoverDialog
local CreateMoverFrame = Core.Components.CreateMoverFrame
local CreateSlidingMessageFrame = Core.Components.CreateSlidingMessageFrame

-- luacheck: push ignore 113
local BNToastFrame = BNToastFrame
local ChatAlertFrame = ChatAlertFrame
local ChatFrameChannelButton = ChatFrameChannelButton
local ChatFrameMenuButton = ChatFrameMenuButton
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
local QuickJoinToastButton = QuickJoinToastButton
local UIParent = UIParent
-- luacheck: pop

----
-- UIManager Module
function UIManager:OnInitialize()
  self.state = {
    frames = {},
    tabs = {}
  }
end

function UIManager:OnEnable()
  -- Mover
  self.moverFrame = CreateMoverFrame("GlassMoverFrame", UIParent)
  self.moverDialog = CreateMoverDialog("GlassMoverDialog", UIParent)

  -- Main Container
  self.container = CreateMainContainerFrame("GlassFrame", UIParent)
  self.container:SetPoint("TOPLEFT", self.moverFrame)

  -- Chat dock
  self.dock = CreateChatDock(self.container)

  -- SlidingMessageFrames
  for i=1, NUM_CHAT_WINDOWS do
    local chatFrame = _G["ChatFrame"..i]
    local smf = CreateSlidingMessageFrame(
      "Glass"..chatFrame:GetName(), self.container, chatFrame
    )

    self.state.frames[i] = smf
    self.state.tabs[i] = CreateChatTab(smf)
  end

  -- Edit box
  self.editBox = CreateEditBox(self.container)

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
