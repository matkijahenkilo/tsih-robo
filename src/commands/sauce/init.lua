local limitHandler = require("./limitHandler");
local imageSender = require("./imageSenderHandler");
require('discordia').extensions();

local function hasMultipleLinks(t)
  local count = 0
  for _, word in ipairs(t) do
    if imageSender.verify(word, imageSender.doesNotRequireDownload)
      or imageSender.verify(word, imageSender.requireDownload)
      or word:find("https://twitter.com/")
    then
      count = count + 1
      if count > 1 then return true end
    end
  end
  return false
end

local function warnFail(interaction, err)
  if err then
    interaction:reply(err, true);
  end
end

local function findLinksToSend(message, info)
  if imageSender.verify(info.link, imageSender.doesNotRequireDownload) then

    imageSender.sendDirectImageUrl(message, info);

  elseif imageSender.verify(info.link, imageSender.requireDownload) then

    imageSender.downloadSendAndDeleteImages(message, info);

  elseif info.link:find("https://twitter.com/") then

    if not imageSender.sendTwitterDirectVideoUrl(message, info) then
      imageSender.sendTwitterImages(message, info);
    end

  end
end

local function sendSauce(message, client)
  local content = message.content;
  if content and content:find("https://") then
    local limit = limitHandler.getRoomImageLimit(message) or 5;
    if limit == 0 then return end

    content = content:gsub('\n', ' '):gsub('||', ' ');
    local t = content:split(' ');
    local multipleLinks = hasMultipleLinks(t);

    for _, link in ipairs(t) do
      if link ~= '' then
        coroutine.wrap(function()
          local info = {
            link = link,
            limit = limit,
            client = client,
            multipleLinks = multipleLinks
          }
          findLinksToSend(message, info);
        end)();
      end
    end
  end
end

local function sendAnySauce(message, interaction)
  local content = message.content;
  if content and content:find("https://") then
    local limit = limitHandler.getRoomImageLimit(message) or 5;
    if limit == 0 then return end

    content = content:gsub('\n', ' '):gsub('||', ' ');
    local t = content:split(' ');
    local multipleLinks = hasMultipleLinks(t);

    for _, link in ipairs(t) do
      if link ~= '' and link:find("https://") then
        coroutine.wrap(function()
          local info = {
            link = link,
            limit = limit,
            multipleLinks = multipleLinks
          }
          local err = imageSender.downloadSendAndDeleteImages(message, info)
          warnFail(interaction, err)
        end)();
      end
    end
  end
end

return {
  getSlashCommand = function(tools)
    return tools.slashCommand("sauce", "Sets a limit for images I send nanora!")
        :addOption(
          tools.subCommand("channel", "Sets a limit for this channel only nanora!")
            :addOption(
              tools.integer("limit", "Default is 5 nanora! Input 0 if you don't want me to send images again nora!")
              :setMinValue(0)
              :setMaxValue(100)
              :setRequired(true)
            )
        )
        :addOption(
          tools.subCommand("global", "Sets a limit for this entire server nanora!")
            :addOption(
              tools.integer("limit", "Default is 5 nanora! Input 0 if you don't want me to send images again nora!")
              :setMinValue(0)
              :setMaxValue(10)
              :setRequired(true)
            )
        )
  end,

  getMessageCommand = function(tools)
    return tools.messageCommand("Send sauce");
  end,

  executeSlashCommand = function(interaction, _, args)
    if args.global then
      limitHandler.setSauceLimitOnServer(interaction, args.global);
    else
      limitHandler.setSauceLimitOnChannel(interaction, args.channel);
    end
  end,

  executeMessageCommand = function (interaction, _, message)
    coroutine.wrap(function () interaction:reply("Alrighty nanora! One second...", true) end)();
    sendAnySauce(message, interaction);
  end,

  sendSauce = function(message, client)
    sendSauce(message, client)
  end
}
