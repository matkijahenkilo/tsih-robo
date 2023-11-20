local fs = require("fs")
local Gallerydl = require("./Gallerydl")
local constant = require("./constants")
local discordia = require("discordia")
local clock = discordia.Clock()
local class = discordia.class

local SauceSender, get = class("SauceSender")

---@param message Message
---@param link string
---@param info table
function SauceSender:__init(message, link, info)
  self._message = message
  self._info = info
  self._link = link
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

local function removeReact(message)
  message:clearReactions()
end

---just a little "notification"
local function react(message)
  for _, emoji in ipairs(failEmojis) do
    message:addReaction(emoji)
  end
  removeReact(message)
end

---Returns true if a message couldn't be sent
local function checkErrors(t)
  for _, v in ipairs(t) do
    if not v then return true end
  end
  return false
end

---@return Message
local function sendDownloadedImage(message, images, link)
  local messageToSend = {
    files = images,
    reference = {
      message = message,
      mention = false,
    }
  }

  if link then
    messageToSend.content = string.format("`%s`", link)
  end

  return message.channel:send(messageToSend)
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

local function sendImages(message, separatedFilestbl, link, hasMultipleLinks)
  local msg = sendDownloadedImage(message, separatedFilestbl, hasMultipleLinks and link)
  if not msg then react(message) end
  return msg
end

local function sendPartitionedImages(message, wholeFilestbl, link, hasMultipleLinks)
  local msgs = {}
  local partitionedFilestbl = {}
  for index, file in ipairs(wholeFilestbl)  do
    table.insert(partitionedFilestbl, file)
    if #partitionedFilestbl == 10 or index == #wholeFilestbl then
      local msg = sendImages(message, partitionedFilestbl, link, hasMultipleLinks)
      table.insert(msgs, msg)
      partitionedFilestbl = {}
    end
  end
  return msgs
end


---@return boolean success
function SauceSender:sendTwitterVideoLink()
  local message, info, link = self._message, self._info, self._link
  local hasMultipleLinks = info.multipleLinks
  local outputLink = Gallerydl(link, nil, info.limit):getLink()
  if outputLink:find(constant.TWITTER_VIDEO) then
    local msg = sendLink(message, outputLink, hasMultipleLinks and link)
    if not msg then react(message) end
    return true
  end
  return false
end

function SauceSender:sendImageLink()
  local message, info, link = self._message, self._info, self._link
  local limit = info.limit
  local hasMultipleLinks = info.multipleLinks

  if link:find(constant.BARAAG_LINK) then
    link = link:gsub("web/", '')
  end

  local outputLink = Gallerydl(link, nil, limit):getLink()

  if hasString(outputLink) then
    if shouldSendBaraagLinks(outputLink) or not outputLink:find(constant.BARAAG_LINK) then
      local msg = sendLink(message, outputLink, hasMultipleLinks and link)
      if not msg then react(message) end
    end
  end
end

---Downloads files, send them into a channel and deletes them from host after finished.
---@return boolean success
---@return string | nil discordError
---@return string gallerydlOutput
function SauceSender:downloadSendAndDeleteImages()
  local message, info, link = self._message, self._info, self._link
  local id = self._message.channel.id
  local hasMultipleLinks = info.multipleLinks
  local okMsgs = {}
  local msg = {}

  local wholeFilestbl, gallerydlOutput = Gallerydl(link, id, info.limit):downloadImage()

  if not wholeFilestbl or not hasFile(wholeFilestbl) then
    react(message)
    return false, string.format(constant.WARNING_NO_FILE, link), gallerydlOutput
  end

  if #wholeFilestbl > 10 then
    local msgs = sendPartitionedImages(message, wholeFilestbl, link, hasMultipleLinks)
    for _, returnedMsg in ipairs(msgs) do
      table.insert(okMsgs, returnedMsg)
    end
  else
    msg = sendImages(message, wholeFilestbl, link, hasMultipleLinks)
    table.insert(okMsgs, msg)
  end

  deleteDownloadedImage(wholeFilestbl, id)

  if checkErrors(okMsgs) then
    return false, string.format(constant.WARNING_NO_FILE, link), gallerydlOutput
  end

  return true, nil, gallerydlOutput
end

function SauceSender:sendTwitterImages()
  if not self._message.embed then
    if not clock:waitFor("messageUpdate", 5000) then
      SauceSender.downloadSendAndDeleteImages(self)
    end
  end
end

function get.link(self)    return self._link    end
function get.message(self) return self._message end

return SauceSender