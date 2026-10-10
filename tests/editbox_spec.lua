_G.strmatch = string.match
dofile("libs/LibStub/LibStub.lua")
local LibStub = _G.LibStub
_G.issecurevariable = function() return false end
dofile("libs/AceHook-3.0/AceHook-3.0.lua")
local AceHook = LibStub("AceHook-3.0")

local function noop() end

local function region()
  return {
    Hide = noop, Show = noop, SetTexture = noop,
    SetColorTexture = noop, SetAllPoints = noop,
    SetFontObject = noop, ClearAllPoints = noop, SetPoint = noop,
    GetStringWidth = function() return 50 end,
    GetLineHeight = function() return 12 end,
  }
end

local function animationGroup()
  local group = {scripts = {}, playing = false}
  function group:CreateAnimation()
    return {
      SetFromAlpha = noop, SetToAlpha = noop,
      SetDuration = noop, SetSmoothing = noop,
    }
  end
  function group:SetScript(script, handler) self.scripts[script] = handler end
  function group:Play() self.playing = true end
  function group:Stop() self.playing = false end
  function group:IsPlaying() return self.playing end
  function group:Finish()
    self.playing = false
    if self.scripts.OnFinished then self.scripts.OnFinished(self) end
  end
  return group
end

local function editBox()
  local frame = {
    scripts = {}, animations = {}, header = region(),
    focusLeft = region(), focusMid = region(), focusRight = region(),
    ClearAllPoints = noop, SetPoint = noop, SetFontObject = noop,
    SetHeight = noop, Show = noop,
  }
  function frame:GetName() return "ChatFrame1EditBox" end
  function frame:GetWidth() return self.width end
  function frame:SetWidth(width) self.width = width end
  function frame:SetTextInsets(...) self.insets = {...} end
  function frame:Hide() self.hideCount = (self.hideCount or 0) + 1 end
  function frame:HasFocus() return false end
  function frame:CreateTexture() return region() end
  function frame:CreateAnimationGroup()
    local group = animationGroup()
    self.animations[#self.animations + 1] = group
    return group
  end
  function frame:HasScript() return true end
  function frame:GetScript(script) return self.scripts[script] end
  function frame:SetScript(script, handler) self.scripts[script] = handler end
  function frame:HookScript(script, handler)
    assert(type(script) == "string", "native HookScript requires a script name")
    assert(type(handler) == "function", "native HookScript requires a handler")
    local previous = self.scripts[script]
    self.scripts[script] = function(...)
      if previous then previous(...) end
      handler(...)
    end
  end
  return frame
end

_G.Mixin = function(object, mixin)
  for key, value in pairs(mixin) do object[key] = value end
  return object
end

local profile = {
  frameWidth = 550,
  editBoxAnchor = {position = "BELOW", yOfs = -5},
  editBoxBackgroundOpacity = 0.9,
}
local constants = {
  COLORS = {codGray = {r = 0.1, g = 0.1, b = 0.1}},
  ACTIONS = {
    EditBoxFocusGained = function() return "focus gained" end,
    EditBoxFocusLost = function() return "focus lost" end,
  },
  EVENTS = {LOCK_MOVER = "lock", UNLOCK_MOVER = "unlock", UPDATE_CONFIG = "config"},
}

local function check(pratFirst)
  local core = {
    Libs = {AceHook = AceHook}, Components = {},
    db = {profile = profile}, listeners = {}, events = {},
  }
  function core:Subscribe(event, handler) self.listeners[event] = handler end
  function core:Dispatch(event) self.events[#self.events + 1] = event end
  local frame = editBox()
  _G.ChatFrame1EditBox = frame
  for _, suffix in ipairs({"Left", "Mid", "Right"}) do
    _G[frame:GetName() .. suffix] = region()
  end
  local nativeHookScript = frame.HookScript
  local arrowCount, gainedCount, lostCount = 0, 0, 0
  frame:SetScript("OnEditFocusGained", function() gainedCount = gainedCount + 1 end)
  frame:SetScript("OnEditFocusLost", function() lostCount = lostCount + 1 end)

  local function addPratHook()
    -- Prat's Editbox module uses the native frame API to enable arrow-key history.
    frame:HookScript("OnArrowPressed", function(_, key)
      assert(key == "UP")
      arrowCount = arrowCount + 1
    end)
  end
  if pratFirst then addPratHook() end

  assert(loadfile("Glass/Components/EditBox.lua"))("Glass", {
    core, constants, {getEditBoxXPadding = function() return 12 end},
  })
  assert(core.Components.CreateEditBox({}) == frame)

  -- AceHook re-embeds its targets when a newer library copy loads.
  for target in pairs(AceHook.embeded) do AceHook:Embed(target) end
  if not pratFirst then addPratHook() end
  assert(frame.HookScript == nativeHookScript, "Glass replaced the native HookScript method")
  frame:GetScript("OnArrowPressed")(frame, "UP")
  assert(arrowCount == 1, "Prat's arrow-key hook did not run")

  local laterFocusCount = 0
  frame:HookScript("OnEditFocusGained", function() laterFocusCount = laterFocusCount + 1 end)
  frame:GetScript("OnEditFocusGained")(frame)
  frame:GetScript("OnEditFocusLost")(frame)
  assert(gainedCount == 1 and lostCount == 1 and laterFocusCount == 1)
  assert(core.events[1] == "focus gained" and core.events[2] == "focus lost")

  frame:SetTextInsets(0, 0, 0, 0)
  assert(frame.insets[1] == 62 and frame.insets[2] == 12)
  assert(frame.insets[3] == 12 * 0.66 and frame.insets[4] == 12 * 0.66)
  frame:Hide()
  assert(frame.hideCount == nil, "Glass bypassed its hide animation")
  frame.animations[2]:Finish()
  assert(frame.hideCount == 1, "Glass did not finish hiding the edit box")
  print("PASS: edit-box hooks, " .. (pratFirst and "Prat before Glass" or "Glass before Prat"))
end

check(false)
check(true)
