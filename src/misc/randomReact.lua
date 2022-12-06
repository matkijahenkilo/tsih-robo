local M = {}

function M.sendRandomReaction(message, myServer)
    message:addReaction(myServer.emojis:random());
end

return M;