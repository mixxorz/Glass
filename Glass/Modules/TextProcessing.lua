local Core, _, Utils = unpack(select(2, ...))
local TP = Core:GetModule("TextProcessing")
local Formatting = Core:GetModule("MessageFormatting")
local Markup = Core:GetModule("MessageMarkup")

local TIMESTAMP_FORMATS = {
  ["24h"] = "%H:%M",
  ["24h-seconds"] = "%H:%M:%S",
  ["12h"] = "%I:%M %p",
  ["12h-seconds"] = "%I:%M:%S %p",
}
local TIMESTAMP_COLOR = { r = 128 / 255, g = 128 / 255, b = 128 / 255 }

-- luacheck: push ignore 113
local strjoin = strjoin
local strsplit = strsplit
-- luacheck: pop

---
--Takes a texture escape string and adjusts its yOffset
local function adjustTextureYOffset(texture, settings)
  -- Texture has 14 parts
  -- path, height, width, offsetX, offsetY,
  -- texWidth, texHeight
  -- leftTex, topTex, rightTex, bottomText,
  -- rColor, gColor, bColor

  -- Strip escape characters
  -- Split into parts
  local parts = {strsplit(':', strsub(texture, 3, -3))}
  local yOffset = (settings or Core.db.profile).iconTextureYOffset

  if #parts < 5 then
    -- Pad out ommitted attributes
    for i=1, 5 do
      if parts[i] == nil then
        if i == 3 then
          -- If width is not specified, the width should equal the height
          parts[i] = parts[2]
        else
          parts[i] = '0'
        end
      end
    end
  end

  -- Adjust yOffset by configured amount
  parts[5] = tostring(tonumber(parts[5]) - yOffset)

  -- Rejoin string and readd escape codes
  return '|T'..strjoin(':', unpack(parts))..'|t'
end


---
-- Gets all inline textures found in the string and adjusts their yOffset
local function textureProcessor(text, settings)
  local cursor, unchangedStart = 1, 1
  local textureStart
  local parts = {}

  while cursor <= strlen(text) do
    local pipe = strfind(text, "|", cursor, true)
    if not pipe then break end
    local delimiter = strsub(text, pipe + 1, pipe + 1)
    if delimiter == "|" then
      cursor = pipe + 2
    elseif delimiter == "T" then
      textureStart = pipe
      cursor = pipe + 2
    elseif delimiter == "t" and textureStart then
      table.insert(parts, strsub(text, unchangedStart, textureStart - 1))
      table.insert(parts, adjustTextureYOffset(strsub(text, textureStart, pipe + 1), settings))
      unchangedStart = pipe + 2
      textureStart = nil
      cursor = pipe + 2
    else
      cursor = pipe + 1
    end
  end

  table.insert(parts, strsub(text, unchangedStart))
  return strjoin("", unpack(parts))
end

local function nativeTimestampProcessor(text, _, message)
  return Markup:StripNativeTimestamp(text, message)
end

local function baseColorProcessor(text, settings, message)
  if not Utils.canAccessValue(message) or type(message) ~= "table" then return text end
  local style = Formatting:ResolveStyle(message, settings or Core.db.profile)
  return Markup:NormalizeBaseColor(text, message, style)
end

local function headerProcessor(text, _, message)
  return Markup:FormatHeader(text, message)
end

local function glassTimestampProcessor(text, _, message)
  local settings = Formatting:GetSettings().timestamps
  if not settings.enabled or not Utils.canAccessValue(message) or type(message) ~= "table" then
    return text
  end
  local arrivedAt = message.arrivedAt
  if not Utils.canAccessValue(arrivedAt) or type(arrivedAt) ~= "number"
    or arrivedAt ~= arrivedAt or arrivedAt <= 0 or arrivedAt >= math.huge
    or not Utils.canAccessValue(_G.date) or type(_G.date) ~= "function" then
    return text
  end
  local preset = settings.preset
  if not TIMESTAMP_FORMATS[preset] then preset = "24h" end
  local stamp = _G.date(TIMESTAMP_FORMATS[preset], arrivedAt)
  if not Utils.canAccessValue(stamp) or type(stamp) ~= "string" then return text end
  if preset == "12h" or preset == "12h-seconds" then
    stamp = stamp:gsub("^0", "")
  end
  local color = Markup:ColorCode(settings.color) or Markup:ColorCode(TIMESTAMP_COLOR)
  if not color then return text end
  return color .. "[" .. stamp .. "]|r " .. text
end

---
-- Text processing pipeline
local TEXT_PROCESSORS = {
  nativeTimestampProcessor,
  baseColorProcessor,
  headerProcessor,
  textureProcessor,
  glassTimestampProcessor,
}

function TP:ProcessText(text, settings, message)
  local result = text
  local context = message or { text = text, r = 1, g = 1, b = 1 }

  for _, processor in ipairs(TEXT_PROCESSORS) do
    if not Utils.canAccessValue(result) then
      break
    end

    -- Prevent failing processors from bringing down the whole pipeline
    local retOk, retVal = pcall(processor, result, settings, context)

    if retOk then
      if not Utils.canAccessValue(retVal) then
        result = retVal
        break
      elseif type(retVal) == "string" then
        result = retVal
      end
    end
  end

  return result
end
