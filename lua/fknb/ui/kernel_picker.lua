local M = {}
local pickers = require('telescope.pickers')
local config = require("fknb.config")
local state = require("fknb.utils.state")
local kernel = require("fknb.core.kernel")

function M.show_kernel_picker(available_kernels)
  if #available_kernels == 0 then
    vim.notify("No kernels found.", vim.log.levels.WARN)
    return
  end

  local entries = {}
  for _, k in ipairs(available_kernels) do
    table.insert(entries, { value = k.name, display = k.display_name .. " (" .. k.language .. ")" })
  end

  pickers.new({}, {
    prompt_title = "Select Kernel",
    finder = require('telescope.finders').new_table({
      results = entries,
      entry_maker = function(entry)
        return { value = entry.value, display = entry.display, ordinal = entry.display }
      end,
    }),
    sorter = require('telescope.sorters').get_generic_fuzzy_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      local function on_confirm(bufnr)
        local selection = require('telescope.actions.state').get_selected_entry()
        if selection then
          local selected_kernel_name = selection.value
          config.options.default_kernel = selected_kernel_name
          state.last_selected_kernel = selected_kernel_name
          kernel.stop(function()
            kernel.start()
            vim.notify("Selected kernel: " .. selection.display, vim.log.levels.INFO)
          end)
        end
        require('telescope.actions').close(bufnr)
      end
      map("i", "<CR>", on_confirm)
      map("n", "<CR>", on_confirm)
      return true
    end,
  }):find()
end

return M