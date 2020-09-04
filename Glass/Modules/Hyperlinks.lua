local Core, Constants = unpack(select(2, ...))
local Hyperlinks = Core:GetModule("Hyperlinks")

local HYPERLINK_CLICK = Constants.EVENTS.HYPERLINK_CLICK
local HYPERLINK_ENTER = Constants.EVENTS.HYPERLINK_ENTER
local HYPERLINK_LEAVE = Constants.EVENTS.HYPERLINK_LEAVE

-- luacheck: push ignore 113
local BattlePetToolTip_ShowLink = BattlePetToolTip_ShowLink
local BattlePetTooltip = BattlePetTooltip
local GameTooltip = GameTooltip
local ShowUIPanel = ShowUIPanel
local UIParent = UIParent
-- luacheck: pop

local linkTypes = {
  item = true,
  enchant = true,
  spell = true,
  quest = true,
  achievement = true,
  currency = true,
  battlepet = true,
}

function Hyperlinks:OnInitialize()
  self.state = {
    showingTooltip = nil
  }
end

function Hyperlinks:OnEnable()
  Core:Subscribe(HYPERLINK_CLICK, function (payload)
    local link, text, button = unpack(payload)
    -- Use global reference in case some addon has hooked into it for custom
    -- hyperlinks (e.g. Mythic Dungeon Tools, Prat)
    _G.SetItemRef(link, text, button)
  end)

  Core:Subscribe(HYPERLINK_ENTER, function (payload)
    local link, text = unpack(payload)
    local t = string.match(link, "^(.-):")

    if linkTypes[t] then
      if t == "battlepet" then
        self.state.showingTooltip = BattlePetTooltip
        GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
        BattlePetToolTip_ShowLink(text)
      else
        self.state.showingTooltip = GameTooltip
        ShowUIPanel(GameTooltip)
        GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
      end
    end
  end)

  Core:Subscribe(HYPERLINK_LEAVE, function (link)
    if self.state.showingTooltip then
      self.state.showingTooltip:Hide()
      self.state.showingTooltip = false
    end
  end)
end
