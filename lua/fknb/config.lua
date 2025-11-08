local M = {}

M.options = {
  default_kernel = "python3",
  default_kernel_path = nil,
  cell_separator = "─",
  auto_save = false,

  ui = {
    spinner_frames = { "󰪞", "󰪟", "󰪠", "󰪡", "󰪢", "󰪣", "󰪤", "󰪥" },
    highlights = {
      FknbStatusDone       = { fg = "green" },
      FknbStatusError      = { fg = "red" },
      FknbStatusReady      = { fg = "white" },
      FknbStatusRunning    = { fg = "yellow" },
      FknbStatusRetry      = { fg = "yellow" },
      FknbStatusActive     = { fg = "green" },
      FknbStatusInactive   = { fg = "red" },
      FknbStatusNotReady   = { fg = "red" },
      FknbActionRunReady   = { fg = "green" },
      FknbActionRunError   = { fg = "red" },
      FknbActionDebug      = { fg = "red" },
      FknbActionRetry      = { fg = "yellow" },
    },
    cell_label_text = "Cell",
    cell_label_hl = "WarningMsg",
    id_label_hl = "DiagnosticInfo",
  },

  output = {
    icons = {
      ok    = "󰗠",
      error = "",
      info  = "󰜉",
    },
    highlights = {
      sep         = "Comment",
      icon_ok     = "DiffAdded",
      icon_err    = "DiagnosticError",
      icon_info   = "DiagnosticWarn",

      out_label   = "Normal",
      out_id      = "DiagnosticInfo",
      exec_lbl    = "Comment",
      exec_time   = "DiagnosticWarn",
      log_lbl     = "DiagnosticError",

      out_text    = "Normal",
      err_text    = "Normal",
    },
    indent_string = "  ",
  },

  icons = {
    kernels = {
      python = "",
      markdown = "",
      default = "",
    },
    env = {
      active   = "",
      inactive = "󱋙",
    },
    status = {
      ready     = "",
      running   = "",
      retry     = "󱍷",
      error     = "󰗖",
      not_ready = "󱃓",
    },
    actions = {
      run   = "▶",
      retry = "󰜉",
      debug = "",
    },
  },

  -- ⚙️ New: Keybindings (users can override)
  keymaps = {
    run_cell        = "<leader>kr",
    restart_kernel  = "<leader>kk",
    stop_kernel     = "<leader>ks",
    start_kernel    = "<leader>kS",
    clear_output    = "<leader>kc",
    clear_all       = "<leader>kC",
    toggle_output   = "<leader>kt",
  },
}

-- ============================================================================
-- Setup
-- ============================================================================
M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})

  -- Apply UI highlights
  for hl_group, opts in pairs(M.options.ui.highlights) do
    vim.api.nvim_set_hl(0, hl_group, opts)
  end

  -- Apply Output highlights
  for hl_group, opts in pairs(M.options.output.highlights) do
    vim.api.nvim_set_hl(0, hl_group, opts)
  end

  -- Apply keybindings dynamically
  local k = M.options.keymaps
  local map = vim.keymap.set

  -- Only map if not empty or false
  if k.run_cell then
    map("n", k.run_cell, function()
      require("fknb.commands").run_current_cell()
    end, { desc = "Run current FKNB cell", silent = true })
  end

  if k.restart_kernel then
    map("n", k.restart_kernel, function()
      require("fknb.commands").restart_kernel()
    end, { desc = "Restart FKNB kernel", silent = true })
  end

  if k.stop_kernel then
    map("n", k.stop_kernel, function()
      require("fknb.core.kernel").stop()
    end, { desc = "Stop FKNB kernel", silent = true })
  end

  if k.start_kernel then
    map("n", k.start_kernel, function()
      require("fknb.core.kernel").start()
    end, { desc = "Start FKNB kernel", silent = true })
  end

  if k.clear_output then
    map("n", k.clear_output, function()
      local cell = require("fknb.core.parser").get_cell_at_cursor()
      if cell then
        require("fknb.ui.output").clear(cell.id)
      else
        vim.notify("No cell under cursor", vim.log.levels.WARN)
      end
    end, { desc = "Clear current FKNB cell output", silent = true })
  end

  if k.clear_all then
    map("n", k.clear_all, function()
      require("fknb.core.kernel").clear_all_outputs()
    end, { desc = "Clear all FKNB outputs", silent = true })
  end

  if k.toggle_output then
    map("n", k.toggle_output, function()
      local cell = require("fknb.core.parser").get_cell_at_cursor()
      if cell then
        require("fknb.ui.output").toggle_collapse(cell.id)
      else
        vim.notify("No cell under cursor", vim.log.levels.WARN)
      end
    end, { desc = "Toggle FKNB cell output collapse", silent = true })
  end
end

return M
