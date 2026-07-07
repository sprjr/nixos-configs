{
  config,
  lib,
  dark-wallpaper-laptop,
  ...
}:

with lib;

# hyprlock — PAM + fingerprint auth (fingerprint is a no-op where fprintd is absent),
# label/timing layout carried over from the deprecated hyprlock for parity, rethemed to
# Catppuccin Mocha. System-side PAM is enabled by nixos/modules/desktop/hyprland.nix.
let
  cfg = config.patrick.home.hyprland;
in
{
  config = mkIf cfg.enable {
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          disable_loading_bar = true;
          hide_cursor = false;
        };

        auth = {
          pam.enabled = true;
          fingerprint.enabled = true;
        };

        background = {
          monitor = "";
          path = "${dark-wallpaper-laptop}";
          blur_passes = 2;
          blur_size = 4;
        };

        label = [
          {
            monitor = "";
            text = "cmd[update:30000] echo \"$(date +\"%I:%M\")\"";
            color = "rgb(cdd6f4)";
            font_size = 90;
            position = "-30, 0";
            halign = "right";
            valign = "top";
          }
          {
            monitor = "";
            text = "cmd[update:43200000] echo \"$(date +\"%A, %B %d %Y\")\"";
            color = "rgb(a6adc8)";
            font_size = 25;
            position = "-30, -150";
            halign = "right";
            valign = "top";
          }
          {
            monitor = "";
            text = "$FPRINTPROMPT";
            color = "rgb(cdd6f4)";
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
          outer_color = "rgb(b4befe)";
          inner_color = "rgb(1e1e2e)";
          font_color = "rgb(cdd6f4)";
          fade_on_empty = false;
          placeholder_text = "󰌾 Logged in as $USER";
          hide_input = false;
          check_color = "rgb(a6e3a1)";
          fail_color = "rgb(f38ba8)";
          fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
          position = "0, -35";
          halign = "center";
          valign = "center";
        };
      };
    };
  };
}
