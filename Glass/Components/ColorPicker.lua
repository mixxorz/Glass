local AceGUI = _G.LibStub("AceGUI-3.0")
local Type, Version = "GlassColorPicker", 1
if (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

local function ownsPopup(widget, session, picker)
  return widget.pickerSession == session and not AceGUI:IsReleasing(widget)
    and picker:GetExtraInfo() == session
end

local function closeSession(widget)
  local session = widget.pickerSession
  widget.pickerSession = nil
  local picker = _G.ColorPickerFrame
  if session and picker and picker.GetExtraInfo and picker:GetExtraInfo() == session then
    picker:Hide()
  end
end

local function openPicker(frame)
  local widget = frame.obj
  if widget.disabled then return end
  local picker = _G.ColorPickerFrame
  -- Without extraInfo there is no safe way to distinguish a reused widget's popup.
  if not picker or not picker.SetupColorPickerAndShow or not picker.GetExtraInfo
    or not picker.GetColorRGB or not picker.GetColorAlpha then return end

  closeSession(widget)
  picker:Hide()
  picker:SetFrameStrata("FULLSCREEN_DIALOG")
  picker:SetFrameLevel(frame:GetFrameLevel() + 10)
  picker:SetClampedToScreen(true)

  local session = {}
  widget.pickerSession = session
  local ready = false
  local r, g, b = widget.r, widget.g, widget.b
  local a = widget.HasAlpha and widget.a or 1
  local directAlpha = picker.Content and picker.Content.ColorPicker
  local function publish(red, green, blue, alpha)
    if not ready or not ownsPopup(widget, session, picker) then return end
    if red == widget.r and green == widget.g and blue == widget.b and alpha == widget.a then return end
    widget:SetColor(red, green, blue, alpha)
    widget:Fire("OnValueChanged", red, green, blue, alpha)
  end
  local function changed()
    if not ready or not ownsPopup(widget, session, picker) then return end
    local red, green, blue = picker:GetColorRGB()
    local alpha = 1
    if widget.HasAlpha then
      alpha = picker:GetColorAlpha()
      if not directAlpha then alpha = 1 - alpha end
    end
    publish(red, green, blue, alpha)
  end

  picker:SetupColorPickerAndShow({
    r = r, g = g, b = b,
    hasOpacity = widget.HasAlpha,
    opacity = directAlpha and a or (1 - a),
    extraInfo = session,
    swatchFunc = changed,
    opacityFunc = changed,
    cancelFunc = function() publish(r, g, b, a) end,
  })
  -- Setup changes RGB before OnShow initializes alpha; neither is a user edit.
  ready = true
  AceGUI:ClearFocus()
end

local function Constructor()
  -- Permanently adopt this public-factory widget into our own pool. Never return
  -- its custom scripts to the default ColorPicker pool used by other addons.
  local widget = AceGUI:Create("ColorPicker")
  widget.type = Type
  local baseAcquire, baseRelease = widget.OnAcquire, widget.OnRelease
  local baseUpdate = widget.frame:GetScript("OnUpdate")
  widget.OnAcquire = function(self)
    closeSession(self)
    if baseAcquire then baseAcquire(self) end
  end
  widget.OnRelease = function(self)
    closeSession(self)
    if baseRelease then baseRelease(self) end
  end
  widget.frame:SetScript("OnClick", openPicker)
  widget.frame:SetScript("OnUpdate", function(frame, elapsed)
    if baseUpdate then baseUpdate(frame, elapsed) end
    local self = frame.obj
    local session = self.pickerSession
    if not session then return end
    local picker = _G.ColorPickerFrame
    if not ownsPopup(self, session, picker) then
      self.pickerSession = nil
    elseif not picker:IsShown() and not _G.IsMouseButtonDown() then
      -- Outside cancellation hides on mouse-down, but swatches open on mouse-up.
      -- Wait out held clicks, rechecking ownership each frame before confirming.
      self.pickerSession = nil
      self:Fire("OnValueConfirmed", self.r, self.g, self.b, self.a)
    end
  end)
  return widget
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
