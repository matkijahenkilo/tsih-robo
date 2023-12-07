local json = require("json")
local fs = require("fs")

local STORAGE = "data/storage.json"

local DataManager = require("discordia").class("DataManager")

---Verifies if storage.json exists. If not,
---it creates a new storage.json containing just "[]".
local function verifyFile()
  local rawJson = fs.readFileSync(STORAGE)
  if not rawJson then
    fs.writeFileSync(STORAGE, json.encode({}))
  end
end

---Constructor should receive the class' name
function DataManager:__init(commandName)
  self._commandName = commandName
  verifyFile()
end

---Pass true if you want to read the entire json file.
---Use key param to get the contents of that index
---@param entireFile boolean|nil
---@param key string|nil
---@return table
function DataManager:readData(entireFile, key)
  local t = json.decode(fs.readFileSync(STORAGE))
  return entireFile and t or key and (t[self._commandName][key] or {}) or (t[self._commandName] or {})
end

---Inserts new data into storage.json with information given by a table.
---Use key param to insert a key inside the list
---@param value table
---@param key table|nil
function DataManager:writeData(value, key)
  if not value then error("No value set") return end
  local t = DataManager:readData(true)
  if key then
    t[self._commandName][key] = value
  else
    t[self._commandName] = value
  end
  fs.writeFileSync(STORAGE, json.encode(t))
end

return DataManager