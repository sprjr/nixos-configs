{ config, pkgs, ... }:

{
  home.file.".config/alacritty/alacritty.toml" = {
    text = ''
      # Alacritty Configuration

      # Window configuration
      [window]
      decorations = "none"
      opacity = 0.2
      blur = true
      decorations_theme_variant = "dark"

      # Nord theme
      [colors.primary]
      background = "#2e3440"
      foreground = "#d8dee9"
      dim_foreground = "#a5aaad"

      [colors.cursor]
      text = "#2e3440"
      cursor = "#d8dee9"

      [colors.selection]
      text = "CellForeground"
      background = "#4c566a"

      [colors.search.matches]
      foreground = "CellBackground"
      background = "#88c0d0"

      [colors.search.focused_match]
      foreground = "CellBackground"
      background = "#5e81ac"

      [colors.footer_bar]
      background = "#434c5e"
      foreground = "#d8dee9"

      [colors.hints.start]
      foreground = "#2e3440"
      background = "#ebcb8b"

      [colors.hints.end]
      foreground = "#2e3440"
      background = "#a3be8c"

      [colors.line_indicator]
      foreground = "None"
      background = "None"

      [colors.normal]
      black = "#3b4252"
      red = "#bf616a"
      green = "#a3be8c"
      yellow = "#ebcb8b"
      blue = "#81a1c1"
      magenta = "#b48ead"
      cyan = "#88c0d0"
      white = "#eceff4"

      [colors.dim]
      black = "#373e4d"
      red = "#94545d"
      green = "#809575"
      yellow = "#b29e75"
      blue = "#68809a"
      magenta = "#8c738c"
      cyan = "#6d96a5"
      white = "#aeb3bb"
    '';
  };
}
