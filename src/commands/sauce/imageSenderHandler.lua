local fs = require("fs");
local gallerydl = require("./gallerydl")

local M = {}

M.doesNotRequireDownload = {
  "https://e621.net/",
  "https://booru.io/",
  "https://pawoo.net/",
  "https://nijie.info/",
  "https://baraag.net/",
  "https://nhentai.net/",
  "https://inkbunny.net/",
  "https://e-hentai.org/",
  "https://hentai2read.com/",
}

M.requireDownload = {
  "https://hitomi.la/",
  "https://misskey.io/",
  "https://sankaku.app/",
  "https://exhentai.org/",
  "https://kemono.party/",
  "https://www.pixiv.net/",
  "https://www.deviantart.com/",
  "https://chan.sankakucomplex.com/",
}

---@return boolean|table
function M.getDirectoryInfo(directory)
  return pcall(fs.readdirSync, directory);
end

local function hasFile(file)
  return file or file[1];
end

local function hasUrl(url)
  return url ~= '';
end

local function editErrorMessage(value, err)
  local errmsg = "Could not deliver images from `" .. value .. "` nanora!\nReason: `"
  if err and err ~= "" then
    if err:find("empty message") then
      errmsg = errmsg .. err .. "`. Maybe Nanako stole the images I was going to send nanora!";
    else
      errmsg = errmsg .. err .. "`, nanora.";
    end
  else
    err = "Not even God knows why nanora...";
    errmsg = errmsg .. err .. "`";
  end

  return errmsg;
end

local function checkSuccess(success, err, message, value)
  if not success then
    local t = {
      "🇳","🇴"
    }
    for _, emoji in ipairs(t) do
      message:addReaction(emoji);
    end

    local errmsg = editErrorMessage(value, err);
    return errmsg;
  end
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

  if hasFile(messageToSend.files) then
    return message.channel:send(messageToSend);
  else
    return false, "Couldn't get images to send! Maybe I can't access the website nora..."
  end
end

local function removeDirectory(dirName)
  local directory = "./temp/" .. dirName;
  local exists, files = M.getDirectoryInfo(directory);
  if exists and not files[1] then -- to avoid error messages on terminal
    fs.rmdir(directory);
  end
end

local function deleteDownloadedImage(file, id)
  for _, value in ipairs(file) do
    fs.unlinkSync(value);
  end

  removeDirectory(id);
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

local function sendImages(message, separatedFilestbl, source, hasMultipleLinks)
  local err = nil
  if hasFile(separatedFilestbl) then
    local success;
    if hasMultipleLinks then
      success, err = sendDownloadedImage(message, separatedFilestbl, source);
    else
      success, err = sendDownloadedImage(message, separatedFilestbl);
    end
    err = checkSuccess(success, err, message, source);
  end
  return err
end

local function sendPartitionedImages(message, wholeFilestbl, source, hasMultipleLinks)
  local partitionedFilestbl = {}
  local errors = {}

  for index, file in ipairs(wholeFilestbl)  do

    table.insert(partitionedFilestbl, file)

    if #partitionedFilestbl == 10 or index == #wholeFilestbl then

      local err = sendImages(message, partitionedFilestbl, source, hasMultipleLinks)
      table.insert(errors, err)

      partitionedFilestbl = {}

    end
  end

  return errors
end


function M.verify(string, list)
  for _, value in pairs(list) do
    if string:find(value) then
      return true;
    end
  end

  return false;
end

function M.sendTwitterDirectVideoUrl(message, info)
  local source = info.link
  local multipleLinks = info.multipleLinks
  local url = gallerydl.getUrl(source, info.limit);
  if url:find("video.twimg") then
    local success, err;
    if multipleLinks then
      success, err = sendUrl(message, url, source);
    else
      success, err = sendUrl(message, url);
    end
    checkSuccess(success, err, message, source);
    return true;
  end
  return false;
end

function M.sendDirectImageUrl(message, info)
  local source = info.link
  local limit = info.limit
  local multipleLinks = info.multipleLinks
  if source:find("https://baraag.net/") then
    source = source:gsub("web/", '');
  end

  local url = gallerydl.getUrl(source, limit);

  if hasUrl(url) then
    if shouldSendBaraagLinks(url) or not url:find("https://baraag.net/") then
      local success, err;
      if multipleLinks then
        success, err = sendUrl(message, url, source);
      else
        success, err = sendUrl(message, url);
      end
      checkSuccess(success, err, message, source);
    end
  end
end

function M.downloadSendAndDeleteImages(message, info)
  local id = message.channel.id;
  local source = info.link
  local limit = info.limit
  local multipleLinks = info.multipleLinks
  local wholeFilestbl = gallerydl.downloadImage(source, id, limit)
  local errors = {}

  if not wholeFilestbl then return end

  if #wholeFilestbl > 10 then
    errors = sendPartitionedImages(message, wholeFilestbl, source, multipleLinks)
  else
    local err = sendImages(message, wholeFilestbl, source, multipleLinks)
    table.insert(errors, err)
  end

  deleteDownloadedImage(wholeFilestbl, id);

  local errorstr = table.concat(errors, '\n')
  if errorstr ~= '' then
    return errorstr
  else
    return nil
  end
end

function M.sendTwitterImages(message, info)
  local client = info.client
  if not message.embed then
    if not client:waitFor("messageUpdate", 5000) then
      M.downloadSendAndDeleteImages(message, info);
    end
  end
end

return M;
