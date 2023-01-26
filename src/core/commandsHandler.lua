local commands = {
  hello     = require("../commands/hello"),
  echo      = require("../commands/echo"),
  hug       = require("../commands/hug"),
  avatar    = require("../commands/avatar"),
  pinch     = require("../commands/pinch"),
  question  = require("../commands/question"),
  tsihClock = require("../commands/tsihClock"),
  song      = require("../commands/song2"),
  giveRole  = require("../commands/giveRole"),
  sauce     = require("../auto/sendSauce.lua"),
};

local commandsMetaTable = {
  __index = function ()
    local M = {};
    function M.execute(message)
      message.channel:send("@Tag me if you want to see my list of commands nanola~!");
    end
    return M;
  end
};

return setmetatable(commands, commandsMetaTable);
