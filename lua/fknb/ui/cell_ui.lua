local M = {}

local ns = vim.api.nvim_create_namespace("fknb_cells")

-- Spinner frames (VSCode style)
local spinner_frames = { "●", "◐", "◓", "◑" }
local spinner_index = 1

local icons = {
  kernels = {
    python = "",
    markdown = "",
    javascript = "",
    lua = "",
    r = "",
    default = "",
  },
  env = {
    active = "",
    inactive = "󱋙",
  },
  status = {
    ready = "",
    running = spinner_frames[1],
    done = "󰗠",
    error = "",
    retry = "󰜉",
  },
  actions = {
    run = "▶",
    retry = "󰜉",
    debug = "",
  },
}

local state = require("fknb.utils.state")

local function get_status(cell)
  return cell.status or "ready"
end

local function setup_highlights()
  vim.api.nvim_set_hl(0, "FknbStatusDone", { fg = "green" })
  vim.api.nvim_set_hl(0, "FknbStatusError", { fg = "red" })
  vim.api.nvim_set_hl(0, "FknbStatusReady", { fg = "gray" })
  vim.api.nvim_set_hl(0, "FknbStatusRunning", { fg = "yellow" })
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
        or icons.status[status_key]

    local status_hl_group = "Normal"
    if status_key == "done" then
      status_hl_group = "FknbStatusDone"
    elseif status_key == "error" then
      status_hl_group = "FknbStatusError"
    elseif status_key == "ready" then
      status_hl_group = "FknbStatusReady"
    elseif status_key == "running" then
      status_hl_group = "FknbStatusRunning"
    end

    local cell_label = { "Cell", "WarningMsg" }  -- Yellow
    local id_label = { "#" .. cell.id, "DiagnosticInfo" } -- Blue

    -- Right side text icons
    local right_text = string.format(
      "%s %s  %s  %s %s %s",
      icons.kernels[cell.lang] or icons.kernels.default,
      cell.lang,
      icons.env.active,
      icons.actions.run,
      icons.actions.retry,
      icons.actions.debug
    )

    local visible_left = #status_icon + 2 + #"Cell" + 1 + #tostring(cell.id) + 1
    local visible_right = vim.fn.strdisplaywidth(right_text)
    local spacing = width - visible_left - visible_right
    if spacing < 1 then spacing = 1 end

    -- Separator lines
    local sep = string.rep("─", width)

    local virt = {
      { { sep, "Comment" } }, -- top line
      {
        { " " .. status_icon .. "  ", status_hl_group },
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
