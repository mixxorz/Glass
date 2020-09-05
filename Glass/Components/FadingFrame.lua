local Core, _, Utils = unpack(select(2, ...))

local super = Utils.super

-- luacheck: push ignore 113
local CreateFrame = CreateFrame
local Mixin = Mixin
-- luacheck: pop

local FadingFrameMixin = {}

function FadingFrameMixin:Init()
  if self.showAg == nil then
    self.showAg = self:CreateAnimationGroup()
    self.fadeIn = self.showAg:CreateAnimation("Alpha")
    self.fadeIn:SetFromAlpha(0)
    self.fadeIn:SetToAlpha(1)
    self.fadeIn:SetDuration(0)
    self.fadeIn:SetSmoothing("OUT")

    self.showAg:SetScript("OnPlay", function ()
      self:QuickShow()
    end)
  end

  if self.hideAg == nil then
    self.hideAg = self:CreateAnimationGroup()
    self.fadeOut = self.hideAg:CreateAnimation("Alpha")
    self.fadeOut:SetFromAlpha(1)
    self.fadeOut:SetToAlpha(0)
    self.fadeOut:SetDuration(0)

    self.hideAg:SetScript("OnFinished", function ()
      self:QuickHide()
    end)
  end
end

function FadingFrameMixin:QuickShow()
  super(self).Show(self)
end

function FadingFrameMixin:QuickHide()
  super(self).Hide(self)
end

function FadingFrameMixin:Show()
  if not self:IsVisible() then
    self.showAg:Play()
  end
end

function FadingFrameMixin:Hide()
  if self:IsVisible() then
    self.hideAg:Play()
  end
end

function FadingFrameMixin:SetFadeInDuration(duration)
  self.fadeIn:SetDuration(duration)
end

function FadingFrameMixin:SetFadeOutDuration(duration)
  self.fadeOut:SetDuration(duration)
end

local function CreateFadingFrame(frameType, name, parent)
  local frame = CreateFrame(frameType, name, parent)
  local object = Mixin(frame, FadingFrameMixin)
  object:Init()
  return object
end

Core.Components.CreateFadingFrame = CreateFadingFrame
Core.Components.FadingFrameMixin = FadingFrameMixin
