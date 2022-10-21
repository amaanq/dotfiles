local M = {
	event = "BufEnter",
	requires = {
		"nvim-neotest/neotest-go",
		"mrcjkb/neotest-haskell",
		"haydenmeade/neotest-jest",
		"nvim-neotest/neotest-plenary",
		"nvim-neotest/neotest-python",
		"rouge8/neotest-rust",
	},
}

function M.config()
	require("neotest").setup({
		adapters = {
			-- require("neotest-go"),
			-- require("neotest-haskell"),
			-- require("neotest-jest"),
			-- require("neotest-plenary"),
			-- require("neotest-python")({
			-- 	dap = { justMyCode = false },
			-- }),
			-- require("neotest-rust"),
		},
	})
end

return M
