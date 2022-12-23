local M = {
	"saecki/crates.nvim",
	event = { "BufRead Cargo.toml" },
	dependencies = { "nvim-lua/plenary.nvim" },
}

function M.config()
	require("crates").setup()
end

return M
