local Core = unpack(select(2, ...))

local MoverFrameMixin = {}

-- luacheck: push ignore 113
local CreateFrame = CreateFrame
local Mixin = Mixin
-- luacheck: pop

function MoverFrameMixin:Init()
  local pos = Core.db.profile.positionAnchor
  self:SetPoint(pos.point, pos.relativeTo, pos.relativePoint, pos.xOfs, pos.yOfs)
  self:SetWidth(Core.db.profile.frameWidth)
  self:SetHeight(Core.db.profile.frameHeight + 35)

  self.bg = self:CreateTexture(nil, "BACKGROUND")
  self.bg:SetColorTexture(0, 1, 0, 0.5)
  self.bg:SetAllPoints()

  self:Hide()

  self:RegisterForDrag("LeftButton")
  self:SetScript("OnDragStart", self.StartMoving)
  self:SetScript("OnDragStop", self.StopMovingOrSizing)
end

Core.Components.CreateMoverFrame = function (name, parent)
  local frame = CreateFrame("Frame", name, parent)
  local object = Mixin(frame, MoverFrameMixin)
  object:Init()
  return object
end
