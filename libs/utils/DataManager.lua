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
  self._commandName = commandName
  self._key = nil
  verifyFile()
end

---@return table
function DataManager:readFile()
  return json.decode(fs.readFileSync(STORAGE))
end

---@return any
function DataManager:readData()
  local t = json.decode(fs.readFileSync(STORAGE))[self._commandName]
  local k = self._key
  if not t then return {} end
  return k and (t[k] or {}) or t
end

---@param v table
function DataManager:writeData(v)
  if not v or type(v) ~= "table" then
    error("No value was set or value isn't a table.")
    return
  end

  local n = self._commandName
  local k = self._key
  local t = DataManager:readFile()

  if not t[n] then t[n] = {} end

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