-- lua/fknb/commands.lua
-- Entry-point for all FKNB commands (run, restart, clear, etc.)
-- Keeps logic simple and decoupled from config keymaps.

local M = {}
local kernel = require("fknb.core.kernel")
local parser = require("fknb.core.parser")
local output = require("fknb.ui.output")

------------------------------------------------------------
-- 🧠 Core Notebook Commands
------------------------------------------------------------

-- ▶ Run current cell
function M.run_current_cell()
  local cell = parser.get_cell_at_cursor()
  if not cell then
    vim.notify("No FKNB cell under cursor", vim.log.levels.WARN)
    return
  end

  -- Combine lines into code string
  local code = table.concat(cell.lines, "\n")

  -- Save status
  cell.status = "running"
  cell.output = nil

  vim.notify("Running Cell #" .. cell.id, vim.log.levels.INFO)
  kernel.execute(code)
end

-- 🔁 Restart kernel (stop + start)
function M.restart_kernel()
  vim.notify("Restarting FKNB kernel...", vim.log.levels.INFO)
  kernel.stop()
  vim.defer_fn(function()
    kernel.start()
  end, 300)
end

-- ⏹ Stop kernel
function M.stop_kernel()
  vim.notify("Stopping FKNB kernel...", vim.log.levels.INFO)
  kernel.stop()
end

-- ▶ Start kernel
function M.start_kernel()
  vim.notify("Starting FKNB kernel...", vim.log.levels.INFO)
  kernel.start()
end

-- 🧹 Clear current cell output
function M.clear_output()
  local cell = parser.get_cell_at_cursor()
  if not cell then
    vim.notify("No FKNB cell under cursor", vim.log.levels.WARN)
    return
  end
  output.clear(cell.id)
  vim.notify("Cleared output for Cell #" .. cell.id, vim.log.levels.INFO)
end

-- 🧹 Clear all outputs in buffer
function M.clear_all_outputs()
  kernel.clear_all_outputs()
  vim.notify("Cleared all FKNB outputs", vim.log.levels.INFO)
end

-- 🔽 Toggle output collapse
function M.toggle_output()
  local cell = parser.get_cell_at_cursor()
  if not cell then
    vim.notify("No FKNB cell under cursor", vim.log.levels.WARN)
    return
  end
  output.toggle_collapse(cell.id)
end

vim.api.nvim_create_user_command("FknbHealth", function()
  require("fknb.utils.health").run()
end, { desc = "Run health diagnostics for FKNB.nvim" })



------------------------------------------------------------
-- 🎛 Helper Commands Registration
------------------------------------------------------------

-- Register user commands (optional, in case config didn’t do it)
vim.api.nvim_create_user_command("FknbRunCell", M.run_current_cell, { desc = "Run current FKNB cell" })
vim.api.nvim_create_user_command("FknbRestartKernel", M.restart_kernel, { desc = "Restart FKNB kernel" })
vim.api.nvim_create_user_command("FknbStartKernel", M.start_kernel, { desc = "Start FKNB kernel" })
vim.api.nvim_create_user_command("FknbStopKernel", M.stop_kernel, { desc = "Stop FKNB kernel" })
vim.api.nvim_create_user_command("FknbClearOutput", M.clear_output, { desc = "Clear current cell output" })
vim.api.nvim_create_user_command("FknbClearAllOutputs", M.clear_all_outputs, { desc = "Clear all cell outputs" })
vim.api.nvim_create_user_command("FknbToggleOutput", M.toggle_output, { desc = "Toggle output collapse for cell" })

------------------------------------------------------------
return M
