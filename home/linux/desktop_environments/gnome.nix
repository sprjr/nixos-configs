{ config, lib, pkgs, home-manager, ... }:

# This module provides user-level customization of my basic GNOME config as declared in a Nix module
{
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
