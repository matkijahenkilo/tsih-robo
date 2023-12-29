local Command = require("utils").Command
local Avatar = require("discordia").class("Avatar", Command)

function Avatar:__init(message, client, args)
  Command.__init(self, message, client, args)
end

function Avatar.getSlashCommand(tools)
  return tools.slashCommand("avatar", "I send your or somebody else's avatar nanora!")
    :addOption(
      tools.user("user", "Somebody else's avatar")
    )
end

function Avatar:executeSlashCommand()
  local interaction, args = self._message, self._args
  local avatarLink

  if not args then
    avatarLink = interaction.member or interaction.user
  else
    avatarLink = args.member or args.user
  end

  avatarLink = avatarLink:getAvatarURL(1024)

  interaction:reply {
    embed = {
      title = "Your avatar nanora!",
      image = { url = avatarLink },
      color = 0xff80fd,
      fields = {
        { name = "What a lazy adult!", value = "They look like holding a lot of shiny stars..." },
      },
    },
  }
end

return Avatar