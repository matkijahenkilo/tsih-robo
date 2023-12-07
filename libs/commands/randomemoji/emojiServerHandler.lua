local dataManager = require("utils").DataManager("RandomEmoji")

local M = {}

local function isServerAlreadySaved(serverId, jsonContent)
  for _, savedId in ipairs(jsonContent) do
    if savedId == serverId then
      return true
    end
  end
  return false
end

local function removeId(id, jsonContent)
  for index, savedId in ipairs(jsonContent) do
    if savedId == id then
      table.remove(jsonContent, index)
      dataManager:writeData(jsonContent)
      return true
    end
  end
  return false
end

local function saveId(id, jsonContent)
  if not isServerAlreadySaved(id, jsonContent) then
    table.insert(jsonContent, id)
    dataManager:writeData(jsonContent)
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