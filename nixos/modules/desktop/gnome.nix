{ config, pkgs, lib, home-manager, ... }:

# This module sets up a basic and default GNOME setup for further customization
# Read more at:
# https://wiki.nixos.org/wiki/GNOME

{
  # Set the desktop environment to GDM and GNOME
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Enable dconf module
  programs.dconf.enable = true;

  # Enable gnome-settings-daemon udev rules
  services.udev.packages = with pkgs; [ gnome-settings-daemon ];

  # Set packages
  environment.systemPackages = with pkgs; [
    adwaita-icon-theme
    gnome-keyring
    gnome-session
    gnome-tweaks
    guake

    # Extensions
    gnomeExtensions.blur-my-shell
    gnomeExtensions.just-perfection
    gnomeExtensions.arc-menu
  ];

  # Remove unneeded software
  services.gnome = {
    core-apps.enable = false;
    core-developer-tools.enable = false;
    games.enable = false;
  };
  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
    gedit # text editor
    cheese # webcam tool
    gnome-music
    gnome-terminal
    epiphany # web browser
    geary # email reader
    evince # doc viewer
    gnome-characters
    totem # video player
    tali # poker game
    iagno # go game
    hitori # sudoku game
    atomix # puzzle game
  ]);
}
