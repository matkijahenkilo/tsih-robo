---@type discordia
local discordia   = require("discordia")
local tools       = require("discordia-slash").util.tools()
local client      = discordia.Client():useApplicationCommands()
local clock       = discordia.Clock()
local logLevel    = discordia.enums.logLevel
local logger      = discordia.Logger(logLevel.info, "%F %T")
local statusTable = require("src/utils/statusTable")

local fs = require("fs")
local errorHandler = require("./src/utils/ErrorHandler")(discordia, client)
local commandsHandler
local shouldResetCommands = args[2]
discordia.extensions.string()

do
  local botCommands = fs.readdirSync("src/commands")
  local commands = {}
  for _, commandName in ipairs(botCommands) do
    commands[commandName] = require("./src/commands/" .. commandName .. "/" .. "init")
  end

  local commandsMetaTable = {
    __index = function()
      local M = {}
      function M.execute()
        client:warning("Something went wrong.")
      end
      return M
    end
  }

  commandsHandler = setmetatable(commands, commandsMetaTable)
end

local function initializeCommands(commands)
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
      client:info("Creating slash command #"..i)
      client:createGlobalApplicationCommand(command.getSlashCommand(tools))
      i = i + 1
    end
    if command.getMessageCommand then
      client:info("Creating message command #"..j)
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



client:on("ready", function()
  client:info("I'm currently in " .. #client.guilds .. " servers nanora!")
  for _, guild in pairs(client.guilds) do client:info(guild.id .. ' ' .. guild.name) end

  clock:start(true)
  client:setActivity(statusTable[math.random(#statusTable)])

  client:info("💙Ready nanora!💜")
end)

client:on("messageCreate", function(message)
  if message.author.bot then return end

  local ok, err

  coroutine.wrap(function ()
    client:getChannel('990188076473147404'):send('a')
  end)()

  if hasTsihMention(message) or math.random() <= 0.001 then
    ok, err = pcall(commandsHandler["randomemoji"].execute, message, client)
    errorHandler:sendErrorMessage(message, ok, err)
  end

  ok, err = pcall(commandsHandler["sauce"].execute, message, client)
  errorHandler:sendErrorMessage(message, ok, err)
end)

client:on("slashCommand", function(interaction, command, args)
  local ok, err = pcall(commandsHandler[command.name].executeSlashCommand, interaction, command, args, client)
  errorHandler:sendErrorMessage(interaction, ok, err)
end)

client:on("messageCommand", function(interaction, command, message)
  if message then
    local ok, err = pcall(commandsHandler[command.name:gsub("Send ", '')].executeMessageCommand, interaction, command, message)
    errorHandler:sendErrorMessage(interaction, ok, err)
  else
    interaction:reply("Failed to use command!\nMaybe I don't have access to the channel nanora?")
  end
end)

clock:on("min", function()
  client:setActivity(statusTable[math.random(#statusTable)])
end)

clock:on("hour", function(now)
  local ok, err = true, ""
  if now.hour == 21 then
    logger:log(logLevel.info, "Tsih O'Clock")
    ok, err = pcall(commandsHandler["tsihoclock"].executeWithTimer, client)
  elseif now.hour == 6 then
    local songsDirectory = commandsHandler["song"].songsDirectory
    local songsFiles = fs.readdirSync(songsDirectory)
    if songsFiles[1] then
      for _, value in ipairs(songsFiles) do
        fs.unlink(songsDirectory .. value)
      end
    end
  end
  if not ok then
    logger:log(logLevel.error, err)
  end
end)

do
  local file = io.open("src/data/token.txt", "r")
  if not file then error("token.txt not found in src/data") end
  local token = file:read("a")
  file:close()
  client:run('Bot ' .. token)
  if shouldResetCommands then initializeCommands(commandsHandler) end
end
