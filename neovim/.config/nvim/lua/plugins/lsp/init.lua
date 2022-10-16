---@diagnostic disable: missing-parameter

local M = {
	event = "BufReadPre",
	requires = "jose-elias-alvarez/typescript.nvim",
}

function M.config()
	require("neodev").setup()
	require("mason")
	require("plugins.lsp.diagnostics").setup()
	require("fidget").setup({ text = { spinner = "dots" } })

	local function on_attach(client, bufnr)
		require("nvim-navic").attach(client, bufnr)
		require("plugins.lsp.formatting").setup(client, bufnr)
		require("plugins.lsp.keys").setup(client, bufnr)
	end

	---@type _.lspconfig.options
	local servers = {
		ansiblels = {},
		bashls = {},
		clangd = {},
		cssls = {},
		dockerls = {},
		tsserver = {},
		eslint = {},
		html = {},
		jsonls = {
			settings = {
				json = {
					format = {
						enable = true,
					},
					schemas = require("schemastore").json.schemas(),
					validate = { enable = true },
				},
			},
		},
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
		yamlls = {},
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
					},
					misc = {
						parameters = {
							"--log-level=trace",
						},
					},
					diagnostics = {
						-- enable = false,
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
		teal_ls = {},
		vimls = {},
		-- tailwindcss = {},
	}

	-- local capabilities = vim.lsp.protocol.make_client_capabilities()
	-- capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities)
	local capabilities = require("cmp_nvim_lsp").default_capabilities()
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

		if server ~= "tsserver" and server ~= "rust_analyzer" then
			require("lspconfig")[server].setup(opts)
		elseif server == "rust_analyzer" then
			require("plugins.rust-tools").setup(opts)
		elseif server == "tsserver" then
			require("typescript").setup({ server = opts })
		end
	end

	require("plugins.null-ls").setup(options)
end

return M
