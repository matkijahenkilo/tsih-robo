local ErrorHandler = require("discordia").class("ErrorHandler")
local timer = require("timer")

function ErrorHandler:__init(discordia, client)
  self._discordia = discordia
  self._client = client
end

function ErrorHandler:sendErrorMessage(message, ok, err)
  if not ok then
    local discordia = self._discordia
    local client = self._client
    local msg = message:reply({
      embed = {
        title = "I stumbled...",
        fields = {
          {
            name = string.format("Please send this horrible mistake to %s!", client.owner.username, err),
            value = string.format("This message will auto-delete itself in 30 seconds.\n```\n%s```", err)
          }
        },
        timestamp = discordia.Date():toISO('T', 'Z'),
        color = 0x0000ff
      }
    })
    timer.setTimeout(30000, coroutine.wrap(msg.delete), msg)
  end
end

return ErrorHandler