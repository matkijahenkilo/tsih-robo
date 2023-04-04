local MUSIC_FOLDER = "assets/sounds/yt-dlp/";

local discordia = require("discordia");
local spawn = require('coro-spawn');
local fs = require("fs");
local cache = {};
discordia.extensions();



local function connectAndCacheNewConnection(interaction)
  cache[interaction.guild.id] = {
    connection   = interaction.member.voiceChannel:join();
    playlist     = discordia.Deque();
    whoRequested = {};
    nowPlaying   = '';
    isPlaying    = false;
  }
  return cache[interaction.guild.id];
end

local function isMemberOnVoiceChannel(voiceChannel, interaction)
  return voiceChannel.connection.channel.id == interaction.member.voiceChannel.id;
end

local function deleteExistingFiles(interaction, id)
  interaction:reply("**Song was opted to be re-downloaded**.\n"
    .."Deleting existing files and re-downloading possible corrupted song nanora! Please wait~");
  fs.unlinkSync(MUSIC_FOLDER .. id .. ".mp3");
  fs.unlinkSync(MUSIC_FOLDER .. id .. ".webm");
end

local function findAndDeleteExistingFile(interaction, url)
  local child = spawn("yt-dlp", {args = {"--print", "id", url}});
  if child then
    child.waitExit();
    local info = child.stdout.read();
    if info then
      deleteExistingFiles(interaction, info:gsub("%c", ''));
    end
  end
end

local function downloadSong(currentSongInfo, interaction)
  local url = currentSongInfo["url"];

  if currentSongInfo["shouldRedownload"] and url then
    findAndDeleteExistingFile(interaction, url);
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

local function showCurrentMusic(interaction, song, user, count)
  interaction.channel:send {
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
    }
  };
end

local function notifySongAdded(interaction, playlistSize)
  local playlistAddResponse = "Song added into the playlist";
  if playlistSize > 5 then
    playlistAddResponse = playlistAddResponse .. "~\nThere's now " .. playlistSize .. " tracks to play nora!"
  else
    playlistAddResponse = playlistAddResponse .. " nora!";
  end

  interaction.channel:send(playlistAddResponse);
end

local function getQueuedSongInfo(currentSongInfo, interaction)
  if not currentSongInfo then return end
  local song = downloadSong(currentSongInfo, interaction);
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

local function startStreaming(interaction, voiceChannel)
  coroutine.wrap(function ()
    while true do

      local room = voiceChannel.connection;

      voiceChannel.isPlaying = true;

      local song, whoRequested;
      local currentSongInfo = voiceChannel.playlist:popLeft();
      if currentSongInfo then
        local notification = interaction.channel:send("Fetching song, please wait nanora!");
        song, whoRequested = getQueuedSongInfo(currentSongInfo, interaction);
        coroutine.wrap(function() notification:delete() end)()
      end

      if song then

        showCurrentMusic(interaction, song, whoRequested, voiceChannel.playlist:getCount());
        setInformationToCache(voiceChannel, song, whoRequested);
        room:playFFmpeg(MUSIC_FOLDER .. song.id .. ".mp3");

      else

        if voiceChannel.playlist:peekLeft() then
          interaction.channel:send("I couldn't fetch the song! Attempting to fetch the next song from the list~");
        else
          interaction.channel:send("Queue is empty nora! Stopping~");
          room:close();
          cache[interaction.guild.id] = nil;
          return;
        end

      end
    end
  end)();
end

local function play(interaction, args, shouldRedownload)
  local voiceChannel = cache[interaction.guild.id];
  if voiceChannel == nil then
    voiceChannel = connectAndCacheNewConnection(interaction);
  end

  interaction:reply("Okie dokie~! Adding more songs into the playlist nora!")
  addSongsIntoDeque(voiceChannel.playlist, interaction.member.user, args, shouldRedownload);

  notifySongAdded(interaction, voiceChannel.playlist:getCount());

  if not voiceChannel.isPlaying then
    startStreaming(interaction, voiceChannel)
  end

end

local function showWhatIsPlayingCurrently(interaction)
  local voiceChannel = cache[interaction.guild.id];
  if voiceChannel == nil then return end
  local nowPlaying = voiceChannel.nowPlaying;
  local user = voiceChannel.whoRequested;

  if user or user[1] or nowPlaying then
    interaction:reply {
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
  else
    interaction:reply("For some reason, I can't say what is playing now nora...");
  end
end

local function pause(interaction)
  local voiceChannel = cache[interaction.guild.id];
  if not voiceChannel then return end
  interaction:reply("Pausing... nanora!");
  voiceChannel.connection:pauseStream();
end

local function resume(interaction)
  local voiceChannel = cache[interaction.guild.id];
  if not voiceChannel then return end
  interaction:reply("Resuming... nanora!");
  voiceChannel.connection:resumeStream();
end

local function skip(interaction)
  local voiceChannel = cache[interaction.guild.id];
  if not voiceChannel then return end
  interaction:reply("Skipping... nanora!");
  voiceChannel.connection:stopStream();
end

local function stop(interaction)
  local voiceChannel = cache[interaction.guild.id];
  if not voiceChannel then return end
  interaction:reply("Stopping... nanora!");
  while voiceChannel.playlist:peekLeft() do
    voiceChannel.playlist:popLeft();
  end
  voiceChannel.connection:close();
  cache[interaction.guild.id] = nil;
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

local function shuffle(interaction)
  local voiceChannel = cache[interaction.guild.id];

  local t = {};
  t = populateTableWithDequePlaylist(t, voiceChannel);
  t = shuffleTable(t);
  populateDequeWithShuffledPlaylist(t, voiceChannel);

  interaction:reply("Playlist has now " .. voiceChannel.playlist:getCount() .. " shuffled tracks nanora!");
end

local functions = {
  play       = play,
  skip       = skip,
  nowplaying = showWhatIsPlayingCurrently,
  stop       = stop,
  pause      = pause,
  resume     = resume,
  shuffle    = shuffle
}

return {
  getSlashCommand = function(tools)
    return tools.slashCommand("song", "I'll play any song for you nanora!")
        :addOption(
          tools.subCommand("play", "I'll play or add any song for you nanora!")
          :addOption(
            tools.string("urls", "One or more URL that works with yt-dlp nora!")
            :setRequired(true)
          )
          :addOption(
            tools.boolean("redownload", "Re-downloads the song if you feel the need nora!")
          )
        )
        :addOption(
          tools.subCommand("skip", "I'll skip the current song nanora!")
        )
        :addOption(
          tools.subCommand("stop", "I'll stop and clear the current playlist nanora!")
        )
        :addOption(
          tools.subCommand("shuffle", "Shuffles the current playlist nanora!")
        )
        :addOption(
          tools.subCommand("pause", "I'll just pause the song nanora.")
        )
        :addOption(
          tools.subCommand("resume", "I'll just resume the song nanora.")
        )
        :addOption(
          tools.subCommand("nowplaying", "Shows you the current song playing nora!")
        )
  end,
  executeSlashCommand = function(interaction, command, args)
    if not interaction.guild then
      interaction:reply("You're not even in a server nora!", true);
      return;
    end

    if not interaction.member.voiceChannel then
      interaction:reply("You're not even in a voice chat nora!", true);
      return;
    end

    local voiceChannel = cache[interaction.guild.id];
    if voiceChannel then
      if not isMemberOnVoiceChannel(voiceChannel, interaction) then
        interaction:reply("Get into the voice channel with the boys first nanora!");
        return;
      end
    end

    local url, redownload;
    local commandName = command.options[1].name;
    if commandName == "play" then
      url         = args.play.urls:split(' ');
      redownload  = args.play.redownload;
    end

    functions[commandName](interaction, url, redownload or false);
  end
};

