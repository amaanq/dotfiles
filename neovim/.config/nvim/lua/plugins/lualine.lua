local M = { event = "User PackerDefered", requires = "folke/noice.nvim" }

local function clock()
	return " " .. os.date("%H:%M")
end

local function holidays()
	return "🌴🌊"
	-- return "🎅🎄🌟🎁"
end

function M.config()
	local colors = require("onedarkpro").get_colors(vim.g.onedarkpro_theme)
	require("lualine").setup({
		options = {
			theme = "auto",
			section_separators = { left = "", right = "" },
			component_separators = { left = "", right = "" },
			icons_enabled = true,
			globalstatus = true,
			disabled_filetypes = {
				statusline = { "dashboard" },
				winbar = { "dashboard", "neo-tree", "neo-tree-popup" },
			},
		},
		sections = {
			lualine_a = { "mode" },
			lualine_b = { "branch" },
			lualine_c = {
				{ "diagnostics", sources = { "nvim_diagnostic" } },
				{ "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
				{ "filename", path = 1, symbols = { modified = "  ", readonly = "", unnamed = "" } },
			},

			lualine_x = {
				{
					require("noice").api.statusline.message.get_hl,
					cond = require("noice").api.statusline.message.has,
				},
				{
					require("noice").api.statusline.command.get,
					cond = require("noice").api.statusline.command.has,
					color = { fg = colors.blue },
				},
				{
					require("noice").api.statusline.mode.get,
					cond = require("noice").api.statusline.mode.has,
					color = { fg = colors.blue },
				},
				{
					require("noice").api.statusline.search.get,
					cond = require("noice").api.statusline.search.has,
					color = { fg = colors.blue },
				},
				{ require("github-notifications").statusline_notification_count },
				{ holidays },
			},
			lualine_y = { "location" },
			lualine_z = { clock },
		},
		inactive_sections = {
			lualine_a = {},
			lualine_b = {},
			lualine_c = {},

			lualine_x = {},
			lualine_y = {},
			lualine_z = {},
		},
		winbar = {
			lualine_a = {},
			lualine_b = {},
			lualine_c = {
				{ "diagnostics", sources = { "nvim_diagnostic" } },
				{ "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
				{ "filename", path = 1, symbols = { modified = "  ", readonly = "", unnamed = "" } },
				{
					function()
						local navic = require("nvim-navic")
						local ret = navic.get_location()
						return ret:len() > 2000 and "navic error" or ret
					end,
					cond = function()
						local navic = require("nvim-navic")
						return navic.is_available()
					end,
				},
			},
			lualine_x = {},
			lualine_y = {},
			lualine_z = {},
		},
		inactive_winbar = {
			lualine_a = {},
			lualine_b = {},
			lualine_c = {
				{ "diagnostics", sources = { "nvim_diagnostic" } },
				{ "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
				{ "filename", path = 1, symbols = { modified = "  ", readonly = "", unnamed = "" } },
				{
					function()
						local navic = require("nvim-navic")
						return navic.get_location()
					end,
					cond = function()
						local navic = require("nvim-navic")
						return navic.is_available()
					end,
				},
			},
			lualine_x = {},
			lualine_y = {},
			lualine_z = {},
		},
		extensions = { "nvim-tree" },
	})
end

return M
