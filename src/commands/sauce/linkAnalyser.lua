local limitHandler = require("./limitHandler")
local json = require("json")
local fs = require("fs")
local discordia = require('discordia')
discordia.extensions()

local M = {}

-- don't insert twitter into the nonDownloables list, lots of problem will come if so.
local doesNotRequireDownload        = json.decode(fs.readFileSync("src/commands/sauce/links/nonDownloables.json"))
local requireDownload               = json.decode(fs.readFileSync("src/commands/sauce/links/downloables.json"))
local blacklistIsPresent, blacklist = pcall(json.decode, fs.readFileSync("src/commands/sauce/links/blacklist.json"))

if not doesNotRequireDownload or not doesNotRequireDownload[1] then
  error("./links/nonDownloables.json does not return any string for gallery-dl to read nora.")
end

if not requireDownload or not requireDownload[1] then
  error("./links/downloables.json does not return any string for gallery-dl to read nora.")
end

if not blacklistIsPresent then
  local loglevel = discordia.enums.logLevel.warning
  discordia.Logger(loglevel, "%F %T", nil):log(loglevel, "blacklist.json is not present.")
end

local function verify(string, list)
  for _, value in pairs(list) do
    if string:find(value) then
      return true
    end
  end
  return false
end

function M.linkRequireDownload(link)
  return verify(link, requireDownload)
end

function M.linkDoesNotRequireDownload(link)
  return verify(link, doesNotRequireDownload)
end

function M.linkShouldBeIgnored(link)
  if not blacklistIsPresent then
    return nil
  end
  return verify(link, blacklist)
end

function M.isTwitterPost(link)
  return link:find("/status/")
end

function M.isTwitter(link)
  IamtheboneofmyswordSteelismybodyandfireismybloodIhavecreatedoverathousandtwitterlinksUnawareoflossNorawareofgainWithstoodpaintocreatebloodinprogrammerseyeswaitingforonesarrivalIhaveregretsThisistheonlypathunfortunatelyMywholelifewasUnlimitedTwitterWorks = {
    "https://twitter.com",
    "https://x.com",
  }
  for _, UnlimitedTwitterString in ipairs(IamtheboneofmyswordSteelismybodyandfireismybloodIhavecreatedoverathousandtwitterlinksUnawareoflossNorawareofgainWithstoodpaintocreatebloodinprogrammerseyeswaitingforonesarrivalIhaveregretsThisistheonlypathunfortunatelyMywholelifewasUnlimitedTwitterWorks) do
    if link:find(UnlimitedTwitterString) then
      return true
    end
  end
  return false
end

local function hasMultipleLinks(t)
  local count = 0
  for _, word in ipairs(t) do
    if M.linkRequireDownload(word)
      or M.linkDoesNotRequireDownload(word)
    then
      count = count + 1
      if count > 1 then return true end
    end
  end
  return false
end

---returns information about current channel's limit, message's contents, 
---and if the message has multiple links in it.
---@param message Message
---@param isCommand boolean
---@return table | nil
function M.getinfo(message, isCommand)
  local limit = limitHandler.getRoomImageLimit(message) or 5

  if limit == 0 then
    if isCommand then
      limit = 5
    else
      return nil
    end
  end

  local content = message.content

  content = content:gsub('\n', ' '):gsub('||', ' ')
  local words = content:split(' ')
  local multipleLinks = hasMultipleLinks(words)

  return {
    words = words,
    limit = limit,
    multipleLinks = multipleLinks
  }
end

return M