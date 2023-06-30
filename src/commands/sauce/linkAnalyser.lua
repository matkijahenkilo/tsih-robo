local limitHandler = require("./limitHandler")
require('discordia').extensions()

local doesNotRequireDownload = {
  "https://e621.net/",
  "https://booru.io/",
  "https://pawoo.net/",
  "https://nijie.info/",
  "https://baraag.net/",
  "https://nhentai.net/",
  "https://inkbunny.net/",
  "https://e-hentai.org/",
  "https://hentai2read.com/",
}

local requireDownload = {
  "https://hitomi.la/",
  "https://misskey.io/",
  "https://sankaku.app/",
  "https://exhentai.org/",
  "https://e-hentai.org/",
  "https://kemono.party/",
  "https://www.pixiv.net/",
  "https://www.tsumino.com/",
  "https://www.deviantart.com/",
  "https://chan.sankakucomplex.com/",
}

local function verify(string, list)
  for _, value in pairs(list) do
    if string:find(value) then
      return true;
    end
  end
  return false;
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
      or word:find("https://twitter.com/")
    then
      count = count + 1
      if count > 1 then return true end
    end
  end
  return false
end

function M.getinfo(message, client)
  local limit = limitHandler.getRoomImageLimit(message) or 5

  if limit == 0 then return nil end

  local content = message.content

  content = content:gsub('\n', ' '):gsub('||', ' ')
  local words = content:split(' ')
  local multipleLinks = hasMultipleLinks(words)

  return {
    words = words,
    limit = limit,
    link = nil,
    client = client,
    multipleLinks = multipleLinks
  }
end

return M