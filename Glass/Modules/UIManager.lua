local Core, _, Utils = unpack(select(2, ...))
local CT = Core:GetModule("ChatTabs")
local MC = Core:GetModule("MainContainer")
local UIManager = Core:GetModule("UIManager")

local LSM = Core.Libs.LSM
local CreateSlidingMessageFramePool = Core.Frames.CreateSlidingMessageFramePool

-- luacheck: push ignore 113
local ChatFrame2 = ChatFrame2
local CreateFont = CreateFont
local FCF_PopInWindow = FCF_PopInWindow
local GeneralDockManager = GeneralDockManager
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
-- luacheck: pop

function UIManager:OnInitialize()
  self.state = {
    frames = {}
  }
  self.slidingMessageFramePool = CreateSlidingMessageFramePool()
end

function UIManager:OnEnable()
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

  for i=1, NUM_CHAT_WINDOWS do
    self.state.frames[i] = self:InitializeFrame(_G["ChatFrame"..i])
  end

  -- Handle temporary chat frames (whisper popout, pet battle)
  self:RawHook("FCF_OpenTemporaryWindow", function (...)
    local args = {...}
    local chatFrame = self.hooks["FCF_OpenTemporaryWindow"](unpack(args))
    local smf = self:InitializeFrame(chatFrame)
    table.insert(self.state.frames, smf)
    return chatFrame
  end, true)
end

function UIManager:InitializeFrame(chatFrame)
  -- Replace default chat frames with SlidingMessageFrames
  local containerFrame = MC:GetFrame()
  local dockHeight = GeneralDockManager:GetHeight() + 5
  local height = containerFrame:GetHeight() - dockHeight

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
  if chatFrame == ChatFrame2 then
    CT:InitializeTab(chatFrame, nil)
    return
  end

  local smf = self.slidingMessageFramePool:Acquire(chatFrame)
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

  -- Cleanup function
  local function closeWindow()
    FCF_PopInWindow(chatFrame)
    Utils.print('Should release')
    self.slidingMessageFramePool:Release(smf)
    self:Unhook(chatFrame, "SetPoint")
    self:Unhook(chatFrame, "AddMessage")
    self:Unhook(chatFrame, "Show")
    self:Unhook(chatFrame, "Hide")
    CT:UnloadTab(chatFrame)
  end

  -- Customize its tab
  CT:InitializeTab(chatFrame, smf, closeWindow)

  return smf
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
  self.font:SetFont(
    LSM:Fetch(LSM.MediaType.FONT, Core.db.profile.font),
    Core.db.profile.messageFontSize
  )

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
