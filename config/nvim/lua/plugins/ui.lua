return {

	-- floating winbar
	{
		"b0o/incline.nvim",
		event = "BufReadPre",
		config = function()
			local colors = require("tokyonight.colors").setup()
			require("incline").setup({
				highlight = {
					groups = {
						InclineNormal = { guibg = "#3e68d7", guifg = colors.black },
						InclineNormalNC = { guifg = "#3e68d7", guibg = colors.black },
					},
				},
				window = { margin = { vertical = 0, horizontal = 1 } },
				render = function(props)
					local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
					local icon, color = require("nvim-web-devicons").get_icon_color(filename)
					return { { icon, guifg = color }, { " " }, { filename } }
				end,
			})
		end,
	},

	-- auto-resize windows
	{
		"anuvyklack/windows.nvim",
		event = "WinNew",
		dependencies = {
			{ "anuvyklack/middleclass" },
			{ "anuvyklack/animation.nvim", enabled = false },
		},
		keys = { { "<leader>Z", "<cmd>WindowsMaximize<cr>", desc = "Zoom" } },
		config = function()
			vim.o.winminwidth = 5
			vim.o.winminwidth = 5
			vim.o.equalalways = false
			require("windows").setup({
				animation = { enable = false, duration = 150 },
			})
		end,
	},

	-- scrollbar
	{
		"petertriho/nvim-scrollbar",
		event = "BufReadPost",
		config = function()
			local scrollbar = require("scrollbar")
			local colors = require("tokyonight.colors").setup()
			scrollbar.setup({
				handle = { color = colors.bg_highlight },
				excluded_filetypes = { "prompt", "TelescopePrompt", "noice", "notify" },
				marks = {
					Search = { color = colors.orange },
					Error = { color = colors.error },
					Warn = { color = colors.warning },
					Info = { color = colors.info },
					Hint = { color = colors.hint },
					Misc = { color = colors.purple },
				},
			})
		end,
	},

	-- better comment highlighting
	{
		"folke/paint.nvim",
		enabled = false,
		event = "BufReadPre",
		config = function()
			require("paint").setup({
				highlights = {
					{
						filter = { filetype = "lua" },
						pattern = "%s*%-%-%-%s*(@%w+)",
						hl = "Constant",
					},
					{
						filter = { filetype = "lua" },
						pattern = "%s*%-%-%[%[(@%w+)",
						hl = "Constant",
					},
					{
						filter = { filetype = "lua" },
						pattern = "%s*%-%-%-%s*@field%s+(%S+)",
						hl = "@field",
					},
					{
						filter = { filetype = "lua" },
						pattern = "%s*%-%-%-%s*@class%s+(%S+)",
						hl = "@variable.builtin",
					},
					{
						filter = { filetype = "lua" },
						pattern = "%s*%-%-%-%s*@alias%s+(%S+)",
						hl = "@keyword",
					},
					{
						filter = { filetype = "lua" },
						pattern = "%s*%-%-%-%s*@param%s+(%S+)",
						hl = "@parameter",
					},
				},
			})
		end,
	},

	-- style windows with different colorschemes
	{
		"folke/styler.nvim",
		event = "VeryLazy",
		opts = {
			themes = {
				markdown = { colorscheme = "tokyonight-storm" },
				help = { colorscheme = "oxocarbon", background = "dark" },
			},
		},
	},

	-- silly drops
	{
		"folke/drop.nvim",
		event = "VeryLazy",
		enabled = true,
		config = function()
			math.randomseed(os.time())
			local theme = ({ "stars", "snow" })[math.random(1, 3)]
			require("drop").setup({ theme = theme, max = 60, interval = 50 })
		end,
	},

	-- animations
	{
		"echasnovski/mini.animate",
		event = "VeryLazy",
		config = function()
			local mouse_scrolled = false
			for _, scroll in ipairs({ "Up", "Down" }) do
				local key = "<ScrollWheel" .. scroll .. ">"
				vim.keymap.set("", key, function()
					mouse_scrolled = true
					return key
				end, { expr = true })
			end

			local animate = require("mini.animate")

			animate.setup({
				resize = {
					timing = animate.gen_timing.linear({ duration = 100, unit = "total" }),
				},
				scroll = {
					timing = animate.gen_timing.linear({ duration = 150, unit = "total" }),
					subscroll = animate.gen_subscroll.equal({
						predicate = function(total_scroll)
							if mouse_scrolled then
								mouse_scrolled = false
								return false
							end
							return total_scroll > 1
						end,
					}),
				},
			})
		end,
	},

	-- lualine
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		opts = function(_, opts)
			table.insert(opts.sections.lualine_x, {
				function()
					return require("util.dashboard").status()
				end,
			})
		end,
	},

	{
		"norcalli/nvim-terminal.lua",
		ft = "terminal",
		config = true,
	},

	{
		"akinsho/nvim-toggleterm.lua",
		keys = "<C-`>",
		event = "BufReadPre",
		config = function()
			require("toggleterm").setup({
				size = 20,
				hide_numbers = true,
				open_mapping = [[<C-`>]],
				shade_filetypes = {},
				shade_terminals = true,
				shading_factor = 0.3, -- the degree by which to darken to terminal colour, default: 1 for dark backgrounds, 3 for light
				start_in_insert = true,
				persist_size = true,
				direction = "float",
				close_on_exit = true,
				shell = vim.o.shell,
			})

			-- Hide number column for
			-- vim.cmd [[au TermOpen * setlocal nonumber norelativenumber]]

			-- Esc twice to get to normal mode
			vim.cmd([[tnoremap <ESC> <C-\><C-N>]])
		end,
	},

	-- git blame
	{
		"f-person/git-blame.nvim",
		event = "BufReadPre",
		init = function()
			vim.g.gitblame_display_virtual_text = 0
		end,
	},

	-- git conflict
	{
		"akinsho/git-conflict.nvim",
		event = "BufReadPre",
		config = true,
	},
	{ "rhysd/git-messenger.vim", event = "BufRead" },
	{ "rhysd/committia.vim", event = "BufRead" },
	{
		"ruifm/gitlinker.nvim",
		event = "BufRead",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("gitlinker").setup()
		end,
	},
	{ "pwntester/octo.nvim", cmd = "Octo", config = true },

	{
		"lukas-reineke/virt-column.nvim",
		event = "VeryLazy",
		config = function()
			require("virt-column").setup({ char = "▕" })
		end,
	},

	{
		"itchyny/vim-highlighturl",
		event = "VeryLazy",
	},

	{
		"lukas-reineke/headlines.nvim",
		ft = { "org", "norg", "markdown", "yaml" },
		config = function()
			require("headlines").setup({
				markdown = {
					headline_highlights = { "Headline1", "Headline2", "Headline3" },
				},
				org = {
					headline_highlights = false,
				},
				norg = { codeblock_highlight = false },
			})
		end,
	},

	{
		"utilyre/barbecue.nvim",
		event = "VeryLazy",
		dependencies = {
			"neovim/nvim-lspconfig",
			"SmiteshP/nvim-navic",
			"nvim-tree/nvim-web-devicons", -- optional dependency
		},
		config = true,
	},

	{
		"zbirenbaum/neodim",
		event = "LspAttach",
		opts = {
			hide = {
				virtual_text = false,
				signs = false,
				underline = false,
			},
		},
	},

	{
		"LudoPinelli/comment-box.nvim",
		event = "BufReadPre",
		config = true,
		dev = true,
	},
}
