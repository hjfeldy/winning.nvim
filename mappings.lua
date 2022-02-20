local map = vim.api.nvim_set_keymap
local opts = {noremap = true, silent = true}
-- Recommended default mappings
map('n', '<Leader>tt', ':lua terminals:create()<CR>', opts)
map('n', '<Leader>tn', ':lua terminals:nextTerm()<CR>', opts)
map('n', '<Leader>tp', ':lua terminals:prevTerm()<CR>', opts)
map('n', '<Leader>te', ':lua terminals:evenWindows()<CR>', opts)
map('n', '<Leader>td', ':lua terminals:delete(terminals.recent)()<CR>', opts)
map('n', '<C-t>', ':lua terminals:toggle()<CR>', opts)
map('t', '<C-t>', '<C-\\><C-n>:lua terminals:toggle()<CR>', opts)
map('n', '<Leader>tr', ':lua terminals:rename()<CR>', opts)
