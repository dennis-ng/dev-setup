local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Font
config.font = wezterm.font("MesloLGS Nerd Font Mono")
config.font_size=13

-- Window
config.window_decorations = "RESIZE"
config.tab_bar_at_bottom = true

-- Theme
config.color_scheme = 'Kanagawa (Gogh)'
config.colors = {
	tab_bar = {
		inactive_tab = {
			bg_color = '#2A2A37',
			fg_color = '#C8C093',
		},
		active_tab = {
			bg_color = '#DCD7BA',
			fg_color = '#1F1F28',
		},
	},
}
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
	-- Move tab left/right
	{
		key = 'LeftArrow',
		mods = 'CMD | SHIFT',
		action = wezterm.action_callback(function(window, pane)
			local tab = window:active_tab()
			local idx = tab:tab_id()
			-- Find current tab index
			local tabs = window:mux_window():tabs_with_info()
			for _, t in ipairs(tabs) do
				if t.tab:tab_id() == tab:tab_id() then
					if t.index > 0 then
						window:perform_action(wezterm.action.MoveTab(t.index - 1), pane)
					end
					break
				end
			end
		end),
	},
	{
		key = 'RightArrow',
		mods = 'CMD | SHIFT',
		action = wezterm.action_callback(function(window, pane)
			local tab = window:active_tab()
			local tabs = window:mux_window():tabs_with_info()
			for _, t in ipairs(tabs) do
				if t.tab:tab_id() == tab:tab_id() then
					if t.index < #tabs - 1 then
						window:perform_action(wezterm.action.MoveTab(t.index + 1), pane)
					end
					break
				end
			end
		end),
	},
	-- Fix CMD+9: go to tab 9 instead of last tab (default browser-like behavior)
	{
		key = '9',
		mods = 'CMD',
		action = wezterm.action.ActivateTab(8),
	},
	-- CMD+0: go to last tab
	{
		key = '0',
		mods = 'CMD',
		action = wezterm.action.ActivateTab(-1),
	},
	-- Rename current tab
	{
		key = 'r',
		mods = 'CMD | SHIFT',
		action = wezterm.action.PromptInputLine {
			description = 'Enter new name for tab',
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		},
	},
}

-- SSM multiplexed SSH domain
config.ssh_domains = {
	{
		name = 'sec-dev-dennis',
		remote_address = 'i-07edbacc97803026e',
		username = 'ec2-user',
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

-- Dynamic tab scaling based on window size
wezterm.on('window-resized', function(window, pane)
	local dims = window:get_dimensions()
	local overrides = window:get_config_overrides() or {}
	local width = dims.pixel_width
	if width >= 3440 then
		-- Ultrawide 3440x1440
		overrides.tab_max_width = 48
		overrides.window_frame = { font_size = 16 }
	elseif width >= 3024 then
		-- MacBook Retina 3024x1964
		overrides.tab_max_width = 64
		overrides.window_frame = { font_size = 9 }
	elseif width >= 1600 then
		-- FlipGo-A 1600x2000 (portrait)
		overrides.tab_max_width = 36
		overrides.window_frame = { font_size = 11 }
	else
		overrides.tab_max_width = 28
		overrides.window_frame = { font_size = 10 }
	end
	window:set_config_overrides(overrides)
end)

return config
