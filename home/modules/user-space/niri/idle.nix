{ config, lib, ... }:

with lib;

# swayidle: 300s dim, 330s lock, 350s DPMS off (mirrors hypridle timeouts).
let
  cfg = config.patrick.home.niri;
in
{
  config = mkIf cfg.enable {
    services.swayidle = {
      enable = true;
      events = [
        {
          event = "before-sleep";
          command = "loginctl lock-session";
        }
        {
          event = "lock";
          command = "pidof swaylock || swaylock -f";
        }
      ];
      timeouts = [
        {
          timeout = 300;
          command = "brightnessctl -s set 10";
          resumeCommand = "brightnessctl -r";
        }
        {
          timeout = 330;
          command = "loginctl lock-session";
        }
        {
          timeout = 350;
          command = "niri msg action power-off-monitors";
          resumeCommand = "niri msg action power-on-monitors";
        }
      ];
    };

    # Scoped to niri-session.target to avoid locking under COSMIC/Hyprland.
    systemd.user.services.swayidle.Install.WantedBy = mkForce [ "niri-session.target" ];
  };
}
