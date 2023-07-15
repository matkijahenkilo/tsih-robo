local fs = require("fs")
local gallerydl = require("./gallerydl")
local constant = require("src.utils.constants")
local clock = require("discordia").Clock()

local failEmojis = {
  "🇳","🇴"
}

local M = {}

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

local function react(message)
  for _, emoji in ipairs(failEmojis) do
    message:addReaction(emoji)
  end
end

---Returns true if a message couldn't be sent
local function checkErrors(t)
  for _, v in ipairs(t) do
    if not v then return true end
  end
  return false
end

---@return Message
local function sendDownloadedImage(message, images, source)
  local messageToSend = {
    files = images,
    reference = {
      message = message,
      mention = false,
    }
  }

  if source then
    messageToSend.content = string.format("`%s`", source)
  end

  return message.channel:send(messageToSend)
end

local function sendUrl(message, url, source)
  local messageToSend = {
    reference = {
      message = message,
      mention = false
    }
  }

  if source then
    messageToSend.content = string.format("`%s`\n%s", source, url)
  else
    messageToSend.content = url
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

local function shouldSendBaraagLinks(url)
  local quantity = 0
  for _, value in ipairs(url:split('\n')) do
    if value:find(constant.BARAAG_MEDIA) and value:find(".mp4") then
      return true
    elseif value:find(constant.BARAAG_MEDIA) then
      quantity = quantity + 1
    end
  end
  return quantity > 1
end

local function sendImages(message, separatedFilestbl, source, hasMultipleLinks)
  local msg = sendDownloadedImage(message, separatedFilestbl, hasMultipleLinks and source)
  if not msg then react(message) end
  return msg
end

local function sendPartitionedImages(message, wholeFilestbl, source, hasMultipleLinks)
  local msgs = {}
  local partitionedFilestbl = {}
  for index, file in ipairs(wholeFilestbl)  do
    table.insert(partitionedFilestbl, file)
    if #partitionedFilestbl == 10 or index == #wholeFilestbl then
      local msg = sendImages(message, partitionedFilestbl, source, hasMultipleLinks)
      table.insert(msgs, msg)
      partitionedFilestbl = {}
    end
  end
  return msgs
end

function M.sendTwitterVideoUrl(message, info, source)
  local hasMultipleLinks = info.multipleLinks
  local url = gallerydl.getUrl(source, info.limit)
  if url:find(constant.TWITTER_VIDEO) then
    local msg = sendUrl(message, url, hasMultipleLinks and source)
    if not msg then react(message) end
    return true
  end
  return false
end

function M.sendImageUrl(message, info, source)
  local limit = info.limit
  local hasMultipleLinks = info.multipleLinks

  if source:find(constant.BARAAG_LINK) then
    source = source:gsub("web/", '')
  end

  local url = gallerydl.getUrl(source, limit)

  if hasString(url) then
    if shouldSendBaraagLinks(url) or not url:find(constant.BARAAG_LINK) then
      local ok = sendUrl(message, url, hasMultipleLinks and source)
      if not ok then react(message) end
    end
  end
end

---Downloads files, send them into a channel and deletes them after finished.
---@param message Message
---@param info table
---@param source string
---@return boolean success
---@return string | nil discordError
---@return string gallerydlOutput
function M.downloadSendAndDeleteImages(message, info, source)
  local id = message.channel.id
  local limit = info.limit
  local hasMultipleLinks = info.multipleLinks
  local wholeFilestbl, gallerydlOutput = gallerydl.downloadImage(source, id, limit)
  local okMsgs = {}
  local msg = {}

  if not wholeFilestbl or not hasFile(wholeFilestbl) then
    react(message)
    return false, string.format(constant.WARNING_NO_FILE, source), gallerydlOutput
  end

  if #wholeFilestbl > 10 then
    local msgs = sendPartitionedImages(message, wholeFilestbl, source, hasMultipleLinks)
    for _, returnedMsg in ipairs(msgs) do
      table.insert(okMsgs, returnedMsg)
    end
  else
    msg = sendImages(message, wholeFilestbl, source, hasMultipleLinks)
    table.insert(okMsgs, msg)
  end

  deleteDownloadedImage(wholeFilestbl, id)

  if checkErrors(okMsgs) then
    return false, string.format(constant.WARNING_NO_FILE, source), gallerydlOutput
  end

  return true, nil, gallerydlOutput
end

function M.sendTwitterImages(message, info, source)
  if not message.embed then
    if not clock:waitFor("messageUpdate", 5000) then
      M.downloadSendAndDeleteImages(message, info, source)
    end
  end
end

return M
