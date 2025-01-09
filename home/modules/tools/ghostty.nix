{ config, pkgs, home-manager, ... }:

{
  # Ghostty configuration
  home.file.".config/ghostty/config" = {
    text = ''
      font-family = ""
      font-family = "JetBrains Mono"
      theme = nord
      bold-is-bright = true
      background-opacity = 0.7
      background-blur-radius = 20
      macos-titlebar-style = hidden
      initial-command = export TERM=screen-256color
#     command = zellij --layout=.config/zellij/layouts/darwin.kdl
      # https://github.com/ghostty-org/ghostty/pull/3742
      # quick-terminal-size = 80%

      # quake mode; on MacOS give Ghostty accessibility permissions
      keybind = global:ctrl+grave_accent=toggle_quick_terminal
      quick-terminal-animation-duration = 0.2
    '';
  };
}
