local Core, _, Utils = unpack(select(2, ...))

-- Utility functions

---
-- String split
Utils.split = function (text, sep)
  sep = sep or ":"
  local fields = {}
  local pattern = string.format("([^%s]+)", sep)
  string.gsub(text, pattern, function(c) fields[#fields+1] = c end)
  return fields
end

---
-- Print to VDT
Utils.print = function(str, t)
  if _G.ViragDevTool_AddData then
    _G.ViragDevTool_AddData(t, str)
  else
    -- Buffer print messages until ViragDevTool loads
    table.insert(Core.printBuffer, {str, t})
  end
end
