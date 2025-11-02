local M = {}

local telescope = require("telescope.builtin")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values

local kernel = require("fknb.core.kernel")
local config = require("fknb.config")

function M.show()
  local python_cmd = config.options.default_kernel
  local cmd = {python_cmd, "-m", "jupyter", "kernelspec", "list", "--json"}
  
  vim.notify("Running command: " .. table.concat(cmd, " "))

  local stdout_chunks = {}
  local stderr_chunks = {}

  vim.fn.jobstart(cmd, {
    on_stdout = function(_, data) 
      if data then
        table.insert(stdout_chunks, table.concat(data, "\n"))
      end
    end,
    on_stderr = function(_, data) 
      if data then
        table.insert(stderr_chunks, table.concat(data, "\n"))
      end
    end,
    on_exit = function(_, code, _) 
      if code ~= 0 then
        vim.notify("Failed to get kernel list. Exit code: " .. code .. "\n" .. table.concat(stderr_chunks, "\n"), vim.log.levels.ERROR)
        return
      end

      local kernels_json = table.concat(stdout_chunks, "")
      local ok, kernels_data = pcall(vim.fn.json_decode, kernels_json)

      if not ok or not kernels_data or not kernels_data.kernelspecs then
        vim.notify("Failed to parse Jupyter kernel list. Raw output:\n" .. kernels_json, vim.log.levels.ERROR)
        return
      end

      local kernels = kernels_data.kernelspecs
      local results = {}
      for name, spec in pairs(kernels) do
        table.insert(results, {
          name = name,
          display_name = spec.spec.display_name,
          language = spec.spec.language,
        })
      end

      pickers.new({}, {
        prompt_title = "Select a Kernel",
        finder = finders.new_table {
          results = results,
          entry_maker = function(entry)
            return {
              value = entry,
              display = entry.display_name,
              ordinal = entry.display_name,
            }
          end,
        },
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = require("telescope.actions.state").get_selected_entry()
            kernel.start(selection.value.name)
          end)
          return true
        end,
      }):find()
    end,
  })
end

return M
