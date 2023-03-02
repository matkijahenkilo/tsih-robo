local M = {}
local ORIGIN = "assets/images/omori/";

function M.getOmoriReactionGif(type, intensity)
  return ORIGIN .. type .. "_" .. intensity .. ".gif";
end

return M;
