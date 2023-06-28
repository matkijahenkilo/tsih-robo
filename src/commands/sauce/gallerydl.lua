local fs = require("fs");
local spawn = require("coro-spawn");
local discordia = require("discordia")
local logger = discordia.Logger(3, "%Y-%m-%d %X", "gallery-dl.log")

local MAX_UPLOAD_LIMIT = 25

local gallerydl = {}

local function isEmpty(t)
  return t[1] == nil
end

local function getFileSizeInMegaBytes(file)
  return fs.statSync(file).size / (1024*1024)
end

local function fileExists(file)
  return fs.statSync(file) ~= nil
end

local function logInfo(link, limit, files, stopwatch)
  local mb = 0
  local time = stopwatch:getTime()
  for _, file in ipairs(files) do
    mb = mb + getFileSizeInMegaBytes(file)
  end

  if time:toSeconds() > 60 then
    logger:log(3, string.format("Downloaded %s/%s images from %s - total of %.2fmb. Took %.2f minutes",
      #files, limit, link, mb, time:toMinutes()
    ))
  else
    logger:log(3, string.format("Downloaded %s/%s images from %s - total of %.2fmb. Took %.2f seconds",
      #files, limit, link, mb, time:toSeconds()
    ))
  end
end

local function getSpecificLinksFromString(t, string)
  local specificLinks = {};
  for _, value in ipairs(t:split('\n')) do
    if value:find(string) then
      table.insert(specificLinks, value .. '\n');
    end
  end
  return specificLinks;
end

local function getBaraagLinks(link)
  local baraagLinks = getSpecificLinksFromString(link, "media.baraag.net");
  table.remove(baraagLinks, 1); --removes the first, already embedded image
  return baraagLinks;
end

local function readProcess(child)
  child:waitExit();
  local link = child.stdout.read();

  if link then
    if link:find("pbs.twimg") then
      return getSpecificLinksFromString(link, "video.twimg");
    elseif link:find("media.baraag.net") then
      return getBaraagLinks(link)
    end
  end

  return { link }
end

local function fillNewTable(t)
  local newTable = {};
  for _, value in ipairs(t) do
    table.insert(newTable, value);
  end
  return newTable
end

local function filterLargeFiles(t)
  for index, file in ipairs(t) do
    if getFileSizeInMegaBytes(file) >= MAX_UPLOAD_LIMIT then
      fs.unlinkSync(file);
      t[index] = nil;
    end
  end
  return fillNewTable(t)
end

local function filterNilFiles(t)
  for index, file in ipairs(t) do
    if not fileExists(file) then
      t[index] = nil;
    end
  end
  return fillNewTable(t);
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

function gallerydl.downloadImage(link, id, limit)
  local stopwatch = discordia.Stopwatch()

  local child = spawn("gallery-dl", {
    args = {
      "--cookies", "cookies.txt",
      "--range", "1-"..limit, "--ugoira-conv",
      "-D", "./temp/"..id,
      link
    }
  });

  local filestbl = readProcess(child)
  filestbl = getCleanedTable(filestbl)
  filestbl = filterNilFiles(filestbl)
  filestbl = filterLargeFiles(filestbl)

  stopwatch:stop()

  if isEmpty(filestbl) then return end

  logInfo(link, limit, filestbl, stopwatch)

  return filestbl
end

function gallerydl.getUrl(url, limit)
  if limit > 5 then limit = 5 end

  local child = spawn("gallery-dl", {
    args = {
      "--cookies", "cookies.txt",
      "--range", "1-" .. limit,
      "-g",
      url
    }
  });

  return table.concat(readProcess(child));
end

return gallerydl