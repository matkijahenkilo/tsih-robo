local fs = require("fs");
local spawn = require("coro-spawn");

local MAX_UPLOAD_LIMIT = 25

local gallerydl = {}

local function getFileSizeInMegaBytes(file)
  return fs.statSync(file).size / (1024*1024)
end

local function fileExists(file)
  return fs.statSync(file) ~= nil
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

local function filterNilFiles(downloadedFiles)
  local filestbl = downloadedFiles:split("\n");
  for index, file in ipairs(filestbl) do
    if file ~= '' and not fileExists(file) then
      filestbl[index] = nil;
    end
  end

  return fillNewTable(filestbl);
end

function gallerydl.downloadImage(link, id, limit)
  local child = spawn("gallery-dl", {
    args = {
      "--cookies", "cookies.txt",
      "--range", "1-" .. limit, "--ugoira-conv",
      "-D", "./temp/"..id,
      link
    }
  });
  -- obviously not the best idea to concat table, transform to table, concat table and so on...
  local downloadedFiles = table.concat(readProcess(child));
  downloadedFiles = downloadedFiles:gsub("# ", ''):gsub("\r", '');

  local existingFilestbl = filterNilFiles(downloadedFiles)
  local filesToSend = filterLargeFiles(existingFilestbl);

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