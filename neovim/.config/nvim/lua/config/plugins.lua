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
	-- list of plugins that should be taken from ~/projects
	-- this is NOT packer functionality!
}

local function plugins(use, plugin)
	-- Packer can manage itself as an optional plugin
	use({ "wbthomason/packer.nvim" })

	use({ "stevearc/dressing.nvim", event = "User PackerDefered" })

	use({
		"rcarriga/nvim-notify",
		event = "User PackerDefered",
		config = function()
			vim.notify = require("notify")
		end,
	})

	-- LSP
	use({ "neovim/nvim-lspconfig", plugin = "lsp" })

	-- DAP
	use({
		"mfussenegger/nvim-dap",
		config = function()
			require("dap")
		end,
	})

	use({ "b0o/SchemaStore.nvim", module = "schemastore" })
	use({ "jose-elias-alvarez/typescript.nvim", module = "typescript" })

	plugin("jose-elias-alvarez/null-ls.nvim")

	use({ "folke/lua-dev.nvim", module = "lua-dev" })
	use({
		"j-hui/fidget.nvim",
		module = "fidget",
		config = function()
			require("fidget").setup({
				window = {
					relative = "editor",
				},
			})
			-- HACK: prevent error when exiting Neovim
			vim.api.nvim_create_autocmd("VimLeavePre", { command = [[silent! FidgetClose]] })
		end,
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
				highlight = true,
				separator = " ",
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

	plugin("simrat39/rust-tools.nvim")

	use({ "famiu/bufdelete.nvim", cmd = "Bdelete" })
	plugin("petertriho/nvim-scrollbar")

	plugin("hrsh7th/nvim-cmp")

	plugin("windwp/nvim-autopairs")

	plugin("L3MON4D3/LuaSnip")

	use({
		"kylechui/nvim-surround",
		event = "BufReadPre",
		config = function()
			require("nvim-surround").setup({})
		end,
	})

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

	use({
		"numToStr/Comment.nvim",
		keys = { "gc", "gcc", "gbc" },
		config = function()
			require("Comment").setup({})
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

	use({ "nvim-treesitter/playground", cmd = "TSHighlightCapturesUnderCursor" })

	-- Theme: color schemes
	-- plugin("folke/tokyonight.nvim")
	plugin("olimorris/onedarkpro.nvim")

	-- Theme: icons
	use({
		"kyazdani42/nvim-web-devicons",
		module = "nvim-web-devicons",
		config = function()
			require("nvim-web-devicons").setup({ default = true })
		end,
	})

	-- Dashboard
	plugin("glepnir/dashboard-nvim")

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

	plugin("michaelb/sniprun")

	plugin("lewis6991/gitsigns.nvim")
	plugin("TimUntersberger/neogit")

	use({ "rlch/github-notifications.nvim", module = "github-notifications" })
	-- Statusline
	plugin("nvim-lualine/lualine.nvim")

	plugin("NvChad/nvim-colorizer.lua")

	-- plugin("kevinhwang91/nvim-ufo")

	use({
		"iamcco/markdown-preview.nvim",
		run = function()
			vim.fn["mkdp#util#install"]()
		end,
		ft = "markdown",
		cmd = { "MarkdownPreview" },
	})

	plugin("phaazon/hop.nvim")

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
			require("persistence").setup()
		end,
	})

	use({
		"dstein64/vim-startuptime",
		cmd = "StartupTime",
		config = function()
			vim.g.startuptime_tries = 10
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

	plugin("folke/todo-comments.nvim")

	use({
		"AckslD/nvim-neoclip.lua",
		event = "TextYankPost",
		module = "telescope._extensions.neoclip",
		requires = { { "kkharji/sqlite.lua", module = "sqlite" } },
		config = function()
			require("neoclip").setup({
				enable_persistent_history = true,
				continuous_sync = true,
			})
		end,
	})

	use({
		"andweeb/presence.nvim",
		event = "BufRead",
		config = function()
			-- require("amaanq.plugins.presence")
			require("presence"):setup({
				auto_update = true,
				main_image = "file",
				log_level = nil,
				debounce_timeout = 10,
				blacklist = { "toggleterm", "zsh" },
				enable_line_number = true,
				buttons = true,
				show_time = true,

				-- Rich Presence text options
				editing_text = "Editing %s",
				file_explorer_text = "Browsing %s",
				git_commit_text = "Committing changes",
				plugin_manager_text = "Managing plugins",
				reading_text = "Reading %s",
				workspace_text = "Working on %s",
				line_number_text = "Line %s out of %s",
			})
		end,
	})

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

	-- use({
	-- 	"natecraddock/sessions.nvim",
	-- 	config = function()
	-- 		require("sessions").setup({
	-- 			events = { "WinEnter" },
	-- 			session_filepath = ".nvim/sessions",
	-- 		})
	-- 	end,
	-- })
end

return packer.setup(config, plugins)
