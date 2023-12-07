local dataManager = require("utils").DataManager("TsihOClock")

local M = {}

local function setNewTotal(newTotal)
  local total = dataManager:readData(false, "total")
  if total then
    total = newTotal or 1
    dataManager:writeData(total, "total")
  else
    dataManager:writeData(1, "total")
  end
end

function M.getCurrentCounter()
  local total = dataManager:readData(false, "total")
  return total or nil
end

function M.incrementTsihOClockCounter()
  local total = M.getCurrentCounter()
  if total then
    total = total + 1
  else
    return "ニール"
  end
  setNewTotal(total)
end

return M
