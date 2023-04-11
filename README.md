# tsih-robo

Tsih-robo is a discord bot chosen to be written in Lua because the language shares the same color as her hair. Tsih-robo was made using [Discordia](https://github.com/SinisterRectus/discordia) API.

Tsih's **primary function** is to fill the gap of badly embeded links on discord for websites links like Pixiv, Pawoo, Baraag, Exhentai and etc using [gallery-dl](https://github.com/mikf/gallery-dl). Pretty much what [SaucyBot](https://github.com/Sn0wCrack/saucybot-discord) does, but with more websites that you can insert into a table as you see fit, but only websites that are compatible with [gallery-dl](https://github.com/mikf/gallery-dl).

It's just a fun project I always wanted to create but ended up wanting to maintain, and also my first programming project ever! 

## Commands

tsih-robo supports slash and message commands. If you're cloning this repo and running the bot yourself you need to load the bot as `./luvit main.lua true` to load the commands.

All of her commands are located in src/commands, where each file returns a table of functions.

## Installation

Be aware that simply installing tsih-robo may cause crashes during runtime because of the absence of the /assets folder. Because of that I recommend you to change or delete pinch.lua, hug.lua, tsihoclock.lua and omori.lua if you don't want to have a headache with it!

### pre-requisites programs

`gallery-dl` required for sauce.lua

`yt-dlp` required for song.lua. I do not recommend youtube-dl.

`ffmpeg` reguired by the two programs above.

### bot installation:

Follow [Discordia](https://github.com/SinisterRectus/discordia)'s installation guide.

Git clone [discordia-interactions](https://github.com/Bilal2453/discordia-interactions) and [discordia-slash](https://github.com/GitSparTV/discordia-slash) inside `deps` folder

Inside `src/data` folder, create a file named `token.txt` containing your discord application's token.

run the bot on the termiinal with `./luvit main.lua [true]` where the true argument makes the bot load its commands into Discord's server, if nothing is passed then it will not load its commands.

### known issues

`song.lua` does not work as intended because of discordia-interactions implementation, although there was few times where it worked out flawlessly. Further investigation is required.

### gallery-dl configuration

Depending of which website Tsih-Robo is going to get the images and send, you will need to configurate your gallery-dl to work in those websites.
For that, you will usually need to create an account for example, Inkbunny in order to get the link for the bot to send.
Some websites like Pixiv will need you to run an [oauth](https://github.com/mikf/gallery-dl#oauth) command in gallery-dl in order to download the images from the website and send it to Discord.
It's recommended to export your browser's cookies for gallery-dl.

Please check [here](https://github.com/mikf/gallery-dl#configuration) to understand how to configurate your gallery-dl.

When using `gallery-dl.conf`, be sure to drag it inside tsih-robo folder in case you're on Windows. If you're on Linux just put it to /etc/
