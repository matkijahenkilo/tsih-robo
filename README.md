# tsih-robo

Tsih-robo is a discord bot chosen to be written in Lua because the language shares the same color as her hair! Tsih-robo was made using [Discordia](https://github.com/SinisterRectus/discordia) API.

Tsih-robo's primary function is to fill the gap of badly embeded links on discord for websites links like Pixiv, Pawoo, Baraag, Exhentai and etc using [gallery-dl](https://github.com/mikf/gallery-dl). Pretty much what [SaucyBot](https://github.com/Sn0wCrack/saucybot-discord) does, but with more websites that you can insert into a json as you see fit, but only websites that are compatible with [gallery-dl](https://github.com/mikf/gallery-dl).

It's just a fun project I always wanted to create but ended up wanting to maintain, and also my first programming project ever!

(o′┏▽┓｀o)

## Commands

Tsih-robo supports slash and message commands. If you're cloning this repo to run the bot yourself you need to load the bot with `luvit main.lua true` to load the commands.

All of her commands are located in `src/commands`, where each folder has a `init.lua` file that returns a table of functions.

- `/sauce`
    - `channel limit:integer` personalizes how much images Tsih can send in a channel. It can go from 0* up to 100.
    - `global limit:integer` personalizes how much images Tsih can send in the entire server.** It can go from 0* up to 10.

as for links, she will always send up to 5 because Discord and only embed 5 links per message.

*if set to 0, it means that she will not send anything.

**the `channel` option has priority over `global`, meaning that if `global` is set to 10 and `channel` is set to 20, Tsih will send 20 images to the specific channel where the command was used.

### Misc

- `/avatar [user:User]` returns your or another user's avatar link.
- `/question` returns a random string as an answer to a question.
- `/hug` makes Tsih annoyed.
- `/pinch` makes Tsih sad.
- `/randomemoji allow:boolean` adds or removes the server's id to `src/data/emojiServers.json` file, where Tsih will randomly use it to get the server's custom emoticons and use it as a random react.
- `/role`
    - `give name:string hexcolor:string` gives the user a personalized cargo with the name and color of their choise.
    - `remove` removes the personalized cargo that Tsih created from the user.
- `/tsihoclock`
    - `sign` will make Tsih post daily a random image inside one of the two folders inside `assets/images/tsihoclock/` at 9PM UTC. Be sure to personalize it with your own set of images!
    - `unsign` removes the channel from the daily image posting. Sad...
    - `manual` sends an ephemeral message of one of the images. Nice!
    - `auto` will run the same function that would run at 9PM UTC. Only the bot's owner can run it, it's a dangerous command that can annoy people!
- `/song` just an ordinary function to make the bot play songs. It's broken to a certain degree! The options are:
    - `play urls:string [, redownload:boolean]` you can add multiple links here, Tsih will download the sound files, insert into a playlist and play it on voice chat. If she didn't download it correctly, you can set True as a second argument to redownload the file.
    - `nowplaying` shows what is playing currently.
    - `shuffle` shuffles the current playlist.
    - `skip`
    - `stop`
    - `pause`
    - `resume`

None of the commands above are ephemeral.

## Installation

Be aware that simply installing tsih-robo may cause crashes during runtime because of the absence of the /assets folder. Because of that I recommend you to change or delete `pinch`, `hug`, `omori.lua`, `tsihoclock` commands and their code in `main.lua` if you don't want to have a headache with it!

### pre-requisites programs

`ffmpeg` required by the two programs below.

`gallery-dl` required for `sauce` command.

`yt-dlp` required for `song` command. I do not recommend youtube-dl.

### bot installation:

1. Follow [Discordia](https://github.com/SinisterRectus/discordia)'s installation guide.

2. `lit install creationix/coro-spawn` to install a module that spawns gallery-dl and yt-dlp child-processes during runtime.

3. Git clone [discordia-interactions](https://github.com/Bilal2453/discordia-interactions) and [discordia-slash](https://github.com/GitSparTV/discordia-slash) inside `deps` folder:

```
git clone https://github.com/Bilal2453/discordia-interactions deps/discordia-interactions
git clone https://github.com/GitSparTV/discordia-slash deps/discordia-slash
```

4. Create a file named `token.txt` inside `src/data` containing your discord application's token.

If you're running the bot for the first time, then run `./luvit main.lua true` to load it's slash commands. After that you won't need to use the `true` argument again unless you add/change her slash commands!

### gallery-dl configuration

Depending of which website Tsih-Robo is going to get the images to send, you will need to configurate your gallery-dl to work in those websites, e.g. login credentials.

For that, you will usually need to create an account for websites like Pixiv in order to get permissions for the bot see it's contents.
Some websites like Pixiv will need you to run [oauth](https://github.com/mikf/gallery-dl#oauth) command in gallery-dl in order to download the images from the website and send it to Discord.
It's recommended to export your browser's cookies for gallery-dl.

Please check [here](https://github.com/mikf/gallery-dl#configuration) to understand how to configurate your gallery-dl.

When using `gallery-dl.conf`, be sure to drag it inside tsih-robo folder in case you're on Windows. If you're on Linux just put it to /etc/

## known issues

`song` command can magically work or not work. This issue might be related by the voice channel's creation date, if it's a very old channel then it probably won't work. Weird, right!?

## Huge thanks

This project wouldn't be possible without:

- People that developed gallery-dl, luvit, Discordia API and it's extensions
- Bilal2453, Ta-noshii, Nameless and other brilliant minds for helping me deal with my stupidity
- Asuran95 and rafaelrc7 for telling me the bot was based and that I should rewrite most of the scripts
- Ikuse for making incentivising Tsih art to keep the darkness away
- People that use tsih-robo (and criticised her)
- SaucyBot for being a worthy opponent
- Other people that I forgot to mention
