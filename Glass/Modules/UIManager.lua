local Core, Constants, Utils = unpack(select(2, ...))
local UIManager = Core:GetModule("UIManager")
local ExtraWindows = Core:GetModule("ExtraWindows")
local MessageRouter = Core:GetModule("MessageRouter")

local CreateChatDock = Core.Components.CreateChatDock
local CreateChatTab = Core.Components.CreateChatTab
local CreateEditBox = Core.Components.CreateEditBox
local CreateMainContainerFrame = Core.Components.CreateMainContainerFrame
local CreateMoverDialog = Core.Components.CreateMoverDialog
local CreateMoverFrame = Core.Components.CreateMoverFrame
local CreateSlidingMessageFramePool = Core.Components.CreateSlidingMessageFramePool

-- luacheck: push ignore 113
local BNToastFrame = BNToastFrame
local ChatAlertFrame = ChatAlertFrame
local CreateFrame = CreateFrame
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local FCF_DockUpdate = FCF_DockUpdate
local FCF_GetCurrentChatFrame = FCF_GetCurrentChatFrame
local FCF_SelectDockFrame = FCF_SelectDockFrame
local FCFDock_GetSelectedWindow = FCFDock_GetSelectedWindow
local GENERAL_CHAT_DOCK = GENERAL_CHAT_DOCK
local GetCVar = C_CVar and C_CVar.GetCVar or GetCVar
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
local SetCVar = C_CVar and C_CVar.SetCVar or SetCVar
local UIParent = UIParent
-- luacheck: pop

local UPDATE_CONFIG = Constants.EVENTS.UPDATE_CONFIG

----
-- UIManager Module
function UIManager:OnInitialize()
  self.state = {
    frames = {},
    tabs = {},
    temporaryFrames = {},
    temporaryTabs = {}
  }
end

function UIManager:OnEnable()
  self.tickerFrame = CreateFrame("Frame", "GlassUpdaterFrame", UIParent)

  -- Mover
  self.moverFrame = CreateMoverFrame("GlassMoverFrame", UIParent)
  self.moverDialog = CreateMoverDialog("GlassMoverDialog", UIParent)

  -- Main Container
  self.container = CreateMainContainerFrame("GlassFrame", UIParent)
  self.container:SetPoint("TOPLEFT", self.moverFrame)

  -- Chat dock
  self.dock = CreateChatDock(self.container)

  -- SlidingMessageFrames
  self.slidingMessageFramePool = CreateSlidingMessageFramePool(self.container)

  for i=1, NUM_CHAT_WINDOWS do
    local chatFrame = _G["ChatFrame"..i]
    local smf = self.slidingMessageFramePool:Acquire()
    smf:Init(chatFrame)
    if not smf.state.isCombatLog then MessageRouter:BindChat(smf, chatFrame) end

    self.state.frames[i] = smf
    self.state.tabs[i] = CreateChatTab(smf)
  end

  -- Edit box
  self.editBox = CreateEditBox(self.container)

  FCF_SelectDockFrame(FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK) or DEFAULT_CHAT_FRAME)

  Core:Subscribe(UPDATE_CONFIG, function (key)
    if key == "font" or key == "fontFlags" or
      key == "frameWidth" or key == "tabFont" or key == "tabFontFlags" or
      key == "tabFontSize" or key == "tabXPadding" or key == "tabYPadding" or key == "tabSpacing" then
      FCF_DockUpdate()
    end
  end)

  -- Fix Battle.net Toast frame position
  if ChatAlertFrame then
    ChatAlertFrame:ClearAllPoints()
    ChatAlertFrame:SetPoint("BOTTOMLEFT", self.container, "TOPLEFT", 15, 10)
    if BNToastFrame then
      BNToastFrame:ClearAllPoints()
      BNToastFrame:SetPoint("BOTTOMLEFT", ChatAlertFrame, "BOTTOMLEFT", 0, 0)
    end
  end

  self.socialButtonMover = Core.Components.CreateSocialButton(self.dock)

  -- New version alert
  --[===[@non-debug@
  if Core.db.global.version == nil or Utils.versionGreaterThan(Core.Version, Core.db.global.version) then
    Utils.notify('Glass has just been updated. |cFFFFFF00|Hgarrmission:Glass:opennews|h[See what’s new]|h|r')
    Core.db.global.version = Core.Version
  end
  --@end-non-debug@]===]--

  -- Force classic chat style
  if GetCVar("chatStyle") ~= "classic" then
    SetCVar("chatStyle", "classic")
    Utils.notify('Chat Style set to "Classic Style"')

    -- Resets the background that IM style causes
    self.editBox:SetFocus()
    self.editBox:ClearFocus()
  end

  -- Handle temporary chat frames (whisper popout, pet battle)
  self:RawHook("FCF_OpenTemporaryWindow", function (...)
    local chatFrame = self.hooks["FCF_OpenTemporaryWindow"](...)
    if not chatFrame then return nil end
    local name = chatFrame:GetName()
    if not self.state.temporaryFrames[name] then
      local smf = self.slidingMessageFramePool:Acquire()
      smf:Init(chatFrame)
      if not smf.state.isCombatLog then MessageRouter:BindChat(smf, chatFrame) end

      self.state.temporaryFrames[name] = smf
      self.state.temporaryTabs[name] = CreateChatTab(smf)
    end
    -- The native window may have been selected before its Glass renderer was initialized.
    FCF_DockUpdate()
    ExtraWindows:RefreshSources()
    return chatFrame
  end, true)

  -- Close window
  self:RawHook("FCF_Close", function (chatFrame, fallback)
    local closedFrame = fallback or chatFrame or FCF_GetCurrentChatFrame()
    self.hooks["FCF_Close"](chatFrame, fallback)

    if closedFrame then
      if closedFrame ~= DEFAULT_CHAT_FRAME then ExtraWindows:SourceClosed(closedFrame) end
      local name = closedFrame:GetName()
      local smf = self.state.temporaryFrames[name]
      if smf then
        self.state.temporaryFrames[name] = nil
        self.state.temporaryTabs[name] = nil
        self.slidingMessageFramePool:Release(smf)
      end
    end
  end, true)

  self:SecureHook("FCF_SetWindowName", function () ExtraWindows:RefreshSources() end)
  self:SecureHook("FCF_OpenNewWindow", function () ExtraWindows:RefreshSources() end)
  ExtraWindows:Start()

  -- Start rendering
  self.timeElapsed = 0
  self.tickerFrame:SetScript("OnUpdate", function (_, elapsed)
    self.timeElapsed = self.timeElapsed + elapsed

    -- A frame hitch needs one update, not a replay of every missed render tick.
    if self.timeElapsed >= 0.01 then
      self.timeElapsed = self.timeElapsed % 0.01

      self.container:OnFrame()

      for _, smf in ipairs(self.state.frames) do
        smf:OnFrame()
      end

      for _, smf in pairs(self.state.temporaryFrames) do
        smf:OnFrame()
      end
      ExtraWindows:OnFrame()
    end
  end)
end
