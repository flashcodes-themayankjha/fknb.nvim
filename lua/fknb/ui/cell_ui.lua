local M = {}

local ns = vim.api.nvim_create_namespace("fknb_cells")
local config = require("fknb.config")
local state = require("fknb.utils.state")

local spinner_frames = config.options.ui.spinner_frames
local spinner_index = 1

local function get_status(cell)
  return cell.status or "ready"
end

local function setup_highlights()
  for hl_group, opts in pairs(config.options.ui.highlights) do
    vim.api.nvim_set_hl(0, hl_group, opts)
  end
end

local function draw(buf)
  state.prev_cells = state.cells
  require("fknb.core.parser").parse(buf)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local win = vim.api.nvim_get_current_win()
  local width = vim.api.nvim_win_get_width(win)

  -- Diffing logic
  local to_add = {}
  local to_remove = {}
  local to_update = {}

  for id, cell in pairs(state.cells) do
    if not state.prev_cells[id] then
      table.insert(to_add, cell)
    else
      local prev_cell = state.prev_cells[id]
      if cell.status ~= prev_cell.status or cell.output ~= prev_cell.output then
        table.insert(to_update, cell)
      end
    end
  end

  for id, _ in pairs(state.prev_cells) do
    if not state.cells[id] then
      table.insert(to_remove, id)
    end
  end

  -- Remove old cells
  for _, id in ipairs(to_remove) do
    local cell = state.prev_cells[id]
    vim.api.nvim_buf_clear_namespace(buf, ns, cell.range[1], cell.range[3] + 1)
  end

  -- Add new cells
  for _, cell in ipairs(to_add) do
    local status_key = get_status(cell)
    local status_icon = (status_key == "running")
        and spinner_frames[spinner_index]
        or config.options.icons.status[status_key]

    local status_hl_group_name = "FknbStatus" .. status_key:sub(1,1):upper() .. status_key:sub(2)

    local cell_label = { config.options.ui.cell_label_text, config.options.ui.cell_label_hl }
    local id_label = { "#" .. cell.id, config.options.ui.id_label_hl }

    -- Right side text icons
    local right_text = string.format(
      "%s %s  %s  %s %s %s",
      config.options.icons.kernels[cell.lang] or config.options.icons.kernels.default,
      cell.lang,
      config.options.icons.env.active,
      config.options.icons.actions.run,
      config.options.icons.actions.retry,
      config.options.icons.actions.debug
    )

    local visible_left = #status_icon + 2 + #config.options.ui.cell_label_text + 1 + #tostring(cell.id) + 1
    local visible_right = vim.fn.strdisplaywidth(right_text)
    local spacing = width - visible_left - visible_right
    if spacing < 1 then spacing = 1 end

    -- Separator lines
    local sep = string.rep(config.options.cell_separator, width)

    local virt = {
      { { sep, "Comment" } }, -- top line
      {
        { " " .. status_icon .. "  ", status_hl_group_name }, -- Use the name here
        cell_label, { " ", "Normal" },
        id_label, { string.rep(" ", spacing), "Normal" },
        { right_text, "Comment" }
      },
      { { sep, "Comment" } }, -- bottom line
    }

    vim.api.nvim_buf_set_extmark(buf, ns, cell.range[1], 0, {
      virt_lines = virt,
      virt_lines_above = true,
      priority = 200,
    })

    require("fknb.core.renderer").render_cell(buf, cell)
  end

  -- Update existing cells
  for _, cell in ipairs(to_update) do
    require("fknb.core.renderer").render_cell(buf, cell)
  end
end

function M.attach_autocmd()
  setup_highlights()
  vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
    pattern = "*.fknb",
    callback = function(e) draw(e.buf) end,
  })

  -- Initial draw
  draw(vim.api.nvim_get_current_buf())

  -- Timer tick for spinner
  local timer = vim.loop.new_timer()
  timer:start(0, 150, vim.schedule_wrap(function()
    spinner_index = (spinner_index % #spinner_frames) + 1
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].filetype == "fknb" then
      draw(buf)
    end
  end))
end

return M