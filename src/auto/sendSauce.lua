local SAUCE_LIMITS_JSON = "src/data/sauceLimits.json";

local spawn = require("coro-spawn");
local fs = require("fs");
local json = require("json");
require('discordia').extensions();

local doesNotRequireDownload = {
  "https://e621.net/",
  "https://booru.io/",
  "https://pawoo.net/",
  "https://nijie.info/",
  "https://baraag.net/",
  "https://nhentai.net/",
  "https://kemono.party/",
  "https://inkbunny.net/",
  "https://e-hentai.org/",
  "https://hentai2read.com/",
}

local requireDownload = {
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

local function getSpecificLinks(t, string)
  local specificLinks = {};
  for _, value in ipairs(t:split("\n")) do
    if value:find(string) then
      table.insert(specificLinks, value);
    end
  end
  return specificLinks;
end

local function getBaraagImageFromTheSecondLink(t)
  local baraagLink = {};
  for index, value in ipairs(t:split("\n")) do
    if index == 2 then
      table.insert(baraagLink, value);
    elseif index > 2 then
      table.insert(baraagLink, '\n' .. value);
    end
  end
  return baraagLink;
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
      return getBaraagImageFromTheSecondLink(link);
    end
  end

  return linksTable;
end

local function checkSuccess(success, err, message, value)
  if not success then
    p("Couldn't get link: " .. value, "Reason: " .. err);
    message:addReaction("🇳");
    message:addReaction("🇴");
  end
end

local function downloadImage(url, id, limit)
  local child = spawn("gallery-dl", {
    args = {
      "--cookies", "cookies.txt",
      "--range", "1-" .. limit, "--ugoira-conv",
      "-D", "./temp/" .. id .. "/",
      url
    }
  });

  local file = table.concat(readProcess(child));
  file = file:gsub("# ", '');
  file = file:split("\n");
  table.remove(file, #file);

  return file;
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

local function verify(string, list)
  for _, value in pairs(list) do
    if string:find(value) then
      return true;
    end
  end

  return false;
end

local function sendTwitterDirectVideoUrl(value, message, limit)
  local url = getUrl(value, limit);
  if url:find("video.twimg") then

    local success, err = sendUrl(message, url);
    checkSuccess(success, err, message, value);

  end
end

local function sendDirectImageUrl(value, message, limit)
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

local function downloadSendAndDeleteImages(value, message, limit)
  local id = message.channel.id;
  local file = downloadImage(value, id, limit);

  if hasFile(file) then

    local success, err = sendDownloadedImage(message, file);
    checkSuccess(success, err, message, value);

  end

  deleteDownloadedImage(file, id);
end

local function createJson(newLimit, guildId, channelId)
  local newGuildRule = {
    [guildId] = {
      [channelId] = newLimit
    }
  };
  fs.writeFileSync(SAUCE_LIMITS_JSON, json.encode(newGuildRule));
end

local function verifyIfRuleExists(t, guildId, channelId)
  if t[guildId] then
    return t[guildId][channelId] ~= nil;
  end
  return false;
end

local function replaceChannelRule(t, newLimit, guildId, channelId)
  t[guildId][channelId] = newLimit;

  fs.writeFileSync(SAUCE_LIMITS_JSON, json.encode(t));
end

local function addGuildAndChannelRule(t, newLimit, guildId, channelId)
  if not t[guildId] then t[guildId] = {} end
  t[guildId][channelId] = newLimit;

  fs.writeFileSync(SAUCE_LIMITS_JSON, json.encode(t));
end

local function setSauceLimit(message)
  if not message.guild then
    message:reply("This function does not work with DMs nanora!");
    return;
  end

  local args = message.content:split(' ');
  local guildId = message.guild.id;
  local channelId = message.channel.id;
  local newLimit = tonumber(args[2]);

  if not newLimit then
    message.channel:send("Please set a limit for the saucy images I send nanora!");
    return;
  elseif newLimit <= 0 then
    newLimit = 0;
  elseif newLimit > 10 then
    newLimit = 10;
  end

  local rawJson = fs.readFileSync(SAUCE_LIMITS_JSON);
  local jsonContent = nil;
  if rawJson then
    jsonContent = json.decode(rawJson);
  end

  if not jsonContent then
    createJson(newLimit, guildId, channelId);
    return;
  end

  if verifyIfRuleExists(jsonContent, guildId, channelId) then
    replaceChannelRule(jsonContent, newLimit, guildId, channelId);
  else
    addGuildAndChannelRule(jsonContent, newLimit, guildId, channelId);
  end

  if newLimit > 0 then
    message.channel:send("I will send up to " .. newLimit .. " images per link in this room nanora!");
  else
    message.channel:send("I won't be sending the link's sauces in this room anymore nanora!");
  end
end

local function getRoomImageLimit(message)
  if not message.guild then return end
  local guildId = message.guild.id;
  local channelId = message.channel.id;

  local rawJson = fs.readFileSync(SAUCE_LIMITS_JSON);
  if rawJson then
    local t = json.decode(rawJson);
    if not t then return end
    if t[guildId] then
      return t[guildId][channelId];
    end
  end
end

local function sendSauce(message)
  if message.content:find("https://") then

    local content = message.content:gsub('\n', ' '):gsub('||', ' ');
    local t = content:split(' ');

    local limit = getRoomImageLimit(message) or 5;
    if limit == 0 then return end

    for _, value in ipairs(t) do
      if value ~= '' then
        coroutine.wrap(function ()
          if verify(value, doesNotRequireDownload) then

            sendDirectImageUrl(value, message, limit);

          elseif verify(value, requireDownload) then

            downloadSendAndDeleteImages(value, message, limit);

          elseif value:find("https://twitter.com/") then

            sendTwitterDirectVideoUrl(value, message, limit);

          end
        end)();
      end
    end

  end
end

return {
  description = {
    title = "sauce",
    description = "I'll automatically send the link's content if it's a link that does not embed properly in Discord nora!"
      .. "\n\nI try to not spam a lot of images by sending up to 5 images per link, but you can make me send up to 10 images per link with `ts!sauce 10` if there's a lot of images in, let's say, a Pixiv post nora!"
      .. "\nYou can disable this automatic command by using `ts!sauce 0` too nora.",
    color = 0xff5080,
    fields = {
      {
        name = "[Integer]",
        value = "Sets a limit of images that I can send per message nanora!"
      }
    }
  },
  getSlashCommand = function (tools)
    return tools.getSlashCommand("setsaucelimit", "Sets a limit for images I send on this text channel when getting images from websites nanora!")
      :addOption(tools.integer("limit", "Default is 5 nanora!")
      :setRequired(true)
    );
  end,
  execute = function (message)
    setSauceLimit(message);
  end,
  autoExecute = function (message)
    sendSauce(message);
  end
}
