local limitHandler = require("./limitHandler")
local constants = require("src.utils.constants")
require('discordia').extensions()

-- please check sauce/init.lua to get around this problem, sorry
local doesNotRequireDownload = require("./links/nonDownloables.lua")
local requireDownload = require("./links/downloables.lua")

if not doesNotRequireDownload or not doesNotRequireDownload[1] then
  error("./links/nonDownloables.lua does not return any string for gallery-dl to read nora. Read sauce/init.lua for more information nanora!")
end

if not requireDownload or not requireDownload[1] then
  error("./links/downloables.lua does not return any string for gallery-dl to read nora. Read sauce/init.lua for more information nanora!")
end

local function verify(string, list)
  for _, value in pairs(list) do
    if string:find(value) then
      return true
    end
  end
  return false
end

local M = {}

function M.linkRequireDownload(link)
  return verify(link, requireDownload)
end

function M.linkDoesNotRequireDownload(link)
  return verify(link, doesNotRequireDownload)
end

local function hasMultipleLinks(t)
  local count = 0
  for _, word in ipairs(t) do
    if M.linkRequireDownload(word)
      or M.linkDoesNotRequireDownload(word)
      or word:find(constants.TWITTER_LINK)
    then
      count = count + 1
      if count > 1 then return true end
    end
  end
  return false
end

function M.getinfo(message)
  local limit = limitHandler.getRoomImageLimit(message) or 5

  if limit == 0 then return nil end

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
