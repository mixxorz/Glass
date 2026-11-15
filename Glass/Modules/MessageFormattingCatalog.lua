local Core, _, Utils = unpack(select(2, ...))
local F = Core:GetModule("MessageFormatting")

local SECTIONS = {
  { "PLAYER_MESSAGES", "CHAT_CONFIG_CHAT_LEFT" },
  { "CREATURE_MESSAGES", "CHAT_CONFIG_CHAT_CREATURE_LEFT" },
  { "COMBAT", "CHAT_CONFIG_OTHER_COMBAT" },
  { "PVP", "CHAT_CONFIG_OTHER_PVP" },
  { "OTHER", "CHAT_CONFIG_OTHER_SYSTEM" },
}
local GROUP_NAMES = {
  BG_SYSTEM_HORDE = "BG_HORDE",
  BG_SYSTEM_ALLIANCE = "BG_ALLIANCE",
  BG_SYSTEM_NEUTRAL = "BG_NEUTRAL",
}
local REPRESENTATIVES = { GUILD_MOTD = "GUILD" }

local function public(value, kind)
  return Utils.canAccessValue(value) and type(value) == kind
end
local function label(descriptor)
  local value = descriptor.text
  if public(value, "function") then
    local ok, result = pcall(value)
    value = ok and result or nil
  end
  if public(value, "string") and value ~= "" then return value end
  return _G[descriptor.type] or descriptor.type
end

local function groupEntry(descriptor)
  if not public(descriptor, "table") or not public(descriptor.type, "string") then return end
  local groupName = GROUP_NAMES[descriptor.type] or descriptor.type
  local groups = _G.ChatTypeGroup
  local group = public(groups, "table") and groups[groupName] or nil
  local entry = { key = "group:" .. descriptor.type, name = label(descriptor), members = {}, hasHeader = false }
  local seen = {}
  local function add(chatType)
    local key = F:ResolveIdentity(chatType)
    if not key or seen[key] then return end
    seen[key] = true
    local hasHeader = F:GetDefaultAlias({ chatType = chatType }) ~= nil
    entry.members[#entry.members + 1] = { key = key, chatType = chatType, hasHeader = hasHeader }
    entry.chatType = entry.chatType or chatType
    entry.hasHeader = entry.hasHeader or hasHeader
  end
  if public(group, "table") then
    for _, event in ipairs(group) do
      if public(event, "string") then
        local chatType = event:match("^CHAT_MSG_([A-Z_]+)$")
        add(chatType or REPRESENTATIVES[event] or (groupName == "SYSTEM" and "SYSTEM" or nil))
      end
    end
  end
  if #entry.members == 0 then
    local bossType = descriptor.type:gsub("^MONSTER_BOSS_", "RAID_BOSS_")
    add(bossType)
  end
  return entry
end

function F:GetCategories()
  local categories = {}
  for _, section in ipairs(SECTIONS) do
    local category = { key = section[1], name = _G[section[1]] or section[1], entries = {} }
    local descriptors = _G[section[2]]
    if public(descriptors, "table") then
      for _, descriptor in ipairs(descriptors) do
        local entry = groupEntry(descriptor)
        if entry then category.entries[#category.entries + 1] = entry end
      end
      categories[#categories + 1] = category
    end
  end
  local category = { key = "CHANNELS", name = _G.GLOBAL_CHANNELS or _G.CHANNELS or "CHANNELS", entries = {} }
  for _, member in ipairs(self:GetChannels()) do
    category.entries[#category.entries + 1] = {
      key = member.key, name = member.name, chatType = member.chatType, hasHeader = member.hasHeader,
      channelKind = member.channelKind, channelNumber = member.channelNumber, members = { member },
    }
  end
  categories[#categories + 1] = category
  return categories
end
