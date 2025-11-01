⸻

🧠 FKNB — Notebook Cells in Neovim

Modern interactive notebook experience in Neovim, inspired by Jupyter but built for developers who love Vim.

Run code blocks, render execution controls inline, and work like a scientist without leaving Neovim.

⚠️ Work-in-progress — highly experimental



✨ Features (Current)

| Feature                                | Status |
| -------------------------------------- | :----: |
| Cell detection (`#%%`)                  |   ✅   |
| Clean notebook-style UI                |   ✅   |
| Dynamic separators per cell            |   ✅   |
| Kernel icons (Python/Lua/JS/R/Markdown) |   ✅   |
| Animated status spinner                |   ✅   |
| Cell ID + labels with syntax colors    |   ✅   |
| Execution icons (▶ ↻ 🐞)               |   ✅   |
| Hidden cell delimiter (`#%%`)           |   ✅   |
| Does not override your code            |   ✅   |




🎨 UI Showcase

A cell looks like this:

────────────────────────────────────────
 ● Cell #1                        python    ▶ ↻ 🐞
────────────────────────────────────────
print("Hello, FKNB!")

•Highlighted “Cell” in Yellow
•Cell ID in Blue (#1, #2, etc.)
•Animated execution dots (● ◐ ◓ ◑)
•Kernel icon + language + env icon
•Action icons: run/retry/debug

Markdown cells stay readable.
Code stays editable.
Delimiters remain hidden.

⸻

🚀 Usage

Mark cells with:

```python
#%%
print("Hello World")
```

Or in Markdown:

```markdown
#%%
# This is a markdown cell
```

Cells automatically render with UI if the file ends with `.fknb`.

⸻

📁 File Type

Create a notebook file:

```bash
nvim my_notebook.fknb
```


⸻

⚙️ Under the Hood

FKNB uses:
•Virtual lines
•Extmarks
•Custom status spinner
•No overwriting buffer text
•Kernel icon mapping
•Language recognition from cell header

⸻

🧩 Roadmap

✅ Done
•Basic cell UI & separators
•Spinner + status icons
•Hide cell markers
•No-overlap UI rendering

🔜 Coming Next

| Feature                      | Priority |
| ---------------------------- | :------: |
| Execute Python/Lua cells     |  ⭐⭐⭐⭐  |
| Persistent execution state   |   ⭐⭐⭐    |
| Output panel render          |  ⭐⭐⭐⭐  |
| Async execution queue        |   ⭐⭐⭐    |
| Toolbar keybinds             |    ⭐⭐    |
| Theme support (Catppuccin/Gruvbox) |    ⭐⭐    |


⸻

📦 Install (WIP)

```lua
-- lazy.nvim pseudo-install (soon)
{
  "https://github.com/flashcodes-themayankjha/fknb.nvim",    
  config = function()
    require("fknb").setup()
  end
}
```




💡 Philosophy

Bring interactive computing to Neovim
without killing the Vim workflow.

•No notebook lag
•No ugly borders
•Seamless editing experience
•Beautiful, minimalist inline UI



🧑‍💻 Author

Created by: Mayank Kumar Jha
Project vision: Modern Neovim notebooks + gamified dev UX



🌟 Support / Contribute

This is an early stage tool — feedback & PRs welcome!

Star ⭐ the repo if you love Neovim science ❤️
