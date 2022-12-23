return {
	"marko-cerovac/material.nvim",
	lazy = false,
	config = function()
		-- vim.o.background = "dark"
		local material = require("material")
		material.setup()
		vim.g.material_style = "deep ocean"
	end,
}
