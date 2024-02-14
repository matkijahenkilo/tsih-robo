local fs = require("fs")
local discordia = require("discordia")
local timer = require("timer")
local class = discordia.class
local format = string.format
discordia.extensions()

local BARAAG_MEDIA = "media.baraag.net"
local SAUCE_ASSETS = "assets/images/sauce/"
local FOOTER_ICON = "tsih-icon.png"

local SauceSender, get = class("SauceSender")

---@param message Message
---@param gallerydl Gallerydl
---@param multipleLinks boolean
function SauceSender:__init(message, gallerydl, multipleLinks, client)
  self._message = message
  self._gallerydl = gallerydl
  self._multipleLinks = multipleLinks
  self._client = client
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
local function sendDownloadedImage(self, files, pageJson)
  local message = self._message
  local sourceLink = self._multipleLinks and self._gallerydl.link
  local messageToSend = {
    files = files,
    reference = {
      message = message,
      mention = false,
    }
  }

  if sourceLink then
    messageToSend.content = string.format("<%s>", sourceLink)
  end

  local msg

  if pageJson then
    msg = message.channel:send(makeEmbededMessage(messageToSend, pageJson, self._gallerydl.link))
  else
    msg = message.channel:send(messageToSend)
  end

  return msg
end

---@return Message
local function sendLink(self, outputLink)
  local message = self._message
  local sourceLink = self._multipleLinks and self._gallerydl.link
  local messageToSend = {
    reference = {
      message = message,
      mention = false
    }
  }

  if sourceLink then -- attach original link before it's contents
    messageToSend.content = string.format("<%s>\n%s", sourceLink, outputLink)
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
    if value:find(BARAAG_MEDIA) and value:find(".mp4") then
      return true
    elseif value:find(BARAAG_MEDIA) then
      quantity = quantity + 1
    end
  end
  return quantity > 1
end

local function sendImages(self, separatedFilestbl, pageJson)
  local msg = sendDownloadedImage(self, separatedFilestbl, pageJson)
  if not msg then
    react(self._message)
  end
  return msg
end

local function sendPartitionedImages(self, filestbl, pageJson)
  local msgs = {}
  local partitionedFilestbl = {}
  for index, file in ipairs(filestbl)  do
    table.insert(partitionedFilestbl, file)
    if #partitionedFilestbl == 10 or index == #filestbl then
      local msg = sendImages(self, partitionedFilestbl, pageJson)
      table.insert(msgs, msg)
      partitionedFilestbl = {}
    end
  end
  return msgs
end



---Gets the content's direct link to send. This function does not expect twitter links.
---@return boolean success
function SauceSender:sendImageLink()
  local message, gallerydl = self._message, self._gallerydl

  local outputLink = gallerydl:getLink()

  if hasString(outputLink) then
    if shouldSendBaraagLinks(outputLink) or not outputLink:find(BARAAG_MEDIA) then
      local msg = sendLink(self, outputLink)
      if not msg then
        react(message)
        return false
      end
    end
  end

  return true
end

---Downloads files, send them into a channel and deletes them from host after finished.
---@return boolean success
---@return string|nil output
function SauceSender:downloadSendAndDeleteImages()
  local message, gallerydl = self._message, self._gallerydl
  local id = message.channel.id
  local okMsgs = {}
  local msg = {}
  local wholeFilestbl, pageJson, output

  -- I hate twitter
  if gallerydl.linkParser:isTwitter() then
    if not message.embed then
      --if doesn't update, download anyway
      if not self._client:waitFor("messageUpdate", 5000) then
        wholeFilestbl, output = gallerydl:downloadImage()
        pageJson = gallerydl:getJson()
      else
        --if updates but it's a video or doesn't have an image attached, download it
        if not message.embed.image or gallerydl.linkParser.isTwitterVideo(message.embed.image.url) then
          wholeFilestbl, output = gallerydl:downloadImage()
          pageJson = gallerydl:getJson()
        end
      end
    else
      --if is already embedded and it's a video or doesn't have image, download it
      if not message.embed.image or gallerydl.linkParser.isTwitterVideo(message.embed.image.url) then
        wholeFilestbl, output = gallerydl:downloadImage()
        pageJson = gallerydl:getJson()
      else
        return true, "Already embeded"
      end
    end
  else
    wholeFilestbl, output = gallerydl:downloadImage()
  end

  if not wholeFilestbl or not hasFile(wholeFilestbl) then
    react(message)
    return false, output
  end

  if #wholeFilestbl > 10 then
    local msgs = sendPartitionedImages(self, wholeFilestbl, pageJson)
    for _, returnedMsg in ipairs(msgs) do
      table.insert(okMsgs, returnedMsg)
    end
  else
    msg = sendImages(self, wholeFilestbl, pageJson)
    table.insert(okMsgs, msg)
  end

  deleteDownloadedImage(wholeFilestbl, id)

  if checkErrors(okMsgs) then
    react(message)
    return false, output
  end

  return true
end

function get.gallerydl(self) return self._gallerydl end

return SauceSender
