return {
	opt = false,
	config = function()
		local onedarkpro = require("onedarkpro")
		local colors = require("onedarkpro").get_colors(vim.g.onedarkpro_theme)

		onedarkpro.setup({
			dark_theme = "onedark_vivid",

			highlights = {
				-- Cursor
				CursorLineNr = {
					fg = "${blue}",
					bg = "${cursorline}",
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
			},
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
		-- onedarkpro.load()
		vim.cmd("colorscheme onedarkpro")
	end,
}
