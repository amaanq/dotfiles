---@diagnostic disable: missing-parameter

local wk = require("which-key")
local util = require("util")

vim.o.timeoutlen = 300

wk.setup({
	show_help = false,
	triggers = "auto",
	plugins = { spelling = true },
	key_labels = { ["<leader>"] = "SPC" },
})

-- Move to window using the <ctrl> movement keys
vim.keymap.set("n", "<left>", "<C-w>h")
vim.keymap.set("n", "<down>", "<C-w>j")
vim.keymap.set("n", "<up>", "<C-w>k")
vim.keymap.set("n", "<right>", "<C-w>l")

-- Resize window using <ctrl> arrow keys
vim.keymap.set("n", "<S-Up>", ":resize +2<CR>")
vim.keymap.set("n", "<S-Down>", ":resize -2<CR>")
vim.keymap.set("n", "<S-Left>", ":vertical resize -2<CR>")
vim.keymap.set("n", "<S-Right>", ":vertical resize +2<CR>")

-- Move Lines
vim.keymap.set("n", "<A-j>", ":m .+1<CR>==")
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv")
vim.keymap.set("i", "<A-j>", "<Esc>:m .+1<CR>==gi")
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==")
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv")
vim.keymap.set("i", "<A-k>", "<Esc>:m .-2<CR>==gi")

-- Switch buffers with tab
vim.keymap.set("n", "<C-Left>", ":bprevious<CR>")
vim.keymap.set("n", "<C-Right>", ":bnext<CR>")

-- Easier pasting
vim.keymap.set("n", "[p", ":pu!<CR>")
vim.keymap.set("n", "]p", ":pu<CR>")

-- Clear search with <esc>
vim.keymap.set("", "<esc>", ":noh<CR>")
vim.keymap.set("n", "gw", "*N")
vim.keymap.set("x", "gw", "*N")

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
vim.keymap.set("n", "n", "'Nn'[v:searchforward]", { expr = true })
vim.keymap.set("x", "n", "'Nn'[v:searchforward]", { expr = true })
vim.keymap.set("o", "n", "'Nn'[v:searchforward]", { expr = true })
vim.keymap.set("n", "N", "'nN'[v:searchforward]", { expr = true })
vim.keymap.set("x", "N", "'nN'[v:searchforward]", { expr = true })
vim.keymap.set("o", "N", "'nN'[v:searchforward]", { expr = true })

-- Add undo break-points
vim.keymap.set("i", ",", ",<c-g>u")
vim.keymap.set("i", ".", ".<c-g>u")
vim.keymap.set("i", ";", ";<c-g>u")

-- save in insert mode
vim.keymap.set("i", "<C-s>", "<esc>:w<CR>")
vim.keymap.set("n", "<C-s>", "<esc>:w<CR>")
vim.keymap.set("n", "<C-c>", "<esc>ciw")

-- telescope <ctrl-r> in command line
-- vim.cmd([[cmap <C-R> <Plug>(TelescopeFuzzyCommandSearch)]])

-- better indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

vim.keymap.set("n", "<space>cu", function()
	local number = math.random(math.pow(2, 127) + 1, math.pow(2, 128))
	return "i" .. string.format("%.0f", number)
end, {
	expr = true,
	desc = "GUID",
})

-- makes * and # work on visual mode too.
vim.cmd([[
  function! g:VSetSearch(cmdtype)
    let temp = @s
    norm! gv"sy
    let @/ = '\V' . substitute(escape(@s, a:cmdtype.'\'), '\n', '\\n', 'g')
    let @s = temp
  endfunction

  xnoremap * :<C-u>call g:VSetSearch('/')<CR>/<C-R>=@/<CR><CR>
  xnoremap # :<C-u>call g:VSetSearch('?')<CR>?<C-R>=@/<CR><CR>
]])

local leader = {
	["w"] = {
		name = "+windows",
		["w"] = { "<C-W>p", "other-window" },
		["d"] = { "<C-W>c", "delete-window" },
		["-"] = { "<C-W>s", "split-window-below" },
		["|"] = { "<C-W>v", "split-window-right" },
		["2"] = { "<C-W>v", "layout-double-columns" },
		["h"] = { "<C-W>h", "window-left" },
		["j"] = { "<C-W>j", "window-below" },
		["l"] = { "<C-W>l", "window-right" },
		["k"] = { "<C-W>k", "window-up" },
		["H"] = { "<C-W>5<", "expand-window-left" },
		["J"] = { ":resize +5", "expand-window-below" },
		["L"] = { "<C-W>5>", "expand-window-right" },
		["K"] = { ":resize -5", "expand-window-up" },
		["="] = { "<C-W>=", "balance-window" },
		["s"] = { "<C-W>s", "split-window-below" },
		["v"] = { "<C-W>v", "split-window-right" },
	},
	c = {
		name = "+code",
	},
	b = {
		name = "+buffer",
		["b"] = { "<CMD>:e #<CR>", "Switch to Other Buffer" },
		["p"] = { "<CMD>:BufferLineCyclePrev<CR>", "Previous Buffer" },
		["["] = { "<CMD>:BufferLineCyclePrev<CR>", "Previous Buffer" },
		["n"] = { "<CMD>:BufferLineCycleNext<CR>", "Next Buffer" },
		["]"] = { "<CMD>:BufferLineCycleNext<CR>", "Next Buffer" },
		["d"] = { "<CMD>:Bdelete<CR>", "Delete Buffer" },
		["D"] = { "<CMD>:bd<CR>", "Delete Buffer & Window" },
	},
	g = {
		name = "+git",
		l = {
			function()
				require("util").float_terminal("lazygit")
			end,
			"LazyGit",
		},
		c = { "<Cmd>Telescope git_commits<CR>", "commits" },
		b = { "<Cmd>Telescope git_branches<CR>", "branches" },
		s = { "<Cmd>Telescope git_status<CR>", "status" },
		d = { "<CMD>DiffviewOpen<CR>", "DiffView" },
		h = { name = "+hunk" },
	},
	["h"] = {
		name = "+help",
		t = { "<CMD>:Telescope builtin<CR>", "Telescope" },
		c = { "<CMD>:Telescope commands<CR>", "Commands" },
		h = { "<CMD>:Telescope help_tags<CR>", "Help Pages" },
		m = { "<CMD>:Telescope man_pages<CR>", "Man Pages" },
		k = { "<CMD>:Telescope keymaps<CR>", "Key Maps" },
		s = { "<CMD>:Telescope highlights<CR>", "Search Highlight Groups" },
		l = { [[<CMD>TSHighlightCapturesUnderCursor<CR>]], "Highlight Groups at cursor" },
		f = { "<CMD>:Telescope filetypes<CR>", "File Types" },
		o = { "<CMD>:Telescope vim_options<CR>", "Options" },
		a = { "<CMD>:Telescope autocommands<CR>", "Auto Commands" },
		p = {
			name = "+packer",
			p = { "<CMD>PackerSync<CR>", "Sync" },
			s = { "<CMD>PackerStatus<CR>", "Status" },
			i = { "<CMD>PackerInstall<CR>", "Install" },
			c = { "<CMD>PackerCompile<CR>", "Compile" },
		},
	},
	s = {
		name = "+search",
		g = { "<CMD>Telescope live_grep<CR>", "Grep" },
		b = { "<CMD>Telescope current_buffer_fuzzy_find<CR>", "Buffer" },
		s = {
			function()
				require("telescope.builtin").lsp_document_symbols({
					symbols = { "Class", "Function", "Method", "Constructor", "Interface", "Module", "Struct", "Trait" },
				})
			end,
			"Goto Symbol",
		},
		h = { "<CMD>Telescope command_history<CR>", "Command History" },
		m = { "<CMD>Telescope marks<CR>", "Jump to Mark" },
		r = { "<CMD>lua require('spectre').open()<CR>", "Replace (Spectre)" },
	},
	f = {
		name = "+file",
		t = { "<CMD>Neotree toggle<CR>", "NeoTree" },
		f = { "<CMD>Telescope find_files<CR>", "Find File" },
		r = { "<CMD>Telescope oldfiles<CR>", "Open Recent File" },
		n = { "<CMD>enew<CR>", "New File" },
		z = "Zoxide",
		d = "Dot Files",
	},
	o = {
		name = "+open",
		p = { "<CMD>MarkdownPreview<CR>", "Markdown Preview" },
		g = { "<CMD>Glow<CR>", "Markdown Glow" },
		n = { "<CMD>lua require('github-notifications.menu').notifications()<CR>", "GitHub Notifications" },
	},
	p = {
		name = "+project",
		p = "Open Project",
		b = { ":Telescope file_browser cwd=~/projects<CR>", "Browse ~/projects" },
	},
	t = {
		name = "toggle",
		f = {
			require("plugins.lsp.formatting").toggle,
			"Format on Save",
		},
		s = {
			function()
				util.toggle("spell")
			end,
			"Spelling",
		},
		w = {
			function()
				util.toggle("wrap")
			end,
			"Word Wrap",
		},
		n = {
			function()
				util.toggle("relativenumber", true)
				util.toggle("number")
			end,
			"Line Numbers",
		},
	},
	["<tab>"] = {
		name = "tabs",
		["<tab>"] = { "<CMD>tabnew<CR>", "New Tab" },
		n = { "<CMD>tabnext<CR>", "Next" },
		d = { "<CMD>tabclose<CR>", "Close" },
		p = { "<CMD>tabprevious<CR>", "Previous" },
		["]"] = { "<CMD>tabnext<CR>", "Next" },
		["["] = { "<CMD>tabprevious<CR>", "Previous" },
		f = { "<CMD>tabfirst<CR>", "First" },
		l = { "<CMD>tablast<CR>", "Last" },
	},
	["`"] = { "<CMD>:e #<CR>", "Switch to Other Buffer" },
	[" "] = "Find File",
	["."] = { ":Telescope file_browser<CR>", "Browse Files" },
	[","] = { "<CMD>Telescope buffers show_all_buffers=true<CR>", "Switch Buffer" },
	["/"] = { "<CMD>Telescope live_grep<CR>", "Search" },
	[":"] = { "<CMD>Telescope command_history<CR>", "Command History" },
	["C"] = {
		function()
			util.clipman()
		end,
		"Paste from Clipman",
	},
	["P"] = {
		":Telescope neoclip plus<CR>",
		"Paste from Clipman",
	},
	q = {
		name = "+quit/session",
		q = { "<CMD>:qa<CR>", "Quit" },
		["!"] = { "<CMD>:qa!<CR>", "Quit without saving" },
		s = { [[<CMD>lua require("persistence").load()<CR>]], "Restore Session" },
		l = { [[<CMD>lua require("persistence").load({last=true})<CR>]], "Restore Last Session" },
		d = { [[<CMD>lua require("persistence").stop()<CR>]], "Stop Current Session" },
	},
	x = {
		name = "+errors",
		x = { "<CMD>TroubleToggle workspace_diagnostics<CR>", "Trouble" },
		t = { "<CMD>TodoTrouble<CR>", "Todo Trouble" },
		T = { "<CMD>TodoTelescope<CR>", "Todo Telescope" },
		l = { "<CMD>lopen<CR>", "Open Location List" },
		q = { "<CMD>copen<CR>", "Open Quickfix List" },
	},
	z = { [[<CMD>ZenMode<CR>]], "Zen Mode" },
	T = { [[<Plug>PlenaryTestFile]], "Plenary Test" },

	["1"] = { "[[<CMD>1ToggleTerm<CR>]]", "ToggleTerm 1" },
	["2"] = { "[[<CMD>2ToggleTerm<CR>]]", "ToggleTerm 2" },
	["3"] = { "[[<CMD>3ToggleTerm<CR>]]", "ToggleTerm 3" },
	["4"] = { "[[<CMD>4ToggleTerm<CR>]]", "ToggleTerm 4" },
	["5"] = { "[[<CMD>5ToggleTerm<CR>]]", "ToggleTerm 5" },
}

-- for i = 0, 10 do
--     leader[tostring(i)] = "which_key_ignore"
-- end
-- ignore 0, 6-10
local ignores = { "0", "6", "7", "8", "9", "10" }
for _, v in ipairs(ignores) do
	leader[v] = "which_key_ignore"
end

wk.register(leader, { prefix = "<leader>" })

wk.register({ g = { name = "+goto" } })
