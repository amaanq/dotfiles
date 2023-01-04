local M = {
	"echasnovski/mini.nvim",
	event = "VeryLazy",
}

function M.ai()
	local ai = require("mini.ai")
	require("mini.ai").setup({
		n_lines = 500,
		-- search_method = "cover_or_next",
		custom_textobjects = {
			o = ai.gen_spec.treesitter({
				a = { "@block.outer", "@conditional.outer", "@loop.outer" },
				i = { "@block.inner", "@conditional.inner", "@loop.inner" },
			}, {}),
			f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
			c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
		},
	})

	local map = function(text_obj, desc)
		for _, side in ipairs({ "left", "right" }) do
			for dir, d in pairs({ prev = "[", next = "]" }) do
				local lhs = d .. (side == "right" and text_obj:upper() or text_obj:lower())
				for _, mode in ipairs({ "n", "x", "o" }) do
					vim.keymap.set(mode, lhs, function()
						ai.move_cursor(side, "a", text_obj, { search_method = dir })
					end, {
						desc = dir .. " " .. desc,
					})
				end
			end
		end
	end

	map("f", "function")
	map("c", "class")
	map("o", "block")
end

function M.config()
	M.ai()
	M.animate()
end

function M.animate()
	local mouse_scrolled = false
	for _, scroll in ipairs({ "Up", "Down" }) do
		local key = "<ScrollWheel" .. scroll .. ">"
		vim.keymap.set("", key, function()
			mouse_scrolled = true
			return key
		end, { expr = true })
	end

	local animate = require("mini.animate")
	vim.go.winwidth = 20
	vim.go.winminwidth = 5

	animate.setup({
		resize = {
			timing = animate.gen_timing.linear({ duration = 100, unit = "total" }),
		},
		scroll = {
			timing = animate.gen_timing.linear({ duration = 150, unit = "total" }),
			subscroll = animate.gen_subscroll.equal({
				predicate = function(total_scroll)
					if mouse_scrolled then
						mouse_scrolled = false
						return false
					end
					return total_scroll > 1
				end,
			}),
		},
	})
end

function M.init()
	vim.keymap.set("n", "<leader>bd", function()
		require("mini.bufremove").delete(0, false)
	end)
	vim.keymap.set("n", "<leader>bD", function()
		require("mini.bufremove").delete(0, true)
	end)
end

return M
