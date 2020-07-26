Chat2 = LibStub("AceAddon-3.0"):NewAddon("Chat2", "AceConsole-3.0", "AceHook-3.0")

local AceGUI = LibStub("AceGUI-3.0")
local lodash = LibStub("lodash.wow")

local unpack = unpack

local map = lodash.map

-- Using "print" to debug wil cause a infinite loop
local print = function() end

function Chat2:OnInitialize()
  self.container = CreateFrame("Frame", "Chat2", UIParent)
  self.container:SetHeight(400)
  self.container:SetWidth(300)
  self.container:SetPoint("LEFT", UIParent, "LEFT", 20, 100)

  -- local containerBg = self.container:CreateTexture(nil, "BACKGROUND")
  -- containerBg:SetAllPoints()
  -- containerBg:SetColorTexture(0, 1, 0, 0.6)

  self.containerAg = self.container:CreateAnimationGroup()
  local startOffset = self.containerAg:CreateAnimation("Translation")
  startOffset:SetOffset(0, -18)
  startOffset:SetDuration(0)

  local translateUp = self.containerAg:CreateAnimation("Translation")
  translateUp:SetOffset(0, 18)
  translateUp:SetDuration(0.2)
  translateUp:SetSmoothing("OUT")

  self:AddMessage("INITIALIZING CHAT2")

  self:RawHook(_G.ChatFrame1, "AddMessage", function (...)
    local args = {...}
    self:AddMessage(unpack(args))
  end, true)
end

Chat2:RegisterChatCommand("chat2", "AddMessage")

function Chat2:AddMessage(frame, text, red, green, blue, messageId, holdTime)
  print('---AddNewLine---')
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

  local introChatAg = chatLine:CreateAnimationGroup()

  local fadeIn = introChatAg:CreateAnimation("Alpha")
  fadeIn:SetFromAlpha(0)
  fadeIn:SetToAlpha(1)
  fadeIn:SetDuration(0.2)
  fadeIn:SetSmoothing("OUT")

  introChatAg:Play()
  self.containerAg:Play()

  C_Timer.After(holdTime, function()
    local outroChatAg = chatLine:CreateAnimationGroup()
    local fadeOut = outroChatAg:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(5)
    fadeOut:SetEndDelay(1)

    print('---Start fadeout---')
    outroChatAg:Play()
  end)

  C_Timer.After(holdTime + 5, function()
    print('---Hiding---')
    chatLine:Hide()
  end)
end
