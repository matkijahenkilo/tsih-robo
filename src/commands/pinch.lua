local omori = require("src/misc/omori");

return {
  description = {
    title = "pinch",
    description = "You make a kiddo sad!",
    color = 0xff5080
  },
  execute = function(message)
    omori.omoriReaction(message, 3, 0, "Ooow my cheek nanora!");
  end
}
