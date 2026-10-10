local Core, _, Utils = unpack(select(2, ...))

local CreateNewMessageAlertFrame = Core.Components.CreateNewMessageAlertFrame
local super = Utils.super

-- luacheck: push ignore 113
local CreateFrame = CreateFrame
local Mixin = Mixin
-- luacheck: pop

local ScrollOverlayFrame = {}
local BUTTON_SIZE = 30
local EDGE_OFFSET = 10
local ICON_WIDTH, ICON_HEIGHT = 8, 10
local BACKGROUND = "Interface\\Addons\\Glass\\Glass\\Assets\\jumpButton"

local function AddBackgroundHalf(button, side, left, right)
  local texture = button:CreateTexture(nil, "BACKGROUND")
  texture:SetTexture(BACKGROUND)
  texture:SetTexCoord(left, right, 0, 1)
  texture:SetSize(BUTTON_SIZE / 2, BUTTON_SIZE)
  texture:SetPoint(side, button, side)
end

function ScrollOverlayFrame:Init()
  self:EnableMouse(false)
  self:SetFadeInDuration(0.3)
  self:SetFadeOutDuration(0.15)

  self.snapToBottomFrame = CreateFrame("Button", nil, self)
  local button = self.snapToBottomFrame
  button:SetFrameLevel(self:GetFrameLevel() + 2)
  button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
  button:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -EDGE_OFFSET, EDGE_OFFSET)
  -- Joining the pill texture's rounded end caps makes a circle without a new asset.
  AddBackgroundHalf(button, "LEFT", 0, 0.25)
  AddBackgroundHalf(button, "RIGHT", 0.75, 1)

  self.icon = button:CreateTexture(nil, "ARTWORK")
  self.icon:SetTexture("Interface\\Addons\\Glass\\Glass\\Assets\\snapToBottomIcon")
  -- Crop the asset's asymmetric transparent border so the visible arrow is centered.
  self.icon:SetTexCoord(2 / 16, 10 / 16, 1 / 16, 11 / 16)
  self.icon:SetSize(ICON_WIDTH, ICON_HEIGHT)
  self.icon:SetPoint("CENTER", button, "CENTER")

  self.newMessageAlertFrame = CreateNewMessageAlertFrame(button)
  self.newMessageAlertFrame:QuickHide()
  self:RefreshLayout(Core.db.profile.frameHeight)
end

function ScrollOverlayFrame:RefreshLayout(contentHeight)
  local height = math.min(BUTTON_SIZE + EDGE_OFFSET, contentHeight)
  self:SetHeight(height)
  self:ClearAllPoints()
  self:SetPoint("TOPLEFT", 0, -math.max(0, contentHeight - height))
  self:SetPoint("TOPRIGHT", 0, -math.max(0, contentHeight - height))
end

function ScrollOverlayFrame:SetScript(name, callback)
  if name == "OnClickSnapFrame" then
    self.snapToBottomFrame:SetScript("OnClick", callback)
    return
  end
  super(self).SetScript(self, name, callback)
end

function ScrollOverlayFrame:ShowNewMessageAlert()
  self.newMessageAlertFrame:Show()
end

function ScrollOverlayFrame:HideNewMessageAlert()
  self.newMessageAlertFrame:StopAnimating()
  self.newMessageAlertFrame:QuickHide()
end

local function CreateScrollOverlayFrame(parent)
  local FadingFrameMixin = Core.Components.FadingFrameMixin
  local frame = CreateFrame("Frame", nil, parent)
  local object = Mixin(frame, FadingFrameMixin, ScrollOverlayFrame)
  FadingFrameMixin.Init(object)
  ScrollOverlayFrame.Init(object)
  return object
end

Core.Components.CreateScrollOverlayFrame = CreateScrollOverlayFrame
