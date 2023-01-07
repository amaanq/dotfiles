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
		config = {
			debug = true,
			experimental = {
				pathStrict = true,
			},
			library = {
				runtime = "~/projects/neovim/runtime/",
			},
		},
	},

	-- tools
	{
		"williamboman/mason.nvim",
		ensure_installed = {
			"prettierd",
			"stylua",
			"selene",
			"luacheck",
			"eslint_d",
			"shellcheck",
			"deno",
			"shfmt",
			"black",
			"isort",
			"flake8",
		},
	},

	{
		"jayp0521/mason-null-ls.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"jose-elias-alvarez/null-ls.nvim",
		},
		after = "mason.nvim",
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

	-- json schemas
	"b0o/SchemaStore.nvim",

	-- lsp servers
	{
		"neovim/nvim-lspconfig",
		---@type lspconfig.options
		servers = {
			ansiblels = {},
			-- asm_lsp = {},
			bashls = {},
			cmake = {},
			cssls = {},
			dockerls = {},
			eslint = {},
			golangci_lint_ls = {},
			gopls = {},
			html = {},
			jdtls = {},
			jsonls = {
				on_new_config = function(new_config)
					new_config.settings.json.schemas = new_config.settings.json.schemas or {}
					vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
				end,
				settings = {
					json = {
						format = {
							enable = true,
						},
						validate = { enable = true },
					},
				},
			},
			marksman = {},
			omnisharp = {},
			pyright = {},
			rust_analyzer = {
				settings = {
					["rust-analyzer"] = {
						cargo = {
							allFeatures = true,
						},
						checkOnSave = {
							allFeatures = true,
							command = "clippy",
							extraArgs = { "--no-deps" },
						},
						inlayHints = { locationLinks = false },
						procMacro = {
							ignored = {
								["async-trait"] = { "async_trait" },
								["napi-derive"] = { "napi" },
								["async-recursion"] = { "async_recursion" },
							},
						},
					},
				},
			},
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
								indent_style = "space",
								indent_size = "2",
								continuation_indent_size = "2",
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
			-- vala_ls = {},
			vimls = {},
			yamlls = {},
			zls = {},
		},
	},

	-- clangd++
	{
		"p00f/clangd_extensions.nvim",
		event = "BufReadPre",
		depenencies = {
			{ "folke/neoconf.nvim", cmd = "Neoconf", config = true },
			"hrsh7th/cmp-nvim-lsp",
			"SmiteshP/nvim-navic",
		},
		config = function()
			local function on_attach(client, bufnr)
				require("nvim-navic").attach(client, bufnr)
				require("plugins.lsp.formatting").setup(client, bufnr)
				require("plugins.lsp.keys").setup(client, bufnr)
			end

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities.offsetEncoding = { "utf-16" }

			---@type _.lspconfig.options
			local options = {
				on_attach = on_attach,
				capabilities = capabilities,
				flags = {
					debounce_text_changes = 150,
				},
			}

			require("clangd_extensions").setup({
				server = options,
				extensions = {
					-- defaults:
					-- Automatically set inlay hints (type hints)
					autoSetHints = true,
					-- These apply to the default ClangdSetInlayHints command
					inlay_hints = {
						-- Only show inlay hints for the current line
						only_current_line = false,
						-- Event which triggers a refersh of the inlay hints.
						-- You can make this "CursorMoved" or "CursorMoved,CursorMovedI" but
						-- not that this may cause  higher CPU usage.
						-- This option is only respected when only_current_line and
						-- autoSetHints both are true.
						only_current_line_autocmd = "CursorHold",
						-- whether to show parameter hints with the inlay hints or not
						show_parameter_hints = true,
						-- prefix for parameter hints
						parameter_hints_prefix = "<- ",
						-- prefix for all the other hints (type, chaining)
						other_hints_prefix = "=> ",
						-- whether to align to the length of the longest line in the file
						max_len_align = false,
						-- padding from the left if max_len_align is true
						max_len_align_padding = 1,
						-- whether to align to the extreme right or not
						right_align = false,
						-- padding from the right if right_align is true
						right_align_padding = 7,
						-- The color of the hints
						highlight = "Comment",
						-- The highlight group priority for extmark
						priority = 100,
					},
					ast = {
						-- These are unicode, should be available in any font
						-- role_icons = {
						-- 	type = "🄣",
						-- 	declaration = "🄓",
						-- 	expression = "🄔",
						-- 	statement = ";",
						-- 	specifier = "🄢",
						-- 	["template argument"] = "🆃",
						-- },
						-- kind_icons = {
						-- 	Compound = "🄲",
						-- 	Recovery = "🅁",
						-- 	TranslationUnit = "🅄",
						-- 	PackExpansion = "🄿",
						-- 	TemplateTypeParm = "🅃",
						-- 	TemplateTemplateParm = "🅃",
						-- 	TemplateParamObject = "🅃",
						-- },

						--These require codicons (https://github.com/microsoft/vscode-codicons)
						role_icons = {
							type = "",
							declaration = "",
							expression = "",
							specifier = "",
							statement = "",
							["template argument"] = "",
						},

						kind_icons = {
							Compound = "",
							Recovery = "",
							TranslationUnit = "",
							PackExpansion = "",
							TemplateTypeParm = "",
							TemplateTemplateParm = "",
							TemplateParamObject = "",
						},

						highlights = {
							detail = "Comment",
						},
					},
					memory_usage = {
						border = "none",
					},
					symbol_info = {
						border = "none",
					},
				},
			})
		end,
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
					}),
					fmt.cbfmt:with({
						condition = function()
							return util.executable("cbfmt")
						end,
					}),
					fmt.clang_format,
					fmt.eslint_d,
					fmt.gofmt,
					fmt.goimports_reviser.with({
						condition = function()
							return util.executable("goimports-reviser")
						end,
					}),
					fmt.isort,
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
					fmt.rustfmt,
					fmt.shfmt,
					fmt.stylua.with({
						condition = function()
							return util.executable("stylua")
								and not vim.tbl_isempty(vim.fs.find({ ".stylua.toml", "stylua.toml" }, {
									path = vim.fn.expand("%:p"),
									upward = true,
								}))
						end,
					}),
					fmt.uncrustify,
					fmt.zigfmt,

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
					}),
					dgn.golangci_lint.with({
						condition = function()
							return util.executable("golangci-lint")
						end,
					}),
					-- dgn.luacheck.with({
					-- 	extra_args = { "--globals", "vim", "--std", "luajit" },
					-- }),
					dgn.markdownlint,
					dgn.protolint.with({
						condition = function()
							return util.executable("protolint")
						end,
					}),
					dgn.shellcheck,
					dgn.selene.with({
						condition = function(utils)
							return utils.root_has_file({ "selene.toml" })
						end,
					}),
					dgn.write_good.with({
						condition = function()
							return util.executable("write-good")
						end,
					}),
					dgn.zsh,

					-- Code Actions
					cda.eslint_d,
					cda.gitsigns,
					cda.shellcheck,
				},
				root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", ".git"),
			})
		end,
	},
}
