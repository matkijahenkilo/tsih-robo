local omori = require('src/misc/omori');

local answer = {
  "The heck you doing to me?!",
  "Stop it you weirdo!",
  "Nyuu... くさいのら!",
  "I will smash you nanora!!",
  "Don't just hug me all of sudden nora!",
}

local answerSomeone = {
  "Huuuuug nanora~!",
  "Here's a hug nanora!",
  "They told me to hug you nora!"
}

local function hugSomeone(message, person)
  if person == nil then return end
  omori.omoriReaction(message, 1, math.random(0, 2),
    answerSomeone[math.random(1, #answerSomeone)] .. "\n\\*Tsih warmly hugs " .. person.name .. "~\\*");
  message:addReaction("💙");
end

local function normalHug(message)
  omori.omoriReaction(message, 2, math.random(0, 2), answer[math.random(1, #answer)]);
  message:addReaction("😡");
end

return {
  description = {
    title = "Hug",
    description = "You hug me or tell me to hug someone else!\ne.g: ts!hug @yourLover",
    color = 0xff5080,
    fields = {
      {
        name = "[mention] (Optional)",
        value = "I'll hug your friend and steal him from you nanora!"
      },
    },
  },
  execute = function(message, args, client)
    if args[2] == nil then
      normalHug(message);
    elseif args[2] == "<@897837181794660403>" then
      omori.omoriReaction(message, 3, 2, "Nhaawn, If I had a clone of myself!");
    elseif args[2]:sub(1, 2) == "<@" then
      hugSomeone(message, client:getUser(args[2]:sub(3, -2)));
    else
      omori.omoriReaction(message, 4, 0, "Nyuuun? who's " .. args[2] .. "?");
    end
  end
};
