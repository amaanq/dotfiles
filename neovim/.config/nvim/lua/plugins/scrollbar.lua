local M = {
	event = "BufReadPost",
}

function M.config()
	-- local colors = require("tokyonight.colors").setup()
	local colors = require("onedarkpro").get_colors(vim.g.onedarkpro_theme)

	require("scrollbar").setup({
		handle = {
			color = colors.bg_highlight,
		},
		marks = {
			Search = { color = colors.blue },
			Error = { color = colors.error },
			Warn = { color = colors.warning },
			Info = { color = colors.info },
			Hint = { color = colors.hint },
			Misc = { color = colors.purple },
		},
	})
end

return M
