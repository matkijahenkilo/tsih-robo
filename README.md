# tsih-robo

It's just a fun project I always wanted to create and also my first programming project ever! Tsih-Robo at first was made for fun/entertainment porpuses, but after a long time studying and managing to program my primary objective into her, I decided to leave the cosmetics functions in her code~

Tsih's **primary function** is to fill the gap of badly embeded links on discord for websites links like Pixiv, Pawoo, Baraag, Exhentai and etc. Pretty much what [SaucyBot](https://github.com/Sn0wCrack/saucybot-discord) does, but with more websites and a flexible list for adding more websites as you see fit, but only websites that are compatible with [gallery-dl](https://github.com/mikf/gallery-dl).

I wanted to make her act canonically as she would act in one of the games she's in, but I'm kinda bad at this. w

## Commands

You can write `ts!help` for more information for running commands. For now, the command below is not listed in the help command.

`ts!setsaucelimit NUMBER` - Sets a limit for downloaded images to be sent on a specific channel. Default: 5.

## Installation

**Be aware that simply installing tsih-robo may cause crashes during runtime because of the absence of the /assets/ folder.**

### pre-requisites packages

`base-devel ffmpeg yt-dlp gallery-dl`

### bot installation:

open you terminal, turn off your brain and copy and paste the following commands:

clone this repository
```
git clone https://github.com/Defalts2/tsih-robo
```

```
cd tsih-robo/
```

download lit, luvi and luvit
```
curl -L https://github.com/luvit/lit/raw/master/get-lit.sh | sh
```

install [Discordia](https://github.com/SinisterRectus/discordia) API
```
./lit install SinisterRectus/discordia
```

wget and move coro-spawn
```
wget https://raw.githubusercontent.com/luvit/lit/master/deps/coro-spawn.lua
```

```
mv coro-spawn.lua deps/
```

wget and replace http-codec.lua, the one that exists in deps/ is outdated.
```
wget https://raw.githubusercontent.com/luvit/lit/master/deps/http-codec.lua
```

```
mv http-codec.lua deps/
```

and finally start the bot with your token as an argument! (be sure to turn your brain on at this step)
```
./luvit src/core/main.lua [token]
```

*oooor simply copy this entire block and paste it into a terminal, if you want to speedrun it:*

```
git clone https://github.com/Defalts2/tsih-robo
cd tsih-robo/
curl -L https://github.com/luvit/lit/raw/master/get-lit.sh | sh
./lit install SinisterRectus/discordia
wget https://raw.githubusercontent.com/luvit/lit/master/deps/coro-spawn.lua
wget https://raw.githubusercontent.com/luvit/lit/master/deps/http-codec.lua
mv coro-spawn.lua deps/
mv http-codec.lua deps/
./luvit src/core/main.lua
```

### gallery-dl configuration

Please check [here](https://github.com/mikf/gallery-dl#configuration) to understand how to configurate your gallery-dl.

Export your browser's cookies using an addon and drag it inside this repository's folder.

When using `gallery-dl.conf`, be sure to drag it inside tsih-robo folder in case you're on Windows. If you're on Linux just put it to /etc/