return {
	"catppuccin/nvim",
	lazy = false,
	name = "catppuccin",
	config = function()
		require("catppuccin").setup({
			flavour = "mocha", -- mocha, macchiato, frappe, latte
		})
	end,
}
