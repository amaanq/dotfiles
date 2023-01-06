return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false,
		config = function()
			require("catppuccin").setup({
				flavour = "mocha", -- mocha, macchiato, frappe, latte
			})
		end,
	},
	{ "ellisonleao/gruvbox.nvim" },
	{
		"marko-cerovac/material.nvim",
		lazy = false,
		config = function()
			-- vim.o.background = "dark"
			local material = require("material")
			material.setup()
			vim.g.material_style = "deep ocean"
		end,
	},
	{ "numToStr/Sakura.nvim", lazy = false },
	{
		"olimorris/onedarkpro.nvim",
		lazy = false,
		config = function()
			local onedarkpro = require("onedarkpro")

			onedarkpro.setup({
				highlights = {
					Cursor = {
						fg = "${blue}",
						bg = "${blue}",
						style = "bold",
					},
					CursorLineNr = {
						fg = "${blue}",
						bg = "${cursorline}",
						style = "bold",
					},
					TermCursor = {
						fg = "${blue}",
						bg = "${white}",
						style = "bold",
					},
					TabLineSel = {
						fg = "${fg}",
						bg = "${bg}",
						style = "bold",
					},

					-- Dashboard
					dashboardCenter = { fg = "${blue}", style = "bold" },

					-- NeoTree
					NeoTreeDirectoryIcon = { fg = "${yellow}" },
					NeoTreeFileIcon = { fg = "${blue}" },
					NeoTreeFileNameOpened = {
						fg = "${blue}",
						style = "italic",
					},
					NeoTreeFloatTitle = { fg = "${bg}", bg = "${blue}" },
					NeoTreeRootName = { fg = "${cyan}", style = "bold" },
					NeoTreeTabActive = { bg = "${bg}" },
					NeoTreeTabInactive = { bg = "${black}" },
					NeoTreeTitleBar = { fg = "${bg}", bg = "${blue}" },

					-- Indent Blankline
					IndentBlanklineContextChar = { fg = "${gray}" },

					-- Telescope
					TelescopeSelection = {
						bg = "${cursorline}",
						fg = "${blue}",
					},
					TelescopeSelectionCaret = { fg = "${blue}" },
					TelescopePromptPrefix = { fg = "${blue}" },

					DiagnosticUnderlineError = { sp = "${red}", style = "undercurl" },
					DiagnosticUnderlineWarn = { sp = "${yellow}", style = "undercurl" },
					DiagnosticUnderlineInfo = { sp = "${blue}", style = "undercurl" },
					DiagnosticUnderlineHint = { sp = "${cyan}", style = "undercurl" },

					-- DiagnosticVirtualTextError = { bg = darken("${red}", 0.1), fg = "${red}" },

					["@constant.builtin.rust"] = { fg = "${cyan}" },
					["@field.rust"] = { fg = "${red}" },
					["@function.builtin.rust"] = { fg = "${cyan}" },
					["@function.macro.rust"] = { fg = "${orange}" },
					["@keyword.rust"] = { fg = "${purple}" },
					["@label.rust"] = { fg = "${white}" },
					["@operator.rust"] = { fg = "${fg}" },
					["@parameter.rust"] = { fg = "${red}", style = "italic" },
					["@punctuation.bracket.rust"] = { fg = "${purple}" },
					-- ["@variable.builtin.rust"] = { fg = "${purple}", style = "italic" },
					["@property.toml"] = { fg = "${purple}" },
				},
				options = {
					bold = true,
					-- italic = true,
					underline = true,
					cursorline = true,
					terminal_colors = true,
					undercurl = true,
				},
			})
		end,
	},
	{ "projekt0n/github-nvim-theme", lazy = false },
	{
		"rebelot/kanagawa.nvim",
		lazy = false,
		config = function()
			local kanagawa = require("kanagawa")
			kanagawa.setup()
		end,
	},
	{
		"Shatur/neovim-ayu",
		lazy = false,
		config = function()
			require("ayu").setup({})
		end,
	},
	{ "shaunsingh/oxocarbon.nvim" },
	{ "LunarVim/horizon.nvim", lazy = false, priority = 1000 },
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,

		config = function()
			local tokyonight = require("tokyonight")
			tokyonight.setup({
				style = "moon",
				sidebars = {
					"qf",
					"vista_kind",
					"terminal",
					"spectre_panel",
					"NeogitStatus",
					"startuptime",
					"Outline",
				},
				on_highlights = function(hl, c)
					hl.CursorLineNr = { fg = c.orange, bold = true }
					local prompt = "#2d3149"
					hl.TelescopeNormal = { bg = c.bg_dark, fg = c.fg_dark }
					hl.TelescopeBorder = { bg = c.bg_dark, fg = c.bg_dark }
					hl.TelescopePromptNormal = { bg = prompt }
					hl.TelescopePromptBorder = { bg = prompt, fg = prompt }
					hl.TelescopePromptTitle = { bg = c.fg_gutter, fg = c.orange }
					hl.TelescopePreviewTitle = { bg = c.bg_dark, fg = c.bg_dark }
					hl.TelescopeResultsTitle = { bg = c.bg_dark, fg = c.bg_dark }
				end,
			})
			tokyonight.load()
		end,
	},
}
