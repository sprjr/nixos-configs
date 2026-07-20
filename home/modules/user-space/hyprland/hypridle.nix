{ config, lib, ... }:

with lib;

# hypridle — idle timings carried over from the deprecated hypridle for parity:
# 300s dim brightness, 330s lock, 350s DPMS off. Locking is routed through
# loginctl lock-session -> lock_cmd so it composes with before_sleep_cmd.
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

    # Rebound from graphical-session.target to hyprland-session.target (default.nix) so it
    # never locks the screen or manages idle while the user is in COSMIC/KDE.
    systemd.user.services.hypridle.Install.WantedBy = mkForce [ "hyprland-session.target" ];
  };
}
