local function sendMessage(interaction, user)
  if not user then
    interaction:reply {
      embed = {
        title = "Your avatar nanora!",
        fields = {
          { name = "What a lazy adult!", value = "They look like holding a lot of shiny stars..." },
        },
        image = { url = interaction.member.user:getAvatarURL(1024) },
        color = 0xff80fd,
      },
    };
  else
    interaction:reply {
      embed = {
        title = user.name .. "'s avatar nanora!",
        fields = {
          { name = "How beautiful nanora...", value = "ｶﾜ(・∀・)ｲｲ!!" },
        },
        image = { url = user:getAvatarURL(1024) },
        color = 0xff80fd,
      },
    };
  end
end

return {
  getSlashCommand = function(tools)
    return tools.slashCommand("avatar", "I send your or somebody else's avatar nanora!")
        :addOption(
          tools.user("user", "Somebody else's avatar")
        )
  end,
  executeSlashCommand = function(interaction, command, args, client)
    if command.parsed_options == nil then
      sendMessage(interaction);
    else
      sendMessage(interaction, client:getUser(command.parsed_options.user.id));
    end
  end
};
