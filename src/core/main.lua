if not args[2] then print("please especify a token!"); return; end

local discordia     = require("discordia");
local client        = discordia.Client();
local clock         = discordia.Clock();
local settings      = require("../data/settings");
local handler       = require("./commandsHandler");
local secretHandler = require("./secretCommandsHandler");
local help          = require("./help");
local sauce         = require("../auto/sendSauce");
local sendTsihClock = require("../commands/tsihClock").executeWithTimer;
local statusTable   = require("../misc/statusTable");
local randomReact   = require("../misc/randomReact");

local emoticonsServer;
local prefix = settings.prefix;
discordia.extensions.string();

local function hasTsihMention(str)
  local t = { "tsih", "nanora", "nora", };
  for _, tValue in ipairs(t) do
    for __, strValue in ipairs(str) do
      if strValue:lower():find(tValue) then
        return true;
      end
    end
  end
  return false;
end

local function rollRandomReactionDice(message, args)
  if hasTsihMention(args) then
    randomReact.sendRandomReaction(message, emoticonsServer);
  elseif math.random() <= 0.01 then
    randomReact.sendRandomReaction(message, emoticonsServer);
  end
end

local function isSauceCommand(message, args)
  if message.content:find("https://") then
    sauce.sendSauce(message);
  elseif args[1]:find("setsaucelimit") then
    sauce.setSauceLimit(message);
    return true;
  end
  return false;
end

local function checkForCommand(message, args)
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
  client:setGame(statusTable[math.random(#statusTable)]);
  emoticonsServer = client:getGuild(settings.emoticonsServerId);

  print("Ready nanora!\nPrefix = ", prefix);
end)

client:on("messageCreate", function(message)
  if message.author.bot then return end
  local args = message.content:gsub('%c', ' '):split(' ');

  rollRandomReactionDice(message, args);
  if not isSauceCommand(message, args) then
    checkForCommand(message, args);
  end
end)

clock:on("min", function()
  client:setGame(statusTable[math.random(#statusTable)]);
end)

clock:on("hour", function(now)
  if now.hour == 18 then
    sendTsihClock(client);
  end
end)

client:run('Bot ' .. args[2])