local Command = require("utils").Command
local Question = require("discordia").class("Question", Command)

function Question:__init(message, client, args)
  Command.__init(self, message, client, args)
end

local answer = {
  "Of course!",
  "That's a strong yes nanora!",
  "Indeed nora!",
  "Ooooh!! Yes nora!!!",
  "Hmmmm... I guess nanora?",
  "Yes, that's based nanora!",
  "I don't think so nora.",
  "Well, yes, but no nanora.",
  "I think that perhaps it's a maybe nanora!",
  "I think that...",
  "Ask Nanako, won't you nora?!",
  "Teheheh~ no.",
  "I think it's better not to answer nora.",
  "No, that's cringe nanora!",
  "You just invented these words nanora.",
  "Whooooa! n-no nora!",
}

function Question.getSlashCommand(tools)
  return tools.slashCommand("question", "I answer a question with yes or no nanora!")
    :addOption(
      tools.string("question", "The!!!!!!!! question."):setRequired(true)
    )
end

function Question:executeSlashCommand()
  local interaction, args = self._message, self._args

  local person = interaction.member or interaction.user
    interaction:reply(string.format('%s asked:\n> %s\n%s',
      person.name,
      args.question,
      answer[math.random(#answer)]
    ))
end

return Question