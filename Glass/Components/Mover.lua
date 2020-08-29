local Core = unpack(select(2, ...))

-- luacheck: push ignore 113
local BackdropTemplateMixin = BackdropTemplateMixin
local CreateFrame = CreateFrame
local PlaySound = PlaySound
local SOUNDKIT = SOUNDKIT
local UIParent = UIParent
-- luacheck: pop

local Mover = {}

----
-- Mover
--
-- Handles frame repositioning
function Mover:Create()
  local o = {
    state = {
      mouseOver = false
    }
  }

  setmetatable(o, self)
  self.__index = self
  return o
end
function Mover:OnInitialize()
  self.state = {
    locked = true
  }
  self:CreateMoverDialog()
  self:CreateMoverFrame()
end

function Mover:CreateMoverFrame()
  local pos = Core.db.profile.positionAnchor

  self.moverFrame = CreateFrame("Frame", "GlassMoverFrame", UIParent)
  self.moverFrame:SetPoint(pos.point, pos.relativeTo, pos.relativePoint, pos.xOfs, pos.yOfs)
  self.moverFrame:SetWidth(Core.db.profile.frameWidth)
  self.moverFrame:SetHeight(Core.db.profile.frameHeight + 35)

  self.moverFrame.bg = self.moverFrame:CreateTexture(nil, "BACKGROUND")
  self.moverFrame.bg:SetColorTexture(0, 1, 0, 0.5)
  self.moverFrame.bg:SetAllPoints()

  self.moverFrame:Hide()

  self.moverFrame:RegisterForDrag("LeftButton")
  self.moverFrame:SetScript("OnDragStart", self.moverFrame.StartMoving)
  self.moverFrame:SetScript("OnDragStop", self.moverFrame.StopMovingOrSizing)
end

function Mover:GetMoverFrame()
  return self.moverFrame
end

function Mover:CreateMoverDialog()
  self.moverDialog = CreateFrame(
    "Frame", "GlassMoverDialog", UIParent,
    BackdropTemplateMixin and "BackdropTemplate" or nil
  )

  self.moverDialog:SetFrameStrata("DIALOG")
  self.moverDialog:SetToplevel(true)
  self.moverDialog:EnableMouse(true)
  self.moverDialog:SetMovable(true)
  self.moverDialog:SetClampedToScreen(true)
  self.moverDialog:SetWidth(360)
  self.moverDialog:SetHeight(110)
  self.moverDialog:SetBackdrop{
    bgFile="Interface\\DialogFrame\\UI-DialogBox-Background" ,
    edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    insets = {left = 11, right = 12, top = 12, bottom = 11},
    tileSize = 32,
    edgeSize = 32,
  }
  self.moverDialog:SetPoint("TOP", 0, -50)
  self.moverDialog:Hide()

  self.moverDialog:SetScript("OnShow", function() PlaySound(SOUNDKIT.IG_MAINMENU_OPTION) end)
  self.moverDialog:SetScript("OnHide", function() PlaySound(SOUNDKIT.GS_TITLE_OPTION_EXIT) end)

  self.moverDialog.header = self.moverDialog:CreateTexture(nil, "ARTWORK")
  self.moverDialog.header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  self.moverDialog.header:SetWidth(256)
  self.moverDialog.header:SetHeight(64)
  self.moverDialog.header:SetPoint("TOP", 0, 12)

  self.moverDialog.title = self.moverDialog:CreateFontString("ARTWORK")
  self.moverDialog.title:SetFontObject("GameFontNormal")
  self.moverDialog.title:SetPoint("TOP", self.moverDialog.header, "TOP", 0, -14)
  self.moverDialog.title:SetText("Glass")

  self.moverDialog.desc = self.moverDialog:CreateFontString("ARTWORK")
  self.moverDialog.desc:SetFontObject("GameFontHighlight")
  self.moverDialog.desc:SetJustifyV("TOP")
  self.moverDialog.desc:SetJustifyH("LEFT")
  self.moverDialog.desc:SetPoint("TOPLEFT", 18, -32)
  self.moverDialog.desc:SetPoint("BOTTOMRIGHT", -18, 48)
  self.moverDialog.desc:SetText("Chat frame unlocked. You can now drag the chat frame to reposition it.")

  self.moverDialog.lockButton = CreateFrame("Button", nil, self.moverDialog, "OptionsButtonTemplate")
  self.moverDialog.lockButton:SetText("Lock")
  self.moverDialog.lockButton:SetScript("OnClick", function()
    self:Lock()
  end)
  self.moverDialog.lockButton:SetPoint("BOTTOMRIGHT", -14, 14)
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

Core.Components.Mover = Mover
