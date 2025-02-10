{ config, pkgs, home-manager, ... }:

{
  # Ghostty configuration
  home.file.".config/ghostty/config" = {
    text = ''
      font-family = "JetBrains Mono"
      theme = nord
      bold-is-bright = true
      background-opacity = 0.9
      background-blur-radius = 30
      term = screen-256color
      cursor-style = bar
      window-decoration = false
      window-theme = ghostty
      # https://github.com/ghostty-org/ghostty/pull/3742
      # quick-terminal-size = 80%

      ## MacOS-specific Settings
      # quake mode; on MacOS give Ghostty accessibility permissions
      keybind = global:ctrl+grave_accent=toggle_quick_terminal
      macos-titlebar-style = hidden
      quick-terminal-animation-duration = 0.2
    '';
  };
}
