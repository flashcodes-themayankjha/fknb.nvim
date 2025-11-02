local M = {}

M.options = {
  default_kernel = "python3",
  default_kernel_path = nil,
  default_kernel_name = nil,
  cell_separator = "─",
  auto_save = false,

  ui = {
    spinner_frames = { "󰪞", "󰪟", "󰪠", "󰪡", "󰪢","󰪣", "󰪤", "󰪥" },
    highlights = {
      FknbStatusDone = { fg = "green" },
      FknbStatusError = { fg = "red" },
      FknbStatusReady = { fg = "gray" },
      FknbStatusRunning = { fg = "yellow" },
      FknbStatusRetry = { fg = "orange" },
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

  markdown = {
    headers = {
      -- Highlight group names
      h1 = "FKNBHeader1",
      h2 = "FKNBHeader2",
      h3 = "FKNBHeader3",
      h4 = "FKNBHeader4",
      h5 = "FKNBHeader5",
      h6 = "FKNBHeader6",

      -- Symbols for inline visualization
      symbols = {
        h1 = "󰲡",
        h2 = "󰲣",
        h3 = "󰲥",
        h4 = "󰲧",
        h5 = "󰲩",
        h6 = "󰲫",
      },

      -- Fallback colors (Catppuccin inspired)
      colors = {
        h1 = "#F5C2E7", -- pink
        h2 = "#CBA6F7", -- lavender
        h3 = "#F9E2AF", -- yellow
        h4 = "#A6E3A1", -- green
        h5 = "#89B4FA", -- blue
        h6 = "#F38BA8", -- red
      },
    },
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
      error = "󰗖"
    },
    actions = {
      run = "▶",
      retry = "🔄",
      debug = "🐞",
    },
  },
}

-- Setup function for user override
M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})

  -- Auto-create header highlight groups if they don't exist
  local headers = M.options.markdown.headers
  for i = 1, 6 do
    local hl_name = headers["h" .. i]
    local color = headers.colors["h" .. i] or "#FFFFFF"
    if hl_name and color then
      vim.api.nvim_set_hl(0, hl_name, { fg = color, bold = true })
    end
  end

  -- Setup FknbStatus highlight groups
  for hl_group, opts in pairs(M.options.ui.highlights) do
    vim.api.nvim_set_hl(0, hl_group, opts)
  end
end

return M
