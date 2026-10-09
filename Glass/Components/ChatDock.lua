local Core, Constants, Utils = unpack(select(2, ...))

local AceHook = Core.Libs.AceHook

local Colors = Constants.COLORS

local EDIT_BOX_FOCUS_GAINED = Constants.EVENTS.EDIT_BOX_FOCUS_GAINED
local EDIT_BOX_FOCUS_LOST = Constants.EVENTS.EDIT_BOX_FOCUS_LOST
local LOCK_MOVER = Constants.EVENTS.LOCK_MOVER
local MOUSE_ENTER = Constants.EVENTS.MOUSE_ENTER
local MOUSE_LEAVE = Constants.EVENTS.MOUSE_LEAVE
local UNLOCK_MOVER = Constants.EVENTS.UNLOCK_MOVER
local UPDATE_CONFIG = Constants.EVENTS.UPDATE_CONFIG

-- luacheck: push ignore 113
local Mixin = Mixin
local FCFDock_HideInsertHighlight = FCFDock_HideInsertHighlight
local FCF_DockFrame = FCF_DockFrame
local FCF_DockUpdate = FCF_DockUpdate
local GENERAL_CHAT_DOCK = GENERAL_CHAT_DOCK
local GeneralDockManager = GeneralDockManager
local GetCursorPosition = GetCursorPosition
local UIParent = UIParent
-- luacheck: pop

local ChatDockMixin = {}

local function UpdateBackground(self)
  local profile = Core.db.profile
  local left = math.min(profile.tabLeftGradientWidth, self:GetWidth() - 1)
  local right = math.min(profile.tabRightGradientWidth, self:GetWidth() - left)
  self:SetGradientBackground(left, right, Colors.black, profile.tabBarBackgroundOpacity)
end

local function ScrollToActualTab(scroll, elapsed)
  local target = scroll.glassScrollTarget
  if not target then
    scroll:SetScript("OnUpdate", nil)
    return
  end
  local position = scroll:GetHorizontalScroll()
  local delta = target - position
  if math.abs(delta) < 1 then
    scroll:SetHorizontalScroll(target)
    scroll:SetScript("OnUpdate", nil)
  else
    scroll:SetHorizontalScroll(position + delta * math.min(1, elapsed * 10))
  end
end

local function UpdateTabSpacing(dock)
  if dock ~= GENERAL_CHAT_DOCK then return end
  local spacing = Core.db.profile.tabSpacing or 0
  -- Horizontal padding belongs at the bar's outer edges, not between labels.
  local padding = Utils.getTabXPadding(Core.db.profile)
  local staticTab, dynamicTab
  local dynamicWidth, dynamicCount = 0, 0
  local selected = dock.selected
  local selectedLeft, selectedRight
  for _, frame in ipairs(dock.DOCKED_CHAT_FRAMES) do
    local tab = _G[frame:GetName() .. "Tab"]
    -- Native tab resizing can restore label anchors and padded widths.
    tab.Text:ClearAllPoints()
    tab.Text:SetWidth(0)
    tab.Text:SetWordWrap(false)
    tab.Text:SetPoint("LEFT", 0, 0)
    tab:SetWidth(tab.Text:GetStringWidth())
    if frame.isStaticDocked then
      tab:ClearAllPoints()
      if staticTab then
        tab:SetPoint("LEFT", staticTab, "RIGHT", spacing, 0)
      else
        tab:SetPoint("TOPLEFT", dock, "TOPLEFT", padding, 0)
      end
      staticTab = tab
    else
      tab:ClearAllPoints()
      if dynamicTab then
        -- Spacing is only the distance between adjacent labels.
        tab:SetPoint("LEFT", dynamicTab, "RIGHT", spacing, 0)
        dynamicWidth = dynamicWidth + spacing
      else
        tab:SetPoint("TOPLEFT", dock.scrollFrame:GetScrollChild(), "TOPLEFT")
      end
      if frame == selected then
        selectedLeft = dynamicWidth
        selectedRight = dynamicWidth + tab:GetWidth()
      end
      dynamicWidth = dynamicWidth + tab:GetWidth()
      dynamicCount = dynamicCount + 1
      dynamicTab = tab
    end
  end

  local scroll = dock.scrollFrame
  scroll:ClearAllPoints()
  scroll:SetPoint("TOPLEFT", staticTab or dock, staticTab and "TOPRIGHT" or "TOPLEFT",
    staticTab and spacing or padding, 0)
  scroll:SetPoint("BOTTOMRIGHT", dock, "BOTTOMRIGHT", -padding, 0)
  local available = scroll:GetWidth()
  local overflow = dynamicWidth > available
  if overflow then
    dock.overflowButton:Show()
    scroll:SetPoint("BOTTOMRIGHT", dock, "BOTTOMRIGHT", -padding - dock.overflowButton:GetWidth() - 5, 0)
  else
    dock.overflowButton:Hide()
  end
  local viewport = math.max(1, scroll:GetWidth())
  scroll:GetScrollChild():SetWidth(math.max(1, dynamicWidth))
  scroll.numDynFrames = dynamicCount
  local current = scroll:GetHorizontalScroll()
  local maximum = math.max(0, dynamicWidth - viewport)
  local target = math.min(current, maximum)
  if selectedLeft then
    if selectedLeft < target then
      target = selectedLeft
    elseif selectedRight > target + viewport then
      target = selectedRight - viewport
    end
  end
  scroll.glassScrollTarget = math.max(0, math.min(maximum, target))
  if math.abs(current - scroll.glassScrollTarget) >= 1 then
    scroll:SetScript("OnUpdate", ScrollToActualTab)
  else
    scroll:SetHorizontalScroll(scroll.glassScrollTarget)
    scroll:SetScript("OnUpdate", nil)
  end
end

local function GetInsertIndex(dock, dragged, mouseX)
  local lastIndex = dragged.isStaticDocked and 1 or #dock.DOCKED_CHAT_FRAMES + 1
  local left = dock.scrollFrame:GetLeft()
  local right = dock.scrollFrame:GetRight()
  for index, frame in ipairs(dock.DOCKED_CHAT_FRAMES) do
    if (not not frame.isStaticDocked) == (not not dragged.isStaticDocked) then
      local tab = _G[frame:GetName() .. "Tab"]
      local center = tab:GetLeft() and tab:GetRight() and (tab:GetLeft() + tab:GetRight()) / 2
      local visible = frame.isStaticDocked or (left and right and center and center >= left and center <= right)
      if visible and center and frame ~= dock.primary then
        if mouseX < center then return index end
        lastIndex = index + 1
      end
    end
  end
  return lastIndex
end

local function HideWhenInactive(self)
  if self.state.mouseOver or self.state.moverUnlocked or self.state.editBoxFocused then
    return
  end

  if Core.db.profile.chatShowOnMouseOver then
    self:HideDelay(Core.db.profile.chatHoldTime)
  else
    self:Hide()
  end
end

function ChatDockMixin:Init(parent)
  self.state = {
    mouseOver = false,
    moverUnlocked = false,
    editBoxFocused = _G.ChatFrame1EditBox:HasFocus()
  }

  self:SetWidth(Core.db.profile.frameWidth)
  self:SetHeight(Utils.getDockHeight(Core.db.profile))
  self:ClearAllPoints()
  self:SetPoint("TOPLEFT", parent, "TOPLEFT")
  self:SetFadeInDuration(0.6)
  self:SetFadeOutDuration(0.6)

  self.scrollFrame:SetHeight(Utils.getDockHeight(Core.db.profile))
  self.scrollFrame:SetPoint("TOPLEFT", _G.ChatFrame2Tab, "TOPRIGHT")
  self.scrollFrame.child:SetHeight(Utils.getDockHeight(Core.db.profile))

  -- Gradient background
  UpdateBackground(self)

  -- Override drag behaviour
  -- Disable undocking frames
  self:RawHook("FCF_StopDragging", function (chatFrame)
    chatFrame:StopMovingOrSizing();
    _G[chatFrame:GetName().."Tab"]:UnlockHighlight();

    FCFDock_HideInsertHighlight(GENERAL_CHAT_DOCK);

    local mouseX = GetCursorPosition();
    mouseX = mouseX / UIParent:GetScale();
    FCF_DockFrame(chatFrame, GetInsertIndex(GENERAL_CHAT_DOCK, chatFrame, mouseX), true);
  end, true)

  if not self:IsHooked("FCFDock_UpdateTabs") then
    self:SecureHook("FCFDock_UpdateTabs", UpdateTabSpacing)
  end

  if self.state.editBoxFocused then
    self:QuickShow()
  else
    self:QuickHide()
  end

  if self.subscriptions == nil then
    self.subscriptions = {
      Core:Subscribe(MOUSE_ENTER, function ()
        -- Don't hide tabs when mouse is over
        self.state.mouseOver = true
        self:Show()
      end),
      Core:Subscribe(MOUSE_LEAVE, function ()
        self.state.mouseOver = false
        HideWhenInactive(self)
      end),
      Core:Subscribe(EDIT_BOX_FOCUS_GAINED, function ()
        self.state.editBoxFocused = true
        self:Show()
      end),
      Core:Subscribe(EDIT_BOX_FOCUS_LOST, function ()
        self.state.editBoxFocused = false
        HideWhenInactive(self)
      end),
      Core:Subscribe(UNLOCK_MOVER, function ()
        self.state.moverUnlocked = true
        self:Show()
      end),
      Core:Subscribe(LOCK_MOVER, function ()
        self.state.moverUnlocked = false
        HideWhenInactive(self)
      end),
      Core:Subscribe(UPDATE_CONFIG, function (key)
        if key == "frameWidth" then
          self:SetWidth(Core.db.profile.frameWidth)
        end

        if key == "tabFontSize" or key == "tabYPadding" then
          local height = Utils.getDockHeight(Core.db.profile)
          self:SetHeight(height)
          self.scrollFrame:SetHeight(height)
          self.scrollFrame.child:SetHeight(height)
        end
        if key == "tabSpacing" or key == "tabXPadding" then
          FCF_DockUpdate()
        end

        if key == "frameWidth" or key == "tabLeftGradientWidth" or
          key == "tabRightGradientWidth" or key == "tabBarBackgroundOpacity" then
          UpdateBackground(self)
        end
      end)
    }
  end
end

local isCreated = false

Core.Components.CreateChatDock = function (parent)
  if isCreated then
    error("ChatDock already exists. Only one ChatDock can exist at a time.")
  end

  local FadingFrameMixin = Core.Components.FadingFrameMixin
  local GradientBackgroundMixin = Core.Components.GradientBackgroundMixin

  isCreated = true
  local object = Mixin(GeneralDockManager, FadingFrameMixin, GradientBackgroundMixin, ChatDockMixin)
  AceHook:Embed(object)
  FadingFrameMixin.Init(object)
  GradientBackgroundMixin.Init(object)
  ChatDockMixin.Init(object, parent)
  return object
end
