local wezterm = require "wezterm"
local act = wezterm.action

local function basename(path)
  if not path or path == "" then
    return ""
  end

  return path:match("([^/\\]+)$") or path
end

local function cwd_basename(cwd)
  if not cwd then
    return ""
  end

  local path = ""

  if type(cwd) == "string" then
    path = cwd
  else
    local ok, file_path = pcall(function()
      return cwd.file_path
    end)
    if ok and file_path and file_path ~= "" then
      path = file_path
    else
      ok, file_path = pcall(function()
        return cwd.path
      end)
      if ok and file_path and file_path ~= "" then
        path = file_path
      else
        path = tostring(cwd)
      end
    end
  end

  if path == "" then
    return ""
  end

  if path:sub(1, 7) == "file://" then
    local parsed = wezterm.url.parse(path)
    if parsed and parsed.file_path then
      path = parsed.file_path
    end
  end

  return basename(path)
end

local function deepest_process_name(info)
  if not info then
    return ""
  end

  local child_ids = {}
  for pid, _ in pairs(info.children or {}) do
    table.insert(child_ids, pid)
  end

  table.sort(child_ids)
  if #child_ids == 0 then
    return basename(info.executable or info.name or ""):lower()
  end

  return deepest_process_name(info.children[child_ids[#child_ids]])
end

local function short_tab_name(tab)
  local pane = tab.active_pane
  local cwd = cwd_basename(pane:get_current_working_dir())
  local title = pane:get_title() or ""

  if cwd ~= "" then
    return cwd
  end

  if title ~= "" and title ~= "wezterm" then
    return title
  end

  local process_info = pane:get_foreground_process_info()
  local process = deepest_process_name(process_info)
  if process == "" then
    process = basename(pane:get_foreground_process_name() or ""):lower()
  end

  if process == "bash" or process == "zsh" or process == "sh" or process == "fish" then
    return "SHELL"
  end

  return "TAB"
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local title = short_tab_name(tab)
  if title == "" then
    title = "TAB"
  end

  if tab.is_active then
    return {
      { Background = { Color = "#a855f7" } },
      { Text = " " .. title .. " " },
    }
  end

  return {
    { Background = { Color = "#6d28d9" } },
    { Text = " " .. title .. " " },
  }
end)

wezterm.on("format-window-title", function(tab, pane, tabs, panes, config)
  return short_tab_name(tab)
end)

return {
  font = wezterm.font("JetBrainsMono Nerd Font"),
  font_size = 14,
  line_height = 0.9,
  color_scheme = "Darcula (base16)",
  window_background_opacity = 0.95,
  scrollback_lines = 10000,
  inactive_pane_hsb = {
    saturation = 0.6,
    brightness = 0.4,
  },
  adjust_window_size_when_changing_font_size = false,
  native_macos_fullscreen_mode = true,
  default_cursor_style = "BlinkingBar",
  cursor_blink_rate = 600,
  colors = {
    foreground = "#f8fafc",
    cursor_bg = "#67e8f9",
    cursor_border = "#67e8f9",
    cursor_fg = "#0f172a",
    split = "#a855f7",
    tab_bar = {
      inactive_tab_edge = "#c4b5fd",
    },
  },
  enable_tab_bar = true,
  initial_cols = 140,
  initial_rows = 40,
  tab_bar_at_bottom = false,
  use_fancy_tab_bar = true,
  show_tabs_in_tab_bar = true,
  show_new_tab_button_in_tab_bar = true,
  hide_tab_bar_if_only_one_tab = false,
  show_tab_index_in_tab_bar = true,
  window_frame = {
    font = wezterm.font { family = "JetBrainsMono Nerd Font", weight = "Bold" },
    font_size = 9.5,
    active_titlebar_bg = "#8b5cf6",
    inactive_titlebar_bg = "#6d28d9",
    active_titlebar_fg = "#fde047",
    inactive_titlebar_fg = "#f5f3ff",
    border_top_height = "0.22cell",
    border_bottom_height = "0.22cell",
  },

  leader = { key = "b", mods = "CTRL", timeout_milliseconds = 1000 },

  keys = {
    { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
    { key = "\"", mods = "LEADER|SHIFT", action = act.SplitVertical { domain = "CurrentPaneDomain" } },
    { key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal { domain = "CurrentPaneDomain" } },
    { key = "x", mods = "LEADER", action = act.CloseCurrentPane { confirm = true } },
    { key = "d", mods = "LEADER", action = act.CloseCurrentPane { confirm = true } },
    { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
    { key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
    { key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
    { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
    { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
    { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
    { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
    { key = "LeftArrow", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
    { key = "DownArrow", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
    { key = "UpArrow", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
    { key = "RightArrow", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
    { key = "r", mods = "LEADER", action = act.ReloadConfiguration },
    { key = ",", mods = "LEADER", action = act.PromptInputLine {
      description = "Rename current tab",
      action = wezterm.action_callback(function(window, pane, line)
        if line and line ~= "" then
          local tab = pane:tab()
          if tab then
            tab:set_title(line)
          end
        end
      end),
    } },
    { key = "o", mods = "LEADER", action = act.ShowLauncherArgs { flags = "FUZZY|WORKSPACES" } },
    {
      key = "c",
      mods = "CTRL",
      action = wezterm.action_callback(function(window, pane)
        local selection = window:get_selection_text_for_pane(pane)
        if selection ~= "" then
          window:perform_action(act.CopyTo("Clipboard"), pane)
        else
          window:perform_action(act.SendKey { key = "c", mods = "CTRL" }, pane)
        end
      end),
    },
    { key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
  },

  window_padding = {
    left = 12,
    right = 12,
    top = 10,
    bottom = 10,
  },

  bypass_mouse_reporting_modifiers = "SHIFT",

  mouse_bindings = {
    {
      event = { Down = { streak = 1, button = "Right" } },
      mods = "NONE",
      action = wezterm.action.Nop,
    },
    {
      event = { Up = { streak = 1, button = "Right" } },
      mods = "NONE",
      action = wezterm.action_callback(function(window, pane)
        local selection = window:get_selection_text_for_pane(pane)

        if selection ~= "" then
          window:perform_action(wezterm.action.CopyTo("Clipboard"), pane)
          window:perform_action(wezterm.action.ClearSelection, pane)
        else
          window:perform_action(wezterm.action.PasteFrom("Clipboard"), pane)
        end
      end),
    },
    {
      event = { Down = { streak = 1, button = "Right" } },
      mods = "SHIFT",
      action = wezterm.action.Nop,
    },
    {
      event = { Up = { streak = 1, button = "Right" } },
      mods = "SHIFT",
      action = wezterm.action_callback(function(window, pane)
        local selection = window:get_selection_text_for_pane(pane)

        if selection ~= "" then
          window:perform_action(wezterm.action.CopyTo("Clipboard"), pane)
          window:perform_action(wezterm.action.ClearSelection, pane)
        else
          window:perform_action(wezterm.action.PasteFrom("Clipboard"), pane)
        end
      end),
    },
    {
      event = { Down = { streak = 1, button = { WheelUp = 1 } } },
      mods = "CTRL",
      action = wezterm.action.IncreaseFontSize,
    },
    {
      event = { Down = { streak = 1, button = { WheelDown = 1 } } },
      mods = "CTRL",
      action = wezterm.action.DecreaseFontSize,
    },
  },
}
