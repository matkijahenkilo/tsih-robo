local json = require("json")
local fs = require("fs")

local M = {}

M.IdsPath = "src/data/tsihclockids.json"

local function registrationExists(t, id)
  if t[1] then
    for _, value in ipairs(t) do
      if value.id == id then
        return true
      end
    end
  end
  return false
end

local function isInGuild(interaction)
  if not interaction.guild then
    interaction:reply("This function only works within servers nanora!", true)
    return false
  end
  return true
end

function M.sign(interaction)
  if not isInGuild(interaction) then return end

  local ids = fs.readFileSync(M.IdsPath)
  local id = interaction.channel.id
  local guildName = interaction.guild.name
  local t = {}

  if ids then
    t = json.decode(ids)
  end

  if registrationExists(t, id) then
    interaction:reply("Room is already signed for Tsih O'Clock!")
    return
  end

  table.insert(t, { id = id, guildName = guildName })
  fs.writeFileSync(M.IdsPath, json.encode(t))

  interaction:reply("This room is now signed for Tsih O'Clock nanora!")
end

function M.remove(interaction)
  if not isInGuild(interaction) then return end

  local id = interaction.channel.id
  local ids = fs.readFileSync(M.IdsPath)

  if ids then
    local t = json.decode(ids)
    for key, value in pairs(t) do
      if value.id == id then
        table.remove(t, key)
        fs.writeFileSync(M.IdsPath, json.encode(t))
        interaction:reply("Ugeeeh! You won't be seeing my artworks here anymore nanora!")
        return
      end
    end
  end

  interaction:reply("B-but this room isn't even signed up nora!")
end

return M