local limitHandler = require("./limitHandler")
local SauceSender = require("./SauceSender")
local analyser = require("./linkAnalyser")
local constants = require("./constants")
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

  elseif link:find(constants.TWITTER_LINK) or link:find(constants.TWITTER_LINK2) then

    if not sauceSender:sendTwitterVideoLink() then
      sauceSender:sendTwitterImages()
    end

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

        if analyser.linkShouldBeIgnored(link) then return end

        local sauceSender = SauceSender(message, link, info)
        local ok, err

        if wasCommand then
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

--[[ this function is way beyong my skill level, so I'll let it away from the code for now
--this entire function should reply as emphemeral
local function fixPreviousLinks(interaction, argument, isInteraction)
  local lastChannelMsg = interaction.channel:getLastMessage()
  local notFixed = true
  local count = 1
  local limit = 1
  local oldMsgs = interaction.channel:getMessagesBefore(lastChannelMsg.id, 100):toArray("id")

  if type(argument) == "table" then
    limit = argument.fix_previous_links.limit
  else
    if argument then
      limit = tonumber(argument) or 1
      if limit < 0 or limit > 20 then
        limit = 1
      end
    end
  end

  interaction:reply(string.format("Fixing the %s previous message's links nanora!", limit), true)

  for i = #oldMsgs, 1, -1 do
    if count > limit then break end
    local msg = oldMsgs[i]
    if hasHttps(msg.content) and not msg.author.bot then
      sendSauce(msg, isInteraction and interaction or nil)
      notFixed = false
      count = count + 1
    end
  end

  if notFixed then
    interaction:reply("I couldn't get any messages to fix nora!", true)
  end
end
]]

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
        --[[ this is unreliable
        :addOption(
          tools.subCommand("fix_previous_links", "I'll fix the messages before this interaction nora!")
            :addOption(
              tools.integer("limit", "I will get n number of previous messages before this command nora.")
              :setMinValue(1)
              :setMaxValue(20)
              :setRequired(true)
            )
        )
        ]]--
  end,

  getMessageCommand = function(tools)
    return tools.messageCommand("Send sauce")
  end,

  executeSlashCommand = function(interaction, _, args)
    --[[if args.fix_previous_links then
      fixPreviousLinks(interaction, args, true)
      return
    end]]--

    if args.global then
      limitHandler.setSauceLimitOnServer(interaction, args.global)
    else
      limitHandler.setSauceLimitOnChannel(interaction, args.channel)
    end
  end,

  executeMessageCommand = function (interaction, _, message)
    if hasHttps(message.content) then
      coroutine.wrap(function ()
        interaction:reply(format("%s wants me to send this message's contents nanora!", message.author.name))
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

  executeAsFavor = function (message)
    message:reply("Not now nora.")
    --local args = message.content:split(" ")
    --fixPreviousLinks(message, args[3], true)
  end
}
