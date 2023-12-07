local discordia = require("discordia")
local timer = require("timer")

local StackTrace = discordia.class("StackTrace")

function StackTrace:__init(client)
  self._client = client
end

function StackTrace:getEmbededMessage(err)
  return {
    embed = {
      title = "I stumbled...",
      fields = {
        {
          name = string.format("Please send this horrible mistake to %s!", self._client.owner.username),
          value = string.format("This message *might* auto-delete itself after 30 seconds.\n```\n%s```", err)
        }
      },
      timestamp = discordia.Date():toISO('T', 'Z'),
      color = 0x0000ff
    }
  }
end

function StackTrace:sendErrorMessage(message, ok, err)
  if not ok then
    local client = self._client
    local msg = message:reply({
      embed = {
        title = "I stumbled...",
        fields = {
          {
            name = string.format("Please send this horrible mistake to %s!", client.owner.username),
            value = string.format("This message *might* auto-delete itself after 30 seconds.\n```\n%s```", err)
          }
        },
        timestamp = discordia.Date():toISO('T', 'Z'),
        color = 0x0000ff
      }
    })
    if not msg then return end
    timer.setTimeout(30000, coroutine.wrap(msg.delete), msg)
  end
end

return StackTrace