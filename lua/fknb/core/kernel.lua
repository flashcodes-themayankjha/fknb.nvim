local M = {}
local config = require("fknb.config")
local state = require("fknb.utils.state")
local renderer = require("fknb.core.renderer")

local job_id = nil

-- Forward declaration
local check_dependencies

local buffer = ""
local function on_stdout(id, data, event)
  if not data or not state.kernel then return end

  buffer = buffer .. table.concat(data, "\n")
  local lines = vim.split(buffer, "\n")

  -- Keep the last, possibly incomplete, line in the buffer
  buffer = #lines > 0 and lines[#lines] or ""
  if #lines > 1 then
    table.remove(lines)
  end

  for _, line in ipairs(lines) do
    if line ~= "" then
      local ok, result = pcall(vim.fn.json_decode, line)
      if ok then
        if result.status == "ready" then
          state.kernel.id = id
          state.kernel.connection_file = result.connection_file
          vim.notify("Kernel is ready.", vim.log.levels.INFO)
        else
          renderer.render_output(result)
        end
      else
        vim.notify("Error decoding JSON from kernel bridge: " .. line, vim.log.levels.ERROR)
      end
    end
  end
end

local function on_stderr(id, data, event)
  if data then
    vim.notify("Kernel bridge error: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
  end
end

local function on_exit(id, code, event)
  state.kernel = nil
  job_id = nil
  vim.notify("Kernel has exited.", vim.log.levels.WARN)
end

check_dependencies = function(python_cmd, callback)
  vim.notify("Using python command: " .. python_cmd)
  local check_cmd = {python_cmd, "-c", "import jupyter_client, ipykernel"}
  vim.fn.jobstart(check_cmd, {
    on_exit = function(_, code, __) 
      if code == 0 then
        callback()
      else
        vim.notify(
          "Missing Python dependencies. Please run: pip install jupyter_client ipykernel",
          vim.log.levels.ERROR,
          { title = "FkNb" }
        )
      end
    end
  })
end

function M.start()
  if job_id then
    vim.notify("Kernel is already running.", vim.log.levels.WARN)
    return
  end

  local python_cmd = config.options.default_kernel
  state.kernel = { name = python_cmd } -- Set kernel name in state

  check_dependencies(python_cmd, function()
    local bridge_path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h") .. "/bridge/kernel_bridge.py"
    job_id = vim.fn.jobstart({python_cmd, "-u", bridge_path}, {
      on_stdout = on_stdout,
      on_stderr = on_stderr,
      on_exit = on_exit,
      pty = false,
      rpc = false,
    })

    if job_id <= 0 then
      job_id = nil
      vim.notify("Failed to start kernel bridge.", vim.log.levels.ERROR)
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
  end, 1000)
end

function M.execute(code)
  if not job_id or not state.kernel then
    vim.notify("Kernel is not running. Start one first.", vim.log.levels.ERROR)
    return
  end
  local command = { action = "execute", code = code }
  vim.fn.jobsend(job_id, vim.fn.json_encode(command) .. "\n")
end

return M

