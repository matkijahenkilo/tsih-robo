local answer = {
	"Of course!",
	"That's a strong yes nanora!",
	"Indeed!",
	"Ooooh!! Yes nora!!!",
	"Hmmmm... I guess nanora?",
	"I don't think so nora.",
	"Well, yes, but no nanora.",
	"I think that perhaps it's a maybe nanora!",
	"I think that...",
	"Ask Nanako, won't you nora?!",
	"Teheheh~ no.",
	"I think it's better not to answer nora.",
	"No that's cringe nanora!",
	"You just invented these words nanora.",
	"Whooooa! n-no nora!",
}

return {
	description = {
    title = "question",
    description = "Will reply you with a random answer! (with " .. #answer .. " possibilites of replies nanora!)\n"
			.. "e.g: ts!question isn't Ikusene a cutie?\n\n:smiling_face_with_3_hearts:~~",
    color = 0xff5080,
    fields = {
      {
        name = "[string]",
        value = "A random question nanora."
      }
    }
  },
	execute = function (message, args)
		if args[2] == nil then
			message.channel:send("Ask me anything and I'll answer with yes or no!");
			message:addReaction("😭");
			return;
		end
		message:reply("> " ..  	table.concat(args, " ", 2) .. "\n" .. answer[math.random(1, #answer)]);
		message:addReaction("🤔");
	end
};
