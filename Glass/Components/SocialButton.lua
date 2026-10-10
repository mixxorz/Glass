local Core, Constants = unpack(select(2, ...))

local AceHook = Core.Libs.AceHook
local events = Constants.EVENTS
local CreateFrame = _G.CreateFrame
local UIParent = _G.UIParent
local Mixin = _G.Mixin

local SocialButtonMixin = {}

function SocialButtonMixin:ShouldShowButton()
  if not Core.db.profile.showSocialButton then return false end
  if self.button.InitMKB then
    if _G.InputUtil and _G.InputUtil.IsMKBUIEnabled and not _G.InputUtil.IsMKBUIEnabled() then
      return false
    end
    if _G.C_GameRules and _G.Enum.GameRule
      and _G.C_GameRules.IsGameRuleActive(_G.Enum.GameRule.IngameFriendsListDisabled) then
      return false
    end
  end
  return true
end

function SocialButtonMixin:UpdateToastDirection()
  local button = self.button
  if not button.SetToastDirection or not button.Toast then return end
  local left, right = button:GetLeft(), button:GetRight()
  if not left or not right then return end
  local scale = button:GetEffectiveScale()
  local leftSpace = left * scale
  local rightSpace = UIParent:GetWidth() * UIParent:GetEffectiveScale() - right * scale
  local toastWidth = button.Toast:GetWidth() * button.Toast:GetEffectiveScale()
  local isOnRight = rightSpace < toastWidth and leftSpace > rightSpace
  if button.isOnRight ~= isOnRight then button:SetToastDirection(isOnRight) end
  if button.displayedToast and not (button.ToastToFriendAnim and button.ToastToFriendAnim:IsPlaying()) then
    local width = button.Toast:GetWidth()
    button:SetHitRectInsets(isOnRight and -width or 0, isOnRight and 0 or -width, 0, 0)
  end
end

function SocialButtonMixin:AnchorButton()
  self.button:ClearAllPoints()
  self.button:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
end

function SocialButtonMixin:UpdatePosition()
  local position = Core.db.profile.socialButtonPosition
  self:ClearAllPoints()
  if position.point then
    self:SetPoint(position.point, UIParent, position.point, position.xOfs, position.yOfs)
  else
    self:SetPoint("BOTTOMLEFT", self.dock, "TOPLEFT", 0, 0)
  end
  self:AnchorButton()
  self:UpdateToastDirection()
end

function SocialButtonMixin:UpdateMoverVisibility()
  local shown = self.unlocked and self:ShouldShowButton() and self.button:IsShown()
  self:SetShown(shown)
  self:EnableMouse(shown)
  self:SetMovable(shown)
end

function SocialButtonMixin:FinishDragging()
  if not self.dragProfile then return end
  self:StopMovingOrSizing()
  self:SetScript("OnUpdate", nil)
  local x, y = self:GetLeft(), self:GetBottom()
  if x and y then
    self.dragProfile.socialButtonPosition = {point = "BOTTOMLEFT", xOfs = x, yOfs = y}
  end
  self.dragProfile = nil
  self:UpdatePosition()
end

function SocialButtonMixin:UpdateVisibility()
  self:FinishDragging()
  self.button:SetShown(self:ShouldShowButton())
  self:UpdateMoverVisibility()
end

function SocialButtonMixin:Init(button, dock)
  self.button, self.dock, self.unlocked = button, dock, false
  self:SetSize(button:GetSize())
  self:SetFrameStrata("DIALOG")
  self:SetClampedToScreen(true)
  self:Hide()

  self.bg = self:CreateTexture(nil, "BACKGROUND")
  self.bg:SetColorTexture(0, 1, 0, 0.5)
  self.bg:SetAllPoints()
  self.label = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self.label:SetPoint("BOTTOM", self, "TOP", 0, 2)
  self.label:SetText("Social")

  -- Skip Social in Blizzard's alert stack so it cannot reset our anchor or move other alerts.
  local container = button:GetAlertContainer()
  for _, subsystem in ipairs(container and container.alertFrameSubSystems or {}) do
    if subsystem.anchorFrame == button then
      self:RawHook(subsystem, "AdjustAnchors", function (_, relativeAlert)
        return relativeAlert
      end, true)
      break
    end
  end

  if button.SetToastDirection then
    self:SecureHook(button, "SetToastDirection", function () self:UpdateToastDirection() end)
  end

  self:RegisterForDrag("LeftButton")
  self:SetScript("OnDragStart", function ()
    if not self.unlocked then return end
    self.dragProfile = Core.db.profile
    self:StartMoving()
    self:SetScript("OnUpdate", function () self:UpdateToastDirection() end)
  end)
  self:SetScript("OnDragStop", function () self:FinishDragging() end)

  button:HookScript("OnShow", function ()
    -- Blizzard can show the widget again when input modes change.
    if not self:ShouldShowButton() then button:Hide() end
    self:UpdateMoverVisibility()
  end)
  button:HookScript("OnHide", function ()
    self:FinishDragging()
    self:UpdateMoverVisibility()
  end)

  Core:Subscribe(events.UNLOCK_MOVER, function ()
    self.unlocked = true
    self:UpdateMoverVisibility()
  end)
  Core:Subscribe(events.LOCK_MOVER, function ()
    self:FinishDragging()
    self.unlocked = false
    self:UpdateMoverVisibility()
    self:UpdateToastDirection()
  end)
  Core:Subscribe(events.UPDATE_CONFIG, function (key)
    if key == "showSocialButton" then self:UpdateVisibility() end
    if key == "socialButtonPosition" then
      self:FinishDragging()
      self:UpdatePosition()
    elseif key == "framePosition" or key == "frameWidth" or key == "frameHeight" then
      self:UpdateToastDirection()
    end
  end)

  self:UpdatePosition()
  self:UpdateVisibility()
  if container then container:UpdateAnchors() end
end

Core.Components.CreateSocialButton = function (dock)
  local button = _G.QuickJoinToastButton
  if not button then return nil end
  local frame = CreateFrame("Frame", "GlassSocialMover", UIParent)
  local object = Mixin(frame, SocialButtonMixin)
  AceHook:Embed(object)
  object:Init(button, dock)
  return object
end
