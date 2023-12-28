local limitHandler = require("./limitHandler")
local json = require("json")
local fs = require("fs")
local discordia = require('discordia')
discordia.extensions()

local LinkParser, get, set = discordia.class("LinkParser")

function LinkParser:__init(message, wasCommand)
  self._message = message
  self._wasCommand = wasCommand
  self._link = nil
end

-- don't insert twitter into the nonDownloables list, lots of problem will come if so.
local doesNotRequireDownload        = json.decode(fs.readFileSync("data/links/nonDownloables.json"))
local requireDownload               = json.decode(fs.readFileSync("data/links/downloables.json"))
local blacklistIsPresent, blacklist = pcall(json.decode, fs.readFileSync("data/links/blacklist.json"))

if not doesNotRequireDownload or not doesNotRequireDownload[1] then
  error("data/links/nonDownloables.json does not return any string for gallery-dl to read nora.")
end

if not requireDownload or not requireDownload[1] then
  error("data/links/downloables.json does not return any string for gallery-dl to read nora.")
end

if not blacklistIsPresent then
  local loglevel = discordia.enums.logLevel.warning
  discordia.Logger(loglevel, "%F %T", nil):log(loglevel, "blacklist.json is not present.")
end

local function verify(str, list)
  for _, value in pairs(list) do
    if str:find(value) then
      return true
    end
  end
  return false
end

function LinkParser:linkRequireDownload(word)
  local link = self._link or word
  return verify(link, requireDownload)
end

function LinkParser:linkDoesNotRequireDownload(word)
  local link = self._link or word
  return verify(link, doesNotRequireDownload)
end

function LinkParser:linkShouldBeIgnored()
  if not blacklistIsPresent then
    return nil
  end
  return verify(self._link, blacklist)
end

function LinkParser:isTwitterPost()
  return self._link:find("/status/")
end

function LinkParser:isTwitter()
  IamtheboneofmyswordSteelismybodyandfireismybloodIhavecreatedoverathousandtwitterlinksUnawareoflossNorawareofgainWithstoodpaintocreatebloodinprogrammerseyeswaitingforonesarrivalIhaveregretsThisistheonlypathunfortunatelyMywholelifewasUnlimitedTwitterWorks = {
    "https://twitter.com",
    "https://x.com",
  }
  for _, UnlimitedTwitterString in ipairs(IamtheboneofmyswordSteelismybodyandfireismybloodIhavecreatedoverathousandtwitterlinksUnawareoflossNorawareofgainWithstoodpaintocreatebloodinprogrammerseyeswaitingforonesarrivalIhaveregretsThisistheonlypathunfortunatelyMywholelifewasUnlimitedTwitterWorks) do
    if self._link:find(UnlimitedTwitterString) then
      return true
    end
  end
  return false
end

local function removeDuplicates(words)
  local hash = {}
  local newWords = {}
  for _, v in ipairs(words) do
    if not hash[v] then
      newWords[#newWords+1] = v
      hash[v] = true
    end
  end
  return newWords
end

local function hasMultipleLinks(self, words)
  local count = 0
  for _, word in ipairs(words) do
    if self:linkRequireDownload(word)
      or self:linkDoesNotRequireDownload(word)
    then
      count = count + 1
      if count > 1 then return true end
    end
  end
  return false
end

---returns information about current channel's limit, message's contents, 
---and if the message has multiple links in it.
---@return table | nil
function LinkParser:getinfo()

  local limit = limitHandler.getRoomImageLimit(self._message) or 5

  if limit == 0 then
    if self._wasCommand then
      limit = 5
    else
      return nil
    end
  end

  local content = self._message.content:gsub('\n', ' '):gsub('||', ' ')
  local words = content:split(' ')
  words = removeDuplicates(words)
  local multipleLinks = hasMultipleLinks(self, words)

  return {
    words = words,
    limit = limit,
    multipleLinks = multipleLinks
  }
end

function get.link(self)
  return self._link
end

function set.link(self, link)
  self._link = link
end

return LinkParser