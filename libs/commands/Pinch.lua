local utils = require("utils")
local omori = utils.omori
local Command = utils.Command
local Pinch = require("discordia").class("Pinch", utils.Command)

function Pinch:__init(message, client, args)
  Command.__init(self, message, client, args)
end

function Pinch.getSlashCommand(tools)
  return tools.slashCommand("pinch", "You make a kiddo sad!")
end

function Pinch:executeSlashCommand()
  local interaction = self._message
  interaction:reply {
    content = "Ooow my cheek nanora!",
    file = omori.getOmoriReactionGif(3, 0)
  }
end

return Pinch