local omori = require("src/misc/omori");

return {
  description = {
    title = "Hello",
    description = "I simply say hewwo back to you!\ne.g: ts!hello",
    color = 0xff5080
  },
  execute = function (message)
    omori.omoriReaction(message, 1, 2, "Hewwo nanora!");
    message:addReaction("👋");
  end
};
