-- lua/fknb/ui/kernel_picker.lua
-- Kernel picker UI for FKNB.nvim
-- Supports Telescope (if available) or vim.ui.select fallback.

local M = {}
local state = require("fknb.utils.state")
local kernel = require("fknb.core.kernel")

-- 🧠 Internal helper to actually start the selected kernel
local function select_and_start(selected_kernel)
  if not selected_kernel then
    vim.notify("No kernel selected.", vim.log.levels.WARN)
    return
  end

  local already_running = kernel.is_running and kernel.is_running()

  -- Stop current kernel if one is active
  if already_running then
    vim.notify("Restarting kernel: " .. selected_kernel.name, vim.log.levels.INFO)
    kernel.stop()
  end

  state.selected_kernel = selected_kernel
  state.last_selected_kernel = selected_kernel.name
  vim.defer_fn(function()
    kernel.start("python3", selected_kernel.name)
    vim.notify("Kernel started: " .. selected_kernel.display_name, vim.log.levels.INFO)
  end, already_running and 250 or 0)
end

-- 🧭 Fallback using vim.ui.select
local function fallback_picker(kernels)
  local entries = {}
  for _, k in ipairs(kernels) do
    table.insert(entries, string.format("%s (%s)", k.display_name, k.name))
  end

  vim.schedule(function()
    vim.ui.select(entries, { prompt = "Select Kernel:" }, function(choice)
      if not choice then return end
      local selected = choice:match("%((.-)%)")
      for _, k in ipairs(kernels) do
        if k.name == selected then
          select_and_start(k)
          return
        end
      end
    end)
  end)
end

-- 🚀 Telescope-based picker
local function telescope_picker(kernels)
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    fallback_picker(kernels)
    return
  end

  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  vim.schedule(function()
    pickers
      .new({}, {
        prompt_title = "Select Kernel",
        finder = finders.new_table({
          results = vim.tbl_map(function(k)
            return string.format("%s (%s)", k.display_name, k.name)
          end, kernels),
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(_, map)
          map("i", "<CR>", function(bufnr)
            local selection = action_state.get_selected_entry()
            actions.close(bufnr)
            if not selection then return end
            local selected = selection.value:match("%((.-)%)")
            for _, k in ipairs(kernels) do
              if k.name == selected then
                select_and_start(k)
                return
              end
            end
          end)
          return true
        end,
      })
      :find()
  end)
end

-- 🔧 Public function
function M.show_kernel_picker(kernels)
  if not kernels or #kernels == 0 then
    vim.notify("No kernels available.", vim.log.levels.WARN)
    return
  end

  -- Prefer Telescope if available, else fallback
  local ok = pcall(require, "telescope")
  if ok then
    telescope_picker(kernels)
  else
    fallback_picker(kernels)
  end
end

return M
