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
            gsconnect.extensionUuid
            paperwm.extensionUuid
            space-bar.extensionUuid
	  ];
	};
      };
    };
  };
}
