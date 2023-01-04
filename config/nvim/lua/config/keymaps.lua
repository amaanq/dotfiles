local wk = require("which-key")
local util = require("util")

vim.o.timeoutlen = 300

local id
for _, key in ipairs({ "h", "j", "k", "l" }) do
	local count = 0
	vim.keymap.set("n", key, function()
		if count >= 10 then
			id = vim.notify("Hold it Cowboy!", vim.log.levels.WARN, {
				icon = "🤠",
				replace = id,
				keep = function()
					return count >= 10
				end,
			})
		else
			count = count + 1
			vim.defer_fn(function()
				count = count - 1
			end, 5000)
			return key
		end
	end, { expr = true })
end

-- Move to window using the movement keys
vim.keymap.set("n", "<left>", "<C-w>h")
vim.keymap.set("n", "<down>", "<C-w>j")
vim.keymap.set("n", "<up>", "<C-w>k")
vim.keymap.set("n", "<right>", "<C-w>l")

-- change word with <c-c>
vim.keymap.set("n", "<C-c>", "<cmd>normal ciw<cr>a")

-- makes * and # work on visual mode too.
vim.cmd([[
  function! g:VSetSearch(cmdtype)
    let temp = @s
    norm! gv"sy
    let @/ = '\V' . substitute(escape(@s, a:cmdtype.'\'), '\n', '\\n', 'g')
    let @s = temp
  endfunction

  xnoremap * :<C-u>call g:VSetSearch('/')<cr>/<C-R>=@/<cr><cr>
  xnoremap # :<C-u>call g:VSetSearch('?')<cr>?<C-R>=@/<cr><cr>
]])

local leader = {
	["w"] = {
		name = "+windows",
		["w"] = { "<C-W>p", "other-window" },
		["d"] = { "<C-W>c", "delete-window" },
		["-"] = { "<C-W>s", "split-window-below" },
		["|"] = { "<C-W>v", "split-window-right" },
	},
	b = {
		name = "+buffer",
		["b"] = { "<cmd>:e #<cr>", "Switch to Other Buffer" },
		["p"] = { "<cmd>:BufferLineCyclePrev<cr>", "Previous Buffer" },
		["["] = { "<cmd>:BufferLineCyclePrev<cr>", "Previous Buffer" },
		["n"] = { "<cmd>:BufferLineCycleNext<cr>", "Next Buffer" },
		["]"] = { "<cmd>:BufferLineCycleNext<cr>", "Next Buffer" },
		-- ["D"] = { "<cmd>:bd<cr>", "Delete Buffer & Window" },
	},
	g = {
		d = { "<cmd>DiffviewOpen<cr>", "DiffView" },
		h = { name = "+hunk" },
	},
	n = {
		name = "+test",
		r = { "<cmd>lua require('neotest').run.run()<cr>", "Run Nearest Test" },
		o = { "<cmd>lua require('neotest').output.open()<cr>", "Open Output" },
		s = { "<cmd>lua require('neotest').summary.toggle()<cr>", "Toggle Summary" },
	},
	k = {
		name = "+theme",
		a = { "<cmd>colorscheme ayu<cr>", "Ayu" },
		c = { "<cmd>colorscheme catppuccin<cr>", "Catppuccin" },
		d = { "<cmd>colorscheme onedark_vivid<cr>", "One Dark Pro" },
		g = { "<cmd>lua require('github-theme').setup({theme_style = 'dark_default'})<cr>", "GitHub" },
		k = { "<cmd>colorscheme kanagawa<cr>", "Kanagawa" },
		m = { "<cmd>colorscheme material<cr>", "Material" },
		o = { "<cmd>colorscheme oxocarbon<cr>", "Oxocarbon" },
		s = { "<cmd>lua require('Sakura').load()<cr>", "Sakura" },
		t = { "<cmd>lua require('tokyonight').load()<cr>", "Tokyo Night" },
	},
	t = {
		name = "toggle",
		f = {
			require("lazyvim.plugins.lsp.format").toggle,
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
		["<tab>"] = { "<cmd>tabnew<cr>", "New Tab" },
		n = { "<cmd>tabnext<cr>", "Next" },
		d = { "<cmd>tabclose<cr>", "Close" },
		p = { "<cmd>tabprevious<cr>", "Previous" },
		["]"] = { "<cmd>tabnext<cr>", "Next" },
		["["] = { "<cmd>tabprevious<cr>", "Previous" },
		f = { "<cmd>tabfirst<cr>", "First" },
		l = { "<cmd>tablast<cr>", "Last" },
	},
	["`"] = { "<cmd>:e #<cr>", "Switch to Other Buffer" },
	[" "] = "Find File",
	["C"] = {
		function()
			util.clipman()
		end,
		"Paste from Clipman",
	},
	q = {
		name = "+quit/session",
		q = { "<cmd>qa<cr>", "Quit" },
		["!"] = { "<cmd>:qa!<cr>", "Quit without saving" },
		s = { [[<cmd>lua require("persistence").load()<cr>]], "Restore Session" },
		l = { [[<cmd>lua require("persistence").load({last=true})<cr>]], "Restore Last Session" },
		d = { [[<cmd>lua require("persistence").stop()<cr>]], "Stop Current Session" },
	},
	x = {
		name = "+errors",
		x = { "<cmd>TroubleToggle workspace_diagnostics<cr>", "Trouble" },
		t = { "<cmd>TodoTrouble<cr>", "Todo Trouble" },
		tt = { "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>", "Todo Trouble" },
		T = { "<cmd>TodoTelescope<cr>", "Todo Telescope" },
		l = { "<cmd>lopen<cr>", "Open Location List" },
		q = { "<cmd>copen<cr>", "Open Quickfix List" },
	},
	z = { [[<cmd>ZenMode<cr>]], "Zen Mode" },
	T = {
		function()
			util.test(true)
		end,
		"Plenary Test File",
	},
	D = {
		function()
			util.test()
		end,
		"Plenary Test Directory",
	},

	["1"] = { "<cmd>1ToggleTerm<cr>", "ToggleTerm 1" },
	["2"] = { "<cmd>2ToggleTerm<cr>", "ToggleTerm 2" },
	["3"] = { "<cmd>3ToggleTerm<cr>", "ToggleTerm 3" },
	["4"] = { "<cmd>4ToggleTerm<cr>", "ToggleTerm 4" },
	["5"] = { "<cmd>5ToggleTerm<cr>", "ToggleTerm 5" },
}

-- ignore 0, 6-10
for _, v in ipairs({ "0", "6", "7", "8", "9", "10" }) do
	leader[v] = "which_key_ignore"
end

wk.register(leader, { prefix = "<leader>" })

wk.register({ g = { name = "+goto" } })
