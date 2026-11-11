local Core, Constants = unpack(select(2, ...))
local Demo = Core:GetModule("Demo")
local Router = Core:GetModule("MessageRouter")
local Metadata = Core:GetModule("MessageMetadata")

local function sample(chatType, text, r, g, b, channel)
  return {
    text = text, r = r, g = g, b = b,
    chatType = chatType,
    nativeEvent = "CHAT_MSG_" .. chatType,
    identity = channel and channel.key or "type:" .. chatType,
    channelName = channel and channel.name,
    channelNumber = channel and channel.number,
    channelKind = channel and channel.kind,
  }
end

local general = { key = "channel:builtin:1", name = "General", number = 1, kind = "builtin" }
local samples = {
  sample("GUILD", "|Hchannel:GUILD|h[Guild]|h |cff3fc7eb[Elowen]|r: Anyone up for a dungeon?", 0.25, 1, 0.25),
  sample("GUILD", "|Hchannel:GUILD|h[Guild]|h |cfff48cba[Brenna]|r: Sure, I can heal. Just finishing this quest.",
    0.25, 1, 0.25),
  sample("LOOT", "You receive loot: |cffffffff|Hitem:2589|h[Linen Cloth]|h|r x4.", 0, 0.67, 0),
  sample("MONEY", "You loot 12 |TInterface\\MoneyFrame\\UI-SilverIcon:12|t " ..
    "45 |TInterface\\MoneyFrame\\UI-CopperIcon:12|t", 1, 1, 0),
  sample("PARTY", "|Hchannel:PARTY|h[Party]|h |cffc69b6d[Torin]|r: Everyone ready?", 0.67, 0.67, 1),
  sample("PARTY", "|Hchannel:PARTY|h[Party]|h |cffaad372[Rowan]|r: Ready!", 0.67, 0.67, 1),
  sample("WHISPER", "|cfffff468[Mira]|r whispers: I'm near the flight master. Let me know when you're back in town.",
    1, 0.5, 1),
  sample("LOOT", "You receive loot: |cff1eff00|Hitem:15210|h[Raider's Shortsword]|h|r.", 0, 0.67, 0),
  sample("PARTY", "|Hchannel:PARTY|h[Party]|h |cfff48cba[Brenna]|r: Give me a moment to drink before the next pull.",
    0.67, 0.67, 1),
  sample("SYSTEM", "Quest accepted: A Helping Hand", 1, 1, 0),
  sample("CHANNEL", "|Hchannel:channel:1|h[1. General]|h |cff3fc7eb[Elowen]|r: " ..
    "The entrance is around the back of the tower, past the bridge.", 1, 0.75, 0.75, general),
  sample("LOOT", "You receive loot: |cffffffff|Hitem:2447|h[Peacebloom]|h|r x2.", 0, 0.67, 0),
  sample("PARTY", "|Hchannel:PARTY|h[Party]|h |cffc69b6d[Torin]|r: " ..
    "Let's clear the patrol first, then head up the stairs together. " ..
    "There is another group just around the corner, so stay close to the wall until everyone is ready.", 0.67, 0.67, 1),
  sample("COMBAT_FACTION_CHANGE", "You gain 250 reputation with Stormwind.", 0.5, 0.5, 1),
  sample("GUILD", "|Hchannel:GUILD|h[Guild]|h |cffaad372[Rowan]|r: That was a great run. Same time tomorrow?",
    0.25, 1, 0.25),
  sample("SYSTEM", "|cfffff468[Mira]|r has come online.", 1, 1, 0),
  sample("LOOT", "You receive loot: |cff0070dd|Hitem:2042|h[Staff of Westfall]|h|r.", 0, 0.67, 0),
  sample("PARTY", "|Hchannel:PARTY|h[Party]|h |cfff48cba[Brenna]|r: Nice! Congratulations!", 0.67, 0.67, 1),
  sample("SYSTEM", "A Helping Hand completed.", 1, 1, 0),
  sample("GUILD", "|Hchannel:GUILD|h[Guild]|h |cff3fc7eb[Elowen]|r: " ..
    "Thanks everyone. I'll put the spare materials in the guild bank.", 0.25, 1, 0.25),
}

function Demo:OnInitialize()
  self.active = false
  self.messages = {}
  self.source = Router:CreateSource(function() return self.messages end)
end

function Demo:IsActive()
  return self.active == true
end

function Demo:NextMessage()
  self.cursor = self.cursor % #samples + 1
  local template = samples[self.cursor]
  local message = {}
  for key, value in pairs(template) do message[key] = value end
  message.arrivedAt = Metadata:Now()
  message.origin = "demo"
  self.messages[#self.messages + 1] = message
  if #self.messages > Constants.MESSAGE_HISTORY_LIMIT then table.remove(self.messages, 1) end
  return message
end

function Demo:SetActive(active)
  active = active == true
  if self.active == active then return end
  self.active = active
  if active then
    self.messages, self.cursor = {}, 0
    for _ = 1, math.min(60, Constants.MESSAGE_HISTORY_LIMIT) do self:NextMessage() end
    Router:SetOverride(self.source)
    self.ticker = _G.C_Timer.NewTicker(2.5, function()
      Router:Append(self.source, {self:NextMessage()})
    end)
  else
    if self.ticker then self.ticker:Cancel(); self.ticker = nil end
    Router:SetOverride(nil)
    self.messages = {}
  end
  Core:GetModule("ExtraWindows"):RefreshVisibility()
  _G.LibStub("AceConfigRegistry-3.0"):NotifyChange("Glass")
end

function Demo:OnDisable()
  self:SetActive(false)
end
