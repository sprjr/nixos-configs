{ config, lib, pkgs, home-manager, ... }:

# This module provides user-level customization of my basic GNOME config as declared in a Nix module
{
  home-manager.users.patrick = {
    dconf = {
      enable = true;
      settings = {
        "org/gnome/desktop/interface".color-scheme = "prefer-dark";
        "org/gnome/shell" = {
          disable-user-extensions = false;
          enabled-extensions = with pkgs.gnomeExtensions; [
            blur-my-shell.3193
	    caffeine.517
            gsconnect.1319
	    just-perfection.3843
            paperwm.6099
	    search-light.5489
            space-bar.5090
          ];
        };
      };
    };
  };
  home.packages = with pkgs.gnomeExtensions; [
    blur-my-shell
    caffeine
    gsconnect
    just-perfection
    paperwm
    search-light
    space-bar
  ];
}
