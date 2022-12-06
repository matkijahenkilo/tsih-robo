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

local function sendCuteness(channel, fileType)
  local list = fileTables[fileType];

  local fileToSend = list[math.random(#list)]; -- filename must not have weird characters, spaces nor '()' and '+'
  local file = ORIGIN .. fileType .. '/' .. fileToSend;

  channel:send {
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

  print("Sent Tsih O'Clock file: " .. fileToSend);
end

local function tsihClock(channel, fileType)
  if channel == nil then return false end


  if fileType == "gif" or fileType == "image" then
    sendCuteness(channel, fileType);
    return true;
  end

  if math.random() <= 0.1 then
    sendCuteness(channel, "gif");
  else
    sendCuteness(channel, "image");
  end

  return true;
end

local function sign(message)
  local ids = fs.readFileSync(IDS_PATH);
  local id = message.channel.id;
  local t = {};
  if ids then
    t = json.decode(ids);
  end

  if t[1] then

    for _, value in ipairs(t) do
      if value.id == id then
        message:reply("Room is already signed for Tsih O'Clock!");
        return;
      end
    end

  end

  table.insert(t, { id = id });
  fs.writeFileSync(IDS_PATH, json.encode(t));

  message:reply("This room is now signed for Tsih O'Clock nanora!");
end

local function remove(message)
  local ids = fs.readFileSync(IDS_PATH)
  local id = message.channel.id;
  if ids then

    local t = json.decode(ids);
    for key, value in pairs(t) do
      if value.id == id then
        table.remove(t, key);
        fs.writeFileSync(IDS_PATH, json.encode(t));
        message:reply("Done! How can you meanies see my cuteness daily now nanora!?");
        return;
      end
    end

  end
  message:reply("B-but this room isn't even signed up nora!");
end

local function sendAllTOC(client)
  local ids = fs.readFileSync(IDS_PATH);
  if ids then
    local t = json.decode(ids);
    local total = 0;

    for _, value in pairs(t) do
      total = total + 1;
      coroutine.wrap(function ()

        tsihClock(client:getChannel(value.id));

      end)();
    end
    print("Sending " .. total .. " Tsih's fan arts nanora!");
  end
end

return {
  description = {
    title = "tsihClock",
    description = "e.g: ts!tsihClock sign\nts!tsihClock manual gif",
    color = 0xff5080,
    fields = {
      {
        name = "sign",
        value = "If you sign the chatroom, I will send an artwork of mine to this room every 9PM nanora! ||except for private chats because discord nora.||"
      },
      {
        name = "remove",
        value = "If the channel is signed up for Tsih O'Clock, I'll stop sending my artworks nanora!"
      },
      {
        name = "manual",
        value = "I'll send you an artwork without signing your room.\n"
            .. "This argument can be followed with `gif` or `image` for custom formats nanora!"
      },
    },
  },
  execute = function(message, args, client)
    if args[2] == "sign" then
      sign(message);
    elseif args[2] == "remove" then
      remove(message);
    elseif args[2] == "manual" then
      tsihClock(message.channel, args[3]);
    elseif args[2] == "auto" and message.author.id == "206755895181312003" then
      sendAllTOC(client);
    else
      message:reply("what nanora?!\nArguments for this command is `sign`, `remove` and `manual` nora!");
    end
  end,
  executeWithTimer = function(client)
    sendAllTOC(client);
  end;
};
