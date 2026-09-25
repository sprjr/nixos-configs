{ pkgs, stylix, ... }:

# Standardized theming for homelab hosts with a desktop environment. One base16
# scheme drives every Stylix target; app-specific palettes are no longer declared
# per app.
#
# Imported by a host's flake module list, alongside desktop/hyprland.nix. Kept at
# NixOS level so the palette reaches home-manager.users.* through Stylix's
# homeManagerIntegration (autoImport and followSystem both default to true).
{
  imports = [ stylix.nixosModules.stylix ];

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

    # Single source for the desktop wallpaper and the lock-screen background, in
    # place of the awww rotation daemon that used to own this.
    image = ../../../home/modules/assets/wallpaper.jpeg;

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

    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus-Dark";
    };

    # Pin dark explicitly; the default "either" derives polarity from the image.
    polarity = "dark";

    # Single knob for terminal transparency; matches the live Ghostty value.
    # Alacritty derives its window opacity from this too.
    opacity.terminal = 0.5;
  };

  # Stylix themes every home-manager user on the host, not just the Hyprland
  # session owner. Its GNOME target auto-enables on Linux, which would overwrite
  # whale/seagull's own desktop background; opt out for all users here because
  # homeManagerIntegration does not propagate target enable flags from the system
  # config.
  home-manager.sharedModules = [
    { stylix.targets.gnome.enable = false; }
  ];
}
