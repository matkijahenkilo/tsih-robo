local dataManager = require("utils").DataManager("Sauce")

local M = {}

local function createJsonFileWithChannelRule(newLimit, guildId, channelId)
  local newJsonFileWithRule = {
    [guildId] = {
      [channelId] = newLimit
    }
  }
  dataManager:writeData(newJsonFileWithRule)
end

local function verifyIfRuleExists(t, guildId, channelId)
  if t[guildId] then
    return t[guildId][channelId] ~= nil
  end
  return false
end

local function replaceChannelRule(t, newLimit, guildId, channelId)
  t[guildId][channelId] = newLimit

  dataManager:writeData(t)
end

local function addGuildAndChannelRule(t, newLimit, guildId, channelId)
  if not t[guildId] then t[guildId] = {} end
  t[guildId][channelId] = newLimit

  dataManager:writeData(t)
end

local function replyToSlash(interaction, newLimit, isGlobal)
  if isGlobal then
    if newLimit ~= 0 then
      interaction:reply("I will send up to " .. newLimit .. " images per link in this **server** nanora!")
    else
      interaction:reply("I won't be sending the link's contents in this **server** anymore nanora!")
    end
  else
    if newLimit ~= 0 then
      interaction:reply("I will send up to " .. newLimit .. " images per link in this room nanora!")
    else
      interaction:reply("I won't be sending the link's contents in this room anymore nanora!")
    end
  end
end

local function isMemberOnGuild(interaction)
  if not interaction.guild then
    interaction:reply("This function does not work with DMs nanora!", true)
    return false
  end
  return true
end

local function saveConfig(newLimit, guildId, globalOrChannelId)
  local jsonContent = dataManager:readData()
  if jsonContent then
    if verifyIfRuleExists(jsonContent, guildId, globalOrChannelId) then
      replaceChannelRule(jsonContent, newLimit, guildId, globalOrChannelId)
    else
      addGuildAndChannelRule(jsonContent, newLimit, guildId, globalOrChannelId)
    end
  else
    createJsonFileWithChannelRule(newLimit, guildId, globalOrChannelId)
  end
end

---@return number | nil
function M.getRoomImageLimit(message)
  if not message.guild then return end
  local guildId = message.guild.id
  local channelId = message.channel.id

  local t = dataManager:readData()

  if t[guildId] then
    return t[guildId][channelId] or t[guildId]["global"]
  end
end

function M.setSauceLimitOnChannel(interaction, channelCommand)
  if not isMemberOnGuild(interaction) then return end

  local newLimit = channelCommand.limit
  local guildId = interaction.guild.id
  local channelId = interaction.channel.id

  saveConfig(newLimit, guildId, channelId)

  replyToSlash(interaction, newLimit, false)
end

function M.setSauceLimitOnServer(interaction, globalCommand)
  if not isMemberOnGuild(interaction) then return end

  local newLimit = globalCommand.limit
  local guildId = interaction.guild.id

  saveConfig(newLimit, guildId, "global")

  replyToSlash(interaction, newLimit, true)
end

return M