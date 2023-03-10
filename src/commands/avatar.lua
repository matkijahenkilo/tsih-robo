local function sendMessage(interaction, args)
  local avatarLink;
  if not args then
    avatarLink = interaction.member or interaction.user;
    avatarLink = avatarLink:getAvatarURL(1024);
  else
    avatarLink = args.member or args.user;
    avatarLink = avatarLink:getAvatarURL(1024);
  end

  interaction:reply {
    embed = {
      title = "Your avatar nanora!",
      fields = {
        { name = "What a lazy adult!", value = "They look like holding a lot of shiny stars..." },
      },
      image = { url = avatarLink },
      color = 0xff80fd,
    },
  };
end

return {
  getSlashCommand = function(tools)
    return tools.slashCommand("avatar", "I send your or somebody else's avatar nanora!")
        :addOption(
          tools.user("user", "Somebody else's avatar")
        )
  end,
  executeSlashCommand = function(interaction, _, args)
    sendMessage(interaction, args);
  end
};
