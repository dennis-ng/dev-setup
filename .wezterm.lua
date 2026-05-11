local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Font
config.font = wezterm.font("MesloLGS Nerd Font Mono")
config.font_size=13

-- Window
-- config.window_decorations = "RESIZE"
config.tab_bar_at_bottom = true
config.bypass_mouse_reporting_modifiers = 'CMD'
config.audible_bell = 'Disabled'

-- Helper: detect if pane is running inside tmux (cached per pane for 5s)
local tmux_cache = {}
local function is_inside_tmux(pane)
	local ok, result = pcall(function()
		local pane_id = pane:pane_id()
		local now = os.time()
		local cached = tmux_cache[pane_id]
		if cached and (now - cached.time) < 5 then
			return cached.result
		end
		-- Use pane's child PID to walk process tree looking for tmux
		local pid = pane:get_child_pid()
		if not pid then
			tmux_cache[pane_id] = { result = false, time = now }
			return false
		end
		local success, output = wezterm.run_child_process({
			"bash", "-c",
			string.format(
				"pid=%d; while [ \"$pid\" -gt 1 ] 2>/dev/null; do c=$(ps -o comm= -p \"$pid\" 2>/dev/null); case \"$c\" in *tmux*) echo y; exit;; esac; pid=$(ps -o ppid= -p \"$pid\" 2>/dev/null | tr -d ' '); done; echo n",
				pid
			),
		})
		local detected = success and output:match("y") ~= nil
		tmux_cache[pane_id] = { result = detected, time = now }
		return detected
	end)
	if not ok then return false end
	return result
end

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
		action = wezterm.action_callback(function(window, pane)
			if is_inside_tmux(pane) then
				window:perform_action(wezterm.action.SendString('\x02:kill-pane\r'), pane)
			else
				window:perform_action(wezterm.action.CloseCurrentPane { confirm = false }, pane)
			end
		end),
	},
	{
		key = 'd',
		mods = 'CMD',
		action = wezterm.action_callback(function(window, pane)
			if is_inside_tmux(pane) then
				-- tmux prefix + % = vertical split (left/right)
				window:perform_action(wezterm.action.SendString('\x02%'), pane)
			else
				window:perform_action(wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }, pane)
			end
		end),
	},
	{
		key = 'd',
		mods = 'CMD | SHIFT',
		action = wezterm.action_callback(function(window, pane)
			if is_inside_tmux(pane) then
				-- tmux prefix + " = horizontal split (top/bottom)
				window:perform_action(wezterm.action.SendString('\x02"'), pane)
			else
				window:perform_action(wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' }, pane)
			end
		end),
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
		action = wezterm.action_callback(function(window, pane)
			if is_inside_tmux(pane) then
				-- tmux prefix + o = cycle panes (prev not available, use select-pane -t :.-1)
				window:perform_action(wezterm.action.SendString('\x02;'), pane)
			else
				window:perform_action(wezterm.action.ActivatePaneDirection('Prev'), pane)
			end
		end),
	},
	{
		key = ']',
		mods = 'CMD',
		action = wezterm.action_callback(function(window, pane)
			if is_inside_tmux(pane) then
				-- tmux prefix + o = next pane
				window:perform_action(wezterm.action.SendString('\x02o'), pane)
			else
				window:perform_action(wezterm.action.ActivatePaneDirection('Next'), pane)
			end
		end),
	},
	-- CMD+Shift+[ / CMD+Shift+]: rotate panes
	{
		key = '[',
		mods = 'CMD | SHIFT',
		action = wezterm.action_callback(function(window, pane)
			if is_inside_tmux(pane) then
				window:perform_action(wezterm.action.SendString('\x02{'), pane)
			else
				window:perform_action(wezterm.action.RotatePanes('CounterClockwise'), pane)
			end
		end),
	},
	{
		key = ']',
		mods = 'CMD | SHIFT',
		action = wezterm.action_callback(function(window, pane)
			if is_inside_tmux(pane) then
				window:perform_action(wezterm.action.SendString('\x02}'), pane)
			else
				window:perform_action(wezterm.action.RotatePanes('Clockwise'), pane)
			end
		end),
	},
	-- Ctrl+CMD+[ / Ctrl+CMD+]: switch tabs
	{
		key = '[',
		mods = 'CTRL | CMD',
		action = wezterm.action.ActivateTabRelative(-1),
	},
	{
		key = ']',
		mods = 'CTRL | CMD',
		action = wezterm.action.ActivateTabRelative(1),
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
	-- Unstick terminal after SSH disconnect (alt screen, mouse reporting, bracketed paste, cursor)
	-- Soft: preserves scrollback. Use CMD+CTRL+R for hard RIS reset.
	{
		key = 'u',
		mods = 'CMD | CTRL',
		action = wezterm.action.Multiple {
			wezterm.action.SendString('\x1b[?1049l'),  -- exit alt screen
			wezterm.action.SendString('\x1b[?1000l\x1b[?1002l\x1b[?1003l\x1b[?1006l\x1b[?1015l'),  -- mouse off
			wezterm.action.SendString('\x1b[?2004l'),  -- bracketed paste off
			wezterm.action.SendString('\x1b[?25h'),    -- cursor visible
			wezterm.action.SendString('\x1b[?7h'),     -- autowrap on
			wezterm.action.SendString('\x1b[0m'),      -- reset SGR
			wezterm.action.SendString('\x1b>'),         -- exit application keypad
			wezterm.action.SendString('\x1b[?1l'),     -- normal cursor keys
		},
	},
	-- Hard reset (RIS) — clears scrollback too. Nuclear option.
	{
		key = 'r',
		mods = 'CMD | CTRL',
		action = wezterm.action.ResetTerminal,
	},
	-- Rename current tab/window
	{
		key = 'r',
		mods = 'CMD | SHIFT',
		action = wezterm.action_callback(function(window, pane)
			if is_inside_tmux(pane) then
				-- tmux prefix + , = rename window
				window:perform_action(wezterm.action.SendString('\x02,'), pane)
			else
				window:perform_action(wezterm.action.PromptInputLine {
					description = 'Enter new name for tab',
					action = wezterm.action_callback(function(inner_window, inner_pane, line)
						if line then
							inner_window:active_tab():set_title(line)
						end
					end),
				}, pane)
			end
		end),
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
		action = wezterm.action.Multiple {},
	},
	-- Open link only on CMD+left click
	{
		event = { Up = { streak = 1, button = 'Left' } },
		mods = 'CMD',
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
}


-- Bell-based tab highlighting: tabs turn blue when a BEL is received, clear on focus
local bell_panes = {}

wezterm.on('bell', function(window, pane)
	bell_panes[pane:pane_id()] = true
	window:invalidate()
	-- Play sound only if ~/.claude/bell_enabled contains "1"
	local f = io.open(os.getenv('HOME') .. '/.claude/bell_enabled', 'r')
	if f then
		local val = f:read('*l')
		f:close()
		if val and val:match('^1') then
			wezterm.background_child_process({ 'afplay', '/System/Library/Sounds/Glass.aiff' })
		end
	end
end)

wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
	local title = tab.tab_title
	if not title or #title == 0 then
		title = tab.active_pane.title
	end
	title = (tab.tab_index + 1) .. ':' .. title
	if #title > max_width - 2 then
		title = wezterm.truncate_right(title, max_width - 2)
	end

	if tab.is_active then
		bell_panes[tab.active_pane.pane_id] = nil
		return {
			{ Background = { Color = '#DCD7BA' } },
			{ Foreground = { Color = '#1F1F28' } },
			{ Text = ' ' .. title .. ' ' },
		}
	elseif bell_panes[tab.active_pane.pane_id] then
		return {
			{ Background = { Color = '#7E9CD8' } },
			{ Foreground = { Color = '#1F1F28' } },
			{ Text = ' ' .. title .. ' ' },
		}
	else
		return {
			{ Background = { Color = '#2A2A37' } },
			{ Foreground = { Color = '#C8C093' } },
			{ Text = ' ' .. title .. ' ' },
		}
	end
end)

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
