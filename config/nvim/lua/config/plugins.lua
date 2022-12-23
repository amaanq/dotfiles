return {
	"b0o/SchemaStore.nvim",
	{ "folke/neoconf.nvim", cmd = "Neoconf" },
	"folke/neodev.nvim",
	"folke/twilight.nvim",
	"folke/which-key.nvim",
	"jose-elias-alvarez/typescript.nvim",
	"MunifTanjim/nui.nvim",
	"nvim-lua/plenary.nvim",
	{ "rlch/github-notifications.nvim", branch = "hooks" },
	"williamboman/mason-lspconfig.nvim",
	"windwp/nvim-spectre",

	{
		"smjonas/inc-rename.nvim",
		cmd = "IncRename",
		config = function()
			require("inc_rename").setup()
		end,
	},

	{
		"folke/styler.nvim",
		event = "VeryLazy",
		enabled = true,
		config = function()
			require("styler").setup({
				themes = {
					markdown = { colorscheme = "tokyonight-storm" },
					help = { colorscheme = "oxocarbon", background = "dark" },
					-- noice = { colorscheme = "gruvbox", background = "dark" },
				},
			})
		end,
	},

	{
		"folke/drop.nvim",
		event = "VimEnter",
		enabled = true,
		config = function()
			math.randomseed(os.time())
			local theme = ({ "stars", "snow", "xmas" })[math.random(1, 2)]
			require("drop").setup({ theme = theme, max = 60, interval = 50 })
		end,
	},

	{
		"shaunsingh/oxocarbon.nvim",
		lazy = false,
		enabled = true,
	},

	{ "ellisonleao/gruvbox.nvim", lazy = false },

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

	{ "stevearc/dressing.nvim", event = "VeryLazy" },

	-- LSP
	{ "neovim/nvim-lspconfig", name = "lsp" },
	{ "ray-x/lsp_signature.nvim", event = "BufEnter" },

	{
		"lvimuser/lsp-inlayhints.nvim",
		branch = "anticonceal",
		event = "BufEnter",
		config = function()
			require("lsp-inlayhints").setup({
				inlay_hints = {
					highlight = "Comment",
					type_hints = {
						-- prefix = " =>",
					},
				},
			})
		end,
	},

	{
		"SmiteshP/nvim-navic",
		config = function()
			vim.g.navic_silence = true
			require("nvim-navic").setup({
				depth_limit = 5,
				highlight = true,
				icons = {
					File = " ",
					Module = " ",
					Namespace = " ",
					Package = " ",
					Class = " ",
					Method = " ",
					Property = " ",
					Field = " ",
					Constructor = " ",
					Enum = " ",
					Interface = " ",
					Function = " ",
					Variable = " ",
					Constant = " ",
					String = " ",
					Number = " ",
					Boolean = " ",
					Array = " ",
					Object = " ",
					Key = " ",
					Null = " ",
					EnumMember = " ",
					Struct = " ",
					Event = " ",
					Operator = " ",
					TypeParameter = " ",
				},
			})
		end,
	},

	{
		"ThePrimeagen/refactoring.nvim",
		init = function()
			-- prompt for a refactor to apply when the remap is triggered
			vim.keymap.set("v", "<leader>r", function()
				require("refactoring").select_refactor()
			end, { noremap = true, silent = true, expr = false })
		end,
		config = function()
			require("refactoring").setup({})
		end,
	},
	{
		"ThePrimeagen/vim-be-good",
		lazy = false,
		config = function()
			require("vim-be-good")
		end,
	},

	{ "famiu/bufdelete.nvim", cmd = "Bdelete" },

	{
		"simrat39/symbols-outline.nvim",
		cmd = "SymbolsOutline",
		init = function()
			vim.keymap.set("n", "<leader>cs", "<cmd>SymbolsOutline<cr>", { desc = "Symbols Outline" })
		end,
		config = function()
			require("symbols-outline").setup()
		end,
	},

	{
		"MunifTanjim/nui.nvim",
	},

	{
		"danymat/neogen",
		config = function()
			require("neogen").setup({ snippet_engine = "luasnip" })
		end,
	},

	{
		"m-demare/hlargs.nvim",
		enabled = false,
		event = "VeryLazy",
		config = function()
			require("hlargs").setup({
				excluded_argnames = {
					usages = {
						lua = { "self", "use" },
					},
				},
			})
		end,
	},

	-- Theme: icons
	{
		"nvim-tree/nvim-web-devicons",
		config = function()
			require("nvim-web-devicons").setup({ default = true })
		end,
	},

	{
		"norcalli/nvim-terminal.lua",
		ft = "terminal",
		config = function()
			require("terminal").setup()
		end,
	},
	{ "nvim-lua/plenary.nvim" },

	{
		"windwp/nvim-spectre",
	},

	{ "rhysd/git-messenger.vim", event = "BufRead" },
	{ "rhysd/committia.vim", event = "BufRead" },

	{
		"folke/trouble.nvim",
		cmd = { "TroubleToggle", "Trouble" },
		config = function()
			require("trouble").setup({
				auto_open = false,
				use_diagnostic_signs = true, -- en
			})
		end,
	},

	{
		"folke/persistence.nvim",
		event = "BufReadPre",
		config = function()
			require("persistence").setup({
				options = { "buffers", "curdir", "tabpages", "winsize", "help" },
			})
		end,
	},

	{
		"Wansmer/treesj",
		keys = "J",
		config = function()
			require("treesj").setup({ use_default_keymaps = false })
			vim.keymap.set("n", "J", "<cmd>TSJToggle<cr>")
		end,
	},
	{
		"cshuaimin/ssr.nvim",
		-- Calling setup is optional.
		init = function()
			vim.keymap.set({ "n", "x" }, "<leader>cR", function()
				require("ssr").open()
			end, { desc = "Structural Replace" })
		end,
	},

	{
		"dstein64/vim-startuptime",
		cmd = "StartupTime",
		config = function()
			vim.g.startuptime_tries = 10
		end,
	},

	{ "wakatime/vim-wakatime", event = "VeryLazy" },

	{
		"nvim-treesitter/nvim-treesitter-context",
		event = "BufReadPre",
		config = function()
			require("treesitter-context").setup()
		end,
	},

	{
		"folke/zen-mode.nvim",
		cmd = "ZenMode",
		config = function()
			require("zen-mode").setup({
				plugins = {
					gitsigns = true,
					tmux = true,
					kitty = { enabled = false, font = "+2" },
				},
			})
		end,
	},

	{
		"folke/which-key.nvim",
	},

	{
		"andymass/vim-matchup",
		event = "BufReadPost",
		config = function()
			vim.g.matchup_matchparen_offscreen = { method = "status_manual" }
		end,
	},

	-- { "simnalamburt/vim-mundo", event = "BufReadPre", cmd = "MundoToggle" },

	{
		"zbirenbaum/copilot-cmp",
		after = { "copilot.lua" },
		config = function()
			require("copilot_cmp").setup()
		end,
	},
}
