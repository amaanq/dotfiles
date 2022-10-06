local M = {
	event = "BufRead",
}

M.setup = function()
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
		reading_text = "Reading %s",
		workspace_text = "Working on %s",
		line_number_text = "Line %s out of %s",
	})
end

return M
