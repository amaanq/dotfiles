return {
	opt = false,
	config = function()
		local onedarkpro = require("onedarkpro")
		local colors = onedarkpro.get_colors(vim.g.onedarkpro_theme)

		onedarkpro.setup({
			dark_theme = "onedark_vivid",

			highlights = {
				Cursor = {
					fg = "${blue}",
					bg = "${cursorline}",
					style = "bold",
				},
				CursorLineNr = {
					fg = "${blue}",
					bg = "${cursorline}",
					style = "bold",
				},
				TermCursor = {
					fg = "${blue}",
					bg = "${cursorline}",
					style = "bold",
				},
				TabLineSel = {
					fg = "${fg}",
					bg = "${bg}",
					style = "bold",
				},

				-- Dashboard
				dashboardCenter = { fg = colors.blue, style = "bold" },

				-- -- NvimTree
				-- NvimTreeFolderIcon = { fg = colors.yellow },
				-- NvimTreeOpenedFolderName = { fg = colors.blue },
				-- NvimTreeRootFolder = { fg = colors.cyan },

				-- NeoTree
				NeoTreeFileIcon = { fg = colors.blue },
				NeoTreeFileNameOpened = {
					fg = colors.blue,
					style = "italic",
				},
				NeoTreeDirectoryIcon = { fg = colors.blue },
				NeoTreeRootName = { fg = colors.cyan, style = "bold" },
				NeoTreeTitleBar = { fg = "${bg}", bg = colors.blue },
				NeoTreeFloatTitle = { fg = "${bg}", bg = colors.blue },

				-- Indent Blankline
				IndentBlanklineContextChar = { fg = colors.gray },

				-- Telescope
				TelescopeSelection = {
					bg = "${cursorline}",
					fg = colors.blue,
				},
				TelescopeSelectionCaret = { fg = colors.blue },
				TelescopePromptPrefix = { fg = colors.blue },
				-- TelescopeBorder = {
				-- 	bg = "${bg}",
				-- 	fg = "${bg}",
				-- },
				-- TelescopePromptBorder = {
				-- 	bg = "${bg}",
				-- 	fg = "${bg}",
				-- },
				["@constant.builtin.rust"] = { fg = "${cyan}" },
				["@field.rust"] = { fg = "${red}" },
				["@function.builtin.rust"] = { fg = "${cyan}" },
				["@function.macro.rust"] = { fg = "${orange}" },
				["@keyword.rust"] = { fg = "${purple}" },
				["@label.rust"] = { fg = "${white}" },
				["@operator.rust"] = { fg = "${fg}" },
				["@parameter.rust"] = { fg = "${red}", style = "italic" },
				-- ["@punctuation.bracket.rust"] = { fg = "${purple}" },
				["@variable.builtin.rust"] = { fg = "${purple}", style = "italic" },

				["@property.toml"] = { fg = "${purple}" },
			},
			-- ft_highlights = {
			-- 	rust = {
			-- 		TSField = { fg = "${red}" },
			-- 	},
			-- 	-- lua = {
			-- 	-- 	TSField = { fg = "${red}" },
			-- 	-- },
			-- },
			options = {
				bold = true,
				italic = true,
				underline = true,
				cursorline = true,
				-- transparency = true,
				terminal_colors = true,
				-- window_unfocused_color = true,
			},
		})
		vim.cmd("colorscheme onedarkpro")
	end,
}
