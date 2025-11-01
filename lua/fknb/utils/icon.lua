-- lua/fknb/icons.lua
local M = {}

-- @fknotes NOTE: FkNB file icon definition.
M.icon = {
   icon = "󰧑",
   color = "#f9e2af",
   name = "FkNB",
}

-- @fknotes NOTE: Function to set up and register icons with nvim-web-devicons.
function M.setup()
   local ok, devicons = pcall(require, "nvim-web-devicons")
  
  if not ok then return end


  -- @fknotes NOTE: Register the FkNB icon for various notebook filetypes.
  devicons.set_icon({
    fknb = M.icon,
    nb = M.icon,
    ipynb = M.icon,
    pynb = M.icon,
  })
end

return M
