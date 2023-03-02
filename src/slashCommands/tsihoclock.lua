local ORIGIN = "assets/images/tsihoclock/";
local IDS_PATH = "src/data/tsihclockids.json";

local fs = require("fs");
local json = require("json");
local discordia = require("discordia");

local randomTitle = {
  "Wake up honey, It's Tsih O'Clock~!",
  "Pigyamoh! It's that time of the day again~!",
  "It's Tsih O'Clock~!",
}

local randomName = {
  "ぴぎゃもーう！",
  "にゃふふふ～",
  "にゅひひ！",
  "どりゃー！",
  "そーい！",
  "うりゃー！",
  "あたっくなのら！",
  "トラップなのら",
  "いぇーい！",
  "元気になったのら",
  "覚悟はいいのら？",
  "もっともっとなのら！",
  "ツィーなのら！よろ！",
}

local randomValue = {
  "Here's a cute picture of me, nora~!",
  "I'm here, once again!",
  "Tsih is here, yo!",
  "Poor Nanako, she still doesn't have a \"Nanako O'Clock\"!",
  "Behold nanora!",
  "Bless this incredible artist nanora~!",
  "私は君よりかわいいなのら！",
  "にゅふーにゅふー♪",
  "ぴぎゃーも♪　いい気分なのらー",
  "当たりなのら",
  "満足したのら？",
  "ラッキーなのらぁ！",
  "にゅはははは！　これも使っちゃうのら！",
}

local fileTables = {
  image = fs.readdirSync(ORIGIN .. "image"),
  gif = fs.readdirSync(ORIGIN .. "gif"),
}

local function sendCuteness(interaction, fileType, isSlashCommand)
  local channel = interaction.channel;
  if channel == nil then return end

  local list = fileTables[fileType];

  local fileToSend = list[math.random(#list)]; -- filename must not have weird characters, spaces nor '()' and '+'
  local file = ORIGIN .. fileType .. '/' .. fileToSend;
  local embed = {
    file = file,
    embed = {
      title = randomTitle[math.random(#randomTitle)],
      color = 0xff80fd,
      timestamp = discordia.Date():toISO('T', 'Z'),
      fields = {
        {
          name = randomName[math.random(#randomName)],
          value = randomValue[math.random(#randomValue)],
        },
      },
      image = {
        url = "attachment://" .. fileToSend,
      },
    },
  };

  if isSlashCommand then
    interaction:reply(embed, true);
  else
    channel:send(embed);
  end

  print("Sent Tsih O'Clock file: " .. fileToSend);
end

local function tsihClock(interaction, fileType, isSlashCommand)
  if fileType == "gif" or fileType == "image" then
    sendCuteness(interaction, fileType, isSlashCommand);
  else
    if math.random() <= 0.1 then
      sendCuteness(interaction, "gif", isSlashCommand);
    else
      sendCuteness(interaction, "image", isSlashCommand);
    end
  end
end

local function sign(interaction)
  local ids = fs.readFileSync(IDS_PATH);
  local id = interaction.channel.id;
  local t = {};
  if ids then
    t = json.decode(ids);
  end

  if t[1] then
    for _, value in ipairs(t) do
      if value.id == id then
        interaction:reply("Room is already signed for Tsih O'Clock!");
        return;
      end
    end
  end

  table.insert(t, { id = id });
  fs.writeFileSync(IDS_PATH, json.encode(t));

  interaction:reply("This room is now signed for Tsih O'Clock nanora!");
end

local function remove(interaction)
  local ids = fs.readFileSync(IDS_PATH)
  local id = interaction.channel.id;
  if ids then
    local t = json.decode(ids);
    for key, value in pairs(t) do
      if value.id == id then
        table.remove(t, key);
        fs.writeFileSync(IDS_PATH, json.encode(t));
        interaction:reply("Done! How can you meanies see my cuteness daily now nanora!?");
        return;
      end
    end
  end
  interaction:reply("B-but this room isn't even signed up nora!");
end

local function sendAllTOC(client)
  local ids = fs.readFileSync(IDS_PATH);
  if ids then
    local t = json.decode(ids);
    local total = 0;

    for _, value in pairs(t) do
      total = total + 1;
      coroutine.wrap(function()
        tsihClock(client:getChannel(value.id));
      end)();
    end
    print("Sending " .. total .. " Tsih's fan arts nanora!");
  end
end

local functions = {
  sign   = sign,
  unsign = remove,
  manual = tsihClock
}

return {
  getSlashCommand = function(tools)
    return tools.slashCommand("tsihoclock", "For signing text channels to receive daily Tsih artworks nanora!")
        :addOption(
          tools.subCommand("sign", "When used, I'll send a random artwork of me here everyday at 9PM nanora!")
        )
        :addOption(
          tools.subCommand("unsign", "I will not send artworks here anymore if used nora!")
        )
        :addOption(
          tools.subCommand("manual", "I'll manually send a (ephemeral) random artwork nora!")
          :addOption(
            tools.string("format", "You can specify if I send a gif or an image nora!")
            :addChoice(tools.choice("gif", "gif"))
            :addChoice(tools.choice("image", "image"))
          )
        );
  end,
  executeSlashCommand = function(interaction, command, args)
    local format;
    if args.manual then
      format = args.manual.format
    end

    functions[command.options[1].name](interaction, format, true);
  end,
  executeWithTimer = function(client)
    sendAllTOC(client);
  end,
};
