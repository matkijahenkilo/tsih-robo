if not args[2] then print("please especify a token!"); return; end

local discordia     = require("discordia");
local client        = discordia.Client();
local clock         = discordia.Clock();
local settings      = require("../data/settings");
local handler       = require("./commandsHandler");
local secretHandler = require("./secretCommandsHandler");
local help          = require("./help");
local statusTable   = require("../misc/statusTable");
local randomReact   = require("../misc/randomReact");

local emoticonsServer;
local prefix = settings.prefix;
local wrap = coroutine.wrap;

discordia.extensions.string();

local function hasTsihMention(message)
  local content = message.content:lower();
  return content:find("tsih") or content:find("nora");
end

local function rollRandomReactionDice(message)
  if hasTsihMention(message) or math.random() <= 0.01 then
    randomReact.sendRandomReaction(message, emoticonsServer);
  end
end

local function executeCommand(message, args)
  if args[1]:sub(1, #prefix) == prefix then

    args[1] = args[1]:sub(#prefix + 1, -1);

    if args[1]:find("secret") and message.author.id == "206755895181312003" then
      secretHandler[args[1]].execute(message, args, client);
    else
      handler[args[1]].execute(message, args, client);
    end

  elseif args[1] == "<@" .. client.user.id .. ">" then

    help.execute(message, args);

  end
end



client:on("ready", function()
  clock:start();
  client:setActivity(statusTable[math.random(#statusTable)]);
  emoticonsServer = client:getGuild(settings.emoticonsServerId);
  print("Ready nanora!\nPrefix = ", prefix);
end)

client:on("messageCreate", function(message)
  if message.author.bot then return end
  local args = message.content:gsub('%c', ' '):split(' ');

  wrap(function () rollRandomReactionDice(message) end)();

  wrap(function () executeCommand(message, args)   end)();

  handler["sauce"].autoExecute(message);
end)

clock:on("min", function()
  client:setActivity(statusTable[math.random(#statusTable)]);
end)

clock:on("hour", function(now)
  if now.hour == 18 then
    handler["tsihClock"].executeWithTimer(client);
  end
end)

client:run('Bot ' .. args[2])
