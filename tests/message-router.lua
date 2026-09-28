-- Run from the project root: luajit tests/message-router.lua
local router = {}
local core = {GetModule = function() return router end}
assert(loadfile("Glass/Modules/MessageRouter.lua"))("Glass", {core, {MESSAGE_HISTORY_LIMIT = 128}})
router:OnInitialize()

local function receiver()
  local view = {replacements = 0, appends = {}, prepends = {}}
  function view:ReplaceMessages(messages)
    self.history = messages
    self.replacements = self.replacements + 1
  end
  function view:AppendMessages(messages) self.appends[#self.appends + 1] = messages end
  function view:PrependMessages(messages) self.prepends[#self.prepends + 1] = messages end
  return view
end

local history = {{text = "Existing loot", r = 1, g = 1, b = 1}}
local reads = 0
local source = router:CreateSource(function()
  reads = reads + 1
  return history
end)
local main, extra = receiver(), receiver()
router:Bind(main, source)
router:Bind(extra, source)
assert(main.history == history and extra.history == history)
assert(reads == 2)

router:Bind(extra, source)
assert(reads == 2 and extra.replacements == 1, "Rebinding the same source must preserve scrollback")

local live = {{text = "New loot", r = 0, g = 1, b = 0}}
router:Append(source, live)
assert(main.appends[1] == live and extra.appends[1] == live)
local older = {{text = "Oldest"}, {text = "Older"}}
router:Prepend(source, older)
assert(main.prepends[1] == older and extra.prepends[1] == older)
assert(older[1].text == "Oldest" and older[2].text == "Older")

local otherHistory = {{text = "Guild chat"}}
local otherSource = router:CreateSource(function() return otherHistory end)
router:Bind(main, otherSource)
assert(main.history == otherHistory and main.replacements == 2)
router:Append(source, live)
assert(#main.appends == 1 and #extra.appends == 2, "Main must not relay messages to extras")
router:Append(otherSource, otherHistory)
assert(main.appends[2] == otherHistory and #extra.appends == 2)

router:Bind(extra, nil)
assert(#extra.history == 0 and extra.replacements == 2)
router:Append(source, live)
assert(#extra.appends == 2, "Detached sources must stop delivering messages")
history = {{text = "Messages received while disabled"}}
router:Bind(extra, source)
assert(extra.history == history and reads == 3, "Re-enabling must read current history")

router:Unbind(main)
router:Unbind(main)
router:Append(otherSource, otherHistory)
assert(#main.appends == 2)
router:Append(source, live)
assert(#extra.appends == 3, "Unbinding one view must leave other subscriptions intact")
router:Unbind(extra)

local demoHistory = {{text = "Demo history"}}
local demoSource = router:CreateSource(function() return demoHistory end)
main, extra = receiver(), receiver()
local unavailable, disabled = receiver(), receiver()
router:Bind(main, source)
router:Bind(extra, source)
router:Bind(unavailable, nil)
router:Bind(disabled, source)
router:Unbind(disabled)
router:SetOverride(demoSource)
assert(main.history == demoHistory and extra.history == demoHistory)
assert(unavailable.history == demoHistory and router:HasSource(unavailable))
assert(disabled.history ~= demoHistory and not router:HasSource(disabled))
router:Append(source, live)
assert(#main.appends == 0 and #extra.appends == 0, "Real chat must not mix into the preview")
router:Append(demoSource, live)
assert(main.appends[1] == live and extra.appends[1] == live and unavailable.appends[1] == live)
assert(#disabled.appends == 0)

router:Bind(extra, otherSource)
assert(extra.replacements == 2, "Changing the real source must not reset an active preview")
local added = receiver()
router:Bind(added, otherSource)
assert(added.history == demoHistory, "New windows must join the active preview")
router:Bind(main, nil)
assert(main.history == demoHistory, "Unavailable native sources must still support previews")
router:Unbind(extra)
router:SetOverride(demoSource)
assert(added.replacements == 1, "Applying the same override must preserve scrollback")

otherHistory = {{text = "Chat received during demo"}}
router:SetOverride(nil)
assert(added.history == otherHistory and added.replacements == 2)
assert(#main.history == 0 and not router:HasSource(main))
assert(#unavailable.history == 0 and not router:HasSource(unavailable))
assert(extra.replacements == 2, "Removed views must not be reconnected when the preview ends")
router:Append(otherSource, otherHistory)
assert(added.appends[1] == otherHistory and #extra.appends == 1)
router:Append(demoSource, live)
assert(#added.appends == 1 and #main.appends == 1 and #unavailable.appends == 1)
router:SetOverride(nil)
assert(added.replacements == 2)

print("Message routing checks passed")
