-- lua/fknb/core/renderer.lua
local M = {}

local cell_ui = require("fknb.ui.cell_ui")
local output_ui = require("fknb.ui.output")

-- Create a namespace for our virtual text
local ns_id = vim.api.nvim_create_namespace("fknb")

--- Renders the UI for a single cell.
--- @param bufnr number The buffer number.
--- @param cell table Information about the cell.
function M.render_cell(bufnr, cell)
  -- Clear old marks for this cell to prevent duplicates
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, cell.range[1], cell.range[3] + 1)

  -- Render output if it exists
  if cell.output then
    local output_lines = output_ui.create_output_text(cell.output)
    local output_virt_lines = {}
    for _, line in ipairs(output_lines) do
        table.insert(output_virt_lines, { { line, "Normal" } })
    end

    vim.api.nvim_buf_set_extmark(bufnr, ns_id, cell.range[3], 0, {
        virt_lines = output_virt_lines,
    })
  end
end

return M