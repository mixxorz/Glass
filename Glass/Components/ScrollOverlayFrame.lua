local Core, _, Utils = unpack(select(2, ...))

local CreateNewMessageAlertFrame = Core.Components.CreateNewMessageAlertFrame
local super = Utils.super

-- luacheck: push ignore 113
local CreateFrame = CreateFrame
local Mixin = Mixin
-- luacheck: pop

local ScrollOverlayFrame = {}
local BUTTON_HEIGHT = 30
local BOTTOM_OFFSET = 10
local ICON_WIDTH, ICON_HEIGHT = 8, 10
local CONTENT_PADDING, ICON_GAP = 12, 6
local CONTENT_EXTRA_WIDTH = CONTENT_PADDING * 2 + ICON_WIDTH + ICON_GAP
local CORNER = 15
local BACKGROUND = "Interface\\Addons\\Glass\\Glass\\Assets\\jumpButton"

local function AddBackground(button, name, width, coordinates)
  local texture = button:CreateTexture(nil, "BACKGROUND")
  texture:SetTexture(BACKGROUND)
  texture:SetTexCoord(unpack(coordinates))
  texture:SetWidth(width)
  texture:SetPoint("TOP", button, "TOP")
  texture:SetPoint("BOTTOM", button, "BOTTOM")
  if name == "left" then
    texture:SetPoint("LEFT")
  elseif name == "right" then
    texture:SetPoint("RIGHT")
  else
    texture:SetPoint("LEFT", CORNER, 0)
    texture:SetPoint("RIGHT", -CORNER, 0)
  end
end

function ScrollOverlayFrame:Init()
  self:SetHeight(64)
  self:SetPoint("TOPLEFT")
  self:SetPoint("TOPRIGHT")
  self:EnableMouse(false)
  self:SetFadeInDuration(0.3)
  self:SetFadeOutDuration(0.15)

  self.snapToBottomFrame = CreateFrame("Button", nil, self)
  local button = self.snapToBottomFrame
  button:SetFrameLevel(self:GetFrameLevel() + 2)
  button:SetHeight(BUTTON_HEIGHT)
  button:SetPoint("BOTTOM", self, "BOTTOM", 0, BOTTOM_OFFSET)
  AddBackground(button, "left", CORNER, {0, 0.25, 0, 1})
  AddBackground(button, "center", 0, {0.25, 0.75, 0, 1})
  AddBackground(button, "right", CORNER, {0.75, 1, 0, 1})

  self.icon = button:CreateTexture(nil, "ARTWORK")
  self.icon:SetTexture("Interface\\Addons\\Glass\\Glass\\Assets\\snapToBottomIcon")
  -- Crop the asset's asymmetric transparent border so the visible arrow is centered.
  self.icon:SetTexCoord(2 / 16, 10 / 16, 1 / 16, 11 / 16)
  self.icon:SetSize(ICON_WIDTH, ICON_HEIGHT)
  self.icon:SetPoint("LEFT", button, "LEFT", CONTENT_PADDING, 0)

  self.label = button:CreateFontString(nil, "ARTWORK", "GlassMessageFont")
  self.label:SetPoint("LEFT", button, "LEFT", CONTENT_PADDING + ICON_WIDTH + ICON_GAP, 0)
  self.label:SetText("Jump to latest message")
  self.label:SetTextColor(1, 1, 1)
  self.label:SetWordWrap(false)

  self.newMessageAlertFrame = CreateNewMessageAlertFrame(button)
  self.newMessageAlertFrame:QuickHide()
  self:RefreshLayout(Core.db.profile.frameHeight)
  super(self).SetScript(self, "OnSizeChanged", function ()
    self:UpdateButtonWidth()
  end)
end

function ScrollOverlayFrame:UpdateButtonWidth()
  self.label:SetWidth(math.max(1, self:GetWidth() - CONTENT_EXTRA_WIDTH))
  self.snapToBottomFrame:SetWidth(math.min(self:GetWidth(), self.label:GetStringWidth() + CONTENT_EXTRA_WIDTH))
end

function ScrollOverlayFrame:RefreshLayout(contentHeight, font)
  self.contentHeight = contentHeight
  self.label:SetFontObject(font or "GlassMessageFont")
  local buttonHeight = math.max(BUTTON_HEIGHT, self.label:GetLineHeight() + 12)
  self.snapToBottomFrame:SetHeight(buttonHeight)
  local height = math.min(buttonHeight + BOTTOM_OFFSET, contentHeight)
  self:SetHeight(height)
  self:ClearAllPoints()
  self:SetPoint("TOPLEFT", 0, -math.max(0, contentHeight - height))
  self:SetPoint("TOPRIGHT", 0, -math.max(0, contentHeight - height))
  self:UpdateButtonWidth()
end

function ScrollOverlayFrame:SetScript(name, callback)
  if name == "OnClickSnapFrame" then
    self.snapToBottomFrame:SetScript("OnClick", callback)
    return
  end
  super(self).SetScript(self, name, callback)
end

function ScrollOverlayFrame:ShowNewMessageAlert()
  self.label:SetText("Jump to latest unread messages")
  self:RefreshLayout(self.contentHeight or Core.db.profile.frameHeight, self.label:GetFontObject())
  self.newMessageAlertFrame:Show()
end

function ScrollOverlayFrame:HideNewMessageAlert()
  self.label:SetText("Jump to latest message")
  self:RefreshLayout(self.contentHeight or Core.db.profile.frameHeight, self.label:GetFontObject())
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
