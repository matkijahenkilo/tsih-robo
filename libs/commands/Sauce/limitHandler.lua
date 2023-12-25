local dataManager = require("utils").DataManager("Sauce")

local M = {}

local function isMemberOnGuild(interaction)
  if not interaction.guild then
    interaction:reply("This function does not work with DMs nanora!", true)
    return false
  end
  return true
end

---@return integer|nil
function M.getRoomImageLimit(message)
  if not message.guild then return end
  local guildId = message.guild.id
  local channelId = message.channel.id

  dataManager.key = guildId
  local t = dataManager:readData()
  return t[channelId] or t["global"]
end

function M.setSauceLimitOnChannel(interaction, channelCommand)
  if not isMemberOnGuild(interaction) then return end

  local newLimit = channelCommand.limit
  local guildId = interaction.guild.id
  local channelId = interaction.channel.id

  dataManager.key = guildId
  local t = dataManager:readData()
  t[channelId] = newLimit
  dataManager:writeData(t)
end

function M.setSauceLimitOnServer(interaction, globalCommand)
  if not isMemberOnGuild(interaction) then return end

  local newLimit = globalCommand.limit
  local guildId = interaction.guild.id

  dataManager.key = guildId
  local t = dataManager:readData()
  t["global"] = newLimit
  dataManager:writeData(t)
end

return M