vim.g.mapleader = " "

vim.opt.fillchars = {
	foldopen = "",
	foldclose = "",
	fold = " ",
	foldsep = " ",
	diff = "╱",
	eob = " ",
}
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.o.foldcolumn = "0"

vim.g.os = vim.loop.os_uname().sysname
vim.g.open_command = vim.g.os == "Darwin" and "open" or "xdg-open"
vim.g.dotfiles = vim.env.DOTFILES or vim.fn.expand("~/.dotfiles")
vim.g.vim_dir = vim.g.dotfiles .. "/.config/nvim"

----------------------------------------------------------------------------------------------------
-- Default plugins
----------------------------------------------------------------------------------------------------
-- Stop loading built in plugins
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_tarPlugin = 1
vim.g.logipat = 1

-- Ensure all autocommands are cleared
vim.api.nvim_create_augroup("vimrc", {})

if vim.fn.has("nvim-0.8") == 1 then
	vim.opt.backup = true
	vim.opt.cmdheight = 0
	vim.opt.backupdir = vim.fn.stdpath("state") .. "/backup"
end

vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0

require("util.status")
