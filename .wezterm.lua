-- config.color_scheme = "Dracula (Official)"
-- config.color_scheme = "Catppuccin Mocha"
-- config.color_scheme = "Solarized (dark) (terminal.sexy)"
-- config.color_scheme = "tokyonight_night"
-- config.color_scheme = "Catppuccin Latte"
-- config.color_scheme = "Gruvbox light, soft (base16)"
-- config.colors = {
-- 	background = "#EBDBB2",
-- }
-- config.default_cursor_style = "BlinkingUnderline"

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder and wezterm.config_builder() or {}
config.color_scheme = "Catppuccin Mocha"
config.font_size = 17
config.font = wezterm.font("Maple Mono Normal NF CN")
-- config.font = wezterm.font("JetBrains Maple Mono")
config.window_decorations = "RESIZE"
config.default_cursor_style = "BlinkingBar"
config.hide_tab_bar_if_only_one_tab = true
config.scrollback_lines = 30000
config.window_padding = { left = 6, right = 6, top = 16, bottom = 0 }
-- config.window_padding = { left = 6, right = 6, top = 36, bottom = 0 }
config.tab_bar_at_bottom = true
config.window_close_confirmation = "NeverPrompt"

-- config.key_tables = {
-- 	resize_pane = {
-- 		{ key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
-- 		{ key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
-- 		{ key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
-- 		{ key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },
-- 		-- Cancel the mode by pressing escape
-- 		{ key = "Escape", action = "PopKeyTable" },
-- 	},
-- }
--
-- -- Leader Key 设定
-- config.leader = { key = "b", mods = "CTRL", timeout_milliseconds = 1500 }
config.keys = {
	-- 取消默认快捷键
	{ key = "L", mods = "CTRL", action = act.DisableDefaultAssignment },
	{ key = "H", mods = "CTRL", action = act.DisableDefaultAssignment },
	{ key = "D", mods = "CTRL", action = "ShowDebugOverlay" },
	-- -- 分割窗格
	-- { key = "s", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	-- { key = "v", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	-- -- 切换窗格
	-- { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	-- { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	-- { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	-- { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	-- -- 改变 Pane 宽度
	-- { key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
	-- { key = "b", mods = "LEADER", action = act.PaneSelect({ mode = "SwapWithActive" }) }, -- 替换 Pane
	-- { key = "p", mods = "LEADER", action = act.PaneSelect }, -- Select Pane
	-- { key = " ", mods = "LEADER", action = act.TogglePaneZoomState }, -- 最大化 Pane
	-- { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) }, -- 关闭 Pane
}

return config
