local commands = {
  secretshutdown = require("../secretCommands/shutdown");
}

local commandsMetaTable = {
  __index = function ()
    local M = {};
    function M.execute(message) message:addReaction("👀") end
    return M;
  end
}

return setmetatable(commands, commandsMetaTable)