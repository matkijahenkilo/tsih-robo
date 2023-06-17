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

do
  local conn = sql.open("NanakosStolenDataBase")
  conn[[
    CREATE TEMP TABLE t(
      id INTEGER PRIMARY KEY,
      id2 TEXT,
      id3 TEXT,
      id4 TEXT
    )
  ]]

  local statement = conn:prepare("INSERT INTO t(id2, id3, id4) VALUES(?, ?, ?)")
  for i = 1, 5, 1 do
    statement:reset()
    statement:bind(200*i, nil, "jesus")
    statement:step()
    p(conn:exec("SELECT * FROM t"))
    print('\n')
  end

  local select = conn:exec("SELECT * FROM t")
  for index, value in ipairs(select) do
    p(index,value)
  end

  p(getColumnsNames(select))

  conn:exec(format("INSERT INTO t(%s) VALUES ('nice','nice','nice')", getColumnsNames(select)))

  for index, value in ipairs(conn:exec("SELECT * FROM t")) do
    p(index,value)
  end

  conn:close()
end

return sqlite