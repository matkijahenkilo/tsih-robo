local commands = {
  hello     = require("../commands/hello"),
  echo      = require("../commands/echo"),
  hug       = require("../commands/hug"),
  avatar    = require("../commands/avatar"),
  pinch     = require("../commands/pinch"),
  question  = require("../commands/question"),
  tsihClock = require("../commands/tsihClock"),
  song      = require("../commands/song2"),
  giveRole  = require("../commands/giveRole"),
  sauce     = require("../auto/sendSauce.lua"),
};

local answers = {
  "https://tenor.com/view/anya-forger-anya-spy-x-family-sxf-speechbubble-gif-25813545",
  "https://tenor.com/view/fifo-hot-dog-sausage-spin-trick-gif-26299391",
  "https://tenor.com/view/touhou-speech-bubble-cirno-touhou-meme-gif-25609623",
  "https://tenor.com/view/bird-speech-bubble-funny-gif-25189137",
  "https://c.tenor.com/JG5LGxIDpzcAAAAM/big-boss-metal-gear-big-boss.gif",
  "https://media.discordapp.net/attachments/401817972148273183/973612289968181318/60060E53-8BCB-4299-8315-A5D14CA899DB-2.gif",
  "https://tenor.com/view/jerma-jerma-sus-jerma985-sus-jerma-jeremy-gif-25376340",
  "https://tenor.com/view/changed-game-gif-25542903",
  "https://tenor.com/view/american-psycho-willem-dafoe-duh-duhh-obviously-gif-16794513",
  "https://media.discordapp.net/attachments/741945274901200897/942858131346706442/worm.gif",
  "https://tenor.com/view/speech-bubble-argument-argument-fail-argument-when-argument-after-gif-24989784",
  "https://tenor.com/view/tewi-inaba-fumo-touhou-project-gif-22933353",
  "https://media.discordapp.net/attachments/837152549575327784/939504784082341928/greed.gif",
};

local commandsMetaTable = {
  __index = function ()
    local M = {};
    function M.execute(message)
      message:reply(answers[math.random(#answers)]);
      message.channel:send("@Tag me if you want to see my list of commands nanola~!");
    end
    return M;
  end
};

return setmetatable(commands, commandsMetaTable);
