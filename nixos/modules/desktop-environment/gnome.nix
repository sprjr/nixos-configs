{ config, pkgs, lib, home-manager, ... }:

# This module sets up a basic and default GNOME setup for further customization
{
  # Set the desktop environment to GDM and GNOME
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # Enable dconf module
  programs.dconf.enable = true;

  # Setup user-specific extensions
  home-manager.users.patrick = {
    dconf = {
      enable = true;
      settings = {
        "org/gnome/desktop/interface".color-scheme = "prefer-dark";
       "org/gnome/shell" = {
         disable-user-extensions = false;
         enabled-extensions = with pkgs.gnomeExtensions; [
           blur-my-shell@aunetx
           caffeine@patapon.info
           gsconnect@ahdyholmes.github.io
           just-perfection-desktop@just-perfection
           paperwm@paperwm.github.com
           search-light@icedman.github.com
           space-bar@luchrioh
         ];
       };
     };
    };
  };

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
