-- lua/fknb/ftdetect.lua
vim.filetype.add({
  extension = {
    fknb = "fknb",
    nb = "fknb",
    ipynb = "fknb",
    pynb = "fknb",
  },
})

-- lua/fknb/ftplugin/fknb.lua
-- Treat .fknb files as markdown for parsing
vim.treesitter.language.register("markdown", "fknb")

-- Optional: enable markdown highlight
vim.bo.filetype = "fknb"
vim.bo.syntax = "markdown"