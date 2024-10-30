{ config, pkgs, lib, home-manager, ... }:

{
  # Set the desktop environment to GDM and GNOME
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # Enable gnome-settings-daemon udev rules
  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

  # Set icon theme
  environment.systemPackages = [ gnome.adwaita-icon-theme ];

  # Remove unneeded packages
  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
    gedit # text editor
  ]) ++ (with pkgs.gnome; [
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

  # Via Home-Manager, set preferences and extensions
  home-manager.users.patrick = {
    dconf = {
      enable = true;
      settings = {
        "org/gnome/desktop/interface".color-scheme = "prefer-dark";
        "org/gnome/shell" = {
          disable-user-extensions = false;
	  enabled-extensions = with pkgs.gnomeExtensions; [
	    blur-myshell.extensionUuid
	    gsconnect.extensionUuid
	  ];
	};
      };
    };
  };
}
