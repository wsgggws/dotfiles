-- config.color_scheme = "Dracula (Official)"
-- config.color_scheme = "Catppuccin Mocha"
-- config.color_scheme = "Solarized (dark) (terminal.sexy)"
-- config.color_scheme = "tokyonight_night"
-- config.color_scheme = "Catppuccin Latte"
-- config.color_scheme = "Gruvbox light, soft (base16)"
-- config.default_cursor_style = "BlinkingUnderline"

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder and wezterm.config_builder() or {}

-- config.color_scheme = "Catppuccin Mocha"
config.color_scheme = "tokyonight_night"
config.font_size = 16
-- config.font = wezterm.font("Maple Mono Normal NF CN")
config.font = wezterm.font("JetBrains Maple Mono")
config.window_decorations = "RESIZE"
config.default_cursor_style = "BlinkingBar"
config.hide_tab_bar_if_only_one_tab = true
config.scrollback_lines = 30000
config.window_padding = { left = 6, right = 6, top = 16, bottom = 0 }
-- config.window_padding = { left = 6, right = 6, top = 36, bottom = 0 }
config.tab_bar_at_bottom = true
config.window_close_confirmation = "NeverPrompt"
config.window_background_opacity = 0.96

config.keys = {
	-- 取消默认快捷键
	{ key = "L", mods = "CTRL", action = act.DisableDefaultAssignment },
	{ key = "H", mods = "CTRL", action = act.DisableDefaultAssignment },
	{ key = "D", mods = "CTRL", action = "ShowDebugOverlay" },
}

-- wezterm.on("selection_changed", function(window, pane)
-- 	local sel = window:get_selection_text_for_pane(pane, { logical_lines = true })
--
-- 	if sel and #sel > 0 then
-- 		-- 去掉行尾空格，但保留真正的换行
-- 		local cleaned = sel
-- 			:gsub("[ \t]+\n", "\n") -- 清理行尾空格+换行
-- 			:gsub("[ \t]+$", "") -- 清理最后一行结尾
-- 		window:copy_to_clipboard(cleaned)
-- 	end
-- end)
-- 避免复制软换行
config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = wezterm.action.CopyTo("Clipboard", "TrimTrailingWhitespace"),
	},
}

return config
