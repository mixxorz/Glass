local Core, _, Utils = unpack(select(2, ...))
local Metadata = Core:GetModule("MessageMetadata")
local Formatting = Core:GetModule("MessageFormatting")

local function public(value, kind)
  return Utils.canAccessValue(value) and type(value) == kind
end
local function positive(value)
  return public(value, "number") and value > 0 and value < math.huge
end
local function integer(value)
  return positive(value) and value % 1 == 0
end
local function packed(value, count)
  return public(value, "table") and integer(value.n) and value.n >= count
end
local function component(value)
  if Utils.canAccessValue(value) and value == nil then return 1 end
  return value
end
local function clock(fn)
  if not public(fn, "function") then return nil end
  local ok, value = pcall(fn)
  if ok and positive(value) then return value end
end

function Metadata:Now()
  return clock(_G.GetServerTime) or clock(_G.time)
end

local function channelInfo(identifier, name)
  local api = _G.C_ChatInfo
  if not public(api, "table") or not public(api.GetChannelInfoFromIdentifier, "function") then return end
  local info = api.GetChannelInfoFromIdentifier(identifier)
  if Utils.canAccessValue(info) and info == nil and public(name, "string") then
    info = api.GetChannelInfoFromIdentifier(name)
  end
  if not public(info, "table") then return end
  local enum = _G.Enum
  if not public(enum, "table") then return end
  enum = enum.PermanentChatChannelType
  if not public(enum, "table") or not public(info.channelType, "number") then return end
  local kind
  if public(enum.Zone, "number") and info.channelType == enum.Zone then kind = "builtin"
  elseif public(enum.Custom, "number") and info.channelType == enum.Custom then kind = "custom"
  elseif public(enum.Communities, "number") and info.channelType == enum.Communities then kind = "community" end
  if not kind then return end
  return info, kind
end

function Metadata:RefreshChannels()
  local descriptors = {}
  if public(_G.GetChannelList, "function") then
    local list = {_G.GetChannelList()}
    for index = 1, #list, 3 do
      local id, name = list[index], list[index + 1]
      if integer(id) and public(name, "string") then
        local info, kind = channelInfo(tostring(id), name)
        if info and public(info.name, "string") and integer(info.localID) then
          local category = integer(info.zoneChannelID) and info.zoneChannelID or nil
          local key = Formatting:ResolveIdentity("CHANNEL", category, info.name, kind)
          if key then
            local displayName = name
            local chatFrameUtil = _G.ChatFrameUtil
            local resolveName = public(chatFrameUtil, "table") and chatFrameUtil.ResolveChannelName
              or _G.ChatFrame_ResolveChannelName
            if public(resolveName, "function") then
              local ok, resolved = pcall(resolveName, name)
              if ok and public(resolved, "string") then displayName = resolved end
            end
            descriptors[#descriptors + 1] = {
              key = key, name = tostring(info.localID) .. "." .. displayName,
              chatType = "CHANNEL", channelName = info.name,
              channelNumber = info.localID, channelKind = kind, hasHeader = true, available = true,
            }
          end
        end
      end
    end
  end
  Formatting:ReplaceChannels(descriptors)
end

local function nativeType(infoID)
  if not positive(infoID) then return end
  local api = _G.C_ChatInfo
  if public(api, "table") and public(api.GetChatTypeName, "function") then
    local ok, name = pcall(api.GetChatTypeName, infoID)
    if ok and public(name, "string") then
      return Formatting:ResolveIdentity(name) and name or nil
    end
  end
  local resolved
  for name, info in pairs(Formatting:GetChatTypes()) do
    if public(info.id, "number") and info.id == infoID then
      if resolved then return nil end
      resolved = name
    end
  end
  return resolved
end

local CHANNEL_NOTICES = {
  CHANNEL_JOIN = true, CHANNEL_LEAVE = true, CHANNEL_LIST = true,
  CHANNEL_NOTICE = true, CHANNEL_NOTICE_USER = true,
}

local function matchesNotice(extra, chatType, notice)
  if not public(notice, "table") or not public(notice.chatType, "string")
    or not CHANNEL_NOTICES[notice.chatType] then return false end
  if chatType then return chatType == notice.chatType end
  if not packed(extra, 1) or not public(extra[1], "number") or not integer(notice.channelNumber) then return false end
  local colors = _G.ChatTypeInfo
  local info = public(colors, "table") and colors["CHANNEL" .. notice.channelNumber]
  return public(info, "table") and public(info.id, "number") and info.id == extra[1]
end

local function decode(entry, origin, liveNotice)
  local result = {origin = origin}
  local extra = entry.extraData
  local hasEvent = false
  local plain = Utils.canAccessValue(extra) and extra == nil
  if public(extra, "table") then
    plain = public(extra.n, "number") and extra.n == 0
    if packed(extra, 1) then
      result.chatType = nativeType(extra[1])
      if extra.n == 1 and result.chatType then plain = true end
    end
    if packed(extra, 5) and public(extra[4], "string") then
      local event = extra[4]
      local chatType = event:match("^CHAT_MSG_([A-Z_]+)$")
      if chatType then
        result.nativeEvent, result.chatType = event, chatType
        hasEvent = true
        local args = extra[5]
        if chatType == "COMMUNITIES_CHANNEL" and packed(args, 9) then
          result.channelKind = "community"
          if integer(args[8]) then result.channelNumber = args[8] end
          if public(args[9], "string") then result.channelName = args[9] end
          result.identity = Formatting:ResolveIdentity("CHANNEL", nil, result.channelName, "community")
        elseif chatType == "CHANNEL" and packed(args, 9) then
          local category, slot, name = args[7], args[8], args[9]
          if integer(slot) then result.channelNumber = slot end
          if public(name, "string") then result.channelName = name end
          if integer(category) then
            result.channelKind = "builtin"
          elseif origin == "live" and integer(slot) and public(name, "string") then
            local info, kind = channelInfo(tostring(slot), name)
            if info and public(info.name, "string") and info.name == name
              and integer(info.localID) and info.localID == slot then result.channelKind = kind end
          end
          result.identity = Formatting:ResolveIdentity(chatType,
            integer(category) and category or nil, result.channelName, result.channelKind)
        end
      end
    end
  end
  if not hasEvent and origin == "live" and matchesNotice(extra, result.chatType, liveNotice) then
    result.chatType = liveNotice.chatType
    result.nativeEvent = "CHAT_MSG_" .. liveNotice.chatType
    result.identity = Formatting:ResolveIdentity(liveNotice.chatType)
    hasEvent = true
  end
  if not result.identity then result.identity = Formatting:ResolveIdentity(result.chatType) end
  if positive(entry.serverTime) then result.arrivedAt = entry.serverTime
  elseif origin == "live" and (hasEvent or plain) then
    -- Fade uptime is not evidence of an original wall-clock arrival.
    result.arrivedAt = Metadata:Now()
  end
  return result
end

local SENDERS = { SAY = true, YELL = true, WHISPER = true, WHISPER_INFORM = true,
  PARTY = true, PARTY_LEADER = true, PARTY_GUIDE = true, RAID = true, RAID_LEADER = true,
  RAID_WARNING = true, GUILD = true, OFFICER = true, INSTANCE_CHAT = true,
  INSTANCE_CHAT_LEADER = true, EMOTE = true, CHANNEL = true }

local function sender(entry)
  local extra = entry.extraData
  if not packed(extra, 5) or not public(extra[4], "string") then return end
  local chatType = extra[4]:match("^CHAT_MSG_([A-Z_]+)$")
  if not chatType or not SENDERS[chatType] then return end
  local args = extra[5]
  if not packed(args, 12) then return end
  local name, guid, line, flag = args[2], args[12], args[11], args[6]
  if not public(name, "string") or name == "" or not public(guid, "string")
    or not guid:match("^Player%-.+") or not integer(line) or not public(flag, "string") then return end
  return { senderName = name, senderGUID = guid, senderLineID = line, senderFlag = flag,
    nativeEvent = extra[4], chatType = chatType }
end

function Metadata:GetRecord(entry, origin, liveNotice)
  if not public(entry, "table") then return end
  local cached = self.records[entry]
  if cached then return cached end
  local text = entry.message
  if Utils.canAccessValue(text) then
    if text == nil then return end
    if type(text) ~= "string" then text = tostring(text) end
  end
  local record = {text = text, r = component(entry.r), g = component(entry.g), b = component(entry.b)}
  -- Optional metadata must never suppress an accepted native message.
  local ok, metadata = pcall(decode, entry, origin, liveNotice)
  if ok then for key, value in pairs(metadata) do record[key] = value end end
  local senderOK, fields = pcall(sender, entry)
  if senderOK and fields then for key, value in pairs(fields) do record[key] = value end end
  self.records[entry] = record
  return record
end

function Metadata:OnInitialize()
  self.records = setmetatable({}, { __mode = "k" })
  self.eventFrame = _G.CreateFrame("Frame")
  self.eventFrame:SetScript("OnEvent", function() self:RefreshChannels() end)
end

function Metadata:OnEnable()
  self:RefreshChannels()
  self.eventFrame:RegisterEvent("CHANNEL_UI_UPDATE")
end

function Metadata:OnDisable()
  self.eventFrame:UnregisterAllEvents()
end
