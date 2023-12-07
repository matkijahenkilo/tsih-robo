local pp = require('pretty-print')
local Command = require("utils").Command

local Lua = require("discordia").class("Lua", Command)

function Lua:__init(message, client, args)
  Command.__init(self, message, client, args)
end

local function prettyLine(...)
    local ret = {}
    for i = 1, select('#', ...) do
        local arg = pp.strip(pp.dump(select(i, ...)))
        table.insert(ret, arg)
    end
    return table.concat(ret, '\t')
end

local function printLine(...)
  local ret = {}
  for i = 1, select('#', ...) do
      local arg = tostring(select(i, ...))
      table.insert(ret, arg)
  end
  return table.concat(ret, '\t')
end

local function code(str)
  return string.format('```\n%s```', str)
end

function Lua.getSlashCommand(tools)
  return tools.slashCommand("lua", "I'll execute a Lua code for you nora!")
    :addOption(
      tools.string("code", "Your beautiful code!")
      :setRequired(true)
    )
end

-- https://github.com/SinisterRectus/Discordia/wiki/Executing-Lua-with-your-bot
function Lua:executeSlashCommand()
  local interaction, client, args = self._message, self._client, self._args

  if client.owner.id ~= interaction.user.id then
    interaction:reply("Only my owner can run this command nora.", true)
    return
  end

  local sandbox = setmetatable({
    os = { }
  }, { __index = _G })

  arg = args.code:gsub('```\n?', '') -- strip markdown codeblocks

  local lines = {}

  sandbox.message = interaction

  sandbox.print = function(...)
    table.insert(lines, printLine(...))
  end

  sandbox.p = function(...)
    table.insert(lines, prettyLine(...))
  end

  local fn, syntaxError = load(arg, 'DiscordBot', 't', sandbox)
  if not fn then return interaction:reply(code(syntaxError)) end

  local success, runtimeError = pcall(fn)
  if not success then return interaction:reply(code(runtimeError)) end

  local output = table.concat(lines, '\n')

  if #output > 1990 then -- truncate long messages
    output = output:sub(1, 1990)
  end

  interaction:reply(code(output))
end

return Lua