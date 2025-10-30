# FkNB.nvim

A Neovim plugin for enhanced filetype detection and custom icons for notebook files.

## ✨ Features

-   **Filetype Detection:** Automatically detects and sets the filetype for `.fknb`, `.ipynb`, `.pynb`, and `.nb` files to `fknb`.
-   **Custom Icons:** Provides a distinct icon for `fknb` filetypes, integrating with `nvim-web-devicons` if available.
-   **Markdown Integration:** Treats `fknb` files as markdown for Treesitter parsing and syntax highlighting.

## 🚀 Installation

Install with your favorite plugin manager.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'flashcodes-themayankjha/fknb.nvim', -- Assuming this will be the repository name
  name = 'fknb',
  config = function()
    require('fknb').setup()
  end,
}
```

## 📖 Usage

Once installed, the plugin will automatically:
-   Detect `.fknb`, `.ipynb`, `.pynb`, and `.nb` files as `fknb` filetypes.
-   Display the custom `FkNB` icon for these files (requires `nvim-web-devicons` to be installed and set up).
-   Enable markdown syntax highlighting and Treesitter parsing for `fknb` files.

## ⚙️ Configuration

Currently, there are no explicit configuration options. The plugin works out-of-the-box.

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or pull requests.

## 📄 License

This project is licensed under the MIT License.
