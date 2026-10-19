{ pkgs, ... }:

# Platform-neutral Stylix settings shared by NixOS (desktop/stylix.nix) and
# nix-darwin (darwin/modules/stylix.nix). Does not import a Stylix module itself.
{
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      # Mapped from the live values: waybar 13px CSS ≈ 10pt, fuzzel/swaync 12pt.
      sizes = {
        desktop = 10;
        applications = 12;
        terminal = 12;
        popups = 12;
      };
    };

    # Pin dark explicitly; the default "either" derives polarity from the image.
    polarity = "dark";

    # Single knob for terminal transparency; matches the live Ghostty value.
    # Alacritty derives its window opacity from this too.
    opacity.terminal = 0.5;
  };
}
