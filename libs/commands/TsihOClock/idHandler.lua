local dataManager = require("utils").DataManager("TsihOClock")

local M = {}

local function registrationExists(t, id)
  if t and t[1] then
    for _, value in ipairs(t) do
      if value.id == id then
        return true
      end
    end
  end
  return false
end

function M.sign(interaction)
  dataManager.key = "tsihoclockids"

  local id = interaction.channel.id
  local guildName = interaction.guild.name
  local idTable = dataManager:readData()

  if registrationExists(idTable, id) then
    return false
  end

  table.insert(idTable, { id = id, guildName = guildName })
  dataManager:writeData(idTable)

  return true
end

function M.remove(interaction)
  dataManager.key = "tsihoclockids"

  local id = interaction.channel.id
  local idTable = dataManager:readData()
  for key, value in pairs(idTable) do
    if value.id == id then
      table.remove(idTable, key)
      dataManager:writeData(idTable)
      return false
    end
  end

  return true
end

return M