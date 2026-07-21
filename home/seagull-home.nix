{
  whale-wallpaper,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    firefox
  ];

  dconf.settings = {
    "org/gnome/desktop/background" = {
      picture-uri = "file://${whale-wallpaper}";
      picture-uri-dark = "file://${whale-wallpaper}";
      picture-options = "zoom";
    };

    "org/gnome/desktop/screensaver" = {
      picture-uri = "file://${whale-wallpaper}";
      picture-options = "zoom";
    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  home.stateVersion = "24.11";
}
