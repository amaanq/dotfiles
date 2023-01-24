return {
	{ "nvim-treesitter/playground", cmd = "TSPlaygroundToggle" },

	{
		"mfussenegger/nvim-treehopper",
		keys = { { "m", mode = { "o", "x" } } },
		config = function()
			vim.cmd([[
        omap     <silent> m :<C-U>lua require('tsht').nodes()<CR>
        xnoremap <silent> m :lua require('tsht').nodes()<CR>
      ]])
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter-context",
		event = "BufReadPre",
		config = true,
	},

	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = { "p00f/nvim-ts-rainbow" },
		-- init = function()
		-- 	local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
		-- 	parser_config.thrift = {
		-- 		install_info = {
		-- 			url = "~/projects/treesitter/tree-sitter-thrift", -- local path or git repo
		-- 			files = { "src/parser.c" },
		-- 			-- optional entries:
		-- 			branch = "main", -- default branch in case of git repo if different from master
		-- 			generate_requires_npm = false, -- if stand-alone parser without npm dependencies
		-- 			requires_generate_from_grammar = false, -- if folder contains pre-generated src/parser.c
		-- 		},
		-- 	}
		-- 	parser_config.capnp = {
		-- 		install_info = {
		-- 			url = "~/projects/treesitter/tree-sitter-capnp", -- local path or git repo
		-- 			files = { "src/parser.c" },
		-- 			-- optional entries:
		-- 			branch = "master", -- default branch in case of git repo if different from master
		-- 			generate_requires_npm = false, -- if stand-alone parser without npm dependencies
		-- 			requires_generate_from_grammar = false, -- if folder contains pre-generated src/parser.c
		-- 		},
		-- 	}
		-- end,
		opts = {
			ensure_installed = {
				"bash",
				"c",
				"cmake",
				-- "comment", -- comments are slowing down TS bigtime, so disable for now
				"cpp",
				"css",
				"c_sharp",
				"cuda",
				"diff",
				"dockerfile",
				"fish",
				"gitattributes",
				"gitcommit",
				"gitignore",
				"git_rebase",
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
				"query",
				"regex",
				"rust",
				"scss",
				"smali",
				"sql",
				"svelte",
				"teal",
				"toml",
				"tsx",
				"typescript",
				"vala",
				"vhs",
				"vim",
				"vue",
				"yaml",
				"zig",
				"json",
			},
			autopairs = { enable = true },
			highlight = { enable = true },
			-- indent = { enable = false },
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
			query_linter = {
				enable = true,
				use_virtual_text = true,
				lint_events = { "BufWrite", "CursorHold" },
			},
			rainbow = {
				enable = true,
				disable = vim.tbl_filter(function(p)
					local rainbow_enabled = { "c_sharp", "c", "cpp", "dart", "go", "rust" }
					local disable = true
					for _, lang in pairs(rainbow_enabled) do
						if p == lang then
							disable = false
						end
					end
					return disable
				end, require("nvim-treesitter.parsers").available_parsers()),
				colors = {
					"royalblue3",
					"darkorange3",
					"seagreen3",
					"firebrick",
					"darkorchid3",
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
			textsubjects = {
				enable = true,
				keymaps = {
					["."] = "textsubjects-smart",
					[";"] = "textsubjects-container-outer",
				},
			},
		},
	},
}
