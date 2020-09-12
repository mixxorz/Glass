local Core, Constants = unpack(select(2, ...))

local AceHook = Core.Libs.AceHook

local Colors = Constants.COLORS

local MOUSE_ENTER = Constants.EVENTS.MOUSE_ENTER
local MOUSE_LEAVE = Constants.EVENTS.MOUSE_LEAVE
local UPDATE_CONFIG = Constants.EVENTS.UPDATE_CONFIG

-- luacheck: push ignore 113
local Mixin = Mixin
local FCFDock_GetInsertIndex = FCFDock_GetInsertIndex
local FCFDock_HideInsertHighlight = FCFDock_HideInsertHighlight
local FCF_DockFrame = FCF_DockFrame
local GENERAL_CHAT_DOCK = GENERAL_CHAT_DOCK
local GeneralDockManager = GeneralDockManager
local GetCursorPosition = GetCursorPosition
local UIParent = UIParent
-- luacheck: pop

local ChatDockMixin = {}

function ChatDockMixin:Init(parent)
  self.state = {
    mouseOver = false
  }

  self:SetWidth(Core.db.profile.frameWidth)
  self:SetHeight(Constants.DOCK_HEIGHT)
  self:ClearAllPoints()
  self:SetPoint("TOPLEFT", parent, "TOPLEFT")
  self:SetFadeInDuration(0.6)
  self:SetFadeOutDuration(0.6)

  self.scrollFrame:SetHeight(Constants.DOCK_HEIGHT)
  self.scrollFrame:SetPoint("TOPLEFT", _G.ChatFrame2Tab, "TOPRIGHT")
  self.scrollFrame.child:SetHeight(Constants.DOCK_HEIGHT)

  local opacity = 0.4

  self.leftBg = self:CreateTexture(nil, "BACKGROUND")
  self.leftBg:SetPoint("LEFT")
  self.leftBg:SetWidth(50)
  self.leftBg:SetHeight(Constants.DOCK_HEIGHT)
  self.leftBg:SetColorTexture(1, 1, 1, 1)
  self.leftBg:SetGradientAlpha(
    "HORIZONTAL",
    Colors.black.r, Colors.black.g, Colors.black.b, 0,
    Colors.black.r, Colors.black.g, Colors.black.b, opacity
  )

  self.centerBg = self:CreateTexture(nil, "BACKGROUND")
  self.centerBg:SetPoint("LEFT", 50, 0)
  self.centerBg:SetPoint("RIGHT", -250, 0)
  self.centerBg:SetHeight(Constants.DOCK_HEIGHT)
  self.centerBg:SetColorTexture(
    Colors.black.r,
    Colors.black.g,
    Colors.black.b,
    opacity
  )

  self.rightBg = self:CreateTexture(nil, "BACKGROUND")
  self.rightBg:SetPoint("RIGHT")
  self.rightBg:SetWidth(250)
  self.rightBg:SetHeight(Constants.DOCK_HEIGHT)
  self.rightBg:SetColorTexture(1, 1, 1, 1)
  self.rightBg:SetGradientAlpha(
    "HORIZONTAL",
    Colors.black.r, Colors.black.g, Colors.black.b, opacity,
    Colors.black.r, Colors.black.g, Colors.black.b, 0
  )

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

  self:QuickHide()

  Core:Subscribe(MOUSE_ENTER, function ()
    -- Don't hide tabs when mouse is over
    self.state.mouseOver = true
    self:Show()
  end)

  Core:Subscribe(MOUSE_LEAVE, function ()
    -- Hide chat tab when mouse leaves
    self.state.mouseOver = false

    if Core.db.profile.chatShowOnMouseOver then
      -- When chatShowOnMouseOver is on, synchronize the chat tab's fade out with
      -- the chat
      self:HideDelay(Core.db.profile.chatHoldTime)
    else
      -- Otherwise hide it immediately on mouse leave
      self:Hide()
    end
  end)

  Core:Subscribe(UPDATE_CONFIG, function (key)
    if key == "frameWidth" then
      self:SetWidth(Core.db.profile.frameWidth)
    end
  end)
end

local isCreated = false

Core.Components.CreateChatDock = function (parent)
  if isCreated then
    error("ChatDock already exists. Only one ChatDock can exist at a time.")
  end

  local FadingFrameMixin = Core.Components.FadingFrameMixin

  isCreated = true
  local object = Mixin(GeneralDockManager, FadingFrameMixin, ChatDockMixin)
  AceHook:Embed(object)
  FadingFrameMixin.Init(object)
  ChatDockMixin.Init(object, parent)
  return object
end
