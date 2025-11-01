local M = {}

local M = {}

function M.get_display_name(path)
  local name = path
  -- Try to create a friendlier name
  local env_name = name:match(".*/%.virtualenvs/([^/]+)/bin/python.?")
  if env_name then
    name = "py: " .. env_name
  else
    env_name = name:match(".*/(%.venv)/bin/python.?")
    if env_name then
      name = "py: .venv"
    else
      name = vim.fn.fnamemodify(name, ":t")
    end
  end
  return name
end

function M.find_kernels()
  local kernels = {}
  local checked = {}

  local function add_kernel(path)
    local real_path = vim.fn.resolve(path)
    if not checked[real_path] and vim.fn.executable(real_path) == 1 then
      table.insert(kernels, { path = real_path, name = M.get_display_name(real_path) })
      checked[real_path] = true
    end
  end

  -- Add python from path
  local python3 = vim.fn.exepath("python3")
  if python3 ~= "" then
    add_kernel(python3)
  end
  local python = vim.fn.exepath("python")
  if python ~= "" then
    add_kernel(python)
  end

  -- Scan common virtualenv paths
  local home = os.getenv("HOME")
  local venv_paths = vim.fn.glob(home .. "/.virtualenvs/*/bin/python", true, true)
  for _, path in ipairs(venv_paths) do
    add_kernel(path)
  end

  return kernels
end

return M
