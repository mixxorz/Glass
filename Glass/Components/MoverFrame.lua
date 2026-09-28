local Core, Constants = unpack(select(2, ...))

local SaveFramePosition = Constants.ACTIONS.SaveFramePosition
local UpdateConfig = Constants.ACTIONS.UpdateConfig

local LOCK_MOVER = Constants.EVENTS.LOCK_MOVER
local UNLOCK_MOVER = Constants.EVENTS.UNLOCK_MOVER
local UPDATE_CONFIG = Constants.EVENTS.UPDATE_CONFIG

local MoverFrameMixin = {}

-- luacheck: push ignore 113
local CreateFrame = CreateFrame
local Mixin = Mixin
-- luacheck: pop

function MoverFrameMixin:Init()
  local editBoxMargin = 35
  self:ClearAllPoints()
  self:SetPoint(
    Core.db.profile.positionAnchor.point,
    Core.db.profile.positionAnchor.xOfs,
    Core.db.profile.positionAnchor.yOfs
  )
  self:SetWidth(Core.db.profile.frameWidth)
  self:SetHeight(Core.db.profile.frameHeight + editBoxMargin)
  self:SetResizable(true)
  self:SetResizeBounds(100, 1 + editBoxMargin, 9999, 9999 + editBoxMargin)

  self.bg = self:CreateTexture(nil, "BACKGROUND")
  self.bg:SetColorTexture(0, 1, 0, 0.5)
  self.bg:SetAllPoints()

  self.label = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self.label:SetPoint("CENTER")
  self.label:SetText("Main")

  self.resizeHandle = CreateFrame("Button", nil, self)
  self.resizeHandle:SetSize(20, 20)
  self.resizeHandle:SetPoint("BOTTOMRIGHT")
  self.resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  self.resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  self.resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  self.resizeHandle:SetScript("OnMouseDown", function (_, button)
    if button == "LeftButton" then
      self:StartSizing("BOTTOMRIGHT")
    end
  end)
  self.resizeHandle:SetScript("OnMouseUp", function (_, button)
    if button == "LeftButton" then
      self:StopMovingOrSizing()
      Core.db.profile.frameWidth = math.floor(self:GetWidth() + 0.5)
      Core.db.profile.frameHeight = math.floor(self:GetHeight() - editBoxMargin + 0.5)
      Core:Dispatch(UpdateConfig("frameWidth"))
      Core:Dispatch(UpdateConfig("frameHeight"))
    end
  end)

  self:Hide()

  self:RegisterForDrag("LeftButton")
  self:SetScript("OnDragStart", self.StartMoving)
  self:SetScript("OnDragStop", self.StopMovingOrSizing)

  if self.subscriptions == nil then
    self.subscriptions = {
      Core:Subscribe(LOCK_MOVER, function ()
        self:StopMovingOrSizing()
        self:Hide()
        self:EnableMouse(false)
        self:SetMovable(false)

        local point, _, _, xOfs, yOfs = self:GetPoint(1)
        local position = {
          point = point,
          xOfs = xOfs,
          yOfs = yOfs
        }

        Core:Dispatch(SaveFramePosition(position))
      end),
      Core:Subscribe(UNLOCK_MOVER, function ()
        self:Show()
        self:EnableMouse(true)
        self:SetMovable(true)
      end),
      Core:Subscribe(UPDATE_CONFIG, function (key)
        if (key == "frameWidth") then
          self:SetWidth(Core.db.profile.frameWidth)
        end

        if (key == "frameHeight") then
          self:SetHeight(Core.db.profile.frameHeight + editBoxMargin)
        end

        if key == "framePosition" then
          self:ClearAllPoints()
          self:SetPoint(
            Core.db.profile.positionAnchor.point,
            Core.db.profile.positionAnchor.xOfs,
            Core.db.profile.positionAnchor.yOfs
          )
        end
      end),
    }
  end
end

Core.Components.CreateMoverFrame = function (name, parent)
  local frame = CreateFrame("Frame", name, parent)
  local object = Mixin(frame, MoverFrameMixin)
  object:Init()
  return object
end
