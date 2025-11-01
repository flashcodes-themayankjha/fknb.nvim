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

-- Parse buffer & return list of notebook cells
function M.parse(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local parser = ensure_parser(bufnr)
  if not parser then return {} end

  local tree = parser:parse()[1]
  local root = tree:root()

  local cells = {}

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
      local type = name == "code_cell" and "code" or "markdown"
      local start_row, start_col, end_row, end_col = node:range()

      -- language (for code cells)
      local lang_cap = metadata.lang
      local lang = nil
      if lang_cap then
        lang = vim.treesitter.get_node_text(lang_cap, bufnr)
      end

      local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, false)

      table.insert(cells, {
        type = type,
        lang = lang,
        range = {start_row, start_col, end_row, end_col},
        lines = lines,
      })
    end
  end

  return cells
end

return M
