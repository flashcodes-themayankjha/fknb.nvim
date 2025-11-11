-- lua/fknb/core/parser.lua
-- Parses .fknb buffers into structured notebook cells, safely ignoring UI decorations.

local M = {}

local ts = vim.treesitter
local parsers = require("nvim-treesitter.parsers")
local state = require("fknb.utils.state")

-- 🔹 Ensure parser exists and matches our language
local function ensure_parser(bufnr)
  local lang = parsers.get_buf_lang(bufnr)
  if lang ~= "fknb" then return nil end
  local ok, parser = pcall(ts.get_parser, bufnr, "fknb")
  return ok and parser or nil
end

-- 🔹 Clean up raw lines: remove separators, UI junk, and trailing spaces
local function sanitize_lines(lines)
  local cleaned = {}
  if not lines or type(lines) ~= "table" then return cleaned end

  for _, line in ipairs(lines) do
    if type(line) == "string" then
      -- ignore any full separator lines or decorative characters
      if not line:match("^%s*[─━%-%_=]+%s*$")
         and not line:match("^%s*$")
         and not line:match("^%s*#%%") then
        table.insert(cleaned, (line:gsub("%s+$", ""))) -- strip trailing spaces
      end
    end
  end

  return cleaned
end

-- 🔹 Extract language tag text if present
local function extract_lang(node, bufnr, query)
  for id, child in query:iter_captures(node, bufnr, node:start(), node:end_(), {}) do
    if query.captures[id] == "lang" then
      return vim.treesitter.get_node_text(child, bufnr)
    end
  end
  return nil
end

-- 🔹 Parse buffer into cells
function M.parse(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local parser = ensure_parser(bufnr)
  if not parser then return {} end

  local ok, tree = pcall(function() return parser:parse()[1] end)
  if not ok or not tree then return {} end

  local root = tree:root()
  state.cells = {}
  local cell_id = 0

  local query = ts.query.parse("fknb", [[
    (notebook_code_cell
      marker: "#%%"
      (language_tag)? @lang
      (raw_code_line)* @content
    ) @code_cell

    (notebook_markdown_cell
      marker: "#%"
      (markdown_text_line)* @content
    ) @md_cell
  ]])

  for id, node in query:iter_captures(root, bufnr, 0, -1, {}) do
    local name = query.captures[id]
    if name == "code_cell" or name == "md_cell" then
      cell_id = cell_id + 1
      local type = (name == "code_cell") and "code" or "markdown"
      local srow, scol, erow, ecol = node:range()
      local lang = extract_lang(node, bufnr, query)

      local raw_lines = vim.api.nvim_buf_get_lines(bufnr, srow + 1, erow, false)
      local clean_lines = sanitize_lines(raw_lines)

      state.cells[cell_id] = {
        id = cell_id,
        type = type,
        lang = lang or "python",
        range = { srow, scol, erow, ecol },
        lines = clean_lines,
        status = "ready",
        output = nil,
      }
    end
  end

  return state.cells
end

-- 🔹 Get cell at current cursor position
function M.get_cell_at_cursor(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local parser = ensure_parser(bufnr)
  if not parser then return nil end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1

  for _, cell in pairs(state.cells or {}) do
    if row >= cell.range[1] and row <= cell.range[3] then
      return cell
    end
  end
  return nil
end

-- 🔹 Get all code cells
function M.get_all_code_cells()
  local result = {}
  for _, cell in pairs(state.cells or {}) do
    if cell.type == "code" then table.insert(result, cell) end
  end
  table.sort(result, function(a, b) return a.id < b.id end)
  return result
end

-- 🔹 Get next code cell
function M.get_next_cell(current_id)
  local all = M.get_all_code_cells()
  for i, cell in ipairs(all) do
    if cell.id == current_id and all[i + 1] then
      return all[i + 1]
    end
  end
  return nil
end

return M
