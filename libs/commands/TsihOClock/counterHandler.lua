local dataManager = require("utils").DataManager("TsihOClock")

local M = {}

local function setNewTotal(newTotal)
  dataManager.key = "total"
  local total = dataManager:readData()
  if total then
    total = newTotal or 1
    dataManager:writeData(total)
  else
    dataManager:writeData(1)
  end
end

function M.getCurrentCounter()
  dataManager.key = "total"
  local total = dataManager:readData()
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
