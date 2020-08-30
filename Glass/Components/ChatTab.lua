local Core, Constants = unpack(select(2, ...))

local AceHook = Core.Libs.AceHook

local UnlockMover = Constants.ACTIONS.UnlockMover

local Colors = Constants.COLORS

-- luacheck: push ignore 113
local CHAT_CONFIGURATION = CHAT_CONFIGURATION
local CLOSE_CHAT_WINDOW = CLOSE_CHAT_WINDOW
local ChatConfigFrame = ChatConfigFrame
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local FCF_GetNumActiveChatFrames = FCF_GetNumActiveChatFrames
local FCF_NewChatWindow = FCF_NewChatWindow
local FCF_PopInWindow = FCF_PopInWindow
local FCF_RenameChatWindow_Popup = FCF_RenameChatWindow_Popup
local FCF_StopAlertFlash = FCF_StopAlertFlash
local FILTERS = FILTERS
local IsCombatLog = IsCombatLog
local Mixin = Mixin
local NEW_CHAT_WINDOW = NEW_CHAT_WINDOW
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
local RENAME_CHAT_WINDOW = RENAME_CHAT_WINDOW
local ShowUIPanel = ShowUIPanel
local UIDropDownMenu_AddButton = UIDropDownMenu_AddButton
local UIDropDownMenu_CreateInfo = UIDropDownMenu_CreateInfo
local UIDropDownMenu_Initialize = UIDropDownMenu_Initialize
local UNLOCK_WINDOW = UNLOCK_WINDOW
-- luacheck: pop

local tabTexs = {
  '',
  'Selected',
  'Highlight'
}

local ChatTabMixin = {}

function ChatTabMixin:Init(slidingMessageFrame)
  self.slidingMessageFrame = slidingMessageFrame
  self.chatFrame = slidingMessageFrame.chatFrame
  local dropDown = _G[self.chatFrame:GetName().."TabDropDown"]

  for _, texName in ipairs(tabTexs) do
    _G[self:GetName()..texName..'Left']:SetTexture()
    _G[self:GetName()..texName..'Middle']:SetTexture()
    _G[self:GetName()..texName..'Right']:SetTexture()
  end

  self:SetHeight(20)
  self:SetNormalFontObject("GlassChatDockFont")
  self.Text:ClearAllPoints()
  self.Text:SetPoint("LEFT", 15, 0)
  self:SetWidth(self.Text:GetStringWidth() + 15 * 2)

  self:RawHook(self, "SetAlpha", function (alpha)
    self.hooks[self].SetAlpha(self, 1)
  end, true)

  -- Set width dynamically based on text width
  self:RawHook(self, "SetWidth", function (_, width)
    self.hooks[self].SetWidth(self, self:GetTextWidth() + 15 * 2)
  end, true)

  self:RawHook(self.Text, "SetTextColor", function (...)
    self.hooks[self.Text].SetTextColor(self.Text, Colors.apache.r, Colors.apache.g, Colors.apache.b)
  end, true)

  -- Don't highlight when frame is already visible
  self:RawHook(self.glow, "Show", function ()
    if not slidingMessageFrame:IsVisible() then
      self.hooks[self.glow].Show(self.glow)
    end
  end, true)

  -- Un-highlight when clicked
  self:HookScript(self, "OnClick", function ()
    FCF_StopAlertFlash(self.chatFrame)
  end)

  -- Disable dragging for General and CombatLog
  if self.chatFrame == DEFAULT_CHAT_FRAME or IsCombatLog(self.chatFrame) then
    self:RegisterForDrag()
  end

  -- Override context menu
  UIDropDownMenu_Initialize(dropDown, function ()
    local info = UIDropDownMenu_CreateInfo()

    if self.chatFrame == DEFAULT_CHAT_FRAME then
      -- Unlock chat window
      info = UIDropDownMenu_CreateInfo()
      info.text = UNLOCK_WINDOW
      info.notCheckable = 1
      info.func = function()
        Core:Dispatch(UnlockMover())
      end
      UIDropDownMenu_AddButton(info)

      -- Create new chat window
      info = UIDropDownMenu_CreateInfo()
      info.text = NEW_CHAT_WINDOW
      info.func = FCF_NewChatWindow
      info.notCheckable = 1
      if FCF_GetNumActiveChatFrames() == NUM_CHAT_WINDOWS then
        info.disabled = 1
      end
      UIDropDownMenu_AddButton(info)
    end

    -- Rename window
    info.text = RENAME_CHAT_WINDOW
    info.func = FCF_RenameChatWindow_Popup
    info.notCheckable = 1
    UIDropDownMenu_AddButton(info)

    -- Close chat window
    if self.chatFrame ~= DEFAULT_CHAT_FRAME and not IsCombatLog(self.chatFrame) then
      info = UIDropDownMenu_CreateInfo()
      info.text = CLOSE_CHAT_WINDOW
      info.func = FCF_PopInWindow
      info.arg1 = self.chatFrame
      info.notCheckable = 1
      UIDropDownMenu_AddButton(info)
    end

    -- Filter header
    info = UIDropDownMenu_CreateInfo()
    info.text = FILTERS
    info.isTitle = 1
    info.notCheckable = 1
    UIDropDownMenu_AddButton(info)

    -- Configure settings
    info = UIDropDownMenu_CreateInfo()
    info.text = CHAT_CONFIGURATION
    info.func = function() ShowUIPanel(ChatConfigFrame) end
    info.notCheckable = 1
    UIDropDownMenu_AddButton(info)
  end, "MENU")
end

function ChatTabMixin:OnUpdateConfig()
  self:SetWidth() -- Calls hooked function
end

Core.Components.CreateChatTab = function (slidingMessageFrame)
  local frame = _G[slidingMessageFrame.chatFrame:GetName().."Tab"]
  local object = Mixin(frame, ChatTabMixin)
  AceHook:Embed(object)
  object:Init(slidingMessageFrame)
  return object
end
