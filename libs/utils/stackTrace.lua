local discordia = require("discordia")
local logEnum = discordia.enums.logLevel
local logger = discordia.Logger(3, "%F %T", "stackTrace.log")
local timer = require("timer")

local StackTrace = discordia.class("StackTrace")

function StackTrace:__init(client)
  self._client = client
end

function StackTrace:getEmbededMessage(err)
  return {
    embed = {
      title = "I stumbled...",
      color = 0x0000ff,
      fields = {
        {
          name = string.format("Please send this horrible mistake to %s!", self._client.owner.username),
          value = string.format("This message *might* auto-delete itself after 30 seconds.\n```\n%s```", err)
        }
      },
      timestamp = discordia.Date():toISO('T', 'Z')
    }
  }
end

local function sendStackTraceMessage(message, err)
  local msg = message:reply(StackTrace:getEmbededMessage(err))
  if not msg then return end
  timer.setTimeout(30000, coroutine.wrap(msg.delete), msg)
end

function StackTrace:log(message, ok, err)
  if not ok then
    logger:log(logEnum.error, err)
    sendStackTraceMessage(message, err)
  end
end

return StackTrace