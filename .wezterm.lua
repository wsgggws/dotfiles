local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

local config = wezterm.config_builder()

-- config.color_scheme = "Catppuccin Mocha"
config.color_scheme = "Dracula (Official)"
config.font_size = 16.5
config.font = wezterm.font("Monaco")
config.front_end = "Software"
config.animation_fps = 2
config.cursor_blink_rate = 800
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.hide_tab_bar_if_only_one_tab = true

config.default_cursor_style = "BlinkingBar"
config.scrollback_lines = 30000

-- 关键：不要用 padding 手动补偿 tmux 底部间隙。
-- 让终端网格贴住窗口底部，剩余像素放到顶部。
config.window_padding = {
	left = 15,
	right = 3,
	top = 0,
	bottom = 3,
}
-- Nightly only: keep the terminal grid anchored to the bottom.
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

wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

return config
