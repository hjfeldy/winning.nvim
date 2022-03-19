command! ToggleTerm lua require'autoTerm'.toggle()
command! NextTerm lua require'autoTerm'.nextTerm()
command! PrevTerm lua require'autoTerm'.prevTerm()
command! RenameTerm lua require'autoTerm'.rename()
command! EvenTerms lua require'autoTerm'.evenWindows()
command! NewTerm lua require'autoTerm'.create()
command! ToggleZoom lua require'winSizing'.toggleZoom()

" autocmd TermClose * lua require'autoTerm'.delete()
" autocmd WinClosed * lua require'autoTerm'.unfocus()
autocmd WinEnter * lua require'autoTerm'.setCurrent()
autocmd TermClose * lua require'winSizing'.winInfo()
autocmd WinNew * lua require'winSizing'.winInfo()
