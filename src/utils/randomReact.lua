local M = {};

function M.sendRandomReaction(message, guild)
    local emojiGuild = guild[math.random(#guild)]
    if not emojiGuild or not emojiGuild.emojis then return end
    local emoji = emojiGuild.emojis:random()
    message:addReaction(emoji);
end

return M;