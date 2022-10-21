return {
	keys = "<C-`>",
	event = "BufReadPre",
	config = function()
		require("toggleterm").setup({
			size = 20,
			hide_numbers = true,
			open_mapping = [[<C-`>]],
			shade_filetypes = {},
			shade_terminals = true,
			shading_factor = 0.3, -- the degree by which to darken to terminal colour, default: 1 for dark backgrounds, 3 for light
			start_in_insert = true,
			persist_size = true,
			direction = "float",
			close_on_exit = true,
			shell = vim.o.shell,
		})

		-- Hide number column for
		-- vim.cmd [[au TermOpen * setlocal nonumber norelativenumber]]

		-- Esc twice to get to normal mode
		vim.cmd([[tnoremap <ESC> <C-\><C-N>]])
	end,
}
