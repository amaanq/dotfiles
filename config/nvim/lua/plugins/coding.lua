return {
	-- better text objects
	{
		"echasnovski/mini.ai",
		keys = { { "[f", desc = "Prev function" }, { "]f", desc = "Next function" } },
		config = function(plugin)
			-- call config of parent spec
			plugin._.super.config()

			-- add treesitter jumping
			local function jump(capture, start, down)
				local rhs = function()
					local parser = vim.treesitter.get_parser()
					if not parser then
						return vim.notify("No treesitter parser for the current buffer", vim.log.levels.ERROR)
					end

					local query = vim.treesitter.get_query(vim.bo.filetype, "textobjects")
					if not query then
						return vim.notify("No textobjects query for the current buffer", vim.log.levels.ERROR)
					end

					local cursor = vim.api.nvim_win_get_cursor(0)

					---@type {[1]:number, [2]:number}[]
					local locs = {}
					for _, tree in ipairs(parser:trees()) do
						for capture_id, node, _ in query:iter_captures(tree:root(), 0) do
							if query.captures[capture_id] == capture then
								local range = { node:range() } ---@type number[]
								local row = (start and range[1] or range[3]) + 1
								local col = (start and range[2] or range[4]) + 1
								if down and row > cursor[1] or (not down) and row < cursor[1] then
									table.insert(locs, { row, col })
								end
							end
						end
					end
					return pcall(vim.api.nvim_win_set_cursor, 0, down and locs[1] or locs[#locs])
				end

				local c = capture:sub(1, 1):lower()
				local lhs = (down and "]" or "[") .. (start and c or c:upper())
				local desc = (down and "Next " or "Prev ")
					.. (start and "start" or "end")
					.. " of "
					.. capture:gsub("%..*", "")
				dd(lhs, desc)
				vim.keymap.set("n", lhs, rhs, { desc = desc })
			end

			for _, capture in ipairs({ "function.outer", "class.outer" }) do
				for _, start in ipairs({ true, false }) do
					for _, down in ipairs({ true, false }) do
						jump(capture, start, down)
					end
				end
			end
		end,
	},

	{
		"danymat/neogen",
		keys = {
			{
				"<leader>cc",
				function()
					require("neogen").generate({})
				end,
				desc = "Neogen Comment",
			},
		},
		config = { snippet_engine = "luasnip" },
	},

	{
		"smjonas/inc-rename.nvim",
		cmd = "IncRename",
		config = true,
	},

	{
		"ThePrimeagen/refactoring.nvim",
		keys = {
			{
				"<leader>r",
				function()
					require("refactoring").select_refactor()
				end,
				mode = "v",
				noremap = true,
				silent = true,
				expr = false,
			},
		},
		config = {},
	},

	-- better yank/paste
	{
		"kkharji/sqlite.lua",
		enabled = function()
			return not jit.os:find("Windows")
		end,
	},
	{
		"gbprod/yanky.nvim",
		event = "BufReadPost",
		config = function()
			require("yanky").setup({
				highlight = {
					timer = 150,
				},
				ring = {
					storage = jit.os:find("Windows") and "shada" or "sqlite",
				},
			})

			vim.keymap.set({ "n", "x" }, "y", "<Plug>(YankyYank)")

			vim.keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
			vim.keymap.set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
			vim.keymap.set({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)")
			vim.keymap.set({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)")

			vim.keymap.set("n", "<c-n>", "<Plug>(YankyCycleForward)")
			vim.keymap.set("n", "<c-p>", "<Plug>(YankyCycleBackward)")

			-- vim.keymap.set("n", "]p", "<Plug>(YankyPutIndentAfterLinewise)")
			-- vim.keymap.set("n", "]P", "<Plug>(YankyPutIndentAfterLinewise)")
			-- vim.keymap.set("n", "[p", "<Plug>(YankyPutIndentBeforeLinewise)")
			-- vim.keymap.set("n", "[P", "<Plug>(YankyPutIndentBeforeLinewise)")
			--
			-- vim.keymap.set("n", ">p", "<Plug>(YankyPutIndentAfterShiftRight)")
			-- vim.keymap.set("n", "<p", "<Plug>(YankyPutIndentAfterShiftLeft)")
			-- vim.keymap.set("n", ">P", "<Plug>(YankyPutIndentBeforeShiftRight)")
			-- vim.keymap.set("n", "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)")

			vim.keymap.set("n", "]p", "<Plug>(YankyPutAfterFilter)")
			vim.keymap.set("n", "[p", "<Plug>(YankyPutBeforeFilter)")
			vim.keymap.set("n", "<leader>P", function()
				require("telescope").extensions.yank_history.yank_history({})
			end, { desc = "Paste from Yanky" })
		end,
	},

	-- better increase/descrease
	{
		"monaqa/dial.nvim",
		keys = {
			{
				"<C-a>",
				function()
					return require("dial.map").inc_normal()
				end,
				expr = true,
			},
			{
				"<C-x>",
				function()
					return require("dial.map").dec_normal()
				end,
				expr = true,
			},
		},
		config = function()
			local augend = require("dial.augend")
			require("dial.config").augends:register_group({
				default = {
					augend.integer.alias.decimal,
					augend.integer.alias.hex,
					augend.date.alias["%Y/%m/%d"],
					augend.constant.alias.bool,
					augend.semver.alias.semver,
				},
			})
		end,
	},

	-- copilot
	{
		"zbirenbaum/copilot.lua",
		event = "VeryLazy",
		config = function()
			vim.defer_fn(function()
				require("copilot").setup({
					panel = {
						enabled = true,
						auto_refresh = true,
						keymap = {
							jump_prev = "[[",
							jump_next = "]]",
							accept = "<CR>",
							refresh = "gr",
							open = "<M-CR>",
						},
					},
					suggestion = {
						enabled = true,
						auto_trigger = true,
						debounce = 75,
						keymap = {
							accept = "<M-l>",
							next = "<M-]>",
							prev = "<M-[>",
							dismiss = "<C-]>",
						},
					},
					filetypes = {
						yaml = false,
						markdown = false,
						help = false,
						gitcommit = false,
						gitrebase = false,
						hgcommit = false,
						svn = false,
						cvs = false,
						["."] = false,
					},
					copilot_node_command = "node", -- Node version must be < 18
					plugin_manager_path = vim.fn.stdpath("data") .. "/site/pack/packer",
					server_opts_overrides = {},
				})
			end, 100)
		end,
	},
	{
		"zbirenbaum/copilot-cmp",
		after = { "copilot.lua" },
		config = function()
			require("copilot_cmp").setup()
		end,
	},

	{
		"simrat39/symbols-outline.nvim",
		keys = { { "<leader>cs", "<cmd>SymbolsOutline<cr>", desc = "Symbols Outline" } },
		config = true,
	},

	{
		"gorbit99/codewindow.nvim",
		enabled = false,
		event = "BufReadPre",
		config = function()
			-- require("as.highlights").plugin("codewindow", {
			-- 	{ CodewindowBorder = { link = "WinSeparator" } },
			-- 	{ CodewindowWarn = { bg = "NONE", fg = { from = "DiagnosticSignWarn", attr = "bg" } } },
			-- 	{ CodewindowError = { bg = "NONE", fg = { from = "DiagnosticSignError", attr = "bg" } } },
			-- })
			local util = require("util")
			local codewindow = require("codewindow")
			util.command("CodewindowToggle", codewindow.toggle_minimap)
			codewindow.setup({
				z_index = 25,
				auto_enable = true,
				exclude_filetypes = {
					"qf",
					"git",
					"help",
					"alpha",
					"gitcommit",
					"NeogitStatus",
					"neo-tree",
					"neo-tree-popup",
					"neotest-summary",
					"NeogitCommitMessage",
					"",
				},
			})
		end,
	},

	{
		"mbbill/undotree",
		cmd = "UndotreeToggle",
		keys = { { "<leader>u", "<cmd>UndotreeToggle<CR>", desc = "UndoTree Toggle" } },
		config = function()
			vim.g.undotree_TreeNodeShape = "◦" -- Alternative: '◉'
			vim.g.undotree_SetFocusWhenToggle = 1
		end,
	},

	{
		"aarondiel/spread.nvim",
		after = "nvim-treesitter",
		keys = {
			{ "gS", "<cmd>lua require('spread').out()<cr>", desc = "Expand (Spread)" },
			{ "gJ", "<cmd>lua require('spread').combine()<cr>", desc = "Combine (Spread)" },
		},
	},
}
