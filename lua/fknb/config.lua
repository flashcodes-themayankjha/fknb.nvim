
local M = {}

M.options = {
  theme = "onedark",
  default_kernel = "python3",
  cell_separator = "─",
  show_watermark = true,

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
    auto_rerender = true,
    
    lists = {
      ordered = "FKNBListOrdered",
      unordered = "FKNBListUnordered",
    },
    codeblocks = "FKNBCodeBlock",
    links = "FKNBLink",
    images = "FKNBImage",
    callouts = "FKNBCallout",
    blockquotes = "FKNBBlockquote",
  },

  icons = {
    kernels = {
      python = "",
      r = "",
      markdown = "",
      kernel = "",
      default = "",
      active = "",
      inactive = "󱋙",
    },
    env = {
      active = "",
      inactive = "󱋙",
    },
    status = {
      ready = "▶",
      running = "󰑙",
      paused = "⏸",
      stop = "⏹",
      retry = "🔄",
    },
  },

  colors = {
    kernel_active = "#00ff00",
    kernel_inactive = "#ff0000",
    env_active = "#00ff00",
    env_inactive = "#ff0000",
  },

  export = {
    enable_pdf = true,
    enable_md = true,
  },

  render = {
    max_output_lines = 100,
    image_inline = true,
    non_destructive = false,  -- true = pretty, false = selectable

  },

  -- Internal state, not meant for user configuration
  cells = {},
  kernel = {
    instance = nil,
    name = nil,
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
end

return M
