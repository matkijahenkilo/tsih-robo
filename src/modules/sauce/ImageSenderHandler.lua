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
    print("Couldn't get link: " .. value, "Reason: " .. err);
    message:addReaction("🇳");
    message:addReaction("🇴");
    message:removeReaction("🇴");
    message:removeReaction("🇳");
  end
end

local function filterBigFiles(filestbl)
  for index, file in ipairs(filestbl) do
    if file ~= '' and getFileSizeInMegaBytes(file) >= 8 then
      print("deleting file "..file..", size: " .. getFileSizeInMegaBytes(file) .."mb");
      filestbl[index] = '';
      fs.unlinkSync(file);
    end
  end
  return table.concat(filestbl, ' '):split(' '); -- because table.remove messes up with the for lmao
end

local function downloadImage(url, id, limit)
  local child = spawn("gallery-dl", {
    args = {
      "--cookies", "cookies.txt",
      "--range", "1-" .. limit, "--ugoira-conv",
      --"-D", "./temp/"..id,
      "-D", "./temp/",
      url
    }
  });

  local filestbl = table.concat(readProcess(child));
  filestbl = filestbl:gsub("# ", ''):gsub("\r", '');
  filestbl = filestbl:split("\n");
  filestbl = filterBigFiles(filestbl);
  table.remove(filestbl, #filestbl); --removes an empty index

  return filestbl;
end

local function sendDownloadedImage(message, images)
  return message.channel:send {
    files = images,
    reference = {
      message = message,
      mention = false,
    }
  };
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

local function sendUrl(message, url)
  return message.channel:send {
    content = url,
    reference = {
      message = message,
      mention = false,
    }
  };
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

function M.sendTwitterDirectVideoUrl(value, message, limit)
  local url = getUrl(value, limit);
  if url:find("video.twimg") then
    local success, err = sendUrl(message, url);
    checkSuccess(success, err, message, value);
    return true;
  end
  return false;
end

function M.sendDirectImageUrl(value, message, limit)
  if value:find("https://baraag.net/") then
    value = value:gsub("web/", '');
  end

  local url = getUrl(value, limit);
  if hasUrl(url) then
    if shouldSendBaraagLinks(url) or not url:find("https://baraag.net/") then
      local success, err = sendUrl(message, url);
      checkSuccess(success, err, message, value);
    end
  end
end

function M.downloadSendAndDeleteImages(value, message, limit)
  local id = message.channel.id;
  local filestbl = downloadImage(value, id, limit);

  if hasFile(filestbl) then
    local success, err = sendDownloadedImage(message, filestbl);
    checkSuccess(success, err, message, value);
  end

  --deleteDownloadedImage(filestbl, id);
end

function M.sendTwitterImages(value, message, limit, client)
  if not message.embed then
    if not client:waitFor("messageUpdate", 2500) then
      M.downloadSendAndDeleteImages(value, message, limit);
    end
  end
end

return M;