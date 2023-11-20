local ErrorHandler = require("discordia").class("ErrorHandler")

function ErrorHandler:__init(discordia, client)
  self._discordia = discordia
  self._client = client
end

function ErrorHandler:sendErrorMessage(message, ok, err)
  if not ok then
    local discordia = self._discordia
    local client = self._client
    message:reply({
      embed = {
        title = "I stumbled...",
        fields = {
          {
            name = string.format("Please send this horrible mistake to %s!", client.owner.username, err),
            value = string.format("```\n%s```", err)
          }
        },
        timestamp = discordia.Date():toISO('T', 'Z'),
        color = 0x0000ff
      }
    })
  end
end

return ErrorHandler