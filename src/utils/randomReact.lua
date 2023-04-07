local M = {};

function M.sendRandomReaction(message, emoticonServer)
    message:addReaction(emoticonServer[math.random(#emoticonServer)].emojis:random());
end

return M;
