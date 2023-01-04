if vim.fn.has("nvim-0.8") == 1 then
	vim.opt.backup = true
	vim.opt.cmdheight = 0
	vim.opt.backupdir = vim.fn.stdpath("state") .. "/backup"
end
