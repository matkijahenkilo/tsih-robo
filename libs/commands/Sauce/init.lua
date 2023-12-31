local discordia = require("discordia")
local limitHandler = require("./limitHandler")
local Gallerydl = require("./Gallerydl")
local SauceSender = require("./SauceSender")
local LinkParser = require("./LinkParser")
local timer = require("timer")
local utils = require("utils")
local StackTrace = utils.StackTrace
local Command = utils.Command
local PermissionsParser = utils.PermissionParser
discordia.extensions()

local Sauce = discordia.class("Sauce", Command)

function Sauce:__init(message, client, args, previousMsg)
  Command.__init(self, message, client, args)
  self._previousMsg = previousMsg
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
  if sauceSender.gallerydl.linkParser:linkDoesNotRequireDownload() then

    sauceSender:sendImageLink()

  elseif sauceSender.gallerydl.linkParser:linkRequireDownload() then

    sauceSender:downloadSendAndDeleteImages()

  end
end

---@param message Message
---@param interaction Interaction|nil
local function sendSauce(self, message, interaction)
  local wasCommand = interaction and true or false
  local parser = LinkParser(message, wasCommand)
  local info = parser:getinfo()

  if not info then return end

  local condition = specificLinkCondition

  if wasCommand then
    condition = anyLinkCondition
  end

  for _, link in ipairs(info.words) do
    if condition(link) then
      coroutine.wrap(function()

        parser.link = link

        if not wasCommand then -- ignore blacklisted links if function call was automated
          if parser:linkShouldBeIgnored() then return end
        end

        local gdl = Gallerydl(parser, message.channel.id, info.limit)
        local sauceSender = SauceSender(message, gdl, info.multipleLinks)

        local ok, err

        if not wasCommand then
          ok, err = pcall(findLinksToSend, sauceSender)
        else
          --always download content to send if function called as message command
          ok, err = pcall(sauceSender.downloadSendAndDeleteImages, sauceSender)
        end

        if not ok then
          StackTrace(self._client, info.multipleLinks):log(interaction, ok, err)
        end

      end)()
    end
  end
end

function Sauce:executeMessageCommand()
  local previousMessage = self._previousMsg
  local interaction = self._message
  if hasHttps(previousMessage.content) then
    coroutine.wrap(function ()
      previousMessage:addReaction('🆗')
      timer.sleep(2000)
      previousMessage:removeReaction('🆗')
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
  local pp = PermissionsParser(interaction, self._client)

  if pp:unavailableGuild() then
    interaction:reply(pp.replies.lackingGuild, true)
    return
  end

  if not pp:manageMessages() or not pp:owner() then
    interaction:reply(pp.replies.lackingManageMessagesOrOwner, true)
    return
  end

  if args.global then
    if not pp:admin() or not pp:owner() then
      interaction:reply(pp.replies.lackingAdminOrOwner, true)
      return
    end
    limitHandler.setSauceLimitOnServer(interaction, args.global)
    interaction:reply(string.format("I will now send up to %s images around this server nanora!", args.global.limit))
  elseif args.channel then
    limitHandler.setSauceLimitOnChannel(interaction, args.channel)
    interaction:reply(string.format("I will now send up to %s images in this channel nanora!", args.channel.limit))
  end
end

function Sauce.getSlashCommand(tools)
  --TODO: config deletion/reset
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