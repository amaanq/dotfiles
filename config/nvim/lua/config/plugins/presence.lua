local M = {
	"andweeb/presence.nvim",
	event = "BufRead",
}

M.config = function()
	require("presence"):setup({
		auto_update = true,
		main_image = "file",
		log_level = nil,
		debounce_timeout = 10,
		blacklist = {
			"toggleterm",
			"zsh",
			"zsh*",
			"ToggleTerm",
			"zsh;#toggleterm#1",
			"zsh;#toggleterm#2",
			"zsh;#toggleterm#3",
			"zsh;#toggleterm#4",
			"zsh;#toggleterm#5",
		},
		enable_line_number = true,
		buttons = true,
		show_time = true,

		-- Rich Presence text options
		editing_text = "Editing %s",
		file_explorer_text = "Browsing %s",
		git_commit_text = "Committing changes",
		plugin_manager_text = "Managing plugins",
		reading_text = function(buf_name)
			-- Extract the process name running in toggleterm from the given buffer name
			-- we want to match `zsh;#toggleterm#1`, grab the "zsh" part (aka the beginning before the semicolon) and store it into toggleterm_process
			local toggleterm_process = buf_name:match("([^;]+);#toggleterm#%d+")

			-- Terminal check
			if toggleterm_process == "lazygit" then
				return "Committing files"
			elseif toggleterm_process == "zsh" then
				return "In the terminal"
			end

			-- Lazygit check `59683:lazygit` grab the "lazygit" part (aka the end after the colon) and store it into lazygit_process
			local lazygit_process = buf_name:match("%d+:(.+)")
			if lazygit_process == "lazygit" then
				return "In Lazygit"
			end

			return string.format("Reading %s", buf_name)
		end,
		workspace_text = "Working on %s",
		line_number_text = "Line %s out of %s",
	})
end

return M
