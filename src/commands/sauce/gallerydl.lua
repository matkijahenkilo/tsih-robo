local fs = require("fs")
local spawn = require("coro-spawn")
local discordia = require("discordia")
local logger = discordia.Logger(3, "%F %T", "gallery-dl.log")
local constant = require("src.utils.constants")
local logLevel = discordia.enums.logLevel

local function isEmpty(t)
  return t[1] == nil
end

local function getFileSizeInMegaBytes(file)
  return fs.statSync(file).size / (1024*1024)
end

local function fileExists(file)
  return fs.statSync(file) ~= nil
end

local function logInfo(link, files, stopwatch)
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




local gallerydl = {}

---Downloads files from a link, receiving the channel's id and the limit of images
---@param link string
---@param id string
---@param limit integer
---@return table | nil files, string gallerydlOutput
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
  p(output)
  local filestbl = getCleanedTable(output)
  filestbl = filterNilFiles(filestbl)
  filestbl = filterLargeFiles(filestbl)

  stopwatch:stop()

  local outputstr = table.concat(output, '\n')
  p(outputstr)
  if isEmpty(filestbl) then
    logger:log(logLevel.error, "gallery-dl : Could not download from '%s' - '%s'",
      link,
      outputstr
    )
    return nil, outputstr
  end

  logInfo(link, filestbl, stopwatch)

  return filestbl, outputstr
end

function gallerydl.getUrl(url, limit)
  if limit > 5 then limit = 5 end

  local child = spawn("gallery-dl", {
    args = {
      "--cookies", "cookies.txt",
      "--range", "1-"..limit,
      "-g",
      url
    }
  })

  return table.concat(readProcess(child, "url"))
end

return gallerydl
