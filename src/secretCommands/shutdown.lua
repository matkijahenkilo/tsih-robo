local M = {}

local emojiSequence = {
  "🇧",
  "🇾",
  "🇪",

  "🇳",
  "🇴",
  "🇷",
  "🇦",
  "❗"
}

function M.execute(message)
  for _, value in ipairs(emojiSequence) do
    message:addReaction(value)
  end
  os.execute("shutdown now")
end

return M