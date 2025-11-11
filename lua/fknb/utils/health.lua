-- lua/fknb/core/health.lua
-- 🩺 FKNB Health: health diagnostics and environment checks

local M = {}

local function line(msg, hl)
  hl = hl or "Normal"
  return { { msg, hl } }
end

function M.run()
  local results = {}
  table.insert(results, line("🩺  FKNB Doctor Report", "Title"))
  table.insert(results, line("───────────────────────────────", "Comment"))

  -- Neovim version check
  local v = vim.version()
  local nv_ok = (v.major > 0) or (v.major == 0 and v.minor >= 10)
  table.insert(results, line(string.format("Neovim: %d.%d.%d", v.major, v.minor, v.patch), nv_ok and "DiagnosticOk" or "DiagnosticError"))

  -- Treesitter parser check
  local ok_parser, parsers = pcall(require, "nvim-treesitter.parsers")
  local parser_ok = ok_parser and parsers.has_parser and parsers.has_parser("fknb")
  table.insert(results, line("Tree-sitter: " .. (parser_ok and "✅ fknb parser found" or "❌ missing parser"), parser_ok and "DiagnosticOk" or "DiagnosticError"))

  -- Python + kernel deps
  local python = require("fknb.config").options.default_kernel or "python3"
  local py_check = vim.fn.systemlist(python .. " -c 'import jupyter_client, ipykernel; print(\"OK\")'")
  local kernel_ok = (#py_check > 0 and py_check[1]:match("OK")) ~= nil
  table.insert(results, line("Python Kernel: " .. (kernel_ok and "✅ available" or "❌ missing jupyter_client/ipykernel"), kernel_ok and "DiagnosticOk" or "DiagnosticError"))

  -- Bridge path
  local bridge = vim.fn.stdpath("config") .. "/lua/fknb/core/bridge/kernel_bridge.py"
  local bridge_exists = vim.fn.filereadable(bridge) == 1
  table.insert(results, line("Kernel Bridge: " .. (bridge_exists and "✅ found" or "❌ missing"), bridge_exists and "DiagnosticOk" or "DiagnosticError"))

  -- Plugin load path
  local plug_path = debug.getinfo(1, "S").source:sub(2)
  table.insert(results, line("Plugin Path: " .. plug_path, "Comment"))

  table.insert(results, line("───────────────────────────────", "Comment"))
  table.insert(results, line("Tip: Run :FknbRestart if kernel misbehaves", "Comment"))
  table.insert(results, line(" "))

  -- Show as floating window
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = vim.tbl_map(function(seg)
    return table.concat(vim.tbl_map(function(x) return x[1] end, seg))
  end, results)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = math.floor(vim.o.columns * 0.5)
  local height = #lines + 2
  local row = math.floor((vim.o.lines - height) / 3)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
    style = "minimal",
  })

  vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

return M
