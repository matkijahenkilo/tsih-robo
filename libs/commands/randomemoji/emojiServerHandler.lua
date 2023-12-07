local fs = require("fs")
local json = require("json")

local EMOJI_SERVERS_JSON = "data/emojiServers.json"

local M = {}

local function isServerAlreadySaved(serverId, jsonContent)
  for _, savedId in ipairs(jsonContent) do
    if savedId == serverId then
      return true
    end
  end
  return false
end

local function createJson(id)
  fs.writeFileSync(EMOJI_SERVERS_JSON, json.encode({id}));
end

local function removeId(id, jsonContent)
  for index, savedId in ipairs(jsonContent) do
    if savedId == id then
      table.remove(jsonContent, index)
      fs.writeFileSync(EMOJI_SERVERS_JSON, json.encode(jsonContent))
      return true
    end
  end
  return false
end

local function saveId(id, jsonContent)
  if not isServerAlreadySaved(id, jsonContent) then
    table.insert(jsonContent, id)
    fs.writeFileSync(EMOJI_SERVERS_JSON, json.encode(jsonContent));
    return true
  end
  return false
end

function M.removeServer(id)
  local rawJson = fs.readFileSync(EMOJI_SERVERS_JSON);

  if rawJson then
    local jsonContent = json.decode(rawJson);
    if jsonContent then
      return removeId(id, jsonContent)
    end
  end
  return false
end

function M.addServer(id)
  local rawJson = fs.readFileSync(EMOJI_SERVERS_JSON);

  if rawJson then
    local jsonContent = json.decode(rawJson);
    if jsonContent then
      return saveId(id, jsonContent)
    else
      createJson(id)
    end
  else
    createJson(id)
  end
end

function M.getIds()
  local rawJson = fs.readFileSync(EMOJI_SERVERS_JSON);
  if rawJson then
    local jsonContent = json.decode(rawJson);
    if jsonContent then
      return jsonContent
    end
  end
end

return M