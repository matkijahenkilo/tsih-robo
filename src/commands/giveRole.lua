local color = require("discordia").Color();
local json = require("json");
local fs = require("fs");

local emoticons = {
  "❤️",
  "💜",
  "💙",
  "🖤",
  "🤎",
  "🤍",
  "💚",
  "💛",
  "🧡",
}

local function isHex(x)
  if x == '' then return false end
  return string.byte(x) <= string.byte('f') and string.byte(x) >= string.byte('0');
end

local function isSyntaxWrong(i, j, hashtagPosition, argument)
  if not i or not j or not hashtagPosition then
    return true;
  end
  for house = 1, 6, 1 do
    local place = house + hashtagPosition;
    if not isHex(argument:sub(place, place)) then
      return true;
    end
  end
  return false;
end

local function deleteOldRoleFromGuildMember(message, member, client)
  for _, value in ipairs(member) do
    if message.author.id == value.userID then
      local oldRole = client:getRole(value.roleID);
      if not oldRole then return end
      oldRole:delete();
      return;
    end
  end
end

local function insertMemberInfoToTable(message, role, member)
  table.insert(member, {
    ["userID"] = message.author.id,
    ["roleID"] = role.id,
  });
  return member;
end

local function replaceOldMemberInfoWithNewInfo(message, role, member)
  for key, value in pairs(member) do
    if not member then break end
    if value.userID == message.author.id then
      table.remove(member, key);
    end
  end
  return insertMemberInfoToTable(message, role, member);
end

local function updateJsonFile(message, client, role)
  local customGuildRolesTable;
  local jsonInfo = fs.readFileSync("src/data/" .. message.guild.id .. ".json");
  if jsonInfo then

    customGuildRolesTable = json.decode(jsonInfo);

    if customGuildRolesTable then
      deleteOldRoleFromGuildMember(message, customGuildRolesTable, client);
    end

  end

  if not customGuildRolesTable then
    customGuildRolesTable = insertMemberInfoToTable(message, role, {});
  else
    customGuildRolesTable = replaceOldMemberInfoWithNewInfo(message, role, customGuildRolesTable);
  end

  fs.writeFileSync("src/data/" .. message.guild.id .. ".json", json.encode(customGuildRolesTable));
end

local function deleteMemberRoleAndInfoFromJson(message, client)
  local customGuildRolesTable;
  local jsonInfo = fs.readFileSync("src/data/" .. message.guild.id .. ".json");
  if jsonInfo then

    customGuildRolesTable = json.decode(jsonInfo);

    for index, value in ipairs(customGuildRolesTable) do
      if message.author.id == value.userID then
        local oldRole = client:getRole(value.roleID);
        if not oldRole then return end
        oldRole:delete();
        table.remove(customGuildRolesTable, index);
        fs.writeFileSync("src/data/" .. message.guild.id .. ".json", json.encode(customGuildRolesTable));
        message:reply("You are now free from me!");
        return;
      end
    end

  end
end

return {
  description = {
    title = "GiveRole",
    description = "Creates a custom role for you! If you already asked for one, then your role will be replaced by the new one nanora!\n"
      .. "e.g: ts!giveRole \"Average Lua enjoyer, なのら！\" #ff80fd",
    color = 0xff5080,
    fields = {
      {
        name = "[role name]",
        value = "Must be in between quotes nanora!"
      },
      {
        name = "[hex color]",
        value = "Must have the `#` character nanora!"
      },
      {
        name = "delete",
        value = "You can delete your role by writing `ts!giveRole delete` nora."
      }
    },
  },
  execute = function(message, args, client)
    if not message.guild then
      message:reply("This isn't a server nanola,,,,,");
      return;
    end

    if args[2] == "delete" then
      deleteMemberRoleAndInfoFromJson(message, client);
      return;
    end

    local argument = table.concat(args, ' ', 2);
    local i, j = argument:find("([\"'])(.-)%1");
    local hashtagPosition = argument:find("#");

    if isSyntaxWrong(i, j, hashtagPosition, argument) then
      message:reply("The syntax is wrong. Check if you're putting your name in between `\"` correctly or if the `hex` value is correct nanora!\nExample: `ts!giveRole \"nenê\" #ff80fd`");
      return;
    end

    local name = argument:sub(i + 1, j - 1);
    local hex = argument:sub(hashtagPosition, hashtagPosition + 6);

    local role, err = message.guild:createRole(name);
    if not role then
      print(err);
      message:reply("I couldn't create your role, I might not have permissions to do this nanora!");
      return;
    end

    updateJsonFile(message, client, role);

    role:setColor(color.fromHex(hex));
    message.member:addRole(role.id);

    message:reply("Done nanora! Enjoy your new role~!");
    message:addReaction(emoticons[math.random(#emoticons)]);
  end
};
