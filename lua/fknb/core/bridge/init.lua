local M = {}
local client = require("fknb.core.bridge.client")
local state = require("fknb.utils.state")

-- Execute a code cell via Python kernel bridge
function M.exec(code, cell_id)
  -- Mark cell as running
  state.cells[cell_id] = state.cells[cell_id] or {}
  state.cells[cell_id].status = "running"
  state.current_cell = cell_id

  client.exec(code, cell_id)
end

-- Called by client.lua when kernel sends output
function M.on_output(cell_id, msg)
  state.cells[cell_id] = state.cells[cell_id] or {}

  if msg.output then
    state.cells[cell_id].output = msg.output
    state.cells[cell_id].status = "ready"
  end

  if msg.error then
    state.cells[cell_id].error = msg.error
    state.cells[cell_id].status = "error"
  end

  -- UI signal to refresh cell rendering
  vim.schedule(function()
    vim.api.nvim_exec_autocmds("User", { pattern = "FKNBUpdateUI" })
  end)
end

return M
