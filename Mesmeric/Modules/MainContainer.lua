local Core, Constants = unpack(select(2, ...))
local CT = Core:GetModule("ChatTabs")
local MC = Core:GetModule("MainContainer")
local SMF = Core:GetModule("SlidingMessageFrame")

-- luacheck: push ignore 113
local ChatFrameChannelButton = ChatFrameChannelButton
local ChatFrameMenuButton = ChatFrameMenuButton
local CreateFont = CreateFont
local CreateFrame = CreateFrame
local GeneralDockManager = GeneralDockManager
local MouseIsOver = MouseIsOver
local QuickJoinToastButton = QuickJoinToastButton
local UIParent = UIParent
-- luacheck: pop

function MC:OnInitialize()
  self.state = {
    mouseOver = false
  }

  self.container = CreateFrame("Frame", "MesmericFrame", UIParent)
  self.container:SetSize(unpack(Constants.DEFAULT_SIZE))
  self.container:SetPoint("TOPLEFT", GeneralDockManager, "BOTTOMLEFT", 0, 20)

  self.container.bg = self.container:CreateTexture(nil, "BACKGROUND")
  self.container.bg:SetColorTexture(1, 0, 0, 0)
  self.container.bg:SetAllPoints()

  self.timeElapsed = 0
  self.container:SetScript("OnUpdate", function (_, elapsed)
    self:OnUpdate(elapsed)
  end)

  -- Main font
  local font = CreateFont("MesmericFont")
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
