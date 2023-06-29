local emojiHandler = require("./emojiServerHandler")

local function getRandomServer(client)
  local idList = emojiHandler.getIds()
  return client:getGuild(idList[math.random(#idList)])
end

return {
  getSlashCommand = function(tools)
    return tools.slashCommand("emojiserver", "Do you allow me to use this server's emojis to random react messages nora? ")
        :addOption(
          tools.boolean("allow", "If you set true, I'll be able to randomly use your server's emoji nora! Otherwise I'll not!")
          :setRequired(true)
        )
  end,

  executeSlashCommand = function(interaction, _, arg)
    if arg.allow then
      if emojiHandler.addServer(interaction.guild.id) then
        interaction:reply("Nyahahaha! Now I can use this server's emojis to annoy everyone else nanora!")
      else
        interaction:reply("Nyuuu~ Server is already added nanora!")
      end
    else
      if emojiHandler.removeServer(interaction.guild.id) then
        interaction:reply("How can I now annoy Nanako in other servers nanora!?")
      else
        interaction:reply("But your server is not even saved nanora!")
      end
    end
  end,

  execute = function (message, client)
    local server = nil
    local limit = 0

    repeat
      server = getRandomServer(client)
      if limit >= 100 then return end
      limit = limit + 1
    until server and server.emojis

    local emoji = server.emojis:random()
    if not emoji then return end
    message:addReaction(emoji)
  end
};
