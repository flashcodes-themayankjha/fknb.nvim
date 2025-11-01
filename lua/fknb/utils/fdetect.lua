-- lua/fknb/utils/fdetect.lua
-- @fknotes NOTE: Registering file extensions for FkNB filetype detection.
vim.filetype.add {
  extension = {
    fknb = "fknb",
    nb = "fknb",
    ipynb = "fknb",
    pynb = "fknb",
  },
}

-- @fknotes NOTE: Autocmd to ensure tree-sitter is started for fknb files.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "fknb",
  callback = function(ev)
    -- Removed: vim.treesitter.start(ev.buf, "fknb")
    -- The injections will handle the highlighting within the cells.
  end,
})

vim.treesitter.language.register('fknb', 'fknb')
