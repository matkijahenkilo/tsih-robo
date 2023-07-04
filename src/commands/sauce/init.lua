--[[
-- Please create your own customized nonDownloables.lua and
-- downloables.lua files in 'src/commands/sauce/links/'.
-- They both should return a table of strings, where the strings
-- should be URLs of any website compatible with gallery-dl
-- that you also wish Tsih bot to automatically send its 
-- contents when a link is sent to a text channel.
--
-- URLs inserted in nonDownloables.lua will make Tsih send only the images' direct URL,
-- while URLs inserted in downloables.lua will make Tsih download and send the image(s)
-- to the text channel, and delete them from the computer.
--
-- Both files should contain the following structure example:
--   return {'https://www.pixiv.net', ...etc}
--
-- See https://github.com/mikf/gallery-dl/blob/master/docs/supportedsites.md
-- for more information on which sites gallery-dl supports.
--]]
local limitHandler = require("./limitHandler")
local imageSender = require("./imageSenderHandler")
local analyser = require("./linkAnalyser")
local constants = require("src.utils.constants")
require('discordia').extensions()

local function specificLinkCondition(str)
  return str ~= ''
end

local function anyLinkCondition(str)
  return str ~= '' and str:find("https://")
end

local function hasHttps(str)
  return str and str:find("https://")
end

local function findLinksToSend(message, info, source)
  if analyser.linkDoesNotRequireDownload(source) then

    imageSender.sendImageUrl(message, info, source)

  elseif analyser.linkRequireDownload(source) then

    imageSender.downloadSendAndDeleteImages(message, info, source)

  elseif source:find(constants.TWITTER_LINK) then

    if not imageSender.sendTwitterVideoUrl(message, info, source) then
      imageSender.sendTwitterImages(message, info, source)
    end

  end
end

local function sendSauce(message, interaction)
  local info = analyser.getinfo(message)

  if not info then return end

  local action
  local condition
  local wasCommand

  if not interaction then
    action = findLinksToSend
    condition = specificLinkCondition
    wasCommand = false
  else
    action = imageSender.downloadSendAndDeleteImages
    condition = anyLinkCondition
    wasCommand = true
  end

  for _, link in ipairs(info.words) do
    if condition(link) then
      coroutine.wrap(function()
        local err = action(message, info, link)
        if wasCommand and err then interaction:reply(err, true) end
      end)()
    end
  end
end

return {
  getSlashCommand = function(tools)
    return tools.slashCommand("sauce", "Sets a limit for images I send nanora!")
        :addOption(
          tools.subCommand("channel", "Sets a limit for this channel only nanora!")
            :addOption(
              tools.integer("limit", "Default is 5 nanora! Input 0 if you don't want me to send images again nora!")
              :setMinValue(0)
              :setMaxValue(100)
              :setRequired(true)
            )
        )
        :addOption(
          tools.subCommand("global", "Sets a limit for this entire server nanora!")
            :addOption(
              tools.integer("limit", "Default is 5 nanora! Input 0 if you don't want me to send images again nora!")
              :setMinValue(0)
              :setMaxValue(10)
              :setRequired(true)
            )
        )
  end,

  getMessageCommand = function(tools)
    return tools.messageCommand("Send sauce")
  end,

  executeSlashCommand = function(interaction, _, args)
    if args.global then
      limitHandler.setSauceLimitOnServer(interaction, args.global)
    else
      limitHandler.setSauceLimitOnChannel(interaction, args.channel)
    end
  end,

  executeMessageCommand = function (interaction, _, message)
    coroutine.wrap(function () interaction:reply("Alrighty nanora! One second...", true) end)()
    if hasHttps(message.content) then
      sendSauce(message, interaction)
    end
  end,

  execute = function(message)
    if hasHttps(message.content) then
      sendSauce(message, nil)
    end
  end
}
