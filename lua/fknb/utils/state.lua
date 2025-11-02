-- lua/fknb/utils/state.lua

local M = {
  kernel = {
    name = nil,
    connection_file = nil,
    session_id = nil,
    pid = nil,

    transport = nil, -- tcp/zmq
    ports = {
      hb = nil,
      control = nil,
      shell = nil,
      stdin = nil,
      iopub = nil,
    },

    running = false,
  },

  cells = {},
  prev_cells = {},

  --- Active / last executed cell
  current_cell = nil,

  --- Kernel message queues
  messages = {
    shell = {},
    iopub = {},
    stdin = {},
  },

  --- Execution counters
  exec_count = 0,
}

return M
