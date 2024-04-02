local fs = require("fs")
local spawn = require("coro-spawn")
local discordia = require("discordia")
local logger = discordia.Logger(3, "%F %T", "gallery-dl.log")
local logLevel = discordia.enums.logLevel
local json = require("json")
local format = string.format
discordia.extensions()

local MAX_UPLOAD_LIMIT = 25
local BARAAG_LINK = "https://baraag.net/"
local BARAAG_MEDIA = "media.baraag.net"

local Gallerydl, get = discordia.class("Gallerydl")

---@param linkParser LinkParser
---@param channelId string|nil
---@param limit integer
function Gallerydl:__init(linkParser, channelId, limit)
	self._linkParser = linkParser
	self._link = linkParser.link
  self._id = channelId
  self._limit = limit
end

local function isEmpty(t)
  return type(t) == "table" and (not t or t[1] == nil) or t == ''
end

local function getFileSizeInMegaBytes(file)
  return fs.statSync(file).size / (1024*1024)
end

local function fileExists(file)
  return fs.statSync(file) ~= nil
end

local function logDownloadedInfo(link, files, stopwatch, wasDownloaded)
  local time = stopwatch:getTime()
  local mb = 0

  if #files > 0 then
    for _, file in ipairs(files) do
      mb = mb + getFileSizeInMegaBytes(file)
    end
  end

  local msg = ""
  if wasDownloaded then
    msg = "Gallerydl : %s files from %s = %.2fmb. Took %.2f seconds"
    logger:log(logLevel.info, msg, #files, link, mb, time:toSeconds())
  else
    msg = "Gallerydl : Got links from %s. Took %.2f seconds"
    logger:log(logLevel.info, msg, link, mb, time:toSeconds())
  end
end

local function getSpecificLinksFromString(str, val)
  local specificLinks = {}
  for _, value in ipairs(str:split('\n')) do
    if value:find(val) then
      table.insert(specificLinks, value..'\n')
    end
  end
  return specificLinks
end

local function getBaraagLinks(link)
  local baraagLinks = getSpecificLinksFromString(link, BARAAG_MEDIA)
  table.remove(baraagLinks, 1) --removes the first, already embedded image
  return baraagLinks
end

local function filterLinks(links)
  local filteredLinks = {}
  if links then
    if links:find(BARAAG_MEDIA) then
      filteredLinks = getBaraagLinks(links)
      return filteredLinks[1] and filteredLinks or ""
    end
  end
  return filteredLinks[1] and filteredLinks or links
end

---@return string | nil stdout
---@return string | nil stderr
local function readProcess(child)
  child:waitExit()
  return child.stdout.read(), child.stderr.read()
end

local function fillNewTable(t)
  local newTable = {}
  for _, value in ipairs(t) do
    table.insert(newTable, value)
  end
  return newTable
end

local function filterLargeFiles(t)
  for index, file in ipairs(t) do
    if getFileSizeInMegaBytes(file) >= MAX_UPLOAD_LIMIT then
      fs.unlinkSync(file)
      t[index] = nil
    end
  end
  return fillNewTable(t), "file too big"
end

local function filterNilFiles(t)
  for index, file in ipairs(t) do
    if not fileExists(file) then
      t[index] = nil
    end
  end
  return fillNewTable(t), "file does not exist"
end

---@return table | nil
local function getCleanedTable(t)
  return t:gsub("# ", ''):gsub("\r", ''):split('\n')
end

local function replaceSlash(t)
  for index, _ in ipairs(t) do
    t[index] = t[index]:gsub("\\", "/")
  end
  return t
end

---Converts a table of files into a new format using ffmpeg, if possible.
---Returns the same inputed table if no changes were made.
---Formats should be named as ".mp4", ".gif" etc.
---@param tbl table
---@param oldFormat string
---@param newFormat string
---@return table ret
local function convertFiles(tbl, oldFormat, newFormat)
  local ret = table.copy(tbl)

  for i, file in ipairs(tbl) do
    if file:find(oldFormat) then
      local newFile = file:gsub(oldFormat, newFormat)
      spawn("ffmpeg", {
        args = { "-i", file, newFile }
      }).waitExit()
      fs.unlinkSync(file)
      ret[i] = newFile
    end
  end

  return ret
end


---@return table | nil pageJson
function Gallerydl:getJson()
  local stdout, stderr = readProcess(spawn("gallery-dl", { args = { "-j", "--cookies", "cookies.txt", self._link } }))
  if not stdout then
    logger:log(logLevel.error, "Gallerydl : Failed to fetch Twitter Json: %s", stderr)
    return
  end
  local pageJson = json.decode(stdout)
  if not pageJson or not pageJson[1] then return end
  return pageJson[#pageJson][3].author and pageJson or nil
end

---@return table | nil files
---@return string | nil gallerydlOutput
function Gallerydl:downloadImage()
  local stopwatch = discordia.Stopwatch()

  local parser = self._linkParser
  local link = parser.link
  local id = self._id
  local limit = self._limit

  logger:log(logLevel.info, "Gallerydl : Downloading images from %s ...", link)

  if not id then
    return error("Gallerydl : No id was set")
  end

  if parser:isTwitter() and not parser:isTwitterPost() then
    return error(format("Gallerydl : Ignored a Twitter profile to avoid spam (%s)", link))
  end

  local child = spawn("gallery-dl", {
    args = {
      "--cookies", "cookies.txt",
      "--range", "1-"..limit, "--ugoira-conv",
      "-D", "./temp/"..id,
      link
    }
  })

  if not child then return nil end

  local stdout, stderr = readProcess(child)
  if not stdout or stdout == '' then
    return error(format("Gallerydl : Couldn't get anything from `%s`, reason: %s",
      link,
      stderr
    ))
  end
  local filestbl, err = getCleanedTable(stdout)
  filestbl, err = filterNilFiles(filestbl)
  filestbl, err = filterLargeFiles(filestbl)
  filestbl = replaceSlash(filestbl)
  filestbl = convertFiles(filestbl, ".webp", ".png")

  stopwatch:stop()

  if isEmpty(filestbl) then
    stdout = stdout:gsub("\n", "")
    return error(format("Gallerydl : Could not download files from `%s` nanora!\nreason: %s\nfile(s): `%s`",
      link,
      err,
      stderr
    ))
  end

  logDownloadedInfo(link, filestbl, stopwatch, true)

  return filestbl
end

---@return string links
---@return string | nil gallerydlOutput
function Gallerydl:getLink()
  local stopwatch = discordia.Stopwatch()

  local link = self._link
  local limit = self._limit

  logger:log(3, "Gallerydl : Getting link from %s ...", link)

  if limit > 5 then limit = 5 end

  local child = spawn("gallery-dl", {
    args = {
      "--cookies", "cookies.txt",
      "--range", "1-"..limit,
      "-g",
      link
    }
  })

  local stdout, stderr = readProcess(child)
  if not stdout then
    return "", error(format(("Gallerydl : Could not get anything from '%s', reason: '%s'"),
      link,
      stderr
    ))
  end

  local links = filterLinks(stdout)

  stopwatch:stop()
  if isEmpty(links) then
    if not link:find(BARAAG_LINK) then
      return "", error(format(("Gallerydl : Could not get links from '%s', reason: '%s'"),
        link,
        stderr
      ))
    end
  end

  if not link:find(BARAAG_LINK) then
    logDownloadedInfo(link, {}, stopwatch, false)
  end

  if type(links) == "table" then
    return table.concat(links)
  end

  return links
end

function get.link(self) return self._link end
function get.linkParser(self) return self._linkParser end

return Gallerydl