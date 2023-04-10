local spawn = require("coro-spawn");
local fs = require("fs");

local M = {}

M.doesNotRequireDownload = {
  "https://e621.net/",
  "https://booru.io/",
  "https://pawoo.net/",
  "https://nijie.info/",
  "https://baraag.net/",
  "https://misskey.io/",
  "https://nhentai.net/",
  "https://kemono.party/",
  "https://inkbunny.net/",
  "https://e-hentai.org/",
  "https://hentai2read.com/",
}

M.requireDownload = {
  "https://hitomi.la/",
  "https://sankaku.app/",
  "https://exhentai.org/",
  "https://www.pixiv.net/",
  "https://chan.sankakucomplex.com/",
}

local function hasFile(file)
  return file or file[1];
end

local function hasUrl(url)
  return url ~= '';
end

local function getFileSizeInMegaBytes(file)
  return fs.statSync(file).size / (1024*1024)
end

local function getSpecificLinks(t, string)
  local specificLinks = {};
  for _, value in ipairs(t:split('\n')) do
    if value:find(string) then
      table.insert(specificLinks, value .. '\n');
    end
  end
  return specificLinks;
end

local function readProcess(child)
  local linksTable = {};
  child:waitExit();
  local link = child.stdout.read();

  table.insert(linksTable, link);
  if link then
    if link:find("pbs.twimg") then
      return getSpecificLinks(link, "video.twimg");
    elseif link:find("media.baraag.net") then
      local baraagLinks = getSpecificLinks(link, "media.baraag.net");
      table.remove(baraagLinks, 1);
      return baraagLinks;
    end
  end

  return linksTable;
end

local function checkSuccess(success, err, message, value)
  if not success then
    local t = {
      "🇳","🇴"
    }
    print("Couldn't get link: " .. value, "Reason: " .. (err or "Only God knows why"));
    for _, emoji in ipairs(t) do
      message:addReaction(emoji);
    end
  end
end

local function filterLargeFiles(downloadedFiles)
  local filestbl = downloadedFiles:split("\n");
  for index, file in ipairs(filestbl) do
    if file ~= '' and getFileSizeInMegaBytes(file) >= 25 then
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

local function downloadImage(link, id, limit)
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

local function sendDownloadedImage(message, images, link)
  local messageToSend = {
    files = images,
    reference = {
      message = message,
      mention = false,
    }
  };

  if link then
    messageToSend.content = "`" .. link .. "`";
  end

  return message.channel:send(messageToSend);
end

local function deleteDownloadedImage(file, id)
  for _, value in ipairs(file) do
    fs.unlinkSync(value);
  end
  fs.rmdir("./temp/" .. id);
end

local function getUrl(url, limit)
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

local function sendUrl(message, url, source)
  local messageToSend = {
    reference = {
      message = message,
      mention = false,
    }
  };

  if source then
    messageToSend.content = "`" .. source .. "`\n" .. url;
  else
    messageToSend.content = url;
  end

  return message.channel:send(messageToSend);
end

local function shouldSendBaraagLinks(url)
  local quantity = 0;
  for _, value in ipairs(url:split('\n')) do
    if value:find("baraag.net") and value:find(".mp4") then
      return true;
    elseif value:find("baraag.net") then
      quantity = quantity + 1;
    end
  end

  return quantity > 1;
end

function M.verify(string, list)
  for _, value in pairs(list) do
    if string:find(value) then
      return true;
    end
  end

  return false;
end

function M.sendTwitterDirectVideoUrl(source, message, limit, hasMultipleLinks)
  local url = getUrl(source, limit);
  if url:find("video.twimg") then
    local success, err;
    if hasMultipleLinks then
      success, err = sendUrl(message, url, source);
    else
      success, err = sendUrl(message, url);
    end
    checkSuccess(success, err, message, source);
    return true;
  end
  return false;
end

function M.sendDirectImageUrl(source, message, limit, hasMultipleLinks)
  if source:find("https://baraag.net/") then
    source = source:gsub("web/", '');
  end

  local url = getUrl(source, limit);

  if hasUrl(url) then
    if shouldSendBaraagLinks(url) or not url:find("https://baraag.net/") then
      local success, err;
      if hasMultipleLinks then
        sendUrl(message, url, source);
      else
        sendUrl(message, url);
      end
      checkSuccess(success, err, message, source);
    end
  end
end

function M.downloadSendAndDeleteImages(source, message, limit, hasMultipleLinks)
  local id = message.channel.id;
  local filestbl = downloadImage(source, id, limit);
  local response = nil;

  if hasFile(filestbl) then
    local success, err;
    if hasMultipleLinks then
      success, err = sendDownloadedImage(message, filestbl, source);
    else
      success, err = sendDownloadedImage(message, filestbl);
    end
    checkSuccess(success, err, message, source);
    response = err;
  end

  deleteDownloadedImage(filestbl, id);

  return response;
end

function M.sendTwitterImages(source, message, limit, client, hasMultipleLinks)
  if not message.embed then
    if not client:waitFor("messageUpdate", 2500) then
      M.downloadSendAndDeleteImages(source, message, limit, hasMultipleLinks);
    end
  end
end

return M;