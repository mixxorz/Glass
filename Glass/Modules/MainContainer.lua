local Core = unpack(select(2, ...))
local CT = Core:GetModule("ChatTabs")
local MC = Core:GetModule("MainContainer")
local M = Core:GetModule("Mover")
local SMF = Core:GetModule("SlidingMessageFrame")

-- luacheck: push ignore 113
local ChatAlertFrame = ChatAlertFrame
local ChatFrameChannelButton = ChatFrameChannelButton
local ChatFrameMenuButton = ChatFrameMenuButton
local CreateFont = CreateFont
local CreateFrame = CreateFrame
local MouseIsOver = MouseIsOver
local QuickJoinToastButton = QuickJoinToastButton
local UIParent = UIParent
-- luacheck: pop

function MC:OnInitialize()
  self.state = {
    mouseOver = false
  }

  self.container = CreateFrame("Frame", "GlassFrame", UIParent)
  self.container:SetWidth(Core.db.profile.frameWidth)
  self.container:SetHeight(Core.db.profile.frameHeight)
  self.container:SetPoint("TOPLEFT", M:GetMoverFrame())

  self.container.bg = self.container:CreateTexture(nil, "BACKGROUND")
  self.container.bg:SetColorTexture(1, 0, 0, 0)
  self.container.bg:SetAllPoints()

  self.timeElapsed = 0
  self.container:SetScript("OnUpdate", function (_, elapsed)
    self:OnUpdate(elapsed)
  end)

  ChatAlertFrame:ClearAllPoints()
  ChatAlertFrame:SetPoint("BOTTOMLEFT", self.container, "TOPLEFT", 15, 10)

  -- Main font
  local font = CreateFont("GlassFont")
  font:SetFont("Fonts\\FRIZQT__.TTF", 12)
  font:SetShadowColor(0, 0, 0, 1)
  font:SetShadowOffset(1, -1)
  font:SetJustifyH("LEFT")
  font:SetJustifyV("MIDDLE")
  font:SetSpacing(3)

  -- Hide other chat elements
  QuickJoinToastButton:Hide()
  ChatFrameChannelButton:Hide()
  ChatFrameMenuButton:Hide()
end

function MC:GetFrame()
  return self.container
end

function MC:OnEnter()
  self.state.mouseOver = true
  CT:OnEnterContainer()
  SMF:OnEnterContainer()
end

function MC:OnLeave()
  self.state.mouseOver = false
  CT:OnLeaveContainer()
  SMF:OnLeaveContainer()
end

function MC:OnUpdate(elapsed)
  self.timeElapsed = self.timeElapsed + elapsed

  while (self.timeElapsed > 0.1) do
    self.timeElapsed = self.timeElapsed - 0.1

    -- Mouse over tracking
    if self.state.mouseOver ~= MouseIsOver(self.container) then
      if not self.state.mouseOver then
        self:OnEnter()
      else
        self:OnLeave()
      end
    end
  end
end

function MC:OnUpdateFrame()
  self.container:SetWidth(Core.db.profile.frameWidth)
  self.container:SetHeight(Core.db.profile.frameHeight)
end
