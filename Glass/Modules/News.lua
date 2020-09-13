local Core, Constants = unpack(select(2, ...))
local News = Core:GetModule("News")

local AceGUI = Core.Libs.AceGUI

local OPEN_NEWS = Constants.EVENTS.OPEN_NEWS

local CHANGELOG = {
  {
    name = "Unreleased (2020-09-13)",
    items = {
      "- Add more customization options (#107)"
    }
  },
  {
    name = "1.4.2 (2020-09-09)",
    items = {
      "- Fix icons not sliding up (#99)",
      "- Fix messages not being displayed sometimes (#99)",
      "- Fix issues with scrolling after frame resize (#99)",
    }
  },
  {
    name = "1.4.1 (2020-09-08)",
    items = {
      "- Fix AceDB issues"
    }
  },
  {
    name = "1.4.0 (2020-09-07)",
    items = {
      "- Add classic support (#95)"
    }
  },
  {
    name = "1.3.0 (2020-09-06)",
    items = {
      "- Add support for third-party chat links (#90)",
      "- Improve scrolling behavior (#92)",
      "- Force chatStyle to classic (#94)",
    }
  },
  {
    name = "1.2.1 (2020-09-01)",
    items = {
      "- Fix conflict with ElvUI Mover",
    }
  },
  {
    name = "1.2.0 (2020-08-31)",
    items = {
      "- Major rearchitecture (#79)",
      "- Add support for new tab whisper mode (#80)",
    }
  },
  {
    name = "1.1.1 (2020-08-26)",
    items = {
      "- Fix text processing pipeline (#70)",
      "- Fix jittery animations (#71)",
      "- Fix dependency issues (#72)",
    }
  },
  {
    name = "1.1.0 (2020-08-24)",
    items = {
      "- Add \"Unlock Window\" option to context menu - SammyJames",
      "- Add support for Prat timestamps",
    }
  },
  {
    name = "1.0.1 (2020-08-22)",
    items = {
      "- Fix Battle.net toast position",
      "- Fix some icon textures being squished",
    }
  },
  {
    name = "1.0.0 (2020-08-22)",
    items = {
      "- Initial release",
    }
  }
}

-- Module
function News:OnEnable()
  local baseSize = 12
  local scale = 1.333

  local frame = AceGUI:Create("Frame")
  frame:SetTitle("Glass: What’s new")
  frame:SetStatusText("Version: "..Core.Version)
  frame:SetCallback("OnClose", function(widget) frame:Hide() end)
  frame:SetLayout("Fill")
  frame:Hide()

  local scrollFrame = AceGUI:Create("ScrollFrame")
  scrollFrame:SetLayout("List")
  frame:AddChild(scrollFrame)

  for _, release in ipairs(CHANGELOG) do
    local releaseLabel = AceGUI:Create("Label")
    releaseLabel:SetFont('Fonts\\FRIZQT__.TTF', baseSize * scale);
    releaseLabel:SetRelativeWidth(1)
    releaseLabel:SetText("|c00DFBA69"..release.name.."|r")
    scrollFrame:AddChild(releaseLabel)

    for i, item in ipairs(release.items) do
      local itemLabel = AceGUI:Create("Label")
      itemLabel:SetFont('Fonts\\FRIZQT__.TTF', baseSize);
      itemLabel:SetRelativeWidth(1)

      local prefix, suffix = "", ""

      if i == 1 then
        prefix = "\n"
      end

      if i == #release.items then
        suffix = "\n"
      end

      itemLabel:SetText(prefix..item..suffix)
      scrollFrame:AddChild(itemLabel)
    end
  end

  Core:Subscribe(OPEN_NEWS, function ()
    frame:Show()
  end)
end
