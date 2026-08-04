{ config, lib, ... }:

with lib;

# hypridle: 300s dim, 330s lock, 350s DPMS off.
let
  cfg = config.patrick.home.hyprland;
in
{
  config = mkIf cfg.enable {
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };
        listener = [
          {
            timeout = 300;
            on-timeout = "brightnessctl -s set 10";
            on-resume = "brightnessctl -r";
          }
          {
            timeout = 330;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 350;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
      };
    };

    # Scoped to hyprland-session.target to avoid locking under COSMIC/KDE.
    systemd.user.services.hypridle.Install.WantedBy = mkForce [ "hyprland-session.target" ];
  };
}
