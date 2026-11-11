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
  return { name = "Timestamps", type = "group", order = 0, args = {
    description = { type = "description", order = 0,
      name = "Show local time from original-arrival metadata when available. " ..
        "Native WoW timestamps are suppressed in Glass only; other chat displays are unchanged." },
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

local function typeOptions(descriptor, order)
  local identity, displayName, chatType = descriptor.key, descriptor.name, descriptor.chatType
  local context = { chatType = chatType, channelKind = descriptor.channelKind,
    channelNumber = descriptor.channelNumber }
  local page = { name = displayName, type = "group", order = order, args = {} }
  local function set(field, value)
    Formatting:SetRuleValue(identity, field, value, displayName)
    if value == nil then C:RefreshMessageFormattingOptions() end
  end
  local function rgbOverride(parent, field, name, index)
    parent[field .. "Enabled"] = { name = "Override " .. name, type = "toggle", order = index,
      get = function() return Formatting:GetRule(identity)[field] ~= nil end,
      set = function(_, enabled) set(field, enabled and nativeColor(chatType, context.channelNumber) or nil) end }
    parent[field] = { name = name, type = "color", dialogControl = "GlassColorPicker",
      hasAlpha = false, order = index + 1,
      disabled = function() return Formatting:GetRule(identity)[field] == nil end,
      get = function()
        local color = Formatting:GetRule(identity)[field] or nativeColor(chatType, context.channelNumber)
        return color.r, color.g, color.b
      end,
      set = function(_, r, g, b) set(field, { r = r, g = g, b = b }) end }
  end
  if descriptor.available == false then
    page.args.availability = { type = "description", order = 0,
      name = "This channel is currently unavailable. Saved settings remain editable and apply when it returns." }
  end
  if descriptor.hasHeader then
    local header = { name = "Channel label", type = "group", inline = true, order = 1, args = {} }
    page.args.header = header
    header.args.enabled = { name = "Enable alias", type = "toggle", order = 1,
      get = function() return Formatting:GetRule(identity).aliasEnabled ~= false end,
      set = function(_, value) set("aliasEnabled", value) end }
    header.args.alias = { name = "Alias", type = "input", order = 2,
      desc = "Leave blank to preserve the original header. Default: " ..
        (Formatting:GetDefaultAlias(context)
          or (context.channelKind and "Current channel number" or "Original header")),
      disabled = function() return Formatting:GetRule(identity).aliasEnabled == false end,
      get = function()
        local alias = Formatting:GetRule(identity).alias
        if alias ~= nil then return alias end
        return Formatting:GetDefaultAlias(context) or ""
      end,
      set = function(_, value) set("alias", value) end }
    rgbOverride(header.args, "labelColor", "Label color", 3)
  end
  local style = { name = "Message style", type = "group", inline = true, order = 2, args = {} }
  page.args.style = style
  style.args.backgroundEnabled = { name = "Override background", type = "toggle", order = 1,
    get = function() return Formatting:GetRule(identity).background ~= nil end,
    set = function(_, enabled)
      set("background", enabled and backgroundDefault(chatType, context.channelNumber) or nil)
    end }
  style.args.background = { name = "Background color", type = "color", dialogControl = "GlassColorPicker",
    hasAlpha = true, order = 2,
    disabled = function() return Formatting:GetRule(identity).background == nil end,
    get = function()
      local color = Formatting:GetRule(identity).background or backgroundDefault(chatType, context.channelNumber)
      return color.r, color.g, color.b, color.a
    end,
    set = function(_, r, g, b, a)
      Formatting:SetRuleValue(identity, "background", { r = r, g = g, b = b, a = a }, displayName)
    end }
  rgbOverride(style.args, "textColor", "Body color", 3)
  page.args.reset = { name = "Reset to defaults", type = "execute", order = 3,
    confirm = true, confirmText = "Reset all formatting overrides for this type or channel?",
    func = function()
      Formatting:ResetRule(identity)
      C:RefreshMessageFormattingOptions()
    end }
  return page
end

function C:BuildMessageFormattingOptions()
  local group = { name = "Message formatting", type = "group", order = 3, childGroups = "tree",
    args = { timestamps = timestampOptions() } }
  for index, descriptor in ipairs(Formatting:GetEntries()) do
    group.args[descriptor.key] = typeOptions(descriptor, index)
  end
  return group
end

function C:RefreshMessageFormattingOptions()
  if not self.options then return end
  local group = self:BuildMessageFormattingOptions()
  self.options.args.messageFormatting = group
  local root = Dialog:GetStatusTable("Glass", {}).groups
  local nested = Dialog:GetStatusTable("Glass", { "messageFormatting" }).groups
  local selected = root and root.selected
  local identity = selected and selected:match("^messageFormatting\001(.+)$")
  if (identity and not group.args[identity])
    or (selected == "messageFormatting" and nested and nested.selected and not group.args[nested.selected]) then
    Dialog:SelectGroup("Glass", "messageFormatting", "timestamps")
  else
    _G.LibStub("AceConfigRegistry-3.0"):NotifyChange("Glass")
  end
end
