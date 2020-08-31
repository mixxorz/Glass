local Core, Constants = unpack(select(2, ...))

local Colors = Constants.COLORS

local HyperlinkClick = Constants.ACTIONS.HyperlinkClick
local HyperlinkEnter = Constants.ACTIONS.HyperlinkEnter
local HyperlinkLeave = Constants.ACTIONS.HyperlinkLeave

-- luacheck: push ignore 113
local C_Timer = C_Timer
local CreateFrame = CreateFrame
local CreateObjectPool = CreateObjectPool
local Mixin = Mixin
-- luacheck: pop

local MessageLineMixin = {}

function MessageLineMixin:Init()
  self:SetWidth(Core.db.profile.frameWidth)

  -- Gradient background
  if self.leftBg == nil then
    self.leftBg = self:CreateTexture(nil, "BACKGROUND")
  end
  self.leftBg:SetPoint("LEFT")
  self.leftBg:SetWidth(50)
  self.leftBg:SetColorTexture(1, 1, 1, 1)
  self.leftBg:SetGradientAlpha(
    "HORIZONTAL",
    Colors.codGray.r, Colors.codGray.g, Colors.codGray.b, 0,
    Colors.codGray.r, Colors.codGray.g, Colors.codGray.b, Core.db.profile.chatBackgroundOpacity
  )

  if self.centerBg == nil then
    self.centerBg = self:CreateTexture(nil, "BACKGROUND")
  end
  self.centerBg:SetPoint("LEFT", 50, 0)
  self.centerBg:SetPoint("RIGHT", -250, 0)
  self.centerBg:SetColorTexture(
    Colors.codGray.r,
    Colors.codGray.g,
    Colors.codGray.b,
    Core.db.profile.chatBackgroundOpacity
  )

  if self.rightBg == nil then
    self.rightBg = self:CreateTexture(nil, "BACKGROUND")
  end
  self.rightBg:SetPoint("RIGHT")
  self.rightBg:SetWidth(250)
  self.rightBg:SetColorTexture(1, 1, 1, 1)
  self.rightBg:SetGradientAlpha(
    "HORIZONTAL",
    Colors.codGray.r, Colors.codGray.g, Colors.codGray.b, Core.db.profile.chatBackgroundOpacity,
    Colors.codGray.r, Colors.codGray.g, Colors.codGray.b, 0
  )

  if self.text == nil then
    self.text = self:CreateFontString(nil, "ARTWORK", "GlassMessageFont")
  end
  self.text:SetPoint("LEFT", Constants.TEXT_XPADDING, 0)
  self.text:SetWidth(Core.db.profile.frameWidth - Constants.TEXT_XPADDING * 2)

  -- Intro animations
  if self.introAg == nil then
    self.introAg = self:CreateAnimationGroup()
    local fadeIn = self.introAg:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.6)
    fadeIn:SetSmoothing("OUT")
  end

  -- Outro animations
  if self.outroAg == nil then
    self.outroAg = self:CreateAnimationGroup()
    local fadeOut = self.outroAg:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.6)
  end

  -- Hide the frame when the outro animation finishes
  self.outroAg:SetScript("OnFinished", function ()
    self:Hide()
  end)

  -- Start intro animation when element is shown
  self:SetScript("OnShow", function ()
    self.introAg:Play()

    -- Play outro after hold time
    if not self:GetParent():GetParent().state.mouseOver then
      self.outroTimer = C_Timer.NewTimer(Core.db.profile.chatHoldTime, function()
        if self:IsVisible() then
          self.outroAg:Play()
        end
      end)
    end
  end)

  -- Hyperlink handling
  self:SetHyperlinksEnabled(true)

  self:SetScript("OnHyperlinkClick", function (_, link, text, button)
    Core:Dispatch(HyperlinkClick({link, text, button}))
  end)

  self:SetScript("OnHyperlinkEnter", function (_, link, text)
    if Core.db.profile.mouseOverTooltips then
      Core:Dispatch(HyperlinkEnter({link, text}))
    end
  end)

  self:SetScript("OnHyperlinkLeave", function (_, link)
    Core:Dispatch(HyperlinkLeave(link))
  end)
end

---
-- Update height based on text height
function MessageLineMixin:UpdateFrame()
  local Ypadding = self.text:GetLineHeight() * 0.25
  local messageLineHeight = (self.text:GetStringHeight() + Ypadding * 2)
  self:SetHeight(messageLineHeight)
  self.leftBg:SetHeight(messageLineHeight)
  self.centerBg:SetHeight(messageLineHeight)
  self.rightBg:SetHeight(messageLineHeight)

  self:SetWidth(Core.db.profile.frameWidth)
  self.text:SetWidth(Core.db.profile.frameWidth - Constants.TEXT_XPADDING * 2)
end

---
-- Update texture color based on setting
function MessageLineMixin:UpdateTextures()
  self.leftBg:SetGradientAlpha(
    "HORIZONTAL",
    Colors.codGray.r, Colors.codGray.g, Colors.codGray.b, 0,
    Colors.codGray.r, Colors.codGray.g, Colors.codGray.b, Core.db.profile.chatBackgroundOpacity
  )

  self.centerBg:SetColorTexture(
    Colors.codGray.r,
    Colors.codGray.g,
    Colors.codGray.b,
    Core.db.profile.chatBackgroundOpacity
  )

  self.rightBg:SetGradientAlpha(
    "HORIZONTAL",
    Colors.codGray.r, Colors.codGray.g, Colors.codGray.b, Core.db.profile.chatBackgroundOpacity,
    Colors.codGray.r, Colors.codGray.g, Colors.codGray.b, 0
  )
end

local function CreateMessageLine(parent)
  local frame = CreateFrame("Frame", nil, parent)
  local object = Mixin(frame, MessageLineMixin)
  object:Init()
  return object
end

local function CreateMessageLinePool(parent)
  return CreateObjectPool(
    function () return CreateMessageLine(parent) end,
    function (_, message)
      -- Reset all animations and timers
      if message.outroTimer then
        message.outroTimer:Cancel()
      end

      message.introAg:Stop()
      message.outroAg:Stop()
      message:Hide()
    end
  )
end

Core.Components.CreateMessageLine = CreateMessageLine
Core.Components.CreateMessageLinePool = CreateMessageLinePool
