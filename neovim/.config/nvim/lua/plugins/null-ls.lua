local M = { module = "null-ls" }

function M.setup(options)
	local nls = require("null-ls")

	local fmt = nls.builtins.formatting
	local dgn = nls.builtins.diagnostics
	local cda = nls.builtins.code_actions

	nls.setup({
		debounce = 150,
		save_after_format = false,
		sources = {
			-- Formatting
			fmt.black.with({
				extra_args = { "--line-length=120" },
			}),
			-- fmt.eslint_d,
			fmt.fish_indent,
			fmt.gofmt,
			fmt.prettierd,
			fmt.rustfmt,
			fmt.shfmt,
			fmt.stylua,
			fmt.zigfmt,
			-- fmt.fixjson.with({ filetypes = { "jsonc" } }),
			-- fmt.deno_fmt.with({
			--   filetypes = { "markdown" }, -- only runs `deno fmt` for markdown
			-- }),

			-- Diagnostics
			-- dgn.eslint_d,
			dgn.flake8,
			-- dgn.luacheck.with({
			-- 	extra_args = { "--globals", "vim", "--std", "luajit" },
			-- }),
			dgn.markdownlint,
			dgn.shellcheck,
			-- dgn.selene,

			-- Code Actions
			-- cda.eslint_d,
			cda.gitsigns,
			cda.shellcheck,
		},
		on_attach = options.on_attach,
		root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".nvim.settings.json", ".git"),
	})
end

function M.has_formatter(ft)
	local sources = require("null-ls.sources")
	local available = sources.get_available(ft, "NULL_LS_FORMATTING")
	return #available > 0
end

return M
