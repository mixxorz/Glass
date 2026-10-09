local Core, Constants = unpack(select(2, ...))
local ExtraWindows = Core:GetModule("ExtraWindows")
local E = Constants.EVENTS

local function copy(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for key, item in pairs(value) do result[key] = copy(item) end
  return result
end

local function profileName()
  return Core.db:GetCurrentProfile()
end

function ExtraWindows:OnInitialize()
  self.views = {}
  self.liveBindings = {}
  self.unlocked = false
  self.started = false
  self.sourceNames = {}
end

function ExtraWindows:GetWindows()
  return Core.db.profile.extraWindows
end

function ExtraWindows:GetBindings()
  local sources = Core.db.char.extraWindowSources
  local name = profileName()
  sources[name] = sources[name] or {}
  return sources[name]
end

function ExtraWindows:GetSources()
  local sources = {}
  local function add(frame)
    if not frame or frame == _G.ChatFrame2 then return end
    if _G.IsCombatLog and _G.IsCombatLog(frame) then return end
    local name, active
    if frame.isTemporary then
      name, active = frame.name, frame.inUse
    else
      local savedName, _, _, _, _, _, shown, _, docked = _G.GetChatWindowInfo(frame:GetID())
      -- A docked tab remains a source when it isn't selected or marked as shown.
      active = (shown and shown ~= 0) or (docked and docked ~= 0) or frame.isDocked
      -- Saved names are available before Blizzard finishes initializing each frame on reload.
      name = savedName and savedName ~= "" and savedName or frame.name
    end
    if name and name ~= "" and active and active ~= 0 then sources[frame:GetName()] = name end
  end
  for i = 1, _G.NUM_CHAT_WINDOWS do add(_G["ChatFrame" .. i]) end
  for _, name in ipairs(_G.CHAT_FRAMES or {}) do add(_G[name]) end
  local ui = Core:GetModule("UIManager")
  for name in pairs(ui.state and ui.state.temporaryFrames or {}) do add(_G[name]) end
  return sources
end

function ExtraWindows:ResolveSource(id, sources)
  local binding = self:GetBindings()[id]
  if not binding or binding.missing then return nil end
  sources = sources or self:GetSources()
  if sources[binding.frame] ~= binding.name then return nil end
  local frame = _G[binding.frame]
  if binding.temporary then
    local live = self.liveBindings[profileName()]
    if not live or live[id] ~= frame then return nil end
  end
  return frame
end

function ExtraWindows:GetSource(id)
  local frame = self:ResolveSource(id)
  return frame and frame:GetName() or ""
end

function ExtraWindows:SetSource(id, sourceName)
  if not self:GetWindows()[id] then return end
  local name = self:GetSources()[sourceName]
  if not name then return end
  local frame = _G[sourceName]
  self:GetBindings()[id] = { frame = sourceName, name = name, temporary = frame.isTemporary or false }
  local key = profileName()
  self.liveBindings[key] = self.liveBindings[key] or {}
  self.liveBindings[key][id] = frame
  self:UpdateWindow(id)
end

function ExtraWindows:AddWindow(sourceName)
  local source = self:GetSources()[sourceName]
  if not source then return nil end
  Core.db.global.extraWindowSerial = (Core.db.global.extraWindowSerial or 0) + 1
  local id = tostring(Core.db.global.extraWindowSerial)
  local settings = {}
  for key, value in pairs(Core.db.profile) do
    if type(value) ~= "table" then settings[key] = value end
  end
  -- AceDB fills defaults lazily; copy their effective values, not just saved overrides.
  for key in pairs(Core.defaults.profile) do
    if key ~= "extraWindows" and key ~= "editBoxAnchor" then settings[key] = copy(Core.db.profile[key]) end
  end
  settings.positionAnchor = copy(Core.db.profile.positionAnchor)
  settings.positionAnchor.xOfs = settings.positionAnchor.xOfs + 40
  settings.positionAnchor.yOfs = settings.positionAnchor.yOfs + 40
  settings.name = source
  settings.enabled = true
  settings.showTabBar = false
  settings.hoverEnabled, settings.scrollEnabled, settings.linksEnabled = true, true, true
  settings.nonInteractive = false
  settings.tabFont = Core.db.profile.tabFont or settings.font
  settings.tabFontFlags = Core.db.profile.tabFontFlags or settings.fontFlags
  settings.tabXPadding = Core.db.profile.tabXPadding
  settings.tabLeftGradientWidth = Core.db.profile.tabLeftGradientWidth
  settings.tabRightGradientWidth = Core.db.profile.tabRightGradientWidth
  self:GetWindows()[id] = settings
  self:SetSource(id, sourceName)
  Core:Dispatch(Constants.ACTIONS.UnlockMover())
  Core:GetModule("Config"):OpenWindow(id)
  return id
end

function ExtraWindows:DeleteWindow(id)
  if self.views[id] then self.views[id]:Release(); self.views[id] = nil end
  self:GetWindows()[id] = nil
  self:GetBindings()[id] = nil
  local live = self.liveBindings[profileName()]
  if live then live[id] = nil end
  Core:GetModule("Config"):RefreshOptions()
end

function ExtraWindows:UpdateWindowSettings(id, key)
  local settings = self:GetWindows()[id]
  if not settings then return end
  local view = self.views[id]
  if view then view:UpdateSettings(settings, key) end
  if key == "name" or key == "showTabBar" or key == "tabFontSize" or key == "tabYPadding" then
    Core:GetModule("Config"):UpdateWindowOptions(id)
  end
end

function ExtraWindows:UpdateWindow(id)
  if not self.started then return end
  local settings = self:GetWindows()[id]
  if not settings then return end
  local view = self.views[id]
  if not view then
    view = Core.Components.CreateExtraWindow(id, settings)
    self.views[id] = view
  else
    view:UpdateSettings(settings)
  end
  view:SetSource(self:ResolveSource(id))
  view:SetUnlocked(self.unlocked)
  Core:GetModule("Config"):RefreshOptions()
end

function ExtraWindows:Rebuild()
  if not self.started then return end
  for _, view in pairs(self.views) do view:Release() end
  self.views = {}
  for id in pairs(self:GetWindows()) do self:UpdateWindow(id) end
end

function ExtraWindows:RefreshSources()
  if not self.started then return end
  local sources = self:GetSources()
  local changed = false
  for frame, name in pairs(sources) do
    if self.sourceNames[frame] ~= name then changed = true end
  end
  for frame in pairs(self.sourceNames) do
    if not sources[frame] then changed = true end
  end
  for _, bindings in pairs(Core.db.char.extraWindowSources) do
    for _, binding in pairs(bindings) do
      local previous = self.sourceNames[binding.frame]
      if not binding.missing and previous and sources[binding.frame] and binding.name == previous then
        binding.name = sources[binding.frame]
      end
    end
  end
  self.sourceNames = sources
  for id, view in pairs(self.views) do
    local source = self:ResolveSource(id, sources)
    if view.source ~= source then changed = true end
    view:SetSource(source)
  end
  if changed then Core:GetModule("Config"):RefreshOptions() end
end

function ExtraWindows:SourceClosed(frame)
  -- Chat frame objects are recycled. Keep closed sources unbound even if their slot is reused.
  for _, bindings in pairs(Core.db.char.extraWindowSources) do
    for _, binding in pairs(bindings) do
      if binding.frame == frame:GetName() then binding.missing = true end
    end
  end
  for _, view in pairs(self.views) do
    if view.source == frame then view:SetSource(nil) end
  end
  Core:GetModule("Config"):RefreshOptions()
end

function ExtraWindows:RefreshVisibility()
  for _, view in pairs(self.views) do view:UpdateVisibility() end
end

function ExtraWindows:OnFrame()
  for _, view in pairs(self.views) do view:OnFrame() end
end

function ExtraWindows:Start()
  if self.started then return end
  self.started = true
  self.sourceNames = self:GetSources()
  self.sourceEvents = _G.CreateFrame("Frame")
  self.sourceEvents:RegisterEvent("UPDATE_CHAT_WINDOWS")
  self.sourceEvents:RegisterEvent("UPDATE_FLOATING_CHAT_WINDOWS")
  self.sourceEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
  self.sourceEvents:SetScript("OnEvent", function ()
    if self.sourceRefreshPending then return end
    self.sourceRefreshPending = true
    _G.C_Timer.After(0, function ()
      self.sourceRefreshPending = false
      self:RefreshSources()
    end)
  end)
  Core:Subscribe(E.UNLOCK_MOVER, function ()
    self.unlocked = true
    for _, view in pairs(self.views) do view:SetUnlocked(true) end
  end)
  Core:Subscribe(E.LOCK_MOVER, function ()
    self.unlocked = false
    for _, view in pairs(self.views) do view:SetUnlocked(false) end
  end)
  self:Rebuild()
end
