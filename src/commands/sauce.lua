local limitHandler = require("../modules/sauce/LimitHandler");
local imageHandler = require("../modules/sauce/ImageSenderHandler");
require('discordia').extensions();

local function warnFail(interaction, link, err)
  if err then
    interaction:reply("Could not deliver images for `"..link.."` nanora!\n`"..err.."`", true);
  end
end

local function findLinksToSend(message, link, limit, client)
  coroutine.wrap(function()
    if imageHandler.verify(link, imageHandler.doesNotRequireDownload) then

      imageHandler.sendDirectImageUrl(link, message, limit);

    elseif imageHandler.verify(link, imageHandler.requireDownload) then

      imageHandler.downloadSendAndDeleteImages(link, message, limit);

    elseif link:find("https://twitter.com/") then

      if not imageHandler.sendTwitterDirectVideoUrl(link, message, limit) then
        imageHandler.sendTwitterImages(link, message, limit, client);
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

    if limit == 0 then return end

    for _, link in ipairs(t) do
      if link ~= '' then
        findLinksToSend(message, link, limit, client);
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

    if limit == 0 then return end

    for _, link in ipairs(t) do
      if link ~= '' and link:find("https://") then
        coroutine.wrap(function()
          local err = imageHandler.downloadSendAndDeleteImages(link, message, limit);
          warnFail(interaction, link, err);
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
            :setMinlink(0)
            :setMaxlink(10)
            :setRequired(true)
          )
        )
        :addOption(
          tools.subCommand("global", "Sets a limit for this entire server nanora!")
            :addOption(
              tools.integer("limit", "Default is 5 nanora! Input 0 if you don't want me to send images again nora!")
              :setMinlink(0)
              :setMaxlink(10)
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
