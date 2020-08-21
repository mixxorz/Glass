local Core, Constants = unpack(select(2, ...))
local CT = Core:GetModule("ChatTabs")
local MC = Core:GetModule("MainContainer")
local SMF = Core:GetModule("SlidingMessageFrame")

local LSM = Core.Libs.LSM

-- luacheck: push ignore 113
local CHAT_CONFIGURATION = CHAT_CONFIGURATION
local CLOSE_CHAT_WINDOW = CLOSE_CHAT_WINDOW
local C_Timer = C_Timer
local ChatConfigFrame = ChatConfigFrame
local CreateFont = CreateFont
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local FCFDock_GetInsertIndex = FCFDock_GetInsertIndex
local FCFDock_HideInsertHighlight = FCFDock_HideInsertHighlight
local FCF_DockFrame = FCF_DockFrame
local FCF_GetNumActiveChatFrames = FCF_GetNumActiveChatFrames
local FCF_NewChatWindow = FCF_NewChatWindow
local FCF_PopInWindow = FCF_PopInWindow
local FCF_RenameChatWindow_Popup = FCF_RenameChatWindow_Popup
local FCF_StopAlertFlash = FCF_StopAlertFlash
local FILTERS = FILTERS
local GENERAL_CHAT_DOCK = GENERAL_CHAT_DOCK
local GeneralDockManager = GeneralDockManager
local GeneralDockManagerScrollFrame = GeneralDockManagerScrollFrame
local GeneralDockManagerScrollFrameChild = GeneralDockManagerScrollFrameChild
local GetCursorPosition = GetCursorPosition
local IsCombatLog = IsCombatLog
local NEW_CHAT_WINDOW = NEW_CHAT_WINDOW
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
local RENAME_CHAT_WINDOW = RENAME_CHAT_WINDOW
local ShowUIPanel = ShowUIPanel
local UIDropDownMenu_AddButton = UIDropDownMenu_AddButton
local UIDropDownMenu_CreateInfo = UIDropDownMenu_CreateInfo
local UIDropDownMenu_Initialize = UIDropDownMenu_Initialize
local UIParent = UIParent
-- luacheck: pop

local Colors = Constants.COLORS

local tabTexs = {
  '',
  'Selected',
  'Highlight'
}

function CT:OnInitialize()
  self.state = {
    mouseOver = false
  }
end

function CT:OnEnable()
  self.font = CreateFont("GlassChatTabsFont")
  self.font:SetFont(LSM:Fetch(LSM.MediaType.FONT, Core.db.profile.font), 12)
  self.font:SetShadowColor(0, 0, 0, 0)
  self.font:SetShadowOffset(1, -1)
  self.font:SetJustifyH("LEFT")
  self.font:SetJustifyV("MIDDLE")
  self.font:SetSpacing(3)

  -- ChatTabDock
  GeneralDockManager:SetWidth(MC:GetFrame():GetWidth())
  GeneralDockManager:SetHeight(20)
  GeneralDockManager:ClearAllPoints()
  GeneralDockManager:SetPoint("TOPLEFT", MC:GetFrame(), "TOPLEFT")

  GeneralDockManagerScrollFrame:SetHeight(20)
  GeneralDockManagerScrollFrame:SetPoint("TOPLEFT", _G.ChatFrame2Tab, "TOPRIGHT")
  GeneralDockManagerScrollFrameChild:SetHeight(20)

  local opacity = 0.4
  local dock = {}

  dock.leftBg = GeneralDockManager:CreateTexture(nil, "BACKGROUND")
  dock.leftBg:SetPoint("LEFT")
  dock.leftBg:SetWidth(50)
  dock.leftBg:SetHeight(20)
  dock.leftBg:SetColorTexture(1, 1, 1, 1)
  dock.leftBg:SetGradientAlpha(
    "HORIZONTAL",
    Colors.black.r, Colors.black.g, Colors.black.b, 0,
    Colors.black.r, Colors.black.g, Colors.black.b, opacity
  )

  dock.centerBg = GeneralDockManager:CreateTexture(nil, "BACKGROUND")
  dock.centerBg:SetPoint("LEFT", 50, 0)
  dock.centerBg:SetPoint("RIGHT", -250, 0)
  dock.centerBg:SetHeight(20)
  dock.centerBg:SetColorTexture(
    Colors.black.r,
    Colors.black.g,
    Colors.black.b,
    opacity
  )

  dock.rightBg = GeneralDockManager:CreateTexture(nil, "BACKGROUND")
  dock.rightBg:SetPoint("RIGHT")
  dock.rightBg:SetWidth(250)
  dock.rightBg:SetHeight(20)
  dock.rightBg:SetColorTexture(1, 1, 1, 1)
  dock.rightBg:SetGradientAlpha(
    "HORIZONTAL",
    Colors.black.r, Colors.black.g, Colors.black.b, opacity,
    Colors.black.r, Colors.black.g, Colors.black.b, 0
  )

  -- Customize chat tabs
  for i=1, NUM_CHAT_WINDOWS do
    local chatFrame = _G["ChatFrame"..i]
    local tab = _G["ChatFrame"..i.."Tab"]
    local dropDown = _G["ChatFrame"..i.."TabDropDown"]

    for _, texName in ipairs(tabTexs) do
      _G[tab:GetName()..texName..'Left']:SetTexture()
      _G[tab:GetName()..texName..'Middle']:SetTexture()
      _G[tab:GetName()..texName..'Right']:SetTexture()
    end

    tab:SetHeight(20)
    tab:SetNormalFontObject("GlassChatTabsFont")
    tab.Text:ClearAllPoints()
    tab.Text:SetPoint("LEFT", 15, 0)
    tab:SetWidth(tab.Text:GetStringWidth() + 15 * 2)

    self:RawHook(tab, "SetAlpha", function (alpha)
      self.hooks[tab].SetAlpha(tab, 1)
    end, true)

    -- Set width dynamically based on text width
    self:RawHook(tab, "SetWidth", function (_, width)
      self.hooks[tab].SetWidth(tab, tab:GetTextWidth() + 15 * 2)
    end, true)

    self:RawHook(tab.Text, "SetTextColor", function (...)
      self.hooks[tab.Text].SetTextColor(tab.Text, Colors.apache.r, Colors.apache.g, Colors.apache.b)
    end, true)

    -- Don't highlight when frame is already visible
    self:RawHook(tab.glow, "Show", function ()
      if SMF.state.frames[i] and not SMF.state.frames[i]:IsVisible() then
        self.hooks[tab.glow].Show(tab.glow)
      end
    end, true)

    -- Un-highlight when clicked
    tab:HookScript("OnClick", function ()
      FCF_StopAlertFlash(chatFrame)
    end)

    -- Disable dragging for General and CombatLog
    if chatFrame == DEFAULT_CHAT_FRAME or IsCombatLog(chatFrame) then
      tab:RegisterForDrag()
    end

    -- Override context menu
    UIDropDownMenu_Initialize(dropDown, function ()
      local info = UIDropDownMenu_CreateInfo()
      info.text = RENAME_CHAT_WINDOW
      info.func = FCF_RenameChatWindow_Popup
      info.notCheckable = 1
      UIDropDownMenu_AddButton(info)

      -- Create new chat window
      if chatFrame == DEFAULT_CHAT_FRAME then
        info = UIDropDownMenu_CreateInfo()
        info.text = NEW_CHAT_WINDOW
        info.func = FCF_NewChatWindow
        info.notCheckable = 1
        if FCF_GetNumActiveChatFrames() == NUM_CHAT_WINDOWS then
          info.disabled = 1
        end
        UIDropDownMenu_AddButton(info)
      end

      -- Close chat window
      if chatFrame ~= DEFAULT_CHAT_FRAME and not IsCombatLog(chatFrame) then
        info = UIDropDownMenu_CreateInfo()
        info.text = CLOSE_CHAT_WINDOW
        info.func = FCF_PopInWindow
        info.arg1 = chatFrame
        info.notCheckable = 1
        UIDropDownMenu_AddButton(info)
      end

      -- Filter header
      info = UIDropDownMenu_CreateInfo();
      info.text = FILTERS;
      info.isTitle = 1;
      info.notCheckable = 1;
      UIDropDownMenu_AddButton(info);

      -- Configure settings
      info = UIDropDownMenu_CreateInfo();
      info.text = CHAT_CONFIGURATION;
      info.func = function() ShowUIPanel(ChatConfigFrame); end;
      info.notCheckable = 1;
      UIDropDownMenu_AddButton(info);
    end, "MENU")
  end

  -- Override drag behaviour
  -- Disable undocking frames
  self:RawHook("FCF_StopDragging", function (chatFrame)
    chatFrame:StopMovingOrSizing();
    _G[chatFrame:GetName().."Tab"]:UnlockHighlight();

    FCFDock_HideInsertHighlight(GENERAL_CHAT_DOCK);

    local mouseX, mouseY = GetCursorPosition();
    mouseX, mouseY = mouseX / UIParent:GetScale(), mouseY / UIParent:GetScale();
    FCF_DockFrame(chatFrame, FCFDock_GetInsertIndex(GENERAL_CHAT_DOCK, chatFrame, mouseX, mouseY), true);
  end, true)

  -- Intro animations
  self.introAg = GeneralDockManager:CreateAnimationGroup()
  local fadeIn = self.introAg:CreateAnimation("Alpha")
  fadeIn:SetFromAlpha(0)
  fadeIn:SetToAlpha(1)
  fadeIn:SetDuration(0.3)
  fadeIn:SetSmoothing("OUT")

  -- Outro animations
  self.outroAg = GeneralDockManager:CreateAnimationGroup()
  local fadeOut = self.outroAg:CreateAnimation("Alpha")
  fadeOut:SetFromAlpha(1)
  fadeOut:SetToAlpha(0)
  fadeOut:SetDuration(0.3)
  fadeOut:SetEndDelay(1)

  -- Hide the frame when the outro animation finishes
  self.outroAg:SetScript("OnFinished", function ()
    GeneralDockManager:Hide()
  end)

  -- Start intro animation when element is shown
  GeneralDockManager:SetScript("OnShow", function ()
    self.introAg:Play()
  end)

  GeneralDockManager:Hide()
end

function CT:OnEnterContainer()
  -- Don't hide tabs when mouse is over
  self.state.mouseOver = true

  if not GeneralDockManager:IsVisible() then
    GeneralDockManager:Show()
  end

  if self.outroTimer then
    self.outroTimer:Cancel()
  end

  if self.outroAg:IsPlaying() then
    self.outroAg:Stop()
    self.introAg:Play()
  end
end

function CT:OnLeaveContainer()
  -- Hide chat tab when mouse leaves
  self.state.mouseOver = false

  if Core.db.profile.chatShowOnMouseOver then
    -- When chatShowOnMouseOver is on, synchronize the chat tab's fade out with
    -- the chat
    self.outroTimer = C_Timer.NewTimer(Core.db.profile.chatHoldTime, function()
      if GeneralDockManager:IsVisible() then
        self.outroAg:Play()
      end
    end)
  else
    -- Otherwise hide it immediately on mouse leave
    self.outroAg:Play()
  end
end

function CT:OnUpdateFont()
  self.font:SetFont(LSM:Fetch(LSM.MediaType.FONT, Core.db.profile.font), 12)

  for i=1, NUM_CHAT_WINDOWS do
    local tab = _G["ChatFrame"..i.."Tab"]

    tab:SetWidth()  -- Calls hooked function
  end
end

function CT:OnUpdateFrame()
  GeneralDockManager:SetWidth(MC:GetFrame():GetWidth())

  for i=1, NUM_CHAT_WINDOWS do
    local tab = _G["ChatFrame"..i.."Tab"]

    tab:SetWidth()  -- Calls hooked function
  end
end
