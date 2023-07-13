local fs = require("fs")
local spawn = require("coro-spawn")
local discordia = require("discordia")
local logger = discordia.Logger(3, "%F %T", "gallery-dl.log")
local constant = require("src.utils.constants")
local logLevel = discordia.enums.logLevel

local function isEmpty(t)
  return not t or t[1] == nil
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

local function readProcess(child, type)
  local result = {}
  child:waitExit()
  local link = child.stdout.read()
  result[1] = link

  if type == "file" then
    return result
  elseif type == "url" then
    if link then
      if link:find(constant.TWITTER_IMAGE) then
        result = getSpecificLinksFromString(link, constant.TWITTER_VIDEO)
      elseif link:find(constant.BARAAG_MEDIA) then
        result = getBaraagLinks(link)
      end
    end
  end
  return result
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

local function getCleanedTable(t)
  local cleanedTable = {}
  for _, v in ipairs(t) do
    if v or v ~= '' then
      local value = v:gsub("# ", ''):gsub("\r", '')
      table.insert(cleanedTable, value)
    end
  end
  return table.concat(cleanedTable):split('\n')
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

  local output = readProcess(child, "file")
  local filestbl = getCleanedTable(output)
  filestbl = filterNilFiles(filestbl)
  filestbl = filterLargeFiles(filestbl)
  --filestbl = convertFiles(filestbl, ".mp4", ".gif")

  local outputstr = table.concat(output, '\n')

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

  local output = readProcess(child, "url")
  local outputstr = table.concat(output, '\n')

  stopwatch:stop()

  if isEmpty(output) then
    logger:log(logLevel.error, "gallery-dl : Could not get links from '%s' - '%s'",
      link,
      outputstr
    )
    return "", outputstr
  else
    logger:log(logLevel.info, "gallery-dl : Got links from '%s', took %.2f seconds",
      link,
      stopwatch:getTime():toSeconds()
    )
  end

  return table.concat(output), outputstr
end

return gallerydl
