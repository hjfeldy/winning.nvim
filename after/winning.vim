lua require'autoTerm'
lua require'winSizing'
command! ToggleTerm lua require'autoTerm':toggle()
command! NextTerm lua Terminals:nextTerm()
command! PrevTerm lua Terminals:prevTerm()
command! RenameTerm lua Terminals:rename()
command! EvenTerms lua Terminals:evenWindows()
command! NewTerm lua Terminals:create()
command! ToggleZoom lua Windows:toggleZoom()

autocmd TermClose * lua Terminals:delete(Terminals.recent)
autocmd WinClosed * lua Terminals:unfocus()
autocmd WinEnter * lua Terminals:setCurrent()
autocmd TermClose * lua Windows:winInfo()
autocmd WinNew * lua Windows:winInfo()
