local wk = require("which-key")

local M = {}

function M.setup(client, bufnr)
	local cap = client.server_capabilities

	-- Mappings.
	local opts = { noremap = true, silent = true, buffer = bufnr }

	local keymap = {
		c = {
			name = "+code",
			r = {
				function()
					require("inc_rename")
					return ":IncRename " .. vim.fn.expand("<cword>")
				end,
				"Rename",
				cond = cap.renameProvider,
				expr = true,
			},
			a = { "<cmd>lua vim.lsp.buf.code_action()<CR>", "Code Action" },
			d = { "<cmd>lua vim.diagnostic.open_float()<CR>", "Line Diagnostics" },
			l = {
				name = "+lsp",
				i = { "<cmd>LspInfo<cr>", "Lsp Info" },
				a = { "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", "Add Folder" },
				r = { "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", "Remove Folder" },
				l = { "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", "List Folders" },
				h = { "<cmd>lua vim.lsp.codelens.run()<CR>", "Run Code Lens" },
				d = { "<cmd>lua vim.lsp.codelens.refresh()<CR>", "Refresh Code Lens" },
			},
		},
		x = {
			d = { "<cmd>Telescope diagnostics<cr>", "Search Diagnostics" },
		},
	}

	if not client.server_capabilities.renameProvider then
		keymap.c.r = nil
	end

	if client.name == "tsserver" then
		keymap.c.o = { "<cmd>:TypescriptOrganizeImports<CR>", "Organize Imports" }
		keymap.c.R = { "<cmd>:TypescriptRenameFile<CR>", "Rename File" }
	end

	local keymap_visual = {
		c = {
			name = "+code",
			a = { ":<C-U>lua vim.lsp.buf.range_code_action()<CR>", "Code Action" },
		},
	}

	local keymap_goto = {
		name = "+goto",
		d = { "<cmd>Telescope lsp_definitions<cr>", "Goto Definition" },
		r = { "<cmd>Telescope lsp_references<cr>", "References" },
		R = { "<cmd>Trouble lsp_references<cr>", "Trouble References" },
		D = { "<Cmd>Telescope lsp_declarations<CR>", "Goto Declaration" },
		s = { "<cmd>lua vim.lsp.buf.signature_help()<CR>", "Signature Help" },
		I = { "<cmd>Telescope lsp_implementations<CR>", "Goto Implementation" },
		t = { "<cmd>Telescope lsp_type_definitions<cr>", "Goto Type Definition" },
	}

	-- vim.keymap.set("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", { noremap = true, silent = true })
	vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
	vim.keymap.set("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", opts)
	vim.keymap.set("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", opts)
	vim.keymap.set("n", "[e", "<cmd>lua vim.diagnostic.goto_prev({severity = vim.diagnostic.severity.ERROR})<CR>", opts)
	vim.keymap.set("n", "]e", "<cmd>lua vim.diagnostic.goto_next({severity = vim.diagnostic.severity.ERROR})<CR>", opts)
	vim.keymap.set(
		"n",
		"[w",
		"<cmd>lua vim.diagnostic.goto_prev({severity = vim.diagnostic.severity.WARNING})<CR>",
		opts
	)
	vim.keymap.set(
		"n",
		"]w",
		"<cmd>lua vim.diagnostic.goto_next({severity = vim.diagnostic.severity.WARNING})<CR>",
		opts
	)

	-- Set some keybinds conditional on server capabilities
	if client.server_capabilities.documentFormatting then
		keymap.c.f = { "<cmd>lua vim.lsp.buf.formatting()<CR>", "Format Document" }
	elseif client.server_capabilities.documentRangeFormatting then
		keymap_visual.c.f = { "<cmd>lua vim.lsp.buf.range_formatting()<CR>", "Format Range" }
	end

	wk.register(keymap, { buffer = bufnr, prefix = "<leader>" })
	wk.register(keymap_visual, { buffer = bufnr, prefix = "<leader>", mode = "v" })
	wk.register(keymap_goto, { buffer = bufnr, prefix = "g" })
end

return M
