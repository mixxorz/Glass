local Core, Constants = unpack(select(2, ...))

local Colors = Constants.COLORS
local GLOW_INSET = 5
local GLOW_TEXTURE = "Interface\\Addons\\Glass\\Glass\\Assets\\jumpButtonGlow"

local function AddGlow(frame, side, left, right)
  local texture = frame:CreateTexture(nil, "ARTWORK")
  texture:SetTexture(GLOW_TEXTURE)
  texture:SetTexCoord(left, right, 0, 1)
  texture:SetVertexColor(Colors.apache.r, Colors.apache.g, Colors.apache.b)
  texture:SetPoint("TOP")
  texture:SetPoint("BOTTOM")
  texture:SetPoint(side)
  texture:SetPoint(side == "LEFT" and "RIGHT" or "LEFT", frame, "CENTER")
end

Core.Components.CreateNewMessageAlertFrame = function (button)
  local fading = Core.Components.FadingFrameMixin
  local frame = _G.Mixin(_G.CreateFrame("Frame", nil, button), fading)
  fading.Init(frame)
  frame:SetPoint("TOPLEFT", button, "TOPLEFT", -GLOW_INSET, GLOW_INSET)
  frame:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", GLOW_INSET, -GLOW_INSET)
  frame:EnableMouse(false)
  frame:SetFadeInDuration(0.15)
  frame:SetFadeOutDuration(0.15)
  AddGlow(frame, "LEFT", 0, 0.25)
  AddGlow(frame, "RIGHT", 0.75, 1)
  return frame
end
