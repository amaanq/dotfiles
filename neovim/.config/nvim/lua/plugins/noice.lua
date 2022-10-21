local M = {
	module = "noice",
	event = "VimEnter",
}

function M.config()
	require("noice").setup()
end

return M
