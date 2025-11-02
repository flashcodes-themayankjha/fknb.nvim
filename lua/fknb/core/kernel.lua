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
        if result.event == "kernel_started" then
          vim.notify("Kernel bridge started.", vim.log.levels.INFO)
        elseif result.event == "kernels_list" then
          state.available_kernels = result.kernels
        elseif result.event == "cell_update" then
          local cell = state.cells[result.cell_id]
          if cell then
            cell.status = result.status
            cell.output = result.output
          end
        elseif result.event == "error" then
          vim.notify("Kernel bridge error: " .. result.message .. "\n" .. result.traceback, vim.log.levels.ERROR)
        else
          vim.notify("Unhandled kernel output: " .. vim.inspect(result), vim.log.levels.WARN)
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
  local kernel_name = config.options.default_kernel

  if config.options.default_kernel_path then
    python_cmd = config.options.default_kernel_path
  end
  if config.options.default_kernel_name then
    kernel_name = config.options.default_kernel_name
  end

  state.kernel = { name = kernel_name } -- Set kernel name in state

  vim.notify("Launching kernel bridge with python_cmd: " .. python_cmd .. " and kernel_name: " .. kernel_name, vim.log.levels.INFO)

  check_dependencies(python_cmd, function()
    local bridge_path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h") .. "/bridge/python/kernel.py"
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
  -- Give the bridge a moment to shut down gracefully
  vim.defer_fn(function()
    if job_id and vim.fn.jobpid(job_id) ~= -1 then -- Check if job is still running
      vim.fn.jobstop(job_id)
    end
    job_id = nil
    state.kernel = nil
  end, 1000)
end

function M.execute(cell_id, code)
  if not job_id or not state.kernel then
    vim.notify("Kernel is not running. Start one first.", vim.log.levels.ERROR)
    return
  end
  local command = { action = "execute", cell_id = cell_id, code = code }
  vim.fn.jobsend(job_id, vim.fn.json_encode(command) .. "\n")
end

function M.list_kernels(callback)
  if not job_id then
    vim.notify("Kernel bridge is not running. Start one first.", vim.log.levels.ERROR)
    return
  end
  state.available_kernels = nil -- Clear previous list
  vim.fn.jobsend(job_id, vim.fn.json_encode({ action = "list_kernels" }) .. "\n")
  -- Wait for the response to be processed by on_stdout
  local timer = vim.loop.new_timer()
  timer:start(0, 100, vim.schedule_wrap(function()
    if state.available_kernels then
      timer:stop()
      callback(state.available_kernels)
    end
  end))
end

return M