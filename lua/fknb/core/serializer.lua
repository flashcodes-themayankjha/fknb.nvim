local M = {}
local state = require("fknb.utils.state")

function M.serialize_cells()
  local lines = {}
  for _, cell in ipairs(state.cells) do
    if cell.type == "code" then
      table.insert(lines, "#%%" .. (cell.lang and " " .. cell.lang or ""))
      for _, line in ipairs(cell.lines) do
        table.insert(lines, line)
      end
    elseif cell.type == "markdown" then
      table.insert(lines, "#%")
      for _, line in ipairs(cell.lines) do
        table.insert(lines, line)
      end
    end
  end
  return table.concat(lines, "\n")
end

return M
