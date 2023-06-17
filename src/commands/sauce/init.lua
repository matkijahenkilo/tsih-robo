local limitHandler = require("./limitHandler");
local imageHandler = require("./imageSenderHandler");
require('discordia').extensions();

local function getLinksQuantity(t)
  local count = 0;
  for _, value in ipairs(t) do
    if value:find("https://") then
      count = count + 1;
      if count >= 2 then return count end -- lol
    end
  end
  return count;
end

local function warnFail(interaction, err)
  if err then
    interaction:reply(err, true);
  end
end

local function findLinksToSend(message, link, limit, client, hasMultipleLinks)
  coroutine.wrap(function()
    if imageHandler.verify(link, imageHandler.doesNotRequireDownload) then

      imageHandler.sendDirectImageUrl(link, message, limit, hasMultipleLinks);

    elseif imageHandler.verify(link, imageHandler.requireDownload) then

      imageHandler.downloadSendAndDeleteImages(link, message, limit, hasMultipleLinks);

    elseif link:find("https://twitter.com/") then

      if not imageHandler.sendTwitterDirectVideoUrl(link, message, limit, hasMultipleLinks) then
        imageHandler.sendTwitterImages(link, message, limit, client, hasMultipleLinks);
      end

    end
  end)();
end

local function sendSauce(message, client)
  local content = message.content;
  if content and content:find("https://") then
    content = content:gsub('\n', ' '):gsub('||', ' ');
    local t = content:split(' ');
    local limit = limitHandler.getRoomImageLimit(message) or 5;
    local hasMultipleLinks = false;

    if getLinksQuantity(t) > 1 then
      hasMultipleLinks = true;
    end

    if limit == 0 then return end

    for _, link in ipairs(t) do
      if link ~= '' then
        findLinksToSend(message, link, limit, client, hasMultipleLinks);
      end
    end

  end
end

local function sendAnySauce(message, interaction)
  local content = message.content;
  if content and content:find("https://") then
    content = content:gsub('\n', ' '):gsub('||', ' ');
    local t = content:split(' ');
    local limit = limitHandler.getRoomImageLimit(message) or 5;
    local hasMultipleLinks = false;

    if getLinksQuantity(t) > 1 then
      hasMultipleLinks = true;
    end

    if limit == 0 then return end

    for _, link in ipairs(t) do
      if link ~= '' and link:find("https://") then
        coroutine.wrap(function()
          local err = imageHandler.downloadSendAndDeleteImages(link, message, limit, hasMultipleLinks);
          warnFail(interaction, err);
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
            :setMaxValue(10)
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
    sendSauce(message, client);
  end
}
