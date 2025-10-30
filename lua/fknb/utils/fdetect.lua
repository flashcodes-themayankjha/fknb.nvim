-- lua/fknb/ftdetect.lua
-- @fknotes NOTE: Registering file extensions for FkNB filetype detection.
vim.filetype.add({
  extension = {
       fknb = "fknb",
       nb = "fknb",
       ipynb = "fknb",
       pynb = "fknb",
  },
})

-- lua/fknb/ftplugin/fknb.lua
-- @fknotes NOTE: Treat .fknb files as markdown for Treesitter parsing.
vim.treesitter.language.register("markdown", "fknb")

-- @fknotes NOTE: Optional: Enable markdown highlight for 'fknb' filetype.
vim.bo.filetype = "fknb"
vim.bo.syntax = "markdown"
