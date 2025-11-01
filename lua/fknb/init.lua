local M = {}

function M.setup()
  -- Filetype + icons
  require("fknb.utils.fdetect")
  require("fknb.utils.icon").setup()

  -- Treesitter parser config
  local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
  parser_config.fknb = {
    install_info = {
      url = "https://github.com/flashcodes-themayankjha/tree-sitter-fknb",
      files = { "src/parser.c" },
      branch = "main",
    },
    filetype = "fknb",
  }

  -- Needed for Neovim 0.10+
  if vim.treesitter.language then
    vim.treesitter.language.register("fknb", "fknb")
  end

  -- Parser + UI
  local parser = require("fknb.core.parser")
  local ui = require("fknb.ui.cell_ui")

  -- Debug command
  vim.api.nvim_create_user_command("FKNBParse", function()
    local cells = parser.parse()
    print(vim.inspect(cells))
  end, {})

  -- Attach smoothing UI behavior
  ui.attach_autocmd()
end

return M
