--[[
-- Please create your own customized nonDownloables.lua and
-- downloables.lua files in 'src/commands/sauce/links/'.
-- They both should return a table of strings, where the strings
-- should be links of any website compatible with gallery-dl
-- that you also wish Tsih bot to automatically send its 
-- contents when a link is sent to a text channel.
--
-- links inserted in nonDownloables.lua will make Tsih send only the images' direct link,
-- while links inserted in downloables.lua will make Tsih download and send the image(s)
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

local function isInkbunnyImage(str)
  return str:find("https://inkbunny.net/files/screen")
end

local function findLinksToSend(message, info, source)
  if analyser.linkDoesNotRequireDownload(source) then

    imageSender.sendImageLink(message, info, source)

  elseif analyser.linkRequireDownload(source) then

    imageSender.downloadSendAndDeleteImages(message, info, source)

  elseif source:find(constants.TWITTER_LINK) or source:find(constants.TWITTER_LINK2) then

    if not imageSender.sendTwitterVideoLink(message, info, source) then
      imageSender.sendTwitterImages(message, info, source)
    end

  end
end

---@param message Message
---@param interaction Interaction | nil
local function sendSauce(message, interaction)
  local wasCommand = interaction and true or false
  local info = analyser.getinfo(message, wasCommand)

  if not info then return end

  local action = findLinksToSend
  local condition = specificLinkCondition

  if wasCommand then
    action = imageSender.downloadSendAndDeleteImages
    condition = anyLinkCondition
  end

  for _, link in ipairs(info.words) do
    if condition(link) then
      coroutine.wrap(function()
        if isInkbunnyImage(link) then return end --ignore direct image link
        local ok, err = action(message, info, link)
        if wasCommand and type(interaction) == "table" and not ok then
          interaction:reply(err, true)
        end
      end)()
    end
  end
end

local function fixPreviousLinks(interaction, args, isInteraction)
  local lastChannelMsg = interaction.channel:getLastMessage()
  local notFixed = true
  local count = 1
  local limit = 1
  local oldMsgs = interaction.channel:getMessagesBefore(lastChannelMsg.id, 100):toArray("id")
  if type(args) == "table" then
    limit = args.fix_previous_links.limit
  else
    if args then
      limit = tonumber(args) or 1
      if limit < 0 or limit > 20 then
        limit = 1
      end
    end
  end

  interaction:reply(string.format("Fixing the %s previous message's links nanora!", limit))

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
        --[[:addOption(
          tools.subCommand("fix_previous_links", "I'll fix the messages before this interaction nora!")
            :addOption(
              tools.integer("limit", "I will get n number of previous messages before this command nora.")
              :setMinValue(1)
              :setMaxValue(20)
              :setRequired(true)
            )
        )]]-- this is unreliable
  end,

  getMessageCommand = function(tools)
    return tools.messageCommand("Send sauce")
  end,

  executeSlashCommand = function(interaction, _, args)
    if args.fix_previous_links then
      fixPreviousLinks(interaction, args, true)
      return
    end

    if args.global then
      limitHandler.setSauceLimitOnServer(interaction, args.global)
    else
      limitHandler.setSauceLimitOnChannel(interaction, args.channel)
    end
  end,

  executeMessageCommand = function (interaction, _, message)
    if hasHttps(message.content) then
      coroutine.wrap(function ()
        interaction:reply(format("%s wants me to send images from a link nanora!", message.author.name))
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
    local args = message.content:split(" ")
    fixPreviousLinks(message, args[3], true)
  end
}
