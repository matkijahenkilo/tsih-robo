---@type discordia
local discordia     = require("discordia")
local tools         = require("discordia-slash").util.tools()
local timer         = require("timer")
local utils         = require("utils")
local fs            = require("fs")
local json          = require("json")
local client        = discordia.Client():useApplicationCommands()
local clock         = discordia.Clock()
local statusTable   = utils.statusTable
local stackTrace    = utils.StackTrace(client)
local wrap          = coroutine.wrap
local commandsTable = {}
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
  commandsTable = setmetatable(require("commands"), commandsMetaTable)
end

local function initializeCommands()
  client:info("Bot was opted to reset all global commands~")
  local i, j = 1, 1
  for commandId in pairs(client:getGlobalApplicationCommands()) do
    client:info("Deleting command #%s", i)
    client:deleteGlobalApplicationCommand(commandId)
    i = i + 1
  end

  client:info("Creating commands...")

  i = 1
  for _, command in pairs(commandsTable) do
    if command.getSlashCommand then
      client:info("Creating slash command #%s - %s", i, command.__name)
      client:createGlobalApplicationCommand(command.getSlashCommand(tools))
      i = i + 1
    end
    if command.getMessageCommand then
      client:info("Creating message command #%s - %s", i, command.__name)
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

local function executeCommand(cmdName, message)
  local cmd = commandsTable[cmdName](message, client)
  local ok, err = pcall(cmd.execute, cmd)
  stackTrace:log(nil, ok, err)
end

local function executeSlashCommand(cmdName, interaction, args, command)
  local cmd = commandsTable[cmdName](interaction, client, args, command)
  local ok, err = pcall(cmd.executeSlashCommand, cmd)
  stackTrace:log(interaction, ok, err)
end



client:on("ready", function()
  client:info("I'm currently in %s servers nanora!", #client.guilds)
  for _, guild in pairs(client.guilds) do client:info('%s %s', guild.id, guild.name) end

  clock:start(true)
  client:setActivity(statusTable[math.random(#statusTable)])

  client:info("💙Ready nanora!💜")
end)

client:on("messageCreate", function(message)
  if message.author.bot then return end

  if hasTsihMention(message) or math.random() <= 0.001 then
    executeCommand("randomemoji", message)
  end

  if message.content:find("tsih pls") then
    local args = message.content:split(" ")
    if args[1] == "tsih" and args[2] == "pls" then
      message.channel:getMessagesBefore(message.id, (args[3] and type(tonumber(args[3])) == "number") and tonumber(args[3]) or 1):forEach(function (msg)
        local cmd = commandsTable["sauce"](message, client, nil, msg, true)
        local ok, err = pcall(cmd.executeMessageCommand, cmd)
        stackTrace:log(interaction, ok, err)
      end)
    end
  else
    executeCommand("sauce", message)
  end
end)

client:on("slashCommand", function(interaction, command, args)
  executeSlashCommand(command.name, interaction, args, command)
end)

client:on("messageCommand", function(interaction, command, message)
  if message then
    local cmd = commandsTable[command.name](interaction, client, nil, message)
    local ok, err = pcall(cmd.executeMessageCommand, cmd)
    stackTrace:log(interaction, ok, err)
  else
    interaction:reply("Failed to use command!\nMaybe I don't have access to the channel nanora?", true)
    timer.setTimeout(5000, wrap(interaction.deleteReply), interaction, interaction.getReply)
  end
end)

clock:on("min", function()
  client:getChannel('990188076473147404'):send('a') -- delete this line if you're not unlucky like me
  client:setActivity(statusTable[math.random(#statusTable)])
end)

clock:on("hour", function(now)
  if now.hour == 21 then
    client:info("Tsih O'Clock!")
    local cmd = commandsTable["tsihoclock"](nil, client)
    local ok, err = pcall(cmd.executeWithTimer, cmd)
    stackTrace:log(nil, ok, err)
  end
end)

do
  --clear ./temp/ folder completely if ./data/persistentDownload.lua is returning false
  if not require("data/persistentDownload") then
    local folder = "./temp/%s/"
    local tempFolder = fs.readdirSync("./temp/")
    for _, content in ipairs(tempFolder) do
      local fullPath = folder:format(content)
      local thingy = fs.statSync(fullPath)
      if thingy.type == 'file' then -- rm temp/file
        fs.unlinkSync(fullPath)
      elseif thingy.type == 'directory' then -- rm -r temp/folder
        local subFolder = folder:format(content)
        for _, file in ipairs(fs.readdirSync(subFolder)) do
          fs.unlinkSync(subFolder..file)
        end
        fs.rmdir(subFolder)
      end
    end
  end

  --[[ config.json structure:
    [
      {
        "name": "main profile",
        "token": "asd123"
      },
      {
        "name": "fucking test",
        "token": "fgh456"
      }
    ]
  --]]
  local bots = json.decode(fs.readFileSync("data/config.json"))
  local bot = bots[1]
  client:run('Bot ' .. bot.token)
  if args[2] then initializeCommands() end
end
