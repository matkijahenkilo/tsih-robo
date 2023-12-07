---@type discordia
local discordia    = require("discordia")
local tools        = require("discordia-slash").util.tools()
local utils        = require("utils")
local client       = discordia.Client():useApplicationCommands()
local clock        = discordia.Clock()
local statusTable  = utils.statusTable
local stackTrace   = utils.StackTrace(client)
local wrap         = coroutine.wrap
local timer        = require("timer")
local commands     = {}
discordia.extensions.string()

do
  local commandsMetaTable = {
    __index = function()
      local M = {}
      function M.execute()
        client:warning("Something went wrong.")
      end
      return M
    end
  }
  commands = setmetatable(require("commands"), commandsMetaTable)
end

local function initializeCommands()
  client:info("Bot was opted to reset all global commands~")
  local i, j = 1, 1
  for commandId in pairs(client:getGlobalApplicationCommands()) do
    client:info("Deleting command #"..i)
    client:deleteGlobalApplicationCommand(commandId)
    i = i + 1
  end

  client:info("Creating commands...")

  i = 1
  for _, command in pairs(commands) do
    if command.getSlashCommand then
      client:info(string.format("Creating slash command #%s - %s", i, command.__name))
      client:createGlobalApplicationCommand(command.getSlashCommand(tools))
      i = i + 1
    end
    if command.getMessageCommand then
      client:info(string.format("Creating message command #%s - %s", i, command.__name))
      client:createGlobalApplicationCommand(command.getMessageCommand(tools))
      j = j + 1
    end
  end

  client:info("Done!")
end

local function hasTsihMention(message)
  local content = message.content:lower()
  return content:find("tsih") or content:find("nora")
end

local function executeCommand(commandName, message)
  local cmd = commands[commandName](message, client)
  local ok, err = pcall(cmd.execute, cmd, message, client)
  stackTrace:sendErrorMessage(message, ok, err)
end

local function executeSlashCommand(commandName, interaction, args, command)
  local cmd = commands[commandName](interaction, client, args, command)
  local ok, err = pcall(cmd.executeSlashCommand, cmd, interaction, client, args, command)
  if not ok then client:error(err) interaction:reply(stackTrace:getEmbededMessage(err), true) end
end



client:on("ready", function()
  client:info("I'm currently in " .. #client.guilds .. " servers nanora!")
  for _, guild in pairs(client.guilds) do client:info(guild.id .. ' ' .. guild.name) end

  clock:start(true)
  client:setActivity(statusTable[math.random(#statusTable)])

  client:info("💙Ready nanora!💜")
end)

client:on("messageCreate", function(message)
  if message.author.bot then return end

  if hasTsihMention(message) or math.random() <= 0.001 then
    executeCommand("randomemoji", message)
  end

  executeCommand("sauce", message)
end)

client:on("slashCommand", function(interaction, command, args)
  executeSlashCommand(command.name, interaction, args, command)
end)

client:on("messageCommand", function(interaction, command, message)
  if message then
    local ok, err = pcall(commands[command.name:gsub("Send ", '')].executeMessageCommand, interaction, command, message)
    stackTrace:sendErrorMessage(interaction, ok, err)
  else
    interaction:reply("Failed to use command!\nMaybe I don't have access to the channel nanora?")
    timer.setTimeout(5000, wrap(interaction.deleteReply), interaction, interaction.getReply)
  end
end)

clock:on("min", function()
  client:getChannel('990188076473147404'):send('a') -- delete this line if you're not unlucky like me
  client:setActivity(statusTable[math.random(#statusTable)])
end)

clock:on("hour", function(now)
  if now.hour == 21 then
    local ok, err = true, nil
    client:info("Tsih O'Clock")
    local cmd = commands["tsihoclock"]
    ok, err = pcall(cmd.executeWithTimer, cmd)
    if not ok then client:error(err) end
  end
end)

do
  local file = io.open("data/token.txt", "r")
  if not file then error("token.txt not found in ./data/") end
  local token = file:read("a")
  file:close()
  client:run('Bot ' .. token)
  if args[2] then initializeCommands() end
end
