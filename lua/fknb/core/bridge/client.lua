local M = {}

local handle
local stdin
local stdout

function M.start()
  if handle then return end

  handle = vim.loop.spawn(
    "python3",
    {
      args = { vim.fn.stdpath("config") .. "/fknb/core/bridge/python/kernel.py" }, 
      stdio = {stdin, stdout},
    },
    function() handle = nil end
  )

  stdin = assert(vim.loop.new_pipe(false))
  stdout = assert(vim.loop.new_pipe(false))

  stdout:read_start(function(err, data)
    if data then
      local ok, msg = pcall(vim.json.decode, data)
      if ok then vim.api.nvim_exec_autocmds("User", { pattern = "FKNBKernelOut", data = msg }) end
    end
  end)
end

function M.exec(code)
  M.start()
  stdin:write(vim.json.encode({ code = code }) .. "\n")
end

return M
