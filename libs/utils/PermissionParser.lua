local discordia = require("discordia")
local enums = discordia.enums
local permissionsEnum = enums.permission

local PermissionParser = discordia.class("PermissionParser")

PermissionParser.replies = enums.enum {
  lackingGuild = "You are not currently in a server nanora.",
  lackingOwner = "Only my owner can use this command nora. (￣y▽,￣)╭ ",
  lackingAdminOrOwner = "Only the server's administrator and the bot's owner can use this command nanora!",
  lackingManageMessagesOrOwner = "You're either not the bot's owner or you are missing permissions to manage messages nanora!",
  lackingAdmin = "Only the server's administrator can use this command nanora!",
  lackingManageMessages = "You are missing permissions to manage messages nanora!",
}

function PermissionParser:__init(message, client)
  self._message = message
  self._client = client
end

function PermissionParser:guild()
  return self._message.guild.unavailable
end

function PermissionParser:owner()
  return self._client.owner.id == self._message.user.id
end

function PermissionParser:admin()
  return self._message.member:hasPermission(self._message.channel, permissionsEnum.administrator)
end

function PermissionParser:manageMessages()
  return self._message.member:hasPermission(self._message.channel, permissionsEnum.manageMessages)
end

return PermissionParser