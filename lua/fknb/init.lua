-- lua/fknb/init.lua

-- @fknotes NOTE: Main entry point for the FkNB plugin.
local M = {}

-- @fknotes NOTE: Function to set up the FkNB plugin.
function M.setup()
  -- @fknotes NOTE: Load filetype detection for FkNB related files.
  require("fknb.utils.fdetect")

  -- @fknotes NOTE: Initialize and register icons for FkNB related files.
  require("fknb.utils.icon").setup()
end

return M