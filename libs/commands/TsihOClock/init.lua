local idHandler = require("./idHandler")
local tsihSender = require("./tsihSender")
local counterHandler = require("./counterHandler")
local discordia = require("discordia")
local Command = require("utils").Command
local permissionsEnum = discordia.enums.permission
local TsihOClock = discordia.class("TsihOClock", Command)

function TsihOClock:__init(message, client, args, command)
  Command.__init(self, message, client, args)
  self._command = command
end

local functions = {
  sign   = idHandler.sign,
  unsign = idHandler.remove,
  manual = tsihSender.tsihClockSlash
}

function TsihOClock.getSlashCommand(tools)
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
end

function TsihOClock:executeSlashCommand()
  local interaction, command, args, client = self._message, self._command, self._args, self._client

  if not interaction.member:hasPermission(interaction.channel, permissionsEnum.administrator) and not args.manual then
    interaction:reply("Only the server's administrator can use this command nanora!", true)
    return
  end

  local commandName = command.options[1].name
  local format
  if args.manual then
    format = args.manual.format
  end

  if commandName == "auto" then
    if client.owner.id == interaction.user.id then
      interaction:reply("Oki nanora!", true)
      counterHandler.incrementTsihOClockCounter()
      tsihSender.sendAllTOC(client)
    else
      interaction:reply("👁️〰️👁️", true)
    end
  else
    functions[commandName](interaction, format)
  end
end

function TsihOClock:executeWithTimer()
  counterHandler.incrementTsihOClockCounter()
  tsihSender.sendAllTOC(self._client)
end

return TsihOClock