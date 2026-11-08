{ pkgs, stylix, ... }:

# Standardized theming for homelab hosts with a desktop environment. One base16
# scheme drives every Stylix target; app-specific palettes are no longer declared
# per app. Scheme, fonts, polarity, and opacity live in stylix-common.nix, shared
# with darwin/modules/stylix.nix.
#
# Imported by a host's flake module list, alongside desktop/hyprland.nix. Kept at
# NixOS level so the palette reaches home-manager.users.* through Stylix's
# homeManagerIntegration (autoImport and followSystem both default to true).
{
  imports = [
    stylix.nixosModules.stylix
    ./stylix-common.nix
  ];

  stylix = {
    # Single source for the desktop wallpaper and the lock-screen background, in
    # place of the awww rotation daemon that used to own this.
    image = ../../../home/modules/assets/wallpaper.jpeg;

    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus-Dark";
    };

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };
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
