local discordia = require("discordia")
local utils = require("utils")
local Command = utils.Command
local PermissionParser = utils.PermissionParser
local dataManager = utils.DataManager("RoleManager")
local color = discordia.Color()

local RoleManager = discordia.class("RoleManager", Command)

function RoleManager:__init(message, client, args, command)
  Command.__init(self, message, client, args)
  self._command = command
end

local function isHex(x)
  if x == '' then return false end
  return string.byte(x) <= string.byte('f') and string.byte(x) >= string.byte('0')
end

local function deleteOldRoleFromGuildMember(interaction, member, client)
  for _, value in ipairs(member) do
    if interaction.member.id == value.userID then
      local oldRole = client:getRole(value.roleID)
      if not oldRole then return end
      oldRole:delete()
      return
    end
  end
end

---@return table
local function insertMemberInfoToTable(interaction, role, t)
  table.insert(t, {
    userID = interaction.member.id,
    roleID = role.id,
  })
  return t
end

local function replaceOldMemberInfoWithNewInfo(interaction, role, member)
  for key, value in pairs(member) do
    if not member then break end
    if value.userID == interaction.member.id then
      table.remove(member, key)
    end
  end
  return insertMemberInfoToTable(interaction, role, member)
end

local function updateJsonFile(interaction, client, role)
  dataManager.key = interaction.guild.id
  local customGuildRolesTable = dataManager:readData()

  if not customGuildRolesTable then
    customGuildRolesTable = insertMemberInfoToTable(interaction, role, {})
  else
    deleteOldRoleFromGuildMember(interaction, customGuildRolesTable, client)
    customGuildRolesTable = replaceOldMemberInfoWithNewInfo(interaction, role, customGuildRolesTable)
  end

  dataManager:writeData(customGuildRolesTable)
end

local function deleteMemberRoleAndInfoFromJson(interaction, _, client)
  dataManager.key = interaction.guild.id
  local customGuildRolesTable = dataManager:readData()

  if not customGuildRolesTable then
    interaction:reply("I yet have to create custom roles in this server nanora!", true)
    return
  end

  for index, value in ipairs(customGuildRolesTable) do
    if interaction.member.id == value.userID then
      local oldRole = client:getRole(value.roleID)
      if not oldRole then return end
      oldRole:delete()
      table.remove(customGuildRolesTable, index)
      dataManager:writeData(customGuildRolesTable)
      interaction:reply("You are now free nanora!")
      return
    end
  end

  interaction:reply("But you don't have any roles from me nanora!", true)
end

local function giveRoleToMember(interaction, command, client)
  local name = command.give.name
  local hex  = command.give.hexcolor
  if hex:find('#') then
    hex = hex:gsub('#', '')
  end

  if not isHex(hex) then
    interaction:reply("The hex value is wrong nora!", true)
    return
  end

  local role, err = interaction.guild:createRole(name)
  if not role then
    print(err)
    interaction:reply("I couldn't create your role, I might not have permissions to do this nanora!", true)
    return
  end

  updateJsonFile(interaction, client, role)

  role:setColor(color.fromHex(hex))
  interaction.member:addRole(role.id)

  interaction:reply("Done nanora! Enjoy your new role~!")
end

local functions = {
  give = giveRoleToMember,
  delete = deleteMemberRoleAndInfoFromJson
}

function RoleManager.getSlashCommand(tools)
  return tools.slashCommand("rolemanager", "I can give or delete a personalized role nora!")
    :addOption(
      tools.subCommand("give", "I'll give you a personalized role nanora!")
      :addOption(
        tools.string("name", "Your role's name nora!")
        :setRequired(true)
      )
      :addOption(
        tools.string("hexcolor", "The role's color must be in hexadecimal value, sorry nora!")
        :setRequired(true)
      )
    )
    :addOption(
      tools.subCommand("delete", "I'll delete your personalized role nanora!")
    )
end

function RoleManager:executeSlashCommand()
  local interaction, client, args, command = self._message, self._client, self._args, self._command
  local pp = PermissionParser(interaction, client)

  if pp:unavailableGuild() then
    interaction:reply(pp.replies.lackingGuild, true)
    return
  end

  functions[command.options[1].name](interaction, args, client)
end

return RoleManager