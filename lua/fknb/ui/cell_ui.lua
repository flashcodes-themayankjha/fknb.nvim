local M = {}

local parser = require("fknb.core.parser")

-- namespace for extmarks
local ns = vim.api.nvim_create_namespace("fknb_ui_cells")

-- Icons (you can override these later from config)
local icons = {
  code = "",
  markdown = "",
  python = "",
  r = "󰟔",
  bash = "",
  unknown = "",
  run = "",
}

-- simple lang→icon map
local lang_icon = {
  python = icons.python,
  py = icons.python,
  r = icons.r,
  bash = icons.bash,
  sh = icons.bash,
}

local function get_icon_for_cell(cell)
  if cell.type == "markdown" then return icons.markdown end
  if not cell.lang then return icons.code end
  return lang_icon[cell.lang] or icons.code
end

-- small status text — later we'll make dynamic
local function get_status(cell)
  return cell.type == "markdown" and "md" or (cell.lang or "code")
end

-- draw a single cell
local function render_cell(bufnr, cell)
  local icon = get_icon_for_cell(cell)
  local status = get_status(cell)

  local right = string.format("%s  %s", icon, status)
  local left = cell.type == "markdown" and "Markdown Cell" or "Code Cell"

  local width = vim.api.nvim_win_get_width(0)
  local pad = width - #left - #right - 2
  if pad < 1 then pad = 1 end

  local header = left .. string.rep(" ", pad) .. right
  local sep = string.rep("─", width)

  local pos = cell.range[1]  -- start line

  vim.api.nvim_buf_set_extmark(bufnr, ns, pos, 0, {
    virt_lines = {
      { { sep, "Comment" } },
      { { header, "Title" } },
      { { sep, "Comment" } },
    },
    virt_lines_above = true,
    hl_mode = "combine",
    priority = 200,
  })
end

-- clear previous marks
local function clear(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

-- public API: render all cells
function M.render(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  clear(bufnr)

  local cells = parser.parse(bufnr)
  for _, c in ipairs(cells) do
    render_cell(bufnr, c)
  end
end

-- auto-render
function M.attach_autocmd()
  vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
    pattern = "*.fknb",
    callback = function(args)
      vim.schedule(function()
        M.render(args.buf)
      end)
    end,
  })
end

return M
