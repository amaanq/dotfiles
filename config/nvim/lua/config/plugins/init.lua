return {
	"b0o/SchemaStore.nvim",
	"folke/twilight.nvim",
	"folke/which-key.nvim",
	"jose-elias-alvarez/typescript.nvim",
	"MunifTanjim/nui.nvim",
	"nvim-lua/plenary.nvim",
	"williamboman/mason-lspconfig.nvim",
	"windwp/nvim-spectre",

	{
		"smjonas/inc-rename.nvim",
		cmd = "IncRename",
		config = true,
	},

	{
		"folke/styler.nvim",
		event = "VeryLazy",
		enabled = true,
		config = {
			themes = {
				markdown = { colorscheme = "tokyonight-storm" },
				help = { colorscheme = "oxocarbon", background = "dark" },
				-- noice = { colorscheme = "gruvbox", background = "dark" },
			},
		},
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

	{ "shaunsingh/oxocarbon.nvim", enabled = true },

	{ "ellisonleao/gruvbox.nvim" },

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

	{
		"stevearc/dressing.nvim",
		init = function()
			---@diagnostic disable-next-line: duplicate-set-field
			vim.ui.select = function(...)
				require("lazy").load({ plugins = { "dressing.nvim" } })
				return vim.ui.select(...)
			end
			---@diagnostic disable-next-line: duplicate-set-field
			vim.ui.input = function(...)
				require("lazy").load({ plugins = { "dressing.nvim" } })
				return vim.ui.input(...)
			end
		end,
	},

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
		keys = {
			{
				"<leader>r",
				function()
					require("refactoring").select_refactor()
				end,
				mode = "v",
				noremap = true,
				silent = true,
				expr = false,
			},
		},
		config = {},
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
		keys = { { "<leader>cs", "<cmd>SymbolsOutline<cr>", desc = "Symbols Outline" } },
		config = true,
	},

	{
		"MunifTanjim/nui.nvim",
	},

	{
		"danymat/neogen",
		keys = {
			{
				"<leader>cc",
				function()
					require("neogen").generate({})
				end,
				desc = "Neogen Comment",
			},
		},
		config = { snippet_engine = "luasnip" },
	},

	{
		"m-demare/hlargs.nvim",
		enabled = false,
		event = "VeryLazy",
		config = {
			excluded_argnames = {
				usages = {
					lua = { "self", "use" },
				},
			},
		},
	},

	-- Theme: icons
	{
		"nvim-tree/nvim-web-devicons",
		config = { default = true },
	},

	{
		"norcalli/nvim-terminal.lua",
		ft = "terminal",
		config = true,
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
		config = {
			auto_open = false,
			use_diagnostic_signs = true, -- en
		},
	},

	{
		"folke/persistence.nvim",
		event = "BufReadPre",
		config = { options = { "buffers", "curdir", "tabpages", "winsize", "help" } },
	},

	{
		"Wansmer/treesj",
		keys = {
			{ "J", "<cmd>TSJToggle<cr>" },
		},
		config = { use_default_keymaps = false },
	},
	{
		"cshuaimin/ssr.nvim",
		-- Calling setup is optional.
		keys = {
			{
				"<leader>cR",
				function()
					require("ssr").open()
				end,
				mode = { "n", "x" },
				desc = "Structural Replace",
			},
		},
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
		config = true,
	},

	{
		"folke/zen-mode.nvim",
		cmd = "ZenMode",
		config = {
			plugins = {
				gitsigns = true,
				tmux = true,
				kitty = { enabled = false, font = "+2" },
			},
		},
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
