local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

local config = wezterm.config_builder()

-- config.color_scheme = "Catppuccin Mocha"
-- config.color_scheme = "Dracula (Official)"
-- config.color_scheme = "Gruvbox light, soft (base16)"

-- Keep WezTerm in sync with sheepskin.nvim's light palette.
config.colors = {
	foreground = "#342f23",
	background = "#cdb06a",
	cursor_bg = "#683b13",
	cursor_border = "#683b13",
	cursor_fg = "#cdb06a",
	selection_bg = "#b08b47",
	selection_fg = "#252219",
	compose_cursor = "#7d2925",
	split = "#987d48",
	scrollbar_thumb = "#987d48",
	ansi = {
		"#cdb06a",
		"#7d2925",
		"#2d4824",
		"#563e0a",
		"#234861",
		"#613457",
		"#1e4b3b",
		"#342f23",
	},
	brights = {
		"#766b4b",
		"#7d2925",
		"#2d4824",
		"#563e0a",
		"#234861",
		"#613457",
		"#1e4b3b",
		"#252219",
	},
	tab_bar = {
		background = "#c2a25d",
		active_tab = {
			bg_color = "#b08b47",
			fg_color = "#252219",
		},
		inactive_tab = {
			bg_color = "#c5a75f",
			fg_color = "#504a37",
		},
		inactive_tab_hover = {
			bg_color = "#bea058",
			fg_color = "#342f23",
		},
		new_tab = {
			bg_color = "#c5a75f",
			fg_color = "#504a37",
		},
		new_tab_hover = {
			bg_color = "#bea058",
			fg_color = "#342f23",
		},
	},
}
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
