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

local function deleteExistingFiles(msg, id)
  msg:setContent("**Song was opted to be re-downloaded**. Deleting existing files and re-downloading possible corrupted song nanora! Please wait~");
  fs.unlinkSync(MUSIC_FOLDER .. id .. ".mp3");
  fs.unlinkSync(MUSIC_FOLDER .. id .. ".webm");
end

local function findAndDeleteExistingFile(msg, url)
  local child = spawn("yt-dlp", {args = {"--print", "id", url}});
  if child then
    child.waitExit();
    local id = child.stdout.read():gsub("%c", '');
    deleteExistingFiles(msg, id);
  end
end

local function downloadSong(currentSongInfo, msg)
  local url = currentSongInfo["url"];

  if currentSongInfo["shouldRedownload"] and url then
    findAndDeleteExistingFile(msg, url);
  end

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

  local t = {};

  if child then
    child.waitExit();
    local info = child.stdout.read();
    if not info then return end
    t = info:split('\n');
  end

  return {
    title = t[1],
    id    = t[2],
  };
end

local function setInformationToCache(voiceChannel, song, whoRequested)
  voiceChannel.nowPlaying = song.title;
  voiceChannel.whoRequested = whoRequested;
end

local function getListOfVideosFromPlaylist(url)
  local child = spawn("yt-dlp", { args = { "--flat-playlist", "-g", url } });
  if child then
    child.waitExit();
    return child.stdout.read():split('\n');
  end
end

local function addIndividualUrlsFromPlaylistIntoDeque(url, playlist, user, shouldRedownload)
  local list = getListOfVideosFromPlaylist(url);
  for _, link in ipairs(list) do
    if link ~= '' then
      playlist:pushRight({["url"]=link, ["whoRequested"]=user, ["shouldRedownload"]=shouldRedownload});
    end
  end
end

local function isPlaylist(url)
  local playlistIndicators = {
    "?list=",
    "&list=",
    "/sets/",
    "/album/",
  }
  for _, value in ipairs(playlistIndicators) do
    if url:find(value) then return true end
  end
  return false;
end

local function showCurrentMusic(msg, song, user, count)
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
  msg:setContent("");
end

local function notifySongAdded(message, playlistSize)
  local playlistAddResponse = "Song added into the playlist";
  if playlistSize > 5 then
    playlistAddResponse = playlistAddResponse .. "~\nThere's now " .. playlistSize .. " tracks to play nora!"
  else
    playlistAddResponse = playlistAddResponse .. " nora!";
  end

  message.channel:send {
    content = playlistAddResponse,
    reference = {
      message = message,
      mention = false,
    };
  };
end

local function getQueuedSongInfo(currentSongInfo, msg)
  if not currentSongInfo then return end
  local song = downloadSong(currentSongInfo, msg);
  local whoRequested = currentSongInfo["whoRequested"];
  return song, whoRequested;
end

local function addSongIntoUrlsForDownloadDeque(url, playlist, user, shouldRedownload)

  if isPlaylist(url) then
    addIndividualUrlsFromPlaylistIntoDeque(url, playlist, user, shouldRedownload);
  else
    playlist:pushRight({["url"]=url, ["whoRequested"]=user, ["shouldRedownload"]=shouldRedownload});
  end

end

local function addSongsIntoDeque(playlist, user, args, shouldRedownload)
  for _, link in ipairs(args) do
    if link and link ~= '' then
      addSongIntoUrlsForDownloadDeque(link, playlist, user, shouldRedownload);
    end
  end
end

local function startStreaming(message, voiceChannel)
  coroutine.wrap(function ()
    while true do

      local room = voiceChannel.connection;

      voiceChannel.isPlaying = true;
      local msg = message:reply("Fetching song, please wait nanora!");

      local currentSongInfo = voiceChannel.playlist:popLeft();
      local song, whoRequested = getQueuedSongInfo(currentSongInfo, msg);
      if song then

        showCurrentMusic(msg, song, whoRequested, voiceChannel.playlist:getCount());
        setInformationToCache(voiceChannel, song, whoRequested);
        room:playFFmpeg(MUSIC_FOLDER .. song.id .. ".mp3");

      else

        if voiceChannel.playlist:peekLeft() then
          msg:setContent("I couldn't fetch the song! Attempting to fetch the next song from the list~");
        else
          msg:setContent("Queue is empty nora! Stopping~");
          room:close();
          cache[message.guild.id] = nil;
          return;
        end

      end

    end
  end)();
end

local function play(message, args, shouldRedownload)

  local voiceChannel = cache[message.guild.id];
  if voiceChannel == nil then
    voiceChannel = connectAndCacheNewConnection(message);
  end

  addSongsIntoDeque(voiceChannel.playlist, message.member.user, args, shouldRedownload);

  notifySongAdded(message, voiceChannel.playlist:getCount());

  if not voiceChannel.isPlaying then
    startStreaming(message, voiceChannel)
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
      title = "Now playing: **" .. nowPlaying .. "** ...nanora!",
      description = voiceChannel.playlist:getCount() .. " tracks remaining nanora.",
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

local function populateTableWithDequePlaylist(t, voiceChannel)
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

local function populateDequeWithShuffledPlaylist(t, voiceChannel)
  for i = 1, #t do
    voiceChannel.playlist:pushRight(t[i]);
  end
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

  local t = {};
  t = populateTableWithDequePlaylist(t, voiceChannel);
  t = shuffleTable(t);
  populateDequeWithShuffledPlaylist(t, voiceChannel);

  msg:setContent("Playlist has now " .. voiceChannel.playlist:getCount() .. " shuffled tracks nanora!");
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
        value = "Will shuffle my current playlist nora."
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
      play(message, args, false);
    elseif command == "redownload" or command == "forceplay" then
      play(message, args, true);
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
