local limitHandler = require("./limitHandler")
local imageSender = require("./imageSenderHandler")
local analyser = require("./linkAnalyser")
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

local function findLinksToSend(message, info)
  if analyser.linkDoesNotRequireDownload(info.link) then

    imageSender.sendImageUrl(message, info)

  elseif analyser.linkRequireDownload(info.link) then

    imageSender.downloadSendAndDeleteImages(message, info)

  elseif info.link:find("https://twitter.com/") then

    if not imageSender.sendTwitterVideoUrl(message, info) then
      imageSender.sendTwitterImages(message, info)
    end

  end
end

local function sendSauce(message, client, interaction)
  local info = analyser.getinfo(message, client)

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
        info.link = link
        local err = action(message, info)
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
      sendSauce(message, nil, interaction)
    end
  end,

  execute = function(message, client)
    if hasHttps(message.content) then
      sendSauce(message, client, nil)
    end
  end
}
