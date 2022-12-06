return {
  description = {
    title = "Echo",
    description = "I'll say whatever you say!\ne.g: ts!echo aloha",
    color = 0xff5080,
    fields = {
      {
        name = "[string]",
        value = "Vou repetir o que você disse exatamente, concatenado com 'nanora' no final do seu vetor de caracteres, estou com preguiça de escrever em inglês nanola ;v;"
      },
    },
  },
  execute = function(message, args)
    if args[2] == nil then
      message.channel:send("Say something and I'll say it back nanora!");
      return;
    end
    message.channel:send(table.concat(args, " ", 2) .. " nanora!");
  end
};
