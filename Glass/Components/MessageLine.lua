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
    if self.view:IsInteractive("hoverEnabled") and self.view:GetSettings().mouseOverTooltips then
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
  self.text:SetTextColor(message.r or 1, message.g or 1, message.b or 1, 1)
  self.text:SetText(TP:ProcessText(message.text, self.view:GetSettings()))
  self:UpdateFrame()
end

function MessageLineMixin:UpdateFrame()
  local settings = self.view:GetSettings()
  local leftPadding, rightPadding = Utils.getMessagePadding(settings)
  self:SetWidth(settings.frameWidth)
  self.text:SetFontObject(self.view.window and self.view.window.fonts.message or "GlassMessageFont")
  self.text:ClearAllPoints()
  self.text:SetPoint("LEFT", leftPadding, 0)
  self.text:SetWidth(math.max(1, settings.frameWidth - leftPadding - rightPadding))
  self.text:SetIndentedWordWrap(settings.indentWordWrap)
  if self.indentWordWrap ~= settings.indentWordWrap then
    self.indentWordWrap = settings.indentWordWrap
    -- Invalidate the cached text layout before measuring the changed wrap mode.
    local text = self.text:GetText()
    self.text:SetText(nil)
    self.text:SetText(text)
  end
  self:SetFadeInDuration(settings.chatFadeInDuration)
  self:SetFadeOutDuration(settings.chatFadeOutDuration)
  local yPadding = self.text:GetLineHeight() * settings.messageLinePadding
  self:SetHeight(math.max(1, self.text:GetStringHeight() + yPadding * 2))

  local links = self.view:IsInteractive("linksEnabled")
  local tooltips = self.view:IsInteractive("hoverEnabled") and settings.mouseOverTooltips
  if not tooltips and self.hoveredLink then
    Core:Dispatch(Constants.ACTIONS.HyperlinkLeave(self.hoveredLink))
    self.hoveredLink = nil
  end
  self:SetHyperlinksEnabled(links or tooltips)
  -- Hyperlinks receive their own events; ordinary message text stays click-through.
  self:EnableMouse(false)
  -- Keep wheel input on the message pane, even when a link is under the cursor.
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
      message:StopAnimating()
      message:QuickHide()
      message:ClearAllPoints()
      message.rawText = nil
    end
  )
end
