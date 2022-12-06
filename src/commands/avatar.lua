local function sendMessage(message, user)
  if user == nil then
    message.channel:send {
      embed = {
        title = "Your avatar nanora!",
        fields = {
          { name = "What a lazy adult!", value = "They look like holding a lot of shiny stars..." },
        },
        image = { url = message.author:getAvatarURL(1024) },
        color = 0xff80fd,
      },
    };
  else
    message.channel:send {
      embed = {
        title = user.name .. "'s avatar nanora!",
        fields = {
          { name = "How beautiful nanora...", value = "ｶﾜ(・∀・)ｲｲ!!" },
        },
        image = { url = user:getAvatarURL(1024) },
        color = 0xff80fd,
      },
    };
  end
end

return {
  description = {
    title = "Avatar",
    description = "Sends your or another user's avatar's URL!\ne.g: ts!avatar @ᵉˢᵘᵏᶦ",
    fields = {
      {
        name = "[mention] (optional)",
        value = "If a user is mentioned, I'll send their avatar nanora!"
      },
    },
    color = 0xff5080
  },
  execute = function(message, args, client)
    if args[2] == nil then
      sendMessage(message);
    else
      sendMessage(message, client:getUser(args[2]:sub(3, -2)));
    end
    message:addReaction("😋");
  end
};