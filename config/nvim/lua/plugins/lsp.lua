return {
	{
		"ray-x/lsp_signature.nvim",
		event = "BufEnter",
		enabled = false,
		config = function()
			require("lsp_signature").setup({
				bind = true,
				fix_pos = false,
				auto_close_after = 15, -- close after 15 seconds
				hint_enable = false,
				-- handler_opts = { border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" } },
				toggle_key = "<C-K>",
				select_signature_key = "<M-N>",
			})
		end,
	},

	{
		"lvimuser/lsp-inlayhints.nvim",
		branch = "anticonceal",
		event = "BufEnter",
		config = function()
			require("lsp-inlayhints").setup({
				inlay_hints = {
					highlight = "Comment",
					type_hints = {
						-- prefix = " =>",
					},
				},
			})
		end,
	},

	-- neodev
	{
		"folke/neodev.nvim",
		opts = {
			debug = true,
			experimental = {
				pathStrict = true,
			},
		},
	},

	-- tools
	{
		"williamboman/mason.nvim",
		opts = {
			ensure_installed = {
				"black",
				"csharp-language-server",
				"deno",
				"eslint_d",
				"flake8",
				"isort",
				"luacheck",
				"prettierd",
				"selene",
				"shellcheck",
				"shfmt",
				"stylua",
			},
		},
	},

	{
		"jayp0521/mason-null-ls.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"jose-elias-alvarez/null-ls.nvim",
		},
		config = function()
			require("mason-null-ls").setup({
				automatic_installation = true,
			})
		end,
	},

	{
		"DNLHC/glance.nvim",
		event = "BufReadPre",
		config = function()
			require("glance").setup()
		end,
	},

	-- lsp servers
	{
		"neovim/nvim-lspconfig",
		opts = {
			---@type lspconfig.options
			servers = {
				ansiblels = {},
				asm_lsp = {},
				bashls = {},
				cmake = {},
				csharp_ls = {},
				cssls = {},
				dockerls = {},
				eslint = {},
				golangci_lint_ls = {},
				gopls = {},
				html = {},
				marksman = {},
				pyright = {},
				sumneko_lua = {
					-- cmd = { "/home/folke/projects/lua-language-server/bin/lua-language-server" },
					single_file_support = true,
					settings = {
						Lua = {
							workspace = {
								checkThirdParty = false,
							},
							completion = {
								workspaceWord = true,
								callSnippet = "Both",
							},
							misc = {
								parameters = {
									"--log-level=trace",
								},
							},
							diagnostics = {
								-- enable = false,
								groupSeverity = {
									strong = "Warning",
									strict = "Warning",
								},
								groupFileStatus = {
									["ambiguity"] = "Opened",
									["await"] = "Opened",
									["codestyle"] = "None",
									["duplicate"] = "Opened",
									["global"] = "Opened",
									["luadoc"] = "Opened",
									["redefined"] = "Opened",
									["strict"] = "Opened",
									["strong"] = "Opened",
									["type-check"] = "Opened",
									["unbalanced"] = "Opened",
									["unused"] = "Opened",
								},
								unusedLocalExclude = { "_*" },
							},
							format = {
								enable = false,
								defaultConfig = {
									indent_style = "tab",
									indent_size = "4",
									continuation_indent_size = "4",
								},
							},
						},
					},
				},
				svelte = {},
				-- tailwindcss = {},
				teal_ls = {},
				texlab = {},
				tsserver = {},
				vala_ls = {},
				vimls = {},
				yamlls = {},
				zls = {},
			},
		},
	},

	-- Rust Deps 🚀
	{
		"saecki/crates.nvim",
		event = { "BufRead Cargo.toml" },
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("crates").setup()
		end,
	},

	-- null-ls
	{
		"jose-elias-alvarez/null-ls.nvim",
		config = function()
			local util = require("util")
			local nls = require("null-ls")
			local fmt = nls.builtins.formatting
			local dgn = nls.builtins.diagnostics
			local cda = nls.builtins.code_actions

			nls.setup({
				debounce = 150,
				save_after_format = false,
				sources = {
					-- Formatting
					fmt.asmfmt.with({
						condition = function()
							return util.executable("asmfmt")
						end,
					}),
					fmt.black.with({
						extra_args = { "--line-length=120" },
						condition = function()
							return util.executable("black")
						end,
					}),
					fmt.cbfmt:with({
						condition = function()
							return util.executable("cbfmt")
						end,
					}),
					fmt.clang_format.with({
						condition = function()
							return util.executable("clang-format")
						end,
					}),
					fmt.eslint_d.with({
						condition = function()
							return util.executable("eslint_d")
						end,
					}),
					fmt.gofmt.with({
						condition = function()
							return util.executable("gofmt")
						end,
					}),
					fmt.goimports_reviser.with({
						condition = function()
							return util.executable("goimports-reviser")
						end,
					}),
					fmt.isort.with({
						condition = function()
							return util.executable("isort")
						end,
					}),
					fmt.nginx_beautifier.with({
						condition = function()
							return util.executable("nginxbeautifier")
						end,
					}),
					fmt.pg_format.with({
						condition = function()
							return util.executable("pg_format")
						end,
					}),
					fmt.prettierd.with({
						filetypes = { "graphql", "html", "json", "markdown", "yaml" },
						condition = function()
							return util.executable("prettier")
						end,
					}),
					fmt.rustfmt.with({
						condition = function()
							return util.executable("rustfmt")
						end,
					}),
					fmt.shfmt.with({
						condition = function()
							return util.executable("shfmt")
						end,
					}),
					fmt.stylua.with({
						condition = function()
							return util.executable("stylua")
								and not vim.tbl_isempty(vim.fs.find({ ".stylua.toml", "stylua.toml" }, {
									path = vim.fn.expand("%:p"),
									upward = true,
								}))
						end,
					}),
					fmt.uncrustify.with({
						condition = function()
							return util.executable("uncrustify")
						end,
					}),
					fmt.zigfmt.with({
						condition = function()
							return util.executable("zig")
						end,
					}),

					-- Diagnostics
					dgn.ansiblelint.with({
						condition = function()
							return util.executable("ansible-lint")
						end,
					}),
					dgn.buf.with({
						condition = function()
							return util.executable("buf")
						end,
					}),
					-- dgn.eslint_d,
					dgn.flake8.with({
						-- set config to  ~/.config/flake8
						extra_args = { "--config", "~/.config/flake8", "--max-line-length=88" },
						condition = function()
							return util.executable("flake8")
						end,
					}),
					dgn.golangci_lint.with({
						condition = function()
							return util.executable("golangci-lint")
						end,
					}),
					-- dgn.luacheck.with({
					-- 	extra_args = { "--globals", "vim", "--std", "luajit" },
					-- }),
					dgn.markdownlint.with({
						condition = function()
							return util.executable("markdownlint")
						end,
					}),
					dgn.protolint.with({
						condition = function()
							return util.executable("protolint")
						end,
					}),
					dgn.shellcheck.with({
						condition = function()
							return util.executable("shellcheck")
						end,
					}),
					dgn.selene.with({
						condition = function(utils)
							return utils.root_has_file({ "selene.toml" }) and util.executable("selene")
						end,
					}),
					dgn.write_good.with({
						condition = function()
							return util.executable("write-good")
						end,
					}),
					dgn.zsh,

					-- Code Actions
					cda.eslint_d.with({
						condition = function()
							return util.executable("eslint_d")
						end,
					}),
					cda.gitsigns,
					cda.shellcheck.with({
						condition = function()
							return util.executable("shellcheck")
						end,
					}),
				},
				root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", ".git"),
			})
		end,
	},
}
