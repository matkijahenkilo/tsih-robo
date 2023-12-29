local Command = require("discordia").class("Command")

function Command:__init(message, client, args)
  self._message = message
  self._client = client
  self._args = args
end

return Command