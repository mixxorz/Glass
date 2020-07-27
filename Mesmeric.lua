Mesmeric = LibStub("AceAddon-3.0"):NewAddon("Mesmeric", "AceConsole-3.0", "AceHook-3.0")

local AceGUI = LibStub("AceGUI-3.0")
local lodash = LibStub("lodash.wow")

local unpack = unpack

local map = lodash.map

-- Using "print" to debug wil cause a infinite loop
local print = function() end

function Mesmeric:OnInitialize()
  self.container = CreateFrame("Frame", "Mesmeric", UIParent)
  self.container:SetHeight(400)
  self.container:SetWidth(300)
  self.container:SetPoint("LEFT", UIParent, "LEFT", 20, 100)

  self.containerAg = self.container:CreateAnimationGroup()
  local startOffset = self.containerAg:CreateAnimation("Translation")
  startOffset:SetOffset(0, -18)
  startOffset:SetDuration(0)

  local translateUp = self.containerAg:CreateAnimation("Translation")
  translateUp:SetOffset(0, 18)
  translateUp:SetDuration(0.2)
  translateUp:SetSmoothing("OUT")

  self:Hook(_G.ChatFrame1, "AddMessage", true)
end

function Mesmeric:AddMessage(frame, text, red, green, blue, messageId, holdTime)
  holdTime = holdTime or 5
  red = red or 1
  green = green or 1
  blue = blue or 1

  local chatLine = CreateFrame("Frame", nil, self.container)
  chatLine:SetHeight(18)
  chatLine:SetWidth(300)
  chatLine:SetPoint("TOPLEFT", self.container, "BOTTOMLEFT")

  if self.prevLine then
    self.prevLine:ClearAllPoints()
    self.prevLine:SetPoint("BOTTOMLEFT", chatLine, "TOPLEFT")
  end

  self.prevLine = chatLine

  local chatLineBg = chatLine:CreateTexture(nil, "BACKGROUND")
  chatLineBg:SetAllPoints()
  chatLineBg:SetColorTexture(0, 0, 0, 0.6)

  local textLayer = chatLine:CreateFontString(nil, "ARTWORK")
  textLayer:SetFont("Fonts\\FRIZQT__.TTF", 12)
  textLayer:SetTextColor(red, green, blue, 1)
  textLayer:SetPoint("LEFT", 3, 0)
  textLayer:SetText(text)

  local introAg = chatLine:CreateAnimationGroup()

  local fadeIn = introAg:CreateAnimation("Alpha")
  fadeIn:SetFromAlpha(0)
  fadeIn:SetToAlpha(1)
  fadeIn:SetDuration(0.2)
  fadeIn:SetSmoothing("OUT")

  introAg:Play()
  self.containerAg:Play()

  C_Timer.After(holdTime, function()
    local outroAg = chatLine:CreateAnimationGroup()
    local fadeOut = outroAg:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(5)
    fadeOut:SetEndDelay(1)

    outroAg:SetScript("OnFinished", function ()
      print('---Hiding---')
      chatLine:Hide()
    end)

    print('---Start fadeout---')
    outroAg:Play()
  end)
end
