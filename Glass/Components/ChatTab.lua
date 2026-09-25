local Core, Constants, Utils = unpack(select(2, ...))

local AceHook = Core.Libs.AceHook

local UnlockMover = Constants.ACTIONS.UnlockMover

local Colors = Constants.COLORS

local UPDATE_CONFIG = Constants.EVENTS.UPDATE_CONFIG

-- luacheck: push ignore 113
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local FCF_StopAlertFlash = FCF_StopAlertFlash
local IsCombatLog = IsCombatLog
local Mixin = Mixin
local UNLOCK_WINDOW = UNLOCK_WINDOW
-- luacheck: pop

local tabTexs = {
  "Left", "Middle", "Right",
  "ActiveLeft", "ActiveMiddle", "ActiveRight",
  "HighlightLeft", "HighlightMiddle", "HighlightRight"
}

local ChatTabMixin = {}

function ChatTabMixin:Init(slidingMessageFrame)
  self.slidingMessageFrame = slidingMessageFrame
  self.chatFrame = slidingMessageFrame.chatFrame

  for _, texName in ipairs(tabTexs) do
    self[texName]:SetTexture(nil)
  end

  self:SetHeight(Constants.DOCK_HEIGHT)
  self:SetNormalFontObject("GlassChatDockFont")
  self.Text:ClearAllPoints()
  self.Text:SetPoint("LEFT", Utils.getContentXPadding(), 0)
  self:SetWidth(self.Text:GetStringWidth() + Utils.getContentXPadding() * 2)

  if not self:IsHooked(self, "SetAlpha") then
    self:RawHook(self, "SetAlpha", function (alpha)
      self.hooks[self].SetAlpha(self, 1)
    end, true)
  end

  -- Set width dynamically based on text width
  if not self:IsHooked(self, "SetWidth") then
    self:RawHook(self, "SetWidth", function (_, width)
      self.hooks[self].SetWidth(self, self:GetTextWidth() + Utils.getContentXPadding() * 2)
    end, true)
  end

  if not self:IsHooked(self.Text, "SetTextColor") then
    self:RawHook(self.Text, "SetTextColor", function (...)
      -- Temporary chat frames retain their color
      if self.chatFrame.isTemporary then
        self.hooks[self.Text].SetTextColor(...)
      else
        self.hooks[self.Text].SetTextColor(self.Text, Colors.apache.r, Colors.apache.g, Colors.apache.b)
      end
    end, true)
  end

  -- Don't highlight when frame is already visible
  if not self:IsHooked(self.glow, "Show") then
    self:RawHook(self.glow, "Show", function ()
      if not slidingMessageFrame:IsVisible() then
        self.hooks[self.glow].Show(self.glow)
      end
    end, true)
  end

  -- Un-highlight when clicked
  if not self:IsHooked(self, "OnClick") then
    self:HookScript(self, "OnClick", function ()
      FCF_StopAlertFlash(self.chatFrame)
    end)
  end

  -- Disable dragging for General and CombatLog
  if self.chatFrame == DEFAULT_CHAT_FRAME or IsCombatLog(self.chatFrame) then
    self:RegisterForDrag()
  end

  if self.chatFrame == DEFAULT_CHAT_FRAME then
    _G.Menu.ModifyMenu("MENU_FCF_TAB", function (owner, rootDescription)
      if owner == self then
        rootDescription:CreateButton(UNLOCK_WINDOW, function ()
          Core:Dispatch(UnlockMover())
        end)
      end
    end)
  end

  -- Listeners
  if self.subscriptions == nil then
    self.subscriptions = {
      Core:Subscribe(UPDATE_CONFIG, function (key)
        if key == "frameWidth" or key == "contentXPadding" then
          self.Text:ClearAllPoints()
          self.Text:SetPoint("LEFT", Utils.getContentXPadding(), 0)
        end

        if key == "frameWidth" or key == "frameHeight" or key == "font" or
          key == "messageFontSize" or key == "contentXPadding" then
          self:SetWidth()
        end
      end)
    }
  end
end

Core.Components.CreateChatTab = function (slidingMessageFrame)
  local frame = _G[slidingMessageFrame.chatFrame:GetName().."Tab"]
  local object = Mixin(frame, ChatTabMixin)
  AceHook:Embed(object)
  object:Init(slidingMessageFrame)
  return object
end
