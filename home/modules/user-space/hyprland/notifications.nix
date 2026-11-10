{ config, lib, pkgs, hokum, ... }:

with lib;

# swaync notification center. The waybar custom/notification button (waybar.nix) toggles
# the panel via swaync-client. Catppuccin Mocha styling.
let
  cfg = config.patrick.home.hyprland;
  hokumPkg = hokum.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  config = mkIf (cfg.enable && cfg.shell == "native") (mkMerge [
    (mkIf (cfg.notifications.daemon == "swaync") {
      services.swaync = {
        enable = true;
        settings = {
          positionX = "right";
          positionY = "top";
          control-center-width = 380;
          notification-window-width = 380;
          timeout = 8;
          timeout-low = 4;
          timeout-critical = 0;
          fit-to-screen = true;
          keyboard-shortcuts = true;
          image-visibility = "when-available";
          widgets = [
            "title"
            "dnd"
            "notifications"
          ];
        };
      };

      # Scoped to hyprland-session.target.
      systemd.user.services.swaync.Install.WantedBy = mkForce [ "hyprland-session.target" ];
    })

    (mkIf (cfg.notifications.daemon == "hokum") {
      systemd.user.services.hokum = {
        Unit = {
          Description = "Hokum control center and notification daemon";
          PartOf = [ "hyprland-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${hokumPkg}/bin/hokum service";
          Restart = "on-failure";
          RestartSec = 2;
        };
        Install.WantedBy = [ "hyprland-session.target" ];
      };
    })
  ]);
}
