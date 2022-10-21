local M = {
	module = "rust-tools",
}

function M.setup(options)
	local rt = require("rust-tools")

	local opts = {
		tools = { -- rust-tools options
			--   -- These apply to the default RustSetInlayHints command
			inlay_hints = {
				-- auto = false,

				-- whether to show parameter hints with the inlay hints or not
				show_parameter_hints = true,

				-- prefix for parameter hints
				-- parameter_hints_prefix = "  <-  ",

				-- prefix for all the other hints (type, chaining)
				-- other_hints_prefix = "  =>  ",

				-- The color of the hints
				highlight = "LspCodeLens",
			},

			hover_actions = {
				-- whether the hover action window gets automatically focused
				auto_focus = true,

				-- the border that is used for the hover window
				-- see vim.api.nvim_open_win()
				border = {
					{ "╭", "FloatBorder" },
					{ "─", "FloatBorder" },
					{ "╮", "FloatBorder" },
					{ "│", "FloatBorder" },
					{ "╯", "FloatBorder" },
					{ "─", "FloatBorder" },
					{ "╰", "FloatBorder" },
					{ "│", "FloatBorder" },
				},
			},
		},

		on_attach = function(client, bufnr)
			require("nvim-navic").attach(client, bufnr)
			-- Hover actions
			vim.keymap.set("n", "<C-space>", rt.hover_actions.hover_actions, { buffer = bufnr })
			-- -- Code action groups
			vim.keymap.set("n", "<Leader>a", rt.code_action_group.code_action_group, { buffer = bufnr })
			-- -- Toggle inlay hints
			vim.keymap.set("n", "<C-ii>", ":lua rt.inlay_hints.set()", { buffer = bufnr })
			vim.keymap.set("n", "<C-io>", ":lua rt.inlay_hints.unset()", { buffer = bufnr })
		end,

		-- all the opts to send to nvim-lspconfig
		-- these override the defaults set by rust-tools.nvim
		-- see https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#rust_analyzer
		server = options, -- rust-analyer options

		-- debugging stuff
		dap = {
			adapter = {
				type = "executable",
				command = "lldb-vscode",
				name = "rt_lldb",
			},
		},
	}

	rt.setup(opts)
	rt.inlay_hints.enable()
	rt.inlay_hints.set()
end

return M
