local emojiHandler = require("./emojiServerHandler")
local logger = require("discordia").Logger(3, "%F %T", "randomemoji.log")
local permissionsEnum = require("discordia").enums.permission

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
          tools.boolean("allow", "If you set true, I'll be able to randomly use your server's emojis nora! Otherwise I'll not!")
          :setRequired(true)
        )
  end,

  executeSlashCommand = function(interaction, _, arg)
    if not interaction.member:hasPermission(interaction.channel, permissionsEnum.administrator) then
      interaction:reply("Only the server's administrator can use this command nanora!", true)
      return
    end

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
        interaction:reply("But your server is not even saved nanora!", true)
      end
    end
  end,

  execute = function(message, client)
    local guild, id = nil, nil
    local limit = 0
    local emoji

    repeat
      repeat
        guild, id = getRandomServer(client)
        if limit >= 100 then
          logger:log(2, "randomemoji: fetch limit hit 100. Last guild id fetched: %s", id)
          return
        end
        limit = limit + 1
      until guild and guild.emojis
      emoji = guild.emojis:random()
    until emoji

    local ok, err = message:addReaction(emoji)

    if ok then
      logger:log(3, "randomemoji: sent emoji '%s' after %s retries",
        emoji.name,
        limit
      )
    else
      logger:log(1, "randomemoji: Failed to send emoji '%s' - %s", emoji.name, err)
    end
  end
}
