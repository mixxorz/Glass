local Core, Constants, Utils = unpack(select(2, ...))
local F = Core:GetModule("MessageFormatting")

local DEFAULT_ALIASES = {
  PARTY = "P", PARTY_LEADER = "PL",
  RAID = "R", RAID_LEADER = "RL", RAID_WARNING = "RW",
  GUILD = "G", OFFICER = "O",
  INSTANCE_CHAT = "I", INSTANCE_CHAT_LEADER = "IL",
}
local COMMON_TYPES = {
  "SAY", "YELL", "WHISPER", "WHISPER_INFORM", "PARTY", "PARTY_LEADER",
  "RAID", "RAID_LEADER", "RAID_WARNING", "GUILD", "OFFICER",
  "INSTANCE_CHAT", "INSTANCE_CHAT_LEADER", "EMOTE", "SYSTEM",
}
local TYPE_NAMES = {
  WHISPER = "Whisper (receiving)",
  WHISPER_INFORM = "Whisper (sending)",
}
local PRESETS = { ["24h"] = true, ["24h-seconds"] = true, ["12h"] = true, ["12h-seconds"] = true }
local RULE_FIELDS = { aliasEnabled = true, alias = true, background = true, textColor = true, labelColor = true }
local DESCRIPTOR_FIELDS = {
  "key", "name", "chatType", "channelName", "channelNumber", "channelKind", "hasHeader", "available",
}
local channels = {}
local function public(value, kind)
  return Utils.canAccessValue(value) and type(value) == kind
end
local function text(value)
  return public(value, "string") and value ~= ""
end
local function container(value)
  if public(value, "table") then return value end
  return {}
end
local function readonly(value)
  return setmetatable({}, { __index = value, __newindex = function() error("Read-only formatting view", 2) end,
    __metatable = false })
end
local EMPTY = readonly({})
local function number(value)
  return public(value, "number") and value == value and value > -math.huge and value < math.huge
end
local function positiveInteger(value)
  return number(value) and value > 0 and value % 1 == 0
end
local function color(value, alpha)
  if not public(value, "table") then return nil end
  local result = {}
  for _, key in ipairs(alpha and { "r", "g", "b", "a" } or { "r", "g", "b" }) do
    local component = value[key]
    if not number(component) or component < 0 or component > 1 then return nil end
    result[key] = component
  end
  return result
end
local function validate(field, value)
  if field == "aliasEnabled" or field == "enabled" then
    if public(value, "boolean") then return value end
  elseif field == "alias" then
    if public(value, "string") then return value end
  elseif field == "preset" then
    if public(value, "string") and PRESETS[value] then return value end
  elseif field == "background" then
    return color(value, true)
  elseif field == "textColor" or field == "labelColor" or field == "color" then
    return color(value)
  end
end
local function equal(a, b)
  if not Utils.canAccessValue(a) or not Utils.canAccessValue(b) then return false end
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for _, key in ipairs({ "r", "g", "b", "a" }) do
    if not equal(a[key], b[key]) then return false end
  end
  return true
end
local function supported(chatType)
  return text(chatType) and chatType:match("^[A-Z_]+$") ~= nil
    and not chatType:match("^CHANNEL") and chatType ~= "ADDON" and chatType ~= "NONE"
    and public((_G.ChatTypeInfo or {})[chatType], "table")
end
local function validIdentity(identity)
  if not text(identity) then return false end
  if identity:match("^type:[A-Z_]+$") then return true end
  local id = identity:match("^channel:builtin:([1-9]%d*)$")
  if id then return positiveInteger(tonumber(id)) end
  local name = identity:match("^channel:custom:(.+)$")
  return name ~= nil and name == (_G.strlower or string.lower)(name)
end
local function savedSettings()
  return container(Core.db.profile.messageFormatting)
end
local function writableSettings()
  local profile = Core.db.profile
  if not public(profile.messageFormatting, "table") then profile.messageFormatting = {} end
  return profile.messageFormatting
end

function F:GetSettings()
  local saved = savedSettings()
  local stamps = container(saved.timestamps)
  local rules = {}
  for identity in pairs(container(saved.rules)) do
    if validIdentity(identity) then rules[identity] = self:GetRule(identity) end
  end
  local enabled = validate("enabled", stamps.enabled)
  return {
    timestamps = {
      enabled = enabled == true,
      preset = validate("preset", stamps.preset) or "24h",
      color = color(stamps.color) or { r = 128 / 255, g = 128 / 255, b = 128 / 255 },
    },
    rules = rules,
  }
end

function F:ResolveIdentity(chatType, zoneChannelID, channelName, channelKind)
  if not text(chatType) then return nil end
  if supported(chatType) then return "type:" .. chatType end
  if chatType ~= "CHANNEL" and not chatType:match("^CHANNEL%d+$") then return nil end
  if public(channelKind, "string") and channelKind == "builtin" and positiveInteger(zoneChannelID) then
    return "channel:builtin:" .. string.format("%.0f", zoneChannelID)
  end
  if public(channelKind, "string") and channelKind == "custom" and text(channelName) then
    return "channel:custom:" .. (_G.strlower or string.lower)(channelName)
  end
end

function F:GetRule(identity)
  if not validIdentity(identity) then return EMPTY end
  local saved = container(rawget(container(savedSettings().rules), identity))
  local result = {}
  local any = false
  for field in pairs(RULE_FIELDS) do
    local value = validate(field, saved[field])
    if value ~= nil then
      result[field] = type(value) == "table" and readonly(value) or value
      any = true
    end
  end
  if not any then return EMPTY end
  if text(saved.displayName) then result.displayName = saved.displayName end
  return readonly(result)
end

function F:GetDefaultAlias(context)
  if context.channelKind == "builtin" or context.channelKind == "custom" then
    if context.channelNumber then return tostring(context.channelNumber) end
    return nil
  end
  return DEFAULT_ALIASES[context.chatType]
end

function F:GetAlias(context)
  if not context or not context.identity then return nil end
  local rule = self:GetRule(context.identity)
  if rule.aliasEnabled == false then return nil end
  local alias = rule.alias
  if alias == nil then alias = self:GetDefaultAlias(context) end
  if alias == "" then return nil end
  return alias
end

function F:ResolveStyle(message, windowSettings)
  local rule = self:GetRule(message.identity)
  local background = rule.background
  return {
    textColor = rule.textColor or { r = message.r, g = message.g, b = message.b },
    backgroundColor = background or color(Constants.COLORS.codGray),
    backgroundOpacity = background and background.a or windowSettings.chatBackgroundOpacity,
  }
end

function F:SetTimestampValue(field, value)
  if not public(field, "string") then return end
  if field ~= "enabled" and field ~= "preset" and field ~= "color" then return end
  if not Utils.canAccessValue(value) then return end
  local accepted = validate(field, value)
  if value ~= nil and accepted == nil then return end
  local saved = container(savedSettings().timestamps)
  if equal(saved[field], accepted) then return end
  local settings = writableSettings()
  if not public(settings.timestamps, "table") then settings.timestamps = {} end
  settings.timestamps[field] = accepted
  self:NotifyChanged()
end

function F:SetRuleValue(identity, field, value, displayName)
  if not validIdentity(identity) or not public(field, "string") or not RULE_FIELDS[field]
    or not Utils.canAccessValue(value) then return end
  local accepted = validate(field, value)
  if value ~= nil and accepted == nil then return end
  local old = container(rawget(container(savedSettings().rules), identity))
  if equal(old[field], accepted) then return end
  local rule = {}
  local any = false
  for key in pairs(RULE_FIELDS) do
    rule[key] = validate(key, old[key])
    if key == field then rule[key] = accepted end
    if rule[key] ~= nil then any = true end
  end
  if any then
    if text(displayName) then rule.displayName = displayName
    elseif text(old.displayName) then rule.displayName = old.displayName end
  end
  local settings = writableSettings()
  if not public(settings.rules, "table") then settings.rules = {} end
  settings.rules[identity] = any and rule or nil
  self:NotifyChanged(identity, field)
end

function F:ResetRule(identity)
  if not validIdentity(identity) then return end
  local rules = container(savedSettings().rules)
  if not Utils.canAccessValue(rules[identity]) then return end
  if rules[identity] == nil then return end
  rules[identity] = nil
  self:NotifyChanged(identity)
end

function F:NotifyChanged(identity, field)
  local kind = "text"
  if public(field, "string") then
    if field == "background" then kind = "background"
    elseif field == "textColor" then kind = "body" end
  end
  Core:Dispatch(Constants.EVENTS.MESSAGE_FORMATTING_CHANGED, { identity = identity, kind = kind })
end

local function copyDescriptor(descriptor)
  local copy = {}
  for _, field in ipairs(DESCRIPTOR_FIELDS) do copy[field] = descriptor[field] end
  return copy
end
local function sortedChannels(snapshot)
  local result = {}
  for _, descriptor in pairs(snapshot) do result[#result + 1] = copyDescriptor(descriptor) end
  table.sort(result, function(a, b)
    if a.name == b.name then return a.key < b.key end
    return a.name < b.name
  end)
  return result
end

function F:ReplaceChannels(descriptors)
  local replacement = {}
  for _, descriptor in ipairs(container(descriptors)) do
    if public(descriptor, "table") and text(descriptor.name) and text(descriptor.key) then
      local key = self:ResolveIdentity("CHANNEL", nil, descriptor.channelName, descriptor.channelKind)
      if public(descriptor.channelKind, "string") and descriptor.channelKind == "builtin"
        and text(descriptor.key) and descriptor.key:match("^channel:builtin:")
        and validIdentity(descriptor.key) then key = descriptor.key end
      if key and key == descriptor.key then
        replacement[key] = {
          key = key, name = descriptor.name, chatType = "CHANNEL",
          channelName = text(descriptor.channelName) and descriptor.channelName or nil,
          channelNumber = positiveInteger(descriptor.channelNumber) and descriptor.channelNumber or nil,
          channelKind = descriptor.channelKind, hasHeader = true, available = true,
        }
      end
    end
  end
  local changed = false
  for key, descriptor in pairs(replacement) do
    local old = channels[key]
    if not old then changed = true else
      for _, field in ipairs(DESCRIPTOR_FIELDS) do
        if descriptor[field] ~= old[field] then changed = true end
      end
    end
  end
  for key in pairs(channels) do if not replacement[key] then changed = true end end
  channels = replacement
  if changed then Core:Dispatch(Constants.EVENTS.MESSAGE_CHANNELS_CHANGED) end
end

function F:GetEntries()
  local result, seen = {}, {}
  local function add(chatType)
    if supported(chatType) and not seen[chatType] then
      seen[chatType] = true
      result[#result + 1] = {
        key = "type:" .. chatType,
        name = TYPE_NAMES[chatType] or (text(_G[chatType]) and _G[chatType] or chatType),
        chatType = chatType, hasHeader = DEFAULT_ALIASES[chatType] ~= nil, available = true,
      }
    end
  end
  for _, chatType in ipairs(COMMON_TYPES) do add(chatType) end
  local remaining = {}
  for chatType in pairs(_G.ChatTypeInfo or {}) do
    if supported(chatType) and not seen[chatType] then remaining[#remaining + 1] = chatType end
  end
  table.sort(remaining)
  for _, chatType in ipairs(remaining) do add(chatType) end
  local snapshot = {}
  for key, descriptor in pairs(channels) do snapshot[key] = descriptor end
  for key in pairs(container(savedSettings().rules)) do
    if validIdentity(key) and key:match("^channel:") and not snapshot[key] then
      local rule = self:GetRule(key)
      if rule ~= EMPTY then
        snapshot[key] = {
          key = key, name = rule.displayName or key, chatType = "CHANNEL",
          channelKind = key:match("^channel:([^:]+):"), hasHeader = true, available = false,
        }
      end
    end
  end
  for _, descriptor in ipairs(sortedChannels(snapshot)) do result[#result + 1] = descriptor end
  return result
end
