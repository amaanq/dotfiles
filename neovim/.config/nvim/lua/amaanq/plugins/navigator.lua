require('Navigator').setup({
    auto_save = 'current',
});

vim.keymap.set('n', '<A-Left>', '<CMD>lua require("Navigator").left()<CR>');
vim.keymap.set('n', '<A-Up>', '<CMD>lua require("Navigator").up()<CR>');
vim.keymap.set('n', '<A-Right>', '<CMD>lua require("Navigator").right()<CR>');
vim.keymap.set('n', '<A-Down>', '<CMD>lua require("Navigator").down()<CR>');
