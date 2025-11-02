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
  ui.attach_autocmd()
  local renderer = require("fknb.core.renderer")

  -- Debug command
  vim.api.nvim_create_user_command("FKNBParse", function()
    local cells = parser.parse()
    print(vim.inspect(cells))
  end, {})

  vim.api.nvim_create_user_command("FKNBRender", function()
    renderer.render_dummy_cell()
  end, {})
end

function M.run_current_cell()
  local parser = require("fknb.core.parser")
  local kernel = require("fknb.core.kernel")
  local cell = parser.get_cell_at_cursor()
  if cell then
    kernel.execute(cell.id, table.concat(cell.lines, "\n"))
  else
    vim.notify("Not in a cell", vim.log.levels.WARN)
  end
end

return M