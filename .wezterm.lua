local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

config.color_scheme = "Catppuccin Mocha"
config.font_size = 16.0
config.font = wezterm.font("Monaco")

config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.hide_tab_bar_if_only_one_tab = true

config.default_cursor_style = "BlinkingBar"
config.scrollback_lines = 30000

-- 关键：不要用 padding 手动补偿 tmux 底部间隙。
-- 让终端网格贴住窗口底部，剩余像素放到顶部。
config.window_padding = {
	left = 12,
	right = 3,
	top = 0,
	bottom = 3,
}
-- Nightly only:
-- 让终端网格贴住底部，多余像素放到顶部。
config.window_content_alignment = {
	horizontal = "Left",
	vertical = "Bottom",
}

-- false: 最大化窗口更容易贴住屏幕边缘。
config.use_resize_increments = false

config.keys = {
	{ key = "L", mods = "CTRL", action = act.DisableDefaultAssignment },
	{ key = "H", mods = "CTRL", action = act.DisableDefaultAssignment },
	{ key = "D", mods = "CTRL", action = act.ShowDebugOverlay },
}

return config
