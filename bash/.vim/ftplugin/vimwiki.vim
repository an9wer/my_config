setlocal wrap             " lines longer than the width of the window will wrap
                          " and displaying continues on the next line.
setlocal textwidth=79     " maximum width of text that is being inserted

augroup ftplugin_vimwiki
  au!

  " Q: set formatoptions doesn't work?
  " thx: https://stackoverflow.com/a/24170442
  autocmd BufWinEnter *.wiki setlocal formatoptions=tcqjmB

  " unmap vimwiki's default o and O in normal model
  " nnoremap <silent> <buffer> o :<C-U>call vimwiki#lst#kbd_o()<CR>
  " nnoremap <silent> <buffer> O :<C-U>call vimwiki#lst#kbd_O()<CR>
  autocmd BufWinEnter *.wiki
    \ if !empty(maparg('o', 'n')) |
    \   nunmap <buffer> o|
    \ endif
  autocmd BufWinEnter *.wiki
    \ if !empty(maparg('O', 'n')) |
    \   nunmap <buffer> O|
    \ endif
augroup END


inoreabbrev <buffer> 2= ==  ==<Left><Left><Left>
inoreabbrev <buffer> = =  =<Left><Left>
