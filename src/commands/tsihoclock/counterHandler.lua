local FILE_JSON = "src/data/tsihclockcounter.json"

local json = require("json")
local fs = require("fs")

local M = {}

local function setNewTotal(newTotal)
  local rawJson = fs.readFileSync(FILE_JSON)
  if rawJson then
    local t = json.decode(rawJson)
    t["total"] = newTotal or 1
    fs.writeFileSync(FILE_JSON, json.encode(t))
  else
    fs.writeFileSync(FILE_JSON, json.encode({ total = 1 }))
  end
end

function M.getCurrentCounter()
  local rawJson = fs.readFileSync(FILE_JSON)
  if rawJson then
    return json.decode(rawJson).total
  else
    return "ニール"
  end
end

function M.incrementTsihOClockCounter()
  local total = M.getCurrentCounter()
  if total then
    total = total + 1
  end
  setNewTotal(total)
end

return M
