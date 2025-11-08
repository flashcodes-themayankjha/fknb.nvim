-- lua/fknb/core/kernel.lua
print("FkNBDebug: kernel.lua loaded")

local M = {}
local config = require("fknb.config")
local state = require("fknb.utils.state")

local job_id = nil
local buffer = ""

-- map exec msg id -> cell_id (in case the bridge forgets to echo)
local msg_to_cell = {}

-- safe json
local function safe_decode(line)
  local ok, res = pcall(vim.fn.json_decode, line)
  if not ok then
    print("FkNBDebug: JSON decode failed:", line)
    return nil
  end
  return res
end

-- core UI (persistent selectable output)
local function output_ui()
  local ok, ui = pcall(require, "fknb.ui.output")
  if ok then return ui end
  print("FkNBDebug: fknb.ui.output missing")
  return nil
end

-- handle a single message from bridge
local function handle_msg(msg)
  local ui = output_ui()
  if not ui or not msg then return end

  local t = msg.type or "info"
  local cell_id = msg.cell_id or (msg.id and msg_to_cell[msg.id]) -- belt & suspenders
  if not cell_id then
    -- last resort: current cell
    local cur = require("fknb.core.parser").get_cell_at_cursor()
    if cur then cell_id = cur.id end
  end
  if not cell_id then
    print("FkNBDebug: no cell_id for message", vim.inspect(msg))
    return
  end

  local cell = state.cells[cell_id]
  if not cell then
    print("FkNBDebug: unknown cell", cell_id)
    return
  end

  -- normalize common shapes
  if t == "status" then
    -- ignore busy/idle (we handle via running spinner + exec_complete)
    return
  elseif t == "stream" then
    local text = (msg.content and msg.content.text) or ""
    -- keep “running” status while streaming
    cell.status = "running"
    cell.output = (cell.output or "") .. text
    ui.render_output(cell_id, cell.output, "running", cell.exec_time)
    return
  elseif t == "execute_result" or t == "display_data" then
    local content = msg.content or {}
    local text = content["text/plain"] or content.output or vim.inspect(content)
    cell.status = "ok"
    cell.output = text
    ui.render_output(cell_id, cell.output, "ok", cell.exec_time)
    return
  elseif t == "error" then
    local content = msg.content or {}
    local tb = table.concat(content.traceback or {}, "\n")
    cell.status = "error"
    cell.output = tb ~= "" and tb or (content.evalue or "Error")
    ui.render_output(cell_id, cell.output, "error", cell.exec_time)
    return
  elseif t == "execution_complete" then
    local et = (msg.content and msg.content.execution_time) or 0
    cell.exec_time = et * 1000 -- s -> ms (bridge sends seconds; standardize to ms)
    -- keep body as-is; only refresh header with time
    ui.render_output(cell_id, cell.output or "", cell.status or "ok", cell.exec_time)
    return
  end
end

-- stdout aggregator
local function on_stdout(_, data, _)
  if not data or not state.kernel then return end
  buffer = buffer .. table.concat(data, "\n")
  local lines = vim.split(buffer, "\n", { trimempty = false })
  if #lines == 0 then buffer = ""; return end

  -- process all but last (may be partial)
  for i = 1, #lines - 1 do
    local line = lines[i]
    if line ~= "" then
      local msg = safe_decode(line)
      if msg then
        if msg.status == "ready" then
          state.kernel.id = job_id
          print("FkNBDebug: Kernel ready.")
        else
          handle_msg(msg)
        end
      end
    end
  end
  buffer = lines[#lines] or ""
end

local function on_stderr(_, data, _)
  if data and #data > 0 then
    print("FkNBDebug: Kernel bridge error:", table.concat(data, "\n"))
    -- try to capture ack lines like: Executed code with msg_id: <id> [cell_id X]
    for _, line in ipairs(data) do
      local id = line:match("msg_id:%s*([%w%-_]+)")
      local cid = line:match("cell_id%s*(%d+)")
      if id and cid then
        msg_to_cell[id] = tonumber(cid)
      end
    end
  end
end

local function on_exit(_, code, _)
  print("FkNBDebug: Kernel exited code", code)
  state.kernel = nil
  job_id = nil
end

-- ensure deps
local function check_deps(python, cb)
  vim.fn.jobstart({ python, "-c", "import jupyter_client, ipykernel" }, {
    on_exit = function(_, code)
      if code == 0 then cb() else print("FkNBDebug: pip install jupyter_client ipykernel") end
    end
  })
end

function M.start()
  if job_id then print("FkNBDebug: Kernel already running."); return end
  local python = config.options.default_kernel or "python3"
  state.kernel = { name = python, running = true }

  local bridge = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h") .. "/bridge/kernel_bridge.py"
  check_deps(python, function()
    job_id = vim.fn.jobstart({ python, "-u", bridge }, {
      on_stdout = on_stdout,
      on_stderr = on_stderr,
      on_exit = on_exit,
      pty = false,
    })
    if job_id > 0 then
      print("FkNBDebug: Kernel bridge started with job_id", job_id)
    else
      print("FkNBDebug: Failed to start kernel bridge")
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
  end, 300)
end

-- ▶️ Execute current cells 
function M.execute(code)
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

  -- ✅ Filter out any “─” or decorative lines
  local clean_lines = {}
  for _, line in ipairs(cell.lines) do
    if not line:match("^─+$") and not line:match("^%s*#%%") then
      table.insert(clean_lines, line)
    end
  end

  -- ✅ Join clean code lines
  local cleaned_code = table.concat(clean_lines, "\n")
  cleaned_code = vim.trim(cleaned_code)

  if cleaned_code == "" then
    print("FkNBDebug: Cell is empty, nothing to run.")
    return
  end

  print("FkNBDebug: Executing clean code:\n" .. cleaned_code)

  -- ✅ Send to kernel
  local command = { action = "execute", code = cleaned_code }
  vim.fn.jobsend(job_id, vim.fn.json_encode(command) .. "\n")
  print("FkNBDebug: Code sent to kernel.")
end


return M
