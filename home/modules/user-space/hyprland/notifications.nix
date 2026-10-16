{ config, lib, ... }:

with lib;

# swaync notification center. The waybar custom/notification button (waybar.nix) toggles
# the panel via swaync-client. Catppuccin Mocha styling.
let
  cfg = config.patrick.home.hyprland;
in
{
  config = mkIf (cfg.enable && cfg.shell == "native") {
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
  };
}
