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

local function isInGuild(interaction)
  if not interaction.guild then
    interaction:reply("This function only works within servers nanora!", true)
    return false
  end
  return true
end

function M.sign(interaction)
  if not isInGuild(interaction) then return end

  local id = interaction.channel.id
  local guildName = interaction.guild.name
  local idTable = dataManager:readData(false, "tsihoclockids")

  if registrationExists(idTable, id) then
    interaction:reply("Room is already signed for Tsih O'Clock!")
    return
  end

  table.insert(idTable, { id = id, guildName = guildName })
  dataManager:writeData(idTable, "tsihoclockids")

  interaction:reply("This room is now signed for Tsih O'Clock nanora!")
end

function M.remove(interaction)
  if not isInGuild(interaction) then return end

  local id = interaction.channel.id
  local idTable = dataManager:readData(false, "tsihoclockids")
  for key, value in pairs(idTable) do
    if value.id == id then
      table.remove(idTable, key)
      dataManager:writeData(idTable, "tsihoclockids")
      interaction:reply("Ugeeeh! You won't be seeing my artworks here anymore nanora!")
      return
    end
  end

  interaction:reply("B-but this room isn't even signed up nora!")
end

return M