local M = {}

local ts = vim.treesitter
local parsers = require("nvim-treesitter.parsers")

-- Ensure parser exists
local function ensure_parser(bufnr)
  local lang = parsers.get_buf_lang(bufnr)
  if lang ~= "fknb" then return nil end

  local parser = ts.get_parser(bufnr, "fknb")
  return parser
end

---@class FKNBCell
---type: "code" | "markdown"
---lang: string | nil
---range: {start_row, start_col, end_row, end_col}
---lines: table

local state = require("fknb.utils.state")

-- Parse buffer & return list of notebook cells
function M.parse(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local parser = ensure_parser(bufnr)
  if not parser then return {} end

  local tree = parser:parse()[1]
  local root = tree:root()

  state.cells = {}
  local cell_id = 0

  local query = ts.query.parse(
    "fknb",
    [[
      (notebook_code_cell
        marker: "#%%"
        lang: (language_tag)? @lang
        (raw_code_line)* @content
      ) @code_cell

      (notebook_markdown_cell
        marker: "#%"
        (markdown_text_line)* @content
      ) @md_cell
    ]]
  )

  for id, node, metadata in query:iter_captures(root, bufnr, 0, -1) do
    local name = query.captures[id]

    if name == "code_cell" or name == "md_cell" then
      cell_id = cell_id + 1
      local type = name == "code_cell" and "code" or "markdown"
      local start_row, start_col, end_row, end_col = node:range()

      -- language (for code cells)
      local lang_cap = metadata.lang
      local lang = nil
      if lang_cap then
        lang = vim.treesitter.get_node_text(lang_cap, bufnr)
      end

      local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, false)

      state.cells[cell_id] = {
        id = cell_id,
        type = type,
        lang = lang,
        range = {start_row, start_col, end_row, end_col},
        lines = lines,
        status = "ready",
      }
    end
  end

  return state.cells
end

function M.get_cell_at_cursor(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local parser = ensure_parser(bufnr)
  if not parser then return nil end

  local tree = parser:parse()[1]
  local root = tree:root()

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1

  local query = ts.query.parse(
    "fknb",
    [[
      (notebook_code_cell) @cell
      (notebook_markdown_cell) @cell
    ]]
  )

  for id, node, metadata in query:iter_captures(root, bufnr, row, row) do
    local name = query.captures[id]
    if name == "cell" then
      local start_row, _, end_row, _ = node:range()
      for _, cell in pairs(state.cells) do
        if cell.range[1] == start_row and cell.range[3] == end_row then
          return cell
        end
      end
    end
  end

  return nil
end

return M
