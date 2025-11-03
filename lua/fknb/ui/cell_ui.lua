local M = {}

local ns = vim.api.nvim_create_namespace("fknb_cells")
local config = require("fknb.config")
local state = require("fknb.utils.state")

local spinner_frames = config.options.ui.spinner_frames
local spinner_index = 1

-- highlight passthrough helper (keeps your design intent)
local function hl(name) return name end

local function get_status(cell)
  return cell.status or "ready"
end

-- ✅ measure display width (icons/emojis count as 2 cells sometimes)
local function seg_width(segments)
  local text = table.concat(vim.tbl_map(function(s) return s[1] end, segments))
  return vim.fn.strdisplaywidth(text)
end

local function draw(buf)
  state.prev_cells = state.cells
  require("fknb.core.parser").parse(buf)

  local win = vim.api.nvim_get_current_win()
  local width = vim.api.nvim_win_get_width(win)

  local to_add, to_remove, to_update = {}, {}, {}

  for id, cell in pairs(state.cells) do
    local prev = state.prev_cells[id]
    if not prev then
      table.insert(to_add, cell)
    elseif cell.status ~= prev.status or cell.output ~= prev.output then
      table.insert(to_update, cell)
    end
  end

  for id in pairs(state.prev_cells) do
    if not state.cells[id] then table.insert(to_remove, id) end
  end

  for _, id in ipairs(to_remove) do
    local c = state.prev_cells[id]
    vim.api.nvim_buf_clear_namespace(buf, ns, c.range[1], c.range[3] + 1)
  end

  for _, cell in ipairs(to_add) do
    local status = get_status(cell)
    local running = state.kernel and state.kernel.running

    local icon = running
      and (status == "running" and spinner_frames[spinner_index]
          or config.options.icons.status[status])
      or config.options.icons.status.not_ready

    local status_hl = status == "not_ready"
      and "FknbStatusNotReady"
      or ("FknbStatus"..status:sub(1,1):upper()..status:sub(2))

    local cell_label = { config.options.ui.cell_label_text, config.options.ui.cell_label_hl }
    local id_label   = { "#" .. cell.id, config.options.ui.id_label_hl }

    local kernel_icon = running and config.options.icons.env.active or config.options.icons.env.inactive
    local kernel_hl   = running and hl("FknbStatusActive") or hl("FknbStatusInactive")

    local actions = {}
    if status == "ready" or status == "done" then
      actions = {
        { config.options.icons.actions.run,   hl("FknbActionRunReady") },
      }
    elseif status == "running" then
      actions = {
        { config.options.icons.actions.run,   hl("FknbActionRunReady") },
        { " ", "Normal" },
        { config.options.icons.actions.retry, hl("FknbActionRetry") },
      }
    elseif status == "error" then
      actions = {
        { config.options.icons.actions.run,   hl("FknbActionRunError") },
        { " ", "Normal" },
        { config.options.icons.actions.retry, hl("FknbActionRetry") },
        { " ", "Normal" },
        { config.options.icons.actions.debug, hl("FknbActionDebug") },
      }
    end

    local right = {
      { config.options.icons.kernels[cell.lang or "default"] or config.options.icons.kernels.default, "Comment" },
      { " ", "Normal" },
      { cell.lang or "unknown", "Comment" },
      { "  ", "Normal" },
      { kernel_icon, kernel_hl },
      { "  ", "Normal" },
    }
    vim.list_extend(right, actions)

    -- ✅ compute widths correctly
    local left_text = " "..icon.."  "..config.options.ui.cell_label_text.." #" .. cell.id
    local left_len = vim.fn.strdisplaywidth(left_text)
    local right_len = seg_width(right)

    local spacing = width - left_len - right_len - 1
    if spacing < 1 then spacing = 1 end

    -- ✅ dynamic full separator line
    local sep = string.rep(config.options.cell_separator, width)

    local virt = {
      { { sep, "Comment" } },
      {
        { " "..icon.."  ", status_hl },
        cell_label, { " ", "Normal" },
        id_label,   { string.rep(" ", spacing), "Normal" },
      },
      { { sep, "Comment" } },
    }

    vim.list_extend(virt[2], right)

    vim.api.nvim_buf_set_extmark(buf, ns, cell.range[1], 0, {
      virt_lines = virt,
      virt_lines_above = true,
      priority = 200,
    })

    require("fknb.core.renderer").render_cell(buf, cell)
  end

  for _, cell in ipairs(to_update) do
    require("fknb.core.renderer").render_cell(buf, cell)
  end
end

function M.attach_autocmd()
  local function safe_redraw(buf)
    if vim.api.nvim_buf_is_valid(buf)
       and vim.bo[buf].filetype == "fknb"
    then draw(buf) end
  end

  vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
    pattern = "*.fknb",
    callback = function(e) safe_redraw(e.buf) end,
  })

  -- ✅ dynamic live resize
  vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
    callback = function()
      safe_redraw(vim.api.nvim_get_current_buf())
    end
  })

  draw(vim.api.nvim_get_current_buf())

  local timer = vim.loop.new_timer()
  timer:start(0, 150, vim.schedule_wrap(function()
    spinner_index = (spinner_index % #spinner_frames) + 1
    safe_redraw(vim.api.nvim_get_current_buf())
  end))
end

return M
