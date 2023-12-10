local limitHandler = require("./limitHandler")
local Gallerydl = require("./Gallerydl")
local SauceSender = require("./SauceSender")
local analyser = require("./linkAnalyser")
local timer = require("timer")
local format = string.format
local discordia = require("discordia")
local Command = require("utils").Command
local permissionsEnum = discordia.enums.permission
discordia.extensions()

local Sauce = discordia.class("Sauce", Command)

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

        local gdl = Gallerydl(link, message.channel.id, info.limit)
        local sauceSender = SauceSender(message, gdl, info.multipleLinks)

        local ok, err

        if wasCommand then -- always download content if function called as message command
          ok, err = sauceSender:downloadSendAndDeleteImages()
        else
          findLinksToSend(sauceSender)
        end

        if not ok and wasCommand and type(interaction) == "table" then
          interaction:reply(err, true)
        end
      end)()
    end
  end
end

function Sauce:executeMessageCommand(interaction, _, message)
  if hasHttps(message.content) then
    coroutine.wrap(function ()
      interaction:reply(format("Fixing a message's content nora..."))
      --deletes the reply after 10 seconds
      timer.setTimeout(10000, coroutine.wrap(interaction.deleteReply), interaction, interaction.getReply)
    end)()
    sendSauce(message, interaction)
  else
    interaction:reply("This message has no links nanora!", true)
  end
end

function Sauce:execute(message)
  if hasHttps(message.content) then
    sendSauce(message, nil)
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
  return tools.messageCommand("Send sauce")
end

return Sauce