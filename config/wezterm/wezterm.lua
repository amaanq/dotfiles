---@type Wezterm
local wezterm = require("wezterm")
local colors = require("lua/rose-pine").colors()
local window_frame = require("lua/rose-pine").window_frame()

local config = wezterm.config_builder()

config.alternate_buffer_wheel_scroll_speed = 5
config.audible_bell = "Disabled"
config.bold_brightens_ansi_colors = true
config.colors = colors
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.cursor_blink_rate = 600
config.default_cursor_style = "BlinkingBar"
config.hide_tab_bar_if_only_one_tab = true
config.font = wezterm.font("Berkeley Mono", { weight = "Regular" })
config.font_size = 11
config.force_reverse_video_cursor = true
config.front_end = "WebGpu"
config.initial_cols = 90
config.initial_rows = 30
config.scrollback_lines = 500000
config.webgpu_power_preference = "HighPerformance"
config.window_frame = window_frame

return config
