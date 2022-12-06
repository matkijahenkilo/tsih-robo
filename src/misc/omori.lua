local M = {}
local ORIGIN = "assets/images/omori/";

---Sends an OMORI's parody Tsih emotion to the message sender.
---@param message table
---@param type integer
---@param intensity integer
---@param answer string
function M.omoriReaction(message, type, intensity, answer)
  local gif = ORIGIN .. type .. "_" .. intensity .. ".gif";

  if answer ~= nil then
    message.channel:send {
      content = answer;
      file = gif;
    }
  else
    message.channel:send {
      file = gif;
    }
  end
end

return M;
