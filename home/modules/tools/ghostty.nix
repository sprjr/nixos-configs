{ config, pkgs, home-manager, ... }:

{
  # Ghostty configuration
  home.file.".config/ghostty/config" = {
    text = ''
      font-family = "JetBrains Mono"
      theme = nord
      bold-is-bright = true
      background-opacity = 0.7
      background-blur = 20
      term = screen-256color
      cursor-style = bar
      window-decoration = none
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
