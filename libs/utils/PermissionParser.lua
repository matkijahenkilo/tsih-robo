local discordia = require("discordia")
local enums = discordia.enums
local permissionsEnum = enums.permission
local channelType = enums.channelType

local PermissionParser = discordia.class("PermissionParser")

PermissionParser.replies = enums.enum {
  lackingGuild = "You are not currently in a server nanora.",
  lackingOwner = "Only my owner can use this command nora. (￣y▽,￣)╭",
  lackingAdminOrOwner = "Only the server's administrator and my owner can use this command nanora!",
  lackingManageMessagesOrOwner = "Either you aren't my owner or you don't have permission to manage messages nanora!",
  lackingAdmin = "Only the server's administrator can use this command nanora!",
  lackingManageMessages = "You are missing permissions to manage messages nanora!",
}

function PermissionParser:__init(message, client)
  self._message = message
  self._client = client
end

---If guild is unavailable or does not exist, it returns true.
function PermissionParser:unavailableGuild()
  local guild = self._message.guild
  return not (guild and not guild.unavailable)
end

function PermissionParser:owner()
  return self._client.owner.id == self._message.user.id
end

function PermissionParser:admin()
  if self._message.channel.type == channelType.private then return true end
  return self._message.member:hasPermission(self._message.channel, permissionsEnum.administrator)
end

function PermissionParser:manageMessages()
  if self._message.channel.type == channelType.private then return true end
  return self._message.member:hasPermission(self._message.channel, permissionsEnum.manageMessages)
end

return PermissionParser