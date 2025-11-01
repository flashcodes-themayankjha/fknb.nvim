local M = {}

function M.setup()
  require("fknb.utils.fdetect")
  require("fknb.utils.icon").setup()

  -- Treesitter parser config
  local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

  parser_config.fknb = {
    install_info = {
      -- MUST be your repo, not local path
      url = "https://github.com/flashcodes-themayankjha/tree-sitter-fknb",
      files = { "src/parser.c" },
      branch = "main",
    },
    filetype = "fknb",
  }

  -- Only needed on Neovim 0.10+ (NOT older versions)
  if vim.treesitter.language then
    vim.treesitter.language.register("fknb", "fknb")
  end
end

return M
