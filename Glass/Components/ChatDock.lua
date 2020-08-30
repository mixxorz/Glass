local Core, Constants = unpack(select(2, ...))

local AceHook = Core.Libs.AceHook

local Colors = Constants.COLORS

local MOUSE_ENTER = Constants.EVENTS.MOUSE_ENTER
local MOUSE_LEAVE = Constants.EVENTS.MOUSE_LEAVE
local UPDATE_CONFIG = Constants.EVENTS.UPDATE_CONFIG

-- luacheck: push ignore 113
local C_Timer = C_Timer
local Mixin = Mixin
local FCFDock_GetInsertIndex = FCFDock_GetInsertIndex
local FCFDock_HideInsertHighlight = FCFDock_HideInsertHighlight
local FCF_DockFrame = FCF_DockFrame
local GENERAL_CHAT_DOCK = GENERAL_CHAT_DOCK
local GeneralDockManager = GeneralDockManager
local GeneralDockManagerScrollFrame = GeneralDockManagerScrollFrame
local GeneralDockManagerScrollFrameChild = GeneralDockManagerScrollFrameChild
local GetCursorPosition = GetCursorPosition
local UIParent = UIParent
-- luacheck: pop

local ChatDockMixin = {}

function ChatDockMixin:Init(parent)
  self.state = {
    mouseOver = false
  }

  self:SetWidth(Core.db.profile.frameWidth)
  self:SetHeight(20)
  self:ClearAllPoints()
  self:SetPoint("TOPLEFT", parent, "TOPLEFT")

  GeneralDockManagerScrollFrame:SetHeight(20)
  GeneralDockManagerScrollFrame:SetPoint("TOPLEFT", _G.ChatFrame2Tab, "TOPRIGHT")
  GeneralDockManagerScrollFrameChild:SetHeight(20)

  local opacity = 0.4

  self.leftBg = self:CreateTexture(nil, "BACKGROUND")
  self.leftBg:SetPoint("LEFT")
  self.leftBg:SetWidth(50)
  self.leftBg:SetHeight(20)
  self.leftBg:SetColorTexture(1, 1, 1, 1)
  self.leftBg:SetGradientAlpha(
    "HORIZONTAL",
    Colors.black.r, Colors.black.g, Colors.black.b, 0,
    Colors.black.r, Colors.black.g, Colors.black.b, opacity
  )

  self.centerBg = self:CreateTexture(nil, "BACKGROUND")
  self.centerBg:SetPoint("LEFT", 50, 0)
  self.centerBg:SetPoint("RIGHT", -250, 0)
  self.centerBg:SetHeight(20)
  self.centerBg:SetColorTexture(
    Colors.black.r,
    Colors.black.g,
    Colors.black.b,
    opacity
  )

  self.rightBg = self:CreateTexture(nil, "BACKGROUND")
  self.rightBg:SetPoint("RIGHT")
  self.rightBg:SetWidth(250)
  self.rightBg:SetHeight(20)
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

  -- Intro animations
  self.introAg = self:CreateAnimationGroup()
  local fadeIn = self.introAg:CreateAnimation("Alpha")
  fadeIn:SetFromAlpha(0)
  fadeIn:SetToAlpha(1)
  fadeIn:SetDuration(0.3)
  fadeIn:SetSmoothing("OUT")

  -- Outro animations
  self.outroAg = self:CreateAnimationGroup()
  local fadeOut = self.outroAg:CreateAnimation("Alpha")
  fadeOut:SetFromAlpha(1)
  fadeOut:SetToAlpha(0)
  fadeOut:SetDuration(0.3)
  fadeOut:SetEndDelay(1)

  -- Hide the frame when the outro animation finishes
  self.outroAg:SetScript("OnFinished", function ()
    self:Hide()
  end)

  -- Start intro animation when element is shown
  self:SetScript("OnShow", function ()
    self.introAg:Play()
  end)

  self:Hide()

  Core:Subscribe(MOUSE_ENTER, function ()
    -- Don't hide tabs when mouse is over
    self.state.mouseOver = true

    if not self:IsVisible() then
      self:Show()
    end

    if self.outroTimer then
      self.outroTimer:Cancel()
    end

    if self.outroAg:IsPlaying() then
      self.outroAg:Stop()
      self.introAg:Play()
    end
  end)

  Core:Subscribe(MOUSE_LEAVE, function ()
    -- Hide chat tab when mouse leaves
    self.state.mouseOver = false

    if Core.db.profile.chatShowOnMouseOver then
      -- When chatShowOnMouseOver is on, synchronize the chat tab's fade out with
      -- the chat
      self.outroTimer = C_Timer.NewTimer(Core.db.profile.chatHoldTime, function()
        if self:IsVisible() then
          self.outroAg:Play()
        end
      end)
    else
      -- Otherwise hide it immediately on mouse leave
      self.outroAg:Play()
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

  isCreated = true
  local object = Mixin(GeneralDockManager, ChatDockMixin)
  AceHook:Embed(object)
  object:Init(parent)
  return object
end
