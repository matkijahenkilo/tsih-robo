# tsih-robo

Tsih-Robo is a discord bot chosen to be written in Lua because the language shares the same color as her hair. Tsih-robo was made using [Discordia](https://github.com/SinisterRectus/discordia) API.

It's just a fun project I always wanted to create but ended up wanting to maintain, and also my first programming project ever! 

Inicially she was made for fun/entertainment porpuses, but after a long time studying and managing to program my primary objective into her, I decided to leave the cosmetics functions in her code~

Tsih's **primary function** is to fill the gap of badly embeded links on discord for websites links like Pixiv, Pawoo, Baraag, Exhentai and etc using [gallery-dl](https://github.com/mikf/gallery-dl). Pretty much what [SaucyBot](https://github.com/Sn0wCrack/saucybot-discord) does, but with more websites that you can insert into a table as you see fit, but only websites that are compatible with [gallery-dl](https://github.com/mikf/gallery-dl).

I wanted to make her act canonically as she would act in one of the games she's in, but I'm kinda bad at this. w

## Commands

tsih-robo supports slash and message commands, to load them pass a third argument "true" when loading main.lua, you would prefer to do this only once.

## Installation

**Be aware that simply installing tsih-robo may cause crashes during runtime because of the absence of the /assets folder.**

### pre-requisites programs

`ffmpeg yt-dlp gallery-dl`

### bot installation:

Follow [Discordia](https://github.com/SinisterRectus/discordia)'s installation guide.

Git clone [discordia-interactions](https://github.com/Bilal2453/discordia-interactions) and [discordia-slash](https://github.com/GitSparTV/discordia-slash) inside `deps` folder

Be aware that I modified discordia-slash's Client.lua file a bit: I've added the following methods into the file:

```lua
function Client:getGlobalApplicationCommands()
	local data, err = self._api:getGlobalApplicationCommands(self:getApplicationInformation().id)

	if data then
		return Cache(data, ApplicationCommand, self)
	else
		return nil, err
	end
end

function Client:createGlobalApplicationCommand(id, payload)
	local data, err = self._api:createGlobalApplicationCommand(self:getApplicationInformation().id, id)

	if data then
		return ApplicationCommand(data, self)
	else
		return nil, err
	end
end

function Client:deleteGlobalApplicationCommand(id)
	local data, err = self._api:deleteGlobalApplicationCommand(self:getApplicationInformation().id, id)

	if data then
		return data
	else
		return nil, err
	end
end
```

Without them, certain Client methods won't work in main.lua

### gallery-dl configuration

Depending of which website Tsih-Robo is going to get the images and send, you will need to configurate your gallery-dl to work in those websites.
For that, you will usually need to create an account for example, Inkbunny in order to get the link for the bot to send.
Some websites like Pixiv will need you to run an [oauth](https://github.com/mikf/gallery-dl#oauth) command in gallery-dl in order to download the images from the website and send it to Discord.
It's recommended to export your browser's cookies for gallery-dl.

Please check [here](https://github.com/mikf/gallery-dl#configuration) to understand how to configurate your gallery-dl.

When using `gallery-dl.conf`, be sure to drag it inside tsih-robo folder in case you're on Windows. If you're on Linux just put it to /etc/
