local M = {
	module = "rust-tools",
}

function M.setup(options)
	local rt = require("rust-tools")

	local opts = {
		tools = {
			-- options right now: termopen / quickfix
			-- executor = require("rust-tools/executors").termopen,

			runnables = {
				-- whether to use telescope for selection menu or not
				use_telescope = true,
				-- rest of the opts are forwarded to telescope
			},

			debuggables = {
				-- whether to use telescope for selection menu or not
				use_telescope = true,
				-- rest of the opts are forwarded to telescope
			},

			-- These apply to the default RustSetInlayHints command
			inlay_hints = {
				-- whether to show parameter hints with the inlay hints or not
				show_parameter_hints = true,

				-- prefix for parameter hints
				-- parameter_hints_prefix = "  <-  ",

				-- prefix for all the other hints (type, chaining)
				-- other_hints_prefix = "  =>  ",

				-- whether to align to the length of the longest line in the file
				-- max_len_align = true,

				-- padding from the left if max_len_align is true
				-- max_len_align_padding = 10,

				highlight = "LspCodeLens",
			},

			hover_actions = {
				auto_focus = true,
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
		--
		-- 	settings = {
		-- 		["rust-analyzer"] = {
		-- 			cargo = {
		-- 				allFeatures = true,
		-- 			},
		-- 			checkOnSave = {
		-- 				allFeatures = true,
		-- 				command = "clippy",
		-- 				extraArgs = { "--no-deps" },
		-- 			},
		-- 			procMacro = {
		-- 				ignored = {
		-- 					["async-trait"] = { "async_trait" },
		-- 					["napi-derive"] = { "napi" },
		-- 					["async-recursion"] = { "async_recursion" },
		-- 				},
		-- 			},
		-- 		},
		-- 	},
		--
		server = options,

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
