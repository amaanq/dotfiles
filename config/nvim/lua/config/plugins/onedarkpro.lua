return {
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
}
