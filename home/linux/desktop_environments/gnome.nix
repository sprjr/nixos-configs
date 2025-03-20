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
            blur-my-shell.extensionUuid
	    caffeine.extensionUuid
            gsconnect.extensionUuid
	    just-perfection.extensionUuid
            paperwm.extensionUuid
	    search-light.extensionUuid
            space-bar.extensionUuid
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
