local Core, Constants, Utils = unpack(select(2, ...))
local C = Core:GetModule("Config")
local Formatting = Core:GetModule("MessageFormatting")
local Dialog = Core.Libs.AceConfigDialog

local function nativeColor(chatType, channelNumber)
  local colors = _G.ChatTypeInfo
  if not Utils.canAccessValue(colors) or type(colors) ~= "table" then return { r = 1, g = 1, b = 1 } end
  local color = colors[chatType == "CHANNEL" and channelNumber and ("CHANNEL" .. channelNumber) or chatType]
  if Utils.canAccessValue(color) and type(color) == "table" then
    local copy = {}
    for _, key in ipairs({ "r", "g", "b" }) do
      local value = color[key]
      if not Utils.canAccessValue(value) or type(value) ~= "number"
        or value ~= value or value < 0 or value > 1 then return { r = 1, g = 1, b = 1 } end
      copy[key] = value
    end
    return copy
  end
  return { r = 1, g = 1, b = 1 }
end

local function backgroundDefault(chatType, channelNumber)
  local base = Constants.COLORS.codGray
  local native = nativeColor(chatType, channelNumber)
  return { r = base.r * 0.9 + native.r * 0.1,
    g = base.g * 0.9 + native.g * 0.1,
    b = base.b * 0.9 + native.b * 0.1,
    a = Core.db.profile.chatBackgroundOpacity }
end

local function timestampOptions()
  local function disabled() return not Formatting:GetSettings().timestamps.enabled end
  return { name = "Timestamps", type = "group", inline = true, order = 1, args = {
    description = { type = "description", order = 0,
      name = "Show the time when a message was received. Native WoW timestamps are hidden." },
    enabled = { name = "Enabled", type = "toggle", order = 1,
      get = function() return Formatting:GetSettings().timestamps.enabled end,
      set = function(_, value) Formatting:SetTimestampValue("enabled", value) end },
    preset = { name = "Format", type = "select", order = 2, disabled = disabled,
      values = { ["24h"] = "24-hour (13:05)", ["24h-seconds"] = "24-hour with seconds (13:05:09)",
        ["12h"] = "12-hour (1:05 PM)", ["12h-seconds"] = "12-hour with seconds (1:05:09 PM)" },
      get = function() return Formatting:GetSettings().timestamps.preset end,
      set = function(_, value) Formatting:SetTimestampValue("preset", value) end },
    color = { name = "Timestamp color", type = "color", dialogControl = "GlassColorPicker",
      hasAlpha = false, order = 3, disabled = disabled,
      get = function()
        local color = Formatting:GetSettings().timestamps.color
        return color.r, color.g, color.b
      end,
      set = function(_, r, g, b) Formatting:SetTimestampValue("color", { r = r, g = g, b = b }) end },
  } }
end

local function playerOptions()
  return { name = "Player names", type = "group", inline = true, order = 2, args = {
    description = { type = "description", order = 0,
      name = "Icons appear when character information is available." },
    raceIcon = { name = "Race icon", type = "toggle", order = 1,
      get = function() return Formatting:GetPlayerSettings().raceIcon end,
      set = function(_, value) Formatting:SetPlayerValue("raceIcon", value) end },
    classIcon = { name = "Class icon", type = "toggle", order = 2,
      get = function() return Formatting:GetPlayerSettings().classIcon end,
      set = function(_, value) Formatting:SetPlayerValue("classIcon", value) end },
    classColor = { name = "Class-colored names", type = "toggle", order = 3,
      get = function() return Formatting:GetPlayerSettings().classColor end,
      set = function(_, value) Formatting:SetPlayerValue("classColor", value) end },
  } }
end

local function typeOptions(descriptor, order)
  local chatType, channelNumber = descriptor.chatType, descriptor.channelNumber
  local context = { chatType = chatType, channelKind = descriptor.channelKind, channelNumber = channelNumber }
  local page = { name = descriptor.name, type = "group", order = order, args = {} }
  if descriptor.key == "group:CHANNEL" and Utils.hasSecretValueAPI() then
    page.args.noticeLimit = { type = "description", width = "full", order = -1,
      name = "Some channel notices can’t be customized on this version of WoW." }
  end
  local function get(field)
    return Formatting:GetEntryValue(descriptor, field)
  end
  local function set(field, value)
    Formatting:SetEntryValue(descriptor, field, value)
  end
  local function fieldName(field, name)
    return function()
      local _, mixed = get(field)
      return mixed and (name .. " (mixed)") or name
    end
  end
  local function overrideEnabled(field)
    local value, mixed = get(field)
    if mixed then return nil end
    return value ~= nil
  end
  local function overrideDisabled(field)
    local value, mixed = get(field)
    return value == nil and not mixed
  end
  local function rgbOverride(parent, field, name, index)
    parent[field .. "Enabled"] = { name = "Override " .. name, type = "toggle", order = index,
      tristate = true,
      get = function() return overrideEnabled(field) end,
      set = function(_, enabled) set(field, enabled and nativeColor(chatType, channelNumber) or nil) end }
    parent[field] = { name = fieldName(field, name), type = "color", dialogControl = "GlassColorPicker",
      hasAlpha = false, order = index + 1,
      arg = #descriptor.members > 1 and { confirmOnly = true } or nil,
      disabled = function() return overrideDisabled(field) end,
      get = function()
        local color = get(field) or nativeColor(chatType, channelNumber)
        return color.r, color.g, color.b
      end,
      set = function(_, r, g, b) set(field, { r = r, g = g, b = b }) end }
  end
  page.args.mixed = { type = "description", order = 0,
    name = "Saved formatting differs within this group. Changes apply to all message types in the group.",
    hidden = function()
      for _, field in ipairs({ "aliasEnabled", "alias", "labelColor", "background", "textColor" }) do
        local _, mixed = get(field)
        if mixed then return false end
      end
      return true
    end }
  if descriptor.hasHeader then
    local header = { name = "Channel label", type = "group", inline = true, order = 1, args = {} }
    page.args.header = header
    header.args.enabled = { name = "Enable alias", type = "toggle", order = 1, tristate = true,
      get = function()
        local enabled, mixed = get("aliasEnabled")
        if mixed then return nil end
        return enabled ~= false
      end,
      set = function(_, value) set("aliasEnabled", value == true) end }
    header.args.alias = { name = fieldName("alias", "Alias"), type = "input", order = 2,
      desc = "Leave blank to preserve the original header. Default: " ..
        (Formatting:GetDefaultAlias(context)
          or (context.channelKind and "Current channel number" or "Original header")),
      disabled = function()
        local enabled, mixed = get("aliasEnabled")
        return enabled == false and not mixed
      end,
      get = function()
        local alias, mixed = get("alias")
        return not mixed and alias or ""
      end,
      set = function(_, value) set("alias", value) end }
    rgbOverride(header.args, "labelColor", "Label color", 3)
  end
  local style = { name = "Message style", type = "group", inline = true, order = 2, args = {} }
  page.args.style = style
  style.args.backgroundEnabled = { name = "Override background", type = "toggle", order = 1,
    tristate = true,
    get = function() return overrideEnabled("background") end,
    set = function(_, enabled)
      set("background", enabled and backgroundDefault(chatType, channelNumber) or nil)
    end }
  style.args.background = { name = fieldName("background", "Background color"),
    type = "color", dialogControl = "GlassColorPicker", hasAlpha = true, order = 2,
    arg = #descriptor.members > 1 and { confirmOnly = true } or nil,
    disabled = function() return overrideDisabled("background") end,
    get = function()
      local color = get("background") or backgroundDefault(chatType, channelNumber)
      return color.r, color.g, color.b, color.a
    end,
    set = function(_, r, g, b, a) set("background", { r = r, g = g, b = b, a = a }) end }
  rgbOverride(style.args, "textColor", "Body color", 3)
  page.args.reset = { name = "Reset to defaults", type = "execute", order = 3,
    confirm = true, confirmText = "Reset all formatting overrides for this message group?",
    func = function()
      Formatting:ResetEntry(descriptor)
      C:RefreshMessageFormattingOptions()
    end }
  return page
end

function C:BuildChatOptions()
  return { name = "Chat options", type = "group", order = 3,
    args = { timestamps = timestampOptions(), players = playerOptions() } }
end

function C:BuildMessageFormattingOptions()
  local group = { name = "Message formatting", type = "group", order = 4, childGroups = "tree", args = {} }
  for index, category in ipairs(Formatting:GetCategories()) do
    local options = { name = category.name, type = "group", order = index, childGroups = "tree", args = {} }
    for entryIndex, descriptor in ipairs(category.entries) do
      options.args[descriptor.key] = typeOptions(descriptor, entryIndex)
    end
    group.args[category.key] = options
  end
  return group
end

function C:RefreshMessageFormattingOptions()
  if not self.options then return end
  local group = self:BuildMessageFormattingOptions()
  self.options.args.messageFormatting = group
  local root = Dialog:GetStatusTable("Glass", {}).groups
  local nested = Dialog:GetStatusTable("Glass", { "messageFormatting" }).groups
  local function validSelection(selected, options)
    if type(selected) ~= "string" then return true end
    for key in selected:gmatch("[^\001]+") do
      options = options.args and options.args[key]
      if not options then return false end
    end
    return true
  end
  local selected = root and root.selected
  local formattingSelected = type(selected) == "string"
    and (selected == "messageFormatting" or selected:match("^messageFormatting\001"))
  if formattingSelected and (not validSelection(selected, self.options)
    or (selected == "messageFormatting" and not validSelection(nested and nested.selected, group))) then
    Dialog:SelectGroup("Glass", "messageFormatting")
  else
    _G.LibStub("AceConfigRegistry-3.0"):NotifyChange("Glass")
  end
end
