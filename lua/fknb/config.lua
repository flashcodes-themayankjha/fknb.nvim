local M = {}

M.options = {
  default_kernel = "python3",
  default_kernel_path = nil,
  default_kernel_name = "Python 3.10",
  cell_separator = "─",
  auto_save = false,

  ui = {
    spinner_frames = { "󰪞", "󰪟", "󰪠", "󰪡", "󰪢","󰪣", "󰪤", "󰪥" },
    highlights = {
      FknbStatusDone = { fg = "green" },
      FknbStatusError = { fg = "red" },
      FknbStatusReady = { fg = "white" },
      FknbStatusRunning = { fg = "yellow" },
      FknbStatusRetry = { fg = "yellow" },
      FknbStatusActive       = { fg = "green" },
      FknbStatusInactive = { fg = "red" },
      FknbStatusNotReady = { fg = "red" },
      FknbActionRunReady = { fg = "green" },
      FknbActionRunError = { fg = "red" },
      FknbActionDebug = { fg = "red" },
      FknbActionRetry = { fg = "yellow" },
    },
    cell_label_text = "Cell",
    cell_label_hl = "WarningMsg",
    id_label_hl = "DiagnosticInfo",
  },

  output = {
    icons = {
      ok = "󰗠",
      error = "",
      info = "󰜉",
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
      active = "",
      inactive = "󱋙",
    },
    status = {
      ready = "",
      running = "",
      retry = "󱍷",
      error = "󰗖",
      not_ready = "󱃓",
    },
    actions = {
      run = "▶",
      retry = "󰜉",
      debug = "",
    },
  },
}

M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})

  -- UI status HL
  for hl_group, opts in pairs(M.options.ui.highlights) do
    vim.api.nvim_set_hl(0, hl_group, opts)
  end

  -- ✅ Output HL
  for hl_group, opts in pairs(M.options.output.highlights) do
    vim.api.nvim_set_hl(0, hl_group, opts)
  end
end
return M
