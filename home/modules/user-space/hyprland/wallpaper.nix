{
  config,
  lib,
  dark-wallpaper-laptop,
  ...
}:

with lib;

# Declarative static wallpaper via hyprpaper, using the same dark-wallpaper-laptop flake
# input COSMIC uses (a single .jpg store path). No runtime randomizer.
let
  cfg = config.patrick.home.hyprland;
  wallpaper = "${dark-wallpaper-laptop}";
in
{
  config = mkIf cfg.enable {
    services.hyprpaper = {
      enable = true;
      settings = {
        ipc = "on";
        splash = false;
        preload = [ wallpaper ];
        wallpaper = [ ",${wallpaper}" ];
      };
    };

    # Started from Hyprland exec-once, not graphical-session.target (foreign-DE safe).
    systemd.user.services.hyprpaper.Install.WantedBy = mkForce [ ];
  };
}
