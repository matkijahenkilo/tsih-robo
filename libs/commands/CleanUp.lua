local discordia = require("discordia")
local utils = require("utils")
local Command = utils.Command
local PermissionsParser = utils.PermissionParser

local CleanUp = discordia.class("CleanUp", Command)

function CleanUp:__init(message, client, args, oldMessage)
  Command.__init(self, message, client, args)
  self._oldMessage = oldMessage
end

function CleanUp.getSlashCommand(tools)
  return tools.slashCommand("cleanup", "I'll delete my past n messages nanora!")
    :addOption(
      tools.integer("limit", "The number of messages I'll delete! with 1 meaning the last sent on this channel nora.")
        :setMinValue(1)
        :setMaxValue(100)
        :setRequired(true)
    )
end

function CleanUp.getMessageCommand(tools)
  return tools.messageCommand("cleanup")
end

function CleanUp:executeMessageCommand()
  local interaction, client, oldMessage = self._message, self._client, self._oldMessage

  if client.user.id ~= oldMessage.author.id then
    interaction:reply("I will only delete my own messages nanora.", true)
    return
  end

  interaction:reply("Ogei, deleting this really quick nora...~", true)
  oldMessage:delete()
end

function CleanUp:executeSlashCommand()
  local interaction, client, args = self._message, self._client, self._args
  local limit = args.limit
  local pp = PermissionsParser(interaction, client)

  if pp:unavailableGuild() then
    interaction:reply(pp.replies.lackingGuild, true)
    return
  end

  if not pp:manageMessages() or not pp:owner() then
    interaction:reply(pp.replies.lackingAdminOrOwner, true)
    return
  end

  interaction:reply(string.format("Deleting my last %s messages nanora!", limit), true)

  local oldMsgs = interaction.channel:getMessages(100):toArray("id")
  local deletedCount = 0
  local messages = {}

  for i = #oldMsgs, 1, -1 do

    if deletedCount == limit then
      break
    end

    local msg = oldMsgs[i]

    if msg.author.id == client.user.id then
      messages[#messages+1] = msg
      deletedCount = deletedCount + 1
    end

  end

  interaction.channel:bulkDelete(messages)
end

return CleanUp