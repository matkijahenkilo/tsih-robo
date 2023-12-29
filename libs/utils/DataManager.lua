local json = require("json")
local fs = require("fs")

local STORAGE = "data/storage.json"

local DataManager, _, set = require("discordia").class("DataManager")

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
  if not commandName then
    error("Command name has to be set.")
  end
  self._commandName = commandName
  self._key = nil
  verifyFile()
end

--Returns the entire storage.json as a lua table.
---@return table
function DataManager:readFile()
  return json.decode(fs.readFileSync(STORAGE))
end


---Returns the command name's value as a lua table.
---Can be specified a return of an inner key if self._key was set.
---@return table
function DataManager:readData()
  local n = self._commandName
  local k = self._key
  local t = self:readFile()[n]
  if not t then return {} end
  return k and (t[k] or {}) or t
end

---Replaces a value from storage.json with information given by a table.
---@param v table
function DataManager:writeData(v)
  if type(v) ~= "table" then
    error("No value was set or value isn't a table.")
  end

  local n = self._commandName
  local k = self._key
  local t = self:readFile()

  if not t then
    t = {}
  end

  if k then
    t[n][k] = v
  else
    t[n] = v
  end

  fs.writeFileSync(STORAGE, json.encode(t))
end

function set.key(self, key)
  self._key = key
end

return DataManager