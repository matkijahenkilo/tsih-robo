local discordia = require("discordia")
local limitHandler = require("./limitHandler")
local Gallerydl = require("./Gallerydl")
local SauceSender = require("./SauceSender")
local analyser = require("./linkAnalyser")
local timer = require("timer")
local utils = require("utils")
local StackTrace = utils.StackTrace
local Command = utils.Command
local permissionsEnum = discordia.enums.permission
local format = string.format
discordia.extensions()

local Sauce = discordia.class("Sauce", Command)

--The third argument, args, can be both the arguments
--of the slash command, or the previous message
--where the message command "sauce" was used.
function Sauce:__init(message, client, args)
  Command.__init(self, message, client, args)
end

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
  local link = sauceSender.gallerydl.link
  if analyser.linkDoesNotRequireDownload(link) then

    sauceSender:sendImageLink()

  elseif analyser.linkRequireDownload(link) then

    sauceSender:downloadSendAndDeleteImages()

  end
end

---@param message Message
---@param previousMsg Interaction | nil
local function sendSauce(self, message, previousMsg)
  local wasCommand = previousMsg and true or false
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

        local gdl = Gallerydl(link, message.channel.id, info.limit)
        local sauceSender = SauceSender(message, gdl, info.multipleLinks)

        local ok, err

        if not wasCommand then
          ok, err = pcall(findLinksToSend, sauceSender)
        else
          --always download content to send if function called as message command
          ok, err = pcall(sauceSender.downloadSendAndDeleteImages, sauceSender)
        end

        if not ok then
          StackTrace(self._client):log(wasCommand and message or nil, ok, err)
        end

      end)()
    end
  end
end

function Sauce:executeMessageCommand()
  local interaction, previousMessage = self._message, self._args
  if hasHttps(previousMessage.content) then
    coroutine.wrap(function ()
      interaction:reply("Fixing a message's content nora...")
      --deletes the reply after 10 seconds
      timer.setTimeout(10000, coroutine.wrap(interaction.deleteReply), interaction, interaction.getReply)
    end)()
    sendSauce(self, previousMessage, interaction)
  else
    interaction:reply("This message has no links nanora!", true)
  end
end

function Sauce:execute()
  if hasHttps(self._message.content) then
    sendSauce(self, self._message, nil)
  end
end

function Sauce:executeSlashCommand()
  local interaction, args = self._message, self._args
  if not interaction.member:hasPermission(interaction.channel, permissionsEnum.manageMessages) then
    if self._client.owner.id ~= self._message.user.id then
      interaction:reply("You're either not the not the bot's owner or you are missing permissions to `manage messages` nanora!", true)
      return
    end
  end

  if args.global then
    if not interaction.member:hasPermission(interaction.channel, permissionsEnum.administrator) then
      if self._client.owner.id ~= self._message.user.id then
        interaction:reply("Only the server's administrator and the bot's owner can use this command nanora!", true)
        return
      end
    end
    limitHandler.setSauceLimitOnServer(interaction, args.global)
  else
    limitHandler.setSauceLimitOnChannel(interaction, args.channel)
  end
end

function Sauce.getSlashCommand(tools)
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
end

function Sauce.getMessageCommand(tools)
  return tools.messageCommand("sauce")
end

return Sauce