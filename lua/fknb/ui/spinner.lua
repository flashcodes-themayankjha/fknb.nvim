local Spinner = {}

local frames = { "●", "◐", "◓", "◑" }

Spinner.active = {} -- { [buf][cell_id] = { timer, index, mark_id } }

function Spinner.start(buf, cell_id, mark_id, update)
  Spinner.active[buf] = Spinner.active[buf] or {}
  local st = Spinner.active[buf][cell_id]

  if st and st.timer then return end

  local idx = 1
  local timer = vim.loop.new_timer()
  timer:start(0, 120, vim.schedule_wrap(function()
    local frame = frames[idx]
    idx = (idx % #frames) + 1

    update(frame) -- callback that updates extmark virt_text

  end))

  Spinner.active[buf][cell_id] = {
    timer = timer,
    mark_id = mark_id,
  }
end

function Spinner.stop(buf, cell_id)
  if not Spinner.active[buf] or not Spinner.active[buf][cell_id] then return end

  local st = Spinner.active[buf][cell_id]
  if st.timer then st.timer:stop() end
  Spinner.active[buf][cell_id] = nil
end

return Spinner
