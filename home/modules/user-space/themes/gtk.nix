{ pkgs, config, lib, ... }:

let
  stylix = config.stylix.enable or false;
in
{
  gtk = {
    enable = true;
    colorScheme = "dark";
  }
  // lib.optionalAttrs (!stylix) {
    theme = {
      name = "catppuccin-mocha-blue-standard";
      package = pkgs.catppuccin-gtk.override {
        variant = "mocha";
        accents = [ "blue" ];
      };
    };

    gtk4.theme = config.gtk.theme;

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  qt = {
    enable = true;
  }
  // lib.optionalAttrs (!stylix) {
    platformTheme.name = "gtk3";
  };
}
