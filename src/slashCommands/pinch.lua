local omori = require("src/misc/omori");

return {
  description = {
    title = "pinch",
    description = "You make a kiddo sad!",
    color = 0xff5080
  },
  getSlashCommand = function (tools)
    return tools.slashCommand("pinch", "You make a kiddo sad!")
  end,
  executeSlashCommand = function(interaction)
    interaction:reply {
      content = "Ooow my cheek nanora!",
      file = omori.getOmoriReactionGif(3, 0);
    }
  end
}
