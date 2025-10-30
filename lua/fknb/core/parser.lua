local M = {}

local function get_ts_parser(lang)
  local parser = vim.treesitter.get_parser(lang)
  if not parser then
    vim.notify("Tree-sitter parser for '" .. lang .. "' not found. Please ensure it's installed.", vim.log.ERROR)
    return nil
  end
  return parser
end

function M.parse(bufnr)
  local parser = get_ts_parser("fknb")
  if not parser then
    return {}
  end

  local buf_content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local tree = parser:parse(buf_content)
  local root = tree:root()

  local cells = {}

  local query_string = [[
  (code_cell body: (code_line) @code)
  (markdown_cell body: (markdown_line) @markdown)
  (fenced_code_cell body: (fenced_line) @code)
]]

  local query = vim.treesitter.query.parse("fknb", query_string)

  for _, match, metadata in query:iter_matches(root, bufnr, 0, #buf_content) do
    local cell_type = nil
    local cell_content = nil

    for id, node in pairs(match) do
      local name = query.captures[id]
      if name == "code" then
        cell_type = "code"
        cell_content = vim.treesitter.get_node_text(node, bufnr)
      elseif name == "markdown" then
        cell_type = "markdown"
        cell_content = vim.treesitter.get_node_text(node, bufnr)
      elseif name == "raw" then
        cell_type = "raw"
        cell_content = vim.treesitter.get_node_text(node, bufnr)
      end
    end

    if cell_type and cell_content then
      table.insert(cells, { type = cell_type, content = cell_content })
    end
  end

  return cells
end

return M
