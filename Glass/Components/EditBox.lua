local Core, Constants, Utils = unpack(select(2, ...))

local AceHook = Core.Libs.AceHook

local Colors = Constants.COLORS

local EditBoxFocusGained = Constants.ACTIONS.EditBoxFocusGained
local EditBoxFocusLost = Constants.ACTIONS.EditBoxFocusLost

local LOCK_MOVER = Constants.EVENTS.LOCK_MOVER
local UNLOCK_MOVER = Constants.EVENTS.UNLOCK_MOVER
local UPDATE_CONFIG = Constants.EVENTS.UPDATE_CONFIG

-- luacheck: push ignore 113
local Mixin = Mixin
-- luacheck: pop

local EditBoxMixin = {}

local function GetEditBoxPadding(self)
  local available = self:GetWidth() - self.header:GetStringWidth() - 20
  return math.min(Utils.getEditBoxXPadding(), math.max(0, math.floor(available / 2)))
end

function EditBoxMixin:Init(parent)
  -- Keep AceHook off the Blizzard frame so its native HookScript API stays intact.
  local hooks = AceHook:Embed({})

  -- Hide default styling
  _G[self:GetName().."Left"]:Hide()
  _G[self:GetName().."Mid"]:Hide()
  _G[self:GetName().."Right"]:Hide()

  hooks:RawHook(_G[self:GetName().."Left"], "Show", function () end, true)
  hooks:RawHook(_G[self:GetName().."Mid"], "Show", function () end, true)
  hooks:RawHook(_G[self:GetName().."Right"], "Show", function () end, true)

  self.focusLeft:SetTexture(nil)
  self.focusMid:SetTexture(nil)
  self.focusRight:SetTexture(nil)

  -- New styling
  self:ClearAllPoints()

  self:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, Core.db.profile.editBoxAnchor.yOfs)

  if Core.db.profile.editBoxAnchor.position == "ABOVE" then
    self:ClearAllPoints()
    self:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 0, Core.db.profile.editBoxAnchor.yOfs)
  end

  self:SetFontObject("GlassEditBoxFont")
  self:SetWidth(Core.db.profile.frameWidth)
  self.header:SetFontObject("GlassEditBoxFont")

  local bg = self:CreateTexture(nil, "BACKGROUND")
  bg:SetColorTexture(
    Colors.codGray.r, Colors.codGray.g, Colors.codGray.b, Core.db.profile.editBoxBackgroundOpacity
  )
  bg:SetAllPoints()

  local Ypadding = self.header:GetLineHeight() * 0.66
  self:SetHeight(self.header:GetLineHeight() + Ypadding * 2)

  hooks:RawHook(self, "SetTextInsets", function ()
    Ypadding = self.header:GetLineHeight() * 0.66
    local padding = GetEditBoxPadding(self)
    self.header:ClearAllPoints()
    self.header:SetPoint("LEFT", padding, 0)
    local leftInset = math.min(self.header:GetStringWidth() + padding, self:GetWidth() - padding - 20)
    hooks.hooks[self].SetTextInsets(self, leftInset, padding, Ypadding, Ypadding)
  end, true)

  self:SetTextInsets()

  -- Animations
  -- Intro animations
  local introAg = self:CreateAnimationGroup()
  local fadeIn = introAg:CreateAnimation("Alpha")
  fadeIn:SetFromAlpha(0)
  fadeIn:SetToAlpha(1)
  fadeIn:SetDuration(0.2)
  fadeIn:SetSmoothing("OUT")

  -- Outro animations
  local outroAg = self:CreateAnimationGroup()
  local fadeOut = outroAg:CreateAnimation("Alpha")
  fadeOut:SetFromAlpha(1)
  fadeOut:SetToAlpha(0)
  fadeOut:SetDuration(0.05)

  -- Workaround for editbox being open on login
  self.glassInitialized = false

  self:SetScript("OnShow", function ()
    if self.glassInitialized then
      introAg:Play()
    else
      self.glassInitialized = true
    end
  end)

  outroAg:SetScript("OnFinished", function ()
    if not introAg:IsPlaying() then
      hooks.hooks[self].Hide(self)
    end
  end)

  local moverUnlocked = false
  hooks:RawHook(self, "Hide", function ()
    if not moverUnlocked then
      outroAg:Play()
    end
  end, true)

  hooks:HookScript(self, "OnEditFocusGained", function ()
    Core:Dispatch(EditBoxFocusGained())
  end)
  hooks:HookScript(self, "OnEditFocusLost", function ()
    Core:Dispatch(EditBoxFocusLost())
  end)

  Core:Subscribe(UNLOCK_MOVER, function ()
    moverUnlocked = true
    outroAg:Stop()
    self:Show()
  end)

  Core:Subscribe(LOCK_MOVER, function ()
    moverUnlocked = false
    if not self:HasFocus() then
      self:Hide()
    end
  end)

  Core:Subscribe(UPDATE_CONFIG, function (key)
    if key == "font" or key == "fontFlags" or key == "editBoxFontSize" then
      Ypadding = self.header:GetLineHeight() * 0.66
      self:SetHeight(self.header:GetLineHeight() + Ypadding * 2)
      self:SetTextInsets()
    end

    if key == "frameWidth" then
      self:SetWidth(Core.db.profile.frameWidth)
    end

    if key == "frameWidth" or key == "editBoxXPadding" then
      self:SetTextInsets()
    end

    if key == "editBoxBackgroundOpacity" then
      bg:SetColorTexture(
        Colors.codGray.r, Colors.codGray.g, Colors.codGray.b, Core.db.profile.editBoxBackgroundOpacity
      )
    end

    if key == "editBoxAnchor" then
      if Core.db.profile.editBoxAnchor.position == "ABOVE" then
        self:ClearAllPoints()
        self:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 0, Core.db.profile.editBoxAnchor.yOfs)
      else
        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, Core.db.profile.editBoxAnchor.yOfs)
      end
    end
  end)
end

Core.Components.CreateEditBox = function (parent)
  local object = Mixin(_G.ChatFrame1EditBox, EditBoxMixin)
  object:Init(parent)
  return object
end
