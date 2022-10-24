return {
	opt = false,
	as = "catppuccin",
	config = function()
		require("catppuccin").setup({
			flavour = "mocha", -- mocha, macchiato, frappe, latte
		})
		vim.api.nvim_command("colorscheme catppuccin")
	end,
}
