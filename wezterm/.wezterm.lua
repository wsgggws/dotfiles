-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
-- config.color_scheme = "Catppuccin Mocha"
config.color_scheme = "tokyonight_night"
-- config.color_scheme = "Catppuccin Latte"

config.font_size = 14.5
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true

config.keys = {
	-- CTRL-SHIFT-l activates the debug overlay
	{ key = "L", mods = "CTRL", action = wezterm.action.DisableDefaultAssignment },
	{ key = "H", mods = "CTRL", action = wezterm.action.DisableDefaultAssignment },
	{ key = "D", mods = "CTRL", action = "ShowDebugOverlay" },
}

-- and finally, return the configuration to wezterm
return config
