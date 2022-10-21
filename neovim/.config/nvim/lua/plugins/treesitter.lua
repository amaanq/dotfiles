local M = {
	run = ":TSUpdate",
	event = "User PackerDefered",
	module = "nvim-treesitter",
	requires = {
		"nvim-treesitter/nvim-treesitter-textobjects",
		"RRethy/nvim-treesitter-textsubjects",
		"nvim-treesitter/nvim-treesitter-refactor",
		{ "mfussenegger/nvim-treehopper", module = "tsht" },
		"p00f/nvim-ts-rainbow",
		"windwp/nvim-ts-autotag",
	},
}

function M.init()
	vim.cmd([[
    omap     <silent> m :<C-U>lua require('tsht').nodes()<CR>
    xnoremap <silent> m :lua require('tsht').nodes()<CR>
  ]])
end

function M.config()
	require("nvim-treesitter.configs").setup({
		ensure_installed = {
			"bash",
			"c",
			"cmake",
			-- "comment", -- comments are slowing down TS bigtime, so disable for now
			"cpp",
			"css",
			"cuda",
			"dockerfile",
			"fish",
			"gitattributes",
			"gitignore",
			"go",
			"gomod",
			"graphql",
			"haskell",
			"help",
			"html",
			"http",
			"java",
			"javascript",
			"jsdoc",
			"jsonc",
			"kotlin",
			"latex",
			"lua",
			"make",
			"markdown",
			"markdown_inline",
			"meson",
			"ninja",
			"nix",
			"norg",
			"org",
			"php",
			"proto",
			"python",
			"regex",
			"rust",
			"scss",
			"sql",
			"svelte",
			"toml",
			"tsx",
			"typescript",
			"vala",
			"vim",
			"vue",
			"wgsl",
			"yaml",
			"zig",
			-- "json",
		},
		sync_install = false,
		auto_install = true,
		highlight = { enable = true },
		indent = { enable = false },
		context_commentstring = { enable = true, enable_autocmd = false },
		incremental_selection = {
			enable = false,
			keymaps = {
				init_selection = "<C-n>",
				node_incremental = "<C-n>",
				scope_incremental = "<C-s>",
				node_decremental = "<C-r>",
			},
		},
		refactor = {
			smart_rename = {
				enable = true,
				client = {
					smart_rename = "<leader>cr",
				},
			},
			navigation = {
				enable = true,
				keymaps = {
					-- goto_definition = "gd",
					-- list_definitions = "gnD",
					-- list_definitions_toc = "gO",
					-- goto_next_usage = "<a-*>",
					-- goto_previous_usage = "<a-#>",
				},
			},
		},
		query_linter = {
			enable = true,
			use_virtual_text = true,
			lint_events = { "BufWrite", "CursorHold" },
		},
		textsubjects = {
			enable = true,
			keymaps = {
				["."] = "textsubjects-smart",
				[";"] = "textsubjects-container-outer",
			},
		},
		playground = {
			enable = true,
			disable = {},
			updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
			persist_queries = true, -- Whether the query persists across vim sessions
			keybindings = {
				toggle_query_editor = "o",
				toggle_hl_groups = "i",
				toggle_injected_languages = "t",
				toggle_anonymous_nodes = "a",
				toggle_language_display = "I",
				focus_language = "f",
				unfocus_language = "F",
				update = "R",
				goto_node = "<cr>",
				show_help = "?",
			},
		},
		textobjects = {
			select = {
				enable = true,
				lookahead = true,
				keymaps = {
					-- You can use the capture groups defined in textobjects.scm
					["af"] = "@function.outer",
					["if"] = "@function.inner",
					["ac"] = "@class.outer",
					["ic"] = "@class.inner",
				},
			},
			move = {
				enable = true,
				set_jumps = true, -- whether to set jumps in the jumplist
				goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
				goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
				goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
				goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
			},
			lsp_interop = {
				enable = true,
				peek_definition_code = {
					["gD"] = "@function.outer",
				},
			},
		},
		rainbow = {
			enable = true,
			-- disable = { "json", "jsonc" }, -- list of languages you want to disable the plugin for
			extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
			max_file_lines = 1000, -- Do not enable for files with more than n lines, int
			-- colors = { colors.purple, colors.cyan, colors.orange },
		},
	})
end

return M
