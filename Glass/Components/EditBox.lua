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

local function HideNativeBackgrounds(editBox)
  for _, suffix in ipairs({"Left", "Mid", "Right", "FocusLeft", "FocusMid", "FocusRight"}) do
    local texture = _G[editBox:GetName() .. suffix]
    if texture then texture:Hide() end
  end
  for _, key in ipairs({"focusLeft", "focusMid", "focusRight"}) do
    local texture = editBox[key]
    if texture then texture:SetAlpha(0) end
  end
  if editBox.pratFrame then editBox.pratFrame:Hide() end
end

function EditBoxMixin:Init(parent)
  -- Keep AceHook off the Blizzard frame so its native HookScript API stays intact.
  local hooks = AceHook:Embed({})
  self:SetAltArrowKeyMode(Core.db.profile.editBoxAltArrowKeyMode)
  HideNativeBackgrounds(self)
  for _, suffix in ipairs({"Left", "Mid", "Right"}) do
    local texture = _G[self:GetName() .. suffix]
    if texture then hooks:RawHook(texture, "Show", function () end, true) end
  end

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
  fadeIn:SetDuration(Core.db.profile.editBoxFadeInDuration)
  fadeIn:SetSmoothing("OUT")

  -- Outro animations
  local outroAg = self:CreateAnimationGroup()
  local fadeOut = outroAg:CreateAnimation("Alpha")
  fadeOut:SetFromAlpha(1)
  fadeOut:SetToAlpha(0)
  fadeOut:SetDuration(Core.db.profile.editBoxFadeOutDuration)

  -- Workaround for editbox being open on login
  self.glassInitialized = false

  -- Reopening during the outro does not fire OnShow while the frame is still visible.
  hooks:RawHook(self, "Show", function ()
    outroAg:Stop()
    hooks.hooks[self].Show(self)
  end, true)

  self:HookScript("OnShow", function ()
    HideNativeBackgrounds(self)
    outroAg:Stop()
    introAg:Stop()
    if self.glassInitialized and Core.db.profile.editBoxFadeInDuration > 0 then
      introAg:Play()
    end
    self.glassInitialized = true
  end)

  outroAg:SetScript("OnFinished", function ()
    hooks.hooks[self].Hide(self)
  end)

  local moverUnlocked = false
  hooks:RawHook(self, "Hide", function ()
    if not moverUnlocked then
      introAg:Stop()
      outroAg:Stop()
      if Core.db.profile.editBoxFadeOutDuration > 0 then
        outroAg:Play()
      else
        hooks.hooks[self].Hide(self)
      end
    end
  end, true)

  self:HookScript("OnEditFocusGained", function ()
    Core:Dispatch(EditBoxFocusGained())
  end)
  self:HookScript("OnEditFocusLost", function ()
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
    if key == "editBoxAltArrowKeyMode" then
      self:SetAltArrowKeyMode(Core.db.profile.editBoxAltArrowKeyMode)
    end
    if key == "editBoxFadeInDuration" then
      if Core.db.profile.editBoxFadeInDuration == 0 then introAg:Stop() end
      fadeIn:SetDuration(Core.db.profile.editBoxFadeInDuration)
    end
    if key == "editBoxFadeOutDuration" then
      if Core.db.profile.editBoxFadeOutDuration == 0 and outroAg:IsPlaying() then
        outroAg:Stop()
        hooks.hooks[self].Hide(self)
      end
      fadeOut:SetDuration(Core.db.profile.editBoxFadeOutDuration)
    end

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
  object:SetParent(parent)
  object:Init(parent)
  return object
end
