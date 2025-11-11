
<div align="center">

# 🧠 fknb.nvim — Notebook Cells in Neovim
**Modern interactive notebook experience in Neovim, inspired by Jupyter but built for developers who love Vim.**
**Run code blocks, render execution controls inline, and work like a scientist without leaving Neovim.**


<a href="https://github.com/TheFlashCodes/FKvim">
  <img src="https://img.shields.io/badge/FkVim-Ecosystem-blueviolet.svg?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZD0iTTkuODYgMy41bDIuNjcgMy43NEwxNC40OCAzLjVoMy41MkwxMiAxMy4yOCAzLjk4IDMuNWg5Ljg4ek0xMiAxNS4wNGwtMy44NyA1LjQ2aDcuNzVsLTMuODgtNS40NnoiIGZpbGw9IiNmZmYiLz48L3N2Zz4=" alt="FkVim Ecosystem"/>
</a> 
<p align="center">
  <img src="https://img.shields.io/badge/Made%20with-Lua-blue.svg?style=for-the-badge&logo=lua" />
  <img src="https://img.shields.io/badge/Powered%20by-Neovim-green.svg?style=for-the-badge&logo=neovim" />
  <a href="https://github.com/flashcodes-themayankjha/Fknotes.nvim/stargazers"><img src="https://img.shields.io/github/stars/flashcodes-themayankjha/fknb.nvim?style=for-the-badge" /></a>
  <a href="https://github.com/flashcodes-themayankjha/Fknotes.nvim/blob/main/LICENSE"><img src="https://img.shields.io/github/license/flashcodes-themayankjha/fknb.nvim?style=for-the-badge" /></a>
</p>

</div>


> ⚠️ Work-in-progress — highly experimental

<img width="1709" height="1062" alt="image" src="https://github.com/user-attachments/assets/c626627f-216f-4739-be51-0cc8a08e8ce3" />


## ✨ Features (Current)

| Feature                                | Status |
| -------------------------------------- | :----: |
| Cell detection (`#%%`)                  |   ✅   |
| Clean notebook-style UI                |   ✅   |
| Dynamic separators per cell            |   ✅   |
| Kernel icons (Python/Lua/JS/R/Markdown) |   ✅   |
| Animated status spinner                |   ✅   |
| Cell ID + labels with syntax colors    |   ✅   |
| Execution icons (▶ ↻ 🐞)               |   ✅   |
| Does not override your code            |   ✅   |




## 🎨 UI Showcase

A cell looks like this:

<img width="1428" height="287" alt="image" src="https://github.com/user-attachments/assets/78e79895-94ae-499f-a543-9fe92038e1b9" />


- Highlighted “Cell” in Yellow
- Cell ID in Blue (#1, #2, etc.)
- Animated execution spinners. 
- Kernel icon + language + env icon
- Action icons: run/retry/debug

Markdown cells stay readable.
Code stays editable.
Delimiters remain hidden.


## 🚀 Usage

Mark cells with:

```python
#%% --> codecell Delimiter
print("Hello World")
```

Or in Markdown:

```markdown
#%  --> Markdown Delimiter
# This is a markdown cell
```

Cells automatically render with UI if the file ends with `.fknb`.


## 📁 File Type

Create a notebook file:

```bash
nvim my_notebook.fknb
```


### ⚙️ Under the Hood

FKNB uses:
- Virtual lines
- Extmarks
- Custom status spinner
- No overwriting buffer text
- Kernel icon mapping
- Language recognition from cell header


## 🧩 Roadmap

### ✅ Done
- Basic cell UI & separators
- Spinner + status icons
- Hide cell markers
- No-overlap UI rendering
- Execute Python/Lua cells
- Output panel render

### 🔜 Coming Next

| Feature                      | Priority |
| ---------------------------- | :------: |
| Persistent execution state   |   ⭐⭐⭐    |
| Async execution queue        |   ⭐⭐⭐    |
| Toolbar keybinds             |    ⭐⭐    |
| Theme support (Catppuccin/Gruvbox) |    ⭐⭐    |



## 📦 Install (WIP)

### using lazy.nvim 

```lua
{
  "https://github.com/flashcodes-themayankjha/fknb.nvim",    
  config = function()
    require("fknb").setup()
  end
}
```

## 📦 Configuration

```lua
require("fknb").setup({
default_kernel = "python3",
  default_kernel_path = nil,
  cell_separator = "─",
  auto_save = false,

  ui = {
    spinner_frames = { "󰪞", "󰪟", "󰪠", "󰪡", "󰪢", "󰪣", "󰪤", "󰪥" },
    highlights = {
      FknbStatusDone       = { fg = "green" },
      FknbStatusError      = { fg = "red" },
      FknbStatusReady      = { fg = "white" },
      FknbStatusRunning    = { fg = "yellow" },
      FknbStatusRetry      = { fg = "yellow" },
      FknbStatusActive     = { fg = "green" },
      FknbStatusInactive   = { fg = "red" },
      FknbStatusNotReady   = { fg = "red" },
      FknbActionRunReady   = { fg = "green" },
      FknbActionRunError   = { fg = "red" },
      FknbActionDebug      = { fg = "red" },
      FknbActionRetry      = { fg = "yellow" },
    },
    cell_label_text = "Cell",
    cell_label_hl = "WarningMsg",
    id_label_hl = "DiagnosticInfo",
  },

  output = {
    icons = {
      ok    = "󰗠",
      error = "",
      info  = "󰜉",
    },
    highlights = {
      sep         = "Comment",
      icon_ok     = "DiffAdded",
      icon_err    = "DiagnosticError",
      icon_info   = "DiagnosticWarn",

      out_label   = "Normal",
      out_id      = "DiagnosticInfo",
      exec_lbl    = "Comment",
      exec_time   = "DiagnosticWarn",
      log_lbl     = "DiagnosticError",

      out_text    = "Normal",
      err_text    = "Normal",
    },
    indent_string = "  ",
  },

  icons = {
    kernels = {
      python = "",
      markdown = "",
      default = "",
    },
    env = {
      active   = "",
      inactive = "󱋙",
    },
    status = {
      ready     = "",
      running   = "",
      retry     = "󱍷",
      error     = "󰗖",
      not_ready = "󱃓",
    },
    actions = {
      run   = "▶",
      retry = "󰜉",
      debug = "",
    },
  },

  -- ⚙️ New: Keybindings (users can override)
  keymaps = {
    run_cell        = "<leader>kr",
    restart_kernel  = "<leader>kk",
    stop_kernel     = "<leader>ks",
    start_kernel    = "<leader>kS",
    clear_output    = "<leader>kc",
    clear_all       = "<leader>kC",
    toggle_output   = "<leader>kt",
  },
})
```

## 💡 Philosophy

Bring interactive computing to Neovim
without killing the Vim workflow.

- No notebook lag
- No ugly borders
- Seamless editing experience
- Beautiful, minimalist inline UI



## 🧑‍💻 Author

Developed  by Mayank Kumar Jha from nfks
Project vision: Modern Neovim notebooks + gamified dev UX



🌟 Support / Contribute

This is an early stage tool — feedback & PRs welcome!

Star ⭐ the repo if you love Neovim science ❤️
