local discordia = require("discordia")
local logEnum = discordia.enums.logLevel
local logger = discordia.Logger(3, "%F %T", "stackTrace.log")
local timer = require("timer")
local SAUCE_ASSETS = "assets/images/sauce/"
local FOOTER_ICON = "tsih-icon.png"
local THUMBNAIL_ICON = "tsih-robo.png"

local StackTrace = discordia.class("StackTrace")

function StackTrace:__init(client)
  self._client = client
end

local function getEmbededMessage(self, err)
  return {
    files = {
      SAUCE_ASSETS..FOOTER_ICON,
      SAUCE_ASSETS..THUMBNAIL_ICON
    },
    embed = {
      title = "I stumbled...",
      color = 0x0000ff,
      thumbnail = {
        url = "attachment://"..THUMBNAIL_ICON,
      },
      fields = {
        {
          name = string.format("Please send this horrible mistake to %s!", self._client.owner.username),
          value = string.format("This message *might* auto-delete itself after 30 seconds.\n```\n%s```", err)
        }
      },
      timestamp = discordia.Date():toISO('T', 'Z'),
      footer = {
        icon_url = "attachment://"..FOOTER_ICON,
        text = "Whoops..."
      }
    }
  }
end

local function sendStackTraceMessage(self, message, err)
  local msg = message:reply(getEmbededMessage(self, err), true)
  if not msg then return end
  timer.setTimeout(30000, coroutine.wrap(msg.delete), msg)
end

function StackTrace:log(message, ok, err)
  if not ok then
    logger:log(logEnum.error, err)
    if message then
      sendStackTraceMessage(self, message, err)
    end
  end
end

return StackTrace