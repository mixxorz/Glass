local Core, Constants = unpack(select(2, ...))

local Colors = Constants.COLORS
local GLOW_INSET = 5
local GLOW_CORNER = 20
local GLOW_TEXTURE = "Interface\\Addons\\Glass\\Glass\\Assets\\jumpButtonGlow"

local function AddGlow(frame, side, left, right)
  local texture = frame:CreateTexture(nil, "ARTWORK")
  texture:SetTexture(GLOW_TEXTURE)
  texture:SetTexCoord(left, right, 0, 1)
  texture:SetVertexColor(Colors.apache.r, Colors.apache.g, Colors.apache.b)
  texture:SetPoint("TOP")
  texture:SetPoint("BOTTOM")
  if side == "left" then
    texture:SetWidth(GLOW_CORNER)
    texture:SetPoint("LEFT")
  elseif side == "right" then
    texture:SetWidth(GLOW_CORNER)
    texture:SetPoint("RIGHT")
  else
    texture:SetPoint("LEFT", GLOW_CORNER, 0)
    texture:SetPoint("RIGHT", -GLOW_CORNER, 0)
  end
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
  AddGlow(frame, "left", 0, 0.25)
  AddGlow(frame, "center", 0.25, 0.75)
  AddGlow(frame, "right", 0.75, 1)
  return frame
end
