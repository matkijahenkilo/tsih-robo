local dataManager = require("utils").DataManager("RandomEmoji")

local M = {}

local function isServerAlreadySaved(serverId, configTable)
  for _, savedId in ipairs(configTable) do
    if savedId == serverId then
      return true
    end
  end
  return false
end

local function removeId(id, configTable)
  for index, savedId in ipairs(configTable) do
    if savedId == id then
      table.remove(configTable, index)
      dataManager:writeData(configTable)
      return true
    end
  end
  return false
end

local function saveId(id, configTable)
  if not isServerAlreadySaved(id, configTable) then
    table.insert(configTable, id)
    dataManager:writeData(configTable)
    return true
  end
  return false
end

function M.removeServer(id)
  return removeId(id, dataManager:readData())
end

function M.addServer(id)
  return saveId(id, dataManager:readData())
end

function M.getIds()
  return dataManager:readData()
end

return M