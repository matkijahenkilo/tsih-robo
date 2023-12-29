local MESSAGE_TIMEOUT = 30000
local SAUCE_ASSETS = "assets/images/sauce/"
local FOOTER_ICON = "tsih-icon.png"
local THUMBNAIL_ICON = "tsih-robo.png"

local discordia = require("discordia")
local logEnum = discordia.enums.logLevel
local logger = discordia.Logger(3, "%F %T", "stackTrace.log")
local time = discordia.Time(MESSAGE_TIMEOUT)
local wrap = coroutine.wrap

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
          value = string.format("This message *might* auto-delete itself after %s seconds.\n```\n%s```",
            time:toSeconds(),
            err
          )
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

function StackTrace:log(interaction, ok, err)
  if not ok then
    if interaction and discordia.class.type(interaction) == "Interaction" then
      wrap(function()
        local _, ok2, err2 = interaction:reply(getEmbededMessage(self, err), true)
        if not ok2 then print(ok2, err2) end
      end)()
      err = string.format("%s (StackTrace got posted in channel as ephemeral message)", err)
    end
    logger:log(logEnum.error, err)
  end
end

return StackTrace