{ ... }:

{
  # Palette, and the window opacity derived from stylix.opacity.terminal, come
  # from Stylix. Only the window decoration is declared here.
  programs.alacritty.settings.window = {
    decorations = "none";
    decorations_theme_variant = "dark";
  };
}
