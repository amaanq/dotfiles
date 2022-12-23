local indent = 4

local notifs = {}
local notify = {
	orig = vim.notify,
	lazy = function(...)
		table.insert(notifs, { ... })
	end,
}

vim.notify = notify.lazy

local function lazy_notify()
	local check = vim.loop.new_check()
	local start = vim.loop.hrtime()
	check:start(function()
		if vim.notify ~= notify.lazy then
		elseif (vim.loop.hrtime() - start) / 1e6 > 300 then
			vim.notify = notify.orig
		else
			return
		end
		check:stop()
		-- use the new notify
		vim.schedule(function()
			for _, notif in ipairs(notifs) do
				vim.notify(unpack(notif))
			end
		end)
	end)
end

lazy_notify()

if vim.fn.has("nvim-0.8") == 1 then
	-- vim.opt.spell = true -- Put new windows below current
	vim.opt.cmdheight = 0

	-- make all keymaps silent by default
	local keymap_set = vim.keymap.set
	vim.keymap.set = function(mode, lhs, rhs, opts)
		opts = opts or {}
		opts.silent = opts.silent ~= false
		return keymap_set(mode, lhs, rhs, opts)
	end
end

if vim.fn.has("nvim-0.9") == 1 then
	vim.opt.splitkeep = "screen"
end

vim.g.mapleader = " "
vim.g.maplocalleader = ","

vim.opt.autowrite = true -- enable auto write
vim.opt.clipboard = "unnamedplus" -- sync with system clipboard
-- vim.opt.concealcursor = "nc" -- Hide * markup for bold and italic
vim.opt.conceallevel = 3 -- Hide * markup for bold and italic
vim.opt.confirm = true -- confirm to save changes before exiting modified buffer
vim.opt.cursorline = true -- Enable highlighting of the current line
-- vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.backup = true

if vim.fn.has("nvim-0.8.0") == 1 then
	vim.opt.backupdir = vim.fn.stdpath("state") .. "/backup"
end

-- vim.opt.foldexpr = "nvim_treesitter#foldexpr()" -- TreeSitter folding
-- vim.opt.foldlevel = 6
-- vim.opt.foldmethod = "expr" -- TreeSitter folding
-- vim.opt.foldmethod = "indent"
-- vim.opt.foldlevel = 0
vim.o.formatoptions = "jcroqlnt" -- tcqj

vim.opt.guifont = "Menlo:h10"
vim.opt.grepprg = "rg --vimgrep --smart-case --"
vim.opt.grepformat = "%f:%l:%c:%m"
vim.opt.hidden = true -- Enable modified buffers in background
vim.opt.ignorecase = true -- Ignore case
vim.opt.inccommand = "nosplit" -- preview incremental substitute
vim.opt.joinspaces = false -- No double spaces with join after a dot
vim.opt.list = true -- Show some invisible characters (tabs...
vim.opt.mouse = "a" -- enable mouse mode
vim.opt.number = true -- Print line number
vim.opt.pumblend = 10 -- Popup blend
vim.opt.pumheight = 10 -- Maximum number of entries in a popup
vim.opt.relativenumber = true -- Relative line numbers
vim.opt.scrolloff = 4 -- Lines of context
vim.opt.shiftround = true -- Round indent
vim.opt.shiftwidth = indent -- Size of an indent
vim.opt.laststatus = 0
vim.opt.showmode = false -- dont show mode since we have a statusline
vim.opt.sidescrolloff = 8 -- Columns of context
vim.opt.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
vim.opt.smartcase = true -- Don't ignore case with capitals
vim.opt.smartindent = true -- Insert indents automatically

vim.g.neovide_refresh_rate = 165
vim.g.neovide_cursor_animation_length = 0.05
vim.g.neovide_cursor_trail_length = 0.5
vim.g.neovide_cursor_antialiasing = true
vim.g.neovide_cursor_vfx_mode = "ripple"
vim.g.neovide_cursor_vfx_opacity = 200.0
vim.g.neovide_cursor_vfx_particle_lifetime = 1.2
vim.g.neovide_cursor_vfx_particle_density = 7.0
vim.g.neovide_cursor_vfx_particle_speed = 10.0
vim.g.neovide_cursor_vfx_particle_phase = 1.5
vim.g.neovide_cursor_vfx_particle_curl = 1.0

vim.opt.splitbelow = true -- Put new windows below current
vim.opt.splitright = true -- Put new windows right of current
vim.opt.tabstop = indent -- Number of spaces tabs count for
vim.opt.termguicolors = true -- True color support
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.updatetime = 200 -- save swap file and trigger CursorHold
vim.opt.wildmode = "longest:full,full" -- Command-line completion mode
vim.opt.completeopt = "menu,menuone,noselect"
vim.opt.wrap = false -- Disable line wrap
vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize" }
vim.opt.listchars = "trail:·,nbsp:◇,tab:→ ,extends:▸,precedes:◂"
vim.opt.fillchars = {
	--   horiz = "━",
	--   horizup = "┻",
	--   horizdown = "┳",
	--   vert = "┃",
	--   vertleft = "┫",
	--   vertright = "┣",
	--   verthoriz = "╋",im.o.fillchars = [[eob: ,
	-- fold = " ",
	foldopen = "",
	-- foldsep = " ",
	foldclose = "",
}
-- vim.o.shortmess = "IToOlxfitn"
-- vim.opt.shortmess:get()
if vim.fn.has("nvim-0.9") == 1 then
	vim.o.shortmess = "filnxtToOFWIcC"
end

-- don't load the plugins below
local builtins = {
	"gzip",
	"zip",
	"zipPlugin",
	"fzf",
	"tar",
	"tarPlugin",
	"getscript",
	"getscriptPlugin",
	"vimball",
	"vimballPlugin",
	"2html_plugin",
	"matchit",
	"matchparen",
	"logiPat",
	"rrhelper",
	"netrw",
	"netrwPlugin",
	"netrwSettings",
	"netrwFileHandlers",
}

for _, plugin in ipairs(builtins) do
	vim.g["loaded_" .. plugin] = 1
end

-- Use proper syntax highlighting in code blocks
local fences = {
	"lua",
	-- "vim",
	"json",
	"typescript",
	"javascript",
	"js=javascript",
	"ts=typescript",
	"shell=sh",
	"python",
	"sh",
	"console=sh",
}
vim.g.markdown_fenced_languages = fences
vim.g.markdown_recommended_style = 0
