-- Author : Mayank Jha
local M = {}
local ns = vim.api.nvim_create_namespace("fknb_output")
local config = require("fknb.config")

local icons = config.options.output.icons
local hl = config.options.output.highlights
local INDENT = config.options.output.indent_string

---
--@param buf number
--@param lnum number
--@param cell_id number
--@param output string
--@param status string
--@param exec_ms number
function M.render(buf, lnum, cell_id, output, status, exec_ms)
  vim.api.nvim_buf_clear_namespace(buf, ns, lnum, lnum + 20)

  local width = vim.api.nvim_win_get_width(0)
  local sep = string.rep(config.options.cell_separator, width)

  local icon = icons[status] or icons.info
  local icon_hl = ({
    ok = hl.icon_ok,
    error = hl.icon_err,
    info = hl.icon_info,
  })[status] or hl.icon_info

  local exec_label = (status == "error") and "Failed in" or "Executed in"

  -- Header Virt Text segments
  local left_segments = {
    { icon .. " ", icon_hl },
    { "[ Out: ", hl.out_label },
    { "#" .. cell_id, hl.out_id },
    { " ]", hl.out_label },
  }

  local right_segments = {
    { exec_label .. " ", hl.exec_lbl },
    { tostring(exec_ms) .. "ms", hl.exec_time },
  }

  local left_len = vim.fn.strdisplaywidth(
    table.concat(vim.tbl_map(function(seg) return seg[1] end, left_segments))
  )
  local right_len = vim.fn.strdisplaywidth(
    table.concat(vim.tbl_map(function(seg) return seg[1] end, right_segments))
  )

  local spacing = width - left_len - right_len
  if spacing < 1 then spacing = 1 end

  local virt = {}

  -- Top header line
  local header = vim.list_extend(
    left_segments,
    { { string.rep(" ", spacing), "" } }
  )
  vim.list_extend(header, right_segments)
  table.insert(virt, header)

  -- Separator
  table.insert(virt, { { sep, hl.sep } })

  -- Log for errors
  if status == "error" then
    table.insert(virt, { { "Log:", hl.log_lbl } })
  end

  -- Output body
  for _, line in ipairs(vim.split(output or "", "\n", { trimempty = false })) do
    table.insert(virt, { { INDENT .. line, status == "error" and hl.err_text or hl.out_text } })
  end

  -- Bottom separator
  table.insert(virt, { { sep, hl.sep } })

  vim.api.nvim_buf_set_extmark(buf, ns, lnum, 0, {
    virt_lines = virt,
    priority = 500,
  })
end

return M