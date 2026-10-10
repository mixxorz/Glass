local Core, Constants = unpack(select(2, ...))
local C = Core:GetModule("Config")
local Demo = Core:GetModule("Demo")
local Dialog = Core.Libs.AceConfigDialog
local DBOptions = Core.Libs.AceDBOptions
local LSM = Core.Libs.LSM
local Actions = Constants.ACTIONS
local ANCHORS = {
  TOPLEFT = "Top left", TOPRIGHT = "Top right",
  BOTTOMLEFT = "Bottom left", BOTTOMRIGHT = "Bottom right",
}
local FLAGS = { [""] = "None", OUTLINE = "Outline", ["OUTLINE, MONOCHROME"] = "Outline Monochrome" }

local SLIDER_BOUNDS = {
  frameWidth = {100, 1200}, frameHeight = {60, 600},
  xOfs = {-2000, 2000}, yOfs = {-1000, 1000}, editBoxAnchorYOfs = {-100, 100},
  messageFontSize = {8, 32}, tabFontSize = {8, 32}, editBoxFontSize = {8, 32},
  messageLinePadding = {0, 1}, tabYPadding = {0, 20}, tabSpacing = {0, 50},
  leftGradientWidth = {1, 300}, rightGradientWidth = {1, 300},
  tabLeftGradientWidth = {1, 300}, tabRightGradientWidth = {1, 300},
  messageHoldTime = {0, 60}, messageFadeInDuration = {0, 3}, messageFadeOutDuration = {0, 3},
  messageSlideInDuration = {0, 1},
  tabBarHoldTime = {0, 60}, tabBarFadeInDuration = {0, 3}, tabBarFadeOutDuration = {0, 3},
  editBoxFadeInDuration = {0, 3}, editBoxFadeOutDuration = {0, 3},
}

local function setSliderBounds(option, key)
  local bounds = SLIDER_BOUNDS[key]
  if not bounds then return end
  -- Limit dragging without discarding saved values or preventing precise manual entry.
  option.softMin = math.max(option.min or bounds[1], bounds[1])
  option.softMax = math.max(option.softMin, math.min(option.max or bounds[2], bounds[2]))
end

local function extra()
  return Core:GetModule("ExtraWindows")
end

local function initializeProfileSettings(profile)
  local function initialize(settings)
    for _, key in ipairs({"contentLeftPadding", "contentRightPadding", "tabXPadding", "editBoxXPadding",
      "messageTopFade", "messageBottomFade", "tabFont", "tabFontFlags",
      "tabLeftGradientWidth", "tabRightGradientWidth",
      "messageHoldTime", "messageFadeInDuration", "messageFadeOutDuration", "messageSlideInDuration",
      "tabBarHoldTime", "tabBarFadeInDuration", "tabBarFadeOutDuration"}) do
      if settings[key] == nil then settings[key] = Core.defaults.profile[key] end
    end
  end
  initialize(profile)
  for _, settings in pairs(profile.extraWindows) do initialize(settings) end
end

local function field(id, key, name, kind, order, min, max, step, values, event)
  local option = { name = name, type = kind, order = order, min = min, max = max, step = step, values = values }
  if kind == "range" then
    setSliderBounds(option, key)
    if key == "messageHoldTime" or key == "tabBarHoldTime" then
      option.desc = "Time to wait before fading out. Set this to 0 to start fading immediately."
    elseif key:match("Duration$") then
      option.desc = "Set this to 0 to skip the animation."
    end
  end
  if key == "font" or key == "tabFont" then
    option.dialogControl = "LSM30_Font"
    option.values = LSM:HashTable("font")
  end
  option.get = function()
    local settings = id and extra():GetWindows()[id] or Core.db.profile
    local value = settings[key]
    if value == nil then value = Core.defaults.profile[key] end
    return value
  end
  option.set = function(_, value)
    local settings = id and extra():GetWindows()[id] or Core.db.profile
    settings[key] = value
    if id then extra():UpdateWindowSettings(id, key)
    elseif event ~= false then Core:Dispatch(Actions.UpdateConfig(event or key)) end
  end
  return option
end

local function section(name, order)
  return { name = name, type = "group", order = order, args = {} }
end

local function inlineSection(parent, key, name, order)
  local group = section(name, order)
  group.inline = true
  parent.args[key] = group
  return group
end

local function editBoxOptions()
  local group = section("Edit box", 2)
  local text = inlineSection(group, "text", "Text", 1)
  local background = inlineSection(group, "background", "Background", 2)
  local layout = inlineSection(group, "layout", "Layout", 3)
  local transitions = inlineSection(group, "transitions", "Transitions", 4)
  transitions.args.editBoxFadeInDuration =
    field(nil, "editBoxFadeInDuration", "Fade in duration", "range", 1, 0, 30, 0.05)
  transitions.args.editBoxFadeOutDuration =
    field(nil, "editBoxFadeOutDuration", "Fade out duration", "range", 2, 0, 30, 0.05)
  local behavior = inlineSection(group, "behavior", "Behavior", 5)
  behavior.args.editBoxAltArrowKeyMode =
    field(nil, "editBoxAltArrowKeyMode", "Alt-arrow editing", "toggle", 1)
  behavior.args.editBoxAltArrowKeyMode.desc =
    "Require Alt for Left/Right arrow-key editing. Turn this off to move the cursor and select text without Alt. " ..
      "Chat history still uses Alt+Up/Down."
  text.args.editBoxFontSize = field(nil, "editBoxFontSize", "Font size", "range", 1, 1, 100, 1)
  background.args.editBoxBackgroundOpacity =
    field(nil, "editBoxBackgroundOpacity", "Background opacity", "range", 2, 0, 1, 0.01)
  layout.args.editBoxXPadding = field(nil, "editBoxXPadding", "Horizontal padding", "range", 1, 0, 100, 1)
  layout.args.editBoxXPadding.desc =
    "Adds space on both sides of the chat input, including before the channel or whisper label."
  layout.args.editBoxAnchorPosition = {
    name = "Position", type = "select", order = 3, values = { ABOVE = "Above", BELOW = "Below" },
    get = function() return Core.db.profile.editBoxAnchor.position end,
    set = function(_, v)
      Core.db.profile.editBoxAnchor.position = v
      Core.db.profile.editBoxAnchor.yOfs = v == "ABOVE" and 5 or -5
      Core:Dispatch(Actions.UpdateConfig("editBoxAnchor"))
    end }
  layout.args.editBoxAnchorYOfs = {
    name = "Vertical offset", type = "range", order = 4,
    min = -9999, max = 9999, step = 1,
    get = function() return Core.db.profile.editBoxAnchor.yOfs end,
    set = function(_, v)
      Core.db.profile.editBoxAnchor.yOfs = v
      Core:Dispatch(Actions.UpdateConfig("editBoxAnchor"))
    end }
  setSliderBounds(layout.args.editBoxAnchorYOfs, "editBoxAnchorYOfs")
  return group
end

local function windowOptions(id)
  local isExtra = id ~= nil
  local group = {
    name = isExtra and (extra():GetWindows()[id].name or tostring(id)) or "Main",
    type = "group", order = 1, childGroups = "tab", args = {},
  }
  local window = section("Window", 1)
  local messages = section("Messages", 2)
  local tabs = section("Tab bar", 3)
  local behavior = section("Behavior", 4)
  group.args.window = window
  group.args.messages = messages
  group.args.tabs = tabs
  group.args.behavior = behavior
  local size = inlineSection(window, "size", "Size", 2)
  local position = inlineSection(window, "position", "Position", 3)
  local function add(target, key, name, kind, order, min, max, step, values, event)
    target.args[key] = field(id, key, name, kind, order, min, max, step, values, event)
  end
  if isExtra then
    local general = inlineSection(window, "general", "General", 1)
    add(general, "name", "Name", "input", 1)
    add(general, "enabled", "Enabled", "toggle", 2)
    general.args.source = {
      name = "Source", type = "select", order = 3,
      desc =
        "Choose a source tab for this character. Its Glass window’s style and layout are saved with your profile.",
      values = function()
        local values = extra():GetSources()
        if extra():GetSource(id) == "" then values[""] = "Source tab unavailable" end
        return values
      end,
      get = function() return extra():GetSource(id) end,
      set = function(_, value) extra():SetSource(id, value) end,
    }
    local management = inlineSection(window, "management", "Window actions", 4)
    management.args.delete = {
      name = "Delete window", type = "execute", order = 20,
      confirm = true, confirmText = "Delete this window?",
      func = function()
        extra():DeleteWindow(id)
        C:RefreshOptions()
        Dialog:SelectGroup("Glass", "windows", "main")
      end,
    }
  end
  if isExtra then
    add(size, "frameWidth", "Width", "range", 4, 100, 9999, 1)
    add(size, "frameHeight", "Height", "range", 5, 40, 9999, 1)
    local settings = extra():GetWindows()[id]
    size.args.frameHeight.min = settings.showTabBar
      and math.max(40, settings.tabFontSize + settings.tabYPadding * 2 + 35) or 40
    setSliderBounds(size.args.frameHeight, "frameHeight")
    size.args.frameHeight.desc = "The window needs enough height to fit the tab bar and messages."
    local function positionField(key, name, kind, order, min, max, values)
      position.args[key] = {
        name = name, type = kind, order = order, min = min, max = max, step = kind == "range" and 1 or nil,
        values = values,
        get = function() return extra():GetWindows()[id].positionAnchor[key] end,
        set = function(_, value)
          extra():GetWindows()[id].positionAnchor[key] = value
          extra():UpdateWindowSettings(id, "framePosition")
        end,
      }
      if kind == "range" then setSliderBounds(position.args[key], key) end
    end
    positionField("point", "Anchor", "select", 6, nil, nil, ANCHORS)
    positionField("xOfs", "X offset", "range", 7, -9999, 9999)
    positionField("yOfs", "Y offset", "range", 8, -9999, 9999)
  else
    position.args.anchor = { name = "Anchor", type = "select", order = 6, values = ANCHORS,
      get = function() return Core.db.profile.positionAnchor.point end,
      set = function(_, v)
        Core.db.profile.positionAnchor.point = v
        Core:Dispatch(Actions.UpdateConfig("framePosition"))
      end }
    for _, spec in ipairs({ { "xOfs", "X offset", 7 }, { "yOfs", "Y offset", 8 } }) do
      local key = spec[1]
      position.args[key] = { name = spec[2], type = "range", order = spec[3], min = -9999, max = 9999, step = 1,
        get = function() return Core.db.profile.positionAnchor[key] end,
        set = function(_, v)
          Core.db.profile.positionAnchor[key] = v
          Core:Dispatch(Actions.UpdateConfig("framePosition"))
        end }
      setSliderBounds(position.args[key], key)
    end
    add(size, "frameWidth", "Width", "range", 4, 100, 9999, 1)
    add(size, "frameHeight", "Height", "range", 5, 1, 9999, 1)
  end
  local messageText = inlineSection(messages, "text", "Text", 1)
  local messageBackground = inlineSection(messages, "background", "Background", 2)
  local messageLayout = inlineSection(messages, "layout", "Layout", 3)
  add(messageText, "font", "Font", "select", 1)
  add(messageText, "fontFlags", "Font flags", "select", 2, nil, nil, nil, FLAGS, "font")
  add(messageText, "messageFontSize", "Font size", "range", 3, 1, 100, 1)
  add(messageText, "messageLeading", "Leading", "range", 4, 0, 10, 1)
  add(messageLayout, "messageLinePadding", "Line padding", "range", 5, 0, 5, 0.05)
  add(messageLayout, "contentLeftPadding", "Left padding", "range", 6, 0, 100, 1)
  add(messageLayout, "contentRightPadding", "Right padding", "range", 7, 0, 100, 1)
  add(messageLayout, "messageTopFade", "Top edge fade", "range", 8, 0, 40, 1)
  add(messageLayout, "messageBottomFade", "Bottom edge fade", "range", 9, 0, 40, 1)
  messageLayout.args.messageTopFade.desc =
    "Fade messages over this many pixels at the top of the pane. Set this to 0 to turn off the fade."
  messageLayout.args.messageBottomFade.desc =
    "Fade the bottom edge over this many pixels when you scroll up. Set this to 0 to turn off the fade."
  for _, key in ipairs({"messageTopFade", "messageBottomFade"}) do
    messageLayout.args[key].disabled = function()
      return not _G.UIParent.SetAlphaGradient or not _G.UIParent.SetFlattensRenderLayers or not _G.CreateVector2D
    end
  end
  add(messageText, "indentWordWrap", "Indent on line wrap", "toggle", 8)
  add(messageText, "iconTextureYOffset", "Text icons Y offset", "range", 9, 0, 12, 1)
  add(messageBackground, "chatBackgroundOpacity", "Background opacity", "range", 10, 0, 1, 0.01)
  add(messageBackground, "leftGradientWidth", "Left gradient width", "range", 11, 1, 9999, 1)
  add(messageBackground, "rightGradientWidth", "Right gradient width", "range", 12, 1, 9999, 1)
  local messageTransitions = inlineSection(messages, "transitions", "Transitions", 4)
  add(messageTransitions, "messageHoldTime", "Fade out delay", "range", 1, 0, 180, 1)
  add(messageTransitions, "messageFadeInDuration", "Fade in duration", "range", 2, 0, 30, 0.05)
  add(messageTransitions, "messageFadeOutDuration", "Fade out duration", "range", 3, 0, 30, 0.05)
  add(messageTransitions, "messageSlideInDuration", "Slide in duration", "range", 4, 0, 30, 0.05)

  if isExtra then add(tabs, "showTabBar", "Show tab bar", "toggle", 1) end
  local tabText = inlineSection(tabs, "text", "Text", 2)
  local tabBackground = inlineSection(tabs, "background", "Background", 3)
  local tabLayout = inlineSection(tabs, "layout", "Layout", 4)
  add(tabText, "tabFont", "Font", "select", 2)
  add(tabText, "tabFontSize", "Font size", "range", 3, 1, 100, 1)
  add(tabText, "tabFontFlags", "Font flags", "select", 4, nil, nil, nil, FLAGS)
  add(tabLayout, "tabXPadding", "Horizontal padding", "range", 5, 0, 100, 1)
  tabLayout.args.tabXPadding.desc = "Padding at the left and right edges of the tab bar."
  add(tabLayout, "tabYPadding", "Vertical padding", "range", 6, 0, 100, 1)
  add(tabBackground, "tabBarBackgroundOpacity", "Background opacity", "range", 7, 0, 1, 0.01)
  add(tabBackground, "tabLeftGradientWidth", "Left gradient width", "range", 8, 1, 9999, 1)
  add(tabBackground, "tabRightGradientWidth", "Right gradient width", "range", 9, 1, 9999, 1)
  local tabTransitions = inlineSection(tabs, "transitions", "Transitions", 5)
  add(tabTransitions, "tabBarHoldTime", "Fade out delay", "range", 1, 0, 180, 1)
  add(tabTransitions, "tabBarFadeInDuration", "Fade in duration", "range", 2, 0, 30, 0.05)
  add(tabTransitions, "tabBarFadeOutDuration", "Fade out duration", "range", 3, 0, 30, 0.05)
  if not isExtra then
    add(tabLayout, "tabSpacing", "Tab spacing", "range", 10, 0, 100, 1)
    tabLayout.args.tabSpacing.desc = "The space between tab labels. Set this to 0 to place them next to each other."
    local buttons = inlineSection(tabs, "buttons", "Buttons", 6)
    add(buttons, "showChatMenuButton", "Show chat menu button", "toggle", 1)
    add(buttons, "showChatChannelButton", "Show chat channels button", "toggle", 2)
    add(buttons, "showSocialButton", "Show social button", "toggle", 3)
    buttons.args.showSocialButton.desc =
      "Show Blizzard's Friends and Quick Join widget. Move it independently with /glass lock."
    buttons.args.showChatMenuButton.disabled = function() return not _G.ChatFrameMenuButton end
    buttons.args.showChatChannelButton.disabled = function() return not _G.ChatFrameChannelButton end
    buttons.args.showSocialButton.disabled = function() return not _G.QuickJoinToastButton end
  end

  local interaction = inlineSection(behavior, "interaction", "Mouse interaction", 1)
  add(interaction, "chatShowOnMouseOver", "Show on mouse over", "toggle", 5, nil, nil, nil, nil, false)
  add(interaction, "mouseOverTooltips", "Mouse over tooltips", "toggle", 6)
  if isExtra then
    add(interaction, "nonInteractive", "Non-interactive", "toggle", 7)
    add(interaction, "hoverEnabled", "Hover enabled", "toggle", 8)
    add(interaction, "scrollEnabled", "Scrolling enabled", "toggle", 9)
    add(interaction, "linksEnabled", "Links enabled", "toggle", 10)
    interaction.args.hoverEnabled.desc = "Show faded messages and tooltips when hovering over the window."
    for _, key in ipairs({ "hoverEnabled", "scrollEnabled", "linksEnabled" }) do
      interaction.args[key].disabled = function() return extra():GetWindows()[id].nonInteractive end
    end
  end
  return group
end

local options

function C:UpdateWindowOptions(id)
  if not options or not options.args.windows then return end
  local entry = options.args.windows.args["extra_" .. tostring(id)]
  local settings = extra():GetWindows()[id]
  if not entry or not settings then return end
  -- Update metadata in place; AceConfig refreshes range controls after mouse-up.
  entry.name = settings.name or tostring(id)
  local height = entry.args.window.args.size.args.frameHeight
  height.min = settings.showTabBar
    and math.max(40, settings.tabFontSize + settings.tabYPadding * 2 + 35) or 40
  setSliderBounds(height, "frameHeight")
end

function C:RefreshOptions()
  if not options then return end
  local windows = {
    name = "Windows", type = "group", order = 1, childGroups = "tree", args = { main = windowOptions() },
  }
  local function unlock() Core:Dispatch(Actions.UnlockMover()) end
  windows.args.unlock = { name = "Unlock all windows", type = "execute", order = 0, func = unlock }
  local module = extra()
  if module then
    local ids = {}
    for id in pairs(module:GetWindows()) do ids[#ids + 1] = id end
    table.sort(ids, function(a, b) return tonumber(a) < tonumber(b) end)
    for i, id in ipairs(ids) do
      local entry = windowOptions(id)
      entry.order = i + 1
      windows.args["extra_" .. tostring(id)] = entry
    end
  end
  local source = ""
  windows.args.add = { name = "Add window", type = "group", order = 10000, args = {
    source = { name = "Source", type = "select", order = 1,
      values = function() return extra():GetSources() end,
      get = function() return source end,
      set = function(_, value) source = value end },
    create = { name = "Add", type = "execute", order = 2,
      disabled = function() return source == "" end,
      func = function() extra():AddWindow(source); source = "" end },
  } }
  options.args.windows = windows
  _G.LibStub("AceConfigRegistry-3.0"):NotifyChange("Glass")
end

function C:OpenWindow(id)
  self:RefreshOptions()
  Dialog:Open("Glass")
  Dialog:SelectGroup("Glass", "windows", "extra_" .. tostring(id))
end

local function homeOptions()
  local home = section("Home", 0)
  local info = inlineSection(home, "info", "Info", 1)
  info.args.version = {
    name = "|cFFDFBA69Glass|r\n|cffffd100Version:|r  " .. Core.Version,
    type = "description", width = "double", fontSize = "medium", order = 1,
    image = "Interface\\AddOns\\Glass\\Glass\\Assets\\icon.tga",
    imageWidth = 32, imageHeight = 32,
  }
  info.args.news = {
    name = "What’s New", type = "execute", order = 2,
    desc = "Read the latest Glass release notes.",
    func = function() Core:Dispatch(Actions.OpenNews()) end,
  }
  info.args.commands = {
    name = "|cFFDFBA69/glass|r  |cff808080...............|r  Open Home\n" ..
      "|cFFDFBA69/glass lock|r  |cff808080.......|r  Unlock all windows\n" ..
      "|cFFDFBA69/glass demo|r  |cff808080......|r  Toggle demo mode\n",
    type = "description", width = "double", order = 3,
  }
  info.args.unlock = {
    name = "Unlock", type = "execute", order = 4,
    desc = "Move and resize your Glass windows. Click Lock when you are finished.",
    func = function() Core:Dispatch(Actions.UnlockMover()) end,
  }
  home.args.demo = {
    name = "Demo mode", type = "toggle", order = 2, width = "full",
    desc = "Fill Glass windows with sample chat to preview styles, scrolling, and animations. " ..
      "Your chat input still sends real messages. Turn this off to return to real chat. " ..
      "Demo mode also ends when you reload or change profiles.",
    get = function() return Demo:IsActive() end,
    set = function(_, value) Demo:SetActive(value) end,
  }
  return home
end

function C:OnEnable()
  initializeProfileSettings(Core.db.profile)
  options = { name = "Glass", type = "group", handler = C, args = {
    home = homeOptions(),
    editBox = editBoxOptions(),
    profile = DBOptions:GetOptionsTable(Core.db),
  } }
  options.args.profile.name = "Profiles"
  options.args.profile.order = 3
  Core.Libs.AceConfig:RegisterOptionsTable("Glass", options)
  self:RefreshOptions()
  Dialog:SetDefaultSize("Glass", 780, 500)
  self:RegisterChatCommand("glass", "OnSlashCommand")
  Core.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
  Core.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
  Core.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
  Core:Subscribe(Constants.EVENTS.SAVE_FRAME_POSITION, function(position)
    Core.db.profile.positionAnchor = position
  end)
end

function C:OnSlashCommand(input)
  if input == "lock" or input == "unlock" then
    Core:Dispatch(Actions.UnlockMover())
  elseif input == "demo" then
    Demo:SetActive(not Demo:IsActive())
  else
    Dialog:SelectGroup("Glass", "home")
    Dialog:Open("Glass")
  end
end

function C:RefreshConfig()
  initializeProfileSettings(Core.db.profile)
  Demo:SetActive(false)
  for _, key in ipairs({ "font", "frameHeight", "frameWidth", "framePosition",
    "contentLeftPadding", "contentRightPadding", "leftGradientWidth", "rightGradientWidth",
    "tabBarBackgroundOpacity", "tabBarHoldTime", "tabBarFadeInDuration", "tabBarFadeOutDuration",
    "editBoxFontSize", "editBoxXPadding", "editBoxBackgroundOpacity", "editBoxAnchor", "editBoxAltArrowKeyMode",
    "editBoxFadeInDuration", "editBoxFadeOutDuration", "messageFontSize", "chatBackgroundOpacity",
    "messageHoldTime", "messageFadeInDuration", "messageFadeOutDuration", "messageSlideInDuration",
    "messageLeading", "messageLinePadding",
    "indentWordWrap", "iconTextureYOffset", "messageTopFade", "messageBottomFade",
    "mouseOverTooltips", "tabFont", "tabFontSize",
    "tabFontFlags", "tabXPadding", "tabYPadding",
    "tabLeftGradientWidth", "tabRightGradientWidth", "tabSpacing",
    "showChatMenuButton", "showChatChannelButton", "showSocialButton", "socialButtonPosition" }) do
    Core:Dispatch(Actions.UpdateConfig(key))
  end
  Core:Dispatch(Actions.RefreshConfig())
  local module = extra()
  if module then module:Rebuild() end
  self:RefreshOptions()
end
