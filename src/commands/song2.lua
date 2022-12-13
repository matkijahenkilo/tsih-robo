-- song2.lua works downloading .mp3 files and streaming them directly from the host's computer.

local MUSIC_FOLDER = "assets/sounds/yt-dlp/";

local discordia = require("discordia");
local spawn = require('coro-spawn');
local cache = {};
discordia.extensions();

local function connectAndCacheNewConnection(message)
  cache[message.guild.id] = {
    connection      = message.member.voiceChannel:join();
    urlsForDownload = discordia.Deque();
    whoRequested    = {};
    nowPlaying      = '';
    isPlaying       = false;
  }
  return cache[message.guild.id];
end

local function downloadSong(url, message)
  local child = spawn("yt-dlp", {
    args = {
      "--no-simulate",
      "--paths", MUSIC_FOLDER,
      "--print", "title",
      "--print", "id",
      "--extract-audio", "--audio-format", "mp3",
      "--output", "%(id)s.mp3",
      url,
    }
  });

  local msg = message:reply("Fetching song, please wait nanora!");
  child.waitExit();
  local info = child.stdout.read();
  if not info then
    return;
  end
  local t = info:split('\n');

  return {
    title    = t[1],
    id       = t[2],
  };
end

local function getListOfVideosFromPlaylist(url)
  local child = spawn("yt-dlp", { args = { "--flat-playlist", "-g", url } });
  child.waitExit();
  return child.stdout.read():split('\n');
end

local function addSongIntourlsForDownloadDeque(url, urlsForDownload, user)
  local function iterateInPlaylist()
    local list = getListOfVideosFromPlaylist(url);
    for _, link in ipairs(list) do
      if link ~= '' then
        urlsForDownload:pushRight({["url"]=link, ["whoRequested"]=user});
      end
    end
  end

  if url then
    if url:find("playlist") or url:find("/sets/") then
      iterateInPlaylist();
    else
      urlsForDownload:pushRight({["url"]=url, ["whoRequested"]=user});
    end
  end
end

local function showCurrentMusic(channel, song, user, count)
  channel:send {
    embed = {
      title = "Enjoy this banger nora!",
      color = 0x6f5ffc,
      fields = {
        {
          name = song.title,
          value = "There's " .. count .. " tracks left to play... nanora!"
        },
      },
      footer = {
        text = "Requested by " .. user.name .. " nora.",
        icon_url = user.avatarURL;
      }
    },
  };
end

local function play(message, args)

  local voiceChannel = cache[message.guild.id];
  if voiceChannel == nil then
    voiceChannel = connectAndCacheNewConnection(message);
  end

  local room = voiceChannel.connection;
  local urlsForDownload = voiceChannel.urlsForDownload;

  for _, link in ipairs(args) do
    addSongIntourlsForDownloadDeque(link, urlsForDownload, message.member.user);
  end

  if not voiceChannel.isPlaying then
    coroutine.wrap(function ()

      while true do
        voiceChannel.isPlaying = true;
        local currentSongInfo = urlsForDownload:popLeft();
        if not currentSongInfo then break end

        local song = downloadSong(currentSongInfo["url"], message);
        local whoRequested = currentSongInfo["whoRequested"];
        if not song then break end

        showCurrentMusic(message.channel, song, whoRequested, urlsForDownload:getCount());
        voiceChannel.nowPlaying = song.title;
        voiceChannel.whoRequested = whoRequested;
        room:playFFmpeg(MUSIC_FOLDER .. song.id .. ".mp3")
      end

      room:close();
      cache[message.guild.id] = nil;

    end)();
  end

end

local function showWhatIsPlayingCurrently(message)
  local voiceChannel = cache[message.guild.id];
  if voiceChannel == nil then return end
  local nowPlaying = voiceChannel.nowPlaying;
  local user = voiceChannel.whoRequested;

  if not user or not user[1] or not nowPlaying then return end
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
end

local function stop(message)
  local voiceChannel = cache[message.guild.id];
  if voiceChannel == nil then return end
  message.channel:send("Stopping... nanora!");
  while voiceChannel.urlsForDownload:peekLeft() do
    voiceChannel.urlsForDownload:popLeft();
  end
  voiceChannel.connection:close();
  cache[message.guild.id] = nil;
end

return {
  description = {
    title = "Song",
    description = "I will play songs for you nanora! e.g:"
      .. "\n`ts!song play url1 url2 ...`"
      .. "\n`ts!song np`",
    color = 0xff5080,
    fields = {
      {
        name = "play or p",
        value = "Will queue a new song or playlist for you, nora."
      },
      {
        name = "nowplaying or np",
        value = "Will show you what song is currently playing nora."
      },
      {
        name = "stop",
        value = "Will............... stop completly, nora."
      },
      {
        name = "pause",
        value = "Will......................... pause, nora."
      },
      {
        name = "resume",
        value = "Ugeeh!"
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
      table.remove(args, 1)
      table.remove(args, 1)
      play(message, args);
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
    else
      message:addReaction("❓");
    end

  end
};