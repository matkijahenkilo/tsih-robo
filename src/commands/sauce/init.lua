local limitHandler = require("./limitHandler")
local SauceSender = require("./SauceSender")
local analyser = require("./linkAnalyser")
local timer = require("timer")
local format = string.format
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

local function findLinksToSend(sauceSender)
  local link = sauceSender.link
  if analyser.linkDoesNotRequireDownload(link) then

    sauceSender:sendImageLink()

  elseif analyser.linkRequireDownload(link) then

    sauceSender:downloadSendAndDeleteImages()

  end
end

---@param message Message
---@param interaction Interaction | nil
local function sendSauce(message, interaction)
  local wasCommand = interaction and true or false
  local info = analyser.getinfo(message, wasCommand)

  if not info then return end

  local condition = specificLinkCondition

  if wasCommand then
    condition = anyLinkCondition
  end

  for _, link in ipairs(info.words) do
    if condition(link) then
      coroutine.wrap(function()

        if not wasCommand then -- ignore blacklisted links if function call was automated
          if analyser.linkShouldBeIgnored(link) then return end
        end

        local sauceSender = SauceSender(message, link, info)
        local ok, err

        if wasCommand then -- always download content if function called as message command
          ok, err = sauceSender:downloadSendAndDeleteImages()
        else
          findLinksToSend(sauceSender)
        end

        if wasCommand and type(interaction) == "table" and not ok then
          interaction:reply(err, true)
        end
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
    if hasHttps(message.content) then
      coroutine.wrap(function ()
        interaction:reply(format("%s wants me to send this message's contents!", message.author.name))
        --deletes the reply after 10 seconds
        timer.setTimeout(10000, coroutine.wrap(interaction.deleteReply), interaction, interaction.getReply)
      end)()
      sendSauce(message, interaction)
    else
      interaction:reply("This message has no links nanora!", true)
    end
  end,

  execute = function(message)
    if hasHttps(message.content) then
      sendSauce(message, nil)
    end
  end,
}