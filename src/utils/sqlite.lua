--lit install SinisterRectus/sqlite3

local sql = require("sqlite3")
local format = string.format

local sqlite = {}

local function getConnection()
  return sql.open("NanakosStolenDataBase")
end

local function getColumnsNames(t)
  if type(t) =="string" then
    local conn = getConnection()
    t = conn:exec("SELECT * FROM " .. t)
  end
  table.remove(t[0], 1) -- removes primary key column
  return table.concat(t[0], ", ")
end

local function concatTableForInsertion(t)
  return table.concat(t, ", ")
end


function sqlite.createTables()
  local conn = getConnection()

  conn:exec[[
    CREATE TABLE IF NOT EXISTS TsihOClockIds(
      id INTEGER PRIMARY KEY,
      roomId TEXT
    );

    CREATE TABLE IF NOT EXISTS EmoticonGuilds(
      id INTEGER PRIMARY KEY,
      guildId TEXT
    );

    CREATE TABLE IF NOT EXISTS TsihOClockCounter(
      id INTEGER PRIMARY KEY,
      automaticCount INTEGER,
      manualCount INTEGER
    );

    CREATE TABLE IF NOT EXISTS RoleIds(
      id INTEGER PRIMARY KEY,
      roleId TEXT
    );
  ]]

  conn:close()
end

---Inserts value(s) into a sqlite table
---@param tableName string
---@param value table
function sqlite.InsertGenericValue(tableName, value)
  local conn = getConnection()
  local column = getColumnsNames(tableName)
  local values = concatTableForInsertion(value)

  p(column)
  p(values)

  conn:exec(format("INSERT INTO %s(%s) VALUES(%s)",
    tableName,
    column,
    values
  ))

  conn:close()
end

return sqlite