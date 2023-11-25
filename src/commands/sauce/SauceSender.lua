local fs = require("fs")
local constant = require("./constants")
local analyser = require("./linkAnalyser")
local discordia = require("discordia")
local timer = require("timer")
local clock = discordia.Clock()
local class = discordia.class
local format = string.format
discordia.extensions()

local SAUCE_ASSETS = "assets/images/sauce/"
local FOOTER_ICON = "tsih-icon.png"

local SauceSender, get = class("SauceSender")

---@param message Message
---@param gallerydl Gallerydl
---@param multipleLinks boolean
function SauceSender:__init(message, gallerydl, multipleLinks)
  self._message = message
  self._gallerydl = gallerydl
  self._multipleLinks = multipleLinks
end

local failEmojis = {
  "🇳","🇴"
}

---@return boolean|table
local function getDirectoryInfo(directory)
  return pcall(fs.readdirSync, directory)
end

local function hasFile(filetbl)
  return filetbl or filetbl[1]
end

local function hasString(str)
  return str ~= ''
end

---Just a little "notification"
local function react(message)
  coroutine.wrap(function ()
    for _, emoji in ipairs(failEmojis) do message:addReaction(emoji)    end
    timer.sleep(1000)
    for _, emoji in ipairs(failEmojis) do message:removeReaction(emoji) end
  end)()
end

---Returns true if one of the list of messages couldn't be sent
local function checkErrors(t)
  for _, v in ipairs(t) do
    if not v then return true end
  end
  return false
end

local function removePath(t)
  local t2 = {}
  for index, filePath in ipairs(t) do
    t2[index] = filePath:gsub(".*/", "")
  end
  return t2
end

local function findVideos(fileNames)
  for _, name in ipairs(fileNames) do
    if name:find(".mp4") then
      return true
    end
  end
  return false
end

local function addAdditionalAttachments(embeds, fileNames)
  for i, fileName in ipairs(fileNames) do
    if embeds[i] == nil then
      embeds[i] = {}
    end
    embeds[i].type = "rich"
    embeds[i].url = embeds[1].url
    embeds[i].image = { url = format("attachment://%s", fileName) }
  end
  return embeds
end

local function makeEmbededMessage(messageToSend, pageJson, sourceLink)
  --local directLink = pageJson[2][2]
  pageJson = pageJson[#pageJson][3]
  local files = table.copy(messageToSend.files)
  local fileNames = removePath(files)
  table.insert(files, SAUCE_ASSETS..FOOTER_ICON)
  local embeds = {
    {
      type = "rich",
      color = 0x80fdff,
      timestamp = pageJson.date,
      url = sourceLink,

      author = {
        url = sourceLink,
        icon_url = pageJson.author.profile_image,
        name = format("%s (@%s)", pageJson.author.nick, pageJson.author.name)
      },

      description = pageJson.content,

      fields = {
        {
          name = "Retweets 🔁",
          value = pageJson.retweet_count,
          inline = true
        },
        {
          name = "Likes 💖",
          value = pageJson.favorite_count,
          inline = true
        }
      },

      footer = {
        icon_url = "attachment://"..FOOTER_ICON,
        text = "Twitter"
      }
    }
  }

  if not findVideos(fileNames) then
    embeds = addAdditionalAttachments(embeds, fileNames)
  end

  return {
    content = messageToSend.content,
    reference = messageToSend.reference,
    files = files,
    embeds = embeds
  }
end

---@return Message
local function sendDownloadedImage(message, images, sourceLink, pageJson, guaranteedSourceLink)
  local messageToSend = {
    files = images,
    reference = {
      message = message,
      mention = false,
    }
  }

  if sourceLink then
    messageToSend.content = string.format("`%s`", sourceLink)
  end

  local msg

  if pageJson then
    msg = message.channel:send(makeEmbededMessage(messageToSend, pageJson, guaranteedSourceLink))
  else
    msg = message.channel:send(messageToSend)
  end

  return msg
end

---@return Message
local function sendLink(message, outputLink, link)
  local messageToSend = {
    reference = {
      message = message,
      mention = false
    }
  }

  if link then -- attach original link before it's contents
    messageToSend.content = string.format("`%s`\n%s", link, outputLink)
  else
    messageToSend.content = outputLink
  end

  return message.channel:send(messageToSend)
end

local function removeDirectory(dirName)
  local directory = string.format("./temp/%s", dirName)
  local exists, files = getDirectoryInfo(directory)
  if exists and not files[1] then
    fs.rmdir(directory)
  end
end

local function deleteDownloadedImage(file, id)
  for _, value in ipairs(file) do
    fs.unlinkSync(value)
  end
  removeDirectory(id)
end

local function shouldSendBaraagLinks(link)
  local quantity = 0
  for _, value in ipairs(link:split('\n')) do
    if value:find(constant.BARAAG_MEDIA) and value:find(".mp4") then
      return true
    elseif value:find(constant.BARAAG_MEDIA) then
      quantity = quantity + 1
    end
  end
  return quantity > 1
end

local function sendImages(message, separatedFilestbl, sourceLink, hasMultipleLinks, pageJson, guaranteedSourceLink)
  local msg = sendDownloadedImage(message, separatedFilestbl, hasMultipleLinks and sourceLink, pageJson, guaranteedSourceLink)
  if not msg then react(message) end
  return msg
end

local function sendPartitionedImages(message, filestbl, sourceLink, hasMultipleLinks, pageJson, guaranteedSourceLink)
  local msgs = {}
  local partitionedFilestbl = {}
  for index, file in ipairs(filestbl)  do
    table.insert(partitionedFilestbl, file)
    if #partitionedFilestbl == 10 or index == #filestbl then
      local msg = sendImages(message, partitionedFilestbl, sourceLink, hasMultipleLinks, pageJson, guaranteedSourceLink)
      table.insert(msgs, msg)
      partitionedFilestbl = {}
    end
  end
  return msgs
end



---Gets the content's direct link to send. This function does not expect twitter links.
function SauceSender:sendImageLink()
  local message, gallerydl, hasMultipleLinks = self._message, self._gallerydl, self._multipleLinks
  local link = gallerydl.link

  if link:find(constant.BARAAG_LINK) then
    link = link:gsub("web/", '')
  end

  local outputLink = gallerydl:getLink()

  if hasString(outputLink) then
    if shouldSendBaraagLinks(outputLink) or not outputLink:find(constant.BARAAG_LINK) then
      local msg = sendLink(message, outputLink, hasMultipleLinks and link)
      if not msg then react(message) end
    end
  end
end

---Downloads files, send them into a channel and deletes them from host after finished.
---@return boolean success
---@return string gallerydlOutput
function SauceSender:downloadSendAndDeleteImages()
  local message, gallerydl, hasMultipleLinks = self._message, self._gallerydl, self._multipleLinks
  local sourceLink = gallerydl.link
  local id = message.channel.id
  local okMsgs = {}
  local msg = {}
  local wholeFilestbl, gallerydlOutput, pageJson

  if analyser.isTwitter(sourceLink) then
    if not message.embed then
      --if not clock:waitFor("messageUpdate", 5000) then
        wholeFilestbl, gallerydlOutput = gallerydl:downloadImage()
        pageJson = gallerydl:getJson()
      --end
    end
  else
    wholeFilestbl, gallerydlOutput = gallerydl:downloadImage()
  end

  if not wholeFilestbl or not hasFile(wholeFilestbl) then
    react(message)
    return false, gallerydlOutput
  end

  if #wholeFilestbl > 10 then
    local msgs = sendPartitionedImages(message, wholeFilestbl, sourceLink, hasMultipleLinks, pageJson, sourceLink)
    for _, returnedMsg in ipairs(msgs) do
      table.insert(okMsgs, returnedMsg)
    end
  else
    msg = sendImages(message, wholeFilestbl, sourceLink, hasMultipleLinks, pageJson, sourceLink)
    table.insert(okMsgs, msg)
  end

  deleteDownloadedImage(wholeFilestbl, id)

  if checkErrors(okMsgs) then
    return false, gallerydlOutput
  end

  return true, gallerydlOutput
end

function get.gallerydl(self) return self._gallerydl end

return SauceSender
