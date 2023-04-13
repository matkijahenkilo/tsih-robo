local discordia   = require("discordia");
local tools       = require("discordia-slash").util.tools();
local client      = discordia.Client():useApplicationCommands();
local clock       = discordia.Clock();
local settings    = require("src/data/settings");
local statusTable = require("src/utils/statusTable");
local randomReact = require("src/utils/randomReact");

local fs = require("fs");
local wrap = coroutine.wrap;
local commandsHandler;
local emoticonsServer = {};
local shouldResetCommands = args[2];
discordia.extensions.string();

do
  local botCommands = fs.readdirSync("src/commands");
  local commands = {};
  for _, value in ipairs(botCommands) do
    local commandName = value:sub(1, value:find(".lua") - 1);
    local commandTable = require("./src/" .. "commands/" .. value);
    commands[commandName] = commandTable;
  end
  local commandsMetaTable = {
    __index = function()
      local M = {};
      function M.execute(message)
        client:warning("Something went wrong.")
      end
      return M;
    end
  };
  commandsHandler = setmetatable(commands, commandsMetaTable);
end

local function initializeCommands(commands)
  client:info("Bot was opted to reset all global commands~");
  local i = 1
  for commandId in pairs(client:getGlobalApplicationCommands()) do
    client:info("Deleting command #"..i);
    client:deleteGlobalApplicationCommand(commandId);
    i = i + 1;
  end

  client:info("Creating commands...");
  i = 1

  for _, command in pairs(commands) do
    if command.getSlashCommand then
      client:info("Creating slash command #"..i);
      client:createGlobalApplicationCommand(command.getSlashCommand(tools));
    end
    if command.getMessageCommand then
      client:info("Creating message command #"..i);
      client:createGlobalApplicationCommand(command.getMessageCommand(tools));
    end
    i = i + 1;
  end

  client:info("Done!");
end

local function hasTsihMention(message)
  local content = message.content:lower();
  return content:find("tsih") or content:find("nora");
end

local function rollRandomReactionDice(message)
  if hasTsihMention(message) or math.random() <= 0.01 then
    randomReact.sendRandomReaction(message, emoticonsServer);
  end
end



client:on("ready", function()
  client:info("I'm currently serving in " .. #client.guilds .. " servers nanora!");
  for _, guild in pairs(client.guilds) do client:info(guild.id .. ' ' .. guild.name) end

  clock:start(true);
  client:setActivity(statusTable[math.random(#statusTable)]);

  for index, id in ipairs(settings.emoticonsServers) do
    emoticonsServer[index] = client:getGuild(id);
  end

  client:info("💙Ready nanora!💜");
end)

client:on("messageCreate", function(message)
  if message.author.bot then return end
  wrap(function () rollRandomReactionDice(message) end)();
  commandsHandler["sauce"].sendSauce(message, client);
end)

client:on("slashCommand", function(interaction, command, args)
  commandsHandler[command.name].executeSlashCommand(interaction, command, args, client);
end)

client:on("messageCommand", function(interaction, command, message)
  commandsHandler[command.name:gsub("Send ", '')].executeMessageCommand(interaction, command, message);
end)

clock:on("min", function()
  client:setActivity(statusTable[math.random(#statusTable)]);
end)

clock:on("hour", function(now)
  if now.hour == 21 then
    commandsHandler["tsihoclock"].executeWithTimer(client);
  end
end)

do
  local file = io.open("src/data/token.txt", "r");
  if not file then error("token.txt not found") end
  local token = file:read("a");
  file:close();
  client:run('Bot ' .. token);
  if shouldResetCommands then initializeCommands(commandsHandler) end
end