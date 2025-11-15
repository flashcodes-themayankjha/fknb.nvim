local M = {}
local state = require("fknb.utils.state")

function M.serialize_cells()
  local lines = {}
  if not state.cells then
    return ""
  end
  for _, cell in ipairs(state.cells) do
    if cell.type == "markdown" then
      table.insert(lines, "#%")
    elseif cell.type == "code" then
      if cell.lang and cell.lang ~= "" then
        table.insert(lines, "#%% ")
      else
        table.insert(lines, "#%%")
      end
    end

    for _, line in ipairs(cell.lines) do
      table.insert(lines, line)
    end
    table.insert(lines, "") -- Add a newline between cells
  end
  return table.concat(lines, "\n")
end

return M
