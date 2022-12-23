local M = {
	"ruifm/gitlinker.nvim",
	event = "BufRead",
	dependencies = { "nvim-lua/plenary.nvim" },
}


function M.config()
	require("gitlinker").setup()
end


return M
