local utils = require("utils")
local omori = utils.omori
local Command = utils.Command
local Hug = require("discordia").class("Hug", Command)

local answer = {
  "The heck you doing to me?!",
  "Stop it you weirdo!",
  "Nyuu... くさいのら!",
  "I will smash you nanora!!",
  "Don't just hug me all of sudden nora!",
}

function Hug:__init(message, client, args)
  Command.__init(self, message, client, args)
end

function Hug.getSlashCommand(tools)
  return tools.slashCommand("hug", "You hug a kiddo!")
end

function Hug:executeSlashCommand()
  local message = self._message
  message:reply {
    content = answer[math.random(1, #answer)],
    file = omori.getOmoriReactionGif(2, math.random(0, 2))
  }
end

return Hug