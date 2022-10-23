local M = {
	-- module = "noice",
	-- event = "User PackerDefered",
	opt = false,
}

function M.config()
	require("noice").setup({
		-- debug = true,
		views = {
			cmdline_popup = {
				position = {
					row = 5,
					col = "50%",
				},
				size = {
					width = 60,
					height = "auto",
				},
			},
			popupmenu = {
				relative = "editor",
				position = {
					row = 8,
					col = "50%",
				},
				size = {
					width = 60,
					height = 10,
				},
				border = {
					style = "rounded",
					padding = { 0, 1 },
				},
				win_options = {
					winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
				},
			},
		},
		cmdline = {
			format = {
				IncRename = {
					pattern = "^:%s*IncRename%s+",
					icon = " ",
					conceal = true,
					opts = {
						relative = "cursor",
						size = { min_width = 20 },
						position = { row = -3, col = 0 },
						buf_options = { filetype = "text" },
					},
				},
			},
		},
	})
	-- require("telescope").load_extension("noice")
end

return M
