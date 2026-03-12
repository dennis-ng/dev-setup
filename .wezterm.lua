local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Font
config.font = wezterm.font("MesloLGS Nerd Font Mono")
config.font_size=13

-- Window
config.window_decorations = "RESIZE"

-- Theme
config.color_scheme = 'Catppuccin Mocha'
-- config.color_scheme = 'OneHalfDark'
-- Key bindings
config.keys = {
	{
		key = 'w',
		mods = 'CMD',
		action = wezterm.action.CloseCurrentPane { confirm = false },
	},
	{
		key = 'd',
		mods = 'CMD',
		action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
	},
	{
		key = 'd',
		mods = 'CMD | SHIFT',
		action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
	},
	-- Rebind CMD-Backspace and Opt-Backspace
	{
		key = 'Backspace',
		mods = 'CMD',
		action = wezterm.action { SendString = '\x15' },
	},
	{
		key = 'Backspace',
		mods = 'OPT',
		action = wezterm.action.SendKey { key = 'w', mods = 'CTRL' },
	},
	-- Rebind OPT-Left, OPT-Right as ALT-b, ALT-f respectively to match Terminal.app behavior
	{
		key = 'LeftArrow',
		mods = 'OPT',
		action = wezterm.action.SendKey {
			key = 'b',
			mods = 'ALT',
		},
	},
	{
		key = 'RightArrow',
		mods = 'OPT',
		action = wezterm.action.SendKey { key = 'f', mods = 'ALT' },
	},
	-- CMD+C: yank in neovim, copy terminal selection otherwise
	{
		key = 'c',
		mods = 'CMD',
		action = wezterm.action_callback(function(window, pane)
			local process = pane:get_foreground_process_name() or ''
			if process:find('nvim') then
				window:perform_action(wezterm.action.SendString('"' .. '+ygv'), pane)
			else
				window:perform_action(wezterm.action.CopyTo('Clipboard'), pane)
			end
		end),
	},
	-- Explicit paste binding
	{
		key = 'v',
		mods = 'CMD',
		action = wezterm.action.PasteFrom('Clipboard'),
	},
	-- CMD+[ / CMD+]: switch focus between panes
	{
		key = '[',
		mods = 'CMD',
		action = wezterm.action.ActivatePaneDirection('Prev'),
	},
	{
		key = ']',
		mods = 'CMD',
		action = wezterm.action.ActivatePaneDirection('Next'),
	},
	-- Shift+Enter: send CSI u sequence so Claude Code recognizes it as newline
	{
		key = 'Enter',
		mods = 'SHIFT',
		action = wezterm.action { SendString = '\x1b[13;2u' },
	},
}

config.mouse_bindings = {
	-- Disable link opening on plain left click
	{
		event = { Up = { streak = 1, button = 'Left' } },
		mods = 'NONE',
		action = wezterm.action.CompleteSelection('ClipboardAndPrimarySelection'),
	},
	-- Open link only on CMD+left click
	{
		event = { Up = { streak = 1, button = 'Left' } },
		mods = 'CMD',
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
}

return config
