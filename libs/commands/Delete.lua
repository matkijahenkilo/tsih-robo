local discordia = require("discordia")
local utils = require("utils")
local Command = utils.Command
local PermissionsParser = utils.PermissionParser

local Delete = discordia.class("Delete", Command)

function Delete:__init(message, client, args, oldMessage)
  Command.__init(self, message, client, args)
  self._oldMessage = oldMessage
end

function Delete.getSlashCommand(tools)
  return tools.slashCommand("delete", "I'll delete my past n messages nanora!")
    :addOption(
      tools.integer("limit", "The number of messages that I'll delete! With 1 meaning my last message sent on this channel nora.")
        :setMinValue(1)
        :setMaxValue(100)
        :setRequired(true)
    )
end

function Delete.getMessageCommand(tools)
  return tools.messageCommand("delete")
end

function Delete:executeMessageCommand()
  local interaction, client, oldMessage = self._message, self._client, self._oldMessage

  if client.user.id ~= oldMessage.author.id then
    interaction:reply("I will only delete my own messages nanora.", true)
    return
  end

  interaction:reply("Ogei, deleting this really quick nora...~", true)
  oldMessage:delete()
end

function Delete:executeSlashCommand()
  local interaction, client, args = self._message, self._client, self._args
  local limit = args.limit
  local pp = PermissionsParser(interaction, client)

  if pp:unavailableGuild() then
    interaction:reply(pp.replies.lackingGuild, true)
    return
  end

  if not pp:manageMessages() then
    if not pp:owner() then
      interaction:reply(pp.replies.lackingManageMessagesOrOwner, true)
      return
    end
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

return Delete