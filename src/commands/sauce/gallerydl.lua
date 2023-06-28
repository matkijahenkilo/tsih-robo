local fs = require("fs");
local spawn = require("coro-spawn");
local logger = require("discordia").Logger(3, "%Y-%m-%d %X", "gallerydl.log")
local stopwatch = require("discordia").Stopwatch(true)

local MAX_UPLOAD_LIMIT = 25

local gallerydl = {}

local function getFileSizeInMegaBytes(file)
  return fs.statSync(file).size / (1024*1024)
end

local function fileExists(file)
  return fs.statSync(file) ~= nil
end

local function printInfo(link, limit, files)
  local mb = 0
  for _, file in ipairs(files) do
    mb = mb + getFileSizeInMegaBytes(file)
  end
  logger:log(3, string.format("Downloaded %s/%s images from %s - total of %.2fmb. Took %.2f seconds",
    #files, limit, link, mb, stopwatch:getTime():toSeconds()
  ))
end

local function fillNewTable(t)
  local newTable = {};
  for _, value in ipairs(t) do
    if value ~= '' then
      table.insert(newTable, value);
    end
  end
  return newTable
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

local function filterLargeFiles(existingFilestbl)
  for index, file in ipairs(existingFilestbl) do
    if file ~= '' and getFileSizeInMegaBytes(file) >= MAX_UPLOAD_LIMIT then
      fs.unlinkSync(file);
      existingFilestbl[index] = nil;
    end
  end

  return fillNewTable(existingFilestbl)
end

local function filterNilFiles(filestbl)
  for index, file in ipairs(filestbl) do
    if file ~= '' and not fileExists(file) then
      filestbl[index] = nil;
    end
  end

  return fillNewTable(filestbl);
end



function gallerydl.downloadImage(link, id, limit)
  stopwatch:start()
  local child = spawn("gallery-dl", {
    args = {
      "--cookies", "cookies.txt",
      "--range", "1-" .. limit, "--ugoira-conv",
      "-D", "./temp/"..id,
      link
    }
  });

  local filestbl = readProcess(child)
  local downloadedFiles = table.concat(filestbl);
  downloadedFiles = downloadedFiles:gsub("# ", ''):gsub("\r", ''):split('\n');

  local existingFilestbl = filterNilFiles(downloadedFiles)
  local filesToSend = filterLargeFiles(existingFilestbl);

  printInfo(link, limit, filesToSend)
  stopwatch:stop()

  return filesToSend;
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