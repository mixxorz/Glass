local Core, Constants, Utils = unpack(select(2, ...))
local Colors = Constants.COLORS
local TP = Core:GetModule("TextProcessing")
local MessageLineMixin = {}

function MessageLineMixin:Init(view)
  self.view = view
  if not self.text then
    self.text = self:CreateFontString(nil, "ARTWORK", "GlassMessageFont")
  end
  self:SetScript("OnHyperlinkClick", function (_, link, text, button)
    if self.view:IsInteractive("linksEnabled") then
      Core:Dispatch(Constants.ACTIONS.HyperlinkClick({link, text, button}))
    end
  end)
  self:SetScript("OnHyperlinkEnter", function (_, link, text)
    if Utils.canAccessValue(link) and self.view:IsInteractive("hoverEnabled")
      and self.view:GetSettings().mouseOverTooltips then
      self.hoveredLink = link
      Core:Dispatch(Constants.ACTIONS.HyperlinkEnter({link, text}))
    end
  end)
  self:SetScript("OnHyperlinkLeave", function (_, link)
    self.hoveredLink = nil
    Core:Dispatch(Constants.ACTIONS.HyperlinkLeave(link))
  end)
  self:UpdateFrame()
end

function MessageLineMixin:SetMessage(message)
  self.rawText = message.text
  self.displayText = TP:ProcessText(message.text, self.view:GetSettings())
  self.text:SetTextColor(message.r or 1, message.g or 1, message.b or 1, 1)
  self:UpdateFrame()
end

function MessageLineMixin:ReprocessText()
  self.displayText = TP:ProcessText(self.rawText, self.view:GetSettings())
end

function MessageLineMixin:UpdateTransitions()
  local settings = self.view:GetSettings()
  self:SetFadeInDuration(settings.messageFadeInDuration)
  self:SetFadeOutDuration(settings.messageFadeOutDuration)
end

function MessageLineMixin:ClearAnchor()
  -- Clear the text aspect before changing anchors or reusing a secret FontString.
  Utils.clearFontStringText(self.text)
  self.text:ClearAllPoints()
  self.anchorTarget, self.anchorRelativePoint, self.anchorPoint = nil, nil, nil
end

function MessageLineMixin:IsAnchoredTo(relativeTo, relativePoint, point)
  return self.anchorTarget == relativeTo and self.anchorRelativePoint == relativePoint and self.anchorPoint == point
end

function MessageLineMixin:SetAnchor(relativeTo, relativePoint, point)
  if self:IsAnchoredTo(relativeTo, relativePoint, point) then return end
  if self.anchorTarget then self:ClearAnchor() end
  local padding = point == "BOTTOMLEFT" and self.yPadding or -self.yPadding
  self.text:SetPoint(point, relativeTo, relativePoint, self.leftPadding, padding)
  self.text:SetText(self.displayText)
  self.anchorTarget, self.anchorRelativePoint, self.anchorPoint = relativeTo, relativePoint, point
end

function MessageLineMixin:UpdateFrame()
  local settings = self.view:GetSettings()
  local leftPadding, rightPadding = Utils.getMessagePadding(settings)
  self:ClearAnchor()
  self:ClearAllPoints()
  self.text:SetFontObject(self.view.window and self.view.window.fonts.message or "GlassMessageFont")
  self.text:SetWidth(math.max(1, settings.frameWidth - leftPadding - rightPadding))
  self.text:SetJustifyH("LEFT")
  self.text:SetWordWrap(true)
  self.text:SetNonSpaceWrap(true)
  self.text:SetIndentedWordWrap(settings.indentWordWrap)
  self.text:SetMaxLines(0)
  self.leftPadding = leftPadding
  self.yPadding = self.text:GetLineHeight() * settings.messageLinePadding
  self.publicHeight = nil

  -- The engine sizes the row around wrapped text; Lua never reads these bounds.
  self:SetPoint("TOPLEFT", self.text, "TOPLEFT", -leftPadding, self.yPadding)
  self:SetPoint("BOTTOMRIGHT", self.text, "BOTTOMRIGHT", rightPadding, -self.yPadding)
  self:SetAnchor(self:GetParent(), "BOTTOMLEFT", "BOTTOMLEFT")
  self:UpdateTransitions()

  local links = self.view:IsInteractive("linksEnabled")
  local tooltips = self.view:IsInteractive("hoverEnabled") and settings.mouseOverTooltips
  if not tooltips and self.hoveredLink then
    Core:Dispatch(Constants.ACTIONS.HyperlinkLeave(self.hoveredLink))
    self.hoveredLink = nil
  end
  self:SetHyperlinksEnabled(links or tooltips)
  -- Hyperlinks receive their own events; ordinary message text stays click-through.
  self:EnableMouse(false)
  self:EnableMouseWheel(false)
  self:UpdateTextures()
end

function MessageLineMixin:UpdateTextures()
  local settings = self.view:GetSettings()
  self:SetChatGradientBackground(Colors.codGray, settings.chatBackgroundOpacity, settings)
end

local function CreateMessageLine(parent, view)
  local Fading = Core.Components.FadingFrameMixin
  local Gradient = Core.Components.GradientBackgroundMixin
  local frame = _G.Mixin(_G.CreateFrame("Frame", nil, parent), Fading, Gradient, MessageLineMixin)
  Fading.Init(frame)
  Gradient.Init(frame)
  frame:Init(view)
  return frame
end

Core.Components.CreateMessageLine = CreateMessageLine
Core.Components.CreateMessageLinePool = function (parent, view)
  return _G.CreateObjectPool(
    function () return CreateMessageLine(parent, view) end,
    function (_, message)
      if message.hoveredLink then
        Core:Dispatch(Constants.ACTIONS.HyperlinkLeave(message.hoveredLink))
        message.hoveredLink = nil
      end
      message:QuickHide()
      message:ClearAnchor()
      message:ClearAllPoints()
      message.rawText, message.displayText, message.publicHeight = nil, nil, nil
    end
  )
end
