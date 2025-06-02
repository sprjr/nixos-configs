{ config, pkgs, home-manager, ... }:

{
  gtk = {
    enable = true;

    theme = {
      name = "Nordic";
      package = pkgs.nordic;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  home.sessionVariables = {
    GTK_THEME = "Nordic";
    QT_STYLE_OVERRIDE = "gtk"; # makes qt apps follow the gtk theme
    XCURSOR_THEME = "Adwaita";
  };

  home.pointerCursor = {
    git.enable = true;
    name = "Adwaita";
    size = 24;
    package = pkgs.gnome-adwaita-icon-theme;
  };
}
