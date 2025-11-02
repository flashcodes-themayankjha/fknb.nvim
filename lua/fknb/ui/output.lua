-- lua/fknb/ui/output.lua

local M = {}

--- Creates the output frame text.
--- @param output_data table Data including content (as a list of strings), execution_count, and status.
function M.create_output_text(output_data)
  local width = vim.api.nvim_win_get_width(0)
  local lines = {}

  -- For now, using a simple top separator. Can be customized later.
  local top_separator = "──────────────── output ────────────────"
  local top_padding_width = width - vim.fn.strwidth(top_separator)
  if top_padding_width > 0 then
      top_separator = top_separator .. string.rep("─", top_padding_width)
  end
  table.insert(lines, top_separator)


  -- Add the actual output content
  for _, line in ipairs(output_data.content or {}) do
    table.insert(lines, line)
  end

  -- Create the footer: ─ Out[5] ─ ERROR ───────────────────╮
  local status_str = string.upper(output_data.status or "SUCCESS")
  local footer_label = string.format("─ Out[%d] ─ %s ─", output_data.execution_count, status_str)
  local footer_end = "╮"

  local padding_width = width - vim.fn.strwidth(footer_label) - vim.fn.strwidth(footer_end)
  local padding = ""
  if padding_width > 0 then
    padding = string.rep("─", padding_width)
  end

  local footer = padding .. footer_label .. footer_end
  table.insert(lines, footer)

  return lines
end


return M
