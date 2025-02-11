{ config, pkgs, lib, home-manager, ... }:

{
  # Set the desktop environment to GDM and GNOME
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

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
  ];

  # Remove unneeded packages
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
