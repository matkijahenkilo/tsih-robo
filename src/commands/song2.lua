-- planning to replace song.lua. WIP.

local discordia = require("discordia");
local fs = require("fs");
local spawn = require('coro-spawn');
local cache = {};
discordia.extensions();

local function downloadSong(url)
  local child = spawn("yt-dlp", {
    args = {
      "-P", "./yt-dlp/",
      "-x", "--audio-format", "mp3",
      "-o", "%(id)s.mp3",
      url,
    }
  });
  local i = 0;
  while true do
    local info = child.stdout.read();
    i = i + 1;
    p(i, info);
    if not info then return end
  end
end

local function printSongInfo(url, user)
  local child = spawn("yt-dlp", { args = { "--print", "title", "--print", "id", url } });
  local t = {};
  while true do
    local info = child.stdout.read();
    p(info);
    if info then
      table.insert(t, info);
    else
      break;
    end
  end

  t = table.concat(t):split('\n');

  return {
    title = t[1],
    id    = t[2],
    user  = user
  }
end

local function connectAndCacheNewConnection(message)
  cache[message.guild.id] = {
    connection      = message.member.voiceChannel:join();
    songsToDownload = discordia.Deque();
    songsToPlay     = discordia.Deque();
    whoRequested    = {};
    nowPlaying      = '';
    remainingToPlay = 0;
    isPlaying       = false;
  }
  return cache[message.guild.id]
end

local function addSongIntoSongsToDownloadDeque(deque, args)
  local urls = table.concat(args, ' ', 3):split(' ');
  for _, value in ipairs(urls) do
    deque:pushRight(value);
  end
end

local function addSongIntoSongsToPlayDeque(songsToDownload, songsToPlay, user)
  local song = songsToDownload:popLeft();
  if not song then return end;
  downloadSong(song);
  songsToPlay:pushRight(printSongInfo(song, user));
end

local function getNextSongs(deque)
  local readObject = deque:iter();
  local i = 1;
  local t = {};
  while true do
    local music = readObject();
    if not music then
      return table.concat(t, '\n');
    end
    if not music["title"] then
      table.insert(t, i .. " - **Unfetched song title**");
    else
      table.insert(t, i .. " - " .. music["title"]);
    end
    i = i + 1;
  end
end

local function showCurrentMusic(channel, song, quantity)
  channel:send(song.title)
end



local function play(message, args)
  local voiceChannel = cache[message.guild.id];
  if voiceChannel == nil then
    voiceChannel = connectAndCacheNewConnection(message);
  end

  addSongIntoSongsToDownloadDeque(voiceChannel.songsToDownload, args);

  local room = voiceChannel.connection;
  local songsToDownload = voiceChannel.songsToDownload;
  local songsToPlay     = voiceChannel.songsToPlay;
  addSongIntoSongsToPlayDeque(songsToDownload, songsToPlay, message.member);

  while songsToDownload:peekRight() do

    if voiceChannel.isPlaying then
      addSongIntoSongsToPlayDeque(songsToDownload, songsToPlay);
    else
      coroutine.wrap(function ()
        voiceChannel.isPlaying = true;
        --showCurrentMusic(message.channel, song, songsToDownload:getCount());

        while voiceChannel.remainingToPlay do
          local song = songsToPlay:popLeft();
          if not song then return end
          voiceChannel.nowPlaying = song.title;
          voiceChannel.whoRequested = song.user;
          print("left to play: ", voiceChannel.remainingToPlay);
          room:playFFmpeg("yt-dlp/" .. song.id .. ".mp3")
          voiceChannel.remainingToPlay = voiceChannel.remainingToPlay - 1;
        end
        room:close();
        cache[message.guild.id] = nil;
      end)();
    end

  end
end

local function queue(message)
  local voiceChannel = cache[message.guild.id];
  if not voiceChannel then return end
  local deque = voiceChannel.songsToPlay;
  if deque:getCount() == 0 then
    message:reply("Queueueueue is empty nanora!");
    return;
  end
  local list = getNextSongs(deque);
  print(list);

  if #list > 4000 then
    list = list:sub(1, 4000);
  end
  message.channel:send {
    embed = {
      title = "These are the next songs to play nanora!",
      description = list,
      color = 0x6f5ffc,
    },
  };
end

local function showWhatIsPlayingCurrently(message)
  local voiceChannel = cache[message.guild.id];
  if voiceChannel == nil then return end
  local nowPlaying = voiceChannel.nowPlaying;
  local user = voiceChannel.whoRequested;

  if not user[1] or not nowPlaying then return end
  message.channel:send {
    embed = {
      title = "Now playing: " .. nowPlaying .. " ...nanora!",
      color = 0xff80fd,
      footer = {
        text = "Requested by " .. user.name .. " nora.",
        icon_url = user.avatarURL
      }
    }
  }
end

local function pause(message)
  local voiceChannel = cache[message.guild.id];
  if voiceChannel == nil then return end
  message.channel:send("Pausing... nanora!");
  voiceChannel.connection:pauseStream();
end

local function resume(message)
  local voiceChannel = cache[message.guild.id];
  if voiceChannel == nil then return end
  message.channel:send("Resuming... nanora!");
  voiceChannel.connection:resumeStream();
  voiceChannel.isPlaying = true;
end

local function skip(message)
  local voiceChannel = cache[message.guild.id];
  if voiceChannel == nil then return end
  message.channel:send("Skipping... nanora!");
  voiceChannel.connection:stopStream();
  voiceChannel.isPlaying = false;
end

local function stop(message)
  local voiceChannel = cache[message.guild.id];
  if voiceChannel == nil then return end
  message.channel:send("Stopping... nanora!");
  while voiceChannel.songsToDownload:peekLeft() do
    voiceChannel.songsToDownload:popLeft();
    while voiceChannel.songsToPlay:peekLeft() do
      voiceChannel.songsToPlay:popLeft();
    end
  end
  voiceChannel.connection:close();
  cache[message.guild.id] = nil;
end

local function special(message)
  local voiceChannel = cache[message.guild.id];
  if voiceChannel == nil then
    voiceChannel = connectAndCacheNewConnection(message);
  end
  voiceChannel.isPlaying = true;
  coroutine.wrap(function()
    voiceChannel.connection:playFFmpeg("assets/sounds/moan.mp3");
    cache[message.guild.id] = nil;
  end)();
end

return {
  description = {
    title = "Song",
    description = "e.g: ts!song play link [link2 [link3 [...linkn]]]",
    color = 0xff5080,
    fields = {
      {
        name = "play",
        value = "Will queue a new song or playlist for you, nora."
      },
    },
  },
  execute = function(message, args)
    local function isMemberOnVoiceChannel(voiceChannel)
      return voiceChannel.connection.channel.id == message.member.voiceChannel.id;
    end

    if not message.guild then
      message.channel:send("You're not even in a server nora!");
      return;
    end

    if not message.member.voiceChannel then
      message.channel:send("You're not even in a voice chat nora!");
      return;
    end

    local voiceChannel = cache[message.guild.id];
    if voiceChannel then
      if not isMemberOnVoiceChannel(voiceChannel) then
        message:reply("Get into the voice channel with the boys nanora!");
        return;
      end
    end

    local command = args[2]:lower();
    if command == "play" or command == 'p' then
      play(message, args);
    elseif command == "queue" or command == 'q' then
      queue(message);
    elseif command == "skip" or command == 's' then
      skip(message);
    elseif command == "nowplaying" or command == "np" then
      showWhatIsPlayingCurrently(message);
    elseif command == "stop" then
      stop(message);
    elseif command == "pause" then
      pause(message);
    elseif command == "resume" then
      resume(message);
    end

  end
};