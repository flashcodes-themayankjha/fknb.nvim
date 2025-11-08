-- lua/fknb/ui/output.lua
-- Persistent Jupyter-style outputs: selectable, overwritable, collapsible.

local M = {}
local ns = vim.api.nvim_create_namespace("fknb_output")
M.ns = ns

local config = require("fknb.config")
local state = require("fknb.utils.state")

state.output_ranges   = state.output_ranges   or {}
state.output_headers  = state.output_headers  or {}
state.output_collapsed= state.output_collapsed or {}
state.output_cache    = state.output_cache    or {}

local icons = config.options.output.icons
local hl    = config.options.output.highlights
local INDENT= config.options.output.indent_string or "  "
local MAXL  = config.options.output.max_lines or 800
local spinner_frames = config.options.ui.spinner_frames or { "●", "◐", "◓", "◑" }
local spinner_index = 1
local running = {}

local function cell_anchor_row(cell) return cell.range[3] end -- exactly under the cell
local function sep_line()
  local w = vim.api.nvim_win_get_width(0)
  return string.rep(config.options.cell_separator or "─", w)
end

local function draw_header(buf, row, cell_id, status, exec_ms)
  if state.output_headers[cell_id] then
    pcall(vim.api.nvim_buf_del_extmark, buf, ns, state.output_headers[cell_id])
  end

  local icon = (status == "running") and spinner_frames[spinner_index] or (icons[status] or icons.info)
  local icon_hl = ({
    ok    = hl.icon_ok,
    error = hl.icon_err,
    info  = hl.icon_info,
    running = hl.icon_info,
  })[status] or hl.icon_info

  local left = {
    { icon .. " ", icon_hl },
    { "[ Out: ", hl.out_label },
    { "#" .. cell_id, hl.out_id },
    { " ]", hl.out_label },
  }

  local right
  if status == "error" then
    right = { { "Failed in ", hl.exec_lbl }, { exec_ms and (math.floor(exec_ms).."ms") or "", hl.exec_time } }
  elseif status == "running" then
    right = { { "Running...", hl.exec_lbl }, { "", hl.exec_time } }
  else
    right = { { "Executed in ", hl.exec_lbl }, { exec_ms and (math.floor(exec_ms).."ms") or "", hl.exec_time } }
  end

  local left_text  = table.concat(vim.tbl_map(function(s) return s[1] end, left))
  local right_text = table.concat(vim.tbl_map(function(s) return s[1] end, right))
  local width = vim.api.nvim_win_get_width(0)
  local spacing = math.max(1, width - vim.fn.strdisplaywidth(left_text) - vim.fn.strdisplaywidth(right_text))

  local virt = {}
  table.insert(virt, { { " ", "" } })
  local header = vim.deepcopy(left)
  table.insert(header, { string.rep(" ", spacing), "" })
  vim.list_extend(header, right)
  table.insert(virt, header)
  table.insert(virt, { { sep_line(), hl.sep } })

  local mark = vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
    virt_lines = virt,
    virt_lines_above = false,
    priority = 500,
  })
  state.output_headers[cell_id] = mark
end

local function wipe_body(buf, cell_id)
  local r = state.output_ranges[cell_id]
  if not r then return end
  pcall(vim.api.nvim_buf_set_lines, buf, r.start, r.finish, false, {})
  state.output_ranges[cell_id] = nil
end

local function insert_body(buf, start_row, cell_id, lines)
  vim.api.nvim_buf_set_lines(buf, start_row, start_row, false, lines)
  state.output_ranges[cell_id] = { start = start_row, finish = start_row + #lines }
end

local function normalize_output(o)
  if type(o) == "string" then return o end
  if type(o) == "table" then
    if o["text/plain"] then return o["text/plain"] end
    if o.data and o.data["text/plain"] then return o.data["text/plain"] end
    if o.output then return o.output end
    return vim.inspect(o)
  end
  return tostring(o or "")
end

function M.render_output(cell_id, output, status, exec_ms)
  local cell = state.cells[cell_id]
  if not cell or not cell.range then return end
  local buf = vim.api.nvim_get_current_buf()
  local anchor = cell_anchor_row(cell)

  running[cell_id] = (status == "running")

  -- header
  draw_header(buf, anchor, cell_id, status, exec_ms)

  -- body
  local body = {}
  local text = normalize_output(output or "")
  local lines = vim.split(text, "\n", { trimempty = false })
  if #lines > MAXL then
    lines = vim.list_slice(lines, 1, MAXL)
    table.insert(lines, "... (output truncated) ...")
  end
  if state.output_collapsed[cell_id] then
    body = { INDENT .. "⋯ output hidden ⋯" }
  else
    for _, l in ipairs(lines) do
      table.insert(body, INDENT .. l)
    end
  end

  -- overwrite body region
  wipe_body(buf, cell_id)
  insert_body(buf, anchor + 1, cell_id, body)

  -- bottom separator (plain line in buffer to keep selection natural)
  pcall(vim.api.nvim_buf_set_lines, buf, state.output_ranges[cell_id].finish, state.output_ranges[cell_id].finish, false, { sep_line() })
  state.output_ranges[cell_id].finish = state.output_ranges[cell_id].finish + 1
end

function M.toggle_collapse(cell_id)
  local cell = state.cells[cell_id]; if not cell then return end
  state.output_collapsed[cell_id] = not state.output_collapsed[cell_id]
  M.render_output(cell_id, cell.output or "", cell.status or "ok", cell.exec_time)
end

function M.clear(cell_id)
  local cell = state.cells[cell_id]; if not cell then return end
  local buf = vim.api.nvim_get_current_buf()
  local hdr = state.output_headers[cell_id]
  if hdr then pcall(vim.api.nvim_buf_del_extmark, buf, ns, hdr) end
  wipe_body(buf, cell_id)
  state.output_headers[cell_id] = nil
  state.output_collapsed[cell_id] = nil
  state.output_cache[cell_id] = nil
  cell.output = nil; cell.exec_time = nil; cell.status = "ready"
end

-- spinner
local function tick()
  spinner_index = (spinner_index % #spinner_frames) + 1
  for cid, isrun in pairs(running) do
    if isrun then
      local cell = state.cells[cid]
      if cell then
        draw_header(vim.api.nvim_get_current_buf(), cell_anchor_row(cell), cid, "running", cell.exec_time)
      end
    end
  end
end
local timer = vim.loop.new_timer()
timer:start(0, 120, vim.schedule_wrap(tick))

-- commands
vim.api.nvim_create_user_command("FknbClearOutput", function()
  local c = require("fknb.core.parser").get_cell_at_cursor()
  if c then M.clear(c.id) end
end, {})

vim.api.nvim_create_user_command("FknbToggleCollapse", function()
  local c = require("fknb.core.parser").get_cell_at_cursor()
  if c then M.toggle_collapse(c.id) end
end, {})

return M
