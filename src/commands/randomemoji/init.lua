local emojiHandler = require("./emojiServerHandler")
local logger = require("discordia").Logger(3, "%F %T", "randomemoji.log")

local function getRandomServer(client)
  local idList = emojiHandler.getIds()
  if not idList then return nil end
  local id = idList[math.random(#idList)]
  return client:getGuild(id), id
end

return {
  getSlashCommand = function(tools)
    return tools.slashCommand("randomemoji", "Do you allow me to use this server's emojis to random react messages nora? ")
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

  execute = function(message, client)
    local server, id = nil, nil
    local limit = 0
    local emoji

    repeat
      repeat
        server, id = getRandomServer(client)
        if limit >= 100 then
          logger:log(2, "Emoji fetch limit just hit 100. Last guild id fetched: %s", id)
          return
        end
        limit = limit + 1
      until server and server.emojis
      emoji = server.emojis:random()
    until emoji

    local ok = message:addReaction(emoji)

    if ok then
      logger:log(3, "emoji : '%s' to %s in '%s', '%s' (took %s tries)",
        emoji.name,
        message.author.name,
        essage.guild.name,
        message.channel.name,
        limit
      )
    else
      logger:log(1, "emoji : Failed to send emoji '%s'", emoji.name)
    end
  end
}
