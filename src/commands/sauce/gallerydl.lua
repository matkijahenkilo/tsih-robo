local fs = require("fs");
local spawn = require("coro-spawn");

local MAX_UPLOAD_LIMIT = 25

local gallerydl = {}

local function getFileSizeInMegaBytes(file)
  return fs.statSync(file).size / (1024*1024)
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

local function readProcess(child)
  local images = {};
  child:waitExit();
  local link = child.stdout.read();

  table.insert(images, link);
  if link then
    if link:find("pbs.twimg") then
      return getSpecificLinksFromString(link, "video.twimg");
    elseif link:find("media.baraag.net") then
      local baraagLinks = getSpecificLinksFromString(link, "media.baraag.net");
      table.remove(baraagLinks, 1); --removes the first, already embedded image
      return baraagLinks;
    end
  end

  return images;
end

local function filterLargeFiles(downloadedFiles)
  local filestbl = downloadedFiles:split("\n");
  for index, file in ipairs(filestbl) do
    if file ~= '' and getFileSizeInMegaBytes(file) >= MAX_UPLOAD_LIMIT then
      fs.unlinkSync(file);
      filestbl[index] = "";
    end
  end

  local filteredFilestbl = {};
  for _, file in ipairs(filestbl) do
    if file ~= '' then
      table.insert(filteredFilestbl, file);
    end
  end

  return filteredFilestbl;
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

  local downloadedFiles = table.concat(readProcess(child));
  downloadedFiles = downloadedFiles:gsub("# ", ''):gsub("\r", '');

  local filestbl = filterLargeFiles(downloadedFiles);

  return filestbl;
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