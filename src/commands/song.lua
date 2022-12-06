local discordia = require("discordia");
local spawn = require('coro-spawn');
local cache = {};
discordia.extensions();

local function downloadStreamingLink(url)
  return spawn("yt-dlp", {
    args = {
      "--print", "title",
      "-f", "ba", "--print", "url",
      url,
    }
  });
end

local function isMemberOnVoiceChannel(message, voiceChannel)
  return voiceChannel.connection.channel.id == message.member.voiceChannel.id;
end

local function connectAndCacheNewConnection(message)
  cache[message.guild.id] = {
    connection = message.member.voiceChannel:join();
    deque      = discordia.Deque();
    whoQueued  = {};
    nowPlaying = '';
    isPlaying  = false;
  };
  return cache[message.guild.id];
end

local function exhaustChild(child)
  local t = {};
  while true do
    local info = child.stdout.read();
    if not info then
      return table.concat(t);
    end
    table.insert(t, info);
  end
end

local function getMusicInfoTable(url)
  local child = downloadStreamingLink(url);
  local t = exhaustChild(child);
  t = t:split('\n');
  table.remove(t, #t);
  return t;
end

local function organizeMusicInfoTable(t)
  local output = {};
  for key, value in ipairs(t) do
    if value:find("https://") then
      table.insert(output, {
        title = t[key - 1],
        stream = t[key]
      });
    end
  end
  return output;
end

local function getMusic(url)
  local t = getMusicInfoTable(url);
  return organizeMusicInfoTable(t);
end

local function addPlaylistIntoDeque(deque, streamTable, user)
  for _, value in pairs(streamTable) do
    value["whoRequested"] = user;
    deque:pushRight(value);
  end
end

local function queueNewSongs(message, args)
  if not args[3] then
    message:reply("A song, please!");
    return;
  end

  local msg = message:reply {
    content = "Fetching audio stream... nora.",
    reference = {
      message = message,
      mention = false
    }
  };

  local newArgs = table.concat(args, ' ', 3);
  local t = newArgs:gsub('%c', ' '):split(' ');

  local deque = cache[message.guild.id].deque;

  local failedFetches = 0;
  local streamTable = {};
  for _, value in ipairs(t) do
    streamTable = getMusic(value);
    if streamTable or streamTable[1] then
      addPlaylistIntoDeque(deque, streamTable, message.member.user);
    else
      failedFetches = failedFetches + 1;
    end
  end

  msg:setContent("Song added to the playlist nanora!");
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

local function sendPlaylistInfo(message, list)
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

local function showCurrentMusic(channel, music, count)
  channel:send {
    embed = {
      title = "Enjoy this banger nora!",
      color = 0x6f5ffc,
      fields = {
        {
          name = music["title"],
          value = "There's " .. count .. " tracks left to play... nanora!"
        },
      },
      footer = {
        text = "Requested by " .. music["whoRequested"].name .. " nora.",
        icon_url = music["whoRequested"].avatarURL;
      }
    },
  };
end

local function startStreamRuntime(message)
  local voiceChannel = cache[message.guild.id];
  local room = voiceChannel.connection;
  local deque = voiceChannel.deque;

  coroutine.wrap(function ()

    voiceChannel.isPlaying = true;

    while deque:peekRight() do

      local music = deque:popLeft();

      voiceChannel.nowPlaying = music["title"];
      voiceChannel.whoQueued = music["whoRequested"];
      showCurrentMusic(message.channel, music, deque:getCount());
      room:playFFmpeg(music["stream"]);

    end

    room:close();
    cache[message.guild.id] = nil;

  end)();
end



local songCommands = {
  play    = function (message, args)
    local voiceChannel = cache[message.guild.id];
    if voiceChannel == nil then
      voiceChannel = connectAndCacheNewConnection(message);
    end

    queueNewSongs(message, args);

    if voiceChannel.isPlaying then return end
    startStreamRuntime(message);
  end,

  queue   = function (message)
    local voiceChannel = cache[message.guild.id];
    if not voiceChannel then return end
    local deque = voiceChannel.deque;
    if deque:getCount() == 0 then
      message:reply("Queueueueue is empty nanora!");
      return;
    end
    local list = getNextSongs(deque);
    print(list);
    sendPlaylistInfo(message, list);
  end,

  np      = function (message)
    local voiceChannel = cache[message.guild.id];
    if voiceChannel == nil then return end
    local nowPlaying = voiceChannel.nowPlaying;
    local user = voiceChannel.whoQueued;
    if not user[1] or not nowPlaying then return end
    message.channel:send {
      embed = {
        title = "Now playing: " .. nowPlaying .. " ...nanora!",
        footer = {
          text = "Requested by " .. user.name .. " nora.",
          icon_url = user.avatarURL;
        }
      }
    }
  end,

  pause   = function (message)
    local voiceChannel = cache[message.guild.id];
    if voiceChannel == nil then return end
    message.channel:send("Pausing... nanora!");
    voiceChannel.connection:pauseStream();
  end,

  resume  = function (message)
    local voiceChannel = cache[message.guild.id];
    if voiceChannel == nil then return end
    message.channel:send("Resuming... nanora!");
    voiceChannel.connection:resumeStream();
    voiceChannel.isPlaying = true;
  end,

  skip    = function (message)
    local voiceChannel = cache[message.guild.id];
    if voiceChannel == nil then return end
    message.channel:send("Skipping... nanora!");
    voiceChannel.connection:stopStream();
    voiceChannel.isPlaying = false;
  end,

  stop    = function (message)
    local voiceChannel = cache[message.guild.id];
    if voiceChannel == nil then return end
    message.channel:send("Stopping... nanora!");
    while voiceChannel.deque:peekLeft() do
      voiceChannel.deque:popLeft();
    end
    voiceChannel.connection:close();
    cache[message.guild.id] = nil;
  end,

  special = function (message)
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
};

local songCommandsMetaTable = {
  __index = function()
    return function(message)
      message.channel:send("You what?!");
    end
  end
};

songCommands = setmetatable(songCommands, songCommandsMetaTable);

return {
  description = {
    title = "Song",
    description = "e.g: ts!song play https://youtu.be/XgX4JFtYRRw https://youtu.be/OUkUGpiWki0 https://soundcloud.com/technorch/dj-mix-biblex3-happy-selection-2007",
    color = 0xff5080,
    fields = {
      {
        name = "play",
        value = "Will queue a new song or playlist for you, nora."
      },
      {
        name = "queue",
        value = "Will show you the next songs that are going to play nanora!"
      },
      {
        name = "np",
        value = "Show's you what is playing now nanora! (abbreviated from \"now Playing\"~)"
      },
      {
        name = "pause, resume, skip",
        value = "They mean exactly what they mean nanora!"
      },
      {
        name = "stop",
        value = "Will delete all tracks from queue, and I will leave your server crying nola!!"
      },
    },
  },
  execute = function(message, args)
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
      if not isMemberOnVoiceChannel(message, voiceChannel) then
        message:reply("Get into the voice channel with the boys nanora!");
        return;
      end
    end

    songCommands[args[2]:lower()](message, args);
  end
};