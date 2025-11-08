" ============================================================================
" FKVim — Jupyter-style Notebook Commands for Neovim
" ============================================================================
if exists('g:loaded_fkvim')
  finish
endif
let g:loaded_fkvim = 1

" ----------------------------------------------------------------------------
" Core Commands
" ----------------------------------------------------------------------------

" ▶️ Run the current cell
command! -nargs=0 FkRunCell lua require("fknb.core.commands").run_current_cell()

" ▶️ Restart kernel (safe stop + start)
command! -nargs=0 FkRestartKernel lua require("fknb.core.commands").restart_kernel()

" ▶️ Stop kernel
command! -nargs=0 FkStopKernel lua require("fknb.core.kernel").stop()

" ▶️ Clear output for current cell
command! -nargs=0 FkClearOutput lua require("fknb.ui.output").clear(require("fknb.core.parser").get_cell_at_cursor().id)

" ▶️ Clear all outputs
command! -nargs=0 FkClearAllOutputs lua require("fknb.core.kernel").clear_all_outputs()

" ▶️ Collapse / Expand current cell output
command! -nargs=0 FkToggleOutput lua require("fknb.ui.output").toggle_collapse(require("fknb.core.parser").get_cell_at_cursor().id)

" ▶️ Start kernel
command! -nargs=0 FkStartKernel lua require("fknb.core.kernel").start()



" ----------------------------------------------------------------------------
" Optional autostart kernel for *.fknb buffers
" ----------------------------------------------------------------------------
augroup FkvimAutostart
  autocmd!
  autocmd BufEnter *.fknb lua require("fknb.core.kernel").start()
augroup END
