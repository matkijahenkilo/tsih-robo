local signHandler = require("../classes/tsihoclock/SignHandler")
local imageHandler = require("../classes/tsihoclock/ImageSenderHandler")

local functions = {
  sign   = signHandler.sign,
  unsign = signHandler.remove,
  manual = imageHandler.tsihClockSlash
}

return {
  getSlashCommand = function(tools)
    return tools.slashCommand("tsihoclock", "For signing text channels to receive daily Tsih artworks nanora!")
        :addOption(
          tools.subCommand("sign", "When used, I'll send a random artwork of me here everyday at 9PM nanora!")
        )
        :addOption(
          tools.subCommand("unsign", "I will not send artworks here anymore if used nora!")
        )
        :addOption(
          tools.subCommand("manual", "I'll manually send a random artwork nora!")
          :addOption(
            tools.string("format", "You can specify if I send a gif or an image nora!")
            :addChoice(tools.choice("gif", "gif"))
            :addChoice(tools.choice("image", "image"))
          )
        )
        :addOption(
          tools.subCommand("auto", "For the strongest, nanora.")
        )
  end,
  executeSlashCommand = function(interaction, command, args, client)
    local commandName = command.options[1].name;
    local format;
    if args.manual then
      format = args.manual.format
    end

    if commandName == "auto" then
      if client.owner.id == interaction.user.id then
        interaction:reply("Oki nanora!", true);
        imageHandler.sendAllTOC(client);
      else
        interaction:reply("👁️〰️👁️", true);
      end
    else
      functions[commandName](interaction, format);
    end
  end,
  executeWithTimer = function(client)
    imageHandler.sendAllTOC(client);
  end,
};
