local limitHandler = require("../classes/sauce/LimitHandler");
local imageHandler = require("../classes/sauce/ImageSenderHandler");
require('discordia').extensions();

local function sendSauce(message, client)
  local content = message.content;
  if content then
    if content:find("https://") then
      content = content:gsub('\n', ' '):gsub('||', ' ');
      local t = content:split(' ');
      local limit = limitHandler.getRoomImageLimit(message) or 5;

      if limit == 0 then return end

      for _, value in ipairs(t) do
        if value ~= '' then
          coroutine.wrap(function()
            if imageHandler.verify(value, imageHandler.doesNotRequireDownload) then
              imageHandler.sendDirectImageUrl(value, message, limit);
            elseif imageHandler.verify(value, imageHandler.requireDownload) then
              imageHandler.downloadSendAndDeleteImages(value, message, limit);
            elseif value:find("https://twitter.com/") then
              if not imageHandler.sendTwitterDirectVideoUrl(value, message, limit) then
                imageHandler.sendTwitterImages(value, message, limit, client)
              end
            end
          end)();
        end
      end
    end
  end
end

local function sendAnySauce(message)
  local content = message.content;
  if content then
    if content:find("https://") then
      content = content:gsub('\n', ' '):gsub('||', ' ');
      local t = content:split(' ');
      local limit = limitHandler.getRoomImageLimit(message) or 5;

      if limit == 0 then return end

      for _, value in ipairs(t) do
        if value ~= '' and value:find("https://") then
          coroutine.wrap(function()
            imageHandler.downloadSendAndDeleteImages(value, message, limit);
          end)();
        end
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
    sendAnySauce(message);
  end,
  sendSauce = function(message, client)
    sendSauce(message, client);
  end
}
