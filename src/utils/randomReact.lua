local M = {};

function M.sendRandomReaction(message, guild)
    local customEmoji = guild[math.random(#guild)].emojis:random();
    message:addReaction(customEmoji);
end

return M;