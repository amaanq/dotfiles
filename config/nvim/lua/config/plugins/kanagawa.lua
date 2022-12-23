return {
	"rebelot/kanagawa.nvim",
	lazy = false,
	config = function()
		local kanagawa = require("kanagawa")
		kanagawa.setup()
	end,
}
