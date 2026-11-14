local Core, _, Utils = unpack(select(2, ...))
local Identity = Core:GetModule("PlayerIdentity")

local function public(value, kind)
  return Utils.canAccessValue(value) and type(value) == kind
end
local function finite(value)
  return public(value, "number") and value == value and value > -math.huge and value < math.huge
end
local function call(fn, ...)
  if not public(fn, "function") then return nil end
  local ok, value = pcall(fn, ...)
  if ok and Utils.canAccessValue(value) then return value end
end
local function realm(value)
  return (value:gsub("[%s%-]", ""):lower())
end
local function atlasExists(atlas)
  if not public(atlas, "string") or not atlas:match("^[%w_%-]+$") then return false end
  local api = _G.C_Texture
  local fn = _G.GetAtlasInfo
  if public(api, "table") and public(api.GetAtlasInfo, "function") then fn = api.GetAtlasInfo end
  return public(call(fn, atlas), "table")
end
local RACES = {
  scourge = "undead", highmountaintauren = "highmountain",
  lightforgeddraenei = "lightforged", zandalaritroll = "zandalari",
}

function Identity:GetAppearance(guid, options, viewSettings, expectedName)
  if not public(options, "table") then return nil end
  local raceOn = public(options.raceIcon, "boolean") and options.raceIcon
  local classOn = public(options.classIcon, "boolean") and options.classIcon
  local colorOn = public(options.classColor, "boolean") and options.classColor
  if not raceOn and not classOn and not colorOn then return nil end
  if not public(guid, "string") or not guid:match("^Player%-.+")
    or not public(expectedName, "string") or expectedName == ""
    or not public(_G.GetPlayerInfoByGUID, "function") then return nil end
  local ok, _, class, _, race, sex, name, server = pcall(_G.GetPlayerInfoByGUID, guid)
  if not ok then return nil end
  local expected, expectedRealm = expectedName:match("^([^%-]+)%-(.+)$")
  expected = expected or expectedName
  if public(name, "string") and name ~= expected then return nil end
  if expectedRealm and public(server, "string") and server ~= "" and realm(server) ~= realm(expectedRealm) then
    return nil
  end
  local settings = public(viewSettings, "table") and viewSettings or Core.db.profile
  local size, offset = settings.messageFontSize, settings.iconTextureYOffset
  local icons = {}
  local function add(atlas)
    if finite(size) and size > 0 and size <= 256 and finite(offset) and math.abs(offset) <= 256
      and atlasExists(atlas) then
      icons[#icons + 1] = string.format("|A:%s:%g:%g:0:%g|a ", atlas, size, size, -offset)
    end
  end
  if raceOn and public(race, "string") and race:match("^[%a]+$")
    and public(sex, "number") and (sex == 2 or sex == 3) then
    local gender = sex == 2 and "male" or "female"
    local raceName = race:lower()
    local atlas = call(_G.GetRaceAtlas, raceName, gender)
    if not atlasExists(atlas) then atlas = "raceicon-" .. (RACES[raceName] or raceName) .. "-" .. gender end
    add(atlas)
  end
  local color
  if public(class, "string") and class:match("^[A-Z]+$") then
    if classOn then
      local className = class:lower()
      local atlas = call(_G.GetClassAtlas, className)
      if not atlasExists(atlas) then atlas = "classicon-" .. className end
      add(atlas)
    end
    if colorOn then
      local api = _G.C_ClassColor
      local candidate = public(api, "table") and call(api.GetClassColor, class) or nil
      if not public(candidate, "table") and public(_G.RAID_CLASS_COLORS, "table") then
        candidate = _G.RAID_CLASS_COLORS[class]
      end
      if public(candidate, "table") and finite(candidate.r) and finite(candidate.g) and finite(candidate.b)
        and candidate.r >= 0 and candidate.r <= 1 and candidate.g >= 0 and candidate.g <= 1
        and candidate.b >= 0 and candidate.b <= 1 then
        color = { r = candidate.r, g = candidate.g, b = candidate.b }
      end
    end
  end
  return { icons = table.concat(icons), color = color }
end
