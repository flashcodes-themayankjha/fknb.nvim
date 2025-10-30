-- lua/fknb/init.lua

-- @fknotes NOTE: Main entry point for the FkNB plugin.
local M = {}

-- @fknotes NOTE: Function to set up the FkNB plugin.
function M.setup()
  -- @fknotes NOTE: Load filetype detection for FkNB related files.
  require("fknb.utils.fdetect")

  -- @fknotes NOTE: Initialize and register icons for FkNB related files.
  require("fknb.utils.icon").setup()

  -- @fknotes NOTE: Configure the fknb tree-sitter parser using nvim-treesitter.
  local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
  parser_config.fknb = {
    install_info = {
      -- path to your local repo
      url = "/Users/mayankjha/Documents/Projects/Flashcodes/Fkvim/fknb1/tree-sitter-fknb",
      files = { "src/parser.c" },

      -- if you also have scanner.cc:
      -- files = { "src/parser.c", "src/scanner.cc" },
    },
    filetype = "fknb",
  }
end

return M
