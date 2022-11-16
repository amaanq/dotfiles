local M = {
	-- event = "User PackerDefered",
	module = "notify",
}

function M.config()
	require("notify").setup({
		level = vim.log.levels.INFO,
		fps = 144,
		max_height = function()
			return math.floor(vim.o.lines * 0.75)
		end,
		max_width = function()
			return math.floor(vim.o.columns * 0.75)
		end,
	})
end

return M
