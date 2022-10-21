return {
	opt = false,
	config = function()
		-- vim.o.background = "dark"
		local kanagawa = require("kanagawa")
		kanagawa.setup()
		vim.cmd("colorscheme kanagawa")
	end,
}
