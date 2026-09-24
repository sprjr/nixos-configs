{ config, pkgs, ... }:

{
  # Font, palette, and background opacity (stylix.opacity.terminal) come from
  # Stylix. Window and keybind behaviour is declared here.
  programs.ghostty = {
    enable = true;
    settings = {
      bold-is-bright = true;
      background-blur = 25;
      term = "screen-256color";
      cursor-style = "bar";
      window-decoration = "none";
      window-theme = "ghostty";
      keybind = "global:ctrl+grave_accent=toggle_quick_terminal";
      quick-terminal-position = "top";
      quick-terminal-screen = "mouse";
      quick-terminal-space-behavior = "move";
      # quake mode; on MacOS give Ghostty accessibility permissions
      macos-titlebar-style = "hidden";
      quick-terminal-animation-duration = 0.2;
    };
  };
}
