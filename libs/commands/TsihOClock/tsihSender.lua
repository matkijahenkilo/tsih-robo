local ORIGIN = "assets/images/tsihoclock/"
local dataManager = require("utils").DataManager("TsihOClock")
local fs = require("fs")
local counterHandler = require("./counterHandler.lua")
local discordia = require("discordia")

local M = {}

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

local function getTsihArtworkWithEmbedMessage(fileFormat)
  local list = fileTables[fileFormat]

  local fileToSend = list[math.random(#list)] -- filename must not have weird characters, spaces nor '()' and '+'
  local file = ORIGIN .. fileFormat .. '/' .. fileToSend
  local tsihClockCounter = counterHandler.getCurrentCounter()

  local embeddedMessage = {
    file = file,
    embed = {
      title = randomTitle[math.random(#randomTitle)]
        .. "\nThis is the Tsih O'Clock #" .. tsihClockCounter .. " nanora!",
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
  }

  if type(tsihClockCounter) == "string" then
    embeddedMessage.embed.color = 0xfffd80
    return embeddedMessage
  end

  if tsihClockCounter % 2 == 0 then
    embeddedMessage.embed.color = 0x80fdff
  else
    embeddedMessage.embed.color = 0xff80fd
  end

  return embeddedMessage
end

local function sendCuteness(channel, fileType)
  if not channel then return end
  local art = getTsihArtworkWithEmbedMessage(fileType)
  local ok, err = channel:send(art)
  if not ok then print(err) end
end

local function tsihClock(interaction, fileType)
  if fileType == "gif" or fileType == "image" then
    sendCuteness(interaction, fileType)
  else
    if math.random() <= 0.1 then
      sendCuteness(interaction, "gif")
    else
      sendCuteness(interaction, "image")
    end
  end
end

function M.sendAllTOC(client)
  dataManager.key = "tsihoclockids"
  local idTable = dataManager:readData()
  local total = 0

  if not idTable then
    print("Failed to run Tsih O'Clock, idTable is nil.")
    return
  end

  for _, value in pairs(idTable) do
    total = total + 1
    coroutine.wrap(function()
      tsihClock(client:getChannel(value.id))
      print("Sending artwork to " .. value.guildName)
    end)()
  end
  print("Sending " .. total .. " Tsih's fan arts nanora!")
end

function M.tsihClockSlash(interaction, format)
  if format then
    interaction:reply(getTsihArtworkWithEmbedMessage(format), true)
  else
    if math.random() <= 0.1 then
      interaction:reply(getTsihArtworkWithEmbedMessage("gif"), true)
    else
      interaction:reply(getTsihArtworkWithEmbedMessage("image"), true)
    end
  end
end

return M
