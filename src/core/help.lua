local prefix = require("src/data/settings").prefix;
local commands = require("../core/commandsHandler");

local M = {}

local function sendCommandsList(message)
  local output = {};

  for key, _ in pairs(commands) do
    table.insert(output, key);
  end

  table.sort(output);

  local listOfCommands = table.concat(output, '\n');

  message.channel:send {
    embed = {
      title = "Here's my command list nanora!",
      color = 0x5080ff,
      fields = {
        {
          name = "Every syntax example should be followed by my current prefix `" .. prefix .. "` nanora!\n"
              .. "To see the details of a command, @Tag me along with the command name nanora.",
          value = listOfCommands
        }
      },
    }
  };
end

local function sendCommandDetails(message, args)
  local command = commands[args[2]];

  if not command["description"] then
    sendCommandsList(message);
    return;
  end

  local answer = command["description"];

  message.channel:send { embed = answer };
end

function M.execute(message, args)
  if not args[2] then
    sendCommandsList(message);
  elseif args[2] then
    sendCommandDetails(message, args);
  end
end

return M;
