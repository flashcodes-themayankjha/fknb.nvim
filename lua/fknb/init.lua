local M = {}
local config = require("fknb.config")
local state = require("fknb.utils.state")
local kernel = require("fknb.core.kernel")
local serializer = require("fknb.core.serializer")
local kernel_picker = require("fknb.ui.kernel_picker")

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

  vim.api.nvim_create_user_command("FkNBRun", function()
    M.run_current_cell()
  end, {})

  vim.api.nvim_create_user_command("FkNBSelectKernel", function()
    M.select_kernel()
  end, {})

  vim.api.nvim_create_user_command("FkNBKernel", function()
    M.start_last_kernel()
  end, {})

  vim.api.nvim_create_user_command("FkNBRunPrev", function()
    M.run_prev_cell()
  end, {})

  vim.api.nvim_create_user_command("FkNBRunNext", function()
    M.run_next_cell()
  end, {})

  vim.api.nvim_create_user_command("FkNBRunAll", function()
    M.run_all_cells()
  end, {})

  vim.api.nvim_create_user_command("FkNBSave", function()
    M.save()
  end, {})

  -- Autocmd for auto_save
  vim.api.nvim_create_autocmd({"BufWriteCmd", "BufWritePost"}, {
    pattern = "*.fknb",
    callback = function(e)
      if config.options.auto_save then
        M.save()
      end
    end,
  })

  -- Start the kernel bridge when the plugin is set up
  kernel.start()
end

function M.run_current_cell()
  local parser = require("fknb.core.parser")
  local kernel = require("fknb.core.kernel")
  local cell = parser.get_cell_at_cursor()
  if cell and cell.type == "code" then
    kernel.execute(cell.id, table.concat(cell.lines, "\n"))
  else
    vim.notify("Not in a code cell", vim.log.levels.WARN)
  end
end

function M.run_prev_cell()
  local parser = require("fknb.core.parser")
  local current_cell = parser.get_cell_at_cursor()
  if not current_cell then
    vim.notify("Not in a cell", vim.log.levels.WARN)
    return
  end

  local prev_cell = nil
  for i = current_cell.id - 1, 1, -1 do
    if state.cells[i] and state.cells[i].type == "code" then
      prev_cell = state.cells[i]
      break
    end
  end

  if prev_cell then
    vim.api.nvim_win_set_cursor(0, {prev_cell.range[1] + 1, 0})
    kernel.execute(prev_cell.id, table.concat(prev_cell.lines, "\n"))
  else
    vim.notify("No previous code cell found", vim.log.levels.INFO)
  end
end

function M.run_next_cell()
  local parser = require("fknb.core.parser")
  local current_cell = parser.get_cell_at_cursor()
  if not current_cell then
    vim.notify("Not in a cell", vim.log.levels.WARN)
    return
  end

  local next_cell = nil
  for i = current_cell.id + 1, #state.cells do
    if state.cells[i] and state.cells[i].type == "code" then
      next_cell = state.cells[i]
      break
    end
  end

  if next_cell then
    vim.api.nvim_win_set_cursor(0, {next_cell.range[1] + 1, 0})
    kernel.execute(next_cell.id, table.concat(next_cell.lines, "\n"))
  else
    vim.notify("No next code cell found", vim.log.levels.INFO)
  end
end

function M.run_all_cells()
  local parser = require("fknb.core.parser")
  local cells = parser.parse() -- Re-parse to ensure latest state
  
  local function execute_next_code_cell(index)
    if index > #cells then
      vim.notify("All cells executed.", vim.log.levels.INFO)
      return
    end

    local cell = cells[index]
    if cell and cell.type == "code" then
      kernel.execute(cell.id, table.concat(cell.lines, "\n"))
      -- A small delay to allow the kernel to process the command
      vim.defer_fn(function()
        execute_next_code_cell(index + 1)
      end, 100) -- Adjust delay as needed
    else
      execute_next_code_cell(index + 1)
    end
  end

  execute_next_code_cell(1)
end

function M.save()
  local bufnr = vim.api.nvim_get_current_buf()
  local file_content = serializer.serialize_cells()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(file_content, "\n"))
  vim.cmd("write") -- Actually write the buffer to disk
  vim.notify("Notebook saved.", vim.log.levels.INFO)
end

function M.select_kernel()
  kernel.list_kernels(function(available_kernels)
    kernel_picker.show_kernel_picker(available_kernels)
  end)
end

function M.start_last_kernel()
  if state.last_selected_kernel then
    config.options.default_kernel = state.last_selected_kernel
    kernel.stop() -- Stop current kernel if running
    kernel.start()
    vim.notify("Starting last selected kernel: " .. state.last_selected_kernel, vim.log.levels.INFO)
  else
    vim.notify("No last selected kernel found. Please select one first.", vim.log.levels.WARN)
  end
end

return M