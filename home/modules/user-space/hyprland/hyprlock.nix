{ config, lib, ... }:

with lib;

# hyprlock: PAM + fingerprint, Catppuccin Mocha.
let
  cfg = config.patrick.home.hyprland;
in
{
  config = mkIf (cfg.enable && cfg.shell == "native") {
    programs.hyprlock = {
      enable = true;
      settings = {
        # disable_loading_bar dropped upstream (0.9.5).
        general = {
          hide_cursor = false;
        };

        auth = {
          pam.enabled = true;
          fingerprint.enabled = true;
        };

        background = {
          monitor = "";
          blur_passes = 2;
          blur_size = 4;
        };

        label = [
          {
            monitor = "";
            text = "cmd[update:30000] echo \"$(date +\"%I:%M\")\"";
            font_size = 90;
            position = "-30, 0";
            halign = "right";
            valign = "top";
          }
          {
            monitor = "";
            text = "cmd[update:43200000] echo \"$(date +\"%A, %B %d %Y\")\"";
            font_size = 25;
            position = "-30, -150";
            halign = "right";
            valign = "top";
          }
          {
            monitor = "";
            text = "$FPRINTPROMPT";
            font_size = 20;
            position = "0, -150";
            halign = "center";
            valign = "center";
          }
        ];

        input-field = {
          monitor = "";
          size = "300, 60";
          outline_thickness = 3;
          dots_size = 0.2;
          dots_spacing = 0.2;
          dots_center = true;
          fade_on_empty = false;
          placeholder_text = "󰌾 Logged in as $USER";
          hide_input = false;
          fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
          position = "0, -35";
          halign = "center";
          valign = "center";
        };
      };
    };
  };
}
