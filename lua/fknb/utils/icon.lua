-- lua/fknb/icons.lua
local M = {}

-- @fknotes NOTE: FkNB File icon definition and registeration

-- FkNB file icon definition
M.icon = {
  icon = "󰧑",            -- You can change to your preferred glyph (, , , etc.)
  color = "#f9e2af",      
  name = "FkNB",
}

-- Register with nvim-web-devicons (if installed)
function M.setup()
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if not ok then return end

  devicons.set_icon({
    fknb = M.icon,
    nb = M.icon,
    ipynb = M.icon,
    pynb = M.icon,
  })
end

return M
