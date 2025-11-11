-- lua/fknb/core/kernel.lua
print("FkNBDebug: kernel.lua loaded")

local M      = {}
local config = require("fknb.config")
local state  = require("fknb.utils.state")

local job_id   = nil
local buf_acc  = ""         -- stdout accumulator
local msg2cell = {}         -- msg_id -> cell_id mapping

-- ╭──────────────────────────────────────────────────────────╮
-- │                     Helper Functions                    │
-- ╰──────────────────────────────────────────────────────────╯
local function ui_output()
  local ok, ui = pcall(require, "fknb.ui.output")
  if ok then return ui end
  print("FkNBDebug: fknb.ui.output missing")
  return nil
end

local function safe_decode(line)
  local ok, t = pcall(vim.fn.json_decode, line)
  if not ok then
    print("FkNBDebug: JSON decode failed:", line)
    return nil
  end
  return t
end

local function current_cell_id_fallback()
  local ok, parser = pcall(require, "fknb.core.parser")
  if not ok then return nil end
  local c = parser.get_cell_at_cursor()
  return c and c.id or nil
end

local function mark_running(cell_id)
  local cell = state.cells[cell_id]
  if not cell then return end
  cell.status = "running"
  cell.exec_time = nil
  local ui = ui_output()
  if ui and ui.render_output then
    ui.render_output(cell_id, cell.output or "", "running", nil)
  end
end

-- ╭──────────────────────────────────────────────────────────╮
-- │                     Message Handling                    │
-- ╰──────────────────────────────────────────────────────────╯
local function handle_msg(msg)
  local ui = ui_output()
  if not ui or not msg then return end

  local t       = msg.type or "info"
  local cell_id = msg.cell_id or (msg.id and msg2cell[msg.id]) or current_cell_id_fallback()
  if not cell_id then
    print("FkNBDebug: ⚠ no cell_id for message", vim.inspect(msg))
    return
  end

  local cell = state.cells[cell_id]
  if not cell then
    print("FkNBDebug: unknown cell", cell_id)
    return
  end

  if t == "status" then
    return

  elseif t == "exec_ack" then
    if msg.id then msg2cell[msg.id] = cell_id end
    mark_running(cell_id)
    return

  elseif t == "stream" then
    local text = (msg.content and msg.content.text) or ""
    cell.status = "running"
    cell.output = (cell.output or "") .. text
    ui.render_output(cell_id, cell.output, "running", cell.exec_time)
    return

  elseif t == "display_data" or t == "execute_result" then
    local c = msg.content or {}
    local payload = c["text/plain"] or c.output or c.data or c
    cell.status = "ok"
    cell.output = payload
    ui.render_output(cell_id, cell.output, "ok", cell.exec_time)
    return

  elseif t == "clear_output" then
    local ui = ui_output()
    if ui and ui.clear then ui.clear(cell_id) end
    cell.output = ""
    cell.status = "running"
    return

  elseif t == "error" then
    local c  = msg.content or {}
    local tb = table.concat(c.traceback or {}, "\n")
    cell.status = "error"
    cell.output = (tb ~= "" and tb) or (c.evalue or "Error")
    ui.render_output(cell_id, cell.output, "error", cell.exec_time)
    return

  elseif t == "execution_complete" then
    local et_ms = (msg.content and msg.content.execution_time) or 0
    cell.exec_time = et_ms
    ui.render_output(cell_id, cell.output or "", cell.status or "ok", cell.exec_time)
    return
  end
end

-- ╭──────────────────────────────────────────────────────────╮
-- │                    Job Callbacks                         │
-- ╰──────────────────────────────────────────────────────────╯
local function on_stdout(_, data, _)
  if not data or not state.kernel then return end
  buf_acc = buf_acc .. table.concat(data, "\n")
  local lines = vim.split(buf_acc, "\n", { trimempty = false })
  if #lines == 0 then buf_acc = ""; return end

  for i = 1, #lines - 1 do
    local line = lines[i]
    if line ~= "" then
      local msg = safe_decode(line)
      if msg then
        if msg.status == "ready" then
          state.kernel.id = job_id
          state.kernel.running = true
          print("FkNBDebug: Kernel ready.")
        else
          handle_msg(msg)
        end
      end
    end
  end
  buf_acc = lines[#lines] or ""
end

local function on_stderr(_, data, _)
  if data and #data > 0 then
    print("FkNBDebug: Kernel bridge error:", table.concat(data, "\n"))
    for _, line in ipairs(data) do
      local mid = line:match("msg_id:%s*([%w%-_]+)")
      local cid = line:match("cell_id%s*(%d+)")
      if mid and cid then msg2cell[mid] = tonumber(cid) end
    end
  end
end

local function on_exit(_, code, _)
  print("FkNBDebug: Kernel exited with code", code)
  state.kernel = nil
  job_id = nil
end

-- ╭──────────────────────────────────────────────────────────╮
-- │                    Kernel Lifecycle                      │
-- ╰──────────────────────────────────────────────────────────╯
local function check_deps(python, cb)
  vim.fn.jobstart({ python, "-c", "import jupyter_client, ipykernel" }, {
    on_exit = function(_, code)
      if code == 0 then cb()
      else print("FkNBDebug: Missing deps — run: pip install jupyter_client ipykernel") end
    end
  })
end

function M.is_running()
  return job_id ~= nil
end

function M.start()
  if job_id then
    print("FkNBDebug: Kernel already running.")
    return
  end

  local python = config.options.default_kernel or "python3"
  state.kernel = { name = python, running = false }

  local bridge = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h") .. "/bridge/kernel_bridge.py"
  check_deps(python, function()
    job_id = vim.fn.jobstart({ python, "-u", bridge }, {
      on_stdout = on_stdout,
      on_stderr = on_stderr,
      on_exit   = on_exit,
      pty       = false,
    })
    if job_id > 0 then
      print("FkNBDebug: Kernel bridge started with job_id", job_id)
    else
      print("FkNBDebug: Failed to start kernel bridge")
      job_id = nil
      state.kernel = nil
    end
  end)
end

function M.stop()
  if not job_id then return end
  vim.fn.jobsend(job_id, vim.fn.json_encode({ action = "shutdown" }) .. "\n")
  vim.defer_fn(function()
    vim.fn.jobstop(job_id)
    job_id = nil
    state.kernel = nil
    print("FkNBDebug: Kernel stopped.")
  end, 300)
end

-- ╭──────────────────────────────────────────────────────────╮
-- │                    Execution Logic                       │
-- ╰──────────────────────────────────────────────────────────╯
function M.execute()
  if not job_id or not state.kernel then
    print("FkNBDebug: Kernel not running.")
    return
  end

  local parser = require("fknb.core.parser")
  local cell = parser.get_cell_at_cursor()
  if not cell or not cell.lines then
    print("FkNBDebug: No valid cell found under cursor.")
    return
  end

  local code = vim.trim(table.concat(cell.lines, "\n"))
  if code == "" then
    print("FkNBDebug: Cell is empty, skipping execution.")
    return
  end

  cell.output = ""
  cell.status = "running"
  mark_running(cell.id)

  local cmd = { action = "execute", code = code, cell_id = cell.id }
  vim.fn.jobsend(job_id, vim.fn.json_encode(cmd) .. "\n")
  print(("FkNBDebug: Code sent to kernel for Cell #%d"):format(cell.id))
end

-- Run all notebook cells
function M.run_all()
  if not job_id or not state.kernel then
    print("FkNBDebug: Kernel not running.")
    return
  end
  local parser = require("fknb.core.parser")
  local cells = parser.get_all_code_cells()
  for _, cell in ipairs(cells) do
    local code = vim.trim(table.concat(cell.lines, "\n"))
    if code ~= "" then
      cell.output, cell.status = "", "running"
      mark_running(cell.id)
      vim.fn.jobsend(job_id, vim.fn.json_encode({
        action = "execute",
        code = code,
        cell_id = cell.id,
      }) .. "\n")
      print(("FkNBDebug: Executing Cell #%d..."):format(cell.id))
    end
  end
end

-- Run all cells below current
function M.run_below()
  if not job_id or not state.kernel then
    print("FkNBDebug: Kernel not running.")
    return
  end
  local parser = require("fknb.core.parser")
  local cur = parser.get_cell_at_cursor()
  if not cur then
    print("FkNBDebug: No current cell.")
    return
  end

  local all = parser.get_all_code_cells()
  local found = false
  for _, cell in ipairs(all) do
    if found then
      local code = vim.trim(table.concat(cell.lines, "\n"))
      if code ~= "" then
        cell.output, cell.status = "", "running"
        mark_running(cell.id)
        vim.fn.jobsend(job_id, vim.fn.json_encode({
          action = "execute",
          code = code,
          cell_id = cell.id,
        }) .. "\n")
        print(("FkNBDebug: Executing Cell #%d..."):format(cell.id))
      end
    end
    if cell.id == cur.id then found = true end
  end
end

-- ╭──────────────────────────────────────────────────────────╮
-- │                    User Commands                         │
-- ╰──────────────────────────────────────────────────────────╯

return M
