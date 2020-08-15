local Core, Constants, Utils = unpack(select(2, ...))
local EB = Core:GetModule("EditBox")
local MC = Core:GetModule("MainContainer")

local Colors = Constants.COLORS
local LSM = Core.Libs.LSM

-- luacheck: push ignore 113
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS
local CreateFont = CreateFont
-- luacheck: pop

function EB:OnInitialize()
  self.state = {
    editBoxes = {}
  }
end

function EB:OnEnable()
  -- Message font
  self.font = CreateFont("MesmericEditBoxFont")
  self.font:SetFont(
    LSM:Fetch(LSM.MediaType.FONT, Core.db.profile.font),
    Core.db.profile.editBoxFontSize
  )
  self.font:SetShadowColor(0, 0, 0, 0)
  self.font:SetShadowOffset(1, -1)
  self.font:SetJustifyH("LEFT")
  self.font:SetJustifyV("MIDDLE")
  self.font:SetSpacing(3)

  for i=1, NUM_CHAT_WINDOWS do
    local editBox = _G["ChatFrame"..i.."EditBox"]

    table.insert(self.state.editBoxes, editBox)

    -- Hide default styling
    _G["ChatFrame"..i.."EditBoxLeft"]:Hide()
    _G["ChatFrame"..i.."EditBoxMid"]:Hide()
    _G["ChatFrame"..i.."EditBoxRight"]:Hide()
    _G["ChatFrame"..i.."EditBoxFocusLeft"]:Hide()
    _G["ChatFrame"..i.."EditBoxFocusMid"]:Hide()
    _G["ChatFrame"..i.."EditBoxFocusRight"]:Hide()

    self:RawHook(_G["ChatFrame"..i.."EditBoxLeft"], "Show", function () end, true)
    self:RawHook(_G["ChatFrame"..i.."EditBoxMid"], "Show", function () end, true)
    self:RawHook(_G["ChatFrame"..i.."EditBoxRight"], "Show", function () end, true)
    self:RawHook(_G["ChatFrame"..i.."EditBoxFocusLeft"], "Show", function () end, true)
    self:RawHook(_G["ChatFrame"..i.."EditBoxFocusMid"], "Show", function () end, true)
    self:RawHook(_G["ChatFrame"..i.."EditBoxFocusRight"], "Show", function () end, true)

    -- New styling
    editBox:ClearAllPoints()
    editBox:SetPoint("TOPLEFT", MC:GetFrame(), "BOTTOMLEFT", 8, -5)
    editBox:SetFontObject("MesmericEditBoxFont")
    editBox:SetWidth(MC:GetFrame():GetWidth() - 8 * 2)
    editBox.header:SetFontObject("MesmericEditBoxFont")
    editBox.header:SetPoint("LEFT", 8, 0)

    local bg = editBox:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(Colors.codGray.r, Colors.codGray.g, Colors.codGray.b, 0.6)
    bg:SetAllPoints()

    self:RawHook(editBox, "SetTextInsets", function ()
      local Ypadding = editBox.header:GetLineHeight() * 0.66
      self.hooks[editBox].SetTextInsets(
        editBox,
        editBox.header:GetStringWidth() + 8,
        8, Ypadding, Ypadding
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

    ---
    -- Methods

    editBox.UpdateFont = function ()
      local Ypadding = editBox.header:GetLineHeight() * 0.66
      editBox:SetHeight(editBox.header:GetLineHeight() + Ypadding * 2)
      editBox:SetTextInsets()
    end

    editBox:UpdateFont()
  end
end

function EB:OnUpdateFont()
  self.font:SetFont(
    LSM:Fetch(LSM.MediaType.FONT, Core.db.profile.font),
    Core.db.profile.editBoxFontSize
  )

  for _, editBox in ipairs(self.state.editBoxes) do
    editBox:UpdateFont()
  end
end

function EB:OnUpdateFrame()
  for _, editBox in ipairs(self.state.editBoxes) do
    editBox:SetWidth(MC:GetFrame():GetWidth() - 8 * 2)
  end
end
