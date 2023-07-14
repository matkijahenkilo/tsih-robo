local fs = require("fs")
local spawn = require("coro-spawn")
local discordia = require("discordia")
local logger = discordia.Logger(3, "%F %T", "gallery-dl.log")
local constant = require("src.utils.constants")
local logLevel = discordia.enums.logLevel

local function isEmpty(t)
  return type(t) == "table" and (not t or t[1] == nil) or t == ''
end

local function getFileSizeInMegaBytes(file)
  return fs.statSync(file).size / (1024*1024)
end

local function fileExists(file)
  return fs.statSync(file) ~= nil
end

local function logDownloadedInfo(link, files, stopwatch)
  local mb = 0
  local time = stopwatch:getTime()
  for _, file in ipairs(files) do
    mb = mb + getFileSizeInMegaBytes(file)
  end
  local  msg = "gallery-dl : %s files from %s = %.2fmb. Took %.2f seconds"
  logger:log(3, msg, #files, link, mb, time:toSeconds())
end

local function getSpecificLinksFromString(t, string)
  local specificLinks = {}
  for _, value in ipairs(t:split('\n')) do
    if value:find(string) then
      table.insert(specificLinks, value .. '\n')
    end
  end
  return specificLinks
end

local function getBaraagLinks(link)
  local baraagLinks = getSpecificLinksFromString(link, constant.BARAAG_MEDIA)
  table.remove(baraagLinks, 1) --removes the first, already embedded image
  return baraagLinks
end

local function filterLinks(link)
  local result = {}
  if link then
    if link:find(constant.TWITTER_IMAGE) then
      result = getSpecificLinksFromString(link, constant.TWITTER_VIDEO)
    elseif link:find(constant.BARAAG_MEDIA) then
      result = getBaraagLinks(link)
    end
  end
  return result[1] and result or link
end

---@return string stdout
local function readProcess(child)
  child:waitExit()
  return child.stdout.read()
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
    if getFileSizeInMegaBytes(file) >= constant.MAX_UPLOAD_LIMIT then
      fs.unlinkSync(file)
      t[index] = nil
    end
  end
  return fillNewTable(t)
end

local function filterNilFiles(t)
  for index, file in ipairs(t) do
    if not fileExists(file) then
      t[index] = nil
    end
  end
  return fillNewTable(t)
end

---@return table | nil
local function getCleanedTable(t)
  return t:gsub("# ", ''):gsub("\r", ''):split('\n')
end

---Converts a table of files into a new format.
---Returns the same inputed table if no changes were made.
---Formats should be named as ".mp4", ".gif" etc.
---@param tbl table
---@param oldFormat string
---@param newFormat string
---@return table newTbl
local function convertFiles(tbl, oldFormat, newFormat)
  local newFileFormatTbl = {}
  for _, file in ipairs(tbl) do
    if file:find(oldFormat) then
      local newFile = file:sub(1, #file-#oldFormat)..newFormat
      spawn("ffmpeg", {
        args = { "-i", file, newFile }
      }).waitExit()
      fs.unlinkSync(file)
      table.insert(newFileFormatTbl, newFile)
    end
  end
  return newFileFormatTbl[1] and newFileFormatTbl or tbl
end



local gallerydl = {}

---@param link string
---@param id string
---@param limit integer
---@return table | nil files
---@return string gallerydlOutput
function gallerydl.downloadImage(link, id, limit)
  local stopwatch = discordia.Stopwatch()

  local child = spawn("gallery-dl", {
    args = {
      "--cookies", "cookies.txt",
      "--range", "1-"..limit, "--ugoira-conv",
      "-D", "./temp/"..id,
      link
    }
  })

  local outputstr = readProcess(child)
  if not outputstr or outputstr == '' then
    logger:log(logLevel.error, "gallery-dl : No output. Maybe authorization is missing?")
    return nil, outputstr
  end
  local filestbl = getCleanedTable(outputstr)
  filestbl = filterNilFiles(filestbl)
  filestbl = filterLargeFiles(filestbl)
  --filestbl = convertFiles(filestbl, ".mp4", ".gif")

  stopwatch:stop()

  if isEmpty(filestbl) then
    logger:log(logLevel.error, "gallery-dl : Could not download from '%s' - '%s'",
      link,
      outputstr
    )
    return nil, outputstr
  end

  logDownloadedInfo(link, filestbl, stopwatch)

  return filestbl, outputstr
end

---@param link string
---@param limit integer
---@return string links
---@return string gallerydlOutput
function gallerydl.getUrl(link, limit)
  local stopwatch = discordia.Stopwatch()
  if limit > 5 then limit = 5 end

  local child = spawn("gallery-dl", {
    args = {
      "--cookies", "cookies.txt",
      "--range", "1-"..limit,
      "-g",
      link
    }
  })

  local outputstr = readProcess(child)
  local links = filterLinks(outputstr)

  stopwatch:stop()

  if isEmpty(links) then
    if not link:find("https://twitter.com/") then
      logger:log(logLevel.error, "gallery-dl : Could not get links from '%s' - '%s'",
        link,
        outputstr
      )
    end
    return "", outputstr
  end

  logger:log(logLevel.info, "gallery-dl : Got links from '%s', took %.2f seconds",
    link,
    stopwatch:getTime():toSeconds()
  )

  if type(links) == "table" then
    return table.concat(links), outputstr
  end
  return links, outputstr
end

return gallerydl
