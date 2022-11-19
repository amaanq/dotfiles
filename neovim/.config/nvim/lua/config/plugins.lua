local packer = require("util.packer")

local config = {
	profile = {
		enable = true,
		threshold = 0, -- the amount in ms that a plugins load time must be over for it to be included in the profile
	},
	display = {
		open_fn = function()
			return require("packer.util").float({ border = "single" })
		end,
	},
	opt_default = true,
	auto_reload_compiled = false,
}

local function plugins(use, plugin)
	-- Packer can manage itself as an optional plugin
	use({ "wbthomason/packer.nvim" })
	plugin("folke/noice.nvim")

	use({
		"smjonas/inc-rename.nvim",
		cmd = "IncRename",
		module = "inc_rename",
		config = function()
			require("inc_rename").setup()
		end,
	})

	use({
		"folke/styler.nvim",
		opt = false,
		event = "User PackerDefered",
		config = function()
			require("styler").setup({
				themes = {
					markdown = { colorscheme = "tokyonight-storm" },
					help = { colorscheme = "catppuccin-mocha", background = "dark" },
					-- noice = { colorscheme = "gruvbox", background = "dark" },
				},
			})
		end,
	})

	use({
		"folke/drop.nvim",
		event = "VimEnter",
		config = function()
			math.randomseed(os.time())
			local theme = ({ "stars", "snow" })[math.random(1, 2)]
			require("drop").setup({ theme = theme, max = 60, interval = 50 })
		end,
	})

	use({
		opt = false,
		"ellisonleao/gruvbox.nvim",
	})

	use({
		"folke/paint.nvim",
		event = "BufReadPre",
		config = function()
			require("paint").setup()
		end,
	})
	plugin("toppair/peek.nvim")

	plugin("b0o/incline.nvim")
	plugin("gbprod/yanky.nvim")

	use({ "stevearc/dressing.nvim", event = "User PackerDefered" })

	plugin("rcarriga/nvim-notify")

	-- LSP
	use({ "neovim/nvim-lspconfig", plugin = "lsp" })
	use({ "ray-x/lsp_signature.nvim", event = "BufEnter" })

	-- use({
	-- 	"lvimuser/lsp-inlayhints.nvim",
	-- 	branch = "anticonceal",
	-- 	event = "BufEnter",
	-- 	config = function()
	-- 		require("lsp-inlayhints").setup({
	-- 			inlay_hints = {
	-- 				highlight = "Comment",
	-- 				type_hints = {
	-- 					-- prefix = " =>",
	-- 				},
	-- 			},
	-- 		})
	-- 	end,
	-- })

	use({ "b0o/SchemaStore.nvim", module = "schemastore" })
	use({ "jose-elias-alvarez/typescript.nvim", module = "typescript" })

	plugin("jose-elias-alvarez/null-ls.nvim")

	use({ "folke/neodev.nvim", module = "neodev" })
	use({
		"folke/neoconf.nvim",
		module = "neoconf",
		cmd = "Neoconf",
	})

	plugin("anuvyklack/windows.nvim")

	plugin("monaqa/dial.nvim")

	plugin("williamboman/mason.nvim")
	use({
		"williamboman/mason-lspconfig.nvim",
		module = "mason-lspconfig",
	})

	use({
		"SmiteshP/nvim-navic",
		module = "nvim-navic",
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
	})

	use({
		"ThePrimeagen/refactoring.nvim",
		module = "refactoring",
		config = function()
			require("refactoring").setup({})
		end,
		setup = function()
			-- prompt for a refactor to apply when the remap is triggered
			vim.keymap.set("v", "<leader>r", function()
				require("refactoring").select_refactor()
			end, { noremap = true, silent = true, expr = false })
		end,
	})
	use({
		"ThePrimeagen/vim-be-good",
		module = "vim-be-good",
		opt = false,
		config = function()
			require("vim-be-good")
		end,
	})

	use({
		"saecki/crates.nvim",
		event = { "BufRead Cargo.toml" },
		requires = { "nvim-lua/plenary.nvim" },
		config = function()
			require("crates").setup()
		end,
	})

	use({ "famiu/bufdelete.nvim", cmd = "Bdelete" })

	plugin("simrat39/rust-tools.nvim")

	plugin("petertriho/nvim-scrollbar")

	plugin("hrsh7th/nvim-cmp")

	plugin("L3MON4D3/LuaSnip")

	use({
		"simrat39/symbols-outline.nvim",
		cmd = { "SymbolsOutline" },
		config = function()
			require("symbols-outline").setup()
		end,
		setup = function()
			vim.keymap.set("n", "<leader>cs", "<cmd>SymbolsOutline<cr>", { desc = "Symbols Outline" })
		end,
	})

	plugin("nvim-neo-tree/neo-tree.nvim")

	use({
		"MunifTanjim/nui.nvim",
		module = "nui",
	})

	use({
		"danymat/neogen",
		module = "neogen",
		config = function()
			require("neogen").setup({ snippet_engine = "luasnip" })
		end,
	})

	plugin("nvim-treesitter/nvim-treesitter")

	use({ "nvim-treesitter/playground", cmd = { "TSHighlightCapturesUnderCursor", "TSPlaygroundToggle" } })

	use({
		"m-demare/hlargs.nvim",
		event = "User PackerDefered",
		config = function()
			require("hlargs").setup({
				excluded_argnames = {
					usages = {
						lua = { "self", "use" },
					},
				},
			})
		end,
	})

	plugin("nvim-neotest/neotest")

	-- Theme: color schemes (uncomment the one to use :))
	-- plugin("olimorris/onedarkpro.nvim")
	plugin("folke/tokyonight.nvim")
	-- plugin("rebelot/kanagawa.nvim")
	-- plugin("projekt0n/github-nvim-theme")
	-- plugin("marko-cerovac/material.nvim")
	-- plugin("numToStr/Sakura.nvim")
	use({
		"catppuccin/nvim",
		opt = false,
		as = "catppuccin",
		config = function()
			require("catppuccin").setup({
				flavour = "mocha", -- mocha, macchiato, frappe, latte
			})
			-- vim.api.nvim_command("colorscheme catppuccin")
		end,
	})

	-- Theme: icons
	use({
		"kyazdani42/nvim-web-devicons",
		module = "nvim-web-devicons",
		config = function()
			require("nvim-web-devicons").setup({ default = true })
		end,
	})

	use({
		"norcalli/nvim-terminal.lua",
		ft = "terminal",
		config = function()
			require("terminal").setup()
		end,
	})
	use({ "nvim-lua/plenary.nvim", module = "plenary" })

	use({
		"windwp/nvim-spectre",
		module = "spectre",
	})

	-- Fuzzy finder
	plugin("nvim-telescope/telescope.nvim")

	plugin("lukas-reineke/indent-blankline.nvim")
	plugin("akinsho/nvim-bufferline.lua")

	-- Terminal
	plugin("akinsho/nvim-toggleterm.lua")

	-- Smooth Scrolling
	plugin("karb94/neoscroll.nvim")

	plugin("edluffy/specs.nvim")

	plugin("echasnovski/mini.nvim")

	plugin("lewis6991/gitsigns.nvim")
	plugin("TimUntersberger/neogit")
	use({ "rhysd/git-messenger.vim", event = "BufRead" })
	use({ "rhysd/committia.vim", event = "BufRead" })
	use({
		"ruifm/gitlinker.nvim",
		event = "BufRead",
		requires = "nvim-lua/plenary.nvim",
		config = function()
			require("gitlinker").setup()
		end,
	})

	plugin("mfussenegger/nvim-dap")

	use({ "rlch/github-notifications.nvim", module = "github-notifications", branch = "hooks" })

	-- Statusline
	plugin("nvim-lualine/lualine.nvim")

	plugin("NvChad/nvim-colorizer.lua")

	plugin("kevinhwang91/nvim-ufo")

	use({
		"ellisonleao/glow.nvim",
		run = "GlowInstall",
		ft = "markdown",
		event = "BufReadPre",
		config = function()
			vim.cmd("autocmd FileType markdown setlocal wrap")

			require("glow").setup({
				style = "dark",
				width = 120,
			})
		end,
	})

	plugin("phaazon/hop.nvim")

	plugin("ggandor/leap.nvim")

	use({
		"folke/trouble.nvim",
		event = "BufReadPre",
		module = "trouble",
		cmd = { "TroubleToggle", "Trouble" },
		config = function()
			require("trouble").setup({
				auto_open = false,
				use_diagnostic_signs = true, -- en
			})
		end,
	})

	use({
		"folke/persistence.nvim",
		event = "BufReadPre",
		module = "persistence",
		config = function()
			require("persistence").setup({
				options = { "buffers", "curdir", "tabpages", "winsize", "help" },
			})
		end,
	})

	use({
		"dstein64/vim-startuptime",
		cmd = "StartupTime",
		config = function()
			vim.g.startuptime_tries = 10
		end,
	})
	use({ "wakatime/vim-wakatime", event = "User PackerDefered" })

	use({
		"nvim-treesitter/nvim-treesitter-context",
		event = "BufReadPre",
		config = function()
			require("treesitter-context").setup()
		end,
	})

	use({ "folke/twilight.nvim", module = "twilight" })
	use({
		"folke/zen-mode.nvim",
		cmd = "ZenMode",
		config = function()
			require("zen-mode").setup({
				plugins = { gitsigns = true, tmux = true, kitty = { enabled = false, font = "+2" } },
			})
		end,
	})

	plugin("pwntester/octo.nvim")

	plugin("andweeb/presence.nvim")

	plugin("folke/todo-comments.nvim")

	use({
		"folke/which-key.nvim",
		module = "which-key",
	})

	plugin("sindrets/diffview.nvim")

	plugin("RRethy/vim-illuminate")

	plugin("nvim-neorg/neorg")

	use({
		"andymass/vim-matchup",
		event = "BufReadPost",
		config = function()
			vim.g.matchup_matchparen_offscreen = { method = "status_manual" }
		end,
	})

	use({ "simnalamburt/vim-mundo", event = "BufReadPre", cmd = "MundoToggle" })

	plugin("zbirenbaum/copilot.lua")

	use({
		"zbirenbaum/copilot-cmp",
		after = { "copilot.lua" },
		config = function()
			require("copilot_cmp").setup()
		end,
	})
end

return packer.setup(config, plugins)
