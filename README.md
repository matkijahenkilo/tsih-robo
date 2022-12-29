# tsih-robo

Tsih-Robo is a discord bot chosen to be written in Lua because the language shares the same color as her hair. Tsih-robo was made using [Discordia](https://github.com/SinisterRectus/discordia) API.

It's just a fun project I always wanted to create but ended up wanting to maintain, and also my first programming project ever! 

Inicially she was made for fun/entertainment porpuses, but after a long time studying and managing to program my primary objective into her, I decided to leave the cosmetics functions in her code~

Tsih's **primary function** is to fill the gap of badly embeded links on discord for websites links like Pixiv, Pawoo, Baraag, Exhentai and etc using [gallery-dl](https://github.com/mikf/gallery-dl). Pretty much what [SaucyBot](https://github.com/Sn0wCrack/saucybot-discord) does, but with more websites that you can insert into a table as you see fit, but only websites that are compatible with [gallery-dl](https://github.com/mikf/gallery-dl).

I wanted to make her act canonically as she would act in one of the games she's in, but I'm kinda bad at this. w

## Commands

You can write `ts!help` for more information for running commands.

## Installation

**Be aware that simply installing tsih-robo may cause crashes during runtime because of the absence of the /assets folder.**

### pre-requisites programs

`ffmpeg yt-dlp gallery-dl`

### bot installation:

Follow [Discordia](https://github.com/SinisterRectus/discordia)'s installation guide.

Download and put [coro-spawn.lua](https://raw.githubusercontent.com/luvit/lit/master/deps/coro-spawn.lua) into deps/

I recommend you do the same with [http-codec.lua](https://raw.githubusercontent.com/luvit/lit/master/deps/http-codec.lua), because the one that Discordia has is outdated.

For a fast setup, simply copy and paste this command block into a Linux terminal:

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

Depending of which website Tsih-Robo is going to get the images and send, you will need to configurate your gallery-dl to work in those websites.
For that, you will usually need to create an account for example, Inkbunny in order to get the link for the bot to send.
Some websites like Pixiv will need you to run an [oauth](https://github.com/mikf/gallery-dl#oauth) command in gallery-dl in order to download the images from the website and send it to Discord.
It's recommended to export your browser's cookies for gallery-dl.

Please check [here](https://github.com/mikf/gallery-dl#configuration) to understand how to configurate your gallery-dl.

When using `gallery-dl.conf`, be sure to drag it inside tsih-robo folder in case you're on Windows. If you're on Linux just put it to /etc/
