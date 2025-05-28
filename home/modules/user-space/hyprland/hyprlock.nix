{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = false;
      };
      auth = {
        pam = {
          enabled = true;
        };
        fingerprint = {
          enabled = true;
        };
      };
      background = {
        monitor = "";
        # path = ../../assets/wallpaper.png;
        blur_passes = 2;
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
          font_color = "rgb(10, 10, 10)";
          font_size = 25;
          position = "0, -150";
          halign = "center";
          valign = "center";
        }
      ];
      input-field = {
        monitor = "";
        size = "300, 60";
        outline_thickness = 4;
        dots_size = 0.2;
        dots_spacing = 0.2;
        dots_center = true;
        outer_color = lib.mkForce "rgb(17, 17, 17)";
        inner_color = lib.mkForce "rgb(200, 200, 200)";
        font_color = lib.mkForce "rgb(10, 10, 10)";
        fade_on_empty = false;
        placeholder_text = "󰌾 Logged in as $USER";
        hide_input = false;
        check_color = lib.mkForce "rgb(204, 136, 34)";
        fail_color = lib.mkForce "rgb(204, 34, 34)";
        fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
        position = "0, -35";
        halign = "center";
        valign = "center";
      };
    };
  };

}
