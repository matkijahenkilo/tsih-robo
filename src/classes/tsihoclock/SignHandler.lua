local IDS_PATH = "src/data/tsihclockids.json";

local json = require("json");
local fs = require("fs");

local M = {}

function M.sign(interaction)
  if interaction.guild then
    local ids = fs.readFileSync(IDS_PATH);
    local id = interaction.channel.id;
    local guildName = interaction.guild.name;
    local t = {};
    if ids then
      t = json.decode(ids);
    end

    if t[1] then
      for _, value in ipairs(t) do
        if value.id == id then
          interaction:reply("Room is already signed for Tsih O'Clock!");
          return;
        end
      end
    end

    table.insert(t, { id = id, guildName = guildName });
    fs.writeFileSync(IDS_PATH, json.encode(t));

    interaction:reply("This room is now signed for Tsih O'Clock nanora!");
  else
    interaction:reply("This function only works withing servers nanora!", true);
  end
end

function M.remove(interaction)
  if interaction.guild then
    local ids = fs.readFileSync(IDS_PATH)
    local id = interaction.channel.id;
    if ids then
      local t = json.decode(ids);
      for key, value in pairs(t) do
        if value.id == id then
          table.remove(t, key);
          fs.writeFileSync(IDS_PATH, json.encode(t));
          interaction:reply("Done! How can you meanies see my cuteness daily now nanora!?");
          return;
        end
      end
    end
    interaction:reply("B-but this room isn't even signed up nora!");
  else
    interaction:reply("This function only works withing servers nanora!", true);
  end
end

return M;