local Core, Constants, Utils = unpack(select(2, ...))
local MessageRouter = Core:GetModule("MessageRouter")

local events = Constants.EVENTS
local colors = Constants.COLORS
local CreateFrame = _G.CreateFrame
local UIParent = _G.UIParent
local Mixin = _G.Mixin

local windows = {}
local pool = {}
local backgroundSettings = {
  chatBackgroundOpacity = true, leftGradientWidth = true, rightGradientWidth = true,
  tabBarBackgroundOpacity = true, tabLeftGradientWidth = true, tabRightGradientWidth = true,
}
local ExtraWindow = {}
ExtraWindow.__index = ExtraWindow

function ExtraWindow:Subscribe(event, handler)
  local listeners = self.listeners[event] or {}
  self.listeners[event] = listeners
  listeners[handler] = true
  return function () listeners[handler] = nil end
end

function ExtraWindow:Dispatch(event, payload)
  local listeners = self.listeners[event]
  if listeners then
    for handler in pairs(listeners) do handler(payload) end
  end
end

local function dockHeight(settings)
  return Utils.getDockHeight(settings)
end

function ExtraWindow:UpdateTabBackground()
  local settings = self.settings
  local width = settings.frameWidth
  local left = math.max(0, math.min(settings.tabLeftGradientWidth, width - 1))
  local rightWidth = settings.tabRightGradientWidth
  local right = math.max(0, math.min(rightWidth, width - left))
  self.tabBar:SetGradientBackground(left, right, colors.black, settings.tabBarBackgroundOpacity or 0)
end

function ExtraWindow:UpdateLayout()
  local settings = self.settings
  local frame = self.frame
  local width = settings.frameWidth or 400
  local barHeight = dockHeight(settings)
  local minHeight = settings.showTabBar and math.max(40, barHeight + 35) or 40
  local height = math.max(minHeight, settings.frameHeight or 200)
  settings.frameHeight = height
  frame:SetSize(width, height)
  frame:ClearAllPoints()
  local anchor = settings.positionAnchor or {point = "CENTER", xOfs = 0, yOfs = 0}
  frame:SetPoint(anchor.point or "CENTER", UIParent, anchor.point or "CENTER",
    anchor.xOfs or 0, anchor.yOfs or 0)

  self.tabBar:SetSize(width, barHeight)
  self.tabBar:ClearAllPoints()
  self.tabBar:SetPoint("TOPLEFT", frame, "TOPLEFT")
  self:UpdateTabBackground()
  self.tab:SetHeight(barHeight)
  self.tab.label:SetFontObject(self.fonts.tab)
  local padding = Utils.getTabXPadding(settings)
  self.tab.label:ClearAllPoints()
  self.tab.label:SetWidth(0)
  self.tab:SetWidth(math.min(width, self.tab.label:GetStringWidth() + 2 * padding))
  self.tab.label:SetPoint("LEFT", self.tab, "LEFT", padding, 0)
  self.tab.label:SetPoint("RIGHT", self.tab, "RIGHT", -padding, 0)
  self.tab.label:SetWordWrap(false)
  self.frame:SetResizeBounds(100, minHeight)
  self:UpdateVisibility()
end

function ExtraWindow:HideInactiveTab()
  if self.hovered or self.unlocked then return end
  if self.settings.chatShowOnMouseOver then
    self.tabBar:HideDelay(self.settings.chatHoldTime)
  else
    self.tabBar:Hide()
  end
end

function ExtraWindow:IsActive()
  return self.enabled and MessageRouter:HasSource(self.renderer)
end

function ExtraWindow:UpdateVisibility()
  local active = self:IsActive()
  if not active and self.hovered then
    self.hovered = false
    self:Dispatch(events.MOUSE_LEAVE)
  end
  self.frame:SetShown(active or self.unlocked)
  self.renderer:SetShown(active)
  self.tab:SetShown(self.source ~= nil and self.settings.showTabBar == true)
  if self.settings.showTabBar and self.source and active then
    if self.unlocked or self.hovered then self.tabBar:Show() else self:HideInactiveTab() end
  else
    self.tabBar:QuickHide()
  end
  self.mover:SetShown(self.unlocked)
  self.mover:EnableMouse(self.unlocked)
  self.mover:SetMovable(self.unlocked)
  local sourceName = self.source and (self.source.name or "Source") or "Unavailable"
  self.mover.label:SetText((self.settings.name or tostring(self.id)) .. " — " .. sourceName)
end

function ExtraWindow:UpdateSettings(settings, key)
  if backgroundSettings[key] or key == "messageTopFade" or key == "messageBottomFade" then
    self.settings = settings
    if backgroundSettings[key] then self:UpdateTabBackground() end
    self:Dispatch(events.UPDATE_CONFIG, key)
    return
  end
  local wasEnabled = self.enabled
  local iconChanged = self.iconTextureYOffset ~= settings.iconTextureYOffset
  self.enabled = settings.enabled ~= false
  self.iconTextureYOffset = settings.iconTextureYOffset
  self.settings = settings
  if self.hovered and (not self.enabled or settings.nonInteractive or not settings.hoverEnabled) then
    self.hovered = false
    self:Dispatch(events.MOUSE_LEAVE)
  end
  self.fonts = Core:GetModule("Fonts"):CreateWindowFonts(self.id, settings)
  self:UpdateLayout()
  self:Dispatch(events.UPDATE_CONFIG, iconChanged and "iconTextureYOffset" or key or "window")
  if self.enabled ~= wasEnabled then self:UpdateMessageSource() end
end

function ExtraWindow:UpdateMessageSource()
  if self.enabled then
    MessageRouter:BindChat(self.renderer, self.source)
  else
    MessageRouter:Unbind(self.renderer)
    self.renderer:ReplaceMessages({})
  end
  self:UpdateVisibility()
end

function ExtraWindow:SetSource(chatFrame)
  local name = chatFrame and (chatFrame.name or "Chat") or ""
  if self.source == chatFrame and self.sourceName == name then return end
  local changed = self.source ~= chatFrame
  self.source, self.sourceName = chatFrame, name
  self.tab.label:SetText(name)
  if changed then self:UpdateMessageSource() end
  self:UpdateLayout()
end

function ExtraWindow:OnFrame()
  if self.released then return end
  if self:IsActive() then self.renderer:OnFrame() end
  if self.unlocked then
    local width, height = self.frame:GetSize()
    if width ~= self.settings.frameWidth or height ~= self.settings.frameHeight then
      self.settings.frameWidth, self.settings.frameHeight = width, height
      self.renderer:RefreshSettings()
      self.tabBar:SetWidth(width)
    end
  end
  local hovered = not self.unlocked and self:IsActive()
    and self.settings.nonInteractive ~= true and self.settings.hoverEnabled ~= false and self.frame:IsMouseOver()
  if hovered ~= self.hovered then
    self.hovered = hovered
    self:Dispatch(hovered and events.MOUSE_ENTER or events.MOUSE_LEAVE)
    if hovered then
      if self.settings.showTabBar then self.tabBar:Show() end
    else
      self:HideInactiveTab()
    end
  end
end

function ExtraWindow:SaveGeometry()
  local point, _, _, x, y = self.frame:GetPoint(1)
  self.settings.positionAnchor = {point = point, xOfs = x, yOfs = y}
  self.settings.frameWidth = math.floor(self.frame:GetWidth() + 0.5)
  self.settings.frameHeight = math.floor(self.frame:GetHeight() + 0.5)
  local module = Core:GetModule("ExtraWindows", true)
  if module then module:UpdateWindowSettings(self.id, "framePosition") end
end

function ExtraWindow:SetUnlocked(unlocked)
  if self.released then return end
  if self.unlocked == unlocked then return end
  self.unlocked = unlocked
  if not unlocked then
    self.frame:StopMovingOrSizing()
    self.frame:SetMovable(false)
    self:SaveGeometry()
  end
  if unlocked and self.hovered then
    self.hovered = false
    self:Dispatch(events.MOUSE_LEAVE)
  end
  self:Dispatch(unlocked and events.UNLOCK_MOVER or events.LOCK_MOVER)
  self:UpdateVisibility()
  if not unlocked then self:HideInactiveTab() end
end

function ExtraWindow:InstallMoverScripts()
  self.mover:SetScript("OnDragStart", function ()
    self.frame:SetMovable(true)
    self.frame:StartMoving()
  end)
  self.mover:SetScript("OnDragStop", function ()
    self.frame:StopMovingOrSizing()
    self.frame:SetMovable(false)
    self:SaveGeometry()
  end)
  self.resizeHandle:SetScript("OnMouseDown", function (_, button)
    if button == "LeftButton" then self.frame:StartSizing("BOTTOMRIGHT") end
  end)
  self.resizeHandle:SetScript("OnMouseUp", function (_, button)
    if button == "LeftButton" then
      self.frame:StopMovingOrSizing()
      self:SaveGeometry()
    end
  end)
end

function ExtraWindow:Release()
  if self.released then return end
  self.released = true
  self.frame:StopMovingOrSizing()
  self.frame:SetMovable(false)
  self.mover:SetScript("OnDragStart", nil)
  self.mover:SetScript("OnDragStop", nil)
  self.resizeHandle:SetScript("OnMouseDown", nil)
  self.resizeHandle:SetScript("OnMouseUp", nil)
  self.listeners = {}
  self.renderer:Dispose()
  self.tabBar:QuickHide()
  self.mover:Hide()
  self.frame:Hide()
  windows[self.id] = nil
  pool[#pool + 1] = self
end

Core.Components.CreateExtraWindow = function (id, settings)
  assert(not windows[id], "Extra window already exists: " .. tostring(id))
  local self = table.remove(pool)
  if self then
    self.id, self.settings, self.listeners = id, settings, {}
    self.hovered, self.unlocked, self.source, self.released = false, false, nil, false
    self.enabled, self.iconTextureYOffset = settings.enabled ~= false, settings.iconTextureYOffset
    self.fonts = Core:GetModule("Fonts"):CreateWindowFonts(id, settings)
    self.tab.label:SetFontObject(self.fonts.tab)
    self.renderer:Init(nil, self)
    self:InstallMoverScripts()
    self.tab.label:SetText("")
    windows[id] = self
    self:UpdateLayout()
    self.renderer:RefreshSettings()
    self:UpdateMessageSource()
    return self
  end
  self = setmetatable({id = id, settings = settings, listeners = {}, hovered = false, unlocked = false}, ExtraWindow)
  self.enabled, self.iconTextureYOffset = settings.enabled ~= false, settings.iconTextureYOffset
  local gradient = Core.Components.GradientBackgroundMixin
  local fading = Core.Components.FadingFrameMixin
  self.frame = CreateFrame("Frame", nil, UIParent)
  self.frame:EnableMouse(false)
  self.fonts = Core:GetModule("Fonts"):CreateWindowFonts(id, settings)
  self.tabBar = Mixin(CreateFrame("Frame", nil, self.frame), fading, gradient)
  fading.Init(self.tabBar)
  gradient.Init(self.tabBar)
  self.tabBar:SetFadeInDuration(0.6)
  self.tabBar:SetFadeOutDuration(0.6)
  self.tab = CreateFrame("Frame", nil, self.tabBar)
  self.tab:SetPoint("LEFT")
  self.tab.label = self.tab:CreateFontString(nil, "OVERLAY")
  self.tab.label:SetFontObject(self.fonts.tab)
  self.tab.label:SetJustifyH("LEFT")
  self.tab.label:SetTextColor(colors.apache.r, colors.apache.g, colors.apache.b)
  self.tab.label:SetText("")
  self.tabBar:EnableMouse(false)
  self.tab:EnableMouse(false)
  self.renderer = Core.Components.CreateSlidingMessageFrame(nil, self.frame)
  self.renderer:Init(nil, self)

  self.mover = CreateFrame("Frame", nil, self.frame)
  self.mover:SetAllPoints()
  self.mover:SetFrameLevel(self.renderer:GetFrameLevel() + 10)
  self.frame:SetResizable(true)
  self.mover.bg = self.mover:CreateTexture(nil, "BACKGROUND")
  self.mover.bg:SetAllPoints()
  self.mover.bg:SetColorTexture(0, 1, 0, 0.35)
  self.mover.label = self.mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self.mover.label:SetPoint("CENTER")
  self.mover:RegisterForDrag("LeftButton")

  self.resizeHandle = CreateFrame("Button", nil, self.mover)
  self.resizeHandle:SetSize(20, 20)
  self.resizeHandle:SetPoint("BOTTOMRIGHT")
  self.resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  self.resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  self:InstallMoverScripts()
  windows[id] = self
  self:UpdateLayout()
  self.renderer:RefreshSettings()
  self:UpdateMessageSource()
  return self
end
