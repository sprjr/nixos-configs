{ config, lib, ... }:

with lib;

# swaync notification center. The waybar custom/notification button (waybar.nix) toggles
# the panel via swaync-client. Catppuccin Mocha styling.
let
  cfg = config.patrick.home.hyprland;
in
{
  config = mkIf cfg.enable {
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
      style = ''
        * {
          font-family: "JetBrainsMono Nerd Font";
        }
        .control-center,
        .notification-row {
          background: #1e1e2e;
          color: #cdd6f4;
        }
        .notification {
          border-radius: 10px;
          background: #313244;
        }
        .notification-content {
          padding: 8px;
        }
        .close-button {
          background: #f38ba8;
          color: #1e1e2e;
          border-radius: 8px;
        }
        .control-center .widget-title > button {
          background: #b4befe;
          color: #1e1e2e;
          border-radius: 8px;
        }
      '';
    };

    # Started from Hyprland exec-once, not graphical-session.target, so it never runs under
    # a foreign DE (COSMIC/KDE).
    systemd.user.services.swaync.Install.WantedBy = mkForce [ ];
  };
}
