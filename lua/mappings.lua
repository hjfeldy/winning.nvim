local map = vim.api.nvim_set_keymap
local opts = {noremap = true, silent = true}
-- Recommended default mappings
map('n', '<Leader>tt', ':NewTerm()<CR>', opts)
map('n', '<Leader>tn', ':NextTerm()<CR>', opts)
map('n', '<Leader>tp', ':PrevTerm()<CR>', opts)
map('n', '<Leader>te', ':EvenTerms()<CR>', opts)
map('n', '<C-t>', ':ToggleTerm()<CR>', opts)
map('t', '<C-t>', '<C-\\><C-n>:ToggleTerm()<CR>', opts)
map('n', '<Leader>tr', ':RenameTerm()<CR>', opts)
