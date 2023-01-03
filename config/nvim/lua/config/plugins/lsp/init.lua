local M = {
	"neovim/nvim-lspconfig",
	event = "BufReadPre",
	dependencies = {
		{ "folke/neoconf.nvim", cmd = "Neoconf", config = true },
		{
			"folke/neodev.nvim",
			config = {
				debug = true,
				experimental = {
					pathStrict = true,
				},
			},
		},
		"hrsh7th/cmp-nvim-lsp",
	},
	pin = true,
}

function M.config()
	require("mason")
	require("config.plugins.lsp.diagnostics").setup()

	local function on_attach(client, bufnr)
		if client.name ~= "rust_analyzer" then
			require("lsp-inlayhints").on_attach(client, bufnr, false)
		end
		require("nvim-navic").attach(client, bufnr)
		require("config.plugins.lsp.formatting").setup(client, bufnr)
		require("config.plugins.lsp.keys").setup(client, bufnr)
	end

	---@type lspconfig.options
	local servers = {
		ansiblels = {},
		-- asm_lsp = {},
		bashls = {},
		cmake = {},
		cssls = {},
		dockerls = {},
		tsserver = {},
		-- svelte = {},
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
			single_file_support = true,
			settings = {
				Lua = {
					workspace = {
						checkThirdParty = false,
					},
					completion = {
						workspaceWord = true,
						callSnippet = "Replace",
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
							tab_width = "4",
						},
					},
				},
			},
		},
		-- tailwindcss = {},
		teal_ls = {},
		texlab = {},
		-- vala_ls = {},
		vimls = {},
		yamlls = {},
		zls = {},
	}

	local capabilities = vim.lsp.protocol.make_client_capabilities()
	capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
	capabilities.textDocument.foldingRange = {
		dynamicRegistration = false,
		lineFoldingOnly = true,
	}
	capabilities.offsetEncoding = { "utf-16" }

	---@type _.lspconfig.options
	local options = {
		on_attach = on_attach,
		capabilities = capabilities,
		flags = {
			debounce_text_changes = 150,
		},
	}

	for server, opts in pairs(servers) do
		opts = vim.tbl_deep_extend("force", {}, options, opts or {})
		if server == "tsserver" then
			require("typescript").setup({ server = opts })
		elseif server == "rust_analyzer" then
			opts.server = vim.tbl_deep_extend("force", {}, options, opts.server or {})
			require("config.plugins.rust-tools").setup(opts)
		else
			require("lspconfig")[server].setup(opts)
		end
	end

	require("config.plugins.null-ls").setup(options)
end

return M
