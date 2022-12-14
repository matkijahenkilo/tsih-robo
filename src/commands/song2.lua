-- song2.lua works downloading .mp3 files and streaming them directly from the host's computer.

local MUSIC_FOLDER = "assets/sounds/yt-dlp/";

local discordia = require("discordia");
local spawn = require('coro-spawn');
local fs = require("fs");
local cache = {};
discordia.extensions();

local function connectAndCacheNewConnection(message)
  cache[message.guild.id] = {
    connection   = message.member.voiceChannel:join();
    playlist     = discordia.Deque();
    whoRequested = {};
    nowPlaying   = '';
    isPlaying    = false;
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

  child.waitExit();
  local info = child.stdout.read();
  if not info then return end
  local t = info:split('\n');

  return {
    title = t[1],
    id    = t[2],
  };
end

local function getListOfVideosFromPlaylist(url)
  local child = spawn("yt-dlp", { args = { "--flat-playlist", "-g", url } });
  child.waitExit();
  return child.stdout.read():split('\n');
end

local function addSongIntourlsForDownloadDeque(url, playlist, user)
  local function iterateInPlaylist()
    local list = getListOfVideosFromPlaylist(url);
    for _, link in ipairs(list) do
      if link ~= '' then
        playlist:pushRight({["url"]=link, ["whoRequested"]=user});
      end
    end
  end

  if url then
    if url:find("playlist") or url:find("/sets/") then
      iterateInPlaylist();
    else
      playlist:pushRight({["url"]=url, ["whoRequested"]=user});
    end
  end
end

local function showCurrentMusic(msg, song, user, count)
  msg:setContent("Song fetched! Playing nora...");
  msg:setEmbed {
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
  };
end

local function play(message, args)

  local voiceChannel = cache[message.guild.id];
  if voiceChannel == nil then
    voiceChannel = connectAndCacheNewConnection(message);
  end

  local room = voiceChannel.connection;

  for _, link in ipairs(args) do
    addSongIntourlsForDownloadDeque(link, voiceChannel.playlist, message.member.user);
  end

  message.channel:send {
    content = "Song added into the playlist nora!",
    reference = {
      message = message,
      mention = false,
    };
  };

  if not voiceChannel.isPlaying then
    coroutine.wrap(function ()

      while true do

        voiceChannel.isPlaying = true;
        local currentSongInfo = voiceChannel.playlist:popLeft();
        if not currentSongInfo then break end

        local msg = message:reply("Fetching song, please wait nanora!");
        local song = downloadSong(currentSongInfo["url"]);
        local whoRequested = currentSongInfo["whoRequested"];
        if song then
          showCurrentMusic(msg, song, whoRequested, voiceChannel.playlist:getCount());
          voiceChannel.nowPlaying = song.title;
          voiceChannel.whoRequested = whoRequested;
          room:playFFmpeg(MUSIC_FOLDER .. song.id .. ".mp3");
        else
          if voiceChannel.playlist:peekLeft() then
            msg:setContent("I couldn't fetch the song! Attempting to fetch the next song from the list~");
          else
            msg:setContent("Queue is empty nora! Stopping~");
            break;
          end
        end

      end

      room:close();
      cache[message.guild.id] = nil;

    end)();
  end

end

local function deleteExistingFiles(message, args)
  local function getFileName(link)
    local child = spawn("yt-dlp", {
      args = {
        "--paths", MUSIC_FOLDER,
        "--print", "id",
        link,
      }
    });
    child.waitExit();
    return child.stdout.read():split('\n');
  end

  message:reply("Deleting old song from host. Re-downloading nora.");

  for _, link in ipairs(args) do
    local t = getFileName(link);
    table.remove(t, #t);
    for _, id in ipairs(t) do
      fs.unlinkSync(MUSIC_FOLDER .. id .. ".mp3");
      fs.unlinkSync(MUSIC_FOLDER .. id .. ".webm");
    end
  end

  play(message, args);
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
  while voiceChannel.playlist:peekLeft() do
    voiceChannel.playlist:popLeft();
  end
  voiceChannel.connection:close();
  cache[message.guild.id] = nil;
end

local function shuffle(message)
  local msg = message:reply{
    content = "Shuffling playlist nora...",
    reference = {
      message = message,
      mention = false,
    }
  };

  local voiceChannel = cache[message.guild.id];

  local function populateTableWithDequePlaylist(t)
    local dequeCount = voiceChannel.playlist:getCount();
    for i = 1, dequeCount do
      t[i] = voiceChannel.playlist:popLeft();
    end
    return t;
  end

  local function shuffleTable(t)
    for i = #t, 2, -1 do
      local j = math.random(i);
      t[i], t[j] = t[j], t[i];
    end
    return t;
  end

  local function populateDequeWithShuffledPlaylist(t)
    for i = 1, #t do
      voiceChannel.playlist:pushRight(t[i]);
    end
  end

  local t = {};
  t = populateTableWithDequePlaylist(t);
  t = shuffleTable(t);
  populateDequeWithShuffledPlaylist(t);

  msg:setContent("Playlist is now shuffled nanora!");
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
        name = "forceplay or redownload",
        value = "Will download the audio file again from your link nora."
          .."\nUse it if you notice that some song I try to play fails to play it 100% nanora!"
      },
      {
        name = "shuffle",
        value = "Will shuffle the my playlist nora."
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
    table.remove(args, 1);
    table.remove(args, 1);
    if command == "play" or command == 'p' then
      play(message, args);
    elseif command == "redownload" or command == "forceplay" then
      deleteExistingFiles(message, args);
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
    elseif command == "shuffle" then
      shuffle(message);
    else
      message:addReaction("❓");
    end

  end
};