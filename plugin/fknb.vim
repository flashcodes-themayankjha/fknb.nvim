if exists('g:loaded_fknb') | finish | endif
let g:loaded_fknb = 1

command! FkStartKernel lua require('fknb').start_kernel()
command! FkStopKernel lua require('fknb').stop_kernel()
command! FkSelectKernel lua require('fknb').select_kernel()
command! -nargs=1 FkExport lua require('fknb').export(<q-args>)
command! FkRunCell lua require('fknb').run_current_cell()

" Default mapping
nnoremap <silent> <leader>r <Cmd>FkRunCell<CR>
