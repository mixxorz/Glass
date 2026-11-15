local Core, _, Utils = unpack(select(2, ...))
local Markup = Core:GetModule("MessageMarkup")
local Formatting = Core:GetModule("MessageFormatting")

local function public(value, kind)
  return Utils.canAccessValue(value) and type(value) == kind
end
local function finite(value)
  return public(value, "number") and value == value and value > -math.huge and value < math.huge
end
local function replaceSpan(text, first, last, replacement)
  return text:sub(1, first - 1) .. replacement .. text:sub(last + 1)
end
local function literal(text)
  return (text:gsub("([^%w])", "%%%1"))
end
local function context(message)
  return public(message, "table") and public(message.chatType, "string")
    and message.chatType:match("^[A-Z_]+%d*$") and public(message.identity, "string")
end
local function nativeContext(message)
  if not public(message, "table") or not public(message.chatType, "string")
    or not message.chatType:match("^[A-Z_]+%d*$") then return false end
  local event = message.nativeEvent
  if not Utils.canAccessValue(event) then return false end
  if event ~= nil then return public(event, "string") and event == "CHAT_MSG_" .. message.chatType end
  -- Native pings supply only a chat-type ID, without event metadata.
  return message.chatType == "PING" and public(message.identity, "string") and message.identity == "type:PING"
end

function Markup:EscapeLabel(value)
  if not public(value, "string") then return value end
  return (value:gsub("[\r\n]", " "):gsub("|", "||"))
end

function Markup:ColorCode(color)
  if not public(color, "table") then return nil end
  for _, key in ipairs({ "r", "g", "b" }) do
    if not finite(color[key]) or color[key] < 0 or color[key] > 1 then return nil end
  end
  return string.format("|cff%02x%02x%02x", math.floor(color.r * 255 + 0.5),
    math.floor(color.g * 255 + 0.5), math.floor(color.b * 255 + 0.5))
end

-- Delimiters must be real pipes, not the second half of an escaped pipe.
local function delimiter(text, start, wanted)
  local at = start
  while at <= #text do
    local pipe = text:find("|", at, true)
    if not pipe then return nil end
    local pair = text:sub(pipe, pipe + 1)
    if pair == "||" then
      at = pipe + 2
    elseif pair == wanted then
      return pipe
    else
      at = pipe + 2
    end
  end
end

local function token(text, at)
  local pair = text:sub(at, at + 1)
  if pair == "||" then return { kind = "literal", last = at + 1 } end
  local color = text:sub(at):match("^|c%x%x%x%x%x%x%x%x")
    or text:sub(at):match("^|cn[%w_]+:")
  if color then return { kind = "color", last = at + #color - 1, raw = color } end
  if pair == "|r" then return { kind = "reset", last = at + 1 } end
  if pair == "|T" or pair == "|A" then
    local close = delimiter(text, at + 2, pair == "|T" and "|t" or "|a")
    if close and not text:sub(at + 2, close - 1):find("|", 1, true) then
      return { kind = "decoration", last = close + 1 }
    end
  elseif pair == "|H" then
    local first = delimiter(text, at + 2, "|h")
    local last = first and delimiter(text, first + 2, "|h")
    if last and not text:sub(at + 2, first - 1):find("|", 1, true) then
      return { kind = "link", last = last + 1, target = text:sub(at + 2, first - 1),
        firstLabel = first + 2, lastLabel = last - 1 }
    end
  end
end

local function prefix(text)
  local at, active = 1, nil
  while at <= #text do
    local item = token(text, at)
    if not item then return at, active end
    if item.kind == "color" then
      active = item.raw
    elseif item.kind == "reset" then
      active = nil -- WoW resets to the FontString base, not a previous color.
    elseif item.kind ~= "decoration" then
      return at, active, item
    end
    at = item.last + 1
  end
  return at, active
end

local FAMILIES = { PARTY_LEADER = "PARTY", RAID_LEADER = "RAID", RAID_WARNING = "RAID",
  INSTANCE_CHAT_LEADER = "INSTANCE_CHAT" }
local function agrees(target, message)
  local number = target:match("^channel:channel:([1-9]%d*)$")
  if number then
    return (message.chatType == "CHANNEL" or message.chatType == "COMMUNITIES_CHANNEL"
      or message.chatType:match("^CHANNEL%d+$"))
      and finite(message.channelNumber) and tonumber(number) == message.channelNumber
  end
  local family = target:match("^channel:([A-Z_]+)$")
  return family and (family == message.chatType or family == FAMILIES[message.chatType])
end

local function header(text, message)
  local at, active, item = prefix(text)
  if item then
    if item.kind ~= "link" or not agrees(item.target, message) then return nil end
    return item.firstLabel, item.lastLabel, active
  end
  local template = _G["CHAT_" .. message.chatType .. "_GET"]
  if not public(template, "string") then return nil end
  local templateAt, _, templateToken = prefix(template)
  local label
  if templateToken and templateToken.kind == "link" and agrees(templateToken.target, message) then
    label = template:sub(templateToken.firstLabel, templateToken.lastLabel)
    if not label:match("^%[[^%[%]%%|]+%]$") then label = nil end
  elseif not templateToken then
    label = template:sub(templateAt):match("^(%[[^%[%]%%|]+%])")
  end
  if label and text:sub(at, at + #label - 1) == label then
    return at, at + #label - 1, active
  end
end

-- Only text bytes participate in the bracket/alias span. Controls and icons
-- retain their order, including tokens before or after the visible brackets.
local function labelTokens(label)
  local items, at, firstText, lastText = {}, 1, nil, nil
  while at <= #label do
    local item
    if label:sub(at, at) == "|" then
      item = token(label, at)
      if not item or item.kind == "link" then return nil end
    else
      item = { kind = "literal", last = at }
    end
    item.raw = label:sub(at, item.last)
    if item.kind == "literal" then
      firstText = firstText or #items + 1
      lastText = #items + 1
    end
    items[#items + 1] = item
    at = item.last + 1
  end
  if not firstText or firstText == lastText or items[firstText].raw ~= "["
    or items[lastText].raw ~= "]" then return nil end
  return items, firstText, lastText
end

local function formatLabel(label, alias, color, active)
  local items, firstText, lastText = labelTokens(label)
  if not items then return nil end
  local result, inserted = {}, false
  if color then result[#result + 1] = color end
  for index, item in ipairs(items) do
    if item.kind == "color" then
      active = item.raw
      result[#result + 1] = item.raw
    elseif item.kind == "reset" then
      active = nil
      -- A native reset selects base color, not a stack pop. Within this label
      -- only, the independent label color substitutes for that base.
      result[#result + 1] = item.raw .. (color or "")
    elseif item.kind == "literal" and index > firstText and index < lastText and alias then
      if not inserted then result[#result + 1] = alias; inserted = true end
    else
      if index == lastText and alias and not inserted then
        result[#result + 1] = alias
        inserted = true
      end
      result[#result + 1] = item.raw
    end
  end
  -- Restore the original *post-label* state, which may differ from its entry
  -- state when the native label itself contains a color opener or reset.
  if color then result[#result + 1] = "|r" .. (active or "") end
  return table.concat(result)
end

function Markup:FormatHeader(text, message)
  if not public(text, "string") or not context(message) then return text end
  local first, last, active = header(text, message)
  if not first then return text end
  -- GetAlias may stringify a channel number, so validate that metadata first.
  if not Utils.canAccessValue(message.channelNumber) then return text end
  if message.channelNumber ~= nil and not finite(message.channelNumber) then return text end
  if not Utils.canAccessValue(message.channelKind) then return text end
  local alias = Formatting:GetAlias(message)
  alias = public(alias, "string") and self:EscapeLabel(alias) or nil
  local color = self:ColorCode(Formatting:GetRule(message.identity).labelColor)
  local label = formatLabel(text:sub(first, last), alias, color, active)
  if not label then return text end
  return replaceSpan(text, first, last, label)
end

local function normalizedPrefix(text, message)
  local parts, at, linked, visible = {}, 1, false, false
  while at <= #text do
    if text:sub(at, at) == "|" then
      local item = token(text, at)
      if not item or item.kind == "literal" then return nil end
      if item.kind == "link" then
        if linked or visible or not agrees(item.target, message) then return nil end
        local label = text:sub(item.firstLabel, item.lastLabel)
        if not labelTokens(label) then return nil end
        linked = true
      end
      at = item.last + 1
    else
      local char = text:sub(at, at)
      parts[#parts + 1] = char
      if not char:match("%s") then visible = true end
      at = at + 1
    end
  end
  return (table.concat(parts):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", ""))
end

local function senderTemplate(message)
  local template = _G["CHAT_" .. message.chatType .. "_GET"]
  if not public(template, "string") then return nil end
  local at = 1
  while at <= #template do
    local char = template:sub(at, at)
    if char == "|" then
      local item = token(template, at)
      if not item or template:sub(at, item.last):find("%", 1, true) then return nil end
      at = item.last + 1
    elseif char == "%" then
      local rest = template:sub(at)
      if rest:sub(1, 2) ~= "%s" and rest:sub(1, 4) ~= "%1$s" then return nil end
      return normalizedPrefix(template:sub(1, at - 1), message)
    else
      at = at + 1
    end
  end
end

function Markup:FormatSender(text, message, viewSettings)
  local options = Formatting:GetPlayerSettings()
  if not options.raceIcon and not options.classIcon and not options.classColor then return text end
  if not public(text, "string") or not nativeContext(message)
    or not public(message.senderName, "string") or not public(message.senderGUID, "string")
    or not finite(message.senderLineID) or message.senderLineID <= 0 or message.senderLineID % 1 ~= 0
    or not public(message.senderFlag, "string") then return text end
  local wanted = senderTemplate(message)
  if not wanted then return text end
  local at, active, candidate, start = 1, nil, nil, nil
  while at <= #text do
    if text:sub(at, at) == "|" then
      local item = token(text, at)
      if not item then return text end
      if item.kind == "color" then active = item.raw
      elseif item.kind == "reset" then active = nil
      elseif item.kind == "link" then
        if not item.target:match("^channel:") then candidate, start = item, at; break end
        local controls = labelTokens(text:sub(item.firstLabel, item.lastLabel))
        if not controls then return text end
        for _, control in ipairs(controls) do
          if control.kind == "color" then active = control.raw
          elseif control.kind == "reset" then active = nil end
        end
      end
      at = item.last + 1
    else
      at = at + 1
    end
  end
  if not candidate then return text end
  local before = normalizedPrefix(text:sub(1, start - 1), message)
  if not before then return text end
  if before ~= wanted then
    local flag = _G["CHAT_FLAG_" .. message.senderFlag]
    if not public(flag, "string") then return text end
    local withFlag = normalizedPrefix((wanted .. " " .. flag), message)
    local joinedFlag = normalizedPrefix(wanted .. flag, message)
    if before ~= withFlag and before ~= joinedFlag then return text end
  end
  local name, line, category = candidate.target:match("^player:([^:]+):(%d+):([A-Z_]+):[^:]*$")
  if not name or name ~= message.senderName or tonumber(line) ~= message.senderLineID
    or category ~= (FAMILIES[message.chatType]
      or (message.chatType == "WHISPER_INFORM" and "WHISPER")
      or (message.chatType == "PARTY_GUIDE" and "PARTY") or message.chatType) then return text end
  local label = text:sub(candidate.firstLabel, candidate.lastLabel)
  local items, cursor = {}, 1
  while cursor <= #label do
    local item
    if label:sub(cursor, cursor) == "|" then
      item = token(label, cursor)
      if not item or item.kind == "link" then return text end
    else
      item = { kind = "literal", last = cursor }
    end
    item.raw = label:sub(cursor, item.last)
    items[#items + 1] = item
    cursor = item.last + 1
  end
  local appearance = Core:GetModule("PlayerIdentity"):GetAppearance(
    message.senderGUID, options, viewSettings, message.senderName)
  if not appearance then return text end
  local color = self:ColorCode(appearance.color)
  if color then
    local parts = { color }
    for _, item in ipairs(items) do
      if item.kind == "color" then active = item.raw
      elseif item.kind == "reset" then active = nil
      else parts[#parts + 1] = item.raw end
    end
    -- Restore the native post-label state, not just the color at link entry.
    parts[#parts + 1] = "|r" .. (active or "")
    label = table.concat(parts)
  end
  local link = text:sub(start, candidate.firstLabel - 1) .. label
    .. text:sub(candidate.lastLabel + 1, candidate.last)
  return replaceSpan(text, start, candidate.last, appearance.icons .. link)
end

local function timestampFormat()
  local util = _G.ChatFrameUtil
  if public(util, "table") and public(util.GetTimestampFormat, "function") then
    return util.GetTimestampFormat()
  end
  if public(_G.CHAT_TIMESTAMP_FORMAT, "string") then return _G.CHAT_TIMESTAMP_FORMAT end
  if public(_G.GetCVar, "function") then return _G.GetCVar("showTimestamps") end
end

local NATIVE_TIMESTAMP_PRESETS = {
  "TIMESTAMP_FORMAT_HHMM", "TIMESTAMP_FORMAT_HHMMSS",
  "TIMESTAMP_FORMAT_HHMM_AMPM", "TIMESTAMP_FORMAT_HHMMSS_AMPM",
  "TIMESTAMP_FORMAT_HHMM_24HR", "TIMESTAMP_FORMAT_HHMMSS_24HR",
}
local function timestampFormats()
  local formats, seen = {}, {}
  local function add(value)
    if public(value, "string") and value ~= "" and not seen[value] then
      seen[value] = true
      formats[#formats + 1] = value
    end
  end
  for _, name in ipairs(NATIVE_TIMESTAMP_PRESETS) do add(_G[name]) end
  add(timestampFormat())
  return formats
end

-- Compile only native clock fields. All surrounding bytes belong to the native
-- template too; unknown strftime fields and markup make the format unsupported.
local function clockPattern(format, period)
  local parts, fields, at = { "^" }, {}, 1
  local hour, minute, activeColor = false, false, false
  while at <= #format do
    local char = format:sub(at, at)
    if char == "%" then
      local field = format:sub(at + 1, at + 1)
      if field == "H" or field == "I" or field == "M" or field == "S" then
        if fields[field] then return nil end
        fields[field] = true
        fields[#fields + 1] = field
        parts[#parts + 1] = "(%d%d)"
        hour = hour or field == "H" or field == "I"
        minute = minute or field == "M"
      elseif field == "p" and public(period, "string") and period ~= "" then
        parts[#parts + 1] = literal(period)
      else
        return nil
      end
      at = at + 2
    elseif char == "|" then
      local item = token(format, at)
      if not item or (item.kind ~= "color" and item.kind ~= "reset") then return nil end
      if item.kind == "reset" and not activeColor then return nil end
      activeColor = item.kind == "color"
      parts[#parts + 1] = literal(format:sub(at, item.last))
      at = item.last + 1
    elseif char:match("[%[%] :%.%-]") then
      parts[#parts + 1] = literal(char)
      at = at + 1
    else
      return nil
    end
  end
  if not hour or not minute or activeColor or (fields.H and fields.I) then return nil end
  parts[#parts + 1] = "()"
  return table.concat(parts), fields
end

local function clockEnd(text, format)
  local am = public(_G.TIMEMANAGER_AM, "string") and _G.TIMEMANAGER_AM or ""
  local pm = public(_G.TIMEMANAGER_PM, "string") and _G.TIMEMANAGER_PM or ""
  for _, period in ipairs({ am, pm }) do
    local pattern, fields = clockPattern(format, period)
    if not pattern then return nil end
    local captures = { text:match(pattern) }
    if #captures > 0 then
      local valid = true
      for index, field in ipairs(fields) do
        local value = tonumber(captures[index])
        local min = field == "I" and 1 or 0
        local max = field == "H" and 23 or (field == "I" and 12 or 59)
        if not value or value < min or value > max then valid = false end
      end
      if valid then return captures[#fields + 1] - 1 end
    end
  end
end

function Markup:StripNativeTimestamp(text, message)
  if not public(text, "string") or not nativeContext(message) then return text end
  local outer = token(text, 1)
  local longest, replacement
  for _, format in ipairs(timestampFormats()) do
    local last = clockEnd(text, format)
    if last and (not longest or last > longest) then
      longest, replacement = last, text:sub(last + 1)
    end
    if outer and outer.kind == "color" then
      last = clockEnd(text:sub(outer.last + 1), format)
      if last and (not longest or outer.last + last > longest) then
        longest = outer.last + last
        replacement = outer.raw .. text:sub(longest + 1)
      end
    end
  end
  if replacement then return replacement end
  return text
end

function Markup:NormalizeBaseColor(text, message, style)
  if not public(text, "string") or not context(message) or not public(style, "table") then return text end
  if not Formatting:GetRule(message.identity).textColor then return text end
  -- Native MessageFormatter passes default RGB separately to AddMessage. The
  -- normalized record carries no provenance for an addon-supplied outer wrapper;
  -- matching its RGB alone cannot prove that its resets are safe to remove.
  return text
end
