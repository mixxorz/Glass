local Core, _, Utils = unpack(select(2, ...))

-- Utility functions
Utils.super = function (obj)
  return getmetatable(obj).__index
end

---
-- Print to VDT
Utils.print = function (str, t)
  if _G.ViragDevTool_AddData then
    _G.ViragDevTool_AddData(t, str)
  else
    -- Buffer print messages until ViragDevTool loads
    table.insert(Core.printBuffer, {str, t})
  end
end

---
-- Prints Glass' notification messages
Utils.notify = function (message)
  print("|c00DFBA69Glass|r: ", message)
end
