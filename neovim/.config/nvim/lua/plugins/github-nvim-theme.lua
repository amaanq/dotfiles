return {
	opt = false,
	config = function()
		-- vim.o.background = "dark"
		local gh = require("github-theme")
		gh.setup({
			theme_style = "dark_default",
		})
	end,
}
