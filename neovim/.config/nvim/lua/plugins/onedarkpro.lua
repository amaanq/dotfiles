---@param c  string
local function hexToRgb(c)
	c = string.lower(c)
	return { tonumber(c:sub(2, 3), 16), tonumber(c:sub(4, 5), 16), tonumber(c:sub(6, 7), 16) }
end

---@param foreground string foreground color
---@param background string background color
---@param alpha number|string number between 0 and 1. 0 results in bg, 1 results in fg
local function blend(foreground, background, alpha)
	alpha = type(alpha) == "string" and (tonumber(alpha, 16) / 0xff) or alpha
	local bg = hexToRgb(background)
	local fg = hexToRgb(foreground)

	local blendChannel = function(i)
		local ret = (alpha * fg[i] + ((1 - alpha) * bg[i]))
		return math.floor(math.min(math.max(0, ret), 255) + 0.5)
	end

	return string.format("#%02x%02x%02x", blendChannel(1), blendChannel(2), blendChannel(3))
end

local function darken(hex, amount, bg)
	return blend(hex, bg, amount)
end

local function lighten(hex, amount, fg)
	return blend(hex, fg, amount)
end

return {
	opt = false,
	config = function()
		local onedarkpro = require("onedarkpro")

		onedarkpro.setup({
			dark_theme = "onedark_vivid",

			highlights = {
				Cursor = {
					fg = "${blue}",
					bg = "${blue}",
					style = "bold",
				},
				CursorLineNr = {
					fg = "${blue}",
					bg = "${cursorline}",
					style = "bold",
				},
				TermCursor = {
					fg = "${blue}",
					bg = "${white}",
					style = "bold",
				},
				TabLineSel = {
					fg = "${fg}",
					bg = "${bg}",
					style = "bold",
				},

				-- Dashboard
				dashboardCenter = { fg = "${blue}", style = "bold" },

				-- NeoTree
				NeoTreeDirectoryIcon = { fg = "${yellow}" },
				NeoTreeFileIcon = { fg = "${blue}" },
				NeoTreeFileNameOpened = {
					fg = "${blue}",
					style = "italic",
				},
				NeoTreeFloatTitle = { fg = "${bg}", bg = "${blue}" },
				NeoTreeRootName = { fg = "${cyan}", style = "bold" },
				NeoTreeTabActive = { bg = "${bg}" },
				NeoTreeTabInactive = { bg = "${black}" },
				NeoTreeTitleBar = { fg = "${bg}", bg = "${blue}" },

				-- Indent Blankline
				IndentBlanklineContextChar = { fg = "${gray}" },

				-- Telescope
				TelescopeSelection = {
					bg = "${cursorline}",
					fg = "${blue}",
				},
				TelescopeSelectionCaret = { fg = "${blue}" },
				TelescopePromptPrefix = { fg = "${blue}" },

				DiagnosticUnderlineError = { sp = "${red}", style = "undercurl" },
				DiagnosticUnderlineWarn = { sp = "${yellow}", style = "undercurl" },
				DiagnosticUnderlineInfo = { sp = "${blue}", style = "undercurl" },
				DiagnosticUnderlineHint = { sp = "${cyan}", style = "undercurl" },

				-- DiagnosticVirtualTextError = { bg = darken("${red}", 0.1), fg = "${red}" },

				["@constant.builtin.rust"] = { fg = "${cyan}" },
				["@field.rust"] = { fg = "${red}" },
				["@function.builtin.rust"] = { fg = "${cyan}" },
				["@function.macro.rust"] = { fg = "${orange}" },
				["@keyword.rust"] = { fg = "${purple}" },
				["@label.rust"] = { fg = "${white}" },
				["@operator.rust"] = { fg = "${fg}" },
				["@parameter.rust"] = { fg = "${red}", style = "italic" },
				["@punctuation.bracket.rust"] = { fg = "${purple}" },
				-- ["@variable.builtin.rust"] = { fg = "${purple}", style = "italic" },
				["@property.toml"] = { fg = "${purple}" },
			},
			options = {
				bold = true,
				-- italic = true,
				underline = true,
				cursorline = true,
				terminal_colors = true,
				undercurl = true,
			},
		})
		vim.cmd("colorscheme onedarkpro")
	end,
}
