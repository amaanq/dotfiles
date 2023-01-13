-- bootstrap from github
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath })
	vim.fn.system({ "git", "-C", lazypath, "checkout", "tags/stable" }) -- last stable release
end
vim.opt.rtp:prepend(lazypath)

-- load lazy
require("lazy").setup({
	spec = {
		{
			"amaanq/LazyVim",
			import = "lazyvim.plugins",
			opts = {},
			branch = "master",
		},
		{ import = "lazyvim.plugins.extras.lang.clangd" },
		{ import = "lazyvim.plugins.extras.lang.copilot" },
		{ import = "lazyvim.plugins.extras.lang.java" },
		{ import = "lazyvim.plugins.extras.lang.json" },
		{ import = "lazyvim.plugins.extras.lang.nodejs" },
		{ import = "lazyvim.plugins.extras.lang.rust" },
		{ import = "lazyvim.plugins.extras.lang.typescript" },
		{ import = "plugins" },
	},
	defaults = { lazy = true },
	dev = { patterns = jit.os:find("Windows") and {} or { "amaanq", "LazyVim" } },
	install = { colorscheme = { "tokyonight", "habamax" } },
	checker = { enabled = true },
	diff = {
		cmd = "terminal_git",
	},
	performance = {
		cache = {
			enabled = true,
			-- disable_events = {},
		},
		rtp = {
			disabled_plugins = {
				"gzip",
				"matchit",
				"matchparen",
				"netrwPlugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
	ui = {
		custom_keys = {
			["<localleader>d"] = function(plugin)
				dd(plugin)
			end,
		},
	},
	debug = true,
})
