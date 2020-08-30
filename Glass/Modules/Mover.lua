local Core, Constants = unpack(select(2, ...))
local Mover = Core:GetModule("Mover")

local LOCK_MOVER = Constants.EVENTS.LOCK_MOVER
local UNLOCK_MOVER = Constants.EVENTS.UNLOCK_MOVER

local CreateMoverFrame = Core.Components.CreateMoverFrame
local CreateMoverDialog = Core.Components.CreateMoverDialog

-- luacheck: push ignore 113
local UIParent = UIParent
-- luacheck: pop

function Mover:OnInitialize()
  self.state = {
    locked = true
  }
  self.moverFrame = CreateMoverFrame("GlassMoverFrame", UIParent)
  self.moverDialog = CreateMoverDialog("GlassMoverDialog", UIParent)

  Core:Subscribe(LOCK_MOVER, function () self:Lock() end)
  Core:Subscribe(UNLOCK_MOVER, function () self:Unlock() end)
end

function Mover:GetMoverFrame()
  return self.moverFrame
end

function Mover:Lock()
  self.state.locked = true
  self.moverDialog:Hide()
  self.moverFrame:Hide()

  self.moverFrame:EnableMouse(false)
  self.moverFrame:SetMovable(false)

  -- Save position
  local point, relativeTo, relativePoint, xOfs, yOfs = self.moverFrame:GetPoint(1)
  Core.db.profile.positionAnchor = {
    point = point,
    relativeTo = relativeTo,
    relativePoint = relativePoint,
    xOfs = xOfs,
    yOfs = yOfs
  }
end

function Mover:Unlock()
  if not self.state.locked then
    -- Already unlocked
    return
  end

  self.state.locked = false
  self.moverDialog:Show()
  self.moverFrame:Show()

  self.moverFrame:EnableMouse(true)
  self.moverFrame:SetMovable(true)
end

function Mover:OnUpdateFrame()
  self.moverFrame:SetWidth(Core.db.profile.frameWidth)
  self.moverFrame:SetHeight(Core.db.profile.frameHeight + 35)
end
