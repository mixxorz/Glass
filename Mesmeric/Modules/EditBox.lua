local Core, Constants = unpack(select(2, ...))
local EB = Core:GetModule("EditBox")
local MC = Core:GetModule("MainContainer")

local Colors = Constants.COLORS

-- luacheck: push ignore 113
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
-- luacheck: pop

function EB:OnInitialize()
  for i=1, NUM_CHAT_WINDOWS do
    local editBox = _G["ChatFrame"..i.."EditBox"]

    -- Hide default styling
    _G["ChatFrame"..i.."EditBoxLeft"]:Hide()
    _G["ChatFrame"..i.."EditBoxMid"]:Hide()
    _G["ChatFrame"..i.."EditBoxRight"]:Hide()

    self:RawHook(_G["ChatFrame"..i.."EditBoxFocusLeft"], "Show", function () end, true)
    self:RawHook(_G["ChatFrame"..i.."EditBoxFocusMid"], "Show", function () end, true)
    self:RawHook(_G["ChatFrame"..i.."EditBoxFocusRight"], "Show", function () end, true)

    -- New styling
    editBox:ClearAllPoints()
    editBox:SetPoint("TOPLEFT", MC:GetFrame(), "BOTTOMLEFT", 8, -5)
    editBox:SetWidth(MC:GetFrame():GetWidth() - 8 * 2)
    editBox:SetHeight(30)
    editBox:SetFontObject("MesmericFont")
    editBox.header:SetFontObject("MesmericFont")
    editBox.header:SetPoint("LEFT", 8, 0)

    local bg = editBox:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(Colors.codGray.r, Colors.codGray.g, Colors.codGray.b, 0.6)
    bg:SetAllPoints()

    self:RawHook(editBox, "SetTextInsets", function ()
      self.hooks[editBox].SetTextInsets(
        editBox,
        editBox.header:GetStringWidth() + 8,
        8, 8, 8
      )
    end, true)

    -- Animations
    -- Intro animations
    local introAg = editBox:CreateAnimationGroup()
    local fadeIn = introAg:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.2)
    fadeIn:SetSmoothing("OUT")

    -- Outro animations
    local outroAg = editBox:CreateAnimationGroup()
    local fadeOut = outroAg:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.05)

    -- Workaround for editbox being open on login
    editBox.mesmericInitialized = false

    editBox:SetScript("OnShow", function ()
      if editBox.mesmericInitialized then
        introAg:Play()
      else
        editBox.mesmericInitialized = true
      end
    end)

    outroAg:SetScript("OnFinished", function ()
      if not introAg:IsPlaying() then
        self.hooks[editBox].Hide(editBox)
      end
    end)

    self:RawHook(editBox, "Hide", function ()
      outroAg:Play()
    end, true)
  end
end
